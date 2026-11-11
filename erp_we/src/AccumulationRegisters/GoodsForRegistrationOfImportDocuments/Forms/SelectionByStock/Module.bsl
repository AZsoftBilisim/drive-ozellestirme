
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	FillPropertyValues(ThisForm, Parameters, "Organization, Vendor, Date, AddressInStorage, Warehouse");
	
	FillInTheProducts();
	CustomizeFormElements();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	FillInTheProducts();
EndProcedure

&AtClient
Procedure TableOfGoodsCountOnChange(Item)
	OwnGoods = Items.Goods.CurrentData;
	OwnGoods.Selected = (OwnGoods.Count <> 0);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()

	PutInStorage();
	Close(DialogReturnCode.OK);
	
	NotifyChoice(AddressInStorage);
	
EndProcedure

&AtClient
Procedure SelectRowsExecute()
	SelectedProductItems = ProcessingOfTabularFormsClientServer.CollectionItems(Goods, Items.Goods.SelectedRows);
	For Each OwnGoods In SelectedProductItems Do
		OwnGoods.Selected = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearRowsExecute()
	SelectedProductItems = ProcessingOfTabularFormsClientServer.CollectionItems(Goods, Items.Goods.SelectedRows);
	For Each OwnGoods In SelectedProductItems Do
		OwnGoods.Selected = False;
	EndDo;
EndProcedure

&AtClient
Procedure Refresh(Command)
	FillInTheProducts();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.RosyBrown);

EndProcedure

&AtServer
Procedure CustomizeFormElements()
	Items.Warehouse.Visible = ValueIsFilled(Warehouse);
	Items.GoodsWarehouse.Visible = Not Items.Warehouse.Visible;
EndProcedure

#Region Other

&AtServer
Procedure PutInStorage() 
	ProductsInStorage =
		Goods.Unload(
			New Structure("Selected", True),
			"Selected, Products, Characteristic, Series, Warehouse, DocumentInflow, PurchaseForActivity, BusinessOperation, Count, NumberOfPackages, Package");
	For Each TableRow In ProductsInStorage Do
		TableRow.NumberOfPackages = TableRow.Count;
	EndDo;
	PutToTempStorage(ProductsInStorage, AddressInStorage);
EndProcedure

&AtServer
Procedure FillInTheProducts()
	Query = New Query(
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.DocumentInflow AS DocumentInflow,
	|	Goods.Count AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OnDate.ItemsLocationAttributes.Products AS Products,
	|	OnDate.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	OnDate.ItemsLocationAttributes.WarehouseArea AS Warehouse,
	|	OnDate.ItemsLocationAttributes.Series AS Series,
	|	ForNow.DocumentInflow AS DocumentInflow,
	|	SUM(ForNow.CountBalance) AS CountBalance
	|INTO ToRegister
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|			&Boundary,
	|			Organization = &Organization
	|				AND Vendor = &Vendor
	|				AND ImportDocumentType = &ImportDocumentType
	|				AND (ItemsLocationAttributes.WarehouseArea = &Warehouse
	|					OR &AllWarehouses)) AS OnDate
	|		LEFT JOIN AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|				,
	|				Organization = &Organization
	|					AND Vendor = &Vendor
	|					AND ImportDocumentType = &ImportDocumentType
	|					AND (ItemsLocationAttributes.WarehouseArea = &Warehouse
	|						OR &AllWarehouses)) AS ForNow
	|		ON OnDate.ItemsLocationAttributes = ForNow.ItemsLocationAttributes
	|			AND OnDate.InventoryOwnerAttribute = ForNow.InventoryOwnerAttribute
	|WHERE
	|	ForNow.CountBalance > 0
	|
	|GROUP BY
	|	OnDate.ItemsLocationAttributes.Products,
	|	OnDate.ItemsLocationAttributes.Characteristic,
	|	OnDate.ItemsLocationAttributes.WarehouseArea,
	|	ForNow.DocumentInflow,
	|	OnDate.ItemsLocationAttributes.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN Goods.Count > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Selected,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ToRegister.Series AS Series,
	|	ToRegister.Warehouse AS Warehouse,
	|	ToRegister.DocumentInflow AS DocumentInflow,
	|	ToRegister.DocumentInflow.PurchaseForActivity AS PurchaseForActivity,
	|	ToRegister.DocumentInflow.BusinessOperation AS BusinessOperation,
	|	ToRegister.CountBalance AS CountBalance,
	|	ISNULL(Goods.Count, 0) AS Count,
	|	ToRegister.Products.UnitOfMeasure AS Package
	|FROM
	|	ToRegister AS ToRegister
	|		LEFT JOIN Goods AS Goods
	|		ON ToRegister.Products = Goods.Products
	|			AND ToRegister.Characteristic = Goods.Characteristic
	|			AND ToRegister.Series = Goods.Series
	|			AND ToRegister.Warehouse = Goods.Warehouse
	|			AND ToRegister.DocumentInflow = Goods.DocumentInflow
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse,
	|	PurchaseForActivity,
	|	BusinessOperation,
	|	DocumentInflow");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Vendor", Vendor);
	Query.SetParameter("ImportDocumentType", AccountingForTraceableGoodsLocalization.IDCustomsDeclarationImport());
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("AllWarehouses", Not ValueIsFilled(Warehouse));
	Boundary = New Boundary(?(ValueIsFilled(Date), EndOfDay(Date), CurrentSessionDate()), BoundaryType.Including);
	Query.SetParameter("Boundary", Boundary);
	
	If Goods.Count() > 0 Then
		ProductsParameter =
			Goods.Unload(New Structure("Selected", True), "Selected, Products, Characteristic, Series, Warehouse, Count, DocumentInflow, Package");
	Else
		ProductsParameter = GetFromTempStorage(AddressInStorage); // ValueTable, TabularSection
		ProductsParameter.GroupBy("Products, Characteristic, Series, Warehouse, DocumentInflow", "Count");
	EndIf;
	Query.SetParameter("Goods", ProductsParameter);
	
	Goods.Load(Query.Execute().Unload());
EndProcedure

#EndRegion

#EndRegion
