#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not ValueIsFilled(Object.CalculationPeriod)
		And Not ValueIsFilled(Object.Organization) Then
		Object.CalculationPeriod = BegOfMonth(CurrentSessionDate());
		Object.Organization = SettingsValueCached.GetDefaultOrganization();
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		ConfigureElementsDuringFormInitialization();
		SetVisibilityOfFormElementsAndPOCalculationStatuses();

	EndIf;	
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateFormDataInBackgroundOnClient();
	
	ManagingFormOfMessages();	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If TypeOf(Source) = Type("ClientApplicationForm")
		And UUID <> Source.UUID Then
		Return;
	EndIf;	
	
	If EventName	= "PayrollCalculationHasBeenPerformedInFormOfDetails" Then
		
		UpdateFormDataInBackgroundOnClient();			
		ManagingFormOfMessages();
	
	ElsIf EventName = "Recording_OneTimeAccrual" Then 

		UpdateFormDataInBackgroundOnClient();			
		ManagingFormOfMessages();
	
	ElsIf EventName = "FillingInPOCalculationStatusTable" Then
	
		UploadPOCalculationStatusesTableATServer(Parameter.AddressOfPOCalculationStatusTable); 
		
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		Items.POCalculationPages.CurrentPage = Items.CalculationStatusPage; 
		
		Items.EmployeePayrollCalculationStatuses.Refresh();
		
		ManagingFormOfMessages();
		
	ElsIf EventName= "NotifyAboutEndOfFillingInPayrollStatusesATServer"  Then

		UpdateFormDataInBackgroundOnClient(Parameter.FillParameters);			
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		ManagingFormOfMessages();
		
	ElsIf EventName= "CalculationOfAccrualsCompleted"  Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		CalculationParameters = Parameter.CalculationParameters;
		
		If CalculationParameters.ContinueSalaryCalculation Then
			
			PayrollCalculationHRClient.CalculateDeductions(CalculationParameters, ThisObject);
			
		Else	
			UpdateFormDataInBackgroundOnClient();			
			ManagingFormOfMessages();
		EndIf;	
		
		Notify("UpdatedDataInPayrollCenter",Parameter, ThisObject);
		
	ElsIf EventName= "DeductionsAreCalculated"  Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		CalculationParameters = Parameter.CalculationParameters;
		
		If CalculationParameters.ContinueSalaryCalculation Then
			
			PayrollCalculationHRClient.CalculateTaxes(CalculationParameters, ThisObject);
			
		Else	
			UpdateFormDataInBackgroundOnClient();			
			ManagingFormOfMessages();
		EndIf;		
		
		Notify("UpdatedDataInPayrollCenter",Parameter, ThisObject);
		
	ElsIf EventName= "TaxCalculationHasBeenCompleted" Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		CalculationParameters = Parameter.CalculationParameters;
		
		If CalculationParameters.ContinueSalaryCalculation Then
			
			PayrollCalculationHRClient.CalculateAmountToBePaid(CalculationParameters, ThisObject);
			
		Else	
			UpdateFormDataInBackgroundOnClient();			
			ManagingFormOfMessages();
		EndIf;		
		
		Notify("UpdatedDataInPayrollCenter",Parameter, ThisObject);
		
	ElsIf EventName= "AmountToBePaidHasBeenCalculated" Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		UpdateFormDataInBackgroundOnClient();			
		ManagingFormOfMessages();
		
		Notify("UpdatedDataInPayrollCenter",Parameter, ThisObject);
		
	ElsIf EventName= "CalculationHasBeenUnblocked" Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		UpdateFormDataInBackgroundOnClient();			
		
		ManagingFormOfMessages();
		
		Notify("UpdatedDataInPayrollCenter",Parameter, ThisObject);
		
	EndIf;	
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Parameters.CalculationPeriod) Then
		FillPropertyValues(Object, Parameters, "CalculationPeriod, Organization, Department"); 
	EndIf;	

	If Not ValueIsFilled(Object.CalculationPeriod)
		And Not ValueIsFilled(Object.Organization) Then
		Object.CalculationPeriod = BegOfMonth(CurrentSessionDate());
		Object.Organization = SettingsValueCached.GetDefaultOrganization();
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
	EndIf;	

	ConfigureElementsDuringFormInitialization();
	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PresentationOfRegistrationPeriodONChange(Item)

	Object.EmployeePayrollCalculationStatuses.Clear();
	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	
EndProcedure
	
&AtClient
Procedure OrganizationOnChange(Item)
	
	Object.EmployeePayrollCalculationStatuses.Clear();	
	WhenOrganizationChangesServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	Object.EmployeePayrollCalculationStatuses.Clear();	
	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
		
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.CalculationPeriod, "MONTH");
	
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
Procedure RegistrationPeriodPresentationClearing(Item, StandardProcessing)
	
		StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Object.CalculationPeriod,
		PresentationOfCalculationPeriod);
	
	PresentationOfCalculationPeriod = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.CalculationPeriod);     
	
	Object.EmployeePayrollCalculationStatuses.Clear();
	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployeePayrollCalculationStatuses

&AtClient
Procedure EmployeePayrollCalculationStatusesSelection(Item, RowSelected, Field, StandardProcessing)

	CurrentData = Items.EmployeePayrollCalculationStatuses.CurrentData;
	DecryptionOptions = OptionsForDecodingCalculationStatuses();

	ChoiceParameters = NewParametersForSelectingTableValuesCalculationStatusesOfPO();
	FillPropertyValues(ChoiceParameters, CurrentData);
	
	If Field.Name = "EmployeePayrollCalculationStatusesEmployee" Then
		
		ChoiceParameters.NameOfTheOperation = "";
		
		FormParameters = New Structure("Key", ChoiceParameters.Employee);
		
		OpenForm("Catalog.EmployeesHR.Form.ItemFormInternational", FormParameters,,,,); 
		
	ElsIf Field.Name = "EmployeePayrollCalculationStatusesSalaryChange" Then
		
		ChoiceParameters.NameOfTheOperation = DecryptionOptions.OpenPersonnelDocuments;
		
	ElsIf Field.Name = "EmployeePayrollCalculationStatusesTimeCard" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.OpenReportCards;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesAmountIsAccrued" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecryptAmountOfAccruals;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesAmountDeductions" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecryptAmountOfDeductions;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesTaxesFromEmployee" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecipherAmountOfTaxesFromEmployee;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesTaxesFromCompany" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecipherAmountOfTaxesFromCompany;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesAmountToBePaid" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecryptAmountToBePaid;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesThereAreErrorsInAccruals" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectErrorsByAccruals;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesThereAreErrorsInDeductions" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectErrorsByDeductions;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesThereAreErrorsInTaxesFromEmployee" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectTaxErrorsFromEmployee;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesThereAreErrorsInTaxesFromCompany" Then	

		ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectTaxErrorsFromCompany;

	ElsIf Field.Name = "EmployeePayrollCalculationStatusesThereAreErrorsInTimesheets" Then	
		
		ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectErrorsByReportCard;
		
	EndIf;

	If ValueIsFilled(ChoiceParameters.NameOfTheOperation) Then
		OpenFormWhenDecipheringValuesOfPOCalculationTable(ChoiceParameters);
	EndIf;	
		
EndProcedure

&AtClient
Procedure EmployeePayrollCalculationStatusesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionProcessingSelectionOfEmployeesOnClient(ValueSelected);	
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfPOCalculationErrors

&AtClient
Procedure TableOfPOCalculationErrorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.TableOfPOCalculationErrors.CurrentData;  

	DecryptionOptions = OptionsForDecodingCalculationStatuses();

	ChoiceParameters = NewParametersForSelectingTableValuesCalculationStatusesOfPO();
	FillPropertyValues(ChoiceParameters, CurrentData);
	
	If Field.Name = "TableOfPOCalculationErrorsErrorName"
		And (ValueIsFilled(ChoiceParameters.Employee)
		Or ValueIsFilled(ChoiceParameters.Individual)) Then
		
		If CurrentData.ErrorInCompanyTaxes Then

			ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecipherAmountOfTaxesFromCompany;
			
		ElsIf CurrentData.EmployeeTaxError Then

			ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecipherAmountOfTaxesFromEmployee;
			
		ElsIf CurrentData.ErrorInAccruals Then

			ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecryptAmountOfAccruals;
			
		ElsIf CurrentData.ErrorInTimesheets Then
			
			ChoiceParameters.NameOfTheOperation = DecryptionOptions.OpenReportCards;
			
		ElsIf CurrentData.ErrorInDeductions Then

			ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecryptAmountOfDeductions;
			
		Else
			
			Raise(CurrentData.ErrorText);
			
		EndIf;	
		
	Else
		
		Raise(CurrentData.ErrorText);
		
	EndIf;

	If ValueIsFilled(ChoiceParameters.NameOfTheOperation) Then
		OpenFormWhenDecipheringValuesOfPOCalculationTable(ChoiceParameters);
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelFilter(Command)
	
	Items.TableOfPOCalculationErrors.RowFilter = Undefined;
	
EndProcedure

&AtClient
Procedure Pickup(Command)

	TableOfPOCalculationErrors.Clear();
	
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.CalculationPeriod);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfMonth(Object.CalculationPeriod));
	ParametersForOpeningSelection.Insert("MultipleChoice", True);
	ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees());
	
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection,
					Items.EmployeePayrollCalculationStatuses);
	
EndProcedure

