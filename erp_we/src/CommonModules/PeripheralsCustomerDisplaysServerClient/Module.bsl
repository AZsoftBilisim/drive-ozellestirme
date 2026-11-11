
#Region Public

// Fills in the structure of additional parameters of the operation on the Equipment.
// 
// Parameters:
//  LinesOfText - String - lines of text to display.
//  QRCodeValue - String, Undefined - The value of the QR code
// 
// Returns:
//  Structure - Operation parameters buyer's display:
//    * LinesOfText - String - Text string
//    * QRCodeValue - String - QR code value
//    * PictureQRCode - String - a string with a base64 representation of the png image of the logo.
//    * Sum - Number - Transaction amount.
//    * OperationStatus - EnumRef.OperationStatusOnDisplay - Status of operation
//    * WorkplaceStatus - EnumRef.WorkplaceStatusOnDisplay  - Workplace Status
//    * SoundSignal - Boolean - Beep.
//    * HTMLText - String - a string with a base64 representation of the png image of the logo.
//    * CompanyName - String - Organization name 
//    * Operation - String - the operation being performed.
//    * PaymentSystemType - EnumRef.TypesOfCashRegisterPaymentSystem
//                          - Undefined
//    * PaymentByCash - Boolean - Cash payment.
//    * AdditionalText - String - Additional text.
//    * Change_2 - Number - Delivery of the operation. 
//    * ReadinessToWork - Boolean - The cash account is ready to work.
//    * PictureBase64 - String - a string with a base64 representation of the png image of the logo. 
//    * TabularSectionColumns - Array of Structure
//    * TabularSection - Array of Map 
//    * Return - Boolean - flag that the Operation is a return
//    * Basement - Number - The sum of the tabular part    
//    * InternalOperation - Boolean - the display on the display is performed by the BPO
//
Function OperationParametersBuyerSDisplay(LinesOfText = "", QRCodeValue = Undefined) Export
	
	Result = New Structure();
	Result.Insert("LinesOfText", LinesOfText);
	Result.Insert("QRCodeValue", QRCodeValue);
	Result.Insert("PictureQRCode");
	Result.Insert("Sum", 0);
	// Status of operation: 0-Not installed, 1-Completed successfully, 2-Operation failed
	Result.Insert("OperationStatus");
	Result.Insert("WorkplaceStatus");
	Result.Insert("SoundSignal", False);
	Result.Insert("HTMLText");
	
	Result.Insert("CompanyName");
	Result.Insert("Operation");
	Result.Insert("PaymentSystemType");
	Result.Insert("PaymentByCash", False);
	Result.Insert("AdditionalText");
	Result.Insert("Change_2", 0);
	Result.Insert("ReadinessToWork");
	Result.Insert("PictureBase64");
	
	Result.Insert("TabularSectionColumns", New Array());
	Result.Insert("TabularSection", New Array());
	Result.Insert("Basement", 0);
	Result.Insert("Return", False);
	Result.Insert("BasementDiscount", 0);
	Result.Insert("InternalOperation", False);
	
	Result.Insert("Buttons", New Array());
	
	Return Result;
	
EndFunction

Function BuyerDisplayButton(Id, Description = "") Export
	
	Result = New Structure();
	Result.Insert("Id", Id);
	Result.Insert("Description", ?(IsBlankString(Description), Id, Description));
	Return Result;
	
EndFunction

// Fills in the column parameter structure of the tabular part of the buyer's display.
// 
// Parameters:
//  Name - String
//  Title - String
//  Width - Number
//  Align - HorizontalAlign
// Returns:
//  Structure -Operation parameters buyer's display
//
Function ColumnParametersOfTabularPartOfBuyerSDisplay(Name, Title = "", Width = 0, Align = Undefined) Export
	
	Result = New Structure();     
	Result.Insert("Name", Name);  // Row,Required - Column ID
	Result.Insert("Title", Title);  // line,required - column Presentation     
	Result.Insert("Width", Width);  // Number,Required - Column width as a percentage     
	Result.Insert("Align", Align); // HorizontalAlign
	Return Result;
	
EndFunction

