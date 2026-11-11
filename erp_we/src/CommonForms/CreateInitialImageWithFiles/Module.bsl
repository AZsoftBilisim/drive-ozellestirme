///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NodeMetadata = Parameters.Node.Metadata(); // MetadataObjectExchangePlan
	Manager = ExchangePlans[NodeMetadata.Name];
	
	If Parameters.Node = Manager.ThisNode() Then
		Raise
			NStr("vi = 'Không thể tạo ảnh ban đầu đối với nút này';
				|ru = 'Создание начального образа для данного узла невозможно.';
				|en = 'Cannot create an initial image for this node.'; fa = 'Cannot create an initial image for this node.';
				|it = 'Non è possibile creare l''immagine iniziale per questo nodo.';
				|pl = 'Utworzenie obrazu początkowego dla danego węzła nie jest możliwe.';
				|tr = 'Bu ünite için ilk resim oluşturulamıyor.'");
	Else
		InfobaseKind = 0; // File infobase.
		DBMSType = "";
		Node = Parameters.Node;
		CanCreateFileInfobase = True;
		If Common.IsLinuxServer() Then
			CanCreateFileInfobase = False;
		EndIf;
		
		LocaleCodes = GetAvailableLocaleCodes();
		FileModeInfobaseLanguage = Items.Find("FileModeInfobaseLanguage");
		ClientServerModeInfobaseLanguage = Items.Find("ClientServerModeInfobaseLanguage");
		
		FileInfobaseLanguages = FileModeInfobaseLanguage.ChoiceList; // ValueList
		ServerBaseLanguages = ClientServerModeInfobaseLanguage.ChoiceList; // ValueList
		For Each Code In LocaleCodes Do
			Presentation = LocaleCodePresentation(Code);
			FileInfobaseLanguages.Add(Code, Presentation);
			ServerBaseLanguages.Add(Code, Presentation);
		EndDo;
		
		Language = InfoBaseLocaleCode();
		
	EndIf;
	
	HasFilesInVolumes = False;
	
	If FilesOperations.HasFileStorageVolumes() Then
		HasFilesInVolumes = FilesOperationsInternal.HasFilesInVolumes();
	EndIf;
	
	WindowsOSServers = Common.IsWindowsServer();
	If Common.FileInfobase() Then
		Items.FileInfobaseFullNameLinux.Visible = Not WindowsOSServers;
		Items.FullFileInfobaseName.Visible = WindowsOSServers;
	EndIf;
	
	If HasFilesInVolumes Then
		If WindowsOSServers Then
			Items.FullFileInfobaseName.AutoMarkIncomplete = True;
			Items.VolumesFilesArchivePath.AutoMarkIncomplete = True;
		Else
			Items.FileInfobaseFullNameLinux.AutoMarkIncomplete = True;
			Items.PathToVolumeFilesArchiveLinux.AutoMarkIncomplete = True;
		EndIf;
	Else
		Items.PathToVolumeFilesArchiveGroup.Visible = False;
	EndIf;
	
	If Not Common.FileInfobase() Then
		Items.VolumesFilesArchivePath.InputHint = NStr("vi = '\ tên máy chủ\resource\files.zip';
														|ru = '\\имя сервера\resource\files.zip';
														|en = '\\server name\resource\files.zip'; fa = '\\server name\resource\files.zip';
														|it = '\\ nome server\resource\files.zip';
														|pl = '\\ nazwa serwera\resource\files.zip';
														|tr = '\\server name\resource\files.zip'");
		Items.VolumesFilesArchivePath.ChoiceButton = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.FormPages.CurrentPage = Items.RawData;
	Items.CreateInitialImage.Visible = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobaseKindOnChange(Item)
	
	// Switch the parameters page.
	Pages = Items.Find("Pages");
	Pages.CurrentPage = Pages.ChildItems[InfobaseKind];
	
	If InfobaseKind = 0 Then
		Items.VolumesFilesArchivePath.InputHint = "";
		Items.VolumesFilesArchivePath.ChoiceButton = True;
	Else
		Items.VolumesFilesArchivePath.InputHint = NStr("vi = '\ tên máy chủ\resource\files.zip';
														|ru = '\\имя сервера\resource\files.zip';
														|en = '\\server name\resource\files.zip'; fa = '\\server name\resource\files.zip';
														|it = '\\ nome server\resource\files.zip';
														|pl = '\\ nazwa serwera\resource\files.zip';
														|tr = '\\server name\resource\files.zip'");
		Items.VolumesFilesArchivePath.ChoiceButton = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure VolumesFilesArchivePathStartChoice(Item, ChoiceData, StandardProcessing)
	
	SaveFileHandler(
		Item,
		"WindowsVolumesFilesArchivePath",
		StandardProcessing,
		"files.zip",
		"Archives zip(*.zip)|*.zip");
	
EndProcedure

&AtClient
Procedure FullFileInfobaseNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SaveFileHandler(
		Item,
		"FullWindowsFileInfobaseName",
		StandardProcessing,
		"1Cv8.1CD",
		"Any file(*.*)|*.*");
	
EndProcedure

&AtClient
Procedure FullFileInfobaseNameOnChange(Item)
	
	If IsBlankString(FullWindowsFileInfobaseName) Then
		Return;
	EndIf;
	
	ErrorMessage = "";
	If Not FullFileInfobaseNameCheckAtServer(FullWindowsFileInfobaseName, ErrorMessage) Then
		FullWindowsFileInfobaseName = "";
		If Not IsBlankString(ErrorMessage) Then
			ShowMessageBox(, ErrorMessage);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DBMSTypeOnChange(Item)
	
	DateOffset = ?(DBMSType = "MSSQLServer", 2000, 0);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateInitialImage(Command)
	
	ClearMessages();
	If InfobaseKind = 0 And Not CanCreateFileInfobase Then
		
		Raise
			NStr("vi = 'Không hỗ trợ tạo mẫu ban đầu của cơ sở thông tin file-server
			           |trên nền tảng này.';
			           |ru = 'Создание начального образа файловой информационной базы
			           |на данной платформе не поддерживается.';
			           |en = 'Creation of initial images for file infobases
			           |is not supported on this platform.'; fa = 'Creation of initial images for file infobases
			           |is not supported on this platform.';
			           |it = 'La creazione di un''immagine iniziale del database informatico di file
			           |su questa piattaforma non è supportata.';
			           |pl = 'Utworzenie obrazu początkowego plikowej bazy informacyjnej
			           |na danej platformie nie jest obsługiwane.';
			           |tr = 'Bu platformda Infobase dosyasının 
			           |ilk resminin oluşturulması desteklenmemektedir.'");
	Else
		ProgressPercent = 0;
		ProgressAdditionalInformation = "";
		JobParameters = New Structure;
		JobParameters.Insert("Node", Node);
		JobParameters.Insert("WindowsVolumesFilesArchivePath", WindowsVolumesFilesArchivePath);
		JobParameters.Insert("PathToVolumeFilesArchiveLinux", PathToVolumeFilesArchiveLinux);
		
		If InfobaseKind = 0 Then
			// File initial image.
			JobParameters.Insert("FormUniqueID", UUID);
			JobParameters.Insert("Language", Language);
			JobParameters.Insert("FullWindowsFileInfobaseName", FullWindowsFileInfobaseName);
			JobParameters.Insert("FileInfobaseFullNameLinux", FileInfobaseFullNameLinux);
		Else
			// Server initial image.
			ConnectionString =
				"Srvr="""       + Server + """;"
				+ ?(ValueIsFilled(ClusterAdministratorName), "SUsr=""" + ClusterAdministratorName + """;", "")
				+ ?(ValueIsFilled(ClusterAdministratorPassword), "SPwd=""" + ClusterAdministratorPassword + """;", "")
				+ "Ref="""      + BaseName + """;"
				+ "DBMS="""     + DBMSType + """;"
				+ "DBSrvr="""   + DataBaseServer + """;"
				+ "DB="""       + DataBaseName + """;"
				+ "DBUID="""    + DatabaseUser + """;"
				+ "DBPwd="""    + UserPassword + """;"
				+ "SQLYOffs=""" + Format(DateOffset, "NG=") + """;"
				+ "Locale="""   + Language + """;"
				+ "SchJobDn=""" + ?(SetScheduledJobLock, "Y", "N") + """;";
			
			JobParameters.Insert("ConnectionString", ConnectionString);
		EndIf;
		Result = PrepareDataToCreateInitialImage(JobParameters, InfobaseKind);
		If TypeOf(Result) = Type("Structure") Then
			If Result.DataReady Then
				JobParametersAddress = PutToTempStorage(JobParameters, UUID);
				CallbackDescription = New CallbackDescription("RunCreateInitialImage", ThisObject);
				If Result.ConfirmationRequired Then
					ShowQueryBox(CallbackDescription, Result.QueryText, QuestionDialogMode.YesNo);
				Else
					RunCallback(CallbackDescription, DialogReturnCode.Yes);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.StatusError.Visible = False;
	Items.Back.Visible = False;
	
	Items.StatusDone.Visible = True;
	Items.CreateInitialImage.Visible = True;
	Items.FormPages.CurrentPage = Items.RawData;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function FullFileInfobaseNameCheckAtServer(FullFileInfobaseName, ErrorMessage = "")
	
	FullFileInfobaseName = TrimAll(FullFileInfobaseName);
	
	PathStructure = CommonClientServer.ParseFullFileName(FullFileInfobaseName);
	If Not IsBlankString(PathStructure.Path) Then
		PathToFile = PathStructure.Path;
		
		If IsBlankString(PathStructure.Extension) Then
			PathToFile = PathStructure.FullName; 
			FullFileInfobaseName = CommonClientServer.GetFullFileName(PathStructure.FullName, "1Cv8.1CD");
		EndIf;
		
		If FindFiles(PathToFile).Count() = 0 Then
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thư mục ""%1"" không tồn tại hoặc không thể truy cập được.
				|Hãy kiểm tra lại đường dẫn.';
				|ru = 'Папка ""%1"" не существует или не доступна.
				|Проверьте правильность указания пути.';
				|en = 'Folder ""%1"" does not exist or is unavailable.
				|Make sure that the path is correct.'; fa = 'Folder ""%1"" does not exist or is unavailable.
				|Make sure that the path is correct.';
				|it = 'La cartella ""%1"" non esiste o non è disponibile.
				| Verifica che il percorso indicato sia corretto.';
				|pl = 'Folder ""%1"" nie istnieje lub nie jest dostępny.
				|Sprawdź poprawność podanej ścieżki.';
				|tr = '""%1"" klasörü mevcut değil ya da kullanılamaz.
				|Yolun doğruluğundan emin olun.'"),
				PathToFile);
			Return False;
		EndIf;
	Else
		ErrorMessage = NStr("vi = 'Chỉ định đường dẫn đầy đủ đến tệp cơ sở thông tin.';
							|ru = 'Укажите полный путь к файлу информационной базы.';
							|en = 'Please specify the full infobase path.'; fa = 'Please specify the full infobase path.';
							|it = 'Indica il percorso completo al file del database.';
							|pl = 'Podaj pełną ścieżkę do pliku bazy informacyjnej.';
							|tr = 'Infobase dosyasına giden tam yolu belirtin.'");
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure SaveFileHandler(
		Item,
		PropertyName,
		StandardProcessing,
		FileName,
		Filter = "")
	
	StandardProcessing = False;
	
	Context = New Structure;
	Context.Insert("Item",     Item);
	Context.Insert("PropertyName", PropertyName);
	Context.Insert("FileName",    FileName);
	Context.Insert("Filter",      Filter);
	
	Dialog = New FileDialog(FileDialogMode.Save);
	
	Dialog.Title = NStr("vi = 'Hãy chọn tệp để lưu';
						|ru = 'Выберите файл для сохранения';
						|en = 'Select file to save'; fa = 'Select file to save';
						|it = 'Scegliete un file per il salvataggio';
						|pl = 'Wybierz plik do zapisania';
						|tr = 'Kaydedilecek dosyayı seçin'");
	Dialog.Multiselect = False;
	Dialog.Preview = False;
	Dialog.Filter = Context.Filter;
	Dialog.FullFileName =
		?(ThisObject[Context.PropertyName] = "",
			Context.FileName,
			ThisObject[Context.PropertyName]);
	
	ChoiceDialogNotificationDetails = New CallbackDescription(
		"FileSaveHandlerAfterChoiceInDialog", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotificationDetails, Dialog);
	
EndProcedure

// Parameters:
//   SelectedFiles - Array
//                  - Undefined
//   Context - Structure
//
&AtClient
Procedure FileSaveHandlerAfterChoiceInDialog(SelectedFiles, Context) Export
	
	If SelectedFiles <> Undefined
		And SelectedFiles.Count() = 1 Then
		
		ThisObject[Context.PropertyName] = SelectedFiles[0];
		If Context.Item = Items.FullFileInfobaseName Then
			FullFileInfobaseNameOnChange(Context.Item);
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PrepareDataToCreateInitialImage(JobParameters, InfobaseKind)
	
	// Writing the parameters of attaching node to constant.
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Cancel = False;
		
		ModuleDataExchangeCreationWizard = Common.CommonModule("DataProcessors.DataExchangeCreationWizard");
		DataExchangeCreationWizard = ModuleDataExchangeCreationWizard.Create();
		DataExchangeCreationWizard.Initialize(JobParameters.Node);
		
		Try
			ModuleDataExchangeCreationWizard.ExportConnectionSettingsForSubordinateDIBNode(
				DataExchangeCreationWizard);
		Except
			Cancel = True;
			WriteLogEvent(NStr("vi = 'Trao đổi dữ liệu';
								|ru = 'Обмен данными';
								|en = 'Data exchange'; fa = 'تبادل داده';
								|it = 'Scambio di dati';
								|pl = 'Wymiana danych';
								|tr = 'Veri değişimi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		If Cancel Then
			Return Undefined;
		EndIf;
		
	EndIf;
	
	If InfobaseKind = 0 Then
		// The initial file image.
		// A function for processing, validating, and preparing parameters.
		Result = FilesOperationsInternal.PrepareDataToCreateFileInitialImage(JobParameters);
	Else
		// The initial server image.
		// A function for processing, validating, and preparing parameters.
		Result = FilesOperationsInternal.PrepareDataToCreateServerInitialImage(JobParameters);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure RunCreateInitialImage(Result, Context) Export
	
	If Result = DialogReturnCode.Yes Then
		ProgressPercent = 0;
		ProgressAdditionalInformation = "";
		GoToWaitPage();
		AttachIdleHandler("StartInitialImageCreation", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartInitialImageCreation()
	
	Result = CreateInitialImageAtServer(InfobaseKind);
	If Result = Undefined Then
		Return;
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("CreateInitialImageAtServerCompletion", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.ExecutionProgressNotification = New CallbackDescription("CreateInitialImageAtServerProgress", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtClient
Procedure GoToWaitPage()
	Items.FormPages.CurrentPage = Items.InitialImageCreationWaiting;
	Items.CreateInitialImage.Visible = False;
EndProcedure

&AtServer
Function CreateInitialImageAtServer(Val InfobaseKind)
	
	If IsTempStorageURL(JobParametersAddress) Then
		JobParameters = GetFromTempStorage(JobParametersAddress);
		If TypeOf(JobParameters) = Type("Structure") Then
			// Start background job.
			ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
			
			If InfobaseKind = 0 Then
				ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo ảnh ban đầu file server';
																	|ru = 'Создание файлового начального образа';
																	|en = 'Create initial file image'; fa = 'Create initial file image';
																	|it = 'Creazione di un immagine iniziale del file';
																	|pl = 'Tworzenie plikowego obrazu początkowego';
																	|tr = 'Dosya başlangıç görüntüsü oluşturma'");
				Return TimeConsumingOperations.ExecuteInBackground(
					"FilesOperationsInternal.CreateFileInitialImageAtServer",
					JobParameters,
					ExecutionParameters);
			Else
				ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo ảnh ban đầu client server';
																	|ru = 'Создание серверного начального образа';
																	|en = 'Create initial server image'; fa = 'Create initial server image';
																	|it = 'Creazione di un immagine iniziale del server';
																	|pl = 'Tworzenie serwerowego obrazu początkowego';
																	|tr = 'Sunucu tabanlı ilk görüntü oluşturma'");
				Return TimeConsumingOperations.ExecuteInBackground(
					"FilesOperationsInternal.CreateServerInitialImageAtServer",
					JobParameters,
					ExecutionParameters);
			EndIf;
		EndIf;
	EndIf;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure CreateInitialImageAtServerCompletion(Result, AdditionalParameters) Export
	
	ProgressAdditionalInformation = "";
	
	If Result = Undefined Then
		ProgressPercent = 0;
		Items.StatusError.Title = NStr("vi = 'Người quản trị đã hủy thao tác.';
										|ru = 'Действие отменено администратором.';
										|en = 'The operation is canceled by administrator.'; fa = 'The operation is canceled by administrator.';
										|it = 'L''azione è stata annullata dall''amministratore.';
										|pl = 'Działanie zostało anulowane przez administratora.';
										|tr = 'Eylem yönetici tarafından iptal edildi'");
		ExecuteGoResult();
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ProgressPercent = 0;
		Items.StatusError.Title = NStr("vi = 'Không thể tạo ảnh ban đầu do nguyên nhân:';
										|ru = 'Не удалось создать начальный образ по причине:';
										|en = 'Cannot create an initial image. Reason:'; fa = 'Cannot create an initial image. Reason:';
										|it = 'Impossibile creare l''immagine iniziale a causa di:';
										|pl = 'Tworzenie obrazu początkowego nie powiodło się z powodu:';
										|tr = 'İlk görüntü aşağıdaki nedenle oluşturulamadı:'") + "
			|" + Result.BriefErrorDescription;
		ExecuteGoResult();
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	ProgressPercent = 100;
	ExecuteGoResult();
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Undefined
//
&AtClient
Procedure CreateInitialImageAtServerProgress(Result, AdditionalParameters) Export
	
	If Result.Status = "Running"
	   And Result.Progress <> Undefined Then
		
		ProgressPercent = Result.Progress.Percent;
		ProgressAdditionalInformation = Result.Progress.Text;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteGoResult()
	Items.FormPages.CurrentPage = Items.Result;
	Items.CreateInitialImage.Visible = False;
	
	If ProgressPercent = 100 Then
		CompleteInitialImageCreation(Node);
	Else
		Items.StatusDone.Visible = False;
		Items.StatusError.Visible = True;
		Items.Back.Visible = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CompleteInitialImageCreation(ExchangeNode)
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CompleteInitialImageCreation(ExchangeNode);
	EndIf;
	
EndProcedure

#EndRegion
