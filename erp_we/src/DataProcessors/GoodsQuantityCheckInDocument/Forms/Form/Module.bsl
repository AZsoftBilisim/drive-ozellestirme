#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ColorInformation     = StyleColors.NoteText;
	ColorSuccess          = StyleColors.TextColorSuccess;
	ColorWarning = StyleColors.TextColorWarning;
	ColorError         = StyleColors.TextColorIssue;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	Object.WarehouseDocument = Parameters.WarehouseDocument;
	Title 	 = Parameters.Title;
	
	If Not ValueIsFilled(Object.WarehouseDocument) Then
		ExceptionText = NStr("vi = 'Không thể mở biểu mẫu bộ xử lý một cách trực tiếp';
							|ru = 'Не предусмотрено непосредственное открытие формы обработки.';
							|en = 'Direct opening of the data processor form is not available.'; fa = 'Direct opening of the data processor form is not available.';
							|it = 'Non è prevista un''apertura diretta del modulo di elaborazione.';
							|pl = 'Nie przewidziano bezpośrednie otwieranie formularzu przetwarzania.';
							|tr = 'İşleme formunun doğrudan açılması sağlanmamaktadır.'");
		Raise ExceptionText;
	EndIf;

	If Not Parameters.Property("UsePackingLists", UsePackingLists) Then
		UsePackingLists = True;
	EndIf;
	
	Object.CorrectionMode = Parameters.CorrectionMode;
	
	ReadDetailsCheckOrder();
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);
	
	OrderObject_ = Object.WarehouseDocument.GetObject();
	LockDataForEdit(Object.WarehouseDocument,,ThisForm.UUID);
	If Not Object.CorrectionMode Then
		If TransferNoteProcessing Then
			OrderObject_.Status = Enums.TransferNoteStatuses.DuringChecking;
		Else
			OrderObject_.Status = Enums.GoodsIssueNoteStatuses.DuringChecking;
		EndIf;
		OrderObject_.Write();
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Object.Warehouse,Object.Premise));
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.GoodsQuantityCheckInDocument));
	
	FillInTSGoods(Object.CorrectionMode);
	
	If Not TransferNoteProcessing Then
		LoadOrderVerificationSettings();
		ConfigureActionsAfterNoteCheckServer(False);
	EndIf;
	
	Object.ShortageAccountingOption = "Get_";
	If Object.CorrectionMode Then
		Items.FinishCheck.Title = NStr("vi = 'Kết thúc sửa >>';
										|ru = 'Завершить исправление >>';
										|en = 'Finish correction >>'; fa = 'Finish correction >>';
										|it = 'Completare la rettifica >>';
										|pl = 'Zakończyć poprawę>>';
										|tr = 'Düzeltmeyi tamamlar >>'");
		Items.ReturnToCheck.Title = NStr("vi = '<< Quay lại để sửa';
										|ru = '<< Вернуться к исправлению';
										|en = '<< Back to correction'; fa = '<< Back to correction';
										|it = '<< Tornare alla rettifica';
										|pl = '<< Powrót do korekcji';
										|tr = '<< Düzeltmeye geri dön'");
	EndIf;
	
	If UseBinLocationWarehousing Then
		Items.CollectionJob.Visible = False;
	EndIf;
	
	If TransferNoteProcessing Or Not UsePackingLists Then
		Items.CurrentPackingListPresentation.Visible     = False;
		Items.GoodsPackingList.Visible                   = False;
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "GoodsPackingListCode", "Visible", False);
		Items.ProductsChangePackingList.Visible           = False;
		Items.FormButtonGroupCurrentPackingList.Visible = False;
		Items.ConfigureActionsAfterNoteCheck.Visible    = False;
	EndIf;
	
	If UserRightsCached.ThisIsPartner() Then
		Items.ImportGoodsFromPDT.Visible = False;
		Items.GoodsImportDataFromPDT.Visible = False;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	PrintPresentationOfCurPackingList("");
	
	If Object.CorrectionMode
		And ThereArePackingLists Then
		MessageText = NStr("vi = 'Để sửa các dòng như vậy, trước tiên cần giải nén chúng.';
							|ru = 'Для исправления таких строк их нужно сначала разупаковать.';
							|en = 'Unpack such lines to correct them.'; fa = 'Unpack such lines to correct them.';
							|it = 'Per rettificare tali righe, devono prima essere decompresse.';
							|pl = 'Dla poprawy takich wierszy trzeba je najpierw rozpakować.';
							|tr = 'Bu tür satırları düzeltmek için önce paketlerinden çıkarılmaları gerekir.'");
		TitleText = NStr("vi = 'Có những dòng bao gồm trong danh sách đóng gói.';
						|ru = 'Есть строки, включенные в упаковочные листы';
						|en = 'There are lines included in packing lists'; fa = 'There are lines included in packing lists';
						|it = 'Ci sono righe incluse nelle liste di imballaggio';
						|pl = 'Są wiersze, które są dołączone w listy pakowe';
						|tr = 'Ürün listelerine dahil edilen satırlar mevcut'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
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
	
	If EventName = "ChangedOptionForCompletingOrderVerification" Then
		
		OptionOfNoteCheckEnd = Parameter;
		
	ElsIf EventName = "OptionToCompleteOrderVerificationIsSet" Then
		
		Object.TransportationJob		= Parameter.TransportationJob;
		Object.NoteStatus				= ?(Parameter.OptionOfNoteCheckEnd = "SetStatusChecked",
											PredefinedValue("Enum.GoodsIssueNoteStatuses.Verified"),
											PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip"));
		OptionOfNoteCheckEnd = ?(Parameter.DontAskAgain, Parameter.OptionOfNoteCheckEnd,
											"RequestActionSelectionAfterVerification");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		Items.Goods.CurrentData.Purpose = ValueSelected;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not SkipConfirmationBeforeClosing
		And Not CheckIsCompleted Then
		
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			
			Return;
		EndIf;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		
		If Items.FormPages.CurrentPage = Items.PageErrors Then
			QueryText = NStr("vi = 'Phản ánh chênh lệch vào kế toán trước khi đóng bộ xử lý?';
							|ru = 'Отразить расхождения в учете перед закрытием обработки?';
							|en = 'Record discrepancies in accounting before closing the data processor?'; fa = 'Record discrepancies in accounting before closing the data processor?';
							|it = 'Riportare le discrepanze in contabilità prima della chiusura di elaborazione?';
							|pl = 'Odzwierciedlij odchylenie w ewidencji przed zamknięciem przetwarzania?';
							|tr = 'İşlemi kapatmadan önce muhasebedeki tutarsızlıkları yansıtıyor mu?'");
		Else
			QueryText = ?(Object.CorrectionMode, NStr("vi = 'Kết thúc sửa trước khi đóng bộ xử lý?';
														|ru = 'Завершить исправление перед закрытием обработки?';
														|en = 'Finish correction before closing the data processor?'; fa = 'Finish correction before closing the data processor?';
														|it = 'Terminare la rettifica prima della chiusura di elaborazione?';
														|pl = 'Zakończyć poprawę przed zamknięciem obróbki?';
														|tr = 'İşlemi kapatmadan önce düzeltme tamamlansın mı?'"),
				NStr("vi = 'Kết thúc kiểm tra trước khi đóng bộ xử lý?';
					|ru = 'Завершить проверку перед закрытием обработки?';
					|en = 'Finish check before closing the data processor?'; fa = 'Finish check before closing the data processor?';
					|it = 'Terminare il controllo prima della chiusura di elaborazione?';
					|pl = 'Zakończyć weryfikację przed zamknięciem obróbki?';
					|tr = 'İşlemi kapatmadan önce kontrol tamamlansın mı?'"));
		EndIf;
		
		ShowQueryBox(ClosingNotification_, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If Items.FormPages.CurrentPage = Items.PageErrors Then
		
		If QuestionResult = DialogReturnCode.Yes Then
			ReflectDiscrepanciesInAccountingClient();
			SkipConfirmationBeforeClosing = True;
		ElsIf QuestionResult = DialogReturnCode.No Then
			If Not Object.CorrectionMode Then
				RollBackOrderToStatusForVerificationServer();
			EndIf;
			SkipConfirmationBeforeClosing = True;
			Close();
		EndIf;
		
	Else
		
		If QuestionResult = DialogReturnCode.Yes Then
			If FinishCheckClient() Then
				SkipConfirmationBeforeClosing = True;
			EndIf;
		ElsIf QuestionResult = DialogReturnCode.No Then
			If Not Object.CorrectionMode Then
				RollBackOrderToStatusForVerificationServer();
			EndIf;
			SkipConfirmationBeforeClosing = True;
			Close();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit
		And Not TransferNoteProcessing Then
		
		SaveOrderVerificationSettings();
		
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure // Closing Prize()

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurrentPackingListPresentationURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "Change" Then
		EditCurPackingListHandler();
	ElsIf Var_URL = "PrintLabel" Then
		PrintingLabelPackingListHandler();	
	ElsIf Var_URL = "PrintPackingList" Then
		PrintPackingListHandler();	
	Else
		ExceptionText = NStr("vi = 'Không xác định tham chiếu dẫn hướng.';
							|ru = 'Неизвестная навигационная ссылка.';
							|en = 'Unknown URL'; fa = 'Unknown URL';
							|it = 'Indirizzo di navigazione sconosciuto.';
							|pl = 'Nieznany odnośnik nawigacyjny.';
							|tr = 'Bilinmeyen URL.'");
		Raise ExceptionText;
	EndIf;
		
EndProcedure

&AtClient
Procedure IssuePresentationURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "DoNotShip" Then
		DonTShipHandler();
	Else
		ExceptionText = NStr("vi = 'Không xác định tham chiếu dẫn hướng.';
							|ru = 'Неизвестная навигационная ссылка.';
							|en = 'Unknown URL'; fa = 'Unknown URL';
							|it = 'Indirizzo di navigazione sconosciuto.';
							|pl = 'Nieznany odnośnik nawigacyjny.';
							|tr = 'Bilinmeyen URL.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInUnitOfMeasurementAttribute", New Structure("Products", "UnitOfMeasure"));
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");

	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPurposeStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;

	CurrentRow = Items.Goods.CurrentData;
	FormParameters = New Structure;
	FormParameters.Insert("ObjectName", "DataProcessor.GoodsQuantityCheckInDocument");
	FormParameters.Insert("Products", CurrentRow.Products);
	FormParameters.Insert("Characteristic", CurrentRow.Characteristic);
	FormParameters.Insert("Warehouse", Object.Warehouse);

	OpenForm("Catalog.Assignments.Form.ChoiceForm", FormParameters, ThisForm);

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

&AtClient
Procedure GoodsPackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,StructureOfActions,CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,CachedValues,SeriesSpecificationParameters);
	
	NeedToUpdateSeries =  ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters,True);
		
	IDCurrentRow = Items.Goods.CurrentData.GetID();
	//	
	FillInStatusesWhenTSLineIsFinishedEditing(IDCurrentRow, CachedValues, True, NeedToUpdateSeries);
	
	
	If NeedToUpdateSeries Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,CachedValues,SeriesSpecificationParameters);
	EndIf;
		
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If NewRow Then
		CurrentData.PackingList = CurrentPackingList;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,CachedValues,SeriesSpecificationParameters,Copy);

EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IDCurrentRow = CurrentData.GetID();
	
	NeedToUpdateSeries = False;
	
	FillInStatusesWhenTSLineIsFinishedEditing(IDCurrentRow, CachedValues, False, NeedToUpdateSeries);
	If NeedToUpdateSeries Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	EndIf;
	
	ProductsWhenHandlerStringIsActivated();
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	AttachIdleHandler("ProductsWhenHandlerStringIsActivated",0.1,True);
EndProcedure

&AtClient
Procedure GoodsDoNotShipOnChange(Item)
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If CurrentData.DoNotShip = 1 Then
		CurrentData.PackingList = PredefinedValue("Document.PackingList.EmptyRef");
	EndIf;
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishCheck(Command)
	FinishCheckClient();
EndProcedure

&AtClient
Procedure ReturnToCheck(Command)
	Items.FormPages.CurrentPage       = Items.GoodsPage;
	Items.FinishCheck.DefaultButton = True
EndProcedure

&AtClient
Procedure RecordInAccounting(Command)
	ReflectDiscrepanciesInAccountingClient();
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
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInByWarehouseDocument(Command)
	FoundRows	= Object.Goods.FindRows(New Structure("Count", 0));
	If FoundRows.Count() <> Object.Goods.Count() Then
		
		QueryText = NStr("vi = 'Trong phần bảng có các dòng mà đã điền số lượng.
		                    |Khi tự động điền, những dữ liệu này sẽ bị mất. Tiếp tục?';
		                    |ru = 'В табличной части присутствуют строки, в которых заполнено количество.
		                    |При автоматическом заполнении эти данные будут утеряны. Продолжить?';
		                    |en = 'There are rows in the table that contain quantity data.
		                    |This data will be lost during auto population. Continue?'; fa = 'There are rows in the table that contain quantity data.
		                    |This data will be lost during auto population. Continue?';
		                    |it = 'Nella parte tabulare ci sono delle righe nelle quali è compilata la quantità.
		                    |Nel corso della compilazione automatica, questi dati andranno persi. Continuare?';
		                    |pl = 'W tabelarycznej części są wiersze, w których została wypełniona ilość.
		                    |Po automatycznym wypełnieniu te dane zostaną utracone. Kontynuować?';
		                    |tr = 'Tablo bölümünde miktarın doldurulduğu satırlar vardır.
		                    |Otomatik olarak doldurulması durumunda bu bilgiler kaybolacaktır. Devam edilsin mi?'");
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillInByWarehouseDocumentCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
        Return;
		
	EndIf;
	
	FillInOrderFragment();
EndProcedure

&AtClient
Procedure FillInByWarehouseDocumentCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    
    FillInOrderFragment();

EndProcedure

&AtClient
Procedure FillInOrderFragment()
    
    FillInTSGoods(True);

EndProcedure

&AtClient
Procedure ChangeQuality(Command)
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		ClearMessages();
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckPackagingByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInUnitOfMeasurementAttribute", New Structure("Products", "UnitOfMeasure"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");

	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentData.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentData.Package);
	EndIf;
	
	Notification = New CallbackDescription("ChangeQualityCompletion", ThisObject);
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues, Notification);
	
EndProcedure

&AtClient
Procedure ChangeQualityCompletion(Result, AdditionalParameters) Export
	
	ProcessQualityChange();
	ProductsWhenHandlerStringIsActivated();

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		FillInProblemStatuses(Items.Goods.CurrentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CollectionJob(Command)
	
	ClearMessages();
	
	If Object.Shortage.Count() = 0 Then
		MessageText = NStr("vi = 'Không thể in nhiệm vụ chọn. Số lượng hàng hóa trong phiếu tương ứng với số lượng hàng hóa cần xuất gửi';
							|ru = 'Невозможно напечатать задание на добор. Количество товаров в ордере соответствует количеству товаров к отгрузке';
							|en = 'Cannot print a collection job. Number of goods in the note corresponds to the quantity of goods pending shipment'; fa = 'Cannot print a collection job. Number of goods in the note corresponds to the quantity of goods pending shipment';
							|it = 'Impossibile stampare il task per la selezione aggiuntiva. La quantità delle merci nel mandato corrisponde alla quantità delle merci da spedire';
							|pl = 'Nie można wydrukować zadania na dobór. Ilość towarów w zleceniu odpowiada ilości towarów do wysyłki';
							|tr = 'Eklenti yazdırılamıyor. Siparişteki ürün sayısı sevk edilecek ürün sayısına karşılık gelir'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(Object.WarehouseDocument);
	
	PrintParameters = New Structure;	
	PrintParameters.Insert("JobType",		"CollectionJob");
	PrintParameters.Insert("WarehouseDocument",			Object.WarehouseDocument);
	PrintParameters.Insert("TableOfGoods",	Object.Shortage);
	
	PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintJobsForInventoryPickingPlacementAndRecount",
													"GoodsPickingPlacementJob",
													CommandParameter,
													ThisForm,
													PrintParameters);

EndProcedure

&AtClient
Procedure AccountingOptionOnChange(Item)
	
	Items.CollectionJob.Enabled = (Object.ShortageAccountingOption = "Get_");
	
EndProcedure

&AtClient
Procedure PrintPackingList(Command)
	PrintPackingListHandler();
EndProcedure

&AtClient
Procedure PrintPackingListLabel(Command)
	PrintingLabelPackingListHandler();
EndProcedure

&AtClient
Procedure ChangePackingListInSelectedLines(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		
		WarningText = NStr("vi = 'Hãy chọn dòng, mà cần thay đổi trang đóng gói.';
							|ru = 'Выделите строки, в которых нужно изменить упаковочный лист.';
							|en = 'Select lines in which packing lists should be changed.'; fa = 'Select lines in which packing lists should be changed.';
							|it = 'Selezionare le righe nelle quali è richiesta la modifica della lista d''imballaggio.';
							|pl = 'Wybierz wiersze, w których chcesz zmienić arkusze opakowaniowe.';
							|tr = 'Ürün listesinin değiştirilmesi gereken satırlarını seç.'");
		
		ShowMessageBox(,);
		Return;
	EndIf;
	
	InputFormParameters = New Structure;
	InputFormParameters.Insert("Warehouse", Object.Warehouse);
	InputFormParameters.Insert("PackingList", CurrentPackingList);
	
	Notification = New CallbackDescription("ChangePackingListInSelectedLinesCompletion",ThisForm);
	
	OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.SelectPackingList",
		InputFormParameters,
		ThisForm,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangePackingListInSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	If Not TypeOf(Result) = Type("Structure") Then
		Return;
	EndIf;
	
	ChangedIn = 0;
	
	For Each ArrRow In Items.Goods.SelectedRows Do
		
		TableRow = Object.Goods.FindByID(ArrRow);
		
		If TableRow.DoNotShip = 0
			Or Not ValueIsFilled(Result.PackingList) Then
			TableRow.PackingList = Result.PackingList;
			ChangedIn = ChangedIn + 1;
		Else
			MessageText_2 = NStr("vi = 'Đã đánh dấu dòng số %LineNumber% như là chưa giao hàng. Không cần đưa các dòng chưa giao hàng vào phiếu đóng gói.';
								|ru = 'Строка номер %LineNumber% отмечена как неотгружаемая. Неотгружаемые строки не нужно размещать в упаковочные листы.';
								|en = 'Line number %LineNumber% is marked as unshipped. Unshipped links should not be placed in packing lists.'; fa = 'Line number %LineNumber% is marked as unshipped. Unshipped links should not be placed in packing lists.';
								|it = 'La riga numero %LineNumber% è contrassegnata come non soggetta alla spedizione. Le righe non soggette alla spedizione non devono essere posizionate nelle liste di imballaggio.';
								|pl = 'Wiersz numer %LineNumber% jest zaznaczona jak nie wysyłana. Nie wysyłane wiersze nie trzeba umieszczać w listy pakowe.';
								|tr = 'Satır numarası %LineNumber% sevk edilmedi olarak işaretlendi. Sevkiyat dışı satırların ürün listelerine yerleştirilmesi gerekmez.'");
			MessageText_2 = StrReplace(MessageText_2, "%LineNumber%", TableRow.LineNumber);
			
			PathToField = CommonClientServer.PathToTabularSection("Goods", TableRow.LineNumber, "DoNotShip");
			CommonClientServer.MessageToUser(MessageText_2,,PathToField,"Object");
		EndIf;
		
	EndDo;
	
	MessageText = NStr("vi = 'Đã thay đổi phiếu đóng gói trong %ChangedIn% từ %Total%.';
						|ru = 'Упаковочный лист измен в %ChangedIn% из %Total%.';
						|en = 'Packing list is changed in %ChangedIn% from %Total%.'; fa = 'Packing list is changed in %ChangedIn% from %Total%.';
						|it = 'La lista di imballaggio è modificata in %ChangedIn% da %Total%.';
						|pl = 'List pakowy został zmieniony na %ChangedIn% z %Total%.';
						|tr = '%ChangedIn% ürün listesi %Total%değiştirildi.'");
	MessageText = StrReplace(MessageText, "%ChangedIn%", ChangedIn);
	
	Total = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Items.Goods.SelectedRows.Count(), "rows,lines,lines");
	
	MessageText = StrReplace(MessageText, "%Total%", Total);
	
	ShowUserNotification(MessageText);
	
EndProcedure

&AtClient
Procedure ChangeCurrentPackingList(Command)
	
	EditCurPackingListHandler();		
	
EndProcedure

&AtClient
Procedure DoNotShip(Command)
	DonTShipHandler();
EndProcedure

&AtClient
Procedure ConfigureActionsAfterNoteCheck(Command)
	
	FormParameters     = New Structure("OptionOfNoteCheckEnd", OptionOfNoteCheckEnd);
	DescriptionOfTheAlert = New CallbackDescription("ConfigureActionsAfterNoteCheckCompletion", ThisObject);
	
	OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.SettingsFormOfActionAfterGoodsReceiptCheck",
		FormParameters, ThisObject, , , , DescriptionOfTheAlert, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConfigureActionsAfterNoteCheckCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		ConfigureActionsAfterNoteCheckServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsWithNewLinesToStructure(ThisObject, StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.BlockFormData                 = False;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.CurrentPackingList                 = CurrentPackingList;
	
	ThereAreProblems = ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	#If Not WebClient Then
	If ThereAreProblems Then
		Beep();
	EndIf;
	#EndIf
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;

	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	ProductsWhenHandlerStringIsActivated();
	
EndProcedure

&AtServer
Function ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	If TypeOf(StructureOfActionParameters.Barcodes) = Type("Array") Then
		CurrentRow = Undefined;
	Else 
		CurrentRow = StructureOfActionParameters.CurrentRow;
	EndIf;
	
	FillInProblemStatuses(CurrentRow);
	
	CurRowWithSeries = False;
	
	If StructureOfActionParameters.CurrentRow <> Undefined Then
		CurrentRow = Object.Goods.FindByID(StructureOfActionParameters.CurrentRow);
		
		SearchFields = New Structure("Products, Characteristic, Purpose, Series, Package");
		FillPropertyValues(SearchFields, CurrentRow);
		
		If StructureOfActionParameters.ArrayOfRowsWithSeries_.Count() > 0
			And StructureOfActionParameters.ArrayOfRowsWithSeries_[0] = StructureOfActionParameters.CurrentRow Then
			
			CurRowWithSeries = True;
			
		EndIf;
	EndIf;
	
	ThereAreProblems = SplitByNonLoadable(CachedValues);
	
	If ThereAreProblems Then
		FillInProblemStatuses();
	EndIf;
	
	If ThereAreProblems
		And StructureOfActionParameters.CurrentRow <> Undefined Then
		// If there are problems, then unloaded lines have been added, so the current line could "fly off".
		FoundRows = Object.Goods.FindRows(SearchFields);
		If FoundRows.Count() > 0 Then
			StructureOfActionParameters.CurrentRow = FoundRows[0].GetID();
		EndIf;
		
		If CurRowWithSeries Then
			StructureOfActionParameters.ArrayOfRowsWithSeries_[0] = StructureOfActionParameters.CurrentRow;
		EndIf;
	EndIf;
	
	Return ThereAreProblems;
	
EndFunction

#EndRegion

#Region SetOfSeries

&AtServer
Function ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm, CurLineProducts, CachedValues)
	
	StructureOfActions = New Structure;
	AddActionsWithNewLinesToStructure(ThisForm, StructureOfActions);
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions, CachedValues);
	ThereAreProblems = SplitByNonLoadable(CachedValues);
	FillInProblemStatuses();
	
	Return ThereAreProblems;
	
EndFunction

&AtServer
Procedure FillInStatusesWhenTSLineIsFinishedEditing(IDCurrentRow, CachedValues, ThisIsRemoval, UpdateSeries)
	
	If UpdateSeries Then
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters,
				?(ThisIsRemoval, Undefined,IDCurrentRow),
				CachedValues);
	EndIf;
				
	FillInProblemStatuses(IDCurrentRow, ThisIsRemoval);

EndProcedure

&AtServer
Procedure ProcessQualityChange()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	FillInProblemStatuses();
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If CurrentData = Undefined Then
		CurrentData = Items.Goods.CurrentData;
		If CurrentData = Undefined Then
			MessageText = NStr("vi = 'Chọn dòng sản phẩm mà bạn muốn chỉ định loạt.';
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
	ParametersOfSeriesIndicationForm.Insert("Recorder", Object.WarehouseDocument);
	
	ReturnValue_1 = Undefined;

	
	OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ThereAreProblems = ProcessIndicationOfSeriesOnServer(ParametersOfSeriesIndicationForm, CurDataId, CachedValues);
        
        #If Not WebClient Then
            If ThereAreProblems Then
                Beep();
            EndIf;
        #EndIf
    EndIf;

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInTSGoods(FillQuantity)
	
	Query = New Query;
	
	If TypeOf(Object.WarehouseDocument) = Type("DocumentRef.GoodsTransferNote") Then
		QueryText = 
		"SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Package AS Package,
		|	SUM(CASE
		|			WHEN &FillQuantity
		|				THEN GoodsTable.Count
		|			ELSE 0
		|		END) AS Count,
		|	SUM(CASE
		|			WHEN &FillQuantity
		|				THEN GoodsTable.NumberOfPackages
		|			ELSE 0
		|		END) AS NumberOfPackages,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 1
		|		ELSE 0
		|	END AS DoNotShip
		|FROM
		|	Document.GoodsTransferNote.ShippedGoods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND &ConditionForSelectingRows
		|
		|GROUP BY
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Purpose,
		|	GoodsTable.Series,
		|	GoodsTable.Package,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 1
		|		ELSE 0
		|	END";
	Else
		QueryText = 
		"SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.PackingListParent AS PackingList,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Package AS Package,
		|	SUM(CASE
		|			WHEN &FillQuantity
		|				THEN GoodsTable.Count
		|			ELSE 0
		|		END) AS Count,
		|	SUM(CASE
		|			WHEN &FillQuantity
		|				THEN GoodsTable.NumberOfPackages
		|			ELSE 0
		|		END) AS NumberOfPackages,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 1
		|		ELSE 0
		|	END AS DoNotShip
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
		|WHERE
		|	NOT GoodsTable.ThisIsAPackingList
		|	AND GoodsTable.Ref = &Ref
		|	AND &ConditionForSelectingRows
		|
		|GROUP BY
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Purpose,
		|	GoodsTable.PackingListParent,
		|	GoodsTable.Series,
		|	GoodsTable.Package,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 1
		|		ELSE 0
		|	END";
	EndIf;
	     
	QueryText = StrReplace(QueryText, "&ConditionForSelectingRows", DataProcessors.GoodsQuantityCheckInDocument.ConditionForSelectingRows(Object)); 
	
	Query.Text = QueryText;

	Query.SetParameter("Ref",Object.WarehouseDocument);
	Query.SetParameter("FillQuantity",FillQuantity);
	Object.Goods.Load(Query.Execute().Unload());
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfMeasurementAttribute",
											New Structure("Products", "UnitOfMeasure"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	FillInProblemStatuses();
	
EndProcedure

&AtServer
Procedure ReadDetailsCheckOrder()
	
	// Let's check the order
	
	If Object.CorrectionMode Then
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	GoodsTable.Ref
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	GoodsTable.Ref
		|FROM
		|	Document.GoodsTransferNote.ShippedGoods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(MAX(NestedQuery.ThereArePackingLists),FALSE) AS ThereArePackingLists,
		|	ISNULL(MAX(NestedQuery.ThereAreLinesWithoutPackingSheets),TRUE) AS ThereAreLinesWithoutPackingSheets
		|FROM
		|	(SELECT
		|		SpendingOrderForGoodsShippedGoods.ThisIsAPackingList AS ThereArePackingLists,
		|		FALSE AS ThereAreLinesWithoutPackingSheets
		|	FROM
		|		Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
		|	WHERE
		|		SpendingOrderForGoodsShippedGoods.Ref = &Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FALSE,
		|		CASE
		|			WHEN NOT SpendingOrderForGoodsShippedGoods.ThisIsAPackingList
		|					AND SpendingOrderForGoodsShippedGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		|				THEN TRUE
		|			ELSE FALSE
		|		END
		|	FROM
		|		Document.GoodsIssueNote.ShippedGoods AS SpendingOrderForGoodsShippedGoods
		|	WHERE
		|		SpendingOrderForGoodsShippedGoods.Ref = &Ref) AS NestedQuery";		
		Query.SetParameter("Ref", Object.WarehouseDocument);
		
		QueryResult = Query.ExecuteBatch();
		
		If Not QueryResult[0].IsEmpty() Then
			ExceptionText = NStr("vi = 'Có các dòng theo thứ tự với giao dịch ""%Pick%"". điều chỉnh một trật tự như vậy là không thể. Nó cần phải được kiểm tra.';
								|ru = 'В ордере есть строки с действием ""%Pick%"". Исправление такого ордера не возможно. Его нужно проверять.';
								|en = 'Note contains lines with the %Pick% action. Cannot correct such note. It must be checked.'; fa = 'Note contains lines with the %Pick% action. Cannot correct such note. It must be checked.';
								|it = 'Nel mandato sono presenti le righe con l''azione ""%Pick%"". La rettifica di tale mandato non è possibile. Deve essere controllato.';
								|pl = 'W zleceniu są wiersze z działaniem ""%Pick%"". Poprawka takiego zlecenia nie jest możliwe. Trzeba go weryfikować.';
								|tr = 'Sipariş, ""%Pick%"" eylemi içeren satırlar içeriyor. Böyle bir siparişin düzeltilmesi mümkün değildir. Kontrol edilmesi gerekir.'");
			ExceptionText = StrReplace(ExceptionText, "%Pick%", Enums.ActionsWithGoodsIssueNoteRows.Pick);
			Raise ExceptionText;
		EndIf;
		
		Selection = QueryResult[1].Select();
		
		If Selection.Next() Then
			If Not Selection.ThereAreLinesWithoutPackingSheets Then
				ExceptionText = NStr("vi = 'Chỉ các dòng không được bao gồm trong danh sách đóng gói được hỗ trợ. Không có dòng như vậy theo thứ tự này. Để chỉnh sửa, cần loại trừ các dòng khỏi danh sách đóng gói.';
									|ru = 'Поддерживается исправление только строк, которые не включены в упаковочные листы. В этом ордере таких строк нет. Для исправления нужно исключить строки из упаковочных листов.';
									|en = 'Only those lines can be corrected which are not included in the packing lists. There are no such lines in this note. To correct, exclude the lines from the packing lists.'; fa = 'Only those lines can be corrected which are not included in the packing lists. There are no such lines in this note. To correct, exclude the lines from the packing lists.';
									|it = 'Sono supportate solo le righe che non sono incluse nella lista di imballaggio. Non ci sono le righe del genere in questo mandato. Per effettuare la rettifica è necessario escludere le righe dalle liste di imballaggio.';
									|pl = 'Obsługiwana jest poprawka tylko wierszy, które nie są dołączone do list pakowych. W danym zleceniu takich wierszy nie ma. Dla poprawki trzeba wykluczyć wiersze z list pakowych.';
									|tr = 'Yalnızca ürün listelerinde yer almayan satırların düzeltilmesi desteklenir. Bu sıralamada böyle bir satır yok. Düzeltmek için satırların ürün listelerinden çıkarılması gerekir.'");
				ExceptionText = StrReplace(ExceptionText, "%Pick%", Enums.ActionsWithGoodsIssueNoteRows.Pick);
				Raise ExceptionText;
			EndIf;
			
			ThereArePackingLists = Selection.ThereArePackingLists;
		EndIf;
		
	Else
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	GoodsTable.Ref
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	GoodsTable.Ref
		|FROM
		|	Document.GoodsTransferNote.ShippedGoods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)";
		
		Query.SetParameter("Ref", Object.WarehouseDocument);
		
		QueryResult = Query.ExecuteBatch();
		
		If QueryResult[0].IsEmpty() Then
			ExceptionText = NStr("vi = 'Hỗ trợ kiểm tra chỉ các dòng có thao tác ""%Pick%"". Trong lệnh này không có các dòng như vậy.';
								|ru = 'Поддерживается проверка только строк с действием ""%Pick%"". В этом ордере таких строк нет.';
								|en = 'Only lines with action ""%Pick%"" can be checked. There are no such lines in this note.'; fa = 'Only lines with action ""%Pick%"" can be checked. There are no such lines in this note.';
								|it = 'È supportato il controllo di sole righe con l''azione ""%Pick%"". Non ci sono righe del genere in questo mandato.';
								|pl = 'Obsługiwana jest weryfikacja tylko wierszy z działaniem ""%Pick%"". W danym zleceniu takich wierszy nie ma.';
								|tr = 'Doğrulama yalnızca ""%Pick%"" eylemine sahip satırlar için desteklenir. Bu siparişte böyle satırlar mevcut değil.'");
			ExceptionText = StrReplace(ExceptionText, "%Pick%", Enums.ActionsWithGoodsIssueNoteRows.Pick);
			Raise ExceptionText;
		EndIf;
	EndIf;
	
	// Fill in the details
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsIssueNote.Status AS Status,
	|	GoodsIssueNote.Warehouse AS Warehouse,
	|	GoodsIssueNote.Premise AS Premise,
	|	GoodsIssueNote.WarehouseOperation AS WarehouseOperation,
	|	GoodsIssueNote.DateOfShipment AS DateOfShipment,
	|	GoodsIssueNote.TransportationJob AS TransportationJob,
	|	GoodsIssueNote.ShipmentUnderTransportationJob AS ShipmentUnderTransportationJob
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTransferNote.Status,
	|	GoodsTransferNote.Warehouse,
	|	GoodsTransferNote.SenderWareroom,
	|	VALUE(Enum.WarehouseTransactions.TransferBetweenWarerooms),
	|	GoodsTransferNote.DateOfShipment,
	|	VALUE(Document.TransportationJob.EmptyRef),
	|	FALSE
	|FROM
	|	Document.GoodsTransferNote AS GoodsTransferNote
	|WHERE
	|	GoodsTransferNote.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.WarehouseDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	TransferNoteProcessing = (TypeOf(Object.WarehouseDocument) = Type("DocumentRef.GoodsTransferNote"));
	
	Object.Warehouse                        = Selection.Warehouse;
	Object.Premise                    = Selection.Premise;
	Object.DateOfShipment                 = Selection.DateOfShipment;
	Object.WarehouseOperation            = Selection.WarehouseOperation;
	Object.TransportationJob           = Selection.TransportationJob;
	Object.ShipmentUnderTransportationJob = Selection.ShipmentUnderTransportationJob;
	
	NoteStatus        = Selection.Status;
	If Object.CorrectionMode Then
		If TransferNoteProcessing Then
			If NoteStatus <> Enums.TransferNoteStatuses.ToShip Then
				ExceptionText = NStr("vi = 'Có thể sửa số lượng trong lệnh điều chuyển, nếu lệnh này có trạng thái ""Cần giao hàng"".';
									|ru = 'Исправление количества в ордере на перемещение товаров возможно, если он находится в статусе ""К отгрузке"".';
									|en = 'Quantity correction in the internal stock transfer is possible if it is in status ""To ship"".'; fa = 'Quantity correction in the internal stock transfer is possible if it is in status ""To ship"".';
									|it = 'La correzione della quantità nel mandato di trasferimento delle merci è possibile se esso ha lo stato ""Per spedizione"".';
									|pl = 'Poprawka ilości w zleceniu na przemieszczenie towarów jest możliwa jeśli znajduje się ono w statusie ""Do wysyłki"".';
									|tr = 'Dahili stok transferinde belirltili miktar düzeltmesi, ancak ""Sevk edilecek"" durumunda olduğu takdirde mümkündür.'");
				Raise ExceptionText;
			EndIf;
		Else
			If NoteStatus <> Enums.GoodsIssueNoteStatuses.Verified
				And NoteStatus <> Enums.GoodsIssueNoteStatuses.ToShip
				And NoteStatus <> Enums.GoodsIssueNoteStatuses.Shipped_ Then
				ExceptionText = NStr("vi = 'Có thể sửa số lượng trong thứ tự tài khoản nếu nó ở trạng thái ""Đã kiểm tra"", ""Theo lô hàng"" hoặc ""Đã giao hàng"".';
									|ru = 'Исправление количества в расходном ордере возможно, если он находится в статусе ""Проверен"", ""К отгрузке"" или ""Отгружен"".';
									|en = 'You can correct the quantity in the goods issue note if its status is ""Checked"", ""To ship"" or ""Shipped"".'; fa = 'You can correct the quantity in the goods issue note if its status is ""Checked"", ""To ship"" or ""Shipped"".';
									|it = 'La correzione della quantità nel mandato di pagamento è possibile se esso ha lo stato ""Controllato"", ""Da spedire"" oppure ""Spedito"".';
									|pl = 'Poprawka ilości w zleceniu rozchodowym jest możliwa, jeśli znajduje się ono w statusie ""Zweryfikowane"", ""Do wysyłki"" lub ""Wysłane"".';
									|tr = '""Kontrol edildi"", ""Sevk edilecek"" veya ""Sevk edildi"" durumunda olduğu takdirde, çıkış siparişindeki miktarı düzeltmek mümkündür.'");
				Raise ExceptionText;
			EndIf;
		EndIf
	Else
		If ?(TransferNoteProcessing,
			NoteStatus <> Enums.TransferNoteStatuses.ForChecking,
			NoteStatus <> Enums.GoodsIssueNoteStatuses.ForChecking) Then
			ExceptionText = NStr("vi = 'Chỉ có thể kiểm tra số lượng trong phiếu có trạng thái ""Cần kiểm tra"".';
								|ru = 'Проверять количество можно только в ордере, находящемся в статусе ""К проверке"".';
								|en = 'You can check the quantity only in a note with status ""For checking"".'; fa = 'You can check the quantity only in a note with status ""For checking"".';
								|it = 'È possibile verificare la quantità solo nel mandato che ha lo stato ""Da controllare"".';
								|pl = 'Sprawdzać ilość można tylko w zleceniu znajdującym się w statusie ""Do weryfikacji"".';
								|tr = 'Miktar yalnızca ""Kontrol edilecek"" durumuna sahip bir siparişte kontrol edilebilir.'");
			ExceptionText = StrReplace(ExceptionText,"%Status%",NoteStatus);
			Raise ExceptionText;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	UOElement = ConditionalAppearance.Items.Add();

	TMCommonUse.FillInConditionalAppearanceFieldsRecursively(UOElement.Fields, Items.Goods.ChildItems);

	ItemFilter = UOElement.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DoNotShip");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	UOElement.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DoNotShip");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GoodsUnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ConditionalDesignParameters.NameOfUnitField = "UnloadedUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Unshipped.Package";
	ConditionalDesignParameters.PathToFieldIsTypeOfMeasuredValue = "Object.Unshipped.MeasuredValueType";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ConditionalDesignParameters.NameOfUnitField = "TheShortageOfTheUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Shortage.Package";
	ConditionalDesignParameters.PathToFieldIsTypeOfMeasuredValue = "Object.Shortage.MeasuredValueType";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

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

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnshippedPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Unshipped.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShortagePackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Shortage.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

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

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
EndProcedure

&AtServer
Function FinishCheckServer(TransferResultToOrder = True)
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	DataProcessorObject = FormAttributeToValue("Object");
	CheckPassed = DataProcessorObject.FinishCheck(
		WarehousesClientServer.FieldsTakenIntoAccountWhenCheckingSpendingOrder(ThisForm, Undefined), TransferResultToOrder);
	ValueToFormAttribute(DataProcessorObject, "Object");

	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));

	If Object.Unshipped.Count() > 0 Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Unshipped, ParametersForFillingInBankingDetails);
	EndIf;

	If Object.Shortage.Count() > 0 Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Shortage, ParametersForFillingInBankingDetails);
	EndIf;

	Items.UnloadedGroup.Visible = Object.Unshipped.Count() <> 0;
	Items.GroupTheShortfall.Visible = Object.Shortage.Count() <> 0;
	
	Return CheckPassed;
	
EndFunction

&AtClient
Function FinishCheckClient(Close = True)
	
	ClearMessages();
	
	If Not TransferNoteProcessing
		And Not NoteStatusIsSelected Then
		
		If FinishCheckServer(False) Then
			
			FormParameters = New Structure("WarehouseDocument, ShipmentUnderTransportationJob, TransportationJob",
				Object.WarehouseDocument, Object.ShipmentUnderTransportationJob, Object.TransportationJob);
			
			CallbackDescription = New CallbackDescription("SelectingActionAfterCheckingOrderCompletion", ThisObject);
			
			OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.SelectionFormOfActionAfterGoodsReceiptCheck",
				FormParameters, ThisObject, , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			
			Return False;
			
		Else
			
			If Object.Unshipped.Count() > 0
				Or Object.Shortage.Count() > 0 Then
				
				CheckPassed = True;
				
			Else
				CheckPassed = False;
			EndIf;
			
		EndIf;
		
	Else
		
		TransferResultToOrder = TransferNoteProcessing
			Or Object.NoteStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.Verified")
			Or (Object.NoteStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip")
				And Not Object.ShipmentUnderTransportationJob)
			Or (Object.NoteStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip")
				And Object.ShipmentUnderTransportationJob
				And ValueIsFilled(Object.TransportationJob));
		
		If TransferResultToOrder Then
			CheckPassed = FinishCheckServer(True);
		Else
			
			If FinishCheckServer(False) Then
				
				FormParameters = New Structure("WarehouseDocument", Object.WarehouseDocument);
				
				AdditionalParameters = New Structure("Close", Close);
				CallbackDescription      = New CallbackDescription("SelectingTransportTaskToEnd", ThisObject,
					AdditionalParameters);
				
				OpenForm("Document.GoodsIssueNote.Form.TransportationJobChoiceForm", FormParameters,
					ThisObject, , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
				
				Return False;
				
			Else
				
				If Object.Unshipped.Count() > 0
					Or Object.Shortage.Count() > 0 Then
					
					CheckPassed = True;
					
				Else
					CheckPassed = False;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not CheckPassed Then
		Return False;
	EndIf;
	
	If Object.Unshipped.Count() > 0
		Or Object.Shortage.Count() > 0 Then
		
		Items.FormPages.CurrentPage    = Items.PageErrors;
		Items.RecordInAccounting.DefaultButton = True;
		
		Return False;
		
	EndIf;
	
	If TransferNoteProcessing Then
		Notify("Write_GoodsTransferNote",New Structure,Object.WarehouseDocument);
	Else
		Notify("Write_GoodsIssueNote",New Structure,Object.WarehouseDocument);
	EndIf;
	
	CheckIsCompleted = True;
	
	If Close Then
		Close();
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure SelectingTransportTaskToEnd(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		Object.TransportationJob = Result;
		
		If Items.FormPages.CurrentPage = Items.PageErrors Then
			ReflectDiscrepanciesInAccountingClient();
		Else
			FinishCheckClient(AdditionalParameters.Close);
		EndIf;
	Else
		SkipConfirmationBeforeClosing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReflectDiscrepanciesInAccountingClient(Close = True)
	
	ClearMessages();
	
	If Items.GroupTheShortfall.Visible
		And Object.ShortageAccountingOption = "Get_" Then
		
		ReflectionIsCompleted = ReflectDiscrepanciesInAccountingServer();
		
	Else
		
		Filter = New Structure("DoNotShip", 1);
		NotShippedGoods = Object.Goods.FindRows(Filter);
		
		If NotShippedGoods.Count() = Object.Goods.Count() Then
			
			ReflectionIsCompleted = ReflectDiscrepanciesInAccountingServer();
			
		ElsIf Not TransferNoteProcessing
			And Not NoteStatusIsSelected Then
			
			FormParameters = New Structure("WarehouseDocument, ShipmentUnderTransportationJob, TransportationJob",
				Object.WarehouseDocument, Object.ShipmentUnderTransportationJob, Object.TransportationJob);
			
			CallbackDescription = New CallbackDescription("SelectingActionAfterCheckingOrderCompletion", ThisObject);
			
			OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.SelectionFormOfActionAfterGoodsReceiptCheck",
				FormParameters, ThisObject, , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
			
		Else
			
			TransferResultToOrder = TransferNoteProcessing
				Or Object.NoteStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.Verified")
				Or (Object.NoteStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip")
					And Not Object.ShipmentUnderTransportationJob)
				Or (Object.NoteStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip")
					And Object.ShipmentUnderTransportationJob
					And ValueIsFilled(Object.TransportationJob));
			
			If TransferResultToOrder Then
				ReflectionIsCompleted = ReflectDiscrepanciesInAccountingServer();
			Else
				
				FormParameters = New Structure("WarehouseDocument", Object.WarehouseDocument);
				
				AdditionalParameters = New Structure("Close", Close);
				CallbackDescription      = New CallbackDescription("SelectingTransportTaskToEnd", ThisObject,
					AdditionalParameters);
				
				OpenForm("Document.GoodsIssueNote.Form.TransportationJobChoiceForm", FormParameters,
					ThisObject, , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
				
				Return;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ReflectionIsCompleted Then
		
		If TransferNoteProcessing Then
			Notify("Write_GoodsTransferNote",New Structure,Object.WarehouseDocument);
		Else
			Notify("Write_GoodsIssueNote",New Structure,Object.WarehouseDocument);
		EndIf;
		
		CheckIsCompleted = True;
		
		If Close Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ReflectDiscrepanciesInAccountingServer()
	
	DataProcessorObject = FormAttributeToValue("Object");
	ReflectionIsCompleted = DataProcessorObject.ReflectDiscrepanciesInAccounting(WarehousesClientServer.FieldsTakenIntoAccountWhenCheckingSpendingOrder(ThisForm,Undefined));
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	Return ReflectionIsCompleted;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsWithNewLinesToStructure(Form, StructureOfActions)
	
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInUnitOfMeasurementAttribute", New Structure("Products", "UnitOfMeasure"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
																				Form.Object.Warehouse, Form.SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume");
	
EndProcedure

&AtServer
Procedure RollBackOrderToStatusForVerificationServer()
	
	Try
		If Not Object.CorrectionMode Then
			OrderObject_ = Object.WarehouseDocument.GetObject();
			If TransferNoteProcessing Then
				OrderObject_.Status = Enums.TransferNoteStatuses.ForChecking;
			Else
				OrderObject_.Status = Enums.GoodsIssueNoteStatuses.ForChecking;
			EndIf;
			OrderObject_.Write(DocumentWriteMode.Write);
		EndIf;
	Except
		CommonClientServer.MessageToUser(ErrorInfo().Description);
		Return;
	EndTry;
	
EndProcedure

&AtClient
Procedure ProductsWhenHandlerStringIsActivated()
	
	DisplayProductPresentation();
	PrintDescriptionOfProblem();
	
EndProcedure

&AtClient
Procedure DisplayProductPresentation()
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		GoodsPresentation = "";
		Return;
	EndIf;
	
	FieldsToConsider = WarehousesClientServer.FieldsTakenIntoAccountWhenCheckingSpendingOrder(ThisForm, CurrentData);
	
	ItemsDescription = ProductsClientServer.ProductPresentation(CurrentData.Products,
																			CurrentData.Characteristic,
																			,
																			?(FieldsToConsider.ConsiderSeries,CurrentData.Series, ""));
	
	GoodsPresentation = New FormattedString(ItemsDescription,,ColorInformation);
	
EndProcedure

&AtServer
Procedure PrintDescriptionOfProblem(VariableString = Undefined)
	
	If Items.Goods.CurrentRow = Undefined Then
		IssuePresentation = "";
		Return;
	EndIf;
	
	CurrentData = VariableString;
	
	If CurrentData = Undefined Then
		CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	EndIf;
	
	If CurrentData = Undefined Then
		IssuePresentation = "";
		Return;
	EndIf;
	
	UnitString_ = CurrentData.UnitOfMeasure;
	
	If CurrentData.IssueStatus = 0 Then
		
		If CurrentData.NumberOfPackages = 0
			Or CurrentData.ItIsACargoItem
				And CurrentData.QuantityAmount = 0 Then
			
			If CurrentData.ItIsACargoItem
				And CurrentData.Count <> 0 Then
				
				StringText1 = NStr("vi = 'Không đủ số lượng mặt hàng để tập hợp toàn bộ số lượng hàng hóa.
					|Số lượng hàng cần giao ít hơn %NoteQuantity% %UnitOfMeasure% so với số lượng cần thiết theo phiếu.';
					|ru = 'Количества товарных мест недостаточно для сборки целого количества товара.
					|Количество товара к отгрузке меньше на %NoteQuantity% %UnitOfMeasure%, чем нужно по ордеру.';
					|en = 'Quantity of cargo items is insufficient to assemble the full quantity of goods.
					|Quantity of goods to ship is %NoteQuantity% %UnitOfMeasure% less than it is required under the note.'; fa = 'Quantity of cargo items is insufficient to assemble the full quantity of goods.
					|Quantity of goods to ship is %NoteQuantity% %UnitOfMeasure% less than it is required under the note.';
					|it = 'Il numero dei colli non è sufficiente per raccogliere un''intera quantità di merce.
					|La quantità di merce da spedire è inferiore di %NoteQuantity% %UnitOfMeasure% a quella necessaria per il mandato.';
					|pl = 'Ilości miejsc towarowych nie jest wystarczająca dla składania całej ilości towaru.
					|Ilość towaru do wysyłki jest mniejsze o %NoteQuantity% %UnitOfMeasure%, niż trzeba według zlecenia.';
					|tr = 'Sevkiyat yerlerinin sayısı, tüm ürün miktarını bir araya getirmek için yeterli değildir.
					|Sevk edilecek ürün miktarı %NoteQuantity%%UnitOfMeasure% kadar, siparişin gerektirdiğinden daha az.'");
				StringText1 = StrReplace(StringText1, "%NoteQuantity%", CurrentData.QuantityOfGoodsInDocument);
				
			Else
				StringText1 = NStr("vi = 'Mặt hàng này vẫn chưa được quét. Trong phiếu %NoteQuantity% %UnitOfMeasure%.';
									|ru = 'Этот товар еще не сканировали. В ордере %NoteQuantity% %UnitOfMeasure%.';
									|en = 'This goods have not been scanned yet. There is/are %NoteQuantity% %UnitOfMeasure% in note.'; fa = 'This goods have not been scanned yet. There is/are %NoteQuantity% %UnitOfMeasure% in note.';
									|it = 'Questo prodotto non è ancora stato scansionato. Nel mandato %NoteQuantity% %UnitOfMeasure%.';
									|pl = 'Ten towar jeszcze nie został zeskanowany. W zleceniu %NoteQuantity% %UnitOfMeasure%.';
									|tr = 'Bu ürün henüz taranmadı. Siparişte %NoteQuantity% %UnitOfMeasure%.'");
				
				If CurrentData.ItIsACargoItem Then
					StringText1 = StrReplace(StringText1,"%NoteQuantity%", CurrentData.QuantityOfGoodsInDocument);
				Else
					StringText1 = StrReplace(StringText1,"%NoteQuantity%", CurrentData.NumberOfPackagesInDocument);
				EndIf;
			EndIf;
			
			StringText1 = StrReplace(StringText1, "%UnitOfMeasure%", UnitString_);
			StringText2 = "";
			
		Else
			
			StringText1 = NStr("vi = 'Số lượng hàng hóa chờ giao nhỏ hơn %NumberOfParticipants_% %UnitOfMeasure%, cần có theo phiếu.';
								|ru = 'Количество товара к отгрузке меньше на %NumberOfParticipants_% %UnitOfMeasure%, чем нужно по ордеру.';
								|en = 'Quantity of goods to ship is %NumberOfParticipants_% %UnitOfMeasure% less than it is required under the note.'; fa = 'Quantity of goods to ship is %NumberOfParticipants_% %UnitOfMeasure% less than it is required under the note.';
								|it = 'La quantità di merce da spedire è inferiore di %NumberOfParticipants_% %UnitOfMeasure%, a quella necessaria per il mandato.';
								|pl = 'Ilość towaru do wysyłki jest mniejsze o %NumberOfParticipants_% %UnitOfMeasure%, niż trzeba według zlecenia.';
								|tr = 'Sevk edilecek ürün miktarı %NumberOfParticipants_% %UnitOfMeasure% kadar, siparişin gerektirdiğinden daha azdır.'");
			StringText2 = "";
			
			If CurrentData.ItIsACargoItem Then
				StringText1 = StrReplace(StringText1,"%NumberOfParticipants_%", CurrentData.QuantityOfGoodsInDocument - CurrentData.QuantityAmount);
			Else
				StringText1 = StrReplace(StringText1,"%NumberOfParticipants_%", CurrentData.NumberOfPackagesInDocument - CurrentData.NumberOfPackagesAmount);
			EndIf;
			StringText1 = StrReplace(StringText1,"%UnitOfMeasure%", UnitString_);  
			
		EndIf;
		
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(StringText1 + Chars.LF,,ColorInformation));
		RowsArray.Add(New FormattedString(StringText2,,ColorInformation));
		
		IssuePresentation = New FormattedString(RowsArray);
	ElsIf CurrentData.IssueStatus = 1 Then
		StringText1 = NStr("vi = 'Số lượng hàng hóa lấy ra trùng với số lượng trong phiếu.';
							|ru = 'Отобранное количество товаров совпадает с количеством в ордере.';
							|en = 'Picked quantity of goods matches the quantity in the note.'; fa = 'Picked quantity of goods matches the quantity in the note.';
							|it = 'La quantità delle merci selezionata coincide con la quantità nel mandato.';
							|pl = 'Dobrana ilość towarów pokrywa się z ilością w zleceniu.';
							|tr = 'Seçilen ürün miktarı, siparişteki miktarla eşleşir.'");
		StringText2 = "";
		
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(StringText1 + Chars.LF,,ColorSuccess));
		RowsArray.Add(New FormattedString(StringText2,,ColorInformation));
		
		IssuePresentation = New FormattedString(RowsArray);
	ElsIf CurrentData.IssueStatus = 2 Then
		StringText1 = NStr("vi = 'Số lượng lấy ra có thể giao hàng';
							|ru = 'Отобранного количества достаточно для отгрузки.';
							|en = 'Picked quantity is enough for shipment.'; fa = 'Picked quantity is enough for shipment.';
							|it = 'La quantità selezionata è sufficiente per la spedizione.';
							|pl = 'Dobrana ilość jest dostateczna dla wysyłki.';
							|tr = 'Seçilen miktar sevkiyat için yeterlidir.'");
		StringText2 = NStr("vi = '%QuantityNotToShip% %UnitOfMeasure% không thể kết xuất.';
							|ru = '%QuantityNotToShip% %UnitOfMeasure% не нужно отгружать.';
							|en = 'It is not required to ship %QuantityNotToShip% %UnitOfMeasure%.'; fa = 'It is not required to ship %QuantityNotToShip% %UnitOfMeasure%.';
							|it = '%QuantityNotToShip% %UnitOfMeasure% non sono soggetti alla spedizione.';
							|pl = '%QuantityNotToShip% %UnitOfMeasure% nie trzeba wysyłać.';
							|tr = '%QuantityNotToShip%%UnitOfMeasure% sevk edilmeye gerek yoktur.'");
		
		StringText2 = StrReplace(StringText2,"%QuantityNotToShip%", CurrentData.NumberOfPackagesDoNotShip);
		
		If CurrentData.ItIsACargoItem Then
			StringText2 = StrReplace(StringText2,"%UnitOfMeasure%", CurrentData.Package);
		Else
			StringText2 = StrReplace(StringText2,"%UnitOfMeasure%", UnitString_);
		EndIf;  
			
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(StringText1 + Chars.LF,,ColorSuccess));
		RowsArray.Add(New FormattedString(StringText2,,ColorInformation));
		
		IssuePresentation = New FormattedString(RowsArray);
	ElsIf CurrentData.IssueStatus = 3 Then
		StringText1 = NStr("vi = 'Hãy giữ lại hàng hóa vì không cần phải giao.';
							|ru = 'Отложите товар, т.к. его не нужно отгружать.';
							|en = 'Hold the goods over as they should not be shipped.'; fa = 'Hold the goods over as they should not be shipped.';
							|it = 'Accantonare la merce, perché essa non è soggetta alla spedizione.';
							|pl = 'Odłóż towar, ponieważ nie trzeba go wysyłać.';
							|tr = 'Ürünü ertele çünkü sev edilmeyi gerekmiyor.'");
		StringText2 = "";
		
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(StringText1 + Chars.LF,,ColorWarning));
		RowsArray.Add(New FormattedString(StringText2,,ColorInformation));
		
		IssuePresentation = New FormattedString(RowsArray);
	ElsIf CurrentData.IssueStatus = 4 Then
		
		If CurrentData.NumberOfPackagesInDocument > 0
			Or CurrentData.ItIsACargoItem And CurrentData.QuantityOfGoodsInDocument > 0 Then
			StringText1 = NStr("vi = 'Đã lấy ra lớn hơn yêu cầu theo phiếu.';
								|ru = 'Отобрано больше, чем требуется по ордеру.';
								|en = 'Picked more than it is required according to the note.'; fa = 'Picked more than it is required according to the note.';
								|it = 'Selezionato più del richiesto per il mandato.';
								|pl = 'Dobrano więcej, niż trzeba według zlecenia.';
								|tr = 'Emirde gerektirdiğinden daha fazla toplanmış.'");
			StringText2 = NStr("vi = 'Cần thiết đối với %NumberSelectedMore% %UnitOfMeasure%';
								|ru = 'Необходимо для %NumberSelectedMore% %UnitOfMeasure%';
								|en = 'Required for %NumberSelectedMore% %UnitOfMeasure%'; fa = 'Required for %NumberSelectedMore% %UnitOfMeasure%';
								|it = 'Necessario per %NumberSelectedMore% %UnitOfMeasure%';
								|pl = 'Należy dla %NumberSelectedMore% %UnitOfMeasure%';
								|tr = '%NumberSelectedMore% %UnitOfMeasure% için gerekli'") + " ";
			StringText3 = New FormattedString(NStr("vi = 'đánh dấu';
													|ru = 'отметить';
													|en = 'mark'; fa = 'mark';
													|it = 'contrassegnare';
													|pl = 'zaznacz';
													|tr = 'işaretle'"),,,,"DoNotShip");
			StringText4 = NStr("vi = ', không cần giao số lượng này.';
								|ru = ', что это количество не нужно отгружать.';
								|en = ', that this quantity does not need to be shipped.'; fa = ', that this quantity does not need to be shipped.';
								|it = ', che questa quantità non deve essere spedita.';
								|pl = ', że daną ilość nie trzeba wysyłać.';
								|tr = ', bu miktarın sevk edilmesi gerekmiyor.'");
			
			If CurrentData.ItIsACargoItem Then
				StringText2 = StrReplace(StringText2,"%NumberSelectedMore%", CurrentData.QuantityAmount - CurrentData.QuantityOfGoodsInDocument);  
			Else
				StringText2 = StrReplace(StringText2,"%NumberSelectedMore%", CurrentData.NumberOfPackagesAmount - CurrentData.NumberOfPackagesInDocument);  
			EndIf;
			
			StringText2 = StrReplace(StringText2,"%UnitOfMeasure%", UnitString_);  
		Else
			StringText1 = NStr("vi = 'Trong phiếu không có hàng hóa như vậy.';
								|ru = 'В ордере нет такого товара.';
								|en = 'This product is not found in the note.'; fa = 'This product is not found in the note.';
								|it = 'Non esiste un tale articolo nel mandato.';
								|pl = 'W zleceniu nie ma takiego towaru.';
								|tr = 'Siparişte böyle ürün mevcut değildir.'");
			If CurrentData.NumberOfPackagesAmount > 0 
				Or CurrentData.ItIsACargoItem And CurrentData.QuantityAmount > 0 Then
				StringText2 = NStr("vi = 'Cần';
									|ru = 'Необходимо';
									|en = 'Required'; fa = 'موردنیاز';
									|it = 'È necessario';
									|pl = 'Jest konieczne';
									|tr = 'Gerekli'") + " ";
			Else
				StringText2 = NStr("vi = 'Cần điền số lượng và';
									|ru = 'Необходимо заполнить количество и';
									|en = 'Fill in quantity and'; fa = 'Fill in quantity and';
									|it = 'È necessario compilare la quantità e';
									|pl = 'Należy wypełnić ilość i';
									|tr = 'Miktarı doldurulması gerekir ve'") + " ";
			EndIf;
			StringText3 = New FormattedString(NStr("vi = 'đánh dấu';
													|ru = 'отметить';
													|en = 'mark'; fa = 'mark';
													|it = 'contrassegnare';
													|pl = 'zaznacz';
													|tr = 'işaretle'"),,,,"DoNotShip");
			StringText4 = NStr("vi = ', không cần giao dòng này.';
								|ru = ', что эту строку не нужно отгружать.';
								|en = ', that this line does not need to be shipped.'; fa = ', that this line does not need to be shipped.';
								|it = ', che questa riga non deve essere spedita.';
								|pl = ', że dany wiersz nie trzeba wysyłać.';
								|tr = ', bu satırın sevk edilmesi gerekmiyor.'");
		EndIf;
		
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(StringText1 + Chars.LF,,ColorError));
		RowsArray.Add(New FormattedString(StringText2,,ColorInformation));
		RowsArray.Add(StringText3);
		RowsArray.Add(New FormattedString(StringText4,,ColorInformation));
		
		IssuePresentation = New FormattedString(RowsArray);
	Else
		ExceptionText = NStr("vi = 'Không xác định trạng thái vấn đề.';
							|ru = 'Неизвестный статус проблемы.';
							|en = 'Unknown issue status.'; fa = 'Unknown issue status.';
							|it = 'Stato problema sconosciuto.';
							|pl = 'Nieznany status problemu.';
							|tr = 'Bilinmeyen sorun durumu.'");
		
		Raise ExceptionText;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProblemStatuses(CurDataId = Undefined, ThisIsRemoval = False)
	
	
	If CurDataId <> Undefined Then
		CurrentData = Object.Goods.FindByID(CurDataId);
	Else
		CurrentData = Undefined;
	EndIf;	
	
	FieldsToConsider = WarehousesClientServer.FieldsTakenIntoAccountWhenCheckingSpendingOrder(ThisForm, CurrentData);
	FieldsToConsider.PackingList_ = False;
	
	DataProcessorObject = FormAttributeToValue("Object");
	Selection = DataProcessorObject.FillInProblemStatuses(FieldsToConsider, CurrentData, ThisIsRemoval, False);
	
	While Selection.Next() Do
		FillPropertyValues(Object.Goods[Selection.LineNumber - 1], Selection);
		
		If Selection.ItIsACargoItem Then
			PrintDescriptionOfProblem(Object.Goods[Selection.LineNumber - 1]);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function SplitByNonLoadable(Cached_Values)
	
	FieldsToConsider = WarehousesClientServer.FieldsTakenIntoAccountWhenCheckingSpendingOrder(ThisObject, Undefined);
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");
	
	DataProcessorObject = FormAttributeToValue("Object");
	FieldsToConsider.PackingList_ = UseItemPackages;
	SelectionOfExceedances = DataProcessorObject.SplitByNonLoadable(FieldsToConsider);
	
	RowsToProcess = New Array;
	ActionsWithStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ActionsWithStrings);
	
	ThereAreProblems = False;
	NonShippingString = Undefined;
	
	While SelectionOfExceedances.Next() Do
		
		ThereAreProblems = True;
		
		If SelectionOfExceedances.BatchesIndicationStatus = 1
			Or SelectionOfExceedances.BatchesIndicationStatus = 2
			Or (SelectionOfExceedances.BatchesIndicationStatus <> 0
			And Not ValueIsFilled(SelectionOfExceedances.Series)) Then
			// If there are series that do not need to be specified in non-shipped lines, then you cannot automatically split into shipped and 
			// non-shipped ones.
			Continue;
		ElsIf FieldsToConsider.SeriesStatusesThatAreNotTakenIntoAccount.Find(SelectionOfExceedances.BatchesIndicationStatus) = Undefined Then
			RowFilter = New Structure("Products,Characteristic,Purpose,Series,DoNotShip");
		Else
			RowFilter = New Structure("Products,Characteristic,Purpose,DoNotShip");
		EndIf;	
		If UseItemPackages Then
			RowFilter.Insert("Package");
		EndIf;
		
		FillPropertyValues(RowFilter, SelectionOfExceedances);
		RowFilter.DoNotShip = 0;
		
		LinesWithExcess = Object.Goods.FindRows(RowFilter);
		TSRow         = LinesWithExcess[0];
		
		If ValueIsFilled(TSRow.Package)
			And TSRow.NumberOfPackages > 0 Then
			PackagingFactor = TSRow.Count / TSRow.NumberOfPackages;
		Else
			PackagingFactor = 1;
		EndIf;
		
		NumberOfPackagesInDocument = SelectionOfExceedances.NumberOfPackagesInDocument;
		
		If SelectionOfExceedances.NumberOfPackagesInDocument > 0 Then
			
			DeleteLine_         = False;
			AccumulatedQuantity = 0;
			
			For Each TSRow In LinesWithExcess Do
				
				NonShippingString = NonShippingString(TSRow, NonShippingString, UseItemPackages);
				
				If AccumulatedQuantity + TSRow.NumberOfPackages >= NumberOfPackagesInDocument Then
					
					If Not DeleteLine_ Then
						
						DeleteLine_        = True;
						NumberOfExceedances = (AccumulatedQuantity + TSRow.NumberOfPackages) - NumberOfPackagesInDocument;
						
						TSRow.NumberOfPackages            = NumberOfPackagesInDocument - AccumulatedQuantity;
						NonShippingString.NumberOfPackages = NonShippingString.NumberOfPackages + NumberOfExceedances;
						
						AccumulatedQuantity = NumberOfPackagesInDocument + NumberOfExceedances;
						
						RowsToProcess.Add(TSRow);
						
					Else
						
						NonShippingString.NumberOfPackages = NonShippingString.NumberOfPackages + TSRow.NumberOfPackages;
						
						AccumulatedQuantity = AccumulatedQuantity + TSRow.NumberOfPackages;
						
						Object.Goods.Delete(TSRow);
						
					EndIf;
					
					RowsToProcess.Add(NonShippingString);
					
				Else
					AccumulatedQuantity = AccumulatedQuantity + TSRow.NumberOfPackages;
				EndIf;
				
			EndDo;
			
		Else
			
			ExcessQuantity_ = SelectionOfExceedances.Count / PackagingFactor;
			
			For Each TSRow In LinesWithExcess Do
				NonShippingString = NonShippingString(TSRow, NonShippingString, UseItemPackages);
				
				Object.Goods.Delete(TSRow);
			EndDo;
			
			If NonShippingString <> Undefined Then
				NonShippingString.NumberOfPackages = ExcessQuantity_;
				
				RowsToProcess.Add(NonShippingString);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		ActionsWithStrings,
		Object.Goods,
		Cached_Values);
	
	Return ThereAreProblems;
	
EndFunction

&AtServer
Function NonShippingString(SurplusLine, CurUnloadedLine, UseItemPackages)
	
	SearchFields = "Products,Characteristic,Purpose,Series";
	If UseItemPackages Then
		SearchFields = SearchFields + ",Package";
	EndIf;
	
	If CurUnloadedLine <> Undefined
		And TMCommonUseClientServer.StructuresAreEqual(SurplusLine,CurUnloadedLine,SearchFields) Then
		Return CurUnloadedLine;
	EndIf;
	
	RowFilter = New Structure(SearchFields);
	FillPropertyValues(RowFilter, SurplusLine);
	RowFilter.Insert("DoNotShip", 1);
	
	UnloadedStrings = Object.Goods.FindRows(RowFilter);
	
	If UnloadedStrings.Count() > 0 Then
		NonShippingString = UnloadedStrings[0];
	Else
		NonShippingString = Object.Goods.Add();
		FillPropertyValues(NonShippingString, SurplusLine);
		NonShippingString.Count         = 0;
		NonShippingString.NumberOfPackages = 0;
		NonShippingString.DoNotShip        = 1;
		NonShippingString.PackingList    = Documents.PackingList.EmptyRef();
	EndIf;
	
	Return NonShippingString;
	
EndFunction

&AtClient
Procedure PrintPresentationOfCurPackingList(PackingListCode_)
	
	StringText1 = New FormattedString(NStr("vi = 'Phiếu đóng gói hiện tại:';
											|ru = 'Текущий упаковочный лист:';
											|en = 'Current packing list:'; fa = 'Current packing list:';
											|it = 'Lista di imballaggio attuale:';
											|pl = 'Bieżący list pakowy:';
											|tr = 'Mevcut ürün listesi:'") + " ");
	If ValueIsFilled(CurrentPackingList) Then
		StringText2 = New FormattedString(PackingListCode_,New Font(,,True));;
	Else
		StringText2 = New FormattedString(NStr("vi = '<chưa chọn>';
												|ru = '<не выбран>';
												|en = '<Not selected>'; fa = '<Not selected>';
												|it = '<non è selezionato>';
												|pl = '<nie wybrany>';
												|tr = '<seçilmedi>'"),New Font(,,True));;
	EndIf;
	
	StringText3 = New FormattedString(NStr("vi = 'Thay đổi (F6)';
											|ru = 'Изменить (F6)';
											|en = 'Change (F6)'; fa = 'Change (F6)';
											|it = 'Modificare (F6)';
											|pl = 'Zmienić (F6)';
											|tr = 'Değiştir (F6)'"),,,,"Change");
	
	StringText4 = New FormattedString(NStr("vi = 'In nhãn tem';
											|ru = 'Напечатать этикетку';
											|en = 'Print label'; fa = 'چاپ برچسب';
											|it = 'Stampare etichetta';
											|pl = 'Wydrukuj etykietę';
											|tr = 'Etiketi yazdır'"),,,,"PrintLabel");
	
	StringText5 = New FormattedString(NStr("vi = 'In danh sách đóng gói';
											|ru = 'Напечатать упаковочный лист';
											|en = 'Print packing list'; fa = 'چاپ فهرست بسته‌بندی';
											|it = 'Stampare la lista d''imballaggio';
											|pl = 'Wydrukować list pakowy';
											|tr = 'Ürün listesini yazdır'"),,,,"PrintPackingList");
	
	Whitespace = "   ";
	
	RowsArray = New Array;
	RowsArray.Add(StringText1);
	RowsArray.Add(StringText2);
	RowsArray.Add(Whitespace);
	RowsArray.Add(StringText3);
	RowsArray.Add(Whitespace);
	RowsArray.Add(Whitespace);
	RowsArray.Add(StringText4);
	RowsArray.Add(Whitespace);
	RowsArray.Add(StringText5);
	
	CurrentPackingListPresentation = New FormattedString(RowsArray);	
	
EndProcedure

&AtClient
Procedure EditCurPackingListHandler()
	
	InputFormParameters = New Structure;
	InputFormParameters.Insert("Warehouse", Object.Warehouse);
	InputFormParameters.Insert("PackingList", CurrentPackingList);
	
	Notification = New CallbackDescription("EditCurPackingListHandlerCompletion",ThisForm);
	
	OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.SelectPackingList",
		InputFormParameters,
		ThisForm,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure EditCurPackingListHandlerCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result)
		And TypeOf(Result) = Type("Structure") Then
		
		CurrentPackingList = Result.PackingList;
		PrintPresentationOfCurPackingList(Result.Code);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintPackingListHandler()
	
	If Not ValueIsFilled(CurrentPackingList) Then
		MessageText = NStr("vi = 'Chưa chọn phiếu đóng gói hiện tại';
							|ru = 'Не выбран текущий упаковочный лист.';
							|en = 'The current packing list is not selected.'; fa = 'The current packing list is not selected.';
							|it = 'Non è stata selezionata la lista di imballaggio corrente.';
							|pl = 'Nie wybrany bieżący arkusz opakowaniowy.';
							|tr = 'Mevcut ürün listesi seçilmedi.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Kết thúc bổ sung danh sách đóng gói hiện tại và in danh sách?';
					|ru = 'Закончить наполнение текущего упаковочного листа и напечатать его?';
					|en = 'End filling in the current packing list and print it?'; fa = 'End filling in the current packing list and print it?';
					|it = 'Completare la compilazione della lista di imballaggio corrente e stamparla?';
					|pl = 'Zakończyć napełnianie bieżącego listu pakowego i wydrukować go?';
					|tr = 'Mevcut ürün listesinin doldurulması tamamlanıp yazdırılsın mı?'");
	QuestionButtons = New ValueList;
	QuestionButtons.Add(DialogReturnCode.Yes, NStr("vi = 'In';
													|ru = 'Напечатать';
													|en = 'Print'; fa = 'چاپ';
													|it = 'Stampare';
													|pl = 'Print';
													|tr = 'Yazdır'"));
	QuestionButtons.Add(DialogReturnCode.No, NStr("vi = 'Tiếp tục bổ sung';
													|ru = 'Продолжить наполнение';
													|en = 'Continue filling'; fa = 'Continue filling';
													|it = 'Continuare la compilazione';
													|pl = 'Kontynuować napełnianie';
													|tr = 'Doldurmaya devam et'"));
	
	Notification = New CallbackDescription("PrintPackingListHandlerCompletion",ThisForm);

	ShowQueryBox(Notification,QueryText,QuestionButtons);

EndProcedure

&AtClient
Procedure PrintPackingListHandlerCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentPackingList) Then
		MessageText = NStr("vi = 'Chưa chọn phiếu đóng gói hiện tại';
							|ru = 'Не выбран текущий упаковочный лист.';
							|en = 'The current packing list is not selected.'; fa = 'The current packing list is not selected.';
							|it = 'Non è stata selezionata la lista di imballaggio corrente.';
							|pl = 'Nie wybrany bieżący arkusz opakowaniowy.';
							|tr = 'Mevcut ürün listesi seçilmedi.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	WriteCurPackingList();
	
	Array = New Array;
	Array.Add(CurrentPackingList);
	
	PrintManagementClient.ExecutePrintCommand("Document.PackingList", "PackingList",
										Array, ThisForm, Undefined);
										
	CurrentPackingList = PredefinedValue("Document.PackingList.EmptyRef");
	PrintPresentationOfCurPackingList("");
	
EndProcedure

&AtServer
Procedure WriteCurPackingList()
	
	LinesOnPackingList = Object.Goods.FindRows(New Structure("PackingList", CurrentPackingList));
	
	PackingListObject = CurrentPackingList.GetObject();
	
	PackingListObject.PackageWarehouse = Object.Warehouse;
	PackingListObject.PackedBy = Users.CurrentUser();
	
	PackingListObject.Goods.Clear();
	
	For Each ArrRow In LinesOnPackingList Do
		
		NewRow = PackingListObject.Goods.Add();
		FillPropertyValues(NewRow, ArrRow); 
		
	EndDo;
	
	ParametersForSpecifyingSheetSeries = ProductsServer.SeriesSpecificationParameters(PackingListObject, Documents.PackingList);
	ProductsServer.FillInStatusesForSpecifyingSeries(PackingListObject, ParametersForSpecifyingSheetSeries); 
	
	PackingListObject.Write(DocumentWriteMode.Posting);
	
EndProcedure

&AtClient
Procedure PrintingLabelPackingListHandler()
	
	If Not ValueIsFilled(CurrentPackingList) Then
		MessageText = NStr("vi = 'Để in nhãn tem, cần chọn danh sách đóng gói, đồng thời chuyển theo tham chiếu ""Thay đổi"".';
							|ru = 'Для печати этикетки выберите упаковочный лист, перейдя по ссылке ""Изменить"".';
							|en = 'To print the label, select a packing list by clicking ""Change"".'; fa = 'To print the label, select a packing list by clicking ""Change"".';
							|it = 'Per stampare l''etichetta, selezionare la lista di imballaggio facendo clic sul link ""Modificare"".';
							|pl = 'Dla drukowania etykiety wybierz list pakowy, klikając na odnośnik ""Zmień"".';
							|tr = 'Bir etiket yazdırmak için ""Değiştir"" bağlantısına tıklayarak bir ürün listesi seç.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	PrintObjects = New Array();
    PrintObjects.Add(CurrentPackingList);
    PrintManagementTMClient.PrintingLabelsPackingSheets(New Structure("PrintObjects",PrintObjects));
	
EndProcedure

&AtClient
Procedure DonTShipHandler()
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormTable) Then
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	PackagingFactor = ?(CurrentData.ItIsACargoItem,
		1,
		?(CurrentData.NumberOfPackages = 0, 1, CurrentData.Count / CurrentData.NumberOfPackages));
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.Count = (CurrentData.NumberOfPackagesAmount
		- CurrentData.NumberOfPackagesInDocument) / PackagingFactor;
	StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng, mà không cần giao';
											|ru = 'Введите количество, которое не нужно отгружать';
											|en = 'Enter quantity that should not be shipped'; fa = 'Enter quantity that should not be shipped';
											|it = 'Inserire la quantità che non viene spedita';
											|pl = 'Wpisz ilość, którą nie trzeba wysyłać';
											|tr = 'Sevk edilmesi gerekmeyen miktarı gir'");
	StringSplittingParameters.AllowZeroCount = False;
	
	Notification = New CallbackDescription("DonTShipHandlerCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure DonTShipHandlerCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		NewRow.DoNotShip = 1;
		NewRow.PackingList = PredefinedValue("Document.PackingList.EmptyRef");
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		If CurrentData.NumberOfPackages = 0
			And NewRow.NumberOfPackages <> 0 Then
			Object.Goods.Delete(CurrentData);
		Else
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			FillInProblemStatuses(CurrentData.GetID());
		EndIf;
		
		FillInProblemStatuses(NewRow.GetID());
		
	EndIf;
	
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

&AtServer
Procedure LoadOrderVerificationSettings()
	
	OptionOfNoteCheckEnd = Common.CommonSettingsStorageLoad("OptionOfNoteCheckEnd",
		"", "RequestActionSelectionAfterVerification");
	
EndProcedure

&AtServer
Procedure ConfigureActionsAfterNoteCheckServer(ShouldSaveSettings = True)
	
	OptionOfNoteCheckEnd = ?(ValueIsFilled(OptionOfNoteCheckEnd),
										OptionOfNoteCheckEnd, "RequestActionSelectionAfterVerification");
	NoteStatusIsSelected				= ?(OptionOfNoteCheckEnd = "RequestActionSelectionAfterVerification", False,
										True);
	Object.NoteStatus				= ?(NoteStatusIsSelected,
										?(OptionOfNoteCheckEnd = "SetStatusChecked",
											Enums.GoodsIssueNoteStatuses.Verified, Enums.GoodsIssueNoteStatuses.ToShip),
										Enums.GoodsIssueNoteStatuses.EmptyRef());
	
	If ShouldSaveSettings Then
		SaveOrderVerificationSettings();
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveOrderVerificationSettings()
	
	Common.CommonSettingsStorageSave("OptionOfNoteCheckEnd", "",
		OptionOfNoteCheckEnd);
	
EndProcedure

&AtClient
Procedure SelectingActionAfterCheckingOrderCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		NoteStatusIsSelected = True;
		
		If Items.FormPages.CurrentPage = Items.PageErrors Then
			ReflectDiscrepanciesInAccountingClient();
		Else
			FinishCheckClient();
		EndIf;
		
	Else
		SkipConfirmationBeforeClosing = False;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
