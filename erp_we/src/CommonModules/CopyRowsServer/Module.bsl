
#Region Public

// Places data to the clipboard
//
// Parameters:
//   SelectedRows - Array - Array of IDs of selected rows
//   TabPart -TabularSection - The table part of the object with the copied lines.
//   ColumnsNames -Structure - contains a description of matching column names, if required.
//
Procedure PlaceSelectedLinesOnClipboard(SelectedRows, TabPart, ColumnsNames = Undefined) Export
	ClipboardTable = InitializeClipboardTable();
	
	HighlightedTSLines = New Array;
	If SelectedRows <> Undefined Then
		
		For Each CurRow In SelectedRows Do
			TableRow = TabPart.FindByID(CurRow);
			HighlightedTSLines.Add(TableRow);
		EndDo;
		
		SetsServerCall.AddToFullSet(TabPart, HighlightedTSLines);
		
	EndIf;
	
	If ValueIsFilled(HighlightedTSLines) Then
		
		CopiedCollection = HighlightedTSLines;
		
	Else
		
		CopiedCollection = TabPart;
		
	EndIf;
	
	For Each TableRow In CopiedCollection Do
		
		NewRow = ClipboardTable.Add();
		FillPropertyValues(NewRow, TableRow);
		
		If ColumnsNames <> Undefined Then
			
			For Each KeyAndValue In ColumnsNames Do
				NewRow[KeyAndValue.Value] = TableRow[KeyAndValue.Key]
			EndDo
			
		EndIf;
		
	EndDo;
	
	CopyTableToClipboard(ClipboardTable, "Rows");
	
EndProcedure 

