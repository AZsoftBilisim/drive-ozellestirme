
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	RestoreSettings();
	FormControl();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNoteText();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure GroupsOnChange(Item)
	
	SetNoteText();
	FormControl();

EndProcedure

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure PeriodTypeOnChange(Item)
	
	EnterPeriodValue(PeriodType);
	
EndProcedure

&AtClient
Procedure PeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PeriodStartChoiceCompletion", ThisObject);
	
	TMCommonUseClient.SelectPeriodFromList(
				ThisForm,
				Item,
				PeriodType,
				BeginOfPeriod,
				CallbackDescription);

EndProcedure

&AtClient
Procedure ReportTypeOnChange(Item)
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveSettingsAndGenerate(Command)

    ParametersList = GetCurrentSettings();
	ParametersList.Insert("Generate", True);

    Close(ParametersList);

EndProcedure

&AtClient
Procedure ShouldSaveSettings(Command)
	
	ParametersList = GetCurrentSettings();
	
    Close(ParametersList);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetNoteText()
	
	If Groups = "Variant1" Then
		NoteText2 = NStr("vi = 'Trong báo cáo hiển thị tất cả nhiệm vụ mà kỳ lập kế hoạch của chúng 
			|nằm trong kỳ báo cáo. Trên biểu đồ sẽ chọn ra các nhiệm vụ 
			|mà bắt đầu đến kỳ lập kế hoạch hoặc kết thúc sau đó.
			|Phương án báo cáo được dùng để tổng kết tất cả nhiệm vụ của quy trình ngân sách';
			|ru = 'В отчете отображаются все задачи, период планирования которых 
			|входит в период отчета. На диаграмму будут выведены задачи, 
			|которые начинаются до периода планирования или заканчиваются после.
			|Вариант отчета предназначен для обзора всех задач бюджетного процесса';
			|en = 'The report displays all tasks whose planning period is included
			|in the report period. Tasks starting before the planning period or ending after the planning period
			|will be displayed in the dashboard.
			|The report option is used to overview all budget process tasks'; fa = 'The report displays all tasks whose planning period is included
			|in the report period. Tasks starting before the planning period or ending after the planning period
			|will be displayed in the dashboard.
			|The report option is used to overview all budget process tasks';
			|it = 'Nel report vengono visualizzati tutti gli obiettivi il cui 
			| periodo di pianificazione è incluso nel periodo del report. Il diagramma mostra gli obiettivi
			|che iniziano prima del periodo di pianificazione o terminano dopo.
			|L''opzione del report serve per rivedere tutti gli obiettivi del processo di budget';
			|pl = 'Raport wyświetla wszystkie zadania, których okres planowania jest 
			|zawarty w okresie sprawozdawczym. Zadania, 
			|które rozpoczną się przed okresem planowania lub po nim, zostaną wyświetlone na diagramie.
			|Opcja raportu służy do przeglądania wszystkich zadań procesu budżetowego';
			|tr = 'Raporda tüm görevler, rapor döneminde dahil olan 
			| tüm tamamlama dönemleri yansıtılıyor. Grafiğe planlama döneminden önce başlayan veya planlama döneminden sonra biten
			| görevler çıkarılacak. 
			| Rapor seçeneği bütçe süreci tamamlama görevini kontrol etmeye amaçlandı'");
	Else
		NoteText2 = NStr("vi = 'Trong báo cáo hiển thị tất cả nhiệm vụ mà kỳ thực hiện của chúng 
			|nằm trong kỳ báo cáo.
			|Phương án báo cáo được dùng để kiểm soát thực hiện nhiệm vụ của quy trình ngân sách';
			|ru = 'В отчете отображаются все задачи, период выполнения которых 
			|входит в период отчета.
			|Вариант отчета предназначен для контроля исполнения задач бюджетного процесса';
			|en = 'The report displays all tasks which performance period
			|is included in the report period.
			|The report option is used to control execution of the budget process tasks'; fa = 'The report displays all tasks which performance period
			|is included in the report period.
			|The report option is used to control execution of the budget process tasks';
			|it = 'Nel report vengono visualizzati tutti gli obiettivi il cui 
			| periodo di pianificazione è incluso nel periodo del report.
			| L''opzione del report serve per controllare l''esecuzione degli obiettivi del processo di budget';
			|pl = 'Raport wyświetla wszystkie zadania, których okres wykonania 
			|zawarty jest w okresie sprawozdawczym.
			|Opcja raportu służy do kontrolowania realizacji zadań procesu budżetowego';
			|tr = 'Raporda tüm görevler, rapor dönemine dahil olan 
			| tüm tamamlama dönemleri yansıtılıyor. 
			| Rapor seçeneği bütçe süreci tamamlama görevini kontrol etmeye amaçlandı'");
	EndIf;
	
	Items.NoteToTheReportVersion.Title = NoteText2;
	
EndProcedure

&AtServer
Procedure RestoreSettings() 
	
	Attributes = ThisForm.GetAttributes();
	For Each Attribute In Attributes Do
		
		If Not Parameters.Property(Attribute.Name) Then
			Continue;
		EndIf;
		ThisForm[Attribute.Name] = Parameters[Attribute.Name];

	EndDo;
	
EndProcedure

&AtServer
Function GetCurrentSettings()
	
	CurrentSettings = New Structure;
	Attributes = ThisForm.GetAttributes();
	
	For Each Attribute In Attributes Do
		
		CurrentSettings.Insert(Attribute.Name,ThisForm[Attribute.Name]);

	EndDo;
	
	Return CurrentSettings;

EndFunction

&AtServer
Procedure FormControl()
		
	If Groups = "Variant1" And ValueIsFilled(BudgetingModel) Then
		PeriodicityOfModel = Common.ObjectAttributeValue(BudgetingModel, "Periodicity");
		PeriodicityName = Common.EnumerationValueName(PeriodicityOfModel);
		NewKindOfPeriod = Enums.AvailableReportPeriods[PeriodicityName];
		If PeriodType <> NewKindOfPeriod Then
			PeriodType = NewKindOfPeriod;
			EnterPeriodValue(PeriodType);
		EndIf;
	EndIf;
	
	Items.PeriodType.Enabled = Groups <> "Variant1";
	Items.ShowProcessExecutionPlan.Visible = ReportType > 0;
	
EndProcedure

&AtServer
Procedure EnterPeriodValue(PeriodType)
	
	BeginOfPeriod = TMCommonUseClientServer.BeginningOfReportPeriod(PeriodType, BeginOfPeriod);
	EndOfPeriod =  TMCommonUseClientServer.EndOfReportPeriod(PeriodType, BeginOfPeriod);
	
	PeriodsList = TMCommonUseClientServer.AvailablePeriodValuesByPeriodType(BeginOfPeriod, PeriodType);
	ListItem = PeriodsList.FindByValue(BeginOfPeriod);
	
	If ListItem = Undefined Then
		Period = "";
	Else
		Period = ListItem.Presentation;
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export

	If SelectedPeriod <> Undefined Then
		
		Period = SelectedPeriod.Presentation;
		
		BeginOfPeriod = SelectedPeriod.Value;
		EndOfPeriod = TMCommonUseClientServer.EndOfReportPeriod(PeriodType, SelectedPeriod.Value);
		
	EndIf; 
	
EndProcedure

#EndRegion



