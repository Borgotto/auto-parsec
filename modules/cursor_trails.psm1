# Add C# call the Win32 API function SystemParametersInfo to change mouse cursor properties
# https://learn.microsoft.com/windows/desktop/api/winuser/nf-winuser-systemparametersinfoa
$CSharpSig = @'
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
'@
$CursorRefresh = Add-Type -MemberDefinition $CSharpSig -Name WinAPICall -Namespace SystemParamInfo -PassThru

function Set-CursorTrails([ValidateRange(0, 7)][int]$Cursors) {
    return $CursorRefresh::SystemParametersInfo(0x005D, $Cursors, $null, 0) | Out-Null
}