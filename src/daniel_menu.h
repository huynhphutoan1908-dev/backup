#pragma once
#include <windows.h>
#include <stdint.h>
#include <d3d11.h>
#include <imgui.h>

void InitIL2CPP();
void SetupModernGlassTheme();
void RenderDanielMenu();
void RenderFloatingToggleButton();
void InitAvatarTexture(ID3D11Device* pDevice);
void ApplyGameSpeed(float speed);

extern ID3D11ShaderResourceView* g_pAvatarTextureView;
void EnforceGameSpeed();
void OnUnityMainThreadUpdate();
bool IsBoxOrbSummonValid();
bool IsLuckySpinValid();
bool IsSuperLuckySpinValid();
bool ExecuteLua(const char* luaCode, char* outMsg = nullptr, size_t msgBufSize = 0);
void SetFruitSkipAnimation(bool enable);

extern bool g_bShowMenu;
extern float g_GameSpeed;
extern bool g_bLockSpeed;
extern int g_CurrentTab;

// Summon features
extern void* g_pBoxOrbSummon;
extern bool g_bAutoSummonRunning;
extern bool g_bSingleSummonQueued;
extern bool g_bGoToSummonQueued;
extern bool g_bFactionChangeQueued;
extern bool g_bRotateFaction;
extern bool g_bFastEffect;
extern bool g_bInfiniteLoop;
extern int g_SelectedFactionId;
extern int64_t g_SummonRounds;
extern int64_t g_CompletedRounds;

// Wheel (Vòng Quay) features
extern void* g_pLuckySpinScene;
extern void* g_pSuperLuckySpinScene;
extern bool g_bWheelRunning;
extern bool g_bWheelGoToQueued;
extern bool g_bWheelSkipAnimation;
extern int g_WheelMode;
extern int g_WheelBatchSize;
extern int64_t g_WheelBatches;
extern int64_t g_WheelCompletedBatches;
extern int64_t g_WheelTotalSpins;
extern bool g_bWheelContinuous;
extern int g_WheelTargetItems;
extern bool g_bWheelRefreshAfterTarget;
extern bool g_bWheelAllowGems;
extern int64_t g_WheelGemBudget;
extern int64_t g_WheelGemsUsed;
extern bool g_bWheelAutoContinue;
extern char g_WheelStatusText[256];

// Fruit Wheel features
extern int g_FruitWheelMode;
extern int g_FruitBatchSize;
extern int64_t g_FruitBatches;
extern int64_t g_FruitCompletedBatches;
extern bool g_bFruitContinuous;
extern bool g_bFruitRunning;
extern char g_FruitStatusText[256];

extern ImFont* g_FontRegular;
extern ImFont* g_FontBold;
extern ImFont* g_FontTitle;
extern ImFont* g_FontSmall;
extern ImFont* g_FontLogo;
extern ImFont* g_FontIcons;

void TriggerUnloadMod();

