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
#### Request
```http
GET /{filename}/{shell_override}/{token}?name={name}&date={date}
```

- **filename:** The name of the file to run. (Required)  
- **shell_override:** The shell to use to run the file. (Optional)  
- **token:** The token to use to authenticate. (Required if set in config)  
- **?** The args to pass to the script. (Optional)"
    - Saved as `ARGS` dict in the script. with the key being the arg name and the value being the arg value.

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


