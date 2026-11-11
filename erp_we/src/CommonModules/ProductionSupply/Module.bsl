#Region Public

#Region SecurityParameters

// Returns the item security parameters
//
// Parameters:
//  Products	 - CatalogRef.Products - The item for which you want to receive provisioning settings.
//  Characteristic	 - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//  Department	 - CatalogRef.BusinessStructure - The Department to get security parameters for.
// 
// Returns:
//  Structure - Contains properties: Warehouse.
//
Function ProductSupportParameters(Products, Characteristic, Department) Export

	TableOfMaterials = New ValueTable;
	TableOfMaterials.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfMaterials.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfMaterials.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	
	StringMaterial = TableOfMaterials.Add();
	StringMaterial.Products = Products; 
	StringMaterial.Characteristic = Characteristic;
	StringMaterial.Department = Department;
	
	SecurityParameters = ProductListSupportParameters(TableOfMaterials);
	
	ConfiguringSoftware = New Structure;
	ConfiguringSoftware.Insert("Warehouse", SecurityParameters[0].Warehouse);

	Return ConfiguringSoftware;
	
EndFunction

// Returns parameters for providing the item list
//
// Parameters:
//  TableOfMaterials	 - ValueTable - contains the Nomenclature, Characteristic, and Division columns
// 
// Returns:
//  ValueTable - contains the Warehouse columns.
//
Function ProductListSupportParameters(TableOfMaterials) Export

	QueryText = 
	"SELECT
	|	CAST(TableOfMaterials.Products AS Catalog.Products)                 AS Products,
	|	CAST(TableOfMaterials.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(TableOfMaterials.Department AS Catalog.BusinessStructure)        AS Department
	|INTO TTTableOfMaterials
	|FROM
	|	&TableOfMaterials AS TableOfMaterials
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfMaterials.Products   AS Products,
	|	TableOfMaterials.Characteristic AS Characteristic,
	|	TableOfMaterials.Department AS Department,
	|	&TextOfMaterialsWarehouseField AS Warehouse
	|FROM
	|	TTTableOfMaterials AS TableOfMaterials,
	|
	|	#TextOfConnectionToGetMaterialsWarehouse";
	
	RequestTextForGettingWarehouse = RequestTextForContentTransferSettings(
		"TableOfMaterials", "Department", Enums.ProductionSupplyFillingVariants.BySupplySchemes);
						
	QueryText = StrReplace(
						QueryText, 
						"#TextOfConnectionToGetMaterialsWarehouse",
						RequestTextForGettingWarehouse.JoinText);
						
	QueryText = StrReplace(
						QueryText, 
						"&TextOfMaterialsWarehouseField",
						RequestTextForGettingWarehouse.WarehouseTextField);
	
	
	Query = New Query(QueryText);
	Query.SetParameter("TableOfMaterials", TableOfMaterials);
	Query.SetParameter("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	
	SetPrivilegedMode(True);
	SecurityParameters = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return SecurityParameters;
	
EndFunction

// Returns parameters for material provision in the production stage
//
// Parameters:
//  Products					 - CatalogRef.Products												 - The item for which you want to receive provisioning settings.
//  Characteristic					 - CatalogRef.ItemsCharacteristics									 - Characteristics of the item.
//  Produced					 - Boolean																		 - Indicates that the material is being produced (it is a semi-finished product).
//  Department					 - CatalogRef.BusinessStructure										 - The Department to get security parameters for.
//  SourceOfSemiFinishedProduct	 - CatalogRef.ProductionStages, CatalogRef.BillsOfMaterials	 - Defines how the semi-finished product is produced.
//  ProductionOrder				 - DocumentRef.ProductionOrder2_2										 - Production order, to get a list of giver's orders and search for items in them.
//  										If the item is found, the security option "Provide separately" is returned.
// 
// Returns:
//  Structure - Contains properties: Warehouse, supply options.
//
Function StageMaterialAssuranceParameters(Products, Characteristic, Produced, Department, SourceOfSemiFinishedProduct, ProductionOrder) Export
	
	TableOfMaterials = New ValueTable;
	TableOfMaterials.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	TableOfMaterials.Columns.Add("SourceOfSemiFinishedProduct", New TypeDescription("CatalogRef.ProductionStages,CatalogRef.BillsOfMaterials"));
	TableOfMaterials.Columns.Add("Produced", New TypeDescription("Boolean"));
	TableOfMaterials.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfMaterials.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	StringMaterial = TableOfMaterials.Add();
	StringMaterial.Products = Products;
	StringMaterial.Characteristic = Characteristic;
	StringMaterial.Produced = Produced;
	StringMaterial.Department = Department;
	StringMaterial.SourceOfSemiFinishedProduct = SourceOfSemiFinishedProduct;
	
	SecurityParameters = StageMaterialAssuranceParameters_(TableOfMaterials, ProductionOrder)[0];
	
	Result = New Structure("Warehouse, SupplyOption, WithAssignment");
	FillPropertyValues(Result, SecurityParameters);
	
	Return Result;
	
EndFunction

// Returns parameters for providing materials in production stages
//
// Parameters:
//   TableOfMaterials 	- ValueTable - table of stage materials.
//							Required fields: Nomenclature, Characteristics,
//									The Unit Is Made Of Historicpreservation
//   ProductionOrder - DocumentRef.ProductionOrder2_2 - Production order, to get a list
//                         of giver's orders and search for items in them. If the item is found,
//                         the security option "Provide separately" is returned.
//
// Returns:
//   ValueTable - table of materials supplemented with columns: Warehouse, supply options.
//
Function StageMaterialAssuranceParameters_(TableOfMaterials, ProductionOrder) Export
	
	QueryText =
	"SELECT
	|	CAST(MaterialsAndServices.Products AS Catalog.Products)                 AS Products,
	|	CAST(MaterialsAndServices.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(MaterialsAndServices.Produced AS BOOLEAN)                                  AS Produced,
	|	CAST(MaterialsAndServices.Department AS Catalog.BusinessStructure)        AS Department,
	|	MaterialsAndServices.SourceOfSemiFinishedProduct                                     AS SourceOfSemiFinishedProduct,
	|	CASE 
	|		WHEN CAST(MaterialsAndServices.Produced AS BOOLEAN) = TRUE
	|				AND MaterialsAndServices.SourceOfSemiFinishedProduct <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|			THEN VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
	|		WHEN CAST(MaterialsAndServices.Produced AS BOOLEAN) = TRUE
	|				AND MaterialsAndServices.SourceOfSemiFinishedProduct = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|			THEN VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)
	|		ELSE VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)
	|	END AS MethodOfReceivingMaterial,
	|	FALSE  AS WithAssignment
	|INTO TTMaterialsAndServices
	|FROM
	|	&TableOfMaterials AS MaterialsAndServices
	|
	|INDEX BY
	|	Department,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|"
	+ Documents.ProductionOrder2_2.QueryTextTTMethodsOfObtainingMaterials2_2()
	+ Common.QueryBatchSeparator()
	+ "
	|SELECT
	|	MaterialsAndServices.Products         AS Products,
	|	MaterialsAndServices.Characteristic       AS Characteristic,
	|	&WarehouseTextField                       AS Warehouse,
	|	&TextFieldSoftwareOption          AS SupplyOption,
	|	&TextFieldIsSeparate                 AS WithAssignment
	|FROM
	|	TTMaterialsAndServices AS MaterialsAndServices
	|
	|		// A request is inserted here to receive a warehouse, a security option
	|		,ConnectionTextSoftwareParameters
	|
	|";
	
	PerformSubstitutionOfMaterialSupportParameters(QueryText,
		"MaterialsAndServices",,,
		Enums.ProductionSupplyFillingVariants.BySupplySchemes);
	
	Query = New Query(QueryText);
	Query.SetParameter("TableOfMaterials", TableOfMaterials);
	Query.SetParameter("References", CommonClientServer.ValueInArray(ProductionOrder));
	Query.SetParameter("ReferenceOrder", ProductionOrder);
	Query.SetParameter("Purpose", Catalogs.Assignments.EmptyRef());
	Query.SetParameter("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	
	SetPrivilegedMode(True);
	SecurityParameters = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return SecurityParameters;
	
EndFunction

// Adds a request to get the data needed to fill out the collateral in the stage.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextCheckFillInSupplyAtProductionStageInBatches(StructureOfActions, QueryDetails, CachedValues) Export
	
	ActionParameters = Undefined;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CheckSoftwareInProductionPhase",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		// TTLinesToFillingOfProvision
		QueryText =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Produced   AS Produced,
		|	Table.Department  AS Department,
		|	Table.BillOfMaterials   AS SourceOfSemiFinishedProduct,
		|	CASE 
		|		WHEN Table.Produced
		|			AND Table.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
		|		WHEN Table.Produced
		|			AND Table.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)
		|		ELSE VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)
		|	END                  AS MethodOfReceivingMaterial,
		|	FALSE                   AS WithAssignment
		|INTO TTLinesToFillingOfProvision
		|FROM
		|	TTDataSource AS Table
		|
		|INDEX BY
		|	Department,
		|	Products,
		|	Characteristic";
		QueryDetails.QueriesTexts.Add(QueryText, "TTLinesToFillingOfProvision");
		
		// TTMethodsOfObtainingMaterials
		QueryText = Documents.ProductionOrder2_2.QueryTextTTMethodsOfObtainingMaterials2_2();
		QueryDetails.QueriesTexts.Add(QueryText, "TTMethodsOfObtainingMaterials");
		
		// TTParametersOfProvisionInProductionPhase
		QueryText =
		"SELECT
		|	MaterialsAndServices.IdOfTTRow AS IdOfTTRow,
		|	MaterialsAndServices.Department         AS Department,
		|	&TextFieldSoftwareOption           AS SupplyOption,
		|	&WarehouseTextField                        AS Warehouse,
		|	&TextFieldIsSeparate                  AS WithAssignment
		|INTO TTParametersOfProvisionInProductionPhase
		|FROM
		|	TTLinesToFillingOfProvision AS MaterialsAndServices
		|
		|		// A request is inserted here to receive a warehouse, a security option
		|		,ConnectionTextSoftwareParameters
		|
		|
		|INDEX BY
		|	Warehouse";
		
		PerformSubstitutionOfMaterialSupportParameters(QueryText,
			"MaterialsAndServices",,,
			Enums.ProductionSupplyFillingVariants.BySupplySchemes);
		
		QueryDetails.QueriesTexts.Add(QueryText, "TTParametersOfProvisionInProductionPhase");
		
		// SecurityParametersInProductionPhase
		QueryText =
		"SELECT
		|	SecurityParameters.IdOfTTRow AS IdOfTTRow,
		|	SecurityParameters.SupplyOption    AS SupplyOption,
		|	SecurityParameters.Warehouse                 AS Warehouse,
		|	SecurityParameters.WithAssignment           AS WithAssignment,
		|	ISNULL(Warehouses.ShopFloorStockroom, FALSE)
		|		AND Warehouses.Department = SecurityParameters.Department AS ThisIsStoreroomOfCurrentUnit
		|FROM
		|	TTParametersOfProvisionInProductionPhase AS SecurityParameters
		|
		|	LEFT JOIN Catalog.Warehouses AS Warehouses
		|	ON SecurityParameters.Warehouse = Warehouses.Ref";
		
		QueryDetails.QueriesTexts.Add(QueryText, "SecurityParametersInProductionPhase");
		
		//
		
		QueryDetails.QueryOptions.Insert("References",
			CommonClientServer.ValueInArray(ActionParameters.ProductionOrder));
		QueryDetails.QueryOptions.Insert("ReferenceOrder", ActionParameters.ProductionOrder);
		QueryDetails.QueryOptions.Insert("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
		
	EndIf;
	
EndProcedure

// Adds a request to get the data needed to fill out the warehouse in the production documents.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextCheckFillOutProductionWarehouse(StructureOfActions, QueryDetails, CachedValues) Export
	
	ActionParameters = Undefined;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CheckFillProductionWarehouse",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.IdOfTTRow AS IdOfTTRow,
	|	&TextOfMaterialsWarehouseField AS Warehouse
	|FROM
	|	TTDataSource AS Table,
	|
	|	#TextOfConnectionToGetMaterialsWarehouse";
	
	If ValueIsFilled(ActionParameters.Department) Then
		DivisionFromSource = False;
	Else
		DivisionFromSource = BatchProcessingOfTablePartServer.ThereIsColumnInDataSource(
			"Department", CachedValues);
	EndIf;
	FieldNameDivision = ?(DivisionFromSource, "Department", "&FillProductionWarehouseDivision");
	RequestTextForGettingWarehouse = RequestTextForContentTransferSettings(
		"Table", FieldNameDivision, Enums.ProductionSupplyFillingVariants.BySupplySchemes);
						
	QueryText = StrReplace(
		QueryText, 
		"#TextOfConnectionToGetMaterialsWarehouse",
		RequestTextForGettingWarehouse.JoinText);
						
	QueryText = StrReplace(
		QueryText, 
		"&TextOfMaterialsWarehouseField",
		RequestTextForGettingWarehouse.WarehouseTextField);
	
	QueryDetails.QueriesTexts.Add(QueryText, "FillingParametersOfProductionWarehouse");
	QueryDetails.QueryOptions.Insert("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	If Not DivisionFromSource Then
		QueryDetails.QueryOptions.Insert("FillProductionWarehouseDivision",
			ActionParameters.Department);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// The function returns the structure of the default method for getting materials
// 
// Returns:
//  Structure - methods of obtaining materials by default.
//
Function StructureDefaultMethodsForObtainingMaterials() Export
	
	Result = New Structure;
	Result.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Result.Insert("OrderToWarehouse", True);
	Result.Insert("SupplyOption", PredefinedValue("Enum.SupplyOptions.NotRequired"));
	Result.Insert("WithAssignment", False);
	Result.Insert("ToPlan", False);
	
	Result.Insert("DemandDate", '00010101');
	
	Return Result;
	
EndFunction

// The function returns an empty table for selecting ways to get materials into production.
// 
// Returns:
//  ValueTable - Table of materials.
//
Function CreateSourceForSelectingMethodsForObtainingMaterials() Export
	
	Table = New ValueTable;
	
	Table.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(10,0)));
	
	Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	
	Table.Columns.Add("ProducedInProcess", New TypeDescription("Boolean"));
	Table.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	
	Table.Columns.Add(
		"MethodOfReceivingMaterial", 
		New TypeDescription("EnumRef.MethodsOfReceivingBOMMaterials"));
	
	Table.Columns.Add(
		"SourceOfSemiFinishedProduct", 
		New TypeDescription("CatalogRef.ProductionStages,CatalogRef.BillsOfMaterials"));
	
	Return Table;
	
