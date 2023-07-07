# This script will automatically accept all incoming connection requests.
# It can be useful to simulate the Parsec Arcade experience where users
# can connect without any interaction from the host.

# Import the key_presses module
Import-Module .\modules\key_presses.psm1

# Look for the log file in the two possible locations
$LogFile = if (Test-Path "$env:APPDATA\Parsec\log.txt") {
    "$env:APPDATA\Parsec\log.txt"
} else {
    "$env:ProgramData\parsec\log.txt"
}

# Begin monitoring the log file for changes
# The function body is executed only when a username is detected in a new line
Get-Content $LogFile -Wait -Tail 0 | Where-Object { $_ -match "\]\s(.+#\d+)" } | ForEach-Object {
    if ($_.EndsWith("is trying to connect to your computer.")) {
        # Accept the connection request (Ctrl + F1)
        Send-Keys -Keys "^{F1}"
    }
}