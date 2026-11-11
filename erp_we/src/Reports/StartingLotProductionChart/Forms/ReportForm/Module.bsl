
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.ScheduleStatus Then
		
		ScheduleStatus = StatusWorkingSchedule();
		
	EndIf;
	
	If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.ProductionLots") Then
		ProductionLot = Parameters.CommandParameter;
	ElsIf TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionStage2_2") Then
		
		ProductionLot = Common.ObjectAttributeValue(
			Parameters.CommandParameter, "ProductionLot");
	EndIf;
	
	KeyLot = Parameters.KeyLot;
	ProductionOrder = Parameters.ProductionOrder;
	
	If ValueIsFilled(ProductionLot) Or ValueIsFilled(KeyLot) Then
		FillInOutputItems();
		SetFormHeader();
		GenerateReportInBackground();
	Else
		MessageText = NStr("vi = 'Không cung cấp việc tạo trực tiếp báo cáo này. Có thể truy cập báo cáo này từ các báo cáo ""Màn hình kiểm soát đơn hàng"" hoặc ""Cấu trúc của đơn hàng sản xuất"".';
							|ru = 'Непосредственное формирование этого отчета не предусмотрено. Перейти к этому отчету можно из отчетов ""Мониторинг заказа"" или ""Структура заказа на производство"".';
							|en = 'Direct generation of this report is not provided. You can access the report from the ""Order monitoring"" or ""Production order structure"" reports.'; fa = 'Direct generation of this report is not provided. You can access the report from the ""Order monitoring"" or ""Production order structure"" reports.';
							|it = 'Непосредственное формирование этого отчета не предусмотрено. Перейти к этому отчету можно из отчетов ""Мониторинг заказа"" или ""Структура заказа на производство"".';
							|pl = 'Direct generation of this report is not provided. You can access the report from the ""Order monitoring"" or ""Production order structure"" reports.';
							|tr = 'Bu rapor doğrudan oluşturulamaz. Bu rapora, ""Sipariş Üretim Grafiği"" veya ""Üretim Emri Takibi"" raporlarından ulaşılabilir.'");
		Raise MessageText;
	EndIf;
	
	Items.ProductionLot.Visible = ValueIsFilled(ProductionLot);
	
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
Procedure GanttChartDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	If TypeOf(Decryptions) = Type("Array")
		And Decryptions.Count() > 1 Then
		
		StandardProcessing = False;
		
		DetailsValue  = Decryptions[1];
		
		FormParameters = New Structure;
		FormParameters.Insert("ScheduleStatus", ScheduleStatus);
		
		If TypeOf(DetailsValue) = Type("DocumentRef.ProductionStage2_2") Then
			FormParameters.Insert("CommandParameter", DetailsValue);
		Else
			FormParameters.Insert("Stage", DetailsValue);
			FormParameters.Insert("KeyLot", KeyLot);
			FormParameters.Insert("ProductionOrder", ProductionOrder);
		EndIf;
		
		OpenForm(
			"Report.ProductionStageResourceChart.Form",
			FormParameters,
			ThisObject,
			DetailsValue);
	
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
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ProductionLot",  ProductionLot);
	ProcedureParameters.Insert("ScheduleStatus",       ScheduleStatus);
	ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
	ProcedureParameters.Insert("KeyLot",          KeyLot);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Lập giải thích của báo cáo ""Lịch biểu sản xuất""';
			|ru = 'Формирование расшифровки отчета ""Диаграмма графика производства заказа""';
			|en = 'Generate drill-down for the ""Order production schedule chart"" report'; fa = 'Generate drill-down for the ""Order production schedule chart"" report';
			|it = 'Formazione dell''interpretazione del report ""Schema del diagramma di produzione dell''ordine""';
			|pl = 'Kształtowanie szczegółów raportu ""Diagram harmonogramu produkcji zlecenia""';
			|tr = '""Siparişin Üretim Programı Grafiği"" raporu detaylandırmasının düzenlenmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Reports.StartingLotProductionChart.GenerateReport",
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
Procedure FillInOutputItems()
	
	DescriptionOfNH = New Array;
	
	If Parameters.Property("ArrayOutputProducts") Then
		
		For Each Products In Parameters.ArrayOutputProducts Do
			
			If DescriptionOfNH.Count() > 0 Then
				DescriptionOfNH.Add(", ");
			EndIf;
			
			ProductDescription_1 = New FormattedString(
				Common.ObjectAttributeValue(Products, "Presentation"),
				,
				,
				,
				GetURL(Products));
				
			DescriptionOfNH.Add(ProductDescription_1);
		
		EndDo;
		
	EndIf;
	
	If DescriptionOfNH.Count() > 0 Then
		
		ManufacturedProducts = New FormattedString(DescriptionOfNH);
		
	Else
	
		Items.ManufacturedProducts.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ScheduleStatus = StatusWorkingSchedule() Then
		
		Title = NStr("vi = 'Lịch biểu sản xuất lô hàng khởi động';
					|ru = 'График производства партии запуска';
					|en = 'Starting lot production schedule'; fa = 'زمان‌بندی تولید لات شروع';
					|it = 'Grafico di produzione del lotto di lancio';
					|pl = 'Harmonogram produkcji partii uruchomienia';
					|tr = 'Başlatma lotu üretim programı'");
		
	ElsIf ScheduleStatus = StatusPreliminarySchedule() Then
		
		Title = NStr("vi = 'Lịch biểu sản xuất lô hàng khởi động (lập kế hoạch)';
					|ru = 'График производства партии запуска (планирование)';
					|en = 'Starting lot production schedule (creating)'; fa = 'Starting lot production schedule (creating)';
					|it = 'Grafico di produzione del lotto di lancio (pianificazione)';
					|pl = 'Harmonogram produkcji partii uruchomienia (planowanie)';
					|tr = 'Başlatma lotu üretim programı (planlama)'");
		
	ElsIf ScheduleStatus = StatusChartModel() Then
		
		Title = NStr("vi = 'Lịch biểu sản xuất lô hàng khởi động (mẫu)';
					|ru = 'График производства партии запуска (модель)';
					|en = 'Starting lot production schedule (model)'; fa = 'Starting lot production schedule (model)';
					|it = 'Grafico di produzione del lotto di lancio (modello)';
					|pl = 'Harmonogram produkcji partii uruchomienia (model)';
					|tr = 'Başlatma lotu üretim programı (model)'");
		
	EndIf;
	
EndProcedure

&AtServer
Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

&AtServer
Function StatusPreliminarySchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule();
	
EndFunction

&AtServer
Function StatusChartModel()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel();
	
EndFunction

#EndRegion

#EndRegion
