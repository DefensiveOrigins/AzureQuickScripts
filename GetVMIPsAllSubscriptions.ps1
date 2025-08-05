# Login to Azure if not already logged in
Connect-AzAccount

# Optional: Select a specific subscription
# Set-AzContext -SubscriptionId 'your-subscription-id'

# Initialize an array to hold IP info
$allIPs = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription

foreach ($sub in $subscriptions) {
    $subId = $sub.Id
    $subName = $sub.Name

    Write-Host "Processing Subscription: $subName ($subId)" -ForegroundColor Cyan
    Set-AzContext -SubscriptionId $subId

    # Get all VMs in this subscription
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        $resourceGroup = $vm.ResourceGroupName
        $vmName = $vm.Name
        $nicIds = $vm.NetworkProfile.NetworkInterfaces.Id

        foreach ($nicId in $nicIds) {
            $nicName = ($nicId -split '/')[8]
            $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup

            foreach ($ipconfig in $nic.IpConfigurations) {
                $privateIp = $ipconfig.PrivateIpAddress

                $publicIp = $null
                if ($ipconfig.PublicIpAddress -ne $null) {
                    $pipId = $ipconfig.PublicIpAddress.Id
                    $pipName = ($pipId -split '/')[8]
                    $pip = Get-AzPublicIpAddress -Name $pipName -ResourceGroupName $resourceGroup
                    $publicIp = $pip.IpAddress
                }

                $allIPs += [PSCustomObject]@{
                    Subscription   = $subName
                    VMName         = $vmName
                    ResourceGroup  = $resourceGroup
                    PrivateIP      = $privateIp
                    PublicIP       = $publicIp
                }
            }
        }
    }
}

# Export to CSV
$allIPs | Export-Csv -Path "./AzureVM_IPs_All_Subscriptions.csv" -NoTypeInformation
Write-Host "Export complete: AzureVM_IPs_All_Subscriptions.csv"
