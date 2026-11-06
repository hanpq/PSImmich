BeforeAll {
    $scriptUnderTest = Join-Path $PSScriptRoot '..\..\scripts\Assert-ReleasePullRequest.ps1'
}

Describe 'Merged release PR validation' {
    BeforeAll {
        $savedToken = $env:GH_TOKEN
        $savedApi = $env:GITHUB_API_URL
        $env:GH_TOKEN = 'test-token'
        $env:GITHUB_API_URL = 'https://api.github.test'
    }

    AfterAll {
        $env:GH_TOKEN = $savedToken
        $env:GITHUB_API_URL = $savedApi
    }

    BeforeEach {
        $apiState = @{
            Version = '2.0.0-beta001'
            MergeVersion = '2.0.0-beta001'
            Pending = @()
            Other = @{ merged_at = $null; base = @{ ref = 'main' } }
            BaseVersion = '2.0.0-beta001'
            BetaCommit = 'beta-sha'
            BetaRelease = @{ tag_name = 'v2.0.0-beta001'; draft = $false; prerelease = $true; published_at = '2026-10-29T12:00:00Z' }
            Files = @(
                @{ filename = '.release-please-manifest.json'; status = 'modified' }
                @{ filename = 'version.txt'; status = 'modified' }
                @{ filename = 'CHANGELOG.md'; status = 'modified' }
            )
            Pr = @{
                user = @{ login = 'release-bot' }
                state = 'closed'
                merged_at = '2026-10-30T12:00:00Z'
                merge_commit_sha = 'merged-sha'
                head = @{ ref = 'release-please--branches--main'; sha = 'head-sha'; repo = @{ full_name = 'example/module' } }
                base = @{ ref = 'main'; repo = @{ full_name = 'example/module' } }
                title = 'chore(main): release 2.0.0-beta001'
                body = ":robot: I have created a release *beep* *boop*`n---`n## [2.0.0-beta001]`n---`nThis PR was generated with [Release Please]"
                labels = @(@{ name = 'autorelease: pending' })
                changed_files = 3
            }
        }
        Mock Invoke-RestMethod {
            param($Uri, $Method)
            if ($Method) { throw 'Finalization validation must be read-only.' }
            switch -Wildcard ($Uri)
            {
                '*/user' { return @{ login = 'release-bot' } }
                '*/pulls/42' { return $apiState.Pr }
                '*/pulls/43' { return $apiState.Other }
                # The real cmdlet returns JSON arrays as a single object.
                '*/pulls/42/files?*' { return , $apiState.Files }
                '*/issues?*' { return , $apiState.Pending }
                '*/git/commits/merged-sha' { return @{ parents = @(@{ sha = 'beta-sha' }) } }
                '*/commits/v2.0.0-beta001' { return @{ sha = $apiState.BetaCommit } }
                '*/releases/tags/v2.0.0-beta001' { return $apiState.BetaRelease }
                '*/contents/.release-please-manifest.json?*' {
                    $version = if ($Uri -like '*ref=merged-sha') { $apiState.MergeVersion }
                        elseif ($Uri -like '*ref=beta-sha') { $apiState.BaseVersion }
                        else { $apiState.Version }
                    return @{
                        encoding = 'base64'
                        content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((@{ '.' = $version } | ConvertTo-Json)))
                    }
                }
                default { throw "Unexpected API URI: $Uri" }
            }
        }
    }

    It 'finalizes a verified beta as beta' {
        & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha |
            Should -BeExactly beta
    }

    It 'finalizes a verified stable promotion with stable configuration' {
        $apiState.Version = $apiState.MergeVersion = '2.0.0'
        $apiState.Pr.title = 'chore(main): release 2.0.0'
        $apiState.Pr.body = $apiState.Pr.body.Replace('2.0.0-beta001', '2.0.0')
        $apiState.Pr.labels += @{ name = 'stable-promotion' }
        & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha |
            Should -BeExactly stable
    }

    It 'rejects an untrusted author, fork, branch, base, unmerged PR or changed event SHA' -ForEach @(
        @{ Field = 'author' }, @{ Field = 'fork' }, @{ Field = 'branch' }, @{ Field = 'base' }
        @{ Field = 'merged' }, @{ Field = 'sha' }, @{ Field = 'pending' }, @{ Field = 'bot-body' }
    ) {
        switch ($Field)
        {
            author { $apiState.Pr.user.login = 'someone-else' }
            fork { $apiState.Pr.head.repo.full_name = 'someone/fork' }
            branch { $apiState.Pr.head.ref = 'feature' }
            base { $apiState.Pr.base.ref = 'feature' }
            merged { $apiState.Pr.merged_at = $null }
            sha { $apiState.Pr.merge_commit_sha = 'another-sha' }
            pending { $apiState.Pr.labels = @() }
            bot-body { $apiState.Pr.body = 'Ordinary PR' }
        }
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*Expected a merged*'
    }

    It 'rejects PR code or config changes before selecting an action configuration' {
        $apiState.Files[2].filename = 'scripts/Assert-ReleasePullRequest.ps1'
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*may change only*'
    }

    It 'rejects extra changed files even if the response is truncated' {
        $apiState.Pr.changed_files = 101
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*may change only*'
    }

    It 'rejects changed merge metadata, a title mismatch or unsupported version' -ForEach @(
        @{ Field = 'merge' }, @{ Field = 'title' }, @{ Field = 'version' }, @{ Field = 'body' }
    ) {
        switch ($Field)
        {
            merge { $apiState.MergeVersion = '2.0.0' }
            title { $apiState.Pr.title = 'chore(main): release 2.0.0' }
            version { $apiState.Version = $apiState.MergeVersion = '2.0.0-rc001' }
            body { $apiState.Pr.body = $apiState.Pr.body.Replace('## [2.0.0-beta001]', '## [2.0.0]') }
        }
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*immutable head/merge manifests must agree*'
    }

    It 'never changes a beta into stable just because a label was added' {
        $apiState.Pr.labels += @{ name = 'stable-promotion' }
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*label must agree*'
    }

    It 'never changes stable into beta just because its label was removed' {
        $apiState.Version = $apiState.MergeVersion = '2.0.0'
        $apiState.Pr.title = 'chore(main): release 2.0.0'
        $apiState.Pr.body = $apiState.Pr.body.Replace('2.0.0-beta001', '2.0.0')
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*label must agree*'
    }

    It 'refuses a stable merge if main advanced after preparation or the beta is unpublished' -ForEach @(
        @{ Field = 'main-advanced' }, @{ Field = 'other-version' }, @{ Field = 'draft' }
    ) {
        $apiState.Version = $apiState.MergeVersion = '2.0.0'
        $apiState.Pr.title = 'chore(main): release 2.0.0'
        $apiState.Pr.body = $apiState.Pr.body.Replace('2.0.0-beta001', '2.0.0')
        $apiState.Pr.labels += @{ name = 'stable-promotion' }
        switch ($Field)
        {
            main-advanced { $apiState.BetaCommit = 'older-beta-sha' }
            other-version { $apiState.BaseVersion = '2.1.0-beta001' }
            draft { $apiState.BetaRelease.draft = $true }
        }
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*published beta*'
    }

    It 'refuses a second merged pending release rather than publishing it with the wrong config' {
        $apiState.Pending = @(@{ number = 43; pull_request = @{ url = 'other' } })
        $apiState.Other.merged_at = '2026-10-29T12:00:00Z'
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*Another merged release PR #43*'
    }

    It 'ignores closed unmerged pending PRs' {
        $apiState.Pending = @(@{ number = 43; pull_request = @{ url = 'other' } })
        & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha |
            Should -BeExactly beta
    }

    It 'fails closed on API errors' {
        Mock Invoke-RestMethod { throw 'API unavailable' }
        { & $scriptUnderTest -Repository 'example/module' -PullRequestNumber 42 -MergeSha merged-sha } |
            Should -Throw '*API unavailable*'
    }
}
