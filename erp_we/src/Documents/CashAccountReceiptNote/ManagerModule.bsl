#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CashAccount";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CashAccount, Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Cashier", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("PlanningCashControl");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CashAccountReceiptNoteLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CashAccountReceiptNote") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	Else
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashAccountBalance(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextCashInTransit(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		
		CashAccountReceiptNoteLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CashAccountReceiptNote, DocumentRef.CashAccountReceiptNote, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	If TypeOf(Object) = Type("DocumentObject.CashAccountReceiptNote")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.CashAccountReceiptNote") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Organization,Contract,Warehouse,Date,LineOfBusiness,BusinessOperation");
	EndIf;
	
	FillParameters.Organization = ObjectData.Organization;
	FillParameters.Date = ObjectData.Date;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	FillParameters.Department = ObjectData.Department;
	
	FillParameters.GoodsSales = True;
	FillParameters.ImplementationOfWorksServices = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.CashAccountReceiptNote - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period  = Object.Date;
	
	FillParameters.PurchaseOfGoods = True;
	FillParameters.AcquisitionOfWorks = True;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

#Region Other

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	If GetFunctionalOption("UseVATAccounting") Then
		Documents.IssuedTaxInvoicePrepayment.AddGenerateCommand(GenerationCommands);
	EndIf;
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	CreateCommandBasedOnApplication = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	EconomicOperationsForInputOnBasisOf = New Array;
	EconomicOperationsForInputOnBasisOf.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	EconomicOperationsForInputOnBasisOf.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	
	If CreateCommandBasedOnApplication <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication,
															"BusinessOperation",
															EconomicOperationsForInputOnBasisOf,
															DataCompositionComparisonType.InList);
	EndIf;
	
	CreationTeamBasedOnACW = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	If CreationTeamBasedOnACW <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreationTeamBasedOnACW,
															"BusinessOperation",
															EconomicOperationsForInputOnBasisOf,
															DataCompositionComparisonType.InList);
	EndIf;
	
	CashAccountReceiptNoteLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "cash Receipt order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CashAccountReceiptNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CashAccountReceiptNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CashAccountReceiptNote);
		CreateBasedOnCommand.WriteMode = "Post";
		
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	CashAccountReceiptNoteLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The function gets the details of the document to exchange with the "enterprise Accounting" configuration.
//
// Parameters:
//	DocumentRef - DocumentRef - The document for which you need to get the banking details.
//
// Returns:
//	Structure - The structure of the document details.
//
Function DocumentDetailsForExchangeWithAccounting(DocumentRef) Export
	
	Query = New Query("
	|SELECT TOP 1
	|	DocumentData.CashFlowItem.OffsettingAccount AS OffsettingAccount,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.CashAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CashFlowItem.OffsettingAccount <> """"
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DocumentData.IncomeItem.OffsettingAccount AS OffsettingAccount,
	|	DocumentData.IncomeItem AS IncomeItem
	|FROM
	|	Document.CashAccountReceiptNote.ARAPDetails AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherIncome)
	|	AND DocumentData.IncomeItem.OffsettingAccount <> """"
	|
	|ORDER BY
	|	DocumentData.LineNumber
	|");
	Query.SetParameter("Ref", DocumentRef);
	ResultsArray = Query.ExecuteBatch();
	
	Selection = ResultsArray[0].Select();
	If Selection.Next() Then
		OffsettingAccount = Selection.OffsettingAccount;
		BusinessOperation = Selection.BusinessOperation;
	Else
		OffsettingAccount = "";
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
	Selection = ResultsArray[1].Select();
	If Selection.Next() Then
		OffsettingAccount = Selection.OffsettingAccount;
		IncomeItem = Selection.IncomeItem;
	Else
		IncomeItem = Undefined;
	EndIf;
	
	OperationKind = "OtherReceipt";
	
	If BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		
		If StrFind(OffsettingAccount, "66") <> 0
		 Or StrFind(OffsettingAccount, "67") <> 0 Then
			OperationKind = "SettlementsOnLoansAndBorrowings";
		EndIf;
		
	EndIf;
	
	AttributesStructure1 = New Structure("OperationKind, Account, IncomeItem",
		OperationKind,
		OffsettingAccount,
		IncomeItem);
	
	Return AttributesStructure1;
		
EndFunction

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("BankAccount");
	ArrayOfAllProps.Add("CurrencyOfConversion");
	ArrayOfAllProps.Add("IncludingVAT");
	ArrayOfAllProps.Add("CashRegister");
	ArrayOfAllProps.Add("CashAccountIssuer");
	ArrayOfAllProps.Add("Counterparty");
	ArrayOfAllProps.Add("ConversionRate");
	ArrayOfAllProps.Add("ConversionRateMultiplier");
	ArrayOfAllProps.Add("ConversionAmount");
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("CashTransferReferenceOrder");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("Department");
	
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("LineOfBusiness");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("VATTaxation");
	
	ArrayOfAllProps.Add("ARAPDetails");
	ArrayOfAllProps.Add("ARAPDetails.ARAPCurrency");
	ArrayOfAllProps.Add("ARAPDetails.LoanDepositContract");
	ArrayOfAllProps.Add("ARAPDetails.EmployeeLoanAgreement");
	ArrayOfAllProps.Add("ARAPDetails.ARAPObject");
	ArrayOfAllProps.Add("ARAPDetails.PaymentPurpose");
	ArrayOfAllProps.Add("ARAPDetails.Partner");
	ArrayOfAllProps.Add("ARAPDetails.Department");
	ArrayOfAllProps.Add("ARAPDetails.CashFlowItem");
	ArrayOfAllProps.Add("ARAPDetails.AmountARAP");
	ArrayOfAllProps.Add("ARAPDetails.VATRate");
	ArrayOfAllProps.Add("ARAPDetails.VATAmount");
	ArrayOfAllProps.Add("ARAPDetails.LoanAndDepositAmountType");
	ArrayOfAllProps.Add("ARAPDetails.Organization");
	ArrayOfAllProps.Add("ARAPDetails.LineOfBusiness");
	ArrayOfAllProps.Add("ARAPDetails.LeaseContracts");
	ArrayOfAllProps.Add("ARAPDetails.TypeOfLeasePayment");
	ArrayOfAllProps.Add("ARAPDetails.ARAPDocumentForLease");
	ArrayOfAllProps.Add("ARAPDetails.MaturityDate");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("IncludingVAT");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister Then
		ArrayOfOperationDetails.Add("CashRegister");
		ArrayOfOperationDetails.Add("IncludingVAT");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("IncludingVAT");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank Then
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank Then
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount Then
		ArrayOfOperationDetails.Add("CashAccountIssuer");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		ArrayOfOperationDetails.Add("IncludingVAT");
		ArrayOfOperationDetails.Add("CashAccountIssuer");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		If BusinessOperation <> Enums.BusinessTransactions.RefundFromAnotherCompany Then
			ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("IncludingVAT");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Department");
		ArrayOfOperationDetails.Add("ARAPDetails.LineOfBusiness");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ArrayOfOperationDetails.Add("IncludingVAT");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("CashAccountIssuer");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("CurrencyOfConversion");
		ArrayOfOperationDetails.Add("ConversionRate");
		ArrayOfOperationDetails.Add("ConversionRateMultiplier");
		ArrayOfOperationDetails.Add("ConversionAmount");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
		
		ArrayOfOperationDetails.Add("Counterparty");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		If BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
			ArrayOfOperationDetails.Add("ARAPDetails.LoanAndDepositAmountType");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanAndDepositAmountType");
		ArrayOfOperationDetails.Add("ARAPDetails.EmployeeLoanAgreement");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
		ArrayOfOperationDetails.Add("Counterparty");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.LeaseContracts");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.TypeOfLeasePayment");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPDocumentForLease");
	EndIf;
	
