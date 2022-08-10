Function New-BcAbCombineScript {
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

    $mainIf = $templates[$OperatingSystem]['if']['combine'] -replace '\{exists\}', ($Parameters.GetIsEmptyStatement($OperatingSystem) -join $orStatement[$OperatingSystem])

    $ifArr = foreach ($param in $Parameters | Where-Object { $_.Name -ne 'Parameters' }) {
        if ($param.Type -eq 2) {
            $templates[$OperatingSystem]['if']['if'].Replace('{condition}', $Param.GetIsTrueStatement($OperatingSystem)) -replace '{command}', "`"$($param.GetValue($OperatingSystem))`""
        } elseif ($Param.Type -eq 0) {
            $templates[$OperatingSystem]['if']['string'].Replace('{param}', $Param.Name) -replace '{command}', "`"$($param.GetValue($OperatingSystem))`""
        }
    }

    $mcSplat.Parameters = $DefaultParameters

    (($mainIf -replace '\{if\}', ($ifArr -join "`n"))) `
        -replace '\{command\}', $Command `
        -replace '\{else\}', (($templates[$OperatingSystem]['if']['else'] -replace '\{command\}', (makeCommand @mcSplat)) -join "`n")
}