# Los Santos Roleplay — open.mp base

A modular Pawn roleplay gamemode targeting **open.mp**. MariaDB is recommended because the SQL migrations use MariaDB's `ADD COLUMN IF NOT EXISTS` syntax. The source includes
`<open.mp>` directly and uses the open.mp server runtime. MySQL R41-4
and samp-bcrypt are legacy SA:MP plugins loaded through open.mp's compatibility
layer; YSI is a compile-time include library.

## Build

The source entry point is `gamemodes/main.pwn` and the output is
`gamemodes/main.amx`. Build scripts use the open.mp compiler bundled at
`qawno/pawncc.exe`, matched to the included open.mp headers and YSI 5.10.0006.
You can still edit source with Pawno, but its older compiler does not support
all compiler features used by this YSI version.

On Windows, run `COMPILE.bat` or press Ctrl+Shift+B in VS Code.
`RUN_LSRP.bat` installs missing MySQL, BCrypt, and YSI dependencies,
compiles the gamemode before starting, and launches `omp-server.exe`.

## Database

1. Import `database_structure.sql` to create the `lsrp`
   database and master-account table.
2. Apply every file in `database/migrations` in filename order,
   from `001` through `014`. Migration `013` adds the remaining rounds and
   equipped state for each firearm item. Apply migration `014` once with the
   server stopped before starting the updated gamemode; it maps existing ammo
   stacks to the four new groups without changing their instance IDs.
3. Copy `mysql.ini.example` to `mysql.ini` and set the hostname, username,
   database, and `server_port`. The file must be in the server root beside
   `omp-server.exe`.
4. If the MySQL account has a password, add a non-empty line such as
   `password = your_password`. If the password is empty, omit the password
   line entirely; do not use `password =`. MySQL R41-4 rejects empty option
   values in this file and returns an invalid connection handle.

The gamemode uses `mysql_connect_file()` to read `mysql.ini`.
`mysql.ini` is local configuration and is excluded from Git.

## Inventory weapons

Use `/inv` after selecting a character. An administrator can grant test items
with `/giveitem [playerid] [type] [amount]`. Item types `4` to `7` and `12` are
unique firearms (9mm, Desert Eagle, Shotgun, M4, MP5). Types `8` to `11` are
pistol, shotgun, rifle, and SMG ammunition. The 9mm and Desert Eagle share
pistol rounds. Open a gun to equip or remove it, then
choose **Nạp đạn** on the equipped gun or on the matching ammunition stack.
Loaded rounds are stored per firearm and restored after spawning. A gun can be
equipped with zero rounds; it becomes usable after reloading. The inventory
allows one gun per game weapon slot, so the 9mm and Desert Eagle replace each
other in the handgun slot.

## open.mp configuration

`config.json` loads `main.amx` and lists MySQL and
samp-bcrypt under `pawn.legacy_plugins`. Keep the server runtime and
its `components/` from the same open.mp release. RCON is disabled by
default; set a private password before enabling it.

The current repository package targets Windows x86. A Linux VPS needs the
Linux open.mp package and matching `.so` plugin builds.

## Project structure

- `gamemodes/main.pwn` — module entry point.
- `gamemodes/modules/core/` — account, character, chat, and server core.
- `gamemodes/modules/system/` — admin, jobs, vehicles, and help.
- `database/migrations/` — incremental schema for the game systems.

## Credits

- open.mp and SA:MP teams
- Mido, the original base gamemode author
- BlueG and maddinat0r, MySQL plugin
- Sys, samp-bcrypt
- Y_Less, YSI
- Kevin and itsneufox, feedback and testing
