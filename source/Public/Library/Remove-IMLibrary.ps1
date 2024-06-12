function Remove-IMLibrary
{
    <#
    .DESCRIPTION
        Removes an Immich library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the library ids that should be removed. Accepts pipeline input.
    .EXAMPLE
        Remove-IMLibrary -id <libraryid>

        Removes an Immich library
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
        # We loop through IDs because ids can be provided as an array to the parameter in which case the process block only gets called once.
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/libraries/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
