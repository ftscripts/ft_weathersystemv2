# ft_weathersystem

Synced weather and time for all players, with an admin dashboard.

## Requirements

| Resource | Needed for |
|---|---|
| oxmysql | saving across restarts (mysql-async and ghmattimysql also work) |
| es_extended or qb-core | admin groups — not needed if you use ACE instead |

Runs standalone. Without a database it falls back to FiveM KVP, so settings still survive a restart.

## Install

**1. Add the resource**

Drop the `ft_weathersystem` folder into your resources, then add to `server.cfg`:

```
ensure ft_weathersystem
```

**2. Database**

Nothing to import. The table is created automatically on first start.

To turn saving off, set `Config.SaveToDatabase = false` in `shared/config.lua`.

**3. Give staff access**

Any one of these works — the script checks all three:

- Framework group: `admin`, `superadmin` or `god` (`Config.AdminGroups`)
- ft_adminmenu permission: `weatherTab` (`Config.AdminMenu`)
- Server ACE: `add_ace group.admin ft_weather.admin allow`

## Using it

Open the dashboard with `/weatherui`.

Commands:

| Command | Does |
|---|---|
| `/weather <type>` | set weather, e.g. `/weather RAIN` |
| `/time <hour> <minute>` | set the time |
| `/freezetime` | stop the clock |
| `/freezeweather` | stop weather changing on its own |
| `/blackout` | toggle city power |
| `/morning` `/noon` `/evening` `/night` | jump to that time |

## Common settings

All in `shared/config.lua`:

| Setting | What it does |
|---|---|
| `Config.StartWeather` | weather on first ever start |
| `Config.BaseTime` | starting hour |
| `Config.TimeSpeed` | how fast the clock runs |
| `Config.DynamicWeather` | weather changes on its own |
| `Config.NewWeatherTimer` | minutes between those changes |
| `Config.RealTimeSync` | follow real world time instead |
| `Config.Framework` | `auto`, `esx`, `qb` or `standalone` |
| `Config.AvailableWeatherTypes` | list shown in the dashboard |

## Editing the UI

The dashboard is a Svelte app in `web/`. The built files in `web/dist` are what the server loads.

```bash
cd web
npm install
npm run build
```

The build writes straight into `web/dist`. Do not rename the output files in `vite.config.js` — the game caches the page and will load a blank dashboard if the names change.

## Client export for shells/interiors

Enable the local interior override when a player enters a shell. It affects only
that player: time is held at 23:00, weather becomes clear immediately, and rain
is removed. The synchronized server weather and time continue normally.

```lua
exports['ft_weathersystemv2']:SetInteriorOverride(true)
```

Disable it when the player leaves. A fresh authoritative state is requested
from the server and normal synchronization resumes.

```lua
exports['ft_weathersystemv2']:SetInteriorOverride(false)
```
