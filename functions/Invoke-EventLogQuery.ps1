function Invoke-EventLogQuery
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
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName = 'localhost',

        ## Dynamic Parameter LogName at Postion 1

        [Parameter(Position=2, Mandatory=$true)]
        [ValidateSet('LogName','FilePath')]
        [String] $LogPathType,

        [Parameter(Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('XPathFilter')]
        [String] $Query,

        [Parameter(Position=4, Mandatory=$false)]
        [Switch] $WithMessage
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

        $StandardEventKeywords = [System.Diagnostics.Eventing.Reader.StandardEventKeywords]
        # $StandardEventKeywords = $StandardEventKeywords.GetEnumValues()

        $StandardEventLevel = [System.Diagnostics.Eventing.Reader.StandardEventLevel]
        # $StandardEventLevel = $StandardEventLevel.GetEnumValues()

        $StandardEventOpcode = [System.Diagnostics.Eventing.Reader.StandardEventOpcode]
        # $StandardEventOpcode = $StandardEventOpcode.GetEnumValues()

        $StandardEventTask = [System.Diagnostics.Eventing.Reader.StandardEventTask]
        # $StandardEventTask = $StandardEventTask.GetEnumValues()

    }
    process
    {
        $EventLogSession = Get-EventLogSession -ComputerName $ComputerName

        if($EventLogSession)
        {
            try
            {
                $EventLogQuery = [System.Diagnostics.Eventing.Reader.EventLogQuery]::new($LogName,$LogPathEnumType,$Query)
                $EventLogQuery.Session = $EventLogSession

                $EventLogReader = [System.Diagnostics.Eventing.Reader.EventLogReader]::new($EventLogQuery)

                if($EventLogReader)
                {
                    while($true)
                    {
                        $EventData = $EventLogReader.ReadEvent()

                        if(-not $EventData)
                        {
                            break
                        }
                        else
                        {
                            if($WithMessage)
                            {
                                try
                                {
                                    $Message = $EventData.FormatDescription()
                                    if($Message)
                                    {
                                        $EventData | Add-Member -MemberType NoteProperty -Name 'Message' -Value $Message
                                    }
                                    $EventData.PSObject.TypeNames.Insert(0,'PoShEventLog.Message')
                                }
                                catch
                                {
                                    Write-Warning -Message ('[Function({0})] Failed to query the EventLog for log ({1}) with path type of ({2}) on computer ({3}) with query ({4}).' -f $MyInvocation.MyCommand, $LogName, $LogPathType, $ComputerName, $Query)
                                    Write-Warning -Message ('[Detail] Failed to get Message Data for an event, continuing.')
                                }
                            }
                            else
                            {
                                $EventData.PSObject.TypeNames.Insert(0,'PoShEventLog.NoMessage')
                            }

                            $EventRecordEventData = Get-EventLogRecordEventData -Record $EventData

                            $EventData | Add-Member -MemberType NoteProperty -Name 'RecordEventData' -Value $EventRecordEventData

                            $EventData | Add-Member -MemberType NoteProperty -Name 'StandardEventKeywords' -Value ([enum]::GetValues($StandardEventKeywords)| % { if([Int64]$_ -eq  $EventData.Keywords){$_} })
                            $EventData | Add-Member -MemberType NoteProperty -Name 'StandardEventLevel' -Value ([enum]::GetValues($StandardEventLevel)| % { if([Int64]$_ -eq  $EventData.Level){$_} })
                            $EventData | Add-Member -MemberType NoteProperty -Name 'StandardEventOpcode' -Value ([enum]::GetValues($StandardEventOpcode)| % { if([Int64]$_ -eq  $EventData.Opcode){$_} })
                            $EventData | Add-Member -MemberType NoteProperty -Name 'StandardEventTask' -Value ([enum]::GetValues($StandardEventTask)| % { if([Int64]$_ -eq  $EventData.Keywords){$_} })

                            $EventData
                        }
                    }

                    $EventLogReader.Dispose()
                }

                if($EventLogQuery)
                {
                    $EventLogQuery = $null
                }

                if($EventLogSession)
                {
                    $EventLogSession.Dispose()
                }
            }
            catch
            {
                Write-Warning -Message ('[Function({0})] Failed to query the EventLog for log ({1}) with path type of ({2}) on computer ({3}) with query ({4}).' -f $MyInvocation.MyCommand, $LogName, $LogPathType, $ComputerName, $Query)
                Throw $_
            }
        }
    }
}