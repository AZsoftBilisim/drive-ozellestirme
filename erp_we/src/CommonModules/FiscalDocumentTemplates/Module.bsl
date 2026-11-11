#Region Public

#Region OutputFormats

// Returns the format for the template string.
// 
// Parameters:
//  BasicFormat - See NewFormat.
// 
// Returns:
//   Structure:
//     * Type - String - template string type: String, Separator, Barcode, XML.
//     * Align - HorizontalAlign
//     * TitleAlignment - Boolean - True - align the title with the text, otherwise False.
//     * WrappingAroundLeft - Boolean - The truth is to flow around the left.
//     * WrappingAroundRight - Boolean - The truth is to flow around the right.
//     * Width - String - column width in characters or percentages: 
//                "10" - 10 characters;
//                "40%" - 40% of the row;
//                "*" - automatically try to put it completely in the column;
//                "0", "" - distribute equally the remaining space in the line.
//     * Placeholder - String - the placeholder character of the line between the header and the field, by default " ".
//     * TitleOutput - Boolean - forcibly output the header even if the value is not set.
//     * SuppressSpaces - Boolean - delete spaces in a string.
//     * BarcodeType - String - barcode type: "EAN13", "QR".
//     * BarcodeHeight - Number - the height of the barcode in lines.
//     * XMLElement - Structure
//     * NameOfXMLAttribute - String
//
Function NewFormat(BasicFormat = Undefined) Export
	
	Align = HorizontalAlign.Left; // HorizontalAlign   
	Format = New Structure();
	Format.Insert("Type",                   "STRING");
	Format.Insert("Align",          Align);
	Format.Insert("TitleAlignment", False);
	Format.Insert("WrappingAroundLeft",        False);
	Format.Insert("WrappingAroundRight",       False);
	Format.Insert("Width",                "0");
	Format.Insert("Placeholder",           " ");
	Format.Insert("TitleOutput",     False);
	Format.Insert("SuppressSpaces",      True);
	Format.Insert("XMLElement",            New Structure());
	Format.Insert("NameOfXMLAttribute",        "");
	Format.Insert("BarcodeType",           "");
	Format.Insert("UseBase64",    False);
	Format.Insert("BarcodeHeight",        0);
	
	If BasicFormat <> Undefined Then
		FillPropertyValues(Format, BasicFormat);
	EndIf;
	
	Return Format;
	
EndFunction

// Returns the format for the delimiter string.
// 
// Returns:
//   Structure - See NewFormat.
//
Function FormatSeparator() Export
	
	Result                   = NewFormat(); // NewFormat 
	Result.Type               = "Separator";
	Result.TitleOutput = True;
	Return Result;
	
EndFunction

// Returns the format for the barcode.
// 
// Parameters:
//   Align - HorizontalAlign
//   BarcodeType - String
//   BarcodeHeight - Number
//   UseBase64 - Boolean
// 
// Returns:
//   Structure - See NewFormat.
Function FormatBarcode(Align = Undefined, BarcodeType = "EAN13", BarcodeHeight = 0, UseBase64 = True) Export
	
	Result                = NewFormat();
	Result.Type            = "BARCODE";
	Result.Align   = ?(Align = Undefined, HorizontalAlign.Left, Align);
	Result.BarcodeHeight = BarcodeHeight;
	Result.BarcodeType    = BarcodeType;
	Result.UseBase64 = UseBase64;
	Return Result;
	
EndFunction

// Returns the format for the barcode.
// 
// Parameters:
//   Width - String - Barcode Width
//   Align - HorizontalAlign
//   BarcodeType - String
//   BarcodeHeight - Number - Barcode Height
//   UseBase64 - Boolean
// 
// Returns:
//   Structure - See NewFormat
Function FormatBarcodeWidth(Width, Align = Undefined, BarcodeType = "EAN13", BarcodeHeight = 0, UseBase64 = True) Export
	
	Result                = NewFormat();
	Result.Type            = "BARCODE";
	Result.Width         = Width;
	Result.Align   = ?(Align = Undefined, HorizontalAlign.Left, Align);
	Result.BarcodeHeight = BarcodeHeight;
	Result.BarcodeType    = BarcodeType;
	Result.UseBase64 = UseBase64;
	Return Result;
	
EndFunction

