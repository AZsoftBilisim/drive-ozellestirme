#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If IsBlankString(Parameters.Title) Then
		Raise NStr("vi = 'Xem xét mở bộ xử lý chỉ từ biểu mẫu của đối tượng.';
					|ru = 'Предусмотрено открытие обработки только из форм объектов.';
					|en = 'Data processor can be opened only from object forms.'; fa = 'Data processor can be opened only from object forms.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme degli oggetti.';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z form obiektów.';
					|tr = 'İşleme sadece nesne formlarından açılır.'");
	EndIf;
	
	Title = Parameters.Title;
	
	Planning.CreatePeriodTable(ThisForm, "TimeIntervals");
	
	TablePeriods = GetFromTempStorage(Parameters.AddressOfThePeriodTable); // See Planning.TablePeriods
	ThisForm.TimeIntervals.Load(TablePeriods);
	
	CrossTable       = Parameters.CrossTable;
	PlanByAmount = Parameters.PlanByAmount;
	PlanProfile           = Parameters.PlanProfile;
	Object.Partner     = Parameters.Partner;
	Department      = Parameters.Department;
	
	ParametersArray = New Array;
	FilterRemainingGoodsByShelfLives = Parameters.FilterParameters;
	For Each Filter In Parameters.FilterParameters Do
		ParametersArray.Add(New ChoiceParameter("Filter." + Filter.Key, Filter.Value));
	EndDo;
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
	
	If Parameters.FilterParameters.Property("ItemsType") Then
		FilterText1 = NStr("vi = 'Để chọn dạng mặt hàng: %1.';
							|ru = 'Для выбора доступна номенклатура с типом: %1.';
							|en = 'Items with type: %1 are available for selection.'; fa = 'Items with type: %1 are available for selection.';
							|it = 'Per la selezione è disponibile l''articolo con tipo: %1';
							|pl = 'Do wyboru jest dostępna nomenklatura typu: %1.';
							|tr = '%1 tipi ile seçim için öğe erişilebilir.'");
		Types = New Array;
		For Each FilterType In Parameters.FilterParameters.ItemsType Do
			If Not GetFunctionalOption("UseReusablePackage")
				And FilterType = Enums.ItemsTypes.ReusablePackage Then
				Continue;
			EndIf;
			Types.Add(FilterType);
		EndDo;
		Items.FilterLabel.Title = StrTemplate(FilterText1, StrConcat(Types, ", "));
	EndIf;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, "PlanType, Owner, FillInPartnerInTabularForm, FillInAgreementInTabularForm, FillInWarehouseInTabularForm");
	FillPropertyValues(ThisForm, PlanViewParameters);
	
	ScriptParameters_ = Common.ObjectAttributesValues(PlanViewParameters.Owner, "UseCalculationBySalesSpeed, UseForMaterialsPlanning");
	FillPropertyValues(ThisForm, ScriptParameters_);
	
	ActivePeriods = TablePeriods.FindRows(New Structure("Active_", True));
	NumberOfPeriods = ActivePeriods.Count();
	For Each Period In ActivePeriods Do
		
		If Not ValueIsFilled(BeginOfPeriod) Then
			BeginOfPeriod = Period.StartDate;
		EndIf;
		
		If BeginOfPeriod > Period.StartDate And ValueIsFilled(Period.StartDate) Then
			BeginOfPeriod = Period.StartDate;
		EndIf;
		
	EndDo;
	
	Items.GoodsNumberOfPackages.Visible = NumberOfPeriods > 1 Or Not CrossTable;
	
	ThisIsASalesPlanByCategory = PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	ThisIsAnAssemblyDisassemblyPlan = PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	If PlanType = Enums.TypesOfPlans.ProductionPlan Then
		
		BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
		
		BOMSelectionParameters.AvailableTypes.Add(Parameters.ProductionProcessType);
		BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
		
		ItemArray = New Array;
		ItemArray.Add(Items.GoodsBillOfMaterials);
		ProductDataManagement.SetSpecificationSelectionParameters(ItemArray, BOMSelectionParameters);
		
	EndIf;
	If CrossTable Then
		
		OutputParameters = New Structure;
		OutputParameters.Insert("NameOfCrossTableProps", "Object.Goods");
		OutputParameters.Insert("CrossTableFormElement", "Goods");
		OutputParameters.Insert("PeriodsTable", TablePeriods);
		Periodicity = Common.ObjectAttributeValue(PlanViewParameters.Owner, "Periodicity");
		OutputParameters.Insert("Periodicity", Periodicity);
		
		OutputParameters.Insert("GroupFields_", True);
		OutputParameters.Insert("HeaderOfDimensionField", NStr("vi = 'Kỳ kế hoạch';
																|ru = 'Периоды планирования';
																|en = 'Planning periods'; fa = 'دوره‌های برنامه‌ریزی';
																|it = 'Periodi di pianificazione';
																|pl = 'Okresy planowania';
																|tr = 'Planlama dönemleri'"));
		
		OutputParameters.Insert("Fields", New Array());
		
		FieldStructure = New Structure;
		FieldStructure.Insert("ColumnAttributePrefix", "Price_");
		FieldStructure.Insert("DeleteTableDetails", False);
		If PlanByAmount Then
			FieldStructure.Insert("CreateElement_", True);
		Else
			FieldStructure.Insert("CreateElement_", False);
		EndIf;
		FieldStructure.Insert("ElementType", TMCommonUse.MoneyFieldTypeDescription());
		FieldStructure.Insert("Title", "Price");
		FieldStructure.Insert("CreateSummaryDetails", False);
		FieldStructure.Insert("ItemWidth", 6);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("OnChange", "Attachable_WhenPriceChanges");
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
		
		OutputParameters.Fields.Add(FieldStructure);
		
		FieldStructure = New Structure;
		FieldStructure.Insert("ColumnAttributePrefix", "Sum_");
		FieldStructure.Insert("DeleteTableDetails", False);
		FieldStructure.Insert("CreateElement_", False);
		FieldStructure.Insert("ElementType", TMCommonUse.MoneyFieldTypeDescription());
		FieldStructure.Insert("Title", "Sum");
		FieldStructure.Insert("CreateSummaryDetails", True);
		FieldStructure.Insert("ItemWidth", 6);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("OnChange", "Attachable_WhenChangingAmount_");
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
		
		OutputParameters.Fields.Add(FieldStructure);
		
		FieldStructure = New Structure;
		FieldStructure.Insert("ColumnAttributePrefix", "Count_");
		FieldStructure.Insert("DeleteTableDetails", False);
		FieldStructure.Insert("CreateElement_", True);
		FieldStructure.Insert("ElementType", "Number");
		If PlanByAmount Or NumberOfPeriods = 1 Then
			FieldStructure.Insert("Title", "Count");
		EndIf;
		FieldStructure.Insert("CreateSummaryDetails", True);
		FieldStructure.Insert("ItemWidth", 6);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("OnChange", "Attachable_WhenChangingQuantity");
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
		
		OutputParameters.Fields.Add(FieldStructure);
		
		Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
	EndIf; 
	
	InitializeSearchStructure();
	
	InitializeTableDocument();
	SetAvailabilityOfClipboardCommands();
	SetColumnAvailability();
	
	If ThisIsASalesPlanByCategory Then
	
		Items.Step1Label1.Title = NStr("vi = 'Cần sao chép các cột vào bảng từ tệp ngoài (Excel, Word ...) thông qua bộ đệm trung gian. Bắt buộc phải điền cột ""Thể loại hàng hóa"".';
										|ru = 'Необходимо скопировать колонки в таблицу из внешнего файла (Excel. Word и пр.) через буфер обмена. Обязательно должна быть заполнена колонка: ""Товарная категория"".';
										|en = 'Copy columns to table from an external file (Excel. Word, etc.) via clipboard. The ""Product category"" column is required.'; fa = 'Copy columns to table from an external file (Excel. Word, etc.) via clipboard. The ""Product category"" column is required.';
										|it = 'È necessario copiare le colonne in una tabella da un file esterno (Excel, Word, ecc.) tramite gli appunti. Deve essere compilata una colonna:""Categoria merceologica"" .';
										|pl = 'Należy skopiować kolumny do tabeli z pliku zewnętrznego (Excel. Word itp.) przez schowek. Obowiązkowo musi być wypełniona kolumna: ""Kategoria produktu"".';
										|tr = 'Sütunları harici bir dosyadan (Excel, Word, vb.) tabloya kopyalamak için panoyu kullanın. ""Ürün kategorisi"" sütunu doldurulmalı.'");
	
	Else
	
		Items.Step1Label1.Title = NStr("vi = 'Cần sao chép các cột từ tệp ngoài (Excel, Word, ...) vào bảng thông qua bộ đệm trung gian. Bắt buộc điền một trong các cột: ""Mã vạch"", ""Mã"", ""Mã hiệu"" và ""Mặt hàng"".';
										|ru = 'Необходимо скопировать колонки в таблицу из внешнего файла (Excel. Word и пр.) через буфер обмена. Обязательно должна быть заполнена одна из колонок: ""Штрихкод"", ""Код"", ""Артикул"" или ""Номенклатура"".';
										|en = 'Copy columns to the table from an external file (Excel, Word, etc.) using the clipboard. One of the columns is required: ""Barcode"", ""Code"", ""item ID"" or ""Items"".'; fa = 'Copy columns to the table from an external file (Excel, Word, etc.) using the clipboard. One of the columns is required: ""Barcode"", ""Code"", ""item ID"" or ""Items"".';
										|it = 'Bisogna copiare dal file esterno (Excel, Word, etc.) le colonne nella tabella tramite gli appunti. Una delle colonne deve essere necessariamente compilata: ""Codice a barra"", ""Codice"", ""ID articolo"" o ""Elenco articoli"".';
										|pl = 'Należy skopiować kolumny do tabeli z pliku zewnętrznego (Excel. Word, itp.) za pomocą schowka. Musi być wypełniona jedna z kolumn: ""Kod Kreskowy"", ""Kod"", ""Artykuł"" lub ""Nomenklatura"".';
										|tr = 'Sütunları harici bir dosyadan (Excel, Word, vb.) tabloya kopyalamak için panoyu kullanın. ""Barkod"", ""Kod"", ""Ürün kodu"" veya ""Ürün"" sütunlarından biri doldurulmalı.'");
	
	EndIf; 
	Items.GoodsCustomerAgreement.TypeRestriction = New TypeDescription("CatalogRef.TermsOfSale"); 
	Items.ProductsSupplierAgreement.TypeRestriction = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors"); 
	
	Items.FormNext.DefaultButton = True;
	
	// If you have already transferred the downloaded data, go to Step 2
	If IsTempStorageURL(Parameters.GoodsTableAddress) Then
	
		ArrayOfProductStructures = GetFromTempStorage(Parameters.GoodsTableAddress);
		For Each ProductStructure_1 In ArrayOfProductStructures Do
			
			If ProductStructure_1.Property("ProductID_") 
				And ValueIsFilled(ProductStructure_1.ProductID_) Then
				ProductStructure_1.Insert("Products",   Catalogs.Products.GetRef(New UUID(ProductStructure_1.ProductID_)));
			EndIf; 
			If ProductStructure_1.Property("IdentifierCharacteristic") 
				And ValueIsFilled(ProductStructure_1.IdentifierCharacteristic) Then
				ProductStructure_1.Insert("Characteristic", Catalogs.ItemsCharacteristics.GetRef(New UUID(ProductStructure_1.IdentifierCharacteristic)));
			EndIf; 
			If ProductStructure_1.Property("PackageIdentifier") 
				And ValueIsFilled(ProductStructure_1.PackageIdentifier) Then
				Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(ProductStructure_1.PackageIdentifier));
				ProductStructure_1.Insert("Package",       ?(Find(String(Package), NStr("vi = '<Không tìm thấy đối tượng>';
																						|ru = '<Объект не найден>';
																						|en = '<Object is not found>'; fa = '<Object is not found>';
																						|it = '<Oggetto non trovato>';
																						|pl = '<Nie znaleziono obiektu>';
																						|tr = '<Nesne bulunamadı>'"))> 0, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), Package));
			EndIf; 
			If ProductStructure_1.Property("PartnerID") 
				And ValueIsFilled(ProductStructure_1.PartnerID) Then
				ProductStructure_1.Insert("Partner",        Catalogs.Partners.GetRef(New UUID(ProductStructure_1.PartnerID)));
			EndIf; 
			If ProductStructure_1.Property("AgreementID") 
				And ValueIsFilled(ProductStructure_1.AgreementID) Then
				ProductStructure_1.Insert("Terms",     Catalogs.TermsOfPurchaseFromVendors.GetRef(New UUID(ProductStructure_1.AgreementID)));
			EndIf; 
			If ProductStructure_1.Property("WarehouseID_") 
				And ValueIsFilled(ProductStructure_1.WarehouseID_) Then
				ProductStructure_1.Insert("Warehouse",          Catalogs.Warehouses.GetRef(New UUID(ProductStructure_1.WarehouseID_)));
			EndIf; 
			If ProductStructure_1.Property("IdConfigurationOption") 
				And ValueIsFilled(ProductStructure_1.IdConfigurationOption) Then
				ProductStructure_1.Insert("ProductKit", Catalogs.ProductKitConfigurations.GetRef(New UUID(ProductStructure_1.IdConfigurationOption)));
			EndIf; 
			If ProductStructure_1.Property("IDSpecification") 
				And ValueIsFilled(ProductStructure_1.IDSpecification) Then
				ProductStructure_1.Insert("BillOfMaterials",   Catalogs.BillsOfMaterials.GetRef(New UUID(ProductStructure_1.IDSpecification)));
			EndIf; 
			If ProductStructure_1.Property("IdProductCategory") 
				And ValueIsFilled(ProductStructure_1.IdProductCategory) Then
				ProductStructure_1.Insert("ProductCategory", Catalogs.ProductCategories.GetRef(New UUID(ProductStructure_1.IdProductCategory)));
			EndIf; 
			If ProductStructure_1.Property("IDSalesRating") 
				And ValueIsFilled(ProductStructure_1.IDSalesRating) Then
				ProductStructure_1.Insert("SalesRank",  Catalogs.SalesRanks.GetRef(New UUID(ProductStructure_1.IDSalesRating)));
			EndIf; 
			
			If ThisIsASalesPlanByCategory Then
			
				If Not ProductStructure_1.Property("IdProductCategory") 
					Or Not ValueIsFilled(ProductStructure_1.IdProductCategory) Then
					ProductStructure_1.Insert("ThereIsUnmappedData", True);
				EndIf; 
			
			Else
				
				If Not ProductStructure_1.Property("ProductID_") 
					Or Not ValueIsFilled(ProductStructure_1.ProductID_) Then
					ProductStructure_1.Insert("ThereIsUnmappedData", True);
				EndIf; 
			
			EndIf; 
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, ProductStructure_1);
		
		EndDo; 
		
		// Comparing the data
		CompareUploadedDataWithInformationSecurityData();
		
		Items.Steps.CurrentPage = Items.Step2;
		Items.MoveGoods.DefaultButton = True;
		Items.FormBack.Visible = False;
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure LineDisplayOptionOnChange(Item)
	
	Items.Goods.RowFilter = Undefined;
	
	If LineDisplayOption = 1 Then
		Items.Goods.RowFilter = New FixedStructure("ThereIsUnmappedData", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	RequiredFieldsFilledIn = False;
	
	If CrossTable Then
		DataNFALAString = 3;
	Else
		DataNFALAString = 2;
	EndIf; 
	
	For Each RequiredField In RequiredFields Do
		Area = "R"+ DataNFALAString + "C" + Format(RequiredField.Value, "NZ=0; NG=0");
		RequiredFieldsFilledIn = RequiredFieldsFilledIn Or ValueIsFilled(SpreadsheetDocument.Area(Area).Text);
		If RequiredFieldsFilledIn Then
			Break;
		EndIf; 
	EndDo; 
	
	If Not RequiredFieldsFilledIn Then
		ShowMessageBox(,NStr("vi = 'Cần sao chép các cột vào bảng từ tệp ngoài.';
							|ru = 'Необходимо скопировать колонки в таблицу из внешнего файла.';
							|en = 'You must copy columns to the table from an external file.'; fa = 'You must copy columns to the table from an external file.';
							|it = 'È necessario copiare le colonne nella tabella dal file esterno.';
							|pl = 'Należy skopiować kolumny do tablicy z pliku zewnętrznego.';
							|tr = 'Sütunları harici bir dosyadan tabloya kopyalamanız gerekmektedir.'"));
		Return;
	EndIf;
	
	ClearMessages();
	Status(NStr("vi = 'Đang thực hiện so sánh dữ liệu đã nhập với dữ liệu của cơ sở thông tin. Xin vui lòng chờ trong giây lát...';
				|ru = 'Осуществляется сопоставление введенных данных с данными информационной базы. Пожалуйста подождите...';
				|en = 'Entered data is being mapped with the infobase data. Please wait...'; fa = 'Entered data is being mapped with the infobase data. Please wait...';
				|it = 'Viene eseguita l''associazione dei dati inseriti con i dati del database informatico. Attendere prego...';
				|pl = 'Odbywa się zestawienie wprowadzonych danych z danymi z bazy informacyjnej. Proszę czekać...';
				|tr = 'Girilen veriler infobase''deki verilerle karşılaştırılır. Lütfen bekle...'"),,,PictureLib.Information32);
	CompareTableDocumentDataWithInformationSecurityData();

	Items.Steps.CurrentPage = Items.Step2;
	Items.MoveGoods.DefaultButton = True;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Steps.CurrentPage = Items.Step1;
	Items.FormNext.DefaultButton = True;
	
EndProcedure

&AtClient
Procedure MoveGoods(Command)
	
	ClearMessages();
	
	If ThisIsASalesPlanByCategory Or CheckFilling() Then
		GoodsAddressInStorage = PutProductsInStorage();
		Close(GoodsAddressInStorage);
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.Goods.CurrentData.RowCode = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("Code", New Structure("Products", "Code"));
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPartnerOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsTermsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsBillOfMaterialsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsProductKitOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsProductCategoryOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSalesRankOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CheckLoadLineDataMapping(CurrentRow, ThisForm);
	ConfigureStringDisplayOptions(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CrossTable Then
		
		For Each PeriodString_ In ThisForm.TimeIntervals Do
			If Not PeriodString_.Active_ Then
				Continue;
			EndIf;
			CurrentRow["Price_" + PeriodString_.ColumnName] = CurrentRow["Price"];
		EndDo;
		
		WhenChangingAmountOfRowSum(Object, ThisForm, CurrentRow)
	
	Else
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined And Item.CurrentItem.Name = "GoodsProducts" Then
		FillInSelectionListOfProductCharacteristics(CurrentRow.RowCode);
	ElsIf Item.CurrentItem.Name = "GoodsCharacteristic" Then
		FillInSelectionListOfProductCharacteristics(CurrentRow.RowCode, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingQuantity(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods)
	
EndProcedure

&AtClient
Procedure Attachable_WhenPriceChanges(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Price = Undefined;
	For Each PeriodString_ In ThisForm.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		If Price = Undefined Then
			Price = RowOfGoods["Price_" + PeriodString_.ColumnName];
		ElsIf Price <> RowOfGoods["Price_" + PeriodString_.ColumnName] Then
			Price = 0;
			Break;
		EndIf;
	EndDo;
	RowOfGoods["Price"] = Price;
	
	WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
	
EndProcedure

// Parameters:
//   Item - FormField - 
&AtClient
Procedure Attachable_WhenChangingAmount_(Item)
		
	RowOfGoods = Items.Goods.CurrentData;
	
	ColumnName = StrReplace(Item.Name, "Goods" + "Sum_", "");
	If RowOfGoods["Count_" + ColumnName] > 0 Then
		RowOfGoods["Price"] =  RowOfGoods["Sum_" + ColumnName] / RowOfGoods["Count_" + ColumnName];
	EndIf; 
	
	WhenChangingAmountOfRowSum(Object, ThisForm, RowOfGoods);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsImportedCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseItemVariants");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanByAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanByAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingAmountOfRowSum(Object, Form, RowOfGoods)

	Count = 0;
	Sum = 0;
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Count = Count + RowOfGoods["Count_" + PeriodString_.ColumnName];
		If Form.PlanByAmount Then
			RowOfGoods["Sum_" + PeriodString_.ColumnName] = RowOfGoods["Count_" + PeriodString_.ColumnName] * RowOfGoods["Price_" + PeriodString_.ColumnName];
		Else
			RowOfGoods["Sum_" + PeriodString_.ColumnName] = 0;
		EndIf; 
		
		Sum = Sum + RowOfGoods["Sum_" + PeriodString_.ColumnName];
		
	EndDo;
	
	RowOfGoods.NumberOfPackages 	= Count;
	RowOfGoods.Sum 				= Sum;

	CalculateTotals_(Form, False);

EndProcedure 

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form, CountLines = True)

	Object = Form.Object;
	
	If Not Form.CrossTable Then
	 
		Return;
	
	EndIf; 
	
	Goods = Object.Goods;
	
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Form["Object_" + "Goods" + "Count_" + PeriodString_.ColumnName] = 0;
		Form["Object_" + "Goods" + "Sum_" + PeriodString_.ColumnName] = 0;
		
	EndDo;
	
	For Each TSRow In Goods Do
		If CountLines Then
			TSRow.NumberOfPackages = 0;
			TSRow.Sum = 0;
			Price = Undefined;
		EndIf;
		
		PriceColumnsToUpdate = New Array;
		
		For Each PeriodString_ In Form.TimeIntervals Do
			If Not PeriodString_.Active_ Then
				Continue;
			EndIf;
			
			If CountLines Then
				If Price = Undefined Then
					Price = TSRow["Price_" + PeriodString_.ColumnName];
				ElsIf Price <> TSRow["Price_" + PeriodString_.ColumnName] And TSRow["Price_" + PeriodString_.ColumnName] <> 0 Then
					Price = 0;
				ElsIf Price <> TSRow["Price_" + PeriodString_.ColumnName] 
					And TSRow["Price_" + PeriodString_.ColumnName] = 0 
					And TSRow["Count_" + PeriodString_.ColumnName] = 0 Then
					PriceColumnsToUpdate.Add(PeriodString_.ColumnName);
				EndIf;
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + TSRow["Count_" + PeriodString_.ColumnName];
				TSRow["Sum_" + PeriodString_.ColumnName] = TSRow["Count_" + PeriodString_.ColumnName] * 
					TSRow["Price_" + PeriodString_.ColumnName];
				TSRow.Sum = TSRow.Sum + TSRow["Sum_" + PeriodString_.ColumnName];
			EndIf;
			
			Form["Object_" + "Goods" + "Count_" + PeriodString_.ColumnName] = Form["Object_" + "Goods" + "Count_" + PeriodString_.ColumnName] + TSRow["Count_" + PeriodString_.ColumnName];
			Form["Object_" + "Goods" + "Sum_" + PeriodString_.ColumnName] = Form["Object_" + "Goods" + "Sum_" + PeriodString_.ColumnName] + TSRow["Sum_" + PeriodString_.ColumnName];
			
		EndDo;
		
		If CountLines Then
			TSRow["Price"] = Price;
			If Price > 0 Then
				For Each PriceColumnForUpdates In PriceColumnsToUpdate Do
					TSRow["Price_" + PriceColumnForUpdates] = Price; 
				EndDo;
			EndIf; 
		EndIf;
		
	EndDo; 

EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	If ThisIsASalesPlanByCategory Then
		TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, "ProductCategory,SalesRank,Count");
	Else
		FilterParameters = New Map;
		For Each FilterCriterion In FilterRemainingGoodsByShelfLives Do
			FilterParameters.Insert("Products." + FilterCriterion.Key, FilterCriterion.Value);
		EndDo;
		
		Columns = "Products,Characteristic,ProductsInSet,ItemVariantOfSet,Package,NumberOfPackages,Price,"
			+ ?(FillInPartnerInTabularForm, "Partner,", "")
			+ ?(FillInAgreementInTabularForm, "Terms,", "")
			+ ?(FillInWarehouseInTabularForm, "Warehouse,", "")
			+ ?(ThisIsAnAssemblyDisassemblyPlan, "ProductKit,", "");
		
		TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	EndIf;
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	FillInServiceDetailsForProductRange();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region SearchAndComparisonOfProducts

&AtServer
Procedure CompareTableDocumentDataWithInformationSecurityData()
	
	SelectedProducts.Clear();
	Object.Goods.Clear();
	
	If CrossTable Then
		LineNumber = 3;
	Else
		LineNumber = 2;
	EndIf; 
	
	StringNumber = Format(LineNumber, "NZ=0; NG=0");
	FilledInRequiredField = False;
	For Each RequiredField In RequiredFields Do
		
		FilledInRequiredField = FilledInRequiredField 
			Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + "C" + Format(RequiredField.Value, "NZ=0; NG=0")).Text);
			
		If FilledInRequiredField Then
			Break;
		EndIf; 
	EndDo; 
	
	CachedValues = Undefined;
	RowsToProcess = New Array;
	
	While FilledInRequiredField Do
		
		NewRow = New Structure("RowCode", LineNumber);
		
		For Each KeyValue In TheStructureOfTheSearch Do
			
			Value = Undefined;
			If KeyValue.Value > 0 Then
				
				StringNumber = Format(LineNumber, "NZ=0; NG=0");
				Value = SpreadsheetDocument.Area("R" + StringNumber + "C" + Format(KeyValue.Value, "NZ=0; NG=0")).Text;
				If TypeOf(Value) = Type("String") 
					And (Find(KeyValue.Key,"Count") > 0
					Or StrFind(KeyValue.Key,"Price") > 0
					Or StrFind(KeyValue.Key,"Sum") > 0) Then
					
					Try
						Value = Number(Value);
					Except
						Value = Undefined;
					EndTry;
				ElsIf TypeOf(Value) = Type("String") 
					And StrFind(KeyValue.Key,"Date") > 0 Then
					
					Try
						Value = Date(Right(Value,4) + Mid(Value,4,2) + Left(Value,2)); // Conversion to date for a string of the format "dd.MM.yyyy"
					Except
						Value = Undefined;
					EndTry;
					
				EndIf; 
				
			EndIf; 
			
			NewRow.Insert(KeyValue.Key, Value);
			
		EndDo;
		
		NewRow.Insert("ThereIsUnmappedData", True);
		
		NewLineProducts = Object.Goods.Add();
		FillPropertyValues(NewLineProducts, NewRow);
		
		If FillInPartner Then
			NewLineProducts.Partner = Object.Partner;
		EndIf; 
		
		RowsToProcess.Add(NewLineProducts);
			
		NewLineProducts.ImportedBarcode = StrReplace(NewLineProducts.ImportedBarcode, " ", "");
		
		LineNumber = LineNumber + 1;
		
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		FilledInRequiredField = False;
		For Each RequiredField In RequiredFields Do
			
			FilledInRequiredField = FilledInRequiredField 
			Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + "C" + Format(RequiredField.Value, "NZ=0; NG=0")).Text);
			
			If FilledInRequiredField Then
				Break;
			EndIf;
		EndDo;
		
	EndDo;
	
	StructureOfActions = New Structure;
	If Object.Goods.Total("Count") > 0 Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
	EndIf;
	
	If Not CrossTable And PlanByAmount And Not ValueIsFilled(Object.Goods.Total("Sum")) Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	CompareUploadedDataWithInformationSecurityData();
	
EndProcedure

&AtServer
Procedure InitializeSearchStructure()
	
	TheStructureOfTheSearch = New Structure;
	RequiredFields = New Structure;
	
	ColumnNumber = 1;
	If ThisIsASalesPlanByCategory Then
		TheStructureOfTheSearch.Insert("ImportedProductCategory", ColumnNumber);
		RequiredFields.Insert("ImportedProductCategory", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	Else
		TheStructureOfTheSearch.Insert("ImportedBarcode", ColumnNumber);
		RequiredFields.Insert("ImportedBarcode", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
		TheStructureOfTheSearch.Insert("ImportedCode", ColumnNumber);
		RequiredFields.Insert("ImportedCode", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
		TheStructureOfTheSearch.Insert("DownloadableArticleNumber", ColumnNumber);
		RequiredFields.Insert("DownloadableArticleNumber", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
		TheStructureOfTheSearch.Insert("ImportedProducts", ColumnNumber);
		RequiredFields.Insert("ImportedProducts", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
		If UseItemVariants Then
			TheStructureOfTheSearch.Insert("ImportedCharacteristic", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		EndIf;
	EndIf;
	If FillInPartnerInTabularForm Then
		TheStructureOfTheSearch.Insert("ImportedPartner", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	EndIf; 
	If FillInAgreementInTabularForm Then
		TheStructureOfTheSearch.Insert("ImportedAgreement", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If FillInWarehouseInTabularForm Then
		TheStructureOfTheSearch.Insert("ImportedWarehouse", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If ThisIsAnAssemblyDisassemblyPlan Then
		TheStructureOfTheSearch.Insert("ImportedProductKit", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If PlanType = Enums.TypesOfPlans.ProductionPlan And UseForMaterialsPlanning Then
		TheStructureOfTheSearch.Insert("ImportedSpecification", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	EndIf;
	If ThisIsASalesPlanByCategory And UseCalculationBySalesSpeed Then
		TheStructureOfTheSearch.Insert("ImportedSalesRank", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
	EndIf;
	
	If CrossTable Then
		
		If Not ThisIsASalesPlanByCategory 
			And GetFunctionalOption("UseItemPackages") Then
			TheStructureOfTheSearch.Insert("ImportedPackaging", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		EndIf; 
		
		For Each Period In ThisForm.TimeIntervals Do
			
			If Not Period.Active_ Or Period.ColumnNumber <=0 Then
				Continue;
			EndIf; 
			TheStructureOfTheSearch.Insert("Count_"+ Period.ColumnName, ColumnNumber);
			ColumnNumber = ColumnNumber +1;
			If PlanByAmount Then
				TheStructureOfTheSearch.Insert("Price_"+ Period.ColumnName, ColumnNumber);
				ColumnNumber = ColumnNumber +1;
				TheStructureOfTheSearch.Insert("Sum_"+ Period.ColumnName, ColumnNumber);
				ColumnNumber = ColumnNumber +1;
			EndIf; 
		EndDo;
		 
	Else
		
		If PlanType = Enums.TypesOfPlans.SalesPlan Then
			TheStructureOfTheSearch.Insert("DateOfShipment", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		ElsIf PlanType = Enums.TypesOfPlans.ProductionPlan Then
			TheStructureOfTheSearch.Insert("DateOfProduction", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		ElsIf ThisIsAnAssemblyDisassemblyPlan Then
			TheStructureOfTheSearch.Insert("DateOfReceipt", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		ElsIf PlanType = Enums.TypesOfPlans.PurchasePlan Then
			TheStructureOfTheSearch.Insert("DateOfReceipt", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		EndIf;
		
		TheStructureOfTheSearch.Insert("NumberOfPackages", ColumnNumber);
		ColumnNumber = ColumnNumber +1;
		If Not ThisIsASalesPlanByCategory 
			And GetFunctionalOption("UseItemPackages") Then
			TheStructureOfTheSearch.Insert("ImportedPackaging", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		EndIf; 
		
		If PlanByAmount Then
			TheStructureOfTheSearch.Insert("Price", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
			TheStructureOfTheSearch.Insert("Sum", ColumnNumber);
			ColumnNumber = ColumnNumber +1;
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure CompareUploadedDataWithInformationSecurityData()
	
	If ThisIsASalesPlanByCategory Then
		
		CompareProductCategoriesRatings();
		
	Else
	
		FillInTableOfProducts();
		
		PerformRepeatedBarCodeSearch = True;
		If BarcodeTable.Count() = 0 Then
			
			SearchForBarcodes(); // If we load data for the first time, we search for all rows
			PerformRepeatedBarCodeSearch = False;
			
		EndIf;
		
	EndIf; 
	
	ProcessedLinesUnitRecalculation = New Array; 
	ProcessedRowsRecalculatingAmount = New Array;
	
	For Each TSRow In Object.Goods Do
		
		If Not TSRow.ThereIsUnmappedData Then
			Continue;
		EndIf; 
		
		If Not ThisIsASalesPlanByCategory Then
			FindProductsBasedOnUploadedData(TSRow);
		EndIf;
		
		If TSRow.Count > 0 Then
			ProcessedLinesUnitRecalculation.Add(TSRow);
		EndIf;
		
		If Not ThisIsASalesPlanByCategory And Not CrossTable And PlanByAmount 
			And Not ValueIsFilled(TSRow.Sum) Then
			ProcessedRowsRecalculatingAmount.Add(TSRow);
		EndIf;
		
		CheckLoadLineDataMapping(TSRow, ThisObject);
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesUnitRecalculation,
		StructureOfActions,
		Object.Goods);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsRecalculatingAmount,
		StructureOfActions,
		Object.Goods);
	
	If Not ThisIsASalesPlanByCategory And PerformRepeatedBarCodeSearch Then
	
		SearchForBarcodes(); 
	
	EndIf;
	
	If Not ThisIsASalesPlanByCategory Then
		
		MatchPackages();
		
		MatchPartnerAndAgreement();
		
		MatchWarehouses();
		
		CompareConfigurationOptions();
		If PlanType = Enums.TypesOfPlans.ProductionPlan Then
			MatchSpecifications();
		EndIf;
		FillInServiceDetailsForProductRange();
		
	EndIf;
	
	CalculateTotals_(ThisObject);
	
	ConfigureStringDisplayOptions(ThisObject);
	
EndProcedure

&AtServer
Procedure FindProductsBasedOnUploadedData(TSRow)
	
	LineNumber = TSRow.LineNumber;
	SearchStringCode            = Upper(StrReplace(TSRow.ImportedCode, " ", "")); 
	SearchStringArticle        = Upper(StrReplace(TSRow.DownloadableArticleNumber, " ", "")); 
	SearchStringProducts   = Upper(StrReplace(TSRow.ImportedProducts, " ", ""));
	SearchStringCharacteristic = Upper(StrReplace(TSRow.ImportedCharacteristic, " ", ""));
	
	If ValueIsFilled(TSRow.ImportedBarcode) Then
		
		If Not ValueIsFilled(TSRow.Products) Then
			
			FoundRows = BarcodeTable.FindRows(New Structure("Barcode", TSRow.ImportedBarcode));
			
			If FoundRows.Count() > 0 Then
				FillPropertyValues(TSRow, FoundRows[0]);
			EndIf;
			
		EndIf; 
	ElsIf ValueIsFilled(TSRow.ImportedCode) And ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("Code, NameOfTheSearchFeature", 
			SearchStringCode, 
			SearchStringCharacteristic));
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("Code, FullNameOfCharacteristicSearch", 
				SearchStringCode, 
				SearchStringCharacteristic));
			If FoundRows.Count() = 0 Then
				FoundRows = ProductsTable.FindRows(New Structure("Code", 
					SearchStringCode));
			EndIf;
		EndIf;
		
		For Each FoundRow In FoundRows Do
			SelectedString_ = SelectedProducts.Add();
			SelectedString_.RowCode = LineNumber;
			FillPropertyValues(SelectedString_, FoundRow);
		EndDo;
		
	ElsIf ValueIsFilled(TSRow.DownloadableArticleNumber) And ValueIsFilled(TSRow.ImportedProducts) And ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, NameSearch, NameOfTheSearchFeature", 
			SearchStringArticle, 
			SearchStringProducts,
			SearchStringCharacteristic));
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameSearch, NameOfTheSearchFeature", 
				SearchStringArticle, 
				SearchStringProducts,
				SearchStringCharacteristic));
			If FoundRows.Count() = 0 Then
				FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, NameSearch, FullNameOfCharacteristicSearch", 
					SearchStringArticle, 
					SearchStringProducts,
					SearchStringCharacteristic));
				If FoundRows.Count() = 0 Then
					FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameSearch, FullNameOfCharacteristicSearch", 
						SearchStringArticle, 
						SearchStringProducts,
						SearchStringCharacteristic));
					If FoundRows.Count() = 0 Then
						FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, NameSearch", 
							SearchStringArticle, 
							SearchStringProducts));
						If FoundRows.Count() = 0 Then
							FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameSearch", 
								SearchStringArticle, 
								SearchStringProducts));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, Characteristic, RowCode",FoundRow.Products, FoundRow.Characteristic, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow);
			EndIf;
		EndDo;
		
	ElsIf ValueIsFilled(TSRow.ImportedCode) And Not ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("Code, NameSearch",
			SearchStringCode,
			SearchStringProducts));
		
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("Code, FullNameSearch",
				SearchStringCode,
				SearchStringProducts));
			If FoundRows.Count() = 0 Then
				FoundRows = ProductsTable.FindRows(New Structure("Code", 
					SearchStringCode));
			EndIf;
		EndIf;
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, RowCode",FoundRow.Products, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow,,"Characteristic");
			EndIf;
		EndDo;
		
	ElsIf ValueIsFilled(TSRow.DownloadableArticleNumber) And ValueIsFilled(TSRow.ImportedProducts) And Not ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, NameSearch",
			SearchStringArticle,
			SearchStringProducts));
		
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameSearch",
				SearchStringArticle,
				SearchStringProducts));
			If FoundRows.Count() = 0 Then
				FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch", 
					SearchStringArticle));
			EndIf;
		EndIf;
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, RowCode",FoundRow.Products, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow,,"Characteristic");
			EndIf;
		EndDo;
		
	ElsIf Not ValueIsFilled(TSRow.DownloadableArticleNumber) And ValueIsFilled(TSRow.ImportedProducts) And ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("NameOfTheSearchFeature, NameSearch",
			SearchStringCharacteristic,
			SearchStringProducts));
		
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("NameOfTheSearchFeature, FullNameSearch",
				SearchStringCharacteristic,
				SearchStringProducts));
			If FoundRows.Count() = 0 Then
				FoundRows = ProductsTable.FindRows(New Structure("FullNameOfCharacteristicSearch, NameSearch",
					SearchStringCharacteristic,
					SearchStringProducts));
				If FoundRows.Count() = 0 Then
					FoundRows = ProductsTable.FindRows(New Structure("FullNameOfCharacteristicSearch, FullNameSearch",
						SearchStringCharacteristic,
						SearchStringProducts));
					If FoundRows.Count() = 0 Then
						FoundRows = ProductsTable.FindRows(New Structure("NameSearch", 
							SearchStringProducts));
						If FoundRows.Count() = 0 Then
							FoundRows = ProductsTable.FindRows(New Structure("FullNameSearch", 
								SearchStringProducts));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, Characteristic, RowCode", FoundRow.Products, FoundRow.Characteristic, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow);
			EndIf;
		EndDo;
		
	ElsIf ValueIsFilled(TSRow.DownloadableArticleNumber) And Not ValueIsFilled(TSRow.ImportedProducts) And Not ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch",
			SearchStringArticle));
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, RowCode",FoundRow.Products, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow,,"Characteristic");
			EndIf;
		EndDo;
		
	ElsIf ValueIsFilled(TSRow.DownloadableArticleNumber) And Not ValueIsFilled(TSRow.ImportedProducts) And ValueIsFilled(TSRow.ImportedCharacteristic) Then
			
		FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, NameOfTheSearchFeature",
			SearchStringArticle,
			SearchStringCharacteristic));
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("ProductIDSearch, FullNameOfCharacteristicSearch",
				SearchStringArticle,
				SearchStringCharacteristic));
		EndIf;
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, RowCode",FoundRow.Products, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow);
			EndIf;
		EndDo;
			
	ElsIf Not ValueIsFilled(TSRow.DownloadableArticleNumber) And ValueIsFilled(TSRow.ImportedProducts) And Not ValueIsFilled(TSRow.ImportedCharacteristic) Then
		
		FoundRows = ProductsTable.FindRows(New Structure("NameSearch",
		SearchStringProducts));
		If FoundRows.Count() = 0 Then
			FoundRows = ProductsTable.FindRows(New Structure("FullNameSearch", 
				SearchStringProducts));
		EndIf;
		
		For Each FoundRow In FoundRows Do
			PreviouslySelectedProducts = SelectedProducts.FindRows(New Structure("Products, RowCode",FoundRow.Products, LineNumber));
			If PreviouslySelectedProducts.Count() = 0 Then
				SelectedString_ = SelectedProducts.Add();
				SelectedString_.RowCode = LineNumber;
				FillPropertyValues(SelectedString_, FoundRow,,"Characteristic");
			EndIf;
		EndDo;
	EndIf;
	
	ArrayOfSelectedProducts = SelectedProducts.FindRows(New Structure("RowCode", LineNumber));
	
	If ArrayOfSelectedProducts.Count() = 1 Then
		FillPropertyValues(TSRow, ArrayOfSelectedProducts.Get(0));
	Else
		TSRow.RowCode = TSRow.LineNumber;
	EndIf;
	
