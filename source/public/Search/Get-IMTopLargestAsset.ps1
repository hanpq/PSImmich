function Get-IMTopLargestAsset
{
    <#
    .SYNOPSIS
        Retrieves the largest assets from Immich
    .DESCRIPTION
        Gets the top largest assets by file size from your Immich library. This is a convenience
        function that calls the large-assets search API without any filters to return the
        biggest files in your collection. Results include file size information and can be
        easily sorted or filtered as needed.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Size
        Maximum number of assets to return. Defaults to 100, maximum is 1000.
    .EXAMPLE
        Get-IMTopLargestAsset

        Returns the top 100 largest assets in your library.
    .EXAMPLE
        Get-IMTopLargestAsset -Size 50

        Returns the top 50 largest assets.
    .EXAMPLE
        Get-IMTopLargestAsset | Sort-Object exifInfo.fileSizeInByte -Descending | Select-Object -First 10

        Gets the largest assets and sorts them by actual file size, showing the top 10.
    .NOTES
        This cmdlet is a simplified interface to the large-assets search endpoint.
        For more advanced filtering by date, location, type, etc., use the full search functionality available in other cmdlets.
        The results include full asset metadata including exifInfo.fileSizeInByte for precise size information.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ApiParameter('size')]
        [ValidateRange(1, 1000)]
        [int]
        $Size = 100
    )

    # Ensure Size parameter is always included, even when using default value
    $Parameters = @{}
    foreach ($key in $PSBoundParameters.Keys)
    {
        $Parameters[$key] = $PSBoundParameters[$key]
    }
    if (-not $Parameters.ContainsKey('Size'))
    {
        $Parameters['Size'] = $Size
    }

    $Body = @{}
    $Body += (ConvertTo-ApiParameters -BoundParameters $Parameters -CmdletName $MyInvocation.MyCommand.Name)

    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/large-assets' -ImmichSession:$Session -Body $Body
    $Result | AddCustomType IMLargeAsset
}
#endregion
