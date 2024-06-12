function Remove-IMUser
{
    <#
    .DESCRIPTION
        Remove Immich user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the user id to update
    .PARAMETER force
        Defines that the user should be removed immediatly. By default the user remains in trash for 7 days before assets are removed.
    .EXAMPLE
        Remove-IMUser -id <userid> -force

        Remove Immich user
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter()]
        [switch]
        $Force
    )

    BEGIN
    {
        $Body = @{}
        $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Force' -NameMapping @{
                Force = 'force'
            })
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/admin/users/$PSItem" -ImmichSession:$Session -Body $Body
            }
        }
    }

}
#endregion
