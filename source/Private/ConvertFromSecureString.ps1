function ConvertFromSecureString
{
    <#
    .DESCRIPTION
        Function that retreives the original value of the securestring. Obsolete in Windows Core becuase
        ConvertFrom-SecureString has an AsPlainText parameter but this function is instead used for
        Windows Powershell backwars compatiblity.
    .PARAMETER SecureString
        Defines the input securestring variable.
    .EXAMPLE
        ConvertFromSecureString
    #>
    param(
        [securestring]$SecureString
    )

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    return ($UnsecurePassword -join '')
}
