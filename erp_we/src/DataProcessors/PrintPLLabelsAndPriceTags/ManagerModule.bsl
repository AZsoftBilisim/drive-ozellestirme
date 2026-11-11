#If Server Then

#Region Public

// Create printed forms of objects
//
// Parameters:
//  ObjectsArray - Array of CatalogRef, DocumentRef - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects - ValueList of ValueListItem - value is a reference to an object;
//                                            view - the name of the area in which the object was output (output parameter);
//  OutputParameters - Structure - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	GeneratePrintForms(ObjectsArray, PrintParameters, PrintObjects, PrintFormsCollection);
EndProcedure

// Template fields.
// 
// Parameters:
//  PrintTemplates - Array of Structure - Print Templates
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.TemplatesOfPLLabelsAndPriceTags
//   * Value - Array of See NewDescriptionField
//
Function TemplatesFields(PrintTemplates) Export
	
	ErrorMessage = "";
	ContentsOfXMLFile = "";
	
	MatchingTemplatesAndFields = New Map;
	
	For Each TemplateRow In PrintTemplates Do
		
		FieldList = New Array;
		Template = TemplateRow.PriceTagLabelTemplate;
		XMLTemplateDetails = CommonCEL.ObjectAttributeValue(Template, "XMLTemplateDetails");
		PeripheralsLabelPrintersServer.GetTemplateDescription(XMLTemplateDetails, ErrorMessage, ContentsOfXMLFile);
		
		For Each DescriptionOfXMLField In ContentsOfXMLFile.Fields Do
			FieldDetails = NewDescriptionField();
			
			FillPropertyValues(FieldDetails, DescriptionOfXMLField);
			If DescriptionOfXMLField.Property("Background") Then
				FieldDetails.BackColor = DescriptionOfXMLField.Background;
			EndIf;
			FieldList.Add(FieldDetails);
		EndDo;
		MatchingTemplatesAndFields.Insert(TemplateRow.PriceTagLabelTemplate, FieldList);
	EndDo;
	
	Return MatchingTemplatesAndFields;
	
EndFunction

