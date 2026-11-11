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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, Partner";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IncomeItem, ExpenseItem", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager, IncomeItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "IncomeItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfRevenue", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager, ExpenseItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ExpenseItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfExpenses", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);
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
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	WriteOffReportFromCommissionAgentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting (See DocumentsPosting.InitializeDocumentDataForPosting)
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.WriteOffReportFromCommissionAgent") Then
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
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);

		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		WriteOffReportFromCommissionAgentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
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
	
	Documents.CustomerCommercialInvoice.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	WriteOffReportFromCommissionAgentLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Commission agent's report on debiting".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.WriteOffReportFromCommissionAgent) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.WriteOffReportFromCommissionAgent.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.WriteOffReportFromCommissionAgent);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSalesCommission";

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
	
	Reports.StateOfSettlementsWithCommissionAgents.AddReportCommand(ReportsCommands);
	
	Reports.GoodsTransferredToCommissionAgent.AddReportCommand(ReportsCommands);
	
	WriteOffReportFromCommissionAgentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.WriteOffReportFromCommissionAgent - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.DocumentAmount AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.EndOfPeriod AS EndOfPeriod,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings
	|
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		ARAPCurrency = Selection.ARAPCurrency;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		BeginOfPeriod = Selection.BeginOfPeriod;
		EndOfPeriod = Selection.EndOfPeriod;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		BeginOfPeriod = Undefined;
		EndOfPeriod = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.WriteOffReportFromCommissionAgent);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("BeginOfPeriod", BeginOfPeriod);
	AttributesStructure1.Insert("EndOfPeriod", EndOfPeriod);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.ConsignmentReportFromCustomer - the document to generate parameters for.
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
	FillParameters.ConsignmentReportFromCustomer = True;
	
	Return FillParameters;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
							|ru = 'Отчет комиссионера';
							|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
							|it = 'Report del commissionario';
							|pl = 'Raport komisanta';
							|tr = 'Konsinye satışlar'"));
	ConsignmentReportFromCustomerLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return WriteOffReportFromCommissionAgentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return WriteOffReportFromCommissionAgentLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction


