#pragma once
#include <windows.h>

void InitEarlyHooks();
void StartD3D11Hook();
void TriggerUnloadMod();
extern HINSTANCE g_hModInstance;

