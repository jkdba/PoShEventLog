## Unblock
Get-ChildItem -Path $PSScriptRoot | Unblock-File
## dot source all script files
Get-ChildItem -Path $PSScriptRoot -Recurse -File | ForEach-Object {
    if($_.Extension -eq '.ps1')
    {
        . $_.FullName
    }
}

Export-ModuleMember -Function *


# 'Microsoft-Windows-TaskScheduler/Operational'
# $EQ=Get-EventLogQuery -After '03/31/2017 5:17:00' -Before '04/02/2017 17:37:00' -EventID 201,102
# Invoke-EventLogQuery -ComputerName name -LogName 'Microsoft-Windows-TaskScheduler/Operational' -LogPathType LogName -Query "$EQ"