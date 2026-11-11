#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region ManagementCompany
	Item = Items.Add();
	Item.PredefinedDataName = "ManagementCompany";
	Item.Description = NStr("vi = 'Doanh nghiệp quản trị';
							|ru = 'Управленческая организация';
							|en = 'Management company'; fa = 'شرکت مدیریت';
							|it = 'Azienda amministrativa';
							|pl = 'Firma zarządzająca';
							|tr = 'Yönetim iş yeri'", Common.DefaultLanguageCode());
	Item.Prefix = NStr("vi = 'QT';
						|ru = 'УУ';
						|en = 'MA'; fa = 'مدیریت';
						|it = 'Contabilità Gestionale';
						|pl = 'MA';
						|tr = 'Yönetim Muhasebesi'");
	Item.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
	Item.LocalAccountingCurrency = SystemSettingsLocalization.CurrencyOfRegulatedAccountingByDefault();
	Item.RegistrationCountry = SystemSettingsLocalization.MainDefaultCountry();
	Item.Status = Enums.BusinessUnitCompanyStatuses.Valid;
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.Companies - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	Object.ParentCompany = Object.Ref;
	
EndProcedure


#Region SeparateBusinessUnits

// Checks whether the organization is interconnected by organizational structure.
// If the first and second organizations are the same, they are considered to belong to the same parent organization.
//
// Parameters:
//	FirstOrganization - CatalogRef.Companies - auditee.
//	SecondOrganization - CatalogRef.Companies - the organization with which you are comparing.
//
// Returns:
//	Boolean - a sign of interconnectedness. If the first organization is a separate subdivision,
//		or if the second organization is a separate subdivision of the first,
//		or if both organizations are separate subdivisions of the same parent organization.
//		Otherwise, False is returned.
//
Function OrganizationsAreInterconnectedByOrganizationalStructure(FirstOrganization, SecondOrganization) Export
	
	If Not (ValueIsFilled(FirstOrganization) And ValueIsFilled(SecondOrganization))
	 Or FirstOrganization = SecondOrganization Then
		Return False;
	EndIf;
	
	ArrayOfInterconnectedOrganizations = ArrayOfInterconnectedOrganizations(FirstOrganization);
	
	Return (ArrayOfInterconnectedOrganizations.Find(SecondOrganization) <> Undefined);
	
EndFunction

// Checks whether the organization is related to other organizations by organizational structure.
//
// Parameters:
//	Organization - CatalogRef.Companies - auditee.
//
// Returns:
//	Boolean - a sign of interconnectedness. If the organization is interconnected with others,
//		the Truth is returned, otherwise False.
//
Function OrganizationIsInterconnectedWithOtherOrganizations(Organization) Export
	
	ArrayOfInterconnectedOrganizations = ArrayOfInterconnectedOrganizations(Organization);
	OrganizationIsInterconnectedWithOtherOrganizations = (ArrayOfInterconnectedOrganizations.Count() <> 0);
	
	Return OrganizationIsInterconnectedWithOtherOrganizations;
	
EndFunction

// Formation of Query Text for TT interconnected organizations
//
// Returns:
//	String - Query text
//
Function QueryTextInterconnectedOrganizations() Export
	
	Return "SELECT ALLOWED
	|	Companies.ParentCompany AS Ref,
	|	NULL AS ParentCompany
	|INTO InterconnectedOrganizations
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.BranchOffice
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|
	|GROUP BY
	|	Companies.ParentCompany
	|
	|UNION ALL
	|
	|SELECT
	|	Companies.Ref,
	|	Companies.ParentCompany
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.BranchOffice
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
EndFunction

// Generates a table of all possible relationships between companies within the same legal entity:
//  - Parent company - Branch Office
//  - Branch Office - Parent Company
//  - Parent company - Parent Company
//  - Branch Office - Branch Office.
//
// Parameters:
//  TempTableManager - TempTablesManager - Optional. If specified, the result will be placed in it.
//                                         Otherwise, the result is returned as an assignment table.
//
// Returns:
//  - Undefined - If the incoming parameter of the manager of the Time tables is filled in, it will be returned Undefined,
//    otherwise the table of values.
//  - ValueTable:
//      * Organization1 -  CatalogRef.Companies
//      * Organization2 -  CatalogRef.Companies
//
Function GetRelatedCompanies(TempTableManager = Undefined) Export
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextInterconnectedOrganizations());
	QueryText = "
	|SELECT
	|	InterconnectedOrganizations.ParentCompany				AS Organization1,
	|	CASE
	|		WHEN InterconnectedOrganizations.Ref IS NULL
	|		OR InterconnectedOrganizations.Ref = VALUE(Catalog.Companies.EmptyRef)
	|			THEN InterconnectedOrganizations.ParentCompany
	|		ELSE InterconnectedOrganizations.Ref
	|	END														AS Organization2
	|INTO TTInterconnectedCompanies
	|FROM
	|	InterconnectedOrganizations AS InterconnectedOrganizations
	|WHERE
	|	NOT (InterconnectedOrganizations.ParentCompany IS NULL
	|		OR InterconnectedOrganizations.ParentCompany = VALUE(Catalog.Companies.EmptyRef))
	|
	|UNION
	|
	|SELECT
	|	InterconnectedOrganizations.Ref							AS Organization1,
	|	CASE
	|		WHEN InterconnectedOrganizations.ParentCompany IS NULL
	|		OR InterconnectedOrganizations.ParentCompany = VALUE(Catalog.Companies.EmptyRef)
	|			THEN InterconnectedOrganizations.Ref
	|		ELSE InterconnectedOrganizations.ParentCompany
	|	END														AS Organization2
	|FROM
	|	InterconnectedOrganizations AS InterconnectedOrganizations
	|WHERE
	|	NOT (InterconnectedOrganizations.Ref IS NULL
	|		OR InterconnectedOrganizations.Ref = VALUE(Catalog.Companies.EmptyRef))
	|
	|UNION
	|
	|SELECT
	|	SeparateBusinessUnits1.Ref AS Organization1,
	|	SeparateBusinessUnits2.Ref AS Organization2
	|FROM
	|	Catalog.Companies AS SeparateBusinessUnits1
	|		INNER JOIN Catalog.Companies AS SeparateBusinessUnits2
	|		ON (SeparateBusinessUnits1.ParentCompany = SeparateBusinessUnits2.ParentCompany)
	|			AND (SeparateBusinessUnits1.Ref <> SeparateBusinessUnits2.Ref)
	|WHERE
	|	SeparateBusinessUnits1.BranchOffice
	|	AND SeparateBusinessUnits1.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|	AND SeparateBusinessUnits2.BranchOffice
	|	AND SeparateBusinessUnits2.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Result = Undefined;
	
	If TempTableManager = Undefined Then
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		Query.Text = StrReplace(QueryText, "INTO TTInterconnectedCompanies", "");
		Result = Query.Execute().Unload();
	Else
		QueryTexts.Add("DROP InterconnectedOrganizations");
		Query.TempTablesManager = TempTableManager;
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		Query.Execute();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an array of organizations that are interconnected by organizational structure.
//
// Parameters:
//	Organization - CatalogRef.Companies - the organization to search for relationships for,
//		if not specified, all related organizations are returned.
//
// Returns:
//	Array of CatalogRef.Companies - an array of interconnected organizations.
//
Function ArrayOfInterconnectedOrganizations(Organization = Undefined) Export
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextInterconnectedOrganizations());
	QueryTexts.Add("
	|SELECT
	|	InterconnectedOrganizations.Ref
	|FROM
	|	InterconnectedOrganizations AS InterconnectedOrganizations
	|WHERE
	|	InterconnectedOrganizations.Ref <> &Organization
	|	AND (&Organization = VALUE(Catalog.Companies.EmptyRef)
	|			OR InterconnectedOrganizations.Ref = &ParentCompany
	|			OR InterconnectedOrganizations.ParentCompany = &ParentCompany
	|				AND &ParentCompany <> VALUE(Catalog.Companies.EmptyRef)
	|			OR InterconnectedOrganizations.ParentCompany = &Organization)
	|");
	
	Query = New Query(StrConcat(QueryTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("Organization", ?(ValueIsFilled(Organization), Organization, Catalogs.Companies.EmptyRef()));
	Query.SetParameter("ParentCompany", ?(ValueIsFilled(Organization),
		Common.ObjectAttributeValue(Organization, "ParentCompany"), Catalogs.Companies.EmptyRef()));
		
	CompanyArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return CompanyArray;
	
EndFunction

// Returns an array of branches of the organization that are allowed to conduct mutual settlements through the parent organization.
//
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which you need to find branches,
//		if not specified, then all branches that allow mutual settlements through the parent organization are returned.
//
// Returns:
//	Array of CatalogRef.Companies - an array of interconnected organizations.
//
Function BranchesWithPaymentsThroughParentOrganization(Organization = Undefined) Export
	
	If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		Return New Array;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND (Companies.Ref <> &Organization
	|				AND Companies.ParentCompany = &Organization
	|			OR &Organization = UNDEFINED
	|			OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|	AND Companies.TransactionsUsingParentCompanyAreAllowed
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|AUTOORDER");
	Query.SetParameter("Organization", Organization);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns an array of parent organizations for the specified organizations.
//
// Parameters:
//	CompanyArray - Array - the organization to get the parent organizations for.
//
// Returns:
//	Array of CatalogRef.Companies - array of parent organizations.
//
Function ParentOrganizations(CompanyArray) Export
	
	Query = New Query;
	Query.SetParameter("CompanyArray", CompanyArray);
	
	Query.Text =
	"SELECT DISTINCT
	|	Companies.ParentCompany AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref IN(&CompanyArray)
	|
	|ORDER BY
	|	Ref";
	
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

// Determines whether the organization has separate divisions (allocated to a separate balance sheet).
//
// Parameters:
//  Organization - CatalogRef.Companies
// 
// Returns:
//  Boolean - True, if the information database keeps records
//           of separate divisions of the organization allocated to a separate balance sheet
//
Function CompanyHasBranchOffices(Organization) Export
	
	Return CompaniesLocalization.CompanyHasBranchOffices(Organization);
	
EndFunction

#EndRegion

#Region UsingMultipleOrganizations

// Returns the default organization.
// If there is only one organization in the IB that is not marked for deletion and is not predefined,
// a link to it will be returned, otherwise an empty link will be returned.
//
// Returns:
//     CatalogRef.Companies - link to the organization.
//
Function DefaultCompany() Export
	
	Organization = Catalogs.Companies.EmptyRef();
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 2
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND NOT Companies.Predefined
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		Organization = Selection.Organization;
	EndIf;
	
	Return Organization;

EndFunction

// Returns the number of items in the Business directory.
// Does not take into account predefined and marked for deletion elements.
//
// Returns:
//     Number - number of organizations.
//
Function NumberOfOrganizations() Export
	
	SetPrivilegedMode(True);
	
	Count = 0;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.Predefined
	|	AND NOT Companies.DeletionMark
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Count = Selection.Count;
	EndIf;
		
	Return Count;
	
EndFunction

// Returns whether multiple organizations are used.
//
// Returns:
//		Boolean
//
Function MultipleOrganizationsAreUsed() Export
	
	Return GetFunctionalOption("UseMultipleCompanies");
	
EndFunction

// Returns an array of available organizations.
//
// Parameters:
//	OnlyAllowed - Boolean - determines whether it is necessary to get all of the IB organization, or only available to the current user.
//	ConsiderThoseMarkedForDeletion - Boolean - determines whether to get organizations marked for deletion.
//
// Returns:
//	Array - array of organizations
//
Function AvailableCompanies(OnlyAllowed = False, ConsiderThoseMarkedForDeletion = True) Export
	
	Query = New Query;
	Query.Text =
	"SELECT //%1
	|	CatalogData.Ref AS Organization
	|FROM
	|	Catalog.Companies AS CatalogData
	|WHERE
	|	(CatalogData.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|		OR &UseManagementCompany)
	|	AND (NOT CatalogData.DeletionMark 
	|		OR &ConsiderThoseMarkedForDeletion)
	|	AND CatalogData.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|
	|ORDER BY
	|	Organization";
	
	Query.SetParameter("ConsiderThoseMarkedForDeletion", ConsiderThoseMarkedForDeletion);
	Query.SetParameter("UseManagementCompany",
		GetFunctionalOption("UseManagementCompany"));
	
	If OnlyAllowed Then
		Query.Text = StrReplace(Query.Text, "//%1", "ALLOWED");
	Else
		SetPrivilegedMode(True);
	EndIf;
	
	CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
	
	Return CompanyArray;
	
EndFunction

#EndRegion

#Region OtherItems

// Returns the names of blocked details for the BSP details blocking mechanism.
//
//	Returns:
//		Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("LocalAccountingCurrency");
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		Result.Add("BranchOffice");
		Result.Add("ParentCompany");
	EndIf;
	
	Return Result;

EndFunction

// This function determines the values of the details of the selected organization.
//
// Parameters:
//  Organization - CatalogRef.Companies - link to the organization.
//
// Returns:
//	Structure - details of the selected organization.
//
Function GetBusinessDetails(Organization) Export
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Description", "");
	AttributesStructure1.Insert("AbbreviatedDescription", "");
	AttributesStructure1.Insert("DescriptionFull", "");
	AttributesStructure1.Insert("LegalEntityIndividual",  Enums.LegalEntityIndividual.EmptyRef());
	AttributesStructure1.Insert("IndividualEntrepreneur", "");
	AttributesStructure1.Insert("TIN", "");
	AttributesStructure1.Insert("CRTR", "");
	AttributesStructure1.Insert("MajorTaxpayerKPP", "");
	AttributesStructure1.Insert("RegistrationCountry", Catalogs.WorldCountries.EmptyRef());
	AttributesStructure1.Insert("DescriptionInternational", "");
	CompaniesLocalization.AddBusinessDetailsToList(AttributesStructure1);
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	Companies.Ref AS Ref,
	|	&SelectionFields1
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref = &Organization";
	
	Query.SetParameter("Organization", Organization);
	
	ParameterSelectionFields = New Array;
	For Each Attribute In AttributesStructure1 Do
		ParameterSelectionFields.Add(StrTemplate("Companies.%1 AS %1", Attribute.Key));
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(ParameterSelectionFields, "," + Chars.LF));
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
		Description = ?(Not IsBlankString(Selection.AbbreviatedDescription), Selection.AbbreviatedDescription, Selection.Description);
		AttributesStructure1.Description = Description;
	Else
		Description = "";
	EndIf;
	AttributesStructure1.Insert("CertificateOfOwnership", "");
	AttributesStructure1.Insert("Presentation", Description);
	CompaniesLocalization.AddCompanyDetails(Organization, AttributesStructure1, Selection);
	Return AttributesStructure1;

EndFunction

// Gets an organization if there is only one organization in the directory.
// If the management organization is disabled in the settings, it is not taken into account.
//
// Returns:
//	CatalogRef.Companies - Found organization
// 	Referenceslink.Organizations.Empty link - if there are no organizations or more than one organization.
//
Function GetDefaultOrganization() Export
	
	QueryText = "
	|SELECT ALLOWED TOP 2
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
	If Not Constants.UseManagementCompany.Get() Then
		QueryText = QueryText + "
			|	AND NOT Companies.Predefined";
	EndIf;
		
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		Organization = Selection.Organization;
	Else
		Organization = Catalogs.Companies.EmptyRef();
	EndIf;
	
	Return Organization;

EndFunction

// Returns a classifier table from A Template with predefined elements. It is used for classifiers (OKVED,
// OKOPF, etc.) Templates are stored in the Templates of THIS Catalog (see the general form "Code Selection Form").
//	Parameters:
//		NameOfTemplate - String - name of the layout that stores data with predefined classifier elements.
//		CurrentPeriod - Date - it is not used in this method, but it may be mandatory if you refer to other classifiers from the General form.
//	Returns:
//		Structure - a parameter structure with the following properties:
//			* ListOfCodes - ValueTable - classifier table with columns:
//				** Code - String - string representation of the classifier element code.
//				** Description - String - name of the classifier element.
//
Function GetSelectionFormParametersForCode(NameOfTemplate, CurrentPeriod) Export
	Return CompaniesLocalization.GetSelectionFormParametersForCode(NameOfTemplate, CurrentPeriod);
EndFunction

// Forms a match between the case name and the form elements associated with the case.
// 
// Parameters:
// Returns:
// 	Map - Compliance with form elements
Function ComplianceOfFormElementsWithTaxAccountingPolicyParameters() Export
	
	MatchingElements = New Map();
	
	ItemArray = New Array();
	ItemArray.Add("GroupAccountingPolicyOfFinancialAccountingIndent");
	ItemArray.Add("IndentAccountingPolicyOfFinancialAccounting");
	ItemArray.Add("DescriptionOfTheAccountingPolicyOfFinancialAccounting");
	ItemArray.Add("FinancialAccountingPolicyGroup");
	ItemArray.Add("OpenTheAccountingPolicyOfFinancialAccounting");
	
	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfTheAccountingPolicyOfFinancialAccounting");
	MatchingElements.Insert("FinancialAccountingPolicy", StructureOfElements);
	
	ItemArray = New Array();
	ItemArray.Add("GroupSettingsAccountingNdsatcom");
	ItemArray.Add("OffsetOfVATAccountingSettings");
	ItemArray.Add("VATAccountingSettingsGroup");
	ItemArray.Add("DescriptionOfSettingUpVATAccounting");
	ItemArray.Add("OpenVATAccountingSettings");

	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfSettingUpVATAccounting");
	
	MatchingElements.Insert("VATAccountingSettings", StructureOfElements);
	
	CompaniesLocalization.SupplementComplianceOfFormElementsWithTaxAccountingPolicyParameters(MatchingElements);
	
	Return MatchingElements
EndFunction

//Checks the currency of regulated accounting between organizations for differences:
//
// Parameters:
// 	Organization1 - CatalogRef - link to the organization.
// 	Organization2 - CatalogRef - link to the organization.
//
// Returns:
// 	Structure - Contains Properties:
// 		* CurrenciesDoNotMatch - Boolean - 
// 		* CountriesMatch - Boolean -
Function CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization1, Organization2) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("CurrenciesDoNotMatch", True);
	ReturnStructure.Insert("CountriesMatch", True);
	
	If Not ValueIsFilled(Organization1) Or Not ValueIsFilled(Organization2) Then
		Return ReturnStructure;
	EndIf;
	
	ReferencesArrray = New Array();
	ReferencesArrray.Add(Organization1);
	ReferencesArrray.Add(Organization2);
	DetailsOfOrganizations = Common.ObjectsAttributesValues(ReferencesArrray, "LocalAccountingCurrency, RegistrationCountry");
	
	ReturnStructure.CurrenciesDoNotMatch = DetailsOfOrganizations.Get(Organization1).LocalAccountingCurrency = DetailsOfOrganizations.Get(Organization2).LocalAccountingCurrency;
	ReturnStructure.CountriesMatch = DetailsOfOrganizations.Get(Organization1).RegistrationCountry = DetailsOfOrganizations.Get(Organization2).RegistrationCountry;
	
	Return ReturnStructure;
	
EndFunction

// Returns the name of the organization as of the specified date.
//
// Parameters:
//     Organization - CatalogRef.Companies - Organization
//     DateOfLastEdit - Date - The date on which you need to get the names
//
// Returns:
//     Structure - Properties:
//     * AbbreviatedDescription - String
//     * FullDescr - String
//     * DescriptionInternational - String
//
Function NamesAsOfDate(Organization, DateOfLastEdit) Export
	
	OrganizationNames = New Structure();
	OrganizationNames.Insert("AbbreviatedDescription", "");
	OrganizationNames.Insert("DescriptionFull", "");
	OrganizationNames.Insert("DescriptionInternational", "");
	
	If Not ValueIsFilled(Organization)
		Or TypeOf(Organization) <> Type("CatalogRef.Companies") Then
		Return OrganizationNames;
	EndIf;
	
	If ValueIsFilled(DateOfLastEdit) Then
		Query = New Query();
		Query.Parameters.Insert("Organization", Organization);
		Query.Parameters.Insert("DateOfLastEdit", DateOfLastEdit);
		Query.Text =
		"SELECT
		|	MAX(HistoryOfNamesOfOrganizations.Period) AS Period,
		|	HistoryOfNamesOfOrganizations.Ref AS Ref
		|INTO ValuesOfNames
		|FROM
		|	Catalog.Companies.NameHistory AS HistoryOfNamesOfOrganizations
		|WHERE
		|	HistoryOfNamesOfOrganizations.Ref = &Organization
		|	AND HistoryOfNamesOfOrganizations.Period <= &DateOfLastEdit
		|
		|GROUP BY
		|	HistoryOfNamesOfOrganizations.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HistoryOfNamesOfOrganizations.AbbreviatedDescription AS AbbreviatedDescription,
		|	HistoryOfNamesOfOrganizations.DescriptionFull AS DescriptionFull,
		|	HistoryOfNamesOfOrganizations.DescriptionInternational AS DescriptionInternational
		|FROM
		|	ValuesOfNames AS ValuesOfNames
		|		INNER JOIN Catalog.Companies.NameHistory AS HistoryOfNamesOfOrganizations
		|		ON ValuesOfNames.Ref = HistoryOfNamesOfOrganizations.Ref
		|			AND ValuesOfNames.Period = HistoryOfNamesOfOrganizations.Period";
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			OrganizationNames.AbbreviatedDescription = Selection.AbbreviatedDescription;
			OrganizationNames.DescriptionFull = Selection.DescriptionFull;
			OrganizationNames.DescriptionInternational = Selection.DescriptionInternational;
			Return OrganizationNames;
		EndIf;
	EndIf;
	
	AttributesValues = Common.ObjectAttributesValues(Organization, "AbbreviatedDescription, DescriptionFull, DescriptionInternational");
	OrganizationNames.AbbreviatedDescription = AttributesValues.AbbreviatedDescription;
	OrganizationNames.DescriptionFull = AttributesValues.DescriptionFull;
	OrganizationNames.DescriptionInternational = AttributesValues.DescriptionInternational;
	
	Return OrganizationNames;
	
EndFunction

// Returns the organization's primary bank account.
//
// Parameters:
//  Organization - CatalogRef.Companies - link to the organization.
//
// Returns:
//  CatalogRef.CompaniesBankAccounts
//
Function GetPrimaryBankAccount(Organization) Export
	
	Return Common.ObjectAttributeValue(Organization, "MainBankAccount");
	
EndFunction

// Sets the main bank account of the organization.
//
// Parameters:
//  Organization - CatalogRef.Companies - link to the organization.
//  MainBankAccount - CatalogRef.CompaniesBankAccounts - link to the bank account.
//
Procedure SetUpPrimaryBankAccount(Organization, MainBankAccount) Export
	
	OrganizationObject = Organization.GetObject();
	Try
		OrganizationObject.Lock();
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = ErrorProcessing.ErrorDescriptionForUser(ErrorInfo);
		Raise ExceptionText;
	EndTry;
	
	OrganizationObject.MainBankAccount = MainBankAccount;
	OrganizationObject.Write();
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	CompaniesLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement


// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	CompaniesServerCall.OrganizationsProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);	
	
EndProcedure

#EndIf

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	CompaniesServerCall.OrganizationsProcessingFormReceipt(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region BatchEditObjects

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array - a list of the names of the object's details.
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	
	Result.Add("Prefix");
	Result.Add("ContactInformation.*");
	
	Return Result
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PrintAssistantFaxPrintingJob") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"PrintAssistantFaxPrintingJob", 
			NStr("vi = 'Làm thế nào để tạo dấu chữ ký và in?';
				|ru = 'Как создать факсимильную подпись и печать?';
				|en = 'How to create facsimile signature and stamp?'; fa = 'How to create facsimile signature and stamp?';
				|it = 'Come creare una firma e un timbro facsimile?';
				|pl = 'Jak utworzyć podpis i pieczęć faksymilową?';
				|tr = 'Faks imzası ve kaşesi nasıl oluşturulur?'"), 
			CreateFacsimilePrintingAssistant(ObjectsArray[0], PrintObjects));
		
		EndIf;
		
EndProcedure

Function CreateFacsimilePrintingAssistant(Organization, PrintObjects)
	
	SpreadsheetDocument	= New SpreadsheetDocument;
	Template				= PrintManagement.PrintFormTemplate("Catalog.Companies.FacsimileStampWizard");
	
	ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Organization);
	
	// Output signatures
	Area = Template.GetArea("FieldsToFillIn_");
	BasementDataStructure = New Structure;
	BasementDataStructure.Insert("ManagerSFullName_", PersonsTM.IndividualShortName(ResponsiblePersons.Director));
	BasementDataStructure.Insert("AccountantSFullName", PersonsTM.IndividualShortName(ResponsiblePersons.ChiefAccountant));
	Area.Parameters.Fill(BasementDataStructure);
	SpreadsheetDocument.Put(Area);

	SpreadsheetDocument.Put(Template.GetArea("Line"));
	PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, 1, PrintObjects, Organization);
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

#EndRegion

#Region InfobaseUpdate

// Called when switching to BSP version 2.2.1.12
//
Procedure FillInUseMultipleOrganizationsConstant() Export
	
	If GetFunctionalOption("UseMultipleCompanies") =
			GetFunctionalOption("NotUseMultipleCompanies") Then
		// The options should have opposite values.
		// If this is not the case, then it means that these options did not exist in the IB before - we initialize their values.
		Constants.UseMultipleCompanies.Set(NumberOfOrganizations() > 1);
	EndIf;
	
EndProcedure

// Returns data on the countries of registration of organizations according to the logic of the update handler to process the data for the transition to the New version().
// Takes into account all elements.
//
// Returns:
//     QueryResultSelection, Undefined - data on the countries of registration of organizations.
//
Function DataOfCountriesOfRegistrationOfOrganizations() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Companies.Ref AS Ref,
	|	Companies.ForeignCompanyOffice AS ForeignCompanyOffice,
	|	Companies.RegistrationCountryOfForeignCompany AS RegistrationCountryOfForeignCompany,
	|	CASE
	|		WHEN Companies.RegistrationCountry <> VALUE(Catalog.WorldCountries.EmptyRef)
	|			THEN Companies.RegistrationCountry
	|		WHEN NOT Companies.ForeignCompanyOffice
	|		AND Companies.RegistrationCountryOfForeignCompany <> VALUE(Catalog.WorldCountries.EmptyRef)
	|			THEN Companies.RegistrationCountryOfForeignCompany
	|		ELSE VALUE(Catalog.WorldCountries.EmptyRef)
	|	END AS RegistrationCountry
	|INTO VT_CountriesOfBusinessRegistrations
	|FROM
	|	Catalog.Companies AS Companies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	VT_CountriesOfBusinessRegistrations.RegistrationCountry AS RegistrationCountry,
	|	COUNT(VT_CountriesOfBusinessRegistrations.RegistrationCountry) AS NumberOfCountriesOfRegistration
	|FROM
	|	VT_CountriesOfBusinessRegistrations AS VT_CountriesOfBusinessRegistrations
	|WHERE
	|	VT_CountriesOfBusinessRegistrations.RegistrationCountry <> VALUE(Catalog.WorldCountries.EmptyRef)
	|GROUP BY
	|	VT_CountriesOfBusinessRegistrations.RegistrationCountry
	|
	|ORDER BY
	|	NumberOfCountriesOfRegistration DESC";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		Return Selection;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.Companies.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("86c8d6c4-9ff8-42a8-b31d-1db8918515ba");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.Companies.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Doanh nghiệp"":';
								|ru = 'Обновление справочника ""Организации"":';
								|en = 'Update the ""Companies"" catalog:'; fa = 'Update the ""Companies"" catalog:';
								|it = 'Update the ""Companies"" catalog:';
								|pl = 'Update the ""Companies"" catalog:';
								|tr = '""İş yerleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.Companies.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.Companies.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.Companies.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.Description = """"
	|	AND Companies.DescriptionLanguage1 = """"
	|
	|UNION
	|
	|SELECT
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.Description = """"
	|	AND Companies.DescriptionLanguage2 = """"";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Doanh nghiệp"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Организации"" по обработчику:';
								|en = 'Cannot process the ""Companies"" catalog by the handler:'; fa = 'Cannot process the ""Companies"" catalog by the handler:';
								|it = 'Cannot process the ""Companies"" catalog by the handler:';
								|pl = 'Cannot process the ""Companies"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""İş yerleri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	Companies.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON TT.Ref = Companies.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
					
					CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
					
				EndIf;
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
					
					CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure


#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
