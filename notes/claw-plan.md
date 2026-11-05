# Claw 460: game plan

A 3D arcade claw machine built in Godot with Claude. This plan was written before any
code and will grow as the game does. Single player, with rigid prizes first and plush
toys later if that works out.

## The game

The game is an arcade cabinet: a big box with transparent windows, a pile of prizes
inside, and a prize chute in one corner. A claw hangs from the top on a cable. The
player positions the claw, drops it, and tries to carry a prize to the chute. Won prizes
slide out of a slot in the front of the machine and pile up in a tray in the floor.

## Controls

- **Mouse:** moves the claw around the top of the cabinet.
- **Hold the left button:** pays out the cable, and the claw descends with its prongs open.
- **Release the button:** the descent stops, the prongs close, and the cable pulls the claw
  back up.
- **After that:** the claw travels to the chute on its own and opens. The player can't
  steer it, so a prize can slip on the way home.
- **Arrow keys or WASD:** orbit the camera around the cabinet.
- **Scroll wheel:** zooms in on the point under the mouse, and back out as far as the starting
  view.
- **Tab:** switches between Easy and Hard on the start and end screens.
- **Click:** starts from the start screen, and plays again after a round.
- **Q:** auto-aim, once per round. The claw centers over the prize and ignores the mouse until
  the attempt is over. It locks onto the prize nearest the mouse, so it works in a pile.

## Rules

A round lasts 60 seconds, starting on the first drop. Grab as many prizes as you can. You
get one auto-aim (Q) per round. A drop in progress when time runs out gets to finish.

| Prize | Value | Count of 40 |
|---|---|---|
| Ball | 1 | 17 |
| Cylinder | 2 | 9 |
| Capsule | 2 | 8 |
| Cube | 4 | 4 |
| Coin | 10 | 2 |

Counts are about 1 / value.

## How it works

- **Camera:** sits on a sphere around the cabinet, with its position set by latitude and
  longitude. It uses a narrow 38-degree lens from further back, so equal distances look
  nearly equal on screen. Latitude is clamped so it can't go under the floor or flip over the top.
- **Aiming:** a ray from the mouse cursor hits the cabinet floor, and a carriage chases that
  point at a limited speed. This keeps the controls correct from every camera angle. We
  started with a plane at the top of the cabinet, but at low camera angles that plane is
  above the camera.
- **Carriage and cable:** the carriage moves along the top of the cabinet, as on a real
  machine. The claw is a physics body hanging from it on a cable. Changing the cable's
  length is what raises and lowers the claw.
- **Slack:** the cable only pulls. If the claw lands on something, it stops and the cable
  goes slack, with no special rule. The player can use that: rest the claw on a prize,
  nudge it, or settle the prongs around it before releasing. The claw also swings when the
  carriage moves.
- **Grip:** each prong hangs on a hinge with a motor. The motor's force limit is the grip
  strength, like the solenoid in a real machine.
- **Landing marker:** a bright green ring on the floor directly below the carriage, so the
  player can see where the claw will land.
- **Aim only moves with the mouse:** orbiting the camera doesn't move the claw, so the player
  can walk around and check their aim.
- **Hands:** one hand on the arrow keys and one on the mouse. The player orbits to study the
  target, then points and holds the button to drop.
- **Glass:** the transparent windows are just for looks. Invisible collision walls keep
  the prizes in.
- **Glass top:** the roof is glass too, so the player can see the rails, gantry, and
  carriage. It also gives the player a straight-down view for judging aim. We don't point
  this out: players discover it by orbiting over the top.
- **Chute:** a real shaft through the base, with a yellow ramp that ends at a slot in the
  front. A prize scores as it enters the shaft, then slides out into a tray cut into the room
  floor and stays there until the next round.
- **Screens:** a semi-transparent overlay with the title and instructions starts the game, and
  a matching one shows the final score. Both have the difficulty line and a click prompt. The
  camera works behind them.
- **Marquee:** "CLAW 460" scrolls around all four sides of the cabinet in glowing letters, and
  dims during a round.
- **Sound:** music on the start and end screens, and one of two tracks at random during a round,
  with fades on every change. Faint motors, collision sounds, and a soft tick for the last 10
  seconds play only during a round.
- **Tuning:** grip strength, claw speed, cable swing, drop speed, and sound levels are settings
  in Godot's Inspector, so they can be changed without touching code.

## Reach

The claw can reach all the way to the glass and hit it. A ball that rolls to a wall stays in
play, and the player has to work with the physics to get it. The game counts prizes and
attempts, so prizes per attempt measures how hard it is.

## Difficulty

