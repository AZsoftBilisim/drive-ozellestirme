
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	ExecutedImportStatus = False;
	// Setting the current transition table
	ScriptTransitions();
	// Positioning ourselves at the first step of the assistant
	SetNavigationNumber(1);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ModelFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription(
		"ModelFileNameExtensionEnabled",
		ThisObject);
	
	FileSystemClient.AttachFileOperationsExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure DetailedInformationClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("Data", SynonymOfProcessing());
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	FormParameters.Insert("Level", FilterByLevel);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region SectionInitializingTransitionsInAssistant

// Transition parameters.
// 
// Returns:
//  Structure - Transition Parameters:
// * NavigationNumber - Number -
// * MainPageName - String -
// * NavigationPageName - String -
// * DecorationPageName - String -
// * OnOpenHandlerName - String -
// * NameOfTheHandlerAfterOpening - String -
// * OnNavigationToNextPageHandlerName - String -
// * OnSwitchToPreviousPageHandlerName - String -
&AtClient
Function MigrationParameters()
	
	MigrationParameters = New Structure;
	MigrationParameters.Insert("NavigationNumber", 0);
	MigrationParameters.Insert("MainPageName", "");
	MigrationParameters.Insert("NavigationPageName", "");
	MigrationParameters.Insert("DecorationPageName", "");
	MigrationParameters.Insert("OnOpenHandlerName", "");
	MigrationParameters.Insert("NameOfTheHandlerAfterOpening", "");
	MigrationParameters.Insert("OnNavigationToNextPageHandlerName", "");
	MigrationParameters.Insert("OnSwitchToPreviousPageHandlerName", "");
	
	Return MigrationParameters;
	
EndFunction

&AtClient
Procedure ScriptTransitions()
	
	Transitions.Clear();
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 1;
	MigrationParameters.MainPageName = "PageGreeting";
	MigrationParameters.NavigationPageName = "NavigationStartPage";
	MigrationParameters.DecorationPageName = "DecorationPageStart";
	MigrationParameters.OnOpenHandlerName = "PageGreeting_OnOpen";
	MigrationParameters.OnNavigationToNextPageHandlerName = "PageGreeting_OnOpenNext";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 2;
	MigrationParameters.MainPageName = "WaitingPage";
	MigrationParameters.NavigationPageName = "NavigationWaitPage";
	MigrationParameters.DecorationPageName = "PageSceneryWaiting";
	MigrationParameters.OnOpenHandlerName = "WaitingPage_OnOpen";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 3;
	MigrationParameters.MainPageName = "PageCompletion";
	MigrationParameters.NavigationPageName = "NavigationEndPage";
	MigrationParameters.DecorationPageName = "DecorationPageEnd";
	MigrationParameters.OnOpenHandlerName = "PageCompletion_OnOpen";
	AddTransition(MigrationParameters);
	
EndProcedure

&AtServer
Procedure AddTransition(MigrationParameters)
	
	NewRow = Transitions.Add();
	
	NewRow.NavigationNumber = MigrationParameters.NavigationNumber;
	NewRow.MainPageName     = MigrationParameters.MainPageName;
	NewRow.DecorationPageName    = MigrationParameters.DecorationPageName;
	NewRow.NavigationPageName    = MigrationParameters.NavigationPageName;
	
	NewRow.OnNavigationToNextPageHandlerName = MigrationParameters.OnNavigationToNextPageHandlerName;
	NewRow.OnSwitchToPreviousPageHandlerName = MigrationParameters.OnSwitchToPreviousPageHandlerName;
	NewRow.OnOpenHandlerName      = MigrationParameters.OnOpenHandlerName;
	NewRow.NameOfTheHandlerAfterOpening    = MigrationParameters.NameOfTheHandlerAfterOpening;
	
