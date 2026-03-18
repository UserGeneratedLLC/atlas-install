# Atlas Installer

> **Access required.** Atlas is a private tool distributed via GitHub Packages. The install scripts in this repository will **fail** unless you have been granted `read:packages` access to the `@usergeneratedllc` organization. If you do not have access, contact your team lead.

## One-Line Install

**macOS / Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/UserGeneratedLLC/atlas-install/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/UserGeneratedLLC/atlas-install/main/install.ps1 | iex
```

## What the Script Does

1. **Installs git** if not already present (Homebrew on macOS, winget on Windows, apt/dnf/pacman on Linux)
2. **Installs Node.js >= 18** if not already present (same package managers; NodeSource LTS on Debian/Ubuntu)
3. **Configures npm for GitHub Packages** -- opens your browser to create a Personal Access Token with `read:packages` scope, then saves it to `~/.npmrc`
4. **Installs Atlas globally** via `npm install -g @usergeneratedllc/atlas`
5. **Installs the Roblox Studio plugin and Cursor/VS Code extension** via `atlas install`

The script is idempotent -- running it again skips anything already set up.

## After Installation

```sh
atlas clone PLACEID        # Clone an existing Roblox place
atlas init                 # Create a new project from scratch
atlas serve                # Start live sync to Roblox Studio
atlas studio               # Open the project in Roblox Studio
atlas cursor               # Open the project in Cursor
```

## Manual Installation

If you prefer not to use the one-liner, follow these steps:

### 1. Install Prerequisites

<details>
<summary>macOS</summary>

```sh
brew install git node
```

</details>

<details>
<summary>Windows (PowerShell)</summary>

```powershell
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
```

</details>

<details>
<summary>Linux (Debian / Ubuntu)</summary>

```sh
sudo apt update && sudo apt install -y git
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

</details>

<details>
<summary>Linux (Fedora / RHEL)</summary>

```sh
sudo dnf install -y git
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
sudo dnf install -y nodejs
```

</details>

<details>
<summary>Linux (Arch)</summary>

```sh
sudo pacman -Sy --noconfirm git nodejs npm
```

</details>

### 2. Configure npm for GitHub Packages

Go to [github.com/settings/tokens/new](https://github.com/settings/tokens/new?scopes=read:packages&description=atlas-read-packages), select **`read:packages`**, and generate a token. Then run:

```sh
npm config set @usergeneratedllc:registry https://npm.pkg.github.com
npm config set //npm.pkg.github.com/:_authToken YOUR_TOKEN
```

Replace `YOUR_TOKEN` with the token you just created.

### 3. Install Atlas

```sh
npm install -g @usergeneratedllc/atlas
```

### 4. Install the Studio Plugin and Editor Extension

```sh
atlas install
```

## Updating

```sh
npm update -g @usergeneratedllc/atlas
```

## License

Copyright (c) 2025 UserGenerated LLC. All rights reserved. See [LICENSE.txt](LICENSE.txt).
