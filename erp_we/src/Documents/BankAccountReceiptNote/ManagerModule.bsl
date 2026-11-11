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
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Department, Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
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
	
	BankAccountReceiptNoteLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.BankAccountReceiptNote") Then
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
		
		QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashFlowLimits(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		
		// Execution of the request and unloading of the received tables for the formation of movements
		BankAccountReceiptNoteLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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
//  Object - DocumentObject.BankAccountReceiptNote - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	
	FillParameters.GoodsSales = True;
	FillParameters.ImplementationOfWorksServices = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.BankAccountReceiptNote - the document to generate parameters for.
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
	
	GenerateFromLocalization.AddCommandCreateExchangeWithBanksBasedOnEmail(GenerationCommands);
	
	BusinessOperationsForCorrection = New Array;
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundFromVendor);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.OtherCashReceipt);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CurrencyConversion);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptFromLoansRepayment);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptUnderDeposits);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.LoanRepaymentByEmployee);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReturnByAdvanceHolder);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptFromAnotherAccount);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment);
	
	CommandCorrection = DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	If CommandCorrection <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CommandCorrection,
			"BusinessOperation",
			BusinessOperationsForCorrection,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	TheStornoTeam = DocumentCorrection.AddReverseCommand(
		GenerationCommands,
		EmptyRef().Metadata());
	
	If TheStornoTeam <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			TheStornoTeam,
			"BusinessOperation",
			BusinessOperationsForCorrection,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	CreateCommandBasedOnApplication = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	EconomicOperationsForInputOnBasisOf = New Array;
	EconomicOperationsForInputOnBasisOf.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	EconomicOperationsForInputOnBasisOf.Add(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment);
	EconomicOperationsForInputOnBasisOf.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	
	If CreateCommandBasedOnApplication <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication,
															"BusinessOperation",
															EconomicOperationsForInputOnBasisOf,
															DataCompositionComparisonType.InList);
	EndIf;
	
	CreateDatabaseWriteOffBasedCommand = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	If CreateDatabaseWriteOffBasedCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateDatabaseWriteOffBasedCommand,
															"BusinessOperation",
															EconomicOperationsForInputOnBasisOf,
															DataCompositionComparisonType.InList);
	EndIf;
		
	BankAccountReceiptNoteLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "receipt of non-cash DS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.BankAccountReceiptNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.BankAccountReceiptNote);
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
	
	BankAccountReceiptNoteLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	CASE WHEN DocumentsTable.ProcessedByBank THEN
	|		&ConductedByBank
	|	ELSE
	|		&TransactionNotConductedByBank
	|	END AS PresentationOfCurStatus,
	|	&ConductedByBank AS PresentationOfNewStatus,
	|	DocumentsTable.ProcessedByBank AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("ConductedByBank", NStr("vi = 'Được doanh nghiệp bởi ngân hàng';
												|ru = 'Проведено банком';
												|en = 'Processed by bank'; fa = 'پردازش‌شده توسط بانک';
												|it = 'Effettuato a cura della banca';
												|pl = 'Potwierdzono przez bank';
												|tr = 'Banka tarafından kaydedildi'"));
	Query.SetParameter("TransactionNotConductedByBank", NStr("vi = 'Chưa thực hiện bởi ngân hàng';
															|ru = 'Не проведено банком';
															|en = 'Not processed by bank'; fa = 'پردازش‌نشده توسط بانک';
															|it = 'Non è stato registrato dalla banca';
															|pl = 'Nie potwierdzono przez bank';
															|tr = 'Banka tarafından kaydedilmedi'"));
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - String - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

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
			"BusinessOperation,
			|ProcessedByBank,
			|Date,
			|BankPostingDate");
		BusinessOperation = StructureFillingData.BusinessOperation;
		ProcessedByBank       = StructureFillingData.ProcessedByBank;
		DocumentDate         = StructureFillingData.Date;
		BankPostingDate  = StructureFillingData.BankPostingDate;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		ProcessedByBank       = False;
		DocumentDate         = Date('00010101');
		BankPostingDate  = Date('00010101');
	Else
		BusinessOperation = FillingData.BusinessOperation;
		ProcessedByBank       = FillingData.ProcessedByBank;
		DocumentDate         = FillingData.Date;
		BankPostingDate  = FillingData.BankPostingDate;
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
	
	ParametersStructure.ChangesPaymentPlan                  = BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
									Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
									Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
									Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany;
	
	ParametersStructure.ChangesCalculationsByString           =
	"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|	OR
	|//Conditions of return beginning
	|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|//Conditions of return end
	|";
	
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		ParametersStructure.Counterparty                             = "Object.SenderBankAccount.Owner";
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
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CashAccount                            = "";
	
	If ProcessedByBank
		And BegOfDay(DocumentDate) <> BankPostingDate Then
		ParametersStructure.Date                             = "Object.BankPostingDate";
	Else
		ParametersStructure.Date                             = "Object.Date";
	EndIf;
	
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Manager                         = "";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	//Names of form elements for the current set of parameters
	ParametersStructure.FormItems.ARAPDetails               = "ARAPDetails";
	ParametersStructure.FormItems.AddToPaymentDecryption        = "ARAPDetailsSelectionByStock";
	
	ParametersStructure.SelectAccountsReceivable    = True;
	ParametersStructure.SelectOnlyUnconditionalDebt = BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
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
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		If BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
			ParametersStructure.Counterparty                             = "Object.SenderBankAccount.Owner";
			ParametersStructure.Partner                                = Catalogs.Partners.OurEnterprise;
		Else
			ParametersStructure.Counterparty                             = "Object.Counterparty";
			ParametersStructure.Partner                                = "Object.ARAPDetails.Partner";
		EndIf;
		
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
		ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
		ParametersStructure.AmountARAP              = "Form.AmountARAP";
		ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
		ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
		ParametersStructure.ARAPObjectSettings                  = "";
		ParametersStructure.PaymentMethod                      = "";
		ParametersStructure.ForeignCurrencyTransaction                    = "";
		ParametersStructure.Terms                       = "";
		ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
		ParametersStructure.CashAccount                            = "";
		
		If ProcessedByBank
			And BegOfDay(DocumentDate) <> BankPostingDate Then
			ParametersStructure.Date                             = "Object.BankPostingDate";
		Else
			ParametersStructure.Date                             = "Object.Date";
		EndIf;
		
		ParametersStructure.PaymentID             = "";
		ParametersStructure.Manager                         = "";
		ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
		ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
		ParametersStructure.VATTaxation               = "Object.VATTaxation";
		
		ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
		ParametersStructure.DocumentCurrencyViewOnly      = True;
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
EndFunction

#Region Other

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	Object - DocumentObject.BankAccountReceiptNote, FormDataStructure, Structure - Document data.
//	ArrayOfAllProps - Array of String - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array of String - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(Object, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	BusinessOperation = Object.BusinessOperation;
	
	If ArrayOfAllProps = Undefined Then
		ArrayOfAllProps = New Array;
	EndIf;
	If ArrayOfOperationDetails = Undefined Then
		ArrayOfOperationDetails = New Array;
	EndIf;
	
	ArrayOfAllProps.Add("CounterpartyBankAccount");
	ArrayOfAllProps.Add("SenderBankAccount");
	ArrayOfAllProps.Add("CurrencyOfConversion");
	ArrayOfAllProps.Add("CashAccountIssuer");
	ArrayOfAllProps.Add("Counterparty");
	ArrayOfAllProps.Add("ConversionRate");
	ArrayOfAllProps.Add("ConversionRateMultiplier");
	ArrayOfAllProps.Add("ConversionAmount");
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("Department");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("AcquiringContract");
	ArrayOfAllProps.Add("ExpenseItem");
	ArrayOfAllProps.Add("DimensionOfExpenses");
	ArrayOfAllProps.Add("KeepRecordsOfCommissionInARAPAccounting");
	ArrayOfAllProps.Add("CommissionARAPObject");
	ArrayOfAllProps.Add("FeeAmount");
	
	ArrayOfAllProps.Add("TaxType");
	
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("LineOfBusiness");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("VATTaxation");
	
	ArrayOfAllProps.Add("BankConfirmationAboutCashReceiptOnEmployeeAccount");
	ArrayOfAllProps.Add("WithdrawalDocument");
	
	ArrayOfAllProps.Add("ARAPDetails");
	ArrayOfAllProps.Add("ARAPDetails.ARAPCurrency");
	ArrayOfAllProps.Add("ARAPDetails.LoanDepositContract");
	ArrayOfAllProps.Add("ARAPDetails.LineOfBusiness");
	ArrayOfAllProps.Add("ARAPDetails.ARAPObject");
	ArrayOfAllProps.Add("ARAPDetails.PaymentPurpose");
	ArrayOfAllProps.Add("ARAPDetails.Partner");
	ArrayOfAllProps.Add("ARAPDetails.Department");
	ArrayOfAllProps.Add("ARAPDetails.CashFlowItem");
	ArrayOfAllProps.Add("ARAPDetails.AmountARAP");
	ArrayOfAllProps.Add("ARAPDetails.LoanAndDepositAmountType");
	ArrayOfAllProps.Add("ARAPDetails.VATRate");
	ArrayOfAllProps.Add("ARAPDetails.VATAmount");
	ArrayOfAllProps.Add("ARAPDetails.Organization");
	ArrayOfAllProps.Add("ARAPDetails.LeaseContracts");
	ArrayOfAllProps.Add("ARAPDetails.TypeOfLeasePayment");
	ArrayOfAllProps.Add("ARAPDetails.ARAPDocumentForLease");
	ArrayOfAllProps.Add("ARAPDetails.MaturityDate");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Department");
		ArrayOfOperationDetails.Add("ARAPDetails.LineOfBusiness");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("CurrencyOfConversion");
		ArrayOfOperationDetails.Add("ConversionRate");
		ArrayOfOperationDetails.Add("ConversionRateMultiplier");
		ArrayOfOperationDetails.Add("ConversionAmount");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("DocumentBasis");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
			Or BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
		
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		
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
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanAndDepositAmountType");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
		
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts Then
		
		ArrayOfOperationDetails.Add("WithdrawalDocument");
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram Then
		
		ArrayOfOperationDetails.Add("WithdrawalDocument");
		ArrayOfOperationDetails.Add("BankConfirmationAboutCashReceiptOnEmployeeAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount Then
		ArrayOfOperationDetails.Add("SenderBankAccount");
		ArrayOfOperationDetails.Add("DocumentBasis");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount Then
		ArrayOfOperationDetails.Add("CashAccountIssuer");
		ArrayOfOperationDetails.Add("DocumentBasis");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		ArrayOfOperationDetails.Add("SenderBankAccount");
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
		ArrayOfOperationDetails.Add("DocumentBasis");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ArrayOfOperationDetails.Add("SenderBankAccount");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("DocumentBasis");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AcquiringContract");
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("RecordCommission");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		ArrayOfOperationDetails.Add("KeepRecordsOfCommissionInARAPAccounting");
		ArrayOfOperationDetails.Add("CommissionARAPObject");
		ArrayOfOperationDetails.Add("FeeAmount");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.LeaseContracts");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.TypeOfLeasePayment");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPDocumentForLease");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TaxRefund Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("TaxType");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
	EndIf;
	
EndProcedure

// Determines the composition of households. operations of the document for which you do not use the transcript of the payment.
//
// Returns:
//    Array - business transactions without the use of payment decryption.
//
Function ArrayOfOperationsWithoutPaymentDecryption() Export
	
	OperationArray = New Array;
	
	OperationArray.Add(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment);
	OperationArray.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromAnotherAccount);
	OperationArray.Add(Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount);
	OperationArray.Add(Enums.BusinessTransactions.CurrencyConversion);
	OperationArray.Add(Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts);
	
	Return OperationArray;
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String- fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	
	Operations = Enums.BusinessTransactions;
	
	SelectionOfTransactionsWithPaymentIdentifier = New DataCompositionFilter();
	Filteroperations = Finances.NewFilter(SelectionOfTransactionsWithPaymentIdentifier, , , Type("DataCompositionFilterItemGroup"));
	Filteroperations.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.RefundFromLessor);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.TaxRefund);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CurrencyConversion);
	
	#Region Header
	// ProcessedByBank
	Item = Settings.Add();
	Item.Fields.Add("ProcessedByBank");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.CollectionOrder_2);
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	Item.Properties.Insert("ReadOnly");
	
	// BankPostingDate
	Item = Settings.Add();
	Item.Fields.Add("BankPostingDate");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "ProcessedByBank", False);
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	Item.Properties.Insert("OnlyViewWithoutBlankMark");
	
	// The date of the incoming document, the number of the incoming document
	Item = Settings.Add();
	Item.Fields.Add("IncomingDocumentDate");
	Item.Fields.Add("IncomingDocumentNumber");
	Finances.NewFilter(Item.Condition, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentDemand);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashRecieptByAcquiringTransactionsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.ReturnOfPayrollPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TaxRefund);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.CashRecieptByAcquiringTransactionsPayment);
	Item.Properties.Insert("Title", NStr("vi = 'Người nộp';
										|ru = 'Плательщик';
										|en = 'Payer'; fa = 'پرداخت‌کننده';
										|it = 'Soggetto pagante';
										|pl = 'Payer';
										|tr = 'Ödeyen'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashRecieptByAcquiringTransactionsPayment);
	Item.Properties.Insert("Title", NStr("vi = 'Thiết bị thanh toán thẻ';
										|ru = 'Эквайер';
										|en = 'Acquirer'; fa = 'پذیرنده';
										|it = 'Acquirer';
										|pl = 'Acquirer';
										|tr = 'Alıcı banka'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Nhà môi giới';
										|ru = 'Брокер';
										|en = 'Broker'; fa = 'کارگزار';
										|it = 'Брокер';
										|pl = 'Broker';
										|tr = 'Komisyoncu'"));
	
	// Contract For Connection To The Payment System
	Item = Settings.Add();
	Item.Fields.Add("AcquiringContract");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashRecieptByAcquiringTransactionsPayment);
	Item.Properties.Insert("Visible");
	
	// CounterpartyBankAccount
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashRecieptByAcquiringTransactionsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.UnremittedSalaryReturnToPersonalAccounts);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.ReturnOfPayrollPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TaxRefund);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản của người thanh toán';
										|ru = 'Счет плательщика';
										|en = 'Payer account'; fa = 'حساب پرداخت‌کننده';
										|it = 'Il conto del pagatore';
										|pl = 'Rachunek płatnika';
										|tr = 'Ödeyen hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản cá nhân';
										|ru = 'Лицевой счет';
										|en = 'Personal account'; fa = 'حساب شخصی';
										|it = 'Conto individuale';
										|pl = 'Konto osobiste';
										|tr = 'Kişisel hesap'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản của nhà môi giới';
										|ru = 'Счет брокера';
										|en = 'Broker account'; fa = 'Broker account';
										|it = 'Счет брокера';
										|pl = 'Broker account';
										|tr = 'Komisyoncunun hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	
	OFOperationsWithIndividuals = New Array;
	OFOperationsWithIndividuals.Add(Operations.LoanRepaymentByEmployee);
	OFOperationsWithIndividuals.Add(Operations.CashReturnByAdvanceHolder);
	OFOperationsWithIndividuals.Add(Operations.UnremittedSalaryReturnToPersonalAccounts);
	
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	CounterpartyIsNotFilledIn = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	CounterpartyIsNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(CounterpartyIsNotFilledIn, "Counterparty", , , DataCompositionComparisonType.NotFilled);
	
	Other_Operations = Finances.NewFilter(CounterpartyIsNotFilledIn, , , Type("DataCompositionFilterItemGroup"));
	Other_Operations.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	Finances.NewFilter(Other_Operations, "BusinessOperation", OFOperationsWithIndividuals, , DataCompositionComparisonType.InList);
	
	PhysicalPersonNotFilledIn = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	PhysicalPersonNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(PhysicalPersonNotFilledIn, "AdvanceHolder", , , DataCompositionComparisonType.NotFilled);
	Finances.NewFilter(PhysicalPersonNotFilledIn, "BusinessOperation", OFOperationsWithIndividuals, , DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("ReadOnly", True);
	
	// Department
	Item = Settings.Add();
	Item.Fields.Add("Department");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	OrGroup1 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.ReturnOfPayrollPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.UnremittedSalaryReturnToPersonalAccounts);
	Finances.NewFilter(AndGroup, "More.DivisionsOnPayrollAccountsAreIncluded", True);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TaxRefund);
	Item.Properties.Insert("Visible");
	
	// SenderBankAccount
	Item = Settings.Add();
	Item.Fields.Add("SenderBankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromAnotherAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Item.Properties.Insert("Visible");
	
	// CashAccountIssuer
	Item = Settings.Add();
	Item.Fields.Add("CashAccountIssuer");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCashRegisterToBankAccount);
	Item.Properties.Insert("Visible");
	
	// AdvanceHolder
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.UnremittedSalaryReturnToPersonalAccounts);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Người nhận tạm ứng';
										|ru = 'Подотчетное лицо';
										|en = 'Advance holder'; fa = 'تنخواه‌دار';
										|it = 'Titolare di anticipo';
										|pl = 'Osoba rozliczająca się za wydatki';
										|tr = 'Sorumlu kişi'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Nhân viên';
										|ru = 'Сотрудник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Employee';
										|tr = 'Çalışan'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.UnremittedSalaryReturnToPersonalAccounts);
	Item.Properties.Insert("Title", NStr("vi = 'Nhân viên';
										|ru = 'Сотрудник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Employee';
										|tr = 'Çalışan'"));
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashRecieptByAcquiringTransactionsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.UnremittedSalaryReturnToPersonalAccounts);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.ReturnOfPayrollPaymentByPayrollCardProgram);
	Item.Properties.Insert("Visible");
	
	// BankConfirmationAboutCashReceiptOnEmployeeAccount
	Item = Settings.Add();
	Item.Fields.Add("BankConfirmationAboutCashReceiptOnEmployeeAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.ReturnOfPayrollPaymentByPayrollCardProgram);
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "More.UsePayrollTM", True);
	Finances.NewFilter(OrGroup, "More.ListingListOfAccountablePersons", True);
	Item.Properties.Insert("Visible");
	
	// WithdrawalDocument
	Item = Settings.Add();
	Item.Fields.Add("WithdrawalDocument");
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.ReturnOfPayrollPaymentByPayrollCardProgram);
	Item.Properties.Insert("Visible");
	
	// ExpensesBusinessUnit
	Item = Settings.Add();
	Item.Fields.Add("ExpensesBusinessUnit");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", False);
	Item.Properties.Insert("Visible");
	
	// CommissionAgreement
	Item = Settings.Add();
	Item.Fields.Add("CommissionAgreement");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", True);
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
	
	// LabelCurrency
	Item = Settings.Add();
	Item.Fields.Add("LabelCurrency");
	Item.Fields.Add("LabelCurrencyCommission");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", False);
	Item.Properties.Insert("Visible");
	
	// Fee
	Item = Settings.Add();
	Item.Fields.Add("GroupCommission");
	Finances.NewFilter(Item.Condition, "RecordCommission", True);
	Item.Properties.Insert("Visible");
	
	// LabelInvertedPayment
	Item = Settings.Add();
	Item.Fields.Add("LabelInvertedPayment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Item.Properties.Insert("Visible");
	
	// TaxType
	Item = Settings.Add();
	Item.Fields.Add("TaxType");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.TaxRefund);
	Item.Properties.Insert("Visible");
	
	// TransferOfTaxesAndContributions
	Item = Settings.Add();
	Item.Fields.Add("TransferOfTaxesAndContributions");
	Item.Fields.Add("Decoration1");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.TaxRefund);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("TextDetailsOfPaymentToBudget");
	Finances.NewFilter(Item.Condition, "TransferOfTaxesAndContributions", True);
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.TaxRefund);
	Item.Properties.Insert("Visible");
	
	// UIP
	Item = Settings.Add();
	Item.Fields.Add("PaymentID");
	Item.Properties.Insert("Title", NStr("vi = 'ID thanh toán';
										|ru = 'УИП';
										|en = 'UIP'; fa = 'UIP';
										|it = 'УИП';
										|pl = 'UIP';
										|tr = 'BÖT'"));
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentID");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.TaxRefund);
	Finances.NewFilter(Item.Condition, "TransferOfTaxesAndContributions", True);
	Item.Properties.Insert("Title", NStr("vi = 'ID thanh toán';
										|ru = 'УИН';
										|en = 'Payment ID'; fa = 'شناسه پرداخت';
										|it = 'УИН';
										|pl = 'Payment ID';
										|tr = 'BÜT (Benzersiz Ücret Tanımlayıcısı)'"));
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentID");
	Finances.CopyFilter(SelectionOfTransactionsWithPaymentIdentifier, Item.Condition);
	Item.Properties.Insert("Visible");
	
	// The UIP is different
	Item = Settings.Add();
	Item.Fields.Add("SceneryOfUIPIsDifferent");
	Item.Fields.Add("UIPInscriptionIsDifferent");
	Item.Fields.Add("UIPDecorationDiffersInList");
	Item.Fields.Add("UIPInscriptionIsDistinguishedByList");
	Item.Fields.Add("DecorationOfUIPIsDifferentWithoutSplitting");
	Item.Fields.Add("DecryptionOfPaymentDecorationOfUIPIsDifferent");
	Finances.NewFilter(Item.Condition, "More.UIPIsDifferent", True);
	Finances.NewFilter(Item.Condition, "TransferOfTaxesAndContributions", False);
	Finances.CopyFilter(SelectionOfTransactionsWithPaymentIdentifier, Item.Condition);
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TaxRefund);
	Item.Properties.Insert("Visible");
	
	// Analytics of other output
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Department");
	Item.Fields.Add("DecryptionWithoutDivisionDivision");
	Item.Fields.Add("ARAPDetails.LineOfBusiness");
	Item.Fields.Add("DecodingWithoutSplittingTheDirectionOfActivity");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.OtherCashReceipt);
	Item.Properties.Insert("Visible");
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.CashFlowItem");
	Item.Fields.Add("DecodingWithoutSplittingTheCashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashReceipt);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.LoanRepaymentByEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReturnByAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromLessor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TaxRefund);
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromLoansRepayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptUnderDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptBorrowingsProvidedToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
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
	
	// Object of accounts, Basis of payment, Sums, rates
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.PaymentPurpose");
	Item.Fields.Add("DecryptionWithoutSplittingTheBasisOfThePayment");
	Item.Fields.Add("ARAPDetails.ARAPObject");
	Item.Fields.Add("DecryptionWithoutSplittingTheCalculationObject");
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
	Finances.NewFilter(Item.Condition, "More.ToUseARAPDocumentForLease", True);
	Item.Properties.Insert("Visible");
	
	// Organization - owner of the settlement object
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
	Finances.NewFilter(AndGroup, "More.AmountUnallocated", 0,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundFromAnotherCompany,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundFromVendor,, DataCompositionComparisonType.NotEqual);
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromOtherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundFromAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// SelectionByUIP
	Item = Settings.Add();
	Item.Fields.Add("SelectionByUIP");
	Finances.CopyFilter(SelectionOfTransactionsWithPaymentIdentifier, Item.Condition);
	Item.Properties.Insert("Visible");
	#EndRegion
	
EndProcedure

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	AdditionalAvailability - Boolean - Additional indication that the selection of articles and Analytics is available.
// 
// Returns:
// 	- Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, AdditionalAvailability = True) Export
	
	ChoiceParametersArray = New Array;
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.ARAPDetails";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	ChoiceParameters.FormItems.AssetRef.Add("DecodingWithoutSplittingTheIncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("ARAPDetailsIncomeItem");
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt);
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DecodingWithoutSplittingTheAssetLiabilityAnalysis");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ARAPDetailsAssetsLiabilitiesDimension");
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DecodingWithoutSplittingTheRevenueAnalyst");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("ARAPDetailsDimensionOfRevenue");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ChoiceParameters.AvailabilityByOperation =
		(BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment) And AdditionalAvailability;
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
EndFunction

// The function gets the details of the document to exchange with the "enterprise Accounting" configuration.
//
// Parameters:
//	DocumentRef - DocumentRef - The document for which you need to get the banking details.
//
// Returns:
//	Structure - The structure of the document details.
//
Function DocumentDetailsForExchangeWithAccounting(DocumentRef) Export
	
	Query = New Query("SELECT TOP 1
	|	DocumentData.CashFlowItem.OffsettingAccount AS OffsettingAccount,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.BankAccount.CashCurrency AS BankAccountCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CashFlowItem.OffsettingAccount <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DocumentData.IncomeItem.OffsettingAccount AS OffsettingAccount,
	|	DocumentData.IncomeItem AS IncomeItem
	|FROM
	|	Document.BankAccountReceiptNote.ARAPDetails AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherIncome)
	|	AND DocumentData.IncomeItem.OffsettingAccount <> """"
	|
	|ORDER BY
	|	DocumentData.LineNumber");
	Query.SetParameter("Ref", DocumentRef);
	ResultsArray = Query.ExecuteBatch();
	
	Selection = ResultsArray[0].Select();
	If Selection.Next() Then
		OffsettingAccount  = Selection.OffsettingAccount;
		BusinessOperation  = Selection.BusinessOperation;
		BankAccountCurrency = Selection.BankAccountCurrency;
		LocalAccountingCurrency = Selection.BankAccountCurrency;
	Else
		OffsettingAccount  = "";
		BusinessOperation  = Enums.BusinessTransactions.EmptyRef();
		BankAccountCurrency = Undefined;
		LocalAccountingCurrency = Undefined;
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
		
		If StrFind(OffsettingAccount, "57.02") <> 0
			And BankAccountCurrency <> LocalAccountingCurrency Then
			OperationKind = "ForeignExchangeBuying";
			
		ElsIf StrFind(OffsettingAccount, "57.22") <> 0
			And BankAccountCurrency = LocalAccountingCurrency Then
			OperationKind = "ProceedsFromSaleOfForeignCurrency";
			
		ElsIf StrFind(OffsettingAccount, "66") <> 0
		 Or StrFind(OffsettingAccount, "67") <> 0 Then
			OperationKind = "SettlementsOnLoansAndBorrowings";
			
		ElsIf StrFind(OffsettingAccount, "76") <> 0
		 Or StrFind(OffsettingAccount, "60") <> 0
		 Or StrFind(OffsettingAccount, "62") <> 0 Then
			OperationKind = "OtherSettlementsWithCounterparties";
			
		EndIf;
		
	EndIf;
	
	AttributesStructure1 = New Structure("OperationKind, Account, IncomeItem",
		OperationKind,
		OffsettingAccount,
		IncomeItem);
	
	Return AttributesStructure1;
		
EndFunction

// Returns a flag indicating whether the specified document number is busy for the period - year.
//
// Parameters:
//   Date - Date - the date on which the number uniqueness check is performed
//   VerifiedNumber - String - document number to be checked for uniqueness
//
// Returns:
//   Boolean - True if the number is unique, False if the number already exists
//
Function ThisIsUniqueDocumentNumber(Date, VerifiedNumber) Export

	Query = New Query;
	Query.Text = 
		"SELECT
		|	BankAccountReceiptNote.Ref AS Ref
		|FROM
		|	Document.BankAccountReceiptNote AS BankAccountReceiptNote
		|WHERE
		|	BankAccountReceiptNote.Number = &Number
		|	AND BankAccountReceiptNote.Date BETWEEN BEGINOFPERIOD(&Date, YEAR) AND ENDOFPERIOD(&Date, YEAR)";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Number", VerifiedNumber);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Result;

EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return BankAccountReceiptNoteLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return BankAccountReceiptNoteLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	TaxType - CatalogRef.TaxContributionKinds - Type of tax.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation, TaxType) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpReflectionAccountInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.ARAPDetails";
	SetupParameters.AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
		Or (BusinessOperation = Enums.BusinessTransactions.TaxRefund
			And LocalAccntingServer.TypesOfTaxesWithAccountSettings().Find(TaxType) <> Undefined);
	SetupParameters.ArticleType = "ArticleType";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("DecodingWithoutSplittingRepresentationOfReflectionInReglAccounting");
	SetupParameters.FormItems.Add("ARAPDetailsPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region AssetAndLiabilityItem
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.TaxRefund
		And LocalAccntingServer.TypesOfTaxesWithAccountSettings().Find(TaxType) = Undefined;
	
	SetupParameters.AssetAndLiabilityItem = "";
	SetupParameters.AssetsLiabilitiesDimension = "";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";
	
	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
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
	|	OR ValueAllowed(ARAPDetails.Organization, Null AS TRUE) AND BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|	)AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor) OR BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|	THEN ValueAllowed(ARAPDetails.Partner, Null AS TRUE)
	|	ELSE TRUE END 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor) OR BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|	THEN ValueAllowed(ARAPDetails.Partner, Null AS TRUE)
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

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	Data.Insert("ExternalDocumentName", TrimAll(Data.PaymentDocumentType));
	Data.Delete("PaymentDocumentType");
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "BankAccountReceiptNote");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("PaymentDocumentType");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

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
	
	FullDocumentName = "Document.BankAccountReceiptNote";
	
	If RegisterName = "CashToBePaid" Then
		
		RedefiningParameterCalculation.Insert("Period", "
			|CASE WHEN NOT DocumentData.ProcessedByBank
			|	OR BEGINOFPERIOD(DocumentData.Date) = DocumentData.BankPostingDate
			|	OR DocumentData.Patch THEN
			|		DocumentData.Date
			|	ELSE
			|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
			|END");
		
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("Period", "
			|CASE WHEN NOT DocumentData.ProcessedByBank
			|	OR BEGINOFPERIOD(DocumentData.Date) = DocumentData.BankPostingDate
			|	OR DocumentData.Patch THEN
			|		DocumentData.Date
			|	ELSE
			|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
			|END");
		RedefiningParameterCalculation.Insert("SenderOrganization", "DocumentData.SenderBankAccount.Owner");
		RedefiningParameterCalculation.Insert("PartnerFromDocument", "
			|CASE
			|	WHEN
			|		DocumentData.BusinessOperation IN (
			|			VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|	THEN
			|		VALUE(Catalog.Partners.OurEnterprise)
			|	ELSE
			|		DocumentData.Partner
			|END");
		RedefiningParameterCalculation.Insert("CounterpartyFromDocument", "
			|CASE
			|	WHEN
			|		DocumentData.BusinessOperation IN (
			|			VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|	THEN
			|		DocumentData.SenderBankAccount.Owner
			|	ELSE
			|		DocumentData.Counterparty
			|END");
			
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
	Query.SetParameter("StartDateOfTransferViaIntermediateAccount", Date('00010101'));
	
	If GetFunctionalOption("UsePayroll") Then
		Query.SetParameter("StartDateOfTransferViaIntermediateAccount",
			Constants.StartDateOfSalaryTransferViaTransfersOnWay.Get());
	EndIf;
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
	|	CASE WHEN NOT DocumentData.ProcessedByBank
	|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate
	|		OR DocumentData.Patch THEN
	|		DocumentData.Date
	|	ELSE
	|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
	|	END AS Period,
	|	CASE WHEN NOT DocumentData.ProcessedByBank
	|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate THEN
	|		DocumentData.Date
	|	ELSE
	|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
	|	END AS RatesPeriod,
	|	DocumentData.ProcessedByBank                         AS ProcessedByBank,
	|
	|	DocumentData.IncomingDocumentNumber                 AS IncomingDocumentNumber,
	|	DocumentData.Number                                   AS Number,
	|	DocumentData.IncomingDocumentDate                  AS IncomingDocumentDate,
	|	DocumentData.Date                                    AS Date,
	|	DocumentData.PaymentPurposes                       AS PaymentPurposes,
	|	DocumentData.Currency                                  AS Currency,
	|	DocumentData.CurrencyOfConversion                       AS CurrencyOfConversion,
	|	DocumentData.Organization                             AS Organization,
	|	DocumentData.CompanyParentCompany          AS ParentCompany,
	|	DocumentData.BankAccount                          AS BankAccount,
	|	DocumentData.BankAccountDivision             AS Department,
	|	DocumentData.BankAccountLineOfBusiness   AS LineOfBusinessCash,
	
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
	|	END                                                   AS Partner,
	|
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.BankAccountSenderOwner
	|	
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Counterparties.RetailCustomer)
	|	
	|	ELSE
	|		DocumentData.Counterparty
	|	END                                                   AS Counterparty,
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
	|	END                                                   AS PartnerFromDocument,
	|
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|				VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.BankAccountSenderOwner
	|		ELSE
	|			DocumentData.Counterparty
	|	END                                                   AS CounterpartyFromDocument,
	
	|	DocumentData.BankAccountSenderOwner       AS SenderOrganization,
	|	DocumentData.BusinessOperation                   AS BusinessOperation,
	
	|	CASE WHEN
	|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount)
	|	THEN
	|		CASE WHEN DocumentData.Currency = DocumentData.CompanyLocalAccountingCurrency THEN
	|			VALUE(Catalog.CashFlowReportItems.CashDepositToBankAccount)
	|		ELSE
	|			VALUE(Catalog.CashFlowReportItems.CashDepositToBankAccountInForeignCurrency)
	|		END
	|	WHEN
	|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount)
	|	THEN
	|		VALUE(Catalog.CashFlowReportItems.TransferCashToAnotherAccount)
	|	ELSE
	|		DocumentData.CashFlowItem
	|	END AS CashFlowItem,
	
	|	DocumentData.TargetFundItem AS TargetFundItem,
	|
	|	DocumentData.WithdrawalDocument AS WithdrawalDocument,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted                AS Posted,
	|	ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE) AS ThereIsGiftCertificate,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting
	|	, CASE
	|		WHEN NOT DocumentData.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentData.Date) = DocumentData.BankPostingDate
	|				OR DocumentData.Patch
	|			THEN DocumentData.Date
	|		ELSE ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
	|	END >= &StartDateOfTransferViaIntermediateAccount
	|	AND &StartDateOfTransferViaIntermediateAccount <> DATETIME(1, 1, 1) AS TransferViaTransfersOnWay
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|		
	|	LEFT JOIN AvailabilityOfTypeOfSettlementObjectGiftCertificate AS AvailabilityOfGiftCertificateType
	|	ON TRUE
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
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.PaymentDocumentType AS PaymentDocumentType,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.SenderBankAccount AS SenderBankAccount,
	|	DocumentData.CashAccountIssuer AS CashAccountIssuer,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.PaymentPurposes AS PaymentPurposes,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.WithdrawalDocument AS WithdrawalDocument,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.ConversionRate AS ConversionRate,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.Department AS Department,
	|	DocumentData.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.ProcessedByBank AS ProcessedByBank,
	|	DocumentData.BankPostingDate AS BankPostingDate,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	DocumentData.PaymentID AS PaymentID,
	|	DocumentData.ConversionAmount AS ConversionAmount,
	|	DocumentData.ExportDate AS ExportDate,
	|	DocumentData.ImportDate AS ImportDate,
	|	DocumentData.ImportErrors AS ImportErrors,
	|	DocumentData.FormattedPurposeOfPayment AS FormattedPurposeOfPayment,
	|	DocumentData.StatementData AS StatementData,
	|	DocumentData.NameOfCounterparty AS NameOfCounterparty,
	|	DocumentData.BankConfirmationAboutCashReceiptOnEmployeeAccount AS BankConfirmationAboutCashReceiptOnEmployeeAccount,
	|	DocumentData.EntriesByEmployees AS EntriesByEmployees,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.KeyOfTransactionWithForeignCurrency AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.Author AS Author,
	|	DocumentData.AcquiringContract AS AcquiringContract,
	|	DocumentData.RecordCommission AS RecordCommission,
	|	DocumentData.FeeAmount AS FeeAmount,
	|	DocumentData.CommissionARAPObject AS CommissionARAPObject,
	|	DocumentData.KeepRecordsOfCommissionInARAPAccounting AS KeepRecordsOfCommissionInARAPAccounting,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.TargetFundItem AS TargetFundItem,
	|	DocumentData.TransferOfTaxesAndContributions AS TransferOfTaxesAndContributions,
	|	DocumentData.AuthorStatus AS AuthorStatus,
	|	DocumentData.BCCode AS BCCode,
	|	DocumentData.RNCPSRNCMTCode AS RNCPSRNCMTCode,
	|	DocumentData.BasisIndicator AS BasisIndicator,
	|	DocumentData.PeriodIndicator AS PeriodIndicator,
	|	DocumentData.NumberIndicator AS NumberIndicator,
	|	DocumentData.DateIndicator AS DateIndicator,
	|	DocumentData.TaxType AS TaxType,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	DocumentData.KindOfFundsTransferToBudget AS KindOfFundsTransferToBudget,
	|	DocumentData.TypeIndicator AS TypeIndicator,
	|	DocumentData.Organization.ParentCompany AS CompanyParentCompany,
	|	DocumentData.BankAccount.Department AS BankAccountDivision,
	|	DocumentData.BankAccount.LineOfBusiness AS BankAccountLineOfBusiness,
	|	DocumentData.SenderBankAccount.Owner AS BankAccountSenderOwner,
	|	DocumentData.SenderBankAccount.LineOfBusiness AS
	|		BankAccountSenderLineOfBusiness,
	|	DocumentData.Organization.LocalAccountingCurrency AS CompanyLocalAccountingCurrency,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Counterparty.Partner AS CounterpartyPartner,
	|	DocumentData.BankAccount.CashCurrency AS BankAccountCashCurrency,
	|	DocumentData.AcquiringContract.CashFlowItemCommission AS
	|		AcquiringContractCashFlowItemFee,
	|	DocumentData.AcquiringContract.Partner AS AcquiringContractPartner,
	|	DocumentData.AcquiringContract.LineOfBusiness AS AcquiringContractLineOfBusiness
	|INTO DocumentDataHeader
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
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
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	PaymentDecryptionTable.MaturityDate AS MaturityDate,
	|	PaymentDecryptionTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	PaymentDecryptionTable.ARAPObject.Partner AS ARAPObjectIsPartner,
	|	PaymentDecryptionTable.ARAPObject.Contract AS ARAPObjectContract,
	|	PaymentDecryptionTable.ARAPObject.VATTaxation AS ARAPObjectTaxationOfVAT,
	|	PaymentDecryptionTable.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	PaymentDecryptionTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	PaymentDecryptionTable.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness AS ARAPObjectRegistersOfMutualSettlementsAreNotDividedAccordingToAreasOfActivity,
	|	CASE
	|		WHEN PaymentDecryptionTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|			THEN
	|				 VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE 
	|			PaymentDecryptionTable.Partner
	|	END AS ARAPObjectOfPaymentIsPartner,
	|	PaymentDecryptionTable.LeaseContracts.LineOfBusiness AS LeaseContractLineOfBusiness,
	|	PaymentDecryptionTable.LeaseContracts.Department AS LeaseContractDivision,
	|	PaymentDecryptionTable.LoanDepositContract.Department AS ContractOfLoanDepositDivision,
	|	PaymentDecryptionTable.LoanDepositContract.LineOfBusiness AS LoanDepositContractLineOfBusiness
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.BankAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.BankAccountReceiptNote"));
	Values.Insert("UseCustomerCommercialInvoices",               GetFunctionalOption("UseCustomerCommercialInvoices"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses",           GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("ControlIssueOfCashByPurposes",       GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Values.Insert("IDOfUnusedFinRecord",            DocumentsPosting.IDOfUnusedFinRecord());
	
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency,
			Undefined,
			Attributes.RatesPeriod,
			Attributes.Organization);
			
		ConversionFactors = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.CurrencyOfConversion,
			Undefined,
			Attributes.RatesPeriod,
			Attributes.Organization);
		
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
		ConversionRateToConversionCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Attributes.Currency,
			Attributes.CurrencyOfConversion,
			Attributes.RatesPeriod,
			LocalAccountingCurrency);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionFactorOfConversionToCurrencyMan",   ConversionFactors.ConversionRateToManCurrency);
		Values.Insert("ConversionRateOfConversionToLocalCurrency",  ConversionFactors.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionRateToConversionCurrency",      ConversionRateToConversionCurrency);
		
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		Values.Insert("SourceDocumentNumber", ?(ValueIsFilled(Attributes.IncomingDocumentNumber),
			Attributes.IncomingDocumentNumber, ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number, True, True)));
		Values.Insert("SourceDocumentDate", ?(ValueIsFilled(Attributes.IncomingDocumentDate),
			Format(Attributes.IncomingDocumentDate, "DLF=D"), Format(Attributes.Date, "DLF=D")));
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query, DocumentObject = Undefined)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestForAnalytics = New Query;
	RequestForAnalytics.TempTablesManager = Query.TempTablesManager;
	
	RequestForAnalytics.Text ="";
	If Not (RequestForAnalytics.TempTablesManager <> Undefined 
		And RequestForAnalytics.TempTablesManager.Tables.Find("TTTableOfCalculationObjects") <> Undefined) Then
		
		RequestForAnalytics.Text = RequestTextTemporaryTableOfCalculationObjects(RequestForAnalytics, New ValueList, DocumentObject);
		RequestForAnalytics.Text = RequestForAnalytics.Text + "
		|;
		|/////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	RequestForAnalytics.Text = StrReplace(RequestForAnalytics.Text, "INTO TableOfCalculationObjects", "INTO TTTableOfCalculationObjects");
	
	RequestForAnalytics.Text = RequestForAnalytics.Text + "
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness 
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|			ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)  AS LineOfBusiness
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
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)  AS LineOfBusiness
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
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef)  = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	&Counterparty AS Counterparty,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		
	|	INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|		ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND VALUE(Catalog.Partners.OurEnterprise) = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|	
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Contract AS Contract,
	|	&Counterparty AS Counterparty,
	|	&Partner AS Partner,
	|	&LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataHeader AS PaymentTable_2
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization= Dimension.Organization
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
	|		)";
	
	If DocumentObject = Undefined Then
		QueryTextForAnalytics = StrReplace(QueryTextForAnalytics, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountReceiptNote.ARAPDetails");
		QueryTextForAnalytics = StrReplace(QueryTextForAnalytics, "DocumentDataHeader", "Document.BankAccountReceiptNote");
	EndIf;
	
	RequestForAnalytics.Text = RequestForAnalytics.Text + QueryTextForAnalytics;
	
	RequestForAnalytics.SetParameter("Ref",                  Query.Parameters.Ref);
	RequestForAnalytics.SetParameter("Organization",             Query.Parameters.Organization);
	RequestForAnalytics.SetParameter("Counterparty",              Query.Parameters.Counterparty);
	RequestForAnalytics.SetParameter("Partner",                 Query.Parameters.Partner);
	RequestForAnalytics.SetParameter("LineOfBusiness", Query.Parameters.LineOfBusiness);
	RequestForAnalytics.SetParameter("BusinessOperation",   Query.Parameters.BusinessOperation);
	
	If ValueIsFilled(Query.Parameters.Contract) Then
		RequestForAnalytics.SetParameter("Contract",                         Query.Parameters.Contract);
	ElsIf Not ValueIsFilled(Query.Parameters.Contract)
			And Query.Parameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Then
		RequestForAnalytics.SetParameter("Contract",                         Catalogs.IntercompanyContracts.EmptyRef());
	Else
		RequestForAnalytics.SetParameter("Contract",                         Catalogs.CounterpartyContracts.EmptyRef());
	EndIf;
	
	Selection = RequestForAnalytics.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	If ARAPAccountingServer.BusinessOperationRefundOfFunds(Query.Parameters.BusinessOperation) Then
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(RequestForAnalytics.Parameters);
	Else
		AccountingDimensionByPartners = Undefined;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized", True);
	
EndProcedure

Function RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "TableOfCalculationObjects";
	
	ArrayOfTemporaryTables = New Array;
	
	If Query.TempTablesManager <> Undefined 
		And Query.TempTablesManager.Tables.Find("DecryptionOfPaymentSettlementObjects") = Undefined Then
	
		TextObjectsOfCalculationsDecryption = "
		|SELECT DISTINCT
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	PaymentDecryptionTable.ARAPObjectOfCompany AS Organization,
		|	PaymentDecryptionTable.ARAPObjectContract AS Contract,
		|	PaymentDecryptionTable.ARAPObjectTaxationOfVAT AS VATTaxation,
		|	PaymentDecryptionTable.ObjectOfCalculationsDivision AS Department,
		|	PaymentDecryptionTable.ARAPObjectLineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.ARAPObjectRegistersOfMutualSettlementsAreNotDividedAccordingToAreasOfActivity AS ARAPObjectRegistersOfMutualSettlementsAreNotDividedAccordingToAreasOfActivity
		|INTO DecryptionOfPaymentSettlementObjects
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
		|WHERE
		|	PaymentDecryptionTable.Ref = &Ref
		|	AND PaymentDecryptionTable.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND NOT &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))
		|
		|INDEX BY
		|	LineOfBusiness
		|";
	
		ArrayOfTemporaryTables.Add(TextObjectsOfCalculationsDecryption);
		
	EndIf;
	
	TextLineOfBusiness = "
	|SELECT
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.Organization AS Organization,
	|	PaymentDecryptionTable.Contract AS Contract,
	|	PaymentDecryptionTable.VATTaxation AS VATTaxation,
	|	PaymentDecryptionTable.Department AS Department,
	|	CASE
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundFromVendor), VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|					AND ISNULL(Directions.VendorARAP, FALSE) AND NOT PaymentDecryptionTable.ARAPObjectRegistersOfMutualSettlementsAreNotDividedAccordingToAreasOfActivity
	|				OR NOT &BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundFromVendor), VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|					AND ISNULL(Directions.IncomeAccounting, FALSE) AND NOT PaymentDecryptionTable.ARAPObjectRegistersOfMutualSettlementsAreNotDividedAccordingToAreasOfActivity
	|			THEN PaymentDecryptionTable.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness
	|INTO TableOfCalculationObjects
	|FROM
	|	DecryptionOfPaymentSettlementObjects AS PaymentDecryptionTable
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|		ON PaymentDecryptionTable.LineOfBusiness = Directions.Ref
	|
	|INDEX BY
	|	ARAPObject
	|";
	
	ArrayOfTemporaryTables.Add(TextLineOfBusiness);
	QueryText = StrConcat(ArrayOfTemporaryTables, Common.QueryBatchSeparator());
	
	If DocumentObject = Undefined Then
		 QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountReceiptNote.ARAPDetails");
		 QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectOfCompany", "PaymentDecryptionTable.ARAPObject.Organization");
		 QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectContract", "PaymentDecryptionTable.ARAPObject.Contract");
		 QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectTaxationOfVAT", "PaymentDecryptionTable.ARAPObject.VATTaxation");
		 QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ObjectOfCalculationsDivision", "PaymentDecryptionTable.ARAPObject.Department");
		 QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectLineOfBusiness", "PaymentDecryptionTable.ARAPObject.LineOfBusiness");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectRegistersOfMutualSettlementsAreNotDividedAccordingToAreasOfActivity", "PaymentDecryptionTable.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness");
	EndIf;
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "PaymentDecryptionTable";
	
	If Not DocumentsPosting.ThereIsQueryTable("GeneralPaymentDescriptionTable", QueryTexts) Then
		QueryTextTemporaryTableARAPDetailsGeneral(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryTextArray = New Array;
	
	If DocumentObject <> Undefined
		And Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor)
		Or DocumentObject = Undefined Then
		
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	ISNULL(Dimension.Organization, UNDEFINED) AS Organization,
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	PaymentDecryptionTable.Contract AS Contract,
		|	PaymentDecryptionTable.ProformaInvoice AS ProformaInvoice,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.OrderDivision_ AS OrderDivision_,
		|
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	UNDEFINED AS LoanDepositContract,
		|	UNDEFINED AS LoanAndDepositAmountType,
		|	UNDEFINED AS LeaseContracts,
		|	UNDEFINED AS TypeOfLeasePayment,
		|	UNDEFINED AS ARAPDocumentForLease,
		|
		|	PaymentDecryptionTable.Sum AS Sum,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.AmountARAP,
		|	PaymentDecryptionTable.ARAPCurrency,
		|	
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.VATAmount AS VATAmount,
		|	PaymentDecryptionTable.VATAmountMan AS VATAmountMan,
		|	PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|
		|	PaymentDecryptionTable.VATTaxation AS VATTaxation,
		|	PaymentDecryptionTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|
		|FROM
		|	GeneralPaymentDescriptionTable AS PaymentDecryptionTable
		|
		|	LEFT JOIN
		|		Catalog.DimensionKeysOfAccountingByPartners AS Dimension
		|	ON
		|		PaymentDecryptionTable.AccountingDimensionByPartners = Dimension.Ref
		|WHERE
		|	NOT &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty),
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
		|		)
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		Or DocumentObject = Undefined Then
		
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	PaymentDecryptionTable.Organization AS Organization,
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS ProformaInvoice,
		|
		|	ContractData.LineOfBusiness AS LineOfBusiness,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|	ContractData.Department AS Department,
		|	UNDEFINED AS OrderDivision_,
		|
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
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
		|	PaymentDecryptionTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|
		|FROM
		|	GeneralPaymentDescriptionTable AS PaymentDecryptionTable
		|	
		|	INNER JOIN
		|		Catalog.LoanAndDepositContracts AS ContractData
		|	ON
		|		PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
		|WHERE
		|	&BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		|		)
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	If (DocumentObject <> Undefined
		And DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor)
		Or DocumentObject = Undefined Then
		
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	PaymentDecryptionTable.Organization AS Organization,
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS ProformaInvoice,
		|
		|	ContractData.LineOfBusiness AS LineOfBusiness,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|	ContractData.Department AS Department,
		|	UNDEFINED AS OrderDivision_,
		|
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
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
		|	PaymentDecryptionTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|
		|FROM
		|	GeneralPaymentDescriptionTable AS PaymentDecryptionTable
		|	
		|	INNER JOIN
		|		Catalog.LeaseContract AS ContractData
		|	ON
		|		PaymentDecryptionTable.LeaseContracts = ContractData.Ref
		|WHERE
		|	&BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
		|		)
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	NestedQuery = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT *
	|INTO PaymentDecryptionTable
	|FROM
	|	&NestedQuery AS NestedQuery
	|";
	QueryText = StrReplace(QueryText, "&NestedQuery", "(" + NestedQuery + ")");
	
	QueryTexts.Add(QueryText, TempTableName);
		
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableARAPDetailsGeneral(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "GeneralPaymentDescriptionTable";
	
	InitializeTrackingAnalyticsKeysForPartners(Query, DocumentObject);
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfTemporaryTables = New Array;
	
	PartnerAnalyticsText = 
	"SELECT
	|	AccountingDimensionByPartners.Partner AS Partner,
	|	AccountingDimensionByPartners.Organization AS Organization,
	|	AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	AccountingDimensionByPartners.Contract AS Contract,
	|	AccountingDimensionByPartners.LineOfBusiness AS LineOfBusiness,
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey
	|INTO AccountingAnalyticsForPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Counterparty = &Counterparty";
	
	ArrayOfTemporaryTables.Add(PartnerAnalyticsText);
	
	TextOfCalculationObjects = 
	"SELECT
	|	TableOfCalculationObjects.ARAPObject AS ARAPObject,
	|	TableOfCalculationObjects.Organization AS Organization,
	|	ISNULL(AccountingAnalyticsForPartners.DimensionKey, UNDEFINED) AS DimensionKey,
	|	ISNULL(AccountingAnalyticsForPartners.Partner, UNDEFINED) AS Partner
	|INTO ObjectsOfSettlementsWithAnalyticsByPartners
	|FROM
	|	TableOfCalculationObjects AS TableOfCalculationObjects
	|		INNER JOIN AccountingAnalyticsForPartners AS AccountingAnalyticsForPartners
	|		ON TableOfCalculationObjects.Organization = AccountingAnalyticsForPartners.Organization
	|			AND TableOfCalculationObjects.Contract = AccountingAnalyticsForPartners.Contract
	|			AND TableOfCalculationObjects.LineOfBusiness = AccountingAnalyticsForPartners.LineOfBusiness";
	
	ArrayOfTemporaryTables.Add(TextOfCalculationObjects);
	
	TextOfPaymentData =
	"SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	ISNULL(TableOfCalculationObjects.Contract, UNDEFINED) AS Contract,
	|	CAST(PaymentDecryptionTable.PaymentPurpose AS Document.CustomerCommercialInvoice) AS ProformaInvoice,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
	|			THEN PaymentDecryptionTable.LineOfBusiness
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromLessor)
	|			THEN PaymentDecryptionTable.LeaseContractLineOfBusiness
	|		ELSE ISNULL(TableOfCalculationObjects.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS LineOfBusiness,
	|	PaymentDecryptionTable.LeaseContractLineOfBusiness AS LeaseContractLineOfBusiness,
	|	PaymentDecryptionTable.LoanDepositContractLineOfBusiness AS LoanDepositContractLineOfBusiness,
	|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
	|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
	|			THEN PaymentDecryptionTable.Department
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromLessor)
	|			THEN PaymentDecryptionTable.LeaseContractDivision
	|	ELSE
	|		PaymentDecryptionTable.Department
	|	END AS Department,
	|	ISNULL(TableOfCalculationObjects.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS OrderDivision_,
	|
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
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
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
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
	|	PaymentDecryptionTable.RowID AS RowID,
	|	DocumentInpayment.DocumentID AS DocumentID,
	|	CASE
	|		WHEN &ThereIsGiftCertificate
	|			THEN &Partner
	|		WHEN PaymentDecryptionTable.Partner = VALUE(Catalog.Partners.EmptyRef)
	|			THEN DocumentInpayment.CounterpartyPartner
	|		ELSE PaymentDecryptionTable.Partner
	|	END AS Partner
	|INTO DataOfPayment
	|FROM
	|	DocumentDataHeader AS DocumentInpayment
	|		INNER JOIN DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|			LEFT JOIN TableOfCalculationObjects AS TableOfCalculationObjects
	|			ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|		ON DocumentInpayment.Ref = PaymentDecryptionTable.Ref
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|";
	
	ArrayOfTemporaryTables.Add(TextOfPaymentData);
	
	QueryTextArray = New Array;
	
	If DocumentObject <> Undefined
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
		Or DocumentObject = Undefined Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	ObjectsOfCalculationsAnalyticsIntercampany.Organization AS Organization,
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	PaymentDecryptionTable.Contract AS Contract,
		|	PaymentDecryptionTable.ProformaInvoice AS ProformaInvoice,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.OrderDivision_ AS OrderDivision_,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
		|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
		|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
		|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
		|	PaymentDecryptionTable.ARAPDocumentForLease AS ARAPDocumentForLease,
		|	PaymentDecryptionTable.Sum AS Sum,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
		|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.VATAmount AS VATAmount,
		|	PaymentDecryptionTable.VATAmountMan AS VATAmountMan,
		|	PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|	PaymentDecryptionTable.VATTaxation AS VATTaxation,
		|	ISNULL(ObjectsOfCalculationsAnalyticsIntercampany.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|FROM
		|	DataOfPayment AS PaymentDecryptionTable
		|		LEFT JOIN ObjectsOfSettlementsWithAnalyticsByPartners AS ObjectsOfCalculationsAnalyticsIntercampany
		|		ON PaymentDecryptionTable.ARAPObject = ObjectsOfCalculationsAnalyticsIntercampany.ARAPObject
		|			AND (VALUE(Catalog.Partners.OurEnterprise) = ObjectsOfCalculationsAnalyticsIntercampany.Partner)
		|WHERE
		|	&BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany), VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined
		And Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		Or DocumentObject = Undefined Then
		
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	ObjectsOfAnalyticsCalculations.Organization AS Organization,
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	PaymentDecryptionTable.Contract AS Contract,
		|	PaymentDecryptionTable.ProformaInvoice AS ProformaInvoice,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.OrderDivision_ AS OrderDivision_,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
		|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
		|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
		|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
		|	PaymentDecryptionTable.ARAPDocumentForLease AS ARAPDocumentForLease,
		|	PaymentDecryptionTable.Sum AS Sum,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
		|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.VATAmount AS VATAmount,
		|	PaymentDecryptionTable.VATAmountMan AS VATAmountMan,
		|	PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|	PaymentDecryptionTable.VATTaxation AS VATTaxation,
		|	ISNULL(ObjectsOfAnalyticsCalculations.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|FROM
		|	DataOfPayment AS PaymentDecryptionTable
		|		LEFT JOIN ObjectsOfSettlementsWithAnalyticsByPartners AS ObjectsOfAnalyticsCalculations
		|		ON PaymentDecryptionTable.ARAPObject = ObjectsOfAnalyticsCalculations.ARAPObject
		|			AND PaymentDecryptionTable.Partner = ObjectsOfAnalyticsCalculations.Partner
		|WHERE
		|	NOT &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
		|	VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany), 
		|	VALUE(Enum.BusinessTransactions.RefundFromLessor),
		|	VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment), 
		|	VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits), 
		|	VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))";

		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		Or DocumentObject = Undefined Then
		
		QueryText = "SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	DimensionLoansDeposits.Organization AS Organization,
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	PaymentDecryptionTable.Contract AS Contract,
		|	PaymentDecryptionTable.ProformaInvoice AS ProformaInvoice,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LinesOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.OrderDivision_ AS OrderDivision_,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
		|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
		|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
		|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
		|	PaymentDecryptionTable.ARAPDocumentForLease AS ARAPDocumentForLease,
		|	PaymentDecryptionTable.Sum AS Sum,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
		|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.VATAmount AS VATAmount,
		|	PaymentDecryptionTable.VATAmountMan AS VATAmountMan,
		|	PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|	PaymentDecryptionTable.VATTaxation AS VATTaxation,
		|	ISNULL(DimensionLoansDeposits.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|FROM
		|	DataOfPayment AS PaymentDecryptionTable
		|		LEFT JOIN AccountingAnalyticsForPartners AS DimensionLoansDeposits
		|		ON (&Organization = DimensionLoansDeposits.Organization)
		|			AND PaymentDecryptionTable.Partner = DimensionLoansDeposits.Partner
		|			AND (VALUE(Catalog.CounterpartyContracts.EmptyRef) = DimensionLoansDeposits.Contract)
		|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef)  = DimensionLoansDeposits.LineOfBusiness
		|WHERE
		|	&BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment), VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits), VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))";

		QueryTextArray.Add(QueryText);
		
	EndIf;
	If (DocumentObject <> Undefined
		And DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor)
		Or DocumentObject = Undefined Then
		
		QueryText = "SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	DimensionRent.Organization AS Organization,
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	PaymentDecryptionTable.Contract AS Contract,
		|	PaymentDecryptionTable.ProformaInvoice AS ProformaInvoice,
		|	PaymentDecryptionTable.LeaseContractLineOfBusiness AS LeaseContractLineOfBusiness,
		|	PaymentDecryptionTable.IncomeItem AS IncomeItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.OrderDivision_ AS OrderDivision_,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
		|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
		|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
		|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
		|	PaymentDecryptionTable.ARAPDocumentForLease AS ARAPDocumentForLease,
		|	PaymentDecryptionTable.Sum AS Sum,
		|	PaymentDecryptionTable.SumMan AS SumMan,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
		|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.VATAmount AS VATAmount,
		|	PaymentDecryptionTable.VATAmountMan AS VATAmountMan,
		|	PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|	PaymentDecryptionTable.VATTaxation AS VATTaxation,
		|	ISNULL(DimensionRent.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.RowID AS RowID,
		|	PaymentDecryptionTable.DocumentID AS DocumentID
		|FROM
		|	DataOfPayment AS PaymentDecryptionTable
		|		LEFT JOIN AccountingAnalyticsForPartners AS DimensionRent
		|		ON (&Organization = DimensionRent.Organization)
		|			AND PaymentDecryptionTable.Partner = DimensionRent.Partner
		|			AND (VALUE(Catalog.CounterpartyContracts.EmptyRef) = DimensionRent.Contract)
		|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = DimensionRent.LineOfBusiness
		|WHERE
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromLessor)";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	NestedQuery = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT *
	|INTO GeneralPaymentDescriptionTable
	|FROM
	|	&NestedQuery AS NestedQuery
	|";
	QueryText = StrReplace(QueryText, "&NestedQuery", "(" + NestedQuery + ")");
	
	ArrayOfTemporaryTables.Add(QueryText);
	QueryText = StrConcat(ArrayOfTemporaryTables, Common.QueryBatchSeparator());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountReceiptNote.ARAPDetails");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountReceiptNote");
		QueryText = StrReplace(QueryText, "DocumentInpayment.CounterpartyPartner", "DocumentInpayment.Counterparty.Partner");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.LeaseContractLineOfBusiness", "PaymentDecryptionTable.LeaseContracts.LineOfBusiness");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.LeaseContractDivision", "PaymentDecryptionTable.LeaseContracts.Department");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.LoanDepositContractLineOfBusiness", "PaymentDecryptionTable.LoanDepositContract.LineOfBusiness");
	EndIf;
	
	QueryTexts.Add(QueryText, TempTableName);
		
	Return QueryText;
	
EndFunction

Function QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BankAccountCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryTextArray = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	
		|	CASE
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|			VALUE(Enum.BusinessTransactions.RefundFromVendor))
		|			THEN PaymentDecryptionTable.OrderDivision_
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
		|			VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
		|			VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))
		|			THEN PaymentDecryptionTable.LoanDepositContract.Department
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder),
		|			VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee))
		|			THEN DocumentData.Department
		|		ELSE UNDEFINED
		|	END AS Department,
		|
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.SumMan
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.SumCompl
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE WHEN NOT DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS ToReceive_,
		|	
		|	&BusinessOperation                                     AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                     AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem                              AS TargetFundItem,
		|	PaymentDecryptionTable.AccountingDimensionByPartners                         AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.ARAPObject                                    AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.RowID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		 &BusinessTransactionSetting
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
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
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor Then
		
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	UNDEFINED AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.SumMan
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.SumCompl
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE WHEN NOT DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS ToReceive_,
		|	
		|	CASE PaymentDecryptionTable.TypeOfLeasePayment
		|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|			THEN VALUE(Enum.BusinessTransactions.SecurityPaymentReturn)
		|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|			THEN VALUE(Enum.BusinessTransactions.RefundLeaseBuyoutValue)
		|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|			THEN VALUE(Enum.BusinessTransactions.RefundPrepaymentLeaseBuyoutValue)
		|		ELSE &BusinessOperation
		|	END                                                      AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                     AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem                              AS TargetFundItem,
		|	PaymentDecryptionTable.AccountingDimensionByPartners                         AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.ARAPObject                                    AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.RowID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		CASE PaymentDecryptionTable.TypeOfLeasePayment
		|			WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|				THEN VALUE(Catalog.BusinessTransactionsSettings.SecurityPaymentReturn)
		|			WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|				THEN VALUE(Catalog.BusinessTransactionsSettings.RefundLeaseBuyoutValue)
		|			WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|				THEN VALUE(Catalog.BusinessTransactionsSettings.RefundPrepaymentLeaseBuyoutValue)
		|			ELSE &BusinessTransactionSetting
		|		END
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund Then
		
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
		|			THEN PaymentDecryptionTable.Department
		|		ELSE DocumentData.Department
		|	END AS Department,
		|
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.SumMan
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.SumCompl
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE WHEN NOT DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS ToReceive_,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                     AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem                              AS TargetFundItem,
		|	UNDEFINED                                                                AS AccountingDimensionByPartners,
		|	UNDEFINED                                                                AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		PaymentDecryptionTable.RowID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		&BusinessTransactionSetting
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	
		|	CASE
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount),
		|			VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount))
		|			THEN DocumentData.BankAccountDivision
		|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts),
		|			VALUE(Enum.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram))
		|			THEN CASE
		|				WHEN DocumentData.WithdrawalDocument REFS Document.CashVoucher
		|					THEN CAST(DocumentData.WithdrawalDocument AS Document.CashVoucher).Department
		|				ELSE CAST(DocumentData.WithdrawalDocument AS Document.BankAccountIssue).Department
		|			END
		|		ELSE UNDEFINED
		|	END AS Department,
		|
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE WHEN NOT DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount
		|	ELSE
		|		0
		|	END AS ToReceive_,
		|	
		|	CASE WHEN ISNULL(BankAccountIssue.BusinessOperation,
		|				VALUE(Enum.BusinessTransactions.EmptyRef)) = 
		|				VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|		THEN VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder)
		|	ELSE
		|		&BusinessOperation
		|	END AS BusinessOperation,
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	UNDEFINED                   AS AccountingDimensionByPartners,
		|	UNDEFINED                   AS ARAPObject,
		
		|	&Ref AS PaymentDocument,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		CASE WHEN ISNULL(BankAccountIssue.BusinessOperation,
		|					VALUE(Enum.BusinessTransactions.EmptyRef)) =
		|					VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN ISNULL(BusinessTransactionsSettings.Ref, &BusinessTransactionSetting)
		|		ELSE
		|			&BusinessTransactionSetting
		|		END
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder)
		|		LEFT JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON DocumentData.WithdrawalDocument = BankAccountIssue.Ref";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "	
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount * &ConversionRateToManCurrency
		|	ELSE
		|		0
		|	END AS SumMan,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE WHEN NOT DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount
		|	ELSE
		|		0
		|	END AS ToReceive_,
		|	
		|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) AS BusinessOperation,
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	UNDEFINED                   AS AccountingDimensionByPartners,
		|	UNDEFINED                   AS ARAPObject,
		|	&Ref AS PaymentDocument,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		&BusinessTransactionSetting
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) 
		And DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryTextArray = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                              AS RecordType,
		|	&Period                                                                             AS Period,
		|	
		|	DocumentData.Organization                                                         AS Organization,
		|	DocumentData.BankAccount                                                      AS Recipient,
		|	UNDEFINED                                                                        AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)  AS CashTransferKind,
		|	DocumentData.Counterparty                                                          AS Counterparty,
		|	DocumentData.AcquiringContract                                                   AS Contract,
		|	DocumentData.Currency                                                              AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                      AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                    AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul                   AS SumCompl,
		|	
		|	&BusinessOperation                                                              AS BusinessOperation,
		|	&CashFlowItem                                                      AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                              AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashRecieptByAcquiringTransactionsPayment) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		And DocumentObject.ProcessedByBank And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
		|	&Period                                                                              AS Period,
		|	
		|	DocumentData.Organization                                                          AS Organization,
		|	DocumentData.BankAccount                                                       AS Recipient,
		|	UNDEFINED                                                                         AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
		|	DocumentData.Counterparty                                                           AS Counterparty,
		|	DocumentData.AcquiringContract                                                    AS Contract,
		|	DocumentData.Currency                                                               AS Currency,
		|	
		|	DocumentData.FeeAmount                                                               AS Sum,
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
		|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS SumCompl,
		|	
		|	VALUE(Enum.BusinessTransactions.AcquiringFee)                    AS BusinessOperation,
		|	DocumentData.AcquiringContractCashFlowItemFee              AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                               AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee)             AS BusinessTransactionSetting 
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                              AS RecordType,
		|	&Period                                                                             AS Period,
		|	
		|	DocumentData.Organization                                                         AS Organization,
		|	DocumentData.BankAccount                                                      AS Recipient,
		|	DocumentData.SenderBankAccount                                           AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount)        AS CashTransferKind,
		|	UNDEFINED                                                                        AS Counterparty,
		|	UNDEFINED                                                                        AS Contract,
		|	DocumentData.Currency                                                              AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                      AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                    AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul                   AS SumCompl,
		|	
		|	&BusinessOperation                                                              AS BusinessOperation,
		|	&CashFlowItem                                                      AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                              AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromAnotherAccount) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                              AS RecordType,
		|	&Period                                                                             AS Period,
		|	
		|	DocumentData.Organization                                                         AS Organization,
		|	DocumentData.BankAccount                                                      AS Recipient,
		|	DocumentData.CashAccountIssuer                                                    AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashDepositToBank)                 AS CashTransferKind,
		|	UNDEFINED                                                                        AS Counterparty,
		|	UNDEFINED                                                                        AS Contract,
		|	DocumentData.Currency                                                              AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                      AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                    AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul                   AS SumCompl,
		|	
		|	&BusinessOperation                                                              AS BusinessOperation,
		|	&CashFlowItem                                                      AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                              AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCashRegisterToBankAccount) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                          AS RecordType,
		|	&Period                                                                         AS Period,
		|	
		|	DocumentData.Organization                                                     AS Organization,
		|	DocumentData.BankAccount                                                  AS Recipient,
		|	UNDEFINED                                                                    AS Sender,
		|	CASE WHEN DocumentData.CurrencyOfConversion = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                           AS CashTransferKind,
		|	DocumentData.Counterparty                                                      AS Counterparty,
		|	UNDEFINED                                                                    AS Contract,
		|	DocumentData.CurrencyOfConversion                                               AS Currency,
		|	
		|	DocumentData.ConversionAmount                                                AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul               AS SumCompl,
		|	
		|	&BusinessOperation                                                          AS BusinessOperation,
		|	&CashFlowItem                                                  AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                          AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion)           AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|UNION ALL
		|
		|// Positive exchange rate differences
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                           AS RecordType,
		|	&Period                                                                          AS Period,
		|	
		|	&Organization                                                                     AS Organization,
		|	&BankAccount                                                                  AS Recipient,
		|	UNDEFINED                                                                     AS Sender,
		|	CASE WHEN &CurrencyOfConversion = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                            AS CashTransferKind,
		|	&Counterparty                                                                      AS Counterparty,
		|	UNDEFINED                                                                     AS Contract,
		|	&CurrencyOfConversion                                                               AS Currency,
		|	
		|	0                                                                                AS Sum,
		|	-TableOfExchangeDifferences.SumMan                                                  AS SumMan,
		|	-TableOfExchangeDifferences.SumCompl                                                 AS SumCompl,
		|	
		|	&BusinessOperation                                                           AS BusinessOperation,
		|	&CashFlowItem                                                   AS CashFlowItem,
		|	
		|	TableOfExchangeDifferences.DocumentID                                     AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)      AS BusinessTransactionSetting
		|	
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|	
		|WHERE
		|	(TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)
		|
		|UNION ALL
		|
		|// Negative exchange rate differences
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                          AS RecordType,
		|	&Period                                                                         AS Period,
		|	
		|	&Organization                                                                    AS Organization,
		|	&BankAccount                                                                 AS Recipient,
		|	UNDEFINED                                                                    AS Sender,
		|	CASE WHEN &CurrencyOfConversion = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                           AS CashTransferKind,
		|	&Counterparty                                                                     AS Counterparty,
		|	UNDEFINED                                                                    AS Contract,
		|	&CurrencyOfConversion                                                              AS Currency,
		|	
		|	0                                                                               AS Sum,
		|	TableOfExchangeDifferences.SumMan                                                  AS SumMan,
		|	TableOfExchangeDifferences.SumCompl                                                 AS SumCompl,
		|	
		|	&BusinessOperation                                                          AS BusinessOperation,
		|	&CashFlowItem                                                  AS CashFlowItem,
		|	
		|	TableOfExchangeDifferences.DocumentID                                    AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)    AS BusinessTransactionSetting
		|	
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|	
		|WHERE
		|	(TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                          AS RecordType,
		|	&Period                                                                         AS Period,
		|	
		|	DocumentData.Organization                                                     AS Organization,
		|	UNDEFINED                                                                    AS Recipient,
		|	DocumentData.BankAccount                                                  AS Sender,
		|	VALUE(Enum.CashTransferKinds.TransferToPersons) AS CashTransferKind,
		|	DocumentData.Counterparty                                                      AS Counterparty,
		|	UNDEFINED                                                                    AS Contract,
		|	DocumentData.Currency                                                          AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                  AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul               AS SumCompl,
		|	
		|	VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) AS BusinessOperation,
		|	&CashFlowItem                                                  AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                          AS FinRecordID,
		|	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder)
		|		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON DocumentData.WithdrawalDocument = BankAccountIssue.Ref
		|	
		|WHERE
		|	BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                          AS RecordType,
		|	&Period                                                                         AS Period,
		|	
		|	DocumentData.Organization                                                     AS Organization,
		|	UNDEFINED                                                                    AS Recipient,
		|	DocumentData.BankAccount                                                  AS Sender,
		|	VALUE(Enum.CashTransferKinds.TransferToPersons) AS CashTransferKind,
		|	DocumentData.Counterparty                                                      AS Counterparty,
		|	UNDEFINED                                                                    AS Contract,
		|	DocumentData.Currency                                                          AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                  AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul               AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                           AS BusinessOperation,
		|	&CashFlowItem                                                  AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                          AS FinRecordID,
		|	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON DocumentData.WithdrawalDocument = BankAccountIssue.Ref
		|	
		|WHERE
		|	BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram)
		|	AND &TransferViaTransfersOnWay
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryTextArray = New Array;
	
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
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
		|	AND &UseAccountingOfOtherIncomeExpenses";
	
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		QueryText = "
		|// Calculation of exchange differences
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
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
		|	
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
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountsOfDocumentsInAccountingCurrencies", QueryTexts) Then
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	
	QueryTextArray = New Array;
	QueryTextArray.Add(QueryText);
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	TableOfExchangeDifferences.Department AS Department,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS ExpenseItem,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
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
		|
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) AS BusinessOperation,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	
		|	TableOfExchangeDifferences.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss) AS BusinessTransactionSetting,
		|	&AdjustmentPeriod_ AS VariancePeriod
		|	
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|
		|WHERE
		|	(TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)";
	
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission And DocumentObject.ProcessedByBank 
		And Not DocumentObject.KeepRecordsOfCommissionInARAPAccounting Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.ExpenseItem AS ExpenseItem,
		|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
		|	DocumentData.AcquiringContractLineOfBusiness AS LineOfBusiness,
		|	UNDEFINED AS VATActivityType,
		|	
		|	// Calculate the amount in the currency of management accounting.
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVATMan,
		|
		|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl, DocumentData.FeeAmount) AS AmountIncludingVATCompl,
		|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentData.FeeAmount) AS AmountExcludingVATCompl,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	VALUE(Enum.BusinessTransactions.OtherExpenses) AS BusinessOperation,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	
		|	DocumentData.DocumentID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee) AS BusinessTransactionSetting, 
		|	&AdjustmentPeriod_ AS VariancePeriod
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN
		|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
		|	ON
		|		DocumentAmountsInAccountingCurrency.Ref = DocumentData.Ref
		|		AND DocumentAmountsInAccountingCurrency.RowID = ""1""
		|";
			
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not((DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund) And DocumentObject.ProcessedByBank) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfQueryTests = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt 
		And DocumentObject.ProcessedByBank Then
	
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
		|	SUM(PaymentDecryptionTable.SumMan) AS Sum
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|WHERE
		|	PaymentDecryptionTable.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
		|
		|GROUP BY
		|	PaymentDecryptionTable.IncomeItem,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.Department,
		|	PaymentDecryptionTable.LineOfBusiness";
	
		ArrayOfQueryTests.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee 
		And DocumentObject.ProcessedByBank Then
	
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
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|
		|GROUP BY
		|	PaymentDecryptionTable.LineOfBusiness";
		
		ArrayOfQueryTests.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram)
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "		
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	SUM(CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END) AS Sum
		|FROM
		|	DocumentDataHeader AS DD
		|		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON DD.WithdrawalDocument = BankAccountIssue.Ref
		|WHERE
		|	NOT BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|
		|HAVING
		|	SUM(CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END) <> 0";
		
		ArrayOfQueryTests.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	&Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
		|	DocumentData.TaxType AS Dimension,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfQueryTests.Add(QueryText);
	
	EndIf;
	
	If ArrayOfQueryTests.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfQueryTests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund) 
			And DocumentObject.ProcessedByBank) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ReflectSettlementWITHBranches = False;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor) 
		And DocumentObject.ProcessedByBank Then
			
		ReflectSettlementWITHBranches = True;
		
	EndIf;
	
	If ReflectSettlementWITHBranches And Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt
		And DocumentObject.ProcessedByBank Then
			
		QueryText = "
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
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
		And DocumentObject.ProcessedByBank Then
			
		QueryText = "
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
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram)
		And DocumentObject.ProcessedByBank And DocumentObject.DocumentAmount <> 0 Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	CASE
		|		WHEN DD.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN BankAccountIssue.Department
		|		ELSE DD.Department
		|	END AS Department,
		|	BankAccountIssue.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	CASE
		|		WHEN &Currency = &LocalAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
		|	END AS SumCompl,
		|	CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS SumMan,
		|	CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS AmountIncludingVAT,
		|	CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS AmountExcludingVAT,
		|
		|	DD.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DD
		|		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON DD.WithdrawalDocument = BankAccountIssue.Ref
		|WHERE
		|	NOT BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And DocumentObject.ProcessedByBank And DocumentObject.DocumentAmount <> 0 Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	UNDEFINED AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
		|	DD.BankAccountSenderOwner AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	CASE
		|		WHEN &Currency = &LocalAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
		|	END AS SumCompl,
		|	CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS SumMan,
		|	CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS AmountIncludingVAT,
		|	CASE
		|		WHEN &Currency = &ManagementAccountingCurrency
		|			THEN DD.DocumentAmount
		|		ELSE CAST(DD.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS AmountExcludingVAT,
		|
		|	DD.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DD
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund
		And DocumentObject.ProcessedByBank Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	UNDEFINED AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
		|	DocumentData.TaxType AS Dimension,
		|	DocumentData.GLAccountSettings AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.SumMan  AS SumMan,
		|	PaymentDecryptionTable.SumMan  AS AmountIncludingVAT,
		|	PaymentDecryptionTable.SumMan  AS AmountExcludingVAT,
		|
		|	PaymentDecryptionTable.RowID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		
		If ReflectSettlementWITHBranches Then
			QueryText = OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches();
			ArrayOfRequestTexts.Add(QueryText);
		EndIf;
		
	Else
		
		If ReflectSettlementWITHBranches Then
			ArrayOfRequestTexts.Add(OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches());
		EndIf;
		
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TableOfExchangeDifferences";
	
	QueryText = "
	|SELECT
	|	DocumentData.BankAccountDivision AS Department,
	|	DocumentData.BankAccountLineOfBusiness AS LineOfBusiness,
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
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountReceiptNote");
		QueryText = StrReplace(QueryText, "DocumentData.BankAccountDivision", "DocumentData.BankAccount.Department");
		QueryText = StrReplace(QueryText, "DocumentData.BankAccountLineOfBusiness", "DocumentData.BankAccount.LineOfBusiness");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""DocumentData""     AS DataSource,
	|	FALSE                    AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	CASE 
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate
	|				OR DocumentTable.Patch THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	ISNULL(Rows.ARAPCurrency, UNDEFINED) AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	CASE 
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS DateOfCourse,
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
	|
	|UNION ALL
	|
	|SELECT
	|	""DocumentData"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	&Period AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	""1"" AS RowID,
	|	DocumentTable.FeeAmount AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.RecordCommission
	|	AND DocumentTable.FeeAmount <> 0
	|";
	
	If DocumentObject = Undefined Then
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.BankAccountReceiptNote");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.BankAccountReceiptNote.ARAPDetails");
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor)
		And DocumentObject.ProcessedByBank) Then
		Return "";
	EndIf;
		
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryTextArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		And DocumentObject.ProcessedByBank Then
	
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
		|	CASE 
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment) 
		|			 THEN VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromLoansRepayment) 
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits) 
		|			 THEN VALUE(Catalog.BusinessTransactionsSettings.CashReceiptUnderDeposits)
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty) 
		|			 THEN VALUE(Catalog.BusinessTransactionsSettings.CashReceiptBorrowingsProvidedToCounterparty)
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
		|		ON PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor
		And DocumentObject.ProcessedByBank Then
	
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
		|WHERE
		|	&BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromLessor)
		|	)
		|	AND &ProcessedByBank
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		And DocumentObject.ProcessedByBank) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Organization,
	|	DocumentData.AdvanceHolder,
	|	DocumentData.Department,
	|	DocumentData.BankAccountCashCurrency AS Currency,
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
	|   	LEFT JOIN Document.BankAccountIssue AS BankAccountIssue
	|		ON DocumentData.DocumentBasis = BankAccountIssue.Ref
	|
	|WHERE
	|	NOT ISNULL(BankAccountIssue.PersonsList, FALSE)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount)
		And DocumentObject.ProcessedByBank Then
			
		QueryText =
		"SELECT
		|	&Period AS Period,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BankAccountDivision AS Department,
		|	
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount) THEN
		|		DocumentData.BankAccount
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount) THEN
		|		DocumentData.CashAccountIssuer
		|	END AS Cash,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	
		|	DocumentData.BankAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount) THEN
		|		DocumentData.BankAccount
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount) THEN
		|		DocumentData.CashAccountIssuer
		|	END AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.BankAccount AS CorSourceOfFAGOfCash
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		And DocumentObject.ProcessedByBank Then
			
		QueryText ="
		|SELECT
		|	&Period AS Period,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|
		|	DocumentData.AdvanceHolder AS Cash,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
		|	PaymentDocumentTable.CashFlowItem AS CashFlowItem,
		|	PaymentDocumentTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.BankAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(PaymentDocumentTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(PaymentDocumentTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	PaymentDocumentTable.Sum AS AmountInCurrency,
		|	PaymentDocumentTable.Sum AS AmountInCorCurrency,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.BankAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		
		|		INNER JOIN
		|			Document.BankAccountReceiptNote.ARAPDetails AS PaymentDocumentTable
		|		ON
		|			PaymentDocumentTable.Ref = DocumentData.Ref
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram
		And DocumentObject.ProcessedByBank Then
			
		QueryText ="
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	BankAccountIssue.Department AS Department,
		|
		|	DocumentData.AdvanceHolder AS Cash,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.BankAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.BankAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON DocumentData.WithdrawalDocument = BankAccountIssue.Ref
		|
		|WHERE
		|	BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		And DocumentObject.ProcessedByBank Then
	
		QueryText ="
		|SELECT
		|	&Period AS Period,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	UNDEFINED AS Department,
		|
		|	DocumentData.AcquiringContract AS Cash,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.BankAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.BankAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		And DocumentObject.ProcessedByBank Then
			
		QueryText ="
		| // Operations of receipt of funds on deposits
		|SELECT
		|	&Period AS Period,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	PaymentDocumentTable.ContractOfLoanDepositDivision AS Department,
		|
		|	PaymentDocumentTable.LoanDepositContract AS Cash,
		|	ContractData.LineOfBusiness AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.Deposits) AS CashType,
		|	PaymentDocumentTable.CashFlowItem AS CashFlowItem,
		|	PaymentDocumentTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.BankAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(PaymentDocumentTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(PaymentDocumentTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	PaymentDocumentTable.Sum AS AmountInCurrency,
		|	PaymentDocumentTable.Sum AS AmountInCorCurrency,
		|
		|	PaymentDocumentTable.LoanDepositContract AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.BankAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		
		|		INNER JOIN
		|			DocumentDataTableDecryptionOfPayment AS PaymentDocumentTable
		|		ON
		|			PaymentDocumentTable.Ref = DocumentData.Ref
		|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
		|			ON PaymentDocumentTable.LoanDepositContract = ContractData.Ref
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		And DocumentObject.ProcessedByBank Then
			
		QueryText ="
		|
		|// Operations of receipt of funds from currency conversion
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|
		|	DocumentData.Counterparty AS Cash,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.CurrencyOfConversion AS Currency,
		|
		|	DocumentData.BankAccount AS CorCash,
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.ConversionAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.BankAccount AS CorSourceOfFAGOfCash
		|FROM
		|	DocumentDataHeader AS DocumentData
		|
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfSubqueryTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "
		|// Cash flow operations
		|	SELECT
		|		&Period AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.ARAPObject.Contract AS Contract,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
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
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "
		|// Operations on receipt of funds from another organization
		|	SELECT
		|		&Period AS Period,
		|		DocumentData.BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		UNDEFINED AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.BankAccountSenderOwner AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.ARAPObject.Contract AS Contract,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
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
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "
		|// Internal money transfer operations
		|	SELECT
		|		&Period AS Period,
		|		VALUE(Enum.BusinessTransactions.InternalCashReceipt) AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		UNDEFINED AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		&CashFlowItem AS CashFlowItem,
		|		&TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.BankAccountSenderOwner AS Counterparty,
		|		DocumentData.BankAccountSenderLineOfBusiness AS LineOfBusiness,
		|		UNDEFINED AS Contract,
		|		UNDEFINED AS ARAPObject,
		|	
		|		DocumentData.DocumentAmount * &ConversionRateToManCurrency AS PayAmount,
		|		DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS PaymentAmountLocal,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|";
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "
		|// Operations receipts on loans and loans issued
		|	SELECT
		|		&Period AS Period,
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
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
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
		|		ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS PaymentAmountPaymentCurrency,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
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
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "
		|SELECT 
		|		&Period AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.ARAPObject.Contract AS Contract,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
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
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "
		|SELECT
		|		&Period AS Period,
		|		DocumentData.BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		UNDEFINED AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.SenderBankAccount.Owner AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.ARAPObject.Contract AS Contract,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
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
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission And DocumentObject.ProcessedByBank 
		And DocumentObject.KeepRecordsOfCommissionInARAPAccounting Then
		
		TextOfQuerySubquery = "//Acquiring fees
		|	SELECT
		|		&Period AS Period,
		|		VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		DocumentData.AcquiringContract.CashFlowItemCommission AS CashFlowItem,
		|		UNDEFINED AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		DocumentData.AcquiringContractPartner AS Partner,
		|		DocumentData.CommissionARAPObject.Counterparty AS Counterparty,
		|		DocumentData.CommissionARAPObject.LineOfBusiness AS LineOfBusiness,
		|		DocumentData.CommissionARAPObject.Contract AS Contract,
		|		DocumentData.CommissionARAPObject AS ARAPObject,
		|	
		|		CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
		|		CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS PaymentAmountLocal,
		|		DocumentData.FeeAmount AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountToBePaidAboveLimit,
		|	
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		DocumentData.Currency AS ARAPCurrency,
		|
		|		DocumentData.FeeAmount AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		DocumentData.CommissionARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		UNDEFINED AS PaymentRequest
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|";

		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
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
	|	DocumentData.Cash AS Cash,
	|	&LineOfBusinessCash AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.TargetFundItem AS TargetFundItem,
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
	|	DocumentData.VATRate AS VATRate,
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
	|	DocumentData.TargetFundItem,
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

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashReceipt 
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	PaymentDocumentData.BusinessOperation AS BusinessOperation,
		|	PaymentDocumentData.Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	PaymentDocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	PaymentDocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	PaymentDecryptionTable.IncomeItem AS IncomeAndExpenseItem,
		|	PaymentDecryptionTable.DimensionOfRevenue AS DimensionOfRevenue,
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
		|	PaymentDocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.IncomeItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
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
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment 
		And DocumentObject.ProcessedByBank And DocumentObject.RecordCommission And DocumentObject.FeeAmount <> 0 Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	DocumentData.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
		|	CASE
		|		WHEN ISNULL(DocumentData.AcquiringContractCashFlowItemFee, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
		|			VALUE(Catalog.CashFlowReportItems.PaymentToVendor)
		|		ELSE
		|			DocumentData.AcquiringContractCashFlowItemFee
		|	END AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.AcquiringContractLineOfBusiness AS LineOfBusinessItems,
		|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.FeeAmount AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor 
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	PaymentDocumentData.BusinessOperation AS BusinessOperation,
		|	PaymentDocumentData.Organization AS Organization,
		|	UNDEFINED AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	PaymentDocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
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
		|	PaymentDocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
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
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "
		|// Calculation of income from exchange differences
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
		|	&Organization AS Organization,
		|	TableOfExchangeDifferences.Department AS Department,
		|	&LineOfBusinessCash,
		|	TableOfExchangeDifferences.Department AS IncomeExpenseBusinessUnit,
		|
		|	&Counterparty AS Cash,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	&CurrencyOfConversion AS Currency,
		|
		|	&LineOfBusinessCash AS LineOfBusinessItems,
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
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|	AND (TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "
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
		|	&TargetFundItem AS TargetFundItem,
		|	&CurrencyOfConversion AS Currency,
		|
		|	&LineOfBusinessCash AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	-TableOfExchangeDifferences.SumMan AS Sum,
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
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|	AND (TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram)
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	&Organization AS Organization,
		|	CASE 
		|		WHEN PaymentDocumentData.WithdrawalDocument REFS Document.CashVoucher
		|			THEN CAST(PaymentDocumentData.WithdrawalDocument AS Document.CashVoucher).Department
		|		WHEN PaymentDocumentData.WithdrawalDocument REFS Document.BankAccountIssue
		|			THEN CAST(PaymentDocumentData.WithdrawalDocument AS Document.BankAccountIssue).Department
		|	END AS Department,
		|	&LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	&BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	ISNULL(PaymentDecryptionTable.CashFlowItem, PaymentDocumentData.CashFlowItem) AS CashFlowItem,
		|	ISNULL(PaymentDecryptionTable.TargetFundItem, PaymentDocumentData.TargetFundItem) AS TargetFundItem,
		|	&Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	ISNULL(PaymentDecryptionTable.IncomeItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll)) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	
		|	SUM(CAST(ISNULL(PaymentDecryptionTable.Sum, PaymentDocumentData.DocumentAmount) * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum,
		|	SUM(CAST(ISNULL(PaymentDecryptionTable.Sum, PaymentDocumentData.DocumentAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS SumCompl,
		|	SUM(ISNULL(PaymentDecryptionTable.Sum, PaymentDocumentData.DocumentAmount)) AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	&BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|FROM
		|	DocumentDataHeader AS PaymentDocumentData
		|
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|	LEFT JOIN Document.BankAccountIssue AS BankAccountIssue
		|		ON PaymentDocumentData.WithdrawalDocument = BankAccountIssue.Ref
		|WHERE
		|	NOT ISNULL(BankAccountIssue.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) =
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|
		|GROUP BY
		|	PaymentDecryptionTable.CashFlowItem,
		|	PaymentDocumentData.CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem,
		|	PaymentDocumentData.TargetFundItem,
		|	PaymentDecryptionTable.IncomeItem,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension,
		|	PaymentDocumentData.WithdrawalDocument,
		|	PaymentDocumentData.BankAccount,
		|	PaymentDocumentData.Department";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
		And DocumentObject.ProcessedByBank Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	&Organization AS Organization,
		|	PaymentDocumentData.Department AS Department,
		|	&LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	&BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	&Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	
		|	SUM(CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum,
		|	SUM(CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS SumCompl,
		|	SUM(PaymentDecryptionTable.Sum) AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	&BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|FROM
		|	DocumentDataHeader AS PaymentDocumentData
		|
		|	INNER JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|WHERE
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee)
		|
		|GROUP BY
		|	PaymentDocumentData.Department,
		|	PaymentDecryptionTable.CashFlowItem";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	PaymentDocumentData.BusinessOperation AS BusinessOperation,
		|	PaymentDocumentData.Organization AS Organization,
		|	PaymentDocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	PaymentDocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	PaymentDocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDocumentData.TaxType AS AssetsLiabilitiesDimension,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	PaymentDocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate
		|
		|FROM
		|	DocumentDataHeader AS PaymentDocumentData
		|
		|	INNER JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts);
	EndIf;
	
	ArrayOfSubqueryTests = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor)
		And DocumentObject.ProcessedByBank Then

		SubqueryText = "
		|// The debt of the client was written off by the prered branch
		|	SELECT
		|		&Period AS Period,
		|		CASE WHEN &BusinessOperation IN (
		|						VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|						VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany))
		|			THEN VALUE(Enum.BusinessTransactions.PaymentTransferFromBranchOffice)
		|			ELSE VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|		END AS BusinessOperation,//AccountsReceivableType
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
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization
		|		AND PaymentDecryptionTable.Organization <> UNDEFINED
		|		"; 
		
		ArrayOfSubqueryTests.Add(SubqueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor)
		And DocumentObject.ProcessedByBank Then

		SubqueryText = "
		|// Transferred the client's debt to the organization
		|	SELECT
		|		&Period AS Period,
		|		CASE WHEN &BusinessOperation IN (
		|						VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
		|						VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany))
		|			THEN VALUE(Enum.BusinessTransactions.PaymentAcceptanceAtBranchOffice)
		|			ELSE VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|		END AS BusinessOperation,//AccountsPayableType
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
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization
		|		AND PaymentDecryptionTable.Organization <> UNDEFINED
		|		"; 

		ArrayOfSubqueryTests.Add(SubqueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		And DocumentObject.ProcessedByBank Then

		SubqueryText = "
		|// Refund of payment at the advance rate
		|	SELECT
		|		&Period AS Period,
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

		ArrayOfSubqueryTests.Add(SubqueryText);
	
	EndIf;
	
	SubqueryText = StrConcat(ArrayOfSubqueryTests, TMCommonUse.QuerySeparatorInJoin());
	
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
	|
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
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
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor) 
			And DocumentObject.ProcessedByBank) Then
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

Function QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "CashToBePaid";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts)) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	CashToBePaid.PointInTime,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CashToBePaid.PaymentRequest,
	|	CashToBePaid.BankAccountCashAccount,
	|	CashToBePaid.Recipient,
	|	CashToBePaid.Organization,
	|	-CashToBePaid.Sum AS Sum,
	|	&BusinessOperation AS BusinessOperation
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	INNER JOIN
	|		AccumulationRegister.CashToBePaid AS CashToBePaid
	|	ON
	|		CashToBePaid.Recorder = DocumentData.WithdrawalDocument
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountReceiptNote");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlowLimits(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlowLimits";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	Limits.CashFlowItem AS CashFlowItem,
	|	Limits.Organization AS Organization,
	|	Limits.Department AS Department,
	|	- Limits.Limit AS Limit,
	|	- Limits.ConsumptionWithinLimit AS ConsumptionWithinLimit,
	|	- Limits.ExcessExpense AS ExcessExpense
	|FROM
	|	AccumulationRegister.CashFlowLimits AS Limits
	|WHERE
	|	Limits.Recorder = &WithdrawalDocument
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts)
	|";
	
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
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TaxRefund
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.EmptyRef()) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&PartnerFromDocument                     AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	&CounterpartyFromDocument                  AS Counterparty,
		|	DocumentData.BankAccountDivision AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
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
		|		VALUE(Enum.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram),
		|		VALUE(Enum.BusinessTransactions.TaxRefund),
		|		VALUE(Enum.BusinessTransactions.EmptyRef)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromLessor) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                         AS RefType,
		|	&BusinessOperation                           AS BusinessOperation,
		|	&Organization                                     AS Organization,
		|	&Partner                                         AS Partner,
		|	&BankAccount                                  AS StorageLocation,
		|	&Counterparty                                      AS Counterparty,
		|	DocumentData.BankAccountDivision      AS Department,
		|	&Period                                          AS IBDocumentDate,
		|	&Ref                                          AS Ref,
		|	&Number                                           AS IBDocumentNumber,
		|	UNDEFINED                                     AS Status,
		|	&EmployeeResponsible                                   AS EmployeeResponsible,
		|	&Author                                           AS Author,
		|	FALSE                                             AS AdditionalRecord,
		|	&PaymentPurposes                               AS More,
		|	&Comment                                     AS Comment,
		|	&Posted                                        AS Posted,
		|	&DeletionMark                                 AS DeletionMark,
		|	&IncomingDocumentDate                          AS SourceDocumentDate,
		|	&IncomingDocumentNumber                         AS SourceDocumentNumber,
		|	&DocumentAmount                                  AS Sum,
		|	&Currency                                          AS Currency,
		|	ISNULL(TLeaseContract.LeaseContracts, UNDEFINED) AS Contract,
		|	&Patch                                     AS ReverseTransactionCorrection,
		|	&ReversedDocument                            AS ReversedDocument,
		|	&CorrectedDocument                            AS CorrectedDocument,
		|	&LineOfBusiness                         AS LineOfBusiness,
		|	CASE
		|		WHEN &ProcessedByBank
		|			THEN &Period
		|		ELSE DATETIME(1, 1, 1)
		|	END                                            AS RecordingInAccountingDate,
		|	UNDEFINED                                     AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN 
		|		
		|		(SELECT
		|			DocumentData.Ref AS Ref,
		|			MAX(NoncashReceiptARAPDetails.LeaseContracts) AS LeaseContracts
		|		FROM
		|			DocumentDataHeader AS DocumentData
		|				INNER JOIN DocumentDataTableDecryptionOfPayment AS NoncashReceiptARAPDetails
		|				ON DocumentData.Ref = NoncashReceiptARAPDetails.Ref
		|				AND (DocumentData.Ref = &Ref)
		|				AND (NoncashReceiptARAPDetails.LeaseContracts <> VALUE(Catalog.LeaseContract.EmptyRef))
		|		GROUP BY
		|			DocumentData.Ref
		|		
		|		HAVING
		|			COUNT(DISTINCT NoncashReceiptARAPDetails.LeaseContracts) = 1
		|		) AS TLeaseContract
		|
		|	ON DocumentData.Ref = TLeaseContract.Ref
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromLessor)";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	&AdvanceHolder                        AS Counterparty,
		|	DocumentData.BankAccountDivision AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee),
		|		VALUE(Enum.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts),
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
		|	&BankAccount                         AS StorageLocation,
		|	&SenderOrganization                 AS Counterparty,
		|	DocumentData.BankAccountDivision AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
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
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	UNDEFINED                            AS Counterparty,
		|	DocumentData.BankAccountDivision AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherAccount),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	&Counterparty                             AS Counterparty,
		|	DocumentData.BankAccountDivision AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	DocumentData.AcquiringContract       AS Contract,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment)
		|	)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject <> Undefined And ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountReceiptNote.ARAPDetails");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountReceiptNote");
		QueryText = StrReplace(QueryText, "DocumentData.BankAccountDivision", "DocumentData.BankAccount.Department");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period 	 				 AS Period,
	|	&Organization 				 AS Organization,
	|	BEGINOFPERIOD(&Period, DAY) AS DateRecord
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Period 							AS Period,
	|	TableOfCalculationObjects.Organization AS Organization,
	|	BEGINOFPERIOD(&Period, DAY) 		AS DateRecord
	|FROM
	|	TableOfCalculationObjects AS TableOfCalculationObjects
	|WHERE
	|	TableOfCalculationObjects.Organization <> &Organization
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment) Then
			
		Return;
			
	EndIf;
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.Ref = ARAPObjects.Object
		|				AND Table.ARAPObjectOfPaymentIsPartner = ARAPObjects.Partner
		|				AND Table.ARAPCurrency = ARAPObjects.ARAPCurrency
		|				AND NOT ARAPObjects.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	DocumentDataHeader.CommissionARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader
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
		|	DocumentDataHeader.Organization                                         AS Organization,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN VALUE(Catalog.Partners.RetailCustomer)
		|		ELSE Table.Partner
		|	END                                                                    AS Partner,
		|	
		|	Table.ARAPCurrency                                             AS ARAPCurrency,
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	
		|	CASE WHEN DocumentDataHeader.ProcessedByBank 
		|			THEN Table.AmountARAP
		|		ELSE 0 
		|	END                                                                    AS AmountARAP,
		|	CASE WHEN DocumentDataHeader.ProcessedByBank 
		|			THEN Table.Sum
		|		ELSE 0 
		|	END                                                                    AS Sum,
		|	CASE WHEN NOT DocumentDataHeader.ProcessedByBank 
		|			THEN Table.AmountARAP
		|		ELSE 0 
		|	END                                              AS IncreaseIsPaid,
		|	0                                                                     AS ReductionIsPaid,
		|	
		|	CASE WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|		OR DocumentDataHeader.Patch
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END                                                                    AS RecorderDate,
		|	CASE WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|		OR DocumentDataHeader.Patch
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END                                                                    AS DateOfCourse,
		|	Table.MaturityDate                                                    AS MaturityDate,
		|	DocumentDataHeader.Number                                                     AS RecorderNumber,
		|	DocumentDataHeader.BusinessOperation                                     AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                           AS PaymentMethod,
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
		|		LEFT JOIN DocumentDataHeader
		|	ON Table.Ref = DocumentDataHeader.Ref
		|";
		
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment);
	
	EndIf;
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
		And DocumentObject.ProcessedByBank Then
			
	TextReturn = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Document.Organization                                                     AS Organization,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
		|		THEN VALUE(Catalog.Partners.OurEnterprise)
		|		ELSE Table.Partner
		|	END                                                                    AS Partner,
		|	SettlementObjectPayment.Ref                                              AS ARAPObject,
		|	
		|	Table.ARAPCurrency                                             AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Sum                                                            AS Sum,
		|	
		|	CASE WHEN NOT Document.ProcessedByBank
		|		OR BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR Document.Patch
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                    AS RecorderDate,
		|	CASE WHEN NOT Document.ProcessedByBank
		|		OR BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR Document.Patch
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                    AS DateOfCourse,
		|	Document.Number                                                           AS RecorderNumber,
		|	Document.BusinessOperation                                           AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                           AS PaymentMethod,
		|	Table.CashFlowItem                                    AS CashFlowItem,
		|	Document.Currency                                                          AS DocumentCurrency,
		|	Table.RowID                                              AS FinRecordID,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
		|		THEN VALUE(Catalog.BusinessTransactionsSettings.RefundFromAnotherCompany)
		|		ELSE VALUE(Catalog.BusinessTransactionsSettings.RefundFromVendor)
		|	END                                                                    AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|			ON Table.Ref = SettlementObjectPayment.Object
		|				AND Table.ARAPObjectOfPaymentIsPartner = SettlementObjectPayment.Partner
		|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|				AND NOT SettlementObjectPayment.DeletionMark";
	
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
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                           AS PaymentMethod,
		|	Document.Number                                                           AS RecorderNumber,
		|	CASE WHEN NOT Document.ProcessedByBank
		|		OR BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR Document.Patch
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                    AS RecorderDate,
		|	CASE WHEN NOT Document.ProcessedByBank
		|		OR BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                    AS DateOfCourse,
		|	Table.CashFlowItem                                    AS CashFlowItem,
		|	Table.RowID                                              AS FinRecordID
		|
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
		|	ARAPObjects.Ref <> SettlementObjectPayment.Ref";
		
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingRefundFromSupplier(Query, QueryTexts, Registers, TextReturn, TextDebtTransfer);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment
		And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission And DocumentObject.ProcessedByBank 
		And DocumentObject.KeepRecordsOfCommissionInARAPAccounting Then
	
		TextPayment = "
		|SELECT
		|	DocumentData.Ref                                           AS Ref,
		|	DocumentData.Organization                                      AS Organization,
		|	DocumentData.AcquiringContractPartner                         AS Partner,
		|	CASE WHEN NOT DocumentData.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate
		|		OR DocumentData.Patch
		|			THEN DocumentData.Date
		|		ELSE ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
		|	END                                                            AS RecorderDate,
		|	DocumentData.Number                                            AS RecorderNumber,
		|	
		|	DocumentData.CommissionARAPObject                           AS ARAPObject,
		|	DocumentData.Currency                                           AS ARAPCurrency,
		|
		|	DocumentData.FeeAmount                                    AS Sum,
		|	DocumentData.FeeAmount                                    AS AmountARAP,
		|	0                                                                AS ReductionIsPaid,
		|	0                                                                AS IncreaseIsPaid,
		|	0                                                                AS SumMan,
		|	0                                                                AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.AcquiringFee)  AS BusinessOperation,
		|	DocumentData.AcquiringContractCashFlowItemFee AS CashFlowItem,
		|	UNDEFINED                                                       AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                     AS PaymentMethod,
		|	DocumentData.Currency                                             AS DocumentCurrency,
		|	CASE WHEN NOT DocumentData.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate
		|			THEN DocumentData.Date
		|		ELSE ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
		|	END                                                              AS DateOfCourse,
		|	DATETIME(1,1,1)                                                   AS MaturityDate,
		|	UNDEFINED                                                       AS LinkedDocument,
		|	DocumentData.DocumentID                             AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee) AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
	
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	BankAccountReceiptNoteLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Adds the command to create the document "receipt of non-cash DS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTable, Undefined - generated commands for output to the submenu.
Function AddCreateBasedOnCommissionReportCommand_Remuneration(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.ReceiptOfNonCashCashPaymentsBasedOnCommissionReport_Remuneration";
		CreateBasedOnCommand.Id = "ReceiptOfNonCashCashPaymentsBasedOnCommissionReport_Remuneration";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.BankAccountReceiptNote) 
			+ " " + NStr("vi = 'cho đại lý hoa hồng (thù lao từ người đặt ký gửi)';
						|ru = 'комиссионеру (вознаграждение от комитента)';
						|en = 'to consignee (commission from consignor)'; fa = 'to consignee (commission from consignor)';
						|it = 'all''agente commissionario (compenso dal committente)';
						|pl = 'do komisanta (wynagrodzenie od komitenta)';
						|tr = 'konsinyeye (göndericiden ikramiyesi)'");
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

#EndRegion

#Region Other

// The function searches for a mirror document of the BDS write-Off for operations between Organizations (Intercampany).
//
// Parameters:
//	DocumentUnderReview - DocumentRef.BankAccountReceiptNote, DocumentObject.BankAccountReceiptNote - 
//	                      The document for which you need to find the mirror document of the DBD write-off.
//
// Returns:
//	DocumentRef.BankAccountIssue
//  Undefined - if the document is not found.
//
Function FindMirrorPayment(DocumentUnderReview) Export
	
	MirrorPayment = Undefined;
	
	If Common.RefTypeValue(DocumentUnderReview) Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	BankAccountIssue.Ref
		|FROM
		|	Document.BankAccountIssue AS BankAccountIssue
		|		INNER JOIN Document.BankAccountReceiptNote AS BankAccountReceiptNote
		|ON
		|	BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|	AND BankAccountIssue.BankAccount = BankAccountReceiptNote.SenderBankAccount
		|	AND BankAccountIssue.DocumentAmount = BankAccountReceiptNote.DocumentAmount
		|	AND BankAccountIssue.Currency = BankAccountReceiptNote.Currency
		|	AND BankAccountIssue.IncomingDocumentDate = BankAccountReceiptNote.IncomingDocumentDate
		|	AND BankAccountIssue.IncomingDocumentNumber = BankAccountReceiptNote.IncomingDocumentNumber
		|	AND BankAccountIssue.BankAccountBeneficiary = BankAccountReceiptNote.BankAccount
		|WHERE
		|	BankAccountReceiptNote.Ref = &DocumentRef";
		
		Query.SetParameter("DocumentRef", DocumentUnderReview);
		
	Else
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	BankAccountIssue.Ref
		|FROM
		|	Document.BankAccountIssue AS BankAccountIssue
		|WHERE
		|	BankAccountIssue.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|	AND BankAccountIssue.BankAccount = &BankAccount
		|	AND BankAccountIssue.DocumentAmount = &DocumentAmount
		|	AND BankAccountIssue.Currency = &Currency
		|	AND BankAccountIssue.IncomingDocumentDate = &IncomingDocumentDate
		|	AND BankAccountIssue.IncomingDocumentNumber = &IncomingDocumentNumber
		|	AND BankAccountIssue.BankAccountBeneficiary = &BankAccountBeneficiary";
		
		Query.SetParameter("BankAccount",				DocumentUnderReview.SenderBankAccount);
		Query.SetParameter("DocumentAmount",				DocumentUnderReview.DocumentAmount);
		Query.SetParameter("Currency",						DocumentUnderReview.Currency);
		Query.SetParameter("IncomingDocumentDate",		DocumentUnderReview.IncomingDocumentDate);
		Query.SetParameter("IncomingDocumentNumber",	DocumentUnderReview.IncomingDocumentNumber);
		Query.SetParameter("BankAccountBeneficiary",	DocumentUnderReview.BankAccount);
		
	EndIf;
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() And Selection.Count() = 1 Then
		MirrorPayment = Selection.Ref;
	EndIf;
	
	Return MirrorPayment;

EndFunction

// Verifies that the transcripts of the payment in the mirror Spainiards,
// for operations between Organizations (of Intercompany).
//
// Parameters:
//	DocumentRef - DocumentRef.BankAccountReceiptNote - Receipt document
//  InvertedPaymentReference - DocumentRef.BankAccountIssue - Write-off document
//  PaymentDecryptionOnly - Boolean - Whether to compare documents only based on the payment transcript
//
// Returns:
//  Boolean - Payment compliance indication
Function CorrespondsToInvertedPayment(DocumentRef, InvertedPaymentReference, PaymentDecryptionOnly=False) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	TRUE AS ThereAreDifferences_
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN
	|				ReceiptOfBDSDecryption.ARAPObject.Object = &NoncashReceipt THEN
	|					UNDEFINED
	|			ELSE
	|				ReceiptOfBDSDecryption.ARAPObject.Object
	|		END AS OrderDocument,
	|		ReceiptOfBDSDecryption.ARAPCurrency AS ARAPCurrency,
	|		SUM(ReceiptOfBDSDecryption.Sum) AS AmountReceived_,
	|		SUM(ReceiptOfBDSDecryption.AmountARAP) AS AmountOfSettlementsReceipt,
	|		SUM(0) AS AmountDebited,
	|		SUM(0) AS AmountOfSettlementsWriteOff,
	|		ReceiptOfBDSDecryption.Ref.BankAccount AS BankAccountReceipt,
	|		ReceiptOfBDSDecryption.Ref.SenderBankAccount AS BankAccountSenderReceipt,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentDate AS DateOfIncomingDocumentReceipt,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentNumber AS IncomingDocumentNumberReceipt,
	|		NULL AS BankAccountRecipientDebiting,
	|		NULL AS BankAccountDebiting,
	|		NULL AS DateOfIncomingDocumentDebited,
	|		NULL AS NumberOfIncomingDebitingDocument
	|	FROM
	|		Document.BankAccountReceiptNote.ARAPDetails AS ReceiptOfBDSDecryption
	|	WHERE
	|		ReceiptOfBDSDecryption.Ref = &NoncashReceipt
	|	
	|	GROUP BY
	|		ReceiptOfBDSDecryption.ARAPCurrency,
	|		CASE
	|			WHEN
	|				ReceiptOfBDSDecryption.ARAPObject.Object = &NoncashReceipt THEN
	|					UNDEFINED
	|			ELSE
	|				ReceiptOfBDSDecryption.ARAPObject.Object
	|		END,
	|		ReceiptOfBDSDecryption.Ref.BankAccount,
	|		ReceiptOfBDSDecryption.Ref.SenderBankAccount,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentDate,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentNumber
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN
	|				BankAccountIssueARAPDetails.ARAPObject.Object = &DebitingBDS THEN
	|					UNDEFINED
	|			ELSE
	|				BankAccountIssueARAPDetails.ARAPObject.Object
	|		END AS OrderDocument,
	|		BankAccountIssueARAPDetails.ARAPCurrency,
	|		0,
	|		0,
	|		SUM(BankAccountIssueARAPDetails.Sum),
	|		SUM(BankAccountIssueARAPDetails.AmountARAP),
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		BankAccountIssueARAPDetails.Ref.BankAccountBeneficiary,
	|		BankAccountIssueARAPDetails.Ref.BankAccount,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentDate,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentNumber
	|	FROM
	|		Document.BankAccountIssue.ARAPDetails AS BankAccountIssueARAPDetails
	|	WHERE
	|		BankAccountIssueARAPDetails.Ref = &DebitingBDS
	|	
	|	GROUP BY
	|		CASE
	|			WHEN
	|				BankAccountIssueARAPDetails.ARAPObject.Object = &DebitingBDS THEN
	|					UNDEFINED
	|			ELSE
	|				BankAccountIssueARAPDetails.ARAPObject.Object
	|		END,
	|		BankAccountIssueARAPDetails.ARAPCurrency,
	|		BankAccountIssueARAPDetails.Ref.BankAccount,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentDate,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentNumber,
	|		BankAccountIssueARAPDetails.Ref.BankAccountBeneficiary) AS DecryptionReceiptWriteOff
	|
	|GROUP BY
	|	DecryptionReceiptWriteOff.OrderDocument,
	|	DecryptionReceiptWriteOff.ARAPCurrency
	|
	|HAVING
	|	(SUM(DecryptionReceiptWriteOff.AmountReceived_) <> SUM(DecryptionReceiptWriteOff.AmountDebited)
	|		OR SUM(DecryptionReceiptWriteOff.AmountOfSettlementsReceipt) <> SUM(DecryptionReceiptWriteOff.AmountOfSettlementsWriteOff)
	|		OR NOT &PaymentDecryptionOnly
	|			AND (MAX(DecryptionReceiptWriteOff.BankAccountReceipt) <> MAX(DecryptionReceiptWriteOff.BankAccountRecipientDebiting)
	|				OR MAX(DecryptionReceiptWriteOff.BankAccountSenderReceipt) <> MAX(DecryptionReceiptWriteOff.BankAccountDebiting)
	|				OR MAX(DecryptionReceiptWriteOff.DateOfIncomingDocumentReceipt) <> MAX(DecryptionReceiptWriteOff.DateOfIncomingDocumentDebited)
	|				OR MAX(DecryptionReceiptWriteOff.IncomingDocumentNumberReceipt) <> MAX(DecryptionReceiptWriteOff.NumberOfIncomingDebitingDocument)))
	|";
	
	Query.SetParameter("NoncashReceipt", DocumentRef);
	Query.SetParameter("DebitingBDS", InvertedPaymentReference);
	Query.SetParameter("PaymentDecryptionOnly", PaymentDecryptionOnly);
	
	Selection = Query.Execute().Select();
	
	Return Not Selection.Next();
	
EndFunction

// Results in compliance with the transcript payment on the mirror Spainiards,
// for operations between Organizations (of Intercompany).
//
// Parameters:
//	DocumentRef - DocumentRef.BankAccountReceiptNote - Receipt document
//  MirrorPaymentObject - DocumentObject.BankAccountIssue - Write-off document
//
// Returns:
//  Boolean - A sign of the success of the operation
Function AlignMirrorPayment(DocumentRef, MirrorPaymentObject) Export
	
	Attributes = New Structure("ARAPDetails, DocumentAmount, SenderBankAccount,
		|BankAccount,IncomingDocumentDate, IncomingDocumentNumber, BusinessOperation");
	Attributes = Common.ObjectAttributesValues(DocumentRef, Attributes);
	
	MirrorPaymentObject.DocumentAmount = Attributes.DocumentAmount;
	MirrorPaymentObject.BankAccount = Attributes.SenderBankAccount;
	MirrorPaymentObject.BankAccountBeneficiary = Attributes.BankAccount;
	MirrorPaymentObject.IncomingDocumentDate= Attributes.IncomingDocumentDate;
	MirrorPaymentObject.IncomingDocumentNumber= Attributes.IncomingDocumentNumber;
	
	If ValueIsFilled(MirrorPaymentObject.Ref)
		And CorrespondsToInvertedPayment(DocumentRef, MirrorPaymentObject.Ref, True) Then
		Return True;
	EndIf;
	
	ARAPDetails = Attributes.ARAPDetails.Unload();
	DecryptionOfPaymentMirrored = MirrorPaymentObject.ARAPDetails;
		
	If ARAPDetails.Count() = 1 And DecryptionOfPaymentMirrored.Count() = 1 Then
		FillPropertyValues(DecryptionOfPaymentMirrored[0], ARAPDetails[0], "ARAPObject, Sum, AmountARAP, ARAPCurrency");
		If Common.ObjectAttributeValue(ARAPDetails[0].ARAPObject,"Object") = DocumentRef Then
			DecryptionOfPaymentMirrored[0].ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		EndIf;
		Return True;
	EndIf;
		
	DefaultArticle = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Attributes.BusinessOperation);
	If Not ValueIsFilled(DefaultArticle) Then
		ArrayOfArticles = DecryptionOfPaymentMirrored.UnloadColumn("CashFlowItem");
		ArrayOfArticles = CommonClientServer.CollapseArray(ArrayOfArticles);

		If ArrayOfArticles.Count() = 1 Then
			DefaultArticle = ArrayOfArticles[0];
		EndIf;
	EndIf;	
	
	DefaultApplication = Undefined;
	If MirrorPaymentObject.PaymentByRequests Then
		ArrayOfRequests = DecryptionOfPaymentMirrored.UnloadColumn("PaymentRequest");
		ArrayOfRequests = CommonClientServer.CollapseArray(ArrayOfRequests);

		If ArrayOfRequests.Count() = 1 Then
			DefaultApplication = ArrayOfRequests[0];
		ElsIf ArrayOfRequests.Count() = 0 Then
			DefaultApplication = DecryptionOfPaymentMirrored.PaymentRequest;
		Else
			CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 không khớp, 
					|không thể điền giấy đề nghị thanh toán theo diễn giải thanh toán.';
					|ru = 'Не приведено в соответствие %1, 
					|не удалось заполнить заявки на расходование дс в расшифровке платежа.';
					|en = 'Not adjusted %1.
					| Cannot fill in payment requests in the payment details.'; fa = 'Not adjusted %1.
					| Cannot fill in payment requests in the payment details.';
					|it = 'Non è reso conforme %1, 
					|non è stato possibile compilare le richieste di spesa dei mezzi finanziari nella trascrizione del pagamento.';
					|pl = 'Nie przedstawiono w zgodności %1, 
					|nie udało się wypełnić wniosku o wydatkowanie ds w szczegółach płatności.';
					|tr = 'Düzeltilmemiş %1, 
					|ödeme ayrıntılarında ödeme talepleri doldurulmadı.'"),MirrorPaymentObject.Ref));
			Return False;

		EndIf;
	EndIf;
				
	Query = New Query("SELECT
	                      |	ARAPObjects.Ref AS ARAPObject,
	                      |	SUM(ARAPDetails.Sum) AS Sum,
	                      |	SUM(ARAPDetails.AmountARAP) AS AmountARAP,
	                      |	ARAPDetails.ARAPCurrency AS ARAPCurrency,
	                      |	CASE
	                      |		WHEN ARAPDetails.ARAPObject.Object REFS Document.CustomerInvoiceIntercompany
	                      |				OR ARAPDetails.ARAPObject.Object REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	                      |				OR ARAPDetails.ARAPObject.Object REFS Document.CommissionReportIntercompany
	                      |			THEN CASE
	                      |					WHEN ARAPDetails.ARAPObject.Contract = VALUE(Catalog.IntercompanyContracts.EmptyRef)
	                      |							OR ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	                      |						THEN &DefaultArticle
	                      |					ELSE ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient
	                      |				END
	                      |		ELSE &DefaultArticle
	                      |	END AS CashFlowItem,
	                      |	&DefaultApplication AS PaymentRequest
	                      |FROM
	                      |	Document.BankAccountReceiptNote.ARAPDetails AS ARAPDetails
	                      |		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
						  |			ON ARAPDetails.ARAPObject.Object = ARAPObjects.Object
						  |				AND ARAPDetails.ARAPObject <> ARAPObjects.Ref
						  |				AND ARAPDetails.ARAPObject.Organization <> ARAPObjects.Organization
						  |				AND ARAPDetails.ARAPObject.PaymentType_ <> ARAPObjects.PaymentType_
						  |				AND NOT ARAPObjects.DeletionMark
	                      |WHERE
	                      |	ARAPDetails.Ref = &Ref
	                      |
	                      |GROUP BY
	                      |	ARAPDetails.ARAPCurrency,
	                      |	ARAPObjects.Ref,
	                      |	CASE
	                      |		WHEN ARAPDetails.ARAPObject.Object REFS Document.CustomerInvoiceIntercompany
	                      |				OR ARAPDetails.ARAPObject.Object REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	                      |				OR ARAPDetails.ARAPObject.Object REFS Document.CommissionReportIntercompany
	                      |			THEN CASE
	                      |					WHEN ARAPDetails.ARAPObject.Contract = VALUE(Catalog.IntercompanyContracts.EmptyRef)
	                      |							OR ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	                      |						THEN &DefaultArticle
	                      |					ELSE ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient
	                      |				END
	                      |		ELSE &DefaultArticle
	                      |	END");
	
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("DefaultArticle",DefaultArticle);
	Query.SetParameter("DefaultApplication",DefaultApplication);
	
	DecryptionResult = Query.Execute().Unload();
	For Each Page1 In DecryptionResult Do
		If Not ValueIsFilled(Page1.CashFlowItem) Then
			CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 không khớp, 
					|không thể điền dạng lưu chuyển tiền tệ theo diễn giải thanh toán.';
					|ru = 'Не приведено в соответствие %1, 
					|не удалось заполнить статьи движения дс в расшифровке платежа.';
					|en = 'Not adjusted %1. 
					|Cannot fill in cash flow items in the payment details.'; fa = 'Not adjusted %1. 
					|Cannot fill in cash flow items in the payment details.';
					|it = 'Non è reso conforme %1, 
					|non è stato possibile compilare le voci di movimento dei mezzi finanziari nella trascrizione del pagamento.';
					|pl = 'Nie uzgodniono %1, 
					| nie udało się wypełnić pozycji przepływu środków pieniężnych w szczegółach płatności';
					|tr = '%1uyumlu değil, 
					| ödeme dökümünde nakit hareket kalemi doldurulamadı.'"),MirrorPaymentObject.Ref));
			Return False;
		EndIf;
	EndDo;
	
	MirrorPaymentObject.ARAPDetails.Load(DecryptionResult);
	
	Return True;
						
EndFunction

#EndRegion

#EndRegion

#EndIf
