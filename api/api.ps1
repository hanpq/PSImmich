$temp = Get-Content C:\Repos\PSImmich\api\api.1.107.json | ConvertFrom-Json -Depth 10

$AllCodeFiles = Get-ChildItem 'C:\Repos\PSImmich\source\public' -Recurse -Filter '*.ps1'
$AllCodeFilesAst = foreach ($file in $AllCodeFiles)
{
    $AST = Get-Command $file.FullName
    $AST | Add-Member -MemberType NoteProperty -Name FullName -Value $file.fullname -PassThru -Force
}
$AllCodeFileCommands = foreach ($ast in $AllCodeFilesAst)
{
    $command = $ast.ScriptBlock.Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
    $command | Add-Member -MemberType NoteProperty -Name FullName -Value $ast.fullname -PassThru -Force
}
$AllCodeFileCommands = $AllCodeFileCommands | Where-Object { $PSItem.Extent.Text -like 'InvokeImmichRestMethod*' }
$CalledApiFunctions = foreach ($invocation in $AllCodeFileCommands)
{
    $MethodIndex = $invocation.CommandElements.Extent.Text.IndexOf('-Method')
    $Method = $invocation.CommandElements.Extent.Text[ ($MethodIndex + 1) ]
    $RelativePathIndex = $invocation.CommandElements.Extent.Text.IndexOf('-RelativePath')
    $RelativePath = $invocation.CommandElements.Extent.Text[ ($RelativePathIndex + 1) ]
    [pscustomobject]@{
        Method       = $Method.ToUpper()
        RelativePath = $RelativePath.Replace("'", '').Replace('"', '')
        FullName     = $invocation.fullname
        BaseName     = (Get-Item $invocation.Fullname | Select-Object -expand basename)
    }
}

$Result = foreach ($path in $temp.paths.PSObject.Properties.Name)
{
    $CleanedPath = $Path.Replace('{id}', '*').Replace('{deviceId}', '*').Replace('{userId}', '*')

    $PathObject = $temp.paths.$path

    foreach ($Method in $PathObject.PSObject.Properties.Name)
    {
        $CoveredBy = $CalledApiFunctions | Where-Object { $PSItem.RelativePath -like $CleanedPath -and $PSItem.Method -eq $Method }
        $Object = [pscustomobject]@{
            Method    = $Method.ToUpper()
            Path      = $Path
            Skipped   = $false
            Covered   = [boolean]($CoveredBy)
            CoveredBy = ($CoveredBy.BaseName | Select-Object -Unique) -join ','

        }

        # Cmdlets covered but not detected
        switch ($Object)
        {
            { $_.Path -eq '/auth/login' -and $_.Method -eq 'POST' }
            {
                $Object.Covered = $true; $Object.CoveredBy = 'Connect-Immich'
            }
            { $_.Path -eq '/auth/logout' -and $_.Method -eq 'POST' }
            {
                $Object.Covered = $true; $Object.CoveredBy = 'Disconnect-Immich'
            }
            { $_.Path -eq '/assets' -and $_.Method -eq 'POST' }
            {
                $Object.Covered = $true; $Object.CoveredBy = 'Import-IMAsset'
            }
        }

        # Cmdlets skipped and should not count for coverage
        switch ( $Object)
        {
            { $_.Path -eq '/assets/bulk-upload-check' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Probably used by mobile'
            }
            { $_.Path -eq '/assets/exist' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Not sure'
            }
            { $_.Path -eq '/auth/admin-sign-up' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Not sure of the use case for using with powershell'
            }
            { $_.Path -eq '/auth/change-password' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Not sure of the use case for using with powershell'
            }
            { $_.Path -eq '/download/archive' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Can use Save-IMAsset to download assets'
            }
            { $_.Path -eq '/download/asset/{id}' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Can use Save-IMAsset to download assets'
            }
            { $_.Path -eq '/download/info' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Not sure'
            }
            { $_.Path -eq '/oauth/authorize' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Used for OIDC integration, not used interactivly'
            }
            { $_.Path -eq '/oauth/callback' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Used for OIDC integration, not used interactivly'
            }
            { $_.Path -eq '/oauth/link' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Used for OIDC integration, not used interactivly'
            }
            { $_.Path -eq '/oauth/mobile-redirect' -and $_.Method -eq 'GET' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Used for OIDC integration, not used interactivly'
            }
            { $_.Path -eq '/oauth/unlink' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Used for OIDC integration, not used interactivly'
            }
            { $_.Path -eq '/people/{id}' -and $_.Method -eq 'PUT' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'This is the single item version of the batch version PUT:/person (Set-IMPerson).'
            }
            { $_.Path -eq '/people/{id}/reassign' -and $_.Method -eq 'PUT' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/reports/fix' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/sync/delta-sync' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/sync/full-sync' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/system-metadata/admin-onboarding' -and $_.Method -eq 'GET' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/system-metadata/admin-onboarding' -and $_.Method -eq 'POST' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/system-metadata/reverse-geocoding-state' -and $_.Method -eq 'GET' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Unclear usage of the API, no docs'
            }
            { $_.Path -eq '/assets/{id}/video/playback' -and $_.Method -eq 'GET' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Not applicable for powershell'
            }
            { $_.Path -eq '/search/suggestions' -and $_.Method -eq 'GET' }
            {
                $Object.Skipped = $true; $Object.CoveredBy = 'Not applicable for powershell'
            }
        }

        $Object
        #$Object | Export-Csv -Path C:\Repos\PSImmich\api\api.1.106.csv -Delimiter ';' -Encoding UTF8 -Append
    }
}

function GetTableColor
{
    param ($propertyname)
    foreach ($property in $propertyname)
    {
        $Hash = [hashtable]@{
            Label      = $property
            Expression = [scriptblock]::Create(@'
            if ($_.Skipped -eq $true -and $_.Covered -eq $false )
            {{
                $e = [char]27; "$e[38;5;8m$($_.{0})$e[0m"
    }}
            elseif ( $_.Skipped -eq $false -and $_.Covered -eq $false )
            {{
                $e = [char]27; "$e[38;5;9m$($_.{0})$e[0m"
    }}
            elseif ( $_.Skipped -eq $false -and $_.Covered -eq $true )
            {{
                $e = [char]27; "$e[38;5;10m$($_.{0})$e[0m"
    }}
            else
            {{
                $e = [char]27; "$e[38;5;15m$($_.{0})$e[0m"
    }}
'@ -f $property
            )
        }
        $Hash
    }

}

$Result | Format-Table (GetTableColor -propertyname 'Method', 'Path', 'Skipped', 'Covered', 'CoveredBy')
$CoveredCount = $Result | Where-Object { $_.covered -EQ $true -and $_.skipped -eq $false } | Measure-Object | Select-Object -expand count

Write-Host "API Coverage $($CoveredCount) / $($Result.Count) ($([Math]::Round($CoveredCount/($Result.Count)*100,0))%)" -ForegroundColor Magenta
