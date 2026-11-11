
#Region Public

#Region GeneralProceduresAndFunctionsOfListAndCatalogSelectionForms

// When dragging in the list form, it updates the value of the props that were dragged to for the array
// of dragged partners.
//
// Parameters:
//  Value              - Arbitrary - the value to which the drag was performed.
//  ArrayOfPartners       - Array of CatalogRef.Partners - array of dragged partners.
//  WrittenItemsCount  - Number - number of registered partners.
//
Procedure UpdatePropsValueForDraggedPartners(Value, ArrayOfPartners, WrittenItemsCount) Export

	WrittenItemsCount = 0;
	ArrayOfGroupsAvailableForModification =
		AccessManagement.AccessValuesGroupsAllowingAccessValuesChange(Type("CatalogRef.Partners"), True);
	
	AttributeName = "";
	If TypeOf(Value) = Type("CatalogRef.BusinessRegions") Then
		AttributeName = "BusinessRegion";
	ElsIf TypeOf(Value) = Type("CatalogRef.PartnerAccessGroups") Then
		AttributeName = "AccessGroup";
		If ArrayOfGroupsAvailableForModification.Find(Value) = Undefined Then
			Return;
		EndIf;
	ElsIf TypeOf(Value) = Type("CatalogRef.Users") Then
		AttributeName = "MainManager";
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	Partners.Ref
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref IN(&ArrayOfPartners)
	|	AND Partners.AccessGroup IN (&ArrayOfGroupsAvailableForModification)
	|	AND &PropsNamePartners <> &Value";
	
	Query.SetParameter("ArrayOfPartners",ArrayOfPartners);
	Query.SetParameter("Value",Value);
	Query.SetParameter("ArrayOfGroupsAvailableForModification", ArrayOfGroupsAvailableForModification);
	
	Query.Text = StrReplace(Query.Text, "&PropsNamePartners", "Partners." + AttributeName);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		PartnerObject_ =  Selection.Ref.GetObject();
		PartnerObject_[AttributeName] = Value;
		PartnerObject_.Write();
		WrittenItemsCount = WrittenItemsCount + 1;
	
	EndDo;

EndProcedure

// Gets the primary Manager of the business in the region.
//
// Parameters:
//  BusinessRegion  - CatalogRef.BusinessRegions - business region for which the main Manager is obtained.
//
// Returns:
//   CatalogRef.Users   - the main manager of the business region.
//
Function MainManagerOfBusinessRegion(BusinessRegion) Export

	Return Common.ObjectAttributeValue(BusinessRegion,"MainManager");

EndFunction

// Gets an external user authorization object partner
//
// Returns:
//  CatalogRef.Partners - partner, if the authorization object is a partner, undefined in the opposite case.
//
Function GetAuthorizedPartner() Export
	
	SetPrivilegedMode(True);
	
	ExternalUser = ExternalUsers.CurrentExternalUser();
	If Not ValueIsFilled(ExternalUser) Then
		Return Undefined;
	EndIf;
	
	AuthorizationObject = Common.ObjectAttributeValue(ExternalUser, "AuthorizationObject");
	
	If TypeOf(AuthorizationObject) = Type("CatalogRef.Partners") Then
		Return AuthorizationObject;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Creates a view of the Partners directory depending on the settings for separate or shared use
