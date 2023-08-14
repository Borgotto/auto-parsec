# Rectangle struct
Add-Type -AssemblyName System.Drawing

# Needed to get the screens bounds
Add-Type -AssemblyName System.Windows.Forms

# Import WinAPI functions to move the windows around
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public struct RECT {
        public int Left;        // x position of upper-left corner
        public int Top;         // y position of upper-left corner
        public int Right;       // x position of lower-right corner
        public int Bottom;      // y position of lower-right corner

        public int Width { get { return Right - Left; } }
        public int Height { get { return Bottom - Top; } }

        public RECT(int left, int top, int right, int bottom) {
            Left = left;
            Top = top;
            Right = right;
            Bottom = bottom;
        }
    }

    public struct POINT {
        public int X;
        public int Y;
    }

    [Serializable]
    [StructLayout(LayoutKind.Sequential)]
    public struct WINDOWPLACEMENT
    {
        public int Length;
        public int Flags;
        public int ShowCmd;
        public POINT MinPosition;
        public POINT MaxPosition;
        public RECT NormalPosition;
    }

    public class Window {
        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetWindowPlacement(IntPtr hWnd, [In] ref WINDOWPLACEMENT lpwndpl);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern bool IsWindowVisible(IntPtr hWnd);

        private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        public static IntPtr[] EnumerateWindows() {
            IntPtr[] windows = new IntPtr[0];
            EnumWindowsProc enumProc = delegate(IntPtr hWnd, IntPtr lParam) {
                if (IsWindowVisible(hWnd) && GetWindowTitle(hWnd) != null) {
                    Array.Resize(ref windows, windows.Length + 1);
                    windows[windows.Length - 1] = hWnd;
                }
                return true;
            };
            EnumWindows(enumProc, IntPtr.Zero);
            return windows;
        }

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpWindowText, int nMaxCount);

        public static string GetWindowTitle(IntPtr hWnd) {
            const int nChars = 1024;
            StringBuilder sb = new StringBuilder(nChars);
            if (GetWindowText(hWnd, sb, nChars) > 0) {
                return sb.ToString();
            }
            return null;
        }

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        public static uint GetWindowProcessId(IntPtr hWnd) {
            uint processId;
            GetWindowThreadProcessId(hWnd, out processId);
            return processId;
        }

        [DllImport("user32.dll")]
        private static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);

        public static bool CanResizeWindow(IntPtr hWnd) {
            const int GWL_STYLE = -16;
            const int WS_SIZEBOX = 0x00040000;
            return (GetWindowLongPtr(hWnd, GWL_STYLE).ToInt64() & WS_SIZEBOX) != 0;
        }
    }
"@

