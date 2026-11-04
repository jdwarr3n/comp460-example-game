# Setup notes

These are the details behind the setup checklist in the Comp 460 email. Work through the
steps in order. If any step doesn't make sense, ask Claude to explain it to you.

These notes are still being written. Steps 1 to 4 have been tried on Windows; the rest
have not been tested yet.

## Get set up

### Step 1: Get Claude

Use a Claude Pro subscription or your Rice account, as the email explains.

### Step 2: Visit Claude chat

Go to [claude.ai](https://claude.ai) and sign in. Keep it handy for questions.

### Step 3: Install VS Code

1. Go to [code.visualstudio.com](https://code.visualstudio.com) and download VS Code.
2. **On Windows:** run the installer, accept the license, keep the default options, and
   click Install. Leave "Launch Visual Studio Code" checked and click Finish.

   **On a Mac:** open the download and drag Visual Studio Code into Applications, then
   open it. (The Mac path has not been tested yet.)

VS Code will offer you GitHub Copilot, which is a different AI assistant. We use Claude
Code, so skip it:

- Say no to the GitHub Copilot CLI.
- If VS Code asks you to continue with GitHub, choose **Continue without Signing in**.
- Ignore the **Build with Agent** panel, which is Copilot's chat.

Stuck? Ask [Claude chat](https://claude.ai), and paste in any error message.

### Step 4: Install the Claude Code extension

1. Open **View > Extensions**.
2. Search for "Claude Code."
3. Install **Claude Code for VS Code**, and check that the publisher is **Anthropic**.
   Other extensions have similar names.
4. Open a folder with **File > Open Folder**, then open a file.
5. Click the orange asterisk at the top right.
6. Sign in with your Claude account in the browser window that opens.

**No orange asterisk?** Look for a **Restricted Mode** message or button at the lower
left. Click it and switch to trusted mode. Claude Code doesn't appear in Restricted Mode.

**Still no asterisk?** This always works: choose **View > Command Palette**, then
**Claude Code: Open in New Tab**.

Stuck? Ask [Claude chat](https://claude.ai), and paste in any error message.

**Which Claude model?** Use Sonnet for normal work and Opus for tough work, such as design
questions or a bug Sonnet can't fix. To switch, click the model name in the Claude panel
and choose from the list. All the setup steps below are normal work.

### Step 5: Install Godot

Let Claude Code do this one. It's much easier than installing Godot by hand. Type this
in the Claude panel:

> Install the latest standard version of Godot 4 on this computer, not the .NET version.
> Then make sure I can launch it from the Start menu or Applications.

Godot is a small portable app, so it may not add a shortcut on its own. That's why the
prompt asks for one. Check that it opens to the Project Manager window.

### Step 6: Install godot-tools

Type this in the Claude panel:

> Install the godot-tools extension in VS Code and point it at my Godot install.

Pointing it at Godot matters, because the extension won't find Godot on its own after
this kind of install. Reload VS Code if the extension doesn't show up.

### Step 7: Install Git and make a GitHub account

Ask Claude Code to help install Git on your computer, then make a GitHub account.

## Try the example game

From here on, "Claude" means Claude Code in VS Code, not Claude chat.

### Step 8: Clone this repo

Ask Claude to clone this repo into an empty folder:
<https://github.com/jdwarr3n/comp460-example-game>

### Step 9: Read the notes

Read the README and the other notes in the repo.

### Step 10: Run the game

1. In Godot's Project Manager, click **Import**.
2. Choose the `project.godot` file in the folder you cloned. If Godot's file dialog is
   hard to navigate, copy the full path and paste it in.
3. Press **F5** or the Play button.

[Godot Editor basics](godot-editor-basics.md) explains what you're looking at.

### Step 11: Change something

Ask Claude for one small change, then press Play to see it.

## Start your team repo

### Step 12: Create the team repo

One team member asks Claude to create a private team repo and add teammates as
collaborators.

### Step 13: Everyone commits

Each teammate clones it, makes one small change, and pushes, then pulls the others'
changes.

You are done when every member of your team has a commit in the team repo.