// The connected displays of the buyer display a QR code.
// 
// Returns:
//  Boolean
//
Function ConnectedBuyerDisplaysDisplayQRCode() Export
	
	Result = False;
	
	SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
	SupportedTypes.CustomerDisplay = True;
	ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
	If ConnectedDevices.Count() > 0 Then
		For Each Device In ConnectedDevices Do
			If Device.DisplayDisplaysQRCode Or Device.DisplayDisplaysGraphics Then
				Result = True;
				Break;
			EndIf;
		EndDo
	EndIf;
	
	Return Result;
	
EndFunction     

// connected customer displays output html.
// 
// Returns:
//  Boolean
//
Function ConnectedCustomerDisplaysOutputHtml() Export
	
	Result = False;
	
	SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
	SupportedTypes.CustomerDisplay = True;
	ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
	If ConnectedDevices.Count() > 0 Then
		For Each Device In ConnectedDevices Do
			If Device.DisplayDisplaysHTML Then
				Result = True;
				Break;
			EndIf;
		EndDo
	EndIf;
	
	Return Result;
	
EndFunction

// To begin the withdrawal of test strings to a connected customer displays.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - the device ID, if indefinite, will be output to everything.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDisplayingInformationOnBuyerSDisplay(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("DisplayText", Undefined, AdditionalParameters, False, False);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.CustomerDisplay = True;    
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do
				EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
					OperationParametersList, ParametersCommandExecution);
			EndDo
		EndIf;
		
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure        

// To begin the withdrawal of test strings to a connected customer displays.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - the device ID, if indefinite, will be output to everything.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDisplayingInformationOnCustomerDisplay(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("DisplayInfo", "PeripheralsCustomerDisplaysServer", AdditionalParameters, True, False);
	OperationParametersList.Insert("WorkplaceStatusCode", WorkplaceStatusOnDisplay(OperationParametersList.WorkplaceStatus));
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.CustomerDisplay = True;
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do
				EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
					OperationParametersList, ParametersCommandExecution);
			EndDo
		EndIf;
		
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure        

 // Start displaying the QR code on the connected displays of the buyer.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - the device ID, if indefinite, will be output to all
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDisplayingQRCodeOnBuyerSDisplay(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("DisplayQRCode", "PeripheralsCustomerDisplaysServer", AdditionalParameters, False, False);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.CustomerDisplay = True;
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do
				If Device.DisplayDisplaysHTML And OperationParametersList.InternalOperation Then
					StatusOfWorkplaceOnDisplay_WorkplaceIsWorking = 3;
					OperationParametersList.Operation = "FiscalCheck";
					OperationParametersList.Insert("WorkplaceStatusCode", StatusOfWorkplaceOnDisplay_WorkplaceIsWorking);
					ParametersCommandExecution.Command = "DisplayInfo";
					ParametersCommandExecution.PrepareData = True;
				EndIf;
				EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
					OperationParametersList, ParametersCommandExecution);
			EndDo
		EndIf;
		
	Else
		If OperationParametersList.InternalOperation Then
			Device = EquipmentManagerClient.GetConnectedDevice(DeviceID);
			If Device.DisplayDisplaysHTML  Then
				StatusOfWorkplaceOnDisplay_WorkplaceIsWorking = 3;
				OperationParametersList.Operation = "FiscalCheck";
				OperationParametersList.Insert("WorkplaceStatusCode", StatusOfWorkplaceOnDisplay_WorkplaceIsWorking);
				ParametersCommandExecution.Command = "DisplayInfo";
				ParametersCommandExecution.PrepareData = True;
			EndIf;
		EndIf;
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

// Start displaying HTML on the connected displays of the buyer.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - the device ID, if indefinite, will be output to all
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDisplayingHtmlOnCustomerDisplay(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("OutputHTML", Undefined, AdditionalParameters, False, False);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.CustomerDisplay = True;
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do     
				If Device.DisplayDisplaysHTML Then
					EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
						OperationParametersList, ParametersCommandExecution);
				EndIf;
			EndDo
		EndIf;
		
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

// To start cleaning up connected displays of the buyer.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartCleaningBuyerSDisplay_(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("ClearText", Undefined, AdditionalParameters, False, False);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();                                                                                   
		SupportedTypes.CustomerDisplay = True;
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do
				EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
					OperationParametersList, ParametersCommandExecution);
			EndDo
		EndIf;
		
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

