Function New-BcAbScript {
    [cmdletbinding()]
    param (
        [BcParameter[]]$Parameters,
        [ValidateSet('Windows', 'Linux')]
        [string]$OperatingSystem,
        [string]$Command,
        [switch]$RedirectCommandOutput,
        [string]$DefaultParameters,
        [Parameter( Mandatory )]
        [ValidateSet('Combine', 'One', 'All')]
        [string]$Type
    )
    switch ($Type) {
        'Combine' {
            $PSBoundParameters.Remove('Type') | Out-Null
            New-BcAbCombineScript @PSBoundParameters
        }
        'One' {
            $PSBoundParameters.Remove('Type') | Out-Null
            New-BcAbOneScript @PSBoundParameters
        }
        'All' {
            $PSBoundParameters.Remove('Type') | Out-Null
            New-BcAbAllScript @PSBoundParameters
        }
    }
}