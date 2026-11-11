
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	PackingList = Parameters.PackingList;
	Warehouse           = Parameters.Warehouse;
	
	If ValueIsFilled(PackingList) Then
		Code = Common.ObjectAttributeValue(PackingList, "Code");
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Source = "Peripherals"
		And IsInputAvailable() Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter);
			Code = BarcodeData_5[0].Barcode;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CodeOnChange(Item)
	ClearMessages();
	FindPackingList();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateNew(Command)
	ClearMessages();
	CreateNewPackingListServer();
EndProcedure

&AtClient
Procedure OK(Command)
	ClearMessages();
	If Not ValueIsFilled(PackingList) Then
		If Not ValueIsFilled(Code) Then
			PackingList = PredefinedValue("Document.PackingList.EmptyRef");
			
			QueryText = NStr("vi = 'Chưa chọn phiếu đóng gói. Xóa phiếu đóng gói trong các dòng đã chọn?';
							|ru = 'Упаковочный лист не выбран. Очистить упаковочный лист в выделенных строках?';
							|en = 'Packing list is not selected. Clear the packing list in the selected lines?'; fa = 'Packing list is not selected. Clear the packing list in the selected lines?';
							|it = 'Nessuna lista di imballaggio selezionata. Cancellare la lista di imballaggio nelle righe evidenziate?';
							|pl = 'List pakowy nie został wybrany. Oczyścić list pakowy w wybranych wierszach?';
							|tr = 'Ürün listesi seçilmedi. Seçilen satırlardaki ürün listesi temizlensin mi?'");
			CallbackDescription = New CallbackDescription("QuestionWithEmptyPackingListEnding",ThisForm);
			
			ShowQueryBox(CallbackDescription,QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.No);
			Return;
			
		Else
			MessageString = NStr("vi = 'Không tìm thấy phiếu đóng gói với mã %1%.';
								|ru = 'Упаковочный лист с кодом %1% не найден.';
								|en = 'Packing list with code %1% is not found.'; fa = 'Packing list with code %1% is not found.';
								|it = 'La lista di imballaggio con il codice %1% non è stato trovata.';
								|pl = 'List pakowy z kodem %1% nie został znaleziony.';
								|tr = '%1% kodu ile olan ürün listesi bulunmadı.'");
			MessageString = StrReplace(MessageString, "%1%", TrimAll(Code));
			CommonClientServer.MessageToUser(MessageString,,"Code");
			PackingList = PredefinedValue("Document.PackingList.EmptyRef");
			Return;	
		EndIf;
	EndIf;
	
	CloseWithResult();
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure PrintLabel(Command)
	
	If Not ValueIsFilled(PackingList) Then
		MessageText = NStr("vi = 'Để in nhãn tem, hãy nhập mã danh sách đóng gói hiện tại hoặc tạo mới.';
							|ru = 'Для печати этикетки введите код существующего упаковочного листа или создайте новый.';
							|en = 'To print the label, enter a code of the existing packing list or create a new one.'; fa = 'To print the label, enter a code of the existing packing list or create a new one.';
							|it = 'Per stampare un''etichetta inserire il codice di una lista di imballaggio esistente o crearne una nuova.';
							|pl = 'Aby wydrukować etykietę wprowadź kod istniejącego listu pakowego lub utwórz nowy.';
							|tr = 'Bir etiket yazdırmak için mevcut bir ürün listesi kodunu gir veya yeni bir tane oluştur.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	PrintObjects = New Array();
    PrintObjects.Add(PackingList);
    PrintManagementTMClient.PrintingLabelsPackingSheets(New Structure("PrintObjects",PrintObjects));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateNewPackingListServer()
	DocStructure = New Structure("Kind, PackageWarehouse", Enums.PackingListKinds.Outgoing, Warehouse);
	PackingList = Documents.PackingList.CreateHoldNew(DocStructure);
	Code = Common.ObjectAttributeValue(PackingList, "Code");
EndProcedure

&AtServer
Procedure FindPackingList()
	
	Array = Documents.PackingList.ArrayOfLinksByArrayOfCodes(Code);
	
	If Array.Count() = 1 Then
		PackingList = Array[0];
	Else
		MessageString = NStr("vi = 'Không tìm thấy phiếu đóng gói với mã %1%';
							|ru = 'Упаковочный лист с кодом %1% не найден';
							|en = 'Packing list with code %1% is not found'; fa = 'Packing list with code %1% is not found';
							|it = 'La lista di imballaggio con il codice %1% non è stata trovata';
							|pl = 'List pakowy z kodem %1% nie został znaleziony';
							|tr = '%1% kodu ile olan ürün listesi bulunmadı'");
		MessageString = StrReplace(MessageString, "%1%", TrimAll(Code));
		CommonClientServer.MessageToUser(MessageString,,"Code");
		PackingList = Documents.PackingList.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseWithResult()
	Result = New Structure;
	Result.Insert("PackingList", PackingList);
	Result.Insert("Code", Code);
	Close(Result);
EndProcedure

&AtClient
Procedure QuestionWithEmptyPackingListEnding(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CloseWithResult();
	EndIf;
	
EndProcedure

#EndRegion


