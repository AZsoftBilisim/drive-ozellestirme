#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function ContentsOfGeneralTemplate(Val TemplateName) Export

	ContentOfTemplate = GetCommonTemplate(TemplateName).GetText();     
	Return ContentOfTemplate; 
	
EndFunction

Function CompatibilityOfExternalComponentFromFile(Val TemplateName) Export
	
	TimeNameOfTemplate = StrSplit(TemplateName,".", False);
	TimeNameOfTemplate = TimeNameOfTemplate[TimeNameOfTemplate.UBound()];
	BinaryData = GetCommonTemplate(TimeNameOfTemplate);
		
	Result = AddInsCEL.InformationOnAddInFromFile(BinaryData, False);
	If Result.Disassembled Then
		Return Result.Attributes;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function SuppliedDrivers() Export
	
	UpgradeModules = New Array();
	If CommonCEL.InputDevicesAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsInputDevices"));       
	EndIf;
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsReceiptPrinters"));       
	EndIf;
	If CommonCEL.UsedPaymentSystems() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsPaymentSystemsServer"));       
	EndIf;          
	If CommonCEL.UsedBuyerSDisplays() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsCustomerDisplaysServer"));       
	EndIf;
	If CommonCEL.WeightEquipmentIsUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsWeighingEquipmentServer"));       
	EndIf;                          
// ++ Non-mobile application
	If CommonCEL.DataCollectionTerminalsAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsPortableDataTerminalsServer"));       
	EndIf;
	If CommonCEL.LabelPrintersAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsLabelPrintersServer"));       
	EndIf;
	If CommonCEL.RFIDReaderIsUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsRFIDReader"));       
	EndIf;
	If CommonCEL.RecognitionDeviceIsUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("EquipmentRecognitionDevice"));       
	EndIf;
	If CommonCEL.CloudCCTSAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("EquipmentCloudCRE"));       
	EndIf;
// -- Non-mobile application
	HardwareDrivers = EquipmentManager.NewTableOfSuppliedHardwareDrivers();
	For Each UpdateModule In UpgradeModules Do
		UpdateModule.UpdateSuppliedDrivers(HardwareDrivers);
	EndDo;
	
	Return HardwareDrivers;
	
EndFunction

Function DriverIds() Export
	
	HardwareDrivers = SuppliedDrivers();
	
	HardwareDrivers.GroupBy("ObjectID, NoLongerSupported");
	Result = New Array();
	For Each Item In HardwareDrivers Do
		If Not Item.NoLongerSupported Then
			Result.Add(Item.ObjectID);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function ParametersTypesOfEquipment() Export
	
	Result = New Structure();
	AvailableTypes = AllEquipmentTypes(True);
	For Each Value In AvailableTypes Do
		
		EnumValueName = CommonCEL.EnumerationValueName(Value);
		Result.Insert(EnumValueName, False);
		
	EndDo;
	
	// Addition of equipment types
	Result.Insert("FiscalCashRegisters", False);
	
	Return Result;

EndFunction

// Get Matching Equipment Types
//
// Returns:
//   Map -
//
Function CompatibilityOfEquipmentTypes() Export
	
	Result = New Map();
	
	AvailableTypes = AllEquipmentTypes(True);
	For Each Value In AvailableTypes Do
		
		EnumValueName = CommonCEL.EnumerationValueName(Value);
		Result.Insert(EnumValueName, Value);
		
	EndDo;
	
	// Russian alphabet. Do not localize
	Result.Insert("УстройствоВвода"       , Enums.PeripheralTypes.BarcodeScanner); //@NON-NLS-1 @NON-NLS-2   
	
	// English alphabet. 
	Result.Insert("BarcodeScanner"        , Enums.PeripheralTypes.BarcodeScanner); //@NON-NLS-1 @NON-NLS-2      
	Result.Insert("CardReader"            , Enums.PeripheralTypes.MagneticStripeCardReaders); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("KKT"                   , Enums.PeripheralTypes.CREWithDataTransfer); //@NON-NLS-1 @NON-NLS-2    
	Result.Insert("FiscalRegistrar"       , Enums.PeripheralTypes.FiscalCashRegisters); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("ReceiptPrinter"        , Enums.PeripheralTypes.ReceiptPrinter); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("CustomerDisplay"       , Enums.PeripheralTypes.CustomerDisplay); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("DataCollectionTerminal", Enums.PeripheralTypes.PortableDataCollectionTerminal); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("POSTerminal"           , Enums.PeripheralTypes.POSTerminal); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("WeighingScales"        , Enums.PeripheralTypes.DigitalRetailScales); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("LabelPrintingScale"    , Enums.PeripheralTypes.LabelPrintingScales); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("LabelPrinter"          , Enums.PeripheralTypes.LabelPrinters); //@NON-NLS-1 @NON-NLS-2   
	Result.Insert("RFIDReader"            , Enums.PeripheralTypes.RFIDReaders); //@NON-NLS-1 @NON-NLS-2    
	Result.Insert("Recognizer"            , Enums.PeripheralTypes.RecognitionDevice); //@NON-NLS-1 @NON-NLS-2       
	
	Return Result;
	
EndFunction

// Returns a list of available hardware types.
//
// Parameters:
//  IncludingUnusedOnes - Boolean - The default is False, add unused types, for compatibility
// 
// Returns:
//   Array of EnumRef.PeripheralTypes - Array of available types of connected equipment in the configuration.
//
Function AvailableTypesOfEquipment(IncludingUnusedOnes = False) Export
	
	ListOfEquipmentTypes = New Array;
	StandardProcessing = True;
	
	EquipmentManagerServerCallOverridable.AvailableTypesOfEquipment(ListOfEquipmentTypes, StandardProcessing);
	
	If StandardProcessing Then
		ListOfEquipmentTypes.Clear();
		If CommonCEL.InputDevicesAreUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.BarcodeScanner);
		// ++ Non-mobile application
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.MagneticStripeCardReaders);
		// -- Non-mobile application     
		EndIf;
		If CommonCEL.CheckPrintingDevicesAreUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.CREWithDataTransfer);
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.ReceiptPrinter);
			If IncludingUnusedOnes Then
				ListOfEquipmentTypes.Add(Enums.PeripheralTypes.FiscalCashRegisters);
			EndIf;
		EndIf;
		If CommonCEL.UsedBuyerSDisplays() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.CustomerDisplay);
		EndIf;
		// ++ Non-mobile application
		If CommonCEL.DataCollectionTerminalsAreUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.PortableDataCollectionTerminal);
		EndIf;
		// -- Non-mobile application     
		If CommonCEL.UsedPaymentSystems() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.POSTerminal);
		EndIf;
		If CommonCEL.WeightEquipmentIsUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.DigitalRetailScales);  
		// ++ Non-mobile application
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.LabelPrintingScales);
		// -- Non-mobile application     
		EndIf;
		// ++ Non-mobile application
		If CommonCEL.LabelPrintersAreUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.LabelPrinters);
		EndIf;
		If CommonCEL.RFIDReaderIsUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.RFIDReaders);
		EndIf;
		If CommonCEL.RecognitionDeviceIsUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.RecognitionDevice);
		EndIf;
		
		If CommonCEL.NonCertifiedEquipmentIsUsed() Then
			ModuleNonCertifiedEquipment = CommonCEL.CommonModule("UncertifiedPeripherals");
			If IncludingUnusedOnes Or ModuleNonCertifiedEquipment.NonCertifiedEquipmentIsAvailable() Then
				TypesOfEquipment = EquipmentManager.AvailableTypesOfNonCertifiedEquipment();
				For Each Item In TypesOfEquipment Do
					ListOfEquipmentTypes.Add(Item);
				EndDo;
			EndIf;
		EndIf;
		
		// -- Non-mobile application     
	EndIf;
	
	// ++ Non-mobile application
	DeleteOfflineEquipment = ListOfEquipmentTypes.Find(Enums.PeripheralTypes.DeleteOfflineEquipment);
	If DeleteOfflineEquipment <> Undefined Then
		ListOfEquipmentTypes.Delete(DeleteOfflineEquipment);
	EndIf;
	
	// -- Non-mobile application     
	Return ListOfEquipmentTypes;
	
