
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.ScheduleStatus Then
		
		ScheduleStatus = StatusWorkingSchedule();
		
	EndIf;
	
	ProductionStage = Parameters.CommandParameter;
	If ValueIsFilled(Parameters.Stage) Then
		ProductionStage = Parameters.Stage;
		KeyLot = Parameters.KeyLot;
		ProductionOrder = Parameters.ProductionOrder;
	EndIf;
	
	If ValueIsFilled(ProductionStage) Then
		
		SetFormHeader();
		GenerateReportOnServer();
		
	EndIf;
	
	OutputLegend();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartAwaitingLongAction Then
		
		AttachIdleHandler("StartAwaitingLongAction", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateReportOnClient();
	
EndProcedure

&AtClient
Procedure ToPlan_2(Command)
	
	PlanStageSchedule();
	
	If StartAwaitingLongAction Then
		
		If Not TimeConsumingOperationIdleHandler = ScheduleSchedulingHandler() Then
			NotifyAboutPlanningOfStageSchedule();
		EndIf;
		
		StartAwaitingLongAction();
		
	Else
		
		NotifyAboutPlanningOfStageSchedule();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiagramOfAdjacentStages(Command)
	
	If ValueIsFilled(ProductionStage) Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ScheduleStatus", ScheduleStatus);
		If TypeOf(ProductionStage) = Type ("DocumentRef.ProductionStage2_2") Then
			FormParameters.Insert("CommandParameter", ProductionStage);
		Else
			FormParameters.Insert("Stage", ProductionStage);
			FormParameters.Insert("KeyLot", KeyLot);
			FormParameters.Insert("ProductionOrder", ProductionOrder);
		EndIf;
		
		OpenForm(
			"Report.ConnectedProductionStagesChart.ObjectForm",
			FormParameters,
			ThisObject,
			ProductionStage);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTabularDocumentFormElement

&AtClient
Procedure SpreadsheetDocumentDetailProcessing(Item, Details, StandardProcessing)
	
	If TypeOf(Details) = Type("Structure") Then
		
		StandardProcessing = False;
		
		If Details.Property("AreaView") Then
			
			If Details.AreaView = "OpenAdjacentStageDiagnostics" Then
				
				OpenAdjacentStageDiagnostics(Details);
				
			ElsIf Details.AreaView = "ManagingVisibilityOfAlternativeRCViews" Then
				
				ShowHideAlternatives(Details, SpreadsheetDocument);
				
			ElsIf Details.AreaView = "UseRCView" Then
				
				ReplaceRCTypeUsedClient(Details);
				
			EndIf; 
			
		EndIf; 
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(ProductionStage) Then
		
		If TypeOf(ProductionStage) = Type("DocumentRef.ProductionStage2_2") Then
			PresentationStage = Documents.ProductionStage2_2.PresentationStage(ProductionStage);
			
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chẩn đoán lịch của công đoạn ""%1"", %2';
					|ru = 'Диагностика графика этапа ""%1"", %2';
					|en = 'The ""%1"" stage resource chart, %2'; fa = 'The ""%1"" stage resource chart, %2';
					|it = 'Диагностика графика этапа ""%1"", %2';
					|pl = 'The ""%1"" stage resource chart, %2';
					|tr = '""%1"" aşaması programı sorun giderme, %2'"),
				PresentationStage);
		Else
			PresentationStage = Common.ObjectAttributeValue(ProductionStage, "Description");
			PresentationOfSpecification = Common.ObjectAttributeValue(ProductionStage, "Owner.Description");
			OrderPresentation = Documents.ProductionOrder2_2.OrderPresentation(ProductionOrder, NStr("vi = 'theo đơn hàng';
																									|ru = 'по заказу';
																									|en = 'against order'; fa = 'against order';
																									|it = 'по заказу';
																									|pl = 'against order';
																									|tr = 'siparişe ilişkin'"));
			
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chẩn đoán lịch của công đoạn ""%1: %2"" %3';
					|ru = 'Диагностика графика этапа ""%1: %2"" %3';
					|en = 'The ""%1"" stage resource chart: %2 %3'; fa = 'The ""%1"" stage resource chart: %2 %3';
					|it = 'Диагностика графика этапа ""%1: %2"" %3';
					|pl = 'The ""%1"" stage resource chart: %2 %3';
					|tr = '""%1: %2"" aşaması programı sorun giderme %3'"),
				PresentationOfSpecification,
				PresentationStage,
				OrderPresentation);
		EndIf;
		
	Else
		
		Title = NStr("vi = 'Chẩn đoán lịch công đoạn sản xuất';
					|ru = 'Диагностика графика этапа производства';
					|en = 'Production stage resource chart'; fa = 'نمودار منابع مرحله تولید';
					|it = 'Diagnostica del grafico delle fasi di produzione';
					|pl = 'Weryfikacja harmonogramu etapu produkcji';
					|tr = 'Üretim aşaması programı tanılama'");
		
	EndIf;
	
EndProcedure

&AtServer
Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

&AtClient
Procedure GenerateReportOnClient()
	
	GenerateReportOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateReportOnServer()
	
	If Not ValueIsFilled(ProductionStage) Then
		SpreadsheetDocument.Clear();
		Return;
	EndIf;
	
	ShowHideGraphNotRelevant();
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Stage", ProductionStage);
	ProcedureParameters.Insert("ScheduleStatus", ScheduleStatus);
	ProcedureParameters.Insert("KeyLot", KeyLot);
	ProcedureParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Tạo một báo cáo ""Chẩn đoán công đoạn sản xuất""';
			|ru = 'Формирование отчета ""Диагностика этапа производства""';
			|en = 'Generate the ""Production stage resource chart"" report'; fa = 'Generate the ""Production stage resource chart"" report';
			|it = 'Creazione del report ""Diagnostica della fase di produzione""';
			|pl = 'Tworzenie raportu ""Diagnoza etapu produkcji""';
			|tr = '""Üretim aşaması kaynak grafiği"" raporunun düzenlenmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Reports.ProductionStageResourceChart.GenerateReport",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = ReportGenerationHandler();
		StartAwaitingLongAction = True;
		
	Else
		
		ProcessReportResultInBackground(ThisObject, TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Function ReportGenerationHandler()
	
	Return "GenerateReportInBackgroundCompletion";
	
EndFunction

&AtServerNoContext
Procedure CancelLongRunningOperation(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProcessReportResultInBackground(Form, Result)
	
	If Result.Status = "Completed2" Then
		
		ResultOfFormation = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(ResultOfFormation) = Type("Structure") Then
			
			If ResultOfFormation.Property("SpreadsheetDocument") Then
				
				Form.SpreadsheetDocument = ResultOfFormation.SpreadsheetDocument;
				
				If ResultOfFormation.Property("DecipheringAlternatives") Then
					
					For Each Details In ResultOfFormation.DecipheringAlternatives Do
						ShowHideAlternatives(Details, Form.SpreadsheetDocument);
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		CommonClientServer.SetSpreadsheetDocumentFieldState(
			Form.Items.SpreadsheetDocument);
		
	Else
		
		ClearTableDocumentAndHideStateDisplay(Form);
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearTableDocumentAndHideStateDisplay(Form)
	
	ClearTabularDocument(Form.SpreadsheetDocument);
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(
		Form.Items.SpreadsheetDocument);
	
EndProcedure

&AtServerNoContext
Procedure ClearTabularDocument(SpreadsheetDocument)
	SpreadsheetDocument.Clear();
EndProcedure

&AtClient
Procedure StartAwaitingLongAction()
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	If TimeConsumingOperationIdleHandler = ReportGenerationHandler() Then
		
		IdleParameters.OutputIdleWindow = False;
		
		CommonClientServer.SetSpreadsheetDocumentFieldState(
			Items.SpreadsheetDocument,
			"ReportGeneration");
		
	EndIf;
	
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		CallbackOnCompletion,
		IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtClient
Procedure GenerateReportInBackgroundCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		
		ClearTableDocumentAndHideStateDisplay(ThisObject);
		
	Else
		
		ProcessReportResultInBackground(ThisObject, Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputLegend()
	
	AppearanceTemplate = Reports.ProductionStageResourceChart.GetTemplate("StageResourceChart");
	AreaLegend = AppearanceTemplate.GetArea("Legend");
	Legend.Put(AreaLegend);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ShowHideAlternatives(Details, SpreadsheetDocument)
	
	ScopeOfAlternative = SpreadsheetDocument.Area(Details.TableHeight + 1,, Details.TableHeight + Details.NumberOfAlternatives * 3);
	ScopeOfAlternative.Visible = Not ScopeOfAlternative.Visible;
	
	Scope__Usage = SpreadsheetDocument.Area(Details.Top, Details.Left, Details.Top, Details.Left);
	If ScopeOfAlternative.Visible Then
		Scope__Usage.Text = NStr("vi = 'ẩn thay thế';
								|ru = 'скрыть альтернативы';
								|en = 'hide alternatives'; fa = 'hide alternatives';
								|it = 'nascondere alternative';
								|pl = 'ukryj alternatywy';
								|tr = 'alternatifleri gizle'");
	Else
		Scope__Usage.Text = NStr("vi = 'hiển thị thay thế';
								|ru = 'показать альтернативы';
								|en = 'show alternatives'; fa = 'show alternatives';
								|it = 'visualizzare alternative';
								|pl = 'pokaż alternatywy';
								|tr = 'alternatifleri göster'");
	EndIf; 
	
EndProcedure

&AtClient
Procedure ReplaceRCTypeUsedClient(Details)

	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thay thế loại NLSX đã sử dụng bằng ""%1""?';
			|ru = 'Заменить используемый вид РЦ на ""%1""?';
			|en = 'Replace the used work center type with ""%1""?'; fa = 'Replace the used work center type with ""%1""?';
			|it = 'Sostituire il tipo di centri utilizzato in ""%1""?';
			|pl = 'Zastąpić używany rodzaj RC na ""%1""?';
			|tr = 'İM türü ""%1"" olarak değiştirilsin mi?'"),
		String(Details.WorkCenterType));
						
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thay đổi loại NLSX';
												|ru = 'Изменить вид РЦ';
												|en = 'Change work center type'; fa = 'Change work center type';
												|it = 'Modificare il tipo di centri di lavoro';
												|pl = 'Zmień widok RC';
												|tr = 'İM türünü değiştir'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	CallbackDescription = New CallbackDescription("ReplaceRCTypeUsedClientCompletion", ThisObject, Details);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure ReplaceRCTypeUsedClientCompletion(QuestionResult, Details) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ReplacementExecuted = ReplaceRCTypeUsedServer(
		ProductionStage,
		Details.ConnectionKey,
		Details.WorkCenterType);
	
	If ReplacementExecuted Then
		GenerateReportOnClient();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ReplaceRCTypeUsedServer(ProductionStage, ConnectionKey, WorkCenterType)
	
	ExecutedSuccessfully = True;
	
	StageObject = ProductionStage.GetObject();
	
	If TypeOf(ConnectionKey) = Type("Array") Then
		For Each Var_Key In ConnectionKey Do
			StageObject.ReplaceRCTypeUsed(Var_Key, WorkCenterType);
		EndDo;
	Else
		StageObject.ReplaceRCTypeUsed(ConnectionKey, WorkCenterType);
	EndIf;
	
	Try
		
		If StageObject.Posted Then
			StageObject.Write(DocumentWriteMode.Posting);
		Else
			StageObject.Write();
		EndIf;
		
	Except
		
		ExecutedSuccessfully = False;
		
	EndTry; 
	
	Return ExecutedSuccessfully;
	
EndFunction

&AtServer
Procedure ShowHideGraphNotRelevant()
	
	Document = ?(TypeOf(ProductionStage) = Type("DocumentRef.ProductionStage2_2"), ProductionStage, ProductionOrder);
	
	DynamicStructure = Common.ObjectAttributeValue(Document, "DynamicStructure");
	
	If DynamicStructure Then
		ScheduleIsRelevant = True; // Recalculation is not available for the dynamic stage, no need to read the Status of the schedule
	Else
		ScheduleIsRelevant = InformationRegisters.JobsToProductionScheduleCalculation.StageScheduleIsRelevant(ProductionStage);
	EndIf;
	
	Items.GroupScheduleIsNotRelevant.Visible = Not DynamicStructure
		And Not ScheduleIsRelevant
		And ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndProcedure

&AtClient
Procedure OpenAdjacentStageDiagnostics(Details)

	FormParameters = New Structure;
	FormParameters.Insert("ScheduleStatus", ScheduleStatus);
	
	If TypeOf(Details.ProductionStage) = Type("DocumentRef.ProductionStage2_2") Then
		FormParameters.Insert("CommandParameter", Details.ProductionStage);
	Else
		FormParameters.Insert("Stage", Details.ProductionStage);
		FormParameters.Insert("KeyLot", Details.KeyLot);
		FormParameters.Insert("ProductionOrder", ProductionOrder);
	EndIf;
	
	OpenForm(
		"Report.ProductionStageResourceChart.Form",
		FormParameters,
		ThisObject,
		Details.ProductionStage);
	
EndProcedure

&AtServer
Procedure PlanStageSchedule()
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
	ProcedureParameters = New Structure;
	Stages = New Array;
	Stages.Add(ProductionStage);
	ProcedureParameters.Insert("Stages", Stages);
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Lập kế hoạch cho các công đoạn sản xuất ""';
			|ru = 'Планирование графика этапов производства""';
			|en = 'Production stage schedule planning""'; fa = 'Production stage schedule planning""';
			|it = 'Pianificazione del grafico delle fasi di produzione';
			|pl = 'Planowanie harmonogramu etapów produkcji""';
			|tr = 'Üretim aşamaları programının planlanması""'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"ProductionManagement.PlanScheduleOfStages",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = ScheduleSchedulingHandler();
		StartAwaitingLongAction = True;
		
	Else
		
		PlanningResult = PlanningResult(TimeConsumingOperation.ResultAddress);
		StartAwaitingLongAction = False;
		
		TimeConsumingOperation = Undefined;
		GenerateReportOnServer();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ScheduleSchedulingHandler()
	
	Return "PlanStageScheduleInBackgroundEnding";
	
EndFunction

&AtClient
Procedure PlanStageScheduleInBackgroundEnding(Result, AdditionalParameters) Export
	
	PlanningResult = PlanningResult(Result.ResultAddress);
	NotifyAboutPlanningOfStageSchedule();
	
	TimeConsumingOperation = Undefined;
	GenerateReportOnClient();
	
EndProcedure

&AtServerNoContext
Function PlanningResult(ResultAddress)
	
	Return GetFromTempStorage(ResultAddress);
	
EndFunction

&AtClient
Procedure NotifyAboutPlanningOfStageSchedule()
	
	If PlanningResult = Undefined Then
		Return;
	EndIf;
	
	ProductionManagementClient.NotifyUserOfProductionSchedulePlanning(PlanningResult);
	
	PlanningResult = Undefined;
	
EndProcedure

#EndRegion
