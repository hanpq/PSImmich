function Get-IMAssetThumbnail
{
    <#
    .DESCRIPTION
        Retreives the asset thumbnail
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines the asset ID to query
    .PARAMETER Format
        Defines the format of the thumbnail to retreive. Valid values are JPEG and WEBP
    .EXAMPLE
        Get-IMAssetThumbnail

        Retreives asset thumbnails
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id,

        [Parameter()]
        [ValidateSet('JPEG', 'WEBP')]
        [string]
        $Format
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Format' -NameMapping @{
                Format = 'format'
            })
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath "/asset/thumbnail/$id" -ImmichSession:$Session -QueryParameters $QueryParameters
    }
}
#endregion