EndFunction

// Returns a list of all types of hardware.
//
// Parameters:
//  IncludingUnusedOnes - Boolean - The default is False, add unused types, for compatibility
// 
// Returns:
//   Array of EnumRef.PeripheralTypes - Array of available types of connected equipment in the configuration.
//
Function AllEquipmentTypes(IncludingUnusedOnes = False) Export
	
	ListOfEquipmentTypes = New Array;
	StandardProcessing = True;
	
	ListOfEquipmentTypes.Clear();
	For Each EquipmentType In Enums.PeripheralTypes Do
		
		If IncludingUnusedOnes And 
			(EquipmentType = Enums.PeripheralTypes.FiscalCashRegisters) Then
			Continue;
		EndIf;
		
		ListOfEquipmentTypes.Add(EquipmentType);
		
	EndDo;
	
	// ++ Non-mobile application
	If CommonCEL.NonCertifiedEquipmentIsUsed() Then
		ModuleNonCertifiedEquipment = CommonCEL.CommonModule("UncertifiedPeripherals");
		If IncludingUnusedOnes Or ModuleNonCertifiedEquipment.NonCertifiedEquipmentIsAvailable() Then
			TypesOfEquipment = EquipmentManager.AvailableTypesOfNonCertifiedEquipment();
			For Each Item In TypesOfEquipment Do
				ListOfEquipmentTypes.Add(Item);
			EndDo;
		EndIf;
	EndIf;
	// -- Non-mobile application     
	
	// ++ Non-mobile application
	DeleteOfflineEquipment = ListOfEquipmentTypes.Find(Enums.PeripheralTypes.DeleteOfflineEquipment);
	If DeleteOfflineEquipment <> Undefined Then
		ListOfEquipmentTypes.Delete(DeleteOfflineEquipment);
	EndIf;
	
	// -- Non-mobile application     
	Return ListOfEquipmentTypes;
	
EndFunction

#Region ClassificationOfErrors

Function NewErrorClass(Class, ShortDescription, DetailedDescription, Recipient, LocalError_Handling = False) Export
	
	Result = New Structure;
	Result.Insert("Group", Class);
	Result.Insert("SearchMasks", New Array);
	Result.Insert("ShortDescription", ShortDescription);
	Result.Insert("DetailedDescription", DetailedDescription);
	Result.Insert("Recipient", Recipient);
	Result.Insert("LocalError_Handling", LocalError_Handling);
	Return Result;
	
EndFunction

