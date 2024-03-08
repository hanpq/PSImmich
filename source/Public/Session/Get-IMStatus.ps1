function Get-IMStatus
{
    <#
    .DESCRIPTION
        Get public status for portainer instance
    .PARAMETER Session
        Optionally define a portainer session object to use. This is useful when you are connected to more than one portainer instance.

        -Session $Session
    .EXAMPLE
        Get-PStatus

        Get public status for portainer instance
    #>
    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    InvokeImmichRestMethod -NoAuth -Method Get -RelativePath '/status' -ImmichSession:$Session

}
