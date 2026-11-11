#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	EntryOfCapitalAssetsBalanceLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers);
		
		// FA
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableFACost(QueryTexts, Registers);
		QueryTextTableFixedAssetsDepreciationCharge(QueryTexts, Registers);
		
		// IA
		QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsRegistrationPlace(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableIACost(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts, Registers);
		
		// Lease
		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableAssetsLeasedOut(QueryTexts, Registers);
		QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers);
		QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers);
		QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers);
		QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		
		// Depreciation of HPA
		QueryTextTableCGUComposition(QueryTexts, Registers);
		QueryTextTableImpairmentFA(QueryTexts, Registers);

		// Common
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		EntryOfCapitalAssetsBalanceLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	EntryOfCapitalAssetsBalanceLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	EntryOfCapitalAssetsBalanceLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		TransactionList = New Array;
		TransactionList.Add(Enums.BusinessTransactions.OBEntryFixedAssets);
		TransactionList.Add(Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut);
		TransactionList.Add(Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets);
		TransactionList.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty);
		AttachableCommands.AddCommandVisibilityCondition(
			Command, "BusinessOperation", TransactionList, DataCompositionComparisonType.InList);
	EndIf;
	
	EntryOfCapitalAssetsBalanceLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export
	
	Result = EntryOfCapitalAssetsBalanceLocalization.BalancesByTypeOfOperation(
					Date, 
					BusinessOperation, 
					Companies, 
					AdditionalSelection, 
					ParametersForFillingBalances);

	Return Result;
			
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Organization");
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets Then
		
		KeyAttributes.Add("FixedAssetsLocation");
		KeyAttributes.Add("Counterparty");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
		
		KeyAttributes.Add("FixedAssetsLocation");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets Then
		
		KeyAttributes.Add("AssetsKind");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets Then
		
		KeyAttributes.Add("FixedAssetsLocation");
		KeyAttributes.Add("Counterparty");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty Then
		
		KeyAttributes.Add("Counterparty");
		KeyAttributes.Add("LeaseholderIntercompanyARAP");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets Then
		
		KeyAttributes.Add("Counterparty");
		KeyAttributes.Add("FixedAssetsLocation");
		KeyAttributes.Add("FinancialAccountingGroup");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut Then
		
		KeyAttributes.Add("Partner");
		KeyAttributes.Add("Counterparty");
		KeyAttributes.Add("FixedAssetsLocation");
		KeyAttributes.Add("FinancialAccountingGroup");
		
	EndIf;
	
	Return KeyAttributes;
		
EndFunction

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
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	Presentation = NonCurrentAssetsServerCall.PresentationOfInputBalances(Data);
	If Not IsBlankString(Presentation) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	BusinessOperation = Undefined;
	
	If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		BusinessOperation = NonCurrentAssetsServerCall.OperationOfEnteringBalances(Parameters.Key);
	ElsIf Parameters.Property("Filter") Then
		Parameters.Filter.Property("BusinessOperation", BusinessOperation);
	ElsIf Parameters.Property("FillingValues") Then
		Parameters.FillingValues.Property("BusinessOperation", BusinessOperation);
	ElsIf Parameters.Property("CopyingValue") Then
		BusinessOperation = NonCurrentAssetsServerCall.OperationOfEnteringBalances(Parameters.CopyingValue);
	ElsIf Parameters.Property("FilterByTransactionTypes") And Parameters.FilterByTransactionTypes.Count() = 1 Then
		BusinessOperation = Parameters.FilterByTransactionTypes[0].Value;
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", BusinessOperation);
		If Parameters.Property("Organization") Then
			FillingValues.Insert("Organization", Parameters.Organization);
		EndIf;
		Parameters.Insert("FillingValues", FillingValues);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets Then
		
		StandardProcessing = False;
		SelectedForm = "FixedAssets";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
		
		StandardProcessing = False;
		SelectedForm = "IntangibleAssets";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets Then
		
		StandardProcessing = False;
		SelectedForm = "InvestmentsInFixedAssets";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets Then
		
		StandardProcessing = False;
		SelectedForm = "LeasedFixedAssets";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut Then
		
		StandardProcessing = False;
		SelectedForm = "LeasingItemsOffBalanceSheet";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryLeaseContractsARAP Then
		
		StandardProcessing = False;
		SelectedForm = "LeaseContractsARAP";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut Then
		
		StandardProcessing = False;
		SelectedForm = "FixedAssetsLeasedOut";
		
	EndIf;
		
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// 
// Parameters:
//  ObjectOrStringData - LineOfATabularSection - 
//  AuxiliaryAttributes - Structure - 
//  ItemDetailsParameters - Array of Structure -
// 
// Returns:
//  String - 
Function FillInDetailsDependingOnProperties(ObjectOrStringData, AuxiliaryAttributes, ItemDetailsParameters) Export

	ChangedBankingDetails = New Array;
	
	ThisIsIA = (AuxiliaryAttributes.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets);
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If AttributeParameters.Property = "Visible" And AttributeParameters.Value = False
			Or AttributeParameters.Property = "ReadOnly" And AttributeParameters.Value = True Then
			Action = "Clear";
		ElsIf AttributeParameters.Property = "Visible" And AttributeParameters.Value = True Then
			Action = "Fill";
		Else
			Continue;
		EndIf;
		
		If Action = "Clear"
			And (AttributeParameters.AttributeName = "CurrentcCostFinAcc"
				Or AttributeParameters.AttributeName = "CurrentcCostManAcc"
				Or AttributeParameters.AttributeName = "InitialCostLocalAccounting"
				Or AttributeParameters.AttributeName = "InitialCostMA"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationAccounting"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationManagementAccounting" 
				Or AttributeParameters.AttributeName = "SecurityDepositValue") Then
			
			ObjectOrStringData[AttributeParameters.AttributeName] = 0;
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "LeaseholderEmployeeInCharge"
			Or AttributeParameters.AttributeName = "LeaseholderBusinessUnit"
			Or AttributeParameters.AttributeName = "Contract" Then
			If Action = "Clear" Then
				ObjectOrStringData[AttributeParameters.AttributeName] = Undefined;
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "AccountingProcedureAC" Then
		
			AttributeValue = 
				?(ThisIsIA, 
					Enums.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization, 
					Enums.FARepaymentProcedure.DepreciationAccrual);
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				AttributeValue, 
				Undefined,
				ChangedBankingDetails);
		
		ElsIf AttributeParameters.AttributeName = "AccountingProcedureMA" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				Enums.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization,
				Undefined,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "DepreciationAccrualAccounting" 
			Or AttributeParameters.AttributeName = "DepreciationAccrualManagementAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				True,
				False,
				ChangedBankingDetails);
				
		ElsIf AttributeParameters.AttributeName = "DepreciationMethodAccounting" Then
			
			AttributeValue = 
				?(ThisIsIA, 
					Enums.AccrualMethodOfIntangibleAssetDepreciation.Linear, 
					Enums.AccrualMethodOfFixedAssetsDepreciation.Linear);
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				AttributeValue,
				Undefined,
				ChangedBankingDetails);
	
		ElsIf AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting" Then
			
			AttributeValue = 
				?(ThisIsIA, 
					Enums.AccrualMethodOfIntangibleAssetDepreciation.Linear, 
					Enums.AccrualMethodOfFixedAssetsDepreciation.Linear);
					
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				AttributeValue,
				Undefined,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "UsefulLifeAccounting"
			Or AttributeParameters.AttributeName = "UsefulLifeManagementAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				ObjectOrStringData.UsefulLifeAccounting,
				0,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "AccelerationFactorAccounting"
			Or AttributeParameters.AttributeName = "AccelerationFactorManagementAccounting" Then
		
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				1,
				0,
				ChangedBankingDetails);
				
		EndIf;
		
		EntryOfCapitalAssetsBalanceLocalization.FillInDetailsDependingOnProperties(
			ObjectOrStringData, AuxiliaryAttributes, AttributeParameters, Action, ChangedBankingDetails);
			
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

// Auxiliary details.
// 
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 -
//  ThisIsStringData - Boolean -
// 
// Returns:
//  FixedStructure - 
Function AuxiliaryAttributes(Object, ThisIsStringData) Export

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	AuxiliaryAttributes.Insert("RecordInMA", Object.RecordInMA);
	AuxiliaryAttributes.Insert("PostInAccounting", Object.PostInAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", Object.RecordInTA);
	AuxiliaryAttributes.Insert("Organization", Object.Organization);
	AuxiliaryAttributes.Insert("BusinessOperation", Object.BusinessOperation);
	AuxiliaryAttributes.Insert("Date", Object.Date);
	AuxiliaryAttributes.Insert("AccountingStartDate", '000101010000');
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Object.Date));
	AuxiliaryAttributes.Insert("AccountingPolicyForFixedAssets", AccountingPoliciesTaxSettingsCached.AccountingPolicyForFixedAssets(Object.Organization, ?(Object.Date <> '000101010000', EndOfMonth(Object.Date), CurrentSessionDate())));
	AuxiliaryAttributes.Insert("UseSeparateFAAccountingByTaxation", GetFunctionalOption("UseSeparateFAAccountingByTaxation"));
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date));
	AuxiliaryAttributes.Insert("LeaseholderIntercompanyARAP", False);
	
	TypeOfTransferContractForLease = ?(ValueIsFilled(Object.RentalContract),
		Common.ObjectAttributeValue(Object.RentalContract, "ContractType"),
		Undefined);
		
	AuxiliaryAttributes.Insert("TypeOfTransferContractForLease", TypeOfTransferContractForLease);
			
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, ?(Object.Date <> '000101010000', EndOfMonth(Object.Date), CurrentSessionDate())));
	
	AuxiliaryAttributes.Insert("UUAccountingIsAvailable", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("BUAccountingIsAvailable", Object.PostInAccounting And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("AccountingIsAvailableWELL", False);
		
	ThereAreRelatedCompanies = Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization);
	AuxiliaryAttributes.Insert("ThereAreRelatedCompanies", ThereAreRelatedCompanies);
	
	EntryOfCapitalAssetsBalanceLocalization.AddAuxiliaryDetails(Object, ThisIsStringData, AuxiliaryAttributes);
	
	AuxiliaryAttributes = New FixedStructure(AuxiliaryAttributes);
	
	If ThisIsStringData Then
		Return AddAuxiliaryDetailsBasedOnLineData(Object, Object, AuxiliaryAttributes);
	EndIf; 
	
	Return AuxiliaryAttributes;
	
EndFunction

Function AddAuxiliaryDetailsBasedOnLineData(Object, RowData, InitialAuxiliaryProps) Export

	AuxiliaryAttributes = New Structure(InitialAuxiliaryProps);
	
	ListOfContractDetails = "AssetHolder,HasSecurityDeposit,ThereIsBuyoutOfLeasedAssets,ThereIsPrepaymentOfBuyoutValue,ARAPCurrency";
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryLeaseContractsARAP
		And ValueIsFilled(RowData.Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(RowData.Contract, ListOfContractDetails);
	Else
		ContractDetails_ = New Structure(ListOfContractDetails);
		ContractDetails_.HasSecurityDeposit = False;
		ContractDetails_.ThereIsBuyoutOfLeasedAssets = False;
		ContractDetails_.ThereIsPrepaymentOfBuyoutValue = False;
		ContractDetails_.ARAPCurrency = Catalogs.Currencies.EmptyRef();
	EndIf;
	AuxiliaryAttributes.Insert("ContractDetails_", ContractDetails_);
	
	EntryOfCapitalAssetsBalanceLocalization.AddAuxiliaryDetailsBasedOnLineData(Object, RowData, AuxiliaryAttributes);
	
	Return New FixedStructure(AuxiliaryAttributes);
	
EndFunction

// Creating a list of available types of operations for entering initial balances.
//
// Parameters:
// 		TransactionTypeList - ValueList - Return, a List of document operation values.
//
Procedure FillInListOfDocumentOperationTypes(TransactionTypeList) Export
	
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryFixedAssets);
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets);
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets);
	
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets);
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty);
	
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets);
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut);
	TransactionTypeList.Add(Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut);
	
EndProcedure

Procedure FillInDefaultValues(RowData, Object) Export
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then	
		
		If Not ValueIsFilled(RowData.FinancialAccountingGroup) Then
			
			AssetKind = ?(RowData.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses, 
							Enums.KindsOfNonCurrentAssets.RD, 
							Enums.KindsOfNonCurrentAssets.IA);
					
			RowData.FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(AssetKind);
			
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryLeaseContractsARAP Then
		
		If Not ValueIsFilled(RowData.PaymentFrequency) Then
			RowData.PaymentFrequency = Enums.ScheduleTimeFence.Month;
		EndIf;	
		
		If Not ValueIsFilled(RowData.AccrualFrequency) Then
			RowData.AccrualFrequency = Enums.ScheduleTimeFence.Month;
		EndIf;	
		
	EndIf; 
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty Then
		
		If Not ValueIsFilled(RowData.FinancialAccountingGroup) Then
			RowData.FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(
													Enums.KindsOfNonCurrentAssets.FixedAsset);
		EndIf;
		
		If Not ValueIsFilled(RowData.SeparateVATAccountingOption) Then
			RowData.SeparateVATAccountingOption = Enums.SeparateVATAccountingOptions.FromDocument;
		EndIf;
		
		If Not ValueIsFilled(RowData.VATTaxation) Then
			RowData.VATTaxation = NonCurrentAssets.VATTaxation(Object.Organization, Object.Date);
		EndIf;
		
	EndIf; 
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
		
		If Not ValueIsFilled(RowData.SeparateVATAccountingOption) Then
			RowData.SeparateVATAccountingOption = Enums.SeparateVATAccountingOptions.FromDocument;
		EndIf;
		
		If Not ValueIsFilled(RowData.VATTaxation) Then
			RowData.VATTaxation = NonCurrentAssets.VATTaxation(Object.Organization, Object.Date);
		EndIf;
		
	EndIf; 
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
		
		RowData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping = Object.PostInAccounting;
		RowData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting = Object.RecordInManAccounting;
		
	EndIf; 
	
	EntryOfCapitalAssetsBalanceLocalization.FillInDefaultValues(RowData, Object);
	
EndProcedure

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.EntryOfCapitalAssetsBalance2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RequestHasSource = True;
	RedefiningParameterCalculation = New Structure;
	
	QueryText = Undefined;
	SynonymForDocumentTable = Undefined;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
				
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
				
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "LeasedAsset" Then
		
		QueryText = QueryTextTableLeasedAsset(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "AccountingProcedureForOSBU" Then
		
		QueryText = QueryTextTableAccountingProcedureForOSBU(QueryTexts, RegisterName);
		SynonymForDocumentTable = "FATable";
		
	Else
		
		QueryText = EntryOfCapitalAssetsBalanceLocalization.AdaptedCaseSensitiveQueryText(
							RegisterName, RedefiningParameterCalculation, SynonymForDocumentTable);
		
	EndIf;
				
	If QueryText = Undefined Then
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments"
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	GetDocumentData(Query);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                               AS Ref,
	|	DocumentData.Date                                 AS Period,
	|	DocumentData.Number                                AS Number,
	|	DocumentData.Organization                          AS Organization,
	|	DocumentData.FixedAssetsLocation                      AS FixedAssetsLocation,
	|	DocumentData.BusinessOperation                AS BusinessOperation,
	|	DocumentData.EmployeeResponsible                        AS EmployeeResponsible,
	|	DocumentData.Comment                          AS Comment,
	|	DocumentData.Posted                             AS Posted,
	|	DocumentData.DeletionMark                      AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting                   AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                    AS RecordInManAccounting,
	|	DocumentData.PostInAccounting                          AS PostInAccounting,
	|	DocumentData.RecordInTA                          AS RecordInTA,
	|	DocumentData.PostInFinancialAndTaxAccounting                       AS PostInFinancialAndTaxAccounting,
	|	DocumentData.RecordInOperationalAccounting            AS RecordInOperationalAccounting,
	|	DocumentData.RecordInMA                          AS RecordInMA,
	|	DocumentData.FinancialAccountingGroup               AS FinancialAccountingGroup,
	|	DocumentData.AssetsKind                           AS AssetsKind,
	|	DocumentData.Partner                              AS Partner,
	|	DocumentData.Counterparty                           AS Counterparty,
	|	DocumentData.RentalContract               AS RentalContract,
	|	DocumentData.LeaseholderIntercompanyARAP   AS LeaseholderIntercompanyARAP,
	|	BusinessTransactionsSettings.Ref                AS BusinessTransactionSetting,
	|	&EnteringBalancesOfNonCurrentAssets_HeaderDetails
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	EntryOfCapitalAssetsBalanceLocalization.AddHeaderDetailsToRequestText(QueryText, "DocumentData");
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset,
	|	DocumentTable.IntangibleAsset AS AccountingObject
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.IA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.EntryOfCapitalAssetsBalance2_4"));
	ValuesOfHoldingParameters.Insert("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Nhập số dư của tài sản dài hạn';
															|ru = 'Ввод остатков внеоборотных активов';
															|en = 'OB entry: Fixed assets cost and depreciation'; fa = 'ورود مانده افتتاحیه: بهای تمام‌شده و استهلاک دارایی‌های ثابت';
															|it = 'Inserimento saldi degli attivi non correnti';
															|pl = 'Wprowadzanie ostatków aktywów pozaobrotowych';
															|tr = 'Duran varlıkların bakiyelerinin girilmesi'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		ValuesOfHoldingParameters.Insert(
			"FALocalAccountingIsConductedIndependently", 
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Attributes.Organization, Attributes.Period));
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period));
			
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&FixedAssetsLocation                        AS Department,
	|	&Counterparty                             AS Counterparty,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	CASE 
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
	|										VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
	|			THEN FATable.Department
	|		ELSE &FixedAssetsLocation
	|	END                                   AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&PostInAccounting                            AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting,
	|	&RecordInTA                            AS RecordInTA,
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.OBEntryFixedAssets),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty),
	|			VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut),
	|			VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets))
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&FixedAssetsLocation                        AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&PostInAccounting                            AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting,
	|	&RecordInTA                            AS RecordInTA,
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut),
	|			VALUE(Enum.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets))
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(DocumentTable.LineNumber-1, 0) AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	DocumentTable.Department          AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&PostInAccounting                            AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting,
	|	&RecordInTA                            AS RecordInTA,
	|	DocumentTable.NonCurrentAsset      AS FixedAsset
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.OtherExpenses AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryInvestmentsInFixedAssets)
	|	AND &AssetsKind IN (
	|		VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset),
	|		VALUE(Enum.KindsOfNonCurrentAssets.ConstructionObjects))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(DocumentTable.LineNumber-1, 0) AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&FixedAssetsLocation                        AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&PostInAccounting                            AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting,
	|	&RecordInTA                            AS RecordInTA,
	|	DocumentTable.IntangibleAsset    AS IntangibleAsset
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.IA AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets)
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(DocumentTable.LineNumber-1, 0) AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&FixedAssetsLocation                        AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&RecordInLocalAccounting                     AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting,
	|	&RecordInLocalAccounting                     AS RecordInTA,
	|	DocumentTable.NonCurrentAsset      AS IntangibleAsset
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.OtherExpenses AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryInvestmentsInFixedAssets)
	|	AND &AssetsKind = VALUE(Enum.KindsOfNonCurrentAssets.IA)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableInitialFixedAssetsInformation(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
			
		QueryText =
		"SELECT
		|	&Ref                         AS Recorder,
		|	&Period                         AS Period,
		|	FATable.FixedAsset      AS FixedAsset,
		|	&Organization                    AS Organization,
		|
		|	CASE 
		|		WHEN &PostInAccounting 
		|			THEN FATable.DateOfRecognitionAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDateAC, DATETIME(1, 1, 1))
		|	END                           AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN FATable.DateOfRecognitionManagementAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDateMA, DATETIME(1, 1, 1))
		|	END                           AS CommissioningDateMA,
		|
		|	CASE
		|		WHEN &PostInAccounting
		|			THEN &Ref 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDocumentAC, UNDEFINED)
		|	END                           AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting
		|			THEN &Ref 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDocumentMA, UNDEFINED)
		|	END                           AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN &PostInAccounting 
		|			THEN FATable.DepreciationMethodAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.DepreciationMethodAccounting, UNDEFINED)
		|	END                           AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN &PostInAccounting 
		|			THEN FATable.AccountingProcedureAC 
		|		ELSE ISNULL(TTInitialInformationFA.AccountingProcedureAC, UNDEFINED)
		|	END                           AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN FATable.AccountingProcedureMA 
		|		ELSE ISNULL(TTInitialInformationFA.AccountingProcedureMA, UNDEFINED)
		|	END                           AS AccountingProcedureMA,
		|
		|	CASE 
		|		WHEN &PostInAccounting 
		|			THEN FATable.InitialCostLocalAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.InitialCostLocalAccounting, 0)
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN FATable.InitialCostMA 
		|		ELSE ISNULL(TTInitialInformationFA.InitialCostMA, 0)
		|	END AS InitialCostMA
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|
		|		LEFT JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.FixedAsset = FATable.FixedAsset
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                         AS Recorder,
		|	&Period                         AS Period,
		|	FATable.FixedAsset      AS FixedAsset,
		|	&Organization                    AS Organization,
		|
		|	FATable.DateOfRecognitionManagementAccounting  AS CommissioningDateAC,
		|	FATable.DateOfRecognitionManagementAccounting  AS CommissioningDateMA,
		|
		|	&Ref                         AS CommissioningDocumentAC,
		|	&Ref                         AS CommissioningDocumentMA,
		|
		|	FATable.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	CASE FATable.AccountingProcedureMA
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.CostIsNotRedeemable)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|	END AS AccountingProcedureAC,
		|
		|	FATable.AccountingProcedureMA        AS AccountingProcedureMA,
		|
		|	FATable.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	FATable.InitialCostMA AS InitialCostMA
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                         AS Recorder,
		|	&Period                         AS Period,
		|	FATable.FixedAsset      AS FixedAsset,
		|	&Organization                    AS Organization,
		|	FATable.DateOfRecognition    AS CommissioningDateAC,
		|	FATable.DateOfRecognition    AS CommissioningDateMA,
		|	&Ref                         AS CommissioningDocumentAC,
		|	&Ref                         AS CommissioningDocumentMA,
		|	UNDEFINED                    AS DepreciationMethodAccounting,
		|	UNDEFINED                    AS AccountingProcedureAC,
		|	UNDEFINED                    AS AccountingProcedureMA,
		|	FATable.SecurityDepositValue    AS InitialCostLocalAccounting,
		|	0                               AS InitialCostMA
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableInitialIntangibleAssetsInformation(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
		
		QueryText =
		"SELECT
		|	&Ref                                AS Recorder,
		|	&Period                                AS Period,
		|	DocumentTable.IntangibleAsset   AS IntangibleAsset,
		|	&Organization                           AS Organization,
		|
		|	DocumentTable.PurchaseDate      AS PurchaseDate,
		|
		|	CASE 
		|		WHEN &PostInAccounting 
		|			THEN DocumentTable.DateOfRecognitionAccounting 
		|		ELSE ISNULL(TTInitialInformationOfIA.DateOfRecognitionAccounting, DATETIME(1, 1, 1))
		|	END AS DateOfRecognitionAccounting,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN DocumentTable.DateOfRecognitionManagementAccounting 
		|		ELSE ISNULL(TTInitialInformationOfIA.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1))
		|	END AS DateOfRecognitionManagementAccounting,
		|
		|	CASE
		|		WHEN &PostInAccounting
		|			THEN &Ref 
		|		ELSE ISNULL(TTInitialInformationOfIA.DocumentOfRecognitionAccounting, UNDEFINED)
		|	END AS DocumentOfRecognitionAccounting,
		|
		|	CASE
		|		WHEN &RecordInManAccounting
		|			THEN &Ref 
		|		ELSE ISNULL(TTInitialInformationOfIA.DocumentOfRecognitionManagementAccounting, UNDEFINED)
		|	END AS DocumentOfRecognitionManagementAccounting,
		|
		|	CASE 
		|		WHEN &PostInAccounting 
		|			THEN DocumentTable.DepreciationMethodAccounting 
		|		ELSE ISNULL(TTInitialInformationOfIA.DepreciationMethodAccounting, UNDEFINED)
		|	END AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN DocumentTable.InitialCostMA 
		|		ELSE ISNULL(TTInitialInformationOfIA.InitialCostMA, 0)
		|	END AS InitialCostMA,
		|
		|	CASE 
		|		WHEN &PostInAccounting OR NOT &ComplianceCAAccountingIsKept
		|			THEN DocumentTable.InitialCostLocalAccounting 
		|		ELSE ISNULL(TTInitialInformationOfIA.InitialCostLocalAccounting, 0)
		|	END AS InitialCostLocalAccounting
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS DocumentTable
		|
		|		LEFT JOIN TTInitialInformationOfIA AS TTInitialInformationOfIA
		|		ON TTInitialInformationOfIA.IntangibleAsset = DocumentTable.IntangibleAsset
		|
		|WHERE
		|	DocumentTable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                                AS Recorder,
		|	&Period                                AS Period,
		|	DocumentTable.IntangibleAsset   AS IntangibleAsset,
		|	&Organization                           AS Organization,
		|
		|	DocumentTable.PurchaseDate      AS PurchaseDate,
		|
		|	DocumentTable.DateOfRecognitionManagementAccounting AS DateOfRecognitionAccounting,
		|	DocumentTable.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
		|
		|	&Ref AS DocumentOfRecognitionAccounting,
		|	&Ref AS DocumentOfRecognitionManagementAccounting,
		|
		|	DocumentTable.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	DocumentTable.InitialCostMA AS InitialCostMA,
		|	DocumentTable.InitialCostLocalAccounting AS InitialCostLocalAccounting
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS DocumentTable
		|
		|		LEFT JOIN TTInitialInformationOfIA AS TTInitialInformationOfIA
		|		ON TTInitialInformationOfIA.IntangibleAsset = DocumentTable.IntangibleAsset
		|
		|WHERE
		|	DocumentTable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	FATable.FinanciallyLiablePerson                 AS FinanciallyLiablePerson,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
	|				VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
	|			THEN FATable.Department
	|		ELSE &FixedAssetsLocation              
	|	END                         AS FixedAssetsLocation,
	|	FATable.LocationAddress AS LocationAddress,
	|	FATable.LocationAddressValue AS LocationAddressValue,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
	|				VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
	|			THEN &Counterparty
	|		ELSE UNDEFINED              
	|	END                         AS Leaseholder,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
	|				VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
	|			THEN FATable.LeaseholderBusinessUnit
	|		ELSE UNDEFINED              
	|	END                         AS LeaseholderBusinessUnit,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
	|				VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
	|			THEN FATable.LeaseholderEmployeeInCharge
	|		ELSE UNDEFINED              
	|	END                         AS LeaseholderEmployeeInCharge,
	|	&RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	&RecordInManAccounting            AS RecordInManAccounting
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref                                   AS Recorder,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	FATable.FixedAsset                AS FixedAsset,
	|	FATable.FinanciallyLiablePerson                             AS FinanciallyLiablePerson,
	|	&FixedAssetsLocation                          AS FixedAssetsLocation,
	|	""""                                      AS LocationAddress,
	|	""""                                      AS LocationAddressValue,
	|	UNDEFINED                              AS Leaseholder,
	|	UNDEFINED                              AS LeaseholderBusinessUnit,
	|	UNDEFINED                              AS LeaseholderEmployeeInCharge,
	|	&RecordInLocalAccounting                       AS RecordInLocalAccounting,
	|	&RecordInManAccounting                        AS RecordInManAccounting
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsRegistrationPlace(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsRegistrationPlace";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	Table.IntangibleAsset   AS IntangibleAsset,
	|	&FixedAssetsLocation              AS Department,
	|	&RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	&RecordInManAccounting            AS RecordInManAccounting
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
	|WHERE
	|	Table.Ref = &Ref
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                 AS Recorder,
	|	&Period                                 AS Period,
	|	&Organization                            AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	FATable.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness       AS LineOfBusiness,
	|	FATable.RunningTimeValue           AS RunningTimeValue,
	|	FATable.EstimatedRunningTime                AS EstimatedRunningTime,
	|	&RecordInLocalAccounting                     AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref                                 AS Recorder,
	|	&Period                                 AS Period,
	|	&Organization                            AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	&FinancialAccountingGroup                 AS FinancialAccountingGroup,
	|	UNDEFINED                            AS LineOfBusiness,
	|	UNDEFINED                            AS RunningTimeValue,
	|	0                                       AS EstimatedRunningTime,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	FALSE                                    AS RecordInManAccounting
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets),
	|		VALUE(Enum.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                 AS Recorder,
	|	&Period                                 AS Period,
	|	&Organization                            AS Organization,
	|	Table.IntangibleAsset             AS IntangibleAsset,
	|	Table.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	Table.LineOfBusiness         AS LineOfBusiness,
	|	Table.EstimatedRunningTime                  AS EstimatedRunningTime,
	|	&RecordInLocalAccounting                     AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
	|WHERE
	|	Table.Ref = &Ref
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableAccountingProcedureForOSBU(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|	FATable.DepreciationAccrualAccounting                 AS DepreciationAccrualAccounting,
		|	FATable.ExpenseRecordMethodAC              AS ExpenseRecordMethodAC,
		|	FATable.ExpenseItemAccounting                       AS ExpenseItemAccounting,
		|	FATable.ExpensesDimensionAccounting                    AS ExpensesDimensionAccounting,
		|	FATable.DepartmentACC                        AS DepartmentACC,
		|	FATable.LineOfBusinessBookkeeping              AS LineOfBusinessBookkeeping,
		|	FATable.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	FATable.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &PostInAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|	FATable.DepreciationAccrualManagementAccounting                 AS DepreciationAccrualAccounting,
		|	FATable.MethodForReflectingMaExpenses              AS ExpenseRecordMethodAC,
		|	FATable.ExpenseItemManagementAccounting                       AS ExpenseItemAccounting,
		|	FATable.ExpensesDimensionManagementAccounting                    AS ExpensesDimensionAccounting,
		|	FATable.BusinessUnitManagementAccounting                        AS DepartmentACC,
		|	FATable.LineOfBusinessManagementAccounting              AS LineOfBusinessBookkeeping,
		|	FATable.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	FATable.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &PostInAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting) AS BUState,
		|	FALSE                                             AS DepreciationAccrualAccounting,
		|	UNDEFINED                                     AS ExpenseRecordMethodAC,
		|	UNDEFINED                                     AS ExpenseItemAccounting,
		|	UNDEFINED                                     AS ExpensesDimensionAccounting,
		|	UNDEFINED                                     AS DepartmentACC,
		|	UNDEFINED                                     AS LineOfBusinessBookkeeping,
		|	FALSE                                             AS TransferExpensesToAnotherCompany,
		|	UNDEFINED                                     AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableFixedAssetsAccountingProcedureManagementAccounting();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Ref                                          AS Recorder,
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
		|	FATable.DepreciationAccrualManagementAccounting                 AS AccrueDepreciationOrAmortization,
		|
		|	CASE 
		|		WHEN FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|				AND FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
		|				AND FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|
		|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
		|
		|			THEN FATable.ExpenseRecordMethodAC
		|
		|		ELSE FATable.MethodForReflectingMaExpenses 
		|
		|	END AS ExpensesPostingMethod,
		|
		|	CASE 
		|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
		|
		|			THEN FATable.ExpenseItemAccounting
		|
		|		ELSE FATable.ExpenseItemManagementAccounting 
		|
		|	END AS ExpenseItem,
		|
		|	CASE 
		|		WHEN FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|				AND FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
		|				AND FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			
		|			THEN UNDEFINED
		|
		|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
		|
		|			THEN FATable.ExpensesDimensionAccounting
		|
		|		ELSE FATable.ExpensesDimensionManagementAccounting
		| 
		|	END AS DimensionOfExpenses,
		|
		|	CASE 
		|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
		|
		|			THEN FATable.DepartmentACC
		|
		|		ELSE FATable.BusinessUnitManagementAccounting
		| 
		|	END AS Department,
		|
		|	CASE 
		|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
		|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
		|
		|			THEN FATable.LineOfBusinessBookkeeping
		|
		|		ELSE FATable.LineOfBusinessManagementAccounting
		| 
		|	END AS LineOfBusiness,
		|
		|	FATable.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	FATable.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInManAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                                          AS Recorder,
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting) AS State,
		|	FALSE                                             AS DepreciationAccrualManagementAccounting,
		|	UNDEFINED                                     AS ExpensesPostingMethod,
		|	UNDEFINED                                     AS ExpenseItem,
		|	UNDEFINED                                     AS DimensionOfExpenses,
		|	UNDEFINED                                     AS Department,
		|	UNDEFINED                                     AS LineOfBusiness,
		|	FALSE                                             AS TransferExpensesToAnotherCompany,
		|	UNDEFINED                                     AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers)

	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Ref                                          AS Recorder,
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	Table.IntangibleAsset                      AS IntangibleAsset,
		|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting) AS BUState,
		|	Table.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization) AS DepreciationAccrualAccounting,
		|	Table.ExpenseRecordMethodAC                AS ExpenseRecordMethodAC,
		|	Table.ExpenseItemAccounting                         AS ExpenseItemAccounting,
		|	Table.ExpensesDimensionAccounting                      AS ExpensesDimensionAccounting,
		|	Table.DepartmentACC                          AS DepartmentACC,
		|	Table.LineOfBusinessBookkeeping                AS LineOfBusinessBookkeeping,
		|	Table.TransferExpensesToAnotherCompany      AS TransferExpensesToAnotherCompany,
		|	Table.CompanyRecipientOfExpenses            AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|
		|WHERE
		|	Table.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &PostInAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                                          AS Recorder,
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	Table.IntangibleAsset                      AS IntangibleAsset,
		|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting) AS BUState,
		|	Table.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization) AS DepreciationAccrualAccounting,
		|	Table.MethodForReflectingMaExpenses                AS ExpenseRecordMethodAC,
		|	Table.ExpenseItemManagementAccounting                         AS ExpenseItemAccounting,
		|	Table.ExpensesDimensionManagementAccounting                      AS ExpensesDimensionAccounting,
		|	Table.BusinessUnitManagementAccounting                          AS DepartmentACC,
		|	Table.LineOfBusinessManagementAccounting                AS LineOfBusinessBookkeeping,
		|	Table.TransferExpensesToAnotherCompany      AS TransferExpensesToAnotherCompany,
		|	Table.CompanyRecipientOfExpenses            AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|
		|WHERE
		|	Table.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting();
	
	If QueryText = Undefined Then
	
		QueryText =
		"SELECT
		|	&Ref                                          AS Recorder,
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	Table.IntangibleAsset                      AS IntangibleAsset,
		|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting) AS State,
		|	Table.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization) AS AccrueDepreciationOrAmortization,
		|
		|	CASE 
		|		WHEN Table.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND Table.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|
		|			THEN Table.ExpenseRecordMethodAC
		|
		|		ELSE Table.MethodForReflectingMaExpenses 
		|
		|	END AS ExpensesPostingMethod,
		|
		|	CASE 
		|		WHEN Table.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND Table.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|
		|			THEN Table.ExpenseItemAccounting
		|
		|		ELSE Table.ExpenseItemManagementAccounting 
		|
		|	END AS ExpenseItem,
		|
		|	CASE 
		|		WHEN Table.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND Table.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|
		|			THEN Table.ExpensesDimensionAccounting
		|
		|		ELSE Table.ExpensesDimensionManagementAccounting 
		|
		|	END AS DimensionOfExpenses,
		|
		|	CASE 
		|		WHEN Table.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND Table.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|
		|			THEN Table.DepartmentACC
		|
		|		ELSE Table.BusinessUnitManagementAccounting 
		|
		|	END AS Department,
		|
		|	CASE 
		|		WHEN Table.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND &RecordInManAccounting
		|				AND &RecordInLocalAccounting
		|				AND Table.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|
		|			THEN Table.LineOfBusinessBookkeeping
		|
		|		ELSE Table.LineOfBusinessManagementAccounting 
		|
		|	END AS LineOfBusiness,
		|
		|	Table.TransferExpensesToAnotherCompany      AS TransferExpensesToAnotherCompany,
		|	Table.CompanyRecipientOfExpenses            AS CompanyRecipientOfExpenses
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|
		|WHERE
		|	Table.Ref = &Ref
		|	AND &RecordInManAccounting
		|	AND &RecordInOperationalAccounting";
	
	EndIf;

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Ref                               AS Recorder,
		|	&Period                               AS Period,
		|	&Organization                          AS Organization,
		|	FATable.FixedAsset            AS FixedAsset,
		|
		|	FATable.UsefulLifeAccounting         AS UsefulLifeMonthsAC,
		|	FATable.AccelerationFactorAccounting      AS AccelerationFactor,
		|	FATable.ResidualValueLocal AS ResidualValueMan,
		|
		|	CASE 
		|		WHEN FATable.ThereIsChangesOfDepreciationParametersAccounting
		|			THEN FATable.ResidualEstimatedRunningTimeAccounting 
		|		ELSE FATable.EstimatedRunningTime 
		|	END                                 AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE 
		|		WHEN FATable.ThereIsChangesOfDepreciationParametersAccounting
		|			THEN FATable.ResidualUsefulLifeAccounting
		|		ELSE FATable.UsefulLifeAccounting 
		|	END                                 AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	CASE 
		|		WHEN FATable.ThereIsChangesOfDepreciationParametersAccounting
		|			THEN FATable.DateOfDepreciationParametersChangeAccounting
		|		ELSE FATable.DateOfRecognitionAccounting
		|	END                                 AS LastChangeDate
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                               AS Recorder,
		|	&Period                               AS Period,
		|	&Organization                          AS Organization,
		|	FATable.FixedAsset            AS FixedAsset,
		|
		|	FATable.UsefulLifeManagementAccounting         AS UsefulLifeMonthsAC,
		|	FATable.AccelerationFactorManagementAccounting      AS AccelerationFactor,
		|	FATable.ResidualValueLocal AS ResidualValueMan,
		|
		|	CASE 
		|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
		|			THEN FATable.ResidualEstimatedRunningTimeManagementAccounting 
		|		ELSE FATable.EstimatedRunningTime 
		|	END                                 AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE 
		|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
		|			THEN FATable.ResidualUsefulLifeManagementAccounting
		|		ELSE FATable.UsefulLifeManagementAccounting 
		|	END                                 AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	CASE 
		|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
		|			THEN FATable.DateOfDepreciationParametersChangeManagementAccounting
		|		ELSE FATable.DateOfRecognitionManagementAccounting
		|	END                                 AS LastChangeDate
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|
		|";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                      AS Recorder,
	|	&Period                                      AS Period,
	|	CASE 
	|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
	|			THEN FATable.DateOfDepreciationParametersChangeManagementAccounting
	|		WHEN &Period < &AccountingStartDate
	|			THEN DATEADD(&Period, DAY, 1)
	|		ELSE FATable.DateOfRecognitionManagementAccounting 
	|	END                                        AS LastChangeDate,
	|	&Organization                                 AS Organization,
	|	FATable.FixedAsset                   AS FixedAsset,
	|	FATable.UsefulLifeManagementAccounting                AS UsefulLifeMonths,
	|	CASE 
	|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
	|			THEN FATable.ResidualUsefulLifeManagementAccounting
	|		ELSE FATable.UsefulLifeManagementAccounting 
	|	END                                        AS UsefulLifeForCalculatingDepreciationMonth,
	|	CASE 
	|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
	|			THEN ResidualEstimatedRunningTimeManagementAccounting 
	|		ELSE FATable.EstimatedRunningTime 
	|	END                                        AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FATable.AccelerationFactorManagementAccounting             AS AccelerationFactor,
	|	FATable.DepreciationAccrualMethodManagementAccounting       AS DepreciationMethod,
	|	FATable.ResidualValueMan            AS ResidualValueMan,
	|	FATable.ResidualValueLocal        AS ResidualValueLocal,
	|	CASE 
	|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
	|			THEN FATable.CostUsedToCalculateDepreciationInManagementAccounting
	|		ELSE FATable.CurrentcCostManAcc
	|	END                                        AS CostUsedToCalculateDepreciationManag,
	|	CASE 
	|		WHEN &ComplianceCAAccountingIsKept
	|			THEN 0
	|		WHEN FATable.HasChangesInDepreciationParametersManagementAccounting
	|			THEN FATable.CostUsedToCalculateDepreciationInAccounting
	|		ELSE FATable.CurrentcCostFinAcc
	|	END                                        AS CostUsedToCalculateDepreciationLocal
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInManAccounting
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IADepreciationParametersBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Ref                               AS Recorder,
		|	&Period                               AS Period,
		|	&Organization                          AS Organization,
		|
		|	CASE 
		|		WHEN Table.ThereIsAnIntangibleAssetImprovementAcc
		|			THEN Table.LastImprovementDateAcc
		|		WHEN &Period < &AccountingStartDate
		|			THEN DATEADD(&Period, DAY, 1)
		|		ELSE Table.DateOfRecognitionAccounting 
		|	END AS LastChangeDate,
		|
		|	Table.IntangibleAsset           AS IntangibleAsset,
		|	Table.UsefulLifeAccounting           AS UsefulLifeMonthsAC,
		|
		|	CASE 
		|		WHEN Table.ThereIsAnIntangibleAssetImprovementAcc
		|			THEN Table.ResidualUsefulLifeAccounting
		|		ELSE Table.UsefulLifeAccounting 
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	CASE 
		|		WHEN Table.ThereIsAnIntangibleAssetImprovementAcc
		|			THEN Table.ResidualEstimatedRunningTimeAccounting 
		|		ELSE Table.EstimatedRunningTime 
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	Table.DepreciationAccrualFactor                 AS DepreciationAccrualFactor,
		|	Table.ResidualValueLocal   AS ResidualValueMan
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|WHERE
		|	Table.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                               AS Recorder,
		|	&Period                               AS Period,
		|	&Organization                          AS Organization,
		|
		|	CASE 
		|		WHEN Table.ThereIsAnIntangibleAssetImprovementMan
		|			THEN Table.LastImprovementDateMan
		|		WHEN &Period < &AccountingStartDate
		|			THEN DATEADD(&Period, DAY, 1)
		|		ELSE Table.DateOfRecognitionManagementAccounting 
		|	END AS LastChangeDate,
		|
		|	Table.IntangibleAsset           AS IntangibleAsset,
		|	Table.UsefulLifeManagementAccounting           AS UsefulLifeMonthsAC,
		|
		|	CASE 
		|		WHEN Table.ThereIsAnIntangibleAssetImprovementMan
		|			THEN Table.ResidualUsefulLifeManagementAccounting
		|		ELSE Table.UsefulLifeAccounting 
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	CASE 
		|		WHEN Table.ThereIsAnIntangibleAssetImprovementMan
		|			THEN Table.ResidualEstimatedRunningTimeManagementAccounting 
		|		ELSE Table.EstimatedRunningTime 
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	Table.AccelerationFactorManagementAccounting        AS DepreciationAccrualFactor,
		|	Table.ResidualValueLocal   AS ResidualValueMan
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|WHERE
		|	Table.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetAmortizationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                      AS Recorder,
	|	&Period                                      AS Period,
	|	&Organization                                 AS Organization,
	|	Table.IntangibleAsset                  AS IntangibleAsset,
	|
	|	CASE 
	|		WHEN Table.ThereIsAnIntangibleAssetImprovementMan
	|			THEN Table.LastImprovementDateMan
	|		WHEN &Period < &AccountingStartDate
	|			THEN DATEADD(&Period, DAY, 1)
	|		ELSE Table.DateOfRecognitionManagementAccounting 
	|	END AS LastChangeDate,
	|
	|	CASE 
	|		WHEN Table.ThereIsAnIntangibleAssetImprovementMan
	|			THEN Table.ResidualUsefulLifeManagementAccounting
	|		ELSE Table.UsefulLifeManagementAccounting 
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	CASE 
	|		WHEN Table.ThereIsAnIntangibleAssetImprovementMan
	|			THEN Table.ResidualEstimatedRunningTimeManagementAccounting 
	|		ELSE Table.EstimatedRunningTime 
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	Table.UsefulLifeManagementAccounting                  AS UsefulLifeMonths,
	|	Table.AccelerationFactorManagementAccounting               AS AccelerationFactor,
	|	Table.DepreciationAccrualMethodManagementAccounting         AS DepreciationMethod,
	|	Table.ResidualValueMan              AS ResidualValueMan,
	|	Table.ResidualValueLocal          AS ResidualValueLocal
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
	|
	|WHERE
	|	Table.Ref = &Ref
	|	AND &RecordInManAccounting
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableFACost();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	FATable.FixedAsset                   AS FixedAsset,
		|	FATable.FinancialAccountingGroup             AS FinancialAccountingGroup,
		|	FATable.LineOfBusiness            AS LineOfBusiness,
		|	CASE 
		|		WHEN &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
		|				VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
		|			THEN &Counterparty
		|		ELSE UNDEFINED
		|	END                                        AS Leaseholder,
		|	&RecordInLocalAccounting                          AS RecordInLocalAccounting,
		|	&RecordInManAccounting                           AS RecordInManAccounting,
		|	FATable.CurrentcCostManAcc                 AS Cost,
		|	FATable.CurrentcCostFinAcc                 AS LocalCost,
		|	FATable.CostRevaluationReserve          AS CostRevaluationReserve,
		|	FATable.CostRevaluationReserveLocal      AS CostRevaluationReserveLocal,
		|
		|	0 AS CostGainMA,
		|	0 AS CostGainLocal,
		|
		|	CASE
		|		WHEN &LeaseholderIntercompanyARAP
		|			THEN FATable.SecurityDepositValue
		|		ELSE 0
		|	END AS SecurityDepositValue,
		|
		|	FATable.RowID AS FinRecordID,
		|	VALUE(Enum.BusinessTransactions.OBEntryFixedAssetsCosts)  AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryFixedAssetsCosts) AS BusinessTransactionSetting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND (FATable.CurrentcCostManAcc <> 0
		|		OR FATable.CurrentcCostFinAcc <> 0
		|		OR FATable.CostRevaluationReserve <> 0
		|		OR FATable.CostRevaluationReserveLocal <> 0)
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	FATable.FixedAsset                   AS FixedAsset,
		|	FATable.FinancialAccountingGroup             AS FinancialAccountingGroup,
		|	FATable.LineOfBusiness            AS LineOfBusiness,
		|	UNDEFINED                                 AS Leaseholder,
		|	&RecordInLocalAccounting                          AS RecordInLocalAccounting,
		|	&RecordInManAccounting                           AS RecordInManAccounting,
		|	0                                            AS Cost,
		|	0                                            AS LocalCost,
		|	0                                            AS CostRevaluationReserve,
		|	0                                            AS CostRevaluationReserveLocal,
		|
		|	CASE 
		|		WHEN (FATable.CostRevaluationReserve - FATable.DepreciationRevaluationReserve) > 0
		|			THEN FATable.CostRevaluationReserve - FATable.DepreciationRevaluationReserve
		|		ELSE 0
		|	END AS CostGainMA,
		|
		|	CASE 
		|		WHEN (FATable.CostRevaluationReserveLocal - FATable.DepreciationRevaluationReserveLocal) > 0
		|			THEN FATable.CostRevaluationReserveLocal - FATable.DepreciationRevaluationReserveLocal
		|		ELSE 0
		|	END AS CostGainLocal,
		|
		|	0                                             AS SecurityDepositValue,
		|
		|	FATable.RowID AS FinRecordID,
		|	VALUE(Enum.BusinessTransactions.OBEntryFixedAssetsCosts)  AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryFixedAssetsCosts) AS BusinessTransactionSetting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND ((FATable.CostRevaluationReserve - FATable.DepreciationRevaluationReserve) > 0
		|		OR (FATable.CostRevaluationReserveLocal - FATable.DepreciationRevaluationReserveLocal) > 0)
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	FATable.FixedAsset                   AS FixedAsset,
		|	&FinancialAccountingGroup                      AS FinancialAccountingGroup,
		|	UNDEFINED                                 AS LineOfBusiness,
		|	UNDEFINED                                 AS Leaseholder,
		|	&RecordInLocalAccounting                          AS RecordInLocalAccounting,
		|	&RecordInManAccounting                           AS RecordInManAccounting,
		|	0                                            AS Cost,
		|	0                                            AS LocalCost,
		|	0                                            AS CostRevaluationReserve,
		|	0                                            AS CostRevaluationReserveLocal,
		|	0                                            AS CostGainMA,
		|	0                                            AS CostGainLocal,
		|	FATable.SecurityDepositValue                 AS SecurityDepositValue,
		|
		|	&IDOfUnusedFinRecord        AS FinRecordID,
		|	&BusinessOperation                       AS BusinessOperation,
		|	UNDEFINED                                 AS BusinessTransactionSetting
		|
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting";
	
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts, Registers)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableFixedAssetsDepreciationCharge();
	
	If QueryText = Undefined Then
	
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	&Ref                                      AS Recorder,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	CASE 
		|		WHEN &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty), 
		|				VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
		|			THEN FATable.Department
		|		ELSE &FixedAssetsLocation
		|	END                                        AS Department,
		|	FATable.FixedAsset                   AS FixedAsset,
		|	FATable.FinancialAccountingGroup             AS FinancialAccountingGroup,
		|	FATable.LineOfBusiness            AS LineOfBusiness,
		|	VALUE(Enum.BusinessTransactions.OBEntryFixedAssetDepreciationCharge)  AS BusinessOperation,
		|	FATable.AccumulatedDepreciationManagementAccounting           AS Depreciation,
		|	FATable.AccumulatedDepreciationAccounting           AS DepreciationLocal,
		|	FATable.DepreciationRevaluationReserve        AS DepreciationRevaluationReserve,
		|	FATable.DepreciationRevaluationReserveLocal    AS DepreciationRevaluationReserveLocal,
		|	FATable.RowID                AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryFixedAssetDepreciationCharge) AS BusinessTransactionSetting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND (FATable.AccumulatedDepreciationManagementAccounting <> 0
		|		OR FATable.AccumulatedDepreciationAccounting <> 0
		|		OR FATable.DepreciationRevaluationReserve <> 0
		|		OR FATable.DepreciationRevaluationReserveLocal <> 0)";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIACost(QueryTexts, Registers)

	RegisterName = "IACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableIACost();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	Table.IntangibleAsset                  AS IntangibleAsset,
		|	Table.FinancialAccountingGroup               AS FinancialAccountingGroup,
		|	Table.LineOfBusiness              AS LineOfBusiness,
		|	&RecordInLocalAccounting                          AS RecordInLocalAccounting,
		|	&RecordInManAccounting                           AS RecordInManAccounting,
		|	Table.CurrentcCostManAcc                   AS Cost,
		|	Table.CurrentcCostFinAcc                   AS LocalCost,
		|	Table.CostRevaluationReserve            AS CostRevaluationReserve,
		|	Table.CostRevaluationReserveLocal        AS CostRevaluationReserveLocal,
		|
		|	0 AS CostGainMA,
		|	0 AS CostGainLocal,
		|
		|	Table.RowID                  AS FinRecordID,
		|	VALUE(Enum.BusinessTransactions.OBEntryIntangibleAssetsValuesAndRDExpenses) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryIntangibleAssetsValuesAndRDExpenses) AS BusinessTransactionSetting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|WHERE
		|	Table.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND (Table.CurrentcCostManAcc <> 0
		|		OR Table.CurrentcCostFinAcc <> 0
		|		OR Table.CostRevaluationReserve <> 0
		|		OR Table.CostRevaluationReserveLocal <> 0)
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	Table.IntangibleAsset                  AS IntangibleAsset,
		|	Table.FinancialAccountingGroup               AS FinancialAccountingGroup,
		|	Table.LineOfBusiness              AS LineOfBusiness,
		|	&RecordInLocalAccounting                          AS RecordInLocalAccounting,
		|	&RecordInManAccounting                           AS RecordInManAccounting,
		|	0                                            AS Cost,
		|	0                                            AS LocalCost,
		|	0                                            AS CostRevaluationReserve,
		|	0                                            AS CostRevaluationReserveLocal,
		|
		|	CASE 
		|		WHEN (Table.CostRevaluationReserve - Table.DepreciationRevaluationReserve) > 0
		|			THEN Table.CostRevaluationReserve - Table.DepreciationRevaluationReserve
		|		ELSE 0
		|	END AS CostGainMA,
		|
		|	CASE 
		|		WHEN (Table.CostRevaluationReserveLocal - Table.DepreciationRevaluationReserveLocal) > 0
		|			THEN Table.CostRevaluationReserveLocal - Table.DepreciationRevaluationReserveLocal
		|		ELSE 0
		|	END AS CostGainLocal,
		|
		|	Table.RowID                  AS FinRecordID,
		|	VALUE(Enum.BusinessTransactions.OBEntryIntangibleAssetsValuesAndRDExpenses) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryIntangibleAssetsValuesAndRDExpenses) AS BusinessTransactionSetting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|WHERE
		|	Table.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND ((Table.CostRevaluationReserve - Table.DepreciationRevaluationReserve) > 0
		|		OR (Table.CostRevaluationReserveLocal - Table.DepreciationRevaluationReserveLocal) > 0)";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = EntryOfCapitalAssetsBalanceLocalization.QueryTextTableIntangibleAssetsAmortizationCharge();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	&Ref                                      AS Recorder,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	Table.IntangibleAsset                  AS IntangibleAsset,
		|	Table.FinancialAccountingGroup               AS FinancialAccountingGroup,
		|	Table.LineOfBusiness              AS LineOfBusiness,
		|	VALUE(Enum.BusinessTransactions.OBEntryIntangibleAssetsAmortizationChargeAndWritingOffRDExpenses)  AS BusinessOperation,
		|	Table.AccumulatedDepreciationManagementAccounting             AS Depreciation,
		|	Table.AccumulatedDepreciationAccounting             AS DepreciationLocal,
		|	Table.DepreciationRevaluationReserve          AS DepreciationRevaluationReserve,
		|	Table.DepreciationRevaluationReserveLocal      AS DepreciationRevaluationReserveLocal,
		|	Table.RowID                  AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryIntangibleAssetsAmortizationChargeAndWritingOffRDExpenses) AS BusinessTransactionSetting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.IA AS Table
		|WHERE
		|	Table.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND (Table.AccumulatedDepreciationManagementAccounting <> 0
		|		OR Table.AccumulatedDepreciationAccounting <> 0
		|		OR Table.DepreciationRevaluationReserve <> 0
		|		OR Table.DepreciationRevaluationReserveLocal <> 0)";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableLeasedAsset(QueryTexts, Registers)

	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	FATable.InitialCostTA AS Cost,
	|	FATable.Contract.Partner     AS Partner,
	|	FATable.Contract.Counterparty  AS Counterparty,
	|	FATable.Contract             AS Contract,
	|	VALUE(Enum.FixedAssetsStates.InLease) AS State
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|
	|		INNER JOIN Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets)
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	FATable.SecurityDepositValue  AS Cost,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	&Counterparty                   AS Counterparty,
	|	FATable.Contract             AS Contract,
	|	VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting) AS State
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|
	|		INNER JOIN Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets),
	|		VALUE(Enum.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableAssetsLeasedOut(QueryTexts, Registers)

	RegisterName = "AssetsLeasedOut";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                         AS Period,
	|	&Period                         AS TransferDate,
	|	&Organization                    AS Organization,
	|	&Counterparty                     AS Counterparty,
	|	&RentalContract         AS Contract,
	|	FATable.SecurityDepositValue    AS SecurityDepositValue,
	|	FATable.FixedAsset      AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.LeasedOut) AS State
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		INNER JOIN Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty),
	|		VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))";

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers)

	RegisterName = "TermsOfLeaseContracts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                       AS Recorder,
	|	&Period                                       AS Period,
	|	Calculations.Contract                               AS Contract,
	|	Calculations.SecurityDepositAmount          AS SecurityDepositAmount,
	|	Calculations.LeaseServicesAmount                    AS LeaseServicesAmount,
	|	Calculations.AmountOfLeaseAssetsByuout            AS AmountOfLeaseAssetsByuout,
	|	Calculations.InterestAmount                        AS InterestAmount,
	|	Calculations.VATAmount                              AS VATAmount,
	|	Calculations.VATRate                             AS VATRate,
	|	Calculations.TermYears                               AS TermYears,
	|	Calculations.TermMonths                               AS TermMonths,
	|	Calculations.TermDays                              AS TermDays,
	|	Calculations.LeaseStartDate                      AS LeaseStartDate,
	|	Calculations.DateOfFirstPayment                    AS DateOfFirstPayment,
	|	Calculations.DateOfFirstSecurityPayment    AS DateOfFirstSecurityPayment,
	|	Calculations.BuyoutDate                            AS BuyoutDate,
	|	Calculations.InterestRate                      AS InterestRate,
	|	Calculations.PaymentFrequency                    AS PaymentFrequency,
	|	Calculations.AccrualFrequency               AS AccrualFrequency,
	|	Calculations.LeaseItemsCost              AS LeaseItemsCost,
	|	Calculations.PaymentForLeaseService                  AS PaymentForLeaseService,
	|	Calculations.AccrualOfLeaseService              AS AccrualOfLeaseService,
	|	&Ref                                       AS EffectiveContractTerms,
	|	VALUE(Enum.CounterpartyContractStates.Valid) AS State
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|WHERE
	|	Calculations.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Function QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesPaymentSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS ChangeDate,
	|	Calculations.Contract                         AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	ChartTable.Date                     AS Date,
	|	ChartTable.RentalService           AS RentalService,
	|	ChartTable.RentalServiceVAT        AS RentalServiceVAT,
	|
	|	CASE 
	|		WHEN Calculations.Contract.HasSecurityDeposit
	|			THEN ChartTable.DepositPayment
	|		ELSE 0
	|	END AS DepositPayment,
	|
	|	CASE 
	|		WHEN Calculations.Contract.HasSecurityDeposit
	|			THEN ChartTable.SecurityPaymentVATAmount
	|		ELSE 0
	|	END AS SecurityPaymentVATAmount,
	|
	|	CASE 
	|		WHEN ChartTable.Date >= Calculations.BuyoutDate
	|				AND Calculations.Contract.ThereIsBuyoutOfLeasedAssets
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END AS BuyoutValue,
	|
	|	CASE 
	|		WHEN ChartTable.Date < Calculations.BuyoutDate
	|				AND Calculations.Contract.ThereIsBuyoutOfLeasedAssets
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END AS BuyoutValuePrepayment,
	|
	|	CASE 
	|		WHEN Calculations.Contract.ThereIsBuyoutOfLeasedAssets
	|			THEN ChartTable.BuyoutValueVAT
	|		ELSE 0
	|	END AS BuyoutValueVAT
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.ServicePaymentSchedule AS ChartTable
	|
	|		INNER JOIN Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|		ON Calculations.Ref = ChartTable.Ref
	|			AND Calculations.RowCode = ChartTable.RowCode
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS ChangeDate,
	|	Calculations.Contract                         AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	ChartTable.Date                     AS Date,
	|	ChartTable.RentalService           AS RentalService,
	|	ChartTable.RentalServiceVAT        AS RentalServiceVAT,
	|
	|	CASE 
	|		WHEN Calculations.Contract.HasSecurityDeposit
	|			THEN ChartTable.DepositPayment
	|		ELSE 0
	|	END AS DepositPayment,
	|
	|	CASE 
	|		WHEN Calculations.Contract.HasSecurityDeposit
	|			THEN ChartTable.SecurityPaymentVATAmount
	|		ELSE 0
	|	END AS SecurityPaymentVATAmount,
	|
	|	CASE 
	|		WHEN Calculations.BuyoutDate = ChartTable.Date
	|				AND Calculations.Contract.ThereIsBuyoutOfLeasedAssets
	|			THEN Calculations.AmountOfLeaseAssetsByuout
	|		ELSE 0
	|	END AS BuyoutValue,
	|
	|	CASE 
	|		WHEN Calculations.BuyoutDate = ChartTable.Date
	|				AND Calculations.Contract.ThereIsBuyoutOfLeasedAssets
	|			THEN Calculations.AmountOfVATRepurchaseOfRentalItems
	|		ELSE 0
	|	END AS BuyoutValueVAT
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.ServiceAccrualSchedule AS ChartTable
	|		INNER JOIN Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|		ON Calculations.Ref = ChartTable.Ref
	|			AND Calculations.RowCode = ChartTable.RowCode
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                 AS ChangeDate,
	|	Calculations.Contract                         AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	Calculations.BuyoutDate                      AS Date,
	|	0                                       AS RentalService,
	|	0                                       AS RentalServiceVAT,
	|	0                                       AS DepositPayment,
	|	0                                       AS SecurityPaymentVATAmount,
	|	Calculations.AmountOfLeaseAssetsByuout      AS BuyoutValue,
	|	Calculations.AmountOfVATRepurchaseOfRentalItems   AS BuyoutValueVAT
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.ServiceAccrualSchedule AS ChartTable
	|		ON ChartTable.Ref = Calculations.Ref
	|			AND ChartTable.Date = Calculations.BuyoutDate
	|			AND ChartTable.RowCode = Calculations.RowCode
	|WHERE
	|	Calculations.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND ChartTable.Ref IS NULL
	|	AND Calculations.AmountOfLeaseAssetsByuout <> 0
	|	AND Calculations.Contract.ThereIsBuyoutOfLeasedAssets
	|	AND Calculations.BuyoutDate <> DATETIME(1, 1, 1)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseInterestAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                    AS ChangeDate,
	|	Calculations.Contract            AS Contract,
	|	&Ref                    AS EffectiveContractTerms,
	|	ChartTable.Date        AS Date,
	|	ChartTable.Interests    AS Interests
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.InterestAccrualSchedule AS ChartTable
	|		INNER JOIN Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|		ON Calculations.Ref = ChartTable.Ref
	|			AND Calculations.RowCode = ChartTable.RowCode
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND &LeaseAccountingAccordingToFSB25_2018IsUsed";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeAnalyticsKeysForPartners(Query);
	
	QueryText = 
	"SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.LeaseLiabilitiesDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.LeaseObligationsBalance                                 AS Sum,
	|	DocumentData.LeaseLiabilityBalanceMan                              AS SumMan,
	|	DocumentData.LeaseLiabilityBalanceLocal                             AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND (DocumentData.LeaseObligationsBalance <> 0
	|		OR DocumentData.LeaseLiabilityBalanceMan <> 0
	|		OR DocumentData.LeaseLiabilityBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.BuyoutValueDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue)                AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.BuyoutValueBalance                                     AS Sum,
	|	DocumentData.BuyoutValueBalanceMan                                  AS SumMan,
	|	DocumentData.BuyoutValueBalanceLocal                                 AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND (DocumentData.BuyoutValueBalance <> 0
	|		OR DocumentData.BuyoutValueBalanceMan <> 0
	|		OR DocumentData.BuyoutValueBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.VATDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)                              AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.VATBalance                                                   AS Sum,
	|	DocumentData.VATBalanceMan                                                AS SumMan,
	|	DocumentData.VATBalanceLocal                                               AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND (DocumentData.VATBalance <> 0
	|		OR DocumentData.VATBalanceMan <> 0
	|		OR DocumentData.VATBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.InterestDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                         AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.InterestsBalance                                              AS Sum,
	|	DocumentData.InterestBalanceMan                                           AS SumMan,
	|	DocumentData.InterestBalanceLocal                                          AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND (DocumentData.InterestsBalance <> 0
	|		OR DocumentData.InterestBalanceMan <> 0
	|		OR DocumentData.InterestBalanceLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	CASE
	|		WHEN DocumentData.RentalServiceDebitBalance THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	DocumentData.Contract                                                      AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.RentalService)                   AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	DocumentData.Contract.ARAPCurrency                                 AS Currency,
	|	
	|	DocumentData.RentalServiceBalance                                        AS Sum,
	|	DocumentData.RentalServiceBalanceMan                                     AS SumMan,
	|	DocumentData.RentalServiceBalanceLocal                                    AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS DocumentData
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND (DocumentData.RentalServiceBalance <> 0
	|		OR DocumentData.RentalServiceBalanceMan <> 0
	|		OR DocumentData.RentalServiceBalanceLocal <> 0)
	|
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	Calculations.Contract                                                              AS Contract,
	|	DocumentData.PaymentType                                                   AS AmountType,
	|	DocumentData.ARAPDocument                                            AS ARAPDocument,
	|	Calculations.Contract.ARAPCurrency                                         AS Currency,
	|	
	|	DocumentData.Sum                                                        AS Sum,
	|	DocumentData.SumMan                                                     AS SumMan,
	|	DocumentData.SumCompl                                                    AS SumCompl,
	|	
	|	DocumentData.RowID                                          AS FinRecordID,
	|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.PrepaymentsUnderLeaseContracts AS DocumentData
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|		ON Calculations.Ref = DocumentData.Ref
	|			AND Calculations.RowCode = DocumentData.RowCode
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryLeaseContractsARAP)
	|	AND (DocumentData.Sum <> 0
	|		OR DocumentData.SumMan <> 0
	|		OR DocumentData.SumCompl <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCGUComposition(QueryTexts, Registers)
	
	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.Ref               AS Recorder,
	|	FATable.Ref.Date          AS Period,
	|	FATable.Ref.Organization   AS Organization,
	|	FATable.FixedAsset     AS NonCurrentAsset,
	|	FATable.CGU                 AS CGU
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND FATable.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfIA.Ref              AS Recorder,
	|	TableOfIA.Ref.Date         AS Period,
	|	TableOfIA.Ref.Organization  AS Organization,
	|	TableOfIA.IntangibleAsset AS NonCurrentAsset,
	|	TableOfIA.CGU                AS CGU
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.IA AS TableOfIA
	|
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND TableOfIA.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableImpairmentFA(QueryTexts, Registers)
	
	RegisterName = "ImpairmentFA";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	FATable.Ref                       AS Recorder,
	|	FATable.Ref.Date                  AS Period,
	|	FATable.Ref.Organization           AS Organization,
	|	FATable.FixedAsset             AS NonCurrentAsset,
	|	FATable.CGU                         AS CGU,
	|	&FixedAssetsLocation                       AS Department,
	|	FATable.LineOfBusiness      AS LineOfBusiness,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	FATable.ImpairmentAC                AS ImpairmentLocalAssets,
	|	FATable.ImpairmentMA                AS ImpairmenMan,
	|	FATable.RowID          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EnterBalanceOfFAImpairment) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (FATable.ImpairmentAC <> 0
	|		OR FATable.ImpairmentMA <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableOfIA.Ref                      AS Recorder,
	|	TableOfIA.Ref.Date                 AS Period,
	|	TableOfIA.Ref.Organization          AS Organization,
	|	TableOfIA.IntangibleAsset         AS NonCurrentAsset,
	|	TableOfIA.CGU                        AS CGU,
	|	&FixedAssetsLocation                       AS Department,
	|	TableOfIA.LineOfBusiness     AS LineOfBusiness,
	|	TableOfIA.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	TableOfIA.ImpairmentAC               AS ImpairmentLocalAssets,
	|	TableOfIA.ImpairmentMA               AS ImpairmenMan,
	|	TableOfIA.RowID         AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EnterBalanceOfIAImpairment) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.IA AS TableOfIA
	|
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (TableOfIA.ImpairmentAC <> 0
	|		OR TableOfIA.ImpairmentMA <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)

	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	TTDataCosts.Date                    AS Period,
	|	TTDataCosts.Organization             AS Organization,
	|	TTDataCosts.Department           AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem          AS ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses       AS DimensionOfExpenses,
	|	TTDataCosts.VATActivityType      AS VATActivityType,
	|
	|	TTDataCosts.Sum                   AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT             AS AmountExcludingVAT,
	|	TTDataCosts.AmountExcludingVAT             AS AmountExcludingVATMan,
	|
	|	TTDataCosts.SumCompl               AS AmountIncludingVATCompl,
	|	TTDataCosts.SumCompl
	|		- TTDataCosts.VATLocal           AS AmountExcludingVATCompl,
	|	TTDataCosts.AmountPermanentDifferences                 AS PermanentDifference,
	|	TTDataCosts.AmountTemporaryDifferences                 AS CostTD,
	|	CASE
	|		WHEN TTDataCosts.Date < &AccountingStartDate
	|				AND (TTDataCosts.Sum < 0 OR TTDataCosts.AmountExcludingVAT < 0 OR TTDataCosts.SumCompl < 0)
	|			THEN VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses)
	|		ELSE &BusinessOperation                  
	|	END AS BusinessOperation,
	|
	|	UNDEFINED                                   AS ItemsLocationAttributes,
	|	TTDataCosts.FinRecordID         AS FinRecordID,
	|	TTDataCosts.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTDataCosts AS TTDataCosts";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataCosts(Query, QueryTexts)
	
	RegisterName = "TTDataCosts";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Organization                                       AS Organization,
	|	&Period                                            AS Date,
	|	DocumentDataExpenses.LineNumber                 AS LineNumber,
	|	DocumentDataExpenses.Department               AS Department,
	|	DocumentDataExpenses.LineOfBusiness     AS LineOfBusiness,
	|	DocumentDataExpenses.ExpenseItem              AS ExpenseItem,
	|	DocumentDataExpenses.NonCurrentAsset           AS DimensionOfExpenses,
	|	DocumentDataExpenses.Ref                      AS ExpenseReceiptDocument,
	|
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			   AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	   AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes    AS LotVendorAttributes,
	|
	|	DocumentDataExpenses.Sum                       AS Sum,
	|	DocumentDataExpenses.AmountExcludingVAT                 AS AmountExcludingVAT,
	|	DocumentDataExpenses.SumCompl                   AS SumCompl,
	|	0                                                  AS VATLocal,
	|	DocumentDataExpenses.AmountPermanentDifferences                     AS AmountPermanentDifferences,
	|	DocumentDataExpenses.AmountTemporaryDifferences                     AS AmountTemporaryDifferences,
	|
	|	DocumentDataExpenses.RowID         AS FinRecordID,
	|	&BusinessTransactionSetting                    AS BusinessTransactionSetting
	|
	|INTO TTDataCosts
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.OtherExpenses AS DocumentDataExpenses
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		DocumentDataExpenses.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber = DocumentDataExpenses.LineNumber
	|
	|WHERE
	|	DocumentDataExpenses.Ref = &Ref
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""OtherExpenses""														AS TabularSectionName,
	|	DocumentTable.LineNumber 											AS LineNumber,
	|	VALUE(Catalog.Partners.EmptyRef)								AS Vendor,
	|	VALUE(Catalog.Counterparties.EmptyRef)                           AS Counterparty,
	|	UNDEFINED 												            AS VATRate,
	|	CASE WHEN ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) =
	|	  VALUE(Enum.SeparateVATAccountingOptions.Allocation) 
	|		THEN VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|		ELSE DocumentData.VATTaxation
	|	END 																	AS VATTaxation,
	|	ARTICLES__.VATAssetTaxClass 													AS AssetTaxClass,
	|	0																		AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.OtherExpenses AS DocumentTable
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
	|	LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                        AS Period,
	|	&Organization                   AS Organization,
	|	BEGINOFPERIOD(&Period, DAY)   AS DateRecord,
	|	&BusinessOperation         AS BusinessOperation
	|WHERE
	|	&Period >= &AccountingStartDate
	|
	|UNION
	|
	|SELECT
	|	&Period                AS Period,
	|	&Counterparty            AS Organization,
	|	BEGINOFPERIOD(&Period, DAY)   AS DateRecord,
	|	&BusinessOperation AS BusinessOperation
	|WHERE
	|	&Period >= &AccountingStartDate
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty),
	|		VALUE(Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut))
	|	AND &LeaseholderIntercompanyARAP";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = "
	|SELECT DISTINCT
	|	&Organization                                           AS Organization,
	|	&Partner                                               AS Partner,
	|	&Counterparty                                            AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.EntryOfCapitalAssetsBalance2_4.LeaseContractsARAP AS Calculations
	|		
	|		INNER JOIN Catalog.LeaseContract AS ContractData
	|		ON Calculations.Contract = ContractData.Ref
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON Dimension.Organization = &Organization
	|			AND Dimension.Counterparty = &Counterparty
	|			AND Dimension.Partner = &Partner
	|			AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND Dimension.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Calculations.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|";
	
	QueryAnalyst.SetParameter("Ref",      Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	QueryAnalyst.SetParameter("Partner",     Query.Parameters.Partner);
	QueryAnalyst.SetParameter("Counterparty",  Query.Parameters.Counterparty);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

#EndRegion

#Region ConductingRegulatedAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return EntryOfCapitalAssetsBalanceLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return EntryOfCapitalAssetsBalanceLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	#Region FA
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.FA";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.FA";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region IA
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.IA";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.IA";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	#EndRegion
	
	EntryOfCapitalAssetsBalanceLocalization.AddOptionsForSelectingArticlesAndAnalytics(ItemsAndDimensionsSelectionParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

Procedure UpdateDataInLinkedTable(TS, NewData, RowCode) Export
	
	SearchForStrings = New Structure("RowCode", RowCode);
	LinesToDelete = TS.FindRows(SearchForStrings);
	
	For Each TableRow In LinesToDelete Do
		TS.Delete(TableRow);
	EndDo;
	
	For Each TableRow In NewData Do
		NewRow = TS.Add();
		FillPropertyValues(NewRow, TableRow);
		NewRow.RowCode = RowCode;
	EndDo;
	
EndProcedure

Procedure FillInAmountOfVATSettlementsUnderLeaseAgreements(Object) Export
	
	For Each RowData In Object.LeaseContractsARAP Do
		
		VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(RowData.VATRate);

		RowData.AmountOfVATRepurchaseOfRentalItems = VATAccountingERPClientServer.CalculateVATAmount(
			RowData.AmountOfLeaseAssetsByuout, VATPercentage, True);
	
		TheStructureOfTheSearch = New Structure("RowCode", RowData.RowCode);
		StringsList = Object.ServiceAccrualSchedule.FindRows(TheStructureOfTheSearch);
		For Each PlotLine In StringsList Do
			PlotLine.RentalServiceVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.RentalService, VATPercentage, True);
			PlotLine.SecurityPaymentVATAmount = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.DepositPayment, VATPercentage, True);
		EndDo;
		
		TheStructureOfTheSearch = New Structure("RowCode", RowData.RowCode);
		StringsList = Object.ServicePaymentSchedule.FindRows(TheStructureOfTheSearch);
		For Each PlotLine In StringsList Do
			PlotLine.RentalServiceVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.RentalService, VATPercentage, True);
			PlotLine.SecurityPaymentVATAmount = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.DepositPayment, VATPercentage, True);
			PlotLine.BuyoutValueVAT = VATAccountingERPClientServer.CalculateVATAmount(PlotLine.BuyoutValue, VATPercentage, True);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
