function ConvertTo-ImmichRequestBody
{
    <#
    .DESCRIPTION
        Normalizes request body values before JSON serialization. Datetimes are written as
        UTC round-trip strings at any depth, because Immich rejects timezone-less dates such as
        filter.takenAt.lte. Booleans, switches and secure strings are converted at any depth.
    .PARAMETER InputObject
        The hashtable body to normalize.
    .EXAMPLE
        ConvertTo-ImmichRequestBody -InputObject @{ isFavorite = [switch]$true }

        Returns a hashtable whose isFavorite value is the boolean $true.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Ignored, internal function')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$InputObject
    )

    $NewBody = @{}
    foreach ($Key in $InputObject.Keys)
    {
        $Value = $InputObject[$Key]
        $TypeName = if ($null -eq $Value) { 'null' } else { $Value.GetType().Name }
        switch ($TypeName)
        {
            'boolean'
            {
                $NewBody[$Key] = [bool]$Value
                break
            }
            'SwitchParameter'
            {
                $NewBody[$Key] = [bool]$Value
                break
            }
            'datetime'
            {
                $NewBody[$Key] = ([DateTimeOffset]$Value).UtcDateTime.ToString('o')
                break
            }
            'SecureString'
            {
                $NewBody[$Key] = ConvertFromSecureString -SecureString $Value
                break
            }
            'Hashtable'
            {
                $NewBody[$Key] = ConvertTo-ImmichRequestBody -InputObject $Value
                break
            }
            'OrderedDictionary'
            {
                $NewBody[$Key] = ConvertTo-ImmichRequestBody -InputObject $Value
                break
            }
            default
            {
                $NewBody[$Key] = $Value
            }
        }
    }
    return $NewBody
}
