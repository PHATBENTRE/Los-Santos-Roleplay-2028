#include <YSI_Coding\y_hooks>

#define INVENTORY_BROWSER (2030)
#define INVENTORY_SLOTS (50)
#define INVENTORY_WORLD_BAGS (300)
#define INVENTORY_BAG_MODEL (11745)
#define INVENTORY_ITEM_MAX (12)
new bool:g_InventoryOpen[MAX_PLAYERS], bool:g_InventoryBrowser[MAX_PLAYERS], bool:g_InventoryVisible[MAX_PLAYERS];
new g_InventoryRequest[MAX_PLAYERS], g_InventoryURL[MAX_PLAYERS][3200];
new g_InventoryInstance[MAX_PLAYERS][INVENTORY_SLOTS], g_InventoryType[MAX_PLAYERS][INVENTORY_SLOTS];
new g_InventoryQuantity[MAX_PLAYERS][INVENTORY_SLOTS], g_InventoryNearbyQuantity[MAX_PLAYERS][INVENTORY_SLOTS];
new g_InventoryAmmo[MAX_PLAYERS][INVENTORY_SLOTS], bool:g_InventoryEquipped[MAX_PLAYERS][INVENTORY_SLOTS];
new bool:g_InventoryActionBusy[MAX_PLAYERS], g_InventoryEquippedInstance[MAX_PLAYERS][6];
new g_InventoryEquippedType[MAX_PLAYERS][6], g_InventoryEquippedAmmo[MAX_PLAYERS][6];
new g_InventoryEquippedCharacter[MAX_PLAYERS];
new bool:g_InventoryWeaponDirty[MAX_PLAYERS];
new g_InventoryWeaponRevision[MAX_PLAYERS];
new g_InventoryNearbyInstance[MAX_PLAYERS][INVENTORY_SLOTS], g_InventoryNearbyType[MAX_PLAYERS][INVENTORY_SLOTS];
new g_InventoryContextVehicle[MAX_PLAYERS];
new g_InventoryRequestedTarget[MAX_PLAYERS], bool:g_InventoryGrantBusy[MAX_PLAYERS];
new Float:g_InventoryNearbyX[MAX_PLAYERS][INVENTORY_SLOTS], Float:g_InventoryNearbyY[MAX_PLAYERS][INVENTORY_SLOTS], Float:g_InventoryNearbyZ[MAX_PLAYERS][INVENTORY_SLOTS];
new g_GroundBagInstance[INVENTORY_WORLD_BAGS], g_GroundBagWorld[INVENTORY_WORLD_BAGS], g_GroundBagInterior[INVENTORY_WORLD_BAGS];
new Float:g_GroundBagX[INVENTORY_WORLD_BAGS], Float:g_GroundBagY[INVENTORY_WORLD_BAGS], Float:g_GroundBagZ[INVENTORY_WORLD_BAGS];
new g_GroundBagObject[MAX_PLAYERS][INVENTORY_WORLD_BAGS], g_GroundRefreshRevision;
new g_GroundBagActive[INVENTORY_WORLD_BAGS], g_GroundBagActiveCount;

hook OnGameModeInit()
{
    CEF_RegisterEvent("inventory:ready", "Inventory_Ready");
    CEF_RegisterEvent("inventory:painted", "Inventory_Painted");
    CEF_RegisterEvent("inventory:close", "Inventory_CloseEvent");
    CEF_RegisterEvent("inventory:use", "Inventory_UseEvent", Argument_Integer);
    CEF_RegisterEvent("inventory:reload", "Inventory_ReloadEvent", Argument_Integer);
    CEF_RegisterEvent("inventory:reload_target", "Inventory_ReloadTargetEvent", Argument_Integer, Argument_Integer);
    CEF_RegisterEvent("inventory:discard", "Inventory_DiscardEvent", Argument_Integer);
    CEF_RegisterEvent("inventory:drag", "Inventory_DragEvent", Argument_Integer, Argument_Integer, Argument_Integer, Argument_Integer);
    SetTimer("Inventory_WeaponAutosave", 60000, true);
    return 1;
}

hook OnPlayerConnect(playerid)
{
    g_InventoryOpen[playerid] = false;
    g_InventoryBrowser[playerid] = false;
    g_InventoryVisible[playerid] = false;
    g_InventoryRequest[playerid]++;
    g_InventoryURL[playerid][0] = EOS;
    g_InventoryContextVehicle[playerid] = 0;
    g_InventoryRequestedTarget[playerid] = -1;
    g_InventoryGrantBusy[playerid] = false;
    g_InventoryActionBusy[playerid] = false;
    g_InventoryEquippedCharacter[playerid] = 0;
    g_InventoryWeaponDirty[playerid] = false;
    g_InventoryWeaponRevision[playerid] = 0;
    for (new i; i < 6; i++)
    {
        g_InventoryEquippedInstance[playerid][i] = 0;
        g_InventoryEquippedType[playerid][i] = 0;
        g_InventoryEquippedAmmo[playerid][i] = 0;
    }
    for (new slot; slot < INVENTORY_SLOTS; slot++)
    {
        g_InventoryInstance[playerid][slot] = 0;
        g_InventoryType[playerid][slot] = 0;
        g_InventoryQuantity[playerid][slot] = 0;
        g_InventoryAmmo[playerid][slot] = 0;
        g_InventoryEquipped[playerid][slot] = false;
        g_InventoryNearbyInstance[playerid][slot] = 0;
        g_InventoryNearbyType[playerid][slot] = 0;
        g_InventoryNearbyQuantity[playerid][slot] = 0;
    }
    for (new bag; bag < INVENTORY_WORLD_BAGS; bag++) g_GroundBagObject[playerid][bag] = INVALID_OBJECT_ID;
    return 1;
}

forward Inventory_RefreshGround();
public Inventory_RefreshGround()
{
    g_GroundRefreshRevision++;
    mysql_tquery(g_DatabaseHandle,
        "SELECT `instance_id`,`pos_x`,`pos_y`,`pos_z`,`virtual_world`,`interior_id` FROM `character_item_instances` WHERE `location`='ground' AND `state`='active' ORDER BY `instance_id` DESC LIMIT 300",
        "Inventory_GroundLoaded", "d", g_GroundRefreshRevision);
    return 1;
}

