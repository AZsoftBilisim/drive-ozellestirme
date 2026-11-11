#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	If Not Document.DynamicStructure Then
		Return Parameters;
	EndIf;
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ProductionOrders);
	EndIf;
	
	Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.OrderStructure);
	Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.OrderStructureLaborCosts);
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of production.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProductionOrders");
	
EndProcedure

// The procedure of formation of movements on the register.
//
// Parameters:
//  TablesForRegisteredRecords		 - Structure				 - document data tables
//  Document				 - DocumentRef			 - link to the document
//  TempTablesManager	 - TempTablesManager	 - Manager temporary tables in the document
//  Cancel					 - Boolean					 - indicates that the document was rejected.
//  CalculateChanges_	 - Boolean					 - True, if there is a need to calculate the result of changes in movements.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel, CalculateChanges_ = True) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	DocumentID = Document.UUID();
	
	TableOrderStructure = Undefined;
	
	If TablesForRegisteredRecords.Property("Table" + "OrderStructure", TableOrderStructure) Then
		WriteDownProductList(DocumentID, TableOrderStructure, CalculateChanges_);
	EndIf;
	
	TableLaborCostsOfOrderStructure = Undefined;
	
	If TablesForRegisteredRecords.Property("Table" + "OrderStructureLaborCosts", TableLaborCostsOfOrderStructure) Then
		RecordLaborCosts(DocumentID, TableLaborCostsOfOrderStructure);
	EndIf;
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	Return; // no additional actions are provided in the current configuration
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	Return; // no additional actions are provided in the current configuration
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region Posting

Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // no additional actions are provided in the current configuration
	
EndProcedure

Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // no additional actions are provided in the current configuration
	
EndProcedure

#EndRegion

#Region ProductionsOrder

