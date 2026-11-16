#include "daniel_menu.h"
#include <imgui.h>
#include <imgui_internal.h>
#include <stdio.h>
#include <math.h>
#include <MinHook.h>
#include "master_lua_data.h"
#include "avatar_image_data.h"

// ==========================================
// Reconstructed Definitions for Compilation
// ==========================================
static void LogDaniel(const char* msg);

static inline bool IsValidMemoryPtr(const void* p) {
    return p != nullptr && (uintptr_t)p > 0x10000 && !IsBadReadPtr(p, sizeof(void*));
}

// IL2CPP Types
typedef void* (*il2cpp_domain_get_t)();
typedef void* (*il2cpp_domain_assembly_open_t)(void* domain, const char* name);
typedef void* (*il2cpp_assembly_get_image_t)(void* assembly);
typedef void* (*il2cpp_class_from_name_t)(void* image, const char* namespaze, const char* name);
typedef void* (*il2cpp_class_get_field_from_name_t)(void* klass, const char* name);
typedef void* (*il2cpp_class_get_method_from_name_t)(void* klass, const char* name, int argsCount);
typedef void* (*il2cpp_runtime_invoke_t)(void* method, void* obj, void** params, void** exc);

// Currency Globals
int64_t g_RealXu = -1;
int64_t g_RealGem = -1;
int64_t g_RealGold = -1;
int64_t g_RealFruitCoin = -1;
static ULONGLONG s_lastCurrencyUpdate = 0;

// Fruit Wheel Globals
int g_FruitWheelMode = 1;
int g_FruitBatchSize = 10;
int64_t g_FruitBatches = 99999;
int64_t g_FruitCompletedBatches = 0;
bool g_bFruitContinuous = true;
bool g_bFruitRunning = false;
char g_FruitStatusText[256] = "Sẵn sàng (Mở Vòng quay Xu Ác Quỷ trong game để bắt đầu)";
void SetFruitSkipAnimation(bool enable) {}

// Wheel (Vòng Quay) Globals
void* g_pLuckySpinScene = nullptr;
void* g_pSuperLuckySpinScene = nullptr;
bool g_bWheelRunning = false;
bool g_bWheelGoToQueued = false;
bool g_bWheelSkipAnimation = true;
int g_WheelMode = 0;
int g_WheelBatchSize = 10000;
int64_t g_WheelBatches = 99999;
int64_t g_WheelCompletedBatches = 0;
int64_t g_WheelTotalSpins = 0;
bool g_bWheelContinuous = true;
int g_WheelTargetItems = 1;
bool g_bWheelRefreshAfterTarget = true;
bool g_bWheelAllowGems = true;
int64_t g_WheelGemBudget = 9999999;
int64_t g_WheelGemsUsed = 0;
bool g_bWheelAutoContinue = true;
char g_WheelStatusText[256] = "Sẵn sàng (Mở Vòng quay trong game để bắt đầu)";
static ULONGLONG s_lastWheelSpinTime = 0;

// LuckySpinScene (0x496E20, 0x495960, 0x4959B0, 0x495860, 0x495A90)
typedef void (*LuckySpinScene_Start_t)(void* this_ptr, void* method);
typedef void (*LuckySpinScene_Update_t)(void* this_ptr, void* method);
typedef void (*LuckySpinScene_ButtonSpin10Click_t)(void* this_ptr, void* method);
typedef void (*LuckySpinScene_ButtonSpin1Click_t)(void* this_ptr, void* method);
typedef void (*LuckySpinScene_ButtonRefreshClick_t)(void* this_ptr, void* method);
typedef void (*LuckySpinScene_DelayShowBoxSpin_t)(void* this_ptr, void* method);

// SuperLuckySpinScene (0x49FE40, 0x49EA10, 0x49EA60, 0x49E9D0, 0x49EB40)
typedef void (*SuperLuckySpinScene_Start_t)(void* this_ptr, void* method);
typedef void (*SuperLuckySpinScene_Update_t)(void* this_ptr, void* method);
typedef void (*SuperLuckySpinScene_ButtonSpin10Click_t)(void* this_ptr, void* method);
typedef void (*SuperLuckySpinScene_ButtonSpin1Click_t)(void* this_ptr, void* method);
typedef void (*SuperLuckySpinScene_ButtonRefreshClick_t)(void* this_ptr, void* method);
typedef void (*SuperLuckySpinScene_DelayShowBoxSpin_t)(void* this_ptr, void* method);

// SpinDisk (0x49D1D0, 0x49D770)
typedef bool (*SpinDisk_IsOnSpinToShowResult_t)(void* this_ptr, void* method);
typedef void (*SpinDisk_Update_t)(void* this_ptr, void* method);

// DataSender (0x4C7330, 0x4CC710, 0x4C72D0, 0x4CC6E0, 0x4C71F0)
typedef void (*DataSender_LuckyRotate_t)(void* this_ptr, int count, void* method);
typedef void (*DataSender_SuperLuckySpinRotate_t)(void* this_ptr, int count, void* method);
typedef void (*DataSender_LuckyRefresh_t)(void* this_ptr, void* method);
typedef void (*DataSender_SuperLuckySpinRefresh_t)(void* this_ptr, void* method);
typedef void (*DataSender_LuckyBuyChip_t)(void* this_ptr, int count, void* method);

// PlayerInventory (0x363340, 0x362D60)
typedef int64_t (*PlayerInventory_GetNumberItemConsumable_t)(void* this_ptr, int itemId, void* method);
typedef void* (*PlayerInventory_GetInstance_t)(void* method);

// GameContext (0x356AE0)
typedef void* (*GameContext_GetIntance_t)(void* method);

static GameContext_GetIntance_t pfn_GameContext_GetIntance = nullptr;
static PlayerInventory_GetInstance_t pfn_PlayerInventory_GetInstance = nullptr;
static PlayerInventory_GetNumberItemConsumable_t pfn_PlayerInventory_GetNumberItemConsumable = nullptr;

static DataSender_LuckyRotate_t pfn_DataSender_LuckyRotate = nullptr;
static DataSender_SuperLuckySpinRotate_t pfn_DataSender_SuperLuckySpinRotate = nullptr;
static DataSender_LuckyRefresh_t pfn_DataSender_LuckyRefresh = nullptr;
static DataSender_SuperLuckySpinRefresh_t pfn_DataSender_SuperLuckySpinRefresh = nullptr;
static DataSender_LuckyBuyChip_t pfn_DataSender_LuckyBuyChip = nullptr;

static LuckySpinScene_Start_t o_LuckySpinScene_Start = nullptr;
static LuckySpinScene_Start_t pfn_LuckySpinScene_Start = nullptr;
static LuckySpinScene_Update_t o_LuckySpinScene_Update = nullptr;
static LuckySpinScene_Update_t pfn_LuckySpinScene_Update = nullptr;
static LuckySpinScene_ButtonSpin10Click_t pfn_LuckySpinScene_ButtonSpin10Click = nullptr;
static LuckySpinScene_ButtonSpin1Click_t pfn_LuckySpinScene_ButtonSpin1Click = nullptr;
static LuckySpinScene_ButtonRefreshClick_t pfn_LuckySpinScene_ButtonRefreshClick = nullptr;
static LuckySpinScene_DelayShowBoxSpin_t o_LuckySpinScene_DelayShowBoxSpin = nullptr;
static LuckySpinScene_DelayShowBoxSpin_t pfn_LuckySpinScene_DelayShowBoxSpin = nullptr;

static SuperLuckySpinScene_Start_t o_SuperLuckySpinScene_Start = nullptr;
static SuperLuckySpinScene_Start_t pfn_SuperLuckySpinScene_Start = nullptr;
static SuperLuckySpinScene_Update_t o_SuperLuckySpinScene_Update = nullptr;
static SuperLuckySpinScene_Update_t pfn_SuperLuckySpinScene_Update = nullptr;
static SuperLuckySpinScene_ButtonSpin10Click_t pfn_SuperLuckySpinScene_ButtonSpin10Click = nullptr;
static SuperLuckySpinScene_ButtonSpin1Click_t pfn_SuperLuckySpinScene_ButtonSpin1Click = nullptr;
static SuperLuckySpinScene_ButtonRefreshClick_t pfn_SuperLuckySpinScene_ButtonRefreshClick = nullptr;
static SuperLuckySpinScene_DelayShowBoxSpin_t o_SuperLuckySpinScene_DelayShowBoxSpin = nullptr;
static SuperLuckySpinScene_DelayShowBoxSpin_t pfn_SuperLuckySpinScene_DelayShowBoxSpin = nullptr;

static SpinDisk_Update_t o_SpinDisk_Update = nullptr;
static SpinDisk_Update_t pfn_SpinDisk_Update = nullptr;
void* g_pSpinDisk = nullptr;
static ULONGLONG s_lastSpinDiskUpdateTick = 0;

static SpinDisk_IsOnSpinToShowResult_t o_SpinDisk_IsOnSpinToShowResult = nullptr;
static SpinDisk_IsOnSpinToShowResult_t pfn_SpinDisk_IsOnSpinToShowResult = nullptr;

static ULONGLONG s_lastLuckySpinUpdateTick = 0;
static ULONGLONG s_lastSuperLuckySpinUpdateTick = 0;

void WINAPI Hooked_LuckySpinScene_Start(void* this_ptr, void* method) {
    g_pLuckySpinScene = this_ptr;
    s_lastLuckySpinUpdateTick = GetTickCount64();
    LogDaniel("Captured LuckySpinScene instance via Start!");
    if (o_LuckySpinScene_Start) o_LuckySpinScene_Start(this_ptr, method);
}

void WINAPI Hooked_LuckySpinScene_Update(void* this_ptr, void* method) {
    g_pLuckySpinScene = this_ptr;
    s_lastLuckySpinUpdateTick = GetTickCount64();
    if (o_LuckySpinScene_Update) o_LuckySpinScene_Update(this_ptr, method);
}

void WINAPI Hooked_SpinDisk_Update(void* this_ptr, void* method) {
    g_pSpinDisk = this_ptr;
    s_lastSpinDiskUpdateTick = GetTickCount64();
    if (this_ptr) {
        __try {
            int32_t tSpin = *(int32_t*)((uintptr_t)this_ptr + 0x40);
            if (tSpin == 1) {
                s_lastSuperLuckySpinUpdateTick = s_lastSpinDiskUpdateTick;
            } else {
                s_lastLuckySpinUpdateTick = s_lastSpinDiskUpdateTick;
            }
            if (g_bWheelSkipAnimation) {
                *(void**)((uintptr_t)this_ptr + 0x38) = nullptr;
                *(float*)((uintptr_t)this_ptr + 0x30) = 0.0f;
                *(float*)((uintptr_t)this_ptr + 0x34) = 0.0f;
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }
    if (o_SpinDisk_Update) {
        o_SpinDisk_Update(this_ptr, method);
    }
}

void WINAPI Hooked_LuckySpinScene_DelayShowBoxSpin(void* this_ptr, void* method) {
    if (o_LuckySpinScene_DelayShowBoxSpin) {
        o_LuckySpinScene_DelayShowBoxSpin(this_ptr, method);
    }
}

void WINAPI Hooked_SuperLuckySpinScene_Start(void* this_ptr, void* method) {
    g_pSuperLuckySpinScene = this_ptr;
    s_lastSuperLuckySpinUpdateTick = GetTickCount64();
    LogDaniel("Captured SuperLuckySpinScene instance via Start!");
    if (o_SuperLuckySpinScene_Start) o_SuperLuckySpinScene_Start(this_ptr, method);
}

void WINAPI Hooked_SuperLuckySpinScene_Update(void* this_ptr, void* method) {
    g_pSuperLuckySpinScene = this_ptr;
    s_lastSuperLuckySpinUpdateTick = GetTickCount64();
    if (o_SuperLuckySpinScene_Update) o_SuperLuckySpinScene_Update(this_ptr, method);
}

void WINAPI Hooked_SuperLuckySpinScene_DelayShowBoxSpin(void* this_ptr, void* method) {
    if (o_SuperLuckySpinScene_DelayShowBoxSpin) {
        o_SuperLuckySpinScene_DelayShowBoxSpin(this_ptr, method);
    }
}

bool WINAPI Hooked_SpinDisk_IsOnSpinToShowResult(void* this_ptr, void* method) {
    if (g_bWheelSkipAnimation) {
        return false;
    }
    if (o_SpinDisk_IsOnSpinToShowResult) {
        return o_SpinDisk_IsOnSpinToShowResult(this_ptr, method);
    }
    return false;
}

bool IsLuckySpinValid() {
    if (!g_pLuckySpinScene) return false;
    __try {
        uintptr_t p = (uintptr_t)g_pLuckySpinScene;
        if (!p || *(void**)p == nullptr) return false;
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        g_pLuckySpinScene = nullptr;
        return false;
    }
}

bool IsSuperLuckySpinValid() {
    if (!g_pSuperLuckySpinScene) return false;
    __try {
        uintptr_t p = (uintptr_t)g_pSuperLuckySpinScene;
        if (!p || *(void**)p == nullptr) return false;
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        g_pSuperLuckySpinScene = nullptr;
        return false;
    }
}

void EnsureIL2CPPThreadAttached() {
    static thread_local bool s_bAttached = false;
    if (s_bAttached) return;
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) return;
    typedef void* (*il2cpp_thread_attach_t)(void* domain);
    typedef void* (*il2cpp_domain_get_t)();
    static il2cpp_thread_attach_t p_thread_attach = (il2cpp_thread_attach_t)GetProcAddress(hGA, "il2cpp_thread_attach");
    static il2cpp_domain_get_t p_domain_get = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    if (p_thread_attach && p_domain_get) {
        void* domain = p_domain_get();
        if (domain) {
            p_thread_attach(domain);
            s_bAttached = true;
        }
    }
}

static void LogDaniel(const char* msg) {
    if (!msg) return;
    FILE* f = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\daniel_mod.log", "a");
    if (f) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d] [DanielMod] %s\n", st.wHour, st.wMinute, st.wSecond, msg);
        fclose(f);
    }
}



static void LogDanielFmt(const char* fmt, ...) {
    char buf[1024];
    va_list va;
    va_start(va, fmt);
    vsnprintf(buf, sizeof(buf), fmt, va);
    va_end(va);
    LogDaniel(buf);
}

