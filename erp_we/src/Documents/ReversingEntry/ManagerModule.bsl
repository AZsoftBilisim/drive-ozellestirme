#If Not MobileStandaloneServer Then
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
	
	// No description is required. The list of accounting mechanisms is obtained from the manager of the document being reversed.
	Return;
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReversingEntry") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		FillInInitializationParameters(Query, DocumentRef);
	EndIf;
	
	AddQueryTextsToTablesStornow(Query, QueryTexts, Registers);
	AddQueryTextToDocumentRegistry(Query, QueryTexts, Registers);
	AddQueryTextDocumentCorrectionTable(Query, QueryTexts, Registers);
	
	ReversingEntryLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	If CalculationOfCostCached.MediumSlipValuationIsUsed() Then
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	ReversingEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create a document "Cancellation".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//	See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReversingEntry) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReversingEntry.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReversingEntry);
		CreateBasedOnCommand.FunctionalOptions = "UseDocumentCorrection";
		CreateBasedOnCommand.WriteMode = "Post";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReversingEntryLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ReversingEntryLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
		|WHERE
		| ObjectReadingAllowed(ReversedDocument)
		|;
		|AllowUpdateIfReadingAllowed
		|WHERE
		| ObjectUpdateAllowed(ReversedDocument)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array of DocumentRef.ReversingEntry - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - Print Objects
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	ReversingEntryLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

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

// Function constructor of procedure parameters correctabledocument
// 
// Returns:
// 	Structure - LongDesc:
// * ReversedDocument - DefinedType.CorrectedDocuments
// * Date - Date
//
Function ParametersForGettingDocumentBeingCorrected() Export
	
	Parameters = New Structure;
	Parameters.Insert("ReversedDocument", Documents.CustomerInvoice.EmptyRef());
	Parameters.Insert("Date", Date(1, 1, 1));
	
	Return Parameters;	
	
EndFunction

// Returns the document being corrected in reverse.
//
// Parameters:
//	DocumentAttributes - See ParametersForGettingDocumentBeingCorrected
//
// Returns:
//  DocumentRef - The document being corrected.
//
Function CorrectedDocument(Val DocumentAttributes) Export
	
	SetPrivilegedMode(True);

	CorrectedDocument = Undefined;
	
	Query = New Query;
	Query.SetParameter("ReversedDocument", DocumentAttributes.ReversedDocument);
	Query.SetParameter("Period", DocumentAttributes.Date);
	
	Query.Text = QueryTextTableDocumentCorrections();
		
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		CorrectedDocument = Selection.CorrectedDocument;	
	EndIf;
	
	Return CorrectedDocument;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("ReversedDocument", Common.ObjectAttributeValue(DocumentRef, "ReversedDocument"));
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT TOP 1
	|	BEGINOFPERIOD(DocumentsRegistry.IBDocumentDate, DAY) AS AdjustmentPeriod_
	|INTO SourceDocument_
	|FROM
	|	FilterCriterion.RelatedDocuments(&ReversedDocument) AS RelatedDocuments
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON RelatedDocuments.Ref = DocumentsRegistry.Ref
	|WHERE
	|	DocumentsRegistry.Posted
	|
	|ORDER BY
	|	DocumentsRegistry.IBDocumentDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Period,
	|	DocumentData.Number                AS Number,
	|	DocumentData.Posted             AS Posted,
	|	DocumentData.DeletionMark      AS DeletionMark,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.Author                AS Author,
	|	DocumentData.Comment          AS Comment,
	|	DocumentData.Organization          AS Organization,
	|	SourceDocument_.AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	SourceDocument_.AdjustmentPeriod_ AS VariancePeriod
	|FROM
	|	Document.ReversingEntry AS DocumentData
	|		LEFT JOIN SourceDocument_ AS SourceDocument_
	|		ON (TRUE)
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	ParametersStructure = New Structure;
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
		ParametersStructure.Insert(Column.Name, Attributes[Column.Name]);
	EndDo;

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, ParametersStructure);
	
