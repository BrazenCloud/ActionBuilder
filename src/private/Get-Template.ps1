Function Get-Template {
    [cmdletbinding()]
    param (
        [switch]$All
    )
    @{
        Windows  = @{
            if     = @{
                if         = @'
if ({condition}) {
    {action}
}
'@
                bool       = @'
if ($settings.'{param}'.ToString() -eq 'true') {
    {command}
}
'@
                combine    = @'
if ( {exists} ) {
    $arr = & {
        {if}
    }
    & {command} $arr
} {else}
'@
                ifElse     = @'
if ( {condition} ) {
    {action}
} {else}
'@
                param      = @'
if ($settings.'{param}'.ToString().Length -gt 0) {
    {value}
}
'@
                string     = @'
if ($settings.'{param}'.Length -gt 1) {
    {command}
}
'@
                else       = @'
else {
    {action}
}
'@
                elseIf     = @'
elseif ( {condition} ) {
    {action}
}
'@
                elseIfElse = @'
elseif ( {condition} ) {
    {action}
} {else}
'@
            }
            script = @'
$settings = Get-Content .\settings.json | ConvertFrom-Json

{ if }
'@
        }
        Linux    = @{
            if     = @{
                if         = @'
if {condition} ; then
    {action}
fi
'@
                bool       = @'
if [ ${param} == "true" ]; then
    {command}
fi
'@
                combine    = @'
declare -a arr

if {exists} ; then
    {if}
    {command} ${arr[*]}
{else}
fi
'@
                ifElse     = @'

if {condition} ; then
    {action}
{else}
'@
                param      = @'
if [ ! -z {param} ]; then
    arr+=("{value}")
fi
'@
                string     = @'
if [ ${#{bashParam}} -gt 0 ]; then
    {command}
fi
'@
                else       = @'
'@
                elseIf     = @'
elif {condition}; then
    {action}
fi
'@
                elseIfElse = @'
elif {condition}; then
    {action}
{else}
'@
            }
            script = @'
#!/bin/bash

# check for current package manager
declare -A osInfo;
osInfo[/etc/redhat-release]=yum
osInfo[/etc/arch-release]=pacman
osInfo[/etc/gentoo-release]=emerge
osInfo[/etc/SuSE-release]=zypp
osInfo[/etc/debian_version]=apt-get
osInfo[/etc/alpine-release]=apk

for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        #echo Package manager: ${osInfo[$f]}
        pman=${osInfo[$f]}
    fi
done

# check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
    echo "Installing jq"

    # check for sudo, install
    if [ -x "$(command -v sudo)" ]; then
        sudo $pman install jq -y
    else
        $pman install jq -y
    fi
else
    echo "jq already installed"
fi

{ jq }

{ if }
'@
            jq     = @'
{bashParam}=$(jq -r '."{param}"' ./settings.json)
'@
        }
        Manifest = @'
COPY . .

RUN_WIN "powershell.exe -ExecutionPolicy Bypass -File .\windows\script.ps1"

RUN_LIN linux/script.sh
'@
    }
}