function Get-IMConfig
{
    <#
    .SYNOPSIS
        Retrieves Immich server configuration.
    .DESCRIPTION
        Gets current or default server configuration settings, optionally as raw JSON.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Default
        Retrieves default configuration instead of current settings.
    .PARAMETER ReturnRawJSON
        Returns configuration as raw JSON for modification and use with Set-IMConfig.
    .PARAMETER StorageTemplate
        Returns storage template configuration settings.
    .EXAMPLE
        Get-IMConfig

        Gets current server configuration.
    .EXAMPLE
        Get-IMConfig -ReturnRawJSON

        Gets configuration as JSON for editing.
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
        $StorageTemplate

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
        'storage'
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/system-config/storage-template-options' -ImmichSession:$Session
            break
        }
    }

}
#endregion
