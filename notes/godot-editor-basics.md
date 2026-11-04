# Godot Editor basics

A one-page map of the Godot editor. Claude writes the code, but you still run the game,
look at it, and tune it yourself. For anything not here, ask Claude: "What is this panel?"
works fine. If you want a full walkthrough, try Godot's
[Your first 2D game](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html)
tutorial.

## The screen

- **Center, the viewport:** the view of your scene. This is the editor's view, not the
  game's camera.
- **Top center, the tabs:** 2D, 3D, Script, and others.
- **Upper left, Scene:** the tree of parts in the current scene.
- **Lower left, FileSystem:** your project's files. `res://` means the project folder.
- **Right side, Inspector:** the settings of whatever you've selected.
- **Bottom, Output:** messages and errors from running the game.
- **Top right, Play buttons:** run the game.

If the viewport is empty, double-click a `.tscn` file in FileSystem to open a scene.

**Select objects using the Scene panel on the left, not by clicking them in the viewport.**
Clicking a 3D model often selects only its `Mesh` part, so changing its position moves the
picture of the object and not the object itself. Check the top of the Inspector to see what
you've selected.

## Moving around in 3D

Hold the **right mouse button** to look around, and press **W A S D** while holding it to
fly. The mouse wheel zooms.

## Running the game

**Stop the game, press Ctrl+S, then press F5.** Don't rely on Play to save your changes, or
you may run an older version without noticing.

Press **F5** or the Play button to run the game. Close the game window to stop it. If something goes
wrong, look in the Output panel, and paste any error into Claude.

## Four words to know

- **Scene:** a saved tree of parts, stored in a `.tscn` file. Your game is made of scenes.
- **Node:** one part in that tree, such as a camera, a light, or a ball.
- **Mesh:** what you see.
- **Collision shape:** what the physics engine uses. It's separate from the mesh, so an
  object can look like one thing and collide like another.

## Tuning a value

Click a node in the Scene tree, change a value in the Inspector, press Enter, then press
Ctrl+S and F5. This is the
fastest way to try things, and you don't need Claude for it. Use **Ctrl+Z** to undo.

## Working with Claude

Claude doesn't control the Godot editor. It changes your project's text files: scenes
(`.tscn`), scripts (`.gd`), and settings (`project.godot`). The editor shows what's in
those files, so it offers to reload after Claude changes something. Say yes.

**At the start,** let Claude do most of the building. Describe one small piece at a time,
then press F5 and look at it. Ask Claude to check its own work: it can run the game from
the command line, print key values, and look at a screenshot.

**As the game grows,** do more yourself. Claude keeps writing the scripts, while you place
things by eye and tune values in the Inspector, which is faster than asking.

Two rules keep this safe:

- Save your scene before asking Claude to change it, or one of you may overwrite the other.
- Only one person on the team works on a scene at a time, because `.tscn` files merge
  badly in Git. Splitting the game into smaller scenes helps.
