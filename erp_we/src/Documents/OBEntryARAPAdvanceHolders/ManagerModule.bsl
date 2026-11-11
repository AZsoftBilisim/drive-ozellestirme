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
	
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringBalancesWithAccountabilityRegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

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
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryARAPAdvanceHolders") Then
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
	QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	OBEntryLocalization.EnteringBalancesWithAccountablePersonsAddRequestTexts(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

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
	OBEntryLocalization.EnteringBalancesWithAccountabilityAddReportingCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesWithAccountablePersonsForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesWithAccountablePersonsRequestTextTTReflectedInLocalAccounting();
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
	
	DateOfRemainingGoods = New Boundary(Date, BoundaryType.Including);
	Return BalancesOnSettlementsWithAccountablePersons(DateOfRemainingGoods, BusinessOperation, Companies, AdditionalSelection);
	
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
	KeyFieldsArray.Add("Organization");
	KeyFieldsArray.Add("Department");
	
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
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryARAPAdvanceHolders);
	
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

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query                       = New Query;
	QueryTexts                = New ValueList();
	
	FullDocumentName = "Document.OBEntryARAPAdvanceHolders"; 
	RequestHasSource = False;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryARAPAdvanceHolders));
	
	RedefiningParameterCalculation = New Structure;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = True;
		
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
	Result.QueryText       = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text ="SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	FALSE AS EnabledGoodsAssignmentInSalesOpportunity,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(DataInTabularPartCalculationsWithAccountablePersons.Sum, 0)) AS Sum
		|FROM
		|	Document.OBEntryARAPAdvanceHolders AS DocumentData
		|		LEFT JOIN Document.OBEntryARAPAdvanceHolders.AdvanceHoldersARAPAccounting_ AS DataInTabularPartCalculationsWithAccountablePersons
		|		ON DocumentData.Ref = DataInTabularPartCalculationsWithAccountablePersons.Ref
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
		|	DocumentData.Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods,
		|	DocumentData.Currency,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	DocumentData.Posted,
		|	DocumentData.DeletionMark,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	DocumentData.EmployeeResponsible,
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Period",   Attributes.Period);
	Query.SetParameter("Number",    Attributes.Number);
	Query.SetParameter("Posted", Attributes.Posted);
	Query.SetParameter("Organization",                           Attributes.Organization);
	Query.SetParameter("Department",                         Attributes.Department);
	Query.SetParameter("BusinessOperation",                 Attributes.BusinessOperation);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("LocalAccountingCurrency",        SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",             Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                        Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                           Attributes.RecordInMA);
	Query.SetParameter("EmptyAssignment",                      Catalogs.Assignments.EmptyRef());
	Query.SetParameter("EmployeeResponsible",                         Attributes.EmployeeResponsible);
	Query.SetParameter("Comment",                           Attributes.Comment);
	Query.SetParameter("DeletionMark",                       Attributes.DeletionMark);
	Query.SetParameter("Currency",                                Attributes.Currency);
	Query.SetParameter("Sum",                                 Attributes.Sum);
	Query.SetParameter("Patch",                           Attributes.Patch);
	Query.SetParameter("ReversedDocument",                  Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",                  Attributes.CorrectedDocument);
	Query.SetParameter("BusinessTransactionSetting",        Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID(Metadata.Documents.OBEntryARAPAdvanceHolders));
	Query.SetParameter("ControlIssueOfCashByPurposes",
		GetFunctionalOption("ControlIssueOfCashByPurposes"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	AdvanceHoldersARAPAccounting_.LineNumber                   AS LineNumber,
	|	&Period                                              AS Period,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                                AS RecordType,
	|	&Organization                                         AS Organization,
	|	AdvanceHoldersARAPAccounting_.AdvanceHolder               AS AdvanceHolder,
	|	AdvanceHoldersARAPAccounting_.Ref.Department          AS Department,
	|	CASE 
	|		WHEN &ControlIssueOfCashByPurposes
	|			THEN AdvanceHoldersARAPAccounting_.CashFlowItem
	|		ELSE UNDEFINED
	|	END AS IssuancePurpose,
	|	AdvanceHoldersARAPAccounting_.Currency                        AS Currency,
	|	AdvanceHoldersARAPAccounting_.Sum                         AS Sum,
	|	AdvanceHoldersARAPAccounting_.SumCompl                     AS SumCompl,
	|	AdvanceHoldersARAPAccounting_.Sum                         AS ToReport,
	|	AdvanceHoldersARAPAccounting_.SumMan                      AS SumMan,
	|	AdvanceHoldersARAPAccounting_.RowID           AS FinRecordID,
	|	&BusinessTransactionSetting                      AS BusinessTransactionSetting,
	|	AdvanceHoldersARAPAccounting_.CashFlowItem AS CashFlowItem
	|FROM
	|	Document.OBEntryARAPAdvanceHolders.AdvanceHoldersARAPAccounting_ AS AdvanceHoldersARAPAccounting_
	|WHERE
	|	AdvanceHoldersARAPAccounting_.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryAdvanceHolderReceivables)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees))
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
	|	&Department AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	CASE
	|		WHEN COUNT(DISTINCT DataInTabularPartCalculationsWithAccountablePersons.Currency) > 1 
	|			THEN UNDEFINED
	|		ELSE MAX(DataInTabularPartCalculationsWithAccountablePersons.Currency)
	|	END AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Period AS RecordingInAccountingDate,
	|	CASE 
	|		WHEN COUNT(DISTINCT DataInTabularPartCalculationsWithAccountablePersons.Currency) > 1 
	|			THEN 0
	|		ELSE SUM(ISNULL(DataInTabularPartCalculationsWithAccountablePersons.Sum, 0))
	|	END AS Sum,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryARAPAdvanceHolders AS DocumentData
	|		LEFT JOIN Document.OBEntryARAPAdvanceHolders.AdvanceHoldersARAPAccounting_ AS
	|			DataInTabularPartCalculationsWithAccountablePersons
	|		ON DocumentData.Ref = DataInTabularPartCalculationsWithAccountablePersons.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref,
	|	CAST(DocumentData.Comment AS STRING(100))";
	
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
	
	OBEntryLocalization.EnteringBalancesWithAccountsAddPrintCommands(PrintCommands);
	
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

#Region ServiceProceduresForFillingInAccordingToOperationalAccountingData

Function BalancesOnSettlementsWithAccountablePersons(DateOfRemainingGoods, BusinessOperation, CompanyArray, AddtlFilter)
	
	Query = New Query("SELECT
		|	""AdvanceHoldersARAPAccounting_"" AS TablePartToFillIn,
		|	AdvanceHolderCashBalance.Organization AS Organization,
		|	AdvanceHolderCashBalance.Department AS Department,
		|	&BusinessOperation AS BusinessOperation,
		|	AdvanceHolderCashBalance.AdvanceHolder,
		|	AdvanceHolderCashBalance.IssuancePurpose AS CashFlowItem,
		|	AdvanceHolderCashBalance.Currency,
		|	&ZoomRatio * AdvanceHolderCashBalance.SumBalance AS Sum,
		|	&ZoomRatio * AdvanceHolderCashBalance.SumComplBalance AS SumCompl,
		|	&ZoomRatio * AdvanceHolderCashBalance.SumManBalance AS SumMan
		|FROM
		|	AccumulationRegister.AdvanceHolderCash.Balance(&Date, Organization IN (&CompanyArray) AND &SubdivisionCondition) AS AdvanceHolderCashBalance
		|WHERE
		|	&ZoomRatio * AdvanceHolderCashBalance.SumBalance > 0
		|
		|ORDER BY
		|	Organization,
		|	Department");
	
	Query.Parameters.Insert("CompanyArray",     CompanyArray);
	Query.Parameters.Insert("BusinessOperation", BusinessOperation);
	Query.Parameters.Insert("ZoomRatio",           ?(BusinessOperation = Enums.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees, -1, 1));
	Query.Parameters.Insert("Date",                  DateOfRemainingGoods);
	
	If ValueIsFilled(AddtlFilter) Then
		Query.Text = StrReplace(Query.Text , "&SubdivisionCondition", "Department = &Department");
		Query.Parameters.Insert("Department", AddtlFilter.Department);
	Else
		Query.Text = StrReplace(Query.Text , "&SubdivisionCondition", "TRUE");
	EndIf;
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
