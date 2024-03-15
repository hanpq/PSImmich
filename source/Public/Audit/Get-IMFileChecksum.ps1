function Get-IMFileChecksum
{
    <#
    .DESCRIPTION
        Retreives Immich file checksum
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER FileName
        Defines the full path to the file that checksum should be calculated for.
    .EXAMPLE
        Get-IMFileChecksum

        Retreives Immich file checksum
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string[]]
        $FileName
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'FileName' -NameMapping @{FileName = 'filenames' })
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method POST -RelativePath '/audit/file-report/checksum' -ImmichSession:$Session -Body:$BodyParameters
    }

}
#endregion
