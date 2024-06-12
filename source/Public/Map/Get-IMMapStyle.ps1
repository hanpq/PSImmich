function Get-IMMapStyle
{
    <#
    .DESCRIPTION
        Retreives Immich map style
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Theme
        Specifies which theme (dark or light) should be returned.
    .EXAMPLE
        Get-IMMapStyle

        Retreives Immich map style
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(ParameterSetName = 'mapstyle')]
        [ValidateSet('light', 'dark')]
        [ValidateScript({ $PSItem -ceq 'light' -or $PSItem -ceq 'dark' })]
        [string]
        $Theme
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/map/style.json' -ImmichSession:$Session -QueryParameters:@{theme = $Theme }

}
#endregion
