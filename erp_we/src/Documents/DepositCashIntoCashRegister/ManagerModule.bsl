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
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	DepositCashIntoCashRegisterLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.DepositCashIntoCashRegister") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// Create a motion initialization request
	
	Query = New Query;
	FillInInitializationParameters(Query, DocumentRef);
	
	////////////////////////////////////////////////////////////////////////////
	// Let's form the request text
	
	QueryTexts = New ValueList;

	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);

	QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers);
	QueryTextTableCashInTransit(Query, QueryTexts, Registers);
	QueryTextTableCashFlow(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	DepositCashIntoCashRegisterLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

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
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.DepositCashIntoCashRegister);
	
EndFunction

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND( ValueAllowed(CashRegister)
	|	OR ValueAllowed(CashAccount)
	|	) ";

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

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return DepositCashIntoCashRegisterLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// 		String - The text of the request for temporary tables required for reflection in the regulated accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return DepositCashIntoCashRegisterLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion
#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.DepositCashIntoCashRegister";
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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
			QueryText, FullDocumentName, "", False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, "");
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.DepositCashIntoCashRegister AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
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
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                       Common.MetadataObjectID("Document.DepositCashIntoCashRegister"));
	Values.Insert("BusinessOperation",                         Enums.BusinessTransactions.DepositCashIntoCashRegister);
	Values.Insert("ManagementAccountingCurrency",                    Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		Values.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.CashRegister               AS CashRegister,
	|	DocumentData.DocumentAmount         AS Sum,
	|	Amounts.AmountExcludingVATCompl AS SumCompl,
	|	Amounts.AmountExcludingVATMan  AS SumMan,
	|	VALUE(Enum.BusinessTransactions.DepositCashIntoCashRegister) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.CashIssueToAnotherCashAccount) AS CashFlowItem,
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DepositCashIntoCashRegister) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.DepositCashIntoCashRegister AS DocumentData
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		DocumentData.Ref = Amounts.Ref
	|		AND Amounts.RowID = """"
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)                                      AS RecordType,
	|	DocumentData.Date                                                        AS Period,
	|	
	|	DocumentData.Organization                                                 AS Organization,
	|	DocumentData.CashRegister                                                    AS Recipient,
	|	UNDEFINED                                                                AS Sender,
	|	VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount) AS CashTransferKind,
	|	UNDEFINED                                                                AS Counterparty,
	|	DocumentData.Currency                                                      AS Currency,
	|	
	|	DocumentData.DocumentAmount                                              AS Sum,
	|	Amounts.AmountExcludingVATCompl                                                       AS SumCompl,
	|	Amounts.AmountExcludingVATMan                                                        AS SumMan,
	|	
	|	VALUE(Enum.BusinessTransactions.DepositCashIntoCashRegister) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.CashIssueToAnotherCashAccount) AS CashFlowItem,
	|	DocumentData.DocumentID                                               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DepositCashIntoCashRegister) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.DepositCashIntoCashRegister AS DocumentData
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		DocumentData.Ref = Amounts.Ref
	|		AND Amounts.RowID = """"
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.DocumentAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.DepositCashIntoCashRegister) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashRegister.Department AS Department,
	|
	|	DocumentData.CashAccount AS Cash,
	|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
	|	VALUE(Catalog.CashFlowReportItems.CashIssueToAnotherCashAccount) AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS CorrespondingCurency,
	|
	|	DocumentData.CashRegister AS CorCash,
	|	VALUE(Enum.CashTypes.CashPayment) AS CorCashType,
	|
	|	Amounts.AmountExcludingVATMan AS Sum,
	|	Amounts.AmountExcludingVATCompl AS SumCompl,
	|	DocumentData.DocumentAmount AS AmountInCurrency,
	|	DocumentData.DocumentAmount AS AmountInCorCurrency,
	|
	|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS CorSourceOfFAGOfCash
	|FROM
	|	Document.DepositCashIntoCashRegister AS DocumentData
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		DocumentData.Ref = Amounts.Ref
	|		AND Amounts.RowID = """"
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	RequestTextForTheseDocuments = "
	|SELECT
	|	""Document"" AS DataSource,
	|	FALSE   AS DistributeTotalAmount,
	|	
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	UNDEFINED AS LineNumber,
	|	UNDEFINED AS RowID,
	|	
	|	DocumentTable.DocumentAmount AS AmountExcludingVAT,
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
	|	Document.DepositCashIntoCashRegister AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, RequestTextForTheseDocuments);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS Partner,
	|	&CashRegister                               AS StorageLocation,
	|	UNDEFINED                            AS Counterparty,
	|	UNDEFINED                            AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	
	|	&Number                                  AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	UNDEFINED                            AS EmployeeResponsible,
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
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#EndRegion

#EndRegion

#EndIf
