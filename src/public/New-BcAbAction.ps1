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
        New-BcParameter @param
    }

    # Add the default parameters parameter, if requested
    if ($IncludeParametersParameter.IsPresent) {
        $action.Parameters += New-BcParameter -Name 'Parameters' -DefaultValue $DefaultParameters -Description $ParametersParameterDescription
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

            if ($ParameterLogic -eq 'Combine') {
                $ifs = New-BcAbCombineScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Linux' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
            } else {

                # bash only allows letters, numbers, and underscores in the var name
                $linuxVarNameReplace = '[^a-zA-Z0-9_]'

                $jqs = foreach ($aParam in $Action.Parameters) {
                    # {bashParam}=$(jq -r '."{param}"' ./settings.json)
                    $bashParam = $aParam.Name -replace $linuxVarNameReplace, ''
                    $templates['Linux']['jq'].Replace('{bashParam}', $bashParam).Replace('{param}', $aParam.Name)
                    
                }

                $ifs = foreach ($aParam in $Action.Parameters) {
                    if ($aParam.Type -eq 2) {
                        # if this param has a default value, use it, else it must have come from the passed actionParameters var
                        $mcSplat.Parameters = $null -ne $aParam.DefaultValue ? $aParam.DefaultValue : $ActionParameters[$Action.Parameters.IndexOf($aParam)]['CommandParameters']
                        $templates['Linux']['if']['bool'].Replace('{param}', $bashParam).Replace('{command}', (makeCommand @mcSplat))
                    } elseIf ($aParam.Type -eq 0) {
                        $mcSplat.Parameters = "`$$bashParam"
                        $templates['Linux']['if']['string'].Replace('{bashParam}', $bashParam).Replace('{command}', (makeCommand @mcSplat))
                    }
                }
            }

            $action.LinuxScript = $templates['Linux']['script'].Replace('{ jq }', ($jqs -join "`n")).Replace('{ if }', ($ifs -join "`n"))
        }
    }
    $action
}