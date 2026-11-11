#Region Internal

Procedure BeforeStart(Parameters) Export
	
	If Parameters.Cancel Then
		Return;
	EndIf;
	
	StartupOptions = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not StartupOptions.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	DownloadAborted = False;
	If Not StartupOptions.Property("UnloadingLoadingDataLoadingAborted", DownloadAborted) Then
		 DownloadAborted = CommonServerCallCTL.DownloadAborted(); 
	EndIf;
	
	If Not DownloadAborted Then
		Return;
	EndIf;
		
	Parameters.InteractiveHandler = New CallbackDescription(
		"ShowAbortedBootDialogBeforeStartingSystem",
		ThisObject);

	
EndProcedure

Procedure ShowAbortedDownloadDialogIfNecessary() Export
	
	DownloadAborted = CommonServerCallCTL.DownloadAborted();	
	
	If Not DownloadAborted Then
		Return;	
	EndIf;
	 
	ShowAbortedDownloadDialog();
		
EndProcedure

#EndRegion

#Region Private

Procedure ShowAbortedBootDialogBeforeStartingSystem(Parameters, AdditionalParameters) Export
	ShowAbortedDownloadDialog();
EndProcedure

Procedure ShowAbortedDownloadDialog()

	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Picture = PictureLib.Warning32;
	QuestionParameters.Title = NStr("vi = 'Đã ngắt thủ tục kết nhập';
									|ru = 'Процедура загрузки была прервана';
									|en = 'Import procedure was interrupted'; fa = 'Import procedure was interrupted';
									|it = 'Il download è stato interrotto';
									|pl = 'Procedura pobierania była przerwana';
									|tr = 'İçe aktarma prosedürü kesintiye uğradı'");
		
	CallbackDescriptionOnCompletion = New CallbackDescription(
		"QuestionAboutInterruptedDownloadCompletion",
		ThisObject);

	StandardSubsystemsClient.ShowQuestionToUser(
		CallbackDescriptionOnCompletion,
		NStr("vi = 'Để tiếp tục, cần chỉ ra một lần nữa tệp mà từ đó dữ liệu được kết nhập.';
			|ru = 'Для продолжения нужно будет снова указать файл, из которого загружались данные.';
			|en = 'To continue, you will need to specify the file from which the data was imported again.'; fa = 'To continue, you will need to specify the file from which the data was imported again.';
			|it = 'Per continuare bisogna nuovamente indicare il file fonte di caricamento dati.';
			|pl = 'W celu kontynuowania będzie trzeba ponownie wskazać plik, z którego były pobierane dane.';
			|tr = 'Devam etmek için, verilerin yüklendiği dosyayı tekrar belirtmeniz gerekecektir.'"),
		QuestionDialogMode.OK,
		QuestionParameters);
		
EndProcedure

Procedure QuestionAboutInterruptedDownloadCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = Undefined Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.DataImportFromService",
		New Structure("DownloadProcedureAborted", True),,,,,,
		FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

#EndRegion