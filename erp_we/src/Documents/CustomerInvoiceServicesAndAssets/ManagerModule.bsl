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
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CustomerInvoiceServicesAndAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CustomerInvoiceServicesAndAssets") Then
		DocumentRef = Document.Ref;
		DocumentObject = Document;
	Else
		DocumentRef = Document;
		DocumentObject = Document.GetObject();
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If AddlParameters <> Undefined
		And AddlParameters.Property("TempTablesManager")
		And AddlParameters.TempTablesManager <> Undefined Then
		Query.TempTablesManager = AddlParameters.TempTablesManager;
	Else
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers, DocumentObject);
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers, DocumentObject);
		QueryTextTableInvestmentInRent(Query, QueryTexts, Registers);
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject);
		
		CustomerInvoiceServicesAndAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	ReflectOtherRevenue(Query, QueryTexts, Registers, DocumentObject);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	GetDataOfDeferredEventDocument(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTDocumentPeriods");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	QueryTexts = New ValueList;
	
	QueryTextTableTTResidualValue(QueryTexts);
	
	QueryTextTableIACost(QueryTexts);
	QueryTextTableOtherExpensesDeferredRegisteredRecords(Query, QueryTexts);
	QueryTextTableIncomeExpensesRegisteredRecordsOtherAssetsLiabilitiesDeferredRegisteredRecords(Query, QueryTexts);
	
	CustomerInvoiceServicesAndAssetsLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements when performing the operation "Closing expenses from the disposal of fixed assets".
//
// Parameters:
//  TempTablesManager	- TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//  RegisterRecordsPeriod - Date - The month in which Registered Records are generated
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfRegisteredRecordsInClosingExpensesFromDisposalOfFA(TempTablesManager, RegisterRecordsPeriod) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("RegisterRecordsPeriod", RegisterRecordsPeriod);
	
	GetDataOfDeferredEventDocument(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTDocumentPeriods");
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	ClosingExpensesFromDisposalOfFixedAssets.SetRequestParameters(Query);

	QueryTexts = New ValueList;
	
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableOtherExpenses(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableReflectionOfDocumentsInLocalAccounting(QueryTexts);
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.TempTablesManager = TempTablesManager;
	AddlParameters.OnlyMarkedOnes = True;
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return TablesForRegisteredRecords;
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.SaleAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	CustomerInvoiceServicesAndAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create the document "Sales of services and other assets".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoiceServicesAndAssets) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CustomerInvoiceServicesAndAssets);
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
	
	ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	
	CustomerInvoiceServicesAndAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Provides data for setting off payments
// Parameters:
//	DocumentRef - DocumentRef.CustomerInvoiceServicesAndAssets - the result is generated using this link
// Returns:
//	Structure - The structure with the data of the specified document, the data can be substituted, depending on the state of the document.
Function DocumentAttributes(DocumentRef) Export
	Attributes = New Structure("Date, BusinessOperation, Organization",
		'00010101', Enums.BusinessTransactions.SaleToCustomer, Catalogs.Companies.EmptyRef());
	Attributes.Insert("Partner", Catalogs.Partners.EmptyRef());
	Attributes.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Attributes.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	Attributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	Attributes.Insert("ARAPObjectSettings", Enums.ARAPObjectSettings.EmptyRef());
	Attributes.Insert("ByOrder", False);
	Attributes.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Attributes.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	Attributes.Insert("DocumentAmount", 0);
	Attributes.Insert("AmountARAP", 0);
	Attributes.Insert("Rate", 1);
	Attributes.Insert("Repetition", 1);
	
	Query = New Query("
		|SELECT
		|	Data.Date AS Date,
		|	(CASE WHEN Data.BusinessOperation=VALUE(Enum.BusinessTransactions.EmptyRef)
		|		THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		ELSE Data.BusinessOperation END) AS BusinessOperation,
		|	Data.Organization AS Organization,
		|	Data.Partner AS Partner,
		|	Data.Counterparty AS Counterparty,
		|	Data.Contract AS Contract,
		|	Data.LineOfBusiness AS LineOfBusiness,
		|	Data.ARAPObjectSettings AS ARAPObjectSettings,
		|	FALSE AS ByOrder,
		|	Data.Currency AS Currency,
		|	Data.ARAPCurrency AS ARAPCurrency,
		|	Data.DocumentAmount AS DocumentAmount,
		|	(CASE WHEN Data.Posted THEN Data.AmountARAP ELSE 0 END) AS AmountARAP,
		|	Data.CourseNumerator AS Rate,
		|	Data.CourseDenominator AS Repetition
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS Data
		|WHERE
		|	Data.Ref = &DocumentRef
		|");
	Query.SetParameter("DocumentRef", DocumentRef);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(Attributes, Selection);
	EndIf;
	Return Attributes;
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CustomerInvoiceServicesAndAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CustomerInvoiceServicesAndAssetsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// 	Structure - See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Expenses";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.AssetAndLiabilityItem = "AssetAndLiabilityItem";
	
	SetupParameters.AvailabilityByOperation = Not
		(BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
		Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer);
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("ExpensesPresentationOfRecordingInComplAccounting");
	
	Return SetupParameters;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//	SaleToAssociatedPerson - Boolean - sign of implementation to an interdependent person
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, SaleToAssociatedPerson) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpensesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Expenses";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpensesAssetAndLiabilityItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Expenses";
	ChoiceParameters.AssetRef = "AssetAndLiabilityItem";
	ChoiceParameters.AvailabilityByOperation = Not
		(BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
		Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesAssetAndLiabilityItem");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAssetsLiabilitiesDimension");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpensesIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Expenses";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.AvailabilityByOperation =
		SaleToAssociatedPerson
		And (BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
		 Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer);
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesIncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("ExpensesDimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region IncomeIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Income";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeIncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("IncomeDimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.PathToTSData                    = "Object.Income";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentSettlement";
	ParametersStructure.FormItems.AmountOfTSSettlements = "IncomeAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	ParametersStructure.CourseNumerator                          = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                        = "Object.CourseDenominator";
	
	//The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies                    = "CurrencyDecoration";
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	//Function Payment stages and payment date
	ParametersStructure.PaymentDate                        = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText                 = "Form.PaymentStepsText";
	ParametersStructure.FormItems.InscriptionStages         = "DecorationPaymentSteps";
	ParametersStructure.ThereIsDateOfTransferOfOwnership = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	ParametersStructure.PaymentSchedule                       = "Object.PaymentSchedule";
	
	#EndRegion
	
	#Region MutualSettlementsStatus
	
	//The name of the hyperlink that displays the status of calculations and opens the corresponding report,
	ParametersStructure.FormItems.InscriptionCalculations = "DecorationSettlementState";
	
	#EndRegion
	
	#Region LimitsOnDebtUnderAgreement
	
	//Hyperlink displaying the status of the debt limit
	ParametersStructure.FormItems.DebtLimitationText    = "DecorationDebtLimitation";
	//A picture showing the shipment ban
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited"; 
	
	#EndRegion
	
	Return ParametersStructure;
EndFunction

#Region StatusChangeChecks

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle") Then
		
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfCustomerInvoices.InTransit, NStr("vi = 'Đã chuyển giao';
																													|ru = 'Передано';
																													|en = 'Handed over'; fa = 'تحویل‌شده';
																													|it = 'Consegnato';
																													|pl = 'Handed over';
																													|tr = 'Teslim edilenler'"));
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfCustomerInvoices.Shipped);
				
	EndIf;
	
	Return Table;
	
EndFunction

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
	
	MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                    AS StatusMatches,
	|	DocumentsTable.Posted               AS Posted,
	|	DocumentsTable.DeletionMark        AS DeletionMark,
	|	TRUE                                   AS Recording,
	|	FALSE                                     AS OrderSales,
	|
	|	DocumentsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		OR DocumentsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale) AS ThisIsImplementationToClient,
	|
	|	DocumentsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		OR DocumentsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer) AS ThisIsImplementationWithNoTransferOfOwnership,
	|
	|	DocumentsTable.Date                            AS Date,
	|	DocumentsTable.DateOfTransferOfTitleToGoods  AS DateOfTransferOfTitleToGoods
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.StatusesOfCustomerInvoices - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Var DateOfTransferOfTitleToGoods;
	
	Cancel = False;
	
	MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices[NewStatus];
	
	If AdditionalParameters <> Undefined Then
		AdditionalParameters.Property("NewDate", DateOfTransferOfTitleToGoods);
	EndIf;
	
	If ValidationSample.ThisIsImplementationToClient Then
		
			ErrorText = NStr("vi = 'Chưa đặt trạng thái ""%Status%"" trong chứng từ %Document%, bởi vì không áp dụng trạng thái đối với chứng từ giao hàng với giao dịch ""Bán hàng cho khách""';
							|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. для реализаций с операцией ""Реализация клиенту"" статусы не применимы';
							|en = 'The ""%Status%"" status is not selected for the %Document% document as statuses are not applied for the ""Customer sales"" operation sale'; fa = 'The ""%Status%"" status is not selected for the %Document% document as statuses are not applied for the ""Customer sales"" operation sale';
							|it = 'Il documento %Document%ha lo stato ""%Status%"" non impostato, perché per le vendite con l''operazione ""Vendita al cliente"" gli stati non sono applicabili';
							|pl = 'Dokument %Document% nie ma ustawionego statusu ""%Status%"", ponieważ dla sprzedazy z ""Sprzedaż klientowi"" statusy nie są stosowane';
							|tr = '%Document%Belgede durum ""%Status%"" ayarlanmamıştır, çünkü ""Müşteriye sat"" işlemine sahip uygulamalar için durumlar geçerli değildir'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
		
	ElsIf MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices.InTransit
		And Not ValidationSample.ThisIsImplementationWithNoTransferOfOwnership Then
		
			ErrorText = NStr("vi = 'Chưa đặt trạng thái ""%Status%"" cho chứng từ %Document%, bởi vì trạng thái này chỉ
				|được áp dụng đối với chứng từ giao hàng có giao dịch ""Giao hàng (hàng đi đường)""';
				|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. этот статус применим
				|только для реализаций с операцией ""Реализация (товары в пути)""';
				|en = 'Status ""%Status%"" is not set for document %Document% as this status applies only to sales 
				|using transaction ""Customer invoice — Goods-in-transit""'; fa = 'Status ""%Status%"" is not set for document %Document% as this status applies only to sales 
				|using transaction ""Customer invoice — Goods-in-transit""';
				|it = 'Il documento %Document%ha lo stato ""%Status%"" non impostato, perché questo stato è applicabile 
				| solo per le vendite con l''operazione ""Vendita (merce in transito)""';
				|pl = 'Dokument %Document% nie ma statusu ""%Status%"", ponieważ ten status można zastosować
				|tylko dla realizacji z operacją ""Realizacja (wiersze pozycji w drodze)""';
				|tr = '""%Document%"" belgesi ""%Status%"" durumuna sahip değildir, çünkü bu durum yalnızca
				| ""Satış (yoldaki ürünler)"" işlemi ile yapılan satışlar için geçerlidir'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);	
			
	ElsIf MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices.Shipped
		And ValidationSample.ThisIsImplementationWithNoTransferOfOwnership
		And DateOfTransferOfTitleToGoods < BegOfDay(ValidationSample.Date) Then
		
			ErrorText =  NStr("vi = 'Đối với chứng từ %Document% chưa đặt ngày chuyển giao quyền sở hữu ""%TransitionDate%"", 
				|bởi vì ngày này không thể nhỏ hơn ngày chứng từ ""%Date%""';
				|ru = 'У документа %Document% не установлена дата перехода права собственности ""%TransitionDate%"", 
				|так как она не может быть меньше даты документа ""%Date%""';
				|en = 'Set date ""%TransitionDate%"" of transfer of title to goods in document %Document%. 
				|It cannot be earlier than date ""%Date%"" of the document'; fa = 'Set date ""%TransitionDate%"" of transfer of title to goods in document %Document%. 
				|It cannot be earlier than date ""%Date%"" of the document';
				|it = 'Il documento %Document% ha la data del passaggio di proprietà non impostata ""%TransitionDate%"", 
				| perché tale data non può essere precedente alla data del documento ""%Date%""';
				|pl = 'Dokument %Document% nie ma ustalonej daty przejścia prawa własności ""%TransitionDate%"", 
				|ponieważ ona nie może być mniejsza niz data dokumentu ""%Date%"".';
				|tr = '%Document% belgesinin mülkiyet devir tarihi ""%TransitionDate%"" belirtilmedi,
				| çünkü belgenin tarihinden ""%Date%"" daha önce olamaz'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%TransitionDate%", Format(DateOfTransferOfTitleToGoods, "DLF=D"));
			ErrorText = StrReplace(ErrorText, "%Date%", Format(ValidationSample.Date, "DLF=D"));
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
			
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes parameters for filling in sales VAT taxation
//
// Parameters:
//  Object - DocumentObject.CustomerInvoiceServicesAndAssets, DocumentRef.CustomerInvoiceServicesAndAssets, FormDataStructure - the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	If TypeOf(Object) = Type("DocumentObject.CustomerInvoiceServicesAndAssets")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Organization,Date,Contract,LineOfBusiness");
	EndIf;
	
	FillParameters.Organization = ObjectData.Organization;
	FillParameters.Date = ObjectData.Date;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	FillParameters.OtherAssetSale = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.CustomerInvoiceServicesAndAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.ImplementationOfWorksServices = True;
	RegistrationParameters.OtherAssetSale = (Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale);
	
	Return RegistrationParameters;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";

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

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
EndProcedure

#Region Other

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Cung cấp dịch vụ và tài sản khác';
		|ru = 'Реализация услуг и прочих активов';
		|en = 'Customer invoice — Services and Assets'; fa = 'فاکتور مشتری — خدمات و دارایی‌ها';
		|it = 'Vendita dei servizi e altri attivi';
		|pl = 'Realizacja usług i innych aktywów';
		|tr = 'Müşteri faturası - Hizmetler ve Varlıklar'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                                 AS Period,
	|	DocumentData.DateOfTransferOfTitleToGoods       AS DateOfTransferOfTitleToGoods,
	|	DocumentData.PaymentDate                          AS PaymentDate,
	|	DocumentData.Ref                               AS Ref,
	|	DocumentData.Organization                          AS Organization,
	|	DocumentData.Partner                              AS Partner,
	|	DocumentData.Counterparty                           AS Counterparty,
	|	DocumentData.Currency                               AS Currency,
	|	CASE WHEN DocumentData.CourseNumerator = 0
	|			THEN 1
	|			ELSE DocumentData.CourseNumerator
	|	END                                                AS Rate,
	|	CASE WHEN DocumentData.CourseDenominator = 0
	|			THEN 1
	|			ELSE DocumentData.CourseDenominator
	|	END                                                Repetition,
	|	DocumentData.ARAPCurrency                 AS ARAPCurrency,
	|	DocumentData.LocalAccountingCurrency 		 AS LocalAccountingCurrency,
	|	DocumentData.PriceIncludesVAT                      AS PriceIncludesVAT,
	|	DocumentData.Department                        AS Department,
	|	DocumentData.BusinessOperation                AS BusinessOperation,
	|	DocumentData.Status                               AS Status,
	|	DocumentData.PaymentMethod                          AS PaymentMethod,
	|	DocumentData.Contract                              AS Contract,
	|	DocumentData.Contract.ContractType                  AS ContractType,
	|	DocumentData.Contract.AllowableAmountPayable AS AllowableAmountPayable,
	|	DocumentData.VATTaxation                   AS VATTaxation,
	|	DocumentData.FinancialAccountingGroup               AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness              AS LineOfBusiness,
	|	DocumentData.Number                                AS Number,
	|	DocumentData.Manager                             AS Manager,
	|	DocumentData.Author                                AS Author,
	|	DocumentData.DocumentAmount                       AS DocumentAmount,
	|	DocumentData.Comment                          AS Comment,
	|	DocumentData.DeletionMark                      AS DeletionMark,
	|	DocumentData.Posted                             AS Posted,
	|	DocumentData.ARAPObject                       AS ARAPObject,
	|	DocumentData.IDARAPObject 		 AS IDARAPObject,
	|	DocumentData.BusinessTransactionSetting		 AS BusinessTransactionSetting,
	|	UNDEFINED AS AdjustmentPeriod_
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	TransferOfTitleToGoods = (Attributes.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
									Or Attributes.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
								And Attributes.Status = Enums.StatusesOfCustomerInvoices.Shipped;
	
	ListOfTransactionsOtherRevenue = New Array;
	ListOfTransactionsOtherRevenue.Add(Enums.BusinessTransactions.SaleToCustomer);
	ListOfTransactionsOtherRevenue.Add(Enums.BusinessTransactions.NonCurrentAssetsSale);
	ListOfTransactionsOtherRevenue.Add(Enums.BusinessTransactions.RenderRentalServices);
	Query.SetParameter("Currency",                          Attributes.Currency);
	Query.SetParameter("Rate",                            Attributes.Rate);
	Query.SetParameter("Repetition",                       Attributes.Repetition);
	Query.SetParameter("ARAPCurrency",            Attributes.ARAPCurrency);
	Query.SetParameter("LocalAccountingCurrency",  Attributes.LocalAccountingCurrency);
	Query.SetParameter("Period",                          Attributes.Period);
	Query.SetParameter("PaymentDate",                     Attributes.PaymentDate);
	Query.SetParameter("DateOfTransferOfTitleToGoods",  Attributes.DateOfTransferOfTitleToGoods);
	Query.SetParameter("TransferOfTitleToGoods",       TransferOfTitleToGoods);
	Query.SetParameter("PaymentMethod",                     Attributes.PaymentMethod);
	Query.SetParameter("Organization",                     Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",                 ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("Department",                   Attributes.Department);
	Query.SetParameter("BusinessOperation",           Attributes.BusinessOperation);
	Query.SetParameter("Status",                          Attributes.Status);
	Query.SetParameter("Contract",                         Attributes.Contract);
	Query.SetParameter("ContractType",                     Attributes.ContractType);
	Query.SetParameter("Counterparty",                      Attributes.Counterparty);
	Query.SetParameter("AllowableAmountPayable",    Attributes.AllowableAmountPayable);
	Query.SetParameter("VATTaxation",              Attributes.VATTaxation);
	Query.SetParameter("Partner",                         Attributes.Partner);
	Query.SetParameter("FinancialAccountingGroup",          Attributes.FinancialAccountingGroup);
	Query.SetParameter("LineOfBusiness",         Attributes.LineOfBusiness);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation",          ContractInformation);
	Query.SetParameter("DocumentAmount",                Attributes.DocumentAmount);
	Query.SetParameter("Number",                         Attributes.Number);
	Query.SetParameter("Comment",                   Attributes.Comment);
	Query.SetParameter("DeletionMark",               Attributes.DeletionMark);
	Query.SetParameter("Posted",                      Attributes.Posted);
	Query.SetParameter("Manager",                      Attributes.Manager);
	Query.SetParameter("Author",                         Attributes.Author);
	Query.SetParameter("ARAPObject", Attributes.ARAPObject);
	Query.SetParameter("IDARAPObject", Attributes.IDARAPObject);
	Query.SetParameter("ListOfTransactionsOtherRevenue", ListOfTransactionsOtherRevenue);
	Query.SetParameter("BusinessTransactionSetting", Attributes.BusinessTransactionSetting);
	Query.SetParameter("AdjustmentPeriod_", Attributes.AdjustmentPeriod_);
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableRevenues(ListOfRequests);
	QueryTextDocumentDataTableExpenses(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPaymentWithSettlementObjects(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date,
	|	DocumentData.DateOfTransferOfTitleToGoods,
	|	DocumentData.PaymentDate,
	|	DocumentData.Organization,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Shipper,
	|	DocumentData.GoodsRecipient,
	|	DocumentData.Currency,
	|	DocumentData.CourseNumerator,
	|	DocumentData.CourseDenominator,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.PriceIncludesVAT,
	|	DocumentData.Department,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Status,
	|	DocumentData.PaymentMethod,
	|	DocumentData.Contract,
	|	DocumentData.Contract.AllowableAmountPayable AS AllowableAmountPayable,
	|	DocumentData.VATTaxation,
	|	DocumentData.FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness,
	|	DocumentData.LineOfBusiness.VendorARAP AS LineOfBusinessSIsAccountingOfVendorsARAP,
	|	DocumentData.Number,
	|	DocumentData.Manager,
	|	DocumentData.Author,
	|	DocumentData.DocumentAmount,
	|	DocumentData.AmountARAP,
	|	DocumentData.ARAPObjectSettings,
	|	DocumentData.Comment,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|INTO DocumentDataHeader
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref IN (&Ref)
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableRevenues(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentTable.Ref              AS Ref,
	|	DocumentTable.LineNumber         AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IncomeItem       AS IncomeItem,
	|	DocumentTable.DimensionOfRevenue    AS DimensionOfRevenue,
	|	DocumentTable.IncomeItem.IncomeByAssets AS IncomeByAssets,
	|	DocumentTable.IncomeItem.IntangibleAssetsAndRDIncome AS IntangibleAssetsAndRDIncome,
	|	DocumentTable.Content          AS Content,
	|	DocumentTable.UnitOfMeasure    AS UnitOfMeasure,
	|	DocumentTable.FEACNCode            AS FEACNCode,
	|	DocumentTable.Count          AS Count,
	|	DocumentTable.AmountIncludingVAT           AS AmountIncludingVAT,
	|	DocumentTable.VATAmount            AS VATAmount,
	|	DocumentTable.VATRate           AS VATRate,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	DocumentTable.RentalComponentOfContract AS RentalComponentOfContract,
	|	DocumentTable.RentalObject       AS RentalObject
	|INTO DocumentDataTableRevenues
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Income AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableExpenses(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	DocumentTable.RowID,
	|	DocumentTable.ExpenseItem,
	|	DocumentTable.ExpenseItem.CostAllocationOptionManag AS ExpenseItemCostAllocationOptionManag,
	|	DocumentTable.DimensionOfExpenses,
	|	DocumentTable.AssetAndLiabilityItem,
	|	DocumentTable.AssetsLiabilitiesDimension,
	|	CASE WHEN FALSE
	|			THEN DocumentTable.Ref.LineOfBusiness
	|		WHEN VALUETYPE(DocumentTable.AssetsLiabilitiesDimension) = TYPE(Catalog.Assets)
	|			THEN DocumentTable.AssetsLiabilitiesDimension.LineOfBusiness
	|			ELSE DocumentTable.Ref.LineOfBusiness
	|	END AS AnalyticsOfAssetsLiabilitiesLineOfBusiness,
	|	DocumentTable.NonCurrentAsset,
	|	DocumentTable.ReverseBonusDepreciation,
	|	DocumentTable.AssetKind,
	|	DocumentTable.GLAccountSettings,
	|
	|	DocumentTable.Sum,
	|	DocumentTable.SumCompl,
	|	DocumentTable.PermanentDifference,
	|	DocumentTable.CostTD,
	|	DocumentTable.AmountOfDepreciationAllowance
	|INTO DocumentDataTableExpenses
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Expenses AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|INDEX BY
	|	Ref
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests)
	
	QueryText =
	"SELECT
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.LineNumber,
	|	PaymentDecryptionTable.ARAPObject,
	|
	|	PaymentDecryptionTable.Sum,
	|	PaymentDecryptionTable.AmountARAP
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref IN (&Ref)
	|INDEX BY
	|	Ref
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPaymentWithSettlementObjects(ListOfRequests)
	
	QueryText =
	"SELECT
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.LineNumber,
	|	PaymentDecryptionTable.ARAPObject,
	|
	|	DataObjectOfCalculations.Department AS ObjectOfCalculationsDivision,
	|	DataObjectOfCalculations.Organization AS ARAPObjectOfCompany,
	|	DataObjectOfCalculations.Ref AS ARAPObjectLink,
	|
	|	PaymentDecryptionTable.Sum,
	|	PaymentDecryptionTable.AmountARAP
	|INTO DocumentDataTableDecryptionOfPaymentWithSettlementObjects
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentTable
	|	LEFT JOIN Document.CustomerInvoiceServicesAndAssets.ARAPDetails AS PaymentDecryptionTable
	|		ON DocumentTable.Ref = PaymentDecryptionTable.Ref
	|	LEFT JOIN Catalog.ARAPObjects AS DataObjectOfCalculations
	|		ON DocumentTable.Contract = DataObjectOfCalculations.Object
	|			AND NOT DataObjectOfCalculations.DeletionMark
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|INDEX BY
	|	Ref
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency, 
	                                                                         Query.Parameters.ARAPCurrency, 
	                                                                         Query.Parameters.Period,
	                                                                         Query.Parameters.Organization);

	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToSettlementCurrency",Coefficients.ConversionRateToSettlementCurrency);
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																				Query.Parameters.ARAPCurrency,
																				Query.Parameters.Period,
																				Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency_",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("ConversionRateToLocalTransferCurrency", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTTTableOtherIncome(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTTableOtherIncome";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	TableRevenue.IncomeItem             AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue          AS DimensionOfRevenue,
	|	TableRevenue.Count                AS Count,
	|	TableRevenue.AmountARAP       AS AmountARAP,
	|	TableRevenue.VATRate                 AS VATRate,
	|	TableRevenue.RentalComponentOfContract AS RentalComponentOfContract,
	|	&AdjustmentPeriod_                    AS AdjustmentPeriod_,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)    AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)  AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)    AS VATLocal,
	|	ISNULL(Amounts.VATAmountMan, 0)     AS VATManag,
	|
	|	TableRevenue.RowID AS RowID,
	|	CASE
	|		WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.RenderRentalServices)
	|			THEN &BusinessTransactionSetting
	|		WHEN TableRevenue.RentalComponentOfContract
	|			THEN &BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
	|	END AS BusinessTransactionSetting
	|
	|INTO TTTableOtherIncome
	|FROM
	|	DocumentDataTableRevenues AS TableRevenue
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableRevenue.Ref = Amounts.Ref
	|		AND TableRevenue.RowID = Amounts.RowID
	|WHERE
	|	TableRevenue.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName); 
	Return QueryText;
	
EndFunction

Procedure ReflectOtherRevenue(Query, QueryTexts, Registers, DocumentObject)

	RegisterName = "RevenueServicesAndAssets";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTableOtherIncome", QueryTexts) Then
		QueryTextTTTableOtherIncome(Query, QueryTexts, DocumentObject);
	EndIf;
	
	TextOtherRevenue =
	"SELECT
	|	CASE
	|		WHEN &TransferOfTitleToGoods
	|			THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END                             AS Period,
	|
	|	&Organization                      AS Organization,
	|	&Partner                          AS Partner,
	|	&Counterparty                       AS Counterparty,
	|	&Contract                          AS Contract,
	|	&Department                    AS Department,
	|	UNDEFINED                      AS Individual,
	|	&LineOfBusiness          AS LineOfBusiness,
	|	&BusinessOperation            AS BusinessOperation,
	|	TableRevenue.IncomeItem       AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue    AS DimensionOfRevenue,
	|	TableRevenue.Count          AS Count,
	|
	|	TableRevenue.AmountExcludingVATMan      AS RevenueExcludingVATManag,
	|	TableRevenue.AmountExcludingVATCompl     AS RevenueExcludingVATLocal,
	|	TableRevenue.AmountIncludingVATMan - TableRevenue.AmountExcludingVATMan AS VATManag,
	|	TableRevenue.VATLocal             AS VATLocal, 
	|	0 AS RevenueAmountPD,
	|	TableRevenue.VATRate           AS VATRate,
	|	&VATTaxation               AS VATTaxation,
	|	&ARAPCurrency             AS ARAPCurrency,
	|	TableRevenue.AmountARAP AS AmountARAP,
	|	&ARAPObject                   AS ARAPObject,
	|	TableRevenue.RowID AS FinRecordID,
	|	TableRevenue.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_              AS AdjustmentPeriod_
	|
	|FROM
	|	TTTableOtherIncome AS TableRevenue
	|
	|WHERE
	|	(&BusinessOperation IN (&ListOfTransactionsOtherRevenue)
	|	OR &TransferOfTitleToGoods)
	|	AND NOT (&BusinessOperation = VALUE(Enum.BusinessTransactions.RenderRentalServices)
	|			AND TableRevenue.RentalComponentOfContract)";
	
	IncomeAndExpensesServer.ReflectOtherRevenue(Query, QueryTexts, Registers, TextOtherRevenue);
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""Income"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Date AS VATBasePeriod,
	|	DocumentData.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataTableRevenues AS DocumentTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON DocumentTable.Ref = DocumentData.Ref
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 	Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
	 	Or ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
	 			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
			  And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
	 
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
		
		QueryText = 
		"SELECT
		|	CASE WHEN &TransferOfTitleToGoods
		|		THEN &DateOfTransferOfTitleToGoods
		|		ELSE &Period
		|	END AS Period,
		|	CASE
		|		WHEN TableRevenue.IncomeByAssets
		|			THEN VALUE(Enum.BusinessTransactions.FixedAssetSale)
		|		WHEN TableRevenue.IntangibleAssetsAndRDIncome
		|			THEN VALUE(Enum.BusinessTransactions.SaleOfIntangibleAssetsAndRD)
		|		ELSE VALUE(Enum.BusinessTransactions.OtherServicesSale)
		|	END AS BusinessOperation,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|
		|	&Partner AS Partner,
		|	&Counterparty AS Counterparty,
		|	&LineOfBusiness AS CounterpartyLineOfBusiness,
		|	&Contract AS Contract,
		|	&ARAPObject AS ARAPObject,
		|	
		|	TableRevenue.IncomeItem AS IncomeAndExpenseItem,
		|	&LineOfBusiness AS LineOfBusinessItems,
		|	TableRevenue.DimensionOfRevenue AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	
		|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS Sum,
		|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVAT,
		|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS SumCompl,
		|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS LocalAmountExcludingVAT,
		|	
		|	&Currency AS Currency,
		|	TableRevenue.AmountIncludingVAT AS AmountInCurrency,
		|	TableRevenue.AmountIncludingVAT - TableRevenue.VATAmount AS AmountExcludingVATInCurrency,
		|	
		|	&ARAPCurrency AS ARAPCurrency,
		|	TableRevenue.AmountARAP AS AmountInARAPCurrency,
		|	TableRevenue.AmountARAP - CASE WHEN TableRevenue.AmountIncludingVAT <> 0 THEN
		|											CAST(TableRevenue.AmountARAP * TableRevenue.VATAmount / TableRevenue.AmountIncludingVAT AS NUMBER(31,2))
		|										ELSE
		|											0
		|										END AS AmountExcludingVATInARAPCurrency,
		|	
		|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	TableRevenue.RowID AS FinRecordID
		|FROM
		|	DocumentDataTableRevenues AS TableRevenue
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|			ON TableRevenue.Ref = DocumentData.Ref
		|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
		|			ON TableRevenue.Ref = Amounts.Ref
		|			AND TableRevenue.RowID = Amounts.RowID
		|WHERE
		|	TableRevenue.Ref IN (&Ref)
		|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.RenderRentalServices)
		|			AND TableRevenue.RentalComponentOfContract = FALSE
		|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
		|		OR &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|			AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)) 
		|"; 
	
		QueryTexts.Add(QueryText, RegisterName);
	Else
		Return "";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueriesArray = New Array;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 	Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			  And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
	
	QueryText = 
	"SELECT
	|	CASE WHEN &TransferOfTitleToGoods
	|		THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesLiabilities) AS BusinessOperation,
	|	&Organization AS Organization,
	|
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableExpenses.AssetAndLiabilityItem AS AssetRef,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	TableExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	UNDEFINED  AS FinancialAccountingGroup,
	|
	|	&Department AS DebitBusinessUnit,
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	TableExpenses.ExpenseItem AS CorItem,
	|	UNDEFINED AS CorIncomeDimension,
	|	TableExpenses.DimensionOfExpenses AS CorExpenditureDimension,
	|	UNDEFINED AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED  AS CorFinancialAccountingGroup,
	|	
	|	TableExpenses.Sum AS Sum,
	|	CASE
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			TableExpenses.Sum
	|	END AS SumMan,
	|	TableExpenses.SumCompl AS SumCompl,
	|	
	|	&Currency AS Currency,
	|	CASE &Currency
	|		WHEN &ManagementAccountingCurrency THEN TableExpenses.Sum
	|		WHEN &LocalAccountingCurrency THEN TableExpenses.SumCompl
	|		ELSE CAST(TableExpenses.SumCompl /&Rate * &Repetition AS NUMBER(31,2))
	|	END AS AmountInCurrency
	|
	|FROM
	|	DocumentDataTableExpenses AS TableExpenses
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	QueryText = StrReplace(QueryText,
		"&LineOfBusiness AS LineOfBusiness,",
		"TableExpenses.AnalyticsOfAssetsLiabilitiesLineOfBusiness AS LineOfBusiness,");
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 	Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
	 	Or ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
	 			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
			  And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
	
	QueryText =
	"SELECT
	|	CASE WHEN &TransferOfTitleToGoods
	|		THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.AssetAndLiabilityItem AS AssetRef,
	|	CASE
	|		WHEN DocumentTable.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE DocumentTable.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	
	|	DocumentTable.Sum AS Sum
	|	
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Sum <> 0
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND DocumentTable.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|		OR &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|			AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped))
	|"; 
	QueryText = StrReplace(QueryText,
		"&LineOfBusiness AS LineOfBusiness",
		"DocumentTable.AnalyticsOfAssetsLiabilitiesLineOfBusiness AS LineOfBusiness");
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	ElsIf DocumentObject.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices Then
	
		QueryText =
		"SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	&LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	DocumentAmounts_.VATAmountMan AS Sum
		|	
		|FROM
		|	DocumentDataTableRevenues AS Income
		|		INNER JOIN TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
		|		ON Income.Ref = DocumentAmounts_.Ref
		|			AND Income.RowID = DocumentAmounts_.RowID
		|
		|WHERE
		|	Income.Ref = &Ref
		|	AND DocumentAmounts_.VATAmountMan <> 0
		|";
		
		QueryTexts.Add(QueryText, RegisterName);
	Else
		Return "";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|
	|	DocumentData.CorPartner AS CorPartner,
	|	DocumentData.CorCounterparty AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusinessSVAccountOfSettlementsWithSuppliersVendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END AS CorLineOfBusiness,
	|	DocumentData.CorContract AS CorContract,
	|	DocumentData.CorARAPObject AS CorARAPObject,
	|	VALUE(Enum.TypesOfDebtAmounts.CustomerAccountsReceivable) AS AmountType,
	|	VALUE(Enum.TypesOfDebtAmounts.CustomerAccountsReceivable) AS CorAmountType,
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
	|FROM (
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		PaymentDecryptionTable.ObjectOfCalculationsDivision AS Department,
	|
	|		DocumentData.Partner AS Partner,
	|		DocumentData.Counterparty AS Counterparty,
	|		DocumentData.LineOfBusiness AS LineOfBusiness,
	|		DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP AS LineOfBusinessSIsAccountingOfVendorsARAP,
	|		DocumentData.Contract AS Contract,
	|		PaymentDecryptionTable.ARAPObjectLink AS ARAPObject,
	|
	|		UNDEFINED AS CorPartner,
	|		PaymentDecryptionTable.ARAPObjectOfCompany AS CorCounterparty,
	|		DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|		DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP AS CorLineOfBusinessSVAccountOfSettlementsWithSuppliersVendorARAP,
	|		DocumentData.Contract AS CorContract,
	|		PaymentDecryptionTable.ARAPObjectLink AS CorARAPObject,
	|	
	|		CASE WHEN DocumentData.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN PaymentDecryptionTable.AmountARAP
	|			WHEN DocumentData.Currency = &ManagementAccountingCurrency
	|				THEN PaymentDecryptionTable.Sum
	|			ELSE 
	|				CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		END AS Sum,
	|		CASE WHEN DocumentData.ARAPCurrency = &LocalAccountingCurrency
	|				THEN PaymentDecryptionTable.AmountARAP
	|			WHEN DocumentData.Currency = &LocalAccountingCurrency
	|				THEN PaymentDecryptionTable.Sum
	|			ELSE 
	|				CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		END AS SumCompl,
	|		PaymentDecryptionTable.Sum AS AmountInCurrency,
	|
	|		DocumentData.ARAPCurrency AS ARAPCurrency,
	|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
	|
	|		DocumentData.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
	|
	|		PaymentDecryptionTable.ARAPObjectLink AS SourceOfARAPFinancialAccountingGroup,
	|		PaymentDecryptionTable.ARAPObjectLink AS CorSourceOfARAPFinancialAccountingGroup
	|	FROM
	|		DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableDecryptionOfPaymentWithSettlementObjects AS PaymentDecryptionTable
	|			ON DocumentData.Ref = PaymentDecryptionTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND PaymentDecryptionTable.ARAPObjectOfCompany <> DocumentData.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
	|		PaymentDecryptionTable.ARAPObjectOfCompany AS Organization,
	|		PaymentDecryptionTable.ObjectOfCalculationsDivision AS Department,
	|
	|		UNDEFINED AS Partner,
	|		DocumentData.Organization AS Counterparty,
	|		DocumentData.LineOfBusiness AS LineOfBusiness,
	|		DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP AS LineOfBusinessSIsAccountingOfVendorsARAP,
	|		DocumentData.Contract AS Contract,
	|		PaymentDecryptionTable.ARAPObjectLink AS ARAPObject,
	|
	|		DocumentData.Partner AS CorPartner,
	|		DocumentData.Counterparty AS CorCounterparty,
	|		DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|		DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP AS CorLineOfBusinessSVAccountOfSettlementsWithSuppliersVendorARAP,
	|		DocumentData.Contract AS CorContract,
	|		PaymentDecryptionTable.ARAPObjectLink AS CorARAPObject,
	|	
	|		CASE WHEN DocumentData.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN PaymentDecryptionTable.AmountARAP
	|			WHEN DocumentData.Currency = &ManagementAccountingCurrency
	|				THEN PaymentDecryptionTable.Sum
	|			ELSE 
	|				CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		END AS Sum,
	|		CASE WHEN DocumentData.ARAPCurrency = &LocalAccountingCurrency
	|				THEN PaymentDecryptionTable.AmountARAP
	|			WHEN DocumentData.Currency = &LocalAccountingCurrency
	|				THEN PaymentDecryptionTable.Sum
	|			ELSE 
	|				CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		END AS SumCompl,
	|		PaymentDecryptionTable.Sum AS AmountInCurrency,
	|
	|		DocumentData.ARAPCurrency AS ARAPCurrency,
	|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
	|
	|		DocumentData.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
	|
	|		PaymentDecryptionTable.ARAPObjectLink AS SourceOfARAPFinancialAccountingGroup,
	|		PaymentDecryptionTable.ARAPObjectLink AS CorSourceOfARAPFinancialAccountingGroup
	|	FROM
	|		DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableDecryptionOfPaymentWithSettlementObjects AS PaymentDecryptionTable
	|			ON DocumentData.Ref = PaymentDecryptionTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND PaymentDecryptionTable.ARAPObjectOfCompany <> DocumentData.Organization
	|
	|	) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|   DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.CorPartner,
	|	DocumentData.CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusinessSVAccountOfSettlementsWithSuppliersVendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END,
	|	DocumentData.CorContract,
	|	DocumentData.CorARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
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
	|	RecordsCounterpartyCounterparty.LineOfBusiness       AS LineOfBusiness,
	|
	|	RecordsCounterpartyCounterparty.Partner                       AS Partner,
	|	RecordsCounterpartyCounterparty.Counterparty                    AS Counterparty,
	|	RecordsCounterpartyCounterparty.Contract                       AS Contract,
	|	RecordsCounterpartyCounterparty.ARAPObject                AS ARAPObject,
	|
	|	RecordsCounterpartyCounterparty.CorPartner                    AS CorPartner,
	|	RecordsCounterpartyCounterparty.CorCounterparty                 AS CorCounterparty,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness    AS CorLineOfBusiness,
	|	RecordsCounterpartyCounterparty.CorContract                    AS CorContract,
	|	RecordsCounterpartyCounterparty.CorARAPObject             AS CorARAPObject,
	|	RecordsCounterpartyCounterparty.AmountType                      AS AmountType,
	|	RecordsCounterpartyCounterparty.CorAmountType                   AS CorAmountType,
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

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 

	If Not DocumentsPosting.ThereIsQueryTable("TTTableOtherIncome", QueryTexts) Then
		QueryTextTTTableOtherIncome(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If DocumentObject <> Undefined Then
		TransferOfTitleToGoods =
			(DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
			And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped;
	Else
		TransferOfTitleToGoods = False;
	EndIf;
	
	QueriesArray = New Array;
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
	 Or TransferOfTitleToGoods Then
		  
	QueryText =
	"SELECT
	|	CASE WHEN &TransferOfTitleToGoods
	|		THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.AssetAndLiabilityItem AS AssetRef,
	|	DocumentTable.AssetsLiabilitiesDimension AS Dimension,
	|	DocumentTable.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	
	|	DocumentTable.SumCompl AS SumCompl,
	|	DocumentTable.Sum AS SumMan,
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	DocumentTable.PermanentDifference AS PermanentDifference,
	|	DocumentTable.CostTD AS CostTD,
	|	
	|	UNDEFINED AS ARAPObject,
	|	DocumentTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND DocumentTable.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|		OR &TransferOfTitleToGoods)
	|	AND (DocumentTable.Sum <> 0 OR DocumentTable.SumCompl <> 0)
	|";
	QueryText = StrReplace(QueryText,
		"&LineOfBusiness AS LineOfBusiness",
		"DocumentTable.AnalyticsOfAssetsLiabilitiesLineOfBusiness AS LineOfBusiness");
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined
	 Or ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
	 		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	 	And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	&Counterparty AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TableRevenue.VATLocal AS SumCompl,
	|	TableRevenue.AmountIncludingVATMan - TableRevenue.AmountExcludingVATMan AS SumMan,
	|	TableRevenue.AmountIncludingVATMan AS AmountIncludingVAT,
	|	TableRevenue.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	UNDEFINED AS ARAPObject,
	|	TableRevenue.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit) AS BusinessTransactionSetting
	|FROM
	|	TTTableOtherIncome AS TableRevenue
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|	AND &Status <> VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
	|";

	QueriesArray.Add(QueryText);
	
	EndIf;

	If DocumentObject = Undefined
	 Or TransferOfTitleToGoods Then
	
	QueryText =
	"SELECT
	|	&DateOfTransferOfTitleToGoods AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	&Counterparty AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TableRevenue.VATLocal AS SumCompl,
	|	TableRevenue.AmountIncludingVATMan - TableRevenue.AmountExcludingVATMan AS SumMan,
	|	TableRevenue.AmountIncludingVATMan AS AmountIncludingVAT,
	|	TableRevenue.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	&ARAPObject AS ARAPObject,
	|	TableRevenue.RowID AS FinRecordID,
	|	TableRevenue.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTableOtherIncome AS TableRevenue
	|WHERE
	|	&TransferOfTitleToGoods
	|";

	QueriesArray.Add(QueryText);
	
	EndIf;

	QueriesArray.Add(OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches(True, True));
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.CustomerInvoiceServicesAndAssets";
	SynonymForDocumentTable = "";
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		RequestHasSource = False;
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "TableOfIA";
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

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.CustomerInvoiceServicesAndAssets"));
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("ArticleAP_CF", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceTargetFinancing);
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("StartDateOfCapitalAssetsAccounting24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ValuesOfHoldingParameters.Insert("UseNonCurrentAssets2_2", GetFunctionalOption("UseNonCurrentAssets2_2"));
	ValuesOfHoldingParameters.Insert("UseNonCurrentAssets2_4", GetFunctionalOption("UseNonCurrentAssets2_4"));
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialOtherExpenses";

	QueriesArray = New Array;

	QueryText =
	"SELECT TOP 0
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	&VATTaxation AS VATActivityType,
	|	
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVATMan,
	|	DocumentTable.SumCompl AS AmountIncludingVATCompl,
	|	DocumentTable.SumCompl AS AmountExcludingVATCompl,
	|	DocumentTable.PermanentDifference AS PermanentDifference,
	|	DocumentTable.CostTD AS CostTD,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting      AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_                 AS VariancePeriod
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|";

	QueriesArray.Add(QueryText);
	If DocumentObject = Undefined 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Then
			
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	&VATTaxation AS VATActivityType,
	|	
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVATMan,
	|	DocumentTable.SumCompl AS AmountIncludingVATCompl,
	|	DocumentTable.SumCompl AS AmountExcludingVATCompl,
	|	DocumentTable.PermanentDifference AS PermanentDifference,
	|	DocumentTable.CostTD AS CostTD,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting      AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_                 AS VariancePeriod
	|
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
			
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	&VATTaxation AS VATActivityType,
	|	
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	DocumentTable.PermanentDifference AS PermanentDifference,
	|	-(DocumentTable.SumCompl - DocumentTable.CostTD) AS CostTD,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting      AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_                 AS VariancePeriod
	|	
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		 And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
			
	QueryText =
	"SELECT
	|	&DateOfTransferOfTitleToGoods AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	&VATTaxation AS VATActivityType,
	|	
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVATMan,
	|	DocumentTable.SumCompl AS AmountIncludingVATCompl,
	|	DocumentTable.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	DocumentTable.SumCompl AS CostTD,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting      AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_                 AS VariancePeriod
	|	
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|	AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableExpenses", "Document.CustomerInvoiceServicesAndAssets.Expenses");
		
	EndIf;
	
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

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
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
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	&Status                                 AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	DocumentData.Date AS Period,
	|	Income.Ref AS Ref,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Shipper AS Shipper,
	|	DocumentData.GoodsRecipient AS GoodsRecipient,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS SalesViaCommissionAgent,
	|	Income.Ref AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	CASE WHEN Income.RentalComponentOfContract
	|		THEN UNDEFINED
	|		ELSE DocumentData.ARAPObject
	|	END AS ARAPObject,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	Income.VATRate AS VATRate,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	Income.Content AS Content,
	|	Income.Count AS Count,
	|	Income.UnitOfMeasure AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	Income.FEACNCode AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	Income.LineNumber AS LineNumber,
	|	Income.RowID AS RowID,
	|	CASE WHEN Income.RentalComponentOfContract 
	|		THEN &IDARAPObject
	|		ELSE Income.RowID
	|	END AS FinRecordID,
	|	CASE
	|		WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.RenderRentalServices)
	|			THEN &BusinessTransactionSetting
	|		WHEN Income.RentalComponentOfContract
	|			THEN &BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
	|	END AS BusinessTransactionSetting
	|FROM
	|	DocumentDataTableRevenues AS Income
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON Income.Ref = DocumentData.Ref
	|WHERE
	|	Income.Ref IN (&Ref)
	|";
	
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN
		|			(DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|		OR
		|			DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
		|		ELSE DocumentDataHeader.Date
		|	END AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN
		|			(DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|		OR
		|			DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
		|		ELSE DocumentDataHeader.Date
		|	END AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
	 Or ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
	 		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		  And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) 
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices Then
		 
	TextSale = "
		|SELECT
		|	Table.Ref                                                    AS Ref,
		|	Table.Organization                                       		  AS Organization,
		|	Table.Partner                                            		  AS Partner,
		|	
		|	Table.ARAPObject                                            AS ARAPObject,
		|	Table.PaymentDate                                               AS PaymentDate,
		|	UNDEFINED                                                      AS SalesOrder_,
		|	FALSE                                                              AS InvoiceForOrders,
		|	Table.AmountARAP                                       AS AmountARAP,
		|	Table.DocumentAmount                                            AS Sum,
		|	0                                                                 AS AmountARAPByPackage,
		|	
		|	Table.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	CASE
		|		WHEN (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|							OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|						AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN Table.DateOfTransferOfTitleToGoods
		|		ELSE Table.Date
		|	END                                                             AS RecorderDate,
		|	Table.Number                                                     AS RecorderNumber,
		|	Table.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.BusinessOperation                                     AS BusinessOperation,
		|	CASE
		|		WHEN (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|							OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|						AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN Table.DateOfTransferOfTitleToGoods
		|		ELSE Table.Date
		|	END                                                             AS DateOfCourse,
		|	Table.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	FALSE                                                              AS ExceedingOrder,
		|	UNDEFINED                                                      AS LinkedDocument
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.RenderRentalServices)
		|		OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
		|		OR (Table.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|			AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)))";
	
	Else
		TextSale = "";
	EndIf;
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                    AS Ref,
		|	Table.Organization                                        		  AS Organization,
		|	Table.Partner                                            		  AS Partner,
		|	
		|	Table.ARAPObject                                            AS ARAPObject,
		|	Table.Date                                                      AS RecorderDate,
		|	Table.Number                                                     AS RecorderNumber,
		|	Table.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.Currency                                                    AS DocumentCurrency,
		|	Table.BusinessOperation                                     AS BusinessOperation,
		|	Table.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.PaymentDate                                               AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	Table.AmountARAP                                       AS AmountDue,
		|		
		|	TRUE                                                            AS ExcludeDuringControl,
		|	FALSE                                                              AS InvoiceForOrders,
		|	VALUE(Document.SalesOrder.EmptyRef)                      AS SalesOrder_,
		|	FALSE                                                              AS ExceedingOrder,
		|	UNDEFINED                                                      AS LinkedDocument
		|	
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region Sale
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
	 Or ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
	 		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		  And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) 
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices Then
		 
	TextProducts_1 = "
		|SELECT
		|	Table.Ref                                  AS Ref,
		|	Table.Organization                             AS Organization,
		|	Table.Partner                                 AS Partner,
		|	Table.Counterparty                              AS Counterparty,
		|	Table.Contract                                 AS Contract,
		|	Table.LineOfBusiness                 AS LineOfBusiness,
		|	
		|	Table.ARAPObject                          AS ARAPObject,
		|	Table.Date                                    AS DateOfShipment,
		|	CASE
		|		WHEN (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|							OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|						AND NOT Table.Status IN (
		|							VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment),
		|							VALUE(Enum.StatusesOfCustomerInvoices.Shipped))
		|			THEN Table.AmountARAP
		|		ELSE 0
		|	END                                           AS IncreaseShipping,
		|	CASE WHEN Table.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|												VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
		|												VALUE(Enum.BusinessTransactions.RenderRentalServices))
		|			OR Table.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|														VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|													AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|		THEN Table.AmountARAP
		|		ELSE 0
		|	END                                           AS ReduceShipping,
		|	Table.AmountARAP                     AS IncreaseToBeSHIPPED,
		|	Table.AmountARAP                     AS ReduceToBESHIPPED,
		|	Table.AmountARAP                     AS AmountARAP,
		|	VALUE(Document.SalesOrder.EmptyRef)    AS SalesOrder_,
		|	0                                               AS DepositForPackage,
		|	FALSE                                            AS InvoiceForOrders,
		|	FALSE                                            AS ExceedingOrder,
		|
		|	Table.ARAPObjectSettings                         AS ARAPObjectSettings,
		|	CASE
		|		WHEN (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|							OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|						AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN Table.DateOfTransferOfTitleToGoods
		|		ELSE Table.Date
		|	END                                                             AS RecorderDate,
		|	Table.Number                                                     AS RecorderNumber,
		|	Table.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.BusinessOperation                                     AS BusinessOperation,
		|	Table.Currency                                                    AS DocumentCurrency
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.RenderRentalServices)
		|		OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
		|		OR (Table.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|			AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)))";
	
	Else
		TextSale = "";
	EndIf;
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	DocumentData.Organization                                               AS Organization,
		|	DocumentData.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	DocumentData.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	DocumentData.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	DocumentData.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	DocumentData.Date                                                      AS RecorderDate,
		|	DocumentData.Number                                                     AS RecorderNumber,
		|	CASE
		|		WHEN (DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|							OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|						AND DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN DocumentData.DateOfTransferOfTitleToGoods
		|		ELSE DocumentData.Date
		|	END                                                                    AS DateOfCourse,
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|		THEN VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
		|		ELSE VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|	END                                                                    AS BusinessOperation
		|	
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|			ON Table.Ref = DocumentData.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset, TextProducts_1);
	
	#Region ImplementationIsOnWay
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                    AS Ref,
		|	Table.Organization                                        		  AS Organization,
		|	Table.Partner                                            		  AS Partner,
		|	
		|	Table.ARAPObject                                            AS ARAPObject,
		|	Table.Date                                                      AS RecorderDate,
		|	Table.Date                                                      AS DateOfShipment,
		|	Table.Number                                                     AS RecorderNumber,
		|	Table.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.Currency                                                    AS DocumentCurrency,
		|	Table.BusinessOperation                                     AS BusinessOperation,
		|	Table.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.PaymentDate                                               AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	Table.AmountARAP                                       AS AmountDue,
		|	TRUE                                                            AS ExcludeDuringControl
		|	
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND Table.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))";
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlanning);
	