EndProcedure
 
&AtServer
Procedure SearchForBarcodes()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.ImportedBarcode,
	|	Goods.RowCode
	|INTO Barcodes
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.ImportedBarcode <> """"
	|	AND Goods.Products = VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	Barcodes.RowCode,
	|	ItemsBarcodes.Barcode AS Barcode,
	|	ItemsBarcodes.Products AS Products,
	|	ItemsBarcodes.Characteristic AS Characteristic,
	|	ItemsBarcodes.Package AS Package
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		INNER JOIN Barcodes AS Barcodes
	|		ON ItemsBarcodes.Barcode = Barcodes.ImportedBarcode
	|WHERE
	|	&TextOfProductSelectionCriteria
	|";
	
	TextOfProductSelectionCriteria = "TRUE";
	
	If ValueIsFilled(FilterRemainingGoodsByShelfLives) Then
		Conditions = New Array;
		
		For Each Filter In FilterRemainingGoodsByShelfLives Do
			Conditions.Add(StrTemplate("ItemsBarcodes.Products.%1 IN (&%2)", Filter.Key, Filter.Key));
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
		
		TextOfProductSelectionCriteria = StrConcat(Conditions, Chars.LF + Chars.Tab + "And ");
	EndIf;
	
	Query.Text = StrReplace(Query.Text,"&TextOfProductSelectionCriteria", TextOfProductSelectionCriteria);
	
	Query.SetParameter("Goods", Object.Goods.Unload());
	
	Result = Query.Execute();
	FoundBarcodes = Result.Unload();
	
	For Each FoundBarcode In FoundBarcodes Do
		FoundRows = Object.Goods.FindRows(New Structure("RowCode", FoundBarcode.RowCode));
		
		If FoundRows.Count() > 0 Then
			FillPropertyValues(FoundRows[0], FoundBarcode);
			
			CheckLoadLineDataMapping(FoundRows[0], ThisObject);
		EndIf;
	EndDo;
	
	FoundBarcodes.GroupBy("Barcode, Products, Characteristic, Package","");
	
	If BarcodeTable.Count() = 0 Then
		BarcodeTable.Load(FoundBarcodes);
	Else
		For Each FoundBarcode In FoundBarcodes Do
			FoundRows = BarcodeTable.FindRows(New Structure("Barcode", FoundBarcode.Barcode));
			
			If FoundRows.Count() = 0 Then
				NewRow = BarcodeTable.Add();
				FillPropertyValues(NewRow, FoundBarcode);
			EndIf;
		EndDo;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTableOfProducts()
	
	ProductsTable.Clear();
	
	// Preparing a list of downloadable items to establish selection
	TableOfProductsToUpload = Object.Goods.Unload();
	
	ListOfProductsToDownload = New Array;
	
	If TableOfProductsToUpload.Count() <> 0 Then
		
		Query = New Query("SELECT
			|	DataToImport.LineNumber                                       AS Id,
			|	CAST(DataToImport.ImportedProducts AS STRING(200)) AS Products,
			|	CAST(DataToImport.DownloadableArticleNumber AS STRING(50))       AS SKU,
			|	CAST(DataToImport.ImportedBarcode AS STRING(200))     AS Barcode,
			|	CAST(DataToImport.ImportedCode AS STRING(11))           AS ProductsAndServicesCode
			|INTO TTDownloadableData
			|FROM
			|	&DataToImport AS DataToImport
			|
			|;
			|
			|SELECT DISTINCT
			|	DataToImport.Id AS Id,
			|	Barcodes.Products          AS Products,
			|	Barcodes.Characteristic        AS Characteristic,
			|	Barcodes.Package              AS Package
			|INTO TTBarcodeData
			|FROM
			|	TTDownloadableData AS DataToImport
			|	
			|	INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
			|	ON Barcodes.Barcode = DataToImport.Barcode
			|
			|WHERE
			|	NOT DataToImport.Barcode = """"
			|
			|INDEX BY
			|	Id
			|
			|;
			|
			|SELECT
			|	CatProducts.Id                      AS Id,
			|	MAX(CatProducts.Products)             AS Products,
			|	COUNT(DISTINCT CatProducts.Products) AS QuantityOfProducts
			|FROM
			|	(SELECT
			|		DataToImport.Id AS Id,
			|		CatProducts.Ref          AS Products
			|	FROM
			|		TTDownloadableData AS DataToImport
			|		
			|		LEFT JOIN TTBarcodeData AS BarcodeData_5
			|		ON BarcodeData_5.Id = DataToImport.Id
			|		
			|		INNER JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.SKU = DataToImport.SKU
			|
			|	WHERE
			|		BarcodeData_5.Id IS NULL
			|		AND NOT DataToImport.SKU = """"
			|		AND NOT CatProducts.DeletionMark
			|
			|	UNION ALL
			|
			|	SELECT
			|		DataToImport.Id AS Id,
			|		CatProducts.Ref          AS Products
			|	FROM
			|		TTDownloadableData AS DataToImport
			|		
			|		LEFT JOIN TTBarcodeData AS BarcodeData_5
			|		ON BarcodeData_5.Id = DataToImport.Id
			|		
			|		INNER JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
			|
			|	WHERE
			|		BarcodeData_5.Id IS NULL
			|		AND NOT DataToImport.ProductsAndServicesCode = """"
			|		AND NOT CatProducts.DeletionMark
			|
			|	UNION ALL
			|
			|	SELECT
			|		DataToImport.Id AS Id,
			|		CatProducts.Ref          AS Products
			|	FROM
			|		TTDownloadableData AS DataToImport
			|		
			|		LEFT JOIN TTBarcodeData AS BarcodeData_5
			|		ON BarcodeData_5.Id = DataToImport.Id
			|		
			|		INNER JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.Description = DataToImport.Products
			|
			|	WHERE
			|		BarcodeData_5.Id IS NULL
			|		AND NOT DataToImport.Products = """"
			|		AND NOT CatProducts.DeletionMark
			|
			|	UNION ALL
			|
			|	SELECT DISTINCT
			|		BarcodeData_5.Id AS Id,
			|		BarcodeData_5.Products  AS Products
			|	FROM
			|		TTBarcodeData AS BarcodeData_5
			|	) AS CatProducts
			|
			|GROUP BY
			|	CatProducts.Id
			|
			|HAVING
			|	COUNT(DISTINCT CatProducts.Products) < 2");
		
		Query.SetParameter("DataToImport", TableOfProductsToUpload);
		
		ListOfProductsToDownload = Query.Execute().Unload().UnloadColumn("Products");
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Products.Ref AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	Products.Code AS Code,
	|	Products.SKU AS SKU
	|INTO NomHar
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	NOT Products.IsFolder
	|	AND NOT Products.DeletionMark
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND Products.Ref IN (&SelectionBasedOnProductToUpload)
	|	AND &TextOfSelectionCondition
	|
	|UNION
	|
	|SELECT
	|	Products.Ref,
	|	ItemsCharacteristics.Ref,
	|	Products.Code,
	|	Products.SKU
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (CASE
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN Products.Ref
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN Products.ItemVariantsOwner
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN Products.ProductKind
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|WHERE
	|	Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND NOT Products.DeletionMark
	|	AND NOT ItemsCharacteristics.DeletionMark
	|	AND Products.Ref IN (&SelectionBasedOnProductToUpload)
	|	AND &TextOfSelectionCondition
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NomHar.Code AS Code,
	|	NomHar.SKU AS SKU,
	|	"""" AS ProductIDSearch,
	|	NomHar.Products.Description AS Description,
	|	"""" AS NameSearch,
	|	NomHar.Products.DescriptionFull AS DescriptionFull,
	|	"""" AS FullNameSearch,
	|	NomHar.Products AS Products,
	|	NomHar.Characteristic.Description AS ItemVariantName,
	|	"""" AS NameOfTheSearchFeature,
	|	NomHar.Characteristic.DescriptionFull AS FullNameOfTheCharacteristic_3,
	|	"""" AS FullNameOfCharacteristicSearch,
	|	NomHar.Characteristic AS Characteristic
	|FROM
	|	NomHar AS NomHar";
	
	TextOfSelectionCondition = "TRUE";
	If ValueIsFilled(FilterRemainingGoodsByShelfLives) Then
		
		Conditions = New Array;
		For Each Filter In FilterRemainingGoodsByShelfLives Do
			Conditions.Add(StrTemplate("Products.%1 IN (&%2)", Filter.Key, Filter.Key));
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
		
		TextOfSelectionCondition = StrConcat(Conditions, Chars.LF + Chars.Tab + "And ");;
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text,"&TextOfSelectionCondition", TextOfSelectionCondition);
	
	Query.SetParameter("SelectionBasedOnProductToUpload", ListOfProductsToDownload);
	Query.SetParameter("Goods", Object.Goods.Unload());
	
	Results = Query.ExecuteBatch();
	
	ProductsTable.Load(Results[1].Unload());
	
	For Each CurRow In ProductsTable Do
		CurRow.Code = Upper(StrReplace(CurRow.Code, " ", ""));
		CurRow.ProductIDSearch = Upper(StrReplace(CurRow.SKU, " ", ""));
		CurRow.NameSearch = Upper(StrReplace(CurRow.Description, " ", ""));
		CurRow.FullNameSearch = Upper(StrReplace(CurRow.DescriptionFull, " ", ""));
		CurRow.NameOfTheSearchFeature = Upper(StrReplace(CurRow.ItemVariantName, " ", ""));
		CurRow.FullNameOfCharacteristicSearch = Upper(StrReplace(CurRow.FullNameOfTheCharacteristic_3, " ", ""));
	EndDo;
	
