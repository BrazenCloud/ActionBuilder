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

    $action = [BcAction]::new()
    $action.Manifest = [BcManifest]::new()

    # Build the parameters
    foreach ($param in $ActionParameters.Keys) {
        $newParam = [BcParameter]::new()
        $newParam.Type = 2 # boolean
        $newParam.Name = $ActionParameters[$param].Name
        $newParam.Description = $ActionParameters[$param].Description
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

    # build default commands
    if ($Windows.IsPresent) {
        $wCommand = $Command
        if ($PSBoundParameters.Key -contains 'DefaultParameters') {
            $wCommand = "$wCommand $DefaultParameters"
        }
        if ($RedirectCommandOutput.IsPresent) {
            $wCommand = "$wCommand | Out-File .\results\out.txt"
        }
    }
    if ($Linux.IsPresent) {
        $lCommand = $Command
        if ($PSBoundParameters.Key -contains 'DefaultParameters') {
            $lCommand = "$lCommand $DefaultParameters"
        }
        if ($RedirectCommandOutput.IsPresent) {
            $lCommand = "$lCommand >> ./results/out.txt"
        }
    }

    # if no parameters and no includeParametersParameter
    # then this is simple
    if ($ActionParameters.Count -eq 0 -and -not $IncludeParametersParameter.IsPresent) {
        if ($Windows.IsPresent) {
            $action.WindowsScript = $windowsTemplate -replace '\{ if \}', $wCommand
        }
        if ($Linux.IsPresent) {
            $action.LinuxScript = $linuxTemplate.Replace('{ if }', $lCommand).Replace('{ jq }', '')
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0 -or $IncludeParametersParameter) {
        if ($Windows.IsPresent) {
            
        }
        if ($Linux.IsPresent) {

        }
    }
    $action
}