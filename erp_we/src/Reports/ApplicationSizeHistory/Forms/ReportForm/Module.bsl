#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ApplicationsSize.CheckSupportForAppSizeCalculation();
	
	UpdateAppSizeGroupVisibility();
	UpdateInformationAboutAppSizeCalculation();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EnableCalculationWaitingHandler();
	
	Period = New StandardPeriod(StandardPeriodVariant.ThisQuarter);
	SortingOption = "BySizeAtPeriodEnd";
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SortingOptionOnChange(Item)
	
	ModifiedTo = VariantModified;
	
	FieldSizeAtPeriodEnd	= New DataCompositionField("SizeAtPeriodEnd");
	FieldGrowthAbsolute		= New DataCompositionField("Growth_Absolute");
	SortingElement_SizeAtEndOfPeriod	= Undefined;
	SortingElement_GrowthAbsolute		= Undefined;
	For Each SortingElement In Report.SettingsComposer.Settings.Order.Items Do
		If SortingElement.Field = FieldSizeAtPeriodEnd Then
			SortingElement_SizeAtEndOfPeriod = SortingElement;
		ElsIf SortingElement.Field = FieldGrowthAbsolute Then
			SortingElement_GrowthAbsolute = SortingElement;
		EndIf;
	EndDo;
	
	If SortingOption = "BySizeAtPeriodEnd" Then
		If SortingElement_SizeAtEndOfPeriod <> Undefined Then
			SortingElement_SizeAtEndOfPeriod.Use = True;
			SortingElement_SizeAtEndOfPeriod.OrderType = DataCompositionSortDirection.Desc;
		Else
			SortingElement = Report.SettingsComposer.Settings.Order.Items.Add(Type("DataCompositionOrderItem"));
			SortingElement.Use = True;
			SortingElement.Field = FieldSizeAtPeriodEnd;
			SortingElement.OrderType = DataCompositionSortDirection.Desc;	
		EndIf;	
	ElsIf SortingElement_SizeAtEndOfPeriod <> Undefined Then
		SortingElement_SizeAtEndOfPeriod.Use = False;		
	EndIf;
	
	If SortingOption = "ByAbsoluteGrowth" Then
		If SortingElement_GrowthAbsolute <> Undefined Then
			SortingElement_GrowthAbsolute.Use = True;
			SortingElement_GrowthAbsolute.OrderType = DataCompositionSortDirection.Desc;
		Else
			SortingElement = Report.SettingsComposer.Settings.Order.Items.Add(Type("DataCompositionOrderItem"));
			SortingElement.Use = True;
			SortingElement.Field = FieldGrowthAbsolute;
			SortingElement.OrderType = DataCompositionSortDirection.Desc;	
		EndIf;	
	ElsIf SortingElement_GrowthAbsolute <> Undefined Then
		SortingElement_GrowthAbsolute.Use = False;		
	EndIf;
	
	If Not ModifiedTo Then
		VariantModified = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayOnlyChangesOnChange(Item)
	
	ModifiedTo = VariantModified;
	
	FilterField = New DataCompositionField("Growth_Absolute");
	FoundSelection = Undefined;
	For Each FilterElement In Report.SettingsComposer.Settings.Filter.Items Do
		If FilterElement.LeftValue = FilterField
			And FilterElement.Presentation = NStr("vi = 'Hiển thị chỉ phần thay đổi';
													|ru = 'Отображать только изменившиеся';
													|en = 'Display only changed ones'; fa = 'نمایش فقط موارد تغییرکرده';
													|it = 'Display only changed ones';
													|pl = 'Display only changed ones';
													|tr = 'Sadece değiştirilenleri göster'") Then
			FoundSelection = FilterElement;
			Break;	
		EndIf;		
	EndDo;
	
	If FoundSelection <> Undefined Then
		FoundSelection.Use = DisplayOnlyChanges;
	ElsIf DisplayOnlyChanges Then
		FilterElement = Report.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use		= True;
		FilterElement.LeftValue		= New DataCompositionField("Growth_Absolute");
		FilterElement.ComparisonType		= DataCompositionComparisonType.NotEqual;
		FilterElement.Presentation		= NStr("vi = 'Hiển thị chỉ phần thay đổi';
												|ru = 'Отображать только изменившиеся';
												|en = 'Display only changed ones'; fa = 'نمایش فقط موارد تغییرکرده';
												|it = 'Display only changed ones';
												|pl = 'Display only changed ones';
												|tr = 'Sadece değiştirilenleri göster'");
		FilterElement.RightValue	= 0;		
	EndIf;
	
	If Not ModifiedTo Then
		VariantModified = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodOfUseOnChange(Item)
	
	SetCompositionParameterValue("ReportPeriod", Period, PeriodOfUse);	
	
	UpdateGroupVisibilityAppSizeAtClient();
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	PeriodOfUse = True;
	SetCompositionParameterValue("ReportPeriod", Period, PeriodOfUse);
	
	UpdateGroupVisibilityAppSizeAtClient();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	
	If CalculationIsRunning Or ThereIsDataForGeneratingReport() Then
		
		GenerateReportContinued();
		
	Else
		
		QueryText = NStr("vi = 'Chưa thực hiện tính toán dung lượng ứng dụng.
							|Thực hiện ngay?';
							|ru = 'Расчет размера приложения не выполнялся.
							|Выполнить сейчас?';
							|en = 'Application size was not calculated.
							|Do you want to calculate it now?'; fa = 'Application size was not calculated.
							|Do you want to calculate it now?';
							|it = 'Calcolo dimensione applicazione non eseguito.
							|Eseguire ora?';
							|pl = 'Obliczenie rozmiaru aplikacji nie było wykonane.
							|Wykonać teraz?';
							|tr = 'Uygulama boyutu hesaplaması yapılmadı.
							|Şimdi çalıştırmak istiyor musunuz?'");
		Handler = New CallbackDescription("HandlerForCalculationIssue", ThisObject);
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateApplicationSize(Command)
	
	If Not AppCalculationIsAvailable() Then
		Raise NStr("vi = 'Trong phiên làm việc chưa chia tách không thể tính toán dung lượng ứng dụng';
					|ru = 'В неразделенном сеансе недоступен расчет размера приложения';
					|en = 'Application size calculation is not available in a shared session'; fa = 'Application size calculation is not available in a shared session';
					|it = 'В неразделенном сеансе недоступен расчет размера приложения';
					|pl = 'W niepodzielonej sesji niedostępne jest obliczenie rozmiaru aplikacji';
					|tr = 'Uygulama boyutu hesaplaması, paylaşımlı oturumda kullanılamaz'");
	EndIf;
	
	RunCalculationApplicationSize();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateReportContinued()
	
	GenerateReportAfterPerformingCalculation = False;
	ThisObject.ComposeResult(ResultCompositionMode.Background);
	
EndProcedure

&AtClient
Procedure SetCompositionParameterValue(ParameterName, ParameterValue, Use)

	ModifiedTo = VariantModified;
	
	Parameter = Report.SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If Parameter <> Undefined Then
		Parameter.Value = ParameterValue;
		Parameter.Use = Use;
		If ParameterName = "ReportPeriod" Then
			PeriodStartParameter = Report.SettingsComposer.Settings.DataParameters.Items.Find("BegPeriod");
			PeriodStartParameter.Value = ?(ValueIsFilled(ParameterValue.StartDate), 
				ParameterValue.StartDate, Date(1,1,1,0,0,1));
			PeriodStartParameter.Use = Use;
		EndIf
	EndIf;
	
	If Not ModifiedTo Then
		VariantModified = False;
	EndIf;
	
EndProcedure

#Region CalculatingApplicationSize

&AtClient
Procedure EnableCalculationWaitingHandler(IncreaseInterval = 0)
	
	If Not CalculationIsRunning Then
		Return;
	EndIf;
	
	WaitingIntervalForCalculation = Max(5 + IncreaseInterval, 300);
	AttachIdleHandler("CheckResultOfApplicationSizeCalculationTask",
		WaitingIntervalForCalculation, True);
	
EndProcedure

&AtClient
Procedure CheckResultOfApplicationSizeCalculationTask()
	
	If ThereIsScheduledJobCalculatingSizeOfApplication() Then
		
		EnableCalculationWaitingHandler(WaitingIntervalForCalculation);
		
	Else
		
		UpdateInformationAboutAppSizeCalculation();
		
		If GenerateReportAfterPerformingCalculation Then
			GenerateReportContinued();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlerForCalculationIssue(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		GenerateReportAfterPerformingCalculation = True;
		RunCalculationApplicationSize();
		
	Else
		
		GenerateReportContinued();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RunCalculationApplicationSize()
	
	If IsSeparatedSession() Then
		
		ScheduleApplicationSizeCalculation();
		EnableCalculationWaitingHandler();
		
	Else
		
		TimeConsumingOperation = StartBackgroundCalculationOfAppSize(UUID);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.MessageText = NStr("vi = 'Đang tính toán dung lượng ứng dụng';
											|ru = 'Выполняется расчет размера приложения';
											|en = 'Calculating the application size'; fa = 'Calculating the application size';
											|it = 'Calcolo dimensione applicazione in corso';
											|pl = 'Trwa obliczenie rozmiaru aplikacji';
											|tr = 'Uygulama boyut hesaplaması gerçekleştiriliyor'");
		
		CallbackOnCompletion = New CallbackDescription("CalculatingApplicationSizeCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculatingApplicationSizeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	 
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	ElsIf Result.Status = "Completed2" Then
		
		UpdateInformationAboutAppSizeCalculation();
		
		If GenerateReportAfterPerformingCalculation Then
			GenerateReportContinued();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StartBackgroundCalculationOfAppSize(Val FormIdentifier)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính toán dung lượng ứng dụng';
														|ru = 'Расчет размера приложения';
														|en = 'Calculate application size'; fa = 'محاسبه اندازه برنامه';
														|it = 'Calcolo dimensione applicazione';
														|pl = 'Obliczenie rozmiaru aplikacji';
														|tr = 'Uygulama boyut hesabı'");
	ExecutionParameters.BackgroundJobKey = String(New UUID);
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"Reports.ApplicationSizeHistory.CalculateApplicationSize",
		Undefined,
		ExecutionParameters);
	
EndFunction

&AtServer
Procedure ScheduleApplicationSizeCalculation()
	
	ApplicationsSize.ScheduleApplicationSizeCalculation();
	UpdateApplicationCalculationExecution();
	
EndProcedure

#EndRegion

#Region InterfaceUpdate

&AtClient
Procedure UpdateGroupVisibilityAppSizeAtClient()

	If PeriodOfUse 
		And ValueIsFilled(Period) 
		And Period.EndDate <= CommonClient.SessionDate() Then
		Items.ApplicationSizeGroup.Visible = False;
	Else
		UpdateAppSizeGroupVisibility();
	EndIf; 
	
EndProcedure

&AtServer
Procedure UpdateAppSizeGroupVisibility()
	
	CalculationAvailable = AppCalculationIsAvailable();
	Items.ApplicationSizeGroup.Visible = CalculationAvailable;
	
	If Not CalculationAvailable Then
		Return;
	EndIf;
	
	MinimumStepChanges = ApplicationsSize.CalculationSettingValue("MinimumStepChanges", 0);
	If MinimumStepChanges > 0 Then
		
		Items.CalculateApplicationSize.ToolTipRepresentation = ToolTipRepresentation.Button;
		Items.CalculateApplicationSizeExtendedTooltip.Title = StrTemplate(
			NStr("vi = 'Không hiển thị thay đổi với dung lượng đối tượng metadata nhỏ hơn %1 Mb';
				|ru = 'Изменения в размере объекта метаданных меньше %1 Мб не отображаются';
				|en = 'Changes in the metadata object size less than %1 MB are not displayed'; fa = 'Changes in the metadata object size less than %1 MB are not displayed';
				|it = 'Modifiche della misura dell''oggetto di metadati inferiori a %1 MB non vengono visualizzate';
				|pl = 'Zmiany rozmiaru obiektu metadanych mniej niż %1 MB nie są wyświetlane';
				|tr = '%1Mb''tan küçük meta veri nesne boyutundaki değişiklikler görüntülenmiyor'"),
			MinimumStepChanges / 1024 / 1024);
		
	Else 
		
		Items.CalculateApplicationSize.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInformationAboutAppSizeCalculation()
	
	UpdateRelevanceOfAppCalculation();
	UpdateApplicationCalculationExecution();
	
EndProcedure

&AtServer
Procedure UpdateApplicationCalculationExecution()
	
	If Not AppCalculationIsAvailable() Then
		Return;
	EndIf;
	
	CalculationIsRunning = ?(IsSeparatedSession(), ThereIsScheduledJobCalculatingSizeOfApplication(), False);

	Items.CalculateApplicationSize.Visible = Not CalculationIsRunning; 
	Items.HowApplicationCalculationIsPerformed.Visible = CalculationIsRunning;
	
EndProcedure

&AtServer
Procedure UpdateRelevanceOfAppCalculation()
	
	If Not AppCalculationIsAvailable() Then
		Return;
	EndIf;
	
	DateOfCalculation = ApplicationsSize.RelevanceOfApplicationSizeCalculation();
	InfoRelevanceOfCalculation = ?(ValueIsFilled(DateOfCalculation),
		StrTemplate(NStr("vi = 'Đã tính toán dung lượng ứng dụng: %1';
						|ru = 'Расчет размера приложения выполнен: %1';
						|en = 'Application size is calculated: %1'; fa = 'Application size is calculated: %1';
						|it = 'Il calcolo della dimensione di applicazione è stato eseguito: %1';
						|pl = 'Obliczenie rozmiaru aplikacji zostało wykonane: %1';
						|tr = 'Uygulama boyut hesaplaması gerçekleştirildi: %1'"), Format(DateOfCalculation, NStr("vi = 'ДФ=дд.ММ.гггг;';
																										|ru = 'ДФ=dd.MM.yyyy;';
																										|en = 'DF=MM/dd/yyyy;'; fa = 'DF=MM/dd/yyyy;';
																										|it = 'ДФ=дд.ММ.гггг;';
																										|pl = 'DF=dd.MM.yyyy;';
																										|tr = 'DF=dd.MM.yyyy;'"))),
		NStr("vi = 'Chưa tính toán dung lượng ứng dụng';
			|ru = 'Расчет размера приложения не выполнялся';
			|en = 'Application size was not calculated'; fa = 'Application size was not calculated';
			|it = 'Calcolo dimensione applicazione non eseguito';
			|pl = 'Obliczenie rozmiaru aplikacji nie zostało wykonane';
			|tr = 'Uygulama boyut hesaplaması gerçekleştirilmesi'"));

EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function ThereIsScheduledJobCalculatingSizeOfApplication()
	
	Return ApplicationsSize.ThereIsScheduledJobCalculatingSizeOfApplication();
	
EndFunction

&AtServerNoContext
Function AppCalculationIsAvailable()
	
	If SaaSOperations.DataSeparationEnabled()
		And Not SaaSOperations.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function IsSeparatedSession()
	
	Return SaaSOperations.DataSeparationEnabled() And SaaSOperations.SeparatedDataUsageAvailable();
	
EndFunction

&AtServerNoContext
Function ThereIsDataForGeneratingReport()
	
	If Not AppCalculationIsAvailable() Then
		Return True;
	EndIf;
	
	DateOfCalculation = ApplicationsSize.RelevanceOfApplicationSizeCalculation();
	Return ValueIsFilled(DateOfCalculation);
	
EndFunction

#EndRegion

#EndRegion
