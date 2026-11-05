# Claw 460: design notes

How I built a 3D arcade claw machine with Claude in seven hours, and what I learned. What the
game is and how it works are in [claw-plan.md](claw-plan.md). The full story, with every test
and number, is in [claw-build-log.md](claw-build-log.md).

## My approach

- **Plan first, with Claude.** I start with a modestly detailed plan, written before any
  code. It's detailed enough to build from, and it can change as I learn.
- **Get to the hardest question early.** Find the thing most likely to kill the project
  and test it as soon as possible.
- **Build in phases, each with a done test.** A phase isn't done until I can say what I
  saw that proves it.
- **Add one thing at a time.** One ball before other shapes, and other shapes before a
  pile. When something breaks, I know what caused it.
- **Play it myself.** Claude can check that the code runs. Only I can tell whether it's
  fun.

## Choosing the game

I gave Claude general parameters and asked for three suggestions. None was right, but a crane
idea led me to a claw game: everyone knows the rules, the prizes make good art, and real claw
machines run a weak grip on purpose. After checking that Godot handles 3D well, I switched from
2D to 3D.

I then wrote a moderately detailed design, and Claude suggested changes, including aiming the
claw with a ray so the controls work from any camera angle, and a marker showing where the claw
will land. The idea and the design were mine. Claude's part was options to react to and a
critical read of what I wrote.

Talking is cheap compared with rebuilding. The hanging claw and slack cable, which make the game
feel real, came out of a conversation before any code was written.

## Testing the hardest thing first

The game depends on one question: can we realistically simulate a claw picking up a ball? So
Claude suggested reordering the steps to reach that test first: a claw and a ball on a plain
floor, with no cabinet and no mouse aiming. If it had failed, I'd have lost very little.

Skill can be measured too. A good game needs a curve: a careful player should usually succeed,
and a careless one should usually fail. Twelve test grabs showed that direction mattered more
than distance. Aiming between two fingers worked well off center, while aiming toward a finger
failed even when nearly centered.

## Lessons from the build

**Push back on explanations.** The claw's range looked uneven to me, and Claude's first answers
explained it away. I wasn't convinced, and checking found a real cause: the camera's wide lens
made equal distances look different on screen. If an explanation doesn't match what you see,
push back.

**Design a test you can check yourself.** For that same problem, I had Claude remove the top and
look straight down with no perspective, and I checked a screenshot myself with a circle drawn
around the reticle. Don't take an LLM's word for it.

**Measure one thing at a time.** My new gold coin looked very dark, so I asked whether it was the
lighting or the color. Claude changed one thing at a time and measured. The color was fine: metal
gets its brightness from what it reflects, and the coin had nothing to reflect.

**Bugs can be features.** In one test a ball stuck to the outside of the claw and rode up with
it. As a player, that would be a thrill, so I left it in. Before fixing a bug, ask whether it
makes the game more fun. See the
[video](../bloopers/ball-stuck-outside-claw.mp4).

**A plan is a starting point, not a contract.** Orbiting over the top showed a solid roof, so I
made it glass. Now you can see the machinery and aim straight down, and players get to discover
that view for themselves. Late in the build I asked whether the chute was a real tunnel. It
wasn't, so it became one, with a ramp, a slot, and a tray where your prizes pile up outside the
machine.

**Try it, then change your mind.** Seeing things beats imagining them. A spinning coin on the
start screen, a blinking sign, a 90-second round, and music that sped up at the end all got built
and all came back out. Each one took minutes.

**Commit before you tear things apart.** Before building a temporary test version, I had Claude
commit the game. That gives you a safe point to come back to.

**Some calls are only yours.** Claude can run the game, but it can't feel it or hear it. When it
suggested speeding up the claw, I said no: the slow trip generates aggravation when you miss, and
then happiness when you land one. It also couldn't judge sound, so I had it play each sound
outside the game and told it what to change.

## How long it took

Five hours from game conception to a playable game with a timer, a pile of prizes, and a score.
Polish took two more: an hour on materials and lighting, and an hour on the UI, sound, and music.