Function DefaultBusinessTransaction() Export
	
	Return PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - Optional, business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation = Undefined) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
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
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	
	ParametersStructure.Manager                         = "Object.Manager";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.FormItems.PaymentSettlement        = "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

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

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "WriteOffReportFromCommissionAgent");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Partner                    AS Partner,
	|	DocumentData.Counterparty                 AS Counterparty,
	|	DocumentData.Date                       AS Period,
	|	DocumentData.Number                      AS Number,
	|	DocumentData.PaymentDate                AS PaymentDate,
	|	DocumentData.Currency                     AS Currency,
	|	DocumentData.Manager                   AS Manager,
	|	DocumentData.Author                      AS Author,
	|	DocumentData.Department              AS Department,
	|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.VATTaxation         AS VATTaxation,
	|	DocumentData.Terms                 AS Terms,
	|	DocumentData.IncomeItem              AS IncomeItem,
	|	DocumentData.DimensionOfRevenue           AS DimensionOfRevenue,
	|	DocumentData.ExpenseItem             AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses          AS DimensionOfExpenses,
	|	DocumentData.Contract                    AS Contract,
	|		
	|	CASE WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|		OR DocumentData.EndOfPeriod > DocumentData.Date
	|		OR BEGINOFPERIOD(DocumentData.EndOfPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN DocumentData.Date
	|		ELSE
	|			DocumentData.EndOfPeriod
	|	END                                      AS EndOfPeriod,
	|		
	|	DocumentData.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	DocumentData.Comment                AS Comment,
	|	DocumentData.Patch                AS Patch,
	|	DocumentData.ReversedDocument       AS ReversedDocument,
	|	DocumentData.CorrectedDocument       AS CorrectedDocument,
	|	DocumentData.LineOfBusiness    AS LineOfBusiness,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	UNDEFINED AS AdjustmentPeriod_
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("EndOfPeriod",           			EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("ARAPCurrency",   			Attributes.Currency);
	
	Query.SetParameter("ManagementAccountingCurrency",				Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("BusinessOperation",					Enums.BusinessTransactions.WriteOffReportFromCommissionAgent);
	Query.SetParameter("BusinessTransactionSetting",			Catalogs.BusinessTransactionsSettings.WriteOffReportFromCommissionAgent);
	Query.SetParameter("IDOfUnusedFinRecord",	DocumentsPosting.IDOfUnusedFinRecord());
	
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses",
		GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	
	Query.SetParameter("LineOfBusiness", Attributes.LineOfBusiness);	
	Query.SetParameter("Comment",						Attributes.Comment);
	Query.SetParameter("Patch",						Attributes.Patch);
	Query.SetParameter("ReversedDocument",				Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",				Attributes.CorrectedDocument);
	Query.SetParameter("MetadataIdentifier",			Common.MetadataObjectID(
		EmptyRef().Metadata().FullName()));	
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
		|	&EndOfPeriod                                 AS Period,
		|	&Organization                                  AS Organization,
		|	&Partner                                      AS Partner,
		|	&Terms                                   AS Terms,
		|	TableTypesOfStocks_.Products               AS Products,
		|	TableTypesOfStocks_.Characteristic             AS Characteristic,
		|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
		|	TableTypesOfStocks_.Count                 AS Count,
		|	CASE
		|		WHEN &UseTraceableImportedGoodsAccounting
		|				AND BEGINOFPERIOD(&Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
		|			THEN TableTypesOfStocks_.QuantityByGBRN
		|		ELSE 0
		|	END AS QuantityByGBRN,
		|	0                                             AS RevenueAmount,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	&VATTaxation                           AS VATTaxation
		|FROM
		|	TTTypesOfStocks AS TableTypesOfStocks_";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period									AS Period,
	|	&Organization AS Organization,
	|	Rows.Currency							AS Currency,
	|	Rows.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	Rows.CommitteeProductAnalysis	AS ItemsLocationAttributes,
	|	Rows.Products						AS Products,
	|	Rows.Characteristic					AS Characteristic,
	|	Rows.CCDNumber							AS CCDNumber,
	|	&BusinessOperation					AS BusinessOperation,
	|	0										AS RevenueAmount,
	|	0										AS RevenueAmountExclVATLocal,
	|	0										AS RevenueAmountMan,
	|	Rows.Count						AS QuantityConsumed,
	|	Rows.Count						AS QuantityConsumedForIncoiceRegistration,
	|	Rows.QuantityByGBRN					AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&IDARAPObject			AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting,
	|	Rows.RowID				AS RowID
	|FROM
	|	TTTypesOfStocks AS Rows
	|WHERE
	|	Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
		"SELECT
		|	&Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.IncomeItem AS IncomeItem,
		|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
		|	&BusinessOperation AS BusinessOperation,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	(CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|		ELSE 0 END) AS SumMan,
		|	(CASE
		|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
		|			THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
		|		ELSE 0 END) AS SumCompl,
		|	
		|	&IDARAPObject AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.IncomeAccordingToWriteOffReportFromCommissionAgent) AS BusinessTransactionSetting
		|	
		|FROM
		|	Document.WriteOffReportFromCommissionAgent AS DocumentData
		|	
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND DocumentData.DocumentAmount <> 0
		|	AND &UseAccountingOfOtherIncomeExpenses";
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|
		|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
		|	&Partner AS Warehouse,
		|	GoodsTable.InventoryType AS InventoryType,
		|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	&LineOfBusiness AS LineOfBusinessItems,
		|	&ExpenseItem AS IncomeAndExpenseItem,
		|	&DimensionOfExpenses AS DimensionOfExpenses,
		|
		|	GoodsTable.Count AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost,
		|
		|	GoodsTable.InventoryOwnerAttribute AS SourceOfProductFinancialAccountingGroup
		|
		|FROM
		|	TTTypesOfStocks AS GoodsTable";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
		"SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.IncomeAccordingToWriteOffReportFromCommissionAgent) AS BusinessOperation,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	
		|	&Partner AS Partner,
		|	&Counterparty AS Counterparty,
		|	&Contract AS Contract,
		|	DocumentData.ARAPObject AS ARAPObject,
		|	&LineOfBusiness AS CounterpartyLineOfBusiness,
		|	
		|	&LineOfBusiness AS LineOfBusinessItems,
		|	DocumentData.IncomeItem AS IncomeAndExpenseItem,
		|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	0 AS AmountExcludingVAT,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	0 AS LocalAmountExcludingVAT,
		|	
		|	&Currency AS Currency,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	0 AS AmountExcludingVATInCurrency,
		|	
		|	&Currency AS ARAPCurrency,
		|	DocumentData.DocumentAmount AS AmountInARAPCurrency,
		|	0 AS AmountExcludingVATInARAPCurrency,
		|	
		|	DocumentData.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	&IDARAPObject AS FinRecordID
		|FROM
		|	Document.WriteOffReportFromCommissionAgent AS DocumentData
		|	
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND DocumentData.DocumentAmount <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountIncludingVAT AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.WriteOffReportFromCommissionAgent.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function TemporaryTableQueryTextInventoryTypes(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText =
		"SELECT DISTINCT
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CommitteeAnalytics.DimensionKey AS CommitteeProductAnalysis,
		|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
		|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
		|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS Currency,
		|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
		|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS GoodsOwner,
		|	TableTypesOfStocks_.Count AS Count,
		|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
		|	TableTypesOfStocks_.VATRate AS VATRate,
		|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
		|	TableTypesOfStocks_.VATAmount AS VATAmount,
		|	TableTypesOfStocks_.RowID AS RowID
		|
		|INTO TTTypesOfStocks
		|FROM
		|	Document.WriteOffReportFromCommissionAgent.InventoryKinds AS TableTypesOfStocks_
		|	LEFT JOIN
		|		InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
		|	ON
		|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeAnalytics.StorageLocation
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeAnalytics.Products
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommitteeAnalytics.Characteristic
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = CommitteeAnalytics.Purpose
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = CommitteeAnalytics.Series
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
		|WHERE
		|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
		|SELECT
		|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
		|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
		|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
		|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series
		|FROM
		|	Document.WriteOffReportFromCommissionAgent.InventoryKinds AS TableTypesOfStocks_
		|	LEFT JOIN
		|		InformationRegister.ItemsLocationAttributes AS Keys
		|	ON
		|		TableTypesOfStocks_.ItemsLocationAttributes.Products = Keys.Products
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = Keys.Characteristic
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = Keys.Purpose
		|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = Keys.Series
		|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = Keys.StorageLocation
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
		|WHERE
		|	TableTypesOfStocks_.Ref = &Ref
		|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|	AND Keys.Products IS NULL");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
					Query.Parameters.Currency, Query.Parameters.Currency, Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_ AS VariancePeriod
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
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
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.WriteOffReportFromCommissionAgent AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.WriteOffReportFromCommissionAgent.ARAPDetails AS Table
		|		LEFT JOIN Document.WriteOffReportFromCommissionAgent AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.PaymentDate                                               AS PaymentDate,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	Table.AmountIncludingVAT                                                        AS AmountARAP,
		|	0	                                                                     AS AmountARAPByPackage,
		|	Table.AmountIncludingVAT                                                        AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.WriteOffReportFromCommissionAgent)  AS BusinessOperation,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)        AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.WriteOffReportFromCommissionAgent.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.WriteOffReportFromCommissionAgent)  AS BusinessOperation,
		|	UNDEFINED                                                             AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate                                               AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)        AS PaymentOption,
		|	Table.AmountIncludingVAT                                                        AS AmountDue,
		|		
		|	TRUE                                                                   AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.WriteOffReportFromCommissionAgent.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.WriteOffReportFromCommissionAgent.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	AdditionalTables.Add("TTOtherExpenses_");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region WriteOffForExpensesAssets_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	&EndOfPeriod 			AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.VATTaxation				AS VATActivityType,
	|	DocumentTable.VATTaxation				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, UNDEFINED) AS CorCompany,
	|	UNDEFINED 								    			AS CorItemsLocationAttributes,
	|	UNDEFINED				  				    			AS CorInventoryOwnerAttribute,
	|	DocumentTable.ExpenseItem 			    			AS ExpenseItemAssets,
	|	DocumentTable.DimensionOfExpenses			    			AS AssetExpenseAnalytics,
	|	DocumentTable.LineOfBusiness	    			AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.WriteOffReportFromCommissionAgent) AS BusinessOperation,
	|	UNDEFINED	 														AS RowID,
	|	TableTypesOfStocks_.RowID 						 			AS FinRecordID,
	|	&BusinessTransactionSetting								 			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN TTOtherExpenses_ AS OtherExpenses
	|		ON OtherExpenses.ExpenseItem = &ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = &DimensionOfExpenses
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN
	|		(VALUE(Enum.InventoryTypes.OwnGoods),
	|		 VALUE(Enum.InventoryTypes.ConsignedGoods))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Commission agent's report on write-offs
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
	PrintCommand.Id = "CommissionAgentSReportWriteOff";
	PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng hóa ghi giảm của người nhận ký gửi';
									|ru = 'Отчет комиссионера о списании';
									|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
									|it = 'Report del commissionario sullo storno';
									|pl = 'Raport komisanta ze spisania';
									|tr = 'Konsinye stok düzeltme raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Bảng kê hàng hóa ghi giảm của người nhận ký gửi';
											|ru = 'Отчет комиссионера о списании';
											|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
											|it = 'Report del commissionario sullo storno';
											|pl = 'Raport komisanta ze spisania';
											|tr = 'Konsinye stok düzeltme raporu'");

	WriteOffReportFromCommissionAgentLocalization.AddPrintCommands(PrintCommands);

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
	ConsignmentReportFromCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

