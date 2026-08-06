Get-AzVM -Status |
    Where-Object {
        $_.Name -eq 'DC01' -and
        $_.PowerState -eq 'VM running'
    } |
    ForEach-Object {
        $result = Invoke-AzVMRunCommand `
            -ResourceGroupName $_.ResourceGroupName `
            -VMName $_.Name `
            -CommandId RunPowerShellScript `
            -ScriptString 'Import-Module ActiveDirectory; (Get-ADDomain).DomainSID.Value'

        [PSCustomObject]@{
            ResourceGroup = $_.ResourceGroupName
            VMName        = $_.Name
            DomainSID     = $result.Value[0].Message.Trim()
        }
    } | ConvertTo-Csv -NoTypeInformation