// Preparation of data for the calculation of the dynamic structure of the production order.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  AdditionalProperties - Structure - additional document properties.
//  Cancel - Boolean - flag for refusing to write
//
Procedure ProductionOrderBeforeWrite(Document, AdditionalProperties, Cancel) Export
	
	If Not Document.DynamicStructure Then
		Return;
	EndIf;
	
	SetProductKeyInRowsOfTablePart(Document, "ManufacturedProduct");
	
	TemporaryTableManagerOrderStructure = New TempTablesManager;
	
	Query = New Query();
	Query.TempTablesManager = TemporaryTableManagerOrderStructure;
	Query.SetParameter("Ref", Document.Ref);
	Query.SetParameter("IsNew", Document.IsNew());
	Query.Text = 
		"SELECT
		|	TabularSection.Products                                               AS Products,
		|	TabularSection.Characteristic                                             AS Characteristic,
		|	CASE
		|		WHEN TabularSection.Products.ItemsType IN (
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			AND NOT TabularSection.ToExpenseAs THEN
		|		TabularSection.Warehouse
		|	WHEN TabularSection.ToExpenseAs
		|		OR TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|		TabularSection.Department
		|	ELSE
		|		UNDEFINED
		|	END                                                                     AS Warehouse,
		|	TabularSection.Purpose                                                 AS Purpose,
		|	TabularSection.Ref                                                     AS ProductionOrder,
		|	TabularSection.KeyProducts                                           AS KeyProducts,
		|	TabularSection.BillOfMaterials                                               AS BillOfMaterials,
		|	TabularSection.DemandDate                                            AS DemandDate,
		|	TabularSection.Count                                                 AS Count
		|INTO OrderProducts_BeforeWrite
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|WHERE
		|	TabularSection.Ref = &Ref
		|		AND NOT TabularSection.Canceled
		|		AND NOT &IsNew";
	Query.Execute();
	
	AdditionalProperties.Insert("TemporaryTableManagerOrderStructure", TemporaryTableManagerOrderStructure);
	
EndProcedure

// Recording data for the calculation of the dynamic structure of the production order.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  AdditionalProperties - Structure - additional document properties.
//  Cancel - Boolean - flag for refusing to write
//
Procedure ProductionOrderForRecording(Document, AdditionalProperties, Cancel) Export
	
	If Not Document.DynamicStructure Then
		Return;
	EndIf;
	
	TemporaryTableManagerOrderStructure = AdditionalProperties.TemporaryTableManagerOrderStructure;
	
	Query = New Query();
	Query.SetParameter("Ref", Document.Ref);
	Query.TempTablesManager = TemporaryTableManagerOrderStructure;
	
	Query.Text =
	"SELECT
	|	ChangesTable.Products         AS Products,
	|	ChangesTable.Characteristic       AS Characteristic,
	|	ChangesTable.Warehouse                AS Warehouse,
	|	ChangesTable.Purpose           AS Purpose,
	|	ChangesTable.ProductionOrder  AS ProductionOrder,
	|	ChangesTable.KeyProducts     AS KeyProducts,
	|	ChangesTable.BillOfMaterials         AS BillOfMaterials,
	|	ChangesTable.DemandDate      AS DemandDate,
	|	SUM(ChangesTable.Count)          AS Count,
	|	SUM(ChangesTable.CountUpdate) AS CountUpdate
	|INTO ChangeOrderMANUFACTUREDProducts
	|FROM
	|	(SELECT
	|		TabularSection.Products                                               AS Products,
	|		TabularSection.Characteristic                                             AS Characteristic,
	|		TabularSection.Warehouse                                                      AS Warehouse,
	|		TabularSection.Purpose                                                 AS Purpose,
	|		TabularSection.ProductionOrder                                        AS ProductionOrder,
	|		TabularSection.KeyProducts                                           AS KeyProducts,
	|		TabularSection.BillOfMaterials                                               AS BillOfMaterials,
	|		TabularSection.DemandDate                                            AS DemandDate,
	|		0                                                                         AS Count,
	|		-TabularSection.Count                                                AS CountUpdate
	|	FROM
	|		OrderProducts_BeforeWrite AS TabularSection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TabularSection.Products                                               AS Products,
	|		TabularSection.Characteristic                                             AS Characteristic,
	|		CASE
	|			WHEN TabularSection.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|				AND NOT TabularSection.ToExpenseAs THEN
	|			TabularSection.Warehouse
	|		WHEN TabularSection.ToExpenseAs
	|			OR TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
	|			TabularSection.Department
	|		ELSE
	|			UNDEFINED
	|		END                                                                     AS Warehouse,
	|		TabularSection.Purpose                                                 AS Purpose,
	|		TabularSection.Ref                                                     AS ProductionOrder,
	|		TabularSection.KeyProducts                                           AS KeyProducts,
	|		TabularSection.BillOfMaterials                                               AS BillOfMaterials,
	|		TabularSection.DemandDate                                            AS DemandDate,
	|		TabularSection.Count                                                 AS Count,
	|		TabularSection.Count                                                 AS CountUpdate
	|	FROM
	|		Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
	|	WHERE
	|		TabularSection.Ref = &Ref
	|			AND NOT TabularSection.Canceled
	|
	|) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Warehouse,
	|	ChangesTable.Purpose,
	|	ChangesTable.ProductionOrder,
	|	ChangesTable.KeyProducts,
	|	ChangesTable.BillOfMaterials,
	|	ChangesTable.DemandDate
	|
	|HAVING
	|	SUM(ChangesTable.CountUpdate) <> 0
	|";
	Query.Execute().IsEmpty();
	
	WriteDownTasksForCalculatingProductionSchedule(Document, AdditionalProperties, TemporaryTableManagerOrderStructure);
	
	UpdateProductionScheduleWhenRecordingOrder(Document, TemporaryTableManagerOrderStructure);
	
	TemporaryTableManagerOrderStructure.Close();
	
EndProcedure

#EndRegion

#Region ProductionStage

// Preparation of data for the calculation of the dynamic structure of the production order.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  AdditionalProperties - Structure - additional document properties.
//  Cancel - Boolean - flag for refusing to write
//
Procedure ProductionStageBeforeWrite(Document, AdditionalProperties, Cancel) Export
	
	If Not Document.DynamicStructure Then
		Return;
	EndIf;
	
	SetProductKeyInRowsOfTablePart(Document, "SupplyWithMaterialsAndWorks,ManufacturedProducts,SideAndIntermediateRelease");
	
	SetWorkTypeKeyInRowsOfTablePart(Document, "LaborCosts");
	
EndProcedure

// Recording data for the calculation of the dynamic structure of the production order.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  AdditionalProperties - Structure - additional document properties.
//  Cancel - Boolean - flag for refusing to write
//
Procedure StageOfProductionDuringRecording(Document, AdditionalProperties, Cancel) Export
	
	If Not Document.DynamicStructure Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region WhenSoftwareChanges

// Generates tasks for calculating the structure of the production order based on movements in the security registers.
//
// Parameters:
//  Document - DocumentObject - the Registrar registers the movements
//  TempTablesManager - TempTablesManager - a temporary table Manager that contains tables of register changes.
//
Procedure CreateTasksForCalculatingStructureOfOrderDistributionOfInventoryWhenWritingDocument(Document, TempTablesManager) Export
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Or InventoryAllocation.CountRegisterWithRoutineTask() Then
		Return;
	EndIf;
	
	StartCalculation = False;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "InventoryAndDemandsUpdate") Then
		StartCalculation = True;
		Query = New Query(
		"SELECT DISTINCT
		|	&Queue               AS Queue,
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.Purpose     AS Purpose
		|FROM
		|	InventoryAndDemandsUpdate AS Table
		|WHERE
		|	Table.Warehouse NOT IN (
		|		UNDEFINED,
		|		VALUE(Catalog.Warehouses.EmptyRef),
		|		VALUE(Catalog.BusinessStructure.EmptyRef))
		|");
		OrderStructureCalculationQueue = 0;
		Document.AdditionalProperties.Property("OrderStructureCalculationQueue", OrderStructureCalculationQueue);
		Query.SetParameter("Queue", OrderStructureCalculationQueue);
		Query.TempTablesManager = TempTablesManager;
		InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(Query.Execute().Unload());
	EndIf;
	
	If StartCalculation Then
		OrderStructure.StartCalculation();
	EndIf;

EndProcedure

// Generates tasks for calculating the structure of the production order during batch formation of stages.
//
// Parameters:
//  References	 - Array	 - formed production stages.
//  Queue	 - Number	 - The current queue number for calculating the order structure.
//
Procedure GenerateTasksBatchGenerationOfStages(References, Queue) Export

	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Return;
	EndIf;
	
	IDs = New Array();
	
	For Each Ref In References Do
		IDs.Add(Ref.UUID());
	EndDo;
	
	// to reduce the number of cycles of recalculation of the structure, the materials are placed in the next queue (the materials need to be processed after the products)
	QueueMaterials = ?(Queue = 0, 0, Queue + 1);
	Query = New Query;
	Query.Text =
		"SELECT DISTINCT
		|	&Queue                            AS Queue,
		|	OrderStructure.Products        AS Products,
		|	OrderStructure.Characteristic      AS Characteristic,
		|	OrderStructure.Warehouse               AS Warehouse,
		|	OrderStructure.Purpose          AS Purpose,
		|	CASE
		|		WHEN OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) THEN
		|			UNDEFINED
		|		ELSE
		|			CAST(OrderStructure.Stage AS Document.ProductionStage2_2).ProductionLot.MainProductProducts
		|	END AS ProductsItems
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.KeySet IN(&IDs) AND OrderStructure.ToSupply <> 0";
	Query.SetParameter("Queue", QueueMaterials);
	Query.SetParameter("IDs", IDs);
	InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(Query.Execute().Unload());
	
