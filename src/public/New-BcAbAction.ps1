Function New-BcAbAction {
    [OutputType('BcAction')]
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$Description,
        [string]$Command,
        [ValidateSet('Windows', 'Linux')]
        [string[]]$OperatingSystems,
        [switch]$IncludeParametersParameter,
        [string]$ParametersParameterDescription,
        [string]$DefaultParameters,
        [switch]$RedirectCommandOutput,
        [ValidateSet('Combine', 'All', 'One')]
        [string]$ParameterLogic,
        [hashtable[]]$ActionParameters,
        [string[]]$ExtraFolders,
        [string]$OutPath
    )
    $templates = Get-Template -All

    $action = [BcAction]::new()

    # Build the parameters
    $action.Parameters = foreach ($param in $ActionParameters) {
        New-BcAbParameter @param
    }

    # Add the default parameters parameter, if requested
    if ($IncludeParametersParameter.IsPresent) {
        $action.Parameters += New-BcAbParameter -Name 'Parameters' -DefaultValue $DefaultParameters -Description $ParametersParameterDescription
    }

    # update repository and manifest
    $action.Repository.Description = $Description
    $action.Repository.Tags += $Command
    if ($OperatingSystems -contains 'Windows') {
        $action.Repository.Language = 'OS Command'
        $action.Repository.Tags += 'Windows'
    } else {
        $action.Manifest.WindowsCommand = $null
    }
    if ($OperatingSystems -contains 'Linux') {
        $action.Repository.Language = 'OS Command'
        $action.Repository.Tags += 'Linux'
    } else {
        $action.Manifest.LinuxCommand = $null
    }

    # declare splat
    $mcSplat = @{
        Command    = $Command
        OS         = ''
        Redirect   = $RedirectCommandOutput.IsPresent
        Parameters = $DefaultParameters
    }

    # add extra folder if passed
    if ($ExtraFolders.Count -gt 0) {
        $action.ExtraFolders = $ExtraFolders
    }

    # if no parameters and no includeParametersParameter
    # then this is simple
    if ($ActionParameters.Count -eq 0 -and -not $IncludeParametersParameter.IsPresent) {
        if ($OperatingSystems -contains 'Windows') {
            $splat['OS'] = 'Windows'
            $action.WindowsScript = $templates['Windows']['script'] -replace '\{ if \}', (makeCommand @mcSplat)
        }
        if ($OperatingSystems -contains 'Linux') {
            $splat['OS'] = 'Linux'
            $action.LinuxScript = $templates['Linux']['script'].Replace('{ if }', (makeCommand @mcSplat)).Replace('{ jq }', '')
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0 -or $IncludeParametersParameter) {
        if ($OperatingSystems -contains 'Windows') {
            $mcSplat.OS = 'Windows'
            $ifs = switch ($ParameterLogic) {
                'Combine' {
                    New-BcAbCombineScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Windows' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
                }
                'All' {
                    New-BcAbAllScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Windows' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
                }
                'One' {
                    New-BcAbOneScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Windows' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
                }
            }

            $action.WindowsScript = $templates['Windows']['script'].Replace('{ if }', ($ifs -join "`n"))
        }
        if ($OperatingSystems -contains 'Linux') {
            $mcSplat.OS = 'Linux'

            $ifs = switch ($ParameterLogic) {
                'Combine' {
                    New-BcAbCombineScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Linux' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
                }
                'All' {
                    New-BcAbAllScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Linux' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
                }
                'One' {
                    New-BcAbOneScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Linux' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
                }
            }

            $action.LinuxScript = $templates['Linux']['script'].Replace('{ jq }', ($jqs -join "`n")).Replace('{ if }', ($ifs -join "`n"))
        }
    }
    $action
}