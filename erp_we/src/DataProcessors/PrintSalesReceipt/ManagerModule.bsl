#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductReceipt_") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
		PrintFormsCollection,
		"ProductReceipt_",
		NStr("vi = 'Phiếu tính tiền';
			|ru = 'Товарный чек';
			|en = 'Sales receipt'; fa = 'رسید فروش';
			|it = 'Ricevuta di vendita';
			|pl = 'Paragon towarowy';
			|tr = 'Satış makbuzu'"),
		GeneratePrintedFormProductReceipt(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
EndProcedure

Function GeneratePrintedFormProductReceipt(StructureOfTypes, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProductReceipt_";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		If Not (ObjectsStructure.Key = "Document.CashRegisterReceipt"
			Or ObjectsStructure.Key = "Document.RetailSalesReport"
			Or ObjectsStructure.Key = "Document.CashRegisterReceiptReturn"
			Or ObjectsStructure.Key = "Document.RetailReturnsReport") Then
			Continue;
		EndIf;
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedFormProductReceipt(PrintParameters, ObjectsStructure.Value);
		
		FillInTabularDocumentProductReceipt(SpreadsheetDocument, DataForPrint, PrintObjects);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Parameters:
// 	SpreadsheetDocument - SpreadsheetDocument
// 	DataForPrint - Structure:
// 		* HeaderResults - QueryResult
// 		* ResultForTabularPart - QueryResult
// 		* DocumentTitle - String
// 
Procedure FillInTabularDocumentProductReceipt(SpreadsheetDocument, DataForPrint, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ErrorPatternProducts = NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in phiếu hàng hóa';
								|ru = 'В документе %1 отсутствуют товары. Печать товарного чека не требуется';
								|en = 'Goods are missing in document %1. It is not required to print the sales receipt'; fa = 'Goods are missing in document %1. It is not required to print the sales receipt';
								|it = 'Nel documento%1 mancano le merci. La stampa della ricevuta di vendita non è richiesta';
								|pl = 'W dokumencie %1 nie ma towarów. Wydruk paragonu nie jest wymagany';
								|tr = 'Belge %1''de ürün bulunmamaktadır. Satış makbuzunun yazdırılması gerekli değildir'");
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintSalesReceipt.PF_MXL_ProductReceipt_");
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	PrintData = DataForPrint.HeaderResults.Select();
	Goods       = DataForPrint.ResultForTabularPart.Unload();
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
		
		If GoodsTable.Count() = 0 Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorPatternProducts,
				PrintData.Ref);
			
			CommonClientServer.MessageToUser(ErrorText, PrintData.Ref);
			Continue;
			
		EndIf;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice.
		TemplateArea = Template.GetArea("Title");
		PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "TitleLogo", PrintData.Organization);
		
		TemplateArea.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, DataForPrint.DocumentTitle);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		SupplierPresentation = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr,TIN,LegalAddress,Phones");
		TemplateArea.Parameters.SupplierPresentation = SupplierPresentation;
		TemplateArea.Parameters.Vendor = PrintData.Organization;
		SpreadsheetDocument.Put(TemplateArea);
		
		If ValueIsFilled(PrintData.Department) Then
			TemplateArea = Template.GetArea("Department");
			TemplateArea.Parameters.Department = PrintData.Department;
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		ThereAreDiscounts = False;
		ThereIsVAT = False;
		For Each LineProducts_ In GoodsTable Do
			If LineProducts_.DiscountAmount <> 0 Then
				ThereAreDiscounts = True;
			EndIf;
			If LineProducts_.VATAmount <> 0 Then
				ThereIsVAT = True;
			EndIf;
		EndDo;
		
		DiscountHeader = DiscountHeader(GoodsTable, ThereAreDiscounts);
		
		AdditionalColumn = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
		AddtlColumnName = AdditionalColumn.ColumnName;
		PresentationOfAdditionalColumns = AdditionalColumn.ColumnPresentation;
		OutputCodes = ValueIsFilled(AddtlColumnName);
		
		DisplayPremises = False;
		
		FirstRoom = Undefined;
		For Each RowOfProduct In GoodsTable Do
			If ValueIsFilled(RowOfProduct.Premise) Then
				DisplayPremises = True;
			EndIf;
		EndDo;
		
		RoomArea    = Template.GetArea("TableHeader|LineNumber");
		AreaCodes     = Template.GetArea("TableHeader|ColumnOfCodes");
		AreaRoom = Template.GetArea("TableHeader|Premise");
		DataArea    = Template.GetArea("TableHeader|Data");
		DiscountArea    = Template.GetArea("TableHeader|Discount");
		ScopeOfVATAmount  = Template.GetArea("TableHeader|VATAmount");
		SumArea     = Template.GetArea("TableHeader|Sum");
		
		SpreadsheetDocument.Put(RoomArea);
		If DisplayPremises Then
			SpreadsheetDocument.Join(AreaRoom);
		EndIf;
		If OutputCodes Then
			AreaCodes.Parameters.NameOfCodeColumn = PresentationOfAdditionalColumns;
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		SpreadsheetDocument.Join(DataArea);
		If ThereAreDiscounts Then
			DiscountArea.Parameters.Discount = DiscountHeader.Discount;
			DiscountArea.Parameters.AmountWithoutADiscount = DiscountHeader.DiscountAmount;
			SpreadsheetDocument.Join(DiscountArea);
		EndIf;
		If ThereIsVAT And ShowVAT Then
			SpreadsheetDocument.Join(ScopeOfVATAmount);
		EndIf;
		
		SpreadsheetDocument.Join(SumArea);
		
		ProductColumnArea = Template.Area("OwnGoods");
		If Not OutputCodes Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
			                                  + Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf;
		If DisplayPremises Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
			                                  + Template.Area("Premise").ColumnWidth;
		EndIf;
		If Not ThereAreDiscounts Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
			                                  + Template.Area("AmountWithoutADiscount").ColumnWidth
			                                  + Template.Area("DiscountAmount").ColumnWidth;
		EndIf;
		
		StandardRoomArea    = Template.GetArea("String|LineNumber");
		AreaCodesStandard     = Template.GetArea("String|ColumnOfCodes");
		ScopeOfApplicationStandard = Template.GetArea("String|Premise");
		DataAreaStandard    = Template.GetArea("String|Data");
		DiscountAreaStandard    = Template.GetArea("String|Discount");
		ScopeOfVATAmountStandard  = Template.GetArea("String|VATAmount");
		AmountAreaIsStandard     = Template.GetArea("String|Sum");
		
		UseSets = False;
		If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			RoomAreaSet    = Template.GetArea("StringSet" + "|LineNumber");
			AreaCodesSet     = Template.GetArea("StringSet" + "|ColumnOfCodes");
			AreaRoomSet = Template.GetArea("StringSet" + "|Premise");
			DataAreaSet    = Template.GetArea("StringSet" + "|Data");
			DiscountAreaSet    = Template.GetArea("StringSet" + "|Discount");
			ScopeOfVATAmountSet  = Template.GetArea("StringSet" + "|VATAmount");
			SumAreaSet     = Template.GetArea("StringSet" + "|Sum");
			
			RoomAreaComponents    = Template.GetArea("StringComponents" + "|LineNumber");
			AreaCodesComponents     = Template.GetArea("StringComponents" + "|ColumnOfCodes");
			AreaRoomComponents = Template.GetArea("StringComponents" + "|Premise");
			DataAreaComponents    = Template.GetArea("StringComponents" + "|Data");
			DiscountAreaComponents    = Template.GetArea("StringComponents" + "|Discount");
			ScopeOfVATAmountComponents  = Template.GetArea("StringComponents" + "|VATAmount");
			SumAreaComponents     = Template.GetArea("StringComponents" + "|Sum");
			
		EndIf;
		
		Sum          = 0;
		VATAmount       = 0;
		TotalOfDiscounts    = 0;
		TotalWithoutDiscounts = 0;
		LineNumber    = 0;
		BlankData   = SetsServer.BlankData();
		
		For Each LineProducts_ In GoodsTable Do
			
			If SetsServer.UseSetArea(LineProducts_, UseSets) Then
				RoomArea    = RoomAreaSet;
				AreaCodes     = AreaCodesSet;
				AreaRoom = AreaRoomSet;
				DataArea    = DataAreaSet;
				DiscountArea    = DiscountAreaSet;
				ScopeOfVATAmount  = ScopeOfVATAmountSet;
				SumArea     = SumAreaSet;
			ElsIf SetsServer.UseScope(LineProducts_, UseSets) Then
				RoomArea    = RoomAreaComponents;
				AreaCodes     = AreaCodesComponents;
				AreaRoom = AreaRoomComponents;
				DataArea    = DataAreaComponents;
				DiscountArea    = DiscountAreaComponents;
				ScopeOfVATAmount  = ScopeOfVATAmountComponents;
				SumArea     = SumAreaComponents;
			Else
				RoomArea    = StandardRoomArea;
				AreaCodes     = AreaCodesStandard;
				AreaRoom = ScopeOfApplicationStandard;
				DataArea    = DataAreaStandard;
				DiscountArea    = DiscountAreaStandard;
				ScopeOfVATAmount  = ScopeOfVATAmountStandard;
				SumArea     = AmountAreaIsStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
				SetParameter(RoomArea, "LineNumber", Undefined);
			Else
				LineNumber = LineNumber + 1;
				SetParameter(RoomArea, "LineNumber", LineNumber);
			EndIf;
			SpreadsheetDocument.Put(RoomArea);
			
			If DisplayPremises Then
				AreaRoom.Parameters.Fill(LineProducts_);
				SpreadsheetDocument.Join(AreaRoom);
			EndIf;
			
			If OutputCodes Then
				If AddtlColumnName = "SKU" Then
					SetParameter(AreaCodes, "SKU", LineProducts_.SKU);
				Else
					SetParameter(AreaCodes, "SKU", LineProducts_.Code);
				EndIf;
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
				DataArea.Parameters.Fill(BlankData);
			Else
				DataArea.Parameters.Fill(LineProducts_);
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(LineProducts_, UseSets);
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			SetParameter(DataArea, "OwnGoods", PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
				LineProducts_.FullNameOfProduct_,
				LineProducts_.FullNameOfCharacteristic,
				,
				,
				AdditionalParametersProductPresentation) + PrefixAndPostfix.Postfix);
			
			SpreadsheetDocument.Join(DataArea);
			
			If ThereAreDiscounts Then
				
				If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
					DiscountArea.Parameters.Fill(BlankData);
				Else
					SetParameter(DiscountArea, "Discount",         ?(DiscountHeader.OnlyMarkUp,-LineProducts_.DiscountAmount, LineProducts_.DiscountAmount));
					SetParameter(DiscountArea, "AmountWithoutADiscount", LineProducts_.Sum + LineProducts_.DiscountAmount);
				EndIf;
				
				SpreadsheetDocument.Join(DiscountArea);
				
			EndIf;
			
			If ThereIsVAT And ShowVAT Then
				
				If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
					ScopeOfVATAmount.Parameters.Fill(BlankData);
				Else
					ScopeOfVATAmount.Parameters.Fill(LineProducts_);
				EndIf;
				
				SpreadsheetDocument.Join(ScopeOfVATAmount);
			EndIf;
			
			If Not PrintData.PriceIncludesVAT Then
				AmountIncludingVAT = LineProducts_.Sum + LineProducts_.VATAmount;
			Else
				AmountIncludingVAT = LineProducts_.Sum;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
				SumArea.Parameters.Fill(BlankData);
			Else
				SetParameter(SumArea, "Sum", AmountIncludingVAT);
			EndIf;
			
			SpreadsheetDocument.Join(SumArea);
			
			If Not SetsServer.UseScope(LineProducts_, UseSets) Then
				Sum    = Sum    + LineProducts_.Sum;
				VATAmount = VATAmount + LineProducts_.VATAmount;
				
				If ThereAreDiscounts Then
					TotalOfDiscounts    = TotalOfDiscounts    + LineProducts_.DiscountAmount;
					TotalWithoutDiscounts = TotalWithoutDiscounts + LineProducts_.Sum + LineProducts_.DiscountAmount;
				EndIf;
			EndIf;
			
		EndDo;
		
		// Output the Total.
		RoomArea    = Template.GetArea("InTotal|LineNumber");
		AreaCodes     = Template.GetArea("InTotal|ColumnOfCodes");
		AreaRoom = Template.GetArea("InTotal|Premise");
		DataArea    = Template.GetArea("InTotal|Data");
		DiscountArea    = Template.GetArea("InTotal|Discount");
		SumArea     = Template.GetArea("InTotal|Sum");
		ScopeOfVATAmount  = Template.GetArea("InTotal|VATAmount");
		
		SpreadsheetDocument.Put(RoomArea);
		If DisplayPremises Then
			SpreadsheetDocument.Join(AreaRoom);
		EndIf;
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		SpreadsheetDocument.Join(DataArea);
		If ThereAreDiscounts Then
			DiscountArea.Parameters.TotalOfDiscounts    = ?(DiscountHeader.OnlyMarkUp,-TotalOfDiscounts, TotalOfDiscounts);
			DiscountArea.Parameters.TotalWithoutDiscounts = TotalWithoutDiscounts;
			SpreadsheetDocument.Join(DiscountArea);
		EndIf;
		
		If ThereIsVAT And ShowVAT Then
			ScopeOfVATAmount.Parameters.VATAmount = VATAmount;
			SpreadsheetDocument.Join(ScopeOfVATAmount);
		EndIf;
		
		If Not PrintData.PriceIncludesVAT Then
			DocumentAmount = Sum + VATAmount;
		Else
			DocumentAmount = Sum;
		EndIf;
		
		SumArea.Parameters.Sum = DocumentAmount;
		SpreadsheetDocument.Join(SumArea);
		
		// Withdraw the Amount in words.
		TemplateArea = Template.GetArea("AmountInWords");
		
		TotalString = NStr("vi = 'Tổng số %1, thành tiền %2';
							|ru = 'Всего наименований %1, на сумму %2';
							|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
							|it = 'Totale articoli %1, per importo di %2';
							|pl = 'Razem pozycji %1, na kwotę %2';
							|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode());
		TemplateArea.Parameters.TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			TotalString,
			LineNumber,
			PrintFormGeneration.SumFormat(PrintData.DocumentAmount));
		
		TemplateArea.Parameters.AmountInWords  = ProcessingOfExchangeRatesTM.GenerateAmountInWords(PrintData.DocumentAmount, PrintData.Currency);
		SpreadsheetDocument.Put(TemplateArea);
	
		// Print signatures.
		TemplateArea = Template.GetArea("Signatures");
		TemplateArea.Parameters.Fill(PrintData);
		TemplateArea.Parameters.EmployeeResponsiblePresentation = PersonsTM.IndividualShortName(PrintData.EmployeeResponsible, PrintData.Date);

		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
EndProcedure // Fill in the table of the Document card()

// The function returns a structure with the Discount or mark-Up headers for the print form table,
// as well as the have Discounts and only mark-Up flags.
//
// Returns:
// 	Structure - 
Function DiscountHeader(GoodsTable, UseDiscounts) Export
	
	ThereAreMargins = False;
	ThereAreDiscounts  = False;
	
	HeaderStructure_ = New Structure("Discount, DiscountAmount, OnlyMarkUp");
	
	If UseDiscounts Then
		
		For Each LineProducts_ In GoodsTable Do
			If LineProducts_.DiscountAmount > 0 Then
				ThereAreDiscounts = True;
				Break;
			EndIf;
		EndDo;
		
		For Each LineProducts_ In GoodsTable Do
			If LineProducts_.DiscountAmount < 0 Then
				ThereAreMargins = True;
				Break;
			EndIf;
		EndDo;
		
		If ThereAreMargins And ThereAreDiscounts Then
			HeaderStructure_.Insert("Discount", NStr("vi = 'Chiết khấu (Phụ thu)';
													|ru = 'Скидка (Наценка)';
													|en = 'Discount (markup)'; fa = 'تخفیف (افزایش قیمت)';
													|it = 'Sconto (sovrapprezzo)';
													|pl = 'Rabat (marża)';
													|tr = 'İndirim (zam)'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("DiscountAmount", NStr("vi = 'Tổng số';
															|ru = 'Сумма';
															|en = 'Amount'; fa = 'مبلغ';
															|it = 'Importo';
															|pl = 'Wartość';
															|tr = 'Tutar'", Common.DefaultLanguageCode()) + Chars.LF + NStr("vi = 'không có chiết khấu (phụ thu)';
																															|ru = 'без скидки (наценки)';
																															|en = 'without discount (markups)'; fa = 'without discount (markups)';
																															|it = 'senza sconto (sovrapprezzo)';
																															|pl = 'bez zniżek (dopłata)';
																															|tr = 'indirim/zam olmadan'", Common.DefaultLanguageCode()));
		ElsIf ThereAreMargins And Not ThereAreDiscounts Then
			HeaderStructure_.Insert("Discount", NStr("vi = 'Phụ thu';
													|ru = 'Наценка';
													|en = 'Markup'; fa = 'افزایش قیمت';
													|it = 'Sovrapprezzo';
													|pl = 'Marża';
													|tr = 'Marj'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("DiscountAmount", NStr("vi = 'Tổng số';
															|ru = 'Сумма';
															|en = 'Amount'; fa = 'مبلغ';
															|it = 'Importo';
															|pl = 'Wartość';
															|tr = 'Tutar'", Common.DefaultLanguageCode()) + Chars.LF + NStr("vi = 'không có phụ thu';
																															|ru = 'без наценки';
																															|en = 'without markup'; fa = 'without markup';
																															|it = 'senza sovrapprezzo';
																															|pl = 'bez dodatkowych opłat';
																															|tr = 'zam olmadan'", Common.DefaultLanguageCode()));
		ElsIf ThereAreDiscounts Then
			HeaderStructure_.Insert("Discount", NStr("vi = 'Chiết khấu';
													|ru = 'Скидка';
													|en = 'Discount'; fa = 'تخفیف';
													|it = 'Sconto';
													|pl = 'Rabat';
													|tr = 'İndirim'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("DiscountAmount", NStr("vi = 'Tổng số';
															|ru = 'Сумма';
															|en = 'Amount'; fa = 'مبلغ';
															|it = 'Importo';
															|pl = 'Wartość';
															|tr = 'Tutar'", Common.DefaultLanguageCode()) + Chars.LF + NStr("vi = 'không có chiết khấu';
																															|ru = 'без скидки';
																															|en = 'without discount'; fa = 'without discount';
																															|it = 'senza sconto';
																															|pl = 'bez zniżek';
																															|tr = 'indirim olmadan'", Common.DefaultLanguageCode()));
		EndIf;
		
		HeaderStructure_.Insert("OnlyMarkUp", (ThereAreMargins And Not ThereAreDiscounts));
		
	EndIf;
	
	Return HeaderStructure_;
	
EndFunction

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

#EndRegion

#EndRegion

#EndIf