bool ExecuteLua(const char* luaCode, char* outMsg, size_t msgBufSize) {
    if (!luaCode || luaCode[0] == '\0') {
        if (outMsg) snprintf(outMsg, msgBufSize, "Lua code rỗng!");
        return false;
    }

    EnsureIL2CPPThreadAttached();

    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) {
        if (outMsg) snprintf(outMsg, msgBufSize, "Lỗi: Không tìm thấy GameAssembly.dll!");
        return false;
    }

    typedef void* (*il2cpp_domain_get_t)();
    typedef void* (*il2cpp_domain_assembly_open_t)(void* domain, const char* name);
    typedef void* (*il2cpp_assembly_get_image_t)(void* assembly);
    typedef void* (*il2cpp_class_from_name_t)(void* image, const char* namespaze, const char* name);
    typedef void* (*il2cpp_class_get_field_from_name_t)(void* klass, const char* name);
    typedef void (*il2cpp_field_static_get_value_t)(void* field, void* value);
    typedef void* (*il2cpp_class_get_methods_t)(void* klass, void** iter);
    typedef const char* (*il2cpp_method_get_name_t)(void* method);
    typedef uint32_t (*il2cpp_method_get_param_count_t)(void* method);
    typedef void* (*il2cpp_method_get_param_t)(void* method, uint32_t index);
    typedef const char* (*il2cpp_type_get_name_t)(void* type);
    typedef void* (*il2cpp_runtime_invoke_t)(void* method, void* obj, void** params, void** exc);
    typedef void* (*il2cpp_string_new_t)(const char* str);
    typedef void* (*il2cpp_domain_get_assemblies_t)(void* domain, size_t* size);
    typedef void (*il2cpp_runtime_class_init_t)(void* klass);

    static auto p_domain_get = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    static auto p_assembly_open = (il2cpp_domain_assembly_open_t)GetProcAddress(hGA, "il2cpp_domain_assembly_open");
    static auto p_get_image = (il2cpp_assembly_get_image_t)GetProcAddress(hGA, "il2cpp_assembly_get_image");
    static auto p_class_from_name = (il2cpp_class_from_name_t)GetProcAddress(hGA, "il2cpp_class_from_name");
    static auto p_get_field = (il2cpp_class_get_field_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_field_from_name");
    static auto p_static_get_value = (il2cpp_field_static_get_value_t)GetProcAddress(hGA, "il2cpp_field_static_get_value");
    static auto p_class_get_methods = (il2cpp_class_get_methods_t)GetProcAddress(hGA, "il2cpp_class_get_methods");
    static auto p_method_get_name = (il2cpp_method_get_name_t)GetProcAddress(hGA, "il2cpp_method_get_name");
    static auto p_method_get_param_count = (il2cpp_method_get_param_count_t)GetProcAddress(hGA, "il2cpp_method_get_param_count");
    static auto p_method_get_param = (il2cpp_method_get_param_t)GetProcAddress(hGA, "il2cpp_method_get_param");
    static auto p_type_get_name = (il2cpp_type_get_name_t)GetProcAddress(hGA, "il2cpp_type_get_name");
    static auto p_runtime_invoke = (il2cpp_runtime_invoke_t)GetProcAddress(hGA, "il2cpp_runtime_invoke");
    static auto p_string_new = (il2cpp_string_new_t)GetProcAddress(hGA, "il2cpp_string_new");
    static auto p_domain_get_assemblies = (il2cpp_domain_get_assemblies_t)GetProcAddress(hGA, "il2cpp_domain_get_assemblies");
    static auto p_runtime_class_init = (il2cpp_runtime_class_init_t)GetProcAddress(hGA, "il2cpp_runtime_class_init");

    if (!p_domain_get || !p_runtime_invoke || !p_string_new) {
        if (outMsg) snprintf(outMsg, msgBufSize, "Lỗi: Không tìm thấy IL2CPP API!");
        LogDaniel("[ExecuteLua] Critical IL2CPP APIs missing!");
        return false;
    }

    __try {
        void* domain = p_domain_get();
        if (!domain) return false;

        static void* klassLuaBehaviour = nullptr;
        static void* fLuaEnv = nullptr;
        static void* klassLuaEnv = nullptr;
        static void* methodDoString = nullptr;

        if (!klassLuaBehaviour || !fLuaEnv || !klassLuaEnv || !methodDoString) {
            void* assembly = p_assembly_open ? p_assembly_open(domain, "Assembly-CSharp") : nullptr;
            void* image = assembly && p_get_image ? p_get_image(assembly) : nullptr;

            if (image && p_class_from_name) {
                klassLuaBehaviour = p_class_from_name(image, "XLuaTest", "LuaBehaviour");
                if (!klassLuaBehaviour) klassLuaBehaviour = p_class_from_name(image, "XLua", "LuaBehaviour");
                if (!klassLuaBehaviour) klassLuaBehaviour = p_class_from_name(image, "", "LuaBehaviour");

                klassLuaEnv = p_class_from_name(image, "XLua", "LuaEnv");
                if (!klassLuaEnv) klassLuaEnv = p_class_from_name(image, "", "LuaEnv");
            }

            if ((!klassLuaBehaviour || !klassLuaEnv) && p_domain_get_assemblies && p_get_image) {
                size_t asmCount = 0;
                void** asms = (void**)p_domain_get_assemblies(domain, &asmCount);
                if (asms) {
                    for (size_t i = 0; i < asmCount; i++) {
                        void* img = p_get_image(asms[i]);
                        if (!img) continue;
                        if (!klassLuaBehaviour && p_class_from_name) {
                            klassLuaBehaviour = p_class_from_name(img, "XLuaTest", "LuaBehaviour");
                            if (!klassLuaBehaviour) klassLuaBehaviour = p_class_from_name(img, "XLua", "LuaBehaviour");
                            if (!klassLuaBehaviour) klassLuaBehaviour = p_class_from_name(img, "", "LuaBehaviour");
                        }
                        if (!klassLuaEnv && p_class_from_name) {
                            klassLuaEnv = p_class_from_name(img, "XLua", "LuaEnv");
                            if (!klassLuaEnv) klassLuaEnv = p_class_from_name(img, "", "LuaEnv");
                        }
                    }
                }
            }

            if (klassLuaBehaviour && p_get_field) {
                fLuaEnv = p_get_field(klassLuaBehaviour, "luaEnv");
                if (!fLuaEnv) fLuaEnv = p_get_field(klassLuaBehaviour, "m_luaEnv");
            }

            if (klassLuaEnv && p_class_get_methods && p_method_get_name) {
                void* iter = nullptr;
                while (void* m = p_class_get_methods(klassLuaEnv, &iter)) {
                    const char* mname = p_method_get_name(m);
                    if (mname && strcmp(mname, "DoString") == 0) {
                        uint32_t pcount = p_method_get_param_count ? p_method_get_param_count(m) : 0;
                        if (pcount == 3) {
                            if (p_method_get_param && p_type_get_name) {
                                void* pType = p_method_get_param(m, 0);
                                const char* tname = pType ? p_type_get_name(pType) : "";
                                if (tname && (strstr(tname, "String") || strstr(tname, "string"))) {
                                    methodDoString = m;
                                    break;
                                }
                            }
                            if (!methodDoString) methodDoString = m;
                        }
                    }
                }
            }

            LogDanielFmt("[ExecuteLua] Resolved klassLuaBehaviour=%p, fLuaEnv=%p, klassLuaEnv=%p, methodDoString=%p",
                         klassLuaBehaviour, fLuaEnv, klassLuaEnv, methodDoString);
        }

        if (!fLuaEnv || !methodDoString) {
            if (outMsg) snprintf(outMsg, msgBufSize, "Lỗi: Không tìm thấy LuaEnv hoặc DoString!");
            LogDanielFmt("[ExecuteLua] Missing fLuaEnv=%p or methodDoString=%p", fLuaEnv, methodDoString);
            return false;
        }

        void* pLuaEnv = nullptr;
        if (p_static_get_value && fLuaEnv) {
            p_static_get_value(fLuaEnv, &pLuaEnv);
        }
        if (!pLuaEnv && p_runtime_class_init && klassLuaBehaviour) {
            LogDaniel("[ExecuteLua] pLuaEnv is null, running il2cpp_runtime_class_init(klassLuaBehaviour)...");
            p_runtime_class_init(klassLuaBehaviour);
            if (p_static_get_value && fLuaEnv) {
                p_static_get_value(fLuaEnv, &pLuaEnv);
            }
        }
        if (!pLuaEnv) {
            if (outMsg) snprintf(outMsg, msgBufSize, "Lỗi: Game chưa nạp LuaEnv!");
            LogDaniel("[ExecuteLua] p_static_get_value returned null pLuaEnv!");
            return false;
        }

        void* strCode = p_string_new(luaCode);
        void* strChunk = p_string_new("daniel_master");
        void* args[3] = { strCode, strChunk, nullptr };
        void* exc = nullptr;
        p_runtime_invoke(methodDoString, pLuaEnv, args, &exc);
        if (exc) {
            if (outMsg) snprintf(outMsg, msgBufSize, "Lỗi ngoại lệ khi chạy Lua!");
            LogDaniel("[ExecuteLua] Exception thrown during DoString execution!");
            return false;
        }

        if (outMsg) snprintf(outMsg, msgBufSize, "Thực thi thành công!");
        LogDaniel("[ExecuteLua] DoString executed successfully!");
        return true;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        if (outMsg) snprintf(outMsg, msgBufSize, "SEH Exception khi thực thi Lua!");
        LogDaniel("[ExecuteLua] SEH Crash / Exception caught in ExecuteLua!");
        return false;
    }
}

ID3D11ShaderResourceView* g_pAvatarTextureView = NULL;

bool g_bShowMenu = true;
bool g_bMasterFeaturesLoaded = false;
float g_GameSpeed = 1.0f;
bool g_bLockSpeed = true; // Auto-lock speed enabled by default

int g_CurrentTab = 1; // Default to Tab 1: "Tăng Tốc"
static bool g_AutoLuckyWheel = false;
static int g_WheelCount = 10;
static bool g_AutoBean = true;
static bool g_AutoAdventure = false;
static bool g_AutoDaily = true;
static bool g_AutoPet = false;
static float g_MenuAlpha = 1.0f;
static char s_SearchQuery[64] = "";

// Chiêu Mộ Globals
void* g_pBoxOrbSummon = nullptr;
bool g_bAutoSummonRunning = false;
bool g_bSingleSummonQueued = false;
bool g_bFactionChangeQueued = false;
bool g_bGoToSummonQueued = false;
bool g_bRotateFaction = true; // "Đảo hệ: Bật" default
bool g_bFastEffect = true;    // "Hiệu ứng: Nhanh" default
int g_SelectedFactionId = 4;      // Default: 4 (Nhanh Nhẹn)
int64_t g_SummonRounds = 10;      // Mặc định 10 đợt x10 = 100 tướng (tối đa 10,000,000,000,000,000)
int64_t g_CompletedRounds = 0;
bool g_bInfiniteLoop = false;     // "Vòng lặp vô hạn" để quay vô tận

static int s_CurrentRotateIdx = 0;
static const int s_RotateFactionIds[4] = { 4, 6, 5, 3 }; // Nhanh Nhẹn (4) -> Bền Bỉ (6) -> Chính Xác (5) -> Sinh Khí (3)

struct FactionTabDef {
    int id;
    const char* name;
};

static const FactionTabDef s_FactionTabs[4] = {
    { 4, "Nhanh Nhẹn" },
    { 6, "Bền Bỉ" },
    { 5, "Chính Xác" },
    { 3, "Sinh Khí" }
};

// BoxOrbSummon Signatures
typedef void (*BoxOrbSummon_Start_t)(void* this_ptr, void* method);
typedef void (*BoxOrbSummon_ButtonSummon10Click_t)(void* this_ptr, void* method);
typedef void (*BoxOrbSummon_ButtonSummon1Click_t)(void* this_ptr, void* method);
typedef void (*BoxOrbSummon_OnFactionSelected_t)(void* this_ptr, int faction_id, void* method);
typedef void (*BoxOrbSummon_ProcessKEvent_t)(void* this_ptr, int event_id, void* event_data, void* method);

static BoxOrbSummon_Start_t o_BoxOrbSummon_Start = nullptr;
static BoxOrbSummon_Start_t pfn_BoxOrbSummon_Start = nullptr;
static BoxOrbSummon_ButtonSummon10Click_t pfn_ButtonSummon10Click = nullptr;
static BoxOrbSummon_ButtonSummon1Click_t pfn_ButtonSummon1Click = nullptr;
static BoxOrbSummon_OnFactionSelected_t pfn_OnFactionSelected = nullptr;
static BoxOrbSummon_ProcessKEvent_t o_BoxOrbSummon_ProcessKEvent = nullptr;
static BoxOrbSummon_ProcessKEvent_t pfn_BoxOrbSummon_ProcessKEvent = nullptr;

// EventSystem::Update Signatures (Unity Main Thread Loop)
typedef void (*EventSystem_Update_t)(void* this_ptr, void* method);
static EventSystem_Update_t o_EventSystem_Update = nullptr;
static EventSystem_Update_t pfn_EventSystem_Update = nullptr;

// PopupShowBonusEffect2 Signatures (Skip 10x cards reveal animation)
// CRITICAL: ShowUp returns PopupShowBonusEffect2* in RAX, caller checks RAX!
typedef void* (*PopupShowBonusEffect2_ShowUp_t)(void* this_ptr, void* method);
typedef void (*PopupShowBonusEffect2_ButtonCloseClick_t)(void* this_ptr, void* method);
static PopupShowBonusEffect2_ShowUp_t o_PopupShowBonusEffect2_ShowUp = nullptr;
static PopupShowBonusEffect2_ShowUp_t pfn_PopupShowBonusEffect2_ShowUp = nullptr;
static PopupShowBonusEffect2_ButtonCloseClick_t pfn_PopupShowBonusEffect2_ButtonCloseClick = nullptr;

// PopupBlockTouch Signatures (SetDurationBlock at RVA 0x366C70)
typedef void (*PopupBlockTouch_SetDurationBlock_t)(void* this_ptr, float duration, void* method);
static PopupBlockTouch_SetDurationBlock_t o_PopupBlockTouch_SetDurationBlock = nullptr;
static PopupBlockTouch_SetDurationBlock_t pfn_PopupBlockTouch_SetDurationBlock = nullptr;

// <RevealRemainItemOneByOne>d__12 Signatures (Skip card reveal coroutine at RVA 0x381630)
typedef bool (*RevealRemainItemOneByOne_MoveNext_t)(void* this_ptr, void* method);
static RevealRemainItemOneByOne_MoveNext_t o_RevealRemainItemOneByOne_MoveNext = nullptr;
static RevealRemainItemOneByOne_MoveNext_t pfn_RevealRemainItemOneByOne_MoveNext = nullptr;

// State tracking for auto summon
static void* g_pBonusPopupToClose = nullptr;
static bool g_bWaitingForResponse = false;
static bool g_bServerResponseReceived = false;
static ULONGLONG s_requestSentTime = 0;

// IL2CPP Engine Hook Signatures
typedef void (*set_timeScale_t)(float);
typedef float (*get_timeScale_t)();
static set_timeScale_t o_set_timeScale = NULL;
static set_timeScale_t g_set_timeScale = NULL;
static get_timeScale_t g_get_timeScale = NULL;

// Target FPS Limiter (Native Unity Application::set_targetFrameRate)
typedef void (*set_targetFrameRate_t)(int);
typedef int (*get_targetFrameRate_t)();
static set_targetFrameRate_t o_set_targetFrameRate = NULL;
static set_targetFrameRate_t g_set_targetFrameRate = NULL;
static get_targetFrameRate_t g_get_targetFrameRate = NULL;
int g_TargetFPS = 60; // Default 60 FPS



// Check if g_pBoxOrbSummon is alive and pointing to valid game object
bool IsBoxOrbSummonValid() {
    if (!g_pBoxOrbSummon) return false;
    __try {
        uintptr_t p = (uintptr_t)g_pBoxOrbSummon;
        if (!p) return false;
        // In Unity IL2CPP MonoBehaviour: +0x10 is m_CachedPtr (native GameObject/Component pointer)
        void* cachedPtr = *(void**)(p + 0x10);
        if (!cachedPtr) return false;
        // In BoxOrbSummon: +0x20 is m_DataSender
        void* dataSender = *(void**)(p + 0x20);
        if (!dataSender) return false;
        // In BoxOrbSummon: +0x30 is m_FactionSelected (valid faction IDs: 1 to 6)
        int curFaction = *(int*)(p + 0x30);
        if (curFaction < 1 || curFaction > 6) return false;
        // In BoxOrbSummon: +0x38 is m_ListFactionSelect
        void* listFaction = *(void**)(p + 0x38);
        if (!listFaction) return false;
        return true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        return false;
    }
}

