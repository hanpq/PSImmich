function Get-IMPartner
{
    <#
    .SYNOPSIS
        Retrieves sharing partners.
    .DESCRIPTION
        Gets users who share assets with you or users you share with.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Direction
        Partnership direction: 'shared-by' (partners sharing with you) or 'shared-with' (partners you share with).
    .EXAMPLE
        Get-IMPartner -Direction 'shared-with'

        Gets users you are sharing assets with.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidateSet('shared-by', 'shared-with')]
        [ApiParameter('direction')]
        [string]
        $Direction

    )

    process
    {
        $QueryParameters = @{}
        $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
        InvokeImmichRestMethod -Method GET -RelativePath '/partners' -ImmichSession:$Session -QueryParameters:$QueryParameters
    }
}
#endregion
