#Region FormsEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DisplayAdditionalElements = Not CommonCEL.ThisIsMobilePlatform();
	
	CreatingNewElement = Object.Ref = Catalogs.Peripherals.EmptyRef();
	TSPIoT = Undefined;
	
	// Protection against modification of an already created instance of the device.
	Items.HardwareDriver.ReadOnly = Not CreatingNewElement;
	Items.HardwareDriver.OpenButton = Not CreatingNewElement;
	Items.EquipmentType.ReadOnly = Not CreatingNewElement;
	     
	CheckingParameters = CreatingNewElement;
	
	If DisplayAdditionalElements Then
		Items.Workplace.Visible = Object.AttachmentType = Enums.PeripheralsTypes.LocalConnection;
		Items.AccessRestriction.Visible = Object.AttachmentType = Enums.PeripheralsTypes.SharedAccess;
	Else
		Items.Workplace.Visible = False;
		Items.AttachmentType.Visible = False;
		Items.AccessRestriction.Visible = False; 
		Items.GoToTheInstructionsWebsite.Visible = False;
	EndIf;

	If CreatingNewElement Then 
		If IsBlankString(Object.Workplace) 
			And Object.AttachmentType = Enums.PeripheralsTypes.LocalConnection Then
			Object.Workplace = EquipmentManagerServerCall.CustomerWorkplace();
		EndIf;
		Object.DeviceIsInUse = True;
	Else
		If Object.DeletionMark Or Not Object.DeviceIsInUse Then
			Items.ConnectionParameters.Enabled = False;
		EndIf;
	EndIf;
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Items.AutomaticFiscalization.Visible = ModuleDistributedFiscalization.AvailableDistributedFiscalization();
	Else
		Items.AutomaticFiscalization.Visible = False;
	EndIf;
	
	If CommonCEL.ThisIsMobilePlatform() Then
		CommonCEL.PrepareControl(Items.AttachmentType);
		CommonCEL.PrepareControl(Items.EquipmentType);
		CommonCEL.PrepareControl(Items.HardwareDriver);
		CommonCEL.PrepareControl(Items.Organization);
		CommonCEL.PrepareControl(Items.Description);      
		CommonCEL.PrepareControl(Items.TechnicalMeanPIoT); 
		CommonCEL.PrepareControl(Items.Workplace);
		CommonCEL.PrepareControl(Items.SerialNumber);   
		CommonCEL.PrepareControl(Items.MethodOfFormatLogicalControl);                                           
		CommonCEL.PrepareControl(Items.AllowableDiscrepancyOfFormatLogicalControl);
	EndIf;
	
	If CreatingNewElement Then
		Items.HardwareDriver.ListChoiceMode = True;
		FillInListOfDrivers();
	Else
		UpdateRegistrationParameters();     
	EndIf;

	UpdateFormInterface();    
	
	If CreatingNewElement Then     
		Items.FormDownloadFromITSWebsite.Visible = False;
	Else                    
		HardwareDriverLink = Object.HardwareDriver;
		HardwareDriverAttributes = CommonCEL.ObjectAttributesValues(HardwareDriverLink, "ConnectionMethod, NoLongerSupported");
		DownloadFromITSWebsiteIsAvailable = HardwareDriverAttributes.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase 
			And Not HardwareDriverAttributes.NoLongerSupported;
		Items.FormDownloadFromITSWebsite.Visible = DownloadFromITSWebsiteIsAvailable 
			And CommonCEL.SubsystemExists("OnlineUserSupport.GetAddIns");
		
		DriverData = EquipmentManager.HardwareDriverData(HardwareDriverLink);
		
	EndIf;
	
	Items.FormMessageToTechnicalSupport.Visible = CommonCEL.UsedMessagesToTechnicalSupportService()
			And CommonCELInternalServerCall.AuthenticationDataOfOnlineSupportUserFilled();
	
	Items.FormOperationsWithEquipment.Visible = 
		CommonCEL.LoggingSubsystemIsUsed()
		And Not CommonCEL.ThisIsMobilePlatform();
		
	Items.DriverLogArchiveManagementGroup.Visible = False;
	UpdateInformationAboutDriverLogsAtServer();

	EquipmentManagerServerCallOverridable.HardwareInstanceWhenCreatedOnServer(Object, ThisObject, Cancel, Parameters, StandardProcessing);
	SetVisibilityOfOrganizationOnServer();   

	// StandardSubsystems.AttachableCommands
	If CommonCEL.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = CommonCEL.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	EquipmentManagerServerCallOverridable.HardwareInstanceWhenReadingOnServer(CurrentObject, ThisObject);
	
	// Calling BSP
	// Standard subsystems.Pluggable Commands
	If CommonCEL.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonCEL.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// The end of the standard subsystem.Pluggable Commands
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonCELClient.UsedMessagesToTechnicalSupportService() Then
		MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
		Items.FormMessageToTechnicalSupport.Visible 
			= MessageModuleToBPOTechnicalSupportServiceClient.SendMessagesToTechnicalSupport();
	EndIf;
		
	Items.FormDownloadFromITSWebsite.Enabled = 
		ValueIsFilled(Object.EquipmentType) And ValueIsFilled(Object.HardwareDriver);
	
	EquipmentManagerClientOverridable.HardwareInstanceWhenOpened(Object, ThisForm, Cancel);
	
	UpdateInformationAboutDriverLogs();
	
	// Calling BSP
	// Standard subsystems.Pluggable Commands
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonCELClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// The end of the standard subsystem.Pluggable Commands
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not Cancel And Modified Then
		RefreshReusableValues();
	EndIf;
	
	EquipmentManagerClientOverridable.HardwareInstanceBeforeWrite(Object, ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	EquipmentManagerServerCallOverridable.HardwareInstanceBeforeWritingToServer(Cancel, CurrentObject, WriteParameters);
	WriteParameters.Insert("NewBPOElement", CurrentObject.IsNew());
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	EquipmentManagerServerCallOverridable.HardwareInstanceWhenWritingToServer(Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If WriteParameters.NewBPOElement And ValueIsFilled(CurrentObject.HardwareDriver) Then
		If Not CommonCEL.DataSeparationEnabled() Then
			AddDriverToCatalogOfExternalComponentsFromTemplate(CurrentObject.HardwareDriver);
		EndIf;
	EndIf;
	WriteParameters.Delete("NewBPOElement");
	
	DeviceParameters = EquipmentManager.DeviceParameters(Object.Ref);
	EquipmentManagerServerCallOverridable.HardwareInstanceAfterWritingToServer(CurrentObject, WriteParameters);
	
	HardwareDriverLink = Object.HardwareDriver;
	HardwareDriverAttributes = 
		CommonCEL.ObjectAttributesValues(HardwareDriverLink, "ConnectionMethod, NoLongerSupported");
	DownloadFromITSWebsiteIsAvailable = 
		HardwareDriverAttributes.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase 
		And Not HardwareDriverAttributes.NoLongerSupported;
	Items.FormDownloadFromITSWebsite.Visible = 
		DownloadFromITSWebsiteIsAvailable 
		And CommonCEL.SubsystemExists("OnlineUserSupport.GetAddIns");
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	CreatingNewElement = False;
	
	Items.ConnectionParameters.Visible = Not CreatingNewElement;
	
	UpdateFormInterface();
	
	EquipmentManagerClientOverridable.HardwareInstanceAfterRecording(Object, ThisObject, WriteParameters);
	
	// Calling BSP
	// Standard subsystems.Pluggable Commands
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonCELClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// The end of the standard subsystem.Pluggable Commands
	// The end of the BSP Challenge
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	EquipmentManagerServerCallOverridable.HardwareInstanceHandlingFillCheckOnServer(Object, ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If Modified Or CreatingNewElement Then
			If Write() Then
				CheckingParameters = False;
				Close();
			Else
				Return;
			EndIf;
		Else
			CheckingParameters = False;
			Close();
		EndIf;
		EquipmentManagerClient.ConfigureHardware(Object.Ref);
	Else
		CheckingParameters = False;
		Close();
	EndIf;   
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Object.Ref.IsEmpty() Then
		If CheckingParameters And Not Exit Then
			Cancel = True;
			Text = NStr("vi = 'Để sử dụng thiết bị, cần tùy chỉnh tham số kết nối.
			|Chuyển đến tùy chỉnh tham số kết nối?';
			|ru = 'Для использования устройства необходимо настроить параметры подключения.
			|Перейти к настройке параметров подключения?';
			|en = 'To use the device, set up connection parameters.
			|Go to connection parameter setup?'; fa = 'To use the device, set up connection parameters.
			|Go to connection parameter setup?';
			|it = 'Per l''utilizzo del dispositivo è necessario impostare i parametri di connessione.
			|Passare all''impostazione dei parametri di connessione?';
			|pl = 'Do użycia urządzenia należy ustawić parametry połączenia.
			|Przejść do ustawienia parametrów połączenia?';
			|tr = 'Cihazı kullanmak için bağlantı parametrelerini ayarlamak gerekiyor.
			|Bağlantı parametrelerini ayarlamak istiyor musunuz?'");
			Notification = New CallbackDescription("BeforeCloseCompletion",  ThisObject);
			ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);
		EndIf;
		
		EquipmentManagerClientOverridable.EquipmentInstanceBeforeClosing(Object, ThisObject, Cancel, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	EquipmentManagerClientOverridable.HardwareInstanceHandlingNavigationLink(Object, ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "BPO.ArchiveOfDriverLogsHasBeenUploaded" Then
		UpdateInformationAboutDriverLogsAtServer();
		UpdateInformationAboutDriverLogs();
	EndIf;
	
EndProcedure

#EndRegion

#Region ElementEventHandlers

&AtClient
Procedure EquipmentTypeChoiceProcessing(Item, ValueSelected, StandardProcessing)

	If Object.EquipmentType <> ValueSelected Then
		Object.EquipmentType = ValueSelected;
		Modified = True;
		FillInListOfDrivers();
		Items.FormDownloadFromITSWebsite.Enabled = False;
	Else
		Items.FormDownloadFromITSWebsite.Enabled = ValueIsFilled(Object.HardwareDriver);
	EndIf;
	
	StandardProcessing = False;
	
	UpdateFormInterface();
	
	EquipmentManagerClientOverridable.EquipmentInstanceEquipmentTypeSelection(Object, ThisObject, ThisObject, Item, ValueSelected);
	
	If Items.Organization.Visible <> CompanyVisibility Then
		SetVisibilityOfOrganizationOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure HardwareDriverChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected <> Object.HardwareDriver Then
		Object.Description = "'" + String(ValueSelected) + "'"
						+ ?(IsBlankString(String(Object.Workplace)),
							"",
							" " + NStr("vi = 'vào';
										|ru = 'на';
										|en = 'to'; fa = 'تا';
										|it = 'per';
										|pl = 'to';
										|tr = 'ilişkin'") + " " + String(Object.Workplace));
	EndIf;
	Items.FormDownloadFromITSWebsite.Enabled = ValueIsFilled(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Async Procedure DeviceIsInUseOnChange(Item)
	
	SelectedEquipment = Object.Ref;
	If SelectedEquipment.IsEmpty() Then
		Return;
	EndIf;
	
	If Object.DeviceIsInUse Then
		Return;
	EndIf;

	ShouldOutputWarning = True;
	WarningText = NStr("vi = 'Thiết bị %1 đang được dùng trong ứng dụng.
							   |Khi vô hiệu hóa có thể dẫn đến làm việc không chính xác với thiết bị này.
							   |Tiếp tục thao tác?';
							   |ru = 'Оборудование %1 используется в приложении.
							   |Отключение может привести к некорректной работе с этим оборудованием.
							   |Продолжить выполнение операции?';
							   |en = 'The %1 peripheral is used in the application.
							   |Disabling it may lead to incorrect operation of this peripheral.
							   |Continue?'; fa = 'The %1 peripheral is used in the application.
							   |Disabling it may lead to incorrect operation of this peripheral.
							   |Continue?';
							   |it = 'Оборудование %1 используется в приложении.
							   |Отключение может привести к некорректной работе с этим оборудованием.
							   |Продолжить выполнение операции?';
							   |pl = 'The %1 peripheral is used in the application.
							   |Disabling it may lead to incorrect operation of this peripheral.
							   |Continue?';
							   |tr = 'Bu ekipman %1 bir uygulamada kullanımdadır. 
							   |Silinmek için işaretlenmesi bu ekipmanın yanlış çalışmasına sebep olabilir. 
							   |İşleme devam edilsin mi?'");
	WarningText = StrTemplate(WarningText, SelectedEquipment);
	
	DeterminePossibilityOfEquipmentShutdown(SelectedEquipment, ShouldOutputWarning, WarningText);
	
	If ShouldOutputWarning Then
		If Await DoQueryBoxAsync(WarningText, QuestionDialogMode.YesNo) = DialogReturnCode.No Then
			Object.DeviceIsInUse = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DriverLogsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(StateOfDriverLogArchiveRequest.ArchiveDate) Then
		SaveDriverLogs(Undefined);
	Else
		If Object.Workplace = EquipmentManagerClient.CustomerWorkplace() Then
			DownloadDriverLogs(Undefined);
		Else
			RequestDriverLogs(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectTSPIoT(Command)
EndProcedure     


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConnectionParameters(Command)
	
	If CreatingNewElement Or Modified Then
		If Write() Then
			CheckingParameters = False;
			Close();
		Else
			Return;
		EndIf;
	Else
		CheckingParameters = False;
		Close();
	EndIf;
	
	If Object.EquipmentType = PredefinedValue("Enum.PeripheralTypes.CloudCashRegister") Then
		CloudCashAccountsModule = CommonCELClient.CommonModule("CloudCashAccountsClient");
		CloudCashAccountsModule.ConnectionSetup(Object.Ref);
	Else
		EquipmentManagerClient.ConfigureHardware(Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisterFiscalStorage(Command)
	
	FiscalStorageOperation(1);
	
EndProcedure

&AtClient
Procedure ChangeRegistrationParametersOfTheFiscalStorage(Command)
	
	FiscalStorageOperation(2);
	
EndProcedure

&AtClient
Procedure CloseFiscalStorage(Command)
	
	FiscalStorageOperation(3);
	
EndProcedure

&AtClient
Procedure GoToTheInstructionsWebsiteClick(Item)
	
	DownloadAddress = "https://its.1c.ru/db/metod81#browse:13:-1:2115:2511";
	OpenURL(DownloadAddress);
	
EndProcedure

&AtClient
Procedure MessageInfoEmailURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DownloadAddress = "https://its.1c.ru/bmk/envd_kkt";
	OpenURL(DownloadAddress);
	
EndProcedure

&AtClient
Procedure MessageToTechnicalSupport(Command)
	
	If CreatingNewElement Or Modified Then
		Write();
	EndIf;
	
	HardwareId = Object.Ref;
	If EquipmentManagerServerCall.DriverIsSuppliedInConfiguration(HardwareId) Then
		MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
		ParametersForMessage = MessageModuleToBPOTechnicalSupportServiceClient.ParametersForSendingErrorMessage();
		ParametersForMessage.HardwareId = HardwareId;
		ParametersForMessage.ErrorText = NStr("vi = 'Thông tin để hỗ trợ kỹ thuật';
												|ru = 'Информация для тех.поддержки';
												|en = 'Information for support'; fa = 'اطلاعات برای پشتیبانی';
												|it = 'Информация для тех.поддержки';
												|pl = 'Information for support';
												|tr = 'Teknik destek için bilgi'");
		CallbackDescription = New CallbackDescription("MessageToTechnicalSupportCompletion", ThisObject);
		MessageModuleToBPOTechnicalSupportServiceClient.StartSendingErrorMessage(CallbackDescription, ParametersForMessage);
	Else              
		CommonCELClient.ShowDriverNotCertifiedWarning();
	EndIf;
	
EndProcedure

&AtClient
Procedure MessageToTechnicalSupportCompletion(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorCode) Then
		CommonCELClient.MessageToUser(Result.ErrorMessage);
	EndIf;
	
EndProcedure 

&AtClient
Procedure OperationsWithEquipment(Command)
	
	EquipmentManagerClient.OpenHardwareOperations(Object.Ref);
	
EndProcedure

#Region LoadingDriverLogs

&AtClient
Async Procedure DownloadDriverLogs(Command)
	
	Enabled = False;
	DriverLogs = NStr("vi = 'Đang kết nhập tệp...';
						|ru = 'Идет загрузка файлов...';
						|en = 'Importing files...'; fa = 'Importing files...';
						|it = 'Importing files...';
						|pl = 'Importing files...';
						|tr = 'Dosyalar yükleniyor...'");
	Items.DriverLogs.Hyperlink = False;
	
	InstallFileSystemExtension = True;
	Result = Await EquipmentManagerClient.DownloadArchiveOfAsyncDriverLogs(
		Object.Ref, 
		Object.HardwareDriver,
		InstallFileSystemExtension);
		
	Items.DriverLogs.Hyperlink = True;
	Enabled = True;
	If Result.Success Then
		Await DoMessageBoxAsync(NStr("vi = 'Đã kết nhập thành công tệp có nhật ký của driver.';
									|ru = 'Файлы с логами драйвера успешно загружены.';
									|en = 'Files with driver logs are imported successfully.'; fa = 'Files with driver logs are imported successfully.';
									|it = 'Files with driver logs are imported successfully.';
									|pl = 'Files with driver logs are imported successfully.';
									|tr = 'Sürücü günlük dosyaları başarıyla yüklendi.'"), , NStr("vi = 'Thành công';
																										|ru = 'Успех';
																										|en = 'Success'; fa = 'موفقیت';
																										|it = 'Success';
																										|pl = 'Success';
																										|tr = 'Başarılı'"));
	Else
		Await DoMessageBoxAsync(Result.ErrorText, , NStr("vi = 'Lỗi';
														|ru = 'Ошибка';
														|en = 'Error'; fa = 'خطا';
														|it = 'Error';
														|pl = 'Error';
														|tr = 'Hata'"));
		
	EndIf;
	UpdateInformationAboutDriverLogsAtServer();
	UpdateInformationAboutDriverLogs();
	
EndProcedure

&AtClient
Procedure RequestDriverLogs(Command)
	
	Items.DriverLogs.Hyperlink = False;
		
	RequestDriverLogsAtServer(Object.Ref);
	UpdateInformationAboutDriverLogs();
	
EndProcedure

&AtClient
Async Procedure SaveDriverLogs(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	TransmittedFiles = ReceivedFilesOfDriverLogArchiveAtServer(Object.Ref);
	GetFilesDialogParameters = New GetFilesDialogParameters;
	GetFilesDialogParameters.Title = NStr("vi = 'Lưu tệp lưu trữ nhật ký của tệp';
											|ru = 'Сохранение архива логов файла';
											|en = 'Save an archive of file logs'; fa = 'Save an archive of file logs';
											|it = 'Save an archive of file logs';
											|pl = 'Save an archive of file logs';
											|tr = 'Dosya günlük arşivinin kaydedilmesi'");
	GetFilesArchiveParameters = New GetFilesArchiveParameters(, GetFilesArchiveMode.GetArchiveAlways);
	
	Await GetFilesFromServerAsync(TransmittedFiles, GetFilesDialogParameters, GetFilesArchiveParameters);
	
EndProcedure

&AtClient
Procedure DeleteDriverLogs(Command)
	
	ClearDriverLogFileAtServer();
	UpdateInformationAboutDriverLogs();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure UpdateInformationAboutDriverLogsAtServer()
	
	RequestWaitingTime = 60*10;
	StateOfDriverLogArchiveRequest = Catalogs.Peripherals.StateOfDriverLogsArchiveRequest(Object.Ref);
		
	If ValueIsFilled(Object.Ref) Then
		If StateOfDriverLogArchiveRequest.State = "Query"
			And CurrentSessionDate() - StateOfDriverLogArchiveRequest.RequestDate_ > RequestWaitingTime Then
			Catalogs.Peripherals.ClearArchiveOfDriverLogs(Object.Ref);
			StateOfDriverLogArchiveRequest = Catalogs.Peripherals.StateOfDriverLogsArchiveRequest(Object.Ref);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateInformationAboutDriverLogs()
	CurrentWorkplace = EquipmentManagerClient.CustomerWorkplace();
	
	If CurrentWorkplace = Object.Workplace Then
		Items.DownloadDriverLogs.Visible = True;
		Items.RequestDriverLogs.Visible = False;
	Else
		Items.DownloadDriverLogs.Visible = False;
		Items.RequestDriverLogs.Visible = True;
	EndIf;
	
	BSPIsUsed = CommonCELClient.BSPIsUsed();
	If Not BSPIsUsed Then
		Items.RequestDriverLogs.Visible = False;
	EndIf;
	
	If StateOfDriverLogArchiveRequest.State = "Received" Then
		ArchiveDate = StateOfDriverLogArchiveRequest.ArchiveDate;
		DriverLogs = StrTemplate(NStr("vi = 'Đã kết nhập tệp có nhật ký của driver từ %1.';
										|ru = 'Загружены файлы с логами драйвера от %1.';
										|en = 'Files with driver logs dated %1 are imported successfully.'; fa = 'Files with driver logs dated %1 are imported successfully.';
										|it = 'Files with driver logs dated %1 are imported successfully.';
										|pl = 'Files with driver logs dated %1 are imported successfully.';
										|tr = '%1 üzerinden sürücü günlük dosyaları yüklendi.'"), Format(ArchiveDate, ""));
		Items.DriverLogs.Hyperlink = True;
		Items.DriverLogArchiveManagementGroup.Visible = True;
	ElsIf StateOfDriverLogArchiveRequest.State = "Query" Then
		RequestDate_ = StateOfDriverLogArchiveRequest.RequestDate_;
		DriverLogs = StrTemplate(NStr("vi = 'Đã yêu cầu lưu trữ nhật ký của driver %1.';
										|ru = 'Архив логов драйвера запрошен %1.';
										|en = 'Driver log archive is requested on %1.'; fa = 'Driver log archive is requested on %1.';
										|it = 'Driver log archive is requested on %1.';
										|pl = 'Driver log archive is requested on %1.';
										|tr = 'Sürücü günlük dosyalarının arşivi talep edildi %1.'"), Format(RequestDate_, ""));
		Items.DriverLogs.Hyperlink = False;
		Items.DriverLogArchiveManagementGroup.Visible = False;
	ElsIf StateOfDriverLogArchiveRequest.State = "Missing" Then
		If CurrentWorkplace = Object.Workplace Then
				Items.DriverLogs.Hyperlink = True;
				DriverLogs = StrTemplate(NStr("vi = 'Kết nhập tệp có nhật ký của driver vào cơ sở dữ liệu.';
												|ru = 'Загрузить файлы с логами драйвера в базу данных.';
												|en = 'Import files with driver logs to the database.'; fa = 'Import files with driver logs to the database.';
												|it = 'Import files with driver logs to the database.';
												|pl = 'Import files with driver logs to the database.';
												|tr = 'Sürücü günlük dosyalarını veri tabanına yükle.'"));
				Items.DriverLogArchiveManagementGroup.Visible = False;
			Else
			If BSPIsUsed Then
			Items.DriverLogs.Hyperlink = True;
			DriverLogs = StrTemplate(NStr("vi = 'Yêu cầu tệp có nhật ký của driver từ máy tính client.';
											|ru = 'Запросить файлы с логами драйвера с клиентского компьютера.';
											|en = 'Request files with driver logs from the client computer.'; fa = 'Request files with driver logs from the client computer.';
											|it = 'Request files with driver logs from the client computer.';
											|pl = 'Request files with driver logs from the client computer.';
											|tr = 'İstemci bilgisayarından sürücü günlüklerini içeren dosyaları iste.'"));
			Items.DriverLogArchiveManagementGroup.Visible = False;
			Else
				Items.DriverLogs.Hyperlink = False;
				DriverLogs = StrTemplate(NStr("vi = 'Không thể yêu cầu tệp có nhật ký driver từ máy tính client mà không có Thư viện phân hệ chuẩn.';
												|ru = 'Недоступен запрос файлов с логами драйвера с клиентского компьютера без БСП.';
												|en = 'Cannot request files with driver logs from a client computer without SSL.'; fa = 'Cannot request files with driver logs from a client computer without SSL.';
												|it = 'Cannot request files with driver logs from a client computer without SSL.';
												|pl = 'Cannot request files with driver logs from a client computer without SSL.';
												|tr = 'SSL olmadan istemci bilgisayardan sürücü günlük dosyalarını içeren dosyalara erişilemiyor.'"));
				Items.DriverLogArchiveManagementGroup.Visible = False;
			EndIf;
		EndIf;
	EndIf;
	
	If CommonCELClient.IsWebClient() Then
		Items.SaveDriverLogs.Visible = False;
	Else
		Items.SaveDriverLogs.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFormInterface();
	
	TypeOfEquipmentCCT         = Object.EquipmentType = Enums.PeripheralTypes.CREWithDataTransfer;
	TypeOfEquipmentFR          = Object.EquipmentType = Enums.PeripheralTypes.FiscalCashRegisters;
	TypeOfEquipmentIF          = Object.EquipmentType = Enums.PeripheralTypes.ReceiptPrinter;
	TypeOfEquipmentCloudCCT = Object.EquipmentType = Enums.PeripheralTypes.CloudCashRegister;
	
	CompanyVisibility = TypeOfEquipmentCCT Or TypeOfEquipmentFR Or TypeOfEquipmentIF Or TypeOfEquipmentCloudCCT;
	
	Items.FiscalData.Visible = TypeOfEquipmentCCT And Not CreatingNewElement;
	
	If Items.FiscalData.Visible Or Items.AccessRestriction.Visible Then
		Items.Tabs.PagesRepresentation = FormPagesRepresentation.TabsOnTop       
	Else
		Items.Tabs.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Items.Organization.Visible = CompanyVisibility;    
	Items.PIoT.Visible = False;   
	If Object.DeletionMark Or Not Object.DeviceIsInUse Then
		Items.ConnectionParameters.Enabled = False;     
	Else
		Items.ConnectionParameters.Enabled = True;     
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalStorageOperation_Completion(ExecutionResult, Var_Parameters) Export
	
	ClearMessages();
	
	If ExecutionResult.Result Then
		MessageText = NStr("vi = 'Giao dịch đã hoàn thành.';
							|ru = 'Операция завершена.';
							|en = 'Operation completed.'; fa = 'عملیات تکمیل شد.';
							|it = 'Operazione completata.';
							|pl = 'Operacja została zakończona.';
							|tr = 'İşlem tamamlandı.'");
	Else
		MessageText = ExecutionResult.ErrorDescription;
	EndIf;
	
	CommonCELClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure FiscalStorageOperation_ContinueReading(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult <> Undefined 
		And TypeOf(ExecutionResult) = Type("Structure")
		And CommonCELClient.CheckPrintingDevicesAreUsed() Then
		
		FiscalDevice = Object.Ref;
		NotificationOnCompletion = New CallbackDescription("FiscalStorageOperation_Completion", ThisObject);
		ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
		ModuleEquipmentReceiptPrintingDevicesClient.StartFNOperationForFiscalDevice(NotificationOnCompletion,
			UUID, FiscalDevice, ExecutionResult); 
			
	EndIf;
	
	ThisObject.Read();
	
EndProcedure

&AtClient
Procedure FiscalStorageOperation(OperationType)
	
#If WebClient Then
	ShowMessageBox(, NStr("vi = 'Chức năng này chỉ khả dụng ở chế độ Thin client và Thick client.';
							|ru = 'Данный функционал доступен только в режиме тонкого и толстого клиента.';
							|en = 'This functionality is available only in the thin and thick client mode.'; fa = 'This functionality is available only in the thin and thick client mode.';
							|it = 'Questa funzionalità è disponibile solo nelle modalità thin e fat client.';
							|pl = 'Dane funkcje są dostępne tylko w trybie cienkiego i grubego klienta.';
							|tr = 'Bu işlevsellik yalnızca ince ve kalın istemci modunda kullanılabilir.'"));
	Return;
#EndIf
	
	FiscalDevice = Object.Ref;
	If Not ValueIsFilled(FiscalDevice) Then
		Return;
	EndIf;               
	
	ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
	OpeningParameters = ModuleEquipmentReceiptPrintingDevicesClient.ParametersFormOfCCTREGISTRATIONSETTINGS();
	OpeningParameters.FiscalDevice = FiscalDevice;
	OpeningParameters.Organization = Object.Organization;
	OpeningParameters.OperationType = OperationType; 
	
	NotificationOnCompletion = New CallbackDescription("FiscalStorageOperation_ContinueReading", ThisObject);
	ModuleEquipmentReceiptPrintingDevicesClient.OpenCCTRegistrationSettingsForm(NotificationOnCompletion, OpeningParameters);
	
EndProcedure

&AtServer
Procedure FillInListOfDrivers()
	
	If CommonCEL.CloudCCTSAreUsed() Then
		TypeOfEquipmentCloudCCT = Object.EquipmentType = Enums.PeripheralTypes.CloudCashRegister;
		
		Items.HardwareDriver.ChoiceList.Clear();
		Items.HardwareDriver.Visible = Not TypeOfEquipmentCloudCCT;
		
	EndIf;
	
	DriversOfHardware = EquipmentManager.Drivers_ByHardwareType(Object.EquipmentType);
	For Each HardwareDriver In DriversOfHardware Do
		Items.HardwareDriver.ChoiceList.Add(HardwareDriver.Value, HardwareDriver.Presentation);
	EndDo;
	
	Object.HardwareDriver = PredefinedValue("Catalog.HardwareDrivers.EmptyRef");
	Object.Description = "";
	
EndProcedure

&AtClient
Procedure OpenURL(Var_URL, Val Notification = Undefined)
	
	#If ThickClientOrdinaryApplication Then
		// Platform feature: The re-navigation link is not available in the thick client of a regular application.
		NotificationOnCompletion = New CallbackDescription();
		BeginRunningApplication(NotificationOnCompletion, Var_URL); // APK:534 fixed strings are transmitted
	#Else
		GotoURL(Var_URL); // APK:534 fixed strings are transmitted
	#EndIf

EndProcedure

&AtServer
Procedure SetVisibilityOfOrganizationOnServer()
	
	Items.Organization.Visible = CompanyVisibility;
	
EndProcedure

&AtClient
Procedure DownloadFromITSWebsite(Command)
	
	// Insert the contents of the handler.
	If CreatingNewElement Or Modified Then
		Write();
	EndIf;
	
	Notification = New CallbackDescription("DownloadFromITSWebsiteCompletion", ThisObject);
	EquipmentManagerClient.InstallHardwareDriver(Notification, Object.HardwareDriver);
	
EndProcedure

&AtClient
Procedure DownloadFromITSWebsiteCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		Title = NStr("vi = 'Đã kết nhập cấu phần.';
					|ru = 'Компонента загружена.';
					|en = 'Add-in is imported.'; fa = 'Add-in is imported.';
					|it = 'Компонента загружена.';
					|pl = 'Add-in is imported.';
					|tr = 'Bileşen yüklendi.'");
		Text     = StrTemplate(NStr("vi = 'Đã kết nhập và cài đặt cấu phần %1.';
									|ru = 'Компонента %1 успешно загружена и установлена.';
									|en = 'The %1 add-in is successfully imported and installed.'; fa = 'The %1 add-in is successfully imported and installed.';
									|it = 'Компонента %1 успешно загружена и установлена.';
									|pl = 'The %1 add-in is successfully imported and installed.';
									|tr = '%1 bileşeni başarıyla yüklendi ve kuruldu.'"),
						ExecutionResult.DeviceID);
	Else
		Title = NStr("vi = 'Lỗi kết nhập cấu phần.';
					|ru = 'Ошибка загрузки компоненты.';
					|en = 'Add-in import error.'; fa = 'Add-in import error.';
					|it = 'Ошибка загрузки компоненты.';
					|pl = 'Add-in import error.';
					|tr = 'Bileşen yükleme hatası.'");
		Text     = StrTemplate(NStr("vi = 'Chưa kết nhập cấu phần %1 theo nguyên nhân:
						|%2.';
						|ru = 'Компонента %1 не загружена, по причине:
						|%2.';
						|en = 'The %1 add-in is not imported. Reason:
						|%2.'; fa = 'The %1 add-in is not imported. Reason:
						|%2.';
						|it = 'Компонента %1 не загружена, по причине:
						|%2.';
						|pl = 'The %1 add-in is not imported. Reason:
						|%2.';
						|tr = '%1 bileşeni şu nedenden dolayı yüklenmedi:
						|%2.'"),
						ExecutionResult.DeviceID,
						ExecutionResult.ErrorDescription);
	EndIf;
	ShowMessageBox(,Text,,Title);
	
EndProcedure

&AtServerNoContext
Procedure DeterminePossibilityOfEquipmentShutdown(Peripherals, ShouldOutputWarning, WarningText)

	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.DeterminePossibilityOfEquipmentShutdown(
		Peripherals, ShouldOutputWarning, WarningText, StandardProcessing);
	If StandardProcessing Then
		ShouldOutputWarning = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddDriverToCatalogOfExternalComponentsFromTemplate(ReferenceToDriver)
	
	If Not CommonCEL.SubsystemExists("StandardSubsystems.AddIns") Then
		Return
	EndIf;

	// ++ Non-mobile application
	
	DriverAttributes = CommonCEL.ObjectAttributesValues(ReferenceToDriver, 
		"ObjectID, ConnectionMethod, Description, PredefinedDataName, DriverTemplateName, DriverVersion");
	If DriverAttributes.ConnectionMethod = Enums.DriverConnectionMethod.From_Template Then
	
		ExternalComponentsServerModule = CommonCEL.CommonModule("AddInsServer");
		
		LoadedExternalComponents = ExternalComponentsServerModule.ComponentsToUse("ForUpdate");
		FoundRow = LoadedExternalComponents.Find(DriverAttributes.ObjectID, "Id");
		If FoundRow = Undefined Then
			
			TemplateIsAvailable = False;
			DriverTemplateName = DriverAttributes.DriverTemplateName;
			NameOfDriver = DriverAttributes.PredefinedDataName;
			EquipmentManager.FillINTemplateData(NameOfDriver, DriverTemplateName, TemplateIsAvailable, Undefined);
			If TemplateIsAvailable Then
				
				DataToAdd = EquipmentManager.NewDataToAddExternalComponentsToCatalog();
				DataToAdd.Id = DriverAttributes.ObjectID;
				DataToAdd.TemplateName = StrReplace(DriverTemplateName, "CommonTemplate.", "");
				DataToAdd.Description = DriverAttributes.Description;
				DataToAdd.Version = DriverAttributes.DriverVersion;
				DataToAdd.Ref = ReferenceToDriver;
				
				StandardProcessing = True;
				EquipmentManagerServerCallOverridable.WhenLoadingDriverIntoCatalogOfExternalComponentsWhenAddingHardware(DataToAdd, StandardProcessing);
				If Not StandardProcessing Then
					Return;
				EndIf;
				
				DriversToAdd = New Array();
				DriversToAdd.Add(DataToAdd);
				EquipmentManager.AddExternalComponentFromTemplateToCatalogInternal(DriversToAdd);
				
			EndIf;
		Else
			EquipmentManager.SetDriverConnectionMethod(ReferenceToDriver, Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase);
		EndIf;
	EndIf;
	
	// -- Non-mobile application
	
EndProcedure

&AtClient
Procedure EquipmentTypeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	FillInAvailableTypesOfEquipment(ChoiceData, Object.AttachmentType);
	
EndProcedure

&AtServerNoContext
Procedure FillInAvailableTypesOfEquipment(ChoiceData, AttachmentType)
	
	If AttachmentType = Enums.PeripheralsTypes.SharedAccess Then
		AvailableTypesOfEquipment = EquipmentManager.AvailableTypesOfPublicEquipment();
	Else
		AvailableTypesOfEquipment = EquipmentManager.AvailableTypesOfEquipment();
	EndIf;
	For Each Type In AvailableTypesOfEquipment Do
		ChoiceData.Add(Type);
	EndDo;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	// Calling BSP
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonCELClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters)
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtServer
Procedure UpdateRegistrationParameters()
	
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
		ModuleEquipmentReceiptPrintingDevices.UpdateCCTRegistrationParameters(CRERegistrationParameters, Object.RegistrationParameters);
	EndIf;             
	
EndProcedure    


&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	// Calling BSP
	If CommonCEL.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = CommonCEL.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	// Calling BSP
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonCELClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure           

&AtClient
Procedure RequestCCTData(Command)
	
	FiscalDevice = Object.Ref;
	If Not ValueIsFilled(FiscalDevice) Then
		Return;
	EndIf;               
	
	NotificationOnCompletion = New CallbackDescription("RequestDataCCT_Continue", ThisObject);
	ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
	ModuleEquipmentReceiptPrintingDevicesClient.StartGettingFiscalDeviceParameters(NotificationOnCompletion, UUID, FiscalDevice);
	
EndProcedure         

&AtClient
Procedure RequestDataCCT_Continue(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then 
		ThisObject.Read();
		UpdateRegistrationParameters();    
	Else
		CommonCELClient.MessageToUser(ExecutionResult.ErrorDescription);
	EndIf;
	
EndProcedure

#Region LoadingDriverLogs

&AtServerNoContext
Function ReceivedFilesOfDriverLogArchiveAtServer(Peripherals)
	
	LogArchive = Catalogs.Peripherals.ArchiveOfDriverLogs(Peripherals);
	
	TransmittedFiles = New Array;
	
	If LogArchive.IsArchive Then
		Address = PutToTempStorage(LogArchive.ArchiveData);
		FileToPass = New TransferableFileDescription;
		FileToPass.Location = Address;
		FileToPass.Name = StrTemplate("logs-%1.zip", Format(LogArchive.ArchiveDate, "DF=dd-MM-yyyy-hh-mm-ss"));
		TransmittedFiles.Add(FileToPass);
	Else
		For Each File In LogArchive.ArchiveData Do
			Address = PutToTempStorage(File.Data);
			FileToPass = New TransferableFileDescription;
			FileToPass.Location = Address;
			FileToPass.Name = File.Name;
			TransmittedFiles.Add(FileToPass);
		EndDo;
	EndIf;
	
	// ++ Non-mobile application
	OperationData_ = InformationRegisters.OperationsWithPeripherals.ArchiveOfOperationsOfEquipment(Peripherals);
	Address = PutToTempStorage(OperationData_.ArchiveData);
	FileToPass = New TransferableFileDescription;
	FileToPass.Location = Address;
	FileToPass.Name = StrTemplate("operations-%1.txt", Format(OperationData_.ArchiveDate, "DF=dd-MM-yyyy-hh-mm-ss"));
	TransmittedFiles.Add(FileToPass);
	// -- Non-mobile application
	
	Return TransmittedFiles;
	
EndFunction

&AtServer
Procedure ClearDriverLogFileAtServer()
	
	If ValueIsFilled(Object.Ref) Then
		Catalogs.Peripherals.ClearArchiveOfDriverLogs(Object.Ref);
		UpdateInformationAboutDriverLogsAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure RequestDriverLogsAtServer(Peripherals)
	
	If ValueIsFilled(Object.Ref) Then
		Catalogs.Peripherals.SendRequestForDriverLogArchive(Peripherals);
		UpdateInformationAboutDriverLogsAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessResponseToRequestForDriverLogArchive(ResponseData, AdditionalParameters) Export
	
	ProcessEndOfWaitingForLogRequest(ResponseData);
		
EndProcedure

&AtClient
Procedure ProcessEndOfWaitingForLogRequest(ResponseData = Undefined)
	
	AdditionalParameters = New Structure("Text, Title", "", "");
	WhenClickingUserAlerts = New CallbackDescription("WhenClickingUserAlerts", ThisObject, AdditionalParameters);
	
	If ResponseData = Undefined Then
		AdditionalParameters.Title = NStr("vi = 'Lỗi.';
											|ru = 'Ошибка.';
											|en = 'Error.'; fa = 'Error.';
											|it = 'Error.';
											|pl = 'Error.';
											|tr = 'Hata.'");
		AdditionalParameters.Text = NStr("vi = 'Không phản hồi từ client';
										|ru = 'Нет ответа от клиента';
										|en = 'No response from the client'; fa = 'No response from the client';
										|it = 'No response from the client';
										|pl = 'No response from the client';
										|tr = 'İstemciden yanıt yok'");
		ShowUserNotification(
			AdditionalParameters.Title, 
			WhenClickingUserAlerts,
			AdditionalParameters.Text,
			PictureLib.AppearanceCrossIcon, 
			UserNotificationStatus.Important);
		
	ElsIf ResponseData.Success Then
		AdditionalParameters.Title = NStr("vi = 'Thành công.';
											|ru = 'Успех.';
											|en = 'Success.'; fa = 'Success.';
											|it = 'Success.';
											|pl = 'Success.';
											|tr = 'Başarılı.'");
		AdditionalParameters.Text = NStr("vi = 'Đã nhận thành công lưu trữ nhật ký.';
										|ru = 'Архив логов успешно получен.';
										|en = 'The log archive is successfully received.'; fa = 'The log archive is successfully received.';
										|it = 'The log archive is successfully received.';
										|pl = 'The log archive is successfully received.';
										|tr = 'Günlük arşivi başarıyla alındı.'");
		ShowUserNotification(
			AdditionalParameters.Title, 
			WhenClickingUserAlerts,
			AdditionalParameters.Text,
			PictureLib.AppearanceCheckIcon, 
			UserNotificationStatus.Important);
		
	Else
		AdditionalParameters.Title = NStr("vi = 'Lỗi.';
											|ru = 'Ошибка.';
											|en = 'Error.'; fa = 'Error.';
											|it = 'Error.';
											|pl = 'Error.';
											|tr = 'Hata.'");
		AdditionalParameters.Text = ResponseData.ErrorText;
		ShowUserNotification(
			AdditionalParameters.Title, 
			WhenClickingUserAlerts,
			AdditionalParameters.Text,
			PictureLib.AppearanceCrossIcon, 
			UserNotificationStatus.Important);
	EndIf;
	
	DetachIdleHandler("EndOfWaitingForLogRequest");
	CommonCELClient.ClientNotifications().
		DetachHandler(
			EquipmentManagerClientServer.KeyForRespondingToRequestForDriverLogArchive());
	Items.DriverLogGroup.Enabled = True;
	ThisForm.Enabled = True;
	
	UpdateInformationAboutDriverLogsAtServer();
	UpdateInformationAboutDriverLogs();
		
EndProcedure

&AtClient
Procedure EndOfWaitingForLogRequest() Export
	
	ProcessEndOfWaitingForLogRequest();
	
EndProcedure

&AtClient
Procedure WhenClickingUserAlerts(AdditionalParameters) Export
	
	DoMessageBoxAsync(AdditionalParameters.Text,, AdditionalParameters.Title);
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_OnChangingFormElement(Item)
	
	EquipmentManagerClientOverridable.HardwareInstanceONChangingFormElement(Object, ThisObject, Item);
	
EndProcedure


#EndRegion