// Returns the format for a string.
// 
// Parameters:
//   Align - HorizontalAlign
//   TitleAlignment - Boolean - True - align the title with the text, otherwise False.
//   FlowAround - Boolean - use wrapping
// 
// Returns:
//   Structure - See NewFormat
Function Format_String(Align = Undefined, TitleAlignment = False, FlowAround = False) Export
	
	Result = NewFormat();
	Result.Align          = ?(Align = Undefined, HorizontalAlign.Left, Align);
	Result.TitleAlignment = TitleAlignment;
	Result.WrappingAroundLeft        = FlowAround;
	Result.WrappingAroundRight       = FlowAround;
	Return Result;
	
EndFunction

// Returns the format for a string.
// 
// Parameters:
//   Width - String - Barcode Width
//   Align - HorizontalAlign
//   TitleAlignment - Boolean - True - align the title with the text, otherwise False.
//   FlowAround - Boolean - use wrapping
// 
// Returns:
//   Structure - See NewFormat
//
Function FormatStringWidth(Width, Align = Undefined, TitleAlignment = False, FlowAround = False) Export
	
	Result = NewFormat();
	Result.Type                   = "String";
	Result.Width                = Width;
	Result.Align          = ?(Align = Undefined, HorizontalAlign.Left, Align);
	Result.TitleAlignment = TitleAlignment;
	Result.WrappingAroundLeft        = FlowAround;
	Result.WrappingAroundRight       = FlowAround;
	Return Result;
	
EndFunction

// Returns the format for the XML element.
// 
// Parameters:
//   XMLElement - Structure
//   NameOfXMLAttribute - String
//   BasicFormat - See NewFormat
// 
// Returns:
//   Structure - See NewFormat
//
Function XMLFormat(XMLElement, NameOfXMLAttribute, BasicFormat = Undefined) Export
	
	Result = NewFormat();
	If TypeOf(BasicFormat) = Type("Structure") Then
		FillPropertyValues(Result, BasicFormat);
	Else
		Result.Type = "XML";
	EndIf;
	Result.XMLElement     = XMLElement;
	Result.NameOfXMLAttribute = NameOfXMLAttribute;
	Return Result;
	
EndFunction

#EndRegion

#Region Constructors

// Creates a template object.
//
// Parameters:
//  LineWidth_ - Number - line width for template calculation
//
// Returns:
//  Structure:
//   * LineWidth_ - Number
//   * Debug - Boolean
//   * ErrorLines - Array of String
//   * XML - Boolean
//   * XMLRoot - Structure
//   * XMLElements - See NewMatchingXMLElements
//   * Items - Array of Structure
//   * Result - Array of Structure
 //
Function NewTemplate(LineWidth_ = 48) Export
	
	Template = New Structure();
	Template.Insert("LineWidth_", ?(ValueIsFilled(LineWidth_), LineWidth_, 0));
	Template.Insert("Debug",      False);
	Template.Insert("ErrorLines", New Array());
	Template.Insert("XML",          False);
	Template.Insert("XMLRoot",    New Structure());
	Template.Insert("XMLElements",  NewMatchingXMLElements());
	Template.Insert("Items",     New Array());
	Template.Insert("Result",    New Array());
	Template.Insert("Generated1",  False);
	Return Template;
	
EndFunction

// Adds an XML element to the template.
//
// Parameters:
//   Template - See NewTemplate
//   TagName - String
//   Parent - See NewXMLElement
//   
// Returns:
//  Structure:
//   * Name - String
//   * Subsidiaries - Array of See NewXMLElement
//   * OutputByLines - Boolean
//   * XMLElement - See NewXMLElement
//   * XMLAttributes - Map of Structure
//
Function NewXMLElement(Template, TagName, Parent = Undefined) Export
	
	XMLElement = New Structure();
	XMLElement.Insert("Name", TagName);
	XMLElement.Insert("Subsidiaries", New Array());
	XMLElement.Insert("OutputByLines", False);
	XMLElement.Insert("XMLElement", New Structure());
	XMLElement.Insert("XMLAttributes", NewMatchingXMLAttributes());
	
	If Parent = Undefined Then
		
		Template.XMLRoot = XMLElement;
		Template.XMLElements.Insert(TagName, XMLElement);
		
	ElsIf TypeOf(Parent) = Type("String") Then
		
		ParentXMLElement = Template.XMLElements.Get(Parent);
		If ParentXMLElement = Undefined Then
			Return Undefined;
		EndIf;
		ParentXMLElement.Subsidiaries.Add(XMLElement);
		Template.XMLElements.Insert(TagName, XMLElement);
		
	ElsIf TypeOf(Parent) = Type("Structure") Then
		
		ParentXMLElement = Template.XMLElements.Get(Parent);
		If ParentXMLElement = Undefined Then
			Return Undefined;
		EndIf;
		ParentXMLElement.Subsidiaries.Add(XMLElement);
		
	EndIf;
	
	Return XMLElement;
	
