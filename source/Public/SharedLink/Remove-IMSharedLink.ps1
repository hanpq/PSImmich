function Remove-IMSharedLink
{
    <#
    .DESCRIPTION
        Remove Immich shared link
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific shared link id to be removed
    .EXAMPLE
        Remove-IMSharedLink -id <sharedlinkid>

        Remove Immich shared link
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/shared-links/$PSItem" -ImmichSession:$Session
            }
        }
    }
}
#endregion
