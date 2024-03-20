function Remove-IMPartner
{
    <#
    .DESCRIPTION
        Remove immich partner
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the partner id
    .EXAMPLE
        Remove-IMPartner -id <userid>

        Remove immich partner
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id
    )
    if ($PSCmdlet.ShouldProcess($id, 'DELETE'))
    {
        InvokeImmichRestMethod -Method DELETE -RelativePath "/partner/$id" -ImmichSession:$Session
    }
}
#endregion