&AtClient
Procedure UnlockAll(Command)

	TableOfPOCalculationErrors.Clear();
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Organization",      Object.Organization);
	CalculationParameters.Insert("CalculationPeriod",    Object.CalculationPeriod);
	CalculationParameters.Insert("Department",    Object.Department);
	CalculationParameters.Insert("AddressOfCalculationStatusesTable", AddressOfStatusTableATServer(, True));	
	
	PayrollCalculationHRClient.UnblockCalculation(CalculationParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure BackButton(Command)
	
	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	UpdateResultsOfEmployeePayrollCalculationStatusesTable();
	
EndProcedure

&AtClient
Procedure CalculateWagesForAllEmployees(Command)

	TableOfPOCalculationErrors.Clear();
	
	NumberOfRowsToCalculate = CheckAndReportBlockingOfPayrollCalculations(); 
	
	If NumberOfRowsToCalculate = 0 Then
		
		NewRow = TableOfPOCalculationErrors.Add();
		NewRow.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Нет сотрудников для расчета заработной платы за период:%1 по организации: %2';
									|vi = 'There are no employees for payroll calculation for period %1 and the %2 company';
									|en = 'There are no employees for payroll calculation for period %1 and the %2 company'; fa = 'There are no employees for payroll calculation for period %1 and the %2 company';
									|it = 'There are no employees for payroll calculation for period %1 and the %2 company';
									|pl = 'There are no employees for payroll calculation for period %1 and the %2 company';
									|tr = '%2 iş yerinde %1 dönemi için bordrosu hesaplanacak çalışan bulunmamaktadır.'"),
										Object.CalculationPeriod, Object.Organization);
										
		Items.TableOfPOCalculationErrors.RowFilter = Undefined;
										
		ManagingFormOfMessages();

		Return;
		
	EndIf;	
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Organization",      Object.Organization);
	CalculationParameters.Insert("CalculationPeriod",    Object.CalculationPeriod);
	CalculationParameters.Insert("Department",    Object.Department);
	CalculationParameters.Insert("ContinueSalaryCalculation", True);
	CalculationParameters.Insert("AddressOfCalculationStatusesTable", AddressOfStatusTableATServer());	
	
	PayrollCalculationHRClient.CalculateAccruals(CalculationParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	TableOfPOCalculationErrors.Clear();
	Object.EmployeePayrollCalculationStatuses.Clear();
	FillInPOCalculationStatuses();

EndProcedure

&AtClient
Procedure Billing_Sheet(Command)
	
	AttachIdleHandler("BillingSheetIsOnClient", 0.1, True);

EndProcedure

&AtClient
Procedure UnblockDedicatedEmployees(Command)

	TableOfPOCalculationErrors.Clear();
	
	ArrayOfSelectedRows = Items.EmployeePayrollCalculationStatuses.SelectedRows;	
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Organization",   Object.Organization);
	CalculationParameters.Insert("CalculationPeriod", Object.CalculationPeriod);
	CalculationParameters.Insert("Department", Object.Department);
	CalculationParameters.Insert("AddressOfCalculationStatusesTable", 
				AddressOfStatusTableBySelectedRowsATServer(ArrayOfSelectedRows, True));	
	
	PayrollCalculationHRClient.UnblockCalculation(CalculationParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CalculateAllocatedEmployees(Command)
	
	ArrayOfSelectedRows = Items.EmployeePayrollCalculationStatuses.SelectedRows;	
	
	TableOfPOCalculationErrors.Clear();
	
	NumberOfRowsToCalculate = CheckAndReportBlockingOfPayrollCalculationsOnHighlightedLines(ArrayOfSelectedRows); 
	
	If NumberOfRowsToCalculate = 0 Then
		
		NewRow = TableOfPOCalculationErrors.Add();
		NewRow.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Расчет по сотруднику(ам) заблокирован за период:%1 по организации: %2';
									|vi = 'Calculation for the employee(s) is locked for period %1 for the %2 company';
									|en = 'Calculation for the employee(s) is locked for period %1 for the %2 company'; fa = 'Calculation for the employee(s) is locked for period %1 for the %2 company';
									|it = 'Calculation for the employee(s) is locked for period %1 for the %2 company';
									|pl = 'Calculation for the employee(s) is locked for period %1 for the %2 company';
									|tr = '%2 iş yerinde %1 dönemi için çalışan(lar)ın hesaplaması kilitlenmiştir.'"),
										Object.CalculationPeriod, Object.Organization);
		
		ManagingFormOfMessages();

		Return;
		
	EndIf;	
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Organization",      Object.Organization);
	CalculationParameters.Insert("CalculationPeriod",    Object.CalculationPeriod);
	CalculationParameters.Insert("Department",    Object.Department);
	CalculationParameters.Insert("ContinueSalaryCalculation", True);
	CalculationParameters.Insert("AddressOfCalculationStatusesTable", 
				AddressOfStatusTableBySelectedRowsATServer(ArrayOfSelectedRows, False));	
						
	PayrollCalculationHRClient.CalculateAccruals(CalculationParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure PayrollSheetForAllocatedEmployees(Command)
	
	AttachIdleHandler("BillingSheetForSelectedLinesOnClient", 0.1, True);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(Object.EmployeePayrollCalculationStatuses.Unload( ,
		"Employee").UnloadColumn("Employee"));
	Return PutToTempStorage(Selected_Employees, UUID);

EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//EmployeePayrollCalculationStatusesAmountIsAccrued
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeePayrollCalculationStatusesAmountIsAccrued.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EmployeePayrollCalculationStatuses.ThereAreManualAccruals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	
	//EmployeePayrollCalculationStatusesAmountDeductions
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeePayrollCalculationStatusesAmountDeductions.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EmployeePayrollCalculationStatuses.ThereAreManualDeductions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);

	//EmployeePayrollCalculationStatusesTaxesFromEmployee
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeePayrollCalculationStatusesTaxesFromEmployee.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EmployeePayrollCalculationStatuses.ThereAreManualTaxesFromEmployee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	
	//EmployeePayrollCalculationStatusesTaxesFromCompany
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeePayrollCalculationStatusesTaxesFromCompany.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EmployeePayrollCalculationStatuses.ThereAreManualTaxesFromCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	
EndProcedure 

&AtClient
Procedure BillingSheetForSelectedLinesOnClient()
	
	DocumentRef = PredefinedValue("Document.PostingPayrollExpensesInFinancialAccounting2_5.EmptyRef");
	
	ListOfIndividuals = PersonsToReportOnSelectedLines(DocumentRef);	
	
	BillingSheet = BillingSheetAtServerWithoutContext(Object.Organization, ListOfIndividuals, Object.CalculationPeriod);
	
	PrintManagementClient.ExecutePrintCommand("Report.PayslipHR", "BillingSheet", 
		CommonClientServer.ValueInArray(DocumentRef), ThisObject,
		New Structure("PrintedDocument", BillingSheet));
	
EndProcedure

&AtClient
Function PersonsToReportOnSelectedLines(DocumentRef)
	
	IndividualsArray = New Array();
	ArrayOfSelectedRows = Items.EmployeePayrollCalculationStatuses.SelectedRows;
	
	For Each CurrentRowNumber1 In ArrayOfSelectedRows Do   
		CurrentRow = Object.EmployeePayrollCalculationStatuses.FindByID(CurrentRowNumber1);
		
		If CurrentRow.CalculationStatusHR <> PredefinedValue("Enum.PayrollStatus.IsFinal") Then
			Continue;
		EndIf;
		
		IndividualsArray.Add(CurrentRow.Individual);	
		DocumentRef = CurrentRow.DocumentOfPostingInAccounting;
		
	EndDo;	
	
	Return IndividualsArray;
	
EndFunction	

&AtClient
Procedure BillingSheetIsOnClient()
	
	DocumentRef = PredefinedValue("Document.PostingPayrollExpensesInFinancialAccounting2_5.EmptyRef");
	
	ListOfIndividuals = PersonsToReport(DocumentRef);	
	
	BillingSheet = BillingSheetAtServerWithoutContext(Object.Organization, ListOfIndividuals, Object.CalculationPeriod);
	
	PrintManagementClient.ExecutePrintCommand("Report.PayslipHR", "BillingSheet", 
		CommonClientServer.ValueInArray(DocumentRef), ThisObject,
		New Structure("PrintedDocument", BillingSheet));
	
EndProcedure

&AtServerNoContext
Function BillingSheetAtServerWithoutContext(Organization, ListOfIndividuals, Month)
	
	Return PayrollAndHumanResourcesReports.BillingSheetForPeriod(Organization, ListOfIndividuals, Month);
	
EndFunction

&AtClient
Function PersonsToReport(DocumentRef)
	
	IndividualsArray = New Array();
	
	For Each CurrentRow In Object.EmployeePayrollCalculationStatuses Do
		If CurrentRow.CalculationStatusHR <> PredefinedValue("Enum.PayrollStatus.IsFinal") Then
			Continue;
		EndIf;
				
		IndividualsArray.Add(CurrentRow.Individual);	
		DocumentRef = CurrentRow.DocumentOfPostingInAccounting;
		
	EndDo;	
	
	Return IndividualsArray;
	
EndFunction	

&AtClient
Function CheckAndReportBlockingOfPayrollCalculationsOnHighlightedLines(ArrayOfSelectedRows)
	
	NumberOfEmployeesToCalculate = 0;
	For Each CurrentLineNumber In ArrayOfSelectedRows Do
		
		CurrentEmployeeByLine = Object.EmployeePayrollCalculationStatuses.FindByID(CurrentLineNumber).Employee;
		NumberOfEmployeesToCalculate = NumberOfEmployeesToCalculate 
			+ CheckAndReportBlockingOfPayrollCalculations(CurrentEmployeeByLine);
	
	EndDo;
	
	Return NumberOfEmployeesToCalculate;
EndFunction	

&AtClient
Function CheckAndReportBlockingOfPayrollCalculations(CurrentEmployeeByLine = "")
	
	For Each CurrentRow In Object.EmployeePayrollCalculationStatuses Do
		
		If (CurrentEmployeeByLine = "" And CurrentRow.SignLock)
			Or (CurrentEmployeeByLine <> "" And CurrentEmployeeByLine =  CurrentRow.Employee 
			And CurrentRow.SignLock) Then
			
			NewRow = TableOfPOCalculationErrors.Add();
			NewRow.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'Сотрудник %1 заблокирован для расчета';
										|vi = 'Employee %1 is locked for calculation';
										|en = 'Employee %1 is locked for calculation'; fa = 'Employee %1 is locked for calculation';
										|it = 'Employee %1 is locked for calculation';
										|pl = 'Employee %1 is locked for calculation';
										|tr = 'Çalışan %1 hesaplama için kilitlenmiştir.'"), CurrentRow.Employee);
			NewRow.Employee = CurrentRow.Employee;
			
		ElsIf CurrentRow.ThereAreErrorsInTimesheets Then	
			
			NewRow = TableOfPOCalculationErrors.Add();
			NewRow.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'По сотруднику %1 не введен табель';
										|vi = 'For employee %1, the timesheet is not created';
										|en = 'For employee %1, the timesheet is not created'; fa = 'For employee %1, the timesheet is not created';
										|it = 'For employee %1, the timesheet is not created';
										|pl = 'For employee %1, the timesheet is not created';
										|tr = 'Çalışan %1 için puantaj girilmemiştir.'"), CurrentRow.Employee);
			NewRow.Employee = CurrentRow.Employee;
			NewRow.Individual = CurrentRow.Individual;
			NewRow.ErrorInTimesheets = True;
			
		EndIf;	
		
	EndDo;	
	
	ManagingFormOfMessages();
	
	Return NumberOfEmployeesToCalculate(CurrentEmployeeByLine);

EndFunction	

&AtServer
Function NumberOfEmployeesToCalculate(CurrentEmployeeByLine = "")
	
	If ValueIsFilled(CurrentEmployeeByLine) Then

		Return Object.EmployeePayrollCalculationStatuses.Unload(
					New Structure("Employee,SignLock,ThereAreErrorsInTimesheets", 
										CurrentEmployeeByLine, False, False)).Count();		
	EndIf;	
		
	Return Object.EmployeePayrollCalculationStatuses.Unload(
					New Structure("SignLock,ThereAreErrorsInTimesheets", False, False)).Count();
	
EndFunction

&AtServer
Function AddressOfStatusTableBySelectedRowsATServer(ArrayOfSelectedRows, SignLock = False)

	TableForCalculation = Object.EmployeePayrollCalculationStatuses.Unload(,); 
	TableForCalculation.Clear();
	
	For Each CurrentRowNumber1 In ArrayOfSelectedRows Do  
		CurrentRow = Object.EmployeePayrollCalculationStatuses.FindByID(CurrentRowNumber1);
		If Not CurrentRow.SignLock = SignLock Then
			Continue;
		EndIf;	
		
		FillPropertyValues(TableForCalculation.Add(), CurrentRow);
		
	EndDo;	

	Return PutToTempStorage(
					TableForCalculation, 
					UUID); 
	
EndFunction	
	
&AtServer
Function AddressOfStatusTableATServer(EmployeeToCalculate = "", SignLock = False)
	
	If ValueIsFilled(EmployeeToCalculate) Then
		
		FilterByEmployee = New Structure("Employee,SignLock,ThereAreErrorsInTimesheets", 
																		EmployeeToCalculate, SignLock,False);
		
		TableForCalculation = Object.EmployeePayrollCalculationStatuses.Unload(FilterByEmployee); 
		
	Else

		SelectionByEmployees = New Structure("SignLock,ThereAreErrorsInTimesheets", SignLock,False); 
		
		TableForCalculation = Object.EmployeePayrollCalculationStatuses.Unload(SelectionByEmployees);
		
	EndIf;
						
	Return PutToTempStorage(
					TableForCalculation, 
					UUID); 
	
EndFunction
					
&AtClient
Procedure SelectionProcessingSelectionOfEmployeesOnClient(ValueSelected)

	FillParameters = New Structure();
	FillParameters.Insert("Organization",       Object.Organization); 
	FillParameters.Insert("Department",     Object.Department); 
	FillParameters.Insert("CalculationPeriod",     Object.CalculationPeriod); 
	FillParameters.Insert("ArrayOfEmployees", ValueSelected); 
	
	PayrollCalculationHRClient.FillInPOCalculationStatuses(FillParameters, ThisObject);	
	
EndProcedure	

&AtClient
Procedure FillInPOCalculationStatuses()
	
	FillParameters = New Structure();
	FillParameters.Insert("Organization",       Object.Organization); 
	FillParameters.Insert("Department",     Object.Department); 
	FillParameters.Insert("CalculationPeriod",     Object.CalculationPeriod); 
	FillParameters.Insert("ArrayOfEmployees", New Array()); 
	
	PayrollCalculationHRClient.FillInPOCalculationStatuses(FillParameters, ThisObject);	
	
EndProcedure	

&AtServer
Procedure ManagingFormOfMessages()
	
	Items.MessageForm.Visible = TableOfPOCalculationErrors.Count() > 0;
	Items.MessageForm.Title = NStr("ru = 'Ошибки (';
									|vi = 'Errors (';
									|en = 'Errors ('; fa = 'Errors (';
									|it = 'Errors (';
									|pl = 'Errors (';
									|tr = 'Hatalar ('") + TableOfPOCalculationErrors.Count() + ")";
	Items.MessageForm.CollapsedRepresentationTitle = Items.MessageForm.Title;
	
	If TableOfPOCalculationErrors.Count() = 0 Then
		Items.MessageForm.Title = NStr("ru = 'Нет ошибок';
										|vi = 'No errors';
										|en = 'No errors'; fa = 'No errors';
										|it = 'No errors';
										|pl = 'No errors';
										|tr = 'Hata yok'")
	EndIf;
	
	CheckErrorMarksInPOStatuses();
	
EndProcedure	

&AtClient
Procedure OpenFormWhenDecipheringValuesOfPOCalculationTable(ChoiceParameters)

	DecryptionOptions = OptionsForDecodingCalculationStatuses();

	If ChoiceParameters.NameOfTheOperation = DecryptionOptions.OpenPersonnelDocuments Then
		
		FormParameters = New Structure();
		QuickFilterStructure = New Structure();
		QuickFilterStructure.Insert("Organization", Object.Organization);
		QuickFilterStructure.Insert("Department", ChoiceParameters.Department); 
		QuickFilterStructure.Insert("RegistrationPeriod", Object.CalculationPeriod);  
		QuickFilterStructure.Insert("Employee", ChoiceParameters.Employee); 
		QuickFilterStructure.Insert("RegistrationMonth", Object.CalculationPeriod);  
		
		FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
		
		OpenForm("DocumentJournal.ChangesInAccrualsAndDeductions.ListForm", FormParameters, ,, , ); 
		
	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.OpenReportCards Then
		
		FormParameters = New Structure();
		QuickFilterStructure = New Structure();
		QuickFilterStructure.Insert("Organization", Object.Organization);
		QuickFilterStructure.Insert("Department", ChoiceParameters.Department); 
		QuickFilterStructure.Insert("Employee", ChoiceParameters.Employee); 
		QuickFilterStructure.Insert("BeginningDateOfPeriod", BegOfDay(Object.CalculationPeriod));  
		QuickFilterStructure.Insert("EndingDateOfPeriod", EndOfMonth(Object.CalculationPeriod));  
		
		FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
		
		OpenForm("Document.TimesheetHR.ListForm", FormParameters,,,,);
		
	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.DecryptAmountToBePaid Then
		
		FormParameters = New Structure();     
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("RegistrationPeriod", Object.CalculationPeriod);  
		FormParameters.Insert("PayrollCalculation", True);  
		
		OpenForm("Document.PostingPayrollExpensesInFinancialAccounting2_5.ListForm", FormParameters, ,, , );
		
	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectErrorsByAccruals Then
		
		Filter = New FixedStructure("Employee,ErrorInAccruals", ChoiceParameters.Employee, True);
		Items.TableOfPOCalculationErrors.RowFilter = Filter;

	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectErrorsByDeductions Then
		
		Filter = New FixedStructure("Employee,ErrorInDeductions", ChoiceParameters.Employee, True);
		Items.TableOfPOCalculationErrors.RowFilter = Filter;

	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectTaxErrorsFromEmployee Then
		
		Filter = New FixedStructure("Individual,EmployeeTaxError", ChoiceParameters.Individual, True);
		Items.TableOfPOCalculationErrors.RowFilter = Filter;

	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectTaxErrorsFromCompany Then
		
		Filter = New FixedStructure("Individual,ErrorInCompanyTaxes", ChoiceParameters.Individual, True);
		Items.TableOfPOCalculationErrors.RowFilter = Filter;

	ElsIf ChoiceParameters.NameOfTheOperation = DecryptionOptions.SelectErrorsByReportCard Then
		
		Filter = New FixedStructure("Employee,ErrorInTimesheets", ChoiceParameters.Employee,
						True);
						
		RowFilter = Items.TableOfPOCalculationErrors.RowFilter;
		
		SelectionHasAlreadyBeenSet = False;
		If TypeOf(RowFilter) = Type("FixedStructure")	
					And RowFilter.Property("ErrorInTimesheets")
					And RowFilter.Property("Employee") Then
			SelectionHasAlreadyBeenSet = Filter.Employee = RowFilter.Employee 
										And Filter.ErrorInTimesheets = RowFilter.ErrorInTimesheets;	
		EndIf;

		Items.TableOfPOCalculationErrors.RowFilter = ?(SelectionHasAlreadyBeenSet, Undefined, Filter);
		
	Else
		
		OpenPayrollDetailsForm(ChoiceParameters);
		
	EndIf;	

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		Object.EmployeePayrollCalculationStatuses.Clear();
		SetVisibilityOfFormElementsAndPOCalculationStatuses();
		
		Object.CalculationPeriod = SelectedPeriod;
		PresentationOfCalculationPeriod = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.CalculationPeriod);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFormDataInBackgroundOnClient(FillParameters = Undefined)
	
	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	
	StartFillingInPOCalculationStatusTable(FillParameters);
	
EndProcedure

&AtClient
Procedure StartFillingInPOCalculationStatusTable(FillParameters)
	
	If Items.POCalculationPages.CurrentPage = Items.BlankPage Then
		Return;
	EndIf;	
	
	Items.POCalculationPages.CurrentPage = Items.WaitingPage;
	
	If FillParameters = Undefined Then
		FillParameters = New Structure();
		FillParameters.Insert("CalculationPeriod", Object.CalculationPeriod);	
		FillParameters.Insert("Organization", Object.Organization);
		FillParameters.Insert("Department", Object.Department);
	EndIf;						

		FillParameters.Insert("AddressOfPOCalculationStatusTable", 
						PutToTempStorage("", UUID));    
						
	If Not FillParameters.Property("ArrayOfEmployees") Then	
		FillParameters.Insert("ArrayOfEmployees", New Array());						
	EndIf;	
							
	ArrayOfEmployees = FillParameters.ArrayOfEmployees;

	For Each CurrentRow In Object.EmployeePayrollCalculationStatuses Do
		ArrayOfEmployees.Add(CurrentRow.Employee);
	EndDo;	
						
	PayrollCalculationHRClient.FillInTableOfStatusesForCalculatingPO(FillParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure ConfigureElementsDuringFormInitialization(LoadingSettings = False)

	PresentationOfCalculationPeriod = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.CalculationPeriod);
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);

