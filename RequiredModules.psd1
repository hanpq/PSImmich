@{
    PSDependOptions                      = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = 'PSGallery'
        }
    }

    InvokeBuild                          = 'latest'
    PSScriptAnalyzer                     = 'latest'
    Pester                               = 'latest'
    Plaster                              = 'latest'
    ModuleBuilder                        = 'latest'
    ChangelogManagement                  = 'latest'
    Sampler                              = 'latest'
    'Sampler.GitHubTasks'                = 'latest'
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
