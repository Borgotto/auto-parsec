# This example enables Cursor Trails when a user connects and disable them when a user disconnects
# This is useful for Android users who can't see the cursor when they connect to a host

# Import the cursor_trails module
Import-Module .\modules\cursor_trails.psm1

# Look for the log file in the two possible locations
$LogFile = if (Test-Path "$env:APPDATA\Parsec\log.txt") {
    "$env:APPDATA\Parsec\log.txt"
} else {
    "$env:ProgramData\parsec\log.txt"
}

# Begin monitoring the log file for changes
# The function body is executed only when a username is detected in a new line
Get-Content $LogFile -Wait -Tail 0 | Where-Object { $_ -match "\]\s(.+#\d+)" } | ForEach-Object {
    if ($_.EndsWith(" connected.")) {
        # This line enables Cursor Trails, setting the trail length to 2
        Set-CursorTrails -Cursors 2
    }
    elseif ($_.EndsWith("disconnected.")) {
        # This line disables Cursor Trails
        Set-CursorTrails -Cursors 0
    }
}