USE `lsrp`;

-- A firearm is one unique item instance. Its remaining loaded rounds survive relog.
-- Ammunition items use the existing quantity column as loose rounds.
ALTER TABLE `character_item_instances`
  ADD COLUMN `weapon_ammo` SMALLINT UNSIGNED NOT NULL DEFAULT 0 AFTER `quantity`,
  ADD COLUMN `equipped` TINYINT(1) NOT NULL DEFAULT 0 AFTER `weapon_ammo`,
  ADD KEY `idx_inventory_equipped` (`character_id`, `equipped`, `state`);
