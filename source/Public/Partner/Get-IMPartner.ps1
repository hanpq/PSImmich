function Get-IMPartner
{
    <#
    .DESCRIPTION
        Get immich partner
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER direction
        Defines the direction of the partnership
    .EXAMPLE
        Get-IMPartner

        Get immich partner
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidateSet('shared-by', 'shared-with')]
        [string]
        $Direction

    )

    PROCESS
    {
        $QueryParameters = @{
            direction = $Direction
        }
        InvokeImmichRestMethod -Method GET -RelativePath '/partner' -ImmichSession:$Session -QueryParameters:$QueryParameters
    }
}
#endregion
