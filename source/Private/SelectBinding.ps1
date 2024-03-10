function SelectBinding
{
    <#
    .DESCRIPTION
        Function that is extracts what parameters the cmdlet was called with
    .PARAMETER Binding
        PSBoundParameters object should be passed
    .PARAMETER SelectProperty
        String array of the properties that should be extracted.
    .EXAMPLE
        SelectBinding
    #>
    param(
        $Binding,
        [string[]]$SelectProperty
    )

    $ReturnHash = @{}

    # Only process binded parameters that we are intreseted in
    foreach ($Parameter in ($Binding.Keys | Where-Object { $SelectProperty -contains $PSItem }))
    {
        # Typecast switch to boolean
        if ($Binding[$Parameter] -is [switch])
        {
            $ReturnHash.Add($Parameter, ($Value -as [boolean]))
        }
        # Else add the value unaltered
        else
        {
            $ReturnHash.Add($Parameter, $Value)
        }
    }
    return $ReturnHash

}
