
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
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		Parameters.Filter.Insert("StandardCostEstimate", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "UseLaborGradesOfEmployeeActivityRates",
		GetFunctionalOption("UseLaborGradesOfEmployeeActivityRates"));
	

	DataSet = DataCompositionSchema.DataSets.DataSet1;
	DataSet.Query = QueryTextOfReportErrorsInCalculationOfProductCalculation();
	
	PriceManagementSystem.SetVSKDPricingOption(SettingsComposer);
	
EndProcedure

Function QueryTextOfReportErrorsInCalculationOfProductCalculation()
	
	ArrayOfRequestTexts = New Array();
	QueryText = "
	|SELECT
	|	PlannedMaterialCosts.StandardCostEstimate AS StandardCostEstimate,
	|	PlannedMaterialCosts.Products AS Products,
	|	PlannedMaterialCosts.Characteristic AS Characteristic,
	|	ISNULL(CASE
	|			WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|				THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|			ELSE PlannedMaterialCosts.Characteristic.ItemsCharacteristicForPricing
	|		END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
	|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage,
	|	PlannedMaterialCosts.Period AS Period
	|INTO ProductsForPrices
	|FROM
	|	AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (ItemKinds.Ref = PlannedMaterialCosts.Products.ProductKind)
	|WHERE
	|	NOT PlannedMaterialCosts.ThisIsASemiFinishedProduct
	|	AND (PlannedMaterialCosts.StandardCostEstimate = &StandardCostEstimate)
	|
	|GROUP BY
	|	PlannedMaterialCosts.StandardCostEstimate,
	|	PlannedMaterialCosts.Products,
	|	PlannedMaterialCosts.Characteristic,
	|	ISNULL(CASE
	|			WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|				THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|			ELSE PlannedMaterialCosts.Characteristic.ItemsCharacteristicForPricing
	|		END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)),
	|	PlannedMaterialCosts.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsForPrices.StandardCostEstimate AS StandardCostEstimate,
	|	ProductsForPrices.Products AS Products,
	|	ProductsForPrices.Characteristic AS Characteristic,
	|	ProductsForPrices.PricingVariant AS PricingVariant,
	|	ProductsForPrices.PricingBatch AS PricingBatch,
	|	ProductsForPrices.PricingPackage AS PricingPackage,
	|	ProductsForPrices.Period AS Period,
	|	MAX(ItemsPrices.Period) AS PricePeriod
	|INTO AveragePriceDates
	|FROM
	|	ProductsForPrices AS ProductsForPrices
	|		LEFT JOIN InformationRegister.ItemsPrices AS ItemsPrices
	|		ON (ItemsPrices.Products = ProductsForPrices.Products)
	|			AND (ItemsPrices.Characteristic = ProductsForPrices.Characteristic)
	|			AND (ItemsPrices.PriceKind = ProductsForPrices.StandardCostEstimate.PriceKind)
	|			AND ProductsForPrices.Period >= ItemsPrices.Period
	|WHERE
	|	NOT &UsePriceManagementSystem25
	|	
	|GROUP BY
	|	ProductsForPrices.StandardCostEstimate,
	|	ProductsForPrices.Period,
	|	ProductsForPrices.Characteristic,
	|	ProductsForPrices.PricingVariant,
	|	ProductsForPrices.PricingBatch,
	|	ProductsForPrices.PricingPackage,
	|	ProductsForPrices.Products
	|
	|UNION ALL
	|
	|SELECT
	|	ProductsForPrices.StandardCostEstimate,
	|	ProductsForPrices.Products,
	|	ProductsForPrices.Characteristic,
	|	ProductsForPrices.PricingVariant AS PricingVariant,
	|	ProductsForPrices.PricingBatch AS PricingBatch,
	|	ProductsForPrices.PricingPackage AS PricingPackage,
	|	ProductsForPrices.Period,
	|	MAX(ItemsPrices25.Period)
	|FROM
	|	ProductsForPrices AS ProductsForPrices
	|		LEFT JOIN InformationRegister.ItemsPrices25 AS ItemsPrices25
	|		ON (ItemsPrices25.Products = ProductsForPrices.Products)
	|		AND (ItemsPrices25.PricingVariant = ProductsForPrices.PricingVariant)
	|		AND (ItemsPrices25.PricingBatch = ProductsForPrices.PricingBatch)
	|		AND (ItemsPrices25.PricingPackage = ProductsForPrices.PricingPackage)
	|		AND (ItemsPrices25.PriceKind = ProductsForPrices.StandardCostEstimate.PriceKind)
	|		AND ProductsForPrices.Period >= ItemsPrices25.Period
	|			
	|WHERE
	|	&UsePriceManagementSystem25
	|
	|GROUP BY
	|	ProductsForPrices.StandardCostEstimate,
	|	ProductsForPrices.Period,
	|	ProductsForPrices.PricingVariant,
	|	ProductsForPrices.PricingBatch,
	|	ProductsForPrices.PricingPackage,
	|	ProductsForPrices.Characteristic,
	|	ProductsForPrices.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AveragePriceDates.StandardCostEstimate AS StandardCostEstimate,
	|	AveragePriceDates.Products AS Products,
	|	AveragePriceDates.Characteristic AS Characteristic,
	|	AveragePriceDates.Period AS Period,
	|	ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	ISNULL(ItemsPrices.Price, 0) AS Price,
	|	ItemsPrices.Currency AS Currency
	|INTO ItemsPrices
	|FROM
	|	AveragePriceDates AS AveragePriceDates
	|		LEFT JOIN InformationRegister.ItemsPrices AS ItemsPrices
	|		ON AveragePriceDates.Products = ItemsPrices.Products
	|			AND AveragePriceDates.Characteristic = ItemsPrices.Characteristic
	|			AND (ItemsPrices.PriceKind = AveragePriceDates.StandardCostEstimate.PriceKind)
	|			AND AveragePriceDates.PricePeriod = ItemsPrices.Period
	|WHERE
	|	NOT &UsePriceManagementSystem25
	|
	|UNION ALL
	|
	|SELECT
	|	AveragePriceDates.StandardCostEstimate,
	|	AveragePriceDates.Products,
	|	AveragePriceDates.Characteristic,
	|	AveragePriceDates.Period,
	|	ISNULL(ItemsPrices25.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ISNULL(ItemsPrices25.Price, 0),
	|	ItemsPrices25.Currency
	|FROM
	|	AveragePriceDates AS AveragePriceDates
	|		LEFT JOIN InformationRegister.ItemsPrices25 AS ItemsPrices25
	|		ON AveragePriceDates.Products = ItemsPrices25.Products
	|			AND AveragePriceDates.PricingVariant = ItemsPrices25.PricingVariant
	|			AND AveragePriceDates.PricingBatch = ItemsPrices25.PricingBatch
	|			AND AveragePriceDates.PricingPackage = ItemsPrices25.PricingPackage
	|			AND (ItemsPrices25.PriceKind = AveragePriceDates.StandardCostEstimate.PriceKind)
	|			AND AveragePriceDates.PricePeriod = ItemsPrices25.Period
	|WHERE
	|	&UsePriceManagementSystem25";
	
	ArrayOfRequestTexts.Add(QueryText);
	ArrayOfRequestTexts.Add(AccumulationRegisters.PlannedLaborCosts.QueryTextOfLaborCostsPricing(True));
	
	QueryText = "
	|SELECT DISTINCT
	|	PlannedMaterialCosts.Period AS Period,
	|	PlannedMaterialCosts.Department AS Department,
	|	PlannedMaterialCosts.StandardCostEstimate AS StandardCostEstimate,
	|	PlannedMaterialCosts.Products AS Products,
	|	PlannedMaterialCosts.Characteristic AS Characteristic,
	|	""UsedMaterials"" AS ExpenseType
	|FROM
	|	AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
	|		LEFT JOIN ItemsPrices AS ItemsPrices
	|		ON PlannedMaterialCosts.StandardCostEstimate = ItemsPrices.StandardCostEstimate
	|			AND PlannedMaterialCosts.Products = ItemsPrices.Products
	|			AND PlannedMaterialCosts.Characteristic = ItemsPrices.Characteristic
	|			AND PlannedMaterialCosts.Period = ItemsPrices.Period
	|WHERE
	|	NOT PlannedMaterialCosts.ThisIsASemiFinishedProduct
	|	AND ISNULL(ItemsPrices.Price, 0) = 0
	|	AND (PlannedMaterialCosts.StandardCostEstimate = &StandardCostEstimate)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	PlannedLaborCosts.Period AS Period,
	|	PlannedLaborCosts.Department AS Department,
	|	PlannedLaborCosts.StandardCostEstimate,
	|	PlannedLaborCosts.WorkKind,
	|	UNDEFINED,
	|	""LaborCosts""
	|FROM
	|	AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
	|		LEFT JOIN Rates AS Rates
	|		ON PlannedLaborCosts.StandardCostEstimate = Rates.StandardCostEstimate
	|			AND PlannedLaborCosts.WorkKind = Rates.WorkKind
	|			AND PlannedLaborCosts.Period = Rates.Period
	|			AND PlannedLaborCosts.Department = Rates.Department
	|WHERE
	|	ISNULL(Rates.Rate_, 0) = 0
	|	AND (PlannedLaborCosts.StandardCostEstimate = &StandardCostEstimate)";
	
	ArrayOfRequestTexts.Add(QueryText);
	
	Return StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
EndFunction

#EndRegion

#EndIf