EndProcedure

Procedure AddQueryTextsToTablesStornow(Query, QueryTexts, Registers) 
	
	If Query.Parameters.Property("ReversedDocument") Then
		// We will form requests only according to the mechanisms of the document being reversed.
		MetadataObjectDocument = Query.Parameters.ReversedDocument.Metadata();
		AccountingMechanisms = DocumentsPosting.DocumentAccountingMechanisms(Documents[MetadataObjectDocument.Name]);
	Else
		// We will form queries for all accounting registers, because the execution context is not known.
		MetadataObjectDocument = Undefined;
		AccountingMechanisms = DocumentsPosting.NamesOfConfigurationAccountingMechanisms();
	EndIf;
	
	ConfigurationMechanisms = DocumentsPosting.ConfigurationAccountingMechanisms();
	For Each Mechanism In AccountingMechanisms Do
		
		MechanismModule = Common.CommonModule(ConfigurationMechanisms[Mechanism]);
		TextsOfCancellationRequests = MechanismModule.TextsOfCancellationRequests(Metadata.Documents.ReversingEntry);
		For Each KeyAndValue In TextsOfCancellationRequests Do
			MetadataObjectRegister = Metadata.FindByFullName(KeyAndValue.Key);
			If Not DocumentsPosting.RequiresTableForRegisteredRecords(MetadataObjectRegister.Name, Registers) Then
				Continue;
			EndIf;
			
			If MetadataObjectDocument <> Undefined
				And Not MetadataObjectDocument.RegisterRecords.Contains(MetadataObjectRegister) Then
				Continue;
			EndIf;
			
			QueryTexts.Add(KeyAndValue.Value, MetadataObjectRegister.Name);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure AddQueryTextToDocumentRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	CorrectedDocumentsEmptyLinks = New Array;
	For Each Type In Metadata.DefinedTypes.CorrectedDocuments.Type.Types() Do
		CorrectedDocumentsEmptyLinks.Add(New (Type));
	EndDo;
	Query.SetParameter("CorrectedDocumentsEmptyLinks", CorrectedDocumentsEmptyLinks);
	
	QueryText = "SELECT
	|	DocumentsRegistry.RefType AS RefType,
	|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistry.Organization AS Organization,
	|	DocumentsRegistry.Partner AS Partner,
	|	DocumentsRegistry.StorageLocation AS StorageLocation,
	|	DocumentsRegistry.Counterparty AS Counterparty,
	|	DocumentsRegistry.Department AS Department,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Ref AS Ref,
	|	DocumentsRegistry.RecordSeparator AS RecordSeparator,
	|	DocumentData.Number AS IBDocumentNumber,
	|	DocumentsRegistry.Status AS Status,
	|	DocumentData.Author AS EmployeeResponsible,
	|	DocumentsRegistry.AdditionalRecord AS AdditionalRecord,
	|	DocumentsRegistry.More AS More,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentsRegistry.SourceDocumentDate AS SourceDocumentDate,
	|	DocumentsRegistry.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentsRegistry.Sum AS Sum,
	|	DocumentsRegistry.Currency AS Currency,
	|	DocumentsRegistry.Contract AS Contract,
	|	DocumentsRegistry.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	TRUE AS ReverseTransactionCorrection,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	CASE
	|		WHEN DocumentsRegistry.CorrectedDocument = UNDEFINED
	|				OR DocumentsRegistry.CorrectedDocument IN (&CorrectedDocumentsEmptyLinks)
	|			THEN DocumentData.ReversedDocument
	|		ELSE DocumentsRegistry.CorrectedDocument
	|	END AS CorrectedDocument,
	|	DocumentData.Author AS Author
	|FROM
	|	Document.ReversingEntry AS DocumentData
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON
	|		DocumentData.ReversedDocument = DocumentsRegistry.Ref
	|WHERE
	|	DocumentData.Ref IN (&Ref)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableDocumentCorrections()

	QueryText =
	"SELECT
	|	&ReversedDocument AS ReversedDocument
	|
	|INTO TT_ReversedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period AS Period,
	|	ISNULL(DocumentCorrections.CorrectedDocument, TT_ReversedDocument.ReversedDocument) AS CorrectedDocument,
	|	CASE
	|		WHEN DocumentCorrections.Recorder IS NULL
	|			THEN UNDEFINED
	|		WHEN DocumentCorrections.CorrectionMethodStorno
	|			THEN TT_ReversedDocument.ReversedDocument
	|		ELSE DocumentCorrections.PreviousCorrection
	|	END AS PreviousCorrection,
	|	CASE
	|		WHEN DocumentCorrections.Recorder IS NULL
	|			THEN UNDEFINED
	|		WHEN DocumentCorrections.CorrectionMethodStorno
	|			THEN UNDEFINED
	|		ELSE DocumentCorrections.PreviousCorrection
	|	END AS LastChainDocument,
	|	CASE
	|		WHEN ISNULL(DocumentCorrections.CorrectionMethodStorno, TRUE)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DocumentToCorrectIsReversed,
	|	TRUE AS CorrectionMethodStorno
	|FROM
	|	TT_ReversedDocument AS TT_ReversedDocument
	|		LEFT JOIN InformationRegister.DocumentCorrections AS DocumentCorrections
	|		ON (DocumentCorrections.Recorder = TT_ReversedDocument.ReversedDocument)";

	Return QueryText;
		
