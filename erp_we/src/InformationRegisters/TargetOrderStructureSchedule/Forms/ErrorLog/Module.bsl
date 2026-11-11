
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.Property("ProductionOrder", ProductionOrder) Then
		ExceptionText = NStr("vi = 'Chưa truyền tham số bắt buộc';
							|ru = 'Не переданы обязательные параметры';
							|en = 'Required parameters are not passed'; fa = 'Required parameters are not passed';
							|it = 'Non sono indicati i parametri necessari';
							|pl = 'Nie są przekazane wymagane parametry';
							|tr = 'Zorunlu parametreler belirtilmedi'");
		Raise ExceptionText;
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.ReportPage;
	IdleParameters = Undefined;
	
	UpdateAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartAwaitingLongAction Then
		AttachIdleHandler("StartWaitingForLongOperationWhenOpening", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;
	
	DetailProcessing = New DataCompositionDetailsProcess(
		ExplanationAddress,
		New DataCompositionAvailableSettingsSource(SchemaURL));
	
	AvailableAction = New Array;
	AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
	
	CallbackDescription = New CallbackDescription("ResultDetailProcessingCompletion", ThisObject);
	
	DetailProcessing.ShowActionChoice(
		CallbackDescription,
		Details,
		AvailableAction,
		,
		True);
	
EndProcedure

&AtClient
Procedure ResultDetailProcessingCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export
	
	If ValueIsFilled(ChosenActionParameter) And ThisIsDocumentCatalogLink(ChosenActionParameter) Then
		
		ShowValue(, ChosenActionParameter);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThisIsDocumentCatalogLink(Value)
	
	ValueType = TypeOf(Value);
	
	Return Catalogs.AllRefsType().ContainsType(ValueType) Or Documents.AllRefsType().ContainsType(ValueType);
	
EndFunction

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Items.GroupPages.CurrentPage = Items.ReportPage;
	IdleParameters = Undefined;
	
	UpdateOnClient();
	
EndProcedure

&AtClient
Procedure ShouldRecalculate(Command)
	
	RecalculateAtServer();
	
	IdleParameters = New Structure;
	IdleParameters.Insert("MaxInterval", 30);
	IdleParameters.Insert("CurrentInterval", 1);
	IdleParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
	AttachIdleHandler("Attachable_CheckEndOfCalculation", 1, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartWaitingForLongOperationWhenOpening()
	
	StartAwaitingLongAction("UpdateInBackgroundCompletion");
	
EndProcedure

&AtClient
Procedure UpdateOnClient() Export
	
	UpdateAtServer();
	
	If StartAwaitingLongAction Then
		StartAwaitingLongAction("UpdateInBackgroundCompletion");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAtServer()
	
	SpreadsheetDocument.Clear();
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Điền nhật ký lỗi tính toán lịch biểu tiêu chuẩn';
			|ru = 'Заполнение журнала ошибок расчета нормативного графика';
			|en = 'Fill the error log of the standard schedule calculation'; fa = 'Fill the error log of the standard schedule calculation';
			|it = 'Compilazione del registro degli errori di calcolo del grafico normativo';
			|pl = 'Wypełnienie dziennika błędów obliczenia harmonogramu normatywnego';
			|tr = 'Standart programın hesaplanmasında hata günlüğünün doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.TargetOrderStructureSchedule.OutputErrorLog",
		New Structure("OrderDocument", ProductionOrder),
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		StartAwaitingLongAction = True;
	Else
		ProcessResultInBackground(TimeConsumingOperation);
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateInBackgroundCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		ProcessResultInBackground(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultInBackground(Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			SpreadsheetDocument = FillingData.SpreadsheetDocument;
			
			SchemaURL       = PutToTempStorage(FillingData.DataCompositionSchema, UUID);
			ExplanationAddress = PutToTempStorage(FillingData.DetailsData, UUID);
			
			Items.SpreadsheetDocument.ViewScalingMode = ViewScalingMode.Normal;
			
		EndIf;
	
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction(ProcedureName)
	
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		New CallbackDescription(ProcedureName, ThisObject));
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure RecalculateAtServer()
	
	InformationRegisters.TargetOrderStructureSchedule.RecalculateOrderSchedule(ProductionOrder);
	
EndProcedure

&AtClient
Procedure Attachable_CheckEndOfCalculation()
	
	If IdleParameters <> Undefined Then
		
		If CalculationIsCompleted(ProductionOrder) Then
			
			Items.GroupPages.CurrentPage = Items.ReportPage;
			IdleParameters = Undefined;
			UpdateOnClient();
			
		Else
			
			Items.GroupPages.CurrentPage = Items.PageWait;
			
			If IdleParameters.CurrentInterval < IdleParameters.MaxInterval Then
				IdleParameters.CurrentInterval = IdleParameters.CurrentInterval
					* IdleParameters.IntervalIncreaseCoefficient;
				If IdleParameters.CurrentInterval > IdleParameters.MaxInterval Then
					IdleParameters.CurrentInterval = IdleParameters.MaxInterval;
				EndIf;
			EndIf;
			
			AttachIdleHandler(
				"Attachable_CheckEndOfCalculation",
				IdleParameters.CurrentInterval,
				True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculationIsCompleted(ProductionOrder)
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OrderStructureCalculationProtocol AS CalculationProtocol
		|WHERE
		|	CalculationProtocol.ProductionOrder = &ProductionOrder
		|	AND CalculationProtocol.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError)
		|
		|UNION
		|
		|SELECT
		|	TRUE
		|WHERE
		|	TRUE NOT IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
		|		WHERE
		|			Jobs.ProductionOrder = &ProductionOrder)");
	Query.SetParameter("ProductionOrder", ProductionOrder);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion
