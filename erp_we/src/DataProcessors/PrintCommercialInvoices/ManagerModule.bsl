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
	
	SynonymForInvoiceTemplate = NStr("vi = 'Yêu cầu thanh toán';
									|ru = 'Счет на оплату';
									|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
									|it = 'Fattura di pagamento';
									|pl = 'Rachunek do zapłaty';
									|tr = 'Ticari fatura'");
	If CommonClientServer.StructureProperty(PrintParameters, "UseSynonymForKit", False) Then
		SynonymForInvoiceTemplate = PrintParameters.SynonymForTemplateForKit;
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProformaInvoice") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProformaInvoice",
			SynonymForInvoiceTemplate,
			GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceForPaymentWithoutDiscounts") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceForPaymentWithoutDiscounts",
			SynonymForInvoiceTemplate,
			GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CommercialInvoiceFacsimile") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CommercialInvoiceFacsimile",
			SynonymForInvoiceTemplate,
			GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProformaInvoiceWithFacsimile") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProformaInvoiceWithFacsimile",
			SynonymForInvoiceTemplate,
			GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CommercialInvoiceFacsimileWithoutDiscounts") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CommercialInvoiceFacsimileWithoutDiscounts",
			SynonymForInvoiceTemplate,
			GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceWithFacsimileWithoutDiscounts") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceWithFacsimileWithoutDiscounts",
			SynonymForInvoiceTemplate,
			GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PreviewOfPrintedInvoiceForm") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PreviewOfPrintedInvoiceForm",
			NStr("vi = 'Yêu cầu thanh toán';
				|ru = 'Счет на оплату';
				|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
				|it = 'Fattura di pagamento';
				|pl = 'Rachunek do zapłaty';
				|tr = 'Ticari fatura'"),
			PrintPreviewInvoiceForPayment(ObjectsArray[0], PrintObjects, "ProformaInvoice"));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceInt") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceInt",
			NStr("vi = 'Invoice';
				|ru = 'Invoice';
				|en = 'Invoice'; fa = 'فاکتور';
				|it = 'Invoice';
				|pl = 'Invoice';
				|tr = 'Invoice'"),
			CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintCommercialInvoices.PF_MXL_Invoice");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("InvoiceInt"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProformaInvoiceEn") Then
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProformaInvoiceEn",
			NStr("vi = 'Proforma invoice';
				|ru = 'Proforma invoice';
				|en = 'Proforma invoice'; fa = 'پیش‌فاکتور';
				|it = 'Proforma invoice';
				|pl = 'Proforma invoice';
				|tr = 'Proforma invoice'"),
			CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintCommercialInvoices.PF_MXL_Invoice");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("ProformaInvoiceEn"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CreditNote") Then
		
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CreditNote",
			NStr("vi = 'Credit Note';
				|ru = 'Credit Note';
				|en = 'Credit Note'; fa = 'Credit Note';
				|it = 'Credit Note';
				|pl = 'Credit Note';
				|tr = 'Credit Note'"),
			FormPrintedFormCreditNote(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintCommercialInvoices.PF_MXL_DebitCreditNote");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("CreditNote"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "DebitNote") Then
		
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"DebitNote",
			NStr("vi = 'Debit Note';
				|ru = 'Debit Note';
				|en = 'Debit Note'; fa = 'Debit Note';
				|it = 'Debit Note';
				|pl = 'Debit Note';
				|tr = 'Debit Note'"),
			CreatePrintedFormDebitNote(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintCommercialInvoices.PF_MXL_DebitCreditNote");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("DebitNote"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

#EndRegion

#Region ProformaInvoice

Function GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProformaInvoice";
	
	DocumentTypeNumber = 0;
	
	SetPrivilegedMode(True);
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedInvoiceForm(PrintParameters, ObjectsStructure.Value);
		
		FillInTabularDocumentOfInvoiceForPayment(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure FillInDetailsOfInvoiceHeader_(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, GoodsTable)
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommercialInvoices.PF_MXL_ProformaInvoice");
	
	SupplierInformation = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date);
	
	TemplateArea = Template.GetArea("InvoiceHeader_");
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "InvoiceHeaderLogo", PrintData.Organization);
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
	
	If PaymentStagesTable.Count() = 0 Then
		PaymentDate = '00010101';
	ElsIf PaymentStagesTable.Count() = 1 Then
		PaymentDate = PaymentStagesTable[0].PaymentDate;
	Else
		PaymentDate = PaymentStagesTable[PaymentStagesTable.Count()-1].PaymentDate;
	EndIf;
	
	If ValueIsFilled(PaymentDate) Then
		DataStructureHeader = New Structure;
		ExpirationDateLabel = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hóa đơn có hiệu lực đến %1.';
				|ru = 'Счет действителен до %1.';
				|en = 'Account is valid till %1.'; fa = 'Account is valid till %1.';
				|it = 'Fattura pro-forma è valida fino %1.';
				|pl = 'Rachunek jest ważny do%1.';
				|tr = '%1 kadar hesap geçerlidir.'", Common.DefaultLanguageCode()), Format(PaymentDate, "DLF=D")) + " ";
		DataStructureHeader.Insert("ValidityPeriod", ExpirationDateLabel);
		TemplateArea.Parameters.Fill(DataStructureHeader);
	EndIf;
	
	SpreadsheetDocument.Put(TemplateArea);
	
	If PrintData.PaymentAbroad Then
		
		TemplateArea = Template.GetArea("SampleFillingBankDetails");
		HeaderDataStructure_1 = New Structure;
		SupplierPresentationForErrandBoards = "";
		
		If ValueIsFilled(PrintData.BankAccount) Then
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", PrintData.BankAccountNumber);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", PrintData.BankNameInt);
			If IsBlankString(HeaderDataStructure_1.PayeeBankPresentation) Then
				HeaderDataStructure_1.Insert("PayeeBankPresentation", PrintData.BankDescription);
			EndIf; 
			HeaderDataStructure_1.Insert("AddressOfRecipientSBankPresentation", PrintData.BankAddress);
			HeaderDataStructure_1.Insert("BankSWIFTCode", PrintData.BankSWIFTCode);
			SupplierPresentationForErrandBoards = PrintData.CorrespondentTextBankAccount;
		EndIf;
		
		If IsBlankString(SupplierPresentationForErrandBoards) Then
			SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr,");
		EndIf;
		HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not IsBlankString(PrintData.BankNameForPaymentsInt) Then
			TemplateArea = Template.GetArea("SampleFillingCorrespondentBankDetails");
			
			HeaderDataStructure_1.Clear();
			HeaderDataStructure_1.Insert("RecipientSCorrespondentBankPresentation",
				PrintData.BankNameForPaymentsInt + " " + PrintData.TransferBankAddress);
			HeaderDataStructure_1.Insert("BankSWIFTCodeForPayments", PrintData.BankSWIFTCodeForPayments);
			HeaderDataStructure_1.Insert("BankAccountForSettlementsPresentation", PrintData.BankAccountForPayments);
			
			TemplateArea.Parameters.Fill(HeaderDataStructure_1);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		TemplateArea = Template.GetArea("SampleFillingPurposeOfPayment");
		HeaderDataStructure_1.Clear();
		If Not ValueIsFilled(PrintData.PaymentPurposes)
			And TypeOf(PrintData.Ref) <> Type("DocumentRef.CustomerCommercialInvoice") Then
			HeaderDataStructure_1.Insert("PaymentPurposes", Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
				PrintData.Number, PrintData.Ref, PrintData.Date));
		Else
			HeaderDataStructure_1.Insert("PaymentPurposes", PrintData.PaymentPurposes);
		EndIf;
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
	Else
		
		PaymentLinkSATPb2b = CashServerLocalization.PaymentLinkb2b(PrintData.Ref);
		
		If PrintData.ThisIsDigitalRubleAccount Then
			TemplateArea = Template.GetArea("SampleOfFillingInItemAccountCR");
		ElsIf PrintData.CounterpartyLegEntInd = Enums.LegalEntityIndividual.Person
			And ValueIsFilled(PrintData.BankAccount) Then
			TemplateArea = Template.GetArea("SampleFillingOfPPSCode");
		ElsIf PrintData.CounterpartyLegEntInd <> Enums.LegalEntityIndividual.Person
			And ValueIsFilled(PaymentLinkSATPb2b) Then
			TemplateArea = Template.GetArea("SampleFillingOfPPSCode");
		Else
			TemplateArea = Template.GetArea("SamplePPFilling");
		EndIf;
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TIN", SupplierInformation.TIN);
		HeaderDataStructure_1.Insert("CRTR",SupplierInformation.CRTR);
		SupplierPresentationForErrandBoards = "";
		
		HeaderDataStructure_1.Insert("PaymentID", PrintData.PaymentID);
		
		If ValueIsFilled(PrintData.BankAccount) Then
			
			If ValueIsFilled(PrintData.TransferBankBIC) Then
				Bank        = ?(ValueIsFilled(PrintData.NameOfBankSRCCForSettlements),
								PrintData.NameOfBankSRCCForSettlements + "//" + PrintData.TransferBankDescription,
								PrintData.TransferBankDescription);
				BIC         = PrintData.TransferBankBIC;
				CorrAccount    = PrintData.TransferBankCorrAccount;
				BankCity  = PrintData.TransferBankCity;
				AccountNumber  = PrintData.BankCorrAccount;
			Else
				Bank        = ?(ValueIsFilled(PrintData.NameOfBankSRCC),
								PrintData.NameOfBankSRCC + "//" + PrintData.BankDescription,
								PrintData.BankDescription);
				BIC         = PrintData.BICBank;
				CorrAccount    = PrintData.BankCorrAccount;
				BankCity  = PrintData.BankCity;
				AccountNumber  = PrintData.BankAccountNumber;
			EndIf;
			
			HeaderDataStructure_1.Insert("RecipientBankBIC", BIC);
			HeaderDataStructure_1.Insert("PayeeBank", Bank);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", TrimAll(Bank) + " " + BankCity);
			HeaderDataStructure_1.Insert("RecipientBankAccount", CorrAccount);
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", CorrAccount);
			HeaderDataStructure_1.Insert("RecipientAccountPresentation", AccountNumber);
			HeaderDataStructure_1.Insert("RecipientAccount", AccountNumber);
			SupplierPresentationForErrandBoards = PrintData.CorrespondentTextBankAccount;
			
		EndIf;
	
		If IsBlankString(SupplierPresentationForErrandBoards) Then
			SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr,");
		EndIf;
		
		If Not ValueIsFilled(PrintData.PaymentPurposes)
			And TypeOf(PrintData.Ref) <> Type("DocumentRef.CustomerCommercialInvoice") Then
			
			HeaderDataStructure_1.Insert("PaymentPurposes", Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
				PrintData.Number, PrintData.Ref, PrintData.Date));
			
		Else
			
			HeaderDataStructure_1.Insert("PaymentPurposes", PrintData.PaymentPurposes);
			
		EndIf;
		
		HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		If Not PrintData.ThisIsDigitalRubleAccount Then
			
			If PrintData.CounterpartyLegEntInd = Enums.LegalEntityIndividual.Person
				And ValueIsFilled(PrintData.BankAccount) Then
				
				PaymentDetails = PaymentDetailsQRCode(HeaderDataStructure_1);
				PaymentDetails.AmountAsNumber = AmountPayableOnInvoice(PrintData, GoodsTable);
				PaymentDetails.Ref = PrintData.Ref;
				
				OutputQRCode(PaymentDetails, PrintData, TemplateArea);
			
			ElsIf PrintData.CounterpartyLegEntInd <> Enums.LegalEntityIndividual.Person
				And ValueIsFilled(PaymentLinkSATPb2b) Then
				
				CodeSize = 190;
				QRCodeData = CashServerLocalization.ImageOfQRCodeSBPb2b(PrintData.Ref, CodeSize);
				
				If TypeOf(QRCodeData) = Type("BinaryData") Then
					PictureQRCode = New Picture(QRCodeData);
					TemplateArea.Drawings.QRCode.Picture = PictureQRCode;
				EndIf;
				
			EndIf;
			
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	OutputCodes = ValueIsFilled(ColumnOfCodes);
	
	Offset_ = SpreadsheetDocumentShiftType.Vertical;
	AreaOfFirstColumnOfGoods = Template.Area("FirstColumnOfGoods");
	If Not OutputCodes Then
		AreaOfFirstColumnOfGoods.ColumnWidth = AreaOfFirstColumnOfGoods.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
		Template.DeleteArea(Template.Area("ColumnOfCodes"), Offset_);
	EndIf;
	
	TemplateArea = Template.GetArea("Title");
	
	TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Yêu cầu thanh toán';
																				|ru = 'Счет на оплату';
																				|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
																				|it = 'Fattura di pagamento';
																				|pl = 'Rachunek do zapłaty';
																				|tr = 'Ticari fatura'", Common.DefaultLanguageCode()));
	HeaderDataStructure_1 = New Structure;
	HeaderDataStructure_1.Insert("TitleText", TitleText);
	TemplateArea.Parameters.Fill(HeaderDataStructure_1);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Vendor");
	
	DataStructureProvider = New Structure;
	DataStructureProvider.Insert("SupplierPresentation", 
		PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.CompanyVendor, PrintData.Date),
			"FullDescr,TIN,CRTR,LegalAddress,Phones,"));
	TemplateArea.Parameters.Fill(DataStructureProvider);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Customer");
	CustomerDataStructure = New Structure;
	CustomerDataStructure.Insert("RecipientPresentation1", 
		PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date),
			"FullDescr,TIN,CRTR,LegalAddress,Phones,"));
	TemplateArea.Parameters.Fill(CustomerDataStructure);
	SpreadsheetDocument.Put(TemplateArea);
	
	If ValueIsFilled(PrintData.Shipper) Then
		TemplateArea = Template.GetArea("Shipper");
		ShipperDataStructure = New Structure;
		ShipperDataStructure.Insert("ShipperPresentation", OrganizationDescription(PrintData, "Shipper"));
		TemplateArea.Parameters.Fill(ShipperDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	If ValueIsFilled(PrintData.GoodsRecipient) Then
		TemplateArea = Template.GetArea("GoodsRecipient");
		DataStructureConsignee = New Structure;
		DataStructureConsignee.Insert("PresentationOfConsignee", OrganizationDescription(PrintData, "GoodsRecipient"));
		TemplateArea.Parameters.Fill(DataStructureConsignee);
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
EndProcedure

Procedure FillInDetailsOfBasementOfInvoiceForPayment(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, ComplianceWithVATRates, PrintParameters)
	
	OutputValidationArray = New Array;
	
	// Display the stages of the payment schedule
	If PaymentStagesTable.Count() > 1 Then
		
		NameOfPaymentDateColumn = ?(PrintData.InvoiceToBeRefunded,
			NStr("vi = 'Ngày thanh toán hoặc trả lại';
				|ru = 'Дата оплаты или возврата';
				|en = 'Date of payment or return'; fa = 'Date of payment or return';
				|it = 'Data di pagamento o restituzione';
				|pl = 'Data płatności lub zwrotu';
				|tr = 'Ödeme veya iade tarihi'", Common.DefaultLanguageCode()),
			NStr("vi = 'Ngày thanh toán';
				|ru = 'Дата оплаты';
				|en = 'Payment date'; fa = 'تاریخ پرداخت';
				|it = 'Data di pagamento';
				|pl = 'Data płatności';
				|tr = 'Ödeme tarihi'", Common.DefaultLanguageCode()));
		
		Area_TableHeader = Template.GetArea("HeaderOfPaymentStagesTable");
		TableBasementArea = Template.GetArea("TotalPaymentStages");
		HeaderDataStructure_1 = New Structure("NameOfPaymentDateColumn",NameOfPaymentDateColumn);
		Area_TableHeader.Parameters.Fill(HeaderDataStructure_1);
		OutputValidationArray.Add(Area_TableHeader);
		OutputValidationArray.Add(TableBasementArea);
		
		AreaTableRow = Template.GetArea("RowOfPaymentStagesTable");
		
		PackageDepositValue = 0;
		For Each CurStage In PaymentStagesTable Do
			If CurStage.ThisIsDepositForPackage Then
				PackageDepositValue = PackageDepositValue + CurStage.PaymentAmount;
			EndIf;
		EndDo;
		
		StageNumber = 1;
		For Each CurStage In PaymentStagesTable Do
			
			RowParameters = NewStageLineParameters();
			FillPropertyValues(RowParameters, CurStage);
			RowParameters.LineNumber = StageNumber;
			If Not RowParameters.ThisIsDepositForPackage Then
				
				AmountToReturn = 0;
				If ValueIsFilled(PrintData.AmountToReturn) Then
					AmountToReturn = PrintData.AmountToReturn;
				EndIf;
							
				PaymentPercentage = CurStage.PaymentPercentage;
				If (AmountToReturn - PackageDepositValue) > 0 Then
					PaymentPercentage = CurStage.PaymentAmount * 100 / (AmountToReturn - PackageDepositValue);
				EndIf;
				
				RowParameters.VATText = PrintFormGeneration.GenerateTextOfVATPaymentStage(
					ComplianceWithVATRates,
					PaymentPercentage);
			Else
				RowParameters.PaymentPercentage = "-";
				RowParameters.VATText = NStr("vi = 'Đặt cọc bao bì, Không thuế (Thuế GTGT).';
											|ru = 'Залог за тару. Без налога (НДС).';
											|en = 'Packaging deposit. Without tax (VAT).'; fa = 'Packaging deposit. Without tax (VAT).';
											|it = 'Cauzione per l''imballo.senza imposta (IVA)';
											|pl = 'Zastaw na pojemnik. Bez podatku (VAT).';
											|tr = 'Depozito. Vergisiz (KDV).'", Common.DefaultLanguageCode());
			EndIf;
			
			AreaTableRow.Parameters.Fill(RowParameters);
			
			OutputValidationArray.Add(AreaTableRow);
			
			If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
				If StageNumber = 1 Then
					SpreadsheetDocument.Put(Area_TableHeader);
					OutputValidationArray.Delete(0);
				EndIf;
			Else
				SpreadsheetDocument.PutHorizontalPageBreak();
				SpreadsheetDocument.Put(Area_TableHeader);
			EndIf;
			
			SpreadsheetDocument.Put(AreaTableRow);
			OutputValidationArray.Delete(OutputValidationArray.UBound());
			
			StageNumber = StageNumber + 1;
			
		EndDo;
		SpreadsheetDocument.Put(TableBasementArea);
		
	EndIf;
	
	// Display additional information
	If ValueIsFilled(PrintData.AdditionalInformation) Then
		
		Area = Template.GetArea("AdditionalInformation");
		Area.Parameters.Fill(PrintData);
		SpreadsheetDocument.Put(Area);
		
	EndIf;
	
	JobTitleExecutive = ?(PrintData.JobTitleExecutive = "", 
								NStr("vi = 'Tổng giám đốc';
									|ru = 'Генеральный директор';
									|en = 'CEO'; fa = 'مدیرعامل';
									|it = 'Direttore generale';
									|pl = 'Dyrektor generalny';
									|tr = 'Genel CEO'"), 
								PrintData.JobTitleExecutive);
	
	// Output signatures
	Area = Template.GetArea("BasementAccounts");
	BasementDataStructure = New Structure;
	BasementDataStructure.Insert("ManagerSFullName_", PrintData.Director);
	BasementDataStructure.Insert("JobTitleExecutive", JobTitleExecutive);
	BasementDataStructure.Insert("AccountantSFullName", PrintData.ChiefAccountant);
	BasementDataStructure.Insert("ManagerSFullName", PersonsTM.IndividualShortName(PrintData.Manager, PrintData.Date));
	Area.Parameters.Fill(BasementDataStructure);
	
	PrintFormGeneration.OutputFacsimileToTabularDocument(Template, Area, PrintData.Organization, PrintParameters);
	OutputValidationArray.Clear();
	OutputValidationArray.Add(Area);
	If Not SpreadsheetDocument.CheckPut(OutputValidationArray) Then
		SpreadsheetDocument.PutHorizontalPageBreak();
	EndIf;
	SpreadsheetDocument.Put(Area);
	
EndProcedure

// Parameters:
//	SpreadsheetDocument           - SpreadsheetDocument -
//	DataForPrint             - Structure - It contains data on the document header, payment stages, and tabular part:
//		* HeaderResults          - QueryResult -
//		* ResultsByPaymentStages   - QueryResult -
//		* ResultForTabularPart - QueryResult -
//	PrintObjects               - See PrintManagementOverridable.OnPrint.PrintObjects
//	PrintParameters             - See PrintManagementOverridable.OnPrint.PrintParameters
//
Procedure FillInTabularDocumentOfInvoiceForPayment(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters)
	
	ErrorPatterns = New Structure;
	ErrorPatterns.Insert("Goods", NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in hóa đơn thanh toán';
										|ru = 'В документе %1 отсутствуют товары. Печать счета на оплату не требуется';
										|en = 'Goods are missing in the %1 document. It is not required to print the commercial invoice'; fa = 'Goods are missing in the %1 document. It is not required to print the commercial invoice';
										|it = 'Il documento %1 non contiene le merci. La stampa della fattura pro-forma non è richiesta';
										|pl = 'W dokumencie %1 nie ma towarów. Wydruk faktury nie jest wymagany';
										|tr = '%1 belgesinde ürün bulunmamaktadır. Ticari faturanın yazdırılması gerekli değildir'"));
	ErrorPatterns.Insert("SubstituteGoods", NStr("vi = 'Trong chứng từ %1 không có hàng hóa thay thế. Không cần in hóa đơn thanh toán';
												|ru = 'В документе %1 отсутствуют заменяющие товары. Печать счета на оплату не требуется';
												|en = 'Exchange goods are missing in the %1 document. It is not required to print the commercial invoice'; fa = 'Exchange goods are missing in the %1 document. It is not required to print the commercial invoice';
												|it = 'Nel documento %1 mancano le merci scambiabili. La stampa della fattura pro-forma non è richiesta';
												|pl = 'W dokumencie %1 nie ma zastępczych towarów. Wydruk faktury nie jest wymagany';
												|tr = '%1 belgesinde yedek kalem bulunmamaktadır. Ticari faturanın yazdırılması gerekli değildir'"));
	ErrorPatterns.Insert("Stages", NStr("vi = 'Trong chứng từ %1 không có giai đoạn thanh toán. Không cần in hóa đơn thanh toán';
										|ru = 'В документе %1 отсутствуют этапы оплаты. Печать счета на оплату не требуется';
										|en = 'Payment milestones are missing in the %1 document. It is not required to print the commercial invoice'; fa = 'Payment milestones are missing in the %1 document. It is not required to print the commercial invoice';
										|it = 'Nel documento %1 mancano le fasi di pagamento. La stampa della fattura pro-forma non è richiesta';
										|pl = 'W dokumencie %1 nie ma etapów płatności. Wydruk faktury nie jest wymagany';
										|tr = '%1 belgesinde herhangi bir ödeme aşaması bulunmamaktadır. Ticari fatura yazdırılması gerekli değildir'"));
	
	VATAccountingIsUsed = GetFunctionalOption("UseVATAccounting");
	UseManualDiscounts         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseAutomaticDiscounts = GetFunctionalOption("UseDiscountsMarkupsInSales");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	StructureColumnName = New Structure("NameOfCodeColumn, PresentationOfCodesColumn", NameOfCodeColumn, PresentationOfCodesColumn);
	
	PrintData = DataForPrint.HeaderResults.Select();
	PaymentSteps = DataForPrint.ResultsByPaymentStages.Unload();
	Goods = DataForPrint.ResultForTabularPart.Unload();
	
	StagesOfPledgePackaging = PaymentSteps.FindRows(New Structure("ThisIsDepositForPackage", True));
	OnlyDepositForContainer = StagesOfPledgePackaging.Count() = PaymentSteps.Count() And StagesOfPledgePackaging.Count() > 0;
	
	If Goods.Columns.Find("Content")=Undefined Then
		ThereIsContent = False;
	Else
		ThereIsContent = True;
	EndIf;
	
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		Cancel = False;
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		
		UseSets = False;
		If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
		EndIf;
		
		GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
		PaymentStagesTable = PaymentSteps.FindRows(TheStructureOfTheSearch);
		
		CheckingDocumentFilling(PrintData, GoodsTable, PaymentStagesTable, ErrorPatterns, Cancel, True);
		If Cancel Then
			Continue;
		EndIf;
		
		If FirstDocument Then
			FirstDocument = False;
		Else
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(GoodsTable, UseManualDiscounts Or UseAutomaticDiscounts);
		ThereAreDiscounts = DiscountHeader.ThereAreDiscounts;
		
		NamesOfRegions = NamesOfRegions(PrintData.ConsiderVAT And Not OnlyDepositForContainer And ShowVAT, ThereAreDiscounts);
		
		Template = New SpreadsheetDocument;
		FillInDetailsOfInvoiceHeader_(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, GoodsTable);
		
		If PrintData.PartialPayment Or TypeOf(PrintData.DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor") Then
			
			Area_TableHeader = Template.GetArea("PartialPaymentTableHeader");
			SpreadsheetDocument.Put(Area_TableHeader);
			
			AreaTableRow = Template.GetArea("TableRowPartialPayment");
			AreaTableRow.Parameters.Fill(PrintData);
			AreaTableRow.Parameters.LineNumber = 1;
			SpreadsheetDocument.Put(AreaTableRow);
			
			AreaTotal = Template.GetArea("BasementTablePartialPayment");
			DataStructureTotal = New Structure;
			DataStructureTotal.Insert("Total", PrintData.DocumentAmount);
			AreaTotal.Parameters.Fill(DataStructureTotal);
			AreaTotal.Parameters.Fill(PrintData);
			SpreadsheetDocument.Join(AreaTotal);
			
			// Output the total of the ADS
			ComplianceWithVATRates = New Map;
			If PrintData.ConsiderVAT And Not OnlyDepositForContainer 
				And Not PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
				RegionTotalVAT = Template.GetArea("VATTableBasement");
				
				If GoodsTable.Count() = 0 Then
					If ValueIsFilled(PrintData.VATRate) Then
						VATAmount = PrintData.VATAmount;
						ComplianceWithVATRates.Insert(PrintData.VATRate, VATAmount);
					EndIf;
				Else
					For Each RowOfProduct In GoodsTable Do
						If UseSets And RowOfProduct.IsRecordsSet
							And Not (RowOfProduct.PresentationOptionInPrintForms = 
								Enums.OptionsOfSetPresentationInPrintForms.OnlySet) Then
							// We exclude VAT amounts for the set as a whole when components are displayed in printed forms.
							Continue;
						EndIf;
						VATAmount = ComplianceWithVATRates[RowOfProduct.VATRate];
						If VATAmount = Undefined Then
							VATAmount = RowOfProduct.VATAmount;
						Else
							VATAmount = VATAmount + RowOfProduct.VATAmount;
						EndIf;
						ComplianceWithVATRates.Insert(RowOfProduct.VATRate, VATAmount);
					EndDo;
				EndIf;
				
				PackageDepositValue = 0;
				For Each CurStage In PaymentStagesTable Do
					If CurStage.ThisIsDepositForPackage Then
						PackageDepositValue = PackageDepositValue + CurStage.PaymentAmount;
					EndIf;
				EndDo;
				
				If ComplianceWithVATRates.Count() > 0 Then
					For Each CurVATRate In ComplianceWithVATRates Do
						DataStructureTotalVAT = New Structure;
						DataStructureTotalVAT.Insert("VAT", PrintFormGeneration.VATRateText(CurVATRate.Key, PrintData.PriceIncludesVAT));
						If ValueIsFilled(CurVATRate.Value) Then
							
							AmountToReturn = 0;
							If ValueIsFilled(PrintData.AmountToReturn) Then
								AmountToReturn = PrintData.AmountToReturn;
							EndIf;
							
							PayPercentage = PrintData.PayPercentage;
							If (AmountToReturn - PackageDepositValue) > 0 Then
								PayPercentage = (PrintData.DocumentAmount - PackageDepositValue) * 100 / (AmountToReturn - PackageDepositValue);
							EndIf;
							DataStructureTotalVAT.Insert("TotalVAT", PrintFormGeneration.SumFormat(CurVATRate.Value /100 * PayPercentage));
							
						Else
							DataStructureTotalVAT.Insert("TotalVAT","-");
						EndIf;
						RegionTotalVAT.Parameters.Fill(DataStructureTotalVAT);
						SpreadsheetDocument.Put(RegionTotalVAT);
					EndDo;
					AreaBasementWithVAT = Template.GetArea("BasementTablesOfEverything");
					DataStructureBasementWithVAT = New Structure("TotalWithVAT", PrintFormGeneration.SumFormat(PrintData.DocumentAmount));
					AreaBasementWithVAT.Parameters.Fill(DataStructureBasementWithVAT);
					SpreadsheetDocument.Put(AreaBasementWithVAT);
				EndIf;
			ElsIf VATAccountingIsUsed Then
				DataStructureVATBasement = New Structure;
				If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
					DataStructureVATBasement.Insert("VAT", NStr("vi = 'Thuế GTGT trích đại lý thuế';
																|ru = 'НДС исчисляется налоговым агентом';
																|en = 'VAT is calculated by tax agent'; fa = 'مالیات بر ارزش افزوده توسط عامل مالیاتی محاسبه می‌شود';
																|it = 'L''IVA viene calcolata dall''agente tributario';
																|pl = 'VAT jest obliczany przez agenta podatkowego';
																|tr = 'KDV, vergi memuru tarafından hesaplanır'", Common.DefaultLanguageCode()));
				Else
					DataStructureVATBasement.Insert("VAT", NStr("vi = 'Không thuế (GTGT)';
																|ru = 'Без налога (НДС)';
																|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
																|it = 'senza imposta (IVA)';
																|pl = 'bez podatku (VAT)';
																|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
				EndIf;
				VATBasementArea             = Template.GetArea("VATTableBasement");
				DataStructureVATBasement.Insert("TotalVAT", "-");
				VATBasementArea.Parameters.Fill(DataStructureVATBasement);
				SpreadsheetDocument.Put(VATBasementArea);
			EndIf;
			
			// Withdraw the Amount in words
			TemplateArea = Template.GetArea("AmountInWordsPartialInvoice");
			AmountInWords = NStr("vi = 'Tổng số tiền %AmountInWords%';
								|ru = 'Всего на сумму %AmountInWords%';
								|en = 'Total in the amount of %AmountInWords%'; fa = 'Total in the amount of %AmountInWords%';
								|it = 'Totale per la somma di %AmountInWords%';
								|pl = 'Razem w wysokości %AmountInWords%';
								|tr = 'Toplam tutar %AmountInWords%'", Common.DefaultLanguageCode());
			AmountInWords = StrReplace(AmountInWords, "%AmountInWords%", ProcessingOfExchangeRatesTM.GenerateAmountInWords(PrintData.DocumentAmount, PrintData.Currency));
			DataStructureSumInWords = New Structure("AmountInWords", AmountInWords);
			TemplateArea.Parameters.Fill(DataStructureSumInWords);
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
		
			// The "Products" table
			Area_TableHeader          = Template.GetArea(NamesOfRegions.TableHeader);
			AreaTableRowStandard = Template.GetArea(NamesOfRegions.TableRow);
			TableBasementArea         = Template.GetArea(NamesOfRegions.TableFooter);
			VATBasementArea             = Template.GetArea("VATTableBasement");
			
			If UseSets Then
				AreaTableRowSet         = Template.GetArea(NamesOfRegions.TableRowSet);
				AreaTableRowComponents = Template.GetArea(NamesOfRegions.TableRowComponents);
			EndIf;
			
			BlankData = SetsServer.BlankData();
			HeaderOutput = 0;
			
			If PrintData.ConsiderVAT And Not OnlyDepositForContainer Then
				If ThereAreDiscounts Then
					AreaBasementWithVAT = Template.GetArea("TableBasementTotalWithVATAtDiscount");
				Else
					AreaBasementWithVAT = Template.GetArea("TotalWithVATTableBasement");
				EndIf
			EndIf;
			
			If ThereAreDiscounts Then
				StructureOfDiscountHeader = New Structure("Discount, AmountWithoutADiscount", 
					DiscountHeader.Discount,
					DiscountHeader.DiscountAmount);
				Area_TableHeader.Parameters.Fill(StructureOfDiscountHeader);
			EndIf; 
			Area_TableHeader.Parameters.Fill(StructureColumnName);
			RegionAmountInWords = Template.GetArea(?(PrintData.InvoiceToBeRefunded, "AmountInWordsToBeRefunded", "AmountInWords"));
			
			OutputValidationArray = New Array;
			
			Sum = 0;
			VATAmount = 0;
			TotalOfDiscounts = 0;
			TotalWithoutDiscounts = 0;
			LineNumber = 0;
			ComplianceWithVATRates = New Map;
			For Each LineProducts_ In GoodsTable Do
				
				If SetsServer.UseSetArea(LineProducts_, UseSets) Then
					AreaTableRow = AreaTableRowSet;
				ElsIf SetsServer.UseScope(LineProducts_, UseSets) Then
					AreaTableRow = AreaTableRowComponents;
				Else
					AreaTableRow = AreaTableRowStandard;
				EndIf;
				
				If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
					LineNumberPrint = "";
				Else
					LineNumber = LineNumber + 1;
					LineNumberPrint = LineNumber;
				EndIf;
				
				If LineNumber = 0 And HeaderOutput <> 2 Then
					HeaderOutput = 1;
				EndIf;
				
				PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(LineProducts_, UseSets);
				
				AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersForGettingNameToPrint.ReturnContainers = LineProducts_.ThisIsReusablePackage;
				AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
				If ThereIsContent Then
					AdditionalParametersForGettingNameToPrint.Content = LineProducts_.Content;
				EndIf;
				
				OwnGoods = PrefixAndPostfix.Prefix
						+ ProductsClientServer.PresentationOfProductsForPrinting(
															LineProducts_.DescriptionFull,
															LineProducts_.Characteristic,
															,
															, // Series
															AdditionalParametersForGettingNameToPrint)
						+ PrefixAndPostfix.Postfix;
						
				StringDataStructure = New Structure;
				StringDataStructure.Insert("OwnGoods", OwnGoods);
				StringDataStructure.Insert("LineNumber", LineNumberPrint);
				AreaTableRow.Parameters.Fill(LineProducts_);
				If DiscountHeader.ThereAreDiscounts Then
					StringDataStructure.Insert("DiscountAmount",
						?(DiscountHeader.OnlyMarkUp,- LineProducts_.DiscountAmount,LineProducts_.DiscountAmount));
				EndIf;
				
				If ValueIsFilled(StructureColumnName.NameOfCodeColumn) Then
					StringDataStructure.Insert("SKU", LineProducts_[StructureColumnName.NameOfCodeColumn]);
				EndIf;
				
				If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
					StringDataStructure.Insert("VATRate", NStr("vi = 'Thuế GTGT trích đại lý thuế';
																|ru = 'НДС исчисляется налоговым агентом';
																|en = 'VAT is calculated by tax agent'; fa = 'مالیات بر ارزش افزوده توسط عامل مالیاتی محاسبه می‌شود';
																|it = 'L''IVA viene calcolata dall''agente tributario';
																|pl = 'VAT jest obliczany przez agenta podatkowego';
																|tr = 'KDV, vergi memuru tarafından hesaplanır'", Common.DefaultLanguageCode()));
				EndIf;
				
				AreaTableRow.Parameters.Fill(StringDataStructure);
				
				If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
					AreaTableRow.Parameters.Fill(BlankData);
				EndIf;
				
				OutputValidationArray.Clear();
				OutputValidationArray.Add(AreaTableRow);
				If LineNumber = GoodsTable.Count() Then
					OutputValidationArray.Add(TableBasementArea);
					OutputValidationArray.Add(VATBasementArea);
					OutputValidationArray.Add(RegionAmountInWords);
				EndIf;
				
				If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
					If (LineNumber = 1 And HeaderOutput = 0) Or (LineNumber = 0 And HeaderOutput = 1) Then
						HeaderOutput = 2;
						SpreadsheetDocument.Put(Area_TableHeader);
					EndIf;
				Else
					SpreadsheetDocument.PutHorizontalPageBreak();
					SpreadsheetDocument.Put(Area_TableHeader);
				EndIf;
				
				SpreadsheetDocument.Put(AreaTableRow);
				
				If Not SetsServer.UseScope(LineProducts_, UseSets) Then
					
					Sum = Sum + LineProducts_.Sum;
					VATAmount = VATAmount + LineProducts_.VATAmount;
					
					If ThereAreDiscounts Then
						TotalOfDiscounts = TotalOfDiscounts + LineProducts_.DiscountAmount;
						TotalWithoutDiscounts = TotalWithoutDiscounts + LineProducts_.AmountWithoutADiscount;
					EndIf;
				
					If PrintData.ConsiderVAT And Not OnlyDepositForContainer Then
						AmountOfVATAtRate = ComplianceWithVATRates[LineProducts_.VATRate];
						If AmountOfVATAtRate = Undefined Then
							AmountOfVATAtRate = 0;
						EndIf;
						ComplianceWithVATRates.Insert(LineProducts_.VATRate, AmountOfVATAtRate + LineProducts_.VATAmount);
					EndIf;
				
				EndIf;
				
			EndDo;
			
			DataStructureOfWholeDiscount = New Structure;
			
			// The basement of the "Products" table
			If ThereAreDiscounts Then
				DataStructureOfWholeDiscount.Insert("TotalOfDiscounts", ?(DiscountHeader.OnlyMarkUp,-TotalOfDiscounts, TotalOfDiscounts));
				DataStructureOfWholeDiscount.Insert("TotalWithoutDiscounts", TotalWithoutDiscounts);
				If PrintData.ConsiderVAT And Not OnlyDepositForContainer Then
					DataStructureOfWholeDiscount.Insert("TotalAmountOfVAT", VATAmount);
				EndIf;
			EndIf;
			DataStructureOfWholeDiscount.Insert("Total", PrintFormGeneration.SumFormat(Sum));
			TableBasementArea.Parameters.Fill(DataStructureOfWholeDiscount);
			SpreadsheetDocument.Put(TableBasementArea);
			
			// The "Basement Tables" area
			If PrintData.ConsiderVAT And Not OnlyDepositForContainer And Not PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
				
				For Each CurVATRate In ComplianceWithVATRates Do
					
					DataStructureVATBasement = New Structure;
					DataStructureVATBasement.Insert("VAT", PrintFormGeneration.VATRateText(CurVATRate.Key, PrintData.PriceIncludesVAT));
					DataStructureVATBasement.Insert("TotalVAT", PrintFormGeneration.SumFormat(CurVATRate.Value, ,"-"));
					VATBasementArea.Parameters.Fill(DataStructureVATBasement);
					SpreadsheetDocument.Put(VATBasementArea);
					
				EndDo;
				
				DataStructureVATBasement = New Structure;
				DataStructureVATBasement.Insert("TotalWithVAT", PrintFormGeneration.SumFormat(Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount)));
				AreaBasementWithVAT.Parameters.Fill(DataStructureVATBasement);
				SpreadsheetDocument.Put(AreaBasementWithVAT);
				
			ElsIf VATAccountingIsUsed Then
				DataStructureVATBasement = New Structure;
				If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
					DataStructureVATBasement.Insert("VAT", NStr("vi = 'Thuế GTGT trích đại lý thuế';
																|ru = 'НДС исчисляется налоговым агентом';
																|en = 'VAT is calculated by tax agent'; fa = 'مالیات بر ارزش افزوده توسط عامل مالیاتی محاسبه می‌شود';
																|it = 'L''IVA viene calcolata dall''agente tributario';
																|pl = 'VAT jest obliczany przez agenta podatkowego';
																|tr = 'KDV, vergi memuru tarafından hesaplanır'", Common.DefaultLanguageCode()));
				Else
					DataStructureVATBasement.Insert("VAT", NStr("vi = 'Không thuế (GTGT)';
																|ru = 'Без налога (НДС)';
																|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
																|it = 'senza imposta (IVA)';
																|pl = 'bez podatku (VAT)';
																|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
				EndIf;
				DataStructureVATBasement.Insert("TotalVAT", "-");
				VATBasementArea.Parameters.Fill(DataStructureVATBasement);
				SpreadsheetDocument.Put(VATBasementArea);
			EndIf;
			
			// Withdraw the Amount in words
			AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
			TotalString = NStr("vi = 'Tổng số mục %Count%, Số tiền %Sum%';
								|ru = 'Всего наименований %Count%, на сумму %Sum%';
								|en = 'Total number of names %Count% in the amount of %Sum%'; fa = 'Total number of names %Count% in the amount of %Sum%';
								|it = 'Totale articoli %Count%, per l''importo di %Sum%';
								|pl = 'Razem pozycji %Count%, o wartości%Sum%';
								|tr = 'Toplam tanım %Count%, tutar %Sum%'", Common.DefaultLanguageCode());
			TotalString = StrReplace(TotalString, "%Count%", LineNumber);
			TotalString = StrReplace(TotalString, "%Sum%",      PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
			
			DataStructureSumInWords = New Structure;
			If PrintData.InvoiceToBeRefunded Then
				
				AmountToReturn = 0;
				If ValueIsFilled(PrintData.AmountToReturn) Then
					AmountToReturn = PrintData.AmountToReturn;
				EndIf;
				
				TotalAmount__ = AmountToBeRegistered-AmountToReturn;
				If TotalAmount__ < 0 Then
					TotalAmount__ = 0;
				EndIf;
				DataStructureSumInWords.Insert("ReturnAmount", PrintFormGeneration.SumFormat(AmountToReturn, PrintData.Currency));
				DataStructureSumInWords.Insert("TotalAmountPayable", PrintFormGeneration.SumFormat(TotalAmount__, PrintData.Currency, "0"));
				DataStructureSumInWords.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(TotalAmount__, PrintData.Currency));
			Else
				
				DataStructureSumInWords.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
			EndIf;
			
			DataStructureSumInWords.Insert("TotalString", TotalString);
			RegionAmountInWords.Parameters.Fill(DataStructureSumInWords);
			SpreadsheetDocument.Put(RegionAmountInWords);
		EndIf;
		FillInDetailsOfBasementOfInvoiceForPayment(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, ComplianceWithVATRates, PrintParameters);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
EndProcedure

Function NamesOfRegions(WithVAT, WithDiscount)
	
	ReturnStructure = New Structure(
		"TableFooter, TableRow, TableHeader, TableRowComponents, TableRowSet");
	
	If WithVAT And WithDiscount Then
		ReturnStructure.TableFooter = "BasementTableWithVATAtDiscount";
		ReturnStructure.TableRow = "RowOfTableWithVATAtDiscount";
		ReturnStructure.TableHeader = "HeaderOfWithVATTableAtDiscount";
		ReturnStructure.TableRowComponents = "RowOfTableWithVATAtDiscountComponents";
		ReturnStructure.TableRowSet = "RowOfTableWithVATAtDiscountSet";
	ElsIf Not WithVAT And WithDiscount Then
		ReturnStructure.TableFooter = "BasementTablesAtDiscount";
		ReturnStructure.TableRow = "TableRowWithDiscount";
		ReturnStructure.TableHeader = "TableHeaderWithDiscount";
		ReturnStructure.TableRowComponents = "TableRowWithDiscountComponents";
		ReturnStructure.TableRowSet = "TableRowWithDiscountSet";
	ElsIf WithVAT And Not WithDiscount Then
		ReturnStructure.TableFooter = "BasementTableWithVAT";
		ReturnStructure.TableRow = "TableRowWithVAT";
		ReturnStructure.TableHeader = "HeaderOfTableWithVAT";
		ReturnStructure.TableRowComponents = "TableRowWithVATComponents";
		ReturnStructure.TableRowSet = "TableRowWithVATSet";
	ElsIf Not WithVAT And Not WithDiscount Then
		ReturnStructure.TableFooter = "TableFooter";
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.TableHeader = "TableHeader";
		ReturnStructure.TableRowComponents = "TableRowComponents";
		ReturnStructure.TableRowSet = "TableRowSet";
	EndIf;
	
	Return ReturnStructure
	
EndFunction

Function PrintPreviewInvoiceForPayment(Organization, PrintObjects, TemplateName)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProformaInvoice";
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommercialInvoices.PF_MXL_ProformaInvoice");
	TemplateArea = Template.GetArea("InvoiceHeader_");
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "InvoiceHeaderLogo", Organization);
	
	RefToNew = Documents.CustomerCommercialInvoice.GetRef(New UUID);
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, RefToNew);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	OutputCodes = ValueIsFilled(ColumnOfCodes);
	StructureColumnName = New Structure("NameOfCodeColumn, PresentationOfCodesColumn", NameOfCodeColumn, PresentationOfCodesColumn);
	WithdrawVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	Offset_ = SpreadsheetDocumentShiftType.Vertical;
	AreaOfFirstColumnOfGoods = Template.Area("FirstColumnOfGoods");
	If Not OutputCodes Then
		AreaOfFirstColumnOfGoods.ColumnWidth = AreaOfFirstColumnOfGoods.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
		Template.DeleteArea(Template.Area("ColumnOfCodes"), Offset_);
	EndIf;
	
	SupplierInformation = PrintFormGeneration.InformationAboutLegalEntity(Organization, CurrentSessionDate());
	PaymentDate = CurrentSessionDate();
	
	HeaderDataStructure_1 = New Structure;
	If ValueIsFilled(PaymentDate) Then
		ExpirationDateLabel = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hóa đơn có hiệu lực đến %1.';
				|ru = 'Счет действителен до %1.';
				|en = 'Account is valid till %1.'; fa = 'Account is valid till %1.';
				|it = 'Fattura pro-forma è valida fino %1.';
				|pl = 'Rachunek jest ważny do%1.';
				|tr = '%1 kadar hesap geçerlidir.'", Common.DefaultLanguageCode()), Format(PaymentDate, "DLF=D")) + " ";
		HeaderDataStructure_1.Insert("ValidityPeriod", ExpirationDateLabel);
	EndIf;
	
	HeaderDataStructure_1.Insert("TIN", SupplierInformation.TIN);
	HeaderDataStructure_1.Insert("CRTR",SupplierInformation.CRTR);
	SupplierPresentationForErrandBoards = "";
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	If ValueIsFilled(BankAccount) Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	ISNULL(BankAccounts.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
			|	CASE
			|		WHEN ISNULL(BankAccounts.DigitalRoubleAccount, FALSE)
			|			THEN BankAccounts.DigitalRoubleAccountID
			|		ELSE BankAccounts.AccountNumber 
			|	END AS AccountNumber,
			|	CASE
			|		WHEN BankAccounts.ManualBankDetailsChange
			|			THEN BankAccounts.BankDescription
			|		ELSE BankAccounts.Bank.Description
			|	END AS BankDescription,
			|	CASE
			|		WHEN BankAccounts.ManualBankDetailsChange
			|			THEN BankAccounts.BankBIC
			|		ELSE BankAccounts.Bank.Code
			|	END AS TransferBankBIC,
			|	CASE
			|		WHEN BankAccounts.ManualBankDetailsChange
			|			THEN BankAccounts.BankCorrAccount
			|		ELSE BankAccounts.Bank.CorrAccount
			|	END AS BankCorrAccount,
			|	CASE
			|		WHEN BankAccounts.ManualBankDetailsChange
			|			THEN BankAccounts.BankCity
			|		ELSE BankAccounts.Bank.City
			|	END AS TransferBankCity,
			|	BankAccounts.CorrespondentText AS CorrespondentText
			|FROM
			|	Catalog.CompaniesBankAccounts AS BankAccounts
			|WHERE
			|	BankAccounts.TransferBank = VALUE(Catalog.BankClassifier.EmptyRef)
			|	AND BankAccounts.Ref = &BankAccount
			|
			|UNION ALL
			|
			|SELECT
			|	FALSE,
			|	BankAccounts.Bank.CorrAccount,
			|	CASE
			|		WHEN BankAccounts.TransferBankDetailsManualEdit
			|			THEN BankAccounts.TransferBankDescription
			|		ELSE BankAccounts.TransferBank.Description
			|	END,
			|	CASE
			|		WHEN BankAccounts.TransferBankDetailsManualEdit
			|			THEN BankAccounts.TransferBankBIC
			|		ELSE BankAccounts.TransferBank.Code
			|	END,
			|	CASE
			|		WHEN BankAccounts.TransferBankDetailsManualEdit
			|			THEN BankAccounts.TransferBankCorrAccount
			|		ELSE BankAccounts.TransferBank.CorrAccount
			|	END,
			|	CASE
			|		WHEN BankAccounts.TransferBankDetailsManualEdit
			|			THEN BankAccounts.TransferBankCity
			|		ELSE BankAccounts.TransferBank.City
			|	END,
			|	BankAccounts.CorrespondentText
			|FROM
			|	Catalog.CompaniesBankAccounts AS BankAccounts
			|WHERE
			|	BankAccounts.TransferBank <> VALUE(Catalog.BankClassifier.EmptyRef)
			|	AND BankAccounts.Ref = &BankAccount";
			
		Query.SetParameter("BankAccount", BankAccount);
		AccountAttributes = Query.Execute().Select();
		
		If AccountAttributes.Next() Then
			HeaderDataStructure_1.Insert("RecipientBankBIC", AccountAttributes.TransferBankBIC);
			HeaderDataStructure_1.Insert("PayeeBank", AccountAttributes.BankDescription);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", TrimAll(AccountAttributes.BankDescription) + " " + AccountAttributes.TransferBankCity);
			HeaderDataStructure_1.Insert("RecipientBankAccount", AccountAttributes.BankCorrAccount);
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", AccountAttributes.BankCorrAccount);
			HeaderDataStructure_1.Insert("RecipientAccountPresentation", AccountAttributes.AccountNumber);
			HeaderDataStructure_1.Insert("RecipientAccount", AccountAttributes.AccountNumber);
			SupplierPresentationForErrandBoards = AccountAttributes.CorrespondentText;
		EndIf;
	EndIf;
	
	If IsBlankString(SupplierPresentationForErrandBoards) Then
		SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr,");
	EndIf;
	
	HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
	HeaderDataStructure_1.Insert("PaymentPurposes", NStr("vi = 'Xem trước khi in hóa đơn thanh toán.';
														|ru = 'Предварительный просмотр печати счета на оплату.';
														|en = 'Preview of commercial invoice printing.'; fa = 'Preview of commercial invoice printing.';
														|it = 'Anteprima di pagamento della fattura.';
														|pl = 'Podgląd wydruku faktury.';
														|tr = 'Ticari fatura yazdırılmasının önizleme.'", Common.DefaultLanguageCode()));
	
	TemplateArea.Parameters.Fill(HeaderDataStructure_1);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Title");
	
	HeaderData = New Structure;
	HeaderData.Insert("Number", "00000000001");
	HeaderData.Insert("Date", PaymentDate);
	HeaderData.Insert("Presentation", NStr("vi = 'Yêu cầu thanh toán';
											|ru = 'Счет на оплату';
											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
											|it = 'Fattura di pagamento';
											|pl = 'Rachunek do zapłaty';
											|tr = 'Ticari fatura'", Common.DefaultLanguageCode()));
	
	TitleText = TMCommonUseClientServer.GenerateDocumentTitle(HeaderData,
		NStr("vi = 'Yêu cầu thanh toán';
			|ru = 'Счет на оплату';
			|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
			|it = 'Fattura di pagamento';
			|pl = 'Rachunek do zapłaty';
			|tr = 'Ticari fatura'", Common.DefaultLanguageCode()));
	HeaderDataStructure_1 = New Structure;
	HeaderDataStructure_1.Insert("TitleText", TitleText);
	TemplateArea.Parameters.Fill(HeaderDataStructure_1);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Vendor");
	
	DataStructureProvider = New Structure;
	DataStructureProvider.Insert("SupplierPresentation", 
		PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(Organization, PaymentDate),
			"FullDescr,TIN,CRTR,LegalAddress,Phones,"));
	TemplateArea.Parameters.Fill(DataStructureProvider);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Customer");
	CustomerDataStructure = New Structure;
	CustomerDataStructure.Insert("RecipientPresentation1", 
		NStr("vi = 'Trường có chứa thông tin của người nhận: tên gọi đầy đủ, MST, MĐK, pháp nhân, điện thoại.';
			|ru = 'Поле содержит информацию покупателя: полное наименование, ИНН, КПП, юридический адрес, телефоны.';
			|en = 'Field contains customer information: full name, TIN, KPP, legal address, phones.'; fa = 'Field contains customer information: full name, TIN, KPP, legal address, phones.';
			|it = 'Questo campo contiene le informazioni dell''acquirente: nome completo, codice fiscale,codice ATECO, indirizzo legale, numeri di telefono.';
			|pl = 'Pole zawiera informacje nabywcy: pełną nazwę, NIP, KPW, adres rejestrowy, telefony.';
			|tr = 'Alan, alıcının bilgilerini içerir: tam ad, VKN, KPP, yasal adres, telefonlar.'", Common.DefaultLanguageCode()));
	TemplateArea.Parameters.Fill(CustomerDataStructure);
	SpreadsheetDocument.Put(TemplateArea);
	
	If WithdrawVAT Then
		TemplateArea = Template.GetArea("HeaderOfTableWithVAT");
	Else
		TemplateArea = Template.GetArea("TableHeader");
	EndIf;
	TemplateArea.Parameters.Fill(StructureColumnName);
	SpreadsheetDocument.Put(TemplateArea);
	
	If WithdrawVAT Then
		TemplateArea = Template.GetArea("TableRowWithVAT");
	Else
		TemplateArea = Template.GetArea("TableRow");
	EndIf;
	Goods = New Structure;
	Goods.Insert("LineNumber",      1);
	Goods.Insert("SKU",          "ART-000001");
	Goods.Insert("Code",              "000001");
	Goods.Insert("OwnGoods",            NStr("vi = 'Hàng hóa (xem trước)';
											|ru = 'Товар (предварительный просмотр)';
											|en = 'Goods (preview)'; fa = 'Goods (preview)';
											|it = 'Merce (visione anteprima)';
											|pl = 'Towar (podgląd)';
											|tr = 'Ürün (önizleme)'", Common.DefaultLanguageCode()));
	Goods.Insert("Count",       1);
	Goods.Insert("UnitOfMeasure", NStr("vi = 'chiếc';
										|ru = 'шт';
										|en = 'pcs.'; fa = 'عدد';
										|it = 'pz.';
										|pl = 'pcs.';
										|tr = 'parça'", Common.DefaultLanguageCode()));
	Goods.Insert("Price",             120.00);
	Goods.Insert("VATRate",        "20%");
	Goods.Insert("VATAmount",         20.00);
	Goods.Insert("Sum",            120.00);
	
	TemplateArea.Parameters.Fill(Goods);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("BasementTablePartialPayment");
	TemplateArea.Parameters.Fill(New Structure("Total", Goods.Sum));
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("VATTableBasement");
	TemplateArea.Parameters.Fill(New Structure("VAT, TotalVAT", NStr("vi = 'Bao gồm thuế GTGT(20%)';
																	|ru = 'В т.ч. НДС (20%)';
																	|en = 'Including VAT (20%)'; fa = 'Including VAT (20%)';
																	|it = 'Iva inclusa (20%)';
																	|pl = 'W tym VAT (20%)';
																	|tr = 'KDV dahil (20%)'", Common.DefaultLanguageCode()), Goods.VATAmount));
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("BasementTablesOfEverything");
	TemplateArea.Parameters.Fill(New Structure("TotalWithVAT", Goods.Sum));
	SpreadsheetDocument.Put(TemplateArea);

	TemplateArea = Template.GetArea("AmountInWords");
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	AmountToBeRegistered = 120;
	TotalString = NStr("vi = 'Tổng số mục %Count%, Số tiền %Sum%';
						|ru = 'Всего наименований %Count%, на сумму %Sum%';
						|en = 'Total number of names %Count% in the amount of %Sum%'; fa = 'Total number of names %Count% in the amount of %Sum%';
						|it = 'Totale articoli %Count%, per l''importo di %Sum%';
						|pl = 'Razem pozycji %Count%, o wartości%Sum%';
						|tr = 'Toplam tanım %Count%, tutar %Sum%'", Common.DefaultLanguageCode());
	TotalString = StrReplace(TotalString, "%Count%", Goods.Count);
	TotalString = StrReplace(TotalString, "%Sum%",      PrintFormGeneration.SumFormat(AmountToBeRegistered, Currency));
	
	AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(Goods.Sum, Currency);
	
	DataStructureSumInWords = New Structure("AmountInWords, TotalString", AmountInWords, TotalString);
	TemplateArea.Parameters.Fill(DataStructureSumInWords);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("BasementAccounts");
	PrintFormGeneration.OutputFacsimileToTabularDocument(Template, TemplateArea, Organization, New Structure("DisplayFacsimiles", True));
	
	// Output signatures
	ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Organization);
	BasementDataStructure = New Structure;
	BasementDataStructure.Insert("ManagerSFullName_", PersonsTM.IndividualShortName(ResponsiblePersons.Director));
	BasementDataStructure.Insert("AccountantSFullName", PersonsTM.IndividualShortName(ResponsiblePersons.ChiefAccountant));
	TemplateArea.Parameters.Fill(BasementDataStructure);
	
	SpreadsheetDocument.Put(TemplateArea);
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region Invoice

Function CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PrintPARAMETERS_INVOICE";
	
	DocumentTypeNumber = 0;
	
	SetPrivilegedMode(True);
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedInvoiceForm(PrintParameters, ObjectsStructure.Value, LanguageCode);
		
		FillInInvoiceTabularDocument(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters,, LanguageCode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return SpreadsheetDocument;
	
EndFunction

// Parameters:
//	SpreadsheetDocument           - SpreadsheetDocument -
//	DataForPrint             - Structure - It contains data on the document header, payment stages, and tabular part:
//		* HeaderResults          - QueryResult -
//		* ResultsByPaymentStages   - QueryResult -
//		* ResultForTabularPart - QueryResult -
//	PrintObjects               - See PrintManagementOverridable.OnPrint.PrintObjects
//	PrintParameters             - See PrintManagementOverridable.OnPrint.PrintParameters
//	Preliminary             - Boolean -
//	LanguageCode                    - String, Undefined -
//
Procedure FillInInvoiceTabularDocument(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters, Preliminary = False, LanguageCode = Undefined)
	
	ErrorPatterns = New Structure;
	ErrorPatterns.Insert("Goods", NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in Hóa đơn chiếu lệ';
										|ru = 'В документе %1 отсутствуют товары. Печать Proforma invoice не требуется';
										|en = 'Goods are missing in document %1. Printing of Proforma invoice is not required'; fa = 'Goods are missing in document %1. Printing of Proforma invoice is not required';
										|it = 'Il documento %1 non contiene merci. Stampa fattura proforma non richiesta';
										|pl = 'W dokumencie %1 nie ma towarów. Wydruk Faktury pro formy nie jest wymagany';
										|tr = 'Belge %1''de ürün bulunmamaktadır. Proforma faturanın yazdırılmasına gerek yoktur'"));
	ErrorPatterns.Insert("SubstituteGoods", NStr("vi = 'Trong chứng từ %1 không có hàng hóa thay thế. Không cần in Hóa đơn chiếu lệ';
												|ru = 'В документе %1 отсутствуют заменяющие товары. Печать Proforma invoice не требуется';
												|en = 'Exchange goods are missing in the %1 document. Printing of Proforma invoice is not required'; fa = 'Exchange goods are missing in the %1 document. Printing of Proforma invoice is not required';
												|it = 'Il documento %1 non contiene merci di sostituzione. Stampa Proforma invoice non richiesta';
												|pl = 'W dokumencie %1 nie ma zastępczych towarów. Wydruk Faktury pro formy nie jest wymagany';
												|tr = 'Belge %1''de ikame ürün bulunmamaktadır. Proforma faturanın yazdırılmasına gerek yoktur'"));
	ErrorPatterns.Insert("Stages", NStr("vi = 'Trong chứng từ %1 không có các giai đoạn thanh toán. Không cần in Hóa đơn chiếu lệ';
										|ru = 'В документе %1 отсутствуют этапы оплаты. Печать Proforma invoice не требуется';
										|en = 'Payment milestones are missing in document %1. Printing of Proforma invoice is not required'; fa = 'Payment milestones are missing in document %1. Printing of Proforma invoice is not required';
										|it = 'Il documento %1 non contiene fasi di pagamento. Stampa Proforma invoice non richiesta';
										|pl = 'W dokumencie %1 nie etapów płatności. Wydruk Faktury pro formy nie jest wymagany';
										|tr = 'Belge %1''de herhangi bir ödeme aşaması bulunmamaktadır. Proforma faturanın yazdırılmasına gerek yok'"));
	
	PrintData = DataForPrint.HeaderResults.Select();
	PaymentSteps = DataForPrint.ResultsByPaymentStages.Unload();
	Goods = DataForPrint.ResultForTabularPart.Unload();
		
	StagesOfPledgePackaging = PaymentSteps.FindRows(New Structure("ThisIsDepositForPackage", True));
	OnlyDepositForContainer = StagesOfPledgePackaging.Count() = PaymentSteps.Count() And StagesOfPledgePackaging.Count() > 0;
	
	ThereIsContent = False;
	If Goods.Columns.Find("Content") <> Undefined Then
		ThereIsContent = True;
	EndIf;
	
	UseSets = False;
	If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
		UseSets = True;
	EndIf;
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		Cancel = False;
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		
		GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
		PaymentStagesTable = PaymentSteps.FindRows(TheStructureOfTheSearch);
		
		CheckingDocumentFilling(PrintData, GoodsTable, PaymentStagesTable, ErrorPatterns, Cancel, Preliminary);
		If Cancel Then
			Continue;
		EndIf;
		
		If FirstDocument Then
			FirstDocument = False;
		Else
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Template = New SpreadsheetDocument;
		FillInDetailsOfInvoiceHeader(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, GoodsTable, Preliminary, LanguageCode);
				
		If PrintData.PartialPayment Or TypeOf(PrintData.DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor") Then
			
			Area_TableHeader = Template.GetArea("PartialPaymentTableHeader");
			SpreadsheetDocument.Put(Area_TableHeader);
			
			AreaTableRow = Template.GetArea("TableRowPartialPayment");
			AreaTableRow.Parameters.Fill(PrintData);
			AreaTableRow.Parameters.LineNumber = 1;
			SpreadsheetDocument.Put(AreaTableRow);
			
			AreaTotal = Template.GetArea("BasementTablePartialPayment");
			DataStructureTotal = New Structure;
			DataStructureTotal.Insert("DocumentCurrency",PrintData.Currency);
			DataStructureTotal.Insert("Total", PrintData.DocumentAmount);
			AreaTotal.Parameters.Fill(DataStructureTotal);
			AreaTotal.Parameters.Fill(PrintData);
			SpreadsheetDocument.Join(AreaTotal);
			
			// Output the total of the ADS
			ComplianceWithVATRates = New Map;
			If PrintData.ConsiderVAT And Not OnlyDepositForContainer 
				And Not PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
				
				RegionTotalVAT = Template.GetArea(?(PrintData.PriceIncludesVAT, "BasementOfVTCHNDSTable", "VATTableBasement"));
				If GoodsTable.Count() = 0 Then
					If ValueIsFilled(PrintData.VATRate) Then
						VATAmount = PrintData.VATAmount;
						ComplianceWithVATRates.Insert(PrintData.VATRate, VATAmount);
					EndIf;
				Else
					For Each RowOfProduct In GoodsTable Do
						If UseSets And RowOfProduct.IsRecordsSet Then 
							Continue; // We exclude VAT amounts for the set as a whole.
						EndIf;	
						VATAmount = ComplianceWithVATRates[RowOfProduct.VATRate];
						If VATAmount = Undefined Then
							VATAmount = RowOfProduct.VATAmount;
						Else
							VATAmount = VATAmount + RowOfProduct.VATAmount;
						EndIf;
						ComplianceWithVATRates.Insert(RowOfProduct.VATRate, VATAmount);
					EndDo;
				EndIf;
				If ComplianceWithVATRates.Count() > 0 Then
					VATAmount = 0;
					For Each CurVATRate In ComplianceWithVATRates Do
						DataStructureTotalVAT = New Structure;
						DataStructureTotalVAT.Insert("DocumentCurrency",PrintData.Currency);
						If ValueIsFilled(CurVATRate.Value) Then
							CurVATAmount = CurVATRate.Value /100 * PrintData.PayPercentage;
							VATAmount = VATAmount + CurVATAmount;
							DataStructureTotalVAT.Insert("TotalVAT", PrintFormGeneration.SumFormat(CurVATAmount));
						Else
							DataStructureTotalVAT.Insert("TotalVAT","--");
						EndIf;
						RegionTotalVAT.Parameters.Fill(DataStructureTotalVAT);
						SpreadsheetDocument.Put(RegionTotalVAT);
					EndDo;
					AreaBasementWithVAT = Template.GetArea("BasementTablesOfEverything");
					DataStructureBasementWithVAT = New Structure;
					DataStructureBasementWithVAT.Insert("DocumentCurrency",PrintData.Currency);
					DataStructureBasementWithVAT.Insert("TotalWithVAT", PrintFormGeneration.SumFormat(PrintData.DocumentAmount));
					DataStructureBasementWithVAT.Insert("TotalWithoutVAT", PrintFormGeneration.SumFormat(PrintData.DocumentAmount - VATAmount));
					AreaBasementWithVAT.Parameters.Fill(DataStructureBasementWithVAT);
					SpreadsheetDocument.Put(AreaBasementWithVAT);
				EndIf;
			Else
				AreaBasementTableTotalWithoutVAT = Template.GetArea("BasementTableTotalWithoutVAT");
				DataStructureTotal = New Structure;
				DataStructureTotal.Insert("Total", PrintData.DocumentAmount);
				AreaBasementTableTotalWithoutVAT.Parameters.Fill(DataStructureTotal);
				AreaBasementTableTotalWithoutVAT.Parameters.Fill(PrintData);
				SpreadsheetDocument.Put(AreaBasementTableTotalWithoutVAT);
			EndIf;
		Else
			// The "Products" table
			Area_TableHeader = Template.GetArea("TableHeader");
			AreaTableRow = Template.GetArea("TableRow");
			TableBasementArea = Template.GetArea("TableFooter");
			AreaSummary = Template.GetArea("BasementTablesSummedUp");
			
			VATBasementArea = Template.GetArea(?(PrintData.PriceIncludesVAT, "BasementOfVTCHNDSTable", "VATTableBasement"));
			
			AreaBasementTotal = Template.GetArea("BasementTablesOfEverything");
			AreaBasementTotalWithoutVAT = Template.GetArea("BasementTableTotalWithoutVAT");
			SpreadsheetDocument.Put(Area_TableHeader);
			
			BlankData = SetsServer.BlankData();
			HeaderOutput = 0;
			
			OutputValidationArray = New Array;
			
			Sum = 0;
			VATAmount = 0;
			TotalOfDiscounts = 0;
			TotalWithoutDiscounts = 0;
			LineNumber = 0;
			ComplianceWithVATRates = New Map;
			For Each LineProducts_ In GoodsTable Do
				If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
					LineNumberPrint = "";
				Else
					LineNumber = LineNumber + 1;
					LineNumberPrint = LineNumber;
				EndIf;
				
				If LineNumber = 0 And HeaderOutput <> 2 Then
					HeaderOutput = 1;
				EndIf;
				
				PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(LineProducts_, UseSets);
				
				AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersForGettingNameToPrint.ReturnContainers = LineProducts_.ThisIsReusablePackage;
				AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
				If ThereIsContent Then
					AdditionalParametersForGettingNameToPrint.Content = LineProducts_.Content;
				EndIf;
				AdditionalColumn = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
				If ValueIsFilled(AdditionalColumn) Then
					AdditionalParametersForGettingNameToPrint.Prefix = LineProducts_[AdditionalColumn];
				EndIf;
				OwnGoods = PrefixAndPostfix.Prefix
						+ ProductsClientServer.PresentationOfProductsForPrinting(
															LineProducts_.DescriptionFull,
															LineProducts_.Characteristic,
															,
															, // Series
															AdditionalParametersForGettingNameToPrint)
						+ PrefixAndPostfix.Postfix;
						
				StringDataStructure = New Structure;
				StringDataStructure.Insert("OwnGoods", OwnGoods);
				StringDataStructure.Insert("LineNumber", LineNumberPrint);
				StringDataStructure.Insert("DiscountAmount",
						?(LineProducts_.DiscountAmount = 0,"--",LineProducts_.DiscountAmount));
				
				AreaTableRow.Parameters.Fill(LineProducts_);
				AreaTableRow.Parameters.Fill(StringDataStructure);
				If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
					AreaTableRow.Parameters.Fill(BlankData);
				EndIf;
				
				OutputValidationArray.Clear();
				OutputValidationArray.Add(AreaTableRow);
				OutputValidationArray.Add(TableBasementArea);
				If LineNumber = GoodsTable.Count() Then
					OutputValidationArray.Add(AreaSummary);
					For AreaCounter = 0 To ComplianceWithVATRates.Count()-1 Do
						OutputValidationArray.Add(VATBasementArea);
					EndDo;
					OutputValidationArray.Add(AreaBasementTotal);
				EndIf;
				
				If Not SpreadsheetDocument.CheckPut(OutputValidationArray) Then
					SpreadsheetDocument.Put(TableBasementArea);
					SpreadsheetDocument.PutHorizontalPageBreak();
					PrintInvoiceHeader(Template, SpreadsheetDocument, PrintData, Preliminary, LanguageCode);
					SpreadsheetDocument.Put(Area_TableHeader);
				EndIf;
				
				SpreadsheetDocument.Put(AreaTableRow);
				If Not SetsServer.UseScope(LineProducts_, UseSets) Then
					Sum = Sum + LineProducts_.Sum;
					VATAmount = VATAmount + LineProducts_.VATAmount;
					TotalOfDiscounts = TotalOfDiscounts + LineProducts_.DiscountAmount;
					TotalWithoutDiscounts = TotalWithoutDiscounts + LineProducts_.AmountWithoutADiscount;
					If PrintData.ConsiderVAT And Not OnlyDepositForContainer Then
						AmountOfVATAtRate = ComplianceWithVATRates[LineProducts_.VATRate];
						If AmountOfVATAtRate = Undefined Then
							AmountOfVATAtRate = 0;
						EndIf;
						ComplianceWithVATRates.Insert(LineProducts_.VATRate, AmountOfVATAtRate + LineProducts_.VATAmount);
					EndIf;
				EndIf;
			EndDo;
			
			SpreadsheetDocument.Put(TableBasementArea);
			StructureResults = New Structure();
			StructureResults.Insert("DocumentCurrency",PrintData.Currency);
			StructureResults.Insert("Total", PrintFormGeneration.SumFormat(Sum));
			StructureResults.Insert("TotalWithoutDiscounts", PrintFormGeneration.SumFormat(TotalWithoutDiscounts));
			StructureResults.Insert("TotalOfDiscounts", ?(TotalOfDiscounts<>0, 
				PrintFormGeneration.SumFormat(TotalOfDiscounts),
				"--"));
			StructureResults.Insert("TotalWithVAT", PrintFormGeneration.SumFormat(Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount)));
			StructureResults.Insert("TotalWithoutVAT", PrintFormGeneration.SumFormat(Sum - ?(PrintData.PriceIncludesVAT, VATAmount, 0)));
			StructureResults.Insert("TotalRows",LineNumber);
			AreaSummary.Parameters.Fill(StructureResults);
			SpreadsheetDocument.Put(AreaSummary);
			If PrintData.ConsiderVAT Then
				For Each CurVATRate In ComplianceWithVATRates Do
					
					DataStructureVATBasement = New Structure;
					DataStructureVATBasement.Insert("VATRate", CurVATRate.Key);
					DataStructureVATBasement.Insert("TotalVAT", PrintFormGeneration.SumFormat(CurVATRate.Value, ,"-"));
					VATBasementArea.Parameters.Fill(DataStructureVATBasement);
					SpreadsheetDocument.Put(VATBasementArea);
					
				EndDo;
				AreaBasementTotal.Parameters.Fill(StructureResults);
				SpreadsheetDocument.Put(AreaBasementTotal);
			Else
				StructureResults.Insert("VAT", NStr("vi = 'Without tax';
													|ru = 'Without tax';
													|en = 'Without tax'; fa = 'Without tax';
													|it = 'Without tax';
													|pl = 'Without tax';
													|tr = 'Without tax'", Common.DefaultLanguageCode()));
				AreaBasementTotalWithoutVAT.Parameters.Fill(StructureResults);
				SpreadsheetDocument.Put(AreaBasementTotalWithoutVAT);
			EndIf;
		EndIf;
		If Preliminary Then
			FillInPaymentStagesTable(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, PrintParameters, LanguageCode);
		EndIf;
		If ValueIsFilled(PrintData.AdditionalInformation) Then
		
			Area = Template.GetArea("AdditionalInformation");
			Area.Parameters.Fill(PrintData);
			SpreadsheetDocument.Put(Area);
		
		EndIf;
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
	EndDo;
	
EndProcedure

Procedure FillInDetailsOfInvoiceHeader(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, GoodsTable, Preliminary, LanguageCode)
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommercialInvoices.PF_MXL_Invoice", LanguageCode);
	
	SupplierInformation = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date);
	PrintInvoiceHeader(Template, SpreadsheetDocument, PrintData, Preliminary, LanguageCode);
	
	UseInternationalAddressName = ValueIsFilled(LanguageCode)
												And Not LanguageCode = Common.DefaultLanguageCode();
	
	If Preliminary Then
		TemplateArea = Template.GetArea("PaymentTerm");
		If PaymentStagesTable.Count() = 0 Then
			PaymentDate = '00010101';
		ElsIf PaymentStagesTable.Count() = 1 Then
			PaymentDate = PaymentStagesTable[0].PaymentDate;
		Else
			PaymentDate = PaymentStagesTable[PaymentStagesTable.Count()-1].PaymentDate;
		EndIf;
	
		If ValueIsFilled(PaymentDate) Then
			DataStructureHeader = New Structure;
			DataStructureHeader.Insert("ValidityPeriod", Format(PaymentDate, StrTemplate("L=%1; DLF=D", LanguageCode)));
			TemplateArea.Parameters.Fill(DataStructureHeader);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	TemplateArea = Template.GetArea("CompanyDetails");
	
	DataStructureProvider = PrintFormGeneration.InformationAboutLegalEntity(PrintData.CompanyVendor,
		PrintData.Date);
	
	DataStructureProvider.FullDescr = SelectAttributes(UseInternationalAddressName, DataStructureProvider.FullDescr, DataStructureProvider.DescriptionInternational);
	DataStructureProvider.LegalAddress = SelectAttributes(UseInternationalAddressName, DataStructureProvider.LegalAddress, DataStructureProvider.International_Address);
	
	TemplateArea.Parameters.Fill(DataStructureProvider);
	SpreadsheetDocument.Put(TemplateArea);
	
	If ValueIsFilled(PrintData.Shipper) Then
		TemplateArea = Template.GetArea("DetailsOfShipper");
		
		DataStructureProvider = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Shipper,
			PrintData.Date);
		
		DataStructureProvider.FullDescr = SelectAttributes(UseInternationalAddressName, DataStructureProvider.FullDescr, DataStructureProvider.DescriptionInternational);
		DataStructureProvider.LegalAddress = SelectAttributes(UseInternationalAddressName, DataStructureProvider.LegalAddress, DataStructureProvider.International_Address);
		
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	TemplateArea = Template.GetArea("BankingDetails");
	If PrintData.PaymentAbroad Then
		
		HeaderDataStructure_1 = New Structure;
		SupplierPresentationForErrandBoards = "";
		
		If ValueIsFilled(PrintData.BankAccount) Then
			
			BankDescription = SelectAttributes(UseInternationalAddressName, PrintData.BankDescription, PrintData.BankNameInt);
			
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", PrintData.BankAccountNumber);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", BankDescription);
			HeaderDataStructure_1.Insert("AddressOfRecipientSBankPresentation", PrintData.BankAddress);
			HeaderDataStructure_1.Insert("BankSWIFTCode", PrintData.BankSWIFTCode);
			SupplierPresentationForErrandBoards = PrintData.CorrespondentTextBankAccount;
			
		EndIf;
		
		If IsBlankString(SupplierPresentationForErrandBoards) Then
			
			AttributesRow = "FullDescr,";
			If UseInternationalAddressName
				And ValueIsFilled(SupplierInformation.DescriptionInternational) Then
				
				AttributesRow = "DescriptionInternational,";
				
			EndIf;
			
			SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, AttributesRow);
			
		EndIf;
		HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not IsBlankString(PrintData.TransferBankDescription) Then
			TemplateArea = Template.GetArea("CorrespondentBankDetails");
			
			HeaderDataStructure_1.Clear();
			HeaderDataStructure_1.Insert("RecipientSCorrespondentBankPresentation",
				PrintData.TransferBankDescription + " " + PrintData.TransferBankAddress);
			HeaderDataStructure_1.Insert("BankSWIFTCodeForPayments", PrintData.BankSWIFTCodeForPayments);
			HeaderDataStructure_1.Insert("BankAccountForSettlementsPresentation", PrintData.BankAccountForPayments);
			
			TemplateArea.Parameters.Fill(HeaderDataStructure_1);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		TemplateArea = Template.GetArea("PaymentPurposes");
		HeaderDataStructure_1.Clear();
		If Not ValueIsFilled(PrintData.PaymentPurposes)
			And TypeOf(PrintData.Ref) <> Type("DocumentRef.CustomerCommercialInvoice") Then
			HeaderDataStructure_1.Insert("PaymentPurposes", Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
				PrintData.Number, PrintData.Ref, PrintData.Date));
		Else
			HeaderDataStructure_1.Insert("PaymentPurposes", PrintData.PaymentPurposes);
		EndIf;
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
	Else
		
		HeaderDataStructure_1 = New Structure;
		SupplierPresentationForErrandBoards = "";
		
		If ValueIsFilled(PrintData.BankAccount) Then
			
			If ValueIsFilled(PrintData.TransferBankBIC) Then
				Bank = SelectAttributes(UseInternationalAddressName, PrintData.TransferBankDescription, PrintData.BankNameForPaymentsInt);
				BIC = SelectAttributes(UseInternationalAddressName, PrintData.TransferBankBIC, PrintData.BankSWIFTCodeForPayments);
				CorrAccount = PrintData.TransferBankCorrAccount;
				BankCity = SelectAttributes(UseInternationalAddressName, PrintData.TransferBankCity, PrintData.BankCityForPaymentsInt);
				AccountNumber = PrintData.BankCorrAccount;
			Else
				Bank = SelectAttributes(UseInternationalAddressName, PrintData.BankDescription, PrintData.BankNameInt);
				BIC = SelectAttributes(UseInternationalAddressName, PrintData.BICBank, PrintData.BankSWIFTCode);
				CorrAccount = PrintData.BankCorrAccount;
				BankCity = SelectAttributes(UseInternationalAddressName, PrintData.BankCity, PrintData.BankCityInt);
				AccountNumber = PrintData.BankAccountNumber;
			EndIf;
			
			HeaderDataStructure_1.Insert("BankSWIFTCode", BIC);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", TrimAll(Bank) + " " + BankCity);
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", CorrAccount);
			HeaderDataStructure_1.Insert("RecipientAccountPresentation", AccountNumber);
			SupplierPresentationForErrandBoards = PrintData.CorrespondentTextBankAccount;
			
		EndIf;
	
		If IsBlankString(SupplierPresentationForErrandBoards) Then
			
			AttributesRow = "FullDescr,";
			If UseInternationalAddressName
				And ValueIsFilled(SupplierInformation.DescriptionInternational) Then
				
				AttributesRow = "DescriptionInternational,";
				
			EndIf;
			
			SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, AttributesRow);
			
		EndIf;
		
		HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("PaymentPurposes");
		HeaderDataStructure_1.Clear();
		If Not ValueIsFilled(PrintData.PaymentPurposes)
			And TypeOf(PrintData.Ref) <> Type("DocumentRef.CustomerCommercialInvoice") Then
			
			HeaderDataStructure_1.Insert("PaymentPurposes", Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
				PrintData.Number, PrintData.Ref, PrintData.Date));
			
		Else
			
			HeaderDataStructure_1.Insert("PaymentPurposes", PrintData.PaymentPurposes);
			
		EndIf;
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	TemplateArea = Template.GetArea("CounterpartyDetails_");
	
	CustomerDataStructure = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty,
		PrintData.Date);
	CustomerDataStructure.Insert("GoodsRecipient", CustomerDataStructure.FullDescr);
	CustomerDataStructure.GoodsRecipient = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.FullDescr, CustomerDataStructure.DescriptionInternational);
	CustomerDataStructure.FullDescr = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.FullDescr, CustomerDataStructure.DescriptionInternational);
	CustomerDataStructure.LegalAddress = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.LegalAddress, CustomerDataStructure.International_Address);
	CustomerDataStructure.ActualAddress = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.ActualAddress, CustomerDataStructure.International_Address);
	If ValueIsFilled(PrintData.GoodsRecipient) Then
		DataStructureConsignee = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty,
			PrintData.Date);
			
		CustomerDataStructure.GoodsRecipient = SelectAttributes(UseInternationalAddressName, DataStructureConsignee.FullDescr, DataStructureConsignee.DescriptionInternational);
		CustomerDataStructure.ActualAddress = SelectAttributes(UseInternationalAddressName, DataStructureConsignee.ActualAddress, DataStructureConsignee.International_Address);
		CustomerDataStructure.Phones = DataStructureConsignee.Phones;
		
	EndIf;
	TemplateArea.Parameters.Fill(CustomerDataStructure);
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Procedure PrintInvoiceHeader(Template, SpreadsheetDocument, PrintData, Preliminary, LanguageCode)
	
	TemplateArea = Template.GetArea("Title");
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "TitleLogo", PrintData.Organization);
	If Not TMCommonUseClientServer.HasObjectAttribute(TemplateArea.Drawings, "Logo") Then 
		TemplateArea.DeleteArea(TemplateArea.Area("AreaLogo"), SpreadsheetDocumentShiftType.Horizontal);
		TemplateArea.DeleteArea(TemplateArea.Area("TitleIndentation"), SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	If Preliminary Then
		TemplateArea.DeleteArea(TemplateArea.Area("CommercialHeader"), SpreadsheetDocumentShiftType.Vertical);
	Else
		TemplateArea.DeleteArea(TemplateArea.Area("ProformaHeader"), SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(PrintData.Number));
	ParametersStructure.Insert("DocumentDate", Format(PrintData.Date, StrTemplate("L=%1; DLF=D", LanguageCode)));
	TemplateArea.Parameters.Fill(ParametersStructure);
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Procedure FillInPaymentStagesTable(PrintData, Template, SpreadsheetDocument, PaymentStagesTable, PrintParameters, LanguageCode)
	
	OutputValidationArray = New Array;
	
	// Display the stages of the payment schedule
	If PaymentStagesTable.Count() > 1 Then
		Area_TableHeader = Template.GetArea("HeaderOfPaymentStagesTable");
		TableBasementArea = Template.GetArea("TotalPaymentStages");
		OutputValidationArray.Add(Area_TableHeader);
		OutputValidationArray.Add(TableBasementArea);
		
		AreaTableRow = Template.GetArea("RowOfPaymentStagesTable");
		
		StageNumber = 1;
		For Each CurStage In PaymentStagesTable Do
			
			RowParameters = NewStageLineParameters();
			FillPropertyValues(RowParameters, CurStage);
			
			RowParameters.PaymentDate = Format(CurStage.PaymentDate, StrTemplate("L=%1; DLF=D", LanguageCode));
			
			RowParameters.LineNumber = StageNumber;
			If RowParameters.ThisIsDepositForPackage Then
				RowParameters.PaymentPercentage = "-";
			EndIf;
			
			AreaTableRow.Parameters.Fill(RowParameters);
			
			OutputValidationArray.Add(AreaTableRow);
			
			If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
				If StageNumber = 1 Then
					SpreadsheetDocument.Put(Area_TableHeader);
					OutputValidationArray.Delete(0);
				EndIf;
			Else
				SpreadsheetDocument.PutHorizontalPageBreak();
				PrintInvoiceHeader(Template, SpreadsheetDocument, PrintData, True, LanguageCode);
				SpreadsheetDocument.Put(Area_TableHeader);
			EndIf;
			
			SpreadsheetDocument.Put(AreaTableRow);
			OutputValidationArray.Delete(OutputValidationArray.UBound());
			
			StageNumber = StageNumber + 1;
			
		EndDo;
		SpreadsheetDocument.Put(TableBasementArea);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProformaInvoice

Function CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PrintPARAMETERS_PROFORMAINVOICE";
	
	DocumentTypeNumber = 0;
	
	SetPrivilegedMode(True);
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		DataForPrint = ObjectManager.GetDataForPrintedInvoiceForm(PrintParameters, ObjectsStructure.Value, LanguageCode);
		
		FillInInvoiceTabularDocument(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters, True, LanguageCode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region DebitCreditNote

Function CreatePrintedFormDebitNote(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PrintPARAMETERS_DebitNote";
	
	DocumentTypeNumber = 0;
	
	SetPrivilegedMode(True);
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		DataForPrint = Documents.SaleAdjustment.PrintDataDebitCreditNote(PrintParameters, ObjectsStructure.Value, "DebitNote", LanguageCode);
		
		FillInTabularDocumentDebitCreditNote(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters, "DebitNote", LanguageCode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return SpreadsheetDocument;
	
EndFunction

Function FormPrintedFormCreditNote(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PrintPARAMETERS_CREDITNOTE";
	
	DocumentTypeNumber = 0;
	
	SetPrivilegedMode(True);
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		If ObjectsStructure.Key = "Document.SaleAdjustment" Then
			
			DataForPrint = Documents.SaleAdjustment.PrintDataDebitCreditNote(PrintParameters, ObjectsStructure.Value, "CreditNote", LanguageCode);
			
		ElsIf ObjectsStructure.Key = "Document.ReturnOfGoodsFromCustomer" Then
			
			DataForPrint = Documents.ReturnOfGoodsFromCustomer.PrintDataDebitCreditNote(PrintParameters, ObjectsStructure.Value, "CreditNote", LanguageCode);
			
		EndIf;
		
		FillInTabularDocumentDebitCreditNote(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters, "CreditNote", LanguageCode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return SpreadsheetDocument;
	
EndFunction

// Parameters:
//	SpreadsheetDocument           - SpreadsheetDocument -
//	DataForPrint             - Structure - Contains data on the header of the document, the tabular part:
//		* HeaderResults          - QueryResult -
//		* ResultForTabularPart - QueryResult -
//	PrintObjects               - See PrintManagementOverridable.OnPrint.PrintObjects
//	PrintParameters             - See PrintManagementOverridable.OnPrint.PrintParameters
//	DebitCreditNote             - String -
//	LanguageCode                    - String -
//
Procedure FillInTabularDocumentDebitCreditNote(SpreadsheetDocument, DataForPrint, PrintObjects, PrintParameters, DebitCreditNote, LanguageCode)
	
	PrintData = DataForPrint.HeaderResults.Select();
	Goods = DataForPrint.ResultForTabularPart.Unload();
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		
		GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
		
		If FirstDocument Then
			FirstDocument = False;
		Else
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Template = New SpreadsheetDocument;
		FillInDetailsOfDebitCreditNoteHeader(PrintData, Template, SpreadsheetDocument, GoodsTable, DebitCreditNote, LanguageCode);
				
		// The "Products" table
		Area_TableHeader  = Template.GetArea("TableHeader");
		AreaTableRow = Template.GetArea("TableRow");
		TableBasementArea = Template.GetArea("TableFooter");
		AreaSummary       = Template.GetArea("BasementTablesSummedUp");
		VATBasementArea = Template.GetArea(?(PrintData.PriceIncludesVAT, "BasementOfVTCHNDSTable", "VATTableBasement"));
		AreaBasementTotal   = Template.GetArea("BasementTablesOfEverything");
		AreaBasementTotalWithoutVAT = Template.GetArea("BasementTableTotalWithoutVAT");
		SpreadsheetDocument.Put(Area_TableHeader);
		
		BlankData = SetsServer.BlankData();
		HeaderOutput = 0;
		
		OutputValidationArray = New Array;
		
		Sum = 0;
		VATAmount = 0;
		LineNumber = 0;
		ComplianceWithVATRates = New Map;
		For Each LineProducts_ In GoodsTable Do
			
			If SetsServer.DisplayOnlyTitle(LineProducts_, True) Then
				LineNumberPrint = "";
			Else
				LineNumber = LineNumber + 1;
				LineNumberPrint = LineNumber;
			EndIf;
			
			If LineNumber = 0 And HeaderOutput <> 2 Then
				HeaderOutput = 1;
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(LineProducts_, True);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			AdditionalParametersForGettingNameToPrint.Content = LineProducts_.Content;
			AdditionalColumn = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
			If ValueIsFilled(AdditionalColumn) Then
				AdditionalParametersForGettingNameToPrint.Prefix = LineProducts_[AdditionalColumn];
			EndIf;
			OwnGoods = PrefixAndPostfix.Prefix
					+ ProductsClientServer.PresentationOfProductsForPrinting(
														LineProducts_.DescriptionFull,
														LineProducts_.Characteristic,
														,
														, // Series
														AdditionalParametersForGettingNameToPrint)
					+ PrefixAndPostfix.Postfix;
					
			StringDataStructure = New Structure;
			StringDataStructure.Insert("OwnGoods", OwnGoods);
			StringDataStructure.Insert("LineNumber", LineNumberPrint);
			StringDataStructure.Insert("Count", ?(LineProducts_.Count = 0, "--", LineProducts_.Count));
			StringDataStructure.Insert("Price", ?(LineProducts_.Price = 0, "--", LineProducts_.Price));
			StringDataStructure.Insert("VATAmount", ?(LineProducts_.VATAmount = 0, "--", LineProducts_.VATAmount));
			StringDataStructure.Insert("Sum", ?(LineProducts_.Sum = 0, "--", LineProducts_.Sum));
			
			AreaTableRow.Parameters.Fill(LineProducts_);
			AreaTableRow.Parameters.Fill(StringDataStructure);
			If SetsServer.DisplayOnlyTitle(LineProducts_, True) Then
				AreaTableRow.Parameters.Fill(BlankData);
			EndIf;
			
			OutputValidationArray.Clear();
			OutputValidationArray.Add(AreaTableRow);
			OutputValidationArray.Add(TableBasementArea);
			If LineNumber = GoodsTable.Count() Then
				OutputValidationArray.Add(AreaSummary);
				For AreaCounter = 0 To ComplianceWithVATRates.Count()-1 Do
					OutputValidationArray.Add(VATBasementArea);
				EndDo;
				OutputValidationArray.Add(AreaBasementTotal);
			EndIf;
			
			If Not SpreadsheetDocument.CheckPut(OutputValidationArray) Then
				SpreadsheetDocument.Put(TableBasementArea);
				SpreadsheetDocument.PutHorizontalPageBreak();
				DisplayDebitCreditNoteHeader(Template, SpreadsheetDocument, PrintData, DebitCreditNote, LanguageCode);
				SpreadsheetDocument.Put(Area_TableHeader);
			EndIf;
			
			SpreadsheetDocument.Put(AreaTableRow);
			If Not SetsServer.UseScope(LineProducts_, True) Then
				Sum = Sum + LineProducts_.Sum;
				VATAmount = VATAmount + LineProducts_.VATAmount;
				If PrintData.ConsiderVAT Then
					AmountOfVATAtRate = ComplianceWithVATRates[LineProducts_.VATRate];
					If AmountOfVATAtRate = Undefined Then
						AmountOfVATAtRate = 0;
					EndIf;
					ComplianceWithVATRates.Insert(LineProducts_.VATRate, AmountOfVATAtRate + LineProducts_.VATAmount);
				EndIf;
			EndIf;
		EndDo;
		
		SpreadsheetDocument.Put(TableBasementArea);
		StructureResults = New Structure();
		StructureResults.Insert("DocumentCurrency",PrintData.Currency);
		StructureResults.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		StructureResults.Insert("TotalWithVAT", PrintFormGeneration.SumFormat(Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount)));
		StructureResults.Insert("TotalWithoutVAT", PrintFormGeneration.SumFormat(Sum - ?(PrintData.PriceIncludesVAT, VATAmount, 0)));
		StructureResults.Insert("TotalRows",LineNumber);
		AreaSummary.Parameters.Fill(StructureResults);
		SpreadsheetDocument.Put(AreaSummary);
		If PrintData.ConsiderVAT Then
			For Each CurVATRate In ComplianceWithVATRates Do
				DataStructureVATBasement = New Structure;
				DataStructureVATBasement.Insert("VATRate", CurVATRate.Key);
				DataStructureVATBasement.Insert("TotalVAT", PrintFormGeneration.SumFormat(CurVATRate.Value, ,"-"));
				VATBasementArea.Parameters.Fill(DataStructureVATBasement);
				SpreadsheetDocument.Put(VATBasementArea);
			EndDo;
			AreaBasementTotal.Parameters.Fill(StructureResults);
			SpreadsheetDocument.Put(AreaBasementTotal);
		Else
			AreaBasementTotalWithoutVAT.Parameters.Fill(StructureResults);
			SpreadsheetDocument.Put(AreaBasementTotalWithoutVAT);
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
	EndDo;
	
EndProcedure

Procedure FillInDetailsOfDebitCreditNoteHeader(PrintData, Template, SpreadsheetDocument, GoodsTable, Preliminary, LanguageCode)
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PrintCommercialInvoices.PF_MXL_DebitCreditNote", LanguageCode);
	
	SupplierInformation = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date);
	DisplayDebitCreditNoteHeader(Template, SpreadsheetDocument, PrintData, Preliminary, LanguageCode);
	
	UseInternationalAddressName = ValueIsFilled(LanguageCode)
												And Not LanguageCode = Common.DefaultLanguageCode();
	
	TemplateArea = Template.GetArea("CompanyDetails");
	
	DataStructureProvider = PrintFormGeneration.InformationAboutLegalEntity(PrintData.CompanyVendor,
		PrintData.Date);
	
	DataStructureProvider.FullDescr = SelectAttributes(UseInternationalAddressName, DataStructureProvider.FullDescr, DataStructureProvider.DescriptionInternational);
	DataStructureProvider.LegalAddress = SelectAttributes(UseInternationalAddressName, DataStructureProvider.LegalAddress, DataStructureProvider.International_Address);
	
	TemplateArea.Parameters.Fill(DataStructureProvider);
	SpreadsheetDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("BankingDetails");
	If PrintData.PaymentAbroad Then
		
		HeaderDataStructure_1 = New Structure;
		SupplierPresentationForErrandBoards = "";
		
		If ValueIsFilled(PrintData.BankAccount) Then
			
			BankDescription = SelectAttributes(UseInternationalAddressName, PrintData.BankDescription, PrintData.BankNameInt);
			
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", PrintData.BankAccountNumber);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", BankDescription);
			HeaderDataStructure_1.Insert("AddressOfRecipientSBankPresentation", PrintData.BankAddress);
			HeaderDataStructure_1.Insert("BankSWIFTCode", PrintData.BankSWIFTCode);
			SupplierPresentationForErrandBoards = PrintData.CorrespondentTextBankAccount;
			
		EndIf;
		
		If IsBlankString(SupplierPresentationForErrandBoards) Then
			SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr,");
		EndIf;
		HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not IsBlankString(PrintData.TransferBankDescription) Then
			TemplateArea = Template.GetArea("CorrespondentBankDetails");
			
			HeaderDataStructure_1.Clear();
			HeaderDataStructure_1.Insert("RecipientSCorrespondentBankPresentation",
				PrintData.TransferBankDescription + " " + PrintData.TransferBankAddress);
			HeaderDataStructure_1.Insert("BankSWIFTCodeForPayments", PrintData.BankSWIFTCodeForPayments);
			HeaderDataStructure_1.Insert("BankAccountForSettlementsPresentation", PrintData.BankAccountForPayments);
			
			TemplateArea.Parameters.Fill(HeaderDataStructure_1);
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
	Else
		
		HeaderDataStructure_1 = New Structure;
		SupplierPresentationForErrandBoards = "";
		
		If ValueIsFilled(PrintData.BankAccount) Then
			
			If ValueIsFilled(PrintData.TransferBankBIC) Then
				Bank = SelectAttributes(UseInternationalAddressName, PrintData.TransferBankDescription, PrintData.BankNameForPaymentsInt);
				BIC = SelectAttributes(UseInternationalAddressName, PrintData.TransferBankBIC, PrintData.BankSWIFTCodeForPayments);
				CorrAccount = PrintData.TransferBankCorrAccount;
				BankCity = SelectAttributes(UseInternationalAddressName, PrintData.TransferBankCity, PrintData.BankCityForPaymentsInt);
				AccountNumber = PrintData.BankCorrAccount;
			Else
				Bank = SelectAttributes(UseInternationalAddressName, PrintData.BankDescription, PrintData.BankNameInt);
				BIC = SelectAttributes(UseInternationalAddressName, PrintData.BICBank, PrintData.BankSWIFTCode);
				CorrAccount = PrintData.BankCorrAccount;
				BankCity = SelectAttributes(UseInternationalAddressName, PrintData.BankCity, PrintData.BankCityInt);
				AccountNumber = PrintData.BankAccountNumber;
			EndIf;
			
			HeaderDataStructure_1.Insert("BankSWIFTCode", BIC);
			HeaderDataStructure_1.Insert("PayeeBankPresentation", TrimAll(Bank) + " " + BankCity);
			HeaderDataStructure_1.Insert("RecipientBankAccountPresentation", CorrAccount);
			HeaderDataStructure_1.Insert("RecipientAccountPresentation", AccountNumber);
			SupplierPresentationForErrandBoards = PrintData.CorrespondentTextBankAccount;
			
		EndIf;
	
		If IsBlankString(SupplierPresentationForErrandBoards) Then
			
			AttributesRow = "FullDescr,";
			If UseInternationalAddressName
				And ValueIsFilled(SupplierInformation.DescriptionInternational) Then
				
				AttributesRow = "DescriptionInternational,";
				
			EndIf;
			
			SupplierPresentationForErrandBoards = PrintFormGeneration.OrganizationDescription(SupplierInformation, AttributesRow);
			
		EndIf;
		
		HeaderDataStructure_1.Insert("SupplierPresentationForErrandBoards", SupplierPresentationForErrandBoards);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		SpreadsheetDocument.Put(TemplateArea);
		
	EndIf;
	
	TemplateArea = Template.GetArea("CounterpartyDetails_");
	
	CustomerDataStructure = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date);
	
	CustomerDataStructure.FullDescr = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.FullDescr, CustomerDataStructure.DescriptionInternational);
	CustomerDataStructure.LegalAddress = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.LegalAddress, CustomerDataStructure.International_Address);
	CustomerDataStructure.ActualAddress = SelectAttributes(UseInternationalAddressName, CustomerDataStructure.ActualAddress, CustomerDataStructure.International_Address);
	
	TemplateArea.Parameters.Fill(CustomerDataStructure);
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Procedure DisplayDebitCreditNoteHeader(Template, SpreadsheetDocument, PrintData, DebitCreditNote, LanguageCode)
	TemplateArea = Template.GetArea("Title");
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "TitleLogo", PrintData.Organization);
	If Not TMCommonUseClientServer.HasObjectAttribute(TemplateArea.Drawings, "Logo") Then 
		TemplateArea.DeleteArea(TemplateArea.Area("AreaLogo"), SpreadsheetDocumentShiftType.Horizontal);
		TemplateArea.DeleteArea(TemplateArea.Area("TitleIndentation"), SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	ParametersStructure = New Structure();
	If DebitCreditNote = "CreditNote" Then
		TemplateArea.DeleteArea(TemplateArea.Area("DebitHeader"), SpreadsheetDocumentShiftType.Vertical);
	Else
		TemplateArea.DeleteArea(TemplateArea.Area("CreditHeader"), SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	ParametersStructure.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(PrintData.Number));
	ParametersStructure.Insert("DocumentDate", Format(PrintData.Date, StrTemplate("L=%1; DLF=D", LanguageCode)));
	TemplateArea.Parameters.Fill(ParametersStructure);
	SpreadsheetDocument.Put(TemplateArea);
EndProcedure

#EndRegion

#Region Other

Procedure CheckingDocumentFilling(PrintData, GoodsTable, PaymentStagesTable, ErrorPatterns, Cancel, Preliminary);
	
	If Not (TypeOf(PrintData.Ref) = Type("DocumentRef.CustomerCommercialInvoice")
	 And TypeOf(PrintData.DocumentBasis) = Type("CatalogRef.CounterpartyContracts")) 
	 And GoodsTable <> Undefined And GoodsTable.Count() = 0 Then
		If TypeOf(PrintData.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(ErrorPatterns.SubstituteGoods, PrintData.Ref), PrintData.Ref);
		Else
			CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(ErrorPatterns.Goods, PrintData.Ref), PrintData.Ref);
		EndIf;
		Cancel = True;
		Return;
	EndIf;
	If Preliminary And PaymentStagesTable <> Undefined And PaymentStagesTable.Count() = 0 Then
		CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(ErrorPatterns.Stages, PrintData.Ref), PrintData.Ref);
		Cancel = True;
	EndIf;
	
EndProcedure

Function AmountPayableOnInvoice(PrintData, GoodsTable)
	
	If TypeOf(PrintData.Ref) = Type("DocumentRef.ExpenseReport")
		Or TypeOf(PrintData.DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor")
		Or PrintData.PartialPayment Then
		
		AmountPayableOnInvoice = PrintData.DocumentAmount;
		
	Else
		
		AmountPayableOnInvoice = 0;
		
		UseSets = False;
		If GoodsTable.Count()>0 And TMCommonUseClientServer.HasObjectAttribute(GoodsTable[0], "IsRecordsSet") Then
			UseSets = True;
		EndIf;
		
		For Each LineProducts_ In GoodsTable Do
			If Not SetsServer.UseScope(LineProducts_, UseSets) Then 
				AmountPayableOnInvoice = AmountPayableOnInvoice
					+ LineProducts_.Sum + ?(PrintData.PriceIncludesVAT, 0, LineProducts_.VATAmount);
			EndIf;
		EndDo;
		
		If PrintData.InvoiceToBeRefunded Then
			AmountPayableOnInvoice = AmountPayableOnInvoice - PrintData.AmountToReturn;
			If AmountPayableOnInvoice < 0 Then
				AmountPayableOnInvoice = 0;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return AmountPayableOnInvoice;
	
EndFunction

Function NewStageLineParameters()
	
	StageLineStructure = New Structure;
	StageLineStructure.Insert("LineNumber", 0);
	StageLineStructure.Insert("PaymentDate", '00010101');
	StageLineStructure.Insert("PaymentPercentage", 0);
	StageLineStructure.Insert("PaymentAmount", 0);
	StageLineStructure.Insert("VATText", "");
	StageLineStructure.Insert("ThisIsDepositForPackage", False);
	
	Return StageLineStructure;
	
EndFunction

Procedure OutputQRCode(PaymentDetails, PrintData, TemplateArea)
	
	CodeSize = 190;
	
	If Not RetailSalesLocalization.OutputQRCode(PrintData, TemplateArea.Drawings.QRCode.Picture, CodeSize) Then
		
		QRString = "";
		PrintManagementLocalization.GenerateStringInFormatOfElectronicBankMessages(QRString, PaymentDetails);
		If Not IsBlankString(QRString) Then
			
			QRCodeData = BarcodeGeneration.QRCodeData(QRString, 0, CodeSize);
			
			If TypeOf(QRCodeData) = Type("BinaryData") Then
				PictureQRCode = New Picture(QRCodeData);
				TemplateArea.Drawings.QRCode.Picture = PictureQRCode;
			Else
				Template = NStr("vi = 'Không thể tạo mã QR cho chứng từ %1.
					|Vui lòng xem nhật ký để biết chi tiết kỹ thuật.';
					|ru = 'Не удалось сформировать QR-код для документа %1.
					|Технические подробности см. в журнале регистрации.';
					|en = 'Cannot generate QR code for document %1.
					|For technical details, see the event log.'; fa = 'Cannot generate QR code for document %1.
					|For technical details, see the event log.';
					|it = 'Non era possibile generare il codice QR per il documento %1.
					|Per i dettagli tecnici consultare il registro.';
					|pl = 'Nie udało się wygenerować QR kod dla dokumentu %1.
					|Szczegóły techniczne można znaleźć w dzienniku rejestracji.';
					|tr = 'Belge %1 için QR kodu oluşturulamadı.
					|Teknik ayrıntılar için kayıt defterine bak.'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, PrintData.Ref);
				Common.MessageToUser(MessageText);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function OrganizationDescription(PrintData, CompanyName)
	
	InformationRecords = PrintFormGeneration.InformationAboutLegalEntity(PrintData[CompanyName], PrintData.Date);
	CompanyDetails = "FullDescr,TIN,CRTR,ActualAddress,Phones,";
	
	Return PrintFormGeneration.OrganizationDescription(InformationRecords, CompanyDetails);
	
EndFunction

Function PaymentDetailsQRCode(HeaderDataStructure_1)
	
	PaymentDetails = New Structure;
	PaymentDetails.Insert("RecipientText", HeaderDataStructure_1.SupplierPresentationForErrandBoards);
	PaymentDetails.Insert("RecipientAccountNumber", HeaderDataStructure_1.RecipientAccountPresentation);
	PaymentDetails.Insert("RecipientBankDescription", HeaderDataStructure_1.PayeeBankPresentation);
	PaymentDetails.Insert("RecipientBankBIC", HeaderDataStructure_1.RecipientBankBIC);
	PaymentDetails.Insert("RecipientBankAccount", HeaderDataStructure_1.RecipientBankAccountPresentation);
	PaymentDetails.Insert("AmountAsNumber");
	PaymentDetails.Insert("PaymentPurposes", HeaderDataStructure_1.PaymentPurposes);
	PaymentDetails.Insert("RecipientTIN", HeaderDataStructure_1.TIN);
	PaymentDetails.Insert("RecipientCRTR", HeaderDataStructure_1.CRTR);
	PaymentDetails.Insert("Ref");
	
	Return PaymentDetails
	
EndFunction

Function SelectAttributes(UseInternational, LocalAttributes, InternationalAttributes)
	
	If UseInternational Then
		
		ReturnValue = ?(ValueIsFilled(InternationalAttributes), InternationalAttributes, LocalAttributes);
		
	Else
		
		ReturnValue = LocalAttributes;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
