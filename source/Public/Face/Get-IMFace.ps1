function Get-IMFace
{
    <#
    .DESCRIPTION
        Get immich face
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines the asset id to get faces for
    .EXAMPLE
        Get-IMFace

        Get immich face
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('assetId')]
        [string[]]
        $Id

    )

    PROCESS
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            $QueryParameters = @{
                id = $CurrentID
            }
            InvokeImmichRestMethod -Method GET -RelativePath '/faces' -ImmichSession:$Session -QueryParameters:$QueryParameters
        }
    }
}
#endregion
