component extends="testbox.system.BaseSpec" {
	function __config() {
		return variables.framework;
	}

	function initFW1App() {
		// Reset the framework instance before each spec is run
		request.delete( "_fw1" );
		variables.fw = new framework.one();
		variables.fw.__config = __config;
		variables.fw.__config().append({
			diEngine: "di1",
			diLocations: [ "/model" ],
			diConfig: {
				loadListener: ( di1 ) => {
					// Create an impersonation of WireBox :D
					di1.declare( "WireBox" ).asValue({
						getInstance: ( name, initArguments = {} ) => {
							if ( name.find( "." ) ) {
								var pathSplit = name.listToArray( "." );
								var module = pathSplit.first();
								var bean = pathSplit.last();

								// Does the dotted path evaluate to a module bean?
								if ( variables.fw.getBeanFactory( module ).containsBean( bean ) ) {
									return variables.fw.getBeanFactory( module ).getBean( bean, initArguments );
								}
								// Else check if a CFC path was passed and instantiate it
								else if ( fileExists( expandPath( name.replace( ".", "/", "all" ) & ".cfc" ) ) ) {
									return createObject( "component", name );
								}
								// Else fail the process
								else {
									throw( "No beans could be found based on the dotted path provided." );
								}
							}
							// Otherwise it's a bean to fetch from a bean factory
							else {
								// Parse object@module to get subsystem
								var module = name.listToArray( "@" ).last();
								return variables.fw.getBeanFactory( module ).getBean( name, initArguments );
							}
						}
					});

					// Make the ValidationManager first class to the parent bean factory
					di1.declare( "ValidationManager" ).asValue( variables.fw.getBeanFactory( "cbvalidation" ).getBean( "ValidationManager" ) );
				}
			},
			validation: {
				manager: "cbvalidation.models.ValidationManager",
				sharedConstraints: {
					loginForm: {
						username: { required: true }, password: { required: true }
					}
				}
			},
			subsystems: {
				cbvalidation: {
					diLocations: [ "/models" ],
					diConfig: {
						singulars: { "models": "@cbvalidation", "result": "@cbvalidation", "validators": "@cbvalidation" },
						transientPattern: "(Object|Error|Result)$",
						loadListener: ( di1 ) => {
							var settings = variables.fw.getConfig();

							di1.declare( "WireBox" ).asValue( variables.fw.getBeanFactory().getBean( "WireBox" ) ).done()
								// Load in shared constraints from validation service
								.declare( "SharedConstraints" ).asValue( settings.validation.sharedConstraints ).done()
								// Fake the cbi18n resource service
								.declare( "ResourceService" ).asValue( { getResource: () => "" } );

							// Custom validation manager?
							var manager = settings.validation.manager;
							if ( manager != "cbvalidation.models.ValidationManager" ) {
								di1.declare( "ValidationManager" ).instanceOf( manager ).asSingleton().done()
									.declare( "ValidationManager@cbvalidation" ).aliasFor( "ValidationManager" ).asSingleton();
							}
							// Setup shared constraints
							di1.declare( "ValidationManager" ).instanceOf( manager ).asSingleton().done()
								.declare( "ValidationManager@cbvalidation" ).aliasFor( "ValidationManager" ).asSingleton();
						}
					}
				}
			}
		});
		variables.fw.onApplicationStart();
	}

	/*********************************** BDD SUITES ***********************************/

	function run() {
		describe( "Validation", function() {
			beforeEach(function( currentSpec ){
				initFW1App();
				ValidationManager = variables.fw.getBeanFactory().getBean( "ValidationManager" );
			});

			it ( "can validate a collection", function() {
				var loginForm = { username: "", password: "" };
				var results = ValidationManager.validate(
					target = loginForm,
					constraints = "loginForm"
				);
				var errors = results.getAllErrorsAsStruct();

				expect( results.hasErrors() ).toBe( true );
				expect( errors ).toHaveLength( 2 );
				expect( errors ).toHaveKey( "username" );
				expect( errors ).toHaveKey( "password" );
			});

			it ( "can validate a domain object", function() {
				var user = variables.fw.getBeanFactory().getBean( "User" );
				var userData = {
					id: 1,
					firstName: "Test",
					lastName: "User",
					email: "bad@email",
					username: "testuser",
					password: "password123",
					age: 32
				};
				var thisUser = variables.fw.getBeanFactory().injectProperties( user, userData );
				var results = thisUser.validate();
				var errors = results.getAllErrorsAsStruct();

				expect( results.hasErrors() ).toBe( true );
				expect( errors ).toHaveLength( 2 );
				expect( errors ).toHaveKey( "email" );
				expect( errors ).toHaveKey( "password" );
			});
		});
	}
}