// Label printing data.
// 
// Parameters:
//  ProductDataForFormationOfPrintedForms - Array of Structure - Nomenclature data for the formation of printed forms
//  MatchingFieldsAndTemplates - Map of KeyAndValue - Matching fields and templates
// 
// Returns:
//  Array of Structure:
//   * LabelPrintingData - Structure:
// 	    ** Count - Number -
// 	    ** Fields - Array of String -
//      ** Width - Number - 
// 	    ** Height - Number
//   * Template - CatalogRef.TemplatesOfPLLabelsAndPriceTags
//   * XMLTemplateDetails - String
//
Function LabelPrintingData(ProductDataForFormationOfPrintedForms, MatchingFieldsAndTemplates) Export
	
	DataForPrintedForms = New Array;
	For Each DataForTemplate In ProductDataForFormationOfPrintedForms Do
		
		AttributeValue = Undefined;
		ResultTable2 = DataForTemplate.ProductsTable; // ValueTable
		
		FieldAliases = New Map;
		AliasesOfPaths = New Map;
		FieldsForFillIn = MatchingFieldsAndTemplates.Get(DataForTemplate.Template);
		For Each Field In FieldsForFillIn Do
			Simple = Field.Value;
			If ValueIsFilled(Simple) Then
				FieldAliases.Insert(Field.Description, Simple);
				
				PathAlias = AliasesOfPaths[Simple];
				If PathAlias = Undefined Then
					AliasesOfPaths.Insert(Simple, Field.Description);
					
					PathAlias = Field.Description;
				EndIf; 
			EndIf;
		EndDo;
		
		ColumnHeaders = New Map;
		For Each Column In ResultTable2.Columns Do
			ColumnHeaders.Insert(Column.Title, Column.Name);
		EndDo;
		
		For Each FieldAlias In FieldAliases Do
			Simple = FieldAlias.Value;
			
			PathAlias = AliasesOfPaths[Simple];
			If PathAlias <> Undefined 
				And ColumnHeaders[PathAlias] <> Undefined Then
				
				FieldAliases[FieldAlias.Key] = ColumnHeaders[PathAlias];
			Else
				
				FieldAliases[FieldAlias.Key] = "";
			EndIf; 
			
		EndDo;
		
		ParameterData = New ValueTable;
		ParameterData.Columns.Add("RowID", New TypeDescription("Number"));
		ParameterData.Columns.Add("AttributesValues");
		
		For Each ResultString1 In ResultTable2 Do
			
			AttributesValues = New Structure;
			For Each FieldDetails In FieldAliases Do
				If ValueIsFilled(FieldDetails.Value) Then
					FieldKey = "_"+StrReplace(FieldDetails.Key, "-", "");
					AttributesValues.Insert(FieldKey, ResultString1[FieldDetails.Value]);
				EndIf; 
			EndDo; 
			
			NewRow = ParameterData.Add();
			NewRow.RowID  = ResultTable2.IndexOf(ResultString1);
			NewRow.AttributesValues   = AttributesValues;
			
		EndDo;
		
		FilterStructure1 = New Structure("RowID");
		LabelPrintingData = New Array;
		For Each OwnGoods In ResultTable2 Do
			LabelData = NewLabelData();
			XMLTemplateDetails  = OwnGoods.PriceTagTemplateForPrinting.XMLTemplateDetails;
			ErrorMessage  = "";
			ContentsOfXMLFile = "";
			PeripheralsLabelPrintersServer.GetTemplateDescription(XMLTemplateDetails, ErrorMessage, ContentsOfXMLFile);
			LabelData.Count = OwnGoods.NumberOfPriceTagsToPrint;
			LabelData.Width = ContentsOfXMLFile.Width;
			LabelData.Height = ContentsOfXMLFile.Height;
			
			For Each TemplateField In FieldsForFillIn Do
				If TemplateField.Type = "UserData" Then
					Continue;
				EndIf;
				
				// For each item, there will be several records of the query result that differ in the marking code.
				FilterStructure1.RowID = ResultTable2.IndexOf(OwnGoods);
				FoundRows = ParameterData.FindRows(FilterStructure1);
				If FoundRows.Count() = 0 Then
					Continue;
				EndIf; 
				
				AttributesValues = FoundRows[0].AttributesValues;
				
				FieldValues = New Structure;
				FieldValues.Insert("FieldName",          TemplateField.Description);
				FieldValues.Insert("FieldDetails",     TemplateField);
				
				AttributeValueKey = "_"+StrReplace(TemplateField.Description, "-", "");
				
				If Not (TemplateField.Type = "Barcode" Or TemplateField.PopulationType = "Parameter")
					Or Not ValueIsFilled(TemplateField.Value) 
					Or Not AttributesValues.Property(AttributeValueKey, AttributeValue) Then
					
					AttributeValue = "";
				EndIf;
				
				If TemplateField.Type = "Barcode" Then
					FieldValues.Insert("Value", AttributeValue);
				ElsIf TemplateField.PopulationType = "Parameter" Then
					If TypeOf(AttributeValue) = Type("ValueStorage") Then
						AttributeValue = AttributeValue.Get();
						
						If TypeOf(AttributeValue) = Type("BinaryData") Then
							AttributeValue = Base64String(AttributeValue);
						Else
							AttributeValue = String(AttributeValue);
						EndIf;
					EndIf;
					
					If ValueIsFilled(AttributeValue) Then
						FieldValues.Insert("Value", ?(ValueIsFilled(TemplateField.Format), Format(AttributeValue, TemplateField.Format), AttributeValue));
					Else
						If ValueIsFilled(TemplateField.DefaultValue) Then
							FieldValues.Insert("Value", ?(ValueIsFilled(TemplateField.Format), Format(TemplateField.DefaultValue, TemplateField.Format), TemplateField.DefaultValue));
						Else
							FieldValues.Insert("Value", ?(ValueIsFilled(TemplateField.Format), Format("", TemplateField.Format), ""));
						EndIf;
					EndIf;
				Else
					FieldValues.Insert("Value", TemplateField.Value);
				EndIf;
				
				LabelData.Fields.Add(FieldValues);
			EndDo;
			LabelPrintingData.Add(LabelData);
		EndDo; 
		
		DataStructureForPrintedForms = New Structure;
		DataStructureForPrintedForms.Insert("LabelPrintingData", LabelPrintingData);
		DataStructureForPrintedForms.Insert("Template", DataForTemplate.Template);
		DataStructureForPrintedForms.Insert("XMLTemplateDetails", XMLTemplateDetails);
		DataForPrintedForms.Add(DataStructureForPrintedForms);
	EndDo;
	Return DataForPrintedForms;
	
