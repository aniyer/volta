migrate((app) => {
    const collection = app.findCollectionByNameOrId("history");
    const field = collection.fields.getByName("status");

    // Start debug
    console.log("FORCE MIGRATION: Checking status field...");

    // Add "redo" to the options if not already present
    // Using top-level 'values' property for select fields in recent PB versions
    const values = field.values || [];
    console.log("FORCE MIGRATION: Current values:", JSON.stringify(values));

    if (!values.includes("redo")) {
        console.log("FORCE MIGRATION: Adding 'redo'...");
        values.push("redo");
        field.values = values;
        app.save(collection);
        console.log("FORCE MIGRATION: Saved collection.");
    } else {
        console.log("FORCE MIGRATION: 'redo' already present.");
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
