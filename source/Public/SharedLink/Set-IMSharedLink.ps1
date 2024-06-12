function Set-IMSharedLink
{
    <#
    .DESCRIPTION
        Set Immich shared link
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines the asset ids to share
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
        Set-IMSharedLink -id <sharedlinkid> -AllowDownload

        Set Immich shared link
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

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
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PATCH -RelativePath "/shared-links/$PSItem" -ImmichSession:$Session -Body $Body
            }
        }
    }

}
#endregion
