#Region Variables

&AtClient
Var ClosurePermitted;

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InformationSecurityUserSUID = InfoBaseUsers.CurrentUser().UUID;
	Performer = Catalogs.Users.FindByAttribute("IBUserID", New UUID(InformationSecurityUserSUID));
	
	TypeOfStorageCellAcceptance  = Enums.TypesOfStorageCells.Receiving;
	TypeOfStorageCellShipment = Enums.TypesOfStorageCells.Shipment;
	
	TheModeOfGeneratingSpendingOrdersAutomatically = (Constants.GoodsIssueNoteGenerationMode.Get() 
		= Enums.GoodsIssueNoteGenerationModes.Automatically);
		
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If MobileClient Then
	GetAttributesOfOfflineNode(ExchangeMobileOfflineClient.CurrentNode());
#Else
	Items.StandaloneWorkplace.Visible = False;
#EndIf
	
	UsePeripherals = True;
	AttachIdleHandler("ExternalEquipmentMechanism", 5, True);
	
	CreatePresentationsOfSelections();
	GoToSection(Items.MenuAcceptance);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.MPMChoiceForm") Then
		
		Warehouse        = ValueSelected;
		Premise    = Undefined;
		ReceivingArea  = Undefined;
		ShippingZone = Undefined;		
		CreatePresentationsOfSelections();
		
	EndIf;
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warerooms.Form.MPMChoiceForm") Then
		
		Premise    = ValueSelected;
		ReceivingArea  = Undefined;
		ShippingZone = Undefined;
		ToFormRepresentationOfSelectionRoom();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

