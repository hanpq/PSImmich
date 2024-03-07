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
                }) }
    ).BaseName

    Import-Module $ProjectName -Force
}

InModuleScope $ProjectName {
    Describe Assert-FolderExist {
        Context 'Default' {
            It 'Folder is created' {
                'TestDrive:\FolderDoesNotExists' | Assert-FolderExist
                'TestDrive:\FolderDoesNotExists' | Should -Exist
            }

            It 'Folder is still present' {
                New-Item -Path 'TestDrive:\FolderExists' -ItemType Directory
                'TestDrive:\FolderExists' | Assert-FolderExist
                'TestDrive:\FolderExists' | Should -Exist
            }
        }
    }
}
