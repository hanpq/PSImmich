function Get-IMConfig
{
    <#
    .DESCRIPTION
        Retreives Immich config
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Default
        Retreives default config instead of current applied
    .PARAMETER ReturnRawJSON
        This is useful if you want to alter the current config and pass it on to Set-IMConfig
    .PARAMETER StorageTemplate
        Specifies that storage template configuration should be returned.
    .PARAMETER MapStyle
        Specifies that map style configuration should be returned.
    .PARAMETER Theme
        Specifies which theme (dark or light) should be returned.
    .EXAMPLE
        Get-IMConfig

        Retreives Immich config
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'applied')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(ParameterSetName = 'applied')]
        [Parameter(ParameterSetName = 'default')]
        [switch]
        $ReturnRawJSON,

        [Parameter(ParameterSetName = 'default')]
        [switch]
        $Default,

        [Parameter(ParameterSetName = 'storage')]
        [switch]
        $StorageTemplate,

        [Parameter(ParameterSetName = 'mapstyle')]
        [switch]
        $MapStyle,

        [Parameter(ParameterSetName = 'mapstyle')]
        [ValidateSet('light', 'dark')]
        [ValidateScript({ $PSItem -ceq 'light' -or $PSItem -ceq 'dark' })]
        [string]
        $Theme
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'applied'
        {
            $Result = InvokeImmichRestMethod -Method Get -RelativePath '/system-config' -ImmichSession:$Session
            if ($ReturnRawJSON)
            {
                $Result | ConvertTo-Json -Depth 10
            }
            else
            {
                $Result
            }
            break
        }
        'default'
        {
            $Result = InvokeImmichRestMethod -Method Get -RelativePath '/system-config/defaults' -ImmichSession:$Session
            if ($ReturnRawJSON)
            {
                $Result | ConvertTo-Json -Depth 10
            }
            else
            {
                $Result
            }
            break
        }
        'mapstyle'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/system-config/map/style.json' -ImmichSession:$Session -QueryParameters:@{theme = $Theme }
            break
        }
        'storage'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/system-config/storage-template-options' -ImmichSession:$Session
            break
        }
    }

}
#endregion
