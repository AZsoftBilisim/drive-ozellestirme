#Region FormsEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CreateNewAccessValue = Not ValueIsFilled(Object.Ref);       
	CloudCashRegister = False;
	
	If CreateNewAccessValue Then
		Object.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsInstalledOnLocalComputer;
		Items.ObjectID.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;   
		Items.SafeConnection.Visible = False;
	Else                                                   
		
		DriverData = EquipmentManager.HardwareDriverData(Object.Ref);
		
		SuppliedWithConfigurations = Object.Predefined;
		ConnectingLocallyById = Object.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsInstalledOnLocalComputer;
		ConnectingFromInformationBase     = Object.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase;
		ConnectingFromTemplate                 = Object.ConnectionMethod = Enums.DriverConnectionMethod.From_Template;
		CloudCashRegister = Object.EquipmentType = Enums.PeripheralTypes.CloudCashRegister;
		
		Items.UpdateDriverFormFromFile.Visible = ConnectingFromInformationBase;    
		Items.NoLongerSupported.Visible = Object.NoLongerSupported;           
		Items.NotCertified.Visible = DriverData.NonCertified;
		Items.MessageWhenUsing.Visible = Object.EquipmentType = Enums.PeripheralTypes.CREWithDataTransfer;
		Items.TemplateIsNotAvailable.Visible = ConnectingFromTemplate And Not DriverData.TemplateIsAvailable And Not IsBlankString(Object.ObjectID);
		
		If SuppliedWithConfigurations Then
			WorkMode = WorkMode + NStr("vi = 'Cục bộ';
										|ru = 'Локальный';
										|en = 'Local'; fa = 'محلی';
										|it = 'Locale';
										|pl = 'Lokalny';
										|tr = 'Yerel'");
		EndIf;
		
		PropertiesViewOnly =  SuppliedWithConfigurations And Not ConnectingLocallyById;
		Items.EquipmentType.ReadOnly = PropertiesViewOnly;
		Items.Description.ReadOnly    = PropertiesViewOnly;
		Items.ObjectID.ReadOnly = PropertiesViewOnly;
		Items.FormWriteAndClose.Visible = Not PropertiesViewOnly;
		Items.SafeConnection.Visible = Not (Object.EquipmentType = Enums.PeripheralTypes.BarcodeScanner
				Or Object.EquipmentType = Enums.PeripheralTypes.MagneticStripeCardReaders 
				Or Object.EquipmentType = Enums.PeripheralTypes.CloudCashRegister);   
				
		If CloudCashRegister Then
			Items.FormInstallDriver.Visible = False;   
			Items.UpdateDriverFormFromFile.Visible = False;   
			Items.CurrentStatus.Visible = False;   
			Items.ObjectID.Visible = False; 
		Else
			Items.ObjectID.ToolTipRepresentation = ToolTipRepresentation.Balloon;
			UpdateDriversInformation();
		EndIf;
		
	EndIf;
	
	If Items.TemplateIsNotAvailable.Visible Then
		Items.TemplateIsNotAvailable.Title = Items.TemplateIsNotAvailable.Title + Chars.NBSp + DriverData.DriverTemplateName;
	EndIf;
	
	Items.DriverVersion.Visible = ConnectingFromTemplate And Not IsBlankString(Object.DriverVersion);
	Items.InstalledVersion.Visible = False;
	Items.LogGroup.Visible = False;
	Items.FormClose.DefaultButton = Not Items.FormWriteAndClose.Visible; 
	
	If CommonCEL.ThisIsMobilePlatform() Then
		CommonCEL.PrepareControl(Items.Description);
		CommonCEL.PrepareControl(Items.EquipmentType);
		CommonCEL.PrepareControl(Items.ConnectionMethod);
		CommonCEL.PrepareControl(Items.WorkMode);
		CommonCEL.PrepareControl(Items.ObjectID);
		CommonCEL.PrepareControl(Items.DriverVersion);
		CommonCEL.PrepareControl(Items.CurrentStatus);
		CommonCEL.PrepareControl(Items.InstalledVersion);       
		Items.SafeConnection.Visible = False;
	EndIf;     
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Left(CurrentObject.ObjectID, 6) = "AddIn." Then
		CurrentObject.ObjectID = Right(CurrentObject.ObjectID, StrLen(CurrentObject.ObjectID) - 6);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Then
	Items.SafeConnection.Enabled = False; 
#EndIf
	
	If ValueIsFilled(Object.Ref) And Not CloudCashRegister Then
		UpdateHardwareDriversInformation();
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallDriver(Command)
	
	InstallHardwareDriver();
	
EndProcedure

&AtClient
Procedure UpdateDriver_Completion(Result, AdditionalParameters) Export
	
	If Result.Imported1 Then  
		
		CommonCELClient.MessageToUser(NStr("vi = 'Đã cập nhật driver thiết bị.';
											|ru = 'Драйвер оборудования обновлен.';
											|en = 'Hardware driver is updated.'; fa = 'Hardware driver is updated.';
											|it = 'Driver di apparecchiatura aggiornato.';
											|pl = 'Sterownik sprzętu został zaktualizowany.';
											|tr = 'Donanım sürücüsü güncellendi.'"));
		Write();  
		
		UpdateDriversInformation();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateDriver(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	ConnectionComponentTypeSearchParameters = AddInsCELClient.AdditionalInformationSearchParameters();
	ConnectionComponentTypeSearchParameters.XMLFileName = "INFO.XML";
	ConnectionComponentTypeSearchParameters.XPathExpression = "//drivers/component/@type";
	
	ImportParameters = AddInsCELClient.ImportParameters();
	ImportParameters.Id = Object.ObjectID;
	
	ImportParameters.AdditionalInformationSearchParameters.Insert("ConnectionComponentType", ConnectionComponentTypeSearchParameters);
	
	Notification = New CallbackDescription("UpdateDriver_Completion", ThisObject, AdditionalParameters);
	
	AddInsCELClient.ImportAddInFromFile(Notification, ImportParameters);
	
EndProcedure

&AtClient
Procedure GoToDriverLogFile(Command)
	
	Notification = New CallbackDescription("LaunchingApplicationCompletion", ThisObject);
	If EquipmentManagerClientServer.LaunchStringIsSafe(DriverLogFilePath) Then
		BeginRunningApplication(Notification, DriverLogFilePath); // APK:534 launch check performed
	Else
		CommonCELClient.MessageToUser(
			NStr("vi = 'Không được phép sử dụng các ký tự $ ` | || ; & && trong đường dẫn đến tệp';
				|ru = 'Не допускается в пути к файлу использование символов $ ` | || ; & &&';
				|en = '$ ` | || ; & && characters are not allowed in the file path.'; fa = '$ ` | || ; & && characters are not allowed in the file path.';
				|it = 'Non è permesso nel percorso al file l''utilizzo dei caratteri $ ` | || ; & &&';
				|pl = 'W ścieżce do pliku nie można używać znaków $ ` | || ; & &&';
				|tr = 'Dosya yolunda $ ` | || ; & && sembolleri kullanılmasına izin verilmez.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure LaunchingApplicationCompletion(ReturnCode, AdditionalParameter) Export
	
	ErrorMessage = NStr("vi = 'Chuyển đến tệp nhật ký driver.';
						|ru = 'Переход к файлу лога драйвера.';
						|en = 'Go to the driver log file.'; fa = 'Go to the driver log file.';
						|it = 'Passaggio al file di log del driver.';
						|pl = 'Przejście do pliku logu sterownika';
						|tr = 'Sürücü günlük dosyasına geçiş.'");
	CommonCELClient.MessageToUser(ErrorMessage);
	
EndProcedure

&AtClient
Procedure SavingLogEnd(SelectedFiles, AdditionalParameters) Export
	
#If Server Or ThinClient Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Or ExternalConnection Then
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Try                                                 
		RecordZIP = New ZipFileWriter(SelectedFiles[0]);
		RecordZIP.Add(DriverLogFilePath + "*", ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);
		RecordZIP.Write();
	Except
		Raise;
	EndTry;
#EndIf
	
EndProcedure

&AtClient
Procedure SaveDriverLog(Command)
	
#If ThinClient Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
	// APK: 1348-off the filesystem Client module from BSP is not used
	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Multiselect = False;
	Dialog.Directory = DriverLogFilePath;
	Dialog.DefaultExt = "zip";
	Dialog.Filter = NStr("vi = 'Tệp nén';
						|ru = 'Файл архива';
						|en = 'Archive file'; fa = 'Archive file';
						|it = 'File di archivio';
						|pl = 'Plik archiwum';
						|tr = 'Arşiv dosyası'") + " (*.zip)|*.zip";
	FileSelectionNotification = New CallbackDescription("SavingLogEnd", ThisObject);
	Dialog.Show(FileSelectionNotification);
	// APK: 1348-on
#EndIf
	
EndProcedure

&AtClient
Procedure SavingLocalizationPattern(SelectedFiles, AdditionalParameters) Export
	
#If Server Or ThinClient Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Or ExternalConnection Then
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Try
		Text = New TextWriter;
		Text.Open(SelectedFiles[0],TextEncoding.UTF8);
		Text.WriteLine(LocalizationPattern);
		Text.Close();
	Except
		Raise;
	EndTry;
#EndIf
	
EndProcedure

&AtClient
Procedure GetLocalizationPattern(Command)

#If ThinClient Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
	// APK: 1348-off the filesystem Client module from BSP is not used
	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Multiselect = False;
	Dialog.Directory = DriverLogFilePath;
	Dialog.DefaultExt = "xml";
	Dialog.Filter = NStr("vi = 'Tệp bản địa hóa driver';
						|ru = 'Файл локализации драйвера';
						|en = 'Driver localization file'; fa = 'Driver localization file';
						|it = 'Файл локализации драйвера';
						|pl = 'Driver localization file';
						|tr = 'Sürücü yerelleştirme dosyası'") + " (*.xml)|*.xml";
	FileSelectionNotification = New CallbackDescription("SavingLocalizationPattern", ThisObject);
	Dialog.Show(FileSelectionNotification);
	// APK: 1348-on
#EndIf

EndProcedure

&AtClient
Procedure EquipmentTypeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	FillInAvailableTypesOfEquipment(ChoiceData);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Async Procedure InstallHardwareDriver()
	
	ExecutionResult = Await EquipmentManagerClient.InstallHardwareDriverAsync(Object.Ref);
	
	If ExecutionResult.Result Then
		MessageText = NStr("vi = 'Đã hoàn thành cài đặt driver thiết bị.';
							|ru = 'Установка драйвера оборудования завершена.';
							|en = 'Peripherals driver is installed.'; fa = 'Peripherals driver is installed.';
							|it = 'Impostazione del driver di apparecchiatura completata.';
							|pl = 'Instalacja sterownika sprzętu została zakończona.';
							|tr = 'Donanım sürücüsü yüklendi.'");
		UpdateHardwareDriversInformation();
#If MobileAppClient Or MobileClient Then
		Message(MessageText);
#Else
		ShowUserNotification(NStr("vi = 'Cài đặt driver';
									|ru = 'Установка драйвера';
									|en = 'Driver installation'; fa = 'Driver installation';
									|it = 'Установка драйвера';
									|pl = 'Driver installation';
									|tr = 'Sürücü kurulumu'"), , MessageText, PictureLib.AppearanceCheckIcon, 
			UserNotificationStatus.Important, ThisForm.UUID);
#EndIf
	Else
		MessageText   = ExecutionResult.ErrorDescription;
#If MobileAppClient Or MobileClient Then
		Message(MessageText);
#Else
		ShowUserNotification(NStr("vi = 'Cài đặt driver';
									|ru = 'Установка драйвера';
									|en = 'Driver installation'; fa = 'Driver installation';
									|it = 'Установка драйвера';
									|pl = 'Driver installation';
									|tr = 'Sürücü kurulumu'"), , MessageText, PictureLib.AppearanceCrossIcon, 
			UserNotificationStatus.Important, ThisForm.UUID);
#EndIf
	EndIf;
	
EndProcedure

&AtClient
Async Procedure UpdateHardwareDriversInformation()
	
	ExecutionResult = Await EquipmentManagerClient.GettingDriverDescriptionAsync(Undefined, DriverData);    
	
	DriverDescription = ?(ExecutionResult.Result, ExecutionResult.DriverDescription, Undefined); 
	UpdateHardwareDriverInformationOnForm(ExecutionResult.Result, DriverDescription, ExecutionResult.ErrorDescription);
	
EndProcedure

&AtServer
Procedure UpdateDriversInformation()
	
	If ConnectingFromInformationBase Then
		ResultInformation = AddInsCEL.AddInInformation(Object.ObjectID);
		If Not IsBlankString(ResultInformation.ErrorDescription) Then
			Items.ObjectID.ToolTip = ResultInformation.ErrorDescription;
			Items.ObjectID.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Else
			Items.ObjectID.ToolTipRepresentation = ToolTipRepresentation.Balloon;
		EndIf;
	EndIf;
	
EndProcedure    

&AtClient
Procedure UpdateHardwareDriverInformationOnForm(DriverIs_Specified, DriverDescription, ErrorDescription = Undefined)
	
	If DriverIs_Specified Then
		
		CurrentStatus = NStr("vi = 'Đã cài đặt trên thiết bị này';
							|ru = 'Установлен на текущем устройстве';
							|en = 'Installed on the current device'; fa = 'Installed on the current device';
							|it = 'Установлен на текущем устройстве';
							|pl = 'Installed on the current device';
							|tr = 'Mevcut cihaza yüklendi'");
		
		If Not IsBlankString(DriverDescription.DriverVersion) Then
			RevisionsOnScreen = StrTemplate(NStr("vi = '(Phiên bản yêu cầu %1)';
												|ru = '(Версия требований %1)';
												|en = '(Requirement version %1)'; fa = '(Requirement version %1)';
												|it = '(Версия требований %1)';
												|pl = '(Requirement version %1)';
												|tr = '(Gereksinim sürümü %1)'"), DriverDescription.InterfaceRevisionPresentation);
			If DriverDescription.IntegrationComponent Then  
				InstalledVersion = StrTemplate(NStr("vi = 'Cấu phần tích hợp %1';
													|ru = 'Интеграционный компонент %1';
													|en = '%1 integration component'; fa = '%1 integration component';
													|it = 'Интеграционный компонент %1';
													|pl = '%1 integration component';
													|tr = 'Entegre %1 eklentisi'"), DriverDescription.VersionOfIntegrationComponent) + Chars.LF +   
									StrTemplate(NStr("vi = 'Bộ cài đặt chính %1';
													|ru = 'Основная поставка %1';
													|en = 'Main %1 distribution package'; fa = 'Main %1 distribution package';
													|it = 'Основная поставка %1';
													|pl = 'Main %1 distribution package';
													|tr = '%1 temel tedariği'"), DriverDescription.DriverVersion) + Chars.LF + 
									RevisionsOnScreen;                     
				Items.CurrentStatus.MultiLine = False;
				Items.InstalledVersion.MultiLine = True;
			Else 
				InstalledVersion = DriverDescription.DriverVersion;
				InstalledVersion = InstalledVersion + Chars.NBSp + RevisionsOnScreen;  
				Items.CurrentStatus.MultiLine = True;
			EndIf;
				
			Items.InstalledVersion.Visible = True;
		Else
			Items.InstalledVersion.Visible = False;
		EndIf;
		
		If DriverDescription.ThisIsEmulator Then
			Items.ThisIsEmulator.Visible = True;    
		EndIf;
		
		If Not IsBlankString(DriverDescription.DriverLogFilePath) Then
			DriverLogFilePath = DriverDescription.DriverLogFilePath;
			Items.LogGroup.Visible = True;
			Items.DriverLogFilePath.ToolTip = ?(DriverDescription.DriverLogIsEnabled, 
				NStr("vi = 'Đã bật ghi nhận các thao tác của driver';
					|ru = 'Логирование операций драйвера включено';
					|en = 'Logging of driver operations is enabled'; fa = 'Logging of driver operations is enabled';
					|it = 'Log delle operazione di driver attivato';
					|pl = 'Logowanie operacji sterownika jest włączone';
					|tr = 'Sürücü işlem günlüğü etkin'"), 
				NStr("vi = 'Đã tắt ghi nhận các thao tác của driver';
					|ru = 'Логирование операций драйвера отключено';
					|en = 'Logging of driver operations is disabled'; fa = 'Logging of driver operations is disabled';
					|it = 'Log delle operazioni di driver disattivato';
					|pl = 'Logowanie operacji sterownika jest wyłączone';
					|tr = 'Sürücü işlem günlüğü devre dışı'"));
				
		#If ThinClient Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
			Items.SaveDriverLog.Visible = DriverDescription.DriverLogIsEnabled;
			Items.GoToDriverLogFile.Visible = DriverDescription.DriverLogIsEnabled;
		#Else
			Items.SaveDriverLog.Visible = False;
			Items.GoToDriverLogFile.Visible = False;
		#EndIf
		Else
			Items.LogGroup.Visible = False;
		EndIf;
		
		LocalizationPattern = DriverDescription.LocalizationPattern;
		#If ThinClient Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
			Items.FormGetLocalizationPattern.Visible = Not IsBlankString(LocalizationPattern);
		#Else
			Items.FormGetLocalizationPattern.Visible = False;  
		#EndIf
			
		Items.FormInstallDriver.Visible = False;        
		
	Else      
		CurrentStatus = StrTemplate(NStr("vi = 'Chưa cài đặt driver. %1';
										|ru = 'Драйвер не установлен. %1';
										|en = 'The driver is not installed. %1'; fa = 'The driver is not installed. %1';
										|it = 'The driver is not installed. %1';
										|pl = 'The driver is not installed. %1';
										|tr = 'Sürücü kurulmadı. %1'"), ErrorDescription);  
		Items.CurrentStatus.ToolTip = ErrorDescription;
		Items.FormInstallDriver.Visible = Not ConnectingLocallyById;  
		Items.CurrentStatus.MultiLine = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure FillInAvailableTypesOfEquipment(ChoiceData)
	
	AvailableTypesOfEquipment = EquipmentManager.AvailableTypesOfEquipment();
	For Each Type In AvailableTypesOfEquipment Do
		ChoiceData.Add(Type);
	EndDo;
	
EndProcedure

#EndRegion