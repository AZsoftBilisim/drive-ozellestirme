////////////////////////////////////////////////////////////////////////////////
// Production planning
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Calculates production plans, called when processing the queue of tasks for production planning.
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan - document being processed
//
Procedure Calculate(ProductionPlan) Export
	
	CalculationParameters = CalculationParameters(ProductionPlan);
	
	ThisIsNewCalculation = (CalculationParameters.SettlementMode = NewCalculationMode());
	If ThisIsNewCalculation Then
		SaveManualAdjustmentsBeforeCalculation(ProductionPlan);
	EndIf;
	CalculationProcedure = CalculationProcedure();
	
	Query = New Query();
	FillInInitializationParameters(Query, CalculationParameters);
	
	// initial calculation, adjustment of the plan
	RequestStructure = DecomposeQueryPackageIntoStructureOfQueryTexts(RequestTextForProductionPlanCalculationOperation());
	Step = Step(CalculationProcedure, True);
	Step["LongDesc"].Add(RequestStructure.LinesOfBusiness,     "");
	Step["LongDesc"].Add(RequestStructure.Delta,                      "");
	Step["LongDesc"].Add(RequestStructure.ManualAdjustments,         "");
	AddSpecificationMatchingTables(Query, Step["LongDesc"]);
	Step["LongDesc"].Add(RequestStructure.ModifiedProducts,           "");
	Step["LongDesc"].Add(RequestStructure.PlannedSpecifications, "");
	Step["LongDesc"].Add(RequestStructure.CancellableProducts,           "");
	Step["LongDesc"].Add(RequestStructure.MaximumRecordingPortionExceeded, "");
	Step["LongDesc"].Add(RequestStructure.Calculation,                      "Calculation");
	Step["LongDesc"].Add(RequestStructure.Adjusting,               "Adjusting");
	
	// re-examination (status change)
	Step = Step(CalculationProcedure, True);
	Step["LongDesc"].Add(RequestTextOperationVerificationChangingBankingDetails(), "Adjusting");
	
	// clearing unused data (with full recalculation)
	Step = Step(CalculationProcedure, True);
	Step["LongDesc"].Add(RequestTextOperationCancelProductionPlanCalculation(), "CancelingCalculation");
	
	Actions = Actions(Query, CalculationProcedure, CalculationParameters);
	ExecuteActions(Actions);
	
	If Common.ObjectAttributeValue(CalculationParameters.Attributes.Scenario, "PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(CalculationParameters.Attributes.Scenario, CalculationParameters.Attributes.PlanProfile);
		
	EndIf;
	
EndProcedure

// Clears unused data after calculation
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan - document being processed
//
Procedure ClearUnusedData(ProductionPlan) Export
	
	NumberOfWriteAttempts = ?(TransactionActive(), 1, 3);
	
	List = New ValueTable();
	List.Columns.Add("Ref");
	List.Columns.Add("DataVersion");
	
	Query = New Query(
	"SELECT TOP 1000
	|	RegisterProductionPlan.Ref AS Ref,
	|	RegisterProductionPlan.DataVersion AS DataVersion
	|FROM
	|	Document.RegisterProductionPlan AS RegisterProductionPlan
	|WHERE
	|	RegisterProductionPlan.ProductionPlan = &ProductionPlan AND RegisterProductionPlan.DeletionMark");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	While Not QueryResult.IsEmpty() Do
		
		Selection = QueryResult.Select();
		
		ThereAreRecordsInSelection = Selection.Next();
		While ThereAreRecordsInSelection Do
			
			RecordCounter = 0;
			While ThereAreRecordsInSelection And RecordCounter < 10 Do
				FillPropertyValues(List.Add(), Selection);
				ThereAreRecordsInSelection = Selection.Next();
				RecordCounter = RecordCounter + 1;
			EndDo;
			
			For ErrorCounter = 1 To 3 Do
				
				BeginTransaction();
				Try
					
					Block = New DataLock;
					LockItem = Block.Add("Document.RegisterProductionPlan");
					LockItem.Mode = DataLockMode.Exclusive;
					LockItem.DataSource = List;
					LockItem.UseFromDataSource("Ref", "Ref");
					Block.Lock();
					
					For Each Item In List Do
						
						DocumentObject = Item.Ref.GetObject();
						
						If DocumentObject <> Undefined
							And DocumentObject.DataVersion = Item.DataVersion Then
							
							DocumentObject.Delete();
							
						EndIf;
						
					EndDo;
					
					CommitTransaction();
					
				Except
					
					RollbackTransaction();
					
					If ErrorCounter >= NumberOfWriteAttempts Then
						ErrorText = DetailErrorDescription(ErrorInfo());
						Raise ErrorText;
					EndIf;
					
					ErrorCounter = ErrorCounter + 1;
					Continue;
					
				EndTry;
				
				Break;
				
			EndDo;
			
			List.Clear();
			
		EndDo;
		
		QueryResult = Query.Execute();
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Private

#Region CalculationSeparator

Function CalculationSeparator(ProductionPlan) Export
	
	Query = New Query(
	"SELECT
	|	Table.CalculationSeparator AS CalculationSeparator
	|FROM
	|	Document.ProductionPlan AS Table
	|WHERE
	|	Table.Ref = &ProductionPlan
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Selection.Next();
	Return Selection.CalculationSeparator;
	
EndFunction

Procedure SetCalculationSeparator(Object, WriteMode = False) Export
	
	MoveCalculationSeparator = False;
	
	If Object.AdditionalProperties.Property("CompleteRecalculation") Then
		
		MoveCalculationSeparator = True;
		
	Else
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			Query = New Query(
			"SELECT
			|	Table.Department AS Department,
			|	Table.Scenario AS Scenario,
			|	Table.PlanProfile AS PlanProfile,
			|	Table.DemandForMaterials AS DemandForMaterials
			|FROM
			|	Document.ProductionPlan AS Table
			|WHERE
			|	Table.Ref = &Ref
			|	AND Table.Posted
			|");
			Query.SetParameter("Ref", Object.Ref);
			
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
				Return;
			EndIf;
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If (Selection.Department <> Object.Department
				Or Selection.Scenario <> Object.Scenario
				Or Selection.PlanProfile <> Object.PlanProfile
				Or Selection.DemandForMaterials <> Object.DemandForMaterials) Then
				MoveCalculationSeparator = True;
			EndIf;
			
		ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
			
			MoveCalculationSeparator = True;
			
		EndIf;
		
	EndIf;
	
	If MoveCalculationSeparator Then
		
		Object.CalculationSeparator = ( Object.CalculationSeparator + 1 );
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PortionOfCalculation

// A portion of the calculation.
// 
// Returns:
//  ValueTable - Portion Of Calculation:
// * ReferenceOrder - DocumentRef.ProductionPlan -
// * ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure -
// * Products - CatalogRef.Products -
// * Characteristic - CatalogRef.ItemsCharacteristics -
// * BillOfMaterials - CatalogRef.BillsOfMaterials -
// * Purpose - CatalogRef.Assignments -
// * LineOfBusiness - CatalogRef.LinesOfBusiness -
// * ProductionScheduling - EnumRef.WayOfLinkingProductionOperations -
// * StartDate2 - Date -
// * DateOfProduction - Date -
// * QuantityToBeCalculated - Number -
// * Count - Number -
// * ToOrder - Number -
// * RangeOfDemandFrom - Number -
// * RangeOfDemandTo - Number -
// * DemandRangeIsSpecified - Number -
// * Separator - Number, DocumentRef.RegisterProductionPlan -
// * ProductionDate - Date -
// * ProductBOM - CatalogRef.BillsOfMaterials -
// * AssignmentOfProducts - CatalogRef.Assignments -
// * ProductsItems - CatalogRef.Products -
// * ItemVariant - CatalogRef.ItemsCharacteristics -
// * RecordType - AccumulationRecordType -
// * ToPlan - Boolean -
// * ProductionIssueDateOfIntermediateProducts - Date -
// * DateOfOrderReleaseAndProductionIssue - Date -
// * ManualAdjustment - Boolean -
// * AdjustmentDate - Date -
// * AdjustmentAuthor - CatalogRef.Users -
// * Comment - String -
// * InitialDemand - Number -
// * InitialDemandForOrder - Number -
// * Recipient - CatalogRef.Warehouses, CatalogRef.BusinessStructure -
// * Sender - CatalogRef.Warehouses, CatalogRef.BusinessStructure -
Function PortionOfCalculation()
	
	Table = New ValueTable;
	
	// Header
	
	Table.Columns.Add("ReferenceOrder", New TypeDescription("DocumentRef.ProductionPlan"));
	Table.Columns.Add("ProductionDispatcherBusinessUnit", New TypeDescription("CatalogRef.BusinessStructure"));
	
	// Demand
	
	Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	
	Table.Columns.Add("ProductionScheduling", New TypeDescription("EnumRef.WayOfLinkingProductionOperations"));
	Table.Columns.Add("StartDate2",       New TypeDescription("Date"));
	Table.Columns.Add("DateOfProduction",       New TypeDescription("Date"));
	
	Table.Columns.Add("QuantityToBeCalculated", New TypeDescription("Number"));
	
	Table.Columns.Add("Count", New TypeDescription("Number"));
	Table.Columns.Add("ToOrder", New TypeDescription("Number"));
	
	Table.Columns.Add("RangeOfDemandFrom", New TypeDescription("Number"));
	Table.Columns.Add("RangeOfDemandTo", New TypeDescription("Number"));
	Table.Columns.Add("DemandRangeIsSpecified", New TypeDescription("Number"));
	
	// grouping, additional information
	
	Table.Columns.Add("Separator", New TypeDescription("Number, DocumentRef.RegisterProductionPlan"));
	Table.Columns.Add("ProductionDate", New TypeDescription("Date"));
	Table.Columns.Add("ProductBOM", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table.Columns.Add("AssignmentOfProducts", New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("ProductsItems", New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("ItemVariant", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("RecordType", New TypeDescription("AccumulationRecordType"));
	
	Table.Columns.Add("ToPlan", New TypeDescription("Boolean"));
	Table.Columns.Add("ThisIsASemiFinishedProduct", New TypeDescription("Boolean"));
	Table.Columns.Add("ProductionIssueDateOfIntermediateProducts", New TypeDescription("Date"));
	Table.Columns.Add("DateOfOrderReleaseAndProductionIssue", New TypeDescription("Date"));

	Table.Columns.Add("ManualAdjustment", Metadata.AccumulationRegisters.ProductionPlans.Attributes.ManualAdjustment.Type);
	Table.Columns.Add("AdjustmentDate", Metadata.AccumulationRegisters.ProductionPlans.Attributes.AdjustmentDate.Type);
	Table.Columns.Add("AdjustmentAuthor", Metadata.AccumulationRegisters.ProductionPlans.Attributes.AdjustmentAuthor.Type);
	Table.Columns.Add("Comment", Metadata.AccumulationRegisters.ProductionPlans.Attributes.Comment.Type);
	
	Table.Columns.Add("InitialDemand", Metadata.AccumulationRegisters.ProductionPlans.Attributes.InitialDemand.Type);
	Table.Columns.Add("InitialDemandForOrder", Metadata.AccumulationRegisters.ProductionPlans.Attributes.InitialDemandForOrder.Type);
	
	// for compatibility
	
	Types = New Array;
	Types.Add(Type("CatalogRef.Warehouses"));
	Types.Add(Type("CatalogRef.BusinessStructure"));
	TypeDetails = New TypeDescription(Types);
	Table.Columns.Add("Recipient", TypeDetails);
	Table.Columns.Add("Sender", TypeDetails);
	
	TypeDetails = New TypeDescription("Undefined");
	TypeDetails = New TypeDescription("DocumentRef.ProductionStage2_2");
	Table.Columns.Add("StageSource", TypeDetails);
	
	Return Table;
	
EndFunction

Function ModifiedRows()
	
	Table = New ValueTable;
	
	Table.Columns.Add("ProductionPlan", New TypeDescription("DocumentRef.ProductionPlan"));
	
	Table.Columns.Add("Period", New TypeDescription("Date"));
	Table.Columns.Add("Recorder", New TypeDescription("DocumentRef.RegisterProductionPlan"));
	
	Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	Table.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	Table.Columns.Add("ToPlan", New TypeDescription("Boolean"));
	Table.Columns.Add("ThisIsASemiFinishedProduct", New TypeDescription("Boolean"));
	Table.Columns.Add("ProductionIssueDateOfIntermediateProducts", New TypeDescription("Date"));
	Table.Columns.Add("DateOfOrderReleaseAndProductionIssue", New TypeDescription("Date"));
	
	Table.Columns.Add("ManualAdjustment", Metadata.AccumulationRegisters.ProductionPlans.Attributes.ManualAdjustment.Type);
	Table.Columns.Add("AdjustmentDate", Metadata.AccumulationRegisters.ProductionPlans.Attributes.AdjustmentDate.Type);
	Table.Columns.Add("AdjustmentAuthor", Metadata.AccumulationRegisters.ProductionPlans.Attributes.AdjustmentAuthor.Type);
	Table.Columns.Add("Comment", Metadata.AccumulationRegisters.ProductionPlans.Attributes.Comment.Type);
	
	Table.Columns.Add("InitialDemand", Metadata.AccumulationRegisters.ProductionPlans.Attributes.InitialDemand.Type);
	Table.Columns.Add("InitialDemandForOrder", Metadata.AccumulationRegisters.ProductionPlans.Attributes.InitialDemandForOrder.Type);
	
	Table.Columns.Add("Count", New TypeDescription("Number"));
	Table.Columns.Add("ToOrder", New TypeDescription("Number"));
	
	Table.Columns.Add("RangeOfDemandFrom", New TypeDescription("Number"));
	Table.Columns.Add("RangeOfDemandTo", New TypeDescription("Number"));
	Table.Columns.Add("DemandRangeIsSpecified", New TypeDescription("Number"));
	
	Return Table;
	
EndFunction

Function RecordSeparatorField()
	
	RecordSeparatorField = "Separator";
	Return RecordSeparatorField;
	
EndFunction

Function GroupFields()
	
	GroupFields = ProductDecomposition.GroupFields("ProductionDate,AssignmentOfProducts,ProductBOM,RecordType");
	Return GroupFields;
	
EndFunction

Function AdditionalInformation()
	
	GroupFields = "ProductsItems,ItemVariant,ToPlan,QuantityToBeCalculated,CalculationBaseQuantity,CalculationBaseForOrder";
	Return GroupFields;
	
EndFunction

Function CalculationPortionSize(Count, CalculationParameters)
	
	OptimalPortion = Min(Count, Max(CalculationParameters.ReadingPortionFrom, Round((Count / CalculationParameters.ThreadsCount) + 0.5, 0, 0)), CalculationParameters.ReadingPortionBefore);
	Return OptimalPortion;
	
EndFunction

Function GetRepeatLoggers(RowsCount, CalculationParameters)
	
	Query = New Query(
	"SELECT TOP 1000
	|	Table.Ref AS Recorder
	|FROM
	|	Document.RegisterProductionPlan AS Table
	|WHERE
	|	Table.Posted
	|	AND Table.ProductionPlan = &ProductionPlan
	|	AND Table.CalculationSeparator < &CalculationSeparator
	|	AND NOT Table.MaximumRecordingPortionExceeded
	|");
	Query.SetParameter("ProductionPlan", CalculationParameters.ProductionPlan);
	Query.SetParameter("CalculationSeparator", CalculationParameters.CalculationSeparator);
	
	Query.Text = StrReplace(Query.Text, "1000", Format(RowsCount, "NZ=; NG="));
	
	Result = Query.Execute().Unload().UnloadColumn(0);
	Return Result;
	
EndFunction

Function UploadDataForRedisclosing(ProductionPlans, CalculationParameters, FilterParameters = Undefined)
	
	PortionOfCalculation = PortionOfCalculation();
	
	If FilterParameters <> Undefined Then
		StringsList = ProductionPlans.FindRows(FilterParameters);
	Else
		StringsList = ProductionPlans;
	EndIf;
	
	For Each String In StringsList Do
		
		NewRow = PortionOfCalculation.Add();
		
		NewRow.ReferenceOrder = CalculationParameters.ProductionPlan;
		NewRow.ProductionDispatcherBusinessUnit = CalculationParameters.Attributes.ProductionDispatcherBusinessUnit;
		
		NewRow.Products = String.Products;
		NewRow.Characteristic = String.Characteristic;
		NewRow.BillOfMaterials = String.BillOfMaterials;
		NewRow.Purpose = String.Purpose;
		NewRow.LineOfBusiness = String.LineOfBusiness;
		
		NewRow.ProductionScheduling = Enums.WayOfLinkingProductionOperations.ToFinish;
		NewRow.StartDate2 = ?(String.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly, String.Period, String.DateOfOrderReleaseAndProductionIssue);
		NewRow.DateOfProduction = ?(String.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly, String.DateOfOrderReleaseAndProductionIssue, String.Period);
		
		NewRow.Separator             = String.Recorder;
		NewRow.ProductionDate        = String.Period;
		NewRow.ProductBOM   = String.BillOfMaterials;
		NewRow.AssignmentOfProducts     = String.Purpose;
		NewRow.ProductsItems   = String.Products;
		NewRow.ItemVariant = String.Characteristic;

		NewRow.ToPlan = String.ToPlan;
		NewRow.ThisIsASemiFinishedProduct = String.ToPlan;
		NewRow.ProductionIssueDateOfIntermediateProducts = String.ProductionIssueDateOfIntermediateProducts;
		NewRow.DateOfOrderReleaseAndProductionIssue = String.DateOfOrderReleaseAndProductionIssue;
		
		NewRow.QuantityToBeCalculated = ?(CalculationParameters.Attributes.Status = Enums.PlanStatuses.Upholded, String.ToOrder, String.Count);
		NewRow.RecordType        = ?(NewRow.QuantityToBeCalculated > 0, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
		NewRow.QuantityToBeCalculated = ?(NewRow.QuantityToBeCalculated > 0, NewRow.QuantityToBeCalculated, -NewRow.QuantityToBeCalculated);
		
		NewRow.Count = String.Count;
		NewRow.ToOrder = String.ToOrder;
		
		NewRow.RangeOfDemandFrom = String.RangeOfDemandFrom;
		NewRow.RangeOfDemandTo = String.RangeOfDemandTo;
		NewRow.DemandRangeIsSpecified = String.DemandRangeIsSpecified;
		
	EndDo;
	
	Return PortionOfCalculation;
	
EndFunction

#EndRegion

#Region Calculation

// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan - Production plan
// 
// Returns:
//  Structure - Calculation parameters:
// * CalculationSeparator - Arbitrary -
// * SettlementMode - String -
// * VectorizeCalculation - Boolean -
// * ThreadsCount - Number -
// * CalculationProtocol - Structure - consists of:
//  * LevelCount - Number -
//  * SpecificationRelationships - Map of KeyAndValue-
Function CalculationParameters(ProductionPlan)
	
	CalculationParameters = New Structure();
	
	Query = New Query(
	"SELECT
	|	
	|	Attributes.Ref AS ProductionPlan,
	|	Attributes.CalculationSeparator AS CalculationSeparator,
	|	
	|	CASE
	|		WHEN NOT ( TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						AccumulationRegister.ProductionPlans AS Table
	|					WHERE
	|						Table.ProductionPlan = &ProductionPlan)
	|					
	|				AND TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						AccumulationRegister.ProductionPlans AS Table
	|					WHERE
	|						Table.ProductionPlan = &ProductionPlan
	|						AND Table.CalculationSeparator = Attributes.CalculationSeparator)
	|		) THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsNewSeparator,
	|	
	|	Attributes.Date AS Date,
	|	Attributes.Status AS Status,
	|	Attributes.Scenario AS Scenario,
	|	Attributes.PlanProfile AS PlanProfile,
	|	PlanProfiles.TransferDemandOfBusinesUnitsThroughTransfers AS TransferDemandOfBusinesUnitsThroughTransfers,
	|	Attributes.ProductionProcessType AS ProductionProcessType,
	|	Attributes.Department AS ProductionDispatcherBusinessUnit,
	|	
	|	Attributes.ProductionManagement2_2 AS ProductionManagement2_2,
	|	Attributes.DemandForMaterials AS DemandForMaterials
	|FROM
	|	Document.ProductionPlan AS Attributes
	|	LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON Attributes.PlanProfile = PlanProfiles.Ref
	|WHERE
	|	Attributes.Ref = &ProductionPlan
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	CalculationParameters.Insert("ProductionPlan", Selection.ProductionPlan);
	CalculationParameters.Insert("CalculationSeparator", Selection.CalculationSeparator);
	CalculationParameters.Insert("SettlementMode", ?(Selection.ThisIsNewSeparator, NewCalculationMode(), RecalculationMode()));
	
	#Region CommonSettings
	
	CommonSettings = CommonSettings(True);

	CalculationParameters.Insert("VectorizeCalculation", CommonSettings.VectorizeCalculation);
	CalculationParameters.Insert("ThreadsCount", CommonSettings.ThreadsCount);
	
	CalculationParameters.Insert("ReadingPortionFrom", CommonSettings.ReadingPortionFrom);
	CalculationParameters.Insert("ReadingPortionBefore", CommonSettings.ReadingPortionBefore);
	
	CalculationParameters.Insert("RecordPortion", CommonSettings.RecordPortion);
	CalculationParameters.Insert("NumberOfRowsInTheRecordset", ?(ValueIsFilled(CommonSettings.NumberOfRowsInTheRecordset), CommonSettings.NumberOfRowsInTheRecordset, MaximumNumberOfLinesInTheRecordSet()));
	
	CalculationParameters.Insert("AllowRepeatedUseOfCalculatedData", CommonSettings.AllowRepeatedUseOfCalculatedData);
	
	CalculationParameters.Insert("CalculationQueue", New Array(CommonSettings.ThreadsCount));
	
	CalculationParameters.Insert("MaxAccountingDepth", CommonSettings.MaxAccountingDepth);
	CalculationParameters.Insert("SearchCyclesAfter", ?(TMCommonUse.DebugMode(), 0, CommonSettings.SearchCyclesAfter));
	
	CalculationParameters.Insert("IntervalForCheckingCompletionOfCalculation", 2);
	
	#EndRegion
	
	#Region Attributes
	
	CalculationParameters.Insert("Attributes", New Structure());
	
	For Each Column In QueryResult.Columns Do //QueryResultColumn
		If StrFind("
				|Date,
				|Status,
				|Scenario,
				|PlanProfile,
				|TransferDemandOfBusinesUnitsThroughTransfers,
				|ProductionProcessType,
				|ProductionDispatcherBusinessUnit", Column.Name) = 0
			Then
			Continue;
		EndIf;
		CalculationParameters.Attributes.Insert(Column.Name, Selection[Column.Name]);
	EndDo;
	
	#EndRegion
	
	#Region DataSamplingParameters
	
	DataSamplingParameters = Catalogs.BillsOfMaterials.DataSamplingParameters();
	DataSamplingParameters.MethodOfCalculationOfMaterials = Selection.DemandForMaterials;
	DataSamplingParameters.SoftwareFillingOption = ProductionSupply.SoftwareOptionAccordingToProductionVersion(Selection.ProductionManagement2_2);
	DataSamplingParameters.RoundUpNumberOfUnitItems_ = False;
	DataSamplingParameters.CombineMaterialsAndWorksPerformed = True;
	CalculationParameters.Insert("DataSamplingParameters", DataSamplingParameters);
	
	#EndRegion
	
	#Region NodulationParameters
	
	NodulationParameters = ProductDecomposition.NodulationParameters();
	NodulationParameters.GroupData_           = True;
	NodulationParameters.GroupFields              = RecordSeparatorField() + "," + GroupFields();
	NodulationParameters.AdditionalInformation     = AdditionalInformation();
	NodulationParameters.DivideIntoOptimalBatches = False;
	
	CalculationParameters.Insert("NodulationParameters", NodulationParameters);
	
	#EndRegion
	
	#Region CalculationProtocol
	CalculationParameters.Insert("CalculationProtocol", New Structure("LevelCount,SpecificationRelationships", 0, New Map));
	#EndRegion
	
	Return CalculationParameters;
	
EndFunction

Function CalculationProcedure()
	
	CalculationProcedure = New ValueTable();
	CalculationProcedure.Columns.Add("LongDesc", New TypeDescription("ValueList"));
	CalculationProcedure.Columns.Add("MultipleExecution", New TypeDescription("Boolean"));
	
	Return CalculationProcedure;
	
EndFunction

Function Step(CalculationProcedure, MultipleExecution = False)
	
	Step = CalculationProcedure.Add();
	Step.MultipleExecution = MultipleExecution;
	Return Step;
	
EndFunction

Function Actions(Query, CalculationProcedure, CalculationParameters)
	
	Owner = New Structure();
	Owner.Insert("Query", Query);
	Owner.Insert("CalculationProcedure", CalculationProcedure);
	Owner.Insert("CalculationParameters", CalculationParameters);
	Actions = New Structure("Owner", Owner);
	Return Actions;
	
EndFunction

Function NextSteps(Actions)
	
	CalculationParameters = Actions.Owner["CalculationParameters"];
	
	If CalculationParameters.MaxAccountingDepth > CalculationParameters["CalculationProtocol"].LevelCount Then
		
		ContinueCalculation_ = True;
		
	Else
		
		ContinueCalculation_ = False;
		
		ErrorText = NStr("vi = 'Trong quá trình tính toán kế hoạch sản xuất, quy trình xử lý dữ liệu đã được lặp lại. Thi hành lệnh hủy bỏ.';
						|ru = 'В процессе расчета плана производства произошло зацикливание процедуры обработки данных. Выполнение прервано.';
						|en = 'The data processing procedure was looped during calculation of the production plan. Performance is broken.'; fa = 'The data processing procedure was looped during calculation of the production plan. Performance is broken.';
						|it = 'Durante il calcolo del piano di produzione si è verificato un malfunzionamento nell''elaborazione dati. Esecuzione interrotta.';
						|pl = 'W procesie obliczania planu produkcji nastąpiło zapętlenie procedury przetwarzania danych. Wykonanie zostało przerwane.';
						|tr = 'Üretim planı hesaplama sürecinde döngüsel veri işlemcisi prosedürleri gerçekleştirildi. Gerçekleştirme işlemi kesintiye uğradı.'");
		Raise ErrorText;
		
	EndIf;
	
	ClearActionStructure(Actions);
	
	CalculationProcedure = Actions.Owner["CalculationProcedure"]; // See ProductionServer.ServiceStructureOfValueTable
	ThereIsDataForProcessing = False;
	
	If ContinueCalculation_ Then
		
		While CalculationProcedure.Count() > 0 And Not ThereIsDataForProcessing Do
			
			SetPrivilegedMode(True);
			Result = TMCommonUse.GetQueryResults(Actions.Owner["Query"], CalculationProcedure[0].LongDesc, True);
			SetPrivilegedMode(False);
			
			For Each NewAction In Result Do
				
				If NewAction.Value.IsEmpty() Then
					Continue;
				EndIf;
				
				Actions.Insert(NewAction.Key, NewAction.Value);
				ThereIsDataForProcessing = True;
				
			EndDo;
			
			If Not ThereIsDataForProcessing Or Not CalculationProcedure[0].MultipleExecution Then
				CalculationParameters["CalculationProtocol"].LevelCount = 0;
				CalculationProcedure.Delete(CalculationProcedure[0]);
			EndIf;
			
		EndDo;
		
		CalculationParameters["CalculationProtocol"].LevelCount = CalculationParameters["CalculationProtocol"].LevelCount + 1;
		
	EndIf;
	
	Return ThereIsDataForProcessing;
	
EndFunction

Procedure ClearActionStructure(Actions)
	
	For Each KeyAndValue In Actions Do
		
		If KeyAndValue.Key = "Owner" Then
			Continue;
		EndIf;
		
		Actions.Delete(KeyAndValue.Key);
		
	EndDo;

EndProcedure

Procedure ExecuteActions(Actions)
	
	CalculationParameters = Actions.Owner["CalculationParameters"];
	
	QueryResult = Undefined;
	
	ThereIsDataForProcessing = NextSteps(Actions);
	While ThereIsDataForProcessing Do
		
		If Actions.Property("Calculation", QueryResult) Then
			
			Action = "CalculationOfProductionPlan.PerformTheCalculation";
			ActionParameters = New Structure("CalculationParameters,PortionOfCalculation,RecordersCached");
			
			Selection = QueryResult.Select();
			
			PortionSize = CalculationPortionSize(Selection.Count(), CalculationParameters);
			Batch = PortionOfCalculation();
			
			PortionSizeCached = Int(CalculationParameters.ReadingPortionBefore/CalculationParameters.RecordPortion)*2;
			Recorders = GetRepeatLoggers(PortionSizeCached*Int(Selection.Count()/PortionSize), CalculationParameters);
			
			ThereAreRecordsInSelection = Selection.Next();
			While ThereAreRecordsInSelection Do
				
				If Selection.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef() And Selection.ToPlan Then
					ErrorText = StrTemplate(NStr("vi = 'Trong quá trình tính toán kế hoạch sản xuất không thể chọn bảng kê chi tiết nguồn lực bán thành phẩm %1, %2. Đã ngừng thực hiện.';
												|ru = 'В процессе расчета плана производства не удалось выполнить подбор ресурсной спецификации полуфабриката %1, %2. Выполнение прервано.';
												|en = 'Cannot select a BOM of the semi-finished product %1 when calculating the production plan, %2. Execution aborted.'; fa = 'Cannot select a BOM of the semi-finished product %1 when calculating the production plan, %2. Execution aborted.';
												|it = 'Nel processo di calcolo del piano di produzione non è stato possibile eseguire la selezione delle specifiche delle risorse del semilavorato %1, %2. Esecuzione interrotta.';
												|pl = 'Podczas obliczenia planu produkcji nie udało się wybrać specyfikacji materiałowej półproduktu %1, %2. Wykonanie zostało przerwane.';
												|tr = 'Üretim planı hesaplama sürecinde %1 ve %2 yarı mamul ürünlerinin ürün reçeteleri gerçekleştirilemedi. Gerçekleştirme işlemi kesintiye uğradı.'"), Selection.Products, Selection.Characteristic);
					Raise ErrorText;
				EndIf;
				
				BillOfMaterials = Undefined;
				Counter = 0;
				While ThereAreRecordsInSelection And (Counter < PortionSize Or BillOfMaterials = Selection.BillOfMaterials) Do
					BillOfMaterials = Selection.BillOfMaterials;
					FillPropertyValues(Batch.Add(), Selection);
					ThereAreRecordsInSelection = Selection.Next();
					Counter = Counter + 1;
				EndDo;
				
				ActionParameters.CalculationParameters = CalculationParameters;
				ActionParameters.PortionOfCalculation = Batch;
				ActionParameters.RecordersCached = CutSublist(Recorders, 0, PortionSizeCached);
				
				ExecuteAction(Action, ActionParameters, CalculationParameters);
				Batch.Clear();
				
			EndDo;
			
		EndIf;
		
		If Actions.Property("Adjusting", QueryResult) Then
			
			Action = "CalculationOfProductionPlan.MakeAdjustments";
			ActionParameters = New Structure("CalculationParameters,Recorders,ModifiedRows");
			
			Selection = QueryResult.Select(QueryResultIteration.ByGroups);
			
			ThereAreModifiedLines = QueryResult.Columns.Find("Products") <> Undefined;
			ModifiedRows = ModifiedRows();
			Batch = New Array();
			
			While Selection.Next() Do // Recorder
				
				Batch.Add(Selection.Recorder);
				
				If ThereAreModifiedLines Then
					
					DetailedRecords = Selection.Select();
					
					While DetailedRecords.Next() Do
						FillPropertyValues(ModifiedRows.Add(), DetailedRecords);
					EndDo;
					
					CheckDataBeforeCalculation(ModifiedRows, CalculationParameters);
					
				EndIf;
				
				ActionParameters.CalculationParameters = CalculationParameters;
				ActionParameters.Recorders = Batch;
				ActionParameters.ModifiedRows = ModifiedRows;
				
				ExecuteAction(Action, ActionParameters, CalculationParameters, Selection.MaximumRecordingPortionExceeded);
				ModifiedRows.Clear();
				Batch.Clear();
				
			EndDo;
			
		EndIf;
		
		If Actions.Property("CancelingCalculation", QueryResult) Then
			
			Action = "CalculationOfProductionPlan.RunCancelingCalculation";
			ActionParameters = New Structure("CalculationParameters,Recorders");
			
			Selection = QueryResult.Select();
			
			PortionSize = Round((Selection.Count() / CalculationParameters.ThreadsCount) + 0.5, 0, 0);
			Batch = New Array();
			
			ThereAreRecordsInSelection = Selection.Next();
			While ThereAreRecordsInSelection Do
				
				MaximumRecordingPortionExceeded = Undefined;
				Counter = 0;
				While ThereAreRecordsInSelection
					And (Counter < PortionSize)
					And (MaximumRecordingPortionExceeded = Undefined Or MaximumRecordingPortionExceeded = Selection.MaximumRecordingPortionExceeded ) Do
					MaximumRecordingPortionExceeded = Selection.MaximumRecordingPortionExceeded;
					Batch.Add(Selection.Recorder);
					ThereAreRecordsInSelection = Selection.Next();
					Counter = Counter + 1;
				EndDo;
				
				ActionParameters.CalculationParameters = CalculationParameters;
				ActionParameters.Recorders = Batch;
				
				ExecuteAction(Action, ActionParameters, CalculationParameters, MaximumRecordingPortionExceeded);
				Batch.Clear();
				
			EndDo;
			
		EndIf;
		
		ExpectCalculationCompletion(CalculationParameters);
		
		ThereIsDataForProcessing = NextSteps(Actions);
		
	EndDo;
	
EndProcedure

Procedure ExecuteAction(ProcedureName, ProcedureParameters, CalculationParameters, ItIsForbiddenToExecuteInSeparateThread = False)
	
	PlaceInQueue = GetPlaceInCalculationQueue(CalculationParameters, ItIsForbiddenToExecuteInSeparateThread);
	BackgroundJobDescription = StrTemplate(NStr("vi = 'Tính toán kế hoạch sản xuất < %1> ( %2)';
												|ru = 'Расчет плана производства <%1> (%2)';
												|en = 'Calculation of the product plan <%1> (%2)'; fa = 'Calculation of the product plan <%1> (%2)';
												|it = 'Calcolo del piano di produzione <%1> (%2)';
												|pl = 'Obliczanie planu produkcji <%1> (%2)';
												|tr = 'Üretim planının hesaplanması <%1> (%2)'"), CalculationParameters.ProductionPlan, (PlaceInQueue + 1));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
	ExecutionParameters.BackgroundJobDescription = BackgroundJobDescription;
	ExecutionParameters.RunNotInBackground1 = (ItIsForbiddenToExecuteInSeparateThread Or Not CalculationParameters.VectorizeCalculation);
	ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, New UUID);
	ExecutionParameters.WaitCompletion = 0;
	
	RunResult = TimeConsumingOperations.ExecuteInBackground(
		ProcedureName,
		ProcedureParameters,
		ExecutionParameters);
		
	If RunResult.Status = "Completed2" Then
		RecordResultInCalculationProtocol(RunResult.ResultAddress, CalculationParameters["CalculationProtocol"]);
	ElsIf RunResult.Status = "Running" Then
		CalculationParameters.CalculationQueue[PlaceInQueue] = New Structure("Id, ResultAddress", RunResult.JobID, RunResult.ResultAddress);
	Else
		Raise RunResult.BriefErrorDescription;
	EndIf;
	
EndProcedure

Procedure PerformTheCalculation(ActionParameters, ResultAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InventoryPlanning.CalculationOfProductionPlan");
	
	PerformCalculationInsideTimeMeasurement(ActionParameters, ResultAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ActionParameters.PortionOfCalculation.Count());
	
EndProcedure

Procedure PerformCalculationInsideTimeMeasurement(ActionParameters, ResultAddress)
	
	CalculationParameters    = ActionParameters.CalculationParameters;
	PortionOfCalculation       = ActionParameters.PortionOfCalculation; // ValueTable - 
	RecordersCached = ActionParameters.RecordersCached;
	
	RecordSeparatorField = RecordSeparatorField();
	GroupFields = GroupFields();
	
	CalculationResult2 = PortionOfCalculation.CopyColumns(RecordSeparatorField + "," + GroupFields); // ValueTable - 
	
	CalculationResult2.Columns.Add("Cnt1", New TypeDescription("Number")); // counters for batch recording
	CalculationResult2.Columns.Add("Cnt2", New TypeDescription("Number"));
	CalculationResult2.Columns.Add("Cnt3", New TypeDescription("Number"));
	CalculationResult2.Columns.Add("Cnt4", New TypeDescription("Number"));
	
	CalculationResult2.Columns.Add("SpecificationData");
	
	If PortionOfCalculation.Count() > CalculationParameters.RecordPortion Then // filling in the "record separator" field
		
		ColumnsList = StrSplit(GroupFields,",");
		
		CompareValues = New CompareValues;
		PortionOfCalculation.Sort(GroupFields, CompareValues);
		
		Separator = 1;
		Cnt = 0;
		For Each String In PortionOfCalculation Do
			If Cnt >= CalculationParameters.RecordPortion
				And ThereAreDifferencesInColumns(String, PortionOfCalculation[PortionOfCalculation.IndexOf(String)-1], ColumnsList) Then
				Separator = Separator + 1;
				Cnt = 0;
			EndIf;
			String.Separator = Separator;
			Cnt = Cnt + 1;
		EndDo;
		
	EndIf;
	
	StructureOfData = UnravelProducts(PortionOfCalculation, CalculationParameters);
	
	If StructureOfData.HasError Then
		
		ErrorText = StructureOfData.ErrorText;
		Raise ErrorText;
		
	Else
		
		For Each SpecificationData In StructureOfData.SpecificationsData Do
			
			SpecificationData.MaterialsAndServices.Columns.Add("MaterialsWarehouse", New TypeDescription("CatalogRef.Warehouses"));
			SpecificationData.MaterialsAndServices.LoadColumn(SpecificationData.MaterialsAndServices.UnloadColumn("Warehouse"), "MaterialsWarehouse");
			
			If CalculationParameters.Attributes.TransferDemandOfBusinesUnitsThroughTransfers Then
				ForwardMovements(SpecificationData.MaterialsAndServices);
			EndIf;
			
			DistributionOfEmploymentByStageDuration(SpecificationData.LaborCosts);
			If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
				Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(SpecificationData);
				ExcludeNodesSubjectToRAndM(SpecificationData);
			EndIf;
			NewRow = CalculationResult2.Add();
			FillPropertyValues(NewRow, SpecificationData);
			
			NewRow.Cnt1 = SpecificationData.ManufacturedProducts.Count() + SpecificationData.RecyclableWaste.Count();
			NewRow.Cnt2 = SpecificationData.MaterialsAndServices.Count();
			NewRow.Cnt3 = SpecificationData.LaborCosts.Count();
			NewRow.Cnt2 = NewRow.Cnt2 + SpecificationData.IncomingProducts.Count();
			NewRow.Cnt4 = SpecificationData.WorkCenterTypes.Count();
			NewRow.SpecificationData = SpecificationData;
			
		EndDo;
		
		PortionOfCalculation.Indexes.Add(RecordSeparatorField);
		PortionOfCalculation.Indexes.Add(GroupFields);
		CalculationResult2.Indexes.Add(RecordSeparatorField);
		CalculationResult2.Indexes.Add(GroupFields);
		
	EndIf;
	
	AdjustedRows = PortionOfCalculation.FindRows(New Structure("ManualAdjustment", True));
	
	TimeIntervals = StructureOfCalculationOfPeriods();
	DetailsOfSpecifications = DetailsOfSpecifications(PortionOfCalculation, CalculationParameters);
	
	IndexLoggers = 0;
	BorderLoggers = ?(RecordersCached <> Undefined, RecordersCached.UBound(), -1);
	
	ListToWrite = New Array();

	Stack = CalculationResult2.Copy(, "Separator" + ",Cnt1,Cnt2,Cnt3,Cnt4");
	Stack.GroupBy("Separator", "Cnt1,Cnt2,Cnt3,Cnt4");
	Stack.Columns.Add("Data", New TypeDescription("Array"));
	Stack.Columns.Add("MaximumRecordingPortionExceeded", New TypeDescription("Boolean"));
	
	While Stack.Count() > 0 Do
		
		RecordPortion = Stack[0];
		
		ThereIsDataToRecord = ValueIsFilled(RecordPortion.Data);
		If Not ThereIsDataToRecord Then
			
			RecordSeparator = New Structure("Separator", RecordPortion.Separator);
			
			If CalculationParameters.NumberOfRowsInTheRecordset > 0
				And Max(RecordPortion.Cnt1, RecordPortion.Cnt2, RecordPortion.Cnt3, RecordPortion.Cnt4) > CalculationParameters.NumberOfRowsInTheRecordset Then
				
				Stack.Delete(RecordPortion);
				RecordPortion = Undefined;
				
				DetailedRecords = CalculationResult2.Copy(RecordSeparator, GroupFields + ",Cnt1,Cnt2,Cnt3,Cnt4");
				DetailedRecords.GroupBy(GroupFields, "Cnt1,Cnt2,Cnt3,Cnt4");
				
				For Each Details_3 In DetailedRecords Do
					
					Group = New Structure(GroupFields);
					FillPropertyValues(Group, Details_3);
					
					If RecordPortion = Undefined
						Or RecordPortion.Cnt1 + Details_3.Cnt1 > CalculationParameters.NumberOfRowsInTheRecordset
						Or RecordPortion.Cnt2 + Details_3.Cnt2 > CalculationParameters.NumberOfRowsInTheRecordset
						Or RecordPortion.Cnt3 + Details_3.Cnt3 > CalculationParameters.NumberOfRowsInTheRecordset
						Or RecordPortion.Cnt4 + Details_3.Cnt4 > CalculationParameters.NumberOfRowsInTheRecordset Then
						
						RecordPortion = Stack.Insert(0);
						FillPropertyValues(RecordPortion, RecordSeparator);
						
					EndIf;
					
					RecordPortion.Data.Add(Group);
					
					RecordPortion.Cnt1 = (RecordPortion.Cnt1 + Details_3.Cnt1);
					RecordPortion.Cnt2 = (RecordPortion.Cnt2 + Details_3.Cnt2);
					RecordPortion.Cnt3 = (RecordPortion.Cnt3 + Details_3.Cnt3);
					RecordPortion.Cnt4 = (RecordPortion.Cnt4 + Details_3.Cnt4);
					
					RecordPortion.MaximumRecordingPortionExceeded = Max(RecordPortion.Cnt1,
																			RecordPortion.Cnt2,
																			RecordPortion.Cnt3,
																			RecordPortion.Cnt4) > CalculationParameters.NumberOfRowsInTheRecordset;
					
				EndDo;
				
			Else
				RecordPortion.Data.Add(RecordSeparator);
				ThereIsDataToRecord = True;
			EndIf;
			
		EndIf;
		
		If IndexLoggers > BorderLoggers Or RecordPortion.MaximumRecordingPortionExceeded Then
			Recorder = Documents.RegisterProductionPlan.GetRef();
			NewRegistrar = True;
		Else
			Recorder = RecordersCached[IndexLoggers];
			NewRegistrar = False;
			IndexLoggers = IndexLoggers + 1;
		EndIf;
		
		RegisterRecords = MotionRecordingSets(Recorder);
		
		FillingValues = MotionFillValues(
			Recorder,
			CalculationParameters);
		
		For Each DataPortion In RecordPortion.Data Do
			
			FoundRows = PortionOfCalculation.FindRows(DataPortion);
			
			FillInRegisteredRecordsInProductionPlans(
				RegisterRecords,
				FillingValues,
				FoundRows,
				DetailsOfSpecifications,
				TimeIntervals);
			
			FoundRows = CalculationResult2.FindRows(DataPortion);
			
			FillInRegisteredRecordsBasedOnCalculationResult(
				RegisterRecords,
				FillingValues,
				FoundRows,
				TimeIntervals);
		
		EndDo;
		
		ListToWrite.Add(New Structure("Recorder, NewRegistrar, RegisterRecords, MaximumRecordingPortionExceeded", Recorder, NewRegistrar, RegisterRecords, RecordPortion.MaximumRecordingPortionExceeded));
		
		Stack.Delete(RecordPortion);
		
	EndDo;
	
	FillInPeriodsInRegisteredRecords(CalculationParameters, TimeIntervals);
	
	TimeIntervals           = Undefined;
	StructureOfData   = Undefined;
	CalculationResult2  = Undefined;
	StructureOfRegisteredRecords = Undefined;
	
	RecordCalculationResult(ListToWrite, CalculationParameters, AdjustedRows);
	
EndProcedure

// Returns the result of the explosion products
//
// Parameters:
//  PortionOfCalculation - See PortionOfCalculation
//  CalculationParameters - See CalculationParameters
//
// Returns:
//  Structure - 
//
Function UnravelProducts(PortionOfCalculation, CalculationParameters)
	
	PortionOfCalculation.Columns["ToOrder"].Name = "CalculationBaseForOrder";
	PortionOfCalculation.Columns["Count"].Name = "CalculationBaseQuantity";
	
	PortionOfCalculation.Columns.Add("Count", Common.TypeDescriptionNumber(15,3, AllowedSign.Nonnegative));
	PortionOfCalculation.LoadColumn(PortionOfCalculation.UnloadColumn("QuantityToBeCalculated"), "Count");
	
	PortionOfCalculation.Columns.Add("LineNumber", Common.TypeDescriptionNumber(15,3, AllowedSign.Nonnegative));
	
	StructureOfData = ProductDecomposition.Explosion(
		PortionOfCalculation,
		CalculationParameters.NodulationParameters,
		CalculationParameters.DataSamplingParameters); // See ProductionServer.ServiceStructureOfStructure
		
	If PortionOfCalculation.Find(Catalogs.BillsOfMaterials.EmptyRef(), "BillOfMaterials") <> Undefined Then // support for "no specification" mode
		
		RowFilter = New Structure(CalculationParameters.NodulationParameters.GroupFields);
		
		For Each Data In StructureOfData.SpecificationsData Do
			
			If ValueIsFilled(Data.BillOfMaterials) Then
				Continue;
			EndIf;
			
			Data.ProductionProcessType = CalculationParameters.Attributes.ProductionProcessType;
			
			FillPropertyValues(RowFilter, Data);
			
			FoundRows = PortionOfCalculation.FindRows(RowFilter);
			For Each String In FoundRows Do
				
				NewRow = Data.ManufacturedProducts.Add();
				
				FillPropertyValues(NewRow, String); // Products,Characteristic
				
				NewRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData;
				NewRow.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
				
				NewRow.ProductQuantity = 1;
				NewRow.NumberOfPackagesPerUnitOfProductionBatch = 1;
				NewRow.PackageData = ProductDataManagementCached.PackingDataStructure();
				
				NewRow.DaysFromDemand = 0;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	PortionOfCalculation.Columns.Delete("Count");
	PortionOfCalculation.Columns.Delete("LineNumber");
	
	PortionOfCalculation.Columns["CalculationBaseQuantity"].Name = "Count";
	PortionOfCalculation.Columns["CalculationBaseForOrder"].Name = "ToOrder";
	
	Return StructureOfData;
	
EndFunction

// Parameters:
//  MaterialsAndServices - ValueTable - Materials and services:
// * LineNumber - Number -
Procedure ForwardMovements(MaterialsAndServices) Export
	
	Result = MaterialsAndServices;
	
	Result.Columns.Add("RowIndex", New TypeDescription("Number"));
	
	IndexOf = 0;
	For Each String In Result Do
		String.RowIndex = IndexOf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	Level = 0;
	MaxAccountingDepth = 125;
	
	While Result.Count() > 0 Do
		
		If Level > MaxAccountingDepth Then
			
			Template = NStr("vi = 'Đã vượt quá số lượng chuyển tối đa (%1) khi tính toán kế hoạch sản xuất.';
							|ru = 'Превышено максимальное количество перемещений (%1) при расчете плана производства.';
							|en = 'The maximum number of transfers (%1) during production plan calculation is exceeded.'; fa = 'The maximum number of transfers (%1) during production plan calculation is exceeded.';
							|it = 'Превышено максимальное количество перемещений (%1) при расчете плана производства.';
							|pl = 'The maximum number of transfers (%1) during production plan calculation is exceeded.';
							|tr = 'Üretim planı hesaplanırken maksimum transfer sayısı (%1) aşıldı.'");
			Template_Item =
				NStr("vi = 'Tại mặt hàng ""%1"" và phương thức đảm bảo ""%2"" đã xảy ra vòng lặp tách.';
					|ru = 'На номенклатуре ""%1"" и способе обеспечения ""%2"" произошло зацикливание разузлования.';
					|en = 'An explosion loop occurred on the ""%1"" item and the ""%2"" procurement strategy.'; fa = 'An explosion loop occurred on the ""%1"" item and the ""%2"" procurement strategy.';
					|it = 'На номенклатуре ""%1"" и способе обеспечения ""%2"" произошло зацикливание разузлования.';
					|pl = 'An explosion loop occurred on the ""%1"" item and the ""%2"" procurement strategy.';
					|tr = '""%1"" öğesinde ve ""%2"" tedarik yönteminde ayrıştırma döngüsü meydana geldi.'");
			
			PieceOfText = New Array;
			PieceOfText.Add(StrTemplate(Template, MaxAccountingDepth));
			
			For Each TableRow In Result Do
				
				PieceOfText.Add(StrTemplate(Template_Item,
													TableRow.Products,
													TableRow.SupplyMethodPresentation));
				
			EndDo;
			
			Raise StrConcat(PieceOfText, Chars.LF);
		EndIf;
		
		Query = New Query(Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False)
		+ "SELECT
			|	MaterialsAndServices.RowIndex   AS RowIndex,
			|	MaterialsAndServices.Id  AS Id,
			|	MaterialsAndServices.Products   AS Products,
			|	MaterialsAndServices.Characteristic AS Characteristic,
			|	MaterialsAndServices.Warehouse          AS Warehouse,
			|	MaterialsAndServices.ToPlan  AS ToPlan,
			|
			|	MaterialsAndServices.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit
			|
			|INTO TTMaterialsAndServices
			|FROM &MaterialsAndServices AS MaterialsAndServices
			|
			|WHERE NOT MaterialsAndServices.ToPlan
			|
			|;
			|///////////////////////////////////////////
			|
			|SELECT
			|	MaterialsAndServices.Id  AS Id,
			|	MaterialsAndServices.RowIndex   AS RowIndex,
			|	MaterialsAndServices.Products   AS Products,
			|	MaterialsAndServices.Characteristic AS Characteristic,
			|	
			|	MaterialsAndServices.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
			|	&ToPlan AS ToPlan,
			|	CASE
			|		WHEN CatSupplyMethod.Ref IS NOT NULL
			|				AND CatSupplyMethod.SupplyType = VALUE(Enum.SupplyTypes.Move)
			|				AND CatSupplyMethod.SourceOfDemandSupply NOT IN (UNDEFINED, VALUE(Catalog.Warehouses.EmptyRef))
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ItIsTransfer,
			|	CASE
			|		WHEN CatSupplyMethod.Ref IS NOT NULL
			|				AND CatSupplyMethod.SupplyType = VALUE(Enum.SupplyTypes.Move)
			|				AND CatSupplyMethod.SourceOfDemandSupply NOT IN (UNDEFINED, VALUE(Catalog.Warehouses.EmptyRef))
			|			THEN CatSupplyMethod.SourceOfDemandSupply
			|		ELSE MaterialsAndServices.Warehouse
			|	END AS Warehouse,
			|	CatSupplyMethod.Presentation AS SupplyMethodPresentation
			|
			|FROM TTMaterialsAndServices AS MaterialsAndServices
			|	LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
			|	ON &MainSupplyMethodSubstitution");
		
		ConnectionFields = "MaterialsAndServices.Products, MaterialsAndServices.Characteristic, MaterialsAndServices.Warehouse";
		ParameterName   = "MainSupplyMethodSubstitution";
		
		Query.Text = StrReplace(Query.Text, "&ToPlan", Catalogs.BillsOfMaterials.TextOfScheduleFieldSubstitution("MaterialsAndServices.ProductionDispatcherBusinessUnit"));
		
		Query.Text = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
			Query.Text, ParameterName, ConnectionFields);
		
		Query.SetParameter("MaterialsAndServices", Result);
		
		Result = Query.Execute().Unload();
		
		For IndexOf = -Result.Count() + 1 To 0 Do
			
			String = Result[-IndexOf];
			
			Material = MaterialsAndServices[String.RowIndex];
			If ValueIsFilled(Material) Then
				Material.Warehouse = String.Warehouse;
				Material.ToPlan = String.ToPlan;
			EndIf;
			
			If Not String.ItIsTransfer Then
				Result.Delete(String);
			EndIf;
			
		EndDo;
		Level =  Level + 1;
	EndDo;
	
EndProcedure

// Distribution of employment by stage duration.
// 
// Parameters:
//  LaborCosts - ValueTable
Procedure DistributionOfEmploymentByStageDuration(LaborCosts)
	NewLines = New Array;
	
	For Each String In LaborCosts Do
		
		If String.StageDurationInDays > 1 And NewLines.Find(LaborCosts.IndexOf(String)) = Undefined Then
			
			String.Count = String.Count / String.StageDurationInDays;
			
			For IndexOf = 1 To String.StageDurationInDays - 1 Do
				
				NewTableRow = LaborCosts.Add();
				FillPropertyValues(NewTableRow, String);
				
				If String.DaysFromDemand < 0 Then
					NewTableRow.DaysFromDemand = NewTableRow.DaysFromDemand + IndexOf;
				Else
					NewTableRow.DaysFromDemand = NewTableRow.DaysFromDemand - IndexOf;
				EndIf;
				
				NewLines.Add(LaborCosts.IndexOf(NewTableRow));
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure
Procedure ExcludeNodesSubjectToRAndM(SpecificationData)
	
	For IndexOf = -SpecificationData.RecyclableWaste.Count() + 1 To 0 Do
		String = SpecificationData.RecyclableWaste[-IndexOf];
		If String.ItIsSubjectToRAndM Then
			SpecificationData.RecyclableWaste.Delete(String);
		EndIf;
	EndDo;
	
EndProcedure
Procedure MakeAdjustments(ActionParameters, ResultAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InventoryPlanning.AdjustmentOfProductionPlan");
	
	MakeAdjustmentsInsideTimeMeasurement(ActionParameters, ResultAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ActionParameters.Recorders.Count());
	
EndProcedure

Procedure MakeAdjustmentsInsideTimeMeasurement(ActionParameters, ResultAddress)
	
	CalculationParameters = ActionParameters.CalculationParameters;
	Recorders     = ActionParameters.Recorders;
	ModifiedRows = ActionParameters.ModifiedRows;
	
	Query = New Query(
	"SELECT
	|	
	|	Table.ProductionPlan AS ProductionPlan,
	|	
	|	Table.Period AS Period,
	|	Table.Recorder AS Recorder,
	|	
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	
	|	Table.BillOfMaterials AS BillOfMaterials,
	|	Table.Purpose AS Purpose,
	|	
	|	Table.ToPlan AS ToPlan,
	|	Table.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Table.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	Table.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
	|	
	|	Table.ManualAdjustment AS ManualAdjustment,
	|	Table.AdjustmentDate   AS AdjustmentDate,
	|	Table.AdjustmentAuthor  AS AdjustmentAuthor,
	|	Table.Comment         AS Comment,
	|	
	|	Table.InitialDemand        AS InitialDemand,
	|	Table.InitialDemandForOrder AS InitialDemandForOrder,
	|	
	|	Table.Count AS Count,
	|	Table.ToOrder AS ToOrder,
	|	
	|	Table.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	Table.RangeOfDemandTo AS RangeOfDemandTo,
	|	Table.DemandRangeIsSpecified AS DemandRangeIsSpecified
	|	
	|INTO ModifiedRows
	|FROM
	|	&ModifiedRows AS Table
	|	
	|INDEX BY
	|	Period,
	|	Recorder,
	|	ProductionPlan,
	|	BillOfMaterials,
	|	Purpose,
	|	ProductionIssueDateOfIntermediateProducts,
	|	ToPlan,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Purpose AS Purpose,
	|	ISNULL(CAST(Table.Purpose AS Catalog.Assignments).LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
	|
	|INTO LinesOfBusiness
	|FROM
	|	ModifiedRows AS Table
	|
	|INDEX BY
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	ModifiedRows.Period AS Period,
	|	ModifiedRows.Recorder AS Recorder,
	|	ModifiedRows.ProductionPlan AS ProductionPlan,
	|	ModifiedRows.BillOfMaterials AS BillOfMaterials,
	|	ModifiedRows.Purpose AS Purpose,
	|	
	|	MAX(CASE
	|				WHEN RegisterRecords.Period IS NULL THEN
	|					TRUE
	|			ELSE
	|				CASE
	|					WHEN ModifiedRows.Period <> RegisterRecords.Period
	|							OR ModifiedRows.BillOfMaterials <> RegisterRecords.BillOfMaterials
	|							OR ModifiedRows.Count <> RegisterRecords.Count
	|							OR ModifiedRows.ToOrder <> RegisterRecords.ToOrder
	|					THEN TRUE
	|					ELSE FALSE
	|				END
	|		END) AS RecountIsRequired,
	|	
	|	MAX(Specifications.ProductionProcessType) AS ProductionProcessType,
	|	MAX(ISNULL(DataCache.RepeatedDecomposition, TRUE)) AS RepeatedDecomposition
	|	
	|INTO ModifiedSpecifications
	|FROM
	|	ModifiedRows AS ModifiedRows
	|	
	|		LEFT JOIN AccumulationRegister.ProductionPlans AS RegisterRecords
	|		ON RegisterRecords.Period                      = ModifiedRows.Period
	|			AND RegisterRecords.Recorder              = ModifiedRows.Recorder
	|			AND RegisterRecords.ProductionPlan         = ModifiedRows.ProductionPlan
	|			AND RegisterRecords.Products             = ModifiedRows.Products
	|			AND RegisterRecords.Characteristic           = ModifiedRows.Characteristic
	|			AND RegisterRecords.BillOfMaterials             = ModifiedRows.BillOfMaterials
	|			AND RegisterRecords.Purpose               = ModifiedRows.Purpose
	|			AND RegisterRecords.ProductionIssueDateOfIntermediateProducts = ModifiedRows.ProductionIssueDateOfIntermediateProducts
	|			AND RegisterRecords.ToPlan            = ModifiedRows.ToPlan
	|	
	|		LEFT JOIN AccumulationRegister.ProductionPlans AS DataCache
	|		ON DataCache.Period                      = ModifiedRows.Period
	|			AND DataCache.Recorder              = ModifiedRows.Recorder
	|			AND DataCache.ProductionPlan         = ModifiedRows.ProductionPlan
	|			AND DataCache.BillOfMaterials             = ModifiedRows.BillOfMaterials
	|			AND DataCache.Purpose               = ModifiedRows.Purpose
	|			AND DataCache.Products             = ModifiedRows.Products
	|			AND DataCache.Characteristic           = ModifiedRows.Characteristic
	|	
	|		LEFT JOIN Catalog.BillsOfMaterials AS Specifications
	|		ON Specifications.Ref = ModifiedRows.BillOfMaterials
	|	
	|GROUP BY
	|	ModifiedRows.Recorder,
	|	ModifiedRows.ProductionPlan,
	|	ModifiedRows.Period,
	|	ModifiedRows.BillOfMaterials,
	|	ModifiedRows.Purpose
	|
	|INDEX BY
	|	Period,
	|	Recorder,
	|	ProductionPlan,
	|	BillOfMaterials,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Recorder AS Recorder,
	|	
	|	RegisterRecords.Products AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.ProductionPlan AS ProductionPlan,
	|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
	|	RegisterRecords.Purpose AS Purpose,
	|	LinesOfBusiness.LineOfBusiness AS LineOfBusiness,
	|	
	|	RegisterRecords.ToPlan AS ToPlan,
	|	RegisterRecords.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	RegisterRecords.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	ISNULL(ModifiedRows.DateOfOrderReleaseAndProductionIssue, RegisterRecords.DateOfOrderReleaseAndProductionIssue) AS DateOfOrderReleaseAndProductionIssue,
	|	
	|	ModifiedSpecifications.Period IS NULL AS HasChanges,
	|	ISNULL(ModifiedSpecifications.RecountIsRequired, FALSE) AS RecountIsRequired,
	|	
	|	RegisterRecords.RepeatedDecomposition        AS RepeatedDecomposition,
	|	RegisterRecords.ProductionProcessType AS ProductionProcessType,
	|	
	|	CASE
	|		WHEN ModifiedRows.Period IS NULL THEN
	|			RegisterRecords.ManualAdjustment
	|		ELSE
	|			CASE
	|				WHEN ModifiedRows.ManualAdjustment
	|				THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS ManualAdjustment,
	|	CASE
	|		WHEN ModifiedRows.Period IS NULL THEN
	|			RegisterRecords.AdjustmentDate
	|		ELSE
	|			CASE
	|				WHEN ModifiedRows.ManualAdjustment
	|				THEN ModifiedRows.AdjustmentDate
	|				ELSE DATETIME(1,1,1)
	|			END
	|	END AS AdjustmentDate,
	|	CASE
	|		WHEN ModifiedRows.Period IS NULL THEN
	|			RegisterRecords.AdjustmentAuthor
	|		ELSE
	|			CASE
	|				WHEN ModifiedRows.ManualAdjustment
	|				THEN ModifiedRows.AdjustmentAuthor
	|				ELSE UNDEFINED
	|			END
	|	END AS AdjustmentAuthor,
	|	CASE
	|		WHEN ModifiedRows.Period IS NULL THEN
	|			RegisterRecords.Comment
	|		ELSE
	|			CASE
	|				WHEN ModifiedRows.ManualAdjustment
	|				THEN ModifiedRows.Comment
	|				ELSE """"
	|			END
	|	END AS Comment,
	|	
	|	CASE
	|		WHEN ModifiedRows.Period IS NULL THEN
	|			RegisterRecords.InitialDemand
	|		ELSE
	|			CASE
	|				WHEN ModifiedRows.ManualAdjustment
	|				THEN ModifiedRows.InitialDemand
	|				ELSE 0
	|			END
	|	END AS InitialDemand,
	|	CASE
	|		WHEN ModifiedRows.Period IS NULL THEN
	|			RegisterRecords.InitialDemandForOrder
	|		ELSE
	|			CASE
	|				WHEN ModifiedRows.ManualAdjustment
	|				THEN ModifiedRows.InitialDemandForOrder
	|				ELSE 0
	|			END
	|	END AS InitialDemandForOrder,
	|	
	|	ISNULL(ModifiedRows.Count, RegisterRecords.Count) AS Count,
	|	ISNULL(ModifiedRows.ToOrder, RegisterRecords.ToOrder) AS ToOrder,
	|	
	|	ISNULL(ModifiedRows.RangeOfDemandFrom, RegisterRecords.RangeOfDemandFrom) AS RangeOfDemandFrom,
	|	ISNULL(ModifiedRows.RangeOfDemandTo, RegisterRecords.RangeOfDemandTo) AS RangeOfDemandTo,
	|	ISNULL(ModifiedRows.DemandRangeIsSpecified, RegisterRecords.DemandRangeIsSpecified) AS DemandRangeIsSpecified,
	|	CASE
	|		WHEN ModifiedRows.DemandRangeIsSpecified IS NULL THEN
	|			FALSE
	|		ELSE
	|			ModifiedRows.DemandRangeIsSpecified <> RegisterRecords.DemandRangeIsSpecified
	|			OR ModifiedRows.RangeOfDemandFrom <> RegisterRecords.RangeOfDemandFrom
	|			OR ModifiedRows.RangeOfDemandTo <> RegisterRecords.RangeOfDemandTo
	|	END AS ChangedNeedInterval,
	|	
	|	RegisterRecords.ProductionPlan AS Ref
	|	
	|INTO ProductionPlans
	|FROM
	|	AccumulationRegister.ProductionPlans AS RegisterRecords
	|		LEFT JOIN ModifiedRows AS ModifiedRows
	|		ON RegisterRecords.Period                      = ModifiedRows.Period
	|			AND RegisterRecords.Recorder              = ModifiedRows.Recorder
	|			AND RegisterRecords.ProductionPlan         = ModifiedRows.ProductionPlan
	|			AND RegisterRecords.Products             = ModifiedRows.Products
	|			AND RegisterRecords.Characteristic           = ModifiedRows.Characteristic
	|			AND RegisterRecords.BillOfMaterials             = ModifiedRows.BillOfMaterials
	|			AND RegisterRecords.Purpose               = ModifiedRows.Purpose
	|			AND RegisterRecords.ProductionIssueDateOfIntermediateProducts = ModifiedRows.ProductionIssueDateOfIntermediateProducts
	|			AND RegisterRecords.ToPlan            = ModifiedRows.ToPlan
	|		LEFT JOIN ModifiedSpecifications AS ModifiedSpecifications
	|		ON RegisterRecords.Period              = ModifiedSpecifications.Period
	|			AND RegisterRecords.Recorder      = ModifiedSpecifications.Recorder
	|			AND RegisterRecords.ProductionPlan = ModifiedSpecifications.ProductionPlan
	|			AND RegisterRecords.BillOfMaterials     = ModifiedSpecifications.BillOfMaterials
	|			AND RegisterRecords.Purpose       = ModifiedSpecifications.Purpose
	|		LEFT JOIN LinesOfBusiness AS LinesOfBusiness
	|		ON RegisterRecords.Purpose = LinesOfBusiness.Purpose
	|
	|WHERE
	|	RegisterRecords.Recorder IN(&Recorders)
	|	
	|UNION ALL
	|	
	|SELECT
	|	
	|	ModifiedRows.Period AS Period,
	|	ModifiedRows.Recorder AS Recorder,
	|	
	|	ModifiedRows.Products AS Products,
	|	ModifiedRows.Characteristic AS Characteristic,
	|	ModifiedRows.ProductionPlan AS ProductionPlan,
	|	ModifiedRows.BillOfMaterials AS BillOfMaterials,
	|	ModifiedRows.Purpose AS Purpose,
	|	LinesOfBusiness.LineOfBusiness AS LineOfBusiness,
	|	
	|	ModifiedRows.ToPlan AS ToPlan,
	|	ModifiedRows.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	ModifiedRows.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	ModifiedRows.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
	|	
	|	ModifiedSpecifications.Period IS NULL AS HasChanges,
	|	ISNULL(ModifiedSpecifications.RecountIsRequired, FALSE) AS RecountIsRequired,
	|	
	|	ModifiedSpecifications.RepeatedDecomposition        AS RepeatedDecomposition,
	|	ModifiedSpecifications.ProductionProcessType AS ProductionProcessType,
	|	
	|	ModifiedRows.ManualAdjustment AS ManualAdjustment,
	|	ModifiedRows.AdjustmentDate   AS AdjustmentDate,
	|	ModifiedRows.AdjustmentAuthor  AS AdjustmentAuthor,
	|	ModifiedRows.Comment         AS Comment,
	|	
	|	ModifiedRows.InitialDemand        AS InitialDemand,
	|	ModifiedRows.InitialDemandForOrder AS InitialDemandForOrder,
	|	
	|	ModifiedRows.Count AS Count,
	|	ModifiedRows.ToOrder    AS ToOrder,
	|	
	|	ModifiedRows.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	ModifiedRows.RangeOfDemandTo AS RangeOfDemandTo,
	|	ModifiedRows.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	FALSE AS ChangedNeedInterval,
	|	
	|	ModifiedRows.ProductionPlan AS Ref
	|FROM
	|	ModifiedRows AS ModifiedRows
	|		LEFT JOIN AccumulationRegister.ProductionPlans AS RegisterRecords
	|		ON RegisterRecords.Period                      = ModifiedRows.Period
	|			AND RegisterRecords.Recorder              = ModifiedRows.Recorder
	|			AND RegisterRecords.ProductionPlan         = ModifiedRows.ProductionPlan
	|			AND RegisterRecords.Products             = ModifiedRows.Products
	|			AND RegisterRecords.Characteristic           = ModifiedRows.Characteristic
	|			AND RegisterRecords.BillOfMaterials             = ModifiedRows.BillOfMaterials
	|			AND RegisterRecords.Purpose               = ModifiedRows.Purpose
	|			AND RegisterRecords.ProductionIssueDateOfIntermediateProducts = ModifiedRows.ProductionIssueDateOfIntermediateProducts
	|			AND RegisterRecords.ToPlan            = ModifiedRows.ToPlan
	|		LEFT JOIN ModifiedSpecifications AS ModifiedSpecifications
	|		ON ModifiedRows.Period              = ModifiedSpecifications.Period
	|			AND ModifiedRows.Recorder      = ModifiedSpecifications.Recorder
	|			AND ModifiedRows.ProductionPlan = ModifiedSpecifications.ProductionPlan
	|			AND ModifiedRows.BillOfMaterials     = ModifiedSpecifications.BillOfMaterials
	|			AND ModifiedRows.Purpose       = ModifiedSpecifications.Purpose
	|		LEFT JOIN LinesOfBusiness AS LinesOfBusiness
	|		ON ModifiedRows.Purpose = LinesOfBusiness.Purpose
	|
	|WHERE
	|	RegisterRecords.Recorder IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	RegisterRecords.Recorder AS Recorder,
	|	
	|	RegisterRecords.ProductionPlan AS ProductionPlan,
	|	RegisterRecords.Period           AS ProductionDate,
	|	RegisterRecords.BillOfMaterials     AS ProductBOM,
	|	RegisterRecords.Purpose       AS AssignmentOfProducts,
	|	RegisterRecords.Products     AS ProductsItems,
	|	RegisterRecords.Characteristic   AS ItemVariant,
	|	
	|	CASE
	|		WHEN NOT &AllowRepeatedUseOfCalculatedData OR MAX(RegisterRecords.RepeatedDecomposition)
	|			THEN 0
	|		ELSE
	|			SUM(RegisterRecords.Count)
	|	END
	|		AS Count,
	|	CASE
	|		WHEN NOT &AllowRepeatedUseOfCalculatedData OR MAX(RegisterRecords.RepeatedDecomposition)
	|			THEN 0
	|		ELSE
	|			SUM(RegisterRecords.ToOrder)
	|	END
	|		AS ToOrder,
	|	
	|	MAX(CAST(RegisterRecords.Count + 0.001 AS NUMBER(15,3))) AS NumberFieldOverflowCheck1,
	|	MAX(CAST(RegisterRecords.ToOrder    + 0.001 AS NUMBER(15,3))) AS NumberFieldOverflowCheck2,
	|	
	|	RegisterRecords.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	RegisterRecords.RangeOfDemandTo AS RangeOfDemandTo,
	|	RegisterRecords.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	RegisterRecords.ChangedNeedInterval AS ChangedNeedInterval,
	|	CASE
	|		WHEN NOT &AllowRepeatedUseOfCalculatedData OR MAX(RegisterRecords.RepeatedDecomposition)
	|			THEN FALSE
	|		ELSE
	|			MAX(RegisterRecords.ChangedNeedInterval)
	|	END AS ChangeNeedInterval
	|	
	|INTO AlteredRegisteredRecords
	|FROM
	|	ProductionPlans AS RegisterRecords
	|WHERE 
	|	RegisterRecords.RecountIsRequired
	|
	|GROUP BY
	|	RegisterRecords.Recorder,
	|	RegisterRecords.ProductionPlan,
	|	RegisterRecords.Period,
	|	RegisterRecords.BillOfMaterials,
	|	RegisterRecords.Purpose,
	|	RegisterRecords.Products,
	|	RegisterRecords.Characteristic,
	|	RegisterRecords.RangeOfDemandFrom,
	|	RegisterRecords.RangeOfDemandTo,
	|	RegisterRecords.DemandRangeIsSpecified,
	|	RegisterRecords.ChangedNeedInterval
	|
	|INDEX BY
	|	Recorder,
	|	ProductionPlan,
	|	ProductionDate,
	|	ProductBOM,
	|	AssignmentOfProducts,
	|	ProductsItems,
	|	ItemVariant
	|");
	
	Query.SetParameter("ProductionPlan", CalculationParameters.ProductionPlan);
	Query.SetParameter("CalculationSeparator", CalculationParameters.CalculationSeparator);
	
	Query.SetParameter("Recorders", Recorders);
	Query.SetParameter("ModifiedRows", ModifiedRows);
	
	Query.SetParameter("AllowRepeatedUseOfCalculatedData", CalculationParameters.AllowRepeatedUseOfCalculatedData);
	
	For Each KeyAndValue In CalculationParameters.Attributes Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Query.TempTablesManager = New TempTablesManager;
	QueryResult = Query.Execute();
	
	ListOfRequests = New ValueList();
	
	QueryText =
	"SELECT
	|	RegisterRecords.*,
	|	
	|	&Status AS Status,
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	&ProductionDispatcherBusinessUnit AS Department,
	|	
	|	&CalculationSeparator AS CalculationSeparator
	|FROM
	|	ProductionPlans AS RegisterRecords
	|WHERE
	|	(RegisterRecords.Count <> 0 OR RegisterRecords.ToOrder <> 0) OR RegisterRecords.ManualAdjustment
	|";
	ListOfRequests.Add(QueryText, "ProductionPlans");
	
	MovementRecalculationIsRequired = Not ValueIsFilled(ModifiedRows) Or QueryResult.Unload()[0].Count > 0; // Status update, recalculation of quantity
	If MovementRecalculationIsRequired Then
	
		QueryText =
		"SELECT
		|	RegisterRecords.*,
		|	&Status AS Status,
		|	ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.Count) AS Count
		|	
		|FROM
		|	AccumulationRegister.ReleasePlansProducts_ AS RegisterRecords
		|		LEFT JOIN AlteredRegisteredRecords AS AlteredRegisteredRecords
		|			ON RegisterRecords.Recorder             = AlteredRegisteredRecords.Recorder
		|			 AND RegisterRecords.ProductionPlan        = AlteredRegisteredRecords.ProductionPlan
		|			 AND RegisterRecords.ProductionDate        = AlteredRegisteredRecords.ProductionDate
		|			 AND RegisterRecords.ProductBOM   = AlteredRegisteredRecords.ProductBOM
		|			 AND RegisterRecords.AssignmentOfProducts     = AlteredRegisteredRecords.AssignmentOfProducts
		|			 AND RegisterRecords.ProductsItems   = AlteredRegisteredRecords.ProductsItems
		|			 AND RegisterRecords.ItemVariant = AlteredRegisteredRecords.ItemVariant
		|WHERE
		|	RegisterRecords.Recorder IN(&Recorders) AND ((ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.Count) <> 0)) 
		|";
		ListOfRequests.Add(QueryText, "ReleasePlansProducts_");
		
		QueryText =
		"SELECT
		|	RegisterRecords.*,
		|	&Status AS Status,
		|	ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.Count) AS Count,
		|	ISNULL(AlteredRegisteredRecords.ToOrder * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.ToOrder) AS ToOrder
		|FROM
		|	AccumulationRegister.MaterialConsumptionPlans AS RegisterRecords
		|		LEFT JOIN AlteredRegisteredRecords AS AlteredRegisteredRecords
		|			ON RegisterRecords.Recorder             = AlteredRegisteredRecords.Recorder
		|			 AND RegisterRecords.ProductionPlan        = AlteredRegisteredRecords.ProductionPlan
		|			 AND RegisterRecords.ProductionDate        = AlteredRegisteredRecords.ProductionDate
		|			 AND RegisterRecords.ProductBOM   = AlteredRegisteredRecords.ProductBOM
		|			 AND RegisterRecords.AssignmentOfProducts     = AlteredRegisteredRecords.AssignmentOfProducts
		|			 AND RegisterRecords.ProductsItems   = AlteredRegisteredRecords.ProductsItems
		|			 AND RegisterRecords.ItemVariant = AlteredRegisteredRecords.ItemVariant
		|WHERE
		|	RegisterRecords.Recorder IN(&Recorders) 
		|	AND (ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.Count) <> 0 OR ISNULL(AlteredRegisteredRecords.ToOrder * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.ToOrder) <> 0)
		|";
		ListOfRequests.Add(QueryText, "MaterialConsumptionPlans");
		
		QueryText =
		"SELECT
		|	RegisterRecords.Recorder AS Recorder,
		|	RegisterRecords.ProductionPlan AS ProductionPlan,
		|	RegisterRecords.ProductionDate AS ProductionDate,
		|	RegisterRecords.ProductBOM AS ProductBOM,
		|	RegisterRecords.AssignmentOfProducts AS AssignmentOfProducts,
		|	RegisterRecords.ProductsItems AS ProductsItems,
		|	RegisterRecords.ItemVariant AS ItemVariant,
		|	RegisterRecords.CalculationSeparator AS CalculationSeparator,
		|	RegisterRecords.WorkKind AS WorkKind,
		|	SUM(1) AS StageDuration
		|INTO TTStringsOfRegisteredRecords
		|FROM
		|	AccumulationRegister.PlansOfHumanResourcesOccupancy AS RegisterRecords
		|WHERE
		|	RegisterRecords.Recorder IN(&Recorders)
		|
		|GROUP BY
		|	RegisterRecords.Recorder,
		|	RegisterRecords.ProductionPlan,
		|	RegisterRecords.ProductionDate,
		|	RegisterRecords.ProductBOM,
		|	RegisterRecords.AssignmentOfProducts,
		|	RegisterRecords.ProductsItems,
		|	RegisterRecords.ItemVariant,
		|	RegisterRecords.CalculationSeparator,
		|	RegisterRecords.WorkKind
		|";
		ListOfRequests.Add(QueryText);
		
		QueryText = 
		"SELECT
		|	RegisterRecords.*,
		|	&Status AS Status,
		|	ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit / MovementStrings.StageDuration, RegisterRecords.Count) AS Count
		|FROM
		|	AccumulationRegister.PlansOfHumanResourcesOccupancy AS RegisterRecords
		|		LEFT JOIN AlteredRegisteredRecords AS AlteredRegisteredRecords
		|			ON RegisterRecords.Recorder             = AlteredRegisteredRecords.Recorder
		|			 AND RegisterRecords.ProductionPlan        = AlteredRegisteredRecords.ProductionPlan
		|			 AND RegisterRecords.ProductionDate        = AlteredRegisteredRecords.ProductionDate
		|			 AND RegisterRecords.ProductBOM   = AlteredRegisteredRecords.ProductBOM
		|			 AND RegisterRecords.AssignmentOfProducts     = AlteredRegisteredRecords.AssignmentOfProducts
		|			 AND RegisterRecords.ProductsItems   = AlteredRegisteredRecords.ProductsItems
		|			 AND RegisterRecords.ItemVariant = AlteredRegisteredRecords.ItemVariant
		|		LEFT JOIN TTStringsOfRegisteredRecords AS MovementStrings
		|			ON RegisterRecords.Recorder             = MovementStrings.Recorder
		|			 AND RegisterRecords.ProductionPlan        = MovementStrings.ProductionPlan
		|			 AND RegisterRecords.ProductionDate        = MovementStrings.ProductionDate
		|			 AND RegisterRecords.ProductBOM   = MovementStrings.ProductBOM
		|			 AND RegisterRecords.AssignmentOfProducts     = MovementStrings.AssignmentOfProducts
		|			 AND RegisterRecords.ProductsItems   = MovementStrings.ProductsItems
		|			 AND RegisterRecords.ItemVariant = MovementStrings.ItemVariant
		|			 AND RegisterRecords.CalculationSeparator      = MovementStrings.CalculationSeparator
		|			 AND RegisterRecords.WorkKind                = MovementStrings.WorkKind
		|WHERE
		|	RegisterRecords.Recorder IN(&Recorders)
		|	AND ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit / MovementStrings.StageDuration, RegisterRecords.Count) <> 0
		|";
		ListOfRequests.Add(QueryText, "PlansOfHumanResourcesOccupancy");
		QueryText =
		"SELECT
		|	RegisterRecords.*,
		|	&Status AS Status,
		|	ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.Occupation) AS Occupation
		|FROM
		|	AccumulationRegister.OccupancyPlansForWorkCenterTypes AS RegisterRecords
		|		LEFT JOIN AlteredRegisteredRecords AS AlteredRegisteredRecords
		|			ON RegisterRecords.Recorder             = AlteredRegisteredRecords.Recorder
		|			 AND RegisterRecords.ProductionPlan        = AlteredRegisteredRecords.ProductionPlan
		|			 AND RegisterRecords.ProductionDate        = AlteredRegisteredRecords.ProductionDate
		|			 AND RegisterRecords.ProductBOM   = AlteredRegisteredRecords.ProductBOM
		|			 AND RegisterRecords.AssignmentOfProducts     = AlteredRegisteredRecords.AssignmentOfProducts
		|			 AND RegisterRecords.ProductsItems   = AlteredRegisteredRecords.ProductsItems
		|			 AND RegisterRecords.ItemVariant = AlteredRegisteredRecords.ItemVariant
		|WHERE
		|	RegisterRecords.Recorder IN(&Recorders) AND ISNULL(AlteredRegisteredRecords.Count * RegisterRecords.QuantityPerProductsUnit, RegisterRecords.Occupation) <> 0
		|";
		ListOfRequests.Add(QueryText, "OccupancyPlansForWorkCenterTypes");
	EndIf;
	
	DataForRegisteredRecords = TMCommonUse.UploadResultsOfQuery(Query, ListOfRequests,, True);

	For Each KeyAndValue In DataForRegisteredRecords Do
		TableForRegisteredRecords = KeyAndValue.Value; // ValueTable - 
		TableForRegisteredRecords.Indexes.Add("Recorder");
	EndDo;
	
	MutableRegisters = StrSplit(CommonClientServer.StructureKeysToString(DataForRegisteredRecords, ","), ",");
	
	If CalculationParameters.AllowRepeatedUseOfCalculatedData Then
		RepeatCalculation = UploadDataForRedisclosing(DataForRegisteredRecords.ProductionPlans,
																CalculationParameters,
																New Structure(
																	"RecountIsRequired,
																	|RepeatedDecomposition",
																	True,
																	True));
		RepeatCalculation.Indexes.Add("Separator");
	Else
		RepeatCalculation = UploadDataForRedisclosing(DataForRegisteredRecords.ProductionPlans,
																CalculationParameters,
																New Structure(
																	"RecountIsRequired",
																	True));
		RepeatCalculation.Indexes.Add("Separator");
	EndIf;
	
	RepeatCalculationRequired = (RepeatCalculation.Count() > 0);
	
	If RepeatCalculationRequired Then
		
		CalculationResult2 = RepeatCalculation.CopyColumns("Separator"); // ValueTable - 
		CalculationResult2.Columns.Add("SpecificationData");
		
		StructureOfData = UnravelProducts(RepeatCalculation, CalculationParameters);
		
		If StructureOfData.HasError Then
			
			ErrorText = StructureOfData.ErrorText;
			Raise ErrorText;
			
		Else
			
			For Each SpecificationData In StructureOfData.SpecificationsData Do
				
				SpecificationData.MaterialsAndServices.Columns.Add("MaterialsWarehouse", New TypeDescription("CatalogRef.Warehouses"));
				SpecificationData.MaterialsAndServices.LoadColumn(SpecificationData.MaterialsAndServices.UnloadColumn("Warehouse"), "MaterialsWarehouse");
				
				If CalculationParameters.Attributes.TransferDemandOfBusinesUnitsThroughTransfers Then
					ForwardMovements(SpecificationData.MaterialsAndServices);
				EndIf;
				
				DistributionOfEmploymentByStageDuration(SpecificationData.LaborCosts);
				If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
					Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(SpecificationData);
					ExcludeNodesSubjectToRAndM(SpecificationData);
				EndIf;
				NewRow = CalculationResult2.Add();
				FillPropertyValues(NewRow, SpecificationData);
				NewRow.SpecificationData = SpecificationData;
			EndDo;
			
		EndIf;
		
		CalculationResult2.Indexes.Add("Separator");
		
	EndIf;
	
	AdjustedRows = ModifiedRows.FindRows(New Structure("ManualAdjustment", True));
	
	TimeIntervals = StructureOfCalculationOfPeriods();
	DetailsOfSpecifications = DetailsOfSpecifications(ModifiedRows, CalculationParameters);
	
	ListToWrite = New Array;
	
	StructureForCalculatingReleaseLaunchDates = New Structure();
	StructureForCalculatingReleaseLaunchDates.Insert("TimeIntervals", TimeIntervals);
	StructureForCalculatingReleaseLaunchDates.Insert("DetailsOfSpecifications", DetailsOfSpecifications);
	
	FilterOfRegisteredRecords = New Structure("Recorder");
	
	For Each Recorder In Recorders Do
		
		RegisterRecords = MotionRecordingSets(Recorder, MutableRegisters);
		FilterOfRegisteredRecords.Recorder = Recorder;
		
		For Each KeyAndValue In DataForRegisteredRecords Do
			RegisterRecords[KeyAndValue.Key].Load(KeyAndValue.Value.Copy(FilterOfRegisteredRecords));
		EndDo;
		
		AddRowsToCalculationOfReleaseLaunchDate(StructureForCalculatingReleaseLaunchDates, RegisterRecords.ProductionPlans);
		
		If RepeatCalculationRequired Then
			
			RecordSeparator = New Structure("Separator", Recorder);
			
			FillingValues = MotionFillValues(
				Recorder,
				CalculationParameters);
			
			FoundRows = CalculationResult2.FindRows(RecordSeparator);
			
			FillInRegisteredRecordsBasedOnCalculationResult(
				RegisterRecords,
				FillingValues,
				FoundRows,
				TimeIntervals);
			
		EndIf;
		
		ListToWrite.Add(New Structure("Recorder, NewRegistrar, RegisterRecords", Recorder, False, RegisterRecords));
		
	EndDo;
	
	FillInPeriodsInRegisteredRecords(CalculationParameters, TimeIntervals);
	
	RecordCalculationResult(ListToWrite, CalculationParameters, AdjustedRows);
	
EndProcedure

Procedure RunCancelingCalculation(ActionParameters, ResultAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InventoryPlanning.AdjustmentOfProductionPlan");
	
	CancelCalculationInsideTimeMeasurement(ActionParameters, ResultAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ActionParameters.Recorders.Count());

EndProcedure

Procedure CancelCalculationInsideTimeMeasurement(ActionParameters, ResultAddress)
	
	CalculationParameters = ActionParameters.CalculationParameters;
	Recorders     = ActionParameters.Recorders;
	
	ListToWrite = New Array;
	
	For Each Recorder In Recorders Do
		ListToWrite.Add(New Structure("Recorder, NewRegistrar, RegisterRecords", Recorder, False, MotionRecordingSets(Recorder)));
	EndDo;
	
	RecordCalculationResult(ListToWrite, CalculationParameters);
	
EndProcedure

Procedure RecordResultInCalculationProtocol(ResultAddress, CalculationProtocol)
	
	Return; // no additional actions are required in this configuration
	
EndProcedure

#EndRegion

#Region CalculationOfPeriods

// Returns the structure for calculating periods
//
// Returns:
//  Structure - Contains:
//   * LinesToSearchForward - ValueTable - Contains:
//                           ** StartingDate - Date - 
//                           ** NumberOfDays - Number -
//                           ** ToSearch - Boolean -
//                           ** FieldName - String -
//                           ** MovementTableRow - AccumulationRegisterRecord, ValueTableRow -
//   * LinesToSearchBack - ValueTable - Contains:
//                           ** StartingDate - Date - 
//                           ** NumberOfDays - Number -
//                           ** ToSearch - Boolean -
//                           ** FieldName - String -
//                           ** MovementTableRow - AccumulationRegisterRecord, ValueTableRow -
//
Function StructureOfCalculationOfPeriods()
	
	LinesToSearchForward = New ValueTable();
	LinesToSearchForward.Columns.Add("StartingDate", New TypeDescription("Date",,, New DateQualifiers));
	LinesToSearchForward.Columns.Add("NumberOfDays",   New TypeDescription("Number",  New NumberQualifiers));
	LinesToSearchForward.Columns.Add("ToSearch",      New TypeDescription("Boolean"));
	LinesToSearchForward.Columns.Add("FieldName");
	LinesToSearchForward.Columns.Add("MovementTableRow");
	
	LinesToSearchBack = New ValueTable();
	LinesToSearchBack.Columns.Add("StartingDate", New TypeDescription("Date",,, New DateQualifiers));
	LinesToSearchBack.Columns.Add("NumberOfDays",   New TypeDescription("Number",  New NumberQualifiers));
	LinesToSearchBack.Columns.Add("ToSearch",      New TypeDescription("Boolean"));
	LinesToSearchBack.Columns.Add("FieldName");
	LinesToSearchBack.Columns.Add("MovementTableRow");
	
	CalculationStructure = New Structure("LinesToSearchForward, LinesToSearchBack", LinesToSearchForward, LinesToSearchBack);
	Return CalculationStructure;
	
EndFunction

// Adds a string to the period calculation
// 
// Parameters:
//  StructureOfCalculationOfPeriods - See StructureOfCalculationOfPeriods
//  StartingDate - Date - Reference date
//  NumberOfDays - Number -
//  String - AccumulationRegisterRecord,ValueTableRow
//  FieldName - String - field name
Procedure AddLineToPeriodCalculation(StructureOfCalculationOfPeriods, StartingDate, NumberOfDays, String, FieldName = "Period")
	
	CalculationStructure =
		?(NumberOfDays > 1, StructureOfCalculationOfPeriods.LinesToSearchForward, StructureOfCalculationOfPeriods.LinesToSearchBack);
		
	NewRow = CalculationStructure.Add();
	
	NewRow.StartingDate = StartingDate;
	NewRow.NumberOfDays   = NumberOfDays * ?(NumberOfDays > 1, 1, -1);
	NewRow.ToSearch      = NumberOfDays <> 0;
	
	NewRow.FieldName = FieldName;
	NewRow.MovementTableRow = String;
	
EndProcedure

Procedure AddRowsToCalculationOfReleaseLaunchDate(StructureForCalculatingReleaseLaunchDates, Table)
	
	TimeIntervals               = StructureForCalculatingReleaseLaunchDates.TimeIntervals;
	DetailsOfSpecifications = StructureForCalculatingReleaseLaunchDates.DetailsOfSpecifications;
	
	For Each String In Table Do
		
		If String.DateOfOrderReleaseAndProductionIssue <> '00010101' Then
			Continue;
		EndIf;
		
		SpecificationDetails = DetailsOfSpecifications[String.BillOfMaterials];
		
		If SpecificationDetails = Undefined Then
			Continue;
		EndIf;
		
		If String.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			Or String.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
			Or String.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
			
			AddLineToPeriodCalculation(
				TimeIntervals,
				String.Period,
				-SpecificationDetails.Duration,
				String,
				"DateOfOrderReleaseAndProductionIssue");
			
		ElsIf String.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
			
			AddLineToPeriodCalculation(
				TimeIntervals,
				String.Period,
				SpecificationDetails.Duration,
				String,
				"DateOfOrderReleaseAndProductionIssue");
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInPeriodsInRegisteredRecords(CalculationParameters, StructureOfCalculationOfPeriods)
	
	Scenario = CalculationParameters.Attributes.Scenario;
	
	For Each KeyAndValue In StructureOfCalculationOfPeriods Do
		
		If Not ValueIsFilled(KeyAndValue.Value) Then
			Continue;
		EndIf;
		
		SearchForward = ?(KeyAndValue.Key = "LinesToSearchForward", True, False);
		RowFilter = New Structure("StartingDate, NumberOfDays");
		
		TimeIntervals = KeyAndValue.Value; // ValueTable - 
		TimeIntervals.Indexes.Add("StartingDate, NumberOfDays");
		TimeIntervals.Indexes.Add("ToSearch");
		
		DoNotSearchForStrings = TimeIntervals.FindRows(New Structure("ToSearch", False));
		
		For Each String In DoNotSearchForStrings Do
			String.MovementTableRow[String.FieldName] = String.StartingDate;
		EndDo;
		
		ReferenceDates = TimeIntervals.Copy(New Structure("ToSearch", True), "StartingDate, NumberOfDays");
		ReferenceDates.GroupBy("StartingDate, NumberOfDays");

		DatesBySchedule = Planning.GetDatesBySchedule(ReferenceDates,
															Scenario,
															SearchForward);
		
		For Each String In DatesBySchedule Do
			
			FillPropertyValues(RowFilter, String);
			FoundRegisteredRecords = TimeIntervals.FindRows(RowFilter);
			
			For Each Movement In FoundRegisteredRecords Do
				Movement.MovementTableRow[Movement.FieldName] = String.DateAccordingToSchedule;
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Adjusting

Procedure SaveManualAdjustmentsBeforeCalculation(ProductionPlan)
	
	Query = New Query(
	"SELECT
	|	Table.ProductionPlan AS ProductionPlan,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.BillOfMaterials AS BillOfMaterials,
	|	Table.StartDate2 AS StartDate2,
	|	Table.DateOfProduction AS DateOfProduction,
	|	Table.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	TRUE AS ToPlan,
	|	TRUE AS ThisIsASemiFinishedProduct,
	|	Table.Count AS Count,
	|	Table.ToOrder AS ToOrder,
	|	Table.AdjustmentDate AS AdjustmentDate,
	|	Table.AdjustmentAuthor AS AdjustmentAuthor,
	|	Table.Comment AS Comment
	|FROM
	|	InformationRegister.ProductionPlanAdjustmentContents AS Table
	|WHERE
	|	Table.ProductionPlan = &ProductionPlan
	|
	|UNION ALL
	|
	|SELECT
	|	Table.ProductionPlan,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.BillOfMaterials,
	|	CASE
	|		WHEN Table.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN Table.Period
	|		ELSE Table.DateOfOrderReleaseAndProductionIssue
	|	END,
	|	CASE
	|		WHEN Table.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN Table.DateOfOrderReleaseAndProductionIssue
	|		ELSE Table.Period
	|	END,
	|	Table.ProductionIssueDateOfIntermediateProducts,
	|	Table.ToPlan,
	|	Table.ThisIsASemiFinishedProduct,
	|	Table.Count,
	|	Table.ToOrder,
	|	Table.AdjustmentDate,
	|	Table.AdjustmentAuthor,
	|	Table.Comment
	|FROM
	|	AccumulationRegister.ProductionPlans AS Table
	|		LEFT JOIN InformationRegister.ProductionPlanAdjustmentContents AS ProductionPlanAdjustmentContents
	|		ON Table.ProductionPlan            = ProductionPlanAdjustmentContents.ProductionPlan
	|			AND Table.Products             = ProductionPlanAdjustmentContents.Products
	|			AND Table.Characteristic           = ProductionPlanAdjustmentContents.Characteristic
	|			AND Table.Purpose               = ProductionPlanAdjustmentContents.Purpose
	|			AND Table.ProductionIssueDateOfIntermediateProducts = ProductionPlanAdjustmentContents.ProductionIssueDateOfIntermediateProducts
	|WHERE
	|	Table.ProductionPlan = &ProductionPlan AND Table.ManualAdjustment AND ProductionPlanAdjustmentContents.ProductionPlan IS NULL
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ProductionPlanAdjustmentContents");
		LockItem.SetValue("ProductionPlan", ProductionPlan);
		Block.Lock();
		
		ListOfAdjustments = Query.Execute().Unload();
		
		InformationRegisters.CancelProductionPlanAdjustingEntries.RecordAdjustments(
			ListOfAdjustments,
			ProductionPlan,
			False);
		InformationRegisters.ProductionPlanAdjustmentContents.ClearQueue(ProductionPlan);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region MultiThreadedExecution

Function ThereAreFreeStreams(CalculationParameters)
	
	ThereAreFreeStreams = False;
	CalculationQueue = CalculationParameters.CalculationQueue;
	
	For IndexOf = -CalculationQueue.UBound() To 0 Do
		
		If CalculationQueue[-IndexOf] = Undefined Then
			ThereAreFreeStreams = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereAreFreeStreams;

EndFunction

Function GetPlaceInCalculationQueue(CalculationParameters, ItIsForbiddenToExecuteInSeparateThread)
	
	PlaceInQueue = 0;
	
	If CalculationParameters.VectorizeCalculation Then
		
		If ItIsForbiddenToExecuteInSeparateThread Or Not ThereAreFreeStreams(CalculationParameters) Then
			ExpectCalculationCompletion(CalculationParameters, ItIsForbiddenToExecuteInSeparateThread);
		EndIf;
		
		PlaceInQueue = CalculationParameters.CalculationQueue.Find(Undefined);
		
	EndIf;
	
	Return PlaceInQueue;
	
EndFunction

Function ExpectCalculationCompletion(CalculationParameters, ExpectCompletionOfCalculationOfAllThreads = True)
	
	CalculationIsCompleted = False;
	CalculationQueue = CalculationParameters.CalculationQueue; // See ProductionServer.ServiceStructureOfArrayOfStructures
	
	FilterStructure1 = New Structure();
	
	SetPrivilegedMode(True);
	
	While Not CalculationIsCompleted Do
		
		ActiveTasks = New Array();
		ThereAreCompletedTasks = False;
		
		For Stream = 0 To CalculationQueue.UBound() Do
			
			If CalculationQueue[Stream] = Undefined Then
				Continue;
			EndIf;
			
			FilterStructure1.Insert("UUID", CalculationQueue[Stream].Id);
			
			JobsList = BackgroundJobs.GetBackgroundJobs(FilterStructure1);
			
			If JobsList.UBound() <> -1 Then
				
				If JobsList[0].State = BackgroundJobState.Active Then
					ActiveTasks.Add(JobsList[0].UUID);
					Continue;
				EndIf;
				
				If JobsList[0].State = BackgroundJobState.Failed Then
					ErrorText = DetailErrorDescription(JobsList[0].ErrorInfo);
					Raise ErrorText;
				EndIf;
				
			EndIf;
			
			RecordResultInCalculationProtocol(CalculationQueue[Stream].ResultAddress, CalculationParameters["CalculationProtocol"]);
			
			CalculationQueue[Stream] = Undefined;
			ThereAreCompletedTasks = True;
			
		EndDo;
		
		CalculationIsCompleted = (ThereAreCompletedTasks And Not ExpectCompletionOfCalculationOfAllThreads) Or Not ValueIsFilled(ActiveTasks);
		
		If Not CalculationIsCompleted Then
			
			Job = BackgroundJobs.FindByUUID(ActiveTasks[0]);
			
			If Job <> Undefined Then
				Try
					Job.WaitForCompletion(CalculationParameters.IntervalForCheckingCompletionOfCalculation);
				Except
					// Special processing is not required, the exception may be caused by a timeout.
				EndTry;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return CalculationIsCompleted;
	
EndFunction

#EndRegion

#Region Record

Function RecordCalculationResult(ListToWrite, CalculationParameters, AdjustedRows = Undefined)
	
	NumberOfWriteAttempts = ?(TransactionActive(), 1, 3);
	
	FillingValues = DocumentFillValues(CalculationParameters);
	
	SetPrivilegedMode(True);
	
	For Each DataToWrite In ListToWrite Do
		
		Recorder = DataToWrite.Recorder;
		
		If TypeOf(Recorder) <> Type("DocumentRef.RegisterProductionPlan") Then
			Continue;
		EndIf;
		
		WriteDocument = DataToWrite.RegisterRecords["ProductionPlans"].Count() > 0;
		
		If DataToWrite.NewRegistrar And Not WriteDocument Then
			Continue;
		EndIf;
		
		Replace = Not DataToWrite.NewRegistrar;
		
		ErrorCounter = 1;
		While True Do
			
			BeginTransaction();
			Try
				
				If Common.FileInfobase() Then
					Block = New DataLock;
					LockItem = Block.Add("Document.ProductionPlan");
					LockItem.SetValue("Ref", CalculationParameters.ProductionPlan);
					Block.Lock();
				EndIf;
				
				If DataToWrite.NewRegistrar Then
					
					DocumentObject = Documents.RegisterProductionPlan.CreateDocument();
					DocumentObject.SetNewObjectRef(Recorder);
					
				Else
					
					Block = New DataLock;
					LockItem = Block.Add("Document.RegisterProductionPlan");
					LockItem.SetValue("Ref", Recorder);
					Block.Lock();
					
					DocumentObject = Recorder.GetObject();
					
				EndIf;
				
				If WriteDocument Then
					
					FillPropertyValues(DocumentObject, FillingValues);
					
					If DataToWrite.Property("MaximumRecordingPortionExceeded") Then
						DocumentObject.MaximumRecordingPortionExceeded = DataToWrite.MaximumRecordingPortionExceeded;
					EndIf;
					
					DocumentObject.Posted        = True;
					DocumentObject.DeletionMark = False;
					
					DocumentObject.DataExchange.Load = True;
					
					DocumentObject.Write(DocumentWriteMode.Write); // RefreshEnabled
					
				Else
					
					FillPropertyValues(DocumentObject, FillingValues);
					
					DocumentObject.MaximumRecordingPortionExceeded = False;
					
					DocumentObject.Posted        = False;
					DocumentObject.DeletionMark = True;
					
					DocumentObject.DataExchange.Load = True;
					
					DocumentObject.Write(DocumentWriteMode.Write); // Mark for deletion
					
				EndIf;
				
				For Each KeysAndValue In DataToWrite.RegisterRecords Do
					
					RecordSet = KeysAndValue.Value;
					RecordSet.AdditionalProperties.Insert("SettlementMode", CalculationParameters.SettlementMode);
					
					If Not Replace
						And RecordSet.Count() > CalculationParameters.NumberOfRowsInTheRecordset Then
						
						RowsCount = RecordSet.Count();
						Table = RecordSet.Unload();
						
						TotalServings = Round(RowsCount/CalculationParameters.NumberOfRowsInTheRecordset + 0.5, 0, 0);
						Divisor = New Array(TotalServings);
						
						Counter = 0;
						PortionNumber = 0;
						For Each String In Table Do
							If Counter >= CalculationParameters.NumberOfRowsInTheRecordset Then
								Counter = 0;
								PortionNumber = PortionNumber + 1;
							EndIf;
							If Divisor[PortionNumber] = Undefined Then
								PortionSize = Min(CalculationParameters.NumberOfRowsInTheRecordset, RowsCount - CalculationParameters.NumberOfRowsInTheRecordset * PortionNumber);
								Divisor[PortionNumber] = New Array(PortionSize);
							EndIf;
							Divisor[PortionNumber][Counter] = String;
							Counter = Counter + 1;
						EndDo;
						
						For Each StringsList In Divisor Do
							RecordSet.Load(Table.Copy(StringsList));
							RecordSet.Write(False);
						EndDo;
						
						Table = Undefined;
						Divisor = Undefined;
						
					Else
						RecordSet.Write(Replace);
					EndIf;
					
				EndDo;
				InformationRegisters.ProductionPlanAdjustmentContents.MarkCompletion(CalculationParameters.ProductionPlan, AdjustedRows);
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				If ErrorCounter >= NumberOfWriteAttempts Then
					ErrorText = DetailErrorDescription(ErrorInfo());
					Raise ErrorText;
				EndIf;
				
				ErrorCounter = ErrorCounter + 1;
				Continue;
				
			EndTry;
			
			Break;
			
		EndDo;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndFunction

#EndRegion

#Region RegisterRecords

Function MotionRecordingSets(Recorder, Registers = Undefined)
	
	MotionMetadata = Metadata.Documents.RegisterProductionPlan.RegisterRecords;
	RegisterRecords = New Structure();
	
	For Each Register In MotionMetadata Do
		If Registers <> Undefined
			And Registers.Find(Register.Name) = Undefined Then
			Continue;
		EndIf;
		RecordSet = AccumulationRegisters[Register.Name].CreateRecordSet(); // AccumulationRegisterRecordSet - 
		RecordSet.Filter.Recorder.Set(Recorder);
		RegisterRecords.Insert(Register.Name, RecordSet);
	EndDo;
	
	Return RegisterRecords;
	
EndFunction

Function DocumentFillValues(CalculationParameters)
	
	Attributes = CalculationParameters.Attributes;
	
	Result = New Structure;
	
	Result.Insert("Date", CurrentSessionDate());
	
	Result.Insert("ProductionPlan",   CalculationParameters.ProductionPlan);
	Result.Insert("CalculationSeparator", CalculationParameters.CalculationSeparator);
	
	Result.Insert("Status", Attributes.Status);
	
	Return Result;
	
EndFunction

Function MotionFillValues(Recorder, CalculationParameters)
	
	Attributes = CalculationParameters.Attributes;
	
	Result = New Structure;
	
	Result.Insert("Recorder", Recorder);
	Result.Insert("Active", True);
	
	Result.Insert("ProductionPlan",   CalculationParameters.ProductionPlan);
	Result.Insert("CalculationSeparator", CalculationParameters.CalculationSeparator);
	
	Result.Insert("Status",                       Attributes.Status);
	Result.Insert("Scenario",                     Attributes.Scenario);
	Result.Insert("PlanProfile",                     Attributes.PlanProfile);
	Result.Insert("ProductionDispatcherBusinessUnit",       Attributes.ProductionDispatcherBusinessUnit);
	
	Return Result;
	
EndFunction

// Fill in the movements based on the calculation result.
// 
// Parameters:
//  RegisterRecords - Structure - Contains:
//  	* ProductionPlans - AccumulationRegisterRecordSet - 
//  	* ReleasePlansProducts_ - AccumulationRegisterRecordSet - 
//  	* MaterialConsumptionPlans - AccumulationRegisterRecordSet - 
//  	* PlansOfHumanResourcesOccupancy - AccumulationRegisterRecordSet - 
//  	* OccupancyPlansForWorkCenterTypes - AccumulationRegisterRecordSet - 
//  FillingValues - Structure - Fill-in values:
//  	* Active - Boolean -
//  CalculationResult2 - Array of ValueTableRow - Where:
//  	*SpecificationData - Structure - Where:
//  		** ManufacturedProducts - ValueTable
//  		** RecyclableWaste - ValueTable
//  		** LaborCosts - ValueTable
//  TimeIntervals - See StructureOfCalculationOfPeriods
Procedure FillInRegisteredRecordsBasedOnCalculationResult(RegisterRecords, FillingValues, CalculationResult2, TimeIntervals)
	
	For Each ResultString1 In CalculationResult2 Do // Resource usage plans
		
		Data = ResultString1.SpecificationData;
		
		AddRegisteredRecordsToProductReleasePlans(RegisterRecords, FillingValues, Data, Data.ManufacturedProducts,  "Main", TimeIntervals);
		AddRegisteredRecordsToProductReleasePlans(RegisterRecords, FillingValues, Data, Data.RecyclableWaste, "SideEffect", TimeIntervals);
	
		AddRegisteredRecordsToMaterialConsumptionPlans(RegisterRecords, FillingValues, Data, Data.MaterialsAndServices, TimeIntervals);
		AddIncomingItemRegisteredRecordsToMaterialConsumptionPlans(RegisterRecords, FillingValues, Data, Data.IncomingProducts, TimeIntervals);
		AddRegisteredRecordsToWorkforceEmploymentPlans(RegisterRecords, FillingValues, Data, Data.LaborCosts, TimeIntervals);
		AddRegisteredRecordsToEmploymentPlansForWorkCenters(RegisterRecords, FillingValues, Data, Data.WorkCenterTypes, TimeIntervals);
	EndDo;
	
EndProcedure

// Fills in movements in production plans
// 
// Parameters:
//  RegisterRecords - Structure - Contains:
// * ProductionPlans - AccumulationRegisterRecordSet -
//  FillingValues - Structure - Fill-in values:
// * Active - Boolean -
//  Table - Array of ValueTableRow - Table
//  DetailsOfSpecifications - Map - details of specifications
//  TimeIntervals - See StructureOfCalculationOfPeriods
Procedure FillInRegisteredRecordsInProductionPlans(RegisterRecords, FillingValues, Table, DetailsOfSpecifications, TimeIntervals)
	
	For Each String In Table Do // Production plan
		
		SpecificationDetails = DetailsOfSpecifications[String.BillOfMaterials];
		
		NewRow = RegisterRecords.ProductionPlans.Add();
		NewRow.Period = String.ProductionDate; // the period can be changed during consolidation and manual editing
		
		FillPropertyValues(NewRow, String); // Products,Characteristic,BillOfMaterials,Purpose,ThisIsASemiFinishedProduct,ProductionIssueDateOfIntermediateProducts,DateOfOrderReleaseAndProductionIssue
		FillPropertyValues(NewRow, FillingValues); // Scenario,Status,ProductionPlan
		
		NewRow.Department = FillingValues.ProductionDispatcherBusinessUnit;
		NewRow.ProductionProcessType = SpecificationDetails.ProductionProcessType;
		
		NewRow.Count = String.Count;
		NewRow.ToOrder    = String.ToOrder;
		
		If NewRow.DateOfOrderReleaseAndProductionIssue = '00010101' Then
			
			If NewRow.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
				Or NewRow.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
				Or NewRow.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
				
				AddLineToPeriodCalculation(
					TimeIntervals,
					NewRow.Period,
					-SpecificationDetails.Duration,
					NewRow,
					"DateOfOrderReleaseAndProductionIssue");
				
			ElsIf NewRow.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
				
				AddLineToPeriodCalculation(
					TimeIntervals,
					NewRow.Period,
					SpecificationDetails.Duration,
					NewRow,
					"DateOfOrderReleaseAndProductionIssue");
				
			EndIf;
			
		EndIf;
		
		NewRow.RepeatedDecomposition = SpecificationDetails.RepeatedDecomposition;
		
	EndDo;
	
EndProcedure

// Puts in motion plans for the release of products
//
Procedure AddRegisteredRecordsToProductReleasePlans(RegisterRecords, FillingValues, Data, Table, TypeOfProductionIssue, TimeIntervals)
	
	For Each String In Table Do //ValueTableRow
		
		If String.RecipientStageCode <> 0 // we exclude semi-finished products produced in the process and at the stage
			Or String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess 
			Or String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess Then
			Continue;
		EndIf;
		
		If (String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
				And Not ValueIsFilled(String.Products)
			Or String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData
				And Not ValueIsFilled(String.Characteristic)) Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 trong dòng số%2 của danh sách ""Sản phẩm đầu ra"" không thể chọn tự động mặt hàng do nguyên nhân: %3.';
							|ru = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Выходные изделия"" не удалось выполнить автовыбор номенклатуры по причине: %3.';
							|en = 'Cannot autoselect an item while exploding the product by the %1 BOM in line No. %2 of the ""Finished products"" list due to: %3.'; fa = 'Cannot autoselect an item while exploding the product by the %1 BOM in line No. %2 of the ""Finished products"" list due to: %3.';
							|it = 'Durante la scomposizione del prodotto per specifica ""%1"" nella riga №%2 dell''elenco ""Prodotti finiti"" non è stato possibile eseguire la selezione automatica dell''articolo a causa di: %3.';
							|pl = 'Przy rozbiciu wyrobu według specyfikacji ""%1"" w wierszu nr%2 listy „Wyroby wyjściowe” nie udało się wykonać automatycznego wyboru produktu z powodu: %3.';
							|tr = '""Çıkan nihai ürünler"" listesinin %2 numaralı satırında %1 ürün reçetesine göre nihai ürün ayrıştırılırken, aşağıdaki nedenden dolayı otomatik ürün seçimi gerçekleştirilemedi: %3.'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.LineNumber, String.AutoselectionDetails);
			Raise ErrorText;
		EndIf;
		
		If String.Count = 0
				And Not IsBlankString(String.Formula)
				And Not IsBlankString(String.FormulaCalculationError) Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 trong dòng số%2 của danh sách ""Sản phẩm đầu ra"" không thể chọn tự động mặt hàng do nguyên nhân: %3.';
							|ru = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Выходные изделия"" не удалось рассчитать количество по формуле по причине: %3.';
							|en = 'Cannot calculate the quantity using the formula while exploding the item by the %1 BOM in line %2 of the ""Finished products"" list due to: %3.'; fa = 'Cannot calculate the quantity using the formula while exploding the item by the %1 BOM in line %2 of the ""Finished products"" list due to: %3.';
							|it = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Выходные изделия"" не удалось рассчитать количество по формуле по причине: %3.';
							|pl = 'Cannot calculate the quantity using the formula while exploding the item by the %1 BOM in line %2 of the ""Finished products"" list due to: %3.';
							|tr = '""Çıkan nihai ürünler"" listesinin %2 numaralı satırında %1 ürün reçetesine göre nihai ürün ayrıştırılırken, şu sebepten dolayı formül kullanılarak miktar hesaplanamadı: %3.'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.LineNumber, String.FormulaCalculationError);
			Raise ErrorText;
		EndIf;
		
		NewRow = RegisterRecords.ReleasePlansProducts_.Add();
		
		FillPropertyValues(NewRow, String); // Nomenclature, Characteristics,
		FillPropertyValues(NewRow, FillingValues); // Scenario,Status,Subdivision Dispatcher,Production plan
		
		NewRow.TypeOfProductionIssue = Enums.ReleaseTypesOfProductionPlan[TypeOfProductionIssue];
		
	#Region DecryptionOfProducts
		NewRow.ProductionDate        = Data.ProductionDate;
		NewRow.AssignmentOfProducts     = Data.AssignmentOfProducts;
		NewRow.ProductBOM   = Data.ProductBOM;
		NewRow.ProductsItems   = Data.ProductsItems;
		NewRow.ItemVariant = Data.ItemVariant;
	#EndRegion
	
		NewRow.BillOfMaterials = Data.BillOfMaterials;
		
		If Data.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
			NewRow.Purpose = Data.AssignmentOfProducts;
		EndIf;
		
		NewRow.AssigneeBusinessUnit = String.StageSubdivision;
		
		If String.ProductQuantity > 0
			And Data.ProductionIssueByCustomPortions
			And Not Data.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList Then
			NewRow.QuantityPerProductsUnit = String.NumberOfPackagesPerUnitOfProductionBatch
				* String.PackageData.Numerator / (String.PackageData.Denominator * String.ProductQuantity);
		Else
			NewRow.QuantityPerProductsUnit = 0;
		EndIf;
		
		CalculateResource(NewRow, String, Data, "Count", "Count");
		CalculateResource(NewRow, String, Data, "Count", "ToOrder");
		
		AddLineToPeriodCalculation(
			TimeIntervals,
			Data.ProductionDate,
			String.DaysFromDemand,
			NewRow);
		
	EndDo;
	
EndProcedure

Procedure CalculateResource(String, SpecificationLine, Data, FieldNameQuantity, ResourceName)

	If ResourceName = "ToOrder" Then
		NumeratorFactor = ?(Data.CalculationBaseForOrder>0, Data.CalculationBaseForOrder, -Data.CalculationBaseForOrder);
		FactorDenominator = Data.QuantityToBeCalculated;
	Else
		NumeratorFactor = ?(Data.CalculationBaseQuantity>0, Data.CalculationBaseQuantity, -Data.CalculationBaseQuantity);
		FactorDenominator = Data.QuantityToBeCalculated;
	EndIf;
	
	If FactorDenominator = 0 Then
		String[ResourceName] = 0;
	Else
		String[ResourceName] = SpecificationLine[FieldNameQuantity] * (NumeratorFactor/FactorDenominator) * ?(Data.RecordType = AccumulationRecordType.Receipt, 1, -1);
	EndIf;
	
EndProcedure

// Adds traffic to the material consumption plan
//
Procedure AddRegisteredRecordsToMaterialConsumptionPlans(RegisterRecords, FillingValues, Data, Table, TimeIntervals)
	
	For Each String In Table Do //ValueTableRow
		
		If String.ItemsType = Enums.ItemsTypes.Set
				And Not ValueIsFilled(String.Products)
				And String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 trong dòng số%2 của danh sách ""Nguyên vật liệu và công việc"": %3';
							|ru = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Материалы и работы"": %3';
							|en = 'While exploding the product by the %1 bill of materials in line No. %2 of the ""Materials and works"" list: %3'; fa = 'While exploding the product by the %1 bill of materials in line No. %2 of the ""Materials and works"" list: %3';
							|it = 'Durante l''esplosione della produzione per specifiche %1 "" nella riga №%2 dell''elenco ""Materiali e lavori"":%3';
							|pl = 'Przy rozbiciu wyrobu według specyfikacji %1 w wierszu nr%2 listy ""Materiały i prace"": %3';
							|tr = '""Malzemeler ve işler"" listesinin %2 numaralı satırındaki %1 ürün reçetesine göre nihai ürünler ayrıştırılırken: %3'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.LineNumber, String.AutoselectionDetails);
			Raise ErrorText;
		EndIf;
		
		If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
			Or String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
			Or String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess Then
			Continue;
		EndIf;
		
		If String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
				And Not ValueIsFilled(String.Products)
			Or (String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData 
				And String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess)
					And Not ValueIsFilled(String.Characteristic) Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 trong dòng số%2 của danh sách ""Nguyên vật liệu và công việc"" không thể tự động chọn mặt hàng do nguyên nhân: %3.';
							|ru = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Материалы и работы"" не удалось выполнить автовыбор номенклатуры по причине: %3.';
							|en = 'Cannot autoselect products while exploding the product by BOM %1 in line %2 of the list ""Materials and works"". Reason: %3.'; fa = 'Cannot autoselect products while exploding the product by BOM %1 in line %2 of the list ""Materials and works"". Reason: %3.';
							|it = 'Durante la scomposizione del prodotto per specifica %1 nella riga №%2 dell''elenco ""Materiali e lavori"" non è stato possibile eseguire la selezione automantica dell''articolo a causa di: %3.';
							|pl = 'Przy rozbiciu wyrobu według specyfikacji ""%1"" w wierszu nr%2 listy ""Materiały i prace"" nie udało się wykonać automatycznego wyboru produktu z powodu: %3.';
							|tr = '""Malzemeler ve işler"" listesinin %2 numaralı satırında %1 ürün reçetesine göre nihai ürün ayrıştırılırken, aşağıdaki nedenden dolayı otomatik ürün seçimi gerçekleştirilemedi: %3.'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.LineNumber, String.AutoselectionDetails);
			Raise ErrorText;
		EndIf;
		
		If String.Count = 0
				And Not IsBlankString(String.Formula)
				And Not IsBlankString(String.FormulaCalculationError) Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 trong dòng số%2 của danh sách ""Nguyên vật liệu và công việc"" không thể tính số lượng theo công thức do nguyên nhân: %3.';
							|ru = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Материалы и работы"" не удалось рассчитать количество по формуле по причине: %3.';
							|en = 'Cannot calculate the quantity using the formula while exploding the item by the %1 BOM in line %2 of the ""Materials and works"" list due to: %3.'; fa = 'Cannot calculate the quantity using the formula while exploding the item by the %1 BOM in line %2 of the ""Materials and works"" list due to: %3.';
							|it = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Материалы и работы"" не удалось рассчитать количество по формуле по причине: %3.';
							|pl = 'Cannot calculate the quantity using the formula while exploding the item by the %1 BOM in line %2 of the ""Materials and works"" list due to: %3.';
							|tr = '""Malzemeler ve işler"" listesinin %2 numaralı satırındaki %1 ürün reçetesine göre nihai ürün ayrıştırılırken, şu nedenden dolayı formül kullanılarak miktar hesaplanamadı: %3.'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.LineNumber, String.FormulaCalculationError);
			Raise ErrorText;
		EndIf;
		
		NewRow = RegisterRecords.MaterialConsumptionPlans.Add();
		
		FillPropertyValues(NewRow, String); // Products,Characteristic,Warehouse
		FillPropertyValues(NewRow, FillingValues); // Scenario,Status,Subdivision Dispatcher,Production plan
		
	#Region DecryptionOfProducts
		NewRow.ProductionDate        = Data.ProductionDate;
		NewRow.AssignmentOfProducts     = Data.AssignmentOfProducts;
		NewRow.ProductBOM   = Data.ProductBOM;
		NewRow.ProductsItems   = Data.ProductsItems;
		NewRow.ItemVariant = Data.ItemVariant;
	#EndRegion
		
		NewRow.AssigneeBusinessUnit = String.StageSubdivision;
		
		If String.WithAssignment Then
			NewRow.Purpose = Data.AssignmentOfProducts;
		EndIf;
		
		If String.ToPlan Then
			NewRow.ThisIsASemiFinishedProduct = True;
		EndIf;
		
		If String.ProductQuantity > 0
			And Data.ProductionIssueByCustomPortions
			And Not Data.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList Then
			NewRow.QuantityPerProductsUnit = String.NumberOfPackagesPerUnitOfProductionBatch
				* String.PackageData.Numerator / (String.PackageData.Denominator * String.ProductQuantity);
		Else
			NewRow.QuantityPerProductsUnit = 0;
		EndIf;
		
		CalculateResource(NewRow, String, Data, "Count", "Count");
		CalculateResource(NewRow, String, Data, "Count", "ToOrder");
		
		AddLineToPeriodCalculation(
			TimeIntervals,
			Data.ProductionDate,
			String.DaysFromDemand,
			NewRow);
			
	EndDo;
	
EndProcedure

// Adds the movements of incoming goods into the plans of material consumption
//
Procedure AddIncomingItemRegisteredRecordsToMaterialConsumptionPlans(RegisterRecords, FillingValues, Data, Table, TimeIntervals)
	
	If Data.BillOfMaterials <> Data.ProductBOM Then // we exclude semi-finished products produced in the process
		Return;
	EndIf;

	For Each String In Table Do
		
		NewRow = RegisterRecords.MaterialConsumptionPlans.Add();
		
		FillPropertyValues(NewRow, String); // Nomenclature, Characteristics, Warehouse
		FillPropertyValues(NewRow, FillingValues); // Scenario,Status,Subdivision Dispatcher,Production plan
		
	#Region DecryptionOfProducts
		NewRow.ProductionDate        = Data.ProductionDate;
		NewRow.AssignmentOfProducts     = Data.AssignmentOfProducts;
		NewRow.ProductBOM   = Data.ProductBOM;
		NewRow.ProductsItems   = Data.ProductsItems;
		NewRow.ItemVariant = Data.ItemVariant;
	#EndRegion
		
		NewRow.Purpose = Data.AssignmentOfProducts;
		NewRow.AssigneeBusinessUnit = String.StageSubdivision;
		
		If String.ProductQuantity > 0
			And Data.ProductionIssueByCustomPortions
			And Not Data.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList Then
			NewRow.QuantityPerProductsUnit = String.NumberOfPackagesPerUnitOfProductionBatch
				* String.PackageData.Numerator / (String.PackageData.Denominator * String.ProductQuantity);
		Else
			NewRow.QuantityPerProductsUnit = 0;
		EndIf;
		
		CalculateResource(NewRow, String, Data, "Count", "Count");
		CalculateResource(NewRow, String, Data, "Count", "ToOrder");
		
		AddLineToPeriodCalculation(
			TimeIntervals,
			Data.ProductionDate,
			String.DaysFromDemand,
			NewRow);
		
	EndDo;
	
EndProcedure
Procedure AddRegisteredRecordsToWorkforceEmploymentPlans(RegisterRecords, FillingValues, Data, Table, TimeIntervals)
	
	For Each String In Table Do
		
		If String.Count = 0
				And Not IsBlankString(String.Formula)
				And Not IsBlankString(String.FormulaCalculationError) Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 trong dòng số%2 của danh sách ""Sản phẩm đầu ra"" không thể chọn tự động mặt hàng do nguyên nhân: %3.';
							|ru = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Трудозатраты"" не удалось рассчитать количество по формуле по причине: %3.';
							|en = 'Cannot calculate the quantity using the formula while exploding the product by the %1 BOM in line %2 of the ""Labor costs"" list due to: %3.'; fa = 'Cannot calculate the quantity using the formula while exploding the product by the %1 BOM in line %2 of the ""Labor costs"" list due to: %3.';
							|it = 'При разузловании изделия по спецификации %1 в строке №%2 списка ""Трудозатраты"" не удалось рассчитать количество по формуле по причине: %3.';
							|pl = 'Cannot calculate the quantity using the formula while exploding the product by the %1 BOM in line %2 of the ""Labor costs"" list due to: %3.';
							|tr = '""İş gücü maliyetleri"" listesinin %2 numaralı satırında %1 ürün reçetesine göre nihai ürün ayrıştırılırken, şu nedenden dolayı formül kullanılarak miktar hesaplanamadı: %3.'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.LineNumber, String.FormulaCalculationError);
			Raise ErrorText;
		EndIf;
		
		NewRow = RegisterRecords.PlansOfHumanResourcesOccupancy.Add();
		
		FillPropertyValues(NewRow, String);
		FillPropertyValues(NewRow, FillingValues);
		
	#Region DecryptionOfProducts
		NewRow.ProductionDate        = Data.ProductionDate;
		NewRow.AssignmentOfProducts     = Data.AssignmentOfProducts;
		NewRow.ProductBOM   = Data.ProductBOM;
		NewRow.ProductsItems   = Data.ProductsItems;
		NewRow.ItemVariant = Data.ItemVariant;
	#EndRegion
		
		NewRow.AssigneeBusinessUnit = String.StageSubdivision;
		
		If String.ProductQuantity > 0
			And Data.ProductionIssueByCustomPortions
			And Not Data.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList Then
			NewRow.QuantityPerProductsUnit = String.QuantityPerReleaseLotUnit / String.ProductQuantity;
		Else
			NewRow.QuantityPerProductsUnit = 0;
		EndIf;
		
		CalculateResource(NewRow, String, Data, "Count", "Count");
		
		AddLineToPeriodCalculation(
			TimeIntervals,
			Data.ProductionDate,
			String.DaysFromDemand,
			NewRow);
		
	EndDo;
	
EndProcedure

// Adds traffic to employment plans for types of work centers
//
Procedure AddRegisteredRecordsToEmploymentPlansForWorkCenters(RegisterRecords, FillingValues, Data, Table, TimeIntervals)
	
	For Each String In Table Do
		
		If String.OperationTime = 0
				And Not IsBlankString(String.Formula)
				And Not IsBlankString(String.FormulaCalculationError) Then
			Template = NStr("vi = 'Khi tách sản phẩm theo bảng kê chi tiết %1 không thể tính thời gian làm việc của năng lực sản xuất ""%2"" ở giai đoạn ""%3"" theo nguyên nhân: %4.';
							|ru = 'При разузловании изделия по спецификации %1 не удалось рассчитать время работы рабочего центра ""%2"" на этапе ""%3"" по причине: %4.';
							|en = 'Cannot calculate working hours of the ""%2"" work center while exploding the item by the ""%1"" BOM on the ""%3"" stage due to: %4.'; fa = 'Cannot calculate working hours of the ""%2"" work center while exploding the item by the ""%1"" BOM on the ""%3"" stage due to: %4.';
							|it = 'При разузловании изделия по спецификации %1 не удалось рассчитать время работы рабочего центра ""%2"" на этапе ""%3"" по причине: %4.';
							|pl = 'Cannot calculate working hours of the ""%2"" work center while exploding the item by the ""%1"" BOM on the ""%3"" stage due to: %4.';
							|tr = '%1 ürün reçetesine göre nihai ürün ayrıştırılırken, ""%2"" iş merkezinin ""%3"" aşamasındaki çalışma süresi şu nedenden dolayı hesaplanamadı: %4.'");
			ErrorText = StrTemplate(Template, BillOfMaterialsPresentation(Data.BillOfMaterials), String.WorkCenterType, String.Stage, String.FormulaCalculationError);
			Raise ErrorText;
		EndIf;

		NewRow = RegisterRecords.OccupancyPlansForWorkCenterTypes.Add();
		
		FillPropertyValues(NewRow, String);
		FillPropertyValues(NewRow, FillingValues);
		
	#Region DecryptionOfProducts
		NewRow.ProductionDate        = Data.ProductionDate;
		NewRow.AssignmentOfProducts     = Data.AssignmentOfProducts;
		NewRow.ProductBOM   = Data.ProductBOM;
		NewRow.ProductsItems   = Data.ProductsItems;
		NewRow.ItemVariant = Data.ItemVariant;
	#EndRegion
		
		NewRow.AssigneeBusinessUnit = String.StageSubdivision;
		
		If String.ProductQuantity > 0
			And Data.ProductionIssueByCustomPortions
			And Not Data.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList
			And Not Data.ContainsAliquotStandardsOfWorkCenterTypes Then
			NewRow.QuantityPerProductsUnit = String.EmploymentPerUnitOfIssueBatch / String.ProductQuantity;
		Else
			NewRow.QuantityPerProductsUnit = 0;
		EndIf;
		
		CalculateResource(NewRow, String, Data, "Occupation", "Occupation");
		
		AddLineToPeriodCalculation(
			TimeIntervals,
			Data.ProductionDate,
			String.DaysFromDemand,
			NewRow);
		
	EndDo;
	
EndProcedure
#EndRegion

#Region QueriesTexts

Function RequestTextForProductionPlanCalculationOperation()
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.Purpose AS Purpose,
	|	ISNULL(Table.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
	|
	|INTO LinesOfBusiness
	|FROM
	|	Document.ProductionPlan.ManufacturedProduct AS Table
	|WHERE
	|	Table.Ref = &ProductionPlan
	|	AND (Table.Count <> 0
	|			OR Table.DemandRangeIsSpecified)
	|	AND NOT Table.Canceled
	|	AND Table.Ref.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (NOT Table.Substituted
	|				AND NOT &Upholded
	|			OR NOT Table.SubstitutedToOrder
	|				AND &Upholded)
	|	AND Table.Ref.Posted
	|
	|INDEX BY
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	
	|	Turnovers.Period AS Period,
	|	
	|	Turnovers.Products.ProductKind AS ProductKind,
	|	Turnovers.Products AS Products,
	|	Turnovers.Characteristic AS Characteristic,
	|	
	|	Turnovers.BillOfMaterials AS BillOfMaterials,
	|	Turnovers.Purpose AS Purpose,
	|
	|	&ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
	|	LinesOfBusiness.LineOfBusiness AS LineOfBusiness,
	|	
	|	Turnovers.ToPlan AS ToPlan,
	|	Turnovers.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	RECORDAUTONUMBER() AS TheIndexOfTheData,
	|	CASE
	|		WHEN Turnovers.ThisIsASemiFinishedProduct
	|			THEN Turnovers.Period
	|		ELSE DATETIME(1,1,1)
	|	END AS ProductionIssueDateOfIntermediateProducts,
	|	MAX(Turnovers.DateOfOrderReleaseAndProductionIssue) AS DateOfOrderReleaseAndProductionIssue,
	|	
	|	&BeginOfPeriod AS ProductionStart,
	|	
	|	SUM(Turnovers.Required2) AS Count,
	|	SUM(Turnovers.ToOrder)   AS ToOrder,
	|
	|	MAX(Turnovers.SetIntervalPerDocument) AS DemandRangeIsSpecified,
	|	MAX(Turnovers.NeedIntervalFromDocument)    AS RangeOfDemandFrom,
	|	MAX(Turnovers.NeedIntervalToDocument)    AS RangeOfDemandTo
	|	
	|INTO Delta
	|FROM
	|	(SELECT
	|	
	|		CASE
	|			WHEN Table.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|					AND Table.StartDate2 <> DATETIME(1, 1, 1)
	|				THEN Table.StartDate2
	|			WHEN Table.Ref.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly),
	|																	VALUE(Enum.ProductionProcessTypes.PerformRM),
	|																	VALUE(Enum.ProductionProcessTypes.Repair))
	|					AND Table.DateOfProduction <> DATETIME(1, 1, 1)
	|				THEN Table.DateOfProduction
	|			ELSE Table.Ref.BeginOfPeriod
	|		END AS Period,
	|	
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|	
	|		Table.BillOfMaterials AS BillOfMaterials,
	|		CASE
	|			WHEN Table.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				THEN VALUE(Catalog.Assignments.EmptyRef)
	|			ELSE Table.Purpose
	|		END AS Purpose,
	|	
	|		FALSE AS ToPlan,
	|		Table.SemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|		CASE
	|			WHEN Table.Ref.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly),
		|																VALUE(Enum.ProductionProcessTypes.PerformRM),
	|																	VALUE(Enum.ProductionProcessTypes.Repair))
	|					AND Table.StartDate2 <> DATETIME(1, 1, 1)
	|				THEN Table.StartDate2
	|			ELSE DATETIME(1,1,1)
	|		END AS DateOfOrderReleaseAndProductionIssue,
	|	
	|		CASE
	|			WHEN Table.Substituted
	|				THEN 0
	|			ELSE Table.Count
	|		END AS Required2,
	|		CASE
	|			WHEN &Upholded
	|				THEN Table.Count
	|			ELSE 0
	|		END AS ToOrder,
	|	
	|		0 AS InitialDemand,
	|		0 AS InitialDemandForOrder,
	|	
	|		0 AS Scheduled,
	|		0 AS ReadyToOrder,
	|	
	|		Table.RangeOfDemandFrom AS NeedIntervalFromDocument,
	|		Table.RangeOfDemandTo AS NeedIntervalToDocument,
	|		Table.DemandRangeIsSpecified AS SetIntervalPerDocument,
	|		0 AS DemandIntervalFromTraffic,
	|		0 AS NeedIntervalBeforeMovement,
	|		FALSE AS IntervalOfTrafficDemandIsSet
	|	FROM
	|		Document.ProductionPlan.ManufacturedProduct AS Table
	|	WHERE
	|		Table.Ref = &ProductionPlan
	|		AND (Table.Count <> 0
	|			OR Table.DemandRangeIsSpecified)
	|		AND NOT Table.Canceled
	|		AND Table.Ref.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|		AND (NOT Table.Substituted
	|				AND NOT &Upholded
	|			OR NOT Table.SubstitutedToOrder
	|				AND &Upholded)
	|		AND Table.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period,
	|		Table.Products,
	|		Table.Characteristic,
	|		VALUE(Catalog.BillsOfMaterials.EmptyRef),
	|		Table.Purpose,
	|		Table.ThisIsASemiFinishedProduct,
	|		Table.ThisIsASemiFinishedProduct,
	|		DATETIME(1,1,1),
	|		Table.Count,
	|		Table.ToOrder,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		FALSE,
	|		0,
	|		0,
	|		FALSE
	|	FROM
	|		AccumulationRegister.MaterialConsumptionPlans AS Table
	|	WHERE
	|		Table.ProductionPlan = &ProductionPlan
	|		AND Table.CalculationSeparator = &CalculationSeparator
	|		AND Table.ThisIsASemiFinishedProduct
	|		AND &CalculateProductionPlanOfSemiFinishedProducts
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN Table.ThisIsASemiFinishedProduct
	|				THEN Table.ProductionIssueDateOfIntermediateProducts
	|			ELSE Table.Period
	|		END,
	|		Table.Products,
	|		Table.Characteristic,
	|		CASE
	|			WHEN Table.ToPlan
	|				THEN VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|			ELSE Table.BillOfMaterials
	|		END,
	|		Table.Purpose,
	|		Table.ToPlan,
	|		Table.ThisIsASemiFinishedProduct,
	|		CASE
	|			WHEN Table.ThisIsASemiFinishedProduct AND NOT Table.ToPlan
	|				THEN Table.DateOfOrderReleaseAndProductionIssue
	|			ELSE DATETIME(1,1,1)
	|		END,
	|		0,
	|		0,
	|		CASE
	|			WHEN Table.ManualAdjustment
	|				THEN Table.InitialDemand
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN Table.ManualAdjustment
	|				THEN Table.InitialDemandForOrder
	|			ELSE 0
	|		END,
	|		Table.Count,
	|		Table.ToOrder,
	|		0,
	|		0,
	|		FALSE,
	|		Table.RangeOfDemandFrom,
	|		Table.RangeOfDemandTo,
	|		CASE
	|			WHEN Table.DemandRangeIsSpecified <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END 
	|	FROM
	|		AccumulationRegister.ProductionPlans AS Table
	|	WHERE
	|		Table.ProductionPlan = &ProductionPlan
	|		AND Table.CalculationSeparator = &CalculationSeparator) AS Turnovers
	|
	|	LEFT JOIN LinesOfBusiness AS LinesOfBusiness
	|	ON Turnovers.Purpose = LinesOfBusiness.Purpose
	|
	|GROUP BY
	|	Turnovers.Period,
	|	Turnovers.BillOfMaterials,
	|	Turnovers.Purpose,
	|	LinesOfBusiness.LineOfBusiness,
	|	Turnovers.ToPlan,
	|	Turnovers.ThisIsASemiFinishedProduct,
	|	Turnovers.Products,
	|	Turnovers.Characteristic
	|
	|HAVING
	|	(SUM(Turnovers.Required2) <> SUM(Turnovers.Scheduled)
	|			AND (SUM(Turnovers.Required2) <> MAX(Turnovers.InitialDemand) OR MAX(Turnovers.InitialDemand) = 0)
	|		OR NOT Turnovers.ToPlan
	|			AND  ( MAX(Turnovers.SetIntervalPerDocument) <> MAX(Turnovers.IntervalOfTrafficDemandIsSet)
	|				OR MAX(Turnovers.NeedIntervalToDocument) <> MAX(Turnovers.NeedIntervalBeforeMovement)
	|				OR MAX(Turnovers.NeedIntervalFromDocument) <> MAX(Turnovers.DemandIntervalFromTraffic))
	|		OR (SUM(Turnovers.ToOrder) <> SUM(Turnovers.ReadyToOrder))
	|				AND (SUM(Turnovers.ToOrder) <> MAX(Turnovers.InitialDemandForOrder) OR MAX(Turnovers.InitialDemandForOrder) = 0))
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	RegisterRecords.Products AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
	|	RegisterRecords.Purpose AS Purpose,
	|	RegisterRecords.ToPlan AS ToPlan,
	|	RegisterRecords.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	
	|	RegisterRecords.AdjustmentDate   AS AdjustmentDate,
	|	RegisterRecords.AdjustmentAuthor  AS AdjustmentAuthor,
	|	RegisterRecords.Comment         AS Comment,
	|	
	|	CASE
	|		WHEN RegisterRecords.InitialDemand <> 0
	|				AND RegisterRecords.InitialDemand = Delta.Count
	|			THEN RegisterRecords.Count
	|		ELSE 0
	|	END AS Count,
	|	CASE
	|		WHEN RegisterRecords.InitialDemand <> 0
	|				AND RegisterRecords.InitialDemand = Delta.Count
	|			THEN RegisterRecords.InitialDemand
	|		ELSE 0
	|	END AS InitialDemand,
	|	CASE
	|		WHEN RegisterRecords.InitialDemand <> 0
	|				AND RegisterRecords.InitialDemand = Delta.Count
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SaveAdjustmentQuantity,
	|	
	|	CASE
	|		WHEN RegisterRecords.InitialDemandForOrder <> 0
	|				AND RegisterRecords.InitialDemandForOrder = Delta.ToOrder
	|			THEN RegisterRecords.ToOrder
	|		WHEN RegisterRecords.InitialDemandForOrder = 0 
	|				AND &Upholded AND RegisterRecords.InitialDemand <> 0 AND RegisterRecords.InitialDemand = Delta.Count
	|			THEN RegisterRecords.Count
	|		ELSE 0
	|	END AS ToOrder,
	|	CASE
	|		WHEN RegisterRecords.InitialDemandForOrder <> 0
	|				AND RegisterRecords.InitialDemandForOrder = Delta.ToOrder
	|			THEN RegisterRecords.InitialDemandForOrder
	|		WHEN RegisterRecords.InitialDemandForOrder = 0 
	|				AND &Upholded AND RegisterRecords.InitialDemand <> 0 AND RegisterRecords.InitialDemand = Delta.Count
	|			THEN RegisterRecords.InitialDemand
	|		ELSE 0
	|	END AS InitialDemandForOrder,
	|	CASE
	|		WHEN RegisterRecords.InitialDemandForOrder <> 0
	|				AND RegisterRecords.InitialDemandForOrder = Delta.ToOrder
	|			THEN TRUE
	|		WHEN RegisterRecords.InitialDemandForOrder = 0 
	|				AND &Upholded AND RegisterRecords.InitialDemand <> 0 AND RegisterRecords.InitialDemand = Delta.Count
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SaveAdjustmentToOrder
	|	
	|INTO ManualAdjustments
	|FROM
	|	Delta AS Delta
	|		INNER JOIN AccumulationRegister.ProductionPlans AS RegisterRecords
	|		ON &ProductionPlan   = RegisterRecords.ProductionPlan
	|		 AND &CalculationSeparator = RegisterRecords.CalculationSeparator
	|			AND Delta.ProductionIssueDateOfIntermediateProducts = RegisterRecords.ProductionIssueDateOfIntermediateProducts
	|			AND Delta.Products             = RegisterRecords.Products
	|			AND Delta.Characteristic           = RegisterRecords.Characteristic
	|			AND Delta.Purpose               = RegisterRecords.Purpose
	|			AND Delta.ToPlan            = RegisterRecords.ToPlan
	|WHERE
	|	NOT &ThisIsNewCalculation
	|	AND RegisterRecords.ManualAdjustment
	|	AND (RegisterRecords.InitialDemand <> 0 AND RegisterRecords.InitialDemand = Delta.Count
	|		OR RegisterRecords.InitialDemandForOrder <> 0 AND RegisterRecords.InitialDemandForOrder = Delta.ToOrder AND &Upholded)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Delta.Period AS Period,
	|	
	|	Delta.Products AS Products,
	|	Delta.Characteristic AS Characteristic,
	|	
	|	CASE
	|		WHEN Delta.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef) AND Delta.ToPlan
	|			THEN ISNULL(SpecificationsOfProducts.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef))
	|		ELSE Delta.BillOfMaterials
	|	END AS BillOfMaterials,
	|	Delta.Purpose AS Purpose,
	|	Delta.LineOfBusiness AS LineOfBusiness,
	|	
	|	Delta.ToPlan AS ToPlan,
	|	Delta.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Delta.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	Delta.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
	|
	|	NOT ManualAdjustments.ToPlan IS NULL                  AS ManualAdjustment,
	|	ISNULL(ManualAdjustments.AdjustmentDate,   DATETIME(1,1,1)) AS AdjustmentDate,
	|	ISNULL(ManualAdjustments.AdjustmentAuthor,  UNDEFINED)     AS AdjustmentAuthor,
	|	ISNULL(ManualAdjustments.Comment,         """")             AS Comment,
	|
	|	ISNULL(ManualAdjustments.InitialDemand, 0)  AS InitialDemand,
	|	ISNULL(ManualAdjustments.InitialDemandForOrder, 0) AS InitialDemandForOrder,
	|
	|	CASE
	|		WHEN ISNULL(ManualAdjustments.SaveAdjustmentQuantity, FALSE)
	|			THEN ManualAdjustments.Count
	|		ELSE Delta.Count
	|	END AS Count,
	|	CASE
	|		WHEN ISNULL(ManualAdjustments.SaveAdjustmentToOrder, FALSE)
	|			THEN ManualAdjustments.ToOrder
	|		ELSE Delta.ToOrder
	|	END AS ToOrder,
	|
	|	Delta.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	Delta.RangeOfDemandFrom    AS RangeOfDemandFrom,
	|	Delta.RangeOfDemandTo    AS RangeOfDemandTo
	|	
	|INTO ModifiedProducts
	|FROM
	|	Delta AS Delta
	|
	|		LEFT JOIN SpecificationsOfProducts AS SpecificationsOfProducts
	|		ON Delta.TheIndexOfTheData = SpecificationsOfProducts.TheIndexOfTheData
	|
	|		LEFT JOIN ManualAdjustments AS ManualAdjustments
	|		ON    Delta.Products             = ManualAdjustments.Products
	|			AND Delta.Characteristic           = ManualAdjustments.Characteristic
	|			AND Delta.Purpose               = ManualAdjustments.Purpose
	|			AND Delta.ProductionIssueDateOfIntermediateProducts = ManualAdjustments.ProductionIssueDateOfIntermediateProducts
	|
	|		LEFT JOIN InformationRegister.ProductionPlanAdjustmentContents AS ProductionPlanAdjustmentContents
	|		ON &ProductionPlan                  = ProductionPlanAdjustmentContents.ProductionPlan
	|			AND Delta.Products             = ProductionPlanAdjustmentContents.Products
	|			AND Delta.Characteristic           = ProductionPlanAdjustmentContents.Characteristic
	|			AND Delta.Purpose               = ProductionPlanAdjustmentContents.Purpose
	|			AND Delta.ProductionIssueDateOfIntermediateProducts = ProductionPlanAdjustmentContents.ProductionIssueDateOfIntermediateProducts
	|WHERE
	|	(&ThisIsNewCalculation OR NOT &ThisIsNewCalculation AND ProductionPlanAdjustmentContents.ProductionPlan IS NULL)
	|	
	|UNION ALL
	|	
	|SELECT
	|	
	|	Table.DateOfProduction AS Period,
	|	
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	
	|	Table.BillOfMaterials AS BillOfMaterials,
	|	Table.Purpose AS Purpose,
	|	LinesOfBusiness.LineOfBusiness AS LineOfBusiness,
	|	
	|	TRUE AS ToPlan,
	|	TRUE AS ThisIsASemiFinishedProduct,
	|	Table.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	Table.StartDate2 AS DateOfOrderReleaseAndProductionIssue,
	|	
	|	TRUE                      AS ManualAdjustment,
	|	Table.AdjustmentDate   AS AdjustmentDate,
	|	Table.AdjustmentAuthor  AS AdjustmentAuthor,
	|	Table.Comment         AS Comment,
	|	
	|	Table.InitialDemand        AS InitialDemand,
	|	Table.InitialDemandForOrder AS InitialDemandForOrder,
	|	
	|	Table.Count AS Count,
	|	Table.ToOrder AS ToOrder,
	|	
	|	Table.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	Table.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	Table.RangeOfDemandTo AS RangeOfDemandTo
	|	
	|FROM
	|	InformationRegister.ProductionPlanAdjustmentContents AS Table
	|
	|		LEFT JOIN LinesOfBusiness AS LinesOfBusiness
	|		ON Table.Purpose = LinesOfBusiness.Purpose
	|
	|WHERE
	|	NOT &ThisIsNewCalculation
	|	AND Table.ProductionPlan = &ProductionPlan
	|	
	|INDEX BY
	|	BillOfMaterials,
	|	Period,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
	|	RegisterRecords.Period       AS Period,
	|	RegisterRecords.Purpose   AS Purpose,
	|	
	|	MAX(RegisterRecords.Recorder) AS Recorder
	|	
	|INTO PlannedSpecifications
	|FROM
	|	AccumulationRegister.ProductionPlans AS RegisterRecords
	|WHERE
	|	(RegisterRecords.BillOfMaterials, RegisterRecords.Period, RegisterRecords.Purpose) IN
	|			(SELECT
	|				Table.BillOfMaterials,
	|				Table.Period,
	|				Table.Purpose
	|			FROM
	|				ModifiedProducts AS Table)
	|	AND RegisterRecords.ProductionPlan = &ProductionPlan
	|	AND RegisterRecords.CalculationSeparator = &CalculationSeparator
	|
	|GROUP BY
	|	RegisterRecords.BillOfMaterials,
	|	RegisterRecords.Period,
	|	RegisterRecords.Purpose
	|
	|INDEX BY
	|	BillOfMaterials,
	|	Period,
	|	Purpose,
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.Products AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
	|	RegisterRecords.Purpose AS Purpose,
	|	RegisterRecords.ToPlan AS ToPlan,
	|	RegisterRecords.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	Changes.LineOfBusiness AS LineOfBusiness
	|	
	|INTO CancellableProducts
	|FROM
	|	AccumulationRegister.ProductionPlans AS RegisterRecords
	|		INNER JOIN ModifiedProducts AS Changes
	|			ON Changes.ProductionIssueDateOfIntermediateProducts = RegisterRecords.ProductionIssueDateOfIntermediateProducts
	|			 AND Changes.Products             = RegisterRecords.Products
	|			 AND Changes.Characteristic           = RegisterRecords.Characteristic
	|			 AND Changes.Purpose               = RegisterRecords.Purpose
	|			 AND Changes.ToPlan            = RegisterRecords.ToPlan
	|WHERE
	|	RegisterRecords.ProductionPlan = &ProductionPlan
	|	AND RegisterRecords.CalculationSeparator = &CalculationSeparator
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				PlannedSpecifications AS Table
	|			WHERE
	|				Table.Period = RegisterRecords.Period
	|				AND Table.Recorder = RegisterRecords.Recorder
	|				AND Table.BillOfMaterials = Changes.BillOfMaterials
	|				AND Table.Purpose = Changes.Purpose)
	|	AND RegisterRecords.ToPlan
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Documents.Ref AS Ref
	|INTO MaximumRecordingPortionExceeded
	|FROM
	|	Document.RegisterProductionPlan AS Documents
	|WHERE
	|	Documents.ProductionPlan = &ProductionPlan
	|	AND Documents.CalculationSeparator = &CalculationSeparator
	|	AND Documents.Posted
	|	AND Documents.MaximumRecordingPortionExceeded
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|
	|	&ProductionPlan AS ReferenceOrder,
	|	&ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
	|
	|	ModifiedProducts.Products AS Products,
	|	ModifiedProducts.Characteristic AS Characteristic,
	|	ModifiedProducts.BillOfMaterials AS BillOfMaterials,
	|	ModifiedProducts.Purpose AS Purpose,
	|	ModifiedProducts.LineOfBusiness AS LineOfBusiness,
	|
	|	VALUE(Enum.WayOfLinkingProductionOperations.ToFinish) AS ProductionScheduling,
	|	CASE
	|		WHEN &ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|		THEN ModifiedProducts.DateOfOrderReleaseAndProductionIssue
	|		ELSE ModifiedProducts.Period
	|	END AS StartDate2,
	|	CASE
	|		WHEN &ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|		THEN ModifiedProducts.Period
	|		ELSE ModifiedProducts.DateOfOrderReleaseAndProductionIssue
	|	END AS DateOfProduction,
	|
	|	ModifiedProducts.Period         AS ProductionDate,
	|	ModifiedProducts.BillOfMaterials   AS ProductBOM,
	|	ModifiedProducts.Purpose     AS AssignmentOfProducts,
	|	ModifiedProducts.Products   AS ProductsItems,
	|	ModifiedProducts.Characteristic AS ItemVariant,
	|
	|	ModifiedProducts.ToPlan AS ToPlan,
	|	ModifiedProducts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	ModifiedProducts.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	ModifiedProducts.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
	|
	|	ModifiedProducts.ManualAdjustment  AS ManualAdjustment,
	|	ModifiedProducts.AdjustmentDate    AS AdjustmentDate,
	|	ModifiedProducts.AdjustmentAuthor   AS AdjustmentAuthor,
	|	ModifiedProducts.Comment          AS Comment,
	|
	|	ModifiedProducts.InitialDemand        AS InitialDemand,
	|	ModifiedProducts.InitialDemandForOrder AS InitialDemandForOrder,
	|
	|	CASE
	|		WHEN &Upholded
	|			THEN CASE
	|					WHEN ModifiedProducts.ToOrder > 0
	|						THEN VALUE(AccumulationRecordType.Receipt)
	|					ELSE VALUE(AccumulationRecordType.Expense)
	|				END
	|		ELSE CASE
	|				WHEN ModifiedProducts.Count > 0
	|					THEN VALUE(AccumulationRecordType.Receipt)
	|				ELSE VALUE(AccumulationRecordType.Expense)
	|			END
	|	END AS RecordType,
	|	CASE
	|		WHEN &Upholded
	|			THEN CASE
	|					WHEN ModifiedProducts.ToOrder > 0
	|						THEN ModifiedProducts.ToOrder
	|					ELSE -ModifiedProducts.ToOrder
	|				END
	|		ELSE CASE
	|				WHEN ModifiedProducts.Count > 0
	|					THEN ModifiedProducts.Count
	|				ELSE -ModifiedProducts.Count
	|			END
	|	END AS QuantityToBeCalculated,
	|
	|	ModifiedProducts.Count AS Count,
	|	ModifiedProducts.ToOrder    AS ToOrder,
	|
	|	ModifiedProducts.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	ModifiedProducts.RangeOfDemandFrom    AS RangeOfDemandFrom,
	|	ModifiedProducts.RangeOfDemandTo    AS RangeOfDemandTo
	|	
	|INTO Calculation
	|FROM
	|	ModifiedProducts AS ModifiedProducts
	|		LEFT JOIN PlannedSpecifications AS PlannedSpecifications
	|			ON ModifiedProducts.BillOfMaterials = PlannedSpecifications.BillOfMaterials
	|			 AND ModifiedProducts.Period       = PlannedSpecifications.Period
	|			 AND ModifiedProducts.Purpose   = PlannedSpecifications.Purpose
	|WHERE
	|	PlannedSpecifications.BillOfMaterials IS NULL
	|	AND (ModifiedProducts.Count <> 0 OR ModifiedProducts.ToOrder <> 0 OR ModifiedProducts.DemandRangeIsSpecified)
	|" + "
	|ORDER BY
	|	BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + "
	|SELECT
	|	
	|	&ProductionPlan AS ProductionPlan,
	|	
	|	PlannedSpecifications.Period AS Period,
	|	CASE WHEN
	|			TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM 
	|					MaximumRecordingPortionExceeded AS MaximumRecordingPortionExceeded
	|				WHERE 
	|					MaximumRecordingPortionExceeded.Ref = PlannedSpecifications.Recorder)
	|			THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|			END
	|	AS MaximumRecordingPortionExceeded,
	|	PlannedSpecifications.Recorder AS Recorder,
	|	
	|	ModifiedProducts.Products AS Products,
	|	ModifiedProducts.Characteristic AS Characteristic,
	|	ModifiedProducts.BillOfMaterials AS BillOfMaterials,
	|	ModifiedProducts.Purpose AS Purpose,
	|	ModifiedProducts.LineOfBusiness AS LineOfBusiness,
	|	
	|	ModifiedProducts.ToPlan AS ToPlan,
	|	ModifiedProducts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	ModifiedProducts.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	ModifiedProducts.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
	|	
	|	ModifiedProducts.ManualAdjustment  AS ManualAdjustment,
	|	ModifiedProducts.AdjustmentDate    AS AdjustmentDate,
	|	ModifiedProducts.AdjustmentAuthor   AS AdjustmentAuthor,
	|	ModifiedProducts.Comment          AS Comment,
	|	
	|	ModifiedProducts.InitialDemand        AS InitialDemand,
	|	ModifiedProducts.InitialDemandForOrder AS InitialDemandForOrder,
	|	
	|	ModifiedProducts.Count AS Count,
	|	ModifiedProducts.ToOrder    AS ToOrder,
	|
	|	ModifiedProducts.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	ModifiedProducts.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	ModifiedProducts.RangeOfDemandTo AS RangeOfDemandTo
	|	
	|INTO Adjusting
	|FROM
	|	PlannedSpecifications AS PlannedSpecifications
	|		INNER JOIN ModifiedProducts AS ModifiedProducts
	|		ON PlannedSpecifications.BillOfMaterials  = ModifiedProducts.BillOfMaterials
	|			AND PlannedSpecifications.Period     = ModifiedProducts.Period
	|			AND PlannedSpecifications.Purpose = ModifiedProducts.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	
	|	&ProductionPlan,
	|	RegisterRecords.Period,
	|	CASE WHEN
	|			TRUE IN (
	|				SELECT TOP 1
	|					TRUE 
	|				FROM 
	|					MaximumRecordingPortionExceeded AS MaximumRecordingPortionExceeded
	|				WHERE 
	|					MaximumRecordingPortionExceeded.Ref = RegisterRecords.Recorder)
	|			THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|			END
	|	AS MaximumRecordingPortionExceeded,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.Products,
	|	RegisterRecords.Characteristic,
	|	RegisterRecords.BillOfMaterials,
	|	RegisterRecords.Purpose,
	|	RegisterRecords.LineOfBusiness,
	|	RegisterRecords.ToPlan,
	|	RegisterRecords.ToPlan,
	|	RegisterRecords.ProductionIssueDateOfIntermediateProducts,
	|	DATETIME(1,1,1),
	|	FALSE,
	|	DATETIME(1,1,1),
	|	UNDEFINED,
	|	"""",
	|	0,
	|	0,
	|	0,
	|	0,
	|
	|	FALSE AS DemandRangeIsSpecified,
	|	0 AS RangeOfDemandFrom,
	|	0 AS RangeOfDemandTo
	|FROM
	|	CancellableProducts AS RegisterRecords
	|" + "
	|ORDER BY
	|	MaximumRecordingPortionExceeded,Recorder
	|TOTALS
	|	MAX(MaximumRecordingPortionExceeded)
	|BY
	|	Recorder
	|";
	
	QueryText = StrReplace(QueryText, "INTO Calculation", "// INTO Calculation");
	QueryText = StrReplace(QueryText, "INTO Adjusting", "// INTO Adjusting");
	
	Return QueryText;
	
EndFunction

Function RequestTextOperationVerificationChangingBankingDetails()
	
	QueryText =
	"SELECT
	|	Table.Ref AS Recorder,
	|	Table.MaximumRecordingPortionExceeded
	|FROM
	|	Document.RegisterProductionPlan AS Table
	|WHERE
	|	Table.Posted
	|	AND Table.ProductionPlan = &ProductionPlan
	|	AND Table.CalculationSeparator = &CalculationSeparator
	|	AND ( NOT Table.Status = &Status )
	|ORDER BY
	|	MaximumRecordingPortionExceeded,Recorder
	|TOTALS
	|	MAX(MaximumRecordingPortionExceeded)
	|BY
	|	Recorder";
	Return QueryText;
	
EndFunction

Function RequestTextOperationCancelProductionPlanCalculation()
	
	QueryText =
	"SELECT
	|	Table.Ref AS Recorder,
	|	Table.MaximumRecordingPortionExceeded
	|FROM
	|	Document.RegisterProductionPlan AS Table
	|WHERE
	|	Table.Posted
	|	AND Table.ProductionPlan = &ProductionPlan
	|	AND Table.CalculationSeparator < &CalculationSeparator
	|ORDER BY
	|	MaximumRecordingPortionExceeded,Recorder";

	Return QueryText;
	
EndFunction

#EndRegion

#Region CommonSettings

Function CommonSettings(CheckOperatingMode = False) Export
	
	CommonSettings = StandardSettingsForCalculatingProductionPlan();
	
	SetPrivilegedMode(True);
	Storage = Constants.CalculationParametersOfProductionPlan.Get();
	SetPrivilegedMode(False);
	
	Try
		
		FillPropertyValues(CommonSettings, Storage.Get(), ParametersContent());
		
	Except
		
		MessageText = NStr("vi = 'Không thể lấy các tham số để tính toán kế hoạch sản xuất, các giá trị sẽ được trả về cài đặt mặc định';
							|ru = 'Не удалось получить параметры расчета плана производства, значения будут приведены к настройкам по умолчанию';
							|en = 'Parameters of production plan calculation could not be retrieved, values will be reduced to default settings'; fa = 'Parameters of production plan calculation could not be retrieved, values will be reduced to default settings';
							|it = 'Non è stato possibile ottenere i parametri del calcolo del piano di produzione, i valori saranno ripristinati';
							|pl = 'Nie udało się uzyskać parametry obliczeń planu produkcji, wartości zostaną przywrócone do ustawień domyślnych';
							|tr = 'Üretim planının hesaplanması için parametreler alınamadı, değerler ayarlara göre sıfırlanacak'");
		
		WriteLogEvent(
			EventLogEvent(),
			EventLogLevel.Error,
			Metadata.Constants.CalculationParametersOfProductionPlan,
			,
			MessageText);
		
	EndTry;
	
	If CheckOperatingMode And Common.FileInfobase() Then
		
		CommonSettings.VectorizeCalculation = False;
		CommonSettings.ThreadsCount      = 1;
		
	EndIf;
	
	Return New FixedStructure(CommonSettings);
	
EndFunction

Function ParametersContent()
	
	ParametersContent = "
		|VectorizeCalculation,
		|ThreadsCount,
		|
		|ReadingPortionFrom,
		|ReadingPortionBefore,
		|
		|RecordPortion,
		|NumberOfRowsInTheRecordset,
		|
		|MaxAccountingDepth,
		|SearchCyclesAfter,
		|
		|AllowRepeatedUseOfCalculatedData
		|
		|";
	Return ParametersContent;
	
EndFunction

Function StandardSettingsForCalculatingProductionPlan() Export
	
	CalculationParameters = New Structure;
	
	CalculationParameters.Insert("VectorizeCalculation", False);
	CalculationParameters.Insert("ThreadsCount", 8);
	
	CalculationParameters.Insert("ReadingPortionFrom", 25); // minimum reading portion (in products)
	CalculationParameters.Insert("ReadingPortionBefore", 1000); // maximum reading portion (in products)
	
	CalculationParameters.Insert("RecordPortion", 250); // maximum recording portion (in products)
	CalculationParameters.Insert("NumberOfRowsInTheRecordset", 2500); // the maximum number of rows that can be placed in a set of register entries (in rows)
	
	CalculationParameters.Insert("MaxAccountingDepth", 125);
	CalculationParameters.Insert("SearchCyclesAfter", 25); // after how many iterations of the calculation to search for cycles in the data
	
	CalculationParameters.Insert("AllowRepeatedUseOfCalculatedData", True);
	
	Return CalculationParameters;
	
EndFunction

Procedure RecordProductionPlanCalculationSettings(ParameterValues) Export
	
	CommonSettings = New Structure(ParametersContent());
	
	FillPropertyValues(CommonSettings, CommonSettings());
	FillPropertyValues(CommonSettings, ParameterValues);
	
	Constants.CalculationParametersOfProductionPlan.Set(New ValueStorage(CommonSettings));
	
EndProcedure

Procedure SetStandardSettingsForCalculatingProductionPlan(Initialize) Export
	
	If Initialize Then
		SetPrivilegedMode(True);
		Storage = Constants.CalculationParametersOfProductionPlan.Get();
		SetPrivilegedMode(False);
		
		If Not ValueIsFilled(Storage.Get()) Then
			
			CommonSettings = New Structure(ParametersContent());
			
			FillPropertyValues(CommonSettings, StandardSettingsForCalculatingProductionPlan());
			
			Constants.CalculationParametersOfProductionPlan.Set(New ValueStorage(CommonSettings));
			
		EndIf;
	Else
		ParameterValues = StandardSettingsForCalculatingProductionPlan();
		RecordProductionPlanCalculationSettings(ParameterValues);
	EndIf;
	
EndProcedure

Function MaximumNumberOfLinesInTheRecordSet()
	
	Return 100000;
	
EndFunction

#EndRegion

#Region Constants

Function NewCalculationMode() Export
	
	Return "NEWSETTLEMENT";
	
EndFunction

Function RecalculationMode() Export
	
	Return "RECALCULATE";
	
EndFunction

#EndRegion

#Region DataValidation

Procedure CheckDataBeforeCalculation(Data, CalculationParameters)
	
	If CalculationParameters.SearchCyclesAfter < CalculationParameters["CalculationProtocol"].LevelCount Then
		
		SpecificationRelationships = CalculationParameters["CalculationProtocol"].SpecificationRelationships;
		
		Cancel = False;
		CycleDescription = "";
		
		Query = New Query(
		"SELECT
		|	Table.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.BillOfMaterials AS BillOfMaterials,
		|	Table.Purpose AS Purpose,
		|	Table.ProductionPlan AS ProductionPlan
		|INTO ModifiedRows
		|FROM
		|	&ModifiedRows AS Table
		|WHERE
		|	Table.ToPlan
		|
		|INDEX BY
		|	ProductionIssueDateOfIntermediateProducts,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	ProductionPlan
		|;
		|SELECT DISTINCT
		|	ModifiedRows.BillOfMaterials AS BillOfMaterials,
		|	MaterialConsumptionPlans.ProductBOM AS ParentSpecification
		|FROM
		|	ModifiedRows AS ModifiedRows
		|		INNER JOIN AccumulationRegister.MaterialConsumptionPlans AS MaterialConsumptionPlans
		|		ON ModifiedRows.ProductionIssueDateOfIntermediateProducts = MaterialConsumptionPlans.Period
		|			AND ModifiedRows.Products          = MaterialConsumptionPlans.Products
		|			AND ModifiedRows.Characteristic        = MaterialConsumptionPlans.Characteristic
		|			AND ModifiedRows.Purpose            = MaterialConsumptionPlans.Purpose
		|			AND ModifiedRows.ProductionPlan      = MaterialConsumptionPlans.ProductionPlan
		|");
		Query.SetParameter("ModifiedRows", Data);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			FindCyclesInLinks(
				SpecificationRelationships, Selection.BillOfMaterials, Selection.ParentSpecification, CycleDescription, Cancel);
			
			If Cancel Then
				
				TemplateText = NStr("vi = 'Trong quá trình tính toán kế hoạch sản xuất, các bảng kê chi tiết các nguồn lực sản xuất đã được lặp lại: %1. Thực hiện bị hủy bỏ.';
									|ru = 'В процессе расчета плана производства произошло зацикливание спецификаций: %1. Выполнение прервано.';
									|en = 'Specifications:%1 were looped during calculation of the production plan. Performance is broken.'; fa = 'Specifications:%1 were looped during calculation of the production plan. Performance is broken.';
									|it = 'Durante il calcolo del piano di produzione si è verificato un malfunzionamento delle specifiche: %1. Esecuzione interrotta.';
									|pl = 'W procesie obliczania planu produkcji nastąpiło zapętlenie specyfikacji: %1. Wykonanie zostało przerwane.';
									|tr = 'Üretim planı hesaplama sürecinde döngüsel şu ürün reçetesinin işlemi gerçekleştirildi: %1. Gerçekleştirme işlemi kesintiye uğradı.'");
				ErrorText = StrTemplate(TemplateText, CycleDescription + "\" + BillOfMaterialsPresentation(Selection.BillOfMaterials));
				Raise ErrorText;
				
			Else
				
				Link = SpecificationRelationships.Get(Selection.BillOfMaterials);
				If Link = Undefined Then
					SpecificationRelationships.Insert(
						Selection.BillOfMaterials,
						CommonClientServer.ValueInArray(Selection.ParentSpecification));
				Else
					If Link.Find(Selection.ParentSpecification) = Undefined Then
						Link.Add(Selection.ParentSpecification);
					EndIf;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//  SpecificationRelationships - Map of KeyAndValue -
//  BillOfMaterials - CatalogRef.BillsOfMaterials -
//  ParentSpecification - CatalogRef.BillsOfMaterials -
//  CycleDescription - String -
//  Cancel - Boolean -
Procedure FindCyclesInLinks(SpecificationRelationships, BillOfMaterials, ParentSpecification, CycleDescription, Cancel)
	
	If BillOfMaterials = ParentSpecification Then
		Cancel = True;
	Else
		
		Link = SpecificationRelationships.Get(ParentSpecification);
		
		If Link = Undefined Then
			Return;
		EndIf;
		
		For Each Predecessor In Link Do
			
			If Predecessor = BillOfMaterials Then
				
				Cancel = True;
				CycleDescription = "" + BillOfMaterialsPresentation(BillOfMaterials);
			Else
				
				FindCyclesInLinks(
					SpecificationRelationships, BillOfMaterials, Predecessor, CycleDescription, Cancel);
				
			EndIf;
			
			If Cancel Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Cancel Then
		CycleDescription = CycleDescription + "\" + BillOfMaterialsPresentation(ParentSpecification);
	EndIf;
	
EndProcedure

Function BillOfMaterialsPresentation(Ref)
	
	Query = New Query(
	"SELECT
	|	BillsOfMaterials.Code AS Code,
	|	BillsOfMaterials.Description AS Description
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|WHERE
	|	BillsOfMaterials.Ref = &Ref");
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = StrTemplate(NStr("vi = '""%1 %2""';
									|ru = '""%1 %2""';
									|en = '""%1 %2""'; fa = '""%1 %2""';
									|it = '""%1 %2""';
									|pl = '""%1 %2""';
									|tr = '""%1 %2""'"), Ref.Code, Ref.Description);
	Else
		Result = "";
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Procedure FillInInitializationParameters(Query, CalculationParameters)
	
	Query.SetParameter("ThisIsNewCalculation", (CalculationParameters.SettlementMode = NewCalculationMode()));
	
	Query.SetParameter("ProductionPlan", CalculationParameters.ProductionPlan);
	Query.SetParameter("CalculationSeparator", CalculationParameters.CalculationSeparator);
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN ISNULL(ProductionPlan.PlanProfile.PlanSemiFinishedProductsAutomatically, FALSE)
	|				AND ProductionPlan.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CalculateProductionPlanOfSemiFinishedProducts,
	|
	|	ProductionPlan.BeginOfPeriod AS BeginOfPeriod,
	|	ProductionPlan.ProductionProcessType AS ProductionProcessType,
	|
	|	CASE
	|		WHEN ProductionPlan.Status = VALUE(Enum.PlanStatuses.Upholded)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Upholded
	|
	|FROM
	|	Document.ProductionPlan AS ProductionPlan
	|WHERE
	|	ProductionPlan.Ref = &ProductionPlan";
	
	QueryResult = Query.Execute();
	
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	Query.SetParameter("UseBudgeting", GetFunctionalOption("UseBudgeting"));
	
	For Each Column In QueryResult.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In CalculationParameters.Attributes Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure

Procedure AddSpecificationMatchingTables(Query, QueriesTexts)
	
	SpecificationRequestParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	SpecificationRequestParameters.NameOfInputTable            = "Delta";
	SpecificationRequestParameters.OutputTableName           = "SpecificationsOfProducts";
	SpecificationRequestParameters.PriorityOnly           = True;
	SpecificationRequestParameters.DestroyTemporaryTables   = False;
	SpecificationRequestParameters.FinalPackageSeparator   = False;
	SpecificationRequestParameters.ConditionsForSelectingIncomingData.Add("Delta.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)");
	
	BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	
	Query.Text = ProductDataManagement.RequestTextForProductItemsSpecifications(
		SpecificationRequestParameters,
		BOMSelectionParameters);
		
	ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(
		Query,
		BOMSelectionParameters);
		
	RequestStructure = DecomposeQueryPackageIntoStructureOfQueryTexts(Query.Text);
	For Each KeyAndValue In RequestStructure Do
		QueriesTexts.Add(KeyAndValue.Value, "");
	EndDo;
	
EndProcedure

Function DetailsOfSpecifications(Source, CalculationParameters)
	
	Result = New Map;
	
	If TypeOf(Source) = Type("ValueTable") Then
		Specifications = Source.UnloadColumn("BillOfMaterials");
	Else
		Specifications = Source;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	BillsOfMaterials.Ref AS Ref,
	|	BillsOfMaterials.ProductionProcessType AS ProductionProcessType,
	|	ISNULL(CASE
	|			WHEN &MethodOfCalculationOfMaterials = VALUE(Enum.MaterialCalculationMethods.MinimumConsumption)
	|				THEN ProductionTime.PlannedProductionDurationDays
	|			ELSE ProductionTime.MaximumProductionDurationDays
	|		END, 0) AS Duration,
	|	NOT ISNULL(ProductionTime.Cached, FALSE) AS RepeatedDecomposition
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|		LEFT JOIN InformationRegister.StandardProductionDuration AS ProductionTime
	|		ON BillsOfMaterials.Ref = ProductionTime.BillOfMaterials
	|WHERE
	|	BillsOfMaterials.Ref IN(&Specifications)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef),
	|	&ProductionProcessType,
	|	0,
	|	TRUE");
	Query.SetParameter("Specifications", Specifications);
	Query.SetParameter("ProductionProcessType", CalculationParameters.Attributes.ProductionProcessType);
	Query.SetParameter("MethodOfCalculationOfMaterials", CalculationParameters.DataSamplingParameters.MethodOfCalculationOfMaterials);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Attributes = New Structure("ProductionProcessType,Duration,RepeatedDecomposition");
		FillPropertyValues(Attributes, Selection);
		Result.Insert(Selection.Ref, Attributes);
	EndDo;
	
	Return Result;
	
EndFunction

Function CutSublist(List, LeftLimit, Length = 1)
	
	Sublist = New Array;
	RightBorder_ = Min(LeftLimit + Length - 1, List.UBound());
	
	If RightBorder_ >= LeftLimit Then
		
		For IndexOf = -RightBorder_ To -LeftLimit Do
			
			Sublist.Add(List[-IndexOf]);
			List.Delete(-IndexOf);
			
		EndDo;
		
	EndIf;
	
	Return Sublist;
	
EndFunction

Function EventLogEvent() Export
	
	Return NStr("vi = 'Tính toán kế hoạch sản xuất';
				|ru = 'Расчет плана производства';
				|en = 'Calculation of the production plan'; fa = 'محاسبه برنامه تولید';
				|it = 'Calcolo del piano di produzione';
				|pl = 'Obliczanie planu produkcji';
				|tr = 'Üretim planının hesaplanması'", CommonClientServer.DefaultLanguageCode());
	
EndFunction

Procedure SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching) Export
	
	If TypeOf(Document) = Type("DocumentRef.ProductionPlan") Then
		RegisterMatching.Insert(Metadata.AccumulationRegisters.ReleasePlansProducts_              , "ProductionPlan");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.OccupancyPlansForWorkCenterTypes, "ProductionPlan");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.PlansOfHumanResourcesOccupancy   , "ProductionPlan");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.MaterialConsumptionPlans       , "ProductionPlan");
		RegisterMatching.Insert(Metadata.AccumulationRegisters.ProductionPlans                , "ProductionPlan");
	EndIf;
	
EndProcedure

Function DecomposeQueryPackageIntoStructureOfQueryTexts(QueryText)
	
	QueryStructure = New Structure();
	
	NumberOfDataSampleRequest = 1;
	WordLength = StrLen("INTO");
	Packages = StrSplit(QueryText, ";", False);
	For Each Package In Packages Do
		
		TableName = "";
		Cursor = 1;
		Position = StrFind(Package, "INTO", SearchDirection.FromBegin, Cursor);
		If Position > 0 Then
			For Cursor = Position + WordLength + 1 To StrLen(Package) - 1 Do
				CharCode = CharCode(Package, Cursor);
				If (CharCode >= 48 And CharCode <= 57) // Digits
					Or (CharCode >= 65 And CharCode <= 90) // latin big
					Or (CharCode >= 97 And CharCode <= 122) // latin letters are small
					Or (CharCode >= 1040 And CharCode <= 1103) // CyrillicCharacters
					Or CharCode = 95 Then // the "_" symbol
					Continue;
				EndIf;
				TableName = Mid(Package, Position + WordLength + 1, Cursor - Position - (WordLength + 1));
				Break;
			EndDo;
		EndIf;
		
		If IsBlankString(TableName) Then
			TableName = Format(NumberOfDataSampleRequest, "NG=; NF=QueryN");
			NumberOfDataSampleRequest = NumberOfDataSampleRequest + 1;
		EndIf;
		
		QueryStructure.Insert(TableName, Package);
		
	EndDo;
	
	Return QueryStructure;
	
EndFunction

Function ThereAreDifferencesInColumns(String1, String2, Columns)
	
	ThereAreDifferences_ = False;
	
	For Each Column In Columns Do
		
		If String1[Column] <> String2[Column] Then
			ThereAreDifferences_ = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereAreDifferences_
	
EndFunction

#EndRegion

#EndRegion
