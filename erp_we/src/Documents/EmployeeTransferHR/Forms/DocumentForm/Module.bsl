#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	CancelAccrualATServer();
	CancelRetentionATServer();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject, True);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	FillInCalculatedData();
	
	FormControl();
	
	SetUpRegistrationForm();
	
	If Parameters.Key.IsEmpty() Then
		FillInCurrentAssignmentATServer();
	EndIf;
	
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
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	DocumentsPayrollAndHumanResourcesServer.FillInCalculationProcedureForAccrualTable(Object.Accruals, Object.Currency);
	DocumentsPayrollAndHumanResourcesServer.FillInProcedureForCalculatingRetentionTable(Object.Deductions, Object.Currency);

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
Procedure EmployeeOnChange(Item)

	FillInCurrentAssignmentATServer();
	ManagingItemAvailability();

EndProcedure

&AtClient
Procedure DateOfTransitionOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	FillInCurrentAssignmentATServer();
	ManagingItemAvailability();

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)

	FillInCurrentAssignmentATServer();
	ManagingItemAvailability();
	FillCurrency();

EndProcedure

&AtClient
Procedure NewAccrualOnChange(Item)

	ManagingItemAvailability();
	BasicAccrualOnChangeATServer()

EndProcedure

&AtClient
Procedure EmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)

	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Period", BegOfDay(Object.DateOfTransition)); 
	ParametersForOpeningSelection.Insert("ItWorks", True);
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.Employee);
	
EndProcedure

&AtClient
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", BegOfMonth(Object.DateOfTransition));
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure ReflectionInAccounting_PresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Item = Items.ReflectionInAccounting_Presentation
		And CheckFilling() Then   
		
		FormParameters = GetDisplayParameters();
		FormParameters.FilterDate = Object.DateOfTransition;
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
	
	ManagingAvailabilityOfAccrualItems(CurrentRow);

EndProcedure

&AtClient
Procedure AccrualsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "AccrualsNewValue" Then
		CurrentRow = Items.Accruals.CurrentData;
			
		ManagingAvailabilityOfAccrualItems(CurrentRow);
	EndIf;
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
		FormParameters.FilterDate = Object.DateOfTransition;
		FormParameters.TypeOfAccrualDeduction = CurrentData.Accrual;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = Object.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
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

EndProcedure

&AtClient
Procedure DeductionsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "RetentionValueIsNew" Then
		CurrentRow = Items.Deductions.CurrentData;
			
		If CurrentRow = Undefined Then
			Return;
		Else
			ManagingAvailabilityOfRetentionItems(CurrentRow);
		EndIf
	EndIf;
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
		FormParameters.FilterDate = Object.DateOfTransition;
		FormParameters.TypeOfAccrualDeduction = CurrentData.Retention;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = Object.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
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

&AtClient
Procedure CancelHold(Command)

	CancelAccrualOfDeductionsATServer(True);

EndProcedure

&AtClient
Procedure CancelAccrual(Command)

	CancelAccrualOfDeductionsATServer(False);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	Font = New Font(, , True) ;

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DivisionIsNew.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Department");
	ItemFilter.RightValue = New DataCompositionField("Object.BusinessUnitOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.JobTitleNew.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.JobTitle");
	ItemFilter.RightValue = New DataCompositionField("Object.JobTitleOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WorkScheduleIsNew.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.WorkScheduleCalendar");
	ItemFilter.RightValue = New DataCompositionField("Object.WorkScheduleOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TypeOfEmploymentNew.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EmploymentKind");
	ItemFilter.RightValue = New DataCompositionField("Object.EmploymentKindOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndDateOfContractIsNew.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractEndDate");
	ItemFilter.RightValue = New DataCompositionField("Object.ContractEndDateOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NewAccrual.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BasicAccrual");
	ItemFilter.RightValue = New DataCompositionField("Object.BasicAccrualOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NewValue_.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BaseValue");
	ItemFilter.RightValue = New DataCompositionField("Object.BasicValueOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TimeKindForNorms.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TimeKindForNorms");
	ItemFilter.RightValue = New DataCompositionField("Object.PayCodeOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdvancePaymentNew.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Prepayment_");
	ItemFilter.RightValue = New DataCompositionField("Object.AdvancePaymentOld");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;	
	
	Item.Appearance.SetParameterValue("Font", Font);
	
EndProcedure

&AtServer
Function GetDisplayParameters()
	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.DisplayParameters();
EndFunction	

&AtServer
Procedure SetUpRegistrationForm(UpdateInHeader = True, UpdateInAccruals = True, UpdateInDeductions = True) 
	
	Documents.EmployeeTransferHR.SetUpRegistrationForm(ThisObject, UpdateInHeader, UpdateInAccruals, UpdateInDeductions);
	
EndProcedure   

&AtServer
Procedure FormControl()
	
	Items.TimeKindForNorms.AutoMarkIncomplete 
		= DocumentsPayrollAndHumanResourcesServer.ForThisAccrualYouNeedStandardHours(Object.BasicAccrual);
	
EndProcedure	

