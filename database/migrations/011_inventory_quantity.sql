USE `lsrp`;

ALTER TABLE `character_item_instances`
  ADD COLUMN `quantity` SMALLINT UNSIGNED NOT NULL DEFAULT 1 AFTER `item_type`;