EndProcedure

&AtServer
Procedure CompareProductCategoriesRatings()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForComparison.ImportedProductCategory,
	|	DataForComparison.ImportedSalesRank,
	|	DataForComparison.RowCode
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ProductCategories.Ref) AS ProductCategoryLink,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.ProductCategories AS ProductCategories
	|		ON (ProductCategories.Description LIKE DataForComparison.ImportedProductCategory)
	|			AND NOT ProductCategories.IsFolder
	|WHERE
	|	NOT ProductCategories.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(SalesRanks.Ref) AS SalesRatingLink,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.SalesRanks AS SalesRanks
	|		ON (SalesRanks.Description LIKE DataForComparison.ImportedSalesRank)
	|WHERE
	|	NOT SalesRanks.Ref IS NULL 
	|	AND &UseCalculationBySalesSpeed
	|
	|GROUP BY
	|	DataForComparison.RowCode";
	
	Query.SetParameter("DataForComparison", Object.Goods.Unload());
	Query.SetParameter("UseCalculationBySalesSpeed", UseCalculationBySalesSpeed);
	
	QueriesResults = Query.ExecuteBatch();
	
	TableProductCategories = QueriesResults[1].Unload();
	
	If UseCalculationBySalesSpeed Then
		TableSalesRatings = QueriesResults[2].Unload();
	EndIf; 
	
	For Each TableRow In Object.Goods Do 
		
		ProductCategoryLine = TableProductCategories.Find(TableRow.RowCode, "RowCode");
		If ProductCategoryLine <> Undefined Then 
			If ProductCategoryLine.Count = 1 Then 
				TableRow.ProductCategory  = ProductCategoryLine.ProductCategoryLink;
			EndIf;
		EndIf;
		
		SalesRatingLine_ = Undefined;
		If UseCalculationBySalesSpeed Then
			SalesRatingLine_ = TableSalesRatings.Find(TableRow.RowCode, "RowCode");
			If SalesRatingLine_ <> Undefined Then 
				If SalesRatingLine_.Count = 1 Then 
					TableRow.SalesRank  = SalesRatingLine_.SalesRatingLink;
				EndIf;
			EndIf;
		EndIf;
		
		If ProductCategoryLine <> Undefined Or SalesRatingLine_ <> Undefined Then
			CheckLoadLineDataMapping(TableRow, ThisForm);
		EndIf; 
		
	EndDo;
	
