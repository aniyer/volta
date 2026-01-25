migrate((app) => {
    const history = app.findCollectionByNameOrId("history");

    // Fix rules to allow proper Mission flow

    // Create: Allow auth users to create their own records
    history.createRule = "@request.auth.id != '' && user_id = @request.auth.id";

    // View/List: Parents can see all (for review), Users can see their own
    history.listRule = "@request.auth.role = 'parent' || user_id = @request.auth.id";
    history.viewRule = "@request.auth.role = 'parent' || user_id = @request.auth.id";

    // Update: Parents can update (approve/reject), OR users can update their own if it's in 'redo' or 'review' state (resubmitting)
    history.updateRule = "@request.auth.role = 'parent' || (@request.auth.id = user_id && (status = 'redo' || status = 'review'))";

    return app.save(history);
}, (app) => {
    const history = app.findCollectionByNameOrId("history");

    // Revert to parent-only update
    history.updateRule = "@request.auth.role = 'parent'";

    return app.save(history);
})
