///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If SaaSOperations.DataSeparationEnabled() Then
		Cancel = True;
		Return;
	EndIf;
	
	FillInFormElementsAttributes();
	HandleInterruptedBootProcedure();
	SetExclusiveLockAndContinueImport();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ExclusiveLockSet And ValueIsFilled(TheHashSumOfTheFile) Then
		
		DialogTitle = NStr("vi = 'Để tiếp tục, cần tải lại tệp';
							|ru = 'Для продолжения необходимо повторно загрузить файл';
							|en = 'To continue, import the file again'; fa = 'To continue, import the file again';
							|it = 'Per continuare è necessario ripetere il download del file';
							|pl = 'W celu kontynuacji należy ponownie pobrać plik';
							|tr = 'Devam etmek için dosyayı tekrar içe aktarın'");
		
		If IsWebClient Then
			SelectDataFileInWebClient(DialogTitle);
		Else
			SelectDataFile(DialogTitle);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Or Not (ExclusiveLockSet Or ValueIsFilled(JobID)) Then
		Return;
	EndIf;
	
	Cancel = True;
	
	If ValueIsFilled(JobID) Then
		
		ShowQueryBox(
			New CallbackDescription("QuestionBeforeClosingCompletion", ThisObject),
			NStr("vi = 'Ngừng tải xuống dữ liệu?';
				|ru = 'Прервать загрузку данных?';
				|en = 'Do you want to cancel the data import?'; fa = 'Do you want to cancel the data import?';
				|it = 'Прервать загрузку данных?';
				|pl = 'Do you want to cancel the data import?';
				|tr = 'Veri dışa aktarma durdurulsun mu?'"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.No);
			
	Else
		
		CancelImportAndCloseForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If RestartProgramAtClosing Then
		RestartApplication();
	Else
		ExportImportDataClient.ShowAbortedDownloadDialogIfNecessary();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If IsWebClient Then
		SelectDataFileInWebClient();
	Else
		SelectDataFile();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContinueImport(Command)
	
	SetExclusiveLockAndContinueImport();
	
EndProcedure

&AtClient
Procedure UpdateSessionsList(Command)
	
	FillUserList();
	
EndProcedure

&AtClient
Procedure TerminateSession(Command)
	
	SelectedLinesNumber = Items.UsersList.SelectedRows.Count();
	
	If SelectedLinesNumber = 0 Then
		
		ShowMessageBox(
			,
			NStr("vi = 'Chưa chọn người sử dụng để kết thúc phiên làm việc.';
				|ru = 'Не выбраны пользователи для завершения сеансов.';
				|en = 'Please select users.'; fa = 'Please select users.';
				|it = 'Non sono selezionati utenti per terminare le sessioni di lavoro.';
				|pl = 'Brak użytkowników do ukończenia sesji.';
				|tr = 'Oturumları sonlandırmak için kullanıcılar seçilmez.'"));
		
		Return;
		
	ElsIf SelectedLinesNumber = 1
		And Items.UsersList.CurrentData.Session = InfoBaseSessionNumber Then
		
		ShowMessageBox(
			,
			NStr("vi = 'Không thể kết thúc phiên làm việc hiện tại. Để thoát khỏi chương trình, có thể đóng cửa sổ chính của chương trình.';
				|ru = 'Невозможно завершить текущий сеанс. Для выхода из программы можно закрыть главное окно программы.';
				|en = 'Cannot close the current session. To exit the application, close its main window.'; fa = 'Cannot close the current session. To exit the application, close its main window.';
				|it = 'Impossibile terminare la sessione corrente. Per uscire dal programma è possibile chiudere la finestra principale del programma.';
				|pl = 'Nie można ukończyć bieżącej sesji. Aby wyjść z programu, możesz zamknąć główne okno programu.';
				|tr = 'Mevcut oturum kapatılamıyor. Uygulamadan çıkmak için ana pencereyi kapatın.'"));
		
		Return;
		
	EndIf;
	
	SessionsNumbers = New Array();
	
	For Each RowID In Items.UsersList.SelectedRows Do
		
		SessionNumber = UsersList.FindByID(RowID).Session;
		
		If SessionNumber <> InfoBaseSessionNumber Then
			SessionsNumbers.Add(SessionNumber);
		EndIf;
		
	EndDo;
	
	If CommonClient.DataSeparationEnabled()
	   And CommonClient.SeparatedDataUsageAvailable() Then
		
		StandardProcessing = True;
		AdditionalParameters = New Structure("SessionsNumbers", SessionsNumbers);
		Notification = New CallbackDescription("AfterSessionTermination", ThisObject, AdditionalParameters);
		
		SSLSubsystemsIntegrationClient.OnEndSessions(
			ThisObject,
			SessionsNumbers,
			StandardProcessing,
			Notification);
		
	ElsIf PromptForIBAdministrationParameters Then
		
		CallbackDescription = New CallbackDescription("TerminateSessionContinued", ThisObject, SessionsNumbers);
		FormCaption = NStr("vi = 'Kết thúc phiên làm việc';
							|ru = 'Завершение сеанса';
							|en = 'Close session'; fa = 'بستن جلسه';
							|it = 'Chiudere la sessione';
							|pl = 'Zakończenie sesji';
							|tr = 'Oturumu sonlandırma'");
		NoteLabel = NStr("vi = 'Để kết thúc phiên làm việc,
			|hãy nhập các tham số quản trị cụm máy chủ';
			|ru = 'Для завершения сеанса введите параметры
			|администрирования кластера серверов';
			|en = 'To end the session, enter
			|the server cluster administration parameters'; fa = 'To end the session, enter
			|the server cluster administration parameters';
			|it = 'Per completare la sessione, inserire i parametri
			|di amministrazione del cluster di server';
			|pl = 'Aby zakończyć sesję, wprowadź parametry
			|administrowania klastera serwerów';
			|tr = 'Oturumu sonlandırmak için sunucu parametrelerinin 
			|yönetim ayarlarını girin'");
		
		IBConnectionsClient.ShowAdministrationParameters(
			CallbackDescription,
			False,
			True,
			AdministrationParameters,
			FormCaption,
			NoteLabel);
		
	Else
		
		TerminateSessionContinued(AdministrationParameters, SessionsNumbers);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EndOfSessions

&AtClient
Procedure TerminateSessionContinued(Result, SessionsArray) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AdministrationParameters = Result;
	
	SessionStructure = New Structure();
	SessionStructure.Insert("Property", "Number");
	SessionStructure.Insert("ComparisonType", ComparisonType.InList);
	SessionStructure.Insert("Value", SessionsArray);
	
	Filter = CommonClientServer.ValueInArray(SessionStructure);
	
	Try
		DeleteInfobaseSessionsAtServer(AdministrationParameters, Filter)
	Except
		PromptForIBAdministrationParameters = True;
		Raise;
	EndTry;
	
	PromptForIBAdministrationParameters = False;
	
	AfterSessionTermination(DialogReturnCode.OK, New Structure("SessionsNumbers", SessionsArray));
	
EndProcedure

&AtClient
Procedure AfterSessionTermination(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	If AdditionalParameters.SessionsNumbers.Count() > 1 Then
		
		NotificationText1 = StrTemplate(
			NStr("vi = 'Đã kết thúc phiên làm việc %1.';
				|ru = 'Сеансы %1 завершены.';
				|en = 'Sessions %1 are closed.'; fa = 'Sessions %1 are closed.';
				|it = 'Le sessioni %1 sono terminate.';
				|pl = 'Sesje %1 zakończone.';
				|tr = 'Oturumlar %1sona erdi.'"),
			StrConcat(AdditionalParameters.SessionsNumbers, ","));
		
		ShowUserNotification(NStr("vi = 'Kết thúc phiên làm việc';
									|ru = 'Завершение сеансов';
									|en = 'Sessions closed'; fa = 'Sessions closed';
									|it = 'Chiudere le sessioni';
									|pl = 'Zakończenie sesji';
									|tr = 'Oturumları sonlandır'"), , NotificationText1);
		
	Else
		
		NotificationText1 = StrTemplate(
			NStr("vi = 'Đã hoàn tất phiên làm việc %1.';
				|ru = 'Сеанс %1 завершен.';
				|en = 'Session %1 is closed.'; fa = 'Session %1 is closed.';
				|it = 'La sessione %1 è terminata.';
				|pl = 'Sesja %1 zakończona.';
				|tr = 'Oturum %1sona erdi.'"),
			AdditionalParameters.SessionsNumbers[0]);
		
		ShowUserNotification(NStr("vi = 'Hoàn tất phiên làm việc';
									|ru = 'Завершение сеанса';
									|en = 'Session closed'; fa = 'Session closed';
									|it = 'Chiudere la sessione';
									|pl = 'Zakończenie sesji';
									|tr = 'Oturumu sonlandırma'"), , NotificationText1);
		
	EndIf;
	
	SetExclusiveLockAndContinueImport();
	
EndProcedure

&AtServer
Procedure FillUserList()
	
	UsersList.Clear();
	
	For Each IBSession In GetInfoBaseSessions() Do
		
		TableRow = UsersList.Add();
		TableRow.Computer = IBSession.ComputerName;
		TableRow.WorkStart = IBSession.SessionStarted;
		TableRow.Application = ApplicationPresentation(IBSession.ApplicationName);
		TableRow.Session = IBSession.SessionNumber;
		
		If TypeOf(IBSession.User) = Type("InfoBaseUser")
		   And ValueIsFilled(IBSession.User.Name) Then
			TableRow.User = IBSession.User.Name;
		Else
			TableRow.User = Users.UnspecifiedUserFullName();
		EndIf;

		If IBSession.SessionNumber = InfoBaseSessionNumber Then
			TableRow.UserPictureNumber = 0;
		Else
			TableRow.UserPictureNumber = 1;
		EndIf;
		
	EndDo;
	
	If Not ExclusiveLockSet Then
		
		SetExclusiveLock();
		Items.GroupDecorationBlockingError.Visible = Not ExclusiveLockSet;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteInfobaseSessionsAtServer(Val AdministrationParameters, Val Filter)
	
	ClusterAdministration.DeleteInfobaseSessions(AdministrationParameters, , Filter);
	
EndProcedure

#EndRegion

#Region DataFileOperations

&AtClient
Async Procedure SelectDataFile(DialogTitle = Undefined)
	
	If Not ValueIsFilled(DialogTitle) Then
		DialogTitle = DataFileSelectionDialogTitle();
	EndIf;
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = DialogTitle;
	Dialog.Filter = DataFileSelectionDialogFilter();
	Dialog.FullFileName = ExportImportDataClientServer.NameOfDataUploadFile();
	Dialog.CheckFileExistence = True;
	Result = Await Dialog.ChooseAsync();
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	DataFile = Result[0];
	
	AfterSelectingDataFile();
	
EndProcedure

&AtClient
Procedure SelectDataFileInWebClient(DialogTitle = Undefined)
	
	If ValueIsFilled(TemporaryStorageFileName) Then
		DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
		TemporaryStorageFileName = "";
	EndIf;
	
	If Not ValueIsFilled(DialogTitle) Then
		DialogTitle = DataFileSelectionDialogTitle();
	EndIf;
	
	TemporaryStorageFileData = GetTemporaryStorageFile(UUID);
	TemporaryStorageFileName = TemporaryStorageFileData.FileName;

	TransferParameters = FilesCTLClient.FileLocationParameters();
	TransferParameters.FileNameOrAddress = TemporaryStorageFileName;
	TransferParameters.CallbackDescriptionOnCompletion = New CallbackDescription("ProcessFilePlacement", ThisObject);
	TransferParameters.BlockedForm = ThisObject;
	TransferParameters.TitleOfSelectionDialog = DialogTitle;
	TransferParameters.SelectionDialogFilter = DataFileSelectionDialogFilter();
	TransferParameters.FileNameOfSelectionDialog = ExportImportDataClientServer.NameOfDataUploadFile();
	
	FilesCTLClient.PlaceFileInteractively(TransferParameters);
	
EndProcedure

&AtClient
Procedure ProcessFilePlacement(Result, AdditionalParameters) Export
	
	VerificationResultReceived = False;
	
	If Result <> Undefined Then
		DataFile = Result.FileNameAtClient;
		CheckResult = CheckAvailabilityImportDataFileOnWebClient(TemporaryStorageFileName);
		VerificationResultReceived = True;
	EndIf;
	
	If Not VerificationResultReceived Or ValueIsFilled(CheckResult.ErrorText) Then
		DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
		TemporaryStorageFileName = "";
	EndIf;
	
	If VerificationResultReceived Then
		AfterCheckingDataFile(CheckResult);
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AfterSelectingDataFile()
	
	DataOfFilesBeingChecked = GetFileDataForDataImportVerification(DataFile);
	
	If Not ValueIsFilled(DataOfFilesBeingChecked.ErrorText) Then
		
		FilesAreAvailableOnServer = Await GetFilesAvailabilityOnServer(DataOfFilesBeingChecked.ListOfFiles);
		
		If Not FilesAreAvailableOnServer Then
			DataOfFilesBeingChecked = Await PlaceFilesBeingCheckedOnServer(DataOfFilesBeingChecked);
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(DataOfFilesBeingChecked.ErrorText) Then
		CheckResult = NewCheckingDataFileResult();
		CheckResult.ErrorText = DataOfFilesBeingChecked.ErrorText;
	Else
		CheckResult = CheckAvailabilityDataFileImport(DataOfFilesBeingChecked);
	EndIf;
	
	DeleteDataOfFilesBeingChecked(DataOfFilesBeingChecked);
	AfterCheckingDataFile(CheckResult);
	
EndProcedure

// Place the files being checked on the server.
// 
// Parameters:
//  DataOfFilesBeingChecked - See NewCheckedFilesData
// 
// Returns:
//  See NewCheckedFilesData
&AtClient
Async Function PlaceFilesBeingCheckedOnServer(DataOfFilesBeingChecked)
	
	ErrorTemplate = NStr("vi = 'Không thể kiểm tra tệp dữ liệu: %1';
						|ru = 'Не удалось проверить файл данных: %1';
						|en = 'Cannot check the data file: %1'; fa = 'Cannot check the data file: %1';
						|it = 'Не удалось проверить файл данных: %1';
						|pl = 'Cannot check the data file: %1';
						|tr = 'Veri dosyası kontrol edilemedi: %1'");
	TransmittedFiles = New Array();
	
	For Each FileName In DataOfFilesBeingChecked.ListOfFiles Do
		TransmittedFiles.Add(New TransferableFileDescription(FileName));
	EndDo;
	
	TransmissionResult = Await PutFilesToServerAsync(, , TransmittedFiles, UUID);
	
	If TransmissionResult = Undefined Then
		
		DataOfFilesBeingChecked.ErrorText = StrTemplate(
			ErrorTemplate,
			NStr("vi = 'đã hủy bỏ sắp xếp tệp vào server.';
				|ru = 'отменено помещение файлов на сервер.';
				|en = 'files are not placed on the server.'; fa = 'files are not placed on the server.';
				|it = 'отменено помещение файлов на сервер.';
				|pl = 'files are not placed on the server.';
				|tr = 'dosyaların sunucuya yerleştirilmesi iptal edildi.'"));
		
	Else
		
		For Each FileDetails In TransmissionResult Do
			
			If FileDetails.PutFileCanceled Then
				
				DataOfFilesBeingChecked.ErrorText = StrTemplate(
					ErrorTemplate,
					NStr("vi = 'đã hủy bỏ sắp xếp tệp vào server.';
						|ru = 'отменено помещение файла на сервер.';
						|en = 'the file is not placed on the server.'; fa = 'the file is not placed on the server.';
						|it = 'отменено помещение файла на сервер.';
						|pl = 'the file is not placed on the server.';
						|tr = 'dosyanın sunucuya yerleştirilmesi iptal edildi.'"));
				
			ElsIf FileDetails.FileRef.File = Undefined Then 
				
				DataOfFilesBeingChecked.ErrorText = StrTemplate(
					ErrorTemplate,
					NStr("vi = 'không sử dụng được tệp được sắp xếp trên server.';
						|ru = 'помещаемый на сервер файл не доступен.';
						|en = 'the file to place on the server is unavailable.'; fa = 'the file to place on the server is unavailable.';
						|it = 'помещаемый на сервер файл не доступен.';
						|pl = 'the file to place on the server is unavailable.';
						|tr = 'sunucuya yerleştirilecek dosya mevcut değil.'"));
				
			EndIf;
			
			If ValueIsFilled(DataOfFilesBeingChecked.ErrorText) Then
				Break;
			EndIf;
			
			FileMatchFound = False;
			
			For Each ElementCheckedFile In DataOfFilesBeingChecked.CheckedFiles Do
				
				If ElementCheckedFile.Value = FileDetails.FileRef.File.FullName Then
					
					DataOfFilesBeingChecked.CheckedFiles[ElementCheckedFile.Key] = FileDetails.Address;
					FileMatchFound = True;
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not FileMatchFound Then
				
				DataOfFilesBeingChecked.ErrorText = StrTemplate(
					ErrorTemplate,
					NStr("vi = 'chưa tìm thấy sự tương ứng của tệp từ client trên server.';
						|ru = 'не найдено соответствие файла с клиента на сервере.';
						|en = 'file mapping from the client is not found on the server.'; fa = 'file mapping from the client is not found on the server.';
						|it = 'не найдено соответствие файла с клиента на сервере.';
						|pl = 'file mapping from the client is not found on the server.';
						|tr = 'istemciden sunucuya dosya eşleşmesi bulunamadı.'"));
				
				Break;
				
			EndIf;
			
		EndDo;
		
		If Not ValueIsFilled(DataOfFilesBeingChecked.ErrorText) Then
			DeleteDataOfFilesBeingChecked(DataOfFilesBeingChecked);
			DataOfFilesBeingChecked.ListOfFiles.Clear();
		EndIf;
		
	EndIf;
	
	Return DataOfFilesBeingChecked;
	
EndFunction

// After checking the data file.
// 
// Parameters:
//  CheckResult - See NewCheckingDataFileResult
&AtClient
Async Procedure AfterCheckingDataFile(CheckResult)
	
	Items.GroupDataFileErrorInformation.Visible = False;
	Items.GroupDataFileError.Visible = False;
	
	If ValueIsFilled(CheckResult.ErrorText) Then
		
		Items.DecorationDataFileError.Title = CheckResult.ErrorText;
		
		If ValueIsFilled(CheckResult.ErrorInfo) Then
			DataFileErrorInformation = CheckResult.ErrorInfo;
			Items.GroupDataFileErrorInformation.Visible = True;
		EndIf;
		
		Items.GroupDataFileError.Visible = True;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(CheckResult.Warnings) Then
		DisplayDataFileWarnings(CheckResult.Warnings);
	EndIf;
	
	StatusPresentation =
		ExportImportDataClientServer.ExportImportDataAreaPreparationStateView(True) 
		+ Chars.LF 
		+ ExportImportDataClientServer.LongTermOperationHint();
	
	Items.DownloadWizardPages.CurrentPage = Items.PageWait;
	Title = FormTitleByPageName(Items.DownloadWizardPages.CurrentPage.Name);
	
	DataFileIsAvailableOnServer = Await GetFilesAvailabilityOnServer(DataFile);
	
	If Not (IsWebClient Or DataFileIsAvailableOnServer) Then
		AttachIdleHandler("Attachable_PlaceDataFileOnServer", 0.1, True);
	Else
		StartDataImport();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure Attachable_PlaceDataFileOnServer()
	
	DataFileIsPlaced = Await PlaceDataFileOnServer();
	
	If Not DataFileIsPlaced Then
		Return;
	EndIf;
	
	StartDataImport();
	
EndProcedure

&AtClient
Async Function PlaceDataFileOnServer()
	
	ErrorInfo = Undefined;
	DataFileIsPlaced = False;
	
	Try
		
		TemporaryStorageFileData = GetTemporaryStorageFile(UUID, True);
		TemporaryStorageFileName = TemporaryStorageFileData.FileName;
		
		DataFileIsPlaced = Await FilesCTLClient.PlaceFileOnServer(
			DataFile, TemporaryStorageFileData.FullFileName);
		
	Except
		
		ErrorInfo = ErrorInfo();
		DataFileIsPlaced = False;
		
	EndTry;
	
	If DataFileIsPlaced Then
		Return True;
	EndIf;
	
	DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
	TemporaryStorageFileName = "";
	
	NoticeParameters = NewParametersNotificationErrorWarning();
	NoticeParameters.ToolTip = NStr("vi = 'Khi khởi động kết nhập dữ liệu đã xảy ra lỗi:';
									|ru = 'При запуске загрузки данных произошла ошибка:';
									|en = 'An error occurred when starting the data import:'; fa = 'An error occurred when starting the data import:';
									|it = 'При запуске загрузки данных произошла ошибка:';
									|pl = 'An error occurred when starting the data import:';
									|tr = 'Veri içe aktarma başlatma sırasında hata oluştu:'");
	NoticeParameters.Recommendation = NStr("vi = 'Cần thử lại kết nhập';
											|ru = 'Рекомендуется повторить попытку загрузки';
											|en = 'We recommend that you try to import again'; fa = 'We recommend that you try to import again';
											|it = 'Рекомендуется повторить попытку загрузки';
											|pl = 'We recommend that you try to import again';
											|tr = 'İçe aktarma yeniden denemek tavsiye ediliyor'");
	
	If ErrorInfo = Undefined Then
		NoticeParameters.Text = NStr("vi = 'Không thể sắp xếp tệp dữ liệu vào server.';
									|ru = 'Не удалось поместить файл данных на сервер.';
									|en = 'Cannot place the data file on the server.'; fa = 'Cannot place the data file on the server.';
									|it = 'Не удалось поместить файл данных на сервер.';
									|pl = 'Cannot place the data file on the server.';
									|tr = 'Veri dosyası sunucuya yerleştirilemedi.'");
	Else
		
		NoticeParameters.Text = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		NoticeParameters.WholeText = StrTemplate(
			NStr("vi = 'Khi sắp xếp tệp dữ liệu vào server đã xảy ra lỗi:
				 |%1';
				 |ru = 'При помещении файла данных на сервер произошла ошибка:
				 |%1';
				 |en = 'An error occurred when placing the data file on the server:
				 |%1'; fa = 'An error occurred when placing the data file on the server:
				 |%1';
				 |it = 'При помещении файла данных на сервер произошла ошибка:
				 |%1';
				 |pl = 'An error occurred when placing the data file on the server:
				 |%1';
				 |tr = 'Veri dosyası sunucuya yerleştirilirken hata oluştu: 
				 |%1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
	EndIf;
	
	ShowWarningErrors(NoticeParameters);
	
	Return False;
	
EndFunction

// Display data file warnings.
// 
// Parameters:
//  Warnings - Array of String - Warnings
&AtServer
Procedure DisplayDataFileWarnings(Warnings)
	
	NumberOfWarnings = Warnings.Count();
	WarningsTexts = New Array();
	
	For WarningNumber = 1 To NumberOfWarnings Do
		
		TotalWarnings = TotalWarnings + 1;
		WarningText = "● " + Warnings[WarningNumber - 1];
		TagName = "WarningDecoration_" + Format(TotalWarnings, "NG=0;");
		
		ItemDecoration = Items.Add(TagName, Type("FormDecoration"), Items.WarningsGroup);
		ItemDecoration.Type = FormDecorationType.Label;
		ItemDecoration.AutoMaxWidth = False;
		ItemDecoration.Title = WarningText;
		
		WarningsTexts.Add(WarningText);
		
	EndDo;
	
	NumerationItemOptions = "warning, warnings, warnings,, , , , , 0";
	NumberInWords = NumberInWords(TotalWarnings, , ",,,,,,,,0");
	SubjectAndNumberInWords = NumberInWords(TotalWarnings, , NumerationItemOptions);
	GroupTitle = StrTemplate(
		"%1 %2",
		Format(TotalWarnings, "NG=0;"),
		StrReplace(SubjectAndNumberInWords, NumberInWords, ""));
	
	Items.WarningsGroup.Title = GroupTitle;
	Items.GroupWarningWaiting.Visible = True;
	
	WriteLogEvent(
		EventLogEventName(),
		EventLogLevel.Warning,
		,
		,
		StrConcat(WarningsTexts, Chars.LF));

EndProcedure

// Check if the data file can be downloaded in the web client.
// 
// Parameters:
//  TempFileName - String
// 
// Returns:
//  See NewCheckingDataFileResult
&AtServerNoContext
Function CheckAvailabilityImportDataFileOnWebClient(Val TempFileName)
	
	TempFileFullName = FilesCTL.FullTemporaryStorageFileName(TempFileName);
	DataOfFilesBeingChecked = GetFileDataForDataImportVerification(TempFileFullName);
	
	If ValueIsFilled(DataOfFilesBeingChecked.ErrorText) Then
		CheckResult = NewCheckingDataFileResult();
		CheckResult.ErrorText = DataOfFilesBeingChecked.ErrorText;
	Else
		CheckResult = CheckAvailabilityDataFileImport(DataOfFilesBeingChecked);
	EndIf;
	
	DeleteDataOfFilesBeingChecked(DataOfFilesBeingChecked);
	
	Return CheckResult;
	
EndFunction

// Check if the data file can be downloaded.
// 
// Parameters:
//  DataOfFilesBeingChecked - See NewCheckedFilesData
// 
// Returns:
//  See NewCheckingDataFileResult
&AtServerNoContext
Function CheckAvailabilityDataFileImport(Val DataOfFilesBeingChecked)
	
	CheckResult = NewCheckingDataFileResult();
	DataOfFilesBeingChecked.ListOfFiles.Clear();
	
	For Each CheckedFilesElement In DataOfFilesBeingChecked.CheckedFiles Do
		
		FullFileName = CheckedFilesElement.Value;
		FileKind = CheckedFilesElement.Key;
		
		If ValueIsFilled(FullFileName) And IsTempStorageURL(FullFileName) Then
			
			//@skip-check missing-temporary-file-deletion
			TempFileName = GetTempFileName();
			
			FileData = GetFromTempStorage(FullFileName);
			FileData.Write(TempFileName);
			
			DeleteFromTempStorage(FullFileName);
			
			DataOfFilesBeingChecked.CheckedFiles[FileKind] = TempFileName;
			DataOfFilesBeingChecked.ListOfFiles.Add(TempFileName);
			
		EndIf;
		
	EndDo;
	
	UploadInformation = ExportImportDataInternal.ReadXDTOObjectFromFile(
		DataOfFilesBeingChecked.CheckedFiles.UploadInformation,
		XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "DumpInfo"));
	
	If Not ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurConfiguration(UploadInformation) Then
		
		CheckResult.ErrorText
			= ExportImportDataInternal.ErrorTextExportNotCompatibleWithCurrentConfiguration(UploadInformation);
		
	ElsIf Not ExportImportDataInternal.UploadingToArchiveIsCompatibleWithCurVersionOfConfiguration(UploadInformation) Then
		
		CheckResult.ErrorText
			= ExportImportDataInternal.ErrorTextExportNotCompatibleWithCurrentConfigurationVersion(UploadInformation);
		
	ElsIf Not ValueIsFilled(DataOfFilesBeingChecked.CheckedFiles.ConfigurationSchema) Then
		
		WarningText = NStr(
			"vi = 'Cấu hình hỗ trợ kiểm tra sơ đồ dữ liệu, nhưng không tìm thấy tệp sơ đồ trong tệp kết xuất.
			| Cấu trúc tệp kết xuất không phù hợp với cấu trúc mong muốn.';
			|ru = 'Конфигурация поддерживает проверку схемы данных, но файл схемы не найден в файле выгрузки.
			|Структура файла выгрузки не соответствует ожидаемой.';
			|en = 'The application supports the ER diagram check, but the ER diagram file is not found in the export file.
			|The export file structure does not match the expected one.'; fa = 'The application supports the ER diagram check, but the ER diagram file is not found in the export file.
			|The export file structure does not match the expected one.';
			|it = 'Конфигурация поддерживает проверку схемы данных, но файл схемы не найден в файле выгрузки.
			|Структура файла выгрузки не соответствует ожидаемой.';
			|pl = 'The application supports the ER diagram check, but the ER diagram file is not found in the export file.
			|The export file structure does not match the expected one.';
			|tr = 'Yapılandırma veri şeması kontrolünü destekliyor, ancak dışa aktarma dosyasında şema dosyası eksik.
			|Dışa aktarma dosyasının yapısı beklendiği gibi değil.'");
		
		WriteLogEvent(
			EventLogEventName(),
			EventLogLevel.Warning,
			,
			,
			WarningText);
		
	Else
		
		CompareConfigurationSchemes(DataOfFilesBeingChecked.CheckedFiles.ConfigurationSchema, CheckResult);
		
	EndIf;
	
	If Not ValueIsFilled(CheckResult.ErrorText) Then
		ImportDataFileAdditionalChecks(DataOfFilesBeingChecked, CheckResult);
	EndIf;
	
	DeleteDataOfFilesBeingChecked(DataOfFilesBeingChecked);
	
	Return CheckResult;
	
EndFunction

// Compare configuration diagrams.
// 
// Parameters:
//  PathToUploadConfigurationSchemaFile - String - The Path To The Upload Configuration Schema File
//  CheckResult - See NewCheckingDataFileResult
&AtServerNoContext
Procedure CompareConfigurationSchemes(PathToUploadConfigurationSchemaFile, CheckResult)
	
	BinaryConfigurationSchemaData = ConfigurationSchema.SchemaBinaryData(False, False);	

	HashingConfigurationSchemaData = New DataHashing(HashFunction.CRC32);
	HashingConfigurationSchemaData.Append(BinaryConfigurationSchemaData);
	
	If HashingConfigurationSchemaData.HashSum = TheHashSumOfTheFile(PathToUploadConfigurationSchemaFile) Then
		Return;
	EndIf;
	 	
	DescriptionsOfDifferences = AnalyzeConfigurationSchemas.DescriptionsOfDifferencesInConfigurationSchemes(
		New BinaryData(PathToUploadConfigurationSchemaFile),
		BinaryConfigurationSchemaData); 
	
	If ValueIsFilled(DescriptionsOfDifferences) Then
		
		CheckResult.ErrorText = NStr(
			"vi = 'Không thể kết nhập tệp vào cơ sở thông tin: cấu hình của tệp khác với cấu hình cơ sở thông tin.
			|Để loại bỏ sự khác biệt, cần liên hệ với doanh nghiệp dịch vụ của bạn hoặc người quản trị cơ sở thông tin.';
			|ru = 'Файл не может быть загружен в информационную базу: его конфигурация отличается от конфигурации информационной базы. 
			|Для устранения различий необходимо обратиться к своей обслуживающей организации или администратору информационной базы.';
			|en = 'Cannot import the file to the infobase: its configuration differs from the infobase configuration. 
			|Contact your service provider or infobase administrator to resolve the differences.'; fa = 'Cannot import the file to the infobase: its configuration differs from the infobase configuration. 
			|Contact your service provider or infobase administrator to resolve the differences.';
			|it = 'Файл не может быть загружен в информационную базу: его конфигурация отличается от конфигурации информационной базы. 
			|Для устранения различий необходимо обратиться к своей обслуживающей организации или администратору информационной базы.';
			|pl = 'Cannot import the file to the infobase: its configuration differs from the infobase configuration. 
			|Contact your service provider or infobase administrator to resolve the differences.';
			|tr = 'Dosya, Infobase''e yüklenemez: yapılandırması Infobase konfigürasyonundan farklıdır.
			|Farklılıkları gidermek için hizmet veren iş yerinize veya Infobase yöneticinize başvurmanız gerekmektedir.'");
		
		PartsOfErrorText = New Array();	
		
		For Each DescriptionsOfDifference In DescriptionsOfDifferences Do
			PartsOfErrorText.Add("● ");
			PartsOfErrorText.Add(DescriptionsOfDifference);
			PartsOfErrorText.Add(Chars.LF);
		EndDo;
		
		CheckResult.ErrorInfo = StrConcat(PartsOfErrorText);
		
	EndIf;
	
EndProcedure

// Additional checks for loading the data file.
// 
// Parameters:
//  DataOfFilesBeingChecked - See NewCheckedFilesData
//  CheckResult - See NewCheckingDataFileResult
&AtServerNoContext
Procedure ImportDataFileAdditionalChecks(DataOfFilesBeingChecked, CheckResult)
	
	CheckingUnloadingModeForTechnicalSupport(DataOfFilesBeingChecked, CheckResult);
	CheckingAvailabilityOfSuppliedExtensions(DataOfFilesBeingChecked, CheckResult);
	
EndProcedure

// Checking the unloading mode for technical support.
// 
// Parameters:
//  DataOfFilesBeingChecked - See NewCheckedFilesData
//  CheckResult - See NewCheckingDataFileResult
&AtServerNoContext
Procedure CheckingUnloadingModeForTechnicalSupport(DataOfFilesBeingChecked, CheckResult)
	
	UploadingForTechnicalSupport = ExportImportDataInternal.ExportForTechnicalSupportMode(
		DataOfFilesBeingChecked.CheckedFiles.Digest);
	
	If UploadingForTechnicalSupport Then
		
		WarningText = NStr(
			"vi = 'Đã tạo tệp dữ liệu ở chế độ kết xuất để hỗ trợ kỹ thuật.
			|Ứng dụng nhận được từ kết xuất chỉ dùng cho mục đích thử nghiệm và khắc phục sự cố.';
			|ru = 'Файл создан в режиме выгрузки для технической поддержки.
			|Приложение, полученное из такой выгрузки предназначено только для целей тестирования и разбора проблем.';
			|en = 'The file was created in export mode for the technical support.
			|An application received from such export must be used only for testing and problem analysis.'; fa = 'The file was created in export mode for the technical support.
			|An application received from such export must be used only for testing and problem analysis.';
			|it = 'Файл создан в режиме выгрузки для технической поддержки.
			|Приложение, полученное из такой выгрузки предназначено только для целей тестирования и разбора проблем.';
			|pl = 'The file was created in export mode for the technical support.
			|An application received from such export must be used only for testing and problem analysis.';
			|tr = 'Dosya, teknik destek için dışa aktarma modunda oluşturuldu.
			|Bu tür bir dışa aktarmadan elde edilen uygulama yalnızca test ve sorun giderme amaçlıdır.'");
		
		CheckResult.Warnings.Add(WarningText);
		
	EndIf;
	
EndProcedure

// Check the availability of the supplied extensions.
// 
// 
// Parameters:
//  DataOfFilesBeingChecked - See NewCheckedFilesData
//  CheckResult - See NewCheckingDataFileResult
&AtServerNoContext
Procedure CheckingAvailabilityOfSuppliedExtensions(DataOfFilesBeingChecked, CheckResult)
	
	XMLReader = New XMLReader();
	XMLReader.OpenFile(DataOfFilesBeingChecked.CheckedFiles.Extensions);
	XMLReader.MoveToContent();
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		XMLReader.Close();
		Return;
	EndIf;
	
	ExtensionsWithFrames = New Array();
	ExtensionsWithoutFrames = New Array();
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Extension" Then		
			Continue;	
		EndIf;
		
		ModifiesDataStructure = XMLValue(Type("Boolean"), XMLReader.AttributeValue("ModifiesDataStructure"));
		
		If Not ModifiesDataStructure Then
			Continue;
		EndIf;

		Description = "- " + XMLValue(Type("String"), XMLReader.AttributeValue("Name"));
		
		If XMLReader.AttributeValue("IsFrame") <> Undefined Then
			
			If XMLValue(Type("Boolean"), XMLReader.AttributeValue("IsFrame")) = True Then
				ExtensionsWithFrames.Add(Description);
			Else
				ExtensionsWithoutFrames.Add(Description);
			EndIf;
			
		Else
			ExtensionsWithoutFrames.Add(Description);
		EndIf;
		
	EndDo;
	
	XMLReader.Close();
	
	If ValueIsFilled(ExtensionsWithoutFrames) Then
		
		WarningText = StrTemplate(
			NStr("vi = 'Tệp có dữ liệu mà được thêm bởi phần mở rộng.
				 |Cần cài đặt các phần mở rộng hoặc các phiên bản khung của chúng:
				 |%1';
				 |ru = 'Файл содержит данные, добавленные расширениями.
				 |Должны быть установлены следующие расширения или их каркасные версии:
				 |%1';
				 |en = 'The file contains data added by extensions.
				 |Install the following extensions or their framework versions:
				 |%1'; fa = 'The file contains data added by extensions.
				 |Install the following extensions or their framework versions:
				 |%1';
				 |it = 'Файл содержит данные, добавленные расширениями.
				 |Должны быть установлены следующие расширения или их каркасные версии:
				 |%1';
				 |pl = 'The file contains data added by extensions.
				 |Install the following extensions or their framework versions:
				 |%1';
				 |tr = 'Dosya, uzantılar tarafından eklenen verileri içermektedir.
				 |Aşağıdaki uzantılar veya bunların çerçeve sürümleri yapılandırılmalıdır:
				 |%1'"),
			StrConcat(ExtensionsWithoutFrames, Chars.LF));
		
		CheckResult.Warnings.Add(WarningText);
		
	EndIf;
	
	If ValueIsFilled(ExtensionsWithFrames) Then
		
		WarningText = StrTemplate(
			NStr("vi = 'Không sử dụng được chức năng của các phần mở rộng tiếp theo, đã kết nối các phiên bản khung:
				 |%1';
				 |ru = 'Функциональность следующих расширений недоступна, были подключены каркасные версии:
				 |%1';
				 |en = 'Cannot use the following extensions, the framework versions were installed:
				 |%1'; fa = 'Cannot use the following extensions, the framework versions were installed:
				 |%1';
				 |it = 'Функциональность следующих расширений недоступна, были подключены каркасные версии:
				 |%1';
				 |pl = 'Cannot use the following extensions, the framework versions were installed:
				 |%1';
				 |tr = 'Aşağıdaki uzantıların işlevselliği mevcut değildir, çerçeve sürümleri etkinleştirilmiştir:
				 |%1'"),
			StrConcat(ExtensionsWithFrames, Chars.LF));
		
		CheckResult.Warnings.Add(WarningText);
		
	EndIf;
	
EndProcedure

// Get files to check the data upload.
// 
// Parameters:
//  FullDataFileName - String - Full Name Of The Data File
// 
// Returns:
//  See NewCheckedFilesData
&AtClientAtServerNoContext
Function GetFileDataForDataImportVerification(FullDataFileName)
	
	DataOfFilesBeingChecked = Undefined;
	
	#If Not WebClient Then
	
	DataOfFilesBeingChecked = NewCheckedFilesData();
	ReadingArchiveData = New ZipFileReader(FullDataFileName);
	
	Try
		
		ExtractFilesBeingCheckedFromArchive(ReadingArchiveData, DataOfFilesBeingChecked);
		
	Except
		
		ReadingArchiveData.Close();
		
		Raise;
		
	EndTry;
	
	ReadingArchiveData.Close();
	
	#EndIf
	
	Return DataOfFilesBeingChecked;
	
EndFunction

// Extract the files being checked from the archive.
// 
// Parameters:
//  ReadingArchiveData - ZipFileReader
//  DataOfFilesBeingChecked - See NewCheckedFilesData
&AtClientAtServerNoContext
Procedure ExtractFilesBeingCheckedFromArchive(ReadingArchiveData, DataOfFilesBeingChecked)
	
	InternalFilesNames = GetInternalFileNames();
	PathToContentFile = ExtractFileFromZipArchive(ReadingArchiveData, InternalFilesNames.Content);
	
	If Not ValueIsFilled(PathToContentFile) Then
		
		DataOfFilesBeingChecked.ErrorText = StrTemplate(
			NStr("vi = 'Trong tệp nén không có tệp nội dung (%1)';
				|ru = 'В архиве отсутствует файл содержимого (%1)';
				|en = 'The content file (%1) is missing in the archive'; fa = 'The content file (%1) is missing in the archive';
				|it = 'Nell''archivio manca il file del contenuto (%1)';
				|pl = 'Brak pliku zawartości w archiwum (%1)';
				|tr = 'Arşivde içerik dosyası eksik (%1)'"),
			InternalFilesNames.Content);
		
		Return;
		
	EndIf;
	
	DataOfFilesBeingChecked.CheckedFiles.UploadInformation = ExtractFileFromZipArchive(
		ReadingArchiveData,
		InternalFilesNames.UploadInformation);
	
	If Not ValueIsFilled(DataOfFilesBeingChecked.CheckedFiles.UploadInformation) Then
		
		DataOfFilesBeingChecked.ErrorText = StrTemplate(
			NStr("vi = 'Trong tệp nén không có tệp thông tin về kết xuất (%1)';
				|ru = 'В архиве отсутствует файл информации о выгрузке (%1)';
				|en = 'The export information file (%1) is missing in the archive'; fa = 'The export information file (%1) is missing in the archive';
				|it = 'Nell''archivio manca il file di informazioni sull''upload (%1)';
				|pl = 'Archiwum nie zawiera pliku informacji o eksporcie (%1)';
				|tr = 'Arşivde dışa aktarma bilgi dosyası eksik (%1)'"),
			InternalFilesNames.UploadInformation);
		
		Return;
		
	EndIf;
	
	DataOfFilesBeingChecked.CheckedFiles.Digest = ExtractFileFromZipArchive(
		ReadingArchiveData,
		InternalFilesNames.Digest);
	
	If Not ValueIsFilled(DataOfFilesBeingChecked.CheckedFiles.Digest) Then
		
		DataOfFilesBeingChecked.ErrorText = StrTemplate(
			NStr("vi = 'Trong lưu trữ không có tệp tóm tắt (%1)';
				|ru = 'В архиве отсутствует файл дайджест (%1)';
				|en = 'Digest file is missing in the archive (%1)'; fa = 'Digest file is missing in the archive (%1)';
				|it = 'В архиве отсутствует файл дайджест (%1)';
				|pl = 'Digest file is missing in the archive (%1)';
				|tr = 'Arşivde özet dosyası eksik (%1)'"),
			InternalFilesNames.Digest);
		
		Return;
		
	EndIf;
	
	DataOfFilesBeingChecked.CheckedFiles.Extensions = ExtractFileFromZipArchive(
		ReadingArchiveData,
		InternalFilesNames.Extensions);
	
	If Not ValueIsFilled(DataOfFilesBeingChecked.CheckedFiles.Extensions) Then
		
		DataOfFilesBeingChecked.ErrorText = StrTemplate(
			NStr("vi = 'Trong lưu trữ không có tệp mô tả phần mở rộng (%1)';
				|ru = 'В архиве отсутствует файл описания расширений (%1)';
				|en = 'Extension details file is missing in the archive (%1)'; fa = 'Extension details file is missing in the archive (%1)';
				|it = 'В архиве отсутствует файл описания расширений (%1)';
				|pl = 'Extension details file is missing in the archive (%1)';
				|tr = 'Arşivde uzantıların açıklama dosyası eksik (%1)'"),
			InternalFilesNames.Extensions);
		
		Return;
		
	EndIf;
	
	NameOfConfigurationSchemaFile = GetFileNameFromContentData(
		PathToContentFile, 
		"CustomData", 
		"ConfigScheme");
	DeleteFilesInAttempt(PathToContentFile);
	
	DataOfFilesBeingChecked.CheckedFiles.ConfigurationSchema = ExtractFileFromZipArchive(
		ReadingArchiveData,
		NameOfConfigurationSchemaFile);
	
	For Each ElementCheckedFile In DataOfFilesBeingChecked.CheckedFiles Do
		
		If ValueIsFilled(ElementCheckedFile.Value) Then
			DataOfFilesBeingChecked.ListOfFiles.Add(ElementCheckedFile.Value);
		EndIf;
		
	EndDo;
	 
EndProcedure

&AtClientAtServerNoContext
Function GetFileNameFromContentData(PathToContentFile, FileType, DataType)
	
	FileName = Undefined;
	
	#If Not WebClient Then

	ContentReading = New XMLReader();
	ContentReading.OpenFile(PathToContentFile);
	ContentReading.MoveToContent();

	If ContentReading.NodeType <> XMLNodeType.StartElement Or ContentReading.Name <> "Data" Then
		Raise NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử ""Data"".';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Data"".';
					|en = 'An error occurred while reading XML. Invalid file format. Start of the Data item is expected.'; fa = 'An error occurred while reading XML. Invalid file format. Start of the Data item is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento ""Data"".';
					|pl = 'Błąd odczytu XML. Błędny format pliku. Oczekiwany jest początek elementu ""Дата"".';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. ""Data"" öğesinin başlangıcı bekleniyor.'");
	EndIf;

	ContentReading.Read();
	
	While ContentReading.NodeType = XMLNodeType.StartElement Do
		
		XDTODataObject = XDTOFactory.ReadXML(ContentReading);

		If XDTODataObject.Type = FileType
			And (DataType = Undefined
			Or XDTODataObject.Properties().Get("DataType") <> Undefined And XDTODataObject.DataType = DataType) Then

			FileName = XDTODataObject.Name;
			
			Break;
			
		EndIf;
		
	EndDo;
	
	ContentReading.Close();
	
	#EndIf

	Return FileName;

EndFunction

// Extract the file from the zip archive.
// 
// Parameters:
//  ReadingArchiveData - ZipFileReader
//  FileName - String
// 
// Returns:
//  String, Undefined - Full name of the extracted file
&AtClientAtServerNoContext
Function ExtractFileFromZipArchive(ReadingArchiveData, FileName)
	
	TempFileName = Undefined;
	
	#If Not WebClient Then
		
	ZipElement = ReadingArchiveData.Items.Find(FileName);
	
	If ZipElement <> Undefined Then
		
		//@skip-check missing-temporary-file-deletion
		TempDirectoryName = GetTempFileName();
		
		ReadingArchiveData.Extract(
			ZipElement,
			TempDirectoryName,
			ZIPRestoreFilePathsMode.DontRestore);
		
		TempFileName = GetTempFileName();
		MoveFile(TempDirectoryName + GetPathSeparator() + FileName, TempFileName);
		
		DeleteFilesInAttempt(TempDirectoryName);
		
	EndIf;

	#EndIf	
				
	Return TempFileName;
	
EndFunction

// Delete the data of the files being checked.
// 
// Parameters:
//  DataOfFilesBeingChecked - See NewCheckedFilesData
&AtClientAtServerNoContext
Procedure DeleteDataOfFilesBeingChecked(DataOfFilesBeingChecked)
	
	For Each FileName In DataOfFilesBeingChecked.ListOfFiles Do
		DeleteFilesInAttempt(FileName);
	EndDo;
	
EndProcedure

// New data of the files being checked.
// 
// Returns:
//  Structure - New Data Of The Files Being Checked:
// * CheckedFiles - Structure -:
// ** UploadInformation - String, Undefined -
// ** Digest - String, Undefined -
// ** ConfigurationSchema - String, Undefined -
// ** Extensions - String, Undefined -
// * ListOfFiles - Array of String -
// * ErrorText - String, Undefined -
&AtClientAtServerNoContext
Function NewCheckedFilesData()
	
	CheckedFiles = New Structure();
	CheckedFiles.Insert("UploadInformation", Undefined);
	CheckedFiles.Insert("Digest", Undefined);
	CheckedFiles.Insert("ConfigurationSchema", Undefined);
	CheckedFiles.Insert("Extensions", Undefined);
	
	DataOfFilesBeingChecked = New Structure();
	DataOfFilesBeingChecked.Insert("CheckedFiles", CheckedFiles);
	DataOfFilesBeingChecked.Insert("ListOfFiles", New Array());
	DataOfFilesBeingChecked.Insert("ErrorText", Undefined);
	
	Return DataOfFilesBeingChecked;
	
EndFunction

// New result of checking the data file.
// 
// Returns:
//  Structure - New Result Of Checking The Data File:
// * ErrorText - String, Undefined -
// * ErrorInfo - String, Undefined -
// * Warnings - Array of String -
&AtClientAtServerNoContext
Function NewCheckingDataFileResult()
	
	CheckResult = New Structure();
	CheckResult.Insert("ErrorText", Undefined);
	CheckResult.Insert("ErrorInfo", Undefined);
	CheckResult.Insert("Warnings", New Array());
	
	Return CheckResult;
	
EndFunction

// Get service file names.
// 
// Returns:
//  Structure - Get Service File Names:
// * UploadInformation - String -
// * Digest - String -
// * Content - String -
// * Extensions - String -
&AtServerNoContext
Function GetInternalFileNames()
	
	InternalFilesNames = New Structure();
	InternalFilesNames.Insert(
		"UploadInformation",
		ExportImportDataInternal.GetFileName(ExportImportDataInternal.DumpInfo()));
	InternalFilesNames.Insert(
		"Digest",
		ExportImportDataInternal.GetFileName(ExportImportDataInternal.Digest()));
	InternalFilesNames.Insert(
		"Content",
		ExportImportDataInternal.GetFileName(ExportImportDataInternal.PackageContents()));
	InternalFilesNames.Insert(
		"Extensions",
		ExportImportDataInternal.GetFileName(ExportImportDataInternal.Extensions()));
	
	Return InternalFilesNames;
	
EndFunction

// Get the availability of files on the server.
// 
// Parameters:
//  ListOfFiles - String, Array of String -
// 
// Returns:
//  Boolean
&AtClient
Async Function GetFilesAvailabilityOnServer(ListOfFiles)
	
	If IsWebClient Or IsFileInformationBase Then
		Return Not IsWebClient;
	EndIf;
	
	If TypeOf(ListOfFiles) = Type("String") Then
		CheckedFiles = New Array();
		CheckedFiles.Add(ListOfFiles);
	Else
		CheckedFiles = ListOfFiles;
	EndIf;
	
	Try
		
		FilesAvailable = Await FilesAreAvailableOnServer(CheckedFiles);
		
	Except
		
		FilesAvailable = False;
		ErrorText = StrTemplate(
			NStr("vi = 'Không thể kiểm tra tính khả dụng của tệp trên server:
				 |%1
				 |
				 |Khi kiểm tra đã xảy ra lỗi:
				 |%2';
				 |ru = 'Не удалось проверить доступность файлов на сервере:
				 |%1
				 |
				 |При проверке произошла ошибка:
				 |%2';
				 |en = 'Cannot check if the files are available on the server:
				 |%1
				 |
				 |An error occurred when checking:
				 |%2'; fa = 'Cannot check if the files are available on the server:
				 |%1
				 |
				 |An error occurred when checking:
				 |%2';
				 |it = 'Не удалось проверить доступность файлов на сервере:
				 |%1
				 |
				 |При проверке произошла ошибка:
				 |%2';
				 |pl = 'Cannot check if the files are available on the server:
				 |%1
				 |
				 |An error occurred when checking:
				 |%2';
				 |tr = 'Sunucudaki dosyaların kullanılabilirliği kontrol edilemedi:
				 |%1
				 |
				 |Doğrulama sırasında hata oluştu:
				 |%2'"),
			StrConcat(CheckedFiles, Chars.LF),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteErrorToEventLog(ErrorText);
		
	EndTry;
	
	Return FilesAvailable;
	
EndFunction

// Checks the availability of files in the same directory from the client to the server.
// 
// Parameters:
//  CheckedFiles - Array of String
// 
// Returns:
//  Boolean
&AtClient
Async Function FilesAreAvailableOnServer(CheckedFiles)
	
	AvailabilityParametersOnClient = NewFileAvailabilityOnServerCheckingParameters();
	
	For Each FileName In CheckedFiles Do
		
		FSObject = New File(FileName);
		FileExists = Await FSObject.ExistsAsync();
		
		If Not FileExists Then
			Return False;
		EndIf;
		
		FileParameters = NewFileParameters();
		FileParameters.FullName = FSObject.FullName;
		FileParameters.Size = Await FSObject.SizeAsync();
		
		AvailabilityParametersOnClient.CheckedFiles.Add(FileParameters);
		
		If Not ValueIsFilled(AvailabilityParametersOnClient.Path) Then
			AvailabilityParametersOnClient.Path = FSObject.Path;
		EndIf;
		
	EndDo;
	
	RecordFileAvailabilityCheckTemporaryData(AvailabilityParametersOnClient);
	AvailabilitySettingsAtServer = GetFileAvailabilityParametersOnServer(AvailabilityParametersOnClient);
	
	FilesCount = AvailabilityParametersOnClient.CheckedFiles.Count();
	FilesAvailable = False;
	
	If FilesCount = AvailabilitySettingsAtServer.CheckedFiles.Count() Then
		
		FilesSizeMatches = True;
		
		For ParameterIndex_ = 0 To FilesCount - 1 Do
			
			FileParametersClient = AvailabilityParametersOnClient.CheckedFiles[ParameterIndex_];
			FileParametersServer = AvailabilitySettingsAtServer.CheckedFiles[ParameterIndex_];
			
			If FileParametersClient.Size <> FileParametersServer.Size Then
				FilesSizeMatches = False;
				Break;
			EndIf;
			
		EndDo;
		
		If FilesSizeMatches Then
		
			TemporaryFileData = ReadTemporaryCheckDataOfFileAvailability(AvailabilitySettingsAtServer);
			
			If AvailabilitySettingsAtServer.TemporaryFileData = TemporaryFileData Then
				FilesAvailable = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	DeleteFilesInAttempt(AvailabilityParametersOnClient.TempFileFullName);
	
	Return FilesAvailable;
	
EndFunction

// Get the file availability parameters on the server.
// 
// Parameters:
//  AvailabilityParametersOnClient - See NewFileAvailabilityOnServerCheckingParameters
// 
// Returns:
//  See NewFileAvailabilityOnServerCheckingParameters
&AtServerNoContext
Function GetFileAvailabilityParametersOnServer(Val AvailabilityParametersOnClient)
	
	AvailabilitySettingsAtServer = NewFileAvailabilityOnServerCheckingParameters();
	
	FillPropertyValues(
		AvailabilitySettingsAtServer,
		AvailabilityParametersOnClient,
		"Path, TempFileFullName");
	
	For Each FileParametersClient In AvailabilityParametersOnClient.CheckedFiles Do
		
		FSObject = New File(FileParametersClient.FullName);
		
		If Not FSObject.Exists() Then
			Return AvailabilitySettingsAtServer;
		EndIf;
		
		FileParameters = NewFileParameters();
		FileParameters.FullName = FSObject.FullName;
		FileParameters.Size = FSObject.Size();
		
		If FileParameters.Size <> FileParametersClient.Size Then
			Return AvailabilitySettingsAtServer;
		EndIf;
		
		AvailabilitySettingsAtServer.CheckedFiles.Add(FileParameters);
		
	EndDo;
	
	TemporaryFileData = ReadTemporaryCheckDataOfFileAvailability(AvailabilityParametersOnClient);
	
	If AvailabilityParametersOnClient.TemporaryFileData <> TemporaryFileData Then
		Return AvailabilitySettingsAtServer;
	EndIf;
	
	RecordFileAvailabilityCheckTemporaryData(AvailabilitySettingsAtServer);
	
	Return AvailabilitySettingsAtServer;
	
EndFunction

// Record temporary data for checking file availability.
// 
// Parameters:
//  AvailabilityParameters - See NewFileAvailabilityOnServerCheckingParameters
&AtClientAtServerNoContext
Procedure RecordFileAvailabilityCheckTemporaryData(AvailabilityParameters)
	
	If Not ValueIsFilled(AvailabilityParameters.TempFileFullName) Then
		
		AvailabilityParameters.TempFileFullName = AvailabilityParameters.Path
			+ ".data_loading_tmp_"
			+ String(New UUID());
		
	EndIf;
	
	AvailabilityParameters.TemporaryFileData = String(New UUID());
	
	#If Not WebClient Then
	
	Record = New TextWriter(AvailabilityParameters.TempFileFullName);
	Record.WriteLine(AvailabilityParameters.TemporaryFileData);
	Record.Close();
	
	#EndIf
	
EndProcedure

// Record temporary data for checking file availability.
// 
// Parameters:
//  AvailabilityParameters - See NewFileAvailabilityOnServerCheckingParameters
// 
// Returns:
//  String - Contents Of The Temporary File
&AtClientAtServerNoContext
Function ReadTemporaryCheckDataOfFileAvailability(AvailabilityParameters)
	
	TemporaryFileData = "";
	
	#If Not WebClient Then
	
	Read = New TextReader(AvailabilityParameters.TempFileFullName);
	RowData = Read.ReadLine();
	Read.Close();
	
	If ValueIsFilled(RowData) Then
		TemporaryFileData = RowData;
	EndIf;
	
	#EndIf
	
	Return TemporaryFileData;
	
EndFunction

// New parameters for checking file availability on the server.
// 
// Returns:
//  Structure - New Parameters For Checking File Availability On The Server:
// * CheckedFiles - Array of See NewFileParameters -
// * Path - String -
// * TempFileFullName - String -
// * TemporaryFileData - String -
&AtClientAtServerNoContext
Function NewFileAvailabilityOnServerCheckingParameters()
	
	AvailabilityParameters = New Structure();
	AvailabilityParameters.Insert("CheckedFiles", New Array());
	AvailabilityParameters.Insert("Path", "");
	AvailabilityParameters.Insert("TempFileFullName", "");
	AvailabilityParameters.Insert("TemporaryFileData", "");
	
	Return AvailabilityParameters;
	
EndFunction

&AtClientAtServerNoContext
Function NewFileParameters()
	
	FileParameters = New Structure();
	FileParameters.Insert("FullName", "");
	FileParameters.Insert("Size", 0);
	
	Return FileParameters;
	
EndFunction

&AtClient
Function DataFileSelectionDialogTitle()
	
	Return NStr("vi = 'Kết nhập tệp';
				|ru = 'Загрузка файла';
				|en = 'Import file'; fa = 'فایل ورود';
				|it = 'Caricamento file';
				|pl = 'Pobieranie pliku';
				|tr = 'Dosya indiriliyor'");
	
EndFunction

&AtClient
Function DataFileSelectionDialogFilter()
	
	Return StrTemplate(NStr("vi = 'Tệp nén %1';
							|ru = 'Архивы %1';
							|en = 'Archives %1'; fa = 'Archives %1';
							|it = 'Archivi %1';
							|pl = 'Archiwa %1';
							|tr = 'Arşivler %1'"), "(*.zip)|*.zip");
	
EndFunction

// Get a temporary storage file.
// 
// Parameters:
//  FormIdentifier - UUID - Form ID
//  GetFullName - Boolean - whether to get the full name of the temporary file
// 
// Returns:
//  Structure - Temporary Storage File Data:
// * FileName - String -
// * FullFileName - String -
&AtServerNoContext
Function GetTemporaryStorageFile(Val FormIdentifier, Val GetFullName = False)
	
	FileName = FilesCTL.NewTemporaryStorageFile("xml2data", "zip", 120);
	FilesCTL.LocATemporaryStorageFile(FileName, FormIdentifier);
	
	Result = New Structure();
	Result.Insert("FileName", FileName);
	Result.Insert("FullFileName", "");
	
	If GetFullName Then
		Result.FullFileName = FilesCTL.FullTemporaryStorageFileName(FileName);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region DataImport

&AtClient
Procedure StartDataImport()
	
	Try
		StartDataImportAtServer();
		
		If ClearMessageWindow Then
			ClearMessages();
			ClearMessageWindow = False;
		EndIf;
	Except
		
		ErrorInfo = ErrorInfo();
		
		CompleteDownloadOnServer();
		
		NoticeParameters = NewParametersNotificationErrorWarning();
		NoticeParameters.ToolTip = NStr("vi = 'Khi khởi động kết nhập dữ liệu đã xảy ra lỗi:';
										|ru = 'При запуске загрузки данных произошла ошибка:';
										|en = 'An error occurred when starting the data import:'; fa = 'An error occurred when starting the data import:';
										|it = 'При запуске загрузки данных произошла ошибка:';
										|pl = 'An error occurred when starting the data import:';
										|tr = 'Veri içe aktarma başlatma sırasında hata oluştu:'");
		NoticeParameters.Recommendation = NStr("vi = 'Cần thử lại kết nhập';
												|ru = 'Рекомендуется повторить попытку загрузки';
												|en = 'We recommend that you try to import again'; fa = 'We recommend that you try to import again';
												|it = 'Рекомендуется повторить попытку загрузки';
												|pl = 'We recommend that you try to import again';
												|tr = 'İçe aktarma yeniden denemek tavsiye ediliyor'");
		NoticeParameters.Text = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		NoticeParameters.WholeText = StrTemplate(
			NStr("vi = 'Khi kết nhập dữ liệu đã xảy ra lỗi:
				 |%1';
				 |ru = 'При загрузке данных произошла ошибка:
				 |%1';
				 |en = 'An error occurred when importing data:
				 |%1'; fa = 'An error occurred when importing data:
				 |%1';
				 |it = 'При загрузке данных произошла ошибка:
				 |%1';
				 |pl = 'An error occurred when importing data:
				 |%1';
				 |tr = 'Veriler yüklenirken hata oluştu:
				 |%1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		ShowWarningErrors(NoticeParameters);
		
		Return;
		
	EndTry;
	
	AttachIdleHandler("ImportReadyCheck", 5);
	
EndProcedure

&AtClient
Procedure ImportReadyCheck()
	
	Try
		ImportState = ImportState(JobID, StateID, StorageAddress);
	Except
		
		ErrorInfo = ErrorInfo();
		
		DetachIdleHandler("ImportReadyCheck");
		CompleteDownloadOnServer();
			
		NoticeParameters = NewParametersNotificationErrorWarning();
		NoticeParameters.ToolTip = NStr("vi = 'Khi kết nhập dữ liệu, đã xảy ra lỗi:';
										|ru = 'При загрузке данных произошла ошибка:';
										|en = 'An error occurred when importing the data:'; fa = 'An error occurred when importing the data:';
										|it = 'При загрузке данных произошла ошибка:';
										|pl = 'An error occurred when importing the data:';
										|tr = 'Veriler indirilirken bir hata oluştu:'");
		NoticeParameters.Recommendation = NStr("vi = 'Nếu tiếp tục, bạn sẽ được nhắc thử lại tải xuống';
												|ru = 'При продолжении будет предложено повторить попытку загрузки';
												|en = 'If you continue, you will be prompted to try to import again'; fa = 'If you continue, you will be prompted to try to import again';
												|it = 'При продолжении будет предложено повторить попытку загрузки';
												|pl = 'If you continue, you will be prompted to try to import again';
												|tr = 'Devam ederseniz, yeniden içe aktarmayı denemeniz istenecektir.'");
		NoticeParameters.Text = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		NoticeParameters.WholeText = StrTemplate(
			NStr("vi = 'Khi kết nhập dữ liệu đã xảy ra lỗi:
				 |%1';
				 |ru = 'При загрузке данных произошла ошибка:
				 |%1';
				 |en = 'An error occurred when importing data:
				 |%1'; fa = 'An error occurred when importing data:
				 |%1';
				 |it = 'При загрузке данных произошла ошибка:
				 |%1';
				 |pl = 'An error occurred when importing data:
				 |%1';
				 |tr = 'Veriler yüklenirken hata oluştu:
				 |%1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		ShowWarningErrors(NoticeParameters);
		
		Return;
		
	EndTry;
	
	If ImportState.StatusPresentation <> Undefined Then	
		StatusPresentation  = ImportState.StatusPresentation
			+ Chars.LF 
			+ ExportImportDataClientServer.LongTermOperationHint();
	EndIf;
						
	EndPercentage = ImportState.EndPercentage;
	Items.GroupEndPercentage.Visible = ImportState.EndPercentage <> Undefined;
		
	If Not ImportState.Completed_ Then 
		Return;
	EndIf;
	
	DetachIdleHandler("ImportReadyCheck");	
		 
	ProcessingResult = ProcessImportResultOnServer();
	
	If ValueIsFilled(ProcessingResult.Warnings) Then
		
		RestartProgramAtClosing = True;
		Separator = "
		|-----------------------------------------------
		|";

		NoticeParameters = NewParametersNotificationErrorWarning();
		NoticeParameters.IsError = False;
		NoticeParameters.ToolTip
			= NStr("vi = 'Đã hoàn tất kết nhập dữ liệu. Trong quá trình kết nhập đã nhận cảnh báo:';
					|ru = 'Загрузка данных завершена. В процессе загрузки получены предупреждения:';
					|en = 'Data is imported. During the operation, the following warnings were received:'; fa = 'Data is imported. During the operation, the following warnings were received:';
					|it = 'Загрузка данных завершена. В процессе загрузки получены предупреждения:';
					|pl = 'Data is imported. During the operation, the following warnings were received:';
					|tr = 'İçe aktarma tamamlandı. İçe aktarma sürecinde uyarılar alındı:'");
		NoticeParameters.Recommendation
			= NStr("vi = 'Thông tin chi tiết được ghi vào nhật ký sự kiện. Nếu bạn tiếp tục, chương trình sẽ khởi động lại';
					|ru = 'Подробная информация записана в журнал регистрации. При продолжении программа будет перезапущена';
					|en = 'Detailed information is saved to the event log. If you continue, the application will be restarted'; fa = 'Detailed information is saved to the event log. If you continue, the application will be restarted';
					|it = 'Подробная информация записана в журнал регистрации. При продолжении программа будет перезапущена';
					|pl = 'Detailed information is saved to the event log. If you continue, the application will be restarted';
					|tr = 'Ayrıntılı bilgiler kayıt defterine kaydedilir. Devam ederseniz, program yeniden başlayacak'");
		NoticeParameters.Text = StrConcat(ProcessingResult.Warnings, Separator);
		
		ShowWarningErrors(NoticeParameters);
		
	Else
		RestartApplication();	
	EndIf;
	
EndProcedure

// The State of the download.
// 
// Parameters:
//  JobID - UUID - Task ID
//  StateID - UUID - State ID
//  StorageAddress - String - The address of the storage
// 
// Returns:
//  Structure - Download State:
// * Completed_ - Boolean -
// * StatusPresentation - Undefined, String -
// * EndPercentage - Undefined, Number -
&AtServerNoContext																	
Function ImportState(JobID, StateID, StorageAddress)
	
	ImportState = New Structure();
	ImportState.Insert("Completed_", False);
	ImportState.Insert("StatusPresentation", Undefined);
	ImportState.Insert("EndPercentage", Undefined);
			
	Job = BackgroundJobs.FindByUUID(JobID);
	JobActive = False;
			
	If Job = Undefined Then
		
		ImportResult1 = GetFromTempStorage(StorageAddress);
		
		If ImportResult1 = Undefined Then
			Raise
				NStr("vi = 'Khi kết nhập dữ liệu đã xảy ra lỗi - chưa tìm thấy nhiệm vụ mà thực hiện kết nhập.';
					|ru = 'При загрузке данных произошла ошибка - не найдено задание выполняющее загрузку.';
					|en = 'An error occurred when importing data. No import job is found.'; fa = 'An error occurred when importing data. No import job is found.';
					|it = 'При загрузке данных произошла ошибка - не найдено задание выполняющее загрузку.';
					|pl = 'An error occurred when importing data. No import job is found.';
					|tr = 'Veriler yüklenirken hata oluştu - yüklemeyi gerçekleştiren görev bulunamadı.'");
		EndIf;
		
	Else
		
		If Job.State = BackgroundJobState.Active Then
					
			JobActive = True;
							
		ElsIf Job.State = BackgroundJobState.Failed Then
			
			JobError = Job.ErrorInfo;
			
			If JobError <> Undefined Then
				Raise ErrorProcessing.DetailErrorDescription(JobError);
			Else
				Raise
					NStr("vi = 'Khi kết nhập dữ liệu đã xảy ra lỗi - nhiệm vụ mà thực hiện kết nhập đã kết thúc với lỗi không xác định.';
						|ru = 'При загрузке данных произошла ошибка - задание выполняющее загрузку завершилось с неизвестной ошибкой.';
						|en = 'An error occurred when importing data. The job executing the import was completed with an unknown error.'; fa = 'An error occurred when importing data. The job executing the import was completed with an unknown error.';
						|it = 'При загрузке данных произошла ошибка - задание выполняющее загрузку завершилось с неизвестной ошибкой.';
						|pl = 'An error occurred when importing data. The job executing the import was completed with an unknown error.';
						|tr = 'Veriler yüklenirken hata oluştu - yüklemeyi gerçekleştiren iş bilinmeyen bir hatayla sona erdi.'");
			EndIf;
			
		ElsIf Job.State = BackgroundJobState.Canceled Then
			
			Raise
				NStr("vi = 'Khi kết nhập dữ liệu đã xảy ra lỗi - nhiệm vụ mà thực hiện kết nhập đã bị hủy bỏ bởi người quản trị.';
					|ru = 'При загрузке данных произошла ошибка - задание выполняющее загрузку было отменено администратором.';
					|en = 'An error occurred when importing data. The job executing the import was canceled by the administrator.'; fa = 'An error occurred when importing data. The job executing the import was canceled by the administrator.';
					|it = 'При загрузке данных произошла ошибка - задание выполняющее загрузку было отменено администратором.';
					|pl = 'An error occurred when importing data. The job executing the import was canceled by the administrator.';
					|tr = 'Veriler yüklenirken hata oluştu - yüklemeyi gerçekleştiren görev yönetici tarafından iptal edildi.'");
			
		EndIf;
				
	EndIf;
	
 	ImportState.Completed_ = Not JobActive;
 				
	DataAreaExportImportState = ExportImportData.DataAreaExportImportState(
		StateID);	
				
	If ValueIsFilled(DataAreaExportImportState) Then
		
		ImportState.StatusPresentation = ExportImportData.DataAreaExportImportStateView(
			DataAreaExportImportState);
		ImportState.EndPercentage = ExportImportData.ExportImportDataAreaEndPercentage(
			DataAreaExportImportState);
		
	EndIf;
 	
	Return ImportState;

EndFunction

&AtServer
Function ProcessImportResultOnServer() 
	
	JobID = Undefined;
	CompleteDownloadOnServer();
	
	Constants.ParametersForLaunchingInteractiveImportProcedure.Set(Undefined);	
	ImportResult1 = GetFromTempStorage(StorageAddress);
	
	If ImportResult1 = Undefined Then
		Raise NStr("vi = 'Khi kết nhập dữ liệu đã xảy ra lỗi - chưa tìm thấy kết quả kết nhập';
					|ru = 'При загрузке данных произошла ошибка - не найден результат загрузки';
					|en = 'An error occurred when importing data. The import result is not found'; fa = 'An error occurred when importing data. The import result is not found';
					|it = 'При загрузке данных произошла ошибка - не найден результат загрузки';
					|pl = 'An error occurred when importing data. The import result is not found';
					|tr = 'Veriler yüklenirken hata oluştu - yükleme sonucu bulunamadı'");
	EndIf;
	
	DeleteFromTempStorage(StorageAddress);
	
	ProcessingResult = New Structure();
	ProcessingResult.Insert("Warnings", ImportResult1.Warnings);
	
	Return ProcessingResult;
	
EndFunction

&AtServer
Procedure StartDataImportAtServer()
	
	If UseMultithreading() Then
		SaaSOperations.SetExclusiveLock(True);
		SaaSOperations.RemoveExclusiveLock();
	EndIf;
	
	FileNameAtServer = ?(IsWebClient Or Not DataFileIsAvailableOnServer,
		FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName),
		DataFile);
	DataFileHashSum = TheHashSumOfTheFile(FileNameAtServer);
	
	If ValueIsFilled(TheHashSumOfTheFile) And TheHashSumOfTheFile <> DataFileHashSum Then
		
		Warnings = CommonClientServer.ValueInArray(
			NStr("vi = 'Tệp không trùng với tệp đã bắt đầu kết nhập từ trước.
				 |Quá trình kết nhập không thể tiếp tục và sẽ bắt đầu lại từ đầu.';
				 |ru = 'Файл не совпадает с тем из которого загрузка запускалась ранее.
				 |Продолжение загрузки было невозможно, и она была запущена с начала.';
				 |en = 'The file does not correspond to the file from which the import was started.
				 |The import could not be continued. It was started from the beginning.'; fa = 'The file does not correspond to the file from which the import was started.
				 |The import could not be continued. It was started from the beginning.';
				 |it = 'Файл не совпадает с тем из которого загрузка запускалась ранее.
				 |Продолжение загрузки было невозможно, и она была запущена с начала.';
				 |pl = 'The file does not correspond to the file from which the import was started.
				 |The import could not be continued. It was started from the beginning.';
				 |tr = 'Dosya, yükleme işleminin daha önce başlatıldığı dosya ile eşleşmiyor.
				 |Yükleme işlemine devam edilemedi ve baştan başlatıldı.'"));
		
		DisplayDataFileWarnings(Warnings);
		
	EndIf;
	
	If Not NotDownloadTheExtensionConfiguration Then
		RestoreInformationBaseExtensions(FileNameAtServer);
	EndIf;
	
	ParametersForLaunchingInteractiveImportProcedure = New Structure();
	ParametersForLaunchingInteractiveImportProcedure.Insert(
		"TheHashSumOfTheFile",
		DataFileHashSum);
	ParametersForLaunchingInteractiveImportProcedure.Insert(
		"NotDownloadTheExtensionConfiguration",
		NotDownloadTheExtensionConfiguration);
	ParametersForLaunchingInteractiveImportProcedure.Insert(
		"ImportDataJobsCount",
		ImportDataJobsCount);
	
	Constants.ParametersForLaunchingInteractiveImportProcedure.Set(
		New ValueStorage(ParametersForLaunchingInteractiveImportProcedure));	
	
	StateID = New UUID();
	StorageAddress = PutToTempStorage(Undefined, UUID);
	
	ImportParameters = ExportImportDataAreas.ImportParameters();
	ImportParameters.UploadUsers = True;
	ImportParameters.CollapseElementsInUsersCatalog = True;
	ImportParameters.StateID = StateID;
	ImportParameters.SkipExtensionsRestoring = True;
	ImportParameters.ResultStorageAddress_ = StorageAddress;
	ImportParameters.ThreadsCount = ImportDataJobsCount;
	ImportParameters.ClientSessionNumber = InfoBaseSessionNumber;
	
	JobParameters = New Array();
	JobParameters.Add(FileNameAtServer);
	JobParameters.Add(ImportParameters);
	
	BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
		"ExportImportDataAreas.LoadAreaFromArchive",
		JobParameters);
	JobID = BackgroundJob.UUID;
	
EndProcedure

&AtServer
Procedure RestoreInformationBaseExtensions(FileNameAtServer)
	
	Result = RecoveryExtensions(FileNameAtServer, ClearMessageWindow);
	ExtensionsFrameForRecovery = ExtensionsFrameForRecovery(FileNameAtServer);
	
	ExtensionData_ = New Structure();
		
	If ValueIsFilled(Result.RecoveryExtensions) Then
		ExtensionData_.Insert("RecoveryExtensions", Result.RecoveryExtensions);
	EndIf;
		
	If ValueIsFilled(ExtensionsFrameForRecovery) Then	
		ExtensionData_.Insert("ExtensionsFrameForRecovery", ExtensionsFrameForRecovery);
	EndIf;
	
	If ValueIsFilled(Result.PlusExtensions) Then
		ExportImportDataInternal.RestorePlusExtensions(Result.PlusExtensions);
	EndIf;
	
	If Not ValueIsFilled(ExtensionData_) Then
		Return;
	EndIf;
	
	ExportImportDataInternal.RestoreInformationBaseExtensions(ExtensionData_);	
	
EndProcedure

&AtServerNoContext
Function RecoveryExtensions(FileNameAtServer, ClearMessageWindow)

	ReadingArchiveData = New ZipFileReader(FileNameAtServer);

	Try
		RecoveryExtensions = ExtensionsForInternalRecovery(ReadingArchiveData, ClearMessageWindow);
	Except
		ReadingArchiveData.Close();
		Raise;
	EndTry;
	
	ReadingArchiveData.Close();
		
	Return RecoveryExtensions;
	
EndFunction

&AtServerNoContext
Function ExtensionsForInternalRecovery(ReadingArchiveData, ClearMessageWindow)
	Result = New Structure("RecoveryExtensions, PlusExtensions", New Array(), New Array());
	
	UUIDType = Type("UUID");
	PathToCustomExtensionsFile = ExtractFileFromZipArchive(ReadingArchiveData, "CustomExtensions.json");
	
	If PathToCustomExtensionsFile = Undefined Then
		Return Result;
	EndIf;

	ReadingCustomExtensionFile = New JSONReader;
	ReadingCustomExtensionFile.OpenFile(PathToCustomExtensionsFile);

	InformationAboutCustomExtensions = ReadJSON(ReadingCustomExtensionFile);
	ReadingCustomExtensionFile.Close();

	For Each UserExtensionInformation In InformationAboutCustomExtensions Do

		If UserExtensionInformation.Property("PlusExtVersionId") 
				And UserExtensionInformation.PlusExtVersionId <> "" Then
			PlusExtension = New Structure();
			PlusExtension.Insert("ExtVersionId", UserExtensionInformation.PlusExtVersionId);
			PlusExtension.Insert("ExtId", UserExtensionInformation.PlusExtId);
			PlusExtension.Insert("Version", UserExtensionInformation.Version);
			PlusExtension.Insert("Name", UserExtensionInformation.Name);
			
			FileDetails = GetBinaryExtensionData(
				ReadingArchiveData, UserExtensionInformation.FileName);
			PlusExtension.Insert("Data", FileDetails.Data);
			PlusExtension.Insert("InstallTask", UserExtensionInformation.InstallTask);
			
			Result.PlusExtensions.Add(PlusExtension);
			
			DeleteFilesInAttempt(FileDetails.Path);
		Else
			NameOfCustomExtensionFile = Undefined;
			
			If Not UserExtensionInformation.Property("FileName", NameOfCustomExtensionFile)
				Or Not ValueIsFilled(NameOfCustomExtensionFile) Then
				Continue;
			EndIf;
			
			FileDetails = GetBinaryExtensionData(ReadingArchiveData, NameOfCustomExtensionFile);
	
			ExtensionForRecovery = New Structure;
			ExtensionForRecovery.Insert("Active", UserExtensionInformation.Active);
			ExtensionForRecovery.Insert("SafeMode", UserExtensionInformation.SafeMode);
	
			UnsafeActionProtection = New UnsafeOperationProtectionDescription;
			UnsafeActionProtection.UnsafeOperationWarnings = UserExtensionInformation.UnsafeOperationWarnings;
			ExtensionForRecovery.Insert("UnsafeActionProtection", UnsafeActionProtection);
	
			ExtensionForRecovery.Insert("Name", UserExtensionInformation.Name);
			ExtensionForRecovery.Insert("UseDefaultRolesForAllUsers",
				UserExtensionInformation.UseDefaultRolesForAllUsers);
			ExtensionForRecovery.Insert("UsedInDistributedInfoBase",
				UserExtensionInformation.UsedInDistributedInfoBase);
			ExtensionForRecovery.Insert("Synonym", UserExtensionInformation.Synonym);
			ExtensionForRecovery.Insert("ModifiesDataStructure",
				UserExtensionInformation.ModifiesDataStructure);
			ExtensionForRecovery.Insert("UUID", XMLValue(UUIDType,
				UserExtensionInformation.UUID));
				
			ExtensionForRecovery.Insert("Data", FileDetails.Data);
			Result.RecoveryExtensions.Add(ExtensionForRecovery);
			
			DeleteFilesInAttempt(FileDetails.Path);
		EndIf;
		
		If UserExtensionInformation.ModifiesDataStructure Then
			ClearMessageWindow = True;
		EndIf;
	EndDo;
	
	DeleteFilesInAttempt(PathToCustomExtensionsFile);
		
	Return Result;
EndFunction

&AtServerNoContext
Function GetBinaryExtensionData(ReadingArchiveData, NameOfCustomExtensionFile)
	PathToUserExtensionFile = ExtractFileFromZipArchive(
		ReadingArchiveData,
		NameOfCustomExtensionFile);
		
	If PathToUserExtensionFile = Undefined Then
		Raise StrTemplate(NStr("vi = 'Không tìm thấy tệp dữ liệu mở rộng %1';
								|ru = 'Не найден файл данных расширения %1';
								|en = 'The %1 extension data file is not found'; fa = 'The %1 extension data file is not found';
								|it = 'Не найден файл данных расширения %1';
								|pl = 'Nie znaleziono pliku danych rozszerzenia %1';
								|tr = '%1 uzantı veri dosyası bulunamadı'"),
			NameOfCustomExtensionFile);
	EndIf;
	
	Return New Structure("Data,Path", 
		New BinaryData(PathToUserExtensionFile), PathToUserExtensionFile);
EndFunction

&AtServerNoContext
Function ExtensionsFrameForRecovery(FileNameAtServer)
	
	ReadingArchiveData = New ZipFileReader(FileNameAtServer);
	
	Try
		RecoveryExtensions = ExtensionFrameworksForRestoringInternal(ReadingArchiveData);
	Except
		ReadingArchiveData.Close();
		Raise;
	EndTry;
	
	ReadingArchiveData.Close();
	
	Return RecoveryExtensions; 
	
EndFunction

&AtServerNoContext
Function ExtensionFrameworksForRestoringInternal(ReadingArchiveData)
	
	RecoveryExtensions = New Array();
	PathToExtensionsFile = ExtractFileFromZipArchive(ReadingArchiveData, "Extensions.xml");
	
	If PathToExtensionsFile = Undefined Then
		Return RecoveryExtensions;
	EndIf;

	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToExtensionsFile);
	XMLReader.MoveToContent();

	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		XMLReader.Close();
		DeleteFilesInAttempt(PathToExtensionsFile);
		Return RecoveryExtensions;
	EndIf;

	While XMLReader.Read() Do

		If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Extension" Then
			Continue;
		EndIf;

		ModifiesDataStructure = XMLValue(Type("Boolean"), XMLReader.AttributeValue("ModifiesDataStructure"));
		Description = XMLValue(Type("String"), XMLReader.AttributeValue("Name"));
		FrameAttribute = XMLReader.AttributeValue("IsFrame");
		FileNameAttribute = XMLReader.AttributeValue("FileName");
		
		If Not ModifiesDataStructure Or FrameAttribute = Undefined Or FileNameAttribute = Undefined Then
			Continue;
		EndIf;

		IsFrame = XMLValue(Type("Boolean"), FrameAttribute);
		ExtensionFileName = XMLValue(Type("String"), FileNameAttribute);

		If Not ValueIsFilled(ExtensionFileName) Or Not IsFrame Then
			Continue;
		EndIf;

		PathToExtensionFile = ExtractFileFromZipArchive(ReadingArchiveData, ExtensionFileName);
		If PathToExtensionFile = Undefined Then
			Raise StrTemplate(NStr("vi = 'Không tìm thấy tệp dữ liệu mở rộng %1';
									|ru = 'Не найден файл данных расширения %1';
									|en = 'The %1 extension data file is not found'; fa = 'The %1 extension data file is not found';
									|it = 'File dati estensione %1 non trovato';
									|pl = 'Nie znaleziono pliku danych rozszerzenia %1';
									|tr = '%1 uzantı veri dosyası bulunamadı'"), ExtensionFileName);
		EndIf;

		ExtensionForRecovery = New Structure;
		ExtensionForRecovery.Insert("Name", Description);
		
		UserExtensionFileData = New BinaryData(PathToExtensionFile);
		ExtensionForRecovery.Insert("Data", UserExtensionFileData);

		RecoveryExtensions.Add(ExtensionForRecovery);

		DeleteFilesInAttempt(PathToExtensionFile);
		
	EndDo;
	
	XMLReader.Close();
	DeleteFilesInAttempt(PathToExtensionsFile);
	
	Return RecoveryExtensions;
	
EndFunction

&AtServer
Procedure CompleteDownloadOnServer()
	
	If ValueIsFilled(JobID) Then
		
		ImportJob = BackgroundJobs.FindByUUID(JobID);
		
		If ImportJob <> Undefined And ImportJob.State = BackgroundJobState.Active Then
			ImportJob.Cancel();
		EndIf;
		
		JobID = Undefined;
		
	EndIf;

	DeleteTemporaryDataAfterUpload(TemporaryStorageFileName);
	TemporaryStorageFileName = "";
				
	SaaSOperations.RemoveExclusiveLock(UseMultithreading());
	ExclusiveLockSet = False;
		
EndProcedure

&AtServerNoContext
Procedure DeleteTemporaryDataAfterUpload(StorageFileName)

	If Not ValueIsFilled(StorageFileName) Then
		Return;
	EndIf;
	
	FilesCTL.DeleteTemporaryStorageFile(StorageFileName);
	
EndProcedure

#EndRegion

#Region ErrorProcessing

// Show warning errors.
// 
// Parameters:
//  NoticeParameters - See NewParametersNotificationErrorWarning
&AtClient
Procedure ShowWarningErrors(NoticeParameters)
	
	ErrorWarningText = NoticeParameters.Text;
	Picture = ?(NoticeParameters.IsError, PictureLib.Error32, PictureLib.Warning32);
		
	Items.ErrorsWarningsHint.Title = NoticeParameters.ToolTip;
	Items.ErrorsWarningsRecommendation.Title = NoticeParameters.Recommendation;
	Items.ErrorsWarningsPicture.Picture = Picture;
	Items.DownloadWizardPages.CurrentPage = Items.ErrorWarningPage;
	
	Title = FormTitleByPageName(
		Items.DownloadWizardPages.CurrentPage.Name,
		NoticeParameters.IsError);
	
	If ValueIsFilled(NoticeParameters.WholeText) Then
		WriteErrorToEventLog(NoticeParameters.WholeText);
	EndIf;
	 
EndProcedure

// New parameters for notification of an error warning.
// 
// Returns:
//  Structure - New Parameters For Notification Of An Error Warning:
// * IsError - Boolean -
// * Text - String -
// * WholeText - String -
// * ToolTip - String -
// * Recommendation - String -
&AtClient
Function NewParametersNotificationErrorWarning()
	
	NoticeParameters = New Structure();
	NoticeParameters.Insert("IsError", True);
	NoticeParameters.Insert("Text", "");
	NoticeParameters.Insert("WholeText", "");
	NoticeParameters.Insert("ToolTip", "");
	NoticeParameters.Insert("Recommendation", "");
	
	Return NoticeParameters;
	
EndFunction

&AtServerNoContext
Procedure WriteErrorToEventLog(ErrorText, EventName = Undefined)
	
	If EventName = Undefined Then
		EventName = EventLogEventName();
	EndIf;
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Error,
		,
		,
		ErrorText);
	
EndProcedure

#EndRegion

#Region FormControl

&AtClient
Procedure QuestionBeforeClosingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	CancelImportAndCloseForm();
	
EndProcedure

&AtClient
Procedure CancelImportAndCloseForm()
	
	CompleteDownloadOnServer();
	Close();
	
EndProcedure

&AtServer
Procedure HandleInterruptedBootProcedure()
		
	If Not Parameters.DownloadProcedureAborted Then
		Return;
	EndIf;
	
	ImportParameters = Constants.ParametersForLaunchingInteractiveImportProcedure.Get().Get(); // Structure
		
	If ImportParameters = Undefined Then
		Return;	
	EndIf;	
	
	FillPropertyValues(ThisObject, ImportParameters);
	
	If Not ImportParameters.Property("NotDownloadTheExtensionConfiguration") Then
	
		OutdatedParameters = New Structure("DownloadTheExtensionConfiguration", True);
		FillPropertyValues(OutdatedParameters, ImportParameters);
		
		NotDownloadTheExtensionConfiguration = Not OutdatedParameters.DownloadTheExtensionConfiguration;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetExclusiveLockAndContinueImport()
	
	SetExclusiveLock();
	
	If ExclusiveLockSet Then
		
		Items.DownloadWizardPages.CurrentPage = Items.PageMain;
		Items.Continue.Visible = False;
		
	Else
		
		ThisIsContinuationOfDownload = ValueIsFilled(UsersList);
		
		FillUserList();
		
		If ThisIsContinuationOfDownload Then
			
			Common.MessageToUser(
				NStr("vi = 'Không phải tất cả phiên làm việc của người dùng bị chấm dứt';
					|ru = 'Не все сеансы пользователей завершены';
					|en = 'Not all user sessions are closed'; fa = 'Not all user sessions are closed';
					|it = 'Не все сеансы пользователей завершены';
					|pl = 'Not all user sessions are closed';
					|tr = 'Tüm kullanıcı oturumları sonlandırılmadı'"),
				,
				"UsersList");
			
		EndIf;
		
	EndIf;
	
	Title = FormTitleByPageName(Items.DownloadWizardPages.CurrentPage.Name);
	
EndProcedure

&AtServer
Procedure FillInFormElementsAttributes()
	
	PromptForIBAdministrationParameters = True;
	InfoBaseSessionNumber = InfoBaseSessionNumber();
	IsWebClient = Common.IsWebClient();
	IsFileInformationBase = Common.FileInfobase();
	ParallelLoadingOptions = ExportImportDataInternal.ParallelDataExportImportParameters();
	
	If ParallelLoadingOptions.AvailableUsage Then
		ImportDataJobsCount = ParallelLoadingOptions.ThreadsCount;
	Else
		ImportDataJobsCount = 1;
		Items.ImportDataJobsCount.Visible = False;
	EndIf;
	
	If IsFileInformationBase Or Not Users.IsFullUser(, True) Then
		Items.UsersListTerminateSession.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FormTitleByPageName(Val PageName, Val DataLoadingError = False)
	
	DefaultTitle = NStr("vi = 'Kết nhập dữ liệu từ Server';
						|ru = 'Загрузка данных из сервиса';
						|en = 'Import data from the service'; fa = 'Import data from the service';
						|it = 'Download dei dati dal servizio';
						|pl = 'Pobieranie danych z serwisu';
						|tr = 'Verileri hizmetten indir'");
	
	If Not ValueIsFilled(PageName) Then
		Return DefaultTitle;
	ElsIf PageName = "BlockingErrorPage" Then
		Return NStr("vi = 'Lỗi phong tỏa cơ sở thông tin';
					|ru = 'Ошибка блокировки информационной базы';
					|en = 'An error occurred when locking the infobase'; fa = 'An error occurred when locking the infobase';
					|it = 'Ошибка блокировки информационной базы';
					|pl = 'An error occurred when locking the infobase';
					|tr = 'İnfobase''i kilitleme hatası'");
	ElsIf PageName = "PageMain" Then
		Return NStr("vi = 'Chuẩn bị kết nhập dữ liệu';
					|ru = 'Подготовка к загрузке данных';
					|en = 'Prepare to import data'; fa = 'Prepare to import data';
					|it = 'Подготовка к загрузке данных';
					|pl = 'Prepare to import data';
					|tr = 'Verileri yüklemeye hazırlık yapılıyor'");
	ElsIf PageName = "ErrorWarningPage" And DataLoadingError Then
		Return NStr("vi = 'Lỗi kết nhập dữ liệu';
					|ru = 'Ошибка загрузки данных';
					|en = 'Data import error'; fa = 'Data import error';
					|it = 'Ошибка загрузки данных';
					|pl = 'Data import error';
					|tr = 'Veri yükleme hatası'");
	ElsIf PageName = "ErrorWarningPage" Then
		Return NStr("vi = 'Hoàn tất kết nhập dữ liệu';
					|ru = 'Завершение загрузки данных';
					|en = 'Complete data import'; fa = 'Complete data import';
					|it = 'Завершение загрузки данных';
					|pl = 'Complete data import';
					|tr = 'Veri yüklemesinin tamamlanması'");
	Else
		Return DefaultTitle;
	EndIf;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure RestartApplication()
	
	Terminate(True);
	
EndProcedure

&AtServer
Function UseMultithreading()
	
	Return ImportDataJobsCount > 1;
	
EndFunction

// Hash amount of the file.
// 
// Parameters: 
//  FileName - String - file name
// 
// Returns: 
//  Number - The hash sum of the file
&AtServerNoContext
Function TheHashSumOfTheFile(FileName)
			
	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.AppendFile(FileName);
	
	Return DataHashing.HashSum;
	
EndFunction

&AtServer
Procedure SetExclusiveLock(UseMultithreading = False)
	
	ExclusiveLockSet = False;
	
	Try
		
		SaaSOperations.SetExclusiveLock(UseMultithreading);
		ExclusiveLockSet = True;
		
	Except
		
		ErrorText = StrTemplate(
			NStr("vi = 'Không thể thiết lập phong tỏa độc quyền cơ sở thông tin.
				 |Không thể bắt đầu tải trong khi những người sử dụng khác đang làm việc với cơ sở thông tin.
				 |
				 |%1';
				 |ru = 'Не удалось установить монопольную блокировку информационной базы.
				 |Загрузка не сможет начаться, пока другие пользователи работают с информационной базой.
				 |
				 |%1';
				 |en = 'Cannot set the exclusive infobase lock.
				 |The import cannot be started while other users use the infobase.
				 |
				 |%1'; fa = 'Cannot set the exclusive infobase lock.
				 |The import cannot be started while other users use the infobase.
				 |
				 |%1';
				 |it = 'Не удалось установить монопольную блокировку информационной базы.
				 |Загрузка не сможет начаться, пока другие пользователи работают с информационной базой.
				 |
				 |%1';
				 |pl = 'Cannot set the exclusive infobase lock.
				 |The import cannot be started while other users use the infobase.
				 |
				 |%1';
				 |tr = 'Özel infobase kilitlemesi yapılandırılamadı.
				 |Diğer kullanıcılar infobase ile çalışırken yükleme işlemi başlatılamayacaktır.
				 |
				 |%1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteErrorToEventLog(ErrorText);
		
	EndTry;
	
EndProcedure

&AtClientAtServerNoContext
Procedure DeleteFilesInAttempt(FileName)
	
	Try
		
		DeleteFiles(FileName);
		
	Except
		
		#If Server Then
			
		EventName = NStr("vi = 'Xóa tệp.Kết nhập dữ liệu từ dịch vụ';
						|ru = 'Удаление файла.Загрузка данных из сервиса';
						|en = 'Delete file.Import data from service'; fa = 'Delete file.Import data from service';
						|it = 'Удаление файла.Загрузка данных из сервиса';
						|pl = 'Delete file.Import data from service';
						|tr = 'Dosyanın silinmesi. Verilerin hizmet üzerinden yüklenmesi'", Common.DefaultLanguageCode());
		ErrorText = CloudTechnology.DetailedErrorText(ErrorInfo());
		WriteErrorToEventLog(ErrorText, EventName);
		
		#EndIf
		
	EndTry;
	
EndProcedure

&AtServerNoContext
Function EventLogEventName()
	
	Return NStr("vi = 'Kết nhập dữ liệu từ dịch vụ';
				|ru = 'Загрузка данных из сервиса';
				|en = 'Data import from service'; fa = 'Data import from service';
				|it = 'Download dei dati dal servizio';
				|pl = 'Pobieranie danych z serwisu';
				|tr = 'Verileri servisten içe aktar'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion
