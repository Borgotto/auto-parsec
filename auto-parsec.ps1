$LogFile = "C:\ProgramData\Parsec\log.txt"

# Begin monitoring the log file for changes
# The function body is executed only when a username is detected in a new line
Get-Content $LogFile -Wait -Tail 0 | Where-Object { $_ -match "\]\s(.+#\d+)" } | ForEach-Object {
    $user = $Matches[1]

    if ($_.EndsWith(" connected.")) {
        # Code here runs when a user connects
    }
    elseif ($_.EndsWith("disconnected.")) {
        # Code here runs when a user disconnects
    }
    elseif ($_.EndsWith("is trying to connect to your computer.")) {
        # Code here runs when a user attempts to connect
    }
}