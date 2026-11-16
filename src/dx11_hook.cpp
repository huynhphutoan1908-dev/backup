#include "dx11_hook.h"
#include "daniel_menu.h"
#include <d3d11.h>
#include <dxgi.h>
#include <stdio.h>
#include <imgui.h>
#include <backends/imgui_impl_win32.h>
#include <backends/imgui_impl_dx11.h>
#include <MinHook.h>

static void Log(const char* msg) {
    FILE* f = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\daniel_mod.log", "a");
    if (f) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d] [D3D11Hook] %s\n", st.wHour, st.wMinute, st.wSecond, msg);
        fclose(f);
    }
}

typedef HRESULT (WINAPI *Present_t)(IDXGISwapChain*, UINT, UINT);
typedef HRESULT (WINAPI *ResizeBuffers_t)(IDXGISwapChain*, UINT, UINT, UINT, DXGI_FORMAT, UINT);
typedef HANDLE (WINAPI *CreateMutexA_t)(LPSECURITY_ATTRIBUTES, BOOL, LPCSTR);
typedef HANDLE (WINAPI *CreateMutexW_t)(LPSECURITY_ATTRIBUTES, BOOL, LPCWSTR);

static Present_t oPresent = NULL;
static ResizeBuffers_t oResizeBuffers = NULL;
static CreateMutexA_t oCreateMutexA = NULL;
static CreateMutexW_t oCreateMutexW = NULL;

HANDLE WINAPI HookedCreateMutexA(LPSECURITY_ATTRIBUTES lpAttr, BOOL bInitialOwner, LPCSTR lpName) {
    if (lpName && lpName[0] != '\0') {
        char newName[512];
        sprintf(newName, "%s_daniel_%lu", lpName, GetCurrentProcessId());
        char logMsg[512];
        sprintf(logMsg, "Bypassing SingleInstance MutexA: '%s' -> '%s'", lpName, newName);
        Log(logMsg);
        HANDLE h = oCreateMutexA(lpAttr, bInitialOwner, newName);
        SetLastError(0);
        return h;
    }
    HANDLE h = oCreateMutexA(lpAttr, bInitialOwner, lpName);
    SetLastError(0);
    return h;
}

HANDLE WINAPI HookedCreateMutexW(LPSECURITY_ATTRIBUTES lpAttr, BOOL bInitialOwner, LPCWSTR lpName) {
    if (lpName && lpName[0] != L'\0') {
        wchar_t newName[512];
        swprintf(newName, 512, L"%ls_daniel_%lu", lpName, GetCurrentProcessId());
        char logMsg[512];
        sprintf(logMsg, "Bypassing SingleInstance MutexW for PID %lu", GetCurrentProcessId());
        Log(logMsg);
        HANDLE h = oCreateMutexW(lpAttr, bInitialOwner, newName);
        SetLastError(0);
        return h;
    }
    HANDLE h = oCreateMutexW(lpAttr, bInitialOwner, lpName);
    SetLastError(0);
    return h;
}

void InitEarlyHooks() {
    // No-op to avoid loader lock issues
}

ImFont* g_FontRegular = NULL;
ImFont* g_FontBold = NULL;
ImFont* g_FontTitle = NULL;
ImFont* g_FontSmall = NULL;
ImFont* g_FontLogo = NULL;
ImFont* g_FontIcons = NULL;

static ID3D11Device* g_pDevice = NULL;
static ID3D11DeviceContext* g_pContext = NULL;
static ID3D11RenderTargetView* g_pRenderTargetView = NULL;
static HWND g_hGameWnd = NULL;
static WNDPROC g_oWndProc = NULL;
static bool g_bHookInitialized = false;

typedef BOOL(WINAPI* GetCursorPos_t)(LPPOINT lpPoint);
static GetCursorPos_t oGetCursorPos = NULL;

typedef SHORT(WINAPI* GetAsyncKeyState_t)(int vKey);
static GetAsyncKeyState_t oGetAsyncKeyState = NULL;

static bool g_bFakeCursor = false;
static POINT g_FakeCursorPos = { 0, 0 };
static bool g_bFakeLButtonDown = false;
static int g_AutoLoginStep = 0;
static int g_AutoLoginTimer = 0;

