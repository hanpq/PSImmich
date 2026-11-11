BeforeDiscovery {
    $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains 'source')
    {
        $RootItem = $RootItem.Parent
    }
    $ProjectPath = $RootItem.FullName
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            $_.Directory.Name -eq 'source' -and (Test-ModuleManifest $_.FullName -ErrorAction Stop)
        }).BaseName
    Import-Module $ProjectName -Force
}

Describe 'Passkey read operations' -Tag 'Integration', 'Get-IMPasskey' {
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
        $Version = Get-IMServer -Version
        if ($Version.version -notmatch '^3\.4\.')
        {
            throw 'Passkey integration tests require an Immich 3.4 server.'
        }
    }

    It 'Lists passkeys for the current user without changing them' {
        { @(Get-IMPasskey) } | Should -Not -Throw
    }

    It 'Retrieves an existing passkey without changing it' {
        $Passkeys = @(Get-IMPasskey)
        if ($Passkeys.Count -eq 0)
        {
            Set-ItResult -Skipped -Because 'No existing passkey is available for read-only retrieval.'
            return
        }
        $Result = Get-IMPasskey -Id $Passkeys[0].id
        ($Result.id -eq $Passkeys[0].id) | Should -BeTrue
    }
}
