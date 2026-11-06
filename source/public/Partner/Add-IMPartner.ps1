function Add-IMPartner
{
    <#
    .SYNOPSIS
        Adds a user as a sharing partner.
    .DESCRIPTION
        Creates a partnership relationship allowing asset sharing between users.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER SharedWithId
        User ID to add as partner. Must be valid GUID format.
    .EXAMPLE
        Add-IMPartner -SharedWithId 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Adds the specified user as a sharing partner.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('sharedWithId')]
        [string]
        $SharedWithId
    )

    $BodyParameters = ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    InvokeImmichRestMethod -Method POST -RelativePath '/partners' -ImmichSession:$Session -Body $BodyParameters
}
#endregion