BOOL WINAPI HookedGetCursorPos(LPPOINT lpPoint) {
    if (g_bFakeCursor && lpPoint) {
        *lpPoint = g_FakeCursorPos;
        return TRUE;
    }
    if (oGetCursorPos) return oGetCursorPos(lpPoint);
    return FALSE;
}

SHORT WINAPI HookedGetAsyncKeyState(int vKey) {
    if (g_bFakeLButtonDown && vKey == VK_LBUTTON) {
        return (SHORT)0x8000;
    }
    if (oGetAsyncKeyState) return oGetAsyncKeyState(vKey);
    return 0;
}

static void TriggerSimulateClick(int cx, int cy) {
    if (!g_hGameWnd) return;
    POINT pt = { cx, cy };
    ClientToScreen(g_hGameWnd, &pt);
    g_FakeCursorPos = pt;
    g_bFakeCursor = true;
    g_bFakeLButtonDown = true;
    PostMessageW(g_hGameWnd, WM_MOUSEMOVE, 0, (cy << 16) | (cx & 0xFFFF));
    PostMessageW(g_hGameWnd, WM_LBUTTONDOWN, MK_LBUTTON, (cy << 16) | (cx & 0xFFFF));
}

static void TriggerReleaseClick(int cx, int cy) {
    g_bFakeLButtonDown = false;
    PostMessageW(g_hGameWnd, WM_LBUTTONUP, 0, (cy << 16) | (cx & 0xFFFF));
    g_bFakeCursor = false;
}

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

static bool g_bUnloading = false;

static DWORD WINAPI UnloadThread(LPVOID lpParam) {
    if (g_bUnloading) return 0;
    g_bUnloading = true;
    Log("TriggerUnloadMod: Beginning complete cleanup of hooks and ImGui...");

    g_bShowMenu = false;

    // 1. Restore WndProc immediately
    if (g_hGameWnd && g_oWndProc) {
        SetWindowLongPtr(g_hGameWnd, GWLP_WNDPROC, (LONG_PTR)g_oWndProc);
        g_oWndProc = NULL;
        Log("TriggerUnloadMod: Original WndProc restored.");
    }

    // 2. Disable and clean all MinHook hooks
    MH_DisableHook(MH_ALL_HOOKS);
    MH_Uninitialize();
    Log("TriggerUnloadMod: MinHook hooks disabled and uninitialized.");

    // 3. Sleep briefly to let any active frames / callbacks exit safely
    Sleep(120);

    // 4. Shutdown ImGui
    if (g_bHookInitialized) {
        ImGui_ImplDX11_Shutdown();
        ImGui_ImplWin32_Shutdown();
        ImGui::DestroyContext();
        g_bHookInitialized = false;
        Log("TriggerUnloadMod: ImGui shutdown completed.");
    }

    // 5. Release DirectX COM objects
    if (g_pRenderTargetView) {
        g_pRenderTargetView->Release();
        g_pRenderTargetView = NULL;
    }
    if (g_pContext) {
        g_pContext->Release();
        g_pContext = NULL;
    }
    if (g_pDevice) {
        g_pDevice->Release();
        g_pDevice = NULL;
    }

    Log("TriggerUnloadMod: Mod menu completely removed from game!");

    // 6. If injected dynamically as daniel_mod.dll, eject self from process
    if (g_hModInstance) {
        char modPath[MAX_PATH] = {0};
        GetModuleFileNameA(g_hModInstance, modPath, MAX_PATH);
        if (strstr(modPath, "version.dll") == NULL) {
            Log("TriggerUnloadMod: FreeLibraryAndExitThread for injected DLL...");
            Sleep(50);
            FreeLibraryAndExitThread(g_hModInstance, 0);
        }
    }

    return 0;
}

void TriggerUnloadMod() {
    CreateThread(NULL, 0, UnloadThread, NULL, 0, NULL);
}

LRESULT CALLBACK HookedWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    if (uMsg == WM_KEYDOWN) {
        if (wParam == VK_INSERT || wParam == VK_F1) {
            g_bShowMenu = !g_bShowMenu;
            return 0;
        }
    }

    if (g_bHookInitialized && ImGui::GetCurrentContext() != NULL) {
        if (ImGui_ImplWin32_WndProcHandler(hWnd, uMsg, wParam, lParam))
            return true;

        ImGuiIO& io = ImGui::GetIO();
        if (io.WantCaptureMouse && (uMsg >= WM_MOUSEFIRST && uMsg <= WM_MOUSELAST))
            return true;
        if (g_bShowMenu && io.WantCaptureKeyboard && (uMsg >= WM_KEYFIRST && uMsg <= WM_KEYLAST))
            return true;
    }

    return CallWindowProc(g_oWndProc, hWnd, uMsg, wParam, lParam);
}

