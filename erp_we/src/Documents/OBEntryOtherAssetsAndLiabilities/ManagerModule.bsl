#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//              .
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	#Region OtherAssetsLiabilities
	
	// Articles of other activesparsives
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object.OtherAssetsLiabilities";
	ChoiceParameters.AssetRef                = "AssetRef";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	ChoiceParameters.SelectingItemOfAssetsLiabilities   = True;
	ChoiceParameters.AssetsLiabilitiesDimension     = "Dimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("OtherAssetsLiabilitiesAssetRef");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("OtherAssetsLiabilitiesDimension");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	#EndRegion
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

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
//     of Table elements<Register name> - data table to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryOtherAssetsAndLiabilities") Then
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
	QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	OBEntryLocalization.InputOfBalancesOfOtherAssetsLiabilitiesSupplementTextsOfRequestsForConducting(Query, QueryTexts, Registers);
	
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
	
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesAndAccountingMechanisms(DocumentMechanisms);
	
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
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesRequestTextTTReflectionInLocalAccounting();
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
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryOtherAssetsAndLiabilities);
	
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Department AS Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	SUM(ISNULL(TableDataOtherAssetsLiabilities.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntryOtherAssetsAndLiabilities AS DocumentData
		|		LEFT JOIN Document.OBEntryOtherAssetsAndLiabilities.OtherAssetsLiabilities AS TableDataOtherAssetsLiabilities
		|		ON DocumentData.Ref = TableDataOtherAssetsLiabilities.Ref
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.Currency,
		|	DocumentData.Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.DeletionMark,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	DocumentData.Posted";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Number",  Attributes.Number);
	
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("Department",                  Attributes.Department);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
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
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document." + Metadata.Documents.OBEntryOtherAssetsAndLiabilities.Name));
	Query.SetParameter("IDOfUnusedFinRecord", 
		DocumentsPosting.IDOfUnusedFinRecord());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	Rows.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	Rows.LineOfBusiness         AS LineOfBusiness,
	|	Rows.AssetRef                          AS AssetRef,
	|	CASE
	|		WHEN Rows.Dimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE Rows.Dimension
	|	END                                  AS Dimension,
	|	Rows.Sum                           AS Sum,
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryOtherAssetsAndLiabilities.OtherAssetsLiabilities AS Rows
	|WHERE
	|	Rows.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOtherAssetsAndLiabilities)
	|	AND Rows.AssetRef.AssetLiability IN (
	|		VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName),
	|		VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetLiability))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                AS Period,
	|	Rows.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	Rows.LineOfBusiness         AS LineOfBusiness,
	|	Rows.AssetRef                          AS AssetRef,
	|	CASE
	|		WHEN Rows.Dimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE Rows.Dimension
	|	END                                  AS Dimension,
	|	Rows.Sum                           AS Sum,
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryOtherAssetsAndLiabilities.OtherAssetsLiabilities AS Rows
	|WHERE
	|	Rows.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOtherAssetsAndLiabilities)
	|	AND Rows.AssetRef.AssetLiability = VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities)
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
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	SUM(ISNULL(TableDataOtherAssetsLiabilities.Sum, 0)) AS Sum,
	|	&Currency AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryOtherAssetsAndLiabilities AS DocumentData
	|		LEFT JOIN Document.OBEntryOtherAssetsAndLiabilities.OtherAssetsLiabilities AS
	|			TableDataOtherAssetsLiabilities
	|		ON DocumentData.Ref = TableDataOtherAssetsLiabilities.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntryOtherAssetsAndLiabilities";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryOtherAssetsAndLiabilities));
	
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

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesAddPrintCommands(PrintCommands);
	
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
