
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If IsTempStorageURL(Parameters.AddressOfTheGoodsInTheTemporaryStorage) Then
		DocumentGoods.Load(GetFromTempStorage(Parameters.AddressOfTheGoodsInTheTemporaryStorage));

		ShowWarehouse = Parameters.ShowWarehouse;
		ShowDate = Parameters.ShowDate;
		ShowReceiptDate = Parameters.ShowReceiptDate;
		
		If ShowReceiptDate Then
			Items.TaraDate.Title = NStr("ru = 'Дата отгрузки';
										|vi = 'Shipment date';
										|en = 'Shipment date'; fa = 'تاریخ ارسال';
										|it = 'Data di spedizione';
										|pl = 'Data wysyłki';
										|tr = 'Sevkiyat tarihi'");
		EndIf;
		
		FillMultiTurnContainerTree();
		UpdateWarningLabel(Items);
	Else
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'This data processor is not intended for manual use.'; fa = 'This data processor is not intended for manual use.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Not MoveToDocument And Modified And Not Exit Then
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Chưa đưa bao bì luân chuyển vào chứng từ. Chuyển vào chứng từ?';
				|ru = 'Многооборотная тара не перенесена в документ. Перенести?';
				|en = 'Reusable packaging is not transferred to the document. Transfer?'; fa = 'Reusable packaging is not transferred to the document. Transfer?';
				|it = 'L''imballaggio restituibile non è stato trasferito nel documento. Trasferire?';
				|pl = 'Opakowanie wielokrotnego użytku nie została przeniesiona do dokumentu. Przenieść?';
				|tr = 'Yeniden kullanılabilir ambalaj belgeye transfer edilmedi. Transfer et?'"), QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		MoveToDocument = True;
		Close();
	ElsIf UserAnswer = DialogReturnCode.No Then
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If MoveToDocument And Not Exit Then
		
		AddressOfReusableContainerInStorage = PlaceContainerInStorage();
		
		Structure = New Structure("TaraIsPickedUp,AddressOfReusableContainerInStorage", True, AddressOfReusableContainerInStorage);
		MoveToDocument = True;
		NotifyChoice(Structure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure SetSlaveValues(TreeRow)
	
	Rows = TreeRow.GetItems();
	If TreeRow.SelectedAmountOfPackaging = 0 Then
		TreeRow.SelectedAmountOfPackaging = TreeRow.QuantityOfProducts;
	EndIf;		
	If Rows.Count()>0 Then
		For Each Page1 In Rows Do
			Page1.Selected_5 = TreeRow.Selected_5;
			SetSlaveValues(Page1);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure TaraSelected_5OnChange(Item)
	
	UpdateWarningLabel(Items, Items.Tara.CurrentData);
	SetSlaveValues(Items.Tara.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExitApp(Command)
	
	MoveToDocument = True;
	Close();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	MoveToDocument = False;
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelectedAmountOfPackaging.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraNumberOfContainersInTheDocument.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.SelectedAmountOfPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Tara.TheRecommendedNumberOfContainers");

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.NumberOfContainersInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Tara.TheRecommendedNumberOfContainers");

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraQuantityOfProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Format", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelected_5.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.ReusablePackageItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bao bì không có hàng hóa>';
													|ru = '<тара без товара>';
													|en = '<package without goods>'; fa = '<package without goods>';
													|it = '<tara senza merce>';
													|pl = '<opakowania bez towarów>';
													|tr = '<ürün olmadan ambalaj>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelectedAmountOfPackaging.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelectedAmountOfPackaging.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.NumberOfContainersInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.SelectedAmountOfPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InformationLabelText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<xóa bỏ>';
													|ru = '<удалить>';
													|en = '<delete>'; fa = '<delete>';
													|it = '<cancellare>';
													|pl = '<delete>';
													|tr = '<sil>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelectedAmountOfPackaging.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraNumberOfContainersInTheDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelectedAmountOfPackaging.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraNumberOfContainersInTheDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.NumberOfContainersInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.SelectedAmountOfPackaging");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.ReusablePackageItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Selected_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InformationLabelText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không chọn>';
													|ru = '<не подбирать>';
													|en = '<do not pick>'; fa = '<do not pick>';
													|it = '<non abbinare>';
													|pl = '<nie dobieraj>';
													|tr = '<seçmemek>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraSelectedAmountOfPackaging.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraReusablePackageItems.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraNumberOfContainersInTheDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.ReusablePackageItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	
	Items.Tara.InitialTreeView = InitialTreeView.NoExpand;	

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShowWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShowDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaraDateOfReceipt.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShowReceiptDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tara.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Tara.DateOfReceipt");

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

#Region Other

&AtServer
Procedure FillMultiTurnContainerTree()
	
	QueryText = 
	"SELECT
	|	DocumentGoods.Products       AS Products,
	|	DocumentGoods.Characteristic     AS Characteristic,
	|	DocumentGoods.Count         AS Count,
	|	DocumentGoods.Warehouse              AS Warehouse,
	|	DocumentGoods.Date               AS Date,
	|	DocumentGoods.DateOfReceipt    AS DateOfReceipt
	|INTO
	|	TTDocumentProducts_
	|FROM
	|	&DocumentGoods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Count > 0
	|;
	|SELECT
	|	TTDocumentProducts_.Products                                  AS Products,
	|	TTDocumentProducts_.Characteristic                                AS Characteristic,
	|	TTDocumentProducts_.Warehouse                                         AS Warehouse,
	|	TTDocumentProducts_.Date                                          AS Date,
	|	TTDocumentProducts_.DateOfReceipt                               AS DateOfReceipt,
	|	0                                                               AS QuantityOfProducts,
	|	0                                                               AS NumberOfGoodsOfDocument,
	|	TTDocumentProducts_.Products.ReusablePackageItems   AS ReusablePackageItems,
	|	TTDocumentProducts_.Products.ReusablePackageVariant AS ReusablePackageVariant,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)      AS Package,
	|	0                                                               AS MinimumNumberOfReusablePackages
	|
	|INTO
	|	TTTare
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND TTDocumentProducts_.Products.SuppliedInReusablePackage
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocumentProducts_.Products                                  AS Products,
	|	TTDocumentProducts_.Characteristic                                AS Characteristic,
	|	TTDocumentProducts_.Warehouse                                         AS Warehouse,
	|	TTDocumentProducts_.Date                                          AS Date,
	|	TTDocumentProducts_.DateOfReceipt                               AS DateOfReceipt,
	|	TTDocumentProducts_.Count                                    AS QuantityOfProducts,
	|	0                                                               AS NumberOfGoodsOfDocument,
	|	VALUE(Catalog.Products.EmptyRef)                  AS ReusablePackageItems,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef)    AS ReusablePackageVariant,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)      AS Package,
	|	0                                                               AS MinimumNumberOfReusablePackages
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocumentProducts_.Products                                           AS Products,
	|	TTDocumentProducts_.Characteristic                                         AS Characteristic,
	|	TTDocumentProducts_.Warehouse                                                  AS Warehouse,
	|	TTDocumentProducts_.Date                                                   AS Date,
	|	TTDocumentProducts_.DateOfReceipt                                        AS DateOfReceipt,
	|	CAST(TTDocumentProducts_.Count / &QueryTextPackagingFactor1 AS NUMBER(15,0)) AS QuantityOfProducts,
	|	TTDocumentProducts_.Count                                             AS NumberOfGoodsOfDocument,
	|	ProductPackages.ReusablePackageItems                      AS ReusablePackageItems,
	|	ProductPackages.ReusablePackageVariant                    AS ReusablePackageVariant,
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	ProductPackages.MinimumNumberOfReusablePackages     AS MinimumNumberOfReusablePackages
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|LEFT JOIN
	|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|ON
	|	TTDocumentProducts_.Products.PackagingGroup = ProductPackages.Owner
	|	OR (TTDocumentProducts_.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|		AND TTDocumentProducts_.Products = ProductPackages.Owner)
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT ProductPackages.DeletionMark
	|	AND ProductPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|SELECT
	|	TTTare.Products                                                        AS Products,
	|	TTTare.Characteristic                                                      AS Characteristic,
	|	TTTare.Warehouse                                                               AS Warehouse,
	|	TTTare.Date                                                                AS Date,
	|	TTTare.DateOfReceipt                                                     AS DateOfReceipt,
	|	TTTare.Package                                                            AS Package,
	|	CASE
	|		WHEN
	|			TTTare.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.Complex)
	|		THEN
	|			TTTare.Package.NumberOfPackages
	|		ELSE
	|			&QueryTextPackagingFactor2
	|	END AS NumberOfPackages,
	|	TTTare.Package.Parent                                                   AS Parent,
	|	TTTare.Products.UnitOfMeasure                                       AS UnitOfMeasure,
	|	MAX(TTTare.MinimumNumberOfReusablePackages)           AS MinimumNumberOfReusablePackages,
	|	MAX(TTTare.ReusablePackageItems)                            AS ReusablePackageItems,
	|	MAX(TTTare.ReusablePackageVariant)                          AS ReusablePackageVariant,
	|	MAX(TTTare.NumberOfGoodsOfDocument) 							   AS NumberOfGoodsOfDocument,
	|	MAX(TTTare.QuantityOfProducts)                                    AS QuantityOfProducts
	|FROM
	|	TTTare AS TTTare
	|GROUP BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Warehouse,
	|	TTTare.Date,
	|	TTTare.DateOfReceipt,
	|	TTTare.Package
	|ORDER BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Warehouse,
	|	TTTare.Date,
	|	TTTare.DateOfReceipt,
	|	NumberOfPackages DESC,
	|	TTTare.Package
	|TOTALS
	|	MAX(ReusablePackageItems),
	|	MAX(ReusablePackageVariant)
	|BY
	|	TTTare.Products,
	|	TTTare.Characteristic,
	|	TTTare.Warehouse,
	|	TTTare.Date,
	|	TTTare.DateOfReceipt
	|;
	|SELECT
	|	TTDocumentProducts_.Products       AS Products,
	|	TTDocumentProducts_.Characteristic     AS Characteristic,
	|	TTDocumentProducts_.Warehouse              AS Warehouse,
	|	TTDocumentProducts_.Date               AS Date,
	|	TTDocumentProducts_.DateOfReceipt    AS DateOfReceipt,
	|	SUM(TTDocumentProducts_.Count)  AS InitialTareQuantity,
	|	SUM(TTDocumentProducts_.Count)  AS NumberOfContainers,
	|	UNDEFINED                         AS TreeRow
	|FROM
	|	TTDocumentProducts_ AS TTDocumentProducts_
	|WHERE
	|	TTDocumentProducts_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|GROUP BY
	|	TTDocumentProducts_.Products,
	|	TTDocumentProducts_.Characteristic,
	|	TTDocumentProducts_.Warehouse,
	|	TTDocumentProducts_.Date,
	|	TTDocumentProducts_.DateOfReceipt
	|ORDER BY
	|	TTDocumentProducts_.Products.Description,
	|	TTDocumentProducts_.Characteristic.Description,
	|	TTDocumentProducts_.Warehouse.Description,
	|	TTDocumentProducts_.Date,
	|	TTDocumentProducts_.DateOfReceipt";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages", Undefined));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TTTare.Package",
		"TTTare.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Goods = DocumentGoods.Unload();
	Goods.GroupBy("Date, DateOfReceipt, Products, Characteristic, Warehouse", "Count");
	GoodsWithAllPackaging = New ValueTable();
	GoodsWithAllPackaging = 	DocumentGoods.Unload();
	GoodsWithAllPackaging.GroupBy("Date, DateOfReceipt, Products, Characteristic,Package,Warehouse", "Count");	
	GoodsWithPackaging_ = New ValueTable(); 
	GoodsWithPackaging_.Columns.Add("Date");
	GoodsWithPackaging_.Columns.Add("DateOfReceipt");
	GoodsWithPackaging_.Columns.Add("Products");
	GoodsWithPackaging_.Columns.Add("Characteristic");
	GoodsWithPackaging_.Columns.Add("Package");
	GoodsWithPackaging_.Columns.Add("Warehouse");
	For Each Page1 In GoodsWithAllPackaging Do
		If ValueIsFilled(Page1.Package) Then
			RowNew_ = GoodsWithPackaging_.Add();
			FillPropertyValues(RowNew_,Page1);
		EndIf;
	EndDo;
	
	Query.SetParameter("DocumentGoods", Goods);
	QueryResult = Query.ExecuteBatch();
	TareLines_ = Tara.GetItems();
	TareLines_.Clear();
	TaraTree = FormAttributeToValue("Tara");
	AllContainersArePickedUp = True;
	
	If Not QueryResult[2].IsEmpty() Then
		
		SelectionOfProducts = QueryResult[2].Select(QueryResultIteration.ByGroups);
		DocumentPackaging = QueryResult[3].Unload();
		
		While SelectionOfProducts.Next() Do
			
			FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
			
			While FeatureSelection_.Next() Do
				
				SampleWarehouses = FeatureSelection_.Select(QueryResultIteration.ByGroups);
				
				While SampleWarehouses.Next() Do
				
					DateSelection = SampleWarehouses.Select(QueryResultIteration.ByGroups);
					
					While DateSelection.Next() Do
						
						SelectionOfReceiptDate = DateSelection.Select(QueryResultIteration.ByGroups);
						
						While SelectionOfReceiptDate.Next() Do
						
							PackageSelection = SelectionOfReceiptDate.Select();
							
							PackingTable_ = New ValueTable();
							PackingTable_.Columns.Add("Products");
							PackingTable_.Columns.Add("Characteristic");
							PackingTable_.Columns.Add("Warehouse");
							PackingTable_.Columns.Add("Date");
							PackingTable_.Columns.Add("DateOfReceipt");
							PackingTable_.Columns.Add("Package");
							PackingTable_.Columns.Add("Parent");
							PackingTable_.Columns.Add("QuantityOfProducts");
							PackingTable_.Columns.Add("NumberOfPackages");
							PackingTable_.Columns.Add("ReusablePackageItems");
							PackingTable_.Columns.Add("ReusablePackageVariant");
							PackingTable_.Columns.Add("MinimumNumberOfReusablePackages");
							
							PackingTable_.Sort("QuantityOfProducts Desc");
							
							While PackageSelection.Next() Do
								
								If ValueIsFilled(PackageSelection.Package) Then
									
									NewLinePackaging = PackingTable_.Add();
									FillPropertyValues(NewLinePackaging, PackageSelection);
									
									If ValueIsFilled(NewLinePackaging.ReusablePackageItems) 
										And PackageSelection.Package.SuppliedInReusablePackage
										And PackageSelection.NumberOfPackages > 0 Then
										
										If PackageSelection.Package.PackageType = Enums.TypesOfItemsPackages.Final Then
											NumberOfContainers = Int(PackageSelection.NumberOfGoodsOfDocument/PackageSelection.NumberOfPackages);
											ContainerResidue = PackageSelection.NumberOfGoodsOfDocument - PackageSelection.NumberOfPackages*NumberOfContainers;
										ElsIf PackageSelection.Package.PackageType = Enums.TypesOfItemsPackages.Complex Then
											NumberOfContainers = Int(PackageSelection.NumberOfGoodsOfDocument/(PackageSelection.Package.Numerator/PackageSelection.Package.Denominator));
											ContainerResidue = PackageSelection.NumberOfGoodsOfDocument - PackageSelection.NumberOfPackages*(PackageSelection.Package.Numerator/PackageSelection.Package.Denominator)*NumberOfContainers;
										EndIf;
										
										If ContainerResidue > 0
											And ContainerResidue >= NewLinePackaging.MinimumNumberOfReusablePackages
											And NewLinePackaging.MinimumNumberOfReusablePackages > 0 Then
											NumberOfContainers = NumberOfContainers + 1;
										EndIf;
										NewLinePackaging.QuantityOfProducts = NumberOfContainers; 
									EndIf;
								Else
									
									NewRow = TaraTree.Rows.Add();
									FillPropertyValues(NewRow, PackageSelection);
									
									If ValueIsFilled(NewRow.ReusablePackageItems) Then
										
										NewRow.TheRecommendedNumberOfContainers = Int(NewRow.QuantityOfProducts);
										NewRow.SelectedAmountOfPackaging = NewRow.TheRecommendedNumberOfContainers;
										
										FillInNumberOfContainersFromDocument(DocumentPackaging, NewRow, AllContainersArePickedUp, GoodsWithPackaging_);
										
									EndIf;
									
								EndIf;
									
							EndDo;
							
						EndDo;
						
						OutputSubordinatePackages(
							NewRow.Rows,
							Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(),
							PackingTable_,
							DocumentPackaging,
							AllContainersArePickedUp,
							GoodsWithPackaging_);
								
					EndDo;
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
		For Each CurRow In DocumentPackaging Do
			
			If CurRow.InitialTareQuantity = CurRow.NumberOfContainers Then
				
				NewRow = TaraTree.Rows.Add();
				NewRow.ReusablePackageItems = CurRow.Products;
				NewRow.ReusablePackageVariant = CurRow.Characteristic;
				NewRow.NumberOfContainersInTheDocument = CurRow.NumberOfContainers;
				NewRow.Warehouse = CurRow.Warehouse;
				NewRow.Date = CurRow.Date;
				NewRow.DateOfReceipt = CurRow.DateOfReceipt;
				NewRow.Selected_5 = True;
				AllContainersArePickedUp = False;
				
			ElsIf CurRow.NumberOfContainers > 0 And CurRow.TreeRow <> Undefined Then
				
				CurRow.TreeRow.NumberOfContainersInTheDocument = CurRow.TreeRow.NumberOfContainersInTheDocument + CurRow.NumberOfContainers;
				
				If CurRow.TreeRow.NumberOfContainersInTheDocument <> CurRow.TreeRow.SelectedAmountOfPackaging Then
					CurRow.TreeRow.Selected_5 = True;
					AllContainersArePickedUp = False;
				EndIf;
				
			EndIf;
			
		EndDo;
				
	EndIf;
	
	ValueToFormAttribute(TaraTree, "Tara");
	
	If QueryResult[2].IsEmpty() Then
		HelpText = NStr("vi = 'Trong chứng từ không có hàng hóa. Không cần bao bì luân chuyển.';
						|ru = 'В документе отсутствуют товары. Многооборотная тара не требуется.';
						|en = 'There are no goods in the document. Reusable packaging is not required.'; fa = 'There are no goods in the document. Reusable packaging is not required.';
						|it = 'Nel documento mancano le merci.L''imballo restituibile non è richiesto.';
						|pl = 'W dokumencie nie ma towarów. Opakowanie wielokrotnego użytku nie jest potrzebne.';
						|tr = 'Belgede herhangi bir ürün bulunmamaktadır. Yeniden kullanılabilir ambalaj gerekli değildir.'");
	ElsIf Tara.GetItems().Count() = 0 Then
		HelpText = NStr("vi = 'Đối với hàng hóa đã chỉ ra trong chứng từ, không cần bao bì luân chuyển.';
						|ru = 'Для указанных в документе товаров многооборотная тара не требуется.';
						|en = 'Reusable packaging is not required for the goods specified in the document.'; fa = 'Reusable packaging is not required for the goods specified in the document.';
						|it = 'Per le merci specificte nel documento l''imballo restituibile non è richiesto.';
						|pl = 'Dla wymienionych w dokumencie towarów opakowanie wielokrotnego użytku nie jest potrzebne.';
						|tr = 'Belgede belirtilen ürünler için yeniden kullanılabilir ambalajlar gerekli değildir.'");
	Else
		
		If AllContainersArePickedUp Then
			HelpText = NStr("vi = 'Đã chọn toàn bộ bao bì luân chuyển cần thiết vào chứng từ.';
							|ru = 'Вся необходимая многооборотная тара уже подобрана в документ.';
							|en = 'All necessary reusable packaging is already picked for the document.'; fa = 'All necessary reusable packaging is already picked for the document.';
							|it = 'Tutto l''imballo restituibile necessario è stata già selezionata nel documento.';
							|pl = 'Wszystkie niezbędne opakowania wielokrotnego użytku już została dobrana do dokumentu.';
							|tr = 'Gerekli tüm yeniden kullanılabilir ambalajlar belgede artık seçildi.'");
		Else
			HelpText = NStr("vi = 'Hãy nhấn nút ""Kết thúc"" để chuyển bao bì luân chuyển đã chọn vào chứng từ.';
							|ru = 'Нажмите ""Завершить"" для переноса подобранной многооборотной тары в документ.';
							|en = 'Click Finish to transfer the picked reusable packaging to the document.'; fa = 'Click Finish to transfer the picked reusable packaging to the document.';
							|it = 'Premere ""Completare"" per il trasferimento dell''imballo restituibile selezionato nel documento.';
							|pl = 'Kliknij ""Zakończ"" aby przenieść dobrane opakowania wielokrotnego użytku do dokumentu.';
							|tr = 'Seçilen yeniden kullanılabilir ambalajı belgeye aktarmak için ""Son"" düğmesine tıkla.'");
			Modified = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputSubordinatePackages(StringPacking_, PackingKnot, PackingTable_, DocumentPackaging, AllContainersArePickedUp, GoodsWithPackaging_)
	
	SubordinatePackages = PackingTable_.FindRows(New Structure("Parent", PackingKnot));
	QuantityOfProducts = StringPacking_.Parent.QuantityOfProducts;
	NumberOfProductsToDistribute = QuantityOfProducts;
	
	For Each CurRow In SubordinatePackages Do
		
		NewLinePackaging = StringPacking_.Add();
		FillPropertyValues(NewLinePackaging, CurRow);
		
		If ValueIsFilled(NewLinePackaging.ReusablePackageItems) And CurRow.Package.SuppliedInReusablePackage Then
		
			NumberOfContainers = Int(NumberOfProductsToDistribute/CurRow.NumberOfPackages);
			ContainerResidue = NumberOfProductsToDistribute - CurRow.NumberOfPackages*NumberOfContainers;
			
			If ContainerResidue > 0 
				And ContainerResidue >= CurRow.MinimumNumberOfReusablePackages
				And CurRow.MinimumNumberOfReusablePackages > 0 Then
				NumberOfContainers = NumberOfContainers + 1;
				ContainerResidue = 0;
			EndIf;
			
			If NumberOfContainers > 0 Then
				NewLinePackaging.TheRecommendedNumberOfContainers = NumberOfContainers;
				NewLinePackaging.SelectedAmountOfPackaging = NewLinePackaging.TheRecommendedNumberOfContainers;
				NumberOfProductsToDistribute = ContainerResidue;
			EndIf;
			
		EndIf;
		
		FillInNumberOfContainersFromDocument(DocumentPackaging, NewLinePackaging, AllContainersArePickedUp, GoodsWithPackaging_);
			
		OutputSubordinatePackages(
			NewLinePackaging.Rows,
			CurRow.Package,
			PackingTable_,
			DocumentPackaging,
			AllContainersArePickedUp,
			GoodsWithPackaging_);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInNumberOfContainersFromDocument(DocumentPackaging, TreeRow, AllContainersArePickedUp, GoodsWithPackaging_)
	
	UseVariants = Common.ObjectAttributeValue(TreeRow.ReusablePackageItems, "UseVariants");
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Products", TreeRow.ReusablePackageItems);
	FilterParameters.Insert("Warehouse", TreeRow.Warehouse);
	FilterParameters.Insert("Date", TreeRow.Date);
	FilterParameters.Insert("DateOfReceipt", TreeRow.DateOfReceipt);
	
	If UseVariants <> Enums.ItemVariantsUsageOptions.DontUse
		And Not ValueIsFilled(TreeRow.ReusablePackageVariant) Then
		
		TareDocumentStrings = DocumentPackaging.FindRows(FilterParameters);
		
	Else
		
		FilterParameters.Insert("Characteristic", TreeRow.ReusablePackageVariant);		
		TareDocumentStrings = DocumentPackaging.FindRows(FilterParameters);
		
	EndIf;
	
	If TareDocumentStrings.Count() > 0 And TareDocumentStrings[0].NumberOfContainers > 0  Then
		
		TreeRow.NumberOfContainersInTheDocument = Min(TreeRow.TheRecommendedNumberOfContainers, TareDocumentStrings[0].NumberOfContainers);
		TareDocumentStrings[0].NumberOfContainers = TareDocumentStrings[0].NumberOfContainers - TreeRow.NumberOfContainersInTheDocument;
		TareDocumentStrings[0].TreeRow = TreeRow;
		
	EndIf;
	
	TareDocumentStringsWithPackaging = New Array();
	FilterParameters = New Structure;
	FilterParameters.Insert("Products", TreeRow.Products);
	FilterParameters.Insert("Warehouse", TreeRow.Warehouse);
	FilterParameters.Insert("Date", TreeRow.Date);
	FilterParameters.Insert("DateOfReceipt", TreeRow.DateOfReceipt);
	ThereIsSelectedPackage = False;
	
	If UseVariants <> Enums.ItemVariantsUsageOptions.DontUse
	And Not ValueIsFilled(TreeRow.ReusablePackageVariant) Then
		
		TareDocumentStringsWithPackaging = GoodsWithPackaging_.FindRows(FilterParameters);
		
	Else
		
		FilterParameters.Insert("Characteristic", TreeRow.ReusablePackageVariant);		
		TareDocumentStringsWithPackaging = GoodsWithPackaging_.FindRows(FilterParameters);
		
	EndIf;
	If TareDocumentStringsWithPackaging.Count()>0 Then
		ThereIsSelectedPackage = True;
	EndIf;

	If ThereIsSelectedPackage Then
		If (TreeRow.NumberOfContainersInTheDocument <> TreeRow.SelectedAmountOfPackaging Or TreeRow.SelectedAmountOfPackaging =0)
		And (TareDocumentStringsWithPackaging[0].Package = TreeRow.Package Or (TreeRow.Parent<>Undefined And TreeRow.Parent.Selected_5 = True)) Then
			TreeRow.Selected_5 = True;
			AllContainersArePickedUp = False;
			If TreeRow.SelectedAmountOfPackaging = 0 Then
				TreeRow.SelectedAmountOfPackaging = TreeRow.QuantityOfProducts;
			EndIf;		
		EndIf;
	ElsIf (TreeRow.NumberOfContainersInTheDocument <> TreeRow.SelectedAmountOfPackaging)
		And (
		(TreeRow.Parent<>Undefined And (TreeRow.Parent.Selected_5 = True Or Not ValueIsFilled(TreeRow.Parent.ReusablePackageItems)))
		Or TreeRow.Parent=Undefined) Then
			TreeRow.Selected_5 = True;
			AllContainersArePickedUp = False;
	EndIf;
	
EndProcedure

&AtServer
Function PlaceContainerInStorage()
	
	TaraTree = FormAttributeToValue("Tara");
	
	PackageTable = New ValueTable();
	PackageTable.Columns.Add("Products");
	PackageTable.Columns.Add("Characteristic");
	PackageTable.Columns.Add("Count");
	PackageTable.Columns.Add("Warehouse");
	PackageTable.Columns.Add("Date");
	PackageTable.Columns.Add("DateOfReceipt");
		
	AddSelectedContainersToTable(TaraTree.Rows, PackageTable);
		
	PackageTable.GroupBy("Products,Characteristic,Warehouse,Date,DateOfReceipt", "Count");
		
	AddressOfReusableContainerInStorage = PutToTempStorage(PackageTable, UUID);
	Return AddressOfReusableContainerInStorage;
	
EndFunction

&AtServer
Function CheckTreeForSelectedRows(TreeRows,ThereIsSelectedContainer)
	
	For Each CurRow In TreeRows Do
		
		If ThereIsSelectedContainer Then
			Break;
		EndIf;
		
		If CurRow.Selected_5 Then
			ThereIsSelectedContainer =  True;
			Break;
		EndIf;
		
		CheckTreeForSelectedRows(CurRow.Rows,ThereIsSelectedContainer)
		
	EndDo;	
	
EndFunction

&AtServer
Procedure AddSelectedContainersToTable(TreeRows, PackageTable)
	
	For Each CurRow In TreeRows Do
		
		If (CurRow.Selected_5 Or (Not CurRow.Selected_5 And CurRow.NumberOfContainersInTheDocument > 0))
			And ValueIsFilled(CurRow.ReusablePackageItems) Then
			
			NewRow = PackageTable.Add();
			NewRow.Products = CurRow.ReusablePackageItems;
			NewRow.Characteristic = CurRow.ReusablePackageVariant;
			NewRow.Count = ?(CurRow.Selected_5, CurRow.SelectedAmountOfPackaging, CurRow.NumberOfContainersInTheDocument);
			NewRow.Warehouse = CurRow.Warehouse;
			NewRow.Date = CurRow.Date;
			NewRow.DateOfReceipt = CurRow.DateOfReceipt;
			
		EndIf;
		
		AddSelectedContainersToTable(CurRow.Rows, PackageTable);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure TaraSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.TaraProducts Then
		StandardProcessing = False;
		If ValueIsFilled(Items.Tara.CurrentData.Package) Then
			ShowValue(Undefined, Items.Tara.CurrentData.Package);
		Else
			ShowValue(Undefined, Items.Tara.CurrentData.Products);
		EndIf;
	ElsIf Field = Items.TaraCharacteristic Then
		StandardProcessing = False;
		ShowValue(Undefined, Items.Tara.CurrentData.Characteristic);
	ElsIf Field = Items.TaraReusablePackageItems Then
		StandardProcessing = False;
		ShowValue(Undefined, Items.Tara.CurrentData.ReusablePackageItems);
	ElsIf Field = Items.TaraReusablePackageVariant Then
		StandardProcessing = False;
		ShowValue(Undefined, Items.Tara.CurrentData.ReusablePackageVariant);
	EndIf;
	
EndProcedure

&AtClient
Procedure TaraOnActivateRow(Item)
	
	UpdateWarningLabel(Items, Items.Tara.CurrentData);
	
EndProcedure

&AtClient
Procedure TaraSelectedAmountOfPackagingOnChange(Item)
	
	UpdateWarningLabel(Items, Items.Tara.CurrentData);
	
EndProcedure

&AtClient
Procedure OpenPackage(Command)
	
    TreeItems = Tara.GetItems();
    For Each TreeItem In TreeItems Do
        Items.Tara.Expand(TreeItem.GetID(),True);
    EndDo;	
	
EndProcedure

&AtClient
Procedure ClosePackage(Command)
	
	TreeItems = Tara.GetItems();
    For Each TreeItem In TreeItems Do
        Items.Tara.Collapse(TreeItem.GetID());
    EndDo;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateWarningLabel(Items, CurrentData = Undefined)
	
	If CurrentData <> Undefined And
		((CurrentData.Selected_5 And CurrentData.SelectedAmountOfPackaging <> CurrentData.TheRecommendedNumberOfContainers)
		Or (Not CurrentData.Selected_5 And CurrentData.NumberOfContainersInTheDocument > 0 And
			CurrentData.NumberOfContainersInTheDocument <> CurrentData.TheRecommendedNumberOfContainers)) Then
			
		Items.Pages.CurrentPage = Items.PageWithAWarning;
		
	Else
		
		Items.Pages.CurrentPage = Items.PageWithoutWarning;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
