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
        # $First = $true

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