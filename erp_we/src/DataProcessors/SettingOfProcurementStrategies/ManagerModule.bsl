#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure LoadFormatTree(Tree, SupplyScheme, Products, Characteristic, WarehousesToUpgrade, FormatsToUpdate) Export
	
	IsUpdate = WarehousesToUpgrade <> Undefined Or FormatsToUpdate <> Undefined;
	
	Query = New Query();
	Query.Text =
		"SELECT ALLOWED
		|	ISNULL(CatFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)) AS Format,
		|	CatWarehouses.Ref          AS Warehouse,
		|	
		|	ISNULL(CatMethod.Ref, VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS SupplyMethod,
		|	
		|	ISNULL(CatMethod.OrderFulfillmentPeriod, 0)    AS DeliveryPeriodDays,
		|	ISNULL(CatMethod.CoveredPeriod, 0)    AS CoveredPeriod,
		|	ISNULL(CatMethod.CoveredPeriodOption, VALUE(Enum.CoveredPeriodOptions.EmptyRef)) AS CoveredPeriodOption,
		|	ISNULL(CatMethod.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef)) AS SupplyType,
		|	ISNULL(CatMethod.SourceOfDemandSupply, UNDEFINED)                  AS SupplySource,
		|	
		|	ISNULL(CatFormatMethod.Ref, VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS MethodOfProvidingFormat,
		|	
		|	ISNULL(CatFormatMethod.OrderFulfillmentPeriod, 0)   AS FormatDeliveryTime,
		|	ISNULL(CatFormatMethod.CoveredPeriod, 0)   AS ProvidedFormatPeriod,
		|	ISNULL(CatFormatMethod.CoveredPeriodOption, VALUE(Enum.CoveredPeriodOptions.EmptyRef)) AS VariantOfProvidedFormatPeriod,
		|	ISNULL(CatFormatMethod.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef)) AS TypeOfFormatSupport,
		|	ISNULL(CatFormatMethod.SourceOfDemandSupply, UNDEFINED)                  AS SourceOfFormatAssurance,
		|
		|	ISNULL(PackingTable.OrderPackage, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS OrderPackage,
		|	
		|	NOT CatFormats.StoreFormat IS NULL AS ThereIsFormat,
		|	NOT &Products = VALUE(Catalog.Products.EmptyRef) AS ThereAreGoods,
		|	NOT SetupForTheItem.ProcurementStrategy IS NULL ThereIsSettingForGoods,
		|	NOT SettingUpForAWarehouse.ProcurementStrategy IS NULL ThereIsASettingForWarehouse,
		|	NOT SettingForTheFormat.ProcurementStrategy IS NULL ThereIsASettingForFormat,
		|	ISNULL(SettingUpForAWarehouse.ProcurementStrategy,
		|		ISNULL(SettingForTheFormat.ProcurementStrategy,
		|			VALUE(Catalog.ProcurementStrategies.EmptyRef))) AS InheritedSupplyMethod,
		|
		|	CASE WHEN ISNULL(CatFormats.StoreFormat.DeletionMark, FALSE) THEN 1 ELSE 0 END AS FormatIndexImages,
		|	CASE WHEN CatWarehouses.DeletionMark THEN 4 ELSE 3 END AS StandardPicture
		|FROM
		|	Catalog.Warehouses AS CatWarehouses
		|		LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(, ) AS CatFormats
		|		ON CatFormats.Warehouse = CatWarehouses.Ref
		|
		|		LEFT JOIN InformationRegister.GoodsProcurementStrategy AS SetupForTheItem
		|		ON SetupForTheItem.Products  = &Products
		|		 AND SetupForTheItem.Characteristic = &Characteristic
		|		 AND SetupForTheItem.Warehouse          = CatWarehouses.Ref
		|		 AND SetupForTheItem.AddlOrderingAttribute = 1
		|		
		|		LEFT JOIN InformationRegister.SupplySchemes AS SettingUpForAWarehouse
		|		ON SettingUpForAWarehouse.Warehouse = CatWarehouses.Ref
		|		 AND SettingUpForAWarehouse.SupplyScheme = &SupplyScheme
		|		
		|		LEFT JOIN InformationRegister.SupplySchemes AS SettingForTheFormat
		|		ON SettingForTheFormat.Warehouse = CatFormats.StoreFormat
		|		 AND SettingForTheFormat.SupplyScheme = &SupplyScheme
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS CatMethod
		|		ON CatMethod.Ref = ISNULL(SetupForTheItem.ProcurementStrategy, ISNULL(SettingUpForAWarehouse.ProcurementStrategy, SettingForTheFormat.ProcurementStrategy))
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS CatFormatMethod
		|		ON CatFormatMethod.Ref = SettingForTheFormat.ProcurementStrategy
		|
		|		LEFT JOIN InformationRegister.ProductRestrictions AS PackingTable
		|		ON (PackingTable.Products = &Products)
		|		 AND (PackingTable.Characteristic = &Characteristic)
		|		 AND (PackingTable.Warehouse = CatWarehouses.Ref)
		|WHERE
		|	NOT CatWarehouses.IsFolder
		|	AND &FilterByWarehouses
		|	AND &SelectionByFormat
		|ORDER BY
		|	CatFormats.StoreFormat,
		|	Warehouse";
		
	If ValueIsFilled(WarehousesToUpgrade) Then
		Query.Text = StrReplace(Query.Text, "&FilterByWarehouses", "CatWarehouses.Ref IN (&Warehouses)");
		Query.SetParameter("Warehouses", WarehousesToUpgrade);
	Else
		Query.Text = StrReplace(Query.Text, "&FilterByWarehouses", "True");
	EndIf;
	If ValueIsFilled(FormatsToUpdate) Then
		Query.Text = StrReplace(Query.Text, "&SelectionByFormat", "CatFormats.StoreFormat IN (&Formats)");
		Query.SetParameter("Formats", FormatsToUpdate);
	Else
		Query.Text = StrReplace(Query.Text, "&SelectionByFormat", "True");
	EndIf;
	
	Query.SetParameter("SupplyScheme",	SupplyScheme);
	Query.SetParameter("Products",		Products);
	Query.SetParameter("Characteristic",		Characteristic);
	Selection = Query.Execute().Select();
	
	If IsUpdate Then
		
		Format = Undefined;
		FormatBranch = Undefined;
		
		Root = Tree.GetItems();
		While Selection.Next() Do
			
			If Format <> Selection.Format Then
				Format = Selection.Format;
				FormatBranch = Undefined;
				For Each RootBranch In Root Do
					If Format = RootBranch.WarehouseFormat
						Or (Not ValueIsFilled(Format) And Not ValueIsFilled(RootBranch.WarehouseFormat)) Then
						FormatBranch = RootBranch;
						FormatBranch.StandardPicture = Selection.FormatIndexImages;
						FormatBranch.SupplyType = Selection.TypeOfFormatSupport;
						FormatBranch.SupplyMethod = Selection.MethodOfProvidingFormat;
						FormatBranch.DeliveryPeriodDays = Selection.FormatDeliveryTime;
						FormatBranch.CoveredPeriod = Selection.ProvidedFormatPeriod;
						FormatBranch.CoveredPeriodOption = Selection.VariantOfProvidedFormatPeriod;
						FormatBranch.SupplySource = Selection.SourceOfFormatAssurance;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If FormatBranch <> Undefined Then
				BranchNodes = FormatBranch.GetItems();
				For Each Node In BranchNodes Do
					If Node.WarehouseFormat = Selection.Warehouse Then
						FillPropertyValues(Node, Selection);
					EndIf;
				EndDo;
			EndIf;
			
		EndDo;
	Else
		Tree.GetItems().Clear();
		
		Root = Tree.GetItems();
		Format = Undefined;
		While Selection.Next() Do
			
			If Format <> Selection.Format Then
				
				Format = Selection.Format;
				
				RootNode_ = Root.Add();
				RootNode_.WarehouseFormat = Selection.Format;
				RootNode_.StandardPicture = Selection.FormatIndexImages;
				RootNode_.ItIsFormat = True;
				RootNode_.SupplyType = Selection.TypeOfFormatSupport;
				RootNode_.SupplyMethod = Selection.MethodOfProvidingFormat;
				RootNode_.DeliveryPeriodDays = Selection.FormatDeliveryTime;
				RootNode_.CoveredPeriod = Selection.ProvidedFormatPeriod;
				RootNode_.CoveredPeriodOption = Selection.VariantOfProvidedFormatPeriod;
				RootNode_.SupplySource = Selection.SourceOfFormatAssurance;
				
				Branch = RootNode_.GetItems();
				
			EndIf;
			
			Node = Branch.Add();
			Node.WarehouseFormat = Selection.Warehouse;
			Node.ItIsFormat = False;
			FillPropertyValues(Node, Selection);
		EndDo;
	EndIf;
	
EndProcedure

Procedure EnableSelectionBasedOnAssortmentChanges(SettingObject1) Export
	
	ParameterUsedSelection = DataCompositionClientServer.GetParameter(
		SettingObject1.Settings, 
		"AssortmentSelectionIsUsed");
	
	ParameterUsedSelection.Value      = False;
	ParameterUsedSelection.Use = False;
	
	MainCircuitSettings = SettingObject1.GetSettings();
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter, "ProductRangeChangeDocument");
	SelectionIsUsed_ = False;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then
			SelectionIsUsed_ = True;
			Break;
		EndIf;
	EndDo;
	
	DataCompositionClientServer.SetParameter(SettingObject1, "AssortmentSelectionIsUsed", True, SelectionIsUsed_);
	
EndProcedure

#EndRegion

#EndIf