Function ErrorsClassifier() Export
	
	Result = New Array;
	GroupsTable = New Map;
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"MarkingErrorBlocking",
		NStr("vi = 'Lỗi dán nhãn';
			|ru = 'Ошибка маркировки';
			|en = 'Marking error'; fa = 'Marking error';
			|it = 'Marking error';
			|pl = 'Marking error';
			|tr = 'İşaretleme hatası'"),
		NStr("vi = 'Máy tính tiền đã chặn việc bán hàng hóa đã dán nhãn, bởi vì trong thời gian dài không thể gửi thông báo bán hàng hoặc nhận biên lai từ hệ thống dán nhãn. Thông thường, việc chặn xảy ra khi không có trao đổi dữ liệu với hệ thống thông tin dán nhãn trong khoảng một tháng. Cần khôi phục việc gửi thông báo và thực hiện đồng bộ hóa.';
			|ru = 'Касса заблокировала продажу маркированных товаров, так как в течение длительного времени не удаётся передать уведомления о продаже или получить квитанции от системы маркировки. Обычно блокировка возникает при отсутствии обмена с ИСМ в течение около месяца. Необходимо восстановить передачу уведомлений и выполнить синхронизацию.';
			|en = 'The cash register locked sales of marked goods, as it was impossible to send sales notifications or receive receipts from the marking system for a long time. Usually, a lock occurs when there is no exchange with the information marking system for about a month. Restore notification transmission and synchronize.'; fa = 'The cash register locked sales of marked goods, as it was impossible to send sales notifications or receive receipts from the marking system for a long time. Usually, a lock occurs when there is no exchange with the information marking system for about a month. Restore notification transmission and synchronize.';
			|it = 'The cash register locked sales of marked goods, as it was impossible to send sales notifications or receive receipts from the marking system for a long time. Usually, a lock occurs when there is no exchange with the information marking system for about a month. Restore notification transmission and synchronize.';
			|pl = 'The cash register locked sales of marked goods, as it was impossible to send sales notifications or receive receipts from the marking system for a long time. Usually, a lock occurs when there is no exchange with the information marking system for about a month. Restore notification transmission and synchronize.';
			|tr = 'Yazar kasa, işaretli ürünlerin satışını engelledi; çünkü uzun süredir satış bildirimleri iletilemiyor veya işaretleme sisteminden makbuz alınamıyor. Engel genellikle İYS ile yaklaşık bir ay boyunca veri alışverişi yapılmadığında ortaya çıkar. Bildirim aktarımının yeniden sağlanması ve senkronizasyon yapılması gerekir.'"),
		"User",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "MarkingErrorBlocking", NStr("vi = 'dán nhãn.*bị phong tỏa';
														|ru = 'маркиров.*заблокирована';
														|en = 'marking.*locked'; fa = 'marking.*locked';
														|it = 'marking.*locked';
														|pl = 'marking.*locked';
														|tr = 'işaretle.*bloke edildi'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = False;
	ErrorClass = NewErrorClass(
		"ErrorOfMarking",
		NStr("vi = 'Lỗi dán nhãn';
			|ru = 'Ошибка маркировки';
			|en = 'Marking error'; fa = 'Marking error';
			|it = 'Marking error';
			|pl = 'Marking error';
			|tr = 'İşaretleme hatası'"),
		NStr("vi = 'Mã dán nhãn không thể được xử lý hoặc kiểm tra bởi máy tính tiền. Hãy kiểm tra tính chính xác của mã dán nhãn, cũng như đảm bảo không có hạn chế hoặc chặn nào liên quan đến việc làm việc với dán nhãn. Sau khi sửa dữ liệu, hãy thực hiện lại thao tác. Nếu các bước này không hữu ích, hãy liên hệ với bộ phận hỗ trợ kỹ thuật của chương trình.';
			|ru = 'Код маркировки не может быть обработан или проверен ККТ. Проверьте корректность КМ, а также отсутствие ограничений или блокировок по работе с маркировкой. После исправления данных повторите операцию. Если эти действия не помогли, обратитесь в техническую поддержку программы.';
			|en = 'The marking code cannot be processed or verified by the cash register. Check that the marking code is correct, as well as that there are no restrictions or locks on operating with marking. After correcting the data, try again. If these steps do not help, contact the technical support of the program.'; fa = 'The marking code cannot be processed or verified by the cash register. Check that the marking code is correct, as well as that there are no restrictions or locks on operating with marking. After correcting the data, try again. If these steps do not help, contact the technical support of the program.';
			|it = 'The marking code cannot be processed or verified by the cash register. Check that the marking code is correct, as well as that there are no restrictions or locks on operating with marking. After correcting the data, try again. If these steps do not help, contact the technical support of the program.';
			|pl = 'The marking code cannot be processed or verified by the cash register. Check that the marking code is correct, as well as that there are no restrictions or locks on operating with marking. After correcting the data, try again. If these steps do not help, contact the technical support of the program.';
			|tr = 'İşaretleme kodu yazar kasa tarafından işlenemiyor veya doğrulanamıyor. İK''nın doğruluğunu ve işaretleme ile ilgili herhangi bir kısıtlama veya engel olup olmadığını kontrol edin. Verileri düzelttikten sonra işlemi tekrarlayın. Bu işlemler işe yaramazsa, programın teknik destek ekibiyle iletişime geçin.'"),
		"TechnicalSupportOfProgram",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "ErrorOfMarking", NStr("vi = 'không có.*MãDánNhãn|dán nhãn|kiểm soát.*nhãn hiệu|mã.*hàng hóa.*chưa được nhận diện|dán nhãn|công việc.*được dán nhãn|bộ đệm phiếu';
												|ru = 'отсутствует.*КМ|маркировк|контрольн.*марка|код.*товара.*не распозн|маркир|работа.*маркированн|буфер чека';
												|en = 'missing.*Marking code|marking|control*mark|product.*code.*not recognized|marking|work.*marked|receipt buffer'; fa = 'missing.*Marking code|marking|control*mark|product.*code.*not recognized|marking|work.*marked|receipt buffer';
												|it = 'missing.*Marking code|marking|control*mark|product.*code.*not recognized|marking|work.*marked|receipt buffer';
												|pl = 'missing.*Marking code|marking|control*mark|product.*code.*not recognized|marking|work.*marked|receipt buffer';
												|tr = 'mevcut değil.İK|işaretleme|kontrol.işaret|kod.ürün.tanınmadı|işaretle|iş.işaretlenmiş|fiş arabelleği'"));
	AddMask(GroupsTable, "ErrorOfMarking", NStr("vi = 'MãDánNhãn.*chưa được xác minh trước đó';
												|ru = 'КМ.*ранее не проверялся';
												|en = 'Marking code.*was not checked before'; fa = 'Marking code.*was not checked before';
												|it = 'Marking code.*was not checked before';
												|pl = 'Marking code.*was not checked before';
												|tr = 'İK.*daha önce kontrol edilmemiş'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"CommunicationError",
		NStr("vi = 'Lỗi liên kết';
			|ru = 'Ошибка связи';
			|en = 'Connection error'; fa = 'خطای اتصال';
			|it = 'Connection error';
			|pl = 'Connection error';
			|tr = 'Bağlantı hatası'"),
		NStr("vi = 'Việc liên kết với MTT hoặc bộ nhớ tài chính không có hoặc đã bị mất. Hãy kiểm tra nguồn điện, cáp, cổng kết nối và mạng. Sau khi khôi phục kết nối, hãy thực hiện lại thao tác. Nếu vấn đề vẫn tiếp diễn, hãy liên hệ với bộ phận hỗ trợ kỹ thuật của công ty bảo trì thiết bị.';
			|ru = 'Связь с ККТ или ФН отсутствует либо потеряна. Проверьте питание, кабели, порты и сетевое соединение. После восстановления связи повторите операцию. Если проблема сохраняется, обратитесь в техподдержку компании, обслуживающей оборудование.';
			|en = 'Connection to the cash register or fiscal storage is missing or lost. Check the power supply, cables, ports, and network connection. After the connection is restored, try again. If the issue persists, contact the technical support of the equipment maintenance company.'; fa = 'Connection to the cash register or fiscal storage is missing or lost. Check the power supply, cables, ports, and network connection. After the connection is restored, try again. If the issue persists, contact the technical support of the equipment maintenance company.';
			|it = 'Connection to the cash register or fiscal storage is missing or lost. Check the power supply, cables, ports, and network connection. After the connection is restored, try again. If the issue persists, contact the technical support of the equipment maintenance company.';
			|pl = 'Connection to the cash register or fiscal storage is missing or lost. Check the power supply, cables, ports, and network connection. After the connection is restored, try again. If the issue persists, contact the technical support of the equipment maintenance company.';
			|tr = 'Yazar kasa veya FH bağlantısı yok ya da kesildi. Güç kaynağını, kabloları, bağlantı noktalarını ve ağ bağlantısını kontrol edin. Bağlantı yeniden sağlandıktan sonra işlemi tekrarlayın. Sorun devam ederse, ekipmanı sağlayan firmanın teknik desteğine başvurun.'"),
		"User",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "CommunicationError", NStr("vi = 'chưa thực hiện kết nối|lỗi.*trao đổi|thiết bị.*(chưa phản hồi|bận)';
													|ru = 'соединение не установлено|ошибка.*обмена|устройство.*(не отвечает|занято)';
													|en = 'connection failed|error.*exchange|device.*(not responding|busy)'; fa = 'connection failed|error.*exchange|device.*(not responding|busy)';
													|it = 'connection failed|error.*exchange|device.*(not responding|busy)';
													|pl = 'connection failed|error.*exchange|device.*(not responding|busy)';
													|tr = 'bağlantı kurulamadı|iletişim.*hatası|cihaz.*(yanıt vermiyor|meşgul)'"));
	AddMask(GroupsTable, "CommunicationError", NStr("vi = 'trao đổi mạng|kết nối.*bị mất|chưa phản hồi hoặc không khả dụng|cổng không được *.|truy cập.*internet';
													|ru = 'сетевого обмена|соединение.*потеряно|не отвечает или недоступна|порт не *.|доступ.*интернет';
													|en = 'network exchange|connection.*lost|not responding or unavailable|port is not *.|access.*Internet'; fa = 'network exchange|connection.*lost|not responding or unavailable|port is not *.|access.*Internet';
													|it = 'network exchange|connection.*lost|not responding or unavailable|port is not *.|access.*Internet';
													|pl = 'network exchange|connection.*lost|not responding or unavailable|port is not *.|access.*Internet';
													|tr = 'ağ iletişimi|bağlantı.kesildi|yanıt vermiyor veya erişilemez|bağlantı noktası ... değil|internet.*erişim'"));
	AddMask(GroupsTable, "CommunicationError", NStr("vi = 'không có\s+liên kết|timeout|timed\s*out|cổng\s*com|port|thiết bị\s+không\s+được tìm thấy|đã vượt quá\s+khoảng thời gian|failed to connect|connection';
													|ru = 'нет\s+связи|timeout|timed\s*out|ком\s*порт|port|устройство\s+не\s+найдено|превышен\s+интервал|failed to connect|connection';
													|en = 'no\s+connection|timeout|timed\s*out|com\s*port|port|device\s+not\s+found|exceeded\s+interval|failed to connect|connection'; fa = 'no\s+connection|timeout|timed\s*out|com\s*port|port|device\s+not\s+found|exceeded\s+interval|failed to connect|connection';
													|it = 'no\s+connection|timeout|timed\s*out|com\s*port|port|device\s+not\s+found|exceeded\s+interval|failed to connect|connection';
													|pl = 'no\s+connection|timeout|timed\s*out|com\s*port|port|device\s+not\s+found|exceeded\s+interval|failed to connect|connection';
													|tr = 'bağlantıs+yok|zaman aşımı|süresdoldu|serisbağlantı noktası|port|cihazs+bulunamadı|süres+aşıldı|bağlantı başarısız|bağlantı'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"CCTStatusError",
		NStr("vi = 'Lỗi trạng thái';
			|ru = 'Ошибка статуса';
			|en = 'Status error'; fa = 'Status error';
			|it = 'Status error';
			|pl = 'Status error';
			|tr = 'Durum hatası'"),
		NStr("vi = 'Không thể thực hiện thao tác trong trạng thái hiện tại của máy tính tiền. Vui lòng đưa máy tính tiền về trạng thái hoạt động bằng cách hoàn tất việc lập chứng từ hoặc đóng ca. Sau đó, hãy lặp lại thao tác. Nếu sự cố vẫn tiếp diễn, hãy liên hệ với bộ phận hỗ trợ kỹ thuật của công ty đang hỗ trợ thiết bị.';
			|ru = 'Операция невозможна в текущем статусе ККТ. Приведите кассу в рабочее состояние, завершив оформление документов или закрыв смену. После этого повторите действие. Если проблема сохраняется, обратитесь в техническую поддержку компании, обслуживающей оборудование.';
			|en = 'The operation is impossible in the current cash register status. Make the cash register operational by completing document registration or closing the shift. Then try again. If the error persists, contact the technical support of the equipment maintenance company.'; fa = 'The operation is impossible in the current cash register status. Make the cash register operational by completing document registration or closing the shift. Then try again. If the error persists, contact the technical support of the equipment maintenance company.';
			|it = 'The operation is impossible in the current cash register status. Make the cash register operational by completing document registration or closing the shift. Then try again. If the error persists, contact the technical support of the equipment maintenance company.';
			|pl = 'The operation is impossible in the current cash register status. Make the cash register operational by completing document registration or closing the shift. Then try again. If the error persists, contact the technical support of the equipment maintenance company.';
			|tr = 'Yazar kasanın geçerli durumunda işlem gerçekleştirilemez. Belgeleri tamamlayarak veya vardiyayı kapatarak kasayı çalışır duruma getirin. Bundan sonra işlemi tekrarlayın. Sorun devam ederse, ekipmanı sağlayan firmanın teknik desteğine başvurun.'"),
		"User",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "CCTStatusError", NStr("vi = '73h|24\s*giờ|Trạng thái không chính xác MTT|Máy tính tiền này chưa được đăng ký với hệ thống đã chỉ định';
												|ru = '73h|24\s*час|Некорректное состояние ККТ|ККТ не зарегистрирована с указанной системой';
												|en = '73h|24\s*hour|Incorrect cash register status|cash register is not registered under the specified system'; fa = '73h|24\s*hour|Incorrect cash register status|cash register is not registered under the specified system';
												|it = '73h|24\s*hour|Incorrect cash register status|cash register is not registered under the specified system';
												|pl = '73h|24\s*hour|Incorrect cash register status|cash register is not registered under the specified system';
												|tr = '73h|24s*saat|Yazar kasanın geçersiz durumu|Yazar kasa belirtilen sistemle kayıtlı değil'"));
	AddMask(GroupsTable, "CCTStatusError", NStr("vi = 'phiên.*(bị đóng|được mở|không mở|hết hạn)|báo cáo.*bị gián đoạn|chứng từ.*(bị đóng|được mở|không đóng)|chức năng.*chưa được thực hiện|invalid\s*mode';
												|ru = 'смена.*(закрыта|открыта|не открыта|истекла)|отчет.*прерван|документ.*(закрыт|открыт|не закрыт)|функция.*не выполнима|invalid\s*mode';
												|en = 'shift.*(closed|open|not open|expired)|report.*aborted|document.*(closed|open|not closed)|function.*not feasible|invalid\s*mode'; fa = 'shift.*(closed|open|not open|expired)|report.*aborted|document.*(closed|open|not closed)|function.*not feasible|invalid\s*mode';
												|it = 'shift.*(closed|open|not open|expired)|report.*aborted|document.*(closed|open|not closed)|function.*not feasible|invalid\s*mode';
												|pl = 'shift.*(closed|open|not open|expired)|report.*aborted|document.*(closed|open|not closed)|function.*not feasible|invalid\s*mode';
												|tr = 'vardiya.(kapalı|açık|açık değil|süresi doldu)|rapor.kesildi|belge.(kapalı|açık|kapalı değil)|fonksiyon.gerçekleştirilemez|geçersizs*mod'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"ErrorInUserAttributes",
		NStr("vi = 'Lỗi mục tin';
			|ru = 'Ошибка реквизитов';
			|en = 'Attribute error'; fa = 'Attribute error';
			|it = 'Attribute error';
			|pl = 'Attribute error';
			|tr = 'Öznitelik hatası'"),
		NStr("vi = 'Một số trường bắt buộc của chứng từ đang thiếu hoặc được điền không chính xác. Hãy kiểm tra lại các mục tin và sửa các dữ liệu bị lỗi. Sau khi chỉnh sửa, hãy thực hiện lại thao tác. Nếu vẫn không khắc phục được, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật của chương trình.';
			|ru = 'Некоторые обязательные поля документа отсутствуют либо заполнены некорректно. Проверьте реквизиты и исправьте ошибочные данные. После внесения исправлений повторите операцию. Если эти действия не помогли, обратитесь в техническую поддержку программы.';
			|en = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If these steps do not help, contact the technical support of the program.'; fa = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If these steps do not help, contact the technical support of the program.';
			|it = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If these steps do not help, contact the technical support of the program.';
			|pl = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If these steps do not help, contact the technical support of the program.';
			|tr = 'Belgenin bazı zorunlu alanları eksik veya hatalı doldurulmuş. Bilgileri kontrol edin ve hatalı verileri düzeltin. Düzeltmeleri yaptıktan sonra işlemi tekrarlayın. Bu işlemler işe yaramazsa, programın teknik destek ekibiyle iletişime geçin.'"),
		"User",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "ErrorInUserAttributes", NStr("vi = '(thu ngân|mst|địa chỉ|doanh nghiệp).*chưa được điền';
														|ru = '(кассир|инн|адрес|организация).*не заполнен';
														|en = '(cashier|tin|address|company).*not filled in'; fa = '(cashier|tin|address|company).*not filled in';
														|it = '(cashier|tin|address|company).*not filled in';
														|pl = '(cashier|tin|address|company).*not filled in';
														|tr = '(kasiyer|vkn|adres|iş yeri).*doldurulmamış'"));
	AddMask(GroupsTable, "ErrorInUserAttributes", StrTemplate(NStr("vi = 'lỗi truyền %1';
																	|ru = 'ошибка передачи %1';
																	|en = '%1 transfer error'; fa = '%1 transfer error';
																	|it = '%1 transfer error';
																	|pl = '%1 transfer error';
																	|tr = '%1 aktarım hatası'"), "CustomerEmail"));
	AddMask(GroupsTable, "ErrorInUserAttributes", NStr("vi = 'chưa chỉ định.*(MST|ngày)';
														|ru = 'не указан.*(ИНН|дата)';
														|en = 'not specified.*(TIN|date)'; fa = 'not specified.*(TIN|date)';
														|it = 'not specified.*(TIN|date)';
														|pl = 'not specified.*(TIN|date)';
														|tr = 'belirtilmemiş.*(VKN|tarih)'"));
	AddMask(GroupsTable, "ErrorInUserAttributes", NStr("vi = 'không tương ứng với cài đặt khi đăng ký';
														|ru = 'не соответствует установкам при регистрации';
														|en = 'does not match the settings during registration'; fa = 'does not match the settings during registration';
														|it = 'does not match the settings during registration';
														|pl = 'does not match the settings during registration';
														|tr = 'kayıt sırasındaki ayarlarla uyuşmuyor'"));
	AddMask(GroupsTable, "ErrorInUserAttributes", NStr("vi = 'không có tiền để thanh toán|không.*(đủ|đủ) tiền mặt trong quầy thu ngân';
														|ru = 'нет денег для выплаты|не.*(достаточно|хватает) наличности в кассе';
														|en = 'no money to pay|not.*enough cash in cash register'; fa = 'no money to pay|not.*enough cash in cash register';
														|it = 'no money to pay|not.*enough cash in cash register';
														|pl = 'no money to pay|not.*enough cash in cash register';
														|tr = 'ödeme için para yok|kasadaki nakit.*(yetersiz|yetmiyor)'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"ErrorReceiptSize",
		NStr("vi = 'Lỗi dung lượng của phiếu';
			|ru = 'Ошибка размера чека';
			|en = 'Receipt size error'; fa = 'Receipt size error';
			|it = 'Receipt size error';
			|pl = 'Receipt size error';
			|tr = 'Fiş boyutu hatası'"),
		NStr("vi = 'Dung lượng của phiếu tính tiền vượt quá giới hạn cho phép do có quá nhiều mặt hàng. Để khắc phục, hãy giảm số lượng mặt hàng trong phiếu: chia một giao dịch lớn thành nhiều hóa đơn nhỏ hơn. Nếu vẫn không giải quyết được, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật của chương trình.';
			|ru = 'Размер кассового чека превышает допустимый предел из‑за избыточного количества позиций. Для устранения проблемы сократите число позиций в чеке: разделите одну крупную покупку на несколько чеков меньшего объёма. Если это не помогло, обратитесь в техническую поддержку программы.';
			|en = 'The cash receipt size exceeds the acceptable limit due to the excessive number of items. To fix the issue, reduce the number of items in the receipt: divide one large purchase into several smaller receipts. If this does not help, contact the technical support of the program.'; fa = 'The cash receipt size exceeds the acceptable limit due to the excessive number of items. To fix the issue, reduce the number of items in the receipt: divide one large purchase into several smaller receipts. If this does not help, contact the technical support of the program.';
			|it = 'The cash receipt size exceeds the acceptable limit due to the excessive number of items. To fix the issue, reduce the number of items in the receipt: divide one large purchase into several smaller receipts. If this does not help, contact the technical support of the program.';
			|pl = 'The cash receipt size exceeds the acceptable limit due to the excessive number of items. To fix the issue, reduce the number of items in the receipt: divide one large purchase into several smaller receipts. If this does not help, contact the technical support of the program.';
			|tr = 'Kasa fişinin boyutu, aşırı kalem sayısı nedeniyle izin verilen sınırı aşıyor. Sorunu gidermek için fişteki kalem sayısını azaltın: büyük bir alışverişi birkaç küçük fişe bölün. Bu işe yaramazsa, programın teknik destek ekibiyle iletişime geçin.'"),
		"User",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "ErrorReceiptSize", NStr("vi = 'vượt quá dung lượng TLV';
													|ru = 'превышение размеров TLV';
													|en = 'TLV size excess'; fa = 'TLV size excess';
													|it = 'TLV size excess';
													|pl = 'TLV size excess';
													|tr = 'TLV boyutlarının aşılması'"));
	AddMask(GroupsTable, "ErrorReceiptSize", NStr("vi = 'mặt hàng.*vượt quá.*giới hạn';
													|ru = 'позиций.*превысило.*лимит';
													|en = 'items.*exceeded.*limit'; fa = 'items.*exceeded.*limit';
													|it = 'items.*exceeded.*limit';
													|pl = 'items.*exceeded.*limit';
													|tr = 'kalemler.*limiti aştı'"));
	
	Result.Add(ErrorClass);
	
	LocalError_Handling = False;
	ErrorClass = NewErrorClass(
		"ErrorInSoftwareAttributes",
		NStr("vi = 'Lỗi mục tin';
			|ru = 'Ошибка реквизитов';
			|en = 'Attribute error'; fa = 'Attribute error';
			|it = 'Attribute error';
			|pl = 'Attribute error';
			|tr = 'Öznitelik hatası'"),
		NStr("vi = 'Một số trường bắt buộc của chứng từ đang thiếu hoặc được điền không chính xác. Hãy kiểm tra lại các mục tin và sửa các dữ liệu bị lỗi. Sau khi chỉnh sửa, hãy thực hiện lại thao tác. Nếu vẫn không khắc phục được, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật của chương trình.';
			|ru = 'Некоторые обязательные поля документа отсутствуют либо заполнены некорректно. Проверьте реквизиты и исправьте ошибочные данные. После внесения исправлений повторите операцию. Если проблема сохраняется, обратитесь в техническую поддержку программы.';
			|en = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If the issue persists, contact the technical support of the program.'; fa = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If the issue persists, contact the technical support of the program.';
			|it = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If the issue persists, contact the technical support of the program.';
			|pl = 'Some required document fields are missing or filled in incorrectly. Check the attributes and correct the errors. Then try again. If the issue persists, contact the technical support of the program.';
			|tr = 'Belgenin bazı zorunlu alanları eksik veya hatalı doldurulmuş. Bilgileri kontrol edin ve hatalı verileri düzeltin. Düzeltmeleri yaptıktan sonra işlemi tekrarlayın. Sorun devam ederse, programın teknik destek ekibiyle iletişime geçin.'"),
		"TechnicalSupportOfProgram",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "ErrorInSoftwareAttributes", NStr("vi = '(sai|đúng).*(số tiền|số lượng)';
															|ru = '(неверн|корректн).*(сумм|количеств)';
															|en = '(incorrect|correct).*(amount|quantity)'; fa = '(incorrect|correct).*(amount|quantity)';
															|it = '(incorrect|correct).*(amount|quantity)';
															|pl = '(incorrect|correct).*(amount|quantity)';
															|tr = '(yanlış|doğru).*(tutar|miktar)'"));
	AddMask(GroupsTable, "ErrorInSoftwareAttributes", NStr("vi = '(sai|bằng không) tổng số phiếu';
															|ru = '(неверный|нулевой) итог чека';
															|en = '(incorrect|zero) receipt total'; fa = '(incorrect|zero) receipt total';
															|it = '(incorrect|zero) receipt total';
															|pl = '(incorrect|zero) receipt total';
															|tr = '(geçersiz|sıfır) fiş toplamı'"));
	AddMask(GroupsTable, "ErrorInSoftwareAttributes", NStr("vi = 'số tiền.*(lớn hơn|nhỏ hơn|không bằng)';
															|ru = 'сумма.*(больше|меньше|не равна)';
															|en = 'amount.*(greater than|less than|not equal to)'; fa = 'amount.*(greater than|less than|not equal to)';
															|it = 'amount.*(greater than|less than|not equal to)';
															|pl = 'amount.*(greater than|less than|not equal to)';
															|tr = 'tutar.(büyük|küçük|eşit değil)'"));
	AddMask(GroupsTable, "ErrorInSoftwareAttributes", NStr("vi = 'không thể ghi lại mục tin của đại lý|không cần thanh toán theo phiếu này|không cần chỉ định thanh toán';
															|ru = 'невозможно записать реквизит агента|оплата по данному чеку не требуется|необходимо указать оплату';
															|en = 'cannot record the agent''s attribute|payment on this receipt is not required|payment must be specified'; fa = 'cannot record the agent''s attribute|payment on this receipt is not required|payment must be specified';
															|it = 'cannot record the agent''s attribute|payment on this receipt is not required|payment must be specified';
															|pl = 'cannot record the agent''s attribute|payment on this receipt is not required|payment must be specified';
															|tr = 'acente bilgisi yazılamıyor|bu fiş için ödeme gerekli değil|ödemeyi belirtmek gerekir'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = False;
	ErrorClass = NewErrorClass(
		"FNError",
		NStr("vi = 'Lỗi bộ nhớ tài chính';
			|ru = 'Ошибка ФН';
			|en = 'Fiscal storage error'; fa = 'Fiscal storage error';
			|it = 'Fiscal storage error';
			|pl = 'Fiscal storage error';
			|tr = 'FH hatası'"),
		NStr("vi = 'Bộ nhớ tài chính không thể thực hiện thao tác do lỗi tài nguyên hoặc sự cố giao diện nội bộ. Hãy kiểm tra trạng thái của bộ nhớ tài chính. Nếu cần, hãy thay thế bộ nhớ tài chính. Nếu sự cố vẫn tiếp diễn, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật của công ty đang hỗ trợ thiết bị.';
			|ru = 'Фискальный накопитель не смог выполнить операцию из‑за ошибки ресурса или сбоя внутреннего интерфейса. Проверьте состояние ФН. При необходимости произведите замену ФН. Если проблема сохраняется, обратитесь в техническую поддержку компании, обслуживающей оборудование.';
			|en = 'The fiscal storage was unable to perform the operation due to a resource error or an internal interface failure. Check the fiscal storage state. If necessary, replace the fiscal storage. If the issue persists, contact the technical support of the equipment maintenance company.'; fa = 'The fiscal storage was unable to perform the operation due to a resource error or an internal interface failure. Check the fiscal storage state. If necessary, replace the fiscal storage. If the issue persists, contact the technical support of the equipment maintenance company.';
			|it = 'The fiscal storage was unable to perform the operation due to a resource error or an internal interface failure. Check the fiscal storage state. If necessary, replace the fiscal storage. If the issue persists, contact the technical support of the equipment maintenance company.';
			|pl = 'The fiscal storage was unable to perform the operation due to a resource error or an internal interface failure. Check the fiscal storage state. If necessary, replace the fiscal storage. If the issue persists, contact the technical support of the equipment maintenance company.';
			|tr = 'Kaynak hatası veya dahili arayüz arızası nedeniyle finansal hafıza işlemi gerçekleştiremedi. Finansal hafıza''nın durumunu kontrol edin. Gerekirse Finansal hafızayı değiştirin. Sorun devam ederse, ekipmanı sağlayan firmanın teknik desteğine başvurun.'"),
		"TechnicalSupportOfKKT",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "FNError", NStr("vi = 'Bộ nhớ tài chính bị đóng|không có phản hồi từ bộ nhớ tài chính';
										|ru = 'фн закрыт|нет ответа от фн';
										|en = 'fiscal storage is closed|no response from fiscal storage'; fa = 'fiscal storage is closed|no response from fiscal storage';
										|it = 'fiscal storage is closed|no response from fiscal storage';
										|pl = 'fiscal storage is closed|no response from fiscal storage';
										|tr = 'fh kapalı|fh''den yanıt yok'"));
	AddMask(GroupsTable, "FNError", NStr("vi = 'đã dùng hết.*nguồn.*|đã dùng hết.*nguồn.*|nguồn.*(bộ nhớ tài chính|chứng từ tài chính)';
										|ru = 'исчерпан.*ресурс.*|ресурс.*исчерпан.*|ресурс.*(фн|фд)';
										|en = 'exhausted.*resource.*|resource.*exhausted.*|resource.*(fiscal storage|fiscal document)'; fa = 'exhausted.*resource.*|resource.*exhausted.*|resource.*(fiscal storage|fiscal document)';
										|it = 'exhausted.*resource.*|resource.*exhausted.*|resource.*(fiscal storage|fiscal document)';
										|pl = 'exhausted.*resource.*|resource.*exhausted.*|resource.*(fiscal storage|fiscal document)';
										|tr = 'kaynak.tükendi|kaynak.tükendi|kaynak.*(fh|fd)'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = False;
	ErrorClass = NewErrorClass(
		"TimeErrorFN",
		NStr("vi = 'Lỗi thời gian của bộ nhớ tài chính';
			|ru = 'Ошибка времени ФН';
			|en = 'Fiscal storage time error'; fa = 'Fiscal storage time error';
			|it = 'Fiscal storage time error';
			|pl = 'Fiscal storage time error';
			|tr = 'FH zaman hatası'"),
		NStr("vi = 'Đã xảy ra chênh lệch giữa thời gian hệ thống của máy tính tiền và bộ nhớ tài chính do lỗi đồng hồ thời gian thực hoặc cài đặt không chính xác. Để khắc phục, cần thiết lập lại ngày và giờ đúng trong phần cài đặt của máy tính tiền. Đồng thời, hãy kiểm tra việc đồng bộ với máy chủ thời gian và đối chiếu ngày giờ hiện tại trên thiết bị. Nếu sự cố vẫn tiếp diễn, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật của công ty đang hỗ trợ thiết bị.';
			|ru = 'Произошло расхождение системного времени ККТ и фискального накопителя из‑за сбоя часов реального времени или некорректных настроек. Для устранения проблемы необходимо установить корректную дату и время в настройках ККТ. Также следует проверить синхронизацию с сервером времени и сверить текущую дату и время на оборудовании. Если проблема сохраняется, обратитесь в техническую поддержку компании, обслуживающей оборудование.';
			|en = 'There was a discrepancy between the cash register time and the fiscal storage time due to a failure of the real‑time clock or incorrect settings. To fix the issue, set the correct date and time in the cash register settings. Also check the synchronization with the time server and check the current date and time on the hardware. If the issue persists, contact the technical support of the equipment maintenance company.'; fa = 'There was a discrepancy between the cash register time and the fiscal storage time due to a failure of the real‑time clock or incorrect settings. To fix the issue, set the correct date and time in the cash register settings. Also check the synchronization with the time server and check the current date and time on the hardware. If the issue persists, contact the technical support of the equipment maintenance company.';
			|it = 'There was a discrepancy between the cash register time and the fiscal storage time due to a failure of the real‑time clock or incorrect settings. To fix the issue, set the correct date and time in the cash register settings. Also check the synchronization with the time server and check the current date and time on the hardware. If the issue persists, contact the technical support of the equipment maintenance company.';
			|pl = 'There was a discrepancy between the cash register time and the fiscal storage time due to a failure of the real‑time clock or incorrect settings. To fix the issue, set the correct date and time in the cash register settings. Also check the synchronization with the time server and check the current date and time on the hardware. If the issue persists, contact the technical support of the equipment maintenance company.';
			|tr = 'Gerçek zamanlı saat arızası veya yanlış ayarlar nedeniyle yazar kasa sistem saati ile finansal hafıza arasında fark oluştu. Sorunu çözmek için yazar kasa ayarlarında doğru tarih ve saatin ayarlanması gerekir. Ayrıca, zaman sunucusuyla senkronizasyon kontrol edilmeli ve ekipmandaki geçerli tarih ve saat karşılaştırılmalıdır. Sorun devam ederse, ekipmanın bakımını yapan şirketin teknik destek ekibiyle iletişime geçin.'"),
		"TechnicalSupportOfKKT",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "TimeErrorFN", NStr("vi = 'lỗi đồng hồ|sai.*(ngày|thời gian|bộ nhớ tài chính|dữ liệu tài chính)|(chênh lệch|đã chênh lệch).*thời gian|hãy kiểm tra (ngày|thời gian)';
											|ru = 'сбой часов|неверн.*(дата|время|фн|фд)|(разница|расхожден).*времен|проверьте (дату|время)';
											|en = 'clock failure|incorrect*(date|time|fiscal storage|fiscal document)|(difference|discrepancy).*time|check (date|time)'; fa = 'clock failure|incorrect*(date|time|fiscal storage|fiscal document)|(difference|discrepancy).*time|check (date|time)';
											|it = 'clock failure|incorrect*(date|time|fiscal storage|fiscal document)|(difference|discrepancy).*time|check (date|time)';
											|pl = 'clock failure|incorrect*(date|time|fiscal storage|fiscal document)|(difference|discrepancy).*time|check (date|time)';
											|tr = 'saat arızası|yanlış.(tarih|saat|fh|fd)|(fark).zaman|(tarihi|saati) kontrol edin'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = False;
	ErrorClass = NewErrorClass(
		"LibraryError",
		NStr("vi = 'Lỗi Thư viện thiết bị được kết nối';
			|ru = 'Ошибка БПО';
			|en = 'PEL error'; fa = 'PEL error';
			|it = 'PEL error';
			|pl = 'PEL error';
			|tr = 'EDK hatası'"),
		NStr("vi = 'Lỗi đã xảy ra trong các cơ chế nội bộ của chương trình khi xử lý dữ liệu của thiết bị. Thư viện hệ thống không thể xử lý chính xác các tham số hoặc ID thiết bị. Để khắc phục, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật của chương trình.';
			|ru = 'Ошибка возникла во внутренних механизмах программы при обработке данных устройства. Встроенная библиотека не смогла корректно обработать параметры или идентификатор устройства. Для устранения проблемы обратитесь в техническую поддержку программы.';
			|en = 'The error occurred in the internal system procedures when processing device data. The built-in library failed to correctly process the device parameters or ID. To fix the issue, contact the technical support of the program.'; fa = 'The error occurred in the internal system procedures when processing device data. The built-in library failed to correctly process the device parameters or ID. To fix the issue, contact the technical support of the program.';
			|it = 'The error occurred in the internal system procedures when processing device data. The built-in library failed to correctly process the device parameters or ID. To fix the issue, contact the technical support of the program.';
			|pl = 'The error occurred in the internal system procedures when processing device data. The built-in library failed to correctly process the device parameters or ID. To fix the issue, contact the technical support of the program.';
			|tr = 'Cihaz verileri işlenirken programın dahili mekanizmalarında bir hata oluştu. Dahili kitaplık, parametreleri veya cihaz tanımlayıcısını doğru şekilde işleyemedi. Sorunu çözmek için programın teknik destek ekibiyle iletişime geçin.'"),
		"BPOTechnicalSupport",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "LibraryError", NStr("vi = 'sai.*id|không tìm thấy.*thiết bị|idthiếtbị|lỗi.*phân tích.*xml|xml.*lỗi';
												|ru = 'неверн.*идент|не найден.*устройств|идустройств|ошибка.*разбор.*xml|xml.*ошибка';
												|en = 'incorrect.*ID|not found.*device|device id|error.*analysis.*xml|xml.*error'; fa = 'incorrect.*ID|not found.*device|device id|error.*analysis.*xml|xml.*error';
												|it = 'incorrect.*ID|not found.*device|device id|error.*analysis.*xml|xml.*error';
												|pl = 'incorrect.*ID|not found.*device|device id|error.*analysis.*xml|xml.*error';
												|tr = 'yanlış.kimlik|cihaz bulunamadı|cihaz kimliği|xml ayrıştırma hatası|xml.*hatası'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"HardwareError",
		NStr("vi = 'Lỗi phần cứng';
			|ru = 'Ошибка аппаратная';
			|en = 'Hardware error'; fa = 'Hardware error';
			|it = 'Hardware error';
			|pl = 'Hardware error';
			|tr = 'Donanım hatası'"),
		NStr("vi = 'Cơ chế in của máy tính tiền chưa sẵn sàng hoạt động. Hãy kiểm tra xem có giấy in không, đã đóng nắp chưa và có vật cản nào không. Sau khi khắc phục xong sự cố, hãy lặp lại thao tác.';
			|ru = 'Печатающий механизм ККТ не готов к работе. Проверьте наличие бумаги, закрытие крышки и отсутствие механических блокировок. После устранения проблемы повторите операцию.';
			|en = 'The cash register printing device is not ready for operation. Check for paper, lid closure, and mechanical interlocks. Then try again.'; fa = 'The cash register printing device is not ready for operation. Check for paper, lid closure, and mechanical interlocks. Then try again.';
			|it = 'The cash register printing device is not ready for operation. Check for paper, lid closure, and mechanical interlocks. Then try again.';
			|pl = 'The cash register printing device is not ready for operation. Check for paper, lid closure, and mechanical interlocks. Then try again.';
			|tr = 'Yazar kasanın yazdırma mekanizması çalışmaya hazır değil. Kağıt olup olmadığını, kapağın kapalı olduğunu ve mekanik blokaj olmadığını kontrol edin. Sorun giderildikten sonra işlemi tekrarlayın.'"),
		"User",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "HardwareError", NStr("vi = 'giấy in|máy in|nắp|cơ khí|dao cắt|nguồn điện';
												|ru = 'бумаги|принтер|крышк|механическ|отрезчик|питани';
												|en = 'paper|printer|lid|mechanic|cutter|feed'; fa = 'paper|printer|lid|mechanic|cutter|feed';
												|it = 'paper|printer|lid|mechanic|cutter|feed';
												|pl = 'paper|printer|lid|mechanic|cutter|feed';
												|tr = 'kağıt|yazıcı|kapak|mekanik|kesici|güç'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"ErrorOutdatedDriver",
		NStr("vi = 'Lỗi driver lỗi thời';
			|ru = 'Ошибка утаревший драйвера';
			|en = 'Outdated driver error'; fa = 'Outdated driver error';
			|it = 'Outdated driver error';
			|pl = 'Outdated driver error';
			|tr = 'Güncel olmayan sürücü hatası'"),
		NStr("vi = 'Hãy cập nhật bộ cài đặt chính của driver và cập nhật phần mềm máy tính tiền. Nếu sự cố vẫn tiếp diễn, hãy liên hệ với bộ phận hỗ trợ kỹ thuật của nhà phát triển driver.';
			|ru = 'Обновите основную поставку драйвера, выполните обновление прошивки ККТ. Если проблема повторяется, требуется обращение в техническую поддержку разработчика драйвера.';
			|en = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.'; fa = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.';
			|it = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.';
			|pl = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.';
			|tr = 'Sürücünün ana sürümünü güncelleyin, yazar kasa yazılımını güncelleyin. Sorun devam ederse, sürücü geliştiricisinin teknik destek ekibiyle iletişime geçilmesi gerekir.'"),
		"TechnicalSupportOfKKT",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "ErrorOutdatedDriver", NStr("vi = 'giá trị.*tax.*';
													|ru = 'значение.*tax.*';
													|en = 'value.*tax.*'; fa = 'value.*tax.*';
													|it = 'value.*tax.*';
													|pl = 'value.*tax.*';
													|tr = 'değer.*vergi.*'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = True;
	ErrorClass = NewErrorClass(
		"CCTDriverError",
		NStr("vi = 'Lỗi driver';
			|ru = 'Ошибка драйвера';
			|en = 'Driver error'; fa = 'Driver error';
			|it = 'Driver error';
			|pl = 'Driver error';
			|tr = 'Sürücü hatası'"),
		NStr("vi = 'Trong quá trình thực hiện thao tác, driver của máy tính tiền hoặc mô-đun chương trình đã trả về lỗi. Hãy khởi động lại driver hoặc máy tính tiền và đảm bảo các bản cập nhật đã được cài đặt đúng. Thực hiện cập nhật phần mềm cho máy tính tiền. Nếu sự cố vẫn lặp lại, cần liên hệ bộ phận hỗ trợ kỹ thuật của nhà phát triển driver.';
			|ru = 'Во время выполнения операции драйвер ККТ или программный модуль вернул ошибку. Перезапустите драйвер или кассу и убедитесь в корректности установленных обновлений. Выполните обновление прошивки ККТ. Если проблема повторяется, требуется обращение в техническую поддержку разработчика драйвера.';
			|en = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.'; fa = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.';
			|it = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.';
			|pl = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.';
			|tr = 'İşlem sırasında yazar kasa sürücüsü veya yazılım modülü bir hata döndürdü. Sürücüyü veya kasanızı yeniden başlatın ve yüklenen güncellemelerin doğruluğunu kontrol edin. Yazar kasa yazılımını güncelleyin. Sorun devam ederse, sürücü geliştiricisinin teknik destek ekibiyle iletişime geçilmesi gerekir.'"),
		"TechnicalSupportOfKKT",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'sai (định dạng|tham số|thao tác)';
												|ru = 'некорректн(ая|ые|ый) (формат|параметр|операция)';
												|en = 'incorrect (format|parameter|operation)'; fa = 'incorrect (format|parameter|operation)';
												|it = 'incorrect (format|parameter|operation)';
												|pl = 'incorrect (format|parameter|operation)';
												|tr = 'geçersiz (format|parametre|işlem)'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'sai (định dạng|tham số|thao tác)';
												|ru = 'некорректн(ая|ые|ый) (формат|параметр|операция)';
												|en = 'incorrect (format|parameter|operation)'; fa = 'incorrect (format|parameter|operation)';
												|it = 'incorrect (format|parameter|operation)';
												|pl = 'incorrect (format|parameter|operation)';
												|tr = 'geçersiz (format|parametre|işlem)'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'sai (định dạng|giá trị) (lệnh|tham số)';
												|ru = 'неверн(ый|ое) (формат|значение) (команды|параметра)';
												|en = 'incorrect (command|parameter) (format|value)'; fa = 'incorrect (command|parameter) (format|value)';
												|it = 'incorrect (command|parameter) (format|value)';
												|pl = 'incorrect (command|parameter) (format|value)';
												|tr = '(komut|parametre) (formatı|değeri) yanlış'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'lỗi lập trình của mục tin|lỗi ghi tiêu đề gói|trường.*bị thiếu|trường.*sai|không còn dữ liệu';
												|ru = 'ошибка программирования реквизита|ошибка записи заголовка пакета|поле.*отсутствует|некоррект.*поля|нет больше данных';
												|en = 'attribute programming error|error writing package header|field.*missing|incorrect.*fields|no more data'; fa = 'attribute programming error|error writing package header|field.*missing|incorrect.*fields|no more data';
												|it = 'attribute programming error|error writing package header|field.*missing|incorrect.*fields|no more data';
												|pl = 'attribute programming error|error writing package header|field.*missing|incorrect.*fields|no more data';
												|tr = 'öznitelik programlama hatası|paket başlığı yazma hatası|alan.eksik|geçersiz.alanlar|daha fazla veri yok'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = '(mô hình|máy tính tiền|lệnh).*không được hỗ trợ|không hỗ trợ lệnh này|lệnh không được phép|lỗi.*driver|không hỗ trợ phần mềm điều khiển máy tính tiền|FFFFFFF8h';
												|ru = '(модель|ккт|команда).*не поддерживается|не поддерживает данную команду|команда не разрешена|ошибка.*драйвер|прошивка ККТ не поддерживает|FFFFFFF8h';
												|en = '(model|cash register|command).*not supported|does not support this command|command is not allowed|error.*driver|cash register firmware does not support|FFFFFFF8h'; fa = '(model|cash register|command).*not supported|does not support this command|command is not allowed|error.*driver|cash register firmware does not support|FFFFFFF8h';
												|it = '(model|cash register|command).*not supported|does not support this command|command is not allowed|error.*driver|cash register firmware does not support|FFFFFFF8h';
												|pl = '(model|cash register|command).*not supported|does not support this command|command is not allowed|error.*driver|cash register firmware does not support|FFFFFFF8h';
												|tr = '(model|yazar kasa|komut).desteklenmiyor|bu komutu desteklemiyor|komuta izin verilmiyor|sürücü.hatası|yazar kasa yazılımı (firmware) desteklemiyor|FFFFFFF8h'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'lỗi giấy phép|cập nhật phần mềm điều khiển';
												|ru = 'ошибка лицензии|обновите прошивку';
												|en = 'license error|update firmware'; fa = 'license error|update firmware';
												|it = 'license error|update firmware';
												|pl = 'license error|update firmware';
												|tr = 'lisans hatası|yazılımı güncelleyin'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'Lỗi nghiêm trọng máy tính tiền|lỗi không xác định|lỗi máy tính tiền.*sai|lỗi.*động cơ máy tính tiền';
												|ru = 'фатальная ошибка ККТ|неизвестная ошибка|ошибка ККТ.*неверн|ошибка.*движка ккт';
												|en = 'fatal cash register error|unknown error|cash register error.*incorrect|error.*cash register engine'; fa = 'fatal cash register error|unknown error|cash register error.*incorrect|error.*cash register engine';
												|it = 'fatal cash register error|unknown error|cash register error.*incorrect|error.*cash register engine';
												|pl = 'fatal cash register error|unknown error|cash register error.*incorrect|error.*cash register engine';
												|tr = 'yazar kasa önemli hatası|bilinmeyen hata|yazar kasa hatası.yanlış|yazar kasa motoru.hatası'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'Đang chờ lệnh để tiếp tục in|in lệnh trước đó';
												|ru = 'ожидание команды продолжения печати|идет печать предыдущей команды';
												|en = 'waiting for print continuation command|previous command is being printed'; fa = 'waiting for print continuation command|previous command is being printed';
												|it = 'waiting for print continuation command|previous command is being printed';
												|pl = 'waiting for print continuation command|previous command is being printed';
												|tr = 'devam komutu bekleniyor|önceki komutun yazdırılması sürüyor'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'không có thiết bị|lỗi bảng cài đặt|không được hỗ trợ ở chế độ này|không được hỗ trợ ở phiên bản này';
												|ru = 'нет устройства|сбой таблицы настроек|не поддерживается в данном режиме|не поддерживается в данной версии';
												|en = 'no device|settings table failure|not supported in this mode|not supported in this version'; fa = 'no device|settings table failure|not supported in this mode|not supported in this version';
												|it = 'no device|settings table failure|not supported in this mode|not supported in this version';
												|pl = 'no device|settings table failure|not supported in this mode|not supported in this version';
												|tr = 'cihaz yok|ayar tablosu arızası|bu modda desteklenmiyor|bu sürümde desteklenmiyor'"));
	AddMask(GroupsTable, "CCTDriverError", NStr("vi = 'Invalid password|Inout error|Command is invalid|служб.*UEMA';
												|ru = 'Invalid password|Inout error|Command is invalid|служб.*UEMA';
												|en = 'Invalid password|Inout error|Command is invalid|service.*UEMA'; fa = 'Invalid password|Inout error|Command is invalid|service.*UEMA';
												|it = 'Invalid password|Inout error|Command is invalid|service.*UEMA';
												|pl = 'Invalid password|Inout error|Command is invalid|service.*UEMA';
												|tr = 'Geçersiz şifre|Giriş-Çıkış hatası|Komut geçersiz|servis.*UEMA'"));
	Result.Add(ErrorClass);
	
	LocalError_Handling = False;
	ErrorClass = NewErrorClass(
		"DriverError",
		NStr("vi = 'Lỗi driver';
			|ru = 'Ошибка драйвера';
			|en = 'Driver error'; fa = 'Driver error';
			|it = 'Driver error';
			|pl = 'Driver error';
			|tr = 'Sürücü hatası'"),
		NStr("vi = 'Trong quá trình thực hiện thao tác, driver của máy tính tiền hoặc mô-đun chương trình đã trả về lỗi. Hãy khởi động lại driver hoặc máy tính tiền và đảm bảo các bản cập nhật đã được cài đặt đúng. Thực hiện cập nhật phần mềm cho máy tính tiền. Nếu sự cố vẫn lặp lại, cần liên hệ bộ phận hỗ trợ kỹ thuật của nhà phát triển driver.';
			|ru = 'Во время выполнения операции драйвер ККТ или программный модуль вернул ошибку. Перезапустите драйвер или кассу и убедитесь в корректности установленных обновлений. Выполните обновление прошивки ККТ. Если проблема повторяется, требуется обращение в техническую поддержку разработчика драйвера.';
			|en = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.'; fa = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.';
			|it = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.';
			|pl = 'During the operation, the cash register driver or the software module returned an error. Restart the driver or cash register and make sure that the installed updates are correct. Update the cash register firmware. If the error persists, contact the technical support of the driver developer.';
			|tr = 'İşlem sırasında yazar kasa sürücüsü veya yazılım modülü bir hata döndürdü. Sürücüyü veya kasanızı yeniden başlatın ve yüklenen güncellemelerin doğruluğunu kontrol edin. Yazar kasa yazılımını güncelleyin. Sorun devam ederse, sürücü geliştiricisinin teknik destek ekibiyle iletişime geçilmesi gerekir.'"),
		"TechnicalSupportOfKKT",
		LocalError_Handling);
	GroupsTable.Insert(ErrorClass.Group, ErrorClass);
	AddMask(GroupsTable, "DriverError", NStr("vi = 'lỗi in sản phẩm|vượt quá chiều dài của mục tin|gói ngắn';
											|ru = 'ошибка печати товарной позициии|превышение длины реквизита|короткий пакет';
											|en = 'item printing error|attribute length excess|short package'; fa = 'item printing error|attribute length excess|short package';
											|it = 'item printing error|attribute length excess|short package';
											|pl = 'item printing error|attribute length excess|short package';
											|tr = 'ürün konumları yazdırma hatası|öznitelik uzunluğu aşımı|kısa paket'"));
	AddMask(GroupsTable, "DriverError", NStr("vi = 'lỗi truyền thẻ|lỗi đọc dữ liệu';
											|ru = 'ошибка передачи тега|ошибка чтения данных';
											|en = 'tag transmission error|data reading error'; fa = 'tag transmission error|data reading error';
											|it = 'tag transmission error|data reading error';
											|pl = 'tag transmission error|data reading error';
											|tr = 'etiket iletim hatası|veri okuma hatası'"));
	AddMask(GroupsTable, "DriverError", NStr("vi = 'Số mức thuế không hợp lệ';
											|ru = 'Недопустимый номер ставки налога';
											|en = 'Invalid tax rate number'; fa = 'Invalid tax rate number';
											|it = 'Invalid tax rate number';
											|pl = 'Invalid tax rate number';
											|tr = 'Geçersiz vergi oranı'"));
	Result.Add(ErrorClass);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ClassificationOfErrors

Procedure AddMask(Classifier, Group, Mask)
	Classifier[Group].SearchMasks.Add(Lower(Mask));
EndProcedure

#EndRegion

#EndRegion

#EndIf

