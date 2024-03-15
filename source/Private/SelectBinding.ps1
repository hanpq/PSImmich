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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    param(
        $Binding,
        [string[]]$SelectProperty
    )

    $ReturnHash = @{}

    # Only process binded parameters that we are intreseted in
    foreach ($Parameter in ($Binding.Keys | Where-Object { $SelectProperty -contains $PSItem }))
    {
        # Typecast switch to string
        if ($Binding[$Parameter] -is [switch])
        {
            $ReturnHash.Add($Parameter, (($Binding[$Parameter] -as [boolean]).ToString().ToLower()))
        }
        # Typecast boolean to string
        elseif ($Binding[$Parameter] -is [boolean])
        {
            $ReturnHash.Add($Parameter, ($Binding[$Parameter].ToString().ToLower()))
        }
        # Else add the value unaltered
        else
        {
            $ReturnHash.Add($Parameter, $Binding[$Parameter])
        }
    }
    return $ReturnHash

}
