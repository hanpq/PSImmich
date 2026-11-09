BeforeDiscovery {
    $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains 'source')
    {
        $RootItem = $RootItem.Parent
    }
    $ProjectPath = $RootItem.FullName
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
            ($_.Directory.Name -eq 'source') -and
            $(try
                {
                    Test-ModuleManifest $_.FullName -ErrorAction Stop
                }
                catch
                {
                    $false
                })
        }
    ).BaseName

    Import-Module $ProjectName -Force
}

Describe 'AuthSession' -Tag 'Integration' {
    # Intentionally excluded: Remove-IMAuthSession (logs out login sessions on the shared live server, including the current one).
    AfterAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }

    Context 'Get-IMAuthSession' -Tag 'Get-IMAuthSession' {
        BeforeAll {
            $Cred = New-Object -TypeName pscredential -ArgumentList $env:PSIMMICHUSER, (ConvertTo-SecureString -String $env:PSIMMICHPASSWORD -AsPlainText -Force)
            Connect-Immich -BaseURL $env:PSIMMICHURI -Credential $Cred
            $Sessions = @(Get-IMAuthSession)
        }
        It 'Should return sessions' {
            $Sessions.Count | Should -BeGreaterThan 0
        }
        It 'Should return SessionResponseDto objects' {
            $Sessions | ForEach-Object { $_.GetType().Name | Should -Be 'SessionResponseDto' }
        }
        It 'Should return exactly one current session' {
            @($Sessions | Where-Object { $_.current -eq $true }) | Should -HaveCount 1
        }
        It 'Should return session ids' {
            $Sessions | ForEach-Object { $_.id | Should -Not -BeNullOrEmpty }
        }
    }
}