forward Inventory_GroundLoaded(revision);
public Inventory_GroundLoaded(revision)
{
    if (revision != g_GroundRefreshRevision || mysql_errno(g_DatabaseHandle)) return 1;
    new bool:seen[INVENTORY_WORLD_BAGS], instance, index;
    for (new row; row < cache_num_rows(); row++)
    {
        cache_get_value_name_int(row, "instance_id", instance);
        if (instance <= 0) continue;
        index = -1;
        for (new i; i < INVENTORY_WORLD_BAGS; i++)
            if (g_GroundBagInstance[i] == instance) { index = i; break; }
        if (index < 0) for (new i; i < INVENTORY_WORLD_BAGS; i++)
            if (!g_GroundBagInstance[i] && !seen[i]) { index = i; break; }
        if (index < 0) break;
        seen[index] = true;
        g_GroundBagInstance[index] = instance;
        cache_get_value_name_float(row, "pos_x", g_GroundBagX[index]);
        cache_get_value_name_float(row, "pos_y", g_GroundBagY[index]);
        cache_get_value_name_float(row, "pos_z", g_GroundBagZ[index]);
        cache_get_value_name_int(row, "virtual_world", g_GroundBagWorld[index]);
        cache_get_value_name_int(row, "interior_id", g_GroundBagInterior[index]);
    }
    for (new i; i < INVENTORY_WORLD_BAGS; i++)
    {
        if (seen[i] || !g_GroundBagInstance[i]) continue;
        for (new playerid; playerid < MAX_PLAYERS; playerid++)
        {
            if (!IsPlayerConnected(playerid) || g_GroundBagObject[playerid][i] == INVALID_OBJECT_ID) continue;
            DestroyPlayerObject(playerid, g_GroundBagObject[playerid][i]);
            g_GroundBagObject[playerid][i] = INVALID_OBJECT_ID;
        }
        g_GroundBagInstance[i] = 0;
    }
    g_GroundBagActiveCount = 0;
    for (new i; i < INVENTORY_WORLD_BAGS; i++)
        if (g_GroundBagInstance[i]) g_GroundBagActive[g_GroundBagActiveCount++] = i;
    Inventory_SyncBagObjects();
    return 1;
}

forward Inventory_SyncBagObjects();
public Inventory_SyncBagObjects()
{
    if (!g_GroundBagActiveCount) return 1;
    for (new playerid; playerid < MAX_PLAYERS; playerid++)
    {
        if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid)) continue;
        new world = GetPlayerVirtualWorld(playerid), interior = GetPlayerInterior(playerid);
        for (new bag; bag < g_GroundBagActiveCount; bag++)
        {
            new i = g_GroundBagActive[bag];
            new bool:visible = g_GroundBagInstance[i] > 0 && world == g_GroundBagWorld[i] &&
                interior == g_GroundBagInterior[i] && IsPlayerInRangeOfPoint(playerid, 45.0,
                    g_GroundBagX[i], g_GroundBagY[i], g_GroundBagZ[i]);
            if (visible && g_GroundBagObject[playerid][i] == INVALID_OBJECT_ID)
                g_GroundBagObject[playerid][i] = CreatePlayerObject(playerid, INVENTORY_BAG_MODEL,
                    g_GroundBagX[i], g_GroundBagY[i], g_GroundBagZ[i] - 0.55,
                    0.0, 0.0, 0.0, 60.0);
            else if (!visible && g_GroundBagObject[playerid][i] != INVALID_OBJECT_ID)
            {
                DestroyPlayerObject(playerid, g_GroundBagObject[playerid][i]);
                g_GroundBagObject[playerid][i] = INVALID_OBJECT_ID;
            }
        }
    }
    return 1;
}

stock Inventory_Close(playerid)
{
    g_InventoryOpen[playerid] = false;
    g_InventoryVisible[playerid] = false;
    g_InventoryRequest[playerid]++;
    g_InventoryRequestedTarget[playerid] = -1;
    CEF_SetEscapeMenuMode(playerid, CEF_ESCAPE_MENU_GTA);
    CEF_FocusBrowser(playerid, INVENTORY_BROWSER, false);
    CEF_SetBrowserVisible(playerid, INVENTORY_BROWSER, false);
    CEF_ToggleChatInput(playerid, true);
    return 1;
}

CMD:inventory(playerid, params[])
{
    #pragma unused params
    if (g_InventoryOpen[playerid]) return Inventory_Close(playerid);
    if (!IsPlayerCharacterLoaded(playerid) || !s_CharacterCreated[playerid])
        return Inventory_Notify(playerid, "warning", "Can vao nhan vat truoc khi mo tui do."), 1;
    if (!s_CefReady[playerid] || s_CefClassic[playerid])
        return Inventory_Notify(playerid, "warning", "Can ReSA CEF de mo tui do."), 1;
    g_InventoryOpen[playerid] = true;
    g_InventoryRequest[playerid]++;
    g_InventoryVisible[playerid] = false;
    if (!g_InventoryBrowser[playerid])
    {
        g_InventoryBrowser[playerid] = true;
        CEF_CreateBrowser(playerid, INVENTORY_BROWSER, "http://cef/lsrp/inventory.html?v=2", false);
        CEF_SetBrowserVisible(playerid, INVENTORY_BROWSER, false);
    }
    else if (g_InventoryURL[playerid][0]) Inventory_Reveal(playerid);
    CEF_SetEscapeMenuMode(playerid, CEF_ESCAPE_MENU_CUSTOM);
    CEF_ToggleChatInput(playerid, false);
    new query[400];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "INSERT IGNORE INTO `character_item_instances` (`character_id`,`item_type`,`slot`,`origin`,`origin_character_id`) VALUES (%d,1,0,'starter_water',%d),(%d,2,1,'starter_food',%d),(%d,3,2,'starter_bandage',%d)",
        s_CharacterID[playerid], s_CharacterID[playerid], s_CharacterID[playerid], s_CharacterID[playerid], s_CharacterID[playerid], s_CharacterID[playerid]);
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Seed", "dddd", playerid,
        s_UISession[playerid], g_InventoryRequest[playerid], s_CharacterID[playerid]))
    {
        Inventory_Notify(playerid, "error", "MySQL chua san sang de mo tui do.");
        Inventory_Close(playerid);
    }
    else SetTimerEx("Inventory_RevealTimeout", 1500, false, "ddd", playerid,
        s_UISession[playerid], g_InventoryRequest[playerid]);
    return 1;
}

