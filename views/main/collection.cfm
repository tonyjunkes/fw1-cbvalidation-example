<cfparam name="rc.results" default="#{}#">

<cfoutput>
    <h1>Collection (Structure) Validation Results</h1>
    <h2><a href="/">Back</a></h2>
</cfoutput>

<cfdump var="#rc.results.hasErrors()#" label="Has Errors?">
<cfdump var="#rc.results.getAllErrorsAsStruct()#" label="Show Errors As Structure">