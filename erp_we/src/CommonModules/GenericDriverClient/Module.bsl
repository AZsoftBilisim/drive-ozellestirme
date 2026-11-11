#Region Internal

// The function starts executing the command, processes and redirects the command to the driver for execution.
//
// Parameters:
//  Notification upon completion - The description of the announcement - the event of the description of the notification.
//  ConnectionParameters - Structure
//  Command - String - command to execute
//  OperationData - Structure - operation data for executing the command
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function CommandExecution(ConnectionParameters, Command, OperationData) Export
	
	DriverObject = ConnectionParameters.DriverObject;         
	OperationData.Insert("Command", Command);
	
	// PROCEDURES FOR WORKING WITH FISCAL DEVICES 
	If Command = "CheckFiscalization" Then
		ExecutionResult = Await ReceiptFiscalization(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "PrintText" Or Command = "PrintQRCode" Then
		ExecutionResult = Await PrintText(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "OpenShift" Then
		ExecutionResult = Await OpenShift(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "CloseShift" Then
		ExecutionResult = Await CloseShift(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "Encash" Then
		ExecutionResult = Await Collection_(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "OpenCashDrawer" Then
		ExecutionResult = Await OpenCashDrawer(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "PrintReceiptCorrection" Then
		ExecutionResult = Await PrintingCorrectionReceipt(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "ReportCurrentStatusOfSettlements" Then
		ExecutionResult = Await ReportCurrentStatusOfSettlements(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "PrintXReport" Then
		ExecutionResult = Await PrintReportWithoutClearance(DriverObject, ConnectionParameters, OperationData); 
	ElsIf Command = "GetLineLength" Then
		ExecutionResult = Await LineWidth_(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "AnnulCheck" Then
		ExecutionResult = Await CancellationOfReceipt(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "GetDataKKT" Then
		ExecutionResult = Await CREParameters(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "GetCurrentStatus" Then
		ExecutionResult = Await CurrentStatus(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "OperationFN" Then
		ExecutionResult = Await FiscalStorageOperation(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "PrintCheckCopy" Then
		ExecutionResult = Await PrintCheckCopy(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "OpenSessionRegistrationKM" Then
		ExecutionResult = Await OpenSessionRegistrationKM(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "CloseSessionRegistrationKM" Then
		ExecutionResult = Await CloseSessionRegistrationKM(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "RequestKM" Then
		ExecutionResult = Await RequestKM(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "RequestKMKMNoWait" Then
		ExecutionResult = Await KMRequestWithoutWaitingForResponse(ConnectionParameters.DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "GetProcessingKMResult" Then
		ExecutionResult = Await KMQueryResults(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "ConfirmKM" Then
		ExecutionResult = Await ConfirmKM(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "CheckKM" Then
		ExecutionResult = Await KMCheck(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "CheckFiscalizationPacket" Then
		ExecutionResult = Await FiscalizationOfReceiptByPackage(DriverObject, ConnectionParameters, OperationData);
		
	// ++ Non-mobile application
	// -- Non-mobile application 
	// PROCEDURES FOR WORKING WITH ACQUIRING TERMINALS
	ElsIf Command = "AuthorizeSales" Or Command = "AuthorizeRefund" Or Command = "AuthorizeVoid" 
		Or Command = "PayByPaymentCardWithCashWithdrawal" Or Command = "PurchaseWithEnrollment" Then      
		If ConnectionParameters.InterfaceRevision > 4002 Then
			ExecutionResult = Await AcquiringOperationOfXML(DriverObject, ConnectionParameters, OperationData, Command);
		Else
			ExecutionResult = Await AcquiringTransaction(DriverObject, ConnectionParameters, OperationData, Command);
		EndIf;
	ElsIf Command = "PayElectronicCertificate" Or Command = "ReturnElectronicCertificate" Then 
		If ConnectionParameters.InterfaceRevision > 4002 Then
			ExecutionResult = Await AcquiringOperationWithXMLElectronicCertificate(DriverObject, ConnectionParameters, OperationData, Command);
		Else
		ExecutionResult = Await AcquiringOperationWithElectronicCertificate(DriverObject, ConnectionParameters, OperationData, Command);
		EndIf;
	ElsIf Command = "Settlement" Then // Results reconciliation on the cards
		ExecutionResult = Await ResultsOfDayByMaps(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "EmergencyVoid" Then // Emergency payment cancellation
		ExecutionResult = Await EmergencyReversal(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "GetCardParametrs" Then // Get map parameters 
		ExecutionResult = Await MapParameters(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "GetOperationByCards" Then // Get map parameters 
		ExecutionResult = Await TransactionsByCards(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "AuthorizePreSales" Or Command = "AuthorizeCompletion" Or Command = "AuthorizeVoidPreSales" Then
		ExecutionResult = Await AcquiringOperationOfXML(DriverObject, ConnectionParameters, OperationData, Command);
		
	// PROCEDURES FOR WORKING WITH CUSTOMER DISPLAYS
	ElsIf Command = "GetOutputOptions" Then // Get output parameters.
		ExecutionResult = Await OutputParameters(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "DisplayText" Then // Displaying lines on the display.
		ExecutionResult = Await StringOutputOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "ClearText" Then // Cleaning the display.
		ExecutionResult = Await ClearCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "DisplayQRCode" Then // QR code output to the display.
		ExecutionResult = Await QRCodeOutputOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "DisplayStatus" Then // display the Status on the customer display
		ExecutionResult = Await DisplayStatusOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "DisplayStatusRM" Then // Display The Status Of The Workplace On The Customer Display
		ExecutionResult = Await DisplayStatusOfWorkplaceOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);   
	ElsIf Command = "OutputHTML" Then // Display HTML on the buyer's display.
		ExecutionResult = Await DisplayHtmlOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "DisplayInfo" Then // Display Information On The Buyer's Display
		ExecutionResult = Await DisplayInformationOnBuyerSDisplay(DriverObject, ConnectionParameters, OperationData);
		
	// PROCEDURES FOR WORKING WITH ELECTRONIC SCALES
	ElsIf Command = "GetWeight" Then // Gain weight.
		ExecutionResult = Await GetWeight(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "Calibrate" Then // Set the tare weight.
		ExecutionResult = Await Tariffing(DriverObject, ConnectionParameters, OperationData);
	
	// ++ Non-mobile application
	// PROCEDURES FOR WORKING WITH SCALES WITH LABEL PRINTING
	ElsIf Command = "UploadGoods" Then // Unloading of goods into scales with label printing.
		ExecutionResult = Await UploadGoods(DriverObject, ConnectionParameters, OperationData);    
	ElsIf Command = "UploadGoodsPacket" Then // Unloading items into scales with label printing package.
		ExecutionResult = Await UnloadItemsAsPackage(DriverObject, ConnectionParameters, OperationData);    
	ElsIf Command = "ClearBase" Then // Clear the scale base with label printing.
		ExecutionResult = Await ClearGoodsInLibra(DriverObject, ConnectionParameters, OperationData);
	// Upload images of goods to the scales by printing labels.
	ElsIf Command = "UploadProductImages" Then
		ExecutionResult = Await UploadProductImages(DriverObject, ConnectionParameters, OperationData);     
		
	// PROCEDURES FOR WORKING WITH THE RECOGNIZER
	ElsIf Command = "Recognize" Then // Recognize products.
		ExecutionResult = Await RecognizeAsync(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "ConfirmRecognize" Then // Confirm recognition.
		ExecutionResult = Await ConfirmRecognitionAsync(DriverObject, ConnectionParameters, OperationData);
		
	// PROCEDURES FOR WORKING WITH DATA COLLECTION TERMINALS
	ElsIf Command =  "UploadDirectory" Then // Uploading the table to the data collection terminal.
		ExecutionResult = Await UploadTable(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "DownloadDocument" Then // Loading the table from the data collection terminal.
		ExecutionResult = Await DownloadTable(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "ClearTable" Then // Clears the previously loaded table in the data collection terminal.
		ExecutionResult = Await ClearTable(DriverObject, ConnectionParameters, OperationData);
		
	// PROCEDURES FOR WORKING WITH LABEL PRINTERS
	ElsIf Command = "InitializePrinter" Then
		ExecutionResult = Await InitializePrinter(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "PrintLabels" Then
		ExecutionResult = Await PrintLabels(DriverObject, ConnectionParameters, OperationData);
		
	// PROCEDURES AND FUNCTIONS COMMON FOR WORKING WITH RFID
	ElsIf Command = "OpenSessionRFID" Then // Open an RFID Reader session
		ExecutionResult = Await OpenSessionRFID(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "CloseSessionRFID" Then // Open an RFID Reader session
		ExecutionResult = Await CloseSessionRFID(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "SaveDataTagRFID" Then // Write data to an RFID tag 
		ExecutionResult = Await SaveDataTagRFID(DriverObject, ConnectionParameters, OperationData);
	ElsIf Command = "ExternalEvent" Then // Generate An External Event 
		ExecutionResult = Await Generate_ExternalEvent(DriverObject, ConnectionParameters, OperationData);
		
	// -- Non-mobile application 
	Else
		ErrorDescription = NStr("vi = 'Lệnh không hợp lệ.';
								|ru = 'Недопустимая команда.';
								|en = 'Invalid command.'; fa = 'Invalid command.';
								|it = 'Comando non disponibile.';
								|pl = 'Niedopuszczalne polecenie.';
								|tr = 'Kabul edilemeyen komut.'"); 
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
	EndIf;                 
	
	Return ExecutionResult;
	
EndFunction

// The function starts executing the command of non-certified equipment, processes and redirects 
// the command to the driver for execution.
//
// Parameters:
//  Notification upon completion - The description of the announcement - the event of the description of the notification.
//  ConnectionParameters - Structure
//  Command - String - command to execute
//  OperationData - Structure - operation data for executing the command
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function ExecutionOfCommandOfNonCertifiedEquipmentAsync(ConnectionParameters, Command, OperationData) Export
	
	DriverObject = ConnectionParameters.DriverObject;
	ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
	ExecutionResult.Insert("Result", False);
	ExecutionResult.Insert("ErrorDescription", "");
	ExecutionResult.Insert("DeviceID", ConnectionParameters.DeviceID);
	
	Try
		ModuleNonCertifiedEquipmentClientOverridable = CommonCELClient.CommonModule("UncertifiedPeripheralsClientOverridable");
		Result = Await ModuleNonCertifiedEquipmentClientOverridable.ExecuteCommandAsync(
			DriverObject, ConnectionParameters, Command, OperationData, ExecutionResult);
		If Result <> Undefined Then
			ExecutionResult.Result = Result;
		EndIf;
	Except   
		Return DriverCallError(Command, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	If Not ExecutionResult.Result Then  
		ExecutionResult = Await GetDriverError(DriverObject);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// Returns the driver object
// 
// Parameters:
//  ConnectionParameters - Structure
// 
// Returns:
//  AddInObject 
//
Async Function DriverObjectAsync(ConnectionParameters) Export
	
	If ConnectionParameters.ObjectID = Undefined Then
		Return Undefined;
	EndIf;
	
	DriverObject = EquipmentManagerClient.DriverObjectFromCache(ConnectionParameters.ObjectID);
	If DriverObject <> Undefined Then 
		ConnectionParameters.DriverObject = DriverObject;
		Return DriverObject;
	EndIf;
	
	MessageText = StrTemplate(
		NStr("vi = 'Để tiếp tục làm việc, cần cài đặt cấu phần ngoài ""%1"".';
			|ru = 'Для продолжения работы требуется установка внешней компоненты ""%1"".';
			|en = 'To continue, set the ""%1"" add-in.'; fa = 'To continue, set the ""%1"" add-in.';
			|it = 'Per continuare il lavoro è richiesta l''installazione della componente esterna ""%1"".';
			|pl = 'Aby kontynuować pracę wymagana jest instalacja komponentu zewnętrznego ""%1"".';
			|tr = 'Devam etmek için ""%1"" dış bileşeninin yüklenmesi gerekiyor.'"), 
		ConnectionParameters.Description); 
	
	If ConnectionParameters.ConnectingFromTemplate Or CommonCELClientServer.IsMobileClient() Then
		
		Operation = NStr("vi = 'Kết nối từ khuôn in';
						|ru = 'Подключить из макета';
						|en = 'Attach from the template'; fa = 'Attach from the template';
						|it = 'Подключить из макета';
						|pl = 'Attach from the template';
						|tr = 'Şablondan bağlan'");
		If Not ConnectionParameters.TemplateIsAvailable Then
			
			ErrorDescription = StrTemplate(NStr("vi = 'Đối với cấu phần bên ngoài, không tìm thấy khuôn in %1.';
												|ru = 'Для внешней компоненты макет %1 не обнаружен.';
												|en = 'The template for the add-in %1 is not found'; fa = 'The template for the add-in %1 is not found';
												|it = 'Для внешней компоненты макет %1 не обнаружен.';
												|pl = 'The template for the add-in %1 is not found';
												|tr = '%1 şablonu için harici eklentiler tespit edilemedi.'"), ConnectionParameters.DriverTemplateName);
			LogError_(ConnectionParameters, Operation, ErrorDescription);
			Return Undefined;
			
		EndIf;
		
		If EquipmentManagerClient.YouCanInstallComponents(ConnectionParameters.DriverTemplateName) Then
			
			Parameters = AddInsCELClient.ConnectionParameters();  
			Parameters.ExplanationText = MessageText;      
			Parameters.Isolated = ConnectionParameters.SafeConnection; 
			Parameters.Cached   = False;
			
			DataOfLog = New Structure();
			DataOfLog.Insert("Id", ConnectionParameters.ObjectID);
			DataOfLog.Insert("FullTemplateName", ConnectionParameters.DriverTemplateName);
			DataOfLog.Insert("ConnectionParameters", Parameters);
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, Operation, DataOfLog);
			ConnectionResult = Await AddInsCELClient.AttachAddInFromTemplateAsync(ConnectionParameters.ObjectID, ConnectionParameters.DriverTemplateName, Parameters);
			CompleteRecordingOfOperationLog(EntryOfLog, ConnectionResult, "Attached, ErrorDescription");
			
		Else
			
			ConnectionResult = AddInsCELClient.ConnectionResult();
			ConnectionResult.Attached = False;
			ErrorDescription = StrTemplate(NStr("vi = 'Không cho phép kết nối cấu phần từ khuôn in %1.';
												|ru = 'Подключение внешней компоненты из макета %1 не допустимо.';
												|en = 'Connection of  add-ins from the template %1 is not allowed.'; fa = 'Connection of  add-ins from the template %1 is not allowed.';
												|it = 'Подключение внешней компоненты из макета %1 не допустимо.';
												|pl = 'Connection of  add-ins from the template %1 is not allowed.';
												|tr = '%1 şemasından harici eklentinin bağlanmasına izin verilmemektedir.'"), ConnectionParameters.DriverTemplateName);
			LogError_(ConnectionParameters, Operation, ErrorDescription);
			
		EndIf;
		
	ElsIf ConnectionParameters.ConnectingLocallyById Then
	#If WebClient Then
		ConnectionResult = AddInsCELClient.ConnectionResult();
		ConnectionResult.Attached = False;
	#Else                   
		Operation = NStr("vi = 'Kết nối từ danh sách Windows';
						|ru = 'Подключить из реестра Windows';
						|en = 'Attach from the Windows registry'; fa = 'Attach from the Windows registry';
						|it = 'Подключить из реестра Windows';
						|pl = 'Attach from the Windows registry';
						|tr = 'Windows kaydıyla bağlan'");
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, Operation, ConnectionParameters.ObjectID, "Id");
		ConnectionResult = Await AddInsCELClient.AttachAddInFromWindowsRegistryAsync(ConnectionParameters.ObjectID);
		CompleteRecordingOfOperationLog(EntryOfLog, ConnectionResult, "Attached, ErrorDescription");
	#EndIf
	Else
		Parameters = AddInsCELClient.ConnectionParameters();
		Parameters.ExplanationText = MessageText;
		Parameters.Isolated = ConnectionParameters.SafeConnection; 
		Parameters.Cached   = False;   
		Parameters.SuggestToImport  = True;
		Parameters.SuggestInstall = True;
		Parameters.AutoUpdate = False;
		
		Operation = NStr("vi = 'Kết nối cấu phần';
						|ru = 'Подключить компоненту';
						|en = 'Attach add-in'; fa = 'Attach add-in';
						|it = 'Подключить компоненту';
						|pl = 'Podłącz komponent';
						|tr = 'Eklentiyi bağla'");
		DataOfLog = New Structure();
		DataOfLog.Insert("Id", ConnectionParameters.ObjectID);
		DataOfLog.Insert("ConnectionParameters", Parameters);
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, Operation, DataOfLog);
		ConnectionResult = Await AddInsCELClient.AttachAddInSSLAsync(ConnectionParameters.ObjectID, Undefined, Parameters);
		CompleteRecordingOfOperationLog(EntryOfLog, ConnectionResult, "Attached, ErrorDescription");
	EndIf;
		
	If ConnectionResult.Attached Then 
		DriverObject = ConnectionResult.Attachable_Module; 
		ConnectionParameters.DriverObject = DriverObject;
		EquipmentManagerClient.AddDriverToCache(ConnectionParameters.ObjectID, DriverObject); 
	EndIf;
		
	Return DriverObject;
	
EndFunction

// Returns a description of the driver
// 
// Parameters:
//   ConnectionParameters - Structure
//   
// Returns:
//  See ResultOfOperationOnEquipment 
//
Async Function DriverDescriptionAsync(ConnectionParameters) Export
	
	DriverObject = Await DriverObjectAsync(ConnectionParameters);
	If DriverObject = Undefined Then
		
		ExecutionResult = DriverLoadingError(ConnectionParameters);  
		Return ExecutionResult;
		
	Else     
		
		If Not IsBlankString(ConnectionParameters.LocalizationPattern) Then   
			Try                         
				CurrentLanguage = CurrentLanguage();
				UserLanguageCode = ?(TypeOf(CurrentLanguage) = Type("String"), CurrentLanguage, CurrentLanguage.LanguageCode); 
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "SetLocalization", ToArray(UserLanguageCode, ConnectionParameters.LocalizationPattern));
				CallResult = Await DriverObject.SetLocalizationAsync(UserLanguageCode, ConnectionParameters.LocalizationPattern); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				If Not CallResult.Value Then
					CommonCELClient.MessageToUser(NStr("vi = 'Lỗi bản địa hóa thiết bị.';
														|ru = 'Ошибка локализации драйвера.';
														|en = 'Driver localization error.'; fa = 'Driver localization error.';
														|it = 'Ошибка локализации драйвера.';
														|pl = 'Driver localization error.';
														|tr = 'Sürücü yerelleştirme hatası.'"));
					GetDriverError(DriverObject, EntryOfLog);
				EndIf
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
			EndTry;   
		EndIf;
		
		DetailsReceived = True;
		DriverDescription = EquipmentManagerClientServer.DescriptionParametersDriver();
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetDescription");
			CallResult = Await DriverObject.GetDescriptionAsync(DriverDescription.DescriptionOfXMLDriver); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except                               
			InterfaceRevision = 2005;
			DetailsReceived = False;
		EndTry;
		
		If Not DetailsReceived Then
			Try
				CallResult = Await DriverObject.GetDescriptionAsync(DriverDescription.DriverName, DriverDescription.DriverDescription, DriverDescription.EquipmentType,
					InterfaceRevision, DriverDescription.IntegrationComponent, DriverDescription.MainDriverIsInstalled, DriverDescription.DriverDownloadURL); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult, 
					"Name, Description, EquipmentType, InterfaceRevision, IntegrationLibrary, MainDriverInstalled, DownloadURL");
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
				Return DriverCallError("GetDescription", DetailErrorDescription(ErrorInfo()), True);
			EndTry;   
		EndIf;
			
		If CallResult.Value <> True Then // It is the value <> that is true. The value may mistakenly return an arbitrary type from the driver.
			GetDriverError(DriverObject, EntryOfLog);
		EndIf;
			
		CallParameters = CallResult.Parameters;
		If CallParameters.Count() > 1 And Not StrStartsWith(CallParameters[0], "<?")  Then  
			// The WEB client does not throw an exception when calling a method with an incorrect number of parameters.
			DriverDescription.DriverName      = CallParameters[0]; // DriverName
			DriverDescription.DriverDescription          = CallParameters[1]; // DriverDescription
			DriverDescription.EquipmentType           = CallParameters[2]; // EquipmentType
			DriverDescription.InterfaceRevision         = CallParameters[3]; // InterfaceRevision
			DriverDescription.IntegrationComponent   = CallParameters[4]; // IntegrationComponent
			DriverDescription.MainDriverIsInstalled = CallParameters[5]; // MainDriverIsInstalled
			DriverDescription.DriverDownloadURL       = CallParameters[6]; // DriverDownloadURL
			
			Try
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetVersion");
			CallResult = Await DriverObject.GetVersionAsync(); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
			EndTry;
			DriverDescription.DriverVersion = CallResult.Value;
		Else
			DriverDescriptionParameters = EquipmentManagerClient.GetDriverDescription(CallParameters[0]); // DescriptionOfXMLDriver
			FillPropertyValues(DriverDescription, DriverDescriptionParameters); 
			
			Try
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetInterfaceRevision");
			CallResult = Await DriverObject.GetInterfaceRevisionAsync(); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
			EndTry;
			DriverDescription.InterfaceRevision = CallResult.Value;
		EndIf;
		
		ConnectionParameters.InterfaceRevision = DriverDescription.InterfaceRevision;
		If DriverDescription.InterfaceRevision >= 4000 And DriverDescription.SupportedLocalization Then   
			LocalizationPattern = "";
			Try
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetLocalizationPattern");
				CallResult = Await DriverObject.GetLocalizationPatternAsync(LocalizationPattern); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				If CallResult.Value Then      
					CallParameters = CallResult.Parameters;
					DriverDescription.LocalizationPattern = CallParameters[0];     
				EndIf
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
				ErrorDescription = DetailErrorDescription(ErrorInfo());
				CommonCELClient.MessageToUser(NStr("vi = 'Lỗi nhận khuôn in bản địa hóa thiết bị.';
													|ru = 'Ошибка получения шаблон локализации драйвера.';
													|en = 'An error occurred when getting the driver localization template.'; fa = 'An error occurred when getting the driver localization template.';
													|it = 'Ошибка получения шаблон локализации драйвера.';
													|pl = 'An error occurred when getting the driver localization template.';
													|tr = 'Sürücü yerelleştirme şablonu alınırken hata oluştu.'") + Chars.LF + ErrorDescription);
			EndTry;
			If CallResult.Value <> True Then  // It is the value <> that is true. The value may mistakenly return an arbitrary type from the driver.
				GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		EndIf;
		
		DriverDescription.InterfaceRevisionPresentation = PresentationRevisionOfInterface(DriverDescription.InterfaceRevision);     
		ConnectionParameters.InterfaceRevision = DriverDescription.InterfaceRevision;
		
		If Not DriverDescription.InterfaceRevision > 4002 Then
			// We set the type of equipment.
			Result = Await SetDriverParametersAsync(DriverObject, ConnectionParameters, True, False);
			If Not Result Then
				Return DriverCallError("SetDriverParameters");
			EndIf;
		EndIf;                     
		
		// We get the driver parameters. For 4003 and above - the type of equipment is set in the method.
		Result = Await DriverParametersAsync(DriverObject, DriverDescription, ConnectionParameters);   
		
		ExecutionResult = ResultOfOperationOnEquipment(Result);     
		ExecutionResult.Insert("DriverDescription", DriverDescription);
		Return ExecutionResult;
		
	EndIf;
	
EndFunction

// Returns driver parameters
// 
// Parameters:
//  DriverObject - AddInObject 
//  DriverDescription - Structure
//  ConnectionParameters - Structure
// 
// Returns:
//  Boolean      
//
Async Function DriverParametersAsync(DriverObject, DriverDescription, ConnectionParameters) Export
	
	DriverParameters = "";
	
	If ConnectionParameters.InterfaceRevision > 4002 Then
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "EquipmentParameters", ConnectionParameters, "EquipmentTypeName");
			CallResult = Await DriverObject.EquipmentParametersAsync(ConnectionParameters.EquipmentTypeName, DriverParameters); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			DriverDescription.DriverParameters = CallResult.Parameters[1];
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ErrorDescription = DetailErrorDescription(ErrorInfo());
			CommonCELClient.MessageToUser(NStr("vi = 'Lỗi nhận tham số driver.';
												|ru = 'Ошибка получения параметров драйвера.';
												|en = 'An error occurred when receiving the driver parameters.'; fa = 'An error occurred when receiving the driver parameters.';
												|it = 'Errore di ricezione dei parametri del driver.';
												|pl = 'Błąd pobierania parametrów sterownika.';
												|tr = 'Sürücü parametreleri alınırken hata oluştu.'") + Chars.LF + ErrorDescription);
			Return False;
		EndTry;
	Else
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetParameters");
			CallResult = Await DriverObject.GetParametersAsync(DriverParameters); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			DriverDescription.DriverParameters = CallResult.Parameters[0];
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ErrorDescription = DetailErrorDescription(ErrorInfo());
			CommonCELClient.MessageToUser(NStr("vi = 'Lỗi nhận tham số driver.';
												|ru = 'Ошибка получения параметров драйвера.';
												|en = 'An error occurred when receiving the driver parameters.'; fa = 'An error occurred when receiving the driver parameters.';
												|it = 'Errore di ricezione dei parametri del driver.';
												|pl = 'Błąd pobierania parametrów sterownika.';
												|tr = 'Sürücü parametreleri alınırken hata oluştu.'") + Chars.LF + ErrorDescription);
			Return False;
		EndTry;
	EndIf;
	
	If CallResult.Value <> True Then  // It is the value <> that is true. The value may mistakenly return an arbitrary type from the driver.
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
	EndIf;
	
	AdditionalActions = "";
	Try
		
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetAdditionalActions");
		CallResult = Await DriverObject.GetAdditionalActionsAsync(AdditionalActions); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		CommonCELClient.MessageToUser(NStr("vi = 'Lỗi nhận bản mô tả driver.';
											|ru = 'Ошибка получения описания драйвера.';
											|en = 'An error occurred when receiving the driver description.'; fa = 'An error occurred when receiving the driver description.';
											|it = 'Errore durante il recupero della descrizione del driver.';
											|pl = 'Błąd pobierania opisu sterownika.';
											|tr = 'Sürücü açıklaması alınırken hata oluştu.'"));
		Return False;
	EndTry;
	
	If CallResult.Value <> True Then // It is the value <> that is true. The value may mistakenly return an arbitrary type from the driver.
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
	EndIf;
	
	CallParameters = CallResult.Parameters;
	DriverDescription.AdditionalActions = CallParameters[0];
	DriverDescription.Is_Specified = True;
	
	If ConnectionParameters.Property("NumberOfConnectedDevices") Then
		DriverDescription.Insert("NumberOfConnectedDevices",  ConnectionParameters.NumberOfConnectedDevices);
	EndIf;
	
	Return True;

EndFunction   

// Sets driver parameters
// 
// Parameters:
//  DriverObject - AddInObject
//  ConnectionParameters - Structure
//  SetTypeOfEquipment - Boolean
//  SpecifyParameters - Boolean
//  
// Returns:
//   Boolean
//
Async Function SetDriverParametersAsync(DriverObject, ConnectionParameters, SetTypeOfEquipment = True, SpecifyParameters = True) Export
	
	If SetTypeOfEquipment And ConnectionParameters.Property("EquipmentTypeName") Then
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "SetParameter", ToArray("EquipmentType", ConnectionParameters.EquipmentTypeName));
			CallResult = Await DriverObject.SetParameterAsync("EquipmentType", ConnectionParameters.EquipmentTypeName); // EquipmentType  
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return False;
		EndTry;
		If CallResult.Value <> True Then // May be Undefined
			GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	EndIf;
	
	If SpecifyParameters And ConnectionParameters.Parameters <> Undefined Then
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "SetParameter", ConnectionParameters.Parameters);

		For Each Parameter In ConnectionParameters.Parameters Do
			If Left(Parameter.Key, 2) = "P_" Then
				ParameterValue = Parameter.Value;
				ParameterName = Mid(Parameter.Key, 3);
				Try
					CallResult = Await DriverObject.SetParameterAsync(ParameterName, ParameterValue); // Structure
				Except
					ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					EndLogRecordingWithException(EntryOfLog, ErrorText);
					Return False;
				EndTry;
				If CallResult.Value <> True Then // May be Undefined
					GetDriverError(DriverObject, EntryOfLog);
				EndIf;
			EndIf;
		EndDo; 
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
	EndIf;  
	
	Return True;
	
EndFunction

// The function starts connecting the device.
// 
// Parameters:
//  ConnectionParameters - Structure
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function ConnectDeviceAsync(ConnectionParameters) Export
	
	If ConnectionParameters.EquipmentType = PredefinedValue("Enum.PeripheralTypes.CloudCashRegister") Then
		ExecutionResult = ResultOfOperationOnEquipment(True);
		Return ExecutionResult;
	EndIf;
	
// ++ Non-mobile application
// -- Non-mobile application 
		DriverObject = Await DriverObjectAsync(ConnectionParameters);
		If DriverObject = Undefined Then
			Return DriverLoadingError(ConnectionParameters);  
		EndIf;   
// ++ Non-mobile application
// -- Non-mobile application 
	
	ConnectionParameters.DriverObject = DriverObject;
	
	InterfaceRevision = 2005;
	DetailsReceived = True;
	DriverDescription = EquipmentManagerClientServer.DescriptionParametersDriver();
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetInterfaceRevision");
		CallResult = Await DriverObject.GetInterfaceRevisionAsync(); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		InterfaceRevision = CallResult.Value;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		DetailsReceived = False;
	EndTry;
	
	If Not DetailsReceived Then
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetDescription");
			CallResult = Await DriverObject.GetDescriptionAsync(DriverDescription.DriverName, DriverDescription.DriverDescription, DriverDescription.EquipmentType,
				DriverDescription.InterfaceRevision, DriverDescription.IntegrationComponent, DriverDescription.MainDriverIsInstalled, DriverDescription.DriverDownloadURL); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			InterfaceRevision = CallResult.Parameters[3];
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("GetDescription");
		EndTry;   
	EndIf;
	ConnectionParameters.InterfaceRevision = InterfaceRevision;
	DriverDescription.InterfaceRevision = InterfaceRevision;
	
	If IsBlankString(ConnectionParameters.InterfaceRevision) Or ConnectionParameters.InterfaceRevision = 0 Then
		ErrorDescription = NStr("vi = 'Chưa xác định bản sửa đổi của giao diện driver.';
								|ru = 'Ревизия интерфейса драйвера не определена.';
								|en = 'Driver interface revision is not defined.'; fa = 'Driver interface revision is not defined.';
								|it = 'Revisione dell''interfaccia del driver non definita.';
								|pl = 'Rewizja interfejsu sterownika jest nieokreślona.';
								|tr = 'Sürücü arayüzü revizyonu tanımlanmamış.'");
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	Else
		ConnectionParameters.InterfaceRevisionPresentation = PresentationRevisionOfInterface(ConnectionParameters.InterfaceRevision);
	EndIf;
	
	If ConnectionParameters.InterfaceRevision >= 4000 Then   
		If Not IsBlankString(ConnectionParameters.LocalizationPattern) Then   
			Try                 
				CurrentLanguage = CurrentLanguage();
				LanguageCode = ?(TypeOf(CurrentLanguage) = Type("String"), CurrentLanguage, CurrentLanguage.LanguageCode); 
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "SetLocalization", ToArray(LanguageCode, ConnectionParameters.LocalizationPattern));
				CallResult = Await DriverObject.SetLocalizationAsync(LanguageCode, ConnectionParameters.LocalizationPattern); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				If Not CallResult.Value Then
					CommonCELClient.MessageToUser(NStr("vi = 'Lỗi bản địa hóa thiết bị.';
														|ru = 'Ошибка локализации драйвера.';
														|en = 'Driver localization error.'; fa = 'Driver localization error.';
														|it = 'Ошибка локализации драйвера.';
														|pl = 'Driver localization error.';
														|tr = 'Sürücü yerelleştirme hatası.'"));
					DriverCallError("SetLocalization");
				EndIf
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
			EndTry;   
		EndIf;
	EndIf;   
	
	If ConnectionParameters.InterfaceRevision > 4002 Then    
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ConnectEquipment", ConnectionParameters, ", EquipmentTypeName, XMLParameters");
			CallResult = Await DriverObject.ConnectEquipmentAsync(ConnectionParameters.DeviceID_,  
				ConnectionParameters.EquipmentTypeName, ConnectionParameters.XMLParameters); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			ConnectionParameters.DeviceID_ = CallResult.Parameters[0];
			Result = CallResult.Value;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("ConnectEquipment", DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else
		
		Result = Await SetDriverParametersAsync(DriverObject, ConnectionParameters, True, False);
		If Not Result Then
			Return DriverCallError("SetDriverParameters");
		EndIf;
	
		Result = Await SetDriverParametersAsync(DriverObject, ConnectionParameters, False);
		If Not Result Then
			Return DriverCallError("SetDriverParameters");
		EndIf;
	
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Open");
			CallResult = Await DriverObject.OpenAsync(ConnectionParameters.DeviceID_); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			ConnectionParameters.DeviceID_ = CallResult.Parameters[0];
			Result = CallResult.Value;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("Open", DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	If Result <> True Then // May be Undefined
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		Return ExecutionResult;
	Else
		
		TypesOfEquipment = ConnectionParameters.TypesOfEquipment;  
		
		If CommonCELClient.CheckPrintingDevicesAreUsed()
			And ((TypesOfEquipment.Property("CREWITHDATATRANSFER") And TypesOfEquipment.CREWithDataTransfer)
				Or (TypesOfEquipment.Property("ReceiptPrinter") And TypesOfEquipment.ReceiptPrinter)
				Or (TypesOfEquipment.Property("FiscalCashRegisters") And TypesOfEquipment.FiscalCashRegisters)
			) Then
			Result = Await LineWidth_(DriverObject, ConnectionParameters, Undefined) 
		EndIf;
		
		If CommonCELClient.UsedPaymentSystems()
			And TypesOfEquipment.Property("POSTerminal") And TypesOfEquipment.POSTerminal Then
			Result = Await TerminalParameters(DriverObject, ConnectionParameters, Undefined) 
		EndIf;
		
		If CommonCELClient.UsedBuyerSDisplays()
			And TypesOfEquipment.Property("CustomerDisplay") And TypesOfEquipment.CustomerDisplay Then
			Result = Await OutputParameters(DriverObject, ConnectionParameters, Undefined);   
			If ConnectionParameters.DisplayWorksOutClicks Then
				ConnectionParameters.EventNames.Add("Нажатие"); //@NON-NLS-1 @NON-NLS-2
				ConnectionParameters.EventNames.Add("OnClick");
			EndIf;
		EndIf;
		
		If CommonCELClient.WeightEquipmentIsUsed()
			And TypesOfEquipment.Property("DigitalRetailScales") And TypesOfEquipment.DigitalRetailScales Then  
			Result = Await ParametersOfScales(DriverObject, ConnectionParameters, Undefined); 
			If ConnectionParameters.WeightGainEvent Then
				ConnectionParameters.EventNames.Add("Взвешивание"); //@NON-NLS-1 @NON-NLS-2
				ConnectionParameters.EventNames.Add("Weighting"); 
			EndIf;
		EndIf; 
		
		If CommonCELClient.InputDevicesAreUsed() 
			And TypesOfEquipment.Property("BarcodeScanner") Then
			
			If ConnectionParameters.TypesOfEquipment.BarcodeScanner Then
				ConnectionParameters.EventNames.Add("Штрихкод");       //@NON-NLS-1 @NON-NLS-2
				ConnectionParameters.EventNames.Add("ШтрихкодBase64"); //@NON-NLS-1 @NON-NLS-2
				ConnectionParameters.EventNames.Add("Barcode"); 
				ConnectionParameters.EventNames.Add("BarcodeBase64");
			EndIf;
			
			If ConnectionParameters.TypesOfEquipment.BarcodeScanner Then
				ConnectionParameters.EventNames.Add("НажатиеКлавиши");  //@NON-NLS-1 @NON-NLS-2
				ConnectionParameters.EventNames.Add("KeyPress"); 
			EndIf;
		EndIf;
		
		// ++ Non-mobile application
		If CommonCELClient.InputDevicesAreUsed()
			And TypesOfEquipment.Property("MagneticStripeCardReaders") And TypesOfEquipment.MagneticStripeCardReaders Then
			ConnectionParameters.EventNames.Add("ДанныеКарты");       //@NON-NLS-1 @NON-NLS-2
			ConnectionParameters.EventNames.Add("ДанныеКартыBase64"); //@NON-NLS-1 @NON-NLS-2
			ConnectionParameters.EventNames.Add("TracksData"); 
			ConnectionParameters.EventNames.Add("TracksDataBase64");
		EndIf;
		
		If CommonCELClient.RFIDReaderIsUsed()
			And TypesOfEquipment.Property("RFIDReaders") And TypesOfEquipment.RFIDReaders Then
			ConnectionParameters.EventNames.Add("RFID");
		EndIf;
		// -- Non-mobile application
		
		ExecutionResult = ResultOfOperationOnEquipment(True);
		Return ExecutionResult;
	EndIf;
	    
	ExecutionResult = ResultOfOperationOnEquipment(True);
	Return ExecutionResult;
	
EndFunction

// The function starts disabling the device.
// 
// Parameters:
//  ConnectionParameters - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function DisableDeviceAsync(ConnectionParameters) Export
	
	DriverObject = ConnectionParameters.DriverObject;   
	If DriverObject = Undefined Then
		Return DriverLoadingError(ConnectionParameters);  
	EndIf;   
	
	If ConnectionParameters.InterfaceRevision > 4002 Then   
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "DisconnectEquipment");
			CallResult = Await DriverObject.DisableHardwareAsync(ConnectionParameters.DeviceID_); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			ExecutionResult = ResultOfOperationOnEquipment(CallResult.Value);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("DisableHardware", DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Close");
			CallResult = Await DriverObject.CloseAsync(ConnectionParameters.DeviceID_); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			ExecutionResult = ResultOfOperationOnEquipment(CallResult.Value);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("Close", DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	If CallResult.Value <> True Then
		GetDriverError(DriverObject, EntryOfLog);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// Performs a device test
// 
// Parameters:
//  ConnectionParameters - Structure
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function DeviceTestAsync(ConnectionParameters) Export
	
	DriverObject = Await DriverObjectAsync(ConnectionParameters);
	If DriverObject = Undefined Then
		Return DriverLoadingError(ConnectionParameters);  
	EndIf;    
	
	InterfaceRevision = Await InterfaceRevisionAsync(DriverObject, ConnectionParameters);
	
	Result = False;
	TestResult       = "";
	DemoModeActivated = ""; 
	If InterfaceRevision > 4002 Then
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "EquipmentTest", ConnectionParameters, "EquipmentTypeName, XMLParameters");
			CallResult = Await DriverObject.EquipmentTestAsync(ConnectionParameters.EquipmentTypeName, 
			ConnectionParameters.XMLParameters, TestResult, DemoModeActivated); // Structure    
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("EquipmentTest", ErrorText);
		EndTry;
			
		If TypeOf(CallResult.Value) = Type("Boolean") Then
			Result = CallResult.Value;       
			TestResult  = CallResult.Parameters[2];      
			DemoModeActivated = CallResult.Parameters[3];
			If CallResult.Value <> True Then
				GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		EndIf;
	Else
		Result = Await SetDriverParametersAsync(DriverObject, ConnectionParameters);
		If Result Then
			Try
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "DeviceTest");
				CallResult = Await DriverObject.DeviceTestAsync(TestResult, DemoModeActivated); // Structure    
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				EndLogRecordingWithException(EntryOfLog, ErrorText);
				Return DriverCallError("DeviceTest");
			EndTry;
			
			If TypeOf(CallResult.Value) = Type("Boolean") Then
				Result = CallResult.Value;       
				TestResult  = CallResult.Parameters[0];      
				DemoModeActivated = CallResult.Parameters[1];
				If CallResult.Value <> True Then
					GetDriverError(DriverObject, EntryOfLog);
				EndIf;
			EndIf;
		Else      
			Return DriverCallError("SetDriverParameters");
		EndIf;
	EndIf;
	
	ExecutionResult = ResultOfOperationOnEquipment(Result);
	ExecutionResult.Insert("ExecutionResult" , TestResult);  
	ExecutionResult.Insert("DemoModeActivated", DemoModeActivated);   
	
	Return ExecutionResult; 
	
EndFunction

// Performs auto-tuning of the device
// 
// Parameters:
//  ConnectionParameters - Structure
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function AutoTuningDeviceAsync(ConnectionParameters) Export
	
	DriverObject = Await DriverObjectAsync(ConnectionParameters);
	If DriverObject = Undefined Then
		Return DriverLoadingError(ConnectionParameters);  
	EndIf;    
	
	InterfaceRevision = Await InterfaceRevisionAsync(DriverObject, ConnectionParameters);
	
	Result = False;    
	ShowAutoTuningWindow = True;
	Timeout = 60;     
	XMLConnectionParameters = "";
	
	If InterfaceRevision > 4002 Then
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "EquipmentAutoSetup", 
				ToArray(Undefined,ConnectionParameters.XMLParameters,,ShowAutoTuningWindow,Timeout));
		CallResult = Await DriverObject.AutoHardwareConfigurationAsync(ConnectionParameters.EquipmentTypeName, 
			ConnectionParameters.XMLParameters, XMLConnectionParameters, ShowAutoTuningWindow, Timeout); // Structure    
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
		EndTry;
		
			
		If TypeOf(CallResult.Value) = Type("Boolean") Then
			Result = CallResult.Value;    
			XMLConnectionParameters = CallResult.Parameters[2]; 
			If CallResult.Value <> True Then
				GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		EndIf;
		
		ExecutionResult = ResultOfOperationOnEquipment(Result);  
		ExecutionResult.Insert("XMLConnectionParameters", XMLConnectionParameters);    
		ExecutionResult.Insert("ConnectionParameters"   , EquipmentManagerServerCall.LoadXMLParameters(XMLConnectionParameters));    
		
	Else
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Драйвер не поддерживает операцию.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'"); 
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
	EndIf;
	
	Return ExecutionResult; 
	
EndFunction

// Performs an additional action
// 
// Parameters:
//  ConnectionParameters - Structure
//  ExecutionParameters - Structure
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function DoAdditionalActionAsync(ConnectionParameters, ExecutionParameters) Export
	
	ExecutionResult = Await DriverDescriptionAsync(ConnectionParameters); 
	
	If ExecutionResult.Result Then
		
		DriverObject = ConnectionParameters.DriverObject;
		
		If ConnectionParameters.InterfaceRevision < 4003 Then 
			Result = Await SetDriverParametersAsync(DriverObject, ConnectionParameters); 
			If Not Result Then
				Return DriverCallError("SetDriverParameters");
			EndIf;
		EndIf;  
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "DoAdditionalAction", ExecutionParameters, "ActionName");
			CallResult = Await DriverObject.DoAdditionalActionAsync(ExecutionParameters.ActionName); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Result = CallResult.Value;
		Except 
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ErrorDescription = NStr("vi = 'Lỗi thực hiện thao tác bổ sung.';
									|ru = 'Ошибка выполнения дополнительного действия.';
									|en = 'An error occurred when performing an additional action.'; fa = 'An error occurred when performing an additional action.';
									|it = 'Ошибка выполнения дополнительного действия.';
									|pl = 'An error occurred when performing an additional action.';
									|tr = 'Ek eylem gerçekleştirilirken hata oluştu.'");
			ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
			Return ExecutionResult; 
		EndTry;
	
		ExecutionResult = ResultOfOperationOnEquipment(True);
		If CallResult.Value <> True Then
			ExecutionResult = GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		
	Else
		Return ExecutionResult;   
	EndIf;
	
	Return ExecutionResult;  
	
EndFunction

// Performs a device test
// 
// Parameters:
//  ConnectionParameters - Structure
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function InterfaceRevisionAsync(DriverObject, ConnectionParameters) Export
	
	Try                 
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetInterfaceRevision");
		CallResult = Await DriverObject.GetInterfaceRevisionAsync(); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		InterfaceRevision = CallResult.Value;
	Except
		// Version of requirements 2.5 and below
		InterfaceRevision = 2005;
	EndTry;  
	ConnectionParameters.InterfaceRevision = InterfaceRevision;
	
	Return InterfaceRevision;
	
EndFunction

#Region CompatibilityMode

// Starts executing the command, processes and redirects the command to the driver for execution.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  ConnectionParameters - Structure
//  Command - String - command to execute
//  OperationData - Structure - operation data for executing the command
//
Async Procedure StartCommandExecution(NotificationOnCompletion, ConnectionParameters, Command, OperationData) Export
	
	If ConnectionParameters.NonCertified Then
		If CommonCELClient.NonCertifiedEquipmentIsUsed() Then
			ExecutionResult = Await ExecutionOfCommandOfNonCertifiedEquipmentAsync(ConnectionParameters, Command, OperationData);
			RunCallback(NotificationOnCompletion, ExecutionResult);
		EndIf;
	Else
		Result = Await CommandExecution(ConnectionParameters, Command, OperationData);
		If Result.Property("TimeConsumingOperation") Then
			If Result.TimeConsumingOperation = "KMCheck" Then 
				ModuleEquipmentManagerMarkingClient = CommonCELClient.CommonModule("EquipmentManagerMarkingClient"); 
				ModuleEquipmentManagerMarkingClient.LongTermOperationCRCheck(NotificationOnCompletion, Command, ConnectionParameters, OperationData);
			EndIf;
		Else
			RunCallback(NotificationOnCompletion, Result);
		EndIf;
		
	EndIf;
	
EndProcedure

// Starts receiving the driver object
Async Procedure StartGettingDriverObject(NotificationOnCompletion, ConnectionParameters) Export
	
	Result = Await DriverObjectAsync(ConnectionParameters);
	RunCallback(NotificationOnCompletion, Result);
	
EndProcedure

// Starts receiving the driver description
Async Procedure StartGettingDescriptionOfDriver(NotificationOnCompletion, ConnectionParameters) Export
	
	Result = Await DriverDescriptionAsync(ConnectionParameters);
	RunCallback(NotificationOnCompletion, Result);   
	
EndProcedure

// The procedure starts connecting the device.
//
Async Procedure StartConnectingDevice(NotificationOnCompletion, ConnectionParameters) Export
	
	Result = Await ConnectDeviceAsync(ConnectionParameters);
	RunCallback(NotificationOnCompletion, Result); 
	
EndProcedure

// The procedure starts disconnecting the device.
//
Async Procedure StartDisconnectingDevice(NotificationOnCompletion, ConnectionParameters) Export
	
	Result = Await DisableDeviceAsync(ConnectionParameters);
	RunCallback(NotificationOnCompletion, Result); 
	
EndProcedure

// The procedure starts the device test.
//
Async Procedure StartDeviceTest(NotificationOnCompletion, ConnectionParameters, ExecutionParameters) Export
	
	Result = Await DeviceTestAsync(ConnectionParameters);
	RunCallback(NotificationOnCompletion, Result); 
	
EndProcedure            

// The procedure starts the device's auto-tuning.
//
Async Procedure StartAutoTuningDevice(NotificationOnCompletion, ConnectionParameters, ExecutionParameters) Export
	
	Result = Await AutoTuningDeviceAsync(ConnectionParameters);
	RunCallback(NotificationOnCompletion, Result); 
	
EndProcedure

// Performing an additional action for the device.
//
Async Procedure StartPerformAdditionalAction(NotificationOnCompletion, ConnectionParameters, ExecutionParameters) Export
	
	Result = Await DoAdditionalActionAsync(ConnectionParameters, ExecutionParameters);
	RunCallback(NotificationOnCompletion, Result); 
	
EndProcedure   

#EndRegion

#Region ProcessEvent 

Function ProcessBarcodeEvent(Data) Export
	
	EventName = "ScanData";
	Barcode = TrimAll(Data);
	If EquipmentManagerClient.InputDevicesEventNewFormat() Then
		EventData = New Structure("Barcode,Data", Barcode, Data);
	Else
		EventData = New Array();
		EventData.Add(Barcode);
		SecondOrderArray = New Array();
		SecondOrderArray.Add(Data);
		SecondOrderArray.Add(Barcode);
		SecondOrderArray.Add(0);
		EventData.Add(SecondOrderArray);
	EndIf;
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", True);
	ProcessingResult.Insert("Event"  , EventName);
	ProcessingResult.Insert("Data"   , EventData);
	Return ProcessingResult;
	
EndFunction

Function ProcessBarcodeEvent64(Data) Export
	
	EventName = "ScanDataBase64";
	Barcode = TrimAll(Data);
	If EquipmentManagerClient.InputDevicesEventNewFormat() Then
		EventData = New Structure("Barcode,Data", Barcode, Data);
	Else
		EventData = New Array();
		EventData.Add(Barcode);
		SecondOrderArray = New Array();
		SecondOrderArray.Add(Data);
		SecondOrderArray.Add(Barcode);
		SecondOrderArray.Add(0);
		EventData.Add(SecondOrderArray);
	EndIf;
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", True);
	ProcessingResult.Insert("Event"  , EventName);
	ProcessingResult.Insert("Data"   , EventData);
	Return ProcessingResult;
	
EndFunction

Function ProcessKeystroke(Data) Export
	
	EventName = "KeyPress";
	Barcode = TrimAll(Data);
	EventData = New Structure("PressedKey,Data", TrimAll(Data), Data);
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", True);
	ProcessingResult.Insert("Event"  , EventName);
	ProcessingResult.Insert("Data"   , EventData);
	Return ProcessingResult;
	
EndFunction

Function ProcessPressOnDisplay(Data) Export
	
	EventName = "Pressed";
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", True);
	ProcessingResult.Insert("Event"  , EventName);
	ProcessingResult.Insert("Data"   , Data);
	Return ProcessingResult;
	
EndFunction

// ++ Non-mobile application

// Process the card data event.
// 
// Parameters:
//  ConnectionParameters - Structure
//  Data - String
// 
// Returns:
//  Structure 
Function ProcessCardDataEvent(ConnectionParameters, Data) Export
	
	CardCode  = Data;
	PrefixPosition = 0;
	SuffixPosition = 0;
	TimeCardCode    = "";
	CardData     = "";
	ReadingPosition = 1;
	Parameters = ConnectionParameters.Parameters;
	
	TrackData = New Array();
	If Parameters.Property("TrackParameters") And Parameters.TrackParameters <> Undefined Then
		For TrackNumber = 1 To 3 Do
			TrackData.Add("");
			CurTrack = Parameters.TrackParameters[TrackNumber - 1];
			If CurTrack.Use Then
				DriverPrefix = Char(CurTrack.Prefix);
				DriverSuffix = Char(CurTrack.Suffix);
				If ReadingPosition < StrLen(CardCode) Then
					CardData = Mid(CardCode, ReadingPosition);
					PrefixPosition = Find(CardData, DriverPrefix);
					SuffixPosition = Find(CardData, DriverSuffix);
					TimePrefixPosition = ?(PrefixPosition = 0, 1, PrefixPosition + StrLen(DriverPrefix));
					TimeLengthBeforeSuffix = ?(SuffixPosition = 0, StrLen(CardData) + 1 - TimePrefixPosition, SuffixPosition - TimePrefixPosition);
					TimeCardCode = TimeCardCode + Mid(CardData, TimePrefixPosition, TimeLengthBeforeSuffix);
					TrackData[TrackNumber - 1] = Mid(CardData, TimePrefixPosition, TimeLengthBeforeSuffix);
					ReadingPosition = ReadingPosition + ?(SuffixPosition = 0, StrLen(CardData), SuffixPosition + StrLen(DriverSuffix) - 1);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	EventName = "TracksData";
	CardCode = TimeCardCode;
	If Parameters.TrackParameters <> Undefined 
		 And CommonCELClient.InputDevicesAreUsed() Then
		 
		ModuleHardwareInputDevicesClient = CommonCELClient.CommonModule("PeripheralsInputDevicesClient");
		TemplateList = ModuleHardwareInputDevicesClient.DecryptMagneticCardCode(TrackData, Parameters.TrackParameters);
		
	Else
		TemplateList = Undefined;
	EndIf;
	
	If EquipmentManagerClient.InputDevicesEventNewFormat() Then
		EventData = New Structure();
		EventData.Insert("CardCode"      , CardCode);
		EventData.Insert("Data"        , Data);
		EventData.Insert("TrackData" , TrackData);
		EventData.Insert("TemplateList", TemplateList);
	Else
		EventData = New Array();
		EventData.Add(CardCode);
		SecondOrderArray = New Array();
		SecondOrderArray.Add(Mid(Data,2));
		SecondOrderArray.Add(TrackData);
		SecondOrderArray.Add(0);
		SecondOrderArray.Add(TemplateList);
		EventData.Add(SecondOrderArray);
	EndIf;
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", True);
	ProcessingResult.Insert("Event"  , EventName);
	ProcessingResult.Insert("Data"   , EventData);
	Return ProcessingResult;
	
EndFunction

Function ProcessRFIDEvent(ConnectionParameters, Event, Data) Export
	
	Result = False;
	EventData = "";
	
	If CommonCELClient.RFIDReaderIsUsed() Then
		OperationData = New Structure("IDPackage", Data);
		ExecutionResult = GetDataTagsRFID(ConnectionParameters.DriverObject, ConnectionParameters, OperationData);
		If ExecutionResult.Result Then
			EventData = EquipmentManagerServerCall.RFIDTags(ExecutionResult.LabelTable);
			Result = True;
		EndIf;
	EndIf;
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", Result);
	ProcessingResult.Insert("Event"  , Event);
	ProcessingResult.Insert("Data"   , EventData);
	Return ProcessingResult;
	
EndFunction

// -- Non-mobile application 

Function HandleWeightEvent(ConnectionParameters, Data) Export
	
	Result = True;
	EventName = "Weighting";          
	Stabilization = True;
	PlacementError = False;  
	IntersectionArea = New Array();
	Weight = 0;
	
	Data_Array = StrSplit(TrimAll(Data), ";");     
	Try
		Weight = ?(Data_Array.Count() > 0, Number(Data_Array[0]), 0);    
		If Data_Array.Count() > 1 And Upper(Data_Array[1]) = "UNSTABLE" Then
			Stabilization = False; // The weight is not stabilized
		EndIf;
		If Data_Array.Count() > 2 Then // Placement Error        
			ArrayPlacementError = StrSplit(TrimAll(Data_Array[2]), ",");   
			For Each ElementPlacementError In ArrayPlacementError Do
				PlacementError = True;   
				If Not IsBlankString(ElementPlacementError) And Upper(Left(ElementPlacementError,3)) = "ERR" Then 
					RowOfIntersectionAreas = Mid(ElementPlacementError, 5); 
					If Not IsBlankString(RowOfIntersectionAreas) Then
						IntersectionArea.Add(Number(RowOfIntersectionAreas));
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	Except
		Result = False;    
	EndTry;
		
	EventData = WeightEventParameters();
	EventData.DeviceID = ConnectionParameters.DeviceID; 
	EventData.Weight = Weight;
	EventData.Stabilization = Stabilization;   
	EventData.PlacementError = PlacementError;  
	EventData.IntersectionArea  = IntersectionArea;

	ProcessingResult = New Structure();
	ProcessingResult.Insert("Result", Result);
	ProcessingResult.Insert("Event"  , EventName);
	ProcessingResult.Insert("Data"   , EventData);
	Return ProcessingResult;
	
EndFunction

// This function handles external events of the connected hardware.
//
// Returns:
//  Structure   
//
Function ProcessEvent(DriverObject, ConnectionParameters, Event, Data) Export
	
	Operation = StrTemplate(NStr("vi = 'Sự kiện: %1';
								|ru = 'Событие: %1';
								|en = 'Event: %1'; fa = 'Event: %1';
								|it = 'Событие: %1';
								|pl = 'Event: %1';
								|tr = 'Etkinlik: %1'"), Event);
	DataForLog = CommonCELClientServer.BarcodeInBase64(Data);
	EntryOfLog = StartRecordingOperationLog(ConnectionParameters, Operation, DataForLog, "Data");
	
	If Event = "Barcode" Or Event = "Barcode" Then
		ProcessingResult = ProcessBarcodeEvent(Data);
	ElsIf Event = "BarcodeBASE64" Or Event = "BarcodeBase64" Then
		ProcessingResult = ProcessBarcodeEvent64(Data);
	// ++ Non-mobile application
	ElsIf Event = "CardData" Or Event = "TracksData" Then
		ProcessingResult = ProcessCardDataEvent(ConnectionParameters, Data);
	// -- Non-mobile application 
	ElsIf Event = "PressingKey" Or Event = "KeyPress" Then
		ProcessingResult = ProcessKeystroke(Data);
	ElsIf Event = "Weighing" Or Event = "Weighting" Then
		ProcessingResult = HandleWeightEvent(ConnectionParameters, Data);                         
	// ++ Non-mobile application
	ElsIf Event = "RFID" Then
		ProcessingResult = ProcessRFIDEvent(ConnectionParameters, Event, Data);
	// -- Non-mobile application 
	ElsIf Event = "Click" Or Event = "OnClick" Then
		ProcessingResult = ProcessPressOnDisplay(Data);
	Else
		ProcessingResult = New Structure();
		ProcessingResult.Insert("Result", False);
		ProcessingResult.Insert("Event"  , "");
		ProcessingResult.Insert("Data"   , Data);
		Return ProcessingResult;
	EndIf;            
	
	CompleteRecordingOfOperationLog(EntryOfLog, ProcessingResult);
	Return ProcessingResult;
	
EndFunction

#EndRegion

#Region CommonSynchronousHandlerMethods

// Constructor of the result of operation on hardware
// 
// Parameters:
//  Result - Boolean
//  ErrorDescription - String
//                 - Undefined
//  DeviceID - CatalogRef.Peripherals
//                          - Undefined
//
// Returns:
//  Structure:
//   * Result - Boolean
//   * ErrorDescription - String
//                    - Undefined
//   * LoadingError - Boolean
//   * DeviceID - CatalogRef.Peripherals
//                             - Undefined
//
Function ResultOfOperationOnEquipment(Result = False, ErrorDescription = Undefined, DeviceID = Undefined) Export
	
	ExecutionResult = New Structure();
	ExecutionResult.Insert("Result"     , Result);
	ExecutionResult.Insert("ErrorDescription", ErrorDescription);
	ExecutionResult.Insert("LoadingError", False);
	ExecutionResult.Insert("DeviceID", DeviceID);
	Return ExecutionResult;
	
EndFunction

Function DriverLoadingError(ConnectionParameters, ErrorDescription = "") Export
	
	Text = NStr("vi = '%1: Không thể kết nhập driver thiết bị.
				|Hãy kiểm tra, đã cài đặt đúng thiết bị và đăng ký nó trong hệ thống chưa.
				|%2';
				|ru = '%1: Не удалось загрузить драйвер устройства.
				|Проверьте, что драйвер корректно установлен и зарегистрирован в системе.
				|%2';
				|en = '%1: Cannot import the device driver.
				|Check if the driver is correctly installed and registered in the application.
				|%2'; fa = '%1: Cannot import the device driver.
				|Check if the driver is correctly installed and registered in the application.
				|%2';
				|it = '%1: Не удалось загрузить драйвер устройства.
				|Проверьте, что драйвер корректно установлен и зарегистрирован в системе.
				|%2';
				|pl = '%1: Cannot import the device driver.
				|Check if the driver is correctly installed and registered in the application.
				|%2';
				|tr = '%1: Cihaz sürücüsü yüklenemedi.
				|Sürücünün doğru şekilde kurulduğunu ve sisteme kaydedildiğini kontrol edin.
				|%2'");
	Text = StrTemplate(Text, ConnectionParameters.Description, ErrorDescription);
	ExecutionResult = ResultOfOperationOnEquipment(False, Text);
	ExecutionResult.LoadingError = True;
	Return ExecutionResult;
	
EndFunction      

Function DriverCallError(DriverMethod = Undefined, ErrorDescription = Undefined, LogEntry = False) Export
	
	If Not IsBlankString(DriverMethod) Then
		ErrorMessage = NStr("vi = 'Lỗi gọi ra phương thức driver <%1>.';
							|ru = 'Ошибка вызова метода драйвера <%1>.';
							|en = 'An error occurred when calling the <%1> driver method.'; fa = 'An error occurred when calling the <%1> driver method.';
							|it = 'Ошибка вызова метода драйвера <%1>.';
							|pl = 'An error occurred when calling the <%1> driver method.';
							|tr = '<%1> sürücü yönteminin çağrısında hata oluştu.'");
		ErrorMessage = StrTemplate(ErrorMessage, DriverMethod); 
	Else
		ErrorMessage = NStr("vi = 'Kiểu thiết bị này không hỗ trợ lệnh này.';
							|ru = 'Данный тип оборудования не поддерживает данную команду.';
							|en = 'This peripherals type does not support the command.'; fa = 'This peripherals type does not support the command.';
							|it = 'Questo tipo di apparecchiatura non supporta questo comando.';
							|pl = 'Ten typ urządzenia nie obsługuje to polecenie.';
							|tr = 'Bu donanım türü bu komutu desteklemiyor.'");
	EndIf;
	
	If Not IsBlankString(ErrorDescription) Then
		ErrorMessage = ErrorMessage + Chars.LF + ErrorDescription;
	EndIf;
	
	If LogEntry Then
		CommonCELClient.WriteErrorToEventLog(NStr("vi = 'Thiết bị kết nối.';
													|ru = 'Подключаемое оборудование.';
													|en = 'Peripherals.'; fa = 'Peripherals.';
													|it = 'Подключаемое оборудование.';
													|pl = 'Urządzenia peryferyjne.';
													|tr = 'Bağlanabilir donanım.'"), ErrorMessage);
	EndIf;
	
	ExecutionResult = ResultOfOperationOnEquipment(False, ErrorMessage);
	Return ExecutionResult;
	
EndFunction

#EndRegion

// ++ Non-mobile application

#Region Recognizer

// The function performs recognition.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function RecognizeAsync(DriverObject, ConnectionParameters, OperationData) Export
	
	Learn = OperationData.Learn;
	Variants = OperationData.Variants;
	RecognizedXMLGoods = "";
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Recognize", ToArray(Undefined,Learn, Variants));
		CallResult = Await DriverObject.RecognizeAsync(ConnectionParameters.DeviceID_, Learn, Variants, RecognizedXMLGoods); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			RecognizedXMLGoods = String(CallResult.Parameters[3]);
			Result = ResultOfOperationOnEquipment(True);
			Result.Insert("RecognizedGoods", RecognizedXMLGoods);
		Else
			Result = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		Result = DriverCallError("Recognize", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Result;
	
EndFunction

// The function confirms recognition.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function ConfirmRecognitionAsync(DriverObject, ConnectionParameters, OperationData) Export
	
	Code = OperationData.Code;
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ConfirmRecognize", ToArray(Undefined,Code));
		CallResult = Await DriverObject.ConfirmRecognitionAsync(ConnectionParameters.DeviceID_, Code); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			Result = ResultOfOperationOnEquipment(True);
		Else
			Result = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		Result = DriverCallError("ConfirmRecognition", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#Region LabelPrintingScales

// The function uploads XML items to scales with label printing.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   DataToUpload - Structure
//   PackageStatus - Boolean
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function UploadXMLToLibra(DriverObject, ConnectionParameters, DataToUpload, PackageStatus) Export

	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "UploadGoods", ToArray(Undefined, DataToUpload, PackageStatus));
		CallResult = Await DriverObject.UploadGoodsAsync(ConnectionParameters.DeviceID_, DataToUpload, PackageStatus); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
	Except                  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("UploadGoods", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return ExecutionResult;
	EndTry;
		
	If CallResult.Value <> True Then
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);        
		Return ExecutionResult;
	EndIf; 
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	Return ExecutionResult;   
	
EndFunction

// The function unloads goods into scales with label printing.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function UploadGoods(DriverObject, ConnectionParameters, OperationData) Export
	
	PackageStatus = "first";
	
	NumberOfPackages_ = OperationData.XMLPackages.Count();
	PercentageIncrement = 100 / NumberOfPackages_;
	CurrentPercentage  = 0;
	CurPackage_ = 0;
	
	PackageStatus = ?(NumberOfPackages_ > 1 , "first", "last");
	
	For Each DataToUpload In OperationData.XMLPackages  Do
		
		ExecutionResult = Await UploadXMLToLibra(DriverObject, ConnectionParameters, DataToUpload, PackageStatus);
		If Not ExecutionResult.Result Then
			Return ExecutionResult;
		EndIf; 
		
		CurPackage_ = CurPackage_ + 1;
		PackageStatus = ?(CurPackage_ < NumberOfPackages_ - 1 , "regular", "last");
		CurrentPercentage = CurrentPercentage + PercentageIncrement;
		Status(NStr("vi = 'Kết xuất dữ liệu...';
					|ru = 'Выгрузка данных...';
					|en = 'Exporting data…'; fa = 'Exporting data…';
					|it = 'Upload dei dati...';
					|pl = 'Eksportowanie danych...';
					|tr = 'Veriler dışa aktarılıyor...'"), Round(CurrentPercentage));
	EndDo; 
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	Return ExecutionResult;   
	
EndFunction          

// The function unloads goods into scales with label printing.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function UnloadItemsAsPackage(DriverObject, ConnectionParameters, OperationData) Export
	
	DataToUpload = ?(OperationData.Property("XMLPackage"), OperationData.XMLPackage, "");
	If IsBlankString(DataToUpload) Then
		ErrorDescription = NStr("vi = 'Gói XML để kết xuất trống.';
								|ru = 'XML пакет для выгрузки пустой.';
								|en = 'The XML package for export is empty.'; fa = 'The XML package for export is empty.';
								|it = 'XML пакет для выгрузки пустой.';
								|pl = 'The XML package for export is empty.';
								|tr = 'Dışa aktarma için XML paketi boş.'");
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	PackageStatus = "last";                                                                                
	
	ExecutionResult = Await UploadXMLToLibra(DriverObject, ConnectionParameters, DataToUpload, PackageStatus);
	Return ExecutionResult;  
	
EndFunction

// The function cleans the database of goods in scales with label printing.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function ClearGoodsInLibra(DriverObject, ConnectionParameters, OperationData) Export
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ClearGoods");
		CallResult = Await DriverObject.ClearGoodsAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ClearGoods", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;  
	
EndFunction

// Upload images of goods to the scales by printing labels.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function UploadProductImages(DriverObject, ConnectionParameters, OperationData) Export
	
	If ConnectionParameters.InterfaceRevision < 3009 Then
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'");
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		LogError_(ConnectionParameters, "UploadProductImages", ErrorDescription);
		Return ExecutionResult;
	EndIf;

	PackageStatus = "first";
	
	NumberOfPackages_ = OperationData.XMLPackages.Count();
	PercentageIncrement = 100 / NumberOfPackages_;
	CurrentPercentage  = 0;
	CurPackage_ = 0;
	
	PackageStatus = ?(NumberOfPackages_ > 1 , "first", "last");
	
	For Each DataToUpload In OperationData.XMLPackages  Do
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "UploadProductImages", ToArray(Undefined, DataToUpload, PackageStatus));
			CallResult = Await DriverObject.UploadProductImagesAsync(ConnectionParameters.DeviceID_, DataToUpload, PackageStatus); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except                  
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("UploadProductImages", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return ExecutionResult;
		EndTry;
		
		If CallResult.Value <> True Then
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);        
			Return ExecutionResult;
		EndIf; 
		CurPackage_ = CurPackage_ + 1;
		PackageStatus = ?(CurPackage_ < NumberOfPackages_ - 1 , "regular", "last");
		CurrentPercentage = CurrentPercentage + PercentageIncrement;
		Status(NStr("vi = 'Kết xuất dữ liệu...';
					|ru = 'Выгрузка данных...';
					|en = 'Exporting data…'; fa = 'Exporting data…';
					|it = 'Upload dei dati...';
					|pl = 'Eksportowanie danych...';
					|tr = 'Veriler dışa aktarılıyor...'"), Round(CurrentPercentage));
	EndDo; 
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	Return ExecutionResult;   
	
EndFunction

#EndRegion

// -- Non-mobile application 

#Region DigitalRetailScales

// The function receives the weight of the load located on the scale.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function GetWeight(DriverObject, ConnectionParameters, OperationData) Export
	
	Weight = 0;   
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetWeight");
		CallResult = Await DriverObject.GetWeightAsync(ConnectionParameters.DeviceID_, Weight); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			Weight = Number(CallResult.Parameters[1]);
			If Weight < 0 Then
				Weight  = 0;  
			EndIf;           
			ExecutionResult = ResultOfOperationOnEquipment(True);
			ExecutionResult.Insert("Weight", Weight);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("GetWeight", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function sets the weight of the container on the scale.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function Tariffing(DriverObject, ConnectionParameters, OperationData) Export
	
	If ConnectionParameters.InterfaceRevision >= 4001 And Not ConnectionParameters.ScalesSupportTaring Then
		ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
								|ru = 'Оборудование не поддерживает данную операцию.';
								|en = 'The peripheral does not support this transaction.'; fa = 'The peripheral does not support this transaction.';
								|it = 'Оборудование не поддерживает данную операцию.';
								|pl = 'The peripheral does not support this transaction.';
								|tr = 'Ekipman, bu işlemi desteklememektedir.'"); 
		LogError_(ConnectionParameters, "Calibrate", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	
	TareWeight = ?(OperationData.Property("TareWeight"), Number(OperationData.TareWeight), 0);
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Calibrate", ToArray(Undefined,TareWeight));
		CallResult = Await DriverObject.SetTareWeightAsync(ConnectionParameters.DeviceID_, TareWeight); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("Calibrate", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

#Region CustomerDisplay

// The function returns the output parameters to the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function OutputParameters(DriverObject, ConnectionParameters, OperationData) Export
	
	If ConnectionParameters.InterfaceRevision >= 3004 Then
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetCustomerDisplayOptions");
			CallResult = Await DriverObject.GetCustomerDisplayOptionsAsync(ConnectionParameters.DeviceID_, ""); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			ResultOfXMLOperation = CallResult.Parameters[1];
			If CallResult.Value Then
				ParametersOfDisplay = CommonCELClient.ReadRootXMLElement(ResultOfXMLOperation);
				If ParametersOfDisplay.Property("Columns") And Not IsBlankString(ParametersOfDisplay.Columns) Then
					ConnectionParameters.ColumnsOnDisplay = Number(ParametersOfDisplay.Columns);
				EndIf; 
				If ParametersOfDisplay.Property("Rows") And Not IsBlankString(ParametersOfDisplay.Rows) Then
					ConnectionParameters.LinesOnDisplay = Number(ParametersOfDisplay.Rows);
				EndIf; 
				ConnectionParameters.DisplayDisplaysText   = ParametersOfDisplay.Property("DisplayText") And Upper(ParametersOfDisplay.DisplayText) = "TRUE"; 
				ConnectionParameters.DisplayDisplaysGraphics = ParametersOfDisplay.Property("DisplayGraphics") And Upper(ParametersOfDisplay.DisplayGraphics) = "TRUE"; 
				ConnectionParameters.DisplayDisplaysQRCode   = ParametersOfDisplay.Property("DisplayQRCode") And Upper(ParametersOfDisplay.DisplayQRCode) = "TRUE"; 
				ConnectionParameters.DisplayDisplaysHTML    = ParametersOfDisplay.Property("DisplayHTML") And Upper(ParametersOfDisplay.DisplayHTML) = "TRUE"; 
				ConnectionParameters.DISPLAYShowsStatus  = ParametersOfDisplay.Property("DisplayStatus") And Upper(ParametersOfDisplay.DisplayStatus) = "TRUE"; 
				ConnectionParameters.DisplayShowsStatusOfRM = ParametersOfDisplay.Property("DisplayWorkplaceStatus") And Upper(ParametersOfDisplay.DisplayWorkplaceStatus) = "TRUE"; 
				ConnectionParameters.DisplayWorksOutClicks   = ParametersOfDisplay.Property("DisplayInteractiveMode") And Upper(ParametersOfDisplay.DisplayInteractiveMode) = "TRUE"; 
				
				ExecutionResult = ResultOfOperationOnEquipment(True);
				ExecutionResult.Insert("ColumnsOnDisplay", ConnectionParameters.ColumnsOnDisplay);
				ExecutionResult.Insert("LinesOnDisplay"   , ConnectionParameters.LinesOnDisplay);
				ExecutionResult.Insert("DisplayDisplaysText"  , ConnectionParameters.DisplayDisplaysText);
				ExecutionResult.Insert("DisplayDisplaysGraphics", ConnectionParameters.DisplayDisplaysGraphics);
				ExecutionResult.Insert("DisplayDisplaysQRCode"  , ConnectionParameters.DisplayDisplaysQRCode);
				ExecutionResult.Insert("DisplayDisplaysHTML"   , ConnectionParameters.DisplayDisplaysHTML);    
				ExecutionResult.Insert("DISPLAYShowsStatus" , ConnectionParameters.DISPLAYShowsStatus);  
				ExecutionResult.Insert("DisplayShowsStatusOfRM", ConnectionParameters.DisplayShowsStatusOfRM); 
				ExecutionResult.Insert("DisplayWorksOutClicks",  ConnectionParameters.DisplayWorksOutClicks); 
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf         
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("GetCustomerDisplayOptions", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetOutputOptions");
			CallResult = Await DriverObject.GetOutputParametersAsync(ConnectionParameters.DeviceID_, 20, 2); // Structure 
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			If CallResult.Value Then
				ConnectionParameters.ColumnsOnDisplay = Number(CallResult.Parameters[1]);
				ConnectionParameters.LinesOnDisplay    = Number(CallResult.Parameters[2]);
				ExecutionResult = ResultOfOperationOnEquipment(True);
				ExecutionResult.Insert("ColumnsOnDisplay", ConnectionParameters.ColumnsOnDisplay);
				ExecutionResult.Insert("LinesOnDisplay"   , ConnectionParameters.LinesOnDisplay);
				ExecutionResult.Insert("DisplayDisplaysText"  , True);
				ExecutionResult.Insert("DisplayDisplaysGraphics", False);
				ExecutionResult.Insert("DisplayDisplaysQRCode"  , False);     
				ExecutionResult.Insert("DisplayDisplaysHTML"   , False);     
				ExecutionResult.Insert("DISPLAYShowsStatus" , False);    
				ExecutionResult.Insert("DisplayShowsStatusOfRM", False);    
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except          
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("GetOutputOptions", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf; 
	
	Return ExecutionResult;
	
EndFunction

// The function displays a list of lines on the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function StringOutputOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	LinesOfText = ?(OperationData.Property("LinesOfText"), OperationData.LinesOfText, NStr("vi = 'Chưa chỉ định dữ liệu để hiển thị';
																							|ru = 'Данные для вывода не указаны';
																							|en = 'Output data is not specified'; fa = 'Output data is not specified';
																							|it = 'Dati per la chiamata non indicati';
																							|pl = 'Dane do wyprowadzenie nie są określone';
																							|tr = 'Çıktı verisi belirtilmemiş'"));
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "StringOutputOnCustomerDisplay", ToArray(Undefined,LinesOfText));
		CallResult = Await DriverObject.StringOutputOnCustomerDisplayAsync(ConnectionParameters.DeviceID_, LinesOfText); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("StringOutputOnCustomerDisplay", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function displays the QR code on the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function QRCodeOutputOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	QRCodeValue = ?(OperationData.Property("QRCodeValue"), OperationData.QRCodeValue, "");
	PictureQRCode = ?(OperationData.Property("PictureQRCode"), OperationData.PictureQRCode, "");   
	LinesOfText = ?(OperationData.Property("LinesOfText"), OperationData.LinesOfText, "");  
	
	If Not IsBlankString(LinesOfText) Then    
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "StringOutputOnCustomerDisplay", ToArray(Undefined,LinesOfText));
			CallResult = Await DriverObject.StringOutputOnCustomerDisplayAsync(ConnectionParameters.DeviceID_, LinesOfText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			If CallResult.Value Then
				ExecutionResult = ResultOfOperationOnEquipment(True);
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);  
				Return ExecutionResult;
			EndIf;
		Except  
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("StringOutputOnCustomerDisplay", ErrorProcessing.DetailErrorDescription(ErrorInfo()));  
			Return ExecutionResult;
		EndTry;   
	EndIf;
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "QRCodeOutputOnCustomerDisplay", ToArray(Undefined,QRCodeValue, PictureQRCode));
		CallResult = Await DriverObject.QRCodeOutputOnCustomerDisplayAsync(ConnectionParameters.DeviceID_, QRCodeValue, PictureQRCode); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("QRCodeOutputOnCustomerDisplay", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction           

// The function displays HTML on the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function DisplayHtmlOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	HTMLText = ?(OperationData.Property("HTMLText"), OperationData.HTMLText, "");  
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "OutputHTML", ToArray(Undefined,HTMLText));
		CallResult = Await DriverObject.OutputHTMLAsync(ConnectionParameters.DeviceID_, HTMLText); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("OutputHTML", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction            

// The function displays information on the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function DisplayInformationOnBuyerSDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	
	If ConnectionParameters.DisplayDisplaysHTML Then
		ExecutionResult = Await DisplayHtmlOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	Else
		
		If ConnectionParameters.DisplayDisplaysText Then      
			ExecutionResult = Await StringOutputOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
		EndIf;
		
		If ConnectionParameters.DisplayDisplaysQRCode Then
			ExecutionResult = Await QRCodeOutputOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
		EndIf;
		
		If ConnectionParameters.DISPLAYShowsStatus Then       
			OperationStatus  = ?(OperationData.Property("OperationStatus"), OperationData.OperationStatus, 0);
			If OperationStatus = 1 Or OperationStatus = 2 Then
				ExecutionResult = Await DisplayStatusOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
			EndIf;
		EndIf;
		
	EndIf;
	
	If ConnectionParameters.DisplayShowsStatusOfRM Then
		ExecutionResult = Await DisplayStatusOfWorkplaceOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData);
	EndIf;
		
	Return ExecutionResult;
	
EndFunction 

// The function displays the Status on the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function DisplayStatusOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	If ConnectionParameters.InterfaceRevision < 3009  Then
		ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
								|ru = 'Устройство не поддерживает данную операцию.';
								|en = 'The device does not support this transaction.'; fa = 'The device does not support this transaction.';
								|it = 'Устройство не поддерживает данную операцию.';
								|pl = 'The device does not support this transaction.';
								|tr = 'Cihaz, bu işlemi desteklememektedir.'");
		LogError_(ConnectionParameters, "DisplayOperationStatus", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);   
		Return ExecutionResult;
	EndIf;
	
	OperationStatus  = ?(OperationData.Property("CodeStatusOfOperation"), OperationData.CodeStatusOfOperation, 0);
	Try                                                                                    
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "DisplayOperationStatus", ToArray(Undefined,OperationStatus));
		CallResult = Await DriverObject.DisplayStatusOfOPERATIONAsync(ConnectionParameters.DeviceID_, OperationStatus); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except    
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("DisplayStatusOfOPERATION", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction     

// The function displays the Status of the workplace on the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function DisplayStatusOfWorkplaceOnCustomerDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	If ConnectionParameters.InterfaceRevision < 4001  Then
		ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
								|ru = 'Устройство не поддерживает данную операцию.';
								|en = 'The device does not support this transaction.'; fa = 'The device does not support this transaction.';
								|it = 'Устройство не поддерживает данную операцию.';
								|pl = 'The device does not support this transaction.';
								|tr = 'Cihaz, bu işlemi desteklememektedir.'");
		LogError_(ConnectionParameters, "DisplayWorkplaceStatus", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);   
		Return ExecutionResult;
	EndIf;
	
	WorkplaceStatus = ?(OperationData.Property("WorkplaceStatusCode"), OperationData.WorkplaceStatusCode, 0);  
	SoundSignal = ?(OperationData.Property("SoundSignal"), ?(OperationData.SoundSignal, 1, 0), 0);  
	
	If SoundSignal = 0 
		And ConnectionParameters.Property("CodeOfCurrentStatusOfWorkplace") 
		And ConnectionParameters.CodeOfCurrentStatusOfWorkplace = WorkplaceStatus Then
		Return ResultOfOperationOnEquipment(True);
	EndIf;
	ConnectionParameters.Insert("CodeOfCurrentStatusOfWorkplace", WorkplaceStatus);
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "DisplayWorkplaceStatus", ToArray(Undefined,WorkplaceStatus, SoundSignal));
		CallResult = Await DriverObject.DisplayWorkplaceStatusAsync(ConnectionParameters.DeviceID_, WorkplaceStatus, SoundSignal); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except    
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("DisplayWorkplaceStatus", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction     

// The function cleans the buyer's display.
//
// Parameters:
//   DriverObject - AddInObject
//   ConnectionParameters - Structure
//   OperationData - Structure
//
// Returns:
//   See ResultOfOperationOnEquipment
//
Async Function ClearCustomerDisplay(DriverObject, ConnectionParameters, OperationData) Export
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ClearCustomerDisplay");
		CallResult = Await DriverObject.ClearCustomerDisplayAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ClearCustomerDisplay", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

//  Set the application information in the driver
// 
// Parameters:
//  ConnectionParameters - Structure
//  Execution Parameterization - Structure
//  
// Returns:
//  See ResultOfOperationOnEquipment
//
Async Function SetAsyncsApplicationInformation(DriverObject, ConnectionParameters) 
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "SetApplicationInformation", ConnectionParameters, "XMLApplicationParameters");
		CallResult = Await DriverObject.SetAsyncsApplicationInformation(ConnectionParameters.XMLApplicationParameters); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ErrorDescription = NStr("vi = 'Lỗi thiết lập thông tin ứng dụng cho driver.';
								|ru = 'Ошибка установки информации приложения для драйвера.';
								|en = 'Error installing the application information for the driver.'; fa = 'Error installing the application information for the driver.';
								|it = 'Ошибка установки информации приложения для драйвера.';
								|pl = 'Error installing the application information for the driver.';
								|tr = 'Sürücünün uygulama bilgileri yüklenirken hata oluştu.'");
		Return ResultOfOperationOnEquipment(False, ErrorDescription);
	EndTry;
	
	ExecutionResult = ResultOfOperationOnEquipment(CallResult.Value);
	If CallResult.Value <> True Then
		GetDriverError(DriverObject, EntryOfLog);
	EndIf;
	
	Return ExecutionResult;  
	
EndFunction

Async Function GetDriverError(DriverObject, EntryOfLog = Undefined, ErrorDescription = Undefined) 
	
	CallResult = Await DriverObject.GetLastErrorAsync(""); // Structure    
	ErrorText = CallResult.Parameters[0];                               
	If Not IsBlankString(ErrorDescription) Then
		ErrorText = ErrorDescription + Chars.LF + ErrorText;
	EndIf;
	ExecutionResult = ResultOfOperationOnEquipment(False, ErrorText);
	
	If EntryOfLog <> Undefined Then
		RecordDriverErrorInOperationLogOfOperation(EntryOfLog, CallResult);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

Function PresentationRevisionOfInterface(InterfaceRevision)
	
	Return CommonCELClientServer.PresentationRevisionOfInterface(InterfaceRevision);
	
EndFunction

#Region FiscalDevices

// Gets the width of the string in characters.
// 
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function LineWidth_(DriverObject, ConnectionParameters, OperationData)  
	
	If ConnectionParameters.Property("LineWidth_") And ConnectionParameters.LineWidth_ > 0 Then
		ExecutionResult = ResultOfOperationOnEquipment(True);
		ExecutionResult.Insert("LineWidth_", ConnectionParameters.LineWidth_);
		Return ExecutionResult;
	EndIf;
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetLineLength");
		CallResult = Await DriverObject.GetLineLengthAsync(ConnectionParameters.DeviceID_, 0); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);

		ConnectionParameters.LineWidth_ = CallResult.Parameters[1];     
	Except   
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		Return DriverCallError("GetLineLength", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	If CallResult.Value Then  
		ExecutionResult = ResultOfOperationOnEquipment(True);
		ExecutionResult.Insert("LineWidth_", CallResult.Parameters[1]); // Structure
	Else
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
	EndIf;     
	
	Return ExecutionResult;
	
EndFunction

// Performs fiscalization of the receipt.
//                                             
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function ReceiptFiscalization(DriverObject, ConnectionParameters, OperationData);
	
	If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter Then
		
		ExecutionResult = Await PrintText(DriverObject, ConnectionParameters, OperationData);
		
	ElsIf ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		
		CurrentStatus = Undefined;
		PurchaseConfirmationWasPerformed = False;
		If ConnectionParameters.InterfaceRevision >= 3004  Then
			CurrentStatus = EquipmentManagerClient.CheckingMarkingCode(ConnectionParameters.DeviceID);
			// If there is a current KM check 
			If Not IsBlankString(CurrentStatus.QueryID) Then
				Try
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ConfirmKM", ToArray(CurrentStatus.QueryID,0));
					CallResult = Await DriverObject.ConfirmKMAsync(ConnectionParameters.DeviceID_, CurrentStatus.QueryID, 0); // Structure
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					If Not CallResult.Value Then   
						ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
						Return ExecutionResult;
					EndIf;
					EquipmentManagerClient.InstallMarkingCodeVerification(ConnectionParameters.DeviceID);
					PurchaseConfirmationWasPerformed = True;
				Except
					ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					EndLogRecordingWithException(EntryOfLog, ErrorText);
					ExecutionResult = DriverCallError("ConfirmKM", ErrorProcessing.DetailErrorDescription(ErrorInfo())); 
					Return ExecutionResult;
				EndTry;
			EndIf;       
		EndIf;
	
		Try
			If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
				If OperationData.ThereIsPersonalData Then
					XMLReceiptData_ = OperationData.ReceiptDataAndPersonalData
				Else
					XMLReceiptData_ = OperationData.XMLReceiptData_;
				EndIf;
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(ConnectionParameters.DeviceID_, OperationData.Electronically, ShouldEscape(OperationData.XMLReceiptData_)));
				CallResult = Await DriverObject.ProcessCheckAsync(ConnectionParameters.DeviceID_, OperationData.Electronically, XMLReceiptData_, OperationData.ResultOfXMLOperation); // Structure 
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				CallParameters = CallResult.Parameters;
				OperationData.ResultOfXMLOperation = CallParameters[3];    
			Else // Standard version 2.2 (OFD 1.05)
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(Undefined,OperationData.Electronically, ShouldEscape(OperationData.XMLReceiptData_)));
				CallResult = Await DriverObject.ProcessCheckAsync(ConnectionParameters.DeviceID_, OperationData.Electronically, 
					OperationData.XMLReceiptData_, OperationData.KKTReceiptNumber, OperationData.CREShiftNumber, OperationData.FiscalFlag, OperationData.VerificationWebsiteAddress); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				CallParameters = CallResult.Parameters;
				OperationData.KKTReceiptNumber  = CallParameters[3];     
				OperationData.CREShiftNumber = CallParameters[4];  
				OperationData.FiscalFlag  = CallParameters[5];       
				OperationData.VerificationWebsiteAddress = CallParameters[6]; 
			EndIf;   
			OperationData.ReceiptDateAndTime = CommonCELClient.SessionDate();
		Except                   
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("ProcessCheck", ErrorProcessing.DetailErrorDescription(ErrorInfo())); 
			Return ExecutionResult;
		EndTry;
	
		If CallResult.Value Then              
			ExecutionResult = ResultOfOperationOnEquipment(True);
			EquipmentManagerClient.EstablishMarkingCodeVerificationSession(ConnectionParameters.DeviceID);
			If CurrentStatus <> Undefined Then
				RecordingOfOperationKM = New Structure();
				RecordingOfOperationKM.Insert("SessionID", CurrentStatus.SessionID);
				RecordingOfOperationKM.Insert("QueryID", CurrentStatus.QueryID);
				RecordingOfOperationKM.Insert("PurchaseConfirmationWasPerformed", PurchaseConfirmationWasPerformed);
				OperationData.Insert("RecordingOfOperationKM", RecordingOfOperationKM);
			EndIf;
			If OperationData.TestReceipts <> Undefined And OperationData.TestReceipts.Count() > 0 Then
				ResultOfPrintingNonFiscalDocuments = Await PrintText(DriverObject, ConnectionParameters, OperationData);
				ExecutionResult.Insert("ResultOfPrintingNonFiscalDocuments", ResultOfPrintingNonFiscalDocuments);
			EndIf;
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Else        
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'");
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction 

// Prints the correction receipt.
//
Async Function PrintingCorrectionReceipt(DriverObject, ConnectionParameters, OperationData)   
	
	Try
		
		If OperationData.CorrectionReceiptForCCT Then
			If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCorrectionCheck", ToArray( , ShouldEscape(OperationData.XMLReceiptData_)));
				If ConnectionParameters.InterfaceRevision >= 4004 Then
					CallResult = Await DriverObject.ProcessCorrectionCheckAsync(ConnectionParameters.DeviceID_, OperationData.Electronically, 
						OperationData.XMLReceiptData_, OperationData.ResultOfXMLOperation); // Structure
						
					CallParameters = CallResult.Parameters;
					Result = CallResult.Value;
					If Result Then
						OperationData.XMLReceiptData_  = CallParameters[2];
						OperationData.ResultOfXMLOperation = CallParameters[3];
					EndIf; 
				Else
					CallResult = Await DriverObject.ProcessCorrectionCheckAsync(ConnectionParameters.DeviceID_, 
						OperationData.XMLReceiptData_, OperationData.ResultOfXMLOperation); // Structure
						
					CallParameters = CallResult.Parameters;
					Result = CallResult.Value;
					If Result Then
						OperationData.XMLReceiptData_  = CallParameters[1];
						OperationData.ResultOfXMLOperation = CallParameters[2];
					EndIf; 
				EndIf; 
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			Else
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCorrectionCheck", ToArray(Undefined, ShouldEscape(OperationData.XMLReceiptData_)));
				CallResult = Await DriverObject.ProcessCorrectionCheckAsync(ConnectionParameters.DeviceID_, OperationData.XMLReceiptData_, OperationData.KKTReceiptNumber, OperationData.CREShiftNumber, 
					OperationData.FiscalFlag, OperationData.VerificationWebsiteAddress); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
				CallParameters = CallResult.Parameters;
				Result = CallResult.Value;
				If Result Then
					OperationData.XMLReceiptData_ = CallParameters[1];  
					OperationData.KKTReceiptNumber  = CallParameters[2]; 
					OperationData.CREShiftNumber      = CallParameters[3]; 
					OperationData.FiscalFlag  = CallParameters[4]; 
					OperationData.VerificationWebsiteAddress = CallParameters[5]; 
				EndIf; 
				OperationData.ReceiptDateAndTime = CommonCELClient.SessionDate();
			EndIf;  
		Else
			If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(Undefined,OperationData.Electronically, ShouldEscape(OperationData.XMLReceiptData_)));
				CallResult = Await DriverObject.ProcessCheckAsync(ConnectionParameters.DeviceID_, OperationData.Electronically, 
					OperationData.XMLReceiptData_, OperationData.ResultOfXMLOperation); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
				CallParameters = CallResult.Parameters;
				Result = CallResult.Value;
				If Result Then
					OperationData.XMLReceiptData_  = CallParameters[2];     
					OperationData.ResultOfXMLOperation = CallParameters[3];  
				EndIf; 
			Else
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(Undefined,OperationData.Electronically, ShouldEscape(OperationData.XMLReceiptData_)));
				CallResult = Await DriverObject.ProcessCheckAsync(ConnectionParameters.DeviceID_, OperationData.Electronically, 
					OperationData.XMLReceiptData_, OperationData.KKTReceiptNumber, OperationData.CREShiftNumber, OperationData.FiscalFlag, OperationData.VerificationWebsiteAddress); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
				CallParameters = CallResult.Parameters;
				Result = CallResult.Value;
				If Result Then
					OperationData.XMLReceiptData_ = CallParameters[2];  
					OperationData.KKTReceiptNumber  = CallParameters[3]; 
					OperationData.CREShiftNumber      = CallParameters[4]; 
					OperationData.FiscalFlag  = CallParameters[5]; 
					OperationData.VerificationWebsiteAddress = CallParameters[6]; 
				EndIf; 
				OperationData.ReceiptDateAndTime = CommonCELClient.SessionDate();
			EndIf;  
		EndIf;
		
		If Result And OperationData.GenerateCorrectionReceiptForReverse Then      
			ParametersOfFiscalizationOfStorno = OperationData.ReverseCorrectionCheck;
			If OperationData.CorrectionReceiptForCCT Then
				If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
					
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCorrectionCheck", ToArray(Undefined, ShouldEscape(OperationData.XMLReceiptData_)));
					If ConnectionParameters.InterfaceRevision >= 4004 Then
						CallResult = Await DriverObject.ProcessCorrectionCheckAsync(ConnectionParameters.DeviceID_, ParametersOfFiscalizationOfStorno.Electronically,
							ParametersOfFiscalizationOfStorno.XMLReceiptData_, ParametersOfFiscalizationOfStorno.ResultOfXMLOperation); // Structure
							
						CallParameters = CallResult.Parameters;
						Result = CallResult.Value;
						If Result Then
							ParametersOfFiscalizationOfStorno.XMLReceiptData_  = CallParameters[2];
							ParametersOfFiscalizationOfStorno.ResultOfXMLOperation = CallParameters[3];
						EndIf; 
					Else
						CallResult = Await DriverObject.ProcessCorrectionCheckAsync(ConnectionParameters.DeviceID_, 
							ParametersOfFiscalizationOfStorno.XMLReceiptData_, ParametersOfFiscalizationOfStorno.ResultOfXMLOperation); // Structure     
						
						CallParameters = CallResult.Parameters;
						Result = CallResult.Value;
						If Result Then
							ParametersOfFiscalizationOfStorno.XMLReceiptData_  = CallParameters[1];     
							ParametersOfFiscalizationOfStorno.ResultOfXMLOperation = CallParameters[2];  
						EndIf; 
					EndIf; 
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
				Else
					
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCorrectionCheck", ToArray(Undefined, ShouldEscape(OperationData.XMLReceiptData_)));
					CallResult = Await DriverObject.ProcessCorrectionCheckAsync(ConnectionParameters.DeviceID_, ParametersOfFiscalizationOfStorno.XMLReceiptData_, ParametersOfFiscalizationOfStorno.KKTReceiptNumber, ParametersOfFiscalizationOfStorno.CREShiftNumber, 
						ParametersOfFiscalizationOfStorno.FiscalFlag, ParametersOfFiscalizationOfStorno.VerificationWebsiteAddress); // Structure
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
					
					CallParameters = CallResult.Parameters;
					Result = CallResult.Value;
					If Result Then
						ParametersOfFiscalizationOfStorno.XMLReceiptData_ = CallParameters[1];  
						ParametersOfFiscalizationOfStorno.KKTReceiptNumber  = CallParameters[2]; 
						ParametersOfFiscalizationOfStorno.CREShiftNumber      = CallParameters[3]; 
						ParametersOfFiscalizationOfStorno.FiscalFlag  = CallParameters[4]; 
						ParametersOfFiscalizationOfStorno.VerificationWebsiteAddress = CallParameters[5]; 
					EndIf; 
					ParametersOfFiscalizationOfStorno.ReceiptDateAndTime = CommonCELClient.SessionDate();
				EndIf;  
			Else        
				If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0
					
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(Undefined, OperationData.Electronically, ShouldEscape(OperationData.XMLReceiptData_)));
					CallResult = Await DriverObject.ProcessCheckAsync(ConnectionParameters.DeviceID_, ParametersOfFiscalizationOfStorno.Electronically, 
						ParametersOfFiscalizationOfStorno.XMLReceiptData_, ParametersOfFiscalizationOfStorno.ResultOfXMLOperation); // Structure
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
					CallParameters = CallResult.Parameters;
					Result = CallResult.Value;
					If Result Then
						ParametersOfFiscalizationOfStorno.XMLReceiptData_  = CallParameters[2];     
						ParametersOfFiscalizationOfStorno.ResultOfXMLOperation = CallParameters[3];  
					EndIf; 
				Else

					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(Undefined, OperationData.Electronically, ShouldEscape(OperationData.XMLReceiptData_)));
					CallResult = Await DriverObject.ProcessCheckAsync(
						ConnectionParameters.DeviceID_, 
						ParametersOfFiscalizationOfStorno.Electronically, 
						ParametersOfFiscalizationOfStorno.XMLReceiptData_, 
						ParametersOfFiscalizationOfStorno.KKTReceiptNumber, 
						ParametersOfFiscalizationOfStorno.CREShiftNumber, 
						ParametersOfFiscalizationOfStorno.FiscalFlag, 
						ParametersOfFiscalizationOfStorno.VerificationWebsiteAddress); // Structure
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
					CallParameters = CallResult.Parameters;
					Result = CallResult.Value;
					If Result Then
						ParametersOfFiscalizationOfStorno.XMLReceiptData_ = CallParameters[2];  
						ParametersOfFiscalizationOfStorno.KKTReceiptNumber  = CallParameters[3]; 
						ParametersOfFiscalizationOfStorno.CREShiftNumber      = CallParameters[4]; 
						ParametersOfFiscalizationOfStorno.FiscalFlag  = CallParameters[5]; 
						ParametersOfFiscalizationOfStorno.VerificationWebsiteAddress = CallParameters[6]; 
					EndIf; 
					ParametersOfFiscalizationOfStorno.ReceiptDateAndTime = CommonCELClient.SessionDate();
					
				EndIf;  
			EndIf;
		EndIf; 
		
		If Result Then  
			ExecutionResult = ResultOfOperationOnEquipment(True);  
		Else                 
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		
	Except            
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ProcessCorrectionCheck", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult; 
	
EndFunction

// Prints the text.
//                
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function PrintText(DriverObject, ConnectionParameters, OperationData)
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	Try
		If OperationData.Property("TestReceipts") And OperationData.TestReceipts.Count() > 0 Then
			For Each PrintText_ In OperationData.TestReceipts Do
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PrintTextDocument", ToArray(Undefined,PrintText_));
				CallResult = Await DriverObject.PrintTextDocumentAsync(ConnectionParameters.DeviceID_, PrintText_); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				If Not CallResult.Value Then
					ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
					Return ExecutionResult;
				EndIf;
			EndDo;
		EndIf;
		If OperationData.Property("CopyOfReceipt") And OperationData.CopyOfReceipt.Count() > 0 Then
			For Each Copy In OperationData.CopyOfReceipt Do
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PrintTextDocument", ToArray(Undefined,Copy));
				CallResult = Await DriverObject.PrintTextDocumentAsync(ConnectionParameters.DeviceID_, Copy); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
				If Not CallResult.Value Then
					ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
					Return ExecutionResult;
				EndIf;
			EndDo;
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("PrintTextDocument", DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;  
	
EndFunction

// Carries out collection.
//    
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function Collection_(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter Then
		
		ExecutionResult = Await PrintText(DriverObject, ConnectionParameters, OperationData);
		
	ElsIf ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		
		ReceiptAmount = ?(OperationData.TypeOfCollection = 1, OperationData.ReceiptAmount, - OperationData.ReceiptAmount);
		Try
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CashInOutcome", ToArray(Undefined,OperationData.XMLReceiptData_, ReceiptAmount));
			CallResult = Await DriverObject.CashInOutcomeAsync(ConnectionParameters.DeviceID_, OperationData.XMLReceiptData_, ReceiptAmount); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			If CallResult.Value Then   
				ExecutionResult = ResultOfOperationOnEquipment(True);  
				OperationData.ShiftStatus = 1; // IsOpen
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("CashInOutcome", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	Else
		ExecutionResult = DriverCallError();
	EndIf;
	
	Return ExecutionResult; 
	
EndFunction 

// Performs the closing of the shift.
//    
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function CloseShift(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter Then
		
		ExecutionResult = Await PrintText(DriverObject, ConnectionParameters, OperationData);
		
	ElsIf ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then        
		
		ExecutionResult = ResultOfOperationOnEquipment(False);
		Try  
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CloseShift", OperationData, ", XMLParameters");
			If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
				CallResult = Await DriverObject.CloseShiftAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, OperationData.XMLResult); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Else
				CallResult = Await DriverObject.CloseShiftAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, OperationData.XMLResult, 
					OperationData.CREShiftNumber, OperationData.KKTReceiptNumber); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			EndIf;
		Except    
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("CloseShift", ErrorProcessing.DetailErrorDescription(ErrorInfo()))
		EndTry;
		
		If CallResult.Value Then              
			CallParameters = CallResult.Parameters;
			OperationData.ShiftStatus = 1; // Status 1 - Closed, 2 - Open, 3 - Expired.         
			OperationData.XMLResult = CallParameters[2];
			If CallParameters.Count() > 3 Then
				OperationData.CREShiftNumber = CallParameters[3];    
				OperationData.KKTReceiptNumber  = CallParameters[4];  
			EndIf;
			ExecutionResult.Result = True;    
			ExecutionResult.Insert("DriverNoLongerSupported"    , ConnectionParameters.NoLongerSupported);
			ExecutionResult.Insert("MessageWhenUsing", ConnectionParameters.MessageWhenUsing);
			
			If ConnectionParameters.InterfaceRevision > 4001 Then
				Result = Await SetAsyncsApplicationInformation(DriverObject, ConnectionParameters);   
			EndIf;
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		
	Else
		ExecutionResult = DriverCallError();
	EndIf;    
	
	Return ExecutionResult; 
	
EndFunction 

// Performs the opening of the shift.
//                
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function OpenShift(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter Then
		
		ExecutionResult = Await PrintText(DriverObject,  ConnectionParameters, OperationData);
		
	ElsIf ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then        
		
		CREParameters = "";
		Try          
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetDataKKT");
			CallResult = Await DriverObject.GetCREParametersAsync(ConnectionParameters.DeviceID_, CREParameters); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ExecutionResult = DriverCallError("GetDataKKT", ErrorProcessing.DetailErrorDescription(ErrorInfo()));  
			Return ExecutionResult; 
		EndTry;
		
		If CallResult.Value Then   
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			CREParameters = CallResult.Parameters[1];
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog); 
			Return ExecutionResult; 
		EndIf;
		
		ExecutionResult = ResultOfOperationOnEquipment(False);
		Try  
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "OpenShift", OperationData, ", XMLParameters");
			If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
				CallResult = Await DriverObject.OpenShiftAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, OperationData.XMLResult); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Else
				CallResult = Await DriverObject.OpenShiftAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, OperationData.XMLResult, 
					OperationData.CREShiftNumber, OperationData.KKTReceiptNumber); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			EndIf;
		Except    
			Return DriverCallError("OpenShift", ErrorProcessing.DetailErrorDescription(ErrorInfo()))
		EndTry;
		
		If CallResult.Value Then              
			CallParameters = CallResult.Parameters;
			OperationData.ShiftStatus = 2; // Status 1 - Closed, 2 - Open, 3 - Expired.         
			OperationData.Insert("CREParameters", CREParameters);
			OperationData.XMLResult = CallParameters[2];
			If CallParameters.Count() > 3 Then
				OperationData.CREShiftNumber = CallParameters[3];    
				OperationData.KKTReceiptNumber  = CallParameters[4];  
			EndIf;
			ExecutionResult.Result = True;    
			ExecutionResult.Insert("DriverNoLongerSupported"    , ConnectionParameters.NoLongerSupported);
			ExecutionResult.Insert("MessageWhenUsing", ConnectionParameters.MessageWhenUsing);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		
	Else
		ExecutionResult = DriverCallError();
	EndIf;    
	
	Return ExecutionResult; 
	
EndFunction 

// Performs the opening of a cash drawer.
//      
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function OpenCashDrawer(DriverObject, ConnectionParameters, OperationData)
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "OpenCashDrawer");
		CallResult = Await DriverObject.OpenCashDrawerAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then   
			ExecutionResult = ResultOfOperationOnEquipment(True);   
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("OpenCashDrawer", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;  
	
EndFunction

// Generates a report on the Cur current State of the calculations.
//                  
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function ReportCurrentStatusOfSettlements(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		
		XMLResult = "";
		Try
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReportCurrentStatusOfSettlements", OperationData, ", XMLParameters");
			CallResult = Await DriverObject.ReportCurrentStatusOfSettlementsAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, XMLResult); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			If CallResult.Value Then   
				ExecutionResult = ResultOfOperationOnEquipment(True);   
				OperationData.XMLResult = CallResult.Parameters[2];
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("ReportCurrentStatusOfSettlements", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	Else
		ExecutionResult = DriverCallError();
	EndIf;
	
	Return ExecutionResult; 
	
EndFunction

// Generates a report without blanking.
//
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function PrintReportWithoutClearance(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter Then
		
		ExecutionResult = Await PrintText(DriverObject, ConnectionParameters, OperationData);
		
	ElsIf ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PrintXReport", OperationData, ", XMLParameters");
			CallResult = Await DriverObject.PrintXReportAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			If CallResult.Value Then   
				ExecutionResult = ResultOfOperationOnEquipment(True);  
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("PrintXReport", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	Else
		ExecutionResult = DriverCallError();
	EndIf;
	
	Return ExecutionResult; 
	
EndFunction

// Performs the revocation check.
// 
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function CancellationOfReceipt(DriverObject, ConnectionParameters, OperationData)  
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	ExecutionResult.Insert("CREShiftNumber" , Undefined);
	ExecutionResult.Insert("KKTReceiptNumber"  , Undefined);
	ExecutionResult.Insert("ShiftStatus", 2);
	ExecutionResult.Insert("ReceiptDateAndTime", CommonCELClient.SessionDate());
	Return ExecutionResult;
	
EndFunction

// Receives the parameters of the CCT.
// 
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function CREParameters(DriverObject, ConnectionParameters, OperationData);
	
	If ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetDataKKT");
			CallResult = Await DriverObject.GetCREParametersAsync(ConnectionParameters.DeviceID_, ""); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			Return DriverCallError("GetDataKKT", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;  
	
		If CallResult.Value Then   
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			ExecutionResult.Insert("CCTXMLParameters", CallResult.Parameters[1]);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		
	Else
		ExecutionResult = DriverCallError();
	EndIf;
	
	Return ExecutionResult; 
	
EndFunction

// Performs the opening of the shift.
//
// Parameters:
//  DriverObject - AddInObject 
//  ConnectionParameters - Structure
//  OperationData - Structure - operation data for executing the command
//
Async Function CurrentStatus(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		Return DriverCallError();
	EndIf; 
	
	ExecutionResult = ResultOfOperationOnEquipment(False);
	Try
		If ConnectionParameters.InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetCurrentStatus", OperationData, ", XMLParameters");
			CallResult = Await DriverObject.GetCurrentStatusAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, OperationData.XMLResult); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Else
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetCurrentStatus");
			CallResult = Await DriverObject.GetCurrentStatusAsync(ConnectionParameters.DeviceID_, OperationData.KKTReceiptNumber, OperationData.CREShiftNumber,
				OperationData.ShiftStatus, OperationData.XMLResult); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		EndIf;    
	Except    
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		Return DriverCallError("GetCurrentStatus", ErrorProcessing.DetailErrorDescription(ErrorInfo()))
	EndTry;
		
	If CallResult.Value Then  
		CallParameters = CallResult.Parameters;
		ExecutionResult.Result = True;    
		If ConnectionParameters.InterfaceRevision >= 3000 Then
			OperationData.XMLParameters = CallParameters[1];
			OperationData.XMLResult = CallParameters[2];
		Else
			OperationData.KKTReceiptNumber  = CallParameters[1];
			OperationData.CREShiftNumber = CallParameters[2];
			OperationData.ShiftStatus   = CallParameters[3];
			OperationData.XMLResult  = CallParameters[4];
		EndIf;    
	Else
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		Return ExecutionResult;
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// The procedure performs an operation with a fiscal storage device.
//
Async Function FiscalStorageOperation(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		Return DriverCallError();
	EndIf; 
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "OperationFN", OperationData, ", OperationType, XMLParameters");
		CallResult = Await DriverObject.OperationFNAsync(ConnectionParameters.DeviceID_, OperationData.OperationType, OperationData.XMLParameters); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If Not CallResult.Value Then   
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			Return ExecutionResult;
		EndIf;                            
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("OperationFN", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Try         
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetDataKKT");
		CallResult = Await DriverObject.GetCREParametersAsync(ConnectionParameters.DeviceID_, ""); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then   
			ExecutionResult = ResultOfOperationOnEquipment(True); 
			OperationData.Insert("CREParameters", CallResult.Parameters[1]);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;                            
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("GetDataKKT", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// Function print a copy of the receipt.
//
Async Function PrintCheckCopy(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
		Return DriverCallError();        
	EndIf;
	
	If OperationData.Property("Hardware") And OperationData.Hardware Then
		
		ReceiptNumber = 0;
		If OperationData <> Undefined And OperationData.Property("ReceiptNumber") Then
			ReceiptNumber = OperationData.ReceiptNumber;
		EndIf;
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PrintCheckCopy", ToArray(Undefined, ReceiptNumber));
			CallResult = Await DriverObject.PrintCheckCopyAsync(ConnectionParameters.DeviceID_, ReceiptNumber); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			If CallResult.Value Then   
				ExecutionResult = ResultOfOperationOnEquipment(True); 
				ExecutionResult.Insert("ReceiptNumber", ReceiptNumber);
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("PrintCheckCopy", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	Else                
		ExecutionResult = Await PrintText(DriverObject, ConnectionParameters, OperationData); 
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// The function opens the KM registration session.
//
Async Function OpenSessionRegistrationKM(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'");
		LogError_(ConnectionParameters, "OpenSessionRegistrationKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
		
	EndIf;
	
	SessionID = EquipmentManagerClient.MarkingCodeVerificationSession(ConnectionParameters.DeviceID);
	If Not IsBlankString(SessionID) Then  
		
		ErrorDescription = NStr("vi = 'Đã mở phiên kiểm tra mã dán nhãn.';
								|ru = 'Сессия проверки кодов маркировки уже открыта.';
								|en = 'Session of marking code check is opened.'; fa = 'Session of marking code check is opened.';
								|it = 'La sessione di verifica dei codici di marcatura è già aperta.';
								|pl = 'Sesja sprawdzenia kodów oznakowania jest już otwarta.';
								|tr = 'İşaretleme kodları kontrol oturumu açık.'");
		LogError_(ConnectionParameters, "OpenSessionRegistrationKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
		
	EndIf;
	
	Try
		
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "OpenSessionRegistrationKM");
		CallResult = Await DriverObject.OpenSessionRegistrationKMAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		
		If CallResult.Value Then
			SessionID = String(New UUID);
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			ExecutionResult.Insert("SessionID", SessionID);
			EquipmentManagerClient.EstablishMarkingCodeVerificationSession(ConnectionParameters.DeviceID, SessionID);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		
	Except
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("OpenSessionRegistrationKM", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function closes the KM registration session.
//
Async Function CloseSessionRegistrationKM(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'"); 
		LogError_(ConnectionParameters, "CloseSessionRegistrationKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
		
	EndIf;
	
	SessionID = EquipmentManagerClient.MarkingCodeVerificationSession(ConnectionParameters.DeviceID);
	If IsBlankString(SessionID) Then  
		ExecutionResult = ResultOfOperationOnEquipment(True);
		Return ExecutionResult;
	EndIf;
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CloseSessionRegistrationKM");
		CallResult = Await DriverObject.CloseSessionRegistrationKMAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			EquipmentManagerClient.EstablishMarkingCodeVerificationSession(ConnectionParameters.DeviceID);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("CloseSessionRegistrationKM", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;  
	
EndFunction

// Request KM.
//
Async Function RequestKM(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'");
		LogError_(ConnectionParameters, "ConfirmKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	
	CurrentStatus = EquipmentManagerClient.CheckingMarkingCode(ConnectionParameters.DeviceID);
	SessionID  = CurrentStatus.SessionID;
	QueryID = CurrentStatus.QueryID;
	
	// If there is no open session, we open it automatically. 
	If IsBlankString(SessionID) Then  
		TimeExecutionResult = Await OpenSessionRegistrationKM(DriverObject, ConnectionParameters, OperationData);
		If Not TimeExecutionResult.Result Then
			Return TimeExecutionResult;
		Else
			SessionID = TimeExecutionResult.SessionID;
		EndIf;
	EndIf;
	
	// If there is a current KM check      
	If Not IsBlankString(QueryID) Then
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ConfirmKM", ToArray(Undefined, QueryID, 0));
			CallResult = Await DriverObject.ConfirmKMAsync(ConnectionParameters.DeviceID_, QueryID, 0); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		
			EquipmentManagerClient.InstallMarkingCodeVerification(ConnectionParameters.DeviceID);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("ConfirmKM", ErrorProcessing.DetailErrorDescription(ErrorInfo())); 
			Return ExecutionResult;
		EndTry;
		
	EndIf;
	
	QueryID = OperationData.QueryID;
	Try
		If Not OperationData.Property("XMLParameters") Then
			Raise NStr("vi = 'Chưa thiết lập các tham số của yêu cầu XML';
						|ru = 'Не сформированы параметры запроса XML';
						|en = 'Parameters for XML query are not generated'; fa = 'Parameters for XML query are not generated';
						|it = 'Parameters for XML query are not generated';
						|pl = 'Parameters for XML query are not generated';
						|tr = 'XML sorgu parametreleri oluşturulmadı'");
		EndIf;
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "RequestKM", ToArray(Undefined, ShouldEscape(OperationData.XMLParameters)));
		CallResult = Await DriverObject.RequestKMAsync(ConnectionParameters.DeviceID_, OperationData.XMLParameters, ""); // Structure   
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then  
			
			CallParameters = CallResult.Parameters;     
			ResultOfXMLOperation = CallParameters[2];
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			ExecutionResult.Insert("SessionID" , SessionID);
			ExecutionResult.Insert("QueryID", QueryID);
			ExecutionResult.Insert("XMLRequest"   , OperationData.XMLParameters);
			ExecutionResult.Insert("XMLResult", ResultOfXMLOperation);
			EquipmentManagerClient.SetResultOfCheckingMarkingCode(ConnectionParameters.DeviceID, 
				SessionID, OperationData, ExecutionResult, QueryID);
				
			InterimResult = EquipmentManagerClient.Peripherals().InterimResult;
			IntermediateResultData = New Structure();
			IntermediateResultData.Insert("OperationData", OperationData);
			IntermediateResultData.Insert("ExecutionResult", ExecutionResult);
			InterimResult.Insert("RequestKM", IntermediateResultData);
				
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("RequestKM", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// KM request without waiting for a response.
//
Async Function KMRequestWithoutWaitingForResponse(DriverObject, ConnectionParameters, OperationData)
	
	ExecutionResult = Await RequestKM(DriverObject, ConnectionParameters, OperationData);
	
	Query_Status = 0;
	ResultOfXMLOperation = "";
	If ExecutionResult.Result Then
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetProcessingKMResult");
			CallResult = Await DriverObject.GetKMQueryResultsAsync(ConnectionParameters.DeviceID_, ResultOfXMLOperation, Query_Status); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			If CallResult.Value Then                             
				ResultOfXMLOperation = CallResult.Parameters[1];
				Query_Status        = CallResult.Parameters[2];
				OperationData.Insert("XMLResult", ResultOfXMLOperation);
				OperationData.Insert("ResultStatusCode", Query_Status);
				ExecutionResult.Result = True;
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("GetProcessingKMResult", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry; 
		
		If CallResult.Value Then
			OperationData.Insert("Disposal", True);  
			ExecutionResult = Await ConfirmKM(DriverObject, ConnectionParameters, OperationData);
		EndIf;
		
	EndIf;
	
	If ExecutionResult.Result And (Query_Status = 0 Or Query_Status = 2) Then
		InterimResult = EquipmentManagerClient.Peripherals().InterimResult;
		ExecutionResult.Insert("RequestKM", InterimResult.Get("RequestKM"));
		InterimResult.Delete("RequestKM");
	ElsIf Not ExecutionResult.Result Then
		InterimResult = EquipmentManagerClient.Peripherals().InterimResult;
		ExecutionResult.Insert("RequestKM", InterimResult.Get("RequestKM"));
		InterimResult.Delete("RequestKM");
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// Confirm the results of the KM request.
//
Async Function ConfirmKM(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'"); 
		LogError_(ConnectionParameters, "ConfirmKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	
	QueryID = ?(OperationData.Property("QueryID"), OperationData.QueryID, "");
	Disposal = ?(OperationData.Property("Disposal"), OperationData.Disposal, True);
	
	If IsBlankString(QueryID) Then
		ErrorDescription = NStr("vi = 'Chưa chỉ ra tên định danh truy vấn mã dán nhãn.';
								|ru = 'Идентификатор запроса КМ не указан.';
								|en = 'MC request ID is not specified.'; fa = 'MC request ID is not specified.';
								|it = 'L''ID richiesta del Codice di Marcatura non è indicato.';
								|pl = 'Nie podano identyfikatora zapytania kodu oznakowania.';
								|tr = 'KM sorgu kimliği belirtilmemiş.'");
		LogError_(ConnectionParameters, "ConfirmKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	
	Try
		
		TypeOfConfirmation = ?(Disposal, 0, 1);
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ConfirmKM", ToArray(Undefined, QueryID, TypeOfConfirmation));
		CallResult = Await DriverObject.ConfirmKMAsync(ConnectionParameters.DeviceID_, QueryID, TypeOfConfirmation); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		
		If CallResult.Value Then   
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			ExecutionResult.Insert("QueryID", QueryID);
			EquipmentManagerClient.InstallMarkingCodeVerification(ConnectionParameters.DeviceID);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ConfirmKM", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// Get the results of the KM query.
//
Async Function KMQueryResults(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'");
		LogError_(ConnectionParameters, "GetProcessingKMResult", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		
		InterimResult = EquipmentManagerClient.Peripherals().InterimResult;
		ExecutionResult.Insert("RequestKM", InterimResult.Get("RequestKM"));
		InterimResult.Delete("RequestKM");
		
		Return ExecutionResult;
	EndIf;
	
	Query_Status = 0;
	ResultOfXMLOperation = "";
	Try
		
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetProcessingKMResult");
		CallResult = Await DriverObject.GetKMQueryResultsAsync(ConnectionParameters.DeviceID_, ResultOfXMLOperation, Query_Status); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		
		If CallResult.Value Then                   
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			ResultOfXMLOperation = CallResult.Parameters[1];
			Query_Status = CallResult.Parameters[2];
			OperationData.Insert("XMLResult", ResultOfXMLOperation);
			OperationData.Insert("ResultStatusCode", Query_Status);
			
		Else
			OperationData.Insert("XMLResult", "");
			OperationData.Insert("ResultStatusCode", 0);
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("GetProcessingKMResult", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If ExecutionResult.Result And (Query_Status = 0 Or Query_Status = 2) Then
		InterimResult = EquipmentManagerClient.Peripherals().InterimResult;
		ExecutionResult.Insert("RequestKM", InterimResult.Get("RequestKM"));
		InterimResult.Delete("RequestKM");
	ElsIf Not ExecutionResult.Result Then
		InterimResult = EquipmentManagerClient.Peripherals().InterimResult;
		ExecutionResult.Insert("RequestKM", InterimResult.Get("RequestKM"));
		InterimResult.Delete("RequestKM");
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// KM check.
//
Async Function KMCheck(DriverObject, ConnectionParameters, OperationData)
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		ErrorDescription = StrTemplate(
			NStr("vi = 'Driver %1 (phiên bản %2) (pb %3) không hỗ trợ thao tác kiểm tra mã dán nhãn. Để làm việc chính xác, cần cập nhật driver.';
				|ru = 'Драйвер %1 (версия %2) (рев.%3) не поддерживает операцию проверки кода маркировки. Для корректной работы требуется обновить драйвер.';
				|en = 'The %1 driver (version %2) (rev. %3) does not support the marking code check. Update the driver.'; fa = 'The %1 driver (version %2) (rev. %3) does not support the marking code check. Update the driver.';
				|it = 'Драйвер %1 (версия %2) (рев.%3) не поддерживает операцию проверки кода маркировки. Для корректной работы требуется обновить драйвер.';
				|pl = 'The %1 driver (version %2) (rev. %3) does not support the marking code check. Update the driver.';
				|tr = '%1 sürücüsü (sürüm %2) (rev.%3) işaretleme kodu kontrol işlemini desteklemiyor. Doğru çalışma için sürücünün güncellenmesi gerekmektedir.'"),
			ConnectionParameters.Description,
			ConnectionParameters.DriverVersion,
			ConnectionParameters.InterfaceRevision);
		LogError_(ConnectionParameters, "RequestKM", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	ExecutionResult.Insert("TimeConsumingOperation", "KMCheck");
	Return ExecutionResult;
	
EndFunction

// The function performs the fiscalization of the check package.
//
Async Function FiscalizationOfReceiptByPackage(DriverObject, ConnectionParameters, OperationData);
	
	If Not ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Or ConnectionParameters.InterfaceRevision < 3004 Then
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ giao dịch.';
								|ru = 'Драйвер не поддерживает операцию.';
								|en = 'The operation is not supported by the driver.'; fa = 'The operation is not supported by the driver.';
								|it = 'Il driver non supporta l''operazione.';
								|pl = 'Sterownik nie obsługuje operacji.';
								|tr = 'Sürücü bu işlemi desteklemiyor.'");
		LogError_(ConnectionParameters, "ProcessCheck", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		Return ExecutionResult;
	EndIf;
	
	Try
		
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ProcessCheck", ToArray(Undefined, False, OperationData.XMLReceiptData_));
		CallResult = Await DriverObject.ProcessCheckAsync(ConnectionParameters.DeviceID_, False, OperationData.XMLReceiptData_, OperationData.ResultOfXMLOperation);; // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ProcessCheck", ErrorProcessing.DetailErrorDescription(ErrorInfo())); 
		Return ExecutionResult;
	EndTry;
	
	If CallResult.Value Then              
		ExecutionResult = ResultOfOperationOnEquipment(True);
	Else
		ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
	EndIf;    
	
	Return ExecutionResult;
	
EndFunction 

#EndRegion

// ++ Non-mobile application
// -- Non-mobile application 

#Region POSTerminals   

Function ResultOfAcquiringOperation(Result, ErrorDescription, ConnectionParameters)
	
	ExecutionResult = ResultOfOperationOnEquipment(Result, ErrorDescription, ConnectionParameters.DeviceID);  
	
	ExecutionResult.Insert("PaymentKindOnTerminal");
	ExecutionResult.Insert("TypeOfPaymentAtTerminalCode", 0);
	ExecutionResult.Insert("MerchantSNumber");
	ExecutionResult.Insert("CardNumber");
	ExecutionResult.Insert("POSTerminalReceiptNumber");
	ExecutionResult.Insert("ReferenceNumber");
	ExecutionResult.Insert("AuthorizationCode");
	ExecutionResult.Insert("OperationStatus");      
	ExecutionResult.Insert("QrCardAttributes");      
	ExecutionResult.Insert("CartID");

	ExecutionResult.Insert("TransactionAmount");
	ExecutionResult.Insert("AmountOfElectronicCertificate");
	ExecutionResult.Insert("AmountOfOwnFunds");
	ExecutionResult.Insert("SlipReceiptText"); 
	
	ExecutionResult.Insert("HashCardNumber"); 
	ExecutionResult.Insert("LinkToPaymentAccount");
	ExecutionResult.Insert("DateTime");
	ExecutionResult.Insert("EndCode");
	ExecutionResult.Insert("PaymentSystemId");
	ExecutionResult.Insert("BankTransactionID");
	
	ExecutionResult.Insert("TerminalId"    , ConnectionParameters.TerminalId); 
	ExecutionResult.Insert("AcquirerBankID", ConnectionParameters.AcquirerBankID);
	
	Return ExecutionResult;
	
EndFunction

// The procedure returns the parameters of the terminal.
//
Async Function TerminalParameters(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.InterfaceRevision >= 3004 Then
		Try
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "TerminalParamters");
			CallResult = Await DriverObject.TerminalParametersAsync(ConnectionParameters.DeviceID_, ""); // Structure  
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			ResultOfXMLOperation = CallResult.Parameters[1];
			
			If CallResult.Value Then
				
				TerminalParameters = CommonCELClient.ReadRootXMLElement(ResultOfXMLOperation);
				If TerminalParameters.Property("TerminalID") And Not IsBlankString(TerminalParameters.TerminalID) Then
					ConnectionParameters.TerminalId = TerminalParameters.TerminalID;
				EndIf;                          
				If TerminalParameters.Property("AcquiringBankIdentifier") And Not IsBlankString(TerminalParameters.AcquiringBankIdentifier) Then
					ConnectionParameters.AcquirerBankID = TerminalParameters.AcquiringBankIdentifier;
				EndIf;                          
				ConnectionParameters.PrintSlipOnTerminal = TerminalParameters.Property("PrintSlipOnTerminal") And Upper(TerminalParameters.PrintSlipOnTerminal) = "TRUE"; 
				ConnectionParameters.ShortSlipChecks = TerminalParameters.Property("ShortSlip") And Upper(TerminalParameters.ShortSlip) = "TRUE"; 
				ConnectionParameters.CashWithdrawals = TerminalParameters.Property("CashWithdrawal") And Upper(TerminalParameters.CashWithdrawal) = "TRUE"; 
				ConnectionParameters.PaymentByElectronicCertificates = TerminalParameters.Property("ElectronicCertificates") And Upper(TerminalParameters.ElectronicCertificates) = "TRUE";
				ConnectionParameters.PartialCancellation = TerminalParameters.Property("PartialCancellation") And Upper(TerminalParameters.PartialCancellation) = "TRUE";
				ConnectionParameters.ConsumerPresentedQR = TerminalParameters.Property("ConsumerPresentedQR") And Upper(TerminalParameters.ConsumerPresentedQR) = "TRUE";
				ConnectionParameters.PurchaseWithCreditCard = TerminalParameters.Property("PurchaseWithEnrollment") And Upper(TerminalParameters.PurchaseWithEnrollment) = "TRUE";
				ConnectionParameters.ListOfCardTransactions = TerminalParameters.Property("ListCardTransactions") And Upper(TerminalParameters.ListCardTransactions) = "TRUE";
				ExecutionResult = ResultOfOperationOnEquipment(True);
			EndIf
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("TerminalParameters", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else     
		Try
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PrintSlipOnTerminal");
			CallResult = Await DriverObject.PrintSlipOnTerminalAsync(); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
			ConnectionParameters.PrintSlipOnTerminal = CallResult.Value;
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Except          
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("PrintSlipOnTerminal", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// This function retrieves map parameters.
//
Async Function MapParameters(DriverObject, ConnectionParameters, OperationData)
	
	InterfaceRevision = ConnectionParameters.InterfaceRevision;
	
	If InterfaceRevision > 3004 Then
		FromLastOperation = False;
		CardNumber = "";
		HashCardNumber = "";
		QrCardAttributes = "";
		LinkToPaymentAccount = "";
		CardType  = "";
		OwnMap = 0;
		Try                  
			If InterfaceRevision >= 4000 Then    
				QrCardAttributes = ?(OperationData.Property("QrCardAttributes"), OperationData.QrCardAttributes, "");
				If Not IsBlankString(QrCardAttributes) And Not ConnectionParameters.ConsumerPresentedQR Then
					ErrorDescription = NStr("vi = 'Driver không hỗ trợ Consumer-Presented QR.';
											|ru = 'Consumer-Presented QR не поддерживается драйвером.';
											|en = 'The driver does not support Consumer-Presented QR.'; fa = 'The driver does not support Consumer-Presented QR.';
											|it = 'Consumer-Presented QR не поддерживается драйвером.';
											|pl = 'The driver does not support Consumer-Presented QR.';
											|tr = 'Consumer-Presented QR sürücü tarafından desteklenmiyor.'");
					LogError_(ConnectionParameters, "GetCardParametrs", ErrorDescription);
					ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
					Return ExecutionResult;   
				EndIf;
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetCardParametrs", ToArray(Undefined, QrCardAttributes, FromLastOperation));
				CallResult = Await DriverObject.GetMapParametersAsync(ConnectionParameters.DeviceID_, QrCardAttributes, FromLastOperation, CardNumber, HashCardNumber, LinkToPaymentAccount, CardType, OwnMap); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			ElsIf InterfaceRevision >= 3007 Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetCardParametrs", ToArray(Undefined,FromLastOperation));
				CallResult = Await DriverObject.GetMapParametersAsync(ConnectionParameters.DeviceID_, FromLastOperation, CardNumber, HashCardNumber, LinkToPaymentAccount, CardType, OwnMap); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			Else
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetCardParametrs", ToArray(Undefined,FromLastOperation));
				CallResult = Await DriverObject.GetMapParametersAsync(ConnectionParameters.DeviceID_, FromLastOperation, CardNumber, HashCardNumber, CardType, OwnMap); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult, ", , CardNumber, HashCardNumber, CardType, OwnMap");
			EndIf;
			If CallResult.Value Then     
				ExecutionResult = ResultOfOperationOnEquipment(True);  
				If InterfaceRevision >= 4000 Then   
					QrCardAttributes = CallResult.Parameters[1];
					CardNumber = CallResult.Parameters[3];
					HashCardNumber = CallResult.Parameters[4];
					LinkToPaymentAccount = CallResult.Parameters[5];
					CardType = CallResult.Parameters[6];
					OwnMap = CallResult.Parameters[7];
				ElsIf InterfaceRevision >= 3007 Then 
					CardNumber = CallResult.Parameters[2];
					HashCardNumber = CallResult.Parameters[3];
					LinkToPaymentAccount = CallResult.Parameters[4];
					CardType = CallResult.Parameters[5];
					OwnMap = CallResult.Parameters[6];
				Else
					CardNumber = CallResult.Parameters[2];
					HashCardNumber = CallResult.Parameters[3];
					CardType = CallResult.Parameters[4];
					OwnMap = CallResult.Parameters[5];
				EndIf;
				ExecutionResult.Insert("CardNumber"   , CardNumber);
				ExecutionResult.Insert("HashCardNumber", HashCardNumber);
				ExecutionResult.Insert("LinkToPaymentAccount", LinkToPaymentAccount);
				ExecutionResult.Insert("QrCardAttributes"     , QrCardAttributes);
				ExecutionResult.Insert("CardType"     , CardType);
				ExecutionResult.Insert("OwnMap"    , OwnMap);
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except      
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("GetCardParametrs", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else     
		ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
								|ru = 'Терминал не поддерживает данную операцию.';
								|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
								|it = 'Il terminale non supporta questa operazione.';
								|pl = 'Terminal nie obsługuje niniejszej operacji.';
								|tr = 'Cihaz, bu işlemi desteklemiyor.'");
		LogError_(ConnectionParameters, "GetCardParametrs", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// The procedure returns card operations.
//
Async Function TransactionsByCards(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.InterfaceRevision < 4000 Then    
		
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
								|ru = 'Команда не поддерживается драйвером.';
								|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
								|it = 'Il comando non è supportato dal driver.';
								|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
								|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
		LogError_(ConnectionParameters, "GetOperationByCards", ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
		Return ExecutionResult;
		
	Else
		
		If Not ConnectionParameters.ListOfCardTransactions Then
			ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
									|ru = 'Терминал не поддерживает данную операцию.';
									|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
									|it = 'Il terminale non supporta questa operazione.';
									|pl = 'Terminal nie obsługuje niniejszej operacji.';
									|tr = 'Cihaz, bu işlemi desteklemiyor.'"); 
			LogError_(ConnectionParameters, "GetOperationByCards", ErrorDescription);
			ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
			Return ExecutionResult;
		EndIf;
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetOperationByCards");
			CallResult = Await DriverObject.GetTransactionsByCardsAsync(ConnectionParameters.DeviceID_, ""); // Structure  
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			If CallResult.Value Then        
				ResultOfXMLOperation = CallResult.Parameters[1];
				ExecutionResult = ResultOfOperationOnEquipment(True);   
				ExecutionResult.Insert("ResultOfXMLOperation", ResultOfXMLOperation);
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("GetCardTransactions", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// The function performs of operation on ET.
//
Async Function AcquiringTransaction(DriverObject, ConnectionParameters, OperationData, Command)
	
	InterfaceRevision = ConnectionParameters.InterfaceRevision;
	
	QrCardAttributes = ?(OperationData.QrCardAttributes <> Undefined, OperationData.QrCardAttributes, "");
	MerchantSNumber  = ?(OperationData.MerchantSNumber <> Undefined, OperationData.MerchantSNumber, 0);
	CardNumber     = ?(OperationData.CardNumber <> Undefined, OperationData.CardNumber, "");
	ReceiptNumber      = ?(OperationData.ReceiptNumber <> Undefined, OperationData.ReceiptNumber, "");
	ReferenceNumber = ?(OperationData.ReferenceNumber <> Undefined, OperationData.ReferenceNumber, "");
	AuthorizationCode = ?(OperationData.AuthorizationCode <> Undefined, OperationData.AuthorizationCode, "");
	TransactionAmount  = ?(OperationData.TransactionAmount <> Undefined, OperationData.TransactionAmount, 0);
	AmountOfCash  = ?(OperationData.AmountOfCash <> Undefined, OperationData.AmountOfCash, 0);
	AmountOfOriginalTransaction = ?(OperationData.AmountOfOriginalTransaction <> Undefined, OperationData.AmountOfOriginalTransaction, 0);
	SlipReceiptText  = "";
	
	Try        
		If InterfaceRevision >= 4000 Then
			
			If Command = "AuthorizeSales" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayByPaymentCard", 
					ToArray(Undefined,MerchantSNumber,QrCardAttributes,TransactionAmount,CardNumber,ReceiptNumber));
				CallResult = Await DriverObject.PayByPaymentCardAsync(ConnectionParameters.DeviceID_, MerchantSNumber, QrCardAttributes, TransactionAmount, 
					CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			ElsIf Command = "AuthorizeRefund" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReturnPaymentByPaymentCard", 
					ToArray(Undefined,MerchantSNumber,QrCardAttributes,TransactionAmount,CardNumber,ReceiptNumber,ReferenceNumber,AuthorizationCode));
				CallResult = Await DriverObject.ReturnPaymentByPaymentCardAsync(ConnectionParameters.DeviceID_, MerchantSNumber, QrCardAttributes, TransactionAmount, 
					CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
			ElsIf Command = "AuthorizeVoid" Then
				
				If AmountOfOriginalTransaction > 0 And Not ConnectionParameters.PartialCancellation Then
					ErrorDescription = NStr("vi = 'Driver không hỗ trợ hủy một phần.';
											|ru = 'Частичная отмена не поддерживается драйвером.';
											|en = 'The driver does not support partial cancellation.'; fa = 'The driver does not support partial cancellation.';
											|it = 'Частичная отмена не поддерживается драйвером.';
											|pl = 'The driver does not support partial cancellation.';
											|tr = 'Kısmi iptal, sürücü tarafından desteklenmiyor.'");
					LogError_(ConnectionParameters, "CancelPaymentByPaymentCard", ErrorDescription);
					ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
					Return ExecutionResult;
				Else
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReturnPaymentByPaymentCard", 
						ToArray(Undefined,MerchantSNumber,QrCardAttributes,TransactionAmount,CardNumber,ReceiptNumber,ReferenceNumber,AuthorizationCode));
					CallResult = Await DriverObject.CancelPaymentByPaymentCardAsync(ConnectionParameters.DeviceID_, MerchantSNumber, QrCardAttributes, TransactionAmount,
						AmountOfOriginalTransaction, CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure        
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				EndIf;
					
			ElsIf Command = "PayByPaymentCardWithCashWithdrawal" Then
				
				If ConnectionParameters.CashWithdrawals Then
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayByPaymentCardWithCashWithdrawal", 
						ToArray(Undefined,MerchantSNumber,QrCardAttributes,TransactionAmount,AmountOfCash));
					CallResult = Await DriverObject.PayByPaymentCardWithCashWithdrawalAsync(ConnectionParameters.DeviceID_, MerchantSNumber, QrCardAttributes, TransactionAmount, 
						AmountOfCash, CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				Else
					ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
											|ru = 'Терминал не поддерживает данную операцию.';
											|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
											|it = 'Il terminale non supporta questa operazione.';
											|pl = 'Terminal nie obsługuje niniejszej operacji.';
											|tr = 'Cihaz, bu işlemi desteklemiyor.'");
					LogError_(ConnectionParameters, "PayByPaymentCardWithCashWithdrawal", ErrorDescription);
					ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
					Return ExecutionResult;
				EndIf;
				
			Else
				ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
										|ru = 'Команда не поддерживается драйвером.';
										|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
										|it = 'Il comando non è supportato dal driver.';
										|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
										|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
				LogError_(ConnectionParameters, Command, ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			EndIf;
			
		ElsIf InterfaceRevision >= 3005 Then
			
			If Command = "AuthorizeSales" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayByPaymentCard", ToArray(Undefined, MerchantSNumber, TransactionAmount, CardNumber, ReceiptNumber));
				CallResult = Await DriverObject.PayByPaymentCardAsync(ConnectionParameters.DeviceID_, MerchantSNumber, TransactionAmount, 
					CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
					
			ElsIf Command = "AuthorizeRefund" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReturnPaymentByPaymentCard", 
					ToArray(Undefined,MerchantSNumber,TransactionAmount,CardNumber,ReceiptNumber,ReferenceNumber,AuthorizationCode));
				CallResult = Await DriverObject.ReturnPaymentByPaymentCardAsync(ConnectionParameters.DeviceID_, MerchantSNumber, TransactionAmount, 
					CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			ElsIf Command = "AuthorizeVoid" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CancelPaymentByPaymentCard", 
					ToArray(Undefined,MerchantSNumber,TransactionAmount,CardNumber,ReceiptNumber,ReferenceNumber,AuthorizationCode));
				CallResult = Await DriverObject.CancelPaymentByPaymentCardAsync(ConnectionParameters.DeviceID_, MerchantSNumber, TransactionAmount, 
					CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			ElsIf InterfaceRevision >= 3006 And Command = "PayByPaymentCardWithCashWithdrawal" Then
				
				If ConnectionParameters.CashWithdrawals Then
					EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayByPaymentCardWithCashWithdrawal", 
						ToArray(Undefined,MerchantSNumber,TransactionAmount,AmountOfCash));
					CallResult = Await DriverObject.PayByPaymentCardWithCashWithdrawalAsync(ConnectionParameters.DeviceID_, MerchantSNumber, TransactionAmount, 
						AmountOfCash, CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
					CompleteRecordingOfOperationLog(EntryOfLog, CallResult, ", , , CardNumber, ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText");
				Else
					ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
											|ru = 'Терминал не поддерживает данную операцию.';
											|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
											|it = 'Il terminale non supporta questa operazione.';
											|pl = 'Terminal nie obsługuje niniejszej operacji.';
											|tr = 'Cihaz, bu işlemi desteklemiyor.'");
					LogError_(ConnectionParameters, "PayByPaymentCardWithCashWithdrawal", ErrorDescription);
					ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
					Return ExecutionResult;
				EndIf;
				
			Else
				ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
										|ru = 'Команда не поддерживается драйвером.';
										|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
										|it = 'Il comando non è supportato dal driver.';
										|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
										|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
				LogError_(ConnectionParameters, Command, ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			EndIf;
			
		Else
			
			If Command = "AuthorizeSales" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayByPaymentCard", ToArray(Undefined, CardNumber, TransactionAmount, ReceiptNumber));
				CallResult = Await DriverObject.PayByPaymentCardAsync(ConnectionParameters.DeviceID_, CardNumber, TransactionAmount, 
					ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			ElsIf Command = "AuthorizeRefund" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReturnPaymentByPaymentCard", 
					ToArray(Undefined, CardNumber,TransactionAmount,ReceiptNumber,ReferenceNumber,AuthorizationCode));
				CallResult = Await DriverObject.ReturnPaymentByPaymentCardAsync(ConnectionParameters.DeviceID_, CardNumber, TransactionAmount, 
					ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			ElsIf Command = "AuthorizeVoid" Then
				
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CancelPaymentByPaymentCard", 
					ToArray(Undefined,CardNumber,TransactionAmount,ReceiptNumber,ReferenceNumber,AuthorizationCode));
				CallResult = Await DriverObject.CancelPaymentByPaymentCardAsync(ConnectionParameters.DeviceID_, CardNumber, TransactionAmount, 
					ReceiptNumber, ReferenceNumber, AuthorizationCode, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
				
			Else
				ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
										|ru = 'Команда не поддерживается драйвером.';
										|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
										|it = 'Il comando non è supportato dal driver.';
										|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
										|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
				LogError_(ConnectionParameters, Command, ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;    
			EndIf;
			
		EndIf;
			
		If CallResult.Value Then        
			If InterfaceRevision >= 4000 Then      
				MerchantSNumber = CallResult.Parameters[1]; 
				QrCardAttributes =  CallResult.Parameters[2];
				TransactionAmount = CallResult.Parameters[3];         
				If Command = "AuthorizeVoid" Then    
					CardNumber = CallResult.Parameters[5]; 
					ReceiptNumber = CallResult.Parameters[6]; 
					ReferenceNumber = CallResult.Parameters[7]; 
					AuthorizationCode = CallResult.Parameters[8]; 
					SlipReceiptText = CallResult.Parameters[9];  
				ElsIf Command = "PayByPaymentCardWithCashWithdrawal" Then    
					AmountOfCash = CallResult.Parameters[4];
					CardNumber = CallResult.Parameters[5]; 
					ReceiptNumber = CallResult.Parameters[6]; 
					ReferenceNumber = CallResult.Parameters[7]; 
					AuthorizationCode = CallResult.Parameters[8]; 
					SlipReceiptText = CallResult.Parameters[9];   
				Else
					CardNumber = CallResult.Parameters[4]; 
					ReceiptNumber = CallResult.Parameters[5]; 
					ReferenceNumber = CallResult.Parameters[6]; 
					AuthorizationCode = CallResult.Parameters[7]; 
					SlipReceiptText = CallResult.Parameters[8];   
				EndIf;
			ElsIf InterfaceRevision >= 3005 Then       
				MerchantSNumber = CallResult.Parameters[1]; 
				TransactionAmount = CallResult.Parameters[2]; 
				If Command = "PayByPaymentCardWithCashWithdrawal" Then   
					AmountOfCash = CallResult.Parameters[3];
					CardNumber = CallResult.Parameters[4]; 
					ReceiptNumber = CallResult.Parameters[5]; 
					ReferenceNumber = CallResult.Parameters[6]; 
					AuthorizationCode = CallResult.Parameters[7]; 
					SlipReceiptText = CallResult.Parameters[8];
				Else
					CardNumber = CallResult.Parameters[3]; 
					ReceiptNumber = CallResult.Parameters[4]; 
					ReferenceNumber = CallResult.Parameters[5]; 
					AuthorizationCode = CallResult.Parameters[6]; 
					SlipReceiptText = CallResult.Parameters[7];
				EndIf;
			Else   
				CardNumber = CallResult.Parameters[1];
				TransactionAmount = CallResult.Parameters[2];
				ReceiptNumber = CallResult.Parameters[3];
				ReferenceNumber = CallResult.Parameters[4];
				AuthorizationCode = CallResult.Parameters[5];
				SlipReceiptText = CallResult.Parameters[6];
			EndIf;  
			ExecutionResult = ResultOfAcquiringOperation(True, Undefined, ConnectionParameters);
			ExecutionResult.MerchantSNumber = MerchantSNumber;
			ExecutionResult.CardNumber    = CardNumber;
			ExecutionResult.POSTerminalReceiptNumber   = ReceiptNumber;
			ExecutionResult.ReferenceNumber = ReferenceNumber;
			ExecutionResult.AuthorizationCode = AuthorizationCode;
			ExecutionResult.TransactionAmount  = TransactionAmount; 
			ExecutionResult.QrCardAttributes = QrCardAttributes;      
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;   
		ExecutionResult.Insert("SlipReceiptText" , SlipReceiptText);
		Peripherals = EquipmentManagerClient.Peripherals();
		Peripherals.LastSlipCheck = SlipReceiptText; 
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError(Command, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function performs of operation on ET in XML mode.
//
Async Function AcquiringOperationOfXML(DriverObject, ConnectionParameters, OperationData, Command)
	
	If ConnectionParameters.InterfaceRevision < 4003 Then      
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
								|ru = 'Команда не поддерживается драйвером.';
								|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
								|it = 'Команда не поддерживается драйвером.';
								|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
								|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
		Return ExecutionResult;   
	EndIf; 
		
	QrCardAttributes = ?(OperationData.QrCardAttributes <> Undefined, OperationData.QrCardAttributes, ""); 
	TransactionAmount  = ?(OperationData.TransactionAmount <> Undefined, OperationData.TransactionAmount, 0);  
	MerchantSNumber  = ?(OperationData.MerchantSNumber <> Undefined, OperationData.MerchantSNumber, 0); 
	AmountOfOriginalTransaction = ?(OperationData.AmountOfOriginalTransaction <> Undefined, OperationData.AmountOfOriginalTransaction, 0);
	IncomingParametersXML = ?(OperationData.Property("IncomingParametersXML"), OperationData.IncomingParametersXML, "");
	SlipReceiptText  = "";          
	OutgoingXMLParameters = ""; 
		
	Try        
		If Command = "AuthorizeSales" Then
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Pay", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.PayAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		ElsIf Command = "AuthorizeRefund" Then
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReturnPayment", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.ReturnPaymentAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		ElsIf Command = "AuthorizeVoid" Then
			
			If AmountOfOriginalTransaction > 0 And Not ConnectionParameters.PartialCancellation Then
				ErrorDescription = NStr("vi = 'Driver không hỗ trợ hủy một phần.';
										|ru = 'Частичная отмена не поддерживается драйвером.';
										|en = 'The driver does not support partial cancellation.'; fa = 'The driver does not support partial cancellation.';
										|it = 'Частичная отмена не поддерживается драйвером.';
										|pl = 'The driver does not support partial cancellation.';
										|tr = 'Kısmi iptal, sürücü tarafından desteklenmiyor.'");
				LogError_(ConnectionParameters, "CancelPayment", ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			Else
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CancelPayment", ToArray(Undefined,IncomingParametersXML));
				CallResult = Await DriverObject.CancelPaymentAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			EndIf;
			
		ElsIf Command = "PayByPaymentCardWithCashWithdrawal" Then
			
			If ConnectionParameters.CashWithdrawals Then
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayWithCashWithdrawal", ToArray(Undefined,IncomingParametersXML));
				CallResult = Await DriverObject.PayWithCashWithdrawalAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Else
				ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
										|ru = 'Терминал не поддерживает данную операцию.';
										|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
										|it = 'Терминал не поддерживает данную операцию.';
										|pl = 'Terminal nie obsługuje niniejszej operacji.';
										|tr = 'Cihaz, bu işlemi desteklemiyor.'");
				LogError_(ConnectionParameters, "PayWithCashWithdrawal", ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			EndIf;
			
		ElsIf Command = "PurchaseWithEnrollment" Then
			
			If ConnectionParameters.PurchaseWithCreditCard Then
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PurchaseWithEnrollment", ToArray(Undefined,IncomingParametersXML));
				CallResult = Await DriverObject.PurchaseWithEnrollmentAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Else
				ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
										|ru = 'Терминал не поддерживает данную операцию.';
										|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
										|it = 'Терминал не поддерживает данную операцию.';
										|pl = 'Terminal nie obsługuje niniejszej operacji.';
										|tr = 'Cihaz, bu işlemi desteklemiyor.'");
				LogError_(ConnectionParameters, "PurchaseWithEnrollment", ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			EndIf;
			
		ElsIf Command = "AuthorizePreSales" Then
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Authorisation", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.AuthorisationAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		ElsIf Command = "AuthorizeCompletion" Then 
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "AuthConfirmation", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.AuthConfirmationAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		ElsIf Command = "AuthorizeVoidPreSales" Then
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CancelAuthorisation", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.CancelAuthorisationAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		Else
			ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
									|ru = 'Команда не поддерживается драйвером.';
									|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
									|it = 'Команда не поддерживается драйвером.';
									|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
									|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
			LogError_(ConnectionParameters, Command, ErrorDescription);
			ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
			Return ExecutionResult;
		EndIf;
		
		If CallResult.Value Then                         
			ExecutionResult = ResultOfAcquiringOperation(True, Undefined, ConnectionParameters);
			ExecutionResult.MerchantSNumber = MerchantSNumber;
			ExecutionResult.TransactionAmount = TransactionAmount;
			ExecutionResult.QrCardAttributes = QrCardAttributes;      
			
			IncomingParametersXML = CallResult.Parameters[1];
			OutgoingXMLParameters = CallResult.Parameters[2]; 
			ExecutionResult.Insert("IncomingParametersXML"  , IncomingParametersXML);
			ExecutionResult.Insert("OutgoingXMLParameters" , OutgoingXMLParameters);   
			SlipReceiptText = CallResult.Parameters[3];
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;      
		
		ExecutionResult.Insert("SlipReceiptText" , SlipReceiptText);
		Peripherals = EquipmentManagerClient.Peripherals();
		Peripherals.LastSlipCheck = SlipReceiptText; 
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError(Command, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function performs of operation on the ETH with an electronic certificate.
//
Async Function AcquiringOperationWithElectronicCertificate(DriverObject, ConnectionParameters, OperationData, Command)
	
	If ConnectionParameters.InterfaceRevision < 3005 Then    
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
								|ru = 'Команда не поддерживается драйвером.';
								|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
								|it = 'Il comando non è supportato dal driver.';
								|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
								|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
		LogError_(ConnectionParameters, Command, ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
		Return ExecutionResult;
	EndIf;
	
	QrCardAttributes = ?(OperationData.QrCardAttributes <> Undefined, OperationData.QrCardAttributes, "");
	MerchantSNumber  = ?(OperationData.MerchantSNumber <> Undefined, OperationData.MerchantSNumber, 0);
	CardNumber     = ?(OperationData.CardNumber <> Undefined, OperationData.CardNumber, "");
	ReceiptNumber      = ?(OperationData.ReceiptNumber <> Undefined, OperationData.ReceiptNumber, "");
	ReferenceNumber = ?(OperationData.ReferenceNumber <> Undefined, OperationData.ReferenceNumber, "");
	AuthorizationCode = ?(OperationData.AuthorizationCode <> Undefined, OperationData.AuthorizationCode, "");
	CartID = ?(OperationData.CartID <> Undefined, OperationData.CartID, "");
	AmountOfElectronicCertificate = ?(OperationData.AmountOfElectronicCertificate <> Undefined, OperationData.AmountOfElectronicCertificate, 0);
	AmountOfOwnFunds = ?(OperationData.AmountOfOwnFunds <> Undefined, OperationData.AmountOfOwnFunds, 0);
	SlipReceiptText  = "";
	OperationStatus = 0;

	If Not ConnectionParameters.PaymentByElectronicCertificates Then
		ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
								|ru = 'Терминал не поддерживает данную операцию.';
								|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
								|it = 'Il terminale non supporta questa operazione.';
								|pl = 'Terminal nie obsługuje niniejszej operacji.';
								|tr = 'Cihaz, bu işlemi desteklemiyor.'"); 
		LogError_(ConnectionParameters, Command, ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
		Return ExecutionResult;
	EndIf;

	Try
		If ConnectionParameters.InterfaceRevision >= 4000 Then
			If Command = "PayElectronicCertificate" Then
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayElectronicCertificate", 
					ToArray(Undefined,MerchantSNumber, QrCardAttributes, CartID, AmountOfElectronicCertificate, AmountOfOwnFunds));
				CallResult = Await DriverObject.PayElectronicCertificateAsync(ConnectionParameters.DeviceID_, MerchantSNumber, QrCardAttributes, CartID, 
					AmountOfElectronicCertificate, AmountOfOwnFunds, CardNumber, ReceiptNumber, 
					ReferenceNumber, AuthorizationCode, OperationStatus, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			ElsIf Command = "ReturnElectronicCertificate" Then
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayElectronicCertificate", 
					ToArray(Undefined,MerchantSNumber, QrCardAttributes, CartID, AmountOfElectronicCertificate, AmountOfOwnFunds, CardNumber, ReceiptNumber, ReferenceNumber));
				CallResult = Await DriverObject.ReturnElectronicCertificateAsync(ConnectionParameters.DeviceID_, MerchantSNumber, QrCardAttributes, CartID, 
					AmountOfElectronicCertificate, AmountOfOwnFunds, CardNumber, ReceiptNumber, 
					ReferenceNumber, AuthorizationCode, OperationStatus, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Else           
				ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
										|ru = 'Команда не поддерживается драйвером.';
										|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
										|it = 'Il comando non è supportato dal driver.';
										|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
										|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
				LogError_(ConnectionParameters, Command, ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			EndIf;
		Else
			If Command = "PayElectronicCertificate" Then
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayElectronicCertificate", 
					ToArray(Undefined,MerchantSNumber, CartID, AmountOfElectronicCertificate, AmountOfOwnFunds));
				CallResult = Await DriverObject.PayElectronicCertificateAsync(ConnectionParameters.DeviceID_, MerchantSNumber, CartID, 
					AmountOfElectronicCertificate, AmountOfOwnFunds, CardNumber, ReceiptNumber, 
					ReferenceNumber, AuthorizationCode, OperationStatus, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			ElsIf Command = "ReturnElectronicCertificate" Then
				EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayElectronicCertificate", 
					ToArray(Undefined,MerchantSNumber, CartID, AmountOfElectronicCertificate, AmountOfOwnFunds, CardNumber, ReceiptNumber, ReferenceNumber));
				CallResult = Await DriverObject.ReturnElectronicCertificateAsync(ConnectionParameters.DeviceID_, MerchantSNumber, CartID, 
					AmountOfElectronicCertificate, AmountOfOwnFunds, CardNumber, ReceiptNumber, 
					ReferenceNumber, AuthorizationCode, OperationStatus, SlipReceiptText); // Structure
				CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			Else           
				ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
										|ru = 'Команда не поддерживается драйвером.';
										|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
										|it = 'Il comando non è supportato dal driver.';
										|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
										|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
				LogError_(ConnectionParameters, Command, ErrorDescription);
				ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
				Return ExecutionResult;
			EndIf;
		EndIf;
			
		If CallResult.Value Then   
			If ConnectionParameters.InterfaceRevision >= 4000 Then
				MerchantSNumber = CallResult.Parameters[1];            
				QrCardAttributes = CallResult.Parameters[2];
				CartID = CallResult.Parameters[3];
				AmountOfElectronicCertificate = CallResult.Parameters[4];
				AmountOfOwnFunds = CallResult.Parameters[5];
				CardNumber = CallResult.Parameters[6];
				ReceiptNumber = CallResult.Parameters[7];
				ReferenceNumber = CallResult.Parameters[8];
				AuthorizationCode = CallResult.Parameters[9];
				OperationStatus = CallResult.Parameters[10];
				SlipReceiptText = CallResult.Parameters[11];
			Else
				MerchantSNumber = CallResult.Parameters[1];
				CartID = CallResult.Parameters[2];
				AmountOfElectronicCertificate = CallResult.Parameters[3];
				AmountOfOwnFunds = CallResult.Parameters[4];
				CardNumber = CallResult.Parameters[5];
				ReceiptNumber = CallResult.Parameters[6];
				ReferenceNumber = CallResult.Parameters[7];
				AuthorizationCode = CallResult.Parameters[8];
				OperationStatus = CallResult.Parameters[9];
				SlipReceiptText = CallResult.Parameters[10];   
			EndIf;                                       
			ExecutionResult = ResultOfAcquiringOperation(True, Undefined, ConnectionParameters);
			ExecutionResult.MerchantSNumber = MerchantSNumber;
			ExecutionResult.CardNumber    = CardNumber;
			ExecutionResult.POSTerminalReceiptNumber   = ReceiptNumber;
			ExecutionResult.ReferenceNumber = ReferenceNumber;
			ExecutionResult.AuthorizationCode = AuthorizationCode;
			ExecutionResult.OperationStatus = OperationStatus;      
			ExecutionResult.QrCardAttributes = QrCardAttributes;      
			ExecutionResult.CartID = CartID;
			ExecutionResult.AmountOfElectronicCertificate = AmountOfElectronicCertificate;
			ExecutionResult.AmountOfOwnFunds = AmountOfOwnFunds;
		Else  
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
		ExecutionResult.Insert("SlipReceiptText" , SlipReceiptText);
		Peripherals = EquipmentManagerClient.Peripherals();
		Peripherals.LastSlipCheck = SlipReceiptText;
	Except              
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError(Command, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function performs emergency cancellation of operation on the card.
//
Async Function EmergencyReversal(DriverObject, ConnectionParameters, OperationData)
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "EmergencyReversal");
		CallResult = Await DriverObject.EmergencyReversalAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);  
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("EmergencyReversal", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

// The function performs reconciliation of totals by cards.
//
Async Function ResultsOfDayByMaps(DriverObject, ConnectionParameters, OperationData)
	
	SlipReceiptText = "";
	Try            
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "Settlement");
		CallResult = Await DriverObject.ResultsOfDayByMapsAsync(ConnectionParameters.DeviceID_, SlipReceiptText); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);  
			ExecutionResult.Insert("SlipReceiptText", CallResult.Parameters[1]);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ResultsOfDayByMaps", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If ConnectionParameters.InterfaceRevision > 4001 Then
		Result = Await SetAsyncsApplicationInformation(DriverObject, ConnectionParameters);   
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// The function performs of operation on the ETH with an electronic certificate in XML mode.
//
Async Function AcquiringOperationWithXMLElectronicCertificate(DriverObject, ConnectionParameters, OperationData, Command)
	
	If ConnectionParameters.InterfaceRevision < 4003 Then      
		ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
								|ru = 'Команда не поддерживается драйвером.';
								|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
								|it = 'Команда не поддерживается драйвером.';
								|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
								|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
		Return ExecutionResult;   
	EndIf;
	
	QrCardAttributes = ?(OperationData.QrCardAttributes <> Undefined, OperationData.QrCardAttributes, "");
	MerchantSNumber  = ?(OperationData.MerchantSNumber <> Undefined, OperationData.MerchantSNumber, 0);                 
	CartID = ?(OperationData.CartID <> Undefined, OperationData.CartID, "");
	AmountOfElectronicCertificate = ?(OperationData.AmountOfElectronicCertificate <> Undefined, OperationData.AmountOfElectronicCertificate, 0);
	AmountOfOwnFunds = ?(OperationData.AmountOfOwnFunds <> Undefined, OperationData.AmountOfOwnFunds, 0);
	IncomingParametersXML = ?(OperationData.Property("IncomingParametersXML"), OperationData.IncomingParametersXML, "");
	SlipReceiptText = "";          
	OutgoingXMLParameters = ""; 
	
	If Not ConnectionParameters.PaymentByElectronicCertificates Then
		ErrorDescription = NStr("vi = 'Thiết bị không hỗ trợ giao dịch này.';
								|ru = 'Терминал не поддерживает данную операцию.';
								|en = 'The terminal does not support this transaction.'; fa = 'The terminal does not support this transaction.';
								|it = 'Терминал не поддерживает данную операцию.';
								|pl = 'Terminal nie obsługuje niniejszej operacji.';
								|tr = 'Cihaz, bu işlemi desteklemiyor.'"); 
		LogError_(ConnectionParameters, Command, ErrorDescription);
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
		Return ExecutionResult;
	EndIf;
	
	Try        
		If Command = "PayElectronicCertificate" Then
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PayElectronicCertificate", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.PayCertificateAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		ElsIf Command = "ReturnElectronicCertificate" Then
			
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ReturnElectronicCertificate", ToArray(Undefined,IncomingParametersXML));
			CallResult = Await DriverObject.ReturnCertificateAsync(ConnectionParameters.DeviceID_, IncomingParametersXML, OutgoingXMLParameters, SlipReceiptText); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			
		Else
			ErrorDescription = NStr("vi = 'Driver không hỗ trợ lệnh.';
									|ru = 'Команда не поддерживается драйвером.';
									|en = 'The command is not supported by the driver.'; fa = 'The command is not supported by the driver.';
									|it = 'Команда не поддерживается драйвером.';
									|pl = 'Polecenie nie jest obsługiwane przez sterownik.';
									|tr = 'Komut, sürücü tarafından desteklenmiyor.'");
			LogError_(ConnectionParameters, Command, ErrorDescription);
			ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription); 
			Return ExecutionResult;
		EndIf;
		
		If CallResult.Value Then                         
			ExecutionResult = ResultOfAcquiringOperation(True, Undefined, ConnectionParameters);
			ExecutionResult.MerchantSNumber = MerchantSNumber;
			ExecutionResult.QrCardAttributes = QrCardAttributes;        
			ExecutionResult.CartID = CartID;
			ExecutionResult.AmountOfElectronicCertificate = AmountOfElectronicCertificate;
			ExecutionResult.AmountOfOwnFunds = AmountOfOwnFunds;
			
			IncomingParametersXML = CallResult.Parameters[1];
			OutgoingXMLParameters = CallResult.Parameters[2]; 
			ExecutionResult.Insert("IncomingParametersXML"  , IncomingParametersXML);
			ExecutionResult.Insert("OutgoingXMLParameters" , OutgoingXMLParameters);   
			SlipReceiptText = CallResult.Parameters[3];
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;      
		
		ExecutionResult.Insert("SlipReceiptText" , SlipReceiptText);
		Peripherals = EquipmentManagerClient.Peripherals();
		Peripherals.LastSlipCheck = SlipReceiptText; 
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError(Command, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

#Region DigitalRetailScales

// The function returns the parameters of the weight event.
// 
// Returns:
//  Structure - Weight Event Parameters:
// * DeviceID - CatalogRef.Peripherals
// * Weight - Number 
// * Stabilization - Boolean - 
// * PlacementError - Boolean - 
// * IntersectionArea - Array of Number -
// 
Function WeightEventParameters() Export
	
	Result = New Structure();
	Result.Insert("DeviceID");
	Result.Insert("Weight");
	Result.Insert("Stabilization", True);
	Result.Insert("PlacementError", False);
	Result.Insert("IntersectionArea" , New Array());
	Return Result;
	
EndFunction    

// The function returns the parameters of the weights.
//
Async Function ParametersOfScales(DriverObject, ConnectionParameters, OperationData)
	
	If ConnectionParameters.InterfaceRevision >= 4000 Then
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ScaleOptions");
			CallResult = Await DriverObject.ParametersOfScalesAsync(ConnectionParameters.DeviceID_, ""); // Structure 
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
			ResultOfXMLOperation = CallResult.Parameters[1];
			If CallResult.Value Then
				ParametersOfScales = CommonCELClient.ReadRootXMLElement(ResultOfXMLOperation);
				ConnectionParameters.ScalesSupportTaring = ParametersOfScales.Property("Calibrate") And Upper(ParametersOfScales.Calibrate) = "TRUE"; 
				ConnectionParameters.WeightGainEvent        = ParametersOfScales.Property("WeighingEvent") And Upper(ParametersOfScales.WeighingEvent) = "TRUE";  
				
				ExecutionResult = ResultOfOperationOnEquipment(True);
				ExecutionResult.Insert("ScalesSupportTaring", ConnectionParameters.ScalesSupportTaring);
				ExecutionResult.Insert("WeightGainEvent"       , ConnectionParameters.WeightGainEvent);
			Else
				ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
			EndIf         
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("ParametersOfScales", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else 
		ExecutionResult = ResultOfOperationOnEquipment(True);
		ExecutionResult.Insert("ScalesSupportTaring", False);
		ExecutionResult.Insert("WeightGainEvent"       , False);   
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

// ++ Non-mobile application

#Region PortableDataCollectionTerminals

// Clears the previously loaded product table in the TSD.
//
Async Function ClearTable(DriverObject, ConnectionParameters, OperationData)
	
	Try
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "ClearTable");
		CallResult = Await DriverObject.ClearTableAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("ClearTable", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;  
	
EndFunction

// This function loads the table from the data collection terminal.
//
Async Function DownloadTable(DriverObject, ConnectionParameters, OperationData)
	
	Try                     
		DownloadData = ""; 
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "DownloadTable");
		CallResult = Await DriverObject.DownloadTableAsync(ConnectionParameters.DeviceID_, DownloadData); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True); 
			DownloadData = CallResult.Parameters[1];
			OperationData.Insert("DownloadData", DownloadData);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except  
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("DownloadTable", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return ExecutionResult;  
	
EndFunction

// This function uploads data to the data collection terminal.
//
Async Function UploadTable(DriverObject, ConnectionParameters, OperationData)
	
	PackageStatus = "first";
	
	NumberOfPackages_ = OperationData.XMLPackages.Count();
	PercentageIncrement = 100 / NumberOfPackages_;
	CurrentPercentage  = 0;
	CurPackage_ = 0;
	
	PackageStatus = ?(NumberOfPackages_ > 1 , "first", "last");
	
	For Each DataToUpload In OperationData.XMLPackages  Do
		
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "UploadTable", ToArray(Undefined, DataToUpload, PackageStatus));
			CallResult = Await DriverObject.UploadTableAsync(ConnectionParameters.DeviceID_, DataToUpload, PackageStatus); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("UploadTable", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return ExecutionResult;
		EndTry;
		
		If CallResult.Value <> True Then
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);        
			Return ExecutionResult;
		EndIf; 
		CurPackage_ = CurPackage_ + 1;
		PackageStatus = ?(CurPackage_ < NumberOfPackages_ - 1 , "regular", "last");
		CurrentPercentage = CurrentPercentage + PercentageIncrement;
		Status(NStr("vi = 'Kết xuất dữ liệu...';
					|ru = 'Выгрузка данных...';
					|en = 'Exporting data…'; fa = 'Exporting data…';
					|it = 'Upload dei dati...';
					|pl = 'Eksportowanie danych...';
					|tr = 'Veriler dışa aktarılıyor...'"), Round(CurrentPercentage));
	EndDo;
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	Return ExecutionResult;   
	
EndFunction

#EndRegion

#Region LabelPrinter

Async Function InitializePrinter(DriverObject, ConnectionParameters, OperationData)
	
	Try       
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "InitializePrinter");
		CallResult = Await DriverObject.InitializePrinterAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("InitializePrinter", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;       
	
	Return ExecutionResult;  
	
EndFunction

Async Function PrintLabels(DriverObject, ConnectionParameters, OperationData)
	
	ExecutionResult = ResultOfOperationOnEquipment(True);
	
	PackagesForUnloading = OperationData.PackagesForUnloading;
	NumberOfPackages_ = PackagesForUnloading.Count() - 1;
	
	PackageStatus  = "first";
	For Counter = 0 To NumberOfPackages_ Do
		If (Counter = NumberOfPackages_) Then
			PackageStatus = "last";
		ElsIf (Counter > 1) Then
			PackageStatus = "regular";
		EndIf;
		
		DataToUpload = PackagesForUnloading[Counter];
		Try
			EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "PrintLabels", ToArray(Undefined, DataToUpload, PackageStatus));
			CallResult = Await DriverObject.PrintLabelsAsync(ConnectionParameters.DeviceID_, DataToUpload, PackageStatus); // Structure
			CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndLogRecordingWithException(EntryOfLog, ErrorText);
			ExecutionResult = DriverCallError("PrintLabels", ErrorProcessing.DetailErrorDescription(ErrorInfo()));   
			Return ExecutionResult;
		EndTry;
		
		If CallResult.Value <> True Then
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);   
			Return ExecutionResult;
		EndIf;  
		
	EndDo;  
	
	Return ExecutionResult; 
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsCommonToRFIDReaders

// A function of receiving data of the RFID reader.
//
Function GetDataTagsRFID(DriverObject, ConnectionParameters, OperationData) 
	
	LabelTable = "";
	IDPackage = OperationData.IDPackage;      
	
	Try       
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "GetDataTagsRFID", ToArray(Undefined, IDPackage, LabelTable));
		CallResult = DriverObject.GetDataTagsRFID(ConnectionParameters.DeviceID_, IDPackage, LabelTable); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);   
			ExecutionResult.Insert("LabelTable", LabelTable);
		Else
			ErrorDescription = "";
			ResultOfErrorCall = DriverObject.GetLastError(ErrorDescription);
			ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("GetDataTagsRFID", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;       
	
	Return ExecutionResult;  
	
EndFunction

// This function opens an RFID reader session.
//
Async Function OpenSessionRFID(DriverObject, ConnectionParameters, OperationData)
	
	Try       
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "OpenSessionRFID");
		CallResult = Await DriverObject.OpenSessionRFIDAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("OpenSessionRFID", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;       
	
	Return ExecutionResult;  
	
EndFunction

// This function closes the RFID reader session.
//
Async Function CloseSessionRFID(DriverObject, ConnectionParameters, OperationData)
	
	Try       
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "CloseSessionRFID");
		CallResult = Await DriverObject.CloseSessionRFIDAsync(ConnectionParameters.DeviceID_); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("CloseSessionRFID", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;       
	
	Return ExecutionResult;  
	
EndFunction

// The function writes data to an RFID tag.
//
Async Function SaveDataTagRFID(DriverObject, ConnectionParameters, OperationData)
	
	// APK: 1353-off TID, EPC - abbreviation
	Timeout = OperationData.Timeout;
	TID = OperationData.TID;
	EPC = OperationData.EPC;
	Data = OperationData.Data;
	MemoryBank = ?(OperationData.MemoryBank = "EPC", 1, 2);
	
	Try       
		EntryOfLog = StartRecordingOperationLog(ConnectionParameters, "SaveDataTagRFID", ToArray(Undefined, TID, EPC, Data, MemoryBank, Timeout));
		CallResult = Await DriverObject.SaveDataTagRFIDAsync(ConnectionParameters.DeviceID_, TID, EPC, Data, MemoryBank, Timeout); // Structure
		CompleteRecordingOfOperationLog(EntryOfLog, CallResult);
		If CallResult.Value Then                    
			ExecutionResult = ResultOfOperationOnEquipment(True);
		Else
			ExecutionResult = Await GetDriverError(DriverObject, EntryOfLog);
		EndIf;
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndLogRecordingWithException(EntryOfLog, ErrorText);
		ExecutionResult = DriverCallError("SaveDataTagRFID", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;       
	
	Return ExecutionResult;  
	// APK: 1353-on
	
EndFunction

// The function generates an external event.
//
Async Function Generate_ExternalEvent(DriverObject, ConnectionParameters, OperationData) 
	
	EventData = ?(OperationData.Property("EventData"), OperationData.EventData, "");
	Base64 = ?(OperationData.Property("Base64"), OperationData.Base64, False);
	
	Try  
		CallResult = Await DriverObject.Generate_ExternalEventAsync(EventData, Base64); // Structure
		ExecutionResult = ResultOfOperationOnEquipment(True);
	Except
		ErrorDescription = NStr("vi = 'Lệnh được phép chỉ đối với giả lập driver.';
								|ru = 'Команда допустима только для эмулятора драйвера.';
								|en = 'The command is available only for the driver emulator.'; fa = 'The command is available only for the driver emulator.';
								|it = 'The command is available only for the driver emulator.';
								|pl = 'The command is available only for the driver emulator.';
								|tr = 'Komut, yalnızca sürücü emülatörü için geçerlidir.'"); 
		ExecutionResult = ResultOfOperationOnEquipment(False, ErrorDescription);  
		Return ExecutionResult
	EndTry;       
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

// -- Non-mobile application 

#Region LoggingOperations

Function StartRecordingOperationLog(ConnectionParameters, Command, ParameterValues = Undefined, IdsOfIncomingParameters = "")
	// ++ Non-mobile application
	#If Not MobileAppClient And Not MobileClient Then
	LoggingSystem = CommonCELClient.LoggingSystem();
	If LoggingSystem = Undefined Then
		Return Undefined;
	EndIf;
	Return LoggingSystem.Module.StartRecordingOperationLog(LoggingSystem, ConnectionParameters, Command, ParameterValues, IdsOfIncomingParameters);
	#EndIf
	// -- Non-mobile application 
EndFunction

Function CompleteRecordingOfOperationLog(EntryOfLog, CallResult, IdsOfOutgoingParameters = "")
	// ++ Non-mobile application
	#If Not MobileAppClient And Not MobileClient Then
	LoggingSystem = CommonCELClient.LoggingSystem();
	If LoggingSystem = Undefined Then
		Return 0;
	EndIf;
	LoggingSystem.Module.CompleteRecordingOfOperationLog(LoggingSystem, EntryOfLog, CallResult, IdsOfOutgoingParameters);
	#EndIf
	// -- Non-mobile application 
EndFunction

Function EndLogRecordingWithException(EntryOfLog, ErrorText)
	// ++ Non-mobile application
	#If Not MobileAppClient And Not MobileClient Then
	LoggingSystem = CommonCELClient.LoggingSystem();
	If LoggingSystem = Undefined Then
		Return 0;
	EndIf;
	LoggingSystem.Module.EndLogRecordingWithException(LoggingSystem, EntryOfLog, ErrorText);
	#EndIf
	// -- Non-mobile application 
EndFunction

Function RecordDriverErrorInOperationLogOfOperation(EntryOfLog, CallResult)
	
	// ++ Non-mobile application
	#If Not MobileAppClient And Not MobileClient Then
	LoggingSystem = CommonCELClient.LoggingSystem();
	If LoggingSystem = Undefined Then
		Return 0;
	EndIf;
	LoggingSystem.Module.RecordDriverErrorInOperationLogOfOperation(LoggingSystem, EntryOfLog, CallResult);
	#EndIf
	// -- Non-mobile application 
	
EndFunction

Function LogError_(ConnectionParameters, Command, ErrorDescription)
	// ++ Non-mobile application
	#If Not MobileAppClient And Not MobileClient Then
	LoggingSystem = CommonCELClient.LoggingSystem();
	If LoggingSystem = Undefined Then
		Return 0;
	EndIf;
	EntryOfLog = LoggingSystem.Module.StartRecordingOperationLog(LoggingSystem, ConnectionParameters, Command);
	LoggingSystem.Module.RecordErrorInOperationLog(LoggingSystem, EntryOfLog, ErrorDescription);
	#EndIf
	// -- Non-mobile application 
EndFunction

Function ToArray(Parameter1, Parameter2=Null, Parameter3=Null, Parameter4=Null, Parameter5=Null, Parameter6=Null, Parameter7=Null, Parameter8=Null, Parameter9=Null)
	
	Result = New Array();
	// ++ Non-mobile application
	#If Not MobileAppClient And Not MobileClient Then
	Result.Add(Parameter1);
	If Parameter2 <> Null Then
		Result.Add(Parameter2);
	EndIf;
	If Parameter3 <> Null Then
		Result.Add(Parameter3);
	EndIf;
	If Parameter4 <> Null Then
		Result.Add(Parameter4);
	EndIf;
	If Parameter5 <> Null Then
		Result.Add(Parameter5);
	EndIf;
	If Parameter6 <> Null Then
		Result.Add(Parameter6);
	EndIf;
	If Parameter7 <> Null Then
		Result.Add(Parameter7);
	EndIf;
	If Parameter8 <> Null Then
		Result.Add(Parameter8);
	EndIf;
	If Parameter9 <> Null Then
		Result.Add(Parameter9);
	EndIf;
	#EndIf
	// -- Non-mobile application 
	Return Result;
	
EndFunction

Function ShouldEscape(Val Value)
	
	Value = StrReplace(Value, CommonCELClientServer.GS1Separator(), CommonCELClientServer.EscapedCharacterGS1());
	Value = StrReplace(Value, CommonCELClientServer.EOTSeparator(), CommonCELClientServer.EscapedEOTCharacter());
	Value = StrReplace(Value, CommonCELClientServer.RSSeparator(), CommonCELClientServer.EscapedCharacterIsRS());
	Value = StrReplace(Value, Char(0), "\n");
	Return Value;
	
EndFunction

#EndRegion

// ++ Non-mobile application
// -- Non-mobile application 

#EndRegion