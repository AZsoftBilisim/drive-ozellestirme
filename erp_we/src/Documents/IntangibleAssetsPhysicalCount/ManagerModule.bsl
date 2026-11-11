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
	
	DocumentMechanisms.Add("IntangibleAssets");
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
	
	If TypeOf(Document) = Type("DocumentObject.IntangibleAssetsPhysicalCount") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers);
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.IntangibleAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Order = 1;
	EndIf;
	
	Command = Documents.IATransfer2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Order = 2;
	EndIf;
	
	Command = Documents.IARevaluation2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Order = 3;
	EndIf;
	
	Command = Documents.DisposeIntangibleAssets2_4.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Order = 4;
	EndIf;
	
EndProcedure

// Adds the command to create the document "IA Inventory".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.IntangibleAssetsPhysicalCount) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IntangibleAssetsPhysicalCount.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IntangibleAssetsPhysicalCount);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
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

// Returns IA accounting data.
//
// Parameters:
//  Parameters - Structure - The operation parameters.
//
// Returns:
//  Map of KeyAndValue - Contains accounting data: 
//  	* Key - CatalogRef.IntangibleAssets -
//  	* Value - Structure - 
//
Function DataOfAccounting(Parameters) Export

	If Parameters.Property("ListOfIA") And Parameters.ListOfIA.Count() = 0 Then
		Return New Map;
	EndIf;
	
	QueryText = 
	"SELECT
	|	ListOfIA.IntangibleAsset AS IntangibleAsset
	|
	|INTO IAState
	|
	|FROM
	|	(SELECT
	|		IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset AS IntangibleAsset
	|	FROM
	|		InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|				&Date,
	|				&RecordInManAccounting
	|					AND Organization = &Organization
	|					AND (NOT &AccordingToIAList OR IntangibleAsset IN (&ListOfIA))) AS IntangibleAssetsAccountingProcedureManagementAccounting
	|	WHERE
	|		IntangibleAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting) 
	|
	|	UNION ALL
	|
	|	SELECT
	|		IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset AS IntangibleAsset
	|	FROM
	|		InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|				&Date,
	|				&RecordInLocalAccounting
	|					AND Organization = &Organization
	|					AND (NOT &AccordingToIAList OR IntangibleAsset IN (&ListOfIA))) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|	WHERE
	|		(&PostInAccounting
	|				AND IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
	|			OR &RecordInTA
	|				AND IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting))
	|
	|	) AS ListOfIA
	|
	|WHERE
	|	ListOfIA.IntangibleAsset.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|
	|GROUP BY
	|	ListOfIA.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsRegistrationPlace.Organization AS Organization,
	|	IntangibleAssetsRegistrationPlace.Department AS Department,
	|	IntangibleAssetsRegistrationPlace.IntangibleAsset AS IntangibleAsset
	|
	|INTO ListOfIA
	|
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
	|		&Date, 
	|		IntangibleAsset IN
	|				(SELECT
	|					IAState.IntangibleAsset
	|				FROM
	|					IAState)) AS IntangibleAssetsRegistrationPlace
	|
	|WHERE
	|	(&AccordingToIAList
	|		OR IntangibleAssetsRegistrationPlace.Organization = &Organization
	|				AND IntangibleAssetsRegistrationPlace.Department = &Department)
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IACost.Organization AS Organization,
	|	IACost.Department AS Department,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|	IACost.CostBalance AS CostByAccountingDataMA,
	|	IACost.LocalCostBalance + IACost.CostTargetFinancingBalance AS CostByAccountingDataLA,
	|	IACost.CostInTaxAccountingBalance AS CostByAccountingDataTA
	|
	|INTO IACost
	|
	|FROM
	|	AccumulationRegister.IACost.Balance(
	|			&Date,
	|			(IntangibleAsset, Organization, Department) IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset,
	|					ListOfIA.Organization,
	|					ListOfIA.Department
	|				FROM
	|					ListOfIA)) AS IACost
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfIA.IntangibleAsset AS IntangibleAsset,
	|	ListOfIA.Organization AS Organization,
	|	ListOfIA.Department AS Department,
	|
	|	CASE
	|		WHEN NOT &RecordInManAccounting
	|			THEN 0
	|		ELSE ISNULL(IACost.CostByAccountingDataMA, 0)
	|	END AS CostByAccountingDataMA,
	|
	|	CASE
	|		WHEN NOT &PostInAccounting
	|			THEN 0
	|		ELSE ISNULL(IACost.CostByAccountingDataLA, 0)
	|	END AS CostByAccountingDataLA,
	|
	|	CASE
	|		WHEN NOT &RecordInTA
	|			THEN 0
	|		ELSE ISNULL(IACost.CostByAccountingDataTA, 0)
	|	END AS CostByAccountingDataTA
	|
	|FROM
	|	ListOfIA AS ListOfIA
	|
	|		LEFT JOIN IACost AS IACost
	|		ON (IACost.IntangibleAsset = ListOfIA.IntangibleAsset)
	|			AND (IACost.Organization = ListOfIA.Organization)
	|			AND (IACost.Department = ListOfIA.Department)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("ListOfIA", ?(Parameters.Property("ListOfIA"), Parameters.ListOfIA, New Array));
	Query.SetParameter("AccordingToIAList", ?(Parameters.Property("ListOfIA"), True, False));
	Query.SetParameter("Date", ?(ValueIsFilled(Parameters.Date), EndOfDay(Parameters.Date), EndOfDay(CurrentSessionDate())));
	Query.SetParameter("RecordInManAccounting", Parameters.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Parameters.PostInAccounting Or Parameters.RecordInTA);
	Query.SetParameter("PostInAccounting", Parameters.PostInAccounting);
	Query.SetParameter("RecordInTA", Parameters.RecordInTA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	CurCurrentAccountingData = New Map;
	
	InterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Parameters.Organization);

	While Selection.Next() Do
		
		DataOfAccounting = New Structure;
		DataOfAccounting.Insert("Organization", Selection.Organization);
		DataOfAccounting.Insert("Department", Selection.Department);
		DataOfAccounting.Insert("CostByAccountingDataLA", Selection.CostByAccountingDataLA);
		DataOfAccounting.Insert("CostByAccountingDataTA", Selection.CostByAccountingDataTA);
		DataOfAccounting.Insert("CostByAccountingDataMA", Selection.CostByAccountingDataMA);
		
		Interconnected = (Selection.Organization = Parameters.Organization Or InterconnectedOrganizations.Find(Selection.Organization) <> Undefined);
		DataOfAccounting.Insert("Interconnected", Interconnected);
		
		CurCurrentAccountingData.Insert(Selection.IntangibleAsset, DataOfAccounting);
	
	EndDo;

	Return CurCurrentAccountingData;
	
EndFunction

Function FillInAccountingData(Object, RowsCollection, FillInServiceDetails = False) Export

	ListOfIA = New Array;
	For Each RowData In RowsCollection Do
		ListOfIA.Add(RowData.IntangibleAsset);
	EndDo; 
	
	PhysicalInventoryCountParameters = New Structure;
	PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
	PhysicalInventoryCountParameters.Insert("Department", Object.Department);
	PhysicalInventoryCountParameters.Insert("Date", Object.Date);
	PhysicalInventoryCountParameters.Insert("ListOfIA", ListOfIA);
	PhysicalInventoryCountParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	PhysicalInventoryCountParameters.Insert("PostInAccounting", Object.PostInAccounting);
	PhysicalInventoryCountParameters.Insert("RecordInTA", Object.RecordInTA);

	AccountingDataByLine = DataOfAccounting(PhysicalInventoryCountParameters);
	
	For Each RowData In RowsCollection Do
		
		DataOfAccounting = AccountingDataByLine.Get(RowData.IntangibleAsset);
		
		NonCurrentAssetsClientServer.FillInAccountingDataInLineOfInventoryOfIntangibleAssetPhysicalInventory(RowData, DataOfAccounting, PhysicalInventoryCountParameters);
		
		NonCurrentAssetsClientServer.FillInActionBasedOnIntangibleAssetPhysicalInventory(RowData, Object, DataOfAccounting);
		
	EndDo; 

	Return AccountingDataByLine;
	
EndFunction

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IntangibleAssetsPhysicalCountLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	IntangibleAssetsPhysicalCountLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
		
EndProcedure

#EndRegion

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
	
	FullDocumentName = "Document.IntangibleAssetsPhysicalCount";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, RegisterName);
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
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
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
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.IntangibleAssetsPhysicalCount AS DocumentData
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IntangibleAssetsPhysicalCount"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.IntangibleAssetsPhysicalCount);

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

Function QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(TabularSection.LineNumber-1, 0)  AS RecNo,
	|	&Ref                               AS Ref,
	|	&Period                               AS Date,
	|	&Organization                          AS Organization,
	|	&Department                        AS Department,
	|	&Posted                             AS Posted,
	|	&BusinessOperation                AS BusinessOperation,
	|	&MetadataIdentifier              AS RefType,
	|	&PostInAccounting                          AS RecordInLocalAccounting,
	|	&RecordInTA                          AS RecordInTA,
	|	&RecordInManAccounting                    AS RecordInManAccounting,
	|	TabularSection.IntangibleAsset    AS IntangibleAsset
	|FROM
	|	Document.IntangibleAssetsPhysicalCount AS DocumentData
	|		LEFT JOIN Document.IntangibleAssetsPhysicalCount.IA AS TabularSection
	|		ON TabularSection.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

// Returns data for filling in the document based on the IA inventory.
//
// Parameters:
// 		DocumentBasis - DocumentRef.IntangibleAssetsPhysicalCount - Link to the inventory document.
// 		Date - Date	- Date of filling.
// 		Action - EnumRef.ActionsBasedOnPhysicalInventoryCount - action.
// 		ArrayOfLineNumbers - Array - An array with line numbers based on which to fill out the document.
//
// Returns:
//  Structure - Contains:
//  	* Attributes - ValueTable - 
//  	* TabularSection - ValueTable - 
//
Function FillingDataBasedOnInventory(DocumentBasis, Date, Action, Val ArrayOfLineNumbers = Undefined) Export
	
	DataToFill = New Structure("Attributes, TabularSection");

	// Filling in the header.
	QueryText =
	"SELECT
	|	IntangibleAssetsPhysicalCount.Date AS DocumentDate,
	|	IntangibleAssetsPhysicalCount.Organization AS Organization,
	|	IntangibleAssetsPhysicalCount.Department AS Department,
	|	IntangibleAssetsPhysicalCount.RecordInManAccounting AS RecordInManAccounting,
	|	IntangibleAssetsPhysicalCount.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	IntangibleAssetsPhysicalCount.PostInAccounting AS PostInAccounting,
	|	IntangibleAssetsPhysicalCount.RecordInTA AS RecordInTA
	|FROM
	|	Document.IntangibleAssetsPhysicalCount AS IntangibleAssetsPhysicalCount
	|
	|WHERE
	|	IntangibleAssetsPhysicalCount.Ref = &Ref
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
	QueryText =
	"SELECT 
	|	IntangibleAssetsPhysicalCount.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsPhysicalCount.CostByAccountingDataLA AS CostByAccountingDataLA,
	|	IntangibleAssetsPhysicalCount.CostByAccountingDataTA AS CostByAccountingDataTA,
	|	IntangibleAssetsPhysicalCount.CostByAccountingDataMA AS CostByAccountingDataMA,
	|	IntangibleAssetsPhysicalCount.ActualCostAC AS ActualCostAC,
	|	IntangibleAssetsPhysicalCount.ActualCostTA AS ActualCostTA,
	|	IntangibleAssetsPhysicalCount.CostActualMan AS CostActualMan,
	|	IntangibleAssetsPhysicalCount.LAAction AS LAAction,
	|	IntangibleAssetsPhysicalCount.TAAction AS TAAction,
	|	IntangibleAssetsPhysicalCount.MAAction AS MAAction
	|
	|INTO TTTableOfIa
	|
	|FROM 
	|	Document.IntangibleAssetsPhysicalCount.IA AS IntangibleAssetsPhysicalCount
	|
	|WHERE
	|	IntangibleAssetsPhysicalCount.Ref = &DocumentBasis
	|
	|	AND (NOT &ArrayOfLineNumbersIsSet
	|			OR IntangibleAssetsPhysicalCount.LineNumber IN (&ArrayOfLineNumbers))
	|	AND (IntangibleAssetsPhysicalCount.LAAction = &Action
	|			OR IntangibleAssetsPhysicalCount.TAAction = &Action
	|			OR IntangibleAssetsPhysicalCount.MAAction = &Action)
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsRegistrationPlace.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsRegistrationPlace.Organization AS Organization,
	|	IntangibleAssetsRegistrationPlace.Department AS Department
	|
	|INTO TTPlaceOfIaAccounting
	|
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
	|			&Date,
	|			IntangibleAsset IN (
	|					SELECT 
	|						TTTableOfIa.IntangibleAsset 
	|					FROM 
	|						TTTableOfIa AS TTTableOfIa)) AS IntangibleAssetsRegistrationPlace
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentsBasedOn.Ref) AS Ref,
	|	DocumentsBasedOn.IntangibleAsset AS IntangibleAsset,
	|	DocumentsBasedOn.Action AS Action,
	|	DocumentsBasedOn.Department AS Department,
	|	DocumentsBasedOn.ReceivingBusinessUnit AS ReceivingBusinessUnit
	|
	|INTO TTDocumentsBasedOn
	|
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		TabularSection.IntangibleAsset AS IntangibleAsset,
	|		VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Move) AS Action,
	|		DocumentData.ReceivingBusinessUnit AS Department,
	|		DocumentData.Department AS ReceivingBusinessUnit
	|
	|	FROM
	|		Document.IATransfer2_4 AS DocumentData
	|	
	|			INNER JOIN Document.IATransfer2_4.IA AS TabularSection
	|			ON DocumentData.Ref = TabularSection.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &DocumentBasis
	|		AND VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Move) = &Action
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Ref,
	|		DocumentData.IntangibleAsset,
	|		VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Recognition),
	|		DocumentData.Department,
	|		DocumentData.Department
	|	FROM
	|		Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &DocumentBasis
	|		AND VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Recognition) = &Action
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Ref,
	|		TabularSection.IntangibleAsset,
	|		VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff),
	|		DocumentData.Department,
	|		DocumentData.Department
	|	FROM
	|		Document.DisposeIntangibleAssets2_4 AS DocumentData
	|
	|			INNER JOIN Document.DisposeIntangibleAssets2_4.IA AS TabularSection
	|			ON DocumentData.Ref = TabularSection.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &DocumentBasis
	|		AND VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff) = &Action
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Ref,
	|		TabularSection.IntangibleAsset,
	|		VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation),
	|		DocumentData.Department,
	|		DocumentData.Department
	|	FROM
	|		Document.IARevaluation2_4 AS DocumentData
	|
	|			INNER JOIN Document.IARevaluation2_4.IA AS TabularSection
	|			ON DocumentData.Ref = TabularSection.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &DocumentBasis
	|		AND VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation) = &Action
	|
	|	) AS DocumentsBasedOn
	|
	|GROUP BY
	|	DocumentsBasedOn.IntangibleAsset,
	|	DocumentsBasedOn.Action,
	|	DocumentsBasedOn.Department,
	|	DocumentsBasedOn.ReceivingBusinessUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTableOfIa.IntangibleAsset AS IntangibleAsset,
	|
	|	TTTableOfIa.CostByAccountingDataLA AS CostByAccountingDataLA,
	|	TTTableOfIa.CostByAccountingDataTA AS CostByAccountingDataTA,
	|	TTTableOfIa.CostByAccountingDataMA AS CostByAccountingDataMA,
	|
	|	CASE
	|		WHEN TTTableOfIa.LAAction = &Action
	|			THEN TTTableOfIa.ActualCostAC
	|		ELSE 0
	|	END AS ActualCostAC,
	|
	|	CASE
	|		WHEN TTTableOfIa.TAAction = &Action
	|			THEN TTTableOfIa.ActualCostTA
	|		ELSE 0
	|	END AS ActualCostTA,
	|
	|	CASE
	|		WHEN TTTableOfIa.MAAction = &Action
	|			THEN TTTableOfIa.CostActualMan
	|		ELSE 0
	|	END AS CostActualMan,
	|
	|	TTPlaceOfIaAccounting.Organization AS LocationOrganization,
	|	TTPlaceOfIaAccounting.Department AS LocationDivision,
	|
	|	CASE
	|		WHEN TTTableOfIa.LAAction = &Action
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PostInAccounting,
	|
	|	CASE
	|		WHEN TTTableOfIa.TAAction = &Action
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecordInTA,
	|
	|	CASE
	|		WHEN TTTableOfIa.MAAction = &Action
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecordInManAccounting
	|
	|FROM
	|	TTTableOfIa AS TTTableOfIa
	|
	|		LEFT JOIN TTDocumentsBasedOn AS DocumentsBasedOn
	|		ON DocumentsBasedOn.IntangibleAsset = TTTableOfIa.IntangibleAsset
	|			AND DocumentsBasedOn.Action = &Action
	|
	|		LEFT JOIN TTPlaceOfIaAccounting AS TTPlaceOfIaAccounting
	|		ON TTPlaceOfIaAccounting.IntangibleAsset = TTTableOfIa.IntangibleAsset
	|
	|WHERE
	|	DocumentsBasedOn.Ref IS NULL
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", Date);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("Action", Action);
	Query.SetParameter("ArrayOfLineNumbers", ?(ArrayOfLineNumbers = Undefined, New Array, ArrayOfLineNumbers));
	Query.SetParameter("ArrayOfLineNumbersIsSet", ?(ArrayOfLineNumbers = Undefined, False, True));
	
	DataToFill.Insert("TabularSection", Query.Execute().Unload());
	
	Return DataToFill;
	
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
	Handler.Procedure = "Documents.IntangibleAssetsPhysicalCount.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e22e6777-0f9c-4dea-9ea4-58813c9e984f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.IntangibleAssetsPhysicalCount.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Kiểm kê TSCĐVH"":
								  |- điền các mục tin phản ánh trong kế toán.';
								  |ru = 'Обновляет документы ""Инвентаризация НМА"":
								  |- заполняет реквизиты отражения в учете.';
								  |en = 'Updates the ""Intangible assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.'; fa = 'Updates the ""Intangible assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.';
								  |it = 'Updates the ""Intangible assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.';
								  |pl = 'Updates the ""Intangible assets — Physical inventory"" documents:
								  |- Fills in the accounting attributes.';
								  |tr = '""Maddi Olmayan Varlık Stok Sayımı"" belgelerini günceller: 
								  | - muhasebede yansıtma özniteliklerini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsPhysicalCount.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.IntangibleAssetsPhysicalCount.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.IntangibleAssetsPhysicalCount.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.IntangibleAssetsPhysicalCount";
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
	|		Document.IntangibleAssetsPhysicalCount AS DocumentData
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
		"Document.IntangibleAssetsPhysicalCount.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.IntangibleAssetsPhysicalCount";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.IntangibleAssetsPhysicalCount
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
