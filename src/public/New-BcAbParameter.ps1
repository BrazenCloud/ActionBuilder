Function New-BcAbParameter {
    [OutputType('BcParameter')]
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$CommandParameters,
        [string]$Description,
        [string]$DefaultValue,
        [bool]$Required = $false
    )
    $param = [BcParameter]::new()
    $param.Description = $Description
    $param.Name = $Name

    if ($CommandParameters -match '\{value\}' -or $CommandParameters.Length -eq 0) {
        $param.Type = 0 # string
        $param.Value = $CommandParameters
    } else {
        $param.Type = 2 # boolean
        $param.Value = $CommandParameters
    }

    if ($PSBoundParameters.Keys -contains 'DefaultValue') {
        $param.DefaultValue = $DefaultValue
    }

    if ($Required) {
        $param.IsOptional = $false
    }

    $param
}