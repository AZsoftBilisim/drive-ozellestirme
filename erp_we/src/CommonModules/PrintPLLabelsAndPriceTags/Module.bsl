#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in predefined elements in the directory Templates of labels and price tags.
//
Procedure FillInPredefinedElements() Export
	
	Catalogs.TemplatesOfPLLabelsAndPriceTags.OnInitialItemsFilling();
	
EndProcedure

// update the label Templates to the new format.
//
// Parameters:
//  Parameters - Structure
//
Procedure UpdateLabelTemplates(Parameters = Undefined) Export 
	
	Templates = New Array;
	PrintPLLabelsAndPriceTagsOverridable.UpdateLabelTemplates(Templates);
	
	For Each Template In Templates Do // Structure
		
		Try
			
			ObjectFromTemplate = Template.Template.Get();
			
			If Not ValueIsFilled(ObjectFromTemplate) Then
				Continue;
			EndIf;
			
			XMLTextOfNewTemplate = ConvertTemplateToXML(ObjectFromTemplate.TabularDocumentEditor);
			
			BeginTransaction();
			Try
				Block = New DataLock();
				LockItem = Block.Add("Catalog.TemplatesOfPLLabelsAndPriceTags");
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				NewItem = Catalogs.TemplatesOfPLLabelsAndPriceTags.CreateItem();
				
				NewItem.Description = Template.Description;
				NewItem.XMLTemplateDetails = XMLTextOfNewTemplate;
				NewItem.DataCompositionSchema = Template.DataCompositionSchema;
				NewItem.Template = Template.Template;
				NewItem.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				ErrorTextTemplate = NStr("vi = 'Không thể tạo mới mẫu in nhãn tem:
				|%1';
				|ru = 'Не удалось создать новый макет этикетки:
				|%1';
				|en = 'Cannot create a new label template:
				|%1'; fa = 'Cannot create a new label template:
				|%1';
				|it = 'Не удалось создать новый макет этикетки:
				|%1';
				|pl = 'Cannot create a new label template:
				|%1';
				|tr = 'Yeni numune etiket oluşturma başarısız:
				|%1'", CommonCEL.DefaultLanguageCode());
				ErrorText = StrTemplate(ErrorTextTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				CommonCEL.WriteErrorToEventLog(
					NStr("vi = 'Cập nhật cơ sở thông tin';
						|ru = 'Обновление информационной базы';
						|en = 'Infobase update'; fa = 'به‌روزرسانی پایگاه اطلاعات';
						|it = 'Aggiornamento del database';
						|pl = 'Aktualizacja bazy informacyjnej';
						|tr = 'Infobase güncellemesi'", CommonCEL.DefaultLanguageCode()),
					ErrorText);
			EndTry;
			
		Except
			Continue;
		EndTry
			
	EndDo;
	
EndProcedure

// Returns a table of product values for printing labels
//
// Returns:
//  ValueTable:
//   * Selected - Boolean
//   * PlItems - DefinedType.PlItems
//   * PlVariant - DefinedType.PlVariant
//   * PlPackagingUnit - DefinedType.PlPackagingUnit
//   * CompanyCEL - DefinedType.CompanyCEL
//   * Price - DefinedType.MonetaryAmountNonNegative
//   * Barcode - String
//   * PriceTagLabelTemplate - CatalogRef.TemplatesOfPLLabelsAndPriceTags
//   * Count - Number
//   * LineNumber - Number
//   * SourceLineNumber - Number
//
Function TableOfProductValues() Export
	
	StandardProcessing = True;
	
	StringType = New TypeDescription("String", , New StringQualifiers(200));
	
	TableOfProductValues = New ValueTable;
	TableOfProductValues.Columns.Add("Selected", New TypeDescription("Boolean"));
	TableOfProductValues.Columns.Add("PlItems", New TypeDescription(StringType, Metadata.DefinedTypes.PlItems.Type.Types()));
	TableOfProductValues.Columns.Add("PlVariant", New TypeDescription(StringType, Metadata.DefinedTypes.PlVariant.Type.Types()));
	TableOfProductValues.Columns.Add("PlPackagingUnit", New TypeDescription(StringType, Metadata.DefinedTypes.PlPackagingUnit.Type.Types()));
	TableOfProductValues.Columns.Add("CompanyCEL", New TypeDescription(StringType, Metadata.DefinedTypes.CompanyCEL.Type.Types()));
	TableOfProductValues.Columns.Add("Price", New TypeDescription(StringType, Metadata.DefinedTypes.MonetaryAmountNonNegative.Type.Types()));
	TableOfProductValues.Columns.Add("Barcode", New TypeDescription("String",,,, New StringQualifiers(200)));
	TableOfProductValues.Columns.Add("PriceTagLabelTemplate", New TypeDescription("CatalogRef.TemplatesOfPLLabelsAndPriceTags",));
	TableOfProductValues.Columns.Add("Count", New TypeDescription("Number",,, New NumberQualifiers(10, 0, AllowedSign.Any)));
	TableOfProductValues.Columns.Add("LineNumber", New TypeDescription("Number"));
	TableOfProductValues.Columns.Add("SourceLineNumber", New TypeDescription("Number"));
	
	PrintPLLabelsAndPriceTagsOverridable.TableOfProductValues(StandardProcessing, TableOfProductValues);
	
	Return TableOfProductValues;
	
EndFunction

#EndRegion

#Region Internal

Function ConvertTemplateToXML(Template, ThisIsTemplateConversion = False) Export
	
	Try
		Area = Template.Area("R1C1"); // SpreadsheetDocumentRange
		ColumnWidth_1 = Area.Comment.Width;
		RowHeight = Area.Comment.Height;
		
		XMLWriter = New XMLWriter;
		XMLWriter.SetString();
		XDTOSerializer.WriteXML(XMLWriter, Template);
		XMLTemplateText = XMLWriter.Close();
		XMLReader = New XMLReader;
		XMLReader.SetString(XMLTemplateText);
		
		DOMBuilder = New DOMBuilder;
		DOMDocument = DOMBuilder.Read(XMLReader); 
		
		MainNode = DOMDocument.ChildNodes.Item(0);
		
		ColumnsMap = New Map;
		FormatMatching = New Map;
		MatchingRows = New Map;
		BarcodeMatching = New Map;
		MatchingImages = New Map;
		TemplateParameters = New Array;
		Pictures = New Array; 
		NumberOfFormatNumber = 1;
		TableOfConnections = New ValueTable();
		TableOfConnections.Columns.Add("Column");
		TableOfConnections.Columns.Add("Row");
		TableOfConnections.Columns.Add("Width");
		TableOfConnections.Columns.Add("Height"); 
		ParametersTable = New ValueTable();
		ParametersTable.Columns.Add("Row");
		ParametersTable.Columns.Add("Column");
		ParametersTable.Columns.Add("Parameter"); 
		TableOfImages = New ValueTable();
		TableOfImages.Columns.Add("InitialColumn");
		TableOfImages.Columns.Add("FinalColumn");
		TableOfImages.Columns.Add("OffsetFromLeft");
		TableOfImages.Columns.Add("OffsetToRight");
		TableOfImages.Columns.Add("InitialRow");
		TableOfImages.Columns.Add("FinalRow");
		TableOfImages.Columns.Add("OffsetFromAbove");
		TableOfImages.Columns.Add("DisplacementFromBelow");
		TableOfImages.Columns.Add("ID_Image");
		TableOfImages.Columns.Add("IDOfImage");
		
		Fields = New ValueTable;
		Fields.Columns.Add("Description");
		Fields.Columns.Add("Presentation");
		Fields.Columns.Add("Type");
		Fields.Columns.Add("PopulationType");
		Fields.Columns.Add("DefaultValue");
		Fields.Columns.Add("Value");
		Fields.Columns.Add("Top");
		Fields.Columns.Add("Left");
		Fields.Columns.Add("Bottom");
		Fields.Columns.Add("Right");
		Fields.Columns.Add("Orientation");
		Fields.Columns.Add("FontName");
		Fields.Columns.Add("FontSize");
		Fields.Columns.Add("Fatty");
		Fields.Columns.Add("Italic");
		Fields.Columns.Add("Underline");
		Fields.Columns.Add("Strikeout");
		Fields.Columns.Add("LeftFrame");
		Fields.Columns.Add("TopFrame");
		Fields.Columns.Add("RightFrame");
		Fields.Columns.Add("BottomFrame");
		Fields.Columns.Add("BorderType");
		Fields.Columns.Add("FrameWidth");
		Fields.Columns.Add("BarcodeType");
		Fields.Columns.Add("SignatureFontSize");
		Fields.Columns.Add("BarcodeLabel");
		Fields.Columns.Add("CheckCharacter");
		Fields.Columns.Add("HorizontalPosition",);
		Fields.Columns.Add("VerticalPosition",);
		Fields.Columns.Add("Multiline",);
		Fields.Columns.Add("Format");
		Fields.Columns.Add("Background");
		
		For Each Node In MainNode.ChildNodes Do
			
			If Node.NodeName = "columns" Then
				
				For Each ChildSubAssetOfColumn In Node.ChildNodes Do
					
					If ChildSubAssetOfColumn.NodeName = "size" Then
						NumberOfColumnsOfTemplate = Number(ChildSubAssetOfColumn.ChildNodes[0].TextContent);
					EndIf;
					
					If ChildSubAssetOfColumn.NodeName = "columnsItem" Then
						ColumnsMap.Insert(Number(ChildSubAssetOfColumn.ChildNodes[0].TextContent), ChildSubAssetOfColumn.ChildNodes[1].TextContent);
					EndIf;
					
				EndDo;
				
			EndIf;
			
			If Node.NodeName = "format" Then
				If Node.ChildNodes.Count() > 0 Then
					FormatMatching.Insert(NumberOfFormatNumber, Node.ChildNodes[0].TextContent);
				Else
					FormatMatching.Insert(NumberOfFormatNumber, "0");
				EndIf;
				NumberOfFormatNumber = NumberOfFormatNumber + 1;
			EndIf;
			
			If Node.NodeName = "rowsItem" Then
				If Node.ChildNodes[1].ChildNodes[0].NodeName = "formatIndex" Then
					MatchingRows.Insert(Number(Node.ChildNodes[0].TextContent), Node.ChildNodes[1].ChildNodes[0].TextContent);
					NumberOfAddFormat = Node.ChildNodes[1].ChildNodes[0].TextContent;
				Else
					MatchingRows.Insert(Number(Node.ChildNodes[0].TextContent), "0");
					NumberOfAddFormat = "0";
				EndIf;
				If Node.ChildNodes[1].NodeName = "indexTo" Then
					MapCount = Number(Node.ChildNodes[1].TextContent) - Number(Node.ChildNodes[0].TextContent);
					AddedMatches = 0;
					While AddedMatches <> MapCount Do
						AddedMatches = AddedMatches + 1;
						MatchingRows.Insert(Number(Node.ChildNodes[0].TextContent) + AddedMatches, NumberOfAddFormat);
					EndDo;
				EndIf;
				IndexOfRow = Number(Node.ChildNodes[0].TextContent);
				For Each ChildSubAssetOfRow In Node.ChildNodes Do
					If ChildSubAssetOfRow.NodeName = "row" Then
						ColumnNumber = 0;
						For Each ChildSubAssetOfSecondOrderOfSeries In ChildSubAssetOfRow.ChildNodes Do
							If ChildSubAssetOfSecondOrderOfSeries.NodeName = "c" Then
								If ChildSubAssetOfSecondOrderOfSeries.ChildNodes[0].NodeName = "i" Then
									ColumnIndex = ChildSubAssetOfSecondOrderOfSeries.ChildNodes[0].TextContent;
								Else
									ColumnIndex = ColumnNumber;
									ColumnNumber = ColumnNumber + 1;
								EndIf;
								For Each ChildSubAssetOfThirdOrderOfSeries In ChildSubAssetOfSecondOrderOfSeries.ChildNodes Do
									If ChildSubAssetOfThirdOrderOfSeries.NodeName = "c" And ChildSubAssetOfThirdOrderOfSeries.ChildNodes.Count() > 1 Then
										ParameterNode = ChildSubAssetOfThirdOrderOfSeries.ChildNodes[1];
										If ParameterNode.NodeName = "tl" And ParameterNode.ChildNodes.Count() >= 1 Then
											ParameterName_ = ParameterNode.ChildNodes[0].ChildNodes[1].TextContent;
										ElsIf ParameterNode.NodeName = "parameter" Then
											ParameterName_ = ParameterNode.TextContent;
										Else
											Continue;
										EndIf;
										NewParameter1 = ParametersTable.Add();
										NewParameter1.Row = IndexOfRow;
										NewParameter1.Column = ColumnIndex;
										NewParameter1.Parameter = ParameterName_;
									EndIf;
								EndDo;
							EndIf;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
			If Node.NodeName = "merge" Then
				NewConnection_ = TableOfConnections.Add();
				For Each ChildSubAssetOfConnection In Node.ChildNodes Do
					If ChildSubAssetOfConnection.NodeName = "r" Then
						NewConnection_.Row = Number(ChildSubAssetOfConnection.TextContent);
					ElsIf ChildSubAssetOfConnection.NodeName = "c" Then
						NewConnection_.Column = Number(ChildSubAssetOfConnection.TextContent);
					ElsIf ChildSubAssetOfConnection.NodeName = "w" Then
						NewConnection_.Width = Number(ChildSubAssetOfConnection.TextContent);
					ElsIf ChildSubAssetOfConnection.NodeName = "h" Then
						NewConnection_.Height = Number(ChildSubAssetOfConnection.TextContent);
					EndIf;
				EndDo;
			EndIf;
			
			If Node.NodeName = "namedItem" Then
				BarcodeMatching.Insert(Node.ChildNodes[1].TextContent, Node.ChildNodes[0].TextContent);
			EndIf;
			
			If Node.NodeName = "picture" Then
				MatchingImages.Insert(Node.ChildNodes[0].TextContent, Node.ChildNodes[1].TextContent);
			EndIf;
			
			If Node.NodeName = "drawing" Then
				ImageOfTemplate = TableOfImages.Add();
				For Each ChildImageSubAsset In Node.ChildNodes Do
					If ChildImageSubAsset.NodeName = "id" Then
						ImageOfTemplate.ID_Image = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "beginRow" Then
						ImageOfTemplate.InitialRow = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "beginRowOffset" Then
						ImageOfTemplate.OffsetFromAbove = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "endRow" Then
						ImageOfTemplate.FinalRow = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "endRowOffset" Then
						ImageOfTemplate.DisplacementFromBelow = ChildImageSubAsset.TextContent;
					EndIf; 
					If ChildImageSubAsset.NodeName = "beginColumn" Then
						ImageOfTemplate.InitialColumn = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "beginColumnOffset" Then
						ImageOfTemplate.OffsetFromLeft = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "endColumn" Then
						ImageOfTemplate.FinalColumn = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "endColumnOffset" Then
						ImageOfTemplate.OffsetToRight = ChildImageSubAsset.TextContent;
					EndIf;
					If ChildImageSubAsset.NodeName = "pictureIndex" Then
						ImageOfTemplate.IDOfImage = ChildImageSubAsset.TextContent;
					EndIf;
					
				EndDo;
			EndIf;
			
			If Node.NodeName = "defaultFormatIndex" Then
				DefaultFormat = Node.ChildNodes[0].TextContent;
			EndIf;
			
		EndDo;
		
		CurrentColumn = 0;
		TemplateWidth = 0;
		NumberOfPixelsPerUnitWidth = Undefined;
		NumberOfPixelsPerUnitHeight = Undefined;
		While CurrentColumn < NumberOfColumnsOfTemplate Do
			ColumnFormatValue = ColumnsMap.Get(CurrentColumn);
			Try
				ColumnWidth = ?(ColumnFormatValue <> "0", Number(FormatMatching.Get(Number(ColumnFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
			Except
				ColumnWidth = 48;
			EndTry;
			TemplateWidth = ColumnWidth + TemplateWidth;
			CurrentColumn = CurrentColumn + 1;
		EndDo;
		NumberOfPixelsPerUnitWidth = TemplateWidth/ColumnWidth_1;
		
		TemplateHeight = 0;
		For Each Row In MatchingRows Do
			RowFormatValue = Row.Value;
			Try 
				HeightOfRow = ?(RowFormatValue <> "0", Number(FormatMatching.Get(Number(RowFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
			Except
				HeightOfRow = 72;
			EndTry;
			TemplateHeight = TemplateHeight + HeightOfRow;
		EndDo;
		NumberOfPixelsPerUnitHeight = TemplateHeight/RowHeight;
		
		For Each TemplateParameter_ In ParametersTable Do
			
			Filter = New Structure();
			Filter.Insert("Column", TemplateParameter_.Column);
			Filter.Insert("Row", TemplateParameter_.Row);
			Rows = TableOfConnections.FindRows(Filter);
			
			If Rows.Count() = 0 Then
				StringStructure = New Structure;
				StringStructure.Insert("Width", 1);
				StringStructure.Insert("Height", 1);
				StringStructure.Insert("Column", TemplateParameter_.Column);
				StringStructure.Insert("Row", TemplateParameter_.Row);
				Rows.Add(StringStructure);
			Else
				CurrentColumn = Number(Rows[0].Column);
			EndIf;
			ColumnsCount = ?(ValueIsFilled(Rows[0].Width), Number(Rows[0].Width) + CurrentColumn, CurrentColumn);
			ParameterWidth = 0;
			While ColumnsCount >= CurrentColumn Do
				ColumnFormatValue = ColumnsMap.Get(CurrentColumn);
				ColumnWidth = ?(ValueIsFilled(ColumnFormatValue), Number(FormatMatching.Get(Number(ColumnFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
				ParameterWidth = ParameterWidth + ColumnWidth;
				CurrentColumn = CurrentColumn + 1;
			EndDo; 
			
			LeftMargin = 0;
			CurrentColumn = Number(Rows[0].Column);
			InitialColumn = 0;
			While InitialColumn < CurrentColumn Do
				ColumnFormatValue = ColumnsMap.Get(InitialColumn);
				ColumnWidth = ?(ValueIsFilled(ColumnFormatValue), Number(FormatMatching.Get(Number(ColumnFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
				LeftMargin = LeftMargin + ColumnWidth;
				InitialColumn = InitialColumn + 1;
			EndDo;
			
			CurCURRENTSeries = Number(Rows[0].Row);
			RowsNumber = ?(ValueIsFilled(Rows[0].Height), Number(Rows[0].Height) + CurCURRENTSeries, CurCURRENTSeries);
			ParameterHeight = 0;
			While RowsNumber >= CurCURRENTSeries Do
				RowFormatValue = MatchingRows.Get(CurCURRENTSeries); 
				HeightOfRow = ?(RowFormatValue <> "0", Number(FormatMatching.Get(Number(RowFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
				ParameterHeight = ParameterHeight + HeightOfRow;
				CurCURRENTSeries = CurCURRENTSeries + 1;
			EndDo;
			
			TopMargin = 0;
			CurCURRENTSeries = Number(Rows[0].Row);
			InitialRow = 0;
			While InitialRow <= CurCURRENTSeries Do
				RowFormatValue = MatchingRows.Get(InitialRow);
				HeightOfRow = ?(RowFormatValue <> "0", Number(FormatMatching.Get(Number(RowFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
				TopMargin = TopMargin + HeightOfRow;
				InitialRow = InitialRow + 1;
			EndDo;
			
			NewField = Fields.Add();
			NewField.Right = ?(Int((ParameterWidth + LeftMargin)/NumberOfPixelsPerUnitWidth) <> 0 , Int((ParameterWidth + LeftMargin)/NumberOfPixelsPerUnitWidth), 1);
			NewField.Left = ?(Int(LeftMargin/NumberOfPixelsPerUnitWidth) <> 0, Int(LeftMargin/NumberOfPixelsPerUnitWidth), 1);
			NewField.Top = ?(Int(TopMargin/NumberOfPixelsPerUnitHeight) <> 0, Int(TopMargin/NumberOfPixelsPerUnitHeight), 1);
			NewField.Bottom = ?(Int((TopMargin + ParameterHeight)/NumberOfPixelsPerUnitHeight) <> 0, Int((TopMargin + ParameterHeight)/NumberOfPixelsPerUnitHeight), 1);
			NewField.Value = TemplateParameter_.Parameter; 
			NewField.Type = "Text";
			NewField.PopulationType = "Parameter";
			NewField.FontSize = 6;
			NewField.FontName = "Arial";
			NewField.Fatty = False;
			NewField.Italic = False; 
			NewField.Underline = False;
			NewField.Strikeout = False; 
			NewField.TopFrame = False;
			NewField.LeftFrame = False;
			NewField.RightFrame = False;
			NewField.BottomFrame = False;
			
			NewField.Description = New UUID();
			
		EndDo;
		
		If Not ThisIsTemplateConversion Then
			For Each Image_Of_Template In TableOfImages Do
				
				CurrentColumn = Number(Image_Of_Template.InitialColumn);
				ParameterWidth = 0;
				While CurrentColumn <= Number(Image_Of_Template.FinalColumn) Do
					ColumnFormatValue = ColumnsMap.Get(CurrentColumn);
					ColumnWidth = ?(ValueIsFilled(ColumnFormatValue), Number(FormatMatching.Get(Number(ColumnFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
					ParameterWidth = ParameterWidth + ColumnWidth;
					CurrentColumn = CurrentColumn + 1;
				EndDo;
				ParameterWidth = TemplateWidth - Image_Of_Template.OffsetFromLeft - Image_Of_Template.OffsetToRight;
				
				LeftMargin = 0;
				CurrentColumn = Image_Of_Template.InitialColumn;
				InitialColumn = 0;
				While InitialColumn < Number(CurrentColumn) Do
					ColumnFormatValue = ColumnsMap.Get(InitialColumn);
					ColumnWidth = ?(ValueIsFilled(ColumnFormatValue), Number(FormatMatching.Get(Number(ColumnFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
					LeftMargin = LeftMargin + ColumnWidth;
					InitialColumn = InitialColumn + 1;
				EndDo;
				LeftMargin = LeftMargin + Image_Of_Template.OffsetFromLeft;
				
				CurCURRENTSeries = Number(Image_Of_Template.InitialRow);
				ParameterHeight = 0;
				While CurCURRENTSeries < Number(Image_Of_Template.FinalRow) Do
					RowFormatValue = MatchingRows.Get(CurCURRENTSeries);
					HeightOfRow = ?(RowFormatValue <> "0", Number(FormatMatching.Get(Number(RowFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
					ParameterHeight = ParameterHeight + HeightOfRow;
					CurCURRENTSeries = CurCURRENTSeries + 1;
				EndDo;
				ParameterHeight = ParameterHeight - Image_Of_Template.OffsetFromAbove - Image_Of_Template.DisplacementFromBelow;
				
				TopMargin = 0;
				CurCURRENTSeries = Number(Image_Of_Template.InitialRow);
				InitialRow = 0;
				While InitialRow < CurCURRENTSeries Do
					RowFormatValue = MatchingRows.Get(InitialRow);
					ColumnWidth = ?(RowFormatValue <> "0", Number(FormatMatching.Get(Number(RowFormatValue))), Number(FormatMatching.Get(Number(DefaultFormat))));
					TopMargin = TopMargin + HeightOfRow;
					InitialRow = InitialRow + 1;
				EndDo;
				TopMargin = TopMargin + Image_Of_Template.OffsetFromAbove;
				
				NewField = Fields.Add();
				NewField.Right = Round((ParameterWidth + LeftMargin)/NumberOfPixelsPerUnitWidth);
				NewField.Left = Round(LeftMargin/NumberOfPixelsPerUnitWidth);
				NewField.Top = Round(TopMargin/NumberOfPixelsPerUnitHeight);
				NewField.Bottom = Round((TopMargin + ParameterHeight)/NumberOfPixelsPerUnitHeight);
				NewField.BarcodeType = "EAN13";
				If ValueIsFilled(BarcodeMatching.Get(Image_Of_Template.ID_Image)) Then
					NewField.Type = "Barcode";
					NewField.PopulationType = "Parameter";
					NewField.BarcodeLabel = "false"; 
					NewField.Value = "Barcode";
				Else
					NewField.Type = "Image";
					NewField.PopulationType = "Constant";
					NewField.Value = MatchingImages.Get(Image_Of_Template.IDOfImage);
					NewField.TopFrame = False;
					NewField.LeftFrame = False;
					NewField.BottomFrame = False;
					NewField.RightFrame = False;
				EndIf;
				NewField.Description = New UUID();
				
			EndDo;
		EndIf;
		
		ThisIsTemplateConversion = True;
		XMLTextOfNewTemplate = PeripheralsLabelPrintersServer.SaveXMLFile(Round(TemplateWidth/NumberOfPixelsPerUnitWidth), 
		Round(TemplateHeight/NumberOfPixelsPerUnitHeight), 0, Fields, ThisIsTemplateConversion);
		
	Except 
		XMLTextOfNewTemplate = "";
	EndTry; 
	
	Return XMLTextOfNewTemplate
	
EndFunction

#EndRegion

#EndIf