CMD:inv(playerid, params[]) return cmd_inventory(playerid, params);

stock bool:Inventory_Valid(playerid, session, request)
{
    return IsPlayerConnected(playerid) && g_InventoryOpen[playerid] &&
        s_UISession[playerid] == session && g_InventoryRequest[playerid] == request &&
        IsPlayerCharacterLoaded(playerid);
}

stock Inventory_Reveal(playerid)
{
    if (!g_InventoryOpen[playerid] || g_InventoryVisible[playerid] || !g_InventoryURL[playerid][0]) return 1;
    g_InventoryVisible[playerid] = true;
    CEF_SetBrowserVisible(playerid, INVENTORY_BROWSER, true);
    CEF_FocusBrowser(playerid, INVENTORY_BROWSER, true);
    return 1;
}

forward Inventory_RevealTimeout(playerid, session, request);
public Inventory_RevealTimeout(playerid, session, request)
{
    if (Inventory_Valid(playerid, session, request)) Inventory_Reveal(playerid);
    return 1;
}

forward Inventory_Painted(playerid, browserid);
public Inventory_Painted(playerid, browserid)
{
    if (browserid == INVENTORY_BROWSER) Inventory_Reveal(playerid);
    return 1;
}

stock Inventory_MaxStack(itemType)
{
    switch (itemType)
    {
        case 1: return 10; // Water
        case 2: return 8;  // Food
        case 3: return 5;  // Bandage
        case 8: return 60; // Pistol rounds
        case 9: return 30; // Shotgun shells
        case 10: return 90; // Rifle rounds
        case 11: return 90; // SMG rounds
    }
    return 1;
}

stock Inventory_Notify(playerid, const type[], const message[])
{
    if (!UI_Notify(playerid, type, message))
        SendClientMessage(playerid, !strcmp(type, "error") ? COLOR_RED : COLOR_WHITE, message);
    return 1;
}

stock Inventory_ItemName(itemType, name[], size)
{
    switch (itemType)
    {
        case 1: format(name, size, "Nuoc uong");
        case 2: format(name, size, "Do an nhe");
        case 3: format(name, size, "Bang cuu thuong");
        case 4: format(name, size, "Sung 9mm");
        case 5: format(name, size, "Desert Eagle");
        case 6: format(name, size, "Shotgun");
        case 7: format(name, size, "M4");
        case 8: format(name, size, "Dan pistol");
        case 9: format(name, size, "Dan shotgun");
        case 10: format(name, size, "Dan rifle");
        case 11: format(name, size, "Dan SMG");
        case 12: format(name, size, "MP5");
    }
    return 1;
}

stock bool:Inventory_IsWeaponType(itemType)
{
    return (itemType >= 4 && itemType <= 7) || itemType == 12;
}

stock Inventory_WeaponID(itemType)
{
    switch (itemType)
    {
        case 4: return 22; // Colt 45
        case 5: return 24; // Desert Eagle
        case 6: return 25; // Shotgun
        case 7: return 31; // M4
        case 12: return 29; // MP5
    }
    return 0;
}

stock Inventory_WeaponSlot(itemType)
{
    switch (itemType)
    {
        case 4, 5: return 2;
        case 6: return 3;
        case 7: return 5;
        case 12: return 4;
    }
    return 0;
}

stock Inventory_AmmoType(itemType)
{
    switch (itemType)
    {
        case 4, 5: return 8;
        case 6: return 9;
        case 7: return 10;
        case 12: return 11;
    }
    return 0;
}

stock Inventory_MagazineSize(itemType)
{
    switch (itemType)
    {
        case 4: return 17;
        case 5: return 7;
        case 6: return 8;
        case 7: return 30;
        case 12: return 30;
    }
    return 0;
}

CMD:giveitem(playerid, params[])
{
    new first = strfind(params, " ");
    if (first < 1 || params[0] < '0' || params[0] > '9')
    {
        SendClientMessage(playerid, COLOR_WHITE, "Su dung: /giveitem [playerid] [loai 1-12] [so luong 1-100]");
        return 1;
    }
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_ADMIN)) return 1;
    new second = strfind(params, " ", false, first + 1);
    new targetid = strval(params), itemType = strval(params[first + 1]);
    new amount = second < 0 ? 1 : strval(params[second + 1]);
    if (targetid < 0 || targetid >= MAX_PLAYERS || !IsPlayerConnected(targetid) ||
        !IsPlayerCharacterLoaded(targetid) || itemType < 1 || itemType > INVENTORY_ITEM_MAX ||
        amount < 1 || amount > 100)
        return Inventory_Notify(playerid, "warning", "Player, loai vat pham hoac so luong khong hop le."), 1;
    if (g_InventoryGrantBusy[targetid])
        return Inventory_Notify(playerid, "info", "Dang cap vat pham cho nguoi choi nay."), 1;
    g_InventoryGrantBusy[targetid] = true;
    new query[400];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "INSERT IGNORE INTO `character_item_instances` (`character_id`,`item_type`,`slot`,`origin`,`origin_character_id`) VALUES (%d,1,0,'starter_water',%d),(%d,2,1,'starter_food',%d),(%d,3,2,'starter_bandage',%d)",
        s_CharacterID[targetid], s_CharacterID[targetid], s_CharacterID[targetid], s_CharacterID[targetid], s_CharacterID[targetid], s_CharacterID[targetid]);
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_GrantSeeded", "dddddd", playerid,
        targetid, s_UISession[targetid], itemType, amount, s_CharacterID[targetid]))
    {
        g_InventoryGrantBusy[targetid] = false;
        Inventory_Notify(playerid, "error", "Khong the cap vat pham luc nay.");
    }
    return 1;
}

forward Inventory_GrantSeeded(adminid, targetid, session, itemType, amount, characterid);
public Inventory_GrantSeeded(adminid, targetid, session, itemType, amount, characterid)
{
    if (!IsPlayerConnected(targetid) || s_UISession[targetid] != session ||
        s_CharacterID[targetid] != characterid) return 1;
    if (mysql_errno(g_DatabaseHandle))
    {
        g_InventoryGrantBusy[targetid] = false;
        if (IsPlayerConnected(adminid)) Inventory_Notify(adminid, "error", "Khong the cap item: kiem tra schema inventory/MySQL.");
        return 1;
    }
    new query[240];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "SELECT `slot` FROM `character_item_instances` WHERE `character_id`=%d AND `location`='carried' AND `state`='active'",
        characterid);
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_GrantSlots", "dddddd", adminid,
        targetid, session, itemType, amount, characterid))
    {
        g_InventoryGrantBusy[targetid] = false;
        if (IsPlayerConnected(adminid)) Inventory_Notify(adminid, "error", "Khong the cap vat pham luc nay.");
    }
    return 1;
}

forward Inventory_GrantSlots(adminid, targetid, session, itemType, amount, characterid);
public Inventory_GrantSlots(adminid, targetid, session, itemType, amount, characterid)
{
    if (!IsPlayerConnected(targetid) || s_UISession[targetid] != session ||
        s_CharacterID[targetid] != characterid) return 1;
    if (mysql_errno(g_DatabaseHandle))
    {
        g_InventoryGrantBusy[targetid] = false;
        if (IsPlayerConnected(adminid)) Inventory_Notify(adminid, "error", "Khong the doc o tui do: kiem tra schema inventory/MySQL.");
        return 1;
    }
    new bool:occupied[INVENTORY_SLOTS], slot;
    for (new row; row < cache_num_rows(); row++)
    {
        cache_get_value_name_int(row, "slot", slot);
        if (slot >= 0 && slot < INVENTORY_SLOTS) occupied[slot] = true;
    }
    new query[1400], entry[80], added, remaining = amount, stackMax = Inventory_MaxStack(itemType);
    format(query, sizeof query, "INSERT INTO `character_item_instances` (`character_id`,`item_type`,`slot`,`quantity`) VALUES ");
    for (new i; i < INVENTORY_SLOTS && remaining > 0; i++)
    {
        if (occupied[i]) continue;
        new quantity = remaining > stackMax ? stackMax : remaining;
        format(entry, sizeof entry, "%s(%d,%d,%d,%d)", added ? "," : "", characterid, itemType, i, quantity);
        strcat(query, entry, sizeof query);
        added++;
        remaining -= quantity;
    }
    if (!added)
    {
        g_InventoryGrantBusy[targetid] = false;
        if (IsPlayerConnected(adminid)) Inventory_Notify(adminid, "warning", "Tui do nguoi choi da day.");
        return 1;
    }
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_GrantSaved", "dddddd", adminid,
        targetid, session, characterid, itemType, amount - remaining))
    {
        g_InventoryGrantBusy[targetid] = false;
        if (IsPlayerConnected(adminid)) Inventory_Notify(adminid, "error", "Khong the luu vat pham luc nay.");
    }
    return 1;
}

forward Inventory_GrantSaved(adminid, targetid, session, characterid, itemType, amount);
public Inventory_GrantSaved(adminid, targetid, session, characterid, itemType, amount)
{
    if (!IsPlayerConnected(targetid) || s_UISession[targetid] != session ||
        s_CharacterID[targetid] != characterid) return 1;
    g_InventoryGrantBusy[targetid] = false;
    if (mysql_errno(g_DatabaseHandle))
    {
        if (IsPlayerConnected(adminid)) Inventory_Notify(adminid, "error", "Khong the luu item vao MySQL.");
        return 1;
    }
    if (cache_affected_rows() > 0)
    {
        new name[24], message[90];
        Inventory_ItemName(itemType, name, sizeof name);
        format(message, sizeof message, "Da nhan %d x %s.", amount, name);
        Inventory_Notify(targetid, "success", message);
        if (adminid != targetid && IsPlayerConnected(adminid))
        {
            format(message, sizeof message, "Da cap %d x %s.", amount, name);
            Inventory_Notify(adminid, "success", message);
        }
        if (g_InventoryOpen[targetid]) Inventory_Load(targetid, session, g_InventoryRequest[targetid]);
    }
    return 1;
}

forward Inventory_Seed(playerid, session, request, characterid);
public Inventory_Seed(playerid, session, request, characterid)
{
    #pragma unused characterid
    if (mysql_errno(g_DatabaseHandle))
    {
        if (Inventory_Valid(playerid, session, request))
        {
            Inventory_Notify(playerid, "error", "Tui do chua san sang. Hay kiem tra migration 009 va MySQL.");
            Inventory_Close(playerid);
        }
        return 1;
    }
    if (Inventory_Valid(playerid, session, request)) Inventory_Load(playerid, session, request);
    return 1;
}

stock Inventory_Load(playerid, session, request)
{
    new query[260];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "SELECT `instance_id`,`item_type`,`slot`,`quantity`,`weapon_ammo`,`equipped` FROM `character_item_instances` WHERE `character_id`=%d AND `location`='carried' AND `state`='active' ORDER BY `slot` LIMIT 50",
        s_CharacterID[playerid]);
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Loaded", "ddd", playerid, session, request))
        Inventory_Close(playerid);
    return 1;
}

forward Inventory_Loaded(playerid, session, request);
public Inventory_Loaded(playerid, session, request)
{
    if (!Inventory_Valid(playerid, session, request)) return 1;
    if (mysql_errno(g_DatabaseHandle))
    {
        Inventory_Notify(playerid, "error", "Khong the tai tui do tu MySQL.");
        Inventory_Close(playerid);
        return 1;
    }
    for (new slot; slot < INVENTORY_SLOTS; slot++)
    {
        g_InventoryInstance[playerid][slot] = 0;
        g_InventoryType[playerid][slot] = 0;
        g_InventoryQuantity[playerid][slot] = 0;
        g_InventoryAmmo[playerid][slot] = 0;
        g_InventoryEquipped[playerid][slot] = false;
    }
    new slot, itemType, instance;
    for (new row; row < cache_num_rows(); row++)
    {
        cache_get_value_name_int(row, "slot", slot);
        cache_get_value_name_int(row, "item_type", itemType);
        cache_get_value_name_int(row, "instance_id", instance);
        new quantity;
        cache_get_value_name_int(row, "quantity", quantity);
        if (slot < 0 || slot >= INVENTORY_SLOTS || itemType < 1 || itemType > INVENTORY_ITEM_MAX || instance <= 0) continue;
        g_InventoryInstance[playerid][slot] = instance;
        g_InventoryType[playerid][slot] = itemType;
        g_InventoryQuantity[playerid][slot] = quantity;
        cache_get_value_name_int(row, "weapon_ammo", g_InventoryAmmo[playerid][slot]);
        new equipped;
        cache_get_value_name_int(row, "equipped", equipped);
        g_InventoryEquipped[playerid][slot] = equipped != 0 && Inventory_IsWeaponType(itemType);
    }
    Inventory_SendSnapshot(playerid);
    return 1;
}

stock Inventory_SendSnapshot(playerid)
{
    new url[3200], piece[55];
    format(url, sizeof url, "http://cef/lsrp/inventory.html?v=2#character=%s&skin=%d&cash=%d&bank=%d",
        s_CharacterName[playerid], s_CharacterSkin[playerid], GetPlayerMoney(playerid), s_CharacterBank[playerid]);
    for (new slot; slot < INVENTORY_SLOTS; slot++)
    {
        if (g_InventoryInstance[playerid][slot] <= 0) continue;
        new ammo = g_InventoryAmmo[playerid][slot];
        if (g_InventoryEquipped[playerid][slot])
            ammo = Inventory_RuntimeAmmo(playerid, g_InventoryType[playerid][slot], ammo);
        format(piece, sizeof piece, "&s%d=%d.%d.%d.%d.%d", slot, g_InventoryInstance[playerid][slot],
            g_InventoryType[playerid][slot], g_InventoryQuantity[playerid][slot],
            ammo, _:g_InventoryEquipped[playerid][slot]);
        strcat(url, piece, sizeof url);
    }
    for (new slot; slot < INVENTORY_SLOTS; slot++)
    {
        if (!g_InventoryEquipped[playerid][slot]) continue;
        new weaponSlot = Inventory_WeaponSlot(g_InventoryType[playerid][slot]);
        new weapon = Inventory_WeaponID(g_InventoryType[playerid][slot]);
        new ammo = Inventory_RuntimeAmmo(playerid, g_InventoryType[playerid][slot],
            g_InventoryAmmo[playerid][slot]);
        format(piece, sizeof piece, "&w%d=%d.%d", weaponSlot, weapon, ammo);
        strcat(url, piece, sizeof url);
    }
    if (!strcmp(g_InventoryURL[playerid], url)) return 1;
    format(g_InventoryURL[playerid], sizeof g_InventoryURL[], "%s", url);
    CEF_LoadUrl(playerid, INVENTORY_BROWSER, url);
    return 1;
}

forward Inventory_DiscardEvent(playerid, browserid, slot);
public Inventory_DiscardEvent(playerid, browserid, slot)
{
    if (browserid != INVENTORY_BROWSER || !g_InventoryOpen[playerid] || g_InventoryActionBusy[playerid] ||
        slot < 0 || slot >= INVENTORY_SLOTS || !g_InventoryInstance[playerid][slot]) return 1;
    if (g_InventoryEquipped[playerid][slot])
        return Inventory_Notify(playerid, "warning", "Thao sung truoc khi vut bo."), 1;
    new query[260], instance = g_InventoryInstance[playerid][slot];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "UPDATE `character_item_instances` SET `state`='destroyed',`ended_at`=NOW() WHERE `instance_id`=%d AND `character_id`=%d AND `location`='carried' AND `state`='active' LIMIT 1",
        instance, s_CharacterID[playerid]);
    g_InventoryInstance[playerid][slot] = 0;
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Moved", "dddd", playerid,
        s_UISession[playerid], g_InventoryRequest[playerid], 2))
    {
        g_InventoryInstance[playerid][slot] = instance;
        Inventory_Notify(playerid, "error", "Khong the vut vat pham luc nay.");
    }
    return 1;
}

stock Inventory_FindOpenTrunk(playerid)
{
    for (new owner; owner < MAX_PLAYERS; owner++)
    {
        if (!IsPlayerConnected(owner)) continue;
        for (new slot; slot < SIMPLE_VEHICLE_MAX; slot++)
        {
            new vehicleid = s_SimpleVehicleServerID[owner][slot];
            if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid) ||
                s_SimpleVehicleDatabaseID[owner][slot] <= 0 ||
                s_SimpleVehicleInterior[owner][slot] != GetPlayerInterior(playerid) ||
                GetVehicleVirtualWorld(vehicleid) != GetPlayerVirtualWorld(playerid)) continue;
            new Float:x, Float:y, Float:z;
            GetVehiclePos(vehicleid, x, y, z);
            if (!IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z)) continue;
            new engine, lights, alarm, doors, bonnet, boot, objective;
            GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
            if (boot == VEHICLE_PARAMS_ON) return s_SimpleVehicleDatabaseID[owner][slot];
        }
    }
    return 0;
}

stock Inventory_LoadContext(playerid, session, request)
{
    g_InventoryContextVehicle[playerid] = Inventory_FindOpenTrunk(playerid);
    new query[500];
    if (g_InventoryContextVehicle[playerid])
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "SELECT `instance_id`,`item_type`,`slot`,`quantity`,`pos_x`,`pos_y`,`pos_z` FROM `character_item_instances` WHERE `location`='trunk' AND `vehicle_id`=%d AND `state`='active' ORDER BY `slot`,`instance_id` LIMIT 50",
            g_InventoryContextVehicle[playerid]);
    else
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "SELECT `instance_id`,`item_type`,`slot`,`quantity`,`pos_x`,`pos_y`,`pos_z` FROM `character_item_instances` WHERE `location`='ground' AND `state`='active' AND `virtual_world`=%d AND `interior_id`=%d AND `pos_x` BETWEEN %f AND %f AND `pos_y` BETWEEN %f AND %f AND `pos_z` BETWEEN %f AND %f ORDER BY `slot`,`instance_id` LIMIT 50",
            GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), x-4.0, x+4.0, y-4.0, y+4.0, z-4.0, z+4.0);
    }
    mysql_tquery(g_DatabaseHandle, query, "Inventory_ContextLoaded", "ddd", playerid, session, request);
    return 1;
}

forward Inventory_ContextLoaded(playerid, session, request);
public Inventory_ContextLoaded(playerid, session, request)
{
    if (!Inventory_Valid(playerid, session, request)) return 1;
    if (mysql_errno(g_DatabaseHandle)) return Inventory_Close(playerid);
    new url[3200], piece[45], slot, itemType, instance;
    format(url, sizeof url, "http://cef/lsrp/inventory.html?v=2#character=%s&context=%d", s_CharacterName[playerid], g_InventoryContextVehicle[playerid]);
    for (new i; i < INVENTORY_SLOTS; i++)
    {
        g_InventoryNearbyInstance[playerid][i] = 0;
        g_InventoryNearbyType[playerid][i] = 0;
        g_InventoryNearbyQuantity[playerid][i] = 0;
        if (g_InventoryInstance[playerid][i] > 0)
        {
            format(piece, sizeof piece, "&s%d=%d.%d.%d", i, g_InventoryInstance[playerid][i], g_InventoryType[playerid][i], g_InventoryQuantity[playerid][i]);
            strcat(url, piece, sizeof url);
        }
    }
    for (new row; row < cache_num_rows() && row < INVENTORY_SLOTS; row++)
    {
        cache_get_value_name_int(row, "item_type", itemType);
        cache_get_value_name_int(row, "instance_id", instance);
        if (itemType < 1 || itemType > 3 || instance <= 0) continue;
        cache_get_value_name_int(row, "slot", slot);
        if (slot < 0 || slot >= INVENTORY_SLOTS || g_InventoryNearbyInstance[playerid][slot])
        {
            slot = -1;
            for (new candidate; candidate < INVENTORY_SLOTS; candidate++)
                if (!g_InventoryNearbyInstance[playerid][candidate]) { slot = candidate; break; }
            if (slot < 0) break;
        }
        g_InventoryNearbyInstance[playerid][slot] = instance;
        g_InventoryNearbyType[playerid][slot] = itemType;
        cache_get_value_name_int(row, "quantity", g_InventoryNearbyQuantity[playerid][slot]);
        cache_get_value_name_float(row, "pos_x", g_InventoryNearbyX[playerid][slot]);
        cache_get_value_name_float(row, "pos_y", g_InventoryNearbyY[playerid][slot]);
        cache_get_value_name_float(row, "pos_z", g_InventoryNearbyZ[playerid][slot]);
        format(piece, sizeof piece, "&g%d=%d.%d.%d", slot, instance, itemType, g_InventoryNearbyQuantity[playerid][slot]);
        strcat(url, piece, sizeof url);
    }
    if (!strcmp(g_InventoryURL[playerid], url)) return 1;
    format(g_InventoryURL[playerid], sizeof g_InventoryURL[], "%s", url);
    CEF_LoadUrl(playerid, INVENTORY_BROWSER, url);
    if (g_InventoryVisible[playerid]) CEF_FocusBrowser(playerid, INVENTORY_BROWSER, true);
    return 1;
}

forward Inventory_Ready(playerid, browserid);
public Inventory_Ready(playerid, browserid)
{
    if (browserid == INVENTORY_BROWSER && g_InventoryOpen[playerid] && g_InventoryURL[playerid][0])
    {
        CEF_LoadUrl(playerid, INVENTORY_BROWSER, g_InventoryURL[playerid]);
        CEF_FocusBrowser(playerid, INVENTORY_BROWSER, true);
    }
    return 1;
}

forward Inventory_CloseEvent(playerid, browserid);
public Inventory_CloseEvent(playerid, browserid)
{
    if (browserid == INVENTORY_BROWSER) Inventory_Close(playerid);
    return 1;
}