EndFunction

#EndRegion

#Region FormationAndOutput

// Add a line to a template, overloaded procedure:
// * Template String(Template, Header, Value, Format)
// * Template string(Template, Header, Value)
// * Template string(Template, Value, Format)
// * Template string(Template, Value)
//
// Parameters:
//   Template - See NewTemplate
//   Parameter1 - String, Arbitrary - The header value to be added to the template
//   Parameter2 - Structure, Arbitrary - The value or format that will be added to the template
//   Parameter3 - Structure - Format See NewFormat
Procedure AddRow(Template, Parameter1 = Undefined, Parameter2 = Undefined, Parameter3 = Undefined) Export
	
	If TypeOf(Parameter3)=Type("Structure") Then
		// parameter1 - header, parameter2 - value, parameter3 - format
		FiscalDocumentTemplatesInternal.AddTemplateElement(Template, Parameter1, Parameter2, Parameter3);
	ElsIf Parameter3 = Undefined Then
		If TypeOf(Parameter2)=Type("Structure") Then
			// parameter1 - value, parameter2 - Format, parameter3 - missing
			FiscalDocumentTemplatesInternal.AddTemplateElement(Template, "", Parameter1, Parameter2);
		ElsIf Parameter2 = Undefined Then
			// parameter1 - value, parameter2 - missing, parameter3 - missing
			FiscalDocumentTemplatesInternal.AddTemplateElement(Template, "", Parameter1, NewFormat());
		Else
			// parameter1 - header, parameter2 - value, parameter3 - missing (format)
			FiscalDocumentTemplatesInternal.AddTemplateElement(Template, Parameter1, Parameter2, NewFormat());
		EndIf;
	Else
		// parameter1 - title, parameter2 - value, parameter3 - it is not clear what
		FiscalDocumentTemplatesInternal.AddTemplateElement(Template, Parameter1, Parameter2, NewFormat());
	EndIf;
	
EndProcedure

// Add a column to a template, overloaded procedure:
// * Template String(Template, Header, Value, Format)
// * Template string(Template, Header, Value)
// * Template string(Template, Value, Format)
// * Template string(Template, Value)
//
// Parameters:
//   Template - See NewTemplate
//   Parameter1 - String, Arbitrary - The header value to be added to the template
//   Parameter2 - Structure, Arbitrary - The value or format that will be added to the template
//   Parameter3 - See NewFormat
Procedure AddColumn(Template, Parameter1 = Undefined, Parameter2 = Undefined, Parameter3 = Undefined) Export
	
	If TypeOf(Parameter3)=Type("Structure") Then
		// parameter1 - header, parameter2 - value, parameter3 - format
		FiscalDocumentTemplatesInternal.AddColumnOfTemplateElement(Template, Parameter1, Parameter2, Parameter3);
	ElsIf Parameter3 = Undefined Then
		If TypeOf(Parameter2)=Type("Structure") Then
			// parameter1 - value, parameter2 - Format, parameter3 - missing
			FiscalDocumentTemplatesInternal.AddColumnOfTemplateElement(Template, "", Parameter1, Parameter2);
		ElsIf Parameter2 = Undefined Then
			// parameter1 - value, parameter2 - missing, parameter3 - missing
			FiscalDocumentTemplatesInternal.AddColumnOfTemplateElement(Template, "", Parameter1, NewFormat());
		Else
			// parameter1 - header, parameter2 - value, parameter3 - missing (format)
			FiscalDocumentTemplatesInternal.AddColumnOfTemplateElement(Template, Parameter1, Parameter2, NewFormat());
		EndIf;
	Else
		// parameter1 - title, parameter2 - value, parameter3 - it is not clear what
		FiscalDocumentTemplatesInternal.AddColumnOfTemplateElement(Template, Parameter1, Parameter2, NewFormat());
	EndIf;
	
EndProcedure

// Generates a document according to the specified template.
//
// Parameters:
//   Template - See NewTemplate
//
Procedure GenerateDocumentUsingTemplate(Template) Export
	
	For Each Item In Template.Items Do
		
		If Item.Columns.Count()=0 Then
			Continue;
		EndIf;
		
		FiscalDocumentTemplatesInternal.SetWidthOfElementColumns(Template, Item.Columns);
		FiscalDocumentTemplatesInternal.GenerateTemplateElementString(Template, Item);
		
		If ValueIsFilled(Item.XMLElement) Then
			Item.XMLElement.OutputByLines = Item.OutputByLines;
			Item.XMLElement.XMLAttributes.Insert(Item.NameOfXMLAttribute, Item.Rows);
		EndIf;
		
		For Each Column In Item.Columns Do
			If Upper(Column.Type) = "BARCODE" Then
				Item.Images.Add(Column);
			EndIf;
		EndDo;
	EndDo;
	
	Template.Generated1 = True;
	
