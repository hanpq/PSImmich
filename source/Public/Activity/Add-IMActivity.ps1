function Add-IMActivity
{
    <#
    .DESCRIPTION
        Adds a new activity to an album
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines a album id to be retreived
    .PARAMETER assetId
        Defines a specific assetid to retreive activities for.
    .PARAMETER comment
        Defines the comment to post.
    .PARAMETER type
        Defines the type of activities to retreive, valid values are comment or like.
    .EXAMPLE
        Add-IMActivity

        Adds a new activity to an album
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
        [string]
        $comment,

        [Parameter()]
        [ValidateSet('comment', 'like')]
        [string]
        $type
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'albumId', 'assetId', 'comment', 'type')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/activity' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
