﻿BeforeDiscovery {
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

InModuleScope $ProjectName {
    Describe 'ConvertFromSecureString' -Tag 'Unit' {
        Context 'When providing a securestring' {
            It 'Should return the correct string' {
                $SecureString = ConvertTo-SecureString -String 'immich' -AsPlainText -Force
                ConvertFromSecureString -SecureString $SecureString | Should -BeExactly 'immich'
            }
        }
    }
}
