USE `lsrp`;

CREATE TABLE IF NOT EXISTS `character_item_instances` (
  `instance_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `character_id` INT UNSIGNED NOT NULL,
  `item_type` TINYINT UNSIGNED NOT NULL,
  `slot` TINYINT UNSIGNED NOT NULL,
  `origin` VARCHAR(32) NULL,
  `state` ENUM('active','consumed','destroyed') NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at` DATETIME NULL,
  KEY `idx_inventory_owner_state` (`character_id`, `state`, `slot`),
  UNIQUE KEY `uq_inventory_origin` (`character_id`, `origin`),
  CONSTRAINT `fk_inventory_item_character` FOREIGN KEY (`character_id`) REFERENCES `player_characters` (`character_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