function Move-WindowsToMonitor {
    param (
        [Parameter(Mandatory = $false)]
        [int]$ScreenIndex
    )

    # Get all connected screens
    $screens = [System.Windows.Forms.Screen]::AllScreens

    # Select the target screen
    if ($ScreenIndex -eq $null) {
        # If no monitor is specified, default to the primary monitor
        $targetScreen = $screens | Where-Object { $_.Primary -eq $true }
    }
    elseif ($ScreenIndex -lt 0 -or $ScreenIndex -ge $screens.Length) {
        # If the specified monitor is out of range, error out
        Write-Error "Invalid monitor. Valid indices are 0 through $($screens.Length - 1)."
        return
    } else {
        # Otherwise, use the specified monitor
        $targetScreen = $screens[$ScreenIndex]
    }

    # Call EnumerateWindows to get an array containing all open windows handles
    $handles = [Window]::EnumerateWindows()

    # Move each (responding) window to the target monitor
    foreach ($handle in $handles) {
        # Get the window process
        $process = Get-Process -Id ([Window]::GetWindowProcessId($handle))

        # Get the window title
        $title = [Window]::GetWindowTitle($handle)
        Write-Host "`nMoving '$($title)'" -ForegroundColor Green

        # Skip if the process is not responding
        if ($process.Responding -eq $false) {
            Write-Warning "Skipping unresponsive process $($process.Name)"
            continue
        }

        # Get the current window placement
        $placement = New-Object -TypeName WINDOWPLACEMENT
        $result = [Window]::GetWindowPlacement($handle, [ref]$placement)

        # Map each screen to window area in that screen
        $screenAreas = @{}
        foreach ($screen in $screens) {
            # Calculate the area of the window that is in the screen
            $area = [Math]::Max(0,
                        [Math]::Min($placement.NormalPosition.Right, $screen.Bounds.Right) -
                        [Math]::Max($placement.NormalPosition.Left, $screen.Bounds.Left)
                    ) *
                    [Math]::Max(0,
                        [Math]::Min($placement.NormalPosition.Bottom, $screen.Bounds.Bottom) -
                        [Math]::Max($placement.NormalPosition.Top, $screen.Bounds.Top)
                    )
            $screenAreas[$screen] = $area
        }

        # Get the screen with the most window area
        $windowScreen = $screenAreas.GetEnumerator() |
                        Sort-Object -Property Value -Descending |
                        Select-Object -First 1 -ExpandProperty Key

        # Print current window position
        Write-Host "Current screen:   $($windowScreen.DeviceName)  $($windowScreen.Bounds.Width) x $($windowScreen.Bounds.Height)"
        Write-Host "Current position: x=$($placement.NormalPosition.Left) y=$($placement.NormalPosition.Top)"
        Write-Host "Current size:     $($placement.NormalPosition.Width) x $($placement.NormalPosition.Height)"

        # Define the new window coordinates
        if ([Window]::CanResizeWindow($handle)) {
            # If the window is resizable, scale the window to the target screen
            $newLeft =   (($placement.NormalPosition.Left   - $windowScreen.Bounds.Left) / $windowScreen.Bounds.Width  * $targetScreen.Bounds.Width )
            $newTop =    (($placement.NormalPosition.Top    - $windowScreen.Bounds.Top ) / $windowScreen.Bounds.Height * $targetScreen.Bounds.Height)
            $newRight =  (($placement.NormalPosition.Right  - $windowScreen.Bounds.Left) / $windowScreen.Bounds.Width  * $targetScreen.Bounds.Width )
            $newBottom = (($placement.NormalPosition.Bottom - $windowScreen.Bounds.Top ) / $windowScreen.Bounds.Height * $targetScreen.Bounds.Height)
        } else {
            # otherwise, position it in the top-left corner of the target screen
            $newLeft =   $targetScreen.WorkingArea.Left
            $newTop =    $targetScreen.WorkingArea.Top
            $newRight =  $targetScreen.WorkingArea.Left + $placement.NormalPosition.Width
            $newBottom = $targetScreen.WorkingArea.Top  + $placement.NormalPosition.Height
        }

        # Update the window placement struct
        $placement.NormalPosition = New-Object -TypeName RECT -ArgumentList (
            $newLeft,
            $newTop,
            $newRight,
            $newBottom
        )

        # Print new window position
        Write-Host "`nNew screen:       $($targetScreen.DeviceName)  $($targetScreen.Bounds.Width) x $($targetScreen.Bounds.Height)"
        Write-Host "New position:     x=$($placement.NormalPosition.Left), y=$($placement.NormalPosition.Top)"
        Write-Host "New size:         $($placement.NormalPosition.Width) x $($placement.NormalPosition.Height)"

        # Print show command
        Write-Host "`nShow command:     $($placement.ShowCmd)"
        # Print flags
        Write-Host "Flags:            $($placement.Flags)"
        # Print if the window is resizable
        Write-Host "Resizable:        $([Window]::CanResizeWindow($handle))"

        # If the window is maximized, set the new window state to normal,
        # move the window, then set it back to maximized.
        if ($placement.ShowCmd -eq 3) {
            $placement.ShowCmd = 1 # SW_NORMAL
            $result = [Window]::SetWindowPlacement($handle, [ref]$placement)
            $placement.ShowCmd = 3 # SW_MAXIMIZE
        }

        # If the window is minimized, set the new window state to normal,
        # move the window, then set it back to minimized.
        if ($placement.ShowCmd -eq 2) {
            $placement.ShowCmd = 1 # SW_NORMAL
            $result = [Window]::SetWindowPlacement($handle, [ref]$placement)
            $placement.ShowCmd = 2 # SW_MINIMIZE
        }

        # Set the new window position
        $result = [Window]::SetWindowPlacement($handle, [ref]$placement)
    }

    Write-Host "`nDone!" -ForegroundColor Green
}
