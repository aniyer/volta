/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = app.findCollectionByNameOrId("users");

    // Add missions_completed field (number)
    collection.fields.addAt(8, new Field({
        "name": "missions_completed",
        "type": "number",
        "required": false,
        "presentable": false,
        "system": false,
        "id": "missions_completed_field",
        "options": {
            "min": 0,
            "max": null,
            "noDecimal": true
        }
    }));

    return app.save(collection);
}, (app) => {
    const collection = app.findCollectionByNameOrId("users");

    // Revert
    collection.fields.removeByName("missions_completed");

    return app.save(collection);
})
