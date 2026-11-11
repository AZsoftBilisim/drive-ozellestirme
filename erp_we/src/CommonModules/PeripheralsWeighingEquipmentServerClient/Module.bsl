
#Region Public

#Region DigitalRetailScales

// Receives weight from electronic scales.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGettingWeightWithElectronicScales(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "GetWeight"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.DigitalRetailScales = True;
		
		Notification = New CallbackDescription("StartOperationOnElectronicScaleEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn cân điện tử';
				|ru = 'Выберите электронные весы';
				|en = 'Select digital retail scales'; fa = 'Select digital retail scales';
				|it = 'Selezionare bilancia elettronica';
				|pl = 'Wybierz wagę elekstroniczną';
				|tr = 'Elektronik terazi seçin'"),
			NStr("vi = 'Không kết nối được cân điện tử.';
				|ru = 'Электронные весы не подключены.';
				|en = 'Digital retail scales are not connected.'; fa = 'Digital retail scales are not connected.';
				|it = 'Le bilance elettroniche non sono collegate.';
				|pl = 'Waga elektroniczna nie jest podłączona.';
				|tr = 'Elektronik terazi bağlı değil.'"), 
			NStr("vi = 'Chưa chọn cân điện tử.';
				|ru = 'Электронные весы не выбраны.';
				|en = 'Digital retail scales are not selected.'; fa = 'Digital retail scales are not selected.';
				|it = 'La bilancia elettronica non è selezionata.';
				|pl = 'Waga elektroniczna nie jest wybrana.';
				|tr = 'Elektronik terazi seçilmedi.'"));
	Else
		StartOperationOnElectronicScaleEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

// Start setting the tare weight of the electronic scales.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartSettingTareWeightOfElectronicScales(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "Calibrate"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.DigitalRetailScales = True;
		
		Notification = New CallbackDescription("StartOperationOnElectronicScaleEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn cân điện tử';
				|ru = 'Выберите электронные весы';
				|en = 'Select digital retail scales'; fa = 'Select digital retail scales';
				|it = 'Selezionare bilancia elettronica';
				|pl = 'Wybierz wagę elekstroniczną';
				|tr = 'Elektronik terazi seçin'"),
			NStr("vi = 'Không kết nối được cân điện tử.';
				|ru = 'Электронные весы не подключены.';
				|en = 'Digital retail scales are not connected.'; fa = 'Digital retail scales are not connected.';
				|it = 'Le bilance elettroniche non sono collegate.';
				|pl = 'Waga elektroniczna nie jest podłączona.';
				|tr = 'Elektronik terazi bağlı değil.'"), 
			NStr("vi = 'Chưa chọn cân điện tử.';
				|ru = 'Электронные весы не выбраны.';
				|en = 'Digital retail scales are not selected.'; fa = 'Digital retail scales are not selected.';
				|it = 'La bilancia elettronica non è selezionata.';
				|pl = 'Waga elektroniczna nie jest wybrana.';
				|tr = 'Elektronik terazi seçilmedi.'"));
	Else
		StartOperationOnElectronicScaleEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

#EndRegion 

#Region LabelPrintingScales

// Start uploading data to scales with label printing.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartUnloadingDataIntoScalesWithLabelPrinting(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "UploadGoods"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.LabelPrintingScales = True;
		
		Notification = New CallbackDescription("StartOperationOnElectronicScaleEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn cân có in nhãn tem';
				|ru = 'Выберите весы с печатью этикеток';
				|en = 'Select label printing scales'; fa = 'Select label printing scales';
				|it = 'Selezionare la bilancia con la stampa di etichette';
				|pl = 'Wybierz wagę z drukiem etykiet';
				|tr = 'Barkodlu terazi seçin'"),
			NStr("vi = 'Chưa kết nối cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не подключены.';
				|en = 'Label printing scales are not connected.'; fa = 'Label printing scales are not connected.';
				|it = 'Le bilance con stampa di etichette non sono collegate.';
				|pl = 'Waga z drukiem etykiet nie jest podłączona.';
				|tr = 'Barkodlu terazi bağlı değil.'"), 
			NStr("vi = 'Chưa chọn cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не выбраны.';
				|en = 'Label printing scales are not selected.'; fa = 'Label printing scales are not selected.';
				|it = 'La bilancia con stampa di etichette non è selezionata.';
				|pl = 'Waga z drukiem etykiet nie jest wybrana.';
				|tr = 'Barkodlu terazi seçilmedi.'"));
	Else
		StartOperationOnElectronicScaleEnd(OperationContext, OperationContext);
	EndIf

EndProcedure

// Start cleaning the data in the scales with label printing.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCleaningGoodsInScalesWithLabelPrinting(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "ClearBase"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.LabelPrintingScales = True;
		
		Notification = New CallbackDescription("StartOperationOnElectronicScaleEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn cân có in nhãn tem';
				|ru = 'Выберите весы с печатью этикеток';
				|en = 'Select label printing scales'; fa = 'Select label printing scales';
				|it = 'Selezionare la bilancia con la stampa di etichette';
				|pl = 'Wybierz wagę z drukiem etykiet';
				|tr = 'Barkodlu terazi seçin'"),
			NStr("vi = 'Chưa kết nối cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не подключены.';
				|en = 'Label printing scales are not connected.'; fa = 'Label printing scales are not connected.';
				|it = 'Le bilance con stampa di etichette non sono collegate.';
				|pl = 'Waga z drukiem etykiet nie jest podłączona.';
				|tr = 'Barkodlu terazi bağlı değil.'"), 
			NStr("vi = 'Chưa chọn cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не выбраны.';
				|en = 'Label printing scales are not selected.'; fa = 'Label printing scales are not selected.';
				|it = 'La bilancia con stampa di etichette non è selezionata.';
				|pl = 'Waga z drukiem etykiet nie jest wybrana.';
				|tr = 'Barkodlu terazi seçilmedi.'"));
	Else
		StartOperationOnElectronicScaleEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

// Start uploading images of goods to the scales with label printing.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartUploadingImagesOfGoodsToScalesWithLabelPrinting(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "UploadProductImages"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.LabelPrintingScales = True;
		
		Notification = New CallbackDescription("StartOperationOnElectronicScaleEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn cân có in nhãn tem';
				|ru = 'Выберите весы с печатью этикеток';
				|en = 'Select label printing scales'; fa = 'Select label printing scales';
				|it = 'Selezionare la bilancia con la stampa di etichette';
				|pl = 'Wybierz wagę z drukiem etykiet';
				|tr = 'Barkodlu terazi seçin'"),
			NStr("vi = 'Chưa kết nối cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не подключены.';
				|en = 'Label printing scales are not connected.'; fa = 'Label printing scales are not connected.';
				|it = 'Le bilance con stampa di etichette non sono collegate.';
				|pl = 'Waga z drukiem etykiet nie jest podłączona.';
				|tr = 'Barkodlu terazi bağlı değil.'"), 
			NStr("vi = 'Chưa chọn cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не выбраны.';
				|en = 'Label printing scales are not selected.'; fa = 'Label printing scales are not selected.';
				|it = 'La bilancia con stampa di etichette non è selezionata.';
				|pl = 'Waga z drukiem etykiet nie jest wybrana.';
				|tr = 'Barkodlu terazi seçilmedi.'"));
	Else
		StartOperationOnElectronicScaleEnd(OperationContext, OperationContext);
	EndIf

EndProcedure

// Upload data to the scales with label printing package.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartUploadingDataToScaleWithLabelPrintingPackage(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "UploadGoodsPacket"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.LabelPrintingScales = True;
		
		Notification = New CallbackDescription("StartOperationOnElectronicScaleEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn cân có in nhãn tem';
				|ru = 'Выберите весы с печатью этикеток';
				|en = 'Select label printing scales'; fa = 'Select label printing scales';
				|it = 'Выберите весы с печатью этикеток';
				|pl = 'Wybierz wagę z drukiem etykiet';
				|tr = 'Barkodlu terazi seçin'"),
			NStr("vi = 'Chưa kết nối cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не подключены.';
				|en = 'Label printing scales are not connected.'; fa = 'Label printing scales are not connected.';
				|it = 'Весы с печатью этикеток не подключены.';
				|pl = 'Waga z drukiem etykiet nie jest podłączona.';
				|tr = 'Barkodlu terazi bağlı değil.'"), 
			NStr("vi = 'Chưa chọn cân có in nhãn tem.';
				|ru = 'Весы с печатью этикеток не выбраны.';
				|en = 'Label printing scales are not selected.'; fa = 'Label printing scales are not selected.';
				|it = 'Весы с печатью этикеток не выбраны.';
				|pl = 'Waga z drukiem etykiet nie jest wybrana.';
				|tr = 'Barkodlu terazi seçilmedi.'"));
	Else
		StartOperationOnElectronicScaleEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

#EndRegion 

#EndRegion  

#Region Private

Procedure StartOperationOnElectronicScaleEnd(SelectionResult, OperationContext) Export
	
	If SelectionResult.Result Then 
		ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution(OperationContext.Command, "PeripheralsWeighingEquipmentServer",
		OperationContext.AdditionalParameters, OperationContext.PrepareData, OperationContext.ProcessData__);
		EquipmentManagerClient.StartCommandExecution(OperationContext.NotificationOnCompletion, OperationContext.ClientID, 
			SelectionResult.DeviceID, OperationContext.OperationParametersList, ParametersCommandExecution);
	Else
		RunCallback(OperationContext.NotificationOnCompletion, SelectionResult);
	EndIf;
	
EndProcedure

#EndRegion  
