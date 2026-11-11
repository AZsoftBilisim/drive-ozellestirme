#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ConsignmentReportFromCustomer") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ConsignmentReportFromCustomer",
			NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
				|ru = 'Отчет комиссионера';
				|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
				|it = 'Report del commissionario';
				|pl = 'Raport komisanta';
				|tr = 'Konsinye raporu'"),
			GeneratePrintedReportOnCommission(StructureOfTypes, PrintObjects, PrintParameters));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CommissionAgentSReportWriteOff") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CommissionAgentSReportWriteOff",
			NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
				|ru = 'Отчет комиссионера';
				|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
				|it = 'Report del commissionario';
				|pl = 'Raport komisanta';
				|tr = 'Konsinye raporu'"),
			GeneratePrintedReportOnCommissionWriteOff(StructureOfTypes, PrintObjects, PrintParameters));
		
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PurchasingReportToConsignorPrincipal") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PurchasingReportToConsignorPrincipal",
			NStr("vi = 'Báo cáo đấu thầu';
				|ru = 'Отчет комитенту о закупках';
				|en = 'Purchase notification'; fa = 'اعلان خرید';
				|it = 'Report sugli acquisti al committente';
				|pl = 'Raport do komisanta o zakupach';
				|tr = 'Satın alma bildirimi'"),
			CreatePrintedFormForPurchaseReport(StructureOfTypes, PrintObjects, PrintParameters));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, StructureOfTypes, PrintFormsCollection);
	
EndProcedure

#Region Print_CommissionReport