EndProcedure

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.ARAPDetails";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	ChoiceParameters.FormItems.AssetRef.Add("DecodingWithoutSplittingTheIncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("ARAPDetailsIncomeItem");
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt);
	
	CostAllocationOptions = New Array();
	CostAllocationOptions.Add(Enums.CostAllocationOptions.DoNotAllocate);
	CostAllocationOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	CostAllocationOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = CostAllocationOptions;
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DecodingWithoutSplittingTheAssetLiabilityAnalysis");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ARAPDetailsAssetsLiabilitiesDimension");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DecodingWithoutSplittingTheExpenseAnalyst");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ARAPDetailsDimensionOfExpenses");
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DecodingWithoutSplittingTheRevenueAnalyst");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("ARAPDetailsDimensionOfRevenue");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	Operations = Enums.BusinessTransactions;
	
	#Region Header
	// AdvanceHolder
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Người lao động';
										|ru = 'Работник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Employee';
										|tr = 'Çalışan'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Item.Properties.Insert("Title", NStr("vi = 'Người nhận tạm ứng';
										|ru = 'Подотчетное лицо';
										|en = 'Advance holder'; fa = 'تنخواه‌دار';
										|it = 'Titolare di anticipo';
										|pl = 'Osoba rozliczająca się za wydatki';
										|tr = 'Sorumlu kişi'"));
	
	// BankAccount
	Item = Settings.Add();
	Item.Fields.Add("BankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashCollectionFromBank);
	Item.Properties.Insert("Visible");
	
	// CashAccountIssuer
	Item = Settings.Add();
	Item.Fields.Add("CashAccountIssuer");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromAnotherCashAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Item.Properties.Insert("Visible");
	
	// CashRegister
	Item = Settings.Add();
	Item.Fields.Add("CashRegister");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCashRegister);
	Item.Properties.Insert("Visible");
	
	// LabelCurrency
	Item = Settings.Add();
	Item.Fields.Add("LabelCurrency");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", False);
	Item.Properties.Insert("Visible");
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Fields.Add("CounterpartyCheckIssueCounterpartyPages");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Nhà môi giới';
										|ru = 'Брокер';
										|en = 'Broker'; fa = 'کارگزار';
										|it = 'Брокер';
										|pl = 'Broker';
										|tr = 'Komisyoncu'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion, ,
		DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Title", NStr("vi = 'Người nộp';
										|ru = 'Плательщик';
										|en = 'Payer'; fa = 'پرداخت‌کننده';
										|it = 'Payer';
										|pl = 'Payer';
										|tr = 'Ödeyen'"));
	
	// IncludingVAT
	Item = Settings.Add();
	Item.Fields.Add("IncludingVAT");
	Item.Fields.Add("InsertVATInclusive");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCashRegister);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Item.Properties.Insert("Visible");
	
	// CashTransferReferenceOrder
	Item = Settings.Add();
	Item.Fields.Add("CashTransferReferenceOrder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashCollectionFromBank);
	Item.Properties.Insert("Visible");
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	// Department
	Item = Settings.Add();
	Item.Fields.Add("Department");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCashRegister);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Visible");
	
	// DocumentBasis
	Item = Settings.Add();
	Item.Fields.Add("DocumentBasis");
	Finances.NewFilter(Item.Condition, "DocumentBasis",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	#EndRegion
	
	#Region Attributes
	// Conversion
	Item = Settings.Add();
	Item.Fields.Add("CurrencyOfConversion");
	Item.Fields.Add("ConversionRate");
	Item.Fields.Add("ConversionAmount");
	Item.Fields.Add("ConversionRateMultiplier");
	Item.Fields.Add("CurrencyOfConversionRate");
	Item.Fields.Add("CurrencyOfConversionRateMultiplicity");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	#EndRegion
	
	#Region ARAPDetails
	// TheDecryptionPage
	Item = Settings.Add();
	Item.Fields.Add("TheDecryptionPage");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("Visible");
	
	// Analytics of other receipts
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Department");
	Item.Fields.Add("DecryptionWithoutDivisionDivision");
	Item.Fields.Add("ARAPDetails.LineOfBusiness");
	Item.Fields.Add("DecodingWithoutSplittingTheDirectionOfActivity");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.OtherCashReceipt);
	Item.Properties.Insert("Visible");
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.CashFlowItem");
	Item.Fields.Add("DecodingWithoutSplittingTheCashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("Visible");
	
	// The sum of the settlements, the currency of the settlements
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.AmountARAP");
	Item.Fields.Add("DecryptionWithoutSplittingTheAmountOfMutualSettlements");
	Item.Fields.Add("ARAPDetails.ARAPCurrency");
	Item.Fields.Add("DecryptionWithoutSplittingTheCurrencyOfMutualSettlements");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("Visible");
	
	// AmountARAP
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingTheAmountOfMutualSettlements");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Finances.NewFilter(Item.Condition, "More.ARAPCurrency", "Currency", , , True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("ReadOnly");
	
	// Decorations of the currency of the course of payment, the exchange rate of the account, the exchange rate of the sign of the account
	Item = Settings.Add();
	Item.Fields.Add("CurrencyDecorationAndPaymentRate");
	Item.Fields.Add("ARAPDetails.ExchangeRateNumeratorOfMutualSettlements");
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	Item.Fields.Add("ARAPDetails.CourseNumeratorOfMutualSettlementsText");
	Item.Fields.Add("DecodingOfThePaymentTheExchangeRateTheDenominatorOfMutualSettlementsTheInscription");
	Item.Fields.Add("ARAPDetails.ContractRateOption");
	Item.Fields.Add("DecodingWithoutSplittingIsVariantOfContractCourse");
	
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	
	Finances.NewFilter(Item.Condition, "Currency", "More.ARAPCurrency",, DataCompositionComparisonType.NotEqual, True);
	UnderGroupOr = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr, "More.MultipleARAPCurrency", True);
	Finances.NewFilter(UnderGroupOr, "More.ARAPCurrency", Catalogs.Currencies.EmptyRef(), , DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	// CurrencyDecorationAndPaymentRate
	Item = Settings.Add();
	Item.Fields.Add("CurrencyDecorationAndPaymentRate");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.ARAPCurrency",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(AndGroup, "More.ContractRateOption",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(AndGroup, "More.ExchangeRateNumeratorOfMutualSettlements", 0,, DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Enabled");
	
	// DecodingWithoutSplittingIsVariantOfContractCourse
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingIsVariantOfContractCourse");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "More.ContractRateOption", Enums.ContractRateOptions.SpecifiedInContract,, DataCompositionComparisonType.Equal);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.ContractRateOption", Enums.ContractRateOptions.FixedAsOfShipmentDate,, DataCompositionComparisonType.Equal);
	Finances.NewFilter(AndGroup, "More.ARAPObjectType", Enums.ARAPObjectTypes.Invoice,, DataCompositionComparisonType.Equal);
	Item.Properties.Insert("Hyperlink");
	
	// SummaNDS, StavkaNDS
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.VATAmount");
	Item.Fields.Add("DecryptionWithoutSplittingTheVATAmount");
	Item.Fields.Add("ARAPDetails.VATRate");
	Item.Fields.Add("DecodingWithoutSplittingTheVATRate");
	Item.Fields.Add("VATCurrency");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// The object of the accounts, the basis of the payment
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.PaymentPurpose");
	Item.Fields.Add("DecryptionWithoutSplittingTheBasisOfThePayment");
	Item.Fields.Add("ARAPDetails.ARAPObject");
	Item.Fields.Add("DecryptionWithoutSplittingTheCalculationObject");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// Partner
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Partner");
	Item.Fields.Add("DecryptionWithoutPartitioningPartner");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("Visible");
	
	// LoanDepositContract
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LoanDepositContract");
	Item.Fields.Add("DecryptionWithoutSplittingTheLoanDepositAgreement");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Item.Properties.Insert("Visible");
	
	// LoanAndDepositAmountType
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LoanAndDepositAmountType");
	Item.Fields.Add("DecryptionWithoutSplittingTheTypeOfLoanAmountDeposit");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Visible");
	
	// EmployeeLoanAgreement
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.EmployeeLoanAgreement");
	Item.Fields.Add("TranscriptWithoutSplittingTheLoanAgreementToTheEmployee");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Visible");
	
	// Contractual rents, type of payment in the Lease
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LeaseContracts");
	Item.Fields.Add("DecryptionWithoutSplittingTheLeaseAgreement");
	Item.Fields.Add("ARAPDetails.TypeOfLeasePayment");
	Item.Fields.Add("DecryptionWithoutSplittingTheTypeOfRentPayment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundFromLessor);
	Item.Properties.Insert("Visible");
	
	// ARAPDocumentForLease
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.ARAPDocumentForLease");
	Item.Fields.Add("DecryptionWithoutSplittingTheLeaseSettlementDocument");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundFromLessor);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "More.TypeOfLeasePayment", Enums.TypesOfLeasePayments.DepositPayment);
	Finances.NewFilter(OrGroup, "More.TypeOfLeasePayment", Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	Item.Properties.Insert("Visible");
	
	// Organization
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Organization");
	Item.Fields.Add("DecryptionWithoutSplittingTheOrganization");
	Finances.NewFilter(Item.Condition, "More.ThereAreBranches", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// HyperlinkPaymentObjectDetails
	Item = Settings.Add();
	Item.Fields.Add("HyperlinkPaymentObjectDetails");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// Unallocated payment
	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroup");
	Item.Fields.Add("LineOfBusiness");
	Item.Fields.Add("RPDivision");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundFromAnotherCompany,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundFromVendor,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "More.AmountUnallocated", 0,, DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroupOfRefund");
	Item.Fields.Add("DirectionOfReturnActivity");
	Item.Fields.Add("RocDivision");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Contract");
	
	AndGroup1 = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	OrGroup = Finances.NewFilter(AndGroup1,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(AndGroup2, "More.UseCustomerContracts", True);
	
	AndGroup3 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup3, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(AndGroup3, "More.UseIntercompanyContracts", True);
	
	Item.Properties.Insert("Visible");

	Item = Settings.Add();
	Item.Fields.Add("ReturnAgreement");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(AndGroup1, "More.UseIntercompanyContracts", True);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(AndGroup2, "More.UseContractsWithVendors", True);
	
	Item.Properties.Insert("Visible");
	
	// Settlement object agreement
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsContract");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "More.UseCustomerContracts", True);
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.CashReceiptFromCustomer);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "More.UseIntercompanyContracts", True);
	OrGroup2 = Finances.NewFilter(AndGroup2,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.RefundFromAnotherCompany);
	
	AndGroup3 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup3, "More.UseContractsWithVendors", True);
	OrGroup3 = Finances.NewFilter(AndGroup3,,, Type("DataCompositionFilterItemGroup"));
	OrGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup3, "BusinessOperation", Operations.RefundFromVendor);
	
	Item.Properties.Insert("Visible");
	
	// Maturity Date
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingRepaymentDate");
	Item.Fields.Add("ARAPDetailsMaturityDate");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	
	Item.Properties.Insert("Visible");
	
	// Course Accuracy
	CashServer.FillInConditionalAppearanceAccuracyOfCourse(Settings);
	
	#EndRegion
	
	#Region Commands
	Item = Settings.Add();
	Item.Fields.Add("FillInThePaymentExplanationOnLoansForCounterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("FillInThePaymentExplanationOnLoansForEmployee");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsSelectionByStock");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Item.Properties.Insert("Visible");
	#EndRegion
	
