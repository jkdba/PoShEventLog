function Get-RDPEvent
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
        [ValidateNotNullOrEmpty()]
        [String[]] $ComputerName,

        [Parameter(Position=1, Mandatory=$false)]
        [Switch] $AttemptJoin
    )
    begin
    {
        $RDPEventQuery = Get-EventLogQuery -EventID 21,24 -After (Get-Date).AddDays(-40).Date #,23
    }
    process
    {
        foreach($Name in $ComputerName)
        {
            $Results = Invoke-EventLogQuery -ComputerName $Name -LogPathType LogName -Query $RDPEventQuery -WithMessage -LogName 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational' | ForEach-Object {
                [Int] $EventID = $_.ID
                [Int] $RecordID = $_.RecordID
                [String] $EventLevel = $_.StandardEventLevel
                [DateTime] $EventTime = $_.TimeCreated

                [String[]] $MessageArry = $_.Message -split "`n"
                [String] $SessionAction = $MessageArry[0] -replace 'Remote Desktop Services: ' -replace ':'
                [String] $SessionUser = $MessageArry[2] -replace 'User: '
                [Int] $SessionID = $MessageArry[3] -replace 'Session ID: '

                if($EventID -ne 23)
                {
                    [String] $SessionClientIP = $MessageArry[4] -replace 'Source Network Address: '
                    [String] $SessionClientComputerName = $(Resolve-DnsName $SessionClientIP -ErrorAction SilentlyContinue).NameHost
                }
                else
                {
                    [String] $SessionClientIP = $null
                    [String] $SessionClientComputerName = $null
                }

                $RecordObject = New-Object -TypeName PSObject
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $Name
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'RecordID' -Value $RecordID
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'EventID' -Value $EventID
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'EventLevel' -Value $EventLevel
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'EventTime' -Value $EventTime
                # $RecordObject | Add-Member -MemberType NoteProperty -Name 'MessageArry' -Value $MessageArry
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionAction' -Value $SessionAction
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionUser' -Value $SessionUser
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionID' -Value $SessionID
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionClientIP' -Value $SessionClientIP
                $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionClientComputerName' -Value $SessionClientComputerName
                $RecordObject
            }

            if($AttemptJoin)
            {
                $Logons = $Results | Where-Object { $_.EventID -eq 21 } | Sort-Object EventTime
                $Disconnects = $Results | Where-Object { $_.EventID -eq 24} | Sort-Object EventTime
                $ExclusionList = @()
                foreach ($Logon in $Logons)
                {
                    foreach($Disconnect in $Disconnects)
                    {
                        if($Logon.SessionUser -eq $Disconnect.SessionUser -and $Logon.SessionID -eq $Disconnect.SessionID -and $Logon.SessionClientIP -eq $Disconnect.SessionClientIP -and $Logon.EventTime -le $Disconnect.EventTime -and $Disconnect.RecordID -notin $ExclusionList)
                        {
                            $ExclusionList += $Disconnect.RecordID
                            $RecordObject = New-Object -TypeName PSObject
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $Name

                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionUser' -Value $Logon.SessionUser
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionID' -Value $Logon.SessionID
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionClientIP' -Value $Logon.SessionClientIP
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionClientComputerName' -Value $Logon.SessionClientComputerName
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'LogonTime' -Value $Logon.EventTime
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'DisconnectTime' -Value $Disconnect.EventTime
                            $RecordObject | Add-Member -MemberType NoteProperty -Name 'SessionDuration' -Value ($Disconnect.EventTime -$Logon.EventTime)
                            $RecordObject
                            break
                            # -and $Logon.RecordID -notin $ExclusionList
                        }
                    }
                }
            }
            else
            {
                $Results
            }
        }
    }
}