Function GeneratePrintedReportOnCommission(StructureOfTypes, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_ReportOnCommission";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		If ObjectsStructure.Key = "Document.WriteOffReportFromCommissionAgent"
			Or ObjectsStructure.Key = "Document.PurchaseInvoiceConsignmentStockLost"
			Or ObjectsStructure.Key = "Document.PurchasingReportToConsignorPrincipal" Then
			
			Continue;
			
		EndIf;
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedCommissionReportForm(PrintParameters,
																						ObjectsStructure.Value);
		
		FillInTabularDocumentSalesCommissionReport(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects);
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GeneratePrintedReportOnCommissionWriteOff(StructureOfTypes, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_ReportOnCommissionWriteOff";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		If ObjectsStructure.Key = "Document.ConsignmentReportFromCustomer"
			Or ObjectsStructure.Key = "Document.ConsignmentReportToVendor"
			Or ObjectsStructure.Key = "Document.PurchasingReportToConsignorPrincipal" Then
			
			Continue;
			
		EndIf;
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedFormCommissionReportOnDebiting(PrintParameters,
																								ObjectsStructure.Value);
		
		FillInTabularDocumentCommissionReportOnWriteOff(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects);
		EndDo;
		
	Return SpreadsheetDocument;
	
EndFunction

Procedure FillInDetailsOfCommissionReportHeader(PrintData, Title, Template, SpreadsheetDocument)
	
	// We output the general details of the header
	InformationAboutCommittee		= PrintFormGeneration.InformationAboutLegalEntity(PrintData.Consignor, PrintData.Date);
	InformationAboutCommissionAgent	= PrintFormGeneration.InformationAboutLegalEntity(PrintData.Consignee, PrintData.Date);
	
	TemplateArea = Template.GetArea("Header");
	TemplateArea.Parameters.Fill(PrintData);
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
																	Template,
																	TemplateArea,
																	PrintData.Ref);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert(
		"TitleText",
		TMCommonUseClientServer.GenerateDocumentTitle(PrintData, Title));
	ParametersStructure.Insert(
		"PresentationOfCommittee",
		PrintFormGeneration.OrganizationDescription(InformationAboutCommittee, "FullDescr,"));
	ParametersStructure.Insert(
		"PresentationOfCommissionAgent",
		PrintFormGeneration.OrganizationDescription(InformationAboutCommissionAgent, "FullDescr,"));
	
	TemplateArea.Parameters.Fill(ParametersStructure);
	
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

// Parameters:
//	PrintData        - QueryResultSelection -
//	SelectionByDocuments - QueryResultSelection -
//	Template               - SpreadsheetDocument - Layout of the printed form
//	SpreadsheetDocument   - SpreadsheetDocument -
//	ThereIsRNPT            - Boolean -
//
Procedure FillInDetailsOfBasementReportOnCommission(PrintData,
													SelectionByDocuments,
													Template,
													SpreadsheetDocument,
													ThereIsRNPT)
	
	If ThereIsRNPT Then
		TemplateArea = Template.GetArea("RNPTBasement");
	Else
		TemplateArea = Template.GetArea("Footer");
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TotalCommiteeAmount",			SelectionByDocuments.ConsignorAmount);
	ParametersStructure.Insert("TotalSalesAmount_",			SelectionByDocuments.SalesAmount);
	ParametersStructure.Insert("TotalRemunerationAmount",	SelectionByDocuments.CommissionAmount);
	
	If SelectionByDocuments.SalesAmount < 0 Then
		TextSummaryLine = NStr("vi = 'Tổng số trả lại tên';
								|ru = 'Всего возвращено наименований';
								|en = 'All returned items'; fa = 'All returned items';
								|it = 'Totale restituito titoli';
								|pl = 'Razem zwrócono nazw';
								|tr = 'Toplam iade edilen tanım'", Common.DefaultLanguageCode());
	Else
		TextSummaryLine = NStr("vi = 'Tổng số đã bán, tên';
								|ru = 'Всего продано наименований';
								|en = 'All sold items'; fa = 'All sold items';
								|it = 'Totale venduto titoli';
								|pl = 'Razem sprzedano nazw';
								|tr = 'Toplam satılan tanım'", Common.DefaultLanguageCode());
	EndIf;
	
	ParametersStructure.Insert(
		"TotalString",
		TextSummaryLine + " " + SelectionByDocuments.Select().Count()
		+ ", " + NStr("vi = 'với số tiền';
						|ru = 'на сумму';
						|en = 'in the amount of'; fa = 'به مبلغ';
						|it = 'per l''importo di';
						|pl = 'na kwotę';
						|tr = 'tutarında'", Common.DefaultLanguageCode()) + " "
		+ PrintFormGeneration.SumFormat(SelectionByDocuments.SalesAmount, PrintData.Currency));
	
	ParametersStructure.Insert(
		"AmountInWords",
		ProcessingOfExchangeRatesTM.GenerateAmountInWords(SelectionByDocuments.SalesAmount, PrintData.Currency));
	
	If PrintData.CommissionAmount <> 0 Then
		ParametersStructure.Insert(
			"CommissionAmount",
			NStr("vi = 'Số tiền hoa hồng ký gửi là';
				|ru = 'Сумма комиссионного вознаграждения составила';
				|en = 'Commission equals'; fa = 'Commission equals';
				|it = 'Importo della provvigione è di';
				|pl = 'Wysokość wynagrodzenia prowizyjnego wyniosła';
				|tr = 'Komisyon miktarı şu şekildedir'", Common.DefaultLanguageCode()) + " "
			+ ?(PrintData.CommissionAmount < 0, NStr("vi = 'trừ';
													|ru = 'минус';
													|en = 'minus'; fa = 'minus';
													|it = 'meno';
													|pl = 'minus';
													|tr = 'eksi'", Common.DefaultLanguageCode()) + " ", "")
			+ ProcessingOfExchangeRatesTM.GenerateAmountInWords(PrintData.CommissionAmount, PrintData.Currency));
	EndIf;
	
	ParametersStructure.Insert(
		"CommitteeRepresentative",
		PersonsTM.IndividualShortName(PrintData.CommitteeRepresentative, PrintData.Date));
	
	ParametersStructure.Insert(
		"RepresentativeOfCommissionAgent",
		PersonsTM.IndividualShortName(PrintData.RepresentativeOfCommissionAgent, PrintData.Date));
	
	TemplateArea.Parameters.Fill(ParametersStructure);
	
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Function AreasOfRowsFilledByParameters(LineNumber,
											LineProducts_,
											TraceableComponents,
											Template,
											NameOfCodeColumn,
											ThereIsRNPT)
	
	AreasToOutput = New Array;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ProductItemName = ProductsClientServer.PresentationOfProductsForPrinting(
							LineProducts_.ProductItemName,
							String(LineProducts_.Characteristic),
							,
							,
							AdditionalParametersProductPresentation);
	
	ConsignorPrice	= ?(LineProducts_.Count = 0, 0, Round(LineProducts_.ConsignorAmount / LineProducts_.Count, 2, 1));
	SellingPrice		= ?(LineProducts_.Count = 0, 0, Round(LineProducts_.SalesAmount / LineProducts_.Count, 2, 1));
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("LineNumber",			LineNumber);
	ParametersStructure.Insert("ProductItemName",	ProductItemName);
	ParametersStructure.Insert("ConsignorPrice",		ConsignorPrice);
	ParametersStructure.Insert("SellingPrice",			SellingPrice);
	
	If ValueIsFilled(NameOfCodeColumn) Then
		ParametersStructure.Insert("SKU", LineProducts_[NameOfCodeColumn]);
	EndIf;
	
	AreaRow = GetProductLineArea(Template, NameOfCodeColumn, ThereIsRNPT);
	AreaRow.Parameters.Fill(LineProducts_);
	AreaRow.Parameters.Fill(ParametersStructure);
	
	If ThereIsRNPT
		And (TypeOf(LineProducts_.Ref) = Type("DocumentRef.ConsignmentReportFromCustomer")
			Or TypeOf(LineProducts_.Ref) = Type("DocumentRef.ConsignmentReportToVendor"))
		And ValueIsFilled(LineProducts_.CCDNumber)
		And LineProducts_.CCDNumberType <> Enums.CCDNumberTypes.CCDNumber Then
		
		If LineProducts_.CCDNumberType = Enums.CCDNumberTypes.ProductBatchIDNumber Then
			TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
			TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(LineProducts_.ProductBatchIDNumber);
			TheseAreRNPTNumbers.QuantityByGBRN		= LineProducts_.QuantityByGBRN;
			TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(LineProducts_.FEACNUnitOfMeasure);
			
			AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
			
			AreasToOutput.Add(AreaRow);
		Else
			RowFilter = New Structure("CCDNumber", LineProducts_.CCDNumber);
			SetLines = TraceableComponents.FindRows(RowFilter);
			
			SetLineNumber = 1;
			
			For Each SetString_ In SetLines Do
				TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
				TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(SetString_.ProductBatchIDNumber);
				TheseAreRNPTNumbers.QuantityByGBRN		= LineProducts_.Count * SetString_.QuantityByGBRN;
				TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(SetString_.FEACNUnitOfMeasure);
				
				If SetLineNumber = 1 Then
					AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
					
					AreasToOutput.Add(AreaRow);
				Else
					AreaRowComponents = GetAreaOfComponentString(Template, NameOfCodeColumn);
					AreaRowComponents.Parameters.Fill(TheseAreRNPTNumbers);
					
					AreasToOutput.Add(AreaRowComponents);
				EndIf;
				
				SetLineNumber = SetLineNumber + 1;
			EndDo;
		EndIf;
		
	Else
		If ThereIsRNPT Then
			TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure",
												"-", 0, "-");
			AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
		EndIf;
		
		AreasToOutput.Add(AreaRow);
	EndIf;
	
	Return AreasToOutput;
	
EndFunction

Function LineAreasFilledInByParametersForWriteOffDocuments(LineNumber,
																LineProducts_,
																TraceableComponents,
																Template,
																NameOfCodeColumn,
																ThereIsRNPT)
	
	AreasToOutput = New Array;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ProductItemName = ProductsClientServer.PresentationOfProductsForPrinting(
							LineProducts_.ProductItemName,
							String(LineProducts_.Characteristic),
							,
							,
							AdditionalParametersProductPresentation);
	
	Price = ?(LineProducts_.Count = 0, 0, Round(LineProducts_.Sum / LineProducts_.Count, 2, 1));
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("LineNumber",			LineNumber);
	ParametersStructure.Insert("ProductItemName",	ProductItemName);
	ParametersStructure.Insert("Price",				Price);
	
	If ValueIsFilled(NameOfCodeColumn) Then
		ParametersStructure.Insert("SKU", LineProducts_[NameOfCodeColumn]);
	EndIf;
	
	AreaRow = GetProductLineArea(Template, NameOfCodeColumn, ThereIsRNPT);
	AreaRow.Parameters.Fill(LineProducts_);
	AreaRow.Parameters.Fill(ParametersStructure);
	
	If ThereIsRNPT
		And (TypeOf(LineProducts_.Ref) = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost")
			Or TypeOf(LineProducts_.Ref) = Type("DocumentRef.WriteOffReportFromCommissionAgent"))
		And ValueIsFilled(LineProducts_.CCDNumber)
		And LineProducts_.CCDNumberType <> Enums.CCDNumberTypes.CCDNumber Then
		
		If LineProducts_.CCDNumberType = Enums.CCDNumberTypes.ProductBatchIDNumber Then
			TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
			TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(LineProducts_.ProductBatchIDNumber);
			TheseAreRNPTNumbers.QuantityByGBRN		= LineProducts_.QuantityByGBRN;
			TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(LineProducts_.FEACNUnitOfMeasure);
			
			AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
			
			AreasToOutput.Add(AreaRow);
		Else
			RowFilter = New Structure("CCDNumber", LineProducts_.CCDNumber);
			SetLines = TraceableComponents.FindRows(RowFilter);
			
			SetLineNumber = 1;
			
			For Each SetString_ In SetLines Do
				TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
				TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(SetString_.ProductBatchIDNumber);
				TheseAreRNPTNumbers.QuantityByGBRN		= LineProducts_.Count * SetString_.QuantityByGBRN;
				TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(SetString_.FEACNUnitOfMeasure);
				
				If SetLineNumber = 1 Then
					AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
					
					AreasToOutput.Add(AreaRow);
				Else
					AreaRowComponents = GetAreaOfComponentString(Template, NameOfCodeColumn);
					AreaRowComponents.Parameters.Fill(TheseAreRNPTNumbers);
					
					AreasToOutput.Add(AreaRowComponents);
				EndIf;
				
				SetLineNumber = SetLineNumber + 1;
			EndDo;
		EndIf;
		
	Else
		If ThereIsRNPT Then
			TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure",
												"-", 0, "-");
			AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
		EndIf;
		
		AreasToOutput.Add(AreaRow);
	EndIf;
	
	Return AreasToOutput;
	
EndFunction

Function TableForPrintingSRNPTReport(DocRef)
	
	DimensionsNames	= "ItemsLocationAttributes, Products, Characteristic, Package, Price, SellingPrice";
	ResourceNames	= "NumberOfPackages, Count, AmountIncludingVAT, SalesAmount, CommissionAmount";
	
	Goods = DocRef.Goods.Unload(); 
	Goods.GroupBy(DimensionsNames, ResourceNames);
	
	GoodsRolledWithoutPrice = Goods.Copy();
	GoodsRolledWithoutPrice.GroupBy("ItemsLocationAttributes", "NumberOfPackages, Count");
	
	InventoryKinds = DocRef.InventoryKinds.Unload();
	InventoryKinds.GroupBy("ItemsLocationAttributes, CCDNumber", "Count, QuantityByGBRN");
	InventoryKinds.Columns.Add("LineBalance");
	InventoryKinds.Columns.Add("RnptBalance");
	
	For Each InventoryLine In InventoryKinds Do
		InventoryLine.LineBalance	= InventoryLine.Count;
		InventoryLine.RnptBalance		= InventoryLine.QuantityByGBRN;
	EndDo;
	
	TableForPrintingSRNPTReport = New ValueTable();
	TableForPrintingSRNPTReport.Columns.Add("Ref");
	TableForPrintingSRNPTReport.Columns.Add("Products");
	TableForPrintingSRNPTReport.Columns.Add("ProductItemName");
	TableForPrintingSRNPTReport.Columns.Add("Code");
	TableForPrintingSRNPTReport.Columns.Add("SKU");
	TableForPrintingSRNPTReport.Columns.Add("UnitOfMeasurementName");
	TableForPrintingSRNPTReport.Columns.Add("FEACNUnitOfMeasure");
	TableForPrintingSRNPTReport.Columns.Add("Characteristic");
	TableForPrintingSRNPTReport.Columns.Add("Package");
	TableForPrintingSRNPTReport.Columns.Add("Count");
	TableForPrintingSRNPTReport.Columns.Add("QuantityByGBRN");
	TableForPrintingSRNPTReport.Columns.Add("CCDNumber");
	TableForPrintingSRNPTReport.Columns.Add("ProductBatchIDNumber");
	TableForPrintingSRNPTReport.Columns.Add("CCDNumberType");
	TableForPrintingSRNPTReport.Columns.Add("Price");
	TableForPrintingSRNPTReport.Columns.Add("SellingPrice");
	TableForPrintingSRNPTReport.Columns.Add("ConsignorAmount");
	TableForPrintingSRNPTReport.Columns.Add("SalesAmount");
	TableForPrintingSRNPTReport.Columns.Add("CommissionAmount");
	TableForPrintingSRNPTReport.Columns.Add("TaxInvoiceDate");
	TableForPrintingSRNPTReport.Columns.Add("Customer");
	
	LineNumber = 0;
	
	For Each LineProducts_ In Goods Do
		
		Structure = New Structure();
		Structure.Insert("ItemsLocationAttributes", LineProducts_.ItemsLocationAttributes);
		RowsOfStockTypes = InventoryKinds.FindRows(Structure);
		LinesCollapsedWithoutPrice = GoodsRolledWithoutPrice.FindRows(Structure);
		StructureForDistribution = New Structure();
		StructureForDistribution.Insert("Products",LineProducts_.Products);
		StructureForDistribution.Insert("Characteristic",LineProducts_.Characteristic);
		TableOfDistributedRows = TableForPrintingSRNPTReport.Copy();
		TableOfDistributedRows.GroupBy("Products, Characteristic","Count");
		DistributedStrings  = TableOfDistributedRows.FindRows(StructureForDistribution);
		
		If DistributedStrings.Count()= 0 Then 
			DistributedQuantity = 0;
		Else
			DistributedQuantity = DistributedStrings[0].Count;
		EndIf;
		NumberOfPackagesBalance = LinesCollapsedWithoutPrice[0].NumberOfPackages - DistributedQuantity;
		DistributedQuantityByProductLine =0;
		
		For Each RowOfStockTypes In RowsOfStockTypes Do
			If RowOfStockTypes.LineBalance>0 And DistributedQuantityByProductLine<LineProducts_.NumberOfPackages Then
				LineNumber = LineNumber+1;
				NewRow = TableForPrintingSRNPTReport.Add();
				FillPropertyValues(NewRow, LineProducts_,
				"Products,Characteristic,Package,Price");
				
				ProductItemName = Common.ObjectAttributeValue(NewRow.Products,"DescriptionFull");
				Code = Common.ObjectAttributeValue(NewRow.Products,"Code"); 
				SKU = Common.ObjectAttributeValue(NewRow.Products,"SKU");
				UnitOfProductMeasurement_ = Common.ObjectAttributeValue(NewRow.Products,"UnitOfMeasure");
				FEACNCode =  Common.ObjectAttributeValue(NewRow.Products,"FEACNCode");				
				If FEACNCode<>Undefined Then
					FEACNUnitOfMeasure =  Common.ObjectAttributeValue(FEACNCode,"UnitOfMeasure"); 
				EndIf;
				If UnitOfProductMeasurement_<>Undefined Then
					UnitOfProductMeasurementName = Common.ObjectAttributeValue(UnitOfProductMeasurement_,"Description");
				EndIf;
				If Not ValueIsFilled(LineProducts_.Package) Then
					UnitOfMeasurementName = UnitOfProductMeasurementName;
				Else
					UnitOfMeasurementName = LineProducts_.Package;
				EndIf;
				
				NewRow.Ref = DocRef;
				NewRow.ProductItemName = ProductItemName;
				NewRow.Code = Code; 
				NewRow.SKU = SKU; 
				NewRow.UnitOfMeasurementName = UnitOfMeasurementName; 
				
				// distribute the number of packages
				NumberOfPackagesGoods = LineProducts_.NumberOfPackages;
				NumberOfProductUnits = LineProducts_.Count;
				NumberOfUnitsTypesOfStocks = RowOfStockTypes.LineBalance;
				If NumberOfUnitsTypesOfStocks<>0 Then  
					Proportion = NumberOfProductUnits/NumberOfUnitsTypesOfStocks;
				Else
					Proportion = 1;
				EndIf;
				If Proportion>1 Then
					NumberOfPackagesTypesOfStocks = Int(NumberOfPackagesGoods/Proportion);
				Else
					NumberOfPackagesTypesOfStocks = Int(NumberOfUnitsTypesOfStocks*Proportion);
				EndIf;
				If DistributedQuantity+NumberOfPackagesTypesOfStocks <= NumberOfPackagesBalance Then
					NewRow.Count = NumberOfPackagesTypesOfStocks;
				Else
					NewRow.Count = NumberOfPackagesBalance;
				EndIf;
				DistributedQuantity = DistributedQuantity + NewRow.Count;
				DistributedQuantityByProductLine = DistributedQuantityByProductLine +  NewRow.Count;
				RowOfStockTypes.LineBalance = RowOfStockTypes.LineBalance - NumberOfProductUnits; 
				NumberOfPackagesBalance = NumberOfPackagesBalance - NewRow.Count;
				
				ProportionAccordingToRNPT = NumberOfUnitsTypesOfStocks/NumberOfProductUnits;
				
				If ProportionAccordingToRNPT>1 Then
					QuantityByGBRN = Int(RowOfStockTypes.QuantityByGBRN/ProportionAccordingToRNPT);
				Else
					QuantityByGBRN  = RowOfStockTypes.RnptBalance;
				EndIf;
				
				RowOfStockTypes.RnptBalance = RowOfStockTypes.RnptBalance - QuantityByGBRN;
				
				NewRow.QuantityByGBRN = QuantityByGBRN;
				NewRow.CCDNumber = RowOfStockTypes.CCDNumber;
				If FEACNCode<>Undefined And FEACNUnitOfMeasure<>Undefined Then
					NewRow.FEACNUnitOfMeasure = FEACNUnitOfMeasure;
				EndIf;
				
				If ValueIsFilled(NewRow.CCDNumber) Then
					AttributesOfCCDNumber = Common.ObjectAttributesValues(RowOfStockTypes.CCDNumber,
																					"Code, CCDNumberType");
					NewRow.ProductBatchIDNumber		= AttributesOfCCDNumber.Code;
					NewRow.CCDNumberType	= AttributesOfCCDNumber.CCDNumberType;
				EndIf;
				
				NewRow.ConsignorAmount = (LineProducts_.AmountIncludingVAT/LineProducts_.NumberOfPackages)* NewRow.Count;
				NewRow.SalesAmount =  (LineProducts_.SalesAmount/LineProducts_.NumberOfPackages)* NewRow.Count;
				NewRow.CommissionAmount =  (LineProducts_.CommissionAmount/LineProducts_.NumberOfPackages)* NewRow.Count;
				
			EndIf;
		EndDo;
	EndDo;
	
	Return TableForPrintingSRNPTReport;
	
EndFunction

Function TableForPrintingReportOnWriteOffOfSRNPT(DocRef)
	
	DimensionsNames	= "ItemsLocationAttributes, Products, Characteristic, Package, Price";
	ResourceNames	= "NumberOfPackages, Count";
	
	Goods = DocRef.Goods.Unload();
	Goods.GroupBy(DimensionsNames, ResourceNames);
	
	GoodsRolledWithoutPrice = Goods.Copy();
	GoodsRolledWithoutPrice.GroupBy("ItemsLocationAttributes", "NumberOfPackages, Count");
	
	InventoryKinds = DocRef.InventoryKinds.Unload();
	InventoryKinds.GroupBy("ItemsLocationAttributes, CCDNumber", "Count, QuantityByGBRN");
	InventoryKinds.Columns.Add("LineBalance");
	InventoryKinds.Columns.Add("RnptBalance");
	
	For Each Page1 In InventoryKinds Do
		Page1.LineBalance = Page1.Count;
		Page1.RnptBalance = Page1.QuantityByGBRN;
	EndDo;
	
	TableForPrintingReportOnWriteOffOfSRNPT = New ValueTable();
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Ref");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Products");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("ProductItemName");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Code");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("SKU");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("UnitOfMeasurementName");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("FEACNUnitOfMeasure");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Characteristic");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Package");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Count");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("QuantityByGBRN");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("CCDNumber");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("ProductBatchIDNumber");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("CCDNumberType");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Price");
	TableForPrintingReportOnWriteOffOfSRNPT.Columns.Add("Sum");
	
	LineNumber = 0;
	
	For Each LineProducts_ In Goods Do
		
		Structure = New Structure();
		Structure.Insert("ItemsLocationAttributes", LineProducts_.ItemsLocationAttributes);
		RowsOfStockTypes = InventoryKinds.FindRows(Structure);
		LinesCollapsedWithoutPrice = GoodsRolledWithoutPrice.FindRows(Structure);
		StructureForDistribution = New Structure();
		StructureForDistribution.Insert("Products",LineProducts_.Products);
		StructureForDistribution.Insert("Characteristic",LineProducts_.Characteristic);
		TableOfDistributedRows = TableForPrintingReportOnWriteOffOfSRNPT.Copy();
		TableOfDistributedRows.GroupBy("Products, Characteristic","Count");
		DistributedStrings  = TableOfDistributedRows.FindRows(StructureForDistribution);
		
		If DistributedStrings.Count()= 0 Then 
			DistributedQuantity = 0;
		Else
			DistributedQuantity = DistributedStrings[0].Count;
		EndIf;
		NumberOfPackagesBalance = LinesCollapsedWithoutPrice[0].NumberOfPackages - DistributedQuantity;
		DistributedQuantityByProductLine =0;
		
		For Each RowOfStockTypes In RowsOfStockTypes Do
			If RowOfStockTypes.LineBalance>0 And DistributedQuantityByProductLine<LineProducts_.NumberOfPackages Then
				LineNumber = LineNumber+1;
				NewRow = TableForPrintingReportOnWriteOffOfSRNPT.Add();
				FillPropertyValues(NewRow, LineProducts_,
				"Products,Characteristic,Package,Price");
				
				ProductItemName = Common.ObjectAttributeValue(NewRow.Products,"DescriptionFull");
				Code = Common.ObjectAttributeValue(NewRow.Products,"Code"); 
				SKU = Common.ObjectAttributeValue(NewRow.Products,"SKU");
				UnitOfProductMeasurement_ = Common.ObjectAttributeValue(NewRow.Products,"UnitOfMeasure");
				FEACNCode =  Common.ObjectAttributeValue(NewRow.Products,"FEACNCode");				
				If FEACNCode<>Undefined Then
					FEACNUnitOfMeasure =  Common.ObjectAttributeValue(FEACNCode,"UnitOfMeasure"); 
				EndIf;
				If UnitOfProductMeasurement_<>Undefined Then
					UnitOfProductMeasurementName = Common.ObjectAttributeValue(UnitOfProductMeasurement_,"Description");
				EndIf;
				If Not ValueIsFilled(LineProducts_.Package) Then
					UnitOfMeasurementName = UnitOfProductMeasurementName; 	
				Else
					UnitOfMeasurementName = LineProducts_.Package;
				EndIf;
				
				NewRow.Ref = DocRef;
				NewRow.ProductItemName = ProductItemName; 
				NewRow.Code = Code; 
				NewRow.SKU = SKU; 
				NewRow.UnitOfMeasurementName = UnitOfMeasurementName; 
				
				// distribute the number of packages
				NumberOfPackagesGoods = LineProducts_.NumberOfPackages;
				NumberOfProductUnits = LineProducts_.Count;
				NumberOfUnitsTypesOfStocks = RowOfStockTypes.LineBalance;
				If NumberOfUnitsTypesOfStocks<>0 Then  
					Proportion = NumberOfProductUnits/NumberOfUnitsTypesOfStocks;
				Else
					Proportion = 1;
				EndIf;
				If Proportion>1 Then
					NumberOfPackagesTypesOfStocks = Int(NumberOfPackagesGoods/Proportion);
				Else
					NumberOfPackagesTypesOfStocks = Int(NumberOfUnitsTypesOfStocks*Proportion);
				EndIf;
				If DistributedQuantity+NumberOfPackagesTypesOfStocks <= NumberOfPackagesBalance Then
					NewRow.Count = NumberOfPackagesTypesOfStocks;
				Else
					NewRow.Count = NumberOfPackagesBalance;
				EndIf;
				DistributedQuantity = DistributedQuantity + NewRow.Count;
				DistributedQuantityByProductLine = DistributedQuantityByProductLine +  NewRow.Count;
				RowOfStockTypes.LineBalance = RowOfStockTypes.LineBalance - NumberOfProductUnits; 
				NumberOfPackagesBalance = NumberOfPackagesBalance - NewRow.Count;
				
				ProportionAccordingToRNPT = NumberOfUnitsTypesOfStocks/NumberOfProductUnits;
				
				If ProportionAccordingToRNPT>1 Then
					QuantityByGBRN = Int(RowOfStockTypes.QuantityByGBRN/ProportionAccordingToRNPT);
				Else
					QuantityByGBRN  = RowOfStockTypes.RnptBalance;
				EndIf;
				
				RowOfStockTypes.RnptBalance = RowOfStockTypes.RnptBalance - QuantityByGBRN;
				
				NewRow.QuantityByGBRN = QuantityByGBRN;
				NewRow.CCDNumber = RowOfStockTypes.CCDNumber;
				If FEACNCode<>Undefined And FEACNUnitOfMeasure<>Undefined Then
					NewRow.FEACNUnitOfMeasure = FEACNUnitOfMeasure;
				EndIf; 
				
				If ValueIsFilled(NewRow.CCDNumber) Then
					AttributesOfCCDNumber = Common.ObjectAttributesValues(RowOfStockTypes.CCDNumber,
																					"Code, CCDNumberType");
					NewRow.ProductBatchIDNumber		= AttributesOfCCDNumber.Code;
					NewRow.CCDNumberType	= AttributesOfCCDNumber.CCDNumberType;
				EndIf;
				
				NewRow.Sum = NewRow.Count*LineProducts_.Price; 
			EndIf;
		EndDo;
	EndDo;
	
	Return TableForPrintingReportOnWriteOffOfSRNPT;
	
EndFunction

// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument -
//	DataForPrint   - Structure - It contains data on the document header, tabular part, and report header:
//		* HeaderResults          - QueryResult -
//		* ResultForTabularPart - QueryResult -
//		* Title                 - String -
//	PrintObjects     - See PrintManagementOverridable.OnPrint.PrintObjects
//
Procedure FillInTabularDocumentSalesCommissionReport(SpreadsheetDocument, DataForPrint, PrintObjects) 
	
	Title			= DataForPrint.Title;
	PrintData		= DataForPrint.HeaderResults.Select();
	SelectionByDocuments	= DataForPrint.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
	
	DocumentTraceabilityData	= Undefined;
	TraceableComponents			= Undefined;
	
	DataForPrint.Property("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataForPrint.Property("TraceableComponents",			TraceableComponents);
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommissionReports.PF_MXL_ReportOnCommission");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn				= ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn	= ColumnOfCodes.ColumnPresentation;
	
	FirstDocument = True;
	
	While PrintData.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument		= False;
		RowNumberStart	= SpreadsheetDocument.TableHeight + 1;
		
		SelectionByDocuments.Reset();
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		
		If SelectionByDocuments.FindNext(TheStructureOfTheSearch) Then
			
			// We output the general details of the header
			FillInDetailsOfCommissionReportHeader(PrintData, Title, Template, SpreadsheetDocument);
			
			ThereIsRNPT = False;
			
			If DocumentTraceabilityData <> Undefined Then
				DocumentStrings = DocumentTraceabilityData.FindRows(TheStructureOfTheSearch);
				If DocumentStrings.Count() > 0 Then
					ThereIsRNPT = DocumentStrings[0].ThereIsRNPT;
				EndIf;
			EndIf;
			
			ParametersStructure = New Structure;
			
			// Output the table header
			If ValueIsFilled(NameOfCodeColumn) Then
				If ThereIsRNPT Then
					TableHeading = Template.GetArea("HeaderOfTableWithRNPTCodes");
				Else
					TableHeading = Template.GetArea("HeaderOfTableWithCodes");
				EndIf;
				
				ParametersStructure.Insert("NameOfCodeColumn", PresentationOfCodesColumn);
			Else
				If ThereIsRNPT Then
					TableHeading = Template.GetArea("HeaderOfRNPTTable");
				Else
					TableHeading = Template.GetArea("TableHeader");
				EndIf;
			EndIf;
			
			ParametersStructure.Insert("Currency", PrintData.Currency);
			
			TableHeading.Parameters.Fill(ParametersStructure);
			SpreadsheetDocument.Put(TableHeading);
			
			LineNumber = 0;
			
			If ThereIsRNPT
				And TypeOf(PrintData.Ref) = Type("DocumentRef.ConsignmentReportToVendor") Then
				
				TableOfGoodsSRNPT = TableForPrintingSRNPTReport(PrintData.Ref);
				
				For Each LineProducts_ In TableOfGoodsSRNPT Do
					LineNumber = LineNumber + 1;
					
					AreasToOutput = AreasOfRowsFilledByParameters(
											LineNumber,
											LineProducts_,
											TraceableComponents,
											Template,
											NameOfCodeColumn,
											True);
					
					For Each TemplateArea In AreasToOutput Do
						SpreadsheetDocument.Put(TemplateArea);
					EndDo;
				EndDo;
				
			Else
				
				LineProducts_ = SelectionByDocuments.Select();
				
				While LineProducts_.Next() Do
					LineNumber = LineNumber + 1;
					
					AreasToOutput = AreasOfRowsFilledByParameters(
											LineNumber,
											LineProducts_,
											TraceableComponents,
											Template,
											NameOfCodeColumn,
											ThereIsRNPT);
					
					For Each TemplateArea In AreasToOutput Do
						SpreadsheetDocument.Put(TemplateArea);
					EndDo;
				EndDo;
				
			EndIf;
			
			FillInDetailsOfBasementReportOnCommission(
				PrintData,
				SelectionByDocuments,
				Template,
				SpreadsheetDocument,
				ThereIsRNPT);
			
			PrintManagement.SetDocumentPrintArea(
				SpreadsheetDocument,
				RowNumberStart,
				PrintObjects,
				PrintData.Ref);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//	PrintData        - QueryResultSelection -
//	SelectionByDocuments - QueryResultSelection -
//	Template               - SpreadsheetDocument - Layout of the printed form
//	SpreadsheetDocument   - SpreadsheetDocument -
//	ThereIsRNPT            - Boolean -
//
Procedure FillInDetailsOfBasementCommissionReportOnDepreciation(PrintData,
															SelectionByDocuments,
															Template,
															SpreadsheetDocument,
															ThereIsRNPT)
	
	If ThereIsRNPT Then
		TemplateArea = Template.GetArea("RNPTBasement");
	Else
		TemplateArea = Template.GetArea("Footer");
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AmountTotal", SelectionByDocuments.Sum);
	
	ParametersStructure.Insert(
		"TotalString",
		NStr("vi = 'Tổng số ghi giảm tên gọi';
			|ru = 'Всего списано наименований';
			|en = 'All written off items'; fa = 'All written off items';
			|it = 'Totale cancellato titoli';
			|pl = 'Razem wyksięgowano nazw';
			|tr = 'Toplam kayıttan düşülen tanım'", Common.DefaultLanguageCode()) + " "
		+ SelectionByDocuments.Select().Count()
		+ ?(SelectionByDocuments.Sum <> 0, ", " + NStr("vi = 'với số tiền';
														|ru = 'на сумму';
														|en = 'in the amount of'; fa = 'به مبلغ';
														|it = 'per l''importo di';
														|pl = 'na kwotę';
														|tr = 'tutarında'", Common.DefaultLanguageCode()) + " ", "")
		+ ?(SelectionByDocuments.Sum <> 0, PrintFormGeneration.SumFormat(SelectionByDocuments.Sum, PrintData.Currency), ""));
	
	ParametersStructure.Insert(
		"AmountInWords",
		ProcessingOfExchangeRatesTM.GenerateAmountInWords(SelectionByDocuments.Sum, PrintData.Currency));
	
	ParametersStructure.Insert(
		"CommitteeRepresentative",
		PersonsTM.IndividualShortName(PrintData.CommitteeRepresentative, PrintData.Date));
	
	ParametersStructure.Insert(
		"RepresentativeOfCommissionAgent",
		PersonsTM.IndividualShortName(PrintData.RepresentativeOfCommissionAgent, PrintData.Date));
	
	TemplateArea.Parameters.Fill(ParametersStructure);
	
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument -
//	DataForPrint   - Structure - It contains data on the document header, tabular part, and report header:
//		* HeaderResults          - QueryResult -
//		* ResultForTabularPart - QueryResult -
//		* Title                 - String -
//	PrintObjects     - See PrintManagementOverridable.OnPrint.PrintObjects
//
Procedure FillInTabularDocumentCommissionReportOnWriteOff(SpreadsheetDocument, DataForPrint, PrintObjects) 
	
	Title			= DataForPrint.Title;
	PrintData		= DataForPrint.HeaderResults.Select();
	SelectionByDocuments	= DataForPrint.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
	
	DocumentTraceabilityData	= Undefined;
	TraceableComponents			= Undefined;
	
	DataForPrint.Property("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataForPrint.Property("TraceableComponents",			TraceableComponents);
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommissionReports.PF_MXL_ReportToConsignor");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn				= ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn	= ColumnOfCodes.ColumnPresentation;
	
	FirstDocument = True;
	
	While PrintData.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument		= False;
		RowNumberStart	= SpreadsheetDocument.TableHeight + 1;
		
		SelectionByDocuments.Reset();
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		
		If SelectionByDocuments.FindNext(TheStructureOfTheSearch) Then
			
			// We output the general details of the header
			FillInDetailsOfCommissionReportHeader(PrintData, Title, Template, SpreadsheetDocument);
			
			ThereIsRNPT = False;
			
			If DocumentTraceabilityData <> Undefined Then
				DocumentStrings = DocumentTraceabilityData.FindRows(TheStructureOfTheSearch);
				If DocumentStrings.Count() > 0 Then
					ThereIsRNPT = DocumentStrings[0].ThereIsRNPT;
				EndIf;
			EndIf;
			
			ParametersStructure = New Structure;
			
			// Output the table header
			If ValueIsFilled(NameOfCodeColumn) Then
				If ThereIsRNPT Then
					TableHeading = Template.GetArea("HeaderOfTableWithRNPTCodes");
				Else
					TableHeading = Template.GetArea("HeaderOfTableWithCodes");
				EndIf;
				ParametersStructure.Insert("NameOfCodeColumn", PresentationOfCodesColumn);
			Else
				If ThereIsRNPT Then
					TableHeading = Template.GetArea("HeaderOfRNPTTable");
				Else
					TableHeading = Template.GetArea("TableHeader");
				EndIf;
			EndIf;
			
			ParametersStructure.Insert("Currency", PrintData.Currency);
			
			TableHeading.Parameters.Fill(ParametersStructure);
			SpreadsheetDocument.Put(TableHeading);
			
			LineNumber = 0;
			
			If ThereIsRNPT
				And TypeOf(PrintData.Ref) = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
				
				TableOfGoodsSRNPT = TableForPrintingReportOnWriteOffOfSRNPT(PrintData.Ref);
				
				For Each LineProducts_ In TableOfGoodsSRNPT Do
					LineNumber = LineNumber + 1;
					
					AreasToOutput = LineAreasFilledInByParametersForWriteOffDocuments(
											LineNumber,
											LineProducts_,
											TraceableComponents,
											Template,
											NameOfCodeColumn,
											True);
					
					For Each TemplateArea In AreasToOutput Do
						SpreadsheetDocument.Put(TemplateArea);
					EndDo;
				EndDo;
				
			Else
				
				LineProducts_ = SelectionByDocuments.Select();
				
				While LineProducts_.Next() Do
					LineNumber = LineNumber + 1;
					
					AreasToOutput = LineAreasFilledInByParametersForWriteOffDocuments(
											LineNumber,
											LineProducts_,
											TraceableComponents,
											Template,
											NameOfCodeColumn,
											ThereIsRNPT);
					
					For Each TemplateArea In AreasToOutput Do
						SpreadsheetDocument.Put(TemplateArea);
					EndDo;
				EndDo;
				
			EndIf;
			
			FillInDetailsOfBasementCommissionReportOnDepreciation(
				PrintData,
				SelectionByDocuments,
				Template,
				SpreadsheetDocument,
				ThereIsRNPT);
			
			PrintManagement.SetDocumentPrintArea(
				SpreadsheetDocument,
				RowNumberStart,
				PrintObjects,
				PrintData.Ref);
			
		EndIf;
	
	EndDo;
	
EndProcedure

Function CreatePrintedFormForPurchaseReport(StructureOfTypes, PrintObjects, PrintParameters) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName	= "PARAMETERS_PRINTING_ProcurementReport";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		If ObjectsStructure.Key = "Document.WriteOffReportFromCommissionAgent"
			Or ObjectsStructure.Key = "Document.PurchaseInvoiceConsignmentStockLost"
			Or ObjectsStructure.Key = "Document.ConsignmentReportFromCustomer"
			Or ObjectsStructure.Key = "Document.ConsignmentReportToVendor" Then
			
			Continue;
			
		EndIf;
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedProcurementReportForm(PrintParameters,
																						ObjectsStructure.Value);
		
		FillInTabularDocumentPurchaseReport(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects);
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument -
//	DataForPrint   - Structure - It contains data on the document header, tabular part, and report header:
//		* HeaderResults          - QueryResult -
//		* ResultForTabularPart - QueryResult -
//		* Title                 - String -
//	PrintObjects     - See PrintManagementOverridable.OnPrint.PrintObjects
//
Procedure FillInTabularDocumentPurchaseReport(SpreadsheetDocument, DataForPrint, PrintObjects) 
	
	Title			= DataForPrint.Title;
	PrintData		= DataForPrint.HeaderResults.Select();
	SelectionByDocuments	= DataForPrint.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
	
	DocumentTraceabilityData	= Undefined;
	TraceableComponents			= Undefined;
	
	DataForPrint.Property("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataForPrint.Property("TraceableComponents",			TraceableComponents);
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommissionReports.PF_MXL_PurchasingReportToConsignorPrincipal");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn				= ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn	= ColumnOfCodes.ColumnPresentation;
	
	FirstDocument = True;
	
	While PrintData.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument		= False;
		RowNumberStart	= SpreadsheetDocument.TableHeight + 1;
		
		SelectionByDocuments.Reset();
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		
		If SelectionByDocuments.FindNext(TheStructureOfTheSearch) Then
			
			// We output the general details of the header
			FillInDetailsOfPurchaseReportHeader(PrintData, Title, Template, SpreadsheetDocument);
			
			ThereIsRNPT = False;
			
			If DocumentTraceabilityData <> Undefined Then
				DocumentStrings = DocumentTraceabilityData.FindRows(TheStructureOfTheSearch);
				If DocumentStrings.Count() > 0 Then
					ThereIsRNPT = DocumentStrings[0].ThereIsRNPT;
				EndIf;
			EndIf;
			
			ParametersStructure = New Structure;
			
			// Output the table header
			If ValueIsFilled(NameOfCodeColumn) Then
				If ThereIsRNPT Then
					TableHeading = Template.GetArea("HeaderOfTableWithRNPTCodes");
				Else
					TableHeading = Template.GetArea("HeaderOfTableWithCodes");
				EndIf;
				
				ParametersStructure.Insert("NameOfCodeColumn", PresentationOfCodesColumn);
			Else
				If ThereIsRNPT Then
					TableHeading = Template.GetArea("HeaderOfRNPTTable");
				Else
					TableHeading = Template.GetArea("TableHeader");
				EndIf;
			EndIf;
			
			CommissionAmount = ?(PrintData.ThereIsRewardRate, NStr("vi = 'Số tiền (gồm thuế GTGT)';
																	|ru = 'Сумма (с НДС)';
																	|en = 'Amount (including VAT)'; fa = 'مبلغ (با VAT)';
																	|it = 'Importo (IVA inclusa)';
																	|pl = 'Wartość (z VAT)';
																	|tr = 'Tutar (KDV dahil)'"), NStr("vi = 'Số tiền';
																											|ru = 'Сумма';
																											|en = 'Amount'; fa = 'مبلغ';
																											|it = 'Importo';
																											|pl = 'Wartość';
																											|tr = 'Tutar'"));
			
			ParametersStructure.Insert("Currency",				PrintData.Currency);
			ParametersStructure.Insert("CommissionAmount",	CommissionAmount);
			
			TableHeading.Parameters.Fill(ParametersStructure);
			SpreadsheetDocument.Put(TableHeading);
			
			// Output the multiline part of the document
			If ValueIsFilled(NameOfCodeColumn) Then
				If ThereIsRNPT Then
					AreaRow = Template.GetArea("StringWithRNPTCodes");
					AreaRowComponents = Template.GetArea("StringWithRNPTCodesComponents");
				Else
					AreaRow = Template.GetArea("StringWithCodes");
				EndIf;
			Else
				If ThereIsRNPT Then
					AreaRow = Template.GetArea("RNPTString");
					AreaRowComponents = Template.GetArea("RNPTStringComponents");
				Else
					AreaRow = Template.GetArea("String");
				EndIf;
			EndIf;
			
			LineNumber = 0;
			
			LineProducts_ = SelectionByDocuments.Select();
			
			While LineProducts_.Next() Do
				
				LineNumber = LineNumber + 1;
				
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				ProductItemName = ProductsClientServer.PresentationOfProductsForPrinting(
										LineProducts_.ProductItemName,
										String(LineProducts_.Characteristic),
										,
										,
										AdditionalParametersProductPresentation);
				
				ConsignorPrice		= ?(LineProducts_.Count = 0, 0, Round(LineProducts_.ConsignorAmount / LineProducts_.Count, 2, 1));
				SupplierInformation	= PrintFormGeneration.InformationAboutLegalEntity(LineProducts_.Vendor, PrintData.Date);
				
				ParametersStructure = New Structure;
				ParametersStructure.Insert("LineNumber",			LineNumber);
				ParametersStructure.Insert("ProductItemName",	ProductItemName);
				ParametersStructure.Insert("ConsignorPrice",		ConsignorPrice);
				ParametersStructure.Insert("SupplierPresentation",
											PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr"));
				
				If ValueIsFilled(NameOfCodeColumn) Then
					ParametersStructure.Insert("SKU", LineProducts_[NameOfCodeColumn]);
				EndIf;
				
				AreaRow.Parameters.Fill(LineProducts_);
				AreaRow.Parameters.Fill(ParametersStructure);
				
				If ThereIsRNPT
					And TypeOf(LineProducts_.Ref) = Type("DocumentRef.PurchasingReportToConsignorPrincipal")
					And ValueIsFilled(LineProducts_.CCDNumber)
					And LineProducts_.CCDNumberType <> Enums.CCDNumberTypes.CCDNumber Then
					
					If LineProducts_.CCDNumberType = Enums.CCDNumberTypes.ProductBatchIDNumber Then
						TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
						TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(LineProducts_.ProductBatchIDNumber);
						TheseAreRNPTNumbers.QuantityByGBRN		= LineProducts_.QuantityByGBRN;
						TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(LineProducts_.FEACNUnitOfMeasure);
						
						AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
						
						SpreadsheetDocument.Put(AreaRow);
					Else
						RowFilter = New Structure("CCDNumber", LineProducts_.CCDNumber);
						SetLines = TraceableComponents.FindRows(RowFilter);
						
						SetLineNumber = 1;
						
						For Each SetString_ In SetLines Do
							TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
							TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(SetString_.ProductBatchIDNumber);
							TheseAreRNPTNumbers.QuantityByGBRN		= LineProducts_.Count * SetString_.QuantityByGBRN;
							TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(SetString_.FEACNUnitOfMeasure);
							
							If SetLineNumber = 1 Then
								AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
								
								SpreadsheetDocument.Put(AreaRow);
							Else
								AreaRowComponents.Parameters.Fill(TheseAreRNPTNumbers);
								
								SpreadsheetDocument.Put(AreaRowComponents);
							EndIf;
							
							SetLineNumber = SetLineNumber + 1;
						EndDo;
					EndIf;
					
				Else
					If ThereIsRNPT Then
						TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure",
															"-", 0, "-");
						AreaRow.Parameters.Fill(TheseAreRNPTNumbers);
					EndIf;
					
					SpreadsheetDocument.Put(AreaRow);
				EndIf;
				
			EndDo;
			
			FillInDetailsOfBasementPurchaseReport(
				PrintData,
				SelectionByDocuments,
				Template,
				SpreadsheetDocument,
				ThereIsRNPT);
			
			PrintManagement.SetDocumentPrintArea(
				SpreadsheetDocument,
				RowNumberStart,
				PrintObjects,
				PrintData.Ref);
			
		EndIf;
	
	EndDo;
	
EndProcedure

// Parameters:
//	PrintData        - QueryResultSelection -
//	SelectionByDocuments - QueryResultSelection -
//	Template               - SpreadsheetDocument - Layout of the printed form
//	SpreadsheetDocument   - SpreadsheetDocument -
//	ThereIsRNPT            - Boolean -
//
Procedure FillInDetailsOfBasementPurchaseReport(PrintData, SelectionByDocuments, Template, SpreadsheetDocument, ThereIsRNPT)
	
	If ThereIsRNPT Then
		TemplateArea = Template.GetArea("RNPTBasement");
	Else
		TemplateArea = Template.GetArea("Footer");
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TotalCommiteeAmount",			SelectionByDocuments.ConsignorAmount);
	ParametersStructure.Insert("VATAmount",					SelectionByDocuments.VATAmount);
	ParametersStructure.Insert("SumWithVATTotal",				SelectionByDocuments.AmountIncludingVAT);
	ParametersStructure.Insert("TotalRemunerationAmount",	SelectionByDocuments.CommissionAmount);
	ParametersStructure.Insert("RemunerationPercentage",		PrintData.RemunerationPercentage);
	
	TextSummaryLine = NStr("vi = 'Tổng số mặt hàng đã mua';
							|ru = 'Всего закуплено наименований';
							|en = 'Total purchased descriptions'; fa = 'Total purchased descriptions';
							|it = 'Totale articoli acquistati';
							|pl = 'Ogółem zakupiono nazw';
							|tr = 'Toplam satın alınan tanım'", Common.DefaultLanguageCode());
	
	ParametersStructure.Insert(
		"TotalString",
		TextSummaryLine + " " + SelectionByDocuments.Select().Count()
		+ ", " + NStr("vi = 'với số tiền';
						|ru = 'на сумму';
						|en = 'in the amount of'; fa = 'به مبلغ';
						|it = 'per l''importo di';
						|pl = 'na kwotę';
						|tr = 'tutarında'", Common.DefaultLanguageCode()) + " "
		+ PrintFormGeneration.SumFormat(SelectionByDocuments.AmountIncludingVAT, PrintData.Currency)
		+ ", " + ?(PrintData.SaleIsSubjectToVAT,
					NStr("vi = 'bao gồm Thuế GTGT';
						|ru = 'в том числе НДС';
						|en = 'including VAT'; fa = 'با احتساب مالیات بر ارزش افزوده';
						|it = 'di cui IVA';
						|pl = 'w tym VAT';
						|tr = 'KDV dahil'",
					Common.DefaultLanguageCode())
		+ " " + PrintFormGeneration.SumFormat(
					SelectionByDocuments.VATAmount, PrintData.Currency),
					NStr("vi = 'Không chịu thuế GTGT';
						|ru = 'НДС не облагается';
						|en = 'Not subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده نیست';
						|it = 'Non soggetta ad IVA';
						|pl = 'Nie podlega VAT';
						|tr = 'KDV''ye tabi değil'")));
		
	ParametersStructure.Insert(
		"AmountInWords",
		ProcessingOfExchangeRatesTM.GenerateAmountInWords(SelectionByDocuments.AmountIncludingVAT, PrintData.Currency));
	
	If PrintData.CommissionAmount <> 0 Then
		ParametersStructure.Insert(
			"CommissionAmount",
			NStr("vi = 'Số tiền hoa hồng ký gửi là';
				|ru = 'Сумма комиссионного вознаграждения составила';
				|en = 'Commission equals'; fa = 'Commission equals';
				|it = 'Importo della provvigione è di';
				|pl = 'Wysokość wynagrodzenia prowizyjnego wyniosła';
				|tr = 'Komisyon miktarı şu şekildedir'", Common.DefaultLanguageCode()) + " "
			+ ?(PrintData.CommissionAmount < 0, NStr("vi = 'trừ';
													|ru = 'минус';
													|en = 'minus'; fa = 'minus';
													|it = 'meno';
													|pl = 'minus';
													|tr = 'eksi'", Common.DefaultLanguageCode()) + " ", "")
			+ ProcessingOfExchangeRatesTM.GenerateAmountInWords(PrintData.CommissionAmount, PrintData.Currency)
			+ ", " + ?(PrintData.ThereIsRewardRate,
						NStr("vi = 'bao gồm Thuế GTGT';
							|ru = 'в том числе НДС';
							|en = 'including VAT'; fa = 'با احتساب مالیات بر ارزش افزوده';
							|it = 'di cui IVA';
							|pl = 'w tym VAT';
							|tr = 'KDV dahil'",
						Common.DefaultLanguageCode())
			+ " " + ProcessingOfExchangeRatesTM.GenerateAmountInWords(
						PrintData.AmountVATRemuneration, PrintData.Currency),
						NStr("vi = 'Không chịu thuế GTGT';
							|ru = 'НДС не облагается';
							|en = 'Not subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده نیست';
							|it = 'Non soggetta ad IVA';
							|pl = 'Nie podlega VAT';
							|tr = 'KDV''ye tabi değil'"))
			+ " (" + PrintData.RemunerationPercentage + "%" + " "
			+ NStr("vi = 'từ số tiền mua hàng)';
					|ru = 'от суммы закупки)';
					|en = 'of the purchase amount)'; fa = 'of the purchase amount)';
					|it = 'dell''importo dell''acquisto)';
					|pl = 'od kwoty zakupu)';
					|tr = 'satın alma tutarından)'", Common.DefaultLanguageCode()));
	EndIf;
	
	ParametersStructure.Insert(
		"CommitteeRepresentative",
		PersonsTM.IndividualShortName(PrintData.CommitteeRepresentative, PrintData.Date));
	ParametersStructure.Insert(
		"RepresentativeOfCommissionAgent",
		PersonsTM.IndividualShortName(PrintData.RepresentativeOfCommissionAgent, PrintData.Date));
	
	TemplateArea.Parameters.Fill(ParametersStructure);
	
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Procedure FillInDetailsOfPurchaseReportHeader(PrintData, Title, Template, SpreadsheetDocument)
	
	// We output the general details of the header
	InformationAboutCommittee = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Consignor, PrintData.Date);
	InformationAboutCommissionAgent = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Consignee, PrintData.Date);
	
	TemplateArea = Template.GetArea("Header");
	TemplateArea.Parameters.Fill(PrintData);
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
	
	PresentationOfContract = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Số %1 ngày %2';
			|ru = '№ %1 от %2';
			|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
			|it = '№ %1 da %2';
			|pl = 'Nr %1 z dnia %2';
			|tr = '%2 itibaren № %1'", Common.DefaultLanguageCode()), PrintData.Contract.Number, Format(PrintData.Contract.Date, "DLF=DD"));
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, Title));
	ParametersStructure.Insert("PresentationOfCommittee", PrintFormGeneration.OrganizationDescription(InformationAboutCommittee, "FullDescr"));
	ParametersStructure.Insert("PresentationOfCommissionAgent", PrintFormGeneration.OrganizationDescription(InformationAboutCommissionAgent, "FullDescr"));
	ParametersStructure.Insert("PresentationOfContract", PresentationOfContract);
	
	TemplateArea.Parameters.Fill(ParametersStructure);
	
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Function GetProductLineArea(Template, NameOfCodeColumn, ThereIsRNPT)
	
	If ValueIsFilled(NameOfCodeColumn) Then
		If ThereIsRNPT Then
			AreaRow = Template.GetArea("StringWithRNPTCodes");
		Else
			AreaRow = Template.GetArea("StringWithCodes");
		EndIf;
	Else
		If ThereIsRNPT Then
			AreaRow = Template.GetArea("RNPTString");
		Else
			AreaRow = Template.GetArea("String");
		EndIf;
	EndIf;
	
	Return AreaRow;
	
EndFunction

Function GetAreaOfComponentString(Template, NameOfCodeColumn)
	
	If ValueIsFilled(NameOfCodeColumn) Then
		AreaRowComponents = Template.GetArea("StringWithRNPTCodesComponents");
	Else
		AreaRowComponents = Template.GetArea("RNPTStringComponents");
	EndIf;
	
	Return AreaRowComponents;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf