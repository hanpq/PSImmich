function Set-IMConfig
{
    <#
    .SYNOPSIS
        Updates Immich server configuration.
    .DESCRIPTION
        Applies new configuration settings to the Immich server using JSON format.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER RawJSON
        Configuration data as JSON text string.
    .EXAMPLE
        $config = Get-IMConfig -ReturnRawJSON
        Set-IMConfig -RawJSON $config

        Updates server configuration using modified JSON.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [string]
        $RawJSON
    )

    if ($PSCmdlet.ShouldProcess('Config', 'Set'))
    {
        InvokeImmichRestMethod -Method Put -RelativePath '/system-config' -ImmichSession:$Session -RawBody:$RawJSON
    }
}
#endregion
