
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
	
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.FixedAssetsPhysicalCount") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.FixedAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands, 2);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command, "BusinessOperation", Enums.BusinessTransactions.FixedAssetsPhysicalCount);
	EndIf;
	
	Command = Documents.FATransfer2_4.AddGenerateCommand(GenerationCommands, 4);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command, "BusinessOperation", Enums.BusinessTransactions.FixedAssetsPhysicalCount);
	EndIf;
	
	Command = Documents.FARevaluation2_4.AddGenerateCommand(GenerationCommands, 5);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command, "BusinessOperation", Enums.BusinessTransactions.FixedAssetsPhysicalCount);
	EndIf;
	
	Command = Documents.DisposeFixedAssets2_4.AddGenerateCommand(GenerationCommands, 7);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command, "BusinessOperation", Enums.BusinessTransactions.FixedAssetsPhysicalCount);
	EndIf;
	
	Command = Documents.LeaseTermination.AddGenerateCommand(GenerationCommands, 8);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command, "BusinessOperation", Enums.BusinessTransactions.FixedAssetsPhysicalCount);
	EndIf;
	

EndProcedure

// Adds a command to create a document "FA Inventory".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.FixedAssetsPhysicalCount) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.FixedAssetsPhysicalCount.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.FixedAssetsPhysicalCount);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_2,UseNonCurrentAssets2_4";
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
	
EndProcedure

#Region FillingBasedOn

