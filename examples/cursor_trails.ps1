# This example shows how to enable Cursor Trails when a user connects and disable them when a user disconnects
# This is useful for Android users who can't see the cursor when they connect to a host

$LogFile = "C:\ProgramData\Parsec\log.txt"

# Import the cursor_trails module
Import-Module .\modules\cursor_trails.psm1

# Begin monitoring the log file for changes
# The function body is executed only when a username is detected in a new line
Get-Content $LogFile -Wait -Tail 0 | Where-Object { $_ -match "\]\s(.+#\d+)" } | ForEach-Object {
    $user = $Matches[1]

    if ($_.EndsWith(" connected.")) {
        # Code here runs when a user connects

        # This line enables Cursor Trails
        Set-CursorTrails -Cursors 2
    }
    elseif ($_.EndsWith("disconnected.")) {
        # Code here runs when a user disconnects

        # This line disables Cursor Trails
        Set-CursorTrails -Cursors 0
    }
    elseif ($_.EndsWith("is trying to connect to your computer.")) {
        # Code here runs when a user attempts to connect
    }
}