EndProcedure

&AtServer
Procedure MatchPartnerAndAgreement()
	
	If Not (FillInPartnerInTabularForm Or FillInAgreementInTabularForm) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForComparison.ImportedPartner,
	|	DataForComparison.Partner,
	|	DataForComparison.ImportedAgreement,
	|	CAST(DataForComparison.RowCode AS NUMBER(15,0)) AS RowCode
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|WHERE
	|	DataForComparison.Partner = VALUE(Catalog.Partners.EmptyRef)
	|	OR DataForComparison.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|	OR DataForComparison.Terms = UNDEFINED
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Partners.Ref) AS Partner,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|INTO DataForPortnerMatching
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON (Partners.Description LIKE DataForComparison.ImportedPartner)
	|WHERE
	|	NOT Partners.Ref IS NULL 
	|	AND DataForComparison.Partner = VALUE(Catalog.Partners.EmptyRef)
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForPortnerMatching.Partner,
	|	DataForPortnerMatching.RowCode,
	|	DataForPortnerMatching.Count
	|FROM
	|	DataForPortnerMatching AS DataForPortnerMatching
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Terms1.Ref) AS Terms,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		INNER JOIN DataForPortnerMatching AS DataForPortnerMatching
	|		ON DataForComparison.RowCode = DataForPortnerMatching.RowCode
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON DataForPortnerMatching.Partner = Terms1.Partner
	|			AND (Terms1.Description LIKE DataForComparison.ImportedAgreement)
	|WHERE
	|	NOT Terms1.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Terms1.Ref) AS Terms,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON DataForComparison.Partner = Terms1.Partner
	|			AND (Terms1.Description LIKE DataForComparison.ImportedAgreement)
	|WHERE
	|	NOT Terms1.Ref IS NULL 
	|	AND DataForComparison.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1";
	
	Query.SetParameter("DataForComparison", Object.Goods.Unload());
	
	If PlanType = Enums.TypesOfPlans.SalesPlan Then
	
		Query.Text = StrReplace(Query.Text, "Catalog.TermsOfPurchaseFromVendors", "Catalog.TermsOfSale");
	
	EndIf; 
	
	QueriesResults = Query.ExecuteBatch();
	
	TablePartners = QueriesResults[2].Unload();
	
	If FillInAgreementInTabularForm Then
		AgreementTable = QueriesResults[3].Unload();
	EndIf; 
	
	For Each TableRow In Object.Goods Do 
		
		PartnerLine = Undefined;
		If FillInPartnerInTabularForm Then
			PartnerLine = TablePartners.Find(TableRow.RowCode, "RowCode");
			If PartnerLine <> Undefined Then 
				TableRow.Partner  = PartnerLine.Partner;
			EndIf;
		EndIf;
		
		LineAgreement = Undefined;
		If FillInAgreementInTabularForm Then
			LineAgreement = AgreementTable.Find(TableRow.RowCode, "RowCode");
			If LineAgreement <> Undefined Then 
				TableRow.Terms  = LineAgreement.Terms;
			EndIf;
		EndIf;
		
		If PartnerLine <> Undefined Or LineAgreement <> Undefined Then
			CheckLoadLineDataMapping(TableRow, ThisForm);
		EndIf; 
		
	EndDo;
