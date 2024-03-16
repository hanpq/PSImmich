function Start-IMJob
{
    <#
    .DESCRIPTION
        Start immich job
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Job
        asd
    .PARAMETER Force
        asd
    .EXAMPLE
        Start-IMJob

        Start immich job
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidateSet('thumbnailGeneration', 'metadataExtraction', 'videoConversion', 'faceDetection', 'facialRecognition', 'smartSearch', 'backgroundTask', 'storageTemplateMigration', 'migration', 'search', 'sidecar', 'library')]
        [string[]]
        $Job,

        [Parameter()]
        [switch]
        $Force
    )

    $Job | ForEach-Object {
        $CurrentJob = $PSItem
        $Body = @{}
        $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Force')
        $Body += @{command = 'start' }
        InvokeImmichRestMethod -Method PUT -RelativePath "/jobs/$CurrentJob" -ImmichSession:$Session -Body:$Body
    }
}
#endregion
