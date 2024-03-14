function Remove-IMAPIKey
{
    <#
    .DESCRIPTION
        Removes Immich api key
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines an api key id to remove
    .EXAMPLE
        Remove-IMAPIKey

        Remove Immich api key
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]
        $id
    )

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/api-key/$CurrentID" -ImmichSession:$Session
            }
        }
    }

}
#endregion
