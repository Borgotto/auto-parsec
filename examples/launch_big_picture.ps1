# This script launches Steam Big Picture when a user connects to the host computer
# It also closes Big Picture when the user disconnects
# It's a good way to play games on your host computer with only a controller

# Look for the log file in the two possible locations
$LogFile = if (Test-Path "$env:APPDATA\Parsec\log.txt") {
    "$env:APPDATA\Parsec\log.txt"
} else {
    "$env:ProgramData\parsec\log.txt"
}

# Begin monitoring the log file for changes
# The function body is executed only when a username is detected in a new line
Write-Host "Script started. Press Ctrl + C to stop."
Get-Content $LogFile -Wait -Tail 0 | Where-Object { $_ -match "\]\s(.+#\d+)" } | ForEach-Object {
    if ($_.EndsWith(" connected.")) {
        # Launch Steam Big Picture
        Start-Process "steam://open/bigpicture"
    }
    elseif ($_.EndsWith("disconnected.")) {
        # Close Steam
        Get-Process "Steam" | Stop-Process
    }
}