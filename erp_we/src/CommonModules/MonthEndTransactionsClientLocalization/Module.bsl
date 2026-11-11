#Region Public

#Region TaskRegisters

// Generates parameters for opening forms from the month closing form
// 
// Parameters:
// 	Form - ClientApplicationForm - form closing of the month.
// Returns:
// 	Structure, Undefined - parameter structure:
// * Filter - Structure - Selection structure:
// ** Organization - CatalogRef.Companies - organization for selection.
Function TaskRegisterFormParameters(Form) Export
	
	OrganizationForSelection = OrganizationFromFixedArray(Form.SharedArrayOfCompanies);
	
	If ValueIsFilled(OrganizationForSelection) Then
		RegisterSelectionParameters = New Structure("Organization", OrganizationForSelection);
		RegisterFormParameters  = New Structure("Filter", RegisterSelectionParameters);
	Else
		RegisterFormParameters = Undefined;
	EndIf;
	
	Return RegisterFormParameters;
	
EndFunction

// Gets an organization from the organization array
// 
// Parameters:
// 	SharedArrayOfCompanies - Arbitrary - the requisite forms
// Returns:
// 	CatalogRef.Companies - Link to the organization
Function OrganizationFromFixedArray(SharedArrayOfCompanies) Export
	If Not ValueIsFilled(SharedArrayOfCompanies)
	 Or SharedArrayOfCompanies.Count() <> 1 Then
		Organization = PredefinedValue("Catalog.Companies.EmptyRef");
	Else
		Organization = SharedArrayOfCompanies[0];
	EndIf;
	
	Return Organization;
	
EndFunction

#EndRegion

#Region CommandHandlers


// The command forms of the operations of closing the month.
// 
// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
//
Procedure ExecuteLocalizationCommand(Command, Form) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Form_ServiceCommandHandlers


#EndRegion

#EndRegion
