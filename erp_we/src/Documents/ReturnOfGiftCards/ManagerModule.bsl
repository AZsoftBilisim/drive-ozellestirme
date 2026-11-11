
#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		
		If (Parameters.Property("Basis")
			And ValueIsFilled(Parameters.Basis))
			Or (Parameters.Property("Key") And Not ValueIsFilled(Parameters.Key)) Then
			
			StandardProcessing = False;
			SelectedForm = "CWPDocumentForm";
			
		ElsIf Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
			
			StandardProcessing = False;
			SelectedForm = "DocumentForm";
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

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
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("GiftCertificates");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	ReturnOfGiftCardsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of value table elements with data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReturnOfGiftCards") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGiftCertificates(Query, QueryTexts, Registers);
		QueryTextTableGiftCardHistory(Query, QueryTexts, Registers);
		QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers);
		QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		// Execution of the request and unloading of the received tables for movements.
		ReturnOfGiftCardsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#Region Other

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array - An array of See ARAPAccountingServer.MechanismParameters
//           - parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	BusinessOperation = Enums.BusinessTransactions.GiftCertificateSale;
	
	StructuresArray = New Array();
	
	#Region AllOtherFunctions
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.ChangesPaymentPlan = True;
		
	ParametersStructure.ChangesCalculationsByString = "";
	
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	ParametersStructure.Partner                          = "Object.Partner";
	ParametersStructure.ARAPObjectSettings                  = "";
	
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	
	ParametersStructure.Organization                      = "Object.Organization";
	ParametersStructure.Terms                       = "";
	ParametersStructure.Contract                          = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "Object.CashRegister";
	ParametersStructure.Date                             = "Object.Date";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Manager                         = "";
	ParametersStructure.IncomingDocumentNumber          = "";
	ParametersStructure.IncomingDocumentDate           = "";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction

#EndRegion

#EndRegion

#Region InterfaceImplementation
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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndRegion

#Region Private

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Return; //In the future, the command code will be added
	
EndProcedure

// Adds a command of creation of the document "the return of the gift certificates".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return;
	