EndProcedure

&AtServer
Procedure MatchPackages()
	
	If Not GetFunctionalOption("UseItemPackages") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForComparison.ImportedPackaging,
	|	CAST(DataForComparison.Products AS Catalog.Products) AS Products,
	|	CAST(DataForComparison.RowCode AS NUMBER(15,0)) AS RowCode
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|WHERE
	|	DataForComparison.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND DataForComparison.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ProductPackages.Ref) AS Package,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (DataForComparison.Products = ProductPackages.Owner
	|			OR DataForComparison.Products.PackagingGroup = ProductPackages.Owner)
	|			AND (ProductPackages.Description LIKE DataForComparison.ImportedPackaging)
	|WHERE
	|	NOT ProductPackages.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1";
	
	Query.SetParameter("DataForComparison", Object.Goods.Unload());
	
	QueriesResults = Query.ExecuteBatch();
	
	PackingTable = QueriesResults[1].Unload();
	
	For Each TableRow In Object.Goods Do 
		
		StringPacking = PackingTable.Find(TableRow.RowCode, "RowCode");
		If StringPacking <> Undefined Then 
			TableRow.Package  = StringPacking.Package;
			CheckLoadLineDataMapping(TableRow, ThisForm);
		EndIf;
		
	EndDo;
EndProcedure

&AtServer
Procedure MatchWarehouses()
	
	If Not FillInWarehouseInTabularForm Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForComparison.ImportedWarehouse,
	|	CAST(DataForComparison.RowCode AS NUMBER(15, 0)) AS RowCode
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|WHERE
	|	DataForComparison.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Warehouses.Ref) AS Warehouse,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON (Warehouses.Description LIKE DataForComparison.ImportedWarehouse)
	|			AND (NOT Warehouses.IsFolder)
	|WHERE
	|	NOT Warehouses.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1";
	
	Query.SetParameter("DataForComparison", Object.Goods.Unload());
	
	QueriesResults = Query.ExecuteBatch();
	
	TableWarehouses_ = QueriesResults[1].Unload();
	
	For Each TableRow In Object.Goods Do 
		
		WarehouseLine = TableWarehouses_.Find(TableRow.RowCode, "RowCode");
		If WarehouseLine <> Undefined Then 
			TableRow.Warehouse  = WarehouseLine.Warehouse;
			CheckLoadLineDataMapping(TableRow, ThisForm);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CompareConfigurationOptions()
	
	If Not ThisIsAnAssemblyDisassemblyPlan Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForComparison.ImportedProductKit,
	|	CAST(DataForComparison.Products AS Catalog.Products) AS Products,
	|	CAST(DataForComparison.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(DataForComparison.RowCode AS NUMBER(15, 0)) AS RowCode
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|WHERE
	|	DataForComparison.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ProductKitConfigurations.Ref) AS ProductKit,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = DataForComparison.Products)
	|			AND (ProductKitConfigurations.Characteristic = DataForComparison.Characteristic)
	|			AND (ProductKitConfigurations.Description LIKE DataForComparison.ImportedProductKit)
	|WHERE
	|	NOT ProductKitConfigurations.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1";
	
	Query.SetParameter("DataForComparison", Object.Goods.Unload());
	
	QueriesResults = Query.ExecuteBatch();
	
	TableConfigurationOptions = QueriesResults[1].Unload();
	
	For Each TableRow In Object.Goods Do 
		
		StringConfigurationOption = TableConfigurationOptions.Find(TableRow.RowCode, "RowCode");
		If StringConfigurationOption <> Undefined Then 
			TableRow.ProductKit  = StringConfigurationOption.ProductKit;
			CheckLoadLineDataMapping(TableRow, ThisForm);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure MatchSpecifications()
	
	If Not UseForMaterialsPlanning Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForComparison.ImportedSpecification,
	|	CAST(DataForComparison.Products AS Catalog.Products) AS Products,
	|	CAST(DataForComparison.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(DataForComparison.RowCode AS NUMBER(15, 0)) AS RowCode
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|WHERE
	|	DataForComparison.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(BillsOfMaterials.Ref) AS BillOfMaterials,
	|	DataForComparison.RowCode,
	|	COUNT(DataForComparison.RowCode) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS BillsOfMaterials
	|		ON (BillsOfMaterials.Products = DataForComparison.Products)
	|			AND (BillsOfMaterials.Characteristic = DataForComparison.Characteristic)
	|			AND (BillsOfMaterials.Ref.Status = VALUE(Enum.BOMStatuses.Valid))
	|			AND (NOT BillsOfMaterials.Ref.DeletionMark)
	|			AND (&ProductionStart = DATETIME(1, 1, 1)
	|				OR (BillsOfMaterials.Ref.ValidOnDate = DATETIME(1, 1, 1)
	|					OR BillsOfMaterials.Ref.ValidOnDate <= &ProductionStart)
	|					AND (BillsOfMaterials.Ref.ValidToDate = DATETIME(1, 1, 1)
	|						OR BillsOfMaterials.Ref.ValidToDate >= &ProductionStart))
	|			AND (NOT BillsOfMaterials.Ref.IsFolder)
	|			AND (BillsOfMaterials.Ref.Description LIKE DataForComparison.ImportedSpecification
	|				OR DataForComparison.ImportedSpecification LIKE """")
	|WHERE
	|	NOT BillsOfMaterials.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.RowCode
	|
	|HAVING
	|	COUNT(DataForComparison.RowCode) = 1";
	
	Query.SetParameter("DataForComparison", Object.Goods.Unload());
	Query.SetParameter("ProductionStart", BeginOfPeriod);
	
	QueriesResults = Query.ExecuteBatch();
	
	SpecificationTable = QueriesResults[1].Unload();
	
	For Each TableRow In Object.Goods Do 
		
		StringSpecification = SpecificationTable.Find(TableRow.RowCode, "RowCode");
		If StringSpecification <> Undefined Then 
			TableRow.BillOfMaterials  = StringSpecification.BillOfMaterials;
			CheckLoadLineDataMapping(TableRow, ThisForm);
		EndIf;
		
	EndDo;
	
EndProcedure
#EndRegion

#Region Other

&AtServer
Procedure InitializeTableDocument()
	
	TemplateSuffix = ?(CrossTable, "Cross", "");
	
	If CrossTable Then
		TemplateName = "DataImportTemplateForPlansCross"; 
	Else
		TemplateName = "DataImportTemplateForPlans"; 
	EndIf;
	
	FillingTemplateBasedOnExternalSource = DataProcessors.ImportGoodsFromExternalFiles.GetTemplate(TemplateName);
	SpreadsheetDocument.Clear();
	
	If ThisIsASalesPlanByCategory Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("ProductCategory");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	Else
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Barcode");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Code");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("SKU");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Products");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		If UseItemVariants Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Characteristic");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		EndIf;
	EndIf;
	
	If FillInPartnerInTabularForm Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Partner");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf; 
	If FillInAgreementInTabularForm Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Terms");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If FillInWarehouseInTabularForm Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Warehouse");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If ThisIsAnAssemblyDisassemblyPlan Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("ProductKit");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If PlanType = Enums.TypesOfPlans.ProductionPlan And UseForMaterialsPlanning Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("BillOfMaterials");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	If ThisIsASalesPlanByCategory And UseCalculationBySalesSpeed Then
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("SalesRank");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
	EndIf;
	
	If CrossTable Then
		
		If Not ThisIsASalesPlanByCategory 
			And GetFunctionalOption("UseItemPackages") Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Package");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		EndIf; 
		
		If PlanByAmount Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("QuantityPriceAmount");
		Else
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Count");
		EndIf;
		
		ThisFormIsPeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		For Each Period In ThisFormIsPeriods Do
		
			If Not Period.Active_ Or Period.ColumnNumber <= 0 Then
				Continue;
			EndIf; 
			
			ScopeOfApplication_10.Parameters.PeriodHeader = Period.Title;
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		
		EndDo; 
		SpreadsheetDocument.FixedTop = 2;
	
	Else
		
		If PlanType = Enums.TypesOfPlans.SalesPlan Or ThisIsASalesPlanByCategory Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("DateOfShipment");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		ElsIf PlanType = Enums.TypesOfPlans.ProductionPlan Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("DateOfProduction");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		ElsIf ThisIsAnAssemblyDisassemblyPlan Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("DateOfReceipt");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		ElsIf PlanType = Enums.TypesOfPlans.PurchasePlan Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("DateOfReceipt");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		EndIf;
		
		ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Count");
		SpreadsheetDocument.Join(ScopeOfApplication_10);
		If Not ThisIsASalesPlanByCategory 
			And GetFunctionalOption("UseItemPackages") Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Package");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		EndIf; 
		If PlanByAmount Then
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Price");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
			ScopeOfApplication_10 = FillingTemplateBasedOnExternalSource.GetArea("Sum");
			SpreadsheetDocument.Join(ScopeOfApplication_10);
		EndIf;
		
		SpreadsheetDocument.FixedTop = 1;
		
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckLoadLineDataMapping(LoadingString, Form)
	
	If LoadingString = Undefined Then
		Return;
	EndIf; 
	
	LoadingString.ThereIsUnmappedData = False;
	
	If Form.TheStructureOfTheSearch.Property("ImportedProducts") 
		And ValueIsFilled(LoadingString.ImportedProducts) 
		And Not ValueIsFilled(LoadingString.Products) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	
	If Form.TheStructureOfTheSearch.Property("ImportedCharacteristic") 
		And ValueIsFilled(LoadingString.ImportedCharacteristic) 
		And Not ValueIsFilled(LoadingString.Characteristic) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf; 
	
	If Form.TheStructureOfTheSearch.Property("ImportedPackaging") 
		And ValueIsFilled(LoadingString.ImportedPackaging) 
		And Not ValueIsFilled(LoadingString.Package) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf; 
	
	If Form.FillInPartnerInTabularForm 
		And Form.TheStructureOfTheSearch.Property("ImportedPartner") 
		And ValueIsFilled(LoadingString.ImportedPartner) 
		And Not ValueIsFilled(LoadingString.Partner) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf; 
	
	If Form.FillInAgreementInTabularForm
		And Form.TheStructureOfTheSearch.Property("ImportedAgreement") 
		And ValueIsFilled(LoadingString.ImportedAgreement) 
		And Not ValueIsFilled(LoadingString.Terms) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	
	If Form.FillInWarehouseInTabularForm
		And Form.TheStructureOfTheSearch.Property("ImportedWarehouse") 
		And ValueIsFilled(LoadingString.ImportedWarehouse) 
		And Not ValueIsFilled(LoadingString.Warehouse) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	If Form.UseForMaterialsPlanning
		And Form.TheStructureOfTheSearch.Property("ImportedSpecification") 
		And ValueIsFilled(LoadingString.ImportedSpecification) 
		And Not ValueIsFilled(LoadingString.BillOfMaterials) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	If Form.ThisIsAnAssemblyDisassemblyPlan
		And Form.TheStructureOfTheSearch.Property("ImportedProductKit") 
		And ValueIsFilled(LoadingString.ImportedProductKit) 
		And Not ValueIsFilled(LoadingString.ProductKit) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	
	If Form.ThisIsASalesPlanByCategory
		And Form.TheStructureOfTheSearch.Property("ImportedProductCategory") 
		And ValueIsFilled(LoadingString.ImportedProductCategory) 
		And Not ValueIsFilled(LoadingString.ProductCategory) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	
	If Form.ThisIsASalesPlanByCategory
		And Form.TheStructureOfTheSearch.Property("ImportedSalesRank") 
		And ValueIsFilled(LoadingString.ImportedSalesRank) 
		And Not ValueIsFilled(LoadingString.SalesRank) Then
		LoadingString.ThereIsUnmappedData = True;
		Return;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtClient
Procedure FillInSelectionListOfProductCharacteristics(CurLineCode, ListOfCharacteristics = False)
	
	If ListOfCharacteristics Then
		TrackSelectionList = Items.GoodsCharacteristic.ChoiceList;
		TrackSelectionList.Clear();
	Else
		ProductSelectionList  = Items.GoodsProducts.ChoiceList;
		ProductSelectionList.Clear();
	EndIf;
	
	ArrayOfSelectedProducts = SelectedProducts.FindRows(New Structure("RowCode", CurLineCode));
	For Each ArrayElement In ArrayOfSelectedProducts Do
		If ListOfCharacteristics Then
			If TrackSelectionList.FindByValue(ArrayElement.Characteristic) = Undefined Then
				TrackSelectionList.Add(ArrayElement.Characteristic);
			EndIf;
		Else
			If ProductSelectionList.FindByValue(ArrayElement.Products) = Undefined Then
				ProductSelectionList.Add(ArrayElement.Products);
			EndIf;
		EndIf;
	EndDo; 
EndProcedure

&AtServer
Function PutProductsInStorage()

	Return PutToTempStorage(Object.Goods.Unload());

EndFunction

&AtClientAtServerNoContext
Procedure ConfigureStringDisplayOptions(Form)
	
	ChoiceList = Form.Items.LineDisplayOption.ChoiceList;
	ChoiceList.Clear();
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tất cả (%1)';
			|ru = 'Все (%1)';
			|en = 'All (%1)'; fa = 'All (%1)';
			|it = 'Tutti (%1)';
			|pl = 'Wszytskie (%1)';
			|tr = 'Tümü (%1)'"), 
		Form.Object.Goods.Count());
		
	ChoiceList.Add(0, Presentation); 
	
	RowsHaveUnmappedData = Form.Object.Goods.FindRows(New Structure("ThereIsUnmappedData", True));
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa so sánh (%1)';
			|ru = 'Несопоставленные (%1)';
			|en = 'Unmapped (%1)'; fa = 'Unmapped (%1)';
			|it = 'Non mappati (%1)';
			|pl = 'Niedopasowane (%1)';
			|tr = 'Eşleşmeyenler (%1)'"), 
		RowsHaveUnmappedData.Count());
		
	ChoiceList.Add(1, Presentation);
	
EndProcedure

&AtServer
Procedure SetColumnAvailability()
	
	Items.GroupUploadedData.Visible = Not ThisIsASalesPlanByCategory;
	Items.GoodsProductsCode.Visible = Not ThisIsASalesPlanByCategory;
	Items.GoodsSKU.Visible = Not ThisIsASalesPlanByCategory;
	Items.GoodsProducts.Visible = Not ThisIsASalesPlanByCategory;
	Items.GoodsGroupCharacteristics.Visible = Not ThisIsASalesPlanByCategory;
	Items.GroupUploadedData.Visible = Not ThisIsASalesPlanByCategory;
	
	Items.GoodsGroupPartner.Visible = FillInPartnerInTabularForm;
	Items.GoodsGroupAgreement.Visible = FillInAgreementInTabularForm;
	Items.ProductsSupplierAgreement.Visible = PlanType = Enums.TypesOfPlans.PurchasePlan And FillInAgreementInTabularForm;
	Items.GoodsCustomerAgreement.Visible = PlanType = Enums.TypesOfPlans.SalesPlan And FillInAgreementInTabularForm;
	
	Items.GoodsGroupWarehouse.Visible = FillInWarehouseInTabularForm;
	Items.GoodsGroupSpecification.Visible = (PlanType = Enums.TypesOfPlans.ProductionPlan) And UseForMaterialsPlanning;
	Items.GoodsGroupProductKit.Visible = ThisIsAnAssemblyDisassemblyPlan;
	
	Items.GoodsGroupProductCategory.Visible = ThisIsASalesPlanByCategory;
	Items.GoodsSalesRankGroup.Visible = ThisIsASalesPlanByCategory And UseCalculationBySalesSpeed;
	
	Items.GoodsGroupPackaging.Visible = Not ThisIsASalesPlanByCategory;
	
	Items.GoodsPrice.Visible = PlanByAmount;
	Items.GoodsSum.Visible = PlanByAmount;
	
	Items.GoodsSum.Enabled = Not CrossTable;
	Items.GoodsNumberOfPackages.Enabled = Not CrossTable;
	
	Items.GoodsDateOfReceipt.Visible = Not CrossTable And PlanType = Enums.TypesOfPlans.PurchasePlan;
	Items.GoodsDateOfReceipt.Visible = Not CrossTable And ThisIsAnAssemblyDisassemblyPlan;
	
	Items.GoodsDateOfShipment.Visible = Not CrossTable And PlanType = Enums.TypesOfPlans.SalesPlan;
	Items.GoodsDateOfProduction.Visible = Not CrossTable And PlanType = Enums.TypesOfPlans.ProductionPlan;
EndProcedure

#EndRegion

#EndRegion