EndFunction

// The function returns the default method for getting the material for the production stage.
//
// Parameters:
//  OrderData	 - Structure - order data structure:
//  	* ReferenceOrder           - DocumentRef.ProductionOrder2_2 - production order
//  	* ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure - Unit responsible for the execution of the order
//  	* Purpose             - CatalogRef.Assignments - assigning a separate need
//  	* EarliestStartDate          - Date - the date that you need to start producing at the earliest.
//  MaterialData	 - Structure - material data structure:
//  	* Department          - CatalogRef.BusinessStructure - Receiving department
//  	* ProductionByThirdParty  - Boolean - indicates that production is being performed on the side
//  	* Products           - CatalogRef.Products - the material to set up the setting for
//  	* Characteristic         - CatalogRef.ItemsCharacteristics - characteristics of the material for which the setting is defined
//   TempTablesManager - TempTablesManager - contains temporary tables used to obtain the provision method:
//        In the method of obtaining materials - A temporary table with the fields Nomenclature, Characteristics, Purpose, Warehouse, Separately.
//  SoftwareFillingOption	 - EnumRef.ProductionSupplyFillingVariants - The option of filling in the security
// 
// Returns:
//  Structure - Contains Properties:
//  	* Warehouse - CatalogRef.Warehouses - The warehouse from which materials are transferred to the division.
//  	* OrderToWarehouse - Boolean - indicates that the material must be ordered to the warehouse
//  	* SupplyOption - EnumRef.SupplyOptions - security option
//  	* ToPlan - Boolean - a sign that the material is possible.
//
Function DefaultMethodForGettingContent(OrderData, MaterialData, TempTablesManager = Undefined, SoftwareFillingOption = Undefined) Export
	
	SettingUpContentTransfer = StructureDefaultMethodsForObtainingMaterials();
	
	If ValueIsFilled(MaterialData.Department)
		And ValueIsFilled(MaterialData.Products) Then
		
		TableOfMaterials = New ValueTable;
		TableOfMaterials.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		TableOfMaterials.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
		TableOfMaterials.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		TableOfMaterials.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfMaterials.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		
		FillPropertyValues(TableOfMaterials.Add(), MaterialData);
		FillPropertyValues(SettingUpContentTransfer, DefaultMethodsForGettingMaterials(OrderData,TableOfMaterials,,SoftwareFillingOption)[0]);
		
	EndIf;
	
	Return New FixedStructure(SettingUpContentTransfer);
	
