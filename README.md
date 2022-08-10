# BrazenCloud Action Builder

This tool can be used to dynamically produce BrazenCloud actions based on commands, executables, or prebuilt scripts. This is designed to ingest a JSON config and spit out Actions.

Here is the blank template config:

```json
[
    {
        "Name": "",
        "Description": "",
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
        ]
    }
]
```

## Explanation

- **Name**: The name to give the action.
- **Description**: The description to give the action.
- **OperatingSystems**: An array of operating systems to make the Action compatible with. Currently supports: Windows and Linux
- **Command**: The command to call to execute the Action.
- **ExtraFolders**: An array of paths. Each path will be copied to the root of the generated Action. If you need to supply OS specific files, be sure they are in an OS specific folder such as 'Windows' or 'Linux'.
- **IncludeParametersParameter**: If true, the generated Action will include a string parameter that, when filled, will pass those values to the command as arguments.
- **ParametersParameterDescription**: The description to place on the Parameters parameter.
- **DefaultParameters**: The default arguments to pass to the command. If no other parameters are specified and this field has value, this will be the only command that runs.
- **RedirectCommandOutput**: If true, this will redirect stdout from the command to a text file in the results folder.
- **ParameterLogic**: One of three options: Combine, All, or One. See below for details.
- **ActionParameters**: An array of parameters to generate. See below for details.

### Action Parameters

Due to the complexity of implementing other potential parameter types, the Action Builder can only produce two types of parameters with very narrow use cases.

- Bool specified value
  - Presented as boolean and the script passes a specified value to the command
- String - passed value
  - Presented as a string and the script passes the string combined with a specified value

#### Bool

A boolean parameter for an `ipconfig` Action might look like:

```json
{
    "Name": "All",
    "CommandParameters": "/all",
    "Description": "Shows the entire IP configuration"
}
```

The generated Action will preset a boolean parameter in the UI (checkbox) and if that box is checked, the `/all` argument will be passed to the command.

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
  - Combines all filled in string parameters or checked boolean parameters to pass to the specified command
  - If none were passed, default command is run
- All
  - Runs each selected parameter against the command
- One
  - Runs the first selected parameter against the command and no other
- None
  - Runs the command with default value or no parameters

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

Then the action, if generated with the combine logic flow, would check each of those parameters for values and if any of them have value, they would be passed as an argument array to the command. So this could end up looking like:

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