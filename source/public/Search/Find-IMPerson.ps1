function Find-IMPerson
{
    <#
    .SYNOPSIS
        Searches for people by name or visibility.
    .DESCRIPTION
        Finds person records using name filtering and hidden status options.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Name
        Search by person name (supports partial matches).
    .PARAMETER WithHidden
        Include hidden people when $true, exclude when $false.
    .EXAMPLE
        Find-IMPerson -Name 'John'

        Searches for people with 'John' in their name.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [boolean]$WithHidden
    )

    $ApiArguments = @{ Name = $Name; ImmichSession = $Session }
    if ($PSBoundParameters.ContainsKey('WithHidden')) { $ApiArguments.WithHidden = $WithHidden }

    Invoke-ImmichApiSearchPerson @ApiArguments | ForEach-Object { [PersonResponseDto]::new($PSItem) }

}
#endregion
