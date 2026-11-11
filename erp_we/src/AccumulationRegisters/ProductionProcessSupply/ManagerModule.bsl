#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region DemandFulfillment

// Returns the query text for semi-finished products produced in the process scheduled for production by the passed selection.
//
// Parameters:
//  TemporaryTableNames - Structure - structure with fields:
//   * SelectionByNeed - String - name of the temporary need selection table.
//   * Result          - String - name of the temporary table to put the result in.
// Returns:
//  String - the text of the request for semi-finished products produced in the process planned to be put into production.
//
Function RequestTextSemiFinishedProductsForProduction(TemporaryTableNames) Export
	
	NameTTSelectionByNeed       = TemporaryTableNames.SelectionByNeed;
	NameOfTemporaryResultTable = TemporaryTableNames.Result;
	
	QueryText =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	CASE
	|		WHEN Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|			THEN Table.Warehouse
	|		ELSE Table.Department
	|	END AS Warehouse,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.Stage AS Stage,
	|	
	|	(Table.Required2Turnover
	|		- Table.ScheduledTurnover
	|		- Table.TransferredToProductionTurnover
	|		- Table.ProducedTurnover
	|		- Table.ManufacturedTurnover) + Table.DisassemblyIsPlannedTurnover AS Count
	|	
	|INTO TTRevsSemiFinishedProductsToStartProductionRedefined
	|FROM
	|	AccumulationRegister.ProductionProcessSupply.Turnovers(,,,
	|	
	|			(Products,Characteristic,Warehouse,Department,Purpose) IN(
	|				SELECT
	|					Filter.Products AS Products,
	|					Filter.Characteristic AS Characteristic,
	|					CASE
	|						WHEN VALUETYPE(Filter.Warehouse) = TYPE(Catalog.Warehouses)
	|							THEN Filter.Warehouse
	|						ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|					END AS Warehouse,
	|					CASE
	|						WHEN VALUETYPE(Filter.Warehouse) = TYPE(Catalog.BusinessStructure)
	|							THEN Filter.Warehouse
	|						ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|					END AS Department,
	|					Filter.Purpose AS Purpose
	|				FROM
	|					TTSelectionAccordingToNeed AS Filter)
	|			
	|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|			
	|		) AS Table
	|WHERE
	|	(Table.Required2Turnover
	|		- Table.ScheduledTurnover
	|		- Table.TransferredToProductionTurnover
	|		- Table.ProducedTurnover
	|		- Table.ManufacturedTurnover) + Table.DisassemblyIsPlannedTurnover > 0
	|;
	|
	|//////////////////////////////////////////
	|SELECT
	|
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Warehouse AS Warehouse,
	|	SUM(Table.Count) AS Count
	|INTO TTSemiFinishedProductsToStartProductionRedefined
	|FROM
	|	TTRevsSemiFinishedProductsToStartProductionRedefined AS Table
	|WHERE
	|	CAST(&OrderFieldText AS Document.ProductionStage2_2).Status <> VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|GROUP BY
	|	Table.Products, Table.Characteristic, Table.Purpose, Table.Warehouse
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|//////////////////////////////////////////
	|DROP TTRevsSemiFinishedProductsToStartProductionRedefined
	|
	|";
	
	OrderFieldText = Documents.ProductionStage2_2.RequestTextSourceStageField(
															"Table.ReferenceOrder",
															"Table.Stage",
															"Table.Purpose");
	QueryText = StrReplace(QueryText, "&OrderFieldText", OrderFieldText);
		
	If ValueIsFilled(NameTTSelectionByNeed) Then
		QueryText = StrReplace(QueryText, "TTSelectionAccordingToNeed", NameTTSelectionByNeed);
	EndIf;
	
	QueryText = StrReplace(QueryText, "TTSemiFinishedProductsToStartProductionRedefined", NameOfTemporaryResultTable);
	Return QueryText;
	
EndFunction

#EndRegion

#Region DynamicStructure

