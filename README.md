# Claw 460

A 3D arcade claw machine built in Godot with Claude, as an example for Comp 460, Advanced
Computer Game Creation, at Rice University.

**New here? Start with the [setup notes](notes/setup.md).**

## Running it

Open `project.godot` in Godot and press **F5**, then click to start. A round lasts 60 seconds,
and you grab as many prizes as you can.

- **Mouse:** aim the claw.
- **Hold the left button:** lower the claw. **Release:** close and lift.
- **Arrow keys or WASD:** orbit the camera.
- **Scroll wheel:** zoom in on the point under the mouse.
- **Q:** auto-aim, once per round.
- **Tab:** change difficulty on the start and end screens.

The original grab test is still here: open `grip_test/grip_test.tscn` and press **F6**. Hold Space
to lower the claw, release to close and lift, and press R to restart.

## Notes

- [Setup notes](notes/setup.md): getting the tools working.
- [Godot Editor basics](notes/godot-editor-basics.md): a one-page map of the editor.
- [Claw plan](notes/claw-plan.md): what we're building, in phases.
- [Claw design notes](notes/claw-design.md): how the game was designed and built, and why.
- [Claw build log](notes/claw-build-log.md): the full story, with every test and number.
- [Bloopers](bloopers/): funny physics, on video.
