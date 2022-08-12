Function New-BcAbConfigActionParameters {
    [cmdletbinding()]
    param (
        [string]$Name,
        [string]$CommandParameters,
        [string]$Description
    )
    [ordered]@{
        Name              = $Name
        CommandParameters = $CommandParameters
        Description       = $Description
    }
}