EndProcedure

#EndRegion

#Region Substitutions

// Generates the text of the field for receiving the free issue assignment
// 
// Parameters:
// 	PathToOrderField - String - path to the "Production order" field
// Returns:
// 	String - LongDesc
Function TextOfFreeReleaseAssignmentField(PathToOrderField = "Table.ProductionOrder") Export
	
	FieldText =
		"CASE
		|	WHEN Orders.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.TollManufacturing2_5))
		|			AND Orders.OptionOfAssignment IN ( VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
		|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
		|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
		|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
		|	
		|		THEN
		|			Orders.Purpose
		|	
		|	ELSE
		|		VALUE(Catalog.Assignments.EmptyRef)
		|END";
	
	FieldText = StrReplace(FieldText, "Orders", PathToOrderField);
	
	Return FieldText;
	
EndFunction

// Generates the text of the field for receiving the assignment of the order materials
// 
// Parameters:
// 	PathToOrderField - String - path to the "Production order" field
// 	PathToTheDestinationField - String - path to the "Product assignment" field
// Returns:
// 	String - LongDesc
Function TextOfMaterialsAssignmentField(PathToOrderField = "Table.ProductionOrder", PathToTheDestinationField = "Table.Purpose") Export
	
	FieldText =
		"CASE
		|	WHEN
		|		Orders.OptionOfAssignment = VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts)
		|		   AND &AssignmentProducts <> VALUE(Catalog.Assignments.EmptyRef)
		|		THEN &AssignmentProducts
		|	ELSE CASE
		|			WHEN Orders.OptionOfAssignment IN (
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionStage),
		|					VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
		|				THEN Orders.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END
		|	END";
	
	FieldText = StrReplace(
		FieldText,
		"&AssignmentProducts",
		StrReplace(
			"CASE
			|	WHEN Orders.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
			|		THEN
			|			Orders.AssignmentProducts
			|		ELSE
			|			&Purpose
			|END",
			"&Purpose",
			PathToTheDestinationField));
	FieldText = StrReplace(FieldText, "Orders", PathToOrderField);
	
	Return FieldText;
	
