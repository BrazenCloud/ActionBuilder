Function New-BcAbAllScript {
    [cmdletbinding()]
    param (
        [BcParameter[]]$Parameters,
        [ValidateSet('Windows', 'Linux')]
        [string]$OperatingSystem,
        [string]$Command,
        [switch]$RedirectCommandOutput,
        [string]$DefaultParameters
    )

    $templates = Get-Template -All

    $mcSplat = @{
        Command    = $Command
        OS         = $OperatingSystem
        Redirect   = $RedirectCommandOutput.IsPresent
        Parameters = $DefaultParameters
    }

    foreach ($param in $Parameters) {
        # if this param has a default value, use it, else it must have come from the passed actionParameters var
        if ($param.Type -eq 2) {
            $mcSplat.Parameters = $param.GetValue($OperatingSystem)
            $templates[$OperatingSystem]['if']['bool'].Replace('{param}', $Param.Name) -replace '"?{command}"?', (makeCommand @mcSplat)
        } elseif ($Param.Type -eq 0) {
            $mcSplat.Parameters = $param.GetValue($OperatingSystem)
            $templates[$OperatingSystem]['if']['string'].Replace('{param}', $Param.Name) -replace '{command}', (makeCommand @mcSplat)
        }
    }
}