Easy and Hard differ in how much the physics is damped: Hard has more claw sway and a ball
that rolls further. Tab switches between them on the start and end screens.

## Biggest risk

The grip. A claw that really holds prizes through contact and friction can be finicky.
The game depends on two questions: can the claw pick up a ball at all, and how much skill
does it take? We answer both first, in Phase 0. If real contact doesn't work, the fallback
is to attach the prize to the claw with a joint that can break when shaken.

Real contact worked, so the fallback was never needed.

## Phases

Each phase ends with a done test, a screenshot, and a commit.

**Phase 0: Grip test (done).** A claw and a ball on a plain floor, with no cabinet and no mouse
aiming. This comes first so we reach the grab as soon as possible. Build it in small
pieces, watching each one in Godot:

1. Floor, light, camera, and a falling ball (done).
2. The claw: a hub and three hinged fingers hanging above the ball, plus an R key to
   restart (done).
3. Cable and descent: the claw becomes a hanging physics body. A held key pays out the
   cable, and the cable goes slack when the claw lands on the ball (done, with the claw
   locked upright and no sideways movement for now).
4. Closing and lifting. This is where we learn whether the game works (first grab done,
   with the claw locked upright and the ball centered).

Claw behavior in Phase 0, with Space standing in for the mouse button:

1. The claw hangs from a fixed carriage with its prongs open.
2. Hold Space: the cable pays out and gravity lowers the claw, prongs still open.
3. If the claw lands on the ball, it rests there and the cable goes slack. If it lands on
   nothing, the cable stops at its full length.
4. Release Space: the cable stops paying out, and the prongs close with limited force.
5. The cable pulls the claw back up, along with the ball if the prongs are holding it.
6. Press R to restart.

Try it by hand. Once the prototype works, run the grab automatically from a range of
aiming errors and measure the success rate.
*Done when:* we know whether the ball can be picked up, and how success falls off with
aiming error. A dead-center grab should usually work, and a sloppy one should usually
fail. If nothing can tune it that way, we decide between the joint fallback and a
different game.

**Phase 1: Cabinet and viewer (done).** Build the cabinet with its windows and prize chute, and
the camera. We added the glass top during this phase.
*Done when:* I can orbit and zoom around the cabinet and see the chute through the glass.

**Phase 2: Claw and movement (done).** Add the cable, the claw, mouse aiming, lowering, closing,
retracting, and the trip to the chute.
Built in pieces: (a) the claw hanging in the cabinet, with the mouse moving the carriage and
real sway (done), (b) lowering, closing, and lifting (done), (c) the trip to the chute, opening, and returning
home (done). The reticle disappears once the player releases the
button and comes back for the next turn.
*Done when:* from any camera angle, the claw goes where I point, and a full cycle runs
from drop to chute.

**Phase 3: One ball and playability (done).** Add a single ball in the cabinet and tune the grip
found in Phase 0. Add a counter that goes up when the ball lands in the chute.
*Done when:* grabbing the ball feels good, it's possible but not guaranteed, and the
counter works.

**Phase 4: Other objects (done).** Add a cylinder, capsule, cube, and gold coin, testing one
at a time. Rules has the final values.
*Done when:* each new shape can be grabbed and dropped without strange behavior.

**Phase 5: A pile (done).** See Rules. Fill the cabinet with a pile of objects.
*Done when:* the pile settles without jitter, and the game still runs smoothly and plays
well.

**Polish (done).**

- **Materials and lighting:** stamped gold coins, new materials and reflections, and tile floor.
- **Chute:** a real shaft with a ramp, front slot, and prize tray.
- **Marquee:** scrolling text on all four sides, dimmed during a round.
- **Camera:** scroll wheel zoom.
- **UI:** start and end overlays, with time, score, attempts, auto-aim, and level upper left, and
  prize values upper right. Difficulty changes between games.
- **Sound:** music, motors, collisions, and a soft countdown.

**Later phases.** More kinds of objects, plush toys, and several machines as levels.

Difficulty could also come from grip strength, with each level or machine using a different
grip. Grip works in both directions: too weak and the prize slips out, too strong and the claw
squeezes it out. Automated tests would show which values give an easy game and which give a hard
one.

A prize that might slip adds tension. Real machines grip hard to lift and then weaken the grip
during the carry. We could do the same: after lifting, fade the grip by a random amount, tuned
per difficulty, so a slip is a deliberate part of the game.

Each prize captured could add 5 seconds to the clock, the same for every prize. The score
already rewards valuable prizes. Show a small "+5" by the timer, so the player sees why the clock
jumped. A drop that finishes after time runs out still scores, but it doesn't restart the clock.
