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
            It 'Should preserve an unconstrained WebAuthn response including nested values' {
                $Response = [pscustomobject]@{
                    id = 'credential'
                    response = [pscustomobject]@{ clientDataJSON = 'encoded'; transports = @('usb', 'nfc') }
                }
                $Dto = [PasskeyRegistrationFinishDto]::new([pscustomobject]@{ name = 'Key'; response = $Response })
                [object]::ReferenceEquals($Dto.response, $Response) | Should -BeTrue
                $Dto.response.response.clientDataJSON | Should -Be 'encoded'
                $Dto.response.response.transports -join ',' | Should -Be 'usb,nfc'
            }
        }
    }

    Describe 'InvokeImmichRestMethod query and output handling' -Tag 'Unit', 'ImmichApiLayer' {
        BeforeAll {
            Mock -CommandName Invoke-RestMethod -MockWith {}
            $Session = [ImmichSession]::New('https://immich.domain.com', 'AccessToken', (ConvertTo-SecureString -String 'accesstoken' -AsPlainText -Force), $true, (New-Object -TypeName pscredential -ArgumentList 'username', (ConvertTo-SecureString -String 'password' -AsPlainText -Force)), (ConvertTo-SecureString -String 'jwt' -AsPlainText -Force), '1.1.1', (New-Guid).Guid)
        }
        It 'Should send array query values as bracketed keys' {
            InvokeImmichRestMethod -Method get -ImmichSession:$Session -RelativePath '/auth/login' -QueryParameters:@{ status = @('active', 'failed') }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -match 'status\[\]=active&status\[\]=failed$'
            }
        }
        It 'Should send a single array query value with a bracketed key' {
            InvokeImmichRestMethod -Method get -ImmichSession:$Session -RelativePath '/auth/login' -QueryParameters:@{ status = @('waiting') }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -match 'status\[\]=waiting$'
            }
        }
        It 'encodes scalar keys and values without allowing extra parameters or fragments' {
            InvokeImmichRestMethod -Method get -ImmichSession $Session -RelativePath '/auth/login' -QueryParameters @{
                'name&key' = 'a&admin=true#fragment +/%'
            }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://immich.domain.com/api/auth/login?name%26key=a%26admin%3Dtrue%23fragment%20%2B%2F%25'
            }
        }
        It 'encodes every array value while preserving bracketed array keys' {
            InvokeImmichRestMethod -Method get -ImmichSession $Session -RelativePath '/auth/login' -QueryParameters @{
                'tag&name' = @('a&b=c', 'x#y +%')
            }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://immich.domain.com/api/auth/login?tag%26name[]=a%26b%3Dc&tag%26name[]=x%23y%20%2B%25'
            }
        }
        It 'preserves empty strings and lowercase boolean query values' {
            InvokeImmichRestMethod -Method get -ImmichSession $Session -RelativePath '/auth/login' -QueryParameters @{
                empty = ''; enabled = $false; switched = [switch]$true
            }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -match '[?&]empty=(&|$)' -and $Uri -match '[?&]enabled=false(&|$)' -and
                $Uri -match '[?&]switched=true(&|$)'
            }
        }
        It 'does not expose headers, bodies, query secrets or raw JSON in debug messages' {
            $DebugOutput = InvokeImmichRestMethod -Method post -ImmichSession $Session -RelativePath '/auth/login' -NoAuth `
                -Headers @{ Authorization = 'synthetic-bearer-secret' } -Body @{ password = 'synthetic-password' } `
                -RawBody '{"password":"synthetic-raw-secret"}' -QueryParameters @{ key = 'synthetic-query-secret' } -Debug 5>&1
            ($DebugOutput | Out-String) | Should -Not -Match 'synthetic-|password|Authorization'
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Headers.Authorization -eq 'synthetic-bearer-secret' -and
                $Body -eq '{"password":"synthetic-raw-secret"}' -and $Uri -match 'key=synthetic-query-secret'
            }
        }
        It 'does not expose the decrypted API key in debug messages' {
            $DebugOutput = InvokeImmichRestMethod -Method get -ImmichSession $Session -RelativePath '/auth/login' -Debug 5>&1
            ($DebugOutput | Out-String) | Should -Not -Match 'accesstoken|X-API-Key'
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Headers.'X-API-Key' -eq 'accesstoken'
            }
        }
        It 'does not expose a credential JWT or login password in debug messages' {
            $CredentialSession = [ImmichSession]::New('https://immich.domain.com', 'Credential', $null, $true, $null, (ConvertTo-SecureString 'synthetic-jwt' -AsPlainText -Force), '3.4.0', (New-Guid).Guid)
            $DebugOutput = InvokeImmichRestMethod -Method post -ImmichSession $CredentialSession -RelativePath '/auth/login' `
                -Body @{ password = 'synthetic-password' } -Debug 5>&1
            ($DebugOutput | Out-String) | Should -Not -Match 'synthetic-|password|Authorization'
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Headers.Authorization -eq 'Bearer synthetic-jwt' -and
                ($Body | ConvertFrom-Json).password -eq 'synthetic-password'
            }
        }
        It 'formats numeric query values independently of the current culture' {
            $OriginalCulture = [Threading.Thread]::CurrentThread.CurrentCulture
            try
            {
                [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('sv-SE')
                InvokeImmichRestMethod -Method get -ImmichSession $Session -RelativePath '/auth/login' -QueryParameters @{ value = 1.5 }
            }
            finally
            {
                [Threading.Thread]::CurrentThread.CurrentCulture = $OriginalCulture
            }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://immich.domain.com/api/auth/login?value=1.5'
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
