function Merge-IMPerson
{
    <#
    .DESCRIPTION
        Merges two people
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER ToPersonID
        Defines the person to merge to
    .PARAMETER FromPersonID
        Defines the id of the person to merge from
    .EXAMPLE
        Merge-IMPerson -ToPersonID <personid> -FromPersonID <personid>,<personid>

        Merges three persons. ToPersonID will persist
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
        [string[]]
        $FromPersonID
    )

    if ($PSCmdlet.ShouldProcess(("Merge people($($FromPersonID -join ',')) with $ToPersonID"), 'POST'))
    {
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'FromPersonID' -NameMapping @{
                FromPersonID = 'ids'
            })

        InvokeImmichRestMethod -Method POST -RelativePath "/people/$ToPersonID/merge" -ImmichSession:$Session -Body:$BodyParameters
    }
}
#endregion
