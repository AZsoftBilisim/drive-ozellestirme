
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	NameOfTheOperation = Parameters.NameOfTheOperation;
	AddressOfEmployeeStatusTable = Parameters.AddressOfEmployeeStatusTable;
	StatusTable = GetFromTempStorage(AddressOfEmployeeStatusTable);

	AddressOfPOCalculationErrorTable = Parameters.AddressOfPOCalculationErrorTable;
	
	Object.EmployeePayrollCalculationStatuses.Load(StatusTable);  
	TableOfPOCalculationErrors.Load(GetFromTempStorage(AddressOfPOCalculationErrorTable));

	CurrentLIneStatuses = Object.EmployeePayrollCalculationStatuses[0];
	
	FillPropertyValues(ThisObject, CurrentLIneStatuses, "Individual,Employee");
	FillPropertyValues(Object, Parameters, "CalculationPeriod,Organization,Department,Currency");
	
	ConfigureElementsDuringFormInitialization();
	
	SetVisibilityOfDetailFormElements(NameOfTheOperation);
	
	SetVisibility1();

	SetConditionalAppearance();
	
	UpdateResultsOfDecryptionTableByEmployee(CurrentLIneStatuses.AmountIsAccrued,
												  	CurrentLIneStatuses.AmountDeductions,
												  	CurrentLIneStatuses.TaxesFromEmployee,
												  	CurrentLIneStatuses.TaxesFromCompany,
												  	CurrentLIneStatuses.AmountToBePaid);
													
	ManagingFormOfMessages();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateDynamicQueryParameters();
	UpdateTableSelection(Items.GroupDetailsByEmployee.CurrentPage);	
	
EndProcedure

&AtClient
Procedure OnReopen()

	SetVisibility1();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If TypeOf(Source) = Type("ClientApplicationForm")
		And UUID <> Source.UUID Then       
		
		//The Form owner sent the notification
		If FormOwner.UUID = Source.UUID
			And EventName = "UpdatedDataInPayrollCenter"
			And Parameters.Employee = Employee Then 
				
				StartFillingInPOCalculationStatusTable(True);			
				DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
				ManagingFormOfMessages();
			
		EndIf;
		
		Return;
	EndIf;	           
	
	If EventName	= "Recording_OneTimeAccrual" Then 

		Items.Accruals.Refresh();
		
	ElsIf EventName = "Recording_OneTimeRetention" Then 

		Items.Deductions.Refresh();
		
	ElsIf EventName = "Record_ManualCalculationOfTaxes" Then 

		Items.CompanyTaxes.Refresh();
		Items.TaxesEmployee.Refresh();
	
	ElsIf EventName = "FillingInPOCalculationStatusTable" Then
	
		UploadPOCalculationStatusesTableATServer(Parameter.AddressOfPOCalculationStatusTable); 
		
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		Items.Accruals.Refresh();
		Items.Deductions.Refresh();
		Items.CompanyTaxes.Refresh(); 
		Items.TaxesEmployee.Refresh(); 
		
		SetAvailabilityOfCalculationButtonsByDetail();
		
		ManagingFormOfMessages(); 
		
		If Not Parameter.FillParameters.CallingFromMainForm Then
			Notify("PayrollCalculationHasBeenPerformedInFormOfDetails",, FormOwner);
		EndIf;
		
	ElsIf EventName= "NotifyAboutEndOfFillingInPayrollStatusesATServer"  Then
		
		StartFillingInPOCalculationStatusTable();			
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		ManagingFormOfMessages();
		
	ElsIf EventName= "CalculationOfAccrualsCompleted"  Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		CalculationParameters = Parameter.CalculationParameters;
		
		If CalculationParameters.ContinueSalaryCalculation Then
			
			PayrollCalculationHRClient.CalculateDeductions(CalculationParameters, ThisObject);
			
		Else	
			StartFillingInPOCalculationStatusTable();			
			ManagingFormOfMessages();
		EndIf;	

	ElsIf EventName= "DeductionsAreCalculated"  Then

		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		CalculationParameters = Parameter.CalculationParameters;
		
		If CalculationParameters.ContinueSalaryCalculation Then
			
			PayrollCalculationHRClient.CalculateTaxes(CalculationParameters, ThisObject);
			
		Else	
			StartFillingInPOCalculationStatusTable();			
			ManagingFormOfMessages();
		EndIf;		

	ElsIf EventName= "TaxCalculationHasBeenCompleted" Then
		
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		CalculationParameters = Parameter.CalculationParameters;
		
		If CalculationParameters.ContinueSalaryCalculation Then
			
			PayrollCalculationHRClient.CalculateAmountToBePaid(CalculationParameters, ThisObject);
			
		Else	
			StartFillingInPOCalculationStatusTable();			
			ManagingFormOfMessages();
		EndIf;		

	ElsIf EventName= "AmountToBePaidHasBeenCalculated" Then
		
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		StartFillingInPOCalculationStatusTable();			
		ManagingFormOfMessages();
		SetAvailabilityOfCalculationButtonsByDetail();
		
	ElsIf EventName= "CalculationHasBeenUnblocked" Then
		
		DisplayErrorsInMessageLine(Parameter.ErrorsArray); 
		
		StartFillingInPOCalculationStatusTable();			
		SetAvailabilityOfCalculationButtonsByDetail();
		
		ManagingFormOfMessages();

	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupDetailsByEmployeeOnCurrentPageChange(Item, CurrentPage)
	
	UpdateTableSelection(CurrentPage);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;

	CurrentData = Items.Accruals.CurrentData; 
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "AccrualsBasis"
		And ValueIsFilled(CurrentData.Basis) Then
		
		ShowValue(Undefined, CurrentData.Basis);
		
	ElsIf Field.Name = "AccrualsAccrual" Then
		
		FormParameters = New Structure("Key", CurrentData.Accrual);
		
		OpenForm("Catalog.AccrualAndDeductionKinds.ObjectForm", FormParameters,,,,); 
			
	EndIf;
	
