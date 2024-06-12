function Add-IMPartner
{
    <#
    .DESCRIPTION
        Add immich partner
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Define the id of the partner to add
    .EXAMPLE
        Add-IMPartner -id <userid>

        Add immich partner
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id
    )

    InvokeImmichRestMethod -Method POST -RelativePath "/partners/$id" -ImmichSession:$Session
}
#endregion
