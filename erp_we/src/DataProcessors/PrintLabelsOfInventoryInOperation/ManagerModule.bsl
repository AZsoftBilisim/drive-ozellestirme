
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "DataProcessor.PrintLabelsOfInventoryInOperation";
	
	SeriesSpecificationParameters.UseItemsBatch = GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	SeriesSpecificationParameters.UseCostAccountingByBatches = SeriesSpecificationParameters.UseItemsBatch;
	
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	SeriesSpecificationParameters.FieldNameQuantity = "Count";
	SeriesSpecificationParameters.NameTSGoods = "InventoryInOperation";
	SeriesSpecificationParameters.TSSeriesName = "InventoryInOperation";
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
// 
// Parameters:
//	SeriesSpecificationParameters - See SeriesSpecificationParameters
//		
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingInventoryInOperation
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 18
	|					ELSE 17
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|
	|INTO Statuses
	|
	|FROM
	|	Goods AS Goods
	|
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Series = ProductsToRequest.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion
	
#EndRegion

#Region Private

#Region Print

Function ToFormPrintedFormOfTMTSVLabel(PrintData, ObjectsArray) Export
	
	SettingsStructure = DataProcessors.PrintPriceTagsAndLabels.SettingsStructure();
	SettingsStructure.RequiredFields.Add("AssetID");
	SettingsStructure.RequiredFields.Add("Products");
	If GetFunctionalOption("UseItemVariants") Then
		SettingsStructure.RequiredFields.Add("Characteristic");
	EndIf;
	If GetFunctionalOption("UseItemsBatchWarehouse", New Structure()) Then
		SettingsStructure.RequiredFields.Add("Series");
	EndIf;
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsOfInventoryInOperation";
	
	Copies = PrintData.Copies;
	
	SettingsStructure.RawData = GetFromTempStorage(PrintData.AddressInStorage);
	
	If Not PrintData.Property("StructureOfTemplateTemplate") Or Not ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		LabelsTemplate = Common.ObjectAttributeValue(PrintData.LabelsTemplate, "Template"); // ValueStorage
		TemplateStructure = LabelsTemplate.Get(); // Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	Else
		TemplateStructure = PrintData.StructureOfTemplateTemplate; // Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	EndIf;
	
	For Each Item In TemplateStructure.TemplateParameters Do
		SettingsStructure.RequiredFields.Add(Item.Key);
	EndDo;
	
	ResultStructure1 = DataProcessors.PrintPriceTagsAndLabels.PrepareDataStructure(SettingsStructure, "InventoryInOperation");
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	TemplateImage = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = TemplateImage.Height / 100;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	ColumnNumber = 0;
	RowNumber = 0;
	
	Area = TemplateStructure.LabelTemplate.GetArea(TemplateStructure.AreaNameSeals);
	
	For Each TableRow In ResultStructure1.Table Do
		
		FillPropertyValues(SpreadsheetDocument, TemplateStructure.LabelTemplate, , "PrintArea");
		
		For Each TemplateParameter In TemplateStructure.TemplateParameters Do
			If TMCommonUseClientServer.HasObjectAttribute(Area.Parameters, TemplateParameter.Value) Then
				ColumnDescription = ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(TemplateParameter.Key));
				If ColumnDescription <> Undefined Then
					Area.Parameters[TemplateParameter.Value] = TableRow[ColumnDescription];
				EndIf;
			EndIf;
		EndDo;
		
		For Each Drawing In Area.Drawings Do
			If StrFind(Drawing.Name, Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter()) = 1 Then
				
				BarcodeValue = TableRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("AssetID")];
				If ValueIsFilled(BarcodeValue) Then
					
					BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
					
					BarcodeParameters.Width = Round(Drawing.Width / NumberOfMillimetersPerPixel);
					BarcodeParameters.Height = Round(Drawing.Height / NumberOfMillimetersPerPixel);
					BarcodeParameters.Barcode = TrimAll(BarcodeValue);
					BarcodeParameters.InputDataType = 0; // A barcode is a string
					BarcodeParameters.CodeType = TemplateStructure.CodeType;
					BarcodeParameters.TextVisible = TemplateStructure.TextVisible;
					BarcodeParameters.FontSize = TemplateStructure.FontSize;
					
					If TemplateStructure.Property("GS1DatabarRowCount") Then
						BarcodeParameters.GS1DatabarRowCount = TemplateStructure.GS1DatabarRowCount;
					EndIf;
					If TemplateStructure.Property("CanvasRotation") Then
						BarcodeParameters.CanvasRotation = TemplateStructure.CanvasRotation;
					EndIf;
					
					TheImageOfTheBarcode = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters);
					If TheImageOfTheBarcode <> Undefined Then
						Drawing.Picture = TheImageOfTheBarcode.Picture;
					EndIf;
					
				EndIf;
				
			EndIf;
		EndDo;
		
		For Indus = 1 To Copies Do // Cycle by number of instances
			
			ColumnNumber = ColumnNumber + 1;
			
			If ColumnNumber = 1 Then
				
				RowNumber = RowNumber + 1;
				
				SpreadsheetDocument.Put(Area);
				
			Else
				
				SpreadsheetDocument.Join(Area);
				
			EndIf;
			
			If ColumnNumber = TemplateStructure.HorizontalQuantity
				And RowNumber = TemplateStructure.VerticalQuantity Then
				
				RowNumber    = 0;
				ColumnNumber = 0;
				
				SpreadsheetDocument.PutHorizontalPageBreak();
				
			ElsIf ColumnNumber = TemplateStructure.HorizontalQuantity Then
				
				ColumnNumber = 0;
				
			EndIf;
			
		EndDo; // Cycle by number of instances
		
	EndDo; // Cycle through the rows of the table
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
