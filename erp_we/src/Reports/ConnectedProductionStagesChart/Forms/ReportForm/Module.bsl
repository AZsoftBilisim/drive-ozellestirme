#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.ScheduleStatus Then
		
		ScheduleStatus = StatusWorkingSchedule();
		
	EndIf;
	
	ProductionStage = Parameters.CommandParameter;
	If ValueIsFilled(Parameters.Stage) Then
		ProductionStage = Parameters.Stage;
		ProductionOrder = Parameters.ProductionOrder;
		KeyLot = Parameters.KeyLot;
	EndIf;
	
	If ValueIsFilled(ProductionStage) Then
		
		GenerateReportInBackground();
		
	EndIf;
	
	Items.ProductionStage.Visible = Not ValueIsFilled(ProductionStage);
	Items.GroupStage.Visible = ValueIsFilled(ProductionStage);
	
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	
	If ValueIsFilled(ProductionStage) And TypeOf(ProductionStage) = Type("DocumentRef.ProductionStage2_2") Then
		
		FilterStructure1.Insert(
			"ReferenceOrder",
			StageOrder(ProductionStage));
			
	EndIf;
	
	FormParameters = New Structure("Filter", FilterStructure1);
	
	OpenForm(
		"Document.ProductionStage2_2.ChoiceForm",
		FormParameters,
		Item);
	
EndProcedure

&AtClient
Procedure StageOfProductionPressing(Item)
	ShowValue(, ProductionStage);
EndProcedure

#EndRegion

#Region EventHandlersForChartElementsOfFormDueDates

&AtClient
Procedure GanttChartDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	If TypeOf(Decryptions) = Type("Array")
		And Decryptions.Count() > 1 Then
		
		DetailsValue  = Decryptions[1];
		
		If TypeOf(DetailsValue.Stage) = Type("DocumentRef.ProductionStage2_2")
			Or TypeOf(DetailsValue.Stage) = Type("CatalogRef.ProductionStages") Then
			
			StandardProcessing = False;
			
			KeyLot = DetailsValue.KeyLot;
			
			If TypeOf(ProductionStage) = Type("DocumentRef.ProductionStage2_2")
				And TypeOf(DetailsValue.Stage) = Type("CatalogRef.ProductionStages") Then
				ProductionOrder = StageOrder(ProductionStage);
			ElsIf TypeOf(ProductionStage) = Type("CatalogRef.ProductionStages")
				And TypeOf(DetailsValue.Stage) = Type("DocumentRef.ProductionStage2_2") Then 
				ProductionOrder = Undefined;
				KeyLot = New UUID("00000000-0000-0000-0000-000000000000");
			EndIf;
			
			ProductionStage = DetailsValue.Stage;
			StartReportGeneration();
		
		EndIf;
		
	ElsIf TypeOf(Decryptions) = Type("Structure")
		And Decryptions.Property("Stage") Then
		
		StandardProcessing = False;
		ShowValue(, Decryptions.Stage);

	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	StartReportGeneration();
	
EndProcedure

#EndRegion

#Region Private

#Region ReportGeneration

&AtClient
Procedure StartReportGeneration()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	GenerateReportInBackground();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction()
	
	CallbackOnCompletion = New CallbackDescription("GenerateReportInBackgroundCompletion", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		CallbackOnCompletion,
		IdleParameters);
	
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationPage;
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure GenerateReportInBackground()
	
	CreateStageHyperlink();
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Stage", ProductionStage);
	ProcedureParameters.Insert("ScheduleStatus", ScheduleStatus);
	ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
	ProcedureParameters.Insert("KeyLot",          KeyLot);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Tạo báo cáo ""Lịch trình các công đoạn sản xuất liền kề""';
			|ru = 'Формирование отчета ""График смежных этапов производства""';
			|en = 'Generate the ""Adjacent production stages"" report'; fa = 'Generate the ""Adjacent production stages"" report';
			|it = 'Formazione del report ""Grafico delle fasi di produzione correlate""';
			|pl = 'Tworzenie raportu ""Harmonogram powiązanych etapów produkcji""';
			|tr = '""İlgili Üretim Aşamaları Programı"" raporunun oluşturulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Reports.ConnectedProductionStagesChart.GenerateReport",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartAwaitingLongAction = True;
		
	Else
		
		ProcessReportResultInBackground(ThisObject, TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateReportInBackgroundCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		
		ClearAndShowDiagram(ThisObject);
		
	Else
		
		ProcessReportResultInBackground(ThisObject, Result);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProcessReportResultInBackground(Form, Result)
	
	If Result.Status = "Completed2" Then
		
		NewChart = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(NewChart) = Type("GanttChart") Then
			Form.GanttChart = NewChart;
		EndIf;
		
		Form.Items.GroupPages.CurrentPage = Form.Items.PageChart;
		
	Else
		
		ClearAndShowDiagram(Form);
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearAndShowDiagram(Form)
	
	Form.GanttChart.Clear();
	Form.Items.GroupPages.CurrentPage = Form.Items.PageChart;
	
EndProcedure

&AtServerNoContext
Procedure CancelLongRunningOperation(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

&AtServerNoContext
Function StageOrder(ProductionStage)
	
	Return Common.ObjectAttributeValue(ProductionStage, "ReferenceOrder");

EndFunction

&AtServer
Procedure CreateStageHyperlink()
	
	If TypeOf(ProductionStage) = Type("CatalogRef.ProductionStages") Then
		Items.ProductionStageLink.Title = Documents.ProductionOrder2_2.OrderPresentation(ProductionOrder) + ", "
			+ Common.ObjectAttributeValue(ProductionStage, "Description");
	Else
		Items.ProductionStageLink.Title = Documents.ProductionStage2_2.PresentationStage(ProductionStage);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
