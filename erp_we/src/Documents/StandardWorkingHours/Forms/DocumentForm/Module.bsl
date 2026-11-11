
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInAdditionalDetailsOfForm();
	
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// Handler of the "Date-change" mechanism
	CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", True);

	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FillInAdditionalDetailsOfForm();
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MonthOfRegistrationByLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.RegistrationMonth, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthOfRegistrationByLineTuning(Item, Direction, StandardProcessing)

	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Object.RegistrationMonth,
		MonthOfRegistrationByLine);
	
	MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);

EndProcedure

&AtClient
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", Object.RegistrationMonth);
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure FillInAccordingToWorkSchedule(Command)
	If Not ValueIsFilled(Object.ScheduleOfWork) Then
		Text = NStr("ru = 'Не заполнен График работ';
					|vi = 'The work schedule is not filled in';
					|en = 'The work schedule is not filled in'; fa = 'The work schedule is not filled in';
					|it = 'The work schedule is not filled in';
					|pl = 'The work schedule is not filled in';
					|tr = 'Doldurulmamış Çalışma takvimi'");
		CommonClient.MessageToUser(Text,,"ScheduleOfWork");
		
		Return;
	EndIf;	
	
	If Object.StandardsByPayCodes.Count() > 0 Then
		
		ShowQueryBox(New CallbackDescription("FillInWorkingTimeNormsEnd", ThisObject), 
			NStr("ru = 'Перед заполнением норм рабочего времени, таблица будет очищена. Продолжить?';
				|vi = 'Before filling in standard working hours, clear the table. Continue?';
				|en = 'Before filling in standard working hours, clear the table. Continue?'; fa = 'Before filling in standard working hours, clear the table. Continue?';
				|it = 'Before filling in standard working hours, clear the table. Continue?';
				|pl = 'Before filling in standard working hours, clear the table. Continue?';
				|tr = 'Çalışma zamanı normları doldurulmadan önce tablo temizlenecek. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
			
		Return;
		
	Else
		
		FillInNormsOfWorkingHoursAccordingToWorkSchedule();
		
	EndIf;	
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		Object.RegistrationMonth = SelectedPeriod;
		MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInWorkingTimeNormsEnd(QuestionResult, AdditionalParameters) Export

	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then  
		Object.StandardsByPayCodes.Clear();
	Else
		Return;
	EndIf;

	FillInNormsOfWorkingHoursAccordingToWorkSchedule();

EndProcedure

&AtClient
Procedure FillInNormsOfWorkingHoursAccordingToWorkSchedule()
	
	FillInNormsOfWorkingHoursAccordingToScheduleOfWorkATServer();
	
EndProcedure	

&AtServer
Procedure FillInNormsOfWorkingHoursAccordingToScheduleOfWorkATServer();
	
	ScheduleOfWorkToFillIn = Object.ScheduleOfWork;
	FillParameters = CatalogsSalaryAndPersonnelServer.ParametersOfFillingNorms();
	FillPropertyValues(FillParameters, ScheduleOfWorkToFillIn);
	FillParameters.WorkScheduleCalendar = ScheduleOfWorkToFillIn;
	NormsAccordingToSchedule = CatalogsSalaryAndPersonnelServer.GetStandardsForWorkSchedule(
					BegOfDay(Object.RegistrationMonth), EndOfMonth(Object.RegistrationMonth), FillParameters);
	
	Object.StandardsByPayCodes.Load(NormsAccordingToSchedule);
	
EndProcedure	

&AtServer
Procedure FillInAdditionalDetailsOfForm()
		
	MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
	
EndProcedure	

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