&AtServer
Procedure BasicAccrualOnChangeATServer()
	
	Object.TimeKindForNorms = 
				Common.ObjectAttributeValue(Object.BasicAccrual, "PayCode");
	
	FillInCalculatedData();
	
	FormControl();
	
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

	Items.NewValue_.Enabled = Not NewValueAvailability;

	If NewValueAvailability Then
		Object.BaseValue = 0;
	EndIf;
	
	AdvancePaymentAvailability = CheckAvailabilityOfAdvanceServer(Object.BasicAccrual, True);
	
	Items.AdvancePaymentNew.Enabled = AdvancePaymentAvailability; 
	
	If Not AdvancePaymentAvailability Then
		 Object.Prepayment_ = 0;
	EndIf;

EndProcedure

&AtClient
Procedure ManagingAvailabilityOfAccrualItems(CurrentRow)
	
	AccessibilityValue_ = CheckAvailabilityOfServerValue(CurrentRow.Accrual, False);
	
	Items.AccrualsNewValue.ReadOnly = AccessibilityValue_; 
	
	If AccessibilityValue_ Then
		 CurrentRow.Value = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ManagingAvailabilityOfRetentionItems(CurrentRow)
	
	AccessibilityValue_ = CheckAvailabilityOfServerValue(CurrentRow.Retention, False);
	
	Items.RetentionValueIsNew.ReadOnly = AccessibilityValue_; 
	
	If AccessibilityValue_ Then
		 CurrentRow.Value = 0;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckAvailabilityOfServerValue(BasicAccrual, BasicEarnings)

	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(BasicAccrual, BasicEarnings);

EndFunction

&НасервереБезКонтекста
Function CheckAvailabilityOfAdvanceServer(BasicAccrual, BasicEarnings)
	
	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAdvanceServer(BasicAccrual, BasicEarnings);
	
EndFunction

&AtServer
Procedure CancelAccrualOfDeductionsATServer(ItIsADeduction)
		
	If ItIsADeduction Then
		TableOfAccrualsOfDeductions = Object.Deductions;
	Else
		TableOfAccrualsOfDeductions = Object.Accruals;
	EndIf;

	DocumentBorder = New Boundary(New PointInTime(Object.DateOfTransition, Object.Ref), BoundaryType.Excluding);

	OperationalAccountingOfManufacturingPayrollAndHumanResources.FillInTableWithAccrualsOrDeductionsAsOfDate(TableOfAccrualsOfDeductions,
		ItIsADeduction, Object.Employee, Object.BusinessUnitOld, Object.Organization, DocumentBorder, Object.Currency);
		
	SetUpRegistrationForm(False, Not ItIsADeduction, ItIsADeduction);  
	
EndProcedure

&AtServer
Procedure FillInCurrentAssignmentATServer()

	SliceDate = ?(ValueIsFilled(Object.DateOfTransition), Object.DateOfTransition, CurrentSessionDate());

	AssignmentStructure = OperationalAccountingOfManufacturingPayrollAndHumanResources.PersonnelHistoryOfEmployee(Object.Organization,
		Object.Employee, SliceDate);

	Object.BusinessUnitOld			 = AssignmentStructure.Department;
	Object.JobTitleOld				 = AssignmentStructure.JobTitle;
	Object.WorkScheduleOld			 = AssignmentStructure.WorkScheduleCalendar;
	Object.EmploymentKindOld			 = AssignmentStructure.EmploymentKind;
	Object.ContractEndDateOld	 = AssignmentStructure.EndDate;
	Object.BasicAccrualOld		 = AssignmentStructure.AccrualDeduction;
	Object.BasicValueOld		 = AssignmentStructure.ValueOfAccrualAndDeduction;
	Object.AdvancePaymentOld					 = AssignmentStructure.Prepayment_;
	Object.PayCodeOld		 = AssignmentStructure.TimeKindForNorms;

	Object.Department			= AssignmentStructure.Department;
	Object.JobTitle				= AssignmentStructure.JobTitle;
	Object.WorkScheduleCalendar			 	= AssignmentStructure.WorkScheduleCalendar;
	Object.EmploymentKind			 	= AssignmentStructure.EmploymentKind;
	Object.ContractEndDate	= AssignmentStructure.EndDate;
	Object.BasicAccrual		= AssignmentStructure.AccrualDeduction;
	Object.BaseValue		 	= AssignmentStructure.ValueOfAccrualAndDeduction;
	Object.Prepayment_					= AssignmentStructure.Prepayment_;
	Object.TimeKindForNorms		= AssignmentStructure.TimeKindForNorms;
	
	SetUpRegistrationForm();
	
EndProcedure

&AtServer
Procedure FillCurrency()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
EndProcedure

&AtServer
Procedure FillInCalculatedData()

	Items.Accrual.ToolTip = DocumentsPayrollAndHumanResourcesServer.AccrualCalculationProcedure(Object.BasicAccrualOld, Object.Currency);
	Items.NewAccrual.ToolTip = DocumentsPayrollAndHumanResourcesServer.AccrualCalculationProcedure(Object.BasicAccrual, Object.Currency); 
		
EndProcedure

&AtServer
Procedure CancelAccrualATServer()

	DocumentsPayrollAndHumanResourcesServer.FillInCalculationProcedureForAccrualTable(Object.Accruals, Object.Currency);

EndProcedure

&AtServer
Procedure CancelRetentionATServer()

	DocumentsPayrollAndHumanResourcesServer.FillInProcedureForCalculatingRetentionTable(Object.Deductions, Object.Currency);

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
	If Item.Name = "sh_ShamsiInput_DateOfTransition" Then
		DateOfTransitionOnChange(Items.DateOfTransition);
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
