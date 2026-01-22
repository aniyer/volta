/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = app.findCollectionByNameOrId("bazaar");

    const items = [
        { "item_name": "Extra Screen Time", "cost": 50, "stock": 99 },
        { "item_name": "Ice Cream Trip", "cost": 100, "stock": 5 },
        { "item_name": "Movie Night Pick", "cost": 75, "stock": 10 },
        { "item_name": "Late Bedtime", "cost": 40, "stock": 7 },
        { "item_name": "Skip a Chore", "cost": 30, "stock": 3 },
        { "item_name": "Pizza Party", "cost": 200, "stock": 2 }
    ];

    items.forEach((item) => {
        const record = new Record(collection);
        record.set("item_name", item.item_name);
        record.set("cost", item.cost);
        record.set("stock", item.stock);
        app.save(record);
    });

}, (app) => {
    // Optional: delete created items, but usually safe to leave or tedious to track exact IDs
})
