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

### Phase 1: Cabinet and viewer

With the grab working, I moved on to the easy part. Claude built the cabinet as its own
scene: a red base, felt floor, glass walls with invisible collision, a prize chute with a
hole in the floor, and a roof with a blank marquee. The camera sits on a sphere around it.
The game now starts from `main.tscn`, and the grip test stays in the project as a separate
scene.

Orbiting over the top showed a solid roof. I could have capped the camera, but I made the
top glass instead, so you can see the rails and carriage above the claw. It also gives the
player a straight-down view, which helps since aim is the main skill. The glass top wasn't
in the plan. Part of the design process is adding new features as you see what the game
could be, so a plan is a starting point, not a contract. The top view turned out to be awesome, and players will love discovering it.

### Phase 2: Claw and movement

**Piece 2a: swaying claw.** I asked for just the claw hanging partway down, so I could move
it and watch it sway, with no opening or closing yet. Claude moved the claw into its own
scene and let it swing and tilt freely on the cable. In the middle of the cabinet it swings
about every 2 seconds and dies away over about 10. The first test ran it to the edge,
where it hit the glass, lost its swing, and later got a sudden kick. Pulling the carriage's
travel limit in fixed that, but the limit now stops short of the chute, which we'll
need to solve in piece 2c.

Playing it, I found the sway awesome, but two things were wrong. Using the camera moved the
claw, which would make players mad, and I had trouble positioning it. Claude first explained
the positioning trouble as having nothing to show where the claw was, but I wasn't convinced
and questioned it. Checking turned up a possible real bug: the game was scaling a 1920 by 1080
picture to fit my window, so mouse positions and camera rays might not agree. We removed the
scaling, made the aim change only when the mouse moves, and added a green landing ring. Don't
accept an explanation just because it sounds good: if it doesn't match what you see, push back.

By playing the game, I helped catch an error in Claude's code. That's natural and important:
Claude can run the code, but only a person playing it notices that something feels wrong.

Next came a decision about controls. Pointing at the floor has a catch: after orbiting, the
next mouse movement makes the claw jump to the new spot. Claude recommended WASD relative
to the camera. I stayed with mouse pointing. Players will rotate the camera to focus on
their target and then use the mouse, and the mouse button already drops the claw. With WASD
and arrows, a player would have to move a hand between the keyboard and the mouse.

The claw and chute looked too big for the cabinet, so I enlarged the cabinet to 2.4 wide, deep,
and tall. We kept the claw at its size, because the grab was tuned there. That also solved
the earlier problem of the carriage stopping short of the chute: it now reaches the chute
corner without the claw hitting the glass.

I spent a fair bit of time double-checking the cabinet measurements. The claw's range looked
uneven to me, and Claude's first answers explained it away instead of finding out. So I had
Claude remove the top and the crane and look straight down with a camera at infinity, which
removes all perspective. Then I checked a screenshot myself, with a circle drawn around the
reticle, and we resized the chute until the reticle touched both of its walls in the corner.
The range turned out to be even. The unevenness came from the camera: its position and wide
lens make equal distances look different on screen. Checking still paid off: it pinned down
the real cause, showed that Claude's first explanation was weak, and fixed a small flaw
where the chute's walls met. Don't take an LLM's word for it. Design a test you can
check yourself.

Since the distortion would confuse players, we changed the camera lens from 75 degrees to
38 and moved the camera back to keep the same framing. The same distance on the right and
left went from 16% different on screen to 7%, and front and back went from 29% to 13%.

The reticle barely fit in the chute after that test, and a ball dropped from the claw's limit
would have hit the chute's wall. We made the chute 0.65 wide so a ball clears it.

Before building the temporary debugging version, with the top and crane removed and the
camera overhead, I had Claude commit the game. A commit gives you a safe point to come back
to, so you can tear things apart for a test without worrying about losing work.

**Piece 2b: lowering, closing, and lifting.** Hold the mouse button to lower the claw and
release to close and lift. At the top it opens, and the next turn begins. With a temporary
ball centered under the claw, a grip strength of 0.3 lifted the ball to the top, and a grip
of 1 squeezed it out, so the grab survived the move into the cabinet with the claw free to
swing. The default grip is now 0.3.

**Piece 2c: the trip to the chute.** I specified the sequence: after release, the reticle
disappears, the claw retracts, moves to the chute by itself, and releases. Then it returns
to its start. The first version missed the chute: the carriage moved at full speed, so the
claw was still swinging when it opened and flung the ball. Claude slowed the automatic trips
and made the claw wait for the swing to die down before opening. With a temporary ball, a full
cycle then worked: lift, carry, drop through the chute, and home. The ball rolled away under
the cabinet, because the base has no collision yet.

### Phase 3: One ball and playability