static void CreateRenderTarget(IDXGISwapChain* pSwapChain) {
    ID3D11Texture2D* pBackBuffer = NULL;
    pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (LPVOID*)&pBackBuffer);
    if (pBackBuffer) {
        g_pDevice->CreateRenderTargetView(pBackBuffer, NULL, &g_pRenderTargetView);
        pBackBuffer->Release();
    }
}

static void CleanupRenderTarget() {
    if (g_pRenderTargetView) {
        g_pRenderTargetView->Release();
        g_pRenderTargetView = NULL;
    }
}

HRESULT WINAPI HookedResizeBuffers(IDXGISwapChain* pSwapChain, UINT BufferCount, UINT Width, UINT Height, DXGI_FORMAT NewFormat, UINT SwapChainFlags) {
    CleanupRenderTarget();
    HRESULT hr = oResizeBuffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);
    CreateRenderTarget(pSwapChain);
    return hr;
}

static void WriteBMP(const char* filename, int width, int height, const unsigned char* data, int pitch, DXGI_FORMAT format) {
    FILE* f = fopen(filename, "wb");
    if (!f) return;

    int row_padded = (width * 3 + 3) & (~3);
    int data_size = row_padded * height;

    BITMAPFILEHEADER bfh;
    bfh.bfType = 0x4D42; // 'BM'
    bfh.bfSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + data_size;
    bfh.bfReserved1 = 0;
    bfh.bfReserved2 = 0;
    bfh.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);

    BITMAPINFOHEADER bih;
    bih.biSize = sizeof(BITMAPINFOHEADER);
    bih.biWidth = width;
    bih.biHeight = height;
    bih.biPlanes = 1;
    bih.biBitCount = 24;
    bih.biCompression = BI_RGB;
    bih.biSizeImage = data_size;
    bih.biXPelsPerMeter = 2835;
    bih.biYPelsPerMeter = 2835;
    bih.biClrUsed = 0;
    bih.biClrImportant = 0;

    fwrite(&bfh, sizeof(bfh), 1, f);
    fwrite(&bih, sizeof(bih), 1, f);

    unsigned char* row_buf = (unsigned char*)malloc(row_padded);
    if (row_buf) {
        bool isRGBA = (format == DXGI_FORMAT_R8G8B8A8_UNORM || format == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB);
        for (int y = height - 1; y >= 0; y--) {
            const unsigned char* src = data + y * pitch;
            for (int x = 0; x < width; x++) {
                if (isRGBA) {
                    row_buf[x * 3 + 0] = src[x * 4 + 2]; // B
                    row_buf[x * 3 + 1] = src[x * 4 + 1]; // G
                    row_buf[x * 3 + 2] = src[x * 4 + 0]; // R
                } else {
                    row_buf[x * 3 + 0] = src[x * 4 + 0]; // B
                    row_buf[x * 3 + 1] = src[x * 4 + 1]; // G
                    row_buf[x * 3 + 2] = src[x * 4 + 2]; // R
                }
            }
            fwrite(row_buf, 1, row_padded, f);
        }
        free(row_buf);
    }
    fclose(f);
}

static void SaveScreenshot(ID3D11Device* pDev, ID3D11DeviceContext* pCtx, IDXGISwapChain* pSwapChain, const char* filename) {
    ID3D11Texture2D* pBackBuffer = NULL;
    if (FAILED(pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (LPVOID*)&pBackBuffer)))
        return;

    D3D11_TEXTURE2D_DESC desc;
    pBackBuffer->GetDesc(&desc);

    desc.BindFlags = 0;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    desc.Usage = D3D11_USAGE_STAGING;

    ID3D11Texture2D* pStaging = NULL;
    if (SUCCEEDED(pDev->CreateTexture2D(&desc, NULL, &pStaging))) {
        pCtx->CopyResource(pStaging, pBackBuffer);

        D3D11_MAPPED_SUBRESOURCE mapped;
        if (SUCCEEDED(pCtx->Map(pStaging, 0, D3D11_MAP_READ, 0, &mapped))) {
            WriteBMP(filename, desc.Width, desc.Height, (const unsigned char*)mapped.pData, mapped.RowPitch, desc.Format);
            pCtx->Unmap(pStaging, 0);
        }
        pStaging->Release();
    }
    pBackBuffer->Release();
}