// Hooked EventSystem::Update - executes on Unity's MAIN THREAD every frame
void WINAPI Hooked_EventSystem_Update(void* this_ptr, void* method) {
    if (o_EventSystem_Update) {
        o_EventSystem_Update(this_ptr, method);
    }
    OnUnityMainThreadUpdate();
}

// Hooked BoxOrbSummon_Start captures the active summon screen instance
void WINAPI Hooked_BoxOrbSummon_Start(void* this_ptr, void* method) {
    g_pBoxOrbSummon = this_ptr;
    LogDaniel("Captured BoxOrbSummon instance!");
    if (this_ptr) {
        __try {
            int curFaction = *(int*)((uintptr_t)this_ptr + 0x30);
            if (curFaction > 0 && curFaction <= 6) {
                g_SelectedFactionId = curFaction;
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }
    if (o_BoxOrbSummon_Start) o_BoxOrbSummon_Start(this_ptr, method);
}

// Hooked BoxOrbSummon::ProcessKEvent captures network response (0xD4 = 212 = summon result)
void WINAPI Hooked_BoxOrbSummon_ProcessKEvent(void* this_ptr, int event_id, void* event_data, void* method) {
    if (event_id == 0xD4) {
        g_bServerResponseReceived = true;
        g_bWaitingForResponse = false;
    }
    if (o_BoxOrbSummon_ProcessKEvent) {
        o_BoxOrbSummon_ProcessKEvent(this_ptr, event_id, event_data, method);
    }
}

// Hooked PopupShowBonusEffect2::ShowUp skips 10x cards reveal safely
// CRITICAL: Must return PopupShowBonusEffect2* in RAX, caller BoxOrbSummon checks RAX for null!
void* WINAPI Hooked_PopupShowBonusEffect2_ShowUp(void* this_ptr, void* method) {
    void* result = nullptr;
    if (o_PopupShowBonusEffect2_ShowUp) {
        result = o_PopupShowBonusEffect2_ShowUp(this_ptr, method);
    }
    g_bServerResponseReceived = true;
    g_bWaitingForResponse = false;

    // Queue popup to be closed safely on the next frame inside Update loop (never synchronously)
    if (g_bFastEffect && (g_bAutoSummonRunning || g_bSingleSummonQueued)) {
        g_pBonusPopupToClose = result ? result : this_ptr;
    }
    return result;
}

// Hooked PopupBlockTouch::SetDurationBlock (RVA 0x366C70) bypasses touch block delay
void WINAPI Hooked_PopupBlockTouch_SetDurationBlock(void* this_ptr, float duration, void* method) {
    if (g_bFastEffect || g_bWheelSkipAnimation) {
        duration = 0.0f; // Bỏ qua chặn thao tác để quay siêu tốc!
    }
    if (o_PopupBlockTouch_SetDurationBlock) {
        o_PopupBlockTouch_SetDurationBlock(this_ptr, duration, method);
    }
}

// Hooked <RevealRemainItemOneByOne>d__12::MoveNext (RVA 0x381630) skips slow card reveal animation
bool WINAPI Hooked_RevealRemainItemOneByOne_MoveNext(void* this_ptr, void* method) {
    if (g_bFastEffect && (g_bAutoSummonRunning || g_bSingleSummonQueued)) {
        return false; // Stop coroutine immediately, fast revealing all cards!
    }
    if (o_RevealRemainItemOneByOne_MoveNext) {
        return o_RevealRemainItemOneByOne_MoveNext(this_ptr, method);
    }
    return false;
}

// Hooked set_timeScale intercepts ALL calls from Unity game scripts
void WINAPI Hooked_set_timeScale(float value) {
    if (g_bLockSpeed && g_GameSpeed >= 1.0f) {
        if (o_set_timeScale) {
            o_set_timeScale(g_GameSpeed);
        }
    } else {
        if (o_set_timeScale) {
            o_set_timeScale(value);
        }
    }
}

// Hooked set_targetFrameRate intercepts Unity frame rate capping
void WINAPI Hooked_set_targetFrameRate(int value) {
    if (g_TargetFPS > 0) {
        if (o_set_targetFrameRate) {
            o_set_targetFrameRate(g_TargetFPS);
        }
    } else {
        if (o_set_targetFrameRate) {
            o_set_targetFrameRate(value);
        }
    }
}

void ApplyFpsLimit(int fps) {
    g_TargetFPS = fps;
    int unityVal = (fps <= 0) ? -1 : fps;
    if (o_set_targetFrameRate) {
        o_set_targetFrameRate(unityVal);
    } else if (g_set_targetFrameRate) {
        g_set_targetFrameRate(unityVal);
    }
}

static size_t s_off_m_Chip = 0x0E0;
static size_t s_off_m_SuperChip = 0x0F8;
static size_t s_off_m_Gem = 0x090;
static size_t s_off_m_Gold = 0x088;
static size_t s_off_dataSender = 0x198;
static bool s_GCOffsetsResolved = false;

static void ResolveGameContextOffsets(void* klassGC, HMODULE hGA) {
    if (s_GCOffsetsResolved || !klassGC || !hGA) return;
    typedef void* (*il2cpp_class_get_field_from_name_t)(void* klass, const char* name);
    typedef void* (*il2cpp_class_get_fields_t)(void* klass, void** iter);
    typedef const char* (*il2cpp_field_get_name_t)(void* field);
    typedef size_t (*il2cpp_field_get_offset_t)(void* field);

    auto p_get_field = (il2cpp_class_get_field_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_field_from_name");
    auto p_get_fields = (il2cpp_class_get_fields_t)GetProcAddress(hGA, "il2cpp_class_get_fields");
    auto p_get_name = (il2cpp_field_get_name_t)GetProcAddress(hGA, "il2cpp_field_get_name");
    auto p_get_offset = (il2cpp_field_get_offset_t)GetProcAddress(hGA, "il2cpp_field_get_offset");

    if (p_get_fields && p_get_name && p_get_offset) {
        void* iter = nullptr;
        void* f = nullptr;
        while ((f = p_get_fields(klassGC, &iter)) != nullptr) {
            const char* name = p_get_name(f);
            size_t off = p_get_offset(f);
            if (!name) continue;
            if (strcmp(name, "m_Chip") == 0) { s_off_m_Chip = off; s_GCOffsetsResolved = true; }
            else if (strcmp(name, "m_SuperChip") == 0) s_off_m_SuperChip = off;
            else if (strcmp(name, "m_Gem") == 0) s_off_m_Gem = off;
            else if (strcmp(name, "m_Gold") == 0) s_off_m_Gold = off;
            else if (strcmp(name, "dataSender") == 0) s_off_dataSender = off;
        }
    } else if (p_get_field && p_get_offset) {
        void* fChip = p_get_field(klassGC, "m_Chip");
        if (fChip) s_off_m_Chip = p_get_offset(fChip);

        void* fSuperChip = p_get_field(klassGC, "m_SuperChip");
        if (fSuperChip) s_off_m_SuperChip = p_get_offset(fSuperChip);

        void* fGem = p_get_field(klassGC, "m_Gem");
        if (fGem) s_off_m_Gem = p_get_offset(fGem);

        void* fGold = p_get_field(klassGC, "m_Gold");
        if (fGold) s_off_m_Gold = p_get_offset(fGold);

        void* fDS = p_get_field(klassGC, "dataSender");
        if (fDS) s_off_dataSender = p_get_offset(fDS);
        s_GCOffsetsResolved = true;
    }
}

void InitIL2CPP() {
    MH_Initialize();
    EnsureIL2CPPThreadAttached();
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) return;

    typedef void* (*il2cpp_resolve_icall_t)(const char*);
    il2cpp_resolve_icall_t resolve_icall = (il2cpp_resolve_icall_t)GetProcAddress(hGA, "il2cpp_resolve_icall");
    if (resolve_icall) {
        if (!g_set_timeScale) {
            g_set_timeScale = (set_timeScale_t)resolve_icall("UnityEngine.Time::set_timeScale(System.Single)");
            g_get_timeScale = (get_timeScale_t)resolve_icall("UnityEngine.Time::get_timeScale()");

            char buf[256];
            sprintf(buf, "Resolved UnityEngine.Time::set_timeScale at %p, get_timeScale at %p", g_set_timeScale, g_get_timeScale);
            LogDaniel(buf);

            if (g_set_timeScale && !o_set_timeScale) {
                MH_STATUS st = MH_CreateHook((LPVOID)g_set_timeScale, (LPVOID)&Hooked_set_timeScale, (LPVOID*)&o_set_timeScale);
                if (st == MH_OK) {
                    MH_EnableHook((LPVOID)g_set_timeScale);
                    LogDaniel("Hooked UnityEngine.Time::set_timeScale successfully! Speed lock ACTIVE!");
                }
            }
        }

        if (!g_set_targetFrameRate) {
            g_set_targetFrameRate = (set_targetFrameRate_t)resolve_icall("UnityEngine.Application::set_targetFrameRate(System.Int32)");
            g_get_targetFrameRate = (get_targetFrameRate_t)resolve_icall("UnityEngine.Application::get_targetFrameRate()");

            char buf[256];
            sprintf(buf, "Resolved UnityEngine.Application::set_targetFrameRate at %p, get_targetFrameRate at %p", g_set_targetFrameRate, g_get_targetFrameRate);
            LogDaniel(buf);

            if (g_set_targetFrameRate && !o_set_targetFrameRate) {
                MH_STATUS st = MH_CreateHook((LPVOID)g_set_targetFrameRate, (LPVOID)&Hooked_set_targetFrameRate, (LPVOID*)&o_set_targetFrameRate);
                if (st == MH_OK) {
                    MH_EnableHook((LPVOID)g_set_targetFrameRate);
                    LogDaniel("Hooked UnityEngine.Application::set_targetFrameRate successfully! FPS Cap ACTIVE!");
                    o_set_targetFrameRate(g_TargetFPS);
                }
            }
        }
    }

    uintptr_t gaBase = (uintptr_t)hGA;

    // 1. Hook EventSystem::Update (Unity main thread loop) at RVA 0x20D3200
    pfn_EventSystem_Update = (EventSystem_Update_t)(gaBase + 0x20D3200);
    if (pfn_EventSystem_Update && !o_EventSystem_Update) {
        if (MH_CreateHook((LPVOID)pfn_EventSystem_Update, (LPVOID)&Hooked_EventSystem_Update, (LPVOID*)&o_EventSystem_Update) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_EventSystem_Update);
            LogDaniel("Hooked EventSystem::Update successfully (Main Thread Loop)!");
        }
    }

    // 2. Resolve native GameAssembly.dll RVAs for Chiêu Mộ
    pfn_BoxOrbSummon_Start = (BoxOrbSummon_Start_t)(gaBase + 0x4F3D50);
    pfn_ButtonSummon10Click = (BoxOrbSummon_ButtonSummon10Click_t)(gaBase + 0x4F3800);
    pfn_ButtonSummon1Click = (BoxOrbSummon_ButtonSummon1Click_t)(gaBase + 0x4F3910);
    pfn_OnFactionSelected = (BoxOrbSummon_OnFactionSelected_t)(gaBase + 0x4F3A60);
    pfn_BoxOrbSummon_ProcessKEvent = (BoxOrbSummon_ProcessKEvent_t)(gaBase + 0x4F3C00);

    // 3. PopupBlockTouch (SetDurationBlock at RVA 0x366C70)
    pfn_PopupBlockTouch_SetDurationBlock = (PopupBlockTouch_SetDurationBlock_t)(gaBase + 0x366C70);

    // 4. PopupShowBonusEffect2 (ShowUp at 0x374310, ButtonCloseClick at 0x373C10)
    pfn_PopupShowBonusEffect2_ShowUp = (PopupShowBonusEffect2_ShowUp_t)(gaBase + 0x374310);
    pfn_PopupShowBonusEffect2_ButtonCloseClick = (PopupShowBonusEffect2_ButtonCloseClick_t)(gaBase + 0x373C10);

    if (pfn_BoxOrbSummon_Start && !o_BoxOrbSummon_Start) {
        if (MH_CreateHook((LPVOID)pfn_BoxOrbSummon_Start, (LPVOID)&Hooked_BoxOrbSummon_Start, (LPVOID*)&o_BoxOrbSummon_Start) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_BoxOrbSummon_Start);
            LogDaniel("Hooked BoxOrbSummon::Start successfully!");
        }
    }

    if (pfn_BoxOrbSummon_ProcessKEvent && !o_BoxOrbSummon_ProcessKEvent) {
        if (MH_CreateHook((LPVOID)pfn_BoxOrbSummon_ProcessKEvent, (LPVOID)&Hooked_BoxOrbSummon_ProcessKEvent, (LPVOID*)&o_BoxOrbSummon_ProcessKEvent) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_BoxOrbSummon_ProcessKEvent);
            LogDaniel("Hooked BoxOrbSummon::ProcessKEvent successfully!");
        }
    }

    if (pfn_PopupShowBonusEffect2_ShowUp && !o_PopupShowBonusEffect2_ShowUp) {
        if (MH_CreateHook((LPVOID)pfn_PopupShowBonusEffect2_ShowUp, (LPVOID)&Hooked_PopupShowBonusEffect2_ShowUp, (LPVOID*)&o_PopupShowBonusEffect2_ShowUp) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_PopupShowBonusEffect2_ShowUp);
            LogDaniel("Hooked PopupShowBonusEffect2::ShowUp successfully!");
        }
    }

    if (pfn_PopupBlockTouch_SetDurationBlock && !o_PopupBlockTouch_SetDurationBlock) {
        if (MH_CreateHook((LPVOID)pfn_PopupBlockTouch_SetDurationBlock, (LPVOID)&Hooked_PopupBlockTouch_SetDurationBlock, (LPVOID*)&o_PopupBlockTouch_SetDurationBlock) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_PopupBlockTouch_SetDurationBlock);
            LogDaniel("Hooked PopupBlockTouch::SetDurationBlock successfully!");
        }
    }

    pfn_RevealRemainItemOneByOne_MoveNext = (RevealRemainItemOneByOne_MoveNext_t)(gaBase + 0x381630);
    if (pfn_RevealRemainItemOneByOne_MoveNext && !o_RevealRemainItemOneByOne_MoveNext) {
        if (MH_CreateHook((LPVOID)pfn_RevealRemainItemOneByOne_MoveNext, (LPVOID)&Hooked_RevealRemainItemOneByOne_MoveNext, (LPVOID*)&o_RevealRemainItemOneByOne_MoveNext) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_RevealRemainItemOneByOne_MoveNext);
            LogDaniel("Hooked RevealRemainItemOneByOne::MoveNext successfully (Instant Card Reveal)!");
        }
    }

    // 5. Resolve native GameAssembly.dll RVAs for Vòng Quay (LuckySpin & SuperLuckySpin)
    pfn_LuckySpinScene_Start = (LuckySpinScene_Start_t)(gaBase + 0x496E20);
    pfn_LuckySpinScene_ButtonSpin10Click = (LuckySpinScene_ButtonSpin10Click_t)(gaBase + 0x495960);
    pfn_LuckySpinScene_ButtonSpin1Click = (LuckySpinScene_ButtonSpin1Click_t)(gaBase + 0x4959B0);
    pfn_LuckySpinScene_ButtonRefreshClick = (LuckySpinScene_ButtonRefreshClick_t)(gaBase + 0x495860);
    pfn_LuckySpinScene_DelayShowBoxSpin = (LuckySpinScene_DelayShowBoxSpin_t)(gaBase + 0x495A90);

    pfn_SuperLuckySpinScene_Start = (SuperLuckySpinScene_Start_t)(gaBase + 0x49FE40);
    pfn_SuperLuckySpinScene_ButtonSpin10Click = (SuperLuckySpinScene_ButtonSpin10Click_t)(gaBase + 0x49EA10);
    pfn_SuperLuckySpinScene_ButtonSpin1Click = (SuperLuckySpinScene_ButtonSpin1Click_t)(gaBase + 0x49EA60);
    pfn_SuperLuckySpinScene_ButtonRefreshClick = (SuperLuckySpinScene_ButtonRefreshClick_t)(gaBase + 0x49E9D0);
    pfn_SuperLuckySpinScene_DelayShowBoxSpin = (SuperLuckySpinScene_DelayShowBoxSpin_t)(gaBase + 0x49EB40);

    pfn_SpinDisk_IsOnSpinToShowResult = (SpinDisk_IsOnSpinToShowResult_t)(gaBase + 0x49D1D0);
    pfn_SpinDisk_Update = (SpinDisk_Update_t)(gaBase + 0x49D770);

    // 6. Resolve native GameAssembly.dll RVAs for DataSender, PlayerInventory and GameContext
    pfn_DataSender_LuckyRotate = (DataSender_LuckyRotate_t)(gaBase + 0x4C7330);
    pfn_DataSender_SuperLuckySpinRotate = (DataSender_SuperLuckySpinRotate_t)(gaBase + 0x4CC710);
    pfn_DataSender_LuckyRefresh = (DataSender_LuckyRefresh_t)(gaBase + 0x4C72D0);
    pfn_DataSender_SuperLuckySpinRefresh = (DataSender_SuperLuckySpinRefresh_t)(gaBase + 0x4CC6E0);
    pfn_DataSender_LuckyBuyChip = (DataSender_LuckyBuyChip_t)(gaBase + 0x4C71F0);
    pfn_PlayerInventory_GetNumberItemConsumable = (PlayerInventory_GetNumberItemConsumable_t)(gaBase + 0x363340);
    pfn_GameContext_GetIntance = (GameContext_GetIntance_t)(gaBase + 0x356AE0);
    pfn_PlayerInventory_GetInstance = (PlayerInventory_GetInstance_t)(gaBase + 0x362D60);

    // Dynamic resolution via IL2CPP reflection
    static il2cpp_domain_get_t p_domain_get_fn = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    static il2cpp_domain_assembly_open_t p_assembly_open_fn = (il2cpp_domain_assembly_open_t)GetProcAddress(hGA, "il2cpp_domain_assembly_open");
    static il2cpp_assembly_get_image_t p_assembly_get_image_fn = (il2cpp_assembly_get_image_t)GetProcAddress(hGA, "il2cpp_assembly_get_image");
    static il2cpp_class_from_name_t p_class_from_name_fn = (il2cpp_class_from_name_t)GetProcAddress(hGA, "il2cpp_class_from_name");
    static il2cpp_class_get_method_from_name_t p_class_get_method_fn = (il2cpp_class_get_method_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_method_from_name");

    if (p_domain_get_fn && p_assembly_open_fn && p_assembly_get_image_fn && p_class_from_name_fn && p_class_get_method_fn) {
        void* dom = p_domain_get_fn();
        if (dom) {
            void* aCS = p_assembly_open_fn(dom, "Assembly-CSharp");
            if (!aCS) aCS = p_assembly_open_fn(dom, "Assembly-CSharp.dll");
            if (aCS) {
                void* iCS = p_assembly_get_image_fn(aCS);
                if (iCS) {
                    void* klLucky = p_class_from_name_fn(iCS, "", "LuckySpinScene");
                    if (klLucky) {
                        void* mUp = p_class_get_method_fn(klLucky, "Update", 0);
                        if (mUp) pfn_LuckySpinScene_Update = (LuckySpinScene_Update_t)(*(void**)mUp);
                        void* mS10 = p_class_get_method_fn(klLucky, "ButtonSpin10Click", 0);
                        if (mS10) pfn_LuckySpinScene_ButtonSpin10Click = (LuckySpinScene_ButtonSpin10Click_t)(*(void**)mS10);
                        void* mRef = p_class_get_method_fn(klLucky, "ButtonRefreshClick", 0);
                        if (mRef) pfn_LuckySpinScene_ButtonRefreshClick = (LuckySpinScene_ButtonRefreshClick_t)(*(void**)mRef);
                    }
                    void* klSupLucky = p_class_from_name_fn(iCS, "", "SuperLuckySpinScene");
                    if (klSupLucky) {
                        void* mUp = p_class_get_method_fn(klSupLucky, "Update", 0);
                        if (mUp) pfn_SuperLuckySpinScene_Update = (SuperLuckySpinScene_Update_t)(*(void**)mUp);
                        void* mS10 = p_class_get_method_fn(klSupLucky, "ButtonSpin10Click", 0);
                        if (mS10) pfn_SuperLuckySpinScene_ButtonSpin10Click = (SuperLuckySpinScene_ButtonSpin10Click_t)(*(void**)mS10);
                        void* mRef = p_class_get_method_fn(klSupLucky, "ButtonRefreshClick", 0);
                        if (mRef) pfn_SuperLuckySpinScene_ButtonRefreshClick = (SuperLuckySpinScene_ButtonRefreshClick_t)(*(void**)mRef);
                    }
                    void* klDS = p_class_from_name_fn(iCS, "", "DataSender");
                    if (klDS) {
                        void* mRot = p_class_get_method_fn(klDS, "LuckyRotate", 1);
                        if (mRot) pfn_DataSender_LuckyRotate = (DataSender_LuckyRotate_t)(*(void**)mRot);
                        void* mSRot = p_class_get_method_fn(klDS, "SuperLuckySpinRotate", 1);
                        if (mSRot) pfn_DataSender_SuperLuckySpinRotate = (DataSender_SuperLuckySpinRotate_t)(*(void**)mSRot);
                        void* mRef = p_class_get_method_fn(klDS, "LuckyRefresh", 0);
                        if (mRef) pfn_DataSender_LuckyRefresh = (DataSender_LuckyRefresh_t)(*(void**)mRef);
                        void* mSRef = p_class_get_method_fn(klDS, "SuperLuckySpinRefresh", 0);
                        if (mSRef) pfn_DataSender_SuperLuckySpinRefresh = (DataSender_SuperLuckySpinRefresh_t)(*(void**)mSRef);
                        void* mBuy = p_class_get_method_fn(klDS, "LuckyBuyChip", 1);
                        if (mBuy) pfn_DataSender_LuckyBuyChip = (DataSender_LuckyBuyChip_t)(*(void**)mBuy);
                    }
                    void* klGC = p_class_from_name_fn(iCS, "", "GameContext");
                    if (klGC) {
                        ResolveGameContextOffsets(klGC, hGA);
                        LogDaniel("Resolved GameContext offsets dynamically via IL2CPP metadata!");
                    }
                }
            }
        }
    }

    if (pfn_LuckySpinScene_Start && !o_LuckySpinScene_Start) {
        if (MH_CreateHook((LPVOID)pfn_LuckySpinScene_Start, (LPVOID)&Hooked_LuckySpinScene_Start, (LPVOID*)&o_LuckySpinScene_Start) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_LuckySpinScene_Start);
            LogDaniel("Hooked LuckySpinScene::Start successfully!");
        }
    }

    if (pfn_SuperLuckySpinScene_Start && !o_SuperLuckySpinScene_Start) {
        if (MH_CreateHook((LPVOID)pfn_SuperLuckySpinScene_Start, (LPVOID)&Hooked_SuperLuckySpinScene_Start, (LPVOID*)&o_SuperLuckySpinScene_Start) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_SuperLuckySpinScene_Start);
            LogDaniel("Hooked SuperLuckySpinScene::Start successfully!");
        }
    }

    if (pfn_SpinDisk_Update && !o_SpinDisk_Update) {
        if (MH_CreateHook((LPVOID)pfn_SpinDisk_Update, (LPVOID)&Hooked_SpinDisk_Update, (LPVOID*)&o_SpinDisk_Update) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_SpinDisk_Update);
            LogDaniel("Hooked SpinDisk::Update successfully! Live wheel instance capture ACTIVE!");
        }
    }

    if (pfn_SpinDisk_IsOnSpinToShowResult && !o_SpinDisk_IsOnSpinToShowResult) {
        if (MH_CreateHook((LPVOID)pfn_SpinDisk_IsOnSpinToShowResult, (LPVOID)&Hooked_SpinDisk_IsOnSpinToShowResult, (LPVOID*)&o_SpinDisk_IsOnSpinToShowResult) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_SpinDisk_IsOnSpinToShowResult);
            LogDaniel("Hooked SpinDisk::IsOnSpinToShowResult successfully!");
        }
    }

    if (pfn_LuckySpinScene_Update && !o_LuckySpinScene_Update) {
        if (MH_CreateHook((LPVOID)pfn_LuckySpinScene_Update, (LPVOID)&Hooked_LuckySpinScene_Update, (LPVOID*)&o_LuckySpinScene_Update) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_LuckySpinScene_Update);
            LogDaniel("Hooked LuckySpinScene::Update successfully! Continuous scene capture ACTIVE!");
        }
    }

    if (pfn_SuperLuckySpinScene_Update && !o_SuperLuckySpinScene_Update) {
        if (MH_CreateHook((LPVOID)pfn_SuperLuckySpinScene_Update, (LPVOID)&Hooked_SuperLuckySpinScene_Update, (LPVOID*)&o_SuperLuckySpinScene_Update) == MH_OK) {
            MH_EnableHook((LPVOID)pfn_SuperLuckySpinScene_Update);
            LogDaniel("Hooked SuperLuckySpinScene::Update successfully! Continuous scene capture ACTIVE!");
        }
    }
}