EndProcedure  

&AtServerNoContext
Procedure AccrualsOnGetDataAtServer(TagName, Settings, Rows)
	
	AdditionalProperties = Settings.AdditionalProperties;
	
	If Not AdditionalProperties.Property("AddressOfErrorTable") Then
		Return;
	EndIf;	
	
	AddressOfErrorTable = Settings.AdditionalProperties.AddressOfErrorTable;
	ErrorsTable = GetFromTempStorage(AddressOfErrorTable);
	
	If ErrorsTable.Count() = 0 Then
		Return;
	EndIf;	
	
	For Each KeyAndValue In Rows Do
		
		Data = KeyAndValue.Value.Data;
		FilterByValue = New Structure("TypeOfAccrualDeduction", Data.Accrual);
		
		FoundRows = ErrorsTable.FindRows(FilterByValue);
		If FoundRows.Count() > 0 Then
			Data.HasErrors = True;
		EndIf;	
		
	EndDo;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCompanyTaxes

&AtClient
Procedure CompanyTaxesSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;

	CurrentData = Items.CompanyTaxes.CurrentData; 
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Field.Name = "CompanyTaxesBasis"
		And ValueIsFilled(CurrentData.Basis) Then
		
		ShowValue(Undefined, CurrentData.Basis);
			
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CompanyTaxesOnGetDataAtServer(TagName, Settings, Rows)
	
	AdditionalProperties = Settings.AdditionalProperties;
	
	If Not AdditionalProperties.Property("ErrorInCompanyTaxes") Then
		Return;
	EndIf;	
	
	AddressOfErrorTable = Settings.AdditionalProperties.ErrorInCompanyTaxes;
	ErrorsTable = GetFromTempStorage(AddressOfErrorTable);
	
	If ErrorsTable.Count() = 0 Then
		Return;
	EndIf;	
	
	For Each KeyAndValue In Rows Do
		
		Data = KeyAndValue.Value.Data;
		FilterByValue = New Structure("TaxKind", Data.TaxKind);
		
		FoundRows = ErrorsTable.FindRows(FilterByValue);
		If FoundRows.Count() > 0 Then
			Data.HasErrors = True;
		EndIf;	
		
	EndDo;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTaxesEmployee

