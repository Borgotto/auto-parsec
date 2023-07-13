#-------------------------------------------------------------------------------
#
# This example enables Cursor Trails when a user connects and disable them when
# a user disconnects.
#
# This is useful for Android users who can't see the cursor when they connect
# to a host
#
#-------------------------------------------------------------------------------

# Import the cursor_trails module
Import-Module $PSScriptRoot\..\modules\cursor_trails.psm1

# Override the OnConnect and OnDisconnect functions with the following:

function OnConnect($user) {
    Write-Host "$user connected"

    # If this is the first user to connect, enable Cursor Trails
    if ($currentlyConnectedUsers.Count -eq 1) {
        Write-Host "Enabling Cursor Trails"

        # This line enables Cursor Trails
        # (setting the trail length to 10000 allows the cursor to be visible
        #   on Android while not impacting the user experience on Windows)
        Set-CursorTrails -Cursors 10000
    }
}

function OnDisconnect($user) {
    Write-Host "$user disconnected"

    # If there are no more connected users, disable Cursor Trails
    if ($currentlyConnectedUsers.Count -eq 0) {
        Write-Host "Disabling Cursor Trails"

        # This line disables Cursor Trails
        Set-CursorTrails -Cursors 0
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