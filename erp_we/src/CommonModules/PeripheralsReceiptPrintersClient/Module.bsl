
#Region Public

// Print the receipt on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCheckFiscalizationOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export;
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CheckFiscalization", 
		"PeripheralsReceiptPrinters", AdditionalParameters);
	// An error message will be generated to the technical support service.  
	ParametersCommandExecution.MessagesToTechSupportService = True;
	If OperationParametersList.Property("AutonomousCCT") And OperationParametersList.AutonomousCCT Then
		If CommonCELClient.AutonomousCCTIsUsed() Then
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient = CommonCELClient.CommonModule("PeripheralsStandaloneReceiptPrintersClient");
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient.StartCommandExecution(NotificationOnCompletion, 
				ClientID, OperationParametersList, ParametersCommandExecution, AdditionalParameters);
		EndIf;
	ElsIf OperationParametersList.CloudCashRegister Then
		If CommonCELClient.CloudCCTSAreUsed() Then
			ModuleEquipmentCloudCCTClient = CommonCELClient.CommonModule("EquipmentCheckPrintingCloudCREClient");
			ModuleEquipmentCloudCCTClient.StartCommandExecution(NotificationOnCompletion, 
				ClientID, DeviceID, OperationParametersList, ParametersCommandExecution);
		EndIf;
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
		
EndProcedure

// Print the receipt on the fiscal device as a package.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartFiscalizationOfCheckOnFiscalDevicePackage(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CheckFiscalizationPacket", 
		"PeripheralsReceiptPrinters", AdditionalParameters);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// To make collection on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if unspecified.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCollectionOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("Encash", 
		"PeripheralsReceiptPrinters", AdditionalParameters, True, True);
		
	If PeripheralsReceiptPrintersClientServer.ThisIsKKTWithoutConnection(OperationParametersList) Then
		If CommonCELClient.AutonomousCCTIsUsed() Then
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient = CommonCELClient.CommonModule("PeripheralsStandaloneReceiptPrintersClient");
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient.StartCommandExecution(NotificationOnCompletion, 
				ClientID, OperationParametersList, ParametersCommandExecution);
		EndIf;
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution); 
	EndIf;
		
EndProcedure

// Print the text on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure Start_PrintingText(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("PrepareDataClient", True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "PrintText"); 
	OperationContext.Insert("Result", True);
	
	SelectFiscalDevice(OperationContext);
	
EndProcedure

// Start opening a shift on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartOpeningShiftOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	Context = New Structure();
	Context.Insert("NotificationOnCompletion", NotificationOnCompletion);
	Context.Insert("ClientID"   , ClientID);
	Context.Insert("DeviceID", DeviceID);
	Context.Insert("OperationParametersList"      , OperationParametersList);
	Context.Insert("CashRegister"               , OperationParametersList.CashRegister);
	Notification = New CallbackDescription("StartOpeningShiftOnFiscalDevice_Completion", ThisObject, Context);
	
	OperationParametersList.Insert("AdditionalParameters", AdditionalParameters);
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("OpenShift", 
		"PeripheralsReceiptPrinters", AdditionalParameters, True, True);   
	// An error message will be generated to the technical support service.  
	ParametersCommandExecution.MessagesToTechSupportService = True;
	ParametersCommandExecution.ProcessData__Client = True;
	
	If OperationParametersList.AutonomousCCT Then
		If CommonCELClient.AutonomousCCTIsUsed() Then
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient = CommonCELClient.CommonModule("PeripheralsStandaloneReceiptPrintersClient");
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient.StartCommandExecution(Notification, 
				ClientID, OperationParametersList, ParametersCommandExecution);
			EndIf;
	ElsIf OperationParametersList.CloudCashRegister Then
		If CommonCELClient.CloudCCTSAreUsed() Then
			ModuleEquipmentCloudCCTClient = CommonCELClient.CommonModule("EquipmentCheckPrintingCloudCREClient");
			ModuleEquipmentCloudCCTClient.StartCommandExecution(Notification, 
				ClientID, DeviceID, OperationParametersList, ParametersCommandExecution);
		EndIf;
	Else
		EquipmentManagerClient.StartCommandExecution(Notification, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

// End of the operation opening a shift on the fiscal device.
//
// Parameters:
//   Result - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware.
//   Context - Structure
//
Procedure StartOpeningShiftOnFiscalDevice_Completion(Result, Context) Export
	
	If Result.Property("CREParameters") Then    
		CREParameters = Result.CREParameters;
		If PeripheralsReceiptPrintersClientServer.ThisIsKKTWithoutConnection(Context.OperationParametersList) Then
			CREParameters.Insert("EquipmentType", PredefinedValue("Enum.PeripheralTypes.CREWithDataTransfer"));
			CREParameters.Insert("IndicatesOfflineMode", True);
		EndIf;
		EquipmentManagerClientOverridable.WhenOpeningShiftOnKKT(Context.DeviceID, Result.CREParameters);
	EndIf;
	
	ShowWarningDriverRemovedFromSupport(Result);
	
	RunCallback(Context.NotificationOnCompletion, Result); 
	
EndProcedure

// Start closing the shift on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartClosingShiftOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationParametersList.Insert("AdditionalParameters", AdditionalParameters); 
		
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CloseShift", 
		"PeripheralsReceiptPrinters", AdditionalParameters, True, True);
	 // An error message will be generated to the technical support service.  
	ParametersCommandExecution.MessagesToTechSupportService = True;
	ParametersCommandExecution.ProcessData__Client = True;
	
	If PeripheralsReceiptPrintersClientServer.ThisIsKKTWithoutConnection(OperationParametersList) Then
		If CommonCELClient.AutonomousCCTIsUsed() Then
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient = CommonCELClient.CommonModule("PeripheralsStandaloneReceiptPrintersClient");
			ModuleEquipmentReceiptPrintingAutonomousDevicesClient.StartCommandExecution(NotificationOnCompletion, 
			ClientID, OperationParametersList, ParametersCommandExecution);
		EndIf;
	ElsIf OperationParametersList.CloudCashRegister Then
		If CommonCELClient.CloudCCTSAreUsed() Then
			ModuleEquipmentCloudCCTClient = CommonCELClient.CommonModule("EquipmentCheckPrintingCloudCREClient");
			ModuleEquipmentCloudCCTClient.StartCommandExecution(NotificationOnCompletion, 
			ClientID, DeviceID, OperationParametersList, ParametersCommandExecution);
		EndIf;
	Else
		OperationContext = New Structure();     
		OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
		Notification = New CallbackDescription("StartClosingShiftOnFiscalDevice_Completion", ThisObject, OperationContext);
		
		EquipmentManagerClient.StartCommandExecution(Notification, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

Procedure StartClosingShiftOnFiscalDevice_Completion(Result, OperationContext) Export
	
	ShowWarningDriverRemovedFromSupport(Result);
	
	RunCallback(OperationContext.NotificationOnCompletion, Result);      
	
EndProcedure

// Start opening the cash drawer of the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartOpeningCashDrawer(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export;
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "OpenCashDrawer"); 
	OperationContext.Insert("Result", True);
	
	SelectFiscalDevice(OperationContext);
	
EndProcedure

// Getting the width of the string in characters for the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGettingWidthOfPrinterLine(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "GetLineLength"); 
	OperationContext.Insert("Result", True);
	
	SelectFiscalDevice(OperationContext);
	
EndProcedure

// To cancel the receipt on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCheckCancellationOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("AnnulCheck", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);

EndProcedure

// Start generating a report on the current status of calculations on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGeneratingReportOnCurStateOfSettlements(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("PrepareDataClient", True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "ReportCurrentStatusOfSettlements"); 
	OperationContext.Insert("Result", True);
	
	SelectFiscalDevice(OperationContext);
	
EndProcedure

// Start generating a report report without blanking on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGeneratingReportWithoutBlanking(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("PrepareDataClient", True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "PrintXReport"); 
	OperationContext.Insert("Result", True);
	
	SelectFiscalDevice(OperationContext);
	
EndProcedure           

// To obtain the parameters of the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGettingFiscalDeviceParameters(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	If PeripheralsReceiptPrintersClientServer.ThisIsKKTWithoutConnection(OperationParametersList) Then
		
		CREParameters = PeripheralsReceiptPrintersClientServer.CRERegistrationParameters();
		CREParameters.Insert("EquipmentType", PredefinedValue("Enum.PeripheralTypes.CREWithDataTransfer"));
		CREParameters.Insert("IndicatesOfflineMode", True);

		OperationResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
		OperationResult.Insert("CREParameters" , CREParameters);
		
		RunCallback(NotificationOnCompletion, OperationResult);
		
	Else
		ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("GetDataKKT", 
			"PeripheralsReceiptPrinters", AdditionalParameters, False, True);
			
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

// Getting the current state of the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGettingCurStateOfFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("GetCurrentStatus", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, True);
	
	ParametersCommandExecution.PrepareDataClient = True; 
	ParametersCommandExecution.ProcessData__Client = True; 
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// Start the FN operation for the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartFNOperationForFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("OperationFN", 
		"PeripheralsReceiptPrinters", AdditionalParameters, True, True);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// Start forming a correction receipt on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGeneratingCorrectionReceiptOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("PrintReceiptCorrection", 
		"PeripheralsReceiptPrinters", AdditionalParameters, True, True);
	
	If OperationParametersList.CloudCashRegister Then
		If CommonCELClient.CloudCCTSAreUsed() Then
			ModuleEquipmentCloudCCTClient = CommonCELClient.CommonModule("EquipmentCheckPrintingCloudCREClient");
			ModuleEquipmentCloudCCTClient.StartCommandExecution(NotificationOnCompletion, 
			ClientID, DeviceID, OperationParametersList, ParametersCommandExecution);
		EndIf;
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

// Prints a copy of the receipt.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartPrintingCopyOfReceipt(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , True); 
	OperationContext.Insert("ProcessData__"       , True); 
	OperationContext.Insert("Command"  , "PrintCheckCopy"); 
	OperationContext.Insert("Result", True);
		
	SelectFiscalDevice(OperationContext);
	
EndProcedure

// Prints the QR code on the fiscal device.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartPrintingQRCodeOnFiscalDevice(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("PrepareDataClient", True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "PrintQRCode"); 
	OperationContext.Insert("Result", True);
	
	SelectFiscalDevice(OperationContext);
	
EndProcedure

// Performs the opening of the KM registration session.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartOpeningRegistrationSession(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("OpenSessionRegistrationKM", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
		
EndProcedure

// At the closing of the KM registration session.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartClosingRegistrationSession(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CloseSessionRegistrationKM", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
		
EndProcedure

// Start KM confirmation.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartKMConfirmation(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("ConfirmKM", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, False);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
		
EndProcedure

// Performs a KM request.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - See PeripheralsReceiptPrintersClientServer.KMVerificationParameters.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCheckingKM(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = EquipmentManagerClientServer.AdditionalOperationParameters(True);
	Else
		If AdditionalParameters.Property("LeaveConnected") Then    
			AdditionalParameters.LeaveConnected = True;     
		EndIf;
	EndIf;
		
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CheckKM", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, True);
	ParametersCommandExecution.Insert("ProcessDataInCaseOfError", True);
	ParametersCommandExecution.PrepareData = False;
	ParametersCommandExecution.PrepareDataClient = True;
	OperationParametersList.Insert("ClientID", ClientID);
	
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// Performs a repeated KM request, which performs verification without waiting for a response from the remote server and without user confirmation.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - See PeripheralsReceiptPrintersClientServer.KMVerificationParameters.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartReCheckingKM(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationParametersList.WaitingForResponseFromKMVerification = False;
	OperationParametersList.Insert("ClientID", ClientID);
	For Each RequestKM In OperationParametersList.KMRequests Do
		RequestKM.PerformValidation = False;
		RequestKM.KMSalesPermitRequest = False;
		RequestKM.IgnoreKMCheckResult  = True;
	EndDo;
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("CheckKM", 
		"PeripheralsReceiptPrinters", AdditionalParameters, True, True);
	ParametersCommandExecution.Insert("ProcessDataInCaseOfError", True);
	
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure


// The function returns whether the fiscal device supports.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Boolean - The fiscal device supports checking the marking codes
Function FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID) Export
	
	Return EquipmentReceiptPrintersServerCall.FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID);
	
EndFunction

// The function returns the FFD version for the fiscal device.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Undefined - The fiscal device supports the FFD version
Function FiscalDeviceSupportsFFDVersion(DeviceID) Export
	
	Return EquipmentReceiptPrintersServerCall.FiscalDeviceSupportsFFDVersion(DeviceID);
	
EndFunction            


#Region BatchProcessing

#Region FiscalizeReceiptWithCardPayment

// Returns a structure for filling in the data of payment by the acquiring terminal and fiscalization
//
// Returns:
//   Structure:
//     * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//     * NotificationOfQuestionToUser - CallbackDescription - Description of the user notification, for self-issuance 
//                            of a message, this notification will be triggered in case of a negative response from the acquiring 
//                            terminal upon payment, the result of the package of operations will be transferred to the procedure, 
//                            as well as the structure containing the package context, if you want to continue the package execution,
//                            then you will need to call the "Start" procedure 
//                            in the hardware module._Continue execution" or
//                            "Start fiscalizationcheck with a payment card_Repeat the payment."
//                            by passing this context there.
//                            The notification procedure contains the following parameters:
//         The result is A Structure:
//           * OperationResult - See the resultfiscalizationcasoplatoycard
//           * OperationContext - Structure - the context of the operation package to be passed to the procedure
//                            "Hardware Printing Device Client.Start the fiscalization of the payment card_Continue Execution"
//                            to continue executing the package
//         Additional parameters - Any - value passed when creating an alert
//     * SlipReceiptInBodyOfFiscal - Boolean, Undefined - Output a slip check in the fiscal body, a true slip check will be output
//                            in the fiscal body, a false short slip check will not be output, An indefinite short slip check 
//                            will be output if the hardware driver supports it.
//
// Example:
//   Defining the user notification procedure
//   The procedure of the user's question Completion(Result, additional parameters)
//      of the operation result = Result.Iteration ResultsreFerences;
//      ContextoPeration = Result.ContextoPeration;
//      ...
//      continue the execution of the package of operations
//      Equipmentexprinting device Client.Start fiscalizationcheck with a payment card_Continue execution (Truth, ContextoPeration);
//   End of the procedure
// 
Function ParametersFiscalizationOfReceiptWithPaymentByCard() Export
	
	Result = ParametersAcquisitionOfOperationWithFiscalization();
	Return Result;
	
EndFunction

// Performs payment at the acquiring terminal, and then fiscalization of the receipt with the seal of the slip receipt in the body of the fiscal one,
// if the operation during fiscalization ended unsuccessfully, then the emergency cancellation of the last operation at 
// the acquiring terminal occurs.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - Description of the procedure that will be called at the End of the operation
//                             with the following parameters:
//     * Result - See the resultfiscalizationcasoplatoycard
//   ClientID - ClientApplicationForm - the ID of the form.
//   CCTID - CatalogRef.Peripherals - The CCT on which the fiscal receipt
//                      containing the slip receipt will be printed.
//   IDOfItem - CatalogRef.Peripherals - Acquiring terminal for processing the transaction.
//   OperationParametersList - See ParametersFiscalizationOfReceiptWithPaymentByCard
//   AdditionalParameters - Structure - Additional parameters that can be passed in 
//                             the payment and fiscalization operations.
Procedure StartFiscalizingReceiptWithCardPayment(NotificationOnCompletion, ClientID, CCTID, 
	IDOfItem, OperationParametersList, AdditionalParameters = Undefined) Export
	
	// prepare the context of a package of operations
	OperationContext = ContextOfOperationOfAcquiringWithFiscalization();
	OperationContext.OperationType = "FiscalizationOfPaymentReceipt";

	OperationContext.CompletionNotification = NotificationOnCompletion;
	OperationContext.ClientID = ClientID;
	OperationContext.CCTID     = CCTID;
	OperationContext.IDOfItem      = IDOfItem;
	FillPropertyValues(OperationContext, OperationParametersList);
	
	PrepareContextOfBatchOperation(OperationContext, AdditionalParameters);

	// Select ET if no specific one is specified
	NotificationOfConnectionEnd = New CallbackDescription("StartEqualizationOperationWithFiscalization_AcquiringOperation",
		ThisObject,
		OperationContext);
	BatchProcessing_DeviceSelection(NotificationOfConnectionEnd, OperationContext);

