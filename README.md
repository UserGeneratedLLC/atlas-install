<div align="center">
    <img src="assets/logo-512.png" alt="Atlas" height="217" />
</div>

<div>&nbsp;</div>

<div align="center">
    <b>Atlas</b> lets you build Roblox games using <b>Cursor</b> and <b>VS Code</b><br>
    instead of working entirely inside Studio.
</div>

<hr />

Edit scripts and models on your computer, and Atlas keeps everything in sync with Roblox Studio in real time.

> **You need access to install Atlas.** The installer will ask you to sign in with GitHub. If authorization fails, ask your team lead to add you to the organization.

## Install

Run one command in your terminal:

**Mac / Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/UserGeneratedLLC/atlas-install/master/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/UserGeneratedLLC/atlas-install/master/install.ps1 | iex
```

The installer takes care of everything -- it installs any missing tools, opens your browser to sign in with GitHub, then sets up Atlas along with the Roblox Studio plugin and Cursor extension.

## Getting Started

**Already have a Roblox place?** Clone it to your computer:

```sh
atlas clone 123456789
```

Replace `123456789` with your actual Place ID. This downloads the entire place and sets up a project folder.

**Starting a new project from scratch?**

```sh
atlas init
```

**Then start working:**

```sh
atlas serve                # Start syncing with Studio
atlas studio               # Open the project in Roblox Studio
atlas cursor               # Open the project in Cursor
```

Once `atlas serve` is running, any changes you make in Cursor are automatically synced to Studio, and vice versa.

## Updating

```sh
npm update -g @usergeneratedllc/atlas
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `atlas serve` | Start live sync between your files and Studio |
| `atlas clone PLACEID` | Download a Roblox place and set up a local project |
| `atlas init` | Create a new project from scratch |
| `atlas studio` | Open the project in Roblox Studio |
| `atlas cursor` | Open the project in Cursor |
| `atlas build -o out.rbxl` | Build a `.rbxl` file from your project |
| `atlas pull` | Pull changes from a Roblox place into your project |
| `atlas install` | Reinstall the Studio plugin and Cursor extension |

## Troubleshooting

**Studio plugin not connecting?**
- Make sure `atlas serve` is running in your terminal
- Check that Roblox Studio is open

**Authorization failed during install?**
- Make sure you have access to the `@usergeneratedllc` organization on GitHub
- Try running the installer again -- it will skip steps that already completed

**Changes not syncing?**
- Make sure `atlas serve` is still running
- Try disconnecting and reconnecting the plugin in Studio

<details>
<summary>Manual installation (without the one-liner)</summary>

If you prefer to set things up yourself:

**1. Install Node.js** (version 18 or newer):

| OS | Command |
|----|---------|
| Mac | `brew install node` |
| Windows | `winget install OpenJS.NodeJS.LTS` |
| Linux | `sudo apt install nodejs npm` |

**2. Create a GitHub token** -- go to [github.com/settings/tokens/new](https://github.com/settings/tokens/new?scopes=read:packages&description=atlas-read-packages), check **`read:packages`**, and generate it.

**3. Configure npm** (run once):

```sh
npm config set @usergeneratedllc:registry https://npm.pkg.github.com
npm config set //npm.pkg.github.com/:_authToken YOUR_TOKEN
```

Replace `YOUR_TOKEN` with the token from step 2.

**4. Install Atlas:**

```sh
npm install -g @usergeneratedllc/atlas
```

**5. Set up the Studio plugin and editor extension:**

```sh
atlas install
```

</details>

## License

Copyright (c) 2025 UserGenerated LLC. All rights reserved. See [LICENSE.txt](LICENSE.txt).
