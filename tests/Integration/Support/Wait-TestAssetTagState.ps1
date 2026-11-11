function Wait-TestAssetTagState
{
    param(
        [Parameter(Mandatory)][string]$AssetId,
        [Parameter(Mandatory)][string]$TagId,
        [Parameter(Mandatory)][bool]$Present,
        [ValidateRange(0, 60)][int]$TimeoutSeconds = 10,
        [ValidateRange(1, 10000)][int]$IntervalMilliseconds = 1000
    )

    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    do
    {
        $Asset = Get-IMAsset -Id $AssetId -ErrorAction Stop
        $TagIds = @($Asset.tags | ForEach-Object { $_.id })
        if (($TagIds -contains $TagId) -eq $Present)
        {
            return
        }
        if ($Timer.Elapsed.TotalSeconds -ge $TimeoutSeconds)
        {
            break
        }
        $Remaining = [int][Math]::Ceiling(($TimeoutSeconds - $Timer.Elapsed.TotalSeconds) * 1000)
        Start-Sleep -Milliseconds ([Math]::Min($IntervalMilliseconds, $Remaining))
    } while ($true)

    $Expected = if ($Present) { 'present' } else { 'absent' }
    throw "Timed out waiting for tag '$TagId' to be $Expected on asset '$AssetId' after $TimeoutSeconds seconds. Observed tags: $($TagIds -join ', ')."
}
