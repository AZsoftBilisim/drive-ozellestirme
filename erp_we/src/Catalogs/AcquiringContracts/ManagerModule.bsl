#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function determines the Attributes of the selected Contract for connecting to the payment system.
//
// Parameters:
//  Contract - CatalogRef.AcquiringContracts - Link to the Contract for connecting to the payment system.
//
// Returns:
//  Structure - Attributes of the Contract for connecting to the payment system:
//   * Organization - CatalogRef.Companies
//   * BankAccount - CatalogRef.CompaniesBankAccounts
//   * Currency - CatalogRef.Currencies
//   * Acquirer - CatalogRef.Counterparties
//   * Partner - CatalogRef.Partners
//   * CounterpartyBankAccount - CatalogRef.CounterpartyBankAccounts
//   * MakingPaymentMethod - EnumRef.MakingPaymentMethods
//   * POSTerminalsAreUsed - Boolean
//   * DetailedTransactionReconciliation - Boolean
//   * CommissionPostingMethod - EnumRef.MethodsOfAcquiringCommissionRecording
//   * FixedFeeRate - Boolean
//   * CommissionRate - Number
//   * FeeIsChargedOnRefund - Boolean
//   * EnableCreatingCashIssueWithoutPaymentRequest - Boolean
//   * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems
//   * DimensionOfExpenses - Characteristic.ExpenseItems
//   * ExpensesBusinessUnit - CatalogRef.BusinessStructure
//   * LineOfBusiness - CatalogRef.LinesOfBusiness
//   * CashFlowItemCashReceipt - CatalogRef.CashFlowReportItems
//   * CashFlowItemReturn - CatalogRef.CashFlowReportItems
//   * CashFlowItemCommission - CatalogRef.CashFlowReportItems
//   * KeepRecordsOfCommissionInARAPAccounting - Boolean
//   * CommissionARAPObject - CatalogRef.ARAPObjects
//
Function ContractDetails_(Contract) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CatalogData.Organization                                    AS Organization,
	|	CatalogData.BankAccount                                 AS BankAccount,
	|	CatalogData.BankAccount.CashCurrency           AS Currency,
	|	CatalogData.Counterparty                                     AS Acquirer,
	|	CatalogData.Partner                                        AS Partner,
	|	CatalogData.CounterpartyBankAccount                      AS CounterpartyBankAccount,
	|	CatalogData.MakingPaymentMethod                        AS MakingPaymentMethod,
	|	CatalogData.POSTerminalsAreUsed             AS POSTerminalsAreUsed,
	|	CatalogData.DetailedTransactionReconciliation                      AS DetailedTransactionReconciliation,
	|	CatalogData.CommissionPostingMethod                        AS CommissionPostingMethod,
	|	CatalogData.FixedFeeRate                    AS FixedFeeRate,
	|	CatalogData.CommissionRate                                 AS CommissionRate,
	|	CatalogData.FeeIsChargedOnRefund                   AS FeeIsChargedOnRefund,
	|	CatalogData.EnableCreatingCashIssueWithoutPaymentRequest              AS EnableCreatingCashIssueWithoutPaymentRequest,
	|	CatalogData.ExpenseItem                                 AS ExpenseItem,
	|	CatalogData.DimensionOfExpenses                              AS DimensionOfExpenses,
	|	CatalogData.ExpensesBusinessUnit                          AS ExpensesBusinessUnit,
	|	CatalogData.LineOfBusiness                        AS LineOfBusiness,
	|	CatalogData.CashFlowItemCashReceipt AS CashFlowItemCashReceipt,
	|	CatalogData.CashFlowItemReturn           AS CashFlowItemReturn,
	|	CatalogData.CashFlowItemCommission          AS CashFlowItemCommission,
	|	CatalogData.KeepRecordsOfCommissionInARAPAccounting              AS KeepRecordsOfCommissionInARAPAccounting,
	|	CatalogData.CommissionARAPObject                         AS CommissionARAPObject
	|FROM
	|	Catalog.AcquiringContracts AS CatalogData
	|WHERE
	|	CatalogData.Ref = &Contract
	|";
	
	Query.SetParameter("Contract", Contract);
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Organization", Catalogs.Companies.EmptyRef());
	AttributesStructure1.Insert("BankAccount", Catalogs.CompaniesBankAccounts.EmptyRef());
	AttributesStructure1.Insert("Currency", Catalogs.Currencies.EmptyRef());
	AttributesStructure1.Insert("Acquirer", Catalogs.Counterparties.EmptyRef());
	AttributesStructure1.Insert("Partner", Catalogs.Partners.EmptyRef());
	AttributesStructure1.Insert("CounterpartyBankAccount", Catalogs.CounterpartyBankAccounts.EmptyRef());
	AttributesStructure1.Insert("MakingPaymentMethod", Enums.MakingPaymentMethods.EmptyRef());
	AttributesStructure1.Insert("POSTerminalsAreUsed", False);
	AttributesStructure1.Insert("DetailedTransactionReconciliation", False);
	AttributesStructure1.Insert("CommissionPostingMethod", Enums.MethodsOfAcquiringCommissionRecording.EmptyRef());
	AttributesStructure1.Insert("FixedFeeRate", False);
	AttributesStructure1.Insert("CommissionRate", 0);
	AttributesStructure1.Insert("FeeIsChargedOnRefund", False);
	AttributesStructure1.Insert("EnableCreatingCashIssueWithoutPaymentRequest", False);
	AttributesStructure1.Insert("ExpenseItem", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	AttributesStructure1.Insert("DimensionOfExpenses");
	AttributesStructure1.Insert("ExpensesBusinessUnit", Catalogs.Companies.EmptyRef());
	AttributesStructure1.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	AttributesStructure1.Insert("CashFlowItemCashReceipt",
		Catalogs.CashFlowReportItems.EmptyRef());
	AttributesStructure1.Insert("CashFlowItemReturn", Catalogs.CashFlowReportItems.EmptyRef());
	AttributesStructure1.Insert("CashFlowItemCommission", Catalogs.CashFlowReportItems.EmptyRef());
	AttributesStructure1.Insert("KeepRecordsOfCommissionInARAPAccounting", False);
	AttributesStructure1.Insert("CommissionARAPObject", Catalogs.ARAPObjects.EmptyRef());
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

// Deprecated. The function defines the Contract for connecting to the payment system for the selected organization.
//
// Returns the Contract if a single Contract is found.
// Returns an empty reference, otherwise.
//
// Parameters:
//    Organization - CatalogRef.Companies - The selected organization.
//    Acquirer - CatalogRef.Counterparties - The selected contractor.
//    Currency - CatalogRef.Currencies - Chosen currency.
//    MakingPaymentMethod - EnumRef.MakingPaymentMethods - selection by payment system.
//
// Returns:
//    CatalogRef.AcquiringContracts - The found contract.
//
Function DefaultContract(
			Organization, Acquirer, Currency = Undefined, MakingPaymentMethod = Undefined) Export
	
	Filter = ParametersOfAcquisitionContractSelection();
	
	Filter.Organization = Organization;
	Filter.Acquirer = Acquirer;
	Filter.Currency = Currency;
	Filter.MakingPaymentMethod = MakingPaymentMethod;
	
	Result = ContractOfAcquiringByDefault(Filter);
	
	Return Result;
	
EndFunction

// Returns the Contract for connecting to the payment system for the specified selection.
//
// Parameters:
//  FilterParameters - See ParametersOfAcquisitionContractSelection.
// 
// Returns:
//  CatalogRef.AcquiringContracts - acquiring Contract.
//
Function ContractOfAcquiringByDefault(FilterParameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED TOP 2
	|	CatalogData.Ref AS Ref
	|FROM
	|	Catalog.AcquiringContracts AS CatalogData
	|WHERE
	|	NOT CatalogData.DeletionMark
	|	AND CatalogData.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND (CatalogData.Organization = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND (CatalogData.Counterparty = &Acquirer
	|		OR &Acquirer = UNDEFINED)
	|	AND (CatalogData.BankAccount.CashCurrency = &Currency
	|		OR &Currency = UNDEFINED
	|		OR CatalogData.BankAccount.CashCurrency IS NULL)
	|	AND (CatalogData.MakingPaymentMethod = &MakingPaymentMethod
	|		OR &MakingPaymentMethod = UNDEFINED)
	|	AND (CatalogData.BankAccount = &BankAccount
	|		OR &BankAccount = UNDEFINED)
	|";
	
	Query.SetParameter("Organization", FilterParameters.Organization);
	Query.SetParameter("Acquirer", FilterParameters.Acquirer);
	Query.SetParameter("Currency", FilterParameters.Currency);
	Query.SetParameter("MakingPaymentMethod", FilterParameters.MakingPaymentMethod);
	Query.SetParameter("BankAccount", FilterParameters.BankAccount);
	
	Selection = Query.Execute().Select();
	If Selection.Count()=1 And Selection.Next() Then
		Result = Selection.Ref;
	Else
		Result = Catalogs.AcquiringContracts.EmptyRef();
	EndIf;
	
	Return Result;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//  Array - a list of the names of the object's details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Partner");
	Result.Add("Counterparty");
	Result.Add("Organization");
	Result.Add("Department");
	Result.Add("BankAccount");
	Result.Add("LineOfBusiness");
	
	Return Result;
	
EndFunction

// Adds a command to create the "leasing Agreements"directory.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	CatalogMetadata = Metadata.Catalogs.AcquiringContracts;
	
	If AccessRight("Insert", CatalogMetadata) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = CatalogMetadata.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(CatalogMetadata);
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.BankReportOnAcquiringTransactions.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	
	// Basis
	Item = Settings.Add();
	Item.Fields.Add("CommissionRate");
	Finances.NewFilter(Item.Condition, "FixedFeeRate", True);
	Item.Properties.Insert("Enabled");
	
	// FeeIsChargedOnRefund
	Item = Settings.Add();
	Item.Fields.Add("FeeIsChargedOnRefund");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "CommissionPostingMethod", Enums.MethodsOfAcquiringCommissionRecording.OnCashReceiving);
	Finances.NewFilter(OrGroup, "CommissionPostingMethod", Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("FeeIsChargedOnRefund");
	Finances.NewFilter(Item.Condition, "More.EditRight", True);
	Item.Properties.Insert("Visible");
	
	// TheInscriptionOfAcquiringTerminals
	Item = Settings.Add();
	Item.Fields.Add("TheInscriptionOfAcquiringTerminals");
	Finances.NewFilter(Item.Condition, "MakingPaymentMethod", Enums.MakingPaymentMethods.POSTerminal);
	Item.Properties.Insert("Visible");

	// InscriptionSettingUpPaymentSystemConnection
	Item = Settings.Add();
	Item.Fields.Add("InscriptionSettingUpPaymentSystemConnection");
	Finances.NewFilter(Item.Condition, "MakingPaymentMethod", Enums.MakingPaymentMethods.InstantPayments);
	Item.Properties.Insert("Visible");
	
	// FiscalReceiptsAreGeneratedByPaymentSystem
	Item = Settings.Add();
	Item.Fields.Add("FiscalReceiptsAreGeneratedByPaymentSystem");
	Finances.NewFilter(Item.Condition, "MakingPaymentMethod", Enums.MakingPaymentMethods.InternetAcquiring);
	Finances.NewFilter(Item.Condition, "More.EditRight", True);
	Item.Properties.Insert("Visible");
	
	// PaymentInOnlineStore
	Item = Settings.Add();
	Item.Fields.Add("PaymentInOnlineStore");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "MakingPaymentMethod", Enums.MakingPaymentMethods.InternetAcquiring);
	Finances.NewFilter(OrGroup, "MakingPaymentMethod", Enums.MakingPaymentMethods.InstantPayments);
	Item.Properties.Insert("Visible");
	
	// OnlineStoreAddress
	Item = Settings.Add();
	Item.Fields.Add("OnlineStoreAddress");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "MakingPaymentMethod", Enums.MakingPaymentMethods.InternetAcquiring);
	Finances.NewFilter(OrGroup, "MakingPaymentMethod", Enums.MakingPaymentMethods.InstantPayments);
	Item.Properties.Insert("Visible");
	
	// Subdivision of expenditures
	// Directions of activity
	// Expenditure articles
	// Spending Analytics
	Item = Settings.Add();
	Item.Fields.Add("ExpensesBusinessUnit");
	Item.Fields.Add("LineOfBusiness");
	Item.Fields.Add("ExpenseItem");
	Item.Fields.Add("DimensionOfExpenses");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", False);
	Item.Properties.Insert("Visible");
	
	// CommissionAgreement
	Item = Settings.Add();
	Item.Fields.Add("CommissionAgreement");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", True);
	Item.Properties.Insert("Visible");
	
EndProcedure

// Returns an empty parameter structure for selecting the default acquiring Contracts.
// 
// Returns:
//  Structure - Selection parameters:
//  *Organization - Undefined - Organization of the contract.
//  *Acquirer - Undefined - acquirer of the Contract.
//  *BankAccount - Undefined - The bank account of the Contract.
//  *Currency - Undefined - currency of the Contract.
//  *MakingPaymentMethod - Undefined - payment method.
//
Function ParametersOfAcquisitionContractSelection() Export

	Filter = New Structure;
	Filter.Insert("Organization", Undefined);
	Filter.Insert("Acquirer", Undefined);
	Filter.Insert("BankAccount", Undefined);
	Filter.Insert("Currency", Undefined);
	Filter.Insert("MakingPaymentMethod", Undefined);
	
	Return Filter;

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
	|LEFT JOIN InformationRegister.PartnerHierarchy AS T2 
	|	ON T2.Parent = T.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T2.Partner)
	|	AND ValueAllowed(T.Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the details of the acquiring account settings that affect the setting,
// 	corresponding to the names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.Organization = "Organization";
	
EndProcedure

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

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If ValueIsFilled(Parameters.SearchString) Then
		StandardProcessing = False;
		
		Query = New Query;
		
		TextOfConnections = "";
		ConditionsText    = "";
		SelectionNumber_     = 0;
		If Parameters.Property("Filter") Then
			
			For Each CurrentFilter In Parameters.Filter Do
				
				If IntegrationLocalization(CurrentFilter.Key, TextOfConnections, ConditionsText) Then
					Continue;
				EndIf;
				
				SelectionNumber_ = SelectionNumber_ + 1;
				
				ConditionsText = ConditionsText + "
				|	AND AcquiringContracts." + CurrentFilter.Key + " IN (&FilterValue" + TrimAll(SelectionNumber_) + ")";
				
				Query.SetParameter("FilterValue" + TrimAll(SelectionNumber_), CurrentFilter.Value);
				
			EndDo;
			
		EndIf;
		
		// The query text contains literals for redefining/substituting &textconditions &textconditions
		QueryText = "SELECT ALLOWED
				|	AcquiringContracts.Ref AS Ref,
				|	AcquiringContracts.Description AS Description,
				|	AcquiringContracts.Description AS Coincidence,
				|	1 AS Order
				|INTO AcquiringContractsSearch 
				|FROM
				|	Catalog.AcquiringContracts AS AcquiringContracts
				|
				|,&TextOfConnections
				|
				|WHERE
				|	AcquiringContracts.Description LIKE &SearchString ESCAPE ""~""
				|	AND &ConditionsText
				|
				|UNION ALL
				|
				|SELECT
				|	AcquiringContracts.Ref,
				|	AcquiringContracts.Description,
				|	AcquiringContracts.Number,
				|	2
				|FROM
				|	Catalog.AcquiringContracts AS AcquiringContracts
				|
				|,&TextOfConnections
				|
				|WHERE
				|	AcquiringContracts.Number LIKE &SearchString ESCAPE ""~""
				|	AND &ConditionsText
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	AcquiringContractsSearch.Ref AS Ref,
				|	MIN(AcquiringContractsSearch.Order) AS Order
				|INTO AcquiringContractsInOrder
				|FROM
				|	AcquiringContractsSearch AS AcquiringContractsSearch
				|
				|GROUP BY
				|	AcquiringContractsSearch.Ref
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ISNULL(AcquiringContractsSearch.Ref, VALUE(Catalog.AcquiringContracts.EmptyRef)) AS Ref,
				|	ISNULL(AcquiringContractsSearch.Description, """") AS Description,
				|	ISNULL(AcquiringContractsSearch.Coincidence, """") AS Coincidence,
				|	ISNULL(AcquiringContractsSearch.Order, 0) AS Order
				|FROM
				|	AcquiringContractsInOrder AS AcquiringContractsInOrder
				|		LEFT JOIN AcquiringContractsSearch AS AcquiringContractsSearch
				|		ON AcquiringContractsInOrder.Ref = AcquiringContractsSearch.Ref
				|			AND AcquiringContractsInOrder.Order = AcquiringContractsSearch.Order
				|
				|ORDER BY
				|	ISNULL(AcquiringContractsSearch.Order, 0),
				|	ISNULL(AcquiringContractsSearch.Coincidence, """"),
				|	ISNULL(AcquiringContractsSearch.Description, """")";
		
		QueryText = StrReplace(QueryText, ",&TextOfConnections", TextOfConnections);
		
		If Not IsBlankString(ConditionsText) Then
			
			QueryText = StrReplace(QueryText, "AND &ConditionsText", ConditionsText);
			
		Else

			QueryText = StrReplace(QueryText, "AND &ConditionsText", "");
			
		EndIf;
		
		Query.Text = QueryText;
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
		
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			TextValue = ?(
				Selection.Order = 1,
				Selection.Description,
				TrimR(Selection.Coincidence) + " (" + Selection.Description + ")");
				
			ChoiceData.Add(Selection.Ref, TextValue);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return;
	
EndProcedure

Procedure AddPrintCommands(PrintCommands) Export
	
	Return;
	
EndProcedure

#Region Localization

Function IntegrationLocalization(Var_Key, TextOfConnections, ConditionsText)
	
	ThereIsIntegrationSetting = False;
	
	
	Return ThereIsIntegrationSetting;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

