/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = app.findCollectionByNameOrId("missions");

    const items = [
        { "title": "Make Bed", "icon": "bed", "base_points": 10, "is_active": true },
        { "title": "Dishes", "icon": "kitchen", "base_points": 20, "is_active": true },
        { "title": "Vacuum", "icon": "cleaning_services", "base_points": 30, "is_active": true },
        { "title": "Laundry", "icon": "local_laundry_service", "base_points": 25, "is_active": true },
        { "title": "Feed Pet", "icon": "pets", "base_points": 15, "is_active": true },
        { "title": "Take Trash", "icon": "delete", "base_points": 15, "is_active": true }
    ];

    items.forEach((item) => {
        const record = new Record(collection);
        record.set("title", item.title);
        record.set("icon", item.icon);
        record.set("base_points", item.base_points);
        record.set("is_active", item.is_active);
        app.save(record);
    });

}, (app) => {
    // Optional: delete created items
})
