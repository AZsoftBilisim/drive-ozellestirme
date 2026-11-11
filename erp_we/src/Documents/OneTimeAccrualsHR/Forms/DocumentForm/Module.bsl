
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInAdditionalDetailsOfForm();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject, False);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	SetUpRegistrationForm();	
	
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
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;     
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Recording_OneTimeAccrual", WriteParameters, Object.Ref);
	
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

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "DataWasSavedToRegisterOfReflectionInAccounting" Then  
		SetUpRegistrationForm();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetUpRegistrationForm();	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

&AtClient
Procedure OrganizationOnChange(Item)
	
	OnChangingCompanyATServer();
	
EndProcedure

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
Procedure AccrualOnChange(Item)
	
		OnChangeOfAccrualATServer();
	
	EndProcedure
	

&AtClient
Procedure DepartmentOnChange(Item)
	
		Object.AccruedByEmployees.Clear();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccruedByEmployees

&AtClient
Procedure AccruedByEmployeesSelection(Item, RowSelected, Field, StandardProcessing)

	CurrentData = Items.AccruedByEmployees.CurrentData;
	
	If Field = Items.AccruedByEmployeesReflectionInAccounting_Presentation Then

		If Not FormDataIsBlocked
			And Not ReadOnly Then  
			If Not CheckFilling() Then
				Return;
			Else
				Write();
			EndIf;	
		EndIf;	
		
		StandardProcessing = False;
		
		FormParameters = SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.GetDisplayParameters();
		FormParameters.FilterDate = Object.RegistrationMonth;
		FormParameters.TypeOfAccrualDeduction = Object.Accrual;	
		FormParameters.Employee = CurrentData.Employee;	
		FormParameters.Department = Object.Department;	
		FormParameters.DocumentCalculation = Object.Ref;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelOneTimeDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccruedByEmployeesChoiceProcessing(Item, ValueSelected, StandardProcessing)

	If Not ValueSelected = Undefined Then
		If TypeOf(ValueSelected) = Type("Array") Then
			For Each CurrentValue In ValueSelected Do
				NewRow = Object.AccruedByEmployees.Add();
				NewRow.Employee = CurrentValue;
			EndDo;
		ElsIf TypeOf(ValueSelected) = Type("CatalogRef.EmployeesHR") Then
			Item.CurrentData.Employee = ValueSelected;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccruedByEmployeesOnStartEdit(Item, NewRow, Copy)
	
	SetUpRegistrationForm();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickEmployees(Command)
	
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("WorkingForPeriod", True);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.RegistrationMonth);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfMonth(Object.RegistrationMonth));
	ParametersForOpeningSelection.Insert("MultipleChoice", True);
	ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees());
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.AccruedByEmployees);
	
EndProcedure

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

&AtServer
Procedure SetUpRegistrationForm() 
	
	Documents.OneTimeAccrualsHR.SetUpRegistrationForm(ThisObject);
	
EndProcedure   

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		Object.RegistrationMonth = SelectedPeriod;
		MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
		
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(Object.AccruedByEmployees.Unload( ,
		"Employee").UnloadColumn("Employee"));
	Return PutToTempStorage(Selected_Employees, UUID);

EndFunction

&AtServer
Procedure FillInAdditionalDetailsOfForm()
		
	MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
	
	OnChangeOfAccrualATServer();
	
EndProcedure	

&AtServer
Procedure OnChangeOfAccrualATServer()
	
	If Not ValueIsFilled(Object.Accrual) Then
		Items.AccrualExtendedTooltip.Title = "";
		Return;
	EndIf;	
	
	InputFrequency = Common.ObjectAttributeValue(Object.Accrual, "InputFrequency");
	TimeFenceOfAccrual = "";

	If InputFrequency = 1 Then
		TimeFenceOfAccrual = NStr("ru = 'постоянное';
									|vi = 'permanent';
									|en = 'permanent'; fa = 'permanent';
									|it = 'permanent';
									|pl = 'permanent';
									|tr = 'sürekli'");
	ElsIf InputFrequency = 2 Then	
		TimeFenceOfAccrual = NStr("ru = 'разовое, ежемесячное';
									|vi = 'one-time, monthly';
									|en = 'one-time, monthly'; fa = 'one-time, monthly';
									|it = 'one-time, monthly';
									|pl = 'one-time, monthly';
									|tr = 'tek seferlik, aylık'");
	ElsIf InputFrequency = 3 Then	
		TimeFenceOfAccrual = NStr("ru = 'разовое, нерегулярное';
									|vi = 'one-time, irregular';
									|en = 'one-time, irregular'; fa = 'one-time, irregular';
									|it = 'one-time, irregular';
									|pl = 'one-time, irregular';
									|tr = 'tek seferlik, düzensiz'");
	EndIf;

	TtleText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'Периодичность начисления: %1';
										|vi = 'Accrual frequency: %1';
										|en = 'Accrual frequency: %1'; fa = 'Accrual frequency: %1';
										|it = 'Accrual frequency: %1';
										|pl = 'Accrual frequency: %1';
										|tr = 'Tahakkuk sıklığı: %1'"),	TimeFenceOfAccrual, ", ");
	
	Items.AccrualExtendedTooltip.Title = TtleText;
	
EndProcedure	

&AtServer
Procedure OnChangingCompanyATServer()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Object.AccruedByEmployees.Clear(); 
	Object.Department = Catalogs.BusinessStructure.EmptyRef();
	
EndProcedure	

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure AccruedByEmployeesEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("WorkingForPeriod", True);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.RegistrationMonth);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfMonth(Object.RegistrationMonth));
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.AccruedByEmployees);

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
