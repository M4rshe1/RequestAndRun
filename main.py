import json

from fastapi import FastAPI
from starlette.requests import Request
from fastapi.responses import RedirectResponse

app = FastAPI()


def read_config() -> dict:
    with open("config.json", "r") as f:
        config = json.load(f)
    return config


def read_file(file: str):
    with open(file, "r") as f:
        file = f.read()
    return file


def check_agent(user_agent: str) -> str or None:
    for shell in read_config()["settings"]["agents"].keys():
        if shell in user_agent.lower():
            return shell
    return None


def check_token(token: str) -> bool:
    if len(read_config()["settings"]["tokens"]) == 0:
        return True
    if token == read_config()["settings"]["tokens"]:
        return True
    return False


@app.get("/files/{token}")
async def root(token: str = None):
    config = read_config()
    if config["settings"]["token_required"] and token is not None:
        if not check_token(token):
            return {"message": "Invalid token"}
    runfile = list(read_config()["files"].keys())
    agents = [{file: list(config["files"][file].keys())} for file in config["files"]]
    return {
        "base_url": config["settings"]["base_url"],
        "names": runfile,
        "agents": agents
    }


@app.get("/{file}/{token}")
async def root(request: Request, file: str, token: str = None):
    config = read_config()
    user_agent = request.headers.get("user-agent")
    agent = check_agent(user_agent)
    if agent is None:
        return {"message": "This is not a supported agent", "agent": user_agent}
    if config["settings"]["token_required"]:
        if not check_token(token):
            return {"message": "Invalid token"}

    if file == config["settings"]["hub_file"]:
        file = read_file(config["settings"]["local_prefix"] + "/" +
                         config["settings"]["hub_file"] + "." +
                         config["settings"]["agents"][agent])
        raw_file = f"$TOKEN = '{token}' \n{file}"
        return raw_file

    if file not in config["files"].keys():
        return {"message": "Invalid file"}

    if config["files"][file][agent]["local"]:
        # return in raw format
        return read_file(config["files"][file][agent]["path"])
    else:
        # return redirect
        return RedirectResponse(config["files"][file][agent]["path"])
