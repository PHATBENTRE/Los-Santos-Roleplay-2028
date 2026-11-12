USE `lsrp`;

-- The starter grant belongs to its original character even after the item changes hands.
ALTER TABLE `character_item_instances`
  ADD COLUMN `origin_character_id` INT UNSIGNED NULL AFTER `origin`;

UPDATE `character_item_instances`
  SET `origin_character_id` = `character_id`
  WHERE `origin` IS NOT NULL;

ALTER TABLE `character_item_instances`
  DROP KEY `uq_inventory_origin`,
  ADD UNIQUE KEY `uq_inventory_seed` (`origin_character_id`, `origin`);
