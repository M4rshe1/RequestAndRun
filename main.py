import json
from fastapi import FastAPI
from starlette.requests import Request
import requests

app = FastAPI()


def read_config() -> dict:
    with open("./config.json", "r") as f:
        config = json.load(f)
    return config


def read_file(file: str):
    with open(file, "r") as f:
        file = f.read()
    return file


def check_agent(user_agent: str, sh: str = None) -> str or None:
    keys = read_config()["settings"]["agents"].keys()
    if sh is not None:
        if sh in keys:
            return sh
    for shell in read_config()["settings"]["agents"].keys():
        if shell in user_agent.lower():
            return shell
    return None


def check_token(token: str) -> bool:
    if len(read_config()["settings"]["tokens"]) == 0:
        return True
    if token in read_config()["settings"]["tokens"]:
        return True
    return False


def add_token(token: str, file: str, agent: str, request: Request):
    base_url = str(request.url).split("/")[2]
    if token is None:
        token = "no_token"
    if agent == "powershell" or agent == "pwsh":
        file = "$TOKEN = '" + token + "' \n" + file
        file = "$BASE_URL = '" + base_url + "' \n" + file
        return file
    elif agent == "bash" or agent == "curl" or agent == "wget":
        # remove the first line
        file = file.split("\n")[1:]
        file = "\n".join(file)
        file = "TOKEN='" + token + "'\n" + file
        file = "BASE_URL='" + base_url + "'\n" + file
        file = "#!/bin/bash\n" + file
        return file


def add_args(file: str, request: Request, agent: str):
    args = request.query_params
    if len(args) == 0:
        return file
    if agent == "powershell" or agent == "pwsh":
        powershell_args = "@{"
        for arg in args:
            powershell_args += "'" + arg + "'='" + args[arg] + "',"
        powershell_args = powershell_args[:-1] + "}"
        file = "$ARGS = " + powershell_args + "\n" + file
    elif agent == "bash" or agent == "curl" or agent == "wget":
        bash_args = "declare -A ARGS\n"
        for arg in args:
            bash_args += "ARGS[" + arg + "]='" + args[arg] + "'\n"
        bash_args = bash_args[:-1]
        file = file.split("\n")[1:]
        file = "\n".join(file)
        file = bash_args + "\n" + file
        file = "#!/bin/bash\n" + file
    return file


def get_files(request: Request):
    origin = str(request.url).split("/")[2]
    config = read_config()
    runfile = list(read_config()["files"].keys())
    agents = {file: list(config["files"][file]["agents"].keys()) for file in config["files"]}
    return {
        "base_url": origin,
        "names": runfile,
        "agents": agents,
        "files": config["files"],
    }


@app.get("/files")
async def root(request: Request):
    return get_files(request)


@app.get("/files/{token}")
async def root(request: Request, token: str = None):
    origin = str(request.url).split("/")[2]
    config = read_config()
    if config["settings"]["token_required"] and token is not None:
        if not check_token(token):
            return {"message": "Invalid token"}
    return get_files(request)


@app.get("/{file}")
async def root(request: Request, file: str):
    config = read_config()
    if config["settings"]["token_required"]:
        return {"message": "Invalid token"}
    return get_response(request, file)


@app.get("/{file}/{shell}")
async def root(request: Request, file: str, shell: str = None):
    config = read_config()
    user_agent = request.headers.get("user-agent")
    agent = check_agent(user_agent, shell)
    if agent is None:
        return {"message": "This is not a supported agent", "agent": user_agent}
    if config["settings"]["token_required"]:
        return {"message": "Invalid token"}
    return get_response(request=request, file=file, shell=shell)


@app.get("/{file}/{shell}/{token}/")
async def root(request: Request, file: str, shell: str = None, token: str = None):
    return get_response(request=request, file=file, token=token, shell=shell)


def get_response(request: Request, file: str, shell: str = None, token: str = None):
    config = read_config()
    user_agent = request.headers.get("user-agent")
    agent = check_agent(user_agent, shell)
    if agent is None:
        return {"message": "This is not a supported agent", "agent": user_agent}
    if config["settings"]["token_required"]:
        if not check_token(token):
            return {"message": "Invalid token"}

    if file == config["settings"]["hub_file"]:
        raw_file = read_file(
            config["settings"]["local_prefix"] + "/" +
            config["settings"]["hub_file"] + "." +
            config["settings"]["agents"][agent]["extension"]
        )
        raw_file = add_args(raw_file, request, agent)
        return add_token(token, raw_file, agent, request)

    if file not in config["files"].keys():
        return {"message": "File not found"}

    if agent not in config["files"][file]["agents"].keys():
        return {"message": "This agent is not supported for this file"}

    if config["files"][file]["agents"][agent]["local"]:
        # return in raw format
        raw_file = read_file(config["files"][file]["agents"][agent]["path"])
        raw_file = add_args(raw_file, request, agent)
        raw_file = add_token(token, raw_file, agent, request)
        return raw_file
    else:
        response = requests.get(config["files"][file]["agents"][agent]["path"])
        if response.status_code != 200:
            return {"message": "File not found"}
        raw_file = response.text
        raw_file = add_args(raw_file, request, agent)
        raw_file = add_token(token, raw_file, agent, request)
        return raw_file
