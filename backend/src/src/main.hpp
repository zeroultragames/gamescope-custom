#pragma once

#include <getopt.h>

#include <atomic>
#include <string>
#include <string_view>

extern const char *gamescope_optstring;
extern const struct option *gamescope_options;

extern std::atomic< bool > g_bRun;

extern int g_nNestedWidth;
extern int g_nNestedHeight;
extern int g_nNestedRefresh; // mHz
extern int g_nNestedUnfocusedRefresh; // mHz
extern int g_nNestedDisplayIndex;

extern uint32_t g_nOutputWidth;
extern uint32_t g_nOutputHeight;
extern bool g_bForceRelativeMouse;
extern int g_nOutputRefresh; // mHz
extern bool g_bOutputHDREnabled;
extern bool g_bForceInternal;

extern bool g_bFullscreen;

extern bool g_bGrabbed;

extern bool g_bPiP;

extern std::string g_sPipCommand;

// 0 = auto (match output aspect). Otherwise width/height (e.g. 16/9).
extern float g_flPipAspectRatio;

// PiP budget-box size as a percent of output width/height. Default 20.
inline constexpr int k_nPipSizePercentMin = 10;
inline constexpr int k_nPipSizePercentMax = 50;
extern int g_nPipSizePercent;

// PiP corner inset as a percent of output (-1 = auto from size).
inline constexpr int k_nPipInsetPercentMin = 0;
inline constexpr int k_nPipInsetPercentMax = 40;
extern int g_nPipInsetPercent;

// Auto inset endpoints when g_nPipInsetPercent < 0 (linear map over size range).
inline constexpr float k_flPipAutoInsetPercentAtMinSize = 20.f;
inline constexpr float k_flPipAutoInsetPercentAtMaxSize = 5.f;

// Parses "16:9", "auto", or "0". Returns false on invalid input.
bool ParsePipAspectRatioArg( std::string_view svArg, float *pOutAspect );

// Parses a whole number in [k_nPipSizePercentMin, k_nPipSizePercentMax].
bool ParsePipSizePercentArg( std::string_view svArg, int *pOutPercent );

// Parses "auto" (-1) or a whole number in [k_nPipInsetPercentMin, k_nPipInsetPercentMax].
bool ParsePipInsetPercentArg( std::string_view svArg, int *pOutPercent );

extern float g_mouseSensitivity;
extern const char *g_sOutputName;

enum class GamescopeUpscaleFilter : uint32_t
{
    LINEAR = 0,
    NEAREST,
    FSR,
    NIS,
    PIXEL,

    FROM_VIEW = 0xF, // internal
};

static constexpr bool DoesHardwareSupportUpscaleFilter( GamescopeUpscaleFilter eFilter )
{
    // Could do nearest someday... AMDGPU DC supports custom tap placement to an extent.

    return eFilter == GamescopeUpscaleFilter::LINEAR;
}

enum class GamescopeUpscaleScaler : uint32_t
{
    AUTO,
    INTEGER,
    FIT,
    FILL,
    STRETCH,
};

extern GamescopeUpscaleFilter g_upscaleFilter;
extern GamescopeUpscaleScaler g_upscaleScaler;
extern GamescopeUpscaleFilter g_wantedUpscaleFilter;
extern GamescopeUpscaleScaler g_wantedUpscaleScaler;
extern int g_upscaleFilterSharpness;

extern bool g_bBorderlessOutputWindow;

extern bool g_bExposeWayland;

extern bool g_bRt;

extern int g_nXWaylandCount;
extern bool g_bNoTouchPointerEmulation;

extern uint32_t g_preferVendorID;
extern uint32_t g_preferDeviceID;

