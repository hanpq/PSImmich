function New-IMSharedLink
{
    <#
    .DESCRIPTION
        New Immich shared link
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER AssetId
        Defines the asset ids to share
    .PARAMETER AlbumId
        Defines the albumid to share
    .PARAMETER AllowDownload
        Defines if downloading of assets are permitted.
    .PARAMETER AllowUpload
        Defines if uploads of assets are permitted.
    .PARAMETER Description
        Defines a description of the shared link
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
        [switch]
        $AllowDownload,

        [Parameter()]
        [switch]
        $AllowUpload,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [datetime]
        $ExpiresAt,

        [Parameter()]
        [switch]
        $ShowMetadata,

        [Parameter()]
        [securestring]
        $Password
    )

    BEGIN
    {
        $Body = @{}
        $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'AllowDownload', 'AllowUpload', 'Description', 'ExpiresAt', 'ShowMetadata', 'Password' -NameMapping @{
                AllowDownload = 'allowDownload'
                AllowUpload   = 'allowUpload'
                Description   = 'description'
                ExpiresAt     = 'expiresAt'
                ShowMetadata  = 'showMetadata'
                Password      = 'password'
            })
        if ($PSCmdlet.ParameterSetName -eq 'asset')
        {
            $Body.assetIds = [string[]]@()
            $Body.type = 'INDIVIDUAL'
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'asset'
            {
                $AssetId | ForEach-Object {
                    $Body.assetIds += $PSItem
                }
            }
            'album'
            {
                $Body += @{
                    type    = 'ALBUM'
                    albumId = $AlbumId
                }
            }
        }
    }

    END
    {
        InvokeImmichRestMethod -Method POST -RelativePath '/shared-links' -ImmichSession:$Session -Body $Body
    }
}
#endregion
