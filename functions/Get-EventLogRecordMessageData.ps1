function Get-EventLogRecordMessageData
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
        .INPUTS
        .OUTPUTS
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullorEmpty()]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]] $Record
    )
    process
    {
        foreach ($_Record in $Record )
        {
            $RecordIDList = $_Record.RecordID
            $ComputerName = $_Record.MachineName
            $LogName = $_Record.LogName
            $Query = Get-EventLogQuery -RecordID $RecordIDList

            Invoke-EventLogQuery -ComputerName $ComputerName -LogPathType LogName -Query $Query -LogName $LogName -WithMessage
        }
    }
}