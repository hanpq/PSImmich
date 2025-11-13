function Set-IMServerLicense
{
    <#
    .SYNOPSIS
        Activates Immich server license.
    .DESCRIPTION
        Installs and activates server license using provided keys.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER ActivationKey
        License activation key provided by Immich.
    .PARAMETER LicenseKey
        License key for server activation.
    .EXAMPLE
        Set-IMServerLicense -LicenseKey 'your-license' -ActivationKey 'activation-key'

        Activates server with provided license keys.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('activationKey')]
        [string]
        $ActivationKey,

        [Parameter(Mandatory)]
        [ValidatePattern('IM(SV|CL)(-[\dA-Za-z]{4}){8}')]
        [ApiParameter('licenseKey')]
        [string]
        $LicenseKey
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    if ($PSCmdlet.ShouldProcess('Service license', 'set'))
    {
        InvokeImmichRestMethod -Method Put -RelativePath '/server/license' -ImmichSession:$Session -Body:$BodyParameters
    }

}
#endregion
