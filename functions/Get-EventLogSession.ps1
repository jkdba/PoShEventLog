function Get-EventLogSession
{
    <#
        .SYNOPSIS
            Gets a windows event log session which can be used to perform various event log tasks.
        .DESCRIPTION

        .PARAMETER ComputerName
            Specify the ComputerName to open the Eventlog Session on.
        .EXAMPLE
            PS> $EventLogSession = Get-EventLogSession -ComputerName 'ServerName'
        .NOTES
            DotNet Type [System.Diagnostics.Eventing.Reader.EventLogSession]
        .INPUTS
            String
        .OUTPUTS
            System.Diagnostics.Eventing.Reader.EventLogSession
        .LINK
            https://msdn.microsoft.com/en-us/library/system.diagnostics.eventing.reader.eventlogsession(v=vs.110).aspx
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName = 'localhost'
    )
    process
    {
        try
        {
            [System.Diagnostics.Eventing.Reader.EventLogSession]::new($ComputerName)
        }
        catch
        {
            Write-Warning -Message ('Failed to get EventLog session for computer: ({0}).' -f $ComputerName)
            Throw $_
        }
    }
}