#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	VATWritingOffAsExpensesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.VATWritingOffAsExpenses") Then
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
		
		QueryTextTableVATInvoiced(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableVATPrepaymentsFromCustomer(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		VATWritingOffAsExpensesLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	VATWritingOffAsExpensesLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	VATWritingOffAsExpensesLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Fills in the table part of the Value with the selection based on the details of the document header.
//
// Parameters:
//   DocumentObject - DocumentObject.VATWritingOffAsExpenses - Reference to the document object.
//
Procedure FillInValueTable(DocumentObject) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|	VATInvoiced.VATActivityType AS VATActivityType,
	|	VATInvoiced.SaleExport AS SaleExport,
	|	VATInvoiced.LineOfBusiness AS LineOfBusiness,
	|	VATInvoiced.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATInvoiced.AmountExcludingVATBalance AS AmountExcludingVAT,
	|	VATInvoiced.VATBalance AS VAT,
	|	VATInvoiced.VATManagBalance AS VATManag
	|FROM
	|	AccumulationRegister.VATInvoiced.Balance(
	|		&Period,
	|		Organization = &Organization 
	|		AND TaxInvoice = &TaxInvoice 
	|		AND Vendor = &Vendor) AS VATInvoiced
	|";
	
	Query.SetParameter("Period",      New Boundary(DocumentObject.Date, BoundaryType.Including));
	Query.SetParameter("Organization", DocumentObject.Organization);
	Query.SetParameter("Vendor",   DocumentObject.Counterparty);
	Query.SetParameter("TaxInvoice", DocumentObject.TaxInvoice);
	
	Selection = Query.Execute().Select(QueryResultIteration.Linear);
	While Selection.Next() Do
		
		NewRow = DocumentObject.Assets_.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo; 
	
EndProcedure

// Fills in the table part of the advance payment Received with the selection of the document header details.
//
// Parameters:
//   DocumentObject - DocumentObject.VATWritingOffAsExpenses - Reference to the document object.
//
Procedure FillInTableAdvancesReceived(DocumentObject) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VATPrepaymentsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VATPrepaymentsFromCustomer.ARAPObject AS ARAPObject,
	|	VATPrepaymentsFromCustomer.CorrectedTaxInvoice AS CorrectedTaxInvoice,
	|	VATPrepaymentsFromCustomer.Department AS Department,
	|	VATPrepaymentsFromCustomer.VATRate AS VATRate,
	|	VATPrepaymentsFromCustomer.AmountExcludingVATBalance AS AmountExcludingVAT,
	|	VATPrepaymentsFromCustomer.VATBalance AS VAT,
	|	VATPrepaymentsFromCustomer.VATManagBalance AS VATManag
	|FROM
	|	AccumulationRegister.VATPrepaymentsFromCustomer.Balance(
	|		&Period,
	|		Organization = &Organization 
	|		AND DocumentPayments = &DocumentPayments 
	|		AND Counterparty = &Counterparty) AS VATPrepaymentsFromCustomer
	|";
	
	Query.SetParameter("Period",         New Boundary(DocumentObject.Date, BoundaryType.Including));
	Query.SetParameter("Organization",    DocumentObject.Organization);
	Query.SetParameter("Counterparty",     DocumentObject.Counterparty);
	Query.SetParameter("DocumentPayments", DocumentObject.DocumentPayments);
	
	Selection = Query.Execute().Select(QueryResultIteration.Linear);
	While Selection.Next() Do
		
		NewRow = DocumentObject.PrepaymentsFromCustomer.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo; 
	
EndProcedure

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request.
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return VATWritingOffAsExpensesLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables used for reflection.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return VATWritingOffAsExpensesLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

// Returns parameters for selecting articles in the document.
// 
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns the accounting account settings.
//  
// Returns:
//	See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.GLAccountSettings = "GLAccountSettings";
	SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
	Return SetupParameters;
	
EndFunction

#Region InterfaceImplementation

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.VATWritingOffAsExpenses);
	
EndFunction

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	VATWritingOffAsExpenses.Ref,
	|	VATWritingOffAsExpenses.DeletionMark,
	|	VATWritingOffAsExpenses.Number,
	|	VATWritingOffAsExpenses.Date,
	|	VATWritingOffAsExpenses.Posted,
	|	VATWritingOffAsExpenses.BusinessOperation,
	|	VATWritingOffAsExpenses.Organization,
	|	VATWritingOffAsExpenses.Counterparty,
	|	VATWritingOffAsExpenses.TaxInvoice,
	|	VATWritingOffAsExpenses.DocumentPayments,
	|	VATWritingOffAsExpenses.ExpenseItem,
	|	VATWritingOffAsExpenses.Department,
	|	VATWritingOffAsExpenses.DimensionOfExpenses,
	|	VATWritingOffAsExpenses.Comment,
	|	VATWritingOffAsExpenses.AmountExcludingVAT,
	|	VATWritingOffAsExpenses.Patch,
	|	VATWritingOffAsExpenses.ReversedDocument,
	|	VATWritingOffAsExpenses.CorrectedDocument,
	|	VATWritingOffAsExpenses.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	VATWritingOffAsExpenses.VATAmount
	|FROM
	|	Document.VATWritingOffAsExpenses AS VATWritingOffAsExpenses
	|WHERE
	|	VATWritingOffAsExpenses.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                     Attributes.Date);
	Query.SetParameter("AdjustmentPeriod_",        Attributes.AdjustmentPeriod_);
	Query.SetParameter("Organization",                Attributes.Organization);
	Query.SetParameter("Counterparty",                 Attributes.Counterparty);
	Query.SetParameter("TaxInvoice",                Attributes.TaxInvoice);
	Query.SetParameter("BusinessOperation",      Attributes.BusinessOperation);
	Query.SetParameter("DocumentPayments",             Attributes.DocumentPayments);
	Query.SetParameter("Number",                      Attributes.Number);
	Query.SetParameter("Posted",                   Attributes.Posted);
	Query.SetParameter("Patch",                Attributes.Patch);
	Query.SetParameter("ReversedDocument",       Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",       Attributes.CorrectedDocument);
	Query.SetParameter("Comment",                Attributes.Comment);
	Query.SetParameter("VATAmount",                   Attributes.VATAmount);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", 	GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID(
		EmptyRef().Metadata().FullName()));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableVATInvoiced(Query, QueryTexts, Registers)
	
	RegisterName = "VATInvoiced";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	VATAccountingERPInternal.SetParameterTypesOfTaxationVATReceipts(Query);
	
	QueryText = "
	|
	|SELECT
	|	&Ref                                AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Operation.Date                          AS Period,
	|	Operation.Organization                   AS Organization,
	|	Operation.TaxInvoice                   AS TaxInvoice,
	|	Operation.Counterparty                    AS Vendor,
	|	Rows.AssetTaxClass                     AS AssetTaxClass,
	|	Rows.VATRate                       AS VATRate,
	|	Rows.VATActivityType              AS VATActivityType,
	|	Rows.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	Rows.SaleExport               AS SaleExport,
	|	Rows.LineOfBusiness         AS LineOfBusiness,
	|	Rows.LineOfBusiness         AS CorLineOfBusiness,
	|	Rows.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	Rows.VAT                             AS VAT,
	|	Rows.VATManag                          AS VATManag,
	|	VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses) AS Event,
	|	UNDEFINED                           AS CorVATActivityTypes,
	|	Operation.Department                 AS Department,
	|	Operation.ExpenseItem                AS ExpenseItem,
	|	Operation.DimensionOfExpenses             AS DimensionOfExpenses,
	|	""""                                     AS RowID,
	|	FALSE                                   AS PeriodEndTransaction,
	|	Rows.RowID             AS FinRecordID,
	|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting
	|FROM
	|	Document.VATWritingOffAsExpenses AS Operation
	|	
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses.Assets_ AS Rows
	|	ON
	|		Rows.Ref = Operation.Ref
	|
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		Operation.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	Operation.Ref = &Ref
	|	AND Operation.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (Rows.VAT <> 0 OR Rows.VATManag <> 0)
	|	
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	&VATAmount AS Sum,
	|	&Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&Number AS SourceDocumentNumber,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate
	|FROM
	|	Document.VATWritingOffAsExpenses AS DocumentData
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
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,,);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function QueryTextTableVATPrepaymentsFromCustomer(Query, QueryTexts, Registers)
	
	RegisterName = "VATPrepaymentsFromCustomer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|
	|SELECT
	|	&Ref                                AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Operation.Date                          AS Period,
	|	Operation.Organization                   AS Organization,
	|	Operation.DocumentPayments                AS DocumentPayments,
	|	Operation.Counterparty                    AS Counterparty,
	|	Rows.CorrectedTaxInvoice         AS CorrectedTaxInvoice,
	|	Rows.Department                   AS Department,
	|	Rows.LineOfBusiness         AS LineOfBusiness,
	|	Rows.ARAPObject                  AS ARAPObject,
	|	Rows.VATRate                       AS VATRate,
	|	Rows.AmountExcludingVAT                     AS AmountExcludingVAT,
	|	Rows.VAT                             AS VAT,
	|	Rows.VATManag                          AS VATManag,
	|	VALUE(Enum.EventsVATFromPrepayments.WriteOffVATFromPrepaymentFromCustomer) AS Event,
	|	UNDEFINED                           AS PrepaymentsSettlementDocument,
	|	FALSE                                   AS PeriodEndTransaction,
	|	Rows.RowID             AS FinRecordID,
	|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting,
	|	FALSE                                   AS ReversingEntry
	|FROM
	|	Document.VATWritingOffAsExpenses AS Operation
	|	
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses.PrepaymentsFromCustomer AS Rows
	|	ON
	|		Rows.Ref = Operation.Ref
	|
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		Operation.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|	
	|WHERE
	|	Operation.Ref IN (&Ref)
	|	AND Operation.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (Rows.VAT <> 0 OR Rows.VATManag <> 0)
	|	
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	Operation.Date                                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	&AdjustmentPeriod_                              AS VariancePeriod,
	|	Operation.Organization                              AS Organization,
	|	Operation.Department                            AS Department,
	|	ValueTable_.LineOfBusiness           AS LineOfBusiness,
	|	Operation.ExpenseItem                           AS ExpenseItem,
	|	Operation.DimensionOfExpenses                        AS DimensionOfExpenses,
	|
	|	0                                                 AS Sum,
	|	0                                                 AS AmountExcludingVAT,
	|	ValueTable_.VAT                               AS SumCompl,
	|	ValueTable_.VATManag                            AS SumMan,
	|	CASE 
	|		WHEN NOT ARTICLES__.EnteredInTaxAccounting THEN
	|			ValueTable_.VAT 
	|		ELSE
	|			0
	|	END                                             AS PermanentDifference,
	|	0                                                 AS CostTD,
	|	
	|	Operation.BusinessOperation                    AS BusinessOperation,
	|	ValueTable_.RowID               AS FinRecordID,
	|	BusinessTransactionsSettings.Ref             AS BusinessTransactionSetting
	|FROM
	|	Document.VATWritingOffAsExpenses AS Operation
	|
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses.Assets_ AS ValueTable_
	|	ON 
	|		Operation.Ref = ValueTable_.Ref
	|	
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|	ON 
	|		Operation.ExpenseItem = ARTICLES__.Ref
	|	
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		Operation.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	Operation.Ref IN (&Ref)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND Operation.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|
	|UNION ALL
	|
	|SELECT
	|	Operation.Date                                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	&AdjustmentPeriod_                              AS VariancePeriod,
	|	Operation.Organization                              AS Organization,
	|	Operation.Department                            AS Department,
	|	TableAdvancesReceived.LineOfBusiness   AS LineOfBusiness,
	|	Operation.ExpenseItem                           AS ExpenseItem,
	|	Operation.DimensionOfExpenses                        AS DimensionOfExpenses,
	|
	|	0                                                 AS Sum,
	|	0                                                 AS AmountExcludingVAT,
	|	TableAdvancesReceived.VAT                       AS SumCompl,
	|	TableAdvancesReceived.VATManag                    AS SumMan,
	|	CASE 
	|		WHEN NOT ARTICLES__.EnteredInTaxAccounting THEN
	|			TableAdvancesReceived.VAT 
	|		ELSE
	|			0
	|	END                                             AS PermanentDifference,
	|	0                                                 AS CostTD,
	|	
	|	Operation.BusinessOperation                    AS BusinessOperation,
	|	TableAdvancesReceived.RowID       AS FinRecordID,
	|	BusinessTransactionsSettings.Ref             AS BusinessTransactionSetting
	|FROM
	|	Document.VATWritingOffAsExpenses AS Operation
	|
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses.PrepaymentsFromCustomer AS TableAdvancesReceived
	|	ON 
	|		Operation.Ref = TableAdvancesReceived.Ref
	|	
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|	ON 
	|		Operation.ExpenseItem = ARTICLES__.Ref
	|	
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		Operation.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	Operation.Ref IN (&Ref)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND Operation.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	Operation.Date                                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	Operation.Organization                              AS Organization,
	|	Operation.Department                            AS Department,
	|	ValueTable_.LineOfBusiness           AS LineOfBusiness,
	|	Operation.ExpenseItem                           AS AssetRef,
	|	Operation.AssetsLiabilitiesDimension                 AS Dimension,
	|	Operation.GLAccountSettings                     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	0                                                 AS AmountIncludingVAT,
	|	0                                                 AS AmountExcludingVAT,
	|	ValueTable_.VAT                               AS SumCompl,
	|	ValueTable_.VATManag                            AS SumMan,
	|	ValueTable_.VAT                               AS PermanentDifference,
	|	
	|	ValueTable_.RowID               AS FinRecordID,
	|	BusinessTransactionsSettings.Ref             AS BusinessTransactionSetting
	|FROM
	|	Document.VATWritingOffAsExpenses AS Operation
	|
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses.Assets_ AS ValueTable_
	|	ON 
	|		Operation.Ref = ValueTable_.Ref
	|	
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		Operation.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	Operation.Ref IN (&Ref)
	|	AND Operation.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|
	|UNION ALL
	|
	|SELECT
	|	Operation.Date                                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	Operation.Organization                              AS Organization,
	|	Operation.Department                            AS Department,
	|	TableAdvancesReceived.LineOfBusiness   AS LineOfBusiness,
	|	Operation.ExpenseItem                           AS AssetRef,
	|	Operation.AssetsLiabilitiesDimension                 AS Dimension,
	|	Operation.GLAccountSettings                     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	0                                                 AS AmountIncludingVAT,
	|	0                                                 AS AmountExcludingVAT,
	|	TableAdvancesReceived.VAT                       AS SumCompl,
	|	TableAdvancesReceived.VATManag                    AS SumMan,
	|	TableAdvancesReceived.VAT                       AS PermanentDifference,
	|	
	|	TableAdvancesReceived.RowID       AS FinRecordID,
	|	BusinessTransactionsSettings.Ref             AS BusinessTransactionSetting
	|FROM
	|	Document.VATWritingOffAsExpenses AS Operation
	|
	|	INNER JOIN
	|		Document.VATWritingOffAsExpenses.PrepaymentsFromCustomer AS TableAdvancesReceived
	|	ON 
	|		Operation.Ref = TableAdvancesReceived.Ref
	|	
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		Operation.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	Operation.Ref IN (&Ref)
	|	AND Operation.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
