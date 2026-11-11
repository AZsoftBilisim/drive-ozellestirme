#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		SourceObject = Parameters.CopyingValue.GetObject();
	Else
		SourceObject = FormAttributeToValue("Object", Type("CatalogObject.TemplatesOfPLLabelsAndPriceTags"));
	EndIf;
	
	DataCompositionSchema = SourceObject.DataCompositionSchema.Get();
	
	If DataCompositionSchema = Undefined Then
		DataCompositionSchema = PrintPLLabelsAndPriceTagsOverridable.DataLayoutTemplate();
	EndIf;
	
	DCSStorageAddress = PutToTempStorage(DataCompositionSchema, UUID);
	
	Template = SourceObject.Template.Get();
	AddressOfTemplate = PutToTempStorage(SourceObject.Template.Get(), UUID);
	
	Etalon = GetReferenceTemplate(); 
	
	PrintPLLabelsAndPriceTagsOverridable.FormTemplatesOfLabelsAndPriceTagsOfBPOWhenCreatingOnServer(ThisForm);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
		
	#If WebClient Then
		
		OneMillimeterWide = 0.535;
		OneMillimeterOfHeight = 2.711;
		
	#Else
	
		TemplateReference = Etalon;
		
		Drawing = TemplateReference.Drawings[0];
		LineHeightInMillimeters = Drawing.Top;
		ColumnWidthInMillimeters = Drawing.Left;
		RowHeight	= Etalon.Area("R1").RowHeight;
		ColumnWidth_1	= Etalon.Area("C1").ColumnWidth;
		
		OneMillimeterWide = ColumnWidth_1 / ColumnWidthInMillimeters;
		OneMillimeterOfHeight = RowHeight / LineHeightInMillimeters;
	
	#EndIf
	
	Template.Area().AutoRowHeight = False;	
	Template.Area().RowHeight = OneMillimeterOfHeight;
	Template.Area().ColumnWidth = OneMillimeterWide;
	Template.Area().BackColor = New Color(128,128,128);
	Template.Area(2, 2, LabelHeight+1, LabelWidth_+1).BackColor = New Color(255,255,255);
	
	GridStep = 1;
	
	XMLTemplateDetails = Object.XMLTemplateDetails;
	ReFillTemplate(XMLTemplateDetails); 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(DCSStorageAddress) Then
		DCS = GetFromTempStorage(DCSStorageAddress);
		CurrentObject.DataCompositionSchema = New ValueStorage(DCS);
	EndIf;
	
	If ValueIsFilled(AddressOfTemplate) Then
		TemplateTemplate = GetFromTempStorage(AddressOfTemplate);
		If TemplateTemplate <> Undefined Then
			Template.Clear();
			Template = TemplateTemplate;
			CurrentObject.Template = New ValueStorage(Template);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToEditTemplate(Command)
	
	NotificationOnCompletion = New CallbackDescription("EditTemplateCompletion", ThisObject);
	PeripheralsLabelPrintersServerClient.StartEditingTemplate(NotificationOnCompletion, Object.XMLTemplateDetails, DCSStorageAddress, AddressOfTemplate);
	
EndProcedure

&AtClient
Procedure DownloadDCS(Command)
	
	SelectingDCSFile();
	
EndProcedure

&AtClient
Procedure LoadDefaultDCS(Command)
	LoadDefaultDCSOnServer();
EndProcedure

&AtClient
Procedure TypeOfPriceTagOnChange(Item)
	LoadDefaultDCSOnServer(Object.TypeOfPriceTag);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure LoadDefaultDCSOnServer(TypeOfPriceTag = "")
	
	DataCompositionSchema = PrintPLLabelsAndPriceTagsOverridable.DataLayoutTemplate(TypeOfPriceTag);
	DCSStorageAddress = PutToTempStorage(DataCompositionSchema, UUID);
	
EndProcedure

&AtClient
Procedure EditTemplateCompletion(Value, Var_Parameters) Export
	
	If Value = DialogReturnCode.OK Then
		ReFillTemplate(Var_Parameters.XMLTemplateDetails);
		Object.Fields.Clear();
		For Each DataField In Var_Parameters.Fields Do
			FillPropertyValues(Object.Fields.Add(), DataField);
		EndDo;
		
		Object.XMLTemplateDetails = Var_Parameters.XMLTemplateDetails;
		AddressOfTemplate = Var_Parameters.Template;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetDescriptionOfTemplateOnServer(Val Source, ErrorMessage, ContentsOfXMLFile)
	
	Return PeripheralsLabelPrintersServer.GetTemplateDescription(Source, ErrorMessage, ContentsOfXMLFile);
	
