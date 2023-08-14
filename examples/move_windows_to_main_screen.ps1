#-------------------------------------------------------------------------------
#
# This example will move every open Window to the top left corner of the screen
# when a user connects to the host.
#
# It can be handy in case you have multiple monitors at home but you're
# connecting from a device with a single display.
# This makes sure you can see all your windows when you connect without having
# to move them manually.
#
#-------------------------------------------------------------------------------

# Import the windows module
Import-Module $PSScriptRoot\..\modules\windows.psm1

function OnConnect($user) {
    Write-Host "$user connected"

    # Omit the ScreenIndex parameter to move all windows to the main monitor
    Move-WindowsToMonitor -ScreenIndex 0
}



#-------------------------------------------------------------------------------
#
# This part is the same for all examples scripts that run the main script.
# You probably shouldn't modify it.
#
#-------------------------------------------------------------------------------

# Prevent function definitions from being overwritten by the main script
("OnConnect", "OnDisconnect", "OnConnectAttempt") | ForEach-Object {
    Set-Item function:$_ -Options ReadOnly
}

# Ignore errors when the main script tries to overwrite the functions
$ErrorActionPreference = "SilentlyContinue"

# Run the main script with the custom functions defined above
. $PSScriptRoot\..\auto-parsec.ps1