// Returns data for the formation of a printed form "Report on the commission on the write-off".
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array of DocumentRef.WriteOffReportFromCommissionAgent - links to documents for which you need
//																			to get data.
//
// Returns:
//	Structure - a collection of data used when printing the UPD, containing the following properties:
//		* Title - String - Report header.
//		* HeaderResults - QueryResult - general data of the document.
//		* ResultForTabularPart - QueryResult - data of the tabular part of the document.
//		* DocumentTraceabilityData - ValueTable - a table containing information about the traceability of the document, with the following columns:
//			** Ref - DocumentRef.WriteOffReportFromCommissionAgent - link to the document.
//			** ThereIsRNPT - Boolean - indicates that the document contains traceability information.
//		* TraceableComponents - ValueTable - - description of the table of information on traceable components, with the following columns:
//			** CCDNumber - CatalogRef.CCDNumbers - link to the RPT number of the kit.
//			** ProductBatchIDNumber - String - product registration number.
//			** QuantityByGBRN - Number - the standard number of components per unit of the kit.
//			** FEACNUnitOfMeasure - String - name of the unit of measurement.
//
Function GetDataForPrintedFormCommissionReportOnDebiting(PrintParameters, ObjectsArray) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref					AS Ref,
	|	DocumentData.Number					AS Number,
	|	DocumentData.Date					AS Date,
	|	DocumentData.Counterparty				AS Consignee,
	|	DocumentData.Organization				AS Consignor,
	|	DocumentData.Organization.Prefix		AS Prefix,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.Manager.Individual	AS CommitteeRepresentative,
	|	""""									AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	NestedQuery.Ref												AS Ref,
	|	MAX(NestedQuery.LineNumber)								AS LineNumber,
	|	NestedQuery.Products										AS Products,
	|	NestedQuery.Products.DescriptionFull						AS ProductItemName,
	|	NestedQuery.Products.Code									AS Code,
	|	NestedQuery.Products.SKU								AS SKU,
	|	NestedQuery.Products.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull					AS Characteristic,
	|	NestedQuery.UnitOfMeasure.Presentation						AS UnitOfMeasurementName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END																AS Package,
	|	SUM(NestedQuery.Count)									AS Count,
	|	SUM(NestedQuery.QuantityByGBRN)								AS QuantityByGBRN,
	|	NestedQuery.Price												AS Price,
	|	SUM(NestedQuery.Sum)										AS Sum,
	|	NestedQuery.CCDNumber											AS CCDNumber,
	|	NestedQuery.CCDNumber.CCDNumberType								AS CCDNumberType,
	|	NestedQuery.CCDNumber.Presentation								AS ProductBatchIDNumber
	|FROM
	|	(SELECT
	|		GoodsTable.Ref						AS Ref,
	|		GoodsTable.LineNumber					AS LineNumber,
	|		GoodsTable.Products					AS Products,
	|		CASE
	|			WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsTable.Products.UnitOfMeasure
	|			ELSE GoodsTable.Package
	|		END										AS UnitOfMeasure,
	|		GoodsTable.Characteristic				AS Characteristic,
	|		GoodsTable.Package						AS Package,
	|		GoodsTable.NumberOfPackages			AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsTable.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE GoodsTable.QuantityByGBRN
	|		END										AS QuantityByGBRN,
	|		GoodsTable.Price							AS Price,
	|		GoodsTable.AmountIncludingVAT						AS Sum,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsTable.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE GoodsTable.CCDNumber
	|		END										AS CCDNumber
	|	FROM
	|		Document.WriteOffReportFromCommissionAgent.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|		AND GoodsTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|														VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.UnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.Price,
	|	NestedQuery.CCDNumber
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.Ref	AS Ref,
	|	MAX(CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(Goods.Ref.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				AND ISNULL(Goods.Ref.Terms.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|				AND ISNULL(Goods.CCDNumber.CCDNumberType, UNDEFINED) IN(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|																		VALUE(Enum.CCDNumberTypes.KitRNPT))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)			AS ThereIsRNPT
	|FROM
	|	Document.WriteOffReportFromCommissionAgent.InventoryKinds AS Goods
	|
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	Goods.Ref
	|
	|ORDER BY
	|	Goods.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	DocumentTable.CCDNumber							AS CCDNumber,
	|	CASE
	|		WHEN Components.ProductBatchIDNumber.RegistrationNumber = """"
	|			THEN Components.ProductBatchIDNumber
	|		ELSE Components.ProductBatchIDNumber.RegistrationNumber
	|	END												AS ProductBatchIDNumber,
	|	Components.QuantityByGBRN						AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure
	|FROM
	|	Document.WriteOffReportFromCommissionAgent.Goods AS DocumentTable
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON DocumentTable.CCDNumber = Components.Ref";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"NestedQuery.Package",
									"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Title = NStr("vi = 'Bảng kê hàng hóa ghi giảm của người nhận ký gửi';
				|ru = 'Отчет комиссионера о списании';
				|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
				|it = 'Report del commissionario sullo storno';
				|pl = 'Raport komisanta ze spisania';
				|tr = 'Konsinye stok düzeltme raporu'", Common.DefaultLanguageCode());
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderResults					= ResultsArray[0]; // QueryResult - 
	ResultForTabularPart			= ResultsArray[1]; // QueryResult - 
	DocumentTraceabilityData	= ResultsArray[2].Unload(); // ValueTable - 
	TraceableComponents			= ResultsArray[3].Unload(); // ValueTable - 
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("Title",							Title);
	DataStructureForPrinting.Insert("HeaderResults",					HeaderResults);
	DataStructureForPrinting.Insert("ResultForTabularPart",			ResultForTabularPart);
	DataStructureForPrinting.Insert("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataStructureForPrinting.Insert("TraceableComponents",		TraceableComponents);
	
	Return DataStructureForPrinting;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	
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

#Region Posting

#EndRegion

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)

	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	UNDEFINED AS BusinessOperation,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Department AS Department,
	|	&Comment AS Comment,
	|	&Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum,
	|	&Manager AS EmployeeResponsible,
	|	&Author AS Author,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&Number AS SourceDocumentNumber,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;

	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
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
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			,);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