EndFunction

// This function returns the default methods for getting materials for production stages.
//
// Parameters:
//   OrderData - Structure - order data structure:
//       * ReferenceOrder           - DocumentRef.ProductionOrder2_2 - production order
//       * ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure - Unit responsible for the execution of the order
//       * Purpose             - CatalogRef.Assignments - assigning a separate need
//       * EarliestStartDate          - Date - the date that you need to start producing at the earliest.
//   TableOfMaterials - ValueTable - stage materials table
//							Required fields: Item, description, Unit, PROIZVODSTVENNOE,
//							Additional fields: Productionprocess, method of obtaining the Material, source of obtaining the semi-Factory.
//
//   TempTablesManager - TempTablesManager - contains temporary tables used to obtain the provision method:
//        In the method of obtaining materials - A temporary table with the fields Nomenclature, Characteristics, Purpose, Warehouse, Separately.
//  SoftwareFillingOption	 - EnumRef.ProductionSupplyFillingVariants - The option of filling in the security
//
// Returns:
//   - ValueTable - table of materials, supplemented by methods of obtaining materials:
//       * LineNumber - Number - row number of the source table
//       * Products - CatalogRef.Products - the material to set up the setting for
//       * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the material for which
//                                                                        the setting is defined
//       * Department - CatalogRef.BusinessStructure - Receiving department 
//       * ProductionByThirdParty - Boolean - indicates that production is being performed on the side
//       * Warehouse - CatalogRef.Warehouses - The warehouse from which materials are transferred to the division. 
//       * OrderToWarehouse - Boolean - indicates that the material must be ordered to the warehouse
//       * SupplyOption - EnumRef.SupplyOptions - security option
//       * ToPlan - Boolean - a sign that the material is possible.
//
Function DefaultMethodsForGettingMaterials(OrderData, TableOfMaterials, TempTablesManager = Undefined, SoftwareFillingOption = Undefined) Export
	
	If TableOfMaterials.Columns.Find("Warehouse") = Undefined Then
		TableOfMaterials.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	
	QueryText = "";
	
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager;
	EndIf;
	
	If TempTablesManager.Tables.Find("TTMethodsOfObtainingMaterials") = Undefined Then
		QueryText = QueryText
			+ RequestTextTTMethodsOfGettingMaterialsEmpty();
	EndIf;
	
	If TempTablesManager.Tables.Find("TTWarehouseFormats") = Undefined Then
		QueryText = QueryText
			+ Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False);
	EndIf;
	
	QueryText = QueryText +
		"SELECT
		|	&TextFieldLineNumber                                                               AS LineNumber,
		|	CAST(MaterialsAndServices.Products AS Catalog.Products)                 AS Products,
		|	CAST(MaterialsAndServices.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	CAST(MaterialsAndServices.Department AS Catalog.BusinessStructure)        AS Department,
		|	CAST(MaterialsAndServices.ProductionByThirdParty AS BOOLEAN)                         AS ProductionByThirdParty,
		|	CAST(MaterialsAndServices.Warehouse AS Catalog.Warehouses)                              AS Warehouse,
		|	&TextFieldIsProducedInProcess                                                     AS ProducedInProcess,
		|	&TextFieldHowToGetContent                                                  AS MethodOfReceivingMaterial,
		|	FALSE                                                                                AS WithAssignment,
		|	&TextFieldSourceOfSemiFinishedProduct                                            AS SourceOfSemiFinishedProduct
		|INTO TTMaterialsAndServices
		|FROM
		|	&TableOfMaterials AS MaterialsAndServices
		|
		|INDEX BY
		|	Department,
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MaterialsAndServices.LineNumber           AS LineNumber,
		|	MaterialsAndServices.Products          AS Products,
		|	MaterialsAndServices.Characteristic        AS Characteristic,
		|	MaterialsAndServices.Department         AS Department,
		|	MaterialsAndServices.ProductionByThirdParty AS ProductionByThirdParty,
		
		// Beginning. Warehouse
		|	CASE WHEN MaterialsAndServices.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) THEN
		|		&WarehouseTextField
		|	ELSE
		|		MaterialsAndServices.Warehouse
		|	END AS Warehouse,
		// End. Warehouse
		
		// Beginning. Order to the warehouse
		|	CASE 
		|		WHEN MaterialsAndServices.Products = VALUE(Catalog.Products.EmptyRef)
		|			OR MaterialsAndServices.Products.ItemsType IN (VALUE(Enum.ItemsTypes.Work_5),
		|																	VALUE(Enum.ItemsTypes.OperationService))
		|			THEN FALSE
		|		WHEN MaterialsAndServices.ProducedInProcess THEN
		|			CASE
		|				WHEN MaterialsAndServices.SourceOfSemiFinishedProduct REFS Catalog.ProductionStages
		|						AND CAST(MaterialsAndServices.SourceOfSemiFinishedProduct AS Catalog.ProductionStages).Department = MaterialsAndServices.Department
		|					THEN FALSE
		|				WHEN MaterialsAndServices.SourceOfSemiFinishedProduct REFS Catalog.ProductionStages
		|						AND CAST(MaterialsAndServices.SourceOfSemiFinishedProduct AS Catalog.ProductionStages).Department <> MaterialsAndServices.Department
		|					THEN TRUE
		|				ELSE FALSE
		|			END
		|		ELSE FALSE
		|	END                                                       AS OrderToWarehouse,
		// End. Order to the warehouse

		// Beginning. Security option
		|	&TextFieldSoftwareOption                                AS SupplyOption,
		|	&TextFieldIsSeparate                                       AS WithAssignment,
		// End. Security option
		
		|	&DemandDate AS DemandDate,
		|	CASE
		|		WHEN (&ProductionDispatcherBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
		|				OR ISNULL(CatSupplyMethod.SourceOfDemandSupply, VALUE(Catalog.BusinessStructure.EmptyRef))
		|					IN (&ProductionDispatcherBusinessUnit,
		|					   UNDEFINED,
		|					   VALUE(Catalog.BusinessStructure.EmptyRef)))
		|				AND ISNULL(CatSupplyMethod.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef)) = VALUE(Enum.SupplyTypes.Production)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                       AS ToPlan
		|FROM
		|	TTMaterialsAndServices AS MaterialsAndServices
		|
		|		// A request is inserted here to receive a warehouse, a security option
		|		,ConnectionTextSoftwareParameters
		|
		|
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON CASE WHEN MaterialsAndServices.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) THEN
		|				&WarehouseTextField
		|			ELSE
		|				MaterialsAndServices.Warehouse
		|			END = CatWarehouses.Ref
		|
		|		LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
		|		ON &MainSupplyMethodSubstitution
		|";
		
	If TableOfMaterials.Columns.Find("ProducedInProcess") <> Undefined Then
		TextFieldIsProducedInProcess = "MaterialsAndServices.ProducedInProcess";
	Else
		TextFieldIsProducedInProcess = "False";
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&TextFieldIsProducedInProcess",
		TextFieldIsProducedInProcess);
		
	// TextFieldLineNumber
	If TableOfMaterials.Columns.Find("LineNumber") <> Undefined Then
		TextFieldLineNumber = "MaterialsAndServices.LineNumber";
	Else
		TextFieldLineNumber = "0";
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&TextFieldLineNumber",
		TextFieldLineNumber);
		
	// TextFieldHowToGetContent
	If TableOfMaterials.Columns.Find("MethodOfReceivingMaterial") <> Undefined Then
		TextFieldHowToGetContent = "MaterialsAndServices.MethodOfReceivingMaterial";
	Else
		TextFieldHowToGetContent = "VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)";
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&TextFieldHowToGetContent",
		TextFieldHowToGetContent);
	
	// TextFieldSourceOfSemiFinishedProduct
	If TableOfMaterials.Columns.Find("SourceOfSemiFinishedProduct") <> Undefined Then
		TextFieldSourceOfSemiFinishedProduct = "MaterialsAndServices.SourceOfSemiFinishedProduct";
	Else
		TextFieldSourceOfSemiFinishedProduct = 
			"CASE 
			|	WHEN TRUE
			|		THEN VALUE(Catalog.BillsOfMaterials.EmptyRef)
			|		ELSE VALUE(Catalog.ProductionStages.EmptyRef)
			|END";
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&TextFieldSourceOfSemiFinishedProduct",
		TextFieldSourceOfSemiFinishedProduct);
		
	PerformSubstitutionOfMaterialSupportParameters(QueryText,
		"MaterialsAndServices",
		"MethodOfReceivingMaterial",,
		SoftwareFillingOption);
		
	ConnectionFields = "MaterialsAndServices.Products, MaterialsAndServices.Characteristic,CatWarehouses.Ref";
	ParameterName   = "MainSupplyMethodSubstitution";
	
	QueryText = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
		QueryText, ParameterName, ConnectionFields);

	Query = New Query(QueryText);
	
	Query.SetParameter("ProductionDispatcherBusinessUnit", OrderData.ProductionDispatcherBusinessUnit);
	Query.SetParameter("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	
	If OrderData.Property("DemandDate") Then
		Query.SetParameter("DemandDate", OrderData.DemandDate);
	ElsIf OrderData.Property("EarliestStartDate") Then
		Query.SetParameter("DemandDate", OrderData.EarliestStartDate);
	Else
		Query.SetParameter("DemandDate", '00010101');
	EndIf;
	
	If OrderData.Property("ReferenceOrder") Then
		Query.SetParameter("ReferenceOrder", OrderData.ReferenceOrder);
	Else
		Query.SetParameter("ReferenceOrder", Undefined);
	EndIf;
	
	If OrderData.Property("Purpose") Then
		Query.SetParameter("Purpose", OrderData.Purpose);
	Else
		Query.SetParameter("Purpose", Catalogs.Assignments.EmptyRef());
	EndIf;
	
	Query.SetParameter("TableOfMaterials", TableOfMaterials);
	
	Query.TempTablesManager = TempTablesManager;
	Result = Query.Execute().Unload();
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager, "TTMaterialsAndServices");
	
	Return Result;
	
