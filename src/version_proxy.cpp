#include <windows.h>
#include <stdio.h>
#include <stdbool.h>
#include "dx11_hook.h"
#include "daniel_menu.h"

static void Log(const char* msg) {
    FILE* f = fopen("C:\\Users\\huynh\\Downloads\\htht by daniel\\daniel_mod.log", "a");
    if (f) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d] [VersionProxy] %s\n", st.wHour, st.wMinute, st.wSecond, msg);
        fclose(f);
    }
}

// -----------------------------------------------------------------------------
// Real System32 version.dll Proxying
// -----------------------------------------------------------------------------
static HMODULE hReal = NULL;
static void InitReal() {
    if (!hReal) {
        wchar_t path[MAX_PATH];
        GetSystemDirectoryW(path, MAX_PATH);
        wcscat(path, L"\\version.dll");
        hReal = LoadLibraryW(path);
        if (hReal) {
            Log("Real System32 version.dll loaded successfully.");
        }
    }
}

static FARPROC GetReal(const char* name) {
    InitReal();
    return hReal ? GetProcAddress(hReal, name) : NULL;
}

extern "C" {

__declspec(dllexport) BOOL WINAPI GetFileVersionInfoA(LPCSTR a, DWORD b, DWORD c, LPVOID d) {
    typedef BOOL (WINAPI *fn_t)(LPCSTR, DWORD, DWORD, LPVOID);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoA");
    return f ? f(a, b, c, d) : FALSE;
}
__declspec(dllexport) BOOL WINAPI GetFileVersionInfoByHandle(int a, HANDLE b, LPVOID c, DWORD d) {
    typedef BOOL (WINAPI *fn_t)(int, HANDLE, LPVOID, DWORD);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoByHandle");
    return f ? f(a, b, c, d) : FALSE;
}
__declspec(dllexport) BOOL WINAPI GetFileVersionInfoExA(DWORD a, LPCSTR b, DWORD c, DWORD d, LPVOID e) {
    typedef BOOL (WINAPI *fn_t)(DWORD, LPCSTR, DWORD, DWORD, LPVOID);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoExA");
    return f ? f(a, b, c, d, e) : FALSE;
}
__declspec(dllexport) BOOL WINAPI GetFileVersionInfoExW(DWORD a, LPCWSTR b, DWORD c, DWORD d, LPVOID e) {
    typedef BOOL (WINAPI *fn_t)(DWORD, LPCWSTR, DWORD, DWORD, LPVOID);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoExW");
    return f ? f(a, b, c, d, e) : FALSE;
}
__declspec(dllexport) DWORD WINAPI GetFileVersionInfoSizeA(LPCSTR a, LPDWORD b) {
    typedef DWORD (WINAPI *fn_t)(LPCSTR, LPDWORD);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoSizeA");
    return f ? f(a, b) : 0;
}
__declspec(dllexport) DWORD WINAPI GetFileVersionInfoSizeExA(DWORD a, LPCSTR b, LPDWORD c) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPCSTR, LPDWORD);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoSizeExA");
    return f ? f(a, b, c) : 0;
}
__declspec(dllexport) DWORD WINAPI GetFileVersionInfoSizeExW(DWORD a, LPCWSTR b, LPDWORD c) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPCWSTR, LPDWORD);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoSizeExW");
    return f ? f(a, b, c) : 0;
}
__declspec(dllexport) DWORD WINAPI GetFileVersionInfoSizeW(LPCWSTR a, LPDWORD b) {
    typedef DWORD (WINAPI *fn_t)(LPCWSTR, LPDWORD);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoSizeW");
    return f ? f(a, b) : 0;
}
__declspec(dllexport) BOOL WINAPI GetFileVersionInfoW(LPCWSTR a, DWORD b, DWORD c, LPVOID d) {
    typedef BOOL (WINAPI *fn_t)(LPCWSTR, DWORD, DWORD, LPVOID);
    fn_t f = (fn_t)GetReal("GetFileVersionInfoW");
    return f ? f(a, b, c, d) : FALSE;
}
__declspec(dllexport) DWORD WINAPI VerFindFileA(DWORD a, LPSTR b, LPSTR c, LPSTR d, LPSTR e, PUINT f, LPSTR g, PUINT h) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPSTR, LPSTR, LPSTR, LPSTR, PUINT, LPSTR, PUINT);
    fn_t f_ptr = (fn_t)GetReal("VerFindFileA");
    return f_ptr ? f_ptr(a, b, c, d, e, f, g, h) : 0;
}
__declspec(dllexport) DWORD WINAPI VerFindFileW(DWORD a, LPWSTR b, LPWSTR c, LPWSTR d, LPWSTR e, PUINT f, LPWSTR g, PUINT h) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPWSTR, LPWSTR, LPWSTR, LPWSTR, PUINT, LPWSTR, PUINT);
    fn_t f_ptr = (fn_t)GetReal("VerFindFileW");
    return f_ptr ? f_ptr(a, b, c, d, e, f, g, h) : 0;
}
__declspec(dllexport) DWORD WINAPI VerInstallFileA(DWORD a, LPSTR b, LPSTR c, LPSTR d, LPSTR e, LPSTR f, LPSTR g, PUINT h) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPSTR, LPSTR, LPSTR, LPSTR, LPSTR, LPSTR, PUINT);
    fn_t f_ptr = (fn_t)GetReal("VerInstallFileA");
    return f_ptr ? f_ptr(a, b, c, d, e, f, g, h) : 0;
}
__declspec(dllexport) DWORD WINAPI VerInstallFileW(DWORD a, LPWSTR b, LPWSTR c, LPWSTR d, LPWSTR e, LPWSTR f, LPWSTR g, PUINT h) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPWSTR, LPWSTR, LPWSTR, LPWSTR, LPWSTR, LPWSTR, PUINT);
    fn_t f_ptr = (fn_t)GetReal("VerInstallFileW");
    return f_ptr ? f_ptr(a, b, c, d, e, f, g, h) : 0;
}
__declspec(dllexport) DWORD WINAPI VerLanguageNameA(DWORD a, LPSTR b, DWORD c) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPSTR, DWORD);
    fn_t f = (fn_t)GetReal("VerLanguageNameA");
    return f ? f(a, b, c) : 0;
}
__declspec(dllexport) DWORD WINAPI VerLanguageNameW(DWORD a, LPWSTR b, DWORD c) {
    typedef DWORD (WINAPI *fn_t)(DWORD, LPWSTR, DWORD);
    fn_t f = (fn_t)GetReal("VerLanguageNameW");
    return f ? f(a, b, c) : 0;
}
__declspec(dllexport) BOOL WINAPI VerQueryValueA(LPCVOID a, LPCSTR b, LPVOID *c, PUINT d) {
    typedef BOOL (WINAPI *fn_t)(LPCVOID, LPCSTR, LPVOID *, PUINT);
    fn_t f = (fn_t)GetReal("VerQueryValueA");
    return f ? f(a, b, c, d) : FALSE;
}
__declspec(dllexport) BOOL WINAPI VerQueryValueW(LPCVOID a, LPCWSTR b, LPVOID *c, PUINT d) {
    typedef BOOL (WINAPI *fn_t)(LPCVOID, LPCWSTR, LPVOID *, PUINT);
    fn_t f = (fn_t)GetReal("VerQueryValueW");
    return f ? f(a, b, c, d) : FALSE;
}

} // extern "C"

HINSTANCE g_hModInstance = NULL;

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        g_hModInstance = hinst;
        DisableThreadLibraryCalls(hinst);
        char modPath[MAX_PATH];
        GetModuleFileNameA(NULL, modPath, MAX_PATH);
        if (strstr(modPath, "LegendaryPirates.exe") != NULL) {
            HMODULE hVer = GetModuleHandleW(L"VERSION.dll");
            if (hVer != NULL && hVer != hinst) {
                Log("=== DANIEL_MOD.DLL INJECTED INTO RUNNING GAME (VERSION.DLL ALREADY ACTIVE) ===");
                CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)InitIL2CPP, NULL, 0, NULL);
            } else {
                Log("=== DANIEL MOD: VERSION.DLL LOADED IN LEGENDARYPIRATES.EXE ===");
                StartD3D11Hook();
            }
        } else {
            char msg[512];
            sprintf(msg, "Skipping hook for process: %s", modPath);
            Log(msg);
        }
    }
    return TRUE;
}
