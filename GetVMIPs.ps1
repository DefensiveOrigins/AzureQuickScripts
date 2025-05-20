# Login to Azure if not already logged in
Connect-AzAccount

# Optional: Select a specific subscription
# Set-AzContext -SubscriptionId 'your-subscription-id'

# Initialize an array to hold IP info
$allIPs = @()

# Get all VMs across all resource groups
$vms = Get-AzVM

foreach ($vm in $vms) {
    $resourceGroup = $vm.ResourceGroupName
    $nicIds = $vm.NetworkProfile.NetworkInterfaces.Id

    foreach ($nicId in $nicIds) {
        $nicName = ($nicId -split '/')[8]
        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup

        $privateIp = $nic.IpConfigurations.PrivateIpAddress
        $publicIp = $nic.IpConfigurations.PublicIpAddress | ForEach-Object {
            if ($_ -ne $null) {
                $pipId = $_.Id
                $pipName = ($pipId -split '/')[8]
                $pip = Get-AzPublicIpAddress -Name $pipName -ResourceGroupName $resourceGroup
                $pip.IpAddress
            }
        }

        $allIPs += [PSCustomObject]@{
            VMName     = $vm.Name
            ResourceGroup = $resourceGroup
            PrivateIP  = $privateIp
            PublicIP   = $publicIp -join ', '
        }
    }
}

# Export to CSV
$allIPs | Export-Csv -Path "./AzureVM_IPs.csv" -NoTypeInformation
Write-Host "Export complete: AzureVM_IPs.csv"
