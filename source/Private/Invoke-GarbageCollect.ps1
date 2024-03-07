function Invoke-GarbageCollect
{
    <#
    .SYNOPSIS
        Calls system.gc collect method. Purpose is mainly for readability.
    .DESCRIPTION
        Calls system.gc collect method. Purpose is mainly for readability.
    .EXAMPLE
        Invoke-GarbageCollect
    #>
    [system.gc]::Collect()
}
