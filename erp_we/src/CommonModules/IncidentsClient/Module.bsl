#Region Private

Procedure CreateIncidentBySubject(SubjectOf, Parameters) Export
	
	FormParameters = New Structure("SubjectOf", SubjectOf);
	OpenForm("Catalog.Incidents.ObjectForm", FormParameters, Parameters.Form);

EndProcedure

#EndRegion