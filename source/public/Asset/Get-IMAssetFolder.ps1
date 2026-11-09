function Get-IMAssetFolder
{
    <#
    .SYNOPSIS
        Browses the folders that Immich assets were imported from
    .DESCRIPTION
        Without parameters, returns the unique folder paths that the assets on the server were
        originally stored in. With -Path, returns the assets whose original file is directly
        inside the specified folder.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Path
        The original folder path to list assets for, exactly as it is reported by Immich (see the list form of this command).
    .EXAMPLE
        Get-IMAssetFolder

        Returns the unique folder paths of all assets on the server.
    .EXAMPLE
        Get-IMAssetFolder -Path '/usr/src/app/upload/library/2024'

        Returns the assets whose original file is in the specified folder.
    #>
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'path')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'path'
            {
                Invoke-ImmichApiGetAssetsByOriginalPath -Path $Path -ImmichSession $Session | ForEach-Object { [AssetResponseDto]::new($PSItem) }
            }
            'list'
            {
                Invoke-ImmichApiGetUniqueOriginalPaths -ImmichSession $Session
            }
        }
    }
}
#endregion
