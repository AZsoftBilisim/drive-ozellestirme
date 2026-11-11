#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Restrict the list of companies.
// If a new item is created from a branch, then the branch and the parent company are available.
// If it is from the parent company, then only the parent company is available.
// An exception to the selection of CGU from the impairment document is BHA, it selects CGU only
// of the company for which the document was created.
// 
// Parameters:
//  OpeningParameters - Structure - Parameters
//  Object - CatalogObject.CashGeneratingUnits - Object
//  OwnerElement - FormField - CGU owner
Procedure RestrictListOfOrganizations(OpeningParameters, Object, OwnerElement) Export
	// Let's limit the list of companies.
	OnlyForOrganizationOfDocument = False;
	CompaniesList = New Array;
	If TypeOf(OpeningParameters) = Type("FormDataStructure") Then
		If OpeningParameters.FillingValues.Count() <> 0 Then
			If OpeningParameters.FillingValues.Property("Owner") Then
				If TypeOf(OpeningParameters.FillingValues.Owner) = Type("CatalogRef.Companies") Then
					OwnerWhenOpening = OpeningParameters.FillingValues.Owner;
				ElsIf TypeOf(OpeningParameters.FillingValues.Owner) = Type("ValueList") Then
					// The first of the list will be the company of the document from which the CGU selection Form is opened.
					OnlyForOrganizationOfDocument = (OpeningParameters.FillingValues.Owner.Count() = 1);
					For Each Owner In OpeningParameters.FillingValues.Owner Do
						OwnerWhenOpening = Owner.Value;
						Break;
					EndDo;
				EndIf;
			EndIf;
		Else
			OwnerWhenOpening = Object.Owner;
		EndIf;
	EndIf;

	ParentCompany = Common.ObjectAttributeValue(OwnerWhenOpening, "ParentCompany");

	CompaniesList.Add(OwnerWhenOpening);

	If OwnerWhenOpening <> ParentCompany 
			And OnlyForOrganizationOfDocument = False Then
		CompaniesList.Add(ParentCompany);
	EndIf;
	
	// Set a limit on the values of companies.
	RestrictingListOfOrganizations = New ChoiceParameter("Filter.Ref", New FixedArray(CompaniesList));
	OrganizationSelectionParameters = New Array;
	OrganizationSelectionParameters.Add(RestrictingListOfOrganizations);

	OwnerElement.ChoiceParameters = New FixedArray(OrganizationSelectionParameters);

EndProcedure

#EndRegion

#Region EventHandlers

//@skip-check module-accessibility-at-client
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	//We choose from all CGU owned by the company (branch office) or the parent company.
	StandardProcessing = False;
	
	Organization = Parameters.Filter.Owner;
	
	OnlyForSpecifiedOrganization = False;
	If Parameters.Filter.Property("OnlyForSpecifiedOrganization") Then
		OnlyForSpecifiedOrganization = Parameters.Filter.OnlyForSpecifiedOrganization;
	EndIf;
	
	If OnlyForSpecifiedOrganization Then
		ParentCompany = Organization;
	Else
		ParentCompany = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.Filter.Owner,
																						"ParentCompany");
	EndIf;
	
	If Parameters.Property("ChoiceFoldersAndItems") Then
		If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
			ToSelectGroups   = False;
			ToSelectItems = True;
		ElsIf Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
			ToSelectGroups   = True;
			ToSelectItems = False;
		ElsIf Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems Then
			ToSelectGroups   = True;
			ToSelectItems = True;
		EndIf;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CashGeneratingUnits.Ref AS Ref
	|FROM
	|	Catalog.CashGeneratingUnits AS CashGeneratingUnits
	|WHERE
	|	CashGeneratingUnits.Owner IN (&ParentCompany, &Organization)
	|	AND NOT CashGeneratingUnits.IsFolder = &ToSelectItems
	|
	|UNION
	|
	|SELECT
	|	CashGeneratingUnits.Ref
	|FROM
	|	Catalog.CashGeneratingUnits AS CashGeneratingUnits
	|WHERE
	|	CashGeneratingUnits.Owner IN (&ParentCompany, &Organization)
	|	AND CashGeneratingUnits.IsFolder = &ToSelectGroups";
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("ParentCompany", ParentCompany);
	Query.SetParameter("Organization",         Organization);
	Query.SetParameter("ToSelectGroups",      ToSelectGroups);
	Query.SetParameter("ToSelectItems",    ToSelectItems);
	
	CGUArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	ChoiceData = New ValueList();
	ChoiceData.LoadValues(CGUArray);
	
EndProcedure

#EndRegion

#EndIf
