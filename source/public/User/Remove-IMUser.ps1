function Remove-IMUser
{
    <#
    .SYNOPSIS
        Removes an Immich user account.
    .DESCRIPTION
        Deletes user account. By default, moves to trash for 7 days before permanent removal.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to remove.
    .PARAMETER Force
        Forces immediate permanent deletion, bypassing 7-day trash period.
    .EXAMPLE
        Remove-IMUser -Id 'user-id'

        Removes user to trash for 7 days.
    .EXAMPLE
        Remove-IMUser -Id 'user-id' -Force

        Immediately deletes user permanently.

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
        [ApiParameter('force')]
        [switch]
        $Force
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'DELETE'))
            {
                InvokeImmichRestMethod -Method DELETE -RelativePath "/admin/users/$PSItem" -ImmichSession:$Session -Body $BodyParameters
            }
        }
    }

}
#endregion
