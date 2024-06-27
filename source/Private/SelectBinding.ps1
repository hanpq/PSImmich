function SelectBinding
{
    <#
    .DESCRIPTION
        Function that is extracts what parameters the cmdlet was called with
    .PARAMETER Binding
        PSBoundParameters object should be passed
    .PARAMETER SelectProperty
        String array of the properties that should be extracted.
    .PARAMETER NameMapping
        Defines a hashtable where a parametername can be mapped to different name of the API parameter name.
    .EXAMPLE
        SelectBinding
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    param(
        $Binding,
        [string[]]$SelectProperty,
        [hashtable]$NameMapping
    )

    $ReturnHash = @{}

    # Only process binded parameters that we are intreseted in
    foreach ($Parameter in ($Binding.Keys | Where-Object { $SelectProperty -contains $PSItem }))
    {
        if ($NameMapping.Keys -contains $Parameter)
        {
            $APIName = $NameMapping[$Parameter]
        }
        else
        {
            $APIName = $Parameter
        }

        $ReturnHash.Add($APIName, $Binding[$Parameter])
    }
    return $ReturnHash

}