// start displaying the Status of the transaction on the connected displays of the buyer.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - the device ID, if indefinite, will be output to all
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDisplayingStatusOfTransactionOnCustomerDisplay(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("DisplayStatus", Undefined, AdditionalParameters, False, False);
	OperationParametersList.Insert("CodeStatusOfOperation", OperationStatusOnDisplay(OperationParametersList.OperationStatus));

	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();                                                                                   
		SupportedTypes.CustomerDisplay = True;
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do
				If Device.DISPLAYShowsStatus Then
					EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
						OperationParametersList, ParametersCommandExecution);
				EndIf;
			EndDo
		EndIf;
		
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure     

// Start displaying the Status of the workplace on the connected displays of the buyer.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - the device ID, if indefinite, will be output to all
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartDisplayingStatusOfWorkplaceOnCustomerDisplay(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution("DisplayStatusRM", Undefined, AdditionalParameters, False, False);
	OperationParametersList.Insert("WorkplaceStatusCode", WorkplaceStatusOnDisplay(OperationParametersList.WorkplaceStatus));
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();                                                                                   
		SupportedTypes.CustomerDisplay = True;
		ConnectedDevices = EquipmentManagerClient.GetConnectedDevices(SupportedTypes);
		If ConnectedDevices.Count() > 0 Then
			For Each Device In ConnectedDevices Do
				If Device.DisplayShowsStatusOfRM Then
					EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, Device.Ref, 
						OperationParametersList, ParametersCommandExecution);
				EndIf;
			EndDo
		EndIf;
		
	Else
		EquipmentManagerClient.StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, 
			OperationParametersList, ParametersCommandExecution);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Workplace Status code on the display.
// 
// Parameters:    
//   WorkplaceStatus - EnumRef.WorkplaceStatusOnDisplay - Workplace status on the display
//   
// Returns:
//   Number - Status code.
//
Function WorkplaceStatusOnDisplay(WorkplaceStatus) Export
	
	If WorkplaceStatus = Undefined Then
		StatusCode_ = 0
	Else
		WorkplaceStatuses = New Map(); 
		WorkplaceStatuses.Insert(PredefinedValue("Enum.WorkplaceStatusOnDisplay.NotSet")        , 0);
		WorkplaceStatuses.Insert(PredefinedValue("Enum.WorkplaceStatusOnDisplay.ServiceMode")      , 1);
		WorkplaceStatuses.Insert(PredefinedValue("Enum.WorkplaceStatusOnDisplay.WorkplaceIsNotUsed"), 2);
		WorkplaceStatuses.Insert(PredefinedValue("Enum.WorkplaceStatusOnDisplay.WorkplaceIsUsed"), 3);
		WorkplaceStatuses.Insert(PredefinedValue("Enum.WorkplaceStatusOnDisplay.WorkplaceError"), 4);
		StatusCode_ = WorkplaceStatuses.Get(WorkplaceStatus);
	EndIf;
	
	Return StatusCode_;
	
EndFunction    

// The Status code of the operation is displayed.
// 
// Parameters:    
//   OperationStatus - EnumRef.OperationStatusOnDisplay - Status of operation on display
//   
// Returns:
//   Number - Status code.
//
Function OperationStatusOnDisplay(OperationStatus) Export
	
	If OperationStatus = Undefined Then
		StatusCode_ = 0
	Else
		StatusesOfOperation = New Map(); 
		StatusesOfOperation.Insert(PredefinedValue("Enum.OperationStatusOnDisplay.NotSet")       , 0);
		StatusesOfOperation.Insert(PredefinedValue("Enum.OperationStatusOnDisplay.ExecutedSuccessfully")   , 1);
		StatusesOfOperation.Insert(PredefinedValue("Enum.OperationStatusOnDisplay.ActionNotExecuted"), 2);
		StatusesOfOperation.Insert(PredefinedValue("Enum.OperationStatusOnDisplay.AwaitingOperation")   , 0);
		StatusesOfOperation.Insert(PredefinedValue("Enum.OperationStatusOnDisplay.Information")         , 0);
		StatusCode_ = StatusesOfOperation.Get(OperationStatus);
	EndIf;
	
	Return StatusCode_;
	
EndFunction

#EndRegion