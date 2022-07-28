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

    # Build the parameters
    foreach ($param in $ActionParameters.Keys) {
        $pClone = $parameterTemplate.Clone()
        $pClone.Type = 2 # boolean
        $pClone.Name = $ActionParameters[$param].Name
        $pClone.Description = $ActionParameters[$param].Description
        $parameters += $pClone
    }

    # Add the default parameters parameter, if requested
    if ($IncludeParametersParameter.IsPresent) {
        $pClone = $parameterTemplate.Clone()
        $pClone.Type = 0
        $pClone.Name = 'Parameters'
        $pClone.DefaultValue = $DefaultParameters
    }

    $action = [BcAction]::new()
    $action.Manifest = [BcManifest]::new()

    # update manifest based on os
    if (-not $Windows.IsPresent) {
        $action.Manifest.WindowsCommand = $null
    }
    if (-not $Linux.IsPresent) {
        $action.Manifest.LinuxCommand = $null
    }

    # if no parameters and no includeParametersParameter
    # then this is simple
    if ($ActionParameters.Count -eq 0 -and -not $IncludeParametersParameter.IsPresent) {
        if ($Windows.IsPresent) {
            if ($RedirectCommandOutput.IsPresent) {
                $wCommand = "$Command | Out-File .\results\out.txt"
            }
            $action.WindowsScript = $windowsTemplate -replace '\{ if \}', $wCommand
        }
        if ($Linux.IsPresent) {
            if ($RedirectCommandOutput.IsPresent) {
                $lCommand = "$Command >> ./results/out.txt"
            }
            $action.LinuxScript = $linuxTemplate.Replace('{ if }', $lCommand).Replace('{ jq }', '')
        }
        # if it has action parameters
    } elseif ($ActionParameters.Count -gt 0) {

    }
    $action
}