function New-IMSharedLink
{
    <#
    .SYNOPSIS
        Creates a new shared link for assets or albums.
    .DESCRIPTION
        Generates public sharing links with configurable permissions and expiration.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER AssetId
        Asset IDs to include in the shared link.
    .PARAMETER AlbumId
        Album ID to share via the link.
    .PARAMETER AllowDownload
        Permits downloading assets through the shared link.
    .PARAMETER AllowUpload
        Permits uploading assets through the shared link.
    .PARAMETER Description
        Description text for the shared link.
    .PARAMETER ExpiresAt
        Defines an expiration date of the shared link
    .PARAMETER ShowMetadata
        Defines if asset metadata is shown
    .PARAMETER Password
        Defines a password for the shared link
    .EXAMPLE
        New-IMSharedLink

        New Immich shared link
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'asset')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'asset', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $AssetId,

        [Parameter(Mandatory, ParameterSetName = 'album')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AlbumId,

        [Parameter()]
        [ApiParameter('allowDownload')]
        [switch]
        $AllowDownload,

        [Parameter()]
        [ApiParameter('allowUpload')]
        [switch]
        $AllowUpload,

        [Parameter()]
        [ApiParameter('description')]
        [string]
        $Description,

        [Parameter()]
        [ApiParameter('expiresAt')]
        [datetime]
        $ExpiresAt,

        [Parameter()]
        [ApiParameter('showMetadata')]
        [switch]
        $ShowMetadata,

        [Parameter()]
        [ApiParameter('password')]
        [securestring]
        $Password
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

        if ($PSCmdlet.ParameterSetName -eq 'asset')
        {
            $BodyParameters.assetIds = [string[]]@()
            $BodyParameters.type = 'INDIVIDUAL'
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'asset'
            {
                $AssetId | ForEach-Object {
                    $BodyParameters.assetIds += $PSItem
                }
            }
            'album'
            {
                $BodyParameters += @{
                    type    = 'ALBUM'
                    albumId = $AlbumId
                }
            }
        }
    }

    end
    {
        InvokeImmichRestMethod -Method POST -RelativePath '/shared-links' -ImmichSession:$Session -Body $BodyParameters
    }
}
#endregion