#If MobileClient Then
		If ClosurePermitted = Undefined Then
			If Exit Then
				WarningText = NStr("vi = 'Đóng ứng dụng?';
									|ru = 'Закрыть приложение?';
									|en = 'Close application?'; fa = 'Close application?';
									|it = 'Chiudere applicazione?';
									|pl = 'Zamknąć aplikację?';
									|tr = 'Uygulamayı kapat?'");
				Cancel = True;
			Else
				Mode = QuestionDialogMode.YesNo;
				Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject, Parameters);
				ShowQueryBox(Notification, NStr("vi = 'Đóng ứng dụng?';
												|ru = 'Закрыть приложение?';
												|en = 'Close application?'; fa = 'Close application?';
												|it = 'Chiudere applicazione?';
												|pl = 'Zamknąć aplikację?';
												|tr = 'Uygulamayı kapat?'"), Mode, 0);
				Cancel = True;
			EndIf;
		EndIf;
#EndIf

EndProcedure

&AtClient
Procedure OnMainServerAvailabilityChange(StandardProcessing)
	
#If MobileClient Then
	ReopenFromOtherServer();
#EndIf
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then 
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
				
				Data = MobileWarehouseKeeperWorkspaceClient.ConvertDataFromScannerToStructure(Parameter);
				
				ProcessBarcode(Data);
			
			EndIf;
		EndIf;
	EndIf;

EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EnableDataExchangeOnChange(Item)
	
	If EnableDataExchange = True Then
		ValueList = New ValueList;
		ValueList.Add("Enable", NStr("vi = 'Bật';
									|ru = 'Включить';
									|en = 'Enable'; fa = 'فعال';
									|it = 'Enable';
									|pl = 'Enable';
									|tr = 'Etkinleştir'"));
		ValueList.Add("DontInclude", NStr("vi = 'Không bật';
											|ru = 'Не включать';
											|en = 'Do not add'; fa = 'افزوده نشود';
											|it = 'Non includere';
											|pl = 'Nie włączaj';
											|tr = 'Etkinleştirme'"));
		
		Notification = New CallbackDescription("AfterClosingQuestionEnableDataExchange", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Sau khi bật đồng bộ, quá trình trao đổi dữ liệu sẽ bắt đầu và có thể mất nhiều thời gian. Có cần bật đồng bộ không?';
										|ru = 'После включения синхронизации начнется обмен данными, который может занять длительное время. Включить синхронизацию?';
										|en = 'After enabling synchronization, data exchange will begin, which may take a long time. Enable synchronization?'; fa = 'After enabling synchronization, data exchange will begin, which may take a long time. Enable synchronization?';
										|it = 'After enabling synchronization, data exchange will begin, which may take a long time. Enable synchronization?';
										|pl = 'After enabling synchronization, data exchange will begin, which may take a long time. Enable synchronization?';
										|tr = 'Senkronizasyon etkinleştirildikten sonra uzun sürebilecek veri alışverişi başlayacaktır. Senkronizasyon etkinleştirilsin mi?'"), ValueList, 0);
	Else
		ValueList = New ValueList;
		ValueList.Add("Disable", NStr("vi = 'Tắt';
										|ru = 'Выключить';
										|en = 'Disable'; fa = 'غیرفعال';
										|it = 'Disable';
										|pl = 'Disable';
										|tr = 'Devre dışı bırak'"));
		ValueList.Add("DonTTurnItOff", NStr("vi = 'Không tắt';
											|ru = 'Не выключать';
											|en = 'Do not disable'; fa = 'Do not disable';
											|it = 'Do not disable';
											|pl = 'Do not disable';
											|tr = 'Devre dışı bırakma'"));
		
		Notification = New CallbackDescription("AfterClosingQuestionEnableDataExchange", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Sau khi tắt đồng bộ, việc trao đổi dữ liệu sẽ không còn được thực hiện và dữ liệu ở chế độ ngoại tuyến có thể không còn cập nhật. Có cần tắt đồng bộ không?';
										|ru = 'После выключения синхронизации обмен больше не будет выполняться, и данные в автономном режиме могут стать неактуальными. Выключить синхронизацию?';
										|en = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?'; fa = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?';
										|it = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?';
										|pl = 'After synchronization is disabled, the exchange will no longer be performed, and standalone mode data may become irrelevant. Disable synchronization?';
										|tr = 'Senkronizasyon kapatıldıktan sonra veri alışverişi artık yapılmayacak ve tek başına mod verileri güncelliğini kaybedebilir. Senkronizasyon devre dışı bırakılsın mı?'"), ValueList, 0);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsExportStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ValueIsFilled(DocumentsExportStartDate) Then
		ValueList = New ValueList;
		ValueList.Add("Clear", NStr("vi = 'Xóa';
									|ru = 'Очистить';
									|en = 'Clear'; fa = 'پاک کردن';
									|it = 'Cancellare';
									|pl = 'Clear';
									|tr = 'Temizle'"));
		ValueList.Add("NotClear", NStr("vi = 'Không xóa';
										|ru = 'Не очищать';
										|en = 'Do not clean up'; fa = 'پاک‌سازی نشود';
										|it = 'Non cancellare';
										|pl = 'Nie oczyszczaj';
										|tr = 'Temizlenmesin'"));
		
		Notification = New CallbackDescription("AfterClosingQuestionDateOfStartOfUploadingDocuments", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Nếu để trống ngày, thì tất cả chứng từ trong toàn bộ giai đoạn sẽ được kết xuất vào cấu hình độc lập, việc này có thể mất nhiều thời gian. Có cần xóa ngày không?';
										|ru = 'Если оставить дату незаполненной, то в автономную конфигурацию будут выгружаться документы за весь период, что может занять продолжительное время. Очистить дату?';
										|en = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?'; fa = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?';
										|it = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?';
										|pl = 'If you leave the date blank, documents for the entire period will be imported to the standalone configuration, which may take a long time. Clear the date?';
										|tr = 'Tarih boş bırakılırsa, tüm dönem için belgeler bağımsız konfigürasyona aktarılacaktır, bu uzun sürebilir. Tarih temizlensin mi?'"), ValueList, 0);
	Else
		StartDateOfUploadingDocumentsOnChangeAtServer();
		Items.DocumentsExportStartDate.ToolTip = StrTemplate(NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng %1 mới được kết xuất vào chế độ độc lập.';
																	|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна %1.';
																	|en = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.'; fa = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																	|it = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																	|pl = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																	|tr = 'Tek başına moda yalnızca tarihi %1''e eşit veya daha büyük olan belgeler aktarılacaktır'"), Format(DocumentsExportStartDate, NStr("vi = 'DLF = D';
																																																				|ru = 'ДЛФ=Д';
																																																				|en = 'DLF=D'; fa = 'DLF=D';
																																																				|it = 'DLF=D';
																																																				|pl = 'DLF=D';
																																																				|tr = 'DLF=D'")));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AcceptanceMenu(Command)
	GoToSection(Items.MenuAcceptance);
EndProcedure

&AtClient
Procedure MenuShipping(Command)
	GoToSection(Items.ShippingMenu);
EndProcedure

&AtClient
Procedure OtherTransactions(Command)
	GoToSection(Items.OtherMenuOperations);
EndProcedure

&AtClient
Procedure ScanMenu(Command)
	GoToSection(Items.ScanningMenu);
EndProcedure

&AtClient
Procedure SettingsMenu(Command)
	GoToSection(Items.MenuSettings);
EndProcedure

&AtClient
Procedure UpdateForm(Command)
	
	Code = Undefined;
#If MobileClient Then
	Code = ExchangeMobileOfflineClient.CurrentNode();
#EndIf
	UpdateFormCommandServer(Code);
	
EndProcedure

&AtClient
Procedure OrdersAcceptance(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ReceiptRefs",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Receiving(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsReceiptNoteList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Place(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ReceivingArea", ReceivingArea);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PutAwayList", FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure PlacementTasks(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PutAwayJobList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure OrdersShipment(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ShipmentReferences",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure NotesToFilter(Command)
	
	OpenListOfOrders("NotesToFilter");

EndProcedure

&AtClient
Procedure NotesToCheck(Command) 
	
	OpenListOfOrders("NotesToCheck"); 
	
EndProcedure

&AtClient
Procedure NotesToShip(Command)
	
	OpenListOfOrders("NotesToShip");
	
EndProcedure 

&AtClient
Procedure PickingFromStorageBins(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PickJobList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Move(Command)
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.TransferJobList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);

EndProcedure

&AtClient
Procedure Recalculate(Command)
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.RecountsList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
EndProcedure

&AtClient
Procedure LockingCells(Command)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.LockList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ProductItemSearch(Command)
	
	LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "ProductItemsSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ResiduesInCells(Command)
	
	LongDesc = New CallbackDescription("CellScanResult", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "CellSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure GoOut(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure SelectionsOpenWarehouse(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	
	Filter = New Structure();
	Filter.Insert("UseWarehouseManagemantSystemForGoodsReceipt", True);
	FormOpenParameters.Insert("Filter", Filter);
		
	OpenForm(
		"Catalog.Warehouses.Form.MPMChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionsOpenRoom(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	
	Filter = New Structure();
	Filter.Insert("Owner", Warehouse);
	
	FormOpenParameters.Insert("Filter", Filter);
		
	OpenForm(
		"Catalog.Warerooms.Form.MPMChoiceForm",
		FormOpenParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectionsClearWarehouse(Command)
	
	Warehouse     = Undefined;
	Premise = Undefined;
	CreatePresentationsOfSelections();
	
EndProcedure

&AtClient
Procedure SelectionsCleanRoom(Command)

	Premise = Undefined;
	ReceivingArea  = Undefined;
	ShippingZone = Undefined;
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure 

#If MobileClient Then
&AtClient
Procedure BarcodeScanning(Command)
			
	If MultimediaTools.BarcodeScanningSupported() Then		
		ScanningHandler = New CallbackDescription("ScanProcessing", ThisObject);
		MultimediaTools.ShowBarcodeScanning(NStr("vi = 'Hướng máy ảnh vào mã vạch';
												|ru = 'Наведите камеру на штрихкод';
												|en = 'Point the camera at the barcode'; fa = 'Point the camera at the barcode';
												|it = 'Puntare la camera sul codice a barre';
												|pl = 'Skieruj aparat na kod kreskowy';
												|tr = 'Kamerayı barkoda doğrult'"), ScanningHandler,,
			BarcodeType.Linear);
	EndIf;
	
EndProcedure
#EndIf

&AtClient
Procedure FindByBarcode(Command)
	
	ProcessBarcode(New Structure("Barcode", Barcode));
	
EndProcedure

#EndRegion 

#Region Private

#If MobileClient Then 
&AtClient
Procedure ScanProcessing(BarcodeCamera, Result, Message, AdditionalParameters) Export

	If Result Then
		MultimediaTools.PlaySoundAlert(SoundAlert.Default, True);
		MultimediaTools.CloseBarcodeScanning(); 
		
		Barcode = BarcodeCamera;
		ProcessBarcode(New Structure("Barcode", Barcode));
	Else
		Message = NStr("vi = 'Lỗi xử lý mã vạch';
						|ru = 'Ошибка обработки штрихкода';
						|en = 'Barcode processing error'; fa = 'Barcode processing error';
						|it = 'Barcode processing error';
						|pl = 'Barcode processing error';
						|tr = 'Barkod İşleme hatası'");
	EndIf;
	
EndProcedure
#EndIf

&AtClient
Procedure OpenListOfOrders(Mode)
	
	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Performer", Performer);
	FormParameters.Insert("Mode", Mode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsIssueNoteList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure ExternalEquipmentMechanism()
	
	// ExternalEquipmentMechanism
#If MobileClient Then
	Execute("EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
	|New CallbackDescription(""StartConnectingDevicesWhenYouOpenFormCompletion"", ThisObject), ThisObject, ""BarcodeScanner"")");
#Else
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
	New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", ThisObject),
	ThisObject,
	"BarcodeScanner");
#EndIf
	// End ExternalEquipmentMechanism
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
			
	ErrorText = "";
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1); 
		
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
	Status(NStr("vi = 'Đang tìm kiếm đối tượng theo mã vạch...';
				|ru = 'Выполняется поиск объекта по штрихкоду...';
				|en = 'Searching for the object by barcode...'; fa = 'Searching for the object by barcode...';
				|it = 'Searching for the object by barcode...';
				|pl = 'Searching for the object by barcode...';
				|tr = 'Nesne barkoda göre aranıyor...'")); 
			
	BarcodeData = DataOnGeneralBarcode(BarcodeData_1.Barcode);
		
	If BarcodeData.ObjectKind = "Products" 
		And UsedFormServer = UsedServer.Main Then 
			
		ResultOfScanningItem(BarcodeData.Goods);
			
	ElsIf BarcodeData.ObjectKind = "Cell"
		And UsedFormServer = UsedServer.Main Then
			
		CellScanResult(BarcodeData.CellData); 
			
	ElsIf BarcodeData.ObjectKind = "Document" Then 
			
		If ValueIsFilled(BarcodeData.DocumentData.ErrorText) Then
			Status(BarcodeData.DocumentData.ErrorText);
			Return;
		EndIf;
		
		DocumentScanResult(BarcodeData.DocumentData);
			
	ElsIf BarcodeData.ObjectKind = Undefined Then

		ErrorText = BarcodeData.ErrorText;
		
		Status(ErrorText);
			
	EndIf;
	
EndProcedure

&AtServer
Function DataOnGeneralBarcode(Val Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOnGeneralBarcode(Barcode, Warehouse, Premise);

EndFunction

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	LongDesc = New CallbackDescription("UpdateFormServer", ThisObject);

	If Result.References.Count() > 1 Then 
		
		LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);

		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", Result);
		FormParameters.Insert("Warehouse", Warehouse); 
		FormParameters.Insert("Premise", Premise);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,,LongDesc, FormWindowOpeningMode.LockWholeInterface);
		
	ElsIf Result.ThisIsOrder_ Then
		
		ReferenceOrder =  Result.References[0];
		
		FormParameters = New Structure;

		If Result.Direction = "Shipment" Then  
			FillingStructure = New Structure;
			FillingStructure.Insert("Warehouse", Warehouse);
			FillingStructure.Insert("Premise", Premise);
			FillingStructure.Insert("ReferenceOrder", ReferenceOrder.ReferenceOrder); 
			FillingStructure.Insert("Recipient", ReferenceOrder.Recipient);
			FormParameters.Insert("DocumentType", 2);
		Else
			FillingStructure = GetStructureOfOrderFilling();
	
			FillPropertyValues(FillingStructure, ReferenceOrder);
			FillingStructure.Warehouse           = Warehouse;
			FillingStructure.Premise       = Premise;
		
			FillingStructure.Insert("Sender", ReferenceOrder.Sender);
			FormParameters.Insert("DocumentType", 1);
		EndIf;
		
		FormParameters.Insert("FillingStructure", FillingStructure);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("DocumentName_1", ReferenceOrder.DocumentType);
		FormParameters.Insert("Number", ReferenceOrder.Number);
		FormParameters.Insert("Barcode", Result.Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Goods", FormParameters,
			ThisObject,,,,LongDesc, FormWindowOpeningMode.Independent);
		
	Else
			
		Document = Result.References[0];
		Type = TypeOf(Document);
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Document);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Result.Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);
		
		If Type = Type("DocumentRef.GoodsIssueNote") Then 
				
			NameOfFormToOpen_ = "DataProcessor.MobileWarehouseKeeperWorkspace.Form.ExpenseOrder"
			
		ElsIf Type = Type("DocumentRef.GoodsReceiptNote") Then 
			
			FormParameters.Insert("Performer", Performer);
			NameOfFormToOpen_ = "DataProcessor.MobileWarehouseKeeperWorkspace.Form.ReceiptGoodsOrder"
			
		ElsIf Type = Type("DocumentRef.GoodsPickingPlacement") Then
			
			If Result.Direction = "Shipment" Then
				FormParameters.Insert("Seamless", False);
				NameOfFormToOpen_ = "DataProcessor.MobileWarehouseKeeperWorkspace.Form.Filter";
			ElsIf Result.Direction = "Receiving" Then 
				NameOfFormToOpen_ = "DataProcessor.MobileWarehouseKeeperWorkspace.Form.PutAwayToStorageBins";
			Else
				NameOfFormToOpen_ = "DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsTransferJob";
			EndIf;
			
		ElsIf Type = Type("DocumentRef.InventoryRecount") Then 
			
			NameOfFormToOpen_ = "DataProcessor.MobileWarehouseKeeperWorkspace.Form.InventoryRecount"
			
		EndIf; 
		
		OpenForm(NameOfFormToOpen_, FormParameters, ThisObject,,,,LongDesc, FormWindowOpeningMode.Independent);

	EndIf;
	
EndProcedure

&AtClient
Procedure ResultOfScanningItem(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Count() > 1 Then 
		
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		
		FillingValues = New Structure;
		FillingValues.Insert("Goods", Result);
		FillingValues.Insert("Mode", "SelectItems");
		FillingValues.Insert("Barcode", "");
		
		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", FillingValues);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,,LongDesc, FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ProductData_8 = Result[0];
	
		FormParameters = New Structure;
		FormParameters.Insert("Products", ProductData_8.Products);
		FormParameters.Insert("Characteristic", ProductData_8.Characteristic);
		FormParameters.Insert("Package", ProductData_8.Package);
		FormParameters.Insert("Series", ProductData_8.Series);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.SearchByProductItem",FormParameters,
			ThisObject,,,,,
			FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

&AtClient
Procedure CellScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell", Result.Cell);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.SearchAtCell",FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure StartConnectingDevicesWhenYouOpenFormCompletion(ExecutionResult, AdditionalParameters) Export

	If Not ExecutionResult.Result Then
		
		IfHardwareConnectionOnServerFails(ExecutionResult.ErrorDescription);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure IfHardwareConnectionOnServerFails(ErrorDescription)
	
	UserMessage = New UserMessage;
	UserMessage.Text = ErrorDescription;
	UserMessage.Message();
	
EndProcedure

&AtClient
Procedure UpdateFormServer(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateCountersServer();
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure UpdateFormCommandServer(NodeCode)
	
	UpdateCountersServer();
	GetAttributesOfOfflineNode(NodeCode);
	
EndProcedure

&AtServer
Procedure UpdateCountersServer()
	
	If Items.Sections.CurrentPage = Items.AcceptanceSection Then
		TagsAcceptanceSection();
	ElsIf Items.Sections.CurrentPage = Items.ShipmentSection Then
		CountersShipmentSection();
	ElsIf Items.Sections.CurrentPage = Items.OtherOperationsSection Then
		CountersOtherOperationsSection();
	EndIf;
	
EndProcedure

&AtServer
Procedure CreatePresentationsOfSelections()

	CreateRepresentationOfWarehouseSelection();
	ToFormRepresentationOfSelectionRoom();
	
EndProcedure

&AtServer
Procedure CreateRepresentationOfWarehouseSelection()
	
	UseWarerooms = False;
	UseGoodsIssueNoteStatuses = False;
		
	PresentationsOfSelections = "";
	If ValueIsFilled(Warehouse) Then
		PresentationsOfSelections = Warehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.TeamSelectionsClear.Visible = True;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
		
		WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(Warehouse);
		If ValueIsFilled(WarehouseProperties) Then
			UseBinLocationWarehousing = WarehouseProperties.UseBinLocationWarehousing;
			UseWarerooms = WarehouseProperties.UseWarerooms;
			UseGoodsIssueNoteStatuses = WarehouseProperties.UseGoodsIssueNoteStatuses;
		EndIf;
	Else
		PresentationsOfSelections = NStr("vi = 'Chọn kho bãi';
										|ru = 'Выбрать склад';
										|en = 'Select a warehouse'; fa = 'Select a warehouse';
										|it = 'Selezionare magazzino';
										|pl = 'Wybierz magazyn';
										|tr = 'Ambar seç'");

		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;  
	EndIf;
			
	Items.GroupTeamSelectionsOpen2.Visible    = UseWarerooms;
	Items.TeamSelectionsClearRoom.Visible = UseWarerooms;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtServer
Procedure ToFormRepresentationOfSelectionRoom()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(Premise) Then
		PresentationsOfSelections = Premise;
		Items.TeamSelectionsOpenRoom.TextColor = WebColors.Black;
		Items.TeamSelectionsClearRoom.Visible = True;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuBlack; 

		UseBinLocationWarehousing = Premise["UseBinLocationWarehousing"];
	Else
		PresentationsOfSelections = NStr("vi = 'Chọn nhà kho';
										|ru = 'Выбрать помещение';
										|en = 'Select a wareroom'; fa = 'Select a wareroom';
										|it = 'Selezionare locale';
										|pl = 'Wybierz pomieszczenie';
										|tr = 'Alan seç'");

		Items.TeamSelectionsOpenRoom.TextColor = WebColors.DarkGray;
		Items.TeamSelectionsClearRoom.Visible = False;
		Items.FrameSelectionsOpen2.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsOpenRoom.Title = PresentationsOfSelections;
	
EndProcedure

&AtClient
Procedure GoToSection(MenuItem)
	
	// Changing the menu icon
	Items.MenuAcceptance.Picture        = PictureLib.MWPWarehouseKeeperReceipt;
	Items.ShippingMenu.Picture       = PictureLib.MWPWarehouseKeeperShipmentGray;
	Items.OtherMenuOperations.Picture = PictureLib.MWPWarehouseKeeperOtherOperations;
	Items.ScanningMenu.Picture   = PictureLib.StorekeeperSMRMScan;
	Items.MenuSettings.Picture      = PictureLib.MWPWarehouseKeeperSettings;
	
	// Menu highlighting
	White  = WebColors.White;
	Yellow = WebColors.LightGoldenRod;
	
	Items.MenuAcceptance.BackColor        = White;
	Items.ShippingMenu.BackColor       = White;
	Items.OtherMenuOperations.BackColor = White;
	Items.ScanningMenu.BackColor   = White;
	Items.MenuSettings.BackColor      = White;
	
	Items.MenuAcceptanceGroup.BackColor        = White;
	Items.ShippingMenuGroup.BackColor       = White;
	Items.OtherMenuOperationsGroup.BackColor = White;
	Items.MenuScanningGroup.BackColor   = White;
	Items.MenuSettingsGroup.BackColor      = White;
	
	If MenuItem = Items.MenuAcceptance Then
		Items.Sections.CurrentPage    = Items.AcceptanceSection;
		MenuItem.Picture     = PictureLib.MWPWarehouseKeeperReceiptActive;
		Items.MenuAcceptanceGroup.BackColor = Yellow;
		Items.MenuAcceptance.BackColor       = Yellow;
	ElsIf MenuItem = Items.ShippingMenu Then
		Items.Sections.CurrentPage     = Items.ShipmentSection;
		MenuItem.Picture     = PictureLib.MWPWarehouseKeeperShipmentActive;
		Items.ShippingMenuGroup.BackColor = Yellow;
		Items.ShippingMenu.BackColor       = Yellow;
		
		Items.OrderGroupSelection.Visible  = True;
		Items.GroupSelectionFromCells.Visible = True;
		Items.OrderGroupVerification.Visible = True;
		
		If ValueIsFilled(Warehouse) And Not UseGoodsIssueNoteStatuses Then			
			Items.OrderGroupSelection.Visible    = False;
			Items.GroupSelectionFromCells.Visible   = False;
			Items.OrderGroupVerification.Visible = False;
		ElsIf UseWarerooms And Not ValueIsFilled(Premise) Then	
			Items.OrderGroupSelection.Visible  = True;
			Items.GroupSelectionFromCells.Visible = True;
		ElsIf Not ValueIsFilled(Warehouse) Then
			Items.OrderGroupSelection.Visible  = True;
			Items.GroupSelectionFromCells.Visible = True;
			Items.OrderGroupVerification.Visible = True;
		Else
			Items.OrderGroupSelection.Visible  = Not UseBinLocationWarehousing 
				Or TheModeOfGeneratingSpendingOrdersAutomatically;
			Items.GroupSelectionFromCells.Visible = UseBinLocationWarehousing;
		EndIf;

	ElsIf MenuItem = Items.OtherMenuOperations Then
		Items.Sections.CurrentPage           = Items.OtherOperationsSection;
		MenuItem.Picture     = PictureLib.MWPWarehouseKeeperOtherOperationsActive;
		Items.OtherMenuOperationsGroup.BackColor = Yellow;
		Items.OtherMenuOperations.BackColor       = Yellow;
	ElsIf MenuItem = Items.ScanningMenu Then
		Items.Sections.CurrentPage   = Items.ScanSection;
		MenuItem.Picture     = PictureLib.StorekeeperSMRMScanActive;
		Items.MenuScanningGroup.BackColor = Yellow;
		Items.ScanningMenu.BackColor       = Yellow;
	ElsIf MenuItem = Items.MenuSettings Then
		Items.Sections.CurrentPage      = Items.ConfigurationSection;
		MenuItem.Picture     = PictureLib.MWPWarehouseKeeperActive;
		Items.MenuSettingsGroup.BackColor = Yellow;
		Items.MenuSettings.BackColor       = Yellow;
	EndIf;
	
	UpdateFormServer();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	Items.CurrentUser.Title = Performer;
	Items.OrderGroupShipment.Visible = Not TheModeOfGeneratingSpendingOrdersAutomatically;  
	
	OrderOfWorkWhenPerformingTaskMCW = Constants.OrderOfWorkWhenPerformingTaskMCW.Get(); 
	
	If OrderOfWorkWhenPerformingTaskMCW = 
		Enums.OrderOfWorkWhenPerformingTaskMCW.DeterminedByStorekeeper Then 
		
		Items.GroupScanOrder.Visible = True;
		If Not ValueIsFilled(ScanningProcedure) Then
			ScanningProcedure = "FirstScanCell";
		EndIf;
		
	ElsIf OrderOfWorkWhenPerformingTaskMCW = 
		Enums.OrderOfWorkWhenPerformingTaskMCW.FirstScanCell 
		Or Not ValueIsFilled(OrderOfWorkWhenPerformingTaskMCW) Then
		
		Items.GroupScanOrder.Visible = False;
		ScanningProcedure = "FirstScanCell";
		
	ElsIf OrderOfWorkWhenPerformingTaskMCW = 
		Enums.OrderOfWorkWhenPerformingTaskMCW.FirstScanProduct Then
		
		Items.GroupScanOrder.Visible = False;
		ScanningProcedure = "FirstScanProduct";
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	// ExternalEquipmentMechanism
	If UsedFormServer = UsedServer.Main Then
#If MobileClient Then
		
		Execute("EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject)");
		
#Else
		
		EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
		
#EndIf
	EndIf;
	// End ExternalEquipmentMechanism
	
	ClosurePermitted = True;
	Close();
	Exit(True);
	
EndProcedure

&AtServer
Procedure TagsAcceptanceSection()
	
	ArrayOfPerformers = New Array;
	ArrayOfPerformers.Add(Performer);
	ArrayOfPerformers.Add(Catalogs.Users.EmptyRef());

	// Acceptance orders
#If Not MobileStandaloneServer Then
	ReceiptState = Enums.GoodsReceiptStates.PendingReceiving;
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RequestForOrderForAcceptance(Warehouse, CurrentSessionDate(), ReceiptState);
	Query.Text = StrReplace(Query.Text, "WHERE &ConditionForOrders", "");
	Table = Query.Execute().Unload();
	Items.OrdersAcceptance1.Title = Table.Count();
#Else
	Items.OrdersAcceptance1.Title = 0;
#EndIf
	
	// Incoming orders
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.GoodsReceiptNoteList();
	Query.SetParameter("Warehouse", Warehouse);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND GoodsReceiptNote.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "AND GoodsReceiptNote.Performer IN(&Performer)");
	Query.SetParameter("Performer", ArrayOfPerformers);
	
	Statuses = New Array();
	Statuses.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
	Statuses.Add(Enums.GoodsReceiptNoteStatuses.InProgress);
	Query.SetParameter("Statuses", Statuses);
	
	Table = Query.Execute().Unload();
	Items.Receiving1.Title = Table.Count();
	
	// Products to be placed in cells
#If Not MobileStandaloneServer Then
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.PutAwayList();
	Query.SetParameter("ReceivingArea", ReceivingArea);
	Table = Query.Execute().Unload();
	Items.Location1.Title = Table.Count();
#Else
	Items.Location1.Title = 0;
#EndIf
	
	// List of placement tasks
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.PutAwayJobList();
	
	Query.SetParameter("ReceivingArea", ReceivingArea);
	
	Query.SetParameter("Warehouse", Warehouse);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND DocumentGoodsPickingPlacement.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "AND DocumentGoodsPickingPlacement.Performer IN(&Performer)");
	Query.SetParameter("Performer", ArrayOfPerformers);
	
	Statuses = New Array();
	Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
	Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
	Query.SetParameter("Statuses", Statuses);
	
	Table = Query.Execute().Unload();
	Items.Location3.Title = Table.Count();

EndProcedure

&AtServer
Procedure CountersShipmentSection()
	
	ArrayOfPerformers = New Array;
	ArrayOfPerformers.Add(Performer);
	ArrayOfPerformers.Add(Catalogs.Users.EmptyRef());

	// Orders for shipment
	#If Not MobileStandaloneServer Then
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RequestOrderForShipment(Warehouse);
	
	DateOfShipment = CurrentSessionDate();
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("TransportationJob", Documents.TransportationJob.EmptyRef());
	Query.SetParameter("DateOfShipment", ?(ValueIsFilled(DateOfShipment), EndOfDay(DateOfShipment) + 1, DateOfShipment));
	IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
	Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
	Query.SetParameter("ShowDetailsShipment", False);
	Query.Text = StrReplace(Query.Text, "&ConditionForOrders", "");
	
	States1 = New Array;
	States1.Add(Enums.GoodsPickingStates.PendingPicking);
	Query.SetParameter("States1", States1);
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Items.OrdersShipmentCounter.Title = Table.Count();
#Else
	Items.OrdersShipmentCounter.Title = 0;
#EndIf
		
	// Expense orders
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RequestListOfSpendingOrders();
	
	//
	QueryText = "
		|	AND GoodsIssueNote.Status = &Status";

	If ValueIsFilled(Premise) Then
		QueryText = QueryText + "
			|	AND GoodsIssueNote.Premise = &Premise";
	EndIf;

	Query.Text = Query.Text + QueryText;
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("ResponsibleTitle", NStr("vi = 'Người thực hiện';
												|ru = 'Исполнитель';
												|en = 'Assignee'; fa = 'Assignee';
												|it = 'Assignee';
												|pl = 'Assignee';
												|tr = 'İcracı'"));
	
	If TheModeOfGeneratingSpendingOrdersAutomatically Then
		Query.SetParameter("Status", Enums.GoodsIssueNoteStatuses.Prepared);
	Else
		Query.SetParameter("Status", Enums.GoodsIssueNoteStatuses.ForPicking);
	EndIf;
	Table = Query.Execute().Unload();
	Items.OrdersToBeSelectedCounter.Title = Table.Count();		
		
	If ValueIsFilled(Warehouse) And Not UseGoodsIssueNoteStatuses Then 
		Query.SetParameter("Status", Enums.GoodsIssueNoteStatuses.Shipped_);
	Else
		Query.SetParameter("Status", Enums.GoodsIssueNoteStatuses.Verified);
	EndIf;
	Table = Query.Execute().Unload();
	Items.OrdersToBeShippedCounter.Title = Table.Count();
	
	CheckOnlyYourNotes = DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders()
		And Not DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders();
	CheckOnlyOtherNotes = DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders()
		And Not DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders();
		
	If CheckOnlyOtherNotes Then
		Query.Text = Query.Text + "
		|	AND GoodsIssueNote.EmployeeResponsible <> &EmployeeResponsible";
			Query.SetParameter("EmployeeResponsible", Performer);
	EndIf;
	If CheckOnlyYourNotes Then
		Query.Text = Query.Text + "
		|	AND GoodsIssueNote.EmployeeResponsible = &EmployeeResponsible";
		Query.SetParameter("EmployeeResponsible", Performer);
	EndIf;
	
	Query.SetParameter("Status", Enums.GoodsIssueNoteStatuses.ForChecking);
	Table = Query.Execute().Unload();
	Items.OrdersToBeCheckedCounter.Title = Table.Count();
	
	// List of selection tasks
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RequestListOfSelectionTasks();

	QueryText = " 
		|	AND GoodsIssueNote.Status = &Status";
	
	QueryText = QueryText + "
		|	AND DocumentGoodsPickingPlacement.Performer IN (&Performer)";

	If ValueIsFilled(Premise) Then
		QueryText = QueryText + "
			|	AND DocumentGoodsPickingPlacement.Premise = &Premise";
	EndIf;
	
	Query.SetParameter("Warehouse", Warehouse); 
	Query.SetParameter("ShippingZone", ShippingZone);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("PerformerTitle", NStr("vi = 'Người thực hiện';
												|ru = 'Исполнитель';
												|en = 'Assignee'; fa = 'Assignee';
												|it = 'Assignee';
												|pl = 'Assignee';
												|tr = 'İcracı'"));
	Query.SetParameter("Performer", ArrayOfPerformers);
		
	Statuses = New Array();
	Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
	Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
	Query.SetParameter("Statuses", Statuses);
	
	Table = Query.Execute().Unload();
	Items.SelectionFromCounterCells.Title = Table.Count();

EndProcedure

&AtServer
Procedure CountersOtherOperationsSection()
	
	// List of moving tasks
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.TransferJobList();
	
	ArrayOfPerformers = New Array;
	ArrayOfPerformers.Add(Performer);
	ArrayOfPerformers.Add(Catalogs.Users.EmptyRef());
	
	Query.SetParameter("Warehouse", Warehouse);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND DocumentGoodsPickingPlacement.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "AND DocumentGoodsPickingPlacement.Performer IN (&Performer)");
	Query.SetParameter("Performer", ArrayOfPerformers);
	
	Statuses = New Array();
	Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
	Statuses.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
	Query.SetParameter("Statuses", Statuses);
	
	Table = Query.Execute().Unload();
	Items.Move1.Title = Table.Count();
	
	// List of recalculations
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.RecountsList();

	Query.SetParameter("Warehouse", Warehouse);
	
	Query.Text = StrReplace(Query.Text, "AND &ConditionExecutor", "AND InventoryRecount.Performer IN (&Performer)");
	Query.SetParameter("Performer", ArrayOfPerformers);
	
	Query.Text = StrReplace(Query.Text, "AND &ConditionStatus", "AND DocumentGoodsPickingPlacement.Status = &Status");
	Query.SetParameter("Status", Enums.InventoryRecountStatuses.EnteringResults);
	
	If ValueIsFilled(Premise) Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND InventoryRecount.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;
	
	Table = Query.Execute().Unload();
	Items.Recalculate1.Title = Table.Count();
	
	// List of locks
	Query = DataProcessors.MobileWarehouseKeeperWorkspace.LockList();
	
	If Not Premise.IsEmpty() Then
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "AND StorageBinsLocks.Cell.Premise = &Premise");
		Query.SetParameter("Premise", Premise);
	Else
		Query.Text = StrReplace(Query.Text, "AND &ConditionPremises", "");
	EndIf;

	Query.SetParameter("Warehouse", Warehouse);
	
	Table = Query.Execute().Unload();
	Items.LockingCells1.Title = Table.Count();
	
EndProcedure

&AtServerNoContext
Function GetStructureOfOrderFilling()
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.StructureOfFillingIncomingOrder();
	
EndFunction

&AtClient
Procedure AfterClosingQuestionEnableDataExchange(Result, Var_Parameters) Export
	
#If MobileClient Then
	If Result = "Enable" Or Result = "DonTTurnItOff" Then
		EnableDataExchange = True;
	Else
		EnableDataExchange = False;
	EndIf;
	
	EnableDataExchangeOnChangeATServer();
	
	If Result = "Enable" Then
		ExchangeMobileClient.EnableSharing();
	EndIf;
	
	If Result = "Disable" Then
		ExchangeMobileClient.DisableSharing();
	EndIf;
	
	Items.DocumentsExportStartDate.Enabled = Not EnableDataExchange;
#EndIf
	
EndProcedure

&AtServer
Procedure EnableDataExchangeOnChangeATServer()
	
	BeginTransaction();	
	Try
		Block = New DataLock;
		LockItem = Block.Add("ExchangePlan.Mobile"); 
		LockItem.SetValue("Ref", StandaloneNode);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Node = StandaloneNode.GetObject();
		Node.EnableDataExchange = EnableDataExchange;
		Node.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
EndProcedure

&AtServer
Procedure StartDateOfUploadingDocumentsOnChangeAtServer(Result = Undefined)
	
	If Result = "NotClear" Then
		DocumentsExportStartDate = Common.ObjectAttributeValue(StandaloneNode, "DocumentsExportStartDate");
	Else
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("ExchangePlan.Mobile");
			LockItem.SetValue("Ref", StandaloneNode);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Node = StandaloneNode.GetObject();
			Node.DocumentsExportStartDate = DocumentsExportStartDate;
			Node.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionDateOfStartOfUploadingDocuments(Result, Var_Parameters) Export
	StartDateOfUploadingDocumentsOnChangeAtServer(Result);
	Items.DocumentsExportStartDate.ToolTip = StrTemplate(NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng %1 mới được kết xuất vào chế độ ngoại tuyến.';
																|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна %1.';
																|en = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.'; fa = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																|it = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																|pl = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																|tr = 'Tek başına moda yalnızca tarihi %1''e eşit veya daha büyük olan belgeler aktarılacaktır'"), Format(DocumentsExportStartDate, NStr("vi = 'DLF = D';
																																																			|ru = 'ДЛФ=Д';
																																																			|en = 'DLF=D'; fa = 'DLF=D';
																																																			|it = 'DLF=D';
																																																			|pl = 'DLF=D';
																																																			|tr = 'DLF=D'")));
EndProcedure

&AtServer
Procedure GetAttributesOfOfflineNode(Code)
	
#If MobileStandaloneServer Then
	Items.StandaloneWorkplace.Visible = False;
#Else
	If Not ValueIsFilled(Code) Then
		Items.StandaloneWorkplace.Visible = False;
	ElsIf Not ExchangeMobilePCCall.OfflineModeIsAvailable() Then
		Items.StandaloneWorkplace.Visible = True;
		Items.DocumentsExportStartDate.Enabled = False;
		Items.EnableDataExchange.Enabled = False;
		Items.DocumentsExportStartDate.ToolTip = NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng ngày này mới được kết xuất vào chế độ ngoại tuyến.';
														|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна этой.';
														|en = 'Only documents with a date greater than or equal to this date will be exported to standalone mode.'; fa = 'فقط اسنادی با تاریخ بزرگ‌تر یا مساوی این تاریخ به حالت مستقل خارج خواهند شد.';
														|it = 'Only documents with a date greater than or equal to this date will be exported to standalone mode.';
														|pl = 'Only documents with a date greater than or equal to this date will be exported to standalone mode.';
														|tr = 'Tek başına moda yalnızca tarihi bu tarihe eşit veya daha büyük olan belgeler aktarılacaktır.'");
		Items.TitleWorkingOffline.ToolTip = NStr("vi = 'Để bật khả dụng cho tùy chọn, cần phải gán cho người dùng hiện tại vai trò ""Sử dụng chế độ ngoại tuyến"".';
												|ru = 'Чтобы включить доступность опции необходимо подключить текущему пользователю роль ""Использование автономного режима"".';
												|en = 'To enable the option, enable the ""Use offline mode"" role for the current user.'; fa = 'To enable the option, enable the ""Use offline mode"" role for the current user.';
												|it = 'To enable the option, enable the ""Use offline mode"" role for the current user.';
												|pl = 'To enable the option, enable the ""Use offline mode"" role for the current user.';
												|tr = 'Seçeneğin kullanılabilirliğini etkinleştirmek için mevcut kullanıcıya “Tek başına mod kullanımı” rolünü bağlamak gerekir.'");
	Else
		Items.StandaloneWorkplace.Visible = True;
		Items.DocumentsExportStartDate.Enabled = True;
		Items.EnableDataExchange.Enabled = True;
		
		StandaloneNode = ExchangePlans.Mobile.FindByCode(Code);
		OfflineNodeAttributes = Common.ObjectAttributesValues(StandaloneNode, "EnableDataExchange, DocumentsExportStartDate");
		EnableDataExchange = OfflineNodeAttributes.EnableDataExchange;
		
		If Not ValueIsFilled(OfflineNodeAttributes.DocumentsExportStartDate) Then
			DocumentsExportStartDate = BegOfDay(CurrentSessionDate());
			
			BeginTransaction();
			Try
				Block = New DataLock;
				LockItem = Block.Add("ExchangePlan.Mobile");
				LockItem.SetValue("Ref", StandaloneNode);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				Node = StandaloneNode.GetObject();
				Node.DocumentsExportStartDate = DocumentsExportStartDate;
				Node.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
			EndTry;
		Else
			DocumentsExportStartDate = OfflineNodeAttributes.DocumentsExportStartDate;
		EndIf;
		
		Items.DocumentsExportStartDate.ToolTip = StrTemplate(NStr("vi = 'Chỉ những chứng từ có ngày lớn hơn hoặc bằng %1 mới được kết xuất vào chế độ độc lập.';
																	|ru = 'В автономный режим будут выгружаться только те документы, дата которых больше или равна %1.';
																	|en = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.'; fa = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																	|it = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																	|pl = 'Only documents with a date greater than or equal to %1 will be exported to standalone mode.';
																	|tr = 'Tek başına moda yalnızca tarihi %1''e eşit veya daha büyük olan belgeler aktarılacaktır'"), Format(DocumentsExportStartDate, NStr("vi = 'DLF = D';
																																																				|ru = 'ДЛФ=Д';
																																																				|en = 'DLF=D'; fa = 'DLF=D';
																																																				|it = 'DLF=D';
																																																				|pl = 'DLF=D';
																																																				|tr = 'DLF=D'")));
		Items.TitleWorkingOffline.ToolTip = NStr("vi = 'Ứng dụng có khả năng làm việc ở chế độ ngoại tuyến. Khi có kết nối đến máy chủ chính, ứng dụng sẽ sao chép dữ liệu cần thiết vào cơ sở dữ liệu cục bộ, và sau khi mất kết nối, sẽ chuyển sang chế độ ngoại tuyến và tiếp tục làm việc với dữ liệu.';
												|ru = 'Приложение имеет возможность работать в автономном режиме. При наличии подключения к основному серверу приложение будет копировать необходимые данные в локальную базу, а после потери соединения переключится в автономный режим и продолжит работу с данными.';
												|en = 'The application can work offline. If you are connected to the main server, the application will copy the necessary data to the local infobase, and after losing the connection, it will switch to standalone mode and continue working with the data.'; fa = 'برنامه می‌تواند به‌صورت آفلاین کار کند. اگر به سرور اصلی متصل باشید، برنامه داده‌های لازم را در پایگاه اطلاعات محلی کپی می‌کند و پس از قطع اتصال، به حالت مستقل رفته و کار با داده‌ها را ادامه می‌دهد.';
												|it = 'The application can work offline. If you are connected to the main server, the application will copy the necessary data to the local infobase, and after losing the connection, it will switch to standalone mode and continue working with the data.';
												|pl = 'The application can work offline. If you are connected to the main server, the application will copy the necessary data to the local infobase, and after losing the connection, it will switch to standalone mode and continue working with the data.';
												|tr = 'Uygulama tek başına modda çalışabilme özelliğine sahiptir. Ana sunucuya bağlantı olduğunda gerekli verileri yerel veritabanına kopyalar, bağlantı kesildiğinde ise otonom moda geçer ve verilerle çalışmaya devam eder.'");
		Items.DocumentsExportStartDate.Enabled = Not EnableDataExchange;
		
	EndIf;
#EndIf

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_DocumentsExportStartDate" Then
		DocumentsExportStartDateOnChange(Items.DocumentsExportStartDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
