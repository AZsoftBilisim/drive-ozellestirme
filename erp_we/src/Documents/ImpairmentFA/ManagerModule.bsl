#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParametersArray = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ExpenseItemItemType";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.ArticleType = "IncomeItemItemType";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
		
	Return ChoiceParametersArray;
	
EndFunction

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("IntangibleAssets");
	
	DocumentMechanisms.Add("DocumentsRegistry");
	
	ImpairmentFALocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of data tables to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ImpairmentFA") Then
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
		
		// Writing to document logs, FA and IA separately.
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);

		ImpairmentFALocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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

	Return ImpairmentFALocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ImpairmentFALocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Receives and places to store data for document generation phase is complete.
//
// Parameters:
//	FillParameters - Structure
//		*Organization - Reference link.Organizations
//		*Period - Date
//	StorageAddress - String 
//	
Procedure FillInVNA(FillParameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.ImpairmentFA.Form.DocumentForm.Command.Fill");
	
	Data = ObtainVNAImpairmentData(FillParameters);
	
	PutToTempStorage(Data, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Data.Count() / 100);
	
EndProcedure

#EndRegion

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

#Region InterfaceImplementation

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

#EndRegion

#Region Private

#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ImpairmentFA";
	
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	ImpairmentFA.Ref AS Ref,
	|	ImpairmentFA.Date AS Date,
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.Number AS IncomingDocumentNumber,
	|	ImpairmentFA.Posted AS Posted,
	|	ImpairmentFA.Comment AS Comment
	|INTO Attributes
	|FROM
	|	Document.ImpairmentFA AS ImpairmentFA
	|WHERE
	|	ImpairmentFA.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Attributes.Ref AS Ref,
	|	Attributes.Date AS Date,
	|	Attributes.Organization AS Organization,
	|	Attributes.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	Attributes.Posted AS Posted,
	|	Attributes.Comment AS Comment
	|FROM
	|	Attributes AS Attributes";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Comment",	Attributes.Comment);
	Query.SetParameter("Ref",			Attributes.Ref);
	Query.SetParameter("Organization",	Attributes.Organization);
	Query.SetParameter("Posted",		Attributes.Posted);
	Query.SetParameter("Date",			Attributes.Date);
	Query.SetParameter("Period",			Attributes.Date);
	Query.SetParameter("Currency", 		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ImpairmentFA"));

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
	|	VALUE(Enum.BusinessTransactions.FAImpairment) AS BusinessOperation,
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
	|	DocumentData.Date AS SourceDocumentDate,
	|	DocumentData.Number AS SourceDocumentNumber,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.ImpairmentFA AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.ImpairmentIA) AS BusinessOperation,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	DocumentData.Organization.LocalAccountingCurrency AS Currency,
	|	0 AS Sum,
	|	UNDEFINED AS Status,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	TRUE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	DocumentData.Date AS SourceDocumentDate,
	|	DocumentData.Number AS SourceDocumentNumber,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.ImpairmentFA AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeVtOSListForLog(Query);
	
	QueryText = 
	"SELECT
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.Organization AS Organization,
	|	ListOfFA.Department AS Department,
	|	ListOfFA.PseudoLineNumber AS PseudoLineNumber
	|INTO ListOfOperatingSystemsForMagazine
	|FROM
	|	&ListOfOperatingSystemsForMagazine AS ListOfFA
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfOperatingSystemsForMagazine.PseudoLineNumber AS RecNo,
	|	&Ref AS Ref,
	|	&Period AS Date,
	|	ListOfOperatingSystemsForMagazine.Organization AS Organization,
	|	ListOfOperatingSystemsForMagazine.Department AS Department,
	|	&MetadataIdentifier AS RefType,
	|	VALUE(Enum.BusinessTransactions.FAImpairment) AS BusinessOperation,
	|	&Posted AS Posted,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	UNDEFINED AS FixedAssetsEvent,
	|	ListOfOperatingSystemsForMagazine.FixedAsset AS FixedAsset,
	|	FALSE AS IsPatch,
	|	DATETIME(1,1,1) AS CorrectionPeriodStart,
	|	DATETIME(1,1,1) AS CorrectionPeriodEnd
	|FROM
	|	Document.ImpairmentFA AS DocumentData,
	|	ListOfOperatingSystemsForMagazine AS ListOfOperatingSystemsForMagazine
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Initialize the temporary OS list table for the log.
// 		We generate line numbers for writing to the register of the EPA document.
// 		The OS may be part of the Unified State Register of Legal Entities, so the line numbers of the tabular part of the document are not applicable.
// Parameters:
//  Query - Query
Procedure InitializeVtOSListForLog(Query)
	
	// Prohibition of re-initialization.
	If Query.Parameters.Property("ListOfOperatingSystemsForMagazine") Then
		Return;
	EndIf;
	
	InitializationRequestText = 
	"SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS FixedAsset,
	|	CGUCompositionSliceLast.Organization AS Organization
	|INTO ListOfFA
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(&Period, NonCurrentAsset REFS Catalog.Assets) AS CGUCompositionSliceLast
	|		INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS
	|			ImpairmentFACashGeneratingUnits
	|		ON (CGUCompositionSliceLast.CGU = ImpairmentFACashGeneratingUnits.CGU
	|			AND CGUCompositionSliceLast.Organization = &Organization)
	|
	|UNION
	|
	|SELECT
	|	ImpairmentFAFixedAssets.FixedAsset AS FixedAsset,
	|	&Organization AS Organization
	|FROM
	|	Document.ImpairmentFA.FixedAssets AS ImpairmentFAFixedAssets
	|WHERE
	|	ImpairmentFAFixedAssets.Ref = &Ref
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALocationSliceLast.FixedAsset AS FixedAsset,
	|	FALocationSliceLast.FixedAssetsLocation AS Department
	|INTO OSDivisions
	|FROM
	|	InformationRegister.FALocation.SliceLast(&Period, FixedAsset IN
	|		(SELECT
	|			ListOfFA.FixedAsset
	|		FROM
	|			ListOfFA)) AS FALocationSliceLast
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfFA.FixedAsset AS FixedAsset,
	|	ListOfFA.Organization AS Organization,
	|	ISNULL(OSDivisions.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	0 AS PseudoLineNumber
	|FROM
	|	ListOfFA AS ListOfFA
	|		LEFT JOIN OSDivisions AS OSDivisions
	|		ON ListOfFA.FixedAsset = OSDivisions.FixedAsset
	|
	|ORDER BY
	|	FixedAsset";
	
	InitializationRequest = New Query;
	InitializationRequest.Text = InitializationRequestText;
	
	InitializationRequest.SetParameter("Ref", Query.Parameters.Ref);
	InitializationRequest.SetParameter("Period", Query.Parameters.Period);
	InitializationRequest.SetParameter("Organization", Query.Parameters.Organization);
	
	TableForRenumbering = InitializationRequest.Execute().Unload();
	
	PseudoNumber = 0;
	
	For Each String In TableForRenumbering Do
		String.PseudoLineNumber = PseudoNumber;
		PseudoNumber = PseudoNumber + 1;
	EndDo;
	
	Query.SetParameter("ListOfOperatingSystemsForMagazine", TableForRenumbering);
	
EndProcedure

Function QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeVtListOfNMAsForLog(Query);
	
	QueryText = 
	"SELECT
	|	ListOfIAForJournal.IntangibleAsset,
	|	ListOfIAForJournal.Organization AS Organization,
	|	ListOfIAForJournal.Department,
	|	ListOfIAForJournal.PseudoLineNumber
	|INTO ListOfIAForJournal
	|FROM
	|	&ListOfIAForJournal AS ListOfIAForJournal
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	VALUE(Enum.BusinessTransactions.ImpairmentIA) AS BusinessOperation,
	|	ListOfIAForJournal.PseudoLineNumber AS RecNo,
	|	&Period AS Date,
	|	ListOfIAForJournal.IntangibleAsset AS IntangibleAsset,
	|	ListOfIAForJournal.Organization AS Organization,
	|	ListOfIAForJournal.Department AS Department,
	|	&Ref AS Ref,
	|	UNDEFINED AS AdditionalRecord,
	|	&Posted AS Posted,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting
	|FROM
	|	Document.ImpairmentFA AS DocumentData,
	|	ListOfIAForJournal AS ListOfIAForJournal
	|		
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Initialize the temporary table list of NMAs for the log.
// 		We generate line numbers for writing to the document register of the volume.
// 		IA can be part of the Unified State Register of Legal Entities, so the line numbers of the tabular part of the document are not applicable.
// Parameters:
//  Query - Query
Procedure InitializeVtListOfNMAsForLog(Query)
	
	// Prohibition of re-initialization.
	If Query.Parameters.Property("ListOfIAForJournal") Then
		Return;
	EndIf;
	
	InitializationRequestText = 
	"SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS IntangibleAsset,
	|	CGUCompositionSliceLast.Organization AS Organization
	|INTO ListOfIA
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(&Period,  NonCurrentAsset REFS Catalog.IntangibleAssets) AS CGUCompositionSliceLast
	|		INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS
	|			ImpairmentFACashGeneratingUnits
	|		ON (CGUCompositionSliceLast.CGU = ImpairmentFACashGeneratingUnits.CGU
	|			AND CGUCompositionSliceLast.Organization = &Organization)
	|
	|UNION
	|
	|SELECT
	|	ImpairmentFAIntangibleAssets.IntangibleAsset AS IntangibleAsset,
	|	&Organization  AS Organization
	|FROM
	|	Document.ImpairmentFA.IntangibleAssets AS ImpairmentFAIntangibleAssets
	|WHERE
	|	ImpairmentFAIntangibleAssets.Ref = &Ref
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsRegistrationPlaceSliceLast.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsRegistrationPlaceSliceLast.Department AS Department
	|INTO IADivisions
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(&Period, IntangibleAsset IN
	|		(SELECT
	|			ListOfIA.IntangibleAsset
	|		FROM
	|			ListOfIA)) AS IntangibleAssetsRegistrationPlaceSliceLast
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.Organization AS Organization,
	|	ISNULL(IADivisions.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	0 AS PseudoLineNumber
	|FROM
	|	ListOfIA AS ListOfIA
	|		LEFT JOIN IADivisions AS IADivisions
	|		ON ListOfIA.IntangibleAsset = IADivisions.IntangibleAsset";
	
	InitializationRequest = New Query;
	InitializationRequest.Text = InitializationRequestText;
	
	InitializationRequest.SetParameter("Ref", Query.Parameters.Ref);
	InitializationRequest.SetParameter("Period", Query.Parameters.Period);
	InitializationRequest.SetParameter("Organization", Query.Parameters.Organization);
	
	TableForRenumbering = InitializationRequest.Execute().Unload();
	
	PseudoNumber = 0;
	
	For Each String In TableForRenumbering Do
		String.PseudoLineNumber = PseudoNumber;
		PseudoNumber = PseudoNumber + 1;
	EndDo;
	
	Query.SetParameter("ListOfIAForJournal", TableForRenumbering);
	
EndProcedure

#EndRegion

#Region LoadingFromFile

////////////////////////////////////////////////////////////////////////////////
// Interface for working with the File Upload subsystem.

// Sets the download parameters.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	For Each TabularSection In Metadata.Documents.ImpairmentFA.TabularSections Do
		If Find(Parameters.TabularSectionName, TabularSection.Name) <> 0 Then
			
			Parameters.DataStructureTemplateName = TabularSection.Name;
			Return;
			
		EndIf;
	EndDo;
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData    - String - the address of the temporary storage with the table of values in which
//                                        the downloaded data from the file is located. Composition of columns:
//     ID - Number - the sequence number of the line.
//     The remaining columns correspond to the columns of the File Upload Template.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document
//                                        that needs to be filled in from the addressable Data table.
// 	ConflictsList    - ValueTable - a list of ambiguous values for which there are several in the information security:
// 		* Id - Number - the ordinal number of the line.
// 		The rest of the column.
// 	FullTabularSectionName   - String -
// 	AdditionalParameters   - Structure:
// 		* TSName - String - name of the table part metadata,
// 		* Catalog - String - the name of the metadata of the downloaded Catalog in
// 		* ColumnName - String - the name of the column metadata in the loaded table part
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	ResultTable2 =  ReadTableForDownload(AddressOfMappingTable);
	DataToImport =  ReadTableForDownload(AddressOfUploadedData);
	
	// It is required to change the data type in the Recoverable Value columns of the REGL, Recoverable Value of the UPR.
	DataToImport = ConvertUploadedData(DataToImport);

	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		Query = New Query;

		If AdditionalParameters.TSName = "CashGeneratingUnits" Then
			Query.Text = CGURequestText();
		ElsIf AdditionalParameters.TSName = "FixedAssets" Then
			Query.Text = FixedAssetsQueryText();
		ElsIf AdditionalParameters.TSName = "IntangibleAssets" Then
			Query.Text = IntangibleAssetsRequestText();
		EndIf;
		
		Query.SetParameter("DataForComparison", DataToImport);
		
		QueryResult = Query.Execute();
		
		MappingTable = QueryResult.Unload();
		
		For Each TableRow In DataToImport Do 
			
			NewRow = ResultTable2.Add();
			NewRow.Id = TableRow.Id;
			
			ResultString1 = MappingTable.Find(TableRow.Id, "Id");
			If ResultString1 <> Undefined Then 
				If ResultString1.Count = 1 Then 
					FillPropertyValues(NewRow, ResultString1,, "Id");
				ElsIf ResultString1.Count > 1 Then 
					WritingAboutAmbiguity = ConflictsList.Add();
					WritingAboutAmbiguity.Id = TableRow.Id; 
					WritingAboutAmbiguity.Column = AdditionalParameters.ColumnName;
				EndIf;
			EndIf;
		EndDo;

	EndIf;
	
	PutToTempStorage(ResultTable2, AddressOfMappingTable);
	
EndProcedure

Function ConvertUploadedData(DataToImport)
	NumberType =  New TypeDescription("Number",New NumberQualifiers(31, 2, AllowedSign.Nonnegative));
	
	Data = New ValueTable;
	For Each Column In DataToImport.Columns Do
		If Find(Column.Name, "RecoverableAmount") <> 0 Then
			DataType = NumberType;
		Else
			DataType = Column.ValueType;
		EndIf;
		
		Data.Columns.Add(Column.Name, DataType);
	EndDo;
	
	For Each String In DataToImport Do
		DataString1 = Data.Add();
		FillPropertyValues(DataString1, String, ,"RecoverableAmountLocal, RecoverableAmountMan");
		
		DataString1.RecoverableAmountLocal = CastValueToType(String.RecoverableAmountLocal, NumberType);
		DataString1.RecoverableAmountMan  = CastValueToType(String.RecoverableAmountMan , NumberType);
	EndDo;
	
	Return Data;

EndFunction

Function CastValueToType(Value, TypeDescription)
	
	For Each Type In TypeDescription.Types() Do
		If Type = Type("Date") Then
			
			Return StringFunctionsClientServer.StringToDate(Value, TypeDescription.DateQualifiers.DateFractions);
			
		ElsIf Type = Type("Boolean") Then
			
			BooleanTypeDetails = New TypeDescription("Boolean");
			Return BooleanTypeDetails.AdjustValue(Value);
			
		ElsIf Type = Type("String") Then
			
			StringTypeDetails = New TypeDescription("String");
			Return StringTypeDetails.AdjustValue(Value);
			
		ElsIf Type = Type("Number") Then
			
			NonNumericCharacters = StrConcat(StrSplit(Value, "1234567890,."));
			Value = StrConcat(StrSplit(Value, NonNumericCharacters));
			TypeDescriptionNumber = New TypeDescription("Number",New NumberQualifiers(31, 2, AllowedSign.Nonnegative));
			Return TypeDescriptionNumber.AdjustValue(Value);
			
		EndIf;
	EndDo;
	
	Return Value;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	FullTabularSectionName - String - full name of the table part where data is loaded.
// 	ConflictsList - Array, ValueTable - A list to fill in with ambiguous data. Columns:
//     * Id        - Number  - Unique ID of the string.
//     * Column              - String -  Name of the column with the resulting ambiguity.
// 	ColumnName - String - Name of the column where the ambiguity occurred.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure -
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CatalogSearchResults_SSLy.Ref
	|FROM
	|	Catalog.CashGeneratingUnits AS CatalogSearchResults_SSLy
	|WHERE
	|	CatalogSearchResults_SSLy.Description = &Description";
	
	If AdditionalParameters.Catalog <> "CashGeneratingUnits" Then  
		Query.Text = StrReplace(Query.Text, "CashGeneratingUnits", AdditionalParameters.Catalog);  
	EndIf;
	
	Query.SetParameter("Description", LoadedValuesString[ColumnName]);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		ConflictsList.Add(SelectionDetailRecords.Ref);
	EndDo;
	                                                                                	
EndProcedure

// Returns a table passed through temporary storage
// 
// Parameters:
// 	TempStorageAddress - String - address of the storage where the table is located
// Returns:
// 	ValueTable - table with columns:
// 		* Id - Number - serial number.
// 		The rest of the column.
Function ReadTableForDownload(TempStorageAddress)
	
	Return GetFromTempStorage(TempStorageAddress); // ValueTable
	
EndFunction

Function CGURequestText()
	
	QueryText = 
	"SELECT
	|	CAST(DataForComparison.CGU AS STRING(&NameLength_)) AS Description,
	|	DataForComparison.Id                                 AS Id,
	|	DataForComparison.RecoverableAmountLocal                      AS RecoverableAmountLocal,
	|	DataForComparison.RecoverableAmountMan                       AS RecoverableAmountMan
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MappingCatalog_.Ref)                             AS CGU,
	|	MAX(DataForMatchingByName.RecoverableAmountLocal) AS RecoverableAmountLocal,
	|	MAX(DataForMatchingByName.RecoverableAmountMan)  AS RecoverableAmountMan,
	|	DataForMatchingByName.Id                      AS Id,
	|	COUNT(DataForMatchingByName.Id)          AS Count
	|FROM
	|	DataForComparison AS DataForMatchingByName
	|		LEFT JOIN Catalog.CashGeneratingUnits AS MappingCatalog_
	|		ON (MappingCatalog_.Description = DataForMatchingByName.Description)
	|			AND NOT MappingCatalog_.IsFolder
	|WHERE
	|	NOT MappingCatalog_.Ref IS NULL
	|
	|GROUP BY
	|	DataForMatchingByName.Id";
	
	NameLength_ = Metadata.Catalogs.CashGeneratingUnits.DescriptionLength;
	
	QueryText = StrReplace(QueryText, "&NameLength_", NameLength_);
	
	Return QueryText;
	
EndFunction

Function FixedAssetsQueryText()
	
	QueryText = 
	"SELECT
	|	CAST(DataForComparison.FixedAsset AS STRING(&NameLength_)) AS Description,
	|	DataForComparison.Id                                             AS Id,
	|	DataForComparison.RecoverableAmountLocal                                  AS RecoverableAmountLocal,
	|	DataForComparison.RecoverableAmountMan                                   AS RecoverableAmountMan
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MappingCatalog_.Ref)                             AS FixedAsset,
	|	MAX(DataForMatchingByName.RecoverableAmountLocal) AS RecoverableAmountLocal,
	|	MAX(DataForMatchingByName.RecoverableAmountMan)  AS RecoverableAmountMan,
	|	DataForMatchingByName.Id                      AS Id,
	|	COUNT(DataForMatchingByName.Id)          AS Count
	|FROM
	|	DataForComparison AS DataForMatchingByName
	|		LEFT JOIN Catalog.Assets AS MappingCatalog_
	|		ON (MappingCatalog_.Description = DataForMatchingByName.Description)
	|			AND NOT MappingCatalog_.IsFolder
	|WHERE
	|	NOT MappingCatalog_.Ref IS NULL
	|
	|GROUP BY
	|	DataForMatchingByName.Id";
	
	NameLength_ = Metadata.Catalogs.Assets.DescriptionLength;
	
	QueryText = StrReplace(QueryText, "&NameLength_", NameLength_);
	
	Return QueryText;
	
EndFunction

Function IntangibleAssetsRequestText()
	
	QueryText = 
	"SELECT
	|	CAST(DataForComparison.IntangibleAsset AS STRING(&NameLength_)) AS Description,
	|	DataForComparison.Id                                                AS Id,
	|	DataForComparison.RecoverableAmountLocal                                     AS RecoverableAmountLocal,
	|	DataForComparison.RecoverableAmountMan                                      AS RecoverableAmountMan
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MappingCatalog_.Ref)                             AS IntangibleAsset,
	|	MAX(DataForMatchingByName.RecoverableAmountLocal) AS RecoverableAmountLocal,
	|	MAX(DataForMatchingByName.RecoverableAmountMan)  AS RecoverableAmountMan,
	|	DataForMatchingByName.Id                      AS Id,
	|	COUNT(DataForMatchingByName.Id)          AS Count
	|FROM
	|	DataForComparison AS DataForMatchingByName
	|		LEFT JOIN Catalog.IntangibleAssets AS MappingCatalog_
	|		ON (MappingCatalog_.Description = DataForMatchingByName.Description)
	|			AND NOT MappingCatalog_.IsFolder
	|WHERE
	|	NOT MappingCatalog_.Ref IS NULL
	|
	|GROUP BY
	|	DataForMatchingByName.Id";
	
	NameLength_ = Metadata.Catalogs.IntangibleAssets.DescriptionLength;
	
	QueryText = StrReplace(QueryText, "&NameLength_", NameLength_);
	
	Return QueryText;
	
EndFunction

#EndRegion

Function ObtainVNAImpairmentData(FillParameters) 
	
Query = New Query;
	Query.Text =
		"SELECT
		|	ImpairmentFABalance.NonCurrentAsset AS NonCurrentAsset
		|FROM
		|	AccumulationRegister.ImpairmentFA.Balance(&Period, Organization = &Organization
		|	AND CGU = VALUE(Catalog.CashGeneratingUnits.EmptyRef)) AS ImpairmentFABalance
		|
		|UNION ALL
		|
		|SELECT
		|	ImpairmentFABalance.CGU
		|FROM
		|	AccumulationRegister.ImpairmentFA.Balance(&Period, Organization = &Organization
		|	AND CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)) AS ImpairmentFABalance";
	
	Query.SetParameter("Organization", FillParameters.Organization);
	Query.SetParameter("Period", FillParameters.Period);
	
	QueryResult = Query.Execute();

	Return QueryResult.Unload();

EndFunction

#EndRegion

#EndIf
