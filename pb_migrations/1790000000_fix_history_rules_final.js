/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const history = app.findCollectionByNameOrId("history");

    // Fix rules to allow proper Mission flow

    // Create: Allow auth users to create their own records
    history.createRule = "@request.auth.id != '' && user_id = @request.auth.id";

    // View/List: Parents can see all (for review), Users can see their own
    history.listRule = "@request.auth.role = 'parent' || user_id = @request.auth.id";
    history.viewRule = "@request.auth.role = 'parent' || user_id = @request.auth.id";

    // Update: Only parents can update (approve/reject)
    // Note: If you want children to be able to edit their pending submissions, adjust this.
    history.updateRule = "@request.auth.role = 'parent'";

    return app.save(history);
}, (app) => {
    const history = app.findCollectionByNameOrId("history");

    // Revert to permissive/previous state if needed, but likely we want to stay fixed.
    // We'll revert to broadly auth-only to be safe during rollback
    history.createRule = "@request.auth.id != ''";
    history.listRule = "@request.auth.id != ''";
    history.viewRule = "@request.auth.id != ''";
    history.updateRule = "@request.auth.id != ''";

    return app.save(history);
})
