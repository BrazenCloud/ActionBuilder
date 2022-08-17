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

    $action = [BcAction]::new()

    # Build the parameters
    $action.Parameters = foreach ($param in $ActionParameters) {
        New-BcAbParameter @param
    }

    # Get Required Parameters
    $reqParams = $action.Parameters | Where-Object { $_.IsOptional -eq $false }

    # Add the default parameters parameter, if requested
    if (-not $ParametersParameterDescription.Length -gt 0) {
        $ParametersParameterDescription = 'Parameters typed here are passed directly to the command.'
    }
    if ($IncludeParametersParameter.IsPresent) {
        $paramSplat = @{
            Name         = 'Custom Parameters'
            DefaultValue = $DefaultParameters
            Description  = $ParametersParameterDescription
        }
        $action.Parameters += New-BcAbParameter @paramSplat
    }

    # update repository and manifest
    foreach ($tag in $Tags) {
        if ($action.Repository.Tags -notcontains $tag) {
            $action.Repository.Tags += $tag
        }
    }
    if ($action.Repository.Tags -notcontains $Name) {
        $action.Repository.Tags += $Name
    }
    $action.Repository.Description = $Description
    if ($OperatingSystems -contains 'Windows') {
        if (-not $Language.Length -gt 0) {
            $action.Repository.Language = 'Generated PowerShell'
        } else {
            $action.Repository.Language = $Language
        }
        if ($action.Repository.Tags -notcontains 'Windows') {
            $action.Repository.Tags += 'Windows'
        }
    } else {
        $action.Manifest.WindowsCommand = $null
    }
    if ($OperatingSystems -contains 'Linux') {
        if (-not $Language.Length -gt 0) {
            $action.Repository.Language = 'Generated Bash'
        } else {
            $action.Repository.Language = $Language
        }
        if ($action.Repository.Tags -notcontains 'Linux') {
            $action.Repository.Tags += 'Linux'
        }
    } else {
        $action.Manifest.LinuxCommand = $null
    }

    # declare splat
    $mcSplat = @{
        Command            = $Command
        OS                 = ''
        Redirect           = $RedirectCommandOutput.IsPresent
        Parameters         = $DefaultParameters
        RequiredParameters = $reqParams
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
            $action.WindowsScript = $templates['Windows']['script'] `
                -replace '\{ preCommands \}', $preCmds `
                -replace '\{ if \}', (makeCommand @mcSplat)
        }
        if ($OperatingSystems -contains 'Linux') {
            $mcSplat['OS'] = 'Linux'
            $action.LinuxScript = $templates['Linux']['script'] `
                -replace '\{ preCommands \}', $preCmds `
                -replace '\{ if \}', (makeCommand @mcSplat) `
                -replace '\{ jq \}', ''
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0 -or $IncludeParametersParameter) {
        foreach ($os in $OperatingSystems) {
            $mcSplat.OS = $os

            $logicSplat = @{
                Parameters            = $Action.Parameters
                Command               = $Command
                OperatingSystem       = $os
                RedirectCommandOutput = $RedirectCommandOutput.IsPresent
                DefaultParameters     = $IncludeParametersParameter ? $null : $DefaultParameters
                Type                  = $ParameterLogic
            }

            $ifs = New-BcAbScript @logicSplat

            $jqs = if ($os -eq 'Linux') {
                foreach ($aParam in $Action.Parameters) {
                    $templates['Linux']['jq'] `
                        -replace '\{bashParam\}', $aParam.GetBashParameterName() `
                        -replace '\{param\}', $aParam.Name
                }
            } else {
                $null
            }

            $prereqs = if ($os -eq 'Linux') {
                if ($RequiredPackages.Count -gt 0) {
                    foreach ($package in $RequiredPackages) {
                        $templates['Linux']['prereq'] `
                            -replace '\{package\}', $package.Name `
                            -replace '\{testCommand\}', $package.TestCommand
                    }
                } else {
                    $null
                }
            } else {
                $null
            }
            

            $action.SetScript($os, (
                    $templates[$os]['script'] `
                        -replace '\{ preCommands \}', $preCmds `
                        -replace '\{ jq \}', ($jqs -join "`n") `
                        -replace '\{ prereqs \}', $prereqs `
                        -replace '\{ if \}', ($ifs -join "`n")
                )
            )
        }
    }
    $action
}