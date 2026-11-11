#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection:
//     of Table elements<Register Name> - Assignment tables - a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryAcquiringContractARAP") Then
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
	QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers);
	QueryTextTableCashInTransit(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	OBEntryLocalization.EnteringBalancesOfSettlementsOnAcquiringSupplementTextsOfRequestsForConducting(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringBalancesOfSettlementsOnAcquiringAndAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	OBEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	OBEntryLocalization.EnteringAccountBalancesForAcquiringAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOfAcquiringCalculationsForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOfAcquiringSettlementsRequestTextTTReflectionInLocalAccounting();
EndFunction

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
	Return Undefined;
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyFieldsArray = New Array;
	Return KeyFieldsArray;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// Adds a command to create a document based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryAcquiringContractARAP);
	
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

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	SelectedOperation = Undefined;
	
	If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		SelectedOperation = Parameters.Key.BusinessOperation;
	ElsIf Parameters.Property("FillingValues") Then
		Parameters.FillingValues.Property("BusinessOperation", SelectedOperation);
	ElsIf Parameters.Property("CopyingValue") Then
		SelectedOperation = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.CopyingValue,"BusinessOperation");
	ElsIf Parameters.Property("FilterByTransactionTypes") And Parameters.FilterByTransactionTypes.Count() = 1 Then
		SelectedOperation = Parameters.FilterByTransactionTypes[0].Value;
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", SelectedOperation);
		Parameters.Insert("FillingValues", FillingValues);
		If Parameters.Property("Organization") Then
			FillingValues.Insert("Organization", Parameters.Organization);
		EndIf;
		If Parameters.Property("RecordInOperationalAccounting") Then
			FillingValues.Insert("RecordInOperationalAccounting", Parameters.RecordInOperationalAccounting);
		EndIf;
		If Parameters.Property("PostInFinancialAndTaxAccounting") Then
			FillingValues.Insert("PostInFinancialAndTaxAccounting", Parameters.PostInFinancialAndTaxAccounting);
		EndIf;
		If Parameters.Property("RecordInMA") Then
			FillingValues.Insert("RecordInMA", Parameters.RecordInMA);
		EndIf;
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If Data.Ref <> Undefined Then
		Presentation = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Data.Ref,
			Data.Number,
			Data.Date,
			Data.BusinessOperation);
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	DataSources = New Map;
	Return DataSources; 
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntryAcquiringContractARAP";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryAcquiringContractARAP));
	
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
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(DataOfTabularPartCalculationsForAcquiring.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntryAcquiringContractARAP AS DocumentData
		|		LEFT JOIN Document.OBEntryAcquiringContractARAP.AcquiringContractARAP AS DataOfTabularPartCalculationsForAcquiring
		|		ON DocumentData.Ref = DataOfTabularPartCalculationsForAcquiring.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.Currency,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	DocumentData.EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.DeletionMark,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	DocumentData.Posted,
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Number",  Attributes.Number);
	
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                 Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                    Attributes.RecordInMA);
	Query.SetParameter("Comment",                    Attributes.Comment);
	Query.SetParameter("Posted",                       Attributes.Posted);
	Query.SetParameter("Currency",                         Attributes.Currency);
	Query.SetParameter("DeletionMark",                Attributes.DeletionMark);
	Query.SetParameter("EmployeeResponsible",                  Attributes.EmployeeResponsible);
	Query.SetParameter("DocumentAmount",                 Attributes.DocumentAmount);
	Query.SetParameter("EmptyAssignment",               Catalogs.Assignments.EmptyRef());
	Query.SetParameter("Patch",                    Attributes.Patch);
	Query.SetParameter("ReversedDocument",           Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",           Attributes.CorrectedDocument);
	Query.SetParameter("BusinessTransactionSetting", Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document." + Metadata.Documents.OBEntryAcquiringContractARAP.Name));	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	AcquiringContractARAP.LineNumber             AS LineNumber,
	|	&Period                                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Organization                                AS Organization,
	|	AcquiringContractARAP.CashType      AS CashType,
	|	AcquiringContractARAP.AcquiringContract.BankAccount.CashCurrency AS Currency,
	|	AcquiringContractARAP.POSTerminal   AS POSTerminal,
	|	AcquiringContractARAP.AcquiringContract       AS Contract,
	|	AcquiringContractARAP.PaymentCardNumber     AS PaymentCardNumber,
	|	AcquiringContractARAP.PaymentDate             AS PaymentDate,
	|	AcquiringContractARAP.Sum                   AS Sum,
	|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer) AS CashFlowItem
	|FROM
	|	Document.OBEntryAcquiringContractARAP.AcquiringContractARAP AS AcquiringContractARAP
	|WHERE
	|	AcquiringContractARAP.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer)
	|	AND AcquiringContractARAP.CashType = VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions)
	|
	|UNION ALL
	|
	|SELECT
	|	AcquiringContractARAP.LineNumber             AS LineNumber,
	|	&Period                                     AS Period,
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Organization                                AS Organization,
	|	AcquiringContractARAP.CashType      AS CashType,
	|	AcquiringContractARAP.AcquiringContract.BankAccount.CashCurrency AS Currency,
	|	AcquiringContractARAP.POSTerminal   AS POSTerminal,
	|	AcquiringContractARAP.AcquiringContract       AS Contract,
	|	AcquiringContractARAP.PaymentCardNumber     AS PaymentCardNumber,
	|	AcquiringContractARAP.PaymentDate             AS PaymentDate,
	|	AcquiringContractARAP.Sum                   AS Sum,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer) AS CashFlowItem
	|FROM
	|	Document.OBEntryAcquiringContractARAP.AcquiringContractARAP AS AcquiringContractARAP
	|WHERE
	|	AcquiringContractARAP.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer)
	|	AND AcquiringContractARAP.CashType = VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard)
	|	
	|ORDER BY
	|	CashType,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	AcquiringContractARAP.LineNumber                                                    AS LineNumber,
	|	&Period                                                                            AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                             AS RecordType,
	|	&Organization                                                                       AS Organization,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring) AS CashTransferKind,
	|	AcquiringContractARAP.AcquiringContract.BankAccount                               AS Recipient,
	|	AcquiringContractARAP.AcquiringContract.Counterparty                                   AS Counterparty,
	|	AcquiringContractARAP.AcquiringContract                                              AS Contract,
	|	AcquiringContractARAP.AcquiringContract.BankAccount.CashCurrency         AS Currency,
	|	AcquiringContractARAP.Sum                                                          AS Sum,
	|	AcquiringContractARAP.SumCompl                                                      AS SumCompl,
	|	AcquiringContractARAP.SumMan                                                       AS SumMan,
	|	AcquiringContractARAP.RowID                                            AS FinRecordID,
	|	&BusinessTransactionSetting                                                    AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryAcquiringContractARAP.AcquiringContractARAP AS AcquiringContractARAP
	|		INNER JOIN Catalog.AcquiringContracts AS AcquiringContracts
	|		ON AcquiringContractARAP.AcquiringContract = AcquiringContracts.Ref
	|WHERE
	|	AcquiringContractARAP.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer)
	|	AND AcquiringContractARAP.CashType = VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions)
	|
	|UNION ALL
	|
	|SELECT
	|	AcquiringContractARAP.LineNumber                                                    AS LineNumber,
	|	&Period                                                                            AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                             AS RecordType,
	|	&Organization                                                                       AS Organization,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring) AS CashTransferKind,
	|	AcquiringContractARAP.AcquiringContract.BankAccount                               AS Recipient,
	|	AcquiringContractARAP.AcquiringContract.Counterparty                                   AS Counterparty,
	|	AcquiringContractARAP.AcquiringContract                                              AS Contract,
	|	AcquiringContractARAP.AcquiringContract.BankAccount.CashCurrency         AS Currency,
	|	AcquiringContractARAP.Sum                                                          AS Sum,
	|	AcquiringContractARAP.SumCompl                                                      AS SumCompl,
	|	AcquiringContractARAP.SumMan                                                       AS SumMan,
	|	AcquiringContractARAP.RowID                                            AS FinRecordID,
	|	&BusinessTransactionSetting                                                    AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryAcquiringContractARAP.AcquiringContractARAP AS AcquiringContractARAP
	|		INNER JOIN Catalog.AcquiringContracts AS AcquiringContracts
	|		ON AcquiringContractARAP.AcquiringContract = AcquiringContracts.Ref
	|WHERE
	|	AcquiringContractARAP.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer)
	|	AND AcquiringContractARAP.CashType = VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard)
	|	
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	CASE
	|		WHEN COUNT(DISTINCT DataOfTabularPartCalculationsForAcquiring.Currency) > 1
	|			THEN 0
	|		ELSE SUM(ISNULL(DataOfTabularPartCalculationsForAcquiring.Sum, 0))
	|	END AS Sum,
	|	CASE
	|		WHEN COUNT(DISTINCT DataOfTabularPartCalculationsForAcquiring.Currency) > 1
	|			THEN UNDEFINED
	|		ELSE &Currency
	|	END AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryAcquiringContractARAP AS DocumentData
	|		LEFT JOIN Document.OBEntryAcquiringContractARAP.AcquiringContractARAP AS
	|			DataOfTabularPartCalculationsForAcquiring
	|		ON DocumentData.Ref = DataOfTabularPartCalculationsForAcquiring.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref";
	
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
	
	OBEntryLocalization.EnteringBalancesOfAcquiringCalculationsAddPrintCommands(PrintCommands);
	
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
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
