function Get-IMSession
{
    <#
    .DESCRIPTION
        Displays the Immich Session object.
    .PARAMETER Session
        Optionally define a portainer session object to use. This is useful when you are connected to more than one portainer instance.

        -Session $Session
    .EXAMPLE
        Get-PSession

        Returns the ImmichSession, if none is specified, it tries to retreive the default
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    if ($Session)
    {
        Write-Debug -Message 'Get-PSession; ImmichSession was passed as parameter'
        return $Session
    }
    elseif ($script:ImmichSession)
    {
        Write-Debug -Message 'Get-PSession; ImmichSession found in script scope'
        return $script:ImmichSession
    }
    else
    {
        Write-Error -Message 'No Immich Session established, please call Connect-Immich'
    }
}
#endregion
