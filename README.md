# `devenv-poetry`

This repo demonstrates using [devenv.sh](https://devenv.sh/) alongside [`poetry`](https://python-poetry.org/docs/) for building `Django` development environment.

Specifically,  `devenv` uses `nix` to install system level packages like `postgresql_14` from `nixpkgs` & `poetry` uses `pip` to install `Python` packages from `pypi`

> **Note**:  Also see https://github.com/nix-community/poetry2nix/ which converts `poetry` projects to `nix`,  this example uses both tools separately


---


## Installation

1. Install [`devenv.sh`](https://devenv.sh/getting-started)

2.a. Launch the database & a development server via `devenv up`

2.b. Automatically activate the environment in your shell via `direnv`

  - Install [`direnv`](https://direnv.net/docs/installation.html),  `nixpkgs` has a guide [here](https://search.nixos.org/packages?query=direnv)
  - [Add the `direnv` hook to your shell](https://direnv.net/docs/hook.html)
  - Once installed, you'll see a warning in your shell the next time you enter the project directory ...
    ```sh
    direnv: error ~/myproject/.envrc is blocked. Run `direnv allow` to approve its content
    ```

3. Create a `.env` file from `.env.example` & add your information

4. Add `SECRET_KEY` as a repository secret in `GitHub` for `GitHub Actions`


---


## Usage

`devenv` enables defining scripts in `devenv.nix` that are automatically added to the shell path ...

- Run tests via `run-tests`
- Launch a development server via `devenv up`
