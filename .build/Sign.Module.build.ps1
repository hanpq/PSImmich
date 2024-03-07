param (
    # Base directory of all output (default to 'output')
    [Parameter()]
    [string]
    $OutputDirectory = (property OutputDirectory (Join-Path -Path $BuildRoot -ChildPath 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [string]
    $PFX_BASE64 = (property PFX_BASE64),

    [Parameter()]
    [string]
    $PFX_PASS = (property PFX_PASS 'test')
)

# Synopsis: Deleting the content of the Build Output folder, except ./modules
Task Sign_Module {
    . Set-SamplerTaskVariable

    Import-Module Microsoft.PowerShell.Security

    $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot

    $CertByteArray = [Convert]::FromBase64String($PFX_BASE64)
    $Password = ConvertTo-SecureString -String $PFX_PASS -AsPlainText -Force
    $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($CertByteArray, $password)

    $ScriptsToBeSigned = Get-ChildItem -Path $BuiltModuleBase -Recurse -Include '*.ps1', '*.psm1', '*.psd1'
    foreach ($File in $ScriptsToBeSigned)
    {
        try
        {
            $null = Set-AuthenticodeSignature -Certificate $cert -TimestampServer 'http://timestamp.digicert.com' -FilePath $File.FullName -ErrorAction stop
            Write-Build -Color Green "Signed $(Resolve-Path -Path $File.FullName -Relative)"
        }
        catch
        {
            throw $_
        }
    }
}
