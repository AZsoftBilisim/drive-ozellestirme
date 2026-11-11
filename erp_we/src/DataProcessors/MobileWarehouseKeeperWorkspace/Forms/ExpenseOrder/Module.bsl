
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Ref = Parameters.Ref;
	
	If Not ValueIsFilled(Ref) Then
		Cancel = True;
		Return;
	EndIf;
	
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;

	LockDataForEdit(Ref,,UUID);
	
	FillForm();
	
	
#If Not MobileStandaloneServer Then
	User = Users.CurrentUser();
#Else
	User = MobileWarehouseKeeperWorkspace.CurrentUser();
#EndIf

	CheckOnlyYourNotes = DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders()
		And Not DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders(); 
	CheckOnlyOtherNotes = DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders()
		And Not DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders();
	CheckingAllOrders = DataProcessors.MobileWarehouseKeeperWorkspace.ThereIsRightToCheckOtherPeopleSOrders()
		And DataProcessors.MobileWarehouseKeeperWorkspace.HaveRightToCheckYourOrders();
	
	SetConditionalAppearance();
	
	If SpecifyingSeries Then
		ThereAreErrorsInSpecifyingBatches();
	EndIf;

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OpenMenuByStatus();
	GenerateMenuCommandHeaders();

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
		StandardProcessing = False;
		Cancel = True;
		CreateMenu_("ToShip");
	EndIf;
	
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
Procedure PremiseOnChange(Item)
	
	FillInAcceptanceArea();
	
EndProcedure

&AtClient
Procedure FilterGoodsOnChange(Item)
	
	GoodsFilterDisplayTable();
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products",   Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series",          Item.CurrentData.Series);
	FormParameters.Insert("Purpose",     Item.CurrentData.Purpose);
	FormParameters.Insert("Package",       Item.CurrentData.Package);
	FormParameters.Insert("Count",     Item.CurrentData.NumberOfPackages);
	FormParameters.Insert("LineNumber",    GoodsForPicking.IndexOf(Items.Goods.CurrentData));
	FormParameters.Insert("Warehouse",          Warehouse);
	FormParameters.Insert("Premise",      Premise);
	FormParameters.Insert("SKU",        Item.CurrentData.SKU);
	FormParameters.Insert("DocumentBarcode", Barcode);

	If IsFilter() Then
		FormParameters.Insert("Mode", "SelectionFromShipmentCell");
	ElsIf SpecifyingSeries Then
		FormParameters.Insert("Mode", ?(ValueIsFilled(Item.CurrentData.Series), 
			"EditingBatches", "SpecifyingSeries"));
	Else
		FormParameters.Insert("Mode", "View");
	EndIf;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile", FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsForInspection

&AtClient
Procedure ProductsForInspectionSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackagesReal);
	If ThisIsTest() Then
		FormParameters.Insert("Mode", ?(ValueIsFilled(Item.CurrentData.Series),
			"EditingRecalculationShipment", "EditingRecalculationShipmentWithoutBatch"));
	Else
		FormParameters.Insert("Mode", "View");
	EndIf;
	FormParameters.Insert("LineNumber", ProductsForInspection.IndexOf(Items.ProductsForInspection.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile", FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsForIssue

&AtClient
Procedure GoodsForIssueSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	If Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Shipped_") 
		And Not UseGoodsIssueNoteStatuses Then
		FormParameters.Insert("Mode", "EditShipment");
	Else
		FormParameters.Insert("Mode", "View"); 
	EndIf;
	FormParameters.Insert("LineNumber", GoodsForIssue.IndexOf(Items.GoodsForIssue.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile", FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToSelectionSection(Command)
	
	CreateMenu_("ForPicking");
	
EndProcedure

&AtClient
Procedure GoToVerificationSection(Command)
	
	CreateMenu_("ForChecking");
	
EndProcedure

&AtClient
Procedure GoToShippingSection(Command)
	
	CreateMenu_("ToShip");
	
EndProcedure

&AtClient
Procedure CompleteSelection_(Command)
	
	If HasFillingErrors() Then
		Return;
	EndIf;
	
	If ProductsForInspection.Count() = 0 Then
		Status(NStr("vi = 'Không thể hoàn tất việc lấy hàng, khi chưa chọn được mặt hàng nào.';
					|ru = 'Не возможно закончить отбор, пока не отобрано ни одного товара.';
					|en = 'Cannot finish picking until at least one item is selected.'; fa = 'Cannot finish picking until at least one item is selected.';
					|it = 'Cannot finish picking until at least one item is selected.';
					|pl = 'Cannot finish picking until at least one item is selected.';
					|tr = 'Toplama, hiçbir ürün toplanmış olmadığı için kapatılamaz.'"));
		Return;
	EndIf;
	
	ValueList = New ValueList;
	
	If CheckOnlyYourNotes Or CheckingAllOrders Then
		
		ValueList.Add("Validate", NStr("vi = 'Chuyển đến kiểm tra phiếu';
										|ru = 'Перейти к проверке ордера';
										|en = 'Proceed to checking the note'; fa = 'Proceed to checking the note';
										|it = 'Proceed to checking the note';
										|pl = 'Proceed to checking the note';
										|tr = 'Sipariş kontrolüne git'"));
		ValueList.Add("ExitApp", NStr("vi = 'Kết thúc làm việc với phiếu';
										|ru = 'Завершить работу с ордером';
										|en = 'Close the note'; fa = 'Close the note';
										|it = 'Close the note';
										|pl = 'Close the note';
										|tr = 'Siparişle çalışmayı tamamla'"));
		ValueList.Add("Continue", NStr("vi = 'Tiếp tục lấy hàng';
										|ru = 'Продолжить отбор';
										|en = 'Continue picking'; fa = 'ادامه برداشت';
										|it = 'Continue picking';
										|pl = 'Continue picking';
										|tr = 'Filtrelemeye devam et'")); 
		If GoodsForPicking.Count() > 0 Then
			MessageText = NStr("vi = 'Các mặt hàng còn lại trên thẻ ""Cần lấy ra"" sẽ chưa được giao.
			|Sau khi hoàn tất quá trình lấy hàng, bạn muốn chuyển sang bước kiểm tra phiếu hay kết thúc làm việc với phiếu hiện tại?';
			|ru = 'Товары, оставшиеся на вкладке ""К отбору"" не будут отгружены.
			|После завершения отбора перейти к проверке ордера или завершить работу с текущим ордером?';
			|en = 'The goods left on the ""Pick list"" tab will not be shipped.
			|After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?'; fa = 'The goods left on the ""Pick list"" tab will not be shipped.
			|After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
			|it = 'The goods left on the ""Pick list"" tab will not be shipped.
			|After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
			|pl = 'The goods left on the ""Pick list"" tab will not be shipped.
			|After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
			|tr = '""Toplamaya hazır"" sekmesinde kalan ürünler sevk edilmeyecektir.
			|Toplama tamamlandıktan sonra sipariş doğrulamaya devam edilsin veya mevcut sipariş tamamlansın mı?'");
		Else  
			MessageText = NStr("vi = 'Sau khi kết thúc lấy hàng, cần chuyển đến kiểm tra phiếu hay kết thúc công việc với phiếu hiện tại?';
								|ru = 'После завершения отбора перейти к проверке ордера или завершить работу с текущим ордером?';
								|en = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?'; fa = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
								|it = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
								|pl = 'After picking is completed, do you want to proceed to checking the goods issue or close the current goods issue?';
								|tr = 'Filtreyi tamamladıktan sonra sipariş doğrulamaya devam etmek veya mevcut siparişle çalışmayı bitirmek istiyor musunuz?'");
		EndIf;
		
	Else
		
		ValueList.Add("ExitApp", NStr("vi = 'Kết thúc';
										|ru = 'Завершить';
										|en = 'Exit'; fa = 'خروج';
										|it = 'Completare';
										|pl = 'Zakończ';
										|tr = 'Tamamla'"));
		ValueList.Add("Continue", NStr("vi = 'Tiếp tục';
										|ru = 'Продолжить';
										|en = 'Continue'; fa = 'ادامه';
										|it = 'Continuare';
										|pl = 'Kontynuuj';
										|tr = 'Devam et'"));
		If GoodsForPicking.Count() > 0 Then
			MessageText = NStr("vi = 'Các mặt hàng còn lại trên thẻ ""Cần lấy ra"" sẽ chưa được giao. Kết thúc lấy hàng?';
								|ru = 'Товары, оставшиеся на вкладке ""К отбору"" не будут отгружены. Завершить отбор?';
								|en = 'The goods left on the ""Pick list"" tab will not be shipped. Finish picking?'; fa = 'The goods left on the ""Pick list"" tab will not be shipped. Finish picking?';
								|it = 'The goods left on the ""Pick list"" tab will not be shipped. Finish picking?';
								|pl = 'The goods left on the ""Pick list"" tab will not be shipped. Finish picking?';
								|tr = '""Toplamaya hazır"" sekmesinde kalan ürünler sevk edilmeyecektir. Toplama tamamlansın mı?'");
		Else  
			MessageText = NStr("vi = 'Kết thúc lấy ra?';
								|ru = 'Завершить отбор?';
								|en = 'Finish picking job?'; fa = 'Finish picking job?';
								|it = 'Terminare la selezione?';
								|pl = 'Zakończyć wybór?';
								|tr = 'Filtre tamamlansın mı?'");
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure("ProcessName", "CompleteSelection_");
	Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, MessageText, ValueList, 0); 

EndProcedure

&AtClient
Procedure FinishCheck(Command)
	
	If HasFillingErrors() Then
		Return;
	EndIf;  
	
	CheckResult = ThereIsShortageSurplusBatchError();
	
	If CheckResult.BatchError Then
		Status(ErrorText);
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AfterClosingVerificationIssue", ThisObject);

	ValueList = New ValueList();
	
	If CheckResult.Shortage Then 
		
		ValueList.Add("Pick", NStr("vi = 'Thêm hàng hóa';
									|ru = 'Добрать товар';
									|en = 'Add goods'; fa = 'افزودن کالاها';
									|it = 'Add goods';
									|pl = 'Add goods';
									|tr = 'Ürün ekle'"));
		ValueList.Add("Ship", NStr("vi = 'Giảm số lượng trong phiếu';
									|ru = 'Уменьшить количество в ордере';
									|en = 'Reduce quantity in the note'; fa = 'کاهش مقدار در حواله';
									|it = 'Diminuire la quantità nel mandato';
									|pl = 'Zmniejsz ilość w zleceniu';
									|tr = 'Sipariş miktarını azalt'"));
		ValueList.Add("ShipWithoutVerification", NStr("vi = 'Kết thúc mà không kiểm tra';
														|ru = 'Завершить без проверки';
														|en = 'Complete without check'; fa = 'تکمیل بدون بررسی';
														|it = 'Complete without check';
														|pl = 'Complete without check';
														|tr = 'Kontrol etmeden tamamla'"));
		ValueList.Add("Continue", NStr("vi = 'Tiếp tục kiểm tra';
										|ru = 'Продолжить проверку';
										|en = 'Continue checking'; fa = 'ادامه بررسی';
										|it = 'Continuare la verifica';
										|pl = 'Kontynuuj weryfikację';
										|tr = 'Kontrolü devam et'")); 
		If CheckResult.Surplus Then
			MessageText = NStr("vi = 'Hàng hóa đã kiểm tra nhiều hơn hàng hóa cần giao trong phiếu. Cần để lại hàng hóa tại khu vực giao hàng.
			|Không phải tất cả mặt hàng đã chọn đều được tìm thấy hoặc kiểm tra.';
			|ru = 'Проверенного товара больше, чем требуется отгрузить в ордере. Товар необходимо оставить в зоне отгрузки.
			|Не все из отобранных товаров найдены или проверены.';
			|en = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
			|Not all the picked goods are found or checked.'; fa = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
			|Not all the picked goods are found or checked.';
			|it = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
			|Not all the picked goods are found or checked.';
			|pl = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
			|Not all the picked goods are found or checked.';
			|tr = 'Siparişte, sevkiyat için gerekenden daha fazla denetlenen ürün bulunmaktadır. Ürünlerin yükleme alanında bırakılması gerekmektedir.
			|Seçilen ürünlerin tamamı bulunamadı veya denetlenmedi.'");
		Else
			MessageText = NStr("vi = 'Không phải tất cả mặt hàng đã chọn đều được tìm thấy hoặc kiểm tra.';
								|ru = 'Не все из отобранных товаров найдены или проверены.';
								|en = 'Not all the picked goods are found or checked.'; fa = 'همه کالاهای برداشت‌شده یافت یا بررسی نشده‌اند.';
								|it = 'Not all the picked goods are found or checked.';
								|pl = 'Not all the picked goods are found or checked.';
								|tr = 'Seçilen ürünlerin tamamı bulunamadı veya kontrol edilemedi.'");
		EndIf;
		
		ShowQueryBox(Notification, MessageText, ValueList, 0);
		
	ElsIf CheckResult.Surplus Then   
		
		ValueList.Add("SurplusToShip", NStr("vi = 'Chuyển đến giao hàng';
											|ru = 'Перейти к отгрузке';
											|en = 'Go to shipment'; fa = 'Go to shipment';
											|it = 'Go to shipment';
											|pl = 'Go to shipment';
											|tr = 'Sevkiyata git'"));
		ValueList.Add("SurplusComplete", NStr("vi = 'Kết thúc làm việc với phiếu';
												|ru = 'Завершить работу с ордером';
												|en = 'Close the note'; fa = 'Close the note';
												|it = 'Close the note';
												|pl = 'Close the note';
												|tr = 'Siparişle çalışmayı tamamla'"));
		ValueList.Add("Continue", NStr("vi = 'Tiếp tục kiểm tra';
										|ru = 'Продолжить проверку';
										|en = 'Continue checking'; fa = 'ادامه بررسی';
										|it = 'Continuare la verifica';
										|pl = 'Kontynuuj weryfikację';
										|tr = 'Kontrolü devam et'"));
		MessageText = NStr("vi = 'Hàng hóa đã kiểm tra nhiều hơn hàng hóa cần giao trong phiếu. Cần để lại hàng hóa tại khu vực giao hàng. 
		|
		|Sau khi kết thúc kiểm tra, bạn muốn chuyển đến giao hàng trong phiếu hay kết thúc làm việc với phiếu hiện tại?';
		|ru = 'Проверенного товара больше, чем требуется отгрузить в ордере. Товар необходимо оставить в зоне отгрузки. 
		|
		|После завершения проверки перейти к отгрузке ордера или завершить работу с текущим ордером?';
		|en = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
		|
		|After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?'; fa = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
		|
		|After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?';
		|it = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
		|
		|After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?';
		|pl = 'More goods are checked than required to be shipped under the goods issue. Leave the goods in the outbound area.
		|
		|After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?';
		|tr = 'Siparişte sevkiyat için gerekenden fazla kontrol edilen ürün var. Ürünlerin yükleme alanında bırakılması gerekiyor. 
		|
		|Kontrol tamamlandıktan sonra sipariş sevkiyatına devam edilsin ya da mevcut siparişle çalışma sonlandırılsın mı?'");

		ShowQueryBox(Notification, MessageText, ValueList, 0); 
		
	Else
		AfterClosingVerificationIssue("Ship"); 
	EndIf;
		
EndProcedure 

&AtClient
Procedure FinishShipment(Command)
	
	If HasFillingErrors() Then
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Kết thúc xuất hàng?';
						|ru = 'Завершить отгрузку?';
						|en = 'Finish shipment?'; fa = 'Finish shipment?';
						|it = 'Terminare la spedizione?';
						|pl = 'Zakończyć wysyłkę?';
						|tr = 'Sevkiyatı tamamla?'"); 
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Kết thúc';
									|ru = 'Завершить';
									|en = 'Exit'; fa = 'خروج';
									|it = 'Completare';
									|pl = 'Zakończ';
									|tr = 'Tamamla'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Kontynuuj';
									|tr = 'Devam et'"));
	
	AdditionalParameters = New Structure("ProcessName", "CompleteShipment");
	Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, MessageText, ValueList, 0); 
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType",         "ProductItemsSearch");
	FormParameters.Insert("Warehouse",             Warehouse);
	FormParameters.Insert("Premise",         Premise);
	FormParameters.Insert("DocumentRef",    Ref);
	FormParameters.Insert("PackageBarcodes", PackageBarcodes);
	FormParameters.Insert("Organization",       Organization);
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
			ThisObject,,,, LongDesc,
			FormWindowOpeningMode.Independent);
	Else
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode", FormParameters,
			ThisObject,,,, LongDesc,
			FormWindowOpeningMode.Independent);
	EndIf;

EndProcedure

&AtClient
Procedure MarkingCodes(Command)
	
	LongDesc = New CallbackDescription("ChangePackageBarcodes", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("PackageBarcodes", PackageBarcodes);
	
	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.MarkingCodeList",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure CancelOrderShipment(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Đặt dấu xóa phiếu';
									|ru = 'Пометить ордер на удаление';
									|en = 'Mark the note for deletion'; fa = 'Mark the note for deletion';
									|it = 'Mark the note for deletion';
									|pl = 'Mark the note for deletion';
									|tr = 'Silme emrini işaretle'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục giao hàng';
									|ru = 'Продолжить отгрузку';
									|en = 'Continue the shipment'; fa = 'Continue the shipment';
									|it = 'Продолжить отгрузку';
									|pl = 'Continue the shipment';
									|tr = 'Sevkiyatı devam ettir'"));
	
	Notification = New CallbackDescription("AfterClosingIssueCancelShipment", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Để hủy giao hàng, cần đặt dấu xóa phiếu xuất kho. Sau đó sẽ không thể quay lại chỉnh sửa. Bạn có muốn đặt dấu xóa không?';
									|ru = 'Для отмены отгрузки необходимо пометить на удаление расходный ордер. Вернуться к редактированию будет невозможно. Пометить на удаление?';
									|en = 'To cancel shipment, mark the goods issue document for deletion. It will be impossible to get back to editing. Mark the document for deletion?'; fa = 'To cancel shipment, mark the goods issue document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|it = 'To cancel shipment, mark the goods issue document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|pl = 'To cancel shipment, mark the goods issue document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|tr = 'Sevkiyatı geri almak için, ambar çıkışını silinmek üzere işaretlemeniz gerekir. Düzenleme yapılamaz. Silinmek üzere işaretlensin mi?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure Information(Command)
	
	Items.GroupPages.CurrentPage = Items["InformationPage"];
	HideMenu();
	
EndProcedure

&AtClient
Procedure ReturnToSelectionDoNotShip(Command)
	
	RowIndex = GoodsDoNotShip.IndexOf(Items.GoodsDoNotShip.CurrentData);
	ReturnDoNotShipAtServer(RowIndex, "GoodsForPicking");
	GenerateMenuCommandHeaders();

EndProcedure

&AtClient
Procedure ReturnToBeShippedDoNotShip(Command)
	
	RowIndex = GoodsDoNotShip.IndexOf(Items.GoodsDoNotShip.CurrentData);
	ReturnDoNotShipAtServer(RowIndex, "GoodsForIssue");
	GenerateMenuCommandHeaders();

EndProcedure

&AtClient
Procedure ReturnToSelectionCheck(Command)
	
	RowIndex = ProductsForInspection.IndexOf(Items.ProductsForInspection.CurrentData);
	BackToSelectionCheckingAtServer(RowIndex);
	GenerateMenuCommandHeaders();

EndProcedure  

 &AtClient
Procedure AssignMe(Command) 
	
	AssignMeAtServer();
	OpenMenuByStatus();

EndProcedure
 
&AtClient
Procedure DoNotShipToSelection(Command)
	
	RowIndex = GoodsForPicking.IndexOf(Items.Goods.CurrentData);
	DoNotShipAtServer(RowIndex, "GoodsForPicking");
	GenerateMenuCommandHeaders();

EndProcedure 

&AtClient
Procedure DoNotShipToBeShipped(Command)
		
	RowIndex = GoodsForIssue.IndexOf(Items.GoodsForIssue.CurrentData);
	DoNotShipAtServer(RowIndex, "GoodsForIssue");
	GenerateMenuCommandHeaders();

EndProcedure

&AtClient
Procedure IndicationOfSeriesIsReady(Command)
	
	If HasFillingErrors() Then
		Return;
	EndIf;
	
	If ThereAreErrorsInSpecifyingBatches() Then
		Return;
	EndIf;
	
	ValueList = New ValueList;
	Notification = New CallbackDescription("AfterClosingQuestionSpecifyingBatches", ThisObject);
		
	ValueList.Add("Pick", NStr("vi = 'Chuyển đến lấy hàng';
								|ru = 'Перейти к отбору';
								|en = 'Go to filter'; fa = 'رفتن به فیلتر';
								|it = 'Passa a selezione';
								|pl = 'Przejdź do filtru';
								|tr = 'Filtreye git'"));
	ValueList.Add("SelectComplete", NStr("vi = 'Kết thúc làm việc với phiếu';
										|ru = 'Завершить работу с ордером';
										|en = 'Close the note'; fa = 'Close the note';
										|it = 'Close the note';
										|pl = 'Close the note';
										|tr = 'Siparişle çalışmayı tamamla'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục chỉ định sê-ri';
									|ru = 'Продолжить указание серий';
									|en = 'Continue specifying batches'; fa = 'Continue specifying batches';
									|it = 'Continue specifying batches';
									|pl = 'Continue specifying batches';
									|tr = 'Parti belirtmeye devam et'"));
	MessageText = NStr("vi = 'Sau khi kết thúc chỉ định sê-ri, bạn muốn chuyển đến lấy hàng trong phiếu hay kết thúc làm việc với phiếu hiện tại?';
						|ru = 'После завершения указания серий перейти к отбору ордера или завершить работу с текущим ордером?';
						|en = 'After the batches are specified, do you want to proceed to picking the goods issue or close the current goods issue?'; fa = 'After the batches are specified, do you want to proceed to picking the goods issue or close the current goods issue?';
						|it = 'After the batches are specified, do you want to proceed to picking the goods issue or close the current goods issue?';
						|pl = 'After the batches are specified, do you want to proceed to picking the goods issue or close the current goods issue?';
						|tr = 'Parti belirtildikten sonra sipariş filtrelemeye devam etmek veya mevcut siparişle çalışmayı bitirmek istiyor musunuz?'");
		
	ShowQueryBox(Notification, MessageText, ValueList, 0);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	If UseBinLocationWarehousing Then
		Items.MenuGroupToCheck.Visible = True;
	Else
		Items.ShippingZone.Visible      = False;
		Items.MenuGroupToCheck.Visible       = False;
	EndIf;
	
	Items.Premise.Visible = UseWarerooms;
	Items.MarkingCodes.Visible = UseAccountingOfLabeledProducts And ThereAreLabeledProducts;
	Items.InformationAboutRecipient.Visible = (TypeOf(Recipient) = Type("CatalogRef.Partners") Or TypeOf(Recipient) = Type("CatalogRef.Persons"));
	
#If MobileStandaloneServer Then
	Items.FormCancelOrderShipment.Visible = False;
#Else
	If Status = Enums.GoodsIssueNoteStatuses.ForPicking
	And (Constants.GoodsIssueNoteGenerationMode.Get() =
	Enums.GoodsIssueNoteGenerationModes.ByWarehouseman) Then
		Items.FormCancelOrderShipment.Visible = True;
	Else
		Items.FormCancelOrderShipment.Visible = False;
	EndIf;
#EndIf
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsForInspectionNumberOfPackagesIsDifference.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsForInspection.NumberOfPackagesIsDifference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue);
		
	Items.MenuGroupForSelection.Visible = UseGoodsIssueNoteStatuses;
	Items.MenuGroupToCheck.Visible = UseGoodsIssueNoteStatuses;

	Items.GoodsMainCell.Visible = UseBinLocationWarehousingForInformation;
	
	Items.Inspector.Visible = UseGoodsIssueNoteStatuses;
	Items.ShippedBy.Visible = UseGoodsIssueNoteStatuses;
	
	Items.DoNotShipToBeShipped.Visible = Not UseGoodsIssueNoteStatuses;
	Items.ReturnToBeShippedDoNotShip.Visible = Not UseGoodsIssueNoteStatuses;

	Items.DoNotShipToSelection.Visible = Not UseBinLocationWarehousing And UseGoodsIssueNoteStatuses; 
	IsFilter = Not UseBinLocationWarehousing And Status = Enums.GoodsIssueNoteStatuses.ForPicking;
	Items.ReturnToSelectionDoNotShip.Visible = IsFilter And UseGoodsIssueNoteStatuses;
	
	Items.ReturnToSelectionCheck.Visible = IsFilter;
	
	Items.GroupSwitchDoNotShip.Visible = GoodsDoNotShip.Count();
	FilterGoods = "Shipped_1";
	
	SetAvailabilityOfOrderEditing();
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)

	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1);

	If Not BarcodesAreValid Then
		Return;
	EndIf;

	If Barcode = BarcodeData_1.Barcode Then
		If Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking")
			And UseBinLocationWarehousing Then

			TasksForSelection = OrderTaskData();
			DocumentScanResult(TasksForSelection);

		Else
			FinishWarehouseOperation();
		EndIf;
		Return;
	EndIf;

	ProductData_9 = ItemDataBySchool(BarcodeData_1.Barcode);

	If ValueIsFilled(ProductData_9) Then
		ResultOfScanningItem(ProductData_9);
		Return;
	EndIf;

	Status(NStr("vi = 'Không tìm thấy mặt hàng theo mã vạch';
				|ru = 'Номенклатура по штрихкоду не найдена';
				|en = 'Item is not found by barcode'; fa = 'Item is not found by barcode';
				|it = 'Item is not found by barcode';
				|pl = 'Item is not found by barcode';
				|tr = 'Barkod ile öğe bulunamadı'"));

EndProcedure

&AtServer
Function OrderTaskData()

	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Ref", Ref);
	TheStructureOfTheSearch.Insert("Direction", "Shipment");

	Return DataProcessors.MobileWarehouseKeeperWorkspace.OrderTaskData(TheStructureOfTheSearch);

EndFunction

&AtClient
Procedure DocumentScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.References.Count() > 1 Then

		LongDesc = New CallbackDescription("DocumentScanResult", ThisObject);

		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", Result);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);

		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,, LongDesc, FormWindowOpeningMode.LockWholeInterface);

	ElsIf Result.References.Count() = 1 Then

		FormParameters = New Structure;
		If TypeOf(Result.References[0]) = Type("Structure") Then
			References = Result.References[0].Ref;
		Else
			References = Result.References[0];
		EndIf;

		Close();

		FormParameters.Insert("Ref", References);
		FormParameters.Insert("Performer", Performer);
		FormParameters.Insert("Seamless", True);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm("DataProcessor.MobileWarehouseKeeperWorkspace.Form.Filter", FormParameters,
			ThisObject,,,,, FormWindowOpeningMode.Independent);

	Else

		CreateNewSelectionOfItems();

	EndIf;

EndProcedure

&AtClient
Procedure FinishWarehouseOperation()

	If Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking") Then

		If HasFillingErrors() Then
			Return;
		EndIf;

		If ProductsForInspection.Count() = 0 Then
			ErrorText = NStr("vi = 'Không thể hoàn tất việc lấy hàng, khi chưa chọn được mặt hàng nào.';
							|ru = 'Не возможно закончить отбор, пока не отобрано ни одного товара.';
							|en = 'Cannot finish picking until at least one item is selected.'; fa = 'Cannot finish picking until at least one item is selected.';
							|it = 'Cannot finish picking until at least one item is selected.';
							|pl = 'Cannot finish picking until at least one item is selected.';
							|tr = 'Toplama, hiçbir ürün toplanmış olmadığı için kapatılamaz.'");
			Status(ErrorText);
			Return;
		EndIf;

		FilterCompleted = FinishSelectionOnServer("ExitApp");
		If FilterCompleted Then
			FillOutFormAgain();
			OpenMenuByStatus();
		Else
			Status(ErrorText);
		EndIf;

	ElsIf Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.DuringChecking") Then

		If Not ThisIsTest() Then
			Status(NStr("vi = 'Không đủ quyền để kiểm tra việc xuất hàng.';
						|ru = 'Недостаточно прав на проверку отгрузки.';
						|en = 'Insufficient rights to check the shipment.'; fa = 'Insufficient rights to check the shipment.';
						|it = 'Insufficient rights to check the shipment.';
						|pl = 'Insufficient rights to check the shipment.';
						|tr = 'Sevkiyat kontrolü için için erişim yetkisi yetersiz.'"));
			Return;
		EndIf;

		If HasFillingErrors() Then
			Return;
		EndIf;

		CheckResult = ThereIsShortageSurplusBatchError();

		If CheckResult.BatchError Then
			Status(ErrorText);
			Return;
		EndIf;

		If CheckResult.Shortage Then

			LongDesc = New CallbackDescription("AfterClosingQuestionForm", ThisObject);
			FormParameters = New Structure("Mode", "Validation");

			OpenForm(
				"DataProcessor.MobileWarehouseKeeperWorkspace.Form.QuestionFormScanning", FormParameters,
				ThisObject,,,, LongDesc, FormWindowOpeningMode.LockWholeInterface);

		Else
			CheckIsCompleted = FinishCheckingOnServer("ShipComplete");
			If CheckIsCompleted Then
				FillOutFormAgain();
				OpenMenuByStatus();
			Else
				Status(ErrorText);
			EndIf;
		EndIf;

	ElsIf Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip") Then

		ShipmentCompleted = FinishShipmentOnServer();

		If ShipmentCompleted Then
			Close();
		Else
			Status(ErrorText);
		EndIf;

	ElsIf Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForChecking") Then

		AssignMeAtServer(True);
		OpenMenuByStatus();
		If ValueIsFilled(ErrorText) Then
			Status(ErrorText);
		EndIf;

	Else
		AssignMeAtServer();
		OpenMenuByStatus();
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

		LongDesc = New CallbackDescription("UpdateForm", ThisObject);

		FormParameters = New Structure;
		FormParameters.Insert("Products", ProductData_8.Products);
		FormParameters.Insert("Characteristic", ProductData_8.Characteristic);
		FormParameters.Insert("Series", ProductData_8.Series);
		FormParameters.Insert("Package", ProductData_8.Package);
		FormParameters.Insert("Count", ProductData_8.Count);
		If IsFilter() Then
			FormParameters.Insert("Mode", "SelectionFromShipmentCell");
		ElsIf ThisIsTest() Then
			FormParameters.Insert("Mode", "RecalculationShipment");
		ElsIf SpecifyingSeries Then
			FormParameters.Insert("Mode", "SpecifyingSeries");
		ElsIf Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Shipped_")
			And Not UseGoodsIssueNoteStatuses Then
			FormParameters.Insert("Mode", "Shipment");
		Else
			FormParameters.Insert("Mode", "View");
		EndIf;
		FormParameters.Insert("LineNumber", 0);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("PackageBarcode", ProductData_8.PackageBarcode);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Source", Ref);
		FormParameters.Insert("DocumentBarcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
			ThisObject,,,,LongDesc,
			FormWindowOpeningMode.Independent);

	EndIf;

EndProcedure

&AtClient
Procedure CreateMenu_(TabName)
	
	ShowMenu();
	
	Items.FrameForShipment.Picture = PictureLib.BorderMenuWhite;
	Items.CommandToShip.TextColor = WebColors.DarkGray;
	
	Items.FrameForSelection.Picture = PictureLib.BorderMenuWhite;
	Items.SelectionCommand.TextColor = WebColors.DarkGray;
	
	Items.FrameForInspection.Picture = PictureLib.BorderMenuWhite;
	Items.CommandToCheck.TextColor = WebColors.DarkGray;
	
	If TabName = "ForPicking" Then 
		Items.SelectionCommand.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PageToSelect;
		Items.FrameForSelection.Picture     = PictureLib.BorderMenuBlack;
		Items.CompleteSelection_.Visible = IsFilter();
		Items.FinishCheck.Visible = False;
		
		If GoodsDoNotShip.Count() Then
			ShippedItem = Items.FilterGoods.ChoiceList.FindByValue("Shipped_1");
			ShippedItem.Presentation = NStr("vi = 'Cần lấy ra';
											|ru = 'К отбору';
											|en = 'Pick list'; fa = 'فهرست برداشت';
											|it = 'Da selezionare';
											|pl = 'Do filtru';
											|tr = 'Toplamaya hazır'");
		EndIf;
		
	ElsIf TabName = "ForChecking" Then  
		Items.CommandToCheck.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PageToCheck;
		Items.FrameForInspection.Picture     = PictureLib.BorderMenuBlack;
		Items.FinishCheck.Visible = ThisIsTest();
		Items.CompleteSelection_.Visible = False;
		UpdateTestPrompt();
		
		If GoodsDoNotShip.Count() Then
			ShippedItem = Items.FilterGoods.ChoiceList.FindByValue("Shipped_1");
			ShippedItem.Presentation = NStr("vi = 'Cần kiểm tra';
											|ru = 'К проверке';
											|en = 'To verify'; fa = 'برای تأیید';
											|it = 'Da verificare';
											|pl = 'Do sprawdzenia';
											|tr = 'Kontrol edilecek'");
		EndIf;

		If ThisIsTest() And UsedFormServer = UsedServer.Standalone Then
			Items.WarningGroup.Visible = True;
		EndIf;

	ElsIf TabName = "ToShip" Then
		Items.CommandToShip.TextColor = WebColors.Black;
		Items.GroupPages.CurrentPage = Items.PageForShipment;
		Items.FrameForShipment.Picture     = PictureLib.BorderMenuBlack;
		Items.CompleteShipment.Visible = 
		Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip")
		Or (Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Shipped_")
		And Not UseGoodsIssueNoteStatuses);
		Items.FinishCheck.Visible = False;
		Items.CompleteSelection_.Visible = False;

		If GoodsDoNotShip.Count() Then
			ShippedItem = Items.FilterGoods.ChoiceList.FindByValue("Shipped_1");
			ShippedItem.Presentation = NStr("vi = 'Cần giao hàng';
											|ru = 'К отгрузке';
											|en = 'To ship'; fa = 'برای ارسال';
											|it = 'Da spedire';
											|pl = 'Do wysłania';
											|tr = 'Sevk edilecek'");
		EndIf;

	EndIf;
	
	If FilterGoods = "Unshipped" Then
		Items.GroupPages.CurrentPage = Items.DonTShipPage;
	EndIf;
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Function IsFilter()
	
	Return Not UseBinLocationWarehousing And Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking");
	
EndFunction
		
&AtClient
Function ThisIsTest()

	CheckingYourOrder = CheckOnlyYourNotes And Performer = User;
	CheckingSomeoneElseSOrder = CheckOnlyOtherNotes And Performer <> User;
	
	Return ((CheckingYourOrder Or CheckingSomeoneElseSOrder Or CheckingAllOrders)
		And Status =  PredefinedValue("Enum.GoodsIssueNoteStatuses.DuringChecking"));
	
EndFunction

&AtClient
Procedure GenerateMenuCommandHeaders()
	
	Items.SelectionCommand.Title = StrTemplate(NStr("vi = 'Cần lấy hàng %1';
													|ru = 'К отбору %1';
													|en = 'To pick %1'; fa = 'To pick %1';
													|it = 'To pick %1';
													|pl = 'To pick %1';
													|tr = 'Toplamaya hazır %1'"), GoodsForPicking.Count()); 
	Items.CommandToCheck.Title = StrTemplate(NStr("vi = 'Cần kiểm tra %1';
													|ru = 'К проверке %1';
													|en = 'To check %1'; fa = 'To check %1';
													|it = 'To check %1';
													|pl = 'To check %1';
													|tr = '%1 kontrolüne git'"), ProductsForInspection.Count());
	Items.CommandToShip.Title = StrTemplate(NStr("vi = 'Cần giao hàng %1';
												|ru = 'К отгрузке %1';
												|en = 'To ship %1'; fa = 'To ship %1';
												|it = 'To ship %1';
												|pl = 'To ship %1';
												|tr = '%1 sevkiyatına git'"), GoodsForIssue.Count());
	
	If GoodsDoNotShip.Count() Then 
		Items.GroupSwitchDoNotShip.Visible = True;
		ItemIsNotBeingShipped = Items.FilterGoods.ChoiceList.FindByValue("Unshipped");
		ItemIsNotBeingShipped.Presentation = StrTemplate(NStr("vi = 'Không giao hàng %1';
																|ru = 'Не отгружать %1';
																|en = 'Do not ship %1'; fa = 'Do not ship %1';
																|it = 'Do not ship %1';
																|pl = 'Do not ship %1';
																|tr = '%1 sevk etme'"), GoodsDoNotShip.Count());
	Else
		Items.GroupSwitchDoNotShip.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure UpdateTestPrompt()
	
	Plan = ProductsForInspection.Total("NumberOfPackages");
	Real = ProductsForInspection.Total("NumberOfPackagesReal");
	Difference = Plan - Real;
	
	Items.TitleHintFact.Title = Real;
	Items.TitleHintPlan.Title = Plan;
	Items.TitleHintDifference.Title = Difference;
	
EndProcedure

&AtServer
Procedure FillForm()
	
	GoodsForPicking.Clear();
	ProductsForInspection.Clear();
	GoodsForIssue.Clear();
	GoodsDoNotShip.Clear();
	
	DataStructure = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(Ref, "Status, Warehouse, Premise, DateOfShipment");
	
	WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(DataStructure.Warehouse);
	If ValueIsFilled(WarehouseProperties) Then
		UseBinLocationWarehousing            = WarehouseProperties.UseBinLocationWarehousing;
		UseWarerooms          = WarehouseProperties.UseWarerooms;
		UseGoodsIssueNoteStatuses		= WarehouseProperties.UseGoodsIssueNoteStatuses;
	EndIf;
	If UseWarerooms Then
		StructureOfRoom = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(DataStructure.Premise,
			"UseBinLocationWarehousing, UseBinLocationWarehousingForInformation");
		UseBinLocationWarehousing = StructureOfRoom.UseBinLocationWarehousing;
		UseBinLocationWarehousingForInformation = StructureOfRoom.UseBinLocationWarehousingForInformation;
		StartDateOfWareroomUse = WarehouseProperties.StartDateOfWareroomUse;
	EndIf; 
	
	Query = New Query;
	Query.Text = QueryTextGoodsTableDocumentData();
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("UseBinLocationWarehousing", UseBinLocationWarehousing);
	Query.SetParameter("Warehouse", DataStructure.Warehouse);

	If UseBinLocationWarehousingForInformation Then 
		StartDateOfWareroomUse = WarehouseProperties.StartDateOfWareroomUse;
		DateOfShipment = DataStructure.DateOfShipment;
		Query.SetParameter("UseWarerooms", UseWarerooms);
		Query.SetParameter("DateOfShipment", DateOfShipment);
		Query.SetParameter("StartDateOfWareroomUse", StartDateOfWareroomUse);
		Query.SetParameter("Premise", DataStructure.Premise);
	EndIf;
	
	StatusInVerification = (DataStructure.Status = Enums.GoodsIssueNoteStatuses.ForChecking
		Or DataStructure.Status = Enums.GoodsIssueNoteStatuses.DuringChecking); 
		
	Query.SetParameter("ThisIsTest", StatusInVerification);
	
	QueryResult = Query.ExecuteBatch();
	
	SelectionDetailRecords = QueryResult[0].Select();
	SelectionDetailRecords.Next();
	
	FillPropertyValues(ThisObject, SelectionDetailRecords);
	GoodsByReferences.Load(SelectionDetailRecords.TableOfItemsByOrder.Unload());
	
	SampleTableToBeShipped = QueryResult[2].Unload();
	SamplingTableDoNotShip = QueryResult[3].Unload();
			
	If Status = Enums.GoodsIssueNoteStatuses.Prepared 
		Or Status = Enums.GoodsIssueNoteStatuses.ForPicking Then
		SpecifyingSeries = DataProcessors.MobileWarehouseKeeperWorkspace.CheckStatusOfBatchIndicationWhenPlanningSelection(Ref, 
			Warehouse);
	EndIf; 
		
	If UseBinLocationWarehousing Then 
		
#If Not MobileStandaloneServer Then
		PackageBarcodes.Load(SelectionDetailRecords.SpendingOrderBarcodesOfPackages.Unload());
#EndIf

		If StatusInVerification Or Status = Enums.GoodsIssueNoteStatuses.ForPicking Then 			
			ProductsForInspection.Load(QueryResult[12].Unload());			
		EndIf;
		
		If SpecifyingSeries Then 
			SelectionTableSelect = QueryResult[4].Unload();
			GoodsForPicking.Load(SelectionTableSelect);
		Else 
			SelectionTableBalancesForSelection = QueryResult[7].Unload();
			GoodsForPicking.Load(SelectionTableBalancesForSelection);
		EndIf;
		
		GoodsForIssue.Load(SampleTableToBeShipped);
		GoodsDoNotShip.Load(SamplingTableDoNotShip);
			
	Else
		
		SelectionTableSelect = QueryResult[4].Unload();
			
		If StatusInVerification Then
			ProductsForInspection.Load(SelectionTableSelect);
		Else
			GoodsForPicking.Load(SelectionTableSelect);
		EndIf;
		
		GoodsForIssue.Load(SampleTableToBeShipped);
		GoodsDoNotShip.Load(SamplingTableDoNotShip);
		
#If Not MobileStandaloneServer Then
		PackageBarcodes.Load(SelectionDetailRecords.SpendingOrderBarcodesOfPackages.Unload());
#EndIf

	EndIf;
		
	DocumentInformation = StrTemplate(NStr("vi = 'Số %1 ngày %2, %3';
											|ru = '№ %1 от %2, %3';
											|en = '%1 dated %2, %3'; fa = '%1 dated %2, %3';
											|it = '%1 dated %2, %3';
											|pl = '%1 dated %2, %3';
											|tr = '%2 tarihli %1 numaralı, %3'"), 
		ObjectsPrefixesClientServer.NumberForPrinting(Number), Format(Date, NStr("vi = 'DF=''dd.ММ.yyy HH:mm''';
																				|ru = 'ДФ=''дд.ММ.гг ЧЧ:мм''';
																				|en = 'DF=''MM/dd/yy hh:mm tt'''; fa = 'DF=''MM/dd/yy hh:mm tt''';
																				|it = 'D F ''=gg.ММ.aa 00:mm''';
																				|pl = 'DF=''dd.MM.yy HH:mm''';
																				|tr = 'DF=''dd.MM.yy HH:mm'''")), Status);

EndProcedure

&AtServer
Function QueryTextGoodsTableDocumentData()
	
#If Not MobileStandaloneServer Then

	QueryText =
		"SELECT
		|	GoodsIssueNote.Warehouse AS Warehouse,
		|	GoodsIssueNote.Comment AS Comment,
		|	GoodsIssueNote.Premise AS Premise,
		|	GoodsIssueNote.ShippingZone AS ShippingZone,
		|	GoodsIssueNote.Recipient AS Recipient,
		|	GoodsIssueNote.Number AS Number,
		|	GoodsIssueNote.Date AS Date,
		|	GoodsIssueNote.Status AS Status,
		|	GoodsIssueNote.ShippedBy AS ShippedBy,
		|	GoodsIssueNote.Inspector AS Inspector,
		|	GoodsIssueNote.EmployeeResponsible AS Performer,
		|	GoodsIssueNote.GoodsByReferences.(
		|		Products AS Products,
		|		Products.SKU AS SKU,
		|		Products.UnitOfMeasure AS Package,
		|		Characteristic AS Characteristic,
		|		Series AS Series,
		|		Purpose AS Purpose,
		|		Count AS Count,
		|		BatchesIndicationStatus AS BatchesIndicationStatus,
		|		ReferenceOrder AS ReferenceOrder
		|	) AS TableOfItemsByOrder,
		|	&BarcodeQueryText
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Ref = &Ref";

#Else

	QueryText =
		"SELECT
		|	GoodsIssueNote.Warehouse AS Warehouse,
		|	GoodsIssueNote.Comment AS Comment,
		|	GoodsIssueNote.Premise AS Premise,
		|	GoodsIssueNote.ShippingZone AS ShippingZone,
		|	GoodsIssueNote.Recipient AS Recipient,
		|	GoodsIssueNote.Number AS Number,
		|	GoodsIssueNote.Date AS Date,
		|	GoodsIssueNote.Status AS Status,
		|	GoodsIssueNote.ShippedBy AS ShippedBy,
		|	GoodsIssueNote.Inspector AS Inspector,
		|	GoodsIssueNote.EmployeeResponsible AS Performer,
		|	GoodsIssueNote.GoodsByReferences.(
		|		Products AS Products,
		|		Products.SKU AS SKU,
		|		Products.UnitOfMeasure AS Package,
		|		Characteristic AS Characteristic,
		|		Series AS Series,
		|		Purpose AS Purpose,
		|		Count AS Count,
		|		BatchesIndicationStatus AS BatchesIndicationStatus,
		|		ReferenceOrder AS ReferenceOrder
		|	) AS TableOfItemsByOrder
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Ref = &Ref";

#EndIf

	QueryText = QueryText + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ShippedGoods.Products AS Products,
		|	ShippedGoods.Products.SKU AS SKU,
		|	ShippedGoods.Characteristic AS Characteristic,
		|	ShippedGoods.Purpose AS Purpose,
		|	ShippedGoods.Series AS Series,
		|	ShippedGoods.Count AS Count,
		|	ShippedGoods.NumberOfPackages AS NumberOfPackages,
		|	ShippedGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	ShippedGoods.Action AS Action,
		|	CASE
		|		WHEN ShippedGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				AND NOT &UseBinLocationWarehousing
		|			THEN ShippedGoods.Products.UnitOfMeasure
		|		ELSE ShippedGoods.Package
		|	END AS Package,
		|	ShippedGoods.ThisIsAPackingList AS ThisIsAPackingList
		|INTO ShippedGoods
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
		|WHERE
		|	ShippedGoods.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableToBeShipped.Products AS Products,
		|	TableToBeShipped.SKU AS SKU,
		|	TableToBeShipped.Characteristic AS Characteristic,
		|	TableToBeShipped.Package AS Package,
		|	TableToBeShipped.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	TableToBeShipped.Series AS Series,
		|	TableToBeShipped.Purpose AS Purpose,
		|	TableToBeShipped.Count AS Count,
		|	TableToBeShipped.NumberOfPackages AS NumberOfPackages,
		|	TableToBeShipped.Action AS Action
		|FROM
		|	ShippedGoods AS TableToBeShipped
		|WHERE
		|	TableToBeShipped.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DoNotShipTable.Products AS Products,
		|	DoNotShipTable.SKU AS SKU,
		|	DoNotShipTable.Characteristic AS Characteristic,
		|	DoNotShipTable.Package AS Package,
		|	DoNotShipTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	DoNotShipTable.Series AS Series,
		|	DoNotShipTable.Purpose AS Purpose,
		|	DoNotShipTable.Count AS Count,
		|	DoNotShipTable.NumberOfPackages AS NumberOfPackages,
		|	DoNotShipTable.Action AS Action
		|FROM
		|	ShippedGoods AS DoNotShipTable
		|WHERE
		|	DoNotShipTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)";
	
	If Not UseBinLocationWarehousingForInformation Then
		QueryText = QueryText + 
		"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText +
		"SELECT
		|	TablePick.Products AS Products,
		|	TablePick.SKU AS SKU,
		|	TablePick.Characteristic AS Characteristic,
		|	TablePick.Package AS Package,
		|	CASE
		|		WHEN &ThisIsTest AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult 
		|			THEN 1
		|		ELSE TablePick.BatchesIndicationStatus
		|	END AS BatchesIndicationStatus,
		|	TablePick.Series AS Series,
		|	TablePick.Purpose AS Purpose,
		|	TablePick.Count AS Count,
		|	TablePick.NumberOfPackages AS NumberOfPackages,
		|	TablePick.NumberOfPackages AS NumberOfPackagesIsDifference,
		|	TablePick.Action AS Action
		|FROM
		|	ShippedGoods AS TablePick 
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
		|			AND TablePick.Products.ProductKind = BatchAccountingPolicies.Ref
		|WHERE
		|	TablePick.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)";
	Else
		QueryText = QueryText + 
		"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText +
		"SELECT
		|	TablePick.Products AS Products,
		|	TablePick.SKU AS SKU,
		|	TablePick.Characteristic AS Characteristic,
		|	TablePick.Package AS Package,
		|	CASE
		|		WHEN &ThisIsTest AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
		|			THEN 1
		|		ELSE TablePick.BatchesIndicationStatus
		|	END AS BatchesIndicationStatus,
		|	TablePick.Series AS Series,
		|	TablePick.Purpose AS Purpose,
		|	TablePick.Count AS Count,
		|	TablePick.NumberOfPackages AS NumberOfPackages,
		|	TablePick.NumberOfPackages AS NumberOfPackagesIsDifference,
		|	TablePick.Action AS Action,
		|	ISNULL(MainStorageBins.Cell.Code, """") AS MainStorageBin
		|FROM
		|	ShippedGoods AS TablePick
		|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
		|		ON TablePick.Products = MainStorageBins.Products
		|			AND MainStorageBins.MainStorageBin
		|			AND MainStorageBins.Warehouse = &Warehouse 
		|			AND CASE
		|				WHEN &UseWarerooms
		|						AND &DateOfShipment >= &StartDateOfWareroomUse
		|					THEN MainStorageBins.Premise = &Premise
		|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|			END
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
		|			AND TablePick.Products.ProductKind = BatchAccountingPolicies.Ref
		|WHERE
		|	TablePick.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)";
	EndIf;
	
	If UseBinLocationWarehousing Then
		QueryText = QueryText + 
		"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = QueryText +
		"SELECT
		|	FilterOfProducts_.Products AS Products,
		|	FilterOfProducts_.Ref AS Ref,
		|	FilterOfProducts_.Characteristic AS Characteristic,
		|	FilterOfProducts_.Package AS Package,
		|	FilterOfProducts_.Series AS Series,
		|	FilterOfProducts_.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	FilterOfProducts_.Purpose AS Purpose,
		|	FilterOfProducts_.CountPicked AS CountPicked,
		|	FilterOfProducts_.NumberOfPackagesPicked AS NumberOfPackagesPicked
		|INTO TablePicked
		|FROM
		|	Document.GoodsPickingPlacement.GoodsFilter AS FilterOfProducts_
		|WHERE
		|	FilterOfProducts_.Ref.ReferenceOrder = &Ref 
		|	AND FilterOfProducts_.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
		|	AND FilterOfProducts_.Ref.Posted
		|	AND (FilterOfProducts_.Ref.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors)
		|			OR FilterOfProducts_.Ref.Status = VALUE(Enum.StatusesOfGoodsPickingPlacement.DoneWithErrors))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose,
		|	NestedQuery.Series, 
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages
		|INTO TableBalancesForSelection
		|FROM
		|	(SELECT
		|		TablePicked.Products AS Products,
		|		TablePicked.Characteristic AS Characteristic,
		|		TablePicked.Purpose AS Purpose,
		|		TablePicked.Series AS Series,
		|		-TablePicked.CountPicked AS Count,
		|		TablePicked.NumberOfPackagesPicked AS NumberOfPackages
		|	FROM
		|		TablePicked AS TablePicked
		|
		|	UNION ALL
		|	
		|	SELECT
		|		ShippedGoods.Products, 
		|		ShippedGoods.Characteristic,
		|		ShippedGoods.Purpose,
		|		CASE
		|			WHEN ShippedGoods.BatchesIndicationStatus IN (1, 2)
		|				THEN VALUE(Catalog.ItemsBatches.EmptyRef)
		|			ELSE ShippedGoods.Series
		|		END AS Series,
		|		ShippedGoods.Count,
		|		0
		|	FROM
		|		ShippedGoods AS ShippedGoods
		|	WHERE
		|		ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip) 
		|
		|	UNION ALL
		|	
		|	SELECT
		|		SurplusesShortages.Products,
		|		SurplusesShortages.Characteristic,
		|		SurplusesShortages.Purpose,
		|		SurplusesShortages.Series,
		|		CASE
		|			WHEN SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
		|				THEN SurplusesShortages.Count
		|			ELSE -SurplusesShortages.Count
		|		END,
		|		0
		|	FROM
		|		Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS SurplusesShortages
		|	WHERE
		|		SurplusesShortages.Ref.Posted
		|		AND SurplusesShortages.Ref.WarehouseDocument = &Ref
		|		AND (SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
		|				OR SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus))) AS NestedQuery
		|
		|GROUP BY 
		|	NestedQuery.Series,
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose
		|;
		| 
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableBalancesForSelection.Products,
		|	TableBalancesForSelection.Products.SKU AS SKU,
		|	TableBalancesForSelection.Characteristic,
		|	TableBalancesForSelection.Purpose,
		|	TableBalancesForSelection.Count,
		|	TableBalancesForSelection.Count AS NumberOfPackages,
		|	TableBalancesForSelection.Products.UnitOfMeasure AS Package,
		|	TableBalancesForSelection.Series,
		|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick) AS Action
		|FROM
		|	TableBalancesForSelection AS TableBalancesForSelection
		|	WHERE
		|		TableBalancesForSelection.Count > 0";
		
		QueryText = QueryText + QueryTextTableOfGoodsBySelected();
	EndIf;

#If Not MobileStandaloneServer Then

	Columns = PackageBarcodes.Unload().Columns;
	If Columns.PackageBarcode.ValueType.ContainsType(Type("String")) Then
		BarcodeQueryText =
		"GoodsIssueNote.PackageBarcodes.(
		|		PackageBarcode AS PackageBarcode
		|	) AS SpendingOrderBarcodesOfPackages"
	Else		
		BarcodeQueryText =
		"GoodsIssueNote.PackageBarcodes.(
		|		PackageBarcode AS PackageBarcode,
		|		PackageBarcode.Products AS Products,
		|		PackageBarcode.Characteristic AS Characteristic
		|	) AS SpendingOrderBarcodesOfPackages";
	EndIf;

	QueryText = StrReplace(QueryText, "&BarcodeQueryText", BarcodeQueryText);
	
#EndIf

	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextTableOfGoodsBySelected()
	
	QueryText = 
	"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText +
	"SELECT
	|	TaraByOrder.Products AS Products,
	|	TaraByOrder.Characteristic AS Characteristic,
	|	SUM(TaraByOrder.Count) AS Count
	|INTO TaraByOrder
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS TaraByOrder
	|WHERE
	|	TaraByOrder.Ref = &Ref
	|		
	|	AND TaraByOrder.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|
	|GROUP BY
	|	TaraByOrder.Products,
	|	TaraByOrder.Characteristic,
	|	TaraByOrder.Ref
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.ItemsType AS ItemsType,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Package AS Package,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages
	|INTO ProductsWithPackagingDiscrepancies
	|FROM
	|	(SELECT
	|		GoodsFilter.Ref AS Filter,
	|		GoodsFilter.Products AS Products,
	|		GoodsFilter.Characteristic AS Characteristic,
	|		GoodsFilter.Purpose AS Purpose,
	|		GoodsFilter.Package AS Package,
	|		GoodsFilter.Series AS Series,
	|		GoodsFilter.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		GoodsFilter.CountPicked AS Count,
	|		GoodsFilter.NumberOfPackagesPicked AS NumberOfPackages
	|	FROM
	|		TablePicked AS GoodsFilter
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NULL,
	|		SurplusesShortages.Products,
	|		SurplusesShortages.Characteristic,
	|		SurplusesShortages.Purpose,
	|		SurplusesShortages.Package,
	|		SurplusesShortages.Series,
	|		0,
	|		CASE
	|			WHEN SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -SurplusesShortages.Count
	|			ELSE SurplusesShortages.Count
	|		END,
	|		CASE
	|			WHEN SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -SurplusesShortages.NumberOfPackages
	|			ELSE SurplusesShortages.NumberOfPackages
	|		END
	|	FROM
	|		Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS SurplusesShortages
	|	WHERE
	|		SurplusesShortages.Ref.Posted
	|		AND SurplusesShortages.Ref.WarehouseDocument = &Ref
	|		AND (SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				OR SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NULL,
	|		SurplusesShortages.Products,
	|		SurplusesShortages.Characteristic,
	|		SurplusesShortages.Purpose,
	|		SurplusesShortages.Package,
	|		SurplusesShortages.Series,
	|		0,
	|		-SurplusesShortages.Count,
	|		-SurplusesShortages.NumberOfPackages
	|	FROM
	|		Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS SurplusesShortages
	|	WHERE
	|		SurplusesShortages.Ref.Posted
	|		AND SurplusesShortages.Ref.WarehouseDocument = &Ref
	|		AND SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NULL,
	|		SurplusesShortages.Products,
	|		SurplusesShortages.Characteristic,
	|		SurplusesShortages.Purpose,
	|		SurplusesShortages.Package,
	|		SurplusesShortages.Series,
	|		0,
	|		SurplusesShortages.Count,
	|		SurplusesShortages.NumberOfPackages
	|	FROM
	|		Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS SurplusesShortages
	|	WHERE
	|		SurplusesShortages.Ref.Posted
	|		AND SurplusesShortages.Ref.RecipientNote = &Ref
	|		AND SurplusesShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NULL,
	|		ShippedGoods.Products,
	|		ShippedGoods.Characteristic,
	|		ShippedGoods.Purpose,
	|		ShippedGoods.Package,
	|		ShippedGoods.Series,
	|		0,
	|		-ShippedGoods.Count,
	|		-ShippedGoods.NumberOfPackages
	|	FROM
	|		ShippedGoods AS ShippedGoods
	|	WHERE
	|		ShippedGoods.Action IN (VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship), VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip))
	|		AND NOT ShippedGoods.ThisIsAPackingList) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Products.ItemsType,
	|	NestedQuery.BatchesIndicationStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepanciesInPackages.Products AS Products,
	|	DiscrepanciesInPackages.Characteristic AS Characteristic,
	|	DiscrepanciesInPackages.Purpose AS Purpose,
	|	DiscrepanciesInPackages.Series AS Series,
	|	SUM(DiscrepanciesInPackages.Count) AS Count
	|INTO StornoDiscrepanciesOnPackages
	|FROM
	|	(SELECT
	|		ProductsAreInSelection.Products AS Products,
	|		ProductsAreInSelection.Characteristic AS Characteristic,
	|		ProductsAreInSelection.Purpose AS Purpose,
	|		ProductsAreInSelection.Series AS Series,
	|		ProductsAreInSelection.Count AS Count
	|	FROM
	|		ProductsWithPackagingDiscrepancies AS ProductsAreInSelection
	|	WHERE
	|		ProductsAreInSelection.Count > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductsNotInSelection.Products,
	|		ProductsNotInSelection.Characteristic,
	|		ProductsNotInSelection.Purpose,
	|		ProductsNotInSelection.Series,
	|		ProductsNotInSelection.Count
	|	FROM
	|		ProductsWithPackagingDiscrepancies AS ProductsNotInSelection
	|	WHERE
	|		ProductsNotInSelection.Count < 0) AS DiscrepanciesInPackages
	|
	|GROUP BY
	|	DiscrepanciesInPackages.Purpose,
	|	DiscrepanciesInPackages.Products,
	|	DiscrepanciesInPackages.Characteristic,
	|	DiscrepanciesInPackages.Series
	|
	|HAVING
	|	SUM(DiscrepanciesInPackages.Count) = 0 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsWithPackagingDiscrepancies.Products AS Products,
	|	ProductsWithPackagingDiscrepancies.ItemsType AS ItemsType,
	|	ProductsWithPackagingDiscrepancies.Characteristic AS Characteristic,
	|	ProductsWithPackagingDiscrepancies.Purpose AS Purpose,
	|	ProductsWithPackagingDiscrepancies.Package AS Package,
	|	ProductsWithPackagingDiscrepancies.Series AS Series, 
	|	ProductsWithPackagingDiscrepancies.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ProductsWithPackagingDiscrepancies.Count AS Count,
	|	ProductsWithPackagingDiscrepancies.NumberOfPackages AS NumberOfPackages
	|INTO SelectionResult_
	|FROM
	|	ProductsWithPackagingDiscrepancies AS ProductsWithPackagingDiscrepancies
	|		LEFT JOIN StornoDiscrepanciesOnPackages AS StornoDiscrepanciesOnPackages
	|		ON ProductsWithPackagingDiscrepancies.Products = StornoDiscrepanciesOnPackages.Products
	|			AND ProductsWithPackagingDiscrepancies.Characteristic = StornoDiscrepanciesOnPackages.Characteristic
	|			AND ProductsWithPackagingDiscrepancies.Purpose = StornoDiscrepanciesOnPackages.Purpose
	|			AND ProductsWithPackagingDiscrepancies.Series = StornoDiscrepanciesOnPackages.Series
	|WHERE
	|	StornoDiscrepanciesOnPackages.Products IS NULL
	|	AND ProductsWithPackagingDiscrepancies.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionResult_.Products AS Products,
	|	SelectionResult_.Products.SKU AS SKU,
	|	SelectionResult_.Characteristic AS Characteristic,
	|	SelectionResult_.Purpose AS Purpose,
	|	SelectionResult_.Package AS Package,
	|	SelectionResult_.Series AS Series,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult 
	|			AND NOT BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries 
	|		THEN 1
    |		ELSE SelectionResult_.BatchesIndicationStatus
    |	END AS BatchesIndicationStatus,
	|	ISNULL(TaraByOrder.Count, 0) AS NumberOfContainersAvailable,
	|	SelectionResult_.Count AS Count,
	|	SelectionResult_.NumberOfPackages AS NumberOfPackages,
	|	SelectionResult_.NumberOfPackages AS NumberOfPackagesIsDifference,
	|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick) AS Action
	|FROM
	|	SelectionResult_ AS SelectionResult_
	|		LEFT JOIN TaraByOrder AS TaraByOrder
	|		ON SelectionResult_.Products = TaraByOrder.Products
	|			AND SelectionResult_.Characteristic = TaraByOrder.Characteristic
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON SelectionResult_.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON SelectionResult_.Characteristic = ItemsCharacteristics.Ref
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON SelectionResult_.Purpose = Assignments.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON SelectionResult_.Package = ProductPackages.Ref
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON SelectionResult_.Series = ItemsBatches.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND SelectionResult_.Products.ProductKind = BatchAccountingPolicies.Ref
	|
	|ORDER BY
	|	CatalogProducts.ItemsType.Order,
	|	CatalogProducts.Description,
	|	ItemsCharacteristics.Description,
	|	Assignments.Description,
	|	&QueryTextPackagingFactor DESC,
	|	ItemsBatches.ValidUntil_,
	|	ItemsBatches.Number";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		MobileWarehouseKeeperWorkspace.RequestTextForPackingCoefficient(
		"ProductPackages", Undefined));
		
	Return QueryText;

EndFunction

&AtServer
Procedure FillOutFormAgain()

	FillForm();
	SetConditionalAppearance();

EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ErrorText = "";
	UpdateFormOnServer(Result);
	GenerateMenuCommandHeaders();
	If ValueIsFilled(ErrorText) Then
		Status(ErrorText);
	EndIf;

	If ValueIsFilled(Result.DataOfFollowingItem) Then
		ResultOfScanningItem(Result.DataOfFollowingItem);
	EndIf;

EndProcedure

&AtServer
Procedure UpdateFormOnServer(Result)
	
	SeriesOnShipment = SeriesOfItemsForShipment(Result.Products);

	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(Result.Package, Result.Products);
	
	TheStructureOfTheSearch = ProductSearchStructure_();
	FillPropertyValues(TheStructureOfTheSearch, Result);
	
	If Result.Mode = "EditShipment" Or Result.Mode = "EditingBatches" Then 
				
		Literal = "LineNumber";
		LineNumber = Result[Literal];
		
		Count = Result.NumberOfPackages * PackagingFactor; 
		TableName = ?(Result.Mode = "EditShipment", "GoodsForIssue", "GoodsForPicking");
		
		If ShipmentIsAllowed(Result, Count) Then
			
			ThisObject[TableName][LineNumber].Package           = Result.Package;
			ThisObject[TableName][LineNumber].NumberOfPackages = Result.NumberOfPackages;
			ThisObject[TableName][LineNumber].Count         = Count;
			ThisObject[TableName][LineNumber].Purpose         = Result.Purpose;
			ThisObject[TableName][LineNumber].Series              = Result.Series;
			ThisObject[TableName][LineNumber].Characteristic     = Result.Characteristic;
			
		Else
			Return;
		EndIf;
		
	ElsIf Result.Mode = "Shipment" Then 
				
		SearchResult = GoodsForIssue.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			NumberOfPackages = SearchResult[0].NumberOfPackages + Result.NumberOfPackages;
			Count = NumberOfPackages * PackagingFactor;
			
			If ShipmentIsAllowed(Result, Count) Then
				SearchResult[0].NumberOfPackages = NumberOfPackages;
				SearchResult[0].Count = Count;
			Else
				Return;
			EndIf;
		Else
			NumberOfPackages = Result.NumberOfPackages;
			Count = NumberOfPackages * PackagingFactor;

			If ShipmentIsAllowed(Result, Count, True) Then
				NewRow = GoodsForIssue.Add();
				FillPropertyValues(NewRow, Result);
				NewRow.Count = Result.NumberOfPackages * PackagingFactor;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
			Else
				Return;
			EndIf;
		EndIf;
		
	ElsIf Result.Mode = "SelectionFromShipmentCell" Or Result.Mode = "SpecifyingSeries" Then
		
		TableName = ?(Result.Mode = "SelectionFromShipmentCell", "ProductsForInspection", "GoodsForPicking");
		
		SearchResult = ThisObject[TableName].FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			NumberOfPackages = SearchResult[0].NumberOfPackages + Result.NumberOfPackages;
			Count = NumberOfPackages * PackagingFactor;
			
			If ShipmentIsAllowed(Result, Count) Then
				SearchResult[0].NumberOfPackages = NumberOfPackages;
				SearchResult[0].Count = Count;
			Else
				Return;
			EndIf;
		Else
			NumberOfPackages = Result.NumberOfPackages;
			Count = NumberOfPackages * PackagingFactor;

			If ShipmentIsAllowed(Result, Count, True) Then
				NewRow = ThisObject[TableName].Add();
				FillPropertyValues(NewRow, Result);
				NewRow.Count = Result.NumberOfPackages * PackagingFactor;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
			Else
				Return;
			EndIf;
		EndIf;
		
		If Result.Mode = "SelectionFromShipmentCell" And SeriesOnShipment.SpecifyWhenPlanningPicking Then
			TheStructureOfTheSearch.Delete("Series");
		ElsIf Result.Mode = "SpecifyingSeries" Then
			TheStructureOfTheSearch.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
		EndIf;
		
		SearchResult = GoodsForPicking.FindRows(TheStructureOfTheSearch);
		If Not SearchResult.Count() Then
			TheStructureOfTheSearch.Delete("Package");
			SearchResult = GoodsForPicking.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		CountPicked = Result.NumberOfPackages * PackagingFactor;
		
		For Each String In SearchResult Do
			
			SubtractedValue = Min(String.Count, CountPicked);
			String.Count = String.Count - SubtractedValue;
			CountPicked = CountPicked - SubtractedValue;
			
			PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(String.Package, String.Products);
			String.NumberOfPackages = String.Count / PackagingFactor;
			
		EndDo;
		
		// Delete the lines if they are fully worked out
		ArrayOfRowsToDelete_1 = New Array;
		For Each String In GoodsForPicking Do
			If String.Count <= 0 Then
				ArrayOfRowsToDelete_1.Add(String);
			EndIf;
		EndDo; 
		
		For Each DeleteLine In ArrayOfRowsToDelete_1 Do
			GoodsForPicking.Delete(DeleteLine);
		EndDo;
		
	ElsIf Result.Mode = "EditingRecalculationShipment" Or Result.Mode = "RecalculationShipment" 
		Or Result.Mode = "EditingRecalculationShipmentWithoutBatch" Then
		
		ProductKind = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Result.Products, "ProductKind");
		BatchUsageSettings = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(ProductKind, "BatchUsageSettings");
		InventoryItem = (BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem); 
		
		If InventoryItem And SeriesOnShipment.SpecifyByPickingResult Then
			TheStructureOfTheSearch.Delete("Package");
			SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch); 				
			If SearchResult.Count() > 0 Then
				MessageTemplate = NStr("vi = 'Số lượng được chỉ định của hàng hóa ""%1"" với sê-ri ""%2"" sẽ lớn hơn 1. Chính sách ghi nhận sê-ri của hàng hóa này quy định rằng, số lượng theo sê-ri bất kỳ của hàng hóa này sẽ luôn bằng 1.';
										|ru = 'Указанное количество товара ""%1"" с серией ""%2"" будет больше 1. Политика учета серий данного товара предусматривает, что количество по любой серии этого товара всегда будет равно 1.';
										|en = 'The specified quantity of the ""%1"" item with batch ""%2"" is greater than 1. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.'; fa = 'The specified quantity of the ""%1"" item with batch ""%2"" is greater than 1. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|it = 'The specified quantity of the ""%1"" item with batch ""%2"" is greater than 1. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|pl = 'The specified quantity of the ""%1"" item with batch ""%2"" is greater than 1. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
										|tr = '""%2"" partisine sahip ""%1"" ürünün belirtilen miktarı 1 değerinin üzerinde olacaktır. Bu ürün için toplu muhasebe politikası, bu ürünün herhangi bir partisi için miktarın her zaman 1 olacağını öngörür.'");
				ErrorText = StrTemplate(MessageTemplate, Result.Products, Result.Series);
				Return;
			EndIf;
		EndIf;
		
		If SeriesOnShipment.SpecifyByPickingResult And (Result.Mode = "EditingRecalculationShipmentWithoutBatch"
			Or Result.Mode = "RecalculationShipment") Then
			
			TheStructureOfTheSearch.Insert("Package", Result.Package);
			TheStructureOfTheSearch.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
			SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch);  
				
			If Not SearchResult.Count() Then
				TheStructureOfTheSearch.Delete("Package");
				SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch);
			EndIf;
				
			If Result.Mode = "RecalculationShipment" And SearchResult.Count = 0 Then 
				Return;
			EndIf;
			
			CountPicked = Result.NumberOfPackages * PackagingFactor;
			
			ArrayOfRowsToDelete_1 = New Array;
			
			For Each String In SearchResult Do
				SubtractedValue = Min(String.Count, CountPicked);
				String.Count = String.Count - SubtractedValue;
				CountPicked = CountPicked - SubtractedValue;
					
				StringPackingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(String.Package, String.Products);
				String.NumberOfPackages = String.Count / StringPackingFactor; 
				String.NumberOfPackagesIsDifference = String.NumberOfPackages;
				If String.Count = 0 Then
					ArrayOfRowsToDelete_1.Add(String);
				EndIf;
			EndDo; 

			TheStructureOfTheSearch.Insert("Series", Result.Series);
			TheStructureOfTheSearch.Insert("Package", Result.Package);
			SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch); 
				
			If SearchResult.Count() > 0 Then
				SearchResult[0].NumberOfPackages = SubtractedValue / PackagingFactor + SearchResult[0].NumberOfPackages;
				SearchResult[0].Count = Result.NumberOfPackages * PackagingFactor; 
				SearchResult[0].NumberOfPackagesReal = SearchResult[0].NumberOfPackagesReal + Result.NumberOfPackages;
				SearchResult[0].CountReal = SearchResult[0].NumberOfPackagesReal * PackagingFactor;
				SearchResult[0].NumberOfPackagesIsDifference = SearchResult[0].NumberOfPackages - SearchResult[0].NumberOfPackagesReal;
				SearchResult[0].QuantityDifference = SearchResult[0].NumberOfPackagesIsDifference * PackagingFactor;
			Else  
				TheStructureOfTheSearch.Delete("Series");
				TheStructureOfTheSearch.Delete("Package");
				SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch);
				If SearchResult.Count() > 0 Then 
					NumberOfPackages = Result.NumberOfPackages;
				Else
					NumberOfPackages = 0; 
				EndIf;
				NewRow = ProductsForInspection.Add();
				FillPropertyValues(NewRow, Result); 
				NewRow.NumberOfPackages = NumberOfPackages;
				NewRow.Count = NewRow.NumberOfPackages * PackagingFactor; 
				NewRow.NumberOfPackagesReal = Result.NumberOfPackages; 
				NewRow.CountReal = NewRow.NumberOfPackagesReal * PackagingFactor;
				NewRow.NumberOfPackagesIsDifference = NewRow.NumberOfPackages - NewRow.NumberOfPackagesReal;
				NewRow.QuantityDifference = NewRow.NumberOfPackagesIsDifference * PackagingFactor;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
			EndIf;
			
			For Each DeleteLine In ArrayOfRowsToDelete_1 Do
				ProductsForInspection.Delete(DeleteLine);
			EndDo;
		Else	
			SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch);  
			If Not SearchResult.Count() Then
				TheStructureOfTheSearch.Delete("Package");
				SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch);
			EndIf;
				
			If SearchResult.Count() > 0 Then  
				If SearchResult[0].Package <> Result.Package Then 
					SearchResult[0].NumberOfPackages = SearchResult[0].Count / PackagingFactor;
				EndIf;
				If Result.Mode = "RecalculationShipment" Then
					SearchResult[0].NumberOfPackagesReal = SearchResult[0].NumberOfPackagesReal + Result.NumberOfPackages;
				Else
					SearchResult[0].NumberOfPackagesReal = Result.NumberOfPackages;
				EndIf;
				SearchResult[0].CountReal = Result.NumberOfPackages * PackagingFactor;
				SearchResult[0].NumberOfPackagesIsDifference = SearchResult[0].NumberOfPackages - SearchResult[0].NumberOfPackagesReal;
				SearchResult[0].QuantityDifference = SearchResult[0].NumberOfPackagesIsDifference * PackagingFactor;
				SearchResult[0].Package = Result.Package;
			Else
				NewRow = ProductsForInspection.Add();
				FillPropertyValues(NewRow, Result); 
				NewRow.NumberOfPackages = 0;
				NewRow.Count = NewRow.NumberOfPackages; 
				NewRow.NumberOfPackagesReal = Result.NumberOfPackages; 
				NewRow.CountReal = NewRow.NumberOfPackagesReal * PackagingFactor;
				NewRow.NumberOfPackagesIsDifference = NewRow.NumberOfPackages - NewRow.NumberOfPackagesReal;
				NewRow.QuantityDifference = NewRow.NumberOfPackagesIsDifference * PackagingFactor;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
			EndIf;

		EndIf; 
	
		UpdateTestPrompt();
		
	EndIf;
	
	For Each LineMarkingCode In Result.PackageBarcodes Do
		NewRow = PackageBarcodes.Add();
		FillPropertyValues(NewRow, LineMarkingCode);
	EndDo;

EndProcedure

&AtServer
Function ThereAreErrorsInSpecifyingBatches()
	
	SelectionOfEmptyBatches = New Structure;
	SelectionOfEmptyBatches.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	ArrayEmptyBatches = New Array;

	If Status = Enums.GoodsIssueNoteStatuses.Prepared 
		Or Status = Enums.GoodsIssueNoteStatuses.ForPicking Then 
		
		SelectionOfEmptyBatches.Insert("BatchesIndicationStatus", 27);
		ArrayEmptyBatches = GoodsForPicking.FindRows(SelectionOfEmptyBatches);
		
		SelectionOfEmptyBatches.Insert("BatchesIndicationStatus", 7);
		ArrayEmptyBatches2 = GoodsForPicking.FindRows(SelectionOfEmptyBatches);
		
		SelectionOfEmptyBatches.Insert("BatchesIndicationStatus", 5);
		ArrayEmptyBatches3 = GoodsForPicking.FindRows(SelectionOfEmptyBatches);
		
		MobileWarehouseKeeperWorkspace.SupplementArray(ArrayEmptyBatches, ArrayEmptyBatches2);
		MobileWarehouseKeeperWorkspace.SupplementArray(ArrayEmptyBatches, ArrayEmptyBatches3);
		
		MessageTemplate = NStr("vi = 'Chưa điền sê-ri đối với hàng hóa ""%1"" trong dòng %2 của danh sách ""Cần lấy ra""';
								|ru = 'Не заполнена серия для товара ""%1"" в строке %2 списка ""К отбору""';
								|en = 'The batch for the ""%1"" item in line %2 of the ""To pick"" list is not filled in'; fa = 'The batch for the ""%1"" item in line %2 of the ""To pick"" list is not filled in';
								|it = 'The batch for the ""%1"" item in line %2 of the ""To pick"" list is not filled in';
								|pl = 'The batch for the ""%1"" item in line %2 of the ""To pick"" list is not filled in';
								|tr = '""Toplamaya hazır"" listesinin %2 satırındaki ""%1"" ürünün partisi doldurulmadı'");
		
		For Each StringIsEmptyBatch In ArrayEmptyBatches Do
			LineNumber = GoodsForPicking.IndexOf(StringIsEmptyBatch) + 1;
			ErrorText = StrTemplate(MessageTemplate, StringIsEmptyBatch.Products, Format(LineNumber, "NZ=0; NG="));
		EndDo;

	ElsIf Status = Enums.GoodsIssueNoteStatuses.DuringChecking Then 
		
		SelectionOfEmptyBatches.Insert("BatchesIndicationStatus", 1);
		ArrayEmptyBatches = ProductsForInspection.FindRows(SelectionOfEmptyBatches);
		
		SelectionOfEmptyBatches.Insert("BatchesIndicationStatus", 3);
		ArrayEmptyBatches2 = ProductsForInspection.FindRows(SelectionOfEmptyBatches);
		
		MobileWarehouseKeeperWorkspace.SupplementArray(ArrayEmptyBatches, ArrayEmptyBatches2);
		
		MessageTemplate = NStr("vi = 'Chưa điền sê-ri đối với hàng hóa ""%1"" trong dòng %2 của danh sách ""Cần kiểm tra""';
								|ru = 'Не заполнена серия для товара ""%1"" в строке %2 списка ""К проверке""';
								|en = 'The batch for the ""%1"" item in line %2 of the ""To verify"" list is not filled in'; fa = 'The batch for the ""%1"" item in line %2 of the ""To verify"" list is not filled in';
								|it = 'The batch for the ""%1"" item in line %2 of the ""To verify"" list is not filled in';
								|pl = 'The batch for the ""%1"" item in line %2 of the ""To verify"" list is not filled in';
								|tr = '""Kontrol edilecek"" listesinin %2 satırındaki ""%1"" ürünün partisi doldurulmadı'");
	
		For Each StringIsEmptyBatch In ArrayEmptyBatches Do
			LineNumber = ProductsForInspection.IndexOf(StringIsEmptyBatch) + 1;
			ErrorText = StrTemplate(MessageTemplate, StringIsEmptyBatch.Products, Format(LineNumber, "NZ=0; NG="));
		EndDo;
		
	EndIf;
	
	Return ArrayEmptyBatches.Count() <> 0;
	
EndFunction

&AtServer
Function FinishSpecifyingBatches()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsForInspection.Products,
	|	ProductsForInspection.Characteristic,
	|	ProductsForInspection.Purpose,
	|	ProductsForInspection.Package,
	|	ProductsForInspection.Series,
	|	ProductsForInspection.Count AS Count,
	|	ProductsForInspection.NumberOfPackages AS NumberOfPackages,
	|	ProductsForInspection.Action AS Action
	|INTO ProductsForInspection
	|FROM 
	|	&ProductsForInspection AS ProductsForInspection	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForPicking.Products,
	|	GoodsForPicking.Characteristic,
	|	GoodsForPicking.Purpose,
	|	GoodsForPicking.Package,
	|	GoodsForPicking.Series,
	|	GoodsForPicking.Count AS Count,
	|	GoodsForPicking.NumberOfPackages AS NumberOfPackages,
	|	GoodsForPicking.Action AS Action
	|INTO GoodsForPicking
	|FROM 
	|	&GoodsForPicking AS GoodsForPicking 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsDoNotShip.Products,
	|	GoodsDoNotShip.Characteristic,
	|	GoodsDoNotShip.Purpose,
	|	GoodsDoNotShip.Package,
	|	GoodsDoNotShip.Series,
	|	GoodsDoNotShip.Count AS Count,
	|	GoodsDoNotShip.NumberOfPackages AS NumberOfPackages,
	|	GoodsDoNotShip.Action
	|INTO GoodsDoNotShip
	|FROM 
	|	&GoodsDoNotShip AS GoodsDoNotShip
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Package,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Count AS Count,
	|	GoodsForIssue.NumberOfPackages AS NumberOfPackages,
	|	GoodsForIssue.Action
	|INTO GoodsForIssue
	|FROM 
	|	&GoodsForIssue AS GoodsForIssue 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages,
	|	NestedQuery.Action
	|FROM 
	|	(SELECT
	|		ProductsForInspection.Products,
	|		ProductsForInspection.Characteristic,
	|		ProductsForInspection.Purpose,
	|		ProductsForInspection.Package,
	|		ProductsForInspection.Series,
	|		ProductsForInspection.Count AS Count,
	|		ProductsForInspection.NumberOfPackages AS NumberOfPackages,
	|		ProductsForInspection.Action
	|	FROM
	|		ProductsForInspection AS ProductsForInspection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForPicking.Products,
	|		GoodsForPicking.Characteristic,
	|		GoodsForPicking.Purpose,
	|		GoodsForPicking.Package,
	|		GoodsForPicking.Series,
	|		GoodsForPicking.Count,
	|		GoodsForPicking.NumberOfPackages,
	|		GoodsForPicking.Action
	|	FROM
	|		GoodsForPicking AS GoodsForPicking
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsDoNotShip.Products,
	|		GoodsDoNotShip.Characteristic,
	|		GoodsDoNotShip.Purpose,
	|		GoodsDoNotShip.Package,
	|		GoodsDoNotShip.Series,
	|		GoodsDoNotShip.Count,
	|		GoodsDoNotShip.NumberOfPackages,
	|		GoodsDoNotShip.Action
	|	FROM
	|		GoodsDoNotShip AS GoodsDoNotShip
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssue.Products,
	|		GoodsForIssue.Characteristic,
	|		GoodsForIssue.Purpose,
	|		GoodsForIssue.Package,
	|		GoodsForIssue.Series,
	|		GoodsForIssue.Count,
	|		GoodsForIssue.NumberOfPackages,
	|		GoodsForIssue.Action
	|	FROM
	|		GoodsForIssue AS GoodsForIssue) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Action"; 
	
	Query.SetParameter("ProductsForInspection", ProductsForInspection.Unload());
	Query.SetParameter("GoodsForPicking", GoodsForPicking.Unload());
	Query.SetParameter("GoodsDoNotShip", GoodsDoNotShip.Unload());
	Query.SetParameter("GoodsForIssue", GoodsForIssue.Unload());
	
	ShippedGoods = Query.Execute().Unload();

	BeginTransaction();
	Try
		OrderObject_ = Ref.GetObject();
			
		OrderObject_.Premise   = Premise;
		OrderObject_.Comment = Comment;
		OrderObject_.ShippingZone = ShippingZone;
			
		OrderObject_.Status = Enums.GoodsIssueNoteStatuses.ForPicking;
		OrderObject_.EmployeeResponsible = User;
			
		OrderObject_.ShippedGoods.Load(ShippedGoods); 
		
		SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.SeriesSpecificationParameters(OrderObject_, Documents.GoodsIssueNote);
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.ShippedGoods);

#If Not MobileStandaloneServer Then
		OrderObject_.PackageBarcodes.Clear();
		For Each StringBC In PackageBarcodes Do
			NewRow = OrderObject_.PackageBarcodes.Add();
			NewRow.PackageBarcode = StringBC.PackageBarcode;
		EndDo;

		OrderObject_.Write(DocumentWriteMode.Posting);
#Else
		OrderObject_.Write(DocumentWriteMode.Write);
#EndIf

		CommitTransaction();
	Except 
		RollbackTransaction(); 
		ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Не удалось записать %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = 'Kaydedilemedi%1. %2'"), Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return False;
	EndTry;
		
	Return True;

EndFunction

&AtServer
Function FinishSelectionOnServer(Mode)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsForInspection.Products,
	|	ProductsForInspection.Characteristic,
	|	ProductsForInspection.Purpose,
	|	ProductsForInspection.Package,
	|	ProductsForInspection.Series,
	|	ProductsForInspection.Count AS Count,
	|	ProductsForInspection.NumberOfPackages AS NumberOfPackages,
	|	ProductsForInspection.Action
	|INTO ProductsForInspection
	|FROM 
	|	&ProductsForInspection AS ProductsForInspection	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForPicking.Products,
	|	GoodsForPicking.Characteristic,
	|	GoodsForPicking.Purpose,
	|	GoodsForPicking.Package,
	|	GoodsForPicking.Series,
	|	GoodsForPicking.Count AS Count,
	|	GoodsForPicking.NumberOfPackages AS NumberOfPackages,
	|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip) AS Action
	|INTO GoodsForPicking
	|FROM 
	|	&GoodsForPicking AS GoodsForPicking 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsDoNotShip.Products,
	|	GoodsDoNotShip.Characteristic,
	|	GoodsDoNotShip.Purpose,
	|	GoodsDoNotShip.Package,
	|	GoodsDoNotShip.Series,
	|	GoodsDoNotShip.Count AS Count,
	|	GoodsDoNotShip.NumberOfPackages AS NumberOfPackages,
	|	GoodsDoNotShip.Action
	|INTO GoodsDoNotShip
	|FROM 
	|	&GoodsDoNotShip AS GoodsDoNotShip
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Package,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Count AS Count,
	|	GoodsForIssue.NumberOfPackages AS NumberOfPackages,
	|	GoodsForIssue.Action
	|INTO GoodsForIssue
	|FROM 
	|	&GoodsForIssue AS GoodsForIssue 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages,
	|	NestedQuery.Action
	|FROM 
	|	(SELECT
	|		ProductsForInspection.Products,
	|		ProductsForInspection.Characteristic,
	|		ProductsForInspection.Purpose,
	|		ProductsForInspection.Package,
	|		ProductsForInspection.Series,
	|		ProductsForInspection.Count AS Count,
	|		ProductsForInspection.NumberOfPackages AS NumberOfPackages,
	|		ProductsForInspection.Action
	|	FROM
	|		ProductsForInspection AS ProductsForInspection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForPicking.Products,
	|		GoodsForPicking.Characteristic,
	|		GoodsForPicking.Purpose,
	|		GoodsForPicking.Package,
	|		GoodsForPicking.Series,
	|		GoodsForPicking.Count,
	|		GoodsForPicking.NumberOfPackages,
	|		GoodsForPicking.Action
	|	FROM
	|		GoodsForPicking AS GoodsForPicking
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsDoNotShip.Products,
	|		GoodsDoNotShip.Characteristic,
	|		GoodsDoNotShip.Purpose,
	|		GoodsDoNotShip.Package,
	|		GoodsDoNotShip.Series,
	|		GoodsDoNotShip.Count,
	|		GoodsDoNotShip.NumberOfPackages,
	|		GoodsDoNotShip.Action
	|	FROM
	|		GoodsDoNotShip AS GoodsDoNotShip
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssue.Products,
	|		GoodsForIssue.Characteristic,
	|		GoodsForIssue.Purpose,
	|		GoodsForIssue.Package,
	|		GoodsForIssue.Series,
	|		GoodsForIssue.Count,
	|		GoodsForIssue.NumberOfPackages,
	|		GoodsForIssue.Action
	|	FROM
	|		GoodsForIssue AS GoodsForIssue) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Action";
	
	Query.SetParameter("ProductsForInspection", ProductsForInspection.Unload());
	Query.SetParameter("GoodsForPicking", GoodsForPicking.Unload());
	Query.SetParameter("GoodsDoNotShip", GoodsDoNotShip.Unload());
	Query.SetParameter("GoodsForIssue", GoodsForIssue.Unload());
	
	ShippedGoods = Query.Execute().Unload();
	
	BeginTransaction();
	Try
		
		OrderObject_ = Ref.GetObject();
		
		OrderObject_.Premise   = Premise;
		OrderObject_.Comment = Comment;
		OrderObject_.ShippingZone = ShippingZone;
			
		If Mode = "Validate" Then
			OrderObject_.Status      = Enums.GoodsIssueNoteStatuses.DuringChecking;
			OrderObject_.Inspector   = User;
		Else
			OrderObject_.Status      = Enums.GoodsIssueNoteStatuses.ForChecking;
		EndIf;
		
		OrderObject_.ShippedGoods.Load(ShippedGoods);

		TheStructureOfTheSearch = ProductSearchStructure_();
		TheStructureOfTheSearch.Delete("Package");
		TheStructureOfTheSearch.Delete("Series");
		TheStructureOfTheSearch.Delete("Action");

		For Each String In GoodsForPicking Do
		
			QuantityToDistribution = String.Count; 
			
			FillPropertyValues(TheStructureOfTheSearch, String);
				
			FoundOrders_ = OrderObject_.GoodsByReferences.FindRows(TheStructureOfTheSearch);
			For Each OrderLine_2 In FoundOrders_ Do
				If QuantityToDistribution >= OrderLine_2.Count Then
					QuantityToDistribution = QuantityToDistribution - OrderLine_2.Count;
					OrderObject_.GoodsByReferences.Delete(OrderLine_2);
				Else
					OrderLine_2.Count = OrderLine_2.Count - QuantityToDistribution;
					QuantityToDistribution = 0;
				EndIf;
					
				If QuantityToDistribution = 0 Then
					Break;
				EndIf;
			EndDo;

		EndDo;

		SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.SeriesSpecificationParameters(OrderObject_, Documents.GoodsIssueNote);
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.GoodsByReferences);
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.ShippedGoods);
		
#If Not MobileStandaloneServer Then
		OrderObject_.PackageBarcodes.Clear();
		For Each StringBC In PackageBarcodes Do
			NewRow = OrderObject_.PackageBarcodes.Add();
			NewRow.PackageBarcode = StringBC.PackageBarcode;
		EndDo;

		OrderObject_.Write(DocumentWriteMode.Posting);
#Else
		OrderObject_.Write(DocumentWriteMode.Write);
#EndIf

		CommitTransaction();
	Except 
		RollbackTransaction(); 
		ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Не удалось записать %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = 'Kaydedilemedi%1. %2'"), Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
		
	Return True;
	
EndFunction

&AtServer
Function FinishCheckingOnServer(Mode)
	
	Dobor = (Mode = "Pick" Or Mode = "SelectComplete");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsForInspection.Products,
	|	ProductsForInspection.Characteristic,
	|	ProductsForInspection.Purpose,
	|	ProductsForInspection.Package,
	|	ProductsForInspection.BatchesIndicationStatus,
	|	ProductsForInspection.Series,
	|	ProductsForInspection.Count,
	|	ProductsForInspection.NumberOfPackages,
	|	ProductsForInspection.CountReal,
	|	ProductsForInspection.NumberOfPackagesReal,
	|	ProductsForInspection.QuantityDifference,
	|	ProductsForInspection.NumberOfPackagesIsDifference,
	|	ProductsForInspection.Action
	|INTO ProductsForInspection
	|FROM
	|	&ProductsForInspection AS ProductsForInspection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages,
	|	NestedQuery.Action
	|INTO ShippedGoods
	|FROM
	|	(SELECT
	|		TTShortageToShip.Products,
	|		TTShortageToShip.Characteristic,
	|		TTShortageToShip.Purpose,
	|		TTShortageToShip.Package,
	|		TTShortageToShip.Series,
	|		TTShortageToShip.CountReal AS Count,
	|		TTShortageToShip.NumberOfPackagesReal AS NumberOfPackages,
	|		VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship) AS Action
	|	FROM
	|		ProductsForInspection AS TTShortageToShip
	|	WHERE
	|		TTShortageToShip.NumberOfPackagesIsDifference > 0
	|		AND TTShortageToShip.NumberOfPackagesReal <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTSurplusToShip.Products,
	|		TTSurplusToShip.Characteristic,
	|		TTSurplusToShip.Purpose,
	|		TTSurplusToShip.Package,
	|		TTSurplusToShip.Series,
	|		TTSurplusToShip.Count AS Count,
	|		TTSurplusToShip.NumberOfPackages AS NumberOfPackages,
	|		VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship) AS Action
	|	FROM
	|		ProductsForInspection AS TTSurplusToShip
	|	WHERE
	|		TTSurplusToShip.NumberOfPackagesIsDifference < 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TTToShip.Products,
	|		TTToShip.Characteristic,
	|		TTToShip.Purpose,
	|		TTToShip.Package,
	|		TTToShip.Series,
	|		TTToShip.CountReal AS Count,
	|		TTToShip.NumberOfPackagesReal AS NumberOfPackages,
	|		VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship) AS Action
	|	FROM
	|		ProductsForInspection AS TTToShip
	|	WHERE
	|		TTToShip.NumberOfPackagesIsDifference = 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TTSurplus.Products,
	|		TTSurplus.Characteristic,
	|		TTSurplus.Purpose,
	|		TTSurplus.Package,
	|		TTSurplus.Series,
	|		-TTSurplus.QuantityDifference AS Count,
	|		-TTSurplus.NumberOfPackagesIsDifference AS NumberOfPackages,
	|		VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip) AS Action
	|	FROM
	|		ProductsForInspection AS TTSurplus
	|	WHERE
	|		TTSurplus.NumberOfPackagesIsDifference < 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TTShortage.Products,
	|		TTShortage.Characteristic,
	|		TTShortage.Purpose,
	|		TTShortage.Package,
	|		CASE
	|			WHEN NOT TTShortage.BatchesIndicationStatus IN (0, 1, 2, 3, 4)
	|				THEN TTShortage.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END AS Series,
	|		CASE
	|			WHEN TTShortage.QuantityDifference = 0
	|				THEN TTShortage.Count
	|			ELSE TTShortage.QuantityDifference
	|		END AS Count,
	|		TTShortage.NumberOfPackagesIsDifference AS NumberOfPackages,
	|		VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick) AS Action
	|	FROM
	|		ProductsForInspection AS TTShortage
	|	WHERE
	|		TTShortage.NumberOfPackagesIsDifference > 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Action
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Package,
	|	ShippedGoods.Series,
	|	ShippedGoods.Count,
	|	ShippedGoods.NumberOfPackages,
	|	ShippedGoods.Action
	|FROM
	|	ShippedGoods AS ShippedGoods";
		
	Query.SetParameter("ProductsForInspection", ProductsForInspection.Unload());
	
	ShippedGoods = Query.Execute().Unload();
	
	DocumentDiscrepanciesObject = GenerateDocumentOfDiscrepancies();
	
	BeginTransaction();
	Try
		
		OrderObject_ = Ref.GetObject();

		OrderObject_.Premise   = Premise;
		OrderObject_.Comment = Comment;
		OrderObject_.ShippingZone = ShippingZone;
		
		If Mode = "Ship" Or Mode = "SurplusToShip" Then
			OrderObject_.Status     = Enums.GoodsIssueNoteStatuses.ToShip;
			OrderObject_.ShippedBy   = User;
		ElsIf Mode = "ShipComplete" Or Mode = "SurplusComplete" Then
			OrderObject_.Status = Enums.GoodsIssueNoteStatuses.Verified;
		ElsIf Dobor Then 
			OrderObject_.Status     = Enums.GoodsIssueNoteStatuses.ForPicking;
			OrderObject_.Inspector  = Undefined; 
		EndIf;
		
		ConditionForSelectingRows = New Structure;
		ConditionForSelectingRows.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick);
		FoundRows = OrderObject_.ShippedGoods.FindRows(ConditionForSelectingRows);
		For Each DeleteLine In FoundRows Do
			OrderObject_.ShippedGoods.Delete(DeleteLine);
		EndDo;
		
		TheStructureOfTheSearch = ProductSearchStructure_();
		TheStructureOfTheSearch.Delete("Package");
		TheStructureOfTheSearch.Delete("Series");
		TheStructureOfTheSearch.Delete("Action");

		For Each LineChecked In ShippedGoods Do
					
			If LineChecked.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick
				And Not Dobor Then
				
				If LineChecked.Count = 0 Then
					PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(LineChecked.Package, LineChecked.Products);
					QuantityToDistribution = LineChecked.NumberOfPackages * PackagingFactor;
				Else
					QuantityToDistribution = LineChecked.Count;
				EndIf; 
				
				FillPropertyValues(TheStructureOfTheSearch, LineChecked);
				FoundOrders_ = OrderObject_.GoodsByReferences.FindRows(TheStructureOfTheSearch);
				For Each OrderLine_2 In FoundOrders_ Do    
					If QuantityToDistribution >= OrderLine_2.Count Then
						QuantityToDistribution = QuantityToDistribution - OrderLine_2.Count;
						OrderObject_.GoodsByReferences.Delete(OrderLine_2);
					Else
						OrderLine_2.Count = OrderLine_2.Count - QuantityToDistribution;
						QuantityToDistribution = 0;
						EndIf;
						
					If QuantityToDistribution = 0 Then
						Break;
					EndIf;
				EndDo;
			Else	
				NewRow = OrderObject_.ShippedGoods.Add();
				FillPropertyValues(NewRow, LineChecked);
			EndIf;
		EndDo;

		SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.SeriesSpecificationParameters(OrderObject_, Documents.GoodsIssueNote);
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.ShippedGoods);

#If Not MobileStandaloneServer Then
		OrderObject_.PackageBarcodes.Clear();
		For Each StringBC In PackageBarcodes Do		
			NewRow = OrderObject_.PackageBarcodes.Add();
			NewRow.PackageBarcode = StringBC.PackageBarcode;
		EndDo;
#EndIf

		If DocumentDiscrepanciesObject <> Undefined Then
			If UsedFormServer = UsedServer.Standalone Then
				RollbackTransaction();
				ErrorText = NStr("vi = 'Do phát hiện sai lệch, không thể hoàn thành kiểm tra ở chế độ ngoại tuyến. Để hoàn thành kiểm tra, cần kết nối internet hoặc chọn tùy chọn ""Hoàn thành mà không kiểm tra"". Nếu không, các sự thay đổi đã thực hiện sẽ không được ghi lại.';
								|ru = 'Из-за обнаружения расхождений невозможно завершить проверку в автономном режиме. Чтобы завершить проверку, необходимо подключиться к интернету или выбрать опцию ""Завершить без проверки"". Иначе выполненные изменения не сохранятся.';
								|en = 'As discrepancies are found, it is impossible to complete the check in standalone mode. To complete the check, connect to the Internet or select the ""Complete without check"" option. Otherwise, the changes will not be saved.'; fa = 'As discrepancies are found, it is impossible to complete the check in standalone mode. To complete the check, connect to the Internet or select the ""Complete without check"" option. Otherwise, the changes will not be saved.';
								|it = 'As discrepancies are found, it is impossible to complete the check in standalone mode. To complete the check, connect to the Internet or select the ""Complete without check"" option. Otherwise, the changes will not be saved.';
								|pl = 'As discrepancies are found, it is impossible to complete the check in standalone mode. To complete the check, connect to the Internet or select the ""Complete without check"" option. Otherwise, the changes will not be saved.';
								|tr = 'Tespit edilen tutarsızlıklar nedeniyle kontrol tek başına modda tamamlanamıyor. Kontrolü tamamlamak için internete bağlanmak veya ""Kontrol etmeden tamamla"" seçeneğini seçmek gerekir. Aksi halde yapılan değişiklikler kaydedilmez.'");
				Return False;
			EndIf;
			DocumentDiscrepanciesObject.Write(DocumentWriteMode.Posting);
		EndIf;
		
#If Not MobileStandaloneServer Then
		If OrderObject_.ShippedGoods.Count() = 0 Then
			OrderObject_.Write(DocumentWriteMode.UndoPosting);
		Else
			OrderObject_.Write(DocumentWriteMode.Posting);
		EndIf;
#Else
		OrderObject_.Write(DocumentWriteMode.Write);
#EndIf

		CommitTransaction();
	Except 
		RollbackTransaction();

		ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Не удалось записать %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = 'Kaydedilemedi%1. %2'"), Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return False;
	EndTry;
	
	Return True;
	
EndFunction

&AtServer
Function GenerateDocumentOfDiscrepancies() 
	
	// 1. Let's calculate according to the selection tasks how many were selected
	// 2. Let's calculate what shows in the TS for Verification
	// 3. Let's calculate how many discrepancies have already been taken into account in the documents
	// 4. Let's calculate how many shipping lines and non-shipping lines are in the order
	// 5. We will create a new document of discrepancies for the difference.
	
	If Not UseBinLocationWarehousing Then
		Return Undefined;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsForInspection.Products,
	|	ProductsForInspection.Characteristic,
	|	ProductsForInspection.Purpose,
	|	ProductsForInspection.Package,
	|	CASE
	|		WHEN NOT ProductsForInspection.BatchesIndicationStatus IN (0, 1, 2)
	|			THEN ProductsForInspection.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	ProductsForInspection.CountReal,
	|	ProductsForInspection.NumberOfPackagesReal,
	|	ProductsForInspection.Action
	|INTO ProductsForInspection
	|FROM
	|	&ProductsForInspection AS ProductsForInspection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages
	|INTO Discrepancies
	|FROM
	|	(SELECT
	|		GoodsFilter.Products AS Products,
	|		GoodsFilter.Characteristic AS Characteristic,
	|		GoodsFilter.Purpose AS Purpose,
	|		GoodsFilter.Package AS Package,
	|		GoodsFilter.Series AS Series,
	|		GoodsFilter.CountPicked AS Count,
	|		GoodsFilter.NumberOfPackagesPicked AS NumberOfPackages
	|	FROM
	|		Document.GoodsPickingPlacement.GoodsFilter AS GoodsFilter
	|	WHERE
	|		GoodsFilter.Ref.Posted
	|		AND GoodsFilter.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
	|		AND GoodsFilter.Ref.ReferenceOrder = &WarehouseDocument
	|
	|	UNION ALL
	|	
	|	SELECT
	|		ProductsForInspection.Products,
	|		ProductsForInspection.Characteristic,
	|		ProductsForInspection.Purpose,
	|		ProductsForInspection.Package,
	|		ProductsForInspection.Series,
	|		-ProductsForInspection.CountReal AS Count, 
	|		-ProductsForInspection.NumberOfPackagesReal AS NumberOfPackages
	|	FROM
	|		ProductsForInspection AS ProductsForInspection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		Goods.Purpose,
	|		Goods.Package,
	|		Goods.Series,
	|		CASE
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|				THEN CASE
	|						WHEN Goods.Ref.WarehouseDocument = &WarehouseDocument
	|							THEN -Goods.Count
	|						ELSE Goods.Count
	|					END
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -Goods.Count
	|			ELSE Goods.Count
	|		END,
	|		CASE
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|				THEN CASE
	|						WHEN Goods.Ref.WarehouseDocument = &WarehouseDocument
	|							THEN -Goods.NumberOfPackages
	|						ELSE Goods.NumberOfPackages
	|					END
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -Goods.NumberOfPackages
	|			ELSE Goods.NumberOfPackages
	|		END
	|	FROM
	|		Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS Goods
	|	WHERE
	|		Goods.Ref.Posted
	|		AND (Goods.Ref.WarehouseDocument = &WarehouseDocument
	|				OR Goods.Ref.RecipientNote = &WarehouseDocument)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShippedGoods.Products,
	|		ShippedGoods.Characteristic,
	|		ShippedGoods.Purpose,
	|		ShippedGoods.Package,
	|		CASE
	|			WHEN NOT ShippedGoods.BatchesIndicationStatus IN (0, 1, 2)
	|				THEN ShippedGoods.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END,
	|		-ShippedGoods.Count,
	|		-ShippedGoods.NumberOfPackages
	|	FROM
	|		Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|	WHERE
	|		ShippedGoods.Ref = &WarehouseDocument
	|		AND ShippedGoods.Action IN (VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship), VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip))
	|		) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Discrepancies.Products,
	|	Discrepancies.Characteristic,
	|	Discrepancies.Purpose,
	|	Discrepancies.Package,
	|	Discrepancies.Series,
	|	CASE
	|		WHEN Discrepancies.NumberOfPackages < 0
	|			THEN VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|		ELSE VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|	END AS OperationKind,
	|	CASE
	|		WHEN Discrepancies.Count < 0
	|			THEN -Discrepancies.Count
	|		ELSE Discrepancies.Count
	|	END AS Count,
	|	CASE
	|		WHEN Discrepancies.NumberOfPackages < 0
	|			THEN -Discrepancies.NumberOfPackages
	|		ELSE Discrepancies.NumberOfPackages
	|	END AS NumberOfPackages
	|FROM
	|	Discrepancies AS Discrepancies
	|WHERE
	|	Discrepancies.NumberOfPackages <> 0";
	
	Query.SetParameter("ProductsForInspection", ProductsForInspection.Unload());
	Query.SetParameter("WarehouseDocument", Ref);
	
	TableOfDiscrepancies = Query.Execute().Unload();
	
	If TableOfDiscrepancies.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DocumentDiscrepanciesObject = Documents.InventoryAdjustmentGoodsShipmentOrder.CreateDocument();
	
	DocumentDiscrepanciesObject.Date = CurrentSessionDate();
	DocumentDiscrepanciesObject.EmployeeResponsible = User;
	DocumentDiscrepanciesObject.WarehouseDocument = Ref;
	DocumentDiscrepanciesObject.Warehouse = Warehouse;
	DocumentDiscrepanciesObject.Premise = Premise;
	DocumentDiscrepanciesObject.ShippingZone = ShippingZone;
	
	DocumentDiscrepanciesObject.Goods.Load(TableOfDiscrepancies);
	SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.SeriesSpecificationParameters(DocumentDiscrepanciesObject, Documents.InventoryAdjustmentGoodsShipmentOrder);
	MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(DocumentDiscrepanciesObject, SeriesSpecificationParameters);
	
	Return DocumentDiscrepanciesObject;
	
EndFunction

&AtServer
Function ThereIsShortageSurplusBatchError()
	
	Result = New Structure("BatchError", False);
	
	If ThereAreErrorsInSpecifyingBatches() Then  
		Result.Insert("BatchError", True);
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table_To_Check.NumberOfPackagesIsDifference AS Difference
		|INTO
		|	TTShortage
		|FROM
		|	&Table_To_Check AS Table_To_Check 
		|WHERE
		|	Table_To_Check.NumberOfPackagesIsDifference > 0
		|; 
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table_To_Check.NumberOfPackagesIsDifference AS Difference
		|INTO
		|	TTSurplus
		|FROM
		|	&Table_To_Check AS Table_To_Check 
		|WHERE
		|	Table_To_Check.NumberOfPackagesIsDifference < 0";
	
	Query.SetParameter("Table_To_Check", ProductsForInspection.Unload());
	
	QueryResult =  Query.ExecuteBatch();
	SamplingShortage = QueryResult[0].Select();
	SamplingShortage.Next();
	SamplingSurplus = QueryResult[1].Select();
	SamplingSurplus.Next();
	
	Result.Insert("Shortage", ?(SamplingShortage[0] > 0, True, False)); 
	Result.Insert("Surplus", ?(SamplingSurplus[0] > 0, True, False));
	
	Return Result;
	
EndFunction

&AtServer
Function ShipWithoutVerification(Mode)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsForInspection.Products,
	|	ProductsForInspection.Characteristic,
	|	ProductsForInspection.Purpose,
	|	ProductsForInspection.Package,
	|	ProductsForInspection.Series,
	|	ProductsForInspection.Count AS Count,
	|	ProductsForInspection.NumberOfPackages AS NumberOfPackages,
	|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship) AS Action
	|INTO ProductsForInspection
	|FROM 
	|	&ProductsForInspection AS ProductsForInspection	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForPicking.Products,
	|	GoodsForPicking.Characteristic,
	|	GoodsForPicking.Purpose,
	|	GoodsForPicking.Package,
	|	GoodsForPicking.Series,
	|	GoodsForPicking.Count AS Count,
	|	GoodsForPicking.NumberOfPackages AS NumberOfPackages,
	|	GoodsForPicking.Action AS Action
	|INTO GoodsForPicking
	|FROM 
	|	&GoodsForPicking AS GoodsForPicking 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsDoNotShip.Products,
	|	GoodsDoNotShip.Characteristic,
	|	GoodsDoNotShip.Purpose,
	|	GoodsDoNotShip.Package,
	|	GoodsDoNotShip.Series,
	|	GoodsDoNotShip.Count AS Count,
	|	GoodsDoNotShip.NumberOfPackages AS NumberOfPackages,
	|	GoodsDoNotShip.Action
	|INTO GoodsDoNotShip
	|FROM 
	|	&GoodsDoNotShip AS GoodsDoNotShip
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Package,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Count AS Count,
	|	GoodsForIssue.NumberOfPackages AS NumberOfPackages,
	|	GoodsForIssue.Action
	|INTO GoodsForIssue
	|FROM 
	|	&GoodsForIssue AS GoodsForIssue 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages,
	|	NestedQuery.Action
	|FROM 
	|	(SELECT
	|		ProductsForInspection.Products,
	|		ProductsForInspection.Characteristic,
	|		ProductsForInspection.Purpose,
	|		ProductsForInspection.Package,
	|		ProductsForInspection.Series,
	|		ProductsForInspection.Count AS Count,
	|		ProductsForInspection.NumberOfPackages AS NumberOfPackages,
	|		ProductsForInspection.Action
	|	FROM
	|		ProductsForInspection AS ProductsForInspection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForPicking.Products,
	|		GoodsForPicking.Characteristic,
	|		GoodsForPicking.Purpose,
	|		GoodsForPicking.Package,
	|		GoodsForPicking.Series,
	|		GoodsForPicking.Count,
	|		GoodsForPicking.NumberOfPackages,
	|		GoodsForPicking.Action
	|	FROM
	|		GoodsForPicking AS GoodsForPicking
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsDoNotShip.Products,
	|		GoodsDoNotShip.Characteristic,
	|		GoodsDoNotShip.Purpose,
	|		GoodsDoNotShip.Package,
	|		GoodsDoNotShip.Series,
	|		GoodsDoNotShip.Count,
	|		GoodsDoNotShip.NumberOfPackages,
	|		GoodsDoNotShip.Action
	|	FROM
	|		GoodsDoNotShip AS GoodsDoNotShip
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssue.Products,
	|		GoodsForIssue.Characteristic,
	|		GoodsForIssue.Purpose,
	|		GoodsForIssue.Package,
	|		GoodsForIssue.Series,
	|		GoodsForIssue.Count,
	|		GoodsForIssue.NumberOfPackages,
	|		GoodsForIssue.Action
	|	FROM
	|		GoodsForIssue AS GoodsForIssue) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Action"; 
	
	Query.SetParameter("ProductsForInspection", ProductsForInspection.Unload());
	Query.SetParameter("GoodsForPicking", GoodsForPicking.Unload());
	Query.SetParameter("GoodsDoNotShip", GoodsDoNotShip.Unload());
	Query.SetParameter("GoodsForIssue", GoodsForIssue.Unload());
	
	ShippedGoods = Query.Execute().Unload();
	
	BeginTransaction();
	Try
		OrderObject_ = Ref.GetObject();
		
		OrderObject_.Premise   = Premise;
		OrderObject_.Comment = Comment;
		OrderObject_.ShippingZone = ShippingZone;
		
		If Mode = "ShipComplete" Then
			OrderObject_.Status = Enums.GoodsIssueNoteStatuses.Verified;
		Else
			OrderObject_.Status     = Enums.GoodsIssueNoteStatuses.ToShip;
			OrderObject_.ShippedBy = User;
		EndIf;
		
		OrderObject_.ShippedGoods.Load(ShippedGoods);
		
#If Not MobileStandaloneServer Then
		OrderObject_.PackageBarcodes.Clear();
		For Each StringBC In PackageBarcodes Do
			NewRow = OrderObject_.PackageBarcodes.Add();
			NewRow.PackageBarcode = StringBC.PackageBarcode;
		EndDo;

		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(OrderObject_, Documents.GoodsIssueNote);
		ProductsServer.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.ShippedGoods);

		OrderObject_.Write(DocumentWriteMode.Posting);
#Else
		SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.SeriesSpecificationParameters(OrderObject_, Documents.GoodsIssueNote);
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.ShippedGoods);

		OrderObject_.Write(DocumentWriteMode.Write);
#EndIf

		CommitTransaction();
	Except
		RollbackTransaction();

		ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Не удалось записать %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = 'Kaydedilemedi%1. %2'"), Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return False;
	EndTry;
	
	Return True;
	
EndFunction

&AtServer
Function FinishShipmentOnServer()
	
	BeginTransaction();
	Try
		
		OrderObject_ = Ref.GetObject();
		
		OrderObject_.Status      = Enums.GoodsIssueNoteStatuses.Shipped_;
		OrderObject_.Premise   = Premise;
		OrderObject_.Comment = Comment;
		OrderObject_.ShippingZone = ShippingZone;
		OrderObject_.ShippedBy = User;
			
		SeriesSpecificationParameters = New FixedStructure(MobileWarehouseKeeperWorkspace.SeriesSpecificationParameters(OrderObject_, Documents.GoodsIssueNote));
		MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(OrderObject_, SeriesSpecificationParameters.ShippedGoods);

#If Not MobileStandaloneServer Then
		OrderObject_.PackageBarcodes.Clear();
		For Each StringBC In PackageBarcodes Do		
			NewRow = OrderObject_.PackageBarcodes.Add();
			NewRow.PackageBarcode = StringBC.PackageBarcode;
		EndDo;

		OrderObject_.Write(DocumentWriteMode.Posting);
#Else
		OrderObject_.Write(DocumentWriteMode.Write);
#EndIf
		CommitTransaction();
	Except
		RollbackTransaction();

		ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Не удалось записать %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = 'Kaydedilemedi%1. %2'"), Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return False;
	EndTry;
	
	Return True;
	
EndFunction

&AtServer
Procedure FillInAcceptanceArea()
	
	ShippingZone = MobileWarehouseKeeperWorkspace.DefaultAcceptanceZone(Warehouse, Premise);
	
EndProcedure

&AtClient
Procedure ShowMenu()

	Items.MenuGroup_2.Visible = True;
	Items.CommandGroup.Visible = True;
	Items.DocumentInformation.Visible = True;
	Items.InformationAboutRecipient.Visible = True;
	
EndProcedure

&AtClient
Procedure HideMenu()

	Items.MenuGroup_2.Visible = False;
	Items.CommandGroup.Visible = False;
	Items.DocumentInformation.Visible = False;
	Items.InformationAboutRecipient.Visible = False;
	
EndProcedure

&AtServer
Function ShipmentIsAllowed(ProductProperties_3, Count, NewRow = False)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", ProductProperties_3.Products);
	TheStructureOfTheSearch.Insert("Characteristic", ProductProperties_3.Characteristic);
	TheStructureOfTheSearch.Insert("Purpose", ProductProperties_3.Purpose);

	SeriesOnShipment = SeriesOfItemsForShipment(ProductProperties_3.Products);

	If SeriesOnShipment.SpecifyWhenPlanningShipment Then
		TheStructureOfTheSearch.Insert("Series", ProductProperties_3.Series);
	EndIf;
		
	AvailableForShipment = 0;
	SearchResult = GoodsByReferences.FindRows(TheStructureOfTheSearch);
	
	For Each FoundRow In SearchResult Do
		PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(FoundRow.Package, FoundRow.Products);
		AvailableForShipment = AvailableForShipment + FoundRow.Count * PackagingFactor;
	EndDo;

	If NewRow Then 
		SearchResult = ProductsForInspection.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In SearchResult Do
			Count = Count + FoundRow.Count;
		EndDo;
	EndIf;
	
	If Count > AvailableForShipment Then
		ErrorText = NStr("vi = 'Số lượng hàng hóa được xuất theo hóa đơn nhiều hơn số lượng cần xuất theo lệnh xuất hàng.';
						|ru = 'Количество товара, которое отгружается ордером, больше чем нужно отгрузить по распоряжениям на отгрузку.';
						|en = 'The quantity of items shipped by the note is greater than required to be shipped under the shipment references.'; fa = 'The quantity of items shipped by the note is greater than required to be shipped under the shipment references.';
						|it = 'The quantity of items shipped by the note is greater than required to be shipped under the shipment references.';
						|pl = 'The quantity of items shipped by the note is greater than required to be shipped under the shipment references.';
						|tr = 'Emirle sevk edilen ürün miktarı, sevkiyat talimatlarına göre sevk edilmesi gerekenden fazla.'");
		Return False;
	EndIf;
	
#If Not MobileStandaloneServer Then
	If (SeriesOnShipment.SpecifyWhenPlanningPicking
		Or SeriesOnShipment.SpecifyWhenPlanningShipment)
		And SeriesOnShipment.AccountForRemainingSeries Then
		
		AvailableQuantity = 0;

		Query = New Query; 
		Query.Text = 
		"SELECT ALLOWED
		|	DataOfRegister.Series AS Series,
		|	SUM(DataOfRegister.AvailableStock) AS AvailableStock
		|FROM
		|	(SELECT
		|		ProductStockBalance.Series AS Series,
		|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.ProductStock.Balance(
		|				,
		|				Products = &Products
		|					AND Characteristic = &Characteristic
		|					AND (Purpose = &Purpose
		|						OR Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|					AND Warehouse = &Warehouse
		|					AND Premise = &Premise
		|					AND Series = &Series) AS ProductStockBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductStock.Series,
		|		CASE
		|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ProductStock.InStock + ProductStock.ToShip
		|			ELSE ProductStock.InStock - ProductStock.ToShip
		|		END
		|	FROM
		|		AccumulationRegister.ProductStock AS ProductStock
		|	WHERE
		|		ProductStock.Products = &Products
		|		AND ProductStock.Characteristic = &Characteristic
		|		AND (ProductStock.Purpose = &Purpose
		|						OR ProductStock.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT CAST(&Purpose AS Catalog.Assignments).RecordsInWarehouseRegisters)
		|		AND ProductStock.Warehouse = &Warehouse
		|		AND ProductStock.Premise = &Premise
		|		AND ProductStock.Recorder = &Recorder
		|		AND ProductStock.Series = &Series) AS DataOfRegister
		|
		|GROUP BY
		|	DataOfRegister.Series";

		Query.SetParameter("Purpose", ProductProperties_3.Purpose);
		Query.SetParameter("Products", ProductProperties_3.Products);
		Query.SetParameter("Series", ProductProperties_3.Series);
		Query.SetParameter("Characteristic", ProductProperties_3.Characteristic);
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("Premise", Premise);
		Query.SetParameter("Recorder", Ref);

		SelectionDetailRecords = Query.Execute().Select();

		While SelectionDetailRecords.Next() Do
			AvailableQuantity = AvailableQuantity + SelectionDetailRecords.AvailableStock;
		EndDo;
		
		If Count > AvailableQuantity Then
			ErrorText = StrTemplate(NStr("vi = 'Số lượng xuất vượt quá tồn kho tại kho là %1.';
										|ru = 'Отгружаемое количество превышает остатки на складе на %1.';
										|en = 'The quantity to ship exceeds the warehouse balance on %1.'; fa = 'The quantity to ship exceeds the warehouse balance on %1.';
										|it = 'The quantity to ship exceeds the warehouse balance on %1.';
										|pl = 'The quantity to ship exceeds the warehouse balance on %1.';
										|tr = 'Sevk edilen miktar, ambar stoklarını %1 kadar aşıyor.'"), Count - AvailableQuantity);
			Common.MessageToUser(ErrorText);
			Return False;
		EndIf;

	EndIf;
	
	Return True;
#Else
	Return True;
#EndIf

EndFunction

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction

&AtClient
Procedure AfterClosingVerificationIssue(Result  = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = "Continue" Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("ProcessName", "FinishCheck");
	AdditionalParameters.Insert("Mode", Result);
	Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject, AdditionalParameters);
	
	ValueList = New ValueList();
	
	If Result = "Ship" Or Result = "ShipWithoutVerification" Then 
		
		ValueList.Add("Ship", NStr("vi = 'Chuyển đến giao hàng';
									|ru = 'Перейти к отгрузке';
									|en = 'Go to shipment'; fa = 'Go to shipment';
									|it = 'Go to shipment';
									|pl = 'Go to shipment';
									|tr = 'Sevkiyata git'"));
		ValueList.Add("ShipComplete", NStr("vi = 'Kết thúc làm việc với phiếu';
											|ru = 'Завершить работу с ордером';
											|en = 'Close the note'; fa = 'Close the note';
											|it = 'Close the note';
											|pl = 'Close the note';
											|tr = 'Siparişle çalışmayı tamamla'"));
		ValueList.Add("Continue", NStr("vi = 'Tiếp tục kiểm tra';
										|ru = 'Продолжить проверку';
										|en = 'Continue checking'; fa = 'ادامه بررسی';
										|it = 'Continuare la verifica';
										|pl = 'Kontynuuj weryfikację';
										|tr = 'Kontrolü devam et'"));
		MessageText = NStr("vi = 'Sau khi kết thúc kiểm tra, bạn muốn chuyển đến giao phiếu hay kết thúc làm việc với phiếu hiện tại?';
							|ru = 'После завершения проверки перейти к отгрузке ордера или завершить работу с текущим ордером?';
							|en = 'After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?'; fa = 'After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?';
							|it = 'After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?';
							|pl = 'After the check is completed, do you want to proceed to shipping the goods issue or close the current goods issue?';
							|tr = 'Kontrolü tamamladıktan sonra sipariş sevkiyatına devam etmek veya mevcut siparişle çalışmayı bitirmek istiyor musunuz?'");
		
		ShowQueryBox(Notification, MessageText, ValueList, 0);
		
	ElsIf Result = "Pick" Then
		
		If UsedFormServer = UsedServer.Main Then

			ValueList.Add("Pick", NStr("vi = 'Chuyến đến lọc';
										|ru = 'Перейти к отбору';
										|en = 'Go to filter'; fa = 'رفتن به فیلتر';
										|it = 'Passa a selezione';
										|pl = 'Przejdź do filtru';
										|tr = 'Filtreye git'"));
			ValueList.Add("SelectComplete", NStr("vi = 'Kết thúc làm việc với phiếu';
												|ru = 'Завершить работу с ордером';
												|en = 'Close the note'; fa = 'Close the note';
												|it = 'Close the note';
												|pl = 'Close the note';
												|tr = 'Siparişle çalışmayı tamamla'"));
			ValueList.Add("Continue", NStr("vi = 'Tiếp tục kiểm tra';
											|ru = 'Продолжить проверку';
											|en = 'Continue checking'; fa = 'ادامه بررسی';
											|it = 'Continuare la verifica';
											|pl = 'Kontynuuj weryfikację';
											|tr = 'Kontrolü devam et'"));
			MessageText = NStr("vi = 'Sau khi kết thúc kiểm tra, bạn muốn chuyển đến lấy hàng từ phiếu hay kết thúc làm việc với phiếu hiện tại?';
								|ru = 'После завершения проверки перейти к отбору ордера или завершить работу с текущим ордером?';
								|en = 'After the check is completed, do you want to proceed to picking the goods issue or close the current goods issue?'; fa = 'After the check is completed, do you want to proceed to picking the goods issue or close the current goods issue?';
								|it = 'After the check is completed, do you want to proceed to picking the goods issue or close the current goods issue?';
								|pl = 'After the check is completed, do you want to proceed to picking the goods issue or close the current goods issue?';
								|tr = 'Kontrolü tamamladıktan sonra sipariş filtrelemeye devam etmek veya mevcut siparişle çalışmayı bitirmek istiyor musunuz?'");

			ShowQueryBox(Notification, MessageText, ValueList, 0);

		Else
			AfterClosingQuestion_("SelectComplete", AdditionalParameters);
		EndIf;

	Else
		AfterClosingQuestion_(Result, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion_(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = "Continue" Then
		Return;
	EndIf;
	
	If AdditionalParameters.ProcessName = "CompleteSelection_" Then
		
		FilterCompleted = FinishSelectionOnServer(Result);
		If Result = "ExitApp" And FilterCompleted Then
			Close();
		ElsIf Result = "Validate" And FilterCompleted Then
			FillOutFormAgain();
			OpenMenuByStatus();
		Else
			Status(ErrorText);
		EndIf; 
		
	ElsIf AdditionalParameters.ProcessName = "FinishCheck" Then
		
		If AdditionalParameters.Mode = "ShipWithoutVerification" Then
			CheckIsCompleted = ShipWithoutVerification(Result);
		Else
			CheckIsCompleted = FinishCheckingOnServer(Result);
		EndIf;
		
		If (Result = "ShipComplete" Or Result = "SelectComplete"
			Or Result = "SurplusComplete") And CheckIsCompleted Then
			Close();
		ElsIf (Result = "Ship" Or Result = "Pick"
			Or Result = "SurplusToShip") And CheckIsCompleted Then
				
			If UseBinLocationWarehousing And Result = "Pick" Then
				CreateNewSelectionOfItems();
				Return;
			EndIf;

			FillOutFormAgain();
			OpenMenuByStatus();
		Else
			Status(ErrorText);
		EndIf;
		
	ElsIf AdditionalParameters.ProcessName = "CompleteShipment" Then  
		
		ShipmentCompleted = FinishShipmentOnServer();
		
		If ShipmentCompleted Then  
			Close();
		Else
			Status(ErrorText);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestionForm(Result = Undefined, AdditionalParameters = Undefined) Export

	If Result = Undefined Then
		Return;
	EndIf;

	If Result = "Continue" Then
		Return;
	EndIf;

	If Result = "ShipWithoutVerification" Then
		CheckIsCompleted = ShipWithoutVerification("ShipComplete");
	Else
		CheckIsCompleted = FinishCheckingOnServer(Result);
	EndIf;

	If CheckIsCompleted Then

		If UseBinLocationWarehousing And Result = "Pick" Then
			CreateNewSelectionOfItems();
			Return;
		EndIf;

		FillOutFormAgain();
		OpenMenuByStatus();
	Else
		Status(ErrorText);
	EndIf;

EndProcedure

&AtClient
Procedure AfterClosingQuestionSpecifyingBatches(Result, AdditionalParameters = Undefined) Export
	
	If Result = "Continue" Then
		Return;
	EndIf;
	
	BatchIndicationCompleted = FinishSpecifyingBatches();
	
	If Result = "Pick" And BatchIndicationCompleted Then 
		
		RefFilter = NewSelectionOfGoods(Ref);
		If ValueIsFilled(RefFilter) Then
			Close();
			FormParameters = New Structure;
			FormParameters.Insert("Ref", RefFilter);
			FormParameters.Insert("Performer", Performer);
			FormParameters.Insert("Seamless", True);
			FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
			FormParameters.Insert("ScanningProcedure", ScanningProcedure);

			OpenForm(
				"DataProcessor.MobileWarehouseKeeperWorkspace.Form.Filter", FormParameters);
			Return;
		Else
			ErrorText = NStr("vi = 'Không thể thực hiện nhiệm vụ lấy ra hàng hóa theo quy tắc lấy ra.';
							|ru = 'Не удалось сформировать задания на отбор товаров согласно правилам отбора.';
							|en = 'Cannot generate goods picking jobs according to the picking rules.'; fa = 'Cannot generate goods picking jobs according to the picking rules.';
							|it = 'Impossibile generare i task per la selezione delle merci secondo le regole di selezione.';
							|pl = 'Nie udało się utworzyć zadania na wybór towarów zgodnie z zasadami wyboru.';
							|tr = 'Filtre kurallarına göre ürün filtre görevleri oluşturulamadı.'");
			Status(ErrorText);
		EndIf;
		
	ElsIf Result = "SelectComplete" And BatchIndicationCompleted Then 
		
		Close();
		
	Else
		Status(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangePackageBarcodes(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ChangeBarcodesOfPackagesOnServer(Result);
	
EndProcedure

&AtServer
Procedure ChangeBarcodesOfPackagesOnServer(Result)
	
	PackageBarcodes.Clear();
	PackageBarcodes.Load(Result.Unload());
	
EndProcedure

&AtClient
Procedure AfterClosingIssueCancelShipment(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		ShipmentCancelled = CancelOrderShipmentATServer();
		
		If ShipmentCancelled Then
			If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
				Close();
			EndIf;
			Close();
		EndIf;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtServer
Function CancelOrderShipmentATServer()
	
#If MobileStandaloneServer Then
	Return False;
#Else
	Try
		DocumentObject = Ref.GetObject();
		DocumentObject.SetDeletionMark(True);
		
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Except
		Common.MessageToUser(NStr("vi = 'Không thể hủy giao hàng.';
									|ru = 'Не удалось отменить отгрузку.';
									|en = 'Cannot cancel the shipment.'; fa = 'Cannot cancel the shipment.';
									|it = 'Cannot cancel the shipment.';
									|pl = 'Cannot cancel the shipment.';
									|tr = 'Sevkiyat iptal edilemedi.'"));
		
		Return False;
	EndTry;
	
	Return True;
#EndIf

EndFunction

&AtClient
Function	HasFillingErrors()
	
	ClearMessages();
	
	If UseWarerooms And Premise.IsEmpty() Then

		Status(NStr("vi = 'Chưa chọn nhà kho';
					|ru = 'Не выбрано помещение';
					|en = 'Wareroom is not selected'; fa = 'Wareroom is not selected';
					|it = 'Locale non selezionato';
					|pl = 'Nie wybrano pomieszczenia';
					|tr = 'Alan seçilmedi'"));
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return True;
			
	EndIf;
	
	If UseBinLocationWarehousing And ShippingZone.IsEmpty() Then

		Status(NStr("vi = 'Chưa chọn khu vực giao hàng';
					|ru = 'Не выбрана зона отгрузки';
					|en = 'Outbound area is not selected'; fa = 'Outbound area is not selected';
					|it = 'Zona di spedizione non selezionata';
					|pl = 'Nie wybrano strefy wysyłki';
					|tr = 'Yükleme alanı seçilmedi'"));
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return True;
			
	EndIf;
	
	Return False;
	
EndFunction	
	
&AtServer
Procedure SetAvailabilityOfOrderEditing()
		
	If Status = Enums.GoodsIssueNoteStatuses.Prepared
		Or Status = Enums.GoodsIssueNoteStatuses.Verified Then
		
		Items.AssignMe.Visible = Not SpecifyingSeries; 
		Items.Done.Visible = SpecifyingSeries;
		Items.Scan.Visible = False;
	ElsIf Status = Enums.GoodsIssueNoteStatuses.ForChecking Then
		CheckingYourOrder = CheckOnlyYourNotes And Performer = User;
		CheckingSomeoneElseSOrder = CheckOnlyOtherNotes And Performer <> User;
	
		Items.AssignMe.Visible = CheckingYourOrder Or CheckingSomeoneElseSOrder Or CheckingAllOrders;
		Items.Scan.Visible = False;
	Else
		Items.AssignMe.Visible = False;
		Items.Done.Visible = SpecifyingSeries;
		Items.Scan.Visible = True;
	EndIf;
	
EndProcedure 

&AtServer
Procedure DoNotShipAtServer(RowIndex, TableName)
	
	CurrentRow = ThisObject[TableName][RowIndex];
	
	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(CurrentRow.Package, CurrentRow.Products);

	TheStructureOfTheSearch = ProductSearchStructure_();
	
	SeriesOnShipment = SeriesOfItemsForShipment(CurrentRow.Products);	
	If SeriesOnShipment.SpecifyWhenPlanningPicking Then
		TheStructureOfTheSearch.Delete("Series");
	EndIf; 
	FillPropertyValues(TheStructureOfTheSearch, CurrentRow);
	
	TheStructureOfTheSearch.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip);
	
	SearchResult = GoodsDoNotShip.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		NumberOfPackages = SearchResult[0].NumberOfPackages + CurrentRow.NumberOfPackages;
		Count = NumberOfPackages * PackagingFactor;
		
		SearchResult[0].NumberOfPackages = NumberOfPackages;
		SearchResult[0].Count = Count;
	Else
		NewRow = GoodsDoNotShip.Add();
		FillPropertyValues(NewRow, CurrentRow);
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.DoNotShip;
		If SeriesOnShipment.SpecifyWhenPlanningPicking Then
			NewRow.Series = Undefined;
		EndIf;
	EndIf;
	
	QuantityToDistribution = CurrentRow.Count;
			
	TheStructureOfTheSearch.Delete("Package");
	TheStructureOfTheSearch.Delete("Series");
	TheStructureOfTheSearch.Delete("Action");
		
	FoundOrders_ = GoodsByReferences.FindRows(TheStructureOfTheSearch);
	For Each OrderLine_2 In FoundOrders_ Do    
		If QuantityToDistribution >= OrderLine_2.Count Then
			QuantityToDistribution = QuantityToDistribution - OrderLine_2.Count;
			GoodsByReferences.Delete(OrderLine_2);
		Else
			OrderLine_2.Count = OrderLine_2.Count - QuantityToDistribution;
			QuantityToDistribution = 0;
		EndIf;
			
		If QuantityToDistribution = 0 Then
			Break;
		EndIf; 
	EndDo;
	
	ThisObject[TableName].Delete(RowIndex);
	
EndProcedure

&AtServer
Procedure AssignMeAtServer(CheckRights1 = False)
	
	If Status = Enums.GoodsIssueNoteStatuses.Prepared Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.ForPicking;
	ElsIf Status = Enums.GoodsIssueNoteStatuses.ForChecking Then
		VerificationIsPossible = True;
		If CheckRights1 Then
			CheckingYourOrder = CheckOnlyYourNotes And Performer = User;
			CheckingSomeoneElseSOrder = CheckOnlyOtherNotes And Performer <> User;

			VerificationIsPossible = CheckingYourOrder Or CheckingSomeoneElseSOrder Or CheckingAllOrders;
		EndIf;
		ErrorText = "";
		If Not VerificationIsPossible Then
			ErrorText = NStr("vi = 'Không đủ quyền để kiểm tra việc xuất hàng.';
							|ru = 'Недостаточно прав на проверку отгрузки.';
							|en = 'Insufficient rights to check the shipment.'; fa = 'Insufficient rights to check the shipment.';
							|it = 'Insufficient rights to check the shipment.';
							|pl = 'Insufficient rights to check the shipment.';
							|tr = 'Sevkiyat kontrolü için için erişim yetkisi yetersiz.'");
			Return;
		EndIf;
		NoteStatus = Enums.GoodsIssueNoteStatuses.DuringChecking;
	ElsIf Status = Enums.GoodsIssueNoteStatuses.Verified Then
		NoteStatus = Enums.GoodsIssueNoteStatuses.ToShip;
	EndIf;
	
	If Not DataProcessors.MobileWarehouseKeeperWorkspace.SetStatusOfOrder(Ref, NoteStatus, False) Then
		Return;
	EndIf;
	
	FillForm();
	SetAvailabilityOfOrderEditing();
	
EndProcedure  

&AtServer
Function SeriesOfItemsForShipment(Val Products)
	
	ProductKind =  MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Products, "ProductKind");
	BatchAccountingPolicy = DataProcessors.MobileWarehouseKeeperWorkspace.BatchAccountingPolicy(ProductKind, Warehouse);
	If ValueIsFilled(BatchAccountingPolicy) Then
		SeriesOnShipment = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(BatchAccountingPolicy, "SpecifyByPickingResult,
		|	SpecifyWhenPlanningPicking, SpecifyWhenPlanningShipment, AccountForRemainingSeries");
	Else
		SeriesOnShipment = New Structure("SpecifyByPickingResult,
		|	SpecifyWhenPlanningPicking, SpecifyWhenPlanningShipment", False, False, False);
		SeriesOnShipment.Insert("AccountForRemainingSeries", False);
	EndIf;
	
	Return SeriesOnShipment;
	
EndFunction 

&AtClient
Procedure OpenMenuByStatus()
	
	If Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking")
		Or Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared") Then
		CreateMenu_("ForPicking");
	ElsIf Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.DuringChecking")
		Or Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForChecking") Then
		CreateMenu_("ForChecking");
	Else
		CreateMenu_("ToShip");
	EndIf;
	
EndProcedure

&AtServer
Procedure BackToSelectionCheckingAtServer(RowIndex)
	 		
	CurrentRow = ProductsForInspection[RowIndex];
	
	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(CurrentRow.Package, CurrentRow.Products);
	
	TheStructureOfTheSearch = ProductSearchStructure_();
	
	SeriesOnShipment = SeriesOfItemsForShipment(CurrentRow.Products);	
	If SeriesOnShipment.SpecifyWhenPlanningPicking Then
		TheStructureOfTheSearch.Delete("Series");
	EndIf;
	FillPropertyValues(TheStructureOfTheSearch, CurrentRow);
	
	TheStructureOfTheSearch.Insert("Action", PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Pick"));
	
	SearchResult = GoodsForPicking.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		NumberOfPackages = SearchResult[0].NumberOfPackages + CurrentRow.NumberOfPackages;
		Count = NumberOfPackages * PackagingFactor;
		
		SearchResult[0].NumberOfPackages = NumberOfPackages;
		SearchResult[0].Count = Count;
	Else
		NewRow = GoodsForPicking.Add();
		FillPropertyValues(NewRow, CurrentRow); 
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;

		If SeriesOnShipment.SpecifyWhenPlanningPicking Then
			NewRow.Series = Undefined; 
		EndIf;
		
		If UseBinLocationWarehousingForInformation Then
			NewRow.MainStorageBin = ItemCell(CurrentRow.Products);
		EndIf;

	EndIf;
		
	ProductsForInspection.Delete(RowIndex);
	
EndProcedure

&AtServer
Procedure ReturnDoNotShipAtServer(RowIndex, TableName)
	
	CurrentRow = GoodsDoNotShip[RowIndex];
	
	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(CurrentRow.Package, CurrentRow.Products);

	TheStructureOfTheSearch = ProductSearchStructure_();
	
	SeriesOnShipment = SeriesOfItemsForShipment(CurrentRow.Products);
	If SeriesOnShipment.SpecifyWhenPlanningPicking 
		Or (Not UseGoodsIssueNoteStatuses And SeriesOnShipment.SpecifyByPickingResult) Then
		TheStructureOfTheSearch.Delete("Series");
	EndIf;
	
	FillPropertyValues(TheStructureOfTheSearch, CurrentRow);
		
	TheStructureOfTheSearch.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick);
	
	SearchResult = ThisObject[TableName].FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		NumberOfPackages = SearchResult[0].NumberOfPackages + CurrentRow.NumberOfPackages;
		Count = NumberOfPackages * PackagingFactor;
		
		SearchResult[0].NumberOfPackages = NumberOfPackages;
		SearchResult[0].Count = Count;
	Else
		NewRow = ThisObject[TableName].Add();
		FillPropertyValues(NewRow, CurrentRow); 
		NewRow.Count = NewRow.NumberOfPackages * PackagingFactor;
		NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;

		If SeriesOnShipment.SpecifyWhenPlanningPicking 
			Or (Not UseGoodsIssueNoteStatuses And SeriesOnShipment.SpecifyByPickingResult) Then
			NewRow.Series = Undefined;
		EndIf; 
		
		If UseBinLocationWarehousingForInformation Then
			NewRow.MainStorageBin = ItemCell(CurrentRow.Products);
		EndIf;
	EndIf;
	
	TheStructureOfTheSearch.Delete("Package");
	TheStructureOfTheSearch.Delete("Series");
	TheStructureOfTheSearch.Delete("Action");
		
	FoundOrders_ = GoodsByReferences.FindRows(TheStructureOfTheSearch);
	
	If FoundOrders_.Count() > 0 Then 	
		FoundOrders_[0].Count = FoundOrders_[0].Count + CurrentRow.Count;
	Else
		NewRow = GoodsByReferences.Add();
		FillPropertyValues(NewRow, CurrentRow);
		NewRow.Count = CurrentRow.NumberOfPackages * PackagingFactor; 
	EndIf;
	
	GoodsDoNotShip.Delete(RowIndex);
	If Not GoodsDoNotShip.Count() Then
		FilterGoods = "Shipped_1";
		GoodsFilterDisplayTable();
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsFilterDisplayTable()
	
	If FilterGoods = "Unshipped" Then
		Items.GroupPages.CurrentPage = Items.DonTShipPage;
	ElsIf Items.SelectionCommand.TextColor = WebColors.Black Then
		Items.GroupPages.CurrentPage = Items.PageToSelect;
	ElsIf Items.CommandToCheck.TextColor = WebColors.Black Then
		Items.GroupPages.CurrentPage = Items.PageToCheck;
	ElsIf Items.CommandToShip.TextColor = WebColors.Black Then 
		Items.GroupPages.CurrentPage = Items.PageForShipment;
	EndIf;
		
EndProcedure

&AtServer
Function ItemCell(Products)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(MainStorageBins.Cell.Code, """") AS MainStorageBin
	|FROM
	|	InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|WHERE
	|	MainStorageBins.Products = &Products 
	|	AND MainStorageBins.MainStorageBin
	|	AND MainStorageBins.Warehouse = &Warehouse 
	|	AND CASE
	|		WHEN &UseWarerooms
	|			AND &DateOfShipment >= &StartDateOfWareroomUse
	|			THEN MainStorageBins.Premise = &Premise
	|		ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|	END";
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("UseWarerooms", UseWarerooms);
	Query.SetParameter("DateOfShipment", DateOfShipment);
	Query.SetParameter("StartDateOfWareroomUse", StartDateOfWareroomUse);
	Query.SetParameter("Premise", Premise);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.MainStorageBin;
	EndIf;
	
	Return "";
	
EndFunction

&AtServer
Function ProductSearchStructure_()
	
	Structure = New Structure;
	Structure.Insert("Products","");
	Structure.Insert("Characteristic","");
	Structure.Insert("Series","");
	Structure.Insert("Purpose","");
	Structure.Insert("Package","");
	
	Return Structure;
	
EndFunction

&AtClient
Procedure CreateNewSelectionOfItems()

	RefFilter = NewSelectionOfGoods(Ref);
	If ValueIsFilled(RefFilter) Then

		Close();

		FormParameters = New Structure;
		FormParameters.Insert("Ref", RefFilter);
		FormParameters.Insert("Performer", Performer);
		FormParameters.Insert("Seamless", True);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Barcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm("DataProcessor.MobileWarehouseKeeperWorkspace.Form.Filter", FormParameters,
			ThisObject,,,,, FormWindowOpeningMode.Independent);

	Else
		ErrorText = NStr("vi = 'Không thể thực hiện nhiệm vụ lấy ra hàng hóa theo quy tắc lấy ra.';
						|ru = 'Не удалось сформировать задания на отбор товаров согласно правилам отбора.';
						|en = 'Cannot generate goods picking jobs according to the picking rules.'; fa = 'Cannot generate goods picking jobs according to the picking rules.';
						|it = 'Impossibile generare i task per la selezione delle merci secondo le regole di selezione.';
						|pl = 'Nie udało się utworzyć zadania na wybór towarów zgodnie z zasadami wyboru.';
						|tr = 'Filtre kurallarına göre ürün filtre görevleri oluşturulamadı.'");
		Status(ErrorText);
	EndIf;

EndProcedure

&AtServerNoContext
Function NewSelectionOfGoods(LinkSpendingOrder)
		
	Return DataProcessors.MobileWarehouseKeeperWorkspace.NewSelectionOfGoods(LinkSpendingOrder);

EndFunction

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