EndFunction

// Updates the data when the production stage software changes
//
// Parameters:
//  AnArrayOfOrders	 - Array			 - contains links to documents.
//  Errors - See InformationRegisters.ProductionStageStates.UpdateSoftwareState.Errors
//
Procedure WhenSoftwareChanges(AnArrayOfOrders, Errors = Undefined) Export
	
	For Each Item In TMCommonUse.MatchingArraysByObjectType(AnArrayOfOrders) Do
		If Item.Key = "Document.ProductionStage2_2" Then
			
			Query = New Query(
				"SELECT
				|	Stages.Ref AS Ref
				|FROM
				|	Document.ProductionStage2_2 AS Stages
				|WHERE
				|	Stages.Ref IN (&References)
				|	AND NOT Stages.DynamicStructure");
			Query.SetParameter("References", Item.Value);
			References = Query.Execute().Unload().UnloadColumn("Ref");
			
			InformationRegisters.ProductionStageStates.UpdateSoftwareState(References, Errors);
			ProductionManagement.CheckTimingOfProvisionOfStages(References);
			Break;
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal
#Region AppointmentInStage

Function ActionParametersFillInPurposeOfProvisionInProductionPhase(Object, ManufacturedProducts, Cached_Values = Undefined) Export
	
	Result = New Structure();
	Result.Insert("AssignmentMaterials", Catalogs.Assignments.EmptyRef());
	Result.Insert("AssignmentSemiFinishedProducts", Catalogs.Assignments.EmptyRef());
	
	If ThisIsStageForManyAppointments(Object) Then
		
		If TypeOf(Cached_Values) = Type("Structure")
			And Cached_Values.Property("AssignmentMaterials") Then
			Result.AssignmentMaterials = Cached_Values.AssignmentMaterials;
		Else
			If ManufacturedProducts <> Undefined
				And ManufacturedProducts.Count() > 0 Then
				
				QueryText =
					"SELECT
					|	Products_1.Purpose AS Purpose,
					|	&ReferenceOrder      AS ReferenceOrder
					|INTO TTWares
					|FROM
					|	&Products_1 AS Products_1
					|;
					|
					|////////////////////////////////////////////////////////////////////////////////
					|SELECT
					|	CASE
					|		WHEN COUNT(DISTINCT &TextOfMaterialsAssignmentField) > 1
					|			THEN VALUE(Catalog.Assignments.EmptyRef)
					|		ELSE MAX(&TextOfMaterialsAssignmentField)
					|	END AS AssignmentMaterials
					|FROM
					|	TTWares AS Products_1";
				
				QueryText = StrReplace(QueryText,
					"&TextOfMaterialsAssignmentField",
					OrderStructureDocumentPosting.TextOfMaterialsAssignmentField(
						"Products_1.ReferenceOrder", "Products_1.Purpose"));
				
				Table = ?(TypeOf(ManufacturedProducts) = Type("ValueTable"),
					ManufacturedProducts.Copy(New Structure("Canceled", False), "Purpose"),
					ManufacturedProducts.Unload(New Structure("Canceled", False), "Purpose"));
				
				Query = New Query(QueryText);
				Query.SetParameter("Products_1", Table);
				Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					Result.AssignmentMaterials = Selection.AssignmentMaterials;
				EndIf;
				
			ElsIf ValueIsFilled(Object.ProductionLot) Then
				
				QueryText =
					"SELECT
					|	CASE
					|		WHEN COUNT(DISTINCT &TextOfMaterialsAssignmentField) > 1
					|			THEN VALUE(Catalog.Assignments.EmptyRef)
					|		ELSE MAX(&TextOfMaterialsAssignmentField)
					|	END AS AssignmentMaterials
					|FROM
					|	Document.ProductionStage2_2.ManufacturedProducts AS Products_1
					|WHERE
					|	Products_1.Ref.ProductionLot = &ProductionLot
					|	AND Products_1.Ref.Posted
					|	AND NOT Products_1.Canceled";
				
				QueryText = StrReplace(QueryText,
					"&TextOfMaterialsAssignmentField",
					OrderStructureDocumentPosting.TextOfMaterialsAssignmentField(
						"Products_1.Ref.ReferenceOrder", "Products_1.Purpose"));
				
				Query = New Query(QueryText);
				Query.SetParameter("ProductionLot", Object.ProductionLot);
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					Result.AssignmentMaterials = Selection.AssignmentMaterials;
				EndIf;
				
			EndIf;
			If TypeOf(Cached_Values) = Type("Structure") Then
				Cached_Values.Insert("AssignmentMaterials", Result.AssignmentMaterials);
			EndIf;
		EndIf;
		
		Result.AssignmentSemiFinishedProducts = Object.Purpose;
		
	Else
		
		If TypeOf(Cached_Values) = Type("Structure")
			And Cached_Values.Property("IsolationScheme") Then
			IsolationScheme = Cached_Values.IsolationScheme;
		Else
			IsolationScheme = Documents.ProductionOrder2_2.IsolationScheme(
				Object.ReferenceOrder,
				Object.AssignmentProducts);
			If TypeOf(Cached_Values) = Type("Structure") Then
				Cached_Values.Insert("IsolationScheme", IsolationScheme);
			EndIf;
		EndIf;
		
		If ValueIsFilled(IsolationScheme.AssignmentMaterials) Then
			AssignmentMaterials = IsolationScheme.AssignmentMaterials;
		Else
			AssignmentMaterials = Object.Purpose;
		EndIf;
		
		If IsolationScheme.DisabledAssignmentByProductionStageForIntermediateProducts
			Or Object.WorkPlanning Then
			AssignmentSemiFinishedProducts = AssignmentMaterials;
		Else
			AssignmentSemiFinishedProducts = Object.Purpose;
		EndIf;
		
		Result.AssignmentMaterials = AssignmentMaterials;
		Result.AssignmentSemiFinishedProducts = AssignmentSemiFinishedProducts;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function PurposeOfProvidingProductionStageAccordingToScheme(IsolationScheme, PurposeObject, WorkPlanning) Export
	
	AssignmentMaterials = PurposeObject;
	AssignmentSemiFinishedProducts = PurposeObject;
	
	If IsolationScheme <> Undefined Then
		If ValueIsFilled(IsolationScheme.AssignmentMaterials) Then
			AssignmentMaterials = IsolationScheme.AssignmentMaterials;
		EndIf;
		If IsolationScheme.DisabledAssignmentByProductionStageForIntermediateProducts
			Or WorkPlanning Then
			AssignmentSemiFinishedProducts = AssignmentMaterials;
		EndIf;
	EndIf;
	
	Result = New Structure();
	Result.Insert("AssignmentMaterials", AssignmentMaterials);
	Result.Insert("AssignmentSemiFinishedProducts", AssignmentSemiFinishedProducts);
	
	Return Result;
	
EndFunction

Procedure FillInPurposeOfSemiFinishedProductsInProductionPhase(Object) Export
	
	If Object.DynamicStructure
		And Not Object.WorkPlanning Then
		
		AssignmentSemiFinishedProducts = Object.Purpose;
		
	Else
		
		IsolationScheme = Documents.ProductionOrder2_2.IsolationScheme(
			Object.ReferenceOrder,
			Object.AssignmentProducts);
		
		If IsolationScheme.DisabledAssignmentByProductionStageForIntermediateProducts
			Or Object.WorkPlanning Then
			If ValueIsFilled(IsolationScheme.AssignmentMaterials) Then
				AssignmentSemiFinishedProducts = IsolationScheme.AssignmentMaterials;
			Else
				AssignmentSemiFinishedProducts = Object.Purpose;
			EndIf;
		Else
			AssignmentSemiFinishedProducts = Object.Purpose;
		EndIf;
		
	EndIf;
	
	FoundRows = Object.SupplyWithMaterialsAndWorks.FindRows(New Structure("Produced", True));
	For Each String In FoundRows Do
		String.SupplyAssignment = AssignmentSemiFinishedProducts;
		String.Purpose = AssignmentSemiFinishedProducts;
	EndDo;
	
EndProcedure

Procedure FillInAssignmentOfMaterialsSpecifications(SpecificationData, Stage, AssignmentsOfMaterials, AssignmentSemiFinishedProducts) Export
	
	TheStructureOfTheSearch = New Structure("Stage", Stage);
	
	For Cnt = 1 To 2 Do
		
		TableName = ?(Cnt = 1, "IncomingProducts", "MaterialsAndServices");
		
		If Not SpecificationData.Property(TableName) Then
			Continue;
		EndIf;
		
		For Each String In SpecificationData[TableName].FindRows(TheStructureOfTheSearch) Do
			
			If String.Produced Or String.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct Then
				String.SupplyAssignment = AssignmentSemiFinishedProducts;
				If String.WithAssignment Then
					String.Purpose = String.SupplyAssignment;
				EndIf;
				Continue;
			EndIf;
			
			Base = String.Count;
			
			MaxIndex_ = AssignmentsOfMaterials.Count()-1;
			For IndexOf = 0 To MaxIndex_ Do
				
				FillingValues = AssignmentsOfMaterials[IndexOf];
				If IndexOf = MaxIndex_
					Or FillingValues.ZoomRatio = 1 Then
					String.SupplyAssignment = FillingValues.Purpose;
					If String.WithAssignment Then
						String.Purpose = String.SupplyAssignment;
					EndIf;
				Else
					
					Count = Min(String.Count, Round(Base * FillingValues.ZoomRatio, 3));
					If Count = 0 Then
						Continue;
					EndIf;
					
					If Count = String.Count Then
						String.SupplyAssignment = FillingValues.Purpose;
						If String.WithAssignment Then
							String.Purpose = String.SupplyAssignment;
						EndIf;
						Break;
					Else
						NewRow = SpecificationData[TableName].Insert(
							SpecificationData[TableName].IndexOf(String));
						FillPropertyValues(NewRow, String,, "Count, NumberOfPackages");
						NewRow.SupplyAssignment = FillingValues.Purpose;
						If NewRow.WithAssignment Then
							NewRow.Purpose = NewRow.SupplyAssignment;
						EndIf;
						NewRow.Count = Count;
						NewRow.NumberOfPackages = NewRow.Count
							* NewRow.PackageData.Denominator / NewRow.PackageData.Numerator;
						
						String.Count = String.Count - Count;
						String.NumberOfPackages = String.Count
							* String.PackageData.Denominator / String.PackageData.Numerator;
					EndIf;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

Function CoefficientsOfSecurityAssignmentsInProductionStage(Object, ManufacturedProducts) Export
	
	If Not ThisIsStageForManyAppointments(Object) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	QueryTexts = New Array;
	
	If ManufacturedProducts.Count() > 0 Then
		QueryTexts.Add(
			"SELECT
			|	&ReferenceOrder          AS ReferenceOrder,
			|	&BillOfMaterials          AS BillOfMaterials,
			|	CAST(Products_1.Products AS Catalog.Products) AS Products,
			|	Products_1.Characteristic AS Characteristic,
			|	Products_1.Purpose     AS Purpose,
			|	Products_1.Count     AS Count
			|INTO TTWares
			|FROM
			|	&Products_1 AS Products_1");
		Query.SetParameter("Products_1", ManufacturedProducts);
		Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
		Query.SetParameter("BillOfMaterials", Object.BillOfMaterials);
	ElsIf ValueIsFilled(Object.ProductionLot) Then
		QueryTexts.Add(
			"SELECT
			|	Products_1.Ref.ReferenceOrder AS ReferenceOrder,
			|	Products_1.Ref.BillOfMaterials AS BillOfMaterials,
			|	Products_1.Products        AS Products,
			|	Products_1.Characteristic      AS Characteristic,
			|	Products_1.Purpose          AS Purpose,
			|	Products_1.Count          AS Count
			|INTO TTWares
			|FROM
			|	Document.ProductionStage2_2.ManufacturedProducts AS Products_1
			|WHERE
			|	Products_1.Ref.ProductionLot = &ProductionLot
			|	AND Products_1.Ref.Posted
			|	AND NOT Products_1.Canceled");
		Query.SetParameter("ProductionLot", Object.ProductionLot);
	EndIf;
	
	QueryTexts.Add(
		"SELECT
		|	&TextOfMaterialsAssignmentField AS Purpose,
		|	SUM(
		|		CASE
		|			WHEN ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1) = 0
		|				THEN 0
		|			ELSE Products_1.Count / (ProductsBOM.NumberOfPackagesPerStartingLotUnit * ISNULL(&QueryTextPackagingFactor, 1))
		|		END)                     AS Count
		|INTO DestinationTT
		|FROM
		|	TTWares AS Products_1
		|
		|	LEFT JOIN InformationRegister.ProductsBOM AS ProductsBOM
		|	ON Products_1.BillOfMaterials = ProductsBOM.BillOfMaterials
		|		AND Products_1.Products.ProductKind = ProductsBOM.ProductKind
		|		AND ProductsBOM.Products   IN (Products_1.Products, VALUE(Catalog.Products.EmptyRef))
		|		AND ProductsBOM.Characteristic IN (Products_1.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|
		|GROUP BY
		|	&TextOfMaterialsAssignmentField
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(PartyAssignments.Count)  AS Count
		|INTO TTAppointmentsTotals
		|FROM
		|	DestinationTT AS PartyAssignments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Assignments.Purpose AS Purpose,
		|	Assignments.Count / AppointmentsResults.Count AS ZoomRatio
		|FROM
		|	DestinationTT AS Assignments
		|
		|	INNER JOIN TTAppointmentsTotals AS AppointmentsResults
		|	ON TRUE
		|WHERE
		|	Assignments.Count <> 0");
	
	QueryText = StrConcat(QueryTexts, ";");
	QueryText = StrReplace(QueryText,
		"&TextOfMaterialsAssignmentField",
		OrderStructureDocumentPosting.TextOfMaterialsAssignmentField(
			"Products_1.ReferenceOrder", "Products_1.Purpose"));
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsBOM.Package", "ProductsBOM.Products"));
	
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure FillInListOfSelectedAssignmentsInProductionPhase(Object, ManufacturedProducts, ChoiceList, Cached_Values = Undefined) Export
	
	ChoiceList.Clear();
	
	If ThisIsStageForManyAppointments(Object) Then
		
		If TypeOf(Cached_Values) = Type("Structure")
			And Cached_Values.Property("Assignments") Then
			ChoiceList.LoadValues(Cached_Values.Assignments);
		Else
			If ManufacturedProducts <> Undefined
				And ManufacturedProducts.Count() > 0 Then
				
				QueryText =
					"SELECT
					|	Products_1.Purpose AS Purpose,
					|	&ReferenceOrder      AS ReferenceOrder
					|INTO TTWares
					|FROM
					|	&Products_1 AS Products_1
					|;
					|
					|////////////////////////////////////////////////////////////////////////////////
					|SELECT DISTINCT
					|	&TextOfMaterialsAssignmentField AS Purpose
					|FROM
					|	TTWares AS Products_1";
				
				QueryText = StrReplace(QueryText,
					"&TextOfMaterialsAssignmentField",
					OrderStructureDocumentPosting.TextOfMaterialsAssignmentField(
						"Products_1.ReferenceOrder", "Products_1.Purpose"));
				
				Table = ?(TypeOf(ManufacturedProducts) = Type("ValueTable"),
					ManufacturedProducts.Copy(New Structure("Canceled", False), "Purpose"),
					ManufacturedProducts.Unload(New Structure("Canceled", False), "Purpose"));
				
				Query = New Query(QueryText);
				Query.SetParameter("Products_1", Table);
				Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					ChoiceList.Add(Selection.Purpose);
				EndDo;
				
			ElsIf ValueIsFilled(Object.ProductionLot) Then
				
				QueryText =
					"SELECT DISTINCT
					|	&TextOfMaterialsAssignmentField AS Purpose
					|FROM
					|	Document.ProductionStage2_2.ManufacturedProducts AS Products_1
					|WHERE
					|	Products_1.Ref.ProductionLot = &ProductionLot
					|	AND Products_1.Ref.Posted
					|	AND NOT Products_1.Canceled";
				
				QueryText = StrReplace(QueryText,
					"&TextOfMaterialsAssignmentField",
					OrderStructureDocumentPosting.TextOfMaterialsAssignmentField(
						"Products_1.Ref.ReferenceOrder", "Products_1.Purpose"));
				
				Query = New Query(QueryText);
				Query.SetParameter("ProductionLot", Object.ProductionLot);
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					ChoiceList.Add(Selection.Purpose);
				EndDo;
				
			EndIf;
			
			If TypeOf(Cached_Values) = Type("Structure") Then
				Cached_Values.Insert("Assignments", ChoiceList.UnloadValues());
			EndIf;
			
		EndIf;
		
	Else
		
		If TypeOf(Cached_Values) = Type("Structure")
			And Cached_Values.Property("IsolationScheme") Then
			IsolationScheme = Cached_Values.IsolationScheme;
		Else
			IsolationScheme = Documents.ProductionOrder2_2.IsolationScheme(
				Object.ReferenceOrder,
				Object.AssignmentProducts);
			If TypeOf(Cached_Values) = Type("Structure") Then
				Cached_Values.Insert("IsolationScheme", IsolationScheme);
			EndIf;
		EndIf;
		
		If ValueIsFilled(IsolationScheme.AssignmentMaterials) Then
			ChoiceList.Add(IsolationScheme.AssignmentMaterials);
		Else
			ChoiceList.Add(Object.Purpose);
		EndIf;
		
	EndIf;
	
	If ChoiceList.FindByValue(Object.Purpose) = Undefined Then
		ChoiceList.Add(Object.Purpose);
	EndIf;
	
EndProcedure

Function ThisIsStageForManyAppointments(Object)
	
	Return Object.DynamicStructure 
		And Not ValueIsFilled(Object.AssignmentProducts)
		And Common.ObjectAttributeValue(Object.ReferenceOrder, "ConsolidatedOrderByProductAssignments");
	
EndFunction

#EndRegion
#EndRegion

#Region Private

#Region Actions

Procedure FillInWarehouseInProductionStageLine(CurrentRow, ActionParameters) Export
	
	SecurityParameters = ProductionSupply.ProductSupportParameters(
								CurrentRow.Products,
								CurrentRow.Characteristic,
								ActionParameters.Department);
								
	FieldList = StrSplit(ActionParameters.WarehouseFieldName, ",");
	For Each WarehouseFieldName In FieldList Do
		CurrentRow[WarehouseFieldName] = SecurityParameters.Warehouse;
	EndDo;

EndProcedure

#EndRegion

#Region QueriesTexts

// Returns the text of the request that can be used to get the warehouse of materials.
//
// Parameters:
//  NameOfMaterialsTable			 - String - Alias of the "materials" table. The table must contain
//		the Item, Characteristic, and Division fields (optional).
//  FieldNameDivision		 - String - Name of the "Division" field in the materials table.
//		If a division is defined by a parameter, add "&"before the name.
//  SoftwareFillingOption	 - EnumRef.ProductionSupplyFillingVariants - The option of filling in the security
// 
// Returns:
//  Structure - contains query texts:
//  	* WarehouseTextField - String - text for getting the "Warehouse" field.
//  	* JoinText - String - connection text.
//
Function RequestTextForContentTransferSettings(NameOfMaterialsTable, FieldNameDivision = Undefined, SoftwareFillingOption = Undefined) Export
	
	If SoftwareFillingOption = Enums.ProductionSupplyFillingVariants.DontFill Then
		
		WarehouseTextField     = "FALSE";
		JoinText    = "";
		
	Else
		
			
			WarehouseTextField = 
			"CASE
			|	WHEN ISNULL(DetailedSetup.InventoryReplenishmentMethod, 
			|			ISNULL(SettingUpAGrouping.InventoryReplenishmentMethod, 
			|			ISNULL(GeneralSetting.InventoryReplenishmentMethod, 
			|			ISNULL(ConfiguringGroupingOfGeneralSettings.InventoryReplenishmentMethod, NULL)))) IN (
			|					VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax),
			|					VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard),
			|					VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics))
			|		THEN ISNULL(DetailedSetup.Warehouse, 
			|			ISNULL(GroupAffiliation.Warehouse, 
			|			ISNULL(GeneralSetting.Warehouse, 
			|			ISNULL(BelongingToSharedSettingsGroup.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)))))
			|	ELSE ISNULL(ProductionSupplySchemes.Warehouse, &DefaultWarehouse)
			|END";
			
			
			JoinText = "
			|		LEFT JOIN InformationRegister.ProductionSupplySchemes AS ProductionSupplySchemes
			|		ON TableMaterials.Products.SupplyScheme = ProductionSupplySchemes.SupplyScheme
			|			AND TableMaterials.Department = ProductionSupplySchemes.Department
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|		ON &SubstituteGoodsRestriction";
			
			ConnectionFieldsProductRestrictions = 
				"TableMaterials.Products,TableMaterials.Characteristic,TableMaterials.Department";
			
			JoinText = InformationRegisters.ProductRestrictions.SubstituteForMaintainingStocksInPantries(
									JoinText, "SubstituteGoodsRestriction", ConnectionFieldsProductRestrictions);
		
		If FieldNameDivision <> Undefined Then
			If Left(FieldNameDivision, 1) = "&" Then
				JoinText = StrReplace(JoinText, "TableMaterials.Department", FieldNameDivision);
			ElsIf FieldNameDivision <> "Department" Then
				JoinText = StrReplace(JoinText, "TableMaterials.Department", "TableMaterials." + FieldNameDivision);
			EndIf; 
		EndIf;
		
		If NameOfMaterialsTable <> "TableMaterials" Then
			WarehouseTextField  = StrReplace(WarehouseTextField,  "TableMaterials", NameOfMaterialsTable);
			JoinText = StrReplace(JoinText, "TableMaterials", NameOfMaterialsTable);
		EndIf;
		
	EndIf;
	
	RequestTemplates = New Structure;
	RequestTemplates.Insert("WarehouseTextField",     WarehouseTextField);
	RequestTemplates.Insert("JoinText",    JoinText);
	
	Return RequestTemplates;
	
