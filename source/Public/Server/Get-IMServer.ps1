﻿function Get-IMServer
{
    <#
    .DESCRIPTION
        Retreives all Immich server info properties
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMServer

        Retreives all Immich server info properties
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null
    )

    $ResultObject = [ordered]@{}
    $Results = [array]@()
    $Results += Get-IMServerAbout -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'About' -PassThru
    $Results += Get-IMServerConfig -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Config' -PassThru
    $Results += Get-IMServerFeature -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Feature' -PassThru
    $Results += Get-IMServerStatistic -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Stats' -PassThru
    $Results += Get-IMServerStorage -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Storage' -PassThru
    $Results += Get-IMServerVersion -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Version' -PassThru
    $Results += Get-IMSupportedMediaType -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Media' -PassThru
    $Results += Get-IMTheme -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Theme' -PassThru
    $Results += Test-IMPing -Session:$Session | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Ping' -PassThru

    foreach ($Result in $Results)
    {
        foreach ($property in ($Result.PSObject.Properties.Name | Sort-Object))
        {
            if ($property -eq 'ObjectType')
            {
                continue
            }
            $ResultObject.Add("$($Result.ObjectType)_$Property", $Result.$Property)
        }
    }
    return [pscustomobject]$ResultObject

}
#endregion
