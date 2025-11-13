function New-IMPerson
{
    <#
    .SYNOPSIS
        Creates a new person record.
    .DESCRIPTION
        Manually creates a person entry for face recognition training and organization.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER BirthDate
        Person's birth date for timeline context.
    .PARAMETER IsHidden
        Set to $true to hide person from main interface.
    .PARAMETER Name
        Display name for the person.
    .EXAMPLE
        New-IMPerson -Name 'John Smith' -BirthDate '1990-01-01'

        Creates a new person with name and birth date.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]
        $Name,

        [Parameter()]
        [ApiParameter('isHidden')]
        [switch]
        $IsHidden,

        [Parameter()]
        [ApiParameter('birthDate')]
        [datetime]
        $BirthDate
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    InvokeImmichRestMethod -Method Post -RelativePath '/people' -ImmichSession:$Session -Body:$BodyParameters
}
#endregion
