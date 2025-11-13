function Set-IMServerLicense
{
    <#
    .DESCRIPTION
        Sets Immich server license
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER ActivationKey
        Defines the activation key
    .PARAMETER LicenseKey
        Defines the license key
    .EXAMPLE
        Set-IMServerLicense -LicenseKey "ABC" -ActivationKey "ABC"

        Sets Immich server license
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
