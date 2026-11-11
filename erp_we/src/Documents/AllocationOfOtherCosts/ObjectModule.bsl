#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If DocumentsPosting.DocumentProperties(ThisObject).IsNew Then
		GetNewObjectRef();
	EndIf;
	If ValueIsFilled(LineOfBusiness) Then
		For Each String In WriteOff Do
			String.LineOfBusiness = LineOfBusiness;
		EndDo;
	EndIf;
	
	For Each DebitingLine In WriteOff Do
		
		If ValueIsFilled(DebitingLine.Department) Then
			Continue;
		EndIf;
		
		DebitingLine.Department = Department;
		
	EndDo;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "WriteOff");
	
	TotalCostShares = CostShareForProduction + CostShareOfWIP + CostShareToExpenseItems + CostShareToCostCenters;
		
	If WriteMode = DocumentWriteMode.Posting
		And AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots
		And (AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit
			Or AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Superior
			Or AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Subordinate) Then
		
		DCSchema = Catalogs.CostAllocationRules.GetTemplate("AllocationDirection");
		DefaultSettings = DCSchema.DefaultSettings;
			
		FilterByBusinessUnit = DefaultSettings.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		
		If AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit Then
			
			FilterByBusinessUnit.LeftValue = New DataCompositionField("Department");
			FilterByBusinessUnit.RightValue = New DataCompositionField("DataParameters.CurrentDepartment");
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.Equal;
				
		ElsIf AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Superior Then
			
			FilterByBusinessUnit.LeftValue = New DataCompositionField("Department");
			FilterByBusinessUnit.RightValue = New DataCompositionField("DataParameters.SuperiorDepartment");
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.Equal;
				
		ElsIf AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Subordinate Then
			
			FilterByBusinessUnit.LeftValue = New DataCompositionField("Department");
			FilterByBusinessUnit.RightValue = New DataCompositionField("DataParameters.CurrentDepartment");
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.InHierarchy;
			
			SelectionByDivisionIsNotEqualTo = DefaultSettings.Filter.Items.Add(
				Type("DataCompositionFilterItem"));
			SelectionByDivisionIsNotEqualTo.LeftValue = New DataCompositionField("Department");
			SelectionByDivisionIsNotEqualTo.ComparisonType = DataCompositionComparisonType.NotEqual;
			SelectionByDivisionIsNotEqualTo.RightValue = New DataCompositionField("DataParameters.CurrentDepartment");
		
		EndIf;

		AllocationDirectionSettingsChanged = True;
		AllocationDirectionSettings = New ValueStorage(DefaultSettings);
		
	EndIf;
		
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.AllocationOfOtherCosts.AccountingAccountSettings_());
		
	IncomeAndExpensesServer.BeforeWrite(ThisObject, 
		Documents.AllocationOfOtherCosts.ItemsAndDimensionsSelectionParameters());
	If AssignAllocationSetting <> Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
		DataSource = Enums.DataSourcesForExpenseAllocation.EmptyRef();
	EndIf;
	
	// Checking for incorrect settings of distribution rules in the context of organizations and divisions
	If WriteMode = DocumentWriteMode.Posting Then
		ThereAreAssignmentErrors = False;
		VariantsOfArticle = Common.ObjectAttributesValues(
			?(ValueIsFilled(ExpenseItem), ExpenseItem, DimensionOfExpenses), 
			"CostAllocationOptionManag, CostAllocationOptionLocal");
		If ManagementAccounting And AssignAllocationSetting <> 
			Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(VariantsOfArticle.CostAllocationOptionManag) 
		Then
			ThereAreAssignmentErrors = True;
		EndIf;
		If LocalAccounting And AssignAllocationSetting <> 
			Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(VariantsOfArticle.CostAllocationOptionLocal) 
		Then
			ThereAreAssignmentErrors = True;
		EndIf;
		If ThereAreAssignmentErrors Then
			MessageText = NStr("vi = 'Khi lập chứng từ phân bổ chi phí, đã tìm thấy chênh lệch giữa phương án và quy tắc phân bổ trong dạng chi phí.
				|Cần đặt tương ứng tùy chỉnh các quy tắc theo từng doanh nghiệp và bộ phận.
				|Kỳ: %1, doanh nghiệp: ""%2"", bộ phận: ""%3"", dạng chi phí: ""%4""';
				|ru = 'При формировании документа распределения расходов обнаружено расхождение варианта и правила распределения в статье расходов.
				|Необходимо привести в соответствие настройки правил в разрезе организаций и подразделений.
				|Период: %1, организация: ""%2"", подразделение: ""%3"", статья расходов: ""%4""';
				|en = 'Discrepancy of the option and the allocation rule is detected in the expense item upon generating the expense allocation document.
				|Match the rule settings by companies and business units.
				|Period: %1, company: ""%2"", business unit: ""%3"", expense item: ""%4""'; fa = 'Discrepancy of the option and the allocation rule is detected in the expense item upon generating the expense allocation document.
				|Match the rule settings by companies and business units.
				|Period: %1, company: ""%2"", business unit: ""%3"", expense item: ""%4""';
				|it = 'Durante la generazione del documento di ripartizione delle spese, è stata rilevata una mancata corrispondenza tra la variante e la regola di ripartizione nella voce di spese.
				|È necessario uniformare le impostazioni delle regole nella specifica delle aziende e dei reparti.
				|Periodo: %1, azienda: ""%2"", reparto: ""%3"", voce di spese: ""%4""';
				|pl = 'Podczas utworzenia dokumentu przydzielenia rozchodów wykryto rozbieżność wariantu i zasady przydzielenia w rodzaju kosztu.
				|Należy uzgodnić ustawienia zasad w przekroju firm i działów.
				|Okres: %1, firma: ""%2"", dział: ""%3"", rodzaj kosztu: ""%4""';
				|tr = 'Gider dağıtım belgesi düzenlenirken, gider kalemindeki seçenek ile dağıtım kuralı arasında uyumsuzluk tespit edildi.
				|İş yeri ve departman bağlamında kural ayarlarının uyumlu hale getirilmesi gerekmektedir.
				|Dönem: %1, iş yeri: ""%2"", departman: ""%3"", gider kalemi: ""%4""'");
			MessageText = StrTemplate(MessageText, Format(Date, "DF='MMMM yyyy';"), Organization, Department, ExpenseItem);
			
			Cancel = True;
			Raise MessageText;
				
		EndIf;
	EndIf;
	
	AllocationOfOtherCostsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	TMCommonUse.ClearDocumentIDs(ThisObject, "WriteOff");
	Return;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	AllocationOfOtherCostsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	ThisIsDistributionFromHIA = False;
	ThisIsDistributionForHIA = False;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		KeyDistributionRules = "";
		DistributionOptionKey = "";
		If ManagementAccounting Then
			KeyDistributionRules = "ManDistributionRule";
			DistributionOptionKey = "ManDistributionOption";
		ElsIf LocalAccounting Then
			KeyDistributionRules = "LocalDistributionRule";
			DistributionOptionKey = "LocalDistributionOption";
		ElsIf AIT Then
			KeyDistributionRules = "RuleOfDistributionOfPersonalIncomeTax";
			DistributionOptionKey = "NDTDistributionOption";
		EndIf;
		ThisIsDistributionFromHIA = 
			TypeOf(DimensionOfExpenses) = Type("CatalogRef.CostCenters");
		ThisIsDistributionForHIA = 
			FillingData[DistributionOptionKey] = Enums.CostAllocationOptions.ToCostCenters;
		If FillingData.Property(DistributionOptionKey)
			And ValueIsFilled(FillingData[DistributionOptionKey])
			And Enums.CostAllocationOptions.VariantUsesAllocationRule(FillingData[DistributionOptionKey])
			And FillingData.Property(KeyDistributionRules)
			And ValueIsFilled(FillingData[KeyDistributionRules]) Then
			If TypeOf(FillingData[KeyDistributionRules]) = Type("CatalogRef.CostAllocationRules") Then
				QueryText = 
					// Selection of directions of activity with verification for the period of activity.
					"SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness
					|FROM
					|	Catalog.CostAllocationRules.FilterByLinesOfBusiness AS T
					|		INNER JOIN Catalog.LinesOfBusiness AS LB
					|		ON T.LineOfBusiness = LB.Ref
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND (LB.StartDateOfActivity <= &EndOfPeriod OR LB.StartDateOfActivity = DATETIME(1,1,1))
					|	AND (LB.EndDateOfActivity >= &BeginOfPeriod OR LB.EndDateOfActivity = DATETIME(1,1,1))
					|
					|UNION ALL
					|
					|SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness
					|FROM
					|	Catalog.CostAllocationRules.FilterByLinesOfBusiness AS T
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND T.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
					|
					|;
					|
					// Directions of activity with verification for the period of activity.
					|SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness,
					|	T.CostShare AS CostShare
					|FROM
					|	Catalog.CostAllocationRules.LinesOfBusiness AS T
					|		INNER JOIN Catalog.LinesOfBusiness AS LB
					|		ON T.LineOfBusiness = LB.Ref
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND (LB.StartDateOfActivity <= &EndOfPeriod OR LB.StartDateOfActivity = DATETIME(1,1,1))
					|	AND (LB.EndDateOfActivity >= &BeginOfPeriod OR LB.EndDateOfActivity = DATETIME(1,1,1))
					|
					|UNION ALL
					|
					|SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness,
					|	T.CostShare AS CostShare
					|FROM
					|	Catalog.CostAllocationRules.LinesOfBusiness AS T
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND T.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
					|;
					|
					|SELECT
					|	AllocationRules.AssignRule AS AssignAllocationSetting,
					|	AllocationRules.AllocationDirection AS AllocationDirection,
					|	AllocationRules.BaseOfAllocationByLots AS BaseOfAllocationByLots,
					|	AllocationRules.SettingsOfBaseOfAllocationByLotsChanged,
					|	AllocationRules.SettingsOfBaseOfAllocationByLots,
					|	CASE
					|		WHEN AllocationRules.DataSource = VALUE(Enum.DataSourcesForExpenseAllocation.EmptyRef)
					|			AND AllocationRules.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
					|		THEN VALUE(Enum.DataSourcesForExpenseAllocation.FinancialResults)
					|		ELSE AllocationRules.DataSource
					|	END AS DataSource
					|	,AllocationRules.SettingsOfBaseOfAllocationByLotsChanged,
					|	AllocationRules.AllocationDirectionSettingsChanged,
					|	AllocationRules.AllocateByLots AS AllocateByLots,
					|	AllocationRules.AllocateToExpenseItems AS AllocateToExpenseItems,
					|	AllocationRules.BaseOfAllocationByBusinessUnits AS BaseOfAllocationByBusinessUnits,
					|	AllocationRules.LotsAreSpecifiedInDocument AS LotsAreSpecifiedManually,
					|	AllocationRules.CostShareForProduction AS CostShareForProduction,
					|	AllocationRules.CostShareToExpenseItems AS CostShareToExpenseItems,
					|	AllocationRules.Factor AS Factor,
					|	AllocationRules.AllocateToBusinessUnits AS AllocateToBusinessUnits,
					|	AllocationRules.BusinessUnitsAreSpecifiedManually AS BusinessUnitsAreSpecifiedManually,
					|	AllocationRules.SettingsOfBaseOfAllocationByLots,
					|	AllocationRules.AllocationDirectionSettings,
					|	AllocationRules.FilterByBusinessUnits.(
					|		Department AS Department
					|	) AS FilterByBusinessUnits,
					|	AllocationRules.FilterByMaterials.(
					|		Material AS Material
					|	) AS FilterByMaterials,
					|	AllocationRules.FilterByActivityKind.(
					|		WorkKind AS WorkKind
					|	) AS FilterByActivityKind,
					|	AllocationRules.FilterByProductsGroups.(
					|		ProductsGroup AS ProductsGroup
					|	) AS FilterByProductsGroups,
					|	AllocationRules.FilterByProducts.(
					|		ManufacturedProduct AS ManufacturedProduct
					|	) AS FilterByProducts,
					|	AllocationRules.Departments.(
					|		Ref AS Ref,
					|		LineNumber AS LineNumber,
					|		Department AS Department,
					|		CostShare AS CostShare
					|	) AS ByInfobase,
					|	AllocationRules.WriteOff.(
					|		Ref AS Ref,
					|		LineNumber AS LineNumber,
					|		ExpenseItem AS ExpenseItem,
					|		DimensionOfExpenses AS DimensionOfExpenses,
					|		CostShare AS CostShare,
					|		AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
					|		GLAccountSettings AS GLAccountSettings,
					|		LineOfBusiness AS LineOfBusiness,
					|		RowID AS RowID,
					|		Department AS Department
					|	) AS WriteOff
					|FROM
					|	Catalog.CostAllocationRules AS AllocationRules
					|WHERE
					|	AllocationRules.Ref = &Ref";
			Else
				
				QueryText = 
					// Selection of directions of activity with verification for the period of activity.
					"SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness
					|FROM
					|	Document.AllocationOfOtherCosts.FilterByLinesOfBusiness AS T
					|		INNER JOIN Catalog.LinesOfBusiness AS LB
					|		ON T.LineOfBusiness = LB.Ref
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND (LB.StartDateOfActivity <= &EndOfPeriod OR LB.StartDateOfActivity = DATETIME(1,1,1))
					|	AND (LB.EndDateOfActivity >= &BeginOfPeriod OR LB.EndDateOfActivity = DATETIME(1,1,1))
					|
					|UNION ALL
					|
					|SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness
					|FROM
					|	Document.AllocationOfOtherCosts.FilterByLinesOfBusiness AS T
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND T.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
					|
					|;
					|
					// Directions of activity with verification for the period of activity.
					|SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness,
					|	T.CostShare AS CostShare
					|FROM
					|	Document.AllocationOfOtherCosts.LinesOfBusiness AS T
					|		INNER JOIN Catalog.LinesOfBusiness AS LB
					|		ON T.LineOfBusiness = LB.Ref
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND (LB.StartDateOfActivity <= &EndOfPeriod OR LB.StartDateOfActivity = DATETIME(1,1,1))
					|	AND (LB.EndDateOfActivity >= &BeginOfPeriod OR LB.EndDateOfActivity = DATETIME(1,1,1))
					|
					|UNION ALL
					|
					|SELECT
					|	T.Ref AS Ref,
					|	T.LineNumber AS LineNumber,
					|	T.LineOfBusiness AS LineOfBusiness,
					|	T.CostShare AS CostShare
					|FROM
					|	Document.AllocationOfOtherCosts.LinesOfBusiness AS T
					|
					|WHERE
					|	T.Ref = &Ref
					|	AND T.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
					|;
					|
					|SELECT
					|	AllocationRules.AssignAllocationSetting AS AssignAllocationSetting,
					|	AllocationRules.AllocateByLots AS AllocateByLots,
					|	AllocationRules.AllocateToExpenseItems AS AllocateToExpenseItems,
					|	AllocationRules.BaseOfAllocationByLots AS BaseOfAllocationByLots,
					|	AllocationRules.BaseOfAllocationByBusinessUnits AS BaseOfAllocationByBusinessUnits,
					|	AllocationRules.SettingsOfBaseOfAllocationByLotsChanged,
					|	AllocationRules.AllocationDirectionSettingsChanged,
					|	AllocationRules.ProductCostElement AS ProductCostElement,
					|	AllocationRules.AllocationDirection AS AllocationDirection,
					|	AllocationRules.LotsAreSpecifiedManually AS LotsAreSpecifiedManually,
					|	AllocationRules.CostShareForProduction AS CostShareForProduction,
					|	AllocationRules.CostShareToExpenseItems AS CostShareToExpenseItems,
					|	AllocationRules.Factor AS Factor,
					|	AllocationRules.AllocateToBusinessUnits AS AllocateToBusinessUnits,
					|	AllocationRules.BusinessUnitsAreSpecifiedManually AS BusinessUnitsAreSpecifiedManually,
					|	AllocationRules.SettingsOfBaseOfAllocationByLotsChanged,
					|	AllocationRules.SettingsOfBaseOfAllocationByLots,
					|	AllocationRules.SettingsOfBaseOfAllocationByLots,
					|	AllocationRules.AllocationDirectionSettings,
					|	AllocationRules.DataSource,
					|	AllocationRules.FilterByBusinessUnits.(
					|		Department AS Department
					|	) AS FilterByBusinessUnits,
					|	AllocationRules.FilterByMaterials.(
					|		Material AS Material
					|	) AS FilterByMaterials,
					|	AllocationRules.FilterByActivityKind.(
					|		WorkKind AS WorkKind
					|	) AS FilterByActivityKind,
					|	AllocationRules.FilterByProductsGroups.(
					|		ProductsGroup AS ProductsGroup
					|	) AS FilterByProductsGroups,
					|	AllocationRules.FilterByProducts.(
					|		ManufacturedProduct AS ManufacturedProduct
					|	) AS FilterByProducts,
					|	AllocationRules.WriteOff.(
					|		Ref AS Ref,
					|		LineNumber AS LineNumber,
					|		ExpenseItem AS ExpenseItem,
					|		DimensionOfExpenses AS DimensionOfExpenses,
					|		CostShare AS CostShare,
					|		AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
					|		GLAccountSettings AS GLAccountSettings,
					|		LineOfBusiness AS LineOfBusiness,
					|		RowID AS RowID,
					|		Department AS Department
					|	) AS WriteOff,
					|	AllocationRules.ByInfobase.(
					|		Ref AS Ref,
					|		LineNumber AS LineNumber,
					|		Department AS Department,
					|		ProductCostElement AS ProductCostElement,
					|		CostShare AS CostShare
					|	) AS ByInfobase
					|FROM
					|	Document.AllocationOfOtherCosts AS AllocationRules
					|WHERE
					|	AllocationRules.Ref = &Ref";
				
			EndIf;
			Query = New Query;
			Query.Text = QueryText;
			
			Query.SetParameter("Ref", FillingData[KeyDistributionRules]);
			Query.SetParameter("BeginOfPeriod", BegOfMonth(FillingData.Date));
			Query.SetParameter("EndOfPeriod", EndOfMonth(FillingData.Date));

			Result = Query.ExecuteBatch();
			Selection = Result[2].Select();
			
			While Selection.Next() Do
				
				FillPropertyValues(ThisObject, Selection, , 
					"FilterByMaterials, FilterByBusinessUnits, FilterByActivityKind, FilterByProductsGroups, FilterByProducts,
					|WriteOff, ByInfobase"
					);
				
				SamplingSettingsOfDistributionBaseByBatch = 
					Selection.SettingsOfBaseOfAllocationByLots; // ValueStorage
				
				SelectionOfDistributionDirectionSetting = 
					Selection.AllocationDirectionSettings; // ValueStorage
					
				
				SettingsOfBaseOfAllocationByLots = New ValueStorage(
					SamplingSettingsOfDistributionBaseByBatch.Get());
				AllocationDirectionSettings = New ValueStorage(
					SelectionOfDistributionDirectionSetting.Get());
				FillingData.Insert("SettingsOfBaseOfAllocationByLots",
					SamplingSettingsOfDistributionBaseByBatch.Get());
				FillingData.Insert("AllocationDirectionSettings",
					SelectionOfDistributionDirectionSetting.Get());
				WriteOff.Load(Selection.WriteOff.Unload());
				ByInfobase.Load(Selection.ByInfobase.Unload());
				For Each DatabaseString In ByInfobase Do
					DatabaseString.ProductCostElement = ProductCostElement;
				EndDo;
				SettingsOfBaseOfAllocationByLots = New ValueStorage(
					SamplingSettingsOfDistributionBaseByBatch.Get());
				FillingData.Insert("SettingsOfBaseOfAllocationByLots",
					SamplingSettingsOfDistributionBaseByBatch.Get());
				
				FilterByLinesOfBusiness.Load(Result[0].Unload());
				LinesOfBusiness.Load(Result[1].Unload())
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(AssignAllocationSetting) Then
		
		AssignmentsByOption = New Map;
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToLinesOfBusiness,
			Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult);
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly,
			Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation);
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToDeferredExpenses,
			Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult);
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToInventoryCost,
			Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts);
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToProductionCosts,
			Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots);
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToCostCenters,
			Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter);
		AssignmentsByOption.Insert(Enums.CostAllocationOptions.ToProductionCostDirect,
			Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost);
		ArticleDistributionOptions = Common.ObjectAttributesValues(ExpenseItem,
			"CostAllocationOptionManag,CostAllocationOptionLocal
			|");
		
		OptionsForDistributionOfCostCenter = Undefined;
		If ThisIsDistributionFromHIA Then
			OptionsForDistributionOfCostCenter = Common.ObjectAttributesValues(DimensionOfExpenses,
				"CostAllocationOptionManag,CostAllocationOptionLocal
				|");
		EndIf;
		
		If ManagementAccounting Then
			If ArticleDistributionOptions.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostCenters
			 Or Not ValueIsFilled(ArticleDistributionOptions.CostAllocationOptionManag) And ThisIsDistributionFromHIA Then
				AssignAllocationSetting = AssignmentsByOption.Get(OptionsForDistributionOfCostCenter.CostAllocationOptionManag);
			Else
				AssignAllocationSetting = AssignmentsByOption.Get(ArticleDistributionOptions.CostAllocationOptionManag);
			EndIf;
		ElsIf LocalAccounting Then
			If ArticleDistributionOptions.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostCenters
			 Or Not ValueIsFilled(ArticleDistributionOptions.CostAllocationOptionLocal) And ThisIsDistributionFromHIA Then
				AssignAllocationSetting = AssignmentsByOption.Get(OptionsForDistributionOfCostCenter.CostAllocationOptionLocal);
			Else
				AssignAllocationSetting = AssignmentsByOption.Get(ArticleDistributionOptions.CostAllocationOptionLocal);
			EndIf;
		ElsIf AIT Then
			AssignAllocationSetting = AssignmentsByOption.Get(FillingData.NDTDistributionOption);
		EndIf;
			
	EndIf;
	
	If AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
		
		If ValueIsFilled(LineOfBusiness) Or TypeOf(DimensionOfExpenses) = Type("CatalogRef.LinesOfBusiness")
			And ValueIsFilled(DimensionOfExpenses) Or Not GetFunctionalOption("GenerateFinancialResult") Then
			AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit;
		EndIf;
		
		If DataSource.IsEmpty() Then
			DataSource = Enums.DataSourcesForExpenseAllocation.RevenueAndCOGS;
		EndIf;

		
	ElsIf AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation Then 
		
		AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit;
		
	ElsIf AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter
		And ThisIsDistributionForHIA And ValueIsFilled(DimensionOfExpenses) Then
		DistributionIndicators = Common.ObjectAttributesValues(DimensionOfExpenses, 
			"CostAllocationRuleManag, CostAllocationRuleLocal
			|");
		AllocateToCostCenter = True;
		If ManagementAccounting Then
			Factor = DistributionIndicators.CostAllocationRuleManag;
		ElsIf LocalAccounting Then
			Factor = DistributionIndicators.CostAllocationRuleLocal;
		ElsIf AIT Then
			Factor = FillingData.RuleOfDistributionOfPersonalIncomeTax;
		EndIf;
	ElsIf AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost Then
		BaseOfAllocationByLots = Common.ObjectAttributesValues(ExpenseItem, 
			"BaseOfAllocationByLots").BaseOfAllocationByLots;
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
	AllocationOfOtherCostsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	IncomeAndExpensesServer.Filling(ThisObject, 
		Documents.AllocationOfOtherCosts.ItemsAndDimensionsSelectionParameters());
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	ThisObject.AdditionalProperties.DocumentsPosting.Insert("NotUseBalanceSheetStatement");
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If Not AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult
		And Not AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation Then
		InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Date, Ref, Organization);
	EndIf;
	
	AllocationOfOtherCostsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Not ((AdditionalProperties.Property("CancelRecordingOfTaskForCalculatingCost")
				And AdditionalProperties.CancelRecordingOfTaskForCalculatingCost) Or
		AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult
		Or AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation) Then
		
		InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Date, Ref, Organization);
	EndIf;
	
	AllocationOfOtherCostsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	AllocationOfOtherCosts.Ref
		|FROM
		|	Document.AllocationOfOtherCosts AS AllocationOfOtherCosts
		|WHERE
		|	AllocationOfOtherCosts.Posted
		|	AND AllocationOfOtherCosts.Organization = &Organization
		|	AND AllocationOfOtherCosts.Department = &Department
		|	AND AllocationOfOtherCosts.LineOfBusiness = &LineOfBusiness
		|	AND AllocationOfOtherCosts.ExpenseItem = &ExpenseItem
		|	AND AllocationOfOtherCosts.DimensionOfExpenses = &DimensionOfExpenses
		|	AND AllocationOfOtherCosts.Date BETWEEN &PeriodBeginning AND &PeriodEnd
		|	AND NOT AllocationOfOtherCosts.Ref = &CurrentDocument
		|	AND (CASE
		|			WHEN &ManagementAccounting
		|				THEN AllocationOfOtherCosts.ManagementAccounting
		|			ELSE FALSE
		|		END 
		|		OR
		|		CASE
		|			WHEN &LocalAccounting
		|				THEN AllocationOfOtherCosts.LocalAccounting
		|			ELSE FALSE
		|		END
		|		OR
		|		CASE
		|			WHEN &AIT
		|				THEN AllocationOfOtherCosts.AIT
		|			ELSE FALSE
		|		END
		|)";
	
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("Department",		Department);
	Query.SetParameter("LineOfBusiness", LineOfBusiness);
	Query.SetParameter("PeriodBeginning",		BegOfMonth(Date));
	Query.SetParameter("PeriodEnd",	EndOfMonth(Date));
	Query.SetParameter("CurrentDocument",	Ref);
	Query.SetParameter("ExpenseItem",		ExpenseItem);
	Query.SetParameter("DimensionOfExpenses",	DimensionOfExpenses);
	Query.SetParameter("ManagementAccounting",	ManagementAccounting);
	Query.SetParameter("LocalAccounting",	LocalAccounting);
	Query.SetParameter("TaxAccounting",		TaxAccounting);
	Query.SetParameter("AIT",				AIT);
		
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		MessageText = NStr("vi = 'Trong kỳ chỉ ra đã có chứng từ tương ứng.
								   |Giao dịch chưa thực hiện.';
								   |ru = 'В указанном периоде уже существует аналогичный документ.
								   |Операция не выполнена.';
								   |en = 'Similar document already exists in the specified period.
								   |Operation failed.'; fa = 'Similar document already exists in the specified period.
								   |Operation failed.';
								   |it = 'Nel periodo indicato esiste già un documento analogo. 
								   |Operazione non eseguita.';
								   |pl = 'W podanym okresie już istnieje analogiczny dokument.
								   |Operacja nie powiodła się.';
								   |tr = 'Belirtilen dönemde benzer bir belge zaten mevcut.
								   |İşlem tamamlanmadı'");
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	If Not AllocateByLots And Not AllocateToBusinessUnits
		And Not AllocateToExpenseItems And Not LeaveAsWIP
		And AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Không một hướng phân bổ duy nhất của mục chi phí đã được chọn.';
					|ru = 'Не выбрано ни одно направление распределения статьи расходов.';
					|en = 'No direction of expense item allocation is selected.'; fa = 'No direction of expense item allocation is selected.';
					|it = 'Non è stata scelta nessuna direzione di ripartizione della voce di spesa.';
					|pl = 'Nie wybrano żadnego kierunku przydzielenia wydatków.';
					|tr = 'Gider kaleminin herhangi bir iş kolu seçilmedi.'"),
				,
				"AllocationDirection",
				,
				Cancel);
	EndIf;
		
	If AllocateToExpenseItems And WriteOff.Count() = 0 Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không có dòng nào được nhập vào danh sách ""Dạng khác""';
				|ru = 'Не введено ни одной строки в список ""Другие статьи""';
				|en = 'No lines entered into the Other items list'; fa = 'No lines entered into the Other items list';
				|it = 'Non è stata inserita nessuna riga nell''elenco ""Altre voci""';
				|pl = 'Nie wprowadzono żadnego wiersza do listy ""Inne pozycje""';
				|tr = '""Diğer Kalemler"" listesine herhangi bir satır girilmedi'"),
			,
			"WriteOff",
			,
			Cancel);
	EndIf;
	
	If Not AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost
		And (Not AllocateByLots 
			Or LotsAreSpecifiedManually Or BusinessUnitsAreSpecifiedManually) Then
		NotCheckedAttributeArray.Add("ProductCostElement");
	EndIf;
	
	If LotsAreSpecifiedManually 
		And ProductionLots.Count() = 0
		And ProductionIssueWithoutReferences.Count() = 0
		And Manually.Count() = 0 Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không quy định lô.';
				|ru = 'Не указаны партии.';
				|en = 'Lots are not specified.'; fa = 'Lots are not specified.';
				|it = 'Non sono stati indicati i lotti.';
				|pl = 'Nie są określone partie.';
				|tr = 'Lot belirtilmedi.'"),,,,	Cancel);
			
	EndIf;
	
	If Not ((AllocateByLots Or AllocateDirectCostOnProductionLots) And (AllocateToExpenseItems Or LeaveAsWIP)
		And Not (LotsAreSpecifiedManually Or BusinessUnitsAreSpecifiedManually)) Then
		NotCheckedAttributeArray.Add("CostShareForProduction");
	EndIf;
	
	If Not AllocateToBusinessUnits Or 
		(AllocateToBusinessUnits And BusinessUnitsAreSpecifiedManually) Then
		NotCheckedAttributeArray.Add("BaseOfAllocationByBusinessUnits");
	EndIf;
	
	If Not AllocateToExpenseItems Then
		NotCheckedAttributeArray.Add("WriteOff");
	EndIf;
	
	If Not BusinessUnitsAreSpecifiedManually Then
		NotCheckedAttributeArray.Add("ByInfobase");
	EndIf;
	
	If Not (AllocateToBusinessUnits Or AllocateToCostCenter) Then
		NotCheckedAttributeArray.Add("Factor");
	ElsIf AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots
		And Not (BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis
		Or BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand) Then
		NotCheckedAttributeArray.Add("Factor");
	EndIf;
	
	If AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots
		And (Not AllocateByLots Or LotsAreSpecifiedManually) Then
		NotCheckedAttributeArray.Add("BaseOfAllocationByLots");
	EndIf;
	
	If AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult
		And (AllocationDirection = Enums.AllocationDirectionByBusinessUnits.ByRates
			Or AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit)
		Or AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation Then
		NotCheckedAttributeArray.Add("BaseOfAllocationByLots");
	EndIf;
	
	If Not LeaveAsWIP Then
		NotCheckedAttributeArray.Add("CostShareOfWIP");
	EndIf;
	
	If BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts 
		And Not CalculationOfCostCached.BatchAccountingVersion22(Date) Then		
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cơ sở phân bổ ''''Chi phí nguyên vật liệu và chi phí nhân công'''' chỉ có sẵn cho kế toán theo lô 2.2.';
				|ru = 'База распределение ""Сумма материальных и трудозатрат"" доступна только для партионного учета 2.2.';
				|en = 'The ""Amount of material and labor costs"" allocation base is available only for lot accounting 2.2.'; fa = 'The ""Amount of material and labor costs"" allocation base is available only for lot accounting 2.2.';
				|it = 'Base di ripartizione ""Importo di spese materiali e di produzione"" è disponibile solo per la contabilità per lotti 2.2.';
				|pl = 'Baza przydziału ""Wartość nakładów materiałowych i nakładów pracy"" jest dostępna tylko dla ewidencji partii 2.2';
				|tr = '""Malzeme ve iş gücü maliyetlerinin tutarı"" dağıtım temeli sadece lot muhasebesi 2.2 için mevcuttur.'"),
			TMCommonUse.DataKeyForMessageToUser(Ref),
			"TheRuleOfDistributionByStages",
			"Object",
			Cancel);
			
	EndIf;
	
	ListOfAccountsToBeChecked = New ValueList;
	ListOfAccountsToBeChecked.Add("ManagementAccounting", NStr("vi = 'quản trị';
																|ru = 'управленческий';
																|en = 'management'; fa = 'management';
																|it = 'управленческий';
																|pl = 'management';
																|tr = 'yönetim'"));
	ListOfAccountsToBeChecked.Add("LocalAccounting", NStr("vi = 'quy định';
															|ru = 'регламентированный';
															|en = 'local'; fa = 'local';
															|it = 'регламентированный';
															|pl = 'local';
															|tr = 'yerel'"));
	
	
	If CalculationOfCostLocalization.GetFunctionalOptionAITAccounting() Then
		ListOfAccountsToBeChecked.Add("AIT", NStr("vi = 'Thuế thu nhập bổ sung';
													|ru = 'налог на дополнительный доход';
													|en = 'additional income tax'; fa = 'additional income tax';
													|it = 'налог на дополнительный доход';
													|pl = 'additional income tax';
													|tr = 'ek gelir vergisi'"));
	EndIf;
	
	AccountingIsCompleted = False;
	ArrayOfStringPresentations = New Array;
	For Each ListItem In ListOfAccountsToBeChecked Do
		AccountingIsCompleted = AccountingIsCompleted Or ThisObject[ListItem.Value];
		ArrayOfStringPresentations.Add(ListItem.Presentation);
	EndDo;
	
	If Not AccountingIsCompleted Then
		
		ErrorText = NStr("vi = 'Hãy chỉ ra trong các dạng kế toán nào cần phản ánh chứng từ (%1).';
						|ru = 'Укажите в каких видах учета должен отражаться документ (%1).';
						|en = 'Specify accounting kinds to record the document (%1).'; fa = 'Specify accounting kinds to record the document (%1).';
						|it = 'Укажите в каких видах учета должен отражаться документ (%1).';
						|pl = 'Specify accounting kinds to record the document (%1).';
						|tr = 'Belgenin hangi kayıt türlerine yansıtılması gerektiğini belirtin (%1).'");
		ErrorText = StrTemplate(ErrorText, StrConcat(ArrayOfStringPresentations, ", "));
		CommonClientServer.MessageToUser(ErrorText, TMCommonUse.DataKeyForMessageToUser(Ref),
			"ManagementAccounting", "Object", Cancel);
			
	EndIf;

	If AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter Then
		NotCheckedAttributeArray.Add("BaseOfAllocationByLots");
		NotCheckedAttributeArray.Add("BaseOfAllocationByBusinessUnits");
	EndIf;
	
	If AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
		
		If AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Specified
			And FilterByLinesOfBusiness.Count() = 0 Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa chỉ định lĩnh vực kinh doanh khi lọc.';
					|ru = 'Не заданы направления деятельности в отборе.';
					|en = 'Lines of business are not set up in the filter.'; fa = 'Lines of business are not set up in the filter.';
					|it = 'Non sono impostati i settoti di attività nella selezione.';
					|pl = 'Nie są określone kierunki działalności w wyborze.';
					|tr = 'Filtrede iş kolu belirtilmedi.'"),
				,
				"AllocationDirection",
				,
				Cancel);
				
		EndIf;
		
		If AllocationDirection = Enums.AllocationDirectionByBusinessUnits.ByRates
			And LinesOfBusiness.Count() = 0 Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""Lĩnh vực kinh doanh""';
					|ru = 'Не введено ни одной строки в список ""Направления деятельности""';
					|en = 'No lines are added into the ""Lines of business"" list'; fa = 'No lines are added into the ""Lines of business"" list';
					|it = 'Non è inserita alcuna riga nell''elenco ""Settori di attività""';
					|pl = 'Nie wprowadzono pojedynczego wierszu na liście „Kierunki działalności”';
					|tr = '""İş Kolu"" listesine herhangi bir satır girilmedi'"),
				,
				"LinesOfBusiness",
				,
				Cancel);
		EndIf;
		
		If ValueIsFilled(AllocationDirection) Then
			NotCheckedAttributeArray.Add("BaseOfAllocationByLots");
		EndIf;
		
	ElsIf AssignAllocationSetting = Enums.AssignmentOfCostAllocationRules.WithoutExpenseAllocation Then
		
		NotCheckedAttributeArray.Add("BaseOfAllocationByLots");
		
	Else
		
		NotCheckedAttributeArray.Add("DataSource");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	AllocationOfOtherCostsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, 
		Documents.AllocationOfOtherCosts.ItemsAndDimensionsSelectionParameters());

EndProcedure

#EndRegion

#EndIf