EndFunction

// Generates a request text that initializes a temporary table in the process of obtaining Materials.
// 
// Returns:
//   - String - Query text
//
Function RequestTextTTMethodsOfGettingMaterialsEmpty() Export
	
	QueryText =
		"SELECT
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef)      AS ReferenceOrder,
		|	VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
		|	VALUE(Catalog.Products.EmptyRef)               AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
		|	TRUE                                                       AS WithAssignment
		|INTO TTMethodsOfObtainingMaterials
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Return QueryText;
	
EndFunction

// Generates the request text for getting the Warehouse and supply Options fields
//
// Parameters:
//  NameOfMaterialsTable			 - String - Alias of the "materials" table. The table must contain
//		the Item, Characteristic, and Division fields (optional).
//  NameOfMethodForGettingContentField	 - String - name of the field that contains the receiving method.
//  FieldNameDivision			 - String - name of the field that contains a reference to the division,
//		such as " Stage.Unit".
//  SoftwareFillingOption	 - EnumRef.ProductionSupplyFillingVariants - The option of filling in the security
// 
// Returns:
//  Structure - contains query texts:
//  	* WarehouseTextField - String - text for getting the "Warehouse" field.
//  	* TextFieldSoftwareOption - String - text for getting the "security Options" field.
//  	* JoinText - String - connection text.
//
Function QueryTextSecurityParameters(NameOfMaterialsTable, NameOfMethodForGettingContentField = Undefined, FieldNameDivision = Undefined, SoftwareFillingOption = Undefined)
	
	If SoftwareFillingOption = Enums.ProductionSupplyFillingVariants.DontFill Then
		
		WarehouseTextField              = "FALSE";
		TextFieldSoftwareOption = "VALUE(Enum.SupplyOptions.NotRequired)";
		TextFieldIsSeparate        = "FALSE";
		JoinText             = "";
		
	Else
		
			
			// In version 2.2. 
			// - PF always go through the warehouse
			// - Provision schemes are used to obtain a warehouse
			
			// Warehouse
			#Region WarehouseTextField
			WarehouseTextField =
			"CASE
			|		WHEN MaterialsAndServices.Products = VALUE(Catalog.Products.EmptyRef)
			|				OR CAST(MaterialsAndServices.Products AS Catalog.Products).ItemsType IN (
			|							VALUE(Enum.ItemsTypes.Work_5),
			|							VALUE(Enum.ItemsTypes.OperationService))
			|			THEN VALUE(Catalog.Warehouses.EmptyRef)
			|		WHEN NOT OverridingProvision1.Warehouse IS NULL
			|				AND OverridingProvision1.Warehouse <> UNDEFINED
			|			THEN OverridingProvision1.Warehouse
			|		ELSE &TextOfMaterialsWarehouseField
			|	END";
			#EndRegion
			
			// SupplyOption
			#Region TextFieldSoftwareOption
			
			TextFieldSoftwareOption = 
			"CASE
			|		WHEN MaterialsAndServices.MethodOfReceivingMaterial IN (VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials),
			|															VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)) THEN
			|
			|			VALUE(Enum.SupplyOptions.ToSupply)
			|			
			|		WHEN MaterialsAndServices.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)
			|				AND MaterialsAndServices.WithAssignment THEN
			|
			|			VALUE(Enum.SupplyOptions.ToSupply)
			|
			|		WHEN MaterialsAndServices.Products.AssignedPurchaseSale THEN
			|
			|			VALUE(Enum.SupplyOptions.ToSupply)
			|
			|		WHEN MaterialsAndServices.Products.ItemsType IN (VALUE(Enum.ItemsTypes.Work_5),
			|																VALUE(Enum.ItemsTypes.OperationService)) THEN
			|			
			|			VALUE(Enum.SupplyOptions.NotRequired)
			|
			|		ELSE VALUE(Enum.SupplyOptions.ToSupply)
			|	
			|	END";
			
			#EndRegion
		
			// WithAssignment
			#Region WithAssignment
			
			TextFieldIsSeparate =
			"CASE
			|		WHEN MaterialsAndServices.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) THEN
			|			
			|			FALSE
			|		
			|		WHEN NOT OverridingProvision1.WithAssignment IS NULL
			|			AND OverridingProvision1.WithAssignment <> UNDEFINED THEN
			|
			|			OverridingProvision1.WithAssignment
			|		
			|		WHEN NOT OverridingProvision2.WithAssignment IS NULL
			|			AND OverridingProvision2.WithAssignment <> UNDEFINED THEN
			|
			|			OverridingProvision2.WithAssignment
			|
			|		WHEN MaterialsAndServices.Products.AssignedPurchaseSale THEN
			|
			|			TRUE
			|
			|		WHEN MaterialsAndServices.WithAssignment THEN
			|
			|			TRUE
			|";
			If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
				TextFieldIsSeparate = TextFieldIsSeparate + "
				|
				|		WHEN MaterialsAndServices.MethodOfReceivingMaterial IN (VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials),
				|															VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)) THEN
				|			TRUE
				|		
				|		ELSE FALSE
				|	
				|	END";
			Else
				TextFieldIsSeparate = TextFieldIsSeparate + "
				|		
				|		ELSE FALSE
				|	
				|	END";
			EndIf;
			#EndRegion
		
		RequestTextForGettingWarehouse = RequestTextForContentTransferSettings(
											NameOfMaterialsTable, 
											FieldNameDivision,
											SoftwareFillingOption);
											
		WarehouseTextField = StrReplace(
							WarehouseTextField, 
							"&TextOfMaterialsWarehouseField",
							RequestTextForGettingWarehouse.WarehouseTextField);
		
		
			
			JoinText = RequestTextForGettingWarehouse.JoinText + " 
			|
			|		LEFT JOIN TTMethodsOfObtainingMaterials AS OverridingProvision1
			|		ON OverridingProvision1.Products = MaterialsAndServices.Products
			|			AND OverridingProvision1.Characteristic = MaterialsAndServices.Characteristic
			|			AND OverridingProvision1.ReferenceOrder = &ReferenceOrder
			|
			|		LEFT JOIN TTMethodsOfObtainingMaterials AS OverridingProvision2
			|		ON OverridingProvision2.ReferenceOrder = &ReferenceOrder
			|			AND OverridingProvision2.Products = UNDEFINED
			|			AND OverridingProvision2.Characteristic = UNDEFINED
			|
			|		LEFT JOIN Catalog.BusinessStructure AS CatDepartment
			|		ON CatDepartment.Ref = MaterialsAndServices.Department";
		
		
		If NameOfMethodForGettingContentField <> Undefined 
			And NameOfMethodForGettingContentField <> "MethodOfReceivingMaterial" Then
			
			WarehouseTextField = StrReplace(
				WarehouseTextField,
				"MaterialsAndServices.MethodOfReceivingMaterial",
				"MaterialsAndServices." + NameOfMethodForGettingContentField);
			
			TextFieldSoftwareOption = StrReplace(
				TextFieldSoftwareOption,
				"MaterialsAndServices.MethodOfReceivingMaterial",
				"MaterialsAndServices." + NameOfMethodForGettingContentField);
			
		
		EndIf;
			
		If FieldNameDivision <> Undefined Then 
			
			If Left(FieldNameDivision, 1) = "&" Then
				
				WarehouseTextField = StrReplace(
					WarehouseTextField,
					"MaterialsAndServices.Department",
					FieldNameDivision);
				
				TextFieldSoftwareOption = StrReplace(
					TextFieldSoftwareOption,
					"MaterialsAndServices.Department",
					FieldNameDivision);
					
				TextFieldIsSeparate = StrReplace(
					TextFieldIsSeparate,
					"MaterialsAndServices.Department",
					FieldNameDivision);
					
				JoinText = StrReplace(
					JoinText,
					"MaterialsAndServices.Department",
					FieldNameDivision);
					
			ElsIf FieldNameDivision <> "Department" Then
				
				WarehouseTextField = StrReplace(
					WarehouseTextField,
					"MaterialsAndServices.Department",
					"MaterialsAndServices." + FieldNameDivision);
				
				TextFieldSoftwareOption = StrReplace(
					TextFieldSoftwareOption,
					"MaterialsAndServices.Department",
					"MaterialsAndServices." + FieldNameDivision);
					
				TextFieldIsSeparate = StrReplace(
					TextFieldIsSeparate,
					"MaterialsAndServices.Department",
					"MaterialsAndServices." + FieldNameDivision);
					
				JoinText = StrReplace(
					JoinText,
					"MaterialsAndServices.Department",
					"MaterialsAndServices." + FieldNameDivision);
					
			EndIf;
			
		EndIf;
		
		If NameOfMaterialsTable <> "MaterialsAndServices" Then
			WarehouseTextField              = StrReplace(WarehouseTextField,              "MaterialsAndServices", NameOfMaterialsTable);
			TextFieldSoftwareOption = StrReplace(TextFieldSoftwareOption, "MaterialsAndServices", NameOfMaterialsTable);
			TextFieldIsSeparate        = StrReplace(TextFieldIsSeparate,        "MaterialsAndServices", NameOfMaterialsTable);
			JoinText             = StrReplace(JoinText,             "MaterialsAndServices", NameOfMaterialsTable);
		EndIf;
		
	EndIf;

	RequestTemplates = New Structure();
	RequestTemplates.Insert("WarehouseTextField",              WarehouseTextField);
	RequestTemplates.Insert("TextFieldSoftwareOption", TextFieldSoftwareOption);
	RequestTemplates.Insert("TextFieldIsSeparate",        TextFieldIsSeparate);
	RequestTemplates.Insert("JoinText",             JoinText);

	Return RequestTemplates;
	
