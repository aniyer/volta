/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = app.findCollectionByNameOrId("bazaar");

    // Add max_stock field
    const field = new Field({
        "name": "max_stock",
        "type": "number",
        "required": false,
        "presentable": false,
        "system": false,
        "id": "max_stock_field_id", // Optional custom ID
        "options": {
            "min": 0,
            "max": null,
            "noDecimal": true
        }
    });

    collection.fields.add(field);

    app.save(collection);

    // Backfill max_stock with current stock for existing items
    // This ensures we have a baseline for replenishment
    const items = app.findAllRecords("bazaar");
    items.forEach((item) => {
        // If stock > 0, assume that is the max. If 0, default to 5 or higher?
        // Let's assume current stock is the intended max for initial setup.
        // If stock is 0, let's look at the seed data if possible, or default to 5.
        let currentStock = item.getInt("stock");
        if (currentStock === 0) {
            currentStock = 5; // Default fallback
        }

        // Check if this item is one of our known seeds to be smarter
        const name = item.getString("item_name");
        if (name === "Extra Screen Time") currentStock = 99;
        if (name === "Ice Cream Trip") currentStock = 5;
        if (name === "Pizza Party") currentStock = 2;

        item.set("max_stock", currentStock);
        app.save(item);
    });

}, (app) => {
    const collection = app.findCollectionByNameOrId("bazaar");
    collection.fields.removeById("max_stock_field_id"); // Or find by name
    app.save(collection);
})
