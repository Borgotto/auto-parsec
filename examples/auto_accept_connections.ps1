#-----------------------------------------------------------------------------
#
# This example will automatically accept all incoming connection requests.
#
# It can be useful to simulate the Parsec Arcade experience where users
# can connect without any interaction from the host.
#
#-----------------------------------------------------------------------------

# Ban list to prevent certain users from connecting.
#
# Please note that this is NOT a reliable way to prevent users from connecting,
# as they can easily get accepted by trying to connect at the same time as
# someone else or by simply changing their username.
$ban_file = "/path/to/ban_list.txt"

# Import the key_presses module
Import-Module $PSScriptRoot\..\modules\key_presses.psm1

# Override the OnConnectAttempt function with the following:
function OnConnectAttempt($user) {
    # If the user is in the ban list, don't let them in
    if (Get-Content $ban_file -ErrorAction Ignore | Select-String "\b($user)\b") {
        Write-Warning "$user is banned, NOT letting them in..."
        return
    }

    # Auto accept all incoming connections by pressing Ctrl + F1
    Write-Host "$user is trying to connect, letting them in..."
    Send-Keys -Keys "^({F1 3})"
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
