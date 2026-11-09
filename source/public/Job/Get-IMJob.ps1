function Get-IMJob
{
    <#
    .SYNOPSIS
        Retrieves Immich background job information
    .DESCRIPTION
        Retrieves information about all background job queues in Immich, including their paused state and
        job statistics. This helps monitor system processing and job performance.

        Uses the queues API (GET /queues). Each queue is returned with its name, isPaused flag and a
        statistics object, replacing the deprecated jobs API shape that exposed jobCounts.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMJob

        Retrieves information about all background job queues.
    .EXAMPLE
        $jobs = Get-IMJob
        $jobs | Where-Object {$_.statistics.active -gt 0}

        Gets job queues that are currently active.
    .EXAMPLE
        Get-IMJob | Format-Table name, isPaused, @{Name='Active';Expression={$_.statistics.active}}, @{Name='Waiting';Expression={$_.statistics.waiting}}

        Displays queue information in a formatted table showing active and waiting job counts.
    .NOTES
        Queue information includes the paused state, active, waiting, completed, delayed, failed and paused job counts for each job type.
        Breaking change: the output no longer includes jobCounts. Use statistics instead.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    Invoke-ImmichApiGetQueues -ImmichSession $Session | ForEach-Object { [QueueResponseDto]::new($PSItem) }

}
#endregion
