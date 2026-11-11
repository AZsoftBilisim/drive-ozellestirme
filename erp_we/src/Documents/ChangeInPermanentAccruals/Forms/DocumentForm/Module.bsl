
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInAccrualDescription();
	
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
	
	ManagingItemAvailability();
	
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
Procedure AccrualOnChange(Item) 
	
	FillInAccrualDescription();
	ClearChangeTable();
	ManagingItemAvailability();
	
EndProcedure

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
	
	ClearChangeTable();
	FillCurrency();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	ClearChangeTable();

EndProcedure

&AtClient
Procedure ActionOnChange(Item)
	ManagingItemAvailability();
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersChangesTable 

&AtClient
Procedure ChangesTableChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ArrayOfVHFEmployeesTableOfChanges = Object.ChangesTable.FindRows(New Structure("Employee", 
														PredefinedValue("Catalog.EmployeesHR.EmptyRef")));
	
	For Each ArrayElement In ArrayOfVHFEmployeesTableOfChanges Do
		Object.ChangesTable.Delete(ArrayElement.LineNumber - 1);	
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("Employee", ValueSelected);
	StructureOfActions.Insert("Organization", Object.Organization);
	StructureOfActions.Insert("Department", Object.Department);
	StructureOfActions.Insert("ChangeDate", Object.ChangeDate);
	StructureOfActions.Insert("Ref", Object.Ref);
	StructureOfActions.Insert("Accrual", Object.Accrual);
			
	FillInPermanentAccrualsATServer(StructureOfActions);
	
EndProcedure 

&AtClient
Procedure ChangesTableEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing) 
	
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
										|tr = '""Birim"" alanı doldurulmamış.'"), Object.Ref, 
															"Department", "Object.Department", Cancel);
	EndIf;
														
	If Not Cancel Then
		
		ParametersForOpeningSelection = New Structure();
		ParametersForOpeningSelection.Insert("Organization", Object.Organization);
		ParametersForOpeningSelection.Insert("Department", Object.Department);
		ParametersForOpeningSelection.Insert("Period", BegOfDay(Object.ChangeDate));
		ParametersForOpeningSelection.Insert("ItWorks", True);
		ParametersForOpeningSelection.Insert("MultipleChoice", False);
		DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.ChangesTable);      
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangesTableOnStartEdit(Item, NewRow, Copy)
	
	SetUpRegistrationForm();
	
EndProcedure

&AtClient
Procedure ChangesTableSelection(Item, RowSelected, Field, StandardProcessing)

	If Field = Items.ChangesTableReflectionInAccountingPresentationNew Then  
		If Not FormDataIsBlocked
			And Not ReadOnly Then  
			If Not CheckFilling() Then
				Return;
			EndIf;	
		EndIf;	

		StandardProcessing = False;
		
		CurrentData = Items.ChangesTable.CurrentData;
		
		FormParameters = GetDisplayParameters();
		FormParameters.FilterDate = Object.ChangeDate;
		FormParameters.TypeOfAccrualDeduction = Object.Accrual;	
		FormParameters.Department = Object.Department;	
		FormParameters.Employee = CurrentData.Employee;	
		FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().LevelPersonnelDocuments;	
		FormParameters.EditingFormIsProhibited	= FormDataIsBlocked Or ReadOnly;	
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettingsInDocumentTable(ThisObject, FormParameters);
	EndIf;
	
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
										|tr = '""Birim"" alanı doldurulmamış.'"), Object.Ref, 
															"Department", "Object.Department", Cancel);
	EndIf;

	If Not Cancel Then
		ParametersForOpeningSelection = New Structure();
		ParametersForOpeningSelection.Insert("Organization", Object.Organization);
		ParametersForOpeningSelection.Insert("Department", Object.Department);
		ParametersForOpeningSelection.Insert("Period", BegOfDay(Object.ChangeDate));
		ParametersForOpeningSelection.Insert("ItWorks", True);
		ParametersForOpeningSelection.Insert("MultipleChoice", True);
		ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees());
		DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.ChangesTable);
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
	
	Documents.ChangeInPermanentAccruals.SetUpRegistrationForm(ThisObject);
	
EndProcedure   

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(
	Object.ChangesTable.Unload( , "Employee").UnloadColumn("Employee"));
	Return PutToTempStorage(Selected_Employees, UUID);

EndFunction 

&AtServer
Procedure FillCurrency()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
EndProcedure

&AtClient
Procedure ManagingItemAvailability()
	
	If Object.Action = PredefinedValue("Enum.CompensationPlanActionsPayrollAndHumanResources.Cancel") Then
		Items.ChangesTableValue.Enabled = False;
		Items.ChangesTableNewValue_.Enabled = False; 
	Else	
		NewValueAvailability = CheckAvailabilityOfServerValue(Object.Accrual);
	
		Items.ChangesTableValue.Enabled = Not NewValueAvailability;
		Items.ChangesTableNewValue_.Enabled = Not NewValueAvailability; 
	EndIf;
	
EndProcedure 

&AtServerNoContext
Function CheckAvailabilityOfServerValue(BasicAccrual)
	
	Return DocumentsPayrollAndHumanResourcesServer.MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(BasicAccrual, False);	
	
EndFunction

&AtClient
Procedure ClearChangeTable()
	
	Object.ChangesTable.Clear();
	
EndProcedure

&AtServer
Procedure FillInPermanentAccrualsATServer(StructureOfActions)
	
	Query = New Query(
	"SELECT
	|	EmployeesHR.Ref AS Employee
	|INTO TT_EmployeesHR
	|FROM
	|	Catalog.EmployeesHR AS EmployeesHR
	|WHERE
	|	EmployeesHR.Ref IN (&EmployeesHR)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee AS Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS Value
	|INTO TT_RegularAccrualsAndDeductionsHR
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(&SliceDate, Employee IN
	|		(SELECT
	|			Employee
	|		FROM
	|			TT_EmployeesHR)
	|	AND Organization = &Organization
	|	AND Department = &Department
	|	AND AccrualDeduction = &Accrual) AS RegularAccrualsAndDeductionsHRSliceLast
	|WHERE
	|	RegularAccrualsAndDeductionsHRSliceLast.Valid
	|	AND NOT RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_EmployeesHR.Employee AS Employee,
	|	ISNULL(TT_RegularAccrualsAndDeductionsHR.Value, UNDEFINED) AS Value
	|FROM
	|	TT_EmployeesHR AS TT_EmployeesHR
	|		LEFT JOIN TT_RegularAccrualsAndDeductionsHR AS TT_RegularAccrualsAndDeductionsHR
	|		ON TT_EmployeesHR.Employee = TT_RegularAccrualsAndDeductionsHR.Employee"); 
	
	Query.SetParameter("SliceDate", StructureOfActions.ChangeDate);
	Query.SetParameter("Organization", StructureOfActions.Organization);
	Query.SetParameter("Department", StructureOfActions.Department);
	Query.SetParameter("EmployeesHR", StructureOfActions.Employee);
	Query.SetParameter("Accrual", StructureOfActions.Accrual); 
	
	ApproveNewAccrual = PredefinedValue("Enum.CompensationPlanActionsPayrollAndHumanResources.ApproveNew");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
			
		Selection = QueryResult.Select(); 
		
		While Selection.Next() Do
			
			If Not Selection.Value = Undefined 
				Or Object.Action = ApproveNewAccrual Then
			
				Page1 = Object.ChangesTable.Add();
			
				FillPropertyValues(Page1, Selection);
				
			Else
				Text = StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"ru = 'По сотруднику ""%1"" не найдено начисление ""%2""';
					|vi = 'No ""%2"" accrual is found for employee %1';
					|en = 'No ""%2"" accrual is found for employee %1'; fa = 'No ""%2"" accrual is found for employee %1';
					|it = 'No ""%2"" accrual is found for employee %1';
					|pl = 'No ""%2"" accrual is found for employee %1';
					|tr = 'Çalışan ""%1"" için ""%2"" tahakkuku bulunamadı'"), Selection.Employee,
					StructureOfActions.Accrual);

				Common.MessageToUser(Text, Object.Ref);				
			EndIf;
		EndDo;	
	EndIf;
	
	SetUpRegistrationForm();
	
EndProcedure  

&AtServer
Procedure FillInAccrualDescription()
	
	Items.Accrual.ToolTip = DocumentsPayrollAndHumanResourcesServer.AccrualCalculationProcedure(Object.Accrual, Object.Currency); 
		
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
