#-------------------------------------------------------------------------------
#
# This example script shows how to change the resolution of a monitor when a user
# connects to the host.
# It also reverts to the previous resolution when the last user disconnects.
#
# Please note that due to the way Parsec works, the resolution will only change
# when a user that's not the owner connects to the host.
#
#-------------------------------------------------------------------------------

# Choose the monitor you want to change the resolution of
# set it to $null to get the primary monitor
$screenIndex = 0

# Choose the resolution you want to change to
# It doesn't check if the resolution is valid, it fails silently if it isn't
$newRes = @{Width = 1280; Height = 720}

# Save the current resolution so we can revert it when the last user disconnects
# You can also set it manually instead of using Get-Resolution
$originalRes = Get-Resolution -ScreenIndex $screenIndex | Select-Object Width, Height

# Import the resolution module
Import-Module "$PSScriptRoot\..\modules\resolution.psm1"

# Override the OnConnect and OnDisconnect functions with the following:

function OnConnect($user) {
    Write-Host "$user connected"

    # Change the resolution
    Write-Host "Changing resolution to $($newRes.Width)x$($newRes.Height)"
    Set-Resolution -Width $newRes.Width -Height $newRes.Height -ScreenIndex $screenIndex
}

function OnDisconnect($user) {
    Write-Host "$user disconnected"

    # Revert back to the original resolution
    if ($currentlyConnectedUsers.Count -eq 0){
        Write-Host "Reverting resolution to $($originalRes.Width)x$($originalRes.Height)"
        Set-Resolution -Width $originalRes.Width -Height $originalRes.Height -ScreenIndex $screenIndex
    }
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