function Export-EventLog
{
    <#
        .SYNOPSIS
            Export and Event log from an eventlog session.
        .DESCRIPTION

        .PARAMETER
        .EXAMPLE
        .NOTES
        .INPUTS
        .OUTPUTS
    #>
    [CmdletBinding(DefaultParameterSetName='AdvancedFilter')]
    param
    (
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName = 'localhost',

        ## Dynamic Parameter LogName at Postion 1

        [Parameter(Position=2, Mandatory=$true)]
        [ValidateSet('LogName','FilePath')]
        [String] $LogPathType,

        [Parameter(Position=3, Mandatory=$false, ParameterSetName='AdvancedFilter')]
        [ValidateNotNullOrEmpty()]
        [Alias('Filter')]
        [String] $Query = '*',

        [Parameter(Position=3, Mandatory=$false, ParameterSetName='TypicalFilter')]
        [ValidateSet('ExcludeInformational','WarningOnly','ErrorOnly','CriticalOnly')]
        [String] $FilterType,

        [Parameter(Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path')]
        [String] $ExportPath,

        [Parameter(Position=5, Mandatory=$false)]
        [Switch] $ShowDetails
    )
    dynamicparam
    {
        Get-EventLogNamesDynamicParameter -ComputerName $ComputerName
    }
    begin
    {
        $LogName = $PSBoundParameters['LogName']

        $LogPathEnumType = switch($LogPathType)
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

        if($PSCmdlet.ParameterSetName -eq 'TypicalFilter')
        {
            $Query = switch($FilterType)
            {
                ('ExcludeInformational')
                {
                    '*/System[Level=1 and Level=2 and Level=3]'
                }
                ('WarningOnly')
                {
                    '*/System[Level=3]'
                }
                ('ErrorOnly')
                {
                    '*/System[Level=2]'
                }
                ('CriticalOnly')
                {
                    '*/System[Level=1]'
                }
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
                $EventLogSession.ExportLog($LogName, $LogPathEnumType, $Query, $ExportPath)
                $EventLogSession.Dispose()

                if($ShowDetails)
                {
                    Get-EventLogInformation -ComputerName $ComputerName -LogName $ExportPath -LogPathType 'FilePath'
                }
            }
            catch
            {
                Write-Warning -Message ('[Function({0})] Failed to export the EventLog for log ({1}) with path type of ({2}) on computer ({3}) with query ({4}) to path ({5}).' -f $MyInvocation.MyCommand, $LogName, $LogPathType, $ComputerName, $Query, $ExportPath)
                Throw $_
            }
        }
    }
}