EndFunction

// A completed tabular document.
// 
// Parameters:
//  Resolution - Structure - Resolution:
//   * NumberOfMillimetersPerPixelHeight - Number -
//   * NumberOfMillimetersPerPixelWidth - Number -
//   * OneMillimeterWide - Number -
//   * OneMillimeterOfHeight - Number -
//  LabelData - See NewLabelData.
//  ErrorMessage - String - Error message
// 
// Returns:
//  SpreadsheetDocument - Completed tabular document
//
Function CompletedTabularDocument(Resolution, LabelData, ErrorMessage) Export
	SpreadsheetDocument = New SpreadsheetDocument;
	
	If LabelData.Count()>0 Then
		FieldValues = New Structure;
		
		For Each Field In LabelData.Fields Do
			
			FieldName      = "P"+StrReplace(Field.FieldName, "-", "");
			FieldDetails = Field.FieldDetails;
			Simple = Field.Value;
			
			If FieldDetails.Type = "UserData" Then
				Continue;
			EndIf;
			
			TableDocumentArea = SaveFieldDesign(FieldName, FieldDetails, SpreadsheetDocument);
			
			If FieldDetails.Type = "Barcode" Then
				AreaWidth = ?(Resolution.NumberOfMillimetersPerPixelWidth = 0, 0, 
				(FieldDetails.Right - FieldDetails.Left)/Resolution.NumberOfMillimetersPerPixelWidth);
				
				AreaHeight = ?(Resolution.NumberOfMillimetersPerPixelHeight = 0, 0, 
				(FieldDetails.Bottom - FieldDetails.Top)/Resolution.NumberOfMillimetersPerPixelHeight);
				
				// The barcode can only be a string
				BarcodeString_ = TrimAll(String(Simple));
				
				BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();      
				BarcodeParameters.Width = AreaWidth;
				BarcodeParameters.Height = AreaHeight;
				BarcodeParameters.Barcode = BarcodeString_;
				BarcodeParameters.CodeType  = BarcodeTypeByName(FieldDetails.BarcodeType);
				BarcodeParameters.TextVisible = FieldDetails.BarcodeLabel = "true"; 
				BarcodeParameters.Zoomable = True;
				If FieldDetails.BarcodeLabel = "true" And ValueIsFilled(FieldDetails.SignatureFontSize) Then
					BarcodeParameters.FontSize = FieldDetails.SignatureFontSize;
				EndIf; 
				If ValueIsFilled(FieldDetails.Orientation) Then
					BarcodeParameters.CanvasRotation = FieldDetails.Orientation;// One of the following values: 0, 90, 180, 270.
				EndIf; 
				BarcodeParameters.BgTransparent = True;
				If FieldDetails.Property("QRErrorCorrectionLevel") Then
					BarcodeParameters.QRErrorCorrectionLevel = FieldDetails.QRErrorCorrectionLevel;
				EndIf;  
				
				Try     
					TheResultOfTheFormationOfBarcode = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters);
					TableDocumentArea.Picture = TheResultOfTheFormationOfBarcode.Picture;
				Except
					ErrorText = NStr("vi = 'Không thể tạo mã vạch.
					|%1';
					|ru = 'Не удалось сформировать штрихкод.
					|%1';
					|en = 'Cannot generate the barcode.
					|%1'; fa = 'Cannot generate the barcode.
					|%1';
					|it = 'Impossibile creare il codice a barre.
					|%1';
					|pl = 'Nie udało się wygenerować kodu kreskowego.
					|%1';
					|tr = 'Barkod oluşturulamadı.
					|%1'");
					ErrorDescription = StrTemplate(ErrorText, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					
					CommonCEL.WriteErrorToEventLog(
							NStr("vi = 'In nhãn tem';
								|ru = 'Печать этикеток';
								|en = 'Print labels'; fa = 'چاپ برچسب‌ها';
								|it = 'Stampa di etichette';
								|pl = 'Drukowanie etykiet';
								|tr = 'Etiketleri yazdır'", CommonCEL.DefaultLanguageCode()), 
							ErrorDescription,
							Metadata.DataProcessors.PrintPLLabelsAndPriceTags);
					
					ErrorMessage = NStr("vi = 'Không thể tạo mã vạch';
										|ru = 'Не удалось сформировать штрихкод';
										|en = 'Cannot generate the barcode'; fa = 'Cannot generate the barcode';
										|it = 'Impossibile creare codice a barre';
										|pl = 'Nie udało się wygenerować kodu kreskowego';
										|tr = 'Barkod oluşturulamadı'");
				EndTry; 
				
			ElsIf FieldDetails.Type = "Image" Then 
				BinaryData = Base64Value(Simple);
				
				TableDocumentArea.Picture = New Picture(BinaryData, True);
				If FieldDetails.PictureSize = "Stretch" Then
					AreaImageSize = PictureSize.Stretch;
				ElsIf FieldDetails.PictureSize = "AutoSize" Then
					AreaImageSize = PictureSize.AutoSize;
				ElsIf FieldDetails.PictureSize = "ByFontSize" Then
					AreaImageSize = PictureSize.ByFontSize;
				ElsIf FieldDetails.PictureSize = "Proportionally" Then
					AreaImageSize = PictureSize.Proportionally;
				ElsIf FieldDetails.PictureSize = "RealSize" Then
					AreaImageSize = PictureSize.RealSize;
				ElsIf FieldDetails.PictureSize = "Tile" Then
					AreaImageSize = PictureSize.Tile;
				EndIf;
				TableDocumentArea.PictureSize = AreaImageSize;
			ElsIf FieldDetails.PopulationType = "Parameter" Then
				If TypeOf(Simple) = Type("ValueStorage") Then
					Simple = Simple.Get();
					
					If TypeOf(Simple) = Type("BinaryData") Then
						Simple = Base64String(Simple);
					Else
						Simple = String(Simple);
					EndIf;
				EndIf;
				
				If ValueIsFilled(Simple) Then
					FieldValues.Insert(FieldName, ?(ValueIsFilled(FieldDetails.Format), Format(Simple, FieldDetails.Format), Simple));
				Else
					If ValueIsFilled(FieldDetails.DefaultValue) Then
						FieldValues.Insert(FieldName, ?(ValueIsFilled(FieldDetails.Format), Format(FieldDetails.DefaultValue, FieldDetails.Format), FieldDetails.DefaultValue));
					Else
						FieldValues.Insert(FieldName, ?(ValueIsFilled(FieldDetails.Format), Format("", FieldDetails.Format), ""));
					EndIf;
				EndIf;
			Else
				FieldValues.Insert(FieldName, FieldDetails.Value);
			EndIf;
		EndDo;
		
		SpreadsheetDocument.Parameters.Fill(FieldValues);
	EndIf;
	
	Return SpreadsheetDocument;
EndFunction

// Save the design of the field.
// 
// Parameters:
//  FieldName - String - field name
//  FieldDetails - See NewDescriptionField
//  SpreadsheetDocument - SpreadsheetDocument - Table document
// 
// Returns:
//  SpreadsheetDocumentRange, SpreadsheetDocumentDrawing - Keep the registration fields
//
Function SaveFieldDesign(FieldName, FieldDetails, SpreadsheetDocument) Export
	
	If FieldDetails.Type = "Text" Or FieldDetails.Type = "Image" Then
		
		Area = SpreadsheetDocument.Area(FieldDetails.Top+1,FieldDetails.Left+1, FieldDetails.Bottom+1, FieldDetails.Right+1);
		Area.Merge();
		
		Area.Name = FieldName;
		
		If FieldDetails.PopulationType = "Constant" And Not FieldDetails.Type = "Image" Then
			Area.FillType=SpreadsheetDocumentAreaFillType.Text;
			Area.Text = FieldDetails.Value;
		Else
			Area.FillType=SpreadsheetDocumentAreaFillType.Parameter;
			Area.Parameter = FieldName;
		EndIf;
		
		If FieldDetails.Multiline Then
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
		Else
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Cut;
		EndIf;
		
		Area.TextOrientation = FieldDetails.Orientation;
		
		If FieldDetails.HorizontalPosition = "Left" Then
			Area.HorizontalAlign=HorizontalAlign.Left;
		ElsIf FieldDetails.HorizontalPosition = "Center" Then
			Area.HorizontalAlign=HorizontalAlign.Center;
		ElsIf FieldDetails.HorizontalPosition = "Right" Then
			Area.HorizontalAlign=HorizontalAlign.Right;
		Else
			Area.HorizontalAlign=HorizontalAlign.Left;
		EndIf;
		
		If FieldDetails.VerticalPosition = "Top" Then
			Area.VerticalAlign=VerticalAlign.Top;
		ElsIf FieldDetails.VerticalPosition = "Center" Then
			Area.VerticalAlign=VerticalAlign.Center;
		ElsIf FieldDetails.VerticalPosition = "Bottom" Then
			Area.VerticalAlign=VerticalAlign.Bottom;
		Else
			Area.VerticalAlign=VerticalAlign.Top;
		EndIf;
		
		Area.Font = New Font(FieldDetails.FontName,FieldDetails.FontSize, FieldDetails.Fatty, FieldDetails.Italic, FieldDetails.Underline, FieldDetails.Strikeout);
		If Not FieldDetails.BackColor = Undefined Then
			Area.BackColor = FieldDetails.BackColor;
		EndIf;
		
		If FieldDetails.BorderType = "Solid" Then
			LineType = SpreadsheetDocumentCellLineType.Solid;
		ElsIf FieldDetails.BorderType = "Double" Then
			LineType = SpreadsheetDocumentCellLineType.Double;
		ElsIf FieldDetails.BorderType = "Dotted" Then
			LineType = SpreadsheetDocumentCellLineType.Dotted;
		ElsIf FieldDetails.BorderType = "Dashed" Then
			LineType = SpreadsheetDocumentCellLineType.LargeDashed;
		Else
			LineType = SpreadsheetDocumentCellLineType.None;
		EndIf;
		
		Border = New Line(LineType, FieldDetails.FrameWidth);
		
		If FieldDetails.LeftFrame Then
			Area.LeftBorder=Border;
		Else
			Area.LeftBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
		If FieldDetails.RightFrame Then
			Area.RightBorder=Border;
		Else
			Area.RightBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
		If FieldDetails.TopFrame Then
			Area.TopBorder=Border;
		Else
			Area.TopBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
		If FieldDetails.BottomFrame Then
			Area.BottomBorder=Border;
		Else
			Area.BottomBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
	ElsIf FieldDetails.Type = "Barcode" Then
		LocationOfImage = SpreadsheetDocument.Area(FieldDetails.Top + 1, FieldDetails.Left + 1, FieldDetails.Bottom+1, FieldDetails.Right+1);
		
		Area = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		
		Area.Place(LocationOfImage);
		Area.PictureSize = PictureSize.Proportionally;
		Area.LeftBorder   = FieldDetails.LeftFrame;
		Area.RightBorder  = FieldDetails.RightFrame;
		Area.TopBorder  = FieldDetails.TopFrame;
		Area.BottomBorder   = FieldDetails.BottomFrame;
		
	EndIf;
	
	Return Area;
EndFunction

#EndRegion

#Region Private

Procedure GeneratePrintForms(ObjectsArray, PrintParameters, PrintObjects, PrintFormsCollection)
	Var ErrorMessage, EachLabelIsOnNewSheet;
	
	If Not PrintParameters.Property("EachLabelIsOnNewSheet", EachLabelIsOnNewSheet) Then
		EachLabelIsOnNewSheet = False;
	EndIf;
	PrintFormsCollection.Clear();
	Resolution = ReferenceResolution();
	
	TemplateOfProductTable = TableOfProductValues();
	GoodsTable = ConvertArrayToTableOfValues(PrintParameters.Goods, TemplateOfProductTable);
	
	TemplatesForPrinting = GoodsTable.Copy(New Structure("Selected", True),"PriceTagLabelTemplate");
	ProductsForPrinting = GoodsTable.Copy(New Structure("Selected", True));
	
	MatchingFieldsAndTemplates = TemplatesFields(TemplatesForPrinting);
	
	ProductDataForFormationOfPrintedForms = PrintPLLabelsAndPriceTagsOverridable.DataForFormationOfPrintedForms(PrintParameters, MatchingFieldsAndTemplates, ProductsForPrinting);
	DataOfPrintedForms = LabelPrintingData(ProductDataForFormationOfPrintedForms, MatchingFieldsAndTemplates);
	
	For Each PrintForm In DataOfPrintedForms Do
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.FitToPage = False;
		
		Line = New Line(SpreadsheetDocumentCellLineType.ThinDashed,1);
		Template = PrintForm.Template;
		Template_Attributes = CommonCEL.ObjectAttributesValues(Template, "Description, Template");
		Var_76_Template = Template_Attributes.Template.Get();
		If Not Var_76_Template = Undefined Then
			FillPropertyValues(SpreadsheetDocument, Var_76_Template,, "PrintArea");
			FitToPage = Var_76_Template.FitToPage;
		Else
			FitToPage = False;
		EndIf;
		
		For Each LabelData In PrintForm.LabelPrintingData Do
			
			LabelTemplate = CompletedTabularDocument(Resolution, LabelData, ErrorMessage).GetArea(1, 1, LabelData.Height+1, LabelData.Width+1);
			
			LabelTemplate.Area().AutoRowHeight = False;
			LabelTemplate.Area().RowHeight =  Resolution.OneMillimeterOfHeight;
			LabelTemplate.Area().ColumnWidth = Resolution.OneMillimeterWide;
			
			LabelTemplate.Area(1,1, LabelData.Height+1, LabelData.Width+1).Outline(Line, Line, Line, Line);
			
			For Counter = 1 To LabelData.Count Do
				
				Try
					YouCanAttach = Not EachLabelIsOnNewSheet 
					And SpreadsheetDocument.CheckAttachment(CommonCELClientServer.ValueInArray(LabelTemplate));
				Except
					// If the printer is not installed, or the user has selected each label separately, we print everything in a column
					YouCanAttach = Not EachLabelIsOnNewSheet;
				EndTry;
				
				If YouCanAttach Then
					SpreadsheetDocument.Join(LabelTemplate);
				Else
					// Calling BSP
					ModuleCommon = CommonCEL.CommonModule("Common");
					YouCanOutput = Not EachLabelIsOnNewSheet 
						And ModuleCommon.SpreadsheetDocumentFitsPage(
							SpreadsheetDocument, 
							CommonCELClientServer.ValueInArray(LabelTemplate), 
							False);
					// The end of the BSP Challenge
					
					If Not YouCanOutput Then
						SpreadsheetDocument.PutHorizontalPageBreak();
					EndIf;
					
					SpreadsheetDocument.Put(LabelTemplate);
				EndIf;
			EndDo;
		EndDo;
		
		// Calling BSP
		ModulePrintManager = CommonCEL.CommonModule("PrintManagement");
		ModulePrintManager.SetDocumentPrintArea(SpreadsheetDocument, 1, PrintObjects, ObjectsArray[0]);
		// The end of the BSP Challenge
		
		If ValueIsFilled(ErrorMessage) Then
			CommonCEL.MessageToUser(ErrorMessage);
		EndIf; 
		
		SpreadsheetDocument.FitToPage = FitToPage;
		
		TemplateName = Template_Attributes.Description;
		NewForm = PrintFormsCollection.Add();
		NewForm.TemplateName         = TemplateName;
		NewForm.TemplateSynonym     = TemplateName;
		NewForm.UpperCaseName           = Upper(TemplateName);
		NewForm.SpreadsheetDocument = SpreadsheetDocument;
		NewForm.Copies2       = 1;
		
	EndDo;
	
EndProcedure

Function ReferenceResolution()
	
	Resolution = New Structure;
	
	Etalon = ReferenceTemplate();
	Drawing = Etalon.Drawings[0];
	
	LineHeightInMillimeters = Drawing.Top;
	ColumnWidthInMillimeters = Drawing.Left;
	
	RowHeight	= Etalon.Area("R1").RowHeight;
	ColumnWidth_1	= Etalon.Area("C1").ColumnWidth;
	
	Resolution.Insert("NumberOfMillimetersPerPixelHeight", Drawing.Height/200);
	Resolution.Insert("NumberOfMillimetersPerPixelWidth", Drawing.Width/200);
	Resolution.Insert("OneMillimeterWide",                 ColumnWidth_1 / ColumnWidthInMillimeters);
	Resolution.Insert("OneMillimeterOfHeight",                 RowHeight / LineHeightInMillimeters);
	
	Return Resolution;
	
EndFunction

Function ReferenceTemplate()
	
	Return Catalogs.Peripherals.GetTemplate("LayoutForDeterminingTheCoefficientsOfUnitsOfMeasurement");
	
EndFunction

// Returns the field description
//
// Returns:
//  Structure
Function NewDescriptionField()
	Result = New Structure;
	
	Result.Insert("Description",           "");
	Result.Insert("Presentation",          "");
	Result.Insert("Type",                    "");
	Result.Insert("PopulationType");
	Result.Insert("DefaultValue");
	Result.Insert("Value");
	Result.Insert("Top",                   0);
	Result.Insert("Left",                   0);
	Result.Insert("Bottom",                    0);
	Result.Insert("Right",                  0);
	Result.Insert("Orientation");
	Result.Insert("FontName");
	Result.Insert("FontSize");
	Result.Insert("Fatty",                 False);
	Result.Insert("Italic",              False);
	Result.Insert("Underline",          False);
	Result.Insert("Strikeout",           False);
	Result.Insert("LeftFrame",             False);
	Result.Insert("TopFrame",            False);
	Result.Insert("RightFrame",            False);
	Result.Insert("BottomFrame",             False);
	Result.Insert("BorderType");
	Result.Insert("FrameWidth");
	Result.Insert("BarcodeType");
	Result.Insert("SignatureFontSize");
	Result.Insert("BarcodeLabel");
	Result.Insert("CheckCharacter");
	Result.Insert("HorizontalPosition", "Left");
	Result.Insert("VerticalPosition",   "Top");
	Result.Insert("Multiline",        False);
	Result.Insert("Format"); 
	Result.Insert("BackColor"); 
	Result.Insert("PictureSize",         "Stretch");
	
	Return Result;
EndFunction 

Function BarcodeTypeByName(CodeTypeByString) 
	
	If CodeTypeByString = "EAN8" Then
		CodeType = 0;
	ElsIf CodeTypeByString = "EAN13" Then
		CodeType = 1;
	ElsIf CodeTypeByString = "EAN128" Then
		CodeType = 2;
	ElsIf CodeTypeByString = "CODE39" Then
		CodeType = 3;
	ElsIf CodeTypeByString = "CODE128" Then
		CodeType = 4;
	ElsIf CodeTypeByString = "ITF14" Then
		CodeType = 11;
	ElsIf CodeTypeByString = "EAN13Addon2" Then
		CodeType = 14;
	ElsIf CodeTypeByString = "EAN13Addon5" Then
		CodeType = 15;
	ElsIf CodeTypeByString = "QR" Or CodeTypeByString = "QRCode" Then
		CodeType = 16;
	ElsIf CodeTypeByString = "GS1DataBarExpandedStacked" Then
		CodeType = 17;
	ElsIf CodeTypeByString = "DataMatrix" Then
		CodeType = 18;
	ElsIf CodeTypeByString = "GS1-DataMatrix" Then
		CodeType = 24;      
	Else
		CodeType = 99;
	EndIf;
	
	Return CodeType; 
	
EndFunction

// New label data.
// 
// Returns:
//  Structure - New Label Data:
//   * Count - Number -
//   * Fields - Array of String -
//   * Width - Number - 
//   * Height - Number
//
Function NewLabelData() Export
	
	LabelData = New Structure;
	LabelData.Insert("Count", 1);
	LabelData.Insert("Fields", New Array);
	LabelData.Insert("Width");
	LabelData.Insert("Height");
	
	Return LabelData;
	
EndFunction

Function TableOfProductValues()
	
	Return PrintPLLabelsAndPriceTags.TableOfProductValues();
	
EndFunction

Function ConvertArrayToTableOfValues(DataArray, ValueTable)
	
	For Each ArrayElement In DataArray Do
		NewRow = ValueTable.Add();
		For Each MeaningOfStructure In ArrayElement Do
			NewRow[MeaningOfStructure.Key] = MeaningOfStructure.Value;
		EndDo;
	EndDo;
	
	Return ValueTable;
	
EndFunction

#EndRegion
#EndIf