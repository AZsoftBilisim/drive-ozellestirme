
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") Then
		
		ShippingWarehouseIsUsed = Undefined;
		If Parameters.Filter.Property("ShippingWarehouseIsUsed", ShippingWarehouseIsUsed) Then
			
			If Not ShippingWarehouseIsUsed Then
				Parameters.Filter.Delete("OriginWarehouse");
			EndIf;
			Parameters.Filter.Delete("ShippingWarehouseIsUsed");
			
		EndIf;
		
		If Parameters.Filter.Property("OriginWarehouse") Then
			Parameters.Filter.Warehouse = Parameters.Filter.OriginWarehouse;
		EndIf;
		
		If Not ValueIsFilled(Parameters.Filter.Warehouse) Then
			Parameters.Filter.Delete("Warehouse");
		EndIf;
		
		If Parameters.Filter.Property("DocumentSalesOfGoodsAndServices") Then
			If Parameters.Filter.DocumentSalesOfGoodsAndServices = Undefined Then
				Parameters.Filter.Delete("DocumentSalesOfGoodsAndServices");
				BySalesDocument = False;
			Else
				BySalesDocument = True;
			EndIf;
		EndIf;
		
	EndIf;
	If GetFunctionalOption("UseExcisableGoods") 
		And Parameters.ExcisableGoods Then
			DataString1 = Undefined;
			Parameters.Property("CurrentRow", DataString1);
		If ValueIsFilled(DataString1) Then
			SubjectToExcise = Common.ObjectAttributeValue(DataString1, "SubjectToExcise");
		EndIf;
		Items.InstallIsSubjectToExciseDuty.Visible = True;
		Items.InstallIsSubjectToExciseDuty.Check = SubjectToExcise;
	EndIf;
	Items.InventoryKindTableBalance.Visible = Not BySalesDocument;
	Items.InventoryKindTableSold.Visible = BySalesDocument;
	
	FillInTableOfStockTypes();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventoryKindTable

&AtClient
Procedure InventoryKindTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Item.CurrentData;
	
	If TableRow <> Undefined Then
		NotifyChoice(TableRow.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure ExecuteSelection(Command)
	
	Close(DialogReturnCode.OK);
	
	TableRow = Items.InventoryKindTable.CurrentData;
	
	If TableRow <> Undefined Then
		NotifyChoice(TableRow.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillInTableOfStockTypes();
	
EndProcedure

&AtClient
Procedure SetSelectionByBalances(Command)
	
	NoBalance = Not NoBalance;
	Items.SetSelectionByBalances.Check = NoBalance;
	FillInTableOfStockTypes();
	
EndProcedure

&AtClient
Procedure InstallIsSubjectToExciseDuty(Command)
	
	SubjectToExcise = Not SubjectToExcise;
	Items.InstallIsSubjectToExciseDuty.Check = SubjectToExcise;
	FillInTableOfStockTypes();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure FillInTableOfStockTypes()
	
	Query = New Query();
	QueryText = 
	"SELECT
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.DeletionMark AS DeletionMark,
	|	InventoryKinds.Predefined AS Predefined,
	|	InventoryKinds.Description AS Description,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	InventoryKinds.GoodsOwner AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.Organization AS Organization,
	|	ISNULL(InventoryKinds.SubjectToExcise, FALSE) AS SubjectToExcise,
	|	CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation AS Warehouse
	|INTO TTTypesOfStocks
	|FROM
	|	AccumulationRegister.CompanyGoods.BalanceAndTurnovers(&PointInTime, &PointInTime, Period, , ) AS CompanyGoods
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON (InventoryKinds.Ref = CompanyGoods.InventoryOwnerAttribute)
	|
	|WHERE &TTTermsAndTypesOfStocks
	|
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SoldGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	SoldGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SoldGoods.Recorder AS DocumentSalesOfGoodsAndServices,
	|	ISNULL(SoldGoods.CountExpense, 0) AS Sold
	|INTO TTGoodsSold
	|FROM
	|	AccumulationRegister.CompanyGoods.Turnovers(
	|			,
	|			,
	|			Recorder,
	|			&BySalesDocument
	|				AND (InventoryOwnerAttribute, ItemsLocationAttributes) IN
	|					(SELECT
	|						Table.Ref AS InventoryOwnerAttribute,
	|						Table.ItemsLocationAttributes
	|					FROM
	|						TTTypesOfStocks AS Table)) AS SoldGoods
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfBalances.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TemporaryTableOfBalances.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	SUM(TemporaryTableOfBalances.Balance)				AS Balance
	|INTO TTBalance
	|FROM
	|	(SELECT
	|		BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		BalanceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		BalanceTable.CountBalance			AS Balance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|			,
	|			(InventoryOwnerAttribute, ItemsLocationAttributes) IN
	|				(SELECT DISTINCT
	|					InventoryTable.Ref AS InventoryOwnerAttribute,
	|					InventoryTable.ItemsLocationAttributes AS ItemsLocationAttributes
	|				FROM
	|					TTTypesOfStocks AS InventoryTable)) AS BalanceTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		BalanceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		CASE
	|			WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -BalanceTable.Count
	|			ELSE BalanceTable.Count
	|		END										AS Balance
	|	FROM
	|		AccumulationRegister.CompanyGoods AS BalanceTable
	|	WHERE
	|		BalanceTable.Active
	|		AND BalanceTable.Recorder = &Recorder
	|		AND (BalanceTable.InventoryOwnerAttribute, BalanceTable.ItemsLocationAttributes) IN
	|			(SELECT DISTINCT
	|				InventoryTable.Ref AS InventoryOwnerAttribute,
	|				InventoryTable.ItemsLocationAttributes AS ItemsLocationAttributes
	|			FROM
	|				TTTypesOfStocks AS InventoryTable)
	|	
	|	) AS TemporaryTableOfBalances
	|
	|GROUP BY
	|	TemporaryTableOfBalances.InventoryOwnerAttribute,
	|	TemporaryTableOfBalances.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(TemporaryTableOfBalances.Balance) > 0
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.DeletionMark AS DeletionMark,
	|	InventoryKinds.Predefined AS Predefined,
	|	InventoryKinds.Description AS Description,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	InventoryKinds.GoodsOwner AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.Products AS Products,
	|	InventoryKinds.Characteristic AS Characteristic,
	|	InventoryKinds.Series AS Series,
	|	InventoryKinds.Warehouse AS Warehouse,
	|	SoldGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	ISNULL(BalanceTable.Balance, 0) AS Balance,
	|	ISNULL(SoldGoods.Sold, 0) AS Sold,
	|	ISNULL(CatalogProducts.UnitOfMeasure, UNDEFINED) AS UnitOfMeasure
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON InventoryKinds.Products = CatalogProducts.Ref
	|		LEFT JOIN TTGoodsSold AS SoldGoods
	|		ON InventoryKinds.Ref = SoldGoods.InventoryOwnerAttribute
	|			AND InventoryKinds.ItemsLocationAttributes = SoldGoods.ItemsLocationAttributes
	|		LEFT JOIN TTBalance AS BalanceTable
	|		ON InventoryKinds.Ref = BalanceTable.InventoryOwnerAttribute
	|			AND InventoryKinds.ItemsLocationAttributes = BalanceTable.ItemsLocationAttributes
	|WHERE
	|	NOT InventoryKinds.SaleOfAnotherCompanyInventory
	|	AND NOT InventoryKinds.DeletionMark
	|	AND InventoryKinds.SubjectToExcise = &SubjectToExcise
	|	AND (&BySalesDocument
	|		OR NOT BalanceTable.Balance IS NULL)
	|	AND NOT &NoBalance
	|	AND &ConditionsSampleTable
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.DeletionMark AS DeletionMark,
	|	InventoryKinds.Predefined AS Predefined,
	|	InventoryKinds.Description AS Description,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	InventoryKinds.GoodsOwner AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.Organization AS Organization,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS Characteristic,
	|	UNDEFINED AS Series,
	|	UNDEFINED AS Warehouse,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	0 AS Balance,
	|	0 AS Sold,
	|	UNDEFINED AS UnitOfMeasure
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	NOT InventoryKinds.DeletionMark
	|	AND InventoryKinds.SubjectToExcise = &SubjectToExcise
	|	AND &NoBalance
	|	AND InventoryKinds.Organization = &Organization
	|	AND NOT InventoryKinds.Ref IN (SELECT TTBalance.InventoryOwnerAttribute FROM TTBalance)
	|	AND &ConditionsSampleTable";
	
	QueryOptions = New Structure();
	QueryOptions.Insert("Products",          Catalogs.Products.EmptyRef());
	QueryOptions.Insert("Characteristic",        Catalogs.ItemsCharacteristics.EmptyRef());
	QueryOptions.Insert("Series",                 Catalogs.ItemsBatches.EmptyRef());
	QueryOptions.Insert("Warehouse",                 Catalogs.Warehouses.EmptyRef());
	QueryOptions.Insert("Organization",           Catalogs.Companies.EmptyRef());
	QueryOptions.Insert("BySalesDocument", False);
	QueryOptions.Insert("DocumentSalesOfGoodsAndServices",    Undefined);
	QueryOptions.Insert("PointInTime",         Date(1, 1, 1));
	QueryOptions.Insert("Recorder",           Undefined);
	QueryOptions.Insert("SubjectToExcise",     SubjectToExcise);
	QueryOptions.Insert("NoBalance",           NoBalance);
	
	TermsOfRequestTTTypesOfInventory = New Structure();
	TermsOfRequestTTTypesOfInventory.Insert("Products",   "CompanyGoods.ItemsLocationAttributes.Products = &Products");
	TermsOfRequestTTTypesOfInventory.Insert("Characteristic", "CompanyGoods.ItemsLocationAttributes.Characteristic = &Characteristic");
	TermsOfRequestTTTypesOfInventory.Insert("Series",          "CompanyGoods.ItemsLocationAttributes.Series = &Series");
	TermsOfRequestTTTypesOfInventory.Insert("Warehouse",          "CompanyGoods.ItemsLocationAttributes.StorageLocation = &Warehouse");
	TermsOfRequestTTTypesOfInventory.Insert("Organization",    "InventoryKinds.Organization = &Organization");
	
	QueryConditionsSelectionTable = New Structure();
	QueryConditionsSelectionTable.Insert("DocumentSalesOfGoodsAndServices", "SoldGoods.DocumentSalesOfGoodsAndServices = &DocumentSalesOfGoodsAndServices");
	
	For Each QueryParameter In QueryOptions Do
		If Parameters.Filter.Property(QueryParameter.Key)
			And ValueIsFilled(Parameters.Filter[QueryParameter.Key]) Then
				
			QueryOptions[QueryParameter.Key] = Parameters.Filter[QueryParameter.Key];
			
		EndIf;
	EndDo;
	
	If Parameters.Filter.Property("ShippingWarehouseIsUsed")
		And Parameters.Filter.ShippingWarehouseIsUsed
		And Parameters.Filter.Property("OriginWarehouse")
		And ValueIsFilled(Parameters.Filter.OriginWarehouse) Then
		QueryOptions.Warehouse = Parameters.Filter.OriginWarehouse;
	EndIf;
	
	If ValueIsFilled(QueryOptions.DocumentSalesOfGoodsAndServices) Then
		QueryOptions.PointInTime = QueryOptions.DocumentSalesOfGoodsAndServices.PointInTime();
	EndIf;
	
	If Parameters.Filter.Property("DocumentSalesOfGoodsAndServices")
		And ValueIsFilled(Parameters.Filter.DocumentSalesOfGoodsAndServices) Then
		QueryOptions.BySalesDocument = True;
	EndIf;
	
	ArrayOfTTConditionsTypesOfInventory = New Array();
	ArrayOfConditionsTableSelection = New Array();
	
	For Each QueryParameter In QueryOptions Do
		
		If TermsOfRequestTTTypesOfInventory.Property(QueryParameter.Key)
			And ValueIsFilled(QueryParameter.Value) Then
			ArrayOfTTConditionsTypesOfInventory.Add(TermsOfRequestTTTypesOfInventory[QueryParameter.Key]);
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		ElsIf QueryConditionsSelectionTable.Property(QueryParameter.Key)
			And ValueIsFilled(QueryParameter.Value) Then
			ArrayOfConditionsTableSelection.Add(QueryConditionsSelectionTable[QueryParameter.Key]);
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		Else
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndIf;
		
	EndDo;
	
	TTTermsAndConditionsTypesOfInventory  = StrConcat(ArrayOfTTConditionsTypesOfInventory, " And ");
	ConditionTextSelectionTable = StrConcat(ArrayOfConditionsTableSelection, " And ");
	
	If TTTermsAndConditionsTypesOfInventory = "" Then
		QueryText = StrReplace(QueryText, "WHERE &TTTermsAndTypesOfStocks", "");
	Else	
		QueryText = StrReplace(QueryText, "WHERE &TTTermsAndTypesOfStocks", "WHERE " + TTTermsAndConditionsTypesOfInventory);
	EndIf;
	
	If ConditionTextSelectionTable = "" Then
		QueryText = StrReplace(QueryText, "AND &ConditionsSampleTable", "");
	Else	
		QueryText = StrReplace(QueryText, "AND &ConditionsSampleTable", "And " + ConditionTextSelectionTable);
	EndIf;
	
	Query.Text = QueryText;
	
	Result = Query.Execute().Unload();
	
	InventoryKindTable.Load(Result);
	
EndProcedure

#EndRegion

#EndRegion
