#-------------------------------------------------------------------------------
#
# This example will disable physical monitors when a client connects and
# re-enable them when the client disconnects.
#
# It's an alternative to the paid Parsec Warp feature "Privacy Mode".
# If you like this feature, consider supporting Parsec by subscribing to Warp.
#
# Unlike Privacy Mode, this script won't provide a virtual display driver.
# Install your own virtual display adapter.
#
# Read more about it in the 'vdd.psm1' module.
#
# This script requires admin privileges to enable/disable display adapters.
#
#-------------------------------------------------------------------------------

# Import the vdd module
Import-Module "$PSScriptRoot\..\modules\vdd.psm1"

function OnConnect($user) {
    Enable-PrivacyMode | Out-Null
}

function OnDisconnect($user) {
    # Log out the Windows user
    rundll32.exe user32.dll,LockWorkStation

    Disable-PrivacyMode | Out-Null
}



#-------------------------------------------------------------------------------
#
# This part is the same for all examples scripts that run auto-parsec.
# You probably shouldn't modify it.
#
#-------------------------------------------------------------------------------

# Prevent function definitions from being overwritten by auto-parsec
("OnConnect", "OnDisconnect", "OnConnectAttempt") | ForEach-Object {
    Set-Item function:$_ -Options ReadOnly
}

# Ignore the error when auto-parsec tries to overwrite the functions
$ErrorActionPreference = "SilentlyContinue"

# Run the auto-parsec script with the custom functions defined above
. $PSScriptRoot\..\auto-parsec.ps1