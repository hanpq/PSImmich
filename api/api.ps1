$temp = Get-Content C:\Repos\PSImmich\api.1.105.local.json | ConvertFrom-Json -Depth 10

$AllCodeFiles = Get-ChildItem 'C:\Repos\PSImmich\source\public' -Recurse -Filter '*.ps1'
$AllCodeFilesAst = foreach ($file in $AllCodeFiles)
{
    Get-Command $file.FullName
}
$AllCodeFileCommands = foreach ($ast in $AllCodeFilesAst)
{
    $ast.ScriptBlock.Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
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
    }
}

$Result = foreach ($path in $temp.paths.PSObject.Properties.Name)
{
    $ApiSkipList = @(
        '/asset/bulk-upload-check',
        '/asset/exist',
        '/auth/admin-sign-up',
        '/auth/change-password'
    )

    $CleanedPath = $Path.Replace('{id}', '*').Replace('{deviceId}', '*').Replace('{userId}', '*')

    if ($apiskiplist -contains $path)
    {
        continue
    }

    $PathObject = $temp.paths.$path

    foreach ($Method in $PathObject.PSObject.Properties.Name)
    {

        $Object = [pscustomobject]@{
            Method     = $Method.ToUpper()
            Path       = $Path
            Parameters = $($Params -join ',')
            Covered    = [boolean]($CalledApiFunctions | Where-Object { $PSItem.RelativePath -like $CleanedPath -and $PSItem.Method -eq $Method })
        }

        # Special cases

        $ForceCovered = @(
            '/asset/upload', # upload is not using InvokeImmichRestMethod and is therefor not detected but it is covered.
            '/auth/login', # handled in immichsession class and is therefor not detected
            '/auth/logout' # not using InvokeImmichRestMethod and is therefor not detected
        )
        if ($ForceCovered -contains $CleanedPath) {
            $Object.Covered = $true
        }


        $Object
        $Object | Export-Csv -Path C:\Repos\PSImmich\api.1.105.local.csv -Delimiter ';' -Encoding UTF8 -Append
    }
}

$Result | Out-Default
$CoveredCount = $Result | Where-Object covered -EQ $true | Measure-Object | Select-Object -expand count

Write-Host "API Coverage $($CoveredCount) / $($Result.Count) ($([Math]::Round($CoveredCount/($Result.Count)*100,0))%)" -ForegroundColor Magenta
