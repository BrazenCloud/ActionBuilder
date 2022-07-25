Function New-BcOsCommandAction {
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

    # if no parameters and no includeParametersParameter
    # then this is simple
    if ($ActionParameters.Count -eq 0 -and -not $IncludeParametersParameter.IsPresent) {
        if ($Windows.IsPresent) {
            if ($RedirectCommandOutput.IsPresent) {
                $Command = "$Command | Out-File .\results\out.txt"
            }
            $windowsTemplate -replace '\{ if \}', $Command | Out-File "$OutPath\$Name\Windows\script.ps1"
        }
        if ($Linux.IsPresent) {

        }
    }
}