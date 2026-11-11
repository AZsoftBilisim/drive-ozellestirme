
#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
// 
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	
EndProcedure

// Prepare the operation data.
// 
// Parameters:
//  ConnectionParameters - Structure -Connection parameters.
//  Command - String - executed command.
//  OperationParametersList - Structure - The operation parameters.
// 
// Returns:
//  See PeripheralsLabelPrintersServer.OperationDataLabelPrinters.
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	If Command = "PrintLabels" Then
		
		OperationData = OperationDataLabelPrinters();
		ArrayOfLabels_ = OperationParametersList.DataForPrint;
		LabelsTemplate = OperationParametersList.LabelDescriptionInHTML;
		
		If ArrayOfLabels_.Count() = 0 Then
			OperationData.Result = False;
			OperationData.ErrorText = NStr("vi = 'Không có dữ liệu để in.';
											|ru = 'Нет данных для печати.';
											|en = 'No data to print.'; fa = 'No data to print.';
											|it = 'Nessun dato da stampare.';
											|pl = 'Brak danych do druku.';
											|tr = 'Yazdırmak için veri mevcut değil.'");
			Return OperationData;
		EndIf;
		
		ErrorText = "";
		DescriptionOfLabelInStructure = Undefined;
		If Not GetTemplateDescription(LabelsTemplate, ErrorText, DescriptionOfLabelInStructure) Then
			OperationData.Result = False;
			OperationData.ErrorText = ErrorText;
			Return OperationData;
		EndIf;
		
		PackageSize = DefaultPacketSize();
		OperationData.PackagesForUnloading = PreparePackagesForLabelPrinter(ArrayOfLabels_, PackageSize, DescriptionOfLabelInStructure);
		
		Return OperationData;
	EndIf
	
EndFunction

// Process the operation data.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - Team.
//  ExecutionResult - Boolean - The result of the execution.
//  OperationData - Structure - Operation data.
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
EndProcedure

// Fill in the operation structure
// 
// Returns:
//  Structure - Operation Data Label Printers:
// * Result - Boolean
// * ErrorText - String
// * PackagesForUnloading - Array of XMLReader
Function OperationDataLabelPrinters() Export
	
	OperationData = New Structure();
	OperationData.Insert("Result", True);
	OperationData.Insert("ErrorText");
	OperationData.Insert("PackagesForUnloading");
	Return OperationData;
	
EndFunction 

// The function forms a structure with a description of the layout.
//
// Parameters:
//  Source - String - event source.
//  ErrorMessage - String - error message to the user
//  Result - See CreateTemplateDescription
// Returns:
// 	Boolean - the result of the operation.
//
Function GetTemplateDescription(Source, ErrorMessage, Result) Export
	
#If Not MobileAppServer Then
	
	Result = CreateTemplateDescription();
	
	XMLReader = New XMLReader();
	ReaderSettings = New XMLReaderSettings("1.0");
	XMLReader.SetString(Source, ReaderSettings);
	
	ErrorMessageTemplate = NStr("vi = 'Lỗi khi đọc tệp thuộc tính %1 của phần tử %2.';
								|ru = 'При чтении файла атрибута %1 элемента %2 произошла ошибка.';
								|en = 'An error occurred when reading a file of the %2 attribute of the %1 item.'; fa = 'An error occurred when reading a file of the %2 attribute of the %1 item.';
								|it = 'Si è verificato un errore durante la lettura del file di attributo %1 dell''elemento %2.';
								|pl = 'Podczas odczytu pliku atrybutu %1 elementu %2 zaistniał błąd.';
								|tr = 'Dosyadaki %1 ürün seçeneğinin %2 öğesi okunurken hata oluştu.'");
	ErrorMessageText = "";
	
	While ReadXMLElement(XMLReader, ErrorMessageText) Do
		
		AttributeValue = Undefined;
		If XMLReader.Name="Formatting" And XMLReader.NodeType=XMLNodeType.StartElement Then
			
			If ReadAttribute(XMLReader, "Width", AttributeValue) Then
				Result.Width = Number(AttributeValue);
			Else
				ErrorMessage = StrTemplate(ErrorMessageTemplate, "Width", "Formatting");
				Return False;
			EndIf;
			
			If ReadAttribute(XMLReader, "Height", AttributeValue) Then
				Result.Insert("Height", Number(AttributeValue));
			Else
				ErrorMessage = StrTemplate(ErrorMessageTemplate, "Height", "Formatting");
				Return False;
			EndIf;
			
			If ReadAttribute(XMLReader, "Orientation", AttributeValue) Then
				Result.Insert("Orientation", Number(AttributeValue));
			Else
				Result.Insert("Orientation", 0);
			EndIf;
			
			If ReadAttribute(XMLReader, "Scale", AttributeValue) Then
				Result.Insert("Scale", Number(AttributeValue));
			Else
				Result.Insert("Scale", 1);
			EndIf;
			
		ElsIf (XMLReader.Name="Text" Or XMLReader.Name="Barcode" Or XMLReader.Name="Image" Or XMLReader.Name="UserData") And XMLReader.NodeType=XMLNodeType.StartElement Then
			
			NewField = New Structure;
			NewField.Insert("Type", XMLReader.Name);
			
			If ReadAttribute(XMLReader, "FieldName", AttributeValue) Then
				NewField.Insert("Description", AttributeValue);
			Else
				ErrorMessage = StrTemplate(ErrorMessageTemplate, "FieldName", "UserData");
				Return False;
			EndIf;
			
			If ReadAttribute(XMLReader, "TypeFill", AttributeValue) Then
				
				If AttributeValue=Undefined Then
					ErrorMessage = StrTemplate(ErrorMessageTemplate, "TypeFill", "UserData");
					Return False;
				EndIf;
				
				NewField.Insert("PopulationType", AttributeValue);
				
				If AttributeValue="Parameter" Then
					
					If ReadAttribute(XMLReader, "ValueDefault", AttributeValue) Then
						NewField.Insert("DefaultValue", AttributeValue);
					EndIf;
					
					If ReadAttribute(XMLReader, "Value", AttributeValue) Then
						If AttributeValue=Undefined Then
							ErrorMessage = StrTemplate(ErrorMessageTemplate, "Value", "UserData");
							Return False;
						Else
							NewField.Insert("Value", AttributeValue);
						EndIf;
					Else
						ErrorMessage = StrTemplate(ErrorMessageTemplate, "Value", "UserData");
						Return False;
					EndIf;
				Else
					If ReadAttribute(XMLReader, "Value", AttributeValue) Then
						NewField.Insert("Value", AttributeValue);
					EndIf;
				EndIf;
			Else
				ErrorMessage = StrTemplate(ErrorMessageTemplate, "TypeFill", "UserData");
				Return False;
			EndIf;
			
			If NewField.Type<>"UserData" Then
				
				If ReadAttribute(XMLReader, "Left", AttributeValue) Then
					NewField.Insert("Left", Number(AttributeValue));
				Else
					ErrorMessage = StrTemplate(ErrorMessageTemplate, "Left", "Text");
					Return False;
				EndIf;
				
				If ReadAttribute(XMLReader, "Top", AttributeValue) Then
					NewField.Insert("Top", Number(AttributeValue));
				Else
					ErrorMessage = StrTemplate(ErrorMessageTemplate, "Top", "Text");
					Return False;
				EndIf;
				
				If ReadAttribute(XMLReader, "Width", AttributeValue) Then
					NewField.Insert("Right", NewField.Left + Number(AttributeValue) - 1);
				Else
					ErrorMessage = StrTemplate(ErrorMessageTemplate, "Width", "Text");
					Return False;
				EndIf;
				
				If ReadAttribute(XMLReader, "Height", AttributeValue) Then
					NewField.Insert("Bottom", NewField.Top + Number(AttributeValue) - 1);
				Else
					ErrorMessage = StrTemplate(ErrorMessageTemplate, "Height", "Text");
					Return False;
				EndIf;
				
				If ReadAttribute(XMLReader, "Orientation", AttributeValue) Then
					NewField.Insert("Orientation", Number(AttributeValue));
				EndIf;
				
				If NewField.Type="Text" Then
					
					If ReadAttribute(XMLReader, "FontName", AttributeValue) Then
						NewField.Insert("FontName", AttributeValue);
					EndIf;
					
					If ReadAttribute(XMLReader, "FontSize", AttributeValue) Then
						NewField.Insert("FontSize", Number(AttributeValue));
					Else
						ErrorMessage = StrTemplate(ErrorMessageTemplate, "FontSize", "Text");
						Return False;
					EndIf;
					
					If ReadAttribute(XMLReader, "FontStyle", AttributeValue) Then
						FontStyleValue = AttributeValue;
						NewField.Insert("Fatty", Find(FontStyleValue, "Bold")>0);
						NewField.Insert("Italic", Find(FontStyleValue, "Italic")>0);
						NewField.Insert("Underline",  Find(FontStyleValue, "Underline")>0);
						NewField.Insert("Strikeout", Find(FontStyleValue, "Strikeout")>0);
					EndIf;
					
					If ReadAttribute(XMLReader, "Align", AttributeValue) Then
						NewField.Insert("HorizontalPosition", AttributeValue);
					EndIf;
					
					If ReadAttribute(XMLReader, "VAlign", AttributeValue) Then
						NewField.Insert("VerticalPosition", AttributeValue);
					EndIf;
					
					If ReadAttribute(XMLReader, "Multiline", AttributeValue) Then
						NewField.Insert("Multiline", AttributeValue);
					EndIf;
					
					If ReadAttribute(XMLReader, "Background", AttributeValue) Then
						NewField.Insert("Background", ValueFromStringInternal(AttributeValue));
					EndIf;
					
				ElsIf NewField.Type="Barcode" Then
					
					If ReadAttribute(XMLReader, "Type", AttributeValue) Then
						NewField.Insert("BarcodeType", AttributeValue);
					Else
						ErrorMessage = StrTemplate(ErrorMessageTemplate, "Type", "Barcode");
						Return False;
					EndIf;
					
					If ReadAttribute(XMLReader, "PrintHRI", AttributeValue) Then
						NewField.Insert("BarcodeLabel", AttributeValue);
						BarcodeLabel = AttributeValue;
					Else
						BarcodeLabel = True;
					EndIf;
					
					If ReadAttribute(XMLReader, "FontSize", AttributeValue) Then
						If BarcodeLabel And AttributeValue=Undefined Then
							ErrorMessage = StrTemplate(ErrorMessageTemplate, "FontSize", "Barcode");
							TemplateExtension = NStr("vi = 'Nếu giá trị thuộc tính %1 = %2 thì bắt buộc phải chỉ định giá trị thuộc tính %3.';
													|ru = 'При значении атрибута %1 = %2 указание значения атрибута %3 обязательно.';
													|en = 'If the attribute value is %1 =%2, the attribute value %3 is required.'; fa = 'If the attribute value is %1 =%2, the attribute value %3 is required.';
													|it = 'Se il valore dell''attributo è %1 = %2, è obbligatorio indicare il valore dell''attributo %3.';
													|pl = 'Dla wartości atrybutu %1 = %2 podanie wartości atrybutu %3 jest konieczne.';
													|tr = 'Ürün seçeneği %1 = %2 ise, ürün seçeneği %3 değerinin belirtilmesi gereklidir.'");
							ErrorMessage = ErrorMessage + Chars.NBSp + StrTemplate(TemplateExtension, "PrintHRI", "True", "FontSize");
							Return False;
						EndIf;
						NewField.Insert("SignatureFontSize", Number(AttributeValue));
					EndIf;
					
					If ReadAttribute(XMLReader, "CheckSymbol", AttributeValue) Then
						NewField.Insert("CheckCharacter", AttributeValue);
					EndIf; 
					
				ElsIf NewField.Type="Image" Then
					If ReadAttribute(XMLReader, "PictureSize", AttributeValue) Then
						NewField.Insert("PictureSize", AttributeValue);
					EndIf; 
				EndIf;
				
				If NewField.Type = "Text" Or NewField.Type = "Image" Then
					
					If ReadAttribute(XMLReader, "Border", AttributeValue) Then
						BorderValue = AttributeValue;
						NewField.Insert("LeftFrame", Find(BorderValue, "Left")>0);
						NewField.Insert("TopFrame", Find(BorderValue, "Top")>0);
						NewField.Insert("RightFrame",  Find(BorderValue, "Right")>0);
						NewField.Insert("BottomFrame", Find(BorderValue, "Bottom")>0);
						If ValueIsFilled(BorderValue) Then
							If ReadAttribute(XMLReader, "BorderStyle", AttributeValue) Then
								NewField.Insert("BorderType", AttributeValue);
							EndIf;
							If ReadAttribute(XMLReader, "BorderWidth", AttributeValue) Then
								NewField.Insert("FrameWidth", Number(AttributeValue));
							EndIf;
						EndIf;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If NewField.Type="UserData" Or NewField.Type="Text" Then
				If ReadAttribute(XMLReader, "Format", AttributeValue) Then
					NewField.Insert("Format", AttributeValue);
				EndIf;
			EndIf;
			Result.Fields.Add(NewField);
			
		EndIf;
		
	EndDo;

	If ValueIsFilled(ErrorMessageText) Then
		ErrorMessage = ErrorMessageText;
		Return False;
	Else
		Return True;
	EndIf;
	
#EndIf  

EndFunction

// This function generates an XML description of the layout.
//
// Returns:
//  String
//
Function SaveXMLFile(LabelWidth_, LabelHeight, Var_Orientation, Fields, ThisIsTemplateConversion = False) Export

#If Not MobileAppServer Then
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();

	XMLWriter.WriteStartElement("Formatting");

	WriteElementAttribute(XMLWriter, "Width", LabelWidth_);
	WriteElementAttribute(XMLWriter, "Height", LabelHeight);

	If ValueIsFilled(Var_Orientation) Then
		WriteElementAttribute(XMLWriter, "Orientation", Var_Orientation);
	EndIf;

	For Each CurItem In Fields Do

		XMLWriter.WriteStartElement(CurItem.Type);
		WriteElementAttribute(XMLWriter, "FieldName", CurItem.Description);

		If CurItem.Type <> "UserData" Then
			
			WriteElementAttribute(XMLWriter, "Left", CurItem.Left);
			WriteElementAttribute(XMLWriter, "Top", CurItem.Top);
			If Not ThisIsTemplateConversion Then
				OffsetLeftTop = 1;
			Else
				OffsetLeftTop = 0;
			EndIf;
			WriteElementAttribute(XMLWriter, "Width", CurItem.Right - CurItem.Left + OffsetLeftTop);
			WriteElementAttribute(XMLWriter, "Height", CurItem.Bottom - CurItem.Top + OffsetLeftTop);

			If ValueIsFilled(CurItem.Orientation) Then
				WriteElementAttribute(XMLWriter, "Orientation", CurItem.Orientation);
			EndIf;
			
		Else
			WriteElementAttribute(XMLWriter, "Format", CurItem.Format);
		EndIf;

		If CurItem.Type = "Text" Then

			If ValueIsFilled(CurItem.FontName) Then
				WriteElementAttribute(XMLWriter, "FontName", CurItem.FontName);
			EndIf;

			WriteElementAttribute(XMLWriter, "FontSize", CurItem.FontSize);
			FontStyle_ = "";

			If CurItem.Fatty Then
				FontStyle_ = "Bold";
			EndIf;

			If CurItem.Italic Then
				FontStyle_ = ?(ValueIsFilled(FontStyle_), FontStyle_ + " ", "") + "Italic";
			EndIf;

			If CurItem.Underline Then
				FontStyle_ = ?(ValueIsFilled(FontStyle_), FontStyle_ + " ", "") + "Underline";
			EndIf;

			If CurItem.Strikeout Then
				FontStyle_ = ?(ValueIsFilled(FontStyle_), FontStyle_ + " ", "") + "Strikeout";
			EndIf;

			If ValueIsFilled(FontStyle_) Then
				WriteElementAttribute(XMLWriter, "FontStyle", FontStyle_);
			EndIf;
			
			If ThisIsTemplateConversion Then
				Background = New Color(255,255,255);
			Else
				Background = CurItem.Background;
			EndIf;
			BackgroundColorString = ValueToStringInternal(Background);
			WriteElementAttribute(XMLWriter, "Background", BackgroundColorString);
			
			WriteElementAttribute(XMLWriter, "Align", CurItem.HorizontalPosition);
			WriteElementAttribute(XMLWriter, "VAlign", CurItem.VerticalPosition);
			WriteElementAttribute(XMLWriter, "Multiline", CurItem.Multiline);
			WriteElementAttribute(XMLWriter, "Format", CurItem.Format);

		ElsIf CurItem.Type = "Barcode" Then

			If CurItem.Type = "Barcode" Then
				WriteElementAttribute(XMLWriter, "Type", CurItem.BarcodeType);
			EndIf;

			WriteElementAttribute(XMLWriter, "PrintHRI", CurItem.BarcodeLabel);

			If CurItem.BarcodeLabel Then
				WriteElementAttribute(XMLWriter, "FontSize", CurItem.SignatureFontSize);
				WriteElementAttribute(XMLWriter, "CheckSymbol", CurItem.CheckCharacter);
			EndIf;

		EndIf;

		If CurItem.Type = "Text" Or CurItem.Type = "Image" Then

			Border = "";

			If CurItem.TopFrame Then
				Border = "Top";
			EndIf;

			If CurItem.LeftFrame Then
				Border = ?(ValueIsFilled(Border), Border + " ", "") + "Left";
			EndIf;

			If CurItem.RightFrame Then
				Border = ?(ValueIsFilled(Border), Border + " ", "") + "Right";
			EndIf;

			If CurItem.BottomFrame Then
				Border = ?(ValueIsFilled(Border), Border + " ", "") + "Bottom";
			EndIf;

			If ValueIsFilled(Border) Then
				WriteElementAttribute(XMLWriter, "Border", Border);
				WriteElementAttribute(XMLWriter, "BorderWidth", CurItem.FrameWidth);
				WriteElementAttribute(XMLWriter, "BorderStyle", CurItem.BorderType);
			EndIf;

		EndIf;
		
		If CurItem.Type = "Image" Then
			
			WriteElementAttribute(XMLWriter, "PictureSize", CurItem.PictureSize);
			
		EndIf;

		WriteElementAttribute(XMLWriter, "TypeFill", CurItem.PopulationType);
		WriteElementAttribute(XMLWriter, "Value", CurItem.Value);

		If CurItem.PopulationType<>"Constant" And ValueIsFilled(CurItem.DefaultValue) Then			
			WriteElementAttribute(XMLWriter, "ValueDefault", CurItem.DefaultValue);
		EndIf;

		XMLWriter.WriteEndElement();

	EndDo;

	XMLWriter.WriteEndElement();

	Return XMLWriter.Close();

#EndIf  
	
EndFunction

#EndRegion

#Region Private   

// Creates a description of the layout.
// 
// Returns:
//  Structure -- structure with fields::
// * Fields - Array - array of fields.
// * Width - Number - width of the layout.
// * Height - Number - height of the layout.
// * Orientation - Number - the orientation of the layout.
// * Scale - Number - scale.
Function CreateTemplateDescription()
	
	Result = New Structure;
	Result.Insert("Fields", New Array);
	Result.Insert("Width", 0);
	Result.Insert("Height", 0);
	Result.Insert("Orientation", 0);
	Result.Insert("Scale", 0);
	
	Return Result;
	
EndFunction

// This function generates XML text to pass to the label printer.
//
// Returns:
//  XMLWriter
//
Function GenerateDataForLabelPrinter(ArrayOfLabels_, LabelTemplate, InterfaceRevision = 0)
	
	FieldFormats = New Structure;
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();

	XMLWriter.WriteStartElement("Data");

	If ValueIsFilled(LabelTemplate) Then
		XMLWriter.WriteStartElement("Formatting");

		If LabelTemplate.Orientation = 0 Or LabelTemplate.Orientation = 180 Then
			WriteElementAttribute(XMLWriter, "Width", LabelTemplate.Width);
			WriteElementAttribute(XMLWriter, "Height", LabelTemplate.Height);
		Else
			WriteElementAttribute(XMLWriter, "Width", LabelTemplate.Height);
			WriteElementAttribute(XMLWriter, "Height", LabelTemplate.Width);
		EndIf;

		For Each CurItem In LabelTemplate.Fields Do

			XMLWriter.WriteStartElement(CurItem.Type);
			WriteElementAttribute(XMLWriter, "FieldName", CurItem.Description);

			If CurItem.Type <> "UserData" Then
				
				If LabelTemplate.Orientation = 0 Then
					WriteElementAttribute(XMLWriter, "Left", CurItem.Left-1);
				ElsIf LabelTemplate.Orientation = 90 Then
					WriteElementAttribute(XMLWriter, "Left", CurItem.Top-1);
				ElsIf LabelTemplate.Orientation = 180 Then
					WriteElementAttribute(XMLWriter, "Left", LabelTemplate.Width - CurItem.Right);
				ElsIf LabelTemplate.Orientation = 270 Then
					WriteElementAttribute(XMLWriter, "Left", LabelTemplate.Height - CurItem.Bottom);
				EndIf;

				If LabelTemplate.Orientation = 0 Then
					WriteElementAttribute(XMLWriter, "Top", CurItem.Top-1);
				ElsIf LabelTemplate.Orientation = 90 Then
					WriteElementAttribute(XMLWriter, "Top", LabelTemplate.Width - CurItem.Right);
				ElsIf LabelTemplate.Orientation = 180 Then
					WriteElementAttribute(XMLWriter, "Top", LabelTemplate.Height - CurItem.Bottom);
				ElsIf LabelTemplate.Orientation = 270 Then
					WriteElementAttribute(XMLWriter, "Top", CurItem.Left-1);
				EndIf;

				If LabelTemplate.Orientation = 0 Or LabelTemplate.Orientation = 180 Then
					WriteElementAttribute(XMLWriter, "Width", CurItem.Right - CurItem.Left+1);
					WriteElementAttribute(XMLWriter, "Height", CurItem.Bottom - CurItem.Top+1);
				Else
					WriteElementAttribute(XMLWriter, "Width", CurItem.Bottom - CurItem.Top+1);
					WriteElementAttribute(XMLWriter, "Height", CurItem.Right - CurItem.Left+1);
				EndIf;

				If LabelTemplate.Orientation <> 0 Then
					
					If CurItem.Property("Orientation") Then
						If ValueIsFilled(CurItem.Orientation) Then
							FieldOrientation = Number(CurItem.Orientation);
						Else
							FieldOrientation = 0;
						EndIf;
					Else
						FieldOrientation = 0;
					EndIf;
					
					NewOrientationValue = FieldOrientation + Number(LabelTemplate.Orientation);
					NewOrientationValue = Format(?(NewOrientationValue>270, NewOrientationValue-360, NewOrientationValue), "NG=0");
					WriteElementAttribute(XMLWriter, "Orientation", NewOrientationValue);
					
				Else

					If CurItem.Property("Orientation") Then
						WriteElementAttribute(XMLWriter, "Orientation", CurItem.Orientation);
					EndIf;

				EndIf;
				
			EndIf;
			
			If CurItem.PopulationType = "Parameter" Then
				
				If CurItem.Property("DefaultValue") Then
					If CurItem.Type = "Text"
						And CurItem.Property("Format") And ValueIsFilled(CurItem.Format) Then
						WriteElementAttribute(XMLWriter, "Value", CurItem.DefaultValue, CurItem.Format);
					ElsIf CurItem.Type = "Barcode" And InterfaceRevision > 3002 Then
						BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(CurItem.DefaultValue);
						WriteElementAttribute(XMLWriter, "ValueBase64", BarcodeBASE64);
					Else
						WriteElementAttribute(XMLWriter, "Value", CurItem.DefaultValue);
					EndIf;
				EndIf;
				
			Else
				
				WriteElementAttribute(XMLWriter, "Static", True);
				If CurItem.Type = "Text" And CurItem.Property("Format") And ValueIsFilled(CurItem.Format) Then
					WriteElementAttribute(XMLWriter, "Value", CurItem.Value, CurItem.Format);
				ElsIf CurItem.Type = "Barcode" And InterfaceRevision > 3002 Then
					BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(CurItem.Value);
					WriteElementAttribute(XMLWriter, "ValueBase64", BarcodeBASE64);
				Else
					WriteElementAttribute(XMLWriter, "Value", CurItem.Value);
				EndIf;
				
			EndIf;
			
			If CurItem.Type = "Text" Then
				
				If CurItem.Property("Format") And ValueIsFilled(CurItem.Format) Then
					FieldFormats.Insert("Format" + StrReplace(CurItem.Description, "-", ""), CurItem.Format);
				EndIf;
				
				If CurItem.Property("FontName") Then
					WriteElementAttribute(XMLWriter, "FontName", CurItem.FontName);
				EndIf;
				
				WriteElementAttribute(XMLWriter, "FontSize", CurItem.FontSize);
				
				FontStyle_ = "";
				If CurItem.Property("Fatty") Then
					If CurItem.Fatty Then
						FontStyle_ = "Bold";
					EndIf;
				EndIf;
				
				If CurItem.Property("Italic") Then
					If CurItem.Italic Then
						FontStyle_ = ?(FontStyle_ <> "", FontStyle_ + " ", "") + "Italic";
					EndIf;
				EndIf;
				
				If CurItem.Property("Underline") Then
					If CurItem.Underline Then
						FontStyle_ = ?(FontStyle_ <> "", FontStyle_ + " ", "") + "Underline";
					EndIf;
				EndIf;
				
				If CurItem.Property("Strikeout") Then
					If CurItem.Strikeout Then
						FontStyle_ = ?(FontStyle_ <> "", FontStyle_ + " ", "") + "StrikeOut";
					EndIf;
				EndIf;
				
				WriteElementAttribute(XMLWriter, "FontStyle", FontStyle_);

				HorizontalAlignment = "Left";

				If CurItem.Property("HorizontalPosition") Then
					If ValueIsFilled(CurItem.HorizontalPosition) Then
						HorizontalAlignment = CurItem.HorizontalPosition;
					EndIf;
				EndIf;

				VerticalAlignment_ = "Top";

				If CurItem.Property("VerticalPosition") Then
					If ValueIsFilled(CurItem.VerticalPosition) Then
						VerticalAlignment_ = CurItem.VerticalPosition;
					EndIf;
				EndIf;

				If LabelTemplate.Orientation = 0 Then
					WriteElementAttribute(XMLWriter, "Align", HorizontalAlignment);
					WriteElementAttribute(XMLWriter, "VAlign", VerticalAlignment_);
				ElsIf LabelTemplate.Orientation = 90 Then

					If VerticalAlignment_="Top" Then
						WriteElementAttribute(XMLWriter, "Align", "Left");
					ElsIf VerticalAlignment_="Center" Then
						WriteElementAttribute(XMLWriter, "Align", "Center");
					ElsIf VerticalAlignment_="Bottom" Then
						WriteElementAttribute(XMLWriter, "Align", "Right");
					EndIf;

					If HorizontalAlignment="Left" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Bottom");
					ElsIf HorizontalAlignment="Center" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Center");
					ElsIf HorizontalAlignment="Right" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Top");
					EndIf;

				ElsIf LabelTemplate.Orientation = 180 Then

					If HorizontalAlignment="Left" Then
						WriteElementAttribute(XMLWriter, "Align", "Right");
					ElsIf HorizontalAlignment="Center" Then
						WriteElementAttribute(XMLWriter, "Align", "Center");
					ElsIf HorizontalAlignment="Right" Then
						WriteElementAttribute(XMLWriter, "Align", "Left");
					EndIf;

					If VerticalAlignment_="Top" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Bottom");
					ElsIf VerticalAlignment_="Center" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Center");
					ElsIf VerticalAlignment_="Bottom" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Top");
					EndIf;

				ElsIf LabelTemplate.Orientation = 270 Then

					If VerticalAlignment_="Top" Then
						WriteElementAttribute(XMLWriter, "Align", "Right");
					ElsIf VerticalAlignment_="Center" Then
						WriteElementAttribute(XMLWriter, "Align", "Center");
					ElsIf VerticalAlignment_="Bottom" Then
						WriteElementAttribute(XMLWriter, "Align", "Left");
					EndIf;

					If HorizontalAlignment="Left" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Top");
					ElsIf HorizontalAlignment="Center" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Center");
					ElsIf HorizontalAlignment="Right" Then
						WriteElementAttribute(XMLWriter, "VAlign", "Bottom");
					EndIf;

				EndIf;

				If CurItem.Property("Multiline") Then
					WriteElementAttribute(XMLWriter, "Multiline", CurItem.Multiline);
				EndIf;

			ElsIf CurItem.Type = "Barcode" Then

				WriteElementAttribute(XMLWriter, "Type", CurItem.BarcodeType);

				If CurItem.Property("BarcodeLabel") Then
					WriteElementAttribute(XMLWriter, "PrintHRI", CurItem.BarcodeLabel);

					If CurItem.BarcodeLabel Then
						WriteElementAttribute(XMLWriter, "FontSize", CurItem.SignatureFontSize);
					EndIf;

				EndIf;

				If CurItem.Property("CheckCharacter") Then
					WriteElementAttribute(XMLWriter, "CheckSymbol", CurItem.CheckCharacter);
				EndIf;	

			EndIf;

			If CurItem.Type = "Text" Or CurItem.Type = "Image" Then

				Border = "";
				
				If CurItem.Property("LeftFrame") Then
					If CurItem.LeftFrame Then
						Border = "Left";
					EndIf;
				EndIf;
				
				If CurItem.Property("TopFrame") Then
					If CurItem.TopFrame Then
						Border = ?(Border <> "", Border + " ", "") + "Top";
					EndIf;
				EndIf;
				
				If CurItem.Property("RightFrame") Then
					If CurItem.RightFrame Then
						Border = ?(Border <> "", Border + " ", "") + "Right";
					EndIf;
				EndIf;
				
				If CurItem.Property("BottomFrame") Then
					If CurItem.BottomFrame Then
						Border = ?(Border <> "", Border + " ", "") + "Bottom";
					EndIf;
				EndIf;
				
				If ValueIsFilled(Border) Then
					
					If LabelTemplate.Orientation = 0 Then
						WriteElementAttribute(XMLWriter, "Border", Border);
					ElsIf LabelTemplate.Orientation = 90 Then
						Border=StrReplace(Border, "Left", "B1ottom");
						Border=StrReplace(Border, "Top", "L1eft");
						Border=StrReplace(Border, "Right", "T1op");
						Border=StrReplace(Border, "Bottom", "R1ight");
						Border=StrReplace(Border, "1", "");
						WriteElementAttribute(XMLWriter, "Border", Border);
					ElsIf LabelTemplate.Orientation = 180 Then
						Border=StrReplace(Border, "Left", "R1ight");
						Border=StrReplace(Border, "Top", "B1ottom");
						Border=StrReplace(Border, "Right", "L1eft");
						Border=StrReplace(Border, "Bottom", "T1op");
						Border=StrReplace(Border, "1", "");
						WriteElementAttribute(XMLWriter, "Border", Border);
					ElsIf LabelTemplate.Orientation = 270 Then
						Border=StrReplace(Border, "Left", "T1op");
						Border=StrReplace(Border, "Top", "R1ight");
						Border=StrReplace(Border, "Right", "B1ottom");
						Border=StrReplace(Border, "Bottom", "L1eft");
						Border=StrReplace(Border, "1", "");
						WriteElementAttribute(XMLWriter, "Border", Border);
					EndIf;
					
					If CurItem.Property("BorderType") Then
						WriteElementAttribute(XMLWriter, "BorderStyle", CurItem.BorderType);
					EndIf;
					
					If CurItem.Property("FrameWidth") Then
						WriteElementAttribute(XMLWriter, "BorderWidth", CurItem.FrameWidth);
					EndIf;
					
				EndIf;

			EndIf;

			XMLWriter.WriteEndElement();		

		EndDo;

		XMLWriter.WriteEndElement();

	EndIf;
	
	XMLWriter.WriteStartElement("Labels");
	
	For Each CurLabel In ArrayOfLabels_ Do
		
		XMLWriter.WriteStartElement("Label");
		
		If CurLabel.Property("Count") Then
			WriteElementAttribute(XMLWriter, "Quantity", CurLabel.Count);
		EndIf;
		
		For Each CurField In CurLabel.Fields Do
			
			ElementValue = Undefined;
			For Each CurItem In LabelTemplate.Fields Do
				If CurItem.Description = CurField.FieldName Then
					ElementValue = CurItem;
					Break;
				EndIf
			EndDo;
			
			XMLWriter.WriteStartElement("Record");
			WriteElementAttribute(XMLWriter, "FieldName", CurField.FieldName);
			If FieldFormats.Property("Format" + StrReplace(CurField.FieldName, "-", "")) Then
				WriteElementAttribute(XMLWriter, "Value", CurField.Value, FieldFormats["Format" + StrReplace(CurField.FieldName, "-", "")]);
			Else
				If InterfaceRevision > 3002 And ElementValue <> Undefined And ElementValue.Type = "Barcode" Then
					BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(CurField.Value);
					WriteElementAttribute(XMLWriter, "ValueBase64", BarcodeBASE64);
				Else
					WriteElementAttribute(XMLWriter, "Value", CurField.Value);
				EndIf;
			EndIf;
			XMLWriter.WriteEndElement();
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLWriter.WriteEndElement();
	
	Result = XMLWriter.Close(); 
	
	Return Result;
	
EndFunction

// Generate XML product packages for uploading the TSD.
//
// Returns:
//  Array
Function PreparePackagesForLabelPrinter(ArrayOfLabels_, PackageSize, LabelTemplate = Undefined)
	
	PackagesForUnloading = New Array();  
	ArrayOfProducts_2 = New Array;
	
	FirstPackage      = True;
	WritingInPackage    = 0;
	RecordsUnloaded = 0;
	TotalRecords_     = ArrayOfLabels_.Count();
	
	For Each Position In ArrayOfLabels_ Do
		
		If WritingInPackage = 0 Then
		    ArrayOfProducts_2.Clear();
		EndIf;
		
		ArrayOfProducts_2.Add(Position);
		
		RecordsUnloaded  = RecordsUnloaded + 1;
		WritingInPackage = WritingInPackage + 1;
		
		If (WritingInPackage = PackageSize) Or (RecordsUnloaded = TotalRecords_) Then  
			DataToUpload = GenerateDataForLabelPrinter(ArrayOfProducts_2, ?(FirstPackage, LabelTemplate, Undefined));
			PackagesForUnloading.Add(DataToUpload);
			WritingInPackage = 0;
			FirstPackage   = False;
		EndIf;
		
	EndDo;
	
	Return PackagesForUnloading;
	
EndFunction

// The size of the packet in the elements of information transmitted to the driver.
//
// Returns:
// Number
Function DefaultPacketSize() 
	
	PackageSize = 200;
	Return PackageSize;
	
EndFunction

// The function gets the attribute value of the current element.
//
Function ReadAttribute(XMLReader, AttributeName, AttributeValue)
	
	Value = XMLReader.AttributeValue(AttributeName);
	
	If Value = Undefined Then
		AttributeValue = Undefined;
		Return False;
	Else
		AttributeValue = XMLValue(Type("String"), Value);
		Return True;
	EndIf;
	
EndFunction

Function ReadXMLElement(XMLReader, ErrorMessageText)
	
	Try
		Result = XMLReader.Read();
	Except
		ErrorMessageText = NStr("vi = 'Khi đọc mô tả XML của khuôn in, đã xảy ra lỗi.';
								|ru = 'При чтении XML-описания макета произошла ошибка.';
								|en = 'An error occurred when reading XML description of the template.'; fa = 'An error occurred when reading XML description of the template.';
								|it = 'Si è verificato un errore durante la lettura della descrizione XML del layout.';
								|pl = 'Podczas odczytu XML-opisu makiety zaistniał błąd.';
								|tr = 'XML şablonunun ayrıntıları okunurken hata oluştu.'");
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// The procedure records the attribute value of the current element.
//
Procedure WriteElementAttribute(XMLWriter, AttributeName, AttributeValue, FormatString="NDS=.; NZ=0; NG=0; BF=false; BT=true")
	
	If ValueIsFilled(AttributeValue) Or TypeOf(AttributeValue)=Type("Number") Or AttributeName="Value" Then
		XMLWriter.WriteAttribute(AttributeName, XMLString(Format(AttributeValue, FormatString)));
	EndIf;
	
EndProcedure

#EndRegion