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

    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    $BodyParameters = @{}
    $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'ActivationKey', 'LicenseKey' -namemapping @{ActivationKey = 'activationKey'; LicenseKey = 'licenseKey'} )

    if ($PSCmdlet.ShouldProcess('Service license', 'set')) {
        InvokeImmichRestMethod -Method Put -RelativePath "/server/license" -ImmichSession:$Session -Body:$BodyParameters
    }

}
#endregion