static ULONGLONG s_lastSummonTime = 0;

static void RotateToNextFaction() {
    if (!pfn_OnFactionSelected || !g_pBoxOrbSummon) return;
    int curIdx = 0;
    for (int i = 0; i < 4; i++) {
        if (s_RotateFactionIds[i] == g_SelectedFactionId) {
            curIdx = i;
            break;
        }
    }
    int nextIdx = (curIdx + 1) % 4;
    g_SelectedFactionId = s_RotateFactionIds[nextIdx];
    __try {
        pfn_OnFactionSelected(g_pBoxOrbSummon, g_SelectedFactionId, nullptr);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogDaniel("Exception in OnFactionSelected!");
    }
}

typedef void* (*il2cpp_domain_get_t)();
typedef void* (*il2cpp_domain_assembly_open_t)(void* domain, const char* name);
typedef void* (*il2cpp_assembly_get_image_t)(void* assembly);
typedef void* (*il2cpp_class_from_name_t)(void* image, const char* namespaze, const char* name);
typedef void* (*il2cpp_class_get_method_from_name_t)(void* klass, const char* name, int argsCount);
typedef void* (*il2cpp_string_new_t)(const char* str);
typedef void* (*il2cpp_runtime_invoke_t)(void* method, void* obj, void** params, void** exc);
typedef void* (*il2cpp_object_get_class_t)(void* obj);
typedef void* (*il2cpp_class_get_field_from_name_t)(void* klass, const char* name);
typedef void* (*il2cpp_class_get_fields_t)(void* klass, void** iter);
typedef const char* (*il2cpp_field_get_name_t)(void* field);
typedef void (*il2cpp_field_get_value_t)(void* obj, void* field, void* value);



