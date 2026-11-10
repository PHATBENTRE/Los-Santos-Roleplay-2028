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
compiles the gamemode when `main.amx` is absent, and starts
`omp-server.exe`.

## Database

1. Import `database_structure.sql` to create the `lsrp`
   database and master-account table.
2. Apply every file in `database/migrations` in filename order,
   from `001` through `008`.
3. Copy `mysql.ini.example` to `mysql.ini` and set the hostname, username,
   password, database, and `server_port`. Leave the password blank only if
   your MySQL root account has no password.

The gamemode uses `mysql_connect_file()` to read `mysql.ini`.
`mysql.ini` is local configuration and is excluded from Git.

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
