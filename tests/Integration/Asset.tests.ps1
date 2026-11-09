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

Describe 'Asset' -Tag 'Integration' {
    # Intentionally excluded from live testing:
    # Import-IMAsset, Remove-IMAsset and Restore-IMAsset only act on assets uploaded by the test itself. Each test
    # permanently deletes what it imports, so the shared server is left as it was found.
    # Start-IMVideoTranscode: queues a transcode job on shared assets with no way to revert it.
    # Update-IMAssetThumbnail: regenerates thumbnails on shared assets with no way to revert it.

    BeforeAll {
        Connect-Immich -BaseURL $env:PSIMMICHURI -AccessToken $env:PSIMMICHAPIKEY

        $SourceAssetId = '025665c6-d874-46a2-bbc6-37250ddcb2eb'
        $SecondAssetId = '0d34e23c-8a4e-40a2-9c70-644eea8a9037'
        $TargetAssetId = '0dcc5ecc-7033-4e42-b24e-1bfeac7bc84d'
        $OcrAssetId = '02e1a2f4-b88b-4eb1-9ec5-34accfb3155a'
        $MissingAssetId = '00000000-0000-4000-8000-000000000000'
        $RunTag = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { Get-Date -Format 'yyyyMMddHHmmss' }

        function Get-TestAssetMetadata
        {
            param([string]$AssetId)
            & (Get-Module PSImmich) { param($Id) Invoke-ImmichApiGetAssetMetadata -Id $Id } $AssetId
        }

        # Each call writes a uniquely named copy of the test image with a unique trailing marker,
        # so the server never treats it as a duplicate of an earlier upload.
        function New-TestImportFile
        {
            $Path = Join-Path ([System.IO.Path]::GetTempPath()) "psimtest-$([guid]::NewGuid().ToString('N')).png"
            $Image = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Immich.png'))
            $Marker = [System.Text.Encoding]::ASCII.GetBytes("psimtest:$([guid]::NewGuid().ToString('N'))")
            [System.IO.File]::WriteAllBytes($Path, [byte[]]($Image + $Marker))
            $script:TempImportFiles.Add($Path)
            Get-Item -LiteralPath $Path
        }

        $script:TempImportFiles = [System.Collections.Generic.List[string]]::new()
        $script:ImportedAssetIds = [System.Collections.Generic.List[string]]::new()
    }

    AfterAll {
        foreach ($Id in $script:ImportedAssetIds)
        {
            try { Remove-IMAsset -Ids $Id -Force -Confirm:$false } catch { $null = $_ }
        }
        foreach ($Path in $script:TempImportFiles)
        {
            Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-IMAsset' -Tag 'Get-IMAsset' {
        It 'Should return an object with the expected properties for a single ID' {
            $Result = Get-IMAsset -Id $SourceAssetId
            $ExpectedProperties = @('duplicateId', 'hasMetadata', 'isOffline', 'checksum', 'people', 'tags', 'livePhotoVideoId', 'exifInfo', 'duration', 'isTrashed', 'isArchived', 'isFavorite', 'updatedAt', 'localDateTime', 'fileModifiedAt', 'fileCreatedAt', 'thumbhash', 'resized', 'id', 'ownerId', 'owner', 'libraryId', 'type', 'originalPath', 'originalFileName', 'originalMimeType', 'stack', 'createdAt', 'visibility', 'width', 'height', 'isEdited')
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject $Result.PSObject.Properties.Name | Select-Object -ExpandProperty InputObject | Should -BeNullOrEmpty
        }

        It 'Should return a single object for a single ID' {
            Get-IMAsset -Id $SourceAssetId | Should -HaveCount 1
        }

        It 'Should return the requested ID' {
            (Get-IMAsset -Id $SourceAssetId).id | Should -Be $SourceAssetId
        }

        It 'Should return OCR data when IncludeOCR is specified' {
            $Result = Get-IMAsset -Id $OcrAssetId -IncludeOCR
            $Result.PSObject.Properties.Name | Should -Contain 'OCR'
            $Result.OCR | Should -HaveCount 6
        }

        It 'Should not return OCR data by default' {
            $Result = Get-IMAsset -Id $OcrAssetId
            $Result.PSObject.Properties.Name | Should -Not -Contain 'OCR'
        }

        It 'Should accept an object with an id property from the pipeline' {
            [pscustomobject]@{ id = $SourceAssetId } | Get-IMAsset | Should -HaveCount 1
        }

        It 'Should accept an ID string from the pipeline' {
            $SourceAssetId | Get-IMAsset | Should -HaveCount 1
        }

        It 'Should return one object per ID for multiple IDs from the pipeline' {
            @($SourceAssetId, $SecondAssetId) | Get-IMAsset | Should -HaveCount 2
        }

        It 'Should return multiple objects for multiple piped objects' {
            @([pscustomobject]@{ id = $SourceAssetId }, [pscustomobject]@{ id = $SecondAssetId }) | Get-IMAsset | Should -HaveCount 2
        }

        It 'Should return an array when no parameters are specified' {
            Get-IMAsset | Measure-Object | Select-Object -ExpandProperty Count | Should -BeGreaterThan 1
        }

        It 'Should return one random asset by default' {
            Get-IMAsset -Random | Should -HaveCount 1
        }

        It 'Should return the requested number of random assets' {
            Get-IMAsset -Random -Count 3 | Should -HaveCount 3
        }

        It 'Should return assets for a person ID' {
            $Person = Get-IMPerson | Select-Object -First 1
            if (-not $Person)
            {
                Set-ItResult -Skipped -Because 'No people exist on the server'
                return
            }
            $Result = Get-IMAsset -PersonId $Person.id
            $Result | ForEach-Object { $PSItem.people.id | Should -Contain $Person.id }
        }

        It 'Should return assets for a tag ID' {
            $Tag = Get-IMTag | Select-Object -First 1
            if (-not $Tag)
            {
                Set-ItResult -Skipped -Because 'No tags exist on the server'
                return
            }
            $Result = Get-IMAsset -TagId $Tag.id
            $Result | ForEach-Object { $PSItem.tags.id | Should -Contain $Tag.id }
        }

        It 'Should throw for a non-existent ID' {
            { Get-IMAsset -Id $MissingAssetId } | Should -Throw
        }
    }

    Context 'Set-IMAsset' -Tag 'Set-IMAsset' {
        BeforeAll {
            $AlbumName = "PSImmich-Asset-Test-$RunTag"
            $TestAlbum = New-IMAlbum -AlbumName $AlbumName -Description 'Set-IMAsset integration test'
            $TestTag = New-IMTag -Name "PSImmich-Asset-Test-$RunTag"
            $OriginalAsset = Get-IMAsset -Id $SourceAssetId
            $OriginalIsFavorite = [bool]$OriginalAsset.isFavorite
        }

        AfterAll {
            Set-IMAsset -Id $SourceAssetId -IsFavorite:$OriginalIsFavorite -ErrorAction SilentlyContinue
            Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
            Set-IMAsset -Id $SecondAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
            Remove-IMAlbum -AlbumId $TestAlbum.id -Confirm:$false -ErrorAction SilentlyContinue
            Remove-IMTag -Id $TestTag.id -Confirm:$false -ErrorAction SilentlyContinue
        }

        It 'Should add assets to an album' {
            Set-IMAsset -Id $SourceAssetId, $SecondAssetId -AddToAlbum $TestAlbum.id
            $Result = Get-IMAlbum -AlbumId $TestAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 2
            $Result.assets.id | Should -Contain $SourceAssetId
            $Result.assets.id | Should -Contain $SecondAssetId
        }

        It 'Should remove assets from an album' {
            Set-IMAsset -Id $SourceAssetId, $SecondAssetId -RemoveFromAlbum $TestAlbum.id
            $Result = Get-IMAlbum -AlbumId $TestAlbum.id -IncludeAssets
            $Result.assets | Should -HaveCount 0
        }

        It 'Should set and clear the favorite flag' {
            Set-IMAsset -Id $SourceAssetId -IsFavorite:$true
            (Get-IMAsset -Id $SourceAssetId).isFavorite | Should -BeTrue
            Set-IMAsset -Id $SourceAssetId -IsFavorite:$false
            (Get-IMAsset -Id $SourceAssetId).isFavorite | Should -BeFalse
        }

        It 'Should add and remove a tag' {
            Set-IMAsset -Id $SourceAssetId -AddTag $TestTag.id | Out-Null
            $Retry = 0
            while ((Get-IMAsset -Id $SourceAssetId).tags.id -notcontains $TestTag.id -and $Retry -lt 5)
            {
                Start-Sleep -Seconds 2
                $Retry++
            }
            (Get-IMAsset -Id $SourceAssetId).tags.id | Should -Contain $TestTag.id

            Set-IMAsset -Id $SourceAssetId -RemoveTag $TestTag.id | Out-Null
            $Retry = 0
            while ((Get-IMAsset -Id $SourceAssetId).tags.id -contains $TestTag.id -and $Retry -lt 5)
            {
                Start-Sleep -Seconds 2
                $Retry++
            }
            (Get-IMAsset -Id $SourceAssetId).tags.id | Should -Not -Contain $TestTag.id
        }

        It 'Should accept asset IDs from the pipeline' {
            $SourceAssetId | Set-IMAsset -AddToAlbum $TestAlbum.id
            (Get-IMAlbum -AlbumId $TestAlbum.id -IncludeAssets).assets.id | Should -Contain $SourceAssetId
            $SourceAssetId | Set-IMAsset -RemoveFromAlbum $TestAlbum.id
        }

        It 'Should throw when the album ID does not exist' {
            { Set-IMAsset -Id $SourceAssetId -AddToAlbum '00000000-0000-4000-8000-000000000000' } | Should -Throw
        }
    }

    Context 'Copy-IMAssetInfo' -Tag 'Copy-IMAssetInfo' {
        BeforeAll {
            $AlbumName = "PSImmich-Copy-Asset-Info-$RunTag"
            $TestAlbum = New-IMAlbum -AlbumName $AlbumName -Description 'Copy-IMAssetInfo integration test'
        }

        AfterAll {
            Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
            Set-IMAsset -Id $TargetAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
            Remove-IMAlbum -AlbumId $TestAlbum.id -Confirm:$false -ErrorAction SilentlyContinue
        }

        It 'Should copy album associations from the source to the target asset with -Albums' {
            try
            {
                Set-IMAsset -Id $SourceAssetId -AddToAlbum $TestAlbum.id
                $Before = (Get-IMAlbum -AlbumId $TestAlbum.id -IncludeAssets).assets.id
                $Before | Should -Contain $SourceAssetId
                $Before | Should -Not -Contain $TargetAssetId

                Copy-IMAssetInfo -SourceId $SourceAssetId -TargetId $TargetAssetId -Albums

                $After = (Get-IMAlbum -AlbumId $TestAlbum.id -IncludeAssets).assets.id
                $After | Should -Contain $TargetAssetId
            }
            finally
            {
                Set-IMAsset -Id $TargetAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
                Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
            }
        }

        It 'Should not copy albums when only metadata is requested' {
            try
            {
                Set-IMAsset -Id $SourceAssetId -AddToAlbum $TestAlbum.id
                Copy-IMAssetInfo -SourceId $SourceAssetId -TargetId $TargetAssetId -Metadata

                (Get-IMAlbum -AlbumId $TestAlbum.id -IncludeAssets).assets.id | Should -Not -Contain $TargetAssetId
            }
            finally
            {
                Set-IMAsset -Id $SourceAssetId -RemoveFromAlbum $TestAlbum.id -ErrorAction SilentlyContinue
            }
        }

        It 'Should throw for a non-existent target ID' {
            { Copy-IMAssetInfo -SourceId $SourceAssetId -TargetId $MissingAssetId -Albums } | Should -Throw
        }
    }

    Context 'Export-IMAssetThumbnail' -Tag 'Export-IMAssetThumbnail' {
        It 'Should save a thumbnail to the given folder' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'thumbs-single') -Force
            Export-IMAssetThumbnail -Id $SourceAssetId -Path $OutputFolder.FullName
            Join-Path $OutputFolder.FullName "$SourceAssetId.jpeg" | Should -Exist
        }

        It 'Should save thumbnails for multiple IDs from the pipeline' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'thumbs-pipeline') -Force
            @($SourceAssetId, $SecondAssetId) | Export-IMAssetThumbnail -Path $OutputFolder.FullName
            Join-Path $OutputFolder.FullName "$SourceAssetId.jpeg" | Should -Exist
            Join-Path $OutputFolder.FullName "$SecondAssetId.jpeg" | Should -Exist
        }

        It 'Should throw for a non-existent ID' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'thumbs-missing') -Force
            { Export-IMAssetThumbnail -Id $MissingAssetId -Path $OutputFolder.FullName } | Should -Throw
        }
    }

    Context 'Get-IMAssetEdit' -Tag 'Get-IMAssetEdit' {
        It 'Should return the edit collection for an asset' {
            $Result = Get-IMAssetEdit -Id $SourceAssetId
            $Result.PSObject.Properties.Name | Should -Contain 'edits'
            $Result.assetId | Should -Be $SourceAssetId
        }

        It 'Should accept an asset ID from the pipeline' {
            $SourceAssetId | Get-IMAssetEdit | Should -HaveCount 1
        }

        It 'Should throw for a non-existent asset ID' {
            { Get-IMAssetEdit -Id $MissingAssetId } | Should -Throw
        }
    }

    Context 'Set-IMAssetEdit' -Tag 'Set-IMAssetEdit' {
        It 'Should set an edit on an asset with no edits and remove it afterwards' {
            $Existing = Get-IMAssetEdit -Id $SourceAssetId
            if ($Existing.edits.Count -gt 0)
            {
                Set-ItResult -Skipped -Because 'Source asset already has edits'
                return
            }
            try
            {
                $Result = Set-IMAssetEdit -Id $SourceAssetId -Edit @(@{ action = 'mirror'; parameters = @{ axis = 'horizontal' } })
                $Result.edits | Should -HaveCount 1
                $Result.edits[0].action | Should -Be 'mirror'
            }
            finally
            {
                Remove-IMAssetEdit -Id $SourceAssetId -ErrorAction SilentlyContinue
            }
        }

        It 'Should throw when Edit is empty' {
            { Set-IMAssetEdit -Id $SourceAssetId -Edit @() } | Should -Throw
        }
    }

    Context 'Remove-IMAssetEdit' -Tag 'Remove-IMAssetEdit' {
        It 'Should remove edits from an asset that had none at start' {
            $Existing = Get-IMAssetEdit -Id $SourceAssetId
            if ($Existing.edits.Count -gt 0)
            {
                Set-ItResult -Skipped -Because 'Source asset already has edits'
                return
            }
            try
            {
                Set-IMAssetEdit -Id $SourceAssetId -Edit @(@{ action = 'mirror'; parameters = @{ axis = 'vertical' } }) | Out-Null
            }
            finally
            {
                Remove-IMAssetEdit -Id $SourceAssetId
            }
            (Get-IMAssetEdit -Id $SourceAssetId).edits | Should -HaveCount 0
        }

        It 'Should throw for a non-existent asset ID' {
            { Remove-IMAssetEdit -Id $MissingAssetId } | Should -Throw
        }
    }

    Context 'Get-IMAssetFile' -Tag 'Get-IMAssetFile' {
        It 'Should return asset files for an asset ID' {
            $Result = Get-IMAssetFile -AssetId $SourceAssetId
            $Result | ForEach-Object { $PSItem.PSObject.Properties.Name | Should -Contain 'path' }
        }

        It 'Should filter asset files by type' {
            $Result = Get-IMAssetFile -AssetId $SourceAssetId -Type thumbnail
            $Result | ForEach-Object { $PSItem.type | Should -Be 'thumbnail' }
        }

        It 'Should return a file for a file ID from the pipeline' {
            $FirstFile = Get-IMAssetFile -AssetId $SourceAssetId | Select-Object -First 1
            if (-not $FirstFile)
            {
                Set-ItResult -Skipped -Because 'Source asset has no asset files'
                return
            }
            $FirstFile | Get-IMAssetFile | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-IMAssetFolder' -Tag 'Get-IMAssetFolder' {
        It 'Should return unique original folder paths' {
            $Result = Get-IMAssetFolder
            $Result | Should -Not -BeNullOrEmpty
        }

        It 'Should return assets for a folder path' {
            $Folder = Get-IMAssetFolder | Select-Object -First 1
            if (-not $Folder)
            {
                Set-ItResult -Skipped -Because 'No folders exist on the server'
                return
            }
            Get-IMAssetFolder -Path $Folder | Should -Not -BeNullOrEmpty
        }

        It 'Should throw when Path is empty' {
            { Get-IMAssetFolder -Path '' } | Should -Throw
        }
    }

    Context 'Get-IMAssetStatistic' -Tag 'Get-IMAssetStatistic' {
        It 'Should return one object with image, video and total counts' {
            $Result = Get-IMAssetStatistic
            $Result | Should -HaveCount 1
            $Result.PSObject.Properties.Name | Should -Contain 'images'
            $Result.PSObject.Properties.Name | Should -Contain 'videos'
            $Result.PSObject.Properties.Name | Should -Contain 'total'
        }

        It 'Should return statistics filtered by favorite' {
            $Result = Get-IMAssetStatistic -IsFavorite $true
            $Result | Should -HaveCount 1
            $Result.total | Should -BeGreaterOrEqual 0
        }

        It 'Should return statistics filtered by trashed state' {
            $Result = Get-IMAssetStatistic -IsTrashed $false
            $Result | Should -HaveCount 1
            $Result.total | Should -BeGreaterOrEqual 0
        }
    }

    Context 'Set-IMAssetMetadata' -Tag 'Set-IMAssetMetadata' {
        BeforeAll {
            $MetadataKey = 'mobile-app'
            $OriginalMetadata = Get-TestAssetMetadata -AssetId $SourceAssetId
            $OriginalEntry = $OriginalMetadata | Where-Object key -EQ $MetadataKey
        }

        AfterAll {
            if ($OriginalEntry)
            {
                Set-IMAssetMetadata -Id $SourceAssetId -Key $MetadataKey -Value $OriginalEntry.value -ErrorAction SilentlyContinue | Out-Null
            }
            else
            {
                Remove-IMAssetMetadata -Id $SourceAssetId -Key $MetadataKey -ErrorAction SilentlyContinue | Out-Null
            }
        }

        It 'Should set a metadata entry on an asset' {
            $Value = @{ note = "PSImmich-Asset-Test-$RunTag" }
            Set-IMAssetMetadata -Id $SourceAssetId -Key $MetadataKey -Value $Value | Out-Null
            $Entry = Get-TestAssetMetadata -AssetId $SourceAssetId | Where-Object key -EQ $MetadataKey
            $Entry.value.note | Should -Be "PSImmich-Asset-Test-$RunTag"
        }

        It 'Should accept an asset ID from the pipeline' {
            $SourceAssetId | Set-IMAssetMetadata -Key $MetadataKey -Value @{ note = "PSImmich-Asset-Pipeline-$RunTag" } | Out-Null
            $Entry = Get-TestAssetMetadata -AssetId $SourceAssetId | Where-Object key -EQ $MetadataKey
            $Entry.value.note | Should -Be "PSImmich-Asset-Pipeline-$RunTag"
        }
    }

    Context 'Remove-IMAssetMetadata' -Tag 'Remove-IMAssetMetadata' {
        BeforeAll {
            $MetadataKey = 'mobile-app'
            $OriginalEntry = Get-TestAssetMetadata -AssetId $SourceAssetId | Where-Object key -EQ $MetadataKey
        }

        AfterAll {
            if ($OriginalEntry)
            {
                Set-IMAssetMetadata -Id $SourceAssetId -Key $MetadataKey -Value $OriginalEntry.value -ErrorAction SilentlyContinue | Out-Null
            }
        }

        It 'Should remove a metadata entry from an asset' {
            Set-IMAssetMetadata -Id $SourceAssetId -Key $MetadataKey -Value @{ note = "PSImmich-Asset-Remove-$RunTag" } | Out-Null
            Remove-IMAssetMetadata -Id $SourceAssetId -Key $MetadataKey | Out-Null
            Get-TestAssetMetadata -AssetId $SourceAssetId | Where-Object key -EQ $MetadataKey | Should -BeNullOrEmpty
        }
    }

    Context 'Save-IMAsset' -Tag 'Save-IMAsset' {
        It 'Should download the original file to the given folder' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'save-asset') -Force
            $OriginalFileName = (Get-IMAsset -Id $SourceAssetId).originalFileName
            Save-IMAsset -Id $SourceAssetId -Path $OutputFolder.FullName
            Join-Path $OutputFolder.FullName $OriginalFileName | Should -Exist
        }

        It 'Should accept an asset ID from the pipeline' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'save-asset-pipeline') -Force
            $OriginalFileName = (Get-IMAsset -Id $SecondAssetId).originalFileName
            $SecondAssetId | Save-IMAsset -Path $OutputFolder.FullName
            Join-Path $OutputFolder.FullName $OriginalFileName | Should -Exist
        }

        It 'Should throw for a non-existent ID' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'save-asset-missing') -Force
            { Save-IMAsset -Id $MissingAssetId -Path $OutputFolder.FullName } | Should -Throw
        }
    }

    Context 'Save-IMAssetFile' -Tag 'Save-IMAssetFile' {
        It 'Should download an asset file to the given folder' {
            $OutputFolder = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'save-asset-file') -Force
            $AssetFile = Get-IMAssetFile -AssetId $SourceAssetId | Select-Object -First 1
            if (-not $AssetFile)
            {
                Set-ItResult -Skipped -Because 'Source asset has no asset files'
                return
            }
            Save-IMAssetFile -Id $AssetFile.id -Path $OutputFolder
            (Get-ChildItem -LiteralPath $OutputFolder.FullName -File | Measure-Object).Count | Should -BeGreaterOrEqual 1
        }
    }

    Context 'Update-IMAssetMetadata' -Tag 'Update-IMAssetMetadata' {
        It 'Should not throw for a valid asset' {
            { Update-IMAssetMetadata -Id $SourceAssetId } | Should -Not -Throw
        }
    }

    Context 'Import-IMAsset' -Tag 'Import-IMAsset' {
        It 'Should upload a file and return the created asset' {
            $File = New-TestImportFile
            $Asset = Import-IMAsset -FilePath $File.FullName
            $script:ImportedAssetIds.Add($Asset.id)
            $Asset.id | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
            $Asset.originalFileName | Should -Be $File.Name
            $Asset.type | Should -Be 'IMAGE'
        }

        It 'Should upload a file piped as a FileInfo object' {
            $File = New-TestImportFile
            $Asset = $File | Import-IMAsset
            $script:ImportedAssetIds.Add($Asset.id)
            $Asset | Should -HaveCount 1
            $Asset.originalFileName | Should -Be $File.Name
        }

        It 'Should mark the imported asset as a favorite when IsFavorite is specified' {
            $File = New-TestImportFile
            $Asset = Import-IMAsset -FilePath $File.FullName -isFavorite
            $script:ImportedAssetIds.Add($Asset.id)
            (Get-IMAsset -Id $Asset.id).isFavorite | Should -BeTrue
        }

        It 'Should throw for a file that does not exist' {
            { Import-IMAsset -FilePath (Join-Path $TestDrive 'missing-file.png') } | Should -Throw
        }
    }

    Context 'Remove-IMAsset' -Tag 'Remove-IMAsset' {
        It 'Should permanently delete an asset when Force is specified' {
            $File = New-TestImportFile
            $Asset = Import-IMAsset -FilePath $File.FullName
            Remove-IMAsset -Ids $Asset.id -Force -Confirm:$false
            { Get-IMAsset -Id $Asset.id } | Should -Throw
        }

        It 'Should move an asset to trash when Force is not specified' {
            $File = New-TestImportFile
            $Asset = Import-IMAsset -FilePath $File.FullName
            $script:ImportedAssetIds.Add($Asset.id)
            Remove-IMAsset -Ids $Asset.id -Confirm:$false
            (Get-IMAsset -Id $Asset.id).isTrashed | Should -BeTrue
        }

        It 'Should remove an asset piped by property name' {
            $File = New-TestImportFile
            $Asset = Import-IMAsset -FilePath $File.FullName
            [pscustomobject]@{ id = $Asset.id } | Remove-IMAsset -Force -Confirm:$false
            { Get-IMAsset -Id $Asset.id } | Should -Throw
        }

        It 'Should throw for a malformed asset ID' {
            { Remove-IMAsset -Ids 'not-a-guid' -Force -Confirm:$false } | Should -Throw
        }
    }

    Context 'Restore-IMAsset' -Tag 'Restore-IMAsset' {
        It 'Should restore an asset that was moved to trash' {
            $File = New-TestImportFile
            $Asset = Import-IMAsset -FilePath $File.FullName
            $script:ImportedAssetIds.Add($Asset.id)
            Remove-IMAsset -Ids $Asset.id -Confirm:$false
            Restore-IMAsset -Id $Asset.id -Confirm:$false
            (Get-IMAsset -Id $Asset.id).isTrashed | Should -BeFalse
        }
    }
}