EndProcedure

// Displays the generated document as a text string.
//
// Parameters:
//  Template - See NewTemplate
//
// Returns:
//  String
//
Function OutputAsText(Template, ReplaceBarcodes = False) Export
	
	If Not Template.Generated1 Then
		GenerateDocumentUsingTemplate(Template);
	EndIf;
	
	Rows       = New Array(); // Array of String
	RowIndex = 0;
	
	Images = New Array(); // Array of Structure
	
	For Each Item In Template.Items Do
		
		StartElement = RowIndex;
		For Each String In Item.Rows Do
			Rows.Add(String);
			RowIndex = RowIndex + 1;
		EndDo;
		
		For Each Picture In Item.Images Do
			Picture.InitialRow = StartElement;
			Images.Add(Picture);
		EndDo;
			
	EndDo;
	
	If Not ReplaceBarcodes Then
		For Each Picture In Images Do // Structure
			BarcodeString_ = "|"+NStr("vi = 'Mã vạch';
										|ru = 'Штрихкод';
										|en = 'Barcode'; fa = 'بارکد';
										|it = 'Штрихкод';
										|pl = 'Barcode';
										|tr = 'Barkod'")+"|" + Picture.BarcodeType + "|";
			For IndexOf = Picture.InitialRow To Picture.InitialRow + Picture.BarcodeHeight-1 Do
				If IndexOf = Rows.UBound() Then
					Rows.Add(CharacterString(Template.LineWidth_));
				EndIf;
				String = Rows[IndexOf];
				Position = Picture.StartPosition;
				Width  = Picture.InitialWidth;
				OutputRow    = Left(BarcodeString_ + CharacterString(Width), Width);
				BarcodeString_ = Mid(BarcodeString_, Width+1);
				String = Left(String, Position-1)+OutputRow+Mid(String, Position+Width);
				Rows[IndexOf] = String;
			EndDo;
		EndDo;   
	EndIf;
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

// Displays the generated document as a tabular document.
//
// Parameters:
//  Template - See NewTemplate
//
// Returns:
//  SpreadsheetDocument
//
Function OutputAsTabularDocument(Template) Export
	
	If Not Template.Generated1 Then
		GenerateDocumentUsingTemplate(Template);
	EndIf;
	
	SpreadsheetDocument               = New SpreadsheetDocument();

	Area                         = SpreadsheetDocument.Area();//"C1:C"+Template.Width of the line);
	Area.ColumnWidth           = 1;
	Area.RowHeight            = 9;
	Area.AutoRowHeight        = False;
	Area.HorizontalAlign = HorizontalAlign.Center;
	Area.VerticalAlign   = VerticalAlign.Center;
	Area.Font                   = New Font("Courier new", 8);
	LineNumber                     = 1;
	
	For Each Item In Template.Items Do
		
		StartElement = LineNumber;
		For Each String In Item.Rows Do
			
			StringLength = StrLen(String);
			
			For CharacterNumber = 1 To StringLength Do
				Area        = SpreadsheetDocument.Area(LineNumber, CharacterNumber);
				Area.Text  = Mid(String, CharacterNumber, 1);
			EndDo;
			LineNumber = LineNumber + 1;
		EndDo;
		
		For Each Picture In Item.Images Do // Structure
				
			Position         = Picture.StartPosition;
			TheWidthOfTheBarcode = Picture.InitialWidth;
			BarcodeHeight = Picture.BarcodeHeight;
			
			RowArea   = SpreadsheetDocument.Area(StartElement, , StartElement + BarcodeHeight, );
			RowArea.StayWithNext = True;
			
			Area         = SpreadsheetDocument.Area(StartElement, Position, 
				StartElement + BarcodeHeight, Position + TheWidthOfTheBarcode);
			FiscalDocumentTemplatesInternal.OutputBarcode(SpreadsheetDocument, Area, Picture.BarcodeType, Picture.String, Picture.UseBase64);
				
		EndDo;
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Displays the generated document as a PDF document.
//
// Parameters:
//  Template - See NewTemplate
//
// Returns:
//  PDFDocument
//
Function OutputAsPDF(Template) Export
	
	Stream             = New MemoryStream();
	SpreadsheetDocument = OutputAsTabularDocument(Template);
	SpreadsheetDocument.Write(Stream, SpreadsheetDocumentFileType.PDF);
	
	PDFDocument = New PDFDocument();
	PDFDocument.Read(Stream);
	
	Return PDFDocument;
	
EndFunction

#EndRegion

#Region Templates

// Returns the structure of parameters for creating a fiscal document template.
// 
// Returns:
//  Structure:
//   * FDFVersion - String - version of the fiscal document format 
//   * Title - String
//   * Signature - Boolean - whether to create a signature field in the document
//   * AdditionalText - String - additional text for output at the bottom of the document
//
Function ParametersOfFiscalDocumentTemplate() Export
	
	Result = New Structure();
	Result.Insert("FDFVersion", "1.2");
	Result.Insert("Title", "");
	Result.Insert("Signature", True);
	Result.Insert("AdditionalText", "");
	Result.Insert("DisplayFiscalInformation", True);
	Return Result;
	
EndFunction

// Generates a cash receipt template of operation based on receipt fiscalization data.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   FiscalTransaction - Structure
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function SalesSlipTemplate(LineWidth_, Data, FiscalTransaction = Undefined, Parameters = Undefined) Export
	
	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.SalesSlipTemplate(Template, Data, FiscalTransaction, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.SalesSlipTemplate(Template, Data, FiscalTransaction, Parameters);
	EndIf;
	
	Return Template;
	
EndFunction

// Generates a template for a shift opening report.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function TemplateReportOnOpeningShift(LineWidth_, Data, Parameters = Undefined) Export

	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.TemplateReportOnOpeningShift(Template, Data, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.TemplateReportOnOpeningShift(Template, Data, Parameters);
	EndIf;
	
	Return Template;

EndFunction

// Generates a template for a shift closure report.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function TemplateReportOnClosingShift(LineWidth_, Data, Parameters = Undefined) Export

	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.TemplateReportOnClosingShift(Template, Data, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.TemplateReportOnClosingShift(Template, Data, Parameters);
	EndIf;
	
	Return Template;

EndFunction

// Generates a Cur State report template.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.OperationExecutionParameters
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function TemplateReportOnCurrentState(LineWidth_, Data, Parameters = Undefined) Export

	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.TemplateReportOnCurrentState(Template, Data, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.TemplateReportOnCurrentState(Template, Data, Parameters);
	EndIf;
	
	Return Template;

EndFunction

// Generates a template for a cash withdrawal report.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.CollectionParameters
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function CashWithdrawalTemplate(LineWidth_, Data, Parameters = Undefined) Export

	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.CashWithdrawalTemplate(Template, Data, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.CashWithdrawalTemplate(Template, Data, Parameters);
	EndIf;
	
	Return Template;

EndFunction

// Generates a template for a cash deposit report.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.CollectionParameters
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function CashDepositTemplate(LineWidth_, Data, Parameters = Undefined) Export
	
	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.CashDepositTemplate(Template, Data, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.CashDepositTemplate(Template, Data, Parameters);
	EndIf;
	
	Return Template;
	
EndFunction

// Generates a template for an info receipt report.
// 
// Parameters:
//   LineWidth_ - Number
//   Data - See PeripheralsReceiptPrintersClientServer.OperationExecutionParameters
//   Parameters - See ParametersOfFiscalDocumentTemplate
//
// Returns:
//  See NewTemplate
//
Function InfoReceiptTemplate(LineWidth_, Data, Parameters = Undefined) Export
	
	Template = NewTemplate(LineWidth_);
	
	If Parameters = Undefined Then
		Parameters = ParametersOfFiscalDocumentTemplate();
	EndIf;
	
	FiscalDocumentTemplatesLocalization.InfoReceiptTemplate(Template, Data, Parameters);
	
	If Template.Items.Count() = 0 Then
		FiscalDocumentTemplatesInternal.InfoReceiptTemplate(Template, Data, Parameters);
	EndIf;
	
	Return Template;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns matching XML elements
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See NewXMLElement
//
Function NewMatchingXMLElements()
	Return New Map();
EndFunction

// Returns matching XML attributes
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - String
//
Function NewMatchingXMLAttributes()
	Return New Map();
EndFunction

// Creates a string of characters of the specified size.
//
// Parameters:
//  Size - Number - size of the line to be created
//  Char - String - characters that will fill in the result
//
// Returns:
//  String - a string of characters of the specified size
//
Function CharacterString(Size, Char = " ")
	Return FiscalDocumentTemplatesInternal.CharacterString(Size, Char);
EndFunction

#EndRegion