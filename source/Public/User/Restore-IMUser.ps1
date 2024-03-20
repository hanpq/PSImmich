function Restore-IMUser
{
    <#
    .DESCRIPTION
        Restore Immich user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the user id to update
    .EXAMPLE
        Restore-IMUser -id <userid>

        Restore Immich user
    #>

    [CmdletBinding()]
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
            InvokeImmichRestMethod -Method POST -RelativePath "/user/$PSItem/restore" -ImmichSession:$Session
        }
    }

}
#endregion
