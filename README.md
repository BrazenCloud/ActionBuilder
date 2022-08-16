# BrazenCloud.ActionBuilder

This tool can be used to dynamically produce BrazenCloud actions based on commands, executables, or prebuilt scripts. This is designed to ingest a JSON config and spit out Actions.

Here is the blank template config:

```json
[
    {
        "Name": "",
        "Description": "",
        "Tags": [],
        "Language": "",
        "OperatingSystems": [],
        "Command": "",
        "ExtraFolders": [],
        "IncludeParametersParameter": true,
        "ParametersParameterDescription": "",
        "DefaultParameters": "",
        "RedirectCommandOutput": true,
        "ParameterLogic": "",
        "ActionParameters": [
            {
                "Name": "",
                "CommandParameters": "",
                "Description": ""
            }
        ],
        "RequiredPackages": [
            {
                "Name": "",
                "TestCommand": ""
            }
        ],
        "PreCommands": []
    }
]
```

## Getting Started

The easiest way to get started is to use `New-BcAbConfig.ps1` cmdlet to create a new blank config:

```powershell
New-BcAbConfig -Name 'endpoint:ipconfig' -Command 'ipconfig' -OutPath .\testConfig.json
```

Then you can edit it to your specifications per the details below.

## Explanation

- **Name**: The name to give the Action. This is placed in the repository.json file.
- **Description**: The description to give the Action. This is placed in the repository.json file.
- **OperatingSystems**: An array of operating systems to make the Action compatible with. Currently supports: Windows and Linux.
- **Tags**: An array of tags to assign to the Action. This is placed in the repository.json file.
- **Language**: The language to assign to the Action. This is placed in the repository.json file.
- **Command**: The command to call to execute the Action.
- **ExtraFolders**: An array of paths. Each path will be copied to the root of the generated Action. If you need to supply OS specific files, be sure they are in an OS specific folder such as 'Windows' or 'Linux'.
- **IncludeParametersParameter**: If true, the generated Action will include a string parameter that, when filled, will pass those values to the command as arguments.
- **ParametersParameterDescription**: The description to place on the Parameters parameter.
- **DefaultParameters**: The default arguments to pass to the command. If no other parameters are specified and this field has value, this will be the only command that runs.
- **RedirectCommandOutput**: If true, this will redirect stdout from the command to a text file in the results folder.
- **ParameterLogic**: One of three options: Combine, All, or One. See below for details.
- **ActionParameters**: An array of parameters to generate. See below for details.
- **RequiredPackages**: An array of required packages to be installed before the Action executes. See below for details.
- **PreCommands**: An array of commands to be run before the main command executes. Each entry represents one command.

### Action Parameters

Due to the complexity of implementing other potential parameter types, the Action Builder can currently produce two types of parameters with specific, but broad, use cases.

- Bool specified value
  - Presented as a boolean and the script passes a config specified value to the command
- String - passed value
  - Presented as a string (textbox) and the script passes the string combined with a config specified value

#### Bool

A boolean parameter for an `ipconfig` Action might look like:

```json
{
    "Name": "All",
    "CommandParameters": "/all",
    "Description": "Shows the entire IP configuration"
}
```

The generated Action will preset a boolean parameter in the UI (checkbox) and if that box is checked, the `/all` argument will be passed to the command. So you might end up with:

```
ipconfig /all
```

#### String

A string parameter is differentiated from a boolean parameter by including `{value}` in the `CommandParameters` field.

For instance, a string parameter to a `tshark` Action (command line version of WireShark), might look like:

```json
{
    "Name": "Interface",
    "CommandParameters": "-i {value}",
    "Description": "The name or index of the interface."
}
```

The generated Action will present a string parameter in the UI (a textbox) and if a value, such as `4` is passed to it, the argument passed to the command will be `-i 4`.

### Logic Types

This tool can utilize the passed parameters to build out different logic flows in the produced script. The different logic flows are:

- Combine
  - Combines all filled in string parameters or selected boolean parameters to pass to the specified command
  - If none were passed, the default command is run
- All
  - Sequentially runs each selected parameter against the command
- One
  - Runs the first selected parameter against the command and no other

#### Combine

The combine logic flow will combine all passed parameters and present them as an argument array to the command. If none of them are passed, then the default parameter is passed as the only argument.

For example, if you had a `tshark` action with multiple parameters, such as:

```json
 {
    "Name": "Interface",
    "CommandParameters": "-i {value}",
    "Description": "The name or index of the interface."
},
{
    "Name": "Output file",
    "CommandParameters": "-w {value}",
    "Description": "Where to output the file"
},
{
    "Name": "Auto Stop Condition",
    "CommandParameters": "-a {value}",
    "Description": "Stop when duration:SEC, filesize:KB, files:COUNT, or packets:NUM"
},
{
    "Name": "Buffer",
    "CommandParameters": "-b {value}",
    "Description": "Switch to next file when duration:SEC, filesize:KB, files:COUNT, packets:COUNT, interval:SEC"
}
```

Then the action, if generated with the combine logic flow, would check each of those parameters for passed values and if any of them have value, they would be passed as an argument array to the command. So this could end up looking like:

```
.\tshark.exe -i 4 -w .\out.pcap -a filesize:500 -b filesize:500
```

#### All

