function Set-IMPartner
{
    <#
    .DESCRIPTION
        Set immich partner
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Define the id of the partner to update
    .PARAMETER EnableTimeline
        Defines that the partners assets should be displayed within the main timeline
    .EXAMPLE
        Set-IMPartner -id <userid> -EnableTimeline

        Set immich partner
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
