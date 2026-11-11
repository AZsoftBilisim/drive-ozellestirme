#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ActionsString = NStr("vi = 'Tất cả';
						|ru = 'Все';
						|en = 'All'; fa = 'همه';
						|it = 'Tutti';
						|pl = 'Wszystkie';
						|tr = 'Tümü'");
	ActionsList.Add(Enums.SupplyOptions.ToSupply,
		Enums.SupplyOptions.ToSupply, True);
	ActionsList.Add(Enums.SupplyOptions.ReserveAsReceived,
		Enums.SupplyOptions.ReserveAsReceived, True);
	ActionsList.Add(Enums.SupplyOptions.Ship,
		Enums.SupplyOptions.Ship, True);
	ActionsList.Add(Enums.SupplyOptions.FromWarehouse,
		Enums.SupplyOptions.FromWarehouse, True);
	ActionsList.Add(Enums.SupplyOptions.NotRequired,
		Enums.SupplyOptions.NotRequired, True);
	ActionsList.Add(Enums.SupplyOptions.TransferedEarlier,
		Enums.SupplyOptions.TransferedEarlier, True);
	RestoreSettings();
	
	FillInProductsByValueOfAllFromDocumentIsNotProvidedSwitch();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.MarkValuesInList" Then
		
		ActionsList.Clear();
		For Each Item In ValueSelected Do
			ActionsList.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
		EndDo;
		MarkingValuesInListOnServer();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActionsStringClick(Item, StandardProcessing)
	
	FormParameters = New Structure("List,Title", ActionsList, NStr("vi = 'Chọn thao tác của chứng từ';
																	|ru = 'Выбор действий документа';
																	|en = 'Select document actions'; fa = 'Select document actions';
																	|it = 'Selezione azioni documento';
																	|pl = 'Wybór działań dokumentu';
																	|tr = 'Belge işlem seçimi'"));
	StandardProcessing = False;
	OpenForm(
		"CommonForm.MarkValuesInList",
		FormParameters,
		ThisObject,
		UUID,
		,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInDocumentDeficitOnChange(Item)
	
	ShouldSaveSettings();
	FillInProductsByValueOfAllFromDocumentIsNotProvidedSwitch();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	FillInProductsByValueOfAllFromDocumentIsNotProvidedSwitch();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	LineProducts_ = Items.Goods.CurrentData;
	LineProducts_.Mark = LineProducts_.ToOrder > 0;
	LineProducts_.MarkCount = LineProducts_.Mark;
	PagesSelectedRowsSwitch();
	
EndProcedure

&AtClient
Procedure GoodsMarkOnChange(Item)
	
	LineProducts_ = Items.Goods.CurrentData;
	LineProducts_.MarkCount = LineProducts_.Mark;
	PagesSelectedRowsSwitch();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Notice(Command)
	ChangeMark_(True);
EndProcedure

&AtClient
Procedure ClearMark1(Command)
	ChangeMark_(False);
EndProcedure

&AtClient
Procedure CreateDocument(Command)
	
	Result = New Structure("AddressGoods,Basis,Warehouse");
	ReturnStructure = AddressGoods();
	Result.AddressGoods = ReturnStructure.AddressGoods;
	Result.Basis = Parameters.Ref;
	Result.Warehouse = ReturnStructure.OneWarehouse;
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "GoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Goods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisObject,
		"GoodsPurpose",
		"Goods.ItemsType",
		False);
	WarehouseGroup_ = True;
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject, "Goods", True, "");
	
	// An empty security option.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSupplyOption.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.SupplyOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<theo tất cả thao tác>';
																		|ru = '<по всем действиям>';
																		|en = '<by all actions>'; fa = '<by all actions>';
																		|it = '<per tutte le azioni>';
																		|pl = '<dla wszystkich działań>';
																		|tr = '<tüm işlemler için>'"));
	
EndProcedure

&AtServer
Procedure VisibilityManagement(CurElementName = Undefined)
	
	If CurElementName = Items.EverythingFromDocumentIsNotSupplied.Name Or CurElementName = Undefined Then
		
		Items.GoodsSupplied.Visible = EverythingFromDocumentIsNotSupplied = 1; // filling is not provided
		Items.GoodsRequired2.Visible = EverythingFromDocumentIsNotSupplied = 1; // filling is not provided
		Items.GoodsCountByDocument.Visible = EverythingFromDocumentIsNotSupplied = 0; // filling in the document
		Items.GoodsSupplyOption.Visible = EverythingFromDocumentIsNotSupplied = 0; // filling in the document
		Items.GoodsDateOfShipment.Visible = EverythingFromDocumentIsNotSupplied = 0; // filling in the document
		Items.ActionsString.Visible = EverythingFromDocumentIsNotSupplied = 0; // filling in the document
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProductsByValueOfAllFromDocumentIsNotProvidedSwitch()
	
	If Parameters.ParametersAreDescribedInCommonModule Then
		CreationParameters = Common.CalculateInSafeMode(Parameters.NameOfDocumentManager
			+ ".CreationParametersBasedOnProvidingOrder()");
	Else
		CreationParameters = Documents[Parameters.NameOfDocumentManager].CreationParametersBasedOnProvidingOrder();
	EndIf;
	
	CreationParameters.NameOfDocumentManager = Parameters.NameOfDocumentManager;
	
	ManagerOfDocument = Common.ObjectManagerByRef(Parameters.Ref);
	TempTablesManager = New TempTablesManager;
	ManagerOfDocument.GoodsOfDocumentForCreatingSecuringOrder(
		Parameters.Ref,
		CreationParameters,
		TempTablesManager);
		
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Warehouses", Warehouse);
	Query.SetParameter("AllWarehouses", Not ValueIsFilled(Warehouse));
	SupplyOptions = SupplyOptions();
	Query.SetParameter("SupplyOptions", SupplyOptions);
	Query.SetParameter("AllActions", SupplyOptions.Count() = 0);

	Texts = New Array();
	If EverythingFromDocumentIsNotSupplied = 0 Then // filling in everything from the document
		
		Text =
			"SELECT
			|	MIN(Goods.LineNumber) AS LineNumberInDocument,
			|	Goods.Products AS Products,
			|	MIN(CAST(Goods.Products AS Catalog.Products).ItemsType) AS ItemsType,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Package AS Package,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Department AS Department,
			|	Goods.Purpose AS Purpose,
			|	Goods.SupplyOption AS SupplyOption,
			|	Goods.WithAssignment AS WithAssignment,
			|	Goods.DateOfShipment AS DateOfShipment,
			|	SUM(Goods.CountByDocument) AS CountByDocument,
			|	TRUE AS Mark,
			|	TRUE AS MarkCount,
			|	SUM(Goods.CountByDocument) AS ToOrder
			|FROM
			|	DocumentGoods AS Goods
			|WHERE
			|	(&AllWarehouses OR Goods.Warehouse IN(&Warehouses))
			|		AND (&AllActions OR Goods.SupplyOption IN(&SupplyOptions))
			|GROUP BY
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.Package,
			|	Goods.Warehouse,
			|	Goods.Department,
			|	Goods.Purpose,
			|	Goods.SupplyOption,
			|	Goods.WithAssignment,
			|	Goods.DateOfShipment
			|ORDER BY
			|	LineNumberInDocument";
		Texts.Add(Text);
			
	Else // filling is not provided
		
		Text =
			"SELECT
			|	MIN(Goods.LineNumber) AS LineNumber,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Department AS Department,
			|	CASE
			|		WHEN CAST(Goods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|			THEN Goods.Department
			|		ELSE Goods.Warehouse
			|	END AS Sender,
			|	CASE
			|		WHEN COUNT(DISTINCT Goods.Package) = 1
			|			THEN MAX(Goods.Package)
			|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|	END AS Package,
			|	Goods.Purpose AS Purpose,
			|	Goods.WithAssignment AS WithAssignment
			|INTO ProductsGrouped
			|FROM
			|	DocumentGoods AS Goods
			|WHERE
			|	(&AllWarehouses OR Goods.Warehouse IN(&Warehouses))
			|		AND Goods.SupplyOption IN(
			|			VALUE(Enum.SupplyOptions.ReserveAsReceived),
			|			VALUE(Enum.SupplyOptions.ToSupply))
			|GROUP BY
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.Warehouse,
			|	Goods.Department,
			|	CASE
			|		WHEN CAST(Goods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|			THEN Goods.Warehouse
			|		ELSE Goods.Department
			|	END,
			|	Goods.Purpose,
			|	Goods.WithAssignment
			|INDEX BY
			|	Products, Characteristic, Sender, Purpose";
			
		Texts.Add(Text);
		
		Text =
			"SELECT ALLOWED
			|	InventoryAndDemands.Products AS Products,
			|	InventoryAndDemands.Characteristic AS Characteristic,
			|	InventoryAndDemands.Warehouse AS Warehouse,
			|	InventoryAndDemands.Purpose AS Purpose,
			|	InventoryAndDemands.ReserveUponReceiptFromLockedBalance
			|		+ InventoryAndDemands.ReserveAsReceivedBalance
			|		+ InventoryAndDemands.ToSupplyBalance
			|		+ InventoryAndDemands.SnoozeReservationBalance AS Required2,
			|	CASE
			|		WHEN InventoryAndDemands.InStockBalance
			|				+ InventoryAndDemands.OrderedBalance
			|				- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance
			|				- InventoryAndDemands.ReserveAtWarehouseBalance < 0
			|			THEN 0
			|		ELSE InventoryAndDemands.InStockBalance
			|				+ InventoryAndDemands.OrderedBalance
			|				- InventoryAndDemands.ReserveAtWarehouseFromLockedBalance
			|				- InventoryAndDemands.ReserveAtWarehouseBalance
			|	END AS Supplied
			|INTO Demands
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		(Products, Characteristic, Warehouse, Purpose) IN(
			|			SELECT
			|				Goods.Products AS Products,
			|				Goods.Characteristic AS Characteristic,
			|				Goods.Sender AS Warehouse,
			|				Goods.Purpose AS Purpose
			|			FROM
			|				ProductsGrouped AS Goods)) AS InventoryAndDemands
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
			
			Text = StrReplace(Text, "INTO Demands", "INTO PreliminaryDemands");
			Texts.Add(Text);
			
			Text =
				"SELECT
				|	Demands.Products AS Products,
				|	Demands.Characteristic AS Characteristic,
				|	Demands.Warehouse AS Warehouse,
				|	Demands.Purpose AS Purpose,
				|	SUM(Demands.Required2) AS Required2,
				|	CASE
				|		WHEN SUM(Demands.Supplied) < SUM(Demands.Required2)
				|			THEN SUM(Demands.Supplied)
				|		ELSE SUM(Demands.Required2)
				|	END AS Supplied
				|INTO Demands
				|FROM(
				|	SELECT
				|		Demands.Products AS Products,
				|		Demands.Characteristic AS Characteristic,
				|		Demands.Warehouse AS Warehouse,
				|		Demands.Purpose AS Purpose,
				|		Demands.Required2 AS Required2,
				|		Demands.Supplied AS Supplied
				|	FROM
				|		PreliminaryDemands AS Demands
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		Demands.Products AS Products,
				|		Demands.Characteristic AS Characteristic,
				|		Demands.Warehouse AS Warehouse,
				|		Demands.Purpose AS Purpose,
				|		Demands.ToSupply - Demands.Replaced AS Required2,
				|		0 AS Supplied
				|	FROM
				|		InformationRegister.OrderStructure AS Demands
				|	WHERE
				|		(Demands.Products, Demands.Characteristic, Demands.Warehouse, Demands.Purpose) IN(
				|			SELECT
				|				Goods.Products AS Products,
				|				Goods.Characteristic AS Characteristic,
				|				Goods.Sender AS Warehouse,
				|				Goods.Purpose AS Purpose
				|			FROM
				|				ProductsGrouped AS Goods)
				|		AND Demands.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)) AS Demands
				|GROUP BY
				|	Demands.Purpose,
				|	Demands.Products,
				|	Demands.Characteristic,
				|	Demands.Warehouse
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose";
		EndIf;
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	Goods.LineNumber AS LineNumberInDocument,
			|	Goods.Products AS Products,
			|	CAST(Goods.Products AS Catalog.Products).ItemsType AS ItemsType,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Package AS Package,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Department AS Department,
			|	Goods.Purpose AS Purpose,
			|	Goods.WithAssignment AS WithAssignment,
			|	ISNULL(Demands.Required2, 0) / ISNULL(&QueryTextPackagingFactor, 1) AS Required2,
			|	ISNULL(Demands.Supplied, 0) / ISNULL(&QueryTextPackagingFactor, 1) AS Supplied,
			|	ISNULL(Demands.Required2 - Demands.Supplied, 0) > 0 AS Mark,
			|	CASE
			|		WHEN ISNULL(Demands.Required2 - Demands.Supplied, 0) > 0
			|			THEN 1
			|		ELSE 0
			|	END AS MarkCount,
			|	ISNULL(Demands.Required2 - Demands.Supplied, 0) / ISNULL(&QueryTextPackagingFactor, 1) AS ToOrder
			|FROM
			|	ProductsGrouped AS Goods
			|		
			|		LEFT JOIN Demands AS Demands
			|		ON Demands.Products = Goods.Products
			|		 AND Demands.Characteristic = Goods.Characteristic
			|		 AND Demands.Warehouse = Goods.Sender
			|		 AND Demands.Purpose = Goods.Purpose
			|ORDER BY
			|	LineNumberInDocument";
			
		Substitution = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package", "Goods.Products");
		Text = StrReplace(Text, "&QueryTextPackagingFactor", Substitution);
		
		Texts.Add(Text);
	EndIf;
	
	Text =
		"SELECT DISTINCT
		|	Goods.Warehouse AS Ref
		|FROM
		|	DocumentGoods AS Goods
		|WHERE
		|	Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	ResultsPackage = Query.ExecuteBatch();
	GoodsTable = ResultsPackage[ResultsPackage.UBound() - 1].Unload();
	WarehouseArray = ResultsPackage[ResultsPackage.UBound()].Unload().UnloadColumn("Ref");
	Items.Warehouse.ChoiceList.LoadValues(WarehouseArray);
	Goods.Load(GoodsTable);
	PagesSelectedRowsSwitchAtServer();
	VisibilityManagement();
	
EndProcedure

&AtServer
Procedure MarkingValuesInListOnServer()
	
	All = True;
	Presentations = New Array();
	For Each Item In ActionsList Do
		All = All And Item.Check;
		If Item.Check Then
			Presentations.Add(Item.Presentation);
		EndIf;
	EndDo;
	ActionsString = ?(All, NStr("vi = 'Tất cả';
								|ru = 'Все';
								|en = 'All'; fa = 'همه';
								|it = 'Tutti';
								|pl = 'Wszystkie';
								|tr = 'Tümü'"), StrConcat(Presentations, ", "));
	ShouldSaveSettings();
	FillInProductsByValueOfAllFromDocumentIsNotProvidedSwitch();
	
EndProcedure

&AtServer
Procedure ChangeMark_(Set)
	
	For Each Id In Items.Goods.SelectedRows Do
		
		String = Goods.FindByID(Id);
		String.Mark = Set;
		
	EndDo;
	PagesSelectedRowsSwitchAtServer();
	
EndProcedure

&AtServer
Function AddressGoods()
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	Goods.LineNumberInDocument AS LineNumberInDocument,
		|	CAST(Goods.Products AS Catalog.Products) AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	Goods.ToOrder AS ToOrder,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Department AS Department,
		|	Goods.DateOfShipment AS DateOfShipment
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.ToOrder > 0
		|INDEX BY
		|   Products
		|;
		|
		|///////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumberInDocument AS LineNumberInDocument,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
		|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	Goods.ToOrder * ISNULL(&QueryTextPackagingFactor, 1) AS Count,
		|	Goods.ToOrder AS NumberOfPackages,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Department AS Department,
		|	Goods.DateOfShipment AS DateOfShipment,
		|	CASE WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|				Goods.Department
		|			ELSE
		|				Goods.Warehouse
		|		END AS Recipient,
		|	CASE WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService) THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|		END AS ToExpenseAs
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS AllPackages
		|		ON AllPackages.Ref = Goods.Package
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period,
		|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|		ON ProductsVATRates.Products = Goods.Products 
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
		|		ON TRUE
		|ORDER BY
		|	LineNumberInDocument
		|;
		|
		|////////////////////////////
		|SELECT
		|	CASE
		|		WHEN MIN(Goods.Warehouse) = MAX(Goods.Warehouse)
		|			THEN MIN(Goods.Warehouse)
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS OneWarehouse
		|FROM
		|	Goods AS Goods
		|WHERE
		|	VALUETYPE(Goods.Warehouse) = TYPE(Catalog.Warehouses) AND Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"AllPackages.Ref",
		"Goods.Products"));
		
	AttributesValues = Common.ObjectAttributesValues(Parameters.Ref, "Date, Organization");
	Query.SetParameter("Goods", Goods.Unload(New Structure("Mark", True)));
	Query.SetParameter("DocumentRef", Parameters.Ref);
	Query.SetParameter("Period", AttributesValues.Date);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(AttributesValues.Organization));
	
	Results = Query.ExecuteBatch();
	TableOfGoods = Results[Results.UBound() - 1].Unload();
	AddressGoods = PutToTempStorage(TableOfGoods);
	Selection = Results[Results.UBound()].Select();
	OneWarehouse = Catalogs.Warehouses.EmptyRef();
	If Selection.Next() Then
		OneWarehouse = Selection.OneWarehouse;
	EndIf;
	
	Return New Structure("AddressGoods,OneWarehouse", AddressGoods, OneWarehouse);
	
