function Set-IMSharedLink
{
    <#
    .SYNOPSIS
        Updates shared link settings.
    .DESCRIPTION
        Modifies permissions and properties of an existing shared link.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Shared link ID to update.
    .PARAMETER AllowDownload
        Permits downloading assets through the shared link.
    .PARAMETER AllowUpload
        Permits uploading assets through the shared link.
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
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PATCH -RelativePath "/shared-links/$PSItem" -ImmichSession:$Session -Body $BodyParameters
            }
        }
    }

}
#endregion
