function Save-IMAsset
{
    <#
    .DESCRIPTION
        Save Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific asset id to be retreived
    .PARAMETER isThumb
        Defines if faviorites should be returned or not. Do not specify if either should be returned.
    .PARAMETER isWeb
        Defines if archvied assets should be returned or not. Do not specify if either should be returned.
    .PARAMETER Path
        Defines filepath for outputfile
    .EXAMPLE
        Save-IMAsset

        Save Immich asset
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
        [switch]
        $isThumb,

        [Parameter()]
        [switch]
        $isWeb,

        [Parameter()]
        [System.IO.DirectoryInfo]
        $Path
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'isThumb', 'isWeb')
    }

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            $AssetObject = Get-IMAsset -Id $CurrentID
            $OutputPath = Join-Path -Path $Path -ChildPath $AssetObject.originalFileName
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $SavedProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
            }
            InvokeImmichRestMethod -Method Get -RelativePath "/asset/file/$CurrentID" -ImmichSession:$Session -QueryParameters $QueryParameters -ContentType 'application/octet-stream' -OutFilePath $OutputPath
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }

}
#endregion
