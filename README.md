# 🐧 Linux Automation & Guides

A collection of `guides` and `automation` scripts to make setting up, fixing, and troubleshooting Linux tools easier. This is my personal toolkit—a digital Swiss Army knife—to save time, cut down on repetitive tasks, and help my future self when I inevitably forget how I solved something. If it helps you too, even better!

---

## 📂 Repository Structure

Each folder includes:

- **📝 Markdown Guides (`.md`)**: Clear, step-by-step instructions for setups and solutions.
- **⚙️ Shell Scripts (`.sh`)**: Automation to cut down on manual work.

Organized by tool or task—simple to find, simpler to use.

---

## 🔧 What’s Inside

- **[`cursor-ide-setup/`](./cursor-ide-setup/)**: Setup and fixes for the Cursor IDE

  - **What It Solves**: A common annoyance on GNOME (and likely other distros—I’ve only faced it on Fedora) is Cursor running with _`double title bars`_—one from GNOME, one from Cursor itself. I whipped up a script to nix that native title bar hassle.
  - **Guide**: [`installation-guide.md`](./cursor-ide-setup/installation-guide.md) – How to install and troubleshoot Cursor on Linux.
  - **Script**: [`cursor-setup.sh`](./cursor-ide-setup/cursor-setup.sh) – Automates Cursor AppImage setup with custom fixes, like killing that extra title bar.

- _`More scripts and guides will pop up whenever I run into something frustrating enough to automate.`_

---

## 🚀 How to Use

1. **Read the Guides**: Dive into the `.md` files for detailed steps.
2. **Run the Scripts**: Fire them up with `bash script-name.sh` (make sure to `chmod +x script-name.sh` first).
3. **Tweak as Needed**: Fork or adjust to match your setup.

Most of this is tested on **Fedora** (GNOME, x86_64) since that’s my daily driver, but the logic should work across different distros with minor tweaks.

---

## 📌 Contributions

This is my personal sandbox, but feel free to:

- **Fork It**: Customize it for yourself.
- **Drop Ideas**: Open an issue if you’ve got a neat script or fix to suggest.

I’m not chasing formal contributions—this is my space—but I’m stoked if it sparks something for you!

---

## 🌟 Why This Exists

I put this together to save myself time and frustration. Instead of Googling the same problem five times, now I have a place to document fixes and automate the annoying stuff. And since I forget things like any normal human, this is also a way to help my future self.

_`Happy automating! 🐧`_
