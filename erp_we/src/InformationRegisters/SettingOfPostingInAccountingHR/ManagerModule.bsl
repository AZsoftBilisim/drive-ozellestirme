										  
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
										  
// Returns a structure with keys and default values for writing to the information register.
//
// Returns:
//   Structure - structure with pre-filled field values for recording:
//     * Period - Date - date of entry in the information register.
//     * TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - reference to the type of accrual or deduction.
//     * Department - CatalogRef.BusinessStructure - link to the division of the company.
//     * Employee - CatalogRef.EmployeesHR - link to the employee.
//     * DocumentCalculation - DocumentRef - link to the document.
//     * PostingOption - EnumRef.AccrualsDeductionsRecordOptions	
//
Function DataStructureForRecord() Export
	
	DataParameters = New Structure;
	DataParameters.Insert("Period", ""); 
	DataParameters.Insert("TypeOfAccrualDeduction", Catalogs.AccrualAndDeductionKinds.EmptyRef());
	DataParameters.Insert("Department", "");
	DataParameters.Insert("Employee", "");
	DataParameters.Insert("DocumentCalculation", "");
	DataParameters.Insert("PostingOption", "");
	DataParameters.Insert("AllocationBaseType", Enums.TypesOfCostAllocatingBase.EmptyRef());
	DataParameters.Insert("ProductCostElement", Catalogs.ProductCostElements.EmptyRef());
	DataParameters.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	DataParameters.Insert("ExpenseItem", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	DataParameters.Insert("ExpenseAssetLiabilityItem", ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef());
	DataParameters.Insert("IncomeItem", ChartsOfCharacteristicTypes.IncomeItems.EmptyRef());
	DataParameters.Insert("IncomeAssetLiabilityItem", ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef());
	DataParameters.Insert("DimensionOfExpensesAssetsLiabilities", "");
	DataParameters.Insert("DimensionOfIncomeAssetsLiabilities", "");
	DataParameters.Insert("DimensionOfRevenue", "");
	DataParameters.Insert("DimensionOfExpenses", "");
	DataParameters.Insert("IncomeLedgerAccountsSettings", "");
	DataParameters.Insert("ExpenseLedgerAccountsSettings", "");
	DataParameters.Insert("Counterparty", "");
	DataParameters.Insert("IssuancePurpose", "");
	DataParameters.Insert("ARAPObject", ""); 
	
	Return DataParameters;
	
EndFunction	

// Checks for an empty record in the register dimension
//Parameters:
// StructureOfData - Structure - structure with register data See DataStructureForRecord
//                               ()
// Returns:
//   Boolean - True if all measurement records are empty
//
Function MeasurementDataIsEmpty(StructureOfData) Export
	
	HasData = False;
	For Each CurrentValueOfDataStructure In StructureOfData Do
		If CurrentValueOfDataStructure.Key = "Period"
			Or  CurrentValueOfDataStructure.Key = "TypeOfAccrualDeduction"
			Or  CurrentValueOfDataStructure.Key = "Department"
			Or  CurrentValueOfDataStructure.Key = "Employee"
			Or  CurrentValueOfDataStructure.Key = "DocumentCalculation"
			Or  CurrentValueOfDataStructure.Key = "PostingOption" Then
			Continue;
		EndIf;	
		
		If ValueIsFilled(CurrentValueOfDataStructure.Value) Then
			HasData = True;
			Break;
		EndIf;	
		
	EndDo;                 
	
	Return Not HasData;
	
EndFunction

// Returns a structure with data for Presentation of the settings for filling in the reflection in HR accounting.
//
// Returns:
//   Structure - contains "Key" - "Presentation" pairs for register fields:
//      * Period - String - Period;
//      * PostingOption - String - "Reflection option";
//      * AllocationBaseType - String -"Type of distribution base";
//      * ProductCostElement - String -"Article of calculation";
//      * LineOfBusiness - String -"Napravlenie activity";
//      * ExpenseItem - String -"Expense item";
//      * ExpenseAssetLiabilityItem - String -"Expense item of assets and liabilities";
//      * IncomeItem - String -"Income item";
//      * IncomeItemAssets - String -Income item of assets";
//
Function DataStructureForPresentation() Export
	
	DataParameters = New Structure;
	DataParameters.Insert("Period", NStr("ru = 'Период';
										|vi = 'Period';
										|en = 'Period'; fa = 'دوره';
										|it = 'Period';
										|pl = 'Period';
										|tr = 'Dönem'")); 
	DataParameters.Insert("PostingOption", NStr("ru = 'Вариант отражения';
												|vi = 'Posting option';
												|en = 'Posting option'; fa = 'گزینه ثبت';
												|it = 'Opzione di visualizzazione';
												|pl = 'Wariant odzwierciedlenia';
												|tr = 'Yansıtma seçeneği'"));
	DataParameters.Insert("AllocationBaseType", NStr("vi = 'Loại cơ sở phân bổ';
													|ru = 'Тип базы распределения';
													|en = 'Allocation base type'; fa = 'نوع مبنای تسهیم';
													|it = 'Tipo di base di ripartizione';
													|pl = 'Typ bazy podziału';
													|tr = 'Tahsisat tabanı tipi'"));
	DataParameters.Insert("ProductCostElement", NStr("ru = 'Статья калькуляции';
													|vi = 'Product cost element';
													|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
													|it = 'Voce di calcolo';
													|pl = 'Rodzaj kosztu';
													|tr = 'Ürün maliyet kalemi'"));
	DataParameters.Insert("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
												|ru = 'Направление деятельности';
												|en = 'Line of business'; fa = 'خط کسب‌وکار';
												|it = 'Settore di attività';
												|pl = 'Rodzaj działalności';
												|tr = 'İş kolu'"));
	DataParameters.Insert("ExpenseItem", NStr("vi = 'Dạng chi phí';
												|ru = 'Статья расходов';
												|en = 'Expense item'; fa = 'قلم هزینه';
												|it = 'Voce di spese';
												|pl = 'Rodzaj kosztu';
												|tr = 'Gider kalemi'"));
	DataParameters.Insert("ExpenseAssetLiabilityItem", NStr("ru = 'Статья расходов активов и пассивов';
															|vi = 'Expense/asset/liability item';
															|en = 'Expense/asset/liability item'; fa = 'قلم هزینه/دارایی/بدهی';
															|it = 'Expense/asset/liability item';
															|pl = 'Expense/asset/liability item';
															|tr = 'Varlık ve yükümlülük gider kalemi'"));
	DataParameters.Insert("IncomeItem", NStr("ru = 'Статья доходов';
											|vi = 'Income item';
											|en = 'Income item'; fa = 'قلم درآمد';
											|it = 'Voce dei ricavi';
											|pl = 'Rodzaj przychodów';
											|tr = 'Gelir kalemi'"));
	DataParameters.Insert("IncomeAssetLiabilityItem", NStr("ru = 'Статья доходов активов и пассивов';
															|vi = 'Income/asset/liability item';
															|en = 'Income/asset/liability item'; fa = 'قلم درآمد/دارایی/بدهی';
															|it = 'Income/asset/liability item';
															|pl = 'Income/asset/liability item';
															|tr = 'Varlık ve yükümlülük gelir kalemi'"));
	DataParameters.Insert("DimensionOfExpensesAssetsLiabilities", NStr("ru = 'Аналитика расходов активов и пассивов';
																		|vi = 'Dimension of expenses/assets/liabilities';
																		|en = 'Dimension of expenses/assets/liabilities'; fa = 'بُعد هزینه‌ها/دارایی‌ها/بدهی‌ها';
																		|it = 'Dimension of expenses/assets/liabilities';
																		|pl = 'Dimension of expenses/assets/liabilities';
																		|tr = 'Varlık ve yükümlülük gider boyutu'"));
	DataParameters.Insert("DimensionOfIncomeAssetsLiabilities", NStr("ru = 'Аналитика доходов активов и пассивов';
																	|vi = 'Dimension of income/assets/liabilities';
																	|en = 'Dimension of income/assets/liabilities'; fa = 'بُعد درآمد/دارایی‌ها/بدهی‌ها';
																	|it = 'Dimension of income/assets/liabilities';
																	|pl = 'Dimension of income/assets/liabilities';
																	|tr = 'Varlık ve yükümlülük gelir boyutu'"));
	DataParameters.Insert("IncomeLedgerAccountsSettings", NStr("ru = 'Настрока счетов учета';
																|vi = 'Ledger account settings';
																|en = 'Ledger account settings'; fa = 'تنظیمات حساب دفتر کل';
																|it = 'Ledger account settings';
																|pl = 'Ledger account settings';
																|tr = 'Muhasebe hesapları ayarı'"));
	DataParameters.Insert("ExpenseLedgerAccountsSettings", NStr("ru = 'Настрока счетов учета';
																|vi = 'Ledger account settings';
																|en = 'Ledger account settings'; fa = 'تنظیمات حساب دفتر کل';
																|it = 'Ledger account settings';
																|pl = 'Ledger account settings';
																|tr = 'Muhasebe hesapları ayarı'"));
	DataParameters.Insert("Counterparty", NStr("ru = 'Контрагент';
												|vi = 'Counterparty';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Counterparty';
												|pl = 'Counterparty';
												|tr = 'Cari hesap'"));
	DataParameters.Insert("IssuancePurpose", NStr("ru = 'Цель выдачи';
													|vi = 'Issuance purpose';
													|en = 'Issuance purpose'; fa = 'هدف پرداخت';
													|it = 'Scopo di emissione';
													|pl = 'Cel wydania';
													|tr = 'Verilme amacı'"));
	DataParameters.Insert("ARAPObject", NStr("ru = 'Объект расчетов';
											|vi = 'AR/AP object';
											|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
											|it = 'Oggetto di regolamenti';
											|pl = 'Obiekt rozliczeń';
											|tr = 'Alacak/Borç nesnesi'"));
	
	Return DataParameters;
	
EndFunction

// Returns a structure with the selection parameters for the register "Refillingreflection settings".
//
// Returns:
//   Structure - contains empty links for selection by type of accruals/deductions, divisions, employees and Undefined for documentsaccounts:
//		* TypeOfAccrualDeduction - CatalogRef.AccrualAndDeductionKinds - an empty link to the type of accrual/deduction.
//		* Department - CatalogRef.BusinessStructure - an empty link to the division.
//		* Employee - CatalogRef.EmployeesHR - an empty link to an employee.
//		* DocumentCalculation - Undefined - an empty link to the document.
//
Function CaseSelectionParameters() Export
	
	FillParameters = New Structure();
	FillParameters.Insert("TypeOfAccrualDeduction", Catalogs.AccrualAndDeductionKinds.EmptyRef());	
	FillParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());	
	FillParameters.Insert("Employee", Catalogs.EmployeesHR.EmptyRef());	
	FillParameters.Insert("DocumentCalculation", Undefined);

	Return FillParameters;
	
EndFunction	

// Returns the current HR accounting reflection settings for the specified parameters as of the selection date.
//
// Parameters:
//   FillParameters - Structure - Parameters for selecting settings (Retention type, Division, Employee, Document):
//   FilterDate - Date - The date on which you need to get the current settings
//
// Returns:
//   Structure - Contains the settings data and the flag for receiving them (keys: Data structuresdata received):
//     * StructureOfData - Structure - Contains settings data 
//     * DataReceived - Boolean - Flag for receiving data
//
Function CaseSensitiveValues(FillParameters, FilterDate) Export
	
	TypeOfAccrualDeduction = FillParameters.TypeOfAccrualDeduction;
	Department = FillParameters.Department;
	Employee = FillParameters.Employee;
	DocumentCalculation = FillParameters.DocumentCalculation; 
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.SetParameter("AccrualOfDeductions",    TypeOfAccrualDeduction); 
	Query.SetParameter("Department",          Department); 
	Query.SetParameter("Employee",              Employee); 
	Query.SetParameter("DocumentCalculation",        DocumentCalculation); 
	Query.SetParameter("FilterDate",             FilterDate); 
	
	Query.Text = 
	"SELECT
	|	SettingOfPostingInAccountingHRSliceLast.Period AS Period,
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
	|FROM
	|	InformationRegister.SettingOfPostingInAccountingHR.SliceLast(
	|			&FilterDate,
	|			TypeOfAccrualDeduction = &AccrualOfDeductions
	|				AND Department = &Department
	|				AND Employee = &Employee
	|				AND DocumentCalculation = &DocumentCalculation) AS SettingOfPostingInAccountingHRSliceLast";
		
	Result = Query.Execute();	
	
	Selection = Result.Select();
	
	RegisterSelectionData = New Structure("StructureOfData,DataReceived",DataStructureForRecord(), False);
	
	If Selection.Next() Then
		
		FillPropertyValues(RegisterSelectionData.StructureOfData, Selection);
		RegisterSelectionData.DataReceived = True;
		
	EndIf;	
	
	Return RegisterSelectionData;  
	
EndFunction

// Writes a new entry to the information register of the setingfillingreflection settings with the specified parameters.
//
// Parameters:
//   StructureOfData - Structure - a structure containing data to be written to a register
//
Procedure WriteData(StructureOfData) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.SettingOfPostingInAccountingHR");
		LockItem.DataSource = StructureOfData;
		LockItem.UseFromDataSource("TypeOfAccrualDeduction" ,"TypeOfAccrualDeduction");
		LockItem.UseFromDataSource("Department" ,"Department");
		LockItem.UseFromDataSource("Employee" ,"Employee");
		LockItem.UseFromDataSource("DocumentCalculation" ,"DocumentCalculation");
		LockItem.UseFromDataSource("Period" ,"Period");
		Block.Lock();
		
		RecordSet = InformationRegisters.SettingOfPostingInAccountingHR.CreateRecordSet();
		RecordSet.Filter.TypeOfAccrualDeduction.Set(StructureOfData.TypeOfAccrualDeduction);
		RecordSet.Filter.Department.Set(StructureOfData.Department);
		RecordSet.Filter.Employee.Set(StructureOfData.Employee);
		RecordSet.Filter.DocumentCalculation.Set(StructureOfData.DocumentCalculation);   
		RecordSet.Filter.Period.Set(StructureOfData.Period);
		
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, StructureOfData);
		RecordSet.Write(True);
		
		CommitTransaction();
	Except 
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure	

// Deletes an entry in the information register of the setingfillingreflection with the specified parameters.
//
// Parameters:
//   StructureOfData - Structure - a structure containing data to be written to a register
//
Procedure DeleteData(StructureOfData) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.SettingOfPostingInAccountingHR");
		LockItem.DataSource = StructureOfData;
		LockItem.UseFromDataSource("TypeOfAccrualDeduction" ,"TypeOfAccrualDeduction");
		LockItem.UseFromDataSource("Department" ,"Department");
		LockItem.UseFromDataSource("Employee" ,"Employee");
		LockItem.UseFromDataSource("DocumentCalculation" ,"DocumentCalculation");
		LockItem.UseFromDataSource("Period" ,"Period");
		Block.Lock();
		
		RecordSet = InformationRegisters.SettingOfPostingInAccountingHR.CreateRecordSet();
		RecordSet.Filter.TypeOfAccrualDeduction.Set(StructureOfData.TypeOfAccrualDeduction);
		RecordSet.Filter.Department.Set(StructureOfData.Department);
		RecordSet.Filter.Employee.Set(StructureOfData.Employee);
		RecordSet.Filter.DocumentCalculation.Set(StructureOfData.DocumentCalculation);   
		RecordSet.Filter.Period.Set(StructureOfData.Period);
		RecordSet.Read();
		
		For Each CurrentRecord In RecordSet Do
			RecordSet.Delete(CurrentRecord);
		EndDo;	
		
		RecordSet.Write(True);
		
		CommitTransaction();
	Except 
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure	

// Checks the presence of completed data for the division in the transmitted structure.
//
// Parameters:
//   StructureOfData - Structure - the structure containing the data to be checked
//
// Returns:
//   Boolean - true if at least one of the fields of the structure is filled
//
Function ThereIsCompletedDataOnDivision(StructureOfData) Export
	
	Return ValueIsFilled(StructureOfData["LineOfBusiness"])	
		Or ValueIsFilled(StructureOfData["ExpenseItem"])	
		Or ValueIsFilled(StructureOfData["DimensionOfExpenses"])	
		Or ValueIsFilled(StructureOfData["IncomeItem"])	
		Or ValueIsFilled(StructureOfData["DimensionOfRevenue"]);
	
EndFunction

// Returns the Query Text for getting the rules for filling in the reflection in accounting, taking into account the hierarchy of settings.
//
// Returns:
//   String - Query Text for getting hierarchically consistent reflection settings.
//
Function GetTextOfSettingsForFillingInReflectionInAccounting() Export
	
	QueryText1 = 
	"SELECT
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
	|INTO PopulationSettings
	|FROM
	|	InformationRegister.SettingOfPostingInAccountingHR.SliceLast(ENDOFPERIOD(&SettlementStartDate, MONTH), ) AS SettingOfPostingInAccountingHRSliceLast
	|
	|INDEX BY
	|	TypeOfAccrualDeduction,
	|	Department,
	|	Employee,
	|	DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PopulationSettings.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	PopulationSettings.Department AS Department,
	|	PopulationSettings.Employee AS Employee,
	|	PopulationSettings.DocumentCalculation AS DocumentCalculation,
	|	PopulationSettings.PostingOption AS PostingOption,
	|	PopulationSettings.AllocationBaseType AS AllocationBaseType,
	|	PopulationSettings.ProductCostElement AS ProductCostElement,
	|	PopulationSettings.LineOfBusiness AS LineOfBusiness,
	|	PopulationSettings.ExpenseItem AS ExpenseItem,
	|	PopulationSettings.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	PopulationSettings.IncomeItem AS IncomeItem,
	|	PopulationSettings.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	PopulationSettings.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	PopulationSettings.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	PopulationSettings.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	PopulationSettings.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	PopulationSettings.Counterparty AS Counterparty,
	|	PopulationSettings.IssuancePurpose AS IssuancePurpose,
	|	PopulationSettings.ARAPObject AS ARAPObject,
	|	PopulationSettings.DimensionOfExpenses AS DimensionOfExpenses,
	|	PopulationSettings.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TableWithDocumentsLevel1
	|FROM
	|	PopulationSettings AS PopulationSettings
	|WHERE
	|	PopulationSettings.DocumentCalculation <> UNDEFINED
	|
	|INDEX BY
	|	TypeOfAccrualDeduction,
	|	Department,
	|	Employee,
	|	DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PopulationSettings.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	PopulationSettings.Department AS Department,
	|	PopulationSettings.Employee AS Employee,
	|	PopulationSettings.DocumentCalculation AS DocumentCalculation,
	|	PopulationSettings.PostingOption AS PostingOption,
	|	PopulationSettings.AllocationBaseType AS AllocationBaseType,
	|	PopulationSettings.ProductCostElement AS ProductCostElement,
	|	PopulationSettings.LineOfBusiness AS LineOfBusiness,
	|	PopulationSettings.ExpenseItem AS ExpenseItem,
	|	PopulationSettings.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	PopulationSettings.IncomeItem AS IncomeItem,
	|	PopulationSettings.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	PopulationSettings.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	PopulationSettings.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	PopulationSettings.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	PopulationSettings.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	PopulationSettings.Counterparty AS Counterparty,
	|	PopulationSettings.IssuancePurpose AS IssuancePurpose,
	|	PopulationSettings.ARAPObject AS ARAPObject,
	|	PopulationSettings.DimensionOfExpenses AS DimensionOfExpenses,
	|	PopulationSettings.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TablePersonnelDocumentsLevel2
	|FROM
	|	PopulationSettings AS PopulationSettings
	|WHERE
	|	PopulationSettings.DocumentCalculation = UNDEFINED
	|	AND PopulationSettings.Employee <> VALUE(Catalog.EmployeesHR.EmptyRef)
	|
	|INDEX BY
	|	TypeOfAccrualDeduction,
	|	Department,
	|	Employee,
	|	DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PopulationSettings.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	PopulationSettings.Department AS Department,
	|	PopulationSettings.Employee AS Employee,
	|	PopulationSettings.DocumentCalculation AS DocumentCalculation,
	|	PopulationSettings.PostingOption AS PostingOption,
	|	PopulationSettings.AllocationBaseType AS AllocationBaseType,
	|	PopulationSettings.ProductCostElement AS ProductCostElement,
	|	PopulationSettings.LineOfBusiness AS LineOfBusiness,
	|	PopulationSettings.ExpenseItem AS ExpenseItem,
	|	PopulationSettings.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	PopulationSettings.IncomeItem AS IncomeItem,
	|	PopulationSettings.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	PopulationSettings.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	PopulationSettings.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	PopulationSettings.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	PopulationSettings.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	PopulationSettings.Counterparty AS Counterparty,
	|	PopulationSettings.IssuancePurpose AS IssuancePurpose,
	|	PopulationSettings.ARAPObject AS ARAPObject,
	|	PopulationSettings.DimensionOfExpenses AS DimensionOfExpenses,
	|	PopulationSettings.DimensionOfRevenue AS DimensionOfRevenue
	|INTO RetentionAccrualTableLevel4
	|FROM
	|	PopulationSettings AS PopulationSettings
	|WHERE
	|	PopulationSettings.TypeOfAccrualDeduction <> VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|	AND PopulationSettings.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|	AND PopulationSettings.DocumentCalculation = UNDEFINED
	|	AND PopulationSettings.Employee = VALUE(Catalog.EmployeesHR.EmptyRef)
	|
	|INDEX BY
	|	TypeOfAccrualDeduction,
	|	Department,
	|	Employee,
	|	DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RetentionAccrualTableLevel4.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	PopulationSettings.Department AS Department,
	|	PopulationSettings.Employee AS Employee,
	|	PopulationSettings.DocumentCalculation AS DocumentCalculation,
	|	RetentionAccrualTableLevel4.PostingOption AS PostingOption,
	|	PopulationSettings.AllocationBaseType AS AllocationBaseType,
	|	PopulationSettings.ProductCostElement AS ProductCostElement,
	|	PopulationSettings.LineOfBusiness AS LineOfBusiness,
	|	PopulationSettings.ExpenseItem AS ExpenseItem,
	|	PopulationSettings.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	PopulationSettings.IncomeItem AS IncomeItem,
	|	PopulationSettings.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	PopulationSettings.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	PopulationSettings.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	PopulationSettings.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	PopulationSettings.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	PopulationSettings.Counterparty AS Counterparty,
	|	PopulationSettings.IssuancePurpose AS IssuancePurpose,
	|	PopulationSettings.ARAPObject AS ARAPObject,
	|	PopulationSettings.DimensionOfExpenses AS DimensionOfExpenses,
	|	PopulationSettings.DimensionOfRevenue AS DimensionOfRevenue
	|INTO DivisionTable3Level
	|FROM
	|	PopulationSettings AS PopulationSettings,
	|	RetentionAccrualTableLevel4 AS RetentionAccrualTableLevel4
	|WHERE
	|	PopulationSettings.TypeOfAccrualDeduction = VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|	AND PopulationSettings.DocumentCalculation = UNDEFINED
	|	AND PopulationSettings.Employee = VALUE(Catalog.EmployeesHR.EmptyRef)
	|	AND PopulationSettings.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|
	|INDEX BY
	|	TypeOfAccrualDeduction,
	|	Department,
	|	Employee,
	|	DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DivisionTable3Level.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	DivisionTable3Level.Department AS Department,
	|	DivisionTable3Level.Employee AS Employee,
	|	DivisionTable3Level.DocumentCalculation AS DocumentCalculation,
	|	DivisionTable3Level.PostingOption AS PostingOption,
	|	DivisionTable3Level.AllocationBaseType AS AllocationBaseType,
	|	DivisionTable3Level.ProductCostElement AS ProductCostElement,
	|	DivisionTable3Level.LineOfBusiness AS LineOfBusiness,
	|	DivisionTable3Level.ExpenseItem AS ExpenseItem,
	|	DivisionTable3Level.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	DivisionTable3Level.IncomeItem AS IncomeItem,
	|	DivisionTable3Level.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	DivisionTable3Level.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	DivisionTable3Level.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	DivisionTable3Level.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	DivisionTable3Level.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	DivisionTable3Level.Counterparty AS Counterparty,
	|	DivisionTable3Level.IssuancePurpose AS IssuancePurpose,
	|	DivisionTable3Level.ARAPObject AS ARAPObject,
	|	DivisionTable3Level.DimensionOfExpenses AS DimensionOfExpenses,
	|	DivisionTable3Level.DimensionOfRevenue AS DimensionOfRevenue
	|INTO FillingSettingsAreComplete
	|FROM
	|	DivisionTable3Level AS DivisionTable3Level
	|
	|UNION ALL
	|
	|SELECT
	|	PopulationSettings.TypeOfAccrualDeduction,
	|	PopulationSettings.Department,
	|	PopulationSettings.Employee,
	|	PopulationSettings.DocumentCalculation,
	|	PopulationSettings.PostingOption,
	|	PopulationSettings.AllocationBaseType,
	|	PopulationSettings.ProductCostElement,
	|	PopulationSettings.LineOfBusiness,
	|	PopulationSettings.ExpenseItem,
	|	PopulationSettings.ExpenseAssetLiabilityItem,
	|	PopulationSettings.IncomeItem,
	|	PopulationSettings.IncomeAssetLiabilityItem,
	|	PopulationSettings.DimensionOfExpensesAssetsLiabilities,
	|	PopulationSettings.DimensionOfIncomeAssetsLiabilities,
	|	PopulationSettings.IncomeLedgerAccountsSettings,
	|	PopulationSettings.ExpenseLedgerAccountsSettings,
	|	PopulationSettings.Counterparty,
	|	PopulationSettings.IssuancePurpose,
	|	PopulationSettings.ARAPObject AS ARAPObject,
	|	PopulationSettings.DimensionOfExpenses AS DimensionOfExpenses,
	|	PopulationSettings.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	PopulationSettings AS PopulationSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PopulationSettings.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	PopulationSettings.Department AS Department,
	|	PopulationSettings.Employee AS Employee,
	|	PopulationSettings.DocumentCalculation AS DocumentCalculation,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN TableWithDocumentsLevel1.PostingOption
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.PostingOption
	|		WHEN ISNULL(DivisionTable3Level.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN DivisionTable3Level.PostingOption
	|		WHEN ISNULL(RetentionAccrualTableLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.PostingOption
	|		ELSE VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|	END AS PostingOption,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.AllocationBaseType, VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)) <> VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
	|			THEN TableWithDocumentsLevel1.AllocationBaseType
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.AllocationBaseType, VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)) <> VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.AllocationBaseType
	|		WHEN ISNULL(DivisionTable3Level.AllocationBaseType, VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)) <> VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
	|			THEN DivisionTable3Level.AllocationBaseType
	|		WHEN ISNULL(RetentionAccrualTableLevel4.AllocationBaseType, VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)) <> VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.AllocationBaseType
	|		ELSE VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
	|	END AS AllocationBaseType,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.ProductCostElement, VALUE(Catalog.ProductCostElements.EmptyRef)) <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			THEN TableWithDocumentsLevel1.ProductCostElement
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.ProductCostElement, VALUE(Catalog.ProductCostElements.EmptyRef)) <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.ProductCostElement
	|		WHEN ISNULL(DivisionTable3Level.ProductCostElement, VALUE(Catalog.ProductCostElements.EmptyRef)) <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			THEN DivisionTable3Level.ProductCostElement
	|		WHEN ISNULL(RetentionAccrualTableLevel4.ProductCostElement, VALUE(Catalog.ProductCostElements.EmptyRef)) <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN TableWithDocumentsLevel1.LineOfBusiness
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.LineOfBusiness
	|		WHEN ISNULL(DivisionTable3Level.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN DivisionTable3Level.LineOfBusiness
	|		WHEN ISNULL(RetentionAccrualTableLevel4.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.LineOfBusiness
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.ExpenseItem
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.ExpenseItem
	|		WHEN ISNULL(DivisionTable3Level.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DivisionTable3Level.ExpenseItem
	|		WHEN ISNULL(RetentionAccrualTableLevel4.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.ExpenseItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	END AS ExpenseItem,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.ExpenseAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.ExpenseAssetLiabilityItem
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.ExpenseAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.ExpenseAssetLiabilityItem
	|		WHEN ISNULL(DivisionTable3Level.ExpenseAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN DivisionTable3Level.ExpenseAssetLiabilityItem
	|		WHEN ISNULL(RetentionAccrualTableLevel4.ExpenseAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.ExpenseAssetLiabilityItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS ExpenseAssetLiabilityItem,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.IncomeItem, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.IncomeItem
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.IncomeItem, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.IncomeItem
	|		WHEN ISNULL(DivisionTable3Level.IncomeItem, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN DivisionTable3Level.IncomeItem
	|		WHEN ISNULL(RetentionAccrualTableLevel4.IncomeItem, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.IncomeItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|	END AS IncomeItem,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.IncomeAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.IncomeAssetLiabilityItem
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.IncomeAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.IncomeAssetLiabilityItem
	|		WHEN ISNULL(DivisionTable3Level.IncomeAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN DivisionTable3Level.IncomeAssetLiabilityItem
	|		WHEN ISNULL(RetentionAccrualTableLevel4.IncomeAssetLiabilityItem, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.IncomeAssetLiabilityItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS IncomeAssetLiabilityItem,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.DimensionOfExpensesAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.DimensionOfExpensesAssetsLiabilities
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.DimensionOfExpensesAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.DimensionOfExpensesAssetsLiabilities
	|		WHEN ISNULL(DivisionTable3Level.DimensionOfExpensesAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN DivisionTable3Level.DimensionOfExpensesAssetsLiabilities
	|		WHEN ISNULL(RetentionAccrualTableLevel4.DimensionOfExpensesAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.DimensionOfExpensesAssetsLiabilities
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS DimensionOfExpensesAssetsLiabilities,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.DimensionOfIncomeAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.DimensionOfIncomeAssetsLiabilities
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.DimensionOfIncomeAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.DimensionOfIncomeAssetsLiabilities
	|		WHEN ISNULL(DivisionTable3Level.DimensionOfIncomeAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN DivisionTable3Level.DimensionOfIncomeAssetsLiabilities
	|		WHEN ISNULL(RetentionAccrualTableLevel4.DimensionOfIncomeAssetsLiabilities, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.DimensionOfIncomeAssetsLiabilities
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS DimensionOfIncomeAssetsLiabilities,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.IncomeLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN TableWithDocumentsLevel1.IncomeLedgerAccountsSettings
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.IncomeLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.IncomeLedgerAccountsSettings
	|		WHEN ISNULL(DivisionTable3Level.IncomeLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN DivisionTable3Level.IncomeLedgerAccountsSettings
	|		WHEN ISNULL(RetentionAccrualTableLevel4.IncomeLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.IncomeLedgerAccountsSettings
	|		ELSE VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|	END AS IncomeLedgerAccountsSettings,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.ExpenseLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN TableWithDocumentsLevel1.ExpenseLedgerAccountsSettings
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.ExpenseLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.ExpenseLedgerAccountsSettings
	|		WHEN ISNULL(DivisionTable3Level.ExpenseLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN DivisionTable3Level.ExpenseLedgerAccountsSettings
	|		WHEN ISNULL(RetentionAccrualTableLevel4.ExpenseLedgerAccountsSettings, VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)) <> VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.ExpenseLedgerAccountsSettings
	|		ELSE VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
	|	END AS ExpenseLedgerAccountsSettings,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) <> VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN TableWithDocumentsLevel1.Counterparty
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) <> VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.Counterparty
	|		WHEN ISNULL(DivisionTable3Level.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) <> VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN DivisionTable3Level.Counterparty
	|		WHEN ISNULL(RetentionAccrualTableLevel4.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) <> VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.Counterparty
	|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
	|	END AS Counterparty,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.IssuancePurpose, VALUE(Catalog.CashFlowReportItems.EmptyRef)) <> VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.IssuancePurpose
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.IssuancePurpose, VALUE(Catalog.CashFlowReportItems.EmptyRef)) <> VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.IssuancePurpose
	|		WHEN ISNULL(DivisionTable3Level.IssuancePurpose, VALUE(Catalog.CashFlowReportItems.EmptyRef)) <> VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN DivisionTable3Level.IssuancePurpose
	|		WHEN ISNULL(RetentionAccrualTableLevel4.IssuancePurpose, VALUE(Catalog.CashFlowReportItems.EmptyRef)) <> VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.IssuancePurpose
	|		ELSE VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|	END AS IssuancePurpose,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|			THEN TableWithDocumentsLevel1.ARAPObject
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.ARAPObject
	|		WHEN ISNULL(DivisionTable3Level.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|			THEN DivisionTable3Level.ARAPObject
	|		WHEN ISNULL(RetentionAccrualTableLevel4.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.ARAPObject
	|		ELSE VALUE(Catalog.ARAPObjects.EmptyRef)
	|	END AS ARAPObject,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.DimensionOfExpenses, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.DimensionOfExpenses
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.DimensionOfExpenses, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.DimensionOfExpenses
	|		WHEN ISNULL(DivisionTable3Level.DimensionOfExpenses, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DivisionTable3Level.DimensionOfExpenses
	|		WHEN ISNULL(RetentionAccrualTableLevel4.DimensionOfExpenses, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.DimensionOfExpenses
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	END AS DimensionOfExpenses,
	|	CASE
	|		WHEN ISNULL(TableWithDocumentsLevel1.DimensionOfRevenue, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN TableWithDocumentsLevel1.DimensionOfRevenue
	|		WHEN ISNULL(TablePersonnelDocumentsLevel2.DimensionOfRevenue, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN TablePersonnelDocumentsLevel2.DimensionOfRevenue
	|		WHEN ISNULL(DivisionTable3Level.DimensionOfRevenue, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN DivisionTable3Level.DimensionOfRevenue
	|		WHEN ISNULL(RetentionAccrualTableLevel4.DimensionOfRevenue, VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)) <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN RetentionAccrualTableLevel4.DimensionOfRevenue
	|		ELSE VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|	END AS DimensionOfRevenue
	|INTO RulesForFillingInReflectionInAccounting
	|FROM
	|	FillingSettingsAreComplete AS PopulationSettings
	|		LEFT JOIN TableWithDocumentsLevel1 AS TableWithDocumentsLevel1
	|		ON PopulationSettings.TypeOfAccrualDeduction = TableWithDocumentsLevel1.TypeOfAccrualDeduction
	|			AND PopulationSettings.Department = TableWithDocumentsLevel1.Department
	|			AND PopulationSettings.Employee = TableWithDocumentsLevel1.Employee
	|			AND PopulationSettings.DocumentCalculation = TableWithDocumentsLevel1.DocumentCalculation
	|		LEFT JOIN TablePersonnelDocumentsLevel2 AS TablePersonnelDocumentsLevel2
	|		ON (TablePersonnelDocumentsLevel2.DocumentCalculation = UNDEFINED)
	|			AND PopulationSettings.Department = TablePersonnelDocumentsLevel2.Department
	|			AND PopulationSettings.Employee = TablePersonnelDocumentsLevel2.Employee
	|			AND PopulationSettings.TypeOfAccrualDeduction = TablePersonnelDocumentsLevel2.TypeOfAccrualDeduction
	|		LEFT JOIN DivisionTable3Level AS DivisionTable3Level
	|		ON PopulationSettings.Department = DivisionTable3Level.Department
	|			AND PopulationSettings.TypeOfAccrualDeduction = DivisionTable3Level.TypeOfAccrualDeduction
	|			AND (DivisionTable3Level.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND (DivisionTable3Level.DocumentCalculation = UNDEFINED)
	|		LEFT JOIN RetentionAccrualTableLevel4 AS RetentionAccrualTableLevel4
	|		ON PopulationSettings.TypeOfAccrualDeduction = RetentionAccrualTableLevel4.TypeOfAccrualDeduction
	|			AND (RetentionAccrualTableLevel4.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|			AND (RetentionAccrualTableLevel4.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND (RetentionAccrualTableLevel4.DocumentCalculation = UNDEFINED)";
	
	Return QueryText1;
	
EndFunction

#EndRegion

#EndIf
