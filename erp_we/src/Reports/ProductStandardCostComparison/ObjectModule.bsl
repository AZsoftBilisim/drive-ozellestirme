
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
	Settings.Events.BeforeFormationReport = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - Client Application Form - report Form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form Extension for the report.Prizagruzkepusersing settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCUserSettings) Export
	
	Parameters = ThisForm.ParametersForm;
	If Parameters.Property("CostObjectSelection") Then
		CostObjectSelection = Parameters.CostObjectSelection;
		FormSettingsComposer = ThisForm.Report.SettingsComposer;
		
		CostObjectSelectionOfMON = GetSelectionItemByName(FormSettingsComposer,
			FormSettingsComposer.UserSettings, "CostObject");
		
		CostObjectSelectionOfMON.Use = True;
		CostObjectSelectionOfMON.ComparisonType = DataCompositionComparisonType.Equal;
		CostObjectSelectionOfMON.RightValue = CostObjectSelection;
		
		NewDCUserSettings = FormSettingsComposer.UserSettings;
	EndIf;
		
EndProcedure

// Before Generating The Report
//
// Parameters:
//   ReportForm - ClientApplicationForm
//   AdditionalParameters - Structure:
//     * WarningText - String
//     * StorageParameterNameWarningDisclaimer - String
//
Procedure BeforeFormationReport(ReportForm, AdditionalParameters) Export
	FormSettingsComposer = ReportForm.Report.SettingsComposer;
	CostObjectSelection = GetSelectionItemByName(FormSettingsComposer,
		FormSettingsComposer.UserSettings, "CostObject");
		
	If CostObjectSelection <> Undefined And CostObjectSelection.Use Then
		SetSelectionByCostObject(ReportForm, CostObjectSelection.RightValue);
	EndIf;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	If Parameters.Property("CostObjectSelection") Then
		ThisForm.ParametersForm.Insert("CostObjectSelection", Parameters.CostObjectSelection);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private 

// The function searches by name for the CD selection element, if the element is not found returns Undefined
//
// Parameters:
//   FormSettingsComposer - DataCompositionSettingsComposer
//   DCSettings - DataCompositionSettings
//               - DataCompositionUserSettings
//   Name - String - Name of the selection element you are looking for
// Returns:
//  DataCompositionFilterItem
//
Function GetSelectionItemByName(FormSettingsComposer, DCSettings, Name)
	If TypeOf(DCSettings) = Type("DataCompositionSettings") Then
		DCField = New DataCompositionField(Name);
		For Each FilterElement In DCSettings.Filter.Items Do
			If FilterElement.LeftValue = DCField Then
				Return FilterElement;
			EndIf;
		EndDo;
	ElsIf TypeOf(DCSettings) = Type("DataCompositionUserSettings") Then
		SettingsSelectionElement = GetSelectionItemByName(FormSettingsComposer,
			FormSettingsComposer.Settings, "CostObject");
		If SettingsSelectionElement = Undefined Then
			Return Undefined;
		EndIf;
		UserSettingID = SettingsSelectionElement.UserSettingID;
		FilterElement = DCSettings.Items.Find(UserSettingID);
		Return FilterElement;
	EndIf;
		
	Return Undefined;
EndFunction

Procedure SetSelectionByCostObject(ThisForm, CostObjectSelection)

	FormSettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer
	ProductStandardCosts = GetListOfCalculatedProductStandardCostsForCostObject(
			CostObjectSelection);
	If ProductStandardCosts.Count() = 0 Then
		Template = NStr(
			"vi = 'Đối với ""%1"" không có tính giá thành kế hoạch được tính thành công, không thể tạo báo cáo.';
			|ru = 'Для ""%1"" нет успешно рассчитанных плановых калькуляций, формирование отчета невозможно.';
			|en = 'There are no successfully calculated product standard costs for ""%1"". Cannot generate the report.'; fa = 'There are no successfully calculated product standard costs for ""%1"". Cannot generate the report.';
			|it = 'There are no successfully calculated product standard costs for ""%1"". Cannot generate the report.';
			|pl = 'There are no successfully calculated product standard costs for ""%1"". Cannot generate the report.';
			|tr = '""%1"" için başarılı şekilde hesaplanan standart ürün maliyeti yoktur, raporun oluşturulması mümkün değildir.'");
		MessageText = StrTemplate(Template, CostObjectSelection);
		Common.MessageToUser(MessageText);
	EndIf;
	DataCompositionClientServer.SetParameter(FormSettingsComposer.UserSettings,
		"ProductStandardCosts", ProductStandardCosts);

EndProcedure

// Get a list of calculated product standard cost by production order.
// 
// Parameters:
//  CostObject - DocumentRef.ProductionOrder2_2 - the document for which it is necessary to compare product standard cost
//                    - CatalogRef.BillsOfMaterials - the BOM specification according to which it is necessary to compare the planned calculations
// 
// Returns:
//  ValueList of DocumentRef.StandardCosting2_2
Function GetListOfCalculatedProductStandardCostsForCostObject(CostObject)
	
	Query = New Query();
	Query.SetParameter("CostObject", CostObject);
	
	Query.Text = "
	|SELECT DISTINCT
	|	CostObjects.Ref AS Ref
	|FROM
	|	Document.StandardCosting2_2.CostObjects AS CostObjects
	|
	|WHERE
	|	CostObjects.Object = &CostObject
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.StatesOfStandardCostEstimates AS PCState
	|		WHERE
	|			PCState.StandardCostEstimate = CostObjects.Ref
	|			AND PCState.State = VALUE(Enum.StatesOfStandardCostEstimateCalculation.Calculated))
	|";

	QueryResult = Query.Execute().Select();
	ProductStandardCosts = New ValueList();
	While QueryResult.Next() Do
		ProductStandardCosts.Add(QueryResult.Ref);
	EndDo;
	
	Return ProductStandardCosts;
	
EndFunction

// The function returns a request for the report being generated
// Returns:
//  String - Query text
Function QueryText_PlannedCostOfManufacturedProducts()
	
	QueriesTexts = New Array();
	QueriesTexts.Add(Reports.ProductCostEstimate.QueryText_ProductStandardCostData(True));
	
	// Comments are written in the Query Text below. Don't change them in the constructor!
	QueryText = "
		|SELECT
		|	VZ.ThisIsOutput_ AS ThisIsOutput_,
		|	VZ.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	VZ.Organization AS Organization,
		|	VZ.CostObject AS CostObject,
		|	VZ.StandardCostEstimate AS StandardCostEstimate,
		|	VZ.ManufacturedProduct AS ManufacturedProduct,
		|	VZ.ItemVariant AS ItemVariant,
		|	VZ.Department AS Department,
		|	VZ.ProductCostElement AS ProductCostElement,
		|	VZ.Products AS Products,
		|	VZ.Characteristic AS Characteristic,
		|	VZ.ExpenseType AS ExpenseType,
		|	VZ.SemiFinishedProduct AS SemiFinishedProduct,
		|	VZ.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	VZ.AssignmentOfProducts AS AssignmentOfProducts,
		|	SUM(VZ.Count) AS Count,
		|	SUM(VZ.Cost) AS Cost,
		|	SUM(VZ.CostOfMaterial) AS CostOfMaterial,
		|	SUM(VZ.CostLaborCosts) AS CostLaborCosts,
		|	SUM(VZ.CostOtherFixed) AS CostOtherFixed,
		|	SUM(VZ.CostOtherVariable) AS CostOtherVariable,
		|	AVG(VZ.Price) AS Price,
		|	SUM(VZ.OffBalanceCost) AS OffBalanceCost,
		|	SUM(VZ.ReleasedQuantity) AS ReleasedQuantity
		|INTO CalculatedExpenses
		|FROM
		|	(SELECT
		|		Data.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef) AS ThisIsOutput_,
		|		FALSE AS ThisIsASemiFinishedProduct,
		|		Data.StandardCostEstimate.Organization AS Organization,
		|		Data.CostObject AS CostObject,
		|		Data.StandardCostEstimate AS StandardCostEstimate,
		|		Data.ManufacturedProduct AS ManufacturedProduct,
		|		Data.ItemVariant AS ItemVariant,
		|		Data.Department AS Department,
		|		Data.ProductCostElement AS ProductCostElement,
		|		Data.Products AS Products,
		|		Data.Characteristic AS Characteristic,
		|		Data.ExpenseType AS ExpenseType,
		|		SUM(Data.Count) AS Count,
		|		SUM(CASE
		|				WHEN Data.ThisIsASemiFinishedProduct
		|					THEN 0
		|				ELSE Data.Cost
		|			END) AS Cost,
		|		SUM(CASE
		|				WHEN (Data.ExpenseType = ""Material_""
		|						OR Data.ExpenseType = ""RecyclableWaste"")
		|						AND NOT Data.ThisIsASemiFinishedProduct
		|					THEN Data.Cost
		|				ELSE 0
		|			END) AS CostOfMaterial,
		|		SUM(CASE
		|				WHEN Data.ExpenseType = ""LaborCosts""
		|						AND NOT Data.ThisIsASemiFinishedProduct
		|					THEN Data.Cost
		|				ELSE 0
		|			END) AS CostLaborCosts,
		|		SUM(CASE
		|				WHEN Data.ExpenseType = ""OtherPermanent""
		|						AND NOT Data.ThisIsASemiFinishedProduct
		|					THEN Data.Cost
		|				ELSE 0
		|			END) AS CostOtherFixed,
		|		SUM(CASE
		|				WHEN Data.ExpenseType = ""OtherVariables""
		|						AND NOT Data.ThisIsASemiFinishedProduct
		|					THEN Data.Cost
		|				ELSE 0
		|			END) AS CostOtherVariable,
		|		CASE
		|			WHEN Data.ThisIsASemiFinishedProduct
		|				THEN MAX(ISNULL(Prices.Price, 0))
		|			WHEN SUM(Data.Count) = 0
		|				THEN 0
		|			ELSE SUM(Data.Cost) / SUM(Data.Count)
		|		END AS Price,
		|		SUM(Data.OffBalanceSheet) AS OffBalanceCost,
		|		Data.SemiFinishedProduct AS SemiFinishedProduct,
		|		Data.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|		Data.Purpose AS AssignmentOfProducts,
		|		Data.Order AS Order,
		|		0 AS ReleasedQuantity,
		|		Data.KeyLot AS KeyLot
		|	FROM
		|		Data AS Data
		|			LEFT JOIN PricesOfSemiFinishedProducts AS Prices
		|			ON Data.CostObject = Prices.CostObject
		|				AND Data.StandardCostEstimate = Prices.StandardCostEstimate
		|				AND Data.ManufacturedProduct = Prices.ManufacturedProduct
		|				AND Data.ItemVariant = Prices.ItemVariant
		|				AND Data.LotProductBOM = Prices.ProductsBatch
		|				AND Data.Products = Prices.SemiFinishedProduct
		|				AND Data.Characteristic = Prices.ItemVariantsOfIntermediateProduct
		|				AND Data.Purpose = Prices.AssignmentOfProducts
		|	
		|	GROUP BY
		|		Data.ThisIsOutput_,
		|		Data.CostObject,
		|		Data.Characteristic,
		|		Data.StandardCostEstimate,
		|		Data.ManufacturedProduct,
		|		Data.Products,
		|		Data.Department,
		|		Data.ItemVariant,
		|		Data.ExpenseType,
		|		Data.ProductCostElement,
		|		Data.ThisIsASemiFinishedProduct,
		|		Data.SemiFinishedProduct,
		|		Data.ItemVariantsOfIntermediateProduct,
		|		Data.Purpose,
		|		Data.StandardCostEstimate.Organization,
		|		Data.Order,
		|		Data.KeyLot
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ActualCosts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef),
		|		NOT DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL,
		|		ActualCosts.StandardCostEstimate.Organization,
		|		ActualCosts.CostObject,
		|		ActualCosts.StandardCostEstimate,
		|		ActualCosts.ManufacturedProduct,
		|		ActualCosts.ItemVariant,
		|		ActualCosts.Department,
		|		ActualCosts.ProductCostElement,
		|		ActualCosts.Products,
		|		ActualCosts.Characteristic,
		|		ActualCosts.ExpenseType,
		|		ActualCosts.Count,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|				THEN ActualCosts.Cost
		|			WHEN DefinitionOfSemiFinishedProducts.FixedCost
		|				THEN 0
		|			ELSE DefinitionOfSemiFinishedProducts.Cost * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|					AND ActualCosts.ExpenseType = ""Material_""
		|				THEN ActualCosts.Cost
		|			WHEN DefinitionOfSemiFinishedProducts.FixedCost
		|				THEN 0
		|			WHEN ActualCosts.ExpenseType = ""Material_""
		|				THEN DefinitionOfSemiFinishedProducts.CostOfMaterial * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|					AND ActualCosts.ExpenseType = ""LaborCosts""
		|				THEN ActualCosts.Cost
		|			WHEN DefinitionOfSemiFinishedProducts.FixedCost
		|					AND ActualCosts.ExpenseType = ""LaborCosts""
		|				THEN 0
		|			WHEN ActualCosts.ExpenseType = ""LaborCosts""
		|				THEN DefinitionOfSemiFinishedProducts.CostLaborCosts * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|					AND ActualCosts.ExpenseType = ""OtherPermanent""
		|				THEN ActualCosts.Cost
		|			WHEN DefinitionOfSemiFinishedProducts.FixedCost
		|					AND ActualCosts.ExpenseType = ""OtherPermanent""
		|				THEN 0
		|			WHEN ActualCosts.ExpenseType = ""OtherPermanent""
		|				THEN DefinitionOfSemiFinishedProducts.CostOtherFixed * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|					AND ActualCosts.ExpenseType = ""OtherVariables""
		|				THEN ActualCosts.Cost
		|			WHEN DefinitionOfSemiFinishedProducts.FixedCost
		|					AND ActualCosts.ExpenseType = ""OtherVariables""
		|				THEN 0
		|			WHEN ActualCosts.ExpenseType = ""OtherVariables""
		|				THEN DefinitionOfSemiFinishedProducts.CostOtherVariable * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|				THEN CASE
		|						WHEN ActualCosts.Count = 0
		|							THEN 0
		|						ELSE ActualCosts.Cost / ActualCosts.Count
		|					END
		|			ELSE DefinitionOfSemiFinishedProducts.Cost * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count / ActualCosts.Count
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|				THEN ActualCosts.OffBalanceSheet
		|			WHEN DefinitionOfSemiFinishedProducts.FixedCost
		|				THEN 0
		|			ELSE DefinitionOfSemiFinishedProducts.OffBalanceCost * ActualCosts.Count / DefinitionOfSemiFinishedProducts.Count
		|		END,
		|		ActualCosts.SemiFinishedProduct,
		|		ActualCosts.ItemVariantsOfIntermediateProduct,
		|		ActualCosts.Purpose,
		|		ActualCosts.Order,
		|		0,
		|		ISNULL(DefinitionOfSemiFinishedProducts.KeyLot, ActualCosts.KeyLot)
		|	FROM
		|		ActualCosts AS ActualCosts
		|			LEFT JOIN DefinitionOfSemiFinishedProducts AS DefinitionOfSemiFinishedProducts
		|			ON ActualCosts.CostObject = DefinitionOfSemiFinishedProducts.CostObject
		|				AND ActualCosts.ItemsLocationAttributes = DefinitionOfSemiFinishedProducts.ItemsLocationAttributes
		|				AND (CASE
		|					WHEN ActualCosts.ThisIsOutput_
		|						THEN ActualCosts.LotProductBOM = DefinitionOfSemiFinishedProducts.LotProductBOM
		|					ELSE ActualCosts.SemiFinishedProductLot = DefinitionOfSemiFinishedProducts.LotProductBOM
		|				END)
		|				AND (DefinitionOfSemiFinishedProducts.KeyLot = ActualCosts.KeyLot)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef),
		|		MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef),
		|		VALUE(Catalog.Companies.EmptyRef),
		|		SharesOfValueFromCalculatedQuantity.CostObject,
		|		SharesOfValueFromCalculatedQuantity.StandardCostEstimate,
		|		SharesOfValueFromCalculatedQuantity.ManufacturedProduct,
		|		SharesOfValueFromCalculatedQuantity.ItemVariant,
		|		VALUE(Catalog.BusinessStructure.EmptyRef),
		|		VALUE(Catalog.ProductCostElements.EmptyRef),
		|		VALUE(Catalog.Products.EmptyRef),
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef),
		|		CAST("""" AS STRING(16)),
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		SemiFinishedProducts_.Ref,
		|		CASE
		|			WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|				THEN MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|			ELSE MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
		|		END,
		|		SharesOfValueFromCalculatedQuantity.Purpose,
		|																			  
		|		0,
		|		SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct * SharesOfValueFromCalculatedQuantity.CostShare),
		|		MultiplesOfLotsAndSemiFinishedProducts.KeyLot
		|	FROM
		|		SharesOfValueFromCalculatedQuantity AS SharesOfValueFromCalculatedQuantity
		|			INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|			ON SharesOfValueFromCalculatedQuantity.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
		|				AND SharesOfValueFromCalculatedQuantity.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
		|				AND SharesOfValueFromCalculatedQuantity.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|				AND SharesOfValueFromCalculatedQuantity.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
		|				
		|			INNER JOIN Catalog.Products AS SemiFinishedProducts_
		|			ON (SemiFinishedProducts_.Ref = CASE
		|					WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|						THEN MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
		|					ELSE MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct
		|				END)
		|	
		|	GROUP BY
		|		MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef),
		|		SharesOfValueFromCalculatedQuantity.CostObject,
		|		SharesOfValueFromCalculatedQuantity.StandardCostEstimate,
		|		SharesOfValueFromCalculatedQuantity.ManufacturedProduct,
		|		SharesOfValueFromCalculatedQuantity.ItemVariant,
		|		SemiFinishedProducts_.Ref,
		|		CASE
		|			WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|				THEN MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|			ELSE MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
		|		END,
		|		SharesOfValueFromCalculatedQuantity.Purpose,
		|		MultiplesOfLotsAndSemiFinishedProducts.KeyLot,
		|		MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef)) AS VZ
		|
		|GROUP BY
		|	VZ.ThisIsOutput_,
		|	VZ.Organization,
		|	VZ.CostObject,
		|	VZ.StandardCostEstimate,
		|	VZ.ManufacturedProduct,
		|	VZ.ItemVariant,
		|	VZ.Department,
		|	VZ.ProductCostElement,
		|	VZ.Products,
		|	VZ.Characteristic,
		|	VZ.ExpenseType,
		|	VZ.ThisIsASemiFinishedProduct,
		|	VZ.SemiFinishedProduct,
		|	VZ.ItemVariantsOfIntermediateProduct,
		|	VZ.AssignmentOfProducts
		|
		|INDEX BY
		|	CostObject,
		|	StandardCostEstimate,
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Data
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PricesOfSemiFinishedProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ActualCosts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DefinitionOfSemiFinishedProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SharesOfValueFromCalculatedQuantity
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT TOP 1316134911
		|	RECORDAUTONUMBER() AS PCIndex,
		|	DD.CostObject AS CostObject,
		|	DD.StandardCostEstimate.Date AS PCDate,
		|	DD.StandardCostEstimate AS StandardCostEstimate
		|INTO PCIndexing
		|FROM
		|	CalculatedExpenses AS DD
		|
		|ORDER BY
		|	CostObject,
		|	PCDate
		|
		|INDEX BY
		|	CostObject,
		|	StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PCOrder.PCIndex AS PCIndex,
		|	MAX(ISNULL(DD.PCIndex, 0)) AS PreviousPCIndex,
		|	PCOrder.CostObject AS CostObject,
		|	PCOrder.StandardCostEstimate AS StandardCostEstimate,
		|	PCOrder.PCDate AS PCDate,
		|	DD.PCIndex IS NULL AS ThisIsFirstPC
		|INTO PCOrder_Preliminary
		|FROM
		|	PCIndexing AS PCOrder
		|		LEFT JOIN PCIndexing AS DD
		|		ON PCOrder.CostObject = DD.CostObject
		|			AND PCOrder.PCIndex > DD.PCIndex
		|
		|GROUP BY
		|	PCOrder.PCIndex,
		|	PCOrder.CostObject,
		|	PCOrder.StandardCostEstimate,
		|	PCOrder.PCDate,
		|	DD.PCIndex IS NULL
		|
		|INDEX BY
		|	CostObject,
		|	StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// This TT is necessary to determine the correct location of the PC on the time axis.
		|SELECT
		|	PCOrder.PCIndex AS PCIndex,
		|	PCOrder.PreviousPCIndex AS PreviousPCIndex,
		|	DD.StandardCostEstimate AS PreviousCalculation,
		|	PCOrder.CostObject AS CostObject,
		|	PCOrder.StandardCostEstimate AS StandardCostEstimate,
		|	PCOrder.PCDate AS PCDate,
		|	PCOrder.ThisIsFirstPC AS ThisIsFirstPC
		|INTO PCOrder
		|FROM
		|	PCOrder_Preliminary AS PCOrder
		|		LEFT JOIN PCIndexing AS DD
		|		ON PCOrder.PreviousPCIndex = DD.PCIndex
		|
		|INDEX BY
		|	CostObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PCOrder_Preliminary
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(DD.PCIndex) AS IndexOfLastPC,
		|	DD.CostObject AS CostObject
		|INTO IndexOfRecentPCs
		|FROM
		|	PCIndexing AS DD
		|
		|GROUP BY
		|	DD.CostObject
		|
		|INDEX BY
		|	CostObject,
		|	IndexOfLastPC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PCIndexing
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 
		// This TT is necessary to determine all the analytics used in all PCs for each calculation object.
		|SELECT DISTINCT
		|	DD.ThisIsOutput_ AS ThisIsOutput_,
		|	DD.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	DD.Organization AS Organization,
		|	DD.Department AS Department,
		|	DD.CostObject AS CostObject,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.ExpenseType AS ExpenseType,
		|	DD.ManufacturedProduct AS ManufacturedProduct,
		|	DD.ManufacturedProduct.UnitOfMeasure AS ProductsUnitOfMeasurement_3,
		|	DD.ItemVariant AS ItemVariant,
		|	DD.AssignmentOfProducts AS AssignmentOfProducts,
		|	DD.SemiFinishedProduct AS SemiFinishedProduct,
		|	DD.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	DD.SemiFinishedProduct.UnitOfMeasure AS SemiFinishedProductUnitOfMeasurement,
		|	DD.Products AS Products,
		|	DD.Products.UnitOfMeasure AS ProductsUnitOfMeasure,
		|	DD.Characteristic AS Characteristic
		|INTO ExpenseAnalytics
		|FROM
		|	CalculatedExpenses AS DD
		|
		|INDEX BY
		|	CostObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// This TT is necessary so that each PC has all the analytics that have ever been used for each calculation object.
		// If there were no expenses in a separate PC, all resources are set to 0. 
		// This is necessary further for the correct calculation of the differences between PCs.
		|SELECT
		|	ExpenseAnalytics.Organization AS Organization,
		|	PCOrder.StandardCostEstimate AS StandardCostEstimate,
		|	PCOrder.PCDate AS PCDate,
		|	ExpenseAnalytics.ThisIsOutput_ AS ThisIsOutput_,
		|	ExpenseAnalytics.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	ExpenseAnalytics.Department AS Department,
		|	ExpenseAnalytics.CostObject AS CostObject,
		|	ExpenseAnalytics.ProductCostElement AS ProductCostElement,
		|	ExpenseAnalytics.ExpenseType AS ExpenseType,
		|
		|	ExpenseAnalytics.ManufacturedProduct AS ManufacturedProduct,
		|	ExpenseAnalytics.ItemVariant AS ItemVariant,
		|	ExpenseAnalytics.ProductsUnitOfMeasurement_3 AS ProductsUnitOfMeasurement_3,
		|	ExpenseAnalytics.AssignmentOfProducts AS AssignmentOfProducts,
		|
		|	ExpenseAnalytics.SemiFinishedProduct AS SemiFinishedProduct,
		|	ExpenseAnalytics.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	ExpenseAnalytics.SemiFinishedProductUnitOfMeasurement AS SemiFinishedProductUnitOfMeasurement,
		|
		|	ExpenseAnalytics.Products AS Products,
		|	ExpenseAnalytics.Characteristic AS Characteristic,
		|	ExpenseAnalytics.ProductsUnitOfMeasure AS ProductsUnitOfMeasure,
		|
		|	PCOrder.ThisIsFirstPC AS ThisIsFirstPC,
		|	PCOrder.PCIndex AS PCIndex,
		|	PCOrder.PreviousCalculation AS PreviousCalculation,
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			IndexOfRecentPCs AS IndexOfRecentPCs
		|		WHERE
		|			ExpenseAnalytics.CostObject = IndexOfRecentPCs.CostObject
		|			AND PCOrder.PCIndex = IndexOfRecentPCs.IndexOfLastPC) AS ThisIsLastPC,
		|
		|	ISNULL(DD.ReleasedQuantity, 0) AS ReleasedQuantity,
		|	ISNULL(DD.Count, 0) AS Count,
		|	ISNULL(DD.Price, 0) AS Price,
		|	ISNULL(DD.Cost, 0) AS Cost,
		|	ISNULL(DD.CostOfMaterial, 0) AS CostOfMaterial,
		|	ISNULL(DD.CostLaborCosts, 0) AS CostLaborCosts,
		|	ISNULL(DD.CostOtherFixed, 0) AS CostOtherFixed,
		|	ISNULL(DD.CostOtherVariable, 0) AS CostOtherVariable,
		|	ISNULL(DD.OffBalanceCost, 0) AS OffBalanceCost,
		|	DD.CostObject IS NULL AS WithinFrameworkOfPCThereWereNoExpenses
		| 
		|INTO CalculatedExpensesAugmented
		|FROM
		|	ExpenseAnalytics AS ExpenseAnalytics
		|		INNER JOIN PCOrder AS PCOrder
		|		ON ExpenseAnalytics.CostObject = PCOrder.CostObject
		|
		|		LEFT JOIN CalculatedExpenses AS DD
		|		ON (DD.CostObject = ExpenseAnalytics.CostObject)
		|			AND (DD.StandardCostEstimate = PCOrder.StandardCostEstimate)
		|			AND (DD.ManufacturedProduct = ExpenseAnalytics.ManufacturedProduct)
		|			AND (DD.ItemVariant = ExpenseAnalytics.ItemVariant)
		|			AND (DD.AssignmentOfProducts = ExpenseAnalytics.AssignmentOfProducts)
		|			AND (DD.SemiFinishedProduct = ExpenseAnalytics.SemiFinishedProduct)
		|			AND (DD.ItemVariantsOfIntermediateProduct = ExpenseAnalytics.ItemVariantsOfIntermediateProduct)
		|			AND (DD.Products = ExpenseAnalytics.Products)
		|			AND (DD.Characteristic = ExpenseAnalytics.Characteristic)
		|			AND (DD.ThisIsASemiFinishedProduct = ExpenseAnalytics.ThisIsASemiFinishedProduct)
		|			AND (DD.ThisIsOutput_ OR DD.ThisIsASemiFinishedProduct OR DD.ExpenseType = ExpenseAnalytics.ExpenseType)
		|
		|INDEX BY
		|	ThisIsASemiFinishedProduct,
		|	CostObject,
		|	StandardCostEstimate,
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Products,
		|	Characteristic,
		|	ThisIsOutput_,
		|	ExpenseType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ExpenseAnalytics
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PCOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// This TT is necessary to calculate the coefficient - The amount of expenses / Quantity (PF/Manufactured Products)
		// This is necessary further to correctly determine the reason for the change in the current expenses - a change in the amount of consuming upper-level PF/ 
		// The number of expenses for Manufactured Products or for 1 unit of PF/Manufactured Products has changed.
		|SELECT
		|	Costs.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	Costs.CostObject AS CostObject,
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	Costs.ManufacturedProduct AS ManufacturedProduct,
		|	Costs.ItemVariant AS ItemVariant,
		|	Costs.AssignmentOfProducts AS AssignmentOfProducts,
		|	Costs.SemiFinishedProduct AS SemiFinishedProduct,
		|	Costs.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	Costs.Products AS Products,
		|	Costs.ExpenseType AS ExpenseType,
		|	Costs.Characteristic AS Characteristic,
		|	Costs.Count AS Count,
		|	PFIManufacturedProducts.ReleasedQuantity AS UpperLevelQuantity,
		|	CAST(CASE
		|			WHEN PFIManufacturedProducts.ReleasedQuantity = 0
		|				THEN 0
		|			
		|			ELSE Costs.Count / PFIManufacturedProducts.ReleasedQuantity
		|		END AS NUMBER(31, 6)) AS ZoomRatio
		| 
		|INTO CoefficientsOfRatioOfExpensesOfKPFIOfManufacturedProducts
		|FROM
		|	CalculatedExpensesAugmented AS Costs
		|		INNER JOIN CalculatedExpensesAugmented AS PFIManufacturedProducts
		|		ON (NOT Costs.ThisIsOutput_)
		|			AND (NOT Costs.ThisIsASemiFinishedProduct)
		|			AND (PFIManufacturedProducts.ThisIsOutput_)
		|			AND Costs.CostObject = PFIManufacturedProducts.CostObject
		|			AND Costs.StandardCostEstimate = PFIManufacturedProducts.StandardCostEstimate
		|			AND Costs.ManufacturedProduct = PFIManufacturedProducts.ManufacturedProduct
		|			AND Costs.ItemVariant = PFIManufacturedProducts.ItemVariant
		|			AND Costs.AssignmentOfProducts = PFIManufacturedProducts.AssignmentOfProducts
		|			AND Costs.SemiFinishedProduct = PFIManufacturedProducts.SemiFinishedProduct
		|			AND Costs.ItemVariantsOfIntermediateProduct = PFIManufacturedProducts.ItemVariantsOfIntermediateProduct
		|
		|UNION ALL
		|
		|SELECT
		|	Costs.ThisIsASemiFinishedProduct,
		|	Costs.CostObject,
		|	Costs.StandardCostEstimate,
		|	Costs.ManufacturedProduct,
		|	Costs.ItemVariant,
		|	Costs.AssignmentOfProducts,
		|	Costs.SemiFinishedProduct,
		|	Costs.ItemVariantsOfIntermediateProduct,
		|	Costs.Products,
		|	Costs.ExpenseType AS ExpenseType,
		|	Costs.Characteristic,
		|	Costs.Count,
		|	PFIManufacturedProducts.ReleasedQuantity,
		|	CAST(CASE
		|			WHEN PFIManufacturedProducts.ReleasedQuantity = 0
		|				THEN 0
		|			
		|			ELSE Costs.Count / PFIManufacturedProducts.ReleasedQuantity
		|		END AS NUMBER(31, 6))
		|FROM
		|	CalculatedExpensesAugmented AS Costs
		|		INNER JOIN CalculatedExpensesAugmented AS PFIManufacturedProducts
		|		ON (NOT Costs.ThisIsOutput_)
		|			AND (NOT Costs.ThisIsASemiFinishedProduct)
		|			AND (PFIManufacturedProducts.ThisIsASemiFinishedProduct)  
		|			AND PFIManufacturedProducts.Products = VALUE(Catalog.Products.EmptyRef)
		|			AND Costs.CostObject = PFIManufacturedProducts.CostObject
		|			AND Costs.StandardCostEstimate = PFIManufacturedProducts.StandardCostEstimate
		|			AND Costs.ManufacturedProduct = PFIManufacturedProducts.ManufacturedProduct
		|			AND Costs.ItemVariant = PFIManufacturedProducts.ItemVariant
		|			AND Costs.AssignmentOfProducts = PFIManufacturedProducts.AssignmentOfProducts
		|			AND Costs.SemiFinishedProduct = PFIManufacturedProducts.SemiFinishedProduct
		|			AND Costs.ItemVariantsOfIntermediateProduct = PFIManufacturedProducts.ItemVariantsOfIntermediateProduct
		|
		|UNION ALL
		|
		|SELECT
		|	Costs.ThisIsASemiFinishedProduct,
		|	Costs.CostObject,
		|	Costs.StandardCostEstimate,
		|	Costs.ManufacturedProduct,
		|	Costs.ItemVariant,
		|	Costs.AssignmentOfProducts,
		|	Costs.SemiFinishedProduct,
		|	Costs.ItemVariantsOfIntermediateProduct,
		|	Costs.Products,
		|	Costs.ExpenseType AS ExpenseType,
		|	Costs.Characteristic,
		|	Costs.Count,
		|	PFIManufacturedProducts.ReleasedQuantity,
		|	CAST(CASE
		|			WHEN PFIManufacturedProducts.ReleasedQuantity = 0
		|				THEN 0
		|			
		|			ELSE Costs.ReleasedQuantity / PFIManufacturedProducts.ReleasedQuantity
		|		END AS NUMBER(31, 6))
		|
		|FROM
		|	CalculatedExpensesAugmented AS Costs
		|		INNER JOIN CalculatedExpensesAugmented AS PFIManufacturedProducts
		|		ON (Costs.ThisIsASemiFinishedProduct)
		|			AND (PFIManufacturedProducts.ThisIsOutput_)
		|			AND Costs.CostObject = PFIManufacturedProducts.CostObject
		|			AND Costs.StandardCostEstimate = PFIManufacturedProducts.StandardCostEstimate
		|			AND Costs.ManufacturedProduct = PFIManufacturedProducts.ManufacturedProduct
		|			AND Costs.ItemVariant = PFIManufacturedProducts.ItemVariant
		|			AND Costs.AssignmentOfProducts = PFIManufacturedProducts.AssignmentOfProducts
		|
		|INDEX BY
		|	ThisIsASemiFinishedProduct,
		|	CostObject,
		|	StandardCostEstimate,
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Products,
		|	Characteristic,
		|	ExpenseType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// In this TT, we add the coefficients calculated above.
		// It is necessary further that the current expenses have coefficients and the previous one. 
		|SELECT
		|	DD.ThisIsFirstPC AS ThisIsFirstPC,
		|	DD.PCIndex AS PCIndex,
		|	DD.ThisIsLastPC AS ThisIsLastPC,
		|	DD.Organization AS Organization,
		|	DD.CostObject AS CostObject,
		|	DD.StandardCostEstimate AS StandardCostEstimate,
		|	DD.PreviousCalculation AS PreviousCalculation,
		|	DD.PCDate AS PCDate,
		|	DD.ManufacturedProduct AS ManufacturedProduct,
		|	DD.ItemVariant AS ItemVariant,
		|	DD.ThisIsOutput_ AS ThisIsOutput_,
		|	DD.Department AS Department,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.Products AS Products,
		|	DD.Characteristic AS Characteristic,
		|	DD.ExpenseType AS ExpenseType,
		|	DD.ProductsUnitOfMeasurement_3 AS ProductsUnitOfMeasurement_3,
		|	DD.ProductsUnitOfMeasure AS ProductsUnitOfMeasure,
		|	DD.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	DD.SemiFinishedProduct AS SemiFinishedProduct,
		|	DD.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	DD.AssignmentOfProducts AS AssignmentOfProducts,
		|	DD.SemiFinishedProductUnitOfMeasurement AS SemiFinishedProductUnitOfMeasurement,
		|	DD.ReleasedQuantity AS ReleasedQuantity,
		|	DD.Count AS Count,
		|	DD.Price AS Price,
		|	DD.Cost AS Cost,
		|	DD.CostOfMaterial AS CostOfMaterial,
		|	DD.CostLaborCosts AS CostLaborCosts,
		|	DD.CostOtherFixed AS CostOtherFixed,
		|	DD.CostOtherVariable AS CostOtherVariable,
		|	DD.OffBalanceCost AS OffBalanceCost,
		|	DD.WithinFrameworkOfPCThereWereNoExpenses AS WithinFrameworkOfPCThereWereNoExpenses,
		|	ISNULL(OZPIP.ZoomRatio, 0) AS CoefficientToUpperLevelQuantity,
		|	ISNULL(OZPIP.UpperLevelQuantity, 0) AS UpperLevelQuantity
		|INTO CalculatedExpensesWithCoefficients
		|FROM
		|	CalculatedExpensesAugmented AS DD
		|		LEFT JOIN CoefficientsOfRatioOfExpensesOfKPFIOfManufacturedProducts AS OZPIP
		|		ON (NOT DD.ThisIsOutput_)
		|			AND DD.ThisIsASemiFinishedProduct = OZPIP.ThisIsASemiFinishedProduct
		|			AND DD.CostObject = OZPIP.CostObject
		|			AND DD.StandardCostEstimate = OZPIP.StandardCostEstimate
		|			AND DD.ManufacturedProduct = OZPIP.ManufacturedProduct
		|			AND DD.ItemVariant = OZPIP.ItemVariant
		|			AND DD.AssignmentOfProducts = OZPIP.AssignmentOfProducts
		|			AND DD.SemiFinishedProduct = OZPIP.SemiFinishedProduct
		|			AND DD.ItemVariantsOfIntermediateProduct = OZPIP.ItemVariantsOfIntermediateProduct
		|			AND DD.Products = OZPIP.Products
		|			AND DD.Characteristic = OZPIP.Characteristic
		|			AND (DD.ThisIsOutput_ OR DD.ThisIsASemiFinishedProduct OR DD.ExpenseType = OZPIP.ExpenseType)
		|
		|INDEX BY
		|	CostObject,
		|	PreviousCalculation,
		|	ManufacturedProduct,
		|	ItemVariant,
		|	AssignmentOfProducts,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Products,
		|	Characteristic,
		|	ThisIsFirstPC,
		|	ExpenseType
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CoefficientsOfRatioOfExpensesOfKPFIOfManufacturedProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CalculatedExpenses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CalculatedExpensesAugmented
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// The final table where we attach to each PC, if it is not the first, the previous PC.
		// We calculate the differences in expenses resources and calculate the difference in expenses coefficients. 
		|SELECT
		|	DD.ThisIsOutput_ AS ThisIsOutput_,
		|	DD.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	DD.ThisIsFirstPC AS ThisIsFirstPC,
		|	DD.PCIndex AS PCIndex,
		|	DD.ThisIsLastPC AS ThisIsLastPC,
		|	DD.Organization AS Organization,
		|	DD.CostObject AS CostObject,
		|	DD.StandardCostEstimate AS StandardCostEstimate,
		|	DD.PCDate AS PCDate,
		|	DD.ManufacturedProduct AS ManufacturedProduct,
		|	DD.ItemVariant AS ItemVariant,
		|	DD.Department AS Department,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.Products AS Products,
		|	DD.Characteristic AS Characteristic,
		|	DD.ExpenseType AS ExpenseType,
		|	DD.ExpenseType = ""OtherPermanent"" OR DD.ExpenseType = ""OtherVariables"" AS TheseAre_OtherExpenses,
		|	DD.ProductsUnitOfMeasurement_3 AS ProductsUnitOfMeasurement_3,
		|	DD.ProductsUnitOfMeasure AS ProductsUnitOfMeasure,
		|	DD.SemiFinishedProduct AS SemiFinishedProduct,
		|	DD.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	DD.AssignmentOfProducts AS AssignmentOfProducts,
		|	DD.SemiFinishedProductUnitOfMeasurement AS SemiFinishedProductUnitOfMeasurement,
		|	DD.ReleasedQuantity AS ReleasedQuantity,
		|	DD.Count AS Count,
		|	DD.Price AS Price,
		|	DD.Cost AS Cost,
		|	DD.CostOfMaterial AS CostOfMaterial,
		|	DD.CostLaborCosts AS CostLaborCosts,
		|	DD.CostOtherFixed AS CostOtherFixed,
		|	DD.CostOtherVariable AS CostOtherVariable,
		|	DD.OffBalanceCost AS OffBalanceCost,
		|	
		|	ISNULL(PreviousCalculatedExpenses.Count, 0) AS PreviousQuantity,
		|	ISNULL(PreviousCalculatedExpenses.ReleasedQuantity, 0) AS PreviousIssueNumber,
		|	DD.WithinFrameworkOfPCThereWereNoExpenses AS WithinFrameworkOfPCThereWereNoExpenses,
		|
		|	CAST(CASE
		|			WHEN DD.ThisIsFirstPC
		|				THEN 0
		|			ELSE DD.ReleasedQuantity - ISNULL(PreviousCalculatedExpenses.ReleasedQuantity, 0)
		|		END AS NUMBER(15, 3)) AS DifferenceIsNumberOfIssues,
		|	CAST(CASE
		|			WHEN DD.ThisIsFirstPC
		|				THEN 0
		|			ELSE DD.Count - ISNULL(PreviousCalculatedExpenses.Count, 0)
		|		END AS NUMBER(15, 3)) AS DifferenceIsQuantity,
		|	CAST(CASE
		|			WHEN DD.ThisIsFirstPC
		|				THEN 0
		|			ELSE DD.Price - ISNULL(PreviousCalculatedExpenses.Price, 0)
		|		END AS NUMBER(31, 2)) AS PriceDifference,
		|	CAST(CASE
		|			WHEN DD.ThisIsFirstPC
		|				THEN 0
		|			ELSE DD.Cost - ISNULL(PreviousCalculatedExpenses.Cost, 0)
		|		END AS NUMBER(31, 2)) AS CostDifference,
		|		
		|	CASE
		|		WHEN DD.ThisIsFirstPC
		|			THEN 0
		|		WHEN NOT DD.ThisIsOutput_ AND ISNULL(PreviousCalculatedExpenses.UpperLevelQuantity, 0) = 0
					// Up to current. There was no calculation of the upper-level node, when it appears, we note the change only of the upper-level node.  
		|			THEN 0		
		|		WHEN DD.ThisIsASemiFinishedProduct OR DD.ThisIsOutput_
		|										
		|			THEN   
						// We determine whether there was a change in the upper-level quantity.
		|				CASE WHEN DD.UpperLevelQuantity - ISNULL(PreviousCalculatedExpenses.UpperLevelQuantity, 0) = 0
		|					THEN 
								// If there were no changes in the upper-level number, then the difference is current. the level.
		|						DD.ReleasedQuantity - ISNULL(PreviousCalculatedExpenses.ReleasedQuantity, 0)
		|					ELSE    
								// Both the upper-level quantity and the current quantity may change. expenses.
								// In order to correctly calculate whether the amount of expenses has changed for 1 unit. upper-level PF/Manufacturing products
								// are considered to be the difference coefficient = (current. the amount of expenses is the previous one) / (current. the upper-level number of PF/Of manufactured products - the previous one).
		|						CAST(
		|							(DD.ReleasedQuantity - ISNULL(PreviousCalculatedExpenses.ReleasedQuantity, 0)) / (DD.UpperLevelQuantity - ISNULL(PreviousCalculatedExpenses.UpperLevelQuantity, 0))
		|						AS NUMBER(31, 6))   
								// and from the current coefficient of differences we subtract the previous coefficient.
		|				END -  ISNULL(PreviousCalculatedExpenses.CoefficientToUpperLevelQuantity, 0)			  
		|		ELSE 0
		|	END AS DifferenceInCoefficientsOfSemiFinishedProduct,   
		|	
		|	CASE
		|		WHEN DD.ThisIsFirstPC
		|			THEN 0
		|
		|		WHEN DD.ThisIsOutput_ OR DD.ThisIsASemiFinishedProduct 
		|			THEN 0
		|		WHEN ISNULL(PreviousCalculatedExpenses.UpperLevelQuantity, 0) = 0
					// Up to current. There was no calculation of the upper-level node, when it appears, we note the change only of the upper-level node.
		|			THEN 0
		|		ELSE
					// The calculation logic is the same as written above, with one difference - the amount of expenses according to the nomenclature in the resource - Quantity.
		|			CASE WHEN DD.UpperLevelQuantity - ISNULL(PreviousCalculatedExpenses.UpperLevelQuantity, 0) = 0
		|				THEN 
		|					DD.Count - ISNULL(PreviousCalculatedExpenses.Count, 0)
		|				ELSE
		|					CAST(
		|						(DD.Count - ISNULL(PreviousCalculatedExpenses.Count, 0)) / (DD.UpperLevelQuantity - ISNULL(PreviousCalculatedExpenses.UpperLevelQuantity, 0))
		|					AS NUMBER(31, 6))
		|			END - ISNULL(PreviousCalculatedExpenses.CoefficientToUpperLevelQuantity, 0)
		|	END AS CoefficientDifferenceItem
		|	
		|FROM
		|	CalculatedExpensesWithCoefficients AS DD
		|		LEFT JOIN CalculatedExpensesWithCoefficients AS PreviousCalculatedExpenses
		|		ON (NOT DD.ThisIsFirstPC)
		|			AND DD.CostObject = PreviousCalculatedExpenses.CostObject
		|			AND DD.PreviousCalculation = PreviousCalculatedExpenses.StandardCostEstimate
		|			AND DD.ManufacturedProduct = PreviousCalculatedExpenses.ManufacturedProduct
		|			AND DD.ItemVariant = PreviousCalculatedExpenses.ItemVariant
		|			AND DD.AssignmentOfProducts = PreviousCalculatedExpenses.AssignmentOfProducts
		|			AND DD.SemiFinishedProduct = PreviousCalculatedExpenses.SemiFinishedProduct
		|			AND DD.ItemVariantsOfIntermediateProduct = PreviousCalculatedExpenses.ItemVariantsOfIntermediateProduct
		|			AND DD.Products = PreviousCalculatedExpenses.Products
		|			AND DD.Characteristic = PreviousCalculatedExpenses.Characteristic
		|			AND DD.ThisIsASemiFinishedProduct = PreviousCalculatedExpenses.ThisIsASemiFinishedProduct
		|			AND (DD.ThisIsOutput_ OR DD.ThisIsASemiFinishedProduct OR DD.ExpenseType = PreviousCalculatedExpenses.ExpenseType)
		|";
	
	QueriesTexts.Add(QueryText);
	Result = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Return Result;
	
EndFunction

#EndRegion

#EndIf