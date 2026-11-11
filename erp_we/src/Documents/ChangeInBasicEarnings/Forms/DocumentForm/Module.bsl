#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing) 
	
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
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetUpRegistrationForm();	
	
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
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", BegOfMonth(Object.ChangeDate));
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	FillCurrency();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBasicEarnings

&AtClient
Procedure BasicEarningsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ArrayOfVHFEmployeesBasicEarnings = Object.BasicEarnings.FindRows(New Structure("Employee", 
														PredefinedValue("Catalog.EmployeesHR.EmptyRef")));
			
	For Each ArrayElement In ArrayOfVHFEmployeesBasicEarnings Do
		Object.BasicEarnings.Delete(ArrayElement.LineNumber - 1);	
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("Employee", ValueSelected);
	StructureOfActions.Insert("Organization", Object.Organization);
	StructureOfActions.Insert("Department", Object.Department);
	StructureOfActions.Insert("ChangeDate", Object.ChangeDate);
	StructureOfActions.Insert("Ref", Object.Ref);
	
	MainEarningsOfEmployeeOnChangeATServer(StructureOfActions);

EndProcedure  

&AtClient
Procedure BasicEarningsEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("ru = 'Не заполнено поле ""Организация"".';
										|vi = 'Fill in the ""Company"" field.';
										|en = 'Fill in the ""Company"" field.'; fa = 'Fill in the ""Company"" field.';
										|it = 'Fill in the ""Company"" field.';
										|pl = 'Fill in the ""Company"" field.';
										|tr = '""İş yeri"" alanı doldurulmamış.'"), Object.Ref,
			"Organization", "Object.Organization", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Department) Then
		CommonClient.MessageToUser(NStr("ru = 'Не заполнено поле ""Подразделение"".';
										|vi = '""Business unit"" is required.';
										|en = '""Business unit"" is required.'; fa = '""Business unit"" is required.';
										|it = '""Business unit"" is required.';
										|pl = '""Business unit"" is required.';
										|tr = '""Departman"" alanı doldurulmamış.'"), Object.Ref,
			"Department", "Object.Department", Cancel);
	EndIf;
	
	If Not Cancel Then
		ParametersForOpeningSelection = New Structure();
		ParametersForOpeningSelection.Insert("Organization", Object.Organization);
		ParametersForOpeningSelection.Insert("Department", Object.Department);
		ParametersForOpeningSelection.Insert("Period", BegOfDay(Object.ChangeDate));
		ParametersForOpeningSelection.Insert("ItWorks", True);
		ParametersForOpeningSelection.Insert("MultipleChoice", False);
		DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.BasicEarnings);
	EndIf;
	
EndProcedure

&AtClient
Procedure BasicEarningsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "BasicEarningsNewValue_"
		Or Item.CurrentItem.Name = "BasicEarningsAdvancePaymentNew" Then
		CurrentRow = Items.BasicEarnings.CurrentData;
			
		ManagingAvailabilityOfAccrualItems(CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure BasicEarningsSelection(Item, RowSelected, Field, StandardProcessing)

	If Field = Items.BasicEarningsReflectionInAccountingPresentationNew Then  
		If Not FormDataIsBlocked
			And Not ReadOnly Then  
			If Not CheckFilling() Then
				Return;
			EndIf;	
		EndIf;	

		StandardProcessing = False;
		
		CurrentData = Items.BasicEarnings.CurrentData;
		
		FormParameters = GetDisplayParameters();
		FormParameters.FilterDate = Object.ChangeDate;
		FormParameters.TypeOfAccrualDeduction = CurrentData.Accrual;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = CurrentData.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure BasicEarningsOnStartEdit(Item, NewRow, Copy)

	 SetUpRegistrationForm();
	
EndProcedure

&AtClient
Procedure BasicEarningsEmployeeOnChange(Item)
	
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
Procedure Pickup(Command)
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("ru = 'Не заполнено поле ""Организация"".';
										|vi = 'Fill in the ""Company"" field.';
										|en = 'Fill in the ""Company"" field.'; fa = 'Fill in the ""Company"" field.';
										|it = 'Fill in the ""Company"" field.';
										|pl = 'Fill in the ""Company"" field.';
										|tr = '""İş yeri"" alanı doldurulmamış.'"), Object.Ref, 
															"Organization", "Object.Organization", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Department) Then
		CommonClient.MessageToUser(NStr("ru = 'Не заполнено поле ""Подразделение"".';
										|vi = '""Business unit"" is required.';
										|en = '""Business unit"" is required.'; fa = '""Business unit"" is required.';
										|it = '""Business unit"" is required.';
										|pl = '""Business unit"" is required.';
										|tr = '""Departman"" alanı doldurulmamış.'"), Object.Ref, 
															"Department", "Object.Department", Cancel);
	EndIf;
														
	If Not Cancel Then
		ParametersForOpeningSelection = New Structure();
		ParametersForOpeningSelection.Insert("Organization", Object.Organization);
		ParametersForOpeningSelection.Insert("Department", Object.Department);
		ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", BegOfDay(Object.ChangeDate));
		ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfDay(Object.ChangeDate));
		ParametersForOpeningSelection.Insert("MultipleChoice", True);
		ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees());
		
		DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.BasicEarnings);
	EndIf;
	
EndProcedure

#EndRegion 

#Region Private

&AtServer
Function GetDisplayParameters()
	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.DisplayParameters();
EndFunction	

&AtServer
Procedure SetUpRegistrationForm() 
	
	Documents.ChangeInBasicEarnings.SetUpRegistrationForm(ThisObject);
	
EndProcedure   

&AtServerNoContext
Function CheckAvailabilityOfServerValue(BasicAccrual)

	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(BasicAccrual, True);

EndFunction

&НасервереБезКонтекста
Function CheckAvailabilityOfAdvanceServer(BasicAccrual, BasicEarnings)
	
	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAdvanceServer(BasicAccrual, BasicEarnings);	
	
EndFunction

&AtClient
Procedure ManagingAvailabilityOfAccrualItems(CurrentRow)
	
	AccessibilityValue_ = CheckAvailabilityOfServerValue(CurrentRow.Accrual);
	
	Items.BasicEarningsNewValue_.ReadOnly = AccessibilityValue_;
	
	If AccessibilityValue_ Then
		 CurrentRow.Value = 0;
	EndIf;
	
	AdvancePaymentAvailability = CheckAvailabilityOfAdvanceServer(CurrentRow.Accrual, True);
	
	Items.BasicEarningsAdvancePaymentNew.ReadOnly = Not AdvancePaymentAvailability;
	
	If Not AdvancePaymentAvailability Then
		 CurrentRow.AdvancePaymentNew = 0;
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(
	Object.BasicEarnings.Unload( , "Employee").UnloadColumn("Employee"));
	Return PutToTempStorage(Selected_Employees, UUID);

EndFunction 

&AtServer
Procedure FillCurrency()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
EndProcedure

&AtServer
Procedure MainEarningsOfEmployeeOnChangeATServer(StructureOfActions)
	
	Query = New Query(
	"SELECT
	|	EmployeesHR.Ref AS Employee
	|INTO TT_EmployeesHR
	|FROM
	|	Catalog.EmployeesHR AS EmployeesHR
	|WHERE
	|	EmployeesHR.Ref IN(&EmployeesHR)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee AS Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction AS Accrual,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS Value,
	|	RegularAccrualsAndDeductionsHRSliceLast.Period AS Period,
	|	RegularAccrualsAndDeductionsHRSliceLast.TimeKindForNorms AS TimeKindForNorms,
	|	RegularAccrualsAndDeductionsHRSliceLast.Prepayment_ AS Prepayment_
	|INTO TT_RegularAccrualsAndDeductionsHR
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&SliceDate,
	|			Employee IN
	|					(SELECT
	|						TT_EmployeesHR.Employee
	|					FROM
	|						TT_EmployeesHR)
	|				AND Organization = &Organization
	|				AND Department = &Department) AS RegularAccrualsAndDeductionsHRSliceLast
	|WHERE
	|	RegularAccrualsAndDeductionsHRSliceLast.Valid
	|	AND RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_EmployeesHR.Employee AS Employee,
	|	ISNULL(TT_RegularAccrualsAndDeductionsHR.Accrual, UNDEFINED) AS Accrual,
	|	ISNULL(TT_RegularAccrualsAndDeductionsHR.Value, UNDEFINED) AS Value,
	|	ISNULL(TT_RegularAccrualsAndDeductionsHR.Prepayment_, UNDEFINED) AS Prepayment_,
	|	ISNULL(TT_RegularAccrualsAndDeductionsHR.Period, UNDEFINED) AS Period,
	|	TT_RegularAccrualsAndDeductionsHR.TimeKindForNorms AS TimeKindForNorms,
	|	TT_RegularAccrualsAndDeductionsHR.TimeKindForNorms AS PayCodeNew
	|FROM
	|	TT_EmployeesHR AS TT_EmployeesHR
	|		LEFT JOIN TT_RegularAccrualsAndDeductionsHR AS TT_RegularAccrualsAndDeductionsHR
	|		ON TT_EmployeesHR.Employee = TT_RegularAccrualsAndDeductionsHR.Employee
	|
	|ORDER BY
	|	Period DESC
	|TOTALS BY
	|	Employee"); 
	
	Query.SetParameter("SliceDate", New Boundary(New PointInTime(StructureOfActions.ChangeDate, StructureOfActions.Ref), 
																														BoundaryType.Excluding));
	Query.SetParameter("Organization", StructureOfActions.Organization);
	Query.SetParameter("Department", StructureOfActions.Department);
	Query.SetParameter("EmployeesHR", StructureOfActions.Employee);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
			
		SampleEmployee = QueryResult.Select(QueryResultIteration.ByGroups); 
		
		While SampleEmployee.Next() Do
			
			Selection = SampleEmployee.Select(); 
			
			Selection.Next();
			
			If Not Selection.Value = Undefined Then
			
				Page1 = Object.BasicEarnings.Add();
			
				FillPropertyValues(Page1, Selection);
				
				Page1.DescriptionOfAccrual = DocumentsPayrollAndHumanResourcesServer.AccrualCalculationProcedure(Selection.Accrual, Object.Currency);
				
			Else
				Text = StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"ru = 'По сотруднику ""%1"" не найдено основное начисление';
					|vi = 'No main accrual is found for employee %1';
					|en = 'No main accrual is found for employee %1'; fa = 'No main accrual is found for employee %1';
					|it = 'No main accrual is found for employee %1';
					|pl = 'No main accrual is found for employee %1';
					|tr = 'Çalışan ""%1"" için temel tahakkuk bulunamadı'"), Selection.Employee);

				Common.MessageToUser(Text, Object.Ref);
			EndIf;
		EndDo;	
	EndIf;
	
 	SetUpRegistrationForm();	
	
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
