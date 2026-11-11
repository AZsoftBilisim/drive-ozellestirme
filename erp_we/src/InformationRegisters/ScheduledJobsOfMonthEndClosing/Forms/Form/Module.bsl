
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not TMDataExchange.MonthClosingOperationsAreAvailableInThisNode(Cancel) Then
		Return;
	EndIf;
	
	ThisIsInternationalVersion = True;
	
	// Let's assemble the system settings into the Work Mode structure.
	WorkMode = New Structure;
	WorkMode.Insert("BaseVersion", 				 GetFunctionalOption("BaseVersion"));
	WorkMode.Insert("EnterpriseManagement",		 GetFunctionalOption("EnterpriseManagement"));
	WorkMode.Insert("ComplexAutomation",	 GetFunctionalOption("ComplexAutomation"));
	WorkMode.Insert("TradeManagement",			 GetFunctionalOption("TradeManagement"));
	WorkMode.Insert("ScheduleSettingIsPossible",  Not Common.DataSeparationEnabled());
	
	WorkMode.Insert("ManagementAccountingIsAvailable", True);
	WorkMode.Insert("RegulatedAccountingIsAvailable",
		False
		Or LocalAccntingServer.ThereIsRightOfReflectionOfDocumentsInLocalAccounting()
		Or ThisIsInternationalVersion
		);
	WorkMode.Insert("InternationalAccountingIsAvailable",
		False
		Or (GetFunctionalOption("UseFinancialAccounting")
			And AccessRight("Use", Metadata.DataProcessors.DocumentPostingInFinancialAccounting))
		);
	
	WorkMode = New FixedStructure(WorkMode);
	
	Organization = Parameters.Organization;
	PreviousCompany = Organization;
	
	CurrentPeriod = BegOfMonth(CurrentSessionDate());
	
	If CalculationOfCostCached.BatchAccountingVersion22() Then
		CurrentPeriodClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing;
	Else
		CurrentPeriodClosingMode = Enums.MonthEndClosingModes.FinalClosing;
	EndIf;
	
	// Let's configure the properties of the form elements.
	FillInStateOfRoutineTask();
	
	ConfigureElementsDuringFormInitialization();
	
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	SaveDetailsOfRoutineTask();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureJobSchedule(Command)
	
	If JobSchedule = Undefined Then
		JobSchedule = New JobSchedule;
	EndIf;
	
	Dialog = New ScheduledJobDialog(JobSchedule);
	
	CallbackDescription = New CallbackDescription(
		"ConfigureJobScheduleCompletion",
		ThisObject,
		New Structure("Dialog", Dialog));
	
	Dialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure OrganizationOnChange(Item)
	
	SaveDetailsOfRoutineTask();
	
	PreviousCompany = Organization;
	
	FillInStateOfRoutineTask();
	
	ConfigureFieldAvailability();
	
	SavedBankDetails = New UUID;
	
EndProcedure

&AtClient
Procedure OrganizationClearing(Item, StandardProcessing)
	
	OrganizationOnChange(Item);
	
EndProcedure

&AtClient
Procedure StartDateOnChange(Item)
	SavedBankDetails = New UUID;
EndProcedure

&AtClient
Procedure CloseTheOPPWhenChanging(Item)
	
	If Not CloseOperationalAccountingInPastPeriod Then
		
		CloseLocalAccountingInPastPeriod = False;
		CloseFinancialAccountingInPastPeriod = False;
		
	EndIf;
	
	ConfigureFieldAvailability();
	
	SavedBankDetails = New UUID;
	
EndProcedure

&AtClient
Procedure CloseTheRUPri(Item)
	
	If Not CloseLocalAccountingInPastPeriod Then
		
		CloseFinancialAccountingInPastPeriod = False;
		
	EndIf;
	
	ConfigureFieldAvailability();
	
	SavedBankDetails = New UUID;
	
EndProcedure

&AtClient
Procedure CloseApriChange(Item)
	
	ConfigureFieldAvailability();
	
	SavedBankDetails = New UUID;
	
EndProcedure

