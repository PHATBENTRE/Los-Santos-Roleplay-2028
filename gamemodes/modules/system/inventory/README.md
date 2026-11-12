# Inventory CEF

Apply migrations `009_inventory.sql` through `014_inventory_ammo_groups.sql` in order. Apply `014` once with the server stopped when upgrading existing inventory data. Existing installations only need migrations that have not yet been applied.

Open or close with `/inventory` or `/inv`; Escape and the close button also close the panel. The first open grants water, food, and a bandage. `/giveitem [playerid] [type] [amount]` grants items 1–12: supplies (1–3), firearms (4–7 and 12), and pistol, shotgun, rifle, and SMG ammunition (8–11).

Each character has 50 carried slots. The sidebar shows current game cash and the character's bank balance when the inventory snapshot loads. The shared CEF styles prevent accidental text/image selection while preserving text selection inside form fields.

The inventory shows the player's actual skin ID using a bundled still image. The 36 skin images used by the character creator come from [open.mp's skin previews](https://open.mp/docs/scripting/resources/skins) and are stored locally in `scriptfiles/cef/lsrp/skins`. No live browser network request or 3D render is needed.

Click an item to open its action menu. Use consumes one unit. Discard sets the database row to `destroyed` with `ended_at` and does not create a ground item. Information shows the stack's stable 16-digit public ID (`1000000000000000 + instance_id`). Drag between carried slots, or choose Move and then a destination slot, to reorder items. The current UI does not expose ground or vehicle trunks. Legacy ground rows remain in the database; no ground object is spawned by this version.