EndProcedure

Procedure GetDataOfDeferredEventDocument(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref                 AS Ref,
	|	DocumentData.Date                   AS Period,
	|	DocumentData.Number                  AS Number,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	DocumentData.Comment            AS Comment,
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	DocumentData.BusinessOperation  AS BusinessOperation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.VATTaxation     AS VATTaxation,
	|	DocumentData.Status                 AS Status,
	|	DocumentData.DateOfTransferOfTitleToGoods AS DateOfTransferOfTitleToGoods,
	|	DocumentData.Currency                 AS Currency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|
	|	CASE
	|		WHEN DocumentData.CourseNumerator = 0
	|			THEN 1
	|		ELSE DocumentData.CourseNumerator
	|	END AS Rate,
	|
	|	CASE 
	|		WHEN DocumentData.CourseDenominator = 0
	|			THEN 1
	|		ELSE DocumentData.CourseDenominator
	|	END Repetition
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableExpenses
	QueryText =
	"SELECT
	|	DocumentTable.Ref                 AS Ref,
	|	DocumentTable.NonCurrentAsset      AS NonCurrentAsset,
	|	DocumentTable.NonCurrentAsset      AS FixedAsset,
	|	DocumentTable.NonCurrentAsset      AS IntangibleAsset,
	|	DocumentTable.AssetKind              AS AssetKind,
	|	DocumentTable.ExpenseItem         AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses      AS DimensionOfExpenses,
	|	DocumentTable.ReverseBonusDepreciation AS ReverseBonusDepreciation,
	|	DocumentTable.AmountOfDepreciationAllowance AS AmountOfDepreciationAllowance,
	|	DocumentTable.RowID    AS RowID
	|
	|INTO DocumentDataTableExpenses
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Expenses AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region TTDocumentPeriods
	QueryText =
	"SELECT
	|	DocumentDataDetails.Organization AS Organization,
	|	BEGINOFPERIOD(DocumentDataDetails.Period, MONTH) AS Period
	|
	|INTO TTDocumentPeriods
	|
	|FROM
	|	DocumentDataDetails AS DocumentDataDetails
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataDetails.Organization AS Organization,
	|	BEGINOFPERIOD(DocumentDataDetails.DateOfTransferOfTitleToGoods, MONTH) AS Period
	|
	|FROM
	|	DocumentDataDetails AS DocumentDataDetails
	|
	|WHERE
	|	DocumentDataDetails.DateOfTransferOfTitleToGoods <> DATETIME(1,1,1)
	|	AND BEGINOFPERIOD(DocumentDataDetails.DateOfTransferOfTitleToGoods, MONTH) <> BEGINOFPERIOD(DocumentDataDetails.Period, MONTH)
	|
	|INDEX BY
	|	Period,
	|	Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Procedure QueryTextTableOtherExpensesDeferredRegisteredRecords(Query, QueryTexts)
	
	RegisterName = "OtherExpenses";
	
	Add_Fields = "Recorder";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "DocumentDataTableExpenses");
	
	ListOfMergeRequests = New Array;
	
	#Region WriteOffOfResidualCost
	QueryText =
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	DocumentData.Organization AS Organization,
	|	NetBookValue.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	NetBookValue.ExpenseItem AS ExpenseItem,
	|	NetBookValue.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.VATTaxation AS VATActivityType,
	|	
	|	NetBookValue.Cost AS AmountIncludingVAT,
	|	NetBookValue.Cost AS AmountExcludingVAT,
	|	NetBookValue.Cost AS AmountExcludingVATMan,
	|	NetBookValue.LocalCost AS AmountIncludingVATCompl,
	|	NetBookValue.LocalCost AS AmountExcludingVATCompl,
	|	NetBookValue.CostPermanentDifference AS PermanentDifference,
	|	NetBookValue.CostTemporaryDifference AS CostTD,
	|	
	|	VALUE(Enum.BusinessTransactions.CostOfIntangibleAssetsSold) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	NetBookValue.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CostOfIntangibleAssetsSold) AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|
	|INTO TTInitialOtherExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValue AS NetBookValue
	|		ON NetBookValue.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|	AND NetBookValue.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region RestoreBonusDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	DocumentData.Organization AS Organization,
	|	FAAccountingParameters.FixedAssetsLocation AS Department,
	|	FAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses) AS ExpenseItem,
	|	FAAccountingParameters.FixedAsset AS DimensionOfExpenses,
	|	DocumentData.VATTaxation AS VATActivityType,
	|	
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	-Rows.AmountOfDepreciationAllowance AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	VALUE(Enum.BusinessTransactions.RestoreBonusDepreciation) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	Rows.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RestoreBonusDepreciation) AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|	
	|FROM
	|	DocumentDataTableExpenses AS Rows
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = Rows.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = Rows.Ref 
	|			AND FAAccountingParameters.FixedAsset = Rows.NonCurrentAsset 
	|
	|WHERE
	|	Rows.ReverseBonusDepreciation
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, "TTInitialOtherExpenses");
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, "TTOtherExpenses_");

	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableIncomeExpensesRegisteredRecordsOtherAssetsLiabilitiesDeferredRegisteredRecords(Query, QueryTexts)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	ListOfMergeRequests = New Array;
	
	#Region WriteOffOfResidualCost
	QueryText =
	"SELECT
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|
	|	VALUE(Enum.BusinessTransactions.CostOfIntangibleAssetsSold) AS BusinessOperation,
	|
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	NetBookValue.LineOfBusiness AS LineOfBusiness,
	|
	|	&Ap_nmaArticle AS AssetRef,
	|
	|	UNDEFINED                                AS DimensionOfRevenue,
	|	UNDEFINED                                AS DimensionOfExpenses,
	|	NetBookValue.NonCurrentAsset       AS AssetsLiabilitiesDimension,
	|	NetBookValue.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department               AS DebitBusinessUnit,
	|	DocumentData.LineOfBusiness     AS CorLineOfBusiness,
	|	NetBookValue.ExpenseItem          AS CorItem,
	|	UNDEFINED                                AS CorIncomeDimension,
	|	NetBookValue.DimensionOfExpenses       AS CorExpenditureDimension,
	|	UNDEFINED                                AS CorDimensionOfAssetsLiabilities,
	|	NetBookValue.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	NetBookValue.Cost               AS Sum,
	|
	|	CASE
	|		WHEN ISNULL(NetBookValue.ExpenseItem.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 		OR NOT ISNULL(BatchAccountingParameters.CompanyManagementAccounting, FALSE)
	|			THEN 0
	|		ELSE NetBookValue.Cost
	|	END AS SumMan,
	|
	|	NetBookValue.LocalCost + NetBookValue.CostTargetFinancing AS SumCompl,
	|	
	|	DocumentData.Currency AS Currency,
	|
	|	CASE 
	|		WHEN DocumentData.Currency = &ManagementAccountingCurrency 
	|			THEN NetBookValue.Cost
	|		WHEN DocumentData.Currency = DocumentData.LocalAccountingCurrency 
	|			THEN NetBookValue.LocalCost
	|		ELSE CAST(NetBookValue.LocalCost / DocumentData.Rate * DocumentData.Repetition AS NUMBER(31,2))
	|	END AS AmountInCurrency
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValue AS NetBookValue
	|		ON NetBookValue.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|	AND NetBookValue.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region RecognitionOfIncomeFromTargetedFinancing
	QueryText =
	"SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	VALUE(Enum.BusinessTransactions.FlowOfIncomeDueToAssetsLiabilities) AS BusinessOperation,
	|	DocumentData.Organization        AS Organization,
	|
	|	DocumentData.Department      AS Department,
	|	NetBookValue.LineOfBusiness AS LineOfBusiness,
	|	NetBookValue.IncomeItem  AS AssetRef,
	|	NetBookValue.DimensionOfRevenue AS DimensionOfRevenue,
	|	UNDEFINED                       AS DimensionOfExpenses,
	|	UNDEFINED                       AS AssetsLiabilitiesDimension,
	|	NetBookValue.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department      AS DebitBusinessUnit,
	|
	|	DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|
	|	&ArticleAP_CF                       AS CorItem,
	|	UNDEFINED                       AS CorIncomeDimension,
	|	UNDEFINED                       AS CorExpenditureDimension,
	|	NetBookValue.NonCurrentAsset       AS CorDimensionOfAssetsLiabilities,
	|	NetBookValue.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	0 AS Sum,
	|	0 AS SumMan,
	|	NetBookValue.CostTargetFinancing AS SumCompl,
	|	
	|	DocumentData.Currency AS Currency,
	|	0 AS AmountInCurrency
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValue AS NetBookValue
	|		ON NetBookValue.Ref = DocumentData.Ref
	|
	|WHERE
	|	NetBookValue.CostTargetFinancing <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueriesArray = New Array;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
	 	Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	FATable.NonCurrentAsset      AS FixedAsset
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableExpenses AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|			AND (FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|				OR FATable.AssetKind IS NULL)
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices Then
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	FATable.RentalObject          AS FixedAsset
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableRevenues AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RenderRentalServices)
	|	AND ISNULL(FATable.RentalComponentOfContract, FALSE)
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
	 		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.RenderRentalServices) Then
			
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	FATable.AssetsLiabilitiesDimension AS FixedAsset
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableExpenses AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UseNonCurrentAssets2_2 
	|	AND FATable.AssetsLiabilitiesDimension REFS Catalog.Assets
	|	AND FATable.AssetsLiabilitiesDimension <> VALUE(Catalog.Assets.EmptyRef)
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer),
	|		VALUE(Enum.BusinessTransactions.RenderRentalServices))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
	 		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.RenderRentalServices) Then
			
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	FATable.DimensionOfRevenue       AS FixedAsset
	|FROM
	|	DocumentDataHeader AS DocumentData
	|
	|		LEFT JOIN DocumentDataTableRevenues AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN DocumentDataTableExpenses AS TableExpenses
	|		ON FATable.Ref = TableExpenses.Ref
	|			AND FATable.DimensionOfRevenue = TableExpenses.AssetsLiabilitiesDimension
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UseNonCurrentAssets2_2 
	|	AND TableExpenses.Ref IS NULL
	|	AND FATable.DimensionOfRevenue REFS Catalog.Assets
	|	AND FATable.DimensionOfRevenue <> VALUE(Catalog.Assets.EmptyRef)
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer),
	|		VALUE(Enum.BusinessTransactions.RenderRentalServices))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableRevenues", "Document.CustomerInvoiceServicesAndAssets.Income");
		QueryText = StrReplace(QueryText, "DocumentDataTableExpenses", "Document.CustomerInvoiceServicesAndAssets.Expenses");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CustomerInvoiceServicesAndAssets");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueriesArray = New Array;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale Then
	
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	TableOfIA.NonCurrentAsset     AS IntangibleAsset
	|FROM
	|	DocumentDataHeader AS DocumentData
	|
	|		LEFT JOIN DocumentDataTableExpenses AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (TableOfIA.AssetKind IN (
	|			VALUE(Enum.KindsOfNonCurrentAssets.IA),
	|			VALUE(Enum.KindsOfNonCurrentAssets.RD))
	|		OR TableOfIA.AssetKind IS NULL)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
	 		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer) Then
			
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	TableOfIA.AssetsLiabilitiesDimension AS IntangibleAsset
	|FROM
	|	DocumentDataTableExpenses AS TableOfIA
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND &UseNonCurrentAssets2_2 
	|	AND TableOfIA.AssetsLiabilitiesDimension REFS Catalog.IntangibleAssets
	|	AND TableOfIA.AssetsLiabilitiesDimension <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.NonCurrentAssetsSale
	 		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer) Then
			
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	&Ref                          AS Ref,
	|	&Period                          AS Date,
	|	&Organization                     AS Organization,
	|	&Department                   AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	&BusinessOperation           AS BusinessOperation,
	|	&Posted                        AS Posted,
	|	TRUE                           AS RecordInLocalAccounting,
	|	TRUE                           AS RecordInManAccounting,
	|	TRUE                           AS RecordInTA,
	|	TableOfIA.DimensionOfRevenue      AS IntangibleAsset
	|FROM
	|	DocumentDataTableRevenues AS TableOfIA
	|		LEFT JOIN DocumentDataTableExpenses AS TableExpenses
	|		ON TableOfIA.Ref = TableExpenses.Ref
	|			AND TableOfIA.DimensionOfRevenue = TableExpenses.AssetsLiabilitiesDimension
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND &UseNonCurrentAssets2_2 
	|	AND TableExpenses.Ref IS NULL
	|	AND TableOfIA.DimensionOfRevenue REFS Catalog.IntangibleAssets
	|	AND TableOfIA.DimensionOfRevenue <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableRevenues", "Document.CustomerInvoiceServicesAndAssets.Income");
		QueryText = StrReplace(QueryText, "DocumentDataTableExpenses", "Document.CustomerInvoiceServicesAndAssets.Expenses");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CustomerInvoiceServicesAndAssets");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIACost(QueryTexts)
	
	RegisterName = "IACost";
	
	QueryTextTableTTResidualValue(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	
	|	VALUE(Enum.BusinessTransactions.CostOfIntangibleAssetsSold) AS BusinessOperation,
	|
	|	CostTable_.Organization             AS Organization,
	|	CostTable_.Department           AS Department,
	|	CostTable_.LineOfBusiness AS LineOfBusiness,
	|	CostTable_.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	CostTable_.NonCurrentAsset       AS IntangibleAsset,
	|	
	|	CostTable_.Cost               AS Cost,
	|	CostTable_.LocalCost           AS LocalCost,
	|	CostTable_.CostInTaxAccounting             AS CostInTaxAccounting,
	|	CostTable_.CostPermanentDifference             AS CostPermanentDifference,
	|	CostTable_.CostTemporaryDifference             AS CostTemporaryDifference,
	|	CostTable_.CostTargetFinancing             AS CostTargetFinancing,
	|	CostTable_.CostTargetFinancingTA           AS CostTargetFinancingTA,
	|	CostTable_.CostTargetFinancingPD           AS CostTargetFinancingPD,
	|	CostTable_.CostTargetFinancingTD           AS CostTargetFinancingTD,
	|
	|	CostTable_.ExpenseItem          AS CorExpenseItem,
	|	CostTable_.DimensionOfExpenses       AS CorExpenditureDimension,
	|	
	|	DocumentData.Department                           AS DebitBusinessUnit,
	|	DocumentData.LineOfBusiness                 AS CorLineOfBusiness,
	|	
	|	CostTable_.RowID     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CostOfIntangibleAssetsSold) AS BusinessTransactionSetting
	|
	|FROM
	|	TTResidualValue AS CostTable_
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = CostTable_.Ref   
	|
	|WHERE
	|	CostTable_.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTVNATable(QueryTexts)
	
	TableName = "TTVNATable";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "DocumentDataTableExpenses");
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "DocumentDataTableExpenses");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts, "DocumentDataTableExpenses");
	NonCurrentAssetsInternal.QueryTextTableTTPlaceOfIaAccounting(QueryTexts, "DocumentDataTableExpenses");
	
	QueryText = CustomerInvoiceServicesAndAssetsLocalization.QueryTextTableTTVNATable(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	TableVNA.Ref                       AS Ref,
		|	FALocation.Organization           AS Organization,
		|	FALocation.FixedAssetsLocation       AS Department,
		|	TableVNA.AssetKind                    AS AssetKind,
		|	TableVNA.NonCurrentAsset            AS NonCurrentAsset,
		|	FALSE                                    AS RealEstate,
		|
		|	AccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	AccountingProcedure.LineOfBusiness AS LineOfBusiness,
		|
		|	TableVNA.ExpenseItem AS ExpenseItem,
		|	TableVNA.DimensionOfExpenses AS DimensionOfExpenses,
		|
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	
		|	TableVNA.RowID AS RowID
		|	
		|INTO TTVNATable
		|
		|FROM
		|	DocumentDataTableExpenses AS TableVNA
		|
		|		LEFT JOIN TTAccountingFA AS AccountingProcedure
		|		ON AccountingProcedure.Ref = TableVNA.Ref 
		|			AND AccountingProcedure.FixedAsset = TableVNA.NonCurrentAsset 
		|
		|		LEFT JOIN TTLocationOfFA AS FALocation
		|		ON FALocation.Ref = TableVNA.Ref
		|			AND FALocation.FixedAsset = TableVNA.NonCurrentAsset 
		|WHERE
		|	TableVNA.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
		|
		|UNION ALL
		|
		|SELECT
		|	TableVNA.Ref                       AS Ref,
		|	IntangibleAssetsRegistrationPlace.Organization               AS Organization,
		|	IntangibleAssetsRegistrationPlace.Department             AS Department,
		|	TableVNA.AssetKind                    AS AssetKind,
		|	TableVNA.NonCurrentAsset            AS NonCurrentAsset,
		|	FALSE                                    AS RealEstate,
		|
		|	AccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	AccountingProcedure.FinancialAccountingGroup AS LineOfBusiness,
		|
		|	TableVNA.ExpenseItem AS ExpenseItem,
		|	TableVNA.DimensionOfExpenses AS DimensionOfExpenses,
		|
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	
		|	TableVNA.RowID AS RowID
		|	
		|FROM
		|	DocumentDataTableExpenses AS TableVNA
		|
		|		INNER JOIN TTAccountingProcedureForIA AS AccountingProcedure
		|		ON AccountingProcedure.Ref = TableVNA.Ref 
		|			AND AccountingProcedure.IntangibleAsset = TableVNA.NonCurrentAsset 
		|
		|		LEFT JOIN TTPlaceOfIaAccounting AS IntangibleAssetsRegistrationPlace
		|		ON IntangibleAssetsRegistrationPlace.Ref = TableVNA.Ref
		|			AND IntangibleAssetsRegistrationPlace.IntangibleAsset = TableVNA.NonCurrentAsset
		|
		|WHERE
		|	TableVNA.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|
		|INDEX BY
		|	Ref
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTResidualValue(QueryTexts)

	TableName = "TTResidualValue";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTVNATable(QueryTexts);
	
	QueryText =
	"//Write-off of residual value
	|SELECT
	|	TableVNA.Ref                    AS Ref,
	|	TableVNA.Organization               AS Organization,
	|	TableVNA.Department             AS Department,
	|	TableVNA.AssetKind                 AS AssetKind,
	|	TableVNA.NonCurrentAsset         AS NonCurrentAsset,
	|	TableVNA.RealEstate       AS RealEstate,
	|
	|	ISNULL(CostOfVNA.Cost, 0) - ISNULL(DepreciationOfVNA.Depreciation, 0)          AS Cost,
	|	ISNULL(CostOfVNA.LocalCost, 0) - ISNULL(DepreciationOfVNA.DepreciationLocal, 0)  AS LocalCost,
	|	ISNULL(CostOfVNA.CostInTaxAccounting, 0) - ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0)      AS CostInTaxAccounting,
	|	ISNULL(CostOfVNA.CostPermanentDifference, 0) - ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0)      AS CostPermanentDifference,
	|	ISNULL(CostOfVNA.CostTemporaryDifference, 0) - ISNULL(DepreciationOfVNA.DepreciationTD, 0)      AS CostTemporaryDifference,
	|	ISNULL(CostOfVNA.CostTargetFinancing, 0) - ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)      AS CostTargetFinancing,
	|	ISNULL(CostOfVNA.CostTargetFinancingTA, 0) - ISNULL(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing, 0)  AS CostTargetFinancingTA,
	|	ISNULL(CostOfVNA.CostTargetFinancingPD, 0) - ISNULL(DepreciationOfVNA.DepreciationTargetFinancingPD, 0)  AS CostTargetFinancingPD,
	|	ISNULL(CostOfVNA.CostTargetFinancingTD, 0) - ISNULL(DepreciationOfVNA.DepreciationOfTargetFinancingTD, 0)  AS CostTargetFinancingTD,
	|	
	|	TableVNA.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TableVNA.LineOfBusiness   AS LineOfBusiness,
	|	TableVNA.IncomeItem             AS IncomeItem,
	|	TableVNA.DimensionOfRevenue          AS DimensionOfRevenue,
	|	TableVNA.ExpenseItem            AS ExpenseItem,
	|	TableVNA.DimensionOfExpenses         AS DimensionOfExpenses,
	|	
	|	TableVNA.RowID       AS RowID
	|
	|INTO TTResidualValue
	|
	|FROM
	|	TTVNATable AS TableVNA
	|	
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = TableVNA.Ref 
	|			AND CostOfVNA.AccountingObject = TableVNA.NonCurrentAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = TableVNA.Ref 
	|			AND DepreciationOfVNA.AccountingObject = TableVNA.NonCurrentAsset
	|WHERE
	|	TableVNA.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|
	|	AND (ISNULL(CostOfVNA.Cost, 0) - ISNULL(DepreciationOfVNA.Depreciation, 0) > 0
	|		OR ISNULL(CostOfVNA.LocalCost, 0) - ISNULL(DepreciationOfVNA.DepreciationLocal, 0) > 0
	|		OR ISNULL(CostOfVNA.CostInTaxAccounting, 0) - ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0) > 0
	|		OR ISNULL(CostOfVNA.CostPermanentDifference, 0) - ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0) > 0
	|		OR ISNULL(CostOfVNA.CostTemporaryDifference, 0) - ISNULL(DepreciationOfVNA.DepreciationTD, 0) > 0
	|		OR ISNULL(CostOfVNA.CostTargetFinancing, 0) - ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) > 0
	|		OR ISNULL(CostOfVNA.CostTargetFinancingTA, 0) - ISNULL(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing, 0) > 0
	|		OR ISNULL(CostOfVNA.CostTargetFinancingPD, 0) - ISNULL(DepreciationOfVNA.DepreciationTargetFinancingPD, 0) > 0
	|		OR ISNULL(CostOfVNA.CostTargetFinancingTD, 0) - ISNULL(DepreciationOfVNA.DepreciationOfTargetFinancingTD, 0) > 0)
	|
	|INDEX BY
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function QueryTextTableInvestmentInRent(Query, QueryTexts, Registers)
	
	RegisterName = "InvestmentInRent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not ValueIsFilled(Query.Parameters.ContractType) Then
		Return "";
	EndIf;
	
	If Not (Query.Parameters.ContractType = PredefinedValue("Enum.ContractTypes.TransferToRental")
				Or Query.Parameters.ContractType = PredefinedValue("Enum.ContractTypes.Sublease")) Then
		Return "";
	EndIf;
	
	QueryTextOfRentalItems = 
	"// Table of vtspreditovarendy lists
	|SELECT DISTINCT
	|	&Ref AS Ref,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	SalesOfServicesOtherAssetsIncome.RentalObject AS FixedAsset
	|INTO TTListOfRentalItems
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Income AS SalesOfServicesOtherAssetsIncome
	|WHERE
	|	SalesOfServicesOtherAssetsIncome.Ref = &Ref
	|	AND SalesOfServicesOtherAssetsIncome.RentalObject <> VALUE(Catalog.Assets.EmptyRef)
	|
	|INDEX BY
	|	Organization";
	
	QueryTexts.Add(QueryTextOfRentalItems, "TTListOfRentalItems");
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters("FixedAssetsAccountingProcedure",
															"TTOrderOfAccountingOfRentalItems",
															"TTListOfRentalItems",
															QueryTexts);
	
	QueryText =
	"// The table of Registered Records of investments in leases
	|SELECT
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&Contract AS Contract,
	|	&ARAPCurrency AS Currency,
	|	SalesOfServicesOtherAssetsIncome.RentalObject AS FixedAsset,
	|	TTOrderOfAccountingOfRentalItems.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	AmountsInAccountingCurrencies.AmountExcludingVAT AS RentalPayments,
	|	AmountsInAccountingCurrencies.AmountExcludingVATCompl AS RentalPaymentsLocal,
	|	AmountsInAccountingCurrencies.AmountExcludingVATMan AS RentalPaymentsManag,
	|	0 AS NonGuaranteedResidualValueLocal,
	|	0 AS NonGuaranteedResidualValueManag,
	|	0 AS InterestDiscount,
	|	0 AS InterestDiscountMan,
	|	0 AS InterestDiscountLocal,
	|	VALUE(Catalog.BusinessTransactionsSettings.RenderRentalServices) AS BusinessTransactionSetting,
	|	&IDARAPObject AS FinRecordID,
	|	SalesOfServicesOtherAssetsIncome.RowID AS RowID
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Income AS SalesOfServicesOtherAssetsIncome
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsInAccountingCurrencies
	|		ON SalesOfServicesOtherAssetsIncome.Ref = AmountsInAccountingCurrencies.Ref
	|		AND SalesOfServicesOtherAssetsIncome.RowID = AmountsInAccountingCurrencies.RowID
	|		LEFT JOIN TTOrderOfAccountingOfRentalItems AS TTOrderOfAccountingOfRentalItems
	|		ON SalesOfServicesOtherAssetsIncome.RentalObject = TTOrderOfAccountingOfRentalItems.FixedAsset
	|WHERE
	|	SalesOfServicesOtherAssetsIncome.Ref = &Ref
	|	AND SalesOfServicesOtherAssetsIncome.RentalComponentOfContract";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If Not UserRightsCached.ThisIsPartner() Then
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ';
										|ru = 'Акт об оказании услуг';
										|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
										|it = 'Atto di prestazione dei servizi';
										|pl = 'Protokół świadczenia usług';
										|tr = 'Hizmet tutanağı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản cung cấp dịch vụ';
												|ru = 'Акт об оказании услуг';
												|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
												|it = 'Atto di prestazione dei servizi';
												|pl = 'Protokół świadczenia usług';
												|tr = 'Hizmet tutanağı'");
	EndIf;
	If Not UserRightsCached.ThisIsPartner() And Not Constants.UseInternationalPrintingForms.Get() Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Hóa đơn thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	If Constants.UseInternationalPrintingForms.Get() Then
		
		// Proforma invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceEn";
		PrintCommand.Presentation = NStr("vi = 'Proforma invoice (en)';
										|ru = 'Proforma invoice (en)';
										|en = 'Proforma invoice (en)'; fa = 'Proforma invoice (en)';
										|it = 'Proforma invoice (en)';
										|pl = 'Proforma invoice (en)';
										|tr = 'Proforma invoice (en)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;
	
	If Not UserRightsCached.ThisIsPartner() And Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Hóa đơn thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	CustomerInvoiceServicesAndAssetsLocalization.AddPrintCommands(PrintCommands);

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
	CustomerInvoiceServicesAndAssetsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

// Returns the data required for the printed form "Act of rendering services".
// 
// Parameters:
// 	PrintParameters - Structure - advanced print settings
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	
// Returns:
// 	Structure - Contains data on the header of the document, the tabular part:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataForPrintedServiceDeliveryReportForm(PrintParameters, ObjectsArray) Export
	Query = New Query("
		|// REQUEST BY HEADER
		|SELECT // documents without an intermediary
		|	SaleOfGoodsAndServices.Ref AS Ref,
		|	SaleOfGoodsAndServices.Number AS Number,
		|	SaleOfGoodsAndServices.Date AS Date,
		|	SaleOfGoodsAndServices.Partner AS Partner,
		|	SaleOfGoodsAndServices.Counterparty AS Counterparty,
		|	SaleOfGoodsAndServices.Organization AS Organization,
		|	SaleOfGoodsAndServices.Organization.Prefix AS Prefix,
		|	SaleOfGoodsAndServices.Currency AS Currency,
		|	SaleOfGoodsAndServices.PriceIncludesVAT AS PriceIncludesVAT,
		|	(CASE WHEN SaleOfGoodsAndServices.VATTaxation IN (&TaxationWithoutVAT) THEN FALSE ELSE TRUE END) AS ConsiderVAT,
		|	SaleOfGoodsAndServices.IssuiedBy AS VacationProduced
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS SaleOfGoodsAndServices
		|WHERE
		|	SaleOfGoodsAndServices.Ref IN (&DocumentsArray) AND SaleOfGoodsAndServices.Posted
		|ORDER BY
		|	Ref;
		|
		|// QUERY BY TABLE PARTS
		|SELECT
		|	SaleOfGoodsAndServices.Ref AS Ref,
		|	SaleOfGoodsAndServices.LineNumber AS LineNumber,
		|	UNDEFINED AS Products,
		|	SaleOfGoodsAndServices.Content AS ServiceNameFull,
		|	"""" AS Code,
		|	"""" AS SKU,
		|	"""" AS UnitPrice,
		|	SaleOfGoodsAndServices.UnitOfMeasure AS UnitOfMeasure,
		|	UNDEFINED AS Characteristic,
		|	"""" AS CharacteristicFullName,
		|	"""" AS PackagingName_,
		|	SaleOfGoodsAndServices.VATRate AS VATRate,
		|	SaleOfGoodsAndServices.Price AS Price,
		|	SaleOfGoodsAndServices.Count AS Count,
		|	SaleOfGoodsAndServices.Sum AS Sum,
		|	SaleOfGoodsAndServices.VATAmount AS VATAmount,
		|	0 AS DiscountPercentage,
		|	0 AS DiscountAmount,
		|	SaleOfGoodsAndServices.Sum AS AmountWithoutADiscount,
		|	FALSE AS ThisIsReusablePackage
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets.Income AS SaleOfGoodsAndServices
		|WHERE
		|	SaleOfGoodsAndServices.Ref IN (&DocumentsArray)
		|	AND SaleOfGoodsAndServices.Ref.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale))
		|ORDER BY
		|	SaleOfGoodsAndServices.Ref, SaleOfGoodsAndServices.LineNumber
		|TOTALS BY
		|	Ref
		|");

	TaxationWithoutVAT = New Array();
	TaxationWithoutVAT.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	TaxationWithoutVAT.Add(Enums.VATTaxationTypes.SaleIsSubjectToUTII);
	Query.SetParameter("TaxationWithoutVAT", TaxationWithoutVAT);
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	QueryResults = Query.ExecuteBatch();
	Return New Structure("HeaderResults, ResultForTabularPart", QueryResults[0], QueryResults[1]);
EndFunction

// Fills in the structure of recipients of printed forms.
//
// Parameters:
//	PrintObjectDataStructure - Structure - Contains:
//		* ArrayOfRecipientDetails - Array - details of the recipients
//
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	ArrayOfRecipientDetails = PrintObjectDataStructure.ArrayOfRecipientDetails;
	ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	ArrayOfRecipientDetails.Add("ContactPerson");
	ArrayOfRecipientDetails.Add("Shipper");
	ArrayOfRecipientDetails.Add("GoodsRecipient");
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	1 AS LineNumber,
	|	DocumentData.Date AS PaymentDate,
	|	100 AS PaymentPercentage,
	|	DocumentData.AmountARAP AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentData.AmountARAP > 0
	|
	|GROUP BY
	|	DocumentData.Ref
	|
	|HAVING
	|	DocumentData.AmountARAP > 0
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Income.Ref AS Ref,
	|	Income.LineNumber AS LineNumber,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS Code,
	|	UNDEFINED SKU,
	|	Income.Content AS DescriptionFull,
	|	Income.Content AS Content,
	|	CASE 
	|		WHEN &ThisIsMainLanguageOfSystem THEN
	|			PRESENTATION(Income.UnitOfMeasure)
	|		ELSE Income.UnitOfMeasure.InternationalAbbreviation
	|	END AS UnitOfMeasure,
	|	Income.Count AS Count,
	|	Income.Price AS Price,
	|	Income.Sum AS Sum,
	|	Income.VATRate AS VATRate,
	|	Income.VATAmount AS VATAmount,
	|	FALSE AS ThisIsReusablePackage,
	|	UNDEFINED AS Characteristic,
	|	UnitOfMeasure AS Package,
	|	0 AS DiscountAmount,
	|	Income.Sum AS AmountWithoutADiscount
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Income AS Income
	|WHERE
	|	Income.Ref IN(&ObjectsArray)
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
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

#Region InitializationAndFilling

Procedure FillByDefault(Object) Export
	
	Object.Author = Users.CurrentUser();
	If Not ValueIsFilled(Object.Manager) Then
		Object.Manager = Users.CurrentUser();
	EndIf;
	Object.Department = SettingsValueCached.UserDivision(Object.Manager, Object.Department);
	
	Organization = Object.Organization;
	Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	If Organization <> Object.Organization Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		Object.CompanyBankAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
EndProcedure

Procedure FillInByPartner(Object, Partner) Export
	
	If Not ValueIsFilled(Object.Partner) Or (Object.Partner <> Partner) Then
		Object.Partner = Partner;
	EndIf;
	
	SalesTermsAndConditions = SalesServer.GetDefaultSalesTerms(
		Object.Partner,
		New Structure("BusinessTransactions, SelectedAgreement", Object.BusinessOperation, Object.Terms));
	
	If ValueIsFilled(SalesTermsAndConditions) Then
		Object.Terms = SalesTermsAndConditions.Terms;
		FillInByTermsOfSales(Object, SalesTermsAndConditions);
	Else
		Object.Terms = Undefined;
		Counterparty = Object.Counterparty;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		If Counterparty <> Object.Counterparty Then
			ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
			Object.CounterpartyBankAccount =
				CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
	
EndProcedure

Procedure FillInByTermsOfSales(Object, SalesTermsAndConditions) Export
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	FillPropertyValues(Object, SalesTermsAndConditions, "Currency, PriceIncludesVAT, PaymentMethod, FinancialAccountingGroup, LineOfBusiness, ForeignCurrencyTransaction");
	Object.ARAPCurrency = SalesTermsAndConditions.ARAPCurrency;
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = SalesTermsAndConditions.BusinessOperation;
	ElsIf Not SalesTermsAndConditions.SaleWithDeferredTransferOfTitleIsAllowed Then
		If Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
			Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
			Object.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale;
		EndIf;
	EndIf;
	If ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization<>Object.Organization Then
		Object.Organization = SalesTermsAndConditions.Organization;
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	Counterparty = Object.Counterparty;
	If (Not SalesTermsAndConditions.Standard_) And ValueIsFilled(SalesTermsAndConditions.Counterparty) And SalesTermsAndConditions.Counterparty<>Object.Counterparty Then
		Object.Counterparty = SalesTermsAndConditions.Counterparty;
	EndIf;
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	If Counterparty <> Object.Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
		Object.CounterpartyBankAccount =
			CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	If (Not SalesTermsAndConditions.Standard_) And Not ValueIsFilled(Object.ContactPerson) Then
		Object.ContactPerson = SalesTermsAndConditions.ContactPerson;
	EndIf;
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
	
		Object.Contract = SalesServer.GetDefaultContract(
			Object, Object.BusinessOperation, Object.ARAPCurrency);
		
		If ValueIsFilled(Object.Contract) Then
			ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
				Object.ForeignCurrencyTransaction = ForeignCurrencyTransaction;
				Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, Object.CompanyBankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Or ValueIsFilled(SalesTermsAndConditions.Terms) Then
		Object.PaymentDate = SalesServer.GetLatestDateOnSchedule(Object.Date, SalesTermsAndConditions.PaymentSchedule, SalesTermsAndConditions.Terms);
	EndIf;
	
	Object.DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Object.Partner);
	
EndProcedure

Function FormBase(Object, IgnoreOrderOfCalculations=False) Export
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If ValueIsFilled(Object.Contract) Then
		Query = New Query(
			"SELECT ALLOWED
			|	Contracts.NameForPrinting AS Basis,
			|	Contracts.ValidityStartDate AS ReferenceDocumentDateForPrintForms,
			|	Contracts.Number AS BaseDocumentNumber
			|FROM
			|	Catalog.CounterpartyContracts AS Contracts
			|WHERE
			|	Contracts.Ref = &Ref AND (Contracts.ARAPObjectSettings = &ARAPObjectSettings OR &IgnoreOrderOfCalculations)");
		Query.SetParameter("Ref", Object.Contract);
		Query.SetParameter("ARAPObjectSettings", Enums.ARAPObjectSettings.ByCounterpartyContracts);
		Query.SetParameter("IgnoreOrderOfCalculations", IgnoreOrderOfCalculations);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
	EndIf;
	Return StructureBase;
EndFunction

Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = FormBase(Object, True);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

#EndRegion

#Region Other

#EndRegion

#EndRegion

#EndIf
