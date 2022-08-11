Function New-BcAbConfigActionParameters {
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$CommandParameters,
        [string]$Description
    )
    @{
        Name              = $Name
        CommandParameters = $CommandParameters
        Description       = $Description
    }
}