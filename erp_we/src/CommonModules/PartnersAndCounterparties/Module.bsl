#Region Public

// Gets the default counterparty
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner for which you need to get a counterparty.
//
// Returns:
//   CatalogRef.Counterparties   - the partner's counterparty by default.
//
Function GetPartnerSDefaultCounterparty(Partner) Export
	
	RowData = New Structure;
	RowData.Insert("Partner",    Partner);
	RowData.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	
	Actions = New Structure;
	Actions.Insert("FillInPartnerSDefaultCounterparty");
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		RowData,
		Actions,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
	
	Return RowData.Counterparty;
	
EndFunction

// Fills in the counterparty for the partner.
//
// Parameters:
//   Partner                  - CatalogRef.Partners - The partner whose counterparty you need to fill in.
//   Counterparty               - CatalogRef.Counterparties -The counterparty to fill in.
//   RefillingCounterparty - Boolean -Indicates whether the counterparty needs to be refilled.
//
Procedure FillInPartnerSDefaultCounterparty(Val Partner, Counterparty, RefillingCounterparty = False) Export
	
	If ValueIsFilled(Partner)
		And (RefillingCounterparty Or Not ValueIsFilled (Counterparty)) Then
		
		If ValueIsFilled(Counterparty) Then
			If CounterpartyIsAvailableForSelectionForPartner(Partner, Counterparty) Then
				Return;
			EndIf;
		EndIf;
		
		DefaultCounterparty = GetPartnerSDefaultCounterparty(Partner);
		
		If DefaultCounterparty <> Undefined Then
			Counterparty = DefaultCounterparty;
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks whether the counterparty is available for selection in the partner's documents.
//
// Parameters:
//   Partner                  - CatalogRef.Partners - The partner whose counterparty needs to be checked.
//   Counterparty               - CatalogRef.Counterparties -the counterparty being checked.
//
// Returns:
//   Boolean - True if available, False otherwise.
//
Function CounterpartyIsAvailableForSelectionForPartner(Partner, Counterparty) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED DISTINCT TOP 1
	|	Counterparties.Ref AS Counterparty
	|FROM
	|	InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON PartnerHierarchy.Parent = Counterparties.Partner
	|WHERE
	|	PartnerHierarchy.Partner = &Partner
	|	AND Counterparties.Ref = &Counterparty";
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Checks whether the partner is a parent for other partners.
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner that the verification is being performed for.
//
// Returns:
//   Boolean - True if it is, False in the opposite case.
//
Function ThereAreSubordinatePartners(Partner) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT TOP 1
	|	Partners.Ref
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Parent = &Partner
	|");
	Query.SetParameter("Partner",Partner);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Updates the full-text search index
Procedure UpdateFullTextSearchIndex() Export
	
	SetPrivilegedMode(True);
	FullTextSearch.UpdateIndex();
	
EndProcedure

// Gets an array of counterparties available for selection by the partner.
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner for which you need to get contractors.
//
// Returns:
//  Array -  an array containing all counterparties available to the partner.
// 
Function GetAllPartnersOfPartner(Partner) Export
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	|	Counterparties.Ref AS Counterparty
	|FROM
	|	InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON PartnerHierarchy.Parent = Counterparties.Partner
	|WHERE
	|	PartnerHierarchy.Partner = &Partner";
	
	Query.SetParameter("Partner", Partner);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return New Array;
	Else
		Return QueryResult.Unload().UnloadColumn("Counterparty");
	EndIf;
	
EndFunction

// Gets an array of lower-level partners.
//
// Parameters:
//  Partner  -  CatalogRef.Partners - partner for which you want to obtain counterparties.
//
// Returns:
//  Array -  contains all the lower-level partners and the partner himself.
//
Function GetDownstreamPartners(Partner) Export
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	|	PartnerHierarchy.Partner
	|FROM
	|	InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|WHERE
	|	PartnerHierarchy.Parent = &Partner";
	
	Query.SetParameter("Partner",Partner);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return New Array;
	Else
		Return QueryResult.Unload().UnloadColumn("Partner");
	EndIf;
	
EndFunction