// Returns data for filling in the version 2.4 document based on the FA inventory.
//
// Parameters:
// 		DocumentBasis - DocumentRef.FixedAssetsPhysicalCount - Link to the inventory document.
// 		Date - Date	- Date of filling.
// 		Action - EnumRef.ActionsBasedOnPhysicalInventoryCount - action.
// 		ArrayOfLineNumbers - Array - An array with line numbers based on which you want to fill out the document.
//
// Returns:
//  Structure - Contains:
//  	* Attributes - ValueTable - 
//  	* TabularSection - ValueTable - 
//
Function FillingDataBasedOnInventory24(DocumentBasis, Date, Action, Val ArrayOfLineNumbers = Undefined) Export
	
	DataToFill = New Structure("Attributes, TabularSection");

	// Filling in the header.
	QueryText =
	"SELECT
	|	FixedAssetsPhysicalCount.Date AS DocumentDate,
	|	FixedAssetsPhysicalCount.Organization AS Organization,
	|	FixedAssetsPhysicalCount.Department AS FixedAssetsLocation,
	|	FixedAssetsPhysicalCount.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	FixedAssetsPhysicalCount.RecordInManAccounting AS RecordInManAccounting,
	|	FixedAssetsPhysicalCount.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	FixedAssetsPhysicalCount.PostInAccounting AS PostInAccounting,
	|	FixedAssetsPhysicalCount.RecordInTA AS RecordInTA
	|FROM
	|	Document.FixedAssetsPhysicalCount AS FixedAssetsPhysicalCount
	|
	|WHERE
	|	FixedAssetsPhysicalCount.Ref = &Ref
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", DocumentBasis);
	Result = Query.Execute();
	DataToFill.Insert("Attributes", Result.Unload());
	
	Selection = Result.Select();
	If Not Selection.Next() Then
		Return DataToFill;
	EndIf;

	// Filling In The Table Part
	TableManager = New TempTablesManager;

	ActionsArray = CommonClientServer.ValueInArray(Action);

	AddCreatedDocumentsBasedOn2_4(TableManager, DocumentBasis, ActionsArray);
	
	QueryText =
	"SELECT 
	|	FixedAssetsPhysicalCount.AccountingObject AS AccountingObject,
	|	FixedAssetsPhysicalCount.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	FixedAssetsPhysicalCount.CostByAccountingDataLA AS CostByAccountingDataLA,
	|	FixedAssetsPhysicalCount.CostByAccountingDataTA AS CostByAccountingDataTA,
	|	FixedAssetsPhysicalCount.CostByAccountingDataMA AS CostByAccountingDataMA,
	|	FixedAssetsPhysicalCount.ActualCostAC AS ActualCostAC,
	|	FixedAssetsPhysicalCount.ActualCostTA AS ActualCostTA,
	|	FixedAssetsPhysicalCount.CostActualMan AS CostActualMan,
	|	FixedAssetsPhysicalCount.LAAction AS LAAction,
	|	FixedAssetsPhysicalCount.TAAction AS TAAction,
	|	FixedAssetsPhysicalCount.MAAction AS MAAction
	|
	|INTO TTFATable
	|
	|FROM 
	|	Document.FixedAssetsPhysicalCount.FA AS FixedAssetsPhysicalCount
	|
	|WHERE
	|	FixedAssetsPhysicalCount.Ref = &DocumentBasis
	|	AND VALUETYPE(FixedAssetsPhysicalCount.AccountingObject) = TYPE(Catalog.Assets)
	|
	|	AND (NOT &ArrayOfLineNumbersIsSet
	|			OR FixedAssetsPhysicalCount.LineNumber IN (&ArrayOfLineNumbers))
	|
	|	AND (NOT &ActionSet
	|			OR FixedAssetsPhysicalCount.LAAction = &Action
	|			OR FixedAssetsPhysicalCount.TAAction = &Action
	|			OR FixedAssetsPhysicalCount.MAAction = &Action)
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALocation.FixedAsset AS FixedAsset,
	|	FALocation.Organization AS Organization,
	|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
	|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson
	|
	|INTO TTLocationOfFA
	|
	|FROM
	|	InformationRegister.FALocation.SliceLast(
	|			&Date,
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND FixedAsset IN (
	|					SELECT 
	|						TTFATable.AccountingObject 
	|					FROM 
	|						TTFATable AS TTFATable)) AS FALocation
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTFATable.AccountingObject AS FixedAsset,
	|	TTFATable.FinanciallyLiablePerson AS InventoryCustodianRecipient,
	|	CAST(TTFATable.AccountingObject AS Catalog.Assets).Code AS AssetID,
	|	CAST(TTFATable.AccountingObject AS Catalog.Assets).OSGroup AS OSGroup,
	|
	|	TTFATable.CostByAccountingDataLA AS CostByAccountingDataLA,
	|	TTFATable.CostByAccountingDataTA AS CostByAccountingDataTA,
	|	TTFATable.CostByAccountingDataMA AS CostByAccountingDataMA,
	|
	|	CASE
	|		WHEN NOT &ActionSet
	|				OR TTFATable.LAAction = &Action
	|			THEN TTFATable.ActualCostAC
	|		ELSE 0
	|	END AS ActualCostAC,
	|
	|	CASE
	|		WHEN NOT &ActionSet
	|				OR TTFATable.TAAction = &Action
	|			THEN TTFATable.ActualCostTA
	|		ELSE 0
	|	END AS ActualCostTA,
	|
	|	CASE
	|		WHEN NOT &ActionSet
	|				OR TTFATable.MAAction = &Action
	|			THEN TTFATable.CostActualMan
	|		ELSE 0
	|	END AS CostActualMan,
	|
	|	FALocation.Organization AS LocationOrganization,
	|	FALocation.FixedAssetsLocation AS LocationDivision,
	|	FALocation.FinanciallyLiablePerson AS LocationOfPier,
	|
	|	CASE
	|		WHEN NOT &ActionSet
	|				OR TTFATable.LAAction = &Action
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PostInAccounting,
	|
	|	CASE
	|		WHEN NOT &ActionSet
	|				OR TTFATable.TAAction = &Action
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecordInTA,
	|
	|	CASE
	|		WHEN NOT &ActionSet
	|				OR TTFATable.MAAction = &Action
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecordInManAccounting
	|
	|FROM
	|	TTFATable AS TTFATable
	|
	|		LEFT JOIN TTDocumentsBasedOn2_4 AS DocumentsBasedOn
	|		ON DocumentsBasedOn.FixedAsset = TTFATable.AccountingObject
	|			AND DocumentsBasedOn.Action = &Action
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.FixedAsset = TTFATable.AccountingObject
	|
	|WHERE
	|	DocumentsBasedOn.Ref IS NULL
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TableManager;
	Query.SetParameter("Date", Date);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("ActionSet", ValueIsFilled(Action));
	Query.SetParameter("Action", Action);
	Query.SetParameter("ArrayOfLineNumbers", ?(ArrayOfLineNumbers = Undefined, New Array, ArrayOfLineNumbers));
	Query.SetParameter("ArrayOfLineNumbersIsSet", ?(ArrayOfLineNumbers = Undefined, False, True));
	
	DataToFill.Insert("TabularSection", Query.Execute().Unload());
	
	Return DataToFill;
	
EndFunction


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

#EndRegion

#Region Internal

