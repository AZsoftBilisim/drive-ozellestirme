#Region Internal

// Generates a template for a universal cash receipt of operation based on receipt fiscalization,
// independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   FiscalTransaction - Structure
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure SalesSlipTemplate(Template, Data, FiscalTransaction, Parameters) Export
	
	PrepareSalesSlip(Data, FiscalTransaction, Parameters.FDFVersion);
	
	SalesSlipHeaderTemplate(Template, Data, Parameters);
	
	For Each ReceiptPosition In Data.ReceiptPositions Do
		If ReceiptPosition.Property("FiscalLine") Then
			SalesSlipTemplateCheckPositionFiscalLine(Template, ReceiptPosition);
		ElsIf ReceiptPosition.Property("TextString") Then
			SalesSlipTemplateReceiptPositionTextString(Template, ReceiptPosition);
		ElsIf ReceiptPosition.Property("Barcode") Then
			SalesSlipTemplateReceiptPositionBarcode(Template, ReceiptPosition);
		EndIf;
	EndDo;
	
	SalesSlipBasementTemplate(Template, Data, FiscalTransaction, Parameters);
	
EndProcedure

// Generates a template for a universal report on the opening of a shift, independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure TemplateReportOnOpeningShift(Template, Data, Parameters) Export

	TemplateReport(Template, Data, Parameters, NStr("vi = 'MỞ PHIÊN';
													|ru = 'ОТКРЫТИЕ СМЕНЫ';
													|en = 'SHIFT OPENING'; fa = 'SHIFT OPENING';
													|it = 'APERTURA DI UN TURNO';
													|pl = 'OTWARCIE ZMIANY';
													|tr = 'VARDİYA AÇILIŞI'"));

EndProcedure

// Generates a template for a universal report on the closure of a shift, independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure TemplateReportOnClosingShift(Template, Data, Parameters) Export

	TemplateReport(Template, Data, Parameters, NStr("vi = 'BÁO CÁO Z';
													|ru = 'ОТЧЕТ С ГАШЕНИЕМ';
													|en = 'REPORT WITH CLEARANCE'; fa = 'REPORT WITH CLEARANCE';
													|it = 'RAPPORTO CON ANNULLAMENTO';
													|pl = 'RAPORT Z UNIEWAŻNIENIEM';
													|tr = 'SÖNDÜRMELİ RAPOR'"));

EndProcedure

// Generates a template for a universal report on the Cur State, independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure TemplateReportOnCurrentState(Template, Data, Parameters) Export

	TemplateReport(Template, Data, Parameters, NStr("vi = 'BÁO CÁO TẠM THỜI';
													|ru = 'ОТЧЕТ БЕЗ ГАШЕНИЯ';
													|en = 'REPORT WITHOUT CLEARANCE'; fa = 'REPORT WITHOUT CLEARANCE';
													|it = 'RAPPORTO SENZA ANNULLAMENTO';
													|pl = 'RAPORT BEZ UNIEWAŻNIENIA';
													|tr = 'SÖNDÜRMESİZ RAPOR'"));
	
EndProcedure

// Generates a template for a universal cash withdrawal report, independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure CashWithdrawalTemplate(Template, Data, Parameters) Export
	
	CollectionOperationTemplate(Template, Data, Parameters, NStr("vi = 'RÚT TIỀN';
																|ru = 'ВЫЕМКА';
																|en = 'WITHDRAWAL'; fa = 'WITHDRAWAL';
																|it = 'ВЫЕМКА';
																|pl = 'WITHDRAWAL';
																|tr = 'ÇEKME'"));
	
EndProcedure

// Generates a template for a universal cash deposit report, independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure CashDepositTemplate(Template, Data, Parameters) Export

	CollectionOperationTemplate(Template, Data, Parameters, NStr("vi = 'NHẬP TIỀN';
																|ru = 'ВНЕСЕНИЕ';
																|en = 'DEPOSIT'; fa = 'DEPOSIT';
																|it = 'ВНЕСЕНИЕ';
																|pl = 'DEPOSIT';
																|tr = 'YATIRMA'"));

EndProcedure

// Generates a template for an info receipt that is independent of localization.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - Structure
//
Procedure InfoReceiptTemplate(Template, Data, Parameters) Export

	Module = FiscalDocumentTemplates;
	FormatSeparator = Module.FormatSeparator();
	FormatCenter    = Module.Format_String(HorizontalAlign.Center);
	FormatRight    = Module.Format_String(HorizontalAlign.Right);
	FormatLeft     = Module.Format_String(HorizontalAlign.Left);
	FormatByWidth = Module.Format_String(HorizontalAlign.Justify);  
	
	Module.AddRow (Template, Parameters.Title,            FormatCenter);
	Module.AddRow (Template, Data.CompanyName, FormatCenter);
	Module.AddRow (Template, NStr("vi = 'MST:';
									|ru = 'ИНН:';
									|en = 'TIN:'; fa = 'شناسه مالیاتی:';
									|it = 'ИНН:';
									|pl = 'NIP:';
									|tr = 'VKN:'"), Data.TIN,  FormatLeft);
	Module.AddColumn(Template, NStr("vi = 'MĐK:';
									|ru = 'КПП:';
									|en = 'KPP:'; fa = 'KPP:';
									|it = 'КПП:';
									|pl = 'Kod powodu wpisu do ewidencji podatników (KPP):';
									|tr = 'KPP:'"), Data.CRTR,  FormatRight);
	Module.AddRow (Template, NStr("vi = 'QUẦY THU NGÂN:';
									|ru = 'КАССА:';
									|en = 'CASH REGISTER:'; fa = 'CASH REGISTER:';
									|it = 'КАССА:';
									|pl = 'CASH REGISTER:';
									|tr = 'KASA HESABI:'"), Data.CheckoutNumber, FormatLeft);
	Module.AddColumn(Template, NStr("vi = 'PHIÊN LÀM VIỆC:';
									|ru = 'СМЕНА:';
									|en = 'SHIFT:'; fa = 'SHIFT:';
									|it = 'СМЕНА:';
									|pl = 'SHIFT:';
									|tr = 'VARDİYA:'"), Data.ShiftNumber, FormatRight);
	
	DateTime = Format(CommonCEL.SessionDate(), "DF=""dd.MM.yyyy HH:mm""");
	Module.AddRow (Template, NStr("vi = 'PHIẾU:';
									|ru = 'ЧЕК:';
									|en = 'RECEIPT:'; fa = 'RECEIPT:';
									|it = 'ЧЕК:';
									|pl = 'RECEIPT:';
									|tr = 'FİŞ:'"), Data.ReceiptNumber, FormatLeft);
	Module.AddColumn(Template, NStr("vi = 'NGÀY:';
									|ru = 'ДАТА:';
									|en = 'DATE:'; fa = 'DATE:';
									|it = 'ДАТА:';
									|pl = 'DATE:';
									|tr = 'TARİH:'"), DateTime, FormatRight);
	
	If Not IsBlankString(Data.ReceiptAddress) Then
		Module.AddRow(Template, "|Barcode|QR|" + Data.ReceiptAddress, FormatLeft);
	EndIf;

	Module.AddRow(Template, Data.ReceiptAddress, FormatCenter);
	Module.AddRow(Template, Data.ReceiptSignature, FormatCenter);
	
EndProcedure

#Region TemplateGenerator

// Creates a string of characters of the specified size.
//
// Parameters:
//  Size - Number - the size of the row to create.
//  Char - String - characters that will fill in the result.
//
// Returns:
//  String - a string of characters of the specified size.
//
Function CharacterString(Size, Char = " ") Export
	
	IsBlankString = "";
	CharacterLength = StrLen(Char);
	If CharacterLength = 0 Then
		Return IsBlankString;
	EndIf;

	SubstringCount = Int(Size / CharacterLength)+1;
	For Number = 1 To SubstringCount Do
		IsBlankString = IsBlankString + Char;
	EndDo;
	
	Return Left(IsBlankString, Size);
	
EndFunction

// Adds a line to the template.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Title - String - The header that will be added to the template.
//   Value - Arbitrary - The value that will be added to the template.
//   Format - See FiscalDocumentTemplates.NewFormat.
Procedure AddTemplateElement(Template, Title = "", Value = Undefined, Format = Undefined) Export
	
	Item = NewTemplateElement();
	
	If ValueIsFilled(Item.XMLElement) Then
		If TypeOf(Item.XMLElement) = Type("String") Then
			Item.XMLElement = Template.XMLElements.Get(Item.XMLElement);
		EndIf;
	EndIf;
	Template.Items.Add(Item);
	
	AddColumnOfTemplateElement(Template, Title, Value, Format);
	
EndProcedure

// Adds a column to the last line of the template.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Title - String
//   Value - Arbitrary
//   Format - See FiscalDocumentTemplates.NewFormat.
//
Procedure AddColumnOfTemplateElement(Template, Title = "", Value = Undefined, Format = Undefined) Export
	
	Item = Template.Items[Template.Items.UBound()];
	Column = NewColumnOfTemplateElement();
	
	Column.Value     = Value;
	Column.String       = String(Value);
	Column.Title    = Title;
	Column.WidthFormat = Format.Width; 
	
	FillPropertyValues(Column, Format, , "Width");
	
	// calculate the default barcode height
	If Upper(Format.Type) = "BARCODE" And Column.BarcodeHeight = 0 Then 
		HeightOfTwoDimensionalCode   = 4;
		OneDimensionalCodeHeight  = 2;
		Column.BarcodeHeight = ?(Upper(Column.BarcodeType) = "QR", HeightOfTwoDimensionalCode, OneDimensionalCodeHeight);
	EndIf;
	
	If Column.SuppressSpaces Then
		Column.Title = TrimAll(Column.Title);
	EndIf;
	
	If StrLen(Column.String) > 0 Or Column.TitleOutput Then
		Item.Columns.Add(Column);
	EndIf;

EndProcedure

// Calculates and sets the column width of the transmitted column array.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   ColumnsArray1 - Array of See NewColumnOfTemplateElement.
//
Procedure SetWidthOfElementColumns(Template, ColumnsArray1) Export
	
	LineWidth_ = Template.LineWidth_;
	If LineWidth_ = 0 Then
		Return;
	EndIf;
	
	TotalWidthOfColumns               = 0;
	NumberOfColumnsWithZeroWidth = 0;
	
	For Each Column In ColumnsArray1 Do

		If Column.Type = "XML" Then
			Continue;
		EndIf;
		
		// calculate the specified column width
		If Column.WidthFormat = "*" Then
			// calculate the optimal width
			Column.Width = Min(LineWidth_, StrLen(Column.String + Column.Title));
		ElsIf StrFind(Column.WidthFormat, "%")>0 Then
			// calculate the width as a percentage
			WidthAsPercentage = Number(Left(Column.WidthFormat, StrLen(Column.WidthFormat)-1));
			Column.Width = Int(LineWidth_ / 100 * WidthAsPercentage);
		Else
			// set the width in characters
			Column.Width = Number(Column.WidthFormat);
		EndIf;
		
		// prepare values for calculating the width of columns with an unspecified width
		If Column.Width = 0 Then
			NumberOfColumnsWithZeroWidth = NumberOfColumnsWithZeroWidth + 1;
		Else
			TotalWidthOfColumns = TotalWidthOfColumns + Column.Width;
		EndIf;
			
	EndDo;
	
	// set the width of columns with an unspecified width
	NotWidthUsed = Max(0, LineWidth_ - TotalWidthOfColumns);
	If NumberOfColumnsWithZeroWidth>0 And NotWidthUsed>0 Then
		TotalWidthOfColumns = 0;
		ColumnWidth      = Int(NotWidthUsed / NumberOfColumnsWithZeroWidth);
		For Each Column In ColumnsArray1 Do
			
			If Column.Type = "XML" Then
				Continue;
			EndIf;
			
			If Column.Width = 0 Then
				Column.Width = ColumnWidth;
			EndIf;
			TotalWidthOfColumns = TotalWidthOfColumns + Column.Width;
		EndDo;
	EndIf;
	
	// adjust the first column for rounding error
	If TotalWidthOfColumns<LineWidth_ And ColumnsArray1.Count()>0 Then
		ColumnsArray1[0].Width = ColumnsArray1[0].Width + (LineWidth_ - TotalWidthOfColumns);
	EndIf;
	
EndProcedure

// Generates an array of rows in the element, the columns are displayed in accordance with the specified formatting.
//
// Parameters:
//  Template - See FiscalDocumentTemplates.NewTemplate.
//  Item - See NewTemplateElement.
//  
Procedure GenerateTemplateElementString(Template, Item) Export
	
	Columns       = Item.Columns;
	Rows        = Item.Rows;
	OutputCompleted = False;
	While Not OutputCompleted Do
		
		FirstRow  = ?(Rows.Count()=0, True, False);
		OutputCompleted = True;
		OutputRow  = New Array();
		Position       = 1;
		For Each Column In Columns Do // NewColumnOfTemplateElement
		
			Align = Column.Align;
			Width       = Column.Width;
			Placeholder  = Column.Placeholder;
			If FirstRow Then
				// the first line displays the title
				Title          = Column.Title;
				WidthWithoutHeader = Max(0, Column.Width - StrLen(Title));
				Column.StartPosition = Position;
				Column.InitialWidth  = Column.Width;
				Position = Position + Column.Width;
			Else
				Title          = "";
				WidthWithoutHeader = Column.Width;
			EndIf;
			
			If Column.Type = "XML" Or WidthWithoutHeader = 0 Then
				ColumnRow = Column.String;
					ColumnRow = Title + ColumnRow;
			Else
				If Upper(Column.Type) = "BARCODE" Then
					ColumnRow = CharacterString(Width, " ");
				Else
					If Upper(Column.Type) = "SEPARATOR" Then
						ColumnRow  = CharacterString(Width, Column.String);
						Column.String = "";
					Else
						ColumnRow = CutOnLeftAccordingToWords(Column.String, WidthWithoutHeader);
						If IsBlankString(Column.String) And Align = HorizontalAlign.Justify Then
							// this is the last line when aligned to the width, it needs to be aligned to the left
							Align = HorizontalAlign.Left;
						EndIf;
						ColumnRow = AlignLine(Title, ColumnRow, Align, Column.TitleAlignment, Width, Placeholder);
					EndIf;

					// prepare to wrap the columns
					If IsBlankString(Column.String) Then
						// The text in the column has ended, it no longer needs to be displayed
						Column.NewWidth = 0;
						Column.Completed_   = True;
					Else
						Column.NewWidth = Column.Width;
						OutputCompleted       = False;
					EndIf;
				
				EndIf;
			EndIf;
			
			OutputRow.Add(ColumnRow);
			
		EndDo;
		
		RecalculateColumnSizes(Columns);
		
		Rows.Add(StrConcat(OutputRow));
		
	EndDo;
	
EndProcedure

// Outputs the passed element recursively to the xml record.
// 
// Parameters:
//  Record - XMLWriter
//  Item - Structure
//
Procedure OutputXMLElement(Record, Item) Export
	
	If Item.OutputByLines Then
		For Each String In Item.Rows Do
			Record.WriteStartElement(Item.Name);
			Record.WriteAttribute(Item.NameOfXMLAttribute, XMLString(String));
			Record.WriteEndElement();
		EndDo;
	Else
		If Item.XMLAttributes.Count()=0 And Item.Subsidiaries.Count()=0 Then
			Return;
		EndIf;
		Record.WriteStartElement(Item.Name);
		For Each Attribute In Item.XMLAttributes Do
			String = StrConcat(Attribute.Value);
			Record.WriteAttribute(Attribute.Key, XMLString(String));
		EndDo;
		For Each ChildOne In Item.Subsidiaries Do
			OutputXMLElement(Record, ChildOne);
		EndDo;
		Record.WriteEndElement();
	EndIf;
	
EndProcedure

// Displays a barcode tabular document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - the document where the barcode should be displayed.
//  Area - SpreadsheetDocumentRange - the area where the barcode should be displayed.
//  BarcodeType - String - the type of barcode in text form.
//  Barcode - String - Barcode value.
//  UseBase64 - Boolean - Use Base64. 
//
Procedure OutputBarcode(SpreadsheetDocument, Area, BarcodeType, Val Barcode, Val UseBase64 = False) Export
	
	BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
	BarcodeParameters.Zoomable     = True;
	BarcodeParameters.MaintainAspectRatio = True;
	BarcodeParameters.TextVisible    = False;
	BarcodeParameters.Barcode = Barcode;
	BarcodeParameters.InputDataType = ?(UseBase64, 1, 0);
	BarcodeParameters.CodeType  = NumericBarcodeType(BarcodeType);

	Barcode = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	If BarcodeParameters.CodeType = 16 Then
		Barcode.PictureSize   = PictureSize.Proportionally;
		BarcodeParameters.Width = 100;
		BarcodeParameters.Height = 100;
	Else
		Barcode.PictureSize   = PictureSize.RealSize;
		BarcodeParameters.Width = 100;
		BarcodeParameters.Height = 100;
	EndIf;
	
	Image       = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters);
	Barcode.Picture = Image.Picture;
	Barcode.TopBorder = False;
	Barcode.BottomBorder  = False;
	Barcode.RightBorder = False;
	Barcode.LeftBorder  = False;
	
	Area.BySelectedColumns = True;
	Area.TextPlacement     = SpreadsheetDocumentTextPlacementType.Wrap;
	Barcode.Place(Area);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region DocumentTemplates

// Performs preliminary preparation.
//  
// Parameters:
//  Data - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation.
//  FDFVersion - String
//
Procedure PrepareSalesSlip(Data, FiscalTransaction, FDFVersion)
	
	If Not ValueIsFilled(Data.CompanyName) And ValueIsFilled(FiscalTransaction) Then
		InformationRecords = PeripheralsReceiptPrinters.CompanyInformation(FiscalTransaction.Organization);
		Data.CompanyName = InformationRecords.Description;
	EndIf;
	
	// Receipt positions
	VATTable   = New Map();
	TableSum = New Map();
	ReceiptAmount    = 0;
	PayAmount  = 0;
	
	For Each ReceiptPosition In Data.ReceiptPositions Do
		
		If ReceiptPosition.Property("FiscalLine") Then
			Sum        = ReceiptPosition.Sum;
			VATRate    = ReceiptPosition.VATRate;
			VATAmount     = ?(ReceiptPosition.VATAmount = 0, 0, ReceiptPosition.VATAmount);
			
			// VAT
			If VATRate = Undefined Then
				TaxText = NStr("vi = 'KHÔNG GỒM THUẾ GTGT';
								|ru = 'БЕЗ НДС';
								|en = 'EXCLUDING VAT'; fa = 'EXCLUDING VAT';
								|it = 'IVA esclusa';
								|pl = 'NETTO';
								|tr = 'KDV HARİÇ'");
				AmountInTableByKey(VATTable, "EXCLUDINGVAT", VATAmount);
				AmountInTableByKey(TableSum, "EXCLUDINGVAT", Sum);
			ElsIf VATRate = 0 Then
				TaxText = NStr("vi = 'Thuế GTGT 0%';
								|ru = 'НДС 0%';
								|en = 'VAT 0%'; fa = 'VAT 0%';
								|it = 'IVA 0%';
								|pl = 'VAT 0%';
								|tr = '% 0 KDV'");
				AmountInTableByKey(VATTable, VATRate, VATAmount);
				AmountInTableByKey(TableSum, VATRate, Sum);
			ElsIf VATRate < 100 Then
				TaxText = StrTemplate(NStr("vi = 'Thuế GTGT %1%%';
											|ru = 'НДС %1%%';
											|en = 'VAT %1%%'; fa = 'VAT %1%%';
											|it = 'НДС %1%%';
											|pl = 'VAT %1%%';
											|tr = 'KDV %1%%'"), VATRate);
				VATAmount = ?(VATAmount = Undefined, 0, VATAmount);
				AmountInTableByKey(VATTable, VATRate, VATAmount);
				AmountInTableByKey(TableSum, VATRate, Sum);
			ElsIf VATRate >= 100 Then
				TaxText = StrTemplate(NStr("vi = 'Thuế GTGT %1/%2%%';
											|ru = 'НДС %1/%2%%';
											|en = 'VAT %1/%2%%'; fa = 'VAT %1/%2%%';
											|it = 'НДС %1/%2%%';
											|pl = 'VAT %1/%2%%';
											|tr = 'KDV %2/%1%%'"), VATRate-100, VATRate);
				VATAmount = ?(VATAmount = Undefined, 0, VATAmount);
				AmountInTableByKey(VATTable, VATRate, VATAmount);
				AmountInTableByKey(TableSum, VATRate, Sum);
			EndIf;
			ReceiptPosition.Insert("TaxText", TaxText);
			
			ReceiptAmount = ReceiptAmount + Sum;
		EndIf;
	EndDo;
	
	// receipt basement
	// payment table
	TextPaymentTable = New Map();
	For Each PaymentLine_ In Data.TableOfPayment Do
		If PaymentLine_.Sum = 0 Then
			Continue;
		EndIf;
		TypeOfPayment = PeripheralsReceiptPrintersClientServer.NameOfPaymentTypeCCT(PaymentLine_.TypeOfPayment, FDFVersion);
		AmountInTableByKey(TextPaymentTable, TypeOfPayment, PaymentLine_.Sum);
		PayAmount = PayAmount + PaymentLine_.Sum;
	EndDo;
	Data.Insert("TextPaymentTable", TextPaymentTable);
	Data.Insert("PayAmount",  PayAmount);
	Data.Insert("ReceiptAmount",    ReceiptAmount);
	
	// VAT table
	TextVATTable = New Map();
	For Each VATLine In VATTable Do
		
		VATRate = VATLine.Key;
		VATAmount  = VATLine.Value;
		If VATRate = "EXCLUDINGVAT" Then
			Title = " "+NStr("vi = 'SỐ TIỀN KHÔNG GỒM THUẾ GTGT';
							|ru = 'СУММА БЕЗ НДС';
							|en = 'AMOUNT EXCLUDING VAT'; fa = 'AMOUNT EXCLUDING VAT';
							|it = 'СУММА БЕЗ НДС';
							|pl = 'AMOUNT EXCLUDING VAT';
							|tr = 'KDV HARİÇ TUTAR'");    
			Sum = TableSum.Get(VATRate);
			VATAmount  = ?(Sum > 0, Sum, 0);
		ElsIf VATRate = 0 Then
			Title = " "+NStr("vi = 'SỐ TIỀN THUẾ GTGT 0%';
							|ru = 'СУММА С НДС 0%';
							|en = 'AMOUNT INCLUDING VAT 0%'; fa = 'AMOUNT INCLUDING VAT 0%';
							|it = 'СУММА С НДС 0%';
							|pl = 'AMOUNT INCLUDING VAT 0%';
							|tr = '0% KDV DAHİL TUTAR'");
			Sum = TableSum.Get(VATRate);
			VATAmount  = ?(Sum > 0, Sum, 0);
		ElsIf VATRate < 100 Then
			Title = StrTemplate(NStr("vi = 'SỐ TIỀN THUẾ GTGT %1%%';
									|ru = 'СУММА НДС %1%%';
									|en = 'VAT AMOUNT %1%%'; fa = 'VAT AMOUNT %1%%';
									|it = 'СУММА НДС %1%%';
									|pl = 'VAT AMOUNT %1%%';
									|tr = 'KDV TUTARI %1%%'"), VATRate);
			Sum = TableSum.Get(VATRate);
			VATAmount  = ?(VATAmount > 0, VATAmount, Sum / (100+VATRate) * VATRate );
		ElsIf VATRate >= 100 Then
			Title = StrTemplate(NStr("vi = 'Số tiền thuế GTGT %1/%2%%';
									|ru = 'СУММА НДС %1/%2%%';
									|en = 'VAT AMOUNT %1/%2%%'; fa = 'VAT AMOUNT %1/%2%%';
									|it = 'СУММА НДС %1/%2%%';
									|pl = 'VAT AMOUNT %1/%2%%';
									|tr = 'KDV TUTARI %2/%1%%'"), VATRate-100, VATRate);
			Sum = TableSum.Get(VATRate);
			VATAmount  = ?(VATAmount > 0, VATAmount, Sum / VATRate * (VATRate-100) );
		EndIf;
		TextVATTable.Insert(Title, VATAmount);
		
	EndDo;
	Data.Insert("TextVATTable", TextVATTable);
	
	
EndProcedure

// The procedure summarizes according to the value of the transmitted key.
Procedure AmountInTableByKey(Table, Var_Key, Value)
	Sum = Table.Get(Var_Key);
	Sum = ?(Sum = Undefined, 0, Sum);
	Table.Insert(Var_Key, Sum + ?(Value = Undefined, 0, Value));
EndProcedure

// Generates a universal report template.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//   DocumentName_1 - String
//
Procedure TemplateReport(Template, Data, Parameters, DocumentName_1) Export

	Module = FiscalDocumentTemplates;
	FormatSeparator = Module.FormatSeparator();
	FormatCenter    = Module.Format_String(HorizontalAlign.Center);
	FormatRight    = Module.Format_String(HorizontalAlign.Right);
	FormatLeft     = Module.Format_String(HorizontalAlign.Left);
	FormatByWidth = Module.Format_String(HorizontalAlign.Justify);
	
	DateTime  = CommonCEL.SessionDate();
	DateTime  = Format(DateTime, NStr("vi = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|ru = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|en = 'DF=""MM/dd/yyyy HH:mm""'; fa = 'DF=""MM/dd/yyyy HH:mm""';
										|it = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|pl = 'DF=""MM/dd/yyyy HH:mm""';
										|tr = 'DF=""dd.MM.yyyy HH:mm""'"));
	
	FormatSignature = FiscalDocumentTemplates.NewFormat(FormatLeft);
	FormatSignature.Placeholder       = "_";
	FormatSignature.TitleOutput = True;
	
	Module.AddRow (Template, Parameters.Title,  FormatCenter);
	Module.AddRow (Template, NStr("vi = 'CHẾ ĐỘ BÌNH THƯỜNG';
									|ru = 'НЕФИСКАЛЬНЫЙ РЕЖИМ';
									|en = 'NON-FISCAL MODE'; fa = 'NON-FISCAL MODE';
									|it = 'MODALITÀ NON FISCALE';
									|pl = 'TRYB NIEFISKALNY';
									|tr = 'MALİ DÖNEM DIŞI MOD'"),  FormatCenter);
	Module.AddRow (Template, "=", FormatSeparator);
	Module.AddRow (Template, Data.SettlementAddress, FormatCenter);
	Module.AddRow (Template, Data.PlaceOfSettlement, FormatCenter);
	Module.AddRow (Template, DocumentName_1,    FormatCenter);
	Module.AddRow (Template, DateTime,            FormatRight);
	Module.AddRow (Template, NStr("vi = 'THU NGÂN:';
									|ru = 'КАССИР:';
									|en = 'CASHIER:'; fa = 'CASHIER:';
									|it = 'КАССИР:';
									|pl = 'CASHIER:';
									|tr = 'KASİYER:'"), Data.Cashier, FormatLeft);
	If Parameters.Signature Then
		Module.AddRow (Template, NStr("vi = 'CHỮ KÝ:';
										|ru = 'ПОДПИСЬ:';
										|en = 'SIGNATURE:'; fa = 'SIGNATURE:';
										|it = 'ПОДПИСЬ:';
										|pl = 'SIGNATURE:';
										|tr = 'İMZA:'"), FormatSignature);
	EndIf;
	Module.AddRow (Template, "=", FormatSeparator);

EndProcedure

// Generates a template for a universal collection report.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//   NameOfOperation - String
//
Procedure CollectionOperationTemplate(Template, Data, Parameters, NameOfOperation) Export

	Module = FiscalDocumentTemplates;
	FormatSeparator = Module.FormatSeparator();
	FormatCenter    = Module.Format_String(HorizontalAlign.Center);
	FormatRight    = Module.Format_String(HorizontalAlign.Right);
	FormatLeft     = Module.Format_String(HorizontalAlign.Left);
	FormatByWidth = Module.Format_String(HorizontalAlign.Justify);
	
	DateTime  = CommonCEL.SessionDate();
	DateTime  = Format(DateTime, NStr("vi = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|ru = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|en = 'DF=""MM/dd/yyyy HH:mm""'; fa = 'DF=""MM/dd/yyyy HH:mm""';
										|it = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|pl = 'DF=""MM/dd/yyyy HH:mm""';
										|tr = 'DF=""dd.MM.yyyy HH:mm""'"));
	
	FormatSignature = FiscalDocumentTemplates.NewFormat(FormatLeft);
	FormatSignature.Placeholder       = "_";
	FormatSignature.TitleOutput = True;
	
	NumberFormat_ = "NDS=.;ND=12;NFD=2;NZ=0.00;NG=0";
	
	Module.AddRow (Template, Parameters.Title,  FormatCenter);
	Module.AddRow (Template, NStr("vi = 'CHẾ ĐỘ BÌNH THƯỜNG';
									|ru = 'НЕФИСКАЛЬНЫЙ РЕЖИМ';
									|en = 'NON-FISCAL MODE'; fa = 'NON-FISCAL MODE';
									|it = 'MODALITÀ NON FISCALE';
									|pl = 'TRYB NIEFISKALNY';
									|tr = 'MALİ DÖNEM DIŞI MOD'"),  FormatCenter);
	Module.AddRow (Template, Data.Organization, FormatCenter);
	Module.AddRow (Template, NStr("vi = 'SỐ TIỀN=';
									|ru = 'СУММА=';
									|en = 'AMOUNT='; fa = 'AMOUNT=';
									|it = 'СУММА=';
									|pl = 'AMOUNT=';
									|tr = 'TUTAR='"), Format(Data.Sum, NumberFormat_), FormatRight);
	Module.AddRow (Template, "=", FormatSeparator);
	Module.AddRow (Template, NameOfOperation,  FormatCenter);
	Module.AddRow (Template, DateTime, FormatRight);
	Module.AddRow (Template, NStr("vi = 'THU NGÂN:';
									|ru = 'КАССИР:';
									|en = 'CASHIER:'; fa = 'CASHIER:';
									|it = 'КАССИР:';
									|pl = 'CASHIER:';
									|tr = 'KASİYER:'"), Data.Cashier, FormatLeft);
	If Parameters.Signature Then
		Module.AddRow (Template, NStr("vi = 'CHỮ KÝ:';
										|ru = 'ПОДПИСЬ:';
										|en = 'SIGNATURE:'; fa = 'SIGNATURE:';
										|it = 'ПОДПИСЬ:';
										|pl = 'SIGNATURE:';
										|tr = 'İMZA:'"), FormatSignature);
	EndIf;

EndProcedure

// Generates a template for the cash receipt header.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure SalesSlipHeaderTemplate(Template, Data, Parameters)
	
	Module = FiscalDocumentTemplates;
	
	FormatSeparator    = Module.FormatSeparator();
	FormatCenter    = Module.Format_String(HorizontalAlign.Center);
	FormatRight    = Module.Format_String(HorizontalAlign.Right);
	FormatLeft     = Module.Format_String(HorizontalAlign.Left);
	FormatByWidth = Module.Format_String(HorizontalAlign.Justify);
	
	Module.AddRow (Template, Parameters.Title,        FormatCenter);
	Module.AddRow (Template, "=======",                  FormatSeparator);
	Module.AddRow (Template, Data.CompanyName, FormatCenter);
	Module.AddRow (Template, Data.SettlementAddress,       FormatCenter);
	Module.AddRow (Template, Data.PlaceOfSettlement,       FormatCenter);
	Module.AddRow (Template, Data.StoreAddress,       FormatCenter);
	Module.AddRow (Template, Data.HeaderText,          FormatCenter);
	Module.AddRow (Template, NStr("vi = 'PHIẾU TÍNH TIỀN';
									|ru = 'КАССОВЫЙ ЧЕК';
									|en = 'SALES SLIP'; fa = 'SALES SLIP';
									|it = 'SCONTRINI DI VENDITA';
									|pl = 'PARAGON KASOWY';
									|tr = 'SATIŞ FİŞİ'"),  FormatCenter);
	
	CalculationCode = PeripheralsReceiptPrintersClientServer.CashSettlementCode(Data.CalculationType);
	ReceiptType    = PeripheralsReceiptPrintersClientServer.NameOfCashSettlementCode(CalculationCode);
	Module.AddRow (Template, NStr("vi = 'MST';
									|ru = 'ИНН';
									|en = 'TIN'; fa = 'شناسه مالیاتی';
									|it = 'ИНН';
									|pl = 'TIN';
									|tr = 'VKN'")+" ", Data.CompanyTIN, FormatLeft);
	Module.AddColumn(Template, ReceiptType, FormatRight);
	
	DateTime  = ?(Not IsBlankString(Data.DateTime), Data.DateTime, CommonCEL.SessionDate());
	DateTime  = Format(DateTime, NStr("vi = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|ru = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|en = 'DF=""MM/dd/yyyy HH:mm""'; fa = 'DF=""MM/dd/yyyy HH:mm""';
										|it = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
										|pl = 'DF=""MM/dd/yyyy HH:mm""';
										|tr = 'DF=""dd.MM.yyyy HH:mm""'"));
	Module.AddRow (Template, NStr("vi = 'PHIẾU TÍNH TIỀN SỐ';
									|ru = 'ЧЕК №';
									|en = 'RECEIPT No.'; fa = 'RECEIPT No.';
									|it = 'SCONTRINO №';
									|pl = 'PARAGON nr';
									|tr = 'FİŞ NO'"), Data.ReceiptNumber, FormatLeft);
	Module.AddColumn(Template, DateTime, FormatRight);
	
	Customer    = Data.Recipient;
	BuyerTin = Data.BeneficiaryTIN;
	BuyerAddress = "";
	BuyerInformation = Data.BuyerInformation;
	Customer      = ?(Not IsBlankString(BuyerInformation.Customer),      BuyerInformation.Customer,      Customer);
	BuyerTin   = ?(Not IsBlankString(BuyerInformation.BuyerTin),   BuyerInformation.BuyerTin,   BuyerTin);
	BuyerAddress = ?(Not IsBlankString(BuyerInformation.BuyerAddress), BuyerInformation.BuyerAddress, BuyerAddress);
	Module.AddRow (Template, NStr("vi = 'KHÁCH HÀNG:';
									|ru = 'ПОКУПАТЕЛЬ:';
									|en = 'CUSTOMER:'; fa = 'CUSTOMER:';
									|it = 'ПОКУПАТЕЛЬ:';
									|pl = 'CUSTOMER:';
									|tr = 'MÜŞTERİ:'"),     Customer,    FormatRight);
	Module.AddRow (Template, NStr("vi = 'MST KHÁCH HÀNG:';
									|ru = 'ИНН ПОКУПАТЕЛЯ:';
									|en = 'CUSTOMER TIN:'; fa = 'CUSTOMER TIN:';
									|it = 'CODICE FISCALE DELL''ACQUIRENTE';
									|pl = 'NIP NABYWCY:';
									|tr = 'MÜŞTERİYE AİT VKN:'"), BuyerTin, FormatRight);
	Module.AddRow (Template, NStr("vi = 'ĐỊA CHỈ KHÁCH HÀNG:';
									|ru = 'АДРЕС ПОКУПАТЕЛЯ:';
									|en = 'CUSTOMER ADDRESS:'; fa = 'CUSTOMER ADDRESS:';
									|it = 'АДРЕС ПОКУПАТЕЛЯ:';
									|pl = 'CUSTOMER ADDRESS:';
									|tr = 'MÜŞTERİ ADRESİ:'"), BuyerAddress, FormatRight);
	
	Module.AddRow (Template, Upper(Data.AgentAttribute), FormatLeft);

	
	AdditionalUserDetails = Data.AdditionalUserDetails;
	Module.AddRow (Template, AdditionalUserDetails.Description, AdditionalUserDetails.Value, FormatRight);
	
	Module.AddRow(Template, "-", FormatSeparator);
	
EndProcedure

// Generates a template for the fiscal line at the position of the cash receipt.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   ReceiptPosition - Structure
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure SalesSlipTemplateCheckPositionFiscalLine(Template, ReceiptPosition)
	
	Module = FiscalDocumentTemplates;
	
	FormatCenter    = Module.Format_String(HorizontalAlign.Center);
	FormatRight    = Module.Format_String(HorizontalAlign.Right);
	FormatLeft     = Module.Format_String(HorizontalAlign.Left);
	FormatByWidth = Module.Format_String(HorizontalAlign.Justify);
	
	// Receipt positions
	NumberFormat_2 = "NDS=.;ND=12;NFD=2;NZ=0.00;NG=0";
	NumberFormat_3 = "NDS=.;ND=12;NFD=3;NZ=0.000;NG=0";
	
	Count   = ReceiptPosition.Count;
	Sum        = ReceiptPosition.Sum;
	Profit  = ?(IsBlankString(ReceiptPosition.Profit), 0, ReceiptPosition.Profit);
	PriceForPrinting = Round(Sum / ?(Count > 0, Count, 1), 2);
	
	RowOfProduct = StrTemplate("%1 x %2=%3",
		Format(Count, NumberFormat_3),
		Format(PriceForPrinting, NumberFormat_2),
		Format(Sum, NumberFormat_2));
		
	Module.AddRow (Template, ReceiptPosition.Description, FormatLeft);
	Module.AddRow (Template, RowOfProduct,             FormatRight);
	
	If Profit > 0 Then
		Module.AddRow (Template, NStr("vi = 'CHIẾT KHẤU=';
										|ru = 'СКИДКА=';
										|en = 'DISCOUNT='; fa = 'DISCOUNT=';
										|it = 'СКИДКА=';
										|pl = 'DISCOUNT=';
										|tr = 'İNDİRİM='"), Format(Profit, NumberFormat_2), FormatLeft);
	ElsIf Profit < 0 Then
		Module.AddRow (Template, NStr("vi = 'PHỤ CẤP=';
										|ru = 'НАДБАВКА=';
										|en = 'STANDARD BONUS='; fa = 'STANDARD BONUS=';
										|it = 'НАДБАВКА=';
										|pl = 'STANDARD BONUS=';
										|tr = 'ÖDENEK='"), Format(Profit, NumberFormat_2), FormatLeft);
	Else
		Module.AddRow (Template);
	EndIf;
	Module.AddColumn(Template, ReceiptPosition.TaxText, FormatRight);
	Module.AddRow (Template, Upper(ReceiptPosition.SettlementSubjectFlag), FormatRight);
	
	ShowsCalculationMethod = 
		PeripheralsReceiptPrintersClientServer.CodeForCalculationMethodAttribute(ReceiptPosition.ShowsCalculationMethod);
	PaymentMethodAttributeName = 
		PeripheralsReceiptPrintersClientServer.NameOfCalculationMethodAttribute(ShowsCalculationMethod);
	Module.AddRow (Template, PaymentMethodAttributeName, FormatLeft);
	
	
	Module.AddRow (Template, NStr("vi = 'MÃ QUỐC GIA:';
									|ru = 'КОД СТРАНЫ:';
									|en = 'COUNTRY CODE:'; fa = 'COUNTRY CODE:';
									|it = 'CODICE DEL PAESE:';
									|pl = 'KOD KRAJU:';
									|tr = 'ÜLKE KODU:'"),  ReceiptPosition.CountryCodeOfOrigin, FormatLeft);
	Module.AddRow (Template, NStr("vi = 'TỜ KHAI:';
									|ru = 'ДЕКЛАРАЦИЯ:';
									|en = 'DECLARATION:'; fa = 'DECLARATION:';
									|it = 'ДЕКЛАРАЦИЯ:';
									|pl = 'DECLARATION:';
									|tr = 'BEYANNAME:'"),  ReceiptPosition.CustomsDeclarationNumber,    FormatLeft);
	Module.AddRow (Template, NStr("vi = 'THUẾ TIÊU THỤ ĐẶC BIỆT:';
									|ru = 'АКЦИЗ:';
									|en = 'EXCISE:'; fa = 'EXCISE:';
									|it = 'АКЦИЗ:';
									|pl = 'EXCISE:';
									|tr = 'TEDARİK:'"),       ReceiptPosition.ExciseTaxAmount,                  FormatLeft);
	Module.AddRow (Template, NStr("vi = 'ĐƠN VỊ TÍNH:';
									|ru = 'ЕД.ИЗМЕРЕНИЯ:';
									|en = 'UNIT OF MEASURE:'; fa = 'UNIT OF MEASURE:';
									|it = 'ЕД.ИЗМЕРЕНИЯ:';
									|pl = 'UNIT OF MEASURE:';
									|tr = 'ÖLÇÜ BİRİMİ:'"),ReceiptPosition.UnitOfMeasure,             FormatLeft);
	Module.AddRow (Template, Upper(ReceiptPosition.AttributeOfAgentForSubjectOfCalculation),                    FormatLeft);
	

	Module.AddRow (Template, NStr("vi = 'THÔNG TIN BỔ SUNG:';
									|ru = 'ДОП.РЕК.:';
									|en = 'ADD. ATTR.:'; fa = 'ADD. ATTR.:';
									|it = 'ДОП.РЕК.:';
									|pl = 'ADD. ATTR.:';
									|tr = 'EK ÖZNİTELİKLER:'"), ReceiptPosition.AdditionalAttribute, FormatRight);
	
EndProcedure

// Generates a text string template at the position of the cash receipt.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   ReceiptPosition - See PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters.
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure SalesSlipTemplateReceiptPositionTextString(Template, ReceiptPosition)
	
	Module = FiscalDocumentTemplates;
	
	Format = Module.Format_String(HorizontalAlign[ReceiptPosition.Align]);
	Module.AddRow (Template, ReceiptPosition.Text, Format);
	
EndProcedure

// Generates a barcode string template at the cash receipt position.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   ReceiptPosition - See PeripheralsReceiptPrintersClientServer.ParametersBarcodeInReceiptLine
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure SalesSlipTemplateReceiptPositionBarcode(Template, ReceiptPosition)
	
	Module = FiscalDocumentTemplates;
	
	Format = Module.FormatBarcode(HorizontalAlign.Center, ReceiptPosition.BarcodeType, 2);
	Module.AddRow(Template, ReceiptPosition.BarcodeBASE64, Format);
	Module.AddRow(Template, " ");
	
EndProcedure

// Generates a cashier's check basement template.
//
// Parameters:
//   Template - See FiscalDocumentTemplates.NewTemplate.
//   Data - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation.
//   FiscalTransaction - Structure
//   Parameters - See FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate.
//
Procedure SalesSlipBasementTemplate(Template, Data, FiscalTransaction, Parameters)
	
	Module = FiscalDocumentTemplates;
	
	FormatSeparator    = Module.FormatSeparator();
	FormatCenter    = Module.Format_String(HorizontalAlign.Center);
	FormatRight    = Module.Format_String(HorizontalAlign.Right);
	FormatLeft     = Module.Format_String(HorizontalAlign.Left);
	FormatByWidth = Module.Format_String(HorizontalAlign.Justify);
	
	// Receipt positions
	NumberFormat_2 = "NDS=.;ND=12;NFD=2;NZ=0.00;NG=0";
	NumberFormat_3 = "NDS=.;ND=12;NFD=3;NZ=0.000;NG=0";
	
	PayAmount = Data.PayAmount;
	ReceiptAmount   = Data.ReceiptAmount;
	
	Module.AddRow (Template, "-", FormatSeparator);
	Module.AddRow (Template, NStr("vi = 'TỔNG SỐ=';
									|ru = 'ИТОГ=';
									|en = 'TOTAL='; fa = 'TOTAL=';
									|it = 'ИТОГ=';
									|pl = 'TOTAL=';
									|tr = 'TOPLAM='"), Format(ReceiptAmount, NumberFormat_2), FormatRight);
	Module.AddRow (Template, "-", FormatSeparator);
	Module.AddRow (Template, NStr("vi = 'THANH TOÁN';
									|ru = 'ОПЛАТА';
									|en = 'PAYMENT'; fa = 'PAYMENT';
									|it = 'ОПЛАТА';
									|pl = 'PAYMENT';
									|tr = 'ÖDEME'"), FormatLeft);

	FormatWidth2 = FiscalDocumentTemplates.FormatStringWidth(2);
	For Each PaymentLine_ In Data.TextPaymentTable Do
		Module.AddRow (Template, " ", FormatWidth2);
		Module.AddColumn(Template, PaymentLine_.Key, Format(PaymentLine_.Value, NumberFormat_2), FormatRight);
	EndDo;
	
	If PayAmount - ReceiptAmount > 0 Then
		Module.AddRow(Template, NStr("vi = 'ĐÃ NHẬN=';
									|ru = 'ПОЛУЧЕНО=';
									|en = 'RECEIVED='; fa = 'RECEIVED=';
									|it = 'ПОЛУЧЕНО=';
									|pl = 'RECEIVED=';
									|tr = 'ALINAN='"), Format(PayAmount, NumberFormat_2), FormatRight);
		Module.AddRow(Template, NStr("vi = 'TIỀN THỪA=';
									|ru = 'СДАЧА=';
									|en = 'CHANGE='; fa = 'CHANGE=';
									|it = 'СДАЧА=';
									|pl = 'CHANGE=';
									|tr = 'PARA ÜSTÜ='"), Format(PayAmount - ReceiptAmount, NumberFormat_2), FormatRight);
	EndIf; 
	
	
	For Each VATLine In Data.TextVATTable Do
		Module.AddRow (Template, " ", FormatWidth2);
		Module.AddColumn(Template, VATLine.Key, Format(VATLine.Value, NumberFormat_2), FormatRight);
	EndDo;
		
	Module.AddRow (Template, NStr("vi = 'THU NGÂN:';
									|ru = 'КАССИР:';
									|en = 'CASHIER:'; fa = 'CASHIER:';
									|it = 'КАССИР:';
									|pl = 'CASHIER:';
									|tr = 'KASİYER:'"), Data.Cashier, FormatLeft);
	If Parameters.Signature Then
		Format = FiscalDocumentTemplates.NewFormat(FormatLeft);
		Format.Placeholder       = "_";
		Format.TitleOutput = True;
		Module.AddRow (Template, NStr("vi = 'CHỮ KÝ:';
										|ru = 'ПОДПИСЬ:';
										|en = 'SIGNATURE:'; fa = 'SIGNATURE:';
										|it = 'ПОДПИСЬ:';
										|pl = 'SIGNATURE:';
										|tr = 'İMZA:'"), Format);
	EndIf;
	Module.AddRow (Template, Parameters.AdditionalText, FormatCenter);
	Module.AddRow (Template, Data.FooterText,           FormatCenter);
	Module.AddRow (Template, "======", FormatSeparator);
	
	// QR code and data of operation
	If Parameters.DisplayFiscalInformation And FiscalTransaction <> Undefined Then
		Module.AddRow(Template, " ");
		Module.AddRow(Template, NStr("vi = 'Số đăng ký MTT:';
									|ru = 'РН ККТ:';
									|en = 'Cash register registration number:'; fa = 'Cash register registration number:';
									|it = 'Numero di registrazione del registratore di cassa';
									|pl = 'RN KKT:';
									|tr = 'RN KKT (yazar kasa):'"), FiscalTransaction.CRERegistrationNumber, FormatRight);
		Module.AddRow(Template, NStr("vi = 'Bộ nhớ máy tính tiền số:';
									|ru = 'ФН №:';
									|en = 'Fiscal memory device N.:'; fa = 'Fiscal memory device N.:';
									|it = 'Accumulatore fiscale №:';
									|pl = 'Dysk fiskalny nr:';
									|tr = 'FN No:'"), FiscalTransaction.ManufaturerNumberOfFiscalStorage, FormatRight);
		Module.AddRow(Template, NStr("vi = 'Chứng từ tài chính số:';
									|ru = 'ФД №:';
									|en = 'Fiscal document No:'; fa = 'Fiscal document No:';
									|it = 'Documento fiscale №:';
									|pl = 'Dokument fiskalny nr:';
									|tr = 'FD No:'"), Format(FiscalTransaction.CashRegisterReceiptNumber,"NG="), FormatRight);
		Module.AddRow(Template, NStr("vi = 'Bộ nhớ máy tính tiền:';
									|ru = 'ФП:';
									|en = 'Fiscal flag:'; fa = 'Fiscal flag:';
									|it = 'ФП:';
									|pl = 'Fiscal flag:';
									|tr = 'Fİ:'"), FiscalTransaction.FiscalFlag, FormatRight);
		Module.AddRow(Template, " ");
		Format = Module.FormatBarcode(HorizontalAlign.Center, "QR", 6, False);
		Module.AddRow(Template, Data.QRCode.CodeValue, Format);
	EndIf;
	
EndProcedure

#EndRegion

#Region TemplateGenerator

// Constructor of the template element.
//
// Returns:
//  Structure:
//   * Rows - Array of String - array of generated strings.
//   * Columns - Array of See NewColumnOfTemplateElement.
//   * Images - Array of Structure
//   * OutputByLines - Boolean
//   * XMLElement - Structure
//   * NameOfXMLAttribute - String
//
Function NewTemplateElement()

	Item = New Structure();
	Item.Insert("Rows",  New Array()); // Array of String 
	Item.Insert("Columns", New Array()); // Array of See NewColumnOfTemplateElement
	Item.Insert("Images", New Array()); // Array of Structure
	Item.Insert("OutputByLines", True);
	Item.Insert("XMLElement",        New Structure());
	Item.Insert("NameOfXMLAttribute",    "");
	Return Item; 
	
EndFunction

// Creates and returns a structure containing column data.
//
// Returns:
//  Structure:
//   * Type               - String - template string type: String, Separator, Barcode, XML.
//   * Align      - HorizontalAlign
//   * TitleAlignment - Boolean
//   * WrappingAroundLeft    - Boolean
//   * WrappingAroundRight   - Boolean
//   * Width            - Number - the field width is an absolute value.
//   * WidthFormat      - String - the field width is absolute or percentage.
//   * TitleOutput - Boolean - flag to force header output if the string does not contain a value.
//   * SuppressSpaces  - Boolean
//   * Placeholder       - String - placeholder characters when aligning.
//   * BarcodeType       - String
//   * BarcodeHeight    - Number
//   * Title         - String - field header, a string from the template before the first expression.
//   * Value          - Arbitrary
//   * String            - String - the value converted to a string.
//   * StartPosition  - Number - the position in the row where the first row of the column begins.
//   * InitialWidth   - Number - the initial width of the column.
//   * NewWidth       - Number  - the new column width is used when calculating the flow.
//   * Completed_         - Boolean - the column output is complete, used in the calculation of the flow.
//   * InitialRow   - Number
//
Function NewColumnOfTemplateElement()
	
	Column = New Structure();
	Column.Insert("Type", "STRING");
	// column format
	Align = HorizontalAlign.Left; // HorizontalAlign
	Column.Insert("Align",          Align);
	Column.Insert("TitleAlignment", False);
	Column.Insert("WrappingAroundLeft",        False);
	Column.Insert("WrappingAroundRight",       False);
	Column.Insert("Width",                0);
	Column.Insert("WidthFormat",          "0");
	Column.Insert("TitleOutput",     False);
	Column.Insert("SuppressSpaces",      True);
	Column.Insert("Placeholder",           " ");
	Column.Insert("BarcodeType",           "EAN13");
	Column.Insert("BarcodeHeight",        2);
	Column.Insert("UseBase64",    True);
	// Values
	Column.Insert("Title", "");
	Column.Insert("Value",  Undefined);
	Column.Insert("String",    "");
	// Service Properties
	Column.Insert("StartPosition",  0);
	Column.Insert("InitialWidth",   0);
	Column.Insert("NewWidth",       0);
	Column.Insert("Completed_",         False);
	Column.Insert("InitialRow",   0);
	
	
	Return Column;
	
EndFunction

// Recalculates column sizes to create a flow-around effect.
//
// Parameters:
//  ColumnsArray1 - Array of See NewColumnOfTemplateElement.
//
Procedure RecalculateColumnSizes(ColumnsArray1)
	
	IndexOf = 0;
	While IndexOf<=ColumnsArray1.UBound() Do
		
		Column = ColumnsArray1[IndexOf];
		If Not Column.Completed_ Then
			// wrap around to the left
			If Column.WrappingAroundLeft Then
				IndexOfColumnOnLeft = IndexOf-1;
				While IndexOfColumnOnLeft>=0 Do
					If ColumnsArray1[IndexOfColumnOnLeft].NewWidth = 0 
						And ColumnsArray1[IndexOfColumnOnLeft].Width>0 Then
						Column.Width = Column.Width + ColumnsArray1[IndexOfColumnOnLeft].Width;
						ColumnsArray1[IndexOfColumnOnLeft].Width = 0;
					Else
						Break;
					EndIf;
					IndexOfColumnOnLeft = IndexOfColumnOnLeft - 1;
				EndDo;
				
			EndIf;
			// perform a flow to the right
			If Column.WrappingAroundRight Then
				IndexOfColumnOnRight = IndexOf + 1;
				While IndexOfColumnOnRight <= ColumnsArray1.UBound() Do
					If ColumnsArray1[IndexOfColumnOnRight].NewWidth = 0 
						And ColumnsArray1[IndexOfColumnOnRight].Width>0 Then
						Column.Width = Column.Width + ColumnsArray1[IndexOfColumnOnRight].Width;
						ColumnsArray1[IndexOfColumnOnRight].Width = 0;
					Else
						Break;
					EndIf;
					IndexOfColumnOnRight = IndexOfColumnOnRight + 1;
				EndDo;
				
			EndIf;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

// Aligns the string according to the passed rules, to the specified width.
//
// Parameters:
//  Title - String - the text that will be displayed before the line.
//  String - String - the line you want to align.
//  Align - HorizontalAlign
//  TitleAlignment - Boolean - whether to align the title with the text.
//  LineWidth_ - Number - the width of the line that you want to align the line to.
//  Placeholder - String - characters that will be used as an empty string when filling in.
//
// Returns:
//  String - A string is a string aligned according to the rules.
//
Function AlignLine(Title, String, Align, TitleAlignment, LineWidth_, Placeholder = " ")
	
	IsBlankString = CharacterString(LineWidth_, Placeholder);
	
	If Align = HorizontalAlign.Right And Not TitleAlignment Then // right alignment without title
		Size    = LineWidth_ - StrLen(Title);
		Result = Title + Right(IsBlankString + String, Size);
	ElsIf Align = HorizontalAlign.Right And TitleAlignment Then // alignment to the right along with the title
		Size    = LineWidth_;
		Result = Right(IsBlankString + Title + String, Size);
	ElsIf Align = HorizontalAlign.Left And Not TitleAlignment Then // left alignment without title
		Size    = LineWidth_ - StrLen(Title);
		Result = Title + Left(String + IsBlankString, Size);
	ElsIf Align = HorizontalAlign.Left And TitleAlignment Then // alignment on the left along with the title
		Size    = LineWidth_;
		Result = Left(Title + String + IsBlankString, Size);
	ElsIf Align = HorizontalAlign.Center And Not TitleAlignment Then // center alignment without title
		Size       = LineWidth_ - StrLen(Title);
		LineSize = StrLen(String);
		SizeOnLeft  = Int((Size - LineSize) / 2);
		Result    = Title + Left(Left(IsBlankString, SizeOnLeft) + String + IsBlankString, Size);
	ElsIf Align = HorizontalAlign.Center And TitleAlignment Then // center alignment along with the title
		Size       = LineWidth_;
		LineSize = StrLen(Title + String);
		SizeOnLeft  = Int((Size - LineSize) / 2);
		Result    = Left(Left(IsBlankString, SizeOnLeft) + Title + String + IsBlankString, Size);
	ElsIf Align = HorizontalAlign.Justify And TitleAlignment Then // width alignment along with the header
		Text        = Title + String;
		Size       = LineWidth_;
		LineSize = StrLen(Text);
		Rows = StrSplit(Text, " ", True);
		IndexOf = 0;
		While LineSize<Size Do
			Rows[IndexOf] = Rows[IndexOf]+" ";
			IndexOf = ?(IndexOf < Rows.UBound()-1, IndexOf + 1, 0);
			LineSize = LineSize + 1;
		EndDo;
		Result    = StrConcat(Rows, " ");
	ElsIf Align = HorizontalAlign.Justify And Not TitleAlignment Then // width alignment without header
		Text        = String;
		Size       = LineWidth_;
		LineSize = StrLen(Text);
		Rows = StrSplit(Text, " ", True);
		IndexOf = 0;
		While LineSize<Size Do
			Rows[IndexOf] = Rows[IndexOf]+" ";
			IndexOf = ?(IndexOf < Rows.UBound()-1, IndexOf + 1, 0);
			LineSize = LineSize + 1;
		EndDo;
		Result    = Title + StrConcat(Rows, " ");
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a string cut off by a space, so that it fits in the specified size.
//
// Parameters:
//  Text - String - the line from which you want to cut the words.
//  Size - Number - maximum row size.
//
// Returns:
//  String - a line cut off by a space.
//
Function CutOnLeftAccordingToWords(Text, Size)
	
	NextSpace = StrFind(Text, " ");
	TextLength     = StrLen(Text);
	If NextSpace > Size+1 Then
		// space after the line, cut off by characters
		PositionSpace = Size;
	ElsIf NextSpace = 0 Then
		// there are no spaces, it is cut off either by size or by the entire line
		PositionSpace = Min(Size, TextLength);
	Else
		// There is a gap in the border
		While NextSpace <= Size+1 Do
			PositionSpace   = NextSpace;
			If PositionSpace < TextLength Then
				NextSpace = StrFind(Text, " ", , PositionSpace+1);
			Else
				NextSpace = TextLength;
			EndIf;
			If NextSpace = 0 Then
				If PositionSpace = 0 Then 
					PositionSpace = Size;
				ElsIf Size >= TextLength Then
					PositionSpace = TextLength;
				EndIf;
				Break;
			ElsIf NextSpace = TextLength Then
				PositionSpace = NextSpace;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Result = TrimAll(Left(Text, PositionSpace));
	Text = TrimAll(Mid(Text, PositionSpace+1));
	
	Return Result;
	
EndFunction

// Returns a barcode type code by name for Transferring to barcode generationshtrichcode.
//
// Parameters:
//  BarCodeTypeString - String - text Presentation of the barcode type.
//
// Returns:
//  Number - numerical Presentation of a barcode, for use in barcode generation.
//
Function NumericBarcodeType(BarCodeTypeString)
	
	TypesOfBarcode = New Map();
	TypesOfBarcode.Insert("EAN8", 0);
	TypesOfBarcode.Insert("EAN13", 1);
	TypesOfBarcode.Insert("EAN128", 2);
	TypesOfBarcode.Insert("Code39", 3);
	TypesOfBarcode.Insert("Code128", 4);
	TypesOfBarcode.Insert("Code16k", 5);
	TypesOfBarcode.Insert("PDF417", 6);
	TypesOfBarcode.Insert("Standart (Industrial) 2 of 5", 7);
	TypesOfBarcode.Insert("Interleaved 2 of 5", 8);
	TypesOfBarcode.Insert("Code39", 9);
	TypesOfBarcode.Insert("Code93", 10);
	TypesOfBarcode.Insert("ITF14", 11);
	TypesOfBarcode.Insert("RSS14", 12);
	TypesOfBarcode.Insert("EAN13AddOn2", 14);
	TypesOfBarcode.Insert("EAN13AddOn5", 15);
	TypesOfBarcode.Insert("QR", 16);
	TypesOfBarcode.Insert("GS1DataBarExpandedStacked", 17);
	TypesOfBarcode.Insert("Datamatrix ASCII", 18);
	TypesOfBarcode.Insert("Datamatrix BASE256", 19);
	TypesOfBarcode.Insert("Datamatrix TEXT", 20);
	TypesOfBarcode.Insert("Datamatrix C40", 21);
	TypesOfBarcode.Insert("Datamatrix X12", 22);
	TypesOfBarcode.Insert("Datamatrix EDIFACT", 23);
	TypesOfBarcode.Insert("Datamatrix GS1ASCII", 24);
	
	Result = TypesOfBarcode.Get(BarCodeTypeString);
	
	Return ?(Result = Undefined, 99, Result);
	
EndFunction

#EndRegion

#EndRegion 