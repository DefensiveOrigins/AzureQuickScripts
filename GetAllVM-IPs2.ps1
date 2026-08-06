# Get all Public IPs once
$publicIPs = Get-AzPublicIpAddress

$results = foreach ($vm in Get-AzVM) {
    foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
        $nic = Get-AzNetworkInterface -ResourceId $nicRef.Id

        foreach ($ipConfig in $nic.IpConfigurations) {
            $pip = $null

            if ($ipConfig.PublicIpAddress) {
                $pip = $publicIPs | Where-Object { $_.Id -eq $ipConfig.PublicIpAddress.Id }
            }

            [PSCustomObject]@{
                ResourceGroup = $vm.ResourceGroupName
                VMName        = $vm.Name
                PublicIP      = $pip.IpAddress
            }
        }
    }
}

$results |
    Sort-Object ResourceGroup, VMName |
    ConvertTo-Csv -NoTypeInformation
