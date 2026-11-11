
#Region Internal   

// Returns a structure with parameters for displaying data in the HR accounting system.
//
// Returns:
//   Structure - contains selection and display parameters, such as date, type of accrual, division, employee, document, and selection level:
//     * FilterDate - Date - the date on which the data is displayed.
//     * TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - the type of accrual or deduction for which data is selected.
//     * Department - CatalogRef.BusinessStructure - the division for which the data is selected.
//     * Employee - CatalogRef.EmployeesHR - the employee for whom the data is being selected.
//     * DocumentCalculation - DocumentRef - the document for which the data is selected.
//     * SelectionLevel - String - the selection level by which the data is selected.
//
Function DisplayParameters() Export
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterDate",   Date(1,1,1));
	FormParameters.Insert("TypeOfAccrualDeduction", Catalogs.AccrualAndDeductionKinds.EmptyRef());	
	FormParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());	
	FormParameters.Insert("Employee", Catalogs.AccrualAndDeductionKinds.EmptyRef());	
	FormParameters.Insert("DocumentCalculation", Undefined);	
	FormParameters.Insert("SelectionLevel", "");	
	FormParameters.Insert("EditingFormIsProhibited", False);	
	
	Return FormParameters;	
	
EndFunction	

// Gets the accounting settings for the specified type of accrual or deduction as of the selection date.
//
// Parameters:
//   TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - The type of accrual or deduction that settings are being searched for
//   FilterDate - Date - The date on which the settings are current
//
// Returns:
//   InformationRegisterRecord.SettingOfPostingInAccountingHR - Recording the reflection settings in accounting
//
Function GetAccrualRetentionSettings(TypeOfAccrualDeduction, FilterDate) Export
	
	Filter = New Structure();
	Filter.Insert("TypeOfAccrualDeduction", TypeOfAccrualDeduction);
	Filter.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	Filter.Insert("Employee", Catalogs.EmployeesHR.EmptyRef());
	Filter.Insert("DocumentCalculation", Undefined);
	
	FillingSettings = InformationRegisters.SettingOfPostingInAccountingHR.GetLast(FilterDate, Filter);
	
	Return FillingSettings;
	
EndFunction  

// Returns the current HR accounting reflection settings for the specified parameters.
//
// Parameters:
//   TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - Type of accrual or deduction
//   Employee - CatalogRef.EmployeesHR - The employee settings are being searched for
//   Department - CatalogRef.BusinessStructure - Employee Division
//   DocumentCalculation - Undefined - the foundation document
//   FilterDate - Date - The date the current settings are searched for
//
// Returns:
//   InformationRegisterRecord.SettingOfPostingInAccountingHR - Recording the reflection settings in accounting
//
Function GetSettingsByTaxType(TypeOfAccrualDeduction, Employee, Department, DocumentCalculation, FilterDate) Export
	
	Filter = New Structure();
	Filter.Insert("TypeOfAccrualDeduction", TypeOfAccrualDeduction);
	Filter.Insert("Department", Department);
	Filter.Insert("Employee", Employee);
	Filter.Insert("DocumentCalculation", DocumentCalculation);
	
	FillingSettings = InformationRegisters.SettingOfPostingInAccountingHR.GetLast(FilterDate, Filter);
	
	Return FillingSettings;
	
	
EndFunction	

// Creates and returns a table of values for forming a selection.
//
// Returns:
//   ValueTable - table with columns: Type of deduction, Division, Employee, Document accounts, Index lines:
//   * TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds, CatalogRef.TaxContributionKinds - Type of accrual or deduction
//   * Department - CatalogRef.BusinessStructure - Department
//   * Employee - CatalogRef.EmployeesHR - Employee
//   * DocumentCalculation - DocumentRef - the foundation document
//   * RowIndex - Number - Index of the selection table row
//	
Function NewFilterTable() Export
	
	FilterTable = New ValueTable();
	FilterTable.Columns.Add("TypeOfAccrualDeduction", 
		New TypeDescription("CatalogRef.AccrualAndDeductionKinds, CatalogRef.TaxContributionKinds"));
	FilterTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	FilterTable.Columns.Add("Employee", New TypeDescription("CatalogRef.EmployeesHR"));
	FilterTable.Columns.Add("DocumentCalculation", Documents.AllRefsType());
	FilterTable.Columns.Add("RowIndex", New TypeDescription("Number"));
	
	Return FilterTable;
EndFunction

