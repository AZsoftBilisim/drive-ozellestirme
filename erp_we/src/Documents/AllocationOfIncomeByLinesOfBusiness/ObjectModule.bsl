#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocationOfIncomeByLinesOfBusiness.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)

	Income.Clear();
	Expenses.Clear();
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray = New Array;
	If AllocationByAllCompanies Then
		NotCheckedAttributeArray.Add("Organization");
	Else
		NotCheckedAttributeArray.Add("Income.Organization");
		NotCheckedAttributeArray.Add("Expenses.Organization");
	EndIf;
	
	// If there is a line that does not require a distribution method,
	// we will perform a special check for filling in the distribution method.
		
	NotCheckedAttributeArray.Add("Income.LineOfBusinessAllocationMethod");
	NotCheckedAttributeArray.Add("Expenses.LineOfBusinessAllocationMethod");
	
	If GetFunctionalOption("GenerateFinancialResult") Then
	
		For Each TableRow In Income Do
			
			DisplayMessage_ = False;
			If TableRow.AllocationMethodIsRequired
			   And Not ValueIsFilled(TableRow.LineOfBusinessAllocationMethod) Then
				DisplayMessage_ = True;
				
			ElsIf Not TableRow.AllocationMethodIsRequired
				And Not ValueIsFilled(TableRow.LineOfBusiness)
				And Not ValueIsFilled(TableRow.DimensionOfRevenue)
				And Not ValueIsFilled(TableRow.LineOfBusinessAllocationMethod) Then
				DisplayMessage_ = True;
				
			EndIf;
			If DisplayMessage_ Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền cột ""Phương pháp phân bổ"" trong dòng %1 của danh sách ""Thu nhập"".';
						|ru = 'Не заполнена колонка ""Способ распределения"" в строке %1 списка ""Доходы"".';
						|en = 'Column ""Allocation method"" in line %1 of the ""Income"" list is not filled in.'; fa = 'Column ""Allocation method"" in line %1 of the ""Income"" list is not filled in.';
						|it = 'La colonna ""Metodo di ripartizione"" nella riga %1 dell''elenco ""Entrate"" non è stata compilata.';
						|pl = 'Kolumna ""Sposób przydziału"" w wierszu %1 na liście ""Dochody"" nie jest wypełniona.';
						|tr = '""Gelirler"" listesinin %1 satırındaki ""Dağıtım yöntemi"" sütunu doldurulmadı.'"),
					TableRow.LineNumber);
				If Not AdditionalProperties.Property("OutputMessagesToLog") Then
					CommonClientServer.MessageToUser(
						Text,
						ThisObject,
						"Income[" + (TableRow.LineNumber - 1) + "].LineOfBusinessAllocationMethod",
						,
						Cancel);
				Else
					Cancel = True;
				EndIf;
			EndIf;
				
		EndDo;
		
		For Each TableRow In Expenses Do
			
			DisplayMessage_ = False;
			If TableRow.AllocationMethodIsRequired
			   And Not ValueIsFilled(TableRow.LineOfBusinessAllocationMethod) Then
				DisplayMessage_ = True;
				
			ElsIf Not TableRow.AllocationMethodIsRequired
				And Not ValueIsFilled(TableRow.LineOfBusiness)
				And Not ValueIsFilled(TableRow.DimensionOfExpenses)
				And Not ValueIsFilled(TableRow.LineOfBusinessAllocationMethod) Then
				DisplayMessage_ = True;
				
			EndIf;
			If DisplayMessage_ Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền cột ""Phương pháp phân bổ"" trong dòng %1 của danh sách ""Chi phí"".';
						|ru = 'Не заполнена колонка ""Способ распределения"" в строке %1 списка ""Расходы"".';
						|en = 'Column ""Allocation method"" in line %1 of the ""Expenses"" list is not filled in.'; fa = 'Column ""Allocation method"" in line %1 of the ""Expenses"" list is not filled in.';
						|it = 'La colonna ""Metodo di ripartizione"" nella riga %1 dell''elenco ""Uscite"" non è stata compilata.';
						|pl = 'Kolumna ""Sposób przydziału"" w wierszu %1 na liście ""Wydatki"" nie jest wypełniona.';
						|tr = '""Giderler"" listesinin %1 satırındaki ""Dağıtım yöntemi"" sütunu doldurulmadı.'"),
					TableRow.LineNumber);
				If Not AdditionalProperties.Property("OutputMessagesToLog") Then
					CommonClientServer.MessageToUser(
						Text,
						ThisObject,
						"Expenses[" + (TableRow.LineNumber - 1) + "].LineOfBusinessAllocationMethod",
						,
						Cancel);
				Else
					Cancel = True;
				EndIf;
			EndIf;
				
		EndDo;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
		
	ItemsAndDimensionsSelectionParameters = Documents.AllocationOfIncomeByLinesOfBusiness.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);	
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If AllocationByAllCompanies Then
		If ValueIsFilled(Organization) Then
			Organization = Undefined;
		EndIf;
		UpdateOrganizationPresentation();
	Else
		For Each TableRow In Income Do
			If Not ValueIsFilled(TableRow.Organization) Then
				TableRow.Organization = Organization;
			EndIf;
		EndDo;
		For Each TableRow In Expenses Do
			If Not ValueIsFilled(TableRow.Organization) Then
				TableRow.Organization = Organization;
			EndIf;
		EndDo;
		CalculatedCompanies = String(Organization);
	EndIf;
	
	For Each TableRow In Income Do
		If ValueIsFilled(TableRow.DimensionOfRevenue)
			And TypeOf(TableRow.DimensionOfRevenue) = Type("CatalogRef.LinesOfBusiness") Then
			TableRow.LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
		ElsIf ValueIsFilled(TableRow.LineOfBusiness) Then
			TableRow.LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
		EndIf;
	EndDo;
	
	For Each TableRow In Expenses Do
		If ValueIsFilled(TableRow.DimensionOfExpenses)
			And TypeOf(TableRow.DimensionOfExpenses) = Type("CatalogRef.LinesOfBusiness") Then
			TableRow.LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
		ElsIf ValueIsFilled(TableRow.LineOfBusiness) Then
			TableRow.LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
		EndIf;
	EndDo;
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocationOfIncomeByLinesOfBusiness.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.ClearDocumentRegisteredRecords(ThisObject, "FinancialResults");
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#Region FillingInDocument_

