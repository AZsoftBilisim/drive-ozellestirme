#Region Variables

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);  
	
	FillInCalculatedData();
	
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject, False);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	FormControl();
	
	SetUpRegistrationForm();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", True);

	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	DocumentsPayrollAndHumanResourcesServer.FillInCalculationProcedureForAccrualTable(Object.Accruals, Object.Currency);
	DocumentsPayrollAndHumanResourcesServer.FillInProcedureForCalculatingRetentionTable(Object.Deductions, Object.Currency);
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	SetUpRegistrationForm();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	ManagingItemAvailability();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DataWasSavedToRegisterOfReflectionInAccounting" Then  
		SetUpRegistrationForm();
	EndIf;
	
	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.NotificationProcessing(ThisObject, Object.Ref, EventName, Parameter, 
		Source);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion  

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BasicAccrualOnChange(Item)
	
	ManagingItemAvailability();
	
	BasicAcrualOnChangeATServer();
	
EndProcedure

&AtClient
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", BegOfMonth(Object.DateOfAdmission));
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure EmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Period", BegOfDay(Object.DateOfAdmission));
	ParametersForOpeningSelection.Insert("ItWorks", False);
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.Employee);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	FillCurrency();
	
EndProcedure

&AtClient
Procedure SettingUpReflectionInAccountingPresentationClick(Item, StandardProcessing)

	StandardProcessing = False;
	
	If Item = Items.ReflectionInAccounting_Presentation
		And CheckFilling() Then   
		
		FormParameters = GetDisplayParameters();
		FormParameters.FilterDate = Object.DateOfAdmission;
		FormParameters.TypeOfAccrualDeduction = Object.BasicAccrual;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = Object.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettings(ThisObject, FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsAccrualOnChange(Item)

	CurrentRow = Items.Accruals.CurrentData;
	
	If CurrentRow = Undefined Then 
		Return;
	EndIf;
	
	CurrentRow.ValueDescription = ProcedureForCalculatingAccrualByLineATServer(CurrentRow.Accrual);
	
	SetUpRegistrationForm();	
	
EndProcedure

&AtClient
Procedure AccrualsSelection(Item, RowSelected, Field, StandardProcessing)


	If Field = Items.AccrualsReflectionInAccounting_Presentation Then  
		
		If Not FormDataIsBlocked
			And Not ReadOnly Then  
			If Not CheckFilling() Then
				Return;
			EndIf;	
		EndIf;	

		StandardProcessing = False;
		
		CurrentData = Items.Accruals.CurrentData;
		
		FormParameters = GetDisplayParameters();
		FormParameters.FilterDate = Object.DateOfAdmission;
		FormParameters.TypeOfAccrualDeduction = CurrentData.Accrual;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = Object.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "AccrualsValue" Then
		CurrentRow = Items.Accruals.CurrentData;
			
		ManagingAvailabilityOfAccrualItems(CurrentRow);
	EndIf;
		
EndProcedure

&AtClient
Procedure AccrualsOnStartEdit(Item, NewRow, Copy)
	
	SetUpRegistrationForm(False, True, False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDeductions

&AtClient
Procedure DeductionsRetentionOnChange(Item)

	CurrentRow = Items.Deductions.CurrentData;
	
	If CurrentRow = Undefined Then 
		Return;
	EndIf;
	
	CurrentRow.ValueDescription = ProcedureForCalculatingRetentionByLineATServer(CurrentRow.Retention);
	
	SetUpRegistrationForm();	
	
EndProcedure

&AtClient
Procedure DeductionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.DeductionsReflectionInAccounting_Presentation Then  
		
		If Not FormDataIsBlocked
			And Not ReadOnly Then  
			If Not CheckFilling() Then
				Return;
			EndIf;	
		EndIf;	
		
		StandardProcessing = False;
		
		CurrentData = Items.Deductions.CurrentData;
		
		FormParameters = GetDisplayParameters();
		FormParameters.FilterDate = Object.DateOfAdmission;
		FormParameters.TypeOfAccrualDeduction = CurrentData.Retention;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = Object.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeductionsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "DeductionsValue" Then
		CurrentRow = Items.Deductions.CurrentData;
			
		If CurrentRow = Undefined Then
			Return;
		Else
			ManagingAvailabilityOfRetentionItems(CurrentRow);
		EndIf
	EndIf;
EndProcedure

&AtClient
Procedure DeductionsOnStartEdit(Item, NewRow, Copy)
	
	SetUpRegistrationForm(False, False, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetDisplayParameters()
	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.DisplayParameters();
EndFunction	

&AtServer
Procedure SetUpRegistrationForm(UpdateInHeader = True, UpdateInAccruals = True, UpdateInDeductions = True) 
	
	Documents.HiringHR.SetUpRegistrationForm(ThisObject, UpdateInHeader, UpdateInAccruals, UpdateInDeductions);
	
EndProcedure   

&AtServer
Procedure BasicAcrualOnChangeATServer()
	
	Object.TimeKindForNorms = 
				Common.ObjectAttributeValue(Object.BasicAccrual, "PayCode");
	
	FillInCalculatedData();
	
	SetUpRegistrationForm();	
	
	FormControl();
	
EndProcedure	

&AtServer
Procedure FormControl()
	
	Items.TimeKindForNorms.AutoMarkIncomplete 
		= DocumentsPayrollAndHumanResourcesServer.ForThisAccrualYouNeedStandardHours(Object.BasicAccrual);
	
EndProcedure	

&AtServer
Function ProcedureForCalculatingAccrualByLineATServer(Accrual)
	
	Return DocumentsPayrollAndHumanResourcesServer.DetermineProcedureForCalculatingAccrualByLine(Accrual, Object.Currency);	
	
EndFunction	

&AtServer
Function ProcedureForCalculatingRetentionByLineATServer(Accrual)
	
	Return DocumentsPayrollAndHumanResourcesServer.DetermineOrderOfCalculationOfRetentionByLine(Accrual, Object.Currency);	
	
EndFunction

&AtClient
Procedure ManagingItemAvailability()
	
	NewValueAvailability = CheckAvailabilityOfServerValue(Object.BasicAccrual, True);
	
	Items.Value.Enabled = Not NewValueAvailability; 
	
	If NewValueAvailability Then
		 Object.BaseValue = 0;
	EndIf;
	
	AdvancePaymentAvailability = CheckAvailabilityOfAdvanceServer(Object.BasicAccrual, True);
	
	Items.Prepayment_.Enabled = AdvancePaymentAvailability; 
	
	If Not AdvancePaymentAvailability Then
		 Object.Prepayment_ = 0;
	EndIf;
	
EndProcedure   

&НасервереБезКонтекста
Function CheckAvailabilityOfServerValue(BasicAccrual, BasicEarnings)
	
	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(BasicAccrual, BasicEarnings);	
	
EndFunction

&НасервереБезКонтекста
Function CheckAvailabilityOfAdvanceServer(BasicAccrual, BasicEarnings)
	
	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAdvanceServer(BasicAccrual, BasicEarnings);	
	
EndFunction

&AtServer
Procedure FillInCalculatedData()
	
	DocumentsPayrollAndHumanResourcesServer.FillInCalculationProcedureForAccrualTable(Object.Accruals, Object.Currency);
	DocumentsPayrollAndHumanResourcesServer.FillInProcedureForCalculatingRetentionTable(Object.Deductions, Object.Currency);
	
	Items.BasicAccrual.ToolTip = DocumentsPayrollAndHumanResourcesServer.AccrualCalculationProcedure(Object.BasicAccrual, Object.Currency); 
		
EndProcedure

&AtServer
Procedure FillCurrency()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
EndProcedure

&AtClient
Procedure ManagingAvailabilityOfAccrualItems(CurrentRow)
	
	AccessibilityValue_ = CheckAvailabilityOfServerValue(CurrentRow.Accrual, False);
	
	Items.AccrualsValue.ReadOnly = AccessibilityValue_; 
	
	If AccessibilityValue_ Then
		 CurrentRow.Value = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ManagingAvailabilityOfRetentionItems(CurrentRow)
	
	AccessibilityValue_ = CheckAvailabilityOfServerValue(CurrentRow.Retention, False);
	
	Items.DeductionsValue.ReadOnly = AccessibilityValue_; 
	
	If AccessibilityValue_ Then
		 CurrentRow.Value = 0;
	EndIf;
	
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
