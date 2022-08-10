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
        ($templates[$OperatingSystem]['if']['param'] -replace '\{param\}', $Param.Name) -replace '\{value\}', "`"$($param.GetValue($OperatingSystem))`""
    }

    $mcSplat.Parameters = $DefaultParameters

    (($mainIf -replace '\{if\}', ($ifArr -join "`n"))) `
        -replace '\{command\}', $Command `
        -replace '\{else\}', (($templates[$OperatingSystem]['if']['ifElse'] -replace '\{action\}', (makeCommand @mcSplat)) -join "`n")
}