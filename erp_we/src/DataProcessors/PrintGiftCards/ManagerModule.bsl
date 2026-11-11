#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GiftCertificate") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GiftCertificate",
			NStr("vi = 'Phiếu quà tặng';
				|ru = 'Подарочный сертификат';
				|en = 'Gift card'; fa = 'کارت هدیه';
				|it = 'Buono regalo';
				|pl = 'Certyfikat podarunkowy';
				|tr = 'Hediye kartı'"),
			CreatePrintedFormOfGiftCertificate(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
EndProcedure

Function CreatePrintedFormOfGiftCertificate(StructureOfTypes, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GiftCertificate";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		If Not (ObjectsStructure.Key = "Document.GiftCertificateSale"
			Or ObjectsStructure.Key = "Catalog.GiftCertificates") Then
			Continue;
		EndIf;
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedGiftCertificateForm(PrintParameters, ObjectsStructure.Value);
		
		FillOutTabularDocumentGiftCertificate(SpreadsheetDocument, DataForPrint, PrintObjects);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure FillOutTabularDocumentGiftCertificate(SpreadsheetDocument, DataForPrint, PrintObjects)
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintGiftCards.PF_MXL_GiftCertificate");
	
	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	DrawingSquare = Etalon.Drawings.Square100Pixels; // SpreadsheetDocumentDrawing
	NumberOfMillimetersPerPixel = DrawingSquare.Height / 100;
	
	FirstDocument = True;
	
	QueryResult = DataForPrint.QueryResult; // QueryResult
	Selection = QueryResult.Select(); 
	While Selection.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice.
		TemplateArea = Template.GetArea("GiftCertificate");
		FillPropertyValues(TemplateArea.Parameters, Selection);
		
		If TMCommonUseClientServer.HasObjectAttribute(TemplateArea.Drawings, "BarcodeIcon") Then
			
			If ValueIsFilled(Selection.Barcode) And StrLen(Selection.Barcode) = 13 Then
				
				BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
				BarcodeParameters.Insert("Width",           Round(TemplateArea.Drawings.BarcodeIcon.Width / NumberOfMillimetersPerPixel));
				BarcodeParameters.Insert("Height",           Round(TemplateArea.Drawings.BarcodeIcon.Height / NumberOfMillimetersPerPixel));
				BarcodeParameters.Insert("Barcode",         Selection.Barcode);
				BarcodeParameters.Insert("InputDataType", 0); // A barcode is a string
				BarcodeParameters.Insert("CodeType",          1); // EAN13
				BarcodeParameters.Insert("TextVisible",  True);
				BarcodeParameters.Insert("FontSize",     8);
				
				TemplateArea.Drawings.BarcodeIcon.Picture = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
				
			Else
				TemplateArea.Drawings.Delete(TemplateArea.Drawings.BarcodeIcon);
			EndIf;
			
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Selection.Ref);
		
	EndDo;
	
EndProcedure // Fill in the table of the Document card()

#EndRegion

#EndRegion

#EndIf
