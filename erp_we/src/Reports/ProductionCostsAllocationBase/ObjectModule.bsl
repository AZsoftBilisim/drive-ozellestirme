#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//	ThisForm - ClientApplicationForm - report form.
//	Cancel - Boolean - passed from the handler parameters "as is".
//	StandardProcessing - Boolean - passed from the handler parameters "as is".
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Not ValueIsFilled(Parameters.CommandParameter) Then
			Common.MessageToUser(NStr("vi = 'Phân bổ các chi phí khác chưa được hoàn thành hoặc không bắt buộc.';
										|ru = 'Распределение прочих расходов не выполнено или не требуется.';
										|en = 'Allocation of other expenses is not performed or not required.'; fa = 'Allocation of other expenses is not performed or not required.';
										|it = 'La ripartizione delle altre spese non è stata effettuata o non è richiesta.';
										|pl = 'Przydział innych wydatków nie jest wykonany lub nie jest wymagany.';
										|tr = 'Diğer giderlerin dağıtımı gerçekleştirilmedi veya gerekli değildir.'"),,,,Cancel);
		EndIf;
		
		//@skip-warning
		If TypeOf(Parameters.CommandParameter) = Type("DocumentRef.AllocationOfOtherCosts")
			And Reports.ProductionCostsAllocationBase.SupportedTypesOfAllocationAssignments().Find(
			Common.ObjectAttributeValue(Parameters.CommandParameter, "AssignAllocationSetting")) = Undefined 
		Then
			Common.MessageToUser(NStr("vi = 'Báo cáo không hỗ trợ kiểu phân bổ này';
										|ru = 'Отчет не поддерживает данный тип распределения';
										|en = 'The report does not support this allocation type'; fa = 'The report does not support this allocation type';
										|it = 'Il report non supporta questo tipo di distribuzione';
										|pl = 'Raport nie obsługuje dany typ przydzielenia';
										|tr = 'Rapor bu tip dağıtımı desteklemiyor'"),,,,Cancel);
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("Recorder", Parameters.CommandParameter);
		
	Else
		
		Cancel = True;
		Raise NStr("vi = 'Báo cáo chỉ nhằm mục đích mở trong Chứng từ ""phân bổ chi phí"".';
					|ru = 'Отчет предназначен только для открытия в документе ""Распределение расходов"".';
					|en = 'The report is used only to be opened in the document ""Allocation of expenses"".'; fa = 'The report is used only to be opened in the document ""Allocation of expenses"".';
					|it = 'Il report viene aperto solo nel documento ""Allocazione delle spese"".';
					|pl = 'Raport przeznaczony jest wyłącznie do otwarcia w dokumencie ""Przydział wydatków”.';
					|tr = 'Raporun yalnızca ""Gider dağıtımı"" belgesinde açılması amaçlandı.'") ;
		
	EndIf;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") And Context.Parameters.Property("CommandParameter") Then
		
		DCParameters = New Structure;
		DCParameters.Insert("NewDCSettings", NewDCSettings);
		DCParameters.Insert("Document", Context.Parameters.CommandParameter);
		
		If NewDCUserSettings = Undefined Then
			DCParameters.Insert("NewDCUserSettings", 
				Context.Report.SettingsComposer.UserSettings);
		Else
			DCParameters.Insert("NewDCUserSettings", 
				NewDCUserSettings);
		EndIf;
			
		ConfigureReportParametersByReportVariant(DCParameters);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	LoggerParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Recorder");
	Recorder         = LoggerParameter.Value;
	CostData = DataCompositionClientServer.GetParameter(ReportSettings, "CostData").Value;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AllocationOfOtherCosts.Date AS Date,
		|	AllocationOfOtherCosts.Organization AS Organization,
		|	AllocationOfOtherCosts.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	AllocationOfOtherCosts.Department AS Department,
		|	AllocationOfOtherCosts.ExpenseItem AS ExpenseItem,
		|	AllocationOfOtherCosts.DimensionOfExpenses AS DimensionOfExpenses,
		|	AllocationOfOtherCosts.AssignAllocationSetting AS AssignAllocationSetting,
		|	AllocationOfOtherCosts.AllocateByLots AS AllocateByLots,
		|	AllocationOfOtherCosts.AllocateToBusinessUnits AS AllocateToBusinessUnits,
		|	AllocationOfOtherCosts.AllocateToExpenseItems AS AllocateToExpenseItems,
		|	AllocationOfOtherCosts.AllocateToCostCenter AS AllocateToCostCenter,
		|	AllocationOfOtherCosts.LeaveAsWIP AS LeaveAsWIP,
		|	AllocationOfOtherCosts.AllocationDirection AS AllocationDirection,
		|	AllocationOfOtherCosts.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 
		|		AND VALUETYPE(AllocationOfOtherCosts.DimensionOfExpenses) = TYPE(Catalog.CostCenters) AS ThisIsDistributionFromHIA,
		|	AllocationOfOtherCosts.Factor AS Factor,
		|	AllocationOfOtherCosts.LotsAreSpecifiedManually AS LotsAreSpecifiedManually,
		|	AllocationOfOtherCosts.BusinessUnitsAreSpecifiedManually AS BusinessUnitsAreSpecifiedManually,
		|	AllocationOfOtherCosts.CostShareOfWIP AS CostShareOfWIP,
		|	AllocationOfOtherCosts.CostShareForProduction AS CostShareForProduction,
		|	AllocationOfOtherCosts.CostShareToCostCenters AS CostShareToCostCenters,
		|	AllocationOfOtherCosts.BaseOfAllocationByBusinessUnits AS BaseOfAllocationByBusinessUnits,
		|	AllocationOfOtherCosts.BaseOfAllocationByLots AS BaseOfAllocationByLots,
		|	AllocationOfOtherCosts.TotalCostShares AS TotalCostShares,
		|	AllocationOfOtherCosts.CostShareToExpenseItems AS CostShareToExpenseItems,
		|	AllocationOfOtherCosts.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.AllocationOfOtherCosts AS AllocationOfOtherCosts
		|WHERE
		|	AllocationOfOtherCosts.Ref = &Ref";
	
	Query.SetParameter("Ref", Recorder);
	
	Result = Query.Execute();
	Attributes = Result.Select();
	
	If Not Attributes.Next() Then
		Raise NStr("vi = 'Báo cáo chỉ nhằm mục đích mở trong Chứng từ ""Phân bổ chi phí"".';
					|ru = 'Отчет предназначен только для открытия в документе ""Распределение расходов"".';
					|en = 'The report is used only to be opened in the document ""Allocation of expenses"".'; fa = 'The report is used only to be opened in the document ""Allocation of expenses"".';
					|it = 'Il report viene aperto solo nel documento ""Allocazione delle spese"".';
					|pl = 'Raport przeznaczony jest wyłącznie do otwarcia w dokumencie ""Przydział wydatków”.';
					|tr = 'Raporun yalnızca ""Gider dağıtımı"" belgesinde açılması amaçlandı.'") ;
	EndIf;
	
	BeginOfPeriod     = BegOfMonth(Attributes.Date);
	PeriodEnding  = EndOfMonth(Attributes.Date);
	CompanyArray = CommonClientServer.ValueInArray(Attributes.Organization);
	CurrencyOfTargetCost = Catalogs.Currencies.EmptyRef();
	
	If Attributes.BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.TargetProductCost
		Or Attributes.BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases Then
		
		CurrencyOfTargetCost = Common.ObjectAttributeValue(Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(),
																				"PriceCurrency");
	EndIf;
	
	If CostData = 3 
		Or CostData = 4 
		Or CostData = 6
		Then
		ReportCurrency = Attributes.LocalAccountingCurrency;
	Else 
		ReportCurrency = Constants.ManagementAccountingCurrency.Get();
	EndIf;
	
	// Calculation of the amounts of received expenses
	Query = New Query;
	Query.Text = "
		|SELECT
		|	SUM(T.ExpenseReceived) AS ExpenseReceived
		|FROM (
		|	SELECT
		|		CASE
		|			WHEN &CostData = 1
		|				THEN T.SumBalance
		|			WHEN &CostData = 2
		|				THEN T.AmountExcludingVATBalance
		|			WHEN &CostData = 3
		|				THEN T.SumComplBalance
		|			WHEN &CostData = 4
		|				THEN (T.SumComplBalance - T.PermanentDifferenceBalance - T.CostTDBalance)
		|			WHEN &CostData = 5
		|				THEN T.SumManBalance
		|			WHEN &CostData = 6
		|				THEN AITAmountBalance
		|		END AS ExpenseReceived
		|	FROM
		|		AccumulationRegister.OtherExpenses.Balance(&BeginOfPeriod,
		|			Organization = &Organization
		|				AND Department = &Department
		|				AND DimensionOfExpenses = &Dimension
		|				AND (ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.ExpenseToCostCenters) 
		|					OR ExpenseItem = &AssetRef AND LineOfBusiness = &LineOfBusiness)
		|		) AS T
		|
		|	UNION ALL
		|
		|	SELECT
		|		CASE
		|			WHEN &CostData = 1
		|				THEN T.Sum
		|			WHEN &CostData = 2
		|				THEN T.AmountExcludingVAT
		|			WHEN &CostData = 3
		|				THEN T.SumCompl
		|			WHEN &CostData = 4
		|				THEN (T.SumCompl - T.PermanentDifference - T.CostTD)
		|			WHEN &CostData = 5
		|				THEN T.SumMan
		|			WHEN &CostData = 6
		|				THEN T.AITAmount
		|		END AS ExpenseReceived
		|	FROM
		|		AccumulationRegister.OtherExpenses AS T
		|	WHERE
		|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND T.Organization = &Organization
		|		AND T.Department = &Department
		|		AND T.DimensionOfExpenses = &Dimension
		|		AND (T.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.ExpenseToCostCenters) 
		|			OR T.ExpenseItem = &AssetRef AND T.LineOfBusiness = &LineOfBusiness)
		|	) AS T
		|";
	
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", PeriodEnding);
	Query.SetParameter("CostData", CostData);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("Department", Attributes.Department);
	Query.SetParameter("AssetRef", Attributes.ExpenseItem);
	Query.SetParameter("Dimension", Attributes.DimensionOfExpenses);
	Query.SetParameter("LineOfBusiness", Attributes.LineOfBusiness);
	
	SetPrivilegedMode(True);
	
	TemplateOfPresentation = NStr("vi = 'Số tiền chi phí: %1 (%2)';
									|ru = 'Сумма расходов: %1 (%2)';
									|en = 'Expense amount: %1 (%2)'; fa = 'Expense amount: %1 (%2)';
									|it = 'Importo delle spese: %1 (%2)';
									|pl = 'Suma wydatków: %1 (%2)';
									|tr = 'Gider tutarı: %1 (%2)'");
	PresentationOfAmounts = "";
	ExpenseReceived = 0;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ExpenseReceived = Selection.ExpenseReceived;
		PresentationOfAmounts = StrTemplate(TemplateOfPresentation, Selection.ExpenseReceived, ReportCurrency);
	EndIf;
	
	CostCalculationPerformed = False;
	If Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
		
		StateOfCostCalculation = MonthEndTransactionsServer.DetermineStateOfCalculationSteps(
			Catalogs.MonthEndClosingOperations.AllocationOfExpensesByLinesOfBusiness,
			BeginOfPeriod,
			CompanyArray);

		If StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
		 Or StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
			CostCalculationPerformed = True;
		EndIf;

		StructureOfRequestParameters = Documents.AllocationOfOtherCosts.InitializeParametersOfDistributionOfExpensesForFinancial(
			Attributes.Date, TMCommonUseClientServer.Array(Attributes.Organization), Recorder);
		TemporaryTable = Documents.AllocationOfOtherCosts.TemporaryTablesOfDistributionOfExpensesForProfitabilityAndCosts(StructureOfRequestParameters);
		
		Query = New Query;
		Query.TempTablesManager = TemporaryTable;
		Query.SetParameter("Recorder", Recorder);
		Query.SetParameter("CostData", CostData);
		Query.SetParameter("BaseOfAllocationByLots", Attributes.BaseOfAllocationByLots);
		Query.SetParameter("TypesOfDistributionOfSalesBase", Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Sale"));
		
		Query.Text = "
			|SELECT
			|	ISNULL(SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Sum
			|			WHEN &CostData = 2
			|				THEN DD.Sum
			|			WHEN &CostData = 3
			|				THEN DD.SumCompl
			|			WHEN &CostData = 4
			|				THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.SumMan
			|		END), 0) AS Sum
			|FROM
			|	ExpenseForAllocation AS DD";
		
		Selection = Query.Execute().Select();
		If Selection.Next() And Selection.Sum <> ExpenseReceived And ExpenseReceived <> 0 Then
			PresentationTemplateForDistribution = NStr("vi = 'Để phân bổ có tính đến tiêu chuẩn: %1 (%2)';
														|ru = 'К распределению с учетом нормирования: %1 (%2)';
														|en = 'To allocate considering rationing: %1 (%2)'; fa = 'To allocate considering rationing: %1 (%2)';
														|it = 'К распределению с учетом нормирования: %1 (%2)';
														|pl = 'To allocate considering rationing: %1 (%2)';
														|tr = 'Karne ile dağıtım dikkate alınmakla dağıtım için: %1 (%2)'");
			PresentationTemplateIsNorm = NStr("vi = 'Định mức chi phí: %1 %%';
												|ru = 'Норма расхода: %1 %%';
												|en = 'Expense rate: %1 %%'; fa = 'Expense rate: %1 %%';
												|it = 'Норма расхода: %1 %%';
												|pl = 'Expense rate: %1 %%';
												|tr = 'Gider oranı: %1 %%'");
			PresentationOfAmounts = PresentationOfAmounts 
				+ Chars.LF 
				+ StrTemplate(PresentationTemplateForDistribution, Selection.Sum, ReportCurrency)
				+ Chars.LF 
				+ StrTemplate(PresentationTemplateIsNorm, Format(Round(Selection.Sum / ExpenseReceived, 8), "NS=-2; NG=0"));
		EndIf;
		
		Query.Text =
			"SELECT
			|	CASE
			|		WHEN &BaseOfAllocationByLots IN (&TypesOfDistributionOfSalesBase)
			|		THEN ""Andpotential""
			|		ELSE ""Andoptimization""
			|	END AS EntryType,
			|	UNDEFINED AS Department,
			|	DD.FieldOfActivityReceiver AS LineOfBusiness,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END AS ProductionLot,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	SUM(CASE
			|			WHEN &CostData = 3 OR &CostData = 4
			|			THEN ISNULL(DistributionDatabaseData.BaseLocal, 0)
			|			ELSE ISNULL(DistributionDatabaseData.Base, 0)
			|		END) AS IndicatorValue,
			|	1 AS IndicatorValuePercent,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Sum
			|			WHEN &CostData = 2
			|				THEN DD.Sum
			|			WHEN &CostData = 3
			|				THEN DD.SumCompl
			|			WHEN &CostData = 4
			|				THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.SumMan
			|		END) AS Sum,
			|	UNDEFINED AS ExpenseItem,
			|	UNDEFINED AS DimensionOfExpenses,
			|	UNDEFINED AS AssetsLiabilitiesDimension,
			|	&Recorder AS Recorder,
			|	UNDEFINED AS MaterialProductsService,
			|	UNDEFINED AS ProductsGroup,
			|	1 AS OutputOrder,
			|	TRUE AS SumUpQuantityByStage
			|FROM
			|	AllocationResult AS DD
			|		LEFT JOIN AllocationBase AS DistributionDatabaseData
			|		ON DD.FieldOfActivityReceiver = DistributionDatabaseData.LineOfBusiness
			|			AND DD.ProductionOrder = DistributionDatabaseData.ProductionOrder
			|			AND DD.ProductionLot = DistributionDatabaseData.ProductionLot
			|			AND DD.RowCodeProducts = DistributionDatabaseData.RowCodeProducts
			|
			|GROUP BY
			|	DD.FieldOfActivityReceiver,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END,
			|	DD.RowCodeProducts";
		
	EndIf;
		
	If Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter Then
		
		StateOfCostCalculation = CostCalculationAppliedAlgorithms.CurStateOfCalculation(BeginOfPeriod, CompanyArray);
		
		If StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
		 Or StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
			CostCalculationPerformed = True;
		EndIf;
		
		Query = New Query;
		TempTablesManager = New TempTablesManager;
		Query.TempTablesManager = TempTablesManager;
		
	#Region QueryText
		Query.Text = 
			"SELECT
			|	DD.CorExpenditureDimension AS DimensionOfExpenses,
			|	DD.DebitBusinessUnit AS Department,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Sum
			|			WHEN &CostData = 2
			|				THEN DD.AmountExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.SumCompl
			|			WHEN &CostData = 4
			|				THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.SumMan
			|			WHEN &CostData = 6
			|				THEN DD.AITAmount
			|		END) AS Sum
			|INTO OnOvzFact
			|FROM
			|	AccumulationRegister.OtherExpenses AS DD
			|WHERE
			|	&AllocateToCostCenter
			|	AND DD.Recorder = &Recorder
			|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
			|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
			|	AND CASE
			|			WHEN &CostData = 1
			|				THEN DD.Sum
			|			WHEN &CostData = 2
			|				THEN DD.AmountExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.SumCompl
			|			WHEN &CostData = 4
			|				THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.SumMan
			|			WHEN &CostData = 6
			|				THEN DD.AITAmount
			|		END <> 0 
			|
			|GROUP BY
			|	DD.CorExpenditureDimension,
			|	DD.DebitBusinessUnit
			|;
			|
			|SELECT 
			|	T.ConstCenter,
			|	T.ConstCenter.Department AS Department,
			|	T.IndicatorValue
			|INTO PromIndicatorValues
			|FROM InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(&PeriodEnding, Factor = &Factor) AS T
			|WHERE
			|	T.Factor.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand) OR T.Period >= &BeginOfPeriod
			|;
			|
			|SELECT 
			|	SUM(T.IndicatorValue) AS ValueSum
			|INTO SumOfIndicatorValues
			|FROM PromIndicatorValues AS T
			|;
			|
			|SELECT 
			|	T.ConstCenter,
			|	T.Department,
			|	T.IndicatorValue,
			|	T.IndicatorValue / TT__.ValueSum * 100 AS IndicatorValuePercent
			|INTO IndicatorValues_2
			|FROM PromIndicatorValues AS T
			|	LEFT JOIN SumOfIndicatorValues AS TT__ 
			|ON (TRUE)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.LineOfBusiness AS LineOfBusiness,
			|	CASE
			|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
			|			THEN Rows.ExpenseItem
			|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|	END AS ExpenseItem,
			|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
			|	CASE
			|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
			|			THEN Rows.ExpenseItem
			|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
			|	END AS AssetAndLiabilityItem,
			|	Rows.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Sum
			|			WHEN &CostData = 2
			|				THEN DD.AmountExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.SumCompl
			|			WHEN &CostData = 4
			|				THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.SumMan
			|			WHEN &CostData = 6
			|				THEN DD.AITAmount
			|		END) AS Sum
			|INTO OnArticleFact
			|FROM
			|	AccumulationRegister.OtherExpenses AS DD
			|		INNER JOIN Document.AllocationOfOtherCosts.WriteOff AS Rows
			|		ON DD.Recorder = Rows.Ref
			|			AND DD.RowID = Rows.RowID
			|WHERE
			|	DD.Recorder = &Recorder
			|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
			|	AND CASE
			|		WHEN &CostData = 1
			|			THEN DD.Sum
			|		WHEN &CostData = 2
			|			THEN DD.AmountExcludingVAT
			|		WHEN &CostData = 3
			|			THEN DD.SumCompl
			|		WHEN &CostData = 4
			|			THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|		WHEN &CostData = 5
			|			THEN DD.SumMan
			|		WHEN &CostData = 6
			|			THEN DD.AITAmount
			|	END <> 0
			|
			|GROUP BY
			|	DD.LineOfBusiness,
			|	Rows.ExpenseItem,
			|	Rows.DimensionOfExpenses,
			|	Rows.AssetsLiabilitiesDimension
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.Organization AS Organization,
			|	DD.Department AS Department,
			|	DD.DimensionOfExpenses AS DimensionOfExpenses,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN DD.SumBalance
			|		WHEN &CostData = 2
			|			THEN DD.AmountExcludingVATBalance
			|		WHEN &CostData = 3
			|			THEN DD.SumComplBalance
			|		WHEN &CostData = 4
			|			THEN DD.SumComplBalance - DD.PermanentDifferenceBalance - DD.CostTDBalance
			|		WHEN &CostData = 5
			|			THEN DD.SumManBalance
			|		WHEN &CostData = 6
			|			THEN DD.AITAmountBalance
			|	END AS Sum
			|INTO UnfinishedProductionFact
			|FROM
			|	AccumulationRegister.OtherExpenses.Balance(
			|			DATEADD(&PeriodEnding, SECOND, 1),
			|			Organization = &Organization
			|				AND Department = &Department
			|				AND DimensionOfExpenses = &DimensionOfExpenses
			|	) AS DD
			|WHERE
			|	&LeaveAsWIP
			|	AND CASE
			|		WHEN &CostData = 1
			|			THEN DD.SumBalance
			|		WHEN &CostData = 2
			|			THEN DD.AmountExcludingVATBalance
			|		WHEN &CostData = 3
			|			THEN DD.SumComplBalance
			|		WHEN &CostData = 4
			|			THEN DD.SumComplBalance - DD.PermanentDifferenceBalance - DD.CostTDBalance
			|		WHEN &CostData = 5
			|			THEN DD.SumManBalance
			|		WHEN &CostData = 6
			|			THEN DD.AITAmountBalance
			|	END <> 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	WriteOff.Ref AS Recorder,
			|	WriteOff.ExpenseItem AS CorExpenseItem,
			|	WriteOff.DimensionOfExpenses AS CorExpenditureDimension,
			|	WriteOff.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
			|	SUM(WriteOff.CostShare) AS CostShare
			|INTO WriteOffSharesForItems
			|FROM
			|	Document.AllocationOfOtherCosts.WriteOff AS WriteOff
			|WHERE
			|	WriteOff.Ref = &Recorder
			|
			|GROUP BY
			|	WriteOff.Ref,
			|	WriteOff.ExpenseItem,
			|	WriteOff.DimensionOfExpenses,
			|	WriteOff.AssetsLiabilitiesDimension
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	""OnOvz"" AS EntryType,
			|	ISNULL(Real.Department, DD.Department) AS Department,
			|	UNDEFINED AS ProductionLot,
			|	UNDEFINED AS RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.IndicatorValue AS IndicatorValue,
			|	DD.IndicatorValuePercent AS IndicatorValuePercent,
			|	ISNULL(Real.Sum, 0) AS Sum,
			|	UNDEFINED AS ExpenseItem,
			|	ISNULL(Real.DimensionOfExpenses, DD.ConstCenter) AS DimensionOfExpenses,
			|	UNDEFINED AS AssetsLiabilitiesDimension,
			|	&Recorder AS Recorder,
			|	UNDEFINED AS MaterialProductsService,
			|	UNDEFINED AS ProductsGroup,
			|	1 AS OutputOrder,
			|	FALSE AS SumUpQuantityByStage
			|FROM
			|	IndicatorValues_2 AS DD
			|		FULL JOIN OnOvzFact AS Real
			|		ON DD.ConstCenter = Real.DimensionOfExpenses
			|
			|UNION ALL
			|
			|SELECT
			|	""ToOtherItems"",
			|	UNDEFINED,
			|	UNDEFINED,
			|	0,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.CostShare,
			|	DD.CostShare,
			|	ISNULL(Real.Sum, 0),
			|	DD.CorExpenseItem,
			|	DD.CorExpenditureDimension,
			|	DD.CorDimensionOfAssetsLiabilities,
			|	&Recorder,
			|	UNDEFINED,
			|	UNDEFINED,
			|	1,
			|	TRUE
			|FROM
			|	WriteOffSharesForItems AS DD
			|		LEFT JOIN OnArticleFact AS Real
			|		ON CASE WHEN VALUETYPE(DD.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|			THEN 
			|				DD.CorExpenseItem = Real.ExpenseItem
			|			ELSE
			|				DD.CorExpenseItem = Real.AssetAndLiabilityItem
			|			END
			|			AND DD.CorExpenditureDimension = Real.DimensionOfExpenses
			|			AND DD.CorDimensionOfAssetsLiabilities = Real.AssetsLiabilitiesDimension
			|
			|UNION ALL
			|
			|SELECT
			|	""Nbsp"",
			|	UNDEFINED,
			|	UNDEFINED,
			|	0,
			|	UNDEFINED AS LineOfBusiness,
			|	Attributes.CostShareOfWIP,
			|	Attributes.CostShareOfWIP,
			|	ISNULL(Real.Sum, 0),
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	UNDEFINED,
			|	UNDEFINED,
			|	1,
			|	TRUE
			|FROM
			|	UnfinishedProductionFact AS Real
			|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
			|		ON Real.Organization = Real.Organization
			|			AND Real.Department = Real.Department
			|			AND Real.DimensionOfExpenses = Real.DimensionOfExpenses
			|";
		
	#EndRegion	
			
		Query.SetParameter("Recorder",						Recorder);
		Query.SetParameter("CostData",				CostData);
		Query.SetParameter("BeginOfPeriod",						BeginOfPeriod);
		Query.SetParameter("PeriodEnding",					PeriodEnding);
		Query.SetParameter("Organization",						Attributes.Organization);
		Query.SetParameter("Department",						Attributes.Department);
		Query.SetParameter("AllocateToCostCenter",					Attributes.AllocateToCostCenter);
		Query.SetParameter("LeaveAsWIP",						Attributes.LeaveAsWIP);
		Query.SetParameter("LineOfBusiness",			Attributes.LineOfBusiness);
		Query.SetParameter("ExpenseItem",						Attributes.ExpenseItem);
		Query.SetParameter("DimensionOfExpenses",					Attributes.DimensionOfExpenses);
		Query.SetParameter("Factor",							Attributes.Factor);
		
	EndIf;
		
	If Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost Then
		
		TTM = CostCalculationItemizedCosts.DataForDecodingDirectProductionCosts(BeginOfPeriod, CompanyArray, Recorder, CostCalculationPerformed);
		
		Query = New Query;
		Query.TempTablesManager = TTM;
		
	#Region QueryText
		Query.Text = 
			"SELECT
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	DD.ExpenseItem AS ExpenseItem,
			|	DD.DimensionOfExpenses AS DimensionOfExpenses,
			|	DD.Department AS Department,
			|	DD.ProductsGroup AS ProductsGroup,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Cost
			|			WHEN &CostData = 2
			|				THEN DD.CostExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.LocalCost
			|			WHEN &CostData = 4
			|				THEN DD.LocalCost - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.CostMan
			|			WHEN &CostData = 6
			|				THEN DD.CostOfPersonalIncomeTax
			|		END) AS Sum
			|INTO OnPartyFact
			|FROM
			|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
			|WHERE
			|	DD.Recorder = &Recorder
			|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
			|	AND CASE
			|			WHEN &CostData = 1
			|				THEN DD.Cost
			|			WHEN &CostData = 2
			|				THEN DD.CostExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.LocalCost
			|			WHEN &CostData = 4
			|				THEN DD.LocalCost - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.CostMan
			|			WHEN &CostData = 6
			|				THEN DD.CostOfPersonalIncomeTax
			|		END <> 0 
			|
			|GROUP BY
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ExpenseItem,
			|	DD.DimensionOfExpenses,
			|	DD.Department,
			|	DD.ProductsGroup
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.Department AS Department,
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	&BaseOfAllocationByLots AS TypeOfDistributionBaseByBatch,
			|	CASE 
			|		WHEN DD.ProductsGroup = UNDEFINED 
			|			THEN 
			|				VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
			|			ELSE
			|				DD.ProductsGroup
			|	END AS ProductsGroup,
			|	DD.Factor AS MaterialProductsService,
			|	SUM(CASE
			|		WHEN &CostData = 1
			|			THEN DD.Cost
			|		WHEN &CostData = 2
			|			THEN DD.CostExcludingVAT
			|		WHEN &CostData = 3
			|			THEN DD.LocalCost
			|		WHEN &CostData = 4
			|			THEN DD.LocalCost
			|		WHEN &CostData = 5
			|			THEN DD.CostMan
			|		WHEN &CostData = 6
			|			THEN DD.CostOfPersonalIncomeTax
			|	END) AS Denominator,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN CAST(CASE WHEN MAX(BaseIsConsolidated.Base) = 0 THEN 0 ELSE SUM(DD.Cost) / MAX(BaseIsConsolidated.Base) END AS NUMBER(28, 10))
			|		WHEN &CostData = 2
			|			THEN CAST(CASE WHEN MAX(BaseIsConsolidated.DatabaseWithoutVAT) = 0 THEN 0 ELSE SUM(DD.CostExcludingVAT) / MAX(BaseIsConsolidated.DatabaseWithoutVAT) END AS NUMBER(28, 10))
			|		WHEN &CostData = 3
			|			THEN CAST(CASE WHEN MAX(BaseIsConsolidated.BaseLocal) = 0 THEN 0 ELSE SUM(DD.LocalCost) / MAX(BaseIsConsolidated.BaseLocal) END AS NUMBER(28, 10))
			|		WHEN &CostData = 4
			|			THEN CAST(CASE WHEN MAX(BaseIsConsolidated.BaseLocal) = 0 THEN 0 ELSE SUM(DD.LocalCost) / MAX(BaseIsConsolidated.BaseLocal) END AS NUMBER(28, 10))
			|		WHEN &CostData = 5
			|			THEN CAST(CASE WHEN MAX(BaseIsConsolidated.ManBase) = 0 THEN 0 ELSE SUM(DD.CostMan) / MAX(BaseIsConsolidated.ManBase) END AS NUMBER(28, 10))
			|		WHEN &CostData = 6
			|			THEN CAST(CASE WHEN MAX(BaseIsConsolidated.NDDDatabase) = 0 THEN 0 ELSE SUM(DD.CostOfPersonalIncomeTax) / MAX(BaseIsConsolidated.NDDDatabase) END AS NUMBER(28, 10))
			|	END AS Share
			|INTO ToStagesInDetail
			|FROM
			|	TTBasesOfDirectExpensesInDetail AS DD
			|INNER JOIN TTDirectExpenseBase AS BaseIsConsolidated 
			|ON
			|	DD.Department = BaseIsConsolidated.Department
			|	AND DD.ProductionLot = BaseIsConsolidated.ProductionLot
			|	AND DD.BaseOfAllocationByLots = BaseIsConsolidated.BaseOfAllocationByLots
			|
			|WHERE
			|	DD.BaseOfAllocationByLots = &BaseOfAllocationByLots
			|
			|GROUP BY
			|	DD.Department,
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.Factor
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	""Corrected the following steps"" AS EntryType,
			|	DD.Department AS Department,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END AS ProductionLot,
			|	DD.RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.Denominator AS IndicatorValue,
			|	DD.Denominator AS IndicatorValuePercent,
			|	ISNULL(CAST(Real.Sum AS NUMBER(28, 10)), 0) AS Sum,
			|	UNDEFINED AS ExpenseItem,
			|	UNDEFINED AS DimensionOfExpenses,
			|	UNDEFINED AS AssetsLiabilitiesDimension,
			|	&Recorder AS Recorder,
			|	DD.MaterialProductsService AS MaterialProductsService,
			|	DD.ProductsGroup AS ProductsGroup,
			|	1 AS OutputOrder,
			|	TRUE AS SumUpQuantityByStage
			|FROM
			|	ToStagesInDetail AS DD
			|		LEFT JOIN OnPartyFact AS Real
			|		ON DD.Department = Real.Department
			|			AND DD.ProductionLot = Real.ProductionLot
			|			AND DD.ProductionOrder = Real.ProductionOrder
			|			AND DD.RowCodeProducts = Real.RowCodeProducts
			|			AND DD.ProductsGroup = Real.ProductsGroup";
		
	#EndRegion	
			
		Query.SetParameter("Recorder",						Recorder);
		Query.SetParameter("CostData",				CostData);
		Query.SetParameter("QuantityArray",					Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Count"));
		Query.SetParameter("ArrayOfCosts",					Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Cost"));
		Query.SetParameter("VolumeArray",						Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("VolumeM3"));
		Query.SetParameter("WeightArray",							Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Weight"));
		Query.SetParameter("BaseOfAllocationByLots",			Attributes.BaseOfAllocationByLots);
		Query.SetParameter("BeginOfPeriod",						BeginOfPeriod);
		Query.SetParameter("PeriodEnding",					PeriodEnding);
		Query.SetParameter("Organization",						Attributes.Organization);
		Query.SetParameter("Department",						Attributes.Department);
		Query.SetParameter("ExpenseItem",						Attributes.ExpenseItem);
		Query.SetParameter("DimensionOfExpenses",					Attributes.DimensionOfExpenses);
		
	EndIf;
		
	If Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots Then
		
		TTM = CostCalculationItemizedCosts.DataForDecipheringSharesOfProductionCosts(BeginOfPeriod, CompanyArray, Recorder, CostCalculationPerformed);
		
		Query = New Query;
		Query.TempTablesManager = TTM;
		
	#Region QueryText
		Query.Text = 
			"SELECT
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	DD.ExpenseItem AS ExpenseItem,
			|	DD.DimensionOfExpenses AS DimensionOfExpenses,
			|	DD.Department AS Department,
			|	DD.ProductsGroup AS ProductsGroup,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Cost
			|			WHEN &CostData = 2
			|				THEN DD.CostExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.LocalCost
			|			WHEN &CostData = 4
			|				THEN DD.LocalCost - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.CostMan
			|			WHEN &CostData = 6
			|				THEN DD.CostOfPersonalIncomeTax
			|		END) AS Sum
			|INTO OnPartyFact
			|FROM
			|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
			|WHERE
			|	DD.Recorder = &Recorder
			|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
			|	AND CASE
			|			WHEN &CostData = 1
			|				THEN DD.Cost
			|			WHEN &CostData = 2
			|				THEN DD.CostExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.LocalCost
			|			WHEN &CostData = 4
			|				THEN DD.LocalCost - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.CostMan
			|			WHEN &CostData = 6
			|				THEN DD.CostOfPersonalIncomeTax
			|		END <> 0 
			|
			|GROUP BY
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ExpenseItem,
			|	DD.DimensionOfExpenses,
			|	DD.Department,
			|	DD.CostShare,
			|	DD.ProductsGroup
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.LineOfBusiness AS LineOfBusiness,
			|	CASE
			|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
			|			THEN Rows.ExpenseItem
			|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|	END AS ExpenseItem,
			|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
			|	CASE
			|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
			|			THEN Rows.ExpenseItem
			|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
			|	END AS AssetAndLiabilityItem,
			|	Rows.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Sum
			|			WHEN &CostData = 2
			|				THEN DD.AmountExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.SumCompl
			|			WHEN &CostData = 4
			|				THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|			WHEN &CostData = 5
			|				THEN DD.SumMan
			|			WHEN &CostData = 6
			|				THEN DD.AITAmount
			|		END) AS Sum
			|INTO OnArticleFact
			|FROM
			|	AccumulationRegister.OtherExpenses AS DD
			|		INNER JOIN Document.AllocationOfOtherCosts.WriteOff AS Rows
			|		ON DD.Recorder = Rows.Ref
			|			AND DD.RowID = Rows.RowID
			|WHERE
			|	DD.Recorder = &Recorder
			|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
			|	AND CASE
			|		WHEN &CostData = 1
			|			THEN DD.Sum
			|		WHEN &CostData = 2
			|			THEN DD.AmountExcludingVAT
			|		WHEN &CostData = 3
			|			THEN DD.SumCompl
			|		WHEN &CostData = 4
			|			THEN DD.SumCompl - DD.PermanentDifference - DD.CostTD
			|		WHEN &CostData = 5
			|			THEN DD.SumMan
			|		WHEN &CostData = 6
			|			THEN DD.AITAmount
			|	END <> 0
			|
			|GROUP BY
			|	DD.LineOfBusiness,
			|	Rows.ExpenseItem,
			|	Rows.DimensionOfExpenses,
			|	Rows.AssetsLiabilitiesDimension
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.Organization AS Organization,
			|	DD.Department AS Department,
			|	DD.LineOfBusiness AS LineOfBusiness,
			|	DD.ExpenseItem AS ExpenseItem,
			|	DD.DimensionOfExpenses AS DimensionOfExpenses,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN DD.SumBalance
			|		WHEN &CostData = 2
			|			THEN DD.AmountExcludingVATBalance
			|		WHEN &CostData = 3
			|			THEN DD.SumComplBalance
			|		WHEN &CostData = 4
			|			THEN DD.SumComplBalance - DD.PermanentDifferenceBalance - DD.CostTDBalance
			|		WHEN &CostData = 5
			|			THEN DD.SumManBalance
			|		WHEN &CostData = 6
			|			THEN DD.AITAmountBalance
			|	END AS Sum
			|INTO UnfinishedProductionFact
			|FROM
			|	AccumulationRegister.OtherExpenses.Balance(
			|			DATEADD(&PeriodEnding, SECOND, 1),
			|			Organization = &Organization
			|				AND Department = &Department
			|				AND DimensionOfExpenses = &DimensionOfExpenses
			|				AND (ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.ExpenseToCostCenters) 
			|					OR ExpenseItem = &ExpenseItem AND LineOfBusiness = &LineOfBusiness)
			|	) AS DD
			|WHERE
			|	&LeaveAsWIP
			|	AND CASE
			|		WHEN &CostData = 1
			|			THEN DD.SumBalance
			|		WHEN &CostData = 2
			|			THEN DD.AmountExcludingVATBalance
			|		WHEN &CostData = 3
			|			THEN DD.SumComplBalance
			|		WHEN &CostData = 4
			|			THEN DD.SumComplBalance - DD.PermanentDifferenceBalance - DD.CostTDBalance
			|		WHEN &CostData = 5
			|			THEN DD.SumManBalance
			|		WHEN &CostData = 6
			|			THEN DD.AITAmountBalance
			|	END <> 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	WriteOff.Ref AS Recorder,
			|	WriteOff.ExpenseItem AS CorExpenseItem,
			|	WriteOff.DimensionOfExpenses AS CorExpenditureDimension,
			|	WriteOff.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
			|	SUM(WriteOff.CostShare) AS CostShare
			|INTO WriteOffSharesForItems
			|FROM
			|	Document.AllocationOfOtherCosts.WriteOff AS WriteOff
			|WHERE
			|	WriteOff.Ref = &Recorder
			|
			|GROUP BY
			|	WriteOff.Ref,
			|	WriteOff.ExpenseItem,
			|	WriteOff.DimensionOfExpenses,
			|	WriteOff.AssetsLiabilitiesDimension
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.Department AS Department,
			|	SUM(DD.Sum) AS Sum
			|INTO OnThisFact
			|FROM
			|	OnPartyFact AS DD
			|
			|GROUP BY
			|	DD.Department
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.DebitBusinessUnit AS Department,
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	CASE 
			|		WHEN DD.ProductsGroup = UNDEFINED 
			|			THEN 
			|				VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
			|			ELSE
			|				DD.ProductsGroup
			|	END AS ProductsGroup,
			|	DD.Recorder AS Recorder,
			|	&BaseOfAllocationByBusinessUnits AS DivisionAllocationRule,
			|	DD.Factor AS MaterialProductsService,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN DD.Cost
			|		WHEN &CostData = 2
			|			THEN DD.CostExcludingVAT
			|		WHEN &CostData = 3
			|			THEN DD.LocalCost
			|		WHEN &CostData = 4
			|			THEN DD.LocalCost
			|		WHEN &CostData = 5
			|			THEN DD.CostMan
			|		WHEN &CostData = 6
			|			THEN DD.CostOfPersonalIncomeTax
			|	END AS Denominator,
			|	CASE
			|		WHEN ResultsByStages.Recorder IS NULL
			|			THEN 0
			|		WHEN &CostData = 1
			|			THEN DD.Cost
			|		WHEN &CostData = 2
			|			THEN DD.CostExcludingVAT
			|		WHEN &CostData = 3
			|			THEN DD.LocalCost
			|		WHEN &CostData = 4
			|			THEN DD.LocalCost
			|		WHEN &CostData = 5
			|			THEN DD.CostMan
			|		WHEN &CostData = 6
			|			THEN DD.CostOfPersonalIncomeTax
			|	END AS IndicatorValuePercent
			|INTO OnMapInDetail
			|FROM
			|	DatabaseByDivisionsInDetail AS DD
			|		LEFT JOIN ResultsOfBaseByStagesOfDivisions AS ResultsByStages
			|		ON (ResultsByStages.Recorder = DD.Recorder)
			|			AND (ResultsByStages.Department = DD.DebitBusinessUnit)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.Department AS Department,
			|	SUM(DD.IndicatorValuePercent) AS IndicatorValuePercent
			|INTO DivisionsAreSummarized
			|FROM
			|	(SELECT DISTINCT
			|		DD.Department AS Department,
			|		DD.IndicatorValuePercent AS IndicatorValuePercent
			|	FROM
			|		OnMapInDetail AS DD
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		DD.Department,
			|		1
			|	FROM
			|		BaseByStages AS DD
			|	WHERE
			|		NOT &AllocateToBusinessUnits) AS DD
			|
			|GROUP BY
			|	DD.Department
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.Department AS Department,
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	&BaseOfAllocationByLots AS TypeOfDistributionBaseByBatch,
			|	CASE 
			|		WHEN DD.ProductsGroup = UNDEFINED 
			|			THEN 
			|				VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
			|			ELSE
			|				DD.ProductsGroup
			|	END AS ProductsGroup,
			|	DD.Factor AS MaterialProductsService,
			|	MAX(CASE
			|		WHEN &CostData = 1
			|			THEN DD.Cost
			|		WHEN &CostData = 2
			|			THEN DD.CostExcludingVAT
			|		WHEN &CostData = 3
			|			THEN DD.LocalCost
			|		WHEN &CostData = 4
			|			THEN DD.LocalCost
			|		WHEN &CostData = 5
			|			THEN DD.CostMan
			|		WHEN &CostData = 6
			|			THEN DD.CostOfPersonalIncomeTax
			|	END) AS Denominator,
			|	MAX(CASE
			|		WHEN &CostData = 1
			|			THEN CAST(CASE WHEN BaseIsConsolidated.Cost = 0 THEN 0 ELSE DD.Cost / BaseIsConsolidated.Cost END AS NUMBER(28, 10))
			|		WHEN &CostData = 2
			|			THEN CAST(CASE WHEN BaseIsConsolidated.CostExcludingVAT = 0 THEN 0 ELSE DD.CostExcludingVAT / BaseIsConsolidated.CostExcludingVAT END AS NUMBER(28, 10))
			|		WHEN &CostData = 3
			|			THEN CAST(CASE WHEN BaseIsConsolidated.LocalCost = 0 THEN 0 ELSE DD.LocalCost / BaseIsConsolidated.LocalCost END AS NUMBER(28, 10))
			|		WHEN &CostData = 4
			|			THEN CAST(CASE WHEN BaseIsConsolidated.LocalCost = 0 THEN 0 ELSE DD.LocalCost / BaseIsConsolidated.LocalCost END AS NUMBER(28, 10))
			|		WHEN &CostData = 5
			|			THEN CAST(CASE WHEN BaseIsConsolidated.CostMan = 0 THEN 0 ELSE DD.CostMan / BaseIsConsolidated.CostMan END AS NUMBER(28, 10))
			|		WHEN &CostData = 6
			|			THEN CAST(CASE WHEN BaseIsConsolidated.CostOfPersonalIncomeTax = 0 THEN 0 ELSE DD.CostOfPersonalIncomeTax / BaseIsConsolidated.CostOfPersonalIncomeTax END AS NUMBER(28, 10))
			|	END) AS Share
			|INTO ToStagesInDetail
			|FROM
			|	DatabaseByStagesInDetail AS DD
			|INNER JOIN BaseByStages AS BaseIsConsolidated ON
			|	DD.Department = BaseIsConsolidated.Department
			|	AND DD.ProductionLot = BaseIsConsolidated.ProductionLot
			|	AND DD.ProductionOrder = BaseIsConsolidated.ProductionOrder
			|	AND DD.RowCodeProducts = BaseIsConsolidated.RowCodeProducts
			|	AND DD.ProductsGroup = BaseIsConsolidated.ProductsGroup
			|
			|GROUP BY
			|	DD.Department,
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.Factor
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	DD.ProductsGroup AS ProductsGroup,
			|	DD.Material AS Factor,
			|	2 AS OutputOrder,
			|	SUM(DD.Count) AS Count,
			|	SUM(DD.VolumeM3) AS VolumeM3,
			|	SUM(DD.Weight) AS Weight,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN DD.Cost
			|			WHEN &CostData = 2
			|				THEN DD.CostExcludingVAT
			|			WHEN &CostData = 3
			|				THEN DD.LocalCost
			|			WHEN &CostData = 4
			|				THEN DD.LocalCost
			|			WHEN &CostData = 5
			|				THEN DD.CostMan
			|			WHEN &CostData = 6
			|				THEN DD.CostOfPersonalIncomeTax
			|		END) AS Cost,
			|	0 AS StandardCost,
			|	DD.Department AS Department
			|INTO DataNotEntered
			|FROM
			|	DataOnMaterialCosts AS DD
			|		INNER JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|		LEFT JOIN DatabaseByStagesInDetail AS FilterByBatches
			|		ON DD.ProductionLot = FilterByBatches.ProductionLot
			|			AND DD.ProductionOrder = FilterByBatches.ProductionOrder
			|			AND DD.RowCodeProducts = FilterByBatches.RowCodeProducts
			|			AND DD.Department = FilterByBatches.Department
			|			AND DD.Material = FilterByBatches.Factor
			|WHERE
			|	FilterByBatches.Factor IS NULL
			|	AND &BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount), VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts), VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials), VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials), VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
			|
			|GROUP BY
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.Department,
			|	DD.Material
			|
			|UNION ALL
			|
			|SELECT
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.ManufacturedProduct,
			|	2,
			|	SUM(DD.Count),
			|	SUM(DD.VolumeM3),
			|	SUM(DD.Weight),
			|	SUM(DD.Cost),
			|	0,
			|	DD.Department
			|FROM
			|	ProductData_6 AS DD
			|		INNER JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|		LEFT JOIN DatabaseByStagesInDetail AS FilterByBatches
			|		ON DD.ProductionLot = FilterByBatches.ProductionLot
			|			AND DD.ProductionOrder = FilterByBatches.ProductionOrder
			|			AND DD.RowCodeProducts = FilterByBatches.RowCodeProducts
			|			AND DD.Department = FilterByBatches.Department
			|WHERE
			|	FilterByBatches.Factor IS NULL
			|	AND &BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity), VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight), VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume), VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost), VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases), VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases), VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases), VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
			|
			|GROUP BY
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.Department,
			|	DD.ManufacturedProduct
			|
			|UNION ALL
			|
			|SELECT
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.WorkKind,
			|	2,
			|	SUM(DD.Count),
			|	0,
			|	0,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 3
			|				OR &CostData = 4
			|				THEN DD.LocalCost
			|			WHEN &CostData = 6
			|				THEN DD.CostOfPersonalIncomeTax
			|			ELSE
			|				DD.Cost
			|		END) AS Cost,
			|	SUM(DD.StandardCost),
			|	DD.Department
			|FROM
			|	DataOnLaborCosts AS DD
			|		INNER JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|		LEFT JOIN DatabaseByStagesInDetail AS FilterByBatches
			|		ON DD.ProductionLot = FilterByBatches.ProductionLot
			|			AND DD.ProductionOrder = FilterByBatches.ProductionOrder
			|			AND DD.RowCodeProducts = FilterByBatches.RowCodeProducts
			|			AND DD.Department = FilterByBatches.Department
			|			AND DD.WorkKind = FilterByBatches.Factor
			|WHERE
			|	FilterByBatches.Factor IS NULL
			|	AND &BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses), VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts), VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds), VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel))
			|
			|GROUP BY
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup,
			|	DD.Department,
			|	DD.WorkKind
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	DD.Department AS Department,
			|	DD.ProductionLot AS ProductionLot,
			|	DD.ProductionOrder AS ProductionOrder,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	DD.ProductsGroup AS ProductsGroup
			|INTO PartiesNotIncluded
			|FROM
			|	DataOnMaterialCosts AS DD
			|		INNER JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|		LEFT JOIN BaseByStages AS BaseByStages
			|		ON DD.Department = BaseByStages.Department
			|			AND DD.ProductionLot = BaseByStages.ProductionLot
			|			AND DD.ProductionOrder = BaseByStages.ProductionOrder
			|WHERE
			|	BaseByStages.ProductionLot IS NULL
			|	AND &BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount), VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts), VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials), VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials), VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
			|
			|UNION ALL
			|
			|SELECT
			|	DD.Department,
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup
			|FROM
			|	ProductData_6 AS DD
			|		INNER JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|		LEFT JOIN BaseByStages AS FilterByBatches
			|		ON DD.ProductionLot = FilterByBatches.ProductionLot
			|			AND DD.ProductionOrder = FilterByBatches.ProductionOrder
			|			AND DD.Department = FilterByBatches.Department
			|WHERE
			|	FilterByBatches.ProductionLot IS NULL
			|	AND &BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity), VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight), VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume), VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost), VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases), VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases), VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases), VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
			|
			|UNION ALL
			|
			|SELECT
			|	DD.Department,
			|	DD.ProductionLot,
			|	DD.ProductionOrder,
			|	DD.RowCodeProducts,
			|	DD.ProductsGroup
			|FROM
			|	DataOnLaborCosts AS DD
			|		INNER JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|		LEFT JOIN BaseByStages AS FilterByBatches
			|		ON DD.ProductionLot = FilterByBatches.ProductionLot
			|			AND DD.ProductionOrder = FilterByBatches.ProductionOrder
			|			AND DD.Department = FilterByBatches.Department
			|WHERE
			|	FilterByBatches.ProductionLot IS NULL
			|	AND &BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses), VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts), VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds), VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel))
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	""Corrected the Special Forces"" AS EntryType,
			|	DD.Department AS Department,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END AS ProductionLot,
			|	DD.RowCodeProducts AS RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.Denominator AS IndicatorValue,
			|	DD.IndicatorValuePercent AS IndicatorValuePercent,
			|	ISNULL(Real.Sum, 0) AS Sum,
			|	UNDEFINED AS ExpenseItem,
			|	UNDEFINED AS DimensionOfExpenses,
			|	UNDEFINED AS AssetsLiabilitiesDimension,
			|	&Recorder AS Recorder,
			|	DD.MaterialProductsService AS MaterialProductsService,
			|	DD.ProductsGroup AS ProductsGroup,
			|	1 AS OutputOrder,
			|	TRUE AS SumUpQuantityByStage
			|FROM
			|	OnMapInDetail AS DD
			|		LEFT JOIN OnThisFact AS Real
			|		ON DD.Department = Real.Department
			|WHERE
			|	&BaseOfAllocationByBusinessUnits IN (VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount), VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses), VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts))
			|
			|UNION ALL
			|
			|SELECT
			|	""Corrected the Special Forces"",
			|	DD.Department,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END,
			|	DD.RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	0,
			|	0,
			|	0,
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	UNDEFINED,
			|	DD.ProductsGroup,
			|	3,
			|	FALSE
			|FROM
			|	PartiesNotIncluded AS DD
			|WHERE
			|	&BaseOfAllocationByBusinessUnits IN (VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount), VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses), VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts))
			|
			|UNION ALL
			|
			|SELECT
			|	""Papakostantinou"",
			|	DD.Department,
			|	UNDEFINED,
			|	0,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.Denominator,
			|	DD.IndicatorValuePercent,
			|	ISNULL(Real.Sum, 0),
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	UNDEFINED,
			|	UNDEFINED,
			|	1,
			|	TRUE
			|FROM
			|	OnMapInDetail AS DD
			|		LEFT JOIN OnThisFact AS Real
			|		ON DD.Department = Real.Department
			|WHERE
			|	&BaseOfAllocationByBusinessUnits IN (VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis), VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand))
			|
			|UNION ALL
			|
			|SELECT
			|	""Corrected the following steps"",
			|	DD.Department,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END,
			|	DD.RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.Denominator,
			|	CASE
			|		WHEN DivisionsAreSummarized.Department IS NULL
			|				OR DivisionsAreSummarized.IndicatorValuePercent = 0
			|			THEN 0
			|		ELSE DD.Denominator
			|	END,
			|	ISNULL(CAST(Real.Sum AS NUMBER(28, 10)), 0),
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	DD.MaterialProductsService,
			|	DD.ProductsGroup,
			|	1,
			|	CASE
			|		WHEN DD.TypeOfDistributionBaseByBatch IN (&QuantityArray)
			|			THEN FALSE
			|		ELSE TRUE
			|	END
			|FROM
			|	ToStagesInDetail AS DD
			|		LEFT JOIN OnPartyFact AS Real
			|		ON DD.Department = Real.Department
			|			AND DD.ProductionLot = Real.ProductionLot
			|			AND DD.ProductionOrder = Real.ProductionOrder
			|			AND DD.RowCodeProducts = Real.RowCodeProducts
			|			AND DD.ProductsGroup = Real.ProductsGroup
			|		LEFT JOIN DivisionsAreSummarized AS DivisionsAreSummarized
			|		ON DD.Department = DivisionsAreSummarized.Department
			|
			|UNION ALL
			|
			|SELECT
			|	""Corrected the following steps"",
			|	DD.Department,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END,
			|	DD.RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	CASE
			|		WHEN &BaseOfAllocationByLots IN (&VolumeArray)
			|			THEN DD.VolumeM3
			|		WHEN &BaseOfAllocationByLots IN (&WeightArray)
			|			THEN DD.Weight
			|		WHEN &BaseOfAllocationByLots IN (&ArrayOfCosts)
			|			THEN DD.Cost
			|		ELSE 0
			|	END,
			|	0,
			|	0,
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	UNDEFINED,
			|	DD.ProductsGroup,
			|	DD.OutputOrder,
			|	CASE
			|		WHEN &BaseOfAllocationByLots IN (&QuantityArray)
			|			THEN FALSE
			|		ELSE TRUE
			|	END
			|FROM
			|	DataNotEntered AS DD
			|		LEFT JOIN PartiesNotIncluded AS NotLoggedIn
			|		ON DD.Department = NotLoggedIn.Department
			|			AND DD.ProductionLot = NotLoggedIn.ProductionLot
			|			AND DD.ProductionOrder = NotLoggedIn.ProductionOrder
			|WHERE
			|	NotLoggedIn.ProductionLot IS NULL
			|
			|UNION ALL
			|
			|SELECT
			|	""Corrected the following steps"",
			|	DD.Department,
			|	UNDEFINED,
			|	0,
			|	UNDEFINED AS LineOfBusiness,
			|	0,
			|	0,
			|	0,
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END,
			|	UNDEFINED,
			|	3,
			|	FALSE
			|FROM
			|	PartiesNotIncluded AS DD
			|
			|UNION ALL
			|
			|SELECT
			|	""ToOtherItems"",
			|	UNDEFINED,
			|	UNDEFINED,
			|	0,
			|	UNDEFINED AS LineOfBusiness,
			|	DD.CostShare,
			|	DD.CostShare,
			|	ISNULL(Real.Sum, 0),
			|	DD.CorExpenseItem,
			|	DD.CorExpenditureDimension,
			|	DD.CorDimensionOfAssetsLiabilities,
			|	&Recorder,
			|	UNDEFINED,
			|	UNDEFINED,
			|	1,
			|	TRUE
			|FROM
			|	WriteOffSharesForItems AS DD
			|		LEFT JOIN OnArticleFact AS Real
			|		ON CASE WHEN VALUETYPE(DD.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|			THEN 
			|				DD.CorExpenseItem = Real.ExpenseItem
			|			ELSE
			|				DD.CorExpenseItem = Real.AssetAndLiabilityItem
			|			END
			|			AND DD.CorExpenditureDimension = Real.DimensionOfExpenses
			|			AND DD.CorDimensionOfAssetsLiabilities = Real.AssetsLiabilitiesDimension
			|
			|UNION ALL
			|
			|SELECT
			|	""Nbsp"",
			|	UNDEFINED,
			|	UNDEFINED,
			|	0,
			|	UNDEFINED AS LineOfBusiness,
			|	Attributes.CostShareOfWIP,
			|	Attributes.CostShareOfWIP,
			|	ISNULL(Real.Sum, 0),
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	UNDEFINED,
			|	UNDEFINED,
			|	1,
			|	TRUE
			|FROM
			|	LeaveAsWIP AS DD
			|		INNER JOIN Recorders AS Attributes
			|		ON DD.Recorder = Attributes.Recorder
			|		LEFT JOIN UnfinishedProductionFact AS Real
			|		ON DD.Organization = Real.Organization
			|			AND DD.Department = Real.Department
			|			AND DD.LineOfBusiness = Real.LineOfBusiness
			|			AND DD.ExpenseItem = Real.ExpenseItem
			|			AND DD.DimensionOfExpenses = Real.DimensionOfExpenses
			|
			|UNION ALL
			|
			|SELECT
			|	""Dietpillsnow"",
			|	DD.DebitBusinessUnit,
			|	CASE
			|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN DD.ProductionLot
			|		ELSE DD.ProductionOrder
			|	END,
			|	DD.RowCodeProducts,
			|	UNDEFINED AS LineOfBusiness,
			|	CASE
			|		WHEN &CostData = 3 OR &CostData = 4
			|			THEN DD.ShareOfLocalValue
			|		WHEN &CostData = 6
			|			THEN DD.ShareOfCostOfPersonalIncomeTax
			|		ELSE
			|			DD.CostShare
			|	END,
			|	CASE
			|		WHEN &CostData = 3 OR &CostData = 4
			|			THEN DD.ShareOfLocalValue
			|		WHEN &CostData = 6
			|			THEN DD.ShareOfCostOfPersonalIncomeTax
			|		ELSE
			|			DD.CostShare
			|	END,
			|	ISNULL(Real.Sum, 0),
			|	UNDEFINED,
			|	UNDEFINED,
			|	UNDEFINED,
			|	&Recorder,
			|	UNDEFINED,
			|	UNDEFINED,
			|	1,
			|	TRUE
			|FROM
			|	SharesOfProductionCosts AS DD
			|	INNER JOIN Document.AllocationOfOtherCosts AS Attributes
			|	ON DD.Recorder = Attributes.Ref
			|		AND Attributes.LotsAreSpecifiedManually
			|
			|	LEFT JOIN OnPartyFact AS Real
			|	ON DD.DebitBusinessUnit = Real.Department
			|		AND DD.ProductionLot = Real.ProductionLot
			|		AND DD.ProductionOrder = Real.ProductionOrder
			|		AND DD.RowCodeProducts = Real.RowCodeProducts
			|
			|WHERE
			|	DD.EntryType <> VALUE(Enum.LotRecordTypes.UnfinishedProduction)";
		
	#EndRegion	
			
		Query.SetParameter("Recorder",						Recorder);
		Query.SetParameter("CostData",				CostData);
		Query.SetParameter("QuantityArray",					Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Count"));
		Query.SetParameter("ArrayOfCosts",					Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Cost"));
		Query.SetParameter("VolumeArray",						Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("VolumeM3"));
		Query.SetParameter("WeightArray",							Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Weight"));
		Query.SetParameter("BaseOfAllocationByLots",			Attributes.BaseOfAllocationByLots);
		Query.SetParameter("BaseOfAllocationByBusinessUnits",	Attributes.BaseOfAllocationByBusinessUnits);
		Query.SetParameter("BeginOfPeriod",						BeginOfPeriod);
		Query.SetParameter("PeriodEnding",					PeriodEnding);
		Query.SetParameter("Organization",						Attributes.Organization);
		Query.SetParameter("Department",						Attributes.Department);
		Query.SetParameter("AllocateToBusinessUnits",		Attributes.AllocateToBusinessUnits);
		Query.SetParameter("LeaveAsWIP",						Attributes.LeaveAsWIP);
		Query.SetParameter("LineOfBusiness",			Attributes.LineOfBusiness);
		Query.SetParameter("ExpenseItem",						Attributes.ExpenseItem);
		Query.SetParameter("DimensionOfExpenses",					Attributes.DimensionOfExpenses);
	
	EndIf;
	
	If Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts Then
		
		TTM = CostCalculationItemizedCosts.DataForDecodingAdditionalExpenseAmountBetweenShipmentsAndGoods(BeginOfPeriod, CompanyArray, Recorder, CostCalculationPerformed);
		
		Query = New Query;
		Query.TempTablesManager = TTM;
		Query.SetParameter("Recorder", Recorder);
		Query.SetParameter("CostData", CostData);
		
		Query.Text = "
			|SELECT
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN Data.CostShare
			|			WHEN &CostData = 2
			|				THEN Data.ShareOfValueWithoutVAT
			|			WHEN &CostData = 3
			|				THEN Data.ShareOfLocalValue
			|			WHEN &CostData = 4
			|				THEN Data.ShareValueTa
			|			WHEN &CostData = 5
			|				THEN Data.ShareOfManSCost
			|			WHEN &CostData = 6
			|				THEN Data.ShareOfCostOfPersonalIncomeTax
			|		END) AS Sum,
			|	MAX(Data.CorLot) AS ProductionLot,
			|	MAX(Data.CorItemsLocationAttributes.CHARACTERISTIC) AS Characteristic,
			|	MAX(Data.CorItemsLocationAttributes.Series) AS Series,
			|	MAX(Data.CorItemsLocationAttributes.Products) AS MaterialProductsService,
			|	1 AS IndicatorValue,
			|	1 AS IndicatorValuePercent
			|FROM
			|	SharesOfAdditionalExpenses AS Data";
		
		Selection = Query.Execute().Select();
		If Selection.Next() And Selection.Sum <> ExpenseReceived And ExpenseReceived <> 0 Then
			PresentationTemplateForDistribution = String(Attributes.BaseOfAllocationByLots) + " " + NStr("vi = '(tổng số): %1';
																										|ru = '(всего): %1';
																										|en = '(total): %1'; fa = '(total): %1';
																										|it = '(всего): %1';
																										|pl = '(total): %1';
																										|tr = '(toplam): %1'");
			If Attributes.BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.InventoryCost Then
				PresentationTemplateForDistribution = PresentationTemplateForDistribution + " (" + ReportCurrency + ")";
			EndIf;
			PresentationOfAmounts = PresentationOfAmounts + Chars.LF + StrTemplate(PresentationTemplateForDistribution, Selection.Sum);
			Query.SetParameter("SharedExpense", Selection.Sum);
		Else
			Query.SetParameter("SharedExpense", 1);
		EndIf;
		
	#Region QueryText
		Query.Text = "
			|SELECT
			|	T.Recorder,
			|	T.CorCompany AS Organization,
			|	T.CorItemsLocationAttributes.Products AS Products,
			|	T.CorItemsLocationAttributes.Characteristic AS Characteristic,
			|	T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	CASE WHEN FinAccounting.ItemizeVariancesByLinesOfBusiness
			|		THEN T.CorItemsLocationAttributes.Purpose.LineOfBusiness
			|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
			|	END AS LineOfBusiness,
			|	CASE
			|		WHEN NOT FinAccounting.ItemizeVariancesByBusinessUnits
			|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
			|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
			|			THEN T.CorItemsLocationAttributes.StorageLocation
			|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
			|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
			|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
			|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
			|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
			|	END AS Department,
			|	CASE WHEN FinAccounting.ItemizeVariancesByWarehousesStorageLocations
			|		THEN T.CorItemsLocationAttributes.StorageLocation
			|		ELSE UNDEFINED
			|	END AS StorageLocation,
			|	T.CorExpenseItem,
			|	T.CorExpenditureDimension,
			|	T.CorDimensionOfAssetsLiabilities,
			|	SUM(
			|		CASE
			|			WHEN &CostData = 1
			|				THEN T.CostShare
			|			WHEN &CostData = 2
			|				THEN T.ShareOfValueWithoutVAT
			|			WHEN &CostData = 3
			|				THEN T.ShareOfLocalValue
			|			WHEN &CostData = 4
			|				THEN T.ShareValueTa
			|			WHEN &CostData = 5
			|				THEN T.ShareOfManSCost
			|			WHEN &CostData = 6
			|				THEN T.ShareOfCostOfPersonalIncomeTax
			|		END) AS CostShare
			|
			|INTO ShareOfAdditionalExpensesIsMediumSliding
			|FROM
			|	SharesOfAdditionalExpenses AS T
			|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS FinAccounting
			|		ON T.CorCompany = FinAccounting.Organization
			|WHERE
			// With the cost estimation method, the medium-sliding VAT taxation is empty.
			|	T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.EmptyRef)
			|
			|GROUP BY
			|	T.Recorder,
			|	T.CorCompany,
			|	T.CorItemsLocationAttributes.Products,
			|	T.CorItemsLocationAttributes.CHARACTERISTIC,
			|	T.CorInventoryOwnerAttribute,
			|	CASE WHEN FinAccounting.ItemizeVariancesByLinesOfBusiness
			|		THEN T.CorItemsLocationAttributes.Purpose.LineOfBusiness
			|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
			|	END, // LineOfBusiness
			|	CASE
			|		WHEN NOT FinAccounting.ItemizeVariancesByBusinessUnits
			|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
			|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
			|			THEN T.CorItemsLocationAttributes.StorageLocation
			|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
			|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
			|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
			|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
			|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
			|	END, // Department
			|	CASE WHEN FinAccounting.ItemizeVariancesByWarehousesStorageLocations
			|		THEN T.CorItemsLocationAttributes.StorageLocation
			|		ELSE UNDEFINED
			|	END, // StorageLocation
			|	T.CorExpenseItem,
			|	T.CorExpenditureDimension,
			|	T.CorDimensionOfAssetsLiabilities
			|
			|;
			|SELECT
			|	""AddExpensesForGoods"" AS EntryType,
			|	Data.Department AS Department,
			|	Data.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
			|	Data.Lot AS ProductionLot,
			|	UNDEFINED AS RowCodeProducts,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN SharesOfAdditionalExpenses.CostShare
			|		WHEN &CostData = 2
			|			THEN SharesOfAdditionalExpenses.ShareOfValueWithoutVAT
			|		WHEN &CostData = 3
			|			THEN SharesOfAdditionalExpenses.ShareOfLocalValue
			|		WHEN &CostData = 4
			|			THEN SharesOfAdditionalExpenses.ShareValueTa
			|		WHEN &CostData = 5
			|			THEN SharesOfAdditionalExpenses.ShareOfManSCost
			|		WHEN &CostData = 6
			|			THEN SharesOfAdditionalExpenses.ShareOfCostOfPersonalIncomeTax
			|	END AS IndicatorValue,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN SharesOfAdditionalExpenses.CostShare
			|		WHEN &CostData = 2
			|			THEN SharesOfAdditionalExpenses.ShareOfValueWithoutVAT
			|		WHEN &CostData = 3
			|			THEN SharesOfAdditionalExpenses.ShareOfLocalValue
			|		WHEN &CostData = 4
			|			THEN SharesOfAdditionalExpenses.ShareValueTa
			|		WHEN &CostData = 5
			|			THEN SharesOfAdditionalExpenses.ShareOfManSCost
			|		WHEN &CostData = 6
			|			THEN SharesOfAdditionalExpenses.ShareOfCostOfPersonalIncomeTax
			|	END / &SharedExpense * 100 AS IndicatorValuePercent,
			|	SUM(CASE
			|		WHEN &CostData = 1
			|			THEN Data.AddExpensesForGoods
			|		WHEN &CostData = 2
			|			THEN Data.AdditionalExpensesExcludingVAT
			|		WHEN &CostData = 3
			|			THEN Data.AddExpensesLocal
			|		WHEN &CostData = 4
			|			THEN Data.AddExpensesLocal - Data.PermanentDifference - Data.CostTD
			|		WHEN &CostData = 5
			|			THEN Data.AddExpensesMan
			|		WHEN &CostData = 6
			|			THEN Data.AddExpensesLocal
			|	END) AS Sum,
			|	SharesOfAdditionalExpenses.CorExpenseItem AS ExpenseItem,
			|	SharesOfAdditionalExpenses.CorExpenditureDimension AS DimensionOfExpenses,
			|	SharesOfAdditionalExpenses.CorDimensionOfAssetsLiabilities AS AssetsLiabilitiesDimension,
			|	&Recorder AS Recorder,
			|	Data.ItemsLocationAttributes.Products AS MaterialProductsService,
			|	Data.ItemsLocationAttributes.Characteristic AS Characteristic,
			|	Data.ItemsLocationAttributes.Series AS Series,
			|	Data.FinancialAccountingDimension AS ProductsGroup,
			|	1 AS OutputOrder,
			|	TRUE AS SumUpQuantityByStage
			|FROM
			|	AccumulationRegister.InventoryCost AS Data
			|		LEFT JOIN SharesOfAdditionalExpenses AS SharesOfAdditionalExpenses
			|		ON Data.Recorder = SharesOfAdditionalExpenses.Recorder
			|			AND Data.AccountingSection = SharesOfAdditionalExpenses.CorAccountingSection
			|			AND Data.ItemsLocationAttributes = SharesOfAdditionalExpenses.CorItemsLocationAttributes
			|			AND Data.InventoryOwnerAttribute = SharesOfAdditionalExpenses.CorInventoryOwnerAttribute
			|			AND Data.Organization = SharesOfAdditionalExpenses.CorCompany
			|			AND Data.Lot = SharesOfAdditionalExpenses.CorLot
			|			AND Data.LotVendorAttributes = SharesOfAdditionalExpenses.LotVendorAttributesCorr
			|			AND Data.VATActivityType = SharesOfAdditionalExpenses.CorVATActivityTypes
			|			AND Data.EntryType = SharesOfAdditionalExpenses.EntryType
			|WHERE
			|	Data.Recorder = &Recorder
			|	AND Data.RecordType = VALUE(AccumulationRecordType.Receipt)
			|	AND Data.EntryType <> VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost)
			|
			|GROUP BY
			|	Data.Department,
			|	Data.ItemsLocationAttributes.Purpose.LineOfBusiness,
			|	Data.Lot,
			|	CASE
			|		WHEN &CostData = 1
			|			THEN SharesOfAdditionalExpenses.CostShare
			|		WHEN &CostData = 2
			|			THEN SharesOfAdditionalExpenses.ShareOfValueWithoutVAT
			|		WHEN &CostData = 3
			|			THEN SharesOfAdditionalExpenses.ShareOfLocalValue
			|		WHEN &CostData = 4
			|			THEN SharesOfAdditionalExpenses.ShareValueTa
			|		WHEN &CostData = 5
			|			THEN SharesOfAdditionalExpenses.ShareOfManSCost
			|		WHEN &CostData = 6
			|			THEN SharesOfAdditionalExpenses.ShareOfCostOfPersonalIncomeTax
			|	END, // IndicatorValue
			|	CASE
			|		WHEN &CostData = 1
			|			THEN SharesOfAdditionalExpenses.CostShare
			|		WHEN &CostData = 2
			|			THEN SharesOfAdditionalExpenses.ShareOfValueWithoutVAT
			|		WHEN &CostData = 3
			|			THEN SharesOfAdditionalExpenses.ShareOfLocalValue
			|		WHEN &CostData = 4
			|			THEN SharesOfAdditionalExpenses.ShareValueTa
			|		WHEN &CostData = 5
			|			THEN SharesOfAdditionalExpenses.ShareOfManSCost
			|		WHEN &CostData = 6
			|			THEN SharesOfAdditionalExpenses.ShareOfCostOfPersonalIncomeTax
			|	END / &SharedExpense * 100, // IndicatorValuePercent
			|	SharesOfAdditionalExpenses.CorExpenseItem,
			|	SharesOfAdditionalExpenses.CorExpenditureDimension,
			|	SharesOfAdditionalExpenses.CorDimensionOfAssetsLiabilities,
			|	Data.ItemsLocationAttributes.Products,
			|	Data.ItemsLocationAttributes.Characteristic,
			|	Data.ItemsLocationAttributes.Series,
			|	Data.FinancialAccountingDimension
			|
			|UNION ALL
			|
			|SELECT
			|	""AddExpensesForGoods"" AS EntryType,
			|	Data.Department AS Department,
			|	Data.LineOfBusiness AS LineOfBusiness,
			|	UNDEFINED AS ProductionLot,
			|	UNDEFINED AS RowCodeProducts,
			|	SharesOfAdditionalExpenses.CostShare AS IndicatorValue,
			|	SharesOfAdditionalExpenses.CostShare / &SharedExpense * 100 AS IndicatorValuePercent,
			|	SUM(CASE
			|		WHEN &CostData = 1
			|			THEN Data.CostVariancesIncludingVAT + Data.AdditionalExpensesIncludingVAT
			|		WHEN &CostData = 2
			|			THEN Data.CostVariancesExcludingVAT + Data.AdditionalExpensesExcludingVAT
			|		WHEN &CostData = 3
			|			THEN Data.CostVariancesLocal + Data.AddExpensesLocal + Data.VATLocal
			|		WHEN &CostData = 4
			|			THEN Data.CostVariancesLocal + Data.AddExpensesLocal - Data.PermanentDifference - Data.CostTD
			|		WHEN &CostData = 5
			|			THEN Data.CostVariancesMgmt + Data.AddExpensesMan + Data.VATManag
			|		WHEN &CostData = 6
			|			THEN Data.AIT
			|	END) AS Sum,
			|	SharesOfAdditionalExpenses.CorExpenseItem AS ExpenseItem,
			|	SharesOfAdditionalExpenses.CorExpenditureDimension AS DimensionOfExpenses,
			|	SharesOfAdditionalExpenses.CorDimensionOfAssetsLiabilities AS AssetsLiabilitiesDimension,
			|	&Recorder AS Recorder,
			|	Data.Products AS MaterialProductsService,
			|	Data.Characteristic AS Characteristic,
			|	UNDEFINED AS Series,
			|	UNDEFINED AS ProductsGroup,
			|	1 AS OutputOrder,
			|	TRUE AS SumUpQuantityByStage
			|FROM
			|	AccumulationRegister.GoodsCostVariances AS Data
			|		LEFT JOIN ShareOfAdditionalExpensesIsMediumSliding AS SharesOfAdditionalExpenses
			|		ON Data.Recorder = SharesOfAdditionalExpenses.Recorder
			|			AND Data.Organization = SharesOfAdditionalExpenses.Organization
			|			AND Data.Products = SharesOfAdditionalExpenses.Products
			|			AND Data.Characteristic = SharesOfAdditionalExpenses.Characteristic
			|			AND Data.InventoryOwnerAttribute = SharesOfAdditionalExpenses.InventoryOwnerAttribute
			|			AND Data.LineOfBusiness = SharesOfAdditionalExpenses.LineOfBusiness
			|			AND Data.Department = SharesOfAdditionalExpenses.Department
			|			AND Data.StorageLocation = SharesOfAdditionalExpenses.StorageLocation
			|WHERE
			|	Data.Recorder = &Recorder
			|	AND Data.RecordType = VALUE(AccumulationRecordType.Receipt)
			|
			|GROUP BY
			|	Data.Department,
			|	Data.LineOfBusiness,
			|	SharesOfAdditionalExpenses.CostShare,
			|	SharesOfAdditionalExpenses.CostShare / &SharedExpense * 100,
			|	SharesOfAdditionalExpenses.CorExpenseItem,
			|	SharesOfAdditionalExpenses.CorExpenditureDimension,
			|	SharesOfAdditionalExpenses.CorDimensionOfAssetsLiabilities,
			|	Data.Products,
			|	Data.Characteristic
			|";
		
	#EndRegion
	
	EndIf;
	
	Result = Query.ExecuteBatch();
	Allocation = Result[Result.UBound()].Unload();
	
	DistributionByStagesOfProduction = Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots;
	ThereIsNoDistributionBase = Allocation.Count() = 0;
	PresentationNoDistributionBase = NStr("vi = 'Cơ sở phân bổ đã chọn không có giá trị.';
											|ru = 'Выбранная база распределения не содержит значений.';
											|en = 'The selected allocation base does not have values.'; fa = 'The selected allocation base does not have values.';
											|it = 'Выбранная база распределения не содержит значений.';
											|pl = 'The selected allocation base does not have values.';
											|tr = 'Seçilen tahsisat tabanı değer içermiyor.'");
	
	ExternalDataSets = New Structure("Allocation", Allocation);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;

	UsingGroups = New Map;
	UsingGroups.Insert("PresentationOfAmounts", Not IsBlankString(PresentationOfAmounts));
	UsingGroups.Insert("PresentationOfCostCalculation", Not CostCalculationPerformed);
	UsingGroups.Insert("PresentationNoDistributionBase", ThereIsNoDistributionBase);
	// The type of record "Corrected the divisions", the purpose of the "Distribution of the expenditure items by the production stage" (TT per division in detail, the parties that have gone out):
	UsingGroups.Insert("PresentationOfRuleByDivision", DistributionByStagesOfProduction);
	// Type of record "For the purpose of the subdivision", the purpose of the "Distribution of the cost of the production stage" (TT for the subdivision in detail):
	UsingGroups.Insert("PresentationOfIndicatorByDivision", DistributionByStagesOfProduction);
	// The type of record "Corrected these steps", the purpose of the "Distribution of expenditures on the highest cost of production" (
	// TT on this stage in detail), "Distribution of the most expenses on this stage of production" (TT on this stage in detail,data not exceeded,batch not exceeded):
	UsingGroups.Insert("PresentationOfRuleByStages", DistributionByStagesOfProduction
		Or Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost);
	// Similarly, the presentation of the rules to the following steps:
	UsingGroups.Insert("TablesByDivision", DistributionByStagesOfProduction
		Or Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost);
	// Type of record "At hand", The purpose of the "Distribution of the amount of expenditures by the stage of production" (TT to the production costs):
	UsingGroups.Insert("PresentationOnStagesManually", DistributionByStagesOfProduction);
	// The type of record "Abuse", the purpose of the "Distribution of the amount of expenses for the production stage", "Distribution of expenses" (TT until the writing of the article):
	UsingGroups.Insert("PresentationOnArticles", DistributionByStagesOfProduction
		Or Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter);
	// The type of record "NaNZP", the purpose of the "Distribution of the state of expenditures by the stage of production", "Distribution of expenditures" (TT to leave the NANZP,NaNZPFact):
	UsingGroups.Insert("PresentationOnUnfinishedProduction", DistributionByStagesOfProduction
		Or Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter);
	// Type of record "Nandpofinresultatam", Purpose "Distribution of expenditures on financial results", base "Sales revenue,Gross profit,Cost of sales":
	UsingGroups.Insert("PresentationAtLBOnFinResults",
		Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Sale").Find(Attributes.BaseOfAllocationByLots) <> Undefined
		And Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult);
	// Type of record "Direct expenses", Purpose "Distribution of expenditure on financial results", base not "Sales revenue,gross profit,Cost of sales":
	UsingGroups.Insert("PresentationAtLBOnDirectCosts",
		Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Sale").Find(Attributes.BaseOfAllocationByLots) = Undefined
		And Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult);
	// The type of record "NaOVZ", The purpose of the "Distribution of NAOVZ":
	UsingGroups.Insert("PresentationOnHIA", Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter);
	// Type of record "Additional expenses", Assignment of "Distribution of expenses for the highest cost of goods":
	UsingGroups.Insert("PresentationOfAdditionalExpensesAmount", Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts);
	
	For Each StructureItem In SettingsComposer.Settings.Structure Do
		Use = UsingGroups.Get(StructureItem.Name);
		If Use<>Undefined Then
			StructureItem.Use = Use;
		EndIf;
		If StructureItem.Name = "PresentationOfAdditionalExpensesAmount" And Use Then
			For Each ChoiceItem In StructureItem.Selection.Items Do
				If ChoiceItem.Use Then
					ChoiceItem.Use = ValueIsFilled(Selection[String(ChoiceItem.Field)]);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	ReportSettings = SettingsComposer.GetSettings();
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	//Post processing of the report.
	//We set the reflection of the distribution rules, change the column headers, etc.
	
	SpreadsheetDocument = OutputProcessor.EndOutput();
	
	TitleLayout = "%000%";
	PresentationOfSumsPattern = "%005%";
	PresentationOfCostCalculationTemplate = "%010%";
	PresentationNoBaseDistributionTemplate = "%011%";
	
	Area = SpreadsheetDocument.FindText(TitleLayout);
	If Area <> Undefined Then
		
		If Attributes.ThisIsDistributionFromHIA Then
			ReportHeader = NStr("vi = 'Theo SXDD ""%1"" trong bộ phận ""%2"" trong %3';
								|ru = 'По ОВЗ ""%1"" в подразделении ""%2"" за %3';
								|en = 'By ""%1"" cost center in ""%2"" business unit for %3'; fa = 'By ""%1"" cost center in ""%2"" business unit for %3';
								|it = 'Per al CdC ""%1"" nel reparto ""%2"" per %3';
								|pl = 'Wg obiektu tworzenia się rozchodów ""%1"" w dziale ""%2"" za %3';
								|tr = '%3 ile ""%2"" departmanında ""%1"" MOM''a göre'");
			ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(
				ReportHeader,
				Attributes.DimensionOfExpenses,
				Attributes.Department,
				Format(Attributes.Date, "DF='MMMM yyyy'"));
		Else
			HeaderArray = New Array;
			HeaderArray.Add(StrTemplate(NStr("vi = 'Theo dạng ""%1""';
											|ru = 'По статье ""%1""';
											|en = 'By ""%1"" item'; fa = 'By ""%1"" item';
											|it = 'По статье ""%1""';
											|pl = 'By ""%1"" item';
											|tr = '""%1"" kalemine göre'"), Attributes.ExpenseItem));
			If ValueIsFilled(Attributes.DimensionOfExpenses) Then
				HeaderArray.Add(StrTemplate(NStr("vi = '(đối tượng phân tích ""%1"")';
												|ru = '(аналитика ""%1"")';
												|en = '(dimension ""%1"")'; fa = '(dimension ""%1"")';
												|it = '(аналитика ""%1"")';
												|pl = '(dimension ""%1"")';
												|tr = '(boyut ""%1"")'"), Attributes.DimensionOfExpenses));
			EndIf;
			HeaderArray.Add(StrTemplate(NStr("vi = 'trong bộ phận ""%1"" cho %2';
											|ru = 'в подразделении ""%1"" за %2';
											|en = 'in the ""%1"" business unit for %2'; fa = 'in the ""%1"" business unit for %2';
											|it = 'в подразделении ""%1"" за %2';
											|pl = 'in the ""%1"" business unit for %2';
											|tr = '%2 kapsamında ""%1"" departmanında'"), Attributes.Department, Format(Attributes.Date, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																																				|ru = 'ДФ=''ММММ гггг ""г.""''';
																																				|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																																				|it = 'ДФ=''ММММ гггг ""a.""''';
																																				|pl = 'DF=''ММММ yyyy ""r.""''';
																																				|tr = 'DF=''MMMM yyyy ""yıl.""'''"))));
			ReportHeader = StrConcat(HeaderArray, Chars.LF);
		EndIf;
		
		Area.Text = StrReplace(Area.Text, TitleLayout, ReportHeader);
		
	EndIf;
	
	//Output of the sum representation
	Area = SpreadsheetDocument.FindText(PresentationOfSumsPattern);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOfSumsPattern, PresentationOfAmounts);
	EndIf;
	
	//Output of information about the cost calculation status
	Area = SpreadsheetDocument.FindText(PresentationOfCostCalculationTemplate);
	If Area <> Undefined Then
		If Attributes.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
			PresentationOfCostCalculation = NStr("vi = 'Không thực hiện giai đoạn phân bổ chi phí theo các mảng hoạt động, số tiền chi phí sẽ được cập nhật sau khi tính toán.';
												|ru = 'Не выполнен этап распределения расходов по направлениям деятельности, суммы расходов будут актуализированы после расчета.';
												|en = 'The stage of expenses allocation by lines of business has not been completed, the amounts of expenses will be updated after calculation.'; fa = 'The stage of expenses allocation by lines of business has not been completed, the amounts of expenses will be updated after calculation.';
												|it = 'Non è stata eseguita la distribuzione delle spese per direzione di attività, gli importi di spesa saranno attualizzati dopo il calcolo.';
												|pl = 'Nie wykonano etapu przydzielenia rozchodów według rodzajów działalności, wartości rozchodów będą aktualizowane po rozliczeniu.';
												|tr = 'Giderlerin faaliyetlere göre dağıtılması aşaması gerçekleştirilmedi, gider tutarları hesaplandıktan sonra güncellenecektir.'");
		Else
			PresentationOfCostCalculation = NStr("vi = 'Chưa thực hiện tính toán giá vốn, sẽ cập nhật số tiền chi phí sau khi tính toán.';
												|ru = 'Не выполнен расчет себестоимости, суммы расходов будут актуализированы после расчета.';
												|en = 'Cost is not calculated, expense amounts will be updated after calculation.'; fa = 'Cost is not calculated, expense amounts will be updated after calculation.';
												|it = 'Non è stato effettuato il calcolo del costo di produzione, gli importi delle spese verranno aggiornati dopo il calcolo.';
												|pl = 'Kalkulacja kosztów nie została obliczona, koszty zostaną zaktualizowane po obliczeniu.';
												|tr = 'Maliyet hesaplaması gerçekleştirilmedi, gider tutarları hesaplamadan sonra güncellenecektir.'");
		EndIf;
		Area.Text = StrReplace(Area.Text, PresentationOfCostCalculationTemplate, PresentationOfCostCalculation);
	EndIf;
	
	//Output of information about the cost calculation status
	Area = SpreadsheetDocument.FindText(PresentationNoBaseDistributionTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationNoBaseDistributionTemplate, PresentationNoDistributionBase);
	EndIf;
	
	//Initialization of variables for the design of the rule by division
	If ValueIsFilled(CurrencyOfTargetCost) Then
		PresentationOfCostIndicator = StrTemplate(NStr("vi = 'Giá trị, %1';
														|ru = 'Стоимость, %1';
														|en = 'Cost, %1'; fa = 'Cost, %1';
														|it = 'Costo, %1';
														|pl = 'Wartość, %1';
														|tr = 'Maliyet, %1'"), CurrencyOfTargetCost);
	Else
		PresentationOfCostIndicator = StrTemplate(NStr("vi = 'Giá trị, %1';
														|ru = 'Стоимость, %1';
														|en = 'Cost, %1'; fa = 'Cost, %1';
														|it = 'Costo, %1';
														|pl = 'Wartość, %1';
														|tr = 'Maliyet, %1'"), ReportCurrency);
	EndIf;
	
	PresentationOfPositionByDivision  = NStr("vi = 'Nguyên vật liệu/Nhân công/Sản phẩm';
											|ru = 'Материалы/Работы/Продукция';
											|en = 'Materials/Works/Products'; fa = 'Materials/Works/Products';
											|it = 'Materiali/Lavori/Prodotti';
											|pl = 'Materiały/Prace/Wiersze pozycji';
											|tr = 'Malzemeler/İşler/İmal edilen ürünler'");
	PresentationOfUnitIndicator = NStr("vi = 'Giá trị chỉ tiêu';
										|ru = 'Значение показателя';
										|en = 'Indicator value'; fa = 'مقدار شاخص';
										|it = 'Valore dell''indicatore';
										|pl = 'Wartość wskaźnika';
										|tr = 'Gösterge değeri'");
	PresentationOfRuleByDivision  = NStr("vi = 'Tỷ lệ với chi phí nguyên vật liệu';
										|ru = 'Пропорционально стоимости материальных затрат';
										|en = 'Proportionally to value of material costs'; fa = 'Proportionally to value of material costs';
										|it = 'Proporzionale ai costi materiali';
										|pl = 'Proporcjonalnie do wartości kosztów materialnych';
										|tr = 'Malzeme giderleri değeri ile orantılı'");
	
	//Initialization of variables for the design of the rule by stage
	PresentationOfPositionByStage    = NStr("vi = 'Nguyên vật liệu/Nhân công/Sản phẩm';
											|ru = 'Материалы/Работы/Продукция';
											|en = 'Materials/Works/Products'; fa = 'Materials/Works/Products';
											|it = 'Materiali/Lavori/Prodotti';
											|pl = 'Materiały/Prace/Wiersze pozycji';
											|tr = 'Malzemeler/İşler/İmal edilen ürünler'");
	PresentationOfIndicatorByStage = NStr("vi = 'Giá trị chỉ tiêu';
											|ru = 'Значение показателя';
											|en = 'Indicator value'; fa = 'مقدار شاخص';
											|it = 'Valore dell''indicatore';
											|pl = 'Wartość wskaźnika';
											|tr = 'Gösterge değeri'");
	
	FilterByProductsGroups = Recorder.FilterByProductsGroups.Count() > 0;
	
	BaseOfAllocationByBusinessUnits = Attributes.BaseOfAllocationByBusinessUnits;
	BaseOfAllocationByLots        = Attributes.BaseOfAllocationByLots;
	
	If Attributes.AllocateToBusinessUnits Then
		If BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount Then 
			PresentationOfPositionByDivision  = NStr("vi = 'Nguyên vật liệu';
													|ru = 'Материал';
													|en = 'Material'; fa = 'ماده';
													|it = 'Materiale';
													|pl = 'Materiał';
													|tr = 'Malzeme'");
			PresentationOfUnitIndicator = PresentationOfCostIndicator;
			PresentationOfRuleByDivision  = NStr("vi = '%1 tương ứng với chi phí nguyên vật liệu %2';
												|ru = '%1 пропорционально стоимости материалов %2';
												|en = '%1 proportionally to material cost %2'; fa = '%1 proportionally to material cost %2';
												|it = '%1 proporzionale al costo dei materiali %2';
												|pl = '%1 proporcjonalnie do kosztów materiałów %2';
												|tr = '%1 malzeme maliyeti ile orantılı %2'");
		ElsIf BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses Then
			PresentationOfPositionByDivision  = NStr("vi = 'Dạng công việc';
													|ru = 'Вид работ';
													|en = 'Activity kind'; fa = 'نوع فعالیت';
													|it = 'Tipo di lavori';
													|pl = 'Rodzaj prac';
													|tr = 'İş türü'");
			PresentationOfUnitIndicator = PresentationOfCostIndicator;
			PresentationOfRuleByDivision  = NStr("vi = '%1 theo tỷ lệ chi phí nhân công %2';
												|ru = '%1 пропорционально расходам на оплату труда %2';
												|en = '%1 in proportion to payroll expenses %2'; fa = '%1 in proportion to payroll expenses %2';
												|it = '%1 proporzionale alla spese per il pagamento stipendi %2';
												|pl = '%1 proporcjonalnie do kosztów robocizny %2';
												|tr = '%1 işçilik maliyetleri ile orantılı %2'");
		ElsIf BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts Then
			PresentationOfPositionByDivision  = NStr("vi = 'Nguyên vật liệu \ Dạng công việc';
													|ru = 'Материал \ Вид работ';
													|en = 'Material / Activity kind'; fa = 'Material / Activity kind';
													|it = 'Materiale \ Tipo di lavori';
													|pl = 'Materiał \ Rodzaj prac';
													|tr = 'Malzeme \ İş türü '");
			PresentationOfUnitIndicator = PresentationOfCostIndicator;
			PresentationOfRuleByDivision  = NStr("vi = '%1 theo tỷ lệ chi phí trực tiếp %2';
												|ru = '%1 пропорционально прямым затратам %2';
												|en = '%1 proportionally to direct costs %2'; fa = '%1 proportionally to direct costs %2';
												|it = '%1 proporzionale ai costi diretti %2';
												|pl = '%1 proporcjonalnie do kosztów bezpośrednich %2';
												|tr = '%1 doğrudan giderlerle orantılı %2'");
		ElsIf BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis Then
			PresentationOfRuleByDivision  = NStr("vi = '%1 theo chỉ tiêu biến đổi %2';
												|ru = '%1 по переменным показателям %2';
												|en = '%1 by variable indicators %2'; fa = '%1 by variable indicators %2';
												|it = '%1 in base agli indici variabili %2';
												|pl = '%1 wg zmiennych parametrów %2';
												|tr = '%1 değişken göstergelere göre %2'");
		ElsIf BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand Then
			PresentationOfRuleByDivision  = NStr("vi = '%1 theo chỉ tiêu cố định %2';
												|ru = '%1 по постоянным показателям %2';
												|en = '%1 by fixed indicators %2'; fa = '%1 by fixed indicators %2';
												|it = '%1 in base agli indici costanti %2';
												|pl = '%1 wg stałych parametrów %2';
												|tr = '%1 sabit göstergelere göre %2'");
		Else
			PresentationOfUnitIndicator = NStr("vi = 'Tỷ lệ giá trị';
												|ru = 'Доля стоимости';
												|en = 'Cost share'; fa = 'سهم بها';
												|it = 'Quota del costo';
												|pl = 'Udział kosztów';
												|tr = 'Maliyet payı'");
			PresentationOfRuleByDivision = NStr("vi = '%1 thủ công %2';
												|ru = '%1 вручную %2';
												|en = '%1 manually %2'; fa = '%1 manually %2';
												|it = '%1 manualmente %2';
												|pl = '%1 ręcznie %2';
												|tr = '%1 manuel %2'");
		EndIf;
	EndIf;
	
	If BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount Then 
		
		PresentationOfPositionByStage    = NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материал';
												|en = 'Material'; fa = 'ماده';
												|it = 'Materiale';
												|pl = 'Materiał';
												|tr = 'Malzeme'");
		PresentationOfIndicatorByStage = PresentationOfCostIndicator;
			
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материал';
												|en = 'Material'; fa = 'ماده';
												|it = 'Materiale';
												|pl = 'Materiał';
												|tr = 'Malzeme'");
		PresentationOfIndicatorByStage = NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Quantità';
												|pl = 'Ilość';
												|tr = 'Miktar'");
			
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материал';
												|en = 'Material'; fa = 'ماده';
												|it = 'Materiale';
												|pl = 'Materiał';
												|tr = 'Malzeme'");
		PresentationOfIndicatorByStage = NStr("vi = 'Khối lượng';
												|ru = 'Объем';
												|en = 'Volume'; fa = 'حجم';
												|it = 'Volume';
												|pl = 'Objętość';
												|tr = 'Hacim'");
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материал';
												|en = 'Material'; fa = 'ماده';
												|it = 'Materiale';
												|pl = 'Materiał';
												|tr = 'Malzeme'");
		PresentationOfIndicatorByStage = NStr("vi = 'Tỷ trọng';
												|ru = 'Вес';
												|en = 'Weight'; fa = 'وزن';
												|it = 'Peso';
												|pl = 'Waga';
												|tr = 'Ağırlık'");
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Dạng công việc';
												|ru = 'Вид работ';
												|en = 'Activity kind'; fa = 'نوع فعالیت';
												|it = 'Tipo di lavori';
												|pl = 'Rodzaj prac';
												|tr = 'İş türü'");;
		PresentationOfIndicatorByStage = PresentationOfCostIndicator;
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Dạng công việc';
												|ru = 'Вид работ';
												|en = 'Activity kind'; fa = 'نوع فعالیت';
												|it = 'Tipo di lavori';
												|pl = 'Rodzaj prac';
												|tr = 'İş türü'");;
		PresentationOfIndicatorByStage = PresentationOfCostIndicator;
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Dạng công việc';
												|ru = 'Вид работ';
												|en = 'Activity kind'; fa = 'نوع فعالیت';
												|it = 'Tipo di lavori';
												|pl = 'Rodzaj prac';
												|tr = 'İş türü'");
		PresentationOfIndicatorByStage = NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Quantità';
												|pl = 'Ilość';
												|tr = 'Miktar'");
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.TargetProductCost
		Or BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'");
		PresentationOfIndicatorByStage = PresentationOfCostIndicator;
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.ProductsQuantity
		Or BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'");
		PresentationOfIndicatorByStage = NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Quantità';
												|pl = 'Ilość';
												|tr = 'Miktar'");
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.ProductsVolume
		Or BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'");
		PresentationOfIndicatorByStage = NStr("vi = 'Khối lượng';
												|ru = 'Объем';
												|en = 'Volume'; fa = 'حجم';
												|it = 'Volume';
												|pl = 'Objętość';
												|tr = 'Hacim'");
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.ProductsWeight
		Or BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'");
		PresentationOfIndicatorByStage = NStr("vi = 'Tỷ trọng';
												|ru = 'Вес';
												|en = 'Weight'; fa = 'وزن';
												|it = 'Peso';
												|pl = 'Waga';
												|tr = 'Ağırlık'");
		
	ElsIf BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts Then
		
		PresentationOfPositionByStage    = NStr("vi = 'Nguyên vật liệu \ Dạng công việc';
												|ru = 'Материал \ Вид работ';
												|en = 'Material / Activity kind'; fa = 'Material / Activity kind';
												|it = 'Materiale \ Tipo di lavori';
												|pl = 'Materiał \ Rodzaj prac';
												|tr = 'Malzeme \ İş türü '");
		PresentationOfIndicatorByStage = PresentationOfCostIndicator;
		
	ElsIf Enums.TypesOfCostAllocatingBase.TypesOfDistributionBasesByGroup("Goods").Find(BaseOfAllocationByLots) <> Undefined Then
		
		PresentationOfIndicatorByStage = String(BaseOfAllocationByLots);
		
	EndIf;
	
	PresentationOnArticles = "";
	RulePresentationPrefix = "";
	RulePresentationPostfix = "";
	PresentationOfRuleByStages = "";
	
	CalculationError = 0;
	If Attributes.TotalCostShares = 0 Then
		PercentageOfProduction = ?(Attributes.AllocateByLots,100,0);
		PercentageOfHIA = ?(Attributes.AllocateToCostCenter,100,0);
	Else
		
		InterestOnItems = Round(Attributes.CostShareToExpenseItems * 100/ Attributes.TotalCostShares);
		PercentageOfUnfinishedProduction = Round(Attributes.CostShareOfWIP * 100/ Attributes.TotalCostShares);
		PercentageOfProduction = Round(Attributes.CostShareForProduction * 100/ Attributes.TotalCostShares);
		PercentageOfHIA = Round(Attributes.CostShareToCostCenters * 100/ Attributes.TotalCostShares);
		CalculationError = 100 - PercentageOfProduction - PercentageOfUnfinishedProduction - InterestOnItems - PercentageOfHIA;
		
	EndIf;
	
	If Not CalculationError = 0 Then
		
		MaximumPercentage = Max(InterestOnItems, PercentageOfUnfinishedProduction, PercentageOfProduction, PercentageOfHIA);
		If PercentageOfProduction = MaximumPercentage Then
			PercentageOfProduction = PercentageOfProduction + CalculationError;
		ElsIf PercentageOfHIA = MaximumPercentage Then
			PercentageOfHIA = PercentageOfHIA + CalculationError;
		ElsIf InterestOnItems = MaximumPercentage Then
			InterestOnItems = InterestOnItems + CalculationError;
		ElsIf PercentageOfUnfinishedProduction = MaximumPercentage Then
			PercentageOfUnfinishedProduction = PercentageOfUnfinishedProduction + CalculationError;
		EndIf;
		
	EndIf;
	
	If Attributes.CostShareToCostCenters > 0 And Attributes.TotalCostShares <> Attributes.CostShareToCostCenters Then
		PresentationOnHIA = StrTemplate(NStr("vi = '%1%% được phân bổ cho SXDD khác';
											|ru = '%1%% распределяется на другие ОВЗ';
											|en = '%1%% allocated to other cost centers'; fa = '%1%% allocated to other cost centers';
											|it = '%1%% allocato fra altri CdC';
											|pl = '%1%% przeznaczone na obiekty tworzenia się rozchodów';
											|tr = '%1%% diğer MOM''lara dağıtılıyor'"), InterestOnItems);
	Else
		PresentationOnHIA = NStr("vi = 'Chi phí phân bổ đầy đủ cho các dạng SXDD khác';
								|ru = 'Расходы полностью распределяются на другие ОВЗ';
								|en = 'Expenses are fully allocated to other cost centers'; fa = 'Expenses are fully allocated to other cost centers';
								|it = 'Le spese vengono completamente allocate tra altri CdC';
								|pl = 'Koszty w całości przeznaczone na inne obiekty tworzenia się rozchodów';
								|tr = 'Giderler tamamen diğer MOM''lara dağıtılıyor'");
	EndIf;
	
	If Attributes.CostShareToExpenseItems > 0 And Attributes.TotalCostShares <> Attributes.CostShareToExpenseItems Then
		PresentationOnArticles = StrTemplate(NStr("vi = '%1%% được phân bổ cho các dạng khác';
													|ru = '%1%% распределяется на другие статьи';
													|en = '%1%% allocated to other items'; fa = '%1%% allocated to other items';
													|it = '%1%% viene allocata alle altre voci';
													|pl = '%1%% przeznaczone na inne artykuły';
													|tr = '%1%% diğer kalemlere dağıtılıyor'"), InterestOnItems);
	Else
		PresentationOnArticles = NStr("vi = 'Chi phí được phân bổ đầy đủ cho dạng khác';
										|ru = 'Расходы полностью распределяются на другие статьи';
										|en = 'Expenses are fully allocated to other items'; fa = 'Expenses are fully allocated to other items';
										|it = 'Le spese vengono completamente allocate alle altre voci';
										|pl = 'Koszty w całości przeznaczone na inne artykuły';
										|tr = 'Giderler tamamen diğer kalemlere dağıtılıyor'");
	EndIf;
	
	If Attributes.CostShareOfWIP > 0 And Not Attributes.CostShareOfWIP = Attributes.TotalCostShares Then
		PresentationOnUnfinishedProduction = StrTemplate(NStr("vi = '%1%% vẫn còn trong SXDD';
																|ru = '%1%% остается в НЗП';
																|en = '%1%% left in WIP'; fa = '%1%% left in WIP';
																|it = '%1%% rimane nella produzione non portata a termine';
																|pl = '%1%% pozostają w produkcji niezakończonej';
																|tr = '%1%% TMÜ''de kalmaktadır'"), PercentageOfUnfinishedProduction);
	Else
		PresentationOnUnfinishedProduction = NStr("vi = 'Chi phí vẫn hoàn toàn trong SXDD';
													|ru = 'Расходы полностью остаются в НЗП';
													|en = 'Expenses are entirely left in WIP'; fa = 'Expenses are entirely left in WIP';
													|it = 'Le spese rimangono completamente nella produzione non portata a termine';
													|pl = 'Koszty całkowicie pozostają w produkcji niezakończonej';
													|tr = 'Giderler tamamen TMÜ''de kalmaktadır'");
	EndIf;
	
	RulePresentationPrefix = StrTemplate(NStr("vi = '%1%% được phân bổ';
												|ru = '%1%% распределяется';
												|en = '%1%% is allocated'; fa = '%1%% is allocated';
												|it = '%1%% viene allocata';
												|pl = '%1%% rozprowadza się';
												|tr = '%1%% dağıtılıyor'"), PercentageOfProduction);
	
	If FilterByProductsGroups Then
		RulePresentationPostfix = NStr("vi = 'để nhóm sản phẩm được chọn';
										|ru = 'на выбранные группы продукции';
										|en = 'on the selected item groups'; fa = 'on the selected item groups';
										|it = 'per gruppi dei prodotti selezionati';
										|pl = 'w wybranych grupach produktów';
										|tr = 'seçilen imal edilen ürün gruplarına'");
	EndIf;
	
	If Attributes.AllocateToBusinessUnits Then
		PresentationOfRuleByDivision = StrTemplate(PresentationOfRuleByDivision, 
														RulePresentationPrefix, 
														RulePresentationPostfix);
	EndIf;
	
	If Attributes.AllocateByLots Then
		
		If ValueIsFilled(RulePresentationPrefix) Then
			RulePresentationPrefix = StrTemplate(NStr("vi = '%1 theo lô';
														|ru = '%1 по партиям';
														|en = '%1 by lots'; fa = '%1 by lots';
														|it = '%1 in base ai lotti';
														|pl = '%1 według partii';
														|tr = '%1 lotlara göre'"), RulePresentationPrefix);
		Else
			RulePresentationPrefix = NStr("vi = 'Phân bổ chi phí theo đợt';
											|ru = 'Расходы распределяются по партиям';
											|en = 'Expenses are allocated by lots'; fa = 'Expenses are allocated by lots';
											|it = 'Le spese vengono allocate in base ai lotti';
											|pl = 'Koszty są rozdzielane według partii';
											|tr = 'Giderler lotlara göre dağıtılıyor'");
		EndIf;
		
		TemplateOfPresentation = NStr("vi = '%1 %2 %3';
										|ru = '%1 %2 %3';
										|en = '%1 %2 %3'; fa = '%1 %2 %3';
										|it = '%1 %2 %3';
										|pl = '%1 %2 %3';
										|tr = '%1 %2 %3'");
		AllocationDirection = "";
		If Attributes.LotsAreSpecifiedManually Then
			AllocationDirection = NStr("vi = 'thủ công';
										|ru = 'вручную';
										|en = 'manually'; fa = 'به‌صورت دستی';
										|it = 'manualmente';
										|pl = 'ręcznie';
										|tr = 'manuel'");
		ElsIf Attributes.BusinessUnitsAreSpecifiedManually Then
			AllocationDirection = NStr("vi = 'bộ phận';
										|ru = 'подразделения';
										|en = 'business units'; fa = 'business units';
										|it = 'reparti';
										|pl = 'działu';
										|tr = 'departmanlar'");
		ElsIf Not ValueIsFilled(Attributes.AllocationDirection) Then
			AllocationDirection = NStr("vi = 'của tất cả bộ phận';
										|ru = 'всех подразделений';
										|en = 'all business units'; fa = 'all business units';
										|it = 'tutti i reparti';
										|pl = 'wszystkich działów';
										|tr = 'tüm departmanların'");
		ElsIf Attributes.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Superior Then
			AllocationDirection = NStr("vi = 'đơn vị cấp trên';
										|ru = 'вышестоящего подразделения';
										|en = 'superior business unit'; fa = 'superior business unit';
										|it = 'del reparto superiore';
										|pl = 'działu rodzicielskiego';
										|tr = 'yukarıdaki departmanın'");
		ElsIf Attributes.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Subordinate Then
			AllocationDirection = NStr("vi = 'đơn vị hạ lưu';
										|ru = 'нижестоящих подразделений';
										|en = 'subordinate business units'; fa = 'subordinate business units';
										|it = 'dei reparti inferiori';
										|pl = 'podległych działów';
										|tr = 'aşağıdaki departmanların'");
		ElsIf Attributes.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit Then
			AllocationDirection = NStr("vi = 'bộ phận';
										|ru = 'подразделения';
										|en = 'business units'; fa = 'business units';
										|it = 'reparti';
										|pl = 'działu';
										|tr = 'departmanlar'");
		ElsIf Attributes.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Specified Then
			AllocationDirection = NStr("vi = 'đơn vị được chỉ định';
										|ru = 'указанных подразделений';
										|en = 'specified business units'; fa = 'specified business units';
										|it = 'dei riparti indicati';
										|pl = 'określonych działów';
										|tr = 'belirtilen departmanların'");
		EndIf;
		
		PresentationOfRuleByStages = TrimAll(StrTemplate(TemplateOfPresentation,
													RulePresentationPrefix,
													AllocationDirection,
													RulePresentationPostfix));
															
	ElsIf Attributes.AssignAllocationSetting = 
			Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost Then
		PresentationOfRuleByStages = NStr("vi = 'Chi phí được phân bổ trực tiếp cho các lô hàng sản xuất';
											|ru = 'Расходы распределяются непосредственно на партии производства';
											|en = 'Expenses are allocated directly to production lots'; fa = 'Expenses are allocated directly to production lots';
											|it = 'I costi sono imputati direttamente ai lotti di produzione';
											|pl = 'Rozchody są przydzielane bezpośrednio na partie produkcji';
											|tr = 'Giderler doğrudan üretim lotlara dağıtılıyor'")
	EndIf;
	
	//Replace for divisions
	PresentationOfRuleByDivisionTemplate = "%001%";
	PresentationOnArticlesTemplate = "%002%";
	PresentationOnStagesManuallyTemplate = "%003%";
	PresentationOfRuleByStagesTemplate = "%004%";
	PresentationOnUnfinishedProductionTemplate = "%006%";
	PresentationOnLBTemplate = "%007%";
	PresentationOnHIATemplate = "%008%";
	ReportCurrencyTemplate = "%100%";
	UsingPPTemplate = "%101%";
	PEPattern = "%102%";
	PresentationOfPositionByDivisionTemplate = "%201%";
	PresentationOfPositionByStagesTemplate = "%202%";
	PresentationOfPositionInRowPattern = "%203%";
	
	Area = SpreadsheetDocument.FindText(PresentationOfRuleByDivisionTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOfRuleByDivisionTemplate, PresentationOfRuleByDivision);
	EndIf;
	
	Area = SpreadsheetDocument.FindText(PresentationOnStagesManuallyTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOnStagesManuallyTemplate, PresentationOfRuleByStages);
	EndIf;
	
	Area = SpreadsheetDocument.FindText(UsingPPTemplate);
	While Area <> Undefined Do
		Area.Text = PresentationOfUnitIndicator;
		Area = SpreadsheetDocument.FindText(UsingPPTemplate);
	EndDo;
	
	Area = SpreadsheetDocument.FindText(PresentationOfPositionByDivisionTemplate);
	While Area <> Undefined Do
		Area.Text = PresentationOfPositionByDivision;
		Area = SpreadsheetDocument.FindText(PresentationOfPositionByDivisionTemplate);
	EndDo;
	
	//Replace for stages
	
	Area = SpreadsheetDocument.FindText(PresentationOfRuleByStagesTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOfRuleByStagesTemplate, PresentationOfRuleByStages);
	EndIf;
	
	Area = SpreadsheetDocument.FindText(PresentationOfPositionByStagesTemplate);
	While Area <> Undefined Do
		Area.Text = PresentationOfPositionByStage;
		Area = SpreadsheetDocument.FindText(PresentationOfPositionByStagesTemplate);
	EndDo;
	
	Area = SpreadsheetDocument.FindText(PEPattern);
	While TypeOf(Area) <> Type("Undefined") Do
		Area.Text = PresentationOfIndicatorByStage;
		Area = SpreadsheetDocument.FindText(PEPattern);
	EndDo;
	
	Area = SpreadsheetDocument.FindText(PresentationOfPositionInRowPattern);
	While Area <> Undefined Do
		
		If PresentationOfPositionByStage = NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'") Then
			PresentationOfPositionInRow = NStr("vi = '<sản phẩm khác>';
												|ru = '<другая продукция>';
												|en = '<other products>'; fa = '<other products>';
												|it = '<altri prodotti>';
												|pl = '<inne wiersze pozycji>';
												|tr = '<diğer imal edilen ürünler>'");
		Else
			PresentationOfPositionInRow = StrTemplate(NStr("vi = '<khác %1>';
															|ru = '<другие %1>';
															|en = '<other %1>'; fa = '<other %1>';
															|it = '<altri%1>';
															|pl = '<inne %1>';
															|tr = '<diğer %1>'"), Lower(PresentationOfPositionByStage));
		EndIf;
		
		Area.Text = StrReplace(Area.Text, PresentationOfPositionInRowPattern, PresentationOfPositionInRow);
		Area = SpreadsheetDocument.FindText(PresentationOfPositionInRowPattern);
		
	EndDo;
	
	//We will replace it for distribution to OVZ
	
	Area = SpreadsheetDocument.FindText(PresentationOnHIATemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOnHIATemplate, PresentationOnHIA);
	EndIf;
	
	//Replace for distribution by articles
	
	Area = SpreadsheetDocument.FindText(PresentationOnArticlesTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOnArticlesTemplate, PresentationOnArticles);
	EndIf;
	
	// Replacing the WIP header.
	Area = SpreadsheetDocument.FindText(PresentationOnUnfinishedProductionTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOnUnfinishedProductionTemplate, PresentationOnUnfinishedProduction);
	EndIf;
	
	// Replacing the ND header.
	Area = SpreadsheetDocument.FindText(PresentationOnLBTemplate);
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, PresentationOnLBTemplate, NStr("vi = 'Chi phí được phân bổ giữa các hoạt động';
																		|ru = 'Расходы распределяются между направлениями деятельности';
																		|en = 'Expenses are allocated between lines of business'; fa = 'Expenses are allocated between lines of business';
																		|it = 'Delle spese vengono allocati i settori di attività';
																		|pl = 'Koszty są dzielone między kierunkami działalności';
																		|tr = 'Giderler iş kolları arasında dağıtılıyor'"));
	EndIf;
	
	//Setting currency headers.
	
	Area = SpreadsheetDocument.FindText(ReportCurrencyTemplate);
	While Area <> Undefined Do
		Area.Text = StrReplace(Area.Text, ReportCurrencyTemplate, ReportCurrency);
		Area = SpreadsheetDocument.FindText(ReportCurrencyTemplate);
	EndDo;
	
	SpreadsheetDocument.ShowRowGroupLevel(2);
	
EndProcedure

#EndRegion

#Region Private


// Adjusts the available values for the "cost Data" data layout parameter, depending on the option.
// 
// Parameters:
//	DCParameters - Structure - LongDesc:
//		* Document - DocumentRef.AllocationOfOtherCosts - a decoding document.
//		* NewDCUserSettings - DataCompositionUserSettings - data layout scheme settings.
Procedure ConfigureReportParametersByReportVariant(DCParameters)
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("CostData");
	
	AttributesValues = Common.ObjectAttributesValues(DCParameters.Document, "LocalAccounting, ManagementAccounting,
	|AIT,
	|AssignAllocationSetting");
	
	ChoiceList = New ValueList;
	
	If AttributesValues.ManagementAccounting Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		If Not AttributesValues.AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
			ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
									|ru = 'В валюте упр. учета без НДС';
									|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
									|it = 'In valuta della contabilità gestionale senza IVA';
									|pl = 'W walucie zarz. ewidencji bez VAT';
									|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(5, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		
	EndIf;
	
	If AttributesValues.LocalAccounting 
		Or AttributesValues.AIT
		Then
		
		ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));

	EndIf;
	
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If DCParameters.NewDCSettings = Undefined
		Or DCParameters.NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = DCParameters.NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("CostData"));
	ConfiguringReportData = DCParameters.NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
