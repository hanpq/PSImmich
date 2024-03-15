function Remove-IMAlbum
{
    <#
    .DESCRIPTION
        Removes an Immich album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines the asset ids that should be removed. Accepts pipeline input.
    .EXAMPLE
        Remove-IMAlbum

        Removes an Immich album
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('id')]
        [string[]]
        $albumId
    )

    PROCESS
    {
        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $albumId | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/album/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
