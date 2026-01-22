/// <reference path="../pb_data/types.d.ts" />

// Job 1: Replenish Stock
// Schedule: Every Tuesday at 00:00 (Currently testing every minute)
cronAdd("replenish_stock", "0 0 * * 2", () => {
    console.log("[CRON] Starting stock replenishment...");

    try {
        // Use $app directly as evidenced by migration files
        const items = $app.findAllRecords("bazaar");

        for (const item of items) {
            const maxStock = item.getInt("max_stock");

            // Skip items with no max_stock set (or 0)
            if (maxStock <= 0) continue;

            const currentStock = item.getInt("stock");

            if (currentStock < maxStock) {
                item.set("stock", maxStock);

                // Reset claimed_by list
                item.set("claimed_by", []);

                $app.save(item);
                console.log(`[CRON] Replenished ${item.getString('item_name')} to ${maxStock}`);
            }
        }

        console.log("[CRON] Stock replenishment completed.");
    } catch (e) {
        console.log(`[CRON] Error replenishing stock: ${e}`);
    }
});

// Job 2: Decay Volts
// Schedule: Every Tuesday at 00:00
cronAdd("decay_volts", "0 0 * * 2", () => {
    console.log("[CRON] Starting volt decay...");

    try {
        // Use $app directly
        const users = $app.findAllRecords("users");

        for (const user of users) {
            const currentPoints = user.getInt("points");

            if (currentPoints > 0) {
                // 50% Decay, rounded down (integer cast)
                const newPoints = Math.floor(currentPoints * 0.5);

                if (newPoints !== currentPoints) {
                    user.set("points", newPoints);
                    $app.save(user);
                    console.log(`[CRON] Decayed user ${user.getString('username')} from ${currentPoints} to ${newPoints} Volts`);
                }
            }
        }

        console.log("[CRON] Volt decay completed.");
    } catch (e) {
        console.log(`[CRON] Error decaying volts: ${e}`);
    }
});
