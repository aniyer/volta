/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    // 1. History Collection Check
    const history = app.findCollectionByNameOrId("history");

    // Parent can see all, Child can see own
    history.listRule = "@request.auth.role = 'parent' || user_id = @request.auth.id";
    history.viewRule = "@request.auth.role = 'parent' || user_id = @request.auth.id";

    // Auth users can create (submit mission)
    history.createRule = "@request.auth.id != '' && user_id = @request.auth.id";

    // Only parent can update (approve/reject)
    history.updateRule = "@request.auth.role = 'parent'";

    app.save(history);

    // 2. Missions Collection
    const missions = app.findCollectionByNameOrId("missions");
    missions.listRule = "@request.auth.id != ''"; // Visible to all auth users
    missions.viewRule = "@request.auth.id != ''";
    app.save(missions);

    // 3. Bazaar Collection
    const bazaar = app.findCollectionByNameOrId("bazaar");
    bazaar.listRule = "@request.auth.id != ''";
    bazaar.viewRule = "@request.auth.id != ''";
    bazaar.updateRule = "@request.auth.id != ''"; // Allow claiming
    app.save(bazaar);

    // 4. Users Collection
    const users = app.findCollectionByNameOrId("users");
    users.listRule = "@request.auth.id != ''";
    users.viewRule = "@request.auth.id != ''";
    users.updateRule = "id = @request.auth.id || @request.auth.role = 'parent'";
    app.save(users);

}, (app) => {
    // Revert to null (locked)
    const history = app.findCollectionByNameOrId("history");
    history.listRule = null;
    history.viewRule = null;
    history.createRule = null;
    history.updateRule = null;
    app.save(history);

    // ... (omitting other reverts for brevity as this is a fix)
})
