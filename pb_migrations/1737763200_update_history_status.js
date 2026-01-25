migrate((app) => {
    const collection = app.findCollectionByNameOrId("history");
    const field = collection.fields.getByName("status");

    // Add "redo" to the options if not already present
    const values = field.values || [];
    if (!values.includes("redo")) {
        values.push("redo");
        field.values = values;
        app.save(collection);
    }
}, (app) => {
    // Revert: remove "redo" from options
    const collection = app.findCollectionByNameOrId("history");
    const field = collection.fields.getByName("status");

    const values = field.values || [];
    const index = values.indexOf("redo");
    if (index > -1) {
        values.splice(index, 1);
        field.values = values;
        app.save(collection);
    }
})
