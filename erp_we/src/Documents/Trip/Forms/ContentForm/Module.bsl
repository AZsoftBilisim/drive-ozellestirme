// @strict-types

#Region Variables

&AtClient
Var CachedValues; // See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = Parameters.ReadOnly;
	
	Recipient = Parameters.Recipient;
	DeliveryPoint = Parameters.DeliveryPoint;
	DeliveryZone = Parameters.DeliveryZone;
	ConnectionKey = Parameters.ConnectionKey;
	Warehouse = Parameters.Warehouse;
	Organization = Parameters.Organization;
	DeliveryMethod = Parameters.DeliveryMethod;
	Carrier = Parameters.Carrier;
	DateOfDeparture = Parameters.DateOfDeparture;
	FlightHasBeenCompleted = Parameters.FlightHasBeenCompleted;
	FlightLink = Parameters.FlightLink;
	FlightModified = Parameters.FlightModified;
	Operation = Parameters.Operation;
	FlightStatus = Parameters.Status;
	
	ConfigureAvailabilityOfFieldsByStatus();
	
	TableContents = GetFromTempStorage(Parameters.Address_Content); // ValueTable
	DeliveredItems.Load(TableContents);
	
	AddColumnsOfDeliveredGoods(TableContents);
	UpdateNumberingOfGoods(DeliveredItems);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	StructureOfActions.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert(
		"FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	
	StructureOfActions.Insert(
		"FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	
	StructureOfActions.Insert(
		"FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	
	StructureOfActions.Insert(
		"FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(DeliveredItems, StructureOfActions);
	
	For Each RowOfGoods In DeliveredItems Do
		
		FillInNetWeightOfUnit(RowOfGoods);
		
	EndDo;
	
	ProcessingOfTabularForms.InitializeRowCache(Items.DeliveredItems);
	
	RecalculateResultsOfDocumentsAtServer();
	
	If DeliveryMethod <> Enums.TransportMethods25.OwnDelivery Then
		
		Items.DeliveredItemsDeliverToCarrier.Visible = False;
		Items.DeliveredItemsChangeCarrier.Visible = False;
		Items.DeliveredItemsDeliverByOurForces.Visible = False;
		
	EndIf;
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Modified Then
		Return;
	EndIf;
	
	If Exit Then
		
		Cancel = True;
		
	Else
		
		TransferContentTo_Document();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Products"
	 Or EventName = "Write_ProductPackages" Then
		
		RecalculateGoodsRows(EventName, Source);
		
	EndIf;
	
EndProcedure

// Parameters:
//  ValueSelected - Structure, Arbitrary -
//  ChoiceSource - ClientApplicationForm -
//
&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.PickGoodsToDeliveryDocument.Form.PickForm" Then
		
		Modified = True;
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDeliveredItems

&AtClient
Procedure DeliveredItemsOnActivateRow(Item)
	
	AttachIdleHandler("UpdateItemAvailability", 0.1, True);
	
EndProcedure

&AtClient
Procedure DeliveredItemsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure DeliveredItemsProductsOnChange(Item)
	
	CurrentRow = Items.DeliveredItems.CurrentData;
	
	StructureOfActions = New Structure;
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	
	StructureOfActions.Insert("FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	
	StructureOfActions.Insert("FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	
	StructureOfActions.Insert("FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	
	StructureOfActions.Insert("FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInNetWeightOfUnit(CurrentRow);
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	
EndProcedure

&AtClient
Procedure DeliveredItemsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.DeliveredItems.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	
EndProcedure

&AtClient
Procedure DeliveredItemsPackageOnChange(Item)
	
	CurrentRow = Items.DeliveredItems.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	StructureOfActions.Insert("FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	StructureOfActions.Insert("FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	StructureOfActions.Insert("FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInNetWeightOfUnit(CurrentRow);
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	
EndProcedure

&AtClient
Procedure DeliveredItemsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.DeliveredItems, ThisObject);
	
EndProcedure

&AtClient
Procedure DeliveredItemsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.DeliveredItems, ThisObject);
	
EndProcedure

&AtClient
Procedure DeliveredItemsOnChange(Item)
	
	AttachIdleHandler("RecalculateResultsOfDocuments", 0.1, True);
	
EndProcedure

&AtClient
Procedure DeliveredItemsCanceledOnChange(Item)
	
	CurrentRow = Items.DeliveredItems.CurrentData;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.DeliveryCancellationReasons.EmptyRef");
	EndIf;
	
	UpdateRowCancellationAvailability(CurrentRow);
	
EndProcedure

&AtClient
Procedure DeliveredItemsAfterDeleteRow(Item)
	
	UpdateNumberingOfGoods(DeliveredItems);
	
EndProcedure

&AtClient
Procedure DeliveredItemsSpecialConditionsOfCarriageOnChange(Item)
	
	CurrentRow = Items.DeliveredItems.CurrentData;
	UpdateAvailabilityOfSpecialConditionsOfCarriage(CurrentRow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableDocuments

&AtClient
Procedure TableDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure TableDocumentsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	QueryText = NStr("vi = 'Tất cả hàng hóa theo lệnh đã chọn và chứng từ lập kế hoạch sẽ bị xóa.
						|Tiếp tục?';
						|ru = 'Все товары по выбранному распоряжению и документу планирования будут удалены.
						|Продолжить?';
						|en = 'All items of the selected reference and planning document will be deleted.
						|Continue?'; fa = 'All items of the selected reference and planning document will be deleted.
						|Continue?';
						|it = 'All items of the selected reference and planning document will be deleted.
						|Continue?';
						|pl = 'All items of the selected reference and planning document will be deleted.
						|Continue?';
						|tr = 'Seçilen talimat ve planlama belgesine göre tüm mallar silinecek.
						|Devam edilsin mi?'");
	CallbackDescription = New CallbackDescription("TableDocumentsBeforeDeleteRowCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	TransferContentTo_Document();
	
EndProcedure

&AtClient
Procedure PickUpData(Command)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	ClearMessages();
	If FlightModified Then
		
		If FlightHasBeenCompleted Then
			WarningText = NStr("vi = 'Chứng từ đã bị thay đổi. Để mở biểu mẫu chọn, cần phải kết chuyển chuyến đi';
								|ru = 'Документ был изменен. Для открытия формы подбора необходимо провести рейс';
								|en = 'The document was changed. To open the pick form, post the trip'; fa = 'The document was changed. To open the pick form, post the trip';
								|it = 'The document was changed. To open the pick form, post the trip';
								|pl = 'The document was changed. To open the pick form, post the trip';
								|tr = 'Belge değiştirildi. Seçim formunu açmak için seferin kaydedilmesi gerekir'");
		Else
			WarningText = NStr("vi = 'Chứng từ đã bị thay đổi. Để mở biểu mẫu chọn, cần phải ghi lại chuyến đi';
								|ru = 'Документ был изменен. Для открытия формы подбора необходимо записать рейс';
								|en = 'The document was changed. To open the pick form, save the trip'; fa = 'The document was changed. To open the pick form, save the trip';
								|it = 'The document was changed. To open the pick form, save the trip';
								|pl = 'The document was changed. To open the pick form, save the trip';
								|tr = 'Belge değiştirildi. Seçim formunu açmak için seferin yazılması gerekir'");
		EndIf;
		
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	Cancel = False;
	CheckContentBeforeSelection(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	OpenDataSelection();
	
EndProcedure

&AtClient
Procedure DeliverToCarrier(Command)
	
	CurrentData = Items.DeliveredItems.CurrentData;
	
	If CurrentData = Undefined Then
		
		WarningText = NStr("vi = 'Chọn một dòng hàng hóa';
							|ru = 'Выберите строку товаров';
							|en = 'Select a goods line'; fa = 'Select a goods line';
							|it = 'Select a goods line';
							|pl = 'Select a goods line';
							|tr = 'Mal satırını seçin'");
		DoMessageBoxAsync(WarningText);
		
	Else
		
		FormCaption = NStr("vi = 'Lựa chọn bên vận chuyển';
							|ru = 'Выбор перевозчика';
							|en = 'Select a carrier'; fa = 'Select a carrier';
							|it = 'Select a carrier';
							|pl = 'Select a carrier';
							|tr = 'Taşıyıcı seçimi'");
		CallbackDescription = New CallbackDescription("EndOfCarrierSelection", ThisObject);
		ChoiceParameters = New Structure;
		ChoiceParameters.Insert("FormCaption", FormCaption);
		ChoiceParameters.Insert("Recipient", Recipient);
		ChoiceParameters.Insert("RecipientPoint", DeliveryPoint);
		ChoiceParameters.Insert("Recipient_Area", DeliveryZone);
		
		OpenForm("Document.Trip.Form.DeliveryPointChoiceForm", ChoiceParameters, ThisObject,,,, CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeCarrier(Command)
	
	CurrentData = Items.DeliveredItems.CurrentData;
	
	If CurrentData = Undefined Then
		
		WarningText = NStr("vi = 'Chọn một dòng hàng hóa';
							|ru = 'Выберите строку товаров';
							|en = 'Select a goods line'; fa = 'Select a goods line';
							|it = 'Select a goods line';
							|pl = 'Select a goods line';
							|tr = 'Mal satırını seçin'");
		DoMessageBoxAsync(WarningText);
		
	Else
		
		FormCaption = NStr("vi = 'Đổi bên vận chuyển';
							|ru = 'Смена перевозчика';
							|en = 'Change the carrier'; fa = 'تغییر حمل‌کننده';
							|it = 'Change the carrier';
							|pl = 'Change the carrier';
							|tr = 'Taşıyıcı değişikliği'");
		CallbackDescription = New CallbackDescription("EndOfCarrierChange", ThisObject);
		ChoiceParameters = New Structure;
		ChoiceParameters.Insert("FormCaption", FormCaption);
		ChoiceParameters.Insert("Carrier", Recipient);
		ChoiceParameters.Insert("DeliveryPoint", DeliveryPoint);
		ChoiceParameters.Insert("DeliveryZone", DeliveryZone);
		ChoiceParameters.Insert("SelectOnlyCarrier", True);
		ChoiceParameters.Insert("Recipient", CurrentData.FinalDestination);
		
		OpenForm("Document.Trip.Form.DeliveryPointChoiceForm", ChoiceParameters, ThisObject,,,, CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliverByOurForces(Command)
	
	CurrentData = Items.DeliveredItems.CurrentData;
	
	If CurrentData = Undefined Then
		
		WarningText = NStr("vi = 'Chọn một dòng hàng hóa';
							|ru = 'Выберите строку товаров';
							|en = 'Select a goods line'; fa = 'Select a goods line';
							|it = 'Select a goods line';
							|pl = 'Select a goods line';
							|tr = 'Mal satırını seçin'");
		DoMessageBoxAsync(WarningText);
		
	Else
		
		FormCaption = NStr("vi = 'Điểm nhận hàng';
							|ru = 'Пункт получателя';
							|en = 'Recipient point'; fa = 'نقطه گیرنده';
							|it = 'Recipient point';
							|pl = 'Recipient point';
							|tr = 'Alıcı noktası'");
		CallbackDescription = New CallbackDescription("EndDeliveryByOurForces", ThisObject);
		ChoiceParameters = New Structure;
		ChoiceParameters.Insert("FormCaption", FormCaption);
		ChoiceParameters.Insert("Recipient", CurrentData.FinalDestination);
		ChoiceParameters.Insert("RecipientPoint", CurrentData.DeliveryEndpointPlan );
		ChoiceParameters.Insert("Recipient_Area", CurrentData.FinalDeliveryZonePlan);
		ChoiceParameters.Insert("SelectOnlyRecipient", True);
		
		OpenForm("Document.Trip.Form.DeliveryPointChoiceForm", ChoiceParameters, ThisObject,,,, CallbackDescription);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure TransferContentTo_Document()
	
	Result = New Structure();
	Result.Insert("Modified", Modified);
	Result.Insert("ConnectionKey", ConnectionKey);
	
	If Modified Then
		
		Addresses = AddressesOfDeliveredGoods();
		AddressDeliveredGoods = Addresses.AddressDeliveredGoods;
		AddressDeliveredGoodsChanges = Addresses.AddressDeliveredGoodsChanges;
		
	Else
		
		AddressDeliveredGoods = "";
		AddressDeliveredGoodsChanges = "";
		
	EndIf;
	
	Result.Insert("AddressDeliveredGoods", AddressDeliveredGoods);
	Result.Insert("AddressDeliveredGoodsChanges", AddressDeliveredGoodsChanges);
	
	Modified = False;
	
	Close(Result);
	
EndProcedure

&AtServer
Function AddressesOfDeliveredGoods()
	
	Result = New Structure;
	Result.Insert("AddressDeliveredGoods", "");
	Result.Insert("AddressDeliveredGoodsChanges", "");
	
	TableOfDeliveredGoods = DeliveredItems.Unload();
	Result.AddressDeliveredGoods = PutToTempStorage(
		TableOfDeliveredGoods,
		UUID);
	
	TableDeliveredGoodsChanges = DeliveredItemsChanges.Unload();
	Result.AddressDeliveredGoodsChanges = PutToTempStorage(
		TableDeliveredGoodsChanges,
		UUID);
	
	Return Result;
	
EndFunction

&AtClient
Procedure RecalculateResultsOfDocuments()
	
	RecalculateResultsOfDocumentsAtServer();
	
EndProcedure

&AtServer
Procedure RecalculateResultsOfDocumentsAtServer()
	
	GroupColumns = GroupingColumnsByDocuments();
	RowGroupingColumns = StrConcat(GroupColumns, ",");
	
	TotalingColumns = New Array; // Array of String
	TotalingColumns.Add("Net_Weight");
	TotalingColumns.Add("Weight");
	TotalingColumns.Add("VolumeM3");
	RowSummationColumns = StrConcat(TotalingColumns, ",");
	
	AllDocumentColumns = New Array; // Array of String
	AllDocumentColumns.Add("Canceled");
	AllDocumentColumns.Add("CancellationReason");
	CommonClientServer.SupplementArray(AllDocumentColumns, GroupColumns);
	CommonClientServer.SupplementArray(AllDocumentColumns, TotalingColumns);
	AllDocumentColumnsInRow = StrConcat(AllDocumentColumns, ",");
	
	IntermediateTable = DeliveredItems.Unload(, AllDocumentColumnsInRow);
	
	LinesToDelete = New Array; // Array of ValueTableRow
	For Each TableRow In IntermediateTable Do
		
		If TableRow.Canceled Then
			LinesToDelete.Add(TableRow);
		EndIf;
		
	EndDo;
	TMCommonUse.DeleteTableRows(IntermediateTable, LinesToDelete);
	
	IntermediateTable.GroupBy(RowGroupingColumns, RowSummationColumns);
	
	TableDocuments.Load(IntermediateTable);
	
EndProcedure

&AtServer
Procedure DeleteIrrelevantGoodsLines()
	
	GroupColumns = GroupingColumnsByDocuments();
	RowGroupingColumns = StrConcat(GroupColumns, ",");
	ProductKeys = DeliveredItems.Unload(, RowGroupingColumns);
	ProductKeys.GroupBy(RowGroupingColumns);
	RowFilter = New Structure(RowGroupingColumns);
	
	For Each GoodsKeyString In ProductKeys Do
		
		FillPropertyValues(RowFilter, GoodsKeyString);
		DocumentStrings = TableDocuments.FindRows(RowFilter);
		If DocumentStrings.Count() = 0 Then
			
			ProductLines_2 = DeliveredItems.FindRows(RowFilter);
			TMCommonUse.DeleteTableRows(DeliveredItems, ProductLines_2);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function GroupingColumnsByDocuments()
	
	GroupColumns = New Array; // Array of String
	GroupColumns.Add("ReferenceOrder");
	GroupColumns.Add("PlanningDocument");
	
	Return GroupColumns;
	
EndFunction

&AtClientAtServerNoContext
Procedure RecalculateWeightVolumeInCommonUnits(RowOfGoods)
	
	// volume in cubic meters
	If RowOfGoods.MeasuringUnit Then
		RowOfGoods.VolumeM3 = RowOfGoods.Count * RowOfGoods.UnitVolume;
	Else
		RowOfGoods.VolumeM3 = RowOfGoods.NumberOfPackages * RowOfGoods.PackageVolume;
	EndIf;
	
	// Net weight in kg
	RowOfGoods.Net_Weight = RowOfGoods.Count * RowOfGoods.NetWeightUnits;
	
	// gross weight in kg
	If RowOfGoods.MeasuringUnit Then
		RowOfGoods.Weight = RowOfGoods.Net_Weight;
	Else
		RowOfGoods.Weight = RowOfGoods.NumberOfPackages * RowOfGoods.PackageWeight;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CoefficientsWeightVolume(Val Products, Val Package)
	
	EmptyPackaging = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	Result = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(EmptyPackaging, Products,, False);
	MeasuringUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Package);
	Result.Insert("MeasuringUnit", MeasuringUnit);
	Return Result;
	
EndFunction

// Parameters:
//  Result - DialogReturnCode
//  Var_Parameters - Undefined
//
&AtClient
Procedure TableDocumentsBeforeDeleteRowCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		RowID = Items.TableDocuments.CurrentRow; // Number
		CurrentRow = TableDocuments.FindByID(RowID);
		TableDocuments.Delete(CurrentRow);
		Modified = True;
		
		DeleteIrrelevantGoodsLines();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInNetWeightOfUnit(RowOfGoods)
	
	ProductData_1 = CoefficientsWeightVolume(RowOfGoods.Products, RowOfGoods.Package);
	RowOfGoods.NetWeightUnits = ProductData_1.Net_Weight; // Number
	RowOfGoods.UnitVolume = ProductData_1.VolumeM3; // Number
	RowOfGoods.MeasuringUnit = ProductData_1.MeasuringUnit;
	
EndProcedure

&AtClient
Procedure RecalculateGoodsRows(EventName, Source)
	
	RowFilter = New Structure;
	
	If EventName = "Write_Products" Then
		
		RowFilter.Insert("Products", Source);
		
	ElsIf EventName = "Write_ProductPackages" Then
		
		RowFilter.Insert("Package", Source);
		
	Else
		
		Return;
		
	EndIf;
	
	RowsForRecalculate = DeliveredItems.FindRows(RowFilter);
	If RowsForRecalculate.Count() > 0 Then
		
		RecalculateGoodsRowsServer(RowFilter);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateGoodsRowsServer(Val RowFilter)
	
	RowsForRecalculate = DeliveredItems.FindRows(RowFilter);
	
	StructureOfActions = New Structure;
	
	If RowFilter.Property("Products") Then
		
		FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
		StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
		StructureOfActions.Insert("CheckCharacteristicsByOwner", Undefined);
		StructureOfActions.Insert("CheckFillPackageByOwner", Undefined);
		
	EndIf;
	
	StructureOfActions.Insert("FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	StructureOfActions.Insert("FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	StructureOfActions.Insert("FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	StructureOfActions.Insert("FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsForRecalculate, StructureOfActions, DeliveredItems);
	
	For Each RowOfGoods In RowsForRecalculate Do
		
		FillInNetWeightOfUnit(RowOfGoods);
		RecalculateWeightVolumeInCommonUnits(RowOfGoods);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateNumberingOfGoods(DeliveredItems)
	
	RowsCount = DeliveredItems.Count() - 1;
	For RowIndex = 0 To RowsCount Do
		DeliveredItems[RowIndex].LineNumber = RowIndex + 1;
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckContentBeforeSelection(Cancel)
	
	If Not ValueIsFilled(Organization) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText,, "Organization",, Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Warehouse) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
						|ru = 'Поле ""Склад"" не заполнено';
						|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
						|it = 'Il campo ""Magazzino"" non è compilato';
						|pl = 'Nie wypełniono pola ""Magazyn""';
						|tr = '""Ambar"" alanı doldurulmamış'");
		CommonClient.MessageToUser(ErrorText,, "Warehouse",, Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(DeliveryMethod) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Phương thức giao hàng""';
						|ru = 'Поле ""Способ доставки"" не заполнено';
						|en = 'The ""Delivery method"" field is not filled'; fa = 'The ""Delivery method"" field is not filled';
						|it = 'Поле ""Способ доставки"" не заполнено';
						|pl = 'The ""Delivery method"" field is not filled';
						|tr = '""Transfer yöntemi"" alanı doldurulmamış'");
		CommonClient.MessageToUser(ErrorText,, "DeliveryMethod",, Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenDataSelection()
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Organization);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("DeliveryMethod", DeliveryMethod);
	FormParameters.Insert("Carrier", Carrier);
	FormParameters.Insert("DateOfShipment", DateOfDeparture);
	FormParameters.Insert("ConsiderQuantityInDocument", Not FlightHasBeenCompleted);
	FormParameters.Insert("DocumentDeliveries", FlightLink);
	FormParameters.Insert("Recipient", Recipient);
	FormParameters.Insert("DeliveryPoint", DeliveryPoint);
	FormParameters.Insert("DeliveryZone", DeliveryZone);
	
	FixedSelectionFields = New ValueList(); // ValueList of String
	FixedSelectionFields.Add("Recipient");
	FormParameters.Insert("FixedSelectionFields", FixedSelectionFields);
	
	FormParameters.Insert("DeliveryPointFixed", DeliveryPoint);
	FormParameters.Insert("DeliveryZoneFixed", DeliveryZone);
	FormParameters.Insert("RecordDeliveryParameters", True);
	
	If Operation = PredefinedValue("Enum.TripOperations.Unloading") Then
		FormParameters.Insert("DeliveryType", PredefinedValue("Enum.DeliveryTypes.OutgoingInfo"));
	Else
		FormParameters.Insert("DeliveryType", PredefinedValue("Enum.DeliveryTypes.IncomingDataMessage"));
	EndIf;
	
	OpenForm("DataProcessor.PickGoodsToDeliveryDocument.Form.PickForm",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

// Parameters:
//  ValueSelected - Structure:
//   * AddressOfSelectedItems - String
//
&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(Val ValueSelected)
	
	SelectedGoods = SelectedGoods(ValueSelected);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	NewContentLines = New Array; // Array of FormDataCollectionItem
	ChangedContentLines = New Array; // Array of FormDataCollectionItem
	
	FilterContent = New Structure;
	FilterContent.Insert("ReferenceOrder", Undefined);
	FilterContent.Insert("PlanningDocument", Undefined);
	FilterContent.Insert("RowCode", 0);
	FilterContent.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	FilterContent.Insert("Canceled", False);
	
	StructureOfActionRecalculateNumberOfPackagingUnits = New Structure("RecalculateNumberOfPackages", Undefined);
	
	For Each StringMatched In SelectedGoods Do
		
		FillPropertyValues(FilterContent, StringMatched);
		ContentLinesByGoods = DeliveredItems.FindRows(FilterContent);
		If ContentLinesByGoods.Count() > 0 Then
			
			SuitableContentLine = ContentLinesByGoods[0];
			SuitableContentLine.Count = SuitableContentLine.Count + StringMatched.Count;
			ChangedContentLines.Add(SuitableContentLine);
			
		Else
			
			SuitableContentLine = DeliveredItems.Add();
			FillPropertyValues(SuitableContentLine, StringMatched);
			SuitableContentLine.ConnectionKey = ConnectionKey;
			NewContentLines.Add(SuitableContentLine);
			
		EndIf;
		
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesInTSLine(
			SuitableContentLine, StructureOfActionRecalculateNumberOfPackagingUnits, CachedValues);
		
	EndDo;
	
	UpdateNumberingOfGoods(DeliveredItems);
	
	StructureOfActions = New Structure;
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActions.Insert("CheckFillPackageByOwner", Undefined);
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	
	StructureOfActions.Insert("FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	StructureOfActions.Insert("FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	StructureOfActions.Insert("FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	StructureOfActions.Insert("FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		NewContentLines, StructureOfActions, DeliveredItems, CachedValues);
	
	For Each RowWithContent In NewContentLines Do
		
		FillInNetWeightOfUnit(RowWithContent);
		RecalculateWeightVolumeInCommonUnits(RowWithContent);
		
	EndDo;
	
	For Each RowWithContent In ChangedContentLines Do
		
		RecalculateWeightVolumeInCommonUnits(RowWithContent);
		
	EndDo;
	
	Documents.Trip.FillInAdditionalContentParameters(ChangedContentLines);
	Documents.Trip.FillInAdditionalContentParameters(NewContentLines);
	
	RecalculateResultsOfDocumentsAtServer();
	
EndProcedure

// Parameters:
//  ValueSelected - Structure - selected value:
// * AddressOfSelectedItems - String - 
// 
// Returns:
//  ValueTable - Table of selected products:
//  * DeliveryTo - CatalogRef.Partners
//  * DeliveryPoint - CatalogRef.DeliveryPoints
//  * DeliveryZone - CatalogRef.DeliveryZones
//  * Count - Number
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure
//
&AtServer
Function SelectedGoods(ValueSelected)
	
	SelectedGoods = GetFromTempStorage(ValueSelected.AddressOfSelectedItems); // ValueTable
	DeleteFromTempStorage(ValueSelected.AddressOfSelectedItems);
	Return SelectedGoods;
	
EndFunction

&AtClient
Procedure UpdateItemAvailability()
	
	CurrentRow = Items.DeliveredItems.CurrentData;
	
	If CommandsToChangeDeliveryParametersAreAvailable Then
		
		If CurrentRow = Undefined Then
			
			Items.DeliveredItemsDeliverToCarrier.Enabled = False;
			Items.DeliveredItemsChangeCarrier.Enabled = False;
			Items.DeliveredItemsDeliverByOurForces.Enabled = False;
			Items.DeliveredItemsCanceled.ReadOnly = True;
			
		ElsIf Recipient <> CurrentRow.FinalDestination Then
			
			// This is delivery to the carrier
			Items.DeliveredItemsDeliverToCarrier.Enabled = False;
			Items.DeliveredItemsChangeCarrier.Enabled = True;
			Items.DeliveredItemsDeliverByOurForces.Enabled = True;
			
		Else
			
			// This is delivery by our forces
			Items.DeliveredItemsDeliverToCarrier.Enabled = True;
			Items.DeliveredItemsChangeCarrier.Enabled = False;
			Items.DeliveredItemsDeliverByOurForces.Enabled = False;
			
		EndIf;
	
	EndIf;
	
	If CurrentRow <> Undefined Then
		
		UpdateRowCancellationAvailability(CurrentRow);
		
	EndIf;
	
	UpdateAvailabilityOfSpecialConditionsOfCarriage(CurrentRow);
	
EndProcedure

&AtServer
Procedure AddColumnsOfDeliveredGoods(TableContents)
	
	AnalysisColumns = "ReferenceOrder, PlanningDocument, RowCode";
	TableOfDeliveredGoods = TableContents.Copy(, AnalysisColumns);
	TableOfDeliveredGoods.GroupBy(AnalysisColumns);
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TTDataContent.ReferenceOrder AS ReferenceOrder,
	|	TTDataContent.PlanningDocument AS PlanningDocument,
	|	TTDataContent.RowCode AS RowCode
	|INTO TTDataContent
	|FROM
	|	&DataContent AS TTDataContent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataContent.ReferenceOrder AS ReferenceOrder,
	|	TTDataContent.PlanningDocument AS PlanningDocument,
	|	TTDataContent.RowCode AS RowCode,
	|	ISNULL(DeliveryShoulder1.Recipient, UNDEFINED) AS RecipientShoulder1,
	|	ISNULL(DeliveryShoulder1.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS RecipientPointShoulder1,
	|	ISNULL(DeliveryShoulder1.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef)) AS RecipientAreaShoulder1,
	|	ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED) AS Recipient,
	|	ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS RecipientPoint,
	|	ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Recipient_Area
	|FROM
	|	TTDataContent AS TTDataContent
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
	|		ON TTDataContent.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
	|			AND TTDataContent.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
	|			AND TTDataContent.RowCode = DeliveryFinalLeverage.RowCode
	|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
	|			AND (DeliveryFinalLeverage.OperationLevel IN (15, 20))
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryShoulder1
	|		ON TTDataContent.ReferenceOrder = DeliveryShoulder1.ReferenceOrder
	|			AND TTDataContent.PlanningDocument = DeliveryShoulder1.PlanningDocument
	|			AND TTDataContent.RowCode = DeliveryShoulder1.RowCode
	|			AND (DeliveryShoulder1.Arm = 1)
	|			AND (DeliveryShoulder1.OperationLevel IN (15, 20))";
	Query.Text = QueryText;
	Query.SetParameter("DataContent", TableOfDeliveredGoods);
	DeliveryDataOnShoulders = Query.Execute().Unload();
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ReferenceOrder");
	TheStructureOfTheSearch.Insert("PlanningDocument");
	TheStructureOfTheSearch.Insert("RowCode");
	
	For Each DeliveryGoodsLine In DeliveredItems Do
		
		FillPropertyValues(TheStructureOfTheSearch, DeliveryGoodsLine);
		DataRows = DeliveryDataOnShoulders.FindRows(TheStructureOfTheSearch);
		If DataRows.Count() > 0 Then
			
			DataString1 = DataRows[0];
			
			DeliveryGoodsLine.FinalDestination = DataString1.Recipient;
			DeliveryGoodsLine.DeliveryEndpointPlan = DataString1.RecipientPoint;
			DeliveryGoodsLine.FinalDeliveryZonePlan = DataString1.Recipient_Area;
			
			// Now only the first delivery arm is planned for flights, so we check it
			If Recipient <> DataString1.RecipientShoulder1
				Or DeliveryPoint <> DataString1.RecipientPointShoulder1
				Or DeliveryZone <> DataString1.RecipientAreaShoulder1 Then
				
				DeliveryGoodsLine.ThereAreChangesToSourceData = True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
EndProcedure

// Parameters:
//  Result - Structure:
//  * Carrier - CatalogRef.Partners
//  * DeliveryPoint - CatalogRef.DeliveryPoints
//  * DeliveryZone - CatalogRef.DeliveryZones
//  * Recipient - CatalogRef.Partners, CatalogRef.Warehouses -
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  AdditionalParameters - Undefined
//
&AtClient
Procedure EndOfCarrierSelection(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Cancel
		Or Result = Undefined Then
		
		Return;
		
	EndIf;
	
	CurrentData = Items.DeliveredItems.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ItemRowIds = New Array; // Array of Number
	ItemRowIds.Add(CurrentData.GetID());
	
	EndOfCarrierSelectionServer(Result, ItemRowIds);
	
	Modified = True;
	
	NotificationTitle = NStr("vi = 'Giao hàng cho bên vận chuyển';
							|ru = 'Доставка до перевозчика';
							|en = 'Delivery to carrier'; fa = 'تحویل به حمل‌کننده';
							|it = 'Delivery to carrier';
							|pl = 'Delivery to carrier';
							|tr = 'Taşıyıcıya kadar teslimat'");
	NotificationHeaderTemplate = NStr("vi = '%1, %2';
										|ru = '%1, %2';
										|en = '%1, %2'; fa = '%1, %2';
										|it = '%1, %2';
										|pl = '%1, %2';
										|tr = '%1, %2'");
	ExplanationText =  StringFunctionsClientServer.SubstituteParametersToString(
		NotificationHeaderTemplate,
		String(Result.Carrier),
		String(Result.DeliveryPoint));
	
	ShowUserNotification(NotificationTitle,, ExplanationText);
	
EndProcedure

&AtServer
Procedure EndOfCarrierSelectionServer(Val Result, Val ItemRowIds)
	
	LinesToDelete = New Array; // Array of FormDataCollectionItem
	
	For Each IdOfGoodsLine In ItemRowIds Do
		
		RowOfProduct = DeliveredItems.FindByID(IdOfGoodsLine);
		
		ChangesRow = DeliveredItemsChanges.Add();
		FillPropertyValues(ChangesRow, RowOfProduct);
		
		ChangesRow.Carrier = Result.Carrier;
		ChangesRow.DeliveryPoint = Result.DeliveryPoint;
		ChangesRow.DeliveryZone = Result.DeliveryZone;
		
		ChangesRow.FinalDestination = Result.Recipient;
		ChangesRow.FinalDeliveryPoint = Result.RecipientPoint;
		ChangesRow.FinalDeliveryArea = Result.Recipient_Area;
		
		LinesToDelete.Add(RowOfProduct);
		
	EndDo;
	
	TMCommonUse.DeleteTableRows(DeliveredItems, LinesToDelete);
	
	RecalculateResultsOfDocumentsAtServer();
	
EndProcedure

// Parameters:
//  Result - Structure:
//  * Carrier - CatalogRef.Partners
//  * DeliveryPoint - CatalogRef.DeliveryPoints
//  * DeliveryZone - CatalogRef.DeliveryZones
//  AdditionalParameters - Undefined
//
&AtClient
Procedure EndOfCarrierChange(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Cancel
		Or Result = Undefined Then
		
		Return;
		
	EndIf;
	
	CurrentData = Items.DeliveredItems.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ItemRowIds = New Array; // Array of Number
	ItemRowIds.Add(CurrentData.GetID());
	
	EndOfCarrierChangeServer(Result, ItemRowIds);
	
	Modified = True;
	
	NotificationTitle = NStr("vi = 'Thay đổi bên vận chuyển';
							|ru = 'Изменение перевозчика';
							|en = 'Change the carrier'; fa = 'تغییر حمل‌کننده';
							|it = 'Change the carrier';
							|pl = 'Change the carrier';
							|tr = 'Taşıyıcı değişikliği'");
	NotificationHeaderTemplate = NStr("vi = '%1, %2';
										|ru = '%1, %2';
										|en = '%1, %2'; fa = '%1, %2';
										|it = '%1, %2';
										|pl = '%1, %2';
										|tr = '%1, %2'");
	ExplanationText =  StringFunctionsClientServer.SubstituteParametersToString(
		NotificationHeaderTemplate,
		String(Result.Carrier),
		String(Result.DeliveryPoint));
	
	ShowUserNotification(NotificationTitle,, ExplanationText);
	
EndProcedure

&AtServer
Procedure EndOfCarrierChangeServer(Val Result, Val ItemRowIds)
	
	LinesToDelete = New Array; // Array of FormDataCollectionItem
	
	For Each IdOfGoodsLine In ItemRowIds Do
		
		RowOfProduct = DeliveredItems.FindByID(IdOfGoodsLine);
		
		ChangesRow = DeliveredItemsChanges.Add();
		FillPropertyValues(ChangesRow, RowOfProduct);
		
		ChangesRow.Carrier = Result.Carrier;
		ChangesRow.DeliveryPoint = Result.DeliveryPoint;
		ChangesRow.DeliveryZone = Result.DeliveryZone;
		
		LinesToDelete.Add(RowOfProduct);
		
	EndDo;
	
	TMCommonUse.DeleteTableRows(DeliveredItems, LinesToDelete);
	
	RecalculateResultsOfDocumentsAtServer();
	
EndProcedure

// Parameters:
//  Result - Structure:
//  * Recipient - CatalogRef.Partners, CatalogRef.Warehouses -
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  AdditionalParameters - Undefined
//
&AtClient
Procedure EndDeliveryByOurForces(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Cancel
		Or Result = Undefined Then
		
		Return;
		
	EndIf;
	
	CurrentData = Items.DeliveredItems.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ItemRowIds = New Array; // Array of Number
	ItemRowIds.Add(CurrentData.GetID());
	
	EndDeliveryByOurForcesServer(Result, ItemRowIds);
	
	Modified = True;
	
	NotificationTitle = NStr("vi = 'Giao hàng bằng phương tiện của chúng tôi';
							|ru = 'Доставка нашими силами';
							|en = 'Our own delivery'; fa = 'Our own delivery';
							|it = 'Our own delivery';
							|pl = 'Our own delivery';
							|tr = 'Tarafımızdan teslimat'");
	NotificationHeaderTemplate = NStr("vi = '%1, %2';
										|ru = '%1, %2';
										|en = '%1, %2'; fa = '%1, %2';
										|it = '%1, %2';
										|pl = '%1, %2';
										|tr = '%1, %2'");
	ExplanationText =  StringFunctionsClientServer.SubstituteParametersToString(
		NotificationHeaderTemplate,
		String(Result.RecipientPoint),
		String(Result.Recipient_Area));
	
	ShowUserNotification(NotificationTitle,, ExplanationText);
	
EndProcedure

&AtServer
Procedure EndDeliveryByOurForcesServer(Val Result, Val ItemRowIds)
	
	LinesToDelete = New Array; // Array of FormDataCollectionItem
	
	For Each IdOfGoodsLine In ItemRowIds Do
		
		RowOfProduct = DeliveredItems.FindByID(IdOfGoodsLine);
		
		ChangesRow = DeliveredItemsChanges.Add();
		FillPropertyValues(ChangesRow, RowOfProduct);
		
		ChangesRow.FinalDestination = Result.Recipient;
		ChangesRow.FinalDeliveryPoint = Result.RecipientPoint;
		ChangesRow.FinalDeliveryArea = Result.Recipient_Area;
		
		LinesToDelete.Add(RowOfProduct);
		
	EndDo;
	
	TMCommonUse.DeleteTableRows(DeliveredItems, LinesToDelete);
	
	RecalculateResultsOfDocumentsAtServer();
	
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfFieldsByStatus()
	
	If ReadOnly Then
		Return;
	EndIf;
	
	BlockedFields = New Array; // Array of String
	
	ProhibitChangingCompositionOfLines = False;
	
	If FlightStatus = Enums.TripStatuses.Generated1
	 Or FlightStatus = Enums.TripStatuses.Shipped_5 Then
		
		ProhibitChangingCompositionOfLines = True;
		
	ElsIf FlightStatus = Enums.TripStatuses.Completed Then
		
		BlockedFields.Add(Items.DeliveredItemsDeliveryTime.Name);
		BlockedFields.Add(Items.DeliveredItemsGroupInformation.Name);
		
		ProhibitChangingCompositionOfLines = True;
		
	ElsIf FlightStatus = Enums.TripStatuses.RolledBack_ Then
		
		BlockedFields.Add(Items.DeliveredItemsDeliveryTime.Name);
		BlockedFields.Add(Items.DeliveredItemsGroupInformation.Name);
		BlockedFields.Add(Items.DeliveredItemsCanceled.Name);
		
	Else
		
		CommandsToChangeDeliveryParametersAreAvailable = True;
		
	EndIf;
	
	If Not CommandsToChangeDeliveryParametersAreAvailable Then
		
		BlockedFields.Add(Items.DocumentsToPickUpData.Name);
		BlockedFields.Add(Items.DeliveredItemsPickUpData.Name);
		BlockedFields.Add(Items.DeliveredItemsDeliverToCarrier.Name);
		BlockedFields.Add(Items.DeliveredItemsChangeCarrier.Name);
		BlockedFields.Add(Items.DeliveredItemsDeliverByOurForces.Name);
		
	EndIf;
	
	If ProhibitChangingCompositionOfLines Then
		
		Items.TableDocuments.ChangeRowSet = False;
		Items.DeliveredItems.ChangeRowSet = False;
		
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, BlockedFields, "ReadOnly", True);
	
EndProcedure

&AtClient
Procedure UpdateRowCancellationAvailability(RowData)
	
	If RowData <> Undefined Then
		
		Items.DeliveredItemsReasonForCancellation.ReadOnly = Not RowData.Canceled;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfSpecialConditionsOfCarriage(RowData)
	
	If RowData <> Undefined Then
		
		Items.DeliveredItemsSpecialConditionsOfCarriageDescription.ReadOnly = Not RowData.SpecialTransportationConditions;
		
	EndIf;
	
EndProcedure

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetConditionalAppearanceOfUnfilledWeightOfPackagingUnit();
	SetConditionalAppearanceOfUnfilledVolumeOfPackage();
	SetConditionalAppearanceUnfilledNetWeight();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "DeliveredItemsCharacteristic", "DeliveredItems.ItemVariantsAreUsed");
	
	SetConditionalAppearanceOfSeries();
	
	UnitDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	UnitDesignParameters.NameOfUnitField = "DeliveredItemsProductsUnitOfMeasure";
	UnitDesignParameters.PathToPackagingUnitField = "DeliveredItems.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, UnitDesignParameters);
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.DeliveredItems,
		Items.DeliveredItemsCanceled.Name,
		Items.DeliveredItemsReasonForCancellation.Name);
	
	SetConditionalAppearanceUnfilledWeightVolumeAccordingToDocuments();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfSeries()
	
	ListOfTypesForSeries = New ValueList; // ValueList of EnumRef.ItemsTypes
	ListOfTypesForSeries.Add(Enums.ItemsTypes.OwnGoods);
	ListOfTypesForSeries.Add(Enums.ItemsTypes.ReusablePackage);
	
	PathToSeriesField = "DeliveredItems.Series";
	PathToSelectionFieldProductType = "DeliveredItems.ItemsType";
	NameOfSeriesFormField = Items.DeliveredItemsSeries.Name; // FormField
	
	// For goods
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSeriesFormField);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfTypesForSeries;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
																		|ru = '<для товаров>';
																		|en = '<for goods>'; fa = '<for goods>';
																		|it = '<per le merci>';
																		|pl = '<dla towarów>';
																		|tr = '<ürünler için>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// The series is not specified
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSeriesFormField);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSeriesField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTypesForSeries;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
																		|ru = '<серия не указывается>';
																		|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
																		|it = '<serie non è indicata>';
																		|pl = '<seria nie jest określana>';
																		|tr = '<parti belirtilmemektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure SetConditionalAppearanceUnfilledNetWeight()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveredItemsNet_Weight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveredItems.NetWeightUnits");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfUnfilledVolumeOfPackage()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveredItemsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveredItems.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfUnfilledWeightOfPackagingUnit()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveredItemsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveredItems.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceUnfilledWeightVolumeAccordingToDocuments()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableDocumentsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableDocuments.Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableDocumentsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableDocuments.VolumeM3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableDocumentsNet_Weight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableDocuments.Net_Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
EndProcedure

#EndRegion

#EndRegion