// Returns the text of the request for the products of the order for the transmitted selection.
// 
// Parameters:
//  TempTableName	       - String	- name of the temporary table to put the result in.
//  NameOfProductionOrderField - String	- the name of the parameter to select for the production order.
// 
// Returns:
//  ValueTable - table of semi-finished products produced in the process.
//
Function QueryTextOrderProducts_(TempTableName = "OrderProducts_", NameOfProductionOrderField = "ProductionOrder") Export

	QueryText = 
	"SELECT
	|	
	|	Table.Products        AS Products,
	|	Table.Characteristic      AS Characteristic,
	|	Table.Warehouse               AS Warehouse,
	|	Table.Department       AS Department,
	|	Table.Purpose          AS Purpose,
	|	Table.ReferenceOrder        AS ProductionOrder,
	|	Table.KeyProducts    AS KeyProducts,
	|	Table.BillOfMaterials        AS BillOfMaterials,
	|
	|	SUM(Table.Required2)   AS Count
	|
	|INTO OrderProducts_
	|FROM
	|	AccumulationRegister.ProductionProcessSupply AS Table
	|
	|WHERE
	|	Table.Recorder = &ProductionOrder
	|
	|GROUP BY
	|
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Warehouse,
	|	Table.Department,
	|	Table.Purpose,
	|	Table.ReferenceOrder,
	|	Table.KeyProducts,
	|	Table.BillOfMaterials
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Department,
	|	Purpose,
	|	ProductionOrder
	|";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "OrderProducts_", TempTableName);
	EndIf;
	
	If Not IsBlankString(NameOfProductionOrderField) Then
		QueryText = StrReplace(QueryText, "&" + "ProductionOrder", "&" + NameOfProductionOrderField);
	EndIf;
	
	Return QueryText;

EndFunction

// Returns the text of the request for the products of the order for the transmitted selection.
// 
// Parameters:
//  TempTableName	               - String	- name of the temporary table to put the result in.
//  NameOfTemporaryTableProductsOfOrder - String	- the name of the temporary table for selection according to the product table of the order.
// 
// Returns:
//  ValueTable - table of semi-finished products produced in the process.
//
Function RequestTextLaunchedOrReleasedOrderProducts(TempTableName = "LaunchedOrReleased", NameOfTemporaryTableProductsOfOrder = "OrderProducts_") Export
	
	QueryText = 
	"SELECT
	|
	|	Available.Products        AS Products,
	|	Available.Characteristic      AS Characteristic,
	|	Available.Warehouse               AS Warehouse,
	|	Available.Department       AS Department,
	|	Available.Purpose          AS Purpose,
	|	Available.ReferenceOrder        AS ProductionOrder,
	|	Available.ReleasingStage     AS ReleasingStage,
	|
	|	Available.ScheduledTurnover
	|	 + Available.TransferredToProductionTurnover
	|	 + Available.ProducedTurnover  AS Launched,
	|	Available.ManufacturedTurnover      AS Released
	|
	|INTO LaunchedOrReleased
	|FROM
	|	AccumulationRegister.ProductionProcessSupply.Turnovers(
	|			,,,
	|			(Products, Characteristic, Warehouse, Department, Purpose, ReferenceOrder) IN
	|					(SELECT
	|						Table.Products,
	|						Table.Characteristic,
	|						Table.Warehouse,
	|						Table.Department,
	|						Table.Purpose,
	|						Table.ProductionOrder
	|					FROM
	|						OrderProducts_ AS Table)) AS Available
	|";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "LaunchedOrReleased", TempTableName);
	EndIf;
	
	If Not IsBlankString(NameOfTemporaryTableProductsOfOrder) Then
		QueryText = StrReplace(QueryText, "OrderProducts_", NameOfTemporaryTableProductsOfOrder);
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

