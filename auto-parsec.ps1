#-------------------------------------------------------------------------------
#
# These 3 functions are called when a user connects, disconnects, or attempts to
# connect to your computer.
#
# You can edit these functions to do whatever you want or use the already
# existing examples in the 'examples' folder.
#
#-------------------------------------------------------------------------------

# This List keeps track of which users are currently connected
$currentlyConnectedUsers = New-Object System.Collections.ArrayList

function OnConnect($user) {
    # Code here runs when a user connects
    Write-Host "$user connected"
    Write-Host "Currently connected users: $currentlyConnectedUsers"
}

function OnDisconnect($user) {
    # Code here runs when a user disconnects
    Write-Host "$user disconnected"
    Write-Host "Currently connected users: $currentlyConnectedUsers"
}

function OnConnectAttempt($user) {
    # Code here runs when a user attempts to connect
    Write-Host "$user is trying to connect"
}



#-------------------------------------------------------------------------------
#
# The code below handles reading the log file and calling the functions above.
# You shouldn't need to modify anything below this line.
#
#-------------------------------------------------------------------------------

# Set the debug preference
# "SilentlyContinue" to hide debug prints, "Continue" to show them
$DebugPreference = "SilentlyContinue"

# Set the error action preference
# "SilentlyContinue" to hide errors, "Continue" to show them
$ErrorActionPreference = "Continue"


# Look for the log file in the two possible locations
$LogFile = if (Test-Path "$env:APPDATA\Parsec\log.txt") {
    "$env:APPDATA\Parsec\log.txt"
} else {
    "$env:ProgramData\parsec\log.txt"
}


# This variable helps with resuming reading the file after IOErrors
$lastRead = Get-Content $LogFile |
            Where-Object { $_ -match '\S' } |
            Select-Object -Last 1


# Read the log file forever
Write-Host "Script started. Press Ctrl + C to stop."
while($true) {
    try {
        # Set 'unreadLines' to how many lines are in the file after 'lastRead'
        $unreadLines = 0
        while($lastRead -ne
            (Get-Content $LogFile -Tail ($unreadLines + 1) -ErrorAction Stop |
                Select-Object -First 1)) {
            $unreadLines += 1
        }

        # Start reading the log file from the last line we read
        Get-Content $LogFile -Wait -Tail $unreadLines -ErrorAction Stop |
        ForEach-Object {
            Write-Debug $_

            # If the line is not empty, update lastRead
            if ($_ -match "\S") {
                $lastRead = $_
            }

            # If the line contains a username, call the appropriate function
            if ($_ -match "\]\s(.+#\d+)") {
                $user = $Matches[1]

                if ($_.EndsWith(" connected.")) {
                    $currentlyConnectedUsers.Add($user) | Out-Null
                    OnConnect($user)
                }
                elseif ($_.EndsWith("disconnected.")) {
                    $currentlyConnectedUsers.Remove($user) | Out-Null
                    OnDisconnect($user)
                }
                elseif ($_.EndsWith("is trying to connect to your computer.")) {
                    OnConnectAttempt($user)
                }
            }
        }
    }
    catch {
        if ($_.Exception.GetType().Name -eq "IOException") {
            # Warn the user if it failed to read the log file
            Write-Warning "failed to read $($unreadLines + 1) lines, retrying..."
        }
        elseif ($_.TargetObject -in ("OnConnect","OnDisconnect","OnConnectAttempt")) {
            # Ignore not implemented errors
            continue
        }
        else {
            # Print error message
            Write-Error "error $($_.Exception.GetType().Name): $_"
        }
    }
}

# Pause the script so that the window doesn't close immediately
Read-Host -Prompt "Press Enter to exit..."