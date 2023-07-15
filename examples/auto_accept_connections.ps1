#-----------------------------------------------------------------------------
#
# This example will automatically accept all incoming connection requests.
#
# It can be useful to simulate the Parsec Arcade experience where users
# can connect without any interaction from the host.
#
#-----------------------------------------------------------------------------

# Import the key_presses module
Import-Module $PSScriptRoot\..\modules\key_presses.psm1

# Override the OnConnectAttempt function with the following:
function OnConnectAttempt($user) {
    Write-Host "$user is trying to connect, letting them in..."
    # Auto accept all incoming connections by pressing Ctrl + F1
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