&AtClient
Procedure TaxesEmployeeSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;

	CurrentData = Items.TaxesEmployee.CurrentData; 
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "TaxesEmployeeBasis"
		And ValueIsFilled(CurrentData.Basis) Then
		
		ShowValue(Undefined, CurrentData.Basis);
			
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure TaxesEmployeeOnGetDataAtServer(TagName, Settings, Rows)
	
	AdditionalProperties = Settings.AdditionalProperties;
	
	If Not AdditionalProperties.Property("AddressOfErrorTableTaxesFromEmployee") Then
		Return;
	EndIf;	
	
	AddressOfErrorTable = Settings.AdditionalProperties.AddressOfErrorTableTaxesFromEmployee;
	ErrorsTable = GetFromTempStorage(AddressOfErrorTable);
	
	If ErrorsTable.Count() = 0 Then
		Return;
	EndIf;	
	
	For Each KeyAndValue In Rows Do
		
		Data = KeyAndValue.Value.Data;
		FilterByValue = New Structure("TaxKind", Data.TaxKind);
		
		FoundRows = ErrorsTable.FindRows(FilterByValue);
		If FoundRows.Count() > 0 Then
			Data.HasErrors = True;
		EndIf;	
		
	EndDo;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDeductions

&AtClient
Procedure DeductionsSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;

	CurrentData = Items.Deductions.CurrentData; 
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "DeductionsBasis"
		And ValueIsFilled(CurrentData.Basis) Then
		
		ShowValue(Undefined, CurrentData.Basis);
			
	EndIf;

EndProcedure

