# Setup notes

These are the details behind the setup checklist in the Comp 460 email. Work through the
steps in order. If any step doesn't make sense, ask Claude to explain it to you.

## Get set up

### Step 1: Get Claude

Buy a Claude Pro subscription and keep your receipts, as the email explains.

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

Ask Claude Code to help install Git on your computer, then make a GitHub account at
[github.com](https://github.com).

Then type this in the Claude panel:

> Set my Git name and email, and help me sign in to GitHub so you can clone and push for me.

## Try Claw 460

From here on, "Claude" means Claude Code in VS Code, not Claude chat.

### Step 8: Clone this repo

Ask Claude to clone this repo into an empty folder:
<https://github.com/jdwarr3n/comp460-example-game>

### Step 9: Read the notes

Read the README and the other notes in the repo. [claw-design.md](claw-design.md) is a good
overview of the design principles I followed in building Claw 460.

### Step 10: Run Claw 460

1. In Godot's Project Manager, click **Import**.
2. Choose the `project.godot` file in the folder you cloned. If Godot's file dialog is
   hard to navigate, copy the full path and paste it in.
3. Press **F5** or the Play button.

[Godot Editor basics](godot-editor-basics.md) explains what you're looking at.

### Step 11: Change something

Ask Claude for one small change, then press Play to see it. For example:

> Make the balls green.

## Start your team repo

### Step 12: Create the team repo

One team member asks Claude to create a private team repo and add teammates as
collaborators.

### Step 13: Everyone commits

Each teammate clones it, makes one small change, and pushes, then pulls the others'
changes.

You are done when every member of your team has a commit in the team repo.

## Good to know

**Why Godot?** It gives you the game infrastructure you should not be rebuilding: a scene system,
physics, input, audio, and a renderer. It leaves the game itself for you to write. It's free, open
source, and small enough to learn in a weekend, and its scripting language, GDScript, reads like
Python. To learn more, work through the
[Getting Started](https://docs.godotengine.org/en/stable/getting_started/introduction/index.html)
section of the official docs.

**Why Git?** Employers expect to see it, and it's the only sane way for a team to work on one
codebase. It also protects you, because a laptop dies in April every year. If you've never used
it, don't worry: tell Claude to set up the repository, tell it to commit when you finish
something, and tell it what to do when two of you edit the same file.

**The `.godot/` folder.** Make sure it's in your `.gitignore`, since it's generated and large.
Claude will know.

**API keys.** Never commit an API key to your repo. Keep keys in a separate file and ask Claude
to add it to `.gitignore`. Never put a key inside a game you distribute, either: anything in the
game is public the day you ship.
