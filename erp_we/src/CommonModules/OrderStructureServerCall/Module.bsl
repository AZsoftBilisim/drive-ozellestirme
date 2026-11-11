
#Region Public

#Region ValuesForFillingInDocuments

// Returns data for the formation of documents "Order for the movement of goods" Or "Movement of goods", the tabular part is filled with products ready for shipment from the warehouse.
//
// Parameters:
//  RowsIDs - Array - a list of keys indicating the items in the shipment of goods.
//  OnlyInStock - Boolean - flag, if true, then the list of items planned to be moved will be filtered by the availability of the shipment in the warehouse.
// Returns:
//  ValueTable - contains the structure of the replacement parameters:
//  	* Products			 - CatalogRef.Products				 - Nomenclature.
//  	* Characteristic		 - CatalogRef.ItemsCharacteristics	 - Characteristics of the item.
//  	* OriginWarehouse			 - CatalogRef.Warehouses						 - shipping warehouse.
//  	* WarehouseForReceipt		 - CatalogRef.Warehouses						 - receipt warehouse.
//  	* Purpose			 - CatalogRef.Assignments					 - purpose.
//  	* WithAssignment			 - Boolean										 - the attribute, "separate provision".
//  	* NumberOfPackages	 - Number										 - quantity in packages.
//  	* Count			 - Number										 - quantity per unit of storage of the goods.
//
Function TabularPartMovingProductsAccordingToNomenclaturePlan(RowsIDs, OnlyInStock = False) Export

	TabularPartProducts = New Array();
	
	ValueTable = OrderStructureInternal.TabularPartMovingProductsAccordingToNomenclaturePlan(RowsIDs, OnlyInStock);
	
	For Each String In ValueTable Do
		
		LineProducts_ = New Structure;
		
		LineProducts_.Insert("RequestedDeliveryDate", String.ReceiptEnd);
		
		LineProducts_.Insert("SourceWarehouse",	  String.SourceWarehouse);
		LineProducts_.Insert("DestinationWarehouse",	  String.DestinationWarehouse);
		LineProducts_.Insert("ShipmentStart",		  '00010101');
		LineProducts_.Insert("ReceiptEnd", '00010101');
		
		LineProducts_.Insert("Products",		  String.Products);
		LineProducts_.Insert("Characteristic",		  String.Characteristic);
		LineProducts_.Insert("Purpose",			  String.Purpose);
		LineProducts_.Insert(
			"SupplyOption",
			PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
			
		LineProducts_.Insert("NumberOfPackages", String.Count);
		LineProducts_.Insert("Count",         String.Count);
		
		TabularPartProducts.Add(LineProducts_);
		
	EndDo;
	
	Return TabularPartProducts;

EndFunction

// Returns data for the formation of documents "Order for the movement of goods" Or "Movement of goods", the tabular part is filled with components ready for shipment from the warehouse.
//
// Parameters:
//  Product          - Structure - product data to get a list of components to move.
//  ProductionStage - CatalogRef.ProductionStages - additional selection of components by production stage.
//  OnlyInStock - Boolean - flag, if true, then the list of items planned to be moved will be filtered by the availability of the shipment in the warehouse.
//  
// Returns:
//  ValueTable - SeeOrderStructureServerCall.TabularPartMovingProductsAccordingToNomenclaturePlan
//
Function TabularPartMovingComponentsAccordingToNomenclaturePlan(Product, ProductionStage = Undefined, OnlyInStock = False) Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	PlanConsumption.KeyProducts AS KeyProducts
	|FROM
	|	InformationRegister.OrderStructure AS PlanConsumption
	|WHERE
	|	PlanConsumption.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructure AS ProductionPlan
	|		WHERE
	|			&Product
	|			AND ProductionPlan.LineKind IN (
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|			AND ProductionPlan.KeyLot = PlanConsumption.KeyLot)
	|	AND &Stage IN (PlanConsumption.Stage, UNDEFINED, VALUE(Catalog.ProductionStages.EmptyRef))";
	
	TableName = "ProductionPlan";
	ParameterName = "Product";
	
	List = New Array();
	
	For Each Item In Product Do
		List.Add(TableName + "." + Item.Key + " = &" + Item.Key);
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&" + ParameterName, StrConcat(List, " " + "And" + " "));
	
	For Each Item In Product Do
		Query.SetParameter(Item.Key, Item.Value);
	EndDo;
	
	Query.SetParameter("Stage", ProductionStage);
	
	TabularPartProducts = TabularPartMovingProductsAccordingToNomenclaturePlan(Query.Execute().Unload().UnloadColumn(0), OnlyInStock);
	
	Return TabularPartProducts;
	
EndFunction

#EndRegion

#Region Other

// Adds tasks to the recalculation of the production order structure and starts the calculation
// 
// Parameters:
// 	ProductionOrders - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
//
Procedure StartRecalculatingOrderStructure(ProductionOrders) Export
	
	InformationRegisters.OrderStructureCleanupTasks.AddTasks(ProductionOrders);
	
	OrderStructure.StartCalculation();
	
EndProcedure

// Adds tasks to the calculation of the structure of the production order according to the specification and starts the calculation
// 
// Parameters:
// 	BillOfMaterials			 - CatalogRef.BillsOfMaterials			- specification.
// 	ProductionOrders	 - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
//
Procedure StartRecalculatingOrderStructureAccordingToSpecification(BillOfMaterials, ProductionOrders) Export
	
	ListOfProductionOrders = TMCommonUseClientServer.Array(ProductionOrders);
	
	Jobs = InformationRegisters.TasksOfBOMOrderStructureCalculation.CreateRecordSet().UnloadColumns();
	
	For Each ProductionOrder In ListOfProductionOrders Do
		Job = Jobs.Add();
		Job.BillOfMaterials = BillOfMaterials;
		Job.ProductionOrder = ProductionOrder;
	EndDo;
	
	InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTasksFullCalculation(Jobs);
	
	OrderStructure.StartCalculation();
	
EndProcedure

// Generates a complete view of the production order.
// Format: "Order no. %1 from %2, need date %3".
//
// Parameters:
//  DocumentNumber		 - String	 - document number.
//  DocumentDate		 - Date 	 - document date.
//  RequestedCompletionDate	 - Date 	 - the desired date.
//
// Returns:
//  String - full presentation of the production order.
//
Function FullOrderPresentation(DocumentNumber, DocumentDate, RequestedCompletionDate) Export
	
	OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(DocumentNumber, False, True);
	OrderDate  = Format(DocumentDate, "DLF=D");
	
	If RequestedCompletionDate = '00010101' Then
		
		Template = NStr("vi = 'Số %1 ngày %2';
						|ru = '№ %1 от %2';
						|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
						|it = '№ %1 da %2';
						|pl = 'Nr %1 z dnia %2';
						|tr = '%2 tarihli %1 numaralı'");
		Text = StrTemplate(Template, OrderNumber, OrderDate);
		
	Else
		
		Template = NStr("vi = 'Số %1 ngày %2, ngày dự kiến %3';
						|ru = '№ %1 от %2, желаемая дата %3';
						|en = 'No. %1 dated %2, required date %3'; fa = 'No. %1 dated %2, required date %3';
						|it = '№%1 di %2, data richiesta %3';
						|pl = 'Nr %1 z dnia %2, pożądana data %3';
						|tr = '%2 tarihli %1 numaralı, %3 istenen tarih'");
		Text = StrTemplate(Template, OrderNumber, OrderDate, Format(RequestedCompletionDate, "DLF=D"));
		
	EndIf;
	
	Return Text;
	
EndFunction

// If the background structure calculation task is not running, it starts it.
Procedure CheckRunOrderStructureCalculationBackgroundTask() Export
	
	OrderStructureInternal.CheckRunOrderStructureCalculationBackgroundTask();
	
EndProcedure

// Starts the calculation of the order structure
// 
Procedure StartCalculation() Export
	
	OrderStructure.StartCalculation();
	
EndProcedure

#EndRegion

#EndRegion