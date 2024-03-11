function Get-IMActivity
{
    <#
    .DESCRIPTION
        Retreives album activity
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines a album id to be retreived
    .PARAMETER assetId
        Defines a specific assetid to retreive activities for.
    .PARAMETER level
        Defines the level of activities to retreive, valid values are album or asset.
    .PARAMETER type
        Defines the type of activities to retreive, valid values are comment or like.
    .PARAMETER userId
        Defines a specific user to retreive activities for.
    .EXAMPLE
        Get-IMActivity

        Retreives album activity
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $albumId,

        [Parameter()]
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
        InvokeImmichRestMethod -Method Get -RelativePath '/activity' -ImmichSession:$Session -QueryParameters $QueryParameters
    }

}
#endregion
