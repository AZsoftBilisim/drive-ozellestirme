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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Act") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ';
												|ru = 'Акт об оказании услуг';
												|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
												|it = 'Atto di prestazione dei servizi';
												|pl = 'Protokół świadczenia usług';
												|tr = 'Hizmet tutanağı'"),
			FormPrintedFormOfActOnProvisionOfServices(StructureOfTypes, PrintObjects, PrintParameters));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActWithoutDiscounts") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, "ActWithoutDiscounts", NStr("vi = 'Biên bản cung cấp dịch vụ';
																|ru = 'Акт об оказании услуг';
																|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																|it = 'Atto di prestazione dei servizi';
																|pl = 'Protokół świadczenia usług';
																|tr = 'Hizmet tutanağı'"),
			FormPrintedFormOfActOnProvisionOfServices(StructureOfTypes, PrintObjects, PrintParameters));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, StructureOfTypes, PrintFormsCollection);
	
EndProcedure

#EndRegion

#Region CertificateOfRenderedServices

Function FormPrintedFormOfActOnProvisionOfServices(StructureOfTypes, PrintObjects, PrintParameters) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_CertificateOfRenderedServices";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		ThisPrintedFormIsAvailable = False;
		PrintCommands = PrintManagement.CreatePrintCommandsCollection();
		ObjectManager.AddPrintCommands(PrintCommands);
		For Each AvailablePrintedForm In PrintCommands Do
			If AvailablePrintedForm.Id = "Act" Then
				ThisPrintedFormIsAvailable = True;
				Break;
			EndIf;
		EndDo;
		If Not ThisPrintedFormIsAvailable Then
			Continue;
		EndIf;
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		DataForPrint = ObjectManager.GetDataForPrintedServiceDeliveryReportForm(PrintParameters, ObjectsStructure.Value);
		FillInTabularDocumentActOnProvisionOfServices(SpreadsheetDocument, DataForPrint, PrintObjects);
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
Procedure FillInTabularDocumentActOnProvisionOfServices(SpreadsheetDocument, DataForPrint, PrintObjects)
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCertificateOfRenderedServices.PF_MXL_Act");
	
	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseAutomaticDiscounts = GetFunctionalOption("UseDiscountsMarkupsInSales");
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	PrintData = DataForPrint.HeaderResults.Select();
	SelectionByDocuments = DataForPrint.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
	FirstDocument = True;
	TheStructureOfTheSearch = New Structure("Ref");
	LinksWithoutStrings = New Map;
	
	UseSets = False;
	If DataForPrint.ResultForTabularPart.Columns.Find("IsRecordsSet") <> Undefined Then
		UseSets = True;
	EndIf;
	
	While PrintData.Next() Do
		
		TheStructureOfTheSearch.Ref = PrintData.Ref;
		SelectionByDocuments.Reset();
		If Not SelectionByDocuments.FindNext(TheStructureOfTheSearch) Then
			If LinksWithoutStrings[PrintData.Ref] = Undefined Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong chứng từ %1 không có dịch vụ. Không cần in biên bản cung cấp dịch vụ.';
						|ru = 'В документе %1 отсутствуют услуги. Печать акта об оказании услуг не требуется.';
						|en = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.'; fa = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.';
						|it = 'Non ci sono servizi nel documento %1. La stampa dell''atto sulla prestazione dei servizi non è richiesta.';
						|pl = 'W dokumencie %1 brak usług. Drukowanie protokółu świadczenia usług nie jest potrzebne.';
						|tr = '%1 Belgesinde herhangi bir hizmet bulunmamaktadır. Hizmet tutanağı yazdırmaya gerek yoktur'"), PrintData.Ref);
				CommonClientServer.MessageToUser(Text, PrintData.Ref);
			EndIf;
			LinksWithoutStrings.Insert(PrintData.Ref,PrintData.Ref);
			Continue;
		EndIf;
		
		SampleByService = SelectionByDocuments.Select();
		DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(SampleByService, UseManualDiscounts Or UseAutomaticDiscounts);
		ThereAreDiscounts = DiscountHeader.ThereAreDiscounts;
		
		ThereIsVAT = PrintData.ConsiderVAT;
		SampleByService.Reset();
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		Else
			FirstDocument = False;
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the act
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);

		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Biên bản';
																					|ru = 'Акт';
																					|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																					|it = 'Atto';
																					|pl = 'Protokół';
																					|tr = 'Tutanak'", Common.DefaultLanguageCode()));
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TitleText);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Organization);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Counterparty);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Service table
		
		TemplateAreas = TemplateAreas(ThereAreDiscounts, ThereIsVAT And ShowVAT);
		
		TemplateArea = Template.GetArea(TemplateAreas.TableHeader);
		AreaLineStandard = Template.GetArea(TemplateAreas.String);
		
		If ThereAreDiscounts Then
			StructureOfDiscountHeader = New Structure("Discount, AmountWithoutADiscount", 
				DiscountHeader.Discount,
				DiscountHeader.DiscountAmount);
			TemplateArea.Parameters.Fill(StructureOfDiscountHeader);
		EndIf; 
		SpreadsheetDocument.Put(TemplateArea);
		
		Sum       = 0;
		VATAmount    = 0;
		LineNumber = 0;
		
		If UseSets Then
			AreaRowSet         = Template.GetArea(TemplateAreas.StringSet);
			AreaRowComponents = Template.GetArea(TemplateAreas.StringComponents);
		EndIf;
		
		BlankData = SetsServer.BlankData();
		
		// Output the rows of the Services table
		
		While SampleByService.Next() Do
		
			If SetsServer.UseSetArea(SampleByService, UseSets) Then
				RowArea = AreaRowSet;
			ElsIf SetsServer.UseScope(SampleByService, UseSets) Then
				RowArea = AreaRowComponents;
			Else
				RowArea = AreaLineStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(SampleByService, UseSets) Then
				LineNumberPrint = "";
			Else
				LineNumber = LineNumber + 1;
				LineNumberPrint = LineNumber;
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(SampleByService, UseSets);
			
			RowArea.Parameters.Fill(SampleByService);
			
			StringDataStructure = New Structure;
			StringDataStructure.Insert("LineNumber", LineNumberPrint);
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = PrefixAndPostfix.Prefix
					+ ProductsClientServer.PresentationOfProductsForPrinting(
														SampleByService.ServiceNameFull,
														SampleByService.CharacteristicFullName,
														,
														,
														AdditionalParametersProductPresentation)
					+ PrefixAndPostfix.Postfix;
			
			StringDataStructure.Insert("OwnGoods", OwnGoods);
			
			If ThereAreDiscounts Then
				StringDataStructure.Insert("Discount", ?(DiscountHeader.OnlyMarkUp,- SampleByService.DiscountAmount,SampleByService.DiscountAmount));
				StringDataStructure.Insert("AmountWithoutADiscount", PrintFormGeneration.SumFormat(SampleByService.Sum + SampleByService.DiscountAmount));
			EndIf;
			
			RowArea.Parameters.Fill(StringDataStructure);
			
			If SetsServer.DisplayOnlyTitle(SampleByService, UseSets) Then
				RowArea.Parameters.Fill(BlankData);
			EndIf;
			
			SpreadsheetDocument.Put(RowArea);
			
			If Not SetsServer.UseScope(SampleByService, UseSets) Then
				
				Sum = Sum + SampleByService.Sum;
				VATAmount = VATAmount + SampleByService.VATAmount;
				
			EndIf;
			
		EndDo;
		
		TemplateArea = Template.GetArea("InTotal");
		TotalDataStructure = New Structure("Total", PrintFormGeneration.SumFormat(Sum));
		TemplateArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		If GetFunctionalOption("UseVATAccounting") Then
			TemplateArea = Template.GetArea("TotalVAT_");
			DataStructureTotalVAT = New Structure;
			DataStructureTotalVAT.Insert("TotalVAT", VATAmount);
			If ThereIsVAT Then
				DataStructureTotalVAT.Insert("VAT", ?(PrintData.PriceIncludesVAT, " " 
					+ NStr("vi = 'Trong đó thuế GTGT:';
							|ru = 'В том числе НДС:';
							|en = 'including VAT:'; fa = 'including VAT:';
							|it = 'IVA compresa:';
							|pl = 'W tym VAT';
							|tr = 'KDV dahil:'", Common.DefaultLanguageCode()), " " 
					+ NStr("vi = 'Thuế GTGT:';
							|ru = 'Сумма НДС:';
							|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
							|it = 'Importo IVA:';
							|pl = 'Wartość VAT';
							|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			Else
				DataStructureTotalVAT.Insert("VAT", NStr("vi = 'Không thuế (GTGT)';
														|ru = 'Без налога (НДС)';
														|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
														|it = 'senza imposta (IVA)';
														|pl = 'bez podatku (VAT)';
														|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
			EndIf;
			TemplateArea.Parameters.Fill(DataStructureTotalVAT);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		TemplateArea = Template.GetArea("AmountInWords");
		
		TotalString = NStr("vi = 'Tổng số dịch vụ là %NumberOfTitles%, với số tiền là %DocumentAmount%';
							|ru = 'Всего оказано услуг %NumberOfTitles%, на сумму %DocumentAmount%';
							|en = 'Total amount due %DocumentAmount% for the services rendered %NumberOfTitles%'; fa = 'Total amount due %DocumentAmount% for the services rendered %NumberOfTitles%';
							|it = 'Servizi totali resi %NumberOfTitles%, per l''importo di %DocumentAmount%';
							|pl = 'Całkowita ilość świadczonych usług %NumberOfTitles%, na kwotę %DocumentAmount%';
							|tr = 'Sağlanan tüm hizmetler %NumberOfTitles%, tutar %DocumentAmount%'", Common.DefaultLanguageCode());
		TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
		TotalString = StrReplace(TotalString, "%DocumentAmount%", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		DataStructureSumInWords = New Structure;
		DataStructureSumInWords.Insert("TotalString", TotalString);
		DataStructureSumInWords.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
		TemplateArea.Parameters.Fill(DataStructureSumInWords);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Signatures");
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
EndProcedure

Function TemplateAreas(ThereAreDiscounts, ThereIsVAT)
	
	ReturnStructure = New Structure;
	
	If ThereAreDiscounts And ThereIsVAT Then
		ReturnStructure.Insert("TableHeader", "TableHeaderWithDiscountWithVAT");
		ReturnStructure.Insert("String", "LineWithDiscountWithVAT");
		ReturnStructure.Insert("StringSet", "LineWithDiscountWithVATSet");
		ReturnStructure.Insert("StringComponents", "LineWithDiscountWithVATComponents");
	ElsIf ThereAreDiscounts And Not ThereIsVAT Then
		ReturnStructure.Insert("TableHeader", "TableHeaderWithDiscount");
		ReturnStructure.Insert("String", "RowWithDiscount");
		ReturnStructure.Insert("StringSet", "RowWithDiscountSet");
		ReturnStructure.Insert("StringComponents", "RowWithDiscountComponents");
	ElsIf Not ThereAreDiscounts And ThereIsVAT Then
		ReturnStructure.Insert("TableHeader", "HeaderOfTableWithVAT");
		ReturnStructure.Insert("String", "StringWithVAT");
		ReturnStructure.Insert("StringSet", "StringWithVATSet");
		ReturnStructure.Insert("StringComponents", "StringWithVATComponents");
	Else // no discount and no VAT
		ReturnStructure.Insert("TableHeader", "TableHeader");
		ReturnStructure.Insert("String", "String");
		ReturnStructure.Insert("StringSet", "StringSet");
		ReturnStructure.Insert("StringComponents", "StringComponents");
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

#Region Other

#EndRegion

#EndRegion

#EndIf