// Gets a list of the partner's parents from the bottom up in the hierarchy.
//
// Parameters:
//  Partner  - CatalogRef.Partners - the partner for which the list is generated.
//  PartnerListWithParents  - ValueList - a list of the partner's parents to fill in.
//
Procedure FillInListOfPartnersWithParents(Partner,PartnerListWithParents) Export
	
	PartnerListWithParents.Clear();
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Get a partner's parents
	Query = New Query(
	"SELECT
	|	Partners.Ref AS Ref,
	|	Partners.Description
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref = &Partner
	|TOTALS BY
	|	Ref HIERARCHY
	|");
	Query.SetParameter("Partner",Partner);
	
	HierarchyTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	FillInListOfPartnersFromTree(HierarchyTree.Rows, PartnerListWithParents,Partner);
	
EndProcedure

// Retrieves a list of all parent and child elements of the partner in the hierarchy.
//
// Parameters:
//  Partner                   - CatalogRef.Partners - the partner for which the list is generated.
//  PartnerListWithParents - ValueList - a list of values that includes the partner itself and all parents and children in the hierarchy
//
Procedure FillInPartnerListWithAllHierarchy(Partner, PartnerListWithParents) Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		Counterparty = GetPartnerSDefaultCounterparty(Partner);
		MainCounterparty = Common.ObjectAttributeValue(Counterparty, "MainCounterparty");
		Counterparty = ?(ValueIsFilled(MainCounterparty), MainCounterparty, Counterparty);
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	Counterparties.Partner AS Partner,
		|	PRESENTATION(Counterparties.Partner) AS Presentation
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	Counterparties.Ref = &Counterparty
		|	OR Counterparties.MainCounterparty = &Counterparty
		|
		|GROUP BY
		|	Counterparties.Partner
		|";
		
		Query.SetParameter("Counterparty", Counterparty);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			PartnerListWithParents.Add(Selection.Partner, Selection.Presentation);
		EndDo;
		
	Else
		Query = New Query;
		Query.Text = "
		|SELECT ALLOWED
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Parent
		|		ELSE PartnerHierarchy.Partner
		|	END AS Partner,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PRESENTATION(PartnerHierarchy.Parent)
		|		ELSE PRESENTATION(PartnerHierarchy.Partner)
		|	END AS Presentation
		|FROM
		|	InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|WHERE
		|	(PartnerHierarchy.Partner = &Partner
		|			OR PartnerHierarchy.Parent = &Partner)";
		
		Query.SetParameter("Partner", Partner);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			PartnerListWithParents.Add(Selection.Partner, Selection.Presentation);
		EndDo;
		
	EndIf;
	
	Return;
	
EndProcedure

// The transferred value of the transfer determines whether It is a sign of a legal Entity.
//
// Parameters:
//  LegalEntityIndividual  - EnumRef.LegalEntityIndividual - the value passed in.
//
// Returns:
//  Boolean, Undefined - True if a legal entity, False if not, Undefined if the value of the legal entity is not set.
//
Function ThisIsYurFace(LegalEntityIndividual) Export
	
	If LegalEntityIndividual = Enums.LegalEntityIndividual.Entity Or LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident Then
		Return True;
	ElsIf LegalEntityIndividual = Enums.LegalEntityIndividual.Person Or LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur Then
		Return False;
	ElsIf TypeOf(LegalEntityIndividual) = Type("EnumRef.CompanyIndividual") Then
	 	Return LegalEntityIndividual <> Enums.CompanyIndividual.Individual;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Determines whether simplified partner and counterparty input is available to the user.
//
// Returns:
//   Boolean   - True if used, and false otherwise.
//
Function SimplifiedInputAvailable() Export
	
	Return AccessRight("Insert", Metadata.Catalogs.Partners) And UserRightsCached.EnterInformationAboutPartnerWithoutControl();
	
EndFunction

// Determines whether there is a counterparty in the database with the same set of Registrationnumber/country of Registration.
//
// Parameters:
//  RegistrationNumber   - String - Registration number of the counterparty to search in the database.
//  RegistrationCountry      - CatalogRef.WorldCountries - country of registration of the counterparty to search in the database.
//  ExcludingLink         - CatalogRef.Counterparties - the counterparty that is excluded in the search.
//
// Returns:
//   Boolean   - True if the counterparty with such registration number and country of registration already exists in the database.
//
Function CountryRegistrationNumberIsAlreadyUsedInInformationBase(RegistrationNumber, RegistrationCountry, ExcludingLink = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	Counterparties.Ref,
	|	Partners.Ref AS Partner,
	|	Partners.Code AS Code,
	|	PRESENTATION(Partners.MainManager) AS MainManager
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON Counterparties.Partner = Partners.Ref
	|WHERE
	|	Counterparties.RegistrationNumber = &RegistrationNumber
	|	AND Counterparties.RegistrationCountry = &RegistrationCountry
	|	AND Counterparties.Ref <> &Ref";
	
	Query.SetParameter("RegistrationNumber",RegistrationNumber);
	Query.SetParameter("RegistrationCountry",RegistrationCountry);
	Query.SetParameter("Ref",ExcludingLink);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Removes the selection element from the settings and user settings.
//
// Parameters:
//  SettingsComposer   - DataCompositionSettingsComposer - 
//  ItemPresentation - String - representation of the item to be deleted.
//
Procedure DeleteItemFromReportSelectionSettings(SettingsComposer, ItemPresentation) Export

	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(SettingsComposer.Settings.Filter, ItemPresentation);
		For Each FilterElement In FilterItems1 Do
			UserSettingID = FilterElement.UserSettingID;
			SettingsComposer.Settings.Filter.Items.Delete(FilterElement);
			
			ItemTheCustomSettings = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
			If ItemTheCustomSettings <> Undefined Then
				SettingsComposer.UserSettings.Items.Delete(UserSettingID);
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

// Fills in the contact person for the partner
//
// Parameters:
// Partner - CatalogRef.Partners - Partner whose contact person you need to fill in
// ContactPerson - CatalogRef.ContactPersonsForPartners -Contact person to fill in.
//
Procedure FillInDefaultPartnerContactPerson(Val Partner, ContactPerson) Export
	
	If Not ValueIsFilled(Partner) Then
		ContactPerson = Catalogs.ContactPersonsForPartners.EmptyRef();
		Return;
	EndIf;
	
	If ValueIsFilled(ContactPerson) And Common.ObjectAttributeValue(ContactPerson, "Owner") <> Partner Then
		ContactPerson = Catalogs.ContactPersonsForPartners.EmptyRef();
	EndIf;
	
	If Not ValueIsFilled(ContactPerson) Then
		
		DefaultContactPerson = GetDefaultPartnerContactPerson(Partner);
		
		If DefaultContactPerson <> Undefined Then
			ContactPerson = DefaultContactPerson;
		EndIf;
		
	EndIf;
	
EndProcedure

// Gets the default contact person of the counterparty's partner.
//
// Parameters:
//  Counterparty  - CatalogRef.Counterparties - the counterparty whose partner needs to get a contact person.
//
// Returns:
//   CatalogRef.ContactPersonsForPartners  - the default contact person of the counterparty's partner.
//
Function GetDefaultCounterpartyPartnerContactPerson(Counterparty) Export

	Query = New Query;
	Query.Text = "
	|SELECT
	|	Counterparties.Partner AS Owner
	|INTO OwnerOfContactPerson
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Ref = &Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN NestedQuery.Count = 1
	|			THEN ContactPersonsForPartners.Ref
	|		ELSE VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|	END AS ContactPerson
	|FROM
	|	(SELECT
	|		COUNT(DISTINCT ContactPersonsForPartners.Ref) AS Count
	|	FROM
	|		Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	WHERE
	|		ContactPersonsForPartners.Owner IN
	|				(SELECT
	|					OwnerOfContactPerson.Owner AS Owner
	|				FROM
	|					OwnerOfContactPerson)
	|		AND NOT ContactPersonsForPartners.DeletionMark) AS NestedQuery,
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner IN
	|			(SELECT
	|				OwnerOfContactPerson.Owner AS Owner
	|			FROM
	|				OwnerOfContactPerson)";
	
	Query.SetParameter("Counterparty", Counterparty);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.ContactPersonsForPartners.EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.ContactPerson;
	
EndFunction

// Gets the partner's default contact person.
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner for which you need to get a contact person.
//
// Returns:
//   CatalogRef.ContactPersonsForPartners - the default contact person of the partner.
//
Function GetDefaultPartnerContactPerson(Partner) Export

	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	CASE
	|		WHEN NestedQuery.Count = 1
	|			THEN ContactPersonsForPartners.Ref
	|		ELSE VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|	END AS ContactPerson
	|FROM
	|	(SELECT
	|		COUNT(DISTINCT ContactPersonsForPartners.Ref) AS Count
	|	FROM
	|		Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	WHERE
	|		ContactPersonsForPartners.Owner = &Partner
	|		AND NOT ContactPersonsForPartners.DeletionMark
	|		AND (ContactPersonsForPartners.RelationEndDate > &CurrentDate
	|			OR ContactPersonsForPartners.RelationEndDate = &DateEmpty)) AS NestedQuery,
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner = &Partner
	|	AND NOT ContactPersonsForPartners.DeletionMark
	|	AND (ContactPersonsForPartners.RelationEndDate > &CurrentDate
	|		OR ContactPersonsForPartners.RelationEndDate = &DateEmpty)";
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("DateEmpty", Date(1,1,1));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.ContactPersonsForPartners.EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.ContactPerson;
	
EndFunction

Procedure SetAdvancedSearchHint(ExplanationAdvancedSearch) Export

	Template = Catalogs.Partners.GetTemplate("AdvancedSearch");
	
	Try
		
		ObjectIsHTMLDocument = Template.GetHTMLDocument();
		
		ExplanationText = HTMLTextFromHTMLDocumentObject(ObjectIsHTMLDocument);
		
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			ExplanationText = StrReplace(ExplanationText, NStr("vi = 'Bạn hàng';
																|ru = 'Партнеры';
																|en = 'Partners'; fa = 'شرکای تجاری';
																|it = 'Партнеры';
																|pl = 'Partners';
																|tr = 'İş ortakları'"), NStr("vi = 'Đối tác';
																						|ru = 'Контрагенты';
																						|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
																						|it = 'Контрагенты';
																						|pl = 'Counterparties';
																						|tr = 'Cari hesaplar'"));
		EndIf;
		
	Except
		
		ExplanationText = "";
	
	EndTry;
	
	ExplanationAdvancedSearch = ExplanationText;
	
	
EndProcedure

#Region SeparateBusinessUnits

// Gets its separate divisions for the selected counterparty.
//
// Parameters:
//  MainCounterparty - CatalogRef.Counterparties - the counterparty for which you want to separate divisions.
//
// Returns:
//   Array - array of subordinate counterparties.
//
Function SeparateDivisionsOfCounterparty(MainCounterparty) Export
	
	ArrayOfCounterparties = New Array;
	
	If Not ValueIsFilled(MainCounterparty) Then
		Return ArrayOfCounterparties;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("MainCounterparty", MainCounterparty);
	
	Query.Text = 
	"SELECT ALLOWED
	|	Counterparties.Ref AS Ref,
	|	Counterparties.Description AS Description
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Ref <> &MainCounterparty
	|	AND Counterparties.MainCounterparty = &MainCounterparty
	|	AND Counterparties.BranchOffice
	|	AND NOT Counterparties.DeletionMark";
	
	Result = Query.Execute();
	ArrayOfCounterparties = Result.Unload().UnloadColumn("Ref");
	
	Return ArrayOfCounterparties;
	
EndFunction

// Sets the conditional execution field Golodnosteppe table forms.
// If the counterparty is a separate division and the head office is not filled in, then the element is highlighted.
//
// Parameters:
//  Form - ClientApplicationForm - THE Form for which conditional registration is set contains:
//  * Items - FormAllItems - Contains:
//    ** MainCounterparty - FormField -
//
Procedure SetRegistrationOfHeadCounterpartyInList(Form) Export

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items; //

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MainCounterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BranchOffice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.MainCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MainCounterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BranchOffice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.MainCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailableToAddPartners");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", "Fill");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", New Font(, , , , True));

EndProcedure

// Converts the contact information representation to an internal JSON format.
//
// For addresses entered in free form, correct conversion is not guaranteed.
//
//  Parameters:
//      Presentation - String  - string representation of contact information displayed to the user.
//      FieldValues - String - contact information in JSON format.
//      ContactInformationKind - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes, Structure - type or type of contact information.
//
Procedure ValuesOfContactInformationFields(Val Presentation, FieldValues, Val ContactInformationKind) Export
	
	// Creating a new instance based on the view
	FieldValues = ContactsManager.ContactsByPresentation(Presentation, ContactInformationKind);
	
EndProcedure

#EndRegion

#Region PartnerHierarchy

// Writes to the partner Hierarchy PC for an array of passed partners or for the entire directory,
// if the array is not passed to the procedure.
//
// Parameters:
//   ArrayOfPartners - Array of CatalogRef.Partners - contains the partners for which you need to make an entry in the PC "Partner Hierarchy".
//
Procedure PerformPartnerHierarchyEntry(ArrayOfPartners = Undefined) Export
	
	If ArrayOfPartners = Undefined Then
		
		Query = New Query;
		Query.Text = "SELECT
		|	Partners.Ref
		|FROM
		|	Catalog.Partners AS Partners
		|WHERE
		|	Partners.Parent = VALUE(Catalog.Partners.EmptyRef)";
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			RecordPartnerHierarchy(Selection.Ref);
			
		EndDo;
		
	Else
		
		For Each ArrayElement In ArrayOfPartners Do
			
			RecordPartnerHierarchy(ArrayElement);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Clears the partner Hierarchy PC"
Procedure ClearPartnerHierarchyInformationRegister() Export
	
	RecordSet = InformationRegisters.PartnerHierarchy.CreateRecordSet();
	RecordSet.Write();
	
EndProcedure

// Writes to the partner Hierarchy PC for the partner passed to the procedure.
//
// Parameters:
//  Ref - CatalogRef.Partners - link to the partner to be recorded in the partner Hierarchy PC.
//
Procedure RecordPartnerHierarchy(Ref) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT
	|	Partners.Ref AS Ref
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref IN HIERARCHY(&Ref)
	|TOTALS BY
	|	Ref HIERARCHY";
	
	Query.SetParameter("Ref",Ref);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	HierarchyTree = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	CurCatalogElement_ = HierarchyTree.Rows.Find(Ref,"Ref",True);
	
	If CurCatalogElement_ <> Undefined Then
		
		WriteToRegisterByPartner(CurCatalogElement_);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithForms

// Determines whether full-text search is available in the list and selection forms of the partners directory.
//
// Parameters:
//  Form - ClientApplicationForm - The Form for which availability is determined contains:
//  * Items - FormAllItems - Contains:
//   ** Find - FormField -
//
Procedure AccessibilityFullTextSearchPartnerList(Form) Export
	
	// To set the visibility of elements
	Form.AdvancedSearch = False;
	
	TMCommonUse.InitializeFormDetailsForFullTextSearch(Form, "UseFullTextSearch"); 
	
	If Form.UseFullTextSearch Then
		
		SelectionListsClientServer.Load("PartnerSearchHistory", Form.Items.SearchString.ChoiceList);
		
	Else
		
		Form.Items.SearchString.Visible = False;
		Form.Items.Find.Visible        = False;

	EndIf;
	
EndProcedure

// Changes the query for the dynamic list of partners and sets the selection by relationship type.
//
// Parameters:
//  Form - ClientApplicationForm - THE Form for which selections are set contains:
//   * Parameters - Structure - the parameters passed to the form during creation contain:
//     ** Filter - Structure - 
//     ** B - Structure - 
//
Procedure SetSelectionsDynamicListOfPartners(Form) Export
	
	GenerateListOfInstalledSelectionsDynamicListPartners(Form);
	
	If Form.ListFilterByPartnerType.Count() > 0 Then
		
		SetSelectionByPartnerTypeAsOR = False;
		
		If Form.Parameters.Property("SetSelectionByPartnerTypeAsOR") And Form.Parameters.SetSelectionByPartnerTypeAsOR Then
			SetSelectionByPartnerTypeAsOR = True;
		EndIf;
		
		For Each ListItem In Form.ListFilterByPartnerType Do
			Form.Parameters.Filter.Delete(ListItem.Value);
		EndDo;
		
		Form.List.QueryText =  Form.List.QueryText + AddingDynamicListRequestForPartners(Form.ListFilterByPartnerType, SetSelectionByPartnerTypeAsOR); 
		
		ArrayOfSelectionConditions = New Array;
		For Each ListItem In Form.ListFilterByPartnerType Do
			If ListItem.Value = "OurEnterprise" Then
				ArrayOfSelectionConditions.Add(Common.ObjectAttributeValue(Catalogs.Partners.OurEnterprise, "Description"));
			Else
				ArrayOfSelectionConditions.Add(PresentationOfSelectionByPartnerType(ListItem.Value));
			EndIf;
		EndDo;
		Separator = " "  + ?(SetSelectionByPartnerTypeAsOR, NStr("vi = 'hoặc';
																|ru = 'или';
																|en = 'or'; fa = 'یا';
																|it = 'oppure';
																|pl = 'lub';
																|tr = 'veya'"), NStr("vi = 'và';
																					|ru = 'и';
																					|en = 'and'; fa = 'و';
																					|it = 'e';
																					|pl = 'oraz';
																					|tr = 've'")) + " ";
		FilterConditions = StrConcat(ArrayOfSelectionConditions, Separator);
		
		Form.AutoTitle = False;
		TitleTemplate1 = ?(Form.UsePartnersAsCounterparties, NStr("vi = 'Đối tác ( %1)';
																	|ru = 'Контрагенты (%1)';
																	|en = 'Counterparties (%1)'; fa = 'Counterparties (%1)';
																	|it = 'Contraenti (%1)';
																	|pl = 'Kontrahenci (%1)';
																	|tr = 'Cari hesaplar (%1)'"), NStr("vi = 'Bạn hàng ( %1)';
																										|ru = 'Партнеры (%1)';
																										|en = 'Partners (%1)'; fa = 'Partners (%1)';
																										|it = 'I partner (%1)';
																										|pl = 'Partnery (%1)';
																										|tr = 'İş ortakları (%1)'"));
		Form.Title = StrTemplate(TitleTemplate1, FilterConditions);
		
	ElsIf Form.UsePartnersAsCounterparties Then
		
		Form.AutoTitle = False;
		Form.Title =  NStr("vi = 'Đối tác';
							|ru = 'Контрагенты';
							|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
							|it = 'Controparti';
							|pl = 'Counterparties';
							|tr = 'Cari hesaplar'");
		
	EndIf;
	
	If Form.UsePartnersAsCounterparties Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.List,
			?(Form.FormName = "Catalog.Counterparties.Form.ChoiceFormOnlyPartnersAreUsed"
			   Or Form.FormName = "Catalog.Counterparties.Form.ChoiceFormOnlyPartnersAreUsedWithoutFullTextSearch", 
			   "Partner", "Ref"),
			Catalogs.Partners.UnknownPartner,
			DataCompositionComparisonType.NotEqual);
		
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "Managers") Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.Managers,
			"Invalid", 
			False, 
			DataCompositionComparisonType.Equal, 
			NStr("vi = 'Chỉ người sử dụng có hiệu lực';
				|ru = 'Только действительные пользователи';
				|en = 'Active users only'; fa = 'Active users only';
				|it = 'Только действительные пользователи';
				|pl = 'Active users only';
				|tr = 'Sadece gerçek kullanıcılar'"), 
			True, 
			DataCompositionSettingsItemViewMode.Normal);
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.Managers,
			"IsInternal", 
			False, 
			DataCompositionComparisonType.Equal, 
			NStr("vi = 'Không có người dùng dịch vụ';
				|ru = 'Без служебных пользователей';
				|en = 'No utility users'; fa = 'No utility users';
				|it = 'Без служебных пользователей';
				|pl = 'No utility users';
				|tr = 'Özel kullanıcılar olmadan'"), 
			True, 
			DataCompositionSettingsItemViewMode.Normal);
		
	EndIf;
	
EndProcedure

Function PresentationOfSelectionByPartnerType(FilterValue)
	
	If FilterValue = "Client" Then
		Return NStr("vi = 'Khách hàng';
					|ru = 'Клиенты';
					|en = 'Customers'; fa = 'مشتریان';
					|it = 'Clienti';
					|pl = 'Customers';
					|tr = 'Müşteriler'");
	ElsIf FilterValue = "Vendor" Then
		Return NStr("vi = 'Nhà cung cấp';
					|ru = 'Поставщики';
					|en = 'Vendors'; fa = 'تأمین‌کنندگان';
					|it = 'Fornitori';
					|pl = 'Vendors';
					|tr = 'Tedarikçiler'");
	ElsIf FilterValue = "Competitor" Then
		Return NStr("vi = 'Đối thủ cạnh tranh';
					|ru = 'Конкуренты';
					|en = 'Competitors'; fa = 'رقبا';
					|it = 'Concorrenti';
					|pl = 'Competitors';
					|tr = 'Rakipler'");
	ElsIf FilterValue = "OtherRelations" Then
		Return NStr("vi = 'Quan hệ khác';
					|ru = 'Прочие отношения';
					|en = 'Other relations'; fa = 'سایر روابط';
					|it = 'Altre relazioni';
					|pl = 'Inne stosunki';
					|tr = 'Diğer ilişkiler'");
	ElsIf FilterValue = "ServedBySalesRepresentatives" Then
		Return NStr("vi = 'Được phục vụ bởi đại diện thương mại';
					|ru = 'Обслуживается торговыми представителями';
					|en = 'Served by sales representatives'; fa = 'سرویس‌دهی توسط نمایندگان فروش';
					|it = 'Viene seguito dai rappresentanti commerciali';
					|pl = 'Obsługują przedstawiciele handlowe';
					|tr = 'Satış temsilcileri tarafından sunulmaktadır'");
	ElsIf FilterValue = "Carrier" Then
		Return NStr("vi = 'Người vận chuyển';
					|ru = 'Перевозчики';
					|en = 'Carriers'; fa = 'حمل‌کنندگان';
					|it = 'Vettori';
					|pl = 'Carriers';
					|tr = 'Taşıyıcılar'");
	Else
		Return "";
	EndIf;
	
EndFunction

// Performs a full-text search for partners in the form
//
// Parameters:
//  Form   - ClientApplicationForm - the form in which the search is performed.
//
// Returns:
//   String   - The text of the error message, Undefined, if the search is successful.
//
Function FindPartnersFullTextSearch(Form) Export
	
	TableOfBases_ = Form.FormAttributeToValue("Basis1");
	
	// get search results
	ErrorText =
	FindPartners(Form.SearchString, TableOfBases_);
	If ErrorText = Undefined Then
		
		SelectionListsClientServer.UpdateSelectionList(Form.Items.SearchString.ChoiceList, Form.SearchString, 100);
		
		SelectionListsClientServer.Save("PartnerSearchHistory", Form.Items.SearchString.ChoiceList);
		
		// return the base table
		Form.ValueToFormAttribute(TableOfBases_, "Basis1");
		
		If Not Form.AdvancedSearch Then
			Form.DisplayModeBeforeApplyingFullTextSearch = String(Form.Items.List.Representation);
		EndIf;
		Form.Items.List.Representation = TableRepresentation.List;
		
		// set the selection according to the list of found partners
		#If Not ExternalConnection Then
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "FullTextSearchSelectionIsSet",
		                                                                   True);
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "FullTextSearchSelection",
		                                                                   TableOfBases_.UnloadColumn("Partner"));
		#EndIf
		Form.Items.SearchString.BackColor = StyleColors.FieldBackColor;
		Return Undefined;
		
	EndIf;
	
	#If Not ExternalConnection Then
	CommonClientServer.SetDynamicListParameter(Form.List,
		                                                               "FullTextSearchSelectionIsSet",
		                                                               True);
	CommonClientServer.SetDynamicListParameter(Form.List,
		                                                               "FullTextSearchSelection",
		                                                               Undefined);
	#EndIf
	
	Form.Items.SearchString.BackColor = StyleColors.FieldWithAnErrorBackground;
	Return ErrorText;
	
EndFunction

// Sets the title of the "Partner" form element depending on the business transaction.
//
// Parameters:
//  Form  - ClientApplicationForm - The form that contains the element for which the title is set.
//  NameOfPartnerFormElement             - String - Name of the form element to set the title for.
//  BusinessOperation               - EnumRef.BusinessTransactions - the business transaction that the 
//                 header is set depending on.
//
Procedure TitleOfPartnerElementDependingOnBusinessOperation(Form, NameOfPartnerFormElement, BusinessOperation) Export
	
	TitlePartner = HeaderOfPartnerDetailsDependingOnBusinessOperation(BusinessOperation);
	
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, NameOfPartnerFormElement, "Title", TitlePartner);
	
EndProcedure

// Sets the header of the partner form details depending on the business transaction.
//
// Parameters:
//  BusinessOperation  - EnumRef.BusinessTransactions - an operation that affects the title text.
//  ReverseOperation  - Boolean - indicates that the business transaction is being used as a reverse one.
//
// Returns:
//   String   - the generated header.
//
Function HeaderOfPartnerDetailsDependingOnBusinessOperation(BusinessOperation, ReverseOperation = False) Export
	
	ProcurementOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	OperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		TitlePartner = NStr("vi = 'Người nhận bán ký gửi';
							|ru = 'Комиссионер';
							|en = 'Consignee'; fa = 'امانت‌دار';
							|it = 'Commissionario';
							|pl = 'Komisant';
							|tr = 'Konsinye'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		TitlePartner = NStr("vi = 'Người nhận bán ký gửi';
							|ru = 'Комиссионер';
							|en = 'Consignee'; fa = 'امانت‌دار';
							|it = 'Commissionario';
							|pl = 'Komisant';
							|tr = 'Konsinye'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor Then
		TitlePartner = NStr("vi = 'Người nhận bán ký gửi';
							|ru = 'Комиссионер';
							|en = 'Consignee'; fa = 'امانت‌دار';
							|it = 'Commissionario';
							|pl = 'Komisant';
							|tr = 'Konsinye'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense Then
		TitlePartner = NStr("vi = 'Người nhận bán ký gửi';
							|ru = 'Комиссионер';
							|en = 'Consignee'; fa = 'امانت‌دار';
							|it = 'Commissionario';
							|pl = 'Komisant';
							|tr = 'Konsinye'");
	ElsIf ProcurementOperations.Find(BusinessOperation) <> Undefined
		Or ImportOperations.Find(BusinessOperation) <> Undefined
		Or OperationsInEAEUCountries.Find(BusinessOperation) <> Undefined Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Fornitore';
							|pl = 'Dostawca';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		TitlePartner = NStr("vi = 'Người đặt ký gửi';
							|ru = 'Комитент';
							|en = 'Consignor'; fa = 'امانت‌گذار';
							|it = 'Committente';
							|pl = 'Komitent';
							|tr = 'Gönderici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Fornitore';
							|pl = 'Dostawca';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		TitlePartner = NStr("vi = 'Cơ quan thuế';
							|ru = 'Налоговый орган';
							|en = 'Tax authority'; fa = 'Tax authority';
							|it = 'Autorità fiscale';
							|pl = 'Organ podatkowy';
							|tr = 'Vergi idaresi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CustomsPayment Then
		TitlePartner = NStr("vi = 'Hải quan';
							|ru = 'Таможня';
							|en = 'Customs'; fa = 'Customs';
							|it = 'Dogana';
							|pl = 'Urząd celny';
							|tr = 'Gümrük'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		TitlePartner = NStr("vi = 'Ngân hàng';
							|ru = 'Банк';
							|en = 'Bank'; fa = 'بانک';
							|it = 'Banca';
							|pl = 'Bank';
							|tr = 'Banka'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived Then
		TitlePartner = NStr("vi = 'Người cho vay';
							|ru = 'Кредитор';
							|en = 'Creditor'; fa = 'بستانکار';
							|it = 'Creditore';
							|pl = 'Wierzyciel';
							|tr = 'Alacaklı'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToDeposits Then
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty Then
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.LoansInterestCharge Then
		TitlePartner = NStr("vi = 'Người cho vay';
							|ru = 'Кредитор';
							|en = 'Creditor'; fa = 'بستانکار';
							|it = 'Creditore';
							|pl = 'Wierzyciel';
							|tr = 'Alacaklı'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.DepositInterestCharge Then
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.IssuedBorrowingsInterestCharge Then
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Fornitore';
							|pl = 'Dostawca';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment Then
		TitlePartner = NStr("vi = 'Người cho vay';
							|ru = 'Кредитор';
							|en = 'Creditor'; fa = 'بستانکار';
							|it = 'Creditore';
							|pl = 'Wierzyciel';
							|tr = 'Alacaklı'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits Then
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		TitlePartner = NStr("vi = 'Bên gửi hàng';
							|ru = 'Поклажедатель';
							|en = 'Depositor'; fa = 'امانت‌گذار';
							|it = 'Depositante';
							|pl = 'Depozytariusz';
							|tr = 'Kefil'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		TitlePartner = ?(Not ReverseOperation, NStr("vi = 'Bên bảo quản';
													|ru = 'Хранитель';
													|en = 'Custodian'; fa = 'امین';
													|it = 'Depositario';
													|pl = 'Przechowywujący';
													|tr = 'Emanetçi'"), NStr("vi = 'Khách hàng';
																				|ru = 'Покупатель';
																				|en = 'Customer'; fa = 'مشتری';
																				|it = 'Acquirente';
																				|pl = 'Nabywca';
																				|tr = 'Müşteri'"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtCustodian Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.DamageAtCustodian Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		TitlePartner = NStr("vi = 'Bên thuê gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5
		Or BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5 Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5 Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.DamageAtToller Then
		TitlePartner = NStr("vi = 'Bên gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		TitlePartner = ?(Not ReverseOperation, NStr("vi = 'Khách hàng';
													|ru = 'Покупатель';
													|en = 'Customer'; fa = 'مشتری';
													|it = 'Acquirente';
													|pl = 'Nabywca';
													|tr = 'Müşteri'"), NStr("vi = 'Chi nhánh';
																			|ru = 'Принципал';
																			|en = 'Principal'; fa = 'اصل مبلغ';
																			|it = 'Mandante';
																			|pl = 'Principal';
																			|tr = 'Müvekkil'"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.DeletePaymentToSelfEmployedPerson Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Fornitore';
							|pl = 'Dostawca';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Покупатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Acquirente';
							|pl = 'Nabywca';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Fornitore';
							|pl = 'Dostawca';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Fornitore';
							|pl = 'Dostawca';
							|tr = 'Tedarikçi'");
	Else
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			TitlePartner = NStr("vi = 'Đối tác';
								|ru = 'Контрагент';
								|en = 'Counterparty'; fa = 'طرف حساب';
								|it = 'Controparte';
								|pl = 'Kontrahent';
								|tr = 'Cari hesap'");
		Else
			TitlePartner = NStr("vi = 'Bạn hàng';
								|ru = 'Партнер';
								|en = 'Partner'; fa = 'شریک تجاری';
								|it = 'Partner';
								|pl = 'Partner';
								|tr = 'İş ortağı'");
		EndIf;
	EndIf;
	
	Return TitlePartner;
	
EndFunction

// Sets the title of the "Partner" form element depending on the nature of the loan or Deposit agreement.
//
// Parameters:
//  Form  - ClientApplicationForm - The form that contains the element for which the title is set.
//  NameOfPartnerFormElement  - String - Name of the form element to set the title for.
//  ContractKind  - EnumRef.ContractKindsOfFinancialInstruments - the nature of the contract, depending on which 
//                 the title is set.
//
Procedure TitleOfPartnerElementDependsOnNatureOfLoanAndDepositAgreement(Form, NameOfPartnerFormElement, ContractKind) Export

	If ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
		
		TitlePartner = NStr("vi = 'Người cho vay';
							|ru = 'Кредитор';
							|en = 'Creditor'; fa = 'بستانکار';
							|it = 'Creditore';
							|pl = 'Wierzyciel';
							|tr = 'Alacaklı'");
		
	Else
		
		TitlePartner = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
		
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, NameOfPartnerFormElement, "Title", TitlePartner);


EndProcedure

// Sets the header of the "counterparty's Account" form element depending on the business transaction.
//
// Parameters:
//  Form - ClientApplicationForm - The form that contains the element for which the title is set
//  FormItemName - String - Name of the form element to set the header for
//  BusinessOperation - EnumRef.BusinessTransactions - the business transaction that the 
//                 header is set depending on.
//
Procedure HeaderOfCounterpartySAccountElementDependingOnBusinessOperation(Form, FormItemName, BusinessOperation) Export
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		Title = NStr("vi = 'Tài khoản người nhận';
					|ru = 'Счет покупателя';
					|en = 'Customer account'; fa = 'حساب مشتری';
					|it = 'Conto dell''acquirente';
					|pl = 'Rachunek nabywcy';
					|tr = 'Müşteri hesabı'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		Title = NStr("vi = 'Tài khoản nhà cung cấp';
					|ru = 'Счет продавца';
					|en = 'Seller account'; fa = 'Seller account';
					|it = 'Conto del venditore';
					|pl = 'Rachunek sprzedawcy';
					|tr = 'Satıcı hesabı'");
	Else
		Title = NStr("vi = 'Tài khoản của đối tác';
					|ru = 'Счет контрагента';
					|en = 'Counterparty account'; fa = 'حساب طرف حساب';
					|it = 'Conto della controparte';
					|pl = 'Rachunek kontrahenta';
					|tr = 'Cari hesaba ait hesap'");
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, FormItemName, "Title", Title);

EndProcedure 

// Sets the header of the Bank details depending on the value of the "Use partners as contractors"FO.
//
// Parameters:
//  Form  - ClientApplicationForm - The form that contains the element for which the title is set.
//  TagName  - String - Name of the form element to set the title for.
//  NewTitle  - String - the header that will be set if the value of the FO "Use partners as
//                             contractors" is TRUE.
//  UsePartnersAsCounterparties  - Boolean - the value of the FO "Use partners as contractors".
//  NewExtendedHint  - String - hint.
//
Procedure HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(Form, TagName, NewTitle, UsePartnersAsCounterparties = Undefined, NewExtendedHint = "") Export
	
	If UsePartnersAsCounterparties = Undefined Then
		UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	EndIf;
	
	If UsePartnersAsCounterparties Then
		If IsBlankString(TagName) Then
			Form.AutoTitle = False;
			Form.Title = NewTitle;
		Else
			TMCommonUseClientServer.SetFormItemProperty(Form.Items, TagName, "Title", NewTitle);
			If Not IsBlankString(NewExtendedHint) Then
				TMCommonUseClientServer.SetFormItemProperty(Form.Items, TagName, "ExtendedTooltip", NewExtendedHint);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Sets the header of the SKD field depending on the value of the FO "Use partners as contractors".
//
// Parameters:
//  DataSet  - DataCompositionTemplateDataSetQuery - The set that contains the element for which
//                                                           the title is set.
//  TagName  - String - The name of the item for which you are installing the header.
//  NewTitle  - String - the header that will be set if the value of the FO "Use partners as
//                             contractors" is TRUE.
//
Procedure HeaderOfSKDFieldDependingOnFOUsePartnersAsCounterparties(DataSet, TagName, NewTitle) Export

	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Field = DataSet.Fields.Find(TagName); // DataCompositionSchemaDataSetField 
		If Field <> Undefined Then
			Field.Title = NewTitle;
		EndIf;
	EndIf;

EndProcedure

// Gets the Legal Entity attribute based on the data of the new assistant form.
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
//  EnumRef.LegalEntityIndividual, Undefined - 
//
Function LegalEntityPhysicalPersonAccordingToNewAssistantForm(Form) Export
	
	If Form.ThisIsACompany = 1 Then
		Return Enums.LegalEntityIndividual.Person;
	Else
		If Form.TypeOfCompany = 0 
			Or Form.TypeOfCompany = 3 Then
			 Return Enums.LegalEntityIndividual.Entity;
			
		 ElsIf Form.TypeOfCompany = 1 Then
			 
			Return Enums.LegalEntityIndividual.LegalEntityNonResident;
			
		ElsIf Form.TypeOfCompany = 2 Then
			
			Return Enums.LegalEntityIndividual.IndividualEntrepreneur;
			
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region GeneralProceduresForCreatingPartnerCatalogElement

// Handler of the event for adding a form To the server of the partners directory element.
//
// Parameters:
//  Form                - ClientApplicationForm - The Form for which the handler is executed contains:
//    * Object - CatalogObject.Partners -
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure PartnerElementFormWhenCreatedOnServer(Form, Cancel, StandardProcessing) Export
	
	Form.UseShipmentProhibition = GetFunctionalOption("UseShipmentProhibition");
	SimplifiedInputAvailable           = SimplifiedInputAvailable();
	AvailableToAddPartners      = AccessRight("Insert", Metadata.Catalogs.Partners);
	
	// identify the channel and source of primary interest
	If GetFunctionalOption("RecordInitialRequest") Then
		Interest = PrimaryInterest(Form.Object.Ref,True);
		Form.ChannelOfInitialRequest = Interest.ChannelOfInitialRequest;
		Form.SourceOfInitialRequest = Interest.SourceOfInitialRequest;
		Form.Items.SourceOfInitialRequest.ReadOnly = Not ValueIsFilled(Form.ChannelOfInitialRequest);
	Else
		Form.Items.PrimaryInterestGroup.Visible = False;
	EndIf;
	
	If Form.Parameters.Property("ListFilterByPartnerType") Then
		
		For Each ListItem In Form.Parameters.ListFilterByPartnerType Do
			Form.Object[ListItem.Value] = True;
		EndDo;
		
	EndIf;
	
	If Form.Object.Carrier Then
		Form.Object.Vendor = True;
	EndIf;
	
	If Form.Object.ServedBySalesRepresentatives Then
		Form.Object.Client = True;
	EndIf;
	
	If Form.Object.Ref.IsEmpty() Then
		PartnerFormElementWhenCreatedReadOnServer(Form);
	EndIf;
	
	If StrFind(Form.FormName, "CounterpartyAttributesItemForm") > 0 Then
		
		PartnersAndCounterpartiesLocalization.WhenCreatingCounterpartyDetailsElementFormOnServer(Form, Cancel, StandardProcessing);
		
	Else
		
		PartnersAndCounterpartiesLocalization.WhenCreatingPartnerElementFormOnServer(Form, Cancel, StandardProcessing);
		
	EndIf;
	
	If AvailableToAddPartners And Not SimplifiedInputAvailable Then
		TMCommonUseClientServer.SetFormItemProperty(Form.Items,
		                                                               "FormCopy",
		                                                               "Visible",
		                                                               False);
	EndIf;
	
EndProcedure

Procedure FillInPartnerCounterpartyDetails(Receiver, Partner, WithHistoricalData = True) Export

	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	Counterparties.Ref AS PartnerSCounterparty,
	|	Counterparties.DescriptionInternational AS DescriptionInternational,
	|	Counterparties.NameInLetters AS NameInLetters,
	|	Counterparties.LegalEntityIndividual                 AS LegalEntityIndividual,
	|	Counterparties.CompanyIndividual AS CompanyIndividual,
	|	Counterparties.BranchOffice AS BranchOffice,
	|	Counterparties.MainCounterparty        AS MainCounterparty,
	|	Counterparties.RegistrationCountry         AS RegistrationCountry,
	|	Counterparties.RegistrationNumber      AS RegistrationNumber,
	|	Counterparties.TIN                       AS TIN,
	|	Counterparties.TaxNumber            AS TaxNumber
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartiesNameHistory.Period                  AS Period,
	|	CounterpartiesNameHistory.NameAbbreviated AS NameAbbreviated
	|FROM
	|	Catalog.Counterparties.NameHistory AS CounterpartiesNameHistory
	|WHERE
	|	CounterpartiesNameHistory.Ref.Partner = &Partner";
	
	Query.SetParameter("Partner",Partner);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();

	If Selection.Next() Then
	
		FillPropertyValues(Receiver, Selection);
		If WithHistoricalData Then
			Receiver.NameHistory.Load(QueryResult[1].Unload());
		EndIf;
	
	EndIf;
	PartnersAndCounterpartiesLocalization.AddPartnerCounterpartyData(Receiver, Partner, WithHistoricalData);
EndProcedure

// Fills in the counterparty's contact information using the partner's contact information.
// 
// Parameters:
// 	CounterpartyObject             - CatalogObject.Counterparties - 
// 	Form                        - ClientApplicationForm - 
// 	PartnerContactInformation - ValueTable -
// 	
Procedure FillInContactInformationOfPartnerCounterparty(CounterpartyObject, Form, PartnerContactInformation) Export
	
	DeleteLineWithKIType(CounterpartyObject.ContactInformation, Catalogs.ContactInformationKinds.EmailCounterparty_);
	DeleteLineWithKIType(CounterpartyObject.ContactInformation, Catalogs.ContactInformationKinds.CounterpartySPhoneNumber);
	
	For Each PartnerKiString In PartnerContactInformation Do
		
		If PartnerKiString.Kind = Catalogs.ContactInformationKinds.EmailPartner_ Then
			KindCIOfCounterparty = Catalogs.ContactInformationKinds.EmailCounterparty_;
		ElsIf PartnerKiString.Kind = Catalogs.ContactInformationKinds.PartnerSPhoneNumber Then
			KindCIOfCounterparty = Catalogs.ContactInformationKinds.CounterpartySPhoneNumber;
		Else
			Continue;
		EndIf;
		
		CounterpartyKiString = CounterpartyObject.ContactInformation.Add();
		FillPropertyValues(CounterpartyKiString, PartnerKiString);
		CounterpartyKiString.Kind = KindCIOfCounterparty;
		
	EndDo;
	
EndProcedure

// Event handler for the account in The server of the "Partners" directory element forms"
//
// Parameters:
//  Form          - ClientApplicationForm - the form for which the handler is executed.
//  CurrentObject  - CatalogObject.Partners - the object to be read.
//
Procedure WhatIsShapeOfElementWhenReadOnServer(Form, CurrentObject) Export
	
	PartnerFormElementWhenCreatedReadOnServer(Form);
	
EndProcedure

// Controls the availability of the form elements of the "Partners" directory element.
//
// Parameters:
//  Form - ClientApplicationForm - The Form, the accessibility of the elements is configured, contains:
//    * Items - FormAllItems - Contains:
//      ** BirthDate                    - FormField - 
//      ** Gender                             - FormField - 
//      ** OptionOfSendingElectronicReceipt - FormField - .
//
Procedure PartnerFormOfAccessibilityControl(Form) Export
	
	If Form.Object.Predefined Then
		Form.Items.Client.ReadOnly = True;
		Form.Items.Vendor.ReadOnly = True;
		Form.Items.Competitor.ReadOnly = True;
		Form.Items.OtherRelations.ReadOnly = True;
		Form.Items.ServedBySalesRepresentatives.ReadOnly = True;
		Form.Items.Carrier.ReadOnly = True;
	EndIf;
	
	Form.Items.ServedBySalesRepresentatives.Enabled = Form.Object.Client;
	If Not Form.Object.Client Then
		Form.Object.ServedBySalesRepresentatives = False;
	EndIf;
	
	Form.Items.Carrier.Enabled = Form.Object.Vendor;
	If Not Form.Object.Vendor Then
		Form.Object.Carrier = False;
	EndIf;
	
	Form.Items.Gender.Enabled                             = (Form.Object.LegalEntityIndividual = Enums.IndividualCompany.Person_);
	Form.Items.BirthDate.Enabled                    = (Form.Object.LegalEntityIndividual = Enums.IndividualCompany.Person_);
	Form.Items.OptionOfSendingElectronicReceipt.Enabled = (Form.Object.LegalEntityIndividual = Enums.IndividualCompany.Person_);
	
	Form.Items.PageGroupListOfShippingBans.Visible = GetFunctionalOption("UseShipmentProhibition") And Form.Object.Client;
	
EndProcedure

// Event handler for the post-write event in the form Server of the partners directory element
//
// Parameters:
//  Form            - ClientApplicationForm - the form for which the handler is executed.
//  CurrentObject    - CatalogObject.Partners - The recorded object.
//  WriteParameters  - Structure - contains the recording settings.
//
Procedure PartnerFormOfItemAfterRecordingOnServer(Form, CurrentObject, WriteParameters) Export

	PartnerFormOfCustomizeNavigationBarItem(Form);
	CapturePrimaryInterest(Form);
	Form.Items.AdditionalInformationGroup.Picture = CommonClientServer.CommentPicture(Form.Object.AdditionalInformation);

EndProcedure

#EndRegion

#Region GeneralProceduresAndFunctionsOfListAndCatalogSelectionForms

Procedure PartnersFormForSelectingListWhenCreatingItOnServer(Form, Cancel, StandardProcessing) Export
	
	Form.SimplifiedInputAvailable               = SimplifiedInputAvailable();
	Form.CurrentUser                  = Users.AuthorizedUser();
	Form.AvailableToAddPartners          = AccessRight("Insert", Metadata.Catalogs.Partners);
	Form.UseBusinessRegions            = GetFunctionalOption("UseBusinessRegions");
	Form.UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	RequestWithCounterpartyInformation = False;
	
	If Not StrFind(Form.FormName, "Counterparties") > 0 Then
		
		RequestWithCounterpartyInformation = False;
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = RequestTextForDynamicListOfPartners(RequestWithCounterpartyInformation);
		ListProperties.MainTable = "Catalog.Partners";
		ListProperties.DynamicDataRead = True;
	
		Common.SetDynamicListProperties(Form.Items.List, ListProperties);
		
		Form.Items.PartnerSCounterpartiesGroup.Visible      = Not Form.UsePartnersAsCounterparties;

		TMCommonUseClientServer.SetFormItemProperty(Form.Items,
		                                                               "ListContextMenuMoveItem",
		                                                               "Visible",
		                                                               Not Form.UsePartnersAsCounterparties);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items,
		                                                               "FormMoveItem",
		                                                               "Visible",
		                                                               Not Form.UsePartnersAsCounterparties);
	EndIf;
	
	If Form.AvailableToAddPartners And Not Form.SimplifiedInputAvailable Then
		TMCommonUseClientServer.SetFormItemProperty(Form.Items,
		                                                               "FormCopy",
		                                                               "Visible",
		                                                               False);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(Form.List,
	                                                                   "FullTextSearchSelectionIsSet",
	                                                                   False);
	CommonClientServer.SetDynamicListParameter(Form.List,
	                                                                   "FullTextSearchSelection",
	                                                                   Undefined);
	CommonClientServer.SetDynamicListParameter(Form.List,
	                                                                   "SelectionBySegmentIsSet",
	                                                                   False);
	CommonClientServer.SetDynamicListParameter(Form.List,
	                                                                   "FilterBySegment",
	                                                                   Undefined);
	CommonClientServer.SetDynamicListParameter(Form.List,
	                                                                   "RepresentationOfASeparateDivision",
	                                                                   NStr("vi = 'Chi nhánh, văn phòng đại diện';
																			|ru = 'Обособленное подразделение';
																			|en = 'Branch office'; fa = 'شعبه';
																			|it = 'Reparto esterno';
																			|pl = 'Odrębny dział';
																			|tr = 'Ayrı departman'"));
	AccessibilityFullTextSearchPartnerList(Form);
	
	TMCommonUseClientServer.SetFormItemProperty(Form.Items, "CreateNewOne", "Visible", Form.SimplifiedInputAvailable);
	
	FillInSelectionListFilterTypePartnerList(Form, Form.Items.FilterType_.ChoiceList);
	Form.FilterType_ = Form.Items.FilterType_.ChoiceList[0].Value;
	SetVisibilityOfReportCommands(Form);
	SetSelectionsDynamicListOfPartners(Form);
	CreatePropsForDisplayingCI(Form);
	PartnersAndCounterpartiesLocalization.WhenCreatingPartnersListSelectionFormOnServer(Form, Cancel, StandardProcessing, RequestWithCounterpartyInformation);
	DetermineModeOfUsingSearchInList(Form);
	
EndProcedure

// Sets the conditional design in the list of partners form.
//
// Parameters:
//  Form - ClientApplicationForm - THE Form for which conditional registration is set contains:
//   * Items - FormAllItems - Contains:
//    ** SearchString  - FormField - 
//    ** BusinessRegions           - FormTable -
//    ** PartnerAccessGroups  - FormTable -
//    ** Properties                - FormTable - 
//    ** Managers               - FormTable - 
//    ** Categories               - FormTable - 
//
Procedure PartnersListSelectionFormConditionalAppearance(Form) Export

	Items = Form.Items;
	ConditionalAppearance = Form.ConditionalAppearance;

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchString.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdvancedSearch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SearchString");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldBackColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BusinessRegions.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerAccessGroups.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Managers.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Properties.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Categories.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseAFilter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

// Creates in the form of a list or selection of the "Partners" directory details for displaying the partner's CI in the information panel.
//
// Parameters:
//  Form  - ClientApplicationForm - the form that the Bank details are created for.
//
Procedure CreatePropsForDisplayingCI(Form) Export
	
	AttributesToBeAdded = New Array;
	RowTypeDetails500 = New TypeDescription("String",, New StringQualifiers(500));
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ContactInformationKinds.Ref AS Ref,
	|	ISNULL(TypesOfPresentationContactInformation.Description, ContactInformationKinds.Description) AS Description,
	|	CASE
	|		WHEN ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Address)
	|			THEN 1
	|		ELSE 0
	|	END AS OrderingValue
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|		LEFT JOIN Catalog.ContactInformationKinds.Presentations AS TypesOfPresentationContactInformation
	|		ON (TypesOfPresentationContactInformation.Ref = ContactInformationKinds.Ref
	|				AND TypesOfPresentationContactInformation.LanguageCode = &LanguageCode)
	|WHERE
	|	ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogPartners)
	|	AND NOT ContactInformationKinds.DeletionMark
	|
	|ORDER BY
	|	OrderingValue,
	|	Description";
	
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	TableOfTypesOfCI = Query.Execute().Unload();
	
	MaximumLengthOfKiSpecies = 0;
	For Each CIRow In TableOfTypesOfCI Do
		If StrLen(CIRow["Description"]) > MaximumLengthOfKiSpecies Then
			MaximumLengthOfKiSpecies = StrLen(CIRow["Description"] + 3);
		EndIf;
	EndDo;
	
	DescriptionOfTypeOfKiTypeString = New TypeDescription("String",,New StringQualifiers(MaximumLengthOfKiSpecies + 3));
	Form.Items.GroupTypesOfCI.Width = MaximumLengthOfKiSpecies + 3;
	Form.NumberOfCIKinds = TableOfTypesOfCI.Count();
	
	For Indus = 1 To Form.NumberOfCIKinds Do
		
		AttributesToBeAdded.Add(New FormAttribute("TitleKiView_" + String(Indus), DescriptionOfTypeOfKiTypeString,));
		AttributesToBeAdded.Add(New FormAttribute("CIKind_" + String(Indus), RowTypeDetails500,));
		
	EndDo;
	
	Form.ChangeAttributes(AttributesToBeAdded);
	
	For Indus = 1 To Form.NumberOfCIKinds Do
		
		Item = Form.Items.Add("TitleKiView_" + String(Indus), Type("FormField"), Form.Items.GroupTypesOfCI);
		Item.Type                      = FormFieldType.LabelField;
		Item.TitleLocation       = FormItemTitleLocation.None;
		Item.VerticalAlign    = ItemVerticalAlign.Top;
		Item.DataPath              = "TitleKiView_" + String(Indus);
		Item.AutoCellHeight         = True;
		Item.VerticalStretch   = False;
		Item.HorizontalStretch = True;
		Form["TitleKiView_" + String(Indus)] = TableOfTypesOfCI[Indus - 1]["Description"] + " :";
		
		Item = Form.Items.Add("CIKind_" + String(Indus), Type("FormField"), Form.Items.GroupValueOfTheCI); 
		Item.Type                      = FormFieldType.LabelField;
		Item.TitleLocation       = FormItemTitleLocation.None;
		Item.VerticalAlign    = ItemVerticalAlign.Top;
		Item.DataPath              = "CIKind_" + String(Indus);
		Item.TextColor               = StyleColors.SpecialPrice;
		Item.AutoCellHeight         = True;
		Item.VerticalStretch   = False;
		Item.HorizontalStretch = True;
		
	EndDo;
	
	For Indus = 1 To Form.NumberOfCIKinds Do
		
		ConditionalAppearanceItem = Form.ConditionalAppearance.Items.Add();
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("CIKind_" + String(Indus));
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = NStr("vi = '<Chưa chỉ ra>';
										|ru = '<Не указан>';
										|en = '<not specified>'; fa = '<مشخص نشده>';
										|it = '<non specificato>';
										|pl = '<Nie określono>';
										|tr = '<Belirtilmedi>'");
		DataFilterItem.Use  = True;
		
		AppearanceColorItem               = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
		AppearanceColorItem.Value      = Metadata.StyleItems.TextColorOfCanceledRowOfDocument.Value;
		AppearanceColorItem.Use = True;
		
		NewItem = ConditionalAppearanceItem.Fields.Items.Add();
		NewItem.Field = New DataCompositionField("CIKind_" + String(Indus));
		
	EndDo;
	
EndProcedure

// Fills in the details for displaying the partner's CI in the information panel in the "Partners" list or directory selection form.
//
// Parameters:
//  PartnerData - Structure                  - the data used to fill out the form.
//  Form          - ClientApplicationForm - the form for which the bank details are filled in.
//
Procedure FillInPartnerSCIDetails(PartnerData, Form) Export
	
	If PartnerData = Undefined Then
		
		For Indus = 1 To Form.NumberOfCIKinds Do
			
			Form["CIKind_" + String(Indus)] = NStr("vi = '<Chưa chỉ ra>';
													|ru = '<Не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<Nie określono>';
													|tr = '<Belirtilmedi>'");
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If PartnerData.ContactInformationTable_.Count() > Form.NumberOfCIKinds Then
		Return;
	EndIf;
	
	For Indus = 1 To Form.NumberOfCIKinds Do
		
		If IsBlankString(PartnerData.ContactInformationTable_[Indus - 1].KiPresentation) Then
			Form["CIKind_" + String(Indus)] = NStr("vi = '<Chưa chỉ ra>';
													|ru = '<Не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<Nie określono>';
													|tr = '<Belirtilmedi>'");
		Else
			Form["CIKind_" + String(Indus)] = PartnerData.ContactInformationTable_[Indus - 1].KiPresentation;
		EndIf;
		
	EndDo;
	
EndProcedure

// Changes the selection in the list form or the Partners directory selection when changing the type of the navigation bar or
// repositioning in the navigation bar.
//
// Parameters:
//  Form                              - ClientApplicationForm - The Form for which the action is performed contains:
//   * FilterType_ - Structure - Contains:
//     ** Description - String - 
//   * Items  - FormAllItems - Contains:
//     ** OnlyImportant - FormField - 
//  ReshapingNavigationBar    - Boolean           - indicates that the navigation bar needs to be updated.
//  PropertyPageNeedsFilling - Boolean           - indicates that you need to re-fill the properties page.
//
Procedure ChangeFilterList(Form, ReshapingNavigationBar, PropertyPageNeedsFilling) Export
	
	If PropertyPageNeedsFilling Then
		
		If Form.FilterType_ = "Categories" Then
			FillCategoryTree(Form);
			Form.Items.PagesFilterType.CurrentPage = Form.Items.CategoriesPage;
			
			FoundRows = Form.NavigationPanelSettings.FindRows(New Structure("PanelKind","Categories"));
			If FoundRows.Count() > 0 Then
				FoundPanelRows = Form.Categories.FindRows(New Structure("Value", FoundRows[0].CurrentValue));
				If FoundPanelRows.Count() > 0 Then
					Form.Items.Categories.CurrentRow = FoundPanelRows[0].GetID();
				EndIf;
			EndIf;
			
			Form.DoNotTestNavigationPanelActivation = True;
			
		Else
			
			FillPropertiesTree(Form);
			Form.Items.PagesFilterType.CurrentPage = Form.Items.PropertiesPage;
			
			FoundRows = Form.NavigationPanelSettings.FindRows(New Structure("PanelKind", Form.FilterType_));
			If FoundRows.Count() > 0 Then
				Form.Items.Properties.CurrentRow = FindStringInFormDataTree(Form.Properties, FoundRows[0].CurrentValue, "Value", True)
			EndIf;
			
			Form.DoNotTestNavigationPanelActivation = True;
			
		EndIf;
		
	EndIf;
	
	ToSetFilter = True;
	If Not Form.UseAFilter Then
		Form.CurrentFilterValue = Undefined;
		ToSetFilter = False;
	EndIf;
	
	If ToSetFilter Or Form.OnlyMine Then
		FilterGroup = CreateFilterSelectionGroup(Form);
	Else
		FilterGroup = CommonClientServer.FindFilterItemByPresentation(
			TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items, "FilterSelection");
		If FilterGroup <> Undefined Then
			TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items.Delete(FilterGroup);
		EndIf;
	EndIf;
	
	If Form.Items.PagesFilterType.CurrentPage = Form.Items.PropertiesPage 
		Or Form.Items.PagesFilterType.CurrentPage = Form.Items.CategoriesPage Then
		
		Form.OnlyImportant = True;
		Form.Items.OnlyImportant.Enabled = False;
		NameOfSelectionProps = ?(Form.FormName = "Catalog.Counterparties.Form.ChoiceFormOnlyPartnersAreUsed" 
		                      Or Form.FormName = "Catalog.Counterparties.Form.ChoiceFormOnlyPartnersAreUsedWithoutFullTextSearch",
		                      "Partner", "Ref");
		
	Else
		
		Form.Items.OnlyImportant.Enabled = True;
		
		If ReshapingNavigationBar Then
			
			If Form.Items.PagesFilterType.CurrentPage = Form.Items.PageBusinessRegions Then
				FoundRows = Form.NavigationPanelSettings.FindRows(New Structure("PanelKind", "BusinessRegions"));
				If FoundRows.Count() > 0 Then
					Form.Items.BusinessRegions.CurrentRow = FoundRows[0].CurrentValue;
				EndIf;
				ListName = "BusinessRegions";
			ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageAccessGroups Then
				FoundRows = Form.NavigationPanelSettings.FindRows(New Structure("PanelKind", "AccessGroups"));
				If FoundRows.Count() > 0 Then
					Form.Items.PartnerAccessGroups.CurrentRow = FoundRows[0].CurrentValue;
				EndIf;
				ListName = "PartnerAccessGroups";
			ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers Then
				FoundRows = Form.NavigationPanelSettings.FindRows(New Structure("PanelKind", "Manager"));
				If FoundRows.Count() > 0 Then
					Form.Items.Managers.CurrentRow = FoundRows[0].CurrentValue;
				EndIf;
				ListName = "Managers";
			EndIf;
			
			SelectingListToChange = TMCommonUseClientServer.GetDynamicListSelection(Form[ListName]);
			ListOfSignificant = ListOfSignificantNavigationBarValues(ListName);
			
			If ReshapingNavigationBar And Not Form.OnlyImportant Then
				SelectionGroupSignificant = CommonClientServer.FindFilterItemByPresentation(SelectingListToChange.Items, "SelectionBySignificant");
				If SelectionGroupSignificant <> Undefined Then
					SelectingListToChange.Items.Delete(SelectionGroupSignificant);
				EndIf;
			Else
				SelectionGroupSignificant = CreateSignificantSelectionGroup(SelectingListToChange);
				CommonClientServer.AddCompositionItem(SelectionGroupSignificant,
				"Ref",
				DataCompositionComparisonType.InList,
				ListOfSignificant);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Form.Items.PagesFilterType.CurrentPage = Form.Items.PageBusinessRegions And PositioningIsCorrect("BusinessRegions", Form) Then
		
		If ToSetFilter Then
			CommonClientServer.AddCompositionItem(FilterGroup,
		                                                       "BusinessRegion",
		                                                       DataCompositionComparisonType.Equal,
		                                                       Form.Items.BusinessRegions.CurrentRow);
		EndIf;
		
		Form.CurrentFilterValue = Form.Items.BusinessRegions.CurrentRow;
		
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageAccessGroups And  PositioningIsCorrect("PartnerAccessGroups", Form) Then
		
		If ToSetFilter Then
			CommonClientServer.AddCompositionItem(FilterGroup,
			                                                       "AccessGroup",
			                                                       DataCompositionComparisonType.Equal,
			                                                       Form.Items.PartnerAccessGroups.CurrentRow);
		EndIf;
		
		Form.CurrentFilterValue = Form.Items.PartnerAccessGroups.CurrentRow;
		
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers And PositioningIsCorrect("Managers", Form) Then
		
		If ToSetFilter Then
		CommonClientServer.AddCompositionItem(FilterGroup,
		                                                       "MainManager",
		                                                       DataCompositionComparisonType.Equal,
		                                                       Form.Items.Managers.CurrentRow);
		EndIf;
		
		Form.CurrentFilterValue = Form.Items.Managers.CurrentRow;
		
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.PropertiesPage Then
		
		If ToSetFilter Then
			
			If Form.Items.Properties.CurrentRow <> Undefined And TypeOf(Form.Items.Properties.CurrentRow) = Type("Number") Then 
				CurrentData = Form.Properties.FindByID(Form.Items.Properties.CurrentRow);
				If CurrentData <> Undefined Then
					FilterValue =  CurrentData.Value;
				Else
					Return;
				EndIf;
			Else
				Return
			EndIf;
			
			If FilterValue = NStr("vi = 'Chưa chỉ ra';
									|ru = 'Не указан';
									|en = 'Not specified'; fa = 'مشخص نشده';
									|it = 'Non specificato';
									|pl = 'Nie określony';
									|tr = 'Belirtilmedi'") Then
				
				CommonClientServer.AddCompositionItem(FilterGroup,
				                                                       NameOfSelectionProps + ".[" + String(Form.FilterType_) + "]",
				                                                       DataCompositionComparisonType.NotFilled)
				
			ElsIf FilterValue = NStr("vi = 'Tất cả';
									|ru = 'Все';
									|en = 'All'; fa = 'همه';
									|it = 'Tutti';
									|pl = 'All';
									|tr = 'Tümü'") Then
				
				TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items.Delete(FilterGroup);
				Return;
				
			Else
				
				CommonClientServer.AddCompositionItem(FilterGroup,
				                                                       NameOfSelectionProps + ".[" + String(Form.FilterType_) + "]",
				                                                       DataCompositionComparisonType.Equal,
				                                                       FilterValue);
				
			EndIf;
		EndIf;
		
		Form.CurrentFilterValue = FilterValue;
		
	ElsIf Form.Items.PagesFilterType.CurrentPage = Form.Items.CategoriesPage Then
		
		If ToSetFilter Then
			
			If Form.Items.Categories.CurrentRow <> Undefined And TypeOf(Form.Items.Categories.CurrentRow) = Type("Number") Then 
				CurrentData = Form.Categories.FindByID(Form.Items.Categories.CurrentRow);
				If CurrentData <> Undefined Then
					FilterValue      = CurrentData.Value; // CatalogRef - 
					FilterPresentation = CurrentData.Presentation; // String - 
				Else
					Return;
				EndIf;
			Else
				Return
			EndIf;
				
			If FilterValue <> NStr("vi = 'Tất cả';
									|ru = 'Все';
									|en = 'All'; fa = 'همه';
									|it = 'Tutti';
									|pl = 'All';
									|tr = 'Tümü'") Then
				
				CommonClientServer.AddCompositionItem(FilterGroup,
				                                                       NameOfSelectionProps + ".[" + FilterPresentation + "]",
				                                                       DataCompositionComparisonType.Equal,
				                                                       True);
				
			EndIf;
			
			Form.CurrentFilterValue = FilterValue;
			
		EndIf;
		
	EndIf;
	
	If Form.OnlyMine 
		And (Not Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers
		   Or Not ToSetFilter) Then
		CommonClientServer.AddCompositionItem(FilterGroup,
		                                                       "MainManager",
		                                                       DataCompositionComparisonType.Equal,
		                                                       Form.CurrentUser);
	EndIf;
	
EndProcedure

// Creates a selection group to display only significant items in a dynamic list
//  that acts as a navigation bar for the partner list.
// Parameters:
//  FilterForChange  - DataCompositionFilter - the selection for which the group is being added.
//
// Returns:
//   FilterItem   - the selection group created.
//
Function CreateSignificantSelectionGroup(FilterForChange) Export

	Return CommonClientServer.CreateFilterItemGroup(FilterForChange.Items,"SelectionBySignificant",
		DataCompositionFilterItemsGroupType.AndGroup);

EndFunction

// Creates a selection group in the dynamic list of partners, where the selection elements will be placed
// according to the positioning in the navigation panel.
// Parameters:
//  Form  - ClientApplicationForm - a form that contains a dynamic list of partners.
//
// Returns:
//   FilterItem   - the selection group created.
//
Function CreateFilterSelectionGroup(Form) Export

	Return CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items, "FilterSelection",
		DataCompositionFilterItemsGroupType.AndGroup);

EndFunction

// Checks whether positioning is performed correctly in the dynamic list.
// 
// Parameters:
//  ListName - String - name of the form element that is being checked.
//  Form     - ClientApplicationForm - a form that contains a dynamic list of partners.
//
// Returns:
//   FilterItem   - the selection group created.
//
Function PositioningIsCorrect(ListName,Form) Export

	GroupingType = Type("DynamicListGroupRow");
	
	List = Form.Items[ListName]; // FormTable - 
		
	If TypeOf(List.CurrentRow) <> GroupingType And ValueIsFilled(List.CurrentRow) Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

// Fills in the information panel in the list form based on the partner's data.
// 
// Parameters:
//  Form     - ClientApplicationForm - a form that contains a dynamic list of partners.
//  Partner   - CatalogRef.Partners - the partner whose data is filled in the information panel.
//
Procedure FillInInformationPanelBasedOnPartnerData(Form, Partner) Export

	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		"PartnerProfileReport, ContactPersonsOfPartner",
		"Enabled",
		Partner <> Undefined);
	
	If Not Form.UsePartnersAsCounterparties Then
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Form.Items,
			"PartnerCounterparties",
			"Enabled",
			Partner <> Undefined);
	EndIf;
	
	If Partner = Undefined Then
		
		PartnerData = Undefined;
		
		If Form.UsePartnersAsCounterparties Then
			Form.CurrentPartnerName                = NStr("vi = 'Chưa chọn đối tác';
															|ru = 'Контрагент не выбран';
															|en = 'Counterparty is not selected'; fa = 'Counterparty is not selected';
															|it = 'Contraente non è selezionato';
															|pl = 'Kontrahent nie jest wybrany';
															|tr = 'Cari hesap seçilmedi'");
		Else
			Form.CurrentPartnerName                = NStr("vi = 'Bạn hàng chưa chọn';
															|ru = 'Партнер не выбран';
															|en = 'Partner is not selected'; fa = 'Partner is not selected';
															|it = 'Partner non è selezionato';
															|pl = 'Partner nie jest wybrany';
															|tr = 'İş ortağı seçilmedi'");
			Form.PartnerCounterparties                         = NStr("vi = 'Đối tác';
																		|ru = 'Контрагенты';
																		|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
																		|it = 'Controparti';
																		|pl = 'Counterparties';
																		|tr = 'Cari hesaplar'");
		EndIf;
		
		Form.CurrentBusinessRegion    = "";
		Form.ContactPersonsOfPartner = NStr("vi = 'Người liên hệ';
											|ru = 'Контактные лица';
											|en = 'Contact persons'; fa = 'اشخاص تماس';
											|it = 'Persone di contatto';
											|pl = 'Osoby kontaktowe';
											|tr = 'İrtibat kişileri'");
		
	Else
		
		PartnerData = PartnersAndCounterparties.PartnerDataForInformationPanel(Partner);
		
		Form.CurrentPartnerName = PartnerData.Description;
		
		Form.CurrentBusinessRegion 	 = ?(Form.UseBusinessRegions, PartnerData.BusinessRegion, " ");
		Form.ContactPersonsOfPartner = NStr("vi = 'Người liên hệ';
											|ru = 'Контактные лица';
											|en = 'Contact persons'; fa = 'اشخاص تماس';
											|it = 'Persone di contatto';
											|pl = 'Osoby kontaktowe';
											|tr = 'İrtibat kişileri'") + " (" + String(PartnerData.NumberOfContactPersons) + ")";
		
	EndIf;
	
	If Form.UsePartnersAsCounterparties Then
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "PartnerSCounterpartiesGroup", "Visible", False, True);
	EndIf;
	PartnersAndCounterparties.FillInPartnerSCIDetails(PartnerData, Form);
	PartnersAndCounterpartiesLocalization.FillInInformationPanelBasedOnPartnerData(Form, Partner, PartnerData);
	Form.CurrentActivePartner = Partner;

EndProcedure

// Handler for the "Before recording" event.
// 
// Parameters:
//  Form     - ClientApplicationForm - The Form that contains the dynamic list of partners contains:
//   * Items - FormAllItems - Contains:
//     ** Properties               - FormTable - 
//     ** BusinessRegions          - FormTable -
//     ** Categories              - FormTable - 
//     ** Managers              - FormTable - 
//     ** PartnerAccessGroups - FormTable -
//  Settings - Map - Contains:
//    * FilterType_             - String - type of form filter to be installed
//    * CurrentFilterValue - Arbitrary - current filter value
//    * UseAFilter     - Boolean - indicates that the filter is being used
//    * SegmentSelectionHistory - ValueList of CatalogRef.PartnersSegments - history of previously selected segments
//    * OnlyImportant         - Boolean - indicates that the user will be offered only those filter values that guarantee the presence of items in the dynamic list.
//    * Segment                - CatalogRef.PartnersSegments - the segment for which the selection is set
//    * UseAFilter     - Boolean - indicates that the filter is being used
//    * OnlyImportant         - Boolean - a sign of the established selection by partners whose current user is the main manager
//
Procedure BeforeLoadDataFromSettingsAtServer(Form, Settings) Export
	
	FilterTypeSettings                  = Settings.Get("FilterType_");
	CurSettingFilterValue      = Settings.Get("CurrentFilterValue");
	UseFilterSettings          = Settings.Get("UseAFilter");
	HistoryOfSegmentSelectionSettings      = Settings.Get("SegmentSelectionHistory");
	OnlyMeaningfulSettings              = Settings.Get("OnlyImportant");
	Segment                              = Settings.Get("Segment");
	OnlyMine                            = Settings.Get("OnlyMine");
	
	If HistoryOfSegmentSelectionSettings <> Undefined Then
		Form.Items.Segment.ChoiceList.LoadValues(HistoryOfSegmentSelectionSettings.UnloadValues());
	EndIf;

	If OnlyMine <> Undefined Then
		Form.OnlyMine = OnlyMine;
		Settings.Delete("OnlyMine");
		If Form.UseAFilter And Form.FilterType_ = "Manager" Then
			TMCommonUseClientServer.SetFormItemProperty(Form.Items, "OnlyMine","Enabled", False);
			Form.OnlyMine = False;
		EndIf;
	EndIf;
	
	If Segment <> Undefined And Segment <> Catalogs.PartnersSegments.EmptyRef() Then
		
		Form.Items.List.Representation = TableRepresentation.List;
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "SelectionBySegmentIsSet",
		                                                                   True);
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "FilterBySegment",
		                                                                   SegmentsOfCallServer.ValueList(Segment).UnloadValues());
	Else
		
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "SelectionBySegmentIsSet",
		                                                                   False);
		CommonClientServer.SetDynamicListParameter(Form.List,
		                                                                   "FilterBySegment",
		                                                                   Undefined);
		
	EndIf;
	
	If FilterTypeSettings = Undefined  Then
		Return;
	ElsIf Form.Items.FilterType_.ChoiceList.FindByValue(FilterTypeSettings) <> Undefined Then
		
		Form.FilterType_ = FilterTypeSettings;
		
		If TypeOf(FilterTypeSettings) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo")Then
			Form.OnlyImportant = True;
			Form.Items.OnlyImportant.Enabled = False;
			Form.Items.PagesFilterType.CurrentPage = Form.Items.PropertiesPage;
			FillPropertiesTree(Form);
			Form.Items.Properties.CurrentRow = FindStringInFormDataTree(Form.Properties, CurSettingFilterValue, "Value", True);
		ElsIf Form.FilterType_  = "Categories" Then
			Form.OnlyImportant = True;
			Form.Items.OnlyImportant.Enabled = False;
			Form.Items.PagesFilterType.CurrentPage = Form.Items.CategoriesPage;
			FillCategoryTree(Form);
			FoundRows = Form.Categories.FindRows(New Structure("Value", CurSettingFilterValue));
			If FoundRows.Count() > 0 Then
				Form.Items.Categories.CurrentRow = FoundRows[0].GetID();
			EndIf;
		ElsIf Form.FilterType_  = "BusinessRegions" Then
			Form.Items.PagesFilterType.CurrentPage = Form.Items.PageBusinessRegions;
			Form.Items.BusinessRegions.CurrentRow = CurSettingFilterValue;
		ElsIf Form.FilterType_ = "AccessGroups" Then
			Form.Items.PagesFilterType.CurrentPage = Form.Items.PageAccessGroups;
			Form.Items.PartnerAccessGroups.CurrentRow = CurSettingFilterValue;
		ElsIf Form.FilterType_ = "Manager" Then
			Form.Items.PagesFilterType.CurrentPage = Form.Items.PageManagers;
			Form.Items.Managers.CurrentRow = CurSettingFilterValue;
		EndIf;
		
		If UseFilterSettings <> Undefined Then
			Settings.Delete("UseAFilter");
			If Form.FormName = "Catalog.Counterparties.Form.ChoiceFormOnlyPartnersAreUsed" And Form.ByPartner Then
				Form.UseAFilter = False;
			Else
				Form.UseAFilter =  UseFilterSettings;
			EndIf;
		EndIf;
		
		If OnlyMeaningfulSettings <> Undefined Then
			Form.OnlyImportant = OnlyMeaningfulSettings;
		EndIf;
		
		Form.DoNotTestNavigationPanelActivation = True;
		ChangeFilterList(Form,True,False);
		
	EndIf;
	
	Settings.Delete("FilterType_");
	If CurSettingFilterValue <> Undefined Then
		Settings.Delete("CurrentFilterValue");
	EndIf;
	
EndProcedure

// Checks if there is a dynamic list of search string in the layout settings.
// 
// Parameters:
//  List - DynamicList - the list in which the check is performed.
//
// Returns:
//   Boolean - .
//
Function ThereIsPlatformSearchText(List) Export
	
	DataCompositionFilter = List.GetPerformingDataCompositionSettings().Filter; // DataCompositionFilter
	FilterItems1 = DataCompositionFilter.Items;

	AnalyzedDataLayoutField = New DataCompositionField("Ref");
	AnalyzedTypeOfComparison         = DataCompositionComparisonType.InList;
	
	Result = False;
	CheckIfThereIsSelectionElement(FilterItems1, AnalyzedDataLayoutField, AnalyzedTypeOfComparison, Result);
	
	Return Result
	
EndFunction

// Configures form elements when the full-text search mode is changed.
// 
// Parameters:
//  Form - ClientApplicationForm - the form in which the mode is switched.
//  SaveSettings2 - Boolean - determines whether the Cur settings need to be saved during the procedure.
//
Procedure OnChangeFullTextSearchUsageMode(Form, SaveSettings2 = False) Export
	
	Items = Form.Items;
	
	If Not Form.UseFullTextSearch Then
		
		Items.GroupKeyboardShortcuts.Visible = False;
		Items.ListSwitchSearchMode.Visible = False;
		Return;
		
	EndIf;
	
	Items.ListSwitchSearchMode.Check    = Form.UseAdvancedSearch;
	Items.ListSearchControl.Visible       = False;
	If Items.Find("ListFindByCurrentValue") <> Undefined Then
		Items.ListFindByCurrentValue.Visible = False;
	EndIf;
	
	If Form.UseAdvancedSearch Then
		
		Items.List.SearchStringLocation            = SearchStringLocation.None;
		Items.ListSearchString.Visible            = False; 
		Items.ListSearchControl.Visible       = False;
		Items.FiltersGroup.Visible                 = True; 
		Items.GroupKeyboardShortcuts.Visible          = True;
	
	Else
		
		Items.ListSearchString.Visible            = True;
		Items.List.SearchStringLocation            = SearchStringLocation.Top;
		Items.FiltersGroup.Visible                 = False;
		Items.GroupKeyboardShortcuts.Visible          = False;
		Items.SelectionBasis.Visible               = False;
	
	EndIf;
	
	If SaveSettings2 Then
	
		Common.CommonSettingsStorageSave("UsingFullTextSearchInListOfPartners",
		                                                 "UserSettingsUsingPartners",
		                                                 Form.UseAdvancedSearch);
	
	EndIf;

EndProcedure

// Finds the first row in the specified column, with the specified value in the data collection form Tree.
// 
// Parameters:
//  WhereToFind            - FormDataTree - the tree in which the search is performed.
//  Value             - Arbitrary      - the value we are looking for.
//  Column              - String            - the name of the column we are looking for.
//  SearchSubordinateItems   - Boolean            - indicates whether to search in subordinate rows.
//
// Returns:
//   Number - id of the found string.
//
Function FindStringInFormDataTree(WhereToFind, Value, Column, SearchSubordinateItems) Export
	
	TreeItems = WhereToFind.GetItems();
	
	For Each TreeItem In TreeItems Do
		If TreeItem[Column] = Value Then
			Return TreeItem.GetID();
		ElsIf  SearchSubordinateItems Then
			FoundRowID1 =  FindStringInFormDataTree(TreeItem, Value, Column, SearchSubordinateItems);
			If FoundRowID1 >=0 Then
				Return FoundRowID1;
			EndIf;
		EndIf;
	EndDo;
	
	Return -1;
	
EndFunction

#EndRegion

#Region ProceduresForCheckingCorrectnessOfFilling

// Checks whether the counterparty is filled in correctly. Is called from the procedure "Obrabatyvaniya".
//
// Parameters:
//  Object     - CatalogObject.Counterparties, ClientApplicationForm - an object containing the counterparty's data.
//  Counterparty - CatalogRef.Counterparties - link to the counterparty being checked.
//  Cancel      - Boolean - flag for refusal in the fill-in verification procedure.
//
Procedure CheckWhetherCounterpartyIsFilledInCorrectly(Object, Counterparty, Cancel) Export
	
	DataKey = ?(TypeOf(Object) = Type("ClientApplicationForm"), Undefined, Object);
	
	If Object.BranchOffice And ValueIsFilled(Object.MainCounterparty) Then
		
		If Object.MainCounterparty = Counterparty Then
			
			ErrorText = NStr("vi = 'Đối tác có thể là Chi nhánh, văn phòng đại diện của mình';
							|ru = 'Контрагент не может являться своим обособленным подразделением';
							|en = 'Counterparty cannot be its own branch office'; fa = 'Counterparty cannot be its own branch office';
							|it = 'Contraente non può essere un reparto separato di se stesso';
							|pl = 'Kontrahent nie może być swoim odrębnym działem';
							|tr = 'Cari hesap kendi ayrı departmanı olamaz'");
			CommonClientServer.MessageToUser(ErrorText, DataKey, "MainCounterparty", , Cancel);
			
		Else
			
			PropertiesOfHeadCounterparty = Common.ObjectAttributesValues(
				Object.MainCounterparty, "LegalEntityIndividual, Description, BranchOffice");
			
			If PropertiesOfHeadCounterparty.BranchOffice Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể chọn đối tác %1 làm doanh nghiệp mẹ vì đây chính là bộ phận độc lập';
						|ru = 'Контрагент %1 не может быть выбран головным, т.к. сам является обособленным подразделением';
						|en = 'Counterparty %1 cannot be selected as the main one as it is a branch office'; fa = 'Counterparty %1 cannot be selected as the main one as it is a branch office';
						|it = 'Contraente %1 non può essere selezionato come principale, perché esso stesso è un reparto separato';
						|pl = 'Kontrahent %1 nie może być wybrany jako główny, ponieważ sam jest oddzielnym działem';
						|tr = '%1 cari hesabı ana hesap olarak seçilemez, çünkü kendisi bir ayrı departmandır'"),
					PropertiesOfHeadCounterparty.Description);
				CommonClientServer.MessageToUser(ErrorText, DataKey, "MainCounterparty", , Cancel);
				
			ElsIf PropertiesOfHeadCounterparty.LegalEntityIndividual <> Enums.LegalEntityIndividual.Entity Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể chọn đối tác %1 làm doanh nghiệp mẹ vì đây không phải là pháp nhân';
						|ru = 'Контрагент %1 не может быть выбран головным, т.к. не является юридическим лицом';
						|en = 'Counterparty %1 cannot be selected as the main one as it is not a legal entity'; fa = 'Counterparty %1 cannot be selected as the main one as it is not a legal entity';
						|it = 'Contraente %1 non può essere selezionato come principale, in quanto non è una persona giuridica';
						|pl = 'Kontrahent %1 nie może być wybrany jako główny, ponieważ nie jest osobą prawną';
						|tr = '%1 cari hesabı ana hesap olarak seçilemez, çünkü tüzel kişi değil'"),
					PropertiesOfHeadCounterparty.Description);
				CommonClientServer.MessageToUser(ErrorText, DataKey, "MainCounterparty", , Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Object.BranchOffice Or Object.LegalEntityIndividual <> Enums.LegalEntityIndividual.Entity Then
		
		ArrayOfSeparateDivisions = SeparateDivisionsOfCounterparty(Counterparty);
		If ArrayOfSeparateDivisions.Count() > 0 Then
			
			If Object.BranchOffice Then
				ErrorText =
					NStr("vi = 'Đối tác không thể là bộ phận độc lập vì đây chính là doanh nghiệp mẹ của các đối tác khác';
						|ru = 'Контрагент не может быть обособленным подразделением, т.к. сам является головным для других контрагентов';
						|en = 'Counterparty cannot be a branch office as it is the main one for other counterparties'; fa = 'Counterparty cannot be a branch office as it is the main one for other counterparties';
						|it = 'Contraente non può essere un reparto separato, in quanto esso stesso è un reparto principale per altri contraenti';
						|pl = 'Kontrahent nie może być odrębnym działem, ponieważ sam jest głównym dla innych kontrahentów';
						|tr = 'Cari hesap bir ayrı departman olamaz, çünkü kendisi diğer cari hesapların üst öğesidir'");
			Else
				ErrorText =
					NStr("vi = 'Cần chọn đối tác là pháp nhân, vì đây là doanh nghiệp mẹ đối với các đối tác khác';
						|ru = 'Контрагент должен быть юридическим лицом, т.к. является головным подразделением для других контрагентов';
						|en = 'Counterparty must be a legal entity because it is a main business unit for other counterparties'; fa = 'Counterparty must be a legal entity because it is a main business unit for other counterparties';
						|it = 'Contraente deve essere una persona fisica, in quanto è un reparto principale per altri contraenti';
						|pl = 'Kontrahent powinien być osobą prawną, ponieważ jest głównym działem dla innych kontrahentów';
						|tr = 'Cari hesap tüzel kişi olmalıdır, çünkü diğer cari hesaplar için ana alt departmandır'");
			EndIf;
			
			CommonClientServer.MessageToUser(ErrorText, , , "CounterpartyKind", Cancel);
			
		EndIf
		
	EndIf;
	
	If ValueIsFilled(Object.RegistrationNumber) And Object.LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident Then
		
		CounterpartySelection = CountryRegistrationNumberIsAlreadyUsedInInformationBase(Object.RegistrationNumber, Object.RegistrationCountry, Counterparty);
		
		If CounterpartySelection <> Undefined Then
			MessageText = NStr("vi = 'Đã chỉ ra dữ liệu của số đăng ký tại quốc gia này đối với đối tác có mã %1, người chịu trách nhiệm - %2.';
								|ru = 'Данные регистрационного номера в этой же стране регистрации уже указаны для контрагента с кодом %1, ответственный - %2.';
								|en = 'Data of the registration number in this country of residence is already specified for the counterparty with code %1, responsible person - %2.'; fa = 'Data of the registration number in this country of residence is already specified for the counterparty with code %1, responsible person - %2.';
								|it = 'I dati del numero di registrazione nello stesso paese di registrazione sono già indicati per il contraente con il codice %1, responsabile - %2.';
								|pl = 'Dane rejestracyjnego numeru w tym samym kraju rejestracji już są wskazane dla kontrahenta z kodem %1, odpowiedzialny - %2.';
								|tr = 'Aynı kayıt ülkesindeki kayıt numarasının verileri, %1 kodlu, sorumlu - %2 cari hesap için zaten belirtildi.'");
			MessageText =  StringFunctionsClientServer.SubstituteParametersToString(MessageText, CounterpartySelection.Code, CounterpartySelection.MainManager);
			CommonClientServer.MessageToUser(MessageText, DataKey, "RegistrationNumber", , Cancel);			
		EndIf;
		
	EndIf;
	
	PartnersAndCounterpartiesLocalization.CheckWhetherCounterpartyIsFilledInCorrectly(Object, Counterparty, Cancel);
	
EndProcedure

// Checks the partner's completion. Called from the "Check-in processing" procedure.
//
// Parameters:
//  Object - DocumentObject - the object where you want to check the partner.
//  NotCheckedAttributeArray - Array of String - collection of names of object details that do not require verification.
//  Cancel - Boolean - flag for refusal in the fill-in verification procedure.
//  ReverseOperation  - Boolean - indicates that the business transaction is used in the document as the reverse.
//
Procedure CheckPartnerContent(Object, NotCheckedAttributeArray, Cancel, ReverseOperation = False) Export
	
	If Not ValueIsFilled(Object.Partner) Then
		
		NotCheckedAttributeArray.Add("Partner");
		
		TitlePartner = HeaderOfPartnerDetailsDependingOnBusinessOperation(
			Object.BusinessOperation, ReverseOperation);
		ErrorText = CommonClientServer.FillingErrorText(, , TitlePartner);
		
		Common.MessageToUser(ErrorText, Object, "Partner", , Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

// Called to enable history maintenance for the contact information type.
// Parameters:
//  ContactInformationKindName - String - name of the contact information type.
//
Procedure EnableChangeHistoryStorage(ContactInformationKindName) Export
	
	SetPrivilegedMode(True);
	
	If Not Common.ObjectAttributeValue(Catalogs.ContactInformationKinds[ContactInformationKindName], "StoreChangeHistory") Then
		
		ContactInformationKind = Catalogs.ContactInformationKinds[ContactInformationKindName].GetObject();
		ContactInformationKind.StoreChangeHistory = True;
		ContactInformationKind.EditingOption = "Dialog";
		InfobaseUpdate.WriteData(ContactInformationKind);
		
	EndIf;
	
EndProcedure

// The function gets the values of the details of the selected counterparty.
//
// Parameters:
//  Counterparty - CatalogRef.Counterparties - Link to the counterparty.
//  DateOfLastEdit - Date - date the information was received.
//
// Returns:
//  Structure - Attributes of the selected counterparty:
//  	* Presentation - String - 
//  	* Description - String -
//  	* DescriptionInternational - String - 
//  	* LegalEntityIndividual - EnumRef.LegalEntityIndividual -
Function CounterpartyDetails_(Counterparty, DateOfLastEdit = Undefined) Export
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Presentation", "");
	AttributesStructure1.Insert("Description",  "");
	AttributesStructure1.Insert("LegalEntityIndividual",     Enums.LegalEntityIndividual.EmptyRef());
	AttributesStructure1.Insert("TIN",           "");
	AttributesStructure1.Insert("DescriptionInternational", "");
	
	Query = New Query;
	
	If DateOfLastEdit <> Undefined Then
		
		Query.Text = "
		|SELECT ALLOWED TOP 1
		|	HistoryOfCounterpartyNames.NameAbbreviated AS NameAbbreviated
		|INTO HistoricalSignificanceOfName
		|FROM
		|	Catalog.Counterparties.NameHistory AS HistoryOfCounterpartyNames
		|WHERE
		|	HistoryOfCounterpartyNames.Ref = &Counterparty
		|	AND HistoryOfCounterpartyNames.Period <= &DateOfLastEdit
		|	AND HistoryOfCounterpartyNames.NameAbbreviated <> &IsBlankString
		|
		|ORDER BY
		|	HistoryOfCounterpartyNames.Period DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT ALLOWED
		|	Counterparties.TIN                                                                                    AS TIN,
		|	ISNULL(HistoricalSignificanceOfName.NameAbbreviated, Counterparties.DescriptionFull) AS DescriptionFull,
		|	Counterparties.LegalEntityIndividual                                                                              AS LegalEntityIndividual,
		|	Counterparties.DescriptionInternational AS DescriptionInternational
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|	LEFT JOIN HistoricalSignificanceOfName AS HistoricalSignificanceOfName
		|		ON (TRUE)
		|WHERE
		|	Counterparties.Ref = &Counterparty
		|";
		
		Query.SetParameter("DateOfLastEdit", DateOfLastEdit);
		Query.SetParameter("IsBlankString", "");
		
	Else
		
		Query.Text = "
		|SELECT ALLOWED
		|	Counterparties.TIN                       AS TIN,
		|	Counterparties.DescriptionFull        AS DescriptionFull,
		|	Counterparties.LegalEntityIndividual                 AS LegalEntityIndividual,
		|	Counterparties.DescriptionInternational AS DescriptionInternational
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	Counterparties.Ref = &Counterparty";
		
	EndIf;
	
	Query.SetParameter("Counterparty", Counterparty);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		AttributesStructure1.Presentation = Selection.DescriptionFull;
		AttributesStructure1.Description  = Selection.DescriptionFull;
		AttributesStructure1.LegalEntityIndividual     = Selection.LegalEntityIndividual;
		AttributesStructure1.TIN           = Selection.TIN;
		AttributesStructure1.DescriptionInternational = Selection.DescriptionInternational;
	EndIf;
	PartnersAndCounterpartiesLocalization.AddCounterpartyDetails(Counterparty, AttributesStructure1, DateOfLastEdit);
	Return AttributesStructure1;
	
EndFunction

#Region InterfaceImplementation

#Region BatchProcessingOfTableParts

// Adds a request to the request package for obtaining a Contract by default 
// for processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndFillInDefaultPartnerSCounterparty(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInPartnerSDefaultCounterparty",
		StructureOfActions,
		CachedValues,
		Parameters) Then
		
		Return;
		
	EndIf;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		QueryText = 
		"SELECT ALLOWED
		|	DataSource.IdOfTTRow AS IdOfTTRow,
		|	ISNULL(Counterparties.Ref, VALUE(Catalog.Counterparties.EmptyRef)) AS Counterparty
		|FROM
		|	TTDataSource AS DataSource
		|		LEFT JOIN Catalog.Counterparties AS Counterparties
		|		ON DataSource.Partner = Counterparties.Partner";
		QueryDetails.QueriesTexts.Add(QueryText, "FillInPartnerSDefaultCounterparty");
	Else
		
		QueryText = 
		"SELECT ALLOWED
		|	DataSource.IdOfTTRow AS IdOfTTRow,
		|	DataSource.Counterparty AS CurrentCounterparty,
		|	&CounterpartyFromAgreement AS CounterpartyFromAgreement,
		|	ISNULL(PartnerHierarchy.Level, 0) AS LevelInHierarchy,
		|	ISNULL(PartnerHierarchy.Parent, VALUE(Catalog.Partners.EmptyRef)) AS HierarchyPartner
		|INTO DefaultPartnerCounterpartySearchParameters
		|FROM
		|	TTDataSource AS DataSource
		|		LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|		ON DataSource.Partner = PartnerHierarchy.Partner";
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Terms", CachedValues) Then 
		
			// It is necessary to check the use of the Contract by agreement
			QueryText = StrReplace(QueryText,
				"&CounterpartyFromAgreement",
				"ISNULL(
				|	CAST(DataSource.Terms AS Catalog.TermsOfPurchaseFromVendors).Counterparty,
				|	VALUE(Catalog.Counterparties.EmptyRef))");
		
		Else
		
			QueryText = StrReplace(QueryText,
				"&CounterpartyFromAgreement",
				"VALUE(Catalog.Counterparties.EmptyRef)");
	
		EndIf;
		
		QueryDetails.QueriesTexts.Add(QueryText, "DefaultPartnerCounterpartySearchParameters");
		
		QueryText = 
		"SELECT ALLOWED
		|	SearchParameters.IdOfTTRow AS IdOfTTRow,
		|	SearchParameters.LevelInHierarchy AS LevelInHierarchy,
		|	SearchParameters.CounterpartyFromAgreement AS CounterpartyFromAgreement,
		|	Counterparties.Ref AS Counterparty, // We do not process null in order not to complicate the calculation of the number of counterparties at each level of the hierarchy.
		|	ISNULL(SearchParameters.CurrentCounterparty = Counterparties.Ref, FALSE) AS ThisIsCurrentCounterparty
		|INTO AvailablePartnerCounterparties
		|FROM
		|	DefaultPartnerCounterpartySearchParameters AS SearchParameters
		|		LEFT JOIN Catalog.Counterparties AS Counterparties
		|		ON SearchParameters.HierarchyPartner = Counterparties.Partner
		|		AND NOT Counterparties.DeletionMark";
		QueryDetails.QueriesTexts.Add(QueryText, "AvailablePartnerCounterparties");
		
		QueryText = 
		"SELECT
		|	// Choosing the closest ""parent"", with counterparties, provided that the number of its counterparties = 1
		|	DescriptionOfHierarchyLevels.IdOfTTRow AS IdOfTTRow,
		|	&MaximumLevelWithSingleCounterparty AS LevelInHierarchy
		|INTO DescriptionOfSourceLevels
		|FROM
		|	(SELECT
		|		AvailablePartnerCounterparties.IdOfTTRow AS IdOfTTRow,
		|		AvailablePartnerCounterparties.LevelInHierarchy AS LevelInHierarchy,
		|		COUNT(DISTINCT AvailablePartnerCounterparties.Counterparty) = 1 AS OnlyCounterparty,
		|		COUNT(DISTINCT AvailablePartnerCounterparties.Counterparty) > 1 AS CounterpartiesSet
		|	FROM
		|		AvailablePartnerCounterparties AS AvailablePartnerCounterparties
		|	GROUP BY
		|		AvailablePartnerCounterparties.IdOfTTRow,
		|		AvailablePartnerCounterparties.LevelInHierarchy) AS DescriptionOfHierarchyLevels
		|GROUP BY
		|	DescriptionOfHierarchyLevels.IdOfTTRow
		|HAVING
		|	&MaximumLevelWithSingleCounterparty > &MaximumLevelWithMultipleCounterparties";
		
		TemplateForGettingLevel =  
		"MAX(
		|	CASE WHEN DescriptionOfHierarchyLevels.%1 THEN 
		|		DescriptionOfHierarchyLevels.LevelInHierarchy
		|	ELSE // The value is missing. We choose a value less than possible:
		|		-1
		|	END)";
		
		QueryText = StrReplace(
			QueryText,
			"&MaximumLevelWithSingleCounterparty",
			StrTemplate(TemplateForGettingLevel, "OnlyCounterparty"));
		
		QueryText = StrReplace(
			QueryText,
			"&MaximumLevelWithMultipleCounterparties",
			StrTemplate(TemplateForGettingLevel, "CounterpartiesSet"));
			
		QueryDetails.QueriesTexts.Add(QueryText, "DescriptionOfSourceLevels");
		
		QueryText = 
		"SELECT
		|	AvailablePartnerCounterparties.IdOfTTRow,
		|	ISNULL( // 1. Selection of the current specified counterparty:
		|		MAX(CASE WHEN AvailablePartnerCounterparties.ThisIsCurrentCounterparty THEN
		|			 AvailablePartnerCounterparties.Counterparty
		|		ELSE NULL
		|	END),
		|		// 2. Choosing a counterparty from the agreement, if the agreement is completed and the counterparty is in it:
		|		CASE WHEN MAX(AvailablePartnerCounterparties.CounterpartyFromAgreement) <> VALUE(Catalog.Counterparties.EmptyRef) THEN
		|			MAX(AvailablePartnerCounterparties.CounterpartyFromAgreement)
		|		ELSE
		|			MAX(CASE WHEN DescriptionOfSourceLevels.LevelInHierarchy IS NOT NULL THEN
		|				// 3. A counterparty from the nearest ""parent"" with a single counterparty:
		|				AvailablePartnerCounterparties.Counterparty
		|			ELSE // 4. There is no way to automatically select a value:
		|				VALUE(Catalog.Counterparties.EmptyRef)
		|			END)
		|	END) AS Counterparty
		|FROM
		|	AvailablePartnerCounterparties AS AvailablePartnerCounterparties
		|		LEFT JOIN DescriptionOfSourceLevels AS DescriptionOfSourceLevels
		|		ON AvailablePartnerCounterparties.IdOfTTRow = DescriptionOfSourceLevels.IdOfTTRow
		|		AND AvailablePartnerCounterparties.LevelInHierarchy = DescriptionOfSourceLevels.LevelInHierarchy
		|GROUP BY
		|	AvailablePartnerCounterparties.IdOfTTRow";
		QueryDetails.QueriesTexts.Add(QueryText, "FillInPartnerSDefaultCounterparty");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

// Complements the request for a dynamic partner list with a relationship type condition while preserving the higher-level elements of the hierarchy.
//
// Parameters:
//  Relationship type - String - the type of relationship for which the condition is imposed.
//
// Returns:
//  String  - addition of the request text.
//
Function AddingDynamicListRequestForPartners(ListFilterByPartnerType, SetSelectionByPartnerTypeAsOR) 
	
	FIlterRow = "";
	StringConditionOr = " OR ";
	StringConditionAnd   = " And ";
	ConditionString = ?(SetSelectionByPartnerTypeAsOR, StringConditionOr, StringConditionAnd);
	
	For Each ListItem In ListFilterByPartnerType Do
		
		If ListItem.Value = "OurEnterprise" Then
			Condition = "Partners.Ref = VALUE(Catalog.Partners.OurEnterprise)"; 
		Else
			Condition = "Partners." + ListItem; 
		EndIf; 
		FIlterRow = FIlterRow + ConditionString + Condition;
		
	EndDo;
	
	FIlterRow = Right(FIlterRow,
	               StrLen(FIlterRow) - ?(SetSelectionByPartnerTypeAsOR, StrLen(StringConditionOr) - 1, StrLen(StringConditionAnd) - 1));
	
	Return "
	|AND
	|	CatalogPartners.Ref IN
	|		(SELECT DISTINCT
	|			PartnerHierarchy.Parent AS Ref
	|		FROM
	|			Catalog.Partners AS Partners LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|				ON
	|					PartnerHierarchy.Partner = Partners.Ref
	|		WHERE
	|			" + FIlterRow + ")";
	
EndFunction

Function ThereAreFormProps(Source, AttributeName) Export
	
	RequiredDetails = New Structure(AttributeName, NULL);
	FillPropertyValues(RequiredDetails, Source);

	PropsExist = False;
	If RequiredDetails[AttributeName] <> NULL Then
		PropsExist = True;
	EndIf;
	
	Return PropsExist;

EndFunction

#Region PartnerHierarchy

Procedure RecordForSubordinatePartners(TreeRows, CurProcessingElement)
	
	For Each TreeRow In TreeRows Do
		
		If TreeRow["Ref"] <> CurProcessingElement Then
			WriteToRegisterByPartner(TreeRow);
		EndIf;
		
	EndDo;
	
EndProcedure


// Writes to the Partner Hierarchy PC.
// 
// Parameters:
// 	TreeRow - Undefined, ValueTreeRow - LongDesc:
//   * Ref - CatalogRef.Partners - partner that has a parent defined in the hierarchy.
//
Procedure WriteToRegisterByPartner(TreeRow);
	
	RecordSet = InformationRegisters.PartnerHierarchy.CreateRecordSet();
	RecordSet.Filter.Partner.Set(TreeRow.Ref);
	
	ParentOfTreeRow = TreeRow;
	While ParentOfTreeRow <> Undefined Do
		SetRecord = RecordSet.Add();
		SetRecord.Partner  = TreeRow.Ref;
		SetRecord.Parent = ParentOfTreeRow.Ref;
		SetRecord.Level  = ParentOfTreeRow.Level();
		ParentOfTreeRow  = ParentOfTreeRow.Parent;
	EndDo;
	
	RecordSet.Write();
	
	RecordForSubordinatePartners(TreeRow.Rows, TreeRow.Ref);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithForms

// Generates a list of set selections for the partner in the list form.
// 
// Parameters:
// 	Form - ClientApplicationForm - Contains:
// 	* ListFilterByPartnerType - ValueList - 
// 	
Procedure GenerateListOfInstalledSelectionsDynamicListPartners(Form)
	
	If Form.Parameters.Filter.Property("Client") Then
		Form.ListFilterByPartnerType.Add("Client");
	EndIf;
	If Form.Parameters.Filter.Property("Vendor") Then
		Form.ListFilterByPartnerType.Add("Vendor");
	EndIf;
	If Form.Parameters.Filter.Property("Carrier") Then
		Form.ListFilterByPartnerType.Add("Carrier");
	EndIf;
	If Form.Parameters.Filter.Property("Competitor") Then
		Form.ListFilterByPartnerType.Add("Competitor");
	EndIf;
	If Form.Parameters.Filter.Property("OtherRelations") Then
		Form.ListFilterByPartnerType.Add("OtherRelations");
	EndIf;
	If Form.Parameters.Filter.Property("ServedBySalesRepresentatives") Then
		Form.ListFilterByPartnerType.Add("ServedBySalesRepresentatives");
	EndIf;
	If Form.Parameters.Filter.Property("OurEnterprise") Then
		Form.ListFilterByPartnerType.Add("OurEnterprise");
	EndIf;
	
EndProcedure

Procedure SetVisibilityOfReportCommands(Form)
	FormName = Form.FormName;
	
	If StrFind(FormName, "ListForm") Then
		FormSelections = Form.Parameters.Filter;
		ThisIsFormOfSuppliers = FormSelections.Property("Vendor") And FormSelections.Vendor;
		ThisIsClientsForm = FormSelections.Property("Client") And FormSelections.Client;
		
		If Not Form.Items.Find("ListReportStateOfSettlementsWithClient") = Undefined Then
			Form.Items.ListReportStateOfSettlementsWithClient.Visible = ThisIsClientsForm;
		EndIf;
		If Not Form.Items.Find("ListReportCardOfSettlementsWithClient") = Undefined Then
			Form.Items.ListReportCardOfSettlementsWithClient.Visible = ThisIsClientsForm;
		EndIf;
		If Not Form.Items.Find("ListReportRevenueAndCostOfSalesSales") = Undefined Then
			Form.Items.ListReportRevenueAndCostOfSalesSales.Visible = ThisIsClientsForm;
		EndIf;
		If Not Form.Items.Find("ListAndTermsOfAgreementsWithClientForPartner") = Undefined Then
			Form.Items.ListAndTermsOfAgreementsWithClientForPartner.Visible = ThisIsClientsForm;
		EndIf;
		If Not Form.Items.Find("ListReportStateOfSettlementsWithSupplier") = Undefined Then
			Form.Items.ListReportStateOfSettlementsWithSupplier.Visible = ThisIsFormOfSuppliers;
		EndIf;
		If Not Form.Items.Find("ListReportCardOfSettlementsWithSupplier") = Undefined Then
			Form.Items.ListReportCardOfSettlementsWithSupplier.Visible = ThisIsFormOfSuppliers;
		EndIf;
		If Not Form.Items.Find("ListAndTermsOfAgreementsWithSupplierByPartner") = Undefined Then
			Form.Items.ListAndTermsOfAgreementsWithSupplierByPartner.Visible = ThisIsFormOfSuppliers;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                   Form,"PartnerProfileReport", NStr("vi = 'Hồ sơ';
														|ru = 'Досье';
														|en = 'Profile'; fa = 'پروفایل';
														|it = 'Cartella';
														|pl = 'Profile';
														|tr = 'Dosya'"));
	
EndProcedure

#EndRegion

#Region GeneralProceduresForCreatingPartnerCatalogElement

Procedure PartnerFormElementWhenCreatedReadOnServer(Form)

	PartnerFormOfAccessibilityControl(Form);
	Form.CurrentBusinessRegion = Form.Object.BusinessRegion;
	PartnerFormOfCustomizeNavigationBarItem(Form);
	Form.Items.AdditionalInformationGroup.Picture = CommonClientServer.CommentPicture(Form.Object.AdditionalInformation);
	
EndProcedure

Procedure PartnerFormOfCustomizeNavigationBarItem(Form)

	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseCustomerPartnerData", Form.Object.Client);
	SettingsStructure.Insert("UseVendorPartnerData", Form.Object.Vendor);
	SettingsStructure.Insert("UseSalesRepresentativeData", Form.Object.ServedBySalesRepresentatives);
	SettingsStructure.Insert("UseDataOfVendorOrCompetitor", Form.Object.Vendor Or Form.Object.Competitor);
	SettingsStructure.Insert("UseIndividualCounterpartyData", GetFunctionalOption("UsePartnersAsCounterparties")
	                                                                           And CommonClientServer.HasAttributeOrObjectProperty(Form, "LegalEntityIndividual")
	                                                                           And (Form.LegalEntityIndividual = Enums.LegalEntityIndividual.Person Or Form.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur));
	SettingsStructure.Insert("UsePartnerDataOfTermsOfSales", Form.Object.Client 
	                                                                             And GetFunctionalOption("ToUseTermsOfSales"));
	SettingsStructure.Insert("UsePartnerDataCustomerOpportunities",   Form.Object.Client 
	                                                                             And GetFunctionalOption("UseSalesOpportunitiesToCustomer"));
	SettingsStructure.Insert("UseLoanAndDepositContracts", Form.Object.OtherRelations And GetFunctionalOption("UseLoanAndDepositContracts"));
	
	TMCommonUse.ConfigureFormByParameters(Form, SettingsStructure);

EndProcedure


// Gets the primary interest for the partner.
// 
// Parameters:
// 	Partner       - CatalogRef.Partners - for which the primary interest is obtained.
// 	PartnerOnly - Boolean - indicates that you do not need to take into account interest in transactions.
// Returns:
// 	Structure - LongDesc:
// * ChannelOfInitialRequest     - ChartOfCharacteristicTypesRef.ChannelsOfAdvertisingImpacts -
// * SourceOfInitialRequest  - CatalogRef - 
// * SalesOpportunity                      - CatalogRef.SalesOpportunitiesToCustomer - 
//
Function PrimaryInterest(Partner, PartnerOnly = False)

	Interest = New Structure("SourceOfInitialRequest, SalesOpportunity");
	Interest.Insert(
		"ChannelOfInitialRequest",
		ChartsOfCharacteristicTypes.ChannelsOfAdvertisingImpacts.EmptyRef());

	Query = New Query;
	
	QueryText = "SELECT TOP 1
		|	SourcesOfInitialRequests.ChannelOfInitialRequest,
		|	SourcesOfInitialRequests.SourceOfInitialRequest,
		|	SourcesOfInitialRequests.SalesOpportunity
		|FROM
		|	InformationRegister.SourcesOfInitialRequests AS SourcesOfInitialRequests
		|WHERE
		|	SourcesOfInitialRequests.Partner = &Partner";
		
	If PartnerOnly Then
		QueryText = QueryText + "
		|	AND SourcesOfInitialRequests.SalesOpportunity = VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)";
	EndIf;	

	QueryText = QueryText + "
		|
		|ORDER BY
		|	SourcesOfInitialRequests.SalesOpportunity.StartDate";
		
	Query.Text = QueryText;

	Query.SetParameter("Partner", Partner);

	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();

	If Selection.Next() Then
		Interest.ChannelOfInitialRequest		= Selection.ChannelOfInitialRequest;
		Interest.SourceOfInitialRequest	= Selection.SourceOfInitialRequest;
		Interest.SalesOpportunity						= Selection.SalesOpportunity;
	EndIf;

	Return Interest;

EndFunction

// Captures the primary interest when writing from the form.
// 
// Parameters:
//  Form - ClientApplicationForm - Contains:
//   * Object - CatalogObject.Partners -
//            - CatalogObject.SalesOpportunitiesToCustomer -
Procedure CapturePrimaryInterest(Form)

	Interest = PrimaryInterest(Form.Object.Ref, True);
	If Form.ChannelOfInitialRequest <> Interest.ChannelOfInitialRequest
	 Or Form.SourceOfInitialRequest <> Interest.SourceOfInitialRequest Then

		SetPrivilegedMode(True);
		Record = InformationRegisters.SourcesOfInitialRequests.CreateRecordManager();
		Record.Partner = Form.Object.Ref;

		If Not ValueIsFilled(Form.ChannelOfInitialRequest)
		   And Not ValueIsFilled(Form.SourceOfInitialRequest) Then
			Record.Delete();
		Else
			Record.ChannelOfInitialRequest    = Form.ChannelOfInitialRequest;
			Record.SourceOfInitialRequest = Form.SourceOfInitialRequest;
			Record.Write();
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

Procedure FillInListOfPartnersFromTree(TreeRows, PartnerList, Partner)
	
	For Each TreeRow In TreeRows Do
		PartnerList.Add(TreeRow.Ref, TreeRow.Description);
		If TreeRow.Ref <> Partner Then
			FillInListOfPartnersFromTree(TreeRow.Rows, PartnerList,Partner);
		EndIf;
	EndDo;
	
EndProcedure

// Performs advanced partner search
// Parameters:
//   SearchString    - String - it is searched for.
//   PartnerList - ValueTable - filled in with search results.
// Returns:
//    String, Undefined - text representation of the search result.
//
Function FindPartners(SearchString, PartnerList)

	// configure search parameters
	MSearchArea = New Array;
	PortionSize = 200;
	SearchResultsList = FullTextSearch.CreateList(SearchString, PortionSize);
	MSearchArea.Add(Metadata.Catalogs.Partners);
	MSearchArea.Add(Metadata.Catalogs.Counterparties);
	MSearchArea.Add(Metadata.Catalogs.ContactPersonsForPartners);
	MSearchArea.Add(Metadata.Catalogs.CounterpartyContracts);
	SearchResultsList.SearchArea = MSearchArea;
	
	Try
		SearchResultsList.FirstPart();
	Except
		Return NStr("vi = 'Khi thực hiện tìm kiếm đã xảy ra lỗi, hãy thử thay đổi biểu thức tìm kiếm.';
					|ru = 'При выполнении поиска произошла ошибка, попробуйте изменить выражение поиска.';
					|en = 'An error occurred when performing search. Try to change search expression.'; fa = 'An error occurred when performing search. Try to change search expression.';
					|it = 'Si è verificato un errore durante l''esecuzione di una ricerca, prova a cambiare l''inserimento di ricerca';
					|pl = 'Przy wykonaniu wyszukiwania wystąpił błąd, spróbuj zmienić wyrażenie wyszukiwania.';
					|tr = 'Arama yapılırken hata oluştu, arama ifadesini değiştirmeyi dene.'");
	EndTry;
	
	// refund if the search is not effective
	If SearchResultsList.TotalCount() = 0 Then
		Return NStr("vi = 'Không tìm thấy gì';
					|ru = 'Ничего не найдено';
					|en = 'No results found'; fa = 'No results found';
					|it = 'Non è stato trovato nulla';
					|pl = 'Nic nie znaleziono';
					|tr = 'Bulunamadı'");
	EndIf;
	
	If SearchResultsList.TooManyResults() Then
		Return NStr("vi = 'Quá nhiều kết quả, hãy làm rõ yêu cầu.';
					|ru = 'Слишком много результатов, уточните запрос.';
					|en = 'Too many results. Please narrow your search.'; fa = 'Too many results. Please narrow your search.';
					|it = 'Troppi risultati, perfezionate la query.';
					|pl = 'Zbyt dużo wyników, uściślij zapytanie.';
					|tr = 'Çok fazla sonuç var; aramanızı daraltın.'");
	EndIf;
	
	ItemCount = SearchResultsList.TotalCount();
	
	// generate a list of found partners
	PartnerList.Clear();
	StartPosition = 0;
	EndPosition = ?(ItemCount > PortionSize, PortionSize, ItemCount)-1;
	HasNextBatch = True;

	// process the PPD results by portions
	While HasNextBatch Do
		For ItemsCounter = 0 To EndPosition Do
			
			// generate a result element
			Item = SearchResultsList.Get(ItemsCounter);
			ItemRef1 = Item.Value.Ref;
			Basis = Item.Metadata.ObjectPresentation + " """
			            + Item.Presentation + """ - " + Item.Description;
			If Item.Metadata = Metadata.Catalogs.Partners Then
				Partner = Item.Value;
				Basis = NStr("vi = 'Đã tìm thấy trong mục tin bạn hàng';
							|ru = 'Найдено в реквизите партнера';
							|en = 'Found in the partner attribute'; fa = 'Found in the partner attribute';
							|it = 'Trovato nei dettagli del partner';
							|pl = 'Znaleziono w atrybucie partnera';
							|tr = 'İş ortağı özniteliğinde bulundu'") + " - " + Item.Description;
			ElsIf Item.Metadata = Metadata.Catalogs.ContactPersonsForPartners Then
				Partner = Item.Value.Owner;
				BaseTemplate =  NStr("vi = 'Đã tìm thấy trong mục tin của cá nhân liên hệ bạn hàng ""%1"" - %2';
									|ru = 'Найдено в реквизите контактного лица партнера ""%1"" - %2';
									|en = 'Found in the attribute of partner contact person ""%1"" - %2'; fa = 'Found in the attribute of partner contact person ""%1"" - %2';
									|it = 'Trovato nei dettagli di persona di riferimento del partner ""%1"" - %2';
									|pl = 'Znaleziono w atrybucie osoby do kontaktu partnera ""%1"" - %2';
									|tr = '""%1"" - %2 iş ortağının irtibat kişisi özniteliğinde bulundu'");
				Basis = StringFunctionsClientServer.SubstituteParametersToString(BaseTemplate, Item.Value, Item.Description); 
			ElsIf Item.Metadata = Metadata.Catalogs.CounterpartyContracts Then
				Partner = Item.Value.Partner;
				BaseTemplate =  NStr("vi = 'Đã tìm thấy trong hợp đồng của bạn hàng ""%1"" - %2';
									|ru = 'Найдено в договоре партнера ""%1"" - %2';
									|en = 'Found in the partner contract ""%1"" - %2'; fa = 'Found in the partner contract ""%1"" - %2';
									|it = 'Trovato nel contratto del partner ""%1"" - %2';
									|pl = 'Znaleziono w kontrakcie partnera ""%1"" - %2';
									|tr = 'İş ortağı sözleşmesinde bulundu ""%1"" - %2'");
				Basis = StringFunctionsClientServer.SubstituteParametersToString(BaseTemplate, Item.Value, Item.Description);
			ElsIf Item.Metadata = Metadata.Catalogs.Counterparties Then
				Partner = Item.Value.Partner;
				If GetFunctionalOption("UsePartnersAsCounterparties") Then
					Basis = NStr("vi = 'Đã tìm thấy trong mục tin bạn hàng';
								|ru = 'Найдено в реквизите партнера';
								|en = 'Found in the partner attribute'; fa = 'Found in the partner attribute';
								|it = 'Trovato nei dettagli del partner';
								|pl = 'Znaleziono w atrybucie partnera';
								|tr = 'İş ortağı özniteliğinde bulundu'") + " - "+ Item.Description;
					ItemRef1 = Partner;
				Else
					BaseTemplate =  NStr("vi = 'Đã tìm thấy trong đối tác của bạn hàng ""%1"" - %2';
										|ru = 'Найдено в контрагенте партнера ""%1"" - %2';
										|en = 'Found in partner counterparty ""%1"" - %2'; fa = 'Found in partner counterparty ""%1"" - %2';
										|it = 'Trovato nel contraente del partner ""%1"" - %2';
										|pl = 'Znaleziono w kontrahencie partnera ""%1"" - %2';
										|tr = 'İş ortağının cari hesabında bulundu ""%1"" - %2'");
					Basis = StringFunctionsClientServer.SubstituteParametersToString(BaseTemplate, Item.Value, Item.Description);
				EndIf;
				
			ElsIf Not ValueIsFilled(Item.Value.Partner) Then
				Continue;
			EndIf;
			
			If Not AddPartnerToListFoundByFullTextSearch(PartnerList, Partner, Basis, ItemRef1) Then
				Return NStr("vi = 'Quá nhiều kết quả, hãy làm rõ yêu cầu.';
							|ru = 'Слишком много результатов, уточните запрос.';
							|en = 'Too many results. Please narrow your search.'; fa = 'Too many results. Please narrow your search.';
							|it = 'Troppi risultati, perfezionate la query.';
							|pl = 'Zbyt dużo wyników, uściślij zapytanie.';
							|tr = 'Çok fazla sonuç var; aramanızı daraltın.'");
			EndIf;
			
		EndDo;
		StartPosition = StartPosition + PortionSize;
		HasNextBatch = (StartPosition < ItemCount - 1);
		If HasNextBatch Then
			EndPosition = 
			?(ItemCount > StartPosition + PortionSize, PortionSize,
			ItemCount - StartPosition) - 1;
			SearchResultsList.NextPart();
		EndIf;
	EndDo;
	
	If PartnerList.Count() = 0 Then
		Return NStr("vi = 'Không tìm thấy gì.';
					|ru = 'Ничего не найдено.';
					|en = 'No results found.'; fa = 'No results found.';
					|it = 'Non è stato trovato nulla.';
					|pl = 'Nic nie znaleziono.';
					|tr = 'Bulunamadı.'");
	EndIf;

	Return Undefined;

EndFunction

Function AddPartnerToListFoundByFullTextSearch(PartnerList, Partner, Basis, ItemRef1)
	
	// add an item if the partner is not yet in the found list
	FoundRow = PartnerList.Find(Partner,"Partner"); 
	If FoundRow = Undefined Then
		// limit the number of returned partners
		If PartnerList.Count() > 100 Then
			Return False; 
		Else 
			Record = PartnerList.Add(); 
			Record.Partner = Partner;
			Record.Basis = Basis;
			Record["Ref"] = ItemRef1;
		EndIf;
		
	Else
		
		If (TypeOf(FoundRow["Ref"]) = Type("CatalogRef.ContactPersonsForPartners")
			Or TypeOf(FoundRow["Ref"]) = Type("CatalogRef.Counterparties")
			Or TypeOf(FoundRow["Ref"]) = Type("CatalogRef.CounterpartyContracts"))
			And TypeOf(ItemRef1) = Type("CatalogRef.Partners") Then
		
			FoundRow.Partner = Partner;
			FoundRow.Basis = Basis;
			FoundRow["Ref"] = ItemRef1;
		
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure AddToSelectionListFilterTypePartnerList(Form, ChoiceList)
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	If Form.ListFilterByPartnerType.Count() > 0 Then
		TextOfAdmissionSelection = "";
		
		For Each ListItem In Form.ListFilterByPartnerType Do
		
			TextOfAdmissionSelection = TextOfAdmissionSelection + "
			| OR SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Ref = &Set_Catalog_Partners_" 
			+ NameOfDataSet(ListItem.Value);
		
		EndDo;
		
	Else
		
		TextOfAdmissionSelection = "
		| OR SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Ref = &Set_Catalog_Partners_Competitors
		| OR SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Ref = &Set_Catalog_Partners_Customers
		| OR SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Ref = &Set_Catalog_Partners_Vendors
		| OR SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Ref = &Set_Catalog_Partners_OtherItems";
		
	EndIf;
	
	TextProperties = StrReplace(TextOfAdmissionSelection,
	                                 "SetsOfAdditionalDetailsAndDetailsAdditionalDetails",
	                                 "SetsOfAdditionalDetailsAndDetailsAdditionalInformation");
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Property,
	|	TRUE AS IsAttribute
	|INTO AddlAttributesAndInfo
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsOfAdditionalDetailsAndDetailsAdditionalDetails
	|WHERE
	|	SetsOfAdditionalDetailsAndDetailsAdditionalDetails.Ref = &Set_Catalog_Partners_Overall " + TextOfAdmissionSelection + "
	|
	|UNION ALL
	|
	|SELECT
	|	SetsOfAdditionalDetailsAndDetailsAdditionalInformation.Property,
	|	FALSE AS IsAttribute
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS SetsOfAdditionalDetailsAndDetailsAdditionalInformation
	|WHERE
	|	SetsOfAdditionalDetailsAndDetailsAdditionalInformation.Ref = &Set_Catalog_Partners_Overall " + TextProperties + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AdditionalAttributesAndInfo.Ref AS AddlAttributeInfo,
	|	AddlAttributesAndInfo.IsAttribute,
	|	AdditionalAttributesAndInfo.Presentation,
	|	AdditionalAttributesAndInfo.ValueType
	|FROM
	|	AddlAttributesAndInfo AS AddlAttributesAndInfo
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON AddlAttributesAndInfo.Property = AdditionalAttributesAndInfo.Ref";
	
	Query.SetParameter("Set_Catalog_Partners_Overall", PropertyManager.PropertiesSetByName("Catalog_Partners_Overall"));
	Query.SetParameter("Set_Catalog_Partners_OtherItems", PropertyManager.PropertiesSetByName("Catalog_Partners_OtherItems"));
	Query.SetParameter("Set_Catalog_Partners_Vendors", PropertyManager.PropertiesSetByName("Catalog_Partners_Vendors"));
	Query.SetParameter("Set_Catalog_Partners_Customers", PropertyManager.PropertiesSetByName("Catalog_Partners_Customers"));
	Query.SetParameter("Set_Catalog_Partners_Competitors", PropertyManager.PropertiesSetByName("Catalog_Partners_Competitors"));
	
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.ValueType = TypesDetailsBoolean Then
			NewRow = Form.AddlAttributesPropertiesTableOfBooleanType.Add();
			FillPropertyValues(NewRow,Selection);
		Else
			ChoiceList.Add(Selection.AddlAttributeInfo, Lower(Left(Selection.Presentation,1)) + Right(Selection.Presentation,StrLen(Selection.Presentation) - 1));
		EndIf;
		
	EndDo;
	
	If Form.AddlAttributesPropertiesTableOfBooleanType.Count() > 0 Then
		
		ChoiceList.Add("Categories", NStr("vi = 'thể loại';
											|ru = 'категориям';
											|en = 'categories'; fa = 'categories';
											|it = 'categorie';
											|pl = 'categories';
											|tr = 'kategorilere göre'"));
		
	EndIf;
	
EndProcedure

Function NameOfDataSet(FilterName)
	
	If FilterName = "Client" Then
		Return "Customers";
	ElsIf FilterName = "Vendor" Then
		Return "Vendors";
	ElsIf FilterName = "Competitor" Then
		Return "Competitors";
	Else
		Return "OtherItems";
	EndIf;
	
EndFunction

// Generates a string that contains all possible types of partner relationships separated by commas.
//
// Parameters:
//  PartnerData  - QueryResultSelection, Structure - contains data about the types of relationships with the partner.
//
// Returns:
//   String  - generated string information about the types of established relationships with a partner.
//
Function GenerateStringOfCurRelationshipTypes(PartnerData) Export

	StringRelationshipType = ?(PartnerData.Client, NStr("vi = 'Khách hàng';
														|ru = 'Клиент';
														|en = 'Customer'; fa = 'مشتری';
														|it = 'Cliente';
														|pl = 'Klient';
														|tr = 'İstemci'"),"") + ?(PartnerData.Vendor, NStr("vi = ', Nhà cung cấp';
																											|ru = ', Поставщик';
																											|en = ', Vendor'; fa = ', Vendor';
																											|it = ', Fornitore';
																											|pl = ', Dostawca';
																											|tr = ', Tedarikçi'"),"")
	                     + ?(PartnerData.Competitor, NStr("vi = ', Đối thủ cạnh tranh';
															|ru = ', Конкурент';
															|en = ', Competitor'; fa = ', Competitor';
															|it = ', Concorrente';
															|pl = ', Konkurent';
															|tr = ', Rakip'"),"") + ?(PartnerData.OtherRelations, NStr("vi = ', Quan hệ khác';
																															|ru = ', Прочие отношения';
																															|en = ', Other relations'; fa = ', Other relations';
																															|it = ', Altre relazioni';
																															|pl = ', Inne stosunki';
																															|tr = ', Diğer ilişkiler'"),"");
	If Left(StringRelationshipType, 2) = ", " Then
		StringRelationshipType = Right(StringRelationshipType,StrLen(StringRelationshipType) - 2);
	EndIf;
	
	Return StringRelationshipType;

EndFunction

// Gets the necessary data about the partner to display the list forms in the information panel 
// and select the "Partners"directory.
//
// Parameters:
//  Partner  - CatalogRef.Partners - the partner for which you need to get information.
//
// Returns:
//   Structure   - contains information about the partner.
//
Function PartnerDataForInformationPanel(Partner) Export
	
	PartnerData = New Structure;
	PartnerData.Insert("Description", "");
	PartnerData.Insert("BusinessRegion", "");
	PartnerData.Insert("ContactInformation", "");
	PartnerData.Insert("NumberOfContactPersons", 0);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Partners.Description AS Description,
	|	PRESENTATION(Partners.BusinessRegion) AS BusinessRegion
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TypesOfPresentationContactInformation.Description, ContactInformationKinds.Description) AS CIKind,
	|	ISNULL(PartnersContactInformation.Presentation, """") AS KiPresentation,
	|	CASE
	|		WHEN ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Address)
	|			THEN 1
	|		ELSE 0
	|	END AS OrderingValue,
	|	ContactInformationKinds.Ref AS LinkKiView
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
	|		ON (PartnersContactInformation.Kind = ContactInformationKinds.Ref)
	|			AND (PartnersContactInformation.Ref = &Partner)
	|		LEFT JOIN Catalog.ContactInformationKinds.Presentations AS TypesOfPresentationContactInformation
	|		ON (TypesOfPresentationContactInformation.Ref = ContactInformationKinds.Ref
	|				AND TypesOfPresentationContactInformation.LanguageCode = &LanguageCode)
	|WHERE
	|	ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogPartners)
	|	AND NOT ContactInformationKinds.DeletionMark
	|
	|ORDER BY
	|	OrderingValue,
	|	CIKind
	|TOTALS BY
	|	LinkKiView
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT ContactPersonsForPartners.Ref) AS NumberOfCL
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner = &Partner
	|	AND NOT ContactPersonsForPartners.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	
	Result = Query.ExecuteBatch();
	
	ResultPartnerData = Result[0]; // QueryResult - 
	SelectionPartnerData = ResultPartnerData.Select();
	If SelectionPartnerData.Next() Then
		FillPropertyValues(PartnerData, SelectionPartnerData);
	EndIf;
	
	ContactInformationTable_ = New ValueTable;
	ContactInformationTable_.Columns.Add("CIKind");
	ContactInformationTable_.Columns.Add("KiPresentation");
	
	QueryResultTypesOfCI = Result[1]; // QueryResult 
	SamplingTypesOfCI = QueryResultTypesOfCI.Select(QueryResultIteration.ByGroups);
	While SamplingTypesOfCI.Next() Do
		DetailsSelection = SamplingTypesOfCI.Select();
		KiPresentation = "";
		While DetailsSelection.Next() Do
			KiPresentation = KiPresentation + ?(IsBlankString(KiPresentation),"" ,"; ") + DetailsSelection.KiPresentation; 
		EndDo;
		NewRow = ContactInformationTable_.Add();
		NewRow.CIKind = DetailsSelection.CIKind;
		NewRow.KiPresentation = KiPresentation;
	EndDo;
	PartnerData.Insert("ContactInformationTable_",ContactInformationTable_);
	
	ResultOfContactPersonsRequest = Result[2]; // QueryResult 
	SampleNumberOfCells = ResultOfContactPersonsRequest.Select();
	If SampleNumberOfCells.Next() Then
		
		PartnerData.NumberOfContactPersons = SampleNumberOfCells.NumberOfCL;
		
	EndIf;

	PartnersAndCounterpartiesLocalization.AddPartnerDataForInformationPanel(PartnerData, Partner);
	
	Return PartnerData;
	
EndFunction

// Generates a selection list for selecting the filter type.
//
// Parameters:
//  Form        - ClientApplicationForm - the form for which the selection list is generated.
//  ChoiceList - ValueList   - generated selection list.
//
Procedure FillInSelectionListFilterTypePartnerList(Form, ChoiceList)
	
	If GetFunctionalOption("UseBusinessRegions") 
		And AccessRight("Read", Metadata.Catalogs.BusinessRegions) Then
		ChoiceList.Add("BusinessRegions", NStr("vi = 'khu vực kinh doanh';
												|ru = 'бизнес-региону';
												|en = 'business region'; fa = 'business region';
												|it = 'regione economica';
												|pl = 'business region';
												|tr = 'iş bölgesine'"));
	EndIf;
	
	If AccessRight("Read", Metadata.Catalogs.Users) Then
		ChoiceList.Add("Manager", NStr("vi = 'người quản lý chính';
										|ru = 'основному менеджеру';
										|en = 'employee in charge'; fa = 'کارمند مسئول';
										|it = 'direttore generale';
										|pl = 'głównemu menedżerowi';
										|tr = 'ana yöneticiye'"));
	EndIf;
	
	If GetFunctionalOption("UsePartnerAccessGroups")
		And AccessRight("Read", Metadata.Catalogs.PartnerAccessGroups) Then
		ChoiceList.Add("AccessGroups", NStr("vi = 'nhóm truy cập';
											|ru = 'группе доступа';
											|en = 'access group'; fa = 'access group';
											|it = 'gruppo di accesso';
											|pl = 'grupiе dostępu';
											|tr = 'erişim grubuna'"));
	EndIf;
	
	If GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		AddToSelectionListFilterTypePartnerList(Form, ChoiceList);
	EndIf;
	
EndProcedure

Procedure FillInContactInformationElement(Form, ContactInformationKind, StructureOfData) Export
	
	If StructureOfData = Undefined Then
		Return;
	EndIf;
	
	RowData = ContactInformationLineDataByType(Form, ContactInformationKind);
	If RowData = Undefined Then
		Return;
	EndIf;
	RowData.Presentation = StructureOfData.Presentation;
	RowData.Value = StructureOfData.ContactInformation;
	Form[RowData.AttributeName] = StructureOfData.Presentation;
	
EndProcedure

Function ContactInformationLineDataByType(Form, ContactInformationKind) Export
	
	Filter  = New Structure("Kind", ContactInformationKind);
	Rows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	Return ?(Rows.Count() = 0, Undefined, Rows[0]);
	
EndFunction

Procedure DeleteLineWithKIType(ContactInformation, CIKind)
	
	FoundRows = ContactInformation.FindRows(New Structure("Kind", CIKind));
	For Each FoundRow In FoundRows Do
		ContactInformation.Delete(FoundRow);
	EndDo;

EndProcedure

#EndRegion

#Region GeneralProceduresAndFunctionsOfListAndCatalogSelectionForms

Procedure FillCategoryTree(Form)
	
	Form.Categories.Clear();
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	BooleanProperties.AddlAttributeInfo AS Property,
	|	BooleanProperties.IsAttribute
	|INTO BooleanProperties
	|FROM
	|	&BooleanProperties AS BooleanProperties
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	PartnersAdditionalDetails.Property AS Value,
	|	PRESENTATION(PartnersAdditionalDetails.Property) AS Presentation
	|FROM
	|	Catalog.Partners.AdditionalAttributes AS PartnersAdditionalDetails
	|WHERE
	|	PartnersAdditionalDetails.Property IN
	|			(SELECT
	|				BooleanProperties.Property
	|			FROM
	|				BooleanProperties AS BooleanProperties
	|			WHERE
	|				BooleanProperties.IsAttribute)
	|
	|UNION
	|
	|SELECT
	|	AdditionalInfo.Property,
	|	PRESENTATION(AdditionalInfo.Property)
	|FROM
	|	InformationRegister.AdditionalInfo AS AdditionalInfo
	|WHERE
	|	AdditionalInfo.Property IN
	|			(SELECT
	|				BooleanProperties.Property
	|			FROM
	|				BooleanProperties AS BooleanProperties
	|			WHERE
	|				NOT BooleanProperties.IsAttribute)";
	
	Query.SetParameter("BooleanProperties", Form.AddlAttributesPropertiesTableOfBooleanType.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TableRow = Form.Categories.Add();
		FillPropertyValues(TableRow, Selection);
		TableRow.PictureNumber = 0;
		
	EndDo;
	
	AddLineToNavigationBar(Form.Categories,NStr("vi = 'Tất cả';
												|ru = 'Все';
												|en = 'All'; fa = 'همه';
												|it = 'Tutti';
												|pl = 'All';
												|tr = 'Tümü'"),1);
	
	Form.CurrentPropertyOfNavigationPanel = Form.FilterType_;
	
EndProcedure

Procedure CheckIfThereIsSelectionElement(FilterItems1, DataCompositionField, Var_ComparisonType, Result)
	
	For Each FilterElement In FilterItems1 Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			CheckIfThereIsSelectionElement(FilterElement.Items, DataCompositionField, Var_ComparisonType, Result)
			
		Else
			
			If FilterElement.LeftValue = DataCompositionField
				And FilterElement.ComparisonType = Var_ComparisonType Then
				Result = True;
				Break;
			EndIf;
			
		EndIf;
		
		If Result Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DetermineModeOfUsingSearchInList(Form)
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "UseAdvancedSearch") Then
	
		UseAdvancedSearchSettings = Common.CommonSettingsStorageLoad("UsingFullTextSearchInListOfPartners",
		                                                                                         "UserSettingsUsingPartners",
		                                                                                          Undefined);
		
		Form.UseAdvancedSearch = ?(UseAdvancedSearchSettings = Undefined, True, Form.UseAdvancedSearch);
		
		OnChangeFullTextSearchUsageMode(Form, False);
	
	EndIf;
	
EndProcedure

Procedure FillPropertiesTree(Form)
	
	Form.Properties.GetItems().Clear();
	
	Query = New Query;
	
	If Form.FilterType_.IsAdditionalInfo Then
		
		Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	AdditionalInfo.Value AS Value,
		|	PRESENTATION(AdditionalInfo.Value) AS Presentation
		|FROM
		|	InformationRegister.AdditionalInfo AS AdditionalInfo
		|WHERE
		|	AdditionalInfo.Property = &Property
		|	AND AdditionalInfo.Object REFS Catalog.Partners
		|
		|ORDER BY
		|	Value
		|TOTALS BY
		|	Value HIERARCHY";
		
	Else
	
		Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	PartnersAdditionalDetails.Value AS Value,
		|	PRESENTATION(PartnersAdditionalDetails.Value) AS Presentation
		|FROM
		|	Catalog.Partners.AdditionalAttributes AS PartnersAdditionalDetails
		|WHERE
		|	PartnersAdditionalDetails.Property = &Property
		|
		|ORDER BY
		|	Value
		|TOTALS BY
		|	Value HIERARCHY";
		
	EndIf;
	
	Query.SetParameter("Property",Form.FilterType_);
	
	Result = Query.Execute();
	Tree = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	AddLineToNavigationBar(Form.Properties,NStr("vi = 'Chưa chỉ ra';
												|ru = 'Не указан';
												|en = 'Not specified'; fa = 'مشخص نشده';
												|it = 'Non specificato';
												|pl = 'Nie określony';
												|tr = 'Belirtilmedi'"));
	
	RowsFirstLevel = Form.Properties.GetItems(); // ValueTreeRowCollection 
	
	For Each String In Tree.Rows Do
		PropertyRow = RowsFirstLevel.Add();
		FillPropertyValues(PropertyRow, String);
		PropertyRow.PictureNumber = 1;
		AddRowsToNavigationTree(String, PropertyRow,True);
	EndDo;
	
	AddLineToNavigationBar(Form.Properties,NStr("vi = 'Tất cả';
												|ru = 'Все';
												|en = 'All'; fa = 'همه';
												|it = 'Tutti';
												|pl = 'All';
												|tr = 'Tümü'"),2);

	Form.CurrentPropertyOfNavigationPanel = Form.FilterType_;
	
EndProcedure

Function AddLineToNavigationBar(FormDataCollection, RowName, PictureNumber = 0)
	
	If TypeOf(FormDataCollection) = Type("FormDataTree") Then
		NewRow = FormDataCollection.GetItems().Add();
	Else
		NewRow = FormDataCollection.Add();
	EndIf;
	
		NewRow.Value = RowName;
		NewRow.Presentation = RowName;
		NewRow.PictureNumber = PictureNumber;
	
	Return NewRow;
	
EndFunction

Procedure AddRowsToNavigationTree(ParentString, ParentRow, ExecuteCheck1 = False)
	
	For Each String In ParentString.Rows Do
		
		If String.Value = ParentString.Value Or String.Value = Undefined Then
			Continue;
		EndIf;
		
		TreeRows = ParentRow.GetItems(); // ValueTreeRowCollection - 
		
		NewRow = TreeRows.Add();
		FillPropertyValues(NewRow, String);
		NewRow.PictureNumber = 1;
		
		AddRowsToNavigationTree(String, NewRow);
		
	EndDo;
	
EndProcedure

Function ListOfSignificantNavigationBarValues(ListName)
	
	If ListName = "BusinessRegions" Then
		
		Query = New Query;
		Query.Text = "SELECT ALLOWED DISTINCT
		|	Partners.BusinessRegion AS Ref
		|FROM
		|	Catalog.Partners AS Partners";
		
	ElsIf ListName = "PartnerAccessGroups" Then
		
		Query = New Query;
		Query.Text = "SELECT ALLOWED DISTINCT
		|	Partners.AccessGroup AS Ref
		|FROM
		|	Catalog.Partners AS Partners";
		
	ElsIf ListName = "Managers" Then
		
		Query = New Query;
		Query.Text = "SELECT ALLOWED DISTINCT
		|	Partners.MainManager AS Ref
		|FROM
		|	Catalog.Partners AS Partners";
		
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function RequestTextForDynamicListOfPartners(RequestWithCounterpartyInformation)

	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		Query = New Query;
		Query.Text = "SELECT TOP 1
		|	COUNT(DISTINCT Counterparties.Ref) AS Ref,
		|	Counterparties.Partner AS Partner
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|
		|GROUP BY
		|	Counterparties.Partner
		|
		|HAVING
		|	COUNT(DISTINCT Counterparties.Ref) > 1";
		
		SetPrivilegedMode(True);
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			RequestWithCounterpartyInformation = True;
		EndIf;
		
	EndIf;
	
	If RequestWithCounterpartyInformation Then
		QueryText = PartnersAndCounterpartiesLocalization.RequestTextForPartnersDynamicListWithInformationOnCounterparty();
		If IsBlankString(QueryText) Then
			QueryText = "
			|SELECT
			|	CatalogPartners.Ref,
			|	CatalogPartners.DeletionMark,
			|	CatalogPartners.Predefined,
			|	CatalogPartners.Parent,
			|	CatalogPartners.Code,
			|	CatalogPartners.Description,
			|	CatalogPartners.BusinessRegion,
			|	CatalogPartners.AccessGroup,
			|	CatalogPartners.RegistrationDate,
			|	CatalogPartners.Client,
			|	CatalogPartners.Comment,
			|	CatalogPartners.Competitor,
			|	CatalogPartners.DescriptionFull,
			|	CatalogPartners.MainManager,
			|	CatalogPartners.Vendor,
			|	CatalogPartners.Carrier,
			|	CatalogPartners.OtherRelations,
			|	CatalogPartners.AdditionalAttributes.(
			|		Ref,
			|		LineNumber,
			|		Property,
			|		Value,
			|		TextString
			|	),
			|	CatalogPartners.ContactInformation.(
			|		Ref,
			|		LineNumber,
			|		Type,
			|		Kind,
			|		Presentation,
			|		FieldValues,
			|		Country,
			|		State,
			|		City,
			|		EMAddress,
			|		ServerDomainName,
			|		PhoneNumber,
			|		PhoneNumberWithoutCodes
			|	),
			|	ISNULL(Counterparties.Ref, VALUE(Catalog.Counterparties.EmptyRef)) AS Counterparty,
			|	ISNULL(Counterparties.LegalEntityIndividual, VALUE(Enum.LegalEntityIndividual.EmptyRef)) AS LegalEntityIndividual,
			|	CASE
			|		WHEN ISNULL(Counterparties.BranchOffice, FALSE)
			|			THEN Counterparties.MainCounterparty
			|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
			|	END AS MainCounterparty,
			|	CASE
			|		WHEN ISNULL(Counterparties.BranchOffice, FALSE)
			|			THEN &RepresentationOfASeparateDivision
			|		ELSE ISNULL(PRESENTATION(Counterparties.LegalEntityIndividual), """")
			|	END AS CounterpartyKind,
			|	ISNULL(Counterparties.BranchOffice, FALSE) AS BranchOffice
			|FROM
			|	Catalog.Partners AS CatalogPartners
			|		{INNER JOIN Catalog.Counterparties AS Counterparties
			|		ON (Counterparties.Partner = CatalogPartners.Ref)}
			|WHERE
			|	CASE
			|		WHEN &SelectionBySegmentIsSet <> TRUE
			|			THEN TRUE
			|		ELSE CatalogPartners.Ref IN (&FilterBySegment)
			|		END
			|	AND CASE
			|			WHEN NOT &FullTextSearchSelectionIsSet
			|				THEN TRUE
			|			ELSE CatalogPartners.Ref IN (&FullTextSearchSelection)
			|		END";
		EndIf;
		
		Return QueryText
	Else
		
		Return "
		|SELECT
		|	CatalogPartners.Ref,
		|	CatalogPartners.DeletionMark,
		|	CatalogPartners.Predefined,
		|	CatalogPartners.Parent,
		|	CatalogPartners.Code,
		|	CatalogPartners.Description,
		|	CatalogPartners.BusinessRegion,
		|	CatalogPartners.AccessGroup,
		|	CatalogPartners.RegistrationDate,
		|	CatalogPartners.Client,
		|	CatalogPartners.Comment,
		|	CatalogPartners.Competitor,
		|	CatalogPartners.DescriptionFull,
		|	CatalogPartners.MainManager,
		|	CatalogPartners.Vendor,
		|	CatalogPartners.Carrier,
		|	CatalogPartners.OtherRelations,
		|	CatalogPartners.ServedBySalesRepresentatives,
		|	CatalogPartners.AdditionalAttributes.(
		|		Ref AS Ref1,
		|		LineNumber,
		|		Property,
		|		Value
		|	),
		|	CatalogPartners.ContactInformation.(
		|		Ref AS Ref2,
		|		LineNumber AS LineNumber1,
		|		Type,
		|		Kind,
		|		Presentation,
		|		FieldValues,
		|		Country,
		|		State,
		|		City,
		|		EMAddress,
		|		ServerDomainName,
		|		PhoneNumber,
		|		PhoneNumberWithoutCodes
		|	)
		|FROM
		|	Catalog.Partners AS CatalogPartners
		|WHERE
		|	CASE
		|		WHEN &SelectionBySegmentIsSet <> TRUE
		|			THEN TRUE
		|		ELSE CatalogPartners.Ref IN (&FilterBySegment)
		|		END
		|	AND CASE
		|			WHEN NOT &FullTextSearchSelectionIsSet
		|				THEN TRUE
		|			ELSE CatalogPartners.Ref IN (&FullTextSearchSelection)
		|		END";
		
	EndIf;
	

EndFunction

// Hides form commands if you don't have edit rights
// 
// Parameters:
// 	Form - ClientApplicationForm - the form for which actions are performed.
//
Procedure HideCommandsIfYouDonTHaveEditRights(Form) Export

	EditRight = AccessRight("Update", Metadata.Catalogs.Partners);
	
	If Not EditRight Then
		
		ItemArray = New Array;
		ItemArray.Add("ListContextMenuMoveItem");
		ItemArray.Add("ListContextMenuLevelUp");
		ItemArray.Add("ListContextMenuLevelDown");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Visible", False);
		
	EndIf;
	
	If Not Form.SimplifiedInputAvailable Then
		
		ItemArray = New Array;
		ItemArray.Add("ListContextMenuCopy");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Visible", False);
		
	EndIf;

EndProcedure

Function HTMLTextFromHTMLDocumentObject(HTMLDocument)
	
	Try
		DOMWriter = New DOMWriter;
		HTMLWriter = New HTMLWriter;
		HTMLWriter.SetString();
		DOMWriter.Write(HTMLDocument,HTMLWriter);
		Return HTMLWriter.Close();
	Except
		Return "";
	EndTry;
	
EndFunction

#EndRegion

#Region ReportMailing

// See ReportMailingOverridable.OverrideRecipientsTypesTable.
Procedure WhenRedefiningTableOfTypesOfRecipientsOfMailingReports(TypesTable, AvailableTypes) Export
	
	If Common.SubsystemExists("StandardSubsystems.ReportMailing") Then
		
		// Parameters of the "Counterparties" directory.
		TypesSettings = New Structure;
		TypesSettings.Insert("CIGroup",          Catalogs.ContactInformationKinds.CatalogCounterparties);
		TypesSettings.Insert("MainCIKind",     Catalogs.ContactInformationKinds.EmailCounterparty_);
		TypesSettings.Insert("MainType",       Type("CatalogRef.Counterparties"));
		ModuleReportDistribution = Common.CommonModule("ReportMailing");
		ModuleReportDistribution.AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, TypesSettings);
		
		// Parameters of the Partners directory.
		TypesSettings = New Structure;
		TypesSettings.Insert("CIGroup",          Catalogs.ContactInformationKinds.CatalogPartners);
		TypesSettings.Insert("MainCIKind",     Catalogs.ContactInformationKinds.EmailPartner_);
		TypesSettings.Insert("MainType",       Type("CatalogRef.Partners"));
		ModuleReportDistribution = Common.CommonModule("ReportMailing");
		ModuleReportDistribution.AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, TypesSettings);

		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
