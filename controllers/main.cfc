component name="Main Controller" accessors=true
	output=false
{
	property framework;
	property ValidationManager;
	property User;

	void function default( rc ) {}

	void function collection( rc ) {
		// Fake a login form submission in the request context
		rc.form = { username: "", password: "" };

		// Validate the form data
		// Both fields should fail for being empty
		rc.results = variables.ValidationManager.validate(
			target = rc.form,
			constraints = "loginForm"
		);
	}

	void function domain( rc ) {
		// Fake some user data in the request context
		rc.append({
			id: 1,
			firstName: "Test",
			lastName: "User",
			email: "bad@email", // Email should fail format validation
			username: "testuser",
			password: "password123", // Password should fail length validation (too long)
			age: 32
		});

		// Populate User bean
		var thisUser = variables.framework.populate( variables.User );

		rc.results = thisUser.validate();
	}
}
