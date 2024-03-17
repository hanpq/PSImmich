function Remove-IMTag
{
    <#
    .DESCRIPTION
        Remove Immich tag
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific tag id to be retreived
    .EXAMPLE
        Remove-IMTag

        Remove Immich tag
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'Remove'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/tag/$CurrentID" -ImmichSession:$Session
            }
        }
    }
}
#endregion
