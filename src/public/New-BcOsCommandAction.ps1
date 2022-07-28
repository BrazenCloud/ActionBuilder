Function New-BcOsCommandAction {
    [OutputType('BcAction')]
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$Command,
        [hashtable[]]$ActionParameters,
        [string]$DefaultParameters,
        [switch]$IncludeParametersParameter,
        [switch]$RedirectCommandOutput,
        [switch]$Windows,
        [switch]$Linux,
        [string]$OutPath
    )
    $parameters = @()
    $parameterTemplate = Get-Template -Name parameters | ConvertFrom-Json -AsHashtable
    $windowsTemplate = Get-Template -Name osCommand-Windows
    $linuxTemplate = Get-Template -Name osCommand-Linux
    $windowsIfTemplate = Get-Template -Name osCommand-WindowsIf
    $linuxIfTemplate = Get-Template -Name osCommand-LinuxIf
    $linuxJqTemplate = Get-Template -Name osCommand-LinuxJq

    $action = [BcAction]::new()
    $action.Manifest = [BcManifest]::new()

    # Build the parameters
    foreach ($param in $ActionParameters) {
        $newParam = [BcParameter]::new()
        $newParam.Type = 2 # boolean
        $newParam.Name = $param.Name
        $newParam.Description = $param.Description
        $action.Parameters += $newParam
    }

    # Add the default parameters parameter, if requested
    if ($IncludeParametersParameter.IsPresent) {
        $newParam = [BcParameter]::new()
        $newParam.Type = 0
        $newParam.Name = 'Parameters'
        $newParam.DefaultValue = $DefaultParameters
        $action.Parameters += $newParam
    }

    # update manifest based on os
    if (-not $Windows.IsPresent) {
        $action.Manifest.WindowsCommand = $null
    }
    if (-not $Linux.IsPresent) {
        $action.Manifest.LinuxCommand = $null
    }

    # declare splat
    $mcSplat = @{
        Command    = $Command
        OS         = ''
        Redirect   = $RedirectCommandOutput.IsPresent
        Parameters = $DefaultParameters
    }

    # if no parameters and no includeParametersParameter
    # then this is simple
    if ($ActionParameters.Count -eq 0 -and -not $IncludeParametersParameter.IsPresent) {
        if ($Windows.IsPresent) {
            $splat['OS'] = 'Windows'
            $action.WindowsScript = $windowsTemplate -replace '\{ if \}', (makeCommand @mcSplat)
        }
        if ($Linux.IsPresent) {
            $splat['OS'] = 'Linux'
            $action.LinuxScript = $linuxTemplate.Replace('{ if }', (makeCommand @mcSplat)).Replace('{ jq }', '')
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0 -or $IncludeParametersParameter) {
        if ($Windows.IsPresent) {
            $mcSplat.OS = 'Windows'
            $ifs = foreach ($aParam in $Action.Parameters) {
                # if this param has a default value, use it, else it must have come from the passed actionParameters var
                $mcSplat.Parameters = $null -ne $aParam.DefaultValue ? $aParam.DefaultValue : $ActionParameters[$Action.Parameters.IndexOf($aParam)]['CommandParameters']
                $windowsIfTemplate.Replace('{param}', $aParam.Name).Replace('"{command}"', (makeCommand @mcSplat))
            }

            $action.WindowsScript = $windowsTemplate.Replace('{ if }', ($ifs -join "`n"))
        }
        if ($Linux.IsPresent) {
            $mcSplat.OS = 'Linux'

            # bash only allows letters, numbers, and underscores in the var name
            $linuxVarNameReplace = '[^a-zA-Z0-9_]'

            $jqs = foreach ($aParam in $Action.Parameters) {
                # {bashParam}=$(jq -r '."{param}"' ./settings.json)
                $linuxJqTemplate.Replace('{bashParam}', ($aParam.Name -replace $linuxVarNameReplace, '')).Replace('{param}', $aParam.Name)
            }


            $ifs = foreach ($aParam in $Action.Parameters) {
                # if this param has a default value, use it, else it must have come from the passed actionParameters var
                $mcSplat.Parameters = $null -ne $aParam.DefaultValue ? $aParam.DefaultValue : $ActionParameters[$Action.Parameters.IndexOf($aParam)]['CommandParameters']
                $linuxIfTemplate.Replace('{param}', ($aParam.Name -replace $linuxVarNameReplace, '')).Replace('{command}', (makeCommand @mcSplat))
            }

            $action.LinuxScript = $linuxTemplate.Replace('{ jq }', ($jqs -join "`n")).Replace('{ if }', ($ifs -join "`n"))
        }
    }
    $action
}