// of partners and contractors.
//
// Returns:
//   String   - the generated representation of the Partners directory.
//
Function PresentationOfPartnersCatalog() Export
	
	Return ?(GetFunctionalOption("UsePartnersAsCounterparties"), NStr("vi = 'Đối tác';
																		|ru = 'Контрагенты';
																		|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
																		|it = 'Controparti';
																		|pl = 'Counterparties';
																		|tr = 'Cari hesaplar'"), NStr("vi = 'Bạn hàng';
																									|ru = 'Партнеры';
																									|en = 'Partners'; fa = 'شرکای تجاری';
																									|it = 'Partner';
																									|pl = 'Partners';
																									|tr = 'İş ortakları'"));
	
EndFunction

// Retrieves the data structure for an authorized external user
//
// Returns:
//  Structure - Contains:
//  * PartnerAuthorized - Boolean - True if the Partner is authorized, False if the contact person.
//  * Partner            - CatalogRef.Partners - information about the authorized partner.
//  * ContactPerson     - CatalogRef.ContactPersonsForPartners - information about the authorized contact person.
//
Function DataOfAuthorizedExternalUser() Export
	
	SetPrivilegedMode(True);
	
	ExternalUser = ExternalUsers.CurrentExternalUser();
	If Not ValueIsFilled(ExternalUser) Then
		Return Undefined;
	EndIf;
	
	PartnerAuthorized = True;
	Partner            = Catalogs.Partners.EmptyRef();
	ContactPerson     = Catalogs.ContactPersonsForPartners.EmptyRef();
	
	AuthorizationObject = Common.ObjectAttributeValue(ExternalUser, "AuthorizationObject");
	
	If TypeOf(AuthorizationObject) = Type("CatalogRef.Partners") Then
		Partner        = AuthorizationObject;
	ElsIf TypeOf(AuthorizationObject) = Type("CatalogRef.ContactPersonsForPartners") Then
		PartnerAuthorized = False;
		ContactPerson = AuthorizationObject;
		Partner        = Common.ObjectAttributeValue(AuthorizationObject, "Owner");
	Else
		Return Undefined;
	EndIf;
	
	StructureToReturn = New Structure;
	StructureToReturn.Insert("PartnerAuthorized", PartnerAuthorized);
	StructureToReturn.Insert("Partner", Partner);
	StructureToReturn.Insert("ContactPerson", ContactPerson);
	
	Return StructureToReturn;
	
EndFunction

// Gets data for opening the form
// 
// Parameters:
// 	Parameters - Structure - the structure parameters of open forms
//	
Procedure CounterpartyDataForOpeningPartnerForm(Parameters) Export
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	CounterpartyRef.Partner AS Partner,
	|	CounterpartyRef.TIN AS TIN,
	|	CounterpartyRef.Description AS Description
	|FROM
	|	Catalog.Counterparties AS CounterpartyRef
	|WHERE
	|	CounterpartyRef.Ref = &CounterpartyRef
	|";
	Query.SetParameter("CounterpartyRef", Parameters.Key);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Parameters.Insert("Key",         Selection.Partner);
		Parameters.Insert("TIN",          Selection.TIN);
		Parameters.Insert("Description", Selection.Description);
	EndIf;
EndProcedure

#EndRegion

#EndRegion

#Region Private


// Retrieves the values of contact information fields in XML format by representation
// 
// Parameters:
//  Presentation           - String
//  ContactInformationKind - CatalogRef.ContactInformationKinds - 
//  Comment              - String - Comment
// 
// Returns:
//  String - The values of the fields for contact information
Function ValuesOfContactInformationFields(Val Presentation, Val ContactInformationKind, Val Comment = Undefined) Export
	
	// Creating a new instance based on the view
	Result = ContactsManager.ContactsByPresentation(Presentation, ContactInformationKind);
	
	// We add a comment to it, if there is
	If Comment <> Undefined Then
		Comment = ContactsManager.ContactInformationComment(Result);
	EndIf;
	
	Return Result;
	
EndFunction 

// Defines the name of the counterparty creation form
// 
// Returns:
//  String - Name of the counterparty creation form
Function NameOfCounterpartyCreationForm() Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Return "Catalog.Partners.Form.WizardOfNew";
	Else
		Return "Catalog.Counterparties.Form.ItemForm";
	EndIf;
	
EndFunction

// Array of set selection parameters by partner type.
// 
// Parameters:
//  Parameters - Filter - 
// 
// Returns:
//  Array of String - An array of installed parameters selection of the type of partner
Function ArrayOfSetSelectionParametersByPartnerType(Parameters) Export
	
	ArrayOfInstalledSelections = New Array;
	If Parameters.Filter.Property("Client") Then
		ArrayOfInstalledSelections.Add("Client");
	EndIf;
	If Parameters.Filter.Property("Vendor") Then
		ArrayOfInstalledSelections.Add("Vendor");
	EndIf;
	If Parameters.Filter.Property("Carrier") Then
		ArrayOfInstalledSelections.Add("Carrier");
	EndIf;
	If Parameters.Filter.Property("Competitor") Then
		ArrayOfInstalledSelections.Add("Competitor");
	EndIf;
	If Parameters.Filter.Property("OtherRelations") Then
		ArrayOfInstalledSelections.Add("OtherRelations");
	EndIf;
	If Parameters.Filter.Property("ServedBySalesRepresentatives") Then
		ArrayOfInstalledSelections.Add("ServedBySalesRepresentatives");
	EndIf;
	If Parameters.Filter.Property("OurEnterprise") Then
		ArrayOfInstalledSelections.Add("OurEnterprise");
	EndIf;
	
	Return ArrayOfInstalledSelections;
	
EndFunction

// Generates a query text string based on an array of set selections by partner type
// 
// Parameters:
//  Parameters - Structure - Contains:
//    * SetSelectionByPartnerTypeAsOR - Boolean - 
//  ArrayOfInstalledSelections - Array of String - the names of the selection details by type of relationship with the partner.
// 
// Returns:
//  String - 
//
Function QuerySelectionStringByPartnerType(Parameters, ArrayOfInstalledSelections) Export
	
	SetSelectionByPartnerTypeAsOR = Parameters.Property("SetSelectionByPartnerTypeAsOR") 
	                                         And Parameters.SetSelectionByPartnerTypeAsOR;
	
	FIlterRow = "";
	NumberOfSelections = 0;
	
	For Each ArrayElement In ArrayOfInstalledSelections Do
		If ArrayElement = "OurEnterprise" Then
			Condition = "Partners.Ref = VALUE(Catalog.Partners.OurEnterprise)"; 
		Else
			Condition = "Partners." + ArrayElement; 
		EndIf;
		 
		If NumberOfSelections > 0 Then
			If SetSelectionByPartnerTypeAsOR Then
				FIlterRow = FIlterRow + " OR "; // @query-part
			Else
				FIlterRow = FIlterRow + " AND "; // @query-part
			EndIf;
		EndIf;
		
		FIlterRow = FIlterRow + Condition;
		NumberOfSelections = NumberOfSelections + 1;
		
	EndDo;
	
	Return ?(IsBlankString(FIlterRow),""," AND (" + FIlterRow + ")");
	
EndFunction

Procedure FillInPartnerSDefaultCounterparty(Val Partner, Counterparty, RefillingCounterparty) Export
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty, RefillingCounterparty);
	
EndProcedure

Procedure FillInPartnerCounterpartyDetails(Receiver, Partner, WithHistoricalData = True) Export
	
	PartnersAndCounterparties.FillInPartnerCounterpartyDetails(Receiver, Partner, WithHistoricalData);
	
EndProcedure

// Called to enable history maintenance for the contact information type.
// Parameters:
//  ContactInformationKindName - String - name of the contact information type.
//
Procedure EnableChangeHistoryStorage(ContactInformationKindName) Export
	
	PartnersAndCounterparties.EnableChangeHistoryStorage(ContactInformationKindName);
	
EndProcedure

// Receives the partner's only counterparty.
// 
// Parameters:
//  Partner - CatalogRef.Partners -
// 
// Returns:
//  CatalogRef.Counterparties - Partner's counterparty
Function PartnerSCounterparty(Partner) Export
	
	Return PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner);
	