&AtServerNoContext
Procedure DeductionsOnGetDataAtServer(TagName, Settings, Rows)
	
	AdditionalProperties = Settings.AdditionalProperties;
	
	If Not AdditionalProperties.Property("AddressOfErrorTable") Then
		Return;
	EndIf;	
	
	AddressOfErrorTable = Settings.AdditionalProperties.AddressOfErrorTable;
	ErrorsTable = GetFromTempStorage(AddressOfErrorTable);
	
	If ErrorsTable.Count() = 0 Then
		Return;
	EndIf;	
	
	For Each KeyAndValue In Rows Do
		
		Data = KeyAndValue.Value.Data;
		FilterByValue = New Structure("TypeOfAccrualDeduction", Data.Retention);
		
		FoundRows = ErrorsTable.FindRows(FilterByValue);
		If FoundRows.Count() > 0 Then
			Data.HasErrors = True;
		EndIf;	
		
	EndDo;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateOneTimeRetention(Command)

	FillingData = New Structure();
	FillingData.Insert("Organization", Object.Organization);
	FillingData.Insert("Department", Object.Department);
	FillingData.Insert("CalculationPeriod", Object.CalculationPeriod);
	FillingData.Insert("Employee", Employee);
	FillingData.Insert("Currency", Object.Currency);
	
	FormParameters = New Structure("Basis", FillingData);
	
	OpenForm("Document.OneTimeDeductions.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CreateManualTaxCalculation(Command)

	FillingData = New Structure();
	FillingData.Insert("Organization", Object.Organization);
	FillingData.Insert("Department", Object.Department);
	FillingData.Insert("CalculationPeriod", Object.CalculationPeriod);
	FillingData.Insert("Employee", Employee);
	FillingData.Insert("Currency", Object.Currency);
	
	FormParameters = New Structure("Basis", FillingData);
	
	OpenForm("Document.ManualTaxCalculation.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CreateOneTimeAccrual(Command)

	FillingData = New Structure();
	FillingData.Insert("Organization", Object.Organization);
	FillingData.Insert("Department", Object.Department);
	FillingData.Insert("CalculationPeriod", Object.CalculationPeriod);
	FillingData.Insert("Employee", Employee);
	FillingData.Insert("Currency", Object.Currency);
	
	FormParameters = New Structure("Basis", FillingData);
	
	OpenForm("Document.OneTimeAccrualsHR.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure UnblockCalculation(Command)

	TableOfPOCalculationErrors.Clear();
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Organization",      Object.Organization);
	CalculationParameters.Insert("CalculationPeriod",    Object.CalculationPeriod);
	CalculationParameters.Insert("Department",    Object.Department);
	CalculationParameters.Insert("AddressOfCalculationStatusesTable", AddressOfStatusTableATServer(True));	
	
	PayrollCalculationHRClient.UnblockCalculation(CalculationParameters, ThisObject);
	
	
EndProcedure

&AtClient
Procedure CalculateData(Command)

	TableOfPOCalculationErrors.Clear();
	CurrentStatusBar = Object.EmployeePayrollCalculationStatuses[0];
	
	If CurrentStatusBar.SignLock Then
		
		NewRow = TableOfPOCalculationErrors.Add();
		NewRow.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Расчет по сотруднику заблокирован за период:%1 по организации: %2';
									|vi = 'Calculation for the employee is locked for period %1 for the %2 company';
									|en = 'Calculation for the employee is locked for period %1 for the %2 company'; fa = 'Calculation for the employee is locked for period %1 for the %2 company';
									|it = 'Calculation for the employee is locked for period %1 for the %2 company';
									|pl = 'Calculation for the employee is locked for period %1 for the %2 company';
									|tr = '%2 iş yerinde %1 dönemi için çalışanın hesaplaması kilitlenmiştir.'"),
										Object.CalculationPeriod, Object.Organization);
		
		ManagingFormOfMessages();

		Return;
		
	EndIf;	
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("Organization",      Object.Organization);
	CalculationParameters.Insert("CalculationPeriod",    Object.CalculationPeriod);
	CalculationParameters.Insert("Department",    Object.Department);
	CalculationParameters.Insert("ContinueSalaryCalculation", True);
	CalculationParameters.Insert("AddressOfCalculationStatusesTable", AddressOfStatusTableATServer(False));	
						
	PayrollCalculationHRClient.CalculateAccruals(CalculationParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure EmployeeSPaySheet(Command)

	AttachIdleHandler("BillingSheetIsOnClient", 0.1, True);
	
EndProcedure

#EndRegion

#Region Private 

&AtClient
Procedure UpdateTableSelection(CurrentPage)
	
	If CurrentPage = Items.OrganizationSTaxesGroup Then

		SetListFilter(Taxes, "DeductedFromEmployeeWages", False);
		
	ElsIf CurrentPage = Items.GroupEmployeeTaxes Then 

		SetListFilter(Taxes, "DeductedFromEmployeeWages", True);
		
	EndIf;	
	
EndProcedure	

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//AccrualsSum
	ListOfConditionalAppearanceOfTaxesTable = Accruals.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearanceOfTaxesTable.Items.Clear();
	
	Item = ListOfConditionalAppearanceOfTaxesTable.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ManualAccrual");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);	

	//TaxesAmount
	ListOfConditionalAppearanceOfTaxesTable = Taxes.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearanceOfTaxesTable.Items.Clear();
	
	Item = ListOfConditionalAppearanceOfTaxesTable.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ManualTax");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);	
	
	//DeductionsSum
	ListConditionalAppearanceOfRetentionTable = Deductions.SettingsComposer.Settings.ConditionalAppearance;
	ListConditionalAppearanceOfRetentionTable.Items.Clear();
	
	Item = ListConditionalAppearanceOfRetentionTable.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ManualDeduction");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);	
	
EndProcedure 

&AtServer
Function AddressOfStatusTableATServer(SignLock = False)
	
	FilterByEmployee = New Structure("SignLock,ThereAreErrorsInTimesheets", SignLock,False);
		
	TableForCalculation = Object.EmployeePayrollCalculationStatuses.Unload(FilterByEmployee); 
						
	Return PutToTempStorage(
					TableForCalculation, 
					UUID); 
	
EndFunction

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
	
EndProcedure	

&AtServer
Procedure SetVisibility1()
	
	ThereAreErrorsInAccruals = TableOfPOCalculationErrors.Unload(
							New Structure("ErrorInAccruals", True)).Count() > 0;

	ThereAreErrorsInDeductions = TableOfPOCalculationErrors.Unload(
							New Structure("ErrorInDeductions", True)).Count() > 0;
							
	ThereAreErrorsInTaxesFromEmployee = TableOfPOCalculationErrors.Unload(
							New Structure("EmployeeTaxError", True)).Count() > 0;

	ThereAreErrorsInTaxesFromCompany = TableOfPOCalculationErrors.Unload(
							New Structure("ErrorInCompanyTaxes", True)).Count() > 0;	 
							
	ExclamationPointRed = PictureLib.ExclamationPointRed;	
	NoPicture = New Picture;;
							
	Items.AccrualGroup.Picture = ?(ThereAreErrorsInAccruals, ExclamationPointRed, NoPicture);	
	Items.OrganizationSTaxesGroup.Picture = ?(ThereAreErrorsInTaxesFromCompany, ExclamationPointRed, NoPicture);	
	Items.GroupEmployeeTaxes.Picture = ?(ThereAreErrorsInTaxesFromEmployee, ExclamationPointRed, NoPicture);	
	Items.RetentionGroup.Picture = ?(ThereAreErrorsInDeductions, ExclamationPointRed, NoPicture);
	
	TableOfAccrualErrors = TableOfPOCalculationErrors.Unload(New Structure("ErrorInAccruals", True));
	Accruals.SettingsComposer.Settings.AdditionalProperties.Insert("AddressOfErrorTable", 
										PutToTempStorage(TableOfAccrualErrors, UUID));
														
	ErrorTableForEmployeeTaxes = TableOfPOCalculationErrors.Unload(New Structure("EmployeeTaxError", True));
	ErrorTableForCompanyTaxes= TableOfPOCalculationErrors.Unload(New Structure("ErrorInCompanyTaxes", True));  
	
	Taxes.SettingsComposer.Settings.AdditionalProperties.Insert("AddressOfErrorTableTaxesFromEmployee", 
										PutToTempStorage(ErrorTableForEmployeeTaxes, UUID));
														
	Taxes.SettingsComposer.Settings.AdditionalProperties.Insert("AddressOfErrorTableTaxesFromCompany", 
										PutToTempStorage(ErrorTableForCompanyTaxes, UUID));
														
	TableOfRetentionErrors = TableOfPOCalculationErrors.Unload(New Structure("ErrorInDeductions", True));  
	Deductions.SettingsComposer.Settings.AdditionalProperties.Insert("AddressOfErrorTable", 
										PutToTempStorage(TableOfRetentionErrors, UUID));
	
	Items.Accruals.Refresh();
	Items.CompanyTaxes.Refresh();
	Items.TaxesEmployee.Refresh();
	Items.Deductions.Refresh();
	
EndProcedure	

&AtClient
Procedure UpdateDynamicQueryParameters()
	
	Accruals.Parameters.SetParameterValue("BeginOfPeriod", Object.CalculationPeriod);
	Accruals.Parameters.SetParameterValue("EndOfPeriod",  EndOfMonth(Object.CalculationPeriod));	
	SetListFilter(Accruals, "Organization", 				  Object.Organization);
	SetListFilter(Accruals, "Department", 				  Object.Department, 
																	  ValueIsFilled(Object.Department));
	
	Taxes.Parameters.SetParameterValue("BeginOfPeriod", Object.CalculationPeriod);
	Taxes.Parameters.SetParameterValue("EndOfPeriod",  EndOfMonth(Object.CalculationPeriod));
	SetListFilter(Taxes, "Organization", 				  Object.Organization);
	SetListFilter(Taxes, "Department", 				  Object.Department, 
																  ValueIsFilled(Object.Department));

	Deductions.Parameters.SetParameterValue("BeginOfPeriod", Object.CalculationPeriod);
	Deductions.Parameters.SetParameterValue("EndOfPeriod",  EndOfMonth(Object.CalculationPeriod));
	SetListFilter(Deductions, "Organization", 				 Object.Organization);
	SetListFilter(Deductions, "Department", 				 Object.Department, 
																	 ValueIsFilled(Object.Department));
																	 
	SetListFilter(Accruals, "Employee", Employee);
	SetListFilter(Deductions,  "Employee", Employee);
	SetListFilter(Deductions,  "Department", Object.Department);
	SetListFilter(Taxes,     "Employee", Employee);
																	 
EndProcedure	

&AtClient
Procedure SetListFilter(DynamicList, FilterFieldName, FilterValue, Use = True)
	
	CommonClientServer.SetDynamicListFilterItem(
		DynamicList,
		FilterFieldName,
		FilterValue,
		DataCompositionComparisonType.Equal,
		,
		Use,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure	
	
&AtServer
Procedure UpdateResultsOfDecryptionTableByEmployee(AmountIsAccrued, AmountDeductions, TaxesFromEmployee, TaxesFromCompany, AmountToBePaid)
	
	TotalTaxesFromCompany = TaxesFromCompany;
	TotalTaxesPerEmployee = TaxesFromEmployee;
	TotalAccrued = AmountIsAccrued;
	TotalWithheld = AmountDeductions;
	TotalAmount_ToBePaid = AmountToBePaid;
	
EndProcedure	

&AtServer
Procedure SetVisibilityOfDetailFormElements(NameOfDecryptionOperation = "")
		
	Items.SettingsGroup1.ReadOnly = True;
	Items.Employee.ReadOnly = True; 
	
	SetAvailabilityOfCalculationButtonsByDetail(); 
	Items.GroupDetailsByEmployee.CurrentPage = DecryptionPage(NameOfDecryptionOperation);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfCalculationButtonsByDetail()
	
	EmployeeSCurrentLine = Object.EmployeePayrollCalculationStatuses[0];
	SignLock = EmployeeSCurrentLine.SignLock;
	
	Items.DecorationCalculationIsCalculated.Visible = EmployeeSCurrentLine.CalculatedEmployee;
	Items.CalculateData.Enabled = Not SignLock;
	Items.DecorationCalculationIsBlocked.Visible = SignLock;
	Items.UnblockCalculation.Enabled = SignLock;
	Items.EmployeeSPaySheet.Enabled = SignLock; 
	Items.CompanyTaxesCreateManualTaxCalculation.Enabled = Not SignLock;
	Items.AccrualsCreateOneTimeAccrual.Enabled = Not SignLock;
	Items.EmployeeTaxesCreateManualTaxCalculation.Enabled = Not SignLock;
	Items.DeductionsCreateOneTimeDeduction.Enabled = Not SignLock;
	
EndProcedure	

&AtServer
Function DecryptionPage(NameOfDecryptionOperation)
	If Not ValueIsFilled(NameOfDecryptionOperation) Then
		 Return Items.AccrualGroup; 
	EndIf;	 
	
	DecryptionCompliancePage = New Map();
	DecryptionCompliancePage.Insert("DecryptAmountOfAccruals", Items.AccrualGroup);
	DecryptionCompliancePage.Insert("DecryptAmountOfDeductions", Items.RetentionGroup);
	DecryptionCompliancePage.Insert("DecipherAmountOfTaxesFromEmployee", Items.GroupEmployeeTaxes);
	DecryptionCompliancePage.Insert("DecipherAmountOfTaxesFromCompany", Items.OrganizationSTaxesGroup);
	DecryptionCompliancePage.Insert("DecryptAmountToBePaid", Items.AccrualGroup);
	
	Return DecryptionCompliancePage.Get(NameOfDecryptionOperation);
	
EndFunction	

&AtServer
Procedure ConfigureElementsDuringFormInitialization(LoadingSettings = False)

	PresentationOfCalculationPeriod = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.CalculationPeriod);
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Расчет по %1';
				|vi = 'Calculation by %1';
				|en = 'Calculation by %1'; fa = 'Calculation by %1';
				|it = 'Calculation by %1';
				|pl = 'Calculation by %1';
				|tr = '%1 için hesaplama'"), Employee);
	
	Title = TitleText;
	
EndProcedure

&AtServer
Procedure UploadPOCalculationStatusesTableATServer(AddressOfPOCalculationStatusTable)

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

&AtClient
Procedure StartFillingInPOCalculationStatusTable(CallingFromMainForm = False)
	
	Object.EmployeePayrollCalculationStatuses.Clear();
	
	FillParameters = New Structure();
	FillParameters.Insert("CalculationPeriod", Object.CalculationPeriod);	
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Department", Object.Department); 
	FillParameters.Insert("CallingFromMainForm", CallingFromMainForm); 
	FillParameters.Insert("AddressOfPOCalculationStatusTable", 
						PutToTempStorage("", UUID));
						
	ArrayOfEmployees = New Array();
	ArrayOfEmployees.Add(Employee);
	FillParameters.Insert("ArrayOfEmployees", ArrayOfEmployees);
	
	PayrollCalculationHRClient.FillInTableOfStatusesForCalculatingPO(FillParameters, ThisObject);
	
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

&AtClient
Procedure DisplayErrorsInMessageLine(ErrorsArray)

	DisplayErrorsInMessageLineAtServer(ErrorsArray);
	
EndProcedure	

&AtClient
Procedure BillingSheetIsOnClient()
	
	DocumentRef = PredefinedValue("Document.PostingPayrollExpensesInFinancialAccounting2_5.EmptyRef");
	
	ListOfIndividuals = PersonsToReport(DocumentRef);	
	
	BillingSheet = BillingSheetAtServerWithoutContext(Object.Organization, ListOfIndividuals, Object.CalculationPeriod);
	
	PrintManagementClient.ExecutePrintCommand("Report.PayslipHR", "BillingSheet", 
		CommonClientServer.ValueInArray(DocumentRef), ThisObject,
		New Structure("PrintedDocument", BillingSheet));
	
EndProcedure

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

&AtServerNoContext
Function BillingSheetAtServerWithoutContext(Organization, ListOfIndividuals, Month)
	
	Return PayrollAndHumanResourcesReports.BillingSheetForPeriod(Organization, ListOfIndividuals, Month);
	
EndFunction

#EndRegion
