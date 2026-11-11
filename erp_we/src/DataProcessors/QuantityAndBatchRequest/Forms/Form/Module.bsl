#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Products) Then
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Данная форма не предназначена для непосредственного открытия.';
					|en = 'This form is not intended for direct opening.'; fa = 'This form is not intended for direct opening.';
					|it = 'Questo modulo non destinato per l''apertura diretta.';
					|pl = 'Ten formularz nie jest przeznaczony do bezpośredniego otwarcia.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'");
	EndIf;
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	FillingData  = ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm(False);
	FillPropertyValues(FillingData,  Parameters);
	
	// In an unwritten document, the assignment is empty, and the algorithms for obtaining the remainder count on the filled one.
	If KeyParameters.SelectGoods And Not ValueIsFilled(FillingData.Purpose) Then
		FillingData.Purpose = Catalogs.Assignments.GetRef();
	EndIf;
	
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.Fill(KeyParameters, FillingData);
	
	DataProcessors.QuantityAndBatchRequest.CheckFilling(Object);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	If TypeOf(FillingData.Warehouses) = Type("Array") Then
		Warehouses.LoadValues(FillingData.Warehouses);
	EndIf;

	// Initialization of form details, for interactive user work.
	CurDetails_ = DataProcessors.QuantityAndBatchRequest.CurDetails_(Object);
	
	CurrentProducts          = CurDetails_.Products;
	CurrentCharacteristic        = CurDetails_.Characteristic;
	CurrentPackaging              = CurDetails_.Package;
	CurrentProductIndexForFilter = CurDetails_.ProductIndexForSelection;
	
	TheDisplayOfGoods = "ResidualsAndGraph";
	If Object.SupplyOption = Enums.SupplyOptions.Ship
			Or Object.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
			TheDisplayOfGoods = "AvailableStock";
	EndIf;
	
	OnlyWarehousesOfTheSelectedGroup = True;
	
	SeriesDisplayMode       = "AvailableStock";
	DiscountOption = "DISCOUNT";
	
	MaxDiscountPercentage   = 0;
	MaxMarkupPercentage  = 0;
	If IsTempStorageURL(Parameters.AddressInTempStorage) Then
		TableStructure = GetFromTempStorage(Parameters.AddressInTempStorage);
		MaxDiscountPercentage  = TableStructure.Restrictions[0].MaximumPercentageForManualDiscount;
		MaxMarkupPercentage = TableStructure.Restrictions[0].MaximumPercentageForManualMarkup;
	EndIf;
	
	ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
	RoundUpTheQuantity = RoundUpTheQuantity();
	
	If KeyParameters.SelectGoods And KeyParameters.SelectSupplyOptions Then
		
		AcceptableSecurityOptions = ProvisionInDocumentsClientServer.AcceptableSecurityOptions(
			ItemsType,
			Parameters.AcceptableSeparateActions,
			Parameters.AllowedNonIsolatedActions,
			KeyParameters.LimitSupplyOptions,
			Parameters.SecurityOptionAndFlagSeparately);
			
	EndIf;
	
	CalculateUnitOfMeasurement();
	If Object.DocumentRowIndex > -1 Then
		
		Items.Goods.CurrentRow = Object.Goods[Object.DocumentRowIndex].GetID();
		ManagingFormElementsWhenCreatingAndChangingProps(Items.ToSeriesSpecification); // initialization of series elements
		ManagingFormElementsWhenCreatingAndChangingProps(Items.ToActionSelection);
		DataProcessors.QuantityAndBatchRequest.FillInSeriesForProductsLine(
			ThisObject,
			KeyParameters,
			Object.DocumentRowIndex,
			Parameters.SeriesSpecificationParameters);
			
		DocumentLine = Object.Goods[Object.DocumentRowIndex];
		
		QuantityIsSelected = Object.NumberOfPackages;
		If DocumentLine.CheckAvailability
				And KeyParameters.Mode = ProvisionInDocumentsClientServer.ActionSelectionMode() Then
				
			AvailableByLine = Min(DocumentLine.InStock, Object.NumberOfPackages);
			If AvailableByLine < Object.NumberOfPackages Then  
				
				PackagingFactor = PackagingFactor(Object.Package, Object.Products);  
				
				CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
				CheckParameters.TSName = "Object";
				StructureObject = New Structure();
				StructureObject.Insert("Products", Object.Products);
				StructureObject.Insert("Package", Object.Package);
				StructureObject.Insert("Count", AvailableByLine * PackagingFactor);
				StructureObject.Insert("NumberOfPackages", Object.NumberOfPackages);
				RoundingIsIncorrect = ProductsServer.LineNumbersWithIncorrectRoundingOfQuantity(
					StructureObject,
					CheckParameters);
				If RoundingIsIncorrect.Count() = 0 Then
					AvailableByLine = Object.NumberOfPackages;
				EndIf;
				
			EndIf;
			QuantityIsSelected = Max(AvailableByLine, Object.QuantityRegistered);
			
		EndIf;
		
		DocumentLine.Selected            = QuantityIsSelected;
		DocumentLine.PickedBeforeChange = QuantityIsSelected;
		
		ArrayOfSeries = New Array();
		If TypeOf(FillingData.Series) = Type("Array") Then
			ArrayOfSeries = FillingData.Series;
		ElsIf Not FillingData.Series.IsEmpty() Then
			ArrayOfSeries.Add(New Structure("Series,Count", FillingData.Series, Object.NumberOfPackages));
		EndIf;
		
		For Each StructureSeries In ArrayOfSeries Do
			
			FoundRows = Object.SetOfSeries.FindRows(New Structure("Series", StructureSeries.Series));
			If FoundRows.Count() > 0 Then
				RowSeries = FoundRows[0];
				RowSeries.Selected = StructureSeries.Count * UnitOfMeasurementCoefficient;
			EndIf;
			
		EndDo;
		
		RecalculateSeriesIndicationStatus(Object, DocumentLine, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		
	EndIf;
	
	If Object.ItemKitConfiguration.IsEmpty() Then
		DataProcessors.QuantityAndBatchRequest.RecalculateLeftoversInPackage(Object.Goods, CurrentPackaging, CurrentProducts, CurrentCharacteristic);
	EndIf;
	
	ManagingFormElementsDuringCreation();
	
	If Parameters.SeriesSelection_3 Then
		ToSpecifySeriesOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	ClearMessages();
	NumberOfPackagesWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	ClearMessages();
	PackagingWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	ClearMessages();
	QuantityWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure SwitchApartOnChange(Item)
	
	SwitchApartWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ActionOnChange(Item)
	
	ActionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ActionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PriceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("Number") Then
		
		Object.PriceKind = Undefined;
		PriceKindPresentation = NStr("vi = '<tùy ý>';
									|ru = '<произвольная>';
									|en = '<custom>'; fa = '<سفارشی>';
									|it = '<arbitraria>';
									|pl = '<dowolny>';
									|tr = '<isteğe bağlı>'");
		
	Else
		
		StandardProcessing = False;
		
		Object.PriceKind = ValueSelected;
		PriceKindPresentation = ValueSelected;
		
		For Each String In Object.TypesOfPrices Do
			If String.PriceKind = ValueSelected Then
				Object.Price = String.Price;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	Object.PriceKind = Undefined;
	PriceKindPresentation = NStr("vi = '<tùy ý>';
								|ru = '<произвольная>';
								|en = '<custom>'; fa = '<سفارشی>';
								|it = '<arbitraria>';
								|pl = '<dowolny>';
								|tr = '<isteğe bağlı>'");
	Object.Price = Number(Text);
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	PriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PriceSetOnChange(Item)
	
	PriceSetWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DiscountOptionOnChange(Item)
	
	OptionForGrantingDiscountWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure SeriesDisplayModeOnChange(Item)
	
	ToSpecifySeriesOnServer();
	
EndProcedure

&AtClient
Procedure TheDisplayOfGoodsOnChange(Item)
	
	DisplayModeForProductsWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure OnlyWarehousesOfTheSelectedGroupOnChange(Item)
	
	OnlyWarehousesOfSelectedGroupWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSetComposition

&AtClient
Procedure SetCompositionOnActivateRow(Item)
	
	SetRow = Items.SetComposition.CurrentData;
	If SetRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentProducts <> SetRow.Products
		Or CurrentCharacteristic <> SetRow.Characteristic
		Or CurrentPackaging <> SetRow.Package Then
		
		CurrentProducts   = SetRow.Products;
		CurrentCharacteristic = SetRow.Characteristic;
		CurrentPackaging       = SetRow.Package;
		CurrentProductIndexForFilter = Object.SetComposition.IndexOf(SetRow);
		
		CompositionOfSetWhenActivatingLineOnServer();
		CreateCaptionPickUpSelected(ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	If Field = Items.GoodsBatchesIndicationStatus And CurrentData.BatchesIndicationStatus <> 0 Then
		
		StandardProcessing = False;
		If Not CurrentData.ThisIsSelectedGroupWarehouse Then
			ShowMessageBox(, NStr("vi = 'Dòng này không được dùng để chọn vào chứng từ. Không cần chỉ ra sê-ri.';
									|ru = 'Данная строка недоступна для выбора в документ. Указание серий не требуется.';
									|en = 'This line is not available for selection to the document. The batches are not required.'; fa = 'This line is not available for selection to the document. The batches are not required.';
									|it = 'Questa riga non è disponibile per la selezione nel documento. Non è necessario indicare le serie.';
									|pl = 'Ten wiersz jest niedostępny do wyboru do dokumentu Wskazanie serii nie jest wymagane.';
									|tr = 'Bu satır belgede seçim için kullanılamaz. Partinin belirtilmesi gerekli değildir.'"));
			Return;
		EndIf;
		ToSpecifySeriesOnServer();
		
	ElsIf Field = Items.GoodsInReserve And ValueIsFilled(CurrentData.InReserve) Then
		
		Purpose = ?(CurrentData.WithAssignment And Not ValueIsFilled(CurrentData.Purpose),
			Undefined,
			CurrentData.Purpose);
			
		StandardProcessing = False;
		FormParameters = ProvisionInDocumentsClient.ReserveFormParameters();
		FormParameters.Products = CurrentData.Products;
		FormParameters.Characteristic = CurrentData.Characteristic;
		FormParameters.Warehouse = CurrentData.Warehouse;
		FormParameters.Purpose = Purpose;
		FormParameters.ControlledLotReference = ControlledLotReference;
		FormParameters.ShippingOrders = Parameters.ShippingOrders;
		FormParameters.Package = Object.Package;
		
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form.Reserves",
			FormParameters,
			ThisObject,
			UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	CurrentData = Items.Goods.CurrentData;
	Items.ToSeriesSpecification.Enabled = CurrentData <> Undefined And CurrentData.BatchesIndicationStatus > 0;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "GoodsPictureMoveRight" And Not ReadOnly Then
		
		ClearMessages();
		Item.CurrentItem = Items.GoodsSelected;
		
		LineProducts_ = Items.Goods.CurrentData;
		If LineProducts_ = Undefined Or Not LineProducts_.ThisIsSelectedGroupWarehouse Then
			Return;
		EndIf;
		
		KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
		FillPropertyValues(KeyParameters, Parameters);
		
		QuantityPick = 0;
		
		ReduceDocumentLine = False;
		If KeyParameters.SelectGoods Then
			If Object.ItemKitConfiguration.IsEmpty() Then
				QuantityPick = Object.NumberOfPackages - Object.Goods.Total("Selected");
				If QuantityPick = 0 Then
					QuantityPick = 1;
				EndIf;
			Else
				SetRow = Items.SetComposition.CurrentData;
				QuantityPick = SetRow.QuantityPick - SetRow.QuantityIsSelected;
			EndIf;
		Else
			QuantityPick = Max(Object.NumberOfPackages - Object.Goods.Total("Selected"), 0);
			If QuantityPick = 0 And Object.DocumentRowIndex > -1 Then
				DocumentLine = Object.Goods[Object.DocumentRowIndex];
				If DocumentLine.Selected = Object.Goods.Total("Selected") Then
					QuantityPick = DocumentLine.Selected; 
					ReduceDocumentLine = True;
				EndIf;
			EndIf;
		EndIf;
		If TheDisplayOfGoods = "AvailableStock" And LineProducts_.CheckAvailability Then
			QuantityPick = Min(QuantityPick, LineProducts_.InStock);
		ElsIf TheDisplayOfGoods = "ResidualsAndGraph" And LineProducts_.CheckAvailability Then
			QuantityPick = Min(QuantityPick, LineProducts_.OnSchedule);
		EndIf;
		
		If ReduceDocumentLine Then 
			DocumentLine.Selected = DocumentLine.Selected - QuantityPick;
			DocumentLine.PickedBeforeChange = DocumentLine.Selected;
			RecalculateSeriesIndicationStatus(Object, DocumentLine, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		EndIf;
		
		QuantityPick = AdjustQuantityChange(QuantityPick, LineProducts_);
		
		EditSelected(ThisObject, LineProducts_, QuantityPick, UnitOfMeasurementCoefficient, ThisIsADimensionalUnit, AllowableVariance);
		
		If NeedToUpdateNumberOfSets() Then
			AttachIdleHandler("Attachable_UpdateNumberOfSets", 0.5, True);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelectedOnChange(Item)
	
	ClearMessages();
	LineProducts_ = Items.Goods.CurrentData;
	QuantityPick = LineProducts_.Selected - LineProducts_.PickedBeforeChange;
	LineProducts_.Selected = LineProducts_.PickedBeforeChange;
	QuantityPick = AdjustQuantityChange(QuantityPick, LineProducts_);
	EditSelected(ThisObject, LineProducts_, QuantityPick, UnitOfMeasurementCoefficient, ThisIsADimensionalUnit, AllowableVariance);
	
	If NeedToUpdateNumberOfSets() Then
		UpdateNumberOfSets();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RoundOff(Command)
	
	ClearMessages();
	Object.Count = Round(Object.Count, 0, RoundMode.Round15as20);
	QuantityWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ToSeriesSpecification(Command)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Để thực hiện thao tác, cần chọn dòng trong bảng ""Hàng hóa"".';
								|ru = 'Для выполнения действия нужно выбрать строку в таблице ""Товары"".';
								|en = 'To perform an action, select a row in the ""Goods"" table.'; fa = 'To perform an action, select a row in the ""Goods"" table.';
								|it = 'Per eseguire l''azione selezionare una riga nella tabella ""Merci"".';
								|pl = 'Aby wykonać działanie należy wybrać wiersz w tabeli ""Wiersze pozycji"".';
								|tr = 'Eylemi gerçekleştirmek için ""Ürünler"" tablosunda satır seçilmesi gerekir.'"));
		Return;
	EndIf;
	If Not CurrentData.ThisIsSelectedGroupWarehouse Then
		ShowMessageBox(, NStr("vi = 'Dòng này không được dùng để chọn vào chứng từ. Không cần chỉ ra sê-ri.';
								|ru = 'Данная строка недоступна для выбора в документ. Указание серий не требуется.';
								|en = 'This line is not available for selection to the document. The batches are not required.'; fa = 'This line is not available for selection to the document. The batches are not required.';
								|it = 'Questa riga non è disponibile per la selezione nel documento. Non è necessario indicare le serie.';
								|pl = 'Ten wiersz jest niedostępny do wyboru do dokumentu Wskazanie serii nie jest wymagane.';
								|tr = 'Bu satır belgede seçim için kullanılamaz. Partinin belirtilmesi gerekli değildir.'"));
		Return;
	EndIf;
	
	ClearMessages();
	ToSpecifySeriesOnServer();
	
EndProcedure

&AtClient
Procedure AllocateBalance(Command)
	
	ClearMessages();
	MessageText = Undefined;
	If Not DistributeBalanceOnServer(MessageText) Then
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInByFEFO(Command)
	
	ClearMessages();
	If Not FillInFEFOOnServer() Then
		ShowMessageBox(,NStr("vi = 'Tất cả số lượng hàng hóa đã được phân bổ theo sê-ri.';
							|ru = 'Все количество товара распределено по сериям.';
							|en = 'All quantity of goods is allocated by batch.'; fa = 'All quantity of goods is allocated by batch.';
							|it = 'Tutta la quantità di beni distribuiti per serie.';
							|pl = 'Ogólną ilość towaru rozprowadzono w seriach.';
							|tr = 'Tüm miktarlar partilere göre dağıtılmıştır.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ToActionSelection(Command)
	
	ClearMessages();
	ToSelectActionsOnServer();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	Cancel = False;
	
	If Parameters.SelectGoods And Object.NumberOfPackages = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền số lượng';
										|ru = 'Не заполнено количество';
										|en = 'Quantity is not filled in'; fa = 'Quantity is not filled in';
										|it = 'Quantità non compilata';
										|pl = 'Nie wypełniono ilości';
										|tr = 'Miktar doldurulmadı'"),,"Object.NumberOfPackages",,Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If Items.PagesProductsSeries.CurrentPage = Items.SeriesPage Then
		ToSelectActionsOnServer(Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	SelectedGoods = SelectedGoods();
	
	If Parameters.ItIsForbiddenToSplitStrings Then
		ComplianceOptions = New Map;
		SeriesCount = 0;
		For Each LineProducts_ In SelectedGoods Do
			ComplianceOptions.Insert(LineProducts_.SupplyOption);
			If ValueIsFilled(LineProducts_.Series) Then
				SeriesCount = SeriesCount + 1;
			EndIf;
		EndDo;
		If ComplianceOptions.Count() > 1 Then
			CommonClient.MessageToUser(NStr("vi = 'Đã chọn nhiều phương án đảm bảo, chỉ cho phép chọn một';
											|ru = 'Выбрано несколько вариантов обеспечения, допустимо выбирать только один';
											|en = 'Several supply options have been selected, only one can be selected'; fa = 'Several supply options have been selected, only one can be selected';
											|it = 'Sono state selezionate più opzioni di approvvigionamento, è consentito selezionare solo una';
											|pl = 'Wybrano kilka wariantów zaopatrzenia, dopuszczalne jest wybranie tylko jednego';
											|tr = 'Birkaç tedarik seçeneği seçildi, sadece bir tanesinin seçilmesi kabul edilebilir'"),,,,Cancel);
		EndIf;
		If SeriesCount > 1 And TypeOf(Parameters.Series) <> Type("Array") Then // array in the build order.
			CommonClient.MessageToUser(NStr("vi = 'Đã chọn nhiều sê-ri, chỉ cho phép chọn một';
											|ru = 'Выбрано несколько серий, допустимо выбирать только одну';
											|en = 'Several batches have been selected, only one can be selected'; fa = 'Several batches have been selected, only one can be selected';
											|it = 'Sono state selezionate più serie, è consentito selezionare solo una';
											|pl = 'Wybrano kilka serii, można wybrać tylko jedną';
											|tr = 'Birkaç parti seçildiğinde, yalnızca bir parti seçilmesi kabul edilebilir'"),,,,Cancel);
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	If Not KeyParameters.SelectGoods Then
		
		ParametersForSettingShipmentDates = New Structure("TheShipmentDateOfAllLinesIsASingleDate,DateWhenTheNewLinesWereShipped,FillInDateOfShipmentOfAllLinesWithDateOfNewLines");
		ParametersForSettingShipmentDates.FillInDateOfShipmentOfAllLinesWithDateOfNewLines = False;
		
		If Object.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship") Then
			
			ParametersForSettingShipmentDates.FillInDateOfShipmentOfAllLinesWithDateOfNewLines = True;
			If Parameters.AllLinesOfDocumentAreSelected Then
				For Each Item In SelectedGoods Do
					If Item.SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship") Then
						ParametersForSettingShipmentDates.FillInDateOfShipmentOfAllLinesWithDateOfNewLines = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			ParametersForSettingShipmentDates.TheShipmentDateOfAllLinesIsASingleDate = KeyParameters.TheShipmentDateOfAllLinesIsASingleDate;
			ParametersForSettingShipmentDates.DateWhenTheNewLinesWereShipped = KeyParameters.DateWhenTheNewLinesWereShipped;
			
		EndIf;
		
		Result = New Structure("SelectedGoods,ParametersForSettingShipmentDates",
		SelectedGoods, ParametersForSettingShipmentDates);
		Close(Result);
		
	Else
		
		Close(New Structure("SelectedGoods", SelectedGoods));
		
	EndIf;
	
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure CalculateUnitOfMeasurement()
	UnitOfMeasure = Undefined;
	If Object.ItemKitConfiguration.IsEmpty() Then
		UnitOfMeasure = Object.Package;
	Else
		UnitOfMeasure = CurrentPackaging;
	EndIf;
	If Not ValueIsFilled(UnitOfMeasure) Then
		UnitOfMeasure = Common.ObjectAttributeValue(CurrentProducts, "UnitOfMeasure");
	EndIf;
	UnitOfMeasurementCoefficient = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(UnitOfMeasure, CurrentProducts);
EndProcedure

&AtClient
Procedure Attachable_UpdateNumberOfSets()
	
	UpdateNumberOfSets();
	
EndProcedure

&AtServer
Procedure NumberOfPackagesWhenChangedOnServer()
	
	WhenChangingNumberOfPackagesOrPackagingOnServer();
	ManagingFormElementsWhenCreatingAndChangingProps(Items.NumberOfPackages);
	
EndProcedure

&AtServer
Procedure PackagingWhenModifiedOnServer()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	CurrentPackaging = Object.Package;
	DataProcessors.QuantityAndBatchRequest.RecalculateLeftoversInPackage(Object.Goods, CurrentPackaging, CurrentProducts, CurrentCharacteristic);
	DataProcessors.QuantityAndBatchRequest.PackageOnChange(Object, KeyParameters);
	
	CalculateUnitOfMeasurement();
	
	RoundUpTheQuantity = RoundUpTheQuantity();
	
	WhenChangingNumberOfPackagesOrPackagingOnServer();
	
	If KeyParameters.SelectSeries And Object.Goods.Count() > 0 Then
		
		TableToFillIn_ = Object.Goods;
		AdditionalColumnsForSpecifyingSeries = KeyParameters.AdditionalColumnsForSpecifyingSeries;
		If AdditionalColumnsForSpecifyingSeries <> Undefined Then
			TableToFillIn_ = Object.Goods.Unload(New Array());
			TableToFillIn_.Columns.Add("GoodsIndex");
			For Each AdditionalColumn In AdditionalColumnsForSpecifyingSeries Do
				TableToFillIn_.Columns.Add(AdditionalColumn.Key);
			EndDo;
			For IndexOf = 0 To Object.Goods.Count() - 1 Do
				NewRow = TableToFillIn_.Add();
				FillPropertyValues(NewRow, Object.Goods[IndexOf]);
				FillPropertyValues(NewRow, AdditionalColumnsForSpecifyingSeries);
				NewRow.GoodsIndex = IndexOf;
			EndDo;
		EndIf;
		
		DataProcessors.QuantityAndBatchRequest.FillInStatusOfSeriesIndicationInTable(
			Object.SupplyOption, TableToFillIn_, Parameters.SeriesSpecificationParameters, Object.Goods[0].Warehouse);
		
		If AdditionalColumnsForSpecifyingSeries <> Undefined Then
			For Each String In TableToFillIn_ Do
				Object.Goods[String.GoodsIndex].BatchesIndicationStatus = String.BatchesIndicationStatus;
			EndDo;
		EndIf;
		
	EndIf;
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.Package);
	
EndProcedure

&AtServer
Procedure WhenChangingNumberOfPackagesOrPackagingOnServer()
	
	OldNumberOfPackages = Object.NumberOfPackages;
	
	If Object.ItemKitConfiguration.IsEmpty() Then
		
		PackagingFactor = PackagingFactor(Object.Package, Object.Products);
		Object.Count = Object.NumberOfPackages * PackagingFactor;
		If Object.NumberOfPackages < Object.Goods.Total("Selected") Then
			Object.NumberOfPackages = Object.Goods.Total("Selected");
			Object.Count = Object.NumberOfPackages * PackagingFactor;
		EndIf;
		
	Else
		
		// The quantity will be recalculated.
		CompositionOfSetIsRecalculatedOnServer("COUNT");
		
	EndIf;
	
	If OldNumberOfPackages < Object.NumberOfPackages Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã nhập số lượng đóng gói ít hơn số lượng đã chọn. Đã chọn %1 %2.';
				|ru = 'Введено количество упаковок меньше, чем уже подобрано. Подобрано %1 %2.';
				|en = 'You have entered fewer packaging units than already picked. Picked: %1 %2.'; fa = 'You have entered fewer packaging units than already picked. Picked: %1 %2.';
				|it = 'Numero di pacchi inserito inferiore a quello già selezionato. Selezionato %1 %2.';
				|pl = 'Wprowadzono ilość opakowań mniej, niż już dobrano. Dobrano %1 %2.';
				|tr = 'Girilen paketleme ünitesi sayısı, halihazırda seçilmiş olan paketleme ünitesi sayısından az. Seçildi %1 %2.'"),
			Object.NumberOfPackages,
			?(ValueIsFilled(Object.Package), Object.Package, UnitOfMeasure));
		Common.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtServer
Procedure QuantityWhenChangedOnServer()
	
	OldQuantity = Object.Count;
	
	If Object.ItemKitConfiguration.IsEmpty() Then
		
		PackagingFactor = PackagingFactor(Object.Package, Object.Products);
		Object.NumberOfPackages = Object.Count / PackagingFactor;
		If Object.NumberOfPackages < Object.Goods.Total("Selected") Then
			Object.NumberOfPackages = Object.Goods.Total("Selected");
			Object.Count = Object.NumberOfPackages * PackagingFactor;
		EndIf;
		
	Else
		
		// The quantity will be recalculated on the server.
		CompositionOfSetIsRecalculatedOnServer("NUMBEROFPACKAGES");
		
	EndIf;
	
	If OldQuantity < Object.Count Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã nhập số lượng đóng gói ít hơn số lượng đã chọn. Đã chọn %1 %2.';
				|ru = 'Введено количество упаковок меньше, чем уже подобрано. Подобрано %1 %2.';
				|en = 'You have entered fewer packaging units than already picked. Picked: %1 %2.'; fa = 'You have entered fewer packaging units than already picked. Picked: %1 %2.';
				|it = 'Numero di pacchi inserito inferiore a quello già selezionato. Selezionato %1 %2.';
				|pl = 'Wprowadzono ilość opakowań mniej, niż już dobrano. Dobrano %1 %2.';
				|tr = 'Girilen paketleme ünitesi sayısı, halihazırda seçilmiş olan paketleme ünitesi sayısından az. Seçildi %1 %2.'"),
			Object.NumberOfPackages,
			?(ValueIsFilled(Object.Package), Object.Package, UnitOfMeasure));
		Common.MessageToUser(MessageText);
	EndIf;
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.Count);
	
EndProcedure

&AtServer
Procedure SwitchApartWhenChangingOnServer()
	
	If Items.Action.ChoiceList.FindByValue(Object.SupplyOption) = Undefined Then
		Object.SupplyOption = Items.Action.ChoiceList[0].Value;
		ActionWhenChangingOnServer();
	EndIf;
	ManagingFormElementsWhenCreatingAndChangingProps(Items.SwitchApart);
	
EndProcedure

&AtServer
Procedure DisplayModeForProductsWhenChangedOnServer()
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.TheDisplayOfGoods);
	
EndProcedure

&AtServer
Procedure OnlyWarehousesOfSelectedGroupWhenChangedOnServer()
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.OnlyWarehousesOfTheSelectedGroup);
	
EndProcedure

&AtServer
Procedure ActionWhenChangingOnServer()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	If KeyParameters.SelectSeries Then
		
		LinesForSettingStatusOfSeries = New Array;
		For Each String In Object.Goods Do
			LinesForSettingStatusOfSeries.Add(String);
		EndDo;
		DataProcessors.SelectGoodsToSalesDocument.FillInStatusOfSeriesInLine(
			LinesForSettingStatusOfSeries,
			Parameters.SeriesSpecificationParameters,
			Object.SupplyOption);
		If Object.SupplyOption <> Enums.SupplyOptions.Ship
				And Object.SupplyOption <> Enums.SupplyOptions.FromWarehouse Then
			Object.SetOfSeries.Clear();
		EndIf;
		
	EndIf;
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.Action);
	
EndProcedure

&AtServer
Procedure PriceViewWhenChangedOnServer()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);

	DataProcessors.QuantityAndBatchRequest.PriceKindOnChange(Object, KeyParameters, Warehouses.UnloadValues());
	ManagingFormElementsWhenCreatingAndChangingProps(Items.PriceKind);
	
EndProcedure

&AtServer
Procedure PriceSetWhenChangedOnServer()
	
	DataProcessors.QuantityAndBatchRequest.PriceOnChange(Object, Warehouses.UnloadValues());
	
EndProcedure

&AtServer
Procedure CompositionOfSetWhenActivatingLineOnServer()
	
	CalculateUnitOfMeasurement();
	DataProcessors.QuantityAndBatchRequest.RecalculateLeftoversInPackage(Object.Goods, CurrentPackaging, CurrentProducts, CurrentCharacteristic);
	ManagingFormElementsWhenCreatingAndChangingProps(Items.SetComposition);
	
EndProcedure

&AtServer
Procedure OptionForGrantingDiscountWhenChangingOnServer()
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.DiscountOption);
	
EndProcedure

#EndRegion

#Region WhenChangingQuantity

&AtClient
Function AdjustQuantityChange(QuantityChangeOriginal, LineProducts_)
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	CountUpdate = QuantityChangeOriginal;
	
	LineProducts_ = Items.Goods.CurrentData;
	
	// It cannot be changed to a quantity greater than specified in the document.
	If Not KeyParameters.SelectGoods Then
		
		CountUpdate = Min(CountUpdate, Object.NumberOfPackages - Object.Goods.Total("Selected"));
		If CountUpdate < QuantityChangeOriginal Then
			MessageText = StrTemplate(NStr("vi = 'Đã chỉ ra số lượng lớn hơn cần chọn. Đã thay đổi: %1 %2.';
											|ru = 'Указано количество больше, чем требуется подобрать. Изменено на: %1 %2.';
											|en = 'The specified quantity is more than required to pick. Changed to: %1 %2.'; fa = 'The specified quantity is more than required to pick. Changed to: %1 %2.';
											|it = 'La quantità specificata supera quella necessaria. Modificata in: %1 %2.';
											|pl = 'Wskazano ilość większą, niż trzeba wybrać. Zmieniono na: %1 %2.';
											|tr = 'Belirtilen miktar seçilecek miktardan büyük. Bu şekilde değiştirildi: %1 %2.'"),
				LineProducts_.Selected + CountUpdate, UnitOfMeasure);
			CommonClient.MessageToUser(MessageText,,);
		EndIf;
	EndIf;
	
	// It is impossible to leave a quantity less than issued.
	If Not KeyParameters.SelectGoods
				And LineProducts_.ThisIsDocumentRow Then
		
		QuantityResult = LineProducts_.Selected + CountUpdate;
		NumberAdjustment = -Min(QuantityResult - Object.QuantityRegistered, 0);
		CountUpdate = CountUpdate + NumberAdjustment;
		If NumberAdjustment > 0 Then
			MessageText = StrTemplate(NStr("vi = 'Đã chỉ ra số lượng ít hơn số đã giao. Thay đổi %1 %2.';
											|ru = 'Указано количество меньше чем отгружено. Изменено на %1 %2.';
											|en = 'Quantity specified is less than shipped. Changed to %1 %2.'; fa = 'Quantity specified is less than shipped. Changed to %1 %2.';
											|it = 'La quantità specificata è inferiore a quella spedita. Modificata in %1 %2.';
											|pl = 'Wskazano ilość mniejszą niż wysłano. Zmieniono na %1 %2.';
											|tr = 'Belirtilen miktar sevk edilen miktardan az. %2 %1 olarak değiştirildi.'"),
				LineProducts_.Selected + CountUpdate, UnitOfMeasure);
			CommonClient.MessageToUser(MessageText,,);
		EndIf;
	EndIf;
	
	Return CountUpdate;
	
EndFunction

&AtClientAtServerNoContext
Procedure EditSelected(Form, LineProducts_, CountUpdate, UnitOfMeasurementCoefficient, ThisIsADimensionalUnit, AllowableVariance)
	
	Object    = Form.Object;
	Parameters = Form.Parameters;
	Items  = Form.Items;
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	LineProducts_.Selected = LineProducts_.Selected + CountUpdate;
	LineProducts_.PickedBeforeChange = LineProducts_.Selected;
	
	If KeyParameters.SelectGoods Then
		
		If Object.ItemKitConfiguration.IsEmpty() Then
			
			If Object.NumberOfPackages < Object.Goods.Total("Selected") Then
				
				Object.NumberOfPackages = Object.Goods.Total("Selected");
				PackagingFactor = PackagingFactor(Object.Package, Object.Products);
				Object.Count = Object.NumberOfPackages * PackagingFactor;
				
			EndIf;
			
		Else
			
			SetRow = Object.SetComposition.FindByID(Items.SetComposition.CurrentRow);
			SetRow.QuantityIsSelected = SetRow.QuantityIsSelected + CountUpdate;
			
		EndIf;
		
		RecalculateSeriesIndicationStatus(Object, LineProducts_, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		
	Else
		
		RecalculateSeriesIndicationStatus(Object, LineProducts_, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		
	EndIf;
	
	CreateCaptionPickUpSelected(Form);
	
EndProcedure

&AtServer
Procedure UpdateNumberOfSets()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	If KeyParameters.SelectGoods Then
		
		If Not Object.ItemKitConfiguration.IsEmpty() Then
			
			SetRow = Object.SetComposition.FindByID(Items.SetComposition.CurrentRow);
			If SetRow.QuantityIsSelected > SetRow.QuantityPick Then
				Object.Count = SetRow.QuantityIsSelected / SetRow.NumberOfPackages;
				// The number of packages will be recalculated on the server.
				CompositionOfSetIsRecalculatedOnServer("QUANTITYPICK");
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function NeedToUpdateNumberOfSets()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	If KeyParameters.SelectGoods And Not Object.ItemKitConfiguration.IsEmpty() Then
		
		SetRow = Object.SetComposition.FindByID(Items.SetComposition.CurrentRow);
		
		Return SetRow.QuantityIsSelected > SetRow.QuantityPick;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Procedure CreateCaptionPickUpSelected(Form)
	
	If Form.Object.ItemKitConfiguration.IsEmpty() Then
		
		QuantityPick = Form.Object.NumberOfPackages;
		QuantityIsSelected = Form.Object.Goods.Total("Selected");
		
	Else
		
		CurSetLine = Form.Object.SetComposition.FindByID(Form.Items.SetComposition.CurrentRow);
		QuantityPick = CurSetLine.QuantityPick;
		QuantityIsSelected = CurSetLine.QuantityIsSelected;
		
	EndIf;
	
	FormatString = "NFD=3; NZ=0,000";
	Form.Items.TheInscriptionToPickUpSelected.Title =
		StrTemplate(NStr("vi = 'Cần chọn - %1 %3. Đã chọn - %2 %3';
						|ru = 'Требуется подобрать - %1 %3. Подобрано - %2 %3';
						|en = 'Required to pick %1 %3. Picked - %2 %3'; fa = 'Required to pick %1 %3. Picked - %2 %3';
						|it = 'Necessario selezionare - %1 %3. Selezionato - %2 %3';
						|pl = 'Należy dobrać - %1 %3. Dobrano - %2 %3';
						|tr = 'Seçim gerekli - %1 %3. Seçildi - %2 %3'"),
		Format(QuantityPick, FormatString) ,
		Format(QuantityIsSelected, FormatString) ,
		Form.UnitOfMeasure);
	
	Form.Items.CountByDocument.Title =
		StrTemplate(NStr("vi = '%1 %2.';
						|ru = '%1 %2.';
						|en = '%1 %2.'; fa = '%1 %2.';
						|it = '%1 %2.';
						|pl = '%1 %2.';
						|tr = '%1 %2.'"),
		Format(QuantityPick, FormatString),
		Form.UnitOfMeasure);
	
	Form.Items.QuantityPick.Title =
		StrTemplate(NStr("vi = '%1 %2.';
						|ru = '%1 %2.';
						|en = '%1 %2.'; fa = '%1 %2.';
						|it = '%1 %2.';
						|pl = '%1 %2.';
						|tr = '%1 %2.'"),
		Format(QuantityPick - QuantityIsSelected, FormatString),
		Form.UnitOfMeasure);
	
EndProcedure

&AtServer
Procedure ChangeMatchedWhenChangingSeries(LineProducts_, CountUpdate, UnitOfMeasurementCoefficient)
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	LineProducts_.Selected = LineProducts_.Selected + CountUpdate;
	LineProducts_.PickedBeforeChange = LineProducts_.Selected;
	
	If KeyParameters.SelectGoods Then
		
		If Not Object.ItemKitConfiguration.IsEmpty() Then
			
			SetRow = Object.SetComposition.FindByID(Items.SetComposition.CurrentRow);
			SetRow.QuantityIsSelected = SetRow.QuantityIsSelected + CountUpdate;
			
			If SetRow.QuantityIsSelected > SetRow.QuantityPick Then
				Object.Count = SetRow.QuantityIsSelected / SetRow.Count;
				// The number of packages will be recalculated on the server.
				CompositionOfSetIsRecalculatedOnServer("QUANTITYPICK");
			EndIf;
			
		Else
			
			If Object.NumberOfPackages < Object.Goods.Total("Selected") Then
				Object.NumberOfPackages = Object.Goods.Total("Selected");
				PackagingFactor = PackagingFactor(Object.Package, Object.Products);
				Object.Count = Object.NumberOfPackages * PackagingFactor;
			EndIf;
			
		EndIf;
		
		RecalculateSeriesIndicationStatus(Object, LineProducts_, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		
	Else
		
		If Object.DocumentRowIndex > -1 Then
			
			DocumentLine = Object.Goods[Object.DocumentRowIndex];
			DocumentLine.Selected = DocumentLine.Selected - CountUpdate;
			DocumentLine.PickedBeforeChange = DocumentLine.Selected;
			RecalculateSeriesIndicationStatus(Object, DocumentLine, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		
		EndIf;
		
		RecalculateSeriesIndicationStatus(Object, LineProducts_, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CompositionOfSetIsRecalculatedOnServer(Attribute)
	
	If Attribute = "QUANTITYPICK" Then
		
		PackagingFactor = PackagingFactor(Object.Package, Object.Products);
		Object.NumberOfPackages = Object.Count / PackagingFactor;
		
	ElsIf Attribute = "COUNT" Then
		
		PackagingFactor = PackagingFactor(Object.Package, Object.Products);
		Object.Count = Object.NumberOfPackages * PackagingFactor;
		
	ElsIf Attribute = "NUMBEROFPACKAGES" Then
		
		PackagingFactor = PackagingFactor(Object.Package, Object.Products);
		Object.NumberOfPackages = Object.Count / PackagingFactor;
		
	EndIf;
	
	DataProcessors.QuantityAndBatchRequest.CompositionOfSetRecalculate(Object, Attribute);
	
EndProcedure

&AtServer
Function RoundUpTheQuantity()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	UnitOfMeasurementTypeOfMeasuredValue = "";
	PackagingTypeOfMeasuredValue = "";
	
	UnitMeasuring = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(SeriesUnitOfMeasurement, UnitOfMeasurementTypeOfMeasuredValue);
	PackagingMeasured = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Object.Package, PackagingTypeOfMeasuredValue);
	
	Return KeyParameters.SelectGoods And Not UnitMeasuring And UnitOfMeasurementTypeOfMeasuredValue = "NumberOfPieces" And PackagingMeasured;
	
EndFunction

&AtClientAtServerNoContext
Procedure RecalculateSeriesIndicationStatus(Object, LineProducts_, SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient)
	
	SupplyOption = Object.SupplyOption;
	SetOfSeries = Object.SetOfSeries;
	
	If LineProducts_.BatchesIndicationStatus = 0 Then
		Return;
	EndIf;
	
	GoodsQuantity   = Round(LineProducts_.Selected * UnitOfMeasurementCoefficient, 3);
	SeriesCount     = NumberOfSeriesPerLine(LineProducts_, SetOfSeries);
	
	SeriesAreIndicatedInFull = GoodsQuantity > 0
		And (GoodsQuantity = SeriesCount
			Or ThisIsADimensionalUnit And GoodsQuantity > SeriesCount And GoodsQuantity * (1 - AllowableVariance / 100) <= SeriesCount
			Or ThisIsADimensionalUnit And GoodsQuantity < SeriesCount And GoodsQuantity * (1 + AllowableVariance / 100) >= SeriesCount);
	
	ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
		LineProducts_.BatchesIndicationStatus,
		SeriesAreIndicatedInFull,
		SeriesCount,
		SupplyOption);
	
EndProcedure

&AtClientAtServerNoContext
Function NumberOfSeriesPerLine(LineProducts_, SetOfSeries)
	
	SeriesCount = 0;
	
	If LineProducts_.NumberOfBatchesFirstRow > 0 Then
		
		IndexOfSeriesTable = LineProducts_.NumberOfBatchesFirstRow - 1;
		RowKey = New Structure("Products,Characteristic,Warehouse,Purpose");
		FillPropertyValues(RowKey, SetOfSeries[IndexOfSeriesTable]);
		While IndexOfSeriesTable < SetOfSeries.Count() Do
			
			RowSeries = SetOfSeries[IndexOfSeriesTable];
			If Not TMCommonUseClientServer.StructuresAreEqual(RowKey, RowSeries) Then
				Break;
			EndIf;
			
			SeriesCount = SeriesCount + RowSeries.Selected;
			IndexOfSeriesTable = IndexOfSeriesTable + 1;
			
		EndDo;
		
	EndIf;
	
	Return SeriesCount;
	
EndFunction

#EndRegion

#Region WhenCreating

&AtServer
Procedure ManagingFormElementsDuringCreation()
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	If KeyParameters.TheDisplayOfGoods <> Undefined Then
		TheDisplayOfGoods = KeyParameters.TheDisplayOfGoods;
	EndIf;
	
	If ReadOnly Then
		Items.GoodsPictureMoveRight.Visible = False;
		Items.QuantityPick.Visible = False;
		Items.ProductsGroupSelected.HeaderPicture = New Picture();
		Items.LabelQuantityBefitting.Visible = False;
	EndIf;
	
	// Setting the form header.
	Text = Undefined;
	
	If KeyParameters.SelectGoods Then
		
		Text = NStr("vi = 'Nhập số lượng và giá';
					|ru = 'Ввод количества и цены';
					|en = 'Enter quantity and price'; fa = 'ورود مقدار و قیمت';
					|it = 'Inserimento della quantità e del prezzo';
					|pl = 'Wprowadzanie ilości i ceny';
					|tr = 'Miktar ve fiyat girişi'");
		If KeyParameters.HidePrice Then
			Text = NStr("vi = 'Nhập số lượng';
						|ru = 'Ввод количества';
						|en = 'Enter quantity'; fa = 'ورود مقدار';
						|it = 'Inserimento quantità';
						|pl = 'Wprowadzanie ilości';
						|tr = 'Miktar girin'");
		EndIf;
		
	ElsIf KeyParameters.SeriesSelection_3 Then
		
		Text = NStr("vi = 'Chỉ ra sê-ri';
					|ru = 'Указание серий';
					|en = 'Specify batch'; fa = 'تعیین بچ';
					|it = 'Indicazione della serie';
					|pl = 'Określanie serii';
					|tr = 'Parti belirtme'");
		
	ElsIf KeyParameters.SelectionOfWarehouses Then
		
		Text = HeadingWarehouseSelection();
		
	EndIf;
	
	Title = Text;
	
	// Auxiliary details.
	ProductAttributes = New Array();
	ProductAttributes.Add("ItemsType");
	ProductAttributes.Add("AreaCanBeSpecifiedInDocuments");
	ProductAttributes.Add("VolumeCanBeSpecifiedInDocuments");
	ProductAttributes.Add("YouCanSpecifyWeightInDocuments");
	ProductAttributes.Add("YouCanSpecifyLengthInDocuments");
	ProductAttributes.Add("PackagingGroup");
	
	ProductAttributes = Common.ObjectAttributesValues(
		Object.Products,
		StrConcat(ProductAttributes,","));
	
	UsePackages = ProductAttributes.AreaCanBeSpecifiedInDocuments
		Or ProductAttributes.YouCanSpecifyWeightInDocuments
		Or ProductAttributes.VolumeCanBeSpecifiedInDocuments
		Or ProductAttributes.YouCanSpecifyLengthInDocuments
		Or ValueIsFilled(ProductAttributes.PackagingGroup);
		
	IsRecordsSet = ProductAttributes.ItemsType = Enums.ItemsTypes.Set;
	
	// Packaging settings.
	Items.UnitOfMeasure.Visible = Not UsePackages And Not IsRecordsSet;
	Items.Package.Visible = UsePackages And Not IsRecordsSet;
	Items.UnitOfMeasurementOfSet.Visible = IsRecordsSet;
	
	// Setting the visibility of price indicators.
	Items.GroupTypeOfPricePrice.Visible  = Not KeyParameters.HidePrice;
	Items.PriceKind.ReadOnly       = Not KeyParameters.EditPriceType;
	Items.PriceKind.SkipOnInput   = Not KeyParameters.EditPriceType;
	Items.Price.Enabled             = KeyParameters.EditPriceType;
	Items.SetCompositionPrice.Visible   = Not KeyParameters.HidePrice;
	
	// Setting the visibility of discounts.
	UseRestrictionsOfManualDiscounts = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
		Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	
	Items.GroupParametersDiscountsMarkups.Visible           = KeyParameters.UseDiscountAdjustmentsInSales
	                                                               And Not KeyParameters.HideManualDiscounts;
	Items.LabelMaximumManualDiscount.Visible        = UseRestrictionsOfManualDiscounts;
	Items.LabelMaximumManualDiscount.Title        = StrTemplate(NStr("vi = '%2 Tối đa chiết khấu: %1 %%';
																	|ru = '%2 Макс. скидка: %1%%';
																	|en = '%2 Max. discount: %1%%'; fa = '%2 Max. discount: %1%%';
																	|it = '%2 Sconto massimo: %1%%';
																	|pl = '%2 Maks. zniżka: %1%%';
																	|tr = '%2 Maksimum indirim: %1%%'"), MaxDiscountPercentage);
	Items.LabelMaximumManualMargin.Visible       = UseRestrictionsOfManualDiscounts;
	Items.LabelMaximumManualMargin.Title       = StrTemplate(NStr("vi = '%2 Tối đa phụ thu: %1 %%';
																	|ru = '%2 Макс. наценка: %1%%';
																	|en = '%2 Max. markup: %1%%'; fa = '%2 Max. markup: %1%%';
																	|it = '%2 Мargine massimo: %1%%';
																	|pl = '%2 Maks. marża: %1%%';
																	|tr = '%2 Maksimum zam: %1%%'"), MaxMarkupPercentage);
	Items.CaptionMaximumDiscountIsNotLimited.Visible  = Not UseRestrictionsOfManualDiscounts;
	Items.CaptionTheMaximumMarginIsNotLimited.Visible = Not UseRestrictionsOfManualDiscounts;
	
	// Setting the visibility of the elements of the sets.
	Items.SetComposition.Visible                   = IsRecordsSet;
	Items.GroupInStockAvailableBySet.Visible = IsRecordsSet;
	Items.GroupPriceSet.Visible                = IsRecordsSet;
	Items.GroupPrice.Visible                     = Not IsRecordsSet;
	Items.Action.Visible                       = Not IsRecordsSet;
	Items.SwitchApart.Visible       = Not IsRecordsSet;
	
	// Setting visibility on product pages and series.
	Items.ToActionSelection.Visible = Not KeyParameters.SeriesSelection_3;
	
	// Setting the visibility of the quantity.
	Items.GroupQuantity.Visible          = KeyParameters.SelectGoods;
	Items.TheInscriptionToPickUpSelected.Visible = KeyParameters.SelectGoods;
	
	// Setting the visibility of information about the balances.
	DisplayInformation1 = Not KeyParameters.SelectGoods And Not KeyParameters.SeriesSelection_3;
	Items.GroupPickUpPickedUpProducts.Visible = DisplayInformation1;
	Items.GroupPickUpPickedUpProductsUnitsOfMeasurement.Visible = DisplayInformation1;
	
	// Visibility of the action and the flag "Apart".
	Items.Action.Visible = KeyParameters.SelectGoods
		And KeyParameters.SelectSupplyOptions
		And Not KeyParameters.LimitSupplyOptions;
	Items.SwitchApart.Visible = GetFunctionalOption("UseOrderSupplyWithAssignment")
		And KeyParameters.SelectGoods
		And KeyParameters.SelectSupplyOptions
		And Not KeyParameters.LimitSupplyOptions;
	
	// Visibility and heading of the "Group warehouses only" field.
	If Catalogs.Warehouses.IsFolder(Object.Warehouse) Then
		Items.OnlyWarehousesOfTheSelectedGroup.Title = StrTemplate(Items.OnlyWarehousesOfTheSelectedGroup.Title, Object.Warehouse);
	Else
		Items.OnlyWarehousesOfTheSelectedGroup.Title = StrTemplate(NStr("vi = 'Chỉ kho bãi ""%1""';
																		|ru = 'Только склад ""%1""';
																		|en = 'Warehouse ""%1"" only'; fa = 'Warehouse ""%1"" only';
																		|it = 'Solo magazzino ""%1""';
																		|pl = 'Tylko magazyn ""%1""';
																		|tr = 'Sadece ambar ""%1""'"), Object.Warehouse);
	EndIf;
	
	Items.OnlyWarehousesOfTheSelectedGroup.Visible = Not KeyParameters.SeriesSelection_3
		And ValueIsFilled(Object.Warehouse);
	
	// Setting the current line to the document line.
	If Object.DocumentRowIndex > - 1 Then
		DocumentLine = Object.Goods[Object.DocumentRowIndex];
		Items.Goods.CurrentRow = DocumentLine.GetID();
	EndIf;
	
	If Not KeyParameters.SelectGoods Then
		
		If Object.SupplyOption = Enums.SupplyOptions.FromWarehouse
				Or Object.SupplyOption = Enums.SupplyOptions.Ship Then
				
			Items.TheDisplayOfGoods.ChoiceList.Delete(
				Items.TheDisplayOfGoods.ChoiceList.FindByValue("ResidualsAndGraph"));
			
		EndIf;
		
	EndIf;
	
	If Object.SetComposition.Count() > 0 Then
		Items.SetComposition.CurrentRow = Object.SetComposition[0].GetID();
	EndIf;

	// Setting up elements that should be configured both when creating and when repacking individual elements in the form.
	ManagingFormElementsWhenCreatingAndChangingProps(Undefined);
	
EndProcedure

&AtServer
Procedure ManagingFormElementsWhenCreatingAndChangingProps(Item)
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	If Item = Undefined Or Item = Items.SetComposition  Or Item = Items.Package Then
		
		UnitOfMeasure = Undefined;
		UnitOfMeasurementOfSet = Undefined;
		If Object.ItemKitConfiguration.IsEmpty() Then
			UnitOfMeasure = Object.Package;
		Else
			UnitOfMeasure = Object.SetComposition.FindByID(Items.SetComposition.CurrentRow).Package;
			UnitOfMeasurementOfSet = Common.ObjectAttributeValue(Object.Products, "UnitOfMeasure");
		EndIf;
		If Not ValueIsFilled(UnitOfMeasure) Then
			UnitOfMeasure = Common.ObjectAttributeValue(CurrentProducts, "UnitOfMeasure");
		EndIf;
		SeriesUnitOfMeasurement = Common.ObjectAttributeValue(CurrentProducts, "UnitOfMeasure");
		UnitOfMeasurementCoefficient = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(UnitOfMeasure, CurrentProducts);
		AllowableVariance = Constants.AllowableDeviationOfAutomaticRounding.Get();
		ThisIsADimensionalUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(SeriesUnitOfMeasurement, "");
	
		// Packaging in the headings of the tabular part of the Goods.
		Items.GoodsInReserve.Title = StrTemplate(NStr("vi = 'Đang dự phòng, %1';
														|ru = 'В резерве, %1';
														|en = 'In reserve, %1'; fa = 'در رزرو، %1';
														|it = 'In riserva, %1';
														|pl = 'W rezerwie, %1';
														|tr = 'Rezervde, %1'"), UnitOfMeasure);
		Items.GoodsAvailable.Title = StrTemplate(NStr("vi = 'Được phép, %1';
														|ru = 'Доступно, %1';
														|en = 'Available, %1'; fa = 'در دسترس، %1';
														|it = 'Disponibile, %1';
														|pl = 'Dostępne, %1';
														|tr = 'Mevcut, %1'"), UnitOfMeasure);
		Items.ProductsGroupSelected.Title = StrTemplate(NStr("vi = 'Đã chọn, %1';
															|ru = 'Подобрано, %1';
															|en = 'Pick, %1'; fa = 'انتخاب، %1';
															|it = 'Selezionato, %1';
															|pl = 'Wybrano, %1';
															|tr = 'Seçildi, %1'"), UnitOfMeasure);
		Items.Package.InputHint = UnitOfMeasure;
		
		// Packaging in the titles of the tabular part of the Series.
		Items.SetOfSeriesAvailable.Title = StrTemplate(NStr("vi = 'Được phép, %1';
															|ru = 'Доступно, %1';
															|en = 'Available, %1'; fa = 'در دسترس، %1';
															|it = 'Disponibile, %1';
															|pl = 'Dostępne, %1';
															|tr = 'Mevcut, %1'"), SeriesUnitOfMeasurement);
		Items.SetOfSeriesSelected.Title = StrTemplate(NStr("vi = 'Đã chọn, %1';
															|ru = 'Подобрано, %1';
															|en = 'Pick, %1'; fa = 'انتخاب، %1';
															|it = 'Selezionato, %1';
															|pl = 'Wybrano, %1';
															|tr = 'Seçildi, %1'"), SeriesUnitOfMeasurement);
		
		FormatString = "NFD=3; NZ=0,000";
		Items.LabelSupplied.Title = StrTemplate(
			NStr("ru = 'Доступность товара обособленно: в наличии - %1 %3; в наличии и ожидается - %2 %3.';
				|vi = 'Assigned goods availability: in stock - %1 %3, available and expected - %2 %3.';
				|en = 'Assigned goods availability: in stock - %1 %3, available and expected - %2 %3.'; fa = 'دسترس‌پذیری کالای تخصیص‌یافته: موجود - %1 %3، در دسترس و مورد انتظار - %2 %3.';
				|it = 'Assigned goods availability: in stock - %1 %3, available and expected - %2 %3.';
				|pl = 'Assigned goods availability: in stock - %1 %3, available and expected - %2 %3.';
				|tr = 'Ürün mevcudiyeti ayrıştırıldı: stokta; %1 %3; stokta ve bekleniyor; %2 %3.'"),
			Format(Object.Goods.Total("InStockAssigned"), FormatString),
			Format(Object.Goods.Total("BasedOnScheduleAssigned"), FormatString),
			UnitOfMeasure);
			
	EndIf;
	
	If Item = Undefined Or Item = Items.Package Then
		
		DataProcessors.QuantityAndBatchRequest.UploadPriceTypesToList(Object, Items.PriceKind.ChoiceList, False);
		Items.PriceKind.ChoiceList.Add(Catalogs.TypesOfPrices.EmptyRef(), NStr("vi = '<tùy ý>';
																				|ru = '<произвольная>';
																				|en = '<custom>'; fa = '<سفارشی>';
																				|it = '<arbitraria>';
																				|pl = '<dowolny>';
																				|tr = '<isteğe bağlı>'"));
		If KeyParameters.EditPriceType
			And Items.PriceKind.ChoiceList.FindByValue(Object.PriceKind) = Undefined Then
			Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
		EndIf;
		DataProcessors.QuantityAndBatchRequest.UploadPriceTypesToList(Object, Items.Price.ChoiceList, True);
		
		UnitOfMeasurementTypeOfMeasuredValue = "";
		PackagingTypeOfMeasuredValue = "";
		
		UnitMeasuring  = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(SeriesUnitOfMeasurement, UnitOfMeasurementTypeOfMeasuredValue);
		PackagingMeasured = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Object.Package,  PackagingTypeOfMeasuredValue);
		
		If UnitMeasuring
			And PackagingTypeOfMeasuredValue <> UnitOfMeasurementTypeOfMeasuredValue
			And PackagingTypeOfMeasuredValue <> "Package"
			And PackagingTypeOfMeasuredValue <> ""
			Or UnitOfMeasurementTypeOfMeasuredValue = "NumberOfPieces"
				And PackagingMeasured Then
			
			Items.Count.Visible = True;
			Items.ProductsUnitOfMeasure.Visible = True;
			
		Else
			
			Items.Count.Visible = False;
			Items.ProductsUnitOfMeasure.Visible = False;
			
		EndIf;
		
	EndIf;
	
	If Item = Undefined Or Item = Items.PriceKind Then
		
		Items.PriceSet.ReadOnly     = ValueIsFilled(Object.PriceKind);
		Items.PriceSet.SkipOnInput = ValueIsFilled(Object.PriceKind);
		
	EndIf;
	
	If Item = Undefined Or Item = Items.Price Then
		
		PriceKindPresentation = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, NStr("vi = '<tùy ý>';
																							|ru = '<произвольная>';
																							|en = '<custom>'; fa = '<سفارشی>';
																							|it = '<arbitraria>';
																							|pl = '<dowolny>';
																							|tr = '<isteğe bağlı>'"));
		
	EndIf;
	
	If Item = Undefined Or Item = Items.Price Or Item = Items.DiscountOption Then
		
		Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = False;
		Items.PercentRateOfManualDiscountMarkup.ChoiceList.Clear();
		
		If DiscountOption = "DISCOUNT" Then
			Items.DiscountOptionsPages.CurrentPage = Items.Discount;
			If MaxDiscountPercentage > 0 Then
				Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
				Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(
					MaxDiscountPercentage,
					Format(MaxDiscountPercentage, "NFD=2"));
			EndIf;
		Else
			Items.DiscountOptionsPages.CurrentPage = Items.Markup;
			If MaxMarkupPercentage > 0 Then
				Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
				Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(
					MaxMarkupPercentage,
					Format(MaxMarkupPercentage, "NFD=2"));
			EndIf;
		EndIf;
		
	EndIf;
	
	If Item = Undefined
			Or Item = Items.Count
			Or Item = Items.Package
			Or Item = Items.NumberOfPackages Then
			
			If RoundUpTheQuantity And Object.Count <> Int(Object.Count) Then
				
				Items.RoundOff.Visible = True;
				Items.ProductsUnitOfMeasure.TextColor = StyleColors.ErrorNoteText;
				Items.Count.TextColor                   = StyleColors.ErrorNoteText;
				
			Else
				
				Items.RoundOff.Visible = False;
				Items.ProductsUnitOfMeasure.TextColor = StyleColors.FieldTextColor;
				Items.Count.TextColor                   = StyleColors.FieldTextColor;
				
			EndIf;
			
	EndIf;
	
	If Item = Undefined
			Or Item = Items.TheDisplayOfGoods Then
			
			Items.GoodsInReserve.Visible = TheDisplayOfGoods = "AvailableStock";
			Items.GoodsAvailable.Visible = TheDisplayOfGoods <> "All";
			Items.GoodsInStock.Visible = TheDisplayOfGoods = "AvailableStock";
			Items.GoodsOnSchedule.Visible = TheDisplayOfGoods = "ResidualsAndGraph";
			
	EndIf;

	If Item = Undefined
			Or Item = Items.SetComposition Then
				CurTypeOfProduct = Common.ObjectAttributeValue(CurrentProducts,
					 "ItemsType");
	
					IsItJobOrService = CurTypeOfProduct = Enums.ItemsTypes.Work_5
						Or CurTypeOfProduct = Enums.ItemsTypes.OperationService;
					Items.PagesProductsSeries.Visible = Not IsItJobOrService;
				
	EndIf;

	If Item = Undefined
			Or Item = Items.SetComposition
			Or Item = Items.SwitchApart
			Or Item = Items.TheDisplayOfGoods
			Or Item = Items.OnlyWarehousesOfTheSelectedGroup Then
		
		RowFilterProducts = New Structure();
		RowFilterProducts.Insert("WithAssignment", Object.WithAssignment);
		If Not Object.ItemKitConfiguration.IsEmpty() Then
			RowFilterProducts.Insert("ProductIndexForSelection", CurrentProductIndexForFilter);
		EndIf;
		
		If TheDisplayOfGoods = "AvailableStock" Then
			RowFilterProducts.Insert("ThereIsStockOnWarehouse", True);
		EndIf;
		
		If TheDisplayOfGoods = "ResidualsAndGraph" Then
			RowFilterProducts.Insert("ThereIsStockInSchedule", True);
		EndIf;
		
		If OnlyWarehousesOfTheSelectedGroup Then
			RowFilterProducts.Insert("ThisIsSelectedGroupWarehouse", True);
		EndIf;
		
		Items.Goods.RowFilter = New FixedStructure(RowFilterProducts);
		
	EndIf;
	
	If Item = Items.ToSeriesSpecification Then
		
		Items.PagesProductsSeries.CurrentPage = Items.SeriesPage;
		
		LineProducts_ = Object.Goods.FindByID(Items.Goods.CurrentRow);
		SelectionOfSeriesLines = New Structure();
		SelectionOfSeriesLines.Insert("Products",   LineProducts_.Products);
		SelectionOfSeriesLines.Insert("Characteristic", LineProducts_.Characteristic);
		SelectionOfSeriesLines.Insert("Warehouse",          LineProducts_.Warehouse);
		If SeriesDisplayMode = "AvailableStock" Then
			SelectionOfSeriesLines.Insert("CheckAvailability", True);
		EndIf;
		SelectionOfSeriesLines.Insert("Purpose", ?(LineProducts_.WithAssignment And Not ValueIsFilled(LineProducts_.Purpose),
		                                        Undefined,
		                                        LineProducts_.Purpose));
		
		Items.SetOfSeries.RowFilter = New FixedStructure(SelectionOfSeriesLines);
		
		ProductKind = Common.ObjectAttributeValue(LineProducts_.Products, "ProductKind");
		
		SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(
			ProductKind,
			Parameters.SeriesSpecificationParameters,
			New Structure("Warehouse", LineProducts_.Warehouse));
		SeriesUseSettings = New FixedStructure(SeriesUseSettings);
		
		Items.LocalizationAttributesSeriesGroup.Visible = False;
		Items.SetOfSeriesProductionDate.Visible = False;
		
		TMPropertyManagement.AddColumnsOfAdditionalDetails(
			SeriesUseSettings,
			ThisObject,
			"Object.SetOfSeries",
			"SetOfSeries",
			Items.SetOfSeriesAvailable.Name,
			True);
			
		For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			
			NameOfSeriesElement = DataProcessors.QuantityAndBatchRequest.NamesOfSeriesElements(LongDesc.AttributeName);
			If LongDesc.SettingName <> "UseRFIDTags" Then
				
				CustomizableElement = Items.Find(NameOfSeriesElement);
				
				If CustomizableElement = Undefined Then
					Continue;
				EndIf;
				
				CustomizableElement.Visible = LongDesc.Use; 
				
				If Not IsBlankString(LongDesc.Format) Then
					CustomizableElement.Format = LongDesc.Format;
				EndIf;
				
				If Not IsBlankString(LongDesc.PresentationOfFormatStringInHeader) Then
					ColumnHeaderPresentation = NStr("vi = '%AttributeRepresentation% (%FormatPresentation%)';
													|ru = '%AttributeRepresentation% (%FormatPresentation%)';
													|en = '%AttributeRepresentation% (%FormatPresentation%)'; fa = '%AttributeRepresentation% (%FormatPresentation%)';
													|it = '%AttributeRepresentation% (%FormatPresentation%)';
													|pl = '%AttributeRepresentation% (%FormatPresentation%)';
													|tr = '%AttributeRepresentation% (%FormatPresentation%)'");
					ColumnHeaderPresentation = StrReplace(ColumnHeaderPresentation, "%AttributeRepresentation%", LongDesc.AttributeRepresentation);
					ColumnHeaderPresentation = StrReplace(ColumnHeaderPresentation, "%FormatPresentation%", LongDesc.PresentationOfFormatStringInHeader);
					
					CustomizableElement.Title = ColumnHeaderPresentation; 
				EndIf;
				
				If LongDesc.AttributeName = "ValidUntil_" Then
					Items.SeriesFillInByFEFO.Visible = LongDesc.Use;
				EndIf;
				
			EndIf;
		EndDo;
			
		DataAcquisitionOption = DataProcessors.SelectBatchToDocuments.OptionGettingDataFromRegistersByFormParameters(
			Parameters.SeriesSpecificationParameters,
			Undefined,
			LineProducts_.Warehouse,
			ProductKind);
		Headers = DataProcessors.SelectBatchToDocuments.HeadersForOptionGettingDataFromRegisters(DataAcquisitionOption);
		If Headers.ButtonTitle <> "" Then
			Items.SeriesDisplayMode.ChoiceList[0].Presentation = Headers.ButtonTitle;
		EndIf;
		If Headers.FreeBalanceHeader <> "" Then
			Items.SetOfSeriesAvailable.Title = StrReplace(Headers.FreeBalanceHeader,
				"%UnitOfMeasure%", String(SeriesUnitOfMeasurement));
		EndIf;
		
		Items.GroupQuantityAndAction.Visible = False;
		Items.ActionGroupAndSeparately.Visible = False;
		Items.GroupRequiredToPickUpPickedUp.Visible = False;
		Items.GroupPageSeriesMatchByLine.Visible = True;
		Items.SetComposition.Enabled = False;
		
	EndIf;
	
	If Item = Items.ToActionSelection Then
		
		Items.PagesProductsSeries.CurrentPage = Items.GoodsPage;
		Items.GroupQuantityAndAction.Visible = True;
		Items.GroupPageSeriesMatchByLine.Visible = False;
		Items.ActionGroupAndSeparately.Visible = True;
		Items.GroupRequiredToPickUpPickedUp.Visible = True;
		Items.SetComposition.Enabled = True;
		
	EndIf;
	
	If Item = Undefined
			Or Item = Items.ToActionSelection
			Or Item = Items.Count
			Or Item = Items.NumberOfPackages
			Or Item = Items.Package Then
				
				CreateCaptionPickUpSelected(ThisObject);
			
	EndIf;
	
	If Item = Undefined
			Or Item = Items.ToActionSelection
			Or Item = Items.ToSeriesSpecification Then
			
			Items.LabelSupplied.Visible = Not KeyParameters.SelectGoods
				And Items.PagesProductsSeries.CurrentPage = Items.GoodsPage
				And ItemsType <> Enums.ItemsTypes.OperationService
				And GetFunctionalOption("UseOrderSupplyWithAssignment")
				And Not Object.WithAssignment
				And (Object.Goods.Total("InStockAssigned") > 0
					Or Object.Goods.Total("BasedOnScheduleAssigned") > 0);
				
			Items.TheInscriptionToPickUpSelected.Visible = KeyParameters.SelectGoods
				And Items.PagesProductsSeries.CurrentPage = Items.GoodsPage;
				
			Items.InformationDecoration.Visible = Items.LabelSupplied.Visible
				Or Items.TheInscriptionToPickUpSelected.Visible;
			
	EndIf;
	
	// Limiting the list of actions.
	If Item = Undefined
			Or Item = Items.SwitchApart Then
				
				If AcceptableSecurityOptions <> Undefined Then
					
					Items.SwitchApart.Enabled =
						AcceptableSecurityOptions.Separate_.Count() > 0
						And AcceptableSecurityOptions.NonIsolated.Count() > 0;
						
					ItemsList = ?(Object.WithAssignment,
						AcceptableSecurityOptions.Separate_,
						AcceptableSecurityOptions.NonIsolated);
						
					Items.Action.ChoiceList.LoadValues(ItemsList);
					Items.Action.Enabled = Items.Action.ChoiceList.Count() > 1;
						
				EndIf;
				
	EndIf;
	
	If Item = Undefined
			Or Item = Items.SwitchApart
			Or Item = Items.Action Then
			
		YouNeedToSpecifySeries = False;
		For Each String In Object.Goods Do
			If String.BatchesIndicationStatus <> 0 Then
				YouNeedToSpecifySeries = True;
				Break;
			EndIf;
		EndDo;
		Items.ToSeriesSpecification.Visible            = YouNeedToSpecifySeries;
		Items.GoodsBatchesIndicationStatus.Visible = YouNeedToSpecifySeries;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Hiding the unit of measurement of the kit component if the package is full.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetCompositionProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetComposition.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Hiding the packaging of the kit component if the package is not filled.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetCompositionPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetComposition.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Exceeding the maximum discount percentage.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscountMarkup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountPercentage");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MaxDiscountPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DiscountOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "DISCOUNT";
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Exceeding the maximum percentage of the margin.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscountMarkup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupPercentage");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MaxMarkupPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DiscountOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "MARKUP";
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	// Series - Available.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeriesAvailable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeriesDisplayMode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "ALLSERIES";
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bất kỳ';
													|ru = 'Любое';
													|en = 'Any'; fa = 'هر';
													|it = 'Qualsiasi';
													|pl = 'Any';
													|tr = 'Herhangi'"));
	
	// Products - Available.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInStock.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOnSchedule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CheckAvailability");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// Products - Selected.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSelected.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheDisplayOfGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "AvailableStock";
	
	ListOfOptionsForCheckingAvailability = New ValueList();
	ListOfOptionsForCheckingAvailability.Add(Enums.SupplyOptions.FromWarehouse);
	ListOfOptionsForCheckingAvailability.Add(Enums.SupplyOptions.Ship);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfOptionsForCheckingAvailability;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CheckAvailability");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.InStock");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.Selected");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue);
	
	// Series - Available.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeriesAvailable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeriesDisplayMode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "All";
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bất kỳ';
													|ru = 'Любое';
													|en = 'Any'; fa = 'هر';
													|it = 'Qualsiasi';
													|pl = 'Any';
													|tr = 'Herhangi'"));
	
	// Unavailability of specifying the quantity in a row, if not this is the selected group.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPictureMoveRight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsSelectedGroupWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsSelectedGroupWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	// The text "the warehouse is not filled".
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Warehouses.EmptyRef();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
EndProcedure

#EndRegion

#Region WhenExecutingCommands

&AtServer
Procedure ToSpecifySeriesOnServer()
	
	If Items.Goods.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(KeyParameters, Parameters);
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.ToSeriesSpecification);
	
	FormatString = "NFD=3; NZ=0,000";
	Text = Format(Object.Goods.FindByID(
		Items.Goods.CurrentRow).Selected * UnitOfMeasurementCoefficient, FormatString);
	Items.NumberOfDistributeSeries.Title =
		StrTemplate(
			NStr("vi = '%1 %2.';
				|ru = '%1 %2.';
				|en = '%1 %2.'; fa = '%1 %2.';
				|it = '%1 %2.';
				|pl = '%1 %2.';
				|tr = '%1 %2.'"),
			Text,
			SeriesUnitOfMeasurement);
	
	DataProcessors.QuantityAndBatchRequest.FillInSeriesForProductsLine(
		ThisObject,
		KeyParameters,
		Items.Goods.CurrentRow,
		Parameters.SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Function DistributeBalanceOnServer(MessageText)
	
	LineProducts_ = Object.Goods.FindByID(Items.Goods.CurrentRow);
	If LineProducts_.WithAssignment And Not ValueIsFilled(LineProducts_.Purpose) Then
		Return True;
	EndIf;
	
	EnteredNumberOfSeries = 0;
	
	RowFilter = New Structure();
	RowFilter.Insert("Products", LineProducts_.Products);
	RowFilter.Insert("Characteristic", LineProducts_.Characteristic);
	RowFilter.Insert("Warehouse", LineProducts_.Warehouse);
	RowFilter.Insert("Purpose", LineProducts_.Purpose);
	FoundRows = Object.SetOfSeries.FindRows(RowFilter);
	
	For Each SeriesLineCur In FoundRows Do
		EnteredNumberOfSeries = EnteredNumberOfSeries + SeriesLineCur.Selected;
	EndDo;
	
	QuantityToDistribution = Round(LineProducts_.Selected * UnitOfMeasurementCoefficient, 3) - EnteredNumberOfSeries;
	
	If QuantityToDistribution <= 0 Then
		MessageText = NStr("vi = 'Tất cả số lượng hàng hóa đã được phân bổ theo sê-ri.';
							|ru = 'Все количество товара распределено по сериям.';
							|en = 'All quantity of goods is allocated by batch.'; fa = 'All quantity of goods is allocated by batch.';
							|it = 'Tutta la quantità di beni distribuiti per serie.';
							|pl = 'Ogólną ilość towaru rozprowadzono w seriach.';
							|tr = 'Tüm miktarlar partilere göre dağıtılmıştır.'");
		Return False;
	EndIf;
	
	
	For Each RowID In Items.SetOfSeries.SelectedRows Do
		
		If QuantityToDistribution <= 0 Then
			Break;
		EndIf;
		
		RowSeries = Object.SetOfSeries.FindByID(RowID);
		
		If SeriesDisplayMode = "AvailableStock" Then
			Quantity_Per_Line = Max(Min(QuantityToDistribution, RowSeries.Available - RowSeries.Selected), 0);
		Else
			Quantity_Per_Line = Max(QuantityToDistribution, 0);
		EndIf;
		
		QuantityToDistribution = QuantityToDistribution - Quantity_Per_Line;
		
		RowSeries.Selected = RowSeries.Selected + Quantity_Per_Line;
		EnteredNumberOfSeries = EnteredNumberOfSeries + Quantity_Per_Line;
		
	EndDo;
	
	If QuantityToDistribution > 0 Then
		
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.TSName = "Object";
		StructureObject = New Structure();
		StructureObject = New Structure();
		StructureObject.Insert("Products", LineProducts_.Products);
		StructureObject.Insert("Package", CurrentPackaging);
		StructureObject.Insert("Count", EnteredNumberOfSeries);
		StructureObject.Insert("NumberOfPackages", LineProducts_.Selected);
		
		TypeOfValue = Common.ObjectAttributeValue(LineProducts_.Products, "UnitOfMeasure.MeasuredValueType");
		ThisIsPieceByPieceUnit = TypeOfValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
		
		RoundingIsCorrect = LineProducts_.Selected <= 0;
		If Not RoundingIsCorrect
				And ValueIsFilled(CurrentPackaging)
				And Round(EnteredNumberOfSeries, 0, RoundMode.Round15as20)
					= Round(LineProducts_.Selected * UnitOfMeasurementCoefficient, 0, RoundMode.Round15as20)
				And ThisIsPieceByPieceUnit Then
				
					Errors = ProductsServer.LineNumbersWithIncorrectRoundingOfQuantity(
						StructureObject,
						CheckParameters);
					RoundingIsCorrect = Errors.Count() = 0;
				
		EndIf;
		
		If Not RoundingIsCorrect Then
			MessageText = NStr(
				"vi = 'Đã phân bổ toàn bộ số lượng hợp lệ vào các dòng đã chọn, nhưng số lượng không đủ để phân bổ toàn bộ số lượng hàng hóa.
				|Hãy thử chọn các dòng khác và phân bổ lại.';
				|ru = 'Распределено все доступное количество в выделенных строках, но его недостаточно для распределения всего количества товара.
				|Попробуйте выделить другие строки и повторить распределение.';
				|en = 'All quantity available in the selected lines is allocated but it is not enough for all goods allocation.
				|Select other lines and allocate again.'; fa = 'All quantity available in the selected lines is allocated but it is not enough for all goods allocation.
				|Select other lines and allocate again.';
				|it = 'Tutta la quantità disponibile è distribuita nelle righe selezionate, ma non è sufficiente distribuire l''intera quantità di merci.
				| provare di selezionare le altre righe e ripetere la distribuzione.';
				|pl = 'Jest przydzielona dostępna ilość w wybranych wierszach, ale jej niewystarcza do przydzielenia łącznej ilości towaru.
				|Spróbuj wybrać inne wiersze i ponów przydzielenie.';
				|tr = 'Seçilen satırlardaki mevcut tüm miktarlar dağıtıldı, ancak tüm ürün miktarını dağıtmak için yeterli değil.
				|Diğer satırları dağıtmaya çalış ve dağıtımı tekrarla.'");
			Return False;
		EndIf;
		
	EndIf;
	Return True;
	
EndFunction

&AtServer
Function FillInFEFOOnServer()
	
	LineProducts_ = Object.Goods.FindByID(Items.Goods.CurrentRow);
	If LineProducts_.WithAssignment And Not ValueIsFilled(LineProducts_.Purpose) Then
		Return True;
	EndIf;
	
	QuantityToDistribution = Round(LineProducts_.Selected * UnitOfMeasurementCoefficient, 3);
	
	If QuantityToDistribution <= 0 Then
		Return False;
	EndIf;
	
	RowFilter = New Structure();
	RowFilter.Insert("Products",   LineProducts_.Products);
	RowFilter.Insert("Characteristic", LineProducts_.Characteristic);
	RowFilter.Insert("Warehouse",          LineProducts_.Warehouse);
	RowFilter.Insert("Purpose",     LineProducts_.Purpose);
	FoundRows = Object.SetOfSeries.FindRows(RowFilter);
	
	For Each RowSeries In FoundRows Do
		
		If SeriesDisplayMode = "AvailableStock" Then
			Quantity_Per_Line = Max(Min(QuantityToDistribution, RowSeries.Available), 0);
		Else
			Quantity_Per_Line = Max(QuantityToDistribution, 0);
		EndIf;
		
		QuantityToDistribution = QuantityToDistribution - Quantity_Per_Line;
		RowSeries.Selected = Quantity_Per_Line;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure ToSelectActionsOnServer(Cancel = False)
	
	LineProducts_ = Object.Goods.FindByID(Items.Goods.CurrentRow);
	SeriesCount = NumberOfSeriesPerLine(LineProducts_, Object.SetOfSeries);
	CountUpdate = SeriesCount - Round(LineProducts_.Selected * UnitOfMeasurementCoefficient, 3);
	
	If TheDisplayOfGoods = "AvailableStock" And LineProducts_.CheckAvailability
			And SeriesCount > Round(LineProducts_.InStock * UnitOfMeasurementCoefficient, 3) Then
		
		MessageText = StrTemplate(NStr("vi = 'Đã chỉ ra số lượng lớn hơn số được phép là %1 %2.';
										|ru = 'Указано количество больше, чем доступно на %1 %2.';
										|en = 'Quantity specified is greater than available by %1 %2.'; fa = 'Quantity specified is greater than available by %1 %2.';
										|it = 'Quantità specificata supera quella disponibile di %1 %2.';
										|pl = 'Wskazano ilość większą, niż dostępne na %1 %2.';
										|tr = 'Belirtilen miktar %1 %2''de mevcut olan miktardan fazladır.'"),
			SeriesCount - Round(LineProducts_.InStock * UnitOfMeasurementCoefficient, 3), SeriesUnitOfMeasurement);
		Common.MessageToUser(MessageText,,);
		Cancel = True;
		Return;
		
	ElsIf LineProducts_.ThisIsDocumentRow Then
		
		If CountUpdate > 0 Then
			MessageText = StrTemplate(
				NStr("vi = 'Đã nhập sê-ri nhiều hơn số cần thiết. Cần chỉ ra %1 %2';
					|ru = 'Введено серий больше чем требуется. Требуется указать %1 %2';
					|en = 'You have entered more batch than it is required. It is required to specify %1 %2'; fa = 'You have entered more batch than it is required. It is required to specify %1 %2';
					|it = 'Serie inserite più del necessario. È necessario specificare.  %1 %2';
					|pl = 'Wprowadzono serii więcej niż jest wymagane. Należy podać %1 %2';
					|tr = 'Gerekenden daha fazla parti girildi. Gerekli %1 %2'"),
				LineProducts_.Selected, SeriesUnitOfMeasurement);
			Common.MessageToUser(MessageText,,);
			Cancel = True;
			Return;
		EndIf;
		
	Else
		
		KeyParameters = ProvisionInDocumentsClientServer.KeyParametersOfQuantityAndSeriesRequestForm();
		FillPropertyValues(KeyParameters, Parameters);
		If Object.DocumentRowIndex > -1 Then
			DocumentLine = Object.Goods[Object.DocumentRowIndex];
			If CountUpdate > Round(DocumentLine.Selected * UnitOfMeasurementCoefficient, 3) Then
				MessageText = StrTemplate(NStr("vi = 'Đã chỉ định số lượng nhiều hơn số lượng cần phân bổ lại là %1 %2.';
												|ru = 'Указано количество больше, чем требуется перераспределить на %1 %2.';
												|en = 'Specified quantity is greater than required to reallocate to %1%2.'; fa = 'Specified quantity is greater than required to reallocate to %1%2.';
												|it = 'Quantità specificata supera quella da ridistribuire di %1 %2.';
												|pl = 'Podana ilość jest większa, niż należy ponownie podzielić na %1 %2.';
												|tr = 'Belirtilen miktar %1 %2 tarafından yeniden dağıtılacak miktardan büyüktür.'"),
					CountUpdate - Round(DocumentLine.Selected * UnitOfMeasurementCoefficient, 3), SeriesUnitOfMeasurement);
				Common.MessageToUser(MessageText,,);
				Cancel = True;
				Return;
			EndIf;
		ElsIf Not KeyParameters.SelectGoods Then
			Excess = Max(0, CountUpdate / UnitOfMeasurementCoefficient + Object.Goods.Total("Selected") - Object.NumberOfPackages);
			If Excess > 0 Then
				MessageText = StrTemplate(NStr("vi = 'Đã chỉ ra số lượng nhiều hơn số lượng cần chọn là %1 %2.';
												|ru = 'Указано количество больше, чем требуется подобрать на %1 %2.';
												|en = 'Specified quantity is greater than required to pick for %1%2.'; fa = 'Specified quantity is greater than required to pick for %1%2.';
												|it = 'Indicata quantità maggiore di quanto richiesto per %1 %2.';
												|pl = 'Podana ilość jest większa, niż należy wybrać na %1 %2.';
												|tr = 'Belirtilen miktar %1 %2 tarafından seçilecek miktardan büyüktür.'"),
					Round(Excess * UnitOfMeasurementCoefficient, 3), SeriesUnitOfMeasurement);
				Common.MessageToUser(MessageText, ,);
				Cancel = True;
				Return;
			EndIf;
		EndIf;
		
	EndIf;
	
	If LineProducts_.ThisIsDocumentRow Then
		RecalculateSeriesIndicationStatus(Object, LineProducts_, Parameters.SeriesSpecificationParameters, ThisIsADimensionalUnit, AllowableVariance, UnitOfMeasurementCoefficient);
	Else
		ChangeMatchedWhenChangingSeries(LineProducts_, Round(CountUpdate / UnitOfMeasurementCoefficient, 3), UnitOfMeasurementCoefficient);
	EndIf;
	
	ManagingFormElementsWhenCreatingAndChangingProps(Items.ToActionSelection);
	
EndProcedure

#EndRegion

&AtServerNoContext
Function PackagingFactor(Package, Products)
	Return Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
EndFunction

&AtServer
Procedure AddSelectedProducts_(SelectedGoods, ProductLines_3, ProductDetails__, RoundingCheckTable)
	
	For Each LineProducts_ In ProductLines_3 Do
		
		If LineProducts_.Selected = 0 Then
			Continue;
		EndIf;
		
		ProductParameters_1 = ProductParameters_1();
		ProductParameters_1.ItemsType = ProductDetails__.ItemsType;
		ProductParameters_1.SupplyOption = Object.SupplyOption;
		FillPropertyValues(ProductParameters_1, LineProducts_);
		ProductParameters_1.Package            = ProductDetails__.Package;
		ProductParameters_1.Price                = ProductDetails__.Price;
		ProductParameters_1.PriceKind             = Object.PriceKind;
		ProductParameters_1.PercentRateOfManualDiscount = ?(DiscountOption = "DISCOUNT",
			Object.PercentRateOfManualDiscountMarkup,
			-Object.PercentRateOfManualDiscountMarkup);
		ProductParameters_1.ItemVariantsAreUsed = ProductDetails__.ItemVariantsAreUsed;
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Products",   LineProducts_.Products);
		FilterStructure1.Insert("Characteristic", LineProducts_.Characteristic);
		FilterStructure1.Insert("Warehouse",          LineProducts_.Warehouse);
		FilterStructure1.Insert("Purpose",     LineProducts_.Purpose);
		SeriesLines_ = Object.SetOfSeries.FindRows(FilterStructure1);
		
		SeriesCount = 0;
		For Each RowSeries In SeriesLines_ Do
			
			If RowSeries.Selected = 0 Then
				Continue;
			EndIf;
			
			RowWithSeries = ProductParameters_1();
			FillPropertyValues(RowWithSeries, ProductParameters_1);
			RowWithSeries.NumberOfPackages = RowSeries.Selected / ProductDetails__.PackagingFactor;
			RowWithSeries.Count         = RowSeries.Selected;
			RowWithSeries.Series              = RowSeries.Series;
			
			SelectedGoods.Add(RowWithSeries);
			SeriesCount = SeriesCount + RowSeries.Selected;
			
		EndDo;
		
		Selected = LineProducts_.Selected - SeriesCount / ProductDetails__.PackagingFactor;
		
		If Selected > 0 And SeriesCount > 0 And ProductDetails__.ThisIsPieceByPieceUnit And ValueIsFilled(ProductDetails__.Package)
				And Round(Selected * ProductDetails__.PackagingFactor, 0, RoundMode.Round15as20) = 0 Then
				
					NewCheckRow = RoundingCheckTable.Add();
					NewCheckRow.LineNumber = RoundingCheckTable.Count();
					NewCheckRow.IndexToInsert = SelectedGoods.Count();
					NewCheckRow.ProductParameters_1 = ProductParameters_1;
					NewCheckRow.Products = LineProducts_.Products;
					NewCheckRow.Package = ProductDetails__.Package;
					NewCheckRow.Count = 0;
					NewCheckRow.NumberOfPackages = Selected;
					
		ElsIf Selected > 0 Then
			
			ProductParameters_1.NumberOfPackages = Selected;
			ProductParameters_1.Count = Selected / ProductDetails__.PackagingFactor;
			SelectedGoods.Add(ProductParameters_1);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function ProductParameters_1()
	
	ProductParameters_1 = New Structure();
	If Not Object.ItemKitConfiguration.IsEmpty() Then
		ProductParameters_1.Insert("ProductsInSet",   Object.Products);
		ProductParameters_1.Insert("ItemVariantOfSet", Object.Characteristic);
	EndIf;
	
	ProductParameters_1.Insert("Products",                Catalogs.Products.EmptyRef());
	ProductParameters_1.Insert("Characteristic",              Catalogs.ItemsCharacteristics.EmptyRef());
	ProductParameters_1.Insert("Package",                    Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	ProductParameters_1.Insert("Price",                        0);
	ProductParameters_1.Insert("PriceKind",                     Catalogs.TypesOfPrices.EmptyRef());
	ProductParameters_1.Insert("Warehouse",                       Catalogs.Warehouses.EmptyRef());
	ProductParameters_1.Insert("DateOfShipment",                Date('00010101'));
	ProductParameters_1.Insert("SupplyOption",          Enums.SupplyOptions.EmptyRef());
	ProductParameters_1.Insert("ItemsType",             Undefined);
	ProductParameters_1.Insert("WithAssignment",                 False);
	ProductParameters_1.Insert("PercentRateOfManualDiscount",         0);
	ProductParameters_1.Insert("NumberOfPackages",          0);
	ProductParameters_1.Insert("Count",                  0);
	ProductParameters_1.Insert("BatchesIndicationStatus",         0);
	ProductParameters_1.Insert("Series",                       Catalogs.ItemsBatches.EmptyRef());
	ProductParameters_1.Insert("ItemVariantsAreUsed",  False);
	If Object.DocumentRowIndex > -1 Then
		ProductParameters_1.Insert("IsNewLine", True);
		ProductParameters_1.Insert("ThisIsDocumentRow", False);
	EndIf;
	
	Return ProductParameters_1;
	
EndFunction

&AtServer
Function SelectedGoods()
	
	RoundingCheckTable = New ValueTable();
	RoundingCheckTable.Columns.Add("LineNumber",
		New TypeDescription("Number", New NumberQualifiers(5, 0,AllowedSign.Nonnegative)));
	RoundingCheckTable.Columns.Add("Products",
		New TypeDescription("CatalogRef.Products"));
	RoundingCheckTable.Columns.Add("Package",
		New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	RoundingCheckTable.Columns.Add("Count",
		TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
	RoundingCheckTable.Columns.Add("NumberOfPackages",
		TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
	RoundingCheckTable.Columns.Add("IndexToInsert",
		New TypeDescription("Number", New NumberQualifiers(5, 0, AllowedSign.Nonnegative)));
	RoundingCheckTable.Columns.Add("ProductParameters_1", New TypeDescription("Structure"));
	
	SelectedGoods = New Array();
	
	If Object.ItemKitConfiguration.IsEmpty() Then
		
		PackagingFactor = PackagingFactor(Object.Package, Object.Products);
		CurrentBankingDetails = FillInAttributesOfItem(Object.Products)[Object.Products];
		
		ProductDetails__ = New Structure();
		ProductDetails__.Insert("Package", Object.Package);
		ProductDetails__.Insert("Price", Object.Price);
		ProductDetails__.Insert("PackagingFactor", PackagingFactor);
		ProductDetails__.Insert("ItemsType", CurrentBankingDetails.ItemsType);
		ProductDetails__.Insert("ItemVariantsAreUsed", CurrentBankingDetails.ItemVariantsAreUsed);
		ProductDetails__.Insert("ThisIsPieceByPieceUnit", CurrentBankingDetails.ThisIsPieceByPieceUnit);
		
		AddSelectedProducts_(SelectedGoods, Object.Goods, ProductDetails__, RoundingCheckTable);
		
		ItRemainsToPickUp = Max(Object.NumberOfPackages - Object.Goods.Total("Selected"), 0);
		If ItRemainsToPickUp > 0 Then
			
			If Object.DocumentRowIndex > -1 Then
				
				DocumentLine = Object.Goods[Object.DocumentRowIndex];
				
				ProductParameters_1 = ProductParameters_1();
				ProductParameters_1.ThisIsDocumentRow = True;
				ProductParameters_1.WithAssignment = Object.WithAssignment;
				ProductParameters_1.SupplyOption = Object.SupplyOptionBeforeChange;
				ProductParameters_1.Warehouse = DocumentLine.Warehouse;
				ProductParameters_1.NumberOfPackages = ItRemainsToPickUp;
				ProductParameters_1.Count = ItRemainsToPickUp * PackagingFactor;
				ProductParameters_1.ItemVariantsAreUsed = CurrentBankingDetails.ItemVariantsAreUsed;
				SelectedGoods.Add(ProductParameters_1);
				
			Else
				
				ProductParameters_1 = ProductParameters_1();
				FillPropertyValues(ProductParameters_1, Object);
				If Warehouses.Count() = 1 Then
					ProductParameters_1.Warehouse = Warehouses[0].Value;
				Else
					ProductParameters_1.Warehouse = Catalogs.Warehouses.EmptyRef();
				EndIf;
				ProductParameters_1.PercentRateOfManualDiscount = ?(DiscountOption = "DISCOUNT",
					Object.PercentRateOfManualDiscountMarkup,
					-Object.PercentRateOfManualDiscountMarkup);
				ProductParameters_1.NumberOfPackages = ItRemainsToPickUp;
				ProductParameters_1.Count = ItRemainsToPickUp * PackagingFactor;
				ProductParameters_1.ItemVariantsAreUsed = CurrentBankingDetails.ItemVariantsAreUsed;
				SelectedGoods.Add(ProductParameters_1);
				
			EndIf;
			
		EndIf;
		
	Else
		
		AllComponentsAndPackages = Object.SetComposition.Unload(, "Products,Package");
		Packages_Are_Used = GetFunctionalOption("UseItemPackages");
		If Packages_Are_Used Then
			PackingFactors = Catalogs.PackagesAndUnitsOfMeasure.PackingFactors(AllComponentsAndPackages);
		EndIf;
		AllComponents = AllComponentsAndPackages.UnloadColumn("Products");

		ProductAttributes = FillInAttributesOfItem(AllComponents);
		
		For Each SetPosition In Object.SetComposition Do
			
			CurrentBankingDetails = ProductAttributes.Get(SetPosition.Products);
			
			PackagingFactor = Undefined;
			If Packages_Are_Used Then
				PackagingFactor = PackingFactors[SetPosition.Products][SetPosition.Package];
			EndIf;
			If Not ValueIsFilled(PackagingFactor) Then
				PackagingFactor = 1;
			EndIf;
			
			Filter = New Structure;
			Filter.Insert("Products",   SetPosition.Products);
			Filter.Insert("Characteristic", SetPosition.Characteristic);
			FoundRows = Object.Goods.FindRows(Filter);
			
			ProductDetails__ = New Structure();
			ProductDetails__.Insert("Package", SetPosition.Package);
			ProductDetails__.Insert("Price", SetPosition.Price);
			ProductDetails__.Insert("PackagingFactor", PackagingFactor);
			ProductDetails__.Insert("ItemsType", CurrentBankingDetails.ItemsType);
			ProductDetails__.Insert("ItemVariantsAreUsed", CurrentBankingDetails.ItemVariantsAreUsed);
			ProductDetails__.Insert("ThisIsPieceByPieceUnit", CurrentBankingDetails.ThisIsPieceByPieceUnit);
			
			AddSelectedProducts_(SelectedGoods, FoundRows, ProductDetails__, RoundingCheckTable);
			
			Selected = SetPosition.QuantityPick - SetPosition.QuantityIsSelected;
			If Selected > 0 Then
				
				ProductParameters_1 = ProductParameters_1();
				FillPropertyValues(ProductParameters_1, SetPosition);
				ProductParameters_1.ItemsType = CurrentBankingDetails.ItemsType;
				If Warehouses.Count() = 1 Then
					ProductParameters_1.Warehouse = Warehouses[0].Value;
				Else
					ProductParameters_1.Warehouse = Catalogs.Warehouses.EmptyRef();
				EndIf;
				ProductParameters_1.Package            = SetPosition.Package;
				ProductParameters_1.Price                = SetPosition.Price;
				ProductParameters_1.PriceKind             = Object.PriceKind;
				ProductParameters_1.PercentRateOfManualDiscount = ?(DiscountOption = "DISCOUNT",
					Object.PercentRateOfManualDiscountMarkup,
					-Object.PercentRateOfManualDiscountMarkup);
				ProductParameters_1.NumberOfPackages = Selected;
				ProductParameters_1.Count = Selected * PackagingFactor;
				ProductParameters_1.SupplyOption = Object.SupplyOption;
				SelectedGoods.Add(ProductParameters_1);
				ProductParameters_1.ItemVariantsAreUsed = CurrentBankingDetails.ItemVariantsAreUsed;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TableToCheck = RoundingCheckTable;
	LineNumbers = ProductsServer.LineNumbersWithIncorrectRoundingOfQuantity(Undefined, CheckParameters);
	If LineNumbers.Count() > 0 Then
		LineNumbers.Sort("LineNumber");
	
		For Counter = 1 To LineNumbers.Count() Do

			RoundingString = LineNumbers[LineNumbers.Count() - Counter];
			RowOfValidationTable = RoundingCheckTable[RoundingString.LineNumber - 1];
			ProductParameters_1 = RowOfValidationTable.ProductParameters_1;
			ProductParameters_1.NumberOfPackages = RowOfValidationTable.NumberOfPackages;
			ProductParameters_1.Count = ProductParameters_1.NumberOfPackages / PackagingFactor;
			SelectedGoods.Insert(RowOfValidationTable.IndexToInsert, ProductParameters_1);
			
		EndDo;
	EndIf;
	
	If Object.DocumentRowIndex > -1 Then
		
		// This is a new line = False for the first added line, with the warehouse as in the selected line of the document.
		SearchForFirstLineOfDocument = True;
		For IndexOf = 0 To SelectedGoods.Count() - 1 Do
			If Not SearchForFirstLineOfDocument Then
				Break;
			EndIf;
			ProductParameters_1 = SelectedGoods[IndexOf];
			If SearchForFirstLineOfDocument And ProductParameters_1.ThisIsDocumentRow Then
				SearchForFirstLineOfDocument = False;
				ProductParameters_1.IsNewLine = False;
			EndIf;
			
		EndDo;
		If SearchForFirstLineOfDocument And SelectedGoods.Count() > 0 Then
			SelectedGoods[0].IsNewLine = False;
		EndIf;
		
	EndIf;
	
	Return SelectedGoods;
	
EndFunction

&AtServer
Function HeadingWarehouseSelection()
	
	If ReadOnly Then
		
		Text = NStr("vi = 'Thông tin về tính khả dụng (%1)';
					|ru = 'Информация о доступности (%1)';
					|en = 'Availability information (%1)'; fa = 'Availability information (%1)';
					|it = 'Informazioni di accessibilità (%1)';
					|pl = 'Dane o dostępności (%1)';
					|tr = 'Erişilebilirlik hakkında bilgi (%1)'");
			
	ElsIf Object.WithAssignment Then
		
		If Object.SupplyOption = Enums.SupplyOptions.Ship Then
			
			Text = NStr("vi = 'Chọn kho để giao hàng từ số dư đặt riêng (%1)';
						|ru = 'Подбор склада для отгрузки из обособленного остатка (%1)';
						|en = 'Warehouse picking for shipment from assigned balance (%1)'; fa = 'Warehouse picking for shipment from assigned balance (%1)';
						|it = 'Selezione del magazzino per spedizione dalla rimanenza separata (%1)';
						|pl = 'Wybór magazynu do wysyłki z odrębnego salda (%1)';
						|tr = 'Ayrıştırılmış bakiyeden sevkiyat için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
			
			Text = NStr("vi = 'Chọn kho bãi để dự phòng từ số dư đặt riêng (%1)';
						|ru = 'Подбор склада для резервирования из обособленного остатка (%1)';
						|en = 'Warehouse picking for reserving from assigned balance (%1)'; fa = 'Warehouse picking for reserving from assigned balance (%1)';
						|it = 'Selezione del magazzino per prenotazione dalla rimanenza separata (%1)';
						|pl = 'Wybór magazynu do rezerwowania z odrębnego salda (%1)';
						|tr = 'Ayrıştırılmış bakiyeden rezervasyon için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.ReserveAsReceived Then
			
			Text = NStr("vi = 'Chọn kho để đảm bảo riêng (%1)';
						|ru = 'Подбор склада для обособленного обеспечения (%1)';
						|en = 'Warehouse picking for assigned supply (%1)'; fa = 'Warehouse picking for assigned supply (%1)';
						|it = 'Selezione del magazzino per approvvigionamento separato (%1)';
						|pl = 'Wybór magazynu do odrębnego zabezpieczenia (%1)';
						|tr = 'Ayrıştırılmış tedarik için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.ToSupply Then
			
			Text = NStr("vi = 'Chọn kho để đảm bảo riêng (%1)';
						|ru = 'Подбор склада для обособленного обеспечения (%1)';
						|en = 'Warehouse picking for assigned supply (%1)'; fa = 'Warehouse picking for assigned supply (%1)';
						|it = 'Selezione del magazzino per approvvigionamento separato (%1)';
						|pl = 'Wybór magazynu do odrębnego zabezpieczenia (%1)';
						|tr = 'Ayrıştırılmış tedarik için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.NotRequired Then
			
			Text = NStr("vi = 'Chọn kho (%1)';
						|ru = 'Подбор склада (%1)';
						|en = 'Warehouse picking (%1)'; fa = 'Warehouse picking (%1)';
						|it = 'Selezione del magazzino (%1)';
						|pl = 'Wybór magazynu (%1)';
						|tr = 'Ambar seçimi (%1)'");
			
		EndIf;
		
	ElsIf GetFunctionalOption("UseOrderSupplyWithAssignment") Then
	
		If Object.SupplyOption = Enums.SupplyOptions.Ship Then
			
			Text = NStr("vi = 'Chọn kho để giao hàng từ số dư không đặt riêng (%1)';
						|ru = 'Подбор склада для отгрузки из необособленного остатка (%1)';
						|en = 'Warehouse picking for shipment from non-assigned balance (%1)'; fa = 'Warehouse picking for shipment from non-assigned balance (%1)';
						|it = 'Selezione del magazzino per spedizione dalla rimanenza non separata (%1)';
						|pl = 'Wybór magazynu do wysyłki z nieodrębnego salda (%1)';
						|tr = 'Ayrıştırılmayan bakiyeden sevkiyat için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
			
			Text = NStr("vi = 'Chọn kho bãi để dự phòng từ số dư không đặt riêng (%1)';
						|ru = 'Подбор склада для резервирования из необособленного остатка (%1)';
						|en = 'Warehouse picking for reserving from non-assigned balance (%1)'; fa = 'Warehouse picking for reserving from non-assigned balance (%1)';
						|it = 'Selezione del magazzino per prenotazione dalla rimanenza non separata (%1)';
						|pl = 'Wybór magazynu do rezerwowania z nieodrębnego salda (%1)';
						|tr = 'Ayrıştırılmayan  bakiyeden rezervasyon için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.ReserveAsReceived Then
			
			Text = NStr("vi = 'Chọn kho để đảm bảo hàng không đặt riêng (%1)';
						|ru = 'Подбор склада для необособленного обеспечения (%1)';
						|en = 'Warehouse picking for non-assigned supply (%1)'; fa = 'Warehouse picking for non-assigned supply (%1)';
						|it = 'Selezione del magazzino per approvvigionamento non separato (%1)';
						|pl = 'Wybór magazynu do nieodrębnego zabezpieczenia (%1)';
						|tr = 'Ayrıştırılmayan tedarik için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.ToSupply Then
			
			Text = NStr("vi = 'Chọn kho để đảm bảo hàng không đặt riêng (%1)';
						|ru = 'Подбор склада для необособленного обеспечения (%1)';
						|en = 'Warehouse picking for non-assigned supply (%1)'; fa = 'Warehouse picking for non-assigned supply (%1)';
						|it = 'Selezione del magazzino per approvvigionamento non separato (%1)';
						|pl = 'Wybór magazynu do nieodrębnego zabezpieczenia (%1)';
						|tr = 'Ayrıştırılmayan tedarik için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.NotRequired Then
			
			Text = NStr("vi = 'Chọn kho (%1)';
						|ru = 'Подбор склада (%1)';
						|en = 'Warehouse picking (%1)'; fa = 'Warehouse picking (%1)';
						|it = 'Selezione del magazzino (%1)';
						|pl = 'Wybór magazynu (%1)';
						|tr = 'Ambar seçimi (%1)'");
			
		EndIf;
		
	Else
		
		If Object.SupplyOption = Enums.SupplyOptions.Ship Then
			
			Text = NStr("vi = 'Chọn kho để giao hàng (%1)';
						|ru = 'Подбор склада для отгрузки (%1)';
						|en = 'Warehouse picking for shipment (%1)'; fa = 'Warehouse picking for shipment (%1)';
						|it = 'Selezione del magazzino per la spedizione (%1)';
						|pl = 'Wybór magazynu do wysyłki (%1)';
						|tr = 'Sevkiyat için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
			
			Text = NStr("vi = 'Chọn kho để dự phòng (%1)';
						|ru = 'Подбор склада для резервирования (%1)';
						|en = 'Warehouse picking for reserving (%1)'; fa = 'Warehouse picking for reserving (%1)';
						|it = 'Selezione del magazzino per la prenotazione (%1)';
						|pl = 'Wybór magazynu do rezerwowania (%1)';
						|tr = 'Rezervasyon için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.ReserveAsReceived Then
			
			Text = NStr("vi = 'Chọn kho để đảm bảo (%1)';
						|ru = 'Подбор склада для обеспечения (%1)';
						|en = 'Warehouse picking for supply (%1)'; fa = 'Warehouse picking for supply (%1)';
						|it = 'Selezione del magazzino per l''approvvigionamento (%1)';
						|pl = 'Wybór magazynu do zabezpieczenia (%1)';
						|tr = 'Tedarik için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.ToSupply Then
			
			Text = NStr("vi = 'Chọn kho để đảm bảo (%1)';
						|ru = 'Подбор склада для обеспечения (%1)';
						|en = 'Warehouse picking for supply (%1)'; fa = 'Warehouse picking for supply (%1)';
						|it = 'Selezione del magazzino per l''approvvigionamento (%1)';
						|pl = 'Wybór magazynu do zabezpieczenia (%1)';
						|tr = 'Tedarik için ambar seçimi (%1)'");
			
		ElsIf Object.SupplyOption = Enums.SupplyOptions.NotRequired Then
			
			Text = NStr("vi = 'Chọn kho (%1)';
						|ru = 'Подбор склада (%1)';
						|en = 'Warehouse picking (%1)'; fa = 'Warehouse picking (%1)';
						|it = 'Selezione del magazzino (%1)';
						|pl = 'Wybór magazynu (%1)';
						|tr = 'Ambar seçimi (%1)'");
			
		EndIf;
		
	EndIf;
	
	Substitution = Undefined;
	If ValueIsFilled(Object.Characteristic) Then
		Substitution = StrTemplate(NStr("vi = 'Mặt hàng: %1, Đặc tính:%2';
										|ru = 'Номенклатура: %1, Характеристика:%2';
										|en = 'Item: %1, Variant:%2'; fa = 'Item: %1, Variant:%2';
										|it = 'Articolo: %1, Caratteristica: %2';
										|pl = 'Pozycja: %1, Charakterystyka:%2';
										|tr = 'Öğe: %1, Özellik:%2'"),
			Object.Products, Object.Characteristic);
	Else
		Substitution = StrTemplate(NStr("vi = 'Mặt hàng: %1';
										|ru = 'Номенклатура: %1';
										|en = 'Items: %1'; fa = 'Items: %1';
										|it = 'Articolo: %1';
										|pl = 'Towary: %1';
										|tr = 'Öğe: %1'"), Object.Products);
	EndIf;
	
	Return StrTemplate(Text, Substitution);
	
EndFunction

&AtServer
Function FillInAttributesOfItem(AllComponents)
	
	ProductAttributes = New Map();
	
	Query = New Query(
		"SELECT
		|	CatProducts.Ref AS Products,
		|	CatProducts.UseVariants IN(
		|		VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|		VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|		VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)) AS ItemVariantsAreUsed,
		|	CatProducts.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS ThisIsPieceByPieceUnit,
		|	CatProducts.ItemsType AS ItemsType
		|FROM
		|	Catalog.Products AS CatProducts
		|WHERE
		|	CatProducts.Ref IN(&AllComponents)");
	
	Query.SetParameter("AllComponents", AllComponents);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CurrentBankingDetails = New Structure("ItemVariantsAreUsed,ThisIsPieceByPieceUnit,ItemsType");
		FillPropertyValues(CurrentBankingDetails, Selection);
		ProductAttributes.Insert(Selection.Products, CurrentBankingDetails);
	EndDo;
	
	Return ProductAttributes;

EndFunction

#EndRegion
