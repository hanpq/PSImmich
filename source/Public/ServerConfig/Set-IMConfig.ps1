function Set-IMConfig
{
    <#
    .DESCRIPTION
        Set immich config
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER RawJSON
        Defines the immich configuration. Provided as JSON text.
    .EXAMPLE
        Set-IMConfig

        Set immich config
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
