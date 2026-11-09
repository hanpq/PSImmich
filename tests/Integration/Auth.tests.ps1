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

Describe 'Auth' -Tag 'Integration' {
    # Intentionally excluded: none. Test-IMAccessToken is validated against the API-key session so that no extra login session is created.
    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY
    }

    Context 'Test-IMAccessToken' -Tag 'Test-IMAccessToken' {
        It 'Should return true for a valid access token' {
            Test-IMAccessToken | Should -BeTrue
        }
        It 'Should return a boolean' {
            Test-IMAccessToken | Should -BeOfType [bool]
        }
        It 'Should validate the token of an explicit session' {
            $Session = Get-IMSession
            Test-IMAccessToken -Session $Session | Should -BeTrue
        }
        It 'Should return true when called repeatedly' {
            1..3 | ForEach-Object { Test-IMAccessToken | Should -BeTrue }
        }
    }
}
