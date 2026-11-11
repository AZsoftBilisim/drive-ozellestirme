#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	// Setting the current transition table.
	TableOfTransitionsByScenario();
	
	// We are positioning ourselves at the first step of the assistant.
	SetNavigationNumber(1);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseSeveralChartsOfAccountsInFinancialAccounting = GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting");
	
	If UseSeveralChartsOfAccountsInFinancialAccounting Then
		
		Parameters.Property("ChartOfAccounts", Object.ChartOfAccounts);
		
	EndIf;
	
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
	
	If ValueIsFilled(Object.ChartOfAccounts) Then
		
		FileName = NStr("vi = 'Dữ liệu của hệ thống tài khoản (%1)';
						|ru = 'Данные плана счетов (%1)';
						|en = 'Chart of accounts data (%1)'; fa = 'Chart of accounts data (%1)';
						|it = 'Dati del piano di conti (%1)';
						|pl = 'Dane planu kont (%1)';
						|tr = 'Hesap planı verileri (%1)'");
		FileName = StringFunctionsClientServer.SubstituteParametersToString(FileName, Object.ChartOfAccounts);
		
	Else
		
		FileName = NStr("vi = 'Dữ liệu của hệ thống tài khoản';
						|ru = 'Данные плана счетов';
						|en = 'Chart of accounts data'; fa = 'Chart of accounts data';
						|it = 'Dati del piano di conti';
						|pl = 'Dane planu kont';
						|tr = 'Hesap planı verileri'");
		
	EndIf;
	
	Notification = New CallbackDescription("AfterFileChoiceForSaving", ThisObject);
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Filter = NStr("vi = 'Sổ Excel 97 (*.xls)|*.xls|Sổ Excel 2007 (*.xlsx)|*.xlsx|Bảng điện tử OpenDocument (*.ods)|*.ods|Văn bản dạng bảng (*.mxl)|*.mxl';
							|ru = 'Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Табличный документ (*.mxl)|*.mxl';
							|en = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl'; fa = 'Microsoft Excel 97 (*.xls)|*.xls|Microsoft Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Spreadsheet document (*.mxl)|*.mxl';
							|it = 'Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabella Elettronica OpenDocument (*.ods)|*.ods|Documento tabulare (*.mxl)|*.mxl';
							|pl = 'Arkusz Excel 97 (*.xls)|*.xls|Arkusz Excel 2007 (*.xlsx)|*.xlsx|Tabela elektroniczna OpenDocument (*.ods)|*.ods|Dokument tabelaryczny (*.mxl)|*.mxl';
							|tr = 'Excel 97 kitabı (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|E-tablo belgesi (*.mxl)|*.mxl'");
	FileDialog.Title = NStr("vi = 'Chỉ định tên tệp để tải lên dữ liệu';
							|ru = 'Укажите имя файла для выгрузки данных';
							|en = 'Specify a file name for data export'; fa = 'Specify a file name for data export';
							|it = 'Indicare il nome del file per l''upload dei dati';
							|pl = 'Określ nazwę pliku, aby przesłać dane';
							|tr = 'Veri indirimi için dosya adını belirt'");
	FileDialog.DefaultExt = "xls";
	FileDialog.Multiselect = False;
	FileDialog.FilterIndex = 0;
	FileDialog.FullFileName = FileName;
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
	
	Try
		
		UploadChartOfAccounts();
		GoToNext = False;
		Return Undefined;
		
	Except
		
		HandleError(DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure UploadChartOfAccounts()
	
	ExecutionResult = StartUploadingInBackground(ThisObject.UUID, Object.FileName, Object.ChartOfAccounts);
	
	If ExecutionResult.Status = "Completed2"
		Or ExecutionResult.Status = "Error" Then
		
		ProcessResult(ExecutionResult);
		Return;
		
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotificationOfEndOfUploadingChartOfAccounts = New CallbackDescription("ProcessResultOfUploadingChartOfAccounts", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, NotificationOfEndOfUploadingChartOfAccounts, IdleParameters);
	
EndProcedure

&AtClient
Procedure ProcessResultOfUploadingChartOfAccounts(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		ProcessResult(Result);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StartUploadingInBackground(UID, FileName, ChartOfAccounts)
	
	ExportingParameters = DataProcessors.ChartOfAccountsExportImportWizard.ParametersForUploadingChartOfAccounts();
	ExportingParameters.FileName = FileName;
	ExportingParameters.ChartOfAccounts = ChartOfAccounts;
	ExportingParameters.Insert("UID", UID);
	
	BackgroundJobParameters = TimeConsumingOperations.FunctionExecutionParameters(UID);
	BackgroundJobResult = TimeConsumingOperations.ExecuteFunction(BackgroundJobParameters, "DataProcessors.ChartOfAccountsExportImportWizard.UploadAccountPlanData", ExportingParameters);
	
	Return BackgroundJobResult;
	
EndFunction

&AtClient
Procedure ProcessResult(Result)
	
	If Result.Status = "Completed2" Then
		
		SpreadsheetDocument = GetFromTempStorage(Result.ResultAddress);
		AddressInTempStorage = CompleteUpload(SpreadsheetDocument);
		
		FileSystemClient.SaveFile(Undefined, AddressInTempStorage, Object.FileName);
		SetNavigationNumber(NavigationNumber + 1);
		
	ElsIf Result.Status = "Error" Then
		
		HandleError(Result.DetailErrorDescription);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	SpreadsheetDocument - SpreadsheetDocument - A tabular document to write to a file
&AtServer
Function CompleteUpload(SpreadsheetDocument)
	
	FileExtention = CommonClientServer.ExtensionWithoutPoint(CommonClientServer.GetFileNameExtension(Object.FileName));
	
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
	
	AddressInTempStorage = PutToTempStorage(BinaryData);
	
	FileSystem.DeleteTempFile(FileName);
	
	Return AddressInTempStorage;
	
EndFunction

&AtClient
Procedure HandleError(Comment)
	
	EventName = NStr("vi = 'Không thể kết xuất dữ liệu của hệ thống tài khoản';
					|ru = 'Не удалось выгрузить данные плана счетов';
					|en = 'Cannot export the chart of accounts data'; fa = 'Cannot export the chart of accounts data';
					|it = 'Non è stato possibile caricare i dati del piano di conti';
					|pl = 'Nie udało się przesłać danych planu kont';
					|tr = 'Hesap planı verileri dışa aktarılamadı'", CommonClient.DefaultLanguageCode());
	
	AddLogEntry(Comment);
	
	Items.GroupSummaryInformation.Visible = True;
	Summary = Comment;
	
	If NavigationNumber = 3 Then
		
		SetNavigationNumber(NavigationNumber + 1);
		
	EndIf;
	
	If ValueIsFilled(Comment) Then
		
		TextColorIssue = CommonClient.StyleColor("TextColorIssue");
		
		Items.DecorationCompletion.Title = NStr("vi = 'Chưa thực hiện kết xuất dữ liệu.';
												|ru = 'Выгрузка данных не выполнена';
												|en = 'Data is not exported'; fa = 'Data is not exported';
												|it = 'Caricamento dei dati non eseguito';
												|pl = 'Przesyłanie danych nie zostało wykonane';
												|tr = 'Veri dışa aktarılmadı'");
		Items.DecorationCompletion.TextColor = TextColorIssue;
		
	Else
		
		FormTextColor = CommonClient.StyleColor("FormTextColor");
		
		Items.DecorationCompletion.Title = NStr("vi = 'Đã kết xuất thành công dữ liệu!';
												|ru = 'Выгрузка данных успешно завершена!';
												|en = 'Data is exported.'; fa = 'داده‌ها خارج شدند.';
												|it = 'Il caricamento è stato completato con successo';
												|pl = 'Przesyłanie danych zakończone pomyślnie!';
												|tr = 'Veriler başarıyla dışa aktarıldı!'");
		Items.DecorationCompletion.TextColor = FormTextColor;
		
	EndIf;
	
EndProcedure

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
	Transition.MainPageName     = "UploadPage";
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
Procedure AfterFileChoiceForSaving(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		Object.FileName = Result[0];
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SynonymOfProcessing()
	Return Metadata.DataProcessors.ChartOfAccountsExportImportWizard.Synonym;
EndFunction

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

&AtClient
Function CheckFillingClient()
	
	CheckResult = New Structure;
	HasErrors = False;
	ErrorDescription = "";
	
	If Items.PanelMain.CurrentPage = Items.UploadPage Then
		
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
