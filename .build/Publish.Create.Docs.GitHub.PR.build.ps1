param
(
    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [string]
    $GitHubToken = (property GitHubToken ''), # retrieves from Environment variable

    [Parameter()]
    [string]
    $GitHubConfigUserEmail = (property GitHubConfigUserEmail ''),

    [Parameter()]
    $BuildInfo = (property BuildInfo @{ }),

    [Parameter()]
    [string]
    $GitHubConfigUserName = (property GitHubConfigUserName ''),

    [Parameter()]
    [string]
    $BuildRoot = (property BuildRoot '')
)

# CI: Generera docs
# Build: Generera tasks
# Build: Upload docs

Task Update_GetPSDev_Docs {
    . Set-SamplerTaskVariable

    # Get variables from buildinfo
    foreach ($GitHubConfigKey in @('GitHubConfigUserName', 'GitHubConfigUserEmail'))
    {
        if ( -Not (Get-Variable -Name $GitHubConfigKey -ValueOnly -ErrorAction SilentlyContinue))
        {
            # Variable is not set in context, use $BuildInfo.GitHubConfig.<varName>
            $ConfigValue = $BuildInfo.GitHubConfig.($GitHubConfigKey)
            Set-Variable -Name $GitHubConfigKey -Value $ConfigValue
            Write-Build DarkGray "`t$GitHubConfigKey : $ConfigValue"
        }
    }

    # Debug show values
    Write-Build DarkGray "`tBuiltModuleSubdirectory : $BuiltModuleSubdirectory"
    Write-Build DarkGray "`tBuiltModuleManifest : $BuiltModuleManifest"
    Write-Build DarkGray "`tBuildRoot : $BuildRoot"

    # Define docs create path
    $TemporaryDocsFolder = Join-Path $BuiltModuleSubdirectory 'docs'
    $TemporaryDocsFolderModules = Join-Path $TemporaryDocsFolder 'modules'

    # Cleanup docs destination path
    if (Test-Path $TemporaryDocsFolder)
    {
        Remove-Item $TemporaryDocsFolder -Force -Recurse
    }

    $DocsRepo = $BuildInfo.GitHubConfig.Docs.DocsRepo
    git clone $DocsRepo $TemporaryDocsFolder --quiet

    git -C $TemporaryDocsFolder config user.name $GitHubConfigUserName
    git -C $TemporaryDocsFolder config user.email $GitHubConfigUserEmail

    # Commit.gpgsign is configured in local default git config, force gpgsign to false in build pipeline
    git -C $TemporaryDocsFolder config commit.gpgsign false

    # Static text
    $ScriptBlock = {

        $GetStartedPrefix = @'
---
id: getstarted
title: Get started
---

'@

        $ChangelogPrefix = @'
---
id: changelog
title: Changelog
---

'@

        $sidebarjsTemplate = @'
const commands = require('./commands/docusaurus.sidebar.js');
module.exports = [
    {{
        type: 'category',
        label: 'Introduction',
        collapsed: false,
        items: [
            '{0}/getstarted',
            '{0}/changelog'
        ]
    }},
    {{
        type: 'category',
        label: 'Command Reference',
        collapsed: true,
        items: commands
    }},
];

'@
        # Create commands docs
        $TemporaryDocsFolder = Join-Path $args[0] 'docs'
        $TemporaryDocsFolderModules = Join-Path $TemporaryDocsFolder 'modules'
        Import-Module platyPS
        Import-Module (Join-Path $args[2] $args[1]) -Force
        $DocuSplat = @{
            Module          = $args[1]
            DocsFolder      = $TemporaryDocsFolderModules
            Sidebar         = "$($args[1])/commands"
            MetaDescription = ('Help page for the Powershell "%1" command')
            MetaKeywords    = 'Powershell', $($args[1]), 'Help', 'Documentation'
            AppendMarkdown  = ("## EDIT THIS DOC `n`nThis page was auto-generated from the powershell command comment based help. To edit the content of this page, update the script file comment based help on github [Github](https://github.com/hanpq/{0})" -f $args[1])
        }
        $null = New-DocusaurusHelp @DocuSplat -ErrorAction Stop -WarningAction SilentlyContinue

        # Generate new changelog
        $SourceChangeLogPath = Join-Path $args[3] 'CHANGELOG.md'
        Write-Output "Source changelog path is: $SourceChangeLogPath"
        $ChangeLogContent = Get-Content $SourceChangeLogPath -Raw
        $DestinationModulePath = Join-Path $TemporaryDocsFolderModules $args[1]
        Write-Output "Destination module path is: $DestinationModulePath"
        $DestinationChangeLogPath = Join-Path $DestinationModulePath 'changelog.md'
        Write-Output "Destination changelog path is: $DestinationChangeLogPath"
        $ChangelogPrefix + $ChangeLogContent | Out-File -FilePath $DestinationChangeLogPath

        # Generate new getstarted
        $SourceReadmePath = Join-Path $args[3] 'README.md'
        Write-Output "Source readme path is: $SourceReadmePath"
        $ReadmeContent = Get-Content $SourceReadmePath -Raw
        $DestinationModulePath = Join-Path $TemporaryDocsFolderModules $args[1]
        Write-Output "Destination module path is: $DestinationModulePath"
        $DestinationGetStartedPath = Join-Path $DestinationModulePath 'getstarted.md'
        Write-Output "Destination getstarted path is: $DestinationGetStartedPath"
        $GetStartedPrefix + $ReadmeContent | Out-File -FilePath $DestinationGetStartedPath

        # Generate new sidebar
        $DestinationModulePath = Join-Path $TemporaryDocsFolderModules $args[1]
        Write-Output "Destination module path is: $DestinationModulePath"
        $DestinationSidebarPath = Join-Path $DestinationModulePath 'sidebar.js'
        Write-Output "Destination sidebar path is: $DestinationGetStartedPath"
        ($sidebarjsTemplate -f $args[1])  | Out-File -FilePath $DestinationSidebarPath

        # Remove module
        Remove-Module -name $args[1] -Force -ErrorAction Stop

    }

    # Start job is a workaround because New-DocusarusHelp depends on platyps.
    # PlatyPS has a dependency library collision with powershell-yaml for the
    # DotNetYaml assembly. By running the doc generation with Start-Job PlatyPS
    # is loaded in a separate powershell process.
    $result = Start-Job $ScriptBlock -WorkingDirectory (Get-Location).ToString() -ArgumentList $BuiltModuleSubdirectory, $ProjectName, $OutputDirectory, $BuildRoot | Receive-Job -Wait
    $result | ForEach-Object {
        Write-Build DarkGray "`t$_"
    }
    Write-Build Green "`tSuccessfully generated updated docs for $ProjectName"

    $null = git -C $TemporaryDocsFolder add . 2>&1
    Write-Build Green "`tStaged files for $ProjectName"

    $null = git -C $TemporaryDocsFolder commit -m "Updating Docs for $ProjectName" 2>&1
    Write-Build Green " `tSuccessfully commited files for $ProjectName"

    $remoteURL = [URI](git -C $TemporaryDocsFolder remote get-url origin)
    $URI = $remoteURL.Scheme + [URI]::SchemeDelimiter + $GitHubToken + '@' + $remoteURL.Authority + $remoteURL.PathAndQuery
    git -C $TemporaryDocsFolder remote set-url --push origin $URI
    git -C $TemporaryDocsFolder push -u origin HEAD --quiet
    Write-Build Green "`tSuccessfully pushed updated docs to github"

    Remove-Item $TemporaryDocsFolder -Force -Recurse

}
