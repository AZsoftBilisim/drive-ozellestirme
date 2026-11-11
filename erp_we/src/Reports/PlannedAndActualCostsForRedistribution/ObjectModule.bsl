
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options.
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportParametersByReportVariant(VariantKey, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TempTableManager = New TempTablesManager;
	AvailableConditionFields = New Array;
	NodulationScheme = Reports.ProductsCostTree.GetTemplate("MainDataCompositionSchema");
	NodalSettings = NodulationScheme.DefaultSettings;
	ReportSettings = SettingsComposer.GetSettings();
	
	NodalSettings.Filter.Items.Clear();
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
	
	For Each DataField In DeLinkingDataSet.Fields Do
		
		If DataField.UseRestriction.Condition Then
			Continue;
		EndIf;
		
		AvailableConditionFields.Add(New DataCompositionField(DataField.Field));
		
	EndDo;
	
	FillInReportSettingsRecursively(NodalSettings.Filter, ReportSettings.Filter, AvailableConditionFields);
	
	PeriodParameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Period"));
	Period = PeriodParameter.Value; // StandardPeriod
	BeginOfPeriod = ?(PeriodParameter.Use, Period.StartDate, BegOfYear(CurrentSessionDate()));
	EndOfPeriod = ?(PeriodParameter.Use, Period.EndDate, CurrentSessionDate());
	
	DataCompositionClientServer.SetParameter(NodalSettings, "Period", PeriodParameter.Value);
	
	Cost_Data = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data")).Value;
	DataCompositionClientServer.SetParameter(NodalSettings, "Cost_Data", Cost_Data);
	
	CostTreeParameters = CostStructure.CostTreeParameters();
	CostTreeParameters.DynamicReading = False;
	CostTreeParameters.ResultTypeTempTableManager = True;
	CostTreeParameters.TempTablesManager = TempTableManager;
	CostTreeParameters.InteractiveSetup = True;
	CostTreeParameters.DCSettings = NodalSettings;
	CostTreeParameters.ReportParameters.Cost_Data = Cost_Data;
	CostTreeParameters.ReportParameters.DeployAdditionalCosts = False;
		
	CostStructure.BuildCostTree(CostTreeParameters);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.SetParameter("Cost_Data", Cost_Data);
	Query.SetParameter("FactPresentation", NStr("vi = 'ФКП = %1';
												|ru = 'ФКП = %1';
												|en = 'FKP = %1'; fa = 'FKP = %1';
												|it = 'Impresa del governo federale = %1';
												|pl = 'FPP = %1';
												|tr = 'FKP = %1'"));
	Query.SetParameter("PlanPresentation", NStr("vi = 'PEP =%1';
												|ru = 'ПКП = %1';
												|en = 'PKP = %1'; fa = 'PKP = %1';
												|it = 'Indicatore della qualità del prodotto = %1';
												|pl = 'PKP = %1';
												|tr = 'PKP = %1'"));
	
	AveragingOfGNZP = ?(CostTreeParameters.ReportParameters.Property("ItemAveragingOfValueInWorkInProgress"),
		CostTreeParameters.ReportParameters.ItemAveragingOfValueInWorkInProgress,
		NStr("ru = 'Усреднение стоимости в незавершенном производстве';
			|vi = 'Cost averaging in work-in-progress';
			|en = 'Cost averaging in work-in-progress'; fa = 'Cost averaging in work-in-progress';
			|it = 'Cost averaging in work-in-progress';
			|pl = 'Cost averaging in work-in-progress';
			|tr = 'Devam eden imalattaki maliyet ortalaması'"));
	Query.SetParameter("ItemAveragingOfValueInWorkInProgress", AveragingOfGNZP);
	
#Region QueryText
	Query.Text =
		"SELECT
		|	Result.ProductsAccountingDimension.Products AS ManufacturedProduct,
		|	Result.ProductsAccountingDimension.Characteristic AS ItemVariant,
		|	Result.ProductsAccountingDimension.Purpose AS Purpose,
		|	Result.ProductsBatch AS ProductsBatch,
		|	Result.Organization AS Organization,
		|	Result.ProductsAccountingDimension.Series AS Series,
		|	Result.BatchCost AS SemiFinishedProductLot,
		|	CAST(Result.Products AS Catalog.Products) AS SemiFinishedProduct,
		|	Result.Characteristic AS ItemVariantsOfIntermediateProduct,
		|	CASE
		|		WHEN Result.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThisIsOutput_,
		|	SUM(Result.Count) AS Count,
		|	Result.ProductsAccountingDimension AS ProductsAccountingDimension
		|INTO ReleasedQuantity
		|FROM
		|	Result AS Result
		|WHERE
		|	Result.ExplosionIsRequired
		|
		|GROUP BY
		|	CAST(Result.Products AS Catalog.Products),
		|	Result.Characteristic,
		|	Result.ProductsAccountingDimension.Products,
		|	Result.ProductsAccountingDimension.CHARACTERISTIC,
		|	Result.ProductsAccountingDimension,
		|	Result.ProductsAccountingDimension.Purpose,
		|	Result.BatchCost,
		|	Result.Organization,
		|	Result.ProductsBatch,
		|	CASE
		|		WHEN Result.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch)
		|			THEN TRUE
		|		ELSE FALSE
		|	END,
		|	Result.ProductsAccountingDimension.Series
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	Purpose,
		|	ProductsBatch,
		|	Organization,
		|	Series
		|;
		|
		|SELECT
		|	ReleasedQuantity.ManufacturedProduct AS ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant AS ItemVariant,
		|	ReleasedQuantity.Purpose AS Purpose,
		|	ReleasedQuantity.ProductsBatch AS ProductsBatch,
		|	ReleasedQuantity.SemiFinishedProductLot AS SemiFinishedProductLot,
		|	ReleasedQuantity.SemiFinishedProduct AS SemiFinishedProduct,
		|	ReleasedQuantity.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	ReleasedQuantity.ThisIsOutput_ AS ThisIsOutput_,
		|	ReleasedQuantity.Count AS Count,
		|	ReleasedQuantity.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	ReleasedQuantity.Organization AS Organization,
		|	ReleasedQuantity.Series AS Series
		|INTO NumberOfIssuesCosts
		|FROM
		|	ReleasedQuantity AS ReleasedQuantity
		|
		|INDEX BY
		|	ProductsAccountingDimension,
		|	ItemVariantsOfIntermediateProduct,
		|	SemiFinishedProductLot,
		|	ProductsBatch
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReleasedQuantity.ManufacturedProduct AS ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant AS ItemVariant,
		|	ReleasedQuantity.Purpose AS Purpose,
		|	ReleasedQuantity.ProductsBatch AS ProductsBatch,
		|	SUM(ReleasedQuantity.Count) AS Count,
		|	ReleasedQuantity.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	ReleasedQuantity.Organization AS Organization,
		|	ReleasedQuantity.Series AS Series
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
		|	ReleasedQuantity.ItemVariant,
		|	ReleasedQuantity.Organization,
		|	ReleasedQuantity.Series
		|
		|INDEX BY
		|	ProductsAccountingDimension,
		|	ProductsBatch,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Result.Organization AS Organization,
		|	Result.AccountingDimensionFinishedProduct AS AccountingDimensionFinishedProduct,
		|	Result.Count AS Count,
		|	CASE
		|		WHEN Result.ExplosionIsRequired
		|			THEN 0
		|		ELSE Result.Sum
		|	END AS Sum,
		|	CASE
		|		WHEN Result.ExplosionIsRequired
		|			THEN 0
		|		ELSE Result.OffBalanceSheetAmount
		|	END AS OffBalanceSheetAmount,
		|	Result.Products AS Cost_,
		|	Result.Characteristic AS CostCharacteristic,
		|	Result.AccountingDimensionFinishedProduct.Products AS SemiFinishedProduct,
		|	Result.AccountingDimensionFinishedProduct.Characteristic AS ItemVariantsOfIntermediateProduct,
		|	Result.ProductsAccountingDimension AS ProductsAccountingDimension,
		|	Result.ExpenseType AS ExpenseType,
		|	Result.BatchFinishedProduct AS SemiFinishedProductLot,
		|	Result.ProductsBatch AS ProductsBatch,
		|	CASE
		|		WHEN Result.Count = 0
		|			THEN 0
		|		ELSE Result.Sum / Result.Count
		|	END AS Price,
		|	Result.ExplosionIsRequired AS ThisIsASemiFinishedProduct,
		|	Result.Department AS Department,
		|	Result.ProductCostElement AS ProductCostElement,
		|	Result.LineKind AS LineKind,
		|	Result.Level AS Level
		|INTO Costs
		|FROM
		|	Result AS Result
		|
		|INDEX BY
		|	ProductsBatch,
		|	ProductsAccountingDimension,
		|	SemiFinishedProductLot,
		|	ItemVariantsOfIntermediateProduct,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
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
		|	Costs.OffBalanceSheetAmount AS OffBalanceCost,
		|	Costs.Count AS Count,
		|	Costs.Price AS Price,
		|	Costs.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	Costs.Department AS Department,
		|	TTManufacturedProduct.Organization AS Organization,
		|	Costs.ProductCostElement AS ProductCostElement,
		|	TTManufacturedProduct.Series AS Series,
		|	Costs.Level AS Level
		|INTO CostsByType
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN Costs AS Costs
		|		ON TTManufacturedProduct.ProductsAccountingDimension = Costs.AccountingDimensionFinishedProduct
		|			AND (NOT Costs.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch))
		|			AND TTManufacturedProduct.ProductsBatch = Costs.ProductsBatch
		|			AND TTManufacturedProduct.ProductsBatch = Costs.SemiFinishedProductLot
		|			AND TTManufacturedProduct.Organization = Costs.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	ReleasedQuantity.ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant,
		|	ReleasedQuantity.Purpose,
		|	ReleasedQuantity.ProductsBatch,
		|	ReleasedQuantity.Count,
		|	ReleasedQuantity.SemiFinishedProduct,
		|	ReleasedQuantity.ItemVariantsOfIntermediateProduct,
		|	Costs.Cost_,
		|	Costs.CostCharacteristic,
		|	SUM(Costs.Sum),
		|	SUM(Costs.OffBalanceSheetAmount),
		|	SUM(Costs.Count),
		|	AVG(Costs.Price),
		|	Costs.ThisIsASemiFinishedProduct,
		|	Costs.Department,
		|	ReleasedQuantity.Organization,
		|	Costs.ProductCostElement,
		|	ReleasedQuantity.Series,
		|	Costs.Level
		|FROM
		|	NumberOfIssuesCosts AS ReleasedQuantity
		|		INNER JOIN Costs AS Costs
		|		ON ReleasedQuantity.ProductsAccountingDimension = Costs.ProductsAccountingDimension
		|			AND ReleasedQuantity.SemiFinishedProduct = Costs.SemiFinishedProduct
		|			AND ReleasedQuantity.ItemVariantsOfIntermediateProduct = Costs.ItemVariantsOfIntermediateProduct
		|			AND ReleasedQuantity.SemiFinishedProductLot = Costs.SemiFinishedProductLot
		|			AND ReleasedQuantity.ProductsBatch = Costs.ProductsBatch
		|			AND Costs.ProductsBatch <> Costs.SemiFinishedProductLot
		|			AND Costs.Organization = ReleasedQuantity.Organization
		|WHERE
		|	NOT ReleasedQuantity.ThisIsOutput_
		|
		|GROUP BY
		|	ReleasedQuantity.ManufacturedProduct,
		|	ReleasedQuantity.ItemVariant,
		|	ReleasedQuantity.Purpose,
		|	ReleasedQuantity.ProductsBatch,
		|	ReleasedQuantity.Count,
		|	ReleasedQuantity.SemiFinishedProduct,
		|	ReleasedQuantity.ItemVariantsOfIntermediateProduct,
		|	Costs.Cost_,
		|	Costs.CostCharacteristic,
		|	Costs.ThisIsASemiFinishedProduct,
		|	Costs.Department,
		|	ReleasedQuantity.Organization,
		|	Costs.ProductCostElement,
		|	ReleasedQuantity.Series,
		|	Costs.Level
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	Purpose,
		|	ProductsBatch,
		|	Series,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TTManufacturedProduct.ManufacturedProduct AS ManufacturedProduct,
		|	TTManufacturedProduct.ItemVariant AS ItemVariant,
		|	TTManufacturedProduct.Purpose AS AssignmentOfProducts,
		|	TTManufacturedProduct.ProductsBatch AS Lot,
		|	Releases.Period AS Period,
		|	TTManufacturedProduct.Organization AS Organization
		|INTO ReleaseDates_
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN AccumulationRegister.ProductsRelease AS Releases
		|		ON TTManufacturedProduct.Organization = Releases.Organization
		|			AND TTManufacturedProduct.ProductsAccountingDimension = Releases.ItemsLocationAttributes
		|			AND TTManufacturedProduct.ProductsBatch = Releases.Recorder
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	Lot,
		|	Period,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(Multipliers.StandardCostEstimate.Date) AS CalculationDate,
		|	ReleaseDates_.ManufacturedProduct AS ManufacturedProduct,
		|	ReleaseDates_.ItemVariant AS ItemVariant,
		|	ReleaseDates_.AssignmentOfProducts AS AssignmentOfProducts,
		|	ReleaseDates_.Lot AS Lot,
		|	TRUE AS OrderCosting,
		|	ReleaseDates_.Organization AS Organization
		|INTO OrderCalculations
		|FROM
		|	ReleaseDates_ AS ReleaseDates_
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ReleaseDates_.ManufacturedProduct = Multipliers.ManufacturedProduct
		|			AND ReleaseDates_.ItemVariant = Multipliers.ItemVariant
		|			AND ReleaseDates_.AssignmentOfProducts = Multipliers.Purpose
		|			AND ReleaseDates_.Lot = Multipliers.LotProductBOM
		|			AND ReleaseDates_.Period >= Multipliers.StandardCostEstimate.Date
		|			AND ReleaseDates_.Organization = Multipliers.StandardCostEstimate.Organization
		|			AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|GROUP BY
		|	ReleaseDates_.ManufacturedProduct,
		|	ReleaseDates_.ItemVariant,
		|	ReleaseDates_.AssignmentOfProducts,
		|	ReleaseDates_.Lot,
		|	ReleaseDates_.Organization
		|	
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	Lot,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(Multipliers.StandardCostEstimate.Date) AS CalculationDate,
		|	ReleaseDates_.ManufacturedProduct AS ManufacturedProduct,
		|	ReleaseDates_.ItemVariant AS ItemVariant,
		|	ReleaseDates_.AssignmentOfProducts AS AssignmentOfProducts,
		|	ReleaseDates_.Lot AS Lot,
		|	FALSE AS OrderCosting,
		|	ReleaseDates_.Organization AS Organization
		|INTO SpecificationCalculations
		|FROM
		|	ReleaseDates_ AS ReleaseDates_
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ReleaseDates_.ManufacturedProduct = Multipliers.ManufacturedProduct
		|			AND ReleaseDates_.ItemVariant = Multipliers.ItemVariant
		|			AND ReleaseDates_.Period >= Multipliers.StandardCostEstimate.Date
		|			AND (VALUETYPE(Multipliers.LotProductBOM) = TYPE(Catalog.BillsOfMaterials))
		|			AND ReleaseDates_.Organization = Multipliers.StandardCostEstimate.Organization
		|			AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|		LEFT JOIN OrderCalculations AS OrderCalculations
		|		ON ReleaseDates_.ManufacturedProduct = OrderCalculations.ManufacturedProduct
		|			AND ReleaseDates_.ItemVariant = OrderCalculations.ItemVariant
		|			AND ReleaseDates_.AssignmentOfProducts = OrderCalculations.AssignmentOfProducts
		|			AND ReleaseDates_.Lot = OrderCalculations.Lot
		|			AND ReleaseDates_.Organization = OrderCalculations.Organization
		|WHERE
		|	OrderCalculations.CalculationDate IS NULL
		|
		|GROUP BY
		|	ReleaseDates_.ManufacturedProduct,
		|	ReleaseDates_.ItemVariant,
		|	ReleaseDates_.AssignmentOfProducts,
		|	ReleaseDates_.Lot,
		|	ReleaseDates_.Organization
		|// no index required
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderCalculations.CalculationDate AS CalculationDate,
		|	OrderCalculations.ManufacturedProduct AS ManufacturedProduct,
		|	OrderCalculations.ItemVariant AS ItemVariant,
		|	OrderCalculations.AssignmentOfProducts AS AssignmentOfProducts,
		|	OrderCalculations.Lot AS Lot,
		|	OrderCalculations.OrderCosting AS OrderCosting,
		|	OrderCalculations.Organization AS Organization
		|INTO RecentCalculations
		|FROM
		|	OrderCalculations AS OrderCalculations
		|
		|UNION ALL
		|
		|SELECT
		|	SpecificationCalculations.CalculationDate,
		|	SpecificationCalculations.ManufacturedProduct,
		|	SpecificationCalculations.ItemVariant,
		|	SpecificationCalculations.AssignmentOfProducts,
		|	SpecificationCalculations.Lot,
		|	SpecificationCalculations.OrderCosting,
		|	SpecificationCalculations.Organization
		|FROM
		|	SpecificationCalculations AS SpecificationCalculations
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	Lot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
		|	CASE
		|		WHEN VALUETYPE(Multipliers.LotProductBOM) = TYPE(Catalog.BillsOfMaterials)
		|			THEN Multipliers.LotProductBOM
		|		ELSE
		|			VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|	END AS SpecificationOfPlannedCalculation,
		|
		|	RecentCalculations.ManufacturedProduct AS ManufacturedProduct,
		|	RecentCalculations.ItemVariant AS ItemVariant,
		|	RecentCalculations.AssignmentOfProducts AS AssignmentOfProducts,
		|	RecentCalculations.Lot AS Lot,
		|	RecentCalculations.OrderCosting AS OrderCosting,
		|	ReleasedQuantity.Count AS ProductQuantityActual,
		|	RecentCalculations.Organization AS Organization,
		|	ReleasedQuantity.Series AS Series,
		|	RecentCalculations.AssignmentOfProducts = Multipliers.Purpose AS AssignmentConverges
		|
		|INTO ProductCostingsPreliminary
		|FROM
		|	RecentCalculations AS RecentCalculations
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON RecentCalculations.ManufacturedProduct = Multipliers.ManufacturedProduct
		|			AND RecentCalculations.ItemVariant = Multipliers.ItemVariant
		|			AND (RecentCalculations.AssignmentOfProducts = Multipliers.Purpose
		|				OR Multipliers.Purpose = VALUE(Catalog.Assignments.EmptyRef))
		|			AND RecentCalculations.CalculationDate = Multipliers.StandardCostEstimate.Date
		|			AND (CASE
		|				WHEN RecentCalculations.OrderCosting
		|					THEN RecentCalculations.Lot = Multipliers.LotProductBOM
		|				ELSE TRUE
		|			END)
		|			AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|		INNER JOIN ReleasedQuantity AS ReleasedQuantity
		|		ON RecentCalculations.ManufacturedProduct = ReleasedQuantity.ManufacturedProduct
		|			AND RecentCalculations.ItemVariant = ReleasedQuantity.ItemVariant
		|			AND RecentCalculations.AssignmentOfProducts = ReleasedQuantity.Purpose
		|			AND RecentCalculations.Lot = ReleasedQuantity.ProductsBatch
		|			AND (ReleasedQuantity.ThisIsOutput_)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VZ.ManufacturedProduct AS ManufacturedProduct,
		|	VZ.ItemVariant AS ItemVariant,
		|	VZ.AssignmentOfProducts AS AssignmentOfProducts,
		|	VZ.Lot AS Lot,
		|	VZ.OrderCosting AS OrderCosting,
		|	VZ.ProductQuantityActual AS ProductQuantityActual,
		|	VZ.Organization AS Organization,
		|	VZ.Series AS Series,
		|	MAX(VZ.AssignmentConverges) AS AssignmentConverges
		|INTO MeasurementsWithSuitableAssignments
		|FROM
		|	ProductCostingsPreliminary AS VZ
		|
		|GROUP BY
		|	VZ.ManufacturedProduct,
		|	VZ.ItemVariant,
		|	VZ.AssignmentOfProducts,
		|	VZ.Lot,
		|	VZ.OrderCosting,
		|	VZ.ProductQuantityActual,
		|	VZ.Organization,
		|	VZ.Series
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	Lot,
		|	OrderCosting,
		|	ProductQuantityActual,
		|	Organization,
		|	Series,
		|	AssignmentConverges
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(DD.StandardCostEstimate) AS StandardCostEstimate,
		|	MAX(DD.SpecificationOfPlannedCalculation) AS SpecificationOfPlannedCalculation,
		|	DD.ManufacturedProduct AS ManufacturedProduct,
		|	DD.ItemVariant AS ItemVariant,
		|	DD.AssignmentOfProducts AS AssignmentOfProducts,
		|	DD.Lot AS Lot,
		|	DD.OrderCosting AS OrderCosting,
		|	DD.ProductQuantityActual AS ProductQuantityActual,
		|	DD.Organization AS Organization,
		|	DD.Series AS Series,
		|	DD.AssignmentConverges AS FilterByAssignment
		|INTO ProductCostings
		|FROM
		|	ProductCostingsPreliminary AS DD
		|		INNER JOIN MeasurementsWithSuitableAssignments AS ISPN
		|		ON DD.ManufacturedProduct = ISPN.ManufacturedProduct
		|			AND DD.ItemVariant = ISPN.ItemVariant
		|			AND DD.AssignmentOfProducts = ISPN.AssignmentOfProducts
		|			AND DD.Lot = ISPN.Lot
		|			AND DD.OrderCosting = ISPN.OrderCosting
		|			AND DD.ProductQuantityActual = ISPN.ProductQuantityActual
		|			AND DD.Organization = ISPN.Organization
		|			AND DD.Series = ISPN.Series
		|			AND DD.AssignmentConverges = ISPN.AssignmentConverges
		|
		|GROUP BY
		|	DD.ManufacturedProduct,
		|	DD.ItemVariant,
		|	DD.AssignmentOfProducts,
		|	DD.Lot,
		|	DD.OrderCosting,
		|	DD.ProductQuantityActual,
		|	DD.Organization,
		|	DD.Series,
		|	DD.AssignmentConverges
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	Lot,
		|	Series,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductCostings.ManufacturedProduct AS ManufacturedProduct,
		|	ProductCostings.ItemVariant AS ItemVariant,
		|	ProductCostings.AssignmentOfProducts AS AssignmentOfProducts,
		|	ProductCostings.Lot AS Lot,
		|	ProductCostings.Series AS Series,
		|	ProductCostings.Organization AS Organization,
		|	ProductCostings.StandardCostEstimate AS StandardCostEstimate,
		|	ProductCostings.OrderCosting AS OrderCosting
		|INTO ProductAndOrderCalculations
		|FROM
		|	ProductCostings AS ProductCostings
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	Lot,
		|	Series,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CostsByType.ManufacturedProduct AS ManufacturedProduct,
		|	CostsByType.ItemVariant AS ItemVariant,
		|	CostsByType.Purpose AS Purpose,
		|	CostsByType.ProductsBatch AS ProductsBatch,
		|	CostsByType.SemiFinishedProduct AS SemiFinishedProduct,
		|	CostsByType.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	CostsByType.Series AS Series,
		|	CostsByType.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	ProductAndOrderCalculations.StandardCostEstimate AS StandardCostEstimate,
		|	CostsByType.Cost_ AS Cost_,
		|	CostsByType.CostCharacteristic AS CostCharacteristic,
		|	ProductAndOrderCalculations.OrderCosting AS OrderCosting,
		|	CostsByType.Department AS Department,
		|	CostsByType.Organization AS Organization,
		|	CostsByType.ProductCostElement AS ProductCostElement,
		|	CostsByType.Cost AS Cost,
		|	CostsByType.OffBalanceCost AS OffBalanceCost,
		|	CostsByType.Count AS Count,
		|	CostsByType.QuantityRelease AS QuantityRelease,
		|	CostsByType.Price AS Price,
		|	CostsByType.Level AS Level
		|INTO ActualData
		|FROM
		|	CostsByType AS CostsByType
		|		LEFT JOIN ProductAndOrderCalculations AS ProductAndOrderCalculations
		|		ON CostsByType.ManufacturedProduct = ProductAndOrderCalculations.ManufacturedProduct
		|			AND CostsByType.ItemVariant = ProductAndOrderCalculations.ItemVariant
		|			AND CostsByType.Purpose = ProductAndOrderCalculations.AssignmentOfProducts
		|			AND CostsByType.ProductsBatch = ProductAndOrderCalculations.Lot
		|			AND CostsByType.Organization = ProductAndOrderCalculations.Organization
		|			AND CostsByType.Series = ProductAndOrderCalculations.Series
		|WHERE
		|	CostsByType.Cost_ <> &ItemAveragingOfValueInWorkInProgress
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	Purpose,
		|	ProductsBatch,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Series,
		|	ThisIsASemiFinishedProduct,
		|	StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductCostings.StandardCostEstimate AS StandardCostEstimate,
		|	ProductCostings.ManufacturedProduct AS ManufacturedProduct,
		|	ProductCostings.ItemVariant AS ItemVariant,
		|	ProductCostings.AssignmentOfProducts AS Purpose,
		|	ProductCostings.Lot AS LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS CalculationBatchOfProducts,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose AS CalculationPurposeOfProducts,
		|	ProductCostings.ProductQuantityActual / MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct AS CostShare,
		|	ProductCostings.OrderCosting AS OrderCosting,
		|	ProductCostings.Series AS Series
		|INTO SharesOfCostOfPlannedData
		|FROM
		|	ProductCostings AS ProductCostings
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		ON ProductCostings.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
		|			AND ProductCostings.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|			AND ProductCostings.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
		|			AND (ProductCostings.AssignmentOfProducts = MultiplesOfLotsAndSemiFinishedProducts.Purpose
		|				OR NOT ProductCostings.FilterByAssignment)
		|			AND (CASE
		|				WHEN ProductCostings.OrderCosting
		|					THEN MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM = ProductCostings.Lot
		|				ELSE MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM = ProductCostings.SpecificationOfPlannedCalculation
		|			END)
		|			AND (MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SharesOfCostOfPlannedData.StandardCostEstimate AS StandardCostEstimate,
		|	SharesOfCostOfPlannedData.ManufacturedProduct AS ManufacturedProduct,
		|	SharesOfCostOfPlannedData.ItemVariant AS ItemVariant,
		|	SharesOfCostOfPlannedData.Purpose AS Purpose,
		|	SharesOfCostOfPlannedData.LotProductBOM AS LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator * SharesOfCostOfPlannedData.CostShare AS Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator AS Denominator,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct * SharesOfCostOfPlannedData.CostShare AS QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS CalculationBatchOfProducts,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	CASE
		|		WHEN &Cost_Data = 1
		|			THEN MultiplesOfLotsAndSemiFinishedProducts.Cost
		|		WHEN &Cost_Data = 2
		|			THEN MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT
		|		WHEN &Cost_Data = 3
		|			THEN MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT
		|		WHEN &Cost_Data = 4
		|			THEN MultiplesOfLotsAndSemiFinishedProducts.LocalCost
		|	END * SharesOfCostOfPlannedData.CostShare AS Cost,
		|	CASE
		|		WHEN &Cost_Data = 4
		|			THEN MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCostLocal
		|		ELSE MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCost
		|	END * SharesOfCostOfPlannedData.CostShare AS OffBalanceCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased AS LotIsReleased,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.Organization AS Organization,
		|	SharesOfCostOfPlannedData.Series AS Series,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef) AS ThisIsOutput_
		|INTO MultipliersOfSemiFinishedProducts
		|FROM
		|	SharesOfCostOfPlannedData AS SharesOfCostOfPlannedData
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		ON SharesOfCostOfPlannedData.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
		|			AND SharesOfCostOfPlannedData.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|			AND SharesOfCostOfPlannedData.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
		|			AND (MultiplesOfLotsAndSemiFinishedProducts.Purpose = SharesOfCostOfPlannedData.CalculationPurposeOfProducts)
		|			AND (MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM = SharesOfCostOfPlannedData.CalculationBatchOfProducts)
		|
		|INDEX BY
		|	ThisIsOutput_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant AS ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose AS Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM AS LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.CalculationBatchOfProducts AS CalculationBatchOfProducts,
		|	MultipliersOfSemiFinishedProducts.Numerator AS Numerator,
		|	MultipliersOfSemiFinishedProducts.Denominator AS Denominator,
		|	MultipliersOfSemiFinishedProducts.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.LotIsReleased AS LotIsReleased,
		|	MultipliersOfSemiFinishedProducts.Organization AS Organization,
		|	MultipliersOfSemiFinishedProducts.Series AS Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot AS KeyLot
		|INTO ProductMultipliers
		|FROM
		|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
		|WHERE
		|	MultipliersOfSemiFinishedProducts.ThisIsOutput_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductMultipliers.StandardCostEstimate AS StandardCostEstimate,
		|	ProductMultipliers.ManufacturedProduct AS ManufacturedProduct,
		|	ProductMultipliers.ItemVariant AS ItemVariant,
		|	ProductMultipliers.Purpose AS Purpose,
		|	ProductMultipliers.LotProductBOM AS LotProductBOM,
		|	MaterialCosts.Products AS Cost_,
		|	MaterialCosts.Characteristic AS Characteristic,
		|	MaterialCosts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	MaterialCosts.Count * ProductMultipliers.Numerator / ProductMultipliers.Denominator AS Count,
		|	CASE
		|		WHEN &Cost_Data = 1
		|			THEN MaterialCosts.Cost
		|		WHEN &Cost_Data = 2
		|			THEN MaterialCosts.CostExcludingVAT
		|		WHEN &Cost_Data = 3
		|			THEN MaterialCosts.CostExcludingVAT
		|		WHEN &Cost_Data = 4
		|			THEN MaterialCosts.LocalCost
		|	END * ProductMultipliers.Numerator / ProductMultipliers.Denominator AS Cost,
		|	CASE
		|		WHEN &Cost_Data = 4
		|			THEN MaterialCosts.OffBalanceCostLocal
		|		ELSE MaterialCosts.OffBalanceCost
		|	END * ProductMultipliers.Numerator / ProductMultipliers.Denominator AS OffBalanceCost,
		|	MaterialCosts.Department AS Department,
		|	MaterialCosts.ProductCostElement AS ProductCostElement,
		|	ProductMultipliers.Series AS Series,
		|	ProductMultipliers.KeyLot
		|INTO PlannedProductionCosts
		|FROM
		|	ProductMultipliers AS ProductMultipliers
		|		LEFT JOIN AccumulationRegister.PlannedMaterialCosts AS MaterialCosts
		|		ON ProductMultipliers.CalculationBatchOfProducts = MaterialCosts.LotBOM
		|			AND ProductMultipliers.StandardCostEstimate = MaterialCosts.StandardCostEstimate
		|			AND ProductMultipliers.KeyLot = MaterialCosts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	ProductMultipliers.StandardCostEstimate,
		|	ProductMultipliers.ManufacturedProduct,
		|	ProductMultipliers.ItemVariant,
		|	ProductMultipliers.Purpose,
		|	ProductMultipliers.LotProductBOM,
		|	PlannedLaborCosts.WorkKind,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
		|	FALSE,
		|	PlannedLaborCosts.Count * ProductMultipliers.Numerator / ProductMultipliers.Denominator,
		|	CASE
		|		WHEN &Cost_Data = 4
		|			THEN PlannedLaborCosts.LocalCost
		|		ELSE PlannedLaborCosts.Cost
		|	END * ProductMultipliers.Numerator / ProductMultipliers.Denominator,
		|	0,
		|	PlannedLaborCosts.Department,
		|	PlannedLaborCosts.ProductCostElement,
		|	ProductMultipliers.Series,
		|	ProductMultipliers.KeyLot AS KeyLot
		|FROM
		|	ProductMultipliers AS ProductMultipliers
		|		LEFT JOIN AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|		ON ProductMultipliers.CalculationBatchOfProducts = PlannedLaborCosts.LotBOM
		|			AND ProductMultipliers.StandardCostEstimate = PlannedLaborCosts.StandardCostEstimate
		|			AND ProductMultipliers.KeyLot = PlannedLaborCosts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	ProductMultipliers.StandardCostEstimate,
		|	ProductMultipliers.ManufacturedProduct,
		|	ProductMultipliers.ItemVariant,
		|	ProductMultipliers.Purpose,
		|	ProductMultipliers.LotProductBOM,
		|	PlannedOtherCosts.ExpenseItem,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
		|	FALSE,
		|	0,
		|	CASE
		|		WHEN &Cost_Data = 1
		|			THEN PlannedOtherCosts.Cost
		|		WHEN &Cost_Data = 2
		|			THEN PlannedOtherCosts.CostExcludingVAT
		|		WHEN &Cost_Data = 3
		|			THEN PlannedOtherCosts.CostExcludingVAT
		|		WHEN &Cost_Data = 4
		|			THEN PlannedOtherCosts.LocalCost
		|	END * ProductMultipliers.Numerator / ProductMultipliers.Denominator,
		|	0,
		|	PlannedOtherCosts.Department,
		|	PlannedOtherCosts.ProductCostElement,
		|	ProductMultipliers.Series,
		|	ProductMultipliers.KeyLot
		|FROM
		|	ProductMultipliers AS ProductMultipliers
		|		LEFT JOIN AccumulationRegister.PlannedOtherCosts AS PlannedOtherCosts
		|		ON ProductMultipliers.CalculationBatchOfProducts = PlannedOtherCosts.LotBOM
		|			AND ProductMultipliers.StandardCostEstimate = PlannedOtherCosts.StandardCostEstimate
		|			AND ProductMultipliers.KeyLot = PlannedOtherCosts.KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant AS ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose AS Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM AS LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	PlannedMaterialCosts.Products AS Products,
		|	PlannedMaterialCosts.Characteristic AS Characteristic,
		|	PlannedMaterialCosts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	SUM(ISNULL(PlannedMaterialCosts.Count, 0) * MultipliersOfSemiFinishedProducts.Numerator / MultipliersOfSemiFinishedProducts.Denominator) AS Count,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN ISNULL(PlannedMaterialCosts.Cost, 0)
		|			WHEN &Cost_Data = 2
		|				THEN ISNULL(PlannedMaterialCosts.CostExcludingVAT, 0)
		|			WHEN &Cost_Data = 3
		|				THEN ISNULL(PlannedMaterialCosts.CostExcludingVAT, 0)
		|			WHEN &Cost_Data = 4
		|				THEN ISNULL(PlannedMaterialCosts.LocalCost, 0)
		|		END * MultipliersOfSemiFinishedProducts.Numerator / MultipliersOfSemiFinishedProducts.Denominator) AS Cost,
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN PlannedMaterialCosts.OffBalanceCostLocal
		|			ELSE PlannedMaterialCosts.OffBalanceCost
		|		END * MultipliersOfSemiFinishedProducts.Numerator / MultipliersOfSemiFinishedProducts.Denominator) AS OffBalanceCost,
		|	PlannedMaterialCosts.Department AS Department,
		|	PlannedMaterialCosts.ProductCostElement AS ProductCostElement,
		|	0 AS Price,
		|	MultipliersOfSemiFinishedProducts.Series AS Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot AS KeyLot
		|
		|INTO PlannedCostsOfSemiFinishedProducts
		|FROM
		|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
		|		LEFT JOIN AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
		|		ON MultipliersOfSemiFinishedProducts.StandardCostEstimate = PlannedMaterialCosts.StandardCostEstimate
		|			AND MultipliersOfSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedMaterialCosts.LotBOM
		|			AND MultipliersOfSemiFinishedProducts.KeyLot = PlannedMaterialCosts.KeyLot
		|WHERE
		|	NOT MultipliersOfSemiFinishedProducts.ThisIsOutput_
		|
		|GROUP BY
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	PlannedMaterialCosts.Products,
		|	PlannedMaterialCosts.Characteristic,
		|	PlannedMaterialCosts.ThisIsASemiFinishedProduct,
		|	PlannedMaterialCosts.Department,
		|	PlannedMaterialCosts.ProductCostElement,
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	PlannedLaborCosts.WorkKind,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
		|	FALSE,
		|	SUM(ISNULL(PlannedLaborCosts.Count, 0) * MultipliersOfSemiFinishedProducts.Numerator / MultipliersOfSemiFinishedProducts.Denominator),
		|	SUM(CASE
		|			WHEN &Cost_Data = 4
		|				THEN ISNULL(PlannedLaborCosts.LocalCost, 0)
		|			ELSE ISNULL(PlannedLaborCosts.Cost, 0)
		|		END * MultipliersOfSemiFinishedProducts.Numerator / MultipliersOfSemiFinishedProducts.Denominator),
		|	0,
		|	PlannedLaborCosts.Department,
		|	PlannedLaborCosts.ProductCostElement,
		|	0,
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot AS KeyLot
		|FROM
		|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
		|		LEFT JOIN AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|		ON MultipliersOfSemiFinishedProducts.StandardCostEstimate = PlannedLaborCosts.StandardCostEstimate
		|			AND MultipliersOfSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedLaborCosts.LotBOM
		|			AND MultipliersOfSemiFinishedProducts.KeyLot = PlannedLaborCosts.KeyLot
		|WHERE
		|	NOT MultipliersOfSemiFinishedProducts.ThisIsOutput_
		|
		|GROUP BY
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	PlannedLaborCosts.WorkKind,
		|	PlannedLaborCosts.Department,
		|	PlannedLaborCosts.ProductCostElement,
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	PlannedOtherCosts.ExpenseItem,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
		|	FALSE,
		|	0,
		|	SUM(CASE
		|			WHEN &Cost_Data = 1
		|				THEN ISNULL(PlannedOtherCosts.Cost, 0)
		|			WHEN &Cost_Data = 2
		|				THEN ISNULL(PlannedOtherCosts.CostExcludingVAT, 0)
		|			WHEN &Cost_Data = 3
		|				THEN ISNULL(PlannedOtherCosts.CostExcludingVAT, 0)
		|			WHEN &Cost_Data = 4
		|				THEN ISNULL(PlannedOtherCosts.LocalCost, 0)
		|		END * MultipliersOfSemiFinishedProducts.Numerator / MultipliersOfSemiFinishedProducts.Denominator),
		|	0,
		|	PlannedOtherCosts.Department,
		|	PlannedOtherCosts.ProductCostElement,
		|	0,
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot AS KeyLot
		|FROM
		|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
		|		LEFT JOIN AccumulationRegister.PlannedOtherCosts AS PlannedOtherCosts
		|		ON MultipliersOfSemiFinishedProducts.StandardCostEstimate = PlannedOtherCosts.StandardCostEstimate
		|			AND MultipliersOfSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedOtherCosts.LotBOM
		|			AND MultipliersOfSemiFinishedProducts.KeyLot = PlannedOtherCosts.KeyLot
		|WHERE
		|	NOT MultipliersOfSemiFinishedProducts.ThisIsOutput_
		|
		|GROUP BY
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	PlannedOtherCosts.ExpenseItem,
		|	PlannedOtherCosts.Department,
		|	PlannedOtherCosts.ProductCostElement,
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	CostsByType.Cost_,
		|	CostsByType.CostCharacteristic,
		|	CostsByType.ThisIsASemiFinishedProduct,
		|	CostsByType.Count,
		|	SUM(CostsByType.Cost),
		|	SUM(CostsByType.OffBalanceCost),
		|	CostsByType.Department,
		|	VALUE(Catalog.ProductCostElements.EmptyRef),
		|	AVG(CostsByType.Price),
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot AS KeyLot
		|FROM
		|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
		|		INNER JOIN CostsByType AS CostsByType
		|		ON MultipliersOfSemiFinishedProducts.ManufacturedProduct = CostsByType.ManufacturedProduct
		|			AND MultipliersOfSemiFinishedProducts.ItemVariant = CostsByType.ItemVariant
		|			AND MultipliersOfSemiFinishedProducts.Purpose = CostsByType.Purpose
		|			AND MultipliersOfSemiFinishedProducts.LotProductBOM = CostsByType.ProductsBatch
		|			AND MultipliersOfSemiFinishedProducts.SemiFinishedProduct = CostsByType.SemiFinishedProduct
		|			AND MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct = CostsByType.ItemVariantsOfIntermediateProduct
		|			AND MultipliersOfSemiFinishedProducts.Series = CostsByType.Series
		|WHERE
		|	MultipliersOfSemiFinishedProducts.LotIsReleased
		|
		|GROUP BY
		|	MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|	MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariant,
		|	MultipliersOfSemiFinishedProducts.Purpose,
		|	MultipliersOfSemiFinishedProducts.LotProductBOM,
		|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	CostsByType.Cost_,
		|	CostsByType.CostCharacteristic,
		|	CostsByType.ThisIsASemiFinishedProduct,
		|	CostsByType.Count,
		|	CostsByType.Department,
		|	MultipliersOfSemiFinishedProducts.Series,
		|	MultipliersOfSemiFinishedProducts.KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PlannedProductionCosts.StandardCostEstimate AS StandardCostEstimate,
		|	PlannedProductionCosts.ManufacturedProduct AS ManufacturedProduct,
		|	PlannedProductionCosts.ItemVariant AS ItemVariant,
		|	PlannedProductionCosts.Purpose AS Purpose,
		|	PlannedProductionCosts.LotProductBOM AS LotProductBOM,
		|	PlannedProductionCosts.ManufacturedProduct AS SemiFinishedProduct,
		|	PlannedProductionCosts.ItemVariant AS ItemVariantsOfIntermediateProduct,
		|	PlannedProductionCosts.Cost_ AS Cost_,
		|	PlannedProductionCosts.Characteristic AS CostCharacteristic,
		|	PlannedProductionCosts.Count AS Count,
		|	CASE
		|		WHEN PlannedProductionCosts.ThisIsASemiFinishedProduct
		|			THEN 0
		|		ELSE PlannedProductionCosts.Cost
		|	END AS Cost,
		|	CASE
		|		WHEN PlannedProductionCosts.ThisIsASemiFinishedProduct
		|			THEN 0
		|		ELSE PlannedProductionCosts.OffBalanceCost
		|	END AS OffBalanceCost,
		|	CASE
		|		WHEN PlannedProductionCosts.Count = 0
		|			THEN 0
		|		ELSE PlannedProductionCosts.Cost / PlannedProductionCosts.Count
		|	END AS PricePlan,
		|	PlannedProductionCosts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	PlannedProductionCosts.Department AS Department,
		|	PlannedProductionCosts.ProductCostElement AS ProductCostElement,
		|	PlannedProductionCosts.Series AS Series,
		|	PlannedProductionCosts.KeyLot AS KeyLot
		|
		|INTO ScheduledData
		|FROM
		|	PlannedProductionCosts AS PlannedProductionCosts
		|WHERE
		|	NOT PlannedProductionCosts.Cost_ IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	PlannedCostsOfSemiFinishedProducts.StandardCostEstimate,
		|	PlannedCostsOfSemiFinishedProducts.ManufacturedProduct,
		|	PlannedCostsOfSemiFinishedProducts.ItemVariant,
		|	PlannedCostsOfSemiFinishedProducts.Purpose,
		|	PlannedCostsOfSemiFinishedProducts.LotProductBOM,
		|	PlannedCostsOfSemiFinishedProducts.SemiFinishedProduct,
		|	PlannedCostsOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	PlannedCostsOfSemiFinishedProducts.Products,
		|	PlannedCostsOfSemiFinishedProducts.Characteristic,
		|	PlannedCostsOfSemiFinishedProducts.Count,
		|	CASE
		|		WHEN PlannedCostsOfSemiFinishedProducts.ThisIsASemiFinishedProduct
		|			THEN 0
		|		ELSE PlannedCostsOfSemiFinishedProducts.Cost
		|	END,
		|	CASE
		|		WHEN PlannedCostsOfSemiFinishedProducts.ThisIsASemiFinishedProduct
		|			THEN 0
		|		ELSE PlannedCostsOfSemiFinishedProducts.OffBalanceCost
		|	END AS OffBalanceCost,
		|	CASE
		|		WHEN PlannedCostsOfSemiFinishedProducts.Count = 0
		|				OR NOT PlannedCostsOfSemiFinishedProducts.Price = 0
		|			THEN PlannedCostsOfSemiFinishedProducts.Price
		|		ELSE PlannedCostsOfSemiFinishedProducts.Cost / PlannedCostsOfSemiFinishedProducts.Count
		|	END,
		|	PlannedCostsOfSemiFinishedProducts.ThisIsASemiFinishedProduct,
		|	PlannedCostsOfSemiFinishedProducts.Department,
		|	PlannedCostsOfSemiFinishedProducts.ProductCostElement,
		|	PlannedCostsOfSemiFinishedProducts.Series,
		|	PlannedCostsOfSemiFinishedProducts.KeyLot AS KeyLot
		|FROM
		|	PlannedCostsOfSemiFinishedProducts AS PlannedCostsOfSemiFinishedProducts
		|WHERE
		|	NOT PlannedCostsOfSemiFinishedProducts.Products IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ScheduledData.StandardCostEstimate AS StandardCostEstimate,
		|	ScheduledData.ManufacturedProduct AS ManufacturedProduct,
		|	ScheduledData.ItemVariant AS ItemVariant,
		|	ScheduledData.Purpose AS Purpose,
		|	ScheduledData.LotProductBOM AS LotProductBOM,
		|	ScheduledData.SemiFinishedProduct AS SemiFinishedProduct,
		|	ScheduledData.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	ScheduledData.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	ScheduledData.Series AS Series,
		|	AVG(ScheduledData.PricePlan) AS PricePlan,
		|	ScheduledData.Cost_ AS Cost_,
		|	ScheduledData.CostCharacteristic AS CostCharacteristic
		|
		|INTO PlannedPricesOfSemiFinishedProducts
		|FROM
		|	ScheduledData AS ScheduledData
		|
		|GROUP BY
		|	ScheduledData.StandardCostEstimate,
		|	ScheduledData.ManufacturedProduct,
		|	ScheduledData.ItemVariant,
		|	ScheduledData.Purpose,
		|	ScheduledData.LotProductBOM,
		|	ScheduledData.SemiFinishedProduct,
		|	ScheduledData.ItemVariantsOfIntermediateProduct,
		|	ScheduledData.ThisIsASemiFinishedProduct,
		|	ScheduledData.Series,
		|	ScheduledData.Cost_,
		|	ScheduledData.CostCharacteristic
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	ItemVariant,
		|	Purpose,
		|	LotProductBOM,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Series,
		|	ThisIsASemiFinishedProduct,
		|	StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.StandardCostEstimate AS StandardCostEstimate,
		|	NestedQuery.ManufacturedProduct AS ManufacturedProduct,
		|	NestedQuery.ItemVariant AS ItemVariant,
		|	NestedQuery.Purpose AS AssignmentOfProducts,
		|	NestedQuery.ProductsBatch AS ProductsBatch,
		|	NestedQuery.SemiFinishedProduct AS SemiFinishedProduct,
		|	NestedQuery.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	NestedQuery.Cost_ AS Cost_,
		|	NestedQuery.CostCharacteristic AS CostCharacteristic,
		|	SUM(NestedQuery.Cost) AS Cost,
		|	SUM(NestedQuery.OffBalanceCost) AS CostOffBalanceSheetFact,
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.CountPlan) AS CountPlan,
		|	SUM(NestedQuery.CostPlan) AS CostPlan,
		|	SUM(NestedQuery.CostOffBalanceSheetPlan) AS CostOffBalanceSheetPlan,
		|	MAX(NestedQuery.PricePlan) AS PricePlan,
		|	MAX(NestedQuery.PriceActual) AS PriceActual,
		|	NestedQuery.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	CASE
		|		WHEN VALUETYPE(NestedQuery.StandardCostEstimate) = TYPE(Document.StandardCosting2_2)
		|				AND NOT NestedQuery.StandardCostEstimate = VALUE(Document.StandardCosting2_2.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CostingIsFound,
		|	NestedQuery.ProductCostElement AS ProductCostElement,
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.Department AS Department,
		|	NestedQuery.ExpenseType AS ExpenseType,
		|	NestedQuery.Series AS Series,
		|	MIN(NestedQuery.Level) AS Level,
		|	ISNULL(Products.UnitOfMeasure, ISNULL(EmployeeWorkKinds.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))) AS CostUnitOfMeasure
		|FROM
		|	(SELECT
		|		ActualData.StandardCostEstimate AS StandardCostEstimate,
		|		ActualData.ManufacturedProduct AS ManufacturedProduct,
		|		ActualData.ItemVariant AS ItemVariant,
		|		ActualData.Purpose AS Purpose,
		|		ActualData.ProductsBatch AS ProductsBatch,
		|		ActualData.SemiFinishedProduct AS SemiFinishedProduct,
		|		ActualData.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|		ActualData.Cost_ AS Cost_,
		|		ActualData.CostCharacteristic AS CostCharacteristic,
		|		AVG(CAST(ActualData.Price AS NUMBER(31,2))) AS PriceActual,
		|		SUM(CAST(ActualData.Cost AS NUMBER(31,2))) AS Cost,
		|		SUM(CAST(ActualData.OffBalanceCost AS NUMBER(31,2))) AS OffBalanceCost,
		|		SUM(CAST(ActualData.Count AS NUMBER(15, 3))) AS Count,
		|		MAX(CASE
		|				WHEN VALUETYPE(ActualData.Cost_) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
		|					THEN 0
		|				ELSE CAST(ISNULL(PlannedPricesOfSemiFinishedProducts.PricePlan, 0) AS NUMBER(31,2))
		|			END) AS PricePlan,
		|		0 AS CountPlan,
		|		0 AS CostPlan,
		|		0 AS CostOffBalanceSheetPlan,
		|		ActualData.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|		ActualData.Department AS Department,
		|		ActualData.Organization AS Organization,
		|		ActualData.ProductCostElement AS ProductCostElement,
		|		CASE
		|			WHEN VALUETYPE(ActualData.Cost_) = TYPE(Catalog.EmployeeWorkKinds)
		|				THEN ""LaborCosts""
		|			WHEN VALUETYPE(ActualData.Cost_) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
		|				THEN ""Itemized""
		|			WHEN VALUETYPE(ActualData.Cost_) = TYPE(Catalog.Products)
		|					AND ActualData.ThisIsASemiFinishedProduct
		|				THEN ""SemiFinishedProduct""
		|			ELSE ""Material_""
		|		END AS ExpenseType,
		|		ActualData.Series AS Series,
		|		ActualData.Level AS Level
		|	FROM
		|		ActualData AS ActualData
		|			LEFT JOIN PlannedPricesOfSemiFinishedProducts AS PlannedPricesOfSemiFinishedProducts
		|			ON ActualData.ManufacturedProduct = PlannedPricesOfSemiFinishedProducts.ManufacturedProduct
		|				AND ActualData.ItemVariant = PlannedPricesOfSemiFinishedProducts.ItemVariant
		|				AND ActualData.Purpose = PlannedPricesOfSemiFinishedProducts.Purpose
		|				AND ActualData.ProductsBatch = PlannedPricesOfSemiFinishedProducts.LotProductBOM
		|				AND ActualData.SemiFinishedProduct = PlannedPricesOfSemiFinishedProducts.SemiFinishedProduct
		|				AND ActualData.ItemVariantsOfIntermediateProduct = PlannedPricesOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct
		|				AND ActualData.Series = PlannedPricesOfSemiFinishedProducts.Series
		|				AND ActualData.ThisIsASemiFinishedProduct = PlannedPricesOfSemiFinishedProducts.ThisIsASemiFinishedProduct
		|				AND ActualData.StandardCostEstimate = PlannedPricesOfSemiFinishedProducts.StandardCostEstimate
		|				AND ActualData.Cost_ = PlannedPricesOfSemiFinishedProducts.Cost_
		|				AND ActualData.CostCharacteristic = PlannedPricesOfSemiFinishedProducts.CostCharacteristic
		|	
		|	GROUP BY
		|		ActualData.StandardCostEstimate,
		|		ActualData.ManufacturedProduct,
		|		ActualData.ItemVariant,
		|		ActualData.Purpose,
		|		ActualData.ProductsBatch,
		|		ActualData.SemiFinishedProduct,
		|		ActualData.ItemVariantsOfIntermediateProduct,
		|		ActualData.Cost_,
		|		ActualData.CostCharacteristic,
		|		ActualData.ThisIsASemiFinishedProduct,
		|		ActualData.Department,
		|		ActualData.Organization,
		|		ActualData.ProductCostElement,
		|		CASE
		|			WHEN VALUETYPE(ActualData.Cost_) = TYPE(Catalog.EmployeeWorkKinds)
		|				THEN ""LaborCosts""
		|			WHEN VALUETYPE(ActualData.Cost_) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
		|				THEN ""Itemized""
		|			WHEN VALUETYPE(ActualData.Cost_) = TYPE(Catalog.Products)
		|					AND ActualData.ThisIsASemiFinishedProduct
		|				THEN ""SemiFinishedProduct""
		|			ELSE ""Material_""
		|		END,
		|		ActualData.Series,
		|		ActualData.Level
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ScheduledData.StandardCostEstimate,
		|		ScheduledData.ManufacturedProduct,
		|		ScheduledData.ItemVariant,
		|		ScheduledData.Purpose,
		|		ScheduledData.LotProductBOM,
		|		ScheduledData.SemiFinishedProduct,
		|		ScheduledData.ItemVariantsOfIntermediateProduct,
		|		ScheduledData.Cost_,
		|		ScheduledData.CostCharacteristic,
		|		0,
		|		0,
		|		0,
		|		0,
		|		CAST(ScheduledData.PricePlan AS NUMBER(31,2)),
		|		CAST(ScheduledData.Count AS NUMBER(15, 3)),
		|		CAST(ScheduledData.Cost AS NUMBER(31,2)),
		|		CAST(ScheduledData.OffBalanceCost AS NUMBER(31,2)),
		|		ScheduledData.ThisIsASemiFinishedProduct,
		|		ScheduledData.Department,
		|		ScheduledData.StandardCostEstimate.Organization,
		|		ScheduledData.ProductCostElement,
		|		CASE
		|			WHEN VALUETYPE(ScheduledData.Cost_) = TYPE(Catalog.EmployeeWorkKinds)
		|				THEN ""LaborCosts""
		|			WHEN VALUETYPE(ScheduledData.Cost_) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
		|				THEN ""Itemized""
		|			WHEN VALUETYPE(ScheduledData.Cost_) = TYPE(Catalog.Products)
		|					AND ScheduledData.ThisIsASemiFinishedProduct
		|				THEN ""SemiFinishedProduct""
		|			ELSE ""Material_""
		|		END,
		|		ScheduledData.Series,
		|		9999
		|	FROM
		|		ScheduledData AS ScheduledData) AS NestedQuery
		|		LEFT JOIN Catalog.Products AS Products
		|		ON NestedQuery.Cost_ = Products.Ref
		|		LEFT JOIN Catalog.EmployeeWorkKinds AS EmployeeWorkKinds
		|		ON NestedQuery.Cost_ = EmployeeWorkKinds.Ref
		|
		|GROUP BY
		|	NestedQuery.ItemVariant,
		|	NestedQuery.ManufacturedProduct,
		|	NestedQuery.ItemVariantsOfIntermediateProduct,
		|	NestedQuery.Purpose,
		|	NestedQuery.Cost_,
		|	NestedQuery.ProductsBatch,
		|	NestedQuery.StandardCostEstimate,
		|	NestedQuery.SemiFinishedProduct,
		|	NestedQuery.CostCharacteristic,
		|	NestedQuery.ThisIsASemiFinishedProduct,
		|	NestedQuery.ProductCostElement,
		|	NestedQuery.Organization,
		|	NestedQuery.Department,
		|	NestedQuery.ExpenseType,
		|	NestedQuery.Series,
		|	ISNULL(Products.UnitOfMeasure, ISNULL(EmployeeWorkKinds.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.StandardCostEstimate AS StandardCostEstimate,
		|	NestedQuery.ManufacturedProduct AS ManufacturedProduct,
		|	NestedQuery.ItemVariant AS ItemVariant,
		|	NestedQuery.Purpose AS AssignmentOfProducts,
		|	NestedQuery.ProductsBatch AS ProductsBatch,
		|	NestedQuery.SemiFinishedProduct AS SemiFinishedProduct,
		|	NestedQuery.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	SUM(NestedQuery.QuantityRelease) AS QuantityRelease,
		|	&FactPresentation AS FactPresentation,
		|	&PlanPresentation AS PlanPresentation,
		|	MAX(NestedQuery.QuantityReleasePlan) AS QuantityReleasePlan,
		|	NestedQuery.Series AS Series
		|FROM
		|	(SELECT
		|		ProductAndOrderCalculations.StandardCostEstimate AS StandardCostEstimate,
		|		ReleasedQuantity.ManufacturedProduct AS ManufacturedProduct,
		|		ReleasedQuantity.ItemVariant AS ItemVariant,
		|		ReleasedQuantity.Purpose AS Purpose,
		|		ReleasedQuantity.ProductsBatch AS ProductsBatch,
		|		ReleasedQuantity.SemiFinishedProduct AS SemiFinishedProduct,
		|		ReleasedQuantity.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|		SUM(CAST(ReleasedQuantity.Count AS NUMBER(15, 3))) AS QuantityRelease,
		|		0 AS QuantityReleasePlan,
		|		ReleasedQuantity.Series AS Series
		|	FROM
		|		ReleasedQuantity AS ReleasedQuantity
		|		LEFT JOIN ProductAndOrderCalculations AS ProductAndOrderCalculations
		|		ON ProductAndOrderCalculations.ManufacturedProduct = ReleasedQuantity.ManufacturedProduct
		|			AND ProductAndOrderCalculations.ItemVariant = ReleasedQuantity.ItemVariant
		|			AND ProductAndOrderCalculations.Lot = ReleasedQuantity.ProductsBatch
		|			AND ProductAndOrderCalculations.Organization = ReleasedQuantity.Organization
		|			AND ProductAndOrderCalculations.Series = ReleasedQuantity.Series
		|			AND ProductAndOrderCalculations.AssignmentOfProducts = ReleasedQuantity.Purpose
		|	
		|	GROUP BY
		|		ProductAndOrderCalculations.StandardCostEstimate,
		|		ReleasedQuantity.ManufacturedProduct,
		|		ReleasedQuantity.ItemVariant,
		|		ReleasedQuantity.Purpose,
		|		ReleasedQuantity.ProductsBatch,
		|		ReleasedQuantity.SemiFinishedProduct,
		|		ReleasedQuantity.ItemVariantsOfIntermediateProduct,
		|		ReleasedQuantity.Series
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|		MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|		MultipliersOfSemiFinishedProducts.ItemVariant,
		|		MultipliersOfSemiFinishedProducts.Purpose,
		|		MultipliersOfSemiFinishedProducts.LotProductBOM,
		|		MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|		MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|		0,
		|		SUM(CAST(MultipliersOfSemiFinishedProducts.QuantityOfSemiFinishedProduct AS NUMBER(15, 3))),
		|		MultipliersOfSemiFinishedProducts.Series
		|	FROM
		|		MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
		|	WHERE
		|		NOT MultipliersOfSemiFinishedProducts.ThisIsOutput_
		|		
		|	GROUP BY
		|		MultipliersOfSemiFinishedProducts.StandardCostEstimate,
		|		MultipliersOfSemiFinishedProducts.ManufacturedProduct,
		|		MultipliersOfSemiFinishedProducts.ItemVariant,
		|		MultipliersOfSemiFinishedProducts.Purpose,
		|		MultipliersOfSemiFinishedProducts.LotProductBOM,
		|		MultipliersOfSemiFinishedProducts.SemiFinishedProduct,
		|		MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|		MultipliersOfSemiFinishedProducts.Series
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductMultipliers.StandardCostEstimate,
		|		ProductMultipliers.ManufacturedProduct,
		|		ProductMultipliers.ItemVariant,
		|		ProductMultipliers.Purpose,
		|		ProductMultipliers.LotProductBOM,
		|		ProductMultipliers.ManufacturedProduct,
		|		ProductMultipliers.ItemVariant,
		|		0,
		|		SUM(CAST(ProductMultipliers.QuantityOfSemiFinishedProduct AS NUMBER(15, 3))),
		|		ProductMultipliers.Series
		|	FROM
		|		ProductMultipliers AS ProductMultipliers
		|	
		|	GROUP BY
		|		ProductMultipliers.StandardCostEstimate,
		|		ProductMultipliers.ManufacturedProduct,
		|		ProductMultipliers.ItemVariant,
		|		ProductMultipliers.Purpose,
		|		ProductMultipliers.LotProductBOM,
		|		ProductMultipliers.Series) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.ItemVariant,
		|	NestedQuery.ManufacturedProduct,
		|	NestedQuery.ItemVariantsOfIntermediateProduct,
		|	NestedQuery.Purpose,
		|	NestedQuery.ProductsBatch,
		|	NestedQuery.StandardCostEstimate,
		|	NestedQuery.SemiFinishedProduct,
		|	NestedQuery.Series";
	
#EndRegion

	ResultsArray = Query.ExecuteBatch();
	ExternalDataSets = New Structure();
	ExternalDataSets.Insert("Real", ResultsArray[ResultsArray.Count() - 2].Unload());
	ExternalDataSets.Insert("Releases", ResultsArray[ResultsArray.Count() - 1].Unload());
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	PrintWarningAboutRestrictionsOnUseOfReport(BeginOfPeriod,
		EndOfPeriod,
		ResultDocument);
		
	OutputProcessor.Output(CompositionProcessor);
			
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
	
	If VariantKey = "PlannedAndActualCostsOfRedistributionOfEnterprise" Then
		
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
		
	ElsIf VariantKey = "PlannedAndActualCostsOfRedistributionOfOrganization" Then	
		
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

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseItemVariants") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "ItemVariant");
	EndIf;
	
	DataCompositionServer.ClearStructureByFunctionalOptions(FormSettingsComposer.Settings.Structure, FieldsToDeleteByFederalDistrict());
	
EndProcedure

Function FieldsToDeleteByFederalDistrict()
	
	FieldsToDelete__ = New Array;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		
		FieldsToDelete__.Add(New DataCompositionField("ItemVariant"));
		FieldsToDelete__.Add(New DataCompositionField("ItemVariantsOfIntermediateProduct"));
		FieldsToDelete__.Add(New DataCompositionField("CostCharacteristic"));
		
	EndIf;
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		FieldsToDelete__.Add(New DataCompositionField("Series"));
	EndIf;
	
	Return FieldsToDelete__;
	
EndFunction

Procedure PrintWarningAboutRestrictionsOnUseOfReport(BeginOfPeriod, EndOfPeriod, ResultDocument)
	
	WarningText = CostCalculationAppliedAlgorithms.WarningTextUnsupportedOrganizations(BeginOfPeriod, EndOfPeriod, SettingsComposer);
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

#EndRegion

#EndIf