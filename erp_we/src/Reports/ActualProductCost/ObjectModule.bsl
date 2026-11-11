
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
			
		FiltersStructure = New Structure("Recorder", Parameters.CommandParameter);
		ThisForm.ParametersForm.Filter = FiltersStructure;
		
	EndIf;
	
EndProcedure


Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportParametersByReportVariant(VariantKey, NewDCSettings, NewDCUserSettings);
		ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TempTableManager = New TempTablesManager;
	
	FilterAvailableFields = New Array;
	AvailableConditionFields = New Array;
	
	NodulationScheme = Reports.ProductsCostTree.GetTemplate("MainDataCompositionSchema");
	NodalSettings = NodulationScheme.DefaultSettings;
	ReportSettings = SettingsComposer.GetSettings();
	
	DeLinkingDataSet = NodulationScheme.DataSets.Find("IssuedProducts");
	If DeLinkingDataSet = Undefined Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Mô hình tìm kiếm sản phẩm đã thay đổi. Thăm dò là không thể.';
				|ru = 'Изменилась схема разузлования продукции. Разузлование невозможно.';
				|en = 'Product explosion scheme is changed. Cannot explode.'; fa = 'Product explosion scheme is changed. Cannot explode.';
				|it = 'È cambiato lo schema della logica di produzione.';
				|pl = 'Został zmieniony schemat rozdzielenia produkcji. Rozdzielenie jest niemożliwe.';
				|tr = 'Ürünlerin ayrıştırılma şeması değiştirildi. Ayrıştırma mümkün değildir.'"));
		Return;
		
	EndIf;	
	
	PeriodParameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Period"));
	Period = PeriodParameter.Value; // StandardPeriod
	BeginOfPeriod = ?(PeriodParameter.Use, Period.StartDate, BegOfYear(CurrentSessionDate()));
	EndOfPeriod = ?(PeriodParameter.Use, Period.EndDate, CurrentSessionDate());
	
	Cost_Data = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data")).Value;
	DataCompositionClientServer.SetParameter(NodalSettings, "Cost_Data", Cost_Data);
	
	If PeriodParameter.Use Then
		DataCompositionClientServer.SetParameter(NodalSettings, "Period", Period);
	EndIf;
	
	For Each TheAvailableFieldSelection In ReportSettings.Filter.FilterAvailableFields.Items Do
		FilterAvailableFields.Add(TheAvailableFieldSelection.Field);
	EndDo;
	
	For Each DataField In DeLinkingDataSet.Fields Do
		
		If DataField.UseRestriction.Condition Then
			Continue;
		EndIf;
		
		AvailableConditionFields.Add(New DataCompositionField(DataField.Field));
		
	EndDo;
	
	Invoices = Undefined;
		For Each ParameterElement_ In ReportSettings.DataParameters.Items Do
		If ParameterElement_.Parameter = New DataCompositionParameter("Recorder")
			And ParameterElement_.Use Then
			
			Invoices = ParameterElement_.Value;
		EndIf;
	EndDo;
	
	If Not Invoices = Undefined Then
		
		LoggerParameter = NodulationScheme.Parameters.Find("Recorders");
		If Not LoggerParameter = Undefined Then
			LoggerParameter.Value = Invoices;
		EndIf;
				
	EndIf;
		
	NodalSettings.Filter.Items.Clear();
	FillInReportSettingsRecursively(NodalSettings.Filter, ReportSettings.Filter, AvailableConditionFields);
	
	CostTreeParameters = CostStructure.CostTreeParameters();
	CostTreeParameters.DynamicReading = False;
	CostTreeParameters.ResultTypeTempTableManager = True;
	CostTreeParameters.TempTablesManager = TempTableManager;
	CostTreeParameters.InteractiveSetup = True;
	CostTreeParameters.DCSchema = NodulationScheme;
	CostTreeParameters.DCSettings = NodalSettings;
	CostTreeParameters.ReportParameters.Cost_Data = Cost_Data;
	CostTreeParameters.ReportParameters.DeployAdditionalCosts = True;
	CostTreeParameters.ReportParameters.EndDate = EndOfPeriod;
	
	CostStructure.BuildCostTree(CostTreeParameters);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	Query.SetParameter("Invoices", Invoices);
	Query.SetParameter("Cost_Data", Cost_Data);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("EndDate", EndOfPeriod);
	
	SelectionByOrganizationHasBeenEstablished = TMReportFunctionsClientServer.GetSelectionValue(
		SettingsComposer, "Organization", , True) <> Undefined;
	
	#Region QueryText
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query.TempTablesManager,
		"TTInterconnectedCompanies") Then
			
		Catalogs.Companies.GetRelatedCompanies(Query.TempTablesManager);
	EndIf;
	
	QueriesTexts = New Array();
	QueryText =
		"SELECT
		|	ItemsLocationAttributes.Products AS ManufacturedProduct,
		|	ItemsLocationAttributes.Characteristic AS ItemVariant,
		|	ItemsLocationAttributes.Purpose AS Purpose,
		|	Result.ProductsBatch AS ProductsBatch,
		|	Result.ProductBatchAccountingDimension AS ProductBatchAccountingDimension,
		|	Result.BatchCost AS SemiFinishedProductLot,
		|	Result.Products AS SemiFinishedProduct,
		|	Result.Characteristic AS ItemVariantsOfIntermediateProduct,
		|	CASE
		|		WHEN Result.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThisIsOutput_,
		|	SUM(Result.Count) AS Count,
		|	Result.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	Result.Organization AS Organization,
		|	Result.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	ItemsLocationAttributes.Series AS Series,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.Sum
		|		END) AS Sum,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.Material_
		|		END) AS Material_,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|			 OR Result.ItIsRequiredToUnpackAdditionalExpenseAmount
		|				THEN 0
		|			ELSE Result.AddExpensesForGoods
		|		END) AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.LaborCosts
		|		END) AS LaborCosts,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.ItemizedFixed
		|		END) AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.ItemizedVariable
		|		END) AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.OffBalanceSheetAmount
		|		END) AS OffBalanceSheet,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.TaxAccounting
		|		END) AS TaxAccounting,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.PermanentDifference
		|		END) AS PermanentDifference,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.CostTD
		|		END) AS CostTD,
		|	SUM(CASE
		|			WHEN Result.ExplosionIsRequired
		|				THEN 0
		|			ELSE Result.AIT
		|		END) AS AIT
		|INTO ReleasedQuantity
		|FROM
		|	Result AS Result
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ItemsLocationAttributes
		|		ON Result.ProductsAccountingDimension = ItemsLocationAttributes.Ref
		|WHERE
		|	Result.ExplosionIsRequired
		|	OR Result.ItIsRequiredToUnpackAdditionalExpenseAmount AND Result.AddExpensesForGoods <> 0
		|	OR Result.LineKind IN (
		|		VALUE(Enum.KindsOfCostTreeRows.ProductsBatch),
		|		VALUE(Enum.KindsOfCostTreeRows.SemiFinishedProductLot))
		|
		|GROUP BY
		|	Result.Products,
		|	Result.Characteristic,
		|	ItemsLocationAttributes.Products,
		|	ItemsLocationAttributes.Characteristic,
		|	CASE
		|		WHEN Result.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch)
		|			THEN TRUE
		|		ELSE FALSE
		|	END,
		|	Result.ProductsAccountingDimension,
		|	ItemsLocationAttributes.Purpose,
		|	Result.BatchCost,
		|	Result.ProductsBatch,
		|	Result.ProductBatchAccountingDimension,
		|	Result.Organization,
		|	Result.Organization.LocalAccountingCurrency,
		|	ItemsLocationAttributes.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReleasedQuantity.ManufacturedProduct AS ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant AS ItemVariant,
		|	ReleasedQuantity.Purpose AS Purpose,
		|	ReleasedQuantity.ProductsBatch AS ProductsBatch,
		|	ReleasedQuantity.ProductBatchAccountingDimension AS ProductBatchAccountingDimension,
		|	SUM(ReleasedQuantity.Count) AS Count,
		|	ReleasedQuantity.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	ReleasedQuantity.Organization AS Organization,
		|	ReleasedQuantity.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	ReleasedQuantity.Series AS Series,
		|	SUM(ReleasedQuantity.Sum) AS Sum,
		|	SUM(ReleasedQuantity.Material_) AS Material_,
		|	SUM(ReleasedQuantity.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(ReleasedQuantity.LaborCosts) AS LaborCosts,
		|	SUM(ReleasedQuantity.ItemizedFixed) AS ItemizedFixed,
		|	SUM(ReleasedQuantity.ItemizedVariable) AS ItemizedVariable,
		|	SUM(ReleasedQuantity.OffBalanceSheet) AS OffBalanceSheet,
		|	SUM(ReleasedQuantity.TaxAccounting) AS TaxAccounting,
		|	SUM(ReleasedQuantity.PermanentDifference) AS PermanentDifference,
		|	SUM(ReleasedQuantity.CostTD) AS CostTD,
		|	SUM(ReleasedQuantity.AIT) AS AIT
		|INTO TTManufacturedProduct
		|FROM
		|	ReleasedQuantity AS ReleasedQuantity
		|WHERE
		|	ReleasedQuantity.ThisIsOutput_
		|
		|GROUP BY
		|	ReleasedQuantity.ManufacturedProduct,
		|	ReleasedQuantity.ProductsAccountingDimension,
		|	ReleasedQuantity.Purpose,
		|	ReleasedQuantity.ProductsBatch,
		|	ReleasedQuantity.ProductBatchAccountingDimension,
		|	ReleasedQuantity.ItemVariant,
		|	ReleasedQuantity.Organization,
		|	ReleasedQuantity.LocalAccountingCurrency,
		|	ReleasedQuantity.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|	NestedQuery.Count AS Count,
		|	NestedQuery.Sum AS Sum,
		|	NestedQuery.Material_ AS Material_,
		|	NestedQuery.AddExpensesForGoods AS AddExpensesForGoods,
		|	NestedQuery.LaborCosts AS LaborCosts,
		|	NestedQuery.ItemizedFixed AS ItemizedFixed,
		|	NestedQuery.ItemizedVariable AS ItemizedVariable,
		|	NestedQuery.OffBalanceSheet AS OffBalanceSheet,
		|	NestedQuery.TaxAccounting AS TaxAccounting,
		|	NestedQuery.PermanentDifference AS PermanentDifference,
		|	NestedQuery.CostTD AS CostTD,
		|	NestedQuery.AIT AS AIT,
		|	NestedQuery.Cost_ AS Cost_,
		|	NestedQuery.CostCharacteristic AS CostCharacteristic,
		|	NestedQuery.SemiFinishedProduct AS SemiFinishedProduct,
		|	NestedQuery.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	NestedQuery.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	NestedQuery.LineKind AS LineKind,
		|	NestedQuery.SemiFinishedProductLot AS SemiFinishedProductLot,
		|	NestedQuery.SemiFinishedProductBatchAccountingLotSVendorAttributes AS SemiFinishedProductBatchAccountingLotSVendorAttributes,
		|	NestedQuery.ProductsBatch AS ProductsBatch,
		|	NestedQuery.ProductBatchAccountingDimension AS ProductBatchAccountingDimension,
		|	NestedQuery.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	NestedQuery.UnitOfMeasure AS UnitOfMeasure,
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	NestedQuery.Department AS Department,
		|	NestedQuery.ProductCostElement AS ProductCostElement,
		|	NestedQuery.BatchCost AS BatchCost,
		|	NestedQuery.BatchAccountingDimensionCost AS BatchAccountingDimensionCost
		|
		|INTO Costs
		|FROM
		|	(SELECT
		|		Result.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|		SUM(Result.Count) AS Count,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				WHEN Result.ItIsRequiredToUnpackAdditionalExpenseAmount
		|					THEN Result.Sum - Result.AddExpensesForGoods
		|				ELSE Result.Sum
		|			END) AS Sum,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.Material_
		|			END) AS Material_,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|				 OR Result.ItIsRequiredToUnpackAdditionalExpenseAmount
		|					THEN 0
		|				ELSE Result.AddExpensesForGoods
		|			END) AS AddExpensesForGoods,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.LaborCosts
		|			END) AS LaborCosts,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.ItemizedFixed
		|			END) AS ItemizedFixed,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.ItemizedVariable
		|			END) AS ItemizedVariable,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.OffBalanceSheetAmount
		|			END) AS OffBalanceSheet,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.TaxAccounting
		|			END) AS TaxAccounting,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.PermanentDifference
		|			END) AS PermanentDifference,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.CostTD
		|			END) AS CostTD,
		|		SUM(CASE
		|				WHEN Result.ExplosionIsRequired
		|					THEN 0
		|				ELSE Result.AIT
		|			END) AS AIT,
		|		Result.Products AS Cost_,
		|		Result.Characteristic AS CostCharacteristic,
		|		SemiFinishedProductAccountingAnalytics.Products AS SemiFinishedProduct,
		|		SemiFinishedProductAccountingAnalytics.Characteristic AS ItemVariantsOfIntermediateProduct,
		|		Result.ProductsAccountingDimension AS ProductsAccountingDimension,
		|		Result.LineKind AS LineKind,
		|		Result.BatchFinishedProduct AS SemiFinishedProductLot,
		|		Result.BatchAccountingDimensionFinishedProduct AS SemiFinishedProductBatchAccountingLotSVendorAttributes,
		|		Result.ProductsBatch AS ProductsBatch,
		|		Result.ProductBatchAccountingDimension AS ProductBatchAccountingDimension,
		|		Result.ExplosionIsRequired AS ThisIsASemiFinishedProduct,
		|		CASE
		|			WHEN VALUETYPE(Result.Products) = TYPE(Catalog.Products)
		|				THEN CAST(Result.Products AS Catalog.Products).UnitOfMeasure
		|			WHEN VALUETYPE(Result.Products) = TYPE(Catalog.EmployeeWorkKinds)
		|				THEN CAST(Result.Products AS Catalog.EmployeeWorkKinds).UnitOfMeasure
		|			ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		END AS UnitOfMeasure,
		|		Result.Organization AS Organization,
		|		Result.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|		Result.Department AS Department,
		|		Result.ProductCostElement AS ProductCostElement,
		|		Result.BatchCost AS BatchCost,
		|		Result.BatchAccountingDimensionCost AS BatchAccountingDimensionCost
		|	FROM
		|		Result AS Result
		|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS SemiFinishedProductAccountingAnalytics
		|			ON Result.AccountingDimensionFinishedProduct = SemiFinishedProductAccountingAnalytics.Ref
		|	
		|	GROUP BY
		|		Result.Characteristic,
		|		SemiFinishedProductAccountingAnalytics.Products,
		|		Result.ProductsAccountingDimension,
		|		SemiFinishedProductAccountingAnalytics.Characteristic,
		|		Result.Department,
		|		Result.Organization,
		|		Result.Organization.LocalAccountingCurrency,
		|		Result.BatchFinishedProduct,
		|		Result.BatchAccountingDimensionFinishedProduct,
		|		Result.ProductCostElement,
		|		Result.Products,
		|		Result.AccountingDimensionFinishedProduct,
		|		Result.ExplosionIsRequired,
		|		CASE
		|			WHEN VALUETYPE(Result.Products) = TYPE(Catalog.Products)
		|				THEN CAST(Result.Products AS Catalog.Products).UnitOfMeasure
		|			WHEN VALUETYPE(Result.Products) = TYPE(Catalog.EmployeeWorkKinds)
		|				THEN CAST(Result.Products AS Catalog.EmployeeWorkKinds).UnitOfMeasure
		|			ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		END, // UnitOfMeasure
		|		Result.ProductsBatch,
		|		Result.ProductBatchAccountingDimension,
		|		Result.LineKind,
		|		Result.BatchCost,
		|		Result.BatchAccountingDimensionCost
		|	) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""1"" AS RequestSource,
		|	TTManufacturedProduct.ManufacturedProduct AS ManufacturedProduct,
		|	TTManufacturedProduct.ItemVariant AS ItemVariant,
		|	TTManufacturedProduct.Purpose AS Purpose,
		|	TTManufacturedProduct.ProductsBatch AS ProductsBatch,
		|	TTManufacturedProduct.Count AS QuantityRelease,
		|	TTManufacturedProduct.ManufacturedProduct AS SemiFinishedProduct,
		|	TTManufacturedProduct.ItemVariant AS ItemVariantsOfIntermediateProduct,
		|	Costs.Cost_ AS Cost_,
		|	Costs.CostCharacteristic AS CostCharacteristic,
		|	Costs.Sum AS Cost,
		|	Costs.Material_ AS Material_,
		|	Costs.AddExpensesForGoods AS AddExpensesForGoods,
		|	Costs.LaborCosts AS LaborCosts,
		|	Costs.ItemizedFixed AS ItemizedFixed,
		|	Costs.ItemizedVariable AS ItemizedVariable,
		|	Costs.OffBalanceSheet AS OffBalanceSheet,
		|	Costs.TaxAccounting AS TaxAccounting,
		|	Costs.PermanentDifference AS PermanentDifference,
		|	Costs.CostTD AS CostTD,
		|	Costs.AIT AS AIT,
		|
		|	Costs.Count AS Count,
		|	Costs.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	Costs.UnitOfMeasure AS CostUnitOfMeasure,
		|	TTManufacturedProduct.Organization AS Organization,
		|	Costs.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	Costs.Department AS Department,
		|	Costs.ProductCostElement AS ProductCostElement,
		|	TTManufacturedProduct.Series AS Series,
		|	TTManufacturedProduct.Sum AS AmountIssue,
		|	TTManufacturedProduct.Material_ AS MaterialMaterials,
		|	TTManufacturedProduct.AddExpensesForGoods AS AdditionalExpensesAmountOfIssue,
		|	TTManufacturedProduct.LaborCosts AS LaborCostsIssue,
		|	TTManufacturedProduct.ItemizedFixed AS ArticleByArticleStandingOrders,
		|	TTManufacturedProduct.ItemizedVariable AS ItemizedVariableRelease,
		|	TTManufacturedProduct.OffBalanceSheet AS OffBalanceSheetIssue,
		|	TTManufacturedProduct.TaxAccounting AS TaxAccountingIssue,
		|	TTManufacturedProduct.PermanentDifference AS CostPDDifferenceIsConstantIssue,
		|	TTManufacturedProduct.CostTD AS CostTDOfIssueIs,
		|	TTManufacturedProduct.AIT AS NDTIssue,
		|	Costs.BatchCost AS BatchCost
		|INTO CostsByType
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN Costs AS Costs
		|		ON TTManufacturedProduct.ProductsAccountingDimension = Costs.AccountingDimensionFinishedProduct
		|			AND (NOT Costs.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch))
		|			AND TTManufacturedProduct.ProductsBatch = Costs.ProductsBatch
		|			AND TTManufacturedProduct.ProductBatchAccountingDimension = Costs.ProductBatchAccountingDimension
		|			AND TTManufacturedProduct.ProductsBatch = Costs.SemiFinishedProductLot
		|			AND TTManufacturedProduct.ProductBatchAccountingDimension = Costs.SemiFinishedProductBatchAccountingLotSVendorAttributes
		|
		// Adding branches of the parent company, branches with the same parent company, and the parent company of the branch.
		|		LEFT JOIN TTInterconnectedCompanies AS TTInterconnectedCompanies
		|		ON TTManufacturedProduct.Organization = TTInterconnectedCompanies.Organization1
		|			AND Costs.Organization = TTInterconnectedCompanies.Organization2
		|WHERE
		|	(TTManufacturedProduct.Organization = Costs.Organization
		|		OR TTInterconnectedCompanies.Organization1 IS NOT NULL)
		|
		|UNION ALL
		|
		|SELECT
		|	""2"" AS RequestSource,
		|	ReleasedQuantity.ManufacturedProduct AS ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant AS ItemVariant,
		|	ReleasedQuantity.Purpose AS Purpose,
		|	ReleasedQuantity.ProductsBatch AS ProductsBatch,
		|	ReleasedQuantity.Count AS QuantityRelease,
		|	ReleasedQuantity.SemiFinishedProduct AS SemiFinishedProduct,
		|	ReleasedQuantity.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	Costs.Cost_ AS Cost_,
		|	Costs.CostCharacteristic AS CostCharacteristic,
		|	SUM(Costs.Sum) AS Cost,
		|	SUM(Costs.Material_) AS Material_,
		|	SUM(Costs.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(Costs.LaborCosts) AS LaborCosts,
		|	SUM(Costs.ItemizedFixed) AS ItemizedFixed,
		|	SUM(Costs.ItemizedVariable) AS ItemizedVariable,
		|	SUM(Costs.OffBalanceSheet) AS OffBalanceSheet,
		|	SUM(Costs.TaxAccounting) AS TaxAccounting,
		|	SUM(Costs.PermanentDifference) AS PermanentDifference,
		|	SUM(Costs.CostTD) AS CostTD,
		|	SUM(Costs.AIT),
		|
		|	SUM(Costs.Count) AS Count,
		|	Costs.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	Costs.UnitOfMeasure AS CostUnitOfMeasure,
		|	TTManufacturedProduct.Organization AS Organization,
		|	Costs.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	Costs.Department AS Department,
		|	Costs.ProductCostElement AS ProductCostElement,
		|	ReleasedQuantity.Series AS Series,
		|	0 AS AmountIssue,
		|	0 AS MaterialMaterials,
		|	0 AS AdditionalExpensesAmountOfIssue,
		|	0 AS LaborCostsIssue,
		|	0 AS ArticleByArticleStandingOrders,
		|	0 AS ItemizedVariableRelease,
		|	0 AS OffBalanceSheetIssue,
		|	0 AS TaxAccountingIssue,
		|	0 AS CostPDDifferenceIsConstantIssue,
		|	0 AS CostTDOfIssueIs,
		|	0 AS NDTIssue,
		|	Costs.BatchCost AS BatchCost
		|FROM
		|	ReleasedQuantity AS ReleasedQuantity
		|		INNER JOIN Costs AS Costs
		|		ON ReleasedQuantity.ProductsAccountingDimension = Costs.ProductsAccountingDimension
		|			AND ReleasedQuantity.SemiFinishedProduct = Costs.SemiFinishedProduct
		|			AND ReleasedQuantity.ItemVariantsOfIntermediateProduct = Costs.ItemVariantsOfIntermediateProduct
		|			AND ReleasedQuantity.SemiFinishedProductLot = Costs.SemiFinishedProductLot
		|			AND ReleasedQuantity.ProductsBatch = Costs.ProductsBatch
		|			AND ReleasedQuantity.ProductBatchAccountingDimension = Costs.ProductBatchAccountingDimension
		|			AND (Costs.ProductsBatch <> Costs.SemiFinishedProductLot
		|				OR Costs.ProductBatchAccountingDimension <> Costs.BatchAccountingDimensionCost)
		|
		|		INNER JOIN TTManufacturedProduct AS TTManufacturedProduct
		|		ON TTManufacturedProduct.ProductsBatch = ReleasedQuantity.ProductsBatch
		|			AND TTManufacturedProduct.ProductBatchAccountingDimension = ReleasedQuantity.ProductBatchAccountingDimension
		|			AND TTManufacturedProduct.ProductsAccountingDimension = ReleasedQuantity.ProductsAccountingDimension
		|
		// Adding branches of the parent company, branches with the same parent company, and the parent company of the branch.
		|		LEFT JOIN TTInterconnectedCompanies AS TTInterconnectedCompanies
		|		ON ReleasedQuantity.Organization = TTInterconnectedCompanies.Organization1
		|			AND Costs.Organization = TTInterconnectedCompanies.Organization2
		|WHERE
		|	NOT ReleasedQuantity.ThisIsOutput_
		|	AND (Costs.Organization = ReleasedQuantity.Organization
		|		OR TTInterconnectedCompanies.Organization1 IS NOT NULL)
		|
		|GROUP BY
		|	ReleasedQuantity.ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant,
		|	ReleasedQuantity.Purpose,
		|	ReleasedQuantity.Series,
		|	ReleasedQuantity.ProductsBatch,
		|	ReleasedQuantity.Count,
		|	ReleasedQuantity.SemiFinishedProduct,
		|	ReleasedQuantity.ItemVariantsOfIntermediateProduct,
		|	Costs.Cost_,
		|	Costs.CostCharacteristic,
		|	Costs.ThisIsASemiFinishedProduct,
		|	Costs.UnitOfMeasure,
		|	TTManufacturedProduct.Organization,
		|	Costs.LocalAccountingCurrency,
		|	Costs.Department,
		|	Costs.ProductCostElement,
		|	Costs.BatchCost
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InventoryCost.ItemsLocationAttributes.Products AS Products,
		|	InventoryCost.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	InventoryCost.ItemsLocationAttributes.Series AS Series,
		|	InventoryCost.Lot AS Lot,
		|	InventoryCost.Organization AS Organization,
		|	SUM(InventoryCost.Count) AS Count,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsIncludingVAT
		|				+ InventoryCost.ItemizedVariableCostsIncludingVAT
		|				+ InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|				+ InventoryCost.LaborCosts
		|				+ InventoryCost.ItemizedFixedCostsExcludingVAT
		|				+ InventoryCost.ItemizedVariableCostsExcludingVAT
		|				+ InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|				+ InventoryCost.LaborCostsMan
		|				+ InventoryCost.ItemizedFixedCostsManag
		|				+ InventoryCost.ItemizedVariableCostsManag
		|				+ InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|				+ InventoryCost.LaborCostsLocal
		|				+ InventoryCost.ItemizedFixedCostsCompl
		|				+ InventoryCost.ItemizedVariableCostsCompl
		|				+ InventoryCost.AddExpensesLocal
		|		END)												AS Cost,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.Cost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.CostExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.CostMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|		END)												AS Material_,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.AddExpensesForGoods
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.AdditionalExpensesExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.AddExpensesMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.AddExpensesLocal
		|		END)												AS AddExpensesForGoods,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.LaborCosts
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.LaborCostsMan
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LaborCostsLocal
		|		END)												AS LaborCosts,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedFixedCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedFixedCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedFixedCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedFixedCostsCompl
		|		END)												AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.ItemizedVariableCostsIncludingVAT
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.ItemizedVariableCostsExcludingVAT
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.ItemizedVariableCostsManag
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.ItemizedVariableCostsCompl
		|		END)												AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 2
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 3
		|				THEN InventoryCost.OffBalanceCost
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.OffBalanceCostLocal
		|		END)												AS OffBalanceSheet,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.LocalCost
		|					+ InventoryCost.AddExpensesLocal
		|					+ InventoryCost.LaborCostsLocal
		|					+ InventoryCost.ItemizedFixedCostsCompl
		|					+ InventoryCost.ItemizedVariableCostsCompl
		|					- InventoryCost.PermanentDifference
		|					- InventoryCost.CostTD
		|			ELSE 0
		|		END)												AS TaxAccounting,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.PermanentDifference
		|			ELSE 0
		|		END)												AS PermanentDifference,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostTD
		|			ELSE 0
		|		END)												AS CostTD,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN InventoryCost.CostOfPersonalIncomeTax
		|			ELSE 0
		|		END)												AS AIT
		|
		|INTO MaterialsProducts
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|WHERE
		|	InventoryCost.Recorder IN(&Invoices)
		|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND (InventoryCost.Period <= &EndDate OR &EndDate = DATETIME(1,1,1))
		|	AND InventoryCost.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners),
		|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller))
		|
		|GROUP BY
		|	InventoryCost.Lot,
		|	InventoryCost.ItemsLocationAttributes.Series,
		|	InventoryCost.ItemsLocationAttributes.Characteristic,
		|	InventoryCost.ItemsLocationAttributes.Products,
		|	InventoryCost.Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ActualData.ManufacturedProduct AS ManufacturedProduct,
		|	ActualData.ItemVariant AS ItemVariant,
		|	ActualData.Purpose AS AssignmentOfProducts,
		|	ActualData.ProductsBatch AS ProductsBatch,
		|	ActualData.SemiFinishedProduct AS SemiFinishedProduct,
		|	ActualData.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	ActualData.Cost_ AS Cost_,
		|	ActualData.CostCharacteristic AS CostCharacteristic,
		|	CASE
		|		WHEN ActualData.AmountIssue > 0
		|			THEN ActualData.AmountIssue
		|		ELSE ActualData.Cost
		|	END AS Cost,
		|	CASE
		|		WHEN ActualData.MaterialMaterials > 0
		|			THEN ActualData.MaterialMaterials
		|		ELSE ActualData.Material_
		|	END AS Material_,
		|	CASE
		|		WHEN ActualData.AdditionalExpensesAmountOfIssue > 0
		|			THEN ActualData.AdditionalExpensesAmountOfIssue
		|		ELSE ActualData.AddExpensesForGoods
		|	END AS AddExpensesForGoods,
		|	CASE
		|		WHEN ActualData.LaborCostsIssue > 0
		|			THEN ActualData.LaborCostsIssue
		|		ELSE ActualData.LaborCosts
		|	END AS LaborCosts,
		|	CASE
		|		WHEN ActualData.ArticleByArticleStandingOrders > 0
		|			THEN ActualData.ArticleByArticleStandingOrders
		|		ELSE ActualData.ItemizedFixed
		|	END AS ItemizedFixed,
		|	CASE
		|		WHEN ActualData.ItemizedVariableRelease > 0
		|			THEN ActualData.ItemizedVariableRelease
		|		ELSE ActualData.ItemizedVariable
		|	END AS ItemizedVariable,
		|	CASE
		|		WHEN ActualData.OffBalanceSheetIssue > 0
		|			THEN ActualData.OffBalanceSheetIssue
		|		ELSE ActualData.OffBalanceSheet
		|	END AS OffBalanceSheet_,
		|	CASE
		|		WHEN ActualData.TaxAccountingIssue > 0
		|			THEN ActualData.TaxAccountingIssue
		|		ELSE ActualData.TaxAccounting
		|	END AS TaxAccounting,
		|	CASE
		|		WHEN ActualData.CostPDDifferenceIsConstantIssue > 0
		|			THEN ActualData.CostPDDifferenceIsConstantIssue
		|		ELSE ActualData.PermanentDifference
		|	END AS PermanentDifference,
		|	CASE
		|		WHEN ActualData.CostTDOfIssueIs > 0
		|			THEN ActualData.CostTDOfIssueIs
		|		ELSE ActualData.CostTD
		|	END AS CostTD,
		|	CASE
		|		WHEN ActualData.NDTIssue > 0
		|			THEN ActualData.NDTIssue
		|		ELSE ActualData.AIT
		|	END AS AIT,
		|	ActualData.Count AS Count,
		|	ActualData.ManufacturedProduct.UnitOfMeasure AS ProductUnitOfMeasure,
		|	ActualData.SemiFinishedProduct.UnitOfMeasure AS UnitOfMeasurementOfSemiFinishedProduct,
		|	ActualData.CostUnitOfMeasure AS CostUnitOfMeasure,
		|	ActualData.Organization AS Organization,
		|	ActualData.ProductCostElement AS ProductCostElement,
		|	ActualData.Department AS Department,
		|	""ManufacturedProduct"" AS DataType,
		|	ActualData.Series AS Series,
		|	ActualData.BatchCost AS LotCosts,
		|	0 AS Level,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN ActualData.LocalAccountingCurrency
		|		ELSE
		|			&ManagementAccountingCurrency
		|	END AS Currency
		|FROM
		|	CostsByType AS ActualData
		|
		|UNION ALL
		|
		|SELECT
		|	NULL AS ManufacturedProduct,
		|	NULL AS ItemVariant,
		|	NULL AS AssignmentOfProducts,
		|	NULL AS ProductsBatch,
		|	NULL AS SemiFinishedProduct,
		|	NULL AS ItemVariantsOfIntermediateProduct,
		|	MaterialsProducts.Products AS Cost_,
		|	MaterialsProducts.Characteristic AS CostCharacteristic,
		|	SUM(MaterialsProducts.Cost) AS Cost,
		|	SUM(MaterialsProducts.Material_) AS Material_,
		|	SUM(MaterialsProducts.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(MaterialsProducts.LaborCosts) AS LaborCosts,
		|	SUM(MaterialsProducts.ItemizedFixed) AS ItemizedFixed,
		|	SUM(MaterialsProducts.ItemizedVariable) AS ItemizedVariable,
		|	SUM(MaterialsProducts.OffBalanceSheet) AS OffBalanceSheet_,
		|	SUM(MaterialsProducts.TaxAccounting) AS TaxAccounting,
		|	SUM(MaterialsProducts.PermanentDifference) AS PermanentDifference,
		|	SUM(MaterialsProducts.CostTD) AS CostTD,
		|	SUM(MaterialsProducts.AIT),
		|	SUM(MaterialsProducts.Count) AS Count,
		|	NULL AS ProductUnitOfMeasure,
		|	NULL AS UnitOfMeasurementOfSemiFinishedProduct,
		|	MaterialsProducts.Products.UnitOfMeasure AS CostUnitOfMeasure,
		|	MaterialsProducts.Organization AS Organization,
		|	NULL AS ProductCostElement,
		|	NULL AS Department,
		|	""UsedMaterials"" AS DataType,
		|	MaterialsProducts.Series AS Series,
		|	MaterialsProducts.Lot AS LotCosts,
		|	0 AS Level,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN MaterialsProducts.Organization.LocalAccountingCurrency
		|		ELSE
		|			&ManagementAccountingCurrency
		|	END AS Currency
		|FROM
		|	MaterialsProducts AS MaterialsProducts
		|		LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|		ON (InventoryCost.ItemsLocationAttributes.Products = MaterialsProducts.Products)
		|			AND (InventoryCost.ItemsLocationAttributes.Characteristic = MaterialsProducts.Characteristic)
		|			AND (InventoryCost.ItemsLocationAttributes.Series = MaterialsProducts.Series)
		|			AND (InventoryCost.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts), VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)))
		|			AND (InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt))
		|			AND (InventoryCost.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease), VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse), VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)))
		|			AND (NOT InventoryCost.Lot = UNDEFINED)
		|			AND (MaterialsProducts.Lot = UNDEFINED OR MaterialsProducts.Lot = InventoryCost.Lot)
		|WHERE
		|	InventoryCost.Recorder IS NULL
		|
		|GROUP BY
		|	MaterialsProducts.Products,
		|	MaterialsProducts.Characteristic,
		|	MaterialsProducts.Organization,
		|	MaterialsProducts.Series,
		|	MaterialsProducts.Products.UnitOfMeasure,
		|	MaterialsProducts.Lot,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN MaterialsProducts.Organization.LocalAccountingCurrency
		|		ELSE
		|			&ManagementAccountingCurrency
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	TTManufacturedProduct.ManufacturedProduct AS ManufacturedProduct,
		|	TTManufacturedProduct.ItemVariant AS ItemVariant,
		|	TTManufacturedProduct.Purpose AS AssignmentOfProducts,
		|	TTManufacturedProduct.ProductsBatch AS ProductsBatch,
		|	NULL AS SemiFinishedProduct,
		|	NULL AS ItemVariantsOfIntermediateProduct,
		|	Costs.Products AS Cost_,
		|	Costs.Characteristic AS CostCharacteristic,
		|	Costs.Sum AS Cost,
		|	Costs.Material_ AS Material_,
		|	Costs.AddExpensesForGoods AS AddExpensesForGoods,
		|	Costs.LaborCosts AS LaborCosts,
		|	Costs.ItemizedFixed AS ItemizedFixed,
		|	Costs.ItemizedVariable AS ItemizedVariable,
		|	Costs.OffBalanceSheetAmount AS OffBalanceSheet_,
		|	Costs.TaxAccounting AS TaxAccounting,
		|	Costs.PermanentDifference AS PermanentDifference,
		|	Costs.CostTD AS CostTD,
		|	Costs.AIT,
		|	Costs.Count AS Count,
		|	TTManufacturedProduct.ManufacturedProduct.UnitOfMeasure AS ProductUnitOfMeasure,
		|	NULL AS UnitOfMeasurementOfSemiFinishedProduct,
		|	Costs.UnitOfMeasure AS CostUnitOfMeasure,
		|	TTManufacturedProduct.Organization AS Organization,
		|	Costs.ProductCostElement AS ProductCostElement,
		|	Costs.Department AS Department,
		|	""GiverSMaterials"" AS DataType,
		|	TTManufacturedProduct.Series AS Series,
		|	Costs.BatchCost AS LotCosts,
		|	Costs.Level AS Level,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN TTManufacturedProduct.LocalAccountingCurrency
		|		ELSE
		|			&ManagementAccountingCurrency
		|	END AS Currency
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN Result AS Costs
		|		ON TTManufacturedProduct.ProductsAccountingDimension = Costs.ProductsAccountingDimension
		|			AND TTManufacturedProduct.ProductsBatch = Costs.ProductsBatch
		|			AND (Costs.LineKind = VALUE(Enum.KindsOfCostTreeRows.LotCosts))
		|			AND (VALUETYPE(Costs.BatchCost) = TYPE(Document.GoodsReceiptForStorage)
		|						AND CAST(Costs.BatchCost AS Document.GoodsReceiptForStorage).BusinessOperation =
		|							VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
		|				OR FALSE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ActualData.ManufacturedProduct AS ManufacturedProduct,
		|	ActualData.ItemVariant AS ItemVariant,
		|	ActualData.Purpose AS AssignmentOfProducts,
		|	ActualData.ProductsBatch AS ProductsBatch,
		|	ActualData.SemiFinishedProduct AS SemiFinishedProduct,
		|	ActualData.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	SUM(ActualData.Count) AS QuantityRelease,
		|	ActualData.Organization AS Organization,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN ActualData.LocalAccountingCurrency
		|		ELSE
		|			&ManagementAccountingCurrency
		|	END AS Currency
		|FROM
		|	ReleasedQuantity AS ActualData
		|WHERE
		|	ActualData.ThisIsOutput_
		|
		|GROUP BY
		|	ActualData.ManufacturedProduct,
		|	ActualData.SemiFinishedProduct,
		|	ActualData.ItemVariantsOfIntermediateProduct,
		|	ActualData.ProductsBatch,
		|	ActualData.ItemVariant,
		|	ActualData.Purpose,
		|	ActualData.Organization,
		|	CASE
		|		WHEN &Cost_Data = 3
		|			THEN ActualData.LocalAccountingCurrency
		|		ELSE
		|			&ManagementAccountingCurrency
		|	END
		|";
	QueriesTexts.Add(QueryText);
		
	If Not SelectionByOrganizationHasBeenEstablished Then
		QueryText = "
		|SELECT DISTINCT
		|	ActualData.Organization AS Organization
		|FROM
		|	ReleasedQuantity AS ActualData
		|";
		QueriesTexts.Add(QueryText);
	EndIf;
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	#EndRegion

	ResultsArray = Query.ExecuteBatch();
	ExternalDataSets = New Structure();
	LastQueryIndex = ResultsArray.Count();
	
	CompanyArray = Undefined;
	If Not SelectionByOrganizationHasBeenEstablished Then
		LastQueryIndex = LastQueryIndex - 1;
		CompanyArray = New Array();
		OrganizationsToCheck = ResultsArray[LastQueryIndex].Select();
		While OrganizationsToCheck.Next() Do
			CompanyArray.Add(OrganizationsToCheck.Organization);
		EndDo;
	EndIf;
	
	ExternalDataSets.Insert("Releases", ResultsArray[LastQueryIndex - 1].Unload());
	ExternalDataSets.Insert("Real", ResultsArray[LastQueryIndex - 2].Unload());
	
	ItemsToDelete_ = New Array;
	For Each FilterElement In ReportSettings.Filter.Items Do
		
		If FilterElement.LeftValue = New DataCompositionField("Recorder") Then
			ItemsToDelete_.Add(FilterElement);
		EndIf;
		If FilterElement.LeftValue = New DataCompositionField("StandardCostEstimate") Then
			// The report is called as an extension of the "Planned and actual Cost" report.
			ItemsToDelete_.Add(FilterElement);
		EndIf;
	EndDo;
	
	For Each ItemToRemove In ItemsToDelete_ Do
		ReportSettings.Filter.Items.Delete(ItemToRemove);
	EndDo;
	
	// Managing the visibility of permanent and temporary difference columns.
	FoundColumns = New Array;
	FindColumnRecursively(ReportSettings.Structure, FoundColumns, New DataCompositionField("PermanentDifference"));
	FindColumnRecursively(ReportSettings.Structure, FoundColumns, New DataCompositionField("CostTD"));
	
	DisplayPRVR = (Cost_Data = 4)
		And ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("DisplayPRVR")).Value;
	For Each Column In FoundColumns Do
		Column.Use = DisplayPRVR;
	EndDo;
	
	// Managing the visibility of the TaxAccounting column.
	FoundColumns = New Array;
	FindColumnRecursively(ReportSettings.Structure, FoundColumns, New DataCompositionField("TaxAccounting"));
	For Each Column In FoundColumns Do
		Column.Use = (Cost_Data = 4)
			And GetFunctionalOption("UseLocal")
			And Column.Use;
	EndDo;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	PrintWarningAboutRestrictionsOnUseOfReport(BeginOfPeriod,
		EndOfPeriod,
		ResultDocument,
		CompanyArray);
		
	OutputProcessor.Output(CompositionProcessor);
	If Not TypeOf(Invoices) = Type("DocumentRef.ReportToMaterialProvider2_5")
		And True Then
		DataCompositionServer.HideAuxiliaryReportParameters(
			DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Configures report parameters by report variant
//
// Parameters:
//	VariantKey						- String									- name of the predefined or unique ID of the custom
//																						version of the report.
//										- Undefined 								- a call for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure ConfigureReportParametersByReportVariant(VariantKey, NewDCSettings, NewDCUserSettings)
	
	ParameterCostData = DataCompositionSchema.Parameters.Find("Cost_Data");
	
	ChoiceList = New ValueList;
	
	If VariantKey = "ActualCostOfProductionOfEnterprise" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		
	ElsIf VariantKey = "ActualCostOfProductionOfOrganization" Then	
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		
	Else
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(4, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		
	EndIf;
	
	ParameterCostData.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfCostDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data"));
	SettingUpCostData = NewDCUserSettings.Items.Find(ValueOfCostDataParameter.UserSettingID);
	If Not SettingUpCostData = Undefined
		And ChoiceList.FindByValue(SettingUpCostData.Value) = Undefined Then
		SettingUpCostData.Value = ChoiceList[0].Value;
	EndIf;
	
	DisplayPRVRParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("DisplayPRVR"));
	If Not GetFunctionalOption("UseLocal")
	 Or Not AccountingPoliciesTaxSettingsLocalization.CalculationOfPermanentAndTemporaryDifferencesIsKept(Undefined, CurrentSessionDate()) Then
	 	DisplayPRVRParameter.Use = False;
	 	DisplayPRVRParameter.Value = False;
		DisplayPRVRParameter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
EndProcedure

// fills in the selection in the recipient's DCS with possible selections.
// 
// Parameters:
//	SettingsReceiver - DataCompositionFilter
//	SettingsSource - DataCompositionFilter
//	PossibleConditionFields - Array - data layout fields that can be selected in the settings receiver.
//
Procedure FillInReportSettingsRecursively(SettingsReceiver, SettingsSource, PossibleConditionFields)
	
	For Each FilterElement In SettingsSource.Items Do
		
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			NewItem = SettingsReceiver.Items.Add(TypeOf(FilterElement));
			FillPropertyValues(NewItem, FilterElement);
			FillInReportSettingsRecursively(NewItem, FilterElement, PossibleConditionFields);
			
		Else
			
			If StrFind(FilterElement.LeftValue, ".") = 0 And PossibleConditionFields.Find(FilterElement.LeftValue) = Undefined
					Or StrFind(FilterElement.LeftValue, ".") > 0 And PossibleConditionFields.Find(
					New DataCompositionField(Left(FilterElement.LeftValue, StrFind(FilterElement.LeftValue, ".") - 1))) = Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(SettingsReceiver.Items.Add(TypeOf(FilterElement)), FilterElement);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function AuxiliaryReportParameters()
	
	Parameters = New Array;
	Parameters.Add("MaterialsOfMaterialProviderOnly");
	
	Return Parameters;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseItemVariants") Then
		FieldsToDelete__ = New Array; // Array of String
		FieldsToDelete__.Add(New DataCompositionField("ItemVariant"));
		FieldsToDelete__.Add(New DataCompositionField("ItemVariantsOfIntermediateProduct"));
		FieldsToDelete__.Add(New DataCompositionField("CostCharacteristic"));
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.ClearStructureByFunctionalOptions(FormSettingsComposer.Structure, FieldsToDelete__);
	EndIf;
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		FieldsToDelete__ = New Array; // Array of String
		FieldsToDelete__.Add(New DataCompositionField("Series"));
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.ClearStructureByFunctionalOptions(FormSettingsComposer.Structure, FieldsToDelete__);
	EndIf;
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = New Array; // Array of String
		FieldsToDelete__.Add("PermanentDifference");
		FieldsToDelete__.Add("CostTD");
		FieldsToDelete__.Add("TaxAccounting");
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
	If Not GetFunctionalOption("AITAccounting") Then
		FieldsToDelete__ = New Array; // Array of String
		FieldsToDelete__.Add("AIT");
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

Procedure PrintWarningAboutRestrictionsOnUseOfReport(BeginOfPeriod, EndOfPeriod, ResultDocument,
	CompanyArray)
	
	WarningText = CostCalculationAppliedAlgorithms.WarningTextUnsupportedOrganizations(
		BeginOfPeriod, EndOfPeriod, SettingsComposer, CompanyArray);
	
	If Not IsBlankString(WarningText) Then
		
		WarningTable_ = New SpreadsheetDocument;
		AreaWarning = WarningTable_.Area(1,1,1,1);
		
		AreaWarning.Text 	 = TrimAll(WarningText);
		AreaWarning.TextColor = StyleColors.NegativeTextColor;
		
		ResultDocument.InsertArea(
		AreaWarning,
		ResultDocument.Area(1,1,1,1),
		SpreadsheetDocumentShiftType.Vertical);
		
	EndIf;
	
EndProcedure

Procedure FindColumnRecursively(ItemsCollection, FoundColumns, SearchValue)
	For Each Item In ItemsCollection Do
		If TypeOf(Item) = Type("DataCompositionGroup")
			Or TypeOf(Item) = Type("DataCompositionTableGroup")
			Or TypeOf(Item) = Type("DataCompositionChartGroup") Then
			For Each GroupingField In Item.Selection.Items Do
				If TypeOf(GroupingField) <> Type("DataCompositionAutoSelectedField") 
						And GroupingField.Field = SearchValue
				Then
					FoundColumns.Add(GroupingField);
				EndIf;
			EndDo;
			FindColumnRecursively(Item.Structure, FoundColumns, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			FindColumnRecursively(Item.Columns, FoundColumns, SearchValue);
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#EndIf
