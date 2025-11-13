function Get-IMJob
{
    <#
    .SYNOPSIS
        Retrieves Immich background job information
    .DESCRIPTION
        Retrieves information about all background jobs in Immich, including their status, progress,
        and queue information. This helps monitor system processing and job performance.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMJob

        Retrieves information about all background jobs.
    .EXAMPLE
        $jobs = Get-IMJob
        $jobs | Where-Object {$_.jobCounts.active -gt 0}

        Gets jobs that are currently active.
    .EXAMPLE
        Get-IMJob | Format-Table name, @{Name='Active';Expression={$_.jobCounts.active}}, @{Name='Waiting';Expression={$_.jobCounts.waiting}}

        Displays job information in a formatted table showing active and waiting job counts.
    .NOTES
        Job information includes queue status, active jobs, waiting jobs, and completed job counts for each job type.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method GET -RelativePath '/jobs' -ImmichSession:$Session

}
#endregion
