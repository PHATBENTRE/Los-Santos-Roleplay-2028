-- LS:RP migration 008
-- Persistent fuel level for character-owned vehicles.

USE `lsrp`;

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `fuel_liters`
        FLOAT NOT NULL DEFAULT 100.0
        AFTER `health`;
