Function New-BcAbAction {
    [OutputType('BcAction')]
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$Description,
        [string[]]$Tags,
        [string]$Language,
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
        [hashtable[]]$RequiredPackages,
        [string[]]$PreCommands,
        [string]$OutPath
    )
    $templates = Get-Template -All

    $action = [BcAction]::new()

    # Build the parameters
    $action.Parameters = foreach ($param in $ActionParameters) {
        New-BcAbParameter @param
    }

    # Add the default parameters parameter, if requested
    if (-not $ParametersParameterDescription.Length -gt 0) {
        $ParametersParameterDescription = 'Parameters typed here are passed directly to the command.'
    }
    if ($IncludeParametersParameter.IsPresent) {
        $action.Parameters += New-BcAbParameter -Name 'Parameters' -DefaultValue $DefaultParameters -Description $ParametersParameterDescription
    }

    # update repository and manifest
    $action.Repository.Description = $Description
    $action.Repository.Tags += $Command
    if ($OperatingSystems -contains 'Windows') {
        if (-not $Language.Length -gt 0) {
            $action.Repository.Language = 'Generated PowerShell'
        } else {
            $action.Repository.Language = $Language
        }
        $action.Repository.Tags += 'Windows'
    } else {
        $action.Manifest.WindowsCommand = $null
    }
    if ($OperatingSystems -contains 'Linux') {
        if (-not $Language.Length -gt 0) {
            $action.Repository.Language = 'Generated Bash'
        } else {
            $action.Repository.Language = $Language
        }
        $action.Repository.Tags += 'Linux'
    } else {
        $action.Manifest.LinuxCommand = $null
    }

    foreach ($tag in $Tags) {
        if ($action.Repository.Tags -notcontains $tag) {
            $action.Repository.Tags += $tag
        }
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

    $preCmds = if ($PreCommands.Count -gt 0) {
        $PreCommands -join "`n"
    } else {
        $null
    }

    # if no parameters and no includeParametersParameter
    # then this is simple
    if ($ActionParameters.Count -eq 0 -and -not $IncludeParametersParameter.IsPresent) {
        Write-Verbose 'No parameters passed'
        if ($OperatingSystems -contains 'Windows') {
            $mcSplat['OS'] = 'Windows'
            $action.WindowsScript = $templates['Windows']['script'] -replace '\{ if \}', (makeCommand @mcSplat)
        }
        if ($OperatingSystems -contains 'Linux') {
            $mcSplat['OS'] = 'Linux'
            $action.LinuxScript = $templates['Linux']['script'].Replace('{ if }', (makeCommand @mcSplat)).Replace('{ jq }', '')
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0 -or $IncludeParametersParameter) {
        if ($OperatingSystems -contains 'Windows') {
            $mcSplat.OS = 'Windows'

            $logicSplat = @{
                Parameters            = $Action.Parameters
                Command               = $Command
                OperatingSystem       = 'Windows'
                RedirectCommandOutput = $RedirectCommandOutput.IsPresent
                DefaultParameters     = $DefaultParameters
            }

            $ifs = switch ($ParameterLogic) {
                'Combine' {
                    New-BcAbCombineScript @logicSplat
                }
                'All' {
                    New-BcAbAllScript @logicSplat
                }
                'One' {
                    New-BcAbOneScript @logicSplat
                }
            }

            $action.WindowsScript = $templates['Windows']['script'].Replace('{ preCommands }', $preCmds).Replace('{ if }', ($ifs -join "`n"))
        }
        if ($OperatingSystems -contains 'Linux') {
            $mcSplat.OS = 'Linux'

            $logicSplat = @{
                Parameters            = $Action.Parameters
                Command               = $Command
                OperatingSystem       = 'Linux'
                RedirectCommandOutput = $RedirectCommandOutput.IsPresent
                DefaultParameters     = $DefaultParameters
            }

            $ifs = switch ($ParameterLogic) {
                'Combine' {
                    New-BcAbCombineScript @logicSplat
                }
                'All' {
                    New-BcAbAllScript @logicSplat
                }
                'One' {
                    New-BcAbOneScript @logicSplat
                }
            }

            $jqs = foreach ($aParam in $Action.Parameters) {
                # {bashParam}=$(jq -r '."{param}"' ./settings.json)
                $templates['Linux']['jq'].Replace('{bashParam}', $aParam.GetBashParameterName()).Replace('{param}', $aParam.Name)
            }

            $prereqs = if ($RequiredPackages.Count -gt 0) {
                foreach ($package in $RequiredPackages) {
                    $templates['Linux']['prereq'].Replace('{package}', $package.Name).Replace('{testCommand}', $package.TestCommand)
                }
            } else {
                $null
            }

            $action.LinuxScript = $templates['Linux']['script'].Replace('{ preCommands }', $preCmds).Replace('{ jq }', ($jqs -join "`n")).Replace('{ if }', ($ifs -join "`n")).Replace('{ prereqs }', $prereqs)
        }
    }
    $action
}