EndProcedure

&AtServer
Procedure SetVisibilityOfFormElementsAndPOCalculationStatuses()
		
	ErrorInRegistrationPeriod = False;		
	If Not ValueIsFilled(Object.CalculationPeriod) Then
		ErrorInRegistrationPeriod = True;
	EndIf;	

	Items.SettingsGroup1.ReadOnly = False;
		
	ErrorInCompany = False;		
	If Not ValueIsFilled(Object.Organization) Then
		ErrorInCompany = True;	
	EndIf;	
	
	Items.GroupNoCompanySpecified.Visible = ErrorInCompany;
	
	StartDateOfManagementPayrollAndPersonnel = Constants.StartDatePayrollAndHumanResources.Get();
	
	If Not ErrorInRegistrationPeriod Then
		ErrorInRegistrationPeriod = StartDateOfManagementPayrollAndPersonnel > Object.CalculationPeriod;
	EndIf;

	Items.GroupPaymentMonthNotSpecified.Visible = ErrorInRegistrationPeriod;   
	If ErrorInRegistrationPeriod Then  
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Укажите период для заполнения таблицы расчета заработной платы. Расчет зарплаты и кадров доступен в программе с :%1';
				|vi = 'Specify the period for filling in the payroll calculation table. Payroll and human resource calculation is available in the program since %1';
				|en = 'Specify the period for filling in the payroll calculation table. Payroll and human resource calculation is available in the program since %1'; fa = 'Specify the period for filling in the payroll calculation table. Payroll and human resource calculation is available in the program since %1';
				|it = 'Specify the period for filling in the payroll calculation table. Payroll and human resource calculation is available in the program since %1';
				|pl = 'Specify the period for filling in the payroll calculation table. Payroll and human resource calculation is available in the program since %1';
				|tr = 'Bordro hesaplama tablosunu doldurmak için dönemi belirtin. Bordro ve personel hesaplaması programda şu tarihten itibaren kullanılabilir: %1'"),
			Format(StartDateOfManagementPayrollAndPersonnel, "DLF=D"));
		
		Items.Error1.Title = ErrorText;
	EndIf;	
	
	If ErrorInRegistrationPeriod Or ErrorInCompany Then
		Items.POCalculationPages.CurrentPage = Items.BlankPage;
	Else
		Items.POCalculationPages.CurrentPage = Items.CalculationStatusPage;
	EndIf;	
	
