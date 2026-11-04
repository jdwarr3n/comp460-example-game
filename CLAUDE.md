# Claw 460

A 3D arcade claw machine built in Godot 4 with GDScript, as an example for Comp 460. A round
lasts 60 seconds, and the player grabs as many prizes as possible from a pile.

Read `notes/claw-plan.md` for what the game is and what's next, and `notes/claw-design.md`
for how and why it was built this way.

## Layout

- `main.tscn`, `game.gd`: the main scene, the round, and the score.
- `cabinet/`: the machine.
- `claw/`: the claw, cable, carriage movement, and the drop sequence.
- `camera/`: the camera on a sphere around the cabinet.
- `prizes/`: one scene per prize, with its value.
- `grip_test/`: the original grip test, kept as a separate scene.
- `notes/`: setup notes, the plan, the design notes, and Godot Editor basics.
- `bloopers/`: videos of funny physics.

## How we work

- Plan first. Build one small piece at a time, so the change can be seen in Godot.
- Update `notes/claw-plan.md` and `notes/claw-design.md` as decisions are made.
- Keep tuning values in `@export` variables, so they can be changed in the Inspector.
- Check your own work. Run the game from the command line, print key values, and look at a
  screenshot. Say what you tested and what you didn't.
- Measure instead of explaining. If what the player sees doesn't match the code, assume the
  player is right until a test shows otherwise.
- Before a risky change or a teardown for testing, commit first.
- Don't commit or push unless asked.
- This repo is public: no student information.

## Godot notes

- Edit scenes as text only when they're saved and not being changed in the editor.
- After files change, Godot may ask to reload. If Play turns blue and nothing happens, press
  it again.
- The hinge motors close the fingers with positive speed.
- Physics gives the same result from the same start, so randomness has to be added on purpose.
