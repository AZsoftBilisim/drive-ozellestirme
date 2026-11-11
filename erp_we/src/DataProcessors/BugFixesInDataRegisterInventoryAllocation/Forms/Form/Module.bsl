#Region FormCommandsEventHandlers

&AtClient
Procedure FindErrors(Command)
	
	TimeConsumingOperation = FindErrorsInBackground();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		New CallbackDescription("FindErrorsInBackgroundCompletion", ThisObject),
		IdleParameters);
	
EndProcedure

&AtClient
Procedure FixErrors(Command)
	
	ClearMessages();
	TimeConsumingOperation = FixErrorsInBackground();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		New CallbackDescription("FixErrorsInBackgroundCompletion", ThisObject),
		IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FindErrorsInBackground()
	
	ProcedureParameters = New Structure();
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Sửa lỗi trong biểu ghi thông tin ""Phân bổ vật tư"": Tìm kiếm lỗi.';
														|ru = 'Исправление ошибок в регистре сведений ""Распределение запасов"": Поиск ошибок.';
														|en = 'Correction of errors in the ""Inventory allocation"" information register: Search for errors.'; fa = 'Correction of errors in the ""Inventory allocation"" information register: Search for errors.';
														|it = 'Исправление ошибок в регистре сведений ""Распределение запасов"": Поиск ошибок.';
														|pl = 'Correction of errors in the ""Inventory allocation"" information register: Search for errors.';
														|tr = '""Stokların Dağıtımı"" bilgi kaydındaki hataların düzeltilmesi. Hataların bulunması.'");
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessor.BugFixesInDataRegisterInventoryAllocation.ObjectModule.ErrorsCheckingCorrectnessOfInformationRegisterEntriesInventoryAllocationInBackground",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure FindErrorsInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		FindErrorsInBackgroundEndOnServer(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure FindErrorsInBackgroundEndOnServer(ResultAddress)
	
	ErrorTableIsTemporary = GetFromTempStorage(ResultAddress);
	If Not ValueIsFilled(ErrorTableIsTemporary) Then
		ErrorsTable.Clear();
		Return;
	EndIf;
	ErrorsTable.Load(ErrorTableIsTemporary);
	
EndProcedure

&AtServer
Function FixErrorsInBackground()
	
	Analysts = ErrorsTable.Unload(New Array(), "Products,Characteristic,Warehouse,Purpose");
	For Each Id In Items.ErrorsTable.SelectedRows Do
		TableRow = ErrorsTable.FindByID(Id);
		FillPropertyValues(Analysts.Add(), TableRow);
	EndDo;
	ProcedureParameters = New Structure("Analysts", Analysts);
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Sửa lỗi trong biểu ghi thông tin ""Phân bổ vật tư"": Tìm kiếm lỗi.';
														|ru = 'Исправление ошибок в регистре сведений ""Распределение запасов"": Исправление ошибок.';
														|en = 'Correction of errors in the ""Inventory allocation"" information register: Error correction.'; fa = 'Correction of errors in the ""Inventory allocation"" information register: Error correction.';
														|it = 'Исправление ошибок в регистре сведений ""Распределение запасов"": Исправление ошибок.';
														|pl = 'Correction of errors in the ""Inventory allocation"" information register: Error correction.';
														|tr = '""Stokların Dağıtımı"" bilgi kaydındaki hataların düzeltilmesi. Hataların düzeltilmesi.'");
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessor.BugFixesInDataRegisterInventoryAllocation.ObjectModule.CorrectInformationRegisterErrorsInventoryAllocationInBackground",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure FixErrorsInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		ClearMessages();
		FixErrorsInBackgroundEndingOnServer(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure FixErrorsInBackgroundEndingOnServer(ResultAddress)
	ProcessingResult = GetFromTempStorage(ResultAddress);
	For Each MessageText In ProcessingResult.Messages Do
		Common.MessageToUser(MessageText);
	EndDo;
EndProcedure

#EndRegion
