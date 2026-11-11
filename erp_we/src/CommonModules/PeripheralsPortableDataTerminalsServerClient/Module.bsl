
#Region Public

// Start loading data from the data collection terminal.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDownloadingDataFromTSD(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , True); 
	OperationContext.Insert("Command"  , "DownloadDocument"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.PortableDataCollectionTerminal = True;
		
		Notification = New CallbackDescription("StartOperationOnTSDEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn thiết bị thu thập dữ liệu';
				|ru = 'Выберите ТСД';
				|en = 'Select PDT'; fa = 'Select PDT';
				|it = 'Selezionare terminale assemblaggio dati';
				|pl = 'Wybierz terminal zbierania danych';
				|tr = 'TSD seçin'"),
			NStr("vi = 'Chưa kết nối thiết bị thu thập dữ liệu.';
				|ru = 'ТСД не подключен.';
				|en = 'PDT is not connected.'; fa = 'PDT is not connected.';
				|it = 'Terminale assemblaggio dati non connesso.';
				|pl = 'Terminal zbierania danych nie jest podłączony';
				|tr = 'TSD bağlı değil.'"), 
			NStr("vi = 'Chưa chọn thiết bị thu thập dữ liệu.';
				|ru = 'ТСД не выбраны.';
				|en = 'PDTs are not selected.'; fa = 'PDTs are not selected.';
				|it = 'Terminale assemblaggio dati non selezionato.';
				|pl = 'Terminale zbierania danych nie są wybrane.';
				|tr = 'TSD seçili değil.'"));
	Else
		StartOperationOnTSDEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

// Start uploading data to the data collection terminal.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartUploadingVTSDData(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "UploadDirectory"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.PortableDataCollectionTerminal = True;
		
		Notification = New CallbackDescription("StartOperationOnTSDEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn thiết bị thu thập dữ liệu';
				|ru = 'Выберите ТСД';
				|en = 'Select PDT'; fa = 'Select PDT';
				|it = 'Selezionare terminale assemblaggio dati';
				|pl = 'Wybierz terminal zbierania danych';
				|tr = 'TSD seçin'"),
			NStr("vi = 'Chưa kết nối thiết bị thu thập dữ liệu.';
				|ru = 'ТСД не подключен.';
				|en = 'PDT is not connected.'; fa = 'PDT is not connected.';
				|it = 'Terminale assemblaggio dati non connesso.';
				|pl = 'Terminal zbierania danych nie jest podłączony';
				|tr = 'TSD bağlı değil.'"), 
			NStr("vi = 'Chưa chọn thiết bị thu thập dữ liệu.';
				|ru = 'ТСД не выбраны.';
				|en = 'PDTs are not selected.'; fa = 'PDTs are not selected.';
				|it = 'Terminale assemblaggio dati non selezionato.';
				|pl = 'Terminale zbierania danych nie są wybrane.';
				|tr = 'TSD seçili değil.'"));
	Else
		StartOperationOnTSDEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

// Start clearing data in the data collection terminal.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCleaningVTSDData(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "ClearTable"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.PortableDataCollectionTerminal = True;
		
		Notification = New CallbackDescription("StartOperationOnTSDEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn thiết bị thu thập dữ liệu';
				|ru = 'Выберите ТСД';
				|en = 'Select PDT'; fa = 'Select PDT';
				|it = 'Selezionare terminale assemblaggio dati';
				|pl = 'Wybierz terminal zbierania danych';
				|tr = 'TSD seçin'"),
			NStr("vi = 'Chưa kết nối thiết bị thu thập dữ liệu.';
				|ru = 'ТСД не подключен.';
				|en = 'PDT is not connected.'; fa = 'PDT is not connected.';
				|it = 'Terminale assemblaggio dati non connesso.';
				|pl = 'Terminal zbierania danych nie jest podłączony';
				|tr = 'TSD bağlı değil.'"), 
			NStr("vi = 'Chưa chọn thiết bị thu thập dữ liệu.';
				|ru = 'ТСД не выбраны.';
				|en = 'PDTs are not selected.'; fa = 'PDTs are not selected.';
				|it = 'Terminale assemblaggio dati non selezionato.';
				|pl = 'Terminale zbierania danych nie są wybrane.';
				|tr = 'TSD seçili değil.'"));
	Else
		StartOperationOnTSDEnd(OperationContext, OperationContext);
	EndIf
	
EndProcedure

#EndRegion

#Region Private

Procedure StartOperationOnTSDEnd(SelectionResult, OperationContext) Export
	
	If SelectionResult.Result Then 
		ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution(OperationContext.Command, "PeripheralsPortableDataTerminalsServer",
		OperationContext.AdditionalParameters, OperationContext.PrepareData, OperationContext.ProcessData__);
		EquipmentManagerClient.StartCommandExecution(OperationContext.NotificationOnCompletion, OperationContext.ClientID, 
			SelectionResult.DeviceID, OperationContext.OperationParametersList, ParametersCommandExecution);
	Else
		RunCallback(OperationContext.NotificationOnCompletion, SelectionResult);
	EndIf;
	
EndProcedure

#EndRegion  
