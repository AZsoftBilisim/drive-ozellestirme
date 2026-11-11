///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var Attachable_Module;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ClientID = Parameters.ClientID;
	UserScanSettings = FilesOperations.GetUserScanSettings(ClientID);
	FillPropertyValues(ThisObject, UserScanSettings);
	If DeviceName <> "" Then
		Items.DeviceName.ChoiceList.Add(DeviceName);
	EndIf;
	Items.ScanLogCatalog.Enabled = UseScanLogDirectory;
			
	MethodOfConversionToPDF = ?(UseImageMagickToConvertToPDF, 1, 0);
		
	JPGFormat = Enums.ScannedImageFormats.JPG;
	TIFFormat = Enums.ScannedImageFormats.TIF;
	
	MultiPageTIFFormat = Enums.MultipageFileStorageFormats.TIF;
	
	Items.GroupJPGQuantity.Visible = (ScannedImageFormat = JPGFormat);
	Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	
	Items.PathToConverterApplication.Enabled = UseImageMagickToConvertToPDF;
	
	InstallHints();
	
	Rescanning = Parameters.Rescanning;
	
	If Parameters.Rescanning Then
		Items.OK.Title = NStr("vi = 'Scan';
								|ru = 'Сканировать';
								|en = 'Scan'; fa = 'اسکن';
								|it = 'Сканировать';
								|pl = 'Scan';
								|tr = 'Tara'");
	EndIf;
	
	ScanJobParameters = Common.CommonSettingsStorageLoad("ScanAddIn", "ScanJobParameters", Undefined);
	
	Items.ScanningError.Visible = ScanJobParameters <> Undefined;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
	Else
		Items.GroupSupportRequests.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If CommonClient.IsLinuxClient() Then
		AdaptForLinux();
		ShowScannerDialog = False;
	EndIf;
	RefreshStatus();
	ProcessScanDialogUsage();
	Items.ScanningError.Visible = Items.ScanningError.Visible And Not IsScanFormOpen();
	
	SetRecommendationText();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If ShowScannerDialog Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Resolution"));
		CheckedAttributes.Delete(CheckedAttributes.Find("Chromaticity"));
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "ScanSettingsChanged" Then
		FillPropertyValues(ThisObject, Parameter);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeviceNameOnChange(Item)
	ReadScannerSettings();
EndProcedure

&AtClient
Procedure DeviceNameChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If DeviceName = ValueSelected Then // If nothing has changed, do not do anything.
		StandardProcessing = False;
	EndIf;	
EndProcedure

&AtClient
Procedure ScannedImageFormatOnChange(Item)
	
	Items.GroupJPGQuantity.Visible = (ScannedImageFormat = JPGFormat);
	Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	InstallHints();
	
EndProcedure

&AtClient
Procedure PathToConverterApplicationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
		
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName = PathToConverterApplication;
	Filter = NStr("vi = 'Đã thực thi tệp(*.exe)|*.exe';
					|ru = 'Исполняемые файлы(*.exe)|*.exe';
					|en = 'Executable files (*.exe)|*.exe'; fa = 'Executable files (*.exe)|*.exe';
					|it = 'I file in esecuzione(*.exe)|*.exe';
					|pl = 'Wykonywane pliki (*.exe)|*.exe';
					|tr = 'Yürütülebilir dosyalar (*.exe)|*.exe'");
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn tệp để chuyển đổi sang PDF';
								|ru = 'Выберите файл для преобразования в PDF';
								|en = 'Select file to convert to PDF'; fa = 'Select file to convert to PDF';
								|it = 'Selezionare il file da convertire in PDF';
								|pl = 'Wybierz plik do konwersji do PDF';
								|tr = 'PDF''ye dönüştürülecek bir dosya seçin'");
	If OpenFileDialog.Choose() Then
		PathToConverterApplication = OpenFileDialog.FullFileName;
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfConversionToPDFOnChange(Item)
	
	UseImageMagickToConvertToPDF = MethodOfConversionToPDF = 1;
	ProcessChangesUseImageMagick();
	
EndProcedure

&AtClient
Procedure JPGQualityOnChange(Item)
	Items.JPGQuality.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chất lượng (%1)';
																							|ru = 'Качество (%1)';
																							|en = 'Quality (%1)'; fa = 'Quality (%1)';
																							|it = 'Качество (%1)';
																							|pl = 'Quality (%1)';
																							|tr = 'Kalite (%1)'"), JPGQuality);
EndProcedure

&AtClient
Procedure DeviceNameStartChoice(Item, StandardProcessing)
	Try
		DeviceArray = FilesOperationsInternalClient.EnumDevices(ThisObject, Attachable_Module);
	Except
		DeviceArray = New Array;
	EndTry;  
	
	If DeviceArray.Count() > 0 Then
		Item.ChoiceList.LoadValues(DeviceArray);
	Else
		StandardProcessing = False;
		ShowMessageBox(,NStr("vi = 'Không tìm thấy máy quét được kết nối. Hãy kiểm tra kết nối máy quét.';
							|ru = 'Не обнаружено подключенных сканеров. Проверьте подключение сканера.';
							|en = 'No scanners were detected. Check the scanner connection.'; fa = 'No scanners were detected. Check the scanner connection.';
							|it = 'Не обнаружено подключенных сканеров. Проверьте подключение сканера.';
							|pl = 'No scanners were detected. Check the scanner connection.';
							|tr = 'Bağlı tarayıcı bulunamadı. Tarayıcı bağlantısını kontrol edin.'"));
	EndIf;
EndProcedure 

&AtClient
Procedure ShowScannerDialogOnChange(Item)
	
	ProcessScanDialogUsage();
	
EndProcedure

&AtClient
Procedure ScanLogCatalogStartChoice(Item, ChoiceData, StandardProcessing)

	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = ScanLogCatalog;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn đường dẫn để lưu nhật ký quét';
								|ru = 'Выберите путь для сохранения журнала сканирования';
								|en = 'Select a path to save the scan log'; fa = 'Select a path to save the scan log';
								|it = 'Выберите путь для сохранения журнала сканирования';
								|pl = 'Select a path to save the scan log';
								|tr = 'Tarama günlüğünün kaydedileceği yolu seçin'");
	
	If OpenFileDialog.Choose() Then
		ScanLogCatalog = OpenFileDialog.Directory;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseScanLogDirectoryOnChange(Item)
	Items.ScanLogCatalog.Enabled = UseScanLogDirectory;
EndProcedure

&AtClient
Procedure RecommendationsURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "Run32BitClient" Then
		StandardProcessing = False;
		Run32BitClient();
	Else
		Expression = NStr("vi = 'Chưa xác định thao tác đối với tham chiếu dẫn hướng.';
							|ru = 'Действие для навигационной ссылки не определено.';
							|en = 'URL action is not defined.'; fa = 'URL action is not defined.';
							|it = 'URL action is not defined.';
							|pl = 'URL action is not defined.';
							|tr = 'URL bağlantısının işlevi tanımlanmadı.'");
		Raise(Expression, ErrorCategory.GotoURLError);
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportRequestDetailsURLProcessing(Item, Var_URL, StandardProcessing)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		StandardProcessing = False;
		
		If Var_URL = "SupportTicket" Then
			
			CompletionHandler = New CallbackDescription(
				"ContinueSubmitSupportTicket",
				ThisObject);
			
			If Not ValueIsFilled(ErrorPresentation) Then
				ErrorPresentation = NStr("vi = 'Đã gọi trợ giúp từ cài đặt quét.';
										|ru = 'Вызвана помощь из настроек сканирования.';
										|en = 'Help is opened from the scanner settings.'; fa = 'Help is opened from the scanner settings.';
										|it = 'Help is opened from the scanner settings.';
										|pl = 'Help is opened from the scanner settings.';
										|tr = 'Tarama ayarlarından yardım çağrıldı.'");
			EndIf;
			
			FilesOperationsInternalClient.GenerateSupportInformation(
				ErrorPresentation, 
				CompletionHandler);
			
		ElsIf Var_URL = "InfoForSupport" Then
			
			CompletionHandler = New CallbackDescription(
				"ContinueDownloadInfoForSupport",
				ThisObject);
			
			If Not ValueIsFilled(ErrorPresentation) Then
				ErrorPresentation = NStr("vi = 'Đã gọi trợ giúp từ cài đặt quét.';
										|ru = 'Вызвана помощь из настроек сканирования.';
										|en = 'Help is opened from the scanner settings.'; fa = 'Help is opened from the scanner settings.';
										|it = 'Help is opened from the scanner settings.';
										|pl = 'Help is opened from the scanner settings.';
										|tr = 'Tarama ayarlarından yardım çağrıldı.'");
			EndIf;
			
			FilesOperationsInternalClient.GenerateSupportInformation(
				ErrorPresentation,
				CompletionHandler);
			
		Else
			
			Expression = NStr("vi = 'Chưa xác định thao tác đối với tham chiếu dẫn hướng.';
								|ru = 'Действие для навигационной ссылки не определено.';
								|en = 'URL action is not defined.'; fa = 'URL action is not defined.';
								|it = 'URL action is not defined.';
								|pl = 'URL action is not defined.';
								|tr = 'URL bağlantısının işlevi tanımlanmadı.'");
			Raise(Expression, ErrorCategory.GotoURLError);
			
		EndIf;
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If Not CheckFilling() Then 
		Return;
	EndIf;
		
	UserScanSettings = FilesOperationsClientServer.UserScanSettings();
	FillPropertyValues(UserScanSettings, ThisObject);
	
	If CommonClient.IsLinuxClient() Then
		UserScanSettings.PathToConverterApplication = "convert";
	EndIf;
	
	Context = New Structure;
	Context.Insert("UserScanSettings", UserScanSettings);
	Context.Insert("FillingCheckError", False);
	
	If UserScanSettings.UseScanLogDirectory Then
		If UserScanSettings.ScanLogCatalog = "" Then
			ErrorText = NStr("vi = 'Chưa điền đường dẫn đến nhật ký quét.';
							|ru = 'Не заполнен путь к журналу сканирования.';
							|en = 'Path to scan log is not specified.'; fa = 'Path to scan log is not specified.';
							|it = 'Не заполнен путь к журналу сканирования.';
							|pl = 'Path to scan log is not specified.';
							|tr = 'Tarama günlüğü yolu doldurulmadı.'");
			CommonClient.MessageToUser(ErrorText, , "ScanLogCatalog");
			Context.FillingCheckError = True;
			Result = New Structure("Success", True);
			AfterScanDirAvailabilityChecked(Result, Context)
		Else
			Notification = New CallbackDescription("AfterScanDirAvailabilityChecked", ThisObject, Context);
			FilesOperationsInternalClient.CheckDirAvailability(Notification, UserScanSettings.ScanLogCatalog);
		EndIf;
	Else
		Result = New Structure("Success", True);
		AfterScanDirAvailabilityChecked(Result, Context);
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	ReadScannerSettings();
EndProcedure

&AtClient
Procedure OpenScannedFilesNumbers(Command)
	OpenForm("InformationRegister.ScannedFilesNumbers.ListForm");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ContinueSubmitSupportTicket(Result, AdditionalParameters) Export
	
	// StandardSubsystems.SupportRequests
	ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
		"SupportRequestsInternalClient");
	
	RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
	RequestParameters_.TechnologicalInfo = Result.TechnologicalInfo;
	RequestParameters_.AdditionalFiles = Result.AdditionalFiles;
	RequestParameters_.Subject = NStr("vi = 'Vấn đề khi cài đặt quét';
										|ru = 'Проблема при настройке сканирования';
										|en = 'Scanner setup issue'; fa = 'Scanner setup issue';
										|it = 'Scanner setup issue';
										|pl = 'Scanner setup issue';
										|tr = 'Tarama ayarlarında sorun oluştu'");
	
	ModuleSupportRequestsInternalClient.SubmitSupportTicket(
		ThisObject,
		RequestParameters_);
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure ContinueDownloadInfoForSupport(Result, AdditionalParameters) Export
	
	// StandardSubsystems.SupportRequests
	ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
		"SupportRequestsInternalClient");
	
	RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
	RequestParameters_.TechnologicalInfo = Result.TechnologicalInfo;
	RequestParameters_.AdditionalFiles = Result.AdditionalFiles;
	
	ModuleSupportRequestsInternalClient.DownloadInfoForSupport(
		ThisObject,
		RequestParameters_);
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure SetRecommendationText()
	
	Recommendations = New Array;
	
	Recommendations.Add(NStr("vi = 'Hãy thử các phương án sau:';
							|ru = 'Попробуйте следующие варианты:';
							|en = 'Try the following solutions:'; fa = 'Try the following solutions:';
							|it = 'Попробуйте следующие варианты:';
							|pl = 'Try the following solutions:';
							|tr = 'Aşağıdaki seçenekleri deneyin:'"));
	Recommendations.Add(" • " + NStr("vi = 'Hãy kiểm tra kết nối máy quét và thử quét lại.';
									|ru = 'Проверьте подключение сканера и повторите попытку сканирования.';
									|en = 'Check scanner connection and try again.'; fa = 'Check scanner connection and try again.';
									|it = 'Проверьте подключение сканера и повторите попытку сканирования.';
									|pl = 'Check scanner connection and try again.';
									|tr = 'Tarayıcı bağlantısını kontrol edin ve tekrar taramayı deneyin.'"));
	
	If Not ShowScannerDialog And Not CommonClient.IsLinuxClient() Then
		Recommendation = " • " + NStr("vi = 'Thay đổi phương thức đặt tùy chỉnh thành <b>Máy quét được mở rộng trong hộp thoại</b>.';
										|ru = 'Смените способ задания настроек на <b>Расширенные в диалоге сканера</b>.';
										|en = 'Switch to the <b>advanced settings</b>.'; fa = 'Switch to the <b>advanced settings</b>.';
										|it = 'Смените способ задания настроек на <b>Расширенные в диалоге сканера</b>.';
										|pl = 'Switch to the <b>advanced settings</b>.';
										|tr = 'Ayarları belirleme yöntemini <b>Tarayıcı iletişim kutusundaki uzantılar</b> olarak değiştirin.'");
		Recommendations.Add(Recommendation);
	EndIf;
	
	ImageResolution = PredefinedValue("Enum.ScannedImageResolutions.dpi1200");
	If ShowScannerDialog Or Resolution = ImageResolution Then
		Recommendations.Add(" • " + NStr("vi = 'Giảm độ phân giải quét xuống <b>600 dpi</b>.';
										|ru = 'Снизьте разрешение сканирования до <b>600 dpi</b>.';
										|en = 'Reduce the scanner resolution to <b>600 dpi</b>.'; fa = 'Reduce the scanner resolution to <b>600 dpi</b>.';
										|it = 'Снизьте разрешение сканирования до <b>600 dpi</b>.';
										|pl = 'Reduce the scanner resolution to <b>600 dpi</b>.';
										|tr = 'Tarama çözünürlüğünü <b>600 dpi</b> değerine düşürün.'"));
	EndIf;
	
	SystemInfo = New SystemInfo();
	If SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		Template = " • " + NStr(
			"vi = 'Hãy cài đặt và khởi động <a href = ""%1"">thin client 1C:Enterprise đối với Windows (32-bit)</a>, 
			| trong đó có sẵn nhiều thiết bị và tùy chỉnh quét hơn.';
			|ru = 'Установите и запустите <a href = ""%1"">тонкий клиент 1С:Предприятия для Windows (32-bit)</a>,
			|   в котором доступно больше устройств и настроек сканирования.';
			|en = 'Install the <a href = ""%1"">1C:Enterprise thin client for Windows x86</a>.
			|It supports more scanners and settings.'; fa = 'Install the <a href = ""%1"">1C:Enterprise thin client for Windows x86</a>.
			|It supports more scanners and settings.';
			|it = 'Install the <a href = ""%1"">1C:Enterprise thin client for Windows x86</a>.
			|It supports more scanners and settings.';
			|pl = 'Install the <a href = ""%1"">1C:Enterprise thin client for Windows x86</a>.
			|It supports more scanners and settings.';
			|tr = 'Daha fazla cihaz ve tarama ayarı içeren <a href = ""%1"">Windows (32-bit) için 1C:Enterprise ince istemcisini</a>
			|kurun ve çalıştırın.'");
		Recommendation = StringFunctionsClientServer.SubstituteParametersToString(Template, "Run32BitClient");
		Recommendations.Add(Recommendation);
	EndIf;
	
	Items.Recommendations.Title = StringFunctionsClient.FormattedString(
		StrConcat(Recommendations, Chars.LF));
	
EndProcedure

&AtClient
Procedure Run32BitClient()
	
#If Not WebClient Then
	
	BinDir32 = StrReplace(BinDir(), "\Program Files\", "\Program Files (x86)\");
	ApplicationName = BinDir32 + "1cv8.exe";
	AppFile = New File(ApplicationName);
	If AppFile.Exists() Then 
		FileSystemClient.StartApplication(ApplicationName);
	Else
		SystemInfo = New SystemInfo();
		FileSystemClient.OpenURL(
			"https://releases.1c.ru/version_files?nick=Platform83&ver=" + SystemInfo.AppVersion);
	EndIf;
	
#EndIf
	
EndProcedure

&AtClient
Procedure RefreshStatus()
	
	Items.JPGQuality.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chất lượng (%1)';
																							|ru = 'Качество (%1)';
																							|en = 'Quality (%1)'; fa = 'Quality (%1)';
																							|it = 'Качество (%1)';
																							|pl = 'Quality (%1)';
																							|tr = 'Kalite (%1)'"), JPGQuality);
	Items.ScannedImageFormat.Enabled = False;
	Items.Resolution.Enabled = False;
	Items.Chromaticity.Enabled = False;
	Items.Rotation.Enabled = False;
	Items.PaperSize.Enabled = False;
	Items.DuplexScanning.Enabled = False;
	Items.DocumentAutoFeeder.Enabled = False;
	Items.CustomizeStandardSettings.Enabled = False;
	Items.ConvertToPDF.Enabled = False;
	Items.JPGQuality.Enabled = False;
	Items.TIFFDeflation.Enabled = False;
	Items.MultipageStorageFormat.Enabled = False;
	Items.MethodOfConversionToPDF.Enabled = False;
	Items.ShowScannerDialog.Enabled = False;
	
	CallbackDescription = New CallbackDescription("UpdateStateAfterInitialization", ThisObject);
	FilesOperationsInternalClient.InitAddIn(CallbackDescription, True);
EndProcedure

&AtClient
Procedure UpdateStateAfterInitialization(InitializationCheckResult, Context) Export
	Attachable_Module = InitializationCheckResult.Attached;
	
	If Not Attachable_Module Then
		Items.DeviceName.Enabled = False;
		Return;
	EndIf;
	Attachable_Module = InitializationCheckResult.Attachable_Module;
		
	If Not FilesOperationsInternalClient.IsReadyForScanning(ThisObject, Attachable_Module) Then
		Items.DeviceName.InputHint = NStr("vi = 'Hãy kiểm tra kết nối máy quét';
											|ru = 'Проверьте подключение сканера';
											|en = 'Check scanner connection'; fa = 'Check scanner connection';
											|it = 'Проверьте подключение сканера';
											|pl = 'Check scanner connection';
											|tr = 'Tarayıcı bağlantısını kontrol et'");
		Return;
	Else
		Items.DeviceName.InputHint = "";
	EndIf;
		
	If IsBlankString(DeviceName) Then
		Return;
	EndIf;
	
	ReadScannerSettingsAndUpdateValues(False);
	
EndProcedure

&AtClient
Procedure ReadScannerSettings()
	Modified = True;
	Items.DuplexScanning.Enabled = False;
	Items.DocumentAutoFeeder.Enabled = False;
	
	If IsBlankString(DeviceName) Then
		Items.Rotation.Enabled = False;
		Items.PaperSize.Enabled = False;
		Return;
	EndIf;

	ReadScannerSettingsAndUpdateValues(True);
	
EndProcedure

&AtClient
Procedure ReadScannerSettingsAndUpdateValues(ShouldUpdateValues)

	Items.ScannedImageFormat.Enabled = True;
	Items.Resolution.Enabled = True;
	Items.Chromaticity.Enabled = True;
	Items.CustomizeStandardSettings.Enabled = True;
	Items.ConvertToPDF.Enabled = True;
	Items.JPGQuality.Enabled = True;
	Items.TIFFDeflation.Enabled = True;
	Items.MultipageStorageFormat.Enabled = True;
	Items.MethodOfConversionToPDF.Enabled = True;
	Items.ShowScannerDialog.Enabled = True;
	
	PermissionNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "XRESOLUTION");
	ChromaticityNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "PIXELTYPE");
	RotationNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "ROTATION");
	PaperSizeNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "SUPPORTEDSIZES");
	DuplexScanningNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "DUPLEX");
	DocumentAutoFeederNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module, 
		DeviceName, "FEEDER");
	
	Items.Rotation.Enabled = (RotationNumber <> -1);
	Items.PaperSize.Enabled = (PaperSizeNumber <> -1);
	
	Items.DuplexScanning.Enabled = (DuplexScanningNumber <> -1);
	If ShouldUpdateValues Then
		UpdateValue(DuplexScanning, ?((DuplexScanningNumber = 1), True, False), Modified);
	EndIf;
	Items.DocumentAutoFeeder.Enabled = (DocumentAutoFeederNumber <> -1);
	If ShouldUpdateValues Then
		UpdateValue(DocumentAutoFeeder, ?((DocumentAutoFeederNumber = 1), True, False), Modified);
		ConvertScannerParametersToEnums(
			PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber);
		
		ProcessScanDialogUsage();
	EndIf;

EndProcedure

&AtServer
Procedure ConvertScannerParametersToEnums(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber) 
	
	Result = FilesOperationsInternal.ScannerParametersInEnumerations(PermissionNumber, ChromaticityNumber, 
		RotationNumber, PaperSizeNumber);
	UpdateValue(Resolution, Result.Resolution, Modified);
	UpdateValue(Chromaticity, Result.Chromaticity, Modified);
	UpdateValue(Rotation, Result.Rotation, Modified);
	UpdateValue(PaperSize, Result.PaperSize, Modified);
	
EndProcedure

&AtClient
Procedure ProcessChangesUseImageMagick()
	
	Items.PathToConverterApplication.Enabled = UseImageMagickToConvertToPDF;
	
EndProcedure

&AtServer
Procedure InstallHints()
	
	FormatTooltip = "";
	ExtendedTooltip = String(Items.ConvertToPDF.ExtendedTooltip.Title); 
	Hints = StrSplit(ExtendedTooltip, Chars.LF);
	CurFormat = String(ScannedImageFormat);
	For Each ToolTip In Hints Do
		If StrStartsWith(ToolTip, CurFormat) Then
			 FormatTooltip = ToolTip;
		EndIf;
	EndDo;
	
	Items.SinglePageDocumentFormatDetails.Title = FormatTooltip;
	
EndProcedure

&AtClient
Procedure OKCompletion(UserScanSettings)
	FilesOperationsClient.SaveUserScanSettings(UserScanSettings);
	Result = New Structure("Rescanning", Rescanning);
	Close(Result);
EndProcedure

&AtClient
Procedure AfterCheckInstalledConversionApp(RunResult, ExternalContext) Export
	If StrFind(RunResult.OutputStream, "ImageMagick") = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chỉ ra sai đường dẫn đến ứng dụng %1.';
				|ru = 'Ошибочно указан путь к приложению %1.';
				|en = 'Specified path to the %1 application is incorrect.'; fa = 'Specified path to the %1 application is incorrect.';
				|it = 'Ошибочно указан путь к приложению %1.';
				|pl = 'Specified path to the %1 application is incorrect.';
				|tr = '%1 uygulamasına yanlış yol belirtildi.'"), "ImageMagick"); 
		CommonClient.MessageToUser(MessageText, , "PathToConverterApplication");
	ElsIf Not ExternalContext.FillingCheckError Then
		OKCompletion(ExternalContext.UserScanSettings);
	EndIf;
EndProcedure

&AtClient
Procedure ProcessScanDialogUsage()
	
	Items.ScanningParametersGroup.Enabled = Not ShowScannerDialog;
	Items.ScannedImageFormat.Enabled = Not ShowScannerDialog;
	Items.JPGQuality.Enabled = Not ShowScannerDialog;
	Items.TIFFDeflation.Enabled = Not ShowScannerDialog;
	Items.Resolution.MarkIncomplete = Not ShowScannerDialog;
	Items.Chromaticity.MarkIncomplete = Not ShowScannerDialog;

EndProcedure

&AtClientAtServerNoContext
Procedure UpdateValue(Receiver, Source, Modified)
	Modified = Modified Or Receiver <> Source;
	Receiver = ?(ValueIsFilled(Source), Source, Receiver);
EndProcedure

&AtClient
Function IsScanFormOpen()
	For Each ClientApplicationWindow In GetWindows() Do
		For Each WindowContent In ClientApplicationWindow.Content Do
			If WindowContent.FormName = "DataProcessor.Scanning.Form.ScanningResult" Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	Return False;
EndFunction

&AtClient
Procedure AfterTechnicalInfoReceived(Result, Context) Export
	Items.ScanningError.Visible = False;
EndProcedure

&AtServer
Procedure AdaptForLinux()
	Items.ShowScannerDialog.Visible = False;
	Items.Rotation.Visible = False;
	AvailableFormats = New Array;
	AvailableFormats.Add(Enums.ScannedImageFormats.PNG);
	AvailableFormats.Add(Enums.ScannedImageFormats.JPG);
	Items.ScannedImageFormat.ChoiceList.LoadValues(AvailableFormats);
	Items.ScannedImageFormat.ListChoiceMode = True;
	If AvailableFormats.Find(ScannedImageFormat) = Undefined Then
		ScannedImageFormat = Enums.ScannedImageFormats.PNG;
		Modified = True;
	EndIf;
	Items.PathToConverterApplication.Visible = False; 
EndProcedure

&AtClient
Procedure AfterScanDirAvailabilityChecked(Result, ExternalContext) Export
	
	UserScanSettings = ExternalContext.UserScanSettings;
	FillingCheckError = ExternalContext.FillingCheckError;
	
	If Not Result.Success Then
		ErrorText = NStr("vi = 'Thư mục nhật ký quét không được phép để ghi lại. Hãy chọn thư mục khác.';
						|ru = 'Каталог журнала сканирования недоступен для записи. Выберите другой каталог.';
						|en = 'Cannot write to the specified directory. Choose another directory.'; fa = 'Cannot write to the specified directory. Choose another directory.';
						|it = 'Каталог журнала сканирования недоступен для записи. Выберите другой каталог.';
						|pl = 'Cannot write to the specified directory. Choose another directory.';
						|tr = 'Tarama günlüğü dizini kayıt için uygun değildir. Başka bir dizin seçin.'");
		CommonClient.MessageToUser(ErrorText, , "ScanLogCatalog");
		FillingCheckError = True;
	EndIf;
	
	If UserScanSettings.UseImageMagickToConvertToPDF Then
		If Not ValueIsFilled(UserScanSettings.PathToConverterApplication) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa chỉ ra đường dẫn đến ứng dụng %1.';
					|ru = 'Не указан путь к приложению %1.';
					|en = 'Path to %1 is not specified.'; fa = 'Path to %1 is not specified.';
					|it = 'Path to %1 is not specified.';
					|pl = 'Path to %1 is not specified.';
					|tr = '%1 uygulamasının yolu yanlış belirtildi.'"), 
				"ImageMagick");
			CommonClient.MessageToUser(ErrorText, , "PathToConverterApplication");
			FillingCheckError = True;
		Else
			Context = New Structure;
			Context.Insert("Context", UserScanSettings);
			Context.Insert("FillingCheckError", FillingCheckError);
			Context.Insert("UserScanSettings", UserScanSettings);
			CheckResultHandler = New CallbackDescription("AfterCheckInstalledConversionApp", ThisObject, 
				Context);
			FilesOperationsClient.StartCheckConversionAppPresence(UserScanSettings.PathToConverterApplication, 
				CheckResultHandler);
		EndIf;
	ElsIf Not FillingCheckError Then
		OKCompletion(UserScanSettings); 
	EndIf;
	
EndProcedure

#EndRegion
