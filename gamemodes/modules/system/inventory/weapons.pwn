#include <YSI_Coding\y_hooks>

stock Inventory_RuntimeAmmo(playerid, itemType, fallback)
{
    new weaponSlot = Inventory_WeaponSlot(itemType);
    if (!weaponSlot) return fallback;
    new allowed = fallback;
    if (g_InventoryEquippedCharacter[playerid] == s_CharacterID[playerid] &&
        g_InventoryEquippedInstance[playerid][weaponSlot - 2] > 0)
        allowed = g_InventoryEquippedAmmo[playerid][weaponSlot - 2];
    if (!IsPlayerConnected(playerid)) return allowed;
    new WEAPON:weapon, ammo;
    if (!GetPlayerWeaponData(playerid, WEAPON_SLOT:weaponSlot, weapon, ammo) ||
        _:weapon != Inventory_WeaponID(itemType)) return allowed;
    if (ammo > allowed) ammo = allowed;
    return ammo < 0 ? 0 : ammo;
}

stock Inventory_SaveWeaponAmmo(playerid, bool:force = false)
{
    if ((!force && !IsPlayerConnected(playerid)) || !g_InventoryEquippedCharacter[playerid] ||
        (!force && !g_InventoryWeaponDirty[playerid])) return 1;
    new query[900], piece[220], count;
    format(query, sizeof query, "UPDATE `character_item_instances` SET `weapon_ammo`=CASE `instance_id`");
    for (new i; i < 6; i++)
    {
        new instance = g_InventoryEquippedInstance[playerid][i];
        new itemType = g_InventoryEquippedType[playerid][i];
        if (instance <= 0 || !Inventory_IsWeaponType(itemType)) continue;
        new ammo = Inventory_RuntimeAmmo(playerid, itemType, g_InventoryEquippedAmmo[playerid][i]);
        format(piece, sizeof piece, " WHEN %d THEN %d", instance, ammo);
        strcat(query, piece, sizeof query);
        count++;
    }
    if (!count) return 1;
    format(piece, sizeof piece,
        " ELSE `weapon_ammo` END WHERE `character_id`=%d AND `location`='carried' AND `state`='active' AND `equipped`=1",
        g_InventoryEquippedCharacter[playerid]);
    strcat(query, piece, sizeof query);
    mysql_tquery(g_DatabaseHandle, query, "Inventory_AmmoSaved", "dddd", playerid,
        s_UISession[playerid], g_InventoryEquippedCharacter[playerid], g_InventoryWeaponRevision[playerid]);
    return 1;
}

forward Inventory_AmmoSaved(playerid, session, characterid, revision);
public Inventory_AmmoSaved(playerid, session, characterid, revision)
{
    if (!IsPlayerConnected(playerid) || s_UISession[playerid] != session ||
        g_InventoryEquippedCharacter[playerid] != characterid) return 1;
    if (!mysql_errno(g_DatabaseHandle) && revision == g_InventoryWeaponRevision[playerid])
        g_InventoryWeaponDirty[playerid] = false;
    return 1;
}

forward Inventory_WeaponAutosave();
public Inventory_WeaponAutosave()
{
    for (new playerid; playerid < MAX_PLAYERS; playerid++)
        if (g_InventoryWeaponDirty[playerid]) Inventory_SaveWeaponAmmo(playerid);
    return 1;
}

hook OnPlayerWeaponShot(playerid, WEAPON:weaponid, BULLET_HIT_TYPE:hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    #pragma unused hittype, hitid, fX, fY, fZ
    if (g_InventoryEquippedCharacter[playerid] != s_CharacterID[playerid]) return 1;
    for (new i; i < 6; i++)
    {
        if (g_InventoryEquippedInstance[playerid][i] <= 0 ||
            Inventory_WeaponID(g_InventoryEquippedType[playerid][i]) != _:weaponid) continue;
        if (g_InventoryEquippedAmmo[playerid][i] > 0) g_InventoryEquippedAmmo[playerid][i]--;
        g_InventoryWeaponDirty[playerid] = true;
        g_InventoryWeaponRevision[playerid]++;
        break;
    }
    return 1;
}

hook OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    #pragma unused killerid, reason
    Inventory_SaveWeaponAmmo(playerid, true);
    return 1;
}

hook OnPlayerSpawn(playerid)
{
    if (IsPlayerCharacterLoaded(playerid) && s_CharacterCreated[playerid])
        SetTimerEx("Inventory_RestoreTimer", 700, false, "ddd", playerid,
            s_UISession[playerid], s_CharacterID[playerid]);
    return 1;
}

forward Inventory_RestoreTimer(playerid, session, characterid);
public Inventory_RestoreTimer(playerid, session, characterid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid) ||
        s_UISession[playerid] != session || s_CharacterID[playerid] != characterid) return 1;
    if (s_CinematicLoginPreparing[playerid] || Cinematic_IsSpawnActive(playerid) ||
        CharacterCreator_IsActive(playerid))
    {
        SetTimerEx("Inventory_RestoreTimer", 1000, false, "ddd", playerid, session, characterid);
        return 1;
    }
    Inventory_RestoreWeapons(playerid, session, characterid, 0);
    return 1;
}

stock Inventory_RestoreWeapons(playerid, session, characterid, mode)
{
    new query[400];
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "SELECT `instance_id`,`item_type`,`weapon_ammo` FROM `character_item_instances` WHERE `character_id`=%d AND `location`='carried' AND `state`='active' AND `equipped`=1 AND `item_type` IN (4,5,6,7,12) ORDER BY `instance_id` DESC LIMIT 6",
        characterid);
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_WeaponsRestored", "dddd",
        playerid, session, characterid, mode))
    {
        g_InventoryActionBusy[playerid] = false;
        return 0;
    }
    return 1;
}

forward Inventory_WeaponsRestored(playerid, session, characterid, mode);
public Inventory_WeaponsRestored(playerid, session, characterid, mode)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid) ||
        s_UISession[playerid] != session || s_CharacterID[playerid] != characterid) return 1;
    if (mysql_errno(g_DatabaseHandle))
    {
        g_InventoryActionBusy[playerid] = false;
        UI_Notify(playerid, "error", "Khong tai duoc trang bi vu khi.");
        return 1;
    }
    ResetPlayerWeapons(playerid);
    for (new i; i < 6; i++)
    {
        g_InventoryEquippedInstance[playerid][i] = 0;
        g_InventoryEquippedType[playerid][i] = 0;
        g_InventoryEquippedAmmo[playerid][i] = 0;
    }
    g_InventoryEquippedCharacter[playerid] = characterid;
    for (new row; row < cache_num_rows(); row++)
    {
        new instance, itemType, ammo;
        cache_get_value_name_int(row, "instance_id", instance);
        cache_get_value_name_int(row, "item_type", itemType);
        cache_get_value_name_int(row, "weapon_ammo", ammo);
        new weaponSlot = Inventory_WeaponSlot(itemType);
        if (!weaponSlot || instance <= 0 || g_InventoryEquippedInstance[playerid][weaponSlot - 2]) continue;
        g_InventoryEquippedInstance[playerid][weaponSlot - 2] = instance;
        g_InventoryEquippedType[playerid][weaponSlot - 2] = itemType;
        g_InventoryEquippedAmmo[playerid][weaponSlot - 2] = ammo;
        if (ammo > 0) GivePlayerWeapon(playerid, WEAPON:Inventory_WeaponID(itemType), ammo);
    }
    g_InventoryWeaponDirty[playerid] = false;
    g_InventoryActionBusy[playerid] = false;
    if (mode == 1) UI_Notify(playerid, "success", "Da trang bi vu khi.");
    else if (mode == 2) UI_Notify(playerid, "success", "Da thao vu khi.");
    if (g_InventoryOpen[playerid]) Inventory_Load(playerid, session, g_InventoryRequest[playerid]);
    return 1;
}

stock Inventory_WeaponUse(playerid, slot)
{
    new itemType = g_InventoryType[playerid][slot];
    if (!Inventory_IsWeaponType(itemType)) return 1;
    new target = g_InventoryEquipped[playerid][slot] ? 0 : g_InventoryInstance[playerid][slot];
    new group[8];
    if (itemType == 4 || itemType == 5) format(group, sizeof group, "4,5");
    else format(group, sizeof group, "%d", itemType);
    new query[1300], piece[320], bool:hasEquipped;
    format(query, sizeof query, "UPDATE `character_item_instances` SET ");
    for (new i; i < INVENTORY_SLOTS; i++)
    {
        if (!g_InventoryEquipped[playerid][i] || !Inventory_IsWeaponType(g_InventoryType[playerid][i])) continue;
        if (!hasEquipped)
        {
            strcat(query, "`weapon_ammo`=CASE `instance_id`", sizeof query);
            hasEquipped = true;
        }
        new ammo = Inventory_RuntimeAmmo(playerid, g_InventoryType[playerid][i], g_InventoryAmmo[playerid][i]);
        format(piece, sizeof piece, " WHEN %d THEN %d", g_InventoryInstance[playerid][i], ammo);
        strcat(query, piece, sizeof query);
    }
    if (hasEquipped) strcat(query, " ELSE `weapon_ammo` END,", sizeof query);
    format(piece, sizeof piece,
        "`equipped`=CASE WHEN `instance_id`=%d THEN 1 WHEN `item_type` IN (%s) THEN 0 ELSE `equipped` END WHERE `character_id`=%d AND `location`='carried' AND `state`='active' AND `item_type` IN (4,5,6,7,12)",
        target, group, s_CharacterID[playerid]);
    strcat(query, piece, sizeof query);
    g_InventoryActionBusy[playerid] = true;
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_WeaponChanged", "dddd",
        playerid, s_UISession[playerid], s_CharacterID[playerid], target ? 1 : 2))
    {
        g_InventoryActionBusy[playerid] = false;
        UI_Notify(playerid, "error", "Khong the thay doi vu khi luc nay.");
    }
    return 1;
}

forward Inventory_WeaponChanged(playerid, session, characterid, mode);
public Inventory_WeaponChanged(playerid, session, characterid, mode)
{
    if (!IsPlayerConnected(playerid) || s_UISession[playerid] != session ||
        s_CharacterID[playerid] != characterid) return 1;
    if (mysql_errno(g_DatabaseHandle) || cache_affected_rows() < 1)
    {
        g_InventoryActionBusy[playerid] = false;
        UI_Notify(playerid, "error", "Khong luu duoc trang bi vu khi.");
        if (g_InventoryOpen[playerid]) Inventory_Load(playerid, session, g_InventoryRequest[playerid]);
        return 1;
    }
    Inventory_RestoreWeapons(playerid, session, characterid, mode);
    return 1;
}

forward Inventory_ReloadEvent(playerid, browserid, slot);
public Inventory_ReloadEvent(playerid, browserid, slot)
{
    if (browserid == INVENTORY_BROWSER && g_InventoryOpen[playerid] &&
        slot >= 0 && slot < INVENTORY_SLOTS && g_InventoryInstance[playerid][slot])
        Inventory_ReloadItem(playerid, slot);
    return 1;
}

forward Inventory_ReloadTargetEvent(playerid, browserid, slot, targetWeaponSlot);
public Inventory_ReloadTargetEvent(playerid, browserid, slot, targetWeaponSlot)
{
    if (browserid == INVENTORY_BROWSER && g_InventoryOpen[playerid] &&
        slot >= 0 && slot < INVENTORY_SLOTS && g_InventoryInstance[playerid][slot] &&
        targetWeaponSlot >= 2 && targetWeaponSlot <= 7)
        Inventory_ReloadItem(playerid, slot, targetWeaponSlot);
    return 1;
}