EndProcedure

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	ReturnOfGiftCards.Date        AS Date,
	|	ReturnOfGiftCards.Currency      AS Currency,
	|	ReturnOfGiftCards.Organization AS Organization,
	|	ReturnOfGiftCards.Status      AS Status,
	|	ReturnOfGiftCards.Partner     AS Partner,
	|	ReturnOfGiftCards.Number       AS Number,
	|	ReturnOfGiftCards.Posted       AS Posted,
	|	ReturnOfGiftCards.VATTaxation AS VATTaxation,
	|	ReturnOfGiftCards.DeletionMark    AS DeletionMark,
	|	ReturnOfGiftCards.DocumentAmount AS DocumentAmount,
	|	ReturnOfGiftCards.Cashier AS Cashier,
	|	ReturnOfGiftCards.Comment AS Comment
	|
	|FROM
	|	Document.ReturnOfGiftCards AS ReturnOfGiftCards
	|WHERE
	|	ReturnOfGiftCards.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Attributes.Currency,
		Attributes.Currency, // ARAPCurrency
		Attributes.Date,
		Attributes.Organization);
	
	Query.SetParameter("Ref",      DocumentRef);
	Query.SetParameter("Period",      Attributes.Date);
	Query.SetParameter("Currency",      Attributes.Currency);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.RetailSaleOfGoods);
	Query.SetParameter("CashFlowItem", Catalogs.CashFlowReportItems.RefundToCustomer);
	Query.SetParameter("ReceiptCompleted",             Attributes.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("BusinessTransactionSetting", 	Catalogs.BusinessTransactionsSettings.RetailSaleOfGoods);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.ReturnOfGiftCards"));
	Query.SetParameter("Partner", Attributes.Partner);
	Query.SetParameter("Cashier", Attributes.Cashier);
	Query.SetParameter("Number", Attributes.Number);
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("DocumentAmount", Attributes.DocumentAmount);
	Query.SetParameter("Comment", Attributes.Comment);
	Query.SetParameter("Posted", Attributes.Posted);
	Query.SetParameter("DeletionMark", Attributes.DeletionMark);
	Query.SetParameter("HouseholdOperationForRegistry", Enums.BusinessTransactions.ReturnOfGiftCards);
	Query.SetParameter("VATTaxation", Attributes.VATTaxation);
	
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
	Query.SetParameter("LocalAccountingCurrency", CurrencyOfComplianceAccounting);
	
EndProcedure

Function QueryTextTableGiftCertificates(Query, QueryTexts, Registers)
	
	RegisterName = "GiftCertificates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Period                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                  AS RecordType,
	|	TabularSection.GiftCertificate                     AS GiftCertificate,
	|	TabularSection.GiftCertificate.Owner.Nominal    AS Sum,
	|	TabularSection.Sum * &FactorOfConversionToCurrencyOfRegul AS SumCompl,
	|	TabularSection.RowID                      AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGiftCards) AS BusinessTransactionSetting
	|FROM
	|	Document.ReturnOfGiftCards.GiftCertificates AS TabularSection
	|WHERE
	|	
	|	TabularSection.Ref = &Ref
	|	AND NOT TabularSection.GiftCertificate.Owner.GiftCardAccounting25
	|	AND &ReceiptCompleted
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGiftCardHistory(Query, QueryTexts, Registers)
	
	RegisterName = "GiftCardHistory";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Period                                                        AS Period,
	|	TabularSection.GiftCertificate                            AS GiftCertificate,
	|	VALUE(Enum.GiftCertificateStatuses.Returned__) AS Status
	|FROM
	|	Document.ReturnOfGiftCards.GiftCertificates AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.GiftCertificate.Owner.GiftCardAccounting25 = FALSE 
	|	AND &ReceiptCompleted
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 

	If Not DocumentsPosting.ThereIsQueryTable("TTAmountByPaymentCards", QueryTexts) Then
		QueryTextTTAmountByPaymentCards(Query, QueryTexts);
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.CashRegister.Owner AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.DocumentAmount - ISNULL(TTAmountByPaymentCards.Sum, 0) AS Sum,
	|	CAST((DocumentData.DocumentAmount - ISNULL(TTAmountByPaymentCards.Sum, 0)) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((DocumentData.DocumentAmount - ISNULL(TTAmountByPaymentCards.Sum, 0)) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGiftCards) AS BusinessTransactionSetting
	|FROM
	|	Document.ReturnOfGiftCards AS DocumentData
	|		LEFT JOIN TTAmountByPaymentCards AS TTAmountByPaymentCards
	|		ON (TRUE)
	|WHERE
	|	DocumentData.DocumentAmount - ISNULL(TTAmountByPaymentCards.Sum, 0) <> 0
	|	AND DocumentData.Ref = &Ref
	|	AND &ReceiptCompleted
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 

	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard) AS CashType,
	|	&Organization AS Organization,
	|	&Currency AS Currency,
	|	PaymentTable_3.POSTerminal AS POSTerminal,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END AS Contract,
	|	PaymentTable_3.AuthorizationCode AS AuthorizationCode,
	|	PaymentTable_3.PaymentCardNumber AS PaymentCardNumber,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|	&Period AS PaymentDate,
	|	PaymentTable_3.Sum
	|FROM
	|	Document.ReturnOfGiftCards.PaymentWithPaymentCards AS PaymentTable_3
	|
	|WHERE
	|	&ReceiptCompleted
	|	AND PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.PaymentIsCanceled = TRUE
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 

	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	&Organization                                                                         AS Organization,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.BankAccount
	|		ELSE PaymentTable_3.POSTerminal.Owner.BankAccount
	|	END                                                                                AS Recipient,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.Counterparty
	|		ELSE PaymentTable_3.POSTerminal.Owner.Counterparty
	|	END                                                                                AS Counterparty,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END                                                                                AS Contract,
	|	UNDEFINED                                                                         AS PaymentDocument,
	|	&Currency                                                                              AS Currency,
	|
	|	PaymentTable_3.Sum                                                                AS Sum,
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))    AS SumMan,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))   AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)    AS BusinessOperation,
	|	&CashFlowItem                                                       AS CashFlowItem,
	|	PaymentTable_3.RowID                                                  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGiftCards) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReturnOfGiftCards.PaymentWithPaymentCards AS PaymentTable_3
	|
	|WHERE
	|	&ReceiptCompleted
	|	AND PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.PaymentIsCanceled = TRUE
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTCashFlowCounterparty(Query);
	
	QueryText = "
	|SELECT
	|	Table.Period,
	|	Table.BusinessOperation,
	|	Table.Organization,
	|	Table.Department,
	|
	|	Table.Cash,
	|	Table.LineOfBusinessCash,
	|	Table.CashType,
	|	Table.PaymentCurrency,
	|	Table.CashFlowItem,
	|
	|	Table.Partner,
	|	Table.Counterparty,
	|	Table.Contract,
	|	Table.ARAPObject,
	|
	|	Table.PayAmount,
	|	Table.PaymentAmountLocal,
	|	Table.PaymentAmountPaymentCurrency,
	|
	|	Table.PostpaymentAmount,
	|	Table.PostpaymentAmountLocal,
	|	Table.PaymentAmountInPaymentCurrency,
	|	
	|	Table.PrepaymentAmountMan,
	|	Table.PrepaymentAmountLocal,
	|	Table.PrepaymentAmount,
	|
	|	Table.ARAPCurrency,
	|
	|	Table.PaymentAmountInTheSettlementCurrency,
	|	Table.PostPaymentAmountInARAPCurrency,
	|	Table.PrepaymentAmountInARAPCurrency,
	|
	|	Table.SourceOfCashFinancialAccountingGroup,
	|	Table.SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTCashFlowCounterparty AS Table
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates

	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates =
	"SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ReturnOfGiftCards.GiftCertificates AS Table
	|		LEFT JOIN Document.ReturnOfGiftCards AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)";
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates, True);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);

	#EndRegion
	
	TextReturn = 
		"SELECT
		|	Table.Ref                                                                    AS Ref,
		|	Table.Ref.Organization                                                        AS Organization,
		|	Table.Ref.Partner                                                            AS Partner,
		|	
		|	Table.Ref.Currency                                                             AS ARAPCurrency,
		|	Table.ARAPObject                                                            AS ARAPObject,
		|	
		|	Table.Sum                                                                     AS AmountARAP,
		|	Table.Sum                                                                     AS Sum,
		|	0                                                                                 AS BeingPaid,
		|	                                                                           
		|	Table.Ref.Date                                                               AS RecorderDate,
		|	Table.Ref.Date                                                               AS DateOfCourse,
		|	Table.Ref.Number                                                              AS RecorderNumber,
		|
		|	VALUE(Enum.BusinessTransactions.RefundToCustomer)                 AS BusinessOperation,
		|
		|	CASE
		|		WHEN Table.Ref.DocumentAmount = Table.Ref.IssueInCash
		|			THEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|		WHEN Table.Ref.IssueInCash = 0
		|			THEN VALUE(Enum.PaymentForms.PaymentCard)
		|		ELSE
		|			VALUE(Enum.PaymentForms.EmptyRef)
		|	END                                                                             AS PaymentMethod,
		|	
		|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer)           AS CashFlowItem,
		|	UNDEFINED                                                                      AS ProformaInvoice,
		|	UNDEFINED                                                                      AS PaymentRequest,
		|	Table.Ref.Currency                                                             AS DocumentCurrency,
		|	UNDEFINED                                                                      AS LinkedDocument,
		|	Table.RowID                                                       AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGiftCards) AS BusinessTransactionSetting
		|FROM
		|	Document.ReturnOfGiftCards.GiftCertificates AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND &ReceiptCompleted
		|	AND Table.GiftCertificate.Owner.GiftCardAccounting25 = TRUE
		|";
	
	ARAPAccountingPostingCustomers.MakingRefundToClient(Query, QueryTexts, Registers, TextReturn);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	&HouseholdOperationForRegistry AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	&Partner AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&Cashier AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	&DocumentAmount AS Sum,
	|	&Currency AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAmountByPaymentCards(Query, QueryTexts)
	
	RegisterName = "TTAmountByPaymentCards";
	
	QueryText = "
	|SELECT
	|	SUM(TabularSection.Sum) AS Sum
	|INTO TTAmountByPaymentCards
	|FROM
	|	Document.ReturnOfGiftCards.PaymentWithPaymentCards AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.PaymentIsCanceled
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeTTCashFlowCounterparty(Query)
	
	If Query.Parameters.Property("TTCashFlowCounterpartyInitialized") Then
		Return;
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	InitializationRequest = New Query("
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashRegister.Department AS Department,
	|
	|	DocumentData.CashRegister AS Cash,
	|	GiftCertificateKinds.LineOfBusiness AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|	DocumentData.Currency AS PaymentCurrency,
	|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer) AS CashFlowItem,
	|
	|	UNDEFINED AS Partner,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	PaymentTable_3.GiftCertificate AS ARAPObject,
	|
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|	PaymentTable_3.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PrepaymentAmountMan,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PrepaymentAmountLocal,
	|	PaymentTable_3.Sum AS PrepaymentAmount,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	DocumentData.CashRegister AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.ReturnOfGiftCards.GiftCertificates AS PaymentTable_3
	|		LEFT JOIN Document.ReturnOfGiftCards AS DocumentData
	|		ON (DocumentData.Ref = PaymentTable_3.Ref)
	|		INNER JOIN Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|		ON PaymentTable_3.GiftCertificate.Owner = GiftCertificateKinds.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	CompaniesBankAccounts.Department AS Department,
	|
	|	PaymentTable_3.POSTerminal.Owner AS Cash,
	|	CompaniesBankAccounts.LineOfBusiness AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	DocumentData.Currency AS PaymentCurrency,
	|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer) AS CashFlowItem,
	|
	|	UNDEFINED AS Partner,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|	PaymentTable_3.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PrepaymentAmountMan,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PrepaymentAmountLocal,
	|	PaymentTable_3.Sum AS PrepaymentAmount,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	CompaniesBankAccounts.Ref AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS PaymentProcessed
	|FROM
	|	Document.ReturnOfGiftCards.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Document.ReturnOfGiftCards AS DocumentData
	|		ON (DocumentData.Ref = PaymentTable_3.Ref)
	|		INNER JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON PaymentTable_3.POSTerminal.Owner.BankAccount = CompaniesBankAccounts.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.PaymentIsCanceled = TRUE
	|	AND PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	PaymentTable_3.ConnectionContract.BankAccount.Department AS Department,
	|
	|	PaymentTable_3.ConnectionContract AS Cash,
	|	PaymentTable_3.ConnectionContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	DocumentData.Currency AS PaymentCurrency,
	|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer) AS CashFlowItem,
	|
	|	UNDEFINED AS Partner,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|	PaymentTable_3.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PrepaymentAmountMan,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PrepaymentAmountLocal,
	|	PaymentTable_3.Sum AS PrepaymentAmount,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	PaymentTable_3.ConnectionContract.BankAccount AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS PaymentProcessed
	|FROM
	|	Document.ReturnOfGiftCards.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Document.ReturnOfGiftCards AS DocumentData
	|		ON (DocumentData.Ref = PaymentTable_3.Ref)
	|WHERE
	|	PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.PaymentIsCanceled = TRUE
	|	AND NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|");
	
	InitializationRequest.Parameters.Insert("Ref", Query.Parameters.Ref);
	InitializationRequest.Parameters.Insert("ConversionRateToManCurrency", Query.Parameters.ConversionRateToManCurrency);
	InitializationRequest.Parameters.Insert("FactorOfConversionToCurrencyOfRegul", Query.Parameters.FactorOfConversionToCurrencyOfRegul);
	
	QueryResult = InitializationRequest.ExecuteBatch();
	PaymentGiftCertificates = QueryResult[0].Unload();
	PaymentPaymentCards        = QueryResult[1].Unload();
	
	QueryIsStoredInTemporaryTable = New Query("
	|SELECT
	|	Table.Period,
	|	Table.BusinessOperation,
	|	Table.Organization,
	|	Table.Department,
	|
	|	Table.Cash,
	|	Table.LineOfBusinessCash,
	|	Table.CashType,
	|	Table.PaymentCurrency,
	|	Table.CashFlowItem,
	|
	|	Table.Partner,
	|	Table.Counterparty,
	|	Table.Contract,
	|	Table.ARAPObject,
	|
	|	Table.PayAmount,
	|	Table.PaymentAmountLocal,
	|	Table.PaymentAmountPaymentCurrency,
	|
	|	Table.PostpaymentAmount,
	|	Table.PostpaymentAmountLocal,
	|	Table.PaymentAmountInPaymentCurrency,
	|	
	|	Table.PrepaymentAmountMan,
	|	Table.PrepaymentAmountLocal,
	|	Table.PrepaymentAmount,
	|
	|	Table.ARAPCurrency,
	|
	|	Table.PaymentAmountInTheSettlementCurrency,
	|	Table.PostPaymentAmountInARAPCurrency,
	|	Table.PrepaymentAmountInARAPCurrency,
	|
	|	Table.SourceOfCashFinancialAccountingGroup,
	|	Table.SourceOfARAPFinancialAccountingGroup
	|INTO TTCashFlowCounterparty
	|FROM
	|	&Table AS Table
	|");
	
	RecordsCashCounterparty = GiftCertificatesServer.PrepareCashFlowTableCounterparty(
		PaymentGiftCertificates,
		PaymentPaymentCards);
	QueryIsStoredInTemporaryTable.TempTablesManager = Query.TempTablesManager;
	QueryIsStoredInTemporaryTable.Parameters.Insert("Table", RecordsCashCounterparty);
	QueryIsStoredInTemporaryTable.Execute();
	
	Query.SetParameter("TTCashFlowCounterpartyInitialized", True);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
	                                                                         Undefined,
	                                                                         Query.Parameters.Period,
	                                                                         Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return ReturnOfGiftCardsLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ReturnOfGiftCardsLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ReturnOfGiftCards";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ReturnOfGiftCards"));
	ParameterValues.Insert("HouseholdOperationForRegistry", Enums.BusinessTransactions.ReturnOfGiftCards);
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
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
			QueryText, FullDocumentName, SynonymForDocumentTable, False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ReturnOfGiftCardsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	ReturnOfGiftCardsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// The function receives data for forming the KM-3 printing form.
//
// Returns:
// 	Structure:
//		* QueryResult - QueryResult - Contains information for filling out a printed form
//		* DocumentTitle - String - The displayed title of the tabular document
//
Function GetDataForPrintedFormKM3(PrintParameters, ObjectsArray) Export
	
	Return ReturnOfGiftCardsLocalization.GetDataForPrintedFormKM3(PrintParameters, ObjectsArray);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
