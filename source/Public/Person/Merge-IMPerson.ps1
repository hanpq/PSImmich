function Merge-IMPerson
{
    <#
    .SYNOPSIS
        Merges duplicate person records.
    .DESCRIPTION
        Combines multiple person entries when face recognition creates duplicates.
        The target person persists while source persons are merged into it.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER ToPersonID
        Target person ID that will remain after merge.
    .PARAMETER FromPersonID
        Source person ID(s) to merge into target. Supports multiple IDs.
    .EXAMPLE
        Merge-IMPerson -ToPersonID 'bf973405-3f2a-48d2-a687-2ed4167164be' -FromPersonID '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'

        Merges source person into target person.
    .NOTES
        Supports -WhatIf and -Confirm for safety.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $ToPersonID,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('ids')]
        [string[]]
        $FromPersonID
    )

    if ($PSCmdlet.ShouldProcess(("Merge people($($FromPersonID -join ',')) with $ToPersonID"), 'POST'))
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

        InvokeImmichRestMethod -Method POST -RelativePath "/people/$ToPersonID/merge" -ImmichSession:$Session -Body:$BodyParameters
    }
}
#endregion