EndProcedure

&AtServer
Procedure WhenOrganizationChangesServer()

	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);

	SetVisibilityOfFormElementsAndPOCalculationStatuses();
	
EndProcedure

&AtServer
Procedure UploadPOCalculationStatusesTableATServer(AddressOfPOCalculationStatusTable)
	
	Object.EmployeePayrollCalculationStatuses.Clear();	
	
	TableOfPOCalculationStatus = GetFromTempStorage(AddressOfPOCalculationStatusTable);
	
	If TableOfPOCalculationStatus <> Undefined Then
		Object.EmployeePayrollCalculationStatuses.Load(TableOfPOCalculationStatus);
	EndIf;	
	
	UpdateResultsOfEmployeePayrollCalculationStatusesTable();
	
EndProcedure

&AtServer
Procedure UpdateResultsOfEmployeePayrollCalculationStatusesTable()

	TotalTaxesFromCompany = Object.EmployeePayrollCalculationStatuses.Total("TaxesFromCompany");
	TotalTaxesPerEmployee = Object.EmployeePayrollCalculationStatuses.Total("TaxesFromEmployee");
	TotalAccrued = Object.EmployeePayrollCalculationStatuses.Total("AmountIsAccrued");
	TotalWithheld = Object.EmployeePayrollCalculationStatuses.Total("AmountDeductions");
	TotalAmount_ToBePaid = Object.EmployeePayrollCalculationStatuses.Total("AmountToBePaid");
	
