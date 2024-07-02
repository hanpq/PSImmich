function AddCustomType
{
    <#
    .DESCRIPTION
        Helper function to tag a type name to objects, this is used for formatting.
    .PARAMETER InputObject
        Defines the input object
    .PARAMETER Type
        Defines the type name to tag each passed object with
    .EXAMPLE
        $Objects | AddCustomType -Type IMAsset
    #>
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]
        $InputObject,

        [Parameter(Mandatory, Position = 1)]
        [ValidateSet('IMAsset', 'IMAlbum', 'IMActivity', 'IMAPIKey', 'IMPlace', 'IMUser')]
        [string]
        $Type
    )

    BEGIN
    {
        $TypeName = "PSImmich.ObjectType.$Type"
    }

    PROCESS
    {
        $InputObject | ForEach-Object {
            if ($PSItem.PSObject.TypeNames -notcontains $TypeName)
            {
                $null = $PSItem.Psobject.TypeNames.Insert(0, $TypeName)
            }
            $PSItem
        }
    }
}