// Gets the result of selecting the accounting reflection settings for the specified date.
//
// Parameters:
//   FilterTable - ValueTable - Table with data for selecting settings
//   FilterDate - Date - The date on which the settings are selected
//
// Returns:
//   ValueTable - Query result with selected reflection settings:
//   * TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds, CatalogRef.TaxContributionKinds - Type of accrual, withholding or tax
//   * Department - CatalogRef.BusinessStructure - The division for which the setting is selected
//   * Employee - CatalogRef.EmployeesHR - The employee for whom the setting is selected
//   * Document - DocumentRef - The document for which the setting is selected
//
Function GetFilterResult(FilterTable, FilterDate) Export
	
	Query = New Query;  
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("FilterDate",    FilterDate);
	Query.SetParameter("FilterTable", FilterTable);
	
	Query.Text = 
	"SELECT
	|	FilterTable.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	FilterTable.Department AS Department,
	|	FilterTable.Employee AS Employee,
	|	FilterTable.DocumentCalculation AS DocumentCalculation
	|INTO FilterTable
	|FROM
	|	&FilterTable AS FilterTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingOfPostingInAccountingHRSliceLast.Period AS Period,
	|	SettingOfPostingInAccountingHRSliceLast.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	SettingOfPostingInAccountingHRSliceLast.Department AS Department,
	|	SettingOfPostingInAccountingHRSliceLast.Employee AS Employee,
	|	SettingOfPostingInAccountingHRSliceLast.DocumentCalculation AS DocumentCalculation,
	|	SettingOfPostingInAccountingHRSliceLast.PostingOption AS PostingOption,
	|	SettingOfPostingInAccountingHRSliceLast.AllocationBaseType AS AllocationBaseType,
	|	SettingOfPostingInAccountingHRSliceLast.ProductCostElement AS ProductCostElement,
	|	SettingOfPostingInAccountingHRSliceLast.LineOfBusiness AS LineOfBusiness,
	|	SettingOfPostingInAccountingHRSliceLast.ExpenseItem AS ExpenseItem,
	|	SettingOfPostingInAccountingHRSliceLast.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	SettingOfPostingInAccountingHRSliceLast.IncomeItem AS IncomeItem,
	|	SettingOfPostingInAccountingHRSliceLast.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	SettingOfPostingInAccountingHRSliceLast.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	SettingOfPostingInAccountingHRSliceLast.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	SettingOfPostingInAccountingHRSliceLast.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	SettingOfPostingInAccountingHRSliceLast.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	SettingOfPostingInAccountingHRSliceLast.Counterparty AS Counterparty,
	|	SettingOfPostingInAccountingHRSliceLast.IssuancePurpose AS IssuancePurpose,
	|	SettingOfPostingInAccountingHRSliceLast.ARAPObject AS ARAPObject,
	|	SettingOfPostingInAccountingHRSliceLast.DimensionOfExpenses AS DimensionOfExpenses,
	|	SettingOfPostingInAccountingHRSliceLast.DimensionOfRevenue AS DimensionOfRevenue
	|INTO SettingUpFillingOfReflectionInAccounting
	|FROM
	|	InformationRegister.SettingOfPostingInAccountingHR.SliceLast(&FilterDate, ) AS SettingOfPostingInAccountingHRSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SettingUpFillingOfReflectionInAccounting.Period, DATETIME(1, 1, 1, 1, 1, 1)) AS Period,
	|	FilterTable.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	FilterTable.Department AS Department,
	|	FilterTable.Employee AS Employee,
	|	FilterTable.DocumentCalculation AS DocumentCalculation,
	|	SettingUpFillingOfReflectionInAccounting.PostingOption AS PostingOption,
	|	SettingUpFillingOfReflectionInAccounting.AllocationBaseType AS AllocationBaseType,
	|	SettingUpFillingOfReflectionInAccounting.ProductCostElement AS ProductCostElement,
	|	SettingUpFillingOfReflectionInAccounting.LineOfBusiness AS LineOfBusiness,
	|	SettingUpFillingOfReflectionInAccounting.ExpenseItem AS ExpenseItem,
	|	SettingUpFillingOfReflectionInAccounting.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	SettingUpFillingOfReflectionInAccounting.IncomeItem AS IncomeItem,
	|	SettingUpFillingOfReflectionInAccounting.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	SettingUpFillingOfReflectionInAccounting.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	SettingUpFillingOfReflectionInAccounting.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	SettingUpFillingOfReflectionInAccounting.Counterparty AS Counterparty,
	|	SettingUpFillingOfReflectionInAccounting.IssuancePurpose AS IssuancePurpose,
	|	SettingUpFillingOfReflectionInAccounting.ARAPObject AS ARAPObject,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfExpenses AS DimensionOfExpenses,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	FilterTable AS FilterTable
	|		LEFT JOIN SettingUpFillingOfReflectionInAccounting AS SettingUpFillingOfReflectionInAccounting
	|		ON FilterTable.TypeOfAccrualDeduction = SettingUpFillingOfReflectionInAccounting.TypeOfAccrualDeduction
	|			AND FilterTable.Department = SettingUpFillingOfReflectionInAccounting.Department
	|			AND FilterTable.Employee = SettingUpFillingOfReflectionInAccounting.Employee
	|			AND FilterTable.DocumentCalculation = SettingUpFillingOfReflectionInAccounting.DocumentCalculation
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(SettingUpFillingOfReflectionInAccounting.Period, DATETIME(1, 1, 1, 1, 1, 1)),
	|	SettingUpFillingOfReflectionInAccounting.TypeOfAccrualDeduction,
	|	SettingUpFillingOfReflectionInAccounting.Department,
	|	SettingUpFillingOfReflectionInAccounting.Employee,
	|	SettingUpFillingOfReflectionInAccounting.DocumentCalculation,
	|	SettingUpFillingOfReflectionInAccounting.PostingOption,
	|	SettingUpFillingOfReflectionInAccounting.AllocationBaseType,
	|	SettingUpFillingOfReflectionInAccounting.ProductCostElement,
	|	SettingUpFillingOfReflectionInAccounting.LineOfBusiness,
	|	SettingUpFillingOfReflectionInAccounting.ExpenseItem,
	|	SettingUpFillingOfReflectionInAccounting.ExpenseAssetLiabilityItem,
	|	SettingUpFillingOfReflectionInAccounting.IncomeItem,
	|	SettingUpFillingOfReflectionInAccounting.IncomeAssetLiabilityItem,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfExpensesAssetsLiabilities,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfIncomeAssetsLiabilities,
	|	SettingUpFillingOfReflectionInAccounting.IncomeLedgerAccountsSettings,
	|	SettingUpFillingOfReflectionInAccounting.ExpenseLedgerAccountsSettings,
	|	SettingUpFillingOfReflectionInAccounting.Counterparty,
	|	SettingUpFillingOfReflectionInAccounting.IssuancePurpose,
	|	SettingUpFillingOfReflectionInAccounting.ARAPObject,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfExpenses,
	|	SettingUpFillingOfReflectionInAccounting.DimensionOfRevenue
	|FROM
	|	FilterTable AS FilterTable
	|		LEFT JOIN SettingUpFillingOfReflectionInAccounting AS SettingUpFillingOfReflectionInAccounting
	|		ON FilterTable.TypeOfAccrualDeduction = SettingUpFillingOfReflectionInAccounting.TypeOfAccrualDeduction
	|			AND (FilterTable.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|			AND (FilterTable.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND (FilterTable.DocumentCalculation = UNDEFINED)";
	
	Return Query.Execute().Unload();
	
EndFunction


// Fills in the Form Attributes with data about setting up reflection in accounting and checks their correctness.
//
// Parameters:
//   Form - ClientApplicationForm - The Form where Attributes are filled in
//   ReflectionParameters - Structure - Structure with accounting reflection parameters
//   DetailsOfFillingInForm - Structure - Structure with names of Attributes to fill in
//
Procedure FillInAddedHeaderDetails(Form, ReflectionParameters, DetailsOfFillingInForm) Export
	
	RecordingSetting = SettingUpReflectionInAccounting(Form, ReflectionParameters, DetailsOfFillingInForm);
	
	Form[DetailsOfFillingInForm.RecordingSettingPresentation] = ReflectionSettingPresentation(
		ReflectionParameters.TemplateOfPresentation, ReflectionParameters.AttributeProperties, RecordingSetting);
	Form[DetailsOfFillingInForm.ReflectionSettingIsCorrect] = CheckCorrectReflectionSettings(
		ReflectionParameters.AttributeProperties, RecordingSetting);
		
	If Form.Items.Find("PostingOption")<> Undefined Then
		Form.PostingOption = RecordingSetting.PostingOption;
	EndIf;		
		
EndProcedure

// Fills in the Attributes of the tabular part of the document with the HR accounting reflection settings.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document containing the object to fill in
//   DetailsOfFillingInForm - Structure - Structure with data to fill in, including reflection options and selection tables
//   TabularSectionDescription - String - The name of the tabular part of the document in which the Attributes are filled in
//   ReflectionParameters - Structure - Structure with reflection parameters in HR accounting, if not specified, then all are filled in
//
Procedure FillInAddedDetailsOfTablePart(Form, DetailsOfFillingInForm, TabularSectionDescription, ReflectionParameters = Undefined) Export

	Object = Form.Object;
	
	For Each CurrentRow In DetailsOfFillingInForm.FilterTable Do
		
		LineOfTabularPartOfDocument = Object[TabularSectionDescription][CurrentRow.RowIndex];		
		
		If ReflectionParameters = Undefined Then
			ReflectionParameters	= FillReflectionParameters(CurrentRow.TypeOfAccrualDeduction);
		EndIf;
		
		FillParameters = 
		InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters(); 
		
		FillPropertyValues(FillParameters, CurrentRow, "TypeOfAccrualDeduction");	
		
		RecordingSetting = SettingUpReflectionOfTableRowInAccounting(CurrentRow, ReflectionParameters, DetailsOfFillingInForm);
		
		LineOfTabularPartOfDocument[DetailsOfFillingInForm.RecordingSettingPresentation] = ReflectionSettingPresentation(
		ReflectionParameters.TemplateOfPresentation, ReflectionParameters.AttributeProperties, RecordingSetting);
		LineOfTabularPartOfDocument[DetailsOfFillingInForm.ReflectionSettingIsCorrect] = CheckCorrectReflectionSettings(
		ReflectionParameters.AttributeProperties, RecordingSetting);
		
	EndDo;
	
EndProcedure

// Creates and returns a structure with control parameters to be reflected in the ZIK accounting.
//
// Returns:
//   Structure - contains control parameters: Type of Deduction, Division, Employee, Document, level of control, Data control:
//   * TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - type of accrual of deduction.
//   * Department - CatalogRef.BusinessStructure - unit.
//   * Employee - CatalogRef.EmployeesHR - an employee.
//   * DocumentCalculation - DocumentRef - Document.
//   * ControlLevel - String - the level of control.
//   * DateOfControl - Date - date of control.
//	
Function GetControlParameters() Export
	
	ControlParameters = New Structure();
	ControlParameters.Insert("TypeOfAccrualDeduction", Catalogs.AccrualAndDeductionKinds.EmptyRef());
	ControlParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	ControlParameters.Insert("Employee", Catalogs.EmployeesHR.EmptyRef());
	ControlParameters.Insert("DocumentCalculation", Undefined);
	ControlParameters.Insert("ControlLevel", "");
	ControlParameters.Insert("DateOfControl", Date(1,1,1));
	
	Return ControlParameters;
EndFunction

// Checks whether the reflection settings in the accounting are filled in correctly for the specified parameters.
//
// Parameters:
//   ControlParameters - Structure - Parameters for control, containing the level of control, division, type of accrual/retention, employee, document and date of control
//
// Returns:
//   Array of String - list of filling errors.
//
Function CheckCompletionOfReflectionInAccounting(ControlParameters) Export

	ControlLevel =        ControlParameters.ControlLevel;	
	Department =	         ControlParameters.Department;	
	TypeOfAccrualDeduction = ControlParameters.TypeOfAccrualDeduction;	
	Employee =              ControlParameters.Employee;	
	DocumentCalculation =        ControlParameters.DocumentCalculation; 
	DateOfControl =  		 ControlParameters.DateOfControl;
	
	ErrorsArray =  New Array();
	
	ControlLevels = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels();
	
	FilterParameters = InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters();
	FillPropertyValues(FilterParameters, ControlParameters);
	RegisterSelectionData = InformationRegisters.SettingOfPostingInAccountingHR.CaseSensitiveValues(
											FilterParameters, DateOfControl);
											
	If ControlLevel = ControlLevels.ManualTaxLevel Then
		ReflectionParameters	= ParametersForReflectingFillingByTypeOfTax(
				TypeOfAccrualDeduction, Department, Employee, DocumentCalculation, DateOfControl);
	Else	
		ReflectionParameters	= FillReflectionParameters(TypeOfAccrualDeduction);
	EndIf;	
	
	DataStructureForPresentation = InformationRegisters.SettingOfPostingInAccountingHR.DataStructureForPresentation();
	
	For Each CurrentValue In ReflectionParameters.AttributeProperties Do
		
		Value = CurrentValue.Value;
		
		If  Value.Main And Value.AttributeIsRequired Then
			
			AttributeValue = RegisterSelectionData.StructureOfData[CurrentValue.Key];
			
			If Not ValueIsFilled(AttributeValue) Then
			
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не заполнено %1';
						|vi = 'Not filled in: %1';
						|en = 'Not filled in: %1'; fa = 'Not filled in: %1';
						|it = 'Not filled in: %1';
						|pl = 'Not filled in: %1';
						|tr = 'Doldurulmadı %1'"),
						DataStructureForPresentation[CurrentValue.Key]);
				
				ErrorsArray.Add(ErrorText);
				
			EndIf;	
		
		EndIf;	
		
	EndDo;	
	
	Return ErrorsArray; 
	
EndFunction

// Returns a textual Presentation of the state of reflection in payroll accounting for the division.
//
// Parameters:
//   Form - ClientApplicationForm - Form of the subdivision object
//
// Returns:
//   String - Text on the status of reflection in payroll accounting
//
Function PresentationOfReflectionParametersInAccounting(Form) Export
	
	Object = Form.Object;
	
	TextReflectionIsNotSet = NStr("ru = 'Отражение в учете заработной платы не установлено.';
									|vi = 'Payroll accounting is not set.';
									|en = 'Payroll accounting is not set.'; fa = 'Payroll accounting is not set.';
									|it = 'Payroll accounting is not set.';
									|pl = 'Payroll accounting is not set.';
									|tr = 'Bordro muhasebeleştirmesi ayarlanmamış.'");	
	
	If Not ValueIsFilled(Object.Ref) Then

		Return TextReflectionIsNotSet;		
		
	EndIf;	
	
	FilterParameters = InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters();             
	FilterParameters.Department = Object.Ref;
	FilterDate = CurrentSessionDate(); 
	
	RegisterSelectionData = InformationRegisters.SettingOfPostingInAccountingHR.CaseSensitiveValues(
																						FilterParameters, FilterDate);
	
	If RegisterSelectionData.DataReceived 
		And InformationRegisters.SettingOfPostingInAccountingHR.ThereIsCompletedDataOnDivision(
																			RegisterSelectionData.StructureOfData) Then

		TextReflectionIsNotSet = NStr("ru = 'Отражение в учете заработной платы установлено.';
										|vi = 'Payroll accounting is set.';
										|en = 'Payroll accounting is set.'; fa = 'Payroll accounting is set.';
										|it = 'Payroll accounting is set.';
										|pl = 'Payroll accounting is set.';
										|tr = 'Bordro muhasebeleştirmesi ayarlanmış.'");	
		
	EndIf;	
	
	Return TextReflectionIsNotSet;
	
EndFunction

// Defines the accounting parameters for the type of accrual or deduction.
//
// Parameters:
//   TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - Type of accrual or deduction
//
// Returns:
//   Structure - Accounting Reflection Parameters:
//     * PostingOption - EnumRef.AccrualsDeductionsRecordOptions - The option of reflection in accounting.
//
Function FillReflectionParameters(TypeOfAccrualDeduction) Export

	ItIsADeduction = False;	
	ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();
	FillingSettings = New Structure("PostingOption");
	
	If ValueIsFilled(TypeOfAccrualDeduction) Then 
		
		ItIsADeduction = 
		Common.ObjectAttributeValue(TypeOfAccrualDeduction, "ItIsADeduction"); 
		
		If ItIsADeduction Then
			
			ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingDeductions();   
			
		Else	
			
			ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();   
			
		EndIf;
		
		FillingSettings 
			= GetAccrualRetentionSettings(TypeOfAccrualDeduction, CurrentSessionDate());
	EndIf;		
	
	If Not ValueIsFilled(FillingSettings.PostingOption) Then
		
		If ItIsADeduction Then
			PostingOption =
			PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome");
		Else	
			PostingOption =
			PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
		EndIf;		
	Else     
		PostingOption = FillingSettings.PostingOption;	
	EndIf;	
	
	ReflectionParameters = ReflectionOptions[PostingOption];   
	
	Return ReflectionParameters;
	
EndFunction

// Defines the accounting parameters for the specified type of tax, division, and employee.
//
// Parameters:
//   TaxKind - CatalogRef.AccrualAndDeductionKinds - Type of tax to determine reflection settings
//   Department - CatalogRef.BusinessStructure - The division for which the settings are defined
//   Employee - CatalogRef.EmployeesHR - The employee for whom the settings are defined
//   DocumentCalculation - DocumentRef - The document within which the reflection is performed
//   DateOfControl - Date - Date for determining the relevance of reflection settings
//
// Returns:
//   Structure - Accounting parameters for the specified conditions:
//   * PostingOption - EnumRef.AccrualsDeductionsRecordOptions - The option of reflection in accounting
//   * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - Item of expenses to be reflected in accounting
//   * DimensionOfExpenses - Arbitrary - Analytics of expenses to be reflected in accounting
//   * AssetsLiabilitiesDimension - Arbitrary - Analytics of assets/liabilities for accounting purposes
//
Function ParametersForReflectingFillingByTypeOfTax(TaxKind, Department, Employee, DocumentCalculation, DateOfControl) Export

	ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();
	FillingSettings = New Structure("PostingOption");
	
	If ValueIsFilled(TaxKind) Then 
		
		ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();   
		
		FillingSettings 
			= GetSettingsByTaxType(TaxKind, Employee, Department, DocumentCalculation, DateOfControl);
	EndIf;		
	
	If Not ValueIsFilled(FillingSettings.PostingOption) Then
		
		PostingOption =
			PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
	Else     
		PostingOption = FillingSettings.PostingOption;	
	EndIf;	
	
	ReflectionParameters = ReflectionOptions[PostingOption];   
	
	Return ReflectionParameters;
	
EndFunction

// Returns a structure with parameters for filling in the Form Attributes.
//
// Returns:
//   Structure - parameters for filling in the Form Attributes, including the Presentation of the settings, correctness, selection level, tables and date:
//     * RecordingSettingPresentation - String - Presentation of the reflection setting.
//     * ReflectionSettingIsCorrect - Boolean - indicates whether the reflection setting is correct.
//     * SelectionLevel - String - the level of selection.
//     * FilterTable - ValueTable - table of parameters.
//     * ResultTableByFilter - ValueTable - the result of the selection.
//
Function AttributesOfFillingOutForm() Export
	
	ParametersForFillingInFormDetails = New Structure();
	ParametersForFillingInFormDetails.Insert("RecordingSettingPresentation", "RecordingSettingPresentation");
	ParametersForFillingInFormDetails.Insert("ReflectionSettingIsCorrect", "ReflectionSettingIsCorrect");   
	ParametersForFillingInFormDetails.Insert("SelectionLevel", "");
	ParametersForFillingInFormDetails.Insert("FilterTable", New ValueTable());
	ParametersForFillingInFormDetails.Insert("ResultTableByFilter",  New ValueTable());
	ParametersForFillingInFormDetails.Insert("FilterDate", Date(1,1,1)); 
	ParametersForFillingInFormDetails.Insert("ItIsADeduction", False);
	ParametersForFillingInFormDetails.Insert("ReflectionOptions", 
				Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses);
	
	Return ParametersForFillingInFormDetails;
	
EndFunction

// Returns a set of predefined options for reflecting accruals in accounting with their settings.
//
// Returns:
//   FixedMap - Correspondence, where the key is the value of the enumeration of the reflection variationsreferences, and the value is a structure with a description of the reflection variant:
//    * Key - String - the name of the reflection variant Attribute.
//    * Value - String - description of the reflection option Attribute.
//
Function OptionsForReflectingAccruals() Export
	
	ReflectionOptions = New Map;
	
	// Reflection of costs by item of expenditure
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses,
		NStr("vi = 'Số tiền được đưa vào tài khoản dưới dạng chi phí được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма принимается к учету как постатейный расход и распределяется в соответствии с настройками статьи';
			|en = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings'; fa = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings';
			|it = 'L''importo viene registrato in contabilità come spesa dettagliata per articolo e ripartita secondo le impostazioni della voce di spesa';
			|pl = 'Wartość jest przyjmowana do ewidencji jako rozchód wg pozycji i dzielony zgodnie z ustawieniami pozycji';
			|tr = 'Tutar, kalemler bazında gider olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"ExpenseItem, DimensionOfExpenses, LineOfBusiness");
	OptionDetails.CheckFilling = False;
	
	ExpenseItem = OptionDetails.AttributeProperties.ExpenseItem; // See PropertiesOfReflectionProps
	ExpenseItem.Main = True;
	
	LineOfBusiness = OptionDetails.AttributeProperties.LineOfBusiness; // See PropertiesOfReflectionProps
	LineOfBusiness.Used = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	LineOfBusiness.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Reflection of costs under the item of assets/liabilities
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities,
		NStr("vi = 'Số tiền được đưa vào tài khoản dưới dạng chi phí được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма принимается к учету как постатейный расход и распределяется в соответствии с настройками статьи';
			|en = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings'; fa = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings';
			|it = 'L''importo viene registrato in contabilità come spesa dettagliata per articolo e ripartita secondo le impostazioni della voce di spesa';
			|pl = 'Wartość jest przyjmowana do ewidencji jako rozchód wg pozycji i dzielony zgodnie z ustawieniami pozycji';
			|tr = 'Tutar, kalemler bazında gider olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"ExpenseItem, AssetsLiabilitiesDimension, GLAccountSettings, LineOfBusiness");
	OptionDetails.CheckFilling = False;
	
	OptionDetails.Used = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	ExpenseItem = OptionDetails.AttributeProperties.ExpenseItem; // See PropertiesOfReflectionProps
	ExpenseItem.Main = True;
	
	GLAccountSettings = OptionDetails.AttributeProperties.GLAccountSettings; // See PropertiesOfReflectionProps
	GLAccountSettings.Used =
		GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	LineOfBusiness = OptionDetails.AttributeProperties.LineOfBusiness; // See PropertiesOfReflectionProps
	LineOfBusiness.Used = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	LineOfBusiness.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Distribution of production costs
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.AllocateToProduction,
		NStr("vi = 'Số tiền đã trích được phân bổ vào các lô sản xuất theo sản lượng của nhân viên';
			|ru = 'Начисленная сумма распределяется на партии производства по выработке сотрудников';
			|en = 'Accrued amount is allocated to production lots for timesheets charge'; fa = 'Accrued amount is allocated to production lots for timesheets charge';
			|it = 'L''importo maturato viene ripartito per lotti di produzione in base alla produttività dei dipendenti';
			|pl = 'Naliczona kwota przydziela się na partie produkcji wg wydajności pracowników';
			|tr = 'Tahakkuk eden tutar,  zaman çizelgesi bazlı ücretlendirmeye dayalı olarak üretim lotlarına dağıtılır'"),
		"AllocationBaseType, ProductCostElement");
	
	AllocationBaseType = OptionDetails.AttributeProperties.AllocationBaseType; // See PropertiesOfReflectionProps
	AllocationBaseType.Main = True;
	
	ProductCostElement = OptionDetails.AttributeProperties.ProductCostElement; // See PropertiesOfReflectionProps
	ProductCostElement.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// 
	
	Return New FixedMap(ReflectionOptions);
	
EndFunction


// Returns the correspondence of the options for reflecting deductions in accounting with their descriptions.
//
// Returns:
//   FixedMap - The key is the value from the enumeration of the reflection variationsreferences, the value is a fixed structure with a description of the reflection variant.
//
Function OptionsForReflectingDeductions() Export
	
	ReflectionOptions = New Map;
	
	// Reflection of deductions by income item
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome,
		NStr("vi = 'Số tiền khấu trừ được tính đến dưới dạng thu nhập được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма удержания принимается к учету как постатейный доход и распределяется в соответствии с настройками статьи';
			|en = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.'; fa = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.';
			|it = 'L''importo della trattenuta viene registrato come entrata dettagliata per articolo e ripartita secondo le impostazioni della voce';
			|pl = 'Wartość potrącenia jest przyjmowana do ewidencji dochód wg pozycji i przydziela się zgodnie z ustawieniami pozycji';
			|tr = 'Stopaj tutarı kalem bazlı gelir olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"IncomeItem, DimensionOfRevenue");
	OptionDetails.CheckFilling = False;
	
	IncomeItem = OptionDetails.AttributeProperties.IncomeItem; // See PropertiesOfReflectionProps
	IncomeItem.Main = True;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Reflection of deductions under the item of assets/liabilities
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities,
		NStr("vi = 'Số tiền khấu trừ được tính đến dưới dạng thu nhập được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма удержания принимается к учету как постатейный доход и распределяется в соответствии с настройками статьи';
			|en = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.'; fa = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.';
			|it = 'L''importo della trattenuta viene registrato come entrata dettagliata per articolo e ripartita secondo le impostazioni della voce';
			|pl = 'Wartość potrącenia jest przyjmowana do ewidencji dochód wg pozycji i przydziela się zgodnie z ustawieniami pozycji';
			|tr = 'Stopaj tutarı kalem bazlı gelir olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"IncomeItem, AssetsLiabilitiesDimension, GLAccountSettings");
	OptionDetails.CheckFilling = False;
	
	OptionDetails.Used = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	IncomeItem = OptionDetails.AttributeProperties.IncomeItem; // See PropertiesOfReflectionProps
	IncomeItem.Main = True;
	
	GLAccountSettings = OptionDetails.AttributeProperties.GLAccountSettings; // See PropertiesOfReflectionProps
	GLAccountSettings.Used =
		GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Repayment of mutual settlements by withholding
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.PayOffAccountsPayable,
		NStr("vi = 'Số tiền khấu trừ được hướng đến việc thanh toán đối trừ';
			|ru = 'Сумма удержания направляется на погашение взаиморасчетов';
			|en = 'The amount of deduction is directed to the mutual settlements repayment'; fa = 'The amount of deduction is directed to the mutual settlements repayment';
			|it = 'L''importo della trattenuta viene destinato all''estinzione di regolamenti reciproci';
			|pl = 'Wartość potrącenia jest skierowana na umorzenie rozliczeń wzajemnych';
			|tr = 'Stopaj tutarı mutabakat yapılması için kullanılır'"),
		"Counterparty, ARAPObject");
	
	Counterparty = OptionDetails.AttributeProperties.Counterparty; // See PropertiesOfReflectionProps
	Counterparty.Main = True;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Repayment of settlements with the accountable person
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.PayOffAdvanceHolderAccountsPayable,
		NStr("vi = 'Số tiền khấu trừ được hướng đến giảm hạch toán với người nhận tạm ứng';
			|ru = 'Сумма удержания направляется на погашение расчетов с подотчетным лицом';
			|en = 'The amount of deduction is directed to the settlement repayment with advance holder'; fa = 'The amount of deduction is directed to the settlement repayment with advance holder';
			|it = 'L''importo della trattenuta viene destinato all''estinzione di regolamenti con la persona responsabile';
			|pl = 'Wartość potrąceń jest skierowana na umorzenie rozliczeń z zaliczkobiorcą';
			|tr = 'Stopaj tutarı, sorumlu kişiye ödenecek hesapları kapatmak için kullanılır'"),
		"IssuancePurpose");
	
	IssuancePurpose = OptionDetails.AttributeProperties.IssuancePurpose; // See PropertiesOfReflectionProps
	IssuancePurpose.Used = GetFunctionalOption("ControlIssueOfCashByPurposes");
	IssuancePurpose.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// 
	
	Return New FixedMap(ReflectionOptions);
	
EndFunction

// Returns properties of the accounting reflection article, such as accessibility of accounting account settings and autocompletion.
//
// Parameters:
//   AssetRef - ChartOfCharacteristicTypesRef.ExpenseItems - Link to the article reflection in accounting
//
// Returns:
//   Structure - The properties of the article are reflected in accounting:
//   * YouCanConfigureAccountingAccounts - Boolean - Indicates whether account settings are available.
//   * AutocompletionIsAvailable - Boolean - Indicates whether autocomplete is available
//
Function PropertiesOfReflectionArticle(AssetRef) Export
	
	Result = IncomeAndExpensesServerCallCached.ArticleDetailsValues(AssetRef);
	Result.Insert("YouCanConfigureAccountingAccounts", False);
	Result.Insert("AutocompletionIsAvailable", False);
	
	If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		SelectedTypes_ = TypesOfAccrualAnalyticsAvailableForFillingIn();
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		SelectedTypes_ = TypesOfRetentionAnalyticsAvailableForFilling();
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Result.YouCanConfigureAccountingAccounts = Not
			GLAccountSettingsInternalServerCall.AccountingAccountsAreSpecifiedInTransactionSettings(AssetRef);
		Return Result;
	EndIf;
	
	For Each TypeOfAnalytics In SelectedTypes_ Do
		If Result.ValueType.ContainsType(TypeOfAnalytics) Then
			Result.AutocompletionIsAvailable = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function SettingUpReflectionInAccounting(Form, ReflectionParameters, DetailsOfFillingInForm)
	
	If ReflectionParameters <> Undefined Then
		RecordingSetting = New Structure("PostingOption," + ReflectionParameters.Attributes);
	Else
		RecordingSetting = New Structure("PostingOption");
	EndIf;
	
	FillParameters = 
		InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters(); 
		
	FillPropertyValues(FillParameters, DetailsOfFillingInForm.FilterTable[0]);	
	
	FoundRows = DetailsOfFillingInForm.ResultTableByFilter.FindRows(FillParameters);

	If FoundRows.Count() > 0 Then
		FillPropertyValues(RecordingSetting, FoundRows[0]);	
	EndIf;	
	
	Return RecordingSetting;
	
EndFunction

Function SettingUpReflectionOfTableRowInAccounting(CurrentRow, ReflectionParameters, DetailsOfFillingInForm)
	
	If ReflectionParameters <> Undefined Then
		RecordingSetting = New Structure("PostingOption," + ReflectionParameters.Attributes);
	Else
		RecordingSetting = New Structure("PostingOption");
	EndIf;
	
	FillParameters = 
		InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters(); 

	FillPropertyValues(FillParameters, CurrentRow);	
	
	FoundRows = DetailsOfFillingInForm.ResultTableByFilter.FindRows(FillParameters);
	
	If FoundRows.Count() > 0 Then
		FillPropertyValues(RecordingSetting, FoundRows[0]);	
	EndIf;	
	
	Return RecordingSetting;
	
EndFunction

Function PresentationOfReflectionSettingsFillIn()
	Return NStr("vi = 'Điền tham số định khoản...';
				|ru = 'Заполнить параметры отражения...';
				|en = 'Fill in accounting attributes...'; fa = 'Fill in accounting attributes...';
				|it = 'Compilare i parametri di visualizzazione...';
				|pl = 'Wypełnij parametry odzwierciedlenia...';
				|tr = 'Yansıma parametrelerini doldur...'");
EndFunction

Function ReflectionSettingPresentation(Val Template, Attributes, RecordingSetting)
	
	TemplateParameters = New Structure;
	For Each ListItem In Attributes Do
		
		Name = ListItem.Key;
		Attribute = ListItem.Value;
		Value = Undefined;
		
		If RecordingSetting.Property(Name, Value) And ValueIsFilled(Value) Then
			TemplateParameters.Insert(Name, Value);
			Continue;
		ElsIf Not Attribute.Used Then
			Template = StrReplace(Template, "[" + Name + "]", "");
			Continue;
		ElsIf Name = "GLAccountSettings" Then
			Template = StrReplace(Template, "[" + Name + "]", "");
			Continue;
		EndIf;
		
		If Attribute.Main Then
			// The main Attributes are not filled in
			Return PresentationOfReflectionSettingsFillIn();
		EndIf;
		
		// Presentation of blank fields
		
		If Name = "ProductCostElement" Then
			TemplateParameters.Insert(Name, NStr("vi = '<theo sản lượng tính>';
												|ru = '<по выработке>';
												|en = '<by output>'; fa = '<by output>';
												|it = '<по выработке>';
												|pl = '<by output>';
												|tr = '<çıktıya göre>'"));
		ElsIf Name = "IssuancePurpose" Then
			TemplateParameters.Insert(Name, NStr("vi = '<chưa chỉ ra>';
												|ru = '<не указана>';
												|en = '<not specified>'; fa = '<مشخص نشده>';
												|it = '<non indicata>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'"));
		ElsIf Name = "ARAPObject" Then
			TemplateParameters.Insert(Name, NStr("vi = '<chưa chỉ ra>';
												|ru = '<не указана>';
												|en = '<not specified>'; fa = '<مشخص نشده>';
												|it = '<non indicata>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'"));
		ElsIf StrStartsWith(Name, "Dimension") And ThisIsArticleByArticleReflection(RecordingSetting.PostingOption) Then
			
			AssetRef = ArticleOfReflectionInAccounting(RecordingSetting);
			ArticleSettings = PropertiesOfReflectionArticle(AssetRef);
			
			If ArticleSettings.AutocompletionIsAvailable Then
				TemplateParameters.Insert(Name, NStr("vi = '<được chọn tự động>';
													|ru = '<подбирается автоматически>';
													|en = '<picked automatically>'; fa = '<picked automatically>';
													|it = '<viene selezionato automaticamente>';
													|pl = '<wybierane automatycznie>';
													|tr = '<otomatik olarak seçilir>'"));
			EndIf;
			
		EndIf;
		
		If Not TemplateParameters.Property(Name) Then
			TemplateParameters.Insert(Name, NStr("vi = '<...>';
												|ru = '<...>';
												|en = '<...>'; fa = '<...>';
												|it = '<...>';
												|pl = '<...>';
												|tr = '<...>'"));
		EndIf;
		
	EndDo;
	
	If Not IsBlankString(Template) Then
		Template = StrReplace(Template, "][", "], [");
		Presentation = StringFunctionsClientServer.InsertParametersIntoString(Template, TemplateParameters);
	Else
		Presentation = NStr("vi = '<Không bắt buộc>';
							|ru = '<не требуется>';
							|en = '<not required>'; fa = '<الزامی نیست>';
							|it = '<non richiesto>';
							|pl = '<nie jest wymagane>';
							|tr = '<gerekli değil>'");
	EndIf;
	
	Return Presentation;
	
EndFunction

Function CheckCorrectReflectionSettings(Attributes, RecordingSetting)
	
	Result = True;
	
	For Each ListItem In Attributes Do
		
		Name = ListItem.Key;
		Attribute = ListItem.Value;
		Value = Undefined;
		
		If Not Attribute.Used Or Not Attribute.AttributeIsRequired Then
			Continue;
		ElsIf RecordingSetting.Property(Name, Value) And ValueIsFilled(Value) Then
			Continue;
		EndIf;
		
		// Additional verification of required but blank fields
		
		If StrStartsWith(Name, "Dimension") And ThisIsArticleByArticleReflection(RecordingSetting.PostingOption) Then
			
			AssetRef = ArticleOfReflectionInAccounting(RecordingSetting);
			ArticleSettings = PropertiesOfReflectionArticle(AssetRef);
			
			If ArticleSettings.WithoutDimension Then
				Continue;
			ElsIf Not ArticleSettings.ControlDimensionFilling Then
				Continue;
			ElsIf ArticleSettings.AutocompletionIsAvailable Then
				Continue;
			EndIf;
			
		ElsIf Name = "GLAccountSettings" Then
			
			AssetRef = ArticleOfReflectionInAccounting(RecordingSetting);
			ArticleSettings = PropertiesOfReflectionArticle(AssetRef);
			
			If Not ArticleSettings.YouCanConfigureAccountingAccounts Then
				Continue;
			EndIf;
			
		EndIf;
		
		Result = False;
		Break;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function ThisIsArticleByArticleReflection(PostingOption)
	
	Return PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses
			Or PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome
			Or PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
	
EndFunction

Function ArticleOfReflectionInAccounting(RecordingSetting)
	
	AssetRef = Undefined;
	If Not (RecordingSetting.Property("ExpenseItem", AssetRef) Or RecordingSetting.Property("IncomeItem", AssetRef)
				Or RecordingSetting.Property("ExpenseAssetLiabilityItem", AssetRef)
				Or RecordingSetting.Property("IncomeAssetLiabilityItem", AssetRef)) Then
		Return Undefined;
	EndIf;
	
	ReflectionOptions = Enums.AccrualsDeductionsRecordOptions;
	If RecordingSetting.PostingOption = ReflectionOptions.RecogniseAsOtherExpenses Then
		ArticleType = New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems");
	ElsIf RecordingSetting.PostingOption = ReflectionOptions.RecogniseAsOtherIncome Then
		ArticleType = New TypeDescription("ChartOfCharacteristicTypesRef.IncomeItems");
	ElsIf RecordingSetting.PostingOption = ReflectionOptions.RecognizeAsOtherAssetsLiabilities Then
		ArticleType = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
	Else
		ArticleType = Undefined;
	EndIf;
	
	If ArticleType = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ArticleType.AdjustValue(AssetRef);
	
EndFunction


// Returns parameters for setting up accounting accounts in the document.
// 
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	ParametersArray = New Array();
	
	#Region Accruals
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	SetupParameters.Presentation = "";	
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

Function NewVersionOfReflection(Value, LongDesc, Attributes)
	
	PostingOption = New Structure;
	
	PostingOption.Insert("Value", Value);
	PostingOption.Insert("OptionDetails", LongDesc);
	
	PostingOption.Insert("Used", True);
	
	PostingOption.Insert("Attributes", Attributes);
	
	AttributesList = New Array;
	AttributeProperties = New Structure;
	For Each ListItem In StrSplit(Attributes, ",") Do
		AttributeName = TrimAll(ListItem);
		AttributeProperties.Insert(AttributeName, PropertiesOfReflectionProps());
		AttributesList.Add(AttributeName);
	EndDo;
	
	PostingOption.Insert("TemplateOfPresentation", "[" + StrConcat(AttributesList, "][") + "]");
	PostingOption.Insert("AttributeProperties", New FixedStructure(AttributeProperties));
	PostingOption.Insert("CheckFilling", True);
	
	Return PostingOption;
	
EndFunction

// Properties of the reflection props
//
// Returns:
//  Structure - Empty Structure:
//    * Used - Boolean - indication of the use of props for the reflection option,
//    * AttributeIsRequired - Boolean - a sign of mandatory filling,
//    * Main - Boolean - basic Attributes.
//
Function PropertiesOfReflectionProps()
	
	PropsProperties = New Structure;
	PropsProperties.Insert("Used", True);
	PropsProperties.Insert("AttributeIsRequired", True);
	PropsProperties.Insert("Main", False);
	
	Return PropsProperties;
	
EndFunction

Function TypesOfAccrualAnalyticsAvailableForFillingIn()
	
	TypesArray = New Array;
	
	TypesArray.Add(Type("CatalogRef.Persons"));
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.Companies"));
	
	Return New FixedArray(TypesArray);
	
EndFunction

Function TypesOfRetentionAnalyticsAvailableForFilling()
	
	TypesArray = New Array;
	
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.Companies"));
	
	Return New FixedArray(TypesArray);
	
EndFunction

#EndRegion
