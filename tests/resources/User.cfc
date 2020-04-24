component displayname="User Domain Object" accessors=true
    output=false
{
    // Dependencies
    property ValidationManager;

    // Object properties
    property name="id";
    property name="firstName";
    property name="lastName";
    property name="email";
    property name="username";
    property name="password";
    property name="age";

    // Validation
    this.constraints = {
        firstName: { required: true },
        lastName: { required: true},
        username: { required: true, size: "6..10" },
        password: { required: true, size: "6..8" },
        email: { required: true, type: "email" },
        age: { required: true, type: "numeric", min: 18 }
    };

    ValidationResult function validate() {
        return variables.ValidationManager.validate( this );
    }
}
