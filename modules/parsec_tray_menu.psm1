# This module simulates button presses in the Parsec tray menu by sending the
# same message to the Parsec window that the tray menu would send.

# Messages can't be sent directly to a process running with elevated privileges,
# this means that Parsec needs to be run as a normal user for this to work.
# you can stop Parsec from running as admin by stopping the Parsec service.
#
# This will cause issues with the Parsec client like:
#   - Parsec not starting when the computer starts
#   - Stream freezing on UAC prompts
#   - Parsec Virtual Display Driver not working

# If the commands don't work, try running the script as admin or right clicking
# the Parsec tray icon at least once.

Add-Type -TypeDefinition @'
    using System;
    using System.Runtime.InteropServices;

    public class MessageSender {
        private const uint WM_COMMAND = 0x0111;
        public const uint FIRST_BUTTON_ID = 0x000003E8;

        [DllImport("user32.dll")]
        private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        private static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        public static bool SendMessageToParsec(IntPtr buttonId) {
            // Get the Window Handle of Parsec
            IntPtr hwnd = FindWindow("MTY_Window", "Parsec");
            if (hwnd == IntPtr.Zero) {
                return false;
            }

            // Send the message
            SendMessage(hwnd, WM_COMMAND, buttonId, new IntPtr(0));
            return true;
        }
    }
'@

function ResetGamepads {
    [MessageSender]::SendMessageToParsec([MessageSender]::FIRST_BUTTON_ID + 0)
}

function ToggleStartAtBoot {
    [MessageSender]::SendMessageToParsec([MessageSender]::FIRST_BUTTON_ID + 1)
}

function RestartParsec {
    [MessageSender]::SendMessageToParsec([MessageSender]::FIRST_BUTTON_ID + 2)
}

function QuitParsec {
    [MessageSender]::SendMessageToParsec([MessageSender]::FIRST_BUTTON_ID + 3)
}