EndProcedure

// Starts the continuation of the package execution, after processing the user's question, or a successful operation on 
// the acquiring terminal
// 
// Parameters:
//   Result - Boolean - If True, then the operation continues, otherwise
//               the user is notified about the package shutdown.
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartFiscalizationOfCardPaymentReceipt_ContinueExecution(Result, OperationContext) Export
	
	ErrorDescription = OperationContext.ResultOfAcquiringOperationExecution.ErrorDescription;

	If Result Then
		StartEqualizingOperationWithFiscalization_Fiscalization(OperationContext);
	Else
		OperationContext.Result = False;
		OperationContext.ErrorDescription = ErrorDescription;
		PrintSlipReceiptAsTextDocument("Cancel", OperationContext);
	EndIf;
	
EndProcedure

// Launches the re-acquiring operation.
// 
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartFiscalizingReceiptWithCardPayment_RepeatPayment(OperationContext) Export
	
	ErrorDescription = OperationContext.ResultOfAcquiringOperationExecution.ErrorDescription;

	ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
	ExecutionResult.Result              = True;
	ExecutionResult.ErrorDescription         = ErrorDescription;
	ExecutionResult.ConnectedDevice = OperationContext.ConnectedET;
	StartEqualizationOperationWithFiscalization_AcquiringOperation(ExecutionResult, OperationContext);
	
EndProcedure

#EndRegion

#Region PurchaseWithEnrollment

// Returns the structure for filling in the payment data by the acquiring terminal and fiscalization
//
// Returns:
//   Structure:
//     * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//     * NotificationOfQuestionToUser - CallbackDescription - Description of the user notification, for self-issuance 
//                            of a message, this notification will be triggered in case of a negative response from the acquiring 
//                            terminal upon payment, the result of the package of operations will be transferred to the procedure, 
//                            as well as the structure containing the package context, if you want to continue the package execution,
//                            then you will need to call the "Start" procedure 
//                            in the hardware module._Continue execution" or
//                            "Start fiscalizationcheck with a payment card_Repeat the payment."
//                            by passing this context there.
//                            The notification procedure contains the following parameters:
//         The result is A Structure:
//           * OperationResult - See the resultfiscalizationcasoplatoycard
//           * OperationContext - Structure - the context of the operation package to be passed to the procedure
//                            "Hardware Printing Device Client.Start the fiscalization of the payment card_Continue Execution"
//                            to continue executing the package
//         Additional parameters - Any - value passed when creating an alert
//     * SlipReceiptInBodyOfFiscal - Boolean, Undefined - Output a slip check in the fiscal body, a true slip check will be output
//                            in the fiscal body, a false short slip check will not be output, An indefinite short slip check 
//                            will be output if the hardware driver supports it.
//
// Example:
//   Defining the user notification procedure
//   The procedure of the user's question Completion(Result, additional parameters)
//      of the operation result = Result.Iteration ResultsreFerences;
//      ContextoPeration = Result.ContextoPeration;
//      ...
//      continue the execution of the package of operations
//      Equipmentexprinting device Client.Start fiscalizationcheck with a payment card_Continue execution (Truth, ContextoPeration);
//   End of the procedure
// 
Function ParametersPurchaseWithDeposit() Export
	
	Result = ParametersAcquisitionOfOperationWithFiscalization();
	Return Result;
	
EndFunction

// Performs payment at the acquiring terminal, and then fiscalization of the receipt with the seal of the slip receipt in the body of the fiscal one,
// if the operation during fiscalization ended unsuccessfully, then the emergency cancellation of the last operation at 
// the acquiring terminal occurs.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - Description of the procedure that will be called at the End of the operation
//                             with the following parameters:
//     * Result - See the resultfiscalizationcasoplatoycard
//   ClientID - ClientApplicationForm - the ID of the form.
//   CCTID - CatalogRef.Peripherals - The CCT on which the fiscal receipt
//                      containing the slip receipt will be printed.
//   IDOfItem - CatalogRef.Peripherals - Acquiring terminal for processing the transaction.
//   OperationParametersList - See ParametersFiscalizationOfReceiptWithPaymentByCard
//   AdditionalParameters - Structure - Additional parameters that can be passed in 
//                             the payment and fiscalization operations.
Procedure StartPurchaseWithDeposit(NotificationOnCompletion, ClientID, CCTID, 
	IDOfItem, OperationParametersList, AdditionalParameters = Undefined) Export
	
	// prepare the context of a package of operations
	OperationContext = ContextOfOperationOfAcquiringWithFiscalization();
	OperationContext.OperationType = "PurchaseWithEnrollment";
	
	OperationContext.CompletionNotification = NotificationOnCompletion;
	OperationContext.ClientID = ClientID;
	OperationContext.CCTID     = CCTID;
	OperationContext.IDOfItem      = IDOfItem;
	FillPropertyValues(OperationContext, OperationParametersList);
	
	PrepareContextOfBatchOperation(OperationContext, AdditionalParameters);

	// Select ET if no specific one is specified
	NotificationOfConnectionEnd = New CallbackDescription("StartEqualizationOperationWithFiscalization_AcquiringOperation",
		ThisObject,
		OperationContext);
	BatchProcessing_DeviceSelection(NotificationOfConnectionEnd, OperationContext);

EndProcedure

// Starts the continuation of the package execution, after processing the user's question, or a successful operation on 
// the acquiring terminal
// 
// Parameters:
//   Result - Boolean - If True, then the operation continues, otherwise
//               the user is notified about the package shutdown.
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartPurchaseWithDeposit_ContinueExecution(Result, OperationContext) Export
	
	ErrorDescription = OperationContext.ResultOfAcquiringOperationExecution.ErrorDescription;

	If Result Then
		StartEqualizingOperationWithFiscalization_Fiscalization(OperationContext);
	Else
		OperationContext.Result = False;
		OperationContext.ErrorDescription = ErrorDescription;
		PrintSlipReceiptAsTextDocument("Cancel", OperationContext);
	EndIf;
	
EndProcedure

// Launches the re-acquiring operation.
// 
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartPurchaseWithDeposit_RepeatPayment(OperationContext) Export
	
	ErrorDescription = OperationContext.ResultOfAcquiringOperationExecution.ErrorDescription;

	ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
	ExecutionResult.Result              = True;
	ExecutionResult.ErrorDescription         = ErrorDescription;
	ExecutionResult.ConnectedDevice = OperationContext.ConnectedET;
	StartEqualizationOperationWithFiscalization_AcquiringOperation(ExecutionResult, OperationContext);
	
EndProcedure

#EndRegion

#Region SaleWithCashIssue

// Returns a structure for filling in the data of a cash withdrawal sale operation
//
// Returns:
//   Structure:
//     * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * FiscalizationParametersOfIssueReceipt - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * RefundReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//     * AgentAttribute - EnumRef.AgentCharacteristics - agent attribute for automatic receipt generation,
//                            see standard, default Bank payment agent
//     * AgentData - See PeripheralsReceiptPrintersClientServer.ParametersAgentData
//     * VendorData - See PeripheralsReceiptPrintersClientServer.ParametersSupplierData
//     * SlipReceiptInBodyOfFiscal - Boolean, Undefined - Output a slip check in the fiscal body, a true slip check will be output
//                            in the fiscal body, a false short slip check will not be output, An indefinite short slip check 
//                            will be output if the hardware driver supports it.
//     * DisplayUserNotifications - Boolean - if True is set (by default), then if an operation
//                                         in the package fails, a message will be displayed to the user.
//     * IssueAmount - Number - cash withdrawal amount
Function ParametersSaleWithCashWithdrawal() Export
	
	ParametersOfSaleReceiptFiscalizationOperation  = PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation();
	ParametersOfAcquiringOperation  = Undefined;
	ParametersAgentData                     = PeripheralsReceiptPrintersClientServer.ParametersAgentData();
	ParametersSupplierData                 = PeripheralsReceiptPrintersClientServer.ParametersSupplierData();
	AgentAttribute                             = PredefinedValue("Enum.AgentCharacteristics.BankPayingAgent");
	
	If CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
		ParametersOfAcquiringOperation = ModuleEquipmentPaymentSystemsClientServer.ParametersOfAcquiringOperation();
	EndIf;
	
	Result = New Structure();
	Result.Insert("ReceiptFiscalizationParameters",                ParametersOfSaleReceiptFiscalizationOperation);
	Result.Insert("FiscalizationParametersOfIssueReceipt",          Undefined);
	Result.Insert("RefundReceiptFiscalizationParameters",        Undefined);
	Result.Insert("ParametersOfAcquiringOperation", Undefined);
	Result.Insert("AgentAttribute",                            AgentAttribute);
	Result.Insert("AgentData",                             ParametersAgentData);
	Result.Insert("VendorData",                         ParametersSupplierData);
	Result.Insert("SlipReceiptInBodyOfFiscal",                  Undefined);
	Result.Insert("DisplayUserNotifications",          False);
	Result.Insert("IssueAmount",                              0);
	Result.Insert("DocumentBasisOfIssue",                  Undefined);
	Result.Insert("DocumentBasisOfRefund",                Undefined);
	Result.Insert("QrCardAttributes",                         "");
	
	Return Result;
	
EndFunction

