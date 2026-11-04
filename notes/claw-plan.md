# Claw 460: game plan

A 3D arcade claw machine built in Godot with Claude. This plan was written before any
code and will grow as the game does. Single player, with rigid prizes first and plush
toys later if that works out.

## The game

The game is an arcade cabinet: a big box with transparent windows, a pile of prizes
inside, and a prize chute in one corner. A claw hangs from the top on a cable. The
player positions the claw, drops it, and tries to carry a prize to the chute.

## Controls

- **Mouse:** moves the claw around the top of the cabinet.
- **Hold the left button:** pays out the cable, and the claw descends with its prongs open.
- **Release the button:** the descent stops, the prongs close, and the cable pulls the claw
  back up.
- **After that:** the claw travels to the chute on its own and opens. The player can't
  steer it, so a prize can slip on the way home.
- **Arrow keys:** orbit the camera around the cabinet.
- **Scroll wheel:** zoom.

## How it works

- **Camera:** sits on a sphere around the cabinet, with its position set by latitude and
  longitude. Latitude is clamped so it can't go under the floor or flip over the top.
- **Aiming:** a ray from the mouse cursor hits a horizontal plane at the top of the
  cabinet, and a carriage chases that point at a limited speed. This keeps the controls
  correct from every camera angle.
- **Carriage and cable:** the carriage moves along the top of the cabinet, as on a real
  machine. The claw is a physics body hanging from it on a cable. Changing the cable's
  length is what raises and lowers the claw.
- **Slack:** the cable only pulls. If the claw lands on something, it stops and the cable
  goes slack, with no special rule. The player can use that: rest the claw on a prize,
  nudge it, or settle the prongs around it before releasing. The claw also swings when the
  carriage moves.
- **Grip:** each prong hangs on a hinge with a motor. The motor's force limit is the grip
  strength, like the solenoid in a real machine.
- **Landing marker:** a shadow or small marker on the floor directly below the claw, so
  the player can judge depth.
- **Glass:** the transparent windows are just for looks. Invisible collision walls keep
  the prizes in.
- **Glass top:** the roof is glass too, so the player can see the rails, gantry, and
  carriage. It also gives the player a straight-down view for judging aim. We don't point
  this out: players discover it by orbiting over the top.
- **Tuning:** grip strength, claw speed, cable swing, and drop speed are settings in
  Godot's Inspector, so they can be changed without touching code.

## Difficulty

Difficulty will likely be set by grip strength. Each difficulty level, or each machine,
uses a different grip. Grip works in both directions: too weak and the prize slips out, too
strong and the claw squeezes it out. The automated tests will show which values give an
easy game and which give a hard one.

A prize that might slip adds tension. Real machines grip hard to lift and then weaken the
grip during the carry. We can do the same: after lifting, fade the grip by a random amount,
tuned per difficulty, so a slip is a deliberate part of the game.

## Biggest risk

The grip. A claw that really holds prizes through contact and friction can be finicky.
The game depends on two questions: can the claw pick up a ball at all, and how much skill
does it take? We answer both first, in Phase 0. If real contact doesn't work, the fallback
is to attach the prize to the claw with a joint that can break when shaken.

## Phases

Each phase ends with a done test, a screenshot, and a commit.

**Phase 0: Grip test.** A claw and a ball on a plain floor, with no cabinet and no mouse
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
the camera.
*Done when:* I can orbit and zoom around the cabinet and see the chute through the glass.

**Phase 2: Claw and movement.** Add the cable, the claw, mouse aiming, lowering, closing,
retracting, and the trip to the chute.
*Done when:* from any camera angle, the claw goes where I point, and a full cycle runs
from drop to chute.

**Phase 3: One ball and playability.** Add a single ball in the cabinet and tune the grip
found in Phase 0. Add a counter that goes up when the ball lands in the chute.
*Done when:* grabbing the ball feels good, it's possible but not guaranteed, and the
counter works.

**Phase 4: Other objects.** Add other shapes, testing one at a time.
*Done when:* each new shape can be grabbed and dropped without strange behavior.

**Phase 5: A pile.** Fill the cabinet with a pile of objects.
*Done when:* the pile settles without jitter, and the game still runs smoothly and plays
well.

**Later phases.** Menus, sound, better arcade-style visuals, more kinds of objects, plush
toys, and several machines as levels.