HRESULT WINAPI HookedPresent(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags) {
    if (!g_bHookInitialized) {
        if (SUCCEEDED(pSwapChain->GetDevice(__uuidof(ID3D11Device), (void**)&g_pDevice))) {
            g_pDevice->GetImmediateContext(&g_pContext);
            DXGI_SWAP_CHAIN_DESC desc;
            pSwapChain->GetDesc(&desc);
            g_hGameWnd = desc.OutputWindow;

            FILE* fh = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\game_hwnd.txt", "w");
            if (fh) {
                fprintf(fh, "%llu\n", (unsigned long long)g_hGameWnd);
                fclose(fh);
            }

            char hwndMsg[128];
            sprintf(hwndMsg, "Game HWND = %p saved to game_hwnd.txt", g_hGameWnd);
            Log(hwndMsg);

            CreateRenderTarget(pSwapChain);

            IMGUI_CHECKVERSION();
            ImGui::CreateContext();
            ImGuiIO& io = ImGui::GetIO();
            io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

            // Load Vietnamese Segoe UI fonts
            ImFontConfig font_cfg;
            font_cfg.OversampleH = 2;
            font_cfg.OversampleV = 2;

            g_FontRegular = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeui.ttf", 15.0f, &font_cfg, io.Fonts->GetGlyphRangesVietnamese());
            g_FontBold = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeuib.ttf", 15.0f, &font_cfg, io.Fonts->GetGlyphRangesVietnamese());
            g_FontTitle = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeuib.ttf", 26.0f, &font_cfg, io.Fonts->GetGlyphRangesVietnamese());
            g_FontSmall = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeui.ttf", 12.0f, &font_cfg, io.Fonts->GetGlyphRangesVietnamese());
            g_FontLogo = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeuiz.ttf", 24.0f, &font_cfg, io.Fonts->GetGlyphRangesVietnamese());

            static const ImWchar icon_ranges[] = { 0xE700, 0xF8A0, 0 };
            g_FontIcons = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segmdl2.ttf", 15.0f, &font_cfg, icon_ranges);

            if (!g_FontRegular) {
                g_FontRegular = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\arial.ttf", 15.0f, &font_cfg, io.Fonts->GetGlyphRangesVietnamese());
            }

            SetupModernGlassTheme();

            ImGui_ImplWin32_Init(g_hGameWnd);
            ImGui_ImplDX11_Init(g_pDevice, g_pContext);

            g_oWndProc = (WNDPROC)SetWindowLongPtr(g_hGameWnd, GWLP_WNDPROC, (LONG_PTR)HookedWndProc);

            InitIL2CPP();

            g_bHookInitialized = true;
            Log("ImGui and D3D11 Hook initialized successfully in Present!");
        }
    }

    if (g_bHookInitialized && g_pRenderTargetView) {
        if (!g_pAvatarTextureView && g_pDevice) {
            InitAvatarTexture(g_pDevice);
        }

        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        RenderFloatingToggleButton();

        if (g_bShowMenu) {
            RenderDanielMenu();
        }

        ImGui::Render();
        g_pContext->OMSetRenderTargets(1, &g_pRenderTargetView, NULL);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

        // Check file triggers periodically (every 30 frames ~0.5s) to eliminate disk I/O stutter
        static int s_TriggerCheckCounter = 0;
        if (++s_TriggerCheckCounter >= 30) {
            s_TriggerCheckCounter = 0;

            FILE* ft = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\take_shot.txt", "r");
            if (ft) {
                fclose(ft);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\take_shot.txt");
                SaveScreenshot(g_pDevice, g_pContext, pSwapChain, "C:\\Users\\huynh\\.gemini\\antigravity\\brain\\85edcc6f-04e3-4f73-8461-190e3376f6a4\\daniel_menu_directx.bmp");
                Log("Triggered DirectX screenshot saved to daniel_menu_directx.bmp");
            }

            FILE* fGo = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_goto_summon.txt", "r");
            if (fGo) {
                fclose(fGo);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_goto_summon.txt");
                g_bGoToSummonQueued = true;
                Log("Triggered GoToSummon from file!");
            }

            FILE* fSummon = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_auto_summon.txt", "r");
            if (fSummon) {
                fclose(fSummon);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_auto_summon.txt");
                g_bAutoSummonRunning = true;
                Log("Triggered AutoSummon Start from file!");
            }

            FILE* fStop = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_stop_summon.txt", "r");
            if (fStop) {
                fclose(fStop);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_stop_summon.txt");
                g_bAutoSummonRunning = false;
                Log("Triggered AutoSummon Stop from file!");
            }

            FILE* fMenu = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_menu.txt", "r");
            if (fMenu) {
                char mode = 0;
                fscanf(fMenu, "%c", &mode);
                fclose(fMenu);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_menu.txt");
                if (mode == '0') g_bShowMenu = false;
                else if (mode == '1') g_bShowMenu = true;
                else g_bShowMenu = !g_bShowMenu;
                Log("Triggered Menu visibility from file!");
            }

            FILE* fTab = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_tab.txt", "r");
            if (fTab) {
                int t = 1;
                fscanf(fTab, "%d", &t);
                fclose(fTab);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_tab.txt");
                g_CurrentTab = t;
                Log("Triggered tab switch from file!");
            }

            FILE* fFruit = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_auto_fruit.txt", "r");
            if (fFruit) {
                fclose(fFruit);
                remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_auto_fruit.txt");
                g_FruitWheelMode = 2; // Quay Đặc Biệt
                g_FruitBatchSize = 10;
                g_FruitBatches = 1;
                g_FruitCompletedBatches = 0;
                g_bFruitContinuous = false;
                g_bFruitRunning = true;
                Log("Triggered Auto Fruit Spin from file!");
            }

            FILE* fLua = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_lua.txt", "rb");
            if (fLua) {
                fseek(fLua, 0, SEEK_END);
                long sz = ftell(fLua);
                fseek(fLua, 0, SEEK_SET);
                if (sz > 0 && sz < 8192) {
                    char buf[8192] = {0};
                    fread(buf, 1, sz, fLua);
                    fclose(fLua);
                    remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_lua.txt");
                    ExecuteLua(buf);
                    Log("Triggered Lua script from file!");
                } else {
                    fclose(fLua);
                    remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_lua.txt");
                }
            }
        }

        // Process auto-login steps
        if (g_AutoLoginStep == 1) {
            TriggerSimulateClick(741, 848);
            g_AutoLoginStep = 2;
            g_AutoLoginTimer = 15; // hold 15 frames (~250ms)
            Log("AutoLogin: Clicked Dang Nhap button (741, 848)");
        } else if (g_AutoLoginStep == 2) {
            if (--g_AutoLoginTimer <= 0) {
                TriggerReleaseClick(741, 848);
                g_AutoLoginStep = 0;
                Log("AutoLogin: Released Dang Nhap click");
            }
        } else if (g_AutoLoginStep == 3) {
            TriggerSimulateClick(960, 848);
            g_AutoLoginStep = 4;
            g_AutoLoginTimer = 15;
            Log("AutoLogin: Clicked Vao Game button (960, 848)");
        } else if (g_AutoLoginStep == 4) {
            if (--g_AutoLoginTimer <= 0) {
                TriggerReleaseClick(960, 848);
                g_AutoLoginStep = 0;
                Log("AutoLogin: Released Vao Game click");
            }
        }

        FILE* fLogin = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_login.txt", "r");
        if (fLogin) {
            int step = 1;
            fscanf(fLogin, "%d", &step);
            fclose(fLogin);
            remove("C:\\Users\\huynh\\Downloads\\htht by daniel\\trigger_login.txt");
            g_AutoLoginStep = step;
            char lmsg[128];
            sprintf(lmsg, "Triggered AutoLogin Step %d from file!", step);
            Log(lmsg);
        }
    }

    return oPresent(pSwapChain, SyncInterval, Flags);
}

