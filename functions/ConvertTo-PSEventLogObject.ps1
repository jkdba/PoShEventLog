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

            # ActivityId
            # # BookMark
            # ContainerLog
            # Id
            # KeywordsDisplayNames
            # Level
            # LevelDisplayName
            # LogName
            # MachineName
            # OpcodeDisplayName
            # ProcessID
            # Properties
            # ProviderName
            # Qualifiers
            # RecordId
            # RelatedActivityID
            # Task
            # TaskDisplayName
            # ThreadID
            # TimeCreated
            # UserID
            # Version

        }
    }
}