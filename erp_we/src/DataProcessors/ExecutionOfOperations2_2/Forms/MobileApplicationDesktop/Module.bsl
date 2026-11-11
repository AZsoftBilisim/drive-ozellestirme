#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Settings = DataProcessors.ExecutionOfOperations2_2.GetUserSettings();
	
	If Settings <> Undefined
		And Settings.Property("WorkMode")
		And Settings.Property("Department")
		And Settings.Property("ProductionArea")
		And Settings.Property("WorkCenter")
		And Settings.Property("Performer")
		And Settings.Property("YouCanChangeTheDepartment") Then
		
		WorkMode        = Settings.WorkMode;
		DepartmentFilter = Settings.Department;
		LotFilter       = Settings.ProductionArea;
		WorkCenterFilter  = Settings.WorkCenter;
		PerformerFilter   = Settings.Performer;
		
		ArtistInSettings = ValueIsFilled(Settings.Performer);
		Rcvconfigurations          = ValueIsFilled(Settings.WorkCenter);
		PlotInSettings     = ValueIsFilled(Settings.ProductionArea);
		
		Items.FormChangeDepartment.Visible = Settings.YouCanChangeTheDepartment;
		
	Else
		
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Không thể mở nơi làm việc. Thiếu cài đặt mở biểu mẫu';
							|ru = 'Невозможно открыть рабочее место. Отсутствуют настройки открытия формы';
							|en = 'Unable to open workplace. The form opening settings are missing'; fa = 'Unable to open workplace. The form opening settings are missing';
							|it = 'Non è possibile aprire il desktop. Non ci sono le impostazioni di apertura del modulo';
							|pl = 'Nie można otworzyć miejsce pracy. Brak ustawienia otwierania formularzu';
							|tr = 'Çalışma alanı açılamıyor. Form açma ayarları eksik'");
		Message.Message();
		
		Return;
		
	EndIf;
	
	ShiftJobsAreUsed =
		ProductionServer.ProductionBusinessUnitDescription(DepartmentFilter).UseShiftTasks;
	
	FillInData();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOperation2_2"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("Department")
		And Parameter.Department = DepartmentFilter Then
		
		UpdateData1();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSections

&AtClient
Procedure SectionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.Sections.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure();
	
	FormParameters.Insert("ExecutionIsAllowed",     ExecutionIsAllowed);
	FormParameters.Insert("DepartmentFilter", DepartmentFilter);
	FormParameters.Insert("LotFilter",       LotFilter);
	FormParameters.Insert("ViewRatbor",         ViewRatbor);
	FormParameters.Insert("WorkCenterFilter",  WorkCenterFilter);
	FormParameters.Insert("ProductSelection_4_",       ProductSelection_4_);
	FormParameters.Insert("OperationFilter",      OperationFilter);
	FormParameters.Insert("PerformerFilter",   PerformerFilter);
	FormParameters.Insert("ButchFilter",        ButchFilter);
	FormParameters.Insert("StepFilter",          StepFilter);
	
	Section = Items.Sections.CurrentData.SectionName;
	
	If Section = "Purpose" Then
		
		MeasurementUUID = PerformanceMonitorClient.TimeMeasurement("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationListAssign.OpeningForm",, False);
		
		OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationListAssign",
					FormParameters,
					ThisForm,
					,
					,
					,
					New CallbackDescription("SectionsSelectionCompletion",ThisForm));
		
		PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID);
		
	ElsIf Section = "Acceptance" Or Section = "Perform" Then
		
		If Section = "Acceptance" Then
			FormParameters.Insert("WorkMode", "AcceptanceIntoWork");
		EndIf;
		
		MeasurementUUID = PerformanceMonitorClient.TimeMeasurement("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationListMarkAsCompleted.OpeningForm",, False);
		
		OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationListMarkAsCompleted",
					FormParameters,
					ThisForm,
					,
					,
					,
					New CallbackDescription("SectionsSelectionCompletion",ThisForm));
		
		PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID);
		
	ElsIf Section = "Log" Then
		
		OpenForm("Document.ProductionOperation2_2.ListForm",FormParameters,ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SectionsRefreshRequestProcessing()
	
	UpdateData1();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeDepartment(Command)
	SelectDepartment = New CallbackDescription("SelectDepartment",ThisForm);
		
	ShowInputValue(SelectDepartment,DepartmentFilter,NStr("vi = 'Chọn đơn vị';
															|ru = 'Выберите подразделение';
															|en = 'Choose a business unit'; fa = 'Choose a business unit';
															|it = 'Selezionare il reparto';
															|pl = 'Wybierz dział';
															|tr = 'Departman seç'"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Items.SectionsLongDesc.Font     = New Font(StyleFonts.TextFont,,12);
	Items.SectionsImportantData.Font = New Font(StyleFonts.NormalTextFont,,6);
	
EndProcedure

&AtServer
Procedure SelectDepartment(Result, AdditionalParameters) Export
	DepartmentFilter = Result;
	
	ShiftJobsAreUsed =
		ProductionServer.ProductionBusinessUnitDescription(DepartmentFilter).UseShiftTasks;
	
	FillInData();
EndProcedure

&AtClient
Procedure UpdateData1()
	
	MeasurementUUID = PerformanceMonitorClient.TimeMeasurement("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationDesktop.UpdateData1",, False);
	
	FillInDataInsideTimeMeasurement();
	
	PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID);
	
EndProcedure

&AtServer
Procedure FillInData()
	
	MeasurementStartTime = PerformanceMonitor.StartTimeMeasurement();
	
	FillInDataInsideTimeMeasurement();
	
	PerformanceMonitor.EndTimeMeasurement("DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationDesktop.FillInData", MeasurementStartTime);

EndProcedure

&AtServer
Procedure FillInDataInsideTimeMeasurement()
	
	Title = DepartmentFilter;
	
	Sections.Clear();
	
	// Quantity for assignment
	If WorkMode = Enums.WorkModesForemanSWorkplace.AssignmentPuttingIntoOperationAndExecution
		Or WorkMode = Enums.WorkModesForemanSWorkplace.AssignmentAndExecution Then
		
		Query = RequestForUnassignedOperations();
		
		Result = Query.Execute().Select();
		
		If Result.Next() Then
			YouCanStartNow  = Result.QuantityCanBePerformed;
			AllForAssignment = Result.QuantityToDestination;
		EndIf;
		
		YouCanStartNow  = ?(YouCanStartNow  = Null,0,YouCanStartNow);
		AllForAssignment = ?(AllForAssignment = Null,0,AllForAssignment);
		
		TotalAssign = YouCanStartNow + AllForAssignment;
		
		SectionRow = Sections.Add();
		SectionRow.Picture     = PictureLib.PlusIcon;
		SectionRow.SectionName   = "Purpose";
		SectionRow.LongDesc     = NStr("vi = 'Chỉ định một hoạt động';
										|ru = 'Назначить операцию';
										|en = 'Assign operation'; fa = 'تخصیص عملیات';
										|it = 'Assegna l''operazione';
										|pl = 'Przydziel operację';
										|tr = 'İşlem ata'");
		SectionRow.ImportantData = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Bạn có thể bắt đầu: %1 %2Tổng đến đích: %3';
											|ru = 'Можно начинать: %1 %2Всего к назначению: %3';
											|en = 'May start: %1%2Total to be appointed: %3'; fa = 'May start: %1%2Total to be appointed: %3';
											|it = 'Si può iniziare:%1 %2In totale all''assegnazione:%3';
											|pl = 'Można zaczynać: %1 %2Razem do przeznaczenia: %3';
											|tr = 'Başlanabilir: %1 %2Toplam atanacak: %3'"),
										YouCanStartNow,
										Chars.LF,
										TotalAssign);
		
	EndIf;
	
	// Quantity for acceptance and execution
	Query = New Query(
		"SELECT
		|	SUM(CASE Operations.Status
		|			WHEN VALUE(Enum.ProductionOperationStatuses.Running)
		|				THEN 1
		|			ELSE 0
		|		END) AS Started_,
		|	SUM(CASE Operations.Status
		|			WHEN VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
		|				THEN 1
		|			WHEN VALUE(Enum.ProductionOperationStatuses.BeingGenerated)
		|				THEN 1
		|			ELSE 0
		|		END) AS Created
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Department = &Department
		|	AND &TextSelectionBySite
		|	AND &TextSelectionByWorkCenter
		|	AND &TextSelectionByArtist
		|	AND &TextSelectionByShift
		|	AND Operations.Posted");
	
	If PlotInSettings Then
		
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite","AND Operations.ProductionArea = &ProductionArea");
			
			Query.SetParameter("ProductionArea",LotFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite","");
			
	EndIf;
		
	If Rcvconfigurations Then
		
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter",
				"AND Operations.WorkCenter = &WorkCenter");
			
			Query.SetParameter("WorkCenter",WorkCenterFilter);
			
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter","");
			
	EndIf;
	
	If ArtistInSettings Then
		
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByArtist","AND Operations.Performer = &Performer");
			
			Query.SetParameter("Performer",PerformerFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByArtist","");
			
	EndIf;
	
	If ShiftJobsAreUsed Then
	
		ShiftData = ProductionAccounting.CurShift(DepartmentFilter);
		
		Query.Text = StrReplace(
						Query.Text,
						"AND &TextSelectionByShift",
						"AND (Operations.ShiftTask.Date <= &DATE AND NOT Operations.ShiftTask.Status = VALUE(Enum.ShiftTaskStatuses.Closed))");
		
		Query.SetParameter("Date", ?(ValueIsFilled(ShiftData), ShiftData.Date, CurrentSessionDate()));
	Else
		
		Query.Text = StrReplace(Query.Text, "AND &TextSelectionByShift","");
		
	EndIf;
	
	Query.SetParameter("Department",DepartmentFilter);
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		Started_   = Result.Started_;
		Created = Result.Created;
	EndIf;
	
	Started_   = ?(Started_   = Null,0,Started_);
	Created = ?(Created = Null,0,Created);
	
	TotalOperations = Started_ + Created;
	
	If WorkMode = Enums.WorkModesForemanSWorkplace.AssignmentPuttingIntoOperationAndExecution 
		Or WorkMode = Enums.WorkModesForemanSWorkplace.PuttingIntoOperationAndExecution Then
		
		SectionRow = Sections.Add();
		SectionRow.Picture     = PictureLib.FollowUpBuffer;
		SectionRow.SectionName   = "Acceptance";
		SectionRow.LongDesc     = NStr("vi = 'Nhận đi làm';
										|ru = 'Принять в работу';
										|en = 'Start'; fa = 'شروع';
										|it = 'Prendere in carico';
										|pl = 'Akceptować do pracy';
										|tr = 'İşe kabul et'");
		SectionRow.ImportantData = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Chưa bắt đầu: %1';
											|ru = 'Не начато: %1';
											|en = 'Not started: %1'; fa = 'Not started: %1';
											|it = 'Non iniziato: %1';
											|pl = 'Nie rozpoczęto: %1';
											|tr = 'Başlamayan: %1'"),
										Created);
		
	EndIf;
	
	SectionRow = Sections.Add();
	SectionRow.Picture     = PictureLib.ExecutedSuccessfully;
	SectionRow.SectionName   = "Perform";
	SectionRow.LongDesc     = NStr("vi = 'Đánh dấu thực hiện';
									|ru = 'Отметить выполнение';
									|en = 'Mark as completed'; fa = 'علامت‌گذاری به‌عنوان تکمیل‌شده';
									|it = 'Segnare completamento';
									|pl = 'Zaznacz wykonanie';
									|tr = 'Gerçekleştirmeyi işaretle'");
	SectionRow.ImportantData = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Đã chỉ định: %1';
										|ru = 'Назначено: %1';
										|en = 'Assigned: %1'; fa = 'Assigned: %1';
										|it = 'Assegnato: %1';
										|pl = 'Przydzielono: %1';
										|tr = 'Atanan: %1'"),
									TotalOperations);
	
	SectionRow = Sections.Add();
	SectionRow.Picture   = PictureLib.StandardTermsOfSalesWithCustomer;
	SectionRow.SectionName = "Log";
	SectionRow.LongDesc   = NStr("vi = 'Nhật ký giao dịch';
								|ru = 'Журнал операций';
								|en = 'Operation log'; fa = 'Operation log';
								|it = 'Registro operazioni';
								|pl = 'Dziennik operacji';
								|tr = 'İşlem günlüğü'");
	
	Items.Chart.Visible = ShiftJobsAreUsed;
	
	If ShiftJobsAreUsed Then
		DisplayChart();
	EndIf;
	
EndProcedure

&AtClient
Procedure SectionsSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ExecutionIsAllowed    = Result.ExecutionIsAllowed;
		ViewRatbor        = Result.RCView;
		WorkCenterFilter = Result.WorkCenter;
		PerformerFilter  = Result.Performer;
		OperationFilter     = Result.Operation;
		ProductSelection_4_      = Result.Product;
		ButchFilter       = Result.Lot;
		StepFilter         = Result.Stage;
		LotFilter      = Result.ProductionArea;
	
	EndIf;
	
EndProcedure

&AtServer
Function RequestForUnassignedOperations()
	
	If ShiftJobsAreUsed Then
		
		Query = New Query(
		"SELECT
		|	SUM(CASE
		|			WHEN NWOperations.AssignmentIsAllowed
		|				THEN 1
		|			ELSE 0
		|		END) AS QuantityCanBePerformed,
		|	SUM(CASE
		|			WHEN NOT NWOperations.AssignmentIsAllowed
		|				THEN 1
		|			ELSE 0
		|		END) AS QuantityToDestination
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS NWOperations
		|
		|	LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
		|	ON NWOperations.Stage = Queue.Stage
		|		AND NWOperations.Operation = Queue.Operation
		|		AND NWOperations.OperationID = Queue.OperationID
		|		AND Queue.MainEntry_
		|
		|WHERE
		|	NWOperations.ShiftTask = VALUE(Document.ShiftTask.EmptyRef)
		|	AND NWOperations.Department = &Department
		|	AND &TextSelectionBySite
		|	AND &TextSelectionByWorkCenter");
		
		If PlotInSettings Then
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite",
			"	AND (Queue.WorkCenter IN (
			|						UNDEFINED,
			|						VALUE(Catalog.WorkCenters.EmptyRef),
			|						VALUE(Catalog.WorkCenterTypes.EmptyRef))
			|		OR Queue.WorkCenter REFS Catalog.WorkCenters
			|			AND (CAST(Queue.WorkCenter AS Catalog.WorkCenters)).ProductionArea = &ProductionArea
			|		OR Queue.WorkCenter REFS Catalog.WorkCenterTypes
			|			AND TRUE IN
			|				(SELECT TOP 1
			|					TRUE
			|				FROM
			|					Catalog.WorkCenters AS T
			|				WHERE
			|					T.WorkCenterType = Queue.WorkCenter
			|					AND T.ProductionArea = &ProductionArea))");
			
			Query.SetParameter("ProductionArea",LotFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite","");
			
		EndIf;
		
		If Rcvconfigurations Then
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter",
			"	AND (Queue.WorkCenter REFS Catalog.WorkCenterTypes
			|			AND Queue.WorkCenter = &RCView)
			|		OR (Queue.WorkCenter REFS Catalog.WorkCenters
			|			AND Queue.WorkCenter = &WorkCenter)");
			
			Query.SetParameter("RCView",Common.ObjectAttributeValue(WorkCenterFilter,"WorkCenterType"));
			Query.SetParameter("WorkCenter",WorkCenterFilter);
			
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter","");
			
		EndIf;
		
		Query.SetParameter("Department",DepartmentFilter);
		
		Return Query;
		
	Else
		
		Query = New Query(
		"SELECT
		|	SUM(CASE
		|			WHEN Queue.ExecutionIsAllowed > 0 
		|					AND Queue.ExecutionIsAllowed > Queue.CreatedOn - (Queue.Running + Queue.Completed2 + Queue.Skipped3)
		|				THEN 1
		|			ELSE 0
		|		END) AS QuantityCanBePerformed,
		|	SUM(CASE
		|			WHEN Queue.ExecutionIsAllowed = 0 AND (Queue.PendingPredecessorCompletion > 0
		|						AND Queue.PendingPredecessorCompletion > Queue.CreatedOn - (Queue.Running + Queue.Completed2 + Queue.Skipped3)
		|					OR Queue.PreviousOnesStarted > 0
		|						AND Queue.PreviousOnesStarted > Queue.CreatedOn - (Queue.Running + Queue.Completed2 + Queue.Skipped3))
		|				THEN 1
		|			ELSE 0
		|		END) AS QuantityToDestination
		|FROM
		|	InformationRegister.QueueOfProductionOperations AS Queue
		|WHERE
		|	Queue.Department = &Department
		|	AND NOT Queue.InArchive
		|	AND Queue.ProductionOperation = VALUE(Document.ProductionOperation2_2.EmptyRef)
		|	AND &TextSelectionBySite
		|	AND &TextSelectionByWorkCenter");
		
		If PlotInSettings Then
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite",
			"	AND (Queue.WorkCenter IN (
			|						UNDEFINED,
			|						VALUE(Catalog.WorkCenters.EmptyRef),
			|						VALUE(Catalog.WorkCenterTypes.EmptyRef))
			|		OR Queue.WorkCenter REFS Catalog.WorkCenters
			|			AND (CAST(Queue.WorkCenter AS Catalog.WorkCenters)).ProductionArea = &ProductionArea
			|		OR Queue.WorkCenter REFS Catalog.WorkCenterTypes
			|			AND TRUE IN
			|				(SELECT TOP 1
			|					TRUE
			|				FROM
			|					Catalog.WorkCenters AS T
			|				WHERE
			|					T.WorkCenterType = Queue.WorkCenter
			|					AND T.ProductionArea = &ProductionArea))");
			
			Query.SetParameter("ProductionArea",LotFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite","");
			
		EndIf;
		
		If Rcvconfigurations Then
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter",
			"	AND (Queue.WorkCenter REFS Catalog.WorkCenterTypes
			|			AND Queue.WorkCenter = &RCView)
			|		OR (Queue.WorkCenter REFS Catalog.WorkCenters
			|			AND Queue.WorkCenter = &WorkCenter)");
			
			Query.SetParameter("RCView",Common.ObjectAttributeValue(WorkCenterFilter,"WorkCenterType"));
			Query.SetParameter("WorkCenter",WorkCenterFilter);
			
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter","");
			
		EndIf;
		
		Query.SetParameter("Department",DepartmentFilter);
		
		Return Query;
	EndIf;
	
EndFunction

&AtServer
Procedure DisplayChart()
	
	Chart.Clear();
	
	Query = New Query("
		|SELECT
		|	SUM(CASE
		|			WHEN Operations.CountReal > 0
		|				THEN CASE Operations.ExecutionTimeUnitOfMeasure
		|						WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|							THEN (Operations.RunTime / Operations.Count * Operations.CountReal)/3600
		|						WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|							THEN (Operations.RunTime / Operations.Count * Operations.CountReal)/60
		|						WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|							THEN (Operations.RunTime / Operations.Count * Operations.CountReal)
		|						WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|							THEN (Operations.RunTime / Operations.Count * Operations.CountReal)*24
		|						WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|							THEN (Operations.RunTime / Operations.Count * Operations.CountReal)*24
		|						END
		|			ELSE 0
		|		END) AS TimeCompleted,
		|	SUM(CASE Operations.ExecutionTimeUnitOfMeasure
		|			WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|				THEN Operations.RunTime/3600
		|			WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|				THEN Operations.RunTime/60
		|			WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|				THEN Operations.RunTime
		|			WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|				THEN Operations.RunTime*24
		|			WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|				THEN Operations.RunTime*24
		|		END) AS TimeOfEverything
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.ShiftTask.Date = &Date
		|	AND Operations.Department = &Department
		|	AND &TextSelectionBySite
		|	AND &TextSelectionByWorkCenter
		|	AND &TextSelectionByArtist
		|	AND Operations.Posted");
	
	ShiftData = ProductionAccounting.CurShift(DepartmentFilter);
	
	If Not ValueIsFilled(ShiftData) Then
	
		Items.Chart.Visible = False;
		
		Return;
	
	EndIf;
	
	Query.SetParameter("Date", ShiftData.Date);
	Query.SetParameter("Department",DepartmentFilter);
	
	If PlotInSettings Then
		
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite","AND Operations.ProductionArea = &ProductionArea");
			
			Query.SetParameter("ProductionArea",LotFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionBySite","");
			
	EndIf;
		
	If Rcvconfigurations Then
		
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter",
				"AND Operations.WorkCenter = &WorkCenter");
			
			Query.SetParameter("WorkCenter",WorkCenterFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByWorkCenter","");
			
	EndIf;
	
	If ArtistInSettings Then
		
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByArtist","AND Operations.Performer = &Performer");
			
			Query.SetParameter("Performer",PerformerFilter);
		Else
			
			Query.Text = StrReplace(Query.Text, "AND &TextSelectionByArtist","");
			
	EndIf;
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
	
		TimeCompleted = Result.TimeCompleted;
		TimeOfEverything     = Result.TimeOfEverything;
		
	EndIf;
	
	If TimeOfEverything = 0 Or TimeOfEverything = NULL Then
		CompletedPercentage = 0;
	Else
		CompletedPercentage = TimeCompleted/TimeOfEverything*100;
	EndIf;
	
	Series1 = Chart.Series.Add("Completed2");
	Series2 = Chart.Series.Add();
	
	Series1.Color = New Color(87, 190, 133);
	Series2.Color = WebColors.White;
	
	Series1.Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện %1%';
			|ru = 'Выполнение %1%';
			|en = 'Execution %1%'; fa = 'Execution %1%';
			|it = 'Esecuzione%1%';
			|pl = 'Wykonanie %1%';
			|tr = 'Gerçekleştirme %%1'"),
		Round(CompletedPercentage,2));
	
	Chart.TitleArea.Text = ProductionManagementClientServer.ShiftTaskPresentation_(
		ShiftData.Shift,
		ShiftData.Date,
		LotFilter,
		True);
	
	Point = Chart.SetPoint(1);
	
	Chart.SetValue(Point, Series1,CompletedPercentage);
	Chart.SetValue(Point,Series2,100-CompletedPercentage);

	Items.Chart.Visible = True;
EndProcedure

#EndRegion