forward Inventory_MoveEvent(playerid, browserid, side, slot);
public Inventory_MoveEvent(playerid, browserid, side, slot)
{
    new target = g_InventoryRequestedTarget[playerid];
    g_InventoryRequestedTarget[playerid] = -1;
    if (browserid != INVENTORY_BROWSER || !g_InventoryOpen[playerid] || g_InventoryGrantBusy[playerid] || g_InventoryActionBusy[playerid] ||
        (side != 0 && side != 1) || slot < 0 || slot >= INVENTORY_SLOTS) return 1;
    if (side == 0)
    {
        if (!g_InventoryInstance[playerid][slot]) return 1;
        if (target < 0) for (new i; i < INVENTORY_SLOTS; i++)
            if (!g_InventoryNearbyInstance[playerid][i]) { target = i; break; }
    }
    else
    {
        if (!g_InventoryNearbyInstance[playerid][slot]) return 1;
        if (target < 0) for (new i; i < INVENTORY_SLOTS; i++)
            if (!g_InventoryInstance[playerid][i]) { target = i; break; }
    }
    if (target < 0 || target >= INVENTORY_SLOTS ||
        (side == 0 ? g_InventoryNearbyInstance[playerid][target] : g_InventoryInstance[playerid][target]))
    {
        Inventory_Notify(playerid, "warning", "Khong con o trong de chuyen vat pham.");
        return 1;
    }
    new vehicle = g_InventoryContextVehicle[playerid];
    if (vehicle && Inventory_FindOpenTrunk(playerid) != vehicle)
    {
        Inventory_Notify(playerid, "warning", "Can o gan cop xe dang mo.");
        return Inventory_Load(playerid, s_UISession[playerid], g_InventoryRequest[playerid]);
    }
    if (side == 1 && !vehicle && !IsPlayerInRangeOfPoint(playerid, 4.0,
        g_InventoryNearbyX[playerid][slot], g_InventoryNearbyY[playerid][slot], g_InventoryNearbyZ[playerid][slot]))
    {
        Inventory_Notify(playerid, "warning", "Vat pham da o qua xa.");
        return Inventory_Load(playerid, s_UISession[playerid], g_InventoryRequest[playerid]);
    }
    new query[440], instance = side == 0 ? g_InventoryInstance[playerid][slot] : g_InventoryNearbyInstance[playerid][slot];
    if (side == 0)
    {
        if (vehicle)
            mysql_format(g_DatabaseHandle, query, sizeof query,
                "UPDATE `character_item_instances` SET `location`='trunk',`vehicle_id`=%d,`slot`=%d WHERE `instance_id`=%d AND `character_id`=%d AND `location`='carried' AND `state`='active' LIMIT 1",
                vehicle, target, instance, s_CharacterID[playerid]);
        else
        {
            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            mysql_format(g_DatabaseHandle, query, sizeof query,
                "UPDATE `character_item_instances` SET `location`='ground',`vehicle_id`=NULL,`slot`=%d,`pos_x`=%f,`pos_y`=%f,`pos_z`=%f,`interior_id`=%d,`virtual_world`=%d WHERE `instance_id`=%d AND `character_id`=%d AND `location`='carried' AND `state`='active' LIMIT 1",
                target, x, y, z, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid), instance, s_CharacterID[playerid]);
        }
    }
    else if (vehicle)
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "UPDATE `character_item_instances` SET `location`='carried',`character_id`=%d,`vehicle_id`=NULL,`slot`=%d WHERE `instance_id`=%d AND `location`='trunk' AND `vehicle_id`=%d AND `state`='active' LIMIT 1",
            s_CharacterID[playerid], target, instance, vehicle);
    else
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "UPDATE `character_item_instances` SET `location`='carried',`character_id`=%d,`slot`=%d WHERE `instance_id`=%d AND `location`='ground' AND `virtual_world`=%d AND `interior_id`=%d AND `state`='active' LIMIT 1",
            s_CharacterID[playerid], target, instance, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
    // Refresh from the database after the write; duplicate clicks cannot create extra items.
    if (side == 0) g_InventoryInstance[playerid][slot] = 0;
    else g_InventoryNearbyInstance[playerid][slot] = 0;
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Moved", "dddd", playerid,
        s_UISession[playerid], g_InventoryRequest[playerid], !vehicle))
        Inventory_Load(playerid, s_UISession[playerid], g_InventoryRequest[playerid]);
    return 1;
}

forward Inventory_DragEvent(playerid, browserid, fromSide, fromSlot, toSide, toSlot);
public Inventory_DragEvent(playerid, browserid, fromSide, fromSlot, toSide, toSlot)
{
    if (browserid != INVENTORY_BROWSER || !g_InventoryOpen[playerid] || g_InventoryGrantBusy[playerid] || g_InventoryActionBusy[playerid] ||
        fromSide != 0 || toSide != 0 ||
        fromSlot < 0 || fromSlot >= INVENTORY_SLOTS || toSlot < 0 || toSlot >= INVENTORY_SLOTS ||
        (fromSide == toSide && fromSlot == toSlot)) return 1;
    if (fromSide != toSide)
    {
        g_InventoryRequestedTarget[playerid] = toSlot;
        return Inventory_MoveEvent(playerid, browserid, fromSide, fromSlot);
    }
    new source = fromSide == 0 ? g_InventoryInstance[playerid][fromSlot] : g_InventoryNearbyInstance[playerid][fromSlot];
    new destination = fromSide == 0 ? g_InventoryInstance[playerid][toSlot] : g_InventoryNearbyInstance[playerid][toSlot];
    if (!source) return 1;
    if (fromSide == 0 && destination &&
        g_InventoryType[playerid][fromSlot] == g_InventoryType[playerid][toSlot] &&
        Inventory_MaxStack(g_InventoryType[playerid][fromSlot]) > 1)
    {
        new capacity = Inventory_MaxStack(g_InventoryType[playerid][fromSlot]);
        new available = capacity - g_InventoryQuantity[playerid][toSlot];
        if (available <= 0)
            return Inventory_Notify(playerid, "warning", "Chong vat pham nay da day."), 1;
        new moved = g_InventoryQuantity[playerid][fromSlot];
        if (moved > available) moved = available;
        new remaining = g_InventoryQuantity[playerid][fromSlot] - moved;
        new queryMerge[900];
        mysql_format(g_DatabaseHandle, queryMerge, sizeof queryMerge,
            "UPDATE `character_item_instances` AS src JOIN `character_item_instances` AS dst ON dst.`instance_id`=%d SET src.`quantity`=%d,src.`state`=IF(%d=0,'consumed','active'),src.`ended_at`=IF(%d=0,NOW(),src.`ended_at`),dst.`quantity`=%d WHERE src.`instance_id`=%d AND src.`character_id`=%d AND src.`location`='carried' AND src.`state`='active' AND src.`item_type`=%d AND src.`quantity`=%d AND dst.`character_id`=%d AND dst.`location`='carried' AND dst.`state`='active' AND dst.`item_type`=%d AND dst.`quantity`=%d",
            destination, remaining, remaining, remaining,
            g_InventoryQuantity[playerid][toSlot] + moved, source, s_CharacterID[playerid],
            g_InventoryType[playerid][fromSlot], g_InventoryQuantity[playerid][fromSlot],
            s_CharacterID[playerid], g_InventoryType[playerid][toSlot], g_InventoryQuantity[playerid][toSlot]);
        g_InventoryActionBusy[playerid] = true;
        if (!mysql_tquery(g_DatabaseHandle, queryMerge, "Inventory_Moved", "dddd", playerid,
            s_UISession[playerid], g_InventoryRequest[playerid], 3))
        {
            g_InventoryActionBusy[playerid] = false;
            Inventory_Notify(playerid, "error", "Khong the gop vat pham luc nay.");
        }
        return 1;
    }
    new vehicle = g_InventoryContextVehicle[playerid];
    if (fromSide == 1)
    {
        if (vehicle && Inventory_FindOpenTrunk(playerid) != vehicle) return 1;
        if (!vehicle && !IsPlayerInRangeOfPoint(playerid, 4.0,
            g_InventoryNearbyX[playerid][fromSlot], g_InventoryNearbyY[playerid][fromSlot], g_InventoryNearbyZ[playerid][fromSlot])) return 1;
    }
    new query[450];
    if (fromSide == 0)
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "UPDATE `character_item_instances` SET `slot`=CASE `instance_id` WHEN %d THEN %d WHEN %d THEN %d ELSE `slot` END WHERE `instance_id` IN (%d,%d) AND `character_id`=%d AND `location`='carried' AND `state`='active'",
            source, toSlot, destination, fromSlot, source, destination, s_CharacterID[playerid]);
    else if (vehicle)
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "UPDATE `character_item_instances` SET `slot`=CASE `instance_id` WHEN %d THEN %d WHEN %d THEN %d ELSE `slot` END WHERE `instance_id` IN (%d,%d) AND `vehicle_id`=%d AND `location`='trunk' AND `state`='active'",
            source, toSlot, destination, fromSlot, source, destination, vehicle);
    else
        mysql_format(g_DatabaseHandle, query, sizeof query,
            "UPDATE `character_item_instances` SET `slot`=CASE `instance_id` WHEN %d THEN %d WHEN %d THEN %d ELSE `slot` END WHERE `instance_id` IN (%d,%d) AND `location`='ground' AND `virtual_world`=%d AND `interior_id`=%d AND `state`='active'",
            source, toSlot, destination, fromSlot, source, destination, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
    if (fromSide == 0) g_InventoryInstance[playerid][fromSlot] = 0;
    else g_InventoryNearbyInstance[playerid][fromSlot] = 0;
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Moved", "dddd", playerid,
        s_UISession[playerid], g_InventoryRequest[playerid], fromSide == 1 && !vehicle))
        Inventory_Load(playerid, s_UISession[playerid], g_InventoryRequest[playerid]);
    return 1;
}