I asked for a ball so I could play. Claude added it, along with what makes it a game: a
prize counter, a new ball in a random spot after each win, a hidden catch under the chute,
and R to restart. In its tests, a centered grab on a settled claw won a prize, while a
drop made during the swing knocked the ball away. That's the first time this was a game.

The first thing playing showed was that the game was fun, and the reticle made it easier. It
also showed a problem: the ball could get stuck by a wall where the claw couldn't reach.
Claude suggested sloped ramps along the walls. I chose to let the claw hit the glass instead:
it's good gameplay, and the player just has to navigate the physics. I also added an
Attempts counter, so we can measure prizes against attempts.

After some close attempts and no successes, I asked for more floor friction, because the ball
rolled too far. Friction alone doesn't stop a rolling ball, so Claude added rolling damping
instead. The same push went 0.39 instead of 1.64, all the way across the cabinet.

Slower rolling helped, but waiting for the sway to die down took too long. We added a Sway
Damping setting. At 3, the claw settles about 2 seconds after the carriage stops. At the old
value it was still swinging 14 seconds later. Sway was the feature I loved earlier, but a
feature can still need tuning once you play with it.

Playing it myself, I scored 3 prizes in 9 attempts. Corners are tough, a prong once got stuck
in the glass, and with the claw centered, the ball sometimes picks up and sometimes shoots
out like a rocket. That isn't a criticism: randomness in a claw machine is fine. The physics
gives the same result from the same start, so it's tiny differences in aim and timing that
decide it, and to a player that feels like chance.

After more play, I decided that what I'd been playing should be Easy mode, and that less
damping makes a good Hard mode, so there's now an in-game setting. I dropped zoom and left the
view fully zoomed in, since nobody needs it, and added WASD as alternates to the arrow keys.

### Phase 4: Other prizes

I decided prizes should be colored by value, with hard shapes worth more: ball, cube, cylinder,
capsule, and disc, worth 1 to 5. The game cycles through them one at a time so I can see what
I can pick up. The values are a first guess until we measure how hard each shape is.

I played the five shapes and scored 2 prizes in 27 attempts, a ball and a cylinder, and it
played like a real arcade game. I got the cylinder when it was on its side. The cube looked
hard, the capsule was tough, and the disc is impossible. So I set the values from playing:
ball 1, cylinder and capsule 3, cube 10, and the gold disc 100.

I made the cube silver. The prongs were hitting the floor when the claw was fully lowered, which
caused big physics jumps. At full depth the fingertips reached within 0.01 of the floor, and
the thick fingers touched it. Claude stopped the cable a little shorter, which leaves about
0.08 of clearance. The ball, cylinder, and capsule could all still be picked up in a test.

To separate my aim from the physics, I added auto-aim on the Q key: the claw centers itself over
the prize until the attempt is over. That measures the success rate with optimal aiming.

With auto-aim, spheres worked well and everything else was very hard, and the claw seemed to stop
short. It did: stopping it higher to avoid the floor meant the fingers couldn't get under flat
things. I wanted the claw to hit the floor anyway, but with less jumpy closing. We measured
the top speeds during the close across five setups. Slowing the close made it worse. Making the
claw heavier cut the speeds about four times over, because light fingers on a light hub were being
kicked around, and in that test the claw picked up the disc for the first time. The cube is
now teal.

Then I got the gold disc, the prize I'd called impossible. The claw opens just enough to grasp
it. Nobody planned that fit: it came from sizing the claw for the ball and later making it
heavier.

I've been using only Q for now, to assess whether winning is feasible independent of player
skill. I want to be able to win with optimal play. If a prize is impossible, it's not fun. Q is a test tool for now, but we might leave it in as a secret cheat, since those are fun.

### Phase 5: A pile

Short on time, I asked for a pile of 20 shapes, distributed roughly by the log of their
values: 7 balls, 4 cylinders, 4 capsules, 3 cubes, and only 2 gold discs. Q now locks onto the
prize nearest the mouse.

The pile played nicely: 3 prizes in 8 attempts, including a coin. That led to the actual game
design. A round is 60 seconds and you grab as many prizes as you can, with one auto-aim per round.
Values dropped to 2 for cylinders and capsules, 4 for cubes, and 10 for coins, with 40 prizes
at about 1 / value. At the current speed a round is only 4 or 5 attempts. Claude suggested
speeding up the claw's trips, and I said no: the current speed generates aggravation when you
miss, and then happiness when you land one.

My first timed round scored 5, and it was fun. The timer makes you move, and four items is about
right. I replaced Points with Score, removed the prize count, added a colored table of prize
values, and put the final score in the middle of the screen. For the visuals later, the coins
should say "Comp 460" and be shiny.

I scored 14 on the next round. I had fun and felt the time pressure. The blue text was hard to read
on gray, so the prize values moved to a white panel in the upper right.
