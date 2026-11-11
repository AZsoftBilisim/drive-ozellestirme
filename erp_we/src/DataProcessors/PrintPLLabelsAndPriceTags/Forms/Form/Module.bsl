#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FilterVisibility = False;
	
	PrintPLLabelsAndPriceTagsOverridable.WhenDeterminingRedefinitionOfSelectionOfGoods(MatchingFormHasBeenRedefined);
	PrintPLLabelsAndPriceTagsOverridable.WhenDeterminingWhetherToOverrideBarcodeMatching(BarcodeSearchFormHasBeenRedefined);
	PrintPLLabelsAndPriceTagsOverridable.WhenDeterminingRedefinitionOfVTSDUpload(VTSDUploadFormHasBeenRedefined);
	PrintPLLabelsAndPriceTagsOverridable.WhenDeterminingRedefinitionOfSelection(SelectionFormHasBeenRedefined);
	
	PricesAsOfDate = CurrentSessionDate();
	If Not ValueIsFilled(Object.PrintMode) Then
		Object.PrintMode = "PrintingPriceTags";
	EndIf;
	DownloadSelectionSettings();
	
	SetVisibilityAndAccessibilityOfFormElements();
	SetVisibilityOfTableElementsAndColumns();
	
	PrintPLLabelsAndPriceTagsOverridable.FormPrintsLabelsAndPriceTagsWhenCreatedOnServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	ThisObject.UsePeripherals = True;
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner, MagneticStripeCardReaders");
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	// End Peripherals
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalEvent(Source, Event, Data)
	
	If IsInputAvailable() Then
		RawData = Data;
		
		GS1Separator = CommonCELClientServer.GS1Separator();
		EscapedCharacterGS1 = CommonCELClientServer.EscapedCharacterGS1();
		Data = StrReplace(Data, GS1Separator, EscapedCharacterGS1);
		
		EventDescription1 = New Structure();
		ErrorDescription  = "";
		EventDescription1.Insert("Source", Source);
		EventDescription1.Insert("Event",  Event);
		EventDescription1.Insert("Data",   Data);
		
		Result = EquipmentManagerClient.GetEventFromDevice(EventDescription1, ErrorDescription);
		If Result = Undefined Then 
			MessageText = NStr("vi = 'Khi xử lý sự kiện ngoài từ thiết bị, đã xảy ra lỗi:';
								|ru = 'При обработке внешнего события от устройства произошла ошибка:';
								|en = 'An error occurred when processing an external event from the device:'; fa = 'An error occurred when processing an external event from the device:';
								|it = 'Si è verificato un errore durante l''elaborazione di un evento esterno al dispositivo:';
								|pl = 'Przy przetwarzaniu zdarzenia zewnętrznego od urządzenia zaistniał błąd:';
								|tr = 'Harici olayın cihazdan işlenmesi sırasında bir hata oluştu:'")
			+ Chars.LF + ErrorDescription;
			CommonCELClient.MessageToUser(MessageText);
		Else
			If Result.Source = "Peripherals" Then
				If Result.EventName = "ScanData" Then
					
					NotificationData = Result.Parameter;
					CallbackDescription = New CallbackDescription("NotificationOfBarCodeSearchForBPOLabelsAndPriceTags", ThisObject);
					RunCallback(CallbackDescription, NotificationData);
					
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If IsInputAvailable() Then
		If EventName = "ScanData" Then
			
			NotificationData = Parameter[0];
			CallbackDescription = New CallbackDescription("NotificationOfBarCodeSearchForBPOLabelsAndPriceTags", ThisObject);
			RunCallback(CallbackDescription, NotificationData);
			
		EndIf;
	EndIf;
	
	If EventName = "FillInDataOfLabelsAndPriceTags" Then
		
		For Each OwnGoods In Parameter Do
			
			FilterParameters = New Structure;
			FilterParameters.Insert("Barcode", OwnGoods.Barcode);
			SearchBars = Object.Goods.FindRows(FilterParameters);
			
			If SearchBars.Count() = 0 Then
				NewRow = Object.Goods.Add();
				FillPropertyValues(NewRow, OwnGoods);
			Else
				SearchBars[0].Count = SearchBars[0].Count + OwnGoods.Count;
			EndIf;
			
		EndDo;
	EndIf;
	
	PrintPLLabelsAndPriceTagsClientOverridable.NotificationProcessing(EventName, Parameter, Source, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelectedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentRow = CurrentData.LineNumber - 1;
	
	If Not CurrentData.Selected Then
		CurrentData.Selected = False;
	Else
		
		CurrentData.Selected = True;
		
		If Not ValueIsFilled(CurrentData.PriceTagLabelTemplate) Then
			
			Message = New UserMessage;
			Message.Text = NStr("vi = 'Chưa chọn mẫu in';
								|ru = 'Не выбран шаблон печати';
								|en = 'Print template is not selected'; fa = 'Print template is not selected';
								|it = 'Non è stato selezionato il modello di stampa';
								|pl = 'Nie wybrano szablonu wydruku';
								|tr = 'Yazdırma şablonu seçilmedi'");
			Message.Field = "Object.Goods["+CurrentRow+"].PriceTagLabelTemplate";
			Message.Message();
			
			CurrentData.Selected = False;
			
		ElsIf Not ValueIsFilled(CurrentData.Count) Then
			
			Message = New UserMessage;
			Message.Text = NStr("vi = 'Chưa đặt số lượng nhãn giá';
								|ru = 'Не задано количество ценников';
								|en = 'Number of price tags is not set'; fa = 'Number of price tags is not set';
								|it = 'Quantità cartellini non indicata';
								|pl = 'Nie określono ilości cenników';
								|tr = 'Fiyat etiketleri miktarı ayarlanmadı'");
			Message.Field = "Object.Goods["+CurrentRow+"].Count";
			Message.Message();
			
			CurrentData.Selected = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsPrintTemplateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.Selected = CheckProductSelectionOption(CurrentData);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PriceKindOnChange(Item)
	
	PriceKindOnChangeServer();
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtClient
Procedure SelectGoods(Command)
	PickUpProductsOnClient();
EndProcedure

&AtClient
Procedure FillInByPicking(Command)
	
	If Object.Goods.Count() = 0 Then
		FillInBySelectionOnClient();
	Else
		
		CallbackDescription = New CallbackDescription("NotificationFillInTableOfProducts", ThisObject);
		ShowQueryBox(CallbackDescription, NStr("vi = 'Lưu dữ liệu về số lượng, khuôn mẫu trong phần bảng khi điền lại?';
												|ru = 'Сохранить данные о количестве, шаблонах в табличной части при перезаполнении?';
												|en = 'Save information on quantity and templates in the table when refilling?'; fa = 'Save information on quantity and templates in the table when refilling?';
												|it = 'Salvare i dati sul numero, sui modelli nella parte tabulare durante il ricompilazione?';
												|pl = 'Zapisać dane o ilości, szablonach w tabelarycznej części przy ponownym wypełnianiu?';
												|tr = 'Yeniden doldurma sırasında tablo kısmındaki miktarlar, şablonlar hakkındaki veriler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel,,DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	FilterParameters = New Structure("Selected", True);
	Goods = Object.Goods.FindRows(FilterParameters);
	
	If Goods.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn mặt hàng nào';
								|ru = 'Не выбрано ни одного товара';
								|en = 'No goods selected'; fa = 'No goods selected';
								|it = 'Nessuna merce è stata selezionata';
								|pl = 'Nie wybrano ani jednego towaru';
								|tr = 'Hiç bir ürün seçilmedi'"));
		Return;
	EndIf;
	
	PrintParameters = GetPrintSettings_();
	
	// Calling BSP
	If Object.PrintingOnRegularPrinter And CommonCELClient.SubsystemExists("StandardSubsystems.Print") Then
		
		CommandParameter = New Array;
		CommandParameter.Add(PredefinedValue("Catalog.TemplatesOfPLLabelsAndPriceTags.EmptyRef"));
		
		ModulePrintManagerClient = CommonCELClient.CommonModule("PrintManagementClient");
			ModulePrintManagerClient.ExecutePrintCommand("DataProcessor.PrintPLLabelsAndPriceTags", "PriceTags", CommandParameter, ThisObject, PrintParameters);
		
	Else
		
		ListOfDevices = New Array;
		FieldsForFillIn = New Array;
		LabelPrinterData = DataForLabelPrinterOnServer(PrintParameters, FieldsForFillIn, ListOfDevices);
		
		For Each Template In LabelPrinterData Do
			
			DescriptionNotificationAtEndOfPrinting = New CallbackDescription("ProcessingCommandToPrintPriceTagsAndLabelsOnLabelPrinterEnd", ThisObject);
			LabelPrintingOptions = PeripheralsLabelPrintersServerClient.LabelPrintingOperationParameters(Template.XMLTemplateDetails, Template.LabelPrintingData);
			PeripheralsLabelPrintersServerClient.StartPrintingLabels(DescriptionNotificationAtEndOfPrinting, ThisForm.UUID, Undefined, LabelPrintingOptions);
			
		EndDo;
		
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure SetPriceTagTemplate(Command)
	
	HandlerNotifications = New CallbackDescription("TemplateInstallationHandler", ThisObject);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.ChoiceForm", , ThisForm,,,, HandlerNotifications, Mode);
	
EndProcedure

&AtClient
Procedure SetPriceTagQuantity(Command)
	
	ValueSelected = Undefined;
	
	CallbackDescription = New CallbackDescription("NotificationSetNumberOfPriceTags", ThisObject);
	ShowInputNumber(CallbackDescription,ValueSelected, NStr("vi = 'Hãy nhập số lượng nhãn giá/nhãn tem';
															|ru = 'Введите количество ценников/этикеток';
															|en = 'Enter the number of price tags/labels'; fa = 'Enter the number of price tags/labels';
															|it = 'Inserire quantità cartellini/etichette';
															|pl = 'Wpisz ilość cenników/etykiet';
															|tr = 'Fiyat etiketi / etiket miktarını girin'"), 10, 0);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	Barcode = "";
	TitleText = NStr("vi = 'Hãy nhập mã vạch';
					|ru = 'Введите штрихкод';
					|en = 'Enter barcode'; fa = 'Enter barcode';
					|it = 'Inserire codice a barre';
					|pl = 'Wprowadź kod kreskowy';
					|tr = 'Barkod girin'");
	CallbackDescription = New CallbackDescription("NotificationOfBarCodeSearchForBPOLabelsAndPriceTags", ThisObject);
	
	ShowInputString(CallbackDescription, Barcode, TitleText);
	
EndProcedure

&AtClient
Procedure UploadVTSD(Command)
	
	AdditionalParameters = Undefined;
	PrintPLLabelsAndPriceTagsClientOverridable.VTSDUploadAndDownloadParameters(AdditionalParameters);
	PrintPLLabelsAndPriceTagsClientOverridable.UploadVTSD(ThisObject, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure DownloadFromTSD(Command)
	
	CallbackDescription = New CallbackDescription("NotificationOfLoadingOfLabelsAndPriceTagsOfBPOFromTSD", ThisObject);
	
	AdditionalParameters = Undefined;
	PrintPLLabelsAndPriceTagsClientOverridable.VTSDUploadAndDownloadParameters(AdditionalParameters);
	PrintPLLabelsAndPriceTagsClientOverridable.DownloadFromTSD(ThisObject, AdditionalParameters, CallbackDescription);
	
EndProcedure

&AtClient
Procedure Filter(Command)
	
	FilterVisibility = Not FilterVisibility;
	
	If FilterVisibility Then
		Items.GroupFilter.Visible = True;
		Items.Filter.Title = NStr("vi = 'Ẩn bộ lọc';
									|ru = 'Скрыть отбор';
									|en = 'Hide filter'; fa = 'Hide filter';
									|it = 'Nascondere selezione';
									|pl = 'Ukryj wybór';
									|tr = 'Filtreyi gizle'");
	Else
		Items.GroupFilter.Visible = False;
		Items.Filter.Title = NStr("vi = 'Hiển thị bộ lọc';
									|ru = 'Показать отбор';
									|en = 'Show filter'; fa = 'نمایش فیلتر';
									|it = 'Visualizzare selezione';
									|pl = 'Pokaż filtr';
									|tr = 'Filtreyi göster'");
	EndIf;
	
EndProcedure

&AtClient
Procedure SetBarcodeOfItem(Command)
	
	Result = False;
	
	If Not ValueIsFilled(Items.Goods.SelectedRows) Then
		CommonCELClient.MessageToUser(NStr("vi = 'Trong danh sách không có các dòng được chọn';
											|ru = 'В списке отсутствуют выделенные строки';
											|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
											|it = 'Nell''elenco mancano le righe selezionate';
											|pl = 'Na liście brakuje wybranych wierszy';
											|tr = 'Listede seçili satır yok'"));
		Return;
	EndIf;
	
	SelectedProductItems = Items.Goods.SelectedRows;
	Barcodes = New Map;
	TSGoods = Object.Goods;
	PrintPLLabelsAndPriceTagsClientOverridable.SetItemBarcodes(SelectedProductItems, TSGoods, Barcodes);
	
	For Each CurKeyAndVALUE In Barcodes Do
		TSRow = Object.Goods.FindByID(CurKeyAndVALUE.Key);
		TSRow.Barcode = CurKeyAndVALUE.Value;
	EndDo
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibilityAndAccessibilityOfFormElements()
	
	If Not MatchingFormHasBeenRedefined Then
		
		Items.SelectGoods.Visible = False;
		
	EndIf;
	
	If Not BarcodeSearchFormHasBeenRedefined Then
		
		Items.SearchByBarcode.Visible = False;
		
	EndIf;
	
	If Not SelectionFormHasBeenRedefined Then
		
		Items.Filter.Visible = False;
		Items.SelectGoods.Visible = False;
		
	EndIf;
	
	If Not VTSDUploadFormHasBeenRedefined Then
		
		Items.UploadVTSD.Visible = False;
		Items.DownloadFromTSD.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfTableElementsAndColumns()
	
	If Not ValueIsFilled(Metadata.DefinedTypes.PlVariant.Type) Then
		Items.Goods["GoodsPlVariant"].Visible = False;
	EndIf;
	
	If Not ValueIsFilled(Metadata.DefinedTypes.PlPackagingUnit.Type) Then
		Items.Goods["GoodsPlPackagingUnit"].Visible = False;
	EndIf;

	If Not ValueIsFilled(Metadata.DefinedTypes.PlItems.Type) Then
		Items.Goods.Visible = False;
	EndIf;

	If Not ValueIsFilled(Metadata.DefinedTypes.RetailFacilityCEL.Type) Then
		Items.RetailFacility.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInBySelectionOnClient()
	
	ArrayOfProductsForPrinting = New Array;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("RetailFacility", Object.RetailFacilityCEL);
	OpeningParameters.Insert("PriceKind", Object.PriceKind);
	OpeningParameters.Insert("PriceTypePromotion", Object.PriceTypePromotion);
	OpeningParameters.Insert("SettingsComposer", SettingsComposer);
	OpeningParameters.Insert("PricesAsOfDate", PricesAsOfDate);
	OpeningParameters.Insert("PrintMode", Object.PrintMode);
	
	PrintPLLabelsAndPriceTagsClientOverridable.FillInByPicking(OpeningParameters, ArrayOfProductsForPrinting);
	
	For Each OwnGoods In ArrayOfProductsForPrinting Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, OwnGoods);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure PickUpProductsOnClient()
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("OwnerForm", ThisObject);
	OpeningParameters.Insert("CloseHandler", New CallbackDescription("SelectGoodsCompletion", ThisObject, 
	New Structure("RetailFacilityCEL, PriceKind, PricesAsOfDate", Object.RetailFacilityCEL, Object.PriceKind, PricesAsOfDate)));
	OpeningParameters.Insert("LockMode", FormWindowOpeningMode.LockOwnerWindow);
	OpeningParameters.Insert("RetailFacility", Object.RetailFacilityCEL);
	OpeningParameters.Insert("PriceKind", Object.PriceKind);
	OpeningParameters.Insert("PriceTypePromotion", Object.PriceTypePromotion);
	OpeningParameters.Insert("PricesAsOfDate", PricesAsOfDate);
	
	PrintPLLabelsAndPriceTagsClientOverridable.OpenSelectionForm(OpeningParameters);
	
EndProcedure

&AtClient
Procedure SelectGoodsCompletion(Result, OperationParametersList) Export
	
	ArrayOfProductsForPrinting = New Array;
	PrintPLLabelsAndPriceTagsClientOverridable.SelectGoodsCompletion(Result, OperationParametersList, ArrayOfProductsForPrinting);
	
	For Each OwnGoods In ArrayOfProductsForPrinting Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, OwnGoods);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure NotificationOfBarCodeSearchForBPOLabelsAndPriceTags(Result, OperationParametersList) Export
	
	If Not IsBlankString(Result) Then
		
		ArrayOfProductsForPrinting = New Array;
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("RetailFacility", Object.RetailFacilityCEL);
		OpeningParameters.Insert("PriceKind", Object.PriceKind);
		OpeningParameters.Insert("PriceTypePromotion", Object.PriceTypePromotion);
		OpeningParameters.Insert("PricesAsOfDate", PricesAsOfDate);
		PrintPLLabelsAndPriceTagsClientOverridable.NotificationOfBarCodeSearchForBPOLabelsAndPriceTags(Result, OpeningParameters, ArrayOfProductsForPrinting);
		
		For Each OwnGoods In ArrayOfProductsForPrinting Do
			
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, OwnGoods);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationOfLoadingOfLabelsAndPriceTagsOfBPOFromTSD(Result, OperationParametersList) Export
	
	ArrayOfProductsForPrinting = New Array;
	PrintPLLabelsAndPriceTagsClientOverridable.NotificationOfLoadingOfLabelsAndPriceTagsOfBPOFromTSD(Result, OperationParametersList, ArrayOfProductsForPrinting);
	
	For Each OwnGoods In ArrayOfProductsForPrinting Do
		
		NewRow = Object.Goods.Add();
		NewRow.PlItems   = OwnGoods.PlItems;
		NewRow.PlVariant = OwnGoods.PlVariant;
		NewRow.PlPackagingUnit       = OwnGoods.PlPackagingUnit;
		NewRow.Price              = OwnGoods.Price;
		NewRow.CompanyCEL    = OwnGoods.CompanyCEL;
		NewRow.Barcode          = OwnGoods.Barcode;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure TemplateInstallationHandler(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Count = 0;
		RowsArray = Items.Goods.SelectedRows;
		
		For Each LineNumber In RowsArray Do
			
			TSRow = Object.Goods.FindByID(LineNumber);
			TSRow.PriceTagLabelTemplate = ValueSelected;
			If Not ValueIsFilled(TSRow.Count) Then
				TSRow.Count = 1;
			EndIf;
			TSRow.Selected = True;
			
			If TSRow.Selected Then
				Count = Count + 1;
			EndIf;
			
		EndDo;
		
		TotalCount1 = RowsArray.Count();
		
		Text = NStr("vi = 'Đã đặt khuôn mẫu ""%Template%"".';
					|ru = 'Установлен шаблон ""%Template%"".';
					|en = '""%Template%"" template is set.'; fa = '""%Template%"" template is set.';
					|it = 'Impostato modello ""%Template%"".';
					|pl = 'Ustaw szablon ""%Template%"".';
					|tr = '""%Template%"" şablonu ayarlandı.'");
		Text = StrReplace(Text, "%Template%", ValueSelected);
		
		ShowNotificationToUserAboutPossibleError(Text, Count, TotalCount1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationSetNumberOfPriceTags(ValueSelected, AdditionalParameters) Export
	
	If Not ValueSelected = Undefined Then
		
		Count = 0;
		
		RowsArray = Items.Goods.SelectedRows;
		For Each LineNumber In RowsArray Do
			TSRow = Object.Goods.FindByID(LineNumber);
			TSRow.Count  = ValueSelected;
			If ValueIsFilled(TSRow.PriceTagLabelTemplate) Then
				TSRow.Selected = True;
			EndIf;
			
			If TSRow.Selected Then
				Count = Count + 1;
			EndIf;
			
		EndDo;
		
		TotalCount1 = RowsArray.Count();
		
		Text = NStr("vi = 'Đã đặt số lượng nhãn giá %Count%.';
					|ru = 'Установлено количество ценников %Count%.';
					|en = 'Number of %Count% price tags is set.'; fa = 'Number of %Count% price tags is set.';
					|it = 'Impostata quantità di cartellini %Count%';
					|pl = 'Ustawiono ilość cenników %Count%.';
					|tr = '%Count% fiyat etiketi miktarı ayarlandı.'");
		Text = StrReplace(Text, "%Count%", ValueSelected);
		
		ShowNotificationToUserAboutPossibleError(Text, Count, TotalCount1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationFillInTableOfProducts(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Object.Goods.Clear();
	EndIf;
	
	FillInBySelectionOnClient();
	
EndProcedure

&AtClient
Procedure ShowNotificationToUserAboutPossibleError(Text, Count, TotalCount1)
	
	If Count < TotalCount1 Then
		
		Text = Text
		        + ?(Text <> "", Chars.LF, "")
		        + NStr("vi = 'Đã đặt đánh dấu chọn đối với %SelectedCount% dòng trong số %TotalCount1%.';
						|ru = 'Отметка выбора установлена для %SelectedCount% строк из %TotalCount1%.';
						|en = 'Selection mark is set for %SelectedCount% lines out of %TotalCount1%.'; fa = 'Selection mark is set for %SelectedCount% lines out of %TotalCount1%.';
						|it = 'Il contrassegno di selezione è impostato per %SelectedCount% righe di %TotalCount1%.';
						|pl = 'Zaznaczeni wyboru jest ustawione dla %SelectedCount% wierszy z %TotalCount1%.';
						|tr = '%TotalCount1% içinden %SelectedCount% satır için seçim kutucuğu ayarlandı.'");
	
		Text = Text
		        + Chars.LF
		        + NStr("vi = 'Hãy kiểm tra đã điền tất cả mục tin bắt buộc hay chưa.';
						|ru = 'Проверьте, заполнены ли все обязательные реквизиты.';
						|en = 'Check if all required attributes are filled.'; fa = 'Check if all required attributes are filled.';
						|it = 'Verificare se tutti i requisiti obbligatori sono compilati.';
						|pl = 'Sprawdź, czy są wypełnione wszystkie wymagane atrybuty.';
						|tr = 'Tüm gerekli özniteliklerin doldurulup doldurulmadığını kontrol edin.'");
	
		Text = StrReplace(Text, "%SelectedCount%", Count);
		Text = StrReplace(Text, "%TotalCount1%", TotalCount1);
		
		ShowUserNotification(NStr("vi = 'Đã thực hiện giao dịch';
									|ru = 'Операция выполнена';
									|en = 'The operation is complete'; fa = 'عملیات تکمیل شد';
									|it = 'Operazione eseguita';
									|pl = 'Operacja została wykonana';
									|tr = 'İşlem tamamlandı'"), , Text);
	
	EndIf;
	
EndProcedure

&AtServer
Function DataForLabelPrinterOnServer(PrintParameters, FieldsForFillIn, ListOfAvailableDevices = Undefined)
	
	TemplatesForPrinting = PrintParameters.Goods.Unload(New Structure("Selected", True),"PriceTagLabelTemplate");
	FieldsForFillIn = DataProcessors.PrintPLLabelsAndPriceTags.TemplatesFields(TemplatesForPrinting);
	ProductDataForFormationOfPrintedForms = PrintPLLabelsAndPriceTagsOverridable.DataForFormationOfPrintedForms(PrintParameters, FieldsForFillIn, Undefined);
	LabelsData = DataProcessors.PrintPLLabelsAndPriceTags.LabelPrintingData(ProductDataForFormationOfPrintedForms, FieldsForFillIn); 
	
	SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
	SupportedTypes.LabelPrinters = True;
	
	ListOfEquipmentSelection = EquipmentManagerClientServer.ListOfEquipmentSelection();
	ListOfEquipmentSelection.SoftwareTypes = SupportedTypes;
	ListOfAvailableDevices = EquipmentManagerServerCall.EquipmentList(ListOfEquipmentSelection);
	
	Return LabelsData;
	
EndFunction

&AtClient
Procedure ProcessingCommandToPrintPriceTagsAndLabelsOnLabelPrinterEnd(PrintResult, AdditionalParameters) Export
	
	If Not PrintResult.Result Then
		ShowMessageBox(, PrintResult.ErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure DownloadSelectionSettings()
	
	DataCompositionSchema = PrintPLLabelsAndPriceTagsOverridable.DataLayoutTemplate();
	If Not DataCompositionSchema = Undefined Then
		DCSAddress = PutToTempStorage(
						DataCompositionSchema,
						ThisForm.UUID);
		Source = New DataCompositionAvailableSettingsSource(DCSAddress);
		SettingsComposer.Initialize(Source);
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
		RemoveUncheckedComposerSelections(SettingsComposer);
	Else
		MessageText = NStr("vi = 'Chưa xác định khuôn in dàn dựng dữ liệu.';
							|ru = 'Не определен макет компоновки данных.';
							|en = 'Data composition template is not defined.'; fa = 'Data composition template is not defined.';
							|it = 'Non è definito il modello di raccolta dati.';
							|pl = 'Nie określono makiety układu danych.';
							|tr = 'Veri tasarım şablonu tanımlanmamış.'");
		CommonCEL.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteUncheckedSelectionsInGroup(ItemsCollection, Composer)
	
	Count = ItemsCollection.Count();
	
	For IndexOf = 1 To Count Do
		
		FilterElement = ItemsCollection[Count - IndexOf];
		
		If TypeOf(FilterElement)=Type("DataCompositionFilterItem") Then
			
			FilterField = FilterElement.LeftValue;
			
			If Composer.Settings.Filter.FilterAvailableFields.FindField(FilterField) = Undefined Then
				ItemsCollection.Delete(FilterElement);
			EndIf;
			
		Else
			DeleteUncheckedSelectionsInGroup(FilterElement.Items, Composer);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RemoveUncheckedComposerSelections(Composer)

	Count = Composer.Settings.Filter.Items.Count();
	
	For IndexOf = 1 To Count Do
		
		FilterElement = Composer.Settings.Filter.Items[Count - IndexOf];
		
		If TypeOf(FilterElement)=Type("DataCompositionFilterItem") Then
			
			FilterField = FilterElement.LeftValue;
			
			If Composer.Settings.Filter.FilterAvailableFields.FindField(FilterField) = Undefined Then
				Composer.Settings.Filter.Items.Delete(FilterElement);
			EndIf;
			
		Else
			DeleteUncheckedSelectionsInGroup(FilterElement.Items, Composer);
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure PriceKindOnChangeServer()

	PrintPLLabelsAndPriceTagsOverridable.WhenChangingPriceType(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Function CheckProductSelectionOption(CurrentData)
	
	If (CurrentData.Count = 0) Then
		
		Return False;
		
	ElsIf Not ValueIsFilled(CurrentData.PriceTagLabelTemplate) Then
		
		Return False;
		
	Else
		
		Return True;
		
	EndIf;
	
EndFunction

&AtServer
Function GetPrintSettings_()
	
	PrintParameters = New Structure;
	PrintParameters.Insert("RetailFacility", Object.RetailFacilityCEL);
	If Object.PrintingOnRegularPrinter Then
		PrintParameters.Insert("Goods", CommonCEL.ValueTableToArray(Object.Goods.Unload()));
	Else
		PrintParameters.Insert("Goods", Object.Goods);
	EndIf;
	PrintParameters.Insert("PriceKind", Object.PriceKind);
	PrintParameters.Insert("PriceTypePromotion", Object.PriceTypePromotion);
	PrintParameters.Insert("PricesAsOfDate", PricesAsOfDate);
	PrintParameters.Insert("EachLabelIsOnNewSheet", Object.EachLabelIsOnNewSheet);
	
	Return PrintParameters;

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
