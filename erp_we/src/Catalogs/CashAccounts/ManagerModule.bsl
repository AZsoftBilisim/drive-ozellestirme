#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function determines the sales register of the selected organization.
//
// Returns the organization's sales register if a single sales register is found.
// Returns Undefined if the sales register is not found or there are more than one sales registers.
//
// Parameters:
//  Organization - CatalogRef.Companies - Link to the organization
//	Currency - CatalogRef.Currencies - Cash register currency.
//	LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//	Individual - CatalogRef.Persons - Physical person
//
// Returns:
//	CatalogRef.CashAccounts - The found cash register of the organization.
//
Function GetCheckoutByDefault(Organization, Currency = Undefined, LineOfBusiness = Undefined, Individual = Undefined) Export
	
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	CashAccounts.Ref AS CashAccount
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|WHERE
	|	NOT CashAccounts.DeletionMark
	|	AND (CashAccounts.Owner = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND (CashAccounts.CashCurrency = &Currency
	|		OR &Currency = UNDEFINED)
	|	AND CashAccounts.OperationalCashAccount 
	|	AND CashAccounts.Individual = &Individual
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 2
	|	CashAccounts.Ref AS CashAccount
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|WHERE
	|	NOT CashAccounts.DeletionMark
	|	AND (CashAccounts.Owner = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND (CashAccounts.CashCurrency = &Currency
	|		OR &Currency = UNDEFINED)
	|	AND (CashAccounts.LineOfBusiness = &LineOfBusiness
	|			OR &LineOfBusiness = UNDEFINED);
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 2
	|	CashAccounts.Ref AS CashAccount
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|WHERE
	|	NOT CashAccounts.DeletionMark
	|	AND (CashAccounts.Owner = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND (CashAccounts.CashCurrency = &Currency
	|		OR &Currency = UNDEFINED)
	|");
		
	Query.SetParameter("Organization", ?(ValueIsFilled(Organization), Organization, Undefined));
	Query.SetParameter("Currency", ?(ValueIsFilled(Currency), Currency, Undefined));
	Query.SetParameter("LineOfBusiness", ?(ValueIsFilled(LineOfBusiness), LineOfBusiness, Undefined));
	Query.SetParameter("Individual", ?(ValueIsFilled(Individual), Individual, Undefined));
	
	Result = Query.ExecuteBatch();
	SelectionByIndividual		= Result[0].Select();
	SamplingByDirection	= Result[1].Select();
	TotalSample			= Result[2].Select();

	If SelectionByIndividual.Count() = 1 And SelectionByIndividual.Next() Then
		CashAccount = SelectionByIndividual.CashAccount;
	ElsIf SamplingByDirection.Count() = 1 And SamplingByDirection.Next() Then
		CashAccount = SamplingByDirection.CashAccount;
	ElsIf TotalSample.Count() = 1 And TotalSample.Count() = 0 Then
		CashAccount = TotalSample.CashAccount;
	ElsIf ThisIsBasic And TotalSample.Count() = 0 Then
		CashAccount = CreatePredefinedSalesRegister();
	Else
		CashAccount = Catalogs.CashAccounts.EmptyRef();
	EndIf;
	
	Return CashAccount;

EndFunction

// This function determines the details of the selected sales register.
//
// Parameters:
//  CashAccount - CatalogRef.CashAccounts - The link to the cashier.
//
// Returns:
//	Structure - Attributes of the selected Cash account:
//		* Organization - CatalogRef.Companies - The company that owns the cash account.
//		* Currency - CatalogRef.Currencies - Currency of cash accounting.
//		* EnableCreatingCashIssueWithoutPaymentRequest - Boolean - indicates the possibility of spending cash without 
//		                                      the document "Application for spending money".
//
Function GetCheckoutDetails(CashAccount) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	CashAccounts.Owner AS Organization,
	|	CashAccounts.CashCurrency AS Currency,
	|	CashAccounts.EnableCreatingCashIssueWithoutPaymentRequest AS EnableCreatingCashIssueWithoutPaymentRequest,
	|	CashAccounts.Cashier AS Cashier
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|WHERE
	|	CashAccounts.Ref = &CashAccount
	|");
	
	Query.SetParameter("CashAccount", CashAccount);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Organization = Selection.Organization;
		Currency = Selection.Currency;
		EnableCreatingCashIssueWithoutPaymentRequest = Selection.EnableCreatingCashIssueWithoutPaymentRequest;
		Cashier = Selection.Cashier;
	Else
		Organization = Catalogs.Companies.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		EnableCreatingCashIssueWithoutPaymentRequest = False;
		Cashier = Catalogs.Persons.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure("Organization, Currency, EnableCreatingCashIssueWithoutPaymentRequest, Cashier",
		Organization,
		Currency,
		EnableCreatingCashIssueWithoutPaymentRequest,
		Cashier);
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf; 
	
	Return AttributesStructure1;

EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Owner");
	NotAttributesToEdit.Add("CashBook");
	NotAttributesToEdit.Add("ThisIsCashAccountOfBranchOffice");
	If GetFunctionalOption("BaseVersion") Then
		NotAttributesToEdit.Add("LineOfBusiness");
	EndIf;
	
	Return NotAttributesToEdit;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN Catalog.CashAccounts.RecipientOfCashTransfer AS T1 
	|	ON T1.PaymentBeneficiary = T.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T.Owner)
	|	AND( ValueAllowed(T.Ref)
	|	OR ValueAllowed(T1.Ref)
	|	) ";

EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the Attributes of the settings for the accounting accounts that affect the setting,
// 	corresponding to the names of the accounting analytics Attributes.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.CashCurrency = "CashCurrency";
	MatchingNames.CashAnalytics = "Ref";
	MatchingNames.Organization = "Owner";
	
EndProcedure
#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("SelectionOfParentCompanyCashRegisters") Then
		
		If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
			Return;
		EndIf;
		
		Organization = Undefined;
		Parameters.Filter.Property("Owner", Organization);
		
		If Not ValueIsFilled(Organization)
			Or Not GeneralPurposeTMServerCall.ObjectAttributeValue(Organization, "BranchOffice") Then
			Return;
		EndIf;
		
		ThereAreCustomersARAP = Parameters.Property("ThereAreCustomersARAP");
		ThereAreVendorsARAP = Parameters.Property("ThereAreVendorsARAP");
		
		StandardProcessing = False;
		Query = New Query("SELECT
		|	&Organization
		|INTO AvailableCompanies
		|
		|UNION ALL
		|
		|SELECT
		|	Companies.ParentCompany
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed
		|	AND (&ThereAreCustomersARAP OR &ThereAreVendorsARAP)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CashAccounts.Ref,
		|	CashAccounts.Description,
		|	CashAccounts.Owner
		|INTO Data
		|FROM
		|	AvailableCompanies AS AvailableCompanies
		|		INNER JOIN Catalog.CashAccounts AS CashAccounts
		|		ON AvailableCompanies.Organization = CashAccounts.Owner
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Data.Ref
		|FROM
		|	Data AS Data
		|WHERE
		|	&SearchCriteria_ AND &OtherConditions
		|
		|ORDER BY
		|	Data.Owner,
		|	Data.Description
		|AUTOORDER");
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("ThereAreCustomersARAP", ThereAreCustomersARAP);
		Query.SetParameter("ThereAreVendorsARAP", ThereAreVendorsARAP);
		
	EndIf;
	
	If Not StandardProcessing Then
		
		Query.Text = StrReplace(Query.Text, "&SearchCriteria_", "Data.Description LIKE &SearchString");
		Query.SetParameter("SearchString", ?(Parameters.SearchString = Undefined, "", Parameters.SearchString) + "%");
		
		OtherConditions = "";
		For Each Item In Parameters.Filter Do
			
			If Item.Key = "Owner" And Parameters.Property("SelectionOfParentCompanyCashRegisters") Then
				Continue;
			Else
				
				OtherConditions = OtherConditions + "Data.Ref." + Item.Key 
					+ ?(TypeOf(Item.Value) = Type("FixedArray"), " IN (&", " = (&") 
					+ Item.Key + ") AND ";
				Query.SetParameter(Item.Key, Item.Value);
				
			EndIf;
			
		EndDo;
		
		If OtherConditions = "" Then
			OtherConditions = "True";
		Else
			OtherConditions = Left(OtherConditions, StrLen(OtherConditions) - 3);
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&OtherConditions", OtherConditions);
		
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" And Not GetFunctionalOption("UseMultipleCashAccounts") Then
		Parameters.Insert("Key", GeneralPurposeTMServerCall.OrganizationSDefaultSalesRegister());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
	EndIf;
	
	CashAccountsLocalization.FormGetProcessing(
		FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Internal

#EndRegion

#Region Private

Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("CashCurrency");
	Result.Add("Owner");
	Result.Add("IndicatesACashBookOfBranchOffice; IndicatesACashBookOfBranchOffice1, IndicatesACashBookOfBranchOffice2, CashBook");
	Result.Add("FinancialAccountingGroup");
	Result.Add("Department");
	Result.Add("LineOfBusiness");
	Result.Add("SettingUpAccountingAccountsAccountingAccountCash");
	Return Result;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Creates a single cash register that is used by default
//
Function CreatePredefinedSalesRegister()
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	1
	|FROM
	|	Catalog.CashAccounts AS CashAccounts");
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		CatalogObject = CreateItem();
		DefaultCompany = Catalogs.Companies.DefaultCompany();
		If ValueIsFilled(DefaultCompany) Then
			CatalogObject.Owner = DefaultCompany;
			CatalogObject.Description = NStr("vi = 'Quỹ tiền mặt của Tập đoàn';
											|ru = 'Касса предприятия';
											|en = 'Enterprise cash account'; fa = 'Enterprise cash account';
											|it = 'Cassa aziendale';
											|pl = 'Kasa przedsiębiorstwa';
											|tr = 'İşletme kasası'");
			CatalogObject.CashCurrency = Constants.ManagementAccountingCurrency.Get();
			CatalogObject.Write();
		EndIf;
		
		Return CatalogObject.Ref;
	EndIf;
	
	Return Catalogs.CashAccounts.EmptyRef();
	
EndFunction

#EndRegion

#EndIf