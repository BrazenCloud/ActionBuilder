Function New-BcAbConfig {
    [cmdletbinding()]
    param (
        [Parameter( Mandatory )]
        [string]$Name,
        [string]$Description,
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
        [string]$OutPath,
        [switch]$Force
    )
    $ht = [ordered]@{
        Name                           = $Name
        Description                    = $Description
        OperatingSystems               = $OperatingSystems
        Command                        = $Command
        ExtraFolders                   = $ExtraFolders
        IncludeParametersParameter     = $IncludeParametersParameter
        ParametersParameterDescription = $ParametersParameterDescription
        DefaultParameters              = $DefaultParameters
        RedirectCommandOutput          = $RedirectCommandOutput
        ParameterLogic                 = $ParameterLogic
        ActionParameters               = $ActionParameters
        RequiredPackages               = $RequiredPackages
    }

    if ($PSBoundParameters.Keys -notcontains 'ActionParameters') {
        $ht['ActionParameters'] = @(
            [ordered]@{
                Name              = ''
                CommandParameters = ''
                Description       = ''
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
        } elseIf (Test-Path $OutPath -PathType Leaf -and -not $Force.IsPresent) {
            Throw "Output Path: '$OutPath' already exists. Use -Force to overwrite."
        }
        $ht | ConvertTo-Json | Out-File $OutPath -Force:$Force.IsPresent
    } else {
        $ht
    }
    
}