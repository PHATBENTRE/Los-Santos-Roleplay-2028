USE `lsrp`;

-- Old 8=9mm, 9=.50, 10=12 gauge, 11=5.56.
-- New 8=pistol (9mm and .50), 9=shotgun, 10=rifle, 11=SMG.
-- Preserve instance IDs, quantities, origin and lifecycle history.
-- Apply once while the server is stopped, before starting the updated gamemode.
UPDATE `character_item_instances`
SET `item_type` = CASE `item_type`
    WHEN 9 THEN 8
    WHEN 10 THEN 9
    WHEN 11 THEN 10
    ELSE `item_type`
END
WHERE `item_type` IN (9, 10, 11);