EndFunction

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure();
	
	SupplyOptions = SupplyOptions();
	
	Settings.Insert("SupplyOptions", SupplyOptions);
	Settings.Insert("EverythingFromDocumentIsNotSupplied", EverythingFromDocumentIsNotSupplied);
	
	SettingsKey = Parameters.NameOfDocumentManager + TypeOf(Parameters.Ref);
	Common.CommonSettingsStorageSave(
		"CommonForm.GenerateSpecifyTheQuantityToOrder",
		SettingsKey,
		Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsKey = Parameters.NameOfDocumentManager + TypeOf(Parameters.Ref);
	SettingsValue = Common.CommonSettingsStorageLoad(
		"CommonForm.GenerateSpecifyTheQuantityToOrder",
		SettingsKey);
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		EverythingFromDocumentIsNotSupplied = SettingsValue.EverythingFromDocumentIsNotSupplied;
		For Each Item In ActionsList Do
			Item.Check = False;
		EndDo;
		For Each Item In SettingsValue.SupplyOptions Do
			ActionsList.FindByValue(Item).Check = True;
		EndDo;
		All = True;
		Presentations = New Array();
		For Each Item In ActionsList Do
			All = All And Item.Check;
			If Item.Check Then
				Presentations.Add(Item.Presentation);
			EndIf;
		EndDo;
		ActionsString = ?(All, NStr("vi = 'Tất cả';
									|ru = 'Все';
									|en = 'All'; fa = 'همه';
									|it = 'Tutti';
									|pl = 'Wszystkie';
									|tr = 'Tümü'"), StrConcat(Presentations, ", "));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PagesSelectedRowsSwitchAtServer()
	
	MarkCount = Goods.Total("MarkCount");
	If MarkCount = 0 Then
		Items.PagesSelectedRows.CurrentPage = Items.PageSelectedRows0;
	Else
		Items.PagesSelectedRows.CurrentPage = Items.PageSelectedRowsNot0;
	EndIf;
	
EndProcedure

&AtClient
Procedure PagesSelectedRowsSwitch()
	
	MarkCount = Goods.Total("MarkCount");
	If MarkCount = 0 Then
		Items.PagesSelectedRows.CurrentPage = Items.PageSelectedRows0;
	Else
		Items.PagesSelectedRows.CurrentPage = Items.PageSelectedRowsNot0;
	EndIf;
	
EndProcedure

&AtServer
Function SupplyOptions()
	
	SupplyOptions = New Array();
	For Each Item In ActionsList Do
		If Item.Check Then
			SupplyOptions.Add(Item.Value);
		EndIf;
	EndDo;
	Return SupplyOptions;
	
EndFunction

#EndRegion
