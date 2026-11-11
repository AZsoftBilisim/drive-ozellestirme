#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ApplicationForReturnOfGoodsFromClient") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, "ApplicationForReturnOfGoodsFromClient", NStr("vi = 'Giấy đề nghị trả hàng';
																				|ru = 'Заявление на возврат товаров';
																				|en = 'Goods return request'; fa = 'درخواست مرجوعی کالا';
																				|it = 'Domanda di reso delle merci';
																				|pl = 'Oświadczenie zwrotu towarów';
																				|tr = 'Mal iadesi için başvuru'"),
			GeneratePrintedApplicationFormForReturnOfGoodsFromClient(StructureOfTypes, PrintObjects, PrintParameters));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, StructureOfTypes, PrintFormsCollection);
	
EndProcedure

Function GeneratePrintedApplicationFormForReturnOfGoodsFromClient(StructureOfTypes, PrintObjects, PrintParameters) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ApplicationForReturnOfGoodsFromClient";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedReturnApplicationFormFromCustomer(ObjectsStructure.Value);
		
		FillInTabularDocumentApplicationForReturnOfGoodsFromClient(SpreadsheetDocument, DataForPrint, PrintObjects);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument -
//	DataForPrint   - Structure - Contains data on the header of the document, the tabular part:
//		* HeaderResults          - QueryResult -
//		* ResultForTabularPart - QueryResult -
//	PrintObjects     - See PrintManagementOverridable.OnPrint.PrintObjects
//
Procedure FillInTabularDocumentApplicationForReturnOfGoodsFromClient(SpreadsheetDocument, DataForPrint, PrintObjects)
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintApplicationForReturnOfGoodsFromCustomer.PF_MXL_RequestForReturnOfGoods");
	
	PrintData = DataForPrint.HeaderResults.Select();
	Goods       = DataForPrint.ResultForTabularPart.Unload();
	
	FirstDocument = True;
	TheStructureOfTheSearch = New Structure("Ref");
	
	AdditionalColumn = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AddtlColumnName = AdditionalColumn.ColumnName;
	PresentationOfAdditionalColumns = AdditionalColumn.ColumnPresentation;
	OutputCodes = ValueIsFilled(AddtlColumnName);
	
	While PrintData.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		Else
			FirstDocument = False;
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
		// We display the header of the application for a refund
		
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		FillPropertyValues(TemplateArea.Parameters, PrintData);
		
		HeaderDataStructure_1 = New Structure;
		If ValueIsFilled(PrintData.CashRegisterReceiptNumber) Then
			HeaderDataStructure_1.Insert("CashRegisterReceiptNumber", 
				ObjectsPrefixesClientServer.NumberForPrinting(PrintData.CashRegisterReceiptNumber, False, True));
		EndIf;
		
		If GoodsTable.Count() > 1 Then
			HeaderDataStructure_1.Insert("DescriptionOfGoods", NStr("vi = 'hàng hóa';
																	|ru = 'товары';
																	|en = 'goods'; fa = 'goods';
																	|it = 'merci';
																	|pl = 'goods';
																	|tr = 'ürünler'", Common.DefaultLanguageCode()));
		Else
			HeaderDataStructure_1.Insert("DescriptionOfGoods", NStr("vi = 'hàng hóa';
																	|ru = 'товар';
																	|en = 'good'; fa = 'good';
																	|it = 'merce';
																	|pl = 'good';
																	|tr = 'ürün'", Common.DefaultLanguageCode()));
		EndIf;
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(PrintData.Organization, PrintData.Date);
		HeaderDataStructure_1.Insert("Organization", NamesAsOfDate.AbbreviatedDescription);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		NamesOfRegions = NamesOfRegions(OutputCodes);
		
		// We display the header of the returned goods table

		RoomArea   = Template.GetArea(NamesOfRegions.TableHeader + "|" + NamesOfRegions.LineNumber);
		AreaCodes    = Template.GetArea("TableHeader|ColumnOfCodes");
		DataArea   = Template.GetArea(NamesOfRegions.TableHeader + "|" + NamesOfRegions.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		If OutputCodes Then
			StructureAreaCodes = New Structure("NameOfCodeColumn", PresentationOfAdditionalColumns);
			AreaCodes.Parameters.Fill(StructureAreaCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		SpreadsheetDocument.Join(DataArea);
		
		// Output the rows of the returned goods table
		
		StandardRoomArea = Template.GetArea(NamesOfRegions.TableRow + "|" + NamesOfRegions.LineNumber);
		AreaCodesStandard  = Template.GetArea("TableRow|ColumnOfCodes");
		DataAreaStandard = Template.GetArea(NamesOfRegions.TableRow + "|" + NamesOfRegions.Data);
		
		UseSets = False;
		If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			RoomAreaSet    = Template.GetArea(NamesOfRegions.TableRowSet + "|" + NamesOfRegions.LineNumber);
			AreaCodesSet     = Template.GetArea(NamesOfRegions.TableRowSet + "|ColumnOfCodes");
			DataAreaSet    = Template.GetArea(NamesOfRegions.TableRowSet + "|" + NamesOfRegions.Data);
			
			RoomAreaComponents    = Template.GetArea(NamesOfRegions.TableRowComponents + "|" + NamesOfRegions.LineNumber);
			AreaCodesComponents     = Template.GetArea(NamesOfRegions.TableRowComponents + "|ColumnOfCodes");
			DataAreaComponents    = Template.GetArea(NamesOfRegions.TableRowComponents + "|" + NamesOfRegions.Data);
		EndIf;
		
		BlankData   = SetsServer.BlankData();
		
		LineNumber = 0;
		
		For Each SelectingProductLines In GoodsTable Do
			
			If SetsServer.UseSetArea(SelectingProductLines, UseSets) Then
				RoomArea    = RoomAreaSet;
				AreaCodes     = AreaCodesSet;
				DataArea    = DataAreaSet;
			ElsIf SetsServer.UseScope(SelectingProductLines, UseSets) Then
				RoomArea    = RoomAreaComponents;
				AreaCodes     = AreaCodesComponents;
				DataArea    = DataAreaComponents;
			Else
				RoomArea    = StandardRoomArea;
				AreaCodes     = AreaCodesStandard;
				DataArea    = DataAreaStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(SelectingProductLines, UseSets) Then
				SetParameter(RoomArea, "LineNumber", Undefined);
			Else
				LineNumber = LineNumber + 1;
				SetParameter(RoomArea, "LineNumber", LineNumber);
			EndIf;
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				If AddtlColumnName = "SKU" Then
					SKU = SelectingProductLines.SKU;
				Else
					SKU = SelectingProductLines.Code;
				EndIf;
				DataStructureCodes = New Structure("SKU", SKU);
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(SelectingProductLines, UseSets);
			
			If SetsServer.DisplayOnlyTitle(SelectingProductLines, UseSets) Then
				DataArea.Parameters.Fill(BlankData);
			Else
				DataArea.Parameters.Fill(SelectingProductLines);
			EndIf;
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = SelectingProductLines.ThisIsReusablePackage;	
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			GoodsPresentation = PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
					SelectingProductLines.FullNameOfProduct_,
					SelectingProductLines.FullNameOfCharacteristic,
					,
					,
					AdditionalParametersForGettingNameToPrint) + PrefixAndPostfix.Postfix;
			
			DataStructureString = New Structure("OwnGoods", GoodsPresentation);
					
			DataArea.Parameters.Fill(DataStructureString);
			SpreadsheetDocument.Join(DataArea);
			
		EndDo;
		
		// We display the basement of the table of returned goods
		
		RoomArea   = Template.GetArea(NamesOfRegions.TableFooter + "|" + NamesOfRegions.LineNumber);
		AreaCodes    = Template.GetArea("TableFooter|ColumnOfCodes");
		DataArea   = Template.GetArea(NamesOfRegions.TableFooter + "|" + NamesOfRegions.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		SpreadsheetDocument.Join(DataArea);
		
		// We display the basement of the application for a refund
		
		TemplateArea = Template.GetArea("Footer");
		FillPropertyValues(TemplateArea.Parameters, PrintData);
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
EndProcedure

Function NamesOfRegions(OutputCodes)
	
	ReturnStructure = New Structure("TableRow, Data, LineNumber, TableHeader, TableRowSet,
										|TableRowComponents, TableFooter");
	If OutputCodes Then
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.Data = "Data";
		ReturnStructure.LineNumber = "LineNumber";
		ReturnStructure.TableHeader = "TableHeader";
		ReturnStructure.TableRowSet = "TableRowSet";
		ReturnStructure.TableRowComponents = "TableRowComponents";
		ReturnStructure.TableFooter = "TableFooter";
	Else
		ReturnStructure.TableRow = "TableRowWithoutCodes";
		ReturnStructure.Data = "DataWithoutCodes";
		ReturnStructure.LineNumber = "LineNumberWithoutCodes";
		ReturnStructure.TableHeader = "TableHeaderWithoutCodes";
		ReturnStructure.TableRowSet = "TableRowSetWithoutCodes";
		ReturnStructure.TableRowComponents = "TableRowComponentsWithoutCodes";
		ReturnStructure.TableFooter = "BasementTablesWithoutCodes";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

#EndRegion

#EndRegion

#EndIf
