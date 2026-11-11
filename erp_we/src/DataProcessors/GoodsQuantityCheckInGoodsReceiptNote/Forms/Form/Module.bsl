#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CloseWithoutConfirmation; //used to work out the closing of the form

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Verification actions and states are also used in conditional design
	Actions = New Structure;
	Actions.Insert("DoNotTake",        NStr("vi = 'Không tiếp nhận';
											|ru = 'Не принимать';
											|en = 'Do not accept'; fa = 'پذیرفته نشود';
											|it = 'Non ricevere';
											|pl = 'Nie przyjmuj';
											|tr = 'Kabul etme'"));
	Actions.Insert("ReceiveWithoutChecking", NStr("vi = 'Tiếp nhận mà không kiểm tra';
													|ru = 'Принять без проверки';
													|en = 'Receive without checking'; fa = 'دریافت بدون بررسی';
													|it = 'Ricevere senza verifica';
													|pl = 'Przyjmij bez weryfikacji';
													|tr = 'Kontrol etmeden kabul et'"));
	Actions.Insert("AddToDocument",     NStr("vi = 'Thêm vào chứng từ';
											|ru = 'Добавить в документ';
											|en = 'Add to document'; fa = 'افزودن به سند';
											|it = 'Aggiungere al documento';
											|pl = 'Dodaj do dokumentu';
											|tr = 'Belgeye ekle'"));
	Actions.Insert("RemoveFromTheDocument",    NStr("vi = 'Xóa khỏi chứng từ';
													|ru = 'Удалить из документа';
													|en = 'Remove from the document'; fa = 'Remove from the document';
													|it = 'Eliminare dal documento';
													|pl = 'Usunąć z dokumentu';
													|tr = 'Belgeden sil'"));
	
	CheckStatuses = New Structure;
	CheckStatuses.Insert("NotVerified",        NStr("vi = '<không kết chuyển>';
													|ru = '<не проверен>';
													|en = '<not checked>'; fa = '<not checked>';
													|it = '<non verificato>';
													|pl = '<niezweryfikowany>';
													|tr = '<kontrol edilmedi>'"));
	CheckStatuses.Insert("AcceptedWithoutVerification", NStr("vi = '<đã nhận mà không kiểm tra>';
															|ru = '<принят без проверки>';
															|en = '<received without checking>'; fa = '<received without checking>';
															|it = '<approvato senza verifica>';
															|pl = '<zaakceptowany bez weryfikacji>';
															|tr = '<kontrol edilmeden kabul edildi>'"));
	CheckStatuses.Insert("Verified",          NStr("vi = '<đã kết chuyển>';
													|ru = '<проверен>';
													|en = '<checked>'; fa = '<checked>';
													|it = '<verificato>';
													|pl = '<checked>';
													|tr = '<kontrol edildi>'"));
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("AddressInTempStorage") Or (Parameters.Property("WarehouseOperation")
		And Not ValueIsFilled(Parameters.WarehouseOperation)) Then
		
		ExceptionText = NStr("vi = 'Không thể mở biểu mẫu bộ xử lý một cách trực tiếp.';
							|ru = 'Не предусмотрено непосредственное открытие формы обработки.';
							|en = 'Direct opening of the data processor form is not available.'; fa = 'Direct opening of the data processor form is not available.';
							|it = 'Non è prevista un''apertura diretta del modulo di elaborazione.';
							|pl = 'Nie przewidziano bezpośrednie otwieranie formularzu przetwarzania.';
							|tr = 'İşleme formunun doğrudan açılması sağlanmamaktadır.'");
		
		Raise ExceptionText;
		
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	AddressInTempStorage = Parameters.AddressInTempStorage;
	FillPropertyValues(ThisObject, Parameters,,
		"CloseOnChoice,CloseOnOwnerClose,PurposeUseKey,ReadOnly");
	
	FillPropertyValues(Object, Parameters);
	PackingListParent = Parameters.PackingListParent;
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	
	ItemsFromStorage = GetFromTempStorage(AddressInTempStorage);
	RawGoods.Load(ItemsFromStorage);
	
	If ValueIsFilled(PackingListParent) Then
		Object.Ref = PackingListParent;
		PackingLists.Load(
			RawGoods.Unload(
				New Structure("ThisIsAPackingList", True),
				"PackingListCode,PackingListDate,PackingList,PackingListParent"));
	Else
		Object.Ref = Parameters.WarehouseDocument;
	EndIf;
	
	EntryLevelTitle = Metadata.Documents.GoodsReceiptNote.ObjectPresentation;
	
	ThereAreLabeledProducts = Parameters.ThereAreLabeledProducts;
	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisObject, Object.Goods, EntryLevelTitle, False, PackingListParent);
	
	If Not UsePackingLists Then
		
		Items.GoodsGroupTheAmountTheState.Title            = NStr("vi = 'Số lượng';
																	|ru = 'Количество';
																	|en = 'Quantity'; fa = 'مقدار';
																	|it = 'Quantità';
																	|pl = 'Ilość';
																	|tr = 'Miktar'");
		Items.SurplusesGroupProductPackingList.Title   = NStr("vi = 'Hàng hóa';
																|ru = 'Товар';
																|en = 'Product'; fa = 'کالا';
																|it = 'Merce';
																|pl = 'Towar';
																|tr = 'Ürün'");
		Items.ShortagesGroupProductPackingList.Title = NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Product';
															|tr = 'Ürün'");
		Items.GroupHighlightingDiscrepancies.Representation = UsualGroupRepresentation.None;
		
	EndIf;
	
	If Not Object.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient Then
		Items.GoodsDocumentShipments.Visible    = False;
		Items.SurplusesDocumentShipments.Visible   = False;
		Items.ShortagesDocumentShipments.Visible = False;
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.GoodsQuantityCheckInGoodsReceiptNote);
	Items.GoodsSeries.Visible =
		ValueIsFilled(SeriesSpecificationParameters) And SeriesSpecificationParameters.UseItemsBatch;
	
	ChoiceList = Items.UncheckedPackingListsAction.ChoiceList;
	ChoiceList.Clear();
	// The default action value is not filled in: if an empty value is selected (the view is not empty),
	//	then conditional formatting is used to display the empty value.
	ChoiceList.Add("", Actions.ReceiveWithoutChecking);
	ChoiceList.Add(Actions.DoNotTake, Actions.DoNotTake);
	
	ChoiceList = Items.SurplusesAction.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("", Actions.DoNotTake);
	ChoiceList.Add(Actions.AddToDocument, Actions.AddToDocument);
	
	ChoiceList = Items.ShortagesAction.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("", Actions.RemoveFromTheDocument);
	ChoiceList.Add(Actions.ReceiveWithoutChecking, Actions.ReceiveWithoutChecking);
	
	If UserRightsCached.ThisIsPartner() Then
		Items.GoodsImportDataFromPDT.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	CloseWithoutConfirmation = False;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseWithoutConfirmation
		And ThereAreDiscrepancies Then
		
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Đã thay đổi dữ liệu. Sẽ mất tất cả các thay đổi.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			Return;
		EndIf;
		
		CallbackDescription = New CallbackDescription("HandlingIssueBeforeClosing", ThisObject);
		QuestionButtons = New ValueList;
		QuestionButtons.Add(DialogReturnCode.Yes,NStr("vi = 'Kết thúc';
														|ru = 'Завершить';
														|en = 'Exit'; fa = 'خروج';
														|it = 'Completare';
														|pl = 'Exit';
														|tr = 'Tamamla'"));
		QuestionButtons.Add(DialogReturnCode.No,NStr("vi = 'Tiếp tục kiểm tra';
													|ru = 'Продолжить проверку';
													|en = 'Continue checking'; fa = 'ادامه بررسی';
													|it = 'Continuare la verifica';
													|pl = 'Kontynuuj weryfikację';
													|tr = 'Kontrolü devam et'"));
		ShowQueryBox(CallbackDescription,
			NStr("vi = 'Kết thúc kiểm tra mà không chuyển chênh lệch vào chứng từ?';
				|ru = 'Завершить проверку без переноса расхождений в документ?';
				|en = 'Finish checking without discrepancy transfer to the document?'; fa = 'Finish checking without discrepancy transfer to the document?';
				|it = 'Concludere la verifica senza trasferire le discrepanze al documento?';
				|pl = 'Zakończyć weryfikację bez przeniesienia odchylenia do dokumentu?';
				|tr = 'Tutarsızlıklar belgeye aktarılmadan kontrol tamamlansın mı?'"), QuestionButtons);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	CurrentData = Items.Goods.CurrentData;
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		// The preliminary status 11 may turn into the status 12, which is incorrect for the order, we will recalculate the status of the series.
		If CurrentData.BatchesIndicationStatus = 12 Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("CheckSeriesCalculateStatus",
				New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		EndIf;
	
	ElsIf ChoiceSource.FormName = "Catalog.Products.Form.ChoiceForm" Then
		
		CurrentData.Products = ValueSelected;
		ProductsPackingListWhenChanged("GoodsProducts", CachedValues);
		Items.Goods.CurrentItem = Items.GoodsNumberOfPackages;
		Items.Goods.CurrentItem = Items.GoodsProducts;
		
	ElsIf ChoiceSource.FormName = "Document.PackingList.Form.ChoiceForm" Then
		
		CurrentData.PackingList = ValueSelected;
		ProductsPackingListWhenChanged("GoodsPackingList", CachedValues);
		Items.Goods.EndEditRow(False);
		
	ElsIf ChoiceSource.FormName = "Document.GoodsReceiptNote.Form.ShippingDocumentChoiceForm" Then
		
		Modified = True;
		CurrentData.DocumentShipments = ValueSelected;
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		Items.Goods.CurrentData.Purpose = ValueSelected;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	PackingListsClient.BeforeYouStartAddingVTCHSPackingLists(Items.Goods, Cancel, Copy, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	PackingListsClient.AtBeginningOfEditingPMWithPackingLists(ThisForm, CachedValues, NewRow);
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	PackingListsClient.AtEndOfEditingPMWithPackingLists(ThisForm, NewRow, CancelEdit);
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	PackingListsClient.BeforeDeletingPMLinesWithPackingSheets(Items.Goods, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	GoodsAfterDeleteRowServer(CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsProductsStartChoice(Item, ChoiceData, StandardProcessing)
	PackingListsClient.StartOfProductPlaceSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ProductsNomenclaturePackingListIfChanged(Item)
	
	ProductsPackingListWhenChanged(Item.Name, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume");
	CurrentRow = Items.Goods.CurrentData;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsDocumentShipmentsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Object.Warehouse);
	FormParameters.Insert("Products", CurrentRow.Products);
	FormParameters.Insert("Characteristic", CurrentRow.Characteristic);
	FormParameters.Insert("SelectByProduct", True);
	OpenForm("Document.GoodsReceiptNote.Form.ShippingDocumentChoiceForm",
		FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishCheck(Command)
	
	ClearMessages();
	
	Result = FinishCheckServer();
	
	If Result = "HasFillingErrors" Then
		Return;
	ElsIf Result = "ThereAreDiscrepancies" Then
		
		Items.PagesCheckSteps.CurrentPage = Items.PageDiscrepancyProcessing;
		Items.PagesBackButton.CurrentPage  = Items.TheBackButtonPageIsDisplayed;
		
	ElsIf Result = "NoDiscrepanciesOrWorkedOut" Then
		
		Items.PagesCheckSteps.CurrentPage = Items.PageDataInput;
		Items.PagesBackButton.CurrentPage  = Items.PageBackButtonEmpty;
		
	ElsIf Result = "CheckIsOverThereAreDiscrepancies" Then
		
		CloseWithoutConfirmation = True;
		Close(AddressInTempStorage);
		
	ElsIf Result = "CheckIsOverThereAreNoDiscrepancies" Then

		CloseWithoutConfirmation = True;
		Close(Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackagesReal = ExecutionResult.Weight;
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeTheQualityOfTheItem(Command)
	
	CurrentRow = Items.Goods.CurrentData;
	ClearMessages();
	
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClientServer.MessageToUser(MessageText);
		Return
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	PackingListsClient.BreakUpPMStringWithPackingLists(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	 	
	CurrentRowID = Items.Goods.CurrentRow;	
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculateWeightVolume");
		
		IDOfNewLine = NewRow.GetID();
				
		ProcessAndRenumberTSStrings(IDOfNewLine, CurrentRowID, StructureOfActions, CachedValues);
		
	EndIf;

EndProcedure

&AtClient
Procedure AddAllSurplusesToNote(Command)
	For Each Page1 In Surpluses Do
		Page1.Action = Actions.AddToDocument; 
	EndDo;
EndProcedure

&AtClient
Procedure DoNotTakeAll(Command)
	For Each Page1 In Surpluses Do
		Page1.Action = ""; 
	EndDo;
EndProcedure

&AtClient
Procedure AcceptEverythingWithoutCheck(Command)
	For Each Page1 In Shortages Do
		Page1.Action = Actions.ReceiveWithoutChecking;
	EndDo;
EndProcedure

&AtClient
Procedure DeleteAllFromTheNote(Command)
	For Each Page1 In Shortages Do
		Page1.Action = ""; 
	EndDo;
EndProcedure

&AtClient
Procedure DoNotTakeAllUnchecked(Command)
	For Each Page1 In UncheckedPackingLists Do
		Page1.Action = Actions.DoNotTake;
	EndDo;
EndProcedure

&AtClient
Procedure AcceptAllPackingListsWithoutCheck(Command)
	For Each Page1 In UncheckedPackingLists Do
		Page1.Action = ""; 
	EndDo;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessAndRenumberTSStrings(IDOfNewLine, CurrentRowID, StructureOfActions, CachedValues)
	
	NewRow = Object.Goods.FindByID(IDOfNewLine);
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartServer.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	PackingListsServer.RenumberLines(ThisForm, Object.Goods);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	FilterList = New ValueList;
	FilterList.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
	FilterList.Add(Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired);
	ItemFilter.RightValue = FilterList;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCheckState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesPackingList.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesCheckState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Surpluses.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesSeries.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Surpluses.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesPackingList.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesCheckState.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shortages.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesSeries.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shortages.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusesAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Surpluses.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", Actions.DoNotTake);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagesAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shortages.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", Actions.RemoveFromTheDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UncheckedPackingListsAction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UncheckedPackingLists.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", Actions.ReceiveWithoutChecking);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentShipments.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	//
	
	PackingListsServer.EstablishConditionalAppearanceTakingIntoAccountPackingLists(ThisForm);
	
EndProcedure

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)

	If CurrentData = Undefined Then
		CurrentData = Items.Goods.CurrentData;
		If CurrentData = Undefined Then
			MessageText = NStr("vi = 'Hãy chọn dòng hàng hóa mà cần chỉ ra sê-ri.';
								|ru = 'Выберите строку товаров, для которой необходимо указать серии.';
								|en = 'Select a goods line for which the batch shall be specified.'; fa = 'Select a goods line for which the batch shall be specified.';
								|it = 'Selezionare la riga dei prodotti per la quale è necessario specificare le serie.';
								|pl = 'Wybierz wiersz towarów, dla których chcesz określić serie.';
								|tr = 'Partisini belirtmek istediğin ürün satırını seç.'");
			ShowMessageBox(Undefined, MessageText);
			Return;
		EndIf;
	EndIf;
	CurDataId = CurrentData.GetID();
	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
	
	ReturnValue_1 = Undefined;

	
	OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm, CurDataId, CachedValues);
    EndIf;

EndProcedure

&AtServer
Function ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm, CurLineProducts, CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions, CachedValues);
	
	PackingListsServer.RenumberLines(ThisForm, Object.Goods);
	
EndFunction

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActionsWithAddedStrings.Insert("RecalculateWeightVolume");
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateWeightVolume");
	
	StructureOfActionsWithLinesFromPackingLists = New Structure;
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithLinesFromPackingLists.Insert("RecalculateWeightVolume");
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.StructureOfActionsWithLinesFromPackingLists  = StructureOfActionsWithLinesFromPackingLists;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.BlockFormData                 = False;
	StructureOfActions.ConsiderPackingLists              = UsePackingLists;
	StructureOfActions.WorkOutChangingPackingLists   = False;
	StructureOfActions.CurrentPackingList                 = PackingListParent;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	For Each Page1 In Object.Goods.FindRows(New Structure("ThisIsAPackingList, CheckState", True, "")) Do
		Page1.CheckState = CheckStatuses.NotVerified;
	EndDo;
	
EndProcedure

&AtClient
Procedure HandlingIssueBeforeClosing(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CloseWithoutConfirmation = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(CachedValues)
	
	PackingListsServer.AfterRemovalOfVTCHSPackingSheets(ThisForm, Object.Goods, False);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If PackingListsClient.CheckPrepareTransitionToPackingListWhenSelecting(Items.Goods, Field.Name) Then
		WhenMovingToAnotherLevelServer(Items.Goods.CurrentData.PackingList);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenMovingToAnotherLevelServer(Var_URL)
	PackingListsServer.WhenMovingToAnotherLevel(ThisForm,
			Object.Goods, Var_URL, EntryLevelTitle, False);
	If Var_URL = Object.Ref
		Or Not ValueIsFilled(Var_URL) Then
		Items.FinishCheck.Title = NStr("vi = 'Kết thúc kiểm tra';
										|ru = 'Завершить проверку';
										|en = 'Finish check'; fa = 'پایان بررسی';
										|it = 'Completare la verifica';
										|pl = 'Zakończ weryfikację';
										|tr = 'Kontrolü bitir'");
		Items.FinishCheck.Picture = New Picture;
	Else
		Items.FinishCheck.Title = NStr("vi = 'Kết thúc kiểm tra danh sách đóng gói';
										|ru = 'Завершить проверку упаковочного листа';
										|en = 'Finish packing list check'; fa = 'Finish packing list check';
										|it = 'Completare la verifica della distinta di imballaggio';
										|pl = 'Zakończ weryfikację listu pakowego';
										|tr = 'Ürün listesi kontrolünü tamamla'");
		Items.FinishCheck.Picture = PictureLib.FromPackingList;
	EndIf;
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTSGoods()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	PackingListsServer.FillInServiceDetails(ThisForm, Object.Goods, StructureOfActions);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure ProductsPackingListWhenChanged(FieldName, CachedValues)
	
	CurrentRow = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	StructureOfActionsWithCurLine = New Structure;
	StructureOfActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithCurLine.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActionsWithCurLine.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActionsWithCurLine.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActionsWithCurLine.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithCurLine.Insert("CheckFillAssignment");
	StructureOfActionsWithCurLine.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithCurLine.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithCurLine.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithCurLine.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithCurLine.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithCurLine.Insert("RecalculateWeightVolume");
	
	PackingListsServer.ProductsPackingListWhenChanged(ThisForm, Object.Goods,
		FieldName, CachedValues, StructureOfActionsWithCurLine, , False);
	If Not ValueIsFilled(CurrentRow.PackingList) Then
		CurrentRow.CheckState = "";
	ElsIf CurrentRow.PackingList <> CachedValues.PackingList Then
		CurrentRow.CheckState = CheckStatuses.NotVerified;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnToCheck(Command)
	Items.PagesCheckSteps.CurrentPage = Items.PageDataInput;
	Items.PagesBackButton.CurrentPage = Items.PageBackButtonEmpty;
EndProcedure

&AtClient
Procedure ExitWithoutChecking(Command)
	If PackingListParent = Object.Ref
		Or Not ValueIsFilled(PackingListParent) Then
		Close();
	Else
		ExitWithoutCheckingServer();
		
		Items.PagesCheckSteps.CurrentPage = Items.PageDataInput;
		Items.PagesBackButton.CurrentPage  = Items.PageBackButtonEmpty;
		
	EndIf;
EndProcedure

&AtServer
Procedure ExitWithoutCheckingServer()
	
	PackingListsServer.RecursivelyBypassSubordinateStrings(Object.Goods, PackingListParent,,, "Delete");
	FoundRows = Object.Goods.FindRows(New Structure("PackingList", PackingListParent));
	FoundRows[0].CheckState = CheckStatuses.NotVerified;
	WhenMovingToAnotherLevelServer(FoundRows[0].PackingListParent);
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
EndProcedure

&AtClient
Procedure FillInByWarehouseDocument(Command)
	If Object.Goods.Count() > 0 Then
		CallbackDescription = New CallbackDescription("FillInOrderOnServer", ThisForm);
		QueryText = NStr("vi = 'Sẽ điền lại danh sách hàng hóa đã nhận theo chứng từ.
			|Sẽ xóa dữ liệu đã điền. Tiếp tục?';
			|ru = 'Список принятых товаров будет перезаполнен по документу.
			|Заполненные данные будут очищены. Продолжить?';
			|en = 'The list of received goods will be refilled in the document.
			|Populated data will be cleared. Continue?'; fa = 'The list of received goods will be refilled in the document.
			|Populated data will be cleared. Continue?';
			|it = 'The list of received goods will be refilled in the document.
			|Populated data will be cleared. Continue?';
			|pl = 'The list of received goods will be refilled in the document.
			|Populated data will be cleared. Continue?';
			|tr = 'Kabul edilen ürünlerin listesi belge üzerinde yeniden doldurulacaktır.
			|Doldurulan veriler temizlenecektir. Devam edilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add(True, NStr("vi = 'Tiếp tục';
								|ru = 'Продолжить';
								|en = 'Continue'; fa = 'ادامه';
								|it = 'Continuare';
								|pl = 'Kontynuuj';
								|tr = 'Devam et'"));
		Buttons.Add(False, NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Anuluj';
								|tr = 'İptal'"));
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	Else
		FillInOrderOnServer(True, Undefined);
	EndIf;
EndProcedure

&AtServer
Procedure FillInOrderOnServer(Result, Var_Parameters) Export
	
	If Result = True Then
		PackingListsServer.RecursivelyBypassSubordinateStrings(Object.Goods, PackingListParent,,,"Delete");
		
		If ValueIsFilled(PackingListParent)
			And RawGoods.FindRows(
				New Structure("PackingList", PackingListParent)).Count() = 0 Then
				StringsCombined = Object.Goods.FindRows(New Structure("PackingList", PackingListParent));
				PackingListsServer.AddLinesOnPackingLists(ThisForm, Object.Goods, StringsCombined);
				For Each Page1 In StringsCombined Do
					// All subordinate packing lists are also accepted without verification
					If Page1.PackingList <> PackingListParent Then
						Page1.CheckState = CheckStatuses.AcceptedWithoutVerification;
					EndIf;
				EndDo;
		Else
			LinesToFillIn = New Array;
			PackingListsServer.RecursivelyBypassSubordinateStrings(RawGoods, PackingListParent,, LinesToFillIn);
			
			TableAddition = RawGoods.Unload(LinesToFillIn);
			FoundRows = TableAddition.FindRows(New Structure("ThisIsAPackingList", True));
			For Each Page1 In FoundRows Do
				// All subordinate packing lists are also accepted without verification
				Page1.CheckState = CheckStatuses.AcceptedWithoutVerification;
			EndDo;
			CommonClientServer.SupplementTable(TableAddition, Object.Goods);
		EndIf;
		FillInServiceDetailsOfTSGoods();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Function FinishCheckServer()
	
	Result = "";
	
	If Items.PagesCheckSteps.CurrentPage = Items.PageDataInput Then
		
		If Not CheckFilling() Then
			Return "HasFillingErrors";
		EndIf;
		
		Result = CheckFillDiscrepancies();
		
		If Result = "ThereAreDiscrepancies" Then
		
			Return "ThereAreDiscrepancies";
			
		EndIf;
		
	Else
		
		WorkOutActionsOnDiscrepancies();
		
	EndIf;
	
	If ValueIsFilled(PackingListParent)
		And PackingListParent <> Object.Ref Then
		
		FoundRows = Object.Goods.FindRows(New Structure("PackingList", PackingListParent));
		FoundRows[0].CheckState = CheckStatuses.Verified;
		WhenMovingToAnotherLevelServer(FoundRows[0].PackingListParent);
		
		Return "NoDiscrepanciesOrWorkedOut";
		
	ElsIf Not ThereAreDiscrepancies Then
		
		Return "CheckIsOverThereAreNoDiscrepancies"
		
	Else
		// Completion of verification at the top level (there are discrepancies)
		
		DetailsOfGoods = "Products, Characteristic, Purpose, Package, Series, DocumentShipments, ThisIsAPackingList, PackingList, PackingListParent";
		Goods = Object.Goods.Unload();
		
		Goods.GroupBy(DetailsOfGoods, "Count, NumberOfPackages");
		
		VerifiedSourceStrings = New Map;
		
		FilterParameters = New Structure(DetailsOfGoods);
		For Each VerifiedString In Goods Do
			FillPropertyValues(FilterParameters, VerifiedString);
			SourceLines = RawGoods.FindRows(FilterParameters);
			Balance = VerifiedString.Count;
			RemainingPackages = VerifiedString.NumberOfPackages;
			For Each SourceString In SourceLines Do
				VerifiedSourceStrings.Insert(SourceString, True);
				If Balance > SourceString.Count Then
					Balance = Balance - SourceString.Count;
					RemainingPackages = RemainingPackages - SourceString.NumberOfPackages;
				ElsIf Balance > 0 Then
					SourceString.Count = Balance;
					SourceString.NumberOfPackages = RemainingPackages;
					Balance = 0;
				Else
					RawGoods.Delete(SourceString);
				EndIf;
			EndDo;
			If Balance > 0 Then
				NewRow = RawGoods.Add();
				FillPropertyValues(NewRow, VerifiedString);
				NewRow.Count = Balance;
				NewRow.NumberOfPackages = RemainingPackages;
				NewRow.Comment = NStr("vi = 'Đã thêm dòng theo kết quả kiểm tra';
										|ru = 'Строка добавлена по результатам проверки';
										|en = 'The line is added based on the check results'; fa = 'The line is added based on the check results';
										|it = 'Stringa aggiunta secondo i risultati della verifica';
										|pl = 'Wiersz dodany na podstawie wyników weryfikacji';
										|tr = 'Satır, kontrol sonuçlarına göre eklendi'");
				VerifiedSourceStrings.Insert(NewRow, True);
			EndIf;
		EndDo;
		
		// Unchecked rows of the source table need to be deleted
		If TypeOf(Object.Ref) = Type("DocumentRef.PackingList") Then
			SourceLinesForVerification = New Array;
			PackingListsServer.RecursivelyBypassSubordinateStrings(RawGoods, Object.Ref,, SourceLinesForVerification);
			For Each Page1 In SourceLinesForVerification Do
				If VerifiedSourceStrings.Get(Page1) = Undefined Then
					RawGoods.Delete(Page1);
				EndIf;
			EndDo;
		Else
			UBound = RawGoods.Count() - 1;
			For Account = 0 To UBound Do
				Page1 = RawGoods[UBound - Account];
				If VerifiedSourceStrings.Get(Page1) = Undefined Then
					RawGoods.Delete(Page1);
				EndIf;
			EndDo;
		EndIf;
		
		AddressInTempStorage = PutToTempStorage(RawGoods.Unload());
		Return "CheckIsOverThereAreDiscrepancies";
		
	EndIf;
	
EndFunction

&AtServer
Function CheckFillDiscrepancies()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	RawGoods.Products,
	|	RawGoods.Characteristic,
	|	RawGoods.Purpose AS Purpose,
	|	RawGoods.Series,
	|	CASE
	|		WHEN &UseBinLocationWarehousing
	|			THEN RawGoods.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	RawGoods.PackingList,
	|	RawGoods.ThisIsAPackingList,
	|	&PackingListParent,
	|	RawGoods.DocumentShipments AS DocumentShipments,
	|	RawGoods.Count,
	|	RawGoods.NumberOfPackages
	|INTO RawGoods
	|FROM
	|	&RawGoods AS RawGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CASE
	|		WHEN &UseBinLocationWarehousing
	|			THEN Goods.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	Goods.PackingList,
	|	Goods.ThisIsAPackingList,
	|	Goods.PackingListParent,
	|	Goods.DocumentShipments,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	Goods.CheckState
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Package,
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.Action,
	|	Goods.DocumentShipments,
	|	Goods.Count,
	|	Goods.NumberOfPackages
	|INTO Surpluses
	|FROM
	|	&Surpluses AS Goods
	|WHERE
	|	Goods.Action <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Package,
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.Action,
	|	Goods.DocumentShipments,
	|	Goods.Count,
	|	Goods.NumberOfPackages
	|INTO Shortages
	|FROM
	|	&Shortages AS Goods
	|WHERE
	|	Goods.Action <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.Action,
	|	Goods.Count,
	|	Goods.NumberOfPackages
	|INTO UncheckedPackingLists
	|FROM
	|	&UncheckedPackingLists AS Goods
	|WHERE
	|	Goods.Action <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Discrepancies.Products,
	|	Discrepancies.Characteristic,
	|	Discrepancies.Purpose,
	|	Discrepancies.Series,
	|	Discrepancies.Package,
	|	Discrepancies.ThisIsAPackingList,
	|	Discrepancies.PackingList,
	|	Discrepancies.PackingListParent,
	|	Discrepancies.DocumentShipments,
	|	SUM(Discrepancies.Count) AS Count,
	|	CASE
	|		WHEN NOT &UseBinLocationWarehousing
	|			THEN SUM(Discrepancies.Count)
	|		ELSE SUM(Discrepancies.NumberOfPackages)
	|	END AS NumberOfPackages
	|INTO Discrepancies
	|FROM
	|	(SELECT
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.Purpose AS Purpose,
	|		Goods.Series AS Series,
	|		Goods.Package AS Package,
	|		Goods.ThisIsAPackingList AS ThisIsAPackingList,
	|		Goods.PackingList AS PackingList,
	|		Goods.PackingListParent AS PackingListParent,
	|		Goods.DocumentShipments AS DocumentShipments,
	|		Goods.Count AS Count,
	|		Goods.NumberOfPackages AS NumberOfPackages
	|	FROM
	|		Goods AS Goods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RawGoods.Products,
	|		RawGoods.Characteristic,
	|		RawGoods.Purpose,
	|		RawGoods.Series,
	|		RawGoods.Package,
	|		RawGoods.ThisIsAPackingList,
	|		RawGoods.PackingList,
	|		RawGoods.PackingListParent,
	|		RawGoods.DocumentShipments,
	|		-RawGoods.Count,
	|		-RawGoods.NumberOfPackages
	|	FROM
	|		RawGoods AS RawGoods) AS Discrepancies
	|
	|GROUP BY
	|	Discrepancies.Products,
	|	Discrepancies.Characteristic,
	|	Discrepancies.Purpose,
	|	Discrepancies.Series,
	|	Discrepancies.Package,
	|	Discrepancies.ThisIsAPackingList,
	|	Discrepancies.PackingList,
	|	Discrepancies.PackingListParent,
	|	Discrepancies.DocumentShipments
	|;
	|
	|//[6]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Surpluses.Products,
	|	Surpluses.Characteristic,
	|	Surpluses.Purpose,
	|	Surpluses.Series,
	|	Surpluses.Package,
	|	Surpluses.ThisIsAPackingList,
	|	Surpluses.PackingList,
	|	Surpluses.PackingListParent,
	|	ISNULL(Goods.CheckState, """") AS CheckState,
	|	Surpluses.DocumentShipments,
	|	Surpluses.Count,
	|	Surpluses.NumberOfPackages,
	|	ISNULL(SurplusTo.Action, """") AS Action
	|FROM
	|	Discrepancies AS Surpluses
	|		LEFT JOIN Goods AS Goods
	|		ON (Goods.PackingList = Surpluses.PackingList
	|			AND Goods.ThisIsAPackingList)
	|		LEFT JOIN Surpluses AS SurplusTo
	|		ON (SurplusTo.Products = Surpluses.Products)
	|			AND (SurplusTo.Characteristic = Surpluses.Characteristic)
	|			AND (SurplusTo.Purpose = Surpluses.Purpose)
	|			AND (SurplusTo.Series = Surpluses.Series)
	|			AND (SurplusTo.Package = Surpluses.Package)
	|			AND (SurplusTo.Count = Surpluses.Count)
	|			AND (SurplusTo.DocumentShipments = Surpluses.DocumentShipments)
	|WHERE
	|	Surpluses.Count > 0
	|;
	|
	|//[7]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Shortages.Products,
	|	Shortages.Characteristic,
	|	Shortages.Purpose,
	|	Shortages.Series,
	|	Shortages.Package,
	|	Shortages.ThisIsAPackingList,
	|	Shortages.PackingList,
	|	Shortages.PackingListParent,
	|	ISNULL(Goods.CheckState, """") AS CheckState,
	|	Shortages.DocumentShipments,
	|	-Shortages.Count AS Count,
	|	-Shortages.NumberOfPackages AS NumberOfPackages,
	|	ISNULL(ShortfallsTo.Action, """") AS Action
	|FROM
	|	Discrepancies AS Shortages
	|		LEFT JOIN Goods AS Goods
	|		ON (Goods.PackingList = Shortages.PackingList
	|			AND Goods.ThisIsAPackingList)
	|		LEFT JOIN Shortages AS ShortfallsTo
	|		ON (ShortfallsTo.Products = Shortages.Products)
	|			AND (ShortfallsTo.Characteristic = Shortages.Characteristic)
	|			AND (ShortfallsTo.Purpose = Shortages.Purpose)
	|			AND (ShortfallsTo.Series = Shortages.Series)
	|			AND (ShortfallsTo.Package = Shortages.Package)
	|			AND (ShortfallsTo.DocumentShipments = Shortages.DocumentShipments)
	|			AND (ShortfallsTo.Count = -Shortages.Count)
	|WHERE
	|	Shortages.Count < 0
	|;
	|
	|//[8]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UncheckedPackingLists.PackingList,
	|	UncheckedPackingLists.PackingListParent,
	|	CASE
	|		WHEN ISNULL(UnverifiedPackingListsBefore.Count, 0) > 0
	|			THEN UnverifiedPackingListsBefore.Action
	|		ELSE """"
	|	END AS Action
	|FROM
	|	Goods AS UncheckedPackingLists
	|		LEFT JOIN UncheckedPackingLists AS UnverifiedPackingListsBefore
	|		ON (UnverifiedPackingListsBefore.PackingList = UncheckedPackingLists.PackingList)
	|WHERE
	|	UncheckedPackingLists.ThisIsAPackingList
	|	AND UncheckedPackingLists.CheckState = &StateNotChecked
	|	AND NOT UncheckedPackingLists.PackingList IN
	|				(SELECT
	|					Discrepancies.PackingList
	|				FROM
	|					Discrepancies
	|				WHERE
	|					Discrepancies.Count > 0)";
	
	Query.SetParameter("Goods",
		Object.Goods.Unload(New Structure("PackingListParent", PackingListParent)));
		
	WeAreInsideUpSheetNotFromOrder = ValueIsFilled(PackingListParent)
		And (RawGoods.FindRows(New Structure("PackingList", PackingListParent)).Count() = 0);
	Query.SetParameter("PackingListParent", PackingListParent);
	
	If WeAreInsideUpSheetNotFromOrder Then
		Query.Text = StrReplace(Query.Text,
			"&RawGoods AS RawGoods",
			"Document.PackingList.Goods AS RawGoods
			|WHERE Ref = &PackingListParent
			|	AND PackingListParent = VALUE(Document.PackingList.EmptyRef)");
			Query.Text = StrReplace(Query.Text, 
				"RawGoods.Purpose", "VALUE(Catalog.Assignments.EmptyRef)");
			Query.Text = StrReplace(Query.Text, 
				"RawGoods.DocumentShipments", "UNDEFINED");
	Else
		Query.SetParameter("RawGoods",
			RawGoods.Unload(New Structure("PackingListParent", PackingListParent)));
	EndIf;
	
	Query.SetParameter("Surpluses",Surpluses.Unload());
	Query.SetParameter("Shortages",Shortages.Unload());
	Query.SetParameter("UncheckedPackingLists",UncheckedPackingLists.Unload());
	Query.SetParameter("StateNotChecked", CheckStatuses.NotVerified);
	Query.SetParameter("UseBinLocationWarehousing", UseBinLocationWarehousing);
	Result = Query.ExecuteBatch();
	
	ThereAreSurpluses                       = Not Result[6].IsEmpty();
	ThereIsShortages                     = Not Result[7].IsEmpty();
	ThereAreUntestedPackingLists = Not Result[8].IsEmpty();
	
	If Not ThereAreSurpluses
		And Not ThereIsShortages
		And Not ThereAreUntestedPackingLists Then
		
		Return "ThereAreNoDiscrepancies";
		
	EndIf;
	
	Items.GroupSurplus.Visible                       = ThereAreSurpluses;
	Items.GroupShortage.Visible                     = ThereIsShortages;
	Items.GroupUnverifiedPackingLists.Visible = ThereAreUntestedPackingLists;
	
	Surpluses.Load(Result[6].Unload());
	Shortages.Load(Result[7].Unload());
	UncheckedPackingLists.Load(Result[8].Unload());
	
	Return "ThereAreDiscrepancies";
	
EndFunction

&AtServer
Procedure WorkOutActionsOnDiscrepancies()
	
	QueryText =
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	Goods.Series,
	|	Goods.DocumentShipments,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.ThisIsAPackingList,
	|	Goods.CheckState
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	(NOT Goods.ThisIsAPackingList
	|			OR NOT Goods.PackingList IN (&DoNotAcceptUnverifiedUpSheets))
	|	AND Goods.PackingListParent = &PackingListParent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	Goods.Series,
	|	Goods.DocumentShipments,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.ThisIsAPackingList,
	|	Goods.CheckState,
	|	Goods.Action
	|INTO Surpluses
	|FROM
	|	&Surpluses AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	Goods.Series,
	|	Goods.DocumentShipments,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.PackingList,
	|	Goods.PackingListParent,
	|	Goods.ThisIsAPackingList,
	|	Goods.CheckState,
	|	Goods.Action
	|INTO Shortages
	|FROM
	|	&Shortages AS Goods
	|;";
	
	If UseBinLocationWarehousing Then
		QueryText = QueryText +
		"SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Package,
		|	Goods.Series,
		|	Goods.DocumentShipments,
		|	Goods.NumberOfPackages,
		|	Goods.Count,
		|	Goods.PackingList,
		|	Goods.PackingListParent,
		|	Goods.ThisIsAPackingList,
		|	Goods.CheckState
		|INTO ProductsToRequest
		|FROM
		|	Goods AS Goods
		|
		|UNION ALL
		|
		|SELECT
		|	DoNotTakeExcess.Products,
		|	DoNotTakeExcess.Characteristic,
		|	DoNotTakeExcess.Purpose,
		|	DoNotTakeExcess.Package,
		|	DoNotTakeExcess.Series,
		|	DoNotTakeExcess.DocumentShipments,
		|	-DoNotTakeExcess.NumberOfPackages,
		|	-DoNotTakeExcess.Count,
		|	DoNotTakeExcess.PackingList,
		|	DoNotTakeExcess.PackingListParent,
		|	DoNotTakeExcess.ThisIsAPackingList,
		|	DoNotTakeExcess.CheckState
		|FROM
		|	Surpluses AS DoNotTakeExcess
		|WHERE DoNotTakeExcess.Action = """" // Do not take
		|
		|UNION ALL
		|
		|SELECT
		|	AcceptShortagesWithoutChecking.Products,
		|	AcceptShortagesWithoutChecking.Characteristic,
		|	AcceptShortagesWithoutChecking.Purpose,
		|	AcceptShortagesWithoutChecking.Package,
		|	AcceptShortagesWithoutChecking.Series,
		|	AcceptShortagesWithoutChecking.DocumentShipments,
		|	AcceptShortagesWithoutChecking.NumberOfPackages,
		|	AcceptShortagesWithoutChecking.Count,
		|	AcceptShortagesWithoutChecking.PackingList,
		|	AcceptShortagesWithoutChecking.PackingListParent,
		|	AcceptShortagesWithoutChecking.ThisIsAPackingList,
		|	AcceptShortagesWithoutChecking.CheckState
		|FROM
		|	Shortages AS AcceptShortagesWithoutChecking
		|WHERE
		|	AcceptShortagesWithoutChecking.Action <> """" // Receive without checking
		|;";
	Else
		// In the case of inadequate storage, the surpluses are considered without packages
		//	and the order packages may differ from the checked packages,
		//	therefore, goods for which unacceptable surpluses (without packages)
		//	have been identified will have to be converted to basic units of measurement in order to reduce the checked goods.
		QueryText = QueryText +
		"SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Package,
		|	Goods.Series,
		|	Goods.DocumentShipments,
		|	Goods.NumberOfPackages,
		|	Goods.Count,
		|	Goods.PackingList,
		|	Goods.PackingListParent,
		|	Goods.ThisIsAPackingList,
		|	Goods.CheckState
		|INTO ProductsToRequest
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT (Goods.Products, Goods.Characteristic, Goods.Purpose, Goods.Series, Goods.DocumentShipments) IN
		|				(SELECT
		|					DoNotTakeExcess.Products,
		|					DoNotTakeExcess.Characteristic,
		|					DoNotTakeExcess.Purpose,
		|					DoNotTakeExcess.Series,
		|					DoNotTakeExcess.DocumentShipments
		|				FROM
		|					Surpluses AS DoNotTakeExcess
		|				WHERE DoNotTakeExcess.Action = """")
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
		|	Goods.Series,
		|	Goods.DocumentShipments,
		|	Goods.Count,
		|	Goods.Count,
		|	Goods.PackingList,
		|	Goods.PackingListParent,
		|	Goods.ThisIsAPackingList,
		|	Goods.CheckState
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT Goods.ThisIsAPackingList
		|	AND (Goods.Products, Goods.Characteristic, Goods.Series, Goods.DocumentShipments) IN
		|			(SELECT
		|				DoNotTakeExcess.Products,
		|				DoNotTakeExcess.Characteristic,
		|				DoNotTakeExcess.Series,
		|				DoNotTakeExcess.DocumentShipments
		|			FROM
		|				Surpluses AS DoNotTakeExcess
		|			WHERE DoNotTakeExcess.Action = """")
		|
		|UNION ALL
		|
		|SELECT
		|	DoNotTakeExcess.Products,
		|	DoNotTakeExcess.Characteristic,
		|	DoNotTakeExcess.Purpose,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
		|	DoNotTakeExcess.Series,
		|	DoNotTakeExcess.DocumentShipments,
		|	-DoNotTakeExcess.Count,
		|	-DoNotTakeExcess.Count,
		|	DoNotTakeExcess.PackingList,
		|	DoNotTakeExcess.PackingListParent,
		|	DoNotTakeExcess.ThisIsAPackingList,
		|	DoNotTakeExcess.CheckState
		|FROM
		|	Surpluses AS DoNotTakeExcess
		|WHERE DoNotTakeExcess.Action = """" // Do not take
		|
		|UNION ALL
		|
		|SELECT
		|	AcceptShortagesWithoutChecking.Products,
		|	AcceptShortagesWithoutChecking.Characteristic,
		|	AcceptShortagesWithoutChecking.Purpose,
		|	AcceptShortagesWithoutChecking.Package,
		|	AcceptShortagesWithoutChecking.Series,
		|	AcceptShortagesWithoutChecking.DocumentShipments,
		|	AcceptShortagesWithoutChecking.NumberOfPackages,
		|	AcceptShortagesWithoutChecking.Count,
		|	AcceptShortagesWithoutChecking.PackingList,
		|	AcceptShortagesWithoutChecking.PackingListParent,
		|	AcceptShortagesWithoutChecking.ThisIsAPackingList,
		|	AcceptShortagesWithoutChecking.CheckState
		|FROM
		|	Shortages AS AcceptShortagesWithoutChecking
		|WHERE
		|	AcceptShortagesWithoutChecking.Action <> """" // Receive without checking
		|;";
	EndIf;
	
	QueryText = QueryText +
	"//[4]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Package AS Package,
	|	Goods.Series,
	|	SUM(Goods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(Goods.Count) AS Count,
	|	Goods.PackingList AS PackingList,
	|	Goods.PackingListParent AS PackingListParent,
	|	Goods.ThisIsAPackingList AS ThisIsAPackingList,
	|	Goods.DocumentShipments,
	|	MAX(CASE
	|			WHEN Goods.ThisIsAPackingList
	|				THEN CASE
	|						WHEN Goods.PackingList IN (&UncheckedUpSheetsAcceptWithoutVerification)
	|								OR Goods.PackingList IN (&AddExcessUpSheetsToOrder)
	|									AND Goods.CheckState <> &StateChecked
	|								OR Goods.PackingList IN (&DeficienciesCanBeAcceptedWithoutVerification)
	|							THEN &StateAcceptedWithoutVerification
	|						ELSE &StateChecked
	|					END
	|			ELSE """"
	|		END) AS CheckState
	|FROM
	|	ProductsToRequest AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	Goods.Series,
	|	Goods.PackingList,
	|	Goods.ThisIsAPackingList,
	|	Goods.PackingListParent,
	|	Goods.DocumentShipments
	|;
	|
	|//[5]//////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1
	|FROM
	|	Surpluses AS AddExcess
	|WHERE
	|	AddExcess.Action <> """"
	|
	|UNION ALL
	|
	|SELECT
	|	1
	|FROM
	|	Shortages AS DeleteGaps
	|WHERE
	|	DeleteGaps.Action = """"";
	
	DoNotAcceptUnverifiedUpSheets =
		UncheckedPackingLists.Unload(
			New Structure("Action", Actions.DoNotTake),           "PackingList")
		.UnloadColumn("PackingList");
	UncheckedUpSheetsAcceptWithoutVerification =
		UncheckedPackingLists.Unload(
			New Structure("Action", ""),                             "PackingList")
		.UnloadColumn("PackingList");
	ExcessUseShouldNotBeTaken =
		Surpluses.Unload(
			New Structure("ThisIsAPackingList, Action", True, ""), "PackingList")
		.UnloadColumn("PackingList");
	AddExcessUpSheetsToOrder =
		Surpluses.Unload(
			New Structure("ThisIsAPackingList, Action", True, Actions.AddToDocument), "PackingList")
		.UnloadColumn("PackingList");
	
	AddExcessUpSheetsToOrderUnchecked =
		Surpluses.Unload(
			New Structure("ThisIsAPackingList, Action, CheckState",
				True, Actions.AddToDocument, CheckStatuses.NotVerified), "PackingList")
		.UnloadColumn("PackingList");
	
	DeficienciesCanBeAcceptedWithoutVerification =
		Shortages.Unload(
			New Structure("ThisIsAPackingList, Action",
				True, Actions.ReceiveWithoutChecking, CheckStatuses.NotVerified), "PackingList")
		.UnloadColumn("PackingList");
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Goods",                                 Object.Goods.Unload());
	Query.SetParameter("Surpluses",                                Surpluses.Unload());
	Query.SetParameter("Shortages",                              Shortages.Unload());
	Query.SetParameter("StateChecked",                      CheckStatuses.Verified);
	Query.SetParameter("StateAcceptedWithoutVerification",             CheckStatuses.AcceptedWithoutVerification);
	Query.SetParameter("DoNotAcceptUnverifiedUpSheets",        DoNotAcceptUnverifiedUpSheets);
	Query.SetParameter("UncheckedUpSheetsAcceptWithoutVerification", UncheckedUpSheetsAcceptWithoutVerification);
	Query.SetParameter("AddExcessUpSheetsToOrder",           AddExcessUpSheetsToOrder);
	Query.SetParameter("PackingListParent",                PackingListParent);
	Query.SetParameter("DeficienciesCanBeAcceptedWithoutVerification",     DeficienciesCanBeAcceptedWithoutVerification);
	
	// Let's re-fill the Products table based on the results of the decisions
	//	made to do this, first delete the rows of the current nesting level.
	FoundRows = Object.Goods.FindRows(New Structure("PackingListParent",PackingListParent));
	For Each Page1 In FoundRows Do
		// It is necessary to remove the subordinate lines of the up. sheets from the surpluses that were previously added and that they decided not to accept.
		If ValueIsFilled(Page1.PackingList)
			And Page1.CheckState <> CheckStatuses.NotVerified
			And ExcessUseShouldNotBeTaken.Find(Page1.PackingList)  <> Undefined Then
			PackingListsServer.RecursivelyBypassSubordinateStrings(Object.Goods, Page1.PackingList,,, "Delete");
		EndIf;
		Object.Goods.Delete(Page1);
	EndDo;
	
	Result = Query.ExecuteBatch();
	CommonClientServer.SupplementTable(Result[4].Unload(), Object.Goods);
	
	// We will add lines of packing lists not from the order
	For Each UpSheetLink In AddExcessUpSheetsToOrderUnchecked Do
		StringsCombined = Object.Goods.FindRows(New Structure("PackingList",UpSheetLink));
		PackingListsServer.AddLinesOnPackingLists(ThisForm, Object.Goods, StringsCombined);
	EndDo;
	
	// Let's add lines of accepted packing lists without checking, taking into account nesting
	StringsCombined = New Array;
	For Each UpSheetLink In UncheckedUpSheetsAcceptWithoutVerification Do
		PackingListsServer.RecursivelyBypassSubordinateStrings(RawGoods, UpSheetLink,, StringsCombined);
	EndDo;
	TableAddition = RawGoods.Unload(StringsCombined);
	CommonClientServer.SupplementTable(TableAddition, Object.Goods);
	
	// Let's add lines of un-scanned and accepted packing lists without checking, taking into account nesting.
	StringsCombined = New Array;
	For Each UpSheetLink In DeficienciesCanBeAcceptedWithoutVerification Do
		PackingListsServer.RecursivelyBypassSubordinateStrings(RawGoods, UpSheetLink,, StringsCombined);
	EndDo;
	TableAddition = RawGoods.Unload(StringsCombined);
	CommonClientServer.SupplementTable(TableAddition, Object.Goods);
	
	FillInServiceDetailsOfTSGoods();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ThereAreDiscrepancies = ThereAreDiscrepancies Or Not Result[5].IsEmpty() Or (DoNotAcceptUnverifiedUpSheets.Count() > 0);
	
EndProcedure

&AtClient
Procedure GoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

#EndRegion

#EndRegion
