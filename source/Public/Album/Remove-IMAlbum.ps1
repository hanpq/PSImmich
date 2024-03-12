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
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/album/$albumId" -ImmichSession:$Session
            }
        }
    }
}
#endregion
