# RequestAndRun
A rest api basted server that makes it possible to run any shell script file from anywhere.

## Run it yourself
1. Clone the repo

```bash
git clone https.//github.com/M4rshe1/RequestAndRun.git
```

2. Move into the directory

```bash
cd RequestAndRun
```

3. Run the Docker container

```bash
sudo bash run bash -rebuild -pull
```

## API Documentation

### Run a file
```http
GET /{filename}/{shell_override}/{token}?name={name}&date={date}
```

- **filename:** The name of the file to run. (Required)  
- **shell_override:** The shell to use to run the file. (Optional)  
  - if it is not a supported shell it will try to detect the right one. This is practical if you don't want to specify shell by yourself.
- **token:** The token to use to authenticate. (Required if set in config otherwise optional) 
- **?** The args to pass to the script. (Optional)"
    - Saved as `ARGS` dict in the script. with the key being the arg name and the value being the arg value.
    - Example: `?name=Colin&date=2021-09-11`
    - Will be added to the script as dict: `ARGS = {"name": "Colin", "date": "2021-09-11"}`

### Config  

Example `config.json` file:   

```json
{
  "settings": {
    "local_prefix": "runfile",
    "hub_file": "hub",
    "state": "dev",
    "agents": {
      "powershell": "ps1",
      "pwsh": "ps1",
      "bash": "sh",
      "sh": "sh",
      "curl": "sh",
      "wget": "sh"
    },
    "tokens": [
      "hub_config_token_2378r2tvf9iwjzebf89qz9fozhbsontgjnaeriufz973v",
      "admin_token_02q34zhuzgn9ef237tvr28b9f29u3f2389z89wzbhuef92983f"
    ],
    "token_required": false
  },
  "files": {
    "ping-tool": {
      "powershell": {
        "path": "https://raw.githubusercontent.com/M4rshe1/tups1s/master/USB/Scripts/ping_tool/ping_tool.ps1",
        "local": false
      },
      "pwsh": {
        "path": "https://raw.githubusercontent.com/M4rshe1/tups1s/master/USB/Scripts/ping_tool/ping_tool.ps1",
        "local": false
      }
    },
    "ctt": {
      "powershell": {
        "path": "https://christitus.com/win",
        "local": false
      }
    }
  }
}
```

- **settings:** The settings for the server.
    - **local_prefix:** The prefix in which folder to save the files. (Default: `runfile`)
    - **hub_file:** The name of the file to use for the hub. (Default: `hub`)
    - **state:** The state of the server. (Default: `dev`)
    - **agents:** The supported agents and there default extension.
    - **tokens:** The tokens to use for authentication. (Default: `[]`)
    - **token_required:** If a token is required to run a file. (Default: `false`)

- **files:** The files to run.
  - **{filename}:** The name of the file to run.
      - **{agent}:** The shell to use to run the file.
          - **path:** The path to the file to run (local or url)
          - **local:** If the file is local or not. (Default: `false`)

### Hub

It will automatically create a hub file that will list all the files that are available for that agent.  

```powershell
"
  _____  _    _ _   _   ______ _ _
 |  __ \| |  | | \ | | |  ____(_) |
 | |__) | |  | |  \| | | |__   _| | ___
 |  _  /| |  | | . ' | |  __| | | |/ _ \
 | | \ \| |__| | |\  | | |    | | |  __/
 |_|  \_\\____/|_| \_| |_|    |_|_|\___|


****************************************************************
* Copyright of Colin Heggli 2024                               *
* https://colin.heggli.dev                                     *
* https://github.com/M4rshe1                                   *
****************************************************************

Available runfiles:
--------------------------
ping-tool            - [1]
ctt                  - [2]
--------------------------
Quit                 - [q]

Select a runfile to run
>> :
"
```