stock Inventory_ReloadItem(playerid, slot, targetWeaponSlot = 0)
{
    if (g_InventoryActionBusy[playerid]) return 1;
    new selectedType = g_InventoryType[playerid][slot], weaponSlot = -1, ammoSlot = -1;
    if (Inventory_IsWeaponType(selectedType))
    {
        if (!g_InventoryEquipped[playerid][slot]) return 1;
        weaponSlot = slot;
        new ammoType = Inventory_AmmoType(selectedType);
        for (new i; i < INVENTORY_SLOTS; i++)
            if (g_InventoryType[playerid][i] == ammoType && g_InventoryInstance[playerid][i] > 0 &&
                g_InventoryQuantity[playerid][i] > 0) { ammoSlot = i; break; }
    }
    else if (selectedType >= 8 && selectedType <= 11)
    {
        ammoSlot = slot;
        for (new i; i < INVENTORY_SLOTS; i++)
            if (g_InventoryEquipped[playerid][i] &&
                (targetWeaponSlot ? Inventory_WeaponSlot(g_InventoryType[playerid][i]) == targetWeaponSlot :
                    Inventory_AmmoType(g_InventoryType[playerid][i]) == selectedType)) { weaponSlot = i; break; }
    }
    if (weaponSlot < 0)
        return UI_Notify(playerid, "warning", "Chua trang bi sung tuong ung voi loai dan nay."), 1;
    if (ammoSlot < 0)
    {
        new message[90], ammoName[12];
        switch (Inventory_AmmoType(g_InventoryType[playerid][weaponSlot]))
        {
            case 8: format(ammoName, sizeof ammoName, "pistol");
            case 9: format(ammoName, sizeof ammoName, "shotgun");
            case 10: format(ammoName, sizeof ammoName, "rifle");
            case 11: format(ammoName, sizeof ammoName, "SMG");
        }
        format(message, sizeof message, "Khong co dan %s de nap cho sung nay.", ammoName);
        return UI_Notify(playerid, "warning", message), 1;
    }
    if (Inventory_AmmoType(g_InventoryType[playerid][weaponSlot]) != g_InventoryType[playerid][ammoSlot])
        return UI_Notify(playerid, "warning", "Sai loai dan cho sung dang trang bi."), 1;
    new itemType = g_InventoryType[playerid][weaponSlot];
    new current = Inventory_RuntimeAmmo(playerid, itemType, g_InventoryAmmo[playerid][weaponSlot]);
    new capacity = Inventory_MagazineSize(itemType);
    if (current >= capacity)
        return UI_Notify(playerid, "info", "Sung da du dan."), 1;
    new available = g_InventoryQuantity[playerid][ammoSlot];
    new added = capacity - current;
    if (added > available) added = available;
    if (added <= 0) return 1;
    new query[750], after = available - added;
    mysql_format(g_DatabaseHandle, query, sizeof query,
        "UPDATE `character_item_instances` AS w JOIN `character_item_instances` AS a ON a.`instance_id`=%d SET w.`weapon_ammo`=%d,a.`quantity`=%d,a.`state`=IF(%d=0,'consumed','active'),a.`ended_at`=IF(%d=0,NOW(),a.`ended_at`) WHERE w.`instance_id`=%d AND w.`character_id`=%d AND w.`location`='carried' AND w.`state`='active' AND w.`equipped`=1 AND w.`item_type`=%d AND a.`character_id`=%d AND a.`location`='carried' AND a.`state`='active' AND a.`item_type`=%d AND a.`quantity`=%d",
        g_InventoryInstance[playerid][ammoSlot], current + added, after, after, after,
        g_InventoryInstance[playerid][weaponSlot], s_CharacterID[playerid], itemType,
        s_CharacterID[playerid], g_InventoryType[playerid][ammoSlot], available);
    g_InventoryActionBusy[playerid] = true;
    if (!mysql_tquery(g_DatabaseHandle, query, "Inventory_Reloaded", "ddddddd", playerid,
        s_UISession[playerid], s_CharacterID[playerid], itemType, current + added, added, weaponSlot))
    {
        g_InventoryActionBusy[playerid] = false;
        UI_Notify(playerid, "error", "Khong the nap dan luc nay.");
    }
    return 1;
}

forward Inventory_Reloaded(playerid, session, characterid, itemType, newAmmo, added, weaponSlot);
public Inventory_Reloaded(playerid, session, characterid, itemType, newAmmo, added, weaponSlot)
{
    if (!IsPlayerConnected(playerid) || s_UISession[playerid] != session ||
        s_CharacterID[playerid] != characterid) return 1;
    g_InventoryActionBusy[playerid] = false;
    if (mysql_errno(g_DatabaseHandle) || cache_affected_rows() < 2)
    {
        UI_Notify(playerid, "error", "Nap dan that bai. Tui do da duoc tai lai.");
        if (g_InventoryOpen[playerid]) Inventory_Load(playerid, session, g_InventoryRequest[playerid]);
        return 1;
    }
    new weaponSlotID = Inventory_WeaponSlot(itemType);
    g_InventoryEquippedAmmo[playerid][weaponSlotID - 2] = newAmmo;
    g_InventoryAmmo[playerid][weaponSlot] = newAmmo;
    new WEAPON:actualWeapon, actualAmmo;
    if (GetPlayerWeaponData(playerid, WEAPON_SLOT:weaponSlotID, actualWeapon, actualAmmo) &&
        _:actualWeapon == Inventory_WeaponID(itemType))
        SetPlayerAmmo(playerid, WEAPON:Inventory_WeaponID(itemType), newAmmo);
    else GivePlayerWeapon(playerid, WEAPON:Inventory_WeaponID(itemType), newAmmo);
    new message[80];
    format(message, sizeof message, "Da nap %d vien dan.", added);
    UI_Notify(playerid, "success", message);
    if (g_InventoryOpen[playerid]) Inventory_Load(playerid, session, g_InventoryRequest[playerid]);
    return 1;
}