The all logic flow will execute each passed parameter as an argument to the command. So if multiple parameters are passed, then the command will run multiple times.

For example, you could have an `ipconfig` Action with the following parameters:

```json
{
    "Name": "All",
    "CommandParameters": "/all",
    "Description": "Shows the entire IP configuration"
},
{
    "Name": "Show DNS",
    "CommandParameters": "/displaydns",
    "Description": "Shows the entire DNS cache"
}
```

If all of those booleans parameters were checked, the generated Action would run:

```
ipconfig /all
ipconfig /displaydns
```

And if `IncludeParametersParameter` was true, then anything passed into that parameter would also be executed.

#### One

The one logic flow is very similar to the all logic flow, but instead of executing all parameters, it executes the first one that has value.

Using the same example from before with `ipconfig`, say you have the following parameters:


```json
{
    "Name": "All",
    "CommandParameters": "/all",
    "Description": "Shows the entire IP configuration"
},
{
    "Name": "Show DNS",
    "CommandParameters": "/displaydns",
    "Description": "Shows the entire DNS cache"
}
```

And if you have `IncludeParametersParameter` set to true, then the generated action would present 3 parameters in the UI. 2 check boxes for the above values and a blank textbox to be filled in. The script would look through them in the order above with the parameters parameter being last. The first one that has value will be the only one executed.

### RequiredPackages

*Currently this is only implemented for Linux*

Each required package has 2 properties:

- **Name**: The name of the package. This will be passed to the package manager.
- **TestCommand**: The name of a command to check for using `command`. If the check fails, the package will be installed.

Here is an example using `binutils`:

```json
{
    "Name": "binutils",
    "TestCommand": "strings"
}
```

This will generate the following code (`$pman` is the dynamically determined package manager):

```bash
# check if binutils is installed
if ! [ -x "$(command -v strings)" ]; then
    echo "Installing binutils"

    # check for sudo, install
    if [ -x "$(command -v sudo)" ]; then
        sudo $pman install binutils -y
    else
        $pman install binutils -y
    fi
else
    echo "binutils already installed"
fi
```

## Examples

### chkdisk

```json
[
    {
        "Name": "chkdsk",
        "Description": "Checks a disk and displays a status report.",
        "OperatingSystems": [
            "Windows"
        ],
        "Tags": [
            "Disk"
        ],
        "Language": "Windows Executable",
        "Command": "chkdsk",
        "ExtraFolders": null,
        "IncludeParametersParameter": true,
        "ParametersParameterDescription": "If edited, this take precedence over all other parameters.",
        "DefaultParameters": "C: /scan /I /C",
        "RedirectCommandOutput": false,
        "ParameterLogic": "Combine",
        "ActionParameters": [
            {
                "Name": "Volume",
                "CommandParameters": "{value}",
                "Description": "Specifies the drive letter (followed by a colon), mount point, or volume name."
            },
            {
                "Name": "Scan",
                "CommandParameters": "/scan",
                "Description": "If specified, passes the /scan parameter"
            }
        ],
        "RequiredPackages": [],
        "PreCommands": []
    }
]
```

This generates the following script:

```powershell
Set-Location $PSScriptRoot
$settings = Get-Content ..\settings.json | ConvertFrom-Json

if ( $settings.'Volume'.ToString().Length -gt 0 -or $settings.'Scan'.ToString() -eq 'true' -or $settings.'Parameters'.ToString().Length -gt 0 ) {
    $arr = & {
        if ($settings.'Volume'.Length -gt 0) {
            "$($settings.'Volume')"
        }
        if ($settings.'Scan'.ToString() -eq 'true') {
            "/scan"
        }
    }
    & chkdsk $arr
} else {
    chkdsk
}

```

### debsums

```json
[
    {
        "Name": "debsums",
        "Description": "Validate Linux Packages with Debsums",
        "Tags": [
            "Inventory",
            "Packages",
            "Validation"
        ],
        "Language": "",
        "OperatingSystems": [
            "Linux"
        ],
        "Command": "debsums",
        "ExtraFolders": null,
        "IncludeParametersParameter": true,
        "ParametersParameterDescription": "",
        "DefaultParameters": "",
        "RedirectCommandOutput": true,
        "ParameterLogic": "One",
        "ActionParameters": [
            {
                "Name": "Silent",
                "CommandParameters": "-s",
                "Description": "Silences OK packages."
            }
        ],
        "RequiredPackages": [
            {
                "Name": "debsums",
                "TestCommand": "debsums"
            }
        ],
        "PreCommands": []
    }
]
```

This will produce the following script:

```bash
#!/bin/bash
cd "${0%/*}"

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

# check if debsums is installed
if ! [ -x "$(command -v debsums)" ]; then
    echo "Installing debsums"

    # check for sudo, install
    if [ -x "$(command -v sudo)" ]; then
        sudo $pman install debsums -y
    else
        $pman install debsums -y
    fi
else
    echo "debsums already installed"
fi

Silent=$(jq -r '."Silent"' ../settings.json)
Parameters=$(jq -r '."Parameters"' ../settings.json)


if [ ${Silent} == "true" ] ; then
    debsums -s >> ../results/out.txt
elif [ ! -z "$Parameters" ]; then
    debsums $Parameters >> ../results/out.txt
else
    debsums >> ../results/out.txt
fi

```