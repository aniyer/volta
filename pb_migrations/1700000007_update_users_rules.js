/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = app.findCollectionByNameOrId("users");

    // Allow any authenticated user to list/view other users (for Leaderboard)
    collection.listRule = "@request.auth.id != ''";
    collection.viewRule = "@request.auth.id != ''";

    return app.save(collection);
}, (app) => {
    const collection = app.findCollectionByNameOrId("users");

    // Revert to likely default (restrictive)
    collection.listRule = "id = @request.auth.id";
    collection.viewRule = "id = @request.auth.id";

    return app.save(collection);
})
