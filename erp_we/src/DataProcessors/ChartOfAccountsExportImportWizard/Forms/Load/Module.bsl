#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseSeveralChartsOfAccountsInFinancialAccounting = GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting");
	
	If UseSeveralChartsOfAccountsInFinancialAccounting Then
		
		Parameters.Property("ChartOfAccounts", Object.ChartOfAccounts);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Setting the current transition table.
	TableOfTransitionsByScenario();
	
	// We are positioning ourselves at the first step of the assistant.
	SetNavigationNumber(1);
	
	TotalCreated = 0;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	WarningText = NStr("vi = 'Đóng trợ giúp?';
						|ru = 'Закрыть помощник?';
						|en = 'Do you want to close the wizard?'; fa = 'Do you want to close the wizard?';
						|it = 'Chiudere assistente?';
						|pl = 'Zamknij asystenta?';
						|tr = 'Sihirbaz kapatılsın mı?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("AfterSelectingFileToDownload", ThisObject);
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Title = NStr("vi = 'Hãy chọn tệp để kết nhập dữ liệu';
							|ru = 'Выберите файл для загрузки данных';
							|en = 'Select a file to import the data'; fa = 'Select a file to import the data';
							|it = 'Selezionare un file per il caricamento dati';
							|pl = 'Wybierz plik do pobierania danych';
							|tr = 'Veri aktarımı için dosya seçin'");
	FileDialog.Filter = NStr("vi = 'Sổ Excel 97 (*.xls)|*.xls|Sổ Excel 2007 (*.xlsx)|*.xlsx|Bảng điện tử OpenDocument (*.ods)|*.ods|Văn bản dạng bảng (*.mxl)|*.mxl';
							|ru = 'Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Табличный документ (*.mxl)|*.mxl';
							|en = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl'; fa = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl';
							|it = 'Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabella Elettronica OpenDocument (*.ods)|*.ods|Documento tabulare (*.mxl)|*.mxl';
							|pl = 'Arkusz Excel 97 (*.xls)|*.xls|Arkusz Excel 2007 (*.xlsx)|*.xlsx|Tabela elektroniczna OpenDocument (*.ods)|*.ods|Dokument tabelaryczny (*.mxl)|*.mxl';
							|tr = 'Excel 97 kitabı (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|E-tablo belgesi (*.mxl)|*.mxl'");
	FileDialog.Multiselect = False;
	FileDialog.FilterIndex = 0;
	FileSystemClient.ShowSelectionDialog(Notification, FileDialog);
	
EndProcedure

&AtClient
Procedure ExplanationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("AfterSelectingFileToSaveTemplate", ThisObject);
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Filter = NStr("vi = 'Sổ Excel 97 (*.xls)|*.xls|Sổ Excel 2007 (*.xlsx)|*.xlsx|Bảng điện tử OpenDocument (*.ods)|*.ods|Văn bản dạng bảng (*.mxl)|*.mxl';
							|ru = 'Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Табличный документ (*.mxl)|*.mxl';
							|en = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl'; fa = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl';
							|it = 'Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabella Elettronica OpenDocument (*.ods)|*.ods|Documento tabulare (*.mxl)|*.mxl';
							|pl = 'Arkusz Excel 97 (*.xls)|*.xls|Arkusz Excel 2007 (*.xlsx)|*.xlsx|Tabela elektroniczna OpenDocument (*.ods)|*.ods|Dokument tabelaryczny (*.mxl)|*.mxl';
							|tr = 'Excel 97 kitabı (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|E-tablo belgesi (*.mxl)|*.mxl'");
	FileDialog.Title = NStr("vi = 'Hãy chỉ ra tên tệp để lưu khuôn in';
							|ru = 'Укажите имя файла для сохранения шаблона';
							|en = 'To save the template, specify the file name'; fa = 'To save the template, specify the file name';
							|it = 'Specificare il nome del file per salvare il modello';
							|pl = 'Podaj nazwę pliku do zapisywania szablonu';
							|tr = 'Numune kaydı için dosya adını belirt'");
	FileDialog.DefaultExt = "xls";
	FileDialog.Multiselect = False;
	FileDialog.FullFileName = NStr("vi = 'Khuôn in dữ liệu của hệ thống tài khoản';
									|ru = 'Шаблон данных плана счетов';
									|en = 'Chart of accounts data template'; fa = 'Chart of accounts data template';
									|it = 'Modello dei dati del piano di conti';
									|pl = 'Szablon danych planu kont';
									|tr = 'Hesap planı verileri şablonu'");
	FileDialog.FilterIndex = 0;
	FileSystemClient.ShowSelectionDialog(Notification, FileDialog);
	
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

&AtClient
Procedure TotalCreatedClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure("SpreadsheetDocument, ThisIsUpdateReport", TableCreated, False);
	OpenForm("DataProcessor.ChartOfAccountsExportImportWizard.Form.CreatedReport", FormParameters,,ThisObject);
	
EndProcedure

&AtClient
Procedure TotalUpdatedClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure("SpreadsheetDocument, ThisIsUpdateReport", Table_Updated, True);
	OpenForm("DataProcessor.ChartOfAccountsExportImportWizard.Form.CreatedReport", FormParameters,,ThisObject);
	
EndProcedure

&AtClient
Procedure TotalSkippedClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NotificationAfterClosingReportAboutMissed = New CallbackDescription("AfterClosingReportOnMissed", ThisObject);
	
	FormParameters = New Structure("SpreadsheetDocument", TableSkipped);
	OpenForm("DataProcessor.ChartOfAccountsExportImportWizard.Form.SkippedReport", FormParameters,,ThisObject,,,NotificationAfterClosingReportAboutMissed);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	CheckResult = CheckFillingClient();
	
	If CheckResult.HasErrors Then
		
		CommonClient.MessageToUser(CheckResult.ErrorDescription);
		
		Return;
		
	EndIf;
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	ForceCloseForm = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

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
	
	// Executing transition event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Setting the page display.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'Page to be displayed is not specified.'; fa = 'Page to be displayed is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	If Not IsBlankString(NavigationRowCurrent.DecorationPageName) Then
		
		Items.DecorationPanel.CurrentPage = Items[NavigationRowCurrent.DecorationPageName];
		
	EndIf;
	
	// Setting the current button by default.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If ConfirmButton <> Undefined Then
			
			ConfirmButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Transition event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// The handler is later.
			If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					NavigationNumber = NavigationNumber - 1;
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// The handler is pre-transitioned.
			If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "Attachable_[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					NavigationNumber = NavigationNumber + 1;
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'Page to be displayed is not specified.'; fa = 'Page to be displayed is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// handler for opening
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			NavigationNumber = NavigationNumber - 1;
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
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'Page to be displayed is not specified.'; fa = 'Page to be displayed is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// The handler of the processing of the last operation.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			NavigationNumber = NavigationNumber - 1;
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			And StrFind(Item.CommandName, CommandName) > 0 Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPageTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	ImportFile_();
	GoToNext = False;
	Return Undefined;
	
EndFunction

&AtClient
Procedure TableOfTransitionsByScenario()
	
	NavigationTable.Clear();
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 1;
	Transition.MainPageName     = "StartPage";
	Transition.NavigationPageName    = "NavigationStartPage";
	Transition.DecorationPageName    = "DecorationPageStart";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 2;
	Transition.MainPageName     = "SetupPage";
	Transition.NavigationPageName    = "NavigationPageFollowUp";
	Transition.DecorationPageName    = "DecorationPageFollowUp";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 3;
	Transition.MainPageName     = "WaitingPage";
	Transition.NavigationPageName    = "NavigationWaitPage";
	Transition.DecorationPageName    = "DecorationPageFollowUp";
	Transition.TimeConsumingOperation      = True;
	Transition.TimeConsumingOperationHandlerName = "WaitingPageTimeConsumingOperationProcessing";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 4;
	Transition.MainPageName     = "PageCompletion";
	Transition.NavigationPageName    = "NavigationEndPage";
	Transition.DecorationPageName    = "DecorationPageEnd";
	
EndProcedure

&AtClient
Procedure AfterSelectingFileToDownload(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		Object.FileName = Result[0];
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingReportOnMissed(Result, AdditionalParameters) Export
	
		If TypeOf(Result) = Type("SpreadsheetDocument") Then
		
		TableSkipped = Result;
		
		NavigationNumber = 3;
		
		NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
		If NavigationRowsCurrent.Count() = 0 Then
			Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
						|ru = 'Не определена страница для отображения.';
						|en = 'Page to be displayed is not specified.'; fa = 'Page to be displayed is not specified.';
						|it = 'Non è definita la pagina per visualizzazione.';
						|pl = 'Nie określono strony do odzwierciedlenia.';
						|tr = 'Gösterilecek sayfa tanımlanmamış.'");
		EndIf;
		
		NavigationRowCurrent = NavigationRowsCurrent[0];
		
		Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
		Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
		
		If Not IsBlankString(NavigationRowCurrent.DecorationPageName) Then
			
			Items.DecorationPanel.CurrentPage = Items[NavigationRowCurrent.DecorationPageName];
			
		EndIf;
		
		// Setting the current button by default.
		NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
		
		If NextButton <> Undefined Then
			
			NextButton.DefaultButton = True;
			
		Else
			
			ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
			
			If ConfirmButton <> Undefined Then
				
				ConfirmButton.DefaultButton = True;
				
			EndIf;
			
		EndIf;
			
		Try
			
			ImportData(False);
			
		Except
			
			HandleError(DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddLogEntry(Comment)
	
	WriteLogEvent(NStr("vi = 'Không thể kết xuất dữ liệu của hệ thống tài khoản';
						|ru = 'Не удалось выгрузить данные плана счетов';
						|en = 'Cannot export the chart of accounts data'; fa = 'Cannot export the chart of accounts data';
						|it = 'Non è stato possibile caricare i dati del piano di conti';
						|pl = 'Nie udało się przesłać danych planu kont';
						|tr = 'Hesap planı verileri dışa aktarılamadı'", Common.DefaultLanguageCode()),
							EventLogLevel.Error,,SynonymOfProcessing(),Comment);
	
EndProcedure

&AtServerNoContext
Function SynonymOfProcessing()
	Return Metadata.DataProcessors.ChartOfAccountsExportImportWizard.Synonym;
EndFunction

#Region UploadingChartOfAccounts

&AtClient
Procedure ImportFile_()
	
	If ValueIsFilled(Object.FileName) Then
		
		CallbackDescription = New CallbackDescription("DownloadDataFromAFile", ThisObject);
		FileImportParameters = FileSystemClient.FileImportParameters();
		FileImportParameters.FormIdentifier = ThisObject.UUID;
		FileImportParameters.Interactively = False;
		
		FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters, Object.FileName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadDataFromAFile(FileThatWasPut, AdditionalParameters) Export
	
	Try
		
		ImportData(True, FileThatWasPut)
		
	Except
		
		HandleError(DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

&AtClient
Procedure ImportData(FromFile, FileThatWasPut = Undefined)
	
	If FromFile Then
		
		FileExtention = CommonClientServer.ExtensionWithoutPoint(CommonClientServer.GetFileNameExtension(FileThatWasPut.Name));
		ExecutionResult = StartDownloadExecutionInBackground(MappingTable, FromFile, FileThatWasPut.Location, FileExtention);
		
	Else
		
		ExecutionResult = StartDownloadExecutionInBackground(MappingTable, FromFile);
		
	EndIf;
	
	If ExecutionResult.Status = "Completed2"
		Or ExecutionResult.Status = "Error" Then
		
		ProcessResult(ExecutionResult);
		Return;
		
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotificationOfEndOfLoadingChartOfAccounts = New CallbackDescription("ProcessResultOfUploadingInvoicePlan", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, NotificationOfEndOfLoadingChartOfAccounts, IdleParameters);
	
EndProcedure

&AtClient
Procedure ProcessResultOfUploadingInvoicePlan(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		ProcessResult(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Function StartDownloadExecutionInBackground(Val MappingTable, UploadFromFile, TempStorageAddress = Undefined, Extension = Undefined)
	
	ReportParameters = DataProcessors.ChartOfAccountsExportImportWizard.ParametersOfDownloadReports();
	
	ReportParameters.TableCreated = TableCreated;
	ReportParameters.Table_Updated = Table_Updated;
	ReportParameters.TableSkipped = TableSkipped;
	ReportParameters.TotalUpdated = TotalUpdated;
	ReportParameters.TotalSkipped = TotalSkipped;
	ReportParameters.TotalCreated = TotalCreated;
	
	ImportParameters = DataProcessors.ChartOfAccountsExportImportWizard.ParametersForLoadingChartOfAccounts();
	ImportParameters.MappingTable = MappingTable.Unload();
	ImportParameters.ReportParameters = ReportParameters;
	ImportParameters.UploadFromFile = UploadFromFile;
	ImportParameters.BinaryData = ?(UploadFromFile, GetFromTempStorage(TempStorageAddress), Undefined);
	ImportParameters.Extension = Extension; 
	
	If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		
		ImportParameters.ChartOfAccounts = Object.ChartOfAccounts;
		
	EndIf;
	
	BackgroundJobParameters = TimeConsumingOperations.FunctionExecutionParameters(ThisObject.UUID);
	BackgroundJobResult = TimeConsumingOperations.ExecuteFunction(BackgroundJobParameters, "DataProcessors.ChartOfAccountsExportImportWizard.DownloadDataFromAFile", ImportParameters);
	
	Return BackgroundJobResult;
	
EndFunction

&AtClient
Procedure ProcessResult(Result)
	
	If Result.Status = "Completed2" Then
		
		ReportParameters = GetFromTempStorage(Result.ResultAddress);
		CompleteDownload(ReportParameters);
		
	ElsIf Result.Status = "Error" Then
		
		HandleError(Result.DetailErrorDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HandleError(Comment)
	
	EventName = NStr("vi = 'Không thể kết nhập dữ liệu của hệ thống tài khoản';
					|ru = 'Не удалось загрузить данные плана счетов';
					|en = 'Cannot import the chart of accounts data'; fa = 'Cannot import the chart of accounts data';
					|it = 'Non è stato possibile scaricare i dati del piano di conti';
					|pl = 'Nie udało się pobrać danych planu kont';
					|tr = 'Hesap planı verileri içe aktarılamadı'", CommonClient.DefaultLanguageCode());
	
	AddLogEntry(Comment);
	
	Items.GroupSummaryInformation.Visible = True;
	Summary = Comment;
	
	If NavigationNumber = 3 Then
		
		SetNavigationNumber(NavigationNumber + 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteDownload(ReportParameters)
	
	SetNavigationNumber(NavigationNumber + 1);
	
	TotalUpdated = ReportParameters.TotalUpdated;
	TotalSkipped = ReportParameters.TotalSkipped;
	TotalCreated = ReportParameters.TotalCreated;
	
	TableCreated = ReportParameters.TableCreated;
	Table_Updated = ReportParameters.Table_Updated;
	TableSkipped = ReportParameters.TableSkipped;
	
	If TotalSkipped > 0 Then
		
		TextColorIssue = CommonClient.StyleColor("TextColorIssue");
		
		Items.TitleDecorationCompletion.Title = NStr("vi = 'Chưa kết nhập đầy đủ dữ liệu';
													|ru = 'Загрузка данных выполнена не полностью';
													|en = 'Data is not imported completely'; fa = 'Data is not imported completely';
													|it = 'Scaricamento dati non completato';
													|pl = 'Pobieranie danych nie zostało zakończone w całości';
													|tr = 'Verilerin içe aktarılması tam gerçekleşmedi'");
		Items.TitleDecorationCompletion.TextColor = TextColorIssue;
		Items.TotalSkipped.TextColor = TextColorIssue;
		
	Else
		
		FormTextColor = CommonClient.StyleColor("FormTextColor");
		
		Items.TitleDecorationCompletion.Title = NStr("vi = 'Đã hoàn thành kết nhập dữ liệu';
													|ru = 'Загрузка данных завершена';
													|en = 'Data import completed'; fa = 'ورود داده تکمیل شد';
													|it = 'Il download dei dati è completato';
													|pl = 'Pobieranie zostało zakończone';
													|tr = 'Veri içe aktarımı tamamlandı'");
		Items.TitleDecorationCompletion.TextColor = FormTextColor;
		Items.TotalSkipped.TextColor = FormTextColor;
		
	EndIf;
	
	Items.TotalCreated.Hyperlink = TotalCreated > 0;
	Items.TotalSkipped.Hyperlink = TotalSkipped > 0;
	Items.TotalUpdated.Hyperlink = TotalUpdated > 0;
	
EndProcedure

#EndRegion

#Region SavingTemplate

&AtClient
Procedure AfterSelectingFileToSaveTemplate(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		AddressInTempStorage = CreateTemplateOnServer(Result[0]);
		FileSystemClient.SaveFile(Undefined, AddressInTempStorage, Result[0]);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CreateTemplateOnServer(FullFileName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = PrintManagement.PrintFormTemplate("DataProcessor.ChartOfAccountsExportImportWizard.Template");
	
	RegionHeader = Template.GetArea("Header|Data");
	SpreadsheetDocument.Put(RegionHeader);
	
	FileExtention = CommonClientServer.ExtensionWithoutPoint(CommonClientServer.GetFileNameExtension(FullFileName));;
	
	FileName = GetTempFileName(FileExtention);
	If FileExtention = "xlsx" Then
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.XLSX);
		
	ElsIf FileExtention = "xls" Then
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.XLS);
		
	ElsIf FileExtention = "ods" Then
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.ODS);
		
	Else 
		
		SpreadsheetDocument.Write(FileName, SpreadsheetDocumentFileType.MXL);
		
	EndIf;
	
	BinaryData = New BinaryData(FileName);
	
	AddressInTempStorage = PutToTempStorage(BinaryData, AddressInTempStorage);
	
	FileSystem.DeleteTempFile(FileName);
	
	Return AddressInTempStorage;
	
EndFunction

#EndRegion

&AtClient
Function CheckFillingClient()
	
	CheckResult = New Structure;
	HasErrors = False;
	ErrorDescription = "";
	
	If Items.PanelMain.CurrentPage = Items.SetupPage Then
		
		If UseSeveralChartsOfAccountsInFinancialAccounting
			And Not ValueIsFilled(Object.ChartOfAccounts) Then
			
			HasErrors = True;
			ErrorDescription = NStr("vi = 'Chưa điền hệ thống tài khoản.';
									|ru = 'Не заполнен план счетов.';
									|en = 'The chart of accounts is not filled.'; fa = 'The chart of accounts is not filled.';
									|it = 'Не заполнен план счетов.';
									|pl = 'The chart of accounts is not filled.';
									|tr = 'Hesap planı doldurulmadı.'");
			
		EndIf;
		
		If Not ValueIsFilled(Object.FileName) Then
			
			HasErrors = True;
			ErrorDescription = ErrorDescription + 
				?(IsBlankString(ErrorDescription),"", Chars.LF) + 
				NStr("vi = 'Chưa điền tên tệp.';
					|ru = 'Не заполнено имя файла.';
					|en = 'The file name is not filled.'; fa = 'The file name is not filled.';
					|it = 'Не заполнено имя файла.';
					|pl = 'The file name is not filled.';
					|tr = 'Dosya adı doldurulmadı'");
			
		EndIf;
		
	EndIf;
	
	CheckResult.Insert("HasErrors", HasErrors);
	CheckResult.Insert("ErrorDescription", ErrorDescription);
	
	Return CheckResult;
	
EndFunction

#EndRegion
