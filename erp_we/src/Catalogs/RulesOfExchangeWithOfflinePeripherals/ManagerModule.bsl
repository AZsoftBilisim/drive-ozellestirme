#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array of String - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("PeripheralType");
	
	Return Result;

EndFunction

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Item code
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "GoodsCodes";
	PrintCommand.Presentation = NStr("vi = 'Mã hàng hóa';
									|ru = 'Коды товаров';
									|en = 'Goods codes'; fa = 'کدهای کالا';
									|it = 'Codici delle merci';
									|pl = 'Kody towarów';
									|tr = 'Ürün kodları'");

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsCodes") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsCodes",
			NStr("vi = 'Mã hàng hóa';
				|ru = 'Коды товаров';
				|en = 'Goods codes'; fa = 'کدهای کالا';
				|it = 'Codici delle merci';
				|pl = 'Kody towarów';
				|tr = 'Ürün kodları'"),
			GeneratePrintedFormProductCodes(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
EndProcedure

Function GeneratePrintedFormProductCodes(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsCodes";
	
	Template = PrintManagement.PrintFormTemplate("Catalog.RulesOfExchangeWithOfflinePeripherals.PF_MXL_GoodsCodes");
	FirstDocument = True;
	
	For Each ArrayObject In ObjectsArray Do
		
		If TypeOf(ArrayObject) = Type("Structure") Then
			Object = ArrayObject.ExchangeRule;
		Else
			Object = ArrayObject;
		EndIf;
		
		OfflinePeripheralsServerCall.UpdateProductCodes(Object);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TemplateArea = Template.GetArea("Title");
		TemplateArea.Parameters.TitleText = NStr("vi = 'Mã hàng hóa';
												|ru = 'Коды товаров';
												|en = 'Goods codes'; fa = 'کدهای کالا';
												|it = 'Codici delle merci';
												|pl = 'Kody towarów';
												|tr = 'Ürün kodları'");
		TemplateArea.Parameters.ExchangeRule  = Object;
		SpreadsheetDocument.Put(TemplateArea);
		
		AreaCode   = Template.GetArea("TableHeader|Code");
		ProductArea = Template.GetArea("TableHeader|OwnGoods");
		SpreadsheetDocument.Put(AreaCode);
		SpreadsheetDocument.Join(ProductArea);
		
		AreaCode   = Template.GetArea("String|Code");
		ProductArea = Template.GetArea("String|OwnGoods");
		
		Goods = OfflinePeripheralsServerCall.DataOfGoodsUnderExchangeRule(Object, Catalogs.TypesOfPrices.EmptyRef(), Catalogs.TypesOfPrices.EmptyRef());
		MaximumCodeOfGoodsSoldByWeight = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight();
		
		For Each TSRow In Goods Do
			
			If ArrayObject.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
				AreaCode.Parameters.Code = TSRow.Code - MaximumCodeOfGoodsSoldByWeight;
			Else
				AreaCode.Parameters.Code = TSRow.Code;
			EndIf;
			SpreadsheetDocument.Put(AreaCode);
			
			If TSRow.Used Then
				ProductArea.Parameters.OwnGoods = TSRow.Description;
			Else
				ProductArea.Parameters.OwnGoods = "";
			EndIf;
			SpreadsheetDocument.Join(ProductArea);
			
		EndDo;
		
		TemplateArea = Template.GetArea("InTotal");
		SpreadsheetDocument.Put(TemplateArea);
		
		// Print signatures.
		TemplateArea = Template.GetArea("Signatures");
		TemplateArea.Parameters.EmployeeResponsible = Users.CurrentUser();
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Object);
	
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion


#EndRegion

#EndIf