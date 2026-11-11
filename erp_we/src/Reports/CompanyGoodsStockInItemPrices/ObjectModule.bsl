#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	PriceViewParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	If PriceViewParameter <> Undefined Then
		If Not ValueIsFilled(PriceViewParameter.Value) Then
			If Not GetFunctionalOption("UseSeveralPriceTypes") Then
				DataCompositionClientServer.SetParameter(SettingsComposer, "PriceKind", PriceManagementSystemServerCall.PriceTypePriceList_());
			EndIf;
		Else
			CurrencyOfPriceType_ = Common.ObjectAttributeValue(PriceViewParameter.Value, "PriceCurrency");
			
			DataCompositionClientServer.SetParameter(SettingsComposer, "CurrencyOfPriceType_", CurrencyOfPriceType_);
		EndIf;
	EndIf;
	
	ResultDocument.Clear();
	TemplateComposer = New DataCompositionTemplateComposer;
		
	DataCompositionSchema = Reports.CompanyGoodsStockInItemPrices.GetTemplate("MainDataCompositionSchema");
	
	PriceViewParameter = DataCompositionSchema.Parameters.Find("PriceKind");
	ReportOptionParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportVariant");
	
	If PriceViewParameter <> Undefined And ReportOptionParameter <> Undefined Then
		If ReportOptionParameter.Value = "MovementOfGoodsTransferredToCommission25" Then
			PriceViewParameter.DenyIncompleteValues = False;
		Else
			PriceViewParameter.DenyIncompleteValues = True;
		EndIf;
	EndIf;
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		ExecutableDataSet	= DataCompositionSchema.DataSets.Find("Query2_5");
		DataSetToBeDeleted		= DataCompositionSchema.DataSets.Find("Query");
	Else
		ExecutableDataSet	= DataCompositionSchema.DataSets.Find("Query");
		DataSetToBeDeleted		= DataCompositionSchema.DataSets.Find("Query2_5");
	EndIf;
	
	DataCompositionSchema.DataSets.Delete(DataSetToBeDeleted);
	
	QueryText = ExecutableDataSet.Query;
	
	If GetFunctionalOption("UseItemPackages") Then
		
		ReplacementText = 
		"CASE
		|		WHEN PricesOfProduct.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor1, 0) = 0
		|			THEN PricesOfProduct.Price
		|		ELSE PricesOfProduct.Price / &QueryTextPackagingFactor1
		|	END";
		
		QueryText = StrReplace(QueryText, "&CurrentPrice", ReplacementText);
		
		ReplacementText = 
		"CASE
		|		WHEN PricesOfProductB.Price IS NULL 
		|			THEN 0
		|		WHEN PricesOfProductB.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor2, 0) = 0
		|			THEN PricesOfProductB.Price
		|		ELSE PricesOfProductB.Price / &QueryTextPackagingFactor2
		|	END";
		
		QueryText = StrReplace(QueryText, "&OldPrice", ReplacementText);
		
		ReplacementText = 
		"CASE
		|		WHEN PricesOfProduct.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor1, 0) = 0
		|			THEN PricesOfProduct.Price
		|		ELSE PricesOfProduct.Price / &QueryTextPackagingFactor1
		|	END - CASE
		|		WHEN PricesOfProductB.Price IS NULL 
		|			THEN 0
		|		WHEN PricesOfProductB.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor2, 0) = 0
		|			THEN PricesOfProductB.Price
		|		ELSE PricesOfProductB.Price / &QueryTextPackagingFactor2
		|	END";
		
		QueryText = StrReplace(QueryText, "&Delta", ReplacementText);
		
	Else
		
		ReplacementText = 
		"PricesOfProduct.Price";
		
		QueryText = StrReplace(QueryText, "&CurrentPrice", ReplacementText);
		
		ReplacementText = 
		"CASE
		|		WHEN
		|			PricesOfProductB.Price IS NULL
		|		THEN
		|			0
		|		ELSE
		|			PricesOfProductB.Price
		|	END";
		
		QueryText = StrReplace(QueryText, "&OldPrice", ReplacementText);
		
		ReplacementText = 
		"PricesOfProduct.Price
		|		- CASE
		|			WHEN
		|				PricesOfProductB.Price IS NULL
		|			THEN
		|				0
		|			ELSE
		|				PricesOfProductB.Price
		|		END";
		QueryText = StrReplace(QueryText, "&Delta", ReplacementText);
		
	EndIf;
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor1",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"PricesOfProduct.Package",
									"PricesOfProduct.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor2",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"PricesOfProductB.Package",
									"PricesOfProductB.Products"));
	
	ExecutableDataSet.Query = QueryText;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		SettingsComposer.GetSettings(),
		DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor, True);
	OutputProcessor.EndOutput();
	
EndProcedure

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
		
EndProcedure

#EndRegion

#EndIf
