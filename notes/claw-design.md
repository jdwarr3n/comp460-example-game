# Claw 460: design and testing notes

How I went about building this game, written as I go. What the game is and the build
phases are in [claw-plan.md](claw-plan.md). This file is about the thinking behind them:
what I tried, why, and what happened.

## My approach

- **Plan first, with Claude.** I start with a modestly detailed plan, written before any
  code. It's detailed enough to build from, and it can change as I learn.
- **Get to the hardest question early.** Find the thing most likely to kill the project
  and test it as soon as possible. Here that question is: can we realistically simulate
  a claw picking up a ball?
- **Build in phases, each with a done test.** A phase isn't done until I can say what I
  saw that proves it.
- **Add one thing at a time.** One ball before other shapes, and other shapes before a
  pile. When something breaks, I know what caused it.
- **Play it myself.** Claude can check that the code runs. Only I can tell whether it's
  fun.

## Choosing the game

1. **I gave general parameters and asked for three suggestions.** 2D, single player,
   something that exercises Godot's physics engine, Claude-generated art, several
   levels, and a UI. Two of the three involved tethers, which seems to be a favorite of
   LLMs.
2. **I suggested a claw game, based on Claude's crane proposal.** It was better than any
   of the three: everyone knows the rules, the prizes make good art, and each machine
   can be a level. Real claw machines often run a weak grip on purpose, so a hidden grip
   strength fits too. After checking that Godot handles 3D well, I changed my mind about
   2D, and went with 3D and rigid objects first, with plush toys later if that works.
3. **I wrote a moderately detailed design, and Claude suggested updates.** I laid out the
   cabinet, the mouse and keyboard controls, the camera on a sphere, and five phases.
   Claude suggested changes, including adding the prize chute from the start, aiming the
   claw with a ray so the controls work from any camera angle, a marker to show where the
   claw will land, and sending the claw back to the chute on its own.

The idea and the design were mine. Claude's part was options to react to and a critical
read of what I wrote.

## Testing the hardest thing first

Claude suggested reordering the steps to reach the crucial test as soon as possible: a
claw and a ball on a plain floor, before the cabinet or the mouse aiming. The game depends
on whether picking up the ball is feasible and how skillful you need to be to succeed, so
that test became Phase 0. If it fails, I've lost very little.

Skill can be measured. Instead of only playing it, we run the grab automatically from a
range of aiming errors and plot the success rate. A good game needs a curve: a careful
player should usually succeed, and a careless one should usually fail. If every grab works
or none do, there's no game.

## Hold and release, and a slack cable

A real claw machine has one drop button: press it once and the machine does the rest.
Claude recommended starting that way because it's simpler. I chose hold and release, which
gives the player timing as a skill, and because it allows the cable to go slack. That
changed the design: instead of code moving the claw down, the claw hangs from a carriage
on a cable, the way a real machine works. It can rest on an object, which opens up ways
to manipulate that behavior, and it swings without any extra work.

I discussed the claw's behavior with Claude extensively before experimenting with its
motion in Godot: how real claws work, what the prongs do on the way down, what happens if
the player never releases, and what happens when the claw lands on something. Talking is
cheap compared with rebuilding, and the slack cable idea came out of that conversation.

## Build notes

One entry per phase: what I tried, the prompts that worked, what went wrong, and how long
it took.

### Phase 0: Grip test

I chose to build the prototype first and run the automated tests after it works, and to
build one small piece at a time so I can watch it grow in Godot.

**Piece 1: floor, light, camera, and a falling ball.** Claude wrote the project and the
scene. The ball fell and came to rest exactly on the floor. Claude can also have Godot
save a screenshot and look at it, so it can check what the scene looks like.

**Piece 2: the claw.** A hub on a cable, with three fingers on real hinges, locked for now,
so the same claw can close in piece 4. On the first run the ball stayed in the air: it
started on top of the new hub. Claude caught that from the numbers it printed and moved the
ball under the claw. I can press R to restart.

**Piece 3: cable and descent.** The claw became a hanging physics body, with a carriage above
it. A short script makes the cable pull but never push. Claude tested two cases. With the
ball centered, the claw descended around it to the cable's full length without touching
it. With the ball off center, a prong landed on it, the claw stopped, and the cable went
slack with no special rule. For now the claw is locked upright and can't move sideways. The
cable is only a drawn line with no physics, bowed out when slack.

**Piece 4: closing and lifting.** Each finger got a hinge motor, and its force limit became
a Grip Strength setting. The first run closed the fingers the wrong way: Claude had
assumed the hinge's direction, and the printed angles showed it. After flipping that, the
claw picked up a centered ball and carried it to the top. At grip strengths 0.1 and 1 the
ball held. At 5 the claw squeezed the ball out and shot it across the floor, so there's
such a thing as too much grip. The fingers cross under the ball and cradle it, so this may
turn out to be too easy, which the automated tests will show. The answer to the hardest
question so far is yes, for the easiest case.

Watching the test runs gave me a design idea. The strongest grip squeezed the ball out and
shot it across the floor, which was hilarious. Grip strength could be the game's difficulty
setting, and a failed grab can still be fun to watch.

When I played it myself, the ball shot out after about 10 seconds in the claw. It was
hilarious, and random slipping would make the game more intense. Claude's tests held the
ball for 30 seconds at four grip strengths, so we haven't reproduced it yet. The idea we
took from it is a deliberate slip: fade the grip by a random amount during the carry, as
real machines do.

**First off-center tests.** I chose to leave the ball's vibration alone for now: physics
errors will come naturally, and we can use them as the design progresses. Then we ran 12
grabs at grip strength 1, one try at each ball position. I watched them on screen.

| Offset | Toward a finger | Between two fingers |
|---|---|---|
| 0.05 | missed, launched | held |
| 0.10 | missed, launched | held |
| 0.15 | missed, pushed away | held on the outside of the claw |
| 0.20 | missed, launched | missed |
| 0.25 | missed, pushed away | missed |
| 0.30 | missed, pushed away | missed |

Direction matters more than distance. Grabs aimed between two fingers work out to about
half a ball's width off center, while grabs toward a finger failed even when nearly centered,
sometimes firing the ball off the floor. A centered ball worked in the earlier tests.

At offset 0.15 the ball stuck to the outside of the claw, which I wanted to see again. A
rerun ended in exactly the same position, so that grab is repeatable. The simulation gives
the same result from the same start, so any randomness in the game has to be added
deliberately.

I'm leaving that behavior in. Physics bugs were always going to come, and the final version
doesn't need to reproduce this one. For the record, the run that stuck the ball to the
outside of the claw used:

- Godot 4.7.2, Jolt Physics, 120 physics ticks per second.
- Ball: radius 0.15, mass 0.2, friction 0.8, bounce 0.3, starting at x 0.075, y 0.35,
  z -0.13 (offset 0.15, 60 degrees from a finger, so between two fingers).
- Claw: grip strength 1, close speed 1.5, close time 0.7, finger friction 0.9.
- Cable: pay-out speed 0.6, lift speed 0.4, maximum length 2.5.
- Timing: Space held from tick 40 to tick 230.

Bugs sometimes turn into game features. Nobody designed a prize riding up perched on the
outside of the claw, but as a player it would be a thrill. Before fixing a bug, ask whether
it makes the game more fun. See the video:
[ball-stuck-outside-claw.mp4](../bloopers/ball-stuck-outside-claw.mp4).