EndProcedure	

&AtServer
Function NewParametersForSelectingTableValuesCalculationStatusesOfPO()

	ChoiceParameters = New Structure();
	ChoiceParameters.Insert("Employee", Catalogs.EmployeesHR.EmptyRef());
	ChoiceParameters.Insert("Individual", Catalogs.Persons.EmptyRef());	
	ChoiceParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());	
	ChoiceParameters.Insert("NameOfTheOperation", "");

	Return ChoiceParameters;
	
EndFunction

&AtClient
Procedure OpenPayrollDetailsForm(ChoiceParameters)

	CurrentData = Items.EmployeePayrollCalculationStatuses.CurrentData;   
	CurrentRowIndex = Object.EmployeePayrollCalculationStatuses.IndexOf(CurrentData);
	TableAddressStructure = GetTableAddresses(CurrentRowIndex);
	
	If ChoiceParameters.Employee <> CurrentData.Employee
		Or ChoiceParameters.Department <> CurrentData.Department Then
		
		For Each CurrentStatusesLine In Object.EmployeePayrollCalculationStatuses Do
			
			If ChoiceParameters.Employee = CurrentStatusesLine.Employee
					And ChoiceParameters.Department = CurrentStatusesLine.Department Then

				CurrentRowIndex = Object.EmployeePayrollCalculationStatuses.IndexOf(CurrentStatusesLine);
				TableAddressStructure = GetTableAddresses(CurrentRowIndex);
					
				Break
				
			EndIf;
			
		EndDo;
	EndIf;	
	
	FormParameters 	= New Structure();
	FormParameters.Insert("Organization",    Object.Organization);
	FormParameters.Insert("Department",  CurrentData.Department);
	FormParameters.Insert("Individual", ChoiceParameters.Individual);
	FormParameters.Insert("Employee",      ChoiceParameters.Employee); 
	FormParameters.Insert("CalculationPeriod",  Object.CalculationPeriod); 
	FormParameters.Insert("NameOfTheOperation",  ChoiceParameters.NameOfTheOperation); 
	FormParameters.Insert("AddressOfEmployeeStatusTable", TableAddressStructure.AddressOfStatusTable); 
	FormParameters.Insert("AddressOfPOCalculationErrorTable", TableAddressStructure.AddressErrorTableByEmployee); 
	
	OpenForm("DataProcessor.PayrollCalculationHR.Form.ARAPItemForm",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		,
		FormWindowOpeningMode.Independent);
													
