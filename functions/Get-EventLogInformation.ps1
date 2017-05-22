function Get-EventLogInformation
{
    <#
        .SYNOPSIS
            Get EventLog Metadata about the specified log on the specified computer.
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
        .INPUTS
            String
        .OUTPUTS
            Object
        .LINK
            https://msdn.microsoft.com/en-us/library/system.diagnostics.eventing.reader.eventlogsession.getloginformation(v=vs.110).aspx
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName = 'localhost',

        ## Dynamic Parameter LogName at Postion 1

        [Parameter(Position=2, Mandatory=$true)]
        [ValidateSet('LogName','FilePath')]
        [String] $LogPathType
    )
    dynamicparam
    {
        Get-EventLogNamesDynamicParameter -ComputerName $ComputerName
    }
    begin
    {
        $LogName = $PSBoundParameters['LogName']

        $LogPathEnumType = switch ($LogPathType)
        {
            ('LogName')
            {
                [System.Diagnostics.Eventing.Reader.PathType]::LogName
            }
            ('FilePath')
            {
                [System.Diagnostics.Eventing.Reader.PathType]::FilePath
            }
        }
    }
    process
    {
        $EventLogSession = Get-EventLogSession -ComputerName $ComputerName

        if($EventLogSession)
        {
            try
            {
                $EventLogSession.GetLogInformation($LogName, $LogPathEnumType)
                $EventLogSession.Dispose()
            }
            catch
            {
                Write-Warning -Message ('[Function({0})] Failed to get EventLog information for log ({1}) with path type of ({2}) on computer ({3}).' -f $MyInvocation.MyCommand, $LogName, $LogPathType, $ComputerName)
                Throw $_
            }
        }
    }
}