EndFunction

Procedure AddQueryTextDocumentCorrectionTable(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentCorrections";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	QueryText = QueryTextTableDocumentCorrections();		
	
	QueryTexts.Add(QueryText, RegisterName);
	
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
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region DisposalAtFixedCost_Item
	
	If CalculationOfCostCached.MediumSlipValuationIsUsed() Then
		
	QueryText = 
	"SELECT TOP 0
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	TableTypesOfStocks_.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  	AS CorItemsLocationAttributes,
	|	UNDEFINED 								  	AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS ExpenseItemAssets,
	|	UNDEFINED 									AS AssetExpenseAnalytics,
	|	UNDEFINED  									AS IncomeItem,
	|	UNDEFINED 									AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 	AS SalesOpportunity,
	|	UNDEFINED 	AS Department,
	|	UNDEFINED 	AS Manager,
	|	UNDEFINED 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 				AS Count,
	|	TableTypesOfStocks_.RowID 		AS RowID,
	|	TableTypesOfStocks_.Cost 				AS Cost,
	|	TableTypesOfStocks_.Cost 				AS CostExcludingVAT,
	|	TableTypesOfStocks_.Cost 				AS LocalCost,
	|	TableTypesOfStocks_.Cost				AS CostMan,
	|	TableTypesOfStocks_.Cost	 			AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TableTypesOfStocks_.BusinessOperation  			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting 	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReversingEntry AS DocumentTable
	|	INNER JOIN AccumulationRegister.InventoryCost AS TableTypesOfStocks_
	|		ON FALSE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
		
	EndIf;
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList();
	
	FullDocumentName = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable = "DocumentData";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	
	If RegisterName = "DocumentsRegistry" Then
		
		AddQueryTextToDocumentRegistry(Query, QueryTexts, RegisterName);
		QueryText = QueryTexts[0].Value;
		ParameterValues.Insert("CorrectedDocumentsEmptyLinks",
			Query.Parameters.CorrectedDocumentsEmptyLinks);
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
			RedefiningParameterCalculation
		);
			
		For Each Dimension In Metadata.InformationRegisters.DocumentsRegistry.Dimensions Do
		
			If Dimension.Type.ContainsType(Type("CatalogRef.DocumentRegistryKeys")) Then
				
				QueryText = StrReplace(QueryText,
					StringFunctionsClientServer.SubstituteParametersToString("%1 AS %1", Dimension.Name),
					StringFunctionsClientServer.SubstituteParametersToString("%1.Key AS %1", Dimension.Name)
				);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReversingEntryLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return ReversingEntryLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