EndProcedure

&AtServer
Function GetTableAddresses(CurrentRowIndex)
	
	CurrentPOCalculationStatusLine = Object.EmployeePayrollCalculationStatuses[CurrentRowIndex];
	
	Array = New Array();
	Array.Add(CurrentPOCalculationStatusLine);
	
	StatusTableByIndex = Object.EmployeePayrollCalculationStatuses.Unload(Array,);
	
	AddressOfStatusTable = PutToTempStorage(StatusTableByIndex, UUID);
	
	Individual = CurrentPOCalculationStatusLine.Individual;
	Department = CurrentPOCalculationStatusLine.Department;
	
	ErrorTableByEmployee = TableOfPOCalculationErrors.Unload(
								New Structure("Individual,Department", Individual, Department));
	AddressErrorTableByEmployee = PutToTempStorage(ErrorTableByEmployee, UUID);
	
	Return New Structure("AddressOfStatusTable,AddressErrorTableByEmployee", 
								AddressOfStatusTable, AddressErrorTableByEmployee);
	
EndFunction	

&AtServer
Function OptionsForDecodingCalculationStatuses()
	
	OptionsForDecodingValuesOfPOCalculationTable = New Structure();
	OptionsForDecodingValuesOfPOCalculationTable.Insert("OpenPersonnelDocuments", "OpenPersonnelDocuments");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("OpenReportCards", "OpenReportCards");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("DecryptAmountOfAccruals", "DecryptAmountOfAccruals");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("DecryptAmountOfDeductions", "DecryptAmountOfDeductions");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("DecipherAmountOfTaxesFromEmployee", "DecipherAmountOfTaxesFromEmployee");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("DecipherAmountOfTaxesFromCompany", "DecipherAmountOfTaxesFromCompany");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("DecryptAmountToBePaid", "DecryptAmountToBePaid");
	OptionsForDecodingValuesOfPOCalculationTable.Insert("SelectErrorsByAccruals", "SelectErrorsByAccruals");  
	OptionsForDecodingValuesOfPOCalculationTable.Insert("SelectErrorsByReportCard", "SelectErrorsByReportCard"); 
	OptionsForDecodingValuesOfPOCalculationTable.Insert("SelectErrorsByDeductions", "SelectErrorsByDeductions");  
	OptionsForDecodingValuesOfPOCalculationTable.Insert("SelectTaxErrorsFromEmployee", "SelectTaxErrorsFromEmployee");  
	OptionsForDecodingValuesOfPOCalculationTable.Insert("SelectTaxErrorsFromCompany", "SelectTaxErrorsFromCompany");  

	Return OptionsForDecodingValuesOfPOCalculationTable;
	
