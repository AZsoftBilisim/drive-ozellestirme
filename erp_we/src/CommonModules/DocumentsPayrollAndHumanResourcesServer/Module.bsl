#Region Internal

// Returns the index of the specified row in the employee table.
//
// Parameters:
//   CurrentRowOfTableByEmployees - ValueTableRow - The row for which you need to get the index
//   TableByEmployees - ValueTable - A table containing a row
//
// Returns:
//   Number - Index of a row in a table
Function GetRowIndex(CurrentRowOfTableByEmployees, TableByEmployees) Export

	Return TableByEmployees.IndexOf(CurrentRowOfTableByEmployees);
	
EndFunction	

// Defines the procedure for calculating the accrual per line, depending on the accrual method and currency.
//
// Parameters:
//   Accrual - CatalogRef.AccrualAndDeductionKinds - link to accrual
//   Currency - CatalogRef.Currencies - the currency in which the accrual is made
//
// Returns:
//   String - Accrual Calculation Procedure
Function DetermineProcedureForCalculatingAccrualByLine(Accrual, Currency) Export
	
	Return AccrualCalculationProcedure(Accrual, Currency);
	
EndFunction

// Specifies the order in which retention is calculated for the specified row.
//
// Parameters:
//   Retention - CatalogRef.AccrualAndDeductionKinds - Accrual for which the procedure for calculating the deduction is determined
//   Currency - CatalogRef.Currencies - The currency used to calculate the deduction
//
// Returns:
//   String - The Procedure For Calculating Retention
Function DetermineOrderOfCalculationOfRetentionByLine(Retention, Currency) Export
	
	Return ProcedureForCalculatingRetention(Retention, Currency);
	
EndFunction	  

Procedure FillInProcedureForCalculatingRetentionTable(Deductions, Currency) Export

	For Each CurrentRetention In Deductions Do
		
		CurrentRetention.ValueDescription = ProcedureForCalculatingRetention(CurrentRetention.Retention, Currency);
		
	EndDo;
	
EndProcedure

Procedure FillInCalculationProcedureForAccrualTable(Accruals, Currency) Export

	For Each CurrentAccrual In Accruals Do
		
		CurrentAccrual.ValueDescription = AccrualCalculationProcedure(CurrentAccrual.Accrual, Currency);
		
	EndDo;
	
EndProcedure

// Sets a ban on editing objects of the payroll document Form and personnel, if the document is used in the calculation of payroll.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document for which editing is prohibited:
// 		* Items - FormAllItems - All Form elements
// CheckForEntireCalculationTime - Boolean - Check from the beginning of the period or only for the period
//
Procedure SetBanOnEditingItems(Form, CheckForEntireCalculationTime = True) Export
	
	DocumentReference = Form.Object.Ref;
	
	If Not ValueIsFilled(DocumentReference)
		Or Not GetFunctionalOption("PayrollAndHumanResourcesWE")
		Or Form.ReadOnly Then
		Return;
	EndIf;
	
	If (Not DocumentIsUsedInCalculatingPOData(DocumentReference) 
		   And Not DocumentDataIsUsedToCalculateBlockedPOData(DocumentReference, CheckForEntireCalculationTime)) Then
		 Return;
	 EndIf;	

	Items = Form.Items;
	
	Form.FormDataIsBlocked = True;
	
	ListOfAllowedAttributes = ListOfAttributesAllowedForModification(DocumentReference, Items);
	
	For Each FormItem In Items Do
		
		TagName = FormItem.Name;

		// We skip all programmatically added reports
		If (StrFind(TagName, "ReportsSubmenuSeeAlso") > 0)
			Or (StrFind(TagName, "SubmenuPrintNormal") > 0)
			Or (StrFind(TagName, "ReflectionInAccounting_") > 0) Then
			Continue;
		EndIf;	
		
		If ListOfAllowedAttributes.Find(TagName) <> Undefined Then
			Continue;
		EndIf;	
		
		ElementType = TypeOf(FormItem);
		
		If ElementType = Type("FormField") Then 
			FormItem.ReadOnly = True;  

			If StrFind(TagName, "ReflectionInAccounting_") > 0 Then
				FormItem.Enabled = False;
			EndIf;	
			
		ElsIf ElementType = Type("FormButton") Then
			FormItem.Enabled = False;
		EndIf; 
		
	EndDo;		
	
EndProcedure 	

// Displays messages that you cannot cancel the current document.
//
// Parameters:
// DocumentRef - DocumentObject - The object for which you want to show error messages
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportErrorsCancellationOfEvent(Val DocumentRef, Cancel) Export
	
	If TypeOf(DocumentRef) = Type("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Документ %1 участвует в процессе расчета заработной платы. Отмена проведения невозможна.';
				|vi = 'The ""%1"" document is involved in payroll calculation. Cancellation is unavailable.';
				|en = 'The ""%1"" document is involved in payroll calculation. Cancellation is unavailable.'; fa = 'The ""%1"" document is involved in payroll calculation. Cancellation is unavailable.';
				|it = 'The ""%1"" document is involved in payroll calculation. Cancellation is unavailable.';
				|pl = 'The ""%1"" document is involved in payroll calculation. Cancellation is unavailable.';
				|tr = 'Belge %1 bordro hesaplama sürecine dahil. Kaydın iptali mümkün değil.'"),
			DocumentRef);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Данные документа %1 используются при расчете заработной платы. Отмена проведения невозможна.';
				|vi = 'The ""%1"" document data is used in payroll calculation. Cancellation is unavailable.';
				|en = 'The ""%1"" document data is used in payroll calculation. Cancellation is unavailable.'; fa = 'The ""%1"" document data is used in payroll calculation. Cancellation is unavailable.';
				|it = 'The ""%1"" document data is used in payroll calculation. Cancellation is unavailable.';
				|pl = 'The ""%1"" document data is used in payroll calculation. Cancellation is unavailable.';
				|tr = 'Belge %1 verileri bordro hesaplamasında kullanılıyor. Kaydın iptali mümkün değil.'"),
			DocumentRef);
	EndIf;		
	
	Common.MessageToUser(
			ErrorText,
			DocumentRef,
			,
			,
			Cancel);
	
EndProcedure

