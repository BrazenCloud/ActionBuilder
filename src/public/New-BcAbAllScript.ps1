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

    $templates = @{
        'Windows' = @{
            IfCombine = Get-Template -Name osCommand-WindowsIfCombine
            IfParam   = Get-Template -Name osCommand-WindowsIfParam
            Else      = Get-Template -Name osCommand-WindowsElse
            BoolIf    = Get-Template -Name osCommand-WindowsIfBool
            IfString  = Get-Template -Name osCommand-WindowsIfString
        }
        'Linux'   = @{
            IfCombine = Get-Template -Name osCommand-LinuxIfCombine
            IfParam   = Get-Template -Name osCommand-LinuxIfParam
            Else      = Get-Template -Name osCommand-LinuxElse
            BoolIf    = Get-Template -Name osCommand-LinuxIfBool
            IfString  = Get-Template -Name osCommand-LinuxIfString
        }
    }

    $orStatement = @{
        Windows = ' -or '
        Linux   = ' || '
    }

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
            $templates[$OperatingSystem]['BoolIf'].Replace('{param}', $Param.Name) -replace '"?{command}"?', (makeCommand @mcSplat)
        } elseif ($Param.Type -eq 0) {
            $mcSplat.Parameters = $param.GetValue($OperatingSystem)
            $templates[$OperatingSystem]['IfString'].Replace('{param}', $Param.Name) -replace '"?{command}"?', (makeCommand @mcSplat)
        }
    }
}