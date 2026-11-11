
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	DataSet = DataCompositionSchema.DataSets.DataSet1;
	DataSet.Query = QueryText_PlannedCostOfManufacturedProducts();
	
EndProcedure
#EndRegion

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
	FormParametersSelection = ThisForm.ParametersForm.Filter;	// Structure
	
	If ThisForm.ParametersForm.Filter.Property("Period")
		And Not TypeOf(ThisForm.ParametersForm.Filter.Period) = Type("Date") Then
		FormParametersSelection.Delete("Period");
	EndIf;
	
	If ThisForm.ParametersForm.Filter.Property("ProductsBatch") Then
		FormParametersSelection.Delete("ProductsBatch");
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.Parameters.Filter.Insert("StandardCostEstimate", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
Function QueryText_PlannedCostOfManufacturedProducts()
	
	QueriesTexts = New Array();
	QueryText = "SELECT ALLOWED DISTINCT
	|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS LotProductBOM,
	|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
	|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant AS ItemVariant,
	|	MultiplesOfLotsAndSemiFinishedProducts.Purpose AS Purpose,
	|	MAX(MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.Date) AS Period
	|INTO CalculationPeriods
	|FROM
	|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
	|WHERE
	|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.Date <= ENDOFPERIOD(&Period, DAY)
	|	OR &Period = DATETIME(1, 1, 1)
	|{WHERE
	|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.*}
	|GROUP BY
	|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant,
	|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct,
	|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
	|	MultiplesOfLotsAndSemiFinishedProducts.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CalculationPeriods.LotProductBOM AS LotProductBOM,
	|	CalculationPeriods.ManufacturedProduct AS ManufacturedProduct,
	|	CalculationPeriods.ItemVariant AS ItemVariant,
	|	CalculationPeriods.Purpose AS Purpose,
	|	MAX(MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate) AS StandardCostEstimate
	|INTO RecentCalculations
	|FROM
	|	CalculationPeriods AS CalculationPeriods
	|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
	|		ON CalculationPeriods.Period = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.Date
	|		AND CalculationPeriods.LotProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM
	|		AND CalculationPeriods.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
	|		AND CalculationPeriods.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
	|		AND CalculationPeriods.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
	|{WHERE
	|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.*}
	|GROUP BY
	|	CalculationPeriods.LotProductBOM,
	|	CalculationPeriods.ManufacturedProduct,
	|	CalculationPeriods.ItemVariant,
	|	CalculationPeriods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RecentCalculations.StandardCostEstimate AS StandardCostEstimate,
	|	RecentCalculations.ManufacturedProduct AS ManufacturedProduct,
	|	RecentCalculations.ItemVariant AS ItemVariant,
	|	RecentCalculations.Purpose AS Purpose,
	|	SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct) AS CountTotal
	|INTO CalculatedCount
	|FROM
	|	RecentCalculations AS RecentCalculations
	|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
	|		ON RecentCalculations.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
	|		AND RecentCalculations.LotProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM
	|		AND RecentCalculations.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
	|		AND RecentCalculations.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
	|		AND RecentCalculations.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
	|		AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
	|GROUP BY
	|	RecentCalculations.StandardCostEstimate,
	|	RecentCalculations.ManufacturedProduct,
	|	RecentCalculations.ItemVariant,
	|	RecentCalculations.Purpose
	|";
	
	QueriesTexts.Add(QueryText);
	QueriesTexts.Add(Reports.ProductCostEstimate.QueryText_ProductStandardCostData(False));
	QueryText = "
	|SELECT
	|	Data.ThisIsOutput_ AS ThisIsOutput_,
	|	Data.CostObject AS CostObject,
	|	Data.StandardCostEstimate AS StandardCostEstimate,
	|	Data.ManufacturedProduct AS ManufacturedProduct,
	|	Data.ItemVariant AS ItemVariant,
	|	Data.Department AS Department,
	|	Data.ProductCostElement AS ProductCostElement,
	|	Data.Products AS Products,
	|	Data.Characteristic AS Characteristic,
	|	Data.ExpenseType,
	|	SUM(Data.Count) AS Count,
	|	SUM(CASE
	|		WHEN Data.ThisIsASemiFinishedProduct
	|			THEN 0
	|		ELSE Data.Cost
	|	END) AS Cost,
	|	SUM(CASE
	|		WHEN (Data.ExpenseType = ""Material_""
	|		OR Data.ExpenseType = ""RecyclableWaste"")
	|		AND NOT Data.ThisIsASemiFinishedProduct
	|			THEN Data.Cost
	|		ELSE 0
	|	END) AS CostOfMaterial,
	|	SUM(CASE
	|		WHEN Data.ExpenseType = ""LaborCosts""
	|		AND NOT Data.ThisIsASemiFinishedProduct
	|			THEN Data.Cost
	|		ELSE 0
	|	END) AS CostLaborCosts,
	|	SUM(CASE
	|		WHEN Data.ExpenseType = ""OtherPermanent""
	|		AND NOT Data.ThisIsASemiFinishedProduct
	|			THEN Data.Cost
	|		ELSE 0
	|	END) AS CostOtherFixed,
	|	SUM(CASE
	|		WHEN Data.ExpenseType = ""OtherVariables""
	|		AND NOT Data.ThisIsASemiFinishedProduct
	|			THEN Data.Cost
	|		ELSE 0
	|	END) AS CostOtherVariable,
	|	CASE
	|		WHEN Data.ThisIsASemiFinishedProduct
	|			THEN MAX(ISNULL(Prices.Price, 0))
	|		WHEN SUM(Data.Count) = 0
	|			THEN 0
	|		ELSE SUM(Data.Cost) / SUM(Data.Count)
	|	END AS Price,
	|	SUM(Data.OffBalanceSheet) AS OffBalanceCost,
	|	Data.ManufacturedProduct.UnitOfMeasure AS ProductsUnitOfMeasurement_3,
	|	Data.Products.UnitOfMeasure AS ProductsUnitOfMeasure,
	|	Data.LotProductBOM AS ProductsBatch,
	|	Data.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Data.SemiFinishedProduct AS SemiFinishedProduct,
	|	Data.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|	Data.Purpose AS AssignmentOfProducts,
	|	Data.SemiFinishedProduct.UnitOfMeasure AS SemiFinishedProductUnitOfMeasurement,
	|	Data.StandardCostEstimate.Organization AS Organization,
	|	Data.Order AS Order,
	|	Data.LotProductBOM,
	|	0 AS ReleasedQuantity,
	|	Data.KeyLot
	|FROM
	|	Data AS Data
	|		LEFT JOIN PricesOfSemiFinishedProducts AS Prices
	|		ON Data.CostObject = Prices.CostObject
	|		AND Data.StandardCostEstimate = Prices.StandardCostEstimate
	|		AND Data.ManufacturedProduct = Prices.ManufacturedProduct
	|		AND Data.ItemVariant = Prices.ItemVariant
	|		AND Data.LotProductBOM = Prices.ProductsBatch
	|		AND Data.Products = Prices.SemiFinishedProduct
	|		AND Data.Characteristic = Prices.ItemVariantsOfIntermediateProduct
	|		AND Data.Purpose = Prices.AssignmentOfProducts
	|GROUP BY
	|	Data.ThisIsOutput_,
	|	Data.CostObject,
	|	Data.Characteristic,
	|	Data.ManufacturedProduct.UnitOfMeasure,
	|	Data.StandardCostEstimate,
	|	Data.ManufacturedProduct,
	|	Data.Products,
	|	Data.Department,
	|	Data.Products.UnitOfMeasure,
	|	Data.ItemVariant,
	|	Data.ExpenseType,
	|	Data.ProductCostElement,
	|	Data.QuantityOfSemiFinishedProduct,
	|	Data.LotProductBOM,
	|	Data.ThisIsASemiFinishedProduct,
	|	Data.SemiFinishedProduct,
	|	Data.ItemVariantsOfIntermediateProduct,
	|	Data.Purpose,
	|	Data.SemiFinishedProduct.UnitOfMeasure,
	|	Data.StandardCostEstimate.Organization,
	|	Data.Order,
	|	Data.KeyLot
	|
	|UNION ALL
	|
	|SELECT
	|	ActualCosts.ThisIsOutput_ AS ThisIsOutput_,
	|	ActualCosts.CostObject AS CostObject,
	|	ActualCosts.StandardCostEstimate,
	|	ActualCosts.ManufacturedProduct,
	|	ActualCosts.ItemVariant,
	|	ActualCosts.Department,
	|	ActualCosts.ProductCostElement,
	|	ActualCosts.Products,
	|	ActualCosts.Characteristic,
	|	ActualCosts.ExpenseType,
	|	ActualCosts.Count,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			THEN ActualCosts.Cost
	|		WHEN DefinitionOfSemiFinishedProducts.FixedCost
	|			THEN 0
	|		ELSE DefinitionOfSemiFinishedProducts.Cost * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
	|	END,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			AND ActualCosts.ExpenseType = ""Material_""
	|				THEN ActualCosts.Cost
	|		WHEN DefinitionOfSemiFinishedProducts.FixedCost
	|			THEN 0
	|		WHEN ActualCosts.ExpenseType = ""Material_""
	|			THEN DefinitionOfSemiFinishedProducts.CostOfMaterial * ActualCosts.Count /
	|				DefinitionOfSemiFinishedProducts.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			AND ActualCosts.ExpenseType = ""LaborCosts""
	|				THEN ActualCosts.Cost
	|		WHEN DefinitionOfSemiFinishedProducts.FixedCost
	|			AND ActualCosts.ExpenseType = ""LaborCosts""
	|				THEN 0
	|		WHEN ActualCosts.ExpenseType = ""LaborCosts""
	|			THEN DefinitionOfSemiFinishedProducts.CostLaborCosts * ActualCosts.Count /
	|				DefinitionOfSemiFinishedProducts.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			AND ActualCosts.ExpenseType = ""OtherPermanent""
	|				THEN ActualCosts.Cost
	|		WHEN DefinitionOfSemiFinishedProducts.FixedCost
	|			AND ActualCosts.ExpenseType = ""OtherPermanent""
	|				THEN 0
	|		WHEN ActualCosts.ExpenseType = ""OtherPermanent""
	|			THEN DefinitionOfSemiFinishedProducts.CostOtherFixed * ActualCosts.Count /
	|				DefinitionOfSemiFinishedProducts.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			AND ActualCosts.ExpenseType = ""OtherVariables""
	|				THEN ActualCosts.Cost
	|		WHEN DefinitionOfSemiFinishedProducts.FixedCost
	|			AND ActualCosts.ExpenseType = ""OtherVariables""
	|				THEN 0
	|		WHEN ActualCosts.ExpenseType = ""OtherVariables""
	|			THEN DefinitionOfSemiFinishedProducts.CostOtherVariable * ActualCosts.Count /
	|				DefinitionOfSemiFinishedProducts.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			THEN CASE
	|				WHEN ActualCosts.Count = 0
	|					THEN 0
	|				ELSE ActualCosts.Cost / ActualCosts.Count
	|			END
	|		ELSE DefinitionOfSemiFinishedProducts.Cost * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count /
	|			ActualCosts.Count
	|	END AS Price,
	|	CASE
	|		WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
	|			THEN ActualCosts.OffBalanceSheet
	|		WHEN DefinitionOfSemiFinishedProducts.FixedCost
	|			THEN 0
	|		ELSE DefinitionOfSemiFinishedProducts.OffBalanceCost * ActualCosts.Count /
	|			DefinitionOfSemiFinishedProducts.Count
	|	END AS OffBalanceCost,
	|	ActualCosts.ManufacturedProduct.UnitOfMeasure,
	|	ActualCosts.Products.UnitOfMeasure,
	|	ActualCosts.LotProductBOM,
	|	NOT DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL,
	|	ActualCosts.SemiFinishedProduct,
	|	ActualCosts.ItemVariantsOfIntermediateProduct,
	|	ActualCosts.Purpose,
	|	ActualCosts.SemiFinishedProduct.UnitOfMeasure,
	|	ActualCosts.StandardCostEstimate.Organization,
	|	ActualCosts.Order,
	|	ActualCosts.LotProductBOM,
	|	0,
	|	ISNULL(DefinitionOfSemiFinishedProducts.KeyLot, ActualCosts.KeyLot)
	|FROM
	|	ActualCosts AS ActualCosts
	|		LEFT JOIN DefinitionOfSemiFinishedProducts AS DefinitionOfSemiFinishedProducts
	|		ON ActualCosts.CostObject = DefinitionOfSemiFinishedProducts.CostObject
	|		AND ActualCosts.ItemsLocationAttributes = DefinitionOfSemiFinishedProducts.ItemsLocationAttributes
	|		AND CASE
	|			WHEN ActualCosts.ThisIsOutput_
	|				THEN ActualCosts.LotProductBOM = DefinitionOfSemiFinishedProducts.LotProductBOM
	|			ELSE ActualCosts.SemiFinishedProductLot = DefinitionOfSemiFinishedProducts.LotProductBOM
	|		END
	|		AND DefinitionOfSemiFinishedProducts.KeyLot = ActualCosts.KeyLot
	|
	|UNION ALL
	|
	|SELECT
	|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef) AS ThisIsOutput_,
	|	SharesOfValueFromCalculatedQuantity.CostObject AS CostObject,
	|	SharesOfValueFromCalculatedQuantity.StandardCostEstimate,
	|	SharesOfValueFromCalculatedQuantity.ManufacturedProduct,
	|	SharesOfValueFromCalculatedQuantity.ItemVariant,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	SharesOfValueFromCalculatedQuantity.ManufacturedProduct.UnitOfMeasure,
	|	NULL,
	|	NULL,
	|	NOT MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef),
	|	SemiFinishedProducts_.Ref,
	|	CASE
	|		WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
	|			THEN MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
	|		ELSE MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
	|	END,
	|	SharesOfValueFromCalculatedQuantity.Purpose,
	|	SemiFinishedProducts_.UnitOfMeasure,
	|	NULL,
	|	NULL,
	|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
	|	SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct * SharesOfValueFromCalculatedQuantity.CostShare),
	|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot
	|FROM
	|	SharesOfValueFromCalculatedQuantity AS SharesOfValueFromCalculatedQuantity
	|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
	|		ON SharesOfValueFromCalculatedQuantity.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
	|		AND SharesOfValueFromCalculatedQuantity.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
	|		AND
	|			SharesOfValueFromCalculatedQuantity.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
	|		AND SharesOfValueFromCalculatedQuantity.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
	|		
	|		INNER JOIN Catalog.Products AS SemiFinishedProducts_
	|		ON SemiFinishedProducts_.Ref = CASE
	|			WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
	|				THEN MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
	|			ELSE MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct
	|		END
	|GROUP BY
	|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef),
	|	NOT MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef),
	|	SharesOfValueFromCalculatedQuantity.CostObject,
	|	SharesOfValueFromCalculatedQuantity.StandardCostEstimate,
	|	SharesOfValueFromCalculatedQuantity.ManufacturedProduct,
	|	SharesOfValueFromCalculatedQuantity.ItemVariant,
	|	SemiFinishedProducts_.Ref,
	|	CASE
	|		WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
	|			THEN MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
	|		ELSE MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
	|	END,
	|	SharesOfValueFromCalculatedQuantity.Purpose,
	|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
	|	SemiFinishedProducts_.UnitOfMeasure,
	|	SharesOfValueFromCalculatedQuantity.ManufacturedProduct.UnitOfMeasure,
	|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot";
	
	QueriesTexts.Add(QueryText);
	
	Result = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Return Result;
EndFunction
#EndRegion

#EndIf