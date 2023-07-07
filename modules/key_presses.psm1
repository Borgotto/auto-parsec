# This class is used to simulate key presses.
# Keycodes can be found here: https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.sendkeys
Add-Type -AssemblyName System.Windows.Forms

# This function simulates a key press.
# The $key parameter can be a single key or a combination of keys.
function Send-Keys {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Keys
    )

    # This line simulates the key press.
    return [System.Windows.Forms.SendKeys]::SendWait($Keys)
}