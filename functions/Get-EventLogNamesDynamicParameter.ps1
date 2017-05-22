function Get-EventLogNamesDynamicParameter
{
    param
    (
        $ComputerName
    )
    process
    {
        $EventLogSession = Get-EventLogSession -ComputerName $ComputerName
        if($EventLogSession)
        {
            try
            {
                $EventLogNameList = ($EventLogSession).GetLogNames()
                $EventLogSession.Dispose()

                $EventLogParameterName = 'LogName'
                $EventLogAttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                $EventLogParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
                $EventLogParameterAttribute.Mandatory = $true
                $EventLogParameterAttribute.Position = 1

                $EventLogAttributeCollection.Add($EventLogParameterAttribute)

                $EventLogValidateSetAttribute = New-Object -TypeName System.Management.Automation.ValidateSetAttribute($EventLogNameList)
                $EventLogAttributeCollection.Add($EventLogValidateSetAttribute)

                $EventLogRuntimeParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($EventLogParameterName, [String], $EventLogAttributeCollection)

                $RuntimeParameterDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
                $RuntimeParameterDictionary.Add($EventLogParameterName,$EventLogRuntimeParameter)

                return $RuntimeParameterDictionary
            }
            catch
            {
                Write-Warning -Message ('Error Occured with ComputerName: {0}' -f $ComputerName)
                Throw $_
            }
        }
    }
}