// Fills in the parameters of the fiscalization of the issuance receipt, according to the acquiring operation, the parameters of the sales receipt,
// and the data transmitted in the operation parameters, then they will be received from the sales receipt in accordance 
// with the guidelines for FFD 1.05 and 1.1 of the Federal Tax Service of Russia 
//
// Parameters:
//   OperationParametersList - See ParametersSaleWithCashWithdrawal
//
Procedure FillInParametersOfIssueReceipt(OperationParametersList) Export
	AgentAttribute                            = OperationParametersList.AgentAttribute;
	AgentData                             = OperationParametersList.AgentData;
	VendorData                         = OperationParametersList.VendorData;
	ReceiptFiscalizationParameters                = OperationParametersList.ReceiptFiscalizationParameters;
	ParametersOfAcquiringOperation = OperationParametersList.ParametersOfAcquiringOperation;
	AmountOfCash                            = ParametersOfAcquiringOperation.AmountOfCash;

	// create a cash withdrawal receipt
	ReceiptParameters = PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation();
	
	ListOfPropertiesToCopy = "DocumentBasis, Organization, RetailFacility, Electronically, Sends1CSMS, 
		|Sends1CEmail, TaxationSystem, SettlementAddress, PlaceOfSettlement, MachineNumber, EmailSender, 
		|BuyerEmail, BuyerNumber, Recipient, BeneficiaryTIN, PersonalDataSubject, ThereIsPersonalData,
		|PersonalDataType, SerialNumber, CompanyName, CompanyTIN, CompanyCRTR, StoreAddress, 
		|StoreName_, CheckoutNumber, ShiftNumber, DateTime, HeaderText, FooterText, CopiesOfReceipt, CashRegister";
	FillPropertyValues(ReceiptParameters, ReceiptFiscalizationParameters, ListOfPropertiesToCopy);

	If ValueIsFilled(OperationParametersList.DocumentBasisOfIssue) Then
		ReceiptParameters.DocumentBasis = OperationParametersList.DocumentBasisOfIssue;
	EndIf;
	ReceiptParameters.CalculationType        = PredefinedValue("Enum.CashSettlementTypes.CashOutflow");
	ReceiptParameters.ReceiptNumber         = Number(ReceiptFiscalizationParameters.ReceiptNumber) + 1;
	
	FillPropertyValues(ReceiptParameters.BuyerInformation, ReceiptFiscalizationParameters.BuyerInformation);
	
	// Check positions for fiscalization.
	ReceiptParameters.ReceiptPositions.Clear();
	LineOfReceiptPosition = PeripheralsReceiptPrintersClientServer.ParametersOfReceiptSFiscalLine(); 
	LineOfReceiptPosition.ItemLineNumber      = 1;
	LineOfReceiptPosition.Description           = NStr("vi = 'Rút tiền mặt';
														|ru = 'Выдача наличных денежных средств';
														|en = 'Cash issue'; fa = 'Cash issue';
														|it = 'Emissione contanti';
														|pl = 'Wydanie gotówki';
														|tr = 'Küçük kasa nakit çekimleri'");
	LineOfReceiptPosition.Count             = 1;
	LineOfReceiptPosition.Price                   = AmountOfCash;
	LineOfReceiptPosition.DiscountedPrice         = AmountOfCash;
	LineOfReceiptPosition.Sum                  = AmountOfCash;
	LineOfReceiptPosition.VATRate              = Undefined;
	LineOfReceiptPosition.VATAmount               = 0;
	LineOfReceiptPosition.UnitOfMeasure       = NStr("vi = 'Chiếc';
													|ru = 'Штука';
													|en = 'Piece'; fa = 'قطعه';
													|it = 'Pezzo';
													|pl = 'Piece';
													|tr = 'Tanesi'");
	LineOfReceiptPosition.UnitCode    = "796";
	LineOfReceiptPosition.AgentData           = ReceiptParameters.AgentData;
	LineOfReceiptPosition.VendorData       = ReceiptParameters.VendorData;
	LineOfReceiptPosition.ShowsCalculationMethod  = PredefinedValue("Enum.CalculationMethodFlags.TransferWithFullPayment");
	LineOfReceiptPosition.SettlementSubjectFlag = PredefinedValue("Enum.SettlementSubjectFlags.OperationService");
	LineOfReceiptPosition.AttributeOfAgentForSubjectOfCalculation = AgentAttribute;
	LineOfReceiptPosition.AgentData           = AgentData;
	LineOfReceiptPosition.VendorData       = VendorData;
	
	
	ReceiptParameters.ReceiptPositions.Add(LineOfReceiptPosition);
	
	ReceiptParameters.TableOfPayment.Clear();
	PaymentLine_           = PeripheralsReceiptPrintersClientServer.PaymentLineParameters(); 
	PaymentLine_.Sum     = AmountOfCash; 
	PaymentLine_.TypeOfPayment = PredefinedValue("Enum.CREPaymentTypes.CashPayment");
	ReceiptParameters.TableOfPayment.Add(PaymentLine_);

	ReceiptParameters.DetailedPayment.Clear();
	
	OperationParametersList.FiscalizationParametersOfIssueReceipt = ReceiptParameters;
	
EndProcedure

// Fills in the parameters of the fiscalization of the return receipt generated in case of non-fulfillment of the fiscalization of the issuance receipt, 
// according to the parameters of the sales receipt
// 
// Parameters:
//   OperationParametersList - See ParametersSaleWithCashWithdrawal
//
Procedure FillInRefundReceiptParameters(OperationParametersList) Export

	ReceiptFiscalizationParameters                = OperationParametersList.ReceiptFiscalizationParameters;
	
	// create a refund receipt
	ReceiptParameters = PeripheralsReceiptPrintersClientServer.ParametersOfCorrectionReceiptOperation();
	
	FillPropertyValues(ReceiptParameters, ReceiptFiscalizationParameters);
	ReceiptParameters.ReceiptNumber  = Number(ReceiptFiscalizationParameters.ReceiptNumber) + 1;
	ReceiptParameters.CalculationType = PredefinedValue("Enum.CashSettlementTypes.Refund");
	If ValueIsFilled(OperationParametersList.DocumentBasisOfRefund) Then
		ReceiptParameters.DocumentBasis = OperationParametersList.DocumentBasisOfRefund;
	ElsIf ValueIsFilled(OperationParametersList.DocumentBasisOfIssue) Then
		ReceiptParameters.DocumentBasis = OperationParametersList.DocumentBasisOfIssue;
	EndIf;
	
	OperationParametersList.RefundReceiptFiscalizationParameters = ReceiptParameters;

EndProcedure

// Performs the payment operation with cash withdrawal at the acquiring terminal, then fiscalization of the sales receipt 
// fiscalization of the issuance receipt. If the fiscalization of the sales receipt does not pass, then an emergency cancellation
// of the last acquiring operation is performed. If the issue receipt is not fiscalized, then 
// the sale operation is canceled using the correction receipt, and then the emergency cancellation of the last acquiring operation is performed.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - Description of the procedure that will be called at the End of the operation
//                             with the following parameters:
//     * Result - See PeripheralsReceiptPrintersClient.ResultIsSaleWithCashWithdrawal
//   ClientID - ClientApplicationForm - the ID of the form.
//   CCTID - CatalogRef.Peripherals - The CCT on which the fiscal receipt
//                      containing the slip receipt will be printed.
//   IDOfItem - CatalogRef.Peripherals - Acquiring terminal for processing the transaction.
//   OperationParametersList - See ParametersSaleWithCashWithdrawal
//   AdditionalParameters - Structure - Additional parameters that can be passed in 
//                             the payment and fiscalization operations.
Procedure StartSellingWithCashWithdrawal(NotificationOnCompletion, ClientID, CCTID, 
	IDOfItem, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext                      = ContextCashOutSale();
	OperationContext.CompletionNotification = NotificationOnCompletion;
	OperationContext.ClientID = ClientID;
	OperationContext.CCTID     = CCTID;
	OperationContext.IDOfItem      = IDOfItem;
	FillPropertyValues(OperationContext, OperationParametersList);
	
	PrepareContextOfBatchOperation(OperationContext, AdditionalParameters);
	
	If OperationParametersList.ParametersOfAcquiringOperation = Undefined Then
		OperationParametersList.ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	EndIf;
	If OperationContext.FiscalizationParametersOfIssueReceipt = Undefined Then
		FillInParametersOfIssueReceipt(OperationParametersList);
		OperationContext.FiscalizationParametersOfIssueReceipt = OperationParametersList.FiscalizationParametersOfIssueReceipt;
	EndIf;
	If OperationContext.RefundReceiptFiscalizationParameters = Undefined Then
		FillInRefundReceiptParameters(OperationParametersList);
		OperationContext.RefundReceiptFiscalizationParameters = OperationParametersList.RefundReceiptFiscalizationParameters;
	EndIf;
	
	// Select ET if no specific one is specified
	NotificationOfConnectionEnd = New CallbackDescription("StartSellingWithCashWithdrawal_AcquiringOperation",
		ThisObject,
		OperationContext);
	BatchProcessing_DeviceSelection(NotificationOfConnectionEnd, OperationContext);
	
EndProcedure

#EndRegion

#EndRegion

// Returns the structure for filling in the data for opening the CCT registration configuration form
//
// Returns:
//  Structure:
//    * FiscalDevice - CatalogRef.Peripherals - Link to KKT
//    * Organization - DefinedType.CompanyCEL
//    * OperationType - Number
//    * CompletionHandler - CallbackDescription
Function ParametersFormOfCCTREGISTRATIONSETTINGS() Export
	
	Parameters = New Structure();
	Parameters.Insert("FiscalDevice");
	Parameters.Insert("Organization");
	Parameters.Insert("OperationType", 0);
	Return Parameters;
	
EndFunction

// Opens the settings form for CCT registration
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription
//  OpeningParameters - See ParametersFormOfCCTREGISTRATIONSETTINGS
Procedure OpenCCTRegistrationSettingsForm(NotificationOnCompletion, OpeningParameters) Export
	
	PeripheralsReceiptPrintersClientLocalization.OpenCCTRegistrationSettingsForm(NotificationOnCompletion, OpeningParameters);
	
EndProcedure

// Returns the planned Status of the marked product
//
// Returns:
//  Map
Function PlannedStatusesOfMarkedGoods() Export
	
	Result = New Map();
	
	
	Return Result;
	
EndFunction

// Returns the value measure of the quantity of the calculated item liter
//
// Returns:
//  EnumRef.QuantityMeasureOfCRCalculationSubject
Function MeasureOfQuantityOfObjectOfCalculationLiter() Export
	
	Return PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Liter");
	
EndFunction

// Returns the default request processing Status value
//
// Returns:
//  EnumRef
Function DefaultRequestProcessingStatus() Export
	
	
EndFunction

// Returns the Status value of the result expected
//
// Returns:
//  EnumRef
Function StatusOfResultIsExpected() Export
	
	
EndFunction

// Returns the default Status of the product
//
// Returns:
//  EnumRef
Function DefaultGoodsStatus() Export
	
	
EndFunction

// Returns the default result Status value
//
// Returns:
//  EnumRef
Function DefaultResultStatus() Export
	
	
EndFunction

// Makes a KM request without waiting for a response.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartKMRequestWithoutWaitingForResponse(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("RequestKMKMNoWait", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, True);
	ParametersCommandExecution.PrepareDataClient = True;
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

#Region OFDCodes

///////////////////////////////////////////////////////////////////////////////
// Unit codes

// Returns the code for measuring the quantity of the item being calculated by the CCT.
// 
// Parameters:
//  QuantityMeasureOfCRCalculationSubject - EnumRef.QuantityMeasureOfCRCalculationSubject - A measure of the quantity of the subject of calculation of the CCT
// 
// Returns:
//  Arbitrary, Number - The code of the measure of the quantity of the object of calculation of the KKT     
Function CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT(QuantityMeasureOfCRCalculationSubject) Export
	
	LibraryClassifiers = EquipmentManagerClient.LibraryClassifiers();
	MeasureCodes = LibraryClassifiers.CodesOfMeasureOfQuantityOfSubjectOfCalculationOfCCT;
	Return MeasureCodes.Get(QuantityMeasureOfCRCalculationSubject);
	
EndFunction

// Returns a measure of the number of items calculated by code.
// 
// Parameters:
//  CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT - EnumRef.QuantityMeasureOfCRCalculationSubject - The code of the measure of the quantity of the object of calculation of the KKT
// 
// Returns:                                                                                    
//  Arbitrary, EnumRef.QuantityMeasureOfCRCalculationSubject - A measure of the quantity of the subject of calculation of KKT by Code        
//
Function MeasureOfQuantityOfSubjectOfCalculationOfKKTByCode(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT) Export
	
	LibraryClassifiers = EquipmentManagerClient.LibraryClassifiers();
	MeasureOfQuantity = LibraryClassifiers.MeasureOfQuantityOfSubjectOfCalculationOfKKTByCode;
	Return MeasureOfQuantity.Get(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT);
	
EndFunction

// Returns a measure of the quantity of the calculation item by the unit code.
// 
// Parameters:
//  UnitCode - Number - The unit code.
// 
// Returns:
//  EnumRef.QuantityMeasureOfCRCalculationSubject, Arbitrary - A measure of the quantity of the object of calculation according to the unit code
Function MeasureOfQuantityOfSubjectOfCalculationByUnitCode(UnitCode) Export
	
	LibraryClassifiers = EquipmentManagerClient.LibraryClassifiers();
	MeasureOfQuantity = LibraryClassifiers.MeasureOfQuantityOfSubjectOfCalculationByUnitCode;
	Result = MeasureOfQuantity.Get(String(UnitCode));
	If Result = Undefined Then
		Result = MeasureOfQuantity.Get(Undefined);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the unit code for the CCT code.
// 
// Parameters:
//  CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT - Number - The code of the measure of the quantity of the object of calculation of the KKT.
// 
// Returns:
//  String
//
Function CodeOfUnitOfMeasurementAccordingToKKTCode(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT) Export
	
	LibraryClassifiers = EquipmentManagerClient.LibraryClassifiers();
	MeasureOfQuantity = LibraryClassifiers.CodesOfUnitsOfMeasurementByKKTCode;
	UnitCode = MeasureOfQuantity.Get(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT);
	Return UnitCode;
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated: you should use the Start Check.
// Performs KM request.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartKmRequest(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("RequestKM", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, False);
	ParametersCommandExecution.PrepareDataClient = True;
	ParametersCommandExecution.ProcessData__Client = True;
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

// Deprecated: you should use the Start Check.
// Start receiving KM query results.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - Device ID.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure GettingKmQueryResults(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("GetProcessingKMResult", 
		"PeripheralsReceiptPrinters", AdditionalParameters, False, True);
		
	EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
		OperationParametersList, ParametersCommandExecution);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Prepare the operation data before executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - See EquipmentManagerClientServer.ConnectionParameters()
//  Command - String - command to execute
//  OperationParametersList - Structure - 
// 
// Returns:
//  Structure - Prepare Operation Data:
//  * Cashier - DefinedType.PersonalDataSubjectCEL
//  * CashierTIN - Number
//  * DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction
//  * IDOfFiscalRecord - UUID
//  * Organization - DefinedType.CompanyCEL
//  * RetailFacility - DefinedType.RetailFacilityCEL
//  * DocumentToBeCorrected - DefinedType.BaseDocumentForFiscalPLTransaction
//  * ThereIsPersonalData - Boolean -
//  * PersonalDataSubject - DefinedType.PersonalDataSubjectCEL
//  * PersonalDataType - EnumRef.TypesOfPersonalDataOfTheCCT
//  * CalculationType - EnumRef.CashSettlementTypes
//  * DocumentType - EnumRef.TypesOfCREFiscalDocuments
//  * InterfaceRevision - Number -
//  * LineWidth_ - Number - 
//  * CRERegistrationNumber - String -
//  * ManufaturerNumberOfFiscalStorage - String - 
//  * AdditionalAttribute - String - 
//  * CREShiftNumber - Number -
//  * KKTReceiptNumber - Number -
//  * ShiftReceiptNumber - Number -
//  * ReceiptDateAndTime - Date
//  * ReceiptAmount - Number -
//  * CashAccountPayment - Number -
//  * ElectronicalyPayment - Number -
//  * PaymentPrepayment - Number -
//  * PaymentPayment - Number -
//  * PaymentConsideration - Number -
//  * FiscalFlag - String -
//  * VerificationWebsiteAddress - String -
//  * PrintError - Boolean -
//  * Electronically - Boolean -
//  * Sends1CSMS - Boolean -
//  * Sends1CEmail - Boolean -
//  * Offline - Boolean -
//  * XMLReceiptData_ - String
//  * ReceiptDataAndPersonalData - String 
//  * ResultOfXMLOperation - Boolean
//  * MessageText - String
//  * CurrentStatus - Structure -:
//    ** CREShiftNumber - Number -
//    ** KKTReceiptNumber - Number -
//    ** ShiftStatus - Number -
//    ** DateTime - Date
//    ** XMLParameters - String -
//    ** XMLResult - String -
//    ** CashRegisterShift - DocumentRef.CashRegisterShift
//    ** TestReceipts - Boolean
//    ** Result - Boolean -
//    ** ErrorText - String
//  * ReverseCorrectionCheck - Boolean
//  * ProcessCorrectionCheck - Boolean -
//  * CRENonApplication - Boolean -
//  * VersionFDFCRE11 - Boolean -
//  * Result - Boolean -
//  * OperationRecorded - Boolean -
//  * ErrorText - String
//  * ShiftStatus - Number -
//  * TestReceipts - Boolean
//  * SingleReceipt - Boolean -
//  * PaymentSystemPaymentID - UUID
//  * PaymentSystemType - EnumRef.TypesOfCashRegisterPaymentSystem  
//
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList, OperationData) Export
	
	LineWidth_ = ?(ConnectionParameters.Property("LineWidth_") And ConnectionParameters.LineWidth_ > 0, ConnectionParameters.LineWidth_, 32);
	
	If OperationData = Undefined Then
		OperationData = New Structure();
		OperationData.Insert("Result", True);
		OperationData.Insert("ErrorText");
		OperationData.Insert("TestReceipts");
		OperationData.Insert("ReceiptText");
	EndIf;
	
	// For all operations, we check the correctness of the cashier's TIN.
	If OperationParametersList <> Undefined And OperationParametersList.Property("CashierTIN") And Not IsBlankString(OperationParametersList.CashierTIN) Then
		ErrorDescription = "";
		If Not PeripheralsReceiptPrintersClientServer.TINMeetsRequirements(OperationParametersList.CashierTIN, False, ErrorDescription) Then
			ErrorText = NStr("vi = 'MST của thu ngân không chính xác (%Error%)';
							|ru = 'ИНН кассира некорректен (%Error%)';
							|en = 'Cashier TIN is incorrect (%Error%)'; fa = 'Cashier TIN is incorrect (%Error%)';
							|it = 'Codice fiscale del cassiere errato (%Error%)';
							|pl = 'NIP kasjera jest niewłaściwy (%Error%)';
							|tr = 'Kasiyere ait VKN düzeltilmedi (%Error%)'");
			ErrorDescription = StrReplace(ErrorText, "%Error%", ErrorDescription);
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
	EndIf;
	
	// For all operations, we check the correctness of the TIN of the organization.
	If  OperationParametersList <> Undefined And OperationParametersList.Property("CompanyTIN") And Not IsBlankString(OperationParametersList.CompanyTIN) Then
		If StrLen(OperationParametersList.CompanyTIN) <> 10 And StrLen(OperationParametersList.CompanyTIN) <> 12 Then
			ErrorDescription = NStr("vi = 'Sai độ dài MST của doanh nghiệp.';
									|ru = 'Неверная длина ИНН организации.';
									|en = 'Incorrect length of the company TIN.'; fa = 'Incorrect length of the company TIN.';
									|it = 'Lunghezza codice fiscale azienda non valida';
									|pl = 'Nieprawidłowa długość NIP firmy.';
									|tr = 'İş yeri VKN yanlış uzunlukta.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
	EndIf;
	
	// For all operations, we check the correctness of the length of the Cashier field (FFD 1021) (max 64)
	If  OperationParametersList <> Undefined And OperationParametersList.Property("Cashier") And Not IsBlankString(OperationParametersList.Cashier) Then
		If StrLen(OperationParametersList.Cashier) > 64 Then
			OperationParametersList.Cashier = Left(TrimAll(OperationParametersList.Cashier),64);
		EndIf;
	EndIf;
	
	If Command = "PrintText" Then
		
		OperationData.TestReceipts = GetXMLPackageForText(OperationParametersList.LinesOfText, ConnectionParameters.InterfaceRevision); 
		OperationData.ReceiptText = OperationParametersList.LinesOfText; 
		Return OperationData;
		
	ElsIf Command = "PrintQRCode" Then
		
		ReceiptText = Chars.LF;
		TestReceipt = New Array();
		If Not IsBlankString(OperationParametersList.QRCode.CodeValue) Then
			
			ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters();
			TestReceipt.Add(ReceiptRow);
			
			ReceiptRow = PeripheralsReceiptPrintersClientServer.ParametersBarcodeInReceiptLine("QR", OperationParametersList.QRCode.CodeValue);
			TestReceipt.Add(ReceiptRow);
			
			ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters();
			TestReceipt.Add(ReceiptRow);
				
			ReceiptText = ReceiptText + Chars.LF + "|Barcode|QR|" + OperationParametersList.QRCode.CodeValue + Chars.LF; 
			ReceiptText = ReceiptText + Chars.NBSp + Chars.LF; 
			
			If Not IsBlankString(OperationParametersList.PaymentSystemType) Then
				ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters(OperationParametersList.PaymentSystemType);
				ReceiptRow.Align = "Center";
				TestReceipt.Add(ReceiptRow);
				ReceiptText = ReceiptText + PeripheralsReceiptPrintersClientServer.Align_Field(OperationParametersList.PaymentSystemType, ConnectionParameters.LineWidth_, "Center") + Chars.LF; 
			EndIf;
			
			ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters(OperationParametersList.QRCode.UserText);
			ReceiptRow.Align = "Center";
			TestReceipt.Add(ReceiptRow);
			
			If ValueIsFilled(OperationParametersList.TransactionAmount) Then
				NumberFormat_ = "NDS=.;ND=12;NFD=2;NZ=0.00;NG=0";
				TextTransactionAmount = StrTemplate(NStr("vi = 'Số tiền giao dịch: %1';
														|ru = 'Сумма операции: %1';
														|en = 'Transaction amount: %1'; fa = 'Transaction amount: %1';
														|it = 'Importo operazione: %1';
														|pl = 'Kwota operacji: %1';
														|tr = 'İşlem tutarı: %1'"), Format(OperationParametersList.TransactionAmount, NumberFormat_));
				ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters(TextTransactionAmount);
				ReceiptRow.Align = "Center";
				TestReceipt.Add(ReceiptRow);
				ReceiptText = ReceiptText + PeripheralsReceiptPrintersClientServer.Align_Field(TextTransactionAmount, ConnectionParameters.LineWidth_, "Center") + Chars.LF; 
				ReceiptText = ReceiptText + Chars.NBSp + Chars.LF; 
			EndIf;
			
			ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters();
			TestReceipt.Add(ReceiptRow);
		EndIf;
		
		NonFiscalDocuments = New Array();
		NonFiscalDocuments.Add(TestReceipt);
		
		TestReceipts =  New Array();
		FillInXMLPackagesForTextDocument(
			TestReceipts, NonFiscalDocuments, 
			ConnectionParameters, 
			ConnectionParameters.LineWidth_);
		OperationData.Insert("TestReceipts", TestReceipts);
		OperationData.ReceiptText = ReceiptText; 
		
		Return OperationData;
		
	ElsIf Command = "OpenShift"  Then
		
		
	ElsIf Command = "CloseShift" Then
		
		
	ElsIf Command = "ReportCurrentStatusOfSettlements" Or Command = "GetCurrentStatus"  Then
		
		If OperationParametersList = Undefined Then
			OperationParametersList = New Structure();
		EndIf;
		
		OperationData = ParametersOfFiscalOperation();
		OperationData.XMLParameters = GetXMLPacketForOperation(OperationParametersList, ConnectionParameters.InterfaceRevision);  
		
		Return OperationData;                                                                                                 
		
	ElsIf Command = "PrintXReport"  Then
		
		If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter 
				And OperationParametersList.Property("AutonomousCCT") And Not OperationParametersList.AutonomousCCT Then
			ErrorDescription = NStr("vi = 'Đã cấm tài chính hóa trên máy in phiếu tính tiền.';
									|ru = 'Фискализация на принтерах чеков запрещена.';
									|en = 'Fiscalization on receipt printers is not allowed.'; fa = 'Fiscalization on receipt printers is not allowed.';
									|it = 'Фискализация на принтерах чеков запрещена.';
									|pl = 'Fiscalization on receipt printers is not allowed.';
									|tr = 'Fiş yazıcılarında malileştirme yasaktır.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		If OperationParametersList = Undefined Then
			OperationParametersList = New Structure();
		EndIf;
		
		OperationData = ParametersOfFiscalOperation();
		OperationData.XMLParameters = GetXMLPacketForOperation(OperationParametersList, ConnectionParameters.InterfaceRevision);
		
		Return OperationData;
		
	ElsIf Command = "Encash" Then           
		
	ElsIf Command = "PiotStatus" Then  
		
		LastShiftStatus = GetLastShiftStatus(ConnectionParameters.DeviceID);
		If Not LastShiftStatus.Active = True Then
			ErrorDescription = NStr("vi = 'Phiên thu ngân chưa mở hoặc đã hết hạn.';
									|ru = 'Кассовая смена не открыта или истекла.';
									|en = 'POS shift is not opened or expired.'; fa = 'POS shift is not opened or expired.';
									|it = 'Il cambio di cassa non è aperto o è scaduto.';
									|pl = 'Zmiana kasowa nie jest otwarta lub wygasła.';
									|tr = 'Kasa vardiyası açık değil veya süresi dolmuş.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
		EndIf;    
		
		Return OperationData;
		
	ElsIf Command = "OperationFN" Then
		
	ElsIf Command = "RequestKM" Or Command = "RequestKMKMNoWait" Then
		
		OperationData = PeripheralsReceiptPrintersClientServer.KmRequestParameters();
		
		LastShiftStatus = GetLastShiftStatus(ConnectionParameters.DeviceID);
		If Not LastShiftStatus.Active = True Then
			ErrorDescription = NStr("vi = 'Phiên thu ngân chưa mở hoặc đã hết hạn.';
									|ru = 'Кассовая смена не открыта или истекла.';
									|en = 'POS shift is not opened or expired.'; fa = 'POS shift is not opened or expired.';
									|it = 'Il cambio di cassa non è aperto o è scaduto.';
									|pl = 'Zmiana kasowa nie jest otwarta lub wygasła.';
									|tr = 'Kasa vardiyası açık değil veya süresi dolmuş.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		
	ElsIf Command = "CheckKM" Then
		
		OperationData = CommonCELClient.CopyRecursive(OperationParametersList);
		OperationData.Insert("Result", True);
		OperationData.Insert("ErrorText", "");
		Return OperationData;       
		
	ElsIf Command = "CheckFiscalizationPacket" Then
		
	EndIf
	
EndFunction

// Process the operation data after executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - See EquipmentManagerClientServer.ConnectionParameters()
//  Command - String - command to execute
//  ExecutionResult - Structure - 
//  OperationData - Structure - 
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
	InterfaceRevision = ConnectionParameters.InterfaceRevision;
	
	If Command = "CheckFiscalization" Or Command = "CheckFiscalizationPacket" Then
		
	ElsIf Command = "PrintReceiptCorrection" Then
		
	ElsIf Command = "CloseShift" Then
		
		If CommonCELClient.CashShiftIsUsed() 
			And ExecutionResult.Property("LastShiftStatus") Then
			CashShiftModuleClient = CommonCELClient.CommonModule("RegisterShiftsClient");
			CashShiftModuleClient.SetStatusOfLastShift(
				ConnectionParameters.DeviceID, 
				ExecutionResult.LastShiftStatus);
		EndIf;
	
	ElsIf Command = "OpenShift" Then
		
		If CommonCELClient.CashShiftIsUsed() 
			And ExecutionResult.Property("LastShiftStatus") Then
			CashShiftModuleClient = CommonCELClient.CommonModule("RegisterShiftsClient");
			CashShiftModuleClient.SetStatusOfLastShift(
				ConnectionParameters.DeviceID, 
				ExecutionResult.LastShiftStatus);
		EndIf;
		
	ElsIf Command = "Encash" Then
		
		
	ElsIf Command = "GetDataKKT" Then
		
	ElsIf Command = "GetCurrentStatus" Then
		
		If InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
			FiscalDataStructure = GetShiftParametersFromXMLPackage(OperationData.XMLResult, InterfaceRevision);
			CREShiftNumber  = FiscalDataStructure.CREShiftNumber;
			KKTReceiptNumber   = FiscalDataStructure.KKTReceiptNumber;
			ShiftStatus = FiscalDataStructure.ShiftStatus;     
		Else
			FiscalDataStructure = GetStateParametersFromXMLPackage(OperationData.XMLResult);
			CREShiftNumber  = OperationData.CREShiftNumber;
			KKTReceiptNumber   = OperationData.KKTReceiptNumber;
			ShiftStatus = OperationData.ShiftStatus;
		EndIf;
		ExecutionResult.Insert("CREShiftNumber" , CREShiftNumber);
		ExecutionResult.Insert("KKTReceiptNumber"  , KKTReceiptNumber);
		ExecutionResult.Insert("ShiftStatus", ShiftStatus);
		ExecutionResult.Insert("FiscalData", FiscalDataStructure);
		
	ElsIf Command = "RequestKM" Then
		
		
	ElsIf Command = "PiotStart" Or Command = "PiotCheckKM" Or Command = "PiotStatus"  Then  
		
		
	ElsIf Command = "ServiceInformation"  Then  

	
	ElsIf Command = "GetProcessingKMResult"  Or Command = "RequestKMKMNoWait"  Then
		
	ElsIf Command = "CheckKM" Then
		
	ElsIf Command = "OperationFN" Then
		
	EndIf;
	
EndProcedure

#Region GeneratingCCTData

// Get the xmlpackage for the operation.
// 
// Parameters:
//  CommonParameters - Structure, Boolean - General settings
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  String - Get the Xmlpackage for the operation
Function GetXMLPacketForOperation(CommonParameters, InterfaceRevision = 0) Export
	
#If WebClient Then
	Return EquipmentReceiptPrintersServerCall.
		GetXMLPacketForOperation(CommonParameters, InterfaceRevision);
#Else
	Return PeripheralsReceiptPrintersClientServer.
		GetXMLPacketForOperation(CommonParameters, InterfaceRevision);
#EndIf

EndFunction        

// Get an xmlpackage for text.
// 
// Parameters:
//  TextString - String, Structure - Line of text
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  Array of XMLWriter - Get an xmlpackage for text.
Function GetXMLPackageForText(TextString, InterfaceRevision = 0) Export
	
#If WebClient Then
	Return EquipmentReceiptPrintersServerCall.
		GetXMLPackageForText(TextString, InterfaceRevision);
#Else
	Return PeripheralsReceiptPrintersClientServer.
		GetXMLPackageForText(TextString, InterfaceRevision);
#EndIf

EndFunction  

Procedure FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_ = 32) Export
	
#If WebClient Then
	EquipmentReceiptPrintersServerCall.
		FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_);
#Else
	PeripheralsReceiptPrintersClientServer.
		FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_);
#EndIf

EndProcedure

Function GetStateParametersFromXMLPackage(Data, ShiftNumber = Undefined) Export
	
#If WebClient Then
	Return EquipmentReceiptPrintersServerCall.GetStateParametersFromXMLPackage(Data, ShiftNumber);
#Else
	Return PeripheralsReceiptPrintersClientServer.GetStateParametersFromXMLPackage(Data, ShiftNumber);
#EndIf

EndFunction


Function GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision = 0, CREShiftNumber = 0, KKTReceiptNumber = 0) Export
	
#If WebClient Then
	Return EquipmentReceiptPrintersServerCall.
		GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision, CREShiftNumber, KKTReceiptNumber);
#Else
	Return PeripheralsReceiptPrintersClientServer.
		GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision, CREShiftNumber, KKTReceiptNumber);
#EndIf

EndFunction

#EndRegion

#Region BatchProcessing

// Processes the result of selecting an acquiring terminal
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure BatchProcessing_DeviceSelectionCompletion(ExecutionResult, OperationContext) Export
	
	Result = ExecutionResult.Result;
	
	If Not Result Then
		// Acquiring terminal is not selected, complete the package of operations
		CompletePackageOfOperations(False, ExecutionResult.ErrorDescription, OperationContext);
		Return;
	EndIf;
	
	IDOfItem                  = ExecutionResult.DeviceID;
	ClientID             = OperationContext.ClientID;
	OperationContext.IDOfItem = IDOfItem;
	
	// Connect ET, if it is not connected (required to check the possibility of printing short slip checks)
	Notification = New CallbackDescription("BatchProcessing_DeviceConnectionEnd",
		ThisObject,
		OperationContext);
	ConnectedDevice = EquipmentManagerClient.GetConnectedDevice(IDOfItem);
	If ConnectedDevice = Undefined Then
		TypesOfEquipment = New Array();
		TypesOfEquipment.Add("POSTerminal");
		EquipmentManagerClient.StartConnectingEquipment(Notification,
			ClientID,
			TypesOfEquipment,
			IDOfItem);
	Else
		ExecutionResult.ConnectedDevice = ConnectedDevice;
		RunCallback(Notification, ExecutionResult);
	EndIf;

EndProcedure

// Processes the result of connecting the acquiring terminal
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure BatchProcessing_DeviceConnectionEnd(ExecutionResult, OperationContext) Export

	Result              = ExecutionResult.Result;
	ErrorDescription         = ExecutionResult.ErrorDescription;
	ConnectedDevice = ExecutionResult.ConnectedDevice;
	Notification             = OperationContext.NotificationOfConnectionEnd;
	
	If Not Result Then
		// The acquiring terminal could not be connected
		CompletePackageOfOperations(False, ErrorDescription, OperationContext);
		Return;
	EndIf;
	OperationContext.ConnectedET = ConnectedDevice;
	
	DeterminePossibilityOfPrintingSlipCheckInBodyOfFiscal(OperationContext);
	
	// Connect ET, if it is not connected (required to check the possibility of printing short slip checks)
	RunCallback(Notification, ExecutionResult);

EndProcedure

// Processes the result of printing a slip receipt as a text document
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure BatchProcessing_TextPrintingEnd(ExecutionResult, OperationContext) Export
	
	Result      = OperationContext.Result;
	ErrorDescription = OperationContext.ErrorDescription;
	
	CompletePackageOfOperations(Result, ErrorDescription, OperationContext);
	
EndProcedure

#Region AcquiringOperationWithFiscalization

// Returns the completed structure of the result of the batch of operations
//
// Parameters:
//   OperationResult - Boolean - The result of performing a batch of operations
//   ErrorDescription - String - Description of the operation package execution error
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
//
// Returns:
//  Structure:
//    * Result - Boolean - The result of a batch of operations.
//    * ErrorDescription - String - Description of the operation batch execution error.
//    * ResultOfAcquiringOperationExecution - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * ResultOfReceiptFiscalization - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * ResultOfEmergencyCancellationOfOperation - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * AcquiringTransactionParameters - See PeripheralsReceiptPrintersClientServer.BatchOperationParametersInReceiptQueue
Function ResultOfOperationOfAcquisitionWithFiscalization(OperationResult, ErrorDescription, OperationContext) Export
	
	Result = New Structure();
	Result.Insert("Result",                                OperationResult);
	Result.Insert("ErrorDescription",                           ErrorDescription);
	If OperationContext.OperationType = "PurchaseWithEnrollment" Then
		Result.Insert("OperationType",                              PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.PurchaseWithEnrollment"));
	ElsIf OperationContext.OperationType = "FiscalizationOfPaymentReceipt" Then
		Result.Insert("OperationType",                              PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.FiscalizeReceiptWithCardPayment"));
	Else
		Raise StrTemplate(NStr("vi = 'Kiểu giao dịch không xác định %1';
								|ru = 'Неизвестный тип операции %1';
								|en = 'Unknown transaction type: %1'; fa = 'Unknown transaction type: %1';
								|it = 'Неизвестный тип операции %1';
								|pl = 'Unknown transaction type: %1';
								|tr = '%1 işleminin türü belirsiz'"), OperationContext.OperationType);
	EndIf;
	Result.Insert("ResultOfReceiptFiscalization",                OperationContext.ResultOfReceiptFiscalization);
	Result.Insert("ResultOfEmergencyCancellationOfOperation",         OperationContext.ResultOfEmergencyCancellationOfOperation);
	Result.Insert("ResultOfAcquiringOperationExecution", OperationContext.ResultOfAcquiringOperationExecution);
	Result.Insert("AcquiringTransactionParameters",           New Structure());
	
	Return Result;
	
EndFunction

// Starts performing an operation on the acquiring terminal
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartEqualizationOperationWithFiscalization_AcquiringOperation(ExecutionResult, OperationContext) Export
	
	// Check the possibility of performing a batch of operations
	ErrorDescription = "";
	If Not EqualizationOperationWithFiscalizationIsAcceptable(OperationContext, ErrorDescription) Then
		CompletePackageOfOperations(False, ErrorDescription, OperationContext);
		Return;
	EndIf;
	
	// start performing operations
	Notification = New CallbackDescription("StartEqualizationOperationWithFiscalization_AcquiringOperationCompletion",
		ThisObject,
		OperationContext);
	ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
	ModuleEquipmentPaymentSystemsClient.StartOperationOnAcquiringTerminal(Notification, 
		OperationContext.ClientID, 
		OperationContext.IDOfItem, 
		OperationContext.ParametersOfAcquiringOperation,
		OperationContext.AdditionalParameters,
		OperationContext.CCTID);
EndProcedure

// Processes the result of the acquiring operation, if successful, inserts a slip check 
// into the body of the fiscal receipt.
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartEqualizationOperationWithFiscalization_AcquiringOperationCompletion(
	ExecutionResult, OperationContext) Export
	
	ExecutionResult.Insert("TransactionAmount", OperationContext.TransactionAmount);
	OperationContext.ResultOfAcquiringOperationExecution = ExecutionResult;
	
	If ExecutionResult.Result Then
		InsertSlipReceiptIntoBodyOfFiscalReceipt(OperationContext);
		StartEqualizingOperationWithFiscalization_Fiscalization(OperationContext);
	Else
		ToProcessNegativeResultOfAcquiringOperationWithFiscalization(OperationContext);
	EndIf;
	
EndProcedure

// Starts fiscalization of the cash receipt.
// 
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartEqualizingOperationWithFiscalization_Fiscalization(OperationContext) Export
	
	Notification = New CallbackDescription("StartEqualizingOperationWithFiscalization_FiscalizationCompletion", 
		ThisObject, 
		OperationContext);
	StartCheckFiscalizationOnFiscalDevice(Notification, 
		OperationContext.ClientID, 
		OperationContext.CCTID, 
		OperationContext.ReceiptFiscalizationParameters, 
		OperationContext.AdditionalParameters);
	
EndProcedure

// Processes the results of the receipt fiscalization, in case of a fiscalization error causes an emergency cancellation of the last operation 
// of the acquiring terminal
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartEqualizingOperationWithFiscalization_FiscalizationCompletion(ExecutionResult, OperationContext) Export
	
	OperationContext.ResultOfReceiptFiscalization = ExecutionResult;
	Result      = ExecutionResult.Result;
	ErrorDescription = ExecutionResult.ErrorDescription;
	
	If Result Then
		If OperationContext.ReceiptFiscalizationParameters.Electronically Then
			OperationContext.Result = True;
			PrintSlipReceiptAsTextDocument("Electronic", OperationContext);
		Else
			CompletePackageOfOperations(True, ErrorDescription, OperationContext);
		EndIf;
	Else
		If OperationContext.ResultOfAcquiringOperationExecution.Result Then
			ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
			ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
			Notification = New CallbackDescription("StartEqualizingOperationWithFiscalization_EmergencyCancellationEnd", 
				ThisObject, 
				OperationContext);
			ParametersForCancelingAcquiringOperation = ModuleEquipmentPaymentSystemsClientServer.ParametersOfAcquiringOperation();
			FillPropertyValues(
				ParametersForCancelingAcquiringOperation, 
				OperationContext.ParametersOfAcquiringOperation, 
				, 
				"TransactionType, QueryID");
			ModuleEquipmentPaymentSystemsClient.StartPerformingEmergencyOperationCancellation(Notification, 
				OperationContext.ClientID, 
				OperationContext.IDOfItem, 
				ParametersForCancelingAcquiringOperation,
				OperationContext.AdditionalParameters);
		Else
			OperationContext.Result      = False;
			OperationContext.ErrorDescription = ErrorDescription;
			PrintSlipReceiptAsTextDocument("Cancel", OperationContext);
		EndIf;
	EndIf;
	
EndProcedure

// Processes the results of the emergency cancellation of the last operation of the acquiring terminal
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartEqualizingOperationWithFiscalization_EmergencyCancellationEnd(ExecutionResult, OperationContext) Export
	
	OperationContext.ResultOfEmergencyCancellationOfOperation = ExecutionResult;
	OperationContext.Result                        = False;
	If ExecutionResult.Result Then
		OperationContext.ErrorDescription = OperationContext.ResultOfReceiptFiscalization.ErrorDescription;
	Else
		OperationContext.ErrorDescription = OperationContext.ResultOfEmergencyCancellationOfOperation.ErrorDescription;
	EndIf;
	PrintSlipReceiptAsTextDocument("Cancel", OperationContext);
	
EndProcedure

#EndRegion

#Region SaleWithCashIssue

// Begins execution of the acquiring operation "Payment with cash withdrawal"
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextCashOutSale
Procedure StartSellingWithCashWithdrawal_AcquiringOperation(ExecutionResult, OperationContext) Export
	
	// Check the possibility of performing a batch of operations
	ErrorDescription = "";
	If Not CashSaleIsAcceptable(OperationContext, ErrorDescription) Then
		CompletePackageOfOperations(False, ErrorDescription, OperationContext);
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"StartSellingWithCashWithdrawal_AcquiringOperationCompletion",
		ThisObject,
		OperationContext);
	ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
	ModuleEquipmentPaymentSystemsClient.StartOperationOnAcquiringTerminal(
		Notification, 
		OperationContext.ClientID, 
		OperationContext.IDOfItem, 
		OperationContext.ParametersOfAcquiringOperation,
		OperationContext.AdditionalParameters,
		OperationContext.CCTID);
		
EndProcedure

// Begins execution of sale fiscalization
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure StartSellingWithCashWithdrawal_AcquiringOperationCompletion(ExecutionResult, OperationContext) Export
	
	ExecutionResult.Insert("TransactionAmount", OperationContext.TransactionAmount);
	ExecutionResult.Insert("AmountOfCash", OperationContext.IssueAmount);
	OperationContext.ResultOfAcquiringOperationExecution = ExecutionResult;

	Result      = ExecutionResult.Result;
	ErrorDescription = ExecutionResult.ErrorDescription;

	If ExecutionResult.Result Then
		// The acquiring operation was completed successfully, it is required to fiscalize the sale
		If OperationContext.SlipReceiptInBodyOfFiscal Then
			InsertSlipReceiptIntoBodyOfFiscalReceipt(OperationContext);
		EndIf;
		
		Notification = New CallbackDescription(
			"StartSellingWithCashWithdrawal_FiscalizationOfSaleEnd",
			ThisObject,
			OperationContext);
			
		StartCheckFiscalizationOnFiscalDevice(
			Notification, 
			OperationContext.ClientID, 
			OperationContext.CCTID, 
			OperationContext.ReceiptFiscalizationParameters,
			OperationContext.AdditionalParameters);
	Else
		// The acquiring operation has not been completed, the completion of the package of operations
		If OperationContext.DisplayUserNotifications Then
			MessageText = NStr("vi = 'Không thể thanh toán bằng cách rút tiền mặt.%1%2';
								|ru = 'Оплата с выдачей наличных не удалась.%1%2';
								|en = 'Payment with cash issue failed.%1%2'; fa = 'Payment with cash issue failed.%1%2';
								|it = 'Pagamento con emissione di contanti non riuscito.%1%2';
								|pl = 'Opłata z wydaniem gotówki nie powiodła się.%1%2';
								|tr = 'Para çekimiyle ödeme başarısız oldu.%1%2'");
			MessageText = StrTemplate(MessageText, Chars.LF, ErrorDescription);
			CommonCELClient.MessageToUser(MessageText);
		EndIf;

		OperationContext.Result = False;
		OperationContext.ErrorDescription = ErrorDescription;
		PrintSlipReceiptAsTextDocument("Cancel", OperationContext);

	EndIf;
			
EndProcedure

// Processes the result of the execution of the sale fiscalization
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextCashOutSale
Procedure StartSellingWithCashWithdrawal_FiscalizationOfSaleEnd(ExecutionResult, OperationContext) Export

	OperationContext.ResultOfReceiptFiscalization = ExecutionResult;

	Result      = ExecutionResult.Result;
	ErrorDescription = ExecutionResult.ErrorDescription;
	
	If Result Then
		// Fiscalization of the sale has been completed successfully, it is required to fiscalize the issue
		
		Notification = New CallbackDescription("StartSellingWithCashDisbursement_FiscalizationOfDisbursementEnd",
			ThisObject,
			OperationContext);
		StartCheckFiscalizationOnFiscalDevice(
			Notification, 
			OperationContext.ClientID, 
			OperationContext.CCTID, 
			OperationContext.FiscalizationParametersOfIssueReceipt,
			OperationContext.AdditionalParameters);
	Else
		// sale failed, cancellation of acquiring operation
		If OperationContext.DisplayUserNotifications Then
			MessageText = NStr("vi = 'Không thể thực thi tài chính hóa đối với phiếu bán hàng.%1%2';
								|ru = 'Не удалось произвести фискализацию чека продажи.%1%2';
								|en = 'Cannot fiscalize the sales receipt.%1%2'; fa = 'Cannot fiscalize the sales receipt.%1%2';
								|it = 'Non è stato possibile eseguire la fiscalizzazione dello scontrino di vendita.%1%2';
								|pl = 'Nie udało się dokonać fiskalizacji paragonu sprzedaży.%1%2';
								|tr = 'Satış fişleri malileştirilemedi.%1%2'");
			MessageText = StrTemplate(MessageText, Chars.LF, ErrorDescription);
			CommonCELClient.MessageToUser(MessageText);
		EndIf;
		// fiscalization failed, it is required to cancel the operation on ET
		ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
		ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
		Notification = New CallbackDescription(
			"StartCashSale_EmergencyCancellationEnd", 
			ThisObject, 
			OperationContext);
		ParametersForCancelingAcquiringOperation = ModuleEquipmentPaymentSystemsClientServer.ParametersOfAcquiringOperation();
		FillPropertyValues(
			ParametersForCancelingAcquiringOperation, 
			OperationContext.ParametersOfAcquiringOperation, 
			, 
			"TransactionType, QueryID");
		ModuleEquipmentPaymentSystemsClient.StartPerformingEmergencyOperationCancellation(
			Notification, 
			OperationContext.ClientID, 
			OperationContext.IDOfItem, 
			ParametersForCancelingAcquiringOperation,
			OperationContext.AdditionalParameters);
	EndIf;
	
EndProcedure

// Processes the result of the fiscalization of the issue, in case of bad luck, performs fiscalization of the refund receipt 
// and emergency cancellation of the last acquiring operation. If the operation is successful, then the operation is terminated.
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextCashOutSale
Procedure StartSellingWithCashDisbursement_FiscalizationOfDisbursementEnd(ExecutionResult, OperationContext) Export

	OperationContext.ResultOfFiscalizationOfIssueReceipt = ExecutionResult;
	Result = ExecutionResult.Result;
	
	If Result Then
		If OperationContext.FiscalizationParametersOfIssueReceipt.Electronically Then
			OperationContext.Result = True;
			PrintSlipReceiptAsTextDocument("Electronic", OperationContext);
		Else
			CompletePackageOfOperations(True, "", OperationContext);
		EndIf;
	Else
		// Fiscalization failed, it is required to cancel the fiscalization of the sale and cancel the operation on ET
		Notification = New CallbackDescription(
			"StartSellingWithCashWithdrawal_FiscalizationOfReturnOfSaleEnd", 
			ThisObject, 
			OperationContext);
		
		StartCheckFiscalizationOnFiscalDevice(
			Notification, 
			OperationContext.ClientID, 
			OperationContext.CCTID, 
			OperationContext.RefundReceiptFiscalizationParameters,
			OperationContext.AdditionalParameters);
	EndIf;
	
EndProcedure

// Processes the result of the fiscalization of the return of the sale, and performs an emergency cancellation of the last 
// acquiring operation. 
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See PeripheralsReceiptPrintersClient.ContextCashOutSale
Procedure StartSellingWithCashWithdrawal_FiscalizationOfReturnOfSaleEnd(ExecutionResult, OperationContext) Export

	OperationContext.ResultOfFiscalizationOfRefundReceipt = ExecutionResult;
	Result = ExecutionResult.Result;
	
	// Regardless of the result, perform an emergency cancellation of the acquiring operation
	ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
	Notification = New CallbackDescription(
		"StartCashSale_EmergencyCancellationEnd", 
		ThisObject, 
		OperationContext);
	ModuleEquipmentPaymentSystemsClient.StartPerformingEmergencyOperationCancellation(
		Notification, 
		OperationContext.ClientID, 
		OperationContext.IDOfItem, 
		OperationContext.ParametersOfAcquiringOperation,
		OperationContext.AdditionalParameters);
		
EndProcedure

// Processes the result of the emergency cancellation of the last acquiring operation
// 
// Parameters:
//   ExecutionResult - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   OperationContext - See ContextCashOutSale
Procedure StartCashSale_EmergencyCancellationEnd(ExecutionResult, OperationContext) Export

	OperationContext.ResultOfEmergencyCancellationOfOperation = ExecutionResult;
	
	If ExecutionResult.Result Then
		// emergency cancellation completed successfully
		If ValueIsFilled(OperationContext.ResultOfFiscalizationOfIssueReceipt) Then
			// cancellation at the time of fiscalization of the receipt issue
			ErrorDescription = OperationContext.ResultOfFiscalizationOfIssueReceipt.ErrorDescription;
			MessageText = NStr("vi = 'Không thể thực thi tài chính hóa đối với phiếu phát hành.%1%2';
								|ru = 'Фискализация чека выдачи не выполнена.%1%2';
								|en = 'Issue receipt is not fiscalized.%1%2'; fa = 'Issue receipt is not fiscalized.%1%2';
								|it = 'Fiscalizzazione dello scontrino di emissione non eseguita. %1%2';
								|pl = 'Nie wykonano fiskalizacji paragonu wydania.%1%2';
								|tr = 'Fiş çıkarmanın malileştirilmesi gerçekleşmedi.%1%2'");
			MessageText = StrTemplate(MessageText, Chars.LF, ErrorDescription);
			If Not OperationContext.ResultOfFiscalizationOfRefundReceipt.Result Then
				// refund receipt failed
				ErrorDescription = OperationContext.ResultOfFiscalizationOfRefundReceipt.ErrorDescription;
				TextOfCorrectionMessage = NStr("vi = '%1%2Chưa thực thi tài chính hóa đối với phiếu trả lại.%2%3';
												|ru = '%1%2Фискализация чека возврата не выполнена.%2%3';
												|en = '%1%2Refund receipt is not fiscalized.%2%3'; fa = '%1%2Refund receipt is not fiscalized.%2%3';
												|it = '%1%2Fiscalizzazione dello scontrino di reso non eseguita.%2%3';
												|pl = '%1%2Nie wykonano fiskalizacji paragonu zwrotu.%2%3';
												|tr = '%1%2İade fişinin malileştirilmesi gerçekleştirilmedi.%2%3'");
				TextOfCorrectionMessage = StrTemplate(TextOfCorrectionMessage, MessageText, Chars.LF, ErrorDescription);
			EndIf;
		Else 
			// cancellation at the time of fiscalization of the sales receipt
			ErrorDescription = OperationContext.ResultOfReceiptFiscalization.ErrorDescription;
			MessageText = NStr("vi = 'Chưa thực thi tài chính hoá đối với phiếu bán hàng.%1%2';
								|ru = 'Фискализация чека продажи не выполнена.%1%2';
								|en = 'Sales receipt is not fiscalized.%1%2'; fa = 'Sales receipt is not fiscalized.%1%2';
								|it = 'Fiscalizzazione dello scontrino di vendita non eseguita.%1%2';
								|pl = 'Nie wykonano fiskalizacji paragonu sprzedaży.%1%2';
								|tr = 'Satış fişinin malileştirilmesi gerçekleştirilmedi.%1%2'");
			MessageText = StrTemplate(MessageText, Chars.LF, ErrorDescription);
		EndIf;
	Else
		// emergency cancellation of payment with cash withdrawal failed
		ErrorDescription = OperationContext.ResultOfEmergencyCancellationOfOperation.ErrorDescription;
		MessageText = NStr("vi = 'Chưa thực hiện hủy khẩn cấp khoản thanh toán có rút tiền mặt.%1%2';
							|ru = 'Аварийная отмена оплаты с выдачей наличных не выполнена.%1%2';
							|en = 'Abnormal cancellation of payment with cash issue is not completed.%1%2'; fa = 'Abnormal cancellation of payment with cash issue is not completed.%1%2';
							|it = 'Annullamento per errore del pagamento con emissione di contanti non eseguito. %1%2';
							|pl = 'Nie wykonano awaryjnego anulowania opłaty z wydaniem gotówki.%1%2';
							|tr = 'Ödemenin nakit çekimli acil iptali gerçekleştirilmedi. %1%2'");
		MessageText = StrTemplate(MessageText, Chars.LF, ErrorDescription);
	EndIf;
	If OperationContext.DisplayUserNotifications Then
		CommonCELClient.MessageToUser(MessageText);
	EndIf;

	OperationContext.Result = False;
	OperationContext.ErrorDescription = ErrorDescription;
	PrintSlipReceiptAsTextDocument("Cancel", OperationContext);
	
EndProcedure

// Returns the completed structure of the result of the batch of operations
//
// Parameters:
//   OperationResult - Boolean - The result of performing a batch of operations
//   ErrorDescription - String - Description of the operation package execution error
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
//
// Returns:
//  Structure:
//    * Result - Boolean - The result of a batch of operations.
//    * ErrorDescription - ErrorInfo - Description of the operation batch execution error.
//    * ResultOfAcquiringOperationExecution - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * ResultOfReceiptFiscalization - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * ResultOfFiscalizationOfIssueReceipt - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * ResultOfFiscalizationOfRefundReceipt - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * ResultOfEmergencyCancellationOfOperation - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//    * AcquiringTransactionParameters - See PeripheralsReceiptPrintersClientServer.BatchOperationParametersInReceiptQueue
//    * ParametersSaleWithCashWithdrawal - See PeripheralsReceiptPrintersClientServer.BatchOperationParametersInReceiptQueue
Function ResultIsSaleWithCashWithdrawal(OperationResult, ErrorDescription, OperationContext) Export
	
	Result = New Structure();
	Result.Insert("Result",                                OperationResult);
	Result.Insert("ErrorDescription",                           ErrorDescription);
	Result.Insert("OperationType",                              PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.SaleWithCashIssue"));
	Result.Insert("ResultOfReceiptFiscalization",                OperationContext.ResultOfReceiptFiscalization);
	Result.Insert("ResultOfFiscalizationOfIssueReceipt",          OperationContext.ResultOfFiscalizationOfIssueReceipt);
	Result.Insert("ResultOfFiscalizationOfRefundReceipt",        OperationContext.ResultOfFiscalizationOfRefundReceipt);
	Result.Insert("ResultOfEmergencyCancellationOfOperation",         OperationContext.ResultOfEmergencyCancellationOfOperation);
	Result.Insert("ResultOfAcquiringOperationExecution", OperationContext.ResultOfAcquiringOperationExecution);
	Result.Insert("AcquiringTransactionParameters",           New Structure());
	Result.Insert("ParametersSaleWithCashWithdrawal",         New Structure());
	Return Result;
	
EndFunction

// Returns the structure of the execution context of a batch of operations
//
// Returns:
//  Structure:
//   * OperationType - String - type of operation 
//   * Result - Boolean - The result of performing a batch of operations
//   * ErrorDescription - String - Description of the operation package error
//   * CompletionNotification - CallbackDescription - An alert that is called when the package is completed
//   * ClientID - ClientApplicationForm - the ID of the form.
//   * CCTID - CatalogRef.Peripherals - The CCT on which the fiscal receipt
//                        containing the slip receipt will be printed
//   * IDOfItem - CatalogRef.Peripherals - Acquiring terminal for transaction processing
//   * ConnectedET - Structure - parameters of the connected terminal
//   * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   * FiscalizationParametersOfIssueReceipt -See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   * RefundReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//   * ResultOfAcquiringOperationExecution - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * ResultOfReceiptFiscalization - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * ResultOfFiscalizationOfIssueReceipt - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * ResultOfFiscalizationOfRefundReceipt - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * ResultOfEmergencyCancellationOfOperation - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * DisplayUserNotifications - Boolean - if True is set (by default), then if an operation
//                                       in the package fails, a message will be displayed to the user.
//   * LeaveConnected - Boolean - Leave the equipment connected after executing the package
//   * AdditionalParameters - Structure - Additional parameters that can be passed in 
//                               the payment and fiscal operations
//   * QrCardAttributes - String
//
Function ContextCashOutSale() Export
	
	Result = New Structure();
	Result.Insert("OperationType",                              "SaleWithCashIssue");
	Result.Insert("Result",                                False);
	Result.Insert("ErrorDescription",                           "");
	Result.Insert("CompletionNotification",                     Undefined);
	Result.Insert("ClientID",                     Undefined);
	Result.Insert("CCTID",                         Undefined);
	Result.Insert("IDOfItem",                          Undefined);
	Result.Insert("ConnectedET",                           Undefined);
	Result.Insert("ReceiptFiscalizationParameters",                Undefined);
	Result.Insert("RefundReceiptFiscalizationParameters",        Undefined);
	Result.Insert("FiscalizationParametersOfIssueReceipt",          Undefined);
	Result.Insert("ParametersOfAcquiringOperation", Undefined);
	Result.Insert("ResultOfAcquiringOperationExecution", Undefined);
	Result.Insert("ResultOfReceiptFiscalization",                Undefined);
	Result.Insert("ResultOfFiscalizationOfRefundReceipt",        Undefined);
	Result.Insert("ResultOfFiscalizationOfIssueReceipt",          Undefined);
	Result.Insert("ResultOfEmergencyCancellationOfOperation",         Undefined);
	Result.Insert("SlipReceiptInBodyOfFiscal",                  Undefined);
	Result.Insert("DisplayUserNotifications",          Undefined);
	Result.Insert("LeaveConnected",                     False);
	Result.Insert("AdditionalParameters",                  New Structure());
	Result.Insert("AgentAttribute",                            Undefined);
	Result.Insert("AgentData",                             Undefined);
	Result.Insert("VendorData",                         Undefined);
	Result.Insert("IssueAmount",                              0);
	Result.Insert("TransactionAmount",                            0);
	Result.Insert("QrCardAttributes",                         "");
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Private

Function GetLastShiftStatus(DeviceID) 
	
	If CommonCELClient.CashShiftIsUsed() Then
		CashShiftModuleClient = CommonCELClient.CommonModule("RegisterShiftsClient");
		Return CashShiftModuleClient.LastShiftStatus(DeviceID);
	Else
		OperationResult = New Structure();
		OperationResult.Insert("Active", True);
		OperationResult.Insert("IsOpen", True);
		OperationResult.Insert("CurReceiptNumber", 1); 
		OperationResult.Insert("CashRegisterShift", Undefined);
		Return OperationResult; 
	EndIf;
	
EndFunction

// Parameters of the fiscal operation.
// 
// Returns:
//   See PeripheralsReceiptPrintersClientServer.ParametersOfFiscalOperation.
Function ParametersOfFiscalOperation() Export
	
	Return PeripheralsReceiptPrintersClientServer.ParametersOfFiscalOperation();
	
EndFunction

Procedure SelectFiscalDevice(OperationContext)
	
	If OperationContext.DeviceID = Undefined Or IsBlankString(OperationContext.DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.ReceiptPrinter = True;
		SupportedTypes.CREWithDataTransfer = True;
		
		Notification = New CallbackDescription("PerformOperationOnFiscalDevice", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn máy ghi nhận tiền mặt';
				|ru = 'Выберите фискальное устройство';
				|en = 'Select a fiscal device'; fa = 'Select a fiscal device';
				|it = 'Scegliete un dispositivo fiscale';
				|pl = 'Wybierz urządzenie fiskalne';
				|tr = 'Mali cihaz seçiniz'"), 
			NStr("vi = 'Chưa kết nối máy ghi nhận tiền mặt.';
				|ru = 'Фискальное устройство не подключено.';
				|en = 'Fiscal device is not connected.'; fa = 'Fiscal device is not connected.';
				|it = 'Dispositivo fiscale non collegato.';
				|pl = 'Urządzenie fiskalne nie jest podłączone.';
				|tr = 'Mali cihaz bağlı değil.'"), 
			NStr("vi = 'Chưa chọn máy ghi nhận tiền mặt.';
				|ru = 'Фискальное устройство не выбрано.';
				|en = 'Fiscal device is not selected.'; fa = 'Fiscal device is not selected.';
				|it = 'Dispositivo fiscale non selezionato.';
				|pl = 'Nie wybrano urządzenia fiskalnego.';
				|tr = 'Mali cihaz seçili değil.'"));
			
	Else
		PerformOperationOnFiscalDevice(OperationContext, OperationContext);
	EndIf
	
EndProcedure

Procedure PerformOperationOnFiscalDevice(SelectionResult, OperationContext) Export
	
	If SelectionResult.Result Then 
		ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution(OperationContext.Command, 
			"PeripheralsReceiptPrinters", OperationContext.AdditionalParameters, 
			OperationContext.PrepareData, OperationContext.ProcessData__);
			
		If OperationContext.Property("PrepareDataClient") Then
			ParametersCommandExecution.PrepareDataClient = OperationContext.PrepareDataClient;
		EndIf;
			
		EquipmentManagerClient.StartCommandExecution(OperationContext.NotificationOnCompletion, OperationContext.ClientID, 
			SelectionResult.DeviceID, OperationContext.OperationParametersList, ParametersCommandExecution);
	Else
		RunCallback(OperationContext.NotificationOnCompletion, SelectionResult);
	EndIf;
	
EndProcedure

Procedure ShowWarningDriverRemovedFromSupport(Result)    
	
	If Result.Property("DriverNoLongerSupported") And Result.DriverNoLongerSupported       
		 And Result.Property("MessageWhenUsing") And Result.MessageWhenUsing Then      
		TextTitle_ = NStr("vi = 'Driver đang sử dụng đã cũ hoặc đã bỏ hỗ trợ.';
							|ru = 'Используемый драйвер устарел и снят с поддержки.';
							|en = 'The driver is outdated and is no longer supported.'; fa = 'The driver is outdated and is no longer supported.';
							|it = 'Используемый драйвер устарел и снят с поддержки.';
							|pl = 'The driver is outdated and is no longer supported.';
							|tr = 'Kullandığınız sürücü eski ve desteklenmiyor.'");
		WarningText =        
			String(Result.DeviceID) + Chars.LF +
			NStr("vi = 'Khi sử dụng driver này có thể dẫn đến tạo sai dữ liệu tài chính trên MTT.';
				|ru = 'Использование данного драйвера может приводить к некорректному формированию фискальных данных на ККТ.';
				|en = 'This driver may lead to incorrect generation of fiscal data on the cash register.'; fa = 'This driver may lead to incorrect generation of fiscal data on the cash register.';
				|it = 'Использование данного драйвера может приводить к некорректному формированию фискальных данных на ККТ.';
				|pl = 'This driver may lead to incorrect generation of fiscal data on the cash register.';
				|tr = 'Bu sürücünün kullanılması YKE''de mali verilerin yanlış oluşturulmasına neden olabilir.'") + Chars.LF +
			NStr("vi = 'Cần sử dụng phiên bản cập nhật của driver MTT đối với nhà sản xuất này.';
				|ru = 'Необходимо использовать актуальную версию драйвера ККТ для данного производителя.';
				|en = 'Use the current version of the cash register driver for this manufacturer.'; fa = 'Use the current version of the cash register driver for this manufacturer.';
				|it = 'Необходимо использовать актуальную версию драйвера ККТ для данного производителя.';
				|pl = 'Use the current version of the cash register driver for this manufacturer.';
				|tr = 'Bu üretici için YKE sürücüsünün en son sürümünü kullanmak gerekmektedir.'") + Chars.LF +
			NStr("vi = 'Hãy tùy chỉnh lại thiết bị trong phần: ""Hỗ trợ thiết bị - Thiết bị kết nối""';
				|ru = 'Перенастройте оборудование в разделе: «Поддержка оборудования – Подключаемое оборудование»';
				|en = 'Reconfigure the peripherals in Peripherals support – Peripherals'; fa = 'Reconfigure the peripherals in Peripherals support – Peripherals';
				|it = 'Перенастройте оборудование в разделе: «Поддержка оборудования – Подключаемое оборудование»';
				|pl = 'Reconfigure the peripherals in Peripherals support – Peripherals';
				|tr = '""Ekipman Desteği - Bağlanabilir Donanım"" altında donanımı tekrar konfigüre edin'");
		ShowMessageBox(Undefined, WarningText, 0, TextTitle_);
	EndIf;

EndProcedure

#Region BatchProcessing

// Launch the acquiring terminal selection
// 
// Parameters:
//   NotificationOfConnectionEnd - CallbackDescription 
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure BatchProcessing_DeviceSelection(NotificationOfConnectionEnd, OperationContext)
	
	IDOfItem = OperationContext.IDOfItem;
	OperationContext.Insert("NotificationOfConnectionEnd", NotificationOfConnectionEnd);
	// Select ET if no specific one is specified
	Notification = New CallbackDescription("BatchProcessing_DeviceSelectionCompletion",
		ThisObject,
		OperationContext);
	If IDOfItem = Undefined Or  IsBlankString(IDOfItem) Then
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.POSTerminal = True;
		EquipmentManagerClient.SelectDevice(Notification,
			SupportedTypes,
			NStr("vi = 'Hãy chọn thiết bị thanh toán thẻ';
				|ru = 'Выберите эквайринговый терминал';
				|en = 'Select a POS terminal'; fa = 'Select a POS terminal';
				|it = 'Scegliere il terminale di acquisizione';
				|pl = 'Wybierz terminal acquiringowy';
				|tr = 'PoS terminali seçin'"), 
			NStr("vi = 'Chưa kết nối thiết bị thanh toán thẻ.';
				|ru = 'Эквайринговый терминал не подключен.';
				|en = 'POS terminal is not connected.'; fa = 'POS terminal is not connected.';
				|it = 'Il terminale di acquisizione non è collegato.';
				|pl = 'Terminal płatniczy nie jest podłączony.';
				|tr = 'PoS terminali bağlı değil.'"),
			NStr("vi = 'Chưa chọn thiết bị thanh toán thẻ.';
				|ru = 'Эквайринговый терминал не выбран.';
				|en = 'POS terminal is not selected.'; fa = 'POS terminal is not selected.';
				|it = 'Il terminale di acquisizione non è scelto.';
				|pl = 'Terminal płatniczy nie jest wybrany.';
				|tr = 'PoS terminali seçili değil.'"));
	Else
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		ExecutionResult.Result               = True;
		ExecutionResult.DeviceID = IDOfItem;
		RunCallback(Notification, ExecutionResult);
	EndIf;

EndProcedure

#Region AcquiringOperationWithFiscalization

// Returns the structure for filling of operations with the acquiring terminal and fiscalization data
//
// Returns:
//   Structure:
//     * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//     * NotificationOfQuestionToUser - CallbackDescription - Description of the user notification, for self-issuance 
//                            of a message, this notification will be triggered in case of a negative response from the acquiring 
//                            terminal upon payment, the result of the package of operations will be transferred to the procedure, 
//                            as well as the structure containing the package context, if you want to continue the package execution,
//                            then you will need to call the "Start" procedure 
//                            in the hardware module._Continue execution" or
//                            "Start fiscalizationcheck with a payment card_Repeat the payment."
//                            by passing this context there.
//                            The notification procedure contains the following parameters:
//         The result is A Structure:
//           * OperationResult - See the resultfiscalizationcasoplatoycard
//           * OperationContext - Structure - the context of the operation package to be passed to the procedure
//                            "Hardware Printing Device Client.Start the fiscalization of the payment card_Continue Execution"
//                            to continue executing the package
//         Additional parameters - Any - value passed when creating an alert
//     * SlipReceiptInBodyOfFiscal - Boolean, Undefined - Output a slip check in the fiscal body, a true slip check will be output
//                            in the fiscal body, a false short slip check will not be output, An indefinite short slip check 
//                            will be output if the hardware driver supports it.
//
// Example:
//   Defining the user notification procedure
//   The procedure of the user's question Completion(Result, additional parameters)
//      of the operation result = Result.Iteration ResultsreFerences;
//      ContextoPeration = Result.ContextoPeration;
//      ...
//      continue the execution of the package of operations
//      Equipmentexprinting device Client.Start fiscalizationcheck with a payment card_Continue execution (Truth, ContextoPeration);
//   End of the procedure
// 
Function ParametersAcquisitionOfOperationWithFiscalization()
	
	If CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
		ParametersOfAcquiringOperation = ModuleEquipmentPaymentSystemsClientServer.ParametersOfAcquiringOperation();
	EndIf;
	ParametersOfReceiptFiscalizationOperation = PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation();
	
	Result = New Structure();
	Result.Insert("ReceiptFiscalizationParameters",                ParametersOfReceiptFiscalizationOperation);
	Result.Insert("ParametersOfAcquiringOperation", Undefined);
	Result.Insert("NotificationOfQuestionToUser",             Undefined);
	Result.Insert("SlipReceiptInBodyOfFiscal",                  Undefined);
	Result.Insert("QrCardAttributes",                         "");
	Return Result;
	
EndFunction

// Returns the structure and context of the execution of a batch of operations
//
// Returns:
//  Structure:
//   * OperationType - String - type of operation 
//   * Result - Boolean - The result of performing a batch of operations
//   * ErrorDescription - String - Description of the operation package error
//   * CompletionNotification - CallbackDescription - An alert that is called when the package is completed
//   * ClientID - ClientApplicationForm - the ID of the form.
//   * CCTID - CatalogRef.Peripherals - The CCT on which the fiscal receipt
//                        containing the slip receipt will be printed
//   * IDOfItem - CatalogRef.Peripherals - Acquiring terminal for transaction processing
//   * ConnectedET - Structure - parameters of the connected terminal
//   * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//   * ResultOfAcquiringOperationExecution - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * ResultOfReceiptFiscalization - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * ResultOfEmergencyCancellationOfOperation - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//   * NotificationOfQuestionToUser - CallbackDescription - Description of the user notification, for self-issuance 
//                            of a message, this notification will be triggered in case of a negative response from the acquiring 
//                            terminal during payment, the result of the package of operations, 
//                            as well as the structure containing the package context, will be transmitted to the procedure.
//   * LeaveConnected - Boolean - Leave the equipment connected after executing the package
//   * AdditionalParameters - Structure - Additional parameters that can be passed in 
//                               the payment and fiscal operations
//   * QrCardAttributes - String
Function ContextOfOperationOfAcquiringWithFiscalization() Export
	
	Result = New Structure();
	Result.Insert("OperationType",                              "");
	Result.Insert("Result",                                False);
	Result.Insert("ErrorDescription",                           "");
	Result.Insert("CompletionNotification",                     Undefined);
	Result.Insert("ClientID",                     Undefined);
	Result.Insert("CCTID",                         Undefined);
	Result.Insert("IDOfItem",                          Undefined);
	Result.Insert("ConnectedET",                           Undefined);
	Result.Insert("RecordID",                      Undefined);
	Result.Insert("ReceiptFiscalizationParameters",                Undefined);
	Result.Insert("ParametersOfAcquiringOperation", Undefined);
	Result.Insert("ResultOfAcquiringOperationExecution", Undefined);
	Result.Insert("ResultOfReceiptFiscalization",                Undefined);
	Result.Insert("ResultOfEmergencyCancellationOfOperation",         Undefined);
	Result.Insert("SlipReceiptInBodyOfFiscal",                  Undefined);
	Result.Insert("NotificationOfQuestionToUser",             Undefined);
	Result.Insert("LeaveConnected",                     False);
	Result.Insert("AdditionalParameters",                  New Structure());
	Result.Insert("TransactionAmount",                            0);
	Result.Insert("QrCardAttributes",                         "");
	Return Result;
	
EndFunction

// Asks a question to the user, or triggers an alert passed in the parameters of the operation 
// passed to the procedure "Start the fiscalization with a payment card"
//
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure ToProcessNegativeResultOfAcquiringOperationWithFiscalization(OperationContext)
	
	ExecutionResult          = OperationContext.ResultOfAcquiringOperationExecution;
	NotificationOfQuestionToUser = OperationContext.NotificationOfQuestionToUser;
	ErrorDescription               = ExecutionResult.ErrorDescription;
	
	If NotificationOfQuestionToUser <> Undefined Then
		// The user has created his own notification
		Result = New Structure("OperationResult, OperationContext");
		Result.OperationContext  = OperationContext;
		Result.OperationResult = ResultOfOperationOfAcquisitionWithFiscalization(False, ErrorDescription, OperationContext);
		RunCallback(NotificationOfQuestionToUser, Result);
	Else
		OperationContext.Result      = False;
		OperationContext.ErrorDescription = ErrorDescription;
		PrintSlipReceiptAsTextDocument("Cancel", OperationContext);
	EndIf;
	
EndProcedure

// Performs validation of the operation
//
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization.
//   ErrorDescription - String - Description of the operation parameter error
//
// Returns:
//   Boolean - Returns true if the passed operation parameters are correct
Function EqualizationOperationWithFiscalizationIsAcceptable(OperationContext, ErrorDescription)
	
	ErrorDescription = "";
	// The subsystem "Payment systems" is used
	If Not CommonCELClient.UsedPaymentSystems() Then
		ErrorText = NStr("vi = 'Chưa kết nối phân hệ ""Hệ thống thanh toán"".';
						|ru = 'Подсистема ""Платежные системы"" не подключена.';
						|en = '""Payment systems"" subsystem is not connected.'; fa = '""Payment systems"" subsystem is not connected.';
						|it = 'Подсистема ""Платежные системы"" не подключена.';
						|pl = 'Podsystem ""Systemy płatnicze nie jest podłączony.';
						|tr = '""Ödeme sistemleri"" alt sistemi bağlı değil.'");
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;
	
	ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	If ParametersOfAcquiringOperation.TransactionType <> "AuthorizeSales"
		And ParametersOfAcquiringOperation.TransactionType <> "PurchaseWithEnrollment" Then
		ErrorText = NStr("vi = 'Cơ chế này không hỗ trợ giao dịch %1.';
						|ru = 'Операция %1 не поддерживается данным режимом.';
						|en = '%1 transaction is not supported by this mode.'; fa = '%1 transaction is not supported by this mode.';
						|it = 'Операция %1 не поддерживается данным режимом.';
						|pl = 'Operacja %1 nie jest obsługiwana przez niniejszy tryb.';
						|tr = '%1 işlemi veri modunu desteklemiyor.'");
		ErrorText = StrTemplate(ErrorText, ParametersOfAcquiringOperation.TransactionType);
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;

	If ParametersOfAcquiringOperation.TransactionAmount <= 0 Then
		ErrorDescription = ErrorDescription + NStr("vi = 'Số tiền giao dịch phải lớn hơn 0.';
													|ru = 'Сумма операции должна быть больше 0.';
													|en = 'Transaction amount must be greater than 0.'; fa = 'Transaction amount must be greater than 0.';
													|it = 'Сумма операции должна быть больше 0.';
													|pl = 'Kwota operacji powinna być większa niż 0.';
													|tr = 'İşlem tutarı 0''dan fazla olmalıdır.'") + Chars.LF;
	EndIf;
	
	If IsBlankString(ErrorDescription) Then
		Return True;
	Else
		ErrorDescription = Left(ErrorDescription, StrLen(ErrorDescription) - 1);
		Return False;
	EndIf;
		
EndFunction

#EndRegion

#Region SaleWithCashIssue

// Performs verification of the correctness of filling in the bank payment agent
//
// Parameters:
//   OperationContext - See ContextCashOutSale.
//   ErrorDescription - String - Description of the operation parameter error
//
Procedure CheckCorrectnessOfBankAgent(OperationContext, ErrorDescription)
	
	IssueReceiptParameters = OperationContext.FiscalizationParametersOfIssueReceipt;
	If IssueReceiptParameters.ReceiptPositions.Count()=0 Then
		ErrorText    = NStr("vi = 'Chưa đặt dòng giao dịch chi tiền vào vị trí phiếu tính tiền.';
							|ru = 'Не задана строка операции выдачи в позиции чека.';
							|en = 'Issue transaction line is not specified in the receipt item.'; fa = 'Issue transaction line is not specified in the receipt item.';
							|it = 'Riga di operazione di emissione non indicata nella posizione dello scontrino.';
							|pl = 'Nie jest zadany wiersz operacji wydania w pozycji paragonu.';
							|tr = 'Fişin pozisyonundaki düzenleme işlem dizesi ayarlanmadı.'");
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	Else
		AgentDataPosition = IssueReceiptParameters.ReceiptPositions[0].AgentData; // See PeripheralsReceiptPrintersClientServer.ParametersAgentData
		AgentDataHeader   = IssueReceiptParameters.AgentData; // See PeripheralsReceiptPrintersClientServer.ParametersAgentData
		
		If Not ValueIsFilled(AgentDataPosition.TransferOperator.Phone)
			And Not ValueIsFilled(AgentDataHeader.TransferOperator.Phone) Then
			ErrorText    = NStr("vi = 'Chưa thiết lập số điện thoại của bên điều hành chuyển tiền thuộc đại lý thanh toán của ngân hàng (thiết bị thanh toán thẻ).';
								|ru = 'Не установлен телефон оператора перевода банковского платежного агента (эквайера).';
								|en = 'Phone number of the bank paying agent operator (acquirer) is not set.'; fa = 'Phone number of the bank paying agent operator (acquirer) is not set.';
								|it = 'Telefono dell''operatore del trasferimento dell''agente di pagamento bancario (aquirer) non impostato.';
								|pl = 'Nie ustawiono telefonu operatora przelewu bankowego agenta płatności (centrum autoryzacyjnego).';
								|tr = 'Banka ödeme temsilcisinin (alıcı banka) transfer operatörünün telefon numarası ayarlanmamıştır.'") ;
			ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
		EndIf;
		
		If Not ValueIsFilled(AgentDataPosition.TransferOperator.Description)
			And Not ValueIsFilled(AgentDataHeader.TransferOperator.Description) Then
			ErrorText    = NStr("vi = 'Chưa thiết lập tên gọi của bên điều hành chuyển tiền thuộc đại lý thanh toán của ngân hàng (thiết bị thanh toán thẻ).';
								|ru = 'Не установлено наименование оператора перевода банковского платежного агента (эквайера).';
								|en = 'Name of the bank paying agent operator (acquirer) is not set.'; fa = 'Name of the bank paying agent operator (acquirer) is not set.';
								|it = 'Non è impostato il nome dell''operatore del trasferimento dell''agente di pagamento bancario (acquirer).';
								|pl = 'Nie ustawiono nazwy operatora przelewu bankowego agenta płatności (centrum autoryzacyjnego)..';
								|tr = 'Banka ödeme temsilcisinin (alıcı banka) transfer operatörünün ismi ayarlanmamıştır.'") ;
			ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
		EndIf;
		
		If Not ValueIsFilled(AgentDataPosition.TransferOperator.Address)
			And Not ValueIsFilled(AgentDataHeader.TransferOperator.Address) Then
			ErrorText    = NStr("vi = 'Chưa thiết lập địa chỉ của bên điều hành chuyển tiền thuộc đại lý thanh toán của ngân hàng (ngân hàng thanh toán).';
								|ru = 'Не установлен адрес оператора перевода банковского платежного агента (эквайера).';
								|en = 'Address of the bank paying agent operator (acquirer) is not set.'; fa = 'Address of the bank paying agent operator (acquirer) is not set.';
								|it = 'Non è impostato l''indirizzo dell''operatore del trasferimento dell''agente di pagamento bancario (acquirer).';
								|pl = 'Nie ustawiono adresu operatora przelewu bankowego agenta płatności (centrum autoryzacyjnego)..';
								|tr = 'Banka ödeme temsilcisinin (alıcı banka) transfer operatörünün adresi ayarlanmamıştır.'") ;
			ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
		EndIf;
		
		If Not ValueIsFilled(AgentDataPosition.TransferOperator.TIN)
			And Not ValueIsFilled(AgentDataHeader.TransferOperator.TIN) Then
			ErrorText    = NStr("vi = 'Chưa thiết lập MST của bên điều hành chuyển tiền thuộc đại lý thanh toán của ngân hàng (ngân hàng thanh toán).';
								|ru = 'Не установлен ИНН оператора перевода банковского платежного агента (эквайера).';
								|en = 'TIN of the bank paying agent operator (acquirer) is not set.'; fa = 'TIN of the bank paying agent operator (acquirer) is not set.';
								|it = 'Non è impostata la codice fiscale dell''operatore del trasferimento dell''agente di pagamento bancario (acquirer).';
								|pl = 'Nie ustawiono NIPu operatora przelewu bankowego agenta płatności (centrum autoryzacyjnego).';
								|tr = 'Banka ödeme temsilcisinin (alıcı banka) transfer operatörüne ait VKN yapılandırılmadı.'") ;
			ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
		EndIf;
		
		If Not ValueIsFilled(AgentDataPosition.PayingAgent.Phone)
			And Not ValueIsFilled(AgentDataHeader.PayingAgent.Phone) Then
			ErrorText    = NStr("vi = 'Chưa thiết lập điện thoại của đại lý thanh toán thuộc ngân hàng (doanh nghiệp).';
								|ru = 'Не установлен телефон банковского платежного агента (организации).';
								|en = 'Bank paying agent (company) phone number is not set .'; fa = 'Bank paying agent (company) phone number is not set .';
								|it = 'Non è impostato il telefono dell''agente di pagamento bancario (azienda).';
								|pl = 'Nie ustawiono telefonu bankowego agenta płatności (firmy).';
								|tr = 'Banka ödeme temsilcisinin (iş yeri) telefon numarası ayarlanmamıştır.'") ;
			ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
		EndIf;
		
		If Not ValueIsFilled(AgentDataPosition.PayingAgent.Operation)
			And Not ValueIsFilled(AgentDataHeader.PayingAgent.Operation) Then
			ErrorText    = NStr("vi = 'Chưa đặt giao dịch của đại lý thanh toán ngân hàng.';
								|ru = 'Не установлена операция банковского платежного агента.';
								|en = 'Bank paying agent transaction is not set.'; fa = 'Bank paying agent transaction is not set.';
								|it = 'Non è impostata l''operazione dell''agente di pagamento bancario.';
								|pl = 'Nie ustawiono operacji bankowego agenta płatności.';
								|tr = 'Banka ödeme temsilcisinin işlemi ayarlanmamıştır.'") ;
			ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
		EndIf;
		
	EndIf;
	
EndProcedure

// Performs validation of the operation
//
// Parameters:
//   OperationContext - See ContextCashOutSale.
//   ErrorDescription - String - Description of the operation parameter error
//
// Returns:
//   Boolean - Returns true if the passed operation parameters are correct
Function CashSaleIsAcceptable(OperationContext, ErrorDescription)
	
	MultiplicityOfCashWithdrawalAmount    = 100;
	
	ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	FiscalizationParametersOfIssueReceipt          = OperationContext.FiscalizationParametersOfIssueReceipt;
	TransactionType                            = ParametersOfAcquiringOperation.TransactionType;
	TransactionAmount                            = ParametersOfAcquiringOperation.TransactionAmount;
	AmountOfCash                            = ParametersOfAcquiringOperation.AmountOfCash;
	ConnectedDevice                   = OperationContext.ConnectedET;

	Cancel = False;
	EquipmentManagerServerCallOverridable.CheckSufficiencyOfCash(
		OperationContext.CCTID, 
		AmountOfCash,
		Cancel);
	If Cancel Then
		ErrorText = NStr("vi = 'Trong MTT không đủ tiền.';
						|ru = 'В ККТ не достаточно денежных средств.';
						|en = 'There is not enough cash in the cash register.'; fa = 'There is not enough cash in the cash register.';
						|it = 'Nel registratore di cassa non vi sono fondi a sufficienza.';
						|pl = 'W kasie nie ma wystarczającej ilości środków pieniężnych.';
						|tr = 'Yazar kasada yeterli nakit yok.'");
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;
	
	// checking the multiplicity of the cash withdrawal amount
	If AmountOfCash % MultiplicityOfCashWithdrawalAmount <> 0 Then
		ErrorText = StrTemplate(NStr("vi = 'Số tiền rút tiền mặt phải là bội số %1.';
									|ru = 'Сумма выдачи наличных должна быть кратной %1.';
									|en = 'Cash issue amount must be a multiple of %1.'; fa = 'Cash issue amount must be a multiple of %1.';
									|it = 'L''importo di contanti emessi deve essere multiplo di %1.';
									|pl = 'Kwota wydania gotówki powinna być podzielna przez %1.';
									|tr = 'Nakit çekim tutarı aşağıdakilerin katları olmalıdır %1.'"), MultiplicityOfCashWithdrawalAmount);
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;
	
	If FiscalizationParametersOfIssueReceipt = Undefined Then
		ErrorText = NStr("vi = 'Chưa đặt tham số tài khóa của phiếu rút tiền mặt.';
						|ru = 'Не заданы параметры фискализации чека выдачи наличных.';
						|en = 'Cash issue receipt fiscalization parameters are not set.'; fa = 'Cash issue receipt fiscalization parameters are not set.';
						|it = 'Non sono indicati i parametri di fiscalizzazione dello scontrino di emissione di contanti.';
						|pl = 'Nie określono parametrów fiskalizacji paragonu wydania gotówki.';
						|tr = 'Nakit çekme fişini malileştiren parametreler belirlenmemiştir.'");
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;
	
	// The subsystem "Payment systems" is used
	If Not CommonCELClient.UsedPaymentSystems() Then
		ErrorText = NStr("vi = 'Chưa kết nối phân hệ ""Hệ thống thanh toán"".';
						|ru = 'Подсистема ""Платежные системы"" не подключена.';
						|en = '""Payment systems"" subsystem is not connected.'; fa = '""Payment systems"" subsystem is not connected.';
						|it = 'Sottosistema ""Sistemi di pagamento"" non connesso.';
						|pl = 'Podsystem ""Systemy płatnicze nie jest podłączony.';
						|tr = '""Ödeme sistemleri"" alt sistemi bağlı değil.'");
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;
	
	If TransactionType <> "PayByPaymentCardWithCashWithdrawal" Then
		ErrorText = NStr("vi = 'Cơ chế này không hỗ trợ giao dịch %1.';
						|ru = 'Операция %1 не поддерживается данным режимом.';
						|en = '%1 transaction is not supported by this mode.'; fa = '%1 transaction is not supported by this mode.';
						|it = 'Operazione %1 non supportata in questa modalità.';
						|pl = 'Operacja %1 nie jest obsługiwana przez niniejszy tryb.';
						|tr = '%1 işlemi veri modunu desteklemiyor.'");
		ErrorText = StrTemplate(ErrorText, TransactionType);
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;

	If TransactionAmount <= 0 Then
		ErrorText = NStr("vi = 'Số tiền giao dịch phải lớn hơn 0.';
						|ru = 'Сумма операции должна быть больше 0.';
						|en = 'Transaction amount must be greater than 0.'; fa = 'Transaction amount must be greater than 0.';
						|it = 'L''importo delle operazioni deve essere maggiore di 0.';
						|pl = 'Kwota operacji powinna być większa niż 0.';
						|tr = 'İşlem tutarı 0''dan fazla olmalıdır.'");
		ErrorDescription = ErrorDescription + ErrorText + Chars.LF;
	EndIf;
	
	CheckCorrectnessOfBankAgent(OperationContext, ErrorDescription);
	
	If IsBlankString(ErrorDescription) Then
		Return True;
	Else
		ErrorDescription = Left(ErrorDescription, StrLen(ErrorDescription) - 1);
		Return False;
	EndIf;
	
EndFunction

#EndRegion

// Fills in the parameters of the acquiring operation based on the parameters of the fiscal operation
//
// Parameters:
//   OperationContext - See ContextCashOutSale
Procedure PrepareParametersOfAcquiringOperation(OperationContext)
	
	ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	ReceiptFiscalizationParameters                = OperationContext.ReceiptFiscalizationParameters;
	
	If ParametersOfAcquiringOperation = Undefined Then
		
		If CommonCELClient.UsedPaymentSystems() Then
			ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
			ParametersOfAcquiringOperation = ModuleEquipmentPaymentSystemsClientServer.ParametersOfAcquiringOperation();
		EndIf;
		OperationContext.ParametersOfAcquiringOperation = ParametersOfAcquiringOperation;
		
		TransactionAmount = 0;
		TableOfPayment  = ReceiptFiscalizationParameters.TableOfPayment;
		For Each PaymentLine_ In TableOfPayment Do
			If PaymentLine_.TypeOfPayment = PredefinedValue("Enum.CREPaymentTypes.Electronically") Then
				TransactionAmount = TransactionAmount + PaymentLine_.Sum;
			EndIf;
		EndDo;
		
		If OperationContext.OperationType = "SaleWithCashIssue" Then
			IssueAmount = OperationContext.IssueAmount;
			ParametersOfAcquiringOperation.AmountOfCash = IssueAmount;
			ParametersOfAcquiringOperation.TransactionAmount = TransactionAmount;
		ElsIf OperationContext.OperationType = "PurchaseWithEnrollment" Then
			ParametersOfAcquiringOperation.TransactionAmount = TransactionAmount;
		ElsIf OperationContext.OperationType = "FiscalizationOfPaymentReceipt" Then
			ParametersOfAcquiringOperation.TransactionAmount = TransactionAmount;
		Else
			Raise StrTemplate(NStr("vi = 'Kiểu giao dịch không xác định %1';
									|ru = 'Неизвестный тип операции %1';
									|en = 'Unknown transaction type: %1'; fa = 'Unknown transaction type: %1';
									|it = 'Неизвестный тип операции %1';
									|pl = 'Unknown transaction type: %1';
									|tr = '%1 işleminin türü belirsiz'"), OperationContext.OperationType);
		EndIf;
		
		ParametersOfAcquiringOperation.DocumentBasis = ReceiptFiscalizationParameters.DocumentBasis;
		ParametersOfAcquiringOperation.QrCardAttributes  = OperationContext.QrCardAttributes;
		ParametersOfAcquiringOperation.QueryID = New UUID();
		
	EndIf;
	
	If OperationContext.OperationType = "SaleWithCashIssue" Then
		ParametersOfAcquiringOperation.TransactionType = "PayByPaymentCardWithCashWithdrawal";
	ElsIf OperationContext.OperationType = "PurchaseWithEnrollment" Then
		ParametersOfAcquiringOperation.TransactionType = "PurchaseWithEnrollment";
	ElsIf OperationContext.OperationType = "FiscalizationOfPaymentReceipt" Then
		ParametersOfAcquiringOperation.TransactionType = "AuthorizeSales";
	Else
		Raise StrTemplate(NStr("vi = 'Kiểu giao dịch không xác định %1';
								|ru = 'Неизвестный тип операции %1';
								|en = 'Unknown transaction type: %1'; fa = 'Unknown transaction type: %1';
								|it = 'Неизвестный тип операции %1';
								|pl = 'Unknown transaction type: %1';
								|tr = '%1 işleminin türü belirsiz'"), OperationContext.OperationType);
	EndIf;
	
	
EndProcedure

// Prepares the batch operation context for execution
// 
// Parameters:
//   OperationContext - See ContextCashOutSale
//   AdditionalParameters - Structure - additional parameters passed when starting the package
Procedure PrepareContextOfBatchOperation(OperationContext, AdditionalParameters)
	
	If Not ValueIsFilled(AdditionalParameters) Then
		AdditionalParameters = New Structure();
	EndIf;
	OperationContext.AdditionalParameters = AdditionalParameters;
	
	// remember the leave connected status passed by the user
	If AdditionalParameters.Property("LeaveConnected") Then
		OperationContext.LeaveConnected = AdditionalParameters.LeaveConnected;
	EndIf;
	
	PrepareParametersOfAcquiringOperation(OperationContext);
	
	ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	OperationContext.TransactionAmount           = ParametersOfAcquiringOperation.TransactionAmount;
	
	// leave the equipment connected, for the entire duration of the package execution
	AdditionalParameters.Insert("LeaveConnected", True);
EndProcedure

// Determines whether it is possible to print a short slip check in the body of the fiscal
// 
// Parameters:
//   OperationContext - See ContextCashOutSale
Procedure DeterminePossibilityOfPrintingSlipCheckInBodyOfFiscal(OperationContext)
	
	ConnectedDevice = OperationContext.ConnectedET;
	
	// if it is not set in the parameters forced printing of the slip receipt
	If OperationContext.SlipReceiptInBodyOfFiscal = Undefined Then
		// then print a slip check depending on the device
		If ConnectedDevice.ShortSlipChecks And Not ConnectedDevice.PrintSlipOnTerminal Then
			OperationContext.SlipReceiptInBodyOfFiscal = True;
		Else
			OperationContext.SlipReceiptInBodyOfFiscal = False;
		EndIf;
	EndIf;
	
	If OperationContext.SlipReceiptInBodyOfFiscal Then
		OperationContext.AdditionalParameters.Insert("UsePrintingDevice", False);
	EndIf;
	
EndProcedure

// Disables the equipment used in the package (CCT and ET)
//
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure DisablePackageHardware(OperationContext)
	
	// return the original value to remain connected
	AdditionalParameters = OperationContext.AdditionalParameters;
	If AdditionalParameters.Property("LeaveConnected") Then
		AdditionalParameters.LeaveConnected = OperationContext.LeaveConnected;
	EndIf;
	TurnOffEquipment = Not OperationContext.LeaveConnected;

	// It is required to disconnect the equipment, because during the operation, the equipment shutdown was canceled
	ConnectedKKTDevice =  EquipmentManagerClient.GetConnectedDevice(OperationContext.CCTID);
	If ConnectedKKTDevice <> Undefined Then
		If TurnOffEquipment Or ConnectedKKTDevice.NetworkEquipment Then
			EquipmentManagerClient.Start_DisablingEquipmentById(
				Undefined, 
				OperationContext.ClientID, 
				OperationContext.CCTID);
		EndIf;
	EndIf;

	ConnectedDeviceET =  EquipmentManagerClient.GetConnectedDevice(OperationContext.IDOfItem);
	If ConnectedDeviceET <> Undefined Then
		If TurnOffEquipment Or ConnectedDeviceET.NetworkEquipment Then
			EquipmentManagerClient.Start_DisablingEquipmentById(
				Undefined, 
				OperationContext.ClientID, 
				OperationContext.IDOfItem);
		EndIf;
	EndIf;
	
EndProcedure

// Generates the result of a batch of operations and triggers a notification to the user upon completion if it has been set.
//
// Parameters:
//   Result - Boolean - flag that the batch of operations completed successfully
//   ErrorDescription - String - Description of the error that will be transmitted in the notification
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure CompletePackageOfOperations(Result, ErrorDescription, OperationContext)

	OperationType          = OperationContext.OperationType;
	CompletionNotification = OperationContext.CompletionNotification;
	
	If OperationContext.ResultOfReceiptFiscalization <> Undefined 
		And OperationContext.ResultOfReceiptFiscalization.Result Then
		QueryID          = OperationContext.ParametersOfAcquiringOperation.QueryID;
		IDOfFiscalRecord = OperationContext.ReceiptFiscalizationParameters.IDOfFiscalRecord;
		LoggingOfCELOperationsInternalServerCall.SetIdOfFiscalRecord(QueryID, IDOfFiscalRecord);
	EndIf;
	
	DisablePackageHardware(OperationContext);
	If CompletionNotification <> Undefined Then
		If OperationType = "FiscalizationOfPaymentReceipt" Then
			OperationResult = ResultOfOperationOfAcquisitionWithFiscalization(Result, ErrorDescription, OperationContext);
		ElsIf OperationType = "PurchaseWithEnrollment" Then
			OperationResult = ResultOfOperationOfAcquisitionWithFiscalization(Result, ErrorDescription, OperationContext);
		ElsIf OperationType = "SaleWithCashIssue" Then
			OperationResult = ResultIsSaleWithCashWithdrawal(Result, ErrorDescription, OperationContext);
		Else
			Raise NStr("vi = 'Kiểu giao dịch không xác định.';
						|ru = 'Неизвестный тип операции.';
						|en = 'Unknown transaction type.'; fa = 'Unknown transaction type.';
						|it = 'Tipo di operazione sconosciuto.';
						|pl = 'Nieznany typ operacji.';
						|tr = 'İşlem türü belirsiz.'");
		EndIf;
		RunCallback(CompletionNotification, OperationResult);
	EndIf;
EndProcedure

#Region FormationOfSlipReceiptInBodyOfFiscal

// Returns the structure for forming the slip receipt template
//
// Returns:
//   Structure:
//     * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//     * ResultOfAcquiringOperationExecution - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//     * ResultOfEmergencyCancellationOfOperation - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//     * AdditionalParameters - Structure - Additional parameters passed earlier to the procedure 
//                                 "Start fiscalization with a payment card"
Function ParametersForCreatingSlipReceiptTemplate()
	
	Result = New Structure();
	Result.Insert("ReceiptFiscalizationParameters",                Undefined);
	Result.Insert("ParametersOfAcquiringOperation", Undefined);
	Result.Insert("ResultOfAcquiringOperationExecution", Undefined);
	Result.Insert("ResultOfReceiptFiscalization",                Undefined);
	Result.Insert("ResultOfEmergencyCancellationOfOperation",         Undefined);
	Result.Insert("AdditionalParameters",                  Undefined);
	Return Result;
	
EndFunction

// Generates a slip receipt template and prints it as a text document on the CCT
//
// Parameters:
//   Type - String - Type of slip check
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure PrintSlipReceiptAsTextDocument(Type, OperationContext)
	
	Notification = New CallbackDescription("BatchProcessing_TextPrintingEnd", 
		ThisObject, 
		OperationContext);
	If Not OperationContext.SlipReceiptInBodyOfFiscal Then
		RunCallback(Notification, Undefined);
		Return;
	EndIf;

	SlipReceiptParameters = OperationContext.ResultOfAcquiringOperationExecution;
	If OperationContext.OperationType = "FiscalizationOfPaymentReceipt" Then
		ReceiptFiscalizationParameters = OperationContext.ReceiptFiscalizationParameters;
		ResultOfReceiptFiscalization = OperationContext.ResultOfReceiptFiscalization;
	ElsIf OperationContext.OperationType = "SaleWithCashIssue" Then
		ReceiptFiscalizationParameters = OperationContext.FiscalizationParametersOfIssueReceipt;
		ResultOfReceiptFiscalization = OperationContext.ResultOfFiscalizationOfIssueReceipt;
	Else
		Raise NStr("vi = 'Kiểu giao dịch không xác định.';
					|ru = 'Неизвестный тип операции.';
					|en = 'Unknown transaction type.'; fa = 'Unknown transaction type.';
					|it = 'Tipo di operazione sconosciuto.';
					|pl = 'Nieznany typ operacji.';
					|tr = 'İşlem türü belirsiz.'");
	EndIf;

	// enable the user to change the text of the slip receipt
	StandardProcessing = True;
	DataForTemplate     = ParametersForCreatingSlipReceiptTemplate();
	DataForTemplate.ReceiptFiscalizationParameters                = ReceiptFiscalizationParameters;
	DataForTemplate.ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	DataForTemplate.ResultOfAcquiringOperationExecution = OperationContext.ResultOfAcquiringOperationExecution;
	DataForTemplate.ResultOfReceiptFiscalization                = ResultOfReceiptFiscalization;
	DataForTemplate.ResultOfEmergencyCancellationOfOperation         = OperationContext.ResultOfEmergencyCancellationOfOperation;
	DataForTemplate.AdditionalParameters                  = OperationContext.AdditionalParameters;
	
	If CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
		Text = ModuleEquipmentPaymentSystemsClientServer.TextOfSlipReceiptByDefault(
			DataForTemplate.ResultOfAcquiringOperationExecution, False);
	Else
		Text = "";
	EndIf;
	
	EquipmentManagerClientOverridable.CreateSlipReceiptTemplate(Type, DataForTemplate, Text, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;

	// remember the text of the last slip check in the global variable
	If Not IsBlankString(Text) And CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
		ModuleEquipmentPaymentSystemsClient.SetLastSlipReceipt(Text);
	EndIf;

	OperationParametersList = PeripheralsReceiptPrintersClientServer.TextPrintingOptions(Text);
	Start_PrintingText(Notification, 
		OperationContext.ClientID,
		OperationContext.CCTID, 
		OperationParametersList,
		OperationContext.AdditionalParameters);
		
EndProcedure

// Gets the text of the slip check from a predefined procedure and inserts it into the body of the fiscal check,
// also writes the text of the last slip check to the global variable
// 
// Parameters:
//   OperationContext - See ContextOfOperationOfAcquiringWithFiscalization
Procedure InsertSlipReceiptIntoBodyOfFiscalReceipt(OperationContext)

	If Not OperationContext.SlipReceiptInBodyOfFiscal Then
		Return;
	EndIf;

	// generate a default slip check test
	Type   = "Normal";
	If OperationContext.OperationType = "FiscalizationOfPaymentReceipt" Then
		ReceiptFiscalizationParameters = OperationContext.ReceiptFiscalizationParameters;
	ElsIf OperationContext.OperationType = "PurchaseWithEnrollment" Then
		ReceiptFiscalizationParameters = OperationContext.ReceiptFiscalizationParameters;
	ElsIf OperationContext.OperationType = "SaleWithCashIssue" Then
		ReceiptFiscalizationParameters = OperationContext.ReceiptFiscalizationParameters;
	Else
		Raise NStr("vi = 'Kiểu giao dịch không xác định.';
					|ru = 'Неизвестный тип операции.';
					|en = 'Unknown transaction type.'; fa = 'Unknown transaction type.';
					|it = 'Tipo di operazione sconosciuto.';
					|pl = 'Nieznany typ operacji.';
					|tr = 'İşlem türü belirsiz.'");
	EndIf;
	
	// enable the user to change the text of the slip receipt
	StandardProcessing = True;
	DataForTemplate     = ParametersForCreatingSlipReceiptTemplate();
	DataForTemplate.ReceiptFiscalizationParameters                = ReceiptFiscalizationParameters;
	DataForTemplate.ParametersOfAcquiringOperation = OperationContext.ParametersOfAcquiringOperation;
	DataForTemplate.ResultOfAcquiringOperationExecution = OperationContext.ResultOfAcquiringOperationExecution;
	DataForTemplate.AdditionalParameters                  = OperationContext.AdditionalParameters;
	
	If CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
		Text = ModuleEquipmentPaymentSystemsClientServer.TextOfSlipReceiptByDefault(
			DataForTemplate.ResultOfAcquiringOperationExecution);
	Else
		Text = "";
	EndIf;
	
	EquipmentManagerClientOverridable.CreateSlipReceiptTemplate(Type, DataForTemplate, Text, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	// add the text of the slip receipt to the body of the fiscal receipt
	If IsBlankString(ReceiptFiscalizationParameters.TextOfShortSlipReceipt) Then
		ReceiptFiscalizationParameters.TextOfShortSlipReceipt = Text;
	EndIf;
	
	// remember the text of the last slip check in the global variable
	If Not IsBlankString(Text) And CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClient = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClient");
		ModuleEquipmentPaymentSystemsClient.SetLastSlipReceipt(Text);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion