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
                                $Message = $EventData.FormatDescription()
                                if($Message)
                                {
                                    $EventData | Add-Member -MemberType NoteProperty -Name 'Message' -Value $Message
                                }
                                $EventData.PSObject.TypeNames.Insert(0,'PoShEventLog.Message')
                            }
                            else
                            {
                                $EventData.PSObject.TypeNames.Insert(0,'PoShEventLog.NoMessage')
                            }

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

function Get-EventLogQuery
{
    <#
        .SYNOPSIS
            Builds a XPath Query based on the specified parameters.
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
        [Int[]] $EventID,

        [Parameter(Position=1, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int[]] $Level,

        [Parameter(Position=2, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $After,

        [Parameter(Position=3, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $Before,

        [Parameter(Position=4, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int[]] $ProcessID,

        [Parameter(Position=5, Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [Int[]] $RecordID,

        [Parameter(Position=6, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName
    )
    process
    {
        $QueryText = '*/System['
        $First = $true

        if($EventID)
        {
            $QueryText += '( '
            foreach($_EventID in $EventID)
            {
                $QueryText += 'EventID={0} or ' -f $_EventID
            }

            $QueryText = $QueryText -replace ' or $',' ) and '
        }

        if($Level)
        {
            $QueryText += '( '
            foreach($_Level in $Level)
            {
                $QueryText += 'Level={0} or ' -f $_Level
            }

            $QueryText = $QueryText -replace ' or $',' ) and '
        }

        if($After)
        {
            $After = Get-Date (Get-Date $After).ToUniversalTime().ToString() -Format s
            $QueryText += "TimeCreated/@SystemTime >= '{0}' and " -f $After
        }

        if($Before)
        {
            $Before = Get-Date (Get-Date $Before).ToUniversalTime().ToString() -Format s
            $QueryText += "TimeCreated/@SystemTime <= '{0}' and " -f $Before
        }

        if($ProcessID)
        {
            $QueryText += '( '
            foreach($_ProcessID in $ProcessID)
            {
                $QueryText += 'Execution/@ProcessID="{0}" or ' -f $_ProcessID
            }

            $QueryText = $QueryText -replace ' or $',' ) and '
        }

        if($RecordID)
        {
            $QueryText += '( '
            foreach($_RecordID in $RecordID)
            {
                $QueryText += 'EventRecordID={0} or ' -f $_RecordID
            }

            $QueryText = $QueryText -replace ' or $',' ) and '
        }

        if($ComputerName)
        {
            $QueryText += 'Computer="{0}"' -f $ComputerName
        }

        ## Ending
        if($QueryText -match ' (and|or) $')
        {
            $QueryText = $QueryText -replace ' (and|or) $',''
        }

        $QueryText += ']'
        $QueryText
    }
}

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

function ConvertTo-PSEventLogObject
{
    param
    (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]] $EventLogRecord
    )
    begin
    {
    }
    process
    {
        foreach($_EventLogRecord in $EventLogRecord)
        {
            $EventRecordObject | New-Object -TypeName PSObject
            $EventRecordObject

            ActivityId
            # BookMark
            ContainerLog
            Id
            KeywordsDisplayNames
            Level
            LevelDisplayName
            LogName
            MachineName
            OpcodeDisplayName
            ProcessID
            Properties
            ProviderName
            Qualifiers
            RecordId
            RelatedActivityID
            Task
            TaskDisplayName
            ThreadID
            TimeCreated
            UserID
            Version

        }
    }
}

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
    }
}

# 'Microsoft-Windows-TaskScheduler/Operational'
# $EQ=Get-EventLogQuery -After '03/31/2017 5:17:00' -Before '04/02/2017 17:37:00' -EventID 201,102
# Invoke-EventLogQuery -ComputerName appdba -LogName 'Microsoft-Windows-TaskScheduler/Operational' -LogPathType LogName -Query "$EQ"