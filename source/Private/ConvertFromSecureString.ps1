function ConvertFromSecureString
{
    <#
    .DESCRIPTION
        Function that retreives the original value of the securestring. Obsolete in Windows Core becuase
        ConvertFrom-SecureString has an AsPlainText parameter but this function is instead used for
        Windows Powershell backwards compatiblity.
    .PARAMETER SecureString
        Defines the input securestring variable.
    .EXAMPLE
        ConvertFromSecureString
    #>
    param(
        [securestring]$SecureString
    )

    # Windows Powershell does not include ConvertFrom-SecureString -AsPlainText parameter.
    if ($PSVersionTable.PSEdition -eq 'Desktop')
    {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    # Due to text encoding differences between windows and linux PtrToStringAuto does not work as expected with BSTR
    elseif ($PSVersionTable.PSEdition -eq 'Core')
    {
        $UnsecurePassword = ConvertFrom-SecureString -SecureString $SecureString -AsPlainText
    }

    return ($UnsecurePassword -join '')
}