void* GetGameContextInstance() {
    EnsureIL2CPPThreadAttached();
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) return nullptr;
    uintptr_t gaBase = (uintptr_t)hGA;

    if (!pfn_GameContext_GetIntance) {
        pfn_GameContext_GetIntance = (GameContext_GetIntance_t)(gaBase + 0x356AE0);
    }

    // 1. Direct native RVA call (0x356AE0) - fastest and 100% reliable
    if (pfn_GameContext_GetIntance) {
        __try {
            void* inst = pfn_GameContext_GetIntance(nullptr);
            if (inst && IsValidMemoryPtr(inst)) return inst;
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }

    // 2. Direct static pointer from GameContext__TypeInfo at RVA 0x29A12C0
    __try {
        void** ppTypeInfo = (void**)(gaBase + 0x29A12C0);
        if (ppTypeInfo && IsValidMemoryPtr(ppTypeInfo) && *ppTypeInfo) {
            void* typeInfo = *ppTypeInfo;
            if (IsValidMemoryPtr(typeInfo)) {
                void* staticFields = *(void**)((uintptr_t)typeInfo + 0xB8);
                if (staticFields && IsValidMemoryPtr(staticFields)) {
                    void* inst = *(void**)staticFields; // m_Instance at offset 0
                    if (inst && IsValidMemoryPtr(inst)) return inst;
                }
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {}

    // 3. IL2CPP Dynamic Reflection fallback
    static il2cpp_domain_get_t p_domain_get = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    static il2cpp_domain_assembly_open_t p_assembly_open = (il2cpp_domain_assembly_open_t)GetProcAddress(hGA, "il2cpp_domain_assembly_open");
    static il2cpp_assembly_get_image_t p_assembly_get_image = (il2cpp_assembly_get_image_t)GetProcAddress(hGA, "il2cpp_assembly_get_image");
    static il2cpp_class_from_name_t p_class_from_name = (il2cpp_class_from_name_t)GetProcAddress(hGA, "il2cpp_class_from_name");
    static il2cpp_class_get_method_from_name_t p_class_get_method = (il2cpp_class_get_method_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_method_from_name");
    static il2cpp_runtime_invoke_t p_runtime_invoke = (il2cpp_runtime_invoke_t)GetProcAddress(hGA, "il2cpp_runtime_invoke");
    typedef void* (*il2cpp_class_get_field_from_name_t)(void* klass, const char* name);
    typedef void (*il2cpp_field_static_get_value_t)(void* field, void* value);
    static auto p_get_field = (il2cpp_class_get_field_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_field_from_name");
    static auto p_static_get_value = (il2cpp_field_static_get_value_t)GetProcAddress(hGA, "il2cpp_field_static_get_value");

    static void* klassGC = nullptr;
    static void* methodGetIntance = nullptr;
    static void* fieldGCInstance = nullptr;

    if (!klassGC && p_domain_get && p_assembly_open && p_assembly_get_image && p_class_from_name) {
        void* domain = p_domain_get();
        if (domain) {
            void* assy = p_assembly_open(domain, "Assembly-CSharp");
            if (!assy) assy = p_assembly_open(domain, "Assembly-CSharp.dll");
            if (assy) {
                void* img = p_assembly_get_image(assy);
                if (img) {
                    klassGC = p_class_from_name(img, "", "GameContext");
                    if (klassGC) {
                        ResolveGameContextOffsets(klassGC, hGA);
                        if (p_class_get_method) {
                            methodGetIntance = p_class_get_method(klassGC, "GetIntance", 0);
                            if (!methodGetIntance) methodGetIntance = p_class_get_method(klassGC, "GetInstance", 0);
                        }
                        if (p_get_field) {
                            fieldGCInstance = p_get_field(klassGC, "m_Instance");
                            if (!fieldGCInstance) fieldGCInstance = p_get_field(klassGC, "instance");
                        }
                    }
                }
            }
        }
    }

    if (klassGC) {
        if (methodGetIntance && p_runtime_invoke) {
            void* exc = nullptr;
            void* inst = p_runtime_invoke(methodGetIntance, nullptr, nullptr, &exc);
            if (inst && !exc && IsValidMemoryPtr(inst)) return inst;
        }
        if (fieldGCInstance && p_static_get_value) {
            void* inst = nullptr;
            p_static_get_value(fieldGCInstance, &inst);
            if (inst && IsValidMemoryPtr(inst)) return inst;
        }
    }
    return nullptr;
}

void* GetPlayerInventoryInstance() {
    EnsureIL2CPPThreadAttached();
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) return nullptr;
    uintptr_t gaBase = (uintptr_t)hGA;

    if (!pfn_PlayerInventory_GetInstance) {
        pfn_PlayerInventory_GetInstance = (PlayerInventory_GetInstance_t)(gaBase + 0x362D60);
    }
    if (!pfn_PlayerInventory_GetNumberItemConsumable) {
        pfn_PlayerInventory_GetNumberItemConsumable = (PlayerInventory_GetNumberItemConsumable_t)(gaBase + 0x363340);
    }

    // 1. Direct native RVA call (0x362D60)
    if (pfn_PlayerInventory_GetInstance) {
        __try {
            void* inst = pfn_PlayerInventory_GetInstance(nullptr);
            if (inst && IsValidMemoryPtr(inst)) return inst;
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }

    // 2. Direct static pointer from PlayerInventory__TypeInfo at RVA 0x2973548
    __try {
        void** ppTypeInfo = (void**)(gaBase + 0x2973548);
        if (ppTypeInfo && IsValidMemoryPtr(ppTypeInfo) && *ppTypeInfo) {
            void* typeInfo = *ppTypeInfo;
            if (IsValidMemoryPtr(typeInfo)) {
                void* staticFields = *(void**)((uintptr_t)typeInfo + 0xB8);
                if (staticFields && IsValidMemoryPtr(staticFields)) {
                    void* inst = *(void**)staticFields; // m_Instance
                    if (inst && IsValidMemoryPtr(inst)) return inst;
                }
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {}

    // 3. IL2CPP Dynamic Reflection fallback
    static il2cpp_domain_get_t p_domain_get = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    static il2cpp_domain_assembly_open_t p_assembly_open = (il2cpp_domain_assembly_open_t)GetProcAddress(hGA, "il2cpp_domain_assembly_open");
    static il2cpp_assembly_get_image_t p_assembly_get_image = (il2cpp_assembly_get_image_t)GetProcAddress(hGA, "il2cpp_assembly_get_image");
    static il2cpp_class_from_name_t p_class_from_name = (il2cpp_class_from_name_t)GetProcAddress(hGA, "il2cpp_class_from_name");
    static il2cpp_class_get_method_from_name_t p_class_get_method = (il2cpp_class_get_method_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_method_from_name");
    static il2cpp_runtime_invoke_t p_runtime_invoke = (il2cpp_runtime_invoke_t)GetProcAddress(hGA, "il2cpp_runtime_invoke");
    typedef void* (*il2cpp_class_get_field_from_name_t)(void* klass, const char* name);
    typedef void (*il2cpp_field_static_get_value_t)(void* field, void* value);
    static auto p_get_field = (il2cpp_class_get_field_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_field_from_name");
    static auto p_static_get_value = (il2cpp_field_static_get_value_t)GetProcAddress(hGA, "il2cpp_field_static_get_value");

    static void* klassInv = nullptr;
    static void* methodInvGetInstance = nullptr;
    static void* fieldInvInstance = nullptr;

    if (!klassInv && p_domain_get && p_assembly_open && p_assembly_get_image && p_class_from_name) {
        void* domain = p_domain_get();
        if (domain) {
            void* assy = p_assembly_open(domain, "Assembly-CSharp");
            if (!assy) assy = p_assembly_open(domain, "Assembly-CSharp.dll");
            if (assy) {
                void* img = p_assembly_get_image(assy);
                if (img) {
                    klassInv = p_class_from_name(img, "", "PlayerInventory");
                    if (klassInv) {
                        if (p_class_get_method) {
                            methodInvGetInstance = p_class_get_method(klassInv, "GetInstance", 0);
                        }
                        if (p_get_field) {
                            fieldInvInstance = p_get_field(klassInv, "m_Instance");
                            if (!fieldInvInstance) fieldInvInstance = p_get_field(klassInv, "instance");
                        }
                    }
                }
            }
        }
    }

    if (klassInv) {
        if (methodInvGetInstance && p_runtime_invoke) {
            void* exc = nullptr;
            void* inst = p_runtime_invoke(methodInvGetInstance, nullptr, nullptr, &exc);
            if (inst && !exc && IsValidMemoryPtr(inst)) return inst;
        }
        if (fieldInvInstance && p_static_get_value) {
            void* inst = nullptr;
            p_static_get_value(fieldInvInstance, &inst);
            if (inst && IsValidMemoryPtr(inst)) return inst;
        }
    }
    return nullptr;
}

void* GetDataSender() {
    EnsureIL2CPPThreadAttached();
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (hGA) {
        uintptr_t gaBase = (uintptr_t)hGA;
        if (!pfn_DataSender_LuckyRotate) pfn_DataSender_LuckyRotate = (DataSender_LuckyRotate_t)(gaBase + 0x4C7330);
        if (!pfn_DataSender_SuperLuckySpinRotate) pfn_DataSender_SuperLuckySpinRotate = (DataSender_SuperLuckySpinRotate_t)(gaBase + 0x4CC710);
        if (!pfn_DataSender_LuckyRefresh) pfn_DataSender_LuckyRefresh = (DataSender_LuckyRefresh_t)(gaBase + 0x4C72D0);
        if (!pfn_DataSender_SuperLuckySpinRefresh) pfn_DataSender_SuperLuckySpinRefresh = (DataSender_SuperLuckySpinRefresh_t)(gaBase + 0x4CC6E0);
        if (!pfn_DataSender_LuckyBuyChip) pfn_DataSender_LuckyBuyChip = (DataSender_LuckyBuyChip_t)(gaBase + 0x4C71F0);
    }
    void* pGC = GetGameContextInstance();
    if (pGC && IsValidMemoryPtr(pGC)) {
        __try {
            void* ds = *(void**)((uintptr_t)pGC + s_off_dataSender);
            if (IsValidMemoryPtr(ds)) return ds;
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }
    if (g_pLuckySpinScene && IsLuckySpinValid()) {
        __try {
            void* ds = *(void**)((uintptr_t)g_pLuckySpinScene + 0x20);
            if (IsValidMemoryPtr(ds)) return ds;
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }
    if (g_pSuperLuckySpinScene && IsSuperLuckySpinValid()) {
        __try {
            void* ds = *(void**)((uintptr_t)g_pSuperLuckySpinScene + 0x20);
            if (IsValidMemoryPtr(ds)) return ds;
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }
    return nullptr;
}

static void UpdateLiveCurrencies() {
    EnsureIL2CPPThreadAttached();
    ULONGLONG now = GetTickCount64();
    if (now - s_lastCurrencyUpdate < 100) return;
    s_lastCurrencyUpdate = now;

    int64_t gcGold = -1, gcGem = -1, gcChip = -1, gcSuperChip = -1, gcLuckCoin = -1;
    void* pGC = GetGameContextInstance();
    if (pGC && IsValidMemoryPtr(pGC)) {
        __try {
            gcGold = *(int64_t*)((uintptr_t)pGC + s_off_m_Gold);
            gcGem = *(int64_t*)((uintptr_t)pGC + s_off_m_Gem);
            gcChip = *(int64_t*)((uintptr_t)pGC + s_off_m_Chip);
            gcSuperChip = *(int64_t*)((uintptr_t)pGC + s_off_m_SuperChip);
            gcLuckCoin = *(int64_t*)((uintptr_t)pGC + 0x138); // m_LuckCoin (Xu Vòng Quay Thường)
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }

    if (gcGem >= 0) g_RealGem = gcGem;
    if (gcGold >= 0) g_RealGold = gcGold;

    int64_t invChip = -1, invSuperChip = -1, fruitCoin = -1;
    void* pInv = GetPlayerInventoryInstance();
    if (pInv && IsValidMemoryPtr(pInv)) {
        __try {
            if (pfn_PlayerInventory_GetNumberItemConsumable) {
                invChip = pfn_PlayerInventory_GetNumberItemConsumable(pInv, 10, nullptr);
                invSuperChip = pfn_PlayerInventory_GetNumberItemConsumable(pInv, 13, nullptr);
                int32_t fKey = (g_FruitWheelMode == 2) ? 102 : 101;
                fruitCoin = pfn_PlayerInventory_GetNumberItemConsumable(pInv, fKey, nullptr);
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
    }

    if (fruitCoin >= 0) g_RealFruitCoin = fruitCoin;

    int64_t bestNormal = -1;
    if (gcLuckCoin >= 0) bestNormal = gcLuckCoin;
    if (gcChip > bestNormal) bestNormal = gcChip;
    if (invChip > bestNormal) bestNormal = invChip;

    int64_t bestSuper = -1;
    if (gcSuperChip >= 0) bestSuper = gcSuperChip;
    if (invSuperChip > bestSuper) bestSuper = invSuperChip;

    if (g_WheelMode == 1) {
        if (bestSuper >= 0) g_RealXu = bestSuper;
    } else {
        if (bestNormal >= 0) g_RealXu = bestNormal;
    }
}

void* FindActiveSceneObject(const char* className) {
    EnsureIL2CPPThreadAttached();
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) return nullptr;

    static il2cpp_domain_get_t p_domain_get = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    static il2cpp_domain_assembly_open_t p_assembly_open = (il2cpp_domain_assembly_open_t)GetProcAddress(hGA, "il2cpp_domain_assembly_open");
    static il2cpp_assembly_get_image_t p_assembly_get_image = (il2cpp_assembly_get_image_t)GetProcAddress(hGA, "il2cpp_assembly_get_image");
    static il2cpp_class_from_name_t p_class_from_name = (il2cpp_class_from_name_t)GetProcAddress(hGA, "il2cpp_class_from_name");
    static il2cpp_class_get_method_from_name_t p_class_get_method = (il2cpp_class_get_method_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_method_from_name");
    static il2cpp_runtime_invoke_t p_runtime_invoke = (il2cpp_runtime_invoke_t)GetProcAddress(hGA, "il2cpp_runtime_invoke");
    typedef void* (*il2cpp_type_get_object_t)(void* type);
    typedef void* (*il2cpp_class_get_type_t)(void* klass);
    static auto p_type_get_object = (il2cpp_type_get_object_t)GetProcAddress(hGA, "il2cpp_type_get_object");
    static auto p_class_get_type = (il2cpp_class_get_type_t)GetProcAddress(hGA, "il2cpp_class_get_type");

    if (!p_domain_get || !p_assembly_open || !p_assembly_get_image || !p_class_from_name ||
        !p_class_get_method || !p_runtime_invoke || !p_type_get_object || !p_class_get_type) {
        return nullptr;
    }

    __try {
        void* domain = p_domain_get();
        if (!domain) return nullptr;

        void* asmCS = p_assembly_open(domain, "Assembly-CSharp");
        if (!asmCS) asmCS = p_assembly_open(domain, "Assembly-CSharp.dll");
        if (!asmCS) return nullptr;
        void* imgCS = p_assembly_get_image(asmCS);
        if (!imgCS) return nullptr;

        void* klassTarget = p_class_from_name(imgCS, "", className);
        if (!klassTarget) return nullptr;
        void* typeTarget = p_class_get_type(klassTarget);
        if (!typeTarget) return nullptr;
        void* typeObj = p_type_get_object(typeTarget);
        if (!typeObj) return nullptr;

        void* asmCore = p_assembly_open(domain, "UnityEngine.CoreModule");
        if (!asmCore) asmCore = p_assembly_open(domain, "UnityEngine.CoreModule.dll");
        if (asmCore) {
            void* imgCore = p_assembly_get_image(asmCore);
            if (imgCore) {
                void* klassObj = p_class_from_name(imgCore, "UnityEngine", "Object");
                if (klassObj) {
                    // Try 1: FindObjectOfType(1)
                    void* m1 = p_class_get_method(klassObj, "FindObjectOfType", 1);
                    if (m1) {
                        void* args[1] = { typeObj };
                        void* exc = nullptr;
                        void* res = p_runtime_invoke(m1, nullptr, args, &exc);
                        if (res && !exc && IsValidMemoryPtr(res)) return res;
                    }
                    // Try 2: FindFirstObjectByType(1)
                    void* m2 = p_class_get_method(klassObj, "FindFirstObjectByType", 1);
                    if (m2) {
                        void* args[1] = { typeObj };
                        void* exc = nullptr;
                        void* res = p_runtime_invoke(m2, nullptr, args, &exc);
                        if (res && !exc && IsValidMemoryPtr(res)) return res;
                    }
                    // Try 3: FindObjectOfType(2)
                    void* m3 = p_class_get_method(klassObj, "FindObjectOfType", 2);
                    if (m3) {
                        bool bTrue = true;
                        void* args[2] = { typeObj, &bTrue };
                        void* exc = nullptr;
                        void* res = p_runtime_invoke(m3, nullptr, args, &exc);
                        if (res && !exc && IsValidMemoryPtr(res)) return res;
                    }
                    // Try 4: FindAnyObjectByType(1)
                    void* m4 = p_class_get_method(klassObj, "FindAnyObjectByType", 1);
                    if (m4) {
                        void* args[1] = { typeObj };
                        void* exc = nullptr;
                        void* res = p_runtime_invoke(m4, nullptr, args, &exc);
                        if (res && !exc && IsValidMemoryPtr(res)) return res;
                    }
                }

                // Try 5: GameObject.Find(className)->GetComponent(className)
                void* klassGO = p_class_from_name(imgCore, "UnityEngine", "GameObject");
                if (klassGO) {
                    void* mFind = p_class_get_method(klassGO, "Find", 1);
                    static auto p_string_new = (il2cpp_string_new_t)GetProcAddress(hGA, "il2cpp_string_new");
                    if (mFind && p_string_new) {
                        void* strObj = p_string_new(className);
                        void* args[1] = { strObj };
                        void* exc = nullptr;
                        void* go = p_runtime_invoke(mFind, nullptr, args, &exc);
                        if (go && !exc && IsValidMemoryPtr(go)) {
                            void* mGetComp = p_class_get_method(klassGO, "GetComponent", 1);
                            if (mGetComp) {
                                void* argsComp[1] = { typeObj };
                                void* resComp = p_runtime_invoke(mGetComp, go, argsComp, &exc);
                                if (resComp && !exc && IsValidMemoryPtr(resComp)) return resComp;
                            }
                        }
                    }
                }
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return nullptr;
    }
    return nullptr;
}

void ExecuteGoToSummon() {
    EnsureIL2CPPThreadAttached();
    HMODULE hGA = GetModuleHandleW(L"GameAssembly.dll");
    if (!hGA) return;

    auto p_domain_get = (il2cpp_domain_get_t)GetProcAddress(hGA, "il2cpp_domain_get");
    auto p_assembly_open = (il2cpp_domain_assembly_open_t)GetProcAddress(hGA, "il2cpp_domain_assembly_open");
    auto p_get_image = (il2cpp_assembly_get_image_t)GetProcAddress(hGA, "il2cpp_assembly_get_image");
    auto p_class_from_name = (il2cpp_class_from_name_t)GetProcAddress(hGA, "il2cpp_class_from_name");
    auto p_get_method = (il2cpp_class_get_method_from_name_t)GetProcAddress(hGA, "il2cpp_class_get_method_from_name");
    auto p_string_new = (il2cpp_string_new_t)GetProcAddress(hGA, "il2cpp_string_new");
    auto p_runtime_invoke = (il2cpp_runtime_invoke_t)GetProcAddress(hGA, "il2cpp_runtime_invoke");

    if (!p_domain_get || !p_assembly_open || !p_get_image || !p_class_from_name || !p_get_method || !p_string_new || !p_runtime_invoke) {
        LogDaniel("Failed to resolve il2cpp functions for GoToSummon");
        return;
    }

    __try {
        void* domain = p_domain_get();
        if (!domain) return;

        void* sceneStr = p_string_new("SummonOrbScene");
        if (!sceneStr) return;

        // Try Method A: Utils.LoadScene("SummonOrbScene") from Assembly-CSharp
        void* asmCS = p_assembly_open(domain, "Assembly-CSharp");
        if (!asmCS) asmCS = p_assembly_open(domain, "Assembly-CSharp.dll");
        if (asmCS) {
            void* imgCS = p_get_image(asmCS);
            if (imgCS) {
                void* utilsKlass = p_class_from_name(imgCS, "", "Utils");
                if (utilsKlass) {
                    void* uMethod = p_get_method(utilsKlass, "LoadScene", 1);
                    if (uMethod) {
                        void* args[1] = { sceneStr };
                        void* exc = nullptr;
                        p_runtime_invoke(uMethod, nullptr, args, &exc);
                        LogDaniel("Utils.LoadScene('SummonOrbScene') executed successfully!");
                        return;
                    }
                }
            }
        }

        // Try Method B: UnityEngine.SceneManagement.SceneManager.LoadScene("SummonOrbScene")
        void* assembly = p_assembly_open(domain, "UnityEngine.CoreModule");
        if (!assembly) assembly = p_assembly_open(domain, "UnityEngine");
        if (!assembly) assembly = p_assembly_open(domain, "UnityEngine.CoreModule.dll");
        if (!assembly) return;

        void* image = p_get_image(assembly);
        if (!image) return;

        void* klass = p_class_from_name(image, "UnityEngine.SceneManagement", "SceneManager");
        if (!klass) return;

        void* method1 = p_get_method(klass, "LoadScene", 1);
        if (method1) {
            void* args[1] = { sceneStr };
            void* exc = nullptr;
            p_runtime_invoke(method1, nullptr, args, &exc);
            LogDaniel("SceneManager.LoadScene(string) executed successfully!");
            return;
        }

        void* method2 = p_get_method(klass, "LoadScene", 2);
        if (method2) {
            int mode = 0; // LoadSceneMode.Single
            void* args[2] = { sceneStr, &mode };
            void* exc = nullptr;
            p_runtime_invoke(method2, nullptr, args, &exc);
            LogDaniel("SceneManager.LoadScene(string, mode) executed successfully!");
            return;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        LogDaniel("Exception in ExecuteGoToSummon!");
    }
}

// Main thread automation logic - 100% thread safe, called inside EventSystem::Update
void OnUnityMainThreadUpdate() {
    static ULONGLONG s_lastMasterReloadCheck = 0;
    ULONGLONG nowMasterTick = GetTickCount64();
    if (nowMasterTick - s_lastMasterReloadCheck >= 2000) {
        s_lastMasterReloadCheck = nowMasterTick;
        FILE* fTrigger = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\reload_lua.txt", "r");
        if (fTrigger) {
            fclose(fTrigger);
            _unlink("C:\\Users\\huynh\\Downloads\\htht by daniel\\reload_lua.txt");
            _unlink("C:\\Users\\huynh\\Downloads\\htht by daniel\\master_loaded.txt");
            g_bMasterFeaturesLoaded = false;
            LogDaniel("Triggered live reload of Master Lua script!");
        }
    }

    static ULONGLONG s_FirstGameTick = 0;
    if (s_FirstGameTick == 0) {
        s_FirstGameTick = nowMasterTick;
    }
    // Wait at least 12 seconds after game startup before first Lua load attempt
    if (nowMasterTick - s_FirstGameTick < 12000) {
        return;
    }

    static ULONGLONG s_lastMasterAttempt = 0;
    if (!g_bMasterFeaturesLoaded && (nowMasterTick - s_lastMasterAttempt >= 2000)) {
        s_lastMasterAttempt = nowMasterTick;
        bool executed = false;
        // 1. Try reading live disk file if present
        FILE* f = fopen("C:\\Users\\huynh\\Downloads\\HTDC_Clean_Features\\00_MASTER_AUTO_AGENT_ALL_IN_ONE_CLEAN.lua", "rb");
        if (f) {
            fseek(f, 0, SEEK_END);
            long sz = ftell(f);
            fseek(f, 0, SEEK_SET);
            if (sz > 0) {
                char* buf = (char*)malloc(sz + 1);
                if (buf) {
                    fread(buf, 1, sz, f);
                    buf[sz] = '\0';
                    char outMsg[256] = {0};
                    bool ok = ExecuteLua(buf, outMsg, sizeof(outMsg));
                    LogDanielFmt("[MasterLoad] Disk Lua: ok=%d, msg='%s'", ok, outMsg);
                    if (ok) {
                        executed = true;
                    }
                    free(buf);
                }
            }
            fclose(f);
        }
        // 2. Fallback to embedded master Lua code if disk file not loaded
        if (!executed && g_MasterCleanLuaCode[0] != '\0') {
            char outMsg[256] = {0};
            bool ok = ExecuteLua(g_MasterCleanLuaCode, outMsg, sizeof(outMsg));
            LogDanielFmt("[MasterLoad] Embedded Lua: ok=%d, msg='%s'", ok, outMsg);
        }

        // Verify if master_loaded.txt was written by Lua upon successful initialization
        FILE* fReady = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\master_loaded.txt", "r");
        if (fReady) {
            fclose(fReady);
            g_bMasterFeaturesLoaded = true;
            LogDaniel("Master Clean Features VERIFIED READY & ACTIVE (All 10 modules running)!");
        }
    }

    // 0. Process queued scene navigation to Chiêu Mộ (SummonOrbScene)
    if (g_bGoToSummonQueued) {
        g_bGoToSummonQueued = false;
        ExecuteGoToSummon();
    }

    if (!IsBoxOrbSummonValid()) {
        if (g_bAutoSummonRunning || g_bSingleSummonQueued) {
            g_bAutoSummonRunning = false;
            g_bSingleSummonQueued = false;
            g_bFactionChangeQueued = false;
            g_bWaitingForResponse = false;
            g_pBonusPopupToClose = nullptr;
        }
        return;
    }

    __try {
        // Sync live faction from game if user clicked in game
        if (!g_bFactionChangeQueued && !g_bAutoSummonRunning) {
            int liveFac = *(int*)((uintptr_t)g_pBoxOrbSummon + 0x30);
            if (liveFac >= 1 && liveFac <= 6 && liveFac != g_SelectedFactionId) {
                g_SelectedFactionId = liveFac;
            }
        }

        // Close any pending bonus reveal popup safely on main thread (never synchronously inside ShowUp)
        if (g_pBonusPopupToClose && pfn_PopupShowBonusEffect2_ButtonCloseClick) {
            void* pPop = g_pBonusPopupToClose;
            g_pBonusPopupToClose = nullptr;
            __try {
                uintptr_t p = (uintptr_t)pPop;
                if (p && *(void**)(p + 0x10) != nullptr) {
                    pfn_PopupShowBonusEffect2_ButtonCloseClick(pPop, nullptr);
                }
            } __except (EXCEPTION_EXECUTE_HANDLER) {
                LogDaniel("Exception closing bonus popup!");
            }
        }

        // 1. Process queued faction change
        if (g_bFactionChangeQueued && pfn_OnFactionSelected) {
            pfn_OnFactionSelected(g_pBoxOrbSummon, g_SelectedFactionId, nullptr);
            g_bFactionChangeQueued = false;
        }

        // 2. Process single spin (Quay một đợt)
        if (g_bSingleSummonQueued && pfn_ButtonSummon10Click) {
            if (g_bRotateFaction) {
                RotateToNextFaction();
            }
            __try {
                pfn_ButtonSummon10Click(g_pBoxOrbSummon, nullptr);
                g_CompletedRounds++;
            } __except (EXCEPTION_EXECUTE_HANDLER) {
                LogDaniel("Exception in single ButtonSummon10Click!");
            }
            g_bSingleSummonQueued = false;
            s_lastSummonTime = GetTickCount64();
            return;
        }

        // 3. Process auto summon with state machine (waiting for server response)
        if (g_bAutoSummonRunning && pfn_ButtonSummon10Click) {
            ULONGLONG now = GetTickCount64();

            // Safety timeout: If waiting for server response > 4000ms, assume network issue or no tickets, stop safely
            if (g_bWaitingForResponse && (now - s_requestSentTime > 4000)) {
                LogDaniel("Auto summon timeout waiting for server response (tickets may be exhausted). Stopping.");
                g_bWaitingForResponse = false;
                g_bAutoSummonRunning = false;
                return;
            }

            // If we are waiting for server response, do not send next request yet
            if (g_bWaitingForResponse) {
                return;
            }

            // Check if target rounds completed (Bỏ qua kiểm tra nếu bật Vòng lặp vô hạn)
            if (!g_bInfiniteLoop && g_CompletedRounds >= g_SummonRounds) {
                g_bAutoSummonRunning = false;
                return;
            }

            // Delay between rounds (Fast: 200ms, Normal: 1000ms)
            ULONGLONG delay = g_bFastEffect ? 200 : 1000;
            if (now - s_lastSummonTime >= delay) {
                if (g_bRotateFaction) {
                    RotateToNextFaction();
                }

                g_bWaitingForResponse = true;
                g_bServerResponseReceived = false;
                s_requestSentTime = now;
                s_lastSummonTime = now;

                __try {
                    pfn_ButtonSummon10Click(g_pBoxOrbSummon, nullptr);
                    g_CompletedRounds++;
                } __except (EXCEPTION_EXECUTE_HANDLER) {
                    LogDaniel("Exception in auto ButtonSummon10Click!");
                    g_bAutoSummonRunning = false;
                    g_bWaitingForResponse = false;
                }
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        g_bAutoSummonRunning = false;
        g_bSingleSummonQueued = false;
        g_bWaitingForResponse = false;
        g_pBonusPopupToClose = nullptr;
        LogDaniel("Exception intercepted in OnUnityMainThreadUpdate!");
    }
}

void ApplyGameSpeed(float speed) {
    if (speed < 1.0f) speed = 1.0f;
    if (speed > 1000.0f) speed = 1000.0f;
    g_GameSpeed = speed;

    if (o_set_timeScale) {
        o_set_timeScale(g_GameSpeed);
    } else if (g_set_timeScale) {
        g_set_timeScale(g_GameSpeed);
    }
}

void EnforceGameSpeed() {
    EnsureIL2CPPThreadAttached();
    if (!g_set_timeScale || !g_set_targetFrameRate) {
        InitIL2CPP();
    }
    if (g_bLockSpeed && g_GameSpeed >= 1.0f) {
        if (o_set_timeScale) {
            o_set_timeScale(g_GameSpeed);
        } else if (g_set_timeScale) {
            g_set_timeScale(g_GameSpeed);
        }
    }
    if (g_TargetFPS > 0) {
        if (o_set_targetFrameRate) {
            o_set_targetFrameRate(g_TargetFPS);
        } else if (g_set_targetFrameRate) {
            g_set_targetFrameRate(g_TargetFPS);
        }
    }
}

void SetupModernGlassTheme() {
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 18.0f;
    style.ChildRounding = 14.0f;
    style.FrameRounding = 10.0f;
    style.PopupRounding = 12.0f;
    style.ScrollbarSize = 5.0f;
    style.ScrollbarRounding = 12.0f;
    style.GrabRounding = 12.0f;
    style.TabRounding = 10.0f;

    style.WindowBorderSize = 1.0f;
    style.ChildBorderSize = 1.0f;
    style.FrameBorderSize = 1.0f;

    style.WindowPadding = ImVec2(16, 16);
    style.ItemSpacing = ImVec2(10, 10);
    style.FramePadding = ImVec2(8, 6);

    ImVec4* colors = style.Colors;
    colors[ImGuiCol_WindowBg]              = ImVec4(0.965f, 0.968f, 0.975f, g_MenuAlpha);
    colors[ImGuiCol_ChildBg]               = ImVec4(1.00f, 1.00f, 1.00f, 0.90f * g_MenuAlpha);
    colors[ImGuiCol_PopupBg]               = ImVec4(1.00f, 1.00f, 1.00f, 0.95f * g_MenuAlpha);
    colors[ImGuiCol_Border]                = ImVec4(0.88f, 0.86f, 0.92f, 1.00f);
    colors[ImGuiCol_BorderShadow]          = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);

    colors[ImGuiCol_Text]                  = ImVec4(0.18f, 0.14f, 0.25f, 1.00f);
    colors[ImGuiCol_TextDisabled]          = ImVec4(0.58f, 0.55f, 0.64f, 1.00f);

    colors[ImGuiCol_FrameBg]               = ImVec4(0.93f, 0.91f, 0.97f, 1.00f);
    colors[ImGuiCol_FrameBgHovered]        = ImVec4(0.88f, 0.85f, 0.95f, 1.00f);
    colors[ImGuiCol_FrameBgActive]         = ImVec4(0.82f, 0.78f, 0.93f, 1.00f);

    colors[ImGuiCol_Button]                = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
    colors[ImGuiCol_ButtonHovered]         = ImVec4(0.95f, 0.93f, 0.99f, 1.00f);
    colors[ImGuiCol_ButtonActive]          = ImVec4(0.88f, 0.84f, 0.98f, 1.00f);

    colors[ImGuiCol_CheckMark]             = ImVec4(0.48f, 0.36f, 0.98f, 1.00f);
    colors[ImGuiCol_SliderGrab]            = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
    colors[ImGuiCol_SliderGrabActive]      = ImVec4(0.95f, 0.95f, 1.00f, 1.00f);

    colors[ImGuiCol_ScrollbarBg]           = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_ScrollbarGrab]         = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_ScrollbarGrabHovered]  = ImVec4(0.60f, 0.52f, 0.85f, 0.75f);
    colors[ImGuiCol_ScrollbarGrabActive]   = ImVec4(0.48f, 0.36f, 0.80f, 0.95f);
}

static const char* GetSidebarIconGlyph(int type) {
    switch (type) {
        case 0: return "\xEE\xA0\x8F"; // 0xE80F: Home (Chiêu Mộ)
        case 1: return "\xEE\xA4\x96"; // 0xE916: Stopwatch (Tăng Tốc)
        case 2: return "\xEE\x9C\xAC"; // 0xE72C: Refresh / Spin (Vòng Quay)
        case 3: return "\xEE\x9F\xBC"; // 0xE7FC: Game Controller / Event (Hoạt Động)
        case 4: return "\xEE\xA3\x94"; // 0xE8D4: Shield / Hero (Tướng)
        case 5: return "\xEE\x9C\x93"; // 0xE713: Settings Gear (Cài Đặt)
        case 6: return "\xEE\x9E\x90"; // 0xE790: Sparkle / Diamond (Trái Ác Quỷ)
        case 7: return "\xEE\x9F\xBC"; // Code / Terminal
        default: return "\xEE\x9E\x90";
    }
}

// Vector icon drawer for sidebar
static void DrawSidebarIcon(int type, ImVec2 c, ImU32 col) {
    ImDrawList* draw = ImGui::GetWindowDrawList();
    if (g_FontIcons) {
        const char* glyph = GetSidebarIconGlyph(type);
        ImVec2 sz = g_FontIcons->CalcTextSizeA(15.0f, FLT_MAX, -1.0f, glyph);
        draw->AddText(g_FontIcons, 15.0f, ImVec2(c.x - sz.x * 0.5f, c.y - sz.y * 0.5f - 1.0f), col, glyph);
        return;
    }

    // Clean modern vector fallback
    switch (type) {
        case 0: // Minimalist modern Home
            draw->AddTriangle(ImVec2(c.x, c.y - 7), ImVec2(c.x - 7, c.y - 1), ImVec2(c.x + 7, c.y - 1), col, 1.6f);
            draw->AddRect(ImVec2(c.x - 4.5f, c.y - 1), ImVec2(c.x + 4.5f, c.y + 6), col, 1.0f, 0, 1.5f);
            break;
        case 1: // Minimalist Speed Clock
            draw->AddCircle(ImVec2(c.x, c.y + 1), 6.5f, col, 0, 1.5f);
            draw->AddLine(ImVec2(c.x, c.y + 1), ImVec2(c.x, c.y - 3), col, 1.5f);
            draw->AddLine(ImVec2(c.x, c.y + 1), ImVec2(c.x + 3, c.y + 1), col, 1.5f);
            draw->AddLine(ImVec2(c.x - 2, c.y - 7), ImVec2(c.x + 2, c.y - 7), col, 1.5f);
            break;
        case 2: // Minimalist Spin Target
            draw->AddCircle(c, 7.0f, col, 0, 1.5f);
            draw->AddCircleFilled(c, 2.5f, col);
            draw->AddLine(ImVec2(c.x - 7, c.y), ImVec2(c.x + 7, c.y), col, 1.2f);
            draw->AddLine(ImVec2(c.x, c.y - 7), ImVec2(c.x, c.y + 7), col, 1.2f);
            break;
        case 3: // Modern Flag / Event (Hoạt Động)
            draw->AddLine(ImVec2(c.x - 5, c.y - 7), ImVec2(c.x - 5, c.y + 7), col, 1.8f);
            draw->AddTriangleFilled(ImVec2(c.x - 5, c.y - 7), ImVec2(c.x + 5, c.y - 3), ImVec2(c.x - 5, c.y + 1), col);
            break;
        case 4: // Modern Hero Shield (Tướng)
            draw->AddQuad(ImVec2(c.x, c.y - 7), ImVec2(c.x + 6, c.y - 4), ImVec2(c.x, c.y + 7), ImVec2(c.x - 6, c.y - 4), col, 1.6f);
            break;
        case 5: // Modern Gear (Cài Đặt)
            draw->AddCircle(c, 6.0f, col, 0, 2.0f);
            draw->AddCircle(c, 2.2f, col, 0, 1.5f);
            for (int i = 0; i < 4; i++) {
                float angle = i * 3.14159f / 4.0f;
                float dx = cosf(angle) * 7.5f;
                float dy = sinf(angle) * 7.5f;
                draw->AddLine(ImVec2(c.x - dx, c.y - dy), ImVec2(c.x + dx, c.y + dy), col, 1.8f);
            }
            break;
        case 6: // Modern Sparkle / Fruit (Trái Ác Quỷ)
            draw->AddQuadFilled(ImVec2(c.x, c.y - 7), ImVec2(c.x + 5, c.y), ImVec2(c.x, c.y + 7), ImVec2(c.x - 5, c.y), col);
            break;
        default:
            draw->AddCircleFilled(c, 4.0f, col);
            break;
    }
}

// Custom iOS Toggle Switch
static bool DrawToggleSwitch(const char* str_id, bool* v) {
    ImVec2 p = ImGui::GetCursorScreenPos();
    ImDrawList* draw_list = ImGui::GetWindowDrawList();

    float height = 28.0f;
    float width = 50.0f;
    float radius = height * 0.5f;

    ImGui::InvisibleButton(str_id, ImVec2(width, height));
    if (ImGui::IsItemClicked()) {
        *v = !*v;
    }

    ImU32 col_bg = *v ? IM_COL32(52, 199, 89, 255) : IM_COL32(225, 225, 230, 255);
    draw_list->AddRectFilled(p, ImVec2(p.x + width, p.y + height), col_bg, radius);

    float knob_x = *v ? (p.x + width - radius) : (p.x + radius);
    draw_list->AddCircleFilled(ImVec2(knob_x, p.y + radius + 1), radius - 3.0f, IM_COL32(0, 0, 0, 25));
    draw_list->AddCircleFilled(ImVec2(knob_x, p.y + radius), radius - 3.0f, IM_COL32(255, 255, 255, 255));

    return *v;
}

// Custom Sidebar Navigation Item
static bool DrawSidebarItem(int iconType, const char* label, bool selected, float width) {
    ImGui::PushID(label);
    ImVec2 p = ImGui::GetCursorScreenPos();
    float height = 34.0f;
    ImDrawList* draw = ImGui::GetWindowDrawList();

    ImGui::InvisibleButton(label, ImVec2(width, height));
    bool clicked = ImGui::IsItemClicked();
    bool hovered = ImGui::IsItemHovered();

    if (selected) {
        draw->AddRectFilled(p, ImVec2(p.x + width, p.y + height), IM_COL32(236, 228, 255, 255), 10.0f);
        draw->AddRect(p, ImVec2(p.x + width, p.y + height), IM_COL32(180, 160, 252, 220), 10.0f, 0, 1.2f);
    } else if (hovered) {
        draw->AddRectFilled(p, ImVec2(p.x + width, p.y + height), IM_COL32(245, 242, 252, 255), 10.0f);
    }

    ImU32 text_col = selected ? IM_COL32(108, 65, 255, 255) : IM_COL32(55, 48, 70, 255);

    DrawSidebarIcon(iconType, ImVec2(p.x + 22, p.y + 17), text_col);

    if (g_FontBold && selected) ImGui::PushFont(g_FontBold);
    else if (g_FontRegular) ImGui::PushFont(g_FontRegular);

    draw->AddText(ImVec2(p.x + 42, p.y + 8), text_col, label);

    ImGui::PopFont();
    ImGui::PopID();
    return clicked;
}

// Custom Speed Preset Pill Button
static void DrawSpeedPill(const char* label, float speedVal, ImVec2 size) {
    bool isActive = (speedVal >= 999.0f && g_GameSpeed >= 999.0f) ||
                    (fabsf(g_GameSpeed - speedVal) < 0.1f);
    ImVec2 p = ImGui::GetCursorScreenPos();
    ImDrawList* draw = ImGui::GetWindowDrawList();

    ImGui::PushID(label);
    ImGui::InvisibleButton(label, size);
    bool clicked = ImGui::IsItemClicked();
    bool hovered = ImGui::IsItemHovered();

    if (clicked) {
        ApplyGameSpeed(speedVal);
    }

    if (isActive) {
        draw->AddRectFilled(p, ImVec2(p.x + size.x, p.y + size.y), IM_COL32(118, 82, 246, 255), 10.0f);
    } else {
        ImU32 bg_col = hovered ? IM_COL32(246, 242, 255, 255) : IM_COL32(255, 255, 255, 255);
        draw->AddRectFilled(p, ImVec2(p.x + size.x, p.y + size.y), bg_col, 10.0f);
        draw->AddRect(p, ImVec2(p.x + size.x, p.y + size.y), IM_COL32(218, 212, 232, 255), 10.0f, 0, 1.2f);
    }

    ImVec2 textSize = ImGui::CalcTextSize(label);
    ImVec2 textPos = ImVec2(p.x + (size.x - textSize.x) * 0.5f, p.y + (size.y - textSize.y) * 0.5f);
    ImU32 text_col = isActive ? IM_COL32(255, 255, 255, 255) : IM_COL32(45, 38, 60, 255);
    draw->AddText(textPos, text_col, label);

    ImGui::PopID();
}

// Custom FPS Preset Pill Button
static void DrawFpsPill(const char* label, int fpsVal, ImVec2 size) {
    bool isActive = (fpsVal <= 0 && g_TargetFPS <= 0) || (g_TargetFPS == fpsVal);
    ImVec2 p = ImGui::GetCursorScreenPos();
    ImDrawList* draw = ImGui::GetWindowDrawList();

    ImGui::PushID(label);
    ImGui::InvisibleButton(label, size);
    bool clicked = ImGui::IsItemClicked();
    bool hovered = ImGui::IsItemHovered();

    if (clicked) {
        ApplyFpsLimit(fpsVal);
    }

    if (isActive) {
        draw->AddRectFilled(p, ImVec2(p.x + size.x, p.y + size.y), IM_COL32(118, 82, 246, 255), 10.0f);
    } else {
        ImU32 bg_col = hovered ? IM_COL32(246, 242, 255, 255) : IM_COL32(255, 255, 255, 255);
        draw->AddRectFilled(p, ImVec2(p.x + size.x, p.y + size.y), bg_col, 10.0f);
        draw->AddRect(p, ImVec2(p.x + size.x, p.y + size.y), IM_COL32(218, 212, 232, 255), 10.0f, 0, 1.2f);
    }

    ImVec2 textSize = ImGui::CalcTextSize(label);
    ImVec2 textPos = ImVec2(p.x + (size.x - textSize.x) * 0.5f, p.y + (size.y - textSize.y) * 0.5f);
    ImU32 text_col = isActive ? IM_COL32(255, 255, 255, 255) : IM_COL32(45, 38, 60, 255);
    draw->AddText(textPos, text_col, label);

    ImGui::PopID();
}

void RenderDanielMenu() {
    UpdateLiveCurrencies();

    static bool s_FirstInitTheme = true;
    if (s_FirstInitTheme) {
        SetupModernGlassTheme();
        s_FirstInitTheme = false;
    }

    ImGui::SetNextWindowSize(ImVec2(800.0f, 530.0f), ImGuiCond_Always);
    ImGui::SetNextWindowPos(ImVec2(140, 60), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowBgAlpha(g_MenuAlpha);

    ImGuiWindowFlags winFlags = ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize;
    if (!ImGui::Begin("##DanielModernMenu", &g_bShowMenu, winFlags)) {
        ImGui::End();
        return;
    }

    ImVec2 winPos = ImGui::GetWindowPos();
    ImVec2 winSize = ImGui::GetWindowSize();
    if (winPos.y > 550.0f || winPos.y < 0.0f) {
        ImGui::SetWindowPos(ImVec2(160, 60));
        winPos = ImVec2(160, 60);
    }
    ImDrawList* draw = ImGui::GetWindowDrawList();

    // ==========================================
    // 1. TOP HEADER BAR
    // ==========================================

    // 3 Mac Traffic Light Dots (Red, Yellow, Green)
    draw->AddCircleFilled(ImVec2(winPos.x + 24, winPos.y + 24), 6.0f, IM_COL32(255, 95, 86, 255));
    draw->AddCircleFilled(ImVec2(winPos.x + 42, winPos.y + 24), 6.0f, IM_COL32(255, 189, 46, 255));
    draw->AddCircleFilled(ImVec2(winPos.x + 60, winPos.y + 24), 6.0f, IM_COL32(39, 201, 63, 255));

    // Click Red Dot to close
    ImGui::SetCursorScreenPos(ImVec2(winPos.x + 16, winPos.y + 16));
    if (ImGui::InvisibleButton("##MacClose", ImVec2(16, 16))) {
        g_bShowMenu = false;
    }

    // HTDC MOD (Bold Italic stylized purple text)
    if (g_FontLogo) ImGui::PushFont(g_FontLogo);
    draw->AddText(ImVec2(winPos.x + 85, winPos.y + 13), IM_COL32(45, 28, 88, 255), "HTDC MOD");
    if (g_FontLogo) ImGui::PopFont();

    // Close 'X' button on far top-right
    ImGui::SetCursorScreenPos(ImVec2(winPos.x + winSize.x - 34.0f, winPos.y + 12));
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0, 0, 0, 0));
    ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.92f, 0.90f, 0.96f, 1.0f));
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.35f, 0.30f, 0.45f, 1.0f));
    if (ImGui::Button("X##CloseWin", ImVec2(24, 24))) {
        g_bShowMenu = false;
    }
    ImGui::PopStyleColor(3);

    // ==========================================
    // 2. MAIN BODY (TWO COLUMNS: SIDEBAR + CONTENT)
    // ==========================================
    float bodyY = 52.0f;
    float bodyH = winSize.y - bodyY - 14.0f;
    float sidebarW = 180.0f;

    // --- LEFT SIDEBAR ---
    ImGui::SetCursorPos(ImVec2(14, bodyY));
    ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(1.0f, 1.0f, 1.0f, 0.90f * g_MenuAlpha));
    ImGui::PushStyleVar(ImGuiStyleVar_ChildRounding, 14.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0, 3.0f));
    ImGui::BeginChild("##Sidebar", ImVec2(sidebarW, bodyH), true);

    ImGui::Dummy(ImVec2(0, 2.0f));
    if (DrawSidebarItem(1, "Tăng Tốc", g_CurrentTab == 1, sidebarW - 16.0f)) g_CurrentTab = 1;
    if (DrawSidebarItem(5, "Cài Đặt", g_CurrentTab == 5, sidebarW - 16.0f)) g_CurrentTab = 5;

    // Bottom Profile Pill in Sidebar
    ImVec2 sbPos = ImGui::GetWindowPos();
    ImVec2 pillPos = ImVec2(sbPos.x + 8.0f, sbPos.y + bodyH - 46.0f);
    float pillW = sidebarW - 16.0f;
    float pillH = 40.0f;

    draw->AddRectFilled(pillPos, ImVec2(pillPos.x + pillW, pillPos.y + pillH), IM_COL32(255, 255, 255, 255), 12.0f);
    draw->AddRect(pillPos, ImVec2(pillPos.x + pillW, pillPos.y + pillH), IM_COL32(225, 222, 235, 200), 12.0f, 0, 1.0f);

    // Cute Avatar with big eyes (matching mockup)
    ImVec2 avCenter = ImVec2(pillPos.x + 22.0f, pillPos.y + pillH * 0.5f);
    draw->AddCircleFilled(avCenter, 14.0f, IM_COL32(235, 218, 195, 255));
    draw->AddCircle(avCenter, 14.0f, IM_COL32(195, 175, 145, 255), 0, 1.2f);
    draw->AddCircleFilled(ImVec2(avCenter.x - 4, avCenter.y - 2), 3.0f, IM_COL32(65, 45, 30, 255));
    draw->AddCircleFilled(ImVec2(avCenter.x + 4, avCenter.y - 2), 3.0f, IM_COL32(65, 45, 30, 255));
    draw->AddCircleFilled(ImVec2(avCenter.x - 5, avCenter.y - 3), 1.0f, IM_COL32(255, 255, 255, 255));
    draw->AddCircleFilled(ImVec2(avCenter.x + 3, avCenter.y - 3), 1.0f, IM_COL32(255, 255, 255, 255));
    draw->AddCircleFilled(ImVec2(avCenter.x, avCenter.y + 3), 1.5f, IM_COL32(120, 80, 50, 255));

    // Profile text
    if (g_FontBold) ImGui::PushFont(g_FontBold);
    draw->AddText(ImVec2(pillPos.x + 44.0f, pillPos.y + 7.0f), IM_COL32(35, 30, 50, 255), "Daniel");
    if (g_FontBold) ImGui::PopFont();

    if (g_FontSmall) ImGui::PushFont(g_FontSmall);
    draw->AddText(ImVec2(pillPos.x + 44.0f, pillPos.y + 24.0f), IM_COL32(16, 185, 129, 255), "Key: Lifetime");
    if (g_FontSmall) ImGui::PopFont();

    ImGui::EndChild();
    ImGui::PopStyleVar(2);
    ImGui::PopStyleColor();

    // --- RIGHT CONTENT AREA ---
    float contentX = sidebarW + 36.0f;
    float contentW = winSize.x - contentX - 20.0f;

    ImGui::SetCursorPos(ImVec2(contentX, bodyY));
    ImGui::BeginChild("##ContentArea", ImVec2(contentW, bodyH), false);

    // ==========================================
    // TAB 1: TĂNG TỐC (SPEEDHACK 1.0x - 1000.0x)
    // ==========================================
    if (g_CurrentTab == 1) {
        // Big Bold Section Title: TỐC ĐỘ
        ImGui::SetCursorPos(ImVec2(10.0f, 4.0f));
        if (g_FontTitle) ImGui::PushFont(g_FontTitle);
        ImGui::TextColored(ImVec4(0.18f, 0.12f, 0.32f, 1.0f), "TỐC ĐỘ");
        if (g_FontTitle) ImGui::PopFont();

        ImGui::Spacing();

        // ------------------------------------------
        // CARD: Tốc Độ Slider & Chọn Nhanh (Mặc định tự khóa tốc độ)
        // ------------------------------------------
        ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(1.0f, 1.0f, 1.0f, 0.90f * g_MenuAlpha));
        ImGui::PushStyleVar(ImGuiStyleVar_ChildRounding, 14.0f);
        ImGui::BeginChild("##CardSpeedControl", ImVec2(contentW, 260.0f), true);
        {
            // Top Label: Tốc độ
            ImGui::SetCursorPos(ImVec2(18, 20));
            if (g_FontBold) ImGui::PushFont(g_FontBold);
            ImGui::TextColored(ImVec4(0.18f, 0.14f, 0.28f, 1.0f), "Tốc độ");
            if (g_FontBold) ImGui::PopFont();

            // Centered speed value above slider
            char speedStr[32];
            sprintf(speedStr, "%.1fx", g_GameSpeed);
            ImVec2 txtSz = ImGui::CalcTextSize(speedStr);
            ImGui::SetCursorPos(ImVec2((contentW - txtSz.x) * 0.5f - 40.0f, 20.0f));
            if (g_FontBold) ImGui::PushFont(g_FontBold);
            ImGui::TextColored(ImVec4(0.42f, 0.25f, 0.95f, 1.0f), "%s", speedStr);
            if (g_FontBold) ImGui::PopFont();

            // Slider & Stepper Row
            ImGui::SetCursorPos(ImVec2(18, 56));
            float sliderWidth = contentW - 170.0f;
            ImGui::SetNextItemWidth(sliderWidth);

            ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(0.85f, 0.81f, 0.96f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_FrameBgHovered, ImVec4(0.80f, 0.75f, 0.95f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_FrameBgActive, ImVec4(0.75f, 0.70f, 0.94f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_SliderGrab, ImVec4(1.0f, 1.0f, 1.0f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_SliderGrabActive, ImVec4(0.95f, 0.95f, 1.0f, 1.0f));

            float curSpeed = g_GameSpeed;
            if (ImGui::SliderFloat("##SpeedSlider", &curSpeed, 1.0f, 1000.0f, "", ImGuiSliderFlags_Logarithmic)) {
                ApplyGameSpeed(curSpeed);
            }
            ImGui::PopStyleColor(5);

            // Minus Button [-]
            ImGui::SameLine(0, 10);
            if (ImGui::Button("-##SpeedMinus", ImVec2(32, 28))) {
                if (g_GameSpeed > 50.0f) ApplyGameSpeed(g_GameSpeed - 10.0f);
                else if (g_GameSpeed > 5.0f) ApplyGameSpeed(g_GameSpeed - 1.0f);
                else ApplyGameSpeed(g_GameSpeed - 0.5f);
            }

            // Plus Button [+]
            ImGui::SameLine(0, 6);
            if (ImGui::Button("+##SpeedPlus", ImVec2(32, 28))) {
                if (g_GameSpeed >= 50.0f) ApplyGameSpeed(g_GameSpeed + 10.0f);
                else if (g_GameSpeed >= 5.0f) ApplyGameSpeed(g_GameSpeed + 1.0f);
                else ApplyGameSpeed(g_GameSpeed + 0.5f);
            }

            // Direct input / display box
            ImGui::SameLine(0, 6);
            ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 8.0f);
            ImGui::SetNextItemWidth(55.0f);
            float directInput = g_GameSpeed;
            if (ImGui::InputFloat("##DirectSpeed", &directInput, 0.0f, 0.0f, "%.1f", ImGuiInputTextFlags_EnterReturnsTrue)) {
                ApplyGameSpeed(directInput);
            }
            ImGui::PopStyleVar();

            // Section 2: Chọn nhanh
            ImGui::SetCursorPos(ImVec2(18, 108));
            if (g_FontBold) ImGui::PushFont(g_FontBold);
            ImGui::TextColored(ImVec4(0.18f, 0.14f, 0.28f, 1.0f), "Chọn nhanh");
            if (g_FontBold) ImGui::PopFont();

            // Preset Pills Layout (2 Rows of 5 buttons each)
            float pillGap = 10.0f;
            float totalPillsWidth = contentW - 36.0f;
            float pillW = (totalPillsWidth - (pillGap * 4.0f)) / 5.0f;
            float pillH = 36.0f;

            // Row 1: [ 1x ] [ 2x ] [ 3x ] [ 5x ] [ 10x ]
            ImGui::SetCursorPos(ImVec2(18, 142));
            DrawSpeedPill("1x", 1.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("2x", 2.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("3x", 3.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("5x", 5.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("10x", 10.0f, ImVec2(pillW, pillH));

            // Row 2: [ 20x ] [ 50x ] [ 100x ] [ 500x ] [ MAX ]
            ImGui::SetCursorPos(ImVec2(18, 192));
            DrawSpeedPill("20x", 20.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("50x", 50.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("100x", 100.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("500x", 500.0f, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawSpeedPill("MAX", 1000.0f, ImVec2(pillW, pillH));
        }
        ImGui::EndChild();
        ImGui::PopStyleVar();
        ImGui::PopStyleColor();

        // ------------------------------------------
        // BOTTOM STATUS BAR (FPS & Ping)
        // ------------------------------------------
        ImGuiIO& io = ImGui::GetIO();
        float fps = io.Framerate;
        char fpsStr[64];
        sprintf(fpsStr, "FPS: %.0f  |  PING: 32ms", fps);
        ImVec2 fpsSz = ImGui::CalcTextSize(fpsStr);

        ImGui::SetCursorPos(ImVec2(contentW - fpsSz.x - 4.0f, bodyH - 26.0f));
        if (g_FontSmall) ImGui::PushFont(g_FontSmall);
        ImGui::TextColored(ImVec4(0.55f, 0.52f, 0.65f, 1.0f), "%s", fpsStr);
        if (g_FontSmall) ImGui::PopFont();
    }
    // ==========================================
    // TAB 5: CÀI ĐẶT
    // ==========================================
    else if (g_CurrentTab == 5) {
        ImGui::SetCursorPos(ImVec2(10.0f, 4.0f));
        if (g_FontTitle) ImGui::PushFont(g_FontTitle);
        ImGui::TextColored(ImVec4(0.18f, 0.12f, 0.32f, 1.0f), "CÀI ĐẶT");
        if (g_FontTitle) ImGui::PopFont();
        ImGui::Spacing();

        ImGui::PushStyleColor(ImGuiCol_ChildBg, ImVec4(1.0f, 1.0f, 1.0f, 0.90f * g_MenuAlpha));
        ImGui::PushStyleVar(ImGuiStyleVar_ChildRounding, 14.0f);
        ImGui::BeginChild("##SettingsCard", ImVec2(contentW, 255.0f), true);
        {
            // Độ trong suốt Menu
            ImGui::SetCursorPos(ImVec2(18, 18));
            ImGui::SetNextItemWidth(260.0f);
            if (ImGui::SliderFloat("Độ trong suốt Menu", &g_MenuAlpha, 0.30f, 1.0f, "%.2f")) {
                SetupModernGlassTheme();
            }

            // Cap FPS
            ImGui::SetCursorPos(ImVec2(18, 56));
            float liveFps = ImGui::GetIO().Framerate;
            ImGui::TextColored(ImVec4(0.35f, 0.30f, 0.45f, 1.0f), "FPS hiện tại: %.1f FPS", liveFps);

            ImGui::SetCursorPos(ImVec2(18, 84));
            ImGui::TextColored(ImVec4(0.35f, 0.30f, 0.45f, 1.0f), "Các mốc nhanh:");

            float pillGap = 8.0f;
            float totalPillsWidth = contentW - 36.0f;
            float pillW = (totalPillsWidth - (pillGap * 4.0f)) / 5.0f;
            float pillH = 32.0f;

            ImGui::SetCursorPos(ImVec2(18, 108));
            DrawFpsPill("30 FPS", 30, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawFpsPill("60 FPS", 60, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawFpsPill("120 FPS", 120, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawFpsPill("144 FPS", 144, ImVec2(pillW, pillH));
            ImGui::SameLine(0, pillGap);
            DrawFpsPill("Mở Khóa", -1, ImVec2(pillW, pillH));

            ImGui::SetCursorPos(ImVec2(18, 150));
            ImGui::TextColored(ImVec4(0.35f, 0.30f, 0.45f, 1.0f), "Hoặc kéo tùy chỉnh:");

            ImGui::SetCursorPos(ImVec2(18, 174));
            ImGui::SetNextItemWidth(260.0f);
            int sliderFps = (g_TargetFPS <= 0) ? 240 : g_TargetFPS;
            if (ImGui::SliderInt("Giới hạn", &sliderFps, 30, 240, "%d FPS")) {
                ApplyFpsLimit(sliderFps);
            }

            // Thông tin tác giả
            ImGui::SetCursorPos(ImVec2(18, 218));
            ImGui::TextColored(ImVec4(0.40f, 0.35f, 0.50f, 1.0f), "Tác giả: Daniel");
        }
        ImGui::EndChild();
        ImGui::PopStyleVar();
        ImGui::PopStyleColor();
    }

    ImGui::EndChild();

    ImGui::End();
}

void InitAvatarTexture(ID3D11Device* pDevice) {
    if (g_pAvatarTextureView || !pDevice) return;

    D3D11_TEXTURE2D_DESC desc;
    ZeroMemory(&desc, sizeof(desc));
    desc.Width = g_AvatarImageWidth;
    desc.Height = g_AvatarImageHeight;
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_DEFAULT;
    desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
    desc.CPUAccessFlags = 0;

    D3D11_SUBRESOURCE_DATA subResource;
    subResource.pSysMem = g_AvatarImageData;
    subResource.SysMemPitch = g_AvatarImageWidth * 4;
    subResource.SysMemSlicePitch = 0;

    ID3D11Texture2D* pTexture = NULL;
    HRESULT hr = pDevice->CreateTexture2D(&desc, &subResource, &pTexture);
    if (SUCCEEDED(hr) && pTexture) {
        D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc;
        ZeroMemory(&srvDesc, sizeof(srvDesc));
        srvDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
        srvDesc.Texture2D.MipLevels = desc.MipLevels;
        srvDesc.Texture2D.MostDetailedMip = 0;

        pDevice->CreateShaderResourceView(pTexture, &srvDesc, &g_pAvatarTextureView);
        pTexture->Release();
    }
}

void RenderFloatingToggleButton() {
    ImGuiIO& io = ImGui::GetIO();
    static ImVec2 s_FloatingBtnPos(15.0f, 220.0f);
    static bool s_FirstPos = true;
    if (s_FirstPos && io.DisplaySize.y > 100.0f) {
        s_FloatingBtnPos = ImVec2(15.0f, io.DisplaySize.y * 0.45f);
        s_FirstPos = false;
    }

    float btnDiameter = 54.0f;
    float btnRadius = btnDiameter * 0.5f;

    ImGui::SetNextWindowPos(s_FloatingBtnPos, ImGuiCond_Always);
    ImGui::SetNextWindowSize(ImVec2(btnDiameter + 8.0f, btnDiameter + 8.0f), ImGuiCond_Always);

    ImGuiWindowFlags flags = ImGuiWindowFlags_NoTitleBar |
                            ImGuiWindowFlags_NoResize |
                            ImGuiWindowFlags_NoMove |
                            ImGuiWindowFlags_NoScrollbar |
                            ImGuiWindowFlags_NoBackground |
                            ImGuiWindowFlags_NoSavedSettings;

    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);

    if (ImGui::Begin("##FloatingToggleBtn", nullptr, flags)) {
        ImVec2 p = ImGui::GetCursorScreenPos();
        ImDrawList* draw = ImGui::GetWindowDrawList();
        ImVec2 center(p.x + btnRadius + 4.0f, p.y + btnRadius + 4.0f);

        ImGui::InvisibleButton("##ToggleBtnAction", ImVec2(btnDiameter + 8.0f, btnDiameter + 8.0f));
        bool hovered = ImGui::IsItemHovered();
        bool active = ImGui::IsItemActive();

        // Smooth dragging logic: allows moving button anywhere on screen
        static bool s_Dragging = false;
        if (ImGui::IsItemActivated()) {
            s_Dragging = false;
        }
        if (active && ImGui::IsMouseDragging(0, 2.5f)) {
            s_Dragging = true;
            s_FloatingBtnPos.x += io.MouseDelta.x;
            s_FloatingBtnPos.y += io.MouseDelta.y;

            // Clamp inside screen bounds
            if (s_FloatingBtnPos.x < 0.0f) s_FloatingBtnPos.x = 0.0f;
            if (s_FloatingBtnPos.y < 0.0f) s_FloatingBtnPos.y = 0.0f;
            if (s_FloatingBtnPos.x > io.DisplaySize.x - btnDiameter - 8.0f) s_FloatingBtnPos.x = io.DisplaySize.x - btnDiameter - 8.0f;
            if (s_FloatingBtnPos.y > io.DisplaySize.y - btnDiameter - 8.0f) s_FloatingBtnPos.y = io.DisplaySize.y - btnDiameter - 8.0f;
        }

        // Click logic: only toggle if released without dragging
        if (ImGui::IsItemDeactivated() && !s_Dragging && hovered) {
            g_bShowMenu = !g_bShowMenu;
        }

        // Circular drop shadow / ambient glow
        if (hovered || g_bShowMenu) {
            draw->AddCircle(center, btnRadius + 3.0f, IM_COL32(148, 102, 255, 230), 36, 3.5f);
        } else {
            draw->AddCircle(center, btnRadius + 2.0f, IM_COL32(0, 0, 0, 70), 36, 2.5f);
        }

        // Draw Circular Avatar Image
        if (g_pAvatarTextureView) {
            ImVec2 imgMin(center.x - btnRadius, center.y - btnRadius);
            ImVec2 imgMax(center.x + btnRadius, center.y + btnRadius);
            draw->AddImageRounded((ImTextureID)g_pAvatarTextureView, imgMin, imgMax, ImVec2(0, 0), ImVec2(1, 1), IM_COL32(255, 255, 255, 255), btnRadius);
        } else {
            draw->AddCircleFilled(center, btnRadius, IM_COL32(118, 82, 246, 255), 36);
        }

        // White border ring with subtle glass outline
        ImU32 borderCol = g_bShowMenu ? IM_COL32(178, 140, 255, 255) : (hovered ? IM_COL32(255, 255, 255, 255) : IM_COL32(240, 235, 250, 220));
        draw->AddCircle(center, btnRadius, borderCol, 36, 2.2f);

        // Status indicator dot (green = menu open, purple = menu closed)
        ImVec2 badgeCenter(center.x + btnRadius * 0.65f, center.y + btnRadius * 0.65f);
        draw->AddCircleFilled(badgeCenter, 5.5f, g_bShowMenu ? IM_COL32(39, 201, 63, 255) : IM_COL32(128, 90, 220, 255), 16);
        draw->AddCircle(badgeCenter, 5.5f, IM_COL32(255, 255, 255, 255), 16, 1.4f);
    }
    ImGui::End();
    ImGui::PopStyleVar(2);
}