// Returns FA accounting data.
//
// Parameters:
//  Parameters - Structure - The operation parameters.
// 
// Returns:
//  ValueTable - Contains accounting data.
//
Function DataOfAccounting(Parameters) Export

	CurCurrentAccountingData = New ValueTable;
	CurCurrentAccountingData.Columns.Add("AccountingObject", New TypeDescription("CatalogRef.Assets, CatalogRef.ConstructionObjects"));
	CurCurrentAccountingData.Columns.Add("OrganizationBasedOnAccountingData", New TypeDescription("CatalogRef.Companies"));
	CurCurrentAccountingData.Columns.Add("AccountingDataDivision", New TypeDescription("CatalogRef.BusinessStructure"));
	CurCurrentAccountingData.Columns.Add("FINANCIALLYLIABLEPERSON", New TypeDescription("CatalogRef.Persons"));
	CurCurrentAccountingData.Columns.Add("TheySAYAccordingToAccountingData", New TypeDescription("CatalogRef.Persons"));
	CurCurrentAccountingData.Columns.Add("CompaniesAreInterconnected", New TypeDescription("Boolean"));
	CurCurrentAccountingData.Columns.Add("Received_ForRent", New TypeDescription("Boolean"));
	CurCurrentAccountingData.Columns.Add("Contract", New TypeDescription("CatalogRef.LeaseContract, CatalogRef.CounterpartyContracts"));
	CurCurrentAccountingData.Columns.Add("AvailabilityByAccountingData", New TypeDescription("Boolean"));
	CurCurrentAccountingData.Columns.Add("CostByAccountingDataLA", TMCommonUse.MoneyFieldTypeDescription());
	CurCurrentAccountingData.Columns.Add("CostByAccountingDataTA", TMCommonUse.MoneyFieldTypeDescription());
	CurCurrentAccountingData.Columns.Add("CostByAccountingDataMA", TMCommonUse.MoneyFieldTypeDescription());
	CurCurrentAccountingData.Columns.Add("AssetID");
	CurCurrentAccountingData.Columns.Add("Code");
	CurCurrentAccountingData.Columns.Add("BusinessOperation");
	
	If Parameters.Property("ListOfFA") And Parameters.ListOfFA.Count() = 0 Then
		Return CurCurrentAccountingData;
	EndIf;
	
	If NonCurrentAssets.VNAManagementIsUsed_2_4(Parameters.Date) Then
		QueryText = QueryTextDataOfAccounting24(Parameters.BusinessOperation);
	Else
	EndIf;

	Query = New Query(QueryText);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("FINANCIALLYLIABLEPERSON", Parameters.FINANCIALLYLIABLEPERSON);
	Query.SetParameter("ForAllTheySay", Not ValueIsFilled(Parameters.FINANCIALLYLIABLEPERSON));
	Query.SetParameter("BusinessOperation", Parameters.BusinessOperation);
	Query.SetParameter("ListOfFA", ?(Parameters.Property("ListOfFA"), Parameters.ListOfFA, New Array));
	Query.SetParameter("AccordingToListOfFA", ?(Parameters.Property("ListOfFA"), True, False));
	Query.SetParameter("Date", ?(ValueIsFilled(Parameters.Date), EndOfDay(Parameters.Date), EndOfDay(CurrentSessionDate())));
	Query.SetParameter("RecordInManAccounting", Parameters.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Parameters.PostInAccounting Or Parameters.RecordInTA);
	Query.SetParameter("PostInAccounting", Parameters.PostInAccounting);
	Query.SetParameter("RecordInTA", Parameters.RecordInTA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	InterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Parameters.Organization);

	While Selection.Next() Do
		
		DataOfAccounting = CurCurrentAccountingData.Add();
		FillPropertyValues(DataOfAccounting, Selection);
		
		DataOfAccounting.CompaniesAreInterconnected = 
			Selection.OrganizationBasedOnAccountingData = Parameters.Organization 
			Or InterconnectedOrganizations.Find(Selection.OrganizationBasedOnAccountingData) <> Undefined;
	
	EndDo;

	Return CurCurrentAccountingData;
	
EndFunction

Procedure FillInAccountingData(Object, RowsCollection, ThisIsReadingObject, FillInServiceDetails = False) Export

	ListOfFA = New Array;
	For Each RowData In RowsCollection Do
		ListOfFA.Add(RowData.AccountingObject);
	EndDo;
	
	PhysicalInventoryCountParameters = New Structure;
	PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
	PhysicalInventoryCountParameters.Insert("Department", Object.Department);
	PhysicalInventoryCountParameters.Insert("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
	PhysicalInventoryCountParameters.Insert("Date", Object.Date);
	PhysicalInventoryCountParameters.Insert("BusinessOperation", Object.BusinessOperation);
	PhysicalInventoryCountParameters.Insert("ListOfFA", ListOfFA);
	PhysicalInventoryCountParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	PhysicalInventoryCountParameters.Insert("PostInAccounting", Object.PostInAccounting);
	PhysicalInventoryCountParameters.Insert("RecordInTA", Object.RecordInTA);
	
	AccountingDataByLine = DataOfAccounting(PhysicalInventoryCountParameters);
								
	VNAManagementIsUsed_2_4 = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	
	For Each RowData In RowsCollection Do
		
		DataOfAccounting = AccountingDataByLine.Find(RowData.AccountingObject, "AccountingObject");
		
		PhysicalInventoryCountParameters = New Structure;
		PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
		PhysicalInventoryCountParameters.Insert("Department", Object.Department);
		PhysicalInventoryCountParameters.Insert("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
		
		NonCurrentAssetsClientServer.FillInAccountingDataInLineOfPhysicalInventoryCountOfFA(
			RowData, 
			DataOfAccounting,
			PhysicalInventoryCountParameters,
			ThisIsReadingObject,
			FillInServiceDetails,
			VNAManagementIsUsed_2_4);
			
		NonCurrentAssetsClientServer.FillInActionBasedOnFixedAssetPhysicalInventory(
			RowData, 
			Object,
			VNAManagementIsUsed_2_4);
			
	EndDo; 
	
EndProcedure

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.FixedAssetsPhysicalCount";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
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
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.FixedAssetsPhysicalCount AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FixedAssetsPhysicalCount"));

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
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
	|	&Department                          AS Department,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	&Ref                           AS Ref,
	|	&Period                           AS Date,
	|	&Organization                      AS Organization,
	|	&Department                    AS Department,
	|	&Posted                         AS Posted,
	|	&BusinessOperation            AS BusinessOperation,
	|	&MetadataIdentifier          AS RefType,
	|	&PostInAccounting                      AS RecordInLocalAccounting,
	|	&RecordInTA                      AS RecordInTA,
	|	&RecordInManAccounting                AS RecordInManAccounting,
	|	FATable.AccountingObject             AS FixedAsset
	|FROM
	|	Document.FixedAssetsPhysicalCount AS DocumentData
	|
	|		LEFT JOIN Document.FixedAssetsPhysicalCount.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|			AND FATable.AccountingObject REFS Catalog.Assets
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	
	FixedAssetsPhysicalCountLocalization.AddPrintCommands(PrintCommands);
		
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	FixedAssetsPhysicalCountLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
			
EndProcedure

#EndRegion

#Region FillingBasedOn

// Adds a temporary table of documents created based on the inventory to the manager.
//
// Parameters:
// 	TableManager - TempTablesManager - Appointment Manager
// 	DocumentBasis - DocumentRef.FixedAssetsPhysicalCount - Link to the inventory document
// 	ActionsArray - String - Comma-separated string identifiers of the document type created based on
// 			Accepted values are identifiers of the values of the enumeration of the "Action on the basis of the inventory"
// 			If the parameter is not specified, the selection by type is not imposed.
//
Procedure AddCreatedDocumentsBasedOn2_4(TableManager, DocumentBasis, ActionsArray = Undefined)
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	TabularSection.FixedAsset AS FixedAsset,
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Move) AS Action,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	DocumentData.Department AS ReceivingBusinessUnit
	|
	|INTO TTDocumentsBasedOnData
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|		INNER JOIN Document.FATransfer2_4.FA AS TabularSection
	|		ON DocumentData.Ref = TabularSection.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND (NOT &ArrayOfActionsIsSet 
	|		OR VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Move) IN (&ActionsArray))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	TabularSection.FixedAsset,
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Recognition),
	|	DocumentData.FixedAssetsLocation,
	|	DocumentData.FixedAssetsLocation
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA AS TabularSection
	|		ON DocumentData.Ref = TabularSection.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND (NOT &ArrayOfActionsIsSet 
	|		OR VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Recognition) IN (&ActionsArray))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	TabularSection.FixedAsset,
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff),
	|	DocumentData.Department,
	|	DocumentData.Department
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|		INNER JOIN Document.DisposeFixedAssets2_4.FA AS TabularSection
	|		ON DocumentData.Ref = TabularSection.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND (NOT &ArrayOfActionsIsSet 
	|		OR VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff) IN (&ActionsArray))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	TabularSection.FixedAsset,
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation),
	|	DocumentData.Department,
	|	DocumentData.Department
	|FROM
	|	Document.FARevaluation2_4 AS DocumentData
	|
	|		INNER JOIN Document.FARevaluation2_4.FA AS TabularSection
	|		ON DocumentData.Ref = TabularSection.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND (NOT &ArrayOfActionsIsSet 
	|		OR VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation) IN (&ActionsArray))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	TabularSection.FixedAsset,
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets),
	|	DocumentData.Department,
	|	DocumentData.Department
	|FROM
	|	Document.ReturnLeasedAssets AS DocumentData
	|
	|		INNER JOIN Document.ReturnLeasedAssets.FA AS TabularSection
	|		ON DocumentData.Ref = TabularSection.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.GeneratedDocument
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND (NOT &ArrayOfActionsIsSet 
	|		OR VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets) IN (&ActionsArray))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	TabularSection.FixedAsset,
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination),
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	Document.LeaseTermination AS DocumentData
	|
	|		INNER JOIN Document.LeaseTermination.FA AS TabularSection
	|		ON DocumentData.Ref = TabularSection.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND (NOT &ArrayOfActionsIsSet 
	|		OR VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination) IN (&ActionsArray))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TTDocumentsBasedOnData.Ref) AS Ref,
	|	TTDocumentsBasedOnData.FixedAsset AS FixedAsset,
	|	TTDocumentsBasedOnData.Action AS Action,
	|	TTDocumentsBasedOnData.Department AS Department,
	|	TTDocumentsBasedOnData.ReceivingBusinessUnit AS ReceivingBusinessUnit
	|
	|INTO TTDocumentsBasedOn2_4
	|
	|FROM
	|	TTDocumentsBasedOnData AS TTDocumentsBasedOnData
	|
	|GROUP BY
	|	TTDocumentsBasedOnData.FixedAsset,
	|	TTDocumentsBasedOnData.Action,
	|	TTDocumentsBasedOnData.Department,
	|	TTDocumentsBasedOnData.ReceivingBusinessUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDocumentsBasedOnData
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TableManager;
	Query.SetParameter("ArrayOfActionsIsSet", ValueIsFilled(ActionsArray));
	Query.SetParameter("ActionsArray", ActionsArray);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Other
 