EndFunction

&AtClient
Procedure ReFillTemplate(XMLTemplateDetails)
	
	ErrorMessage = Undefined;
	ContentsOfXMLFile = New Structure();
	
	If Not ValueIsFilled(XMLTemplateDetails) Then
		ErrorMessage = NStr("vi = 'Cần tùy chỉnh khuôn mẫu nhãn tem.';
							|ru = 'Необходимо настроить шаблон этикетки.';
							|en = 'Set up the label template.'; fa = 'Set up the label template.';
							|it = 'È necessario impostare il modello di etichetta.';
							|pl = 'Należy ustawić szablon etykiety.';
							|tr = 'Etiket numunesi ayarlarının yapılması gerekiyor.'");
	ElsIf GetDescriptionOfTemplateOnServer(XMLTemplateDetails, ErrorMessage, ContentsOfXMLFile) Then
		
		GridStep = ContentsOfXMLFile.Scale;
		Fields.Clear();
		ClearArea(1, 1, LabelHeight/GridStep, LabelWidth_/GridStep);
		LabelWidth_ = ContentsOfXMLFile.Width;
		LabelHeight = ContentsOfXMLFile.Height;
		
		For Each CurField In ContentsOfXMLFile.Fields Do
			
			NewField = Fields.Add();
			FillPropertyValues(NewField, CurField);
			
			If CurField.Type="Text" Or CurField.Type="UserData" Then
				NewField.Presentation = CurField.Value;
			ElsIf CurField.Type="Barcode" Then
				NewField.Presentation = StrTemplate(NStr("vi = 'Mã vạch %1';
														|ru = 'Штрихкод %1';
														|en = 'Barcode %1'; fa = 'Barcode %1';
														|it = 'Codice a barre %1';
														|pl = 'Kod kreskowy: %1';
														|tr = 'Barkod %1'"), String(CurField.BarcodeType));
			ElsIf CurField.Type="Image" Then
				NewField.Presentation = NStr("vi = 'Hình ảnh';
											|ru = 'Картинка';
											|en = 'Picture'; fa = 'تصویر';
											|it = 'Immagine';
											|pl = 'Obraz';
											|tr = 'Resim'");
			EndIf;
			
			If CurField.Type<>"UserData" Then
				SaveFieldDesign(NewField, True, Template);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetReferenceTemplate()
	
	Return Catalogs.Peripherals.GetTemplate("LayoutForDeterminingTheCoefficientsOfUnitsOfMeasurement");
	
EndFunction

&AtClient
Procedure SaveFieldDesign(FieldDetails, OpeningTemplate=False, SpreadsheetDocument=Undefined)
	
	#If WebClient Then
		
		If TypeOf(FieldDetails)<>Type("Structure") Then
			FieldDetails = GetFieldDescription(FieldDetails);
		EndIf;
		
		SaveFieldDesignOnServer(FieldDetails, OpeningTemplate, SpreadsheetDocument);
		
	#Else
	
		If SpreadsheetDocument=Undefined Then
			SpreadsheetDocument = Template;
		EndIf;
		
		Area = Template.Area((FieldDetails.Top-1)/GridStep+1, (FieldDetails.Left-1)/GridStep+1, FieldDetails.Bottom/GridStep, FieldDetails.Right/GridStep);
		Area.Merge();
		Area.Name = FieldDetails.Description;
		
		If FieldDetails.Type = "Text" Then
			
			If FieldDetails.PopulationType = "Constant" Then
				Area.FillType=SpreadsheetDocumentAreaFillType.Text;
				Area.Text = FieldDetails.Value;
			Else
				Area.FillType=SpreadsheetDocumentAreaFillType.Parameter;
				Area.Parameter = FieldDetails.Value;
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
			
			If GridStep=1 Then
				Multiplier = 1;
			ElsIf GridStep=0.5 Then
				Multiplier = 2;
			ElsIf GridStep = 0.2 Then
				Multiplier = 5;
			Else
				Multiplier = 10;
			EndIf;
			
			If OpeningTemplate Then
				Area.Font = New Font(FieldDetails.FontName,FieldDetails.FontSize * Multiplier, FieldDetails.Fatty, FieldDetails.Italic, FieldDetails.Underline, FieldDetails.Strikeout);
			Else
				Area.Font = New Font(FieldDetails.Font.Name, FieldDetails.Font.Size * Multiplier, FieldDetails.Font.Fatty, FieldDetails.Font.Italic, FieldDetails.Font.Underline, FieldDetails.Font.Strikeout);
			EndIf; 
			
			If FieldDetails.Background = New Color(0,0,0) Then
				Area.BackColor = New Color(255,255,255);
			Else
				Area.BackColor = FieldDetails.Background;
			EndIf;
			
			
		ElsIf FieldDetails.Type = "Barcode" Then		
			
			Area.Text = StrTemplate(NStr("vi = 'Mã vạch %1';
										|ru = 'Штрихкод %1';
										|en = 'Barcode %1'; fa = 'Barcode %1';
										|it = 'Codice a barre %1';
										|pl = 'Kod kreskowy: %1';
										|tr = 'Barkod %1'"), String(FieldDetails.BarcodeType));
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
			
			If GridStep=1 Then
				FontSize = 8;
			ElsIf GridStep=0.5 Then
				FontSize = 16;
			ElsIf GridStep = 0.2 Then
				FontSize = 24;
			Else
				FontSize = 36;
			EndIf;
			
			Area.Font = New Font(, FontSize);
			Area.TextOrientation = FieldDetails.Orientation;
			Area.HorizontalAlign=HorizontalAlign.Center;
			Area.VerticalAlign=VerticalAlign.Center;		
			
		ElsIf FieldDetails.Type = "Image" Then
			Area.Text = NStr("vi = 'Hình ảnh';
							|ru = 'Изображение';
							|en = 'Image'; fa = 'تصویر';
							|it = 'Immagine';
							|pl = 'Image';
							|tr = 'Görsel'");
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
			
			If GridStep=1 Then
				FontSize = 8;
			ElsIf GridStep=0.5 Then
				FontSize = 16;
			ElsIf GridStep = 0.2 Then
				FontSize = 24;
			Else
				FontSize = 36;
			EndIf;
			
			Area.Font = New Font(, FontSize);
			Area.TextOrientation = FieldDetails.Orientation;
			Area.HorizontalAlign=HorizontalAlign.Center;
			Area.VerticalAlign=VerticalAlign.Center;
		EndIf;
		
		If FieldDetails.Type = "Text" Or FieldDetails.Type = "Image" Then
			
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
			
		EndIf;
		
		If FieldDetails.Type = "Barcode" Or FieldDetails.Type = "Image" Then
			Area.BackColor = New Color(235, 235, 235);
		Else
			
			If Not FieldDetails.LeftFrame And Not FieldDetails.TopFrame And Not FieldDetails.RightFrame And Not FieldDetails.BottomFrame Then
				Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
				Area.LeftBorder = Border;
				Area.TopBorder = Border;
				Area.RightBorder = Border;
				Area.BottomBorder = Border;
				Area.BorderColor = New Color(235, 235, 235);
			Else
				Area.BorderColor = New Color(0, 0, 0);
			EndIf;
			
		EndIf;
	
	#EndIf
	
EndProcedure

&AtClient
Procedure ClearArea(Top, Left, Bottom, Right)
	
	#If WebClient Then
		
		ClearAreaOnServer(Top, Left, Bottom, Right);
		
	#Else
	
		Area = Template.Area(Top, Left, Bottom, Right);
		Area.Name = "";
		Area.Picture = Undefined;
		Area.UndoMerge();
		Area.Clear(True, True, True);	
		Area.BackColor = New Color(255,255,255);
	
	#EndIf
	
EndProcedure

&AtClient
Procedure SelectingDCSFile()
	
	// APK: 1348-off the filesystem Client module from BSP is not used
	DOF = New FileDialog(FileDialogMode.Open);
	DOF.FullFileName = FileName;
	DOF.Filter = NStr("vi = 'Tệp XML';
						|ru = 'XML-файл';
						|en = 'XML file'; fa = 'XML file';
						|it = 'File XML';
						|pl = 'XML file';
						|tr = 'XML dosyası'") + "(*.xml)|*.xml"; 
	DOF.Multiselect = False;
	DOF.Title = NStr("vi = 'Hãy chọn tệp khuôn in sơ đồ dàn dựng dữ liệu';
					|ru = 'Выберите файл макета СКД';
					|en = 'Select the DCS template file'; fa = 'Select the DCS template file';
					|it = 'Selezionare file di modello SKD';
					|pl = 'Wybierz plik szablonu systemu rozmieszczenia danych';
					|tr = 'Veri Oluşturma Sistemi şablonu dosyası seçin'");
	DOF.Show(New CallbackDescription("SelectingFileCompletion", ThisObject, New Structure("DOF", DOF)));
	// APK: 1348-on
	
EndProcedure

&AtClient
Procedure SelectingFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	DOF = AdditionalParameters.DOF;
	
	If (SelectedFiles <> Undefined) Then
		FileName = DOF.FullFileName;
		FillAccordingToTemplateData(True);
	Else
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAccordingToTemplateData(ReadingFromFile = False)
	
	MessageText = "";
	
	If ReadingFromFile Then
		Try
			
			XMLReader = New XMLReader;
			XMLReader.OpenFile(FileName);
			
			DCSchema = XDTOSerializer.ReadXML(XMLReader, Type("DataCompositionSchema"));
			
			XMLReader.Close();
			XMLReader = Undefined;
			
			If DCSchema.DefaultSettings.AdditionalProperties.Property("DataCompositionSchema") Then
				DCSchema.DefaultSettings.AdditionalProperties.DataCompositionSchema = Undefined;
			EndIf;
			Object.DataCompositionSchema = New ValueStorage(DCSchema);
			DCSStorageAddress = PutToTempStorage(DCSchema, UUID);
			
		Except
			MessageText = StrReplace(MessageText, "%ErrorDescription%", FileName);
			CommonCEL.MessageToUser(MessageText);
			Return;
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetFieldDescription(FieldDetails)
	
	Result = New Structure;
	
	Result.Insert("Description",			FieldDetails.Description);
	Result.Insert("Type",					FieldDetails.Type);
	Result.Insert("PopulationType",			FieldDetails.PopulationType);
	Result.Insert("DefaultValue",	FieldDetails.DefaultValue);
	Result.Insert("Value",				FieldDetails.Value);
	Result.Insert("Top",					FieldDetails.Top);
	Result.Insert("Left",					FieldDetails.Left);
	Result.Insert("Bottom",					FieldDetails.Bottom);
	Result.Insert("Right",					FieldDetails.Right);
	Result.Insert("Orientation",			FieldDetails.Orientation);
	Result.Insert("FontName",				FieldDetails.FontName);
	Result.Insert("FontSize",			FieldDetails.FontSize);
	Result.Insert("Fatty",				FieldDetails.Fatty);
	Result.Insert("Italic",				FieldDetails.Italic);
	Result.Insert("Underline",			FieldDetails.Underline);
	Result.Insert("Strikeout",			FieldDetails.Strikeout);
	Result.Insert("LeftFrame",			FieldDetails.LeftFrame);
	Result.Insert("TopFrame",			FieldDetails.TopFrame);
	Result.Insert("RightFrame",			FieldDetails.RightFrame);
	Result.Insert("BottomFrame",			FieldDetails.BottomFrame);
	Result.Insert("BorderType",				FieldDetails.BorderType);
	Result.Insert("FrameWidth",			FieldDetails.FrameWidth);
	Result.Insert("BarcodeType",			FieldDetails.BarcodeType);
	Result.Insert("SignatureFontSize",	FieldDetails.SignatureFontSize);
	Result.Insert("BarcodeLabel",		FieldDetails.BarcodeLabel);
	Result.Insert("CheckCharacter",		FieldDetails.CheckCharacter);
	Result.Insert("HorizontalPosition",FieldDetails.HorizontalPosition);
	Result.Insert("VerticalPosition",	FieldDetails.VerticalPosition);
	Result.Insert("Multiline",		FieldDetails.Multiline);
	Result.Insert("Format",				FieldDetails.Format);
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveFieldDesignOnServer(FieldDetails, OpeningTemplate=False, SpreadsheetDocument=Undefined)
	
	If SpreadsheetDocument=Undefined Then
		SpreadsheetDocument = Template;
	EndIf;
	
	Area = SpreadsheetDocument.Area((FieldDetails.Top-1)/GridStep+1, (FieldDetails.Left-1)/GridStep+1, FieldDetails.Bottom/GridStep, FieldDetails.Right/GridStep);
	Area.Merge();
	Area.Name = FieldDetails.Description;
	
	If FieldDetails.Type = "Text" Then
		
		If FieldDetails.PopulationType = "Constant" Then
			Area.FillType=SpreadsheetDocumentAreaFillType.Text;
			Area.Text = FieldDetails.Value;
		Else
			Area.FillType=SpreadsheetDocumentAreaFillType.Parameter;
			Area.Parameter = FieldDetails.Value;
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
		
		If GridStep=1 Then
			Multiplier = 1;
		ElsIf GridStep=0.5 Then
			Multiplier = 2;
		ElsIf GridStep = 0.2 Then
			Multiplier = 5;
		Else
			Multiplier = 10;
		EndIf;
		
		If OpeningTemplate Then
			Area.Font = New Font(FieldDetails.FontName,FieldDetails.FontSize * Multiplier, FieldDetails.Fatty, FieldDetails.Italic, FieldDetails.Underline, FieldDetails.Strikeout);
		Else
			Area.Font = New Font(FieldDetails.Font.Name, FieldDetails.Font.Size * Multiplier, FieldDetails.Font.Fatty, FieldDetails.Font.Italic, FieldDetails.Font.Underline, FieldDetails.Font.Strikeout);
		EndIf;
		
	ElsIf FieldDetails.Type = "Barcode" Then		
		
		Area.Text = StrTemplate(NStr("vi = 'Mã vạch %1';
									|ru = 'Штрихкод %1';
									|en = 'Barcode %1'; fa = 'Barcode %1';
									|it = 'Codice a barre %1';
									|pl = 'Kod kreskowy: %1';
									|tr = 'Barkod %1'"), String(FieldDetails.BarcodeType));
		Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
		
		If GridStep=1 Then
			FontSize = 8;
		ElsIf GridStep=0.5 Then
			FontSize = 16;
		ElsIf GridStep = 0.2 Then
			FontSize = 24;
		Else
			FontSize = 36;
		EndIf;
		
		Area.Font = New Font(, FontSize);
		Area.TextOrientation = FieldDetails.Orientation;
		Area.HorizontalAlign=HorizontalAlign.Center;
		Area.VerticalAlign=VerticalAlign.Center;		
		
	ElsIf FieldDetails.Type = "Image" Then
		Area.Text = NStr("vi = 'Hình ảnh';
						|ru = 'Изображение';
						|en = 'Image'; fa = 'تصویر';
						|it = 'Immagine';
						|pl = 'Image';
						|tr = 'Görsel'");
		Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
		
		If GridStep=1 Then
			FontSize = 8;
		ElsIf GridStep=0.5 Then
			FontSize = 16;
		ElsIf GridStep = 0.2 Then
			FontSize = 24;
		Else
			FontSize = 36;
		EndIf;
		
		Area.Font = New Font(, FontSize);
		Area.TextOrientation = FieldDetails.Orientation;
		Area.HorizontalAlign=HorizontalAlign.Center;
		Area.VerticalAlign=VerticalAlign.Center;
	EndIf;
	
	If FieldDetails.Type = "Text" Or FieldDetails.Type = "Image" Then
		
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
		
	EndIf;
	
	If FieldDetails.Type = "Barcode" Or FieldDetails.Type = "Image" Then
		Area.BackColor = New Color(235, 235, 235);
	Else
		
		If Not FieldDetails.LeftFrame And Not FieldDetails.TopFrame And Not FieldDetails.RightFrame And Not FieldDetails.BottomFrame Then
			Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
			Area.LeftBorder = Border;
			Area.TopBorder = Border;
			Area.RightBorder = Border;
			Area.BottomBorder = Border;
			Area.BorderColor = New Color(235, 235, 235);
		Else
			Area.BorderColor = New Color(0, 0, 0);
		EndIf;
		
	EndIf;
		
EndProcedure

&AtServer
Procedure ClearAreaOnServer(Top, Left, Bottom, Right)
	
	Area = Template.Area(Top, Left, Bottom, Right);
	Area.Name = "";
	Area.Picture = Undefined;
	Area.UndoMerge();
	Area.Clear(True, True, True);	
	Area.BackColor = New Color(255,255,255);
	
EndProcedure

#EndRegion