&AtClient
Procedure CloseTheCurrentPeriodWhenAChangeOccurs(Item)
	If Not CloseOperationalAccountingInCurrentPeriod Then
		CloseLocalAccountingInCurrentPeriod = False;
	EndIf;
	ConfigureFieldAvailability();
	SavedBankDetails = New UUID;
EndProcedure

&AtClient
Procedure CloseTheCurrentPeriodWhenTheChangeOccurs(Item)
	SavedBankDetails = New UUID;
EndProcedure

&AtClient
Procedure ClosingModeWhenChanging(Item)
	ConfigureFieldAvailability();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ConfigureElementsDuringFormInitialization()
	
	// Let's fill in the list of organizations available to the user with organizations.
	ChoiceList = Items.Organization.ChoiceList;
	ChoiceList.LoadValues(Catalogs.Companies.AvailableCompanies(True));
	If Not WorkMode.BaseVersion Then
		ChoiceList.Insert(0, Catalogs.Companies.EmptyRef(), NStr("vi = '<Theo tất cả doanh nghiệp>';
																|ru = '<По всем организациям>';
																|en = '<By all companies>'; fa = '<By all companies>';
																|it = '<per tutte le società>';
																|pl = '<dla wszystkich firm>';
																|tr = '<Tüm iş yerleri için>'"));
	EndIf;
	
	VisibilityInt = False;
	VisibilityInt = GetFunctionalOption("UseFinancialAccounting");
	Items.OUMonthClosingGroup.Enabled = WorkMode.ManagementAccountingIsAvailable;
	Items.URLMonthClosingGroup.Enabled = WorkMode.RegulatedAccountingIsAvailable;
	Items.URLMonthClosingGroup.Visible = WorkMode.RegulatedAccountingIsAvailable; 
	Items.CloseLocalAccountingInCurrentPeriod.Visible = WorkMode.RegulatedAccountingIsAvailable;
	Items.MUMonthClosingGroup.Enabled = WorkMode.InternationalAccountingIsAvailable;
	Items.MUMonthClosingGroup.Visible   = VisibilityInt;
	
	Items.ConfigureJobSchedule.Enabled = WorkMode.ScheduleSettingIsPossible;
		
	InformationRegisters.ScheduledJobsOfMonthEndClosing.FillInTaskAttributeForOrganizations(Items.Organization.ChoiceList);
	
	ConfigureFieldAvailability();
	
EndProcedure

&AtServer
Procedure ConfigureFieldAvailability()
	
	// Past periods
	Items.CloseLocalAccountingInPastPeriod.Enabled = CloseOperationalAccountingInPastPeriod;
	Items.CloseFinancialAccountingInPastPeriod.Enabled = CloseLocalAccountingInPastPeriod;
	
	// Current period
	Items.CurrentPeriodClosingMode.Enabled = CalculationOfCostCached.BatchAccountingVersion22();
	Items.CloseLocalAccountingInCurrentPeriod.Enabled = CloseOperationalAccountingInCurrentPeriod;
	
EndProcedure


#Region ScheduledJob

&AtServer
Procedure FillInStateOfRoutineTask()
	
	JobDetails = InformationRegisters.ScheduledJobsOfMonthEndClosing.GetRoutineTaskForOrganization(Organization);
	
	LastPeriodClosingStartDate = JobDetails.LastPeriodClosingStartDate;
	CloseOperationalAccountingInPastPeriod = JobDetails.CloseOperationalAccountingInPastPeriod;
	CloseLocalAccountingInPastPeriod = JobDetails.CloseLocalAccountingInPastPeriod;
	CloseFinancialAccountingInPastPeriod = JobDetails.CloseFinancialAccountingInPastPeriod;
	CurrentPeriodClosingMode = JobDetails.CurrentPeriodClosingMode;
	CloseOperationalAccountingInCurrentPeriod = JobDetails.CloseOperationalAccountingInCurrentPeriod;
	CloseLocalAccountingInCurrentPeriod = JobDetails.CloseLocalAccountingInCurrentPeriod;
	
	If Not ValueIsFilled(CurrentPeriodClosingMode) Then
		If CalculationOfCostCached.BatchAccountingVersion22() Then
			CurrentPeriodClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing;
		Else
			CurrentPeriodClosingMode = Enums.MonthEndClosingModes.FinalClosing;
		EndIf;
	EndIf;
	
	JobExists = JobDetails.JobExists;
	
	If JobDetails.Job <> Undefined Then
		JobSchedule = JobDetails.Job.Schedule;
	Else
		JobSchedule = New JobSchedule;
	EndIf;
		
	If Not WorkMode.ScheduleSettingIsPossible
	 And String(JobSchedule) = String(New JobSchedule) Then
		JobSchedule = PredefinedSchedule();
	EndIf;
	
	UpdateScheduleAndStatePresentation(JobDetails);
	
EndProcedure

&AtServer
Procedure SaveDetailsOfRoutineTask()
	
	SetPrivilegedMode(True);
	
	UsingTask = CloseOperationalAccountingInPastPeriod
		Or CloseLocalAccountingInPastPeriod
		Or CloseFinancialAccountingInPastPeriod
		Or CloseOperationalAccountingInCurrentPeriod
		Or CloseLocalAccountingInCurrentPeriod;
	
	If Not JobExists And Not UsingTask Then
		Return;
	EndIf;
	
	If Not WorkMode.ScheduleSettingIsPossible
	 And String(JobSchedule) = String(New JobSchedule) Then
		JobSchedule = PredefinedSchedule();
	EndIf;
	
	JobDetails = InformationRegisters.ScheduledJobsOfMonthEndClosing.GetRoutineTaskForOrganization(PreviousCompany);
	
	OrganizationsToCalculate_ = New Array;
	OrganizationsToCalculate_.Add(PreviousCompany);
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", UsingTask);
	JobParameters.Insert("Parameters",     OrganizationsToCalculate_);
	JobParameters.Insert("Schedule",    JobSchedule);
	
	If JobDetails.Job = Undefined Then
		
		NameString_ = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đóng tháng theo doanh nghiệp: %1';
				|ru = 'Закрытие месяца по организации: %1';
				|en = 'Month-end closing for company: %1'; fa = 'Month-end closing for company: %1';
				|it = 'Chiusura del mese per l''azienda: %1';
				|pl = 'Zamknięcie miesiąca dla firmy: %1';
				|tr = 'İş yerine göre ay sonu kapanışı: %1'"),
			?(ValueIsFilled(PreviousCompany), TrimAll(PreviousCompany), NStr("vi = 'Theo tất cả doanh nghiệp.';
																			|ru = 'По всем организациям.';
																			|en = 'By all companies.'; fa = 'By all companies.';
																			|it = 'Per tutte le aziende.';
																			|pl = 'Dla wszystkich firm.';
																			|tr = 'Tüm iş yerlerine.'")));
		
		JobParameters.Insert("Description", NameString_);
		JobParameters.Insert("Metadata",	  Metadata.ScheduledJobs.MonthEndTransactions);
		
		JobDetails.Job = ScheduledJobsServer.AddJob(JobParameters);
		
	Else
		
		ScheduledJobsServer.ChangeJob(JobDetails.Job, JobParameters);
		
	EndIf;
	
	JobDetails.JobID = ScheduledJobsServer.UUID(JobDetails.Job);
	JobDetails.JobState 	 = TMCommonUse.GetStateOfLastJob(JobDetails.Job);
	JobDetails.Use 		 = UsingTask;
	
	JobDetails.LastPeriodClosingStartDate = LastPeriodClosingStartDate;
	JobDetails.CloseOperationalAccountingInPastPeriod = CloseOperationalAccountingInPastPeriod;
	JobDetails.CloseLocalAccountingInPastPeriod = CloseLocalAccountingInPastPeriod;
	JobDetails.CloseFinancialAccountingInPastPeriod = CloseFinancialAccountingInPastPeriod;
	JobDetails.CurrentPeriodClosingMode = CurrentPeriodClosingMode;
	JobDetails.CloseOperationalAccountingInCurrentPeriod = CloseOperationalAccountingInCurrentPeriod;
	JobDetails.CloseLocalAccountingInCurrentPeriod = CloseLocalAccountingInCurrentPeriod;
	
	InformationRegisters.ScheduledJobsOfMonthEndClosing.WriteRoutineTaskForOrganization(JobDetails);
	InformationRegisters.ScheduledJobsOfMonthEndClosing.FillInTaskAttributeForOrganizations(Items.Organization.ChoiceList);
	
	UpdateScheduleAndStatePresentation(JobDetails);
	
EndProcedure

&AtServer
Procedure UpdateScheduleAndStatePresentation(JobDetails = Undefined)
	
	Items.ConfigureJobSchedule.Title =
		AuditOfSystemStateClientServer.SchedulePresentation(JobSchedule);
		
	If JobDetails <> Undefined And JobDetails.JobState <> Undefined Then
		
		If JobDetails.JobState.State = Undefined Then
			JobState = NStr("vi = 'Chưa thực hiện';
							|ru = 'Не выполнялось';
							|en = 'Not executed'; fa = 'اجرا نشده';
							|it = 'Non è stato effettuato';
							|pl = 'Nie było wykonywane';
							|tr = 'Gerçekleştirilmiyordu'");
		Else
			
			RefinementOfPlanning = "";
			
			If JobDetails.JobState.State = Enums.JobsStates.Scheduled
			 And ValueIsFilled(JobDetails.JobState.DatePlan) Then
				RefinementOfPlanning = " (" + TrimAll(JobDetails.JobState.DatePlan) + ")";
			EndIf;
			
			JobState =
				TrimAll(JobDetails.JobState.State) + RefinementOfPlanning + "; "
					+ NStr("vi = 'thực hiện gần nhất';
							|ru = 'последнее выполнение';
							|en = 'last execution'; fa = 'last execution';
							|it = 'ultima esecuzione';
							|pl = 'ostatnie wykonanie';
							|tr = 'son gerçekleştirme'") + ": "
					+ ?(ValueIsFilled(JobDetails.JobState.CompletedOn), TrimAll(JobDetails.JobState.CompletedOn), NStr("vi = 'còn chưa thực hiện';
																														|ru = 'еще не выполнялось';
																														|en = 'has not started yet'; fa = 'has not started yet';
																														|it = 'non ancora eseguito';
																														|pl = 'jeszcze nie było wykonywane';
																														|tr = 'henüz gerçekleştirilmedi'"));
			
		EndIf;
		
	ElsIf JobDetails <> Undefined Then
		
		JobState = NStr("vi = 'Chưa tùy chỉnh';
						|ru = 'Не настроено';
						|en = 'Not configured'; fa = 'پیکربندی نشده';
						|it = 'Non configurato';
						|pl = 'Nie ustawiono';
						|tr = 'Ayarlanmadı'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureJobScheduleCompletion(Schedule, AdditionalParameters) Export
	
	Dialog = AdditionalParameters.Dialog;
	
	If Schedule <> Undefined Then
		
		JobSchedule = Dialog.Schedule;
		UpdateScheduleAndStatePresentation();
		
	EndIf;
	
	SavedBankDetails = New UUID;
	
EndProcedure

&AtServer
Function PredefinedSchedule(ForInternationalAccounting = False)
	
	Months = New Array;
	Months.Add(1);
	Months.Add(2);
	Months.Add(3);
	Months.Add(4);
	Months.Add(5);
	Months.Add(6);
	Months.Add(7);
	Months.Add(8);
	Months.Add(9);
	Months.Add(10);
	Months.Add(11);
	Months.Add(12);
	
	WeekDays = New Array;
	WeekDays.Add(1);
	WeekDays.Add(2);
	WeekDays.Add(3);
	WeekDays.Add(4);
	WeekDays.Add(5);
	WeekDays.Add(6);
	WeekDays.Add(7);
	
	Schedule = New JobSchedule;
	Schedule.Months            = Months;
	Schedule.WeekDays         = WeekDays;
	Schedule.DaysRepeatPeriod = 1; // every day
	
	Schedule.BeginTime = Date('00010101220000'); // 22:00
		
	Return Schedule;
	
EndFunction

#EndRegion

#EndRegion
