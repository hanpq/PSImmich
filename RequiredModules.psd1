@{
    PSDependOptions                      = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = 'PSGallery'
        }
    }

    InvokeBuild                          = '5.11.3'
    PSScriptAnalyzer                     = 'latest'
    Pester                               = 'latest'
    Plaster                              = 'latest'
    ModuleBuilder                        = '3.1.8'
    ChangelogManagement                  = 'latest'
    Sampler                              = '0.118.1'
    'Sampler.GitHubTasks'                = '0.3.4'
    Encoding                             = 'latest'
    PlatyPS                              = 'latest'
    'Alt3.Docusaurus.Powershell'         = 'latest'
    'Microsoft.PowerShell.PSResourceGet' = @{
        Name           = 'Microsoft.PowerShell.PSResourceGet'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository      = 'PSGallery'
            AllowPrerelease = $true
        }
    }
}
