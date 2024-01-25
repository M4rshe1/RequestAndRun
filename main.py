import json
from fastapi import FastAPI
from starlette.requests import Request
from fastapi.responses import RedirectResponse

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


def add_token(token: str, file: str, agent: str):
    if token is None:
        token = "no_token"
    if agent == "powershell":
        return "$TOKEN = '" + token + "' \n" + file
    elif agent == "bash" or agent == "curl" or agent == "wget":
        return "TOKEN='" + token + "' \n" + file


@app.get("/files")
async def root(request: Request):
    origin = str(request.url).split("/")[2]
    config = read_config()
    runfile = list(read_config()["files"].keys())
    agents = [{file: list(config["files"][file].keys())} for file in config["files"]]
    return {
        "base_url": origin,
        "names": runfile,
        "agents": agents
    }


@app.get("/files/{token}")
async def root(request: Request, token: str = None):
    origin = str(request.url).split("/")[2]
    config = read_config()
    if config["settings"]["token_required"] and token is not None:
        if not check_token(token):
            return {"message": "Invalid token"}
    runfile = list(read_config()["files"].keys())
    agents = [{file: list(config["files"][file].keys())} for file in config["files"]]
    return {
        "base_url": origin,
        "names": runfile,
        "agents": agents
    }


@app.get("/{file}")
async def root(request: Request, file: str):
    config = read_config()
    if config["settings"]["token_required"]:
        return {"message": "Invalid token"}
    return response(request, file)


@app.get("/{file}/{shell}")
async def root(request: Request, file: str, shell: str = None):
    config = read_config()
    user_agent = request.headers.get("user-agent")
    agent = check_agent(user_agent, shell)
    if agent is None:
        return {"message": "This is not a supported agent", "agent": user_agent}
    if config["settings"]["token_required"]:
        return {"message": "Invalid token"}
    return response(request=request, file=file, shell=shell)


@app.get("/{file}/{shell}/{token}/")
async def root(request: Request, file: str, shell: str = None, token: str = None):
    return response(request=request, file=file, token=token, shell=shell)


def response(request: Request, file: str, shell: str = None, token: str = None):
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
            config["settings"]["agents"][agent]
        )
        return add_token(token, raw_file, agent)

    if file not in config["files"].keys():
        return {"message": "File not found"}

    if agent not in config["files"][file].keys():
        return {"message": "THis agent is not supported for this file"}

    if config["files"][file][agent]["local"]:
        # return in raw format
        return read_file(config["files"][file][agent]["path"])
    else:
        # return redirect
        return RedirectResponse(
            config["files"][file][agent]["path"]
        )
