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
        [switch]$ParameterLogic,
        [hashtable[]]$ActionParameters,
        [string[]]$ExtraFolders,
        [string]$OutPath
    )
    $windowsTemplate = Get-Template -Name osCommand-Windows
    $linuxTemplate = Get-Template -Name osCommand-Linux
    $windowsIfBoolTemplate = Get-Template -Name osCommand-WindowsIfBool
    $linuxIfBoolTemplate = Get-Template -Name osCommand-LinuxIfBool
    $linuxJqTemplate = Get-Template -Name osCommand-LinuxJq
    $windowsIfStringTemplate = Get-Template -Name osCommand-WindowsIfString
    $linuxIfStringTemplate = Get-Template -Name osCommand-LinuxIfString
    $windowsIfTemplate = Get-Template -Name osCommand-WindowsIf
    $windowsIfCombineTemplate = Get-Template -Name osCommand-WindowsIfCombine
    $windowsIfParamTemplate = Get-Template -Name osCommand-WindowsIfParam
    $windowsElseTemplate = Get-Template -Name osCommand-WindowsElse

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
            $action.WindowsScript = $windowsTemplate -replace '\{ if \}', (makeCommand @mcSplat)
        }
        if ($OperatingSystems -contains 'Linux') {
            $splat['OS'] = 'Linux'
            $action.LinuxScript = $linuxTemplate.Replace('{ if }', (makeCommand @mcSplat)).Replace('{ jq }', '')
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0 -or $IncludeParametersParameter) {
        if ($OperatingSystems -contains 'Windows') {
            $mcSplat.OS = 'Windows'
            if ($ParameterLogic -eq 'Combine') {
                $ifs = New-BcAbCombineScript -Parameters $Action.Parameters -Command $Command -OperatingSystem 'Windows' -RedirectCommandOutput:$RedirectCommandOutput.IsPresent -DefaultParameters $DefaultParameters
            } else {
                $ifs = foreach ($aParam in $Action.Parameters) {
                    # if this param has a default value, use it, else it must have come from the passed actionParameters var
                    if ($aParam.Type -eq 2) {
                        $mcSplat.Parameters = $null -ne $aParam.DefaultValue ? $aParam.DefaultValue : $ActionParameters[$Action.Parameters.IndexOf($aParam)]['CommandParameters']
                        $windowsIfBoolTemplate.Replace('{param}', $aParam.Name).Replace('"{command}"', (makeCommand @mcSplat))
                    } elseif ($aParam.Type -eq 0) {
                        $mcSplat.Parameters = "`$settings.'$($aParam.Name)'"
                        $windowsIfStringTemplate.Replace('{param}', $aParam.Name).Replace('"{command}"', (makeCommand @mcSplat))
                    }
                }
            }

            $action.WindowsScript = $windowsTemplate.Replace('{ if }', ($ifs -join "`n"))
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
                    $linuxJqTemplate.Replace('{bashParam}', $bashParam).Replace('{param}', $aParam.Name)
                }


                $ifs = foreach ($aParam in $Action.Parameters) {
                    if ($aParam.Type -eq 2) {
                        # if this param has a default value, use it, else it must have come from the passed actionParameters var
                        $mcSplat.Parameters = $null -ne $aParam.DefaultValue ? $aParam.DefaultValue : $ActionParameters[$Action.Parameters.IndexOf($aParam)]['CommandParameters']
                        $linuxIfBoolTemplate.Replace('{param}', $bashParam).Replace('{command}', (makeCommand @mcSplat))
                    } elseIf ($aParam.Type -eq 0) {
                        $mcSplat.Parameters = "`$$bashParam"
                        $linuxIfStringTemplate.Replace('{bashParam}', $bashParam).Replace('{command}', (makeCommand @mcSplat))
                    }
                }
            }

            $action.LinuxScript = $linuxTemplate.Replace('{ jq }', ($jqs -join "`n")).Replace('{ if }', ($ifs -join "`n"))
        }
    }
    $action
}