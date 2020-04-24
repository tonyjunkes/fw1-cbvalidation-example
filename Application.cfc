component extends="framework.one"
	output="false"
{
	this.applicationTimeout = createTimeSpan( 0, 2, 0, 0 );
	this.setClientCookies = true;
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 );
	this.mappings = {
		"/cbvalidation" = expandPath( "./subsystems/cbvalidation" ),
		"/cbi18n" = expandPath( "./subsystems/cbvalidation/modules/cbi18n" )
	};

	// FW/1 settings
	variables.framework = {
		defaultSection: "main",
		defaultItem: "default",
		error: "main.error",
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
							if ( getBeanFactory( module ).containsBean( bean ) ) {
								return getBeanFactory( module ).getBean( bean, initArguments );
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
							return getBeanFactory( module ).getBean( name, initArguments );
						}
					}
				});

				// Make the ValidationManager first class to the parent bean factory
				di1.declare( "ValidationManager" ).asValue( getBeanFactory( "cbvalidation" ).getBean( "ValidationManager" ) );
			}
		},
		validation: {
			manager: "cbvalidation.models.ValidationManager",
			sharedConstraints: {
				sharedUser: {
					fName: { required: true },
					lname: { required: true },
					age: { required: true, max: 18 },
					metadata: { required: false, type: "json" }
				},
				loginForm: {
					username: { required: true }, password: { required: true }
				},
				changePasswordForm: {
					password: { required: true, min: 6 }, password2: { required: true, sameAs: "password", min: 6 }
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
						var settings = getConfig();

						di1.declare( "WireBox" ).asValue( getBeanFactory().getBean( "WireBox" ) ).done()
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
		},
		trace: true,
		reloadApplicationOnEveryRequest: true,
		routes: [
			{ "/collection": "/main/collection" },
			{ "/domain": "/main/domain" },
			{ "/": "/main/default" }
		]
	};
}