// Retrieves data from the clipboard.
//
// Parameters:
//   FilterParameters - Structure - Parameters for selecting rows.
//
// Returns:
//   ValueTable - Lines received from the clipboard.
//
Function GetLinesFromClipboard(FilterParameters = Undefined) Export
	
	DataFromClipboard = Common.RowsFromClipboard();
	If DataFromClipboard.Source = "Rows" Then
		LinesToInsert = DataFromClipboard.Data;
	Else
		Return New ValueTable;
	EndIf;
	
	If ValueIsFilled(FilterParameters) Then
		
		Query = New Query(
		"SELECT
		|	VT.ProductCategory,
		|	VT.SalesRank,
		|	VT.ProductsInSet,
		|	VT.Products,
		|	VT.ItemsType,
		|	VT.ItemVariantOfSet,
		|	VT.Characteristic,
		|	VT.Content,
		|	VT.Package,
		|	VT.NumberOfPackages,
		|	VT.Count,
		|	VT.OperationCategory,
		|	VT.Individual,
		|	VT.ExpenseItem,
		|	VT.DimensionOfExpenses,
		|	VT.AssetsLiabilitiesDimension,
		|	VT.Price,
		|	VT.PercentRateOfManualDiscount,
		|	VT.Warehouse,
		|	VT.Partner,
		|	VT.Terms,
		|	VT.Sum,
		|	VT.ManualDiscount,
		|	VT.CostDefiningMethod,
		|	VT.DocumentSalesOfGoodsAndServices,
		|	VT.Cost_,
		|	VT.CostExcludingVAT_,
		|	VT.CostLocal,
		|	VT.CDCost,
		|	VT.TDCost,
		|	VT.CostPriceKind,
		|	VT.DateOfCostFillingByPriceType,
		|	VT.ProductKit,
		|	VT.DateOfReceipt,
		|	VT.BalanceDate,
		|	VT.DateOfShipment,
		|	VT.DateOfAssemblyDisassembly
		|	,VT.WorkKind
		|	,VT.ProductCostElement
		|	,VT.Purpose
		|	,VT.BillOfMaterials
		|	,VT.Sender
		|	,VT.Department
		|	,VT.StorageLocation
		|	,VT.DirectionOfProductionIssue
		|	,VT.Recipient
		|	,VT.Performer
		|	,VT.Contract
		|	,VT.Custodian
		|	,VT.Counterparty
		|	,VT.StartDate2
		|	,VT.DateOfProduction
		|	,VT.ReleaseDateOfProductsOrSemiFinishedProduct
		|	,VT.SemiFinishedProduct
		|	,VT.DocumentTransfers_
		|	,VT.ThereAreSubstituteMaterials
		|INTO T
		|FROM
		|	&VT AS VT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE 
		|		WHEN T.Products <> VALUE(Catalog.Products.EmptyRef) 
		|		THEN T.Products.ProductCategory 
		|		ELSE T.ProductCategory 
		|	END AS ProductCategory,
		|	CASE 
		|		WHEN T.Products <> VALUE(Catalog.Products.EmptyRef) 
		|		THEN T.Products.SalesRank 
		|		ELSE T.SalesRank 
		|	END AS SalesRank,
		|	T.ProductsInSet,
		|	T.Products,
		|	T.Products.ItemsType AS ItemsType,
		|	T.ItemVariantOfSet,
		|	T.Characteristic,
		|	T.Content,
		|	T.Package,
		|	T.NumberOfPackages,
		|	T.Count,
		|	T.OperationCategory,
		|	T.Individual,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.AssetsLiabilitiesDimension,
		|	T.Price,
		|	T.PercentRateOfManualDiscount,
		|	T.Warehouse,
		|	T.Partner,
		|	T.Terms,
		|	T.Sum,
		|	T.ManualDiscount,
		|	T.CostDefiningMethod,
		|	T.DocumentSalesOfGoodsAndServices,
		|	T.Cost_,
		|	T.CostExcludingVAT_,
		|	T.CostLocal,
		|	T.CDCost,
		|	T.TDCost,
		|	T.CostPriceKind,
		|	T.DateOfCostFillingByPriceType,
		|	T.ProductKit,
		|	T.DateOfReceipt,
		|	T.BalanceDate,
		|	T.DateOfShipment,
		|	T.DateOfAssemblyDisassembly
		|	,T.WorkKind
		|	,T.ProductCostElement
		|	,T.Purpose
		|	,T.BillOfMaterials
		|	,T.Sender
		|	,T.Department
		|	,T.StorageLocation
		|	,T.DirectionOfProductionIssue
		|	,T.Recipient
		|	,T.Performer
		|	,T.Contract
		|	,T.Custodian
		|	,T.Counterparty
		|	,T.StartDate2
		|	,T.DateOfProduction
		|	,T.ReleaseDateOfProductsOrSemiFinishedProduct
		|	,T.SemiFinishedProduct
		|	,T.DocumentTransfers_
		|	,T.ThereAreSubstituteMaterials
		|FROM
		|	T AS T
		|WHERE
		|	TRUE
		|	AND &ConditionText");
		
		Query.SetParameter("VT", LinesToInsert);
		TextOfSelectionCondition = "";
		
		If FilterParameters.Property("FilterByProductType") Then
			TextOfSelectionCondition = "AND T.Products.ItemsType IN (&FilterByProductType)";
			Query.SetParameter("FilterByProductType", FilterParameters.FilterByProductType);
		EndIf;
		
		Query.Text = StrReplace(Query.Text,"AND &ConditionText", TextOfSelectionCondition);
		
		LinesToInsert = Query.Execute().Unload();
		
	EndIf;
	
	Return LinesToInsert
EndFunction 

// Places data to the clipboard.
//
// Parameters:
//   BudgetCells - Array - an array with the copied cells.
//
Procedure PlaceSelectedBudgetCellsOnClipboard(BudgetCells) Export
	CopyTableToClipboard(BudgetCells, "BudgetCells");
EndProcedure 

// Retrieves data from the clipboard.
//
// Returns:
//   Array - an array with inserted cells.
//
Function GetBudgetCellsFromClipboard() Export
	
	DataFromClipboard = Common.RowsFromClipboard();
	
	If DataFromClipboard = Undefined Then
		Return New Array;
	EndIf;
	
	If DataFromClipboard.Source <> "BudgetCells" Then
		Return New Array;
	EndIf;
	
	Return DataFromClipboard.Data;
	
EndFunction

#EndRegion

#Region Private

// Returns:
// 	ValueTable:
// * ProductCategory - CatalogRef.ProductCategories
// * SalesRank - CatalogRef.SalesRanks
// * ProductsInSet - CatalogRef.Products
// * Products - CatalogRef.Products
// * PackingList - DocumentRef.PackingList
// * ItemsType - EnumRef.ItemsTypes
// * Characteristic - CatalogRef.ItemsCharacteristics
// * ItemVariantOfSet - CatalogRef.ItemsCharacteristics
// * Content - String -
// * Package - CatalogRef.PackagesAndUnitsOfMeasure
// * NumberOfPackages - Number
// * Count - Number
// * Price - Number
// * PercentRateOfManualDiscount - Number
// * ManualDiscount - Number
// * LineOfBusiness - CatalogRef.LinesOfBusiness
// * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems, ChartOfCharacteristicTypesRef.AssetLiabilityItems -
// * DimensionOfExpenses - ChartOfCharacteristicTypesRef.ExpenseItems
// * AssetsLiabilitiesDimension - ChartOfCharacteristicTypesRef.AssetLiabilityItems
// * Individual - CatalogRef.Persons
// * ExpenseAmount - Number
// * DateRecord - Date
// * IncomeItem - ChartOfCharacteristicTypesRef.IncomeItems
// * IncomeAmount - Number
// * Sum - Number
// * AmountExcludingVAT - Number
// * SumCompl - Number
// * AmountPermanentDifferences - Number
// * AmountTemporaryDifferences - Number
// * CostDefiningMethod - EnumRef.WaysToCalculateReturnCost
// * DocumentSalesOfGoodsAndServices - DocumentRef 
// * Cost_ - Number
// * CostExcludingVAT_ - Number
// * CostLocal - Number
// * CDCost - Number
// * TDCost - Number
// * CostPriceKind - CatalogRef.TypesOfPrices
// * DateOfCostFillingByPriceType - Date
// * Warehouse - CatalogRef.Warehouses
// * Partner - CatalogRef.Partners
// * Terms - CatalogRef.TermsOfPurchaseFromVendors, CatalogRef.TermsOfSale - 
// * ProductKit - CatalogRef.ProductKitConfigurations
// * DateOfReceipt - Date
// * BalanceDate - Date
// * DateOfShipment - Date
// * DateOfAssemblyDisassembly - Date
// * DocumentTransfers_ - DocumentRef 
// * WorkKind - CatalogRef.EmployeeWorkKinds
// * ProductCostElement - CatalogRef.ProductCostElements
// * Purpose - CatalogRef.Assignments
// * BillOfMaterials - CatalogRef.BillsOfMaterials
// * StorageLocation - EnumRef.StorageLocationTypes -
// * Department - CatalogRef.BusinessStructure
// * Contract - CatalogRef.CounterpartyContracts
// * Custodian - CatalogRef.Partners
// * Counterparty - CatalogRef.Counterparties
// * Sender - CatalogRef.BusinessStructure, CatalogRef.Warehouses - 
// * DirectionOfProductionIssue - EnumRef.BusinessTransactions
// * Recipient - ChartOfCharacteristicTypesRef.ExpenseItems, CatalogRef.BusinessStructure, ChartOfCharacteristicTypesRef.AssetLiabilityItems, CatalogRef.Warehouses -
// * Performer - CatalogRef.Teams, CatalogRef.Persons - 
// * StartDate2 - Date
// * DateOfProduction - Date
// * ReleaseDateOfProductsOrSemiFinishedProduct - Date
// * SemiFinishedProduct - Boolean
// * ThereAreSubstituteMaterials - Boolean
Function InitializeClipboardTable()
	
	TableOfRows = New ValueTable();
	DescriptionOfMoneyFieldTypes = TMCommonUse.MoneyFieldTypeDescription();
	TypesDetailsNumber15_3 = TMCommonUse.GetDescriptionOfNumberTypes(15,3);
	TableOfRows.Columns.Add("ProductCategory", New TypeDescription("CatalogRef.ProductCategories"));
	TableOfRows.Columns.Add("SalesRank", New TypeDescription("CatalogRef.SalesRanks"));
	TableOfRows.Columns.Add("ProductsInSet", New TypeDescription("CatalogRef.Products"));
	TableOfRows.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfRows.Columns.Add("PackingList", New TypeDescription("DocumentRef.PackingList"));
	TableOfRows.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	TableOfRows.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfRows.Columns.Add("ItemVariantOfSet", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfRows.Columns.Add("Content", New TypeDescription("String"));
	TableOfRows.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfRows.Columns.Add("NumberOfPackages", TypesDetailsNumber15_3);
	TableOfRows.Columns.Add("Count", TypesDetailsNumber15_3);
	TableOfRows.Columns.Add("Price", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("PercentRateOfManualDiscount", TMCommonUse.GetDescriptionOfNumberTypes(5,2));
	TableOfRows.Columns.Add("ManualDiscount", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	TableOfRows.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems,
																	|ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	TableOfRows.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
	TableOfRows.Columns.Add("AssetsLiabilitiesDimension", Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type);
	TableOfRows.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	TableOfRows.Columns.Add("ExpenseAmount", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("DateRecord", New TypeDescription("Date"));
	TableOfRows.Columns.Add("IncomeItem", New TypeDescription("ChartOfCharacteristicTypesRef.IncomeItems"));
	TableOfRows.Columns.Add("IncomeAmount", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("Sum", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("AmountExcludingVAT", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("SumCompl", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("AmountPermanentDifferences", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("AmountTemporaryDifferences", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("CostDefiningMethod", New TypeDescription("EnumRef.WaysToCalculateReturnCost"));
	TableOfRows.Columns.Add("DocumentSalesOfGoodsAndServices", Documents.AllRefsType());
	TableOfRows.Columns.Add("Cost_", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("CostExcludingVAT_", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("CostLocal", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("CDCost", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("TDCost", DescriptionOfMoneyFieldTypes);
	TableOfRows.Columns.Add("CostPriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfRows.Columns.Add("DateOfCostFillingByPriceType", New TypeDescription("Date"));
	TableOfRows.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfRows.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
	TableOfRows.Columns.Add("Terms", New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors,
																	|CatalogRef.TermsOfSale"));
	TableOfRows.Columns.Add("ProductKit", New TypeDescription("CatalogRef.ProductKitConfigurations"));
	
	TableOfRows.Columns.Add("DateOfReceipt", New TypeDescription("Date"));
	TableOfRows.Columns.Add("BalanceDate", New TypeDescription("Date"));
	TableOfRows.Columns.Add("DateOfShipment", New TypeDescription("Date"));
	TableOfRows.Columns.Add("DateOfAssemblyDisassembly", New TypeDescription("Date"));
	TableOfRows.Columns.Add("DocumentTransfers_", Documents.AllRefsType());
	TableOfRows.Columns.Add("WorkKind", New TypeDescription("CatalogRef.EmployeeWorkKinds"));
	TableOfRows.Columns.Add("ProductCostElement", New TypeDescription("CatalogRef.ProductCostElements"));
	TableOfRows.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableOfRows.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	TableOfRows.Columns.Add("StorageLocation", New TypeDescription("EnumRef.StorageLocationTypes"));
	TableOfRows.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	TableOfRows.Columns.Add("Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
	TableOfRows.Columns.Add("Custodian", New TypeDescription("CatalogRef.Partners"));
	TableOfRows.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	TableOfRows.Columns.Add("Sender", New TypeDescription("CatalogRef.BusinessStructure,
																	|CatalogRef.Warehouses"));
	TableOfRows.Columns.Add("DirectionOfProductionIssue", New TypeDescription("EnumRef.BusinessTransactions"));
	TableOfRows.Columns.Add("Recipient", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems,
																	|CatalogRef.BusinessStructure,
																	|ChartOfCharacteristicTypesRef.AssetLiabilityItems,
																	|CatalogRef.Warehouses"));
	TableOfRows.Columns.Add("Performer", New TypeDescription("CatalogRef.Teams,
																	|CatalogRef.Persons"));
	
	TableOfRows.Columns.Add("StartDate2", New TypeDescription("Date"));
	TableOfRows.Columns.Add("DateOfProduction", New TypeDescription("Date"));
	TableOfRows.Columns.Add("ReleaseDateOfProductsOrSemiFinishedProduct", New TypeDescription("Date"));
	TableOfRows.Columns.Add("SemiFinishedProduct", New TypeDescription("Boolean"));
	TableOfRows.Columns.Add("ThereAreSubstituteMaterials", New TypeDescription("Boolean"));	
	CopyRowsLocalizationServer.InitializeClipboardTable(TableOfRows);
	
	Return TableOfRows;
	
EndFunction 

Procedure CopyTableToClipboard(Table, Source = Undefined)
	CurrentClipboard = SessionParameters.Clipboard;
	
	If ValueIsFilled(CurrentClipboard.Data) Then
		Address = CurrentClipboard.Data;
	Else
		Address = New UUID;
	EndIf;
	
	DataToStorage = PutToTempStorage(Table, Address);
	
	ClipboardStructure = New Structure;
	ClipboardStructure.Insert("Source", Source);
	ClipboardStructure.Insert("Data", DataToStorage);
	
	SessionParameters.Clipboard = New FixedStructure(ClipboardStructure);
	
EndProcedure

#EndRegion