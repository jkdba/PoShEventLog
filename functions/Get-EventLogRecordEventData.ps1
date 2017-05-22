function Get-EventLogRecordEventData
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
        [System.Diagnostics.Eventing.Reader.EventLogRecord] $Record
    )
    process
    {
        try
        {
            [xml] $EventXml = $Record.ToXml()
            $EventData = $EventXml.Event.EventData.Data
            $EventDataHash = @{}

            if($EventData.Name)
            {
                foreach($_EventData in $EventData)
                {
                    $EventDataHash."$($EventData.Name)" = $_EventData.'#text'
                }
            }
            else
            {
                $EventData = $EventData -split ';'

                if($EventData)
                {
                    foreach($_EventData in $EventData)
                    {
                        $DataPart = $_EventData -split '='
                        $EventDataHash."$($DataPart[0])" = $DataPart[1]
                    }
                }
            }

            $EventDataHash

            if($EventXml)
            {
                $EventXml = $null
            }
        }
        catch
        {
            Write-Warning -Message ('[Function({0})] Failed to get the EventLog Record EventData for RecordID ({0}) in Log ({1}) on Computer ({2}).' -f $MyInvocation.MyCommand, $Record.RecordId, $Record.ContainerLog, $Record.MachineName)
            Throw $_
        }
    }
}