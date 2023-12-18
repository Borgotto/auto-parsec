# This module allows you to change the resolution of a monitor.
# It doesn't check if the resolution is valid, it fails silently if it isn't.

Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public class WinAPI {
        // Constants

        // MONITORINFO.dwFlags flags
        public const int MONITORINFOF_PRIMARY = 1;

        // DEVMODE.dmFields flags
        public const int DM_PELSWIDTH = 524288;
        public const int DM_PELSHEIGHT = 1048576;
        public const int DM_DISPLAYFREQUENCY = 4194304;

        // EnumDisplaySettingsEx flags
        public const int ENUM_CURRENT_SETTINGS = -1;
        public const int ENUM_REGISTRY_SETTINGS = -2;

        // Structs

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT {
            public int x;
            public int y;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct MONITORINFOEX {
            public int cbSize;
            public RECT rcMonitor;
            public RECT rcWork;
            public int dwFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string szDevice;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct DEVMODE {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string dmDeviceName;
            public short dmSpecVersion;
            public short dmDriverVersion;
            public short dmSize;
            public short dmDriverExtra;
            public int dmFields;

            public POINT dmPosition;
            public int dmDisplayOrientation;
            public int dmDisplayFixedOutput;

            public short dmColor;
            public short dmDuplex;
            public short dmYResolution;
            public short dmTTOption;
            public short dmCollate;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string dmFormName;
            public short dmLogPixels;
            public int dmBitsPerPel;
            public int dmPelsWidth;
            public int dmPelsHeight;

            public int dmDisplayFlags;
            public int dmNup;

            public int dmDisplayFrequency;
            public int dmICMMethod;
            public int dmICMIntent;
            public int dmMediaType;
            public int dmDitherType;
            public int dmReserved1;
            public int dmReserved2;
            public int dmPanningWidth;
            public int dmPanningHeight;
        }

        // Functions

        [DllImport("user32.dll")]
        public static extern int EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, IntPtr lpfnEnum, int dwData);
        public delegate bool MonitorEnumDelegate(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);

        [DllImport("User32.dll")]
        public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFOEX lpmi);

        [DllImport("user32.dll")]
        public static extern int EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);

        [DllImport("user32.dll")]
        public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, uint dwflags, IntPtr lParam);
    }
"@

function Set-Resolution {
    param(
        [int]$ScreenIndex = -1,
        [int]$Width,
        [int]$Height
    )

    $monitor = Get-Resolution -ScreenIndex $ScreenIndex

    # Get the current display settings for the monitor
    $devMode = New-Object WinAPI+DEVMODE
    $devMode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devMode)
    [WinAPI]::EnumDisplaySettings($monitor.DeviceName,
                                [WinAPI]::ENUM_CURRENT_SETTINGS,
                                [ref]$devMode) | Out-Null

    # Set the new display settings for the monitor
    if ($Width) {
        $devMode.dmPelsWidth = $Width
        $devMode.dmFields = $devMode.dmFields -bor [WinAPI]::DM_PELSWIDTH
    }
    if ($Height) {
        $devMode.dmPelsHeight = $Height
        $devMode.dmFields = $devMode.dmFields -bor [WinAPI]::DM_PELSHEIGHT
    }

    # Apply the new settings
    return [WinAPI]::ChangeDisplaySettingsEx($monitor.DeviceName, [ref]$devMode, 0, 0, 0)
}

function Get-Resolution {
    param(
        [int]$ScreenIndex = -1
    )

    $monitors = New-Object System.Collections.ArrayList

    # Enumerate all monitors
    $delegate = [WinAPI+MonitorEnumDelegate] {
        param([IntPtr]$hMonitor,[IntPtr]$hdcMonitor,[ref]$lprcMonitor,[IntPtr]$dwData)

        # Get info about the monitor
        $monitorInfo = New-Object WinAPI+MONITORINFOEX
        $monitorInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($monitorInfo)
        [WinAPI]::GetMonitorInfo($hMonitor, [ref]$monitorInfo) | Out-Null

        # Add the monitor to the list
        $monitors.Add([PSCustomObject]@{
            DeviceName = $monitorInfo.szDevice
            Handle = $hMonitor
            Width = $monitorInfo.rcMonitor.Right - $monitorInfo.rcMonitor.Left
            Height = $monitorInfo.rcMonitor.Bottom - $monitorInfo.rcMonitor.Top
            Primary = [bool]($monitorInfo.dwFlags -band [WinAPI]::MONITORINFOF_PRIMARY)
        })

        # Return $true to continue enumerating monitors
        return $true
    }
    $callback = [System.Runtime.InteropServices.Marshal]::GetFunctionPointerForDelegate($delegate)
    [WinAPI]::EnumDisplayMonitors(0, 0, $callback, 0) | Out-Null


    # Return the monitor with the specified index or the primary monitor if no index is specified
    if ($ScreenIndex -eq -1) {
        return $monitors | Where-Object { $_.Primary }
    } elseif ($ScreenIndex -ge 0 -and $ScreenIndex -lt $monitors.Count) {
        return $monitors[$ScreenIndex]
    } else {
        throw "Invalid screen index: $ScreenIndex"
    }
}