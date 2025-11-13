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

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    PROCESS
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
