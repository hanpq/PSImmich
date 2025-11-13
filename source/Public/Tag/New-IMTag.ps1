function New-IMTag
{
    <#
    .SYNOPSIS
        Creates a new asset tag.
    .DESCRIPTION
        Creates tags for organizing and categorizing assets by type.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Name
        Name for the new tag.
    .PARAMETER Type
        Tag type: OBJECT, FACE, or CUSTOM.
    .EXAMPLE
        New-IMTag -Name 'Vacation' -Type CUSTOM

        Creates custom tag for vacation photos.

        Creates a new Immich tag
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
        $Name
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    InvokeImmichRestMethod -Method Post -RelativePath '/tags' -ImmichSession:$Session -Body:$BodyParameters

}
#endregion
