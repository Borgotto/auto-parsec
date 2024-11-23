# This module will try to use either one of these two virtual display drivers:
# https://github.com/itsmikethetech/Virtual-Display-Driver
# https://www.amyuni.com/forum/viewtopic.php?t=3030
#
# I plan to add support for:
# https://github.com/nomi-san/parsec-vdd
# once that reaches a stable release.
# Or I might just reimplement it in powershell
#
# NOTE: This module also requires the DisplayConfig module
#       https://github.com/MartinGC94/DisplayConfig
if (-not (Get-Module -Name DisplayConfig -ListAvailable)) {
    Write-Error "DisplayConfig module not found. Please install it with 'Install-Module -Name DisplayConfig'"
    exit
} else {
    Import-Module DisplayConfig
}

function Set-VirtualDisplay {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    # Get all display devices
    $displayDevices = Get-PnpDevice -PresentOnly -Class Display

    # Get supported virtual display drivers
    $VDD_MMT = $displayDevices | Where-Object FriendlyName -eq "Virtual Display Driver by MTT"
    $USB_MMID = $displayDevices | Where-Object FriendlyName -eq "USB Mobile Monitor Virtual Display"

    # Enable/disable the virtual display driver
    if ($VDD_MMT) {
        if ($Enabled) {
            Enable-PnpDevice $VDD_MMT.InstanceId -Confirm:$false
        }
        else {
            Disable-PnpDevice $VDD_MMT.InstanceId -Confirm:$false
        }
    }
    elseif ($USB_MMID) {
        Enable-PnpDevice $USB_MMID.InstanceId -Confirm:$false
        deviceinstaller64.exe enableidd ([int]$Enabled)
    }
    else {
        Write-Error "Virtual display driver not found."
        exit
    }
}

function Enable-VirtualDisplay {
    Set-VirtualDisplay -Enabled $true
}

function Disable-VirtualDisplay {
    Set-VirtualDisplay -Enabled $false
}

function Set-PrivacyMode {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    if ($Enabled) {
        Enable-PrivacyMode
    }
    else {
        Disable-PrivacyMode
    }
}

function Enable-PrivacyMode {
    # Get current displays info
    $displayInfo = Get-DisplayInfo

    # Turn on virtual display
    Enable-VirtualDisplay

    # Wait for Windows to detect the new display
    while ($displayInfo.Count -eq (Get-DisplayInfo).Count) {
        Start-Sleep -Seconds 0.5
    }

    # Get the virtual display
    $vdd = Get-DisplayInfo | Where-Object DevicePath -NotIn $displayInfo.DevicePath

    # Wait for the virtual display to be active
    while ($vdd.Active -ne $true) {
        Start-Sleep -Seconds 0.5
        $vdd = Get-DisplayInfo | Where-Object DevicePath -NotIn $displayInfo.DevicePath
    }

    # Get current display configuration
    $config = Get-DisplayConfig

    # Set the virtual display as primary
    Set-DisplayPrimary $vdd.DisplayId -DisplayConfig $config -ErrorAction Continue

    # Disable other displays
    $displayInfo | ForEach-Object {
        Disable-Display $_.DisplayId -DisplayConfig $config -ErrorAction Continue
    }

    # Apply the new configuration
    Use-DisplayConfig -DisplayConfig $config -AllowChanges -ErrorAction Continue
}

function Disable-PrivacyMode {
    # Enable all displays
    Get-DisplayInfo | ForEach-Object {
        Enable-Display $_.DisplayId -ErrorAction Continue
    }

    # Turn off virtual display
    Disable-VirtualDisplay
}