function Get-IMSharedLink
{
    <#
    .SYNOPSIS
        Retrieves shared links for asset sharing.
    .DESCRIPTION
        Gets shared links that allow external access to assets and albums.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific shared link ID to retrieve.
    .PARAMETER AlbumId
        Filter by album ID to get album shared links.
    .EXAMPLE
        Get-IMSharedLink

        Gets all shared links.
    .EXAMPLE
        Get-IMSharedLink -Id 'link-id'

        Gets specific shared link details.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter(ParameterSetName = 'list')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        $AlbumId
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                $ListParameters = @{ ImmichSession = $Session }
                if ($PSBoundParameters.ContainsKey('AlbumId'))
                {
                    $ListParameters.AlbumId = $AlbumId
                }
                Invoke-ImmichApiGetAllSharedLinks @ListParameters | ForEach-Object { [SharedLinkResponseDto]::new($PSItem) }
            }
            'id'
            {
                $id | ForEach-Object {
                    Invoke-ImmichApiGetSharedLinkById -Id $PSItem -ImmichSession $Session | ForEach-Object { [SharedLinkResponseDto]::new($PSItem) }
                }
            }
        }
    }
}
#endregion
