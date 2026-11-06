# Exporting Claw 460 to itch.io

How to turn the game into a web build and put it on itch.io. The game is live at
https://jdwarr3n.itch.io/claw-460, and it needed no changes to the game itself.

## Make the zip

1. **Install the export templates.** In Godot, use Editor > Manage Export Templates. They must
   match the Godot version, currently 4.7.2. It's a 1.28 GB download and takes 2 GB on disk.
2. **Export.** Use Project > Export > Web, then Export Project, and save as `index.html` in an
   empty folder outside the repo. Turn off Export With Debug.
3. **Zip the folder's contents** so that `index.html` sits at the top level of the zip, not
   inside a folder. Save it as `claw-460-web.zip` in the repo folder. `*.zip` is gitignored, so
   the build stays out of the public repo.

The settings live in `export_presets.cfg`, which is in the repo. It uses the build without
threads, so itch.io needs no special server setup. Its exclude filter, `audio/claw-*`, keeps the
raw music recordings out of the build.

## Test it locally

A web build won't run from a double-click. It needs a local server, from the export folder:

```
python -m http.server 8060 --bind 127.0.0.1
```

Then open http://127.0.0.1:8060/index.html.

## What changes on the web

- **Renderer:** the web build uses Compatibility (WebGL 2), not Forward Plus. The colors are
  brighter and more saturated, the dark room turns purple-gray, and the glow is gone. I'm fine
  with that.
- **Physics:** it held 120 ticks per second with 40 prizes, with up to 39 moving at once. Jolt
  works on the web.
- **Frame rate:** about 19 fps in a maximized 4K-size window on Intel integrated graphics, and
  60 fps at 1280×720 with the pile at rest. It played fine by hand.
- **Size:** a 17.3 MB zip, which is 45.8 MB unpacked. The music was never the problem, because
  Godot compresses it on import.
- **Controls:** Tab, scroll zoom, and click work in a plain page. We haven't confirmed Tab and
  scroll zoom on itch.io.

## The first-load wait

The first load in a browser freezes the page for 20 to 30 seconds before the game appears. We
measured 19 to 25 seconds in a new Chrome profile and about 30 in Firefox. Later loads are fast,
and the worst pause drops to under a second. It's probably shader compiling, which has to happen
on the player's machine, but we haven't proven that.

So the page shows "Compiling shaders.  Please be patient (20 secs)." during the wait. The message
is in the web preset's Head Include setting, not in the game, so the desktop game doesn't have
it and no separate version is needed.

The trap: the message can only clear after the game is really running. An early version cleared
after five quick animation frames, but some of those came before the game started, and in Firefox
the message vanished after 0.3 seconds. It now ignores frames until Godot removes its loading
screen. A 60-second timeout makes sure it can't get stuck.

## Put it on itch.io

1. **Create the page.** On the Dashboard, click Create new game. Set the kind of project to HTML
   and the release status to Released. Leave the visibility on Draft.
2. **Upload** `claw-460-web.zip`, and tick "This file will be played in the browser."
3. **Set the embed options.** Choose **Click to launch in fullscreen**. Leave automatic start,
   Mobile Friendly, scrollbars, and SharedArrayBuffer off. The build has no threads, so it doesn't
   need SharedArrayBuffer.
4. **Fill in the page.** Add the description, the tags, and the statement of AI use. The
   description should list the controls, the first-load wait, and how to exit.
5. **Add the cover image.** Use `notes/itch-cover.png`, at 1260 × 1000, the same shape as itch.io's
   630 × 500. It shows up in listings, not on the game's own page.
6. **Save and test** with Save & view page. A draft is private, so test it there.
7. **Publish.** Set the visibility to Public. Public was grayed out until the page had been saved.

To update the game later, export a new zip and upload it to the same page. Players may see the
first-load wait again after an update. We haven't tested that.

## What we learned on itch.io

- **Use fullscreen launch.** We tried Embed in page at 1280 × 720, and the game was bigger than the
  window and spawned scrollbars. My display scaling makes a Chrome window only about 854 × 446 in
  browser units, so that size can't fit. Fullscreen launch fits any window.
- **Exit.** There's no in-game way out, and Esc does nothing. The browser's Back button works, and
  so does closing the tab. A quit button wouldn't help, because a page can't close its own tab and
  a Godot quit just leaves a frozen page. The description tells players how to exit.
