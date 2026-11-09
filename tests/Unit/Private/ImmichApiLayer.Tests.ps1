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

InModuleScope $ProjectName {
    BeforeDiscovery {
        $RootItem = Get-Item $PSScriptRoot
        while ($RootItem.GetDirectories().Name -notcontains 'source')
        {
            $RootItem = $RootItem.Parent
        }
        $script:GeneratorPath = Join-Path $RootItem.FullName 'tools\New-ImmichApiLayer.ps1'
    }

    Describe 'Generated API layer' -Tag 'Unit', 'ImmichApiLayer' {
        It 'Should match the committed generated output' {
            $Output = & pwsh -NoProfile -File $script:GeneratorPath -Check 2>&1
            $LASTEXITCODE | Should -Be 0 -Because ($Output | Out-String)
        }

        Context 'When calling a generated GET route with an array query' {
            BeforeAll {
                Mock -CommandName InvokeImmichRestMethod -MockWith { }
            }
            It 'Should send the route and the array as a query parameter' {
                Invoke-ImmichApiGetQueueJobs -Name 'backgroundTask' -Status 'active', 'failed'
                Should -Invoke -CommandName InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Get' -and
                    $RelativePath -eq '/queues/backgroundTask/jobs' -and
                    ($QueryParameters['status'] -join ',') -eq 'active,failed'
                }
            }
            It 'Should omit the query when no optional parameter is supplied' {
                Invoke-ImmichApiGetQueueJobs -Name 'backgroundTask'
                Should -Invoke -CommandName InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $null -eq $QueryParameters
                }
            }
        }

        Context 'When calling a generated POST route that returns octet-stream' {
            BeforeAll {
                Mock -CommandName InvokeImmichRestMethod -MockWith { }
            }
            It 'Should pass the output path through to the request' {
                Invoke-ImmichApiDownloadArchive -Body @{ assetIds = @() } -OutFilePath 'archive.zip'
                Should -Invoke -CommandName InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Post' -and "$OutFilePath" -like '*archive.zip'
                }
            }
            It 'Should not set an output path when none is supplied' {
                Invoke-ImmichApiDownloadArchive -Body @{ assetIds = @() }
                Should -Invoke -CommandName InvokeImmichRestMethod -Times 1 -Exactly -ParameterFilter {
                    -not $OutFilePath
                }
            }
        }

        Context 'When calling a generated multipart route' {
            BeforeAll {
                Mock -CommandName Invoke-MultipartHttpUpload -MockWith { '{}' }
            }
            It 'Should send query, header and extra file parts to the upload helper' {
                $Sidecar = New-Item -Path (Join-Path $TestDrive 'sidecar.xmp') -ItemType File
                Invoke-ImmichApiUploadAsset -Key 'k1' -XImmichChecksum 'abc' -FileInfo $Sidecar -SidecarData $Sidecar | Out-Null
                Should -Invoke -CommandName Invoke-MultipartHttpUpload -Times 1 -Exactly -ParameterFilter {
                    $RelativePath -eq '/assets' -and
                    $FileFieldName -eq 'assetData' -and
                    $QueryParameters['key'] -eq 'k1' -and
                    $Headers['x-immich-checksum'] -eq 'abc' -and
                    $AdditionalFiles.ContainsKey('sidecarData')
                }
            }
        }

        Context 'When constructing a generated DTO from a response object' {
            It 'Should map properties and convert date values' {
                $Dto = [UserResponseDto]::new([pscustomobject]@{ id = 'u1'; name = 'Test'; profileChangedAt = '2024-01-02T03:04:05Z' })
                $Dto.id | Should -Be 'u1'
                $Dto.name | Should -Be 'Test'
                $Dto.profileChangedAt | Should -BeOfType ([datetime])
            }
        }
    }

    Describe 'InvokeImmichRestMethod query and output handling' -Tag 'Unit', 'ImmichApiLayer' {
        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith {}
            $Session = [ImmichSession]::New('https://immich.domain.com', 'AccessToken', (ConvertTo-SecureString -String 'accesstoken' -AsPlainText -Force), $true, (New-Object -TypeName pscredential -ArgumentList 'username', (ConvertTo-SecureString -String 'password' -AsPlainText -Force)), (ConvertTo-SecureString -String 'jwt' -AsPlainText -Force), '1.1.1', (New-Guid).Guid)
        }
        It 'Should send array query values as repeated keys' {
            InvokeImmichRestMethod -Method get -ImmichSession:$Session -RelativePath '/auth/login' -QueryParameters:@{ status = @('active', 'failed') }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -match 'status=active&status=failed$'
            }
        }
        It 'Should write a POST octet-stream response to the output path' {
            $OutFile = Join-Path $TestDrive 'out.zip'
            InvokeImmichRestMethod -Method post -ImmichSession:$Session -RelativePath '/auth/login' -Body:@{ assetIds = @() } -OutFilePath $OutFile
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $OutFile -like '*out.zip'
            }
        }
    }
}
