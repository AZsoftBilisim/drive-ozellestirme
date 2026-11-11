
#Region Public

// Returns the numeric code for printing the barcode
//
//	Parameters:
//		Ref - AnyRef - the reference to the object that you want to get the code
//	Returns:
//		String - a string of numbers corresponding to the passed link.
//
Function NumericCodeFromLink(Ref) Export
	HexadecimalNumber = StrReplace(String(Ref.UUID()),"-","");
	Return ConvertFromHexadecimalToDecimal(HexadecimalNumber);
EndFunction

// Retrieves the link ID from a numeric code read from the barcode of a tabular document.
//
// Parameters:
//  Barcode - String - the read barcode of the tabular document.
//  ToAddLine - Boolean - indicates whether the barcode string needs to be padded with zeros.
// 
// Returns:
//  - Undefined - The barcode entered is not a numeric link code.
//  - String - ID of the link from the numeric code.
//
Function IdFromBarcodeOfTabularDocument(Barcode, ToAddLine = True) Export
	
	If Not StringFunctionsClientServer.OnlyNumbersInString(Barcode, False, False)
			Or TrimAll(Barcode) = "" Then
		Return Undefined;
	EndIf;
	
	IdLengthWithoutDelimiters = 32;
	LengthOfIdentifierWithSeparator = 36;
	
	BarcodeInHexadecimal = ConvertDecimalToHexadecimalNotation(Number(Barcode));
	
	If ToAddLine Then
		BarcodeInHexadecimal = StringFunctionsClientServer.SupplementString(
			BarcodeInHexadecimal, IdLengthWithoutDelimiters);
		
	ElsIf StrLen(BarcodeInHexadecimal) <> IdLengthWithoutDelimiters Then
		Return Undefined;
	EndIf;
	
	Id = StrTemplate(
		"%1-%2-%3-%4-%5",
		Mid(BarcodeInHexadecimal, 1, 8),
		Mid(BarcodeInHexadecimal, 9, 4),
		Mid(BarcodeInHexadecimal, 13, 4),
		Mid(BarcodeInHexadecimal, 17, 4),
		Mid(BarcodeInHexadecimal, 21, 12));
	
	If StrLen(Id) <> LengthOfIdentifierWithSeparator Then
		Return Undefined;
	EndIf;
	
	Return Id;
	
EndFunction

// Function-Get a link based on the barcode of a table document
//
// Parameters:
//  Barcode - String - Barcode
//  Managers - Array of CatalogRef, DocumentRef, TaskRef - Document managers.
// 
// Returns:
//  Array - Links to documents
//
Function GetLinkFromBarcodeOfTabularDocument(Barcode, Managers = Undefined) Export
	
	Id = IdFromBarcodeOfTabularDocument(Barcode);
	
	If Id = Undefined Then
		Return New Array;
	EndIf;
	
	If Managers = Undefined Then
		ObjectsManagers = New Array();
		For Each MetadataItem In Metadata.Documents Do
			ObjectsManagers.Add(Documents[MetadataItem.Name]);
		EndDo;
	Else
		ObjectsManagers = New Array();
		For Each EmptyRef In Managers Do
			
			RefType = TypeOf(EmptyRef);
			
			If Documents.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Documents[EmptyRef.Metadata().Name]);
				
			ElsIf Catalogs.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Catalogs[EmptyRef.Metadata().Name]);
				
			ElsIf Tasks.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(Tasks[EmptyRef.Metadata().Name]);
				
			ElsIf BusinessProcesses.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(BusinessProcesses[EmptyRef.Metadata().Name]);
				
			ElsIf ChartsOfCharacteristicTypes.AllRefsType(RefType).ContainsType(RefType) Then
				ObjectsManagers.Add(ChartsOfCharacteristicTypes[EmptyRef.Metadata().Name]);
				
			Else
				ExceptionText = NStr("vi = 'Lỗi tiếp nhận mã vạch: không hỗ trợ kiểu ""%Type%"".';
									|ru = 'Ошибка распознавания штрихкода: тип ""%Type%"" не поддерживается.';
									|en = 'Barcode recognition error: type ""%Type%"" is not supported.'; fa = 'Barcode recognition error: type ""%Type%"" is not supported.';
									|it = 'Errore di riconoscimento del codice a barre: il tipo ""%Type%"" non è supportato.';
									|pl = 'Błąd rozpoznawania kodu kreskowego: typ ""%Type%"" nie jest obsługiwany.';
									|tr = 'Barkod tanıma hatası: ""%Type%"" türü desteklenmiyor.'");
				ExceptionText = StrReplace(ExceptionText,"%Type%",RefType);
				
				Raise ExceptionText;
			EndIf;
			
		EndDo;
	EndIf;
	
	Query = New Query;
	
	ReferencesArrray = New Array;
	FirstQuery = True;
	For Each Manager In ObjectsManagers Do
		
		Try
			Ref = Manager.GetRef(New UUID(Id));
		Except
			Continue;
		EndTry;
		
		RefMetadata = Ref.Metadata();
		If Not AccessRight("Read", RefMetadata) Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Ref);
		
		If FirstQuery Then
			Query.Text = Query.Text +
			"SELECT ALLOWED Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		Else	
			Query.Text = Query.Text + 
			"UNION ALL
			|
			|SELECT Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		EndIf;

		Query.Text = StrReplace(Query.Text, "&TheMetadataLinksToTheFullName", RefMetadata.FullName());
		FirstQuery = False;
		
	EndDo;
	
	If Not FirstQuery Then
		Query.Parameters.Insert("ReferencesArrray", ReferencesArrray);
		Return Query.Execute().Unload().UnloadColumn("Ref");
	Else
		Return New Array;
	EndIf;
	
EndFunction

// Output the barcode to a table document
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - Table document
//  Template - SpreadsheetDocument
//  TemplateArea - SpreadsheetDocumentRange - Area
//  Ref - AnyRef - Link to the document from which the barcode will be calculated.
//
Procedure OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Val TemplateArea, Ref) Export
	
	SetPrivilegedMode(True);
	
	DisplayBarcodeInSeparateArea = False;
	If Not ThereIsBarcodePictureInTemplateArea(TemplateArea) Then
		// There is no barcode image in this area of the layout.
		
		If Template.Areas.Find("BarcodeArea_") <> Undefined Then
			
			// Check the barcode image in the Barcode area
			BarcodeTemplateArea = Template.GetArea("BarcodeArea_");
			If ThereIsBarcodePictureInTemplateArea(BarcodeTemplateArea) Then
				TemplateArea = BarcodeTemplateArea;
				DisplayBarcodeInSeparateArea = True;
			Else
				Return;
			EndIf;
		Else
			Return;
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("UseBarcodingOfObjectPrintForms") Then
		TemplateArea.Drawings.Delete(TemplateArea.Drawings.BarcodeIcon);
		Return;
	EndIf;
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	DrawingSquare = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = DrawingSquare.Height / 100;
	
	BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
	BarcodeParameters.Width           = Round(TemplateArea.Drawings.BarcodeIcon.Width / NumberOfMillimetersPerPixel);
	BarcodeParameters.Height           = Round(TemplateArea.Drawings.BarcodeIcon.Height / NumberOfMillimetersPerPixel);
	BarcodeParameters.Barcode         = TrimAll(NumericCodeFromLink(Ref));
	BarcodeParameters.InputDataType = 0; // A barcode is a string
	BarcodeParameters.CodeType          = 4; // Code128
	BarcodeParameters.TextVisible  = False;
	BarcodeParameters.FontSize     = 6;
	BarcodeParameters.Zoomable   = True;
	
	TemplateArea.Drawings.BarcodeIcon.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
	
	If DisplayBarcodeInSeparateArea Then
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ConvertDecimalToHexadecimalNotation(Val Decimal)
	
	Result = "";
	
	While Decimal > 0 Do
		Remainder = Decimal % 16;
		Decimal  = (Decimal - Remainder) / 16;
		Result        = Mid("0123456789abcdef", Remainder + 1, 1) + Result;
	EndDo;
	
	Return Result;
	
EndFunction

Function ConvertFromHexadecimalToDecimal(Val Value)
	
	Value = Lower(Value);
	StringLength = StrLen(Value);
	
	Result = 0;
	For CharacterNumber = 1 To StringLength Do
		Result = Result * 16 + StrFind("0123456789abcdef", Mid(Value, CharacterNumber, 1)) - 1;
	EndDo;
	
	Return Format(Result, "NG=0");
	
EndFunction

Function ThereIsBarcodePictureInTemplateArea(TemplateArea)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("BarcodeIcon", New UUID);
	PreviousValue2 = TheStructureOfTheSearch.BarcodeIcon;
	
	FillPropertyValues(TheStructureOfTheSearch, TemplateArea.Drawings);
	
	Return Not TheStructureOfTheSearch.BarcodeIcon = PreviousValue2;
	
EndFunction

#EndRegion