EndProcedure

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	NavigationNumber = Value;
	If NavigationNumber < 0 Then
		NavigationNumber = 0;
	EndIf;
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Click event handlers
	If IsMoveNext Then
		
		NavigationRows = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// The handler is later
		If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName) Then
			
			ProcedureName = "Attachable_[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
			
			Cancel = False;
			
			Result = Eval(ProcedureName);
			
			If Cancel Then
				SetNavigationNumber(NavigationNumber - 1);
				Return;
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// The handler is pre-transitioned
		If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName) Then
			
			ProcedureName = "Attachable_[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
			
			Cancel = False;
			
			Result = Eval(ProcedureName);
		
			If Cancel Then
				SetNavigationNumber(NavigationNumber + 1);
				Return;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Return;
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// handler for opening
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			SetNavigationNumber(NavigationNumber - 1);
			Return;
		ElsIf SkipPage Then
			If IsMoveNext Then
				SetNavigationNumber(NavigationNumber + 1);
				Return;
			Else
				SetNavigationNumber(NavigationNumber - 1);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	// Setting the current page display
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	AttachIdleHandler("ExecuteHandlerAfterOpening", 0.1, True);
	
EndProcedure

&AtClient
Procedure ExecuteHandlerAfterOpening()
	
	NavigationRowsCurrent = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Return;
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// Post-opening handler
	If Not IsBlankString(NavigationRowCurrent.NameOfTheHandlerAfterOpening) Then
		
		ProcedureName = "Attachable_[HandlerName]()";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.NameOfTheHandlerAfterOpening);
		
		Result = Eval(ProcedureName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region TransitionEventHandlersSection

&AtClient
Function Attachable_PageGreeting_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	Items.NextCommand.DefaultButton = True;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageGreeting_OnOpenNext(Cancel)
	
	ClearMessages();
	
	If IsBlankString(Object.ModelFileName) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra đường dẫn đến tệp dữ liệu';
				|ru = 'Не указан путь к файлу с данными';
				|en = 'Path to the file with data is not specified'; fa = 'Path to the file with data is not specified';
				|it = 'Non è stato specificato il percorso al file dei dati';
				|pl = 'Nie jest podana ścieżka do pliku z danymi';
				|tr = 'Veri dosyasının yolu belirtilmemiş'"), , "ModelFileName", "ModelFileName", Cancel);
		Return Undefined;
	EndIf;
	
	Handler = New CallbackDescription("LoadModel", ThisForm);
	BeginPutFileToServer(Handler, , , StorageAddress, Object.ModelFileName, UUID);
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageCompletion_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	Items.DoneCommand.DefaultButton = True;
	Items.DownloadStatusLabel.Title = 
		?(ExecutedImportStatus,
			NStr("vi = 'Đã kết nhập thành công';
				|ru = 'Загрузка успешно завершена';
				|en = 'Imported successfully'; fa = 'Imported successfully';
				|it = 'Download terminato con successo';
				|pl = 'Pobieranie zostało zakończone powodzeniem';
				|tr = 'İndirme işlemi başarıyla tamamlandı'"),
			NStr("vi = 'Chưa kết nhập';
				|ru = 'Загрузка не выполнена';
				|en = 'Import failed'; fa = 'ورود اطلاعات ناموفق بود';
				|it = 'Download non completato';
				|pl = 'Nie wykonano importu';
				|tr = 'İndirme işlemi tamamlanmadı'"));
	
	Items.LabelOfContinuationOptions.Title = 
		?(ExecutedImportStatus,
		NStr("vi = 'Hãy nhấn nút ""Đồng ý"" để thoát khỏi trợ giúp';
			|ru = 'Нажмите кнопку ""Готово"" для выхода из помощника.';
			|en = 'Click ""Finish"" to exit the wizard.'; fa = 'برای خروج از ویزارد روی «پایان» کلیک کنید.';
			|it = 'Cliccare il pulsante ""Completato"" per uscire dall''assistente.';
			|pl = 'Wciśnij przycisk ""Gotowe"", aby wyjść z asystenta.';
			|tr = 'Sihirbazdan çıkmak için ""Bitti"" butonuna tıklayın.'"),
		NStr("vi = 'Để thử kết nhập lần nữa, hãy nhấn nút ""Tiếp theo"" để thoát khỏi trợ giúp, hãy nhấn nút ""Đồng ý""';
			|ru = 'Для того чтобы попробовать загрузить еще раз, нажмите ""Назад"", для выхода из помощника, нажимите ""Готово""';
			|en = 'To try to import again, click ""Back""; click ""Finish"" to exit the wizard'; fa = 'To try to import again, click ""Back""; click ""Finish"" to exit the wizard';
			|it = 'Per riprovare premere ""Indietro"", per uscire dall''assistente premere ""Fine""';
			|pl = 'Aby spróbować pobrać jeszcze raz, naciśnij przycisk ""Wstecz"", aby wyjść z kreatora, kliknij przycisk ""Zakończ""';
			|tr = 'Tekrar indirmeyi denemek için ""Geri""ye basın, sihirbazdan çıkmak için ""Tamam""a basın'"));
		
	FillInSummaryInformation();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPage_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	If Not IsMoveNext Then
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure LoadModel(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Lỗi xử lý tệp';
										|ru = 'Ошибка обработки файла';
										|en = 'File processing error'; fa = 'File processing error';
										|it = 'Errore elaborazione file';
										|pl = 'Błąd przetwarzania pliku';
										|tr = 'Dosyanın veri işlemesinde hata'"));
		Return;
	EndIf;
	
	StorageAddress = Result.Address;
	If Not ValueIsFilled(StorageAddress) Then
		CommonClient.MessageToUser(NStr("vi = 'Lỗi xử lý tệp';
										|ru = 'Ошибка обработки файла';
										|en = 'File processing error'; fa = 'File processing error';
										|it = 'Errore elaborazione file';
										|pl = 'Błąd przetwarzania pliku';
										|tr = 'Dosyanın veri işlemesinde hata'"));
		Return;
	EndIf;
	
	TimeConsumingOperation = UploadToServer_1();
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("ImportIsCompleted", ThisObject, ResultAddress);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtServer
Function UploadToServer_1()
	
	ResultAddress = PutToTempStorage(Undefined, UUID);
	
	JobParameters = New Structure;
	JobParameters.Insert("BinaryData", GetFromTempStorage(StorageAddress));
	JobParameters.Insert("ResultAddress", ResultAddress);
	JobParameters.Insert("ThisIsInternationalAccountingModel", True);
	
	MethodName = "ExportImportOfFinancialAccountingAndBudgetingModels.ImportAccountingModel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = SynonymOfProcessing();
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Procedure FillInSummaryInformation()
	
	HasErrors = Not ExecutedImportStatus;
	
	Items.DetailedInformation.Visible = HasErrors;
	Items.Information.Visible = HasErrors;
	If HasErrors Then
		Information =  NStr("vi = 'Lỗi:';
							|ru = 'Ошибка:';
							|en = 'Error:'; fa = 'Error:';
							|it = 'Errore:';
							|pl = 'Błąd:';
							|tr = 'Hata:'") + Chars.LF+ ExchangeProtocol.GetText();
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportIsCompleted(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				ExecutedImportStatus = False;
				ExchangeProtocol.SetText(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				GetFromTempStorage(AdditionalParameters); 
				ExecutedImportStatus = True;
			EndIf;
			FillInSummaryInformation();
			ChangeNavigationNumber(+1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ModelFileNameExtensionEnabled(Result, AdditionalParameters) Export 
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter =  NStr("vi = 'Tệp kết xuất';
									|ru = 'Файл выгрузки';
									|en = 'Export file'; fa = 'فایل خروج';
									|it = 'File di upload';
									|pl = 'Plik przesyłania';
									|tr = 'Dışa aktarma dosyası'") + "(*.xml)|*.xml";
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn đường dẫn đến tệp kết xuất mô hình kế toán';
								|ru = 'Выберите путь к файлу выгрузки модели учета';
								|en = 'Select a path to the file of accounting model export'; fa = 'Select a path to the file of accounting model export';
								|it = 'Seleziona il percorso del file di caricamento del modello di bilancio';
								|pl = 'Wybierz ścieżkę do pliku ładowania modelu ewidencji';
								|tr = 'Muhasebe modeli yükleme dosyasının yolunu seçin'");
	
	CallbackDescription = New CallbackDescription(
		"ModelFileNameShowCompletionDialog",
		ThisObject);
		
	OpenFileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure ModelFileNameShowCompletionDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.ModelFileName = SelectedFiles[0];
	
EndProcedure

&AtServer
Function SynonymOfProcessing()
	Return Metadata.DataProcessors.BudgetingModelExportImportWizard.Synonym;
EndFunction

#EndRegion

#EndRegion
