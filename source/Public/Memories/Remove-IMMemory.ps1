function Remove-IMMemory
{
    <#
    .DESCRIPTION
        Removes an Immich memory
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the memory ids that should be removed. Accepts pipeline input.
    .EXAMPLE
        Remove-IMMemory -id <memoryid>

        Removes an Immich memory
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [Alias('libraryId')]
        [string[]]
        $id
    )

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/memories/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
