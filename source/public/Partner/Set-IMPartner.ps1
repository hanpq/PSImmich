function Set-IMPartner
{
    <#
    .SYNOPSIS
        Updates partner sharing settings.
    .DESCRIPTION
        Configures how partner's assets appear in your timeline and interface.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Partner user ID to update. Must be valid GUID format.
    .PARAMETER EnableTimeline
        When specified, shows partner's assets in your main timeline view.
    .EXAMPLE
        Set-IMPartner -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -EnableTimeline

        Enables timeline integration for the specified partner.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id,

        [Parameter()]
        [ApiParameter('inTimeline')]
        [switch]
        $EnableTimeline
    )

    if ($PSCmdlet.ShouldProcess($id, 'Update'))
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

        InvokeImmichRestMethod -Method PUT -RelativePath "/partners/$id" -ImmichSession:$Session -Body:$BodyParameters
    }
}
#endregion
