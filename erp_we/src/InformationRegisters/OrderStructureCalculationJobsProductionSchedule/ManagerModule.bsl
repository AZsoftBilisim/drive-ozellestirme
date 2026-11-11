#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Adds tasks to the calculation of the production order structure
// 
// Parameters:
// 	Table - ValueTable - tasks to be calculated
// 	CollapseTable - Boolean - flag, it is necessary to collapse the table before recording tasks.
// 
Procedure AddTasks(Table, CollapseTable = False) Export
	
	SetPrivilegedMode(True);
	
	If CollapseTable Then
		
		Columns = "ProductionOrder";
		If Table.Columns.Find("KeyLot") <> Undefined Then
			Columns = Columns + ", KeyLot";
		EndIf;
		If Table.Columns.Find("ProductionStage") <> Undefined Then
			Columns = Columns + ", ProductionStage";
		EndIf;
		If Table.Columns.Find("Queue") <> Undefined Then
			Columns = Columns + ", Queue";
		EndIf;
		Table.GroupBy(Columns);
		
	EndIf;
	
	OrderStructure.FillInAndRecordSetOfRecords(
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet(),
		Table,
		False,
		True);
	
EndProcedure

Procedure AddJob(ProductionOrder, ProductionStage = Undefined, KeyLot = Undefined, StartCalculation = False) Export

	SetPrivilegedMode(True);
	
	Table = New ValueTable;
	Table.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	
	NewRow = Table.Add();
	NewRow.ProductionOrder = ProductionOrder;
	
	If ProductionStage <> Undefined Then
		Table.Columns.Add("ProductionStage", New TypeDescription("DocumentRef.ProductionStage2_2"));
		NewRow.ProductionStage = ProductionStage;
	EndIf;
	
	If KeyLot <> Undefined Then
		Table.Columns.Add("KeyLot", New TypeDescription("UUID"));
		NewRow.KeyLot = KeyLot;
	EndIf;
	
	OrderStructure.FillInAndRecordSetOfRecords(
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet(),
		Table,
		False,
		True);
	
	If StartCalculation Then
		InformationRegisters.TargetOrderStructureSchedule.StartCalculation();
	EndIf;
	
EndProcedure 

Procedure AddTasksFromTemporaryTableManager(TempTablesManager, TempTableName, ProductionOrder, ProductionStage, KeyLot, FilterText1 = "") Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	QueryText =
	"SELECT DISTINCT
	|
	|	&ProductionOrder   AS ProductionOrder,
	|	&ProductionStage      AS ProductionStage,
	|	&KeyLot            AS KeyLot
	|FROM
	|	TempTableName AS TempTableName
	|WHERE
	|	&FilterText1
	|	AND &TextNoErrors
	|";
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
		TextNoErrors = "TRUE";
	Else
		TextNoErrors = 
			"TRUE NOT IN
			|	(SELECT TOP 1
			|		TRUE
			|	FROM
			|		InformationRegister.OrderStructureCalculationProtocol AS Table
			|	WHERE
			|		Table.ProductionOrder = &ProductionOrder
			|		AND Table.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError))";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextNoErrors", TextNoErrors);
	QueryText = StrReplace(QueryText, "TempTableName",  TempTableName);
	QueryText = StrReplace(QueryText, "&ProductionOrder", ProductionOrder);
	QueryText = StrReplace(QueryText, "&ProductionStage",    ProductionStage);
	QueryText = StrReplace(QueryText, "&KeyLot",          KeyLot);
	QueryText = StrReplace(QueryText, "&FilterText1", ?(IsBlankString(FilterText1), "TRUE", FilterText1));
	
	Query.Text = QueryText;

	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		OrderStructure.FillInAndRecordSetOfRecords(
			InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet(),
			QueryResult.Unload(),
			False,
			True);
		
	EndIf;
	
EndProcedure

// Returns a table of tasks for calculating the schedule for this stage of production.
//
// Parameters:
//  Ref - DocumentRef.ProductionStage2_2
//
// Returns:
//  ValueTable
//
Function TasksByStage(Ref) Export
	
	Query = New Query(
		"SELECT
		|	Jobs.ProductionOrder AS ProductionOrder,
		|	Jobs.Separator         AS Separator,
		|	Jobs.ProductionStage    AS ProductionStage,
		|	Jobs.KeyLot          AS KeyLot
		|FROM
		|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
		|WHERE
		|	Jobs.ProductionStage = &ProductionStage");
	Query.SetParameter("ProductionStage", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction

// Deletes tasks.
//
// Parameters:
//   Jobs - ValueTable - tasks to delete with the values of all measurements of the register.
//
Procedure DeleteTasks(Jobs) Export
	
	If Jobs.Count() = 0 Then
		Return;
	EndIf;
	
	Set = InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet();
	Set.Load(Jobs);
	SetPrivilegedMode(True);
	Set.Write(ReplacementMode.Delete);
	SetPrivilegedMode(False);
	
EndProcedure

// Deletes tasks.
//
// Parameters:
//   Filter - Structure - selection structure, the names of the dimensions for which the selection will be applied are passed as keys..
//
Procedure DeleteSelectionEntries(Filter) Export
	
	If Filter.Count() = 0 Then
		Return;
	EndIf;
	
	Set = InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet();
	If Filter.Property("ProductionOrder") Then
		Set.Filter.ProductionOrder.Set(Filter.ProductionOrder);
	EndIf;
	If Filter.Property("Separator") Then
		Set.Filter.Separator.Set(Filter.Separator);
	EndIf;
	If Filter.Property("ProductionStage") Then
		Set.Filter.ProductionStage.Set(Filter.ProductionStage);
	EndIf;
	If Filter.Property("KeyLot") Then
		Set.Filter.KeyLot.Set(Filter.KeyLot);
	EndIf;
	SetPrivilegedMode(True);
	Set.Write();
	SetPrivilegedMode(False);

EndProcedure

#EndRegion

#EndIf
