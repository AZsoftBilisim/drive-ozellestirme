#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ObjectsArray, Period, PriceKind, CachedValues;

#EndRegion

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
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.Parameters.Filter.Insert("ObjectsArray", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers
	
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// We will prepare and output a report.
	TemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionSettings = SettingsComposer.GetSettings();
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		DataCompositionSettings,
		DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	
	TableOfMaterials = CostOfProcessingTollFreeRawMaterials();
	
	ExternalDataSets = New Structure("TableOfMaterials", TableOfMaterials);
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor, True);
	
	OutputProcessor.EndOutput();
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion 

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	
	ObjectsArray = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "ObjectsArray").Value;
	
	Period = EndOfDay(CurrentSessionDate());
	ReportDateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportDate");
	
	If ValueIsFilled(ReportDateParameter.Value) Then
		Period = EndOfDay(ReportDateParameter.Value);
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "ReportDate", Period);
		UserSettingsModified = True;
	EndIf;
	
	ReportDateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	PriceKind = ReportDateParameter.Value;
	
EndProcedure

Function CostOfProcessingTollFreeRawMaterials()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiverSOrder2_5Products.Ref                         AS MaterialProviderOrder,
	|	GiverSOrder2_5Products.BillOfMaterials                   AS BillOfMaterials,
	|	GiverSOrder2_5Products.Ref.LineOfBusiness AS LineOfBusiness,
	|	GiverSOrder2_5Products.Ref.Date                    AS ProductionStart,
	|	GiverSOrder2_5Products.Products                   AS Products,
	|	GiverSOrder2_5Products.Characteristic                 AS Characteristic,
	|	GiverSOrder2_5Products.Count                     AS Count,
	|	CASE
	|		WHEN &PriceKind = UNDEFINED
	|			THEN GiverSOrder2_5Products.PriceKind
	|		ELSE &PriceKind
	|	END                                                    AS PriceKind,
	|	GiverSOrder2_5Products.Ref.Currency                  AS Currency
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GiverSOrder2_5Products
	|WHERE
	|	GiverSOrder2_5Products.Ref IN(&ObjectsArray)
	|	AND NOT GiverSOrder2_5Products.Canceled
	|	AND NOT GiverSOrder2_5Products.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialProviderOrder2_5UsedMaterials.Ref            AS MaterialProviderOrder,
	|	MaterialProviderOrder2_5UsedMaterials.BillOfMaterials      AS BillOfMaterials,
	|	MaterialProviderOrder2_5UsedMaterials.Products      AS Products,
	|	MaterialProviderOrder2_5UsedMaterials.Characteristic    AS Characteristic,
	|	SUM(MaterialProviderOrder2_5UsedMaterials.Count) AS Count
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS MaterialProviderOrder2_5UsedMaterials
	|WHERE
	|	MaterialProviderOrder2_5UsedMaterials.Ref IN(&ObjectsArray)
	|	AND NOT MaterialProviderOrder2_5UsedMaterials.Canceled
	|
	|GROUP BY
	|	MaterialProviderOrder2_5UsedMaterials.Ref,
	|	MaterialProviderOrder2_5UsedMaterials.BillOfMaterials,
	|	MaterialProviderOrder2_5UsedMaterials.Products,
	|	MaterialProviderOrder2_5UsedMaterials.Characteristic
	|";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("PriceKind", PriceKind);
	
	Result = Query.ExecuteBatch();
	
	SamplingOfManufacturedProductsOfOrder   = Result[0].Select();
	TableOfGiverSMaterials = Result[1].Unload();
	
	SearchKey = "MaterialProviderOrder, BillOfMaterials, Products, Characteristic";
	TableOfGiverSMaterials.Indexes.Add(SearchKey);
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(
		"MaterialsAndServices, LaborCosts",,
		Enums.ProductionSupplyFillingVariants.AsSetInTransferToProduction);
	
	SelectionParameters.MethodOfCalculationOfMaterials = Enums.MaterialCalculationMethods.PossibleConsumption;
	SelectionParameters.OverridingReleasePartySetting.Use = True;
	SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
	
	CostTable = NewCostTable();
	
	While SamplingOfManufacturedProductsOfOrder.Next() Do
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, SamplingOfManufacturedProductsOfOrder);
		
		TabularSections = Catalogs.BillsOfMaterials.SpecificationDataBySemiFinishedProducts(ItemData_3, True, SelectionParameters);
		
		// UsedMaterials
		TSUsedMaterials = TabularSections.MaterialsAndServices;
		
		TSUsedMaterials.Columns.Add("MaterialProviderOrder",New TypeDescription(TypesOfGiverSOrder()));
		TSUsedMaterials.FillValues(SamplingOfManufacturedProductsOfOrder.MaterialProviderOrder, "MaterialProviderOrder");
		
		TSUsedMaterials.Columns.Add("ManufacturedProduct",New TypeDescription("CatalogRef.Products"));
		TSUsedMaterials.FillValues(SamplingOfManufacturedProductsOfOrder.Products, "ManufacturedProduct");
		
		TSUsedMaterials.Columns.Add("ItemVariant",New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TSUsedMaterials.FillValues(SamplingOfManufacturedProductsOfOrder.Characteristic, "ItemVariant");
		
		TSUsedMaterials.Columns.Add("PriceKind",New TypeDescription("CatalogRef.TypesOfPrices"));
		TSUsedMaterials.FillValues(SamplingOfManufacturedProductsOfOrder.PriceKind, "PriceKind");
		
		TSUsedMaterials.Columns.Add("Currency",New TypeDescription("CatalogRef.Currencies"));
		TSUsedMaterials.FillValues(SamplingOfManufacturedProductsOfOrder.Currency, "Currency");
		
		TSUsedMaterials.FillValues(SamplingOfManufacturedProductsOfOrder.BillOfMaterials, "BillOfMaterials");
		
		For Each CurrentData In TSUsedMaterials Do
			
			NewRow = CostTable.Add();
			FillPropertyValues(NewRow, CurrentData);
			
			NewRow.QuantityAccordingToBOR = CurrentData.Count;
			QuantityAccordingToBOR = NewRow.QuantityAccordingToBOR;
			
			Filter = New Structure(SearchKey);
			FillPropertyValues(Filter, NewRow);
			
			For Each MaterialOfMaterialProvider In TableOfGiverSMaterials.FindRows(Filter) Do
				
				If MaterialOfMaterialProvider.Count = 0 Then
					Continue;
				EndIf;
				
				Count = Min(QuantityAccordingToBOR, MaterialOfMaterialProvider.Count);
				
				NewRow.QuantityIsProvidedByGiver = NewRow.QuantityIsProvidedByGiver + Count;
				
				MaterialOfMaterialProvider.Count = MaterialOfMaterialProvider.Count - Count;
				QuantityAccordingToBOR = QuantityAccordingToBOR - Count;
				
				If QuantityAccordingToBOR = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Query.Text =
	"SELECT
	|	CostTable.MaterialProviderOrder                      AS MaterialProviderOrder,
	|	CostTable.BillOfMaterials                       AS BillOfMaterials,
	|	CostTable.ManufacturedProduct                          AS ManufacturedProduct,
	|	CostTable.ItemVariant            AS ItemVariant,
	|	CAST(CostTable.Products AS Catalog.Products)                 AS Products,
	|	CAST(CostTable.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CostTable.QuantityAccordingToBOR           AS QuantityAccordingToBOR,
	|	CostTable.QuantityIsProvidedByGiver AS QuantityIsProvidedByGiver,
	|	CostTable.PriceKind                            AS PriceKind,
	|	CostTable.Currency                             AS Currency
	|INTO TTCostTable
	|FROM
	|	&CostTable AS CostTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CostTable.MaterialProviderOrder                      AS MaterialProviderOrder,
	|	CostTable.BillOfMaterials                       AS BillOfMaterials,
	|	CostTable.ManufacturedProduct                          AS ManufacturedProduct,
	|	CostTable.ItemVariant            AS ItemVariant,
	|	CostTable.Products                       AS Products,
	|	CostTable.Characteristic                     AS Characteristic,
	|	SUM(CostTable.QuantityAccordingToBOR)           AS QuantityAccordingToBOR,
	|	SUM(CostTable.QuantityIsProvidedByGiver) AS QuantityIsProvidedByGiver,
	|	CostTable.Currency                             AS Currency,
	|	CAST(CASE
	|		WHEN &UsePriceManagementSystem25
	|			THEN
	|				ItemPrices25CrossSectionOfTheLatest.Price
	|				* CASE
	|					WHEN CostTable.Currency <> ItemPrices25CrossSectionOfTheLatest.Currency
	|						THEN CASE
	|							WHEN ISNULL(CurrencyRatesPrices25.CourseDenominator, 0) > 0
	|								AND ISNULL(CurrencyRatesPrices25.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|								THEN
	|									(CurrencyRatesPrices25.CourseNumerator * Currency_Rates.CourseDenominator)
	|									/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices25.CourseDenominator)
	|							ELSE 0
	|						END
	|					ELSE 1
	|				END
	|		ELSE
	|			ItemPricesCrossSectionOfTheLatest.Price
	|			* CASE
	|				WHEN CostTable.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|					THEN CASE
	|						WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN
	|								(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|								/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|							ELSE 0
	|					END
	|				ELSE 1
	|			END
	|	END AS NUMBER(31,2))                           AS Price,
	|	SUM(CAST(CASE
	|			WHEN &UsePriceManagementSystem25
	|				THEN
	|					ItemPrices25CrossSectionOfTheLatest.Price
	|					* CASE
	|						WHEN CostTable.Currency <> ItemPrices25CrossSectionOfTheLatest.Currency
	|							THEN CASE
	|								WHEN ISNULL(CurrencyRatesPrices25.CourseDenominator, 0) > 0
	|									AND ISNULL(CurrencyRatesPrices25.CourseNumerator, 0) > 0
	|									AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|									AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|									THEN
	|										(CurrencyRatesPrices25.CourseNumerator * Currency_Rates.CourseDenominator)
	|										/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices25.CourseDenominator)
	|								ELSE 0
	|							END
	|						ELSE 1
	|					END
	|			ELSE
	|				ItemPricesCrossSectionOfTheLatest.Price
	|				* CASE
	|					WHEN CostTable.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|						THEN CASE
	|							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|								THEN
	|									(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|									/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|								ELSE 0
	|						END
	|					ELSE 1
	|				END
	|		END AS NUMBER(31,2))
	|		* (CostTable.QuantityAccordingToBOR
	|			- CostTable.QuantityIsProvidedByGiver)) AS OwnMaterials
	|INTO CostTable
	|FROM
	|	TTCostTable AS CostTable
	|	
	|	LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|	ON (ItemKinds.Ref = CostTable.Products.ProductKind)
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON Currency_Rates.Currency = CostTable.Currency
	|	
	|	LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&Period) AS ItemPricesCrossSectionOfTheLatest
	|	ON CostTable.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|	AND CostTable.Products = ItemPricesCrossSectionOfTheLatest.Products
	|	AND CostTable.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|	AND NOT &UsePriceManagementSystem25
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON CurrencyRatesPrices.Currency       = ItemPricesCrossSectionOfTheLatest.Currency
	|	AND NOT &UsePriceManagementSystem25
	|	
	|	LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(&Period) AS ItemPrices25CrossSectionOfTheLatest
	|	ON ItemPrices25CrossSectionOfTheLatest.Products = CostTable.Products
	|	AND ItemPrices25CrossSectionOfTheLatest.PricingVariant =
	|		ISNULL(CASE
	|				WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|				ELSE CostTable.Characteristic.ItemsCharacteristicForPricing
	|			END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
	|	AND ItemPrices25CrossSectionOfTheLatest.PricingBatch = VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|	AND ItemPrices25CrossSectionOfTheLatest.PricingPackage = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	AND CostTable.PriceKind = ItemPrices25CrossSectionOfTheLatest.PriceKind
	|	AND &UsePriceManagementSystem25
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices25
	|	ON CurrencyRatesPrices25.Currency       = ItemPrices25CrossSectionOfTheLatest.Currency
	|	AND &UsePriceManagementSystem25
	|
	|GROUP BY
	|	CostTable.MaterialProviderOrder,
	|	CostTable.BillOfMaterials,
	|	CostTable.ManufacturedProduct,
	|	CostTable.ItemVariant,
	|	CostTable.Products,
	|	CostTable.Characteristic,
	|	CostTable.PriceKind,
	|	CostTable.Currency,
	|	CAST(CASE
	|		WHEN &UsePriceManagementSystem25
	|			THEN
	|				ItemPrices25CrossSectionOfTheLatest.Price
	|				* CASE
	|					WHEN CostTable.Currency <> ItemPrices25CrossSectionOfTheLatest.Currency
	|						THEN CASE
	|							WHEN ISNULL(CurrencyRatesPrices25.CourseDenominator, 0) > 0
	|								AND ISNULL(CurrencyRatesPrices25.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|								THEN
	|									(CurrencyRatesPrices25.CourseNumerator * Currency_Rates.CourseDenominator)
	|									/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices25.CourseDenominator)
	|							ELSE 0
	|						END
	|					ELSE 1
	|				END
	|		ELSE
	|			ItemPricesCrossSectionOfTheLatest.Price
	|			* CASE
	|				WHEN CostTable.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|					THEN CASE
	|						WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN
	|								(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|								/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|							ELSE 0
	|					END
	|				ELSE 1
	|			END
	|	END AS NUMBER(31,2))
	|
	|INDEX BY
	|	MaterialProviderOrder,
	|	BillOfMaterials,
	|	ManufacturedProduct,
	|	ItemVariant
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CostTable.MaterialProviderOrder                     AS MaterialProviderOrder,
	|	CostTable.ManufacturedProduct                         AS ManufacturedProduct,
	|	CostTable.ItemVariant           AS ItemVariant,
	|	CostTable.BillOfMaterials                      AS BillOfMaterials,
	|	SUM(CostTable.OwnMaterials) AS OwnMaterials
	|INTO AmountsOfOwnMaterials
	|FROM
	|	CostTable AS CostTable
	|WHERE
	|	VALUETYPE(CostTable.MaterialProviderOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|
	|GROUP BY
	|	CostTable.MaterialProviderOrder,
	|	CostTable.ManufacturedProduct,
	|	CostTable.ItemVariant,
	|	CostTable.BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableProduction.Ref            AS MaterialProviderOrder,
	|	TableProduction.Products      AS ManufacturedProduct,
	|	TableProduction.Characteristic    AS ItemVariant,
	|	TableProduction.BillOfMaterials      AS BillOfMaterials,
	|	SUM(TableProduction.Count) AS Count,
	|	SUM(ISNULL(AmountsOfOwnMaterials.OwnMaterials, 0))       AS OwnMaterials,
	|	SUM(TableProduction.Sum)
	|		- SUM(ISNULL(AmountsOfOwnMaterials.OwnMaterials, 0)) AS Amount,
	|	SUM(TableProduction.Sum)      AS Sum
	|INTO AmountsOfOrders
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS TableProduction
	|	
	|	LEFT JOIN AmountsOfOwnMaterials AS AmountsOfOwnMaterials
	|	ON AmountsOfOwnMaterials.MaterialProviderOrder = TableProduction.Ref
	|	AND AmountsOfOwnMaterials.ManufacturedProduct = TableProduction.Products
	|	AND AmountsOfOwnMaterials.ItemVariant = TableProduction.Characteristic
	|	AND AmountsOfOwnMaterials.BillOfMaterials = TableProduction.BillOfMaterials
	|	
	|WHERE
	|	TableProduction.Ref IN(&ObjectsArray)
	|	AND NOT TableProduction.Canceled
	|	AND NOT TableProduction.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|GROUP BY
	|	TableProduction.Ref,
	|	TableProduction.BillOfMaterials,
	|	TableProduction.Products,
	|	TableProduction.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CostTable.MaterialProviderOrder                          AS MaterialProviderOrder,
	|	CostTable.Currency                                 AS DocumentCurrency,
	|	CostTable.BillOfMaterials                           AS BillOfMaterials,
	|	CostTable.ManufacturedProduct                              AS ManufacturedProduct,
	|	CostTable.ItemVariant                AS ItemVariant,
	|	CostTable.Products                           AS Products,
	|	CostTable.Characteristic                         AS Characteristic,
	|	CostTable.QuantityAccordingToBOR               AS QuantityAccordingToBOR,
	|	CostTable.QuantityIsProvidedByGiver     AS QuantityIsProvidedByGiver,
	|	CostTable.Price                                   AS Price,
	|	ISNULL(AmountsOfOrders.OwnMaterials, 0) AS AmountOfMaterialsBilled,
	|	ISNULL(AmountsOfOrders.Amount, 0)                AS ServiceAmountBilled,
	|	ISNULL(AmountsOfOrders.Sum, 0)                      AS TotalAmountBilled
	|FROM
	|	CostTable AS CostTable
	|	
	|	LEFT JOIN AmountsOfOrders AS AmountsOfOrders
	|	ON AmountsOfOrders.MaterialProviderOrder = CostTable.MaterialProviderOrder
	|	AND AmountsOfOrders.BillOfMaterials = CostTable.BillOfMaterials
	|	AND AmountsOfOrders.ManufacturedProduct = CostTable.ManufacturedProduct
	|	AND AmountsOfOrders.ItemVariant = CostTable.ItemVariant
	|";
	
	Query.SetParameter("CostTable", CostTable);
	Query.SetParameter("Period", ?(ValueIsFilled(Period), Period, EndOfDay(CurrentSessionDate())));
	Query.SetParameter("UsePriceManagementSystem25", PriceManagementSystemServerCall.UsePriceManagementSystem25());
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Return Query.Execute().Unload();
	
EndFunction

Function NewCostTable()
	
	TypesOfGiverSOrder = TypesOfGiverSOrder();
	
	CostTable = New ValueTable;
	CostTable.Columns.Add("MaterialProviderOrder",New TypeDescription(TypesOfGiverSOrder));
	CostTable.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
	CostTable.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
	CostTable.Columns.Add("ManufacturedProduct",New TypeDescription("CatalogRef.Products"));
	CostTable.Columns.Add("ItemVariant",New TypeDescription("CatalogRef.ItemsCharacteristics"));
	CostTable.Columns.Add("QuantityAccordingToBOR",New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Nonnegative)));
	CostTable.Columns.Add("QuantityIsProvidedByGiver",New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Nonnegative)));
	CostTable.Columns.Add("PriceKind",New TypeDescription("CatalogRef.TypesOfPrices"));
	CostTable.Columns.Add("Currency",New TypeDescription("CatalogRef.Currencies"));
	CostTable.Columns.Add("BillOfMaterials",New TypeDescription("CatalogRef.BillsOfMaterials"));
	
	Return CostTable;
	
EndFunction

Function TypesOfGiverSOrder()
	
	TypesOfGiverSOrder = New Array;
	TypesOfGiverSOrder.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	
	Return TypesOfGiverSOrder;
	
EndFunction

#EndRegion

#EndIf