EndFunction

// Generates the text of the field for checking the status of the production order
// 
// Parameters:
// 	PathToOrderField - String - path to the "Order" field
// Returns:
// 	String - LongDesc
Function TextOfOrderFieldHasBeenSubmittedForProduction(PathToOrderField = "") Export
	
	FieldText =
	"(Table.Posted
	|	AND Table.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
	|)";
	
	If Not IsBlankString(PathToOrderField) Then
		FieldText = StrReplace(FieldText, "Table", PathToOrderField);
	EndIf;
	
	Return FieldText;
	
EndFunction

#EndRegion

#Region Other

Procedure SetProductKeyInRowsOfTablePart(Document, NamesOfTS, NeedControl = True) Export
	
	If IsBlankString(NamesOfTS) Then
		ArrayTS = New Array();
	Else
		ArrayTS = StrSplit(NamesOfTS, ",", False);
	EndIf;
	
	For Each TSName In ArrayTS Do
	
		NewLines = Document[TSName].FindRows(New Structure("KeyProducts", New UUID("00000000-0000-0000-0000-000000000000")));
		
		For Each NewRow In NewLines Do
			NewRow.KeyProducts = New UUID();
		EndDo;
		
		If NeedControl Then
		
			Validation = Document[TSName].Unload(, "KeyProducts"); // ValueTable
			Validation.Columns.Add("Counter");
			Validation.FillValues(1, "Counter");
			Validation.GroupBy("KeyProducts", "Counter");
			If Validation.Count() <> Validation.FindRows(New Structure("Counter", 1)).Count() Then
				ErrorText = NStr("vi = 'Tên định danh nội bộ của các dòng không được trùng nhau!';
								|ru = 'Внутренние идентификаторы строк не должны повторяться!';
								|en = 'Internal row IDs must not be repeated.'; fa = 'Internal row IDs must not be repeated.';
								|it = 'Gli ID interni delle righe non devono ripetersi!';
								|pl = 'Wewnętrzne identyfikatory wierszy nie powinny powtarzać się!';
								|tr = 'Dahili satır tanımlayıcıları tekrarlanmamalıdır!'");
				Raise ErrorText;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetWorkTypeKeyInRowsOfTablePart(Document, TSName, NeedControl = True) Export
	
	NewLines = Document[TSName].FindRows(New Structure("KeyWorkType", New UUID("00000000-0000-0000-0000-000000000000")));
	
	For Each NewRow In NewLines Do
		NewRow.KeyWorkType = New UUID();
	EndDo;
	
	If NeedControl Then
	
		Validation = Document[TSName].Unload(, "KeyWorkType"); // ValueTable
		Validation.Columns.Add("Counter");
		Validation.FillValues(1, "Counter");
		Validation.GroupBy("KeyWorkType", "Counter");
		If Validation.Count() <> Validation.FindRows(New Structure("Counter", 1)).Count() Then
			ErrorText = NStr("vi = 'Tên định danh nội bộ của các dòng không được trùng nhau!';
							|ru = 'Внутренние идентификаторы строк не должны повторяться!';
							|en = 'Internal row IDs must not be repeated.'; fa = 'Internal row IDs must not be repeated.';
							|it = 'Gli ID interni delle righe non devono ripetersi!';
							|pl = 'Wewnętrzne identyfikatory wierszy nie powinny powtarzać się!';
							|tr = 'Dahili satır tanımlayıcıları tekrarlanmamalıdır!'");
			Raise ErrorText;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ClearRowKeysInTablePart(Document, NamesOfTS, FieldName) Export
	
	EmptyStringKey = New UUID("00000000-0000-0000-0000-000000000000");
	
	If IsBlankString(NamesOfTS) Then
		ArrayTS = New Array();
	Else
		ArrayTS = StrSplit(NamesOfTS, ",", False);
	EndIf;
	
	For Each TSName In ArrayTS Do
	
		For Each String In Document[TSName] Do
			String[FieldName] = EmptyStringKey;
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Posting

Procedure WriteDownProductList(DocumentID, DocumentRegisterRecords, CalculateChanges_ = True)
	
	If CalculateChanges_ Then
		
		Query = New Query();
		Query.TempTablesManager = New TempTablesManager();
		Query.Text = 
		"SELECT
		|	RegisterRecords.Products              AS Products,
		|	RegisterRecords.Characteristic            AS Characteristic,
		|	RegisterRecords.Warehouse                     AS Warehouse,
		|	RegisterRecords.Purpose                AS Purpose,
		|	RegisterRecords.ProductionOrder       AS ProductionOrder,
		|	RegisterRecords.KeyProducts          AS KeyProducts,
		|	RegisterRecords.KeyLot                AS KeyLot,
		|	RegisterRecords.LineKind                 AS LineKind,
		|	RegisterRecords.ReceiptOrder        AS ReceiptOrder,
		|	RegisterRecords.DateOfReceipt           AS DateOfReceipt,
		|	RegisterRecords.KeySet                 AS KeySet,
		|	RegisterRecords.Level                   AS Level,
		|	RegisterRecords.DurationBeforeProductionIssue     AS DurationBeforeProductionIssue,
		|	RegisterRecords.Department             AS Department,
		|	RegisterRecords.Stage                      AS Stage,
		|	RegisterRecords.BillOfMaterials              AS BillOfMaterials,
		|	RegisterRecords.SemiFinishedProductBOM AS SemiFinishedProductBOM,
		|	RegisterRecords.StructureAssignment       AS StructureAssignment,
		|	RegisterRecords.Launched                  AS Launched,
		|	RegisterRecords.ToSupply              AS ToSupply,
		|	RegisterRecords.Done                    AS Done,
		|	RegisterRecords.NotProvide            AS NotProvide
		|
		|INTO TrafficOrderStructureBeforeWrite
		|FROM
		|	InformationRegister.OrderStructure AS RegisterRecords
		|WHERE
		|	RegisterRecords.KeySet = &DocumentID
		|";
		Query.SetParameter("DocumentID", DocumentID);
		
		Block = New DataLock();
		Block.Add("InformationRegister.OrderStructure").SetValue("KeySet", DocumentID);
		Block.Lock();
		
		Query.Execute();
		
	EndIf;
	
	RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
	RecordSet.Filter.KeySet.Set(DocumentID);
	RecordSet.Load(DocumentRegisterRecords);
	RecordSet.Write(True);
	
	If CalculateChanges_ Then
	
		Query.Text =
		"SELECT DISTINCT
		|	ChangesTable.Products AS Products,
		|	ChangesTable.Characteristic AS Characteristic,
		|	ChangesTable.Warehouse AS Warehouse,
		|	ChangesTable.Purpose AS Purpose,
		|	ChangesTable.ProductionOrder AS ProductionOrder
		|FROM (
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.ProductionOrder AS ProductionOrder,
		|		RegisterRecords.KeyProducts AS KeyProducts,
		|		RegisterRecords.KeyLot AS KeyLot,
		|		RegisterRecords.LineKind AS LineKind,
		|		RegisterRecords.ReceiptOrder AS ReceiptOrder,
		|		RegisterRecords.DateOfReceipt AS DateOfReceipt,
		|		RegisterRecords.KeySet AS KeySet,
		|		RegisterRecords.Level AS Level,
		|		RegisterRecords.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
		|		RegisterRecords.Department AS Department,
		|		RegisterRecords.Stage AS Stage,
		|		RegisterRecords.BillOfMaterials AS BillOfMaterials,
		|		RegisterRecords.SemiFinishedProductBOM AS SemiFinishedProductBOM,
		|		RegisterRecords.StructureAssignment AS StructureAssignment,
		|		-RegisterRecords.ToSupply AS ToSupply
		|	FROM
		|		TrafficOrderStructureBeforeWrite AS RegisterRecords
		|
		|	UNION ALL
		|
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.ProductionOrder AS ProductionOrder,
		|		RegisterRecords.KeyProducts AS KeyProducts,
		|		RegisterRecords.KeyLot AS KeyLot,
		|		RegisterRecords.LineKind AS LineKind,
		|		RegisterRecords.ReceiptOrder AS ReceiptOrder,
		|		RegisterRecords.DateOfReceipt AS DateOfReceipt,
		|		RegisterRecords.KeySet AS KeySet,
		|		RegisterRecords.Level AS Level,
		|		RegisterRecords.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
		|		RegisterRecords.Department AS Department,
		|		RegisterRecords.Stage AS Stage,
		|		RegisterRecords.BillOfMaterials AS BillOfMaterials,
		|		RegisterRecords.SemiFinishedProductBOM AS SemiFinishedProductBOM,
		|		RegisterRecords.StructureAssignment AS StructureAssignment,
		|		RegisterRecords.ToSupply AS ToSupply
		|	FROM
		|		InformationRegister.OrderStructure AS RegisterRecords
		|	WHERE
		|		RegisterRecords.KeySet = &DocumentID) AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.Warehouse,
		|	ChangesTable.Purpose,
		|	ChangesTable.ProductionOrder,
		|	ChangesTable.KeyProducts,
		|	ChangesTable.KeyLot,
		|	ChangesTable.LineKind,
		|	ChangesTable.ReceiptOrder,
		|	ChangesTable.DateOfReceipt,
		|	ChangesTable.KeySet,
		|	ChangesTable.Level,
		|	ChangesTable.DurationBeforeProductionIssue,
		|	ChangesTable.Department,
		|	ChangesTable.Stage,
		|	ChangesTable.BillOfMaterials,
		|	ChangesTable.SemiFinishedProductBOM,
		|	ChangesTable.StructureAssignment
		|
		|HAVING
		|	SUM(ChangesTable.ToSupply) <> 0
		|;
		|DROP TrafficOrderStructureBeforeWrite
		|;";
		QueryResult = Query.ExecuteBatch();
	
		HasChanges = Not QueryResult[0].IsEmpty();
		If HasChanges Then
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(QueryResult[0].Unload());
			OrderStructure.StartCalculation();
		EndIf;
		
	EndIf
	
EndProcedure

Procedure RecordLaborCosts(DocumentID, DocumentRegisterRecords)
	
	RecordSet = InformationRegisters.OrderStructureLaborCosts.CreateRecordSet();
	RecordSet.Filter.KeySet.Set(DocumentID);
	RecordSet.Load(DocumentRegisterRecords);
	RecordSet.Write(True);

EndProcedure

#EndRegion

#Region ProductionSchedule

Procedure WriteDownTasksForCalculatingProductionSchedule(Document, AdditionalProperties, TempTablesManager)
	
	If AdditionalProperties.DocumentsPosting.DocumentProperties.IsNew Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.DocumentsPosting.DocumentProperties.Posted
		Or AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		Return;
	EndIf;
	
	If Document.Status <> Enums.ProductionOrderStatuses2_2.ToProduce Then
		Return;
	EndIf;
	
	HasChanges = False;
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();

	If TheProductionScheduleIsUsed Then
		
		If Document.EarliestStartDate <> AdditionalProperties.DocumentDataBeforeWrite.EarliestStartDate Then
			HasChanges = True;
		EndIf;
		
		If Document.Priority <> AdditionalProperties.DocumentDataBeforeWrite.Priority Then
			HasChanges = HasChanges Or Catalogs.Priorities.ComparePriorities(Document.Priority, AdditionalProperties.DocumentDataBeforeWrite.Priority) > 0;
		EndIf;
		
	EndIf;
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	(SELECT
		|		Table.ProductionOrder   AS ProductionOrder,
		|		Table.KeyProducts      AS KeyProducts,
		|		1                             AS IsRecord,
		|		Table.DemandDate       AS DemandDate
		|	FROM
		|		ChangeOrderMANUFACTUREDProducts AS Table) AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.ProductionOrder,
		|	ChangesTable.KeyProducts
		|
		|HAVING
		|	SUM(ChangesTable.IsRecord) > 1 AND COUNT(DISTINCT ChangesTable.DemandDate) > 1");

	Query.TempTablesManager = TempTablesManager;
	
	HasChanges = HasChanges Or Not Query.Execute().IsEmpty();
	
	If HasChanges Then
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddJob(Document.Ref,,, Not TheProductionScheduleIsUsed);
	EndIf;
	
EndProcedure

Procedure UpdateProductionScheduleWhenRecordingOrder(Document, TempTablesManager)
	
	If Not ProductionManagementCached.TheProductionScheduleIsUsed() Then
		Return;
	EndIf;
	
	Block = New DataLock();
	Block.Add("InformationRegister.OrderProductReleaseSchedule").SetValue("ProductionOrder", Document.Ref);
	Block.Lock();
	
	RecordSet = InformationRegisters.OrderProductReleaseSchedule.CreateRecordSet();
	RecordSet.Filter.ProductionOrder.Set(Document.Ref);
	
	If Not Document.Posted Or Not Document.Status = Enums.ProductionOrderStatuses2_2.ToProduce Then 

		RecordSet.Write(True); // used only in the "Ready for production" Status
		
	Else
		
		QueryResult = TempTablesManager.Tables.Find("ChangeOrderMANUFACTUREDProducts").GetData();
	
		If Not QueryResult.IsEmpty() Then
			
			ArrayOfRowsToDelete_1 = New Array();
			
			ModifiedRows = QueryResult.Unload();
			ModifiedRows.Indexes.Add("KeyProducts");
		
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				If ModifiedRows.Find(Record.KeyProducts, "KeyProducts") = Undefined Then
					Continue;
				EndIf;
				ArrayOfRowsToDelete_1.Add(Record);
			EndDo;
			
			For Each Record In ArrayOfRowsToDelete_1 Do
				RecordSet.Delete(Record);
			EndDo;
			
			RecordSet.Write(True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Updates the production schedule of the order after calculating the production schedule.
//
// Parameters:
//  Ref - DocumentRef.ProductionOrder2_2
//
Procedure UpdateProductionScheduleAfterCalculatingProductionSchedule(Ref) Export
	
	SetPrivilegedMode(True);

	Query = New Query();
	Query.Text =
		"SELECT
		|
		|	OrderStructure.Products         AS Products,
		|	OrderStructure.Characteristic       AS Characteristic,
		|	OrderStructure.Warehouse                AS Warehouse,
		|	OrderStructure.Purpose           AS Purpose,
		|	OrderStructure.ProductionOrder  AS ProductionOrder,
		|	OrderStructure.KeyProducts     AS KeyProducts,
		|	OrderStructure.KeyLot           AS KeyLot,
		|	SUM(OrderStructure.Ordered + OrderStructure.Done) AS Required2,
		|	SUM(OrderStructure.Scheduled + OrderStructure.AllocatedInAssignedProductionLots + OrderStructure.AllocatedInFreeProductionLots) AS Scheduled
		|
		|INTO OrderStructure
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|
		|WHERE
		|	OrderStructure.ProductionOrder = &Ref
		|	AND OrderStructure.LineKind IN (
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts))
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.KeyLot
		|
		|HAVING
		|	SUM(OrderStructure.Ordered + OrderStructure.Done) > 0
		|		OR SUM(OrderStructure.Scheduled + OrderStructure.AllocatedInAssignedProductionLots + OrderStructure.AllocatedInFreeProductionLots) > 0
		|;
		|
		|SELECT
		|
		|	OrderStructure.Products                              AS Products,
		|	OrderStructure.Characteristic                            AS Characteristic,
		|	OrderStructure.Warehouse                                     AS Warehouse,
		|	OrderStructure.Purpose                                AS Purpose,
		|	OrderStructure.ProductionOrder                       AS ProductionOrder,
		|	OrderStructure.KeyProducts                          AS KeyProducts,
		|	BEGINOFPERIOD(ProductionSchedule.Ending, DAY)         AS ScheduleDate,
		|	OrderStructure.Scheduled                             AS Scheduled
		|
		|INTO ReleaseSchedule
		|FROM
		|	OrderStructure AS OrderStructure
		|
		|		INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ProductionSchedule
		|		ON ProductionSchedule.ProductionOrder = OrderStructure.ProductionOrder
		|		 AND ProductionSchedule.KeyLot          = OrderStructure.KeyLot
		|		 AND ProductionSchedule.Stage                = VALUE(Catalog.ProductionStages.EmptyRef)
		// working schedule (See InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule)
		|		 AND ProductionSchedule.ScheduleStatus = 0
		|
		|WHERE
		|	OrderStructure.Scheduled > 0
		|;
		|
		|SELECT
		|
		|	OrderStructure.Products                              AS Products,
		|	OrderStructure.Characteristic                            AS Characteristic,
		|	OrderStructure.Warehouse                                     AS Warehouse,
		|	OrderStructure.Purpose                                AS Purpose,
		|	OrderStructure.ProductionOrder                       AS ProductionOrder,
		|	OrderStructure.KeyProducts                          AS KeyProducts,
		|	ISNULL(TabPart.DemandDate, DATETIME(1,1,1))        AS ScheduleDate,
		|	OrderStructure.Required2                                 AS Required2
		|
		|INTO OrderProducts_
		|FROM
		|	OrderStructure AS OrderStructure
		|
		|		LEFT JOIN InformationRegister.ProductionOrders AS TabPart
		|		ON TabPart.Products        = OrderStructure.Products
		|		 AND TabPart.Characteristic      = OrderStructure.Characteristic
		|		 AND TabPart.Warehouse               = OrderStructure.Warehouse
		|		 AND TabPart.Purpose          = OrderStructure.Purpose
		|		 AND TabPart.ProductionOrder = OrderStructure.ProductionOrder
		|		 AND TabPart.KeyProducts    = OrderStructure.KeyProducts
		|
		|WHERE
		|	OrderStructure.Required2 > 0
		|;
		|
		|SELECT
		|
		|	ReleaseSchedule.Products                              AS Products,
		|	ReleaseSchedule.Characteristic                            AS Characteristic,
		|	ReleaseSchedule.Warehouse                                     AS Warehouse,
		|	ReleaseSchedule.Purpose                                AS Purpose,
		|	ReleaseSchedule.ProductionOrder                       AS ProductionOrder,
		|	ReleaseSchedule.KeyProducts                          AS KeyProducts,
		|	ReleaseSchedule.ScheduleDate                               AS ScheduleDate,
		|	SUM(ReleaseSchedule.Scheduled)                      AS Count
		|
		|FROM
		|	ReleaseSchedule AS ReleaseSchedule
		|
		|GROUP BY
		|	ReleaseSchedule.Products,
		|	ReleaseSchedule.Characteristic,
		|	ReleaseSchedule.Warehouse,
		|	ReleaseSchedule.Purpose,
		|	ReleaseSchedule.ProductionOrder,
		|	ReleaseSchedule.KeyProducts,
		|	ReleaseSchedule.ScheduleDate
		|
		|UNION ALL
		|
		|SELECT
		|
		|	OrderProducts_.Products                            AS Products,
		|	OrderProducts_.Characteristic                          AS Characteristic,
		|	OrderProducts_.Warehouse                                   AS Warehouse,
		|	OrderProducts_.Purpose                              AS Purpose,
		|	OrderProducts_.ProductionOrder                     AS ProductionOrder,
		|	OrderProducts_.KeyProducts                        AS KeyProducts,
		|	MAX(OrderProducts_.ScheduleDate)                   AS ScheduleDate,
		|	MAX(OrderProducts_.Required2)
		|		- SUM(ISNULL(ReleaseSchedule.Scheduled, 0))     AS Count
		|
		|FROM
		|	OrderProducts_ AS OrderProducts_
		|
		|		LEFT JOIN ReleaseSchedule AS ReleaseSchedule
		|		ON OrderProducts_.Products        = ReleaseSchedule.Products
		|		 AND OrderProducts_.Characteristic      = ReleaseSchedule.Characteristic
		|		 AND OrderProducts_.Warehouse               = ReleaseSchedule.Warehouse
		|		 AND OrderProducts_.Purpose          = ReleaseSchedule.Purpose
		|		 AND OrderProducts_.ProductionOrder = ReleaseSchedule.ProductionOrder
		|		 AND OrderProducts_.KeyProducts    = ReleaseSchedule.KeyProducts
		|
		|GROUP BY
		|	OrderProducts_.Products,
		|	OrderProducts_.Characteristic,
		|	OrderProducts_.Warehouse,
		|	OrderProducts_.Purpose,
		|	OrderProducts_.ProductionOrder,
		|	OrderProducts_.KeyProducts
		|
		|HAVING
		|	MAX(OrderProducts_.Required2)
		|		- SUM(ISNULL(ReleaseSchedule.Scheduled, 0)) > 0
		|";
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.OrderProductReleaseSchedule.CreateRecordSet();
	RecordSet.Filter.ProductionOrder.Set(Ref);
	RecordSet.Load(QueryResult.Unload());
	RecordSet.Write(True);
	
EndProcedure

#EndRegion

#EndRegion
