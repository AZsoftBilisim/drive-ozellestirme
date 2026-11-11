
#Region Public

// Executes the driver command
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , OperationParametersList.PrepareData); 
	OperationContext.Insert("ProcessData__"       , OperationParametersList.ProcessData__); 
	OperationContext.Insert("Command"                , OperationParametersList.Command); 
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedDataTypes = New Array();
		SupportedDataTypes.Add("DigitalRetailScales");       
		
		Notification = New CallbackDescription("StartOfOperationNonCertifiedEquipmentEnd", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedDataTypes,
			NStr("vi = 'Hãy chọn thiết bị';
				|ru = 'Выберите оборудование';
				|en = 'Select the peripherals'; fa = 'Select the peripherals';
				|it = 'Выберите оборудование';
				|pl = 'Select the peripherals';
				|tr = 'Donanımı seçin'"),
			NStr("vi = 'Chưa kết nối thiết bị.';
				|ru = 'Оборудование не подключено.';
				|en = 'Peripheral is not connected.'; fa = 'Peripheral is not connected.';
				|it = 'Оборудование не подключено.';
				|pl = 'Sprzęt nie jest jeszcze podłączony.';
				|tr = 'Ekipman bağlı değil'"), 
			NStr("vi = 'Chưa chọn thiết bị.';
				|ru = 'Оборудование не выбрано.';
				|en = 'Peripheral is not selected.'; fa = 'Peripheral is not selected.';
				|it = 'Оборудование не выбрано.';
				|pl = 'Peripheral is not selected.';
				|tr = 'Donanım seçilmemiş.'"));
	Else
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		ExecutionResult.Result = True;
		ExecutionResult.DeviceID = DeviceID;
		StartOfOperationNonCertifiedEquipmentEnd(ExecutionResult, OperationContext);
	EndIf
	
EndProcedure

#EndRegion

#Region Private

Procedure StartOfOperationNonCertifiedEquipmentEnd(ExecutionResult, OperationContext) Export
	
	If ExecutionResult.Result Then 
		ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution(
			OperationContext.Command, 
			"UncertifiedPeripheralsServerCall",
			OperationContext.AdditionalParameters, 
			OperationContext.PrepareData, 
			OperationContext.ProcessData__);
		EquipmentManagerClient.StartCommandExecution(
			OperationContext.NotificationOnCompletion, 
			OperationContext.ClientID, 
			ExecutionResult.DeviceID, 
			OperationContext.OperationParametersList, 
			ParametersCommandExecution);
	Else
		RunCallback(OperationContext.NotificationOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure

#EndRegion  
