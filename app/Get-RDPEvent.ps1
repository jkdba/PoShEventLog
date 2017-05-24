function Get-RDPEvent.ps1
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
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $ComputerName
    )
    process
    {

    }
}