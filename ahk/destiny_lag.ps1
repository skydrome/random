# $ruleName = "Destiny FuckPVP"
# $portNumber = "27015-27200"

$ruleName = "Destiny FuckPVE"
$portNumber = "3074,3097"

$process = "D:\games\steamlibrary\steamapps\common\destiny 2\destiny2.exe"
$protocol = "udp"
$direction = "in"

function CreateFirewallRule
{
    $exists = netsh advfirewall firewall show rule name=$ruleName
    if(!($exists -cmatch $ruleName)) {
        Write-Host "No"
        Write-Host -NoNewline "Creating Windows Firewall rule... "
        netsh advfirewall firewall add rule name=$ruleName `
                                            action=block ` #program=$process `
                                            dir=$direction protocol=$protocol remoteport=$portNumber
        if($?) {
            Write-Host "Ok"
        } else {
            Write-Host "Failed"
            Exit
        }
    }
}

function Main
{
    # intercept ctrl-c and use it instead of terminating script
    [Console]::TreatControlCAsInput = $True

    while ($true) {
        $sleep = Get-Random -Minimum 4000 -Maximum 6000
        Write-Host -NoNewline "Disabling traffic for $($sleep)ms"
        netsh advfirewall firewall set rule name=$ruleName new enable=yes
        Start-Sleep -Milliseconds $sleep

        $sleep = Get-Random -Minimum 5000 -Maximum 2000
        Write-Host -NoNewline "Enabling traffic  for $($sleep)ms"
        netsh advfirewall firewall set rule name=$ruleName new enable=no
        Start-Sleep -Milliseconds $sleep

        if ($Host.UI.RawUI.KeyAvailable -and ($Key = $Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
            if ([Int]$Key.Character -eq 3) {
                [Console]::TreatControlCAsInput = $False
                netsh advfirewall firewall set rule name=$ruleName new enable=no
                Write-Host "Exiting... Firewall rule disabled"
                Exit
            }
            # flush the key buffer again for the next loop
            $Host.UI.RawUI.FlushInputBuffer()
        }
    }
}

CreateFirewallRule
Main