EndFunction

#Region ChoiceData

// Returns the available types of transactions for the selection data when searching by row.
// 
// Parameters:
//  SearchString -  String - search bar.
// 
// Returns:
//  Undefined, ValueList - 
//
Function TypesOfSelectionDataTransactions(SearchString) Export

	If Not GetFunctionalOption("UseBusinessProcessesAndTasks") Then

		ChoiceData  = New ValueList;
		Query = New Query;
		Query.Text = "
		|SELECT
		|	CustomerOpportunityKinds.Ref
		|FROM
		|	Catalog.CustomerOpportunityKinds AS CustomerOpportunityKinds
		|WHERE
		|	CustomerOpportunityKinds.UsageIsAllowed
		|	AND CustomerOpportunityKinds.SalesOpportunityType IN(&AvailableTransactionTypes)
		|	AND CustomerOpportunityKinds.Description LIKE &SearchString ESCAPE ""~""";
		
		AvailableTransactionTypes = New Array;
		AvailableTransactionTypes.Add(Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities);
		AvailableTransactionTypes.Add(Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement);
		
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString)+"%");
		Query.SetParameter("AvailableTransactionTypes", AvailableTransactionTypes);
		
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
		Return ChoiceData;
		
	Else
		
		Return Undefined;
		
	EndIf;

EndFunction

// Retrieves data from the Contractors directory selection.
// 
// Parameters:
//  Parameters - Structure - Contains:
//   * Filter                         - Filter - 
//   * SelectionOfCounterpartiesAndOrganizations - Boolean - 
//   * SearchString                  - String - 
// 
// Returns:
//  ValueList - 
Function CounterpartiesSelectionData(Parameters) Export
	
 	ChoiceData = New ValueList;
	Partner = Undefined;
	
	If Parameters.Filter.Property("Partner") Then
		Partner = ?(ValueIsFilled(Parameters.Filter.Partner),Parameters.Filter.Partner,Undefined);
		Parameters.Filter.Delete("Partner");
	EndIf;
	
	LegalEntityIndividual = Undefined;
	
	If Parameters.Filter.Property("LegalEntityIndividual") Then
		LegalEntityIndividual = ?(ValueIsFilled(Parameters.Filter.LegalEntityIndividual),Parameters.Filter.LegalEntityIndividual,Undefined);
		Parameters.Filter.Delete("LegalEntityIndividual");
	EndIf;
	
	Query = New Query;
	
	ArrayOfInstalledSelections = PartnersAndCounterpartiesServerCall.ArrayOfSetSelectionParametersByPartnerType(Parameters);
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If ArrayOfInstalledSelections.Count() > 0 And UsePartnersAsCounterparties Then
		
		FIlterRow = PartnersAndCounterpartiesServerCall.QuerySelectionStringByPartnerType(Parameters, ArrayOfInstalledSelections);
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT TOP 51
		|	Counterparties.Ref                AS Ref,
		|	Counterparties.LegalEntityIndividual             AS LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref) AS Presentation,
		|	Partners.Description             AS PartnerName_,
		|	Counterparties.Description          AS Description,
		|	Counterparties.TIN                   AS TIN,
		|	&FoundByName            AS FoundBy,
		|	Counterparties.DeletionMark       AS DeletionMark
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON Counterparties.Partner = Partners.Ref
		|WHERE
		|	&SearchTerms
		|	AND Partners.Ref = &FilterCriterion
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|UNION ALL
		|
		|SELECT TOP 51
		|	Counterparties.Ref,
		|	Counterparties.LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref),
		|	Partner.Description,
		|	Counterparties.Description,
		|	Counterparties.TIN,
		|	&FoundByINN,
		|	Counterparties.DeletionMark
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON Counterparties.Partner = Partners.Ref
		|WHERE
		|	Counterparties.TIN LIKE &InputString ESCAPE ""~""
		|	AND Partners.Ref = &FilterCriterion
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|ORDER BY
		|	Counterparties.DeletionMark";
		
		Query.Text = StrReplace(Query.Text,"AND Partners.Ref = &FilterCriterion" , FIlterRow);
		
	ElsIf Parameters.Property("SelectionOfCounterpartiesAndOrganizations") And GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT TOP 41
		|	Counterparties.Ref                AS Ref,
		|	Counterparties.LegalEntityIndividual             AS LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref) AS Presentation,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Parent.Description
		|		ELSE Counterparties.Partner.Description
		|	END                            AS PartnerName_,
		|	Counterparties.Description,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Level
		|		ELSE -1
		|	END                           AS OutputOrder,
		|	Counterparties.TIN                 AS TIN,
		|	&FoundByName          AS FoundBy,
		|	Counterparties.DeletionMark     AS DeletionMark
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|		ON Counterparties.Partner = PartnerHierarchy.Parent
		|WHERE
		|	&SearchTerms
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|UNION ALL
		|
		|SELECT TOP 41
		|	Counterparties.Ref,
		|	Counterparties.LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref),
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Parent.Description
		|		ELSE Counterparties.Partner.Description
		|	END,
		|	Counterparties.Description,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Level
		|		ELSE -1
		|	END,
		|	Counterparties.TIN,
		|	&FoundByINN,
		|	Counterparties.DeletionMark
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|		ON Counterparties.Partner = PartnerHierarchy.Parent
		|WHERE
		|	Counterparties.TIN LIKE &InputString ESCAPE ""~""
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|UNION ALL
		|
		|SELECT TOP 10
		|	Counterparties.Ref,
		|	Counterparties.LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref),
		|	&OurEnterprise,
		|	Counterparties.Description,
		|	 -1,
		|	Counterparties.TIN,
		|	&FoundByName,
		|	Counterparties.DeletionMark
		|FROM
		|	Catalog.Companies AS Counterparties
		|WHERE
		|	&SearchTerms
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|UNION ALL
		|
		|SELECT TOP 10
		|	Counterparties.Ref,
		|	Counterparties.LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref),
		|	&OurEnterprise,
		|	Counterparties.Description,
		|	 -1,
		|	Counterparties.TIN,
		|	&FoundByINN,
		|	Counterparties.DeletionMark
		|FROM
		|	Catalog.Companies AS Counterparties
		|WHERE
		|	Counterparties.TIN LIKE &InputString ESCAPE ""~""
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|ORDER BY
		|	Counterparties.DeletionMark,
		|	OutputOrder DESC";
		
	Else
		
		Query.Text = "
		|SELECT ALLOWED DISTINCT TOP 51
		|	Counterparties.Ref                AS Ref,
		|	Counterparties.LegalEntityIndividual             AS LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref) AS Presentation,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Parent.Description
		|		ELSE Counterparties.Partner.Description
		|	END                            AS PartnerName_,
		|	Counterparties.Description         AS Description,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Level
		|		ELSE -1
		|	END                           AS OutputOrder,
		|	Counterparties.TIN                    AS TIN,
		|	&FoundByName          AS FoundBy,
		|	Counterparties.DeletionMark     AS DeletionMark
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|		ON Counterparties.Partner = PartnerHierarchy.Parent
		|WHERE
		|	&SearchTerms
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|UNION ALL
		|
		|SELECT TOP 51
		|	Counterparties.Ref,
		|	Counterparties.LegalEntityIndividual,
		|	PRESENTATION(Counterparties.Ref),
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Parent.Description
		|		ELSE Counterparties.Partner.Description
		|	END,
		|	Counterparties.Description,
		|	CASE
		|		WHEN PartnerHierarchy.Partner = &Partner
		|			THEN PartnerHierarchy.Level
		|		ELSE -1
		|	END,
		|	Counterparties.TIN,
		|	&FoundByINN,
		|	Counterparties.DeletionMark
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
		|		ON Counterparties.Partner = PartnerHierarchy.Parent
		|WHERE
		|	Counterparties.TIN LIKE &InputString ESCAPE ""~""
		|   AND &SelectionCriteriaLegalEntityIndividual
		|
		|ORDER BY
		|	Counterparties.DeletionMark,
		|	OutputOrder DESC";
		
	EndIf;
	
	SelectionCriteriaLegalEntityIndividual = "TRUE";
	If ValueIsFilled(LegalEntityIndividual) Then
		SelectionCriteriaLegalEntityIndividual = "Counterparties.LegalEntityIndividual IN (&LegalEntityIndividual)";
	EndIf;
	Query.Text = StrReplace(Query.Text,"&SelectionCriteriaLegalEntityIndividual" , SelectionCriteriaLegalEntityIndividual);
	
	SearchTerms = "Counterparties.Description LIKE &InputString ESCAPE ""~""";
	
	For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
		
		If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
			
			LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
			If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
				
				Continue;
				
			EndIf;
			
			AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
			SearchTerms = SearchTerms + "
			|	OR " + StringFunctionsClientServer.SubstituteParametersToString("Counterparties.%1 LIKE &InputString ESCAPE ""~""",
				AttributesNames["Description"]);
			
		EndIf;
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&SearchTerms", SearchTerms);
	
	SearchString = ?(Parameters.SearchString = Undefined, "", Parameters.SearchString);
	
	Query.SetParameter("InputString", Common.GenerateSearchQueryString(SearchString) + "%");
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("LegalEntityIndividual",             LegalEntityIndividual);
	Query.SetParameter("FoundByName", "ByDescription");
	Query.SetParameter("FoundByINN",          "ByInn");
	Query.SetParameter("OurEnterprise",       NStr("vi = 'Doanh nghiệp chúng ta';
													|ru = 'Наше предприятие';
													|en = 'Our enterprise'; fa = 'سازمان ما';
													|it = 'La nostra impresa';
													|pl = 'Nasze przedsiębiorstwo';
													|tr = 'İşletmemiz'"));
	
	Selection = Query.Execute().Select();
	
	INNToDisplayPrefixFor = TINForWhichPrefixJurIndividualIsRequiredToBeDisplayed(Selection);
	
	While Selection.Next() Do
		
		If ChoiceData.FindByValue(Selection.Ref) = Undefined Then
			
			If Selection.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
				And INNToDisplayPrefixFor.Find(Selection.TIN) <> Undefined Then
				
				PrefixLegalEntityIndividual = NStr("vi = '(CNKD)';
													|ru = '(ИП)';
													|en = '(IE)'; fa = '(IE)';
													|it = '(ИП)';
													|pl = '(IE)';
													|tr = '(ŞŞ)'") ;
				
			ElsIf Selection.LegalEntityIndividual = Enums.LegalEntityIndividual.Person 
				And INNToDisplayPrefixFor.Find(Selection.TIN) <> Undefined Then
				
				PrefixLegalEntityIndividual = NStr("vi = '(CN)';
													|ru = '(ФЛ)';
													|en = '(FL)'; fa = '(FL)';
													|it = '(ФЛ)';
													|pl = '(FL)';
													|tr = '(GK)'");
				
			Else
				
				PrefixLegalEntityIndividual = "";
				
			EndIf;
			
			If Selection.FoundBy = "ByDescription"  Then
				Presentation = PrefixLegalEntityIndividual  + " " + Selection.Description;
			Else
				Presentation =  Selection.TIN  + " " + PrefixLegalEntityIndividual + " (" +Selection.Description + ")";
			EndIf;
			
			If Not UsePartnersAsCounterparties Then
				Presentation = Presentation + " (" + Selection.PartnerName_ + ")";
			EndIf;
			
			If Selection.DeletionMark Then
				StructureValue = New Structure("Value,DeletionMark", Selection.Ref, Selection.DeletionMark);
				ChoiceData.Add(StructureValue,Presentation,,PictureLib.ItemMarkedForDeletion);
			Else
				ChoiceData.Add(Selection.Ref,Presentation);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ChoiceData;
	
EndFunction 

Function TINForWhichPrefixJurIndividualIsRequiredToBeDisplayed(Selection)
	
	CounterpartyData_ = New Array;
	
	VerifiedINN = New Array;
	
	While Selection.Next() Do
		
		If Not IsBlankString(Selection.TIN)
			And (Selection.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
				Or Selection.LegalEntityIndividual = Enums.LegalEntityIndividual.Person) Then
			
			VerifiedINN.Add(Selection.TIN); 
			
		EndIf;
		
	EndDo;
	
	Selection.Reset();
	
	If VerifiedINN.Count() > 0 Then
		
		SetPrivilegedMode(True);
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	COUNT(DISTINCT Counterparties.Ref) AS Ref,
		|	Counterparties.TIN                          AS TIN
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	Counterparties.TIN IN(&VerifiedINN)
		|	AND Counterparties.LegalEntityIndividual IN (VALUE(Enum.LegalEntityIndividual.Person), VALUE(Enum.LegalEntityIndividual.IndividualEntrepreneur))
		|
		|GROUP BY
		|	Counterparties.TIN
		| HAVING COUNT(DISTINCT Counterparties.Ref) > 1"; 
		
		Query.SetParameter("VerifiedINN", VerifiedINN);
		
		CounterpartyData_ = Query.Execute().Unload().UnloadColumn("TIN");
		
	EndIf;
		
	Return CounterpartyData_;
	
EndFunction

// Gets the Partners directory selection data.
// 
// Parameters:
//  Parameters - Structure - Contains:
//   * Filter                         - Filter - 
//   * SearchString                  - String - 
// 
// Returns:
//  ValueList - 
Function PartnersSelectionData(Parameters) Export

	ArrayOfInstalledSelections = PartnersAndCounterpartiesServerCall.ArrayOfSetSelectionParametersByPartnerType(Parameters);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If ArrayOfInstalledSelections.Count() > 0 Or UsePartnersAsCounterparties Then
		
		Query = New Query;
		
		FIlterRow = PartnersAndCounterpartiesServerCall.QuerySelectionStringByPartnerType(Parameters, ArrayOfInstalledSelections);
		
		If Parameters.Filter.Property("BusinessRegion") Then
			FIlterRow = " AND Partners.BusinessRegion = &BusinessRegion";
			Query.SetParameter("BusinessRegion", Parameters.Filter.BusinessRegion);
		EndIf;
		
		If Parameters.Filter.Property("LegalEntityIndividual") Then
			FIlterRow = FIlterRow + " AND (Partners.LegalEntityIndividual IN (&LegalEntityIndividual)) ";
			Query.SetParameter("LegalEntityIndividual", Parameters.Filter.LegalEntityIndividual);
		EndIf;
		
		If UsePartnersAsCounterparties Then
			FIlterRow = FIlterRow + " AND (NOT Partners.Ref = VALUE(Catalog.Partners.UnknownPartner)) ";
		EndIf;
		
		If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
			FIlterRow = FIlterRow + " AND (NOT Partners.Ref = VALUE(Catalog.Partners.OurEnterprise)) ";
		EndIf;
		
		Query.SetParameter(
			"InputString", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
		
		If UsePartnersAsCounterparties Then
			
			Query.Text = 
				"SELECT ALLOWED TOP 51
				|	Partners.Ref AS Partner,
				|	Partners.Description,
				|	Counterparties.LegalEntityIndividual AS LegalEntityIndividual, 
				|	PRESENTATION(Partners.Ref) AS Presentation,
				|	Partners.DeletionMark AS DeletionMark,
				|	Counterparties.TIN AS TIN,
				|	""FoundByName"" AS FoundBy
				|FROM
				|	Catalog.Counterparties AS Counterparties
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON Counterparties.Partner = Partners.Ref
				|WHERE
				|	&SearchTerms" + FIlterRow;
			
			SearchTemplate = "Counterparties.Description LIKE &InputString ESCAPE ""~""";
			
		Else
			
			Query.Text = 
				"SELECT ALLOWED TOP 51
				|	Partners.Ref AS Partner,
				|	Partners.Description,
				|	VALUE(Enum.LegalEntityIndividual.EmptyRef) AS LegalEntityIndividual, 
				|	PRESENTATION(Partners.Ref) AS Presentation,
				|	Partners.DeletionMark AS DeletionMark,
				|	"""" AS TIN,
				|	""FoundByName"" AS FoundBy
				|FROM
				|	Catalog.Partners AS Partners
				|WHERE
				|	&SearchTerms" + FIlterRow;
			
			SearchTemplate = "Partners.Description LIKE &InputString ESCAPE ""~""";
			
		EndIf;
		
		Query.Text = Query.Text + "	
		|
		|UNION ALL
		|
		|SELECT TOP 51
		|	Partners.Ref,
		|	Partners.Description,
		|	Counterparties.LegalEntityIndividual ,
		|	PRESENTATION(Partners.Ref),
		|	Partners.DeletionMark,
		|	Counterparties.TIN AS TIN,
		|	""FoundByINN""
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON Counterparties.Partner = Partners.Ref
		|WHERE
		|	Counterparties.TIN LIKE &InputString ESCAPE ""~""" + FIlterRow;
		
		Query.Text = Query.Text + "	
		| ORDER BY 
    	|Partners.Description";
		
		SearchTerms = SearchTemplate;
		
		For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
			
			If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
				
				LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
				If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
					
					Continue;
					
				EndIf;
				
				AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
				SearchTerms = SearchTerms + "
				|	OR " + StrReplace(SearchTemplate, "Description", AttributesNames["Description"]);
				
			EndIf;
			
		EndDo;
		
		SearchTerms = StrTemplate("(%1)", SearchTerms);
		
		Query.Text = StrReplace(Query.Text, "&SearchTerms", SearchTerms);
		
		Selection = Query.Execute().Select();
		ChoiceData = New ValueList; 
		
		INNToDisplayPrefixFor = TINForWhichPrefixJurIndividualIsRequiredToBeDisplayed(Selection);
		
		While Selection.Next() Do
			
			PrefixLegalEntityIndividual = "";
			
			If UsePartnersAsCounterparties Then
			
				If Selection.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
					And INNToDisplayPrefixFor.Find(Selection.TIN) <> Undefined Then
					
					PrefixLegalEntityIndividual = NStr("vi = '(CNKD)';
														|ru = '(ИП)';
														|en = '(IE)'; fa = '(IE)';
														|it = '(ИП)';
														|pl = '(IE)';
														|tr = '(ŞŞ)'") ;
					
				ElsIf Selection.LegalEntityIndividual = Enums.LegalEntityIndividual.Person 
					And INNToDisplayPrefixFor.Find(Selection.TIN) <> Undefined Then
					
					PrefixLegalEntityIndividual = NStr("vi = '(CN)';
														|ru = '(ФЛ)';
														|en = '(FL)'; fa = '(FL)';
														|it = '(ФЛ)';
														|pl = '(FL)';
														|tr = '(GK)'");
					
				EndIf;
				
			Else
				
				If ChoiceData.FindByValue(Selection.Partner) <> Undefined Then
					Continue;
				EndIf;
			
			EndIf;
			
			If Selection.FoundBy = "FoundByName"  Then
				TextPresentation = PrefixLegalEntityIndividual  + " " + Selection.Presentation;
			Else
				TextPresentation =  Selection.TIN  + " " + PrefixLegalEntityIndividual + " (" +Selection.Presentation + ")";
			EndIf;
			
			If Selection.DeletionMark Then
				StructureValue = New Structure("Value,DeletionMark", Selection.Partner, Selection.DeletionMark);
				ChoiceData.Add(StructureValue,TextPresentation,, PictureLib.ItemMarkedForDeletion);
			Else
				ChoiceData.Add(Selection.Partner, TextPresentation);
			EndIf;
		EndDo;
		
		Return ChoiceData;
	
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

// Retrieves the selection data of the directory "Roles of contact persons in transactions and projects".
// 
// Parameters:
//  Parameters - Structure - Contains:
//   * Filter                         - Filter - 
//   * SearchString                  - String - 
// 
// Returns:
//  ValueList - 
Function RolesOfPartnersInTransactionsAndProjectsDataOfChoice(Parameters) Export
	
	If Parameters.Property("Client") Then

		ChoiceData = New ValueList;
		
		If Parameters.Client = Parameters.Member Then
			
			ChoiceData = New ValueList;
			Role = Catalogs.PartnerRolesInSalesOpportunitiesAndProjects.Client;
			ChoiceData.Add(Role, NStr("vi = 'Tên gọi';
										|ru = 'Наименование';
										|en = 'Name'; fa = 'نام';
										|it = 'Наименование';
										|pl = 'Name';
										|tr = 'Tanım'"));
			
		Else
			
			Query = New Query(
				"SELECT ALLOWED
				|	PartnerRolesInSalesOpportunitiesAndProjects.Ref,
				|	PartnerRolesInSalesOpportunitiesAndProjects.Description
				|FROM
				|	Catalog.PartnerRolesInSalesOpportunitiesAndProjects AS PartnerRolesInSalesOpportunitiesAndProjects
				|WHERE
				|	PartnerRolesInSalesOpportunitiesAndProjects.Ref <> VALUE(Catalog.PartnerRolesInSalesOpportunitiesAndProjects.Client)");
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				While Selection.Next() Do
					ChoiceData.Add(Selection.Ref, Selection.Description);
				EndDo;
				
			EndIf;
			
		EndIf;
		
		Return ChoiceData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