// Returns the query text for semi-finished products produced in the process for the passed selection.
//
// Parameters:
//  TemporaryTableNames - Structure:
//   * SelectionByNeed - String - name of the temporary need selection table.
//   * Result          - String - the name of a temporary table in which to place the result, if not specified, the result will be uploaded.
//  PostfixServiceTemporaryTables - String - if you need to use the function several times in one batch of queries, then you need to specify a unique Postfix
//                                              that will be used in the names of service temporary tables in the query text.
// Returns:
//  String - the text of the request for semi-finished products produced in the process.
//
Function QueryTextSemiFinishedProductsInProduction(TemporaryTableNames, PostfixServiceTemporaryTables) Export
	
	NameTTSelectionByNeed       = TemporaryTableNames.SelectionByNeed;
	NameOfTemporaryResultTable = TemporaryTableNames.Result;
	
	UploadResult = NameOfTemporaryResultTable = "";
	
	QueryText =
	"SELECT
	|	TurnoverOfSemiFinishedProducts.ReferenceOrder AS ReferenceOrder,
	|	
	|	TurnoverOfSemiFinishedProducts.Products   AS Products,
	|	TurnoverOfSemiFinishedProducts.Characteristic AS Characteristic,
	|	
	|	TurnoverOfSemiFinishedProducts.Purpose AS Purpose,
	|	TurnoverOfSemiFinishedProducts.Stage       AS Stage,
	|	
	|	TurnoverOfSemiFinishedProducts.Warehouse          AS Warehouse,
	|	TurnoverOfSemiFinishedProducts.Department  AS Department,
	|	
	|	CASE WHEN TurnoverOfSemiFinishedProducts.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef) THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END                             AS ThisIsAProduct,
	|	
	|	(TurnoverOfSemiFinishedProducts.Required2Turnover + TurnoverOfSemiFinishedProducts.DisassemblyIsPlannedTurnover) AS Count
	|	
	|INTO TTTurnoverOfSemiFinishedProductsInProductionOverridable
	|FROM
	|	AccumulationRegister.ProductionProcessSupply.Turnovers(,,,
	|	
	|			(Products,Characteristic,Warehouse,Department,Purpose) IN(
	|				SELECT
	|					Filter.Products   AS Products,
	|					Filter.Characteristic AS Characteristic,
	|					Filter.Warehouse          AS Warehouse,
	|					Filter.Department  AS Department,
	|					Filter.Purpose     AS Purpose
	|				FROM
	|					TTSelectionAccordingToNeed AS Filter)
	|			
	|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|			
	|		) AS TurnoverOfSemiFinishedProducts
	|WHERE
	|	(TurnoverOfSemiFinishedProducts.Required2Turnover + TurnoverOfSemiFinishedProducts.DisassemblyIsPlannedTurnover) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&OrderFieldText AS OrderDocument,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose     AS Purpose,
	|	
	|	Table.Warehouse         AS Warehouse,
	|	Table.Department AS Department,
	|	
	|	CASE WHEN Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef) THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END              AS ThisIsAProduct,
	|	
	|	Table.Count AS Count
	|	
	|INTO TTSemiFinishedProductsInProductionRedefined
	|FROM
	|	TTTurnoverOfSemiFinishedProductsInProductionOverridable AS Table
	|WHERE
	|	CAST(&OrderFieldText AS Document.ProductionStage2_2).Status <> VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|INDEX BY Products,Characteristic,Purpose,Warehouse,Department";
	
	OrderFieldText = Documents.ProductionStage2_2.RequestTextSourceStageField(
															"Table.ReferenceOrder",
															"Table.Stage",
															"Table.Purpose");
	QueryText = StrReplace(QueryText, "&OrderFieldText", OrderFieldText);
	
	QueryText = StrReplace(
		QueryText,
		"TTTurnoverOfSemiFinishedProductsInProductionOverridable",
		"TTTurnoverOfSemiFinishedProductsInProduction" + PostfixServiceTemporaryTables);
	
	If ValueIsFilled(NameTTSelectionByNeed) Then
		QueryText = StrReplace(QueryText, "TTSelectionAccordingToNeed", NameTTSelectionByNeed);
	EndIf;
	
	If UploadResult Then
		QueryText = StrReplace(QueryText, "INTO TTSemiFinishedProductsInProductionRedefined", "");
		QueryText = StrReplace(QueryText, "INDEX BY Products,Characteristic,Purpose,Warehouse,Department", "");
		
	Else
		QueryText = StrReplace(QueryText, "TTSemiFinishedProductsInProductionRedefined", NameOfTemporaryResultTable);
	EndIf;
	Return QueryText;
	
EndFunction

// Returns a table of semi finished products produced in the process based on the passed selection
//
// Parameters:
//  TempTablesManager	      - TempTablesManager - temporary table Manager
//  NameTTSelectionByNeed	      - String				    - name of the temporary need selection table
//  NameOfTemporaryResultTable - String				    - the name of a temporary table in which to place the result, if not specified, the result will be uploaded.
// 
// Returns:
//  ValueTable - table of semi-finished products produced in the process.
//
Function SemiFinishedProductsInProduction(TempTablesManager, NameTTSelectionByNeed = "", NameOfTemporaryResultTable = "") Export
	
	UploadResult = NameOfTemporaryResultTable = "";
	
	TemporaryTableNames = New Structure();
	TemporaryTableNames.Insert("SelectionByNeed",                 NameTTSelectionByNeed);
	TemporaryTableNames.Insert("Result",                          NameOfTemporaryResultTable);
	
	QueryText = QueryTextSemiFinishedProductsInProduction(TemporaryTableNames, "");
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	QueryExecutionResult = Query.Execute();
	
	Result = Undefined;
	If UploadResult Then
		Result = QueryExecutionResult.Unload();
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