// Displays messages that new documents cannot be entered during this period.
//
// Parameters:
// DocumentRef - DocumentObject - The object for which you want to show error messages
// RegistrationMonth - Date - Month of Registration
// ListOfEmployees - ValueTable:
// 	* Employee - CatalogRef.EmployeesHR - List of employees
// Cancel           - Boolean - flag for refusing to carry out the document.
//
Procedure ReportAboutPostErrors(Val DocumentRef, RegistrationMonth, ListOfEmployees, Cancel) Export
	
	For Each CurrentRow In ListOfEmployees Do
	
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Невозможно проведение документа %1. За период %2 уже рассчитана заработная плата по сотруднику %3. Снять блокировку можно в помощнике расчет заработной платы.';
					|vi = 'Cannot post the %1 document. The salary for employee %3 is already calculated for period %2. You can remove the lock in the payroll calculation wizard.';
					|en = 'Cannot post the %1 document. The salary for employee %3 is already calculated for period %2. You can remove the lock in the payroll calculation wizard.'; fa = 'Cannot post the %1 document. The salary for employee %3 is already calculated for period %2. You can remove the lock in the payroll calculation wizard.';
					|it = 'Cannot post the %1 document. The salary for employee %3 is already calculated for period %2. You can remove the lock in the payroll calculation wizard.';
					|pl = 'Cannot post the %1 document. The salary for employee %3 is already calculated for period %2. You can remove the lock in the payroll calculation wizard.';
					|tr = 'Belgenin kaydedilmesi imkansız%1. İlgili dönem%2 için çalışanın bordrosu zaten hesaplanmış.%3 Kilidi maaş hesaplama asistanından kaldırabilirsiniz.'"),
								DocumentRef, MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(RegistrationMonth), CurrentRow.Employee);
	
		Common.MessageToUser(
				ErrorText,
				DocumentRef,
				,
				,
				Cancel);
	EndDo;			
	
EndProcedure

Procedure CheckPossibilityOfDeletingRowsInTable(TabularSectionDescription, Cancel, Form) Export
	
	Object = Form.Object;
	
	If Not GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		Return;
	ElsIf GetFunctionalOption("PayrollAndHumanResourcesWE")
		And BegOfDay(Constants.StartDatePayrollAndHumanResources.Get()) > Object.CalculationsPeriod Then
		Return;
	ElsIf Not DocumentsPayrollAndHumanResourcesServer.DocumentIsUsedInCalculatingPOData(Object.Ref) Then
		Return
	EndIf;	
	
	Cancel = True;

	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Документ %1 участвует в процессе расчета заработной платы. Удаление строк в таблице:%2 невозможно.';
			|vi = 'The ""%1"" document is involved in payroll calculation. Cannot delete rows in the ""%2"" table.';
			|en = 'The ""%1"" document is involved in payroll calculation. Cannot delete rows in the ""%2"" table.'; fa = 'The ""%1"" document is involved in payroll calculation. Cannot delete rows in the ""%2"" table.';
			|it = 'The ""%1"" document is involved in payroll calculation. Cannot delete rows in the ""%2"" table.';
			|pl = 'The ""%1"" document is involved in payroll calculation. Cannot delete rows in the ""%2"" table.';
			|tr = 'Belge %1 bordro hesaplama sürecine dahil. Tabloda satır silme: %2 Mümkün değil.'"),
		Object.Ref, TabularSectionDescription);
	
	Common.MessageToUser(
			ErrorText,
			Object.Ref,
			,
			,
			Cancel);
	
EndProcedure	

Procedure CheckCorrectnessOfMonthOfRegistration(Object, Cancel) Export
	
	StartDateOfManagementPayrollAndPersonnel = Constants.StartDatePayrollAndHumanResources.Get();
	
	ErrorInRegistrationPeriod = StartDateOfManagementPayrollAndPersonnel > Object.RegistrationMonth;
	
	If ErrorInRegistrationPeriod Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверно указан месяц регистрации. Расчет зарплаты и кадров доступен в программе с :%1';
				|vi = 'The registration month is incorrect. Payroll and human resource calculation is available in the application since %1';
				|en = 'The registration month is incorrect. Payroll and human resource calculation is available in the application since %1'; fa = 'The registration month is incorrect. Payroll and human resource calculation is available in the application since %1';
				|it = 'The registration month is incorrect. Payroll and human resource calculation is available in the application since %1';
				|pl = 'The registration month is incorrect. Payroll and human resource calculation is available in the application since %1';
				|tr = 'Kayıt ayı yanlış belirtilmiş. Bordro ve personel hesaplaması programda şu tarihten itibaren kullanılabilir: %1'"),
			Format(StartDateOfManagementPayrollAndPersonnel, "DLF=D"));

		Common.MessageToUser(MessageText, Object, "RegistrationMonth",, Cancel);
		
	EndIf;	
	
EndProcedure

#Region WorkingWithBanner
	
// Displays an information banner 
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document for which editing is prohibited:
// 		* Items - FormAllItems - All Form elements
//	
Procedure ShowHideBanner(Form) Export
	
	Items = Form.Items; 
	Object = Form.Object;
	
	If Not Form.FormDataIsBlocked
		Or Form.ReadOnly Then
		
		Items.BannerOfInformationAboutFormBlocking.Visible = False;
		Return;
		
	EndIf;

	RowsArray = New Array;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5") Then
		
		BannerTextString = NStr("ru = 'В программе включен режим Учет кадров и расчет зарплаты. Документ формируется автоматически';
								|vi = 'Payroll accounting and HR recordkeeping mode is enabled in the program. The document is generated automatically';
								|en = 'Payroll accounting and HR recordkeeping mode is enabled in the program. The document is generated automatically'; fa = 'Payroll accounting and HR recordkeeping mode is enabled in the program. The document is generated automatically';
								|it = 'Payroll accounting and HR recordkeeping mode is enabled in the program. The document is generated automatically';
								|pl = 'Payroll accounting and HR recordkeeping mode is enabled in the program. The document is generated automatically';
								|tr = 'Programda Personel kaydı ve bordro hesaplama modu etkin. Belge otomatik oluşturulur'");
		RowsArray.Add(New FormattedString(BannerTextString));
		RowsArray.Add(" ");
	
		TextHyperlinkOpenPOCalculationCenter = New FormattedString(NStr("ru = 'Расчет заработной платы';
																		|vi = 'Payroll calculation';
																		|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
																		|it = 'Payroll calculation';
																		|pl = 'Payroll calculation';
																		|tr = 'Bordro hesaplama'"),,,, "OpenPayroll");
	
		RowsArray.Add(TextHyperlinkOpenPOCalculationCenter);
		RowsArray.Add(" ");

		BannerTextString = NStr("ru = '. Редактировать можно только “Отражение в учете”';
								|vi = '. You can only edit ""Accounting attributes""';
								|en = '. You can only edit ""Accounting attributes""'; fa = '. You can only edit ""Accounting attributes""';
								|it = '. You can only edit ""Accounting attributes""';
								|pl = '. You can only edit ""Accounting attributes""';
								|tr = '. Sadece ""muhasebeleştirme"" düzenlenebilir'");
		RowsArray.Add(BannerTextString);
		
	Else
	
		BannerTextString = NStr("ru = 'Данные заблокированы, поскольку выполнен расчет заработной платы. Разблокировать документ можно в помощнике';
								|vi = 'The data is locked because the payroll is calculated. You can unlock the document in the wizard';
								|en = 'The data is locked because the payroll is calculated. You can unlock the document in the wizard'; fa = 'The data is locked because the payroll is calculated. You can unlock the document in the wizard';
								|it = 'The data is locked because the payroll is calculated. You can unlock the document in the wizard';
								|pl = 'The data is locked because the payroll is calculated. You can unlock the document in the wizard';
								|tr = 'Bordro hesaplaması yapıldığı için veriler kilitli. Belgenin kilidini yardımcıda açabilirsiniz'");
		RowsArray.Add(New FormattedString(BannerTextString));
		RowsArray.Add(" ");
	
		TextHyperlinkOpenPOCalculationCenter = New FormattedString(NStr("ru = 'Расчет заработной платы';
																		|vi = 'Payroll calculation';
																		|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
																		|it = 'Payroll calculation';
																		|pl = 'Payroll calculation';
																		|tr = 'Bordro hesaplama'"),,,, "OpenPayroll");

		RowsArray.Add(TextHyperlinkOpenPOCalculationCenter);
		RowsArray.Add(" ");
		
	EndIf;		
		
	FontOfBannerText = New Font(StyleFonts.BannerTextFontHR,,10);
	
	Form.BannerText = New FormattedString(RowsArray, FontOfBannerText);
	
	Items.BannerOfInformationAboutFormBlocking.Visible = True;
	
EndProcedure

#EndRegion

// Sets selections in the Form of the document list in accordance with the Form parameters.
//
// Parameters:
//   Form  - ClientApplicationForm - the list form of the document.
//   List - DynamicList - list of documents.
//
// Returns:
//   Boolean - True if the selections are successfully set, otherwise False.
Function SetSelectionsInFormOfDocumentList(Form, List) Export
	
	OpenedFromCRPForm = Form.Parameters.Property("PayrollCalculation");
	
	If Not OpenedFromCRPForm Then
		Return False;
	EndIf;
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	
	Form.Parameters.Filter.Clear();
	
	CommonClientServer.SetDynamicListFilterItem(
			List,
			"Organization",
			Form.Parameters.Organization,
			DataCompositionComparisonType.Equal,
			,
			True,
			DataCompositionSettingsItemViewMode.Normal);
	
	// selection by period.
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"CalculationsPeriod",
		BegOfMonth(Form.Parameters.RegistrationPeriod),
		DataCompositionComparisonType.GreaterOrEqual,
		,
		True,
		DataCompositionSettingsItemViewMode.Normal);
		
	CommonClientServer.AddCompositionItem(
		List.SettingsComposer.Settings.Filter,
		"CalculationsPeriod",
		DataCompositionComparisonType.LessOrEqual,
		EndOfMonth(Form.Parameters.RegistrationPeriod),
		,
		True,
		DataCompositionSettingsItemViewMode.Normal);
	
	Return True;
	
EndFunction

// Checks whether payroll is blocked for the specified employees.
//
// Parameters:
//   Organization - CatalogRef.Companies - the organization for which the check is performed
//   RegistrationMonth - Date - the month for which the check is performed
//   ListOfEmployees - Array of CatalogRef.EmployeesHR - List Of Employees To Check
//
// Returns:
//   ValueTable - table of employees with blocked payroll calculation
//
Function PayrollBlocked(Organization, RegistrationMonth, ListOfEmployees) Export
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Organization", Organization);                 
	Query.SetParameter("RegistrationMonth", RegistrationMonth);                 
	Query.SetParameter("ListOfEmployees", ListOfEmployees);                 
	
	Query.Text = 
	"SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &RegistrationMonth
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN(&ListOfEmployees)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal)";    
	
	Result = Query.Execute();
	
	Return Result.Unload();
EndFunction	

// Checks whether the document data is used in the calculation of the blocked payroll data.
//
// Parameters:
//   DocumentReference - DocumentRef - link to the document being checked
//   CheckForEntireCalculationTime - Boolean - the check flag for the entire calculation time
//
// Returns:
//   Boolean - indicates the use of document data in the calculation of blocked salary data
Function DocumentDataIsUsedToCalculateBlockedPOData(DocumentReference, CheckForEntireCalculationTime  = True) Export
	
	If TypeOf(DocumentReference) = Type("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5") Then
		Return False;
	EndIf;	
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("DocumentReference", DocumentReference);                 
	Query.SetParameter("CheckForEntireCalculationTime", CheckForEntireCalculationTime);                 
	
	Query.Text = 
	"SELECT
	|	HiringHR.Employee AS Employee,
	|	HiringHR.Organization AS Organization,
	|	HiringHR.Department AS Department,
	|	HiringHR.DateOfAdmission AS StartDate
	|INTO InputDocuments
	|FROM
	|	Document.HiringHR AS HiringHR
	|WHERE
	|	HiringHR.Posted
	|	AND HiringHR.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	EmployeeTransferHR.Employee,
	|	EmployeeTransferHR.Organization,
	|	EmployeeTransferHR.Department,
	|	EmployeeTransferHR.DateOfTransition
	|FROM
	|	Document.EmployeeTransferHR AS EmployeeTransferHR
	|WHERE
	|	EmployeeTransferHR.Posted
	|	AND EmployeeTransferHR.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	ChangeInBasicEarningsBasicEarnings.Employee,
	|	ChangeInBasicEarnings.Organization,
	|	ChangeInBasicEarnings.Department,
	|	ChangeInBasicEarnings.ChangeDate
	|FROM
	|	Document.ChangeInBasicEarnings.BasicEarnings AS ChangeInBasicEarningsBasicEarnings
	|		LEFT JOIN Document.ChangeInBasicEarnings AS ChangeInBasicEarnings
	|		ON ChangeInBasicEarningsBasicEarnings.Ref = ChangeInBasicEarnings.Ref
	|WHERE
	|	ChangeInBasicEarnings.Posted
	|	AND ChangeInBasicEarnings.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	ChangeInPermanentAccrualsChangesTable.Employee,
	|	ChangeInPermanentAccruals.Organization,
	|	ChangeInPermanentAccruals.Department,
	|	ChangeInPermanentAccruals.ChangeDate
	|FROM
	|	Document.ChangeInPermanentAccruals.ChangesTable AS ChangeInPermanentAccrualsChangesTable
	|		LEFT JOIN Document.ChangeInPermanentAccruals AS ChangeInPermanentAccruals
	|		ON ChangeInPermanentAccrualsChangesTable.Ref = ChangeInPermanentAccruals.Ref
	|WHERE
	|	ChangeInPermanentAccruals.Posted
	|	AND ChangeInPermanentAccruals.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	ChangeInPermanentDeductionsChangesTable.Employee,
	|	ChangeInPermanentDeductions.Organization,
	|	ChangeInPermanentDeductions.Department,
	|	ChangeInPermanentDeductions.ChangeDate
	|FROM
	|	Document.ChangeInPermanentDeductions.ChangesTable AS ChangeInPermanentDeductionsChangesTable
	|		LEFT JOIN Document.ChangeInPermanentDeductions AS ChangeInPermanentDeductions
	|		ON ChangeInPermanentDeductionsChangesTable.Ref = ChangeInPermanentDeductions.Ref
	|WHERE
	|	ChangeInPermanentDeductions.Posted
	|	AND ChangeInPermanentDeductions.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	OneTimeAccrualsHRAccruedByEmployees.Employee,
	|	OneTimeAccrualsHR.Organization,
	|	OneTimeAccrualsHR.Department,
	|	OneTimeAccrualsHR.RegistrationMonth
	|FROM
	|	Document.OneTimeAccrualsHR.AccruedByEmployees AS OneTimeAccrualsHRAccruedByEmployees
	|		LEFT JOIN Document.OneTimeAccrualsHR AS OneTimeAccrualsHR
	|		ON OneTimeAccrualsHRAccruedByEmployees.Ref = OneTimeAccrualsHR.Ref
	|WHERE
	|	OneTimeAccrualsHR.Posted
	|	AND OneTimeAccrualsHR.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	OneTimeDeductionsDeductedByEmployees.Employee,
	|	OneTimeDeductions.Organization,
	|	OneTimeDeductions.Department,
	|	OneTimeDeductions.RegistrationMonth
	|FROM
	|	Document.OneTimeDeductions.DeductedByEmployees AS OneTimeDeductionsDeductedByEmployees
	|		LEFT JOIN Document.OneTimeDeductions AS OneTimeDeductions
	|		ON OneTimeDeductionsDeductedByEmployees.Ref = OneTimeDeductions.Ref
	|WHERE
	|	OneTimeDeductions.Posted
	|	AND OneTimeDeductions.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	TimesheetHRDataOnTime.Employee,
	|	TimesheetHR.Organization,
	|	TimesheetHR.Department,
	|	BEGINOFPERIOD(TimesheetHR.BeginningDateOfPeriod, MONTH)
	|FROM
	|	Document.TimesheetHR.DataOnTime AS TimesheetHRDataOnTime
	|		LEFT JOIN Document.TimesheetHR AS TimesheetHR
	|		ON TimesheetHRDataOnTime.Ref = TimesheetHR.Ref
	|WHERE
	|	TimesheetHR.Posted
	|	AND TimesheetHR.Ref = &DocumentReference
	|
	|GROUP BY
	|	TimesheetHRDataOnTime.Employee,
	|	TimesheetHR.Organization,
	|	TimesheetHR.Department,
	|	BEGINOFPERIOD(TimesheetHR.BeginningDateOfPeriod, MONTH)
	|
	|UNION ALL
	|
	|SELECT
	|	DismissalHR.Employee,
	|	DismissalHR.Organization,
	|	DismissalHR.Department,
	|	DismissalHR.DateOfDismissal
	|FROM
	|	Document.DismissalHR AS DismissalHR
	|WHERE
	|	DismissalHR.Posted
	|	AND DismissalHR.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	ManualTaxCalculationEmployeeTaxIsAccrued.Employee,
	|	ManualTaxCalculation.Organization,
	|	ManualTaxCalculation.Department,
	|	ManualTaxCalculation.RegistrationMonth
	|FROM
	|	Document.ManualTaxCalculation.EmployeeTaxIsAccrued AS ManualTaxCalculationEmployeeTaxIsAccrued
	|		LEFT JOIN Document.ManualTaxCalculation AS ManualTaxCalculation
	|		ON ManualTaxCalculationEmployeeTaxIsAccrued.Ref = ManualTaxCalculation.Ref
	|WHERE
	|	ManualTaxCalculation.Posted
	|	AND ManualTaxCalculation.Ref = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	ApplyDeductions.Employee,
	|	ApplyDeductions.Organization,
	|	NULL,
	|	ApplyDeductions.RegistrationMonth
	|FROM
	|	Document.ApplyDeductions AS ApplyDeductions
	|WHERE
	|	ApplyDeductions.Posted
	|	AND ApplyDeductions.Ref = &DocumentReference
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Deductions_HR.Period AS StartDate,
	|	Deductions_HR.Organization AS Organization
	|INTO GeneralDataEntryTable
	|FROM
	|	InformationRegister.Deductions_HR AS Deductions_HR
	|WHERE
	|	Deductions_HR.DocumentRecorder = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	NonTaxableAccrualsHR.Period,
	|	NonTaxableAccrualsHR.Organization
	|FROM
	|	InformationRegister.NonTaxableAccrualsHR AS NonTaxableAccrualsHR
	|WHERE
	|	NonTaxableAccrualsHR.DocumentRecorder = &DocumentReference
	|
	|UNION ALL
	|
	|SELECT
	|	TaxRatesHR.Period,
	|	TaxRatesHR.Organization
	|FROM
	|	InformationRegister.TaxRatesHR AS TaxRatesHR
	|WHERE
	|	TaxRatesHR.DocumentRecorder = &DocumentReference
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization
	|FROM
	|	InputDocuments AS InputDocuments
	|		LEFT JOIN InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|		ON InputDocuments.Organization = StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization
	|			AND InputDocuments.Employee = StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee
	|			AND (CASE
	|				WHEN &CheckForEntireCalculationTime
	|					THEN BEGINOFPERIOD(InputDocuments.StartDate, MONTH) <= StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod
	|				ELSE BEGINOFPERIOD(InputDocuments.StartDate, MONTH) = StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod
	|			END)
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal)
	|
	|UNION ALL
	|
	|SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization
	|FROM
	|	GeneralDataEntryTable AS GeneralDataEntryTable
	|		LEFT JOIN InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|		ON GeneralDataEntryTable.Organization = StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization
	|			AND (CASE
	|				WHEN &CheckForEntireCalculationTime
	|					THEN BEGINOFPERIOD(GeneralDataEntryTable.StartDate, MONTH) <= StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod
	|				ELSE BEGINOFPERIOD(GeneralDataEntryTable.StartDate, MONTH) = StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod
	|			END)
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal)";
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
EndFunction

// Checks whether the document is used in the calculation of salary data.
//
// Parameters:
//   DocumentReference - DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5 - link to the document for verification
//
// Returns:
//   Boolean - whether the document is used for calculating salary data
//	
Function DocumentIsUsedInCalculatingPOData(DocumentReference) Export 
	
	If TypeOf(DocumentReference) <> Type("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5") Then
		Return False;
	EndIf;	
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting = &DocumentReference
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal)";
	
	Query.SetParameter("DocumentReference", DocumentReference); 
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction	

// Returns the text of the accrual calculation procedure depending on the accrual method and currency.
//
// Parameters:
//   Accrual - CatalogRef.AccrualAndDeductionKinds - Accrual Method
//   Currency           - String - accrual currency
//
// Returns:
//   String - text of the accrual calculation procedure
//
Function AccrualCalculationProcedure(Accrual, Currency) Export

	AccrualMethod = Common.ObjectAttributeValue(Accrual, "AccrualMethod");

	If AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Указанной суммой за месяц (%1)';
					|vi = 'By specified amount per month (%1)';
					|en = 'By specified amount per month (%1)'; fa = 'By specified amount per month (%1)';
					|it = 'By specified amount per month (%1)';
					|pl = 'By specified amount per month (%1)';
					|tr = 'Aylık belirtilen tutar (%1)'"), Currency);
		
	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerHour Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Указанной суммой за час (%1)';
					|vi = 'By specified amount per hour (%1)';
					|en = 'By specified amount per hour (%1)'; fa = 'By specified amount per hour (%1)';
					|it = 'By specified amount per hour (%1)';
					|pl = 'By specified amount per hour (%1)';
					|tr = 'Saatlik belirtilen tutar (%1)'"), Currency);
		
	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.Development_1 Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Оплачивается по выработке';
					|vi = 'Paid by output';
					|en = 'Paid by output'; fa = 'Paid by output';
					|it = 'Paid by output';
					|pl = 'Paid by output';
					|tr = 'İş çıtısına göre ödenir'"), Currency);

	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerDay Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Указанной суммой за день (%1)';
					|vi = 'By specified amount per day (%1)';
					|en = 'By specified amount per day (%1)'; fa = 'By specified amount per day (%1)';
					|it = 'By specified amount per day (%1)';
					|pl = 'By specified amount per day (%1)';
					|tr = 'Günlük belirtilen tutar (%1)'"), Currency);
				
	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalary Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Окладом (%1)';
					|vi = 'Base salary (%1)';
					|en = 'Base salary (%1)'; fa = 'Base salary (%1)';
					|it = 'Base salary (%1)';
					|pl = 'Base salary (%1)';
					|tr = 'Sabit ücret (%1)'"), Currency);
				
	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Окладом пропорционально отработанным дням (%1)';
					|vi = 'By base salary in proportion to days worked (%1)';
					|en = 'By base salary in proportion to days worked (%1)'; fa = 'By base salary in proportion to days worked (%1)';
					|it = 'By base salary in proportion to days worked (%1)';
					|pl = 'By base salary in proportion to days worked (%1)';
					|tr = 'Çalışılan günlere oranla sabit ücret  (%1)'"), Currency);
				
	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Окладом пропорционально отработанным часам (%1)';
					|vi = 'By base salary in proportion to hours worked (%1)';
					|en = 'By base salary in proportion to hours worked (%1)'; fa = 'By base salary in proportion to hours worked (%1)';
					|it = 'By base salary in proportion to hours worked (%1)';
					|pl = 'By base salary in proportion to hours worked (%1)';
					|tr = 'Çalışılan saatlere oranla sabit ücret  (%1)'"), Currency);
				
	ElsIf AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth Then
		
		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Указанной суммой за месяц (%1)';
					|vi = 'By specified amount per month (%1)';
					|en = 'By specified amount per month (%1)'; fa = 'By specified amount per month (%1)';
					|it = 'By specified amount per month (%1)';
					|pl = 'By specified amount per month (%1)';
					|tr = 'Aylık belirtilen tutar (%1)'"), Currency);
		
	Else 
		
		TextOfCalculationProcedure = "";		
	EndIf;

	Return TextOfCalculationProcedure;

EndFunction

// Checks employee accrual
//
// Parameters:
//   DateOfSelection - Date
//   CheckParameters - Structure - a set of search parameters:
//   *AccrualDeduction - CatalogRef.AccrualAndDeductionKinds - Accrual or withholding 
//   *ListOfEmployees - Array of CatalogRef.EmployeesHR
//   Cancel - Boolean
//
// Returns:
//   Array of CatalogRef.EmployeesHR - List of employees
//
Function CheckEmployeeAccrualForTimeFence(DateOfSelection, CheckParameters, Cancel) Export
	
	AccrualDeduction = CheckParameters.AccrualDeduction;	
	ListOfEmployees =   CheckParameters.ListOfEmployees;	
	
	AccrualRetentionParameters = Common.ObjectAttributesValues(AccrualDeduction, "InputFrequency,ItIsADeduction");
	
	If AccrualRetentionParameters.InputFrequency <> 2 Then
		Return New Array;;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("DateOfSelection",          DateOfSelection);
	Query.SetParameter("AccrualDeduction", AccrualDeduction);
	Query.SetParameter("ListOfEmployees",   ListOfEmployees);
	
	Query.Text = 
	"SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee AS Employee
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&DateOfSelection,
	|			AccrualDeduction = &AccrualDeduction
	|				AND Employee IN (&ListOfEmployees)) AS RegularAccrualsAndDeductionsHRSliceLast";
	
	TableOfFoundEmployees = Query.Execute().Unload();
	
	Return TableOfFoundEmployees.UnloadColumn("Employee");
	
EndFunction	

// Determines whether the accrual standard hours are needed or not
//
// Parameters:
//   Accrual - CatalogRef.AccrualAndDeductionKinds - Accrual Method
//
// Returns:
//   Boolean - The truth is that we need a standard hour
//
Function ForThisAccrualYouNeedStandardHours(Accrual) Export

	If Not ValueIsFilled(Accrual) Then
		Return False;
	EndIf;	
	
	MethodOfAccrualOfAccrual = 
			Common.ObjectAttributeValue(Accrual, "AccrualMethod");	
			
	WeNeedStandardHours = (MethodOfAccrualOfAccrual = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked 
			Or MethodOfAccrualOfAccrual = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked);
			
	Return WeNeedStandardHours;
	
EndFunction	

#EndRegion

#Region Private

Function ListOfAttributesAllowedForModification(DocumentReference, Items)
	
	ItemsNames = TimeTrackingServer.GetNamesOfFormElements();
	
	AttributesArray = New Array();
	AttributesArray.Add(ItemsNames.IFRSEntries);
	AttributesArray.Add(ItemsNames.IFRSEntriesExtendedTooltip);
	AttributesArray.Add("FormHelp");
	AttributesArray.Add("ReportsSubmenu");
	AttributesArray.Add("FormCopy");
	AttributesArray.Add("FormCopyExtendedTooltip");
	AttributesArray.Add("FormShowInList");
	AttributesArray.Add(ItemsNames.ShowInList);
	AttributesArray.Add(ItemsNames.ShowInListExtendedTooltip);
	AttributesArray.Add("FormShowInListExtendedTooltip");
	AttributesArray.Add("FormCreateBasedOn");
	AttributesArray.Add("ReportsSubmenuExtendedTooltip");
	AttributesArray.Add("ReportsImportantSubmenu");
	AttributesArray.Add("ReportsImportantSubmenuExtendedTooltip");
	AttributesArray.Add("SubmenuReportsStandard");
	AttributesArray.Add("SubmenuReportsStandardExtendedTooltip");
	AttributesArray.Add("ReportsSubmenuSeeAlso"); 
	AttributesArray.Add("FormGlobalCommands"); 
	
	AttributesArray.Add("AccrualsPostingOption");
	AttributesArray.Add("TaxesContributionsOfOrganizationSettingUpReflectionInAccounting");
	
	// Rules only for the document reflection of the payment in the Financial account2_5
	If TypeOf(DocumentReference) = Type("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5") Then
		
		AttributesArray.Add("FormWrite");
		AttributesArray.Add("FormPost"); 
		AttributesArray.Add("FormPostAndClose"); 
		AttributesArray.Add("ChangeTheAccrualReflectionSettings"); 
		AttributesArray.Add("ChangeTheOrganizationSTaxesContributionsReflectionSettings"); 
		AttributesArray.Add("ChangeTheHoldReflectionSettings"); 
	
	EndIf;
	
	Return AttributesArray; 
	
EndFunction	

Function ProcedureForCalculatingRetention(Retention, Currency)
	
	InputFrequency = Common.ObjectAttributeValue(Retention, "InputFrequency");
	
	If InputFrequency = 1 Then

		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Постоянной суммой за месяц (%1)';
					|vi = 'By permanent amount per month (%1)';
					|en = 'By permanent amount per month (%1)'; fa = 'By permanent amount per month (%1)';
					|it = 'By permanent amount per month (%1)';
					|pl = 'By permanent amount per month (%1)';
					|tr = 'Aylık sabit tutar (%1)'"), Currency);
				
	ElsIf InputFrequency = 2 Then

		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Разовой, ежемесячной суммой за месяц (%1)';
					|vi = 'By one-time, monthly amount per month (%1)';
					|en = 'By one-time, monthly amount per month (%1)'; fa = 'By one-time, monthly amount per month (%1)';
					|it = 'By one-time, monthly amount per month (%1)';
					|pl = 'By one-time, monthly amount per month (%1)';
					|tr = 'Tek seferlik, aylık tutar (%1)'"), Currency);
	
	ElsIf InputFrequency = 3 Then

		TextOfCalculationProcedure = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Разовой, нерегулярной суммой (%1)';
					|vi = 'By one-time, irregular amount (%1)';
					|en = 'By one-time, irregular amount (%1)'; fa = 'By one-time, irregular amount (%1)';
					|it = 'By one-time, irregular amount (%1)';
					|pl = 'By one-time, irregular amount (%1)';
					|tr = 'Tek seferlik, düzensiz tutar %1()'"), Currency);
				
	Else
		
		TextOfCalculationProcedure = "";
	EndIf;

	Return TextOfCalculationProcedure;

EndFunction

// Returns boolean values to specify whether you need
// to specify the amount for the accrual or deduction method
//
// Parameters:
//   The method of calculation of retention is a reference link.Types of deduction of deductions - type of accrual (deduction)
//
// Returns:
//   Boolean - True if you do not need to specify the amount
Function MethodOfAccrualOfDeductionWithoutSpecifyingAmountServer(AccrualsOfDeductions, BasicEarnings = False) Export
	
	StructureOfAccrualAttributes = Common.ObjectAttributesValues(AccrualsOfDeductions, "AccrualMethod, InputFrequency");
	
	If (Not BasicEarnings 
		And (StructureOfAccrualAttributes.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked
		Or StructureOfAccrualAttributes.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked))
		Or StructureOfAccrualAttributes.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.Development_1
		Or StructureOfAccrualAttributes.InputFrequency = 2 
		Or StructureOfAccrualAttributes.InputFrequency = 3 Then
			
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns Boolean values to clarify whether
// it is necessary to specify an advance payment for basic earnings
//
// Parameters:
//   The method of calculation of retention is a reference link.Types of deduction of deductions - type of accrual (deduction)
//
// Returns:
//   Boolean - True if you do not need to specify the amount
Function MethodOfAccrualOfDeductionWithoutSpecifyingAdvanceServer(AccrualsOfDeductions, BasicEarnings = False) Export
	
	StructureOfAccrualAttributes = Common.ObjectAttributesValues(AccrualsOfDeductions, "AccrualMethod, InputFrequency");
	
	If BasicEarnings 
		And StructureOfAccrualAttributes.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.Development_1 Then
			
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Returns a list of individuals working in the organization and their associated data according to the parameters.
//
// Parameters:
//   DataParameters - Structure - contains parameters for data selection and calculation:
//     * GetAdvance - Boolean - indication of the need to receive advance payment data;
//     * GetDebts - Boolean - a sign of the need to obtain data on debts;
//     * GetBankAccount - Boolean - indicates that you need to get a bank account;
//     * Period - Date - the period for which the data is based;
//     * Organization - CatalogRef.Companies - The company for which the data is being created.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - CatalogRef.Persons - individual;
//     * Value - Structure - structure with person data. Contains fields:
//       * Salary - Number - salary amount;
//       * Prepayment_ - Number - advance payment amount;
//       * ToBePaid - Number - total amount to be paid;
//       * Debt - Number - amount of debt;
//       * BankAccount - CatalogRef.CounterpartyBankAccounts - bank account for payment.
Function GetFillingDataForIndividuals(DataParameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DocumentsPayrollAndHumanResourcesServer.GetFillingDataForIndividuals");
		
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	EmploymentRecordSliceLast.Employee AS Employee,
	|	MAX(EmploymentRecordSliceLast.Period) AS Period
	|INTO PersonnelHistoryDataGrouped
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(&PeriodLimit, Organization = &Organization) AS EmploymentRecordSliceLast
	|
	|GROUP BY
	|	EmploymentRecordSliceLast.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PersonnelHistoryDataGrouped.Employee AS Employee,
	|	Persons.Ref AS Individual
	|FROM
	|	PersonnelHistoryDataGrouped AS PersonnelHistoryDataGrouped
	|		INNER JOIN InformationRegister.EmploymentRecord.SliceLast(&PeriodLimit, Organization = &Organization) AS EmploymentRecordSliceLast
	|		ON PersonnelHistoryDataGrouped.Employee = EmploymentRecordSliceLast.Employee
	|			AND PersonnelHistoryDataGrouped.Period = EmploymentRecordSliceLast.Period
	|		INNER JOIN Catalog.Persons AS Persons
	|		ON PersonnelHistoryDataGrouped.Employee.Individual = Persons.Ref
	|WHERE
	|	EmploymentRecordSliceLast.WorksInBusinessUnit
	|	AND CASE
	|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN TRUE
	|			ELSE EmploymentRecordSliceLast.Department IN HIERARCHY (&Department)
	|		END
	|";
	
	For Each KeyAndValue In DataParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	QueryResult = Query.Execute();
	ArrayOfEmployees = QueryResult.Unload().UnloadColumn("Individual");
	DataParameters.Insert("ArrayOfEmployees", ArrayOfEmployees);
	DataCompliance = GetCalculationDataForIndividuals(DataParameters);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return DataCompliance;
	
EndFunction

// Returns calculated data for individuals for the specified period and organization.
//
// Parameters:
//   DataParameters - Structure - A set of parameters for calculation. The structure contains the keys:
//     "Period" - Date - The date on which the data is received.
//     "Company" - Directory Link.Companies - The Company for which the calculation is performed.
//     "MassifSotrudnikov" - Array from the reference link.Physical entity - A list of individuals.
//     "Get Advance" - Boolean - A sign of the need to receive data in advance.
//     "Get debts" - Boolean - A sign of the need to get data on debts.
//     "Get a Bank account" - Boolean - A sign of the need to get data on bank accounts.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - CatalogRef.Persons - individual;
//     * Value - Structure - structure with person data. Contains the fields:
//     "Salary" - Number - Amount of accrued salary.
//     "Advance" - The number - The amount of the advance.
//     "Payment" - Number - The amount to be paid.
//     "Debt" - Number - The amount of the company's debt to the employee.
//     "Bank Account" - Directory Link.Agent Bank Account - A bank account for payment.
Function GetCalculationDataForIndividuals(DataParameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DocumentsPayrollAndHumanResourcesServer.GetCalculationDataForIndividuals");
		
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Persons.Ref AS Individual
	|INTO TablePersons
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Ref IN (&ArrayOfEmployees)
	|
	|INDEX BY
	|	Individual
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Persons.Ref AS Individual,
	|	SUM(RegularAccrualsAndDeductionsHRSliceLast.Prepayment_) AS Prepayment_
	|INTO Prepayments
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(&PeriodLimit, &GetAdvance
	|	AND Organization = &Organization
	|	AND Employee.Individual IN
	|		(SELECT DISTINCT
	|			TablePersons.Individual
	|		FROM
	|			TablePersons AS TablePersons)
	|	AND BasicEarnings = TRUE
	|	AND Valid = TRUE) AS RegularAccrualsAndDeductionsHRSliceLast
	|		INNER JOIN Catalog.Persons AS Persons
	|		ON RegularAccrualsAndDeductionsHRSliceLast.Employee.Individual = Persons.Ref
	|GROUP BY
	|	Persons.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollCalculationsHRBalance.Individual AS Individual,
	|	SUM(-1 * PayrollCalculationsHRBalance.SumBalance) AS Accrued,
	|	SUM(-1 * PayrollCalculationsHRBalance.AmountToBePaidBalance) AS Debt
	|INTO BalancesOfSettlements
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR.Balance(&PeriodLimit, &GetDebts
	|	AND Organization = &Organization
	|	AND Individual IN
	|		(SELECT
	|			TablePersons.Individual
	|		FROM
	|			TablePersons)) AS PayrollCalculationsHRBalance
	|GROUP BY
	|	PayrollCalculationsHRBalance.Individual
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TablePersons.Individual AS Individual,
	|	CASE
	|		WHEN &GetAdvance
	|			THEN ISNULL(Prepayments.Prepayment_, 0) - ISNULL(BalancesOfSettlements.Debt, 0)
	|		ELSE ISNULL(BalancesOfSettlements.Accrued, 0) - ISNULL(BalancesOfSettlements.Debt, 0)
	|	END AS ToBePaid,
	|	ISNULL(Prepayments.Prepayment_, 0) AS Prepayment_,
	|	CASE
	|		WHEN &GetAdvance
	|			THEN ISNULL(Prepayments.Prepayment_, 0)
	|		ELSE ISNULL(BalancesOfSettlements.Accrued, 0)
	|	END AS Accrued,
	|	ISNULL(BalancesOfSettlements.Debt, 0) AS Debt
	|FROM
	|	TablePersons AS TablePersons
	|		LEFT JOIN BalancesOfSettlements AS BalancesOfSettlements
	|		ON TablePersons.Individual = BalancesOfSettlements.Individual
	|		LEFT JOIN Prepayments AS Prepayments
	|		ON TablePersons.Individual = Prepayments.Individual";
	
	For Each KeyAndValue In DataParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	DataCompliance = New Map;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	BankingAccountDetails = New Map;
	If DataParameters.GetBankAccount Then
		BankingAccountDetails = GetDataOnBankAccounts(DataParameters);
	EndIf;

	FixedDataStructure = New FixedStructure("Accrued, Prepayment_, ToBePaid, Debt, BankAccount",0,0,0,0,"");
	While Selection.Next() Do
		CurrentStructureOfData = New Structure(FixedDataStructure);
		FillPropertyValues(CurrentStructureOfData, Selection);
		If DataParameters.GetBankAccount Then
			CurrentStructureOfData.Insert("BankAccount", BankingAccountDetails.Get(Selection.Individual));
		EndIf;
		DataCompliance.Insert(Selection.Individual, CurrentStructureOfData);
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return DataCompliance;
	
EndFunction

// Returns data on individuals' bank accounts. 
// Parameters:
//  DataParameters -  Structure: 
//   "Period" Date;
//   "Organization" Reference link.Organizations;
//   "Bank" Reference link.Classificator of banks;
//   "Massifsotrudniki" Array from the reference link.Physical beauty.
// Returns:
//   Map of KeyAndValue:
//     * Key - CatalogRef.Persons - individual;
//     * Value - CatalogRef.CounterpartyBankAccounts - counterparty's bank account;
Function GetDataOnBankAccounts(DataParameters) Export

	Query = New Query;
	Query.Text = 
		"SELECT
		|	CounterpartyBankAccounts.Owner AS Individual,
		|	CounterpartyBankAccounts.Ref AS BankAccount
		|INTO BankAccountsOfIndividuals
		|FROM
		|	Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
		|WHERE
		|	CASE
		|			WHEN &Bank = VALUE(Catalog.BankClassifier.EmptyRef)
		|				THEN TRUE
		|			ELSE CounterpartyBankAccounts.Bank = &Bank
		|		END
		|	AND NOT CounterpartyBankAccounts.DeletionMark
		|	AND NOT CounterpartyBankAccounts.Closed
		|	AND CounterpartyBankAccounts.Owner IN(&ArrayOfEmployees)
		|
		|INDEX BY
		|	BankAccount,
		|	Individual
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	PayrollStatementHRContent.BankAccount AS BankAccount,
		|	PayrollStatementHRContent.Individual AS Individual,
		|	PayrollStatementHR.Date AS Date
		|INTO AllHistoricalDataOnAccounts
		|FROM
		|	Document.PayrollStatementHR.Content AS PayrollStatementHRContent
		|		INNER JOIN Document.PayrollStatementHR AS PayrollStatementHR
		|		ON PayrollStatementHRContent.Ref = PayrollStatementHR.Ref
		|		INNER JOIN BankAccountsOfIndividuals AS BankAccountsOfIndividuals
		|		ON PayrollStatementHRContent.Individual = BankAccountsOfIndividuals.Individual
		|			AND PayrollStatementHRContent.BankAccount = BankAccountsOfIndividuals.BankAccount
		|WHERE
		|	PayrollStatementHR.Organization = &Organization
		|	AND PayrollStatementHR.PaymentMethodHR = VALUE(Enum.PaymentMethodsHR.EmployeeSBankAccount)
		|	AND NOT PayrollStatementHRContent.BankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	AND PayrollStatementHR.Date <= &Period
		|	AND CASE
		|			WHEN &Bank = VALUE(Catalog.BankClassifier.EmptyRef)
		|				THEN TRUE
		|			ELSE PayrollStatementHRContent.BankAccount.Bank = &Bank
		|		END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HistoricalDataOnAccounts.Individual AS Individual,
		|	MAX(HistoricalDataOnAccounts.Date) AS Date
		|INTO AccountDataGrouped
		|FROM
		|	AllHistoricalDataOnAccounts AS HistoricalDataOnAccounts
		|
		|GROUP BY
		|	HistoricalDataOnAccounts.Individual
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccountDataGrouped.Individual AS Individual,
		|	MAX(HistoricalDataOnAccounts.BankAccount) AS BankAccount
		|INTO HistoricalDataOnAccounts
		|FROM
		|	AccountDataGrouped AS AccountDataGrouped
		|		INNER JOIN AllHistoricalDataOnAccounts AS HistoricalDataOnAccounts
		|		ON AccountDataGrouped.Individual = HistoricalDataOnAccounts.Individual
		|			AND AccountDataGrouped.Date = HistoricalDataOnAccounts.Date
		|
		|GROUP BY
		|	AccountDataGrouped.Individual
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BankAccountsOfIndividuals.Individual AS Individual,
		|	BankAccountsOfIndividuals.BankAccount AS BankAccount,
		|	1 AS Priority
		|INTO AllBankAccounts
		|FROM
		|	BankAccountsOfIndividuals AS BankAccountsOfIndividuals
		|
		|UNION ALL
		|
		|SELECT
		|	HistoricalDataOnAccounts.Individual,
		|	HistoricalDataOnAccounts.BankAccount,
		|	2
		|FROM
		|	HistoricalDataOnAccounts AS HistoricalDataOnAccounts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllBankAccounts.Individual AS Individual,
		|	MAX(AllBankAccounts.Priority) AS Priority
		|INTO MaxPrioritiesBankAccounts
		|FROM
		|	AllBankAccounts AS AllBankAccounts
		|
		|GROUP BY
		|	AllBankAccounts.Individual
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllBankAccounts.Individual AS Individual,
		|	MAX(AllBankAccounts.BankAccount) AS BankAccount
		|FROM
		|	AllBankAccounts AS AllBankAccounts
		|		INNER JOIN MaxPrioritiesBankAccounts AS MaxPrioritiesBankAccounts
		|		ON AllBankAccounts.Individual = MaxPrioritiesBankAccounts.Individual
		|
		|GROUP BY
		|	AllBankAccounts.Individual";
	
	For Each KeyAndValue In DataParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	DataCompliance = New Map;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		DataCompliance.Insert(Selection.Individual, Selection.BankAccount);
	EndDo;
	
	Return DataCompliance;
	
EndFunction

#EndRegion

