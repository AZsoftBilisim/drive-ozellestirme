#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.Organization) Then
		Object.Organization = Catalogs.Companies.DefaultCompany();
	EndIf;	
	
	If Not ValueIsFilled(Object.Currency) Then
		
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
	EndIf;	
	
	FillInAdditionalDetailsOfForm();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject, False);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	SetUpRegistrationForm();
	
	SetConditionalAppearance();
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "DataWasSavedToRegisterOfReflectionInAccounting" Then  
		SetUpRegistrationForm();
	EndIf;

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Record_ManualCalculationOfTaxes", WriteParameters, Object.Ref);
	
	FillInAdditionalDetailsOfForm();
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetUpRegistrationForm();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OnChangingCompanyATServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	Object.EmployeeTaxIsAccrued.Clear(); 
	
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
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		Object.RegistrationMonth = SelectedPeriod;
		MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
		
	EndIf;
	
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
Procedure MonthOfRegistrationByLineClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TaxKindOnChange(Item)

	OnChangingTypeOfTaxATServer();
	
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

#Region FormTableItemsEventHandlersEmployeeTaxIsAccrued   

&AtClient
Procedure EmployeeTaxIsAccruedChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	For Each CurrentValue In ValueSelected Do
	
		NewRow = Object.EmployeeTaxIsAccrued.Add();
		NewRow.Employee = CurrentValue;
	
	EndDo;
	
EndProcedure

&AtClient
Procedure EmployeeTaxIsAccruedSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.EmployeeTaxIsAccrued.CurrentData;
	
	If Field = Items.EmployeeTaxIsAccruedReflectionInAccounting_Presentation Then  

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
		FormParameters.TypeOfAccrualDeduction = Object.TaxKind;	
		FormParameters.Employee = CurrentData.Employee;	
		FormParameters.Department = Object.Department;	
		FormParameters.DocumentCalculation = Object.Ref;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().ManualTaxLevel;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeTaxIsAccruedOnStartEdit(Item, NewRow, Copy)
	
	SetUpRegistrationForm();
	
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
Procedure SelectionOfEmployee(Command)

	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.RegistrationMonth);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfMonth(Object.RegistrationMonth));
	ParametersForOpeningSelection.Insert("MultipleChoice", True);
	ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees());
	
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection,
					Items.EmployeeTaxIsAccrued);
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// EmployeeTaxIsAccruedReflectionInAccounting_Presentation	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeeTaxIsAccruedReflectionInAccounting_Presentation.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReflectionInAccountingIsCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);

	// EmployeeTaxIsAccruedReflectionInAccounting_Presentation	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeeTaxIsAccruedReflectionInAccounting_Presentation.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeductedFromEmployeeWages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure SetUpRegistrationForm() 
	
	Documents.ManualTaxCalculation.SetUpRegistrationForm(ThisObject);
	
EndProcedure   

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(Object.EmployeeTaxIsAccrued.Unload( ,
		"Employee").UnloadColumn("Employee"));
	Return PutToTempStorage(Selected_Employees, UUID);

EndFunction

&AtServer
Procedure FillInAdditionalDetailsOfForm()
		
	MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
	
	OnChangingTypeOfTaxATServer();
	
EndProcedure	

&AtServer
Procedure OnChangingTypeOfTaxATServer()
	
	If Not ValueIsFilled(Object.TaxKind) Then
		Items.TaxKindExtendedTooltip.Title = "";
		Return;
	EndIf;	
	
	DeductedFromEmployeeWages = Common.ObjectAttributeValue(Object.TaxKind, "DeductedFromEmployeeWages");

	TtleText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'Налог удерживается с %1';
										|vi = 'Tax is withheld from %1';
										|en = 'Tax is withheld from %1'; fa = 'Tax is withheld from %1';
										|it = 'Tax is withheld from %1';
										|pl = 'Tax is withheld from %1';
										|tr = 'Vergi şu taraftan kesilir: %1'"), 
									?(DeductedFromEmployeeWages, NStr("ru = 'сотрудника';
																		|vi = 'of employee';
																		|en = 'of employee'; fa = 'of employee';
																		|it = 'of employee';
																		|pl = 'of employee';
																		|tr = 'çalışan'"), NStr("ru = 'организации';
																									|vi = 'companies';
																									|en = 'companies'; fa = 'companies';
																									|it = 'companies';
																									|pl = 'companies';
																									|tr = 'iş yeri'")), ", ");
	
	Items.TaxKindExtendedTooltip.Title = TtleText;
	
EndProcedure	

&AtServer
Procedure OnChangingCompanyATServer()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Object.EmployeeTaxIsAccrued.Clear(); 
	Object.Department = Catalogs.BusinessStructure.EmptyRef();
	
EndProcedure	

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ControlLevels = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels();
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Not DeductedFromEmployeeWages Then
		
		ControlParameters = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetControlParameters();
		
		For Each CurrentLineTaxAccruedToEmployees In Object.EmployeeTaxIsAccrued Do
			
			ControlParameters.TypeOfAccrualDeduction = Object.TaxKind; 
			ControlParameters.Department = Object.Department; 
			ControlParameters.DocumentCalculation = Object.Ref; 
			ControlParameters.Employee = CurrentLineTaxAccruedToEmployees.Employee; 
			ControlParameters.DateOfControl = Object.RegistrationMonth; 
			ControlParameters.ControlLevel = ControlLevels.ManualTaxLevel;
			
			ErrorsArray = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.CheckCompletionOfReflectionInAccounting(ControlParameters);	
			
			For Each CurrentValueOfArray In ErrorsArray Do
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка заполнения отражения в учете: %1';
					|vi = 'Error filling in posting in accounting: %1';
					|en = 'Error filling in posting in accounting: %1'; fa = 'Error filling in posting in accounting: %1';
					|it = 'Error filling in posting in accounting: %1';
					|pl = 'Error filling in posting in accounting: %1';
					|tr = 'Muhasebeleştirme doldurma hatası: %1'"), CurrentValueOfArray);
				
				Common.MessageToUser(ErrorText,, "RecordingSettingPresentation",, Cancel);
				
			EndDo;	
			
		EndDo;
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
