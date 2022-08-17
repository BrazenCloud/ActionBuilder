Function New-BcAbConfig {
    [cmdletbinding()]
    param (
        [Parameter( Mandatory )]
        [string]$Name,
        [string]$Description,
        [string[]]$Tags,
        [string]$Language,
        [ValidateSet('Windows', 'Linux')]
        [string[]]$OperatingSystems,
        [Parameter( Mandatory )]
        [string]$Command,
        [string[]]$ExtraFolders,
        [bool]$IncludeParametersParameter,
        [string]$ParametersParameterDescription,
        [string]$DefaultParameters,
        [bool]$RedirectCommandOutput,
        [ValidateSet('Combine', 'All', 'One')]
        [string]$ParameterLogic = 'Combine',
        [hashtable[]]$ActionParameters,
        [hashtable[]]$RequiredPackages,
        [string[]]$PreCommands,
        [string]$OutPath,
        [switch]$Force
    )
    $ht = [ordered]@{
        Name                           = $Name
        Description                    = $Description ? $Description : ""
        OperatingSystems               = $OperatingSystems ? $OperatingSystems : @("Windows", "Linux")
        Tags                           = $Tags ? $Tags : @()
        Language                       = $Language
        Command                        = $Command
        ExtraFolders                   = $ExtraFolders ? $ExtraFolders : @()
        IncludeParametersParameter     = $IncludeParametersParameter ? $IncludeParametersParameter : $false
        ParametersParameterDescription = $ParametersParameterDescription ? $ParametersParameterDescription : ""
        DefaultParameters              = $DefaultParameters ? $DefaultParameters : ""
        RedirectCommandOutput          = $RedirectCommandOutput ? $RedirectCommandOutput : $false
        ParameterLogic                 = $ParameterLogic
        ActionParameters               = $ActionParameters
        RequiredPackages               = $RequiredPackages
        PreCommands                    = $PreCommands ? $PreCommands : @()
    }

    if ($PSBoundParameters.Keys -notcontains 'ActionParameters') {
        $ht['ActionParameters'] = @(
            [ordered]@{
                Name              = ''
                CommandParameters = ''
                Description       = ''
                Required          = ''
            }
        )
    }

    if ($PSBoundParameters.Keys -notcontains 'RequiredPackages') {
        $ht['RequiredPackages'] = @(
            [ordered]@{
                Name        = ''
                TestCommand = ''
            }
        )
    }

    if ($PSBoundParameters.Keys -contains 'OutPath') {
        if (Test-Path $OutPath -PathType Container) {
            $OutPath = "$OutPath\config.json"
        } elseIf ((Test-Path $OutPath -PathType Leaf) -and -not $Force.IsPresent) {
            Throw "Output Path: '$OutPath' already exists. Use -Force to overwrite."
        }
        $ht | ConvertTo-Json -AsArray -Depth 3 | Out-File $OutPath -Force:$Force.IsPresent
    } else {
        $ht
    }
    
}