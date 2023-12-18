#-------------------------------------------------------------------------------
#
# This example launches Steam Big Picture when a user connects and it closes
# Steam Big Picture when the users disconnects.
#
# It's a good way to play games on your host computer with only a controller
#
# You could also change this so that it launches Big Picture only when you
# connect and not for other users.
#
#-------------------------------------------------------------------------------

# Override the OnConnect and OnDisconnect functions with the following:

function OnConnect($user) {
    Write-Host "$user connected, launching Steam Big Picture"

    # Launch Steam Big Picture
    Start-Process "steam://open/bigpicture"
}

function OnDisconnect($user) {
    Write-Host "$user disconnected, closing Steam"

    # Close Steam
    $steamProcesses = Get-Process | Where-Object { $_.MainWindowTitle -like "*Big Picture*" }
    if ($currentlyConnectedUsers.Count -eq 0) {
        if ($steamProcesses | ForEach-Object {$_.CloseMainWindow()}) {
            Write-Host "Steam Big Picture closed"
        } else {
            Write-Host "Steam Big Picture not running"
        }
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