Procedure FillInIncomeOnBalances() Export

	Query = New Query("
	|SELECT DISTINCT
	|	Income.Organization AS Organization,
	|	Income.Department AS Department,
	|	Income.LineOfBusiness AS LineOfBusiness,
	|	Income.IncomeItem AS IncomeItem,
	|	Income.DimensionOfRevenue AS DimensionOfRevenue,
	|	Income.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod
	|
	|INTO Income
	|FROM
	|	&Income AS Income
	|WHERE
	|	Income.LineOfBusinessAllocationMethod <> VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef)
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Income.Organization AS Organization,
	|	Income.Department AS Department,
	|	Income.LineOfBusiness AS LineOfBusiness,
	|	Income.IncomeItem AS IncomeItem,
	|	Income.DimensionOfRevenue AS DimensionOfRevenue,
	|	MAX(Income.LineOfBusinessAllocationMethod) AS LineOfBusinessAllocationMethod
	|
	|INTO Dimension
	|FROM
	|	Income AS Income
	|
	|GROUP BY
	|	Income.Organization,
	|	Income.Department,
	|	Income.LineOfBusiness,
	|	Income.IncomeItem,
	|	Income.DimensionOfRevenue
	|;
	|/////////////////////////////////////////////////////////////////////////////
	| SELECT ALLOWED
	|	OtherIncome.Organization AS Organization,
	|	OtherIncome.Department AS Department,
	|	OtherIncome.LineOfBusiness AS LineOfBusiness,
	|	OtherIncome.IncomeItem AS IncomeItem,
	|	OtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(Dimension.LineOfBusinessAllocationMethod,
	|	(CASE
	|		WHEN OtherIncome.IncomeItem.LineOfBusinessAllocationMethod
	|			<> VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef)
	|		THEN OtherIncome.IncomeItem.LineOfBusinessAllocationMethod
	|		ELSE &LineOfBusinessAllocationMethod END)) AS LineOfBusinessAllocationMethod,
	|	OtherIncome.SumTurnover AS Sum,
	|	OtherIncome.SumManTurnover AS SumMan,
	|	OtherIncome.SumComplTurnover AS SumCompl,
	|
	|	CASE WHEN OtherIncome.DimensionOfRevenue REFS Catalog.LinesOfBusiness
	|	 OR OtherIncome.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	 OR NOT &GenerateFinancialResult THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS AllocationMethodIsRequired
	|FROM
	|	AccumulationRegister.OtherIncome.Turnovers(&BeginOfPeriod,&Boundary,, 
	|		Organization = &Organization
	|		OR &ByAllCompanies
	|	) AS OtherIncome
	|
	|	LEFT JOIN
	|		Dimension AS Dimension
	|	ON
	|		OtherIncome.Organization = Dimension.Organization
	|		AND OtherIncome.Department = Dimension.Department
	|		AND OtherIncome.LineOfBusiness = Dimension.LineOfBusiness
	|		AND OtherIncome.IncomeItem  = Dimension.IncomeItem
	|		AND OtherIncome.DimensionOfRevenue = Dimension.DimensionOfRevenue
	|WHERE
	|	OtherIncome.SumTurnover <> 0
	|	OR OtherIncome.SumManTurnover <> 0
	|	OR OtherIncome.SumComplTurnover <> 0
	|");
	Boundary = New Boundary(EndOfMonth(Date), BoundaryType.Including);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Date));
	Query.SetParameter("Boundary", Boundary);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ByAllCompanies", AllocationByAllCompanies);
	Query.SetParameter("Income", Income.Unload(,));
	Query.SetParameter("LineOfBusinessAllocationMethod",
		Catalogs.AllocationMethodsByLinesOfBusiness.DefaultDistributionMethod(Undefined));
	Query.SetParameter("GenerateFinancialResult",	GetFunctionalOption("GenerateFinancialResult"));
	
	QueryResult = Query.Execute();
	QueryTable = QueryResult.Unload();
	
	Income.Load(QueryTable);

