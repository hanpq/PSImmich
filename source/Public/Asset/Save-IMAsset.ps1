function Save-IMAsset
{
    <#
    .DESCRIPTION
        Downloads and saves Immich assets to a local directory
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.

        -Session $Session
    .PARAMETER Id
        Defines a specific asset ID to be downloaded. Accepts pipeline input.
    .PARAMETER Key
        Defines an optional key parameter.
    .PARAMETER Path
        Defines the directory where the downloaded file will be saved. The file will retain its original filename.
    .EXAMPLE
        Save-IMAsset -Id '550e8400-e29b-41d4-a716-446655440000' -Path 'C:\Downloads'

        Downloads the specified asset to the C:\Downloads directory
    .EXAMPLE
        Get-IMAsset -Random -Count 5 | Save-IMAsset -Path 'C:\RandomAssets'

        Downloads 5 random assets to the C:\RandomAssets directory using pipeline input
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter()]
        [ApiParameter('key')]
        [string]
        $Key,

        [Parameter()]
        [System.IO.DirectoryInfo]
        $Path
    )

    begin
    {
        $QueryParameters = @{}
        $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            $AssetObject = Get-IMAsset -id $CurrentID
            $OutputPath = Join-Path -Path $Path -ChildPath $AssetObject.originalFileName
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $SavedProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
            }
            InvokeImmichRestMethod -Method Get -RelativePath "/assets/$CurrentID/original" -ImmichSession:$Session -QueryParameters $QueryParameters -ContentType 'application/octet-stream' -OutFilePath $OutputPath
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }

}
#endregion
