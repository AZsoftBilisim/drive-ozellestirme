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
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("StandaloneWorkstation") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	StandaloneWorkstation = Parameters.StandaloneWorkstation;
	
	If Not ValueIsFilled(StandaloneWorkstation) Then
		Raise NStr("vi = 'Chưa đặt chỗ làm việc độc lập.';
					|ru = 'Не задано автономное рабочее место.';
					|en = 'Standalone workstation is not specified.'; fa = 'Standalone workstation is not specified.';
					|it = 'Posto di lavoro autonomo non indicato.';
					|pl = 'Nie określono miejsca pracy offline.';
					|tr = 'Çevrimdışı çalışma alanı belirtilmedi.'");
	EndIf;
	
	StandaloneWorkstationDeletionEventLogMessageText = StandaloneModeInternal.StandaloneWorkstationDeletionEventLogMessageText();
	
	SetMainScenario();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Selecting the first wizard step
	SetNavigationNumber(1);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure StopDataSynchronization(Command)
	
	GoToNext();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

// Wait handlers

&AtClient
Procedure TimeConsumingOperationIdleHandler()
	
	Try
		
		If JobCompleted(JobID) Then
			
			TimeConsumingOperation = False;
			TimeConsumingOperationCompleted = True;
			GoToNext();
			
		Else
			
			DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
			AttachIdleHandler("TimeConsumingOperationIdleHandler", IdleHandlerParameters.CurrentInterval, True);
			
		EndIf;
		
	Except
		
		WriteErrorToEventLog(
			ErrorProcessing.DetailErrorDescription(ErrorInfo()), StandaloneWorkstationDeletionEventLogMessageText);
		
		TimeConsumingOperation = False;
		GoBack();
		ShowMessageBox(,NStr("vi = 'Trong quá trình làm việc đã xảy ra lỗi.';
							|ru = 'В процессе работы возникли ошибки.';
							|en = 'Errors occurred when processing.'; fa = 'Errors occurred when processing.';
							|it = 'Durante il processo di lavoro si sono verificati degli errori.';
							|pl = 'W procesie pracy zaistniały błędy.';
							|tr = 'İşlem sırasında hatalar oluştu.'"));
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

// Supplied part

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
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	// Set the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "StopDataSynchronization");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "Close");
		
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
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// OnNavigationToNextPage handler.
		If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
			And Not NavigationRow.TimeConsumingOperation Then
			
			ProcedureName = "[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
			
			Cancel = False;
			
			ReturnValue = Eval(ProcedureName);
			
			If Cancel Then
				
				SetNavigationNumber(NavigationNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// OnNavigationToPreviousPage handler.
		If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
			And Not NavigationRow.TimeConsumingOperation Then
			
			ProcedureName = "[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
			
			Cancel = False;
			
			ReturnValue = Eval(ProcedureName);
			
			If Cancel Then
				
				SetNavigationNumber(NavigationNumber + 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler.
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		ReturnValue = Eval(ProcedureName);
		
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
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationHandler handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		ReturnValue = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(NavigationNumber - 1);
			
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

&AtServer
Function NavigationTableNewRow(MainPageName, NavigationPageName, DecorationPageName = "")
	
	NewRow = NavigationTable.Add();
	
	NewRow.NavigationNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	NewRow.DecorationPageName    = DecorationPageName;
	NewRow.NavigationPageName    = NavigationPageName;
	
	Return NewRow;
	
EndFunction

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
Procedure GoToNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure GoBack()
	
	ChangeNavigationNumber(-1);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Redefined part - Service procedures and functions

&AtServer
Procedure DeleteStandaloneWorkstation1(Cancel, ErrorMessage = "")
	
	DeletionContext = New Structure("StandaloneWorkstation", StandaloneWorkstation);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Xóa chỗ làm việc độc lập';
														|ru = 'Удаление автономного рабочего места';
														|en = 'Delete standalone workstation'; fa = 'Delete standalone workstation';
														|it = 'Eliminazione del posto di lavoro autonomo';
														|pl = 'Usuwanie miejsca pracy offline';
														|tr = 'Çevrimdışı çalışma alanını sil'");
	ExecutionParameters.RunNotInBackground1 = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"StandaloneModeInternal.DeleteStandaloneWorkstation1",
		DeletionContext,
		ExecutionParameters);
	
	If BackgroundJob.Status = "Running" Then
		TimeConsumingOperation = True;
		JobID = BackgroundJob.JobID;
	ElsIf BackgroundJob.Status = "Completed2" Then
		Return;
	Else
		Cancel = True;
		ErrorMessage = BackgroundJob.BriefErrorDescription;
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			ErrorMessage = BackgroundJob.DetailErrorDescription;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteErrorToEventLog(ErrorMessageString, Event)
	
	WriteLogEvent(Event, EventLogLevel.Error,,, ErrorMessageString);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The redefined part is Transition event Handlers

&AtClient
Function Attachable_WaitTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	TimeConsumingOperation = False;
	TimeConsumingOperationCompleted = False;
	JobID = Undefined;
	
	ErrorMessage = "";
	DeleteStandaloneWorkstation1(Cancel, ErrorMessage);
	
	If Cancel Then
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi xóa chỗ làm việc độc lập đã xảy ra lỗi: %1';
				|ru = 'При удалении автономного рабочего места возникли ошибки: %1';
				|en = 'Errors occurred when deleting the standalone workstation: %1'; fa = 'Errors occurred when deleting the standalone workstation: %1';
				|it = 'Durante l''eliminazione della postazione di lavoro autonoma si sono verificati errori: %1';
				|pl = 'Podczas usunięcia miejsca pracy offline zaistnieli błędy: %1';
				|tr = 'Çevrimdışı çalışma alanı silinirken hatalar oluştu: %1'"), ErrorMessage));
		
	ElsIf Not TimeConsumingOperation Then
		
		Notify("DeleteStandaloneWorkstation");
		
	EndIf;
	
EndFunction

&AtClient
Function Attachable_TimeConsumingOperationWaitingTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If TimeConsumingOperation Then
		
		GoToNext = False;
		
		DataExchangeClient.InitIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("TimeConsumingOperationIdleHandler", IdleHandlerParameters.CurrentInterval, True);
		
	EndIf;
	
EndFunction

&AtClient
Function Attachable_TimeConsumingOperationWaitingCompletionTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If TimeConsumingOperationCompleted Then
		
		Notify("DeleteStandaloneWorkstation");
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// The redefined part is Initialization of assistant transitions

&AtServer
Procedure SetMainScenario()
	
	NavigationTable.Clear();
	
	NewNavigation = NavigationTableNewRow("Begin", "NavigationStartPage");
	
	NewNavigation = NavigationTableNewRow("Waiting", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_WaitTimeConsumingOperationProcessing";
	
	NewNavigation = NavigationTableNewRow("Waiting", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_TimeConsumingOperationWaitingTimeConsumingOperationProcessing";
	
	NewNavigation = NavigationTableNewRow("Waiting", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_TimeConsumingOperationWaitingCompletionTimeConsumingOperationProcessing";
	
	NewNavigation = NavigationTableNewRow("End", "NavigationEndPage");
	
EndProcedure

#EndRegion
