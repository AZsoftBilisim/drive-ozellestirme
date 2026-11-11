#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not TMDataExchange.MonthClosingOperationsAreAvailableInThisNode(Cancel) Then
		Return;
	EndIf;
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.MonthEndClosingOperations.Command.MonthEndClosingOperations");
	
	// Let's check the end of the IB update.
	DataProcessors.MonthEndClosingOperations.CheckBlockingIncomingDataWhenUpdatingInformationSecurity();
	
	// Let's assemble the system settings into the Work Mode structure.
	WorkMode = New Structure;

	WorkMode.Insert("BaseVersion", 				 GetFunctionalOption("BaseVersion"));
	WorkMode.Insert("EnterpriseManagement",		 GetFunctionalOption("EnterpriseManagement"));
	WorkMode.Insert("ComplexAutomation",	 GetFunctionalOption("ComplexAutomation"));
	WorkMode.Insert("TradeManagement",			 GetFunctionalOption("TradeManagement"));
	WorkMode.Insert("ContextualOpeningOfForm",  	 ValueIsFilled(Parameters.RegistrationPeriod));
	
	WorkMode.Insert("UseMultipleCompanies",
		GetFunctionalOption("UseMultipleCompanies"));
	
	ThereIsRightOfReflectionOfDocumentsInLocalAccounting = GetFunctionalOption("TradeManagement");
	ThereIsRightOfReflectionOfDocumentsInLocalAccounting =
		ThereIsRightOfReflectionOfDocumentsInLocalAccounting Or LocalAccntingServer.ThereIsRightOfReflectionOfDocumentsInLocalAccounting();
	ThereIsRightToReflectDocumentsInInternationalAccounting = False;
	ThereIsRightToReflectDocumentsInInternationalAccounting = ThereIsRightToReflectDocumentsInInternationalAccounting
		Or FinancialAccountingOfGeneralPurpose.ThereIsRightToReflectDocumentsInInternationalAccounting();
	WorkMode.Insert("AvailabilityOfAccountingTypes", New Structure);
	WorkMode.AvailabilityOfAccountingTypes.Insert("OperationalAccounting", True);
	WorkMode.AvailabilityOfAccountingTypes.Insert("LocalAccounting", ThereIsRightOfReflectionOfDocumentsInLocalAccounting);
	WorkMode.AvailabilityOfAccountingTypes.Insert("FinancialAccounting", ThereIsRightToReflectDocumentsInInternationalAccounting);
	
	WorkMode = New FixedStructure(WorkMode);
	
	// Fill in the default form parameters.
	If WorkMode.ContextualOpeningOfForm Then
		Object.RegistrationPeriod = Parameters.RegistrationPeriod;
		Object.CompanyArray = OrganizationInFixedArray(Parameters.Organization);
	Else
		Object.RegistrationPeriod = BegOfMonth(CurrentSessionDate());
		Object.CompanyArray = OrganizationInFixedArray(SettingsValueCached.GetDefaultOrganization());
	EndIf;
	
	If Not WorkMode.UseMultipleCompanies Then
		Object.CompanyArray = New FixedArray(New Array);
	EndIf;
	
	Object.AllCompanies = Not ValueIsFilled(Object.CompanyArray);
	
	CompanyDescription = DataProcessors.MonthEndClosingOperations.DescriptionOfOrganizationsToCalculate(Object.RegistrationPeriod, True);
	DescriptionOfOrganizationsFormed = False;
	
	Object.HideStepsWithNotRequireStatus = True;
	Object.HideStepsCompletedSuccessfully = False;
	Object.HideExplanationsToSteps = False;
	Object.AutoUpdateWhenClosingSubordinateForms = True;
	Object.MonthEndClosingMode = Enums.MonthEndClosingModes.FinalClosing;
	Object.PreliminaryMonthEndClosingDate = EndOfMonth(Object.RegistrationPeriod);
	
	DataStorage = New ValueStorage(Undefined);
	CalculationState = DataProcessors.MonthEndClosingOperations.InitializeStateStructureOfCalculation(Undefined);
	
	// Let's configure the properties of the form elements.
	ConfigureElementsDuringFormInitialization();
	SetFormItemsVisibility();
	SetAvailabilityOfMonthClosingMode();
	
	MonthEndTransactionsLocalization.WhenCreatingMonthClosingFormOnServer(Cancel, StandardProcessing, ThisObject);
	
	If Not WorkMode.AvailabilityOfAccountingTypes.OperationalAccounting
	 And Not WorkMode.AvailabilityOfAccountingTypes.LocalAccounting
	 And Not WorkMode.AvailabilityOfAccountingTypes.FinancialAccounting Then
		
		Common.MessageToUser(
			NStr("vi = 'Không đủ quyền thực hiện các giao dịch kết chuyển cuối tháng.';
				|ru = 'Недостаточно прав на выполнение операций закрытия месяца.';
				|en = 'Insufficient rights to perform month-end closing operations.'; fa = 'Insufficient rights to perform month-end closing operations.';
				|it = 'Diritti insufficienti per eseguire operazioni di chiusura del mese.';
				|pl = 'Nie masz wystarczających uprawnień do wykonania operacji zamknięcia miesiąca.';
				|tr = 'Ay sonu kapanış işlemleri için yetersiz erişim yetkisi'"));
		
		Cancel = True;
		
		Return;
		
	EndIf;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If WorkMode.ContextualOpeningOfForm Then
		Settings.Insert("Object.RegistrationPeriod", Parameters.RegistrationPeriod);
		Settings.Insert("Object.CompanyArray", OrganizationInFixedArray(Parameters.Organization));
		Settings.Insert("Object.AllCompanies",    Not ValueIsFilled(Settings.Get("Object.CompanyArray")));
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CompanyArray = Settings.Get("Object.CompanyArray");
	
	If Not WorkMode.UseMultipleCompanies
	 Or Not ValueIsFilled(CompanyArray) Then
		Object.CompanyArray = New FixedArray(New Array);
	Else
		Object.CompanyArray = CompanyArray;
	EndIf;
	
	Object.AllCompanies = Not ValueIsFilled(Object.CompanyArray);

	If Not WorkMode.ContextualOpeningOfForm Then
		
		FirstUnblockedPeriod = InformationRegisters.SetUpLockFromChanges.UnblockedPeriod(Object.CompanyArray);
		Object.RegistrationPeriod = BegOfMonth(Max(Object.RegistrationPeriod, FirstUnblockedPeriod));
		
	EndIf;

	ConfigureElementsDuringFormInitialization(True);
	SetFormItemsVisibility();
	SetAvailabilityOfMonthClosingMode();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateFormDataInBackgroundOnClient(,False);
	
	#If WebClient Then
		ColumnWidth_ = 4;
		InformationAboutCalculationStart = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Người sử dụng ""%1"" qua web-client';
				|ru = 'Пользователь ""%1"" через веб-клиент';
				|en = 'User ""%1"" via web client'; fa = 'User ""%1"" via web client';
				|it = 'Utente ""%1"" tramite web-client';
				|pl = 'Użytkownik ""%1"" za pośrednictwem klienta internetowego';
				|tr = 'Web istemcisi aracılığı ile ""%1"" kullanıcısı'", DefaultLanguageCode),
			UserName());
	#Else
		ColumnWidth_ = 4;
		InformationAboutCalculationStart = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Người sử dụng ""%1"" từ máy tính ""%2""';
				|ru = 'Пользователь ""%1"" с компьютера ""%2""';
				|en = 'The ""%1"" user from the ""%2"" computer'; fa = 'The ""%1"" user from the ""%2"" computer';
				|it = 'Utente ""%1"" dal computer ""%2""';
				|pl = 'Użytkownik ""%1"" z komputera ""%2""';
				|tr = '""%2"" bilgisayardan ""%1"" kullanıcısı'", DefaultLanguageCode),
			UserName(),
			ComputerName());
	#EndIf
	
	// Adjust the width of the hyperlink columns.
	Items.StageTreeGroupPerform.Width 	 		= ColumnWidth_;
	Items.StageTreeGroupTextPerform.Width 		= ColumnWidth_;
	Items.StageTreeTextExecute.Width 		 		= ColumnWidth_;
	Items.StageTreeGroupHyperlinkRun.Width 	= ColumnWidth_;
	Items.TheTreeStagesTheHyperlinkToComplete.Width 		= ColumnWidth_;
	Items.StageTreeGroupMore.Width 	 		= ColumnWidth_;
	Items.StageTreeGroupTextMore.Width 		= ColumnWidth_;
	Items.StageTreeReadMoreText.Width 				= ColumnWidth_;
	Items.StageTreeGroupHyperlinkMore.Width 	= ColumnWidth_;
	Items.StageTreeHyperlinkMoreInformation.Width 		= ColumnWidth_;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		DetachIdleHandler("CheckActivityOfBackgroundFormUpdateJob");
		DetachIdleHandler("CheckActivityOfBackgroundCalculationTask");
		CompletingTasksWhenClosingForm();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MonthEndClosingModeOnChange(Item)
	SetFormItemsVisibility();
	UpdateFormDataInBackgroundOnClient(,False);
EndProcedure

