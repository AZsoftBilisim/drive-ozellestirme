
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FindType = Parameters.FindType;
	Context = Parameters.Context;
	
	If Parameters.Property("Warehouse") Then
		Warehouse = Parameters.Warehouse;
	EndIf;
	
	If Parameters.Property("Premise") Then
		Premise = Parameters.Premise;
	EndIf;
	
	If Parameters.Property("DocumentRef") Then
		Ref = Parameters.DocumentRef;
	EndIf;
	
	If Parameters.Property("PackageBarcodes") Then
		PackageBarcodes.Load(Parameters.PackageBarcodes.Unload());
	EndIf;
	
	If Parameters.Property("Organization") Then
		Organization = Parameters.Organization;
	EndIf;
	
	SetHeader();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If MobileClient Then
	CurrentItem = Items.Barcode;
	BeginEditingItem();
#EndIf
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then

			ProcessBarcode(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
			
		EndIf;
		
	EndIf;
	
	
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BarcodeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	BarcodeData_1 = New Structure("Barcode", Text);
	BarcodeData_1.Insert("Count", 1);
	
	ProcessBarcode(BarcodeData_1);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindByBarcode(Command)
	
	BarcodeData_1 = New Structure("Barcode", Barcode);
	BarcodeData_1.Insert("Count", 1);
	
	ProcessBarcode(BarcodeData_1);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetHeader()
	
	If FindType = "CellSearch" Then
		Items.Title.Title = NStr("vi = 'Hãy quét mã vạch ô hàng';
								|ru = 'Отсканируйте штрихкод ячейки';
								|en = 'Scan the storage bin barcode'; fa = 'Scan the storage bin barcode';
								|it = 'Scansionare il codice a barra della cella';
								|pl = 'Zeskanuj kod kreskowy komórki';
								|tr = 'Hücre barkodunu tara'");
	ElsIf FindType = "ProductItemsSearch" Then
		Items.Title.Title = NStr("vi = 'Hãy quét mã vạch mặt hàng';
								|ru = 'Отсканируйте штрихкод номенклатуры';
								|en = 'Scan the item barcode'; fa = 'Scan the item barcode';
								|it = 'Scansionare il codice a barre della nomenclatura';
								|pl = 'Zeskanuj kod kreskowy produktu';
								|tr = 'Ürün gamı barkodunu tara'"); 
	ElsIf FindType = "DocumentSearch" Then
		Items.Title.Title = NStr("vi = 'Hãy quét mã vạch chứng từ';
								|ru = 'Отсканируйте штрихкод документа';
								|en = 'Scan the document barcode'; fa = 'Scan the document barcode';
								|it = 'Scan the document barcode';
								|pl = 'Scan the document barcode';
								|tr = 'Belge barkodunu tara'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
	
	MessageToUserText = "";
		
	If FindType = "CellSearch" Then 
		
		CellData = CellDataByWK(BarcodeData_1.Barcode);
		
		If ValueIsFilled(CellData.Cell) Then
			Close(CellData);
			Return;
		EndIf;

		Status(NStr("vi = 'Không tìm thấy ô theo mã vạch';
					|ru = 'Ячейка по штрихкоду не найдена';
					|en = 'Storage bin is not found by barcode'; fa = 'Storage bin is not found by barcode';
					|it = 'Storage bin is not found by barcode';
					|pl = 'Storage bin is not found by barcode';
					|tr = 'Barkod ile depo yeri bulunamadı'"));
	
	ElsIf FindType = "ProductItemsSearch" Then
		
		ProductData_9 = Undefined;
		
		If BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_1) Then

			ProductData_9 = ItemDataBySchool(BarcodeData_1.Barcode);
				
			If ValueIsFilled(ProductData_9) Then
				Close(ProductData_9);
				Return;
			Else
			EndIf;
				
		Else
		EndIf;
			
		If Not ValueIsFilled(ProductData_9) And MessageToUserText <> "" Then
			Status(MessageToUserText);
		EndIf;
	
	ElsIf FindType = "DocumentSearch" Then 
		
		DocumentData = DataOfDocumentOnSHK(BarcodeData_1.Barcode);
	
		If ValueIsFilled(DocumentData.References) Then
			If ValueIsFilled(DocumentData.ErrorText) Then
				Status(DocumentData.ErrorText);	
				Return;
			Else
				Close(DocumentData);
				Return;
			EndIf;
		EndIf;
		
		Status(NStr("vi = 'Không tìm thấy chứng từ theo mã vạch';
					|ru = 'Документ по штрихкоду не найден';
					|en = 'Document is not found by barcode'; fa = 'Document is not found by barcode';
					|it = 'Document is not found by barcode';
					|pl = 'Document is not found by barcode';
					|tr = 'Barkod ile belge bulunamadı'"));
	EndIf;
		
EndProcedure

&AtServer
Function CellDataByWK(Val Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.CellDataByWK(Warehouse, Premise, Barcode);
	
EndFunction

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction 

&AtServer
Function DataOfDocumentOnSHK(Val Barcode)
	
	If Context = "Receiving" Or Context = "Shipment" Then		
		Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfDocumentOnSHK(Barcode, Warehouse, Context); 		
	Else
		Return DataProcessors.MobileWarehouseKeeperWorkspace.DataOfWarehouseDocumentForSHK(Barcode, Context); 
	EndIf;

EndFunction


&AtClient
Procedure AfterProcessingBarcodes(Result, AdditionalParameters) Export
	
	ProductStructure_2 = New Structure;
	ProductStructure_2.Insert("Products", "");
	ProductStructure_2.Insert("Characteristic", "");
	ProductStructure_2.Insert("Package", "");
	ProductStructure_2.Insert("Series", "");
	ProductStructure_2.Insert("Count", 1);
	ProductStructure_2.Insert("PackageBarcode", "");
	ProductStructure_2.Insert("PackageType", "");
	
	FillPropertyValues(ProductStructure_2, Result.BarcodeData_1);
	
	ProductStructure_2.Count = ?(ProductStructure_2.Count = 0, 1, ProductStructure_2.Count);
	
	
	ProductData_9 = CommonClientServer.ValueInArray(ProductStructure_2);
	
	If ValueIsFilled(ProductStructure_2.Products) Or ValueIsFilled(ProductStructure_2.PackageBarcode) Then
		Close(ProductData_9);
	EndIf;
	
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
												|tr = 'Kamerayı barkoda doğrult'"),
			ScanningHandler,
			,
			BarcodeType.Linear);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScanProcessing(BarcodeCamera, Result, Message, AdditionalParameters) Export

	If Result Then
		
		MultimediaTools.PlaySoundAlert(SoundAlert.Default,True);
		MultimediaTools.CloseBarcodeScanning();
		
		BarcodeData_1 = New Structure("Barcode", BarcodeCamera);
		BarcodeData_1.Insert("Count", 1);
		
		ProcessBarcode(BarcodeData_1);
		
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

#EndRegion