EndFunction

Procedure PerformSubstitutionOfMaterialSupportParameters(QueryText,
	TableName,
	NameOfMethodForGettingContentField = Undefined,
	FieldNameDivision = Undefined,
	SoftwareFillingOption = Undefined) Export
	
	TextsSoftwareParameters = QueryTextSecurityParameters(
		TableName,
		NameOfMethodForGettingContentField,
		FieldNameDivision,
		SoftwareFillingOption);
	
	QueryText = StrReplace(
		QueryText,
		",ConnectionTextSoftwareParameters",
		TextsSoftwareParameters.JoinText);
	
	QueryText = StrReplace(
		QueryText,
		"&WarehouseTextField",
		TextsSoftwareParameters.WarehouseTextField);
	
	
	QueryText = StrReplace(
		QueryText,
		"&TextFieldSoftwareOption",
		TextsSoftwareParameters.TextFieldSoftwareOption);
	
	QueryText = StrReplace(
		QueryText,
		"&TextFieldIsSeparate",
		TextsSoftwareParameters.TextFieldIsSeparate);
	
EndProcedure

#EndRegion

#Region Other

Function SoftwareOptionAccordingToProductionVersion(Val UseProduction2_2 = Undefined) Export
	
	If UseProduction2_2 = Undefined Then
		UseProduction2_2 = GetFunctionalOption("UseProductionManagement2_2")
	EndIf;
	
	If UseProduction2_2 Then
		Return Enums.ProductionSupplyFillingVariants.BySupplySchemes;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion
