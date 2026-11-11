#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Function ToFormPrintedFormOfLabelOfObjectsOfOperation(PrintData, ObjectsArray) Export
	
	SettingsStructure = DataProcessors.PrintPriceTagsAndLabels.SettingsStructure();
	SettingsStructure.RequiredFields.Add("Asset");
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "FieldsOfTemplateAssets";
	
	Copies = PrintData.Copies;
	
	SettingsStructure.RawData = GetFromTempStorage(PrintData.AddressInStorage);
	
	If Not PrintData.Property("StructureOfTemplateTemplate") Or Not ValueIsFilled(PrintData.StructureOfTemplateTemplate) Then
		StorageLabelTemplate = Common.ObjectAttributeValue(PrintData.LabelsTemplate, "Template"); // ValueStorage
		TemplateStructure = StorageLabelTemplate.Get(); // Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	Else
		TemplateStructure = PrintData.StructureOfTemplateTemplate; // Structure - See Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate
	EndIf;
	
	For Each Item In TemplateStructure.TemplateParameters Do
		SettingsStructure.RequiredFields.Add(Item.Key);
	EndDo;
	
	ResultStructure1 = DataProcessors.PrintPriceTagsAndLabels.PrepareDataStructure(SettingsStructure, "Assets");
	
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
				
				BarcodeValue = TableRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get(Catalogs.LabelAndPriceTagTemplates.NameOfBarcodeParameter())];
				If ValueIsFilled(BarcodeValue) Then
					
					BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
					BarcodeParameters.Insert("Width",           Round(Drawing.Width / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Height",           Round(Drawing.Height / NumberOfMillimetersPerPixel));
					BarcodeParameters.Insert("Barcode",         TrimAll(BarcodeValue));
					BarcodeParameters.Insert("InputDataType", 0); // A barcode is a string
					BarcodeParameters.Insert("CodeType",          TemplateStructure.CodeType);
					BarcodeParameters.Insert("TextVisible",  TemplateStructure.TextVisible);
					BarcodeParameters.Insert("FontSize",     TemplateStructure.FontSize);
					
					If TemplateStructure.Property("GS1DatabarRowCount") Then
						BarcodeParameters.Insert("GS1DatabarRowCount", TemplateStructure.GS1DatabarRowCount);
					EndIf;
					If TemplateStructure.Property("FontType") Then
						BarcodeParameters.Insert("FontType", TemplateStructure.MonochromeFont);
					EndIf;
					If TemplateStructure.Property("CanvasRotation") Then
						BarcodeParameters.Insert("CanvasRotation", TemplateStructure.CanvasRotation);
					EndIf;
					
					Drawing.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
					
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