EndProcedure

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation");
		BusinessOperation = StructureFillingData.BusinessOperation;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
	EndIf;
	
	StructuresArray = New Array();
	
	#Region AllOtherFunctions
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	EndIf;
	
	ParametersStructure.ChangesPaymentPlan =
		BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany;
		
	ParametersStructure.ChangesCalculationsByString               =
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
		|	OR
		|//Conditions of return beginning
		|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
		|//Conditions of return end";
	
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		ParametersStructure.Counterparty                             = "Object.CashAccountIssuer.Owner";
		ParametersStructure.Partner                                = Catalogs.Partners.OurEnterprise;
	Else
		ParametersStructure.Counterparty                             = "Object.Counterparty";
		ParametersStructure.Partner                          = "Object.ARAPDetails.Partner";
	EndIf;
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Form.AmountARAP";
	ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
	ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
	ParametersStructure.ARAPObjectSettings                  = "";
	
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.Organization                      = "Object.Organization";
	ParametersStructure.Terms                       = "";
	ParametersStructure.Contract                          = "Object.Contract";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "Object.CashAccount";
	ParametersStructure.Date                             = "Object.Date";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Manager                         = "";
	ParametersStructure.IncomingDocumentNumber          = "";
	ParametersStructure.IncomingDocumentDate           = "";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	//Names of form elements for the current set of parameters
	ParametersStructure.FormItems.ARAPDetails               = "ARAPDetails";
	ParametersStructure.FormItems.AddToPaymentDecryption        = "ARAPDetailsSelectionByStock";
	
	ParametersStructure.SelectAccountsReceivable    = True;
	ParametersStructure.SelectOnlyUnconditionalDebt =
		BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany;
	
	ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
	ParametersStructure.DocumentCurrencyViewOnly      = True;
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region SettlementObjectReturn
	
	If BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.ARAPObject                   = "Object.ARAPObject";
		
		ParametersStructure.ChangesPaymentPlan               = True;
			
		ParametersStructure.ChangesCalculationsByString           =
			"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
			|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
			|	OR
			|//Conditions of return beginning
			|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
			|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
			|//Conditions of return end";
		
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		If BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
			ParametersStructure.Counterparty                             = "Object.CashAccountIssuer.Owner";
			ParametersStructure.Partner                                = Catalogs.Partners.OurEnterprise;
		Else
			ParametersStructure.Counterparty                             = "Object.Counterparty";
			ParametersStructure.Partner                                = "Object.ARAPDetails.Partner";
		EndIf;
		
		ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
		ParametersStructure.AmountARAP              = "Form.AmountARAP";
		ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
		ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
		ParametersStructure.ARAPObjectSettings                  = "";
		
		ParametersStructure.PaymentMethod                      = "";
		ParametersStructure.ForeignCurrencyTransaction                    = "";
		
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
		ParametersStructure.Organization                      = "Object.Organization";
		ParametersStructure.Terms                       = "";
		ParametersStructure.Contract                          = "Object.Contract";
		ParametersStructure.CompanyBankAccount        = "";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.CashAccount                            = "Object.CashAccount";
		ParametersStructure.Date                             = "Object.Date";
		ParametersStructure.PaymentID             = "";
		ParametersStructure.Manager                         = "";
		ParametersStructure.IncomingDocumentNumber          = "";
		ParametersStructure.IncomingDocumentDate           = "";
		ParametersStructure.VATTaxation               = "Object.VATTaxation";
		
		ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
		ParametersStructure.DocumentCurrencyViewOnly      = True;
		
		StructuresArray.Add(ParametersStructure);
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CashAccountReceiptNoteLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CashAccountReceiptNoteLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpReflectionAccountInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.ARAPDetails";
	SetupParameters.AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt;
	SetupParameters.ArticleType = "ArticleType";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";

	SetupParameters.FormItems.Add("DecodingWithoutSplittingRepresentationOfReflectionInReglAccounting");
	SetupParameters.FormItems.Add("ARAPDetailsPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(ARAPDetails.Organization) AND BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|	)AND ValueAllowed(CashAccount)
	|	AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) OR BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor) THEN ValueAllowed(ARAPDetails.Partner)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) THEN ValueAllowed(AdvanceHolder)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister) THEN ValueAllowed(CashRegister)
	|	ELSE TRUE END 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(CashAccount)
	|	AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) OR BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor) THEN ValueAllowed(ARAPDetails.Partner)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) THEN ValueAllowed(AdvanceHolder)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister) THEN ValueAllowed(CashRegister)
	|	ELSE TRUE END ";

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

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	DataSources.Insert("ARAPDetails.ARAPObject");
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	TemporaryTableQueryTexts = New Map;
	RedefiningParameterCalculation = New Structure;
	SynonymForDocumentTable = "";
	
	FullDocumentName = "Document.CashAccountReceiptNote";
	
	If RegisterName = "CashToBePaid" Then
		
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("PartnerFromDocument", "
				|	CASE
				|		WHEN
				|			DocumentData.BusinessOperation IN (
				|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
				|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
				|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
				|		THEN
				|			VALUE(Catalog.Partners.OurEnterprise)
				|		ELSE
				|			DocumentData.Partner
				|	END");
		RedefiningParameterCalculation.Insert("CounterpartyFromDocument", "
				|	CASE
				|		WHEN
				|			DocumentData.BusinessOperation IN (
				|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
				|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
				|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
				|		THEN
				|			DocumentData.CashAccountIssuer.Owner
				|		ELSE
				|			DocumentData.Counterparty
				|	END");
			
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
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
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable, RedefiningParameterCalculation, TemporaryTableQueryTexts);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS ThereIsGiftCertificate
	|INTO AvailabilityOfTypeOfSettlementObjectGiftCertificate
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS ARAPDetails
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (ARAPDetails.ARAPObject = ARAPObjects.Ref)
	|WHERE
	|	ARAPObjects.Object REFS Catalog.GiftCertificates
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashAccountSenderOwner AS SenderOrganization,
	|	DocumentData.CashAccountDivision AS Department,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
	|			AND DocumentData.CashAccountIssuer REFS Catalog.CashRegisters
	|		THEN CAST(DocumentData.CashAccountIssuer AS Catalog.CashRegisters).Warehouse
	|		ELSE DocumentData.CashRegisterKkmWarehouse
	|	END AS CashRegisterWarehouse,
	|	DocumentData.Basis AS Basis,
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			VALUE(Catalog.Partners.OurEnterprise)
	|	
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Partners.RetailCustomer)
	|	
	|	ELSE
	|		DocumentData.Partner
	|	END                                   AS Partner,
	|
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.CashAccountSenderOwner
	|	
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Counterparties.RetailCustomer)
	|	
	|	ELSE
	|		DocumentData.Counterparty
	|	END                                   AS Counterparty,
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE
	|			DocumentData.Partner
	|	END                                   AS PartnerFromDocument,
	|
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.CashAccountSenderOwner
	|		ELSE
	|			DocumentData.Counterparty
	|	END                                   AS CounterpartyFromDocument,
	|
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|
	|	CAST(DocumentData.CashAccount AS Catalog.CashAccounts).LineOfBusiness AS LineOfBusinessCash,
	|	
	|	DocumentData.AdvanceHolder         AS AdvanceHolder,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.CashAccount                   AS CashAccount,
	|	DocumentData.BankAccount          AS BankAccount,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Cashier                  AS Cashier,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted                AS Posted,
	|	ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE) AS ThereIsGiftCertificate,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting,
	|	DocumentData.DocumentBasis       AS DocumentBasis
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|		
	|		LEFT JOIN AvailabilityOfTypeOfSettlementObjectGiftCertificate AS AvailabilityOfGiftCertificateType
	|		ON TRUE
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = "SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.ReceivedFrom AS ReceivedFrom,
	|	DocumentData.Basis AS Basis,
	|	DocumentData.Application AS Application,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Author AS Author,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.CashTransferReferenceOrder AS CashTransferReferenceOrder,
	|	DocumentData.IncludingVAT AS IncludingVAT,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.CashAccountIssuer AS CashAccountIssuer,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.ConversionRate AS ConversionRate,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	DocumentData.IssuedLetterOfAuthority AS IssuedLetterOfAuthority,
	|	DocumentData.ConversionAmount AS ConversionAmount,
	|	DocumentData.Department AS Department,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Cashier AS Cashier,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.CashRegister.Warehouse AS CashRegisterKkmWarehouse,
	|	DocumentData.CashAccount.Department AS CashAccountDivision,
	|	DocumentData.CashAccountIssuer.Owner AS CashAccountSenderOwner,
	|	DocumentData.CashAccount.LineOfBusiness AS CashAccountLineOfBusiness,
	|	DocumentData.CashAccount.CashCurrency AS CashAccountCashCurrency,
	|	DocumentData.Counterparty.Partner AS CounterpartyPartner,
	|	DocumentData.BankAccount.LineOfBusiness AS BankAccountLineOfBusiness,
	|	DocumentData.CashAccountIssuer.LineOfBusiness AS CashAccountSenderLineOfBusiness
	|INTO DocumentDataHeader
	|FROM
	|	Document.CashAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests)
	
	QueryText = "SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.PaymentPurpose AS PaymentPurpose,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
	|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.RowID AS RowID,
	|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.Organization AS Organization,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.ARAPDocumentForLease AS ARAPDocumentForLease,
	|	PaymentDecryptionTable.ExchangeRateNumeratorOfMutualSettlements AS ExchangeRateNumeratorOfMutualSettlements,
	|	PaymentDecryptionTable.TheExchangeRateIsTheDenominatorOfMutualSettlements AS TheExchangeRateIsTheDenominatorOfMutualSettlements,
	|	PaymentDecryptionTable.MaturityDate AS MaturityDate,
	|	PaymentDecryptionTable.Organization.ParentCompany AS CompanyParentCompany,
	|	PaymentDecryptionTable.ARAPObject.Contract AS ARAPObjectContract,
	|	PaymentDecryptionTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	PaymentDecryptionTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	PaymentDecryptionTable.ARAPObject.Partner AS ARAPObjectIsPartner,
	|	PaymentDecryptionTable.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	PaymentDecryptionTable.ARAPObject.VATTaxation AS ARAPObjectTaxationOfVAT,
	|	CASE WHEN PaymentDecryptionTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|			THEN
	|				VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE
	|			PaymentDecryptionTable.Partner
	|	END AS ARAPObjectOfPaymentIsPartner
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.CashAccountReceiptNote"));
	Values.Insert("UseCustomerCommercialInvoices",               GetFunctionalOption("UseCustomerCommercialInvoices"));
	Values.Insert("UsePaymentRequests", GetFunctionalOption("UsePaymentRequests"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses",           GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("ControlIssueOfCashByPurposes",       GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		
		Values.Insert("CashFlowItem",               CashFlowArticleOfDocument(Attributes));
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency,
			Undefined,
			Attributes.Period,
			Attributes.Organization);
			
		ConversionFactors = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.CurrencyOfConversion,
			Undefined,
			Attributes.Period,
			Attributes.Organization);
		
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
		ConversionRateToConversionCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Attributes.Currency,
			Attributes.CurrencyOfConversion,
			Attributes.Period,
			LocalAccountingCurrency);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionFactorOfConversionToCurrencyMan",   ConversionFactors.ConversionRateToManCurrency);
		Values.Insert("ConversionRateOfConversionToLocalCurrency",  ConversionFactors.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionRateToConversionCurrency",      ConversionRateToConversionCurrency);
		
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		Values.Insert("Department", DocumentSubdivision(Attributes));
		
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableOfCalculationObjects(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TableOfCalculationObjects";
	
	QueryText = "
	|SELECT DISTINCT
	|	PaymentDecryptionTable.ARAPObject                         AS ARAPObject,
	|	PaymentDecryptionTable.ARAPObjectOfCompany             AS Organization,
	|	PaymentDecryptionTable.ARAPObjectContract                 AS Contract,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|					VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|				AND ISNULL(Directions.VendorARAP, FALSE)
	|			OR NOT &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|					VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|				AND ISNULL(Directions.IncomeAccounting, FALSE)
	|		THEN
	|			PaymentDecryptionTable.ARAPObjectLineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                                                            AS LineOfBusiness,
	|	PaymentDecryptionTable.ARAPObjectIsPartner                 AS Partner,
	|	PaymentDecryptionTable.ObjectOfCalculationsDivision           AS Department,
	|	PaymentDecryptionTable.ARAPObjectTaxationOfVAT      AS VATTaxation
	|
	|INTO TableOfCalculationObjects
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|	ON PaymentDecryptionTable.ARAPObjectLineOfBusiness = Directions.Ref
	|	
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromLessor),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
	|		)
	|
	|INDEX BY
	|	ARAPObject
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.CashAccountReceiptNote.ARAPDetails");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectOfCompany", "PaymentDecryptionTable.ARAPObject.Organization");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectContract", "PaymentDecryptionTable.ARAPObject.Contract");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectLineOfBusiness", "PaymentDecryptionTable.ARAPObject.LineOfBusiness");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectIsPartner", "PaymentDecryptionTable.ARAPObject.Partner");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ObjectOfCalculationsDivision", "PaymentDecryptionTable.ARAPObject.Department");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectTaxationOfVAT", "PaymentDecryptionTable.ARAPObject.VATTaxation");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query, DocumentObject = Undefined)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	Query.Text = "
	|SELECT DISTINCT
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	
	|	CASE WHEN PaymentDecryptionTable.CompanyParentCompany = &Organization THEN
	|		PaymentDecryptionTable.Organization
	|	ELSE
	|		&Organization
	|	END AS Organization,
	|	
	|	PaymentDecryptionTable.ARAPObjectContract AS Contract,
	|	PaymentDecryptionTable.ARAPObjectLineOfBusiness AS LineOfBusiness
	|
	|INTO TTTableOfCalculationObjects
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromLessor),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
	|	)
	|
	|INDEX BY
	|	ARAPObject
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	CASE WHEN VALUETYPE(&Counterparty) = TYPE(Catalog.Companies)
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE PaymentDecryptionTable.Partner
	|	END AS Partner,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|		ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE WHEN VALUETYPE(&Counterparty) = TYPE(Catalog.Companies)
	|			THEN VALUE(Catalog.Partners.OurEnterprise)
	|			ELSE PaymentDecryptionTable.Partner
	|		END = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	PaymentTable_2.Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	&Partner AS Partner,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataHeader AS PaymentTable_2
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		PaymentTable_2.Organization= Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND &Partner = Dimension.Partner
	|		AND &Contract = Dimension.Contract
	|		AND &LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentTable_2.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
	|		ON PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits), 
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
	|		)
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	INNER JOIN Catalog.LeaseContract AS ContractData
	|		ON PaymentDecryptionTable.LeaseContracts = ContractData.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
	|		)
	|";
	
	If DocumentObject = Undefined Then
		
		Query.Text = StrReplace(Query.Text, "DocumentDataTableDecryptionOfPayment", "Document.CashAccountReceiptNote.ARAPDetails");
		Query.Text = StrReplace(Query.Text, "DocumentDataHeader", "Document.CashAccountReceiptNote");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.CompanyParentCompany", "PaymentDecryptionTable.Organization.ParentCompany");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.ARAPObjectContract", "PaymentDecryptionTable.ARAPObject.Contract");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.ARAPObjectLineOfBusiness", "PaymentDecryptionTable.ARAPObject.LineOfBusiness");
	
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	InitializeAccountingAnalyticsForSettlementObjectPartners(Query);
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure InitializeAccountingAnalyticsForSettlementObjectPartners(Query)
	
	If ARAPAccountingServer.BusinessOperationRefundOfFunds(Query.Parameters.BusinessOperation) Then
	
		StructureOfAnalytics = New Structure("Organization, Counterparty, Partner, Contract, LineOfBusiness");
		FillPropertyValues(StructureOfAnalytics, Query.Parameters);
				
		If Not ValueIsFilled(Query.Parameters.Contract) Then
			ThisIsIntercampany = Query.Parameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany");
			StructureOfAnalytics.Contract = ?(ThisIsIntercampany, Catalogs.IntercompanyContracts.EmptyRef(), Catalogs.CounterpartyContracts.EmptyRef());
		EndIf;
		AnalysisOfAccountingByPartnersOfSettlementObject = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
	Else
		AnalysisOfAccountingByPartnersOfSettlementObject = Undefined;
	EndIf;
	
	Query.SetParameter("AnalysisOfAccountingByPartnersOfSettlementObject", AnalysisOfAccountingByPartnersOfSettlementObject);
	
EndProcedure

Function QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "PaymentDecryptionTable";
	
	InitializeTrackingAnalyticsKeysForPartners(Query, DocumentObject);
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		QueryTextTableOfCalculationObjects(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	Dimension.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	ISNULL(TableOfCalculationObjects.Contract, UNDEFINED) AS Contract,
	|	CAST(PaymentDecryptionTable.PaymentPurpose AS Document.CustomerCommercialInvoice) AS ProformaInvoice,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
	|			THEN PaymentDecryptionTable.LineOfBusiness
	|		ELSE TableOfCalculationObjects.LineOfBusiness
	|	END AS LineOfBusiness,
	|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
	|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	PaymentDecryptionTable.Department AS Department,
	|	ISNULL(TableOfCalculationObjects.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS OrderDivision_,
	|
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	UNDEFINED AS LoanDepositContract,
	|	UNDEFINED AS LoanAndDepositAmountType,
	|	UNDEFINED AS LeaseContracts,
	|	UNDEFINED AS TypeOfLeasePayment,
	|	UNDEFINED AS ARAPDocumentForLease,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	CASE
	|		WHEN &Currency = &ManagementAccountingCurrency
	|			THEN PaymentDecryptionTable.Sum 
	|		WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN PaymentDecryptionTable.Sum
	|		WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|			THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS VATAmountCompl,
	|
	|	ISNULL(TableOfCalculationObjects.VATTaxation, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	PaymentDecryptionTable.RowID AS RowID,
	|	DocumentOCR.DocumentID            AS DocumentID
	|
	|INTO PaymentDecryptionTable
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		
	|	LEFT JOIN
	|		TableOfCalculationObjects AS TableOfCalculationObjects
	|	ON
	| 		PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|	
	|	LEFT JOIN
	|		Document.CashAccountReceiptNote AS DocumentOCR
	|	ON
	| 		PaymentDecryptionTable.Ref = DocumentOCR.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE WHEN VALUETYPE(&Counterparty) = TYPE(Catalog.Companies)
	|				THEN VALUE(Catalog.Partners.OurEnterprise)
	|			WHEN &ThereIsGiftCertificate = TRUE
	|				THEN &Partner
	|			ELSE PaymentDecryptionTable.Partner
	|		END = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty),
	|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	Dimension.Organization AS Organization,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ProformaInvoice,
	|
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS IncomeItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS GLAccountSettings,
	|	ContractData.Department AS Department,
	|	UNDEFINED AS OrderDivision_,
	|
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	UNDEFINED AS LeaseContracts,
	|	UNDEFINED AS TypeOfLeasePayment,
	|	UNDEFINED AS ARAPDocumentForLease,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	CASE
	|		WHEN &Currency = &ManagementAccountingCurrency
	|			THEN PaymentDecryptionTable.Sum
	|		WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN PaymentDecryptionTable.Sum
	|		WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|			THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS VATAmountMan,
	|	0 AS VATAmountCompl,
	|
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	
	|	PaymentDecryptionTable.RowID AS RowID,
	|	DocumentData.DocumentID AS DocumentID
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|	ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|	INNER JOIN
	|		Catalog.LoanAndDepositContracts AS ContractData
	|	ON
	|		PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE
	|			WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|				PaymentDecryptionTable.Partner
	|			ELSE
	|				DocumentData.CounterpartyPartner
	|		END = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	Dimension.Organization AS Organization,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ProformaInvoice,
	|
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS IncomeItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS GLAccountSettings,
	|	ContractData.Department AS Department,
	|	UNDEFINED AS OrderDivision_,
	|
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	UNDEFINED AS LoanDepositContract,
	|	UNDEFINED AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.ARAPDocumentForLease AS ARAPDocumentForLease,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	CASE
	|		WHEN &Currency = &ManagementAccountingCurrency
	|			THEN PaymentDecryptionTable.Sum
	|		WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN PaymentDecryptionTable.Sum
	|		WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|			THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS VATAmountMan,
	|	0 AS VATAmountCompl,
	|
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	
	|	PaymentDecryptionTable.RowID AS RowID,
	|	DocumentData.DocumentID AS DocumentID
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|	ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|	INNER JOIN
	|		Catalog.LeaseContract AS ContractData
	|	ON
	|		PaymentDecryptionTable.LeaseContracts = ContractData.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE
	|			WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|				PaymentDecryptionTable.Partner
	|			ELSE
	|				DocumentData.CounterpartyPartner
	|		END = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
	|		)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.CashAccountReceiptNote.ARAPDetails");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashAccountReceiptNote");
		QueryText = StrReplace(QueryText, "DocumentData.CounterpartyPartner", "DocumentData.Counterparty.Partner");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashAccountBalance(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashAccountBalance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "";
	
	If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromBank
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CurrencyConversion Then
			
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DocumentData.Organization AS Organization,
		|	
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
		|			THEN &Department
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
		|			THEN PaymentDecryptionTable.Department
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|			VALUE(Enum.BusinessTransactions.RefundFromVendor))
		|			THEN PaymentDecryptionTable.OrderDivision_
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|			VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|			VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))
		|			THEN PaymentDecryptionTable.LoanDepositContract.Department
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister),
		|			VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder),
		|			VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee))
		|			THEN DocumentData.Department
		|		ELSE UNDEFINED
		|	END AS Department,
		|
		|	DocumentData.CashAccount AS CashAccount,
		|	
		|	&BusinessOperation AS BusinessOperation,
		|	
		|	CASE WHEN &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor),
		|		VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee),
		|		VALUE(Enum.BusinessTransactions.OtherCashReceipt))
		|	THEN
		|		PaymentDecryptionTable.CashFlowItem
		|	ELSE
		|		&CashFlowItem
		|	END AS CashFlowItem,
		|
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|	CASE WHEN DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty),
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
		|	THEN
		|		PaymentDecryptionTable.AccountingDimensionByPartners
		|	ELSE
		|		UNDEFINED
		|	END AS AccountingDimensionByPartners,
		|	
		|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS Sum,
		|	
		|	CASE WHEN PaymentDecryptionTable.Sum IS NULL
		|		THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) 
		|		ELSE PaymentDecryptionTable.SumCompl
		|	END AS SumCompl,
		|	
		|	CASE WHEN PaymentDecryptionTable.Sum IS NULL
		|		THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|		ELSE PaymentDecryptionTable.SumMan
		|	END AS SumMan,
		|	
		|	CASE
		|		WHEN DocumentData.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.CurrencyConversion),
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister),
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount),
		|			VALUE(Enum.BusinessTransactions.CashCollectionFromBank),
		|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
		|				THEN DocumentData.DocumentID
		|		ELSE
		|			PaymentDecryptionTable.RowID
		|	END AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromLoansRepayment
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptUnderDeposits
			And DocumentObject.BusinessOperation
			<> Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
			QueryText = StrReplace(QueryText, "PaymentDecryptionTable.LoanDepositContract.Department",
				"UNDEFINED"); // @query-part
		EndIf;
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank Then
	
		QueryText = "
		|SELECT
		|	1 AS LineNumber,
		|	DocumentData.Date AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.CashAccount AS CashAccount,
		|	
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	&CashFlowItem AS CashFlowItem,
		|
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	
		|	DocumentData.DocumentAmount AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
		|	
		|	DocumentData.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromBank) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "
		|SELECT
		|	1 AS LineNumber,
		|	DocumentData.Date AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.CashAccount AS CashAccount,
		|	
		|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) AS BusinessOperation,
		|	&CashFlowItem AS CashFlowItem,
		|
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	
		|	DocumentData.DocumentAmount AS Sum,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS SumCompl,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency AS SumMan,
		|	
		|	DocumentData.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
	EndIf;
	
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BankAccountCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.BankAccount AS BankAccount,
	|	
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|	
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	
	|	DocumentData.DocumentAmount AS Sum,
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	
	|	&Ref AS PaymentDocument,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromBank) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextCashInTransit(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount Then
			
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                            AS RecordType,
		|	&Period                                                                           AS Period,
		|	
		|	DocumentData.Organization                                                       AS Organization,
		|	CASE
		|		WHEN VALUETYPE(DocumentData.CashAccountIssuer) = TYPE(Catalog.CashAccounts) THEN
		|			DocumentData.CashAccount
		|		ELSE
		|			UNDEFINED
		|	END AS Recipient,
		|	DocumentData.CashAccountIssuer                                                  AS Sender,
		|	VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount)       AS CashTransferKind,
		|	UNDEFINED                                                                      AS Counterparty,
		|	DocumentData.Currency                                                            AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                    AS Sum,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))  AS SumCompl,
		|	
		|	&BusinessOperation                                                            AS BusinessOperation,
		|	&CashFlowItem                                                    AS CashFlowItem,
		|
		| 	DocumentData.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromAnotherCashAccount) AS BusinessTransactionSetting
		|
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank Then
			
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                            AS RecordType,
		|	&Period                                                                           AS Period,
		|	
		|	DocumentData.Organization                                                       AS Organization,
		|	DocumentData.CashAccount                                                             AS Recipient,
		|	DocumentData.BankAccount                                                    AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashCollectionFromBank_)             AS CashTransferKind,
		|	UNDEFINED                                                                      AS Counterparty,
		|	DocumentData.Currency                                                            AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                    AS Sum,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))  AS SumCompl,
		|	
		|	&BusinessOperation                                                            AS BusinessOperation,
		|	&CashFlowItem                                                    AS CashFlowItem,
		|	
		|	DocumentData.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashCollectionFromBank) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                            AS RecordType,
		|	&Period                                                                           AS Period,
		|	
		|	DocumentData.Organization                                                       AS Organization,
		|	DocumentData.CashAccount                                                             AS Recipient,
		|	UNDEFINED                                                                      AS Sender,
		|	CASE WHEN DocumentData.CurrencyOfConversion = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                             AS CashTransferKind,
		|	DocumentData.Counterparty                                                        AS Counterparty,
		|	DocumentData.CurrencyOfConversion                                                 AS Currency,
		|	
		|	DocumentData.ConversionAmount                                                  AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                  AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul                 AS SumCompl,
		|	
		|	&BusinessOperation                                                            AS BusinessOperation,
		|	&CashFlowItem                                                    AS CashFlowItem,
		|
		|	DocumentData.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion) AS BusinessTransactionSetting
		|
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
		QueryText = "
		|// Positive exchange rate differences
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                                   AS RecordType,
		|	&Period                                                                                  AS Period,
		|	
		|	&Organization                                                                             AS Organization,
		|	TableOfExchangeDifferences.CashAccount                                                              AS Recipient,
		|	UNDEFINED                                                                             AS Sender,
		|	CASE WHEN &CurrencyOfConversion = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                                    AS CashTransferKind,
		|	&Counterparty                                                                              AS Counterparty,
		|	&CurrencyOfConversion                                                                       AS Currency,
		|	
		|	0                                                                                        AS Sum,
		|	-TableOfExchangeDifferences.SumMan                                                          AS SumMan,
		|	-TableOfExchangeDifferences.SumCompl                                                         AS SumCompl,
		|	
		|	&BusinessOperation                                                                   AS BusinessOperation,
		|	&CashFlowItem                                                           AS CashFlowItem,
		|
		| 	TableOfExchangeDifferences.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss) AS BusinessTransactionSetting
		|
		|	
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|	
		|WHERE
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|	AND (TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
		QueryText = "
		|// Negative exchange rate differences
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                                   AS RecordType,
		|	&Period                                                                                  AS Period,
		|	
		|	&Organization                                                                             AS Organization,
		|	TableOfExchangeDifferences.CashAccount                                                              AS Recipient,
		|	UNDEFINED                                                                             AS Sender,
		|	CASE WHEN &CurrencyOfConversion = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                                    AS CashTransferKind,
		|	&Counterparty                                                                              AS Counterparty,
		|	&CurrencyOfConversion                                                                       AS Currency,
		|	
		|	0                                                                                        AS Sum,
		|	TableOfExchangeDifferences.SumMan                                                           AS SumMan,
		|	TableOfExchangeDifferences.SumCompl                                                          AS SumCompl,
		|	
		|	&BusinessOperation                                                                   AS BusinessOperation,
		|	&CashFlowItem                                                           AS CashFlowItem,
		|
		| 	TableOfExchangeDifferences.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain) AS BusinessTransactionSetting
		|
		|	
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|	
		|WHERE
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|	AND (TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "CashToBePaid";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject <> Undefined
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromBank Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.CashTransferReferenceOrder AS PaymentRequest,
	|	DocumentData.BankAccount AS BankAccountCashAccount,
	|	DocumentData.Organization AS Recipient,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UsePaymentRequests
	|	AND DocumentData.CashTransferReferenceOrder <> VALUE(Document.CashTransferReferenceOrder.EmptyRef)
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromBank)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashAccountReceiptNote");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister Then
		Return "";
	EndIf;
		
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.DocumentAmount AS Sum,
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	&BusinessOperation AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|
	| 	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCashRegister) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.Department AS Department,
	|	DocumentData.CashAccountCashCurrency AS Currency,
	|	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS Sum,
	|	CASE WHEN PaymentDecryptionTable.Sum IS NULL
	|		THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE PaymentDecryptionTable.SumCompl
	|	END AS SumCompl,
	|	CASE WHEN PaymentDecryptionTable.Sum IS NULL
	|		THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE PaymentDecryptionTable.SumMan
	|	END AS SumMan,
	|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS ToReport,
	|	
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReturnByAdvanceHolder) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
	|		ON TRUE
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	&Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS AssetRef,
		|	CASE
		|		WHEN PaymentDecryptionTable.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE PaymentDecryptionTable.AssetsLiabilitiesDimension
		|	END AS Dimension,
		|	PaymentDecryptionTable.SumMan AS Sum
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	SUM(PaymentDecryptionTable.SumMan) AS Sum
		|FROM
		|	PaymentDecryptionTable
		|
		|GROUP BY
		|	PaymentDecryptionTable.LineOfBusiness
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt) Then
		
		If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
		EndIf;
		
		ArrayOfRequestTexts.Add(AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False));
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SettlementWithBranches = False;
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor) Then
		SettlementWithBranches = True;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If SettlementWithBranches And Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		
		QueryTextAssetsLiabilities = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS AssetRef,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS Dimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumMan AS AmountIncludingVAT,
		|	PaymentDecryptionTable.SumMan AS AmountExcludingVAT,
		|
		|	PaymentDecryptionTable.RowID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems";
		
		ArrayOfRequestTexts.Add(QueryTextAssetsLiabilities);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		QueryTextAssetsLiabilities = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	&LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
		|	&SenderOrganization AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
		|
		|	DocumentData.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryTextAssetsLiabilities);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		
		QueryTextAssetsLiabilities = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS AssetRef,
		|	&AdvanceHolder AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumMan AS AmountIncludingVAT,
		|	PaymentDecryptionTable.SumMan AS AmountExcludingVAT,
		|
		|	PaymentDecryptionTable.RowID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|";
		
		ArrayOfRequestTexts.Add(QueryTextAssetsLiabilities);
		
	EndIf;
	
	If SettlementWithBranches Then
		ArrayOfRequestTexts.Add(OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches());
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""DocumentData""     AS DataSource,
	|	FALSE                    AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Date   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	ISNULL(Rows.ARAPCurrency, UNDEFINED) AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Date   AS DateOfCourse,
	|
	|	ISNULL(Rows.LineNumber, 0) AS LineNumber,
	|	ISNULL(Rows.RowID, """") AS RowID,
	|	ISNULL(Rows.Sum - Rows.VATAmount, DocumentTable.DocumentAmount) AS AmountExcludingVAT,
	|	ISNULL(Rows.VATRate, UNDEFINED) AS VATRate,
	|	ISNULL(Rows.VATAmount, 0) AS VATAmount,
	|	ISNULL(Rows.AmountARAP, 0) AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	CASE
	|		WHEN ISNULL(Rows.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) = VALUE(Catalog.ARAPObjects.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	ISNULL(Rows.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	LEFT JOIN DocumentDataTableDecryptionOfPayment AS Rows
	|		ON Rows.Ref = DocumentTable.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	If DocumentObject = Undefined Then
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.CashAccountReceiptNote");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableDecryptionOfPayment", "Document.CashAccountReceiptNote.ARAPDetails");
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber                             AS LineNumber,
		|	&Period                                                           AS Period,
		|	VALUE(AccumulationRecordType.Expense)                            AS RecordType,
		
		|	PaymentDecryptionTable.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.LoanDepositContract                  AS Contract,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment)
		|			THEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
		|		ELSE PaymentDecryptionTable.LoanAndDepositAmountType
		|	END AS AmountType,
		|	UNDEFINED AS ARAPDocument,
		|	PaymentDecryptionTable.ARAPCurrency                    AS Currency,
		
		|	PaymentDecryptionTable.AmountARAP                     AS Sum,
		|	PaymentDecryptionTable.SumCompl                               AS SumCompl,
		|	PaymentDecryptionTable.SumMan                                AS SumMan,
		
		|	&BusinessOperation                                            AS BusinessOperation,
		|	CASE
		|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
		|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
		|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
		|	END AS ScheduleType,
		|	PaymentDecryptionTable.CashFlowItem           AS DimensionItem,
		|	
		|	PaymentDecryptionTable.RowID                     AS FinRecordID,
		|	 CASE 
		|	 	WHEN  &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment) THEN
		|	 		VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromLoansRepayment) 
		|	 	WHEN  &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits) THEN
		|	 				VALUE(Catalog.BusinessTransactionsSettings.CashReceiptUnderDeposits)
		|	 	WHEN  &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty) THEN
		|	 				VALUE(Catalog.BusinessTransactionsSettings.CashReceiptBorrowingsProvidedToCounterparty)
		|	 END AS BusinessTransactionSetting
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
		|		ON PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
		|
		|ORDER BY
		|	PaymentDecryptionTable.LineNumber
		|";
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber                             AS LineNumber,
		|	&Period                                                           AS Period,
		|	VALUE(AccumulationRecordType.Expense)                            AS RecordType,
		
		|	PaymentDecryptionTable.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.LeaseContracts                           AS Contract,
		|	PaymentDecryptionTable.TypeOfLeasePayment                      AS AmountType,
		|	CASE
		|		WHEN PaymentDecryptionTable.TypeOfLeasePayment IN (
		|				VALUE(Enum.TypesOfLeasePayments.DepositPayment),
		|				VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)) THEN
		|			PaymentDecryptionTable.ARAPDocumentForLease
		|		ELSE
		|			UNDEFINED
		|	END AS ARAPDocument,
		
		|	PaymentDecryptionTable.ARAPCurrency                    AS Currency,
		
		|	PaymentDecryptionTable.AmountARAP                     AS Sum,
		|	PaymentDecryptionTable.SumCompl                               AS SumCompl,
		|	PaymentDecryptionTable.SumMan                                AS SumMan,
		
		|	CASE PaymentDecryptionTable.TypeOfLeasePayment
		|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|			THEN VALUE(Enum.BusinessTransactions.SecurityPaymentReturn)
		|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|			THEN VALUE(Enum.BusinessTransactions.RefundLeaseBuyoutValue)
		|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|			THEN VALUE(Enum.BusinessTransactions.RefundPrepaymentLeaseBuyoutValue)
		|		ELSE &BusinessOperation
		|	END AS BusinessOperation,
		|
		|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)  AS ScheduleType,
		|	PaymentDecryptionTable.CashFlowItem           AS DimensionItem,
		|	
		|	PaymentDecryptionTable.RowID                     AS FinRecordID,
		|	CASE PaymentDecryptionTable.TypeOfLeasePayment
		|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.SecurityPaymentReturn)
		|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.RefundLeaseBuyoutValue)
		|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.RefundPrepaymentLeaseBuyoutValue)
		|		ELSE &BusinessTransactionSetting
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|
		|ORDER BY
		|	PaymentDecryptionTable.LineNumber
		|
		|";
		
	EndIf;
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister Then
			
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	CASE
		|		WHEN &BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister),
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank))
		|			THEN DocumentData.Department
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
		|			THEN &Department
		|		ELSE
		|			UNDEFINED
		|	END AS Department,
		|
		|	CASE
		|		WHEN &BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
		|			VALUE(Enum.BusinessTransactions.CashCollectionFromBank)
		|			) THEN DocumentData.BankAccount
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister)
		|			THEN DocumentData.CashRegister
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
		|			THEN DocumentData.CashAccountIssuer
		|	END AS Cash,
		|	CASE
		|		WHEN &BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
		|			VALUE(Enum.BusinessTransactions.CashCollectionFromBank)
		|			) THEN DocumentData.BankAccountLineOfBusiness
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister)
		|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		ELSE
		|			DocumentData.CashAccountSenderLineOfBusiness
		|	END AS LineOfBusiness,
		|	
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromBank)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.CashInTransit)
		|	END AS CashType,
		|	
		|	&CashFlowItem AS CashFlowItem,
		|
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.CashAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.CashPayment) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|
		|	CASE
		|		WHEN &BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
		|			VALUE(Enum.BusinessTransactions.CashCollectionFromBank)
		|			) THEN DocumentData.BankAccount
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister)
		|			THEN DocumentData.CashRegister
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
		|			AND VALUETYPE(DocumentData.CashAccountIssuer) = TYPE(Catalog.CashRegisters)
		|			THEN UNDEFINED
		|		ELSE
		|			DocumentData.CashAccount
		|	END AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.CashAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
			
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|
		|	DocumentData.AdvanceHolder AS Cash,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.CashAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.CashPayment) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|	PaymentDecryptionTable.Sum AS AmountInCorCurrency,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.CashAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		
		|		LEFT JOIN
		|			PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON
		|			TRUE
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits Then
			
		QueryText = "
		|// Deposit receipt operations
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	PaymentDecryptionTable.LoanDepositContract.Department AS Department,
		|
		|	PaymentDecryptionTable.LoanDepositContract AS Cash,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.Deposits) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.CashAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.CashPayment) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|	PaymentDecryptionTable.Sum AS AmountInCorCurrency,
		|
		|	PaymentDecryptionTable.LoanDepositContract AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.CashAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		
		|		LEFT JOIN
		|			PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON
		|			TRUE
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
		QueryText = "
		|// Operations of receipt of funds from currency conversion
		|SELECT
		|	DocumentData.Date AS Period,
		|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|
		|	DocumentData.Counterparty AS Cash,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	DocumentData.CurrencyOfConversion AS Currency,
		|
		|	DocumentData.CashAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.CashPayment) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.ConversionAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.CashAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|
		|";
	
	EndIf;
	
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		
		QueryText = 
		"SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	PaymentDecryptionTable.IncomeItem AS IncomeAndExpenseItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.IncomeItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON 
		|		TRUE
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	&LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|	
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|	
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	PaymentDecryptionTable.IncomeItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|	
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.IncomeItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.ExpenseItems
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	&LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	PaymentDecryptionTable.IncomeItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	PaymentDocumentData.BusinessOperation AS BusinessOperation,
		|	PaymentDocumentData.Organization AS Organization,
		|	UNDEFINED AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	PaymentDocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.LeaseContracts AS AssetsLiabilitiesDimension,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	PaymentDocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|
		|FROM
		|	DocumentDataHeader AS PaymentDocumentData
		|
		|	INNER JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		QueryText = "
		|// Calculation of income from exchange differences
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
		|	&Organization AS Organization,
		|	TableOfExchangeDifferences.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	TableOfExchangeDifferences.Department AS IncomeExpenseBusinessUnit,
		|
		|	&Counterparty AS Cash,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	&CurrencyOfConversion AS Currency,
		|
		|	TableOfExchangeDifferences.LineOfBusiness AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome) AS IncomeAndExpenseItem,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	
		|	TableOfExchangeDifferences.SumMan AS Sum,
		|	TableOfExchangeDifferences.SumCompl AS SumCompl,
		|	0 AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome) AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|
		|WHERE
		|	(TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)
		|
		|UNION ALL
		|
		|// Calculation of expenses from exchange differences
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) AS BusinessOperation,
		|	&Organization AS Organization,
		|	TableOfExchangeDifferences.Department AS Department,
		|	&LineOfBusinessCash,
		|	TableOfExchangeDifferences.Department AS IncomeExpenseBusinessUnit,
		|
		|	&Counterparty AS Cash,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	&CurrencyOfConversion AS Currency,
		|
		|	TableOfExchangeDifferences.LineOfBusiness AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	-TableOfExchangeDifferences.SumMan	AS Sum,
		|	-TableOfExchangeDifferences.SumCompl AS SumCompl,
		|	0 AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|
		|WHERE
		|	(TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)
		|";
	
	EndIf;
	
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ArrayOfSubqueryTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
		
		QueryTextOfSubquery = "// Cash flow operations
		|	SELECT
		|		DocumentData.Date AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|		PaymentDecryptionTable.SumMan AS PayAmount,
		|		PaymentDecryptionTable.SumCompl AS PaymentAmountLocal,
		|		PaymentDecryptionTable.Sum AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		PaymentDecryptionTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		
		QueryTextOfSubquery = "// Operations on receipt of funds from another organization
		|	SELECT
		|		DocumentData.Date AS Period,
		|		DocumentData.BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		UNDEFINED AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.CashAccountSenderOwner AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|		PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS PayAmount,
		|		PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS PaymentAmountLocal,
		|		PaymentDecryptionTable.Sum AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		PaymentDecryptionTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		QueryTextOfSubquery = "// Internal money transfer operations
		|	SELECT
		|		DocumentData.Date AS Period,
		|		CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|				THEN VALUE(Enum.BusinessTransactions.InternalCashReceipt)
		|			ELSE &BusinessOperation
		|		END AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		UNDEFINED AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		&CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		UNDEFINED AS Partner,
		|		DocumentData.CashAccountSenderOwner AS Counterparty,
		|		DocumentData.CashAccountSenderLineOfBusiness AS LineOfBusiness,
		|		UNDEFINED AS Contract,
		|		UNDEFINED AS ARAPObject,
		|	
		|		CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
		|		CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
		|		DocumentData.DocumentAmount AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		DocumentData.Currency AS ARAPCurrency,
		|
		|		DocumentData.DocumentAmount AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
		
		QueryTextOfSubquery = "// Operations receipts on loans and loans issued
		|	SELECT
		|		DocumentData.Date AS Period,
		|		CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		|				  AND (PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfReceiptIssuie = PaymentDecryptionTable.CashFlowItem
		|					 OR PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfPrincipalDebt = PaymentDecryptionTable.CashFlowItem)
		|				THEN VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		|				  AND (PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfInterestPayment = PaymentDecryptionTable.CashFlowItem
		|					 OR PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfFeePayment = PaymentDecryptionTable.CashFlowItem)
		|				THEN VALUE(Enum.BusinessTransactions.ReceiptOfInterestOfIssuedBorrowings)
		|			ELSE &BusinessOperation
		|		END  AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.LoanDepositContract.Department AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|		PaymentDecryptionTable.LoanDepositContract AS Contract,
		|		UNDEFINED AS ARAPObject,
		|	
		|		PaymentDecryptionTable.SumMan AS PayAmount,
		|		PaymentDecryptionTable.SumCompl AS PaymentAmountLocal,
		|		PaymentDecryptionTable.Sum AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		PaymentDecryptionTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.LoanDepositContract AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
		
		QueryTextOfSubquery = "SELECT // VAT
		|		DocumentData.Date AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|		0 AS PayAmount,
		|		0 AS PaymentAmountLocal,
		|		0 AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		PaymentDecryptionTable.VATAmountMan AS VATAmount,
		|		PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|		PaymentDecryptionTable.VATAmount AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		0 AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.VATRate AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|	WHERE
		|		PaymentDecryptionTable.VATAmount <> 0";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		
		QueryTextOfSubquery = "SELECT // VAT
		|		DocumentData.Date AS Period,
		|		DocumentData.BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		UNDEFINED AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.CashAccountSenderOwner AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|		0 AS PayAmount,
		|		0 AS PaymentAmountLocal,
		|		0 AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		PaymentDecryptionTable.VATAmountMan AS VATAmount,
		|		PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|		PaymentDecryptionTable.VATAmount AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		0 AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.VATRate AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|	
		|	WHERE
		|		PaymentDecryptionTable.VATAmount <> 0";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If ArrayOfSubqueryTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	TextOfQuerySubquery = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.Cash AS Cash,
	|	&LineOfBusinessCash AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentCurrency AS PaymentCurrency,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|					VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|			OR NOT &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|					VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE)
	|		THEN
	|			DocumentData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS CounterpartyLineOfBusiness,
	|
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	SUM(DocumentData.PayAmount) AS PayAmount,
	|	SUM(DocumentData.PaymentAmountLocal) AS PaymentAmountLocal,
	|	SUM(DocumentData.PaymentAmountPaymentCurrency) AS PaymentAmountPaymentCurrency,
	|
	|	SUM(DocumentData.PostpaymentAmount) AS PostpaymentAmount,
	|	SUM(DocumentData.PostpaymentAmountLocal) AS PostpaymentAmountLocal,
	|	SUM(DocumentData.PaymentAmountInPaymentCurrency) AS PaymentAmountInPaymentCurrency,
	|
	|	SUM(DocumentData.PrepaymentAmountMan) AS PrepaymentAmountMan,
	|	SUM(DocumentData.PrepaymentAmountLocal) AS PrepaymentAmountLocal,
	|	SUM(DocumentData.PrepaymentAmount) AS PrepaymentAmount,
	|
	|	SUM(DocumentData.VATAmount) AS VATAmount,
	|	SUM(DocumentData.VATAmountCompl) AS VATAmountCompl,
	|	SUM(DocumentData.AmountVATCurrencyPayment) AS AmountVATCurrencyPayment,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	SUM(DocumentData.PaymentAmountInTheSettlementCurrency) AS PaymentAmountInTheSettlementCurrency,
	|	SUM(DocumentData.PostPaymentAmountInARAPCurrency) AS PostPaymentAmountInARAPCurrency,
	|	SUM(DocumentData.PrepaymentAmountInARAPCurrency) AS PrepaymentAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.VATRate,
	|	FALSE AS DeferredPosting
	|
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Cash,
	|	DocumentData.CashFlowItem,
	|	DocumentData.PaymentCurrency,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|					VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|			OR NOT &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|					VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE)
	|		THEN
	|			DocumentData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.VATRate
	|";
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + TextOfQuerySubquery + ")");
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfSubqueryTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
			
		SubqueryText = "// The debt of the client was written off by the prered branch
		|	SELECT
		|		DocumentData.Date AS Period,
		|		CASE WHEN &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer), 
		|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany))
		|			THEN VALUE(Enum.BusinessTransactions.PaymentTransferFromBranchOffice)
		|			ELSE VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|		END AS BusinessOperation,
		|		PaymentDecryptionTable.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.LineOfBusiness AS LineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS CorPartner,
		|		DocumentData.Organization AS CorCounterparty,
		|		&LineOfBusinessCash AS CorLineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS CorContract,
		|		PaymentDecryptionTable.ARAPObject AS CorARAPObject,
		|		
		|	
		|		PaymentDecryptionTable.SumMan AS Sum,
		|		PaymentDecryptionTable.SumCompl AS SumCompl,
		|		PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization";
		
		ArrayOfSubqueryTexts.Add(SubqueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
			
		SubqueryText = "// Transferred the client's debt to the organization
		|	SELECT
		|		DocumentData.Date AS Period,
		|		CASE WHEN &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer), 
		|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany))
		|			THEN VALUE(Enum.BusinessTransactions.PaymentAcceptanceAtBranchOffice)
		|			ELSE VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|		END AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		PaymentDecryptionTable.Organization AS Counterparty,
		|		&LineOfBusinessCash AS LineOfBusiness,
		|		PaymentDecryptionTable.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS CorPartner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS CorCounterparty,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.LineOfBusiness AS CorLineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS CorContract,
		|		PaymentDecryptionTable.ARAPObject AS CorARAPObject,
		|		
		|	
		|		PaymentDecryptionTable.SumMan AS Sum,
		|		PaymentDecryptionTable.SumCompl AS SumCompl,
		|		PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization";
		
		ArrayOfSubqueryTexts.Add(SubqueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
			
		SubqueryText = "// Refund of payment at the advance rate
		|	SELECT
		|		DocumentData.Date AS Period,
		|		VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.Organization AS Counterparty,
		|		&LineOfBusinessCash AS LineOfBusiness,
		|		PaymentDecryptionTable.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS CorPartner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS CorCounterparty,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.LineOfBusiness AS CorLineOfBusiness,
		|		DocumentData.Contract AS CorContract,
		|		DocumentData.ARAPObject AS CorARAPObject,
		|		
		|	
		|		PaymentDecryptionTable.SumMan AS Sum,
		|		PaymentDecryptionTable.SumCompl AS SumCompl,
		|		PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		DocumentData.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		PaymentDecryptionTable.ARAPObject.OBJECT <> &Ref";
		
		ArrayOfSubqueryTexts.Add(SubqueryText);
		
	EndIf;
	
	If ArrayOfSubqueryTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	TextOfQuerySubquery = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness 
	|	END AS LineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|
	|	DocumentData.CorPartner AS CorPartner,
	|	DocumentData.CorCounterparty AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END AS CorLineOfBusiness,
	|	DocumentData.CorContract AS CorContract,
	|	DocumentData.CorARAPObject AS CorARAPObject,
	|	&Currency AS Currency,
	|
	|	SUM(DocumentData.Sum) AS Sum,
	|	SUM(DocumentData.SumCompl) AS SumCompl,
	|	SUM(DocumentData.AmountInCurrency) AS AmountInCurrency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	SUM(DocumentData.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
	|	SUM(DocumentData.AdjAmountInARAPCurrency) AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup
	|INTO TTMovementCounterpartyCounterparty
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|   DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness 
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.CorPartner,
	|	DocumentData.CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END,
	|	DocumentData.CorContract,
	|	DocumentData.CorARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup
	|";
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + TextOfQuerySubquery + ")");
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor) Then
	
		Return "";
		
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = 
	"SELECT
	|	RecordsCounterpartyCounterparty.Period                        AS Period,
	|	RecordsCounterpartyCounterparty.BusinessOperation         AS BusinessOperation,
	|	RecordsCounterpartyCounterparty.Organization                   AS Organization,
	|	RecordsCounterpartyCounterparty.Department                 AS Department,
	|
	|	RecordsCounterpartyCounterparty.Partner                       AS Partner,
	|	RecordsCounterpartyCounterparty.Counterparty                    AS Counterparty,
	|	RecordsCounterpartyCounterparty.LineOfBusiness       AS LineOfBusiness,
	|	RecordsCounterpartyCounterparty.Contract                       AS Contract,
	|	RecordsCounterpartyCounterparty.ARAPObject                AS ARAPObject,
	|
	|	RecordsCounterpartyCounterparty.CorPartner                    AS CorPartner,
	|	RecordsCounterpartyCounterparty.CorCounterparty                 AS CorCounterparty,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness    AS CorLineOfBusiness,
	|	RecordsCounterpartyCounterparty.CorContract                    AS CorContract,
	|	RecordsCounterpartyCounterparty.CorARAPObject             AS CorARAPObject,
	|	RecordsCounterpartyCounterparty.Currency                        AS Currency,
	|
	|	RecordsCounterpartyCounterparty.Sum                         AS Sum,
	|	RecordsCounterpartyCounterparty.SumCompl                     AS SumCompl,
	|	RecordsCounterpartyCounterparty.AmountInCurrency                  AS AmountInCurrency,
	|
	|	RecordsCounterpartyCounterparty.ARAPCurrency          AS ARAPCurrency,
	|	RecordsCounterpartyCounterparty.AmountInARAPCurrency    AS AmountInARAPCurrency,
	|	RecordsCounterpartyCounterparty.CorCurrencyOfARAPAccounting       AS CorCurrencyOfARAPAccounting,
	|	RecordsCounterpartyCounterparty.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|
	|	RecordsCounterpartyCounterparty.SourceOfARAPFinancialAccountingGroup           AS SourceOfARAPFinancialAccountingGroup,
	|	RecordsCounterpartyCounterparty.CorSourceOfARAPFinancialAccountingGroup        AS CorSourceOfARAPFinancialAccountingGroup
	|
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	PaymentDecryptionTable.LineNumber AS PaymentDecryptionTableLineNumber,
		|	&Organization AS Organization,
		|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	
		|	&BusinessOperation AS BusinessOperation,
		|	
		|	// Calculate the amount in the currency of management accounting.
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	(CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN PaymentDecryptionTable.SumMan
		|		ELSE 0 END) AS SumMan,
		|	(CASE
		|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
		|			THEN PaymentDecryptionTable.SumCompl
		|		ELSE 0 END) AS SumCompl,
		|
		|	PaymentDecryptionTable.RowID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.OtherCashReceipt) AS BusinessTransactionSetting
		|
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|	
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
		|	AND &UseAccountingOfOtherIncomeExpenses
		|
		|ORDER BY
		|	PaymentDecryptionTableLineNumber";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	0 AS PaymentDecryptionTableLineNumber,
		|	&Organization AS Organization,
		|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome) AS IncomeItem,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
		|	TableOfExchangeDifferences.Department AS Department,
		|	TableOfExchangeDifferences.LineOfBusiness AS LineOfBusiness,
		|
		|	TableOfExchangeDifferences.BusinessOperation AS BusinessOperation,
		|	TableOfExchangeDifferences.SumMan AS Sum,
		|	(CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN TableOfExchangeDifferences.SumMan
		|		ELSE 0 END) AS SumMan,
		|	(CASE
		|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
		|			THEN TableOfExchangeDifferences.SumCompl
		|		ELSE 0 END) AS SumCompl,
		|
		|	TableOfExchangeDifferences.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain) AS BusinessTransactionSetting
		|
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|
		|WHERE
		|	(TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)
		|
		|ORDER BY
		|	PaymentDecryptionTableLineNumber
		|";
	
	EndIf;
	
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt) Then
		Return "";	
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TableOfExchangeDifferences";
	
	QueryText = "
	|SELECT
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.CashAccountDivision AS Department,
	|	DocumentData.CashAccountLineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.CashRevaluation) AS BusinessOperation,
	|
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToConversionCurrency AS NUMBER(31,2))
	|		- DocumentData.ConversionAmount AS Sum,
	|
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		- CAST(DocumentData.ConversionAmount * &ConversionFactorOfConversionToCurrencyMan AS NUMBER(31,2))
	|	AS SumMan,
	|	
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		- CAST(DocumentData.ConversionAmount * &ConversionRateOfConversionToLocalCurrency AS NUMBER(31,2))
	|	AS SumCompl,
	|	DocumentData.DocumentID AS DocumentID
	|
	|INTO TableOfExchangeDifferences
	|FROM
	|	DocumentDataHeader AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashAccountReceiptNote");
		QueryText = StrReplace(QueryText, "DocumentData.CashAccountDivision", "DocumentData.CashAccount.Department");
		QueryText = StrReplace(QueryText, "DocumentData.CashAccountLineOfBusiness", "DocumentData.CashAccount.LineOfBusiness");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTableARAPDetails(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
		
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	PaymentDecryptionTable.LineNumber AS PaymentDecryptionTableLineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	PaymentDecryptionTable.IncomeItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	-CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	-CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	-CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|
	|	-CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	-CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherCashReceipt ) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|	
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		ExpenseItems.Ref = PaymentDecryptionTable.IncomeItem
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
	|	AND PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	0 AS PaymentDecryptionTableLineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS ExpenseItem,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|	TableOfExchangeDifferences.Department AS Department,
	|	TableOfExchangeDifferences.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	-TableOfExchangeDifferences.SumMan AS AmountIncludingVAT,
	|	-TableOfExchangeDifferences.SumMan AS AmountExcludingVAT,
	|	-TableOfExchangeDifferences.SumMan AS AmountExcludingVATMan,
	|	-TableOfExchangeDifferences.SumCompl AS AmountIncludingVATCompl,
	|	-TableOfExchangeDifferences.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	TableOfExchangeDifferences.BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TableOfExchangeDifferences.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss ) AS BusinessTransactionSetting
	|
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|	AND (TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.EmptyRef()) Then
			
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&PartnerFromDocument                     AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	&CounterpartyFromDocument                  AS Counterparty,
		|	DocumentData.CashAccountDivision      AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.OtherCashReceipt),
		|		VALUE(Enum.BusinessTransactions.CurrencyConversion),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty),
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor),
		|		VALUE(Enum.BusinessTransactions.EmptyRef)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	&AdvanceHolder                        AS Counterparty,
		|	DocumentData.CashAccountDivision     AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee),
		|		VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder)
		|	)";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	DocumentData.CashAccountSenderOwner  AS Counterparty,
		|	DocumentData.CashAccountDivision      AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	UNDEFINED                            AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	UNDEFINED                            AS Counterparty,
		|	DocumentData.CashAccountDivision      AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	UNDEFINED                            AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
		|		VALUE(Enum.BusinessTransactions.CashCollectionFromBank),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	UNDEFINED                            AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	UNDEFINED                            AS Counterparty,
		|	DocumentData.CashAccountDivision      AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	TRUE                                  AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	UNDEFINED                            AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromBank)
		|	)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined And ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashAccountReceiptNote");
		QueryText = StrReplace(QueryText, "DocumentData.CashAccountDivision", "DocumentData.CashAccount.Department");
		QueryText = StrReplace(QueryText, "DocumentData.CashAccountSenderOwner", "DocumentData.CashAccountIssuer.Owner");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany) Then
		
		Return;
		
	EndIf;
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.Ref = ARAPObjects.Object
		|				AND Table.ARAPObjectOfPaymentIsPartner = ARAPObjects.Partner
		|				AND Table.ARAPCurrency = ARAPObjects.ARAPCurrency
		|				AND NOT ARAPObjects.DeletionMark
		|";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates, True);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region CustomersARAPAccounting
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
			
		TextPayment = 
			"SELECT
			|	Table.Ref                                                           AS Ref,
			|	DocumentDataHeader.Organization                                               AS Organization,
			|	CASE WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
			|			THEN VALUE(Catalog.Partners.OurEnterprise)
			|		WHEN &ThereIsGiftCertificate = TRUE
			|			THEN &Partner
			|		ELSE Table.Partner
			|	END                                                                    AS Partner,
			|	
			|	Table.ARAPCurrency                                             AS ARAPCurrency,
			|	Table.ARAPObject                                                   AS ARAPObject,
			|	
			|	Table.AmountARAP                                              AS AmountARAP,
			|	Table.Sum                                                            AS Sum,
			|	0                                                                        AS IncreaseIsPaid,
			|	0                                                                        AS ReductionIsPaid,
			|	
			|	DocumentDataHeader.Date                                                AS RecorderDate,
			|	DocumentDataHeader.Date                                                AS DateOfCourse,
			|	Table.MaturityDate                                                    AS MaturityDate,
			|	DocumentDataHeader.Number                                               AS RecorderNumber,
			|	DocumentDataHeader.BusinessOperation                               AS BusinessOperation,
			|	VALUE(Enum.PaymentForms.CashAccountPayment_)                              AS PaymentMethod,
			|	Table.CashFlowItem                                    AS CashFlowItem,
			|	CASE 
			|		WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
			|			THEN CAST(Table.PaymentPurpose AS Document.CustomerCommercialInvoice)
			|		ELSE UNDEFINED 
			|	END                                                                    AS ProformaInvoice,
			|	DocumentDataHeader.Currency                                              AS DocumentCurrency,
			|	UNDEFINED                                                             AS LinkedDocument,
			|	Table.RowID                                              AS FinRecordID,
			|	&BusinessTransactionSetting                                          AS BusinessTransactionSetting
			|FROM
			|	DocumentDataTableDecryptionOfPayment AS Table
			|	
			|	LEFT JOIN DocumentDataHeader AS DocumentDataHeader
			|		ON Table.Ref = DocumentDataHeader.Ref
			|
			|";
			
		ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment);
	
	EndIf;
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	TextReturn = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
			
		TextReturn = "
			|SELECT
			|	Table.Ref                                                     AS Ref,
			|	Document.Organization                                               AS Organization,
			|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
			|		THEN VALUE(Catalog.Partners.OurEnterprise)
			|		ELSE Table.Partner
			|	END                                                              AS Partner,
			|	SettlementObjectPayment.Ref                                        AS ARAPObject,
			|	
			|	Table.ARAPCurrency                                       AS ARAPCurrency,
			|	Table.AmountARAP                                        AS AmountARAP,
			|	Table.Sum                                                      AS Sum,
			|	
			|	Document.Date                                                      AS RecorderDate,
			|	Document.Date                                                      AS DateOfCourse,
			|	Document.Number                                                     AS RecorderNumber,
			|	Document.BusinessOperation                                     AS BusinessOperation,
			|	VALUE(Enum.PaymentForms.CashAccountPayment_)                        AS PaymentMethod,
			|	Table.CashFlowItem                              AS CashFlowItem,
			|	Document.Currency                                                    AS DocumentCurrency,
			|	Table.RowID                                        AS FinRecordID,
			|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
			|		THEN VALUE(Catalog.BusinessTransactionsSettings.RefundFromAnotherCompany)
			|		ELSE VALUE(Catalog.BusinessTransactionsSettings.RefundFromVendor)
			|	END                                                              AS BusinessTransactionSetting
			|FROM
			|	DocumentDataTableDecryptionOfPayment AS Table
			|		INNER JOIN DocumentDataHeader AS Document
			|			ON Document.Ref = Table.Ref
			|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
			|			ON Table.Ref = SettlementObjectPayment.Object
			|				AND Table.ARAPObjectOfPaymentIsPartner = SettlementObjectPayment.Partner
			|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
			|				AND NOT SettlementObjectPayment.DeletionMark
			|";
		
	EndIf;
	
	TextDebtTransfer = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
			
		TextDebtTransfer = "
			|SELECT
			|	Table.Ref                                                           AS Ref,
			|	Document.Organization                                                     AS Organization,
			|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
			|		THEN VALUE(Catalog.Partners.OurEnterprise)
			|		ELSE Table.Partner
			|	END                                                                    AS Partner,
			|	SettlementObjectPayment.Ref                                              AS CalculationObjectReceiver,
			|	Table.ARAPObject                                                   AS CalculationObjectSource,
			|	
			|	Table.ARAPCurrency                                             AS ARAPCurrency,
			|	Document.Currency                                                          AS DocumentCurrency,
			|	Table.AmountARAP                                              AS AmountARAP,
			|	Table.Sum                                                            AS Sum,
			|	
			|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation,
			|	VALUE(Enum.PaymentForms.CashAccountPayment_)                              AS PaymentMethod,
			|	Document.Number                                                           AS RecorderNumber,
			|	Document.Date                                                            AS RecorderDate,
			|	Document.Date                                                            AS DateOfCourse,
			|	Table.CashFlowItem                                    AS CashFlowItem,
			|	Table.RowID                                              AS FinRecordID
			|FROM
			|	DocumentDataTableDecryptionOfPayment AS Table
			|		INNER JOIN DocumentDataHeader AS Document
			|			ON Document.Ref = Table.Ref
			|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
			|			ON Table.Ref = SettlementObjectPayment.Object
			|				AND Table.ARAPObjectOfPaymentIsPartner = SettlementObjectPayment.Partner
			|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
			|				AND NOT SettlementObjectPayment.DeletionMark
			|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
			|			ON Table.ARAPObject = ARAPObjects.Ref
			|WHERE
			|	SettlementObjectPayment.Ref <> ARAPObjects.Ref
			|";
	
	EndIf;

	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingRefundFromSupplier(Query, QueryTexts, Registers, TextReturn, TextDebtTransfer);
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.CashAccountReceiptNote) Then
		// Cash receipt order
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "OCR";
		PrintCommand.Presentation = NStr("vi = 'Phiếu thu 01-TT';
										|ru = 'Приходный кассовый ордер';
										|en = 'Incoming payment — Cash account'; fa = 'دریافت — صندوق';
										|it = 'Reversale di incasso';
										|pl = 'Asygnata kasowa przychodowa';
										|tr = 'Gelen ödeme - kasa hesabı'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	CashAccountReceiptNoteLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "OCR") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"OCR",
			NStr("vi = 'Phiếu thu 01-TT';
				|ru = 'Приходный кассовый ордер';
				|en = 'Incoming payment — Cash account'; fa = 'دریافت — صندوق';
				|it = 'Reversale di incasso';
				|pl = 'Asygnata kasowa przychodowa';
				|tr = 'Gelen ödeme - kasa hesabı'"),
			FormPrintedFormOfICO(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
		
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	CashAccountReceiptNoteLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.CashAccountReceiptNote.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
	
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"OCR");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormOfICO(PrintKit.Objects, PrintObjects, PrintParameters));
	EndDo;	
	CashAccountReceiptNoteLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);

	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.CashAccountReceiptNote",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "OCR", NStr("vi = 'Phiếu thu 01-TT';
																							|ru = 'Приходный кассовый ордер';
																							|en = 'Incoming payment — Cash account'; fa = 'دریافت — صندوق';
																							|it = 'Reversale di incasso';
																							|pl = 'Asygnata kasowa przychodowa';
																							|tr = 'Gelen ödeme - kasa hesabı'"), 1);
	CashAccountReceiptNoteLocalization.PrintFormsSet(PrintFormsSet);
	Return PrintFormsSet;
	
EndFunction

// Fills in the structure of print form recipients depending on the functional options
// 
// Parameters:
//     PrintObjectDataStructure - Structure - Fields:
//      * ArrayOfRecipientDetails - Array of String - Details of recipients of printed forms
//
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Counterparty";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ARAPDetails.Partner");
	EndIf;
	
EndProcedure

Function FormPrintedFormOfICO(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_OCR";
	Template = PrintManagement.PrintFormTemplate("Document.CashAccountReceiptNote.PF_MXL_CashAccountReceiptNote");
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date) AS DocumentDate,
	|	ISNULL(DocumentData.CorrectedDocument.Number, DocumentData.Number) AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.Description AS CompanyName,
	|	DocumentData.Organization.AbbreviatedDescription AS CompanyNameAbbreviated,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.CashAccount.Department AS DivisionRepresentation,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Presentation AS CounterpartyPresentation,
	|	DocumentData.ReceivedFrom AS ReceivedFrom,
	|	DocumentData.Basis AS Basis,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency.Presentation AS CurrencyPresentation
	|FROM
	|	Document.CashAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Number
	|;";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Selection           = Query.Execute().Select();
	
	AttributesOfParties = CashServer.InformationAboutRecipientPayerAccordingToDocuments(ObjectsArray);
	
	FirstDocument = True;
	While Selection.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TemplateArea = Template.GetArea("Header");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, Selection.Ref);
		TemplateArea.Parameters.Fill(Selection);
		
		// Recipient's abbreviated name
		FilterDescriptions = New Structure("Document, Flag", Selection.Ref, 4);
		NameInformation = AttributesOfParties.FindRows(FilterDescriptions);
		
		ParametersStructure = New Structure();
		ParametersStructure.Insert("RepresentationOfTheOrganization");
		If NameInformation.Count() > 0 Then
			ParametersStructure.RepresentationOfTheOrganization = NameInformation[0].AttributeValue;
		Else
			ParametersStructure.RepresentationOfTheOrganization = Selection.CompanyName;
		EndIf;
		TemplateArea.Parameters.Fill(ParametersStructure);
		
		TemplateArea.Parameters.DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(
			Selection.Number, 
			False,
			True);
		
		DataStructureOrganization = PrintFormGeneration.InformationAboutLegalEntity(Selection.Organization,
			Selection.DocumentDate);
		TemplateArea.Parameters.Fill(DataStructureOrganization);
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			Selection.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

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

#Region Other

Function CashFlowArticleOfDocument(DocumentData)
	
	If ValueIsFilled(DocumentData.CashFlowItem) Then
		CashFlowItem = DocumentData.CashFlowItem;
	Else
		CashFlowItem = Catalogs.CashFlowReportItems.PredefinedCFItem(
			DocumentData.BusinessOperation, DocumentData.Currency);
	EndIf;
	
	Return CashFlowItem;
	
EndFunction

Function DocumentSubdivision(DocumentData)

	If DocumentData.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount Then
		
		If ValueIsFilled(DocumentData.DocumentBasis)
			And CommonClientServer.HasAttributeOrObjectProperty(
					DocumentData.DocumentBasis, "CashTransferReferenceOrder") Then
				
			ReferenceOrder = Common.ObjectAttributeValue(DocumentData.DocumentBasis, "CashTransferReferenceOrder");
			Department = CashServer.InitiatorOfCashWithdrawal(ReferenceOrder, DocumentData.CashAccount);
			
		Else
			Department = Common.ObjectAttributeValue(DocumentData.CashAccount, "Department");
		EndIf;
		
	Else
		Department = DocumentData.Department;
	EndIf;
	
	Return Department;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
