#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	AdditionalProperties.Insert("BatchAccountingIsEnabled",
		CalculationOfCostCached.BatchAccountingIsEnabled(
			BegOfMonth(AdditionalProperties.RecorderDate)));
	
	If Constants.ControlCompanyStockBalance.Get()
		Or AdditionalProperties.BatchAccountingIsEnabled Then
		
		InventoriesServer.PreserveOriginalRegisteredRecordsOfGoodsAndReserves(Filter.Recorder.Value,
			AdditionalProperties.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not (Constants.ControlCompanyStockBalance.Get()
		Or AdditionalProperties.BatchAccountingIsEnabled) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	QueryText = 
	"SELECT
	|	MIN(NestedQuery.Period) AS Period,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	SUM(NestedQuery.CountUpdate) AS CountUpdate
	|INTO TTMovementGoodsOfOrganizationsChange
	|FROM
	|	(SELECT
	|		ChangesTable.Period AS Period,
	|		ChangesTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ChangesTable.Organization AS Organization,
	|		ChangesTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		ChangesTable.CCDNumber AS CCDNumber,
	|		SUM(ChangesTable.CountUpdate) AS CountUpdate
	|	FROM
	|		(SELECT
	|			ENDOFPERIOD(Table.Period, MONTH) AS Period,
	|			Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|			Table.Organization AS Organization,
	|			Table.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|			Table.CCDNumber AS CCDNumber,
	|			CASE Table.RecordType
	|				WHEN VALUE(AccumulationRecordType.Receipt)
	|					THEN -Table.Count
	|				ELSE Table.Count
	|			END AS CountUpdate
	|		FROM
	|			MovementOfOrganizationsProductsBeforeRecording AS Table
	|		WHERE
	|			&ToControlBalance
	|			AND NOT &ThisIsDataExchange
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ENDOFPERIOD(Table.Period, MONTH),
	|			Table.ItemsLocationAttributes,
	|			Table.Organization,
	|			Table.InventoryOwnerAttribute,
	|			Table.CCDNumber,
	|			CASE Table.RecordType
	|				WHEN VALUE(AccumulationRecordType.Receipt)
	|					THEN Table.Count
	|				ELSE -Table.Count
	|			END
	|		FROM
	|			AccumulationRegister.CompanyGoods AS Table
	|		WHERE
	|			Table.Recorder = &Recorder
	|			AND &ToControlBalance
	|			AND NOT &ThisIsDataExchange) AS ChangesTable
	|	
	|	GROUP BY
	|		ChangesTable.ItemsLocationAttributes,
	|		ChangesTable.Organization,
	|		ChangesTable.InventoryOwnerAttribute,
	|		ChangesTable.CCDNumber,
	|		ChangesTable.Period
	|	
	|	HAVING
	// We check only the reduction of the remainder
	|		SUM(ChangesTable.CountUpdate) < 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Organization,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MovementOfGoodsOfOrganizationsChange.Period AS Period,
	|	MovementOfGoodsOfOrganizationsChange.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MovementOfGoodsOfOrganizationsChange.Organization AS Organization,
	|	MovementOfGoodsOfOrganizationsChange.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	MovementOfGoodsOfOrganizationsChange.CCDNumber AS CCDNumber,
	|	MovementOfGoodsOfOrganizationsChange.CountUpdate AS CountUpdate
	|INTO MovementOfGoodsOfOrganizationsChange
	|FROM
	|	TTMovementGoodsOfOrganizationsChange AS MovementOfGoodsOfOrganizationsChange
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON MovementOfGoodsOfOrganizationsChange.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|WHERE
	|	NOT InventoryLocationAttributeKeys.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|	OR MovementOfGoodsOfOrganizationsChange.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MovementOfGoodsOfOrganizationsChange.ItemsLocationAttributes.Products   AS Products,
	|	MovementOfGoodsOfOrganizationsChange.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	MovementOfGoodsOfOrganizationsChange.ItemsLocationAttributes.Contract        AS Contract,
	|	MovementOfGoodsOfOrganizationsChange.CountUpdate                       AS CountUpdate
	|INTO MovementOfGoodsOfOrganizationsChangeInSummary
	|FROM
	|	TTMovementGoodsOfOrganizationsChange AS MovementOfGoodsOfOrganizationsChange
	|WHERE
	|	&CreatePivotTable
	|	AND MovementOfGoodsOfOrganizationsChange.ItemsLocationAttributes.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(MovementOfGoodsOfOrganizationsChange.Period) AS Period
	|FROM
	|	MovementOfGoodsOfOrganizationsChange AS MovementOfGoodsOfOrganizationsChange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period AS Period,
	|	Table.Recorder AS Recorder,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.Organization AS Organization,
	|	Table.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.VATTaxation AS VATTaxation,
	|	Table.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	Table.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	Table.ShipmentCompany AS ShipmentCompany,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.ExpenseItem AS ExpenseItem,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Primary AS Primary,
	|	SUM(Table.Count) AS CountUpdate
	|INTO ChangesTableCompanyGoods
	|FROM
	|	(SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.Organization AS Organization,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.Count AS Count,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.VATTaxation AS VATTaxation,
	|		Goods.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|		Goods.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		Goods.ShipmentCompany AS ShipmentCompany,
	|		Goods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		Goods.ExpenseItem AS ExpenseItem,
	|		Goods.DimensionOfExpenses AS DimensionOfExpenses,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.Primary AS Primary
	|	FROM
	|		MovementOfOrganizationsProductsBeforeRecording AS Goods
	|	WHERE
	|		&BatchAccountingIsEnabled
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Period,
	|		Goods.Recorder,
	|		Goods.ItemsLocationAttributes,
	|		Goods.Organization,
	|		Goods.InventoryOwnerAttribute,
	|		Goods.CCDNumber,
	|		-Goods.Count,
	|		Goods.BusinessOperation,
	|		Goods.VATTaxation,
	|		Goods.CorItemsLocationAttributes,
	|		Goods.CorInventoryOwnerAttribute,
	|		Goods.ShipmentCompany,
	|		Goods.DocumentSalesOfGoodsAndServices,
	|		Goods.ExpenseItem,
	|		Goods.DimensionOfExpenses,
	|		Goods.Products,
	|		Goods.Characteristic,
	|		Goods.Primary
	|	FROM
	|		AccumulationRegister.CompanyGoods AS Goods
	|	WHERE
	|		Goods.Recorder = &Recorder
	|		AND &BatchAccountingIsEnabled) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.ItemsLocationAttributes,
	|	Table.Organization,
	|	Table.InventoryOwnerAttribute,
	|	Table.CCDNumber,
	|	Table.BusinessOperation,
	|	Table.VATTaxation,
	|	Table.CorItemsLocationAttributes,
	|	Table.CorInventoryOwnerAttribute,
	|	Table.ShipmentCompany,
	|	Table.DocumentSalesOfGoodsAndServices,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Primary
	|
	|HAVING
	|	SUM(Table.Count) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTMovementGoodsOfOrganizationsChange.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|FROM
	|	TTMovementGoodsOfOrganizationsChange AS TTMovementGoodsOfOrganizationsChange
	|WHERE
	|	(TTMovementGoodsOfOrganizationsChange.InventoryOwnerAttribute.Obsolete1
	|			OR TTMovementGoodsOfOrganizationsChange.InventoryOwnerAttribute.IsDuplicate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTMovementGoodsOfOrganizationsChange";

	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("ThisIsDataExchange", DataExchange.Load);
	Query.SetParameter("ToControlBalance", Constants.ControlCompanyStockBalance.Get());
	Query.SetParameter("BatchAccountingIsEnabled", AdditionalProperties.BatchAccountingIsEnabled);
	
	CreatePivotTable = AdditionalProperties.Property("CreateSummaryTableProductsOfOrganizations");
	Query.SetParameter("CreatePivotTable", CreatePivotTable);
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = QueryText;
	
	Result = Query.ExecuteBatch();
	
	MinimumPeriod = Result[3].Select();
	If MinimumPeriod.Next() Then
		MinimumPeriod = MinimumPeriod.Period;
	Else
		MinimumPeriod = Date('00010101');
	EndIf;
	
	Selection = Result[1].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties, "MovementOfGoodsOfOrganizationsChange",
		Selection.Next() And Selection.Count > 0, New Structure("MinimumPeriod", MinimumPeriod));
	
	Selection = Result[2].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"MovementOfGoodsOfOrganizationsChangeInSummary", Selection.Next() And Selection.Count > 0);
	
	OutdatedTypesOfStocksForUpdatingVRSRecords = Result[5].Unload().UnloadColumn("InventoryOwnerAttribute");
	InformationRegisters.ObsoleteInventoryOwnerAttributesWithBalance.UpdateRecords(OutdatedTypesOfStocksForUpdatingVRSRecords);
	
EndProcedure

#EndRegion

#EndIf
