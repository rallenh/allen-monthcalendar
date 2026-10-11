# Month Calendar (Plasma 6 desktop widget)

The whole month at a glance on the KDE Plasma desktop: week numbers, today highlighted, holidays and other
calendar events with tooltips. Flat and see-through, with the text colour chosen for contrast against the wallpaper.

Modelled on Smurfier's [LuaCalendar](http://smurfier.github.io/LuaCalendar) for Rainmeter (style "DefaultWeeks"),
with one difference that started it all: **every size and gap is derived from the font**, so changing the font or its
size scales the whole grid and keeps its proportions.

- Plugin ID: `org.allen.monthcalendar`
- License: GPL-2.0-or-later

## Features
- Month grid (6 weeks), ISO week numbers, days of the previous/next month in the accent colour.
- Today in bold with an underline; today's weekday label in bold.
- Events from Plasma's calendar event plugins (the same ones the panel clock uses):
  **Holidays** (KDE holiday database, regions selectable on the Holidays settings page) and optionally
  **Astronomical events** (moon phases, season starts). Event days are shown in their own colour (orange);
  hover over a day to see its events.
- Text colour: automatic contrast against the wallpaper (white/black or tinted), custom, or the Plasma theme colour.
  On light wallpapers the accent colours are darkened (same hue) to stay readable.
- One font family and one size for everything (font dialog in the settings); see-through, no background, no shadows.
- Mouse wheel: previous/next month. Click the header: back to the current month. Right-click: month/year navigation.
- No timers ticking: redraws at midnight and when navigating.

## Install
From a `.plasmoid` file:
```sh
kpackagetool6 -t Plasma/Applet -i org.allen.monthcalendar-v0.1.0.plasmoid    # first install
kpackagetool6 -t Plasma/Applet -u org.allen.monthcalendar-v0.1.0.plasmoid    # upgrade
systemctl --user restart plasma-plasmashell
```
From a clone of this repo:
```sh
kpackagetool6 -t Plasma/Applet -i package    # or -u to upgrade
systemctl --user restart plasma-plasmashell
```
Then right-click the desktop → **Add or Manage Widgets…** → **Month Calendar**, drag it onto the desktop, and set
the font and size in its settings (right-click → Configure).

Check the installed version:
```sh
kpackagetool6 -t Plasma/Applet -s org.allen.monthcalendar | grep -i version
```

## Build a `.plasmoid`
A `.plasmoid` is a zip of the `package` folder:
```sh
cd package && zip -r ../org.allen.monthcalendar-v0.1.0.plasmoid . && cd ..
```

## Release steps
1. Bump `"Version"` in `package/metadata.json` (0.x while in trial; 1.0.0 when stable).
2. Commit, then tag: `git tag -a v0.2.0 -m "Month Calendar 0.2.0: …"`
3. Build the `.plasmoid` (above).
4. Push: `git push origin main v0.2.0`
5. Copy the `.plasmoid` to the other machines and upgrade there (Install, above).

## Layout
```
package/metadata.json              plugin ID, name, version
package/contents/config/main.xml   settings (with defaults)
package/contents/config/config.qml settings pages (General, Events, plus the event plugins' own pages)
package/contents/ui/main.qml       the calendar
package/contents/ui/Config*.qml    settings pages
package/contents/code/contrast.js  contrast maths (WCAG relative luminance)
```