&AtClient
Procedure MonthEndClosingModeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure EndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	Object.RegistrationPeriod = BegOfMonth(Object.PreliminaryMonthEndClosingDate);
	RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationPeriod);
	SetAvailabilityOfMonthClosingMode();
	If Not BatchAccountingVersion22 Then
		ShowMessageBox(Undefined,
			NStr("vi = 'Chỉ hỗ trợ kết chuyển cuối tháng sơ bộ khi sử dụng kế toán theo lô phiên bản 2.2.';
				|ru = 'Предварительное закрытие месяца поддерживается только при использовании партионного учета версии 2.2.';
				|en = 'Preliminary month-end closing is only supported when using lot accounting version 2.2.'; fa = 'Preliminary month-end closing is only supported when using lot accounting version 2.2.';
				|it = 'Preliminary month-end closing is only supported when using lot accounting version 2.2.';
				|pl = 'Preliminary month-end closing is only supported when using lot accounting version 2.2.';
				|tr = 'Ay sonu ön kapanışı, yalnızca lot muhasebesi sürüm 2.2 kullanıldığında desteklenir.'"));
		Object.MonthEndClosingMode = PredefinedValue("Enum.MonthEndClosingModes.FinalClosing");
		SetFormItemsVisibility();
	EndIf;
	UpdateFormDataInBackgroundOnClient(,False);
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.RegistrationPeriod, "MONTH");
	
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
Procedure RegistrationPeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Object.RegistrationPeriod,
		RegistrationPeriodPresentation);
	
	RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationPeriod);
	Object.PreliminaryMonthEndClosingDate = EndOfMonth(Object.RegistrationPeriod);
	
	UpdateFormDataInBackgroundOnClient(,False);
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesStartChoice(Item, ChoiceData, StandardProcessing)
	
	CloseHandler = New CallbackDescription("CalculatedCompaniesStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("RegistrationPeriod", 	Object.RegistrationPeriod);
	FormParameters.Insert("CompanyArray", 	Object.CompanyArray);
	FormParameters.Insert("AllCompanies", 		Object.AllCompanies);
	FormParameters.Insert("CompanyDescription", 	CompanyDescription);
	
	OpenForm("DataProcessor.MonthEndClosingOperations.Form.SelectCompanies",
		FormParameters,
		ThisObject, 
		UUID,
		,
		,
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Object.AllCompanies = Result.AllCompanies
	 And TMCommonUseClientServer.ArraysAreEqual(Object.CompanyArray, Result.CompanyArray) Then
		Return;
	EndIf;
	
	Object.AllCompanies 	 = Result.AllCompanies;
	Object.CompanyArray = New FixedArray(Result.CompanyArray);
	
	CreatePresentationOfOrganizations();
	
	UpdateFormDataInBackgroundOnClient(Not DescriptionOfOrganizationsFormed, False);
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.AllCompanies Then
		Return;
	EndIf;
	
	Object.AllCompanies 	 = True;
	Object.CompanyArray = New FixedArray(New Array);
	
	CreatePresentationOfOrganizations();
	
	UpdateFormDataInBackgroundOnClient(Not DescriptionOfOrganizationsFormed, False);
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesOpening(Item, StandardProcessing)
	
	If Object.CompanyArray.Count() <> 1 Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ShowValue(, Object.CompanyArray[0]);
	
EndProcedure

&AtClient
Procedure RepresentationOfTheCalculationStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL <> "MoreDetails" Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SettlementStartDate", 			CommonSettlementStartDate);
	FormParameters.Insert("RegistrationPeriod", 			Object.RegistrationPeriod);
	FormParameters.Insert("IsPeriodLocked", 			IsPeriodLocked);
	FormParameters.Insert("PeriodIsPartiallyBlocked", 	PeriodIsPartiallyBlocked);
	FormParameters.Insert("ExplanationToChangeProhibition", 	ExplanationToChangeProhibition);
	FormParameters.Insert("DecryptionOfLock", 		DecryptionOfLock);
	FormParameters.Insert("DecryptionOfTasks", 			DecryptionOfTasks);
	
	CloseHandler = New CallbackDescription("ClosingHyperlinkFormAction", ThisObject);
	
	OpenForm(
		"DataProcessor.MonthEndClosingOperations.Form.PeriodEndClosing",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		CloseHandler);
	
EndProcedure

&AtClient
Procedure StageTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StageTreeString = StageTree.FindByID(RowSelected);
	If StageTreeString = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem = Items.TheTreeStagesTheHyperlinkToComplete And Not ChangesAreDisabled Then
		
		If StageTreeString.ExecutionAtServer Then
		
			StandardProcessing = False;
			NotificationOfEndOfSelection =
				New CallbackDescription("StageTreeSelectionCompletion", ThisObject);
			
			ListOfItemTypes = New ValueList;
			ListOfItemTypes.Add("ThisOneAndPreviousOnes",
				NStr("vi = 'Thực hiện giai đoạn này và tất cả các giai đoạn trước đó (nên dùng)';
					|ru = 'Выполнить этот и все предыдущие этапы (рекомендуется)';
					|en = 'Complete this and all previous stages (recommended)'; fa = 'Complete this and all previous stages (recommended)';
					|it = 'Complete this and all previous stages (recommended)';
					|pl = 'Complete this and all previous stages (recommended)';
					|tr = 'Bunu ve önceki tüm aşamaları tamamla (önerilir)'"),,
				PictureLib.BusinessProcessStart);
				
			ListOfItemTypes.Add("JustThisOne",
				NStr("vi = 'Chỉ thực hiện giai đoạn này';
					|ru = 'Выполнить только этот этап';
					|en = 'Complete this stage only'; fa = 'Complete this stage only';
					|it = 'Complete this stage only';
					|pl = 'Complete this stage only';
					|tr = 'Sadece bu aşamayı tamamla'"),,PictureLib.GoForward);
			
			ShowChooseFromMenu(NotificationOfEndOfSelection, ListOfItemTypes);
			
		Else
			ProcessHyperlinkClick(StageTreeString, True);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.StageTreeHyperlinkMoreInformation Then
		ProcessHyperlinkClick(StageTreeString, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure StageTreeSelectionCompletion(SelectedMethod, AddlParameters) Export
	
	If SelectedMethod = Undefined Then
		Return;
	EndIf;

	If SelectedMethod.Value = "ThisOneAndPreviousOnes" Then
		ProcessHyperlinkClick(
			StageTree.FindByID(Items.StageTree.CurrentRow), True, False);
	ElsIf SelectedMethod.Value = "JustThisOne" Then
		ProcessHyperlinkClick(
			StageTree.FindByID(Items.StageTree.CurrentRow), True, True);
	EndIf;

EndProcedure

&AtClient
Procedure SettingsForRoutineTaskOfNonOperationalDocumentVerificationClick(Item)

	FormParameters = New Structure;
	FormParameters.Insert("Action", "Change");
	FormParameters.Insert("Id",
		ParametersOfRoutineTaskInNonOperationalQueue.ScheduledJobID);

	NameOfRoutineTaskForm = "DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJob";
	OpenForm(NameOfRoutineTaskForm, FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region UniversalFormCommandHandlers

&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	MonthEndTransactionsClientLocalization.ExecuteLocalizationCommand(Command, ThisObject);
	
EndProcedure

#EndRegion

&AtClient
Procedure HideStepsWithNotRequireStatus(Command)
	
	Object.HideStepsWithNotRequireStatus = Not Object.HideStepsWithNotRequireStatus;
	
	AdjustMarkOfSettingsButtons(Object, Items);
	
	FillFormWithUpdatedDataOnClient();
	
EndProcedure

&AtClient
Procedure HideStepsCompletedSuccessfully(Command)
	
	Object.HideStepsCompletedSuccessfully = Not Object.HideStepsCompletedSuccessfully;
	
	AdjustMarkOfSettingsButtons(Object, Items);
	
	FillFormWithUpdatedDataOnClient();
	
EndProcedure

&AtClient
Procedure HideExplanationsToSteps(Command)
	
	Object.HideExplanationsToSteps = Not Object.HideExplanationsToSteps;
	
	AdjustMarkOfSettingsButtons(Object, Items);
	
	FillFormWithUpdatedDataOnClient();
	
EndProcedure

&AtClient
Procedure AutoUpdateWhenClosingSubordinateForms(Command)
	
	Object.AutoUpdateWhenClosingSubordinateForms = Not Object.AutoUpdateWhenClosingSubordinateForms;
	
	AdjustMarkOfSettingsButtons(Object, Items);
	
EndProcedure

&AtClient
Procedure ConfigureChecks(Command)
	
	CloseHandler = New CallbackDescription("ClosingHyperlinkFormAction", ThisObject);
	
	OpenForm(
		"Catalog.AccountingCheckRules.ListForm",
		,
		ThisObject,
		UUID,
		,
		,
		CloseHandler);
	
EndProcedure

&AtClient
Procedure SetUpLockFromChanges(Command)

	CloseHandler = New CallbackDescription("ClosingHyperlinkFormAction", ThisObject);
	
	OpenForm(
		"InformationRegister.SetUpLockFromChanges.Form.FormSettings",
		,
		ThisObject,
		UUID,
		,
		,
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckClosedPeriod(Command)
	
	GenerateOperationsForClosedPeriod = Not GenerateOperationsForClosedPeriod;
	Items.CheckClosedPeriodButton.Check = GenerateOperationsForClosedPeriod;
	
	UpdateFormDataInBackgroundOnClient();
	
EndProcedure

&AtClient
Procedure ReconciliationOfOperationalAccountingBalancesAndCostOfProductionReport(Command)
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Period", EndOfMonth(Object.RegistrationPeriod));
	
	If ValueIsFilled(SharedArrayOfCompanies) Then
		ReportParameters.Insert("Organization", SharedArrayOfCompanies);
	EndIf;
	
	FormParameters = New Structure("Filter, GenerateOnOpen", ReportParameters, True);
	
	OpenForm(
		"Report.ReconciliationOfOperationalAccountingAndCost.ObjectForm",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure UpdateForm(Command)
	
	UpdateFormDataInBackgroundOnClient(, True);
	
EndProcedure

&AtClient
Procedure CalculateEverything(Command)
	
	ClearMessages();
	
	If StartCalculationExecution() Then
		Notify("UpdatingResultsOfInspectionsInFormOfClosingMonth");
		SetStatusImagesForLongTermOperation(False);
		CheckActivityOfBackgroundCalculationTask();
		NotifyStartOfCalculation();
	EndIf;
	
EndProcedure

&AtClient
Procedure StopCalculationInTheBackground(Command)
	
	CloseHandler = New CallbackDescription("AnswerToQuestionOfStoppingCalculation", ThisObject);
	
	ShowQueryBox(
		CloseHandler,
		NStr("vi = 'Ngắt thực hiện kết chuyển cuối tháng';
			|ru = 'Прервать выполнение закрытия месяца';
			|en = 'Terminate the month-end closing'; fa = 'Terminate the month-end closing';
			|it = 'Прервать выполнение закрытия месяца';
			|pl = 'Terminate the month-end closing';
			|tr = 'Ay sonu kapanışı durdur'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetUpAutomaticMonthClosing(Command)
	
	OpenForm(
		"InformationRegister.ScheduledJobsOfMonthEndClosing.Form.Form",
		New Structure("Organization", MonthEndTransactionsClientLocalization.OrganizationFromFixedArray(SharedArrayOfCompanies)),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenTasksByTheEndOfTheMonth(Command)
	
	OpenForm(
		"InformationRegister.JobsForMonthEndClosing.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	
EndProcedure

&AtClient
Procedure OpenJobsForCalculatingCost(Command)
	
	OpenForm(
		"InformationRegister.JobsForCalculatingCost.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	
EndProcedure

&AtClient
Procedure OpenJobsForAllocatingSettlementsWithCustomers(Command)
	
	OpenForm(
		"InformationRegister.JobsForAllocatingCustomersARAP.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	
EndProcedure

&AtClient
Procedure OpenJobsForAllocatingSettlementsWithSuppliers(Command)
	
	OpenForm(
		"InformationRegister.JobsForAllocatingVendorsARAP.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	
EndProcedure

&AtClient
Procedure OpenJobsToCalculateFADepreciation(Command)
	OpenForm(
		"InformationRegister.JobsForCalculatingFixedAssetDepreciation.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OpenJobsToCalculateIADepreciation(Command)
	OpenForm(
		"InformationRegister.JobsForCalculatingIntangibleAssetAmortization.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OpenTasksForCalculatingTheCostOfVNA(Command)
	OpenForm(
		"InformationRegister.JobsForCalculatingNonCurrentAssetCost.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OpenTasksForUpdatingRegisteredRecordsOfNCA(Command)
	OpenForm(
		"InformationRegister.JobsForUpdatingFixedAssetRecords.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OpenTasksForTheFormationOfRegisteredRecordsOnTheVNA(Command)
	OpenForm(
		"InformationRegister.JobsForGeneratingFixedAssetRecords.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OpenJobsForGeneratingVATRegisteredRecords(Command)
	
	OpenForm(
		"InformationRegister.JobsForGeneratingVATRecords.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
	
EndProcedure

&AtClient
Procedure OpenEventLog(Command)
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	
	LogFormParameters = New Structure("StartDate, Level", Object.RegistrationPeriod, FilterByLevel);
	
	OpenForm(
		"DataProcessor.EventLog.Form.EventLog",
		LogFormParameters);
	
EndProcedure

&AtClient
Procedure OpenBatchAndCostCalculationProtocols(Command)
	
	RegisterSelectionParameters = New Structure("CalculationPeriod", Object.RegistrationPeriod);
	RegisterFormParameters  = New Structure("Filter", RegisterSelectionParameters);
	
	OpenForm(
		"InformationRegister.LotAndCostCalculationProtocols.Form.ListForm",
		RegisterFormParameters);
	
EndProcedure

&AtClient
Procedure ActiveMonthlyClosingSessions(Command)
	
	OpenForm(
		"DataProcessor.MonthEndClosingOperations.Form.ActiveSessionsOfMonthEndClosing",
		,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure ConfigureTechnologicalParameters(Command)
	
	CloseHandler = New CallbackDescription("ClosingHyperlinkFormAction", ThisObject);
	
	OpenForm(
		"DataProcessor.MonthEndClosingOperations.Form.OperationParameters",
		,
		ThisObject,
		UUID,
		,
		,
		CloseHandler);
	
EndProcedure

&AtClient
Procedure ViewTaskPeriods(Command)

	TabDoc = TabularDocumentOfTasks();
	TabDoc.Show(NStr("vi = 'Kỳ nhiệm vụ cần tính toán giao dịch kết chuyển cuối tháng';
					|ru = 'Периоды заданий к расчету операций закрытия месяца';
					|en = 'Job periods to calculate month-end closing operations'; fa = 'Job periods to calculate month-end closing operations';
					|it = 'Периоды заданий к расчету операций закрытия месяца';
					|pl = 'Job periods to calculate month-end closing operations';
					|tr = 'Ay sonu kapanış hesaplamak için görev dönemleri'"));
	
EndProcedure

&AtClient
Procedure OpenTypesOfNonOperationalTasks(Command)
	
	OpenForm(
		"Catalog.BackdateJobKinds.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));

EndProcedure

&AtClient
Procedure OpenTasksForNonOperationalDocumentVerification(Command)
	
	OpenForm(
		"InformationRegister.JobsOfBackdateAdditionalDocumentPosting.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
		
EndProcedure

&AtClient
Procedure OpenTasksForDistributionOfMutualSettlements(Command)
	
	OpenForm(
		"InformationRegister.JobsForARAPAllocating.ListForm",
		MonthEndTransactionsClientLocalization.TaskRegisterFormParameters(ThisObject));
		
EndProcedure

&AtClient
Procedure OpenFormMonthEndClosing24(Command)
	
	UpdateMainFormServer();
	Close();
	OpenForm("DataProcessor.MonthEndClosingOperations.Form",,,,,,,FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region Private

#Region FormControl

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Groups of manual operations
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeDescription.Name);
	
	FilterGroup = AddSelectionGroupForRegistration(AppearanceItem);
	
	AddSelectionForRegistration(FilterGroup, "StageTree.IsFolder", True);
	AddSelectionForRegistration(FilterGroup, "StageTree.Highlight", True);
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Crimson);
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.StageTreeDescription.Font,, 12));
	
	// Groups of automatic operations
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeDescription.Name);
	
	FilterGroup = AddSelectionGroupForRegistration(AppearanceItem);
	
	AddSelectionForRegistration(FilterGroup, "StageTree.IsFolder", True);
	AddSelectionForRegistration(FilterGroup, "StageTree.Highlight", False);
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.StageTreeDescription.Font,, 12));
	
	// The current counting stage
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeDescription.Name);
	
	FilterGroup = AddSelectionGroupForRegistration(AppearanceItem);
	
	AddSelectionForRegistration(FilterGroup, "StageTree.ThisIsAStep", True);
	AddSelectionForRegistration(FilterGroup, "StageTree.Code", New DataCompositionField("CurrentCalculatedStage"));
	
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.StageTreeDescription.Font,,, True));
	
	// The "Execute" text of the inactive stage
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeTextExecute.Name);
	
	AddSelectionForRegistration(AppearanceItem.Filter, "StageTree.State", Enums.StatesOfMonthEndClosingOperations.NotRequired);
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không cần';
															|ru = 'Не требуется';
															|en = 'Not required'; fa = 'لازم نیست';
															|it = 'Non richiesta';
															|pl = 'Nie jest wymagane';
															|tr = 'Gerekli değil'"));
	
	// The "More Details" text of the inactive stage
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeReadMoreText.Name);
	
	AddSelectionForRegistration(AppearanceItem.Filter, "StageTree.State", Enums.StatesOfMonthEndClosingOperations.NotRequired);
	
	AppearanceItem.Appearance.SetParameterValue("Text", "");
	
	// Hyperlink "Execute"
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	ExtendedTooltip = Items.TheTreeStagesTheHyperlinkToCompleteExtendedTooltip; // FormDecoration
	
	AddFieldForAppearance(AppearanceItem, Items.TheTreeStagesTheHyperlinkToComplete.Name);
	AddFieldForAppearance(AppearanceItem, ExtendedTooltip.Name);
	
	AddSelectionForRegistration(AppearanceItem.Filter, "StageTree.HyperlinkExecute", False);
	
	AppearanceItem.Appearance.SetParameterValue("Visible",  False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	// The text "Execute"
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	ExtendedTooltip = Items.StageTreeTextExecuteExtendedTooltip; // FormDecoration
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeTextExecute.Name);
	AddFieldForAppearance(AppearanceItem, ExtendedTooltip.Name);
	
	AddSelectionForRegistration(AppearanceItem.Filter, "StageTree.HyperlinkExecute", True);
	
	AppearanceItem.Appearance.SetParameterValue("Visible",  False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	// Hyperlink "More details"
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	ExtendedTooltip = Items.StageTreeHyperlinkMoreInformationExtendedTooltip; // FormDecoration
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeHyperlinkMoreInformation.Name);
	AddFieldForAppearance(AppearanceItem, ExtendedTooltip.Name);
	
	AddSelectionForRegistration(AppearanceItem.Filter, "StageTree.HyperlinkReadMore", False);
	
	AppearanceItem.Appearance.SetParameterValue("Visible",  False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	// The text "More details"
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	ExtendedTooltip = Items.StageTreeReadMoreTextExtendedTooltip; // FormDecoration
	
	AddFieldForAppearance(AppearanceItem, Items.StageTreeReadMoreText.Name);
	AddFieldForAppearance(AppearanceItem, ExtendedTooltip.Name);
	
	AddSelectionForRegistration(AppearanceItem.Filter, "StageTree.HyperlinkReadMore", True);
	
	AppearanceItem.Appearance.SetParameterValue("Visible",  False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
EndProcedure

&AtServer
Function AddFieldForAppearance(AppearanceItem, FieldName)
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldName);
	
	Return ItemField;
	
EndFunction

&AtServer
Function AddSelectionGroupForRegistration(AppearanceItem)
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Return FilterGroup;
	
EndFunction

&AtServer
Function AddSelectionForRegistration(FilterGroup, FilterFieldName, FilterValue)
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(FilterFieldName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = FilterValue;
	
	Return ItemFilter;
	
EndFunction

&AtServer
Procedure ConfigureElementsDuringFormInitialization(LoadingSettings = False)
	
	RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationPeriod);
	
	CreatePresentationOfOrganizations();
	
	If Not LoadingSettings Then
		
		// Configure the display of command panel elements.
		Items.TheConfigureButtonCheck.Visible =
			AccessRight("Update", Metadata.Catalogs.AccountingCheckRules);
			
		BatchAccountingWasIncluded = CalculationOfCostCached.BatchAccountingWasUsedBeforeSwitchingToVersion22(Date(1,1,1));
		Items.FormReconciliationOfOperationalAccountingBalancesAndCostOfProductionReport.Visible =
		    ?(BatchAccountingWasIncluded = Undefined, False, BatchAccountingWasIncluded)
			And AccessRight("View", Metadata.Reports.ReconciliationOfOperationalAccountingAndCost);
			
		// Configure the visibility of commands for opening task registers.
		Items.FormOpenTasksByTheEndOfTheMonth.Visible =
			AccessRight("View", Metadata.InformationRegisters.JobsForMonthEndClosing);
		Items.FormOpenJobsForCalculatingCost.Visible =
			AccessRight("View", Metadata.InformationRegisters.JobsForCalculatingCost);
		Items.FormOpenJobsForAllocatingSettlementsWithCustomers.Visible =
			AccessRight("View", Metadata.InformationRegisters.JobsForAllocatingCustomersARAP);
		Items.FormOpenJobsForAllocatingSettlementsWithSuppliers.Visible =
			AccessRight("View", Metadata.InformationRegisters.JobsForAllocatingVendorsARAP);

		Items.FormOpenJobsToCalculateFADepreciation.Visible =
		    False // in UT11
			Or AccessRight("View", Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation)
			Or False; // to comply with the standard for the transfer of expressions
		Items.FormOpenJobsToCalculateIADepreciation.Visible =
		    False // in UT11
			Or AccessRight("View", Metadata.InformationRegisters.JobsForCalculatingIntangibleAssetAmortization)
			Or False; // to comply with the standard for the transfer of expressions
		Items.FormOpenTasksForCalculatingTheCostOfVNA.Visible =
		    False // in UT11
			Or AccessRight("View", Metadata.InformationRegisters.JobsForCalculatingNonCurrentAssetCost)
				And GetFunctionalOption("UseNonCurrentAssets2_4")
			Or False; // to comply with the standard for the transfer of expressions
			
		Items.FormOpenTasksForUpdatingRegisteredRecordsOfNCA.Visible =
		    False // in UT11
			Or AccessRight("View", Metadata.InformationRegisters.JobsForUpdatingFixedAssetRecords)
				And GetFunctionalOption("UseNonCurrentAssets2_4")
			Or False; // to comply with the standard for the transfer of expressions
			
		Items.FormOpenTasksForTheFormationOfRegisteredRecordsOnTheVNA.Visible =
		    False // in UT11
			Or AccessRight("View", Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords)
				And GetFunctionalOption("UseNonCurrentAssets2_4")
			Or False; // to comply with the standard for the transfer of expressions
		
		Items.FormOpenJobsForGeneratingVATRegisteredRecords.Visible =
			AccessRight("View", Metadata.InformationRegisters.JobsForGeneratingVATRecords);
		
		Items.FormOpenEventLog.Visible =
			AccessRight("View", Metadata.DataProcessors.EventLog);
		
		Items.FormOpenBatchAndCostCalculationProtocols.Visible =
			AccessRight("View", Metadata.InformationRegisters.LotAndCostCalculationProtocols);
		
		Items.ButtonSettingProcessParameters.Visible =
			Users.IsFullUser();
		
		Items.FormActiveMonthlyClosingSessions.Visible =
			AccessRight("View", Metadata.InformationRegisters.PerformMonthEndClosingOperations);
		
		Items.FormOpenTypesOfNonOperationalTasks.Visible = AccessRight("View",
			Metadata.Catalogs.BackdateJobKinds);
		Items.FormOpenTasksForNonOperationalDocumentVerification.Visible = AccessRight("View",
			Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting);
		Items.FormOpenTasksForDistributionOfMutualSettlements.Visible = AccessRight("View",
			Metadata.InformationRegisters.JobsForARAPAllocating);
		Items.NonOperationalTaskQueueGroup.Visible = Items.FormOpenTypesOfNonOperationalTasks.Visible
			Or Items.FormOpenTasksForNonOperationalDocumentVerification.Visible
			Or Items.NonOperationalTaskQueueGroup.Visible;
		
		// We will configure the form depending on the presence of active background tasks.
		CustomizeItemsBasedOnBackgroundJobs();
		
	EndIf;
	
	// Let's configure the marks of the command panel elements.
	AdjustMarkOfSettingsButtons(Object, Items);
	MonthEndTransactionsLocalization.ConfigureElementsDuringFormInitialization(ThisObject, LoadingSettings);
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustMarkOfSettingsButtons(Object, Items)
	
	Items.ButtonToHideTheStepsWithAStatusOfNotRequired.Check 	    = Object.HideStepsWithNotRequireStatus;
	Items.ButtonHideStagesWithTheStatusCompletedSuccessfully.Check  = Object.HideStepsCompletedSuccessfully;
	Items.ButtonToHideTheExplanationOfTheStages.Check 		  	    = Object.HideExplanationsToSteps;
	Items.AutoUpdateButtonWhenClosingSubordinateForms.Check = Object.AutoUpdateWhenClosingSubordinateForms;
	
EndProcedure

&AtServer
Procedure CustomizeItemsBasedOnBackgroundJobs()
	
	If Not CalculationState.CalculationIsCompleted Then
		
		CalculationIsUnderway = True;
		UpdateIsUnderway = False;
		CancelBackgroundJob(IDOfStageStateUpdateJob, False);
		
	Else
		
		CalculationIsUnderway = False;
		JobState = CurStateOfBackgroundJob(IDOfStageStateUpdateJob);
		UpdateIsUnderway = JobState.Active;
		
		If UpdateIsUnderway Then
			RepresentationOfTheCalculatedStage =
				New FormattedString(TrimAll(JobState.Description) + ": ");
				
		EndIf;
		
	EndIf;
	
	Items.DecorationBagel.Visible 							  = CalculationIsUnderway Or UpdateIsUnderway;
	Items.GroupPeriodAndOrganization.Enabled 	  			  = Not CalculationIsUnderway;
	Items.CalculatedCompanies.Enabled 	  			  = Not CalculationIsUnderway;
	Items.GroupCalculationStatus.Enabled 	  				  = Not CalculationIsUnderway And Not UpdateIsUnderway;
	Items.TheGroupCancelsTheCalculationInTheBackground.Visible 	  			  = CalculationIsUnderway;
	Items.GroupPerformingCalculationInTheBackground.Visible   			  = True;
	
	Items.StopCalculationInTheBackground.Enabled   				  = Not CancelCalculation;
	Items.TheRunButtonClosing.Enabled 	  			  = Not CalculationIsUnderway And Not UpdateIsUnderway And Not ChangesAreDisabled;
	Items.ButtonToUpdateTheForm.Enabled 		  			  = Not CalculationIsUnderway And Not UpdateIsUnderway;
	Items.GroupOfButtonsConfiguringTheDisplayOfRows.Enabled 	  = Not CalculationIsUnderway And Not UpdateIsUnderway;
	Items.TheTreeGroupStages.Enabled 				   	  = Not UpdateIsUnderway Or BackgroundStateUpdate;
	Items.FormViewTaskPeriods.Enabled			  = Not CalculationIsUnderway And Not UpdateIsUnderway;
	
	Items.TheTreeStagesTheHyperlinkToComplete.Enabled		  = Not CalculationIsUnderway 
		And (Not UpdateIsUnderway Or BackgroundStateUpdate) And Not ChangesAreDisabled;
	Items.StageTreeHyperlinkMoreInformation.Enabled		  = (Not UpdateIsUnderway Or BackgroundStateUpdate);
	
	Items.StageTree.Visible 							  = Not IsPeriodLocked Or GenerateOperationsForClosedPeriod;
	Items.InscriptionPeriodIsBlocked.Visible 				  = IsPeriodLocked And Not GenerateOperationsForClosedPeriod;
	Items.CheckClosedPeriodButton.Visible			  = IsPeriodLocked;
	
	Items.ConfigureChangeBlockingButton.Visible		  =
		InformationRegisters.SetUpLockFromChanges.UseMechanismToBlockChanges()
		And MonthEndTransactionsServer.YouHaveRightToManageBlockingOfPeriod();
	Items.ConfigureChangeBlockingButton.Enabled	  = Not CalculationIsUnderway
		And (Not UpdateIsUnderway Or BackgroundStateUpdate);
	
	If UpdateIsUnderway Then
		Items.CalculatedCompanies.ToolTipRepresentation = ToolTipRepresentation.None;
	EndIf;
	
	SetAvailabilityOfMonthClosingMode();
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.PreliminaryMonthEndClosingDate.Visible = (Object.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing);
	Items.RegistrationPeriodPresentation.Visible = (Object.MonthEndClosingMode <> Enums.MonthEndClosingModes.PreliminaryClosing);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfMonthClosingMode()
	
	BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22(Object.RegistrationPeriod);
	Items.MonthEndClosingMode.Enabled = BatchAccountingVersion22; 
	
EndProcedure

&AtClient
Procedure UpdateFormDataInBackgroundOnClient(CreateDescriptionOfOrganizations = True, UpdateCacheOfStatusesOfOperations = True)
	
	DetachIdleHandler("CheckActivityOfBackgroundFormUpdateJob");
	
	StartUpdatingFormDataInBackground(CreateDescriptionOfOrganizations, UpdateCacheOfStatusesOfOperations);
	
	If BackgroundTaskForCreatingList <> Undefined Then
		
		NotificationAboutProgress = New CallbackDescription(
			"UpdateProgressOfFormationOfStages", ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.ExecutionProgressNotification = NotificationAboutProgress;
		 
		CompletionNotification1 = New CallbackDescription("UpdateFormDataInBackgroundOnClientCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundTaskForCreatingList, CompletionNotification1, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFormDataInBackgroundOnClientCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		FillFormWithUpdatedDataOnClient(True);
	ElsIf Result.Status = "Error" Then
		
		DataDate = DateWhenTheDataIsUpToDate();
		DisplayDateOfStateOfStages(DataDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateProgressOfFormationOfStages(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And Result.Status = "Running"
		And Result.Progress <> Undefined Then
			
			Progress = Result.Progress; // See TimeConsumingOperationsClient.LongRunningOperationNewState
			AdditionalParameters = Progress.AdditionalParameters; // See TimeConsumingOperations.ReportProgress.AdditionalParameters
			
			If AdditionalParameters.UpdateCacheOfStatusesOfOperations Then
				
				Status = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trạng thái giao dịch kết chuyển cuối tháng được cập nhật vào %1. Đang cập nhật %2%.';
						|ru = 'Статус операций закрытия месяца актуален на %1. Идет обновление %2%.';
						|en = 'The month-end closing operation status is relevant as of %1. Updating %2%.'; fa = 'The month-end closing operation status is relevant as of %1. Updating %2%.';
						|it = 'The month-end closing operation status is relevant as of %1. Updating %2%.';
						|pl = 'The month-end closing operation status is relevant as of %1. Updating %2%.';
						|tr = 'Ay sonu kapanış işlemlerinin durumu %1 itibarıyla günceldir. Güncelleme devam ediyor %2%.'"),
					Format(AdditionalParameters.DateWhenTheDataIsUpToDate, "DLF=DDT"),
					Progress.Percent);
					
				RepresentationOfTheCalculatedStage = StringFunctionsClient.FormattedString(
					Status);
			Else
				RepresentationOfTheCalculatedStage = New FormattedString(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tạo danh sách giao dịch kết chuyển cuối tháng %1: %2';
							|ru = 'Формирование списка операций закрытия месяца %1: %2';
							|en = 'Generating %1 month-end closing operation list: %2'; fa = 'Generating %1 month-end closing operation list: %2';
							|it = 'Generating %1 month-end closing operation list: %2';
							|pl = 'Generating %1 month-end closing operation list: %2';
							|tr = '%1 ay sonu kapanış işlemleri listesi oluşturuluyor: %2'"),
						MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationPeriod),
						String(Progress.Percent) + "%"));
			EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function StartUpdatingFormDataInBackground(CreateDescriptionOfOrganizations = True, UpdateCacheOfStatusesOfOperations = True)
	
	// Cancel the old state update task if it is still active.
	CancelBackgroundJob(IDOfStageStateUpdateJob);
	
	// We will prepare auxiliary data to start updating the states of the stages.
	StorageAddressForStageStateUpdateJob = PutToTempStorage(Undefined, UUID);
	
	Period = ?(Object.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing,
		Object.PreliminaryMonthEndClosingDate,
		Object.RegistrationPeriod);
	StructureOfData = DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState(
		Period,
		New Array(Object.CompanyArray),
		GetDataWarehouse(),
		Object.MonthEndClosingMode);
		
	CalculationParameters = StructureOfData.CalculationParameters; // save it in the form data
	
	ParametersForTriggeringStateUpdates = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(
		StructureOfData,
		StorageAddressForStageStateUpdateJob,
		,
		WorkMode.AvailabilityOfAccountingTypes);
	
	ParametersForTriggeringStateUpdates.CheckBanDate_ 			  = True;
	ParametersForTriggeringStateUpdates.CleanUnusedJobEntries= True;
	ParametersForTriggeringStateUpdates.UpdateScheduledTaskCaches  = True;
	ParametersForTriggeringStateUpdates.UpdateListOfChecks  		  = Not OperationsAreExecutedOnOpening;
	ParametersForTriggeringStateUpdates.CheckCompletionOfCalculations_		  = Not OperationsAreExecutedOnOpening;
	ParametersForTriggeringStateUpdates.PerformChecksBeforeStage 		  = True;
	ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations	  = CreateDescriptionOfOrganizations;
	ParametersForTriggeringStateUpdates.PreliminaryClosingOfMonthIsPerformed = 
		?(Object.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing, True, False);
	ParametersForTriggeringStateUpdates.GenerateOperationsForClosedPeriod = GenerateOperationsForClosedPeriod;
	ParametersForTriggeringStateUpdates.UpdateCacheOfStatusesOfOperations = UpdateCacheOfStatusesOfOperations;
	
	BackgroundStateUpdate = UpdateCacheOfStatusesOfOperations;
	
	// Let's start updating the states.
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tạo danh sách giao dịch kết chuyển cuối tháng %1';
			|ru = 'Формирование списка операций закрытия месяца %1';
			|en = 'Generating %1 month-end closing operation list'; fa = 'Generating %1 month-end closing operation list';
			|it = 'Generazione dell''elenco delle operazioni di chiusura del mese %1';
			|pl = 'Tworzenie listy operacji zamknięcia miesiąca %1';
			|tr = '%1 ay sonu kapanış işlemleri listesi oluşturuluyor'"),
		CostCalculationProtocol.PresentationOfCalculationPeriod(Object.RegistrationPeriod));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 1;
	
	BackgroundTaskForCreatingList = TimeConsumingOperations.ExecuteInBackground(
		"MonthEndTransactionsServer.FillInStatesOfStagesInBackgroundJob",
		ParametersForTriggeringStateUpdates,
		ExecutionParameters);

	IDOfStageStateUpdateJob = BackgroundTaskForCreatingList.JobID;
	
	// Let's configure the form elements.
	CustomizeItemsBasedOnBackgroundJobs();
	
	SetParametersForRoutineTaskOfNonOperationalQueue();
	
	Return True;
	
EndFunction

&AtClient
Procedure CheckActivityOfBackgroundFormUpdateJob()
	
	If BackgroundTaskIsActive(IDOfStageStateUpdateJob) Then
		AttachIdleHandler("CheckActivityOfBackgroundFormUpdateJob", IntervalForCheckingBackgroundJobs(), True);
		Return;
	EndIf;
	
	FillFormWithUpdatedDataOnClient(True);
	
EndProcedure

&AtClient
Procedure FillFormWithUpdatedDataOnClient(GetDataFromBackgroundJob = False)
	
	Result = FillFormWithUpdatedDataOnServer(GetDataFromBackgroundJob);
	
	ErrorText =  Result.ErrorText;
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	// Let's open all the levels of the tree.
	If Not IsPeriodLocked Or GenerateOperationsForClosedPeriod Then
		For Each CurrentRow In StageTree.GetItems() Do
			Items.StageTree.Expand(CurrentRow.GetID(), False);
		EndDo;
	EndIf;
	
	OperationsAreExecutedOnOpening = True; // we update the list of checks once, when opening the form
	
	If Result.RestartIsRequired Then
		UpdateFormDataInBackgroundOnClient(,True);
	EndIf;
	
	Notify("UpdatingResultsOfInspectionsInFormOfClosingMonth");
	
EndProcedure

&AtServer
Function FillFormWithUpdatedDataOnServer(GetDataFromBackgroundJob = False)
	
	CommonSettlementStartDate = Object.RegistrationPeriod;
	SharedArrayOfCompanies = New FixedArray(New Array);
	
	// To get the data, see Fill in the Stepstates () in the processing manager module.
	If GetDataFromBackgroundJob Then
		StructureOfData = GetFromTempStorage(StorageAddressForStageStateUpdateJob);
	Else
		StructureOfData = GetDataWarehouse();
	EndIf;
	
	Result = New Structure("ErrorText, RestartIsRequired", "", False);
	Result.RestartIsRequired = False;
	
	StageTree.GetItems().Clear();
	
	If TypeOf(StructureOfData) = Type("Structure") Then // background task completed successfully
		Result.RestartIsRequired = StructureOfData.Property("StatesOfStagesFromCache_");
		
		OutputWarning =
			AdditionalCompanies = Undefined
			Or Not TMCommonUseClientServer.ArraysAreEqual(
					AdditionalCompanies,
					StructureOfData.CalculationParameters.AdditionalCompanies,
					False);
		
		CalculationParameters 		  = StructureOfData.CalculationParameters; // save it in the form data
		CompanyDescription 	  = StructureOfData.CompanyDescription;
		SharedArrayOfCompanies 	  = New FixedArray(StructureOfData.CalculationParameters.CompanyArray);
		AdditionalCompanies = New FixedArray(StructureOfData.CalculationParameters.AdditionalCompanies);
		DescriptionOfOrganizationsFormed = True;
		
		CreatePresentationOfOrganizations(SharedArrayOfCompanies);
		
		If OutputWarning And ValueIsFilled(AdditionalCompanies) Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Danh sách doanh nghiệp đã chọn để hạch toán, đã thêm bởi các doanh nghiệp liên quan:
					|%1';
					|ru = 'Список организаций, выбранных для расчета, дополнен связанными организациями:
					|%1';
					|en = 'List of companies selected for calculation is supplemented with related companies:
					|%1'; fa = 'List of companies selected for calculation is supplemented with related companies:
					|%1';
					|it = 'L''elenco delle società selezionate per il calcolo è integrato dalle società correlate:
					|%1';
					|pl = 'Lista firm, wybranych dla rozliczenia, została uzupełniona powiązanymi firmami:
					|%1';
					|tr = 'Hesaplama için seçilen iş yerlerinin listesi, ilgili iş yerleri ile desteklenmiştir:
					|%1'"), 
				CostCalculationAppliedAlgorithms.CalculatedCompanies(AdditionalCompanies, ", "));
			
			Common.MessageToUser(MessageText);
			
		EndIf;
		
		// Let's fill the tree with groups of stages.
		AddTreeRowsFromTable(
			StructureOfData.StageGroupTable,
			StructureOfData.StageGroupTable,
			"IsFolder");
		
		// Let's fill the tree with stages.
		AddTreeRowsFromTable(
			StructureOfData.TableStages,
			StructureOfData.StageGroupTable,
			"ThisIsAStep");
		
		// Let's fill the tree with explanations for the stages.
		AddTreeRowsFromTable(
			StructureOfData.TableOfGroupedExplanations,
			StructureOfData.TableStages,
			"ThisIsAnExplanation");
		
		// Fill in the information about the closing of the month as a whole, by period and organization.
		If Not GetDataFromBackgroundJob Then
			DataProcessors.MonthEndClosingOperations.FillInStageGroupProperties(StructureOfData);
		EndIf;
		
		MonthClosedSuccessfully 		    = StructureOfData.MonthClosedSuccessfully;
		StepsForRecount 		    = StructureOfData.StepsForRecount;
		CalculatedSteps 		    = StructureOfData.CalculatedSteps;
		ChangesAreDisabled 		    = StructureOfData.ChangesAreDisabled;
		ExplanationsToChangeClosing  = StructureOfData.ExplanationsToChangeClosing;
		ExplanationToChangeProhibition = StructureOfData.ExplanationToChangeProhibition;
		CommonSettlementStartDate 		= StructureOfData.SettlementStartDate;
		IsPeriodLocked 		    = StructureOfData.IsPeriodLocked;
		PeriodIsPartiallyBlocked  = StructureOfData.PeriodIsPartiallyBlocked;
		BlockedBusinesses  = New FixedArray(StructureOfData.BlockedBusinesses);
		DecryptionOfLock 		= StructureOfData.DecryptionOfLock;
		DecryptionOfTasks 			= StructureOfData.DecryptionOfTasks;
		
		If Result.RestartIsRequired Then

			RepresentationOfTheCalculatedStage = StringFunctions.FormattedString(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trạng thái giao dịch kết chuyển cuối tháng đã cập nhật vào %1. Đang cập nhật 1%.';
						|ru = 'Статус операций закрытия месяца актуален на %1. Идет обновление 1%.';
						|en = 'The month-end closing operation status is relevant as of %1. Updating 1%.'; fa = 'The month-end closing operation status is relevant as of %1. Updating 1%.';
						|it = 'The month-end closing operation status is relevant as of %1. Updating 1%.';
						|pl = 'The month-end closing operation status is relevant as of %1. Updating 1%.';
						|tr = 'Ay sonu kapanış işlemlerinin durumu %1 itibarıyla günceldir. Güncelleme devam ediyor 1%.'"),
					Format(StructureOfData.DateWhenTheDataIsUpToDate, "DLF=DDT")));
			
		Else

			RepresentationOfTheCalculatedStage = StringFunctions.FormattedString(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trạng thái giao dịch kết chuyển cuối tháng đã cập nhật vào %1.';
						|ru = 'Статус операций закрытия месяца актуален на %1.';
						|en = 'The month-end closing operation status is relevant as of %1.'; fa = 'The month-end closing operation status is relevant as of %1.';
						|it = 'The month-end closing operation status is relevant as of %1.';
						|pl = 'The month-end closing operation status is relevant as of %1.';
						|tr = 'Ay sonu kapanış işlemlerinin durumu %1 itibarıyla günceldir.'"),
						Format(CurrentSessionDate(), "DLF=DDT")));
			
		EndIf;
		
		// Let's update the form header.
		FillInClosingStateOfMonth();
		
	EndIf;
	
	If GetDataFromBackgroundJob Then
		
		// We will configure the form type depending on the presence of active background tasks.
		CustomizeItemsBasedOnBackgroundJobs();
		
	EndIf;
	
	If TypeOf(StructureOfData) <> Type("Structure") Then
		
		// We will return the error text for output in the form.
		MonthClosedSuccessfully  = Undefined;
		CompanyDescription = DataProcessors.MonthEndClosingOperations.DescriptionOfOrganizationsToCalculate(Object.RegistrationPeriod, True);
		DescriptionOfOrganizationsFormed = False;
		
		JobState = CurStateOfBackgroundJob(IDOfStageStateUpdateJob);
		
		If ValueIsFilled(JobState.ErrorText) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi tạo danh sách giao dịch kết chuyển cuối tháng, đã xảy ra lỗi:
					|%1.';
					|ru = 'При формировании списка операций закрытия месяца возникла ошибка:
					|%1.';
					|en = 'An error occurred when generating the list of month-end closing operations:
					|%1.'; fa = 'An error occurred when generating the list of month-end closing operations:
					|%1.';
					|it = 'Nel corso di generazione dell''elenco delle operazioni di chiusura del mese si è verificato un errore:
					|%1.';
					|pl = 'Przy tworzeniu listy operacji zamknięcia miesiąca wystąpił błąd:
					|%1.';
					|tr = 'Ay sonu kapanış işlemleri listesi oluşturulurken bir hata oluştu:
					|%1'"),
				JobState.ErrorText);
			
		Else
			
			Explanation = "";
			If JobState.Canceled Then
				Explanation = NStr("vi = 'bị hủy bởi người quản trị';
									|ru = 'отменено администратором';
									|en = 'canceled by administrator'; fa = 'canceled by administrator';
									|it = 'annullato dall''amministratore';
									|pl = 'anulowane przez administratora';
									|tr = 'yönetici tarafından iptal edildi'");
			ElsIf JobState.Failed Then
				Explanation = NStr("vi = 'đã kết thúc bất thường';
									|ru = 'завершено аварийно';
									|en = 'aborted'; fa = 'aborted';
									|it = 'terminato in modo anomalo';
									|pl = 'zakończone awaryjnie';
									|tr = 'arızalı tamamlandı'");
			EndIf;
			
			If ValueIsFilled(Explanation) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi tạo danh sách giao dịch kết chuyển cuối tháng đã xảy ra lỗi:
						|nhiệm vụ nền %1.';
						|ru = 'При формировании списка операций закрытия месяца возникла ошибка:
						|фоновое задание %1.';
						|en = 'An error occurred when generating the list of month-end closing operations:
						|background job%1.'; fa = 'An error occurred when generating the list of month-end closing operations:
						|background job%1.';
						|it = 'Nel corso di generazione dell''elenco delle operazioni di chiusura del mese si è verificato un errore: 
						| task in background %1.';
						|pl = 'Przy tworzeniu listy operacji zamknięcia miesiąca wystąpił błąd:
						|zadanie w tle %1.';
						|tr = 'Ay sonu işlemlerinin listesi oluşturulurken bir hata oluştu:
						|arka plan işi %1.'"), Explanation);
			EndIf;
			
		EndIf;
		
		Result.ErrorText = ErrorText;
		Return Result;
		
	EndIf;
	
	StructureOfData.Delete("StatesOfStagesFromCache_");
	
	DataStorage = New ValueStorage(StructureOfData, New Deflation(9));
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInIntermediateExplanationsOfStageOnServer()
	
	StructureOfData = GetDataWarehouse();
	FillInIntermediateExplanationsOfStage(CurrentCalculatedStage, StructureOfData, True);
	
EndProcedure

&AtServer
Procedure FillInIntermediateExplanationsOfStage(CalculatedStage, StructureOfData, CalculationIsInProgress = False)
	
	// At the beginning of the calculation of the stage and in the process of performing the calculation of the stage, it adds the found problems to the month closing form
	StageTableRow = StructureOfData.TableStages.Find(CalculatedStage, "Code");
	IdOfStageLine = StructureOfData.TableStages.Find(CalculatedStage, "Code").RowID;
	
	If IdOfStageLine < 0 Then
		Return;
	EndIf;
	
	StageString_ = StageTree.FindByID(IdOfStageLine);
	
	If StageString_ = Undefined Then
		Return;
	EndIf;
	
	StageString_.GetItems().Clear();
	
	CalculationStartParameters = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersForCalculatingStages(
		StructureOfData,
		StageTableRow.Code,
		CalculationState.StepsToCalculation[CalculationState.NumberOfStages - 1],
		Object.MonthEndClosingMode,
		StorageAddressForStageCalculationJob,
		WorkMode.AvailabilityOfAccountingTypes,
		CalculationID);
		
	ParametersForTriggeringStateUpdates = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(
		StructureOfData,
		,
		StageTableRow.Code,
		CalculationStartParameters);
	
	ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations = False;
	
	HandlerParameters = DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters(
		StructureOfData,
		StageTableRow,
		ParametersForTriggeringStateUpdates,
		"MonthEndTransactions.StateUpdate."
			+ Catalogs.MonthEndClosingOperations.GetPredefinedItemName(StageTableRow.Code));
 
	SelectingWhenToRunCheck = New Array;
	SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation);
	SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation);
	If CalculationIsInProgress Then
		SelectingWhenToRunCheck.Add(Enums.TimeOfStartingMonthEndClosingOperationCheck.DuringCalculation);
	EndIf;
	
	DataProcessors.MonthEndClosingOperations.DetermineStateAndFillInExplanationsForStage(
		StructureOfData,
		StageTableRow,
		HandlerParameters,
		SelectingWhenToRunCheck);
	
	AddTreeRowsFromTable(
		StructureOfData.TableOfGroupedExplanations,
		StructureOfData.TableStages,
		"ThisIsAnExplanation",
		New Structure("Parent", CalculatedStage));
	
	DataStorage = New ValueStorage(StructureOfData, New Deflation(9));
	
EndProcedure

&AtServer
Procedure FillInAllStageExplanations(CalculatedStage, StructureOfData)
	
	// After performing the calculation and determining the State, it transfers all the problems found to the month closing form
	StageTableRow = StructureOfData.TableStages.Find(CalculatedStage, "Code");
	IdOfStageLine = StageTableRow.RowID;
	
	RowOfParentTable = StructureOfData.StageGroupTable.Find(StageTableRow.Parent, "Code");
	ParentLineID = RowOfParentTable.RowID;
	
	If IdOfStageLine >= 0 Then
		
		StageString_ = StageTree.FindByID(IdOfStageLine);
		
		If StageString_ <> Undefined Then
			
			StageString_.GetItems().Clear();
			
			FillPropertyValues(StageString_, StageTableRow);
			SetStatusPictureOfStageTreeLine(StageString_);
			
		EndIf;
		
	EndIf;

	If ParentLineID >= 0 Then

		ParentLevelRow = StageTree.FindByID(ParentLineID);
		If ParentLevelRow <> Undefined Then
			FillPropertyValues(ParentLevelRow, RowOfParentTable);
			SetStatusPictureOfStageTreeLine(ParentLevelRow);
		EndIf;
		
	EndIf;
	
	AddTreeRowsFromTable(
		StructureOfData.TableOfGroupedExplanations,
		StructureOfData.TableStages,
		"ThisIsAnExplanation",
		New Structure("Parent", CalculatedStage));
	
EndProcedure

&AtClient
Procedure CheckActivityOfBackgroundCalculationTask()
	
	JobState = CurStateOfBackgroundJob(StageCalculationJobID);
	
	If ValueIsFilled(JobState.ErrorText) Then
		
		FixProblemOfEmergencyCompletionOfCalculation(JobState.ErrorText);
		
	ElsIf JobState.Canceled Or JobState.Failed Or JobState.NotFound4 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhiệm vụ tính toán trên nền %1.';
				|ru = 'Фоновое задание расчета %1.';
				|en = 'Background job for %1 calculation.'; fa = 'Background job for %1 calculation.';
				|it = 'Il task in background per il calcolo %1.';
				|pl = 'Obliczanie zadania %1 w tle.';
				|tr = '%1 hesaplama arka plan işi.'", DefaultLanguageCode),
			?(JobState.Canceled,
				NStr("vi = 'bị hủy bởi người quản trị';
					|ru = 'отменено администратором';
					|en = 'canceled by administrator'; fa = 'canceled by administrator';
					|it = 'annullato dall''amministratore';
					|pl = 'anulowane przez administratora';
					|tr = 'yönetici tarafından iptal edildi'", DefaultLanguageCode),
				?(JobState.Failed,
					NStr("vi = 'đã kết thúc bất thường';
						|ru = 'завершено аварийно';
						|en = 'aborted'; fa = 'aborted';
						|it = 'terminato in modo anomalo';
						|pl = 'zakończone awaryjnie';
						|tr = 'arızalı tamamlandı'", DefaultLanguageCode),
					NStr("vi = 'không tìm thấy trong danh sách nhiệm vụ';
						|ru = 'не найдено в списке заданий';
						|en = 'not found in the job list'; fa = 'not found in the job list';
						|it = 'non trovato nell''elenco dei task';
						|pl = 'nie znaleziono na liście zadań';
						|tr = 'görev listesinde bulunmadı'", DefaultLanguageCode))));
		
		FixProblemOfEmergencyCompletionOfCalculation(ErrorText);
		
	EndIf;
	
	If JobState.Active // the calculation of the stage is still being performed
	 Or RunCalculationOfNextStageInBackground() Then // calculation of the next stage has been started
	 
		If Not JobState.Active Then
			Notify("UpdatingResultsOfInspectionsInFormOfClosingMonth");
			DurationOfCalculationOfStage = 0;
		Else
			
			// We get a list of problems that have already been found
			DurationOfCalculationOfStage = DurationOfCalculationOfStage + 1;
			IterationsOfCalculationActivityCheck = DurationOfCalculationOfStage / UpdateIntervalForStageCalculationProblems();
			
			If Int(IterationsOfCalculationActivityCheck) = IterationsOfCalculationActivityCheck Then
				FillInIntermediateExplanationsOfStageOnServer();
				Notify("UpdatingResultsOfInspectionsInFormOfClosingMonth");
			EndIf;
			
		EndIf;
		
		RepresentationOfTheCalculatedStage = 
			New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đang thực hiện giao dịch ""%1""...';
					|ru = 'Выполняется операция ""%1""...';
					|en = 'Performing the ""%1"" operation...'; fa = 'Performing the ""%1"" operation...';
					|it = 'L''operazione ""%1"" è in corso...';
					|pl = 'Wykonywana jest operacja ""%1""...';
					|tr = '""%1"" işlem yürütülüyor...'"),
				CalculationState.PresentationStage));
		
		SetStatusImagesForLongTermOperation(False);
	 	AttachIdleHandler("CheckActivityOfBackgroundCalculationTask", IntervalForCheckingBackgroundJobs(), True);
		Return;
		
	EndIf;
	
	If CancelCalculation Then
		
		// The calculation is interrupted.
		UpdateFormDataInBackgroundOnClient(False, False);
		
	Else
		
		// The calculation is completed.
		FillFormWithUpdatedDataOnClient();
		
		CustomizeItemsBasedOnBackgroundJobs();
		
	EndIf;
	
	Notify("CompletedMonthEndClosing");
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		Object.RegistrationPeriod = SelectedPeriod;
		RegistrationPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationPeriod);
		Object.PreliminaryMonthEndClosingDate = EndOfMonth(Object.RegistrationPeriod);
		
		UpdateFormDataInBackgroundOnClient(, False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CompletingTasksWhenClosingForm()
	
	CancelBackgroundJob(IDOfStageStateUpdateJob, False);
	CancelBackgroundJob(StageCalculationJobID, False);

	DataProcessors.MonthEndClosingOperations.CompleteSubordinateTasksOfCalculationStage(CalculationID);
	
	InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	
EndProcedure

&AtClient
Procedure NotifyStartOfCalculation(ActionDetails = Undefined)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Period", Object.RegistrationPeriod);
	NotificationParameters.Insert("CompaniesList", Object.CompanyArray);
	
	Notify("BeginningOfCalculationOfMonthClosing", NotificationParameters, ThisObject);
	
EndProcedure

&AtServer
Function GetDataWarehouse()
	
	DataWarehouseIsTyped = DataStorage; // ValueStorage
	Return DataWarehouseIsTyped.Get();
		
EndFunction

&AtServer
Function YouHaveRightToViewForm(Var_FormName)
	
	HasAccessRight = True;
	RowsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Var_FormName, ".");
	
	If RowsArray.Count() >= 2 Then
		
		NameOfFormObject = RowsArray[0] + "." + RowsArray[1];
		HasAccessRight = AccessRight("View", Metadata.FindByFullName(NameOfFormObject));
		
		If Not HasAccessRight Then
			Common.MessageToUser(
				NStr("vi = 'Không có quyền truy cập đến đối tượng';
					|ru = 'Нет прав доступа к объекту';
					|en = 'No access rights to the object'; fa = 'No access rights to the object';
					|it = 'Non vi sono diritti di accesso all''oggetto';
					|pl = 'Brak uprawnień dostępu do obiektu';
					|tr = 'Nesneye erişim yetkisi bulunmuyor'") + " " + NameOfFormObject + Chars.LF
				+ NStr("vi = 'Người quản trị hệ thống có thể thực hiện giao dịch này.';
						|ru = 'Данную операцию может выполнить администратор системы.';
						|en = 'This operation is available to the system administrator.'; fa = 'This operation is available to the system administrator.';
						|it = 'Questa operazione può essere eseguita dall''amministratore di sistema.';
						|pl = 'Tę operację może wykonać tylko administrator systemu.';
						|tr = 'Mevcut işlemi sistem yöneticisi gerçekleştirebilir'"));
		EndIf;
		
	EndIf;
	
	Return HasAccessRight;
	
EndFunction

&AtServer
Function TabularDocumentOfTasks()
	
	DecryptionOfTasks = DecryptionOfTasks; // ValueStorage
	
	Return CostCalculationUniversalAlgorithms.TableOfValuesInTabularDocument(DecryptionOfTasks.Get());
	
EndFunction

&AtClient
Procedure AnswerToQuestionOfStoppingCalculation(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	StopCalculationInTheBackgroundCompletion();
	
EndProcedure

&AtClient
Procedure StopCalculationInTheBackgroundCompletion()
	
	CancelCalculation = True;
	
	Items.StopCalculationInTheBackground.Enabled = False; // there is no need to press the button again
	
	StopBackgroundCalculationJob();
	
	CheckActivityOfBackgroundCalculationTask();
	
EndProcedure

&AtServer
Procedure SetParametersForRoutineTaskOfNonOperationalQueue()

	ParametersOfRoutineTaskInNonOperationalQueue = BackdateJobQueue.ParametersOfRoutineTaskInNonOperationalQueue();
	
	ShowHyperlink = False;
	
	If Not Common.DataSeparationEnabled()
	 And Not ParametersOfRoutineTaskInNonOperationalQueue.ScheduledJobID = Undefined Then
		ShowHyperlink = Not ParametersOfRoutineTaskInNonOperationalQueue.ScheduledJobUsed;
	EndIf;
	
	Items.SettingsForRoutineTaskOfNonOperationalDocumentVerification.Visible = ShowHyperlink;

EndProcedure

&AtServerNoContext
Procedure UpdateMainFormServer()

	Common.CommonSettingsStorageSave(
		"DataProcessor.MonthEndClosingOperations",
		"DefaultForm",
		"DataProcessor.MonthEndClosingOperations.Form.MonthEndTransactions");

EndProcedure

#EndRegion

#Region CalculationStages

&AtClientAtServerNoContext
Procedure SetStatusPictureOfStageTreeLine(StageTreeString)
	
	PictureNumber = 0; // index of the collection of the general image of the statusfulfillation of the month's closing stagesreferences
	
	If TypeOf(StageTreeString.State) = Type("EnumRef.AccountingIssueSeverity") Then
		
		If StageTreeString.State = PredefinedValue("Enum.AccountingIssueSeverity.Information") Then
			PictureNumber = 5;
		ElsIf StageTreeString.State = PredefinedValue("Enum.AccountingIssueSeverity.Warning") Then
			PictureNumber = 2;
		ElsIf StageTreeString.State = PredefinedValue("Enum.AccountingIssueSeverity.Error") Then
			PictureNumber = 3;
		ElsIf StageTreeString.State = PredefinedValue("Enum.AccountingIssueSeverity.ImportantInformation") Then
			PictureNumber = 4;
		ElsIf StageTreeString.State = PredefinedValue("Enum.AccountingIssueSeverity.UsefulTip") Then
			PictureNumber = 9;
		EndIf;
		
	Else
		
		If StageTreeString.State = PredefinedValue("Enum.StatesOfMonthEndClosingOperations.NotRequired") Then
			PictureNumber = 10;
		ElsIf StageTreeString.State = PredefinedValue("Enum.StatesOfMonthEndClosingOperations.Undefined") Then
			PictureNumber = 8;
		ElsIf StageTreeString.State = PredefinedValue("Enum.StatesOfMonthEndClosingOperations.PendingExecutionOfPreviousOperations") Then
			PictureNumber = 6;
		ElsIf StageTreeString.State = PredefinedValue("Enum.StatesOfMonthEndClosingOperations.DoneWithErrors") Then
			If StageTreeString.ThereIsImportantInformation Then
				PictureNumber = 4;
			ElsIf StageTreeString.ThereIsAUsefulTip Then
				PictureNumber = 9;
			Else
				PictureNumber = 2;
			EndIf;
		ElsIf StageTreeString.State = PredefinedValue("Enum.StatesOfMonthEndClosingOperations.ExecutedSuccessfully") Then
			If StageTreeString.ThereIsImportantInformation Then
				PictureNumber = 12;
			ElsIf StageTreeString.ThereIsAUsefulTip Then
				PictureNumber = 11;
			Else
				PictureNumber = 1;
			EndIf;
		ElsIf StageTreeString.State = PredefinedValue("Enum.StatesOfMonthEndClosingOperations.NotCompleted") Then
			PictureNumber = 3;
		EndIf;
		
	EndIf;
	
	StageTreeString.StatusPicture_2 = PictureNumber;
	
EndProcedure

&AtClient
Procedure SetStatusImagesForLongTermOperation(UpdatingStates = False, ParentOfRows = Undefined)
	
	If ParentOfRows = Undefined Then
		ParentOfRows = StageTree;
	EndIf;
	
	// We get the index of the collection of the general picture of the status of the completion of the closing steps of the month.
	If UpdatingStates Then
		PictureNumber = 8; 
	Else
		PictureNumber = 6; // Calculation is in progress
	EndIf;
	
	For Each CurrentTreeRow In ParentOfRows.GetItems() Do
		
		If UpdatingStates Then
			CurrentTreeRow.StatusPicture_2 = PictureNumber;
		Else
			If CurrentTreeRow.Code = CurrentCalculatedStage Then
				CurrentTreeRow.StatusPicture_2 = PictureNumber;
			Else
				//@skip-check structure-consructor-too-many-keys
				LineDetails = New Structure("State, ThereIsImportantInformation, ThereIsAUsefulTip, StatusPicture_2");
				FillPropertyValues(LineDetails, CurrentTreeRow);
				SetStatusPictureOfStageTreeLine(LineDetails);
				CurrentTreeRow.StatusPicture_2 = LineDetails.StatusPicture_2;
			EndIf;
		EndIf;
		
		SetStatusImagesForLongTermOperation(UpdatingStates, CurrentTreeRow);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessHyperlinkClick(StageTreeString, RunActionClicked = True, OnlyOneStage = False)
	
	If StageTreeString.IsFolder Then
		Return; // not supported for groups
	EndIf;
	
	ClearMessages();
	
	ActionDetails = GetDescriptionOfSelectedActionToPerformOnClient(
		StageTreeString.ThisIsAStep,
		StageTreeString.Code,
		RunActionClicked,
		OnlyOneStage);
	
	If ActionDetails = Undefined Then
		Return; // the action was performed on the server
	EndIf;
	
	If ActionDetails.ActionKind = PredefinedValue("Enum.DrillDownActionKindsForMonthEndOperations.OpenForm") Then
		
		If Not YouHaveRightToViewForm(ActionDetails.FormName) Then
			Return;
		EndIf;
			
		FormParameters = ActionDetails.FormParameters;
		
		If CommonClientServer.HasAttributeOrObjectProperty(FormParameters, "Filter") Then
			FillPropertyValues(FormParameters.Filter, CalculationParameters);
			FormParameters.Filter.Organization = FormParameters.Filter.CompanyArray;
		Else
			FillPropertyValues(FormParameters, CalculationParameters);
		EndIf;
		
		If Not (CommonClientServer.HasAttributeOrObjectProperty(FormParameters, "Organization")
			And ValueIsFilled(FormParameters.Organization)) Then 
			FormParameters.Insert("Organization", MonthEndTransactionsClientLocalization.OrganizationFromFixedArray(SharedArrayOfCompanies));
		EndIf;
		
		CloseHandler = New CallbackDescription("ClosingHyperlinkFormAction", ThisObject, CalculationParameters);
		
		If ActionDetails.OpenFormWithBlocking Then
			OpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Else
			OpeningMode = FormWindowOpeningMode.Independent;
		EndIf;
		
		OpenForm(ActionDetails.FormName, FormParameters, ThisObject, StageTreeString.Code,,, CloseHandler, OpeningMode);
		
	ElsIf ActionDetails.ActionKind = PredefinedValue("Enum.DrillDownActionKindsForMonthEndOperations.OpenCheckResults") Then
		
		FormParameters = New Structure("VerificationParameters", ActionDetails.FormParameters);
		FormParameters.Insert("IssueText", StageTreeString.Description);
		
		OpenForm(ActionDetails.FormName, FormParameters, ThisObject, StageTreeString.Code);
		
	ElsIf ActionDetails.ActionKind = PredefinedValue("Enum.DrillDownActionKindsForMonthEndOperations.OpenEventLog") Then
		
		FormParameters = ActionDetails.FormParameters;
		
		OpenForm(ActionDetails.FormName, FormParameters, ThisObject, StageTreeString.Code);
		
	ElsIf ActionDetails.ActionKind = PredefinedValue("Enum.DrillDownActionKindsForMonthEndOperations.PerformTheCalculation") Then
		
		Notify("UpdatingResultsOfInspectionsInFormOfClosingMonth");
		SetStatusImagesForLongTermOperation(False);
		CheckActivityOfBackgroundCalculationTask();
		NotifyStartOfCalculation(ActionDetails);
		
	ElsIf ActionDetails.ActionKind = PredefinedValue("Enum.DrillDownActionKindsForMonthEndOperations.ExecuteProcedureOnClient") Then
		
		FormParameters = ActionDetails.FormParameters;
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("Period", 			 FormParameters.RegistrationPeriod);
		ProcedureParameters.Insert("CompanyArray", FormParameters.CompanyArray);
		
		CompletionHandler = New CallbackDescription("ExecuteProcedureOnClientCompletion", ThisObject);
		ProcedureParameters.Insert("CompletionHandler", CompletionHandler);
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			FormParameters, "AdditionalParameters") Then
				ProcedureParameters.Insert("AdditionalParameters", FormParameters.AdditionalParameters);
		EndIf;
		
		ProcedureName = ActionDetails.Handler + "(ProcedureParameters)";
		
		Result = Eval(ProcedureName);

	ElsIf ActionDetails.ActionKind = PredefinedValue("Enum.DrillDownActionKindsForMonthEndOperations.OpenObjectHelp") Then
		
		OpenHelp(ActionDetails.MetadataObjectName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClosingHyperlinkFormAction(ClosingResult, AdditionalParameters) Export
	
	If Not CalculationState.CalculationIsCompleted Then
		// We don't update the form when performing the calculation
		Return;
	EndIf;
	
	ForcedToUpdateForm = TypeOf(ClosingResult) = Type("Structure") And ClosingResult.Property("UpdateCloseMonthForm");
	
	If Not Object.AutoUpdateWhenClosingSubordinateForms And Not ForcedToUpdateForm Then
		Return;
	EndIf;
	
	// When closing the manual operation form, you need to update the state of the stages.
	UpdateFormDataInBackgroundOnClient();
	
EndProcedure

&AtClient
Procedure ExecuteProcedureOnClientCompletion(Result, AdditionalParameters) Export
	
	UpdateFormDataInBackgroundOnClient();
	
EndProcedure

&AtServer
Function GetDescriptionOfSelectedActionToPerformOnClient(ThisIsAStep, RowCode, RunActionClicked = True, OnlyOneStage = False)
	
	StructureOfData = GetDataWarehouse();
	
	ActionDescriptionTable = ?(ThisIsAStep, StructureOfData.TableStages, StructureOfData.TableOfGroupedExplanations);
	ActionTableRow   = ActionDescriptionTable.Find(RowCode, "Code");
	
	If ActionTableRow = Undefined Then
		Return Undefined;
	EndIf;
	
	ActionDetails = ?(RunActionClicked, ActionTableRow.ActionExecute, ActionTableRow.ActionMoreDetails);
	
	If ThisIsAStep And Not ActionTableRow.PerformedManually And Not RunActionClicked Then // the "More details" action at the settlement stage
		
		// If the "More Details" action is not defined, then open the LR.
		If Not ValueIsFilled(ActionDetails) Then
			ActionDetails = MonthEndTransactionsServer.ActionDescription_OpenLog(RowCode);
		EndIf;
		
	EndIf;
		
	If ActionDetails.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.OpenEventLog Then
		
		CalculationInformation_ = InformationRegisters.PerformMonthEndClosingOperations.GetInformationAboutStageCompletion(
			StructureOfData.CalculationParameters.CompanyArray,
			StructureOfData.CalculationParameters.RegistrationPeriod,
			RowCode);
		
		FillPropertyValues(ActionDetails.FormParameters, CalculationInformation_);
		
	EndIf;
	
	If ActionDetails.AtClient Then
		
		If ActionDetails.ActionKind <> Enums.DrillDownActionKindsForMonthEndOperations.OpenEventLog Then
			
			ActionDetails.FormParameters.Insert("CompanyArray", StructureOfData.CalculationParameters.CompanyArray);
			ActionDetails.FormParameters.Insert("RegistrationPeriod", StructureOfData.CalculationParameters.RegistrationPeriod);
			ActionDetails.FormParameters.Insert("CheckedPeriod", StructureOfData.CalculationParameters.RegistrationPeriod);
			
			AdditionalFormSelections = New Structure("TypesOfRoutineOperations");
			FillPropertyValues(AdditionalFormSelections, ActionTableRow);
			
			If ValueIsFilled(AdditionalFormSelections.TypesOfRoutineOperations) Then
				ActionDetails.FormParameters.Insert("OperationType", AdditionalFormSelections.TypesOfRoutineOperations);
			EndIf;
			
		EndIf;
		
		Return ActionDetails;
		
	EndIf;
	
	If ActionDetails.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.PerformTheCalculation Then
		
		If StartCalculationExecution(RowCode, OnlyOneStage) Then
			Return ActionDetails; // we need to connect the waiting handlers
		EndIf;
		
	EndIf;
	
	Return Undefined; // it is not required to execute on the client
	
EndFunction

&AtServer
Procedure FillInClosingStateOfMonth()
	
	If TypeOf(MonthClosedSuccessfully) <> Type("Boolean") Then
		Items.GroupCalculationStatus.Visible = False;
		Return;
	EndIf;
	
	Items.RepresentationOfTheCalculationStatus.TextColor  = Items.CalculatedCompanies.TitleTextColor;
	Items.RepresentationOfTheCalculationStatus.Hyperlink = False;
	
	If MonthClosedSuccessfully Then
		
		If CalculatedSteps = 0 Then
			RepresentationOfTheCalculationStatus = NStr("vi = 'Không cần kết chuyển cuối tháng';
														|ru = 'Закрытие месяца не требуется';
														|en = 'Month-end closing is not required'; fa = 'Month-end closing is not required';
														|it = 'La chiusura del mese non è richiesta';
														|pl = 'Zamknięcie miesiąca nie jest wymagane';
														|tr = 'Ay sonu kapanışı gerekmiyor'");
		Else
			RepresentationOfTheCalculationStatus = NStr("vi = 'Tất cả giao dịch đã thực hiện thành công';
														|ru = 'Все операции выполнены успешно';
														|en = 'All operations are completed successfully'; fa = 'All operations are completed successfully';
														|it = 'Tutte le operazioni sono eseguite con successo';
														|pl = 'Wszystkie operacje wykonane pomyślnie';
														|tr = 'Tüm işlemler başarıyla gerçekleştirildi'");
		EndIf;
		
		If ChangesAreDisabled Then
			Items.DecorationOfTheCalculationStatus.Picture = PictureLib.ClosedForChanging;
		Else
			Items.DecorationOfTheCalculationStatus.Picture = PictureLib.MediumGreenCheckBox;
		EndIf;
		
	Else
		
		If ChangesAreDisabled Then
			
			RepresentationOfTheCalculationStatus = New FormattedString(
				New FormattedString(NStr("vi = 'Không thể tính toán';
										|ru = 'Расчет невозможен';
										|en = 'Cannot calculate'; fa = 'Cannot calculate';
										|it = 'Calcolo non possibile';
										|pl = 'Obliczenie jest niemożliwe';
										|tr = 'Hesaplama yapılamaz'"),, WebColors.Red),
				"  ",
				New FormattedString(NStr("vi = 'Chi tiết';
										|ru = 'Подробнее';
										|en = 'Details'; fa = 'جزئیات';
										|it = 'Подробнее';
										|pl = 'Details';
										|tr = 'Ayrıntılar'"),, WebColors.Blue,, "MoreDetails"));
			
			Items.DecorationOfTheCalculationStatus.Picture = PictureLib.ClosedForChanging;
			
		Else

			If ValueIsFilled(CommonSettlementStartDate) And CommonSettlementStartDate < Object.RegistrationPeriod Then
				RepresentationOfTheCalculationStatus = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cần tính lại từ kỳ %1';
						|ru = 'Требуется пересчет с периода %1';
						|en = 'Recalculation is required from the period of %1'; fa = 'Recalculation is required from the period of %1';
						|it = 'Требуется пересчет с периода %1';
						|pl = 'Recalculation is required from the period of %1';
						|tr = '%1 döneminden başlayarak yeniden hesaplama gerekmektedir'"),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CommonSettlementStartDate));
				Items.RepresentationOfTheCalculationStatus.TextColor  = WebColors.Red;
			Else
				RepresentationOfTheCalculationStatus = NStr("vi = 'Đang có các giao dịch chưa thực hiện';
															|ru = 'Существуют невыполненные операции';
															|en = 'There are incomplete operations'; fa = 'There are incomplete operations';
															|it = 'Ci sono operazioni in sospeso';
															|pl = 'Istnieją zaległości operacji';
															|tr = 'Tamamlanmamış işlemler var'");
			EndIf;
			
			Items.DecorationOfTheCalculationStatus.Picture = PictureLib.WarningRed;
			
		EndIf;
		
	EndIf;
	
	Items.GroupCalculationStatus.Visible = Not IsPeriodLocked Or GenerateOperationsForClosedPeriod;
	
	CreatePresentationOfOrganizations();
	
EndProcedure

&AtServer
Function StartCalculationExecution(CalculateByStage = Undefined, OnlyOneStage = False)
	
	// Initialize the calculation.
	CancelCalculation = False;
	StorageAddressForStageCalculationJob = "";
	DurationOfCalculationOfStage = 0;
	
	CalculationState = DataProcessors.MonthEndClosingOperations.InitializeStateStructureOfCalculation(
		GetDataWarehouse(),
		CalculateByStage);
		
	If OnlyOneStage Then
		CalculationState.StepsToCalculation.Clear();
		CalculationState.StepsToCalculation.Add(CalculateByStage);
		CalculationState.NumberOfStages = CalculationState.StepsToCalculation.Count();
		CalculationState.CurStageNumber = CalculationState.PreviousStageNumber + 1;
		CalculationStarted = StartCalculationOfOneStageInBackground();
	Else
		CalculationStarted = RunCalculationOfNextStageInBackground();
	EndIf;
	
	If CalculationStarted Then
		CustomizeItemsBasedOnBackgroundJobs();
	EndIf;
	
	Return CalculationStarted;
	
EndFunction

&AtServer
Function StartCalculationOfOneStageInBackground()
	Var StructureOfData;
	
	JobStarted = False;
	
	// We will get the updated states of the stages from the background task.
	If ValueIsFilled(StorageAddressForStageCalculationJob) Then
		StructureOfData = GetFromTempStorage(StorageAddressForStageCalculationJob);
	EndIf;
	
	If TypeOf(StructureOfData) <> Type("Structure") Then
		StructureOfData = GetDataWarehouse();
	EndIf;
	
	StorageAddressForStageCalculationJob = "";
	
	If CalculationState.CurStageNumber < CalculationState.NumberOfStages - 1 Then
		
		If ValueIsFilled(CalculationID) Then
			InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
		EndIf;
		
		CalculationID = New UUID;
		
		// Let's check the possibility of starting the calculation.
		ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.SetFlagForStartingCalculation(
			New Array(SharedArrayOfCompanies),
			CalculationID,
			InformationAboutCalculationStart, 
			StructureOfData.CalculationParameters.RegistrationPeriod,
			CalculationState.StepsToCalculation[CalculationState.CurStageNumber + 1]);
		
		If ActiveCalculations.ThereAreActiveCalculations Then
			Common.MessageToUser(ActiveCalculations.ErrorText,,,, CancelCalculation);
		EndIf;
		
	EndIf;
	
	If CancelCalculation Then
		
		CalculationState = DataProcessors.MonthEndClosingOperations.InitializeStateStructureOfCalculation(Undefined);
		CurrentCalculatedStage = Undefined;
		PreviousCalculatedStage = Undefined;
		
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
		
		Return JobStarted;
		
	EndIf;
	
	If ValueIsFilled(CurrentCalculatedStage) Then
		// Fill in the errors of the previously calculated stage
		FillInAllStageExplanations(CurrentCalculatedStage, StructureOfData);
	EndIf;
	
	StageNumber = 0;
	
	TableStages = StructureOfData.TableStages; // See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
	
	CurrentStep   = CalculationState.StepsToCalculation[StageNumber];
	CurrentRow = TableStages.Find(CurrentStep, "Code");
	
	CurrentCalculatedStage = CurrentStep;
	
	CalculationState.PresentationStage = CurrentRow.Description;
	
	If Not MonthEndTransactionsServer.StageRecalculationIsRequired(CurrentRow) Then
		FillInIntermediateExplanationsOfStage(CurrentCalculatedStage, StructureOfData);
		FillInAllStageExplanations(CurrentCalculatedStage, StructureOfData);
	EndIf;
	
	If ValueIsFilled(CalculationID) Then
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	EndIf;
	
	// Let's check the possibility of starting the calculation.
	ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.SetFlagForStartingCalculation(
		New Array(SharedArrayOfCompanies),
		CalculationID,
		InformationAboutCalculationStart,
		StructureOfData.CalculationParameters.RegistrationPeriod,
		CalculationState.StepsToCalculation[StageNumber]);
	
	If ActiveCalculations.ThereAreActiveCalculations Then
		Common.MessageToUser(ActiveCalculations.ErrorText,,,, CancelCalculation);
	EndIf;
	
	// We will prepare auxiliary data for starting the calculation.
	StorageAddressForStageCalculationJob = PutToTempStorage(Undefined, UUID);
	
	CalculationStartParameters = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersForCalculatingStages(
		StructureOfData,
		CurrentStep,
		CalculationState.StepsToCalculation[CalculationState.NumberOfStages - 1],
		Object.MonthEndClosingMode,
		StorageAddressForStageCalculationJob,
		WorkMode.AvailabilityOfAccountingTypes,
		CalculationID);
	
	// Let's start the calculation.
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(CalculationStartParameters);
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện các giao dịch kết chuyển cuối tháng %1';
			|ru = 'Выполнение операций закрытия месяца %1';
			|en = 'Perform month-end closing operations %1'; fa = 'Perform month-end closing operations %1';
			|it = 'Esecuzione delle operazioni di chiusura del mese %1';
			|pl = 'Wykonanie operacji zamknięcia miesiąca %1';
			|tr = '%1 ay sonu kapanış işlemleri gerçekleştiriliyor'"),
		CostCalculationProtocol.PresentationOfCalculationPeriod(StructureOfData.CalculationParameters.RegistrationPeriod));
	
	SettingCalculationOfStages = BackgroundJobs.Execute(
		"MonthEndTransactionsServer.CalculateStagesInBackgroundJob",
		ExportProcedureParameters,
		MonthEndTransactionsServer.NameOfBackgroundJob(CalculationID),
		JobDescription);
	
	StageCalculationJobID = SettingCalculationOfStages.UUID;
	CalculationState.PreviousStageNumber = StageNumber;
	
	FillInIntermediateExplanationsOfStage(CurrentCalculatedStage, StructureOfData);
	
	JobStarted = True;
	
	CalculationState.CurStageNumber = StageNumber;
	CalculationState.CalculationIsCompleted = (StageNumber >= CalculationState.NumberOfStages);
	
	DataStorage = New ValueStorage(StructureOfData, New Deflation(9));
	
	If Not JobStarted Then
		CurrentCalculatedStage = Undefined;
		PreviousCalculatedStage = Undefined;
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	EndIf;
	
	Return JobStarted;
	
EndFunction

&AtServer
Function RunCalculationOfNextStageInBackground()
	Var StructureOfData;
	
	JobStarted = False;
	
	// We will get the updated states of the stages from the background task.
	If ValueIsFilled(StorageAddressForStageCalculationJob) Then
		StructureOfData = GetFromTempStorage(StorageAddressForStageCalculationJob);
	EndIf;
	
	If TypeOf(StructureOfData) <> Type("Structure") Then
		StructureOfData = GetDataWarehouse();
	EndIf;
	
	StorageAddressForStageCalculationJob = "";
	
	If Object.StopOnError And CalculationState.PreviousStageNumber >= 0 Then
		
		// If the last stage is calculated with errors and the "Stop by mistake" checkbox is selected, then it is necessary to abort the calculation.
		PreviousStage   = CalculationState.StepsToCalculation[CalculationState.PreviousStageNumber];
		PreviousString = StructureOfData.TableStages.Find(PreviousStage, "Code");
		
		If PreviousString.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted Then
			
			CancelCalculation = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giao dịch ''''%1'''' đã tính bị lỗi. Đã dừng giao dịch kết chuyển cuối tháng.';
					|ru = 'Операция ""%1"" рассчитана с ошибками. Выполнение операций закрытия месяца остановлено.';
					|en = 'The ""%1"" operation is calculated with errors. Month-end operations are stopped.'; fa = 'The ""%1"" operation is calculated with errors. Month-end operations are stopped.';
					|it = 'L''operazione ""%1"" è stata calcolata con errori. Le operazioni di chiusura del mese vengono interrotte.';
					|pl = 'Operacja ""%1"" została rozliczona z błędami. Wykonanie operacji zamknięcia miesiąca zostało zatrzymane.';
					|tr = '""%1"" işlemi yanlış hesaplandı. Ay sonu kapanış işlemleri durdurulmuştur.'"),
				PreviousString.Description);
			
			Common.MessageToUser(ErrorText);
			
			// For the Registration Log, the message text must be generated in the main configuration language
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giao dịch ''''%1'''' đã tính bị lỗi. Đã dừng giao dịch kết chuyển cuối tháng.';
					|ru = 'Операция ""%1"" рассчитана с ошибками. Выполнение операций закрытия месяца остановлено.';
					|en = 'The ""%1"" operation is calculated with errors. Month-end operations are stopped.'; fa = 'The ""%1"" operation is calculated with errors. Month-end operations are stopped.';
					|it = 'L''operazione ""%1"" è stata calcolata con errori. Le operazioni di chiusura del mese vengono interrotte.';
					|pl = 'Operacja ""%1"" została rozliczona z błędami. Wykonanie operacji zamknięcia miesiąca zostało zatrzymane.';
					|tr = '""%1"" işlemi yanlış hesaplandı. Ay sonu kapanış işlemleri durdurulmuştur.'", Common.DefaultLanguageCode()),
				PreviousString.Description);
			
			WriteLogEvent(
				MonthEndTransactionsServer.EventLogEventName(
					NStr("vi = 'Dừng kết chuyển cuối tháng do lỗi tính toán';
						|ru = 'Остановка закрытия месяца из-за ошибок расчета';
						|en = 'Stop month-end closing because of calculation errors'; fa = 'Stop month-end closing because of calculation errors';
						|it = 'Interruzione di chiusura del mese a causa degli errori di calcolo';
						|pl = 'Wstrzymanie zamknięcia miesiąca z powodu błędów obliczeń';
						|tr = 'Hesaplama hatasından dolayı ay sonu kapanışı durdurulması'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ErrorText);
			
		EndIf;
		
	ElsIf CalculationState.CurStageNumber < CalculationState.NumberOfStages - 1 Then
		
		If ValueIsFilled(CalculationID) Then
			InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
		EndIf;
		
		CalculationID = New UUID;
		
		// Let's check the possibility of starting the calculation.
		ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.SetFlagForStartingCalculation(
			New Array(SharedArrayOfCompanies),
			CalculationID,
			InformationAboutCalculationStart,
			StructureOfData.CalculationParameters.RegistrationPeriod,
			CalculationState.StepsToCalculation[CalculationState.CurStageNumber + 1]);
		
		If ActiveCalculations.ThereAreActiveCalculations Then
			Common.MessageToUser(ActiveCalculations.ErrorText,,,, CancelCalculation);
		EndIf;
		
	EndIf;
	
	If CancelCalculation Then
		
		CalculationState = DataProcessors.MonthEndClosingOperations.InitializeStateStructureOfCalculation(Undefined);
		CurrentCalculatedStage = Undefined;
		PreviousCalculatedStage = Undefined;
		
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
		
		Return JobStarted;
		
	EndIf;
	
	If ValueIsFilled(CurrentCalculatedStage) Then
		// Fill in the errors of the previously calculated stage
		FillInAllStageExplanations(CurrentCalculatedStage, StructureOfData);
	EndIf;
	
	For StageNumber = CalculationState.CurStageNumber + 1 To CalculationState.NumberOfStages - 1 Do
		
		TableStages = StructureOfData.TableStages; // See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
		
		CurrentStep   = CalculationState.StepsToCalculation[StageNumber];
		CurrentRow = TableStages.Find(CurrentStep, "Code");
		
		PreviousCalculatedStage = CurrentCalculatedStage;
		CurrentCalculatedStage = CurrentStep;
		
		If ValueIsFilled(PreviousCalculatedStage) Then

			PreviousString = TableStages.Find(PreviousCalculatedStage, "Code");
			
			For StageLineNumber = TableStages.IndexOf(PreviousString) + 1 To TableStages.IndexOf(CurrentRow) - 1 Do
				
				MissingLine = TableStages[StageLineNumber];
				If Not MissingLine.PerformedManually Then
					Continue;
				EndIf;

				FillInIntermediateExplanationsOfStage(MissingLine.Code, StructureOfData);
				FillInAllStageExplanations(MissingLine.Code, StructureOfData);
				
			EndDo;
			
		EndIf;
		
		CalculationState.PresentationStage = CurrentRow.Description;
		
		If Not MonthEndTransactionsServer.StageRecalculationIsRequired(CurrentRow) Then
			FillInIntermediateExplanationsOfStage(CurrentCalculatedStage, StructureOfData);
			FillInAllStageExplanations(CurrentCalculatedStage, StructureOfData);
			Continue;
		EndIf;
		
		If ValueIsFilled(CalculationID) Then
			InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
		EndIf;
		
		// Let's check the possibility of starting the calculation.
		ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.SetFlagForStartingCalculation(
			New Array(SharedArrayOfCompanies),
			CalculationID,
			InformationAboutCalculationStart,
			StructureOfData.CalculationParameters.RegistrationPeriod,
			CalculationState.StepsToCalculation[StageNumber]);
		
		If ActiveCalculations.ThereAreActiveCalculations Then
			Common.MessageToUser(ActiveCalculations.ErrorText,,,, CancelCalculation);
		EndIf;
		
		// We will prepare auxiliary data for starting the calculation.
		StorageAddressForStageCalculationJob = PutToTempStorage(Undefined, UUID);
		
		CalculationStartParameters = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersForCalculatingStages(
			StructureOfData,
			CurrentStep,
			CalculationState.StepsToCalculation[CalculationState.NumberOfStages - 1],
			Object.MonthEndClosingMode,
			StorageAddressForStageCalculationJob,
			WorkMode.AvailabilityOfAccountingTypes,
			CalculationID);
		
		// Let's start the calculation.
		ExportProcedureParameters = New Array;
		ExportProcedureParameters.Add(CalculationStartParameters);
		
		JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thực hiện các giao dịch kết chuyển cuối tháng %1';
				|ru = 'Выполнение операций закрытия месяца %1';
				|en = 'Perform month-end closing operations %1'; fa = 'Perform month-end closing operations %1';
				|it = 'Esecuzione delle operazioni di chiusura del mese %1';
				|pl = 'Wykonanie operacji zamknięcia miesiąca %1';
				|tr = '%1 ay sonu kapanış işlemleri gerçekleştiriliyor'"),
			CostCalculationProtocol.PresentationOfCalculationPeriod(StructureOfData.CalculationParameters.RegistrationPeriod));
		
		SettingCalculationOfStages = BackgroundJobs.Execute(
			"MonthEndTransactionsServer.CalculateStagesInBackgroundJob",
			ExportProcedureParameters,
			MonthEndTransactionsServer.NameOfBackgroundJob(CalculationID),
			JobDescription);
		
		StageCalculationJobID = SettingCalculationOfStages.UUID;
		CalculationState.PreviousStageNumber = StageNumber;
		
		FillInIntermediateExplanationsOfStage(CurrentCalculatedStage, StructureOfData);
		
		JobStarted = True;
		
		Break;
		
	EndDo;
	
	CalculationState.CurStageNumber = StageNumber;
	CalculationState.CalculationIsCompleted = (StageNumber >= CalculationState.NumberOfStages);
	
	DataStorage = New ValueStorage(StructureOfData, New Deflation(9));
	
	If Not JobStarted Then
		CurrentCalculatedStage = Undefined;
		PreviousCalculatedStage = Undefined;
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	EndIf;
	
	Return JobStarted;
	
EndFunction

&AtServer
Procedure FixProblemOfEmergencyCompletionOfCalculation(ErrorText)
	
	If CalculationState.PreviousStageNumber < 0
	 Or CalculationState.StepsToCalculation.Count() <= CalculationState.PreviousStageNumber Then
		Return;
	EndIf;
	
	CurrentStep = CalculationState.StepsToCalculation[CalculationState.PreviousStageNumber];
	
	ErrorTextExtended = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi thực hiện giao dịch kết chuyển cuối tháng ""%1"", đã xảy ra lỗi:
			|%2';
			|ru = 'При выполнении операции закрытия месяца ""%1"" произошла ошибка:
			|%2';
			|en = 'An error occurred while performing month-end closing operation ""%1"":
			|%2'; fa = 'An error occurred while performing month-end closing operation ""%1"":
			|%2';
			|it = 'Durante l''operazione di chiusura del mese ""%1"" si è verificato un errore:
			|%2';
			|pl = 'Podczas wykonywania operacji zamknięcia miesiąca ""%1"" wystąpił błąd:
			|%2';
			|tr = '""%1"" ay sonu işlemi gerçekleştirilirken hata oluştu:
			|%2'", DefaultLanguageCode),
		TrimAll(CurrentStep),
		ErrorText);
	
	// Let's register the error.
	RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
		CurrentStep,
		CalculationParameters.CompanyArray,
		CalculationParameters.RegistrationPeriod);
		
	MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
		RegistrationParameters,
		Enums.AccountingIssueSeverity.ProblemTextTemplateCodeExecutionError(),
		,
		ErrorTextExtended);
		
	// Let's update the stage status.
	StructureOfData = GetDataWarehouse();
	
	ParametersForTriggeringStateUpdates = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(
		StructureOfData,
		,
		CurrentStep,
		WorkMode.AvailabilityOfAccountingTypes);
	
	ParametersForTriggeringStateUpdates.UpdateListOfChecks  	   = False;
	ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations = False;
	ParametersForTriggeringStateUpdates.PerformChecksBeforeStage 	   = True;
	
	DataProcessors.MonthEndClosingOperations.FillInStatesOfStages(ParametersForTriggeringStateUpdates);
	
	DataStorage = New ValueStorage(StructureOfData, New Deflation(9));
	
EndProcedure

&AtServer
Procedure AddTreeRowsFromTable(TableOfRows, ParentRowTable, NameOfAttributeColumn, FilterParameters = Undefined)
	
	If FilterParameters <> Undefined Then
		DataSource = TableOfRows.FindRows(FilterParameters);
	Else
		DataSource = TableOfRows;
	EndIf;
	
	For Each CurrentRow In DataSource Do
		
		CurrentRow.RowID = -1;
		
		TableRowProperties = New Structure; // not all lines have these properties
		TableRowProperties.Insert("PerformedManually", 	 False);
		TableRowProperties.Insert("DisplayCompletedSuccessfully", False);
		TableRowProperties.Insert("Disabled", 		 	 False);
		TableRowProperties.Insert("OperationalAccounting", 		 False);
		TableRowProperties.Insert("LocalAccounting", False);
		TableRowProperties.Insert("FinancialAccounting",  	 False);
		FillPropertyValues(TableRowProperties, CurrentRow);
		
		CurrentRow.Visible = Not (
		    TableRowProperties.Disabled
			Or (Object.HideStepsWithNotRequireStatus
				And CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired)
			Or (TableRowProperties.PerformedManually
				And CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired)
			Or (Object.HideStepsCompletedSuccessfully
				And CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully)
			Or (TableRowProperties.PerformedManually And Not TableRowProperties.DisplayCompletedSuccessfully
				And CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully)
			Or (Object.HideExplanationsToSteps
				And TypeOf(CurrentRow.State) = Type("EnumRef.AccountingIssueSeverity")));
		
		If Not CurrentRow.Visible Then
			Continue;
		EndIf;
			
		If ValueIsFilled(CurrentRow.Parent) Then
			
			ParentLineID = ParentRowTable.Find(CurrentRow.Parent, "Code").RowID;
			
			If ParentLineID >= 0 Then
				ParentLevelRow = StageTree.FindByID(ParentLineID);
			Else
				ParentLevelRow = Undefined;
			EndIf;
			
		Else
			ParentLevelRow = StageTree;
		EndIf;
		
		If ParentLevelRow <> Undefined Then // the parent may not be output - it is not necessary to output subordinates either
			
			NewRow = ParentLevelRow.GetItems().Add();
			CurrentRow.RowID = NewRow.GetID();
			
			FillPropertyValues(NewRow, CurrentRow);
			
			NewRow[NameOfAttributeColumn] = True;
			NewRow.ExecutionAtServer =
				CommonClientServer.HasAttributeOrObjectProperty(CurrentRow,"ActionExecute")
				And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow.ActionExecute,"AtServer")
				And CurrentRow.ActionExecute.AtServer;
			
			If ValueIsFilled(CurrentRow.Parent) And NewRow.PerformedManually Then
				ParentLevelRow.Highlight = True; // let's highlight the groups containing manual operations in color
			EndIf;
			
			SetStatusPictureOfStageTreeLine(NewRow);
			
			If NewRow.ThisIsAnExplanation Then
				
				If NewRow.State = Enums.AccountingIssueSeverity.ImportantInformation Then
					ParentLevelRow.ThereIsImportantInformation = True;
					SetStatusPictureOfStageTreeLine(ParentLevelRow);
				ElsIf NewRow.State = Enums.AccountingIssueSeverity.UsefulTip Then
					ParentLevelRow.ThereIsAUsefulTip = True;
					SetStatusPictureOfStageTreeLine(ParentLevelRow);
				EndIf;
				
			EndIf;
				
			If NewRow.ThisIsAStep And ValueIsFilled(CurrentRow.CompanyArray) Then
				NewArrayOfOrganizations = New Array(SharedArrayOfCompanies);
				CommonClientServer.SupplementArray(NewArrayOfOrganizations, CurrentRow.CompanyArray, True);
				SharedArrayOfCompanies = New FixedArray(NewArrayOfOrganizations);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DisplayDateOfStateOfStages(StateDate)
	
	Status = "";
	
	If StateDate <> Date(1,1,1) Then
		Status = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trạng thái giao dịch kết chuyển cuối tháng đã cập nhật vào %1.';
				|ru = 'Статус операций закрытия месяца актуален на %1.';
				|en = 'The month-end closing operation status is relevant as of %1.'; fa = 'The month-end closing operation status is relevant as of %1.';
				|it = 'The month-end closing operation status is relevant as of %1.';
				|pl = 'The month-end closing operation status is relevant as of %1.';
				|tr = 'Ay sonu kapanış işlemlerinin durumu %1 itibarıyla günceldir.'"), Format(StateDate, "DLF=DDT"));
	EndIf;
	
	RepresentationOfTheCalculatedStage = StringFunctionsClient.FormattedString(Status);
	
EndProcedure

#EndRegion

#Region BackgroundJobs

&AtServerNoContext
Function CurStateOfBackgroundJob(JobID, ForReadingOnClient = True)
	
	JobState = MonthEndTransactionsServer.CurStateOfBackgroundJob(JobID);
	
	If ForReadingOnClient Then
		JobState.Delete("Job"); // the value type of this property is not available on the client
	EndIf;
	
	Return JobState;
	
EndFunction

&AtServerNoContext
Function BackgroundTaskIsActive(JobID)
	
	JobState = CurStateOfBackgroundJob(JobID);
	
	Return JobState.Active;
	
EndFunction

&AtServer
Function CancelBackgroundJob(JobID, ReportError_ = True)
	
	If Not MonthEndTransactionsServer.CancelBackgroundJob_(JobID) Then
		
		If ReportError_ Then
			Common.MessageToUser(
				NStr("vi = 'Không thể hủy thực hiện nhiệm vụ nền tạo danh sách giao dịch.
					|Chi tiết xem trong Nhật ký sự kiện.';
					|ru = 'Не удалось отменить выполнение фонового задания формирования списка операций.
					|Подробности см. в Журнале регистрации.';
					|en = 'Cannot cancel the background job of operation list generation.
					|For more information, see the event log.'; fa = 'Cannot cancel the background job of operation list generation.
					|For more information, see the event log.';
					|it = 'Impossibile annullare l''esecuzione del task in background per la generazione dell''elenco operazioni.
					|Per i dettagli consultare il registro.';
					|pl = 'Nie udało się anulować wykonywanie w tle zadania tworzenia listy operacji.
					|szczegóły można znaleźć w Dzienniku rejestracji.';
					|tr = 'İşlem listesi oluşturma arka plan işi iptal edilemedi.
					|Ayrıntılar için Olay günlüğü''ne bakın.'"));
		EndIf;
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function IntervalForCheckingBackgroundJobs()
	Return 1;
EndFunction

&AtClient
Function UpdateIntervalForStageCalculationProblems()
	Return 10;
EndFunction

&AtServer
Function StopBackgroundCalculationJob()
	
	Result = MonthEndTransactionsServer.CancelBackgroundJob_(StageCalculationJobID);

	DataProcessors.MonthEndClosingOperations.CompleteSubordinateTasksOfCalculationStage(CalculationID);
	
	InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	
	Return Result;
	
EndFunction

&AtServer
Function DateWhenTheDataIsUpToDate()
	
	CustomizeItemsBasedOnBackgroundJobs();
	
	StructureOfData = GetDataWarehouse();
	
	If StructureOfData = Undefined Then
		Return Date(1,1,1);
	Else
		Return StructureOfData.DateWhenTheDataIsUpToDate;
	EndIf;
	
	
EndFunction

#EndRegion

#Region Companies

&AtServer
Function OrganizationInFixedArray(Organization = Undefined)
	
	CompanyArray = New Array;
	
	If ValueIsFilled(Organization) Then
		CompanyArray.Add(Organization);
	EndIf;
	
	Return New FixedArray(CompanyArray);
	
EndFunction

&AtServer
Procedure CreatePresentationOfOrganizations(CompanyArray = Undefined)
	
	If CompanyArray = Undefined Then
		CompanyArray = Object.CompanyArray;
	EndIf;
	
	If Object.AllCompanies
	 Or (ValueIsFilled(CompanyDescription)
	   And TMCommonUseClientServer.ArraysAreEqual(CompanyArray, CompanyDescription.AvailableCompanies, False)) Then
	   
		If ValueIsFilled(CompanyDescription) And CompanyDescription.ThereAreAccessRestrictions Then
			CalculatedCompanies = NStr("vi = 'Theo tất cả doanh nghiệp khả dụng';
										|ru = 'По всем доступным организациям';
										|en = 'By all available companies'; fa = 'By all available companies';
										|it = 'Per tutte le società disponibili';
										|pl = 'Dla wshystkich dostępnych firm';
										|tr = 'Tüm mevcut iş yerleri için'");
		Else
			CalculatedCompanies = NStr("vi = 'Theo tất cả doanh nghiệp';
										|ru = 'По всем организациям';
										|en = 'By all companies'; fa = 'بر اساس همه شرکت‌ها';
										|it = 'Per tutte le aziende';
										|pl = 'Według wszystkich firm';
										|tr = 'Tüm iş yerleri için'");
		EndIf;
		
		Items.CalculatedCompanies.ClearButton = False;
		
	Else
		
		CalculatedCompanies = CostCalculationAppliedAlgorithms.CalculatedCompanies(CompanyArray, ", ");
		
		Items.CalculatedCompanies.ClearButton = True;
		
	EndIf;
	
	If MonthClosedSuccessfully = False And Not ChangesAreDisabled And ValueIsFilled(BlockedBusinesses) Then
		
		Items.CalculatedCompanies.ToolTipRepresentation = ToolTipRepresentation.Button;
		Items.CalculatedCompanies.ToolTip = NStr("vi = 'Sẽ không thực hiện tính toán theo doanh nghiệp bị chặn:';
												|ru = 'Расчет не будет выполнен по заблокированным организациям:';
												|en = 'Calculation will not be performed for locked companies:'; fa = 'Calculation will not be performed for locked companies:';
												|it = 'Расчет не будет выполнен по заблокированным организациям:';
												|pl = 'Calculation will not be performed for locked companies:';
												|tr = 'Kilitli iş yerleri için hesaplama yapılmaz:'");
		
		For Each CurOrganization In BlockedBusinesses Do
			Items.CalculatedCompanies.ToolTip = Items.CalculatedCompanies.ToolTip
				+ Chars.LF + TrimAll(CurOrganization);
		EndDo;
		
	Else
		
		Items.CalculatedCompanies.ToolTip = False;
		Items.CalculatedCompanies.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_PreliminaryMonthEndClosingDate" Then
		EndDateOnChange(Items.PreliminaryMonthEndClosingDate);
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