Function QueryTextDataOfAccounting24(BusinessOperation)

	If BusinessOperation = Enums.BusinessTransactions.PhysicalCountOfConstructionInProgress Then
		
		QueryText =
		"SELECT ALLOWED
		|	ExpenseItems.Ref AS Ref
		|INTO TTItemsOfExpenditure
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	ExpenseItems.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
		|	AND ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|	AND ExpenseItems.ExpensesOnConstructionObjects
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	OtherExpenses.DimensionOfExpenses AS AccountingObject,
		|
		|	CASE
		|		WHEN NOT &RecordInManAccounting
		|			THEN 0
		|		ELSE OtherExpenses.SumManBalance
		|	END AS CostByAccountingDataMA,
		|
		|	CASE
		|		WHEN NOT &PostInAccounting
		|			THEN 0
		|		ELSE OtherExpenses.SumComplBalance
		|	END AS CostByAccountingDataLA,
		|
		|	CASE
		|		WHEN NOT &RecordInTA
		|			THEN 0
		|		ELSE OtherExpenses.SumComplBalance - OtherExpenses.PermanentDifferenceBalance - OtherExpenses.CostTDBalance
		|	END AS CostByAccountingDataTA,
		|
		|	OtherExpenses.Organization AS OrganizationBasedOnAccountingData,
		|	OtherExpenses.Department AS AccountingDataDivision,
		|	UNDEFINED AS TheySAYAccordingToAccountingData,
		|	FALSE AS Received_ForRent,
		|	VALUE(Enum.FixedAssetsStates.NotRecognized_) AS State,
		|	&BusinessOperation AS BusinessOperation
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(
		|			&Date,
		|			(NOT &AccordingToListOfFA OR DimensionOfExpenses IN (&ListOfFA))
		|				AND Organization = &Organization
		|				AND Department = &Department
		|				AND DimensionOfExpenses REFS Catalog.ConstructionObjects
		|				AND ExpenseItem IN
		|					(SELECT
		|						ExpenseItems.Ref
		|					FROM
		|						TTItemsOfExpenditure AS ExpenseItems)) AS OtherExpenses
		|
		|ORDER BY
		|	CAST(OtherExpenses.DimensionOfExpenses AS Catalog.ConstructionObjects).Presentation
		|";
			
	ElsIf BusinessOperation = Enums.BusinessTransactions.PhysicalCountOfCIPAssets Then
		
		QueryText =
		"SELECT ALLOWED
		|	ExpenseItems.Ref AS Ref
		|INTO TTItemsOfExpenditure
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	ExpenseItems.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
		|	AND ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|	AND ExpenseItems.ExpensesOnAssets
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	OtherExpenses.DimensionOfExpenses AS AccountingObject,
		|	CAST(OtherExpenses.DimensionOfExpenses AS Catalog.Assets).AssetID AS AssetID,
		|	CAST(OtherExpenses.DimensionOfExpenses AS Catalog.Assets).Code AS Code,
		|
		|	CASE
		|		WHEN NOT &RecordInManAccounting
		|			THEN 0
		|		ELSE OtherExpenses.SumManBalance
		|	END AS CostByAccountingDataMA,
		|
		|	CASE
		|		WHEN NOT &PostInAccounting
		|			THEN 0
		|		ELSE OtherExpenses.SumComplBalance
		|	END AS CostByAccountingDataLA,
		|
		|	CASE
		|		WHEN NOT &RecordInTA
		|			THEN 0
		|		ELSE OtherExpenses.SumComplBalance - OtherExpenses.PermanentDifferenceBalance - OtherExpenses.CostTDBalance
		|	END AS CostByAccountingDataTA,
		|
		|	OtherExpenses.Organization AS OrganizationBasedOnAccountingData,
		|	OtherExpenses.Department AS AccountingDataDivision,
		|	UNDEFINED AS TheySAYAccordingToAccountingData,
		|	FALSE AS Received_ForRent,
		|	VALUE(Enum.FixedAssetsStates.NotRecognized_) AS State,
		|	&BusinessOperation AS BusinessOperation
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(
		|			&Date,
		|			(NOT &AccordingToListOfFA OR DimensionOfExpenses IN (&ListOfFA))
		|				AND Organization = &Organization
		|				AND Department = &Department
		|				AND DimensionOfExpenses REFS Catalog.Assets
		|				AND ExpenseItem IN
		|					(SELECT
		|						ExpenseItems.Ref
		|					FROM
		|						TTItemsOfExpenditure AS ExpenseItems)) AS OtherExpenses
		|WHERE
		|	OtherExpenses.SumComplBalance <> 0
		|
		|ORDER BY
		|	CAST(OtherExpenses.DimensionOfExpenses AS Catalog.Assets).Presentation,
		|	CAST(OtherExpenses.DimensionOfExpenses AS Catalog.Assets).AssetID
		|";
		
	Else
		
		QueryText = 
		"SELECT ALLOWED
		|	ListOfFA.FixedAsset AS FixedAsset,
		|	MAX(ListOfFA.EnteredInOffBalanceAccounting) AS EnteredInOffBalanceAccounting
		|
		|INTO StateOfFA
		|
		|FROM
		|	(SELECT
		|		FixedAssetsAccountingProcedureManagementAccounting.FixedAsset AS FixedAsset,
		|		FALSE AS EnteredInOffBalanceAccounting
		|	FROM
		|		InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Date,
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND &RecordInManAccounting
		|					AND Organization = &Organization
		|					AND (NOT &AccordingToListOfFA
		|						OR FixedAsset IN (&ListOfFA))) AS FixedAssetsAccountingProcedureManagementAccounting
		|	WHERE
		|		FixedAssetsAccountingProcedureManagementAccounting.State IN (
		|			VALUE(Enum.FixedAssetsStates.Recognized_), 
		|			VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))
		|
		|	UNION ALL
		|
		|	SELECT
		|		AccountingProcedureForOSBU.FixedAsset AS FixedAsset,
		|
		|		CASE
		|			WHEN AccountingProcedureForOSBU.BUState = VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS EnteredInOffBalanceAccounting
		|	FROM
		|		InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|				&Date,
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND &RecordInLocalAccounting
		|					AND Organization = &Organization
		|					AND (NOT &AccordingToListOfFA
		|						OR FixedAsset IN (&ListOfFA))) AS AccountingProcedureForOSBU
		|	WHERE
		|		(&PostInAccounting
		|			AND AccountingProcedureForOSBU.BUState IN (
		|					VALUE(Enum.FixedAssetsStates.Recognized_), 
		|					VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))
		|			OR &RecordInTA
		|				AND AccountingProcedureForOSBU.StateTa IN (
		|					VALUE(Enum.FixedAssetsStates.Recognized_)))
		|
		|	) AS ListOfFA
		|
		|WHERE
		|	ListOfFA.FixedAsset.OSType IN (
		|		VALUE(Enum.FATypes.Asset),
		|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
		|
		|GROUP BY
		|	ListOfFA.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CASE
		|		WHEN FALocation.Leaseholder = &Organization
		|			THEN FALocation.Leaseholder
		|		ELSE FALocation.Organization
		|	END AS Organization,
		|
		|	FALocation.FixedAssetsLocation AS Department,
		|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
		|	FALocation.FixedAsset AS FixedAsset
		|
		|INTO FALocation
		|
		|FROM
		|	InformationRegister.FALocation.SliceLast(
		|			&Date,
		|			CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset IN
		|					(SELECT
		|						StateOfFA.FixedAsset
		|					FROM
		|						StateOfFA)) AS FALocation
		|WHERE
		|	(&AccordingToListOfFA
		|		OR (FALocation.Organization = &Organization
		|					OR FALocation.Leaseholder = &Organization)
		|				AND FALocation.FixedAssetsLocation = &Department
		|				AND (FALocation.FinanciallyLiablePerson = &FinanciallyLiablePerson OR &ForAllTheySay))
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	FALocation.Organization AS Organization,
		|	FALocation.Department AS Department,
		|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
		|	FALocation.FixedAsset AS FixedAsset
		|
		|INTO ListOfFA
		|
		|FROM
		|	FALocation AS FALocation
		|
		|WHERE
		|	NOT &AccordingToListOfFA
		|
		|UNION ALL
		|
		|SELECT
		|	FALocation.Organization AS Organization,
		|	FALocation.Department AS Department,
		|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
		|	Assets.Ref AS FixedAsset
		|
		|FROM
		|	Catalog.Assets AS Assets
		|
		|		LEFT JOIN FALocation AS FALocation
		|		ON FALocation.FixedAsset = Assets.Ref
		|
		|WHERE
		|	&AccordingToListOfFA
		|	AND Assets.Ref IN(&ListOfFA)
		|
		|INDEX BY
		|	Organization,
		|	FixedAsset,
		|	Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	LeasedAsset.FixedAsset AS FixedAsset,
		|	LeasedAsset.Contract AS Contract
		|
		|INTO LeasedAsset
		|
		|FROM
		|	InformationRegister.LeasedAsset.SliceLast(
		|			&Date,
		|			FixedAsset IN
		|					(SELECT
		|						StateOfFA.FixedAsset
		|					FROM
		|						StateOfFA AS StateOfFA)) AS LeasedAsset
		|WHERE
		|	LeasedAsset.State IN (
		|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
		|		VALUE(Enum.FixedAssetsStates.InLease))
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	FACost.Organization AS Organization,
		|	FACost.Department AS Department,
		|	FACost.FixedAsset AS FixedAsset,
		|	FACost.CostBalance AS CostByAccountingDataMA,
		|	FACost.LocalCostBalance + FACost.CostTargetFinancingBalance AS CostByAccountingDataLA,
		|	FACost.CostInTaxAccountingBalance AS CostByAccountingDataTA,
		|	FACost.SecurityDepositValueBalance AS SecurityDepositValue
		|
		|INTO FACost
		|
		|FROM
		|	AccumulationRegister.FACost.Balance(
		|			&Date,
		|			(Organization, FixedAsset, Department) IN
		|				(SELECT
		|					ListOfFA.Organization,
		|					ListOfFA.FixedAsset,
		|					ListOfFA.Department
		|				FROM
		|					ListOfFA)) AS FACost
		|
		|UNION ALL
		|
		|SELECT
		|	FACost.Leaseholder AS Organization,
		|	FACost.Department AS Department,
		|	FACost.FixedAsset AS FixedAsset,
		|	0 AS CostByAccountingDataMA,
		|	0 AS CostByAccountingDataLA,
		|	0 AS CostByAccountingDataTA,
		|	FACost.SecurityDepositValueBalance AS SecurityDepositValue
		|FROM
		|	AccumulationRegister.FACost.Balance(
		|			&Date,
		|			(Leaseholder, FixedAsset, Department) IN
		|				(SELECT
		|					ListOfFA.Organization,
		|					ListOfFA.FixedAsset,
		|					ListOfFA.Department
		|				FROM
		|					ListOfFA)) AS FACost
		|
		|INDEX BY
		|	FixedAsset,
		|	Organization,
		|	Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfFA.FixedAsset AS AccountingObject,
		|	ListOfFA.FixedAsset.Presentation AS AccountingObjectPresentation,
		|	ListOfFA.FixedAsset.AssetID AS AssetID,
		|	ListOfFA.FixedAsset.Code AS Code,
		|	ListOfFA.Organization AS OrganizationBasedOnAccountingData,
		|	ListOfFA.Department AS AccountingDataDivision,
		|	ListOfFA.FinanciallyLiablePerson AS FinanciallyLiablePerson,
		|	ListOfFA.FinanciallyLiablePerson AS TheySAYAccordingToAccountingData,
		|
		|	CASE
		|		WHEN StateOfFA.EnteredInOffBalanceAccounting
		|				OR NOT &RecordInManAccounting
		|			THEN 0
		|		ELSE ISNULL(FACost.CostByAccountingDataMA, 0)
		|	END AS CostByAccountingDataMA,
		|
		|	CASE
		|		WHEN NOT &PostInAccounting
		|			THEN 0
		|		WHEN StateOfFA.EnteredInOffBalanceAccounting
		|			THEN ISNULL(FACost.SecurityDepositValue, 0)
		|		ELSE ISNULL(FACost.CostByAccountingDataLA, 0)
		|	END AS CostByAccountingDataLA,
		|
		|	CASE
		|		WHEN StateOfFA.EnteredInOffBalanceAccounting
		|				OR NOT &RecordInTA
		|			THEN 0
		|		ELSE ISNULL(FACost.CostByAccountingDataTA, 0)
		|	END AS CostByAccountingDataTA,
		|
		|	NOT LeasedAsset.FixedAsset IS NULL AS Received_ForRent,
		|	ISNULL(LeasedAsset.Contract, UNDEFINED) AS Contract,
		|	ISNULL(StateOfFA.EnteredInOffBalanceAccounting, FALSE) AS EnteredInOffBalanceAccounting,
		|	&BusinessOperation AS BusinessOperation
		|
		|FROM
		|	ListOfFA AS ListOfFA
		|
		|		LEFT JOIN StateOfFA AS StateOfFA
		|		ON StateOfFA.FixedAsset = ListOfFA.FixedAsset
		|
		|		LEFT JOIN FACost AS FACost
		|		ON FACost.FixedAsset = ListOfFA.FixedAsset
		|			AND FACost.Organization = ListOfFA.Organization
		|			AND FACost.Department = ListOfFA.Department
		|
		|		LEFT JOIN LeasedAsset AS LeasedAsset
		|		ON LeasedAsset.FixedAsset = ListOfFA.FixedAsset
		|
		|ORDER BY
		|	AccountingObjectPresentation,
		|	AssetID
		|";
		
	EndIf; 

	Return QueryText;
	
EndFunction


#EndRegion

#Region InfobaseUpdate

// Adds procedures to the list that handle updating information security
// data for all supported library versions or configurations.
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.FixedAssetsPhysicalCount.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("f3fbac2e-c1b3-46a2-9fd4-759508c57dbb");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.FixedAssetsPhysicalCount.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Kiểm kê TSCĐ"":
								  |- điền các mục tin phản ánh trong kế toán.';
								  |ru = 'Обновляет документы ""Инвентаризация ОС"":
								  |- заполняет реквизиты отражения в учете.';
								  |en = 'Updates the ""Fixed assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.'; fa = 'Updates the ""Fixed assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.';
								  |it = 'Updates the ""Fixed assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.';
								  |pl = 'Updates the ""Fixed assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.';
								  |tr = '""Sabit Kıymet Stok Sayımı"" belgelerini günceller: 
								  | - muhasebede yansıtma özniteliklerini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.FixedAssetsPhysicalCount.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.FixedAssetsPhysicalCount.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.FixedAssetsPhysicalCount.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.FixedAssetsPhysicalCount";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentsList.Ref AS Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref
	|	FROM
	|		Document.FixedAssetsPhysicalCount AS DocumentData
	|	WHERE
	|		NOT DocumentData.RecordInManAccounting
	|		AND NOT DocumentData.RecordInLocalAccounting
	|		AND NOT DocumentData.PostInAccounting
	|		AND NOT DocumentData.RecordInTA
	|
	|	) AS DocumentsList
	|";
	
	Query = New Query(QueryText);

	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.FixedAssetsPhysicalCount.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.FixedAssetsPhysicalCount";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;

	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.FixedAssetsPhysicalCount
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;

			If Not DocumentObject.RecordInManAccounting
				And Not DocumentObject.RecordInLocalAccounting
				And Not DocumentObject.PostInAccounting
				And Not DocumentObject.RecordInTA Then
				
				DocumentObject.PostInAccounting = True;
				DocumentObject.RecordInLocalAccounting = True;
				
			EndIf;
					
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(DocumentObject.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
		EndTry;
		
	EndDo;
	
 	NonCurrentAssetsInternal.CheckHandlerExecution(
 		ObjectsWithIssuesCount, 
 		ObjectsProcessed, 
 		FullObjectName);
 		
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ObjectsProcessed);	
	
EndProcedure
 
#EndRegion

#EndRegion

#EndIf