static DWORD WINAPI HookThread(LPVOID lpParam) {
    Log("HookThread started. Waiting for game to load...");
    Sleep(1500);

    WNDCLASSEXA wc = { sizeof(WNDCLASSEXA), CS_CLASSDC, DefWindowProcA, 0L, 0L, GetModuleHandleA(NULL), NULL, NULL, NULL, NULL, "DXGI_DUMMY_CLS", NULL };
    RegisterClassExA(&wc);
    HWND hWnd = CreateWindowA("DXGI_DUMMY_CLS", "Dummy", WS_OVERLAPPEDWINDOW, 0, 0, 100, 100, NULL, NULL, wc.hInstance, NULL);

    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevels[] = { D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_11_0 };

    DXGI_SWAP_CHAIN_DESC scd;
    ZeroMemory(&scd, sizeof(scd));
    scd.BufferCount = 1;
    scd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    scd.BufferDesc.Width = 100;
    scd.BufferDesc.Height = 100;
    scd.BufferDesc.RefreshRate.Numerator = 60;
    scd.BufferDesc.RefreshRate.Denominator = 1;
    scd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    scd.OutputWindow = hWnd;
    scd.SampleDesc.Count = 1;
    scd.Windowed = TRUE;
    scd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    IDXGISwapChain* pDummySwapChain = NULL;
    ID3D11Device* pDummyDevice = NULL;
    ID3D11DeviceContext* pDummyContext = NULL;

    HRESULT hr = D3D11CreateDeviceAndSwapChain(
        NULL,
        D3D_DRIVER_TYPE_HARDWARE,
        NULL,
        0,
        featureLevels,
        2,
        D3D11_SDK_VERSION,
        &scd,
        &pDummySwapChain,
        &pDummyDevice,
        &featureLevel,
        &pDummyContext
    );

    if (FAILED(hr)) {
        hr = D3D11CreateDeviceAndSwapChain(
            NULL,
            D3D_DRIVER_TYPE_WARP,
            NULL,
            0,
            featureLevels,
            2,
            D3D11_SDK_VERSION,
            &scd,
            &pDummySwapChain,
            &pDummyDevice,
            &featureLevel,
            &pDummyContext
        );
    }

    if (SUCCEEDED(hr) && pDummySwapChain) {
        void** pVTable = *(void***)pDummySwapChain;
        void* targetPresent = pVTable[8];
        void* targetResizeBuffers = pVTable[13];

        pDummySwapChain->Release();
        pDummyDevice->Release();
        pDummyContext->Release();
        DestroyWindow(hWnd);
        UnregisterClassA("DXGI_DUMMY_CLS", wc.hInstance);

        char msg[256];
        sprintf(msg, "Target Present = %p, Target ResizeBuffers = %p", targetPresent, targetResizeBuffers);
        Log(msg);

        MH_STATUS st = MH_Initialize();
        if (st == MH_OK || st == MH_ERROR_ALREADY_INITIALIZED) {
            MH_CreateHook(targetPresent, (LPVOID)&HookedPresent, (LPVOID*)&oPresent);
            MH_CreateHook(targetResizeBuffers, (LPVOID)&HookedResizeBuffers, (LPVOID*)&oResizeBuffers);

            HMODULE hUser32 = GetModuleHandleA("user32.dll");
            if (hUser32) {
                void* pGetCursorPos = (void*)GetProcAddress(hUser32, "GetCursorPos");
                void* pGetAsyncKeyState = (void*)GetProcAddress(hUser32, "GetAsyncKeyState");
                if (pGetCursorPos) {
                    MH_CreateHook(pGetCursorPos, (LPVOID)&HookedGetCursorPos, (LPVOID*)&oGetCursorPos);
                }
                if (pGetAsyncKeyState) {
                    MH_CreateHook(pGetAsyncKeyState, (LPVOID)&HookedGetAsyncKeyState, (LPVOID*)&oGetAsyncKeyState);
                }
            }

            if (MH_EnableHook(MH_ALL_HOOKS) == MH_OK) {
                Log("Hooks enabled successfully on IDXGISwapChain::Present, ResizeBuffers, GetCursorPos & GetAsyncKeyState!");
            } else {
                Log("Failed to enable hooks!");
            }
        } else {
            Log("Failed to initialize MinHook!");
        }
    } else {
        Log("Failed to create dummy D3D11 device and swapchain!");
        DestroyWindow(hWnd);
        UnregisterClassA("DXGI_DUMMY_CLS", wc.hInstance);
    }

    return 0;
}

void StartD3D11Hook() {
    CreateThread(NULL, 0, HookThread, NULL, 0, NULL);
}
