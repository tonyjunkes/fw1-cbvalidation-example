component {
	this.name = "FW1CBValidationTestingSuite" & hash( getCurrentTemplatePath() );
	variables.testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings = {
		"/tests": variables.testsPath,
		"/testbox": variables.testsPath & "../testbox",
		"/framework": variables.testsPath & "../framework",
		"/model": variables.testsPath & "/resources",
		"/cbvalidation" = variables.testsPath & "../subsystems/cbvalidation",
		"/cbi18n" = variables.testsPath & "../subsystems/cbvalidation/modules/cbi18n",
		// This is to fake the subsystem location
		"/tests/subsystems/cbvalidation": variables.testsPath & "../subsystems/cbvalidation"
	};
}