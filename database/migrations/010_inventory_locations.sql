USE `lsrp`;

ALTER TABLE `character_item_instances`
  ADD COLUMN `location` ENUM('carried','ground','trunk') NOT NULL DEFAULT 'carried' AFTER `slot`,
  ADD COLUMN `vehicle_id` INT UNSIGNED NULL AFTER `location`,
  ADD COLUMN `pos_x` FLOAT NULL AFTER `vehicle_id`,
  ADD COLUMN `pos_y` FLOAT NULL AFTER `pos_x`,
  ADD COLUMN `pos_z` FLOAT NULL AFTER `pos_y`,
  ADD COLUMN `interior_id` INT NOT NULL DEFAULT 0 AFTER `pos_z`,
  ADD COLUMN `virtual_world` INT NOT NULL DEFAULT 0 AFTER `interior_id`,
  ADD KEY `idx_inventory_ground` (`location`, `virtual_world`, `interior_id`),
  ADD KEY `idx_inventory_trunk` (`location`, `vehicle_id`);
