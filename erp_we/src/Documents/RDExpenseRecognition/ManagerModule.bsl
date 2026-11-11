#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Receives and places to store data for document generation phase is complete.
//
// Parameters:
//	FillParameters - See FillParameters
//	StorageAddress - String 
//	
Procedure TopicsRelatedToExpenses(FillParameters, StorageAddress) Export
	
	Data = GetTopicsForAttributingExpenses(FillParameters);
	
	PutToTempStorage(Data, StorageAddress);
	
EndProcedure

// Returns the structure of parameters for filling in data by topic
//
// Returns:
//	Structure - The fill parameters:
//	*BeginOfPeriod - Date -
//	*EndOfPeriod - Date -
//	*Organization - Array of CatalogRef, CatalogRef.Companies, Undefined - 
//	*BusinessOperation - EnumRef.BusinessTransactions -
//	*RecognizeAC - Boolean -
//	*RecognizeMA - Boolean -
//
Function FillParameters() Export
	
	FillParameters = New Structure();
	FillParameters.Insert("BeginOfPeriod", '00010101');
	FillParameters.Insert("EndOfPeriod", '00010101');
	FillParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	FillParameters.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	FillParameters.Insert("RecognizeAC", True);
	FillParameters.Insert("RecognizeMA", True);

	Return FillParameters;
	
EndFunction

//Returns the number of topics and stages of research and development to design.
//
// Parameters:
//	Parameters - Structure - a structure with the following properties:
//	* CompanyArray - Array of CatalogRef, Undefined -
//	* BeginOfPeriod - Date - lower limit on the date of the founding document
//	* EndOfPeriod - Date - upper limit on the date of the founding document
//
// Returns:
//	Number - the number of themes to design.
//
Function ThereAreSeveralStagesToDesign(Parameters) Export
	
	FillParameters = FillParameters();
	FillParameters.BeginOfPeriod = Parameters.BeginOfPeriod;
	FillParameters.EndOfPeriod = Parameters.EndOfPeriod;
	FillParameters.Organization = Parameters.CompanyArray;
	FillParameters.BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages;
	
	Data = GetTopicsForAttributingExpenses(FillParameters);
	
	For Each String In Data Do
		If String.CompletionDocumentGenerated = False Then
			Return True; 
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions -See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export 

	ChoiceParametersArray = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Allocation";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureForTheCompletionOfTheStage");
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureOfTheBUPoResearch");
	ChoiceParameters.FormItems.AssetRef.Add("DistributionOfTheCompletionOfTheStageCostItemOfTheBU");
	ChoiceParameters.FormItems.AssetRef.Add("DistributionByResearchItemOfExpenditureOfTheBU");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAnalysisOfTheBuzaperformanceStage");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("BUPoResearchCostAnalysis");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DistributionOfTheCompletionOfTheStageCostAnalysisBU");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DistributionByResearchCostAnalysisBU");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Allocation";
	ChoiceParameters.AssetRef = "ExpenseItemTaxAccounting";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionTaxAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureNuseachievementOfTheStage");
	ChoiceParameters.FormItems.AssetRef.Add("DistributionOfStageCompletionItemOfExpenditureNU");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DistributionOfTheCompletionOfTheStageCostAnalysisWELL");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAnalysisNuseachievementOfTheStage");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Allocation";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureAtTheEndOfTheStage");
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureOfTheUUPoForResearch");
	ChoiceParameters.FormItems.AssetRef.Add("DistributionOfTheCompletionOfTheStageItemOfExpenditureOfTheUU");
	ChoiceParameters.FormItems.AssetRef.Add("DistributionByResearchItemOfExpenditureOfTheUU");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAnalysisAtTheEndOfTheStage");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("UUPoResearchCostAnalysis");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DistributionOfTheCompletionOfTheUUCostAnalysisStage");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DistributionByResearchUUCostAnalysis");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
EndFunction

#Region AttachableCommands

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection.
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	RDExpensesAccountingLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - Array - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects - ValueList - value-reference to the object.
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters - Structure - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

EndProcedure

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	
	RDExpensesAccountingLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
// See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RDExpenseRecognition") Then
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
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers);
		RDExpensesAccountingLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return RDExpensesAccountingLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return RDExpensesAccountingLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns the adapted Query Text of Registered Records by case
// 
// Parameters:
//  RegisterName - String - Name of the register for receiving the adapted request 
// 
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
// 
Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.RDExpenseRecognition";
	
	RequestHasSource = True;
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",           """""");
	
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
										RedefiningParameterCalculation,
										TemporaryTableQueryTexts);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation,
										TemporaryTableQueryTexts);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
// 
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

// Standard subsystems.Versioning objects
//
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

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

#Region HyperlinkFormation

// Create a hyperlink to the paperwork.
// 
// Parameters:
//  Parameters - Structure - 
// 
// Returns:
//  Undefined, FormattedString - Hyperlink
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("View", Metadata.Documents.RDExpenseRecognition) Then
		Return Undefined;
	EndIf;
	
	Parameters.Insert("CompanyArray",?(ValueIsFilled(Parameters.Organization), 
											TMCommonUseClientServer.Array(Parameters.Organization),
											Undefined));
	
	HyperlinkText = NStr("vi = 'Đề tài, giai đoạn cần hoàn tất';
						|ru = 'Темы, этапы к завершению';
						|en = 'Topics, stages for completion'; fa = 'Topics, stages for completion';
						|it = 'Oggetti, fasi da completare';
						|pl = 'Tematy, etapy do zakończenia';
						|tr = 'Konular, tamamlanma aşamaları'");

	ThereAreSeveralStagesToDesign = ThereAreSeveralStagesToDesign(Parameters);
	
	If ThereAreSeveralStagesToDesign Then
		Return New FormattedString(HyperlinkText,,,,
			FormNameRecognitionOfResearchAndDevelopmentExpenses());
	Else
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameRecognitionOfResearchAndDevelopmentExpenses());
	EndIf;
	
EndFunction

// Returns the name of the workplace form for recognizing research and development expenses.
// 
// Returns:
//  String - form name
Function FormNameRecognitionOfResearchAndDevelopmentExpenses() Export
	
	Return "Document.RDExpenseRecognition.Form.WorkplaceOfCompletionOfRDTopicStages";
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	RDExpenseRecognition.Ref AS Ref,
	|	RDExpenseRecognition.Date AS Date,
	|	RDExpenseRecognition.Organization AS Organization,
	|	RDExpenseRecognition.Number AS IncomingDocumentNumber,
	|	RDExpenseRecognition.BusinessOperation AS BusinessOperation,
	|	RDExpenseRecognition.Posted AS Posted,
	|	RDExpenseRecognition.Comment AS Comment
	|INTO Attributes
	|FROM
	|	Document.RDExpenseRecognition AS RDExpenseRecognition
	|WHERE
	|	RDExpenseRecognition.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Attributes.Ref AS Ref,
	|	Attributes.Date AS Date,
	|	Attributes.Organization AS Organization,
	|	Attributes.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	Attributes.BusinessOperation AS BusinessOperation,
	|	Attributes.Posted AS Posted,
	|	Attributes.Comment AS Comment
	|FROM
	|	Attributes AS Attributes";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("BusinessOperation", Attributes.BusinessOperation);
	Query.SetParameter("Comment",           Attributes.Comment);
	Query.SetParameter("Ref",                Attributes.Ref);
	Query.SetParameter("Organization",           Attributes.Organization);
	Query.SetParameter("Posted",              Attributes.Posted);
	Query.SetParameter("Date",                  Attributes.Date);
	Query.SetParameter("Currency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.RDExpenseRecognition"));

	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation, 
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	DocumentData.Organization.LocalAccountingCurrency AS Currency,
	|	0 AS Sum,
	|	UNDEFINED AS Status,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	DocumentData.DateOfDirective AS SourceDocumentDate,
	|	DocumentData.NumberOfDirective AS SourceDocumentNumber,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.RDExpenseRecognition AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers) 
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Query.Text = 
	"SELECT DISTINCT
	|	&Date AS Date,
	|	&Ref AS Ref,
	|	&Organization AS Organization,
	|	TableOfIA.Department AS Department,
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Posted AS Posted,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	TableOfIA.ExpensesDimensionAccounting AS IntangibleAsset
	|FROM
	|	Document.RDExpenseRecognition.Allocation AS TableOfIA
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND TableOfIA.ExpensesDimensionAccounting <> UNDEFINED
	|	AND TableOfIA.ExpensesDimensionAccounting REFS Catalog.IntangibleAssets
	|	AND TableOfIA.ExpensesDimensionAccounting <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|	AND
	|		TableOfIA.ExpenseRecognitionTypeAC = VALUE(Enum.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets)
	|
	|UNION
	|
	|SELECT
	|	&Date AS Date,
	|	&Ref AS Ref,
	|	&Organization AS Organization,
	|	TableOfIA.Department AS Department,
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Posted AS Posted,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	TableOfIA.ExpensesDimensionTaxAccounting AS IntangibleAsset
	|FROM
	|	Document.RDExpenseRecognition.Allocation AS TableOfIA
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND TableOfIA.ExpensesDimensionTaxAccounting <> UNDEFINED
	|	AND TableOfIA.ExpensesDimensionTaxAccounting REFS Catalog.IntangibleAssets
	|	AND TableOfIA.ExpensesDimensionTaxAccounting <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|	AND
	|		TableOfIA.ExpenseRecognitionTypeTA = VALUE(Enum.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets)
	|
	|UNION
	|
	|SELECT
	|	&Date AS Date,
	|	&Ref AS Ref,
	|	&Organization AS Organization,
	|	TableOfIA.Department AS Department,
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Posted AS Posted,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	TableOfIA.ExpensesDimensionManagementAccounting AS IntangibleAsset
	|FROM
	|	Document.RDExpenseRecognition.Allocation AS TableOfIA
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND TableOfIA.ExpensesDimensionManagementAccounting <> UNDEFINED
	|	AND TableOfIA.ExpensesDimensionManagementAccounting REFS Catalog.IntangibleAssets
	|	AND TableOfIA.ExpensesDimensionManagementAccounting <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|	AND
	|		TableOfIA.ExpenseRecognitionTypeMA = VALUE(Enum.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets)
	|";
	QueryResult = Query.Execute();
	TableOfIA = QueryResult.Unload();
	TableOfIA.Columns.Add("RecNo", New TypeDescription("Number"));
	
	Cnt = 0;
	For Each IAString In TableOfIA Do
		IAString.RecNo = Cnt;
		Cnt = Cnt + 1;
	EndDo;
	
	Query.SetParameter("IntangibleAssetsDocuments", TableOfIA);
	
	QueryText = "
	|SELECT
	|	IntangibleAssetsDocuments.RecNo AS RecNo,
	|	IntangibleAssetsDocuments.Date AS Date,
	|	IntangibleAssetsDocuments.Ref AS Ref,
	|	IntangibleAssetsDocuments.Organization AS Organization,
	|	IntangibleAssetsDocuments.Department AS Department,
	|	IntangibleAssetsDocuments.RefType AS RefType,
	|	IntangibleAssetsDocuments.BusinessOperation AS BusinessOperation,
	|	IntangibleAssetsDocuments.Posted AS Posted,
	|	IntangibleAssetsDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	IntangibleAssetsDocuments.RecordInManAccounting AS RecordInManAccounting,
	|	IntangibleAssetsDocuments.IntangibleAsset AS IntangibleAsset
	|INTO IntangibleAssetsDocuments
	|FROM
	|	&IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsDocuments.RecNo-1 AS RecNo,
	|	IntangibleAssetsDocuments.Date AS Date,
	|	IntangibleAssetsDocuments.Ref AS Ref,
	|	IntangibleAssetsDocuments.Organization AS Organization,
	|	IntangibleAssetsDocuments.Department AS Department,
	|	IntangibleAssetsDocuments.RefType AS RefType,
	|	IntangibleAssetsDocuments.BusinessOperation AS BusinessOperation,
	|	IntangibleAssetsDocuments.Posted AS Posted,
	|	IntangibleAssetsDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	IntangibleAssetsDocuments.RecordInManAccounting AS RecordInManAccounting,
	|	IntangibleAssetsDocuments.IntangibleAsset AS IntangibleAsset
	|FROM
	|	IntangibleAssetsDocuments AS IntangibleAssetsDocuments";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
#EndRegion

Function GetRequestTextForTopicsRelatedToExpenses(Parameters)

	Text = "";

	If Parameters.BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages Then

		Text = "SELECT DISTINCT
		|	RDExpenseRecognitionRDTopicsStages.TopicStage AS TopicStage,
		|	RDExpenseRecognitionRDTopicsStages.Ref AS CompletionDocument,
		|	RDExpenseRecognitionRDTopicsStages.Ref.Organization AS Organization
		|INTO PeriodCompletionDocuments
		|FROM
		|	Document.RDExpenseRecognition.RDTopicsStages AS
		|		RDExpenseRecognitionRDTopicsStages
		|WHERE
		|	RDExpenseRecognitionRDTopicsStages.Ref.Date
		|		BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND
		|		RDExpenseRecognitionRDTopicsStages.Ref.BusinessOperation = &BusinessOperation
		|	AND RDExpenseRecognitionRDTopicsStages.Ref.Organization IN
		|		(&CompanyArray)
		|	AND RDExpenseRecognitionRDTopicsStages.Ref.Posted
		|
		|INDEX BY
		|	TopicStage,
		|	Organization
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OtherExpensesBalance.DimensionOfExpenses AS TopicStage,
		|	OtherExpensesBalance.SumManBalance AS AmountOfUU,
		|	OtherExpensesBalance.SumComplBalance AS AmountAccounting,
		|	OtherExpensesBalance.SumComplBalance - OtherExpensesBalance.PermanentDifferenceBalance -
		|		OtherExpensesBalance.CostTDBalance AS AmountFA,
		|	PeriodCompletionDocuments.CompletionDocument,
		|	NOT PeriodCompletionDocuments.CompletionDocument IS NULL AS CompletionDocumentGenerated,
		|	CAST(OtherExpensesBalance.DimensionOfExpenses AS
		|		Catalog.RDTopicsStages).PlannedWorkCompletionDate AS ScheduledEndDate,
		|	CAST(OtherExpensesBalance.DimensionOfExpenses AS Catalog.RDTopicsStages).Completed AS
		|		Completed,
		|	OtherExpensesBalance.Organization AS Organization
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(&BorderEndOfPeriod, Organization IN (&CompanyArray)
		|	AND DimensionOfExpenses REFS Catalog.RDTopicsStages) AS OtherExpensesBalance
		|		LEFT JOIN PeriodCompletionDocuments AS PeriodCompletionDocuments
		|		ON OtherExpensesBalance.DimensionOfExpenses = PeriodCompletionDocuments.TopicStage
		|		AND OtherExpensesBalance.Organization = PeriodCompletionDocuments.Organization
		|ORDER BY
		|	TopicStage";

	ElsIf Parameters.BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses Then

		Text = "SELECT
		|	RDExpenseRecognitionRDTopicsStages.TopicStage AS TopicResearchStage,
		|	RDExpenseRecognitionRDTopicsStages.Ref AS RecognitionDocument,
		|	RDExpenseRecognitionRDTopicsStages.Ref.Organization AS Organization,
		|	COUNT(RDExpenseRecognitionRDTopicsStages.LineNumber) AS
		|		NumberOfDistributionLines
		|INTO PeriodRecognitionDocuments
		|FROM
		|	Document.RDExpenseRecognition.RDTopicsStages AS
		|		RDExpenseRecognitionRDTopicsStages
		|		LEFT JOIN Document.RDExpenseRecognition.Allocation AS
		|			RDExpenseRecognitionAllocation
		|		ON RDExpenseRecognitionRDTopicsStages.Ref = RDExpenseRecognitionAllocation.Ref
		|WHERE
		|	RDExpenseRecognitionRDTopicsStages.Ref.Date
		|		BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND
		|		RDExpenseRecognitionRDTopicsStages.Ref.BusinessOperation = &BusinessOperation
		|	AND RDExpenseRecognitionRDTopicsStages.Ref.Organization IN
		|	(&CompanyArray)
		|	AND RDExpenseRecognitionRDTopicsStages.Ref.Posted
		|GROUP BY
		|	RDExpenseRecognitionRDTopicsStages.TopicStage,
		|	RDExpenseRecognitionRDTopicsStages.Ref.Organization,
		|	RDExpenseRecognitionAllocation.Ref,
		|	RDExpenseRecognitionRDTopicsStages.Ref
		|
		|INDEX BY
		|	TopicStage,
		|	Organization
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OtherExpensesBalance.Organization AS Organization,
		|	OtherExpensesBalance.DimensionOfExpenses AS TopicResearchStage,
		|	CASE
		|		WHEN OtherExpensesBalance.SumManBalance <> 0
		|			THEN OtherExpensesBalance.SumManBalance
		|		WHEN OtherExpensesBalance.SumBalance <> 0
		|			THEN OtherExpensesBalance.SumBalance
		|		ELSE OtherExpensesBalance.AmountExcludingVATBalance
		|	END AS AmountOfUU,
		|	OtherExpensesBalance.SumComplBalance AS AmountAccounting
		|INTO TT_Balance
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(&BorderEndOfPeriod, Organization IN (&CompanyArray)
		|	AND DimensionOfExpenses REFS Catalog.RDTopicsStages
		|	AND CAST(DimensionOfExpenses AS Catalog.RDTopicsStages).Development = FALSE) AS
		|		OtherExpensesBalance
		|
		|INDEX BY
		|	Organization,
		|	TopicResearchStage
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Balance.Organization AS Organization,
		|	TT_Balance.TopicResearchStage AS TopicResearchStage,
		|	PeriodRecognitionDocuments.RecognitionDocument AS RecognitionDocument,
		|	RDExpenseRecognitionAllocation.ExpenseItemAccounting AS ExpenseItemAccounting,
		|	RDExpenseRecognitionAllocation.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
		|	RDExpenseRecognitionAllocation.LineOfBusiness AS LineOfBusiness,
		|	RDExpenseRecognitionAllocation.Department AS Department,
		|	CASE
		|		WHEN PeriodRecognitionDocuments.NumberOfDistributionLines = 1
		|			THEN ""ByDocumentLine""
		|		WHEN PeriodRecognitionDocuments.NumberOfDistributionLines > 1
		|			THEN ""ByDocument""
		|		ELSE ""AccordingToParametersOfUP""
		|	END AS DistributionDisplayParameter,
		|	RDExpenseRecognitionAllocation.ExpenseItemManagementAccounting AS ExpenseItemManagementAccounting,
		|	RDExpenseRecognitionAllocation.ExpensesDimensionManagementAccounting AS ExpensesDimensionManagementAccounting,
		|	RDExpenseRecognitionAllocation.ExpenseRecognitionTypeMA AS ExpenseRecognitionTypeMA,
		|	RDExpenseRecognitionAllocation.ExpenseRecognitionTypeAC AS ExpenseRecognitionTypeAC,
		|	TT_Balance.AmountOfUU,
		|	TT_Balance.AmountAccounting
		|FROM
		|	TT_Balance AS TT_Balance
		|		LEFT JOIN PeriodRecognitionDocuments AS PeriodRecognitionDocuments
		|		ON TT_Balance.Organization = PeriodRecognitionDocuments.Organization
		|		AND TT_Balance.TopicResearchStage = PeriodRecognitionDocuments.TopicResearchStage
		|		LEFT JOIN Document.RDExpenseRecognition.Allocation AS
		|			RDExpenseRecognitionAllocation
		|		ON PeriodRecognitionDocuments.RecognitionDocument = RDExpenseRecognitionAllocation.Ref
		|		AND PeriodRecognitionDocuments.NumberOfDistributionLines = 1
		|WHERE
		|	(&RecognitionOfWBU
		|	AND TT_Balance.AmountAccounting <> 0)
		|	OR (&WooSConfession
		|	AND TT_Balance.AmountOfUU <> 0)";
	EndIf;

	Return Text;

EndFunction

// Gets the data for the document generation phase is complete.
//
// Parameters:
//	FillParameters - See FillParameters
//	
// Returns:
// 	ValueTable
//
Function GetTopicsForAttributingExpenses(FillParameters) 
	
	Query = New Query;
	Query.Text = GetRequestTextForTopicsRelatedToExpenses(FillParameters);
	Query.SetParameter("RecognitionOfWBU", FillParameters.RecognizeAC);
	Query.SetParameter("WooSConfession", FillParameters.RecognizeMA);
	Query.SetParameter("EndOfPeriod", FillParameters.EndOfPeriod);
	Query.SetParameter("BeginOfPeriod", FillParameters.BeginOfPeriod);
	Query.SetParameter("BusinessOperation", FillParameters.BusinessOperation);
	Query.SetParameter("BorderEndOfPeriod", New Boundary(FillParameters.EndOfPeriod, BoundaryType.Including));
	
	If Not ValueIsFilled(FillParameters.Organization) Then
		Query.SetParameter("CompanyArray", Catalogs.Companies.AvailableCompanies());
	Else
		Query.SetParameter("CompanyArray", TMCommonUseClientServer.Array(FillParameters.Organization));
	EndIf;

	QueryResult = Query.Execute();

	Return QueryResult.Unload();

EndFunction

#EndRegion

#EndIf