EndProcedure

Procedure FillInExpensesOnBalances() Export

	Query = New Query("
	|SELECT DISTINCT
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod
	|
	|INTO Expenses
	|FROM
	|	&Expenses AS Expenses
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	MAX(ISNULL(Expenses.LineOfBusinessAllocationMethod, 
	|		VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef))) AS LineOfBusinessAllocationMethod
	|
	|INTO Dimension
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|		LEFT JOIN Expenses AS Expenses 
	|		ON Expenses.Organization = OtherExpenses.Organization
	|			AND Expenses.Department = OtherExpenses.Department
	|			AND Expenses.LineOfBusiness = OtherExpenses.LineOfBusiness
	|			AND Expenses.ExpenseItem = OtherExpenses.ExpenseItem
	|			AND Expenses.DimensionOfExpenses = OtherExpenses.DimensionOfExpenses
	|WHERE
	|	OtherExpenses.Recorder = &Recorder
	|
	|GROUP BY
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Organization AS Organization,
	|	Balance.Department AS Department,
	|	Balance.LineOfBusiness AS LineOfBusiness,
	|	Balance.ExpenseItem AS ExpenseItem,
	|	Balance.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(Balance.SumBalance) AS SumBalance,
	|	SUM(Balance.AmountExcludingVATBalance) AS AmountExcludingVATBalance,
	|	SUM(Balance.SumComplBalance) AS SumComplBalance,
	|	SUM(Balance.PermanentDifferenceBalance) AS PermanentDifferenceBalance,
	|	SUM(Balance.CostTDBalance) AS CostTDBalance,
	|	SUM(Balance.SumManBalance) AS SumManBalance
	|INTO ExpenseBalances
	|FROM
	|	(SELECT
	|		Balance.Organization AS Organization,
	|		Balance.Department AS Department,
	|		Balance.LineOfBusiness AS LineOfBusiness,
	|		Balance.ExpenseItem AS ExpenseItem,
	|		Balance.DimensionOfExpenses AS DimensionOfExpenses,
	|		Balance.SumBalance AS SumBalance,
	|		Balance.AmountExcludingVATBalance AS AmountExcludingVATBalance,
	|		Balance.SumComplBalance AS SumComplBalance,
	|		Balance.PermanentDifferenceBalance AS PermanentDifferenceBalance,
	|		Balance.CostTDBalance AS CostTDBalance,
	|		Balance.SumManBalance AS SumManBalance
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|				&Boundary,
	|				(Organization = &Organization
	|					OR &ByAllCompanies)
	|					AND (ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|						OR ExpenseItem.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness), VALUE(Enum.CostAllocationOptions.ToProductionCosts)))) AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		RegisterRecords.Sum,
	|		RegisterRecords.AmountExcludingVAT,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.SumMan
	|	FROM
	|		AccumulationRegister.OtherExpenses AS RegisterRecords
	|	WHERE
	|		RegisterRecords.Recorder = &Recorder) AS Balance
	|
	|GROUP BY
	|	Balance.LineOfBusiness,
	|	Balance.ExpenseItem,
	|	Balance.DimensionOfExpenses,
	|	Balance.Department,
	|	Balance.Organization
	|
	|INDEX BY
	|	Balance.Organization,
	|	Balance.Department,
	|	Balance.LineOfBusiness,
	|	Balance.ExpenseItem,
	|	Balance.DimensionOfExpenses
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	| SELECT ALLOWED
	|	Balance.Organization AS Organization,
	|	Balance.Department AS Department,
	|	Balance.LineOfBusiness AS LineOfBusiness,
	|	Balance.ExpenseItem AS ExpenseItem,
	|	Balance.DimensionOfExpenses AS DimensionOfExpenses,
	|	Dimension.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionManag
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.SumBalance
	|		ELSE 0 END) AS Sum,
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionManag
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.SumManBalance
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.SumComplBalance
	|		ELSE 0 END) AS SumCompl,
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.PermanentDifferenceBalance
	|		ELSE 0 END) AS PermanentDifference,
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|		 AND NOT AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|		 THEN -(Balance.SumComplBalance - Balance.CostTDBalance - Balance.PermanentDifferenceBalance)
	|		ELSE Balance.CostTDBalance END) AS CostTD,
	|
	|	CASE WHEN Balance.DimensionOfExpenses REFS Catalog.LinesOfBusiness
	|	 OR Balance.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	 OR NOT &GenerateFinancialResult THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS AllocationMethodIsRequired
	|FROM
	|	ExpenseBalances AS Balance
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON AssetRef.Ref = Balance.ExpenseItem
	|
	|	INNER JOIN
	|		Dimension AS Dimension
	|	ON
	|		Balance.Organization = Dimension.Organization
	|		AND Balance.Department = Dimension.Department
	|		AND Balance.LineOfBusiness = Dimension.LineOfBusiness
	|		AND Balance.ExpenseItem  = Dimension.ExpenseItem
	|		AND Balance.DimensionOfExpenses = Dimension.DimensionOfExpenses
	|WHERE
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionManag
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.SumBalance
	|		ELSE 0 END) <> 0
	|	OR (CASE
	|		WHEN AssetRef.CostAllocationOptionManag
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.SumManBalance
	|		ELSE 0 END) <> 0
	|	OR (CASE
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.SumComplBalance
	|		ELSE 0 END) <> 0
	|	OR (CASE
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN Balance.PermanentDifferenceBalance
	|		ELSE 0 END) <> 0
	|	OR (CASE
	|		WHEN AssetRef.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			AND NOT AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
	|			THEN 0
	|		ELSE Balance.CostTDBalance END) <> 0
	|");
	Boundary = New Boundary(EndOfMonth(Date), BoundaryType.Including);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Date));
	Query.SetParameter("Boundary", Boundary);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ByAllCompanies", AllocationByAllCompanies);
	Query.SetParameter("Expenses", Expenses.Unload(,));
	Query.SetParameter("GenerateFinancialResult",	GetFunctionalOption("GenerateFinancialResult"));
	Query.SetParameter("Recorder", Ref);
	
	QueryResult = Query.Execute();
	QueryTable = QueryResult.Unload();
	
	Expenses.Load(QueryTable);

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	
	Organization = Common.CommonSettingsStorageLoad("CurrentCompany", "");
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

#EndRegion

#Region Other

Procedure UpdateOrganizationPresentation()

	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	CatalogData.Description AS OrganizationPresentation
	|FROM
	|	Catalog.Companies AS CatalogData
	|WHERE
	|	CatalogData.Ref IN (&ArrayOfOrganizationsRevenue)
	|	OR CatalogData.Ref IN (&ArrayOfOrganizationsExpenses)
	|
	|ORDER BY
	|	OrganizationPresentation
	|");
	
	ArrayOfOrganizationsRevenue = Income.UnloadColumn("Organization");
	ArrayOfOrganizationsExpenses = Expenses.UnloadColumn("Organization");
	Query.SetParameter("ArrayOfOrganizationsRevenue", ArrayOfOrganizationsRevenue);
	Query.SetParameter("ArrayOfOrganizationsExpenses", ArrayOfOrganizationsExpenses);
	
	TextPresentationOfOrganizations = "";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TextPresentationOfOrganizations = TextPresentationOfOrganizations
			+ ?(IsBlankString(TextPresentationOfOrganizations), "", ", ")
			+ Selection.OrganizationPresentation;
	EndDo;

	If IsBlankString(TextPresentationOfOrganizations) Then 
		TextPresentationOfOrganizations = NStr("vi = 'Hãy chỉ ra doanh nghiệp';
												|ru = 'Укажите организацию';
												|en = 'Specify the company'; fa = 'Specify the company';
												|it = 'Indicate la società';
												|pl = 'Podaj firmę';
												|tr = 'İş yerini belirt'");
	EndIf;

	If CalculatedCompanies <> TextPresentationOfOrganizations Then
		CalculatedCompanies = TextPresentationOfOrganizations;
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf
