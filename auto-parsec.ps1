# Look for the log file in the two possible locations
$LogFile = if (Test-Path "$env:APPDATA\Parsec\log.txt") {
    "$env:APPDATA\Parsec\log.txt"
} else {
    "$env:ProgramData\parsec\log.txt"
}

# Begin monitoring the log file for changes
# The function body is executed only when a username is detected in a new line
Get-Content $LogFile -Wait -Tail 0 | Where-Object { $_ -match "\]\s(.+#\d+)" } | ForEach-Object {
    $user = $Matches[1]

    if ($_.EndsWith(" connected.")) {
        # Code here runs when a user connects
        Write-Host "$user connected"
    }
    elseif ($_.EndsWith("disconnected.")) {
        # Code here runs when a user disconnects
        Write-Host "$user disconnected"
    }
    elseif ($_.EndsWith("is trying to connect to your computer.")) {
        # Code here runs when a user attempts to connect
        Write-Host "$user is trying to connect"
    }
}