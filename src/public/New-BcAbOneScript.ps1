Function New-BcAbOneScript {
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

    $out = if ($Parameters[0].Type -eq 2) {
        $mcSplat.Parameters = $Parameters[0].GetValue($OperatingSystem)
        $templates[$OperatingSystem]['if']['ifElse'].Replace('{condition}', $Parameters[0].GetIsTrueStatement($OperatingSystem)) -replace '{command}', (makeCommand @mcSplat)
    } elseif ($Parameters[0].Type -eq 0) {
        $mcSplat.Parameters = $Parameters[0].GetValue($OperatingSystem)
        $templates[$OperatingSystem]['if']['ifElse'].Replace('{condition}', $Parameters[0].GetIsEmptyStatement($OperatingSystem)) -replace '{command}', (makeCommand @mcSplat)
    }

    for ($x = 1; $x -lt $Parameters.Count - 1; $x++) {
        # if this param has a default value, use it, else it must have come from the passed actionParameters var
        $ifStr = if ($Parameters[$x].Type -eq 2) {
            $mcSplat.Parameters = $Parameters[$x].GetValue($OperatingSystem)
            $templates[$OperatingSystem]['if']['elseIfElse'].Replace('{condition}', $Parameters[$x].GetIsTrueStatement($OperatingSystem)) -replace '{command}', (makeCommand @mcSplat)
        } elseif ($Parameters[$x].Type -eq 0) {
            $mcSplat.Parameters = $Parameters[$x].GetValue($OperatingSystem)
            $templates[$OperatingSystem]['if']['elseIfElse'].Replace('{condition}', $Parameters[$x].GetIsEmptyStatement($OperatingSystem)) -replace '{command}', (makeCommand @mcSplat)
        }
        $out = $out.Replace('{else}', $ifStr)
    }
    if ($DefaultParameters.Length -gt 0) {
        $mcSplat.Parameters = $DefaultParameters
        $out = $out.Replace('{else}', $templates[$OperatingSystem]['if']['else'].Replace('{command}', (makeCommand @mcSplat)))
    }
    $out
}