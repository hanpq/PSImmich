class ApiParameterAttribute : System.Attribute
{
    [string]$Name

    ApiParameterAttribute([string]$name)
    {
        $this.Name = $name
    }
}

# Create a type accelerator for the shortened syntax [ApiParameter]
$TypeAccelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$TypeAccelerators::Add('ApiParameter', [ApiParameterAttribute])
