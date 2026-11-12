/*===============================================================================
    Project        : A simple open.mp base gamemode
    Author         : Mido
    Date           : June 11, 2025
    Target Server  : open multiplayer (open.mp)

    Description    :
    --------------------------------------------------------------------
    This is a simple yet useful base for an open.mp gamemode.  Its purpose
    is to assist new scripters, whether they're just getting started or
    returning to the SA:MP scene after a break.

    For additional details, refer to the README.md file.

    Dependencies   :
    --------------------------------------------------------------------
    - open.mp server (latest version)
    - Plugin: MySQL by maddinat0r and blueG (R41-4)
    - Plugin: BCrypt by Sreyas-Sreelal (0.4.1)
    - Library: YSI by Y_Less (v5.10.0006)

    Thanks to      :
    --------------------------------------------------------------------
    - SA:MP and open.mp Teams past, present and future.
    - Mido - Writing this gamemode.
    - Kevin - Highly constructive suggestions and insights.
    - itsneufox - Testing the script.

    Repository     :
    --------------------------------------------------------------------
    - GitHub: https://github.com/midosvt/omp-base-script

===============================================================================*/

//-----------------------------------------------------------------------------
// Predefinitions
//-----------------------------------------------------------------------------

// Redefine `MAX_PLAYERS` to match our player slot.  This value must align with
// the `max_players` setting in the `config.json` file to prevent any issues.
#define MAX_PLAYERS (50)

// Allows both American and British English spellings.  It is required to
// preserve compatibility with how it was in SA:MP.
#define MIXED_SPELLINGS

//-----------------------------------------------------------------------------
// Script Dependencies
//-----------------------------------------------------------------------------

// Core
#include <open.mp>

// Plugins
#include <a_mysql>
#include <samp_bcrypt>
#include <cef>

// YSI
#include <YSI_Coding\y_hooks>
#include <zcmd>

//-----------------------------------------------------------------------------
// Script Modules
//-----------------------------------------------------------------------------

// Definitions and Utilities
#include "modules/utils/colors.pwn"
#include "modules/utils/dialogs.pwn"
#include "modules/utils/shownotifytext.pwn"

// Server
#include "modules/core/server/database.pwn"
#include "modules/core/server/settings.pwn"
#include "modules/core/player/cef/state.pwn"

// Player Account + Characters
#include "modules/core/player/account/utils.pwn"

#include "modules/core/player/character/utils.pwn"
#include "modules/system/admin/data.pwn"
#include "modules/core/player/chat.pwn"
#include "modules/core/player/character/cinematic.pwn"
#include "modules/core/player/character/creator.pwn"
#include "modules/core/player/stats.pwn"
#include "modules/core/player/character/selector.pwn"
#include "modules/core/player/character/core.pwn"

#include "modules/core/player/account/core.pwn"
#include "modules/core/player/cef/core.pwn"

#include "modules/system/job/data.pwn"
#include "modules/system/job/persistence.pwn"
#include "modules/system/job/core.pwn"

#include "modules/system/job/pizza/data.pwn"
#include "modules/system/job/pizza/vehicle.pwn"
#include "modules/system/job/pizza/ui.pwn"
#include "modules/system/job/pizza/core.pwn"
#include "modules/system/job/pizza/commands.pwn"



#include "modules/system/job/commands.pwn"

#include "modules/system/admin/persistence.pwn"
#include "modules/system/admin/commands.pwn"
#include "modules/system/help/commands.pwn"

// Character-owned vehicles.
//
// The previous vehicle implementation is kept in
// modules/system/vehicles/ as a legacy reference, but is not included here.
// Start with the small load/list flow and add features one at a time.
#include "modules/system/vehicles/simple.pwn"
#include "modules/system/vehicles/controls.pwn"
#include "modules/system/inventory/core.pwn"
#include "modules/system/inventory/weapons.pwn"

// This fallback must remain after every command module.
#include "modules/system/help/unknown.pwn"