forward Inventory_Moved(playerid, session, request, groundChanged);
public Inventory_Moved(playerid, session, request, groundChanged)
{
    if (groundChanged == 3) g_InventoryActionBusy[playerid] = false;
    if (mysql_errno(g_DatabaseHandle) && Inventory_Valid(playerid, session, request))
        Inventory_Notify(playerid, "error", "Khong the chuyen vat pham. Kiem tra du lieu tui do/MySQL.");
    if (groundChanged == 1 && !mysql_errno(g_DatabaseHandle) && cache_affected_rows() > 0) Inventory_RefreshGround();
    if (groundChanged == 2 && !mysql_errno(g_DatabaseHandle) && cache_affected_rows() > 0 &&
        Inventory_Valid(playerid, session, request)) Inventory_Notify(playerid, "success", "Da vut bo vat pham.");
    if (groundChanged == 3 && Inventory_Valid(playerid, session, request))
    {
        if (!mysql_errno(g_DatabaseHandle) && cache_affected_rows() >= 2)
            Inventory_Notify(playerid, "success", "Da gop vat pham.");
        else if (!mysql_errno(g_DatabaseHandle))
            Inventory_Notify(playerid, "warning", "Vat pham da thay doi. Tui do duoc tai lai.");
    }
    if (Inventory_Valid(playerid, session, request)) Inventory_Load(playerid, session, request);
    return 1;
}

forward Inventory_UseEvent(playerid, browserid, slot);
public Inventory_UseEvent(playerid, browserid, slot)
{
    if (browserid != INVENTORY_BROWSER || !g_InventoryOpen[playerid] || g_InventoryGrantBusy[playerid] || g_InventoryActionBusy[playerid] ||
        slot < 0 || slot >= INVENTORY_SLOTS || !g_InventoryInstance[playerid][slot]) return 1;
    if (Inventory_IsWeaponType(g_InventoryType[playerid][slot]))
        return Inventory_WeaponUse(playerid, slot);
    if (g_InventoryType[playerid][slot] >= 8 && g_InventoryType[playerid][slot] <= 11)
        return Inventory_ReloadItem(playerid, slot);
    new query[300], instance = g_InventoryInstance[playerid][slot];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "UPDATE `character_item_instances` SET `state`=IF(`quantity`=1,'consumed',`state`),`ended_at`=IF(`quantity`=1,NOW(),`ended_at`),`quantity`=`quantity`-1 WHERE `instance_id`=%d AND `character_id`=%d AND `location`='carried' AND `state`='active' AND `quantity`>0 LIMIT 1",
        instance, s_CharacterID[playerid]);
    g_InventoryInstance[playerid][slot] = 0;
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Used", "dddddd", playerid,
        s_UISession[playerid], g_InventoryRequest[playerid], slot, g_InventoryType[playerid][slot], s_CharacterID[playerid]))
    {
        g_InventoryInstance[playerid][slot] = instance;
        Inventory_Notify(playerid, "error", "MySQL chua san sang de su dung vat pham.");
    }
    return 1;
}

forward Inventory_Used(playerid, session, request, slot, itemType, characterid);
public Inventory_Used(playerid, session, request, slot, itemType, characterid)
{
    #pragma unused slot
    if (!IsPlayerConnected(playerid) || s_UISession[playerid] != session ||
        s_CharacterID[playerid] != characterid || !IsPlayerCharacterLoaded(playerid)) return 1;
    if (mysql_errno(g_DatabaseHandle))
        Inventory_Notify(playerid, "error", "Khong the su dung vat pham. Hay thu lai.");
    if (cache_affected_rows() == 1)
    {
        new Float:health;
        GetPlayerHealth(playerid, health);
        new Float:restored = health + (itemType == 3 ? 25.0 : 5.0);
        if (restored > 100.0) restored = 100.0;
        SetPlayerHealth(playerid, restored);
        Inventory_Notify(playerid, "success", "Da su dung vat pham.");
    }
    if (Inventory_Valid(playerid, session, request)) Inventory_Load(playerid, session, request);
    return 1;
}
