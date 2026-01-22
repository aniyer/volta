/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = app.findCollectionByNameOrId("users");

    // Add avatar_url field (text)
    // We use a simple text field to store the DiceBear URL
    collection.fields.addAt(7, new Field({
        "name": "avatar_url",
        "type": "text",
        "required": false,
        "presentable": false,
        "system": false,
        "id": "avatar_url_field_id",
        "options": {
            "min": null,
            "max": null,
            "pattern": ""
        }
    }));

    // Remove the default 'avatar' file field if it exists
    // We iterate manually to find the field ID
    let avatarId = "";
    for (const f of collection.fields) {
        if (f.name === "avatar") {
            avatarId = f.id;
            break;
        }
    }

    if (avatarId) {
        collection.fields.removeById(avatarId);
    }

    return app.save(collection);
}, (app) => {
    const collection = app.findCollectionByNameOrId("users");

    // Revert: Remove avatar_url
    collection.fields.removeByName("avatar_url");

    // Revert: Add avatar field back (simplified best-effort)
    collection.fields.add(new Field({
        "name": "avatar",
        "type": "file",
        "options": {
            "maxSelect": 1,
            "maxSize": 5242880,
            "mimeTypes": ["image/jpeg", "image/png", "image/svg+xml", "image/gif", "image/webp"],
            "thumbs": null,
            "protected": false
        }
    }));

    return app.save(collection);
})
