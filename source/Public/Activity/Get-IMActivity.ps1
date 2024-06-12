function Get-IMActivity
{
    <#
    .DESCRIPTION
        Retreives album activity
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines the album to retreive activities for.
    .PARAMETER assetId
        Defines a asset to retreive activities for.
    .PARAMETER level
        Defines the level of activities to retreive, valid values are album or asset.
    .PARAMETER type
        Defines the type of activities to retreive, valid values are comment or like.
    .PARAMETER userId
        Defines a specific user to retreive activities for.
    .EXAMPLE
        Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retreives all activities for an album
    .EXAMPLE
        Get-IMActivity -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -assetId 'a4908e1f-697f-4d7b-9330-93b5eabe3baf'

        Retreives all activities for an album and a specific asset
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $albumId,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $assetId,

        [Parameter()]
        [ValidateSet('album', 'asset')]
        [string]
        $level,

        [Parameter()]
        [ValidateSet('comment', 'like')]
        [string]
        $type,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $userId
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'albumId', 'assetId', 'level', 'type', 'userId')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/activities' -ImmichSession:$Session -QueryParameters $QueryParameters
    }

}
#endregion