EndFunction	

&AtClient
Procedure DisplayErrorsInMessageLine(ErrorsArray)

	DisplayErrorsInMessageLineAtServer(ErrorsArray);
	
EndProcedure	

&AtServer
Procedure DisplayErrorsInMessageLineAtServer(ErrorsArray)
	If ErrorsArray.Count() = 0 Then
		Return;
	EndIf;	
	
	For Each CurrentErrorParameters In ErrorsArray Do
		NewRow = TableOfPOCalculationErrors.Add();
		FillPropertyValues(NewRow, CurrentErrorParameters);
	EndDo;	
	
EndProcedure

&AtServer
Procedure CheckErrorMarksInPOStatuses()
	
	FilterByBankingDetails = New Structure("Employee,Department");
	
	For Each CurrentLineError In TableOfPOCalculationErrors Do
		If Not ValueIsFilled(CurrentLineError.Employee) Then
			Continue;
		EndIf;	
		
		FillPropertyValues(FilterByBankingDetails, CurrentLineError);
		
		FoundRows = Object.EmployeePayrollCalculationStatuses.FindRows(FilterByBankingDetails); 
		
		If FoundRows.Count() > 0 Then

			CurrentPOStatusBar = FoundRows[0]; 
			
			CurrentPOStatusBar.ThereAreErrorsInAccruals = ?(CurrentLineError.ErrorInAccruals, 
														True, CurrentPOStatusBar.ThereAreErrorsInAccruals);
			CurrentPOStatusBar.ThereAreErrorsInDeductions = ?(CurrentLineError.ErrorInDeductions, 
														True, CurrentPOStatusBar.ThereAreErrorsInDeductions); 
			CurrentPOStatusBar.ThereAreErrorsInTaxesFromEmployee = ?(CurrentLineError.EmployeeTaxError, 
														True, CurrentPOStatusBar.ThereAreErrorsInTaxesFromEmployee); 
			CurrentPOStatusBar.ThereAreErrorsInTaxesFromCompany = ?(CurrentLineError.ErrorInCompanyTaxes, 
														True, CurrentPOStatusBar.ThereAreErrorsInTaxesFromCompany);
			
		EndIf;
		
	EndDo;	

	FilterByBankingDetails = New Structure("Individual,Department");
	
	For Each CurrentLineError In TableOfPOCalculationErrors Do
		If Not ValueIsFilled(CurrentLineError.Individual) Then
			Continue;
		EndIf;	
		
		FillPropertyValues(FilterByBankingDetails, CurrentLineError);
		
		FoundRows = Object.EmployeePayrollCalculationStatuses.FindRows(FilterByBankingDetails); 
		
		If FoundRows.Count() > 0 Then

			CurrentPOStatusBar = FoundRows[0]; 
			
			CurrentPOStatusBar.ThereAreErrorsInAccruals = ?(CurrentLineError.ErrorInAccruals, 
														True, CurrentPOStatusBar.ThereAreErrorsInAccruals);
			CurrentPOStatusBar.ThereAreErrorsInDeductions = ?(CurrentLineError.ErrorInDeductions, 
														True, CurrentPOStatusBar.ThereAreErrorsInDeductions); 
			CurrentPOStatusBar.ThereAreErrorsInTaxesFromEmployee = ?(CurrentLineError.EmployeeTaxError, 
														True, CurrentPOStatusBar.ThereAreErrorsInTaxesFromEmployee); 
			CurrentPOStatusBar.ThereAreErrorsInTaxesFromCompany = ?(CurrentLineError.ErrorInCompanyTaxes, 
														True, CurrentPOStatusBar.ThereAreErrorsInTaxesFromCompany);
			
		EndIf;
		
	EndDo;	
	
EndProcedure 	

#EndRegion
