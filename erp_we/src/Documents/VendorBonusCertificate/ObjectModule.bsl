// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	VendorBonusCertificateLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.AccrualOfVendorRebates") Then
		
		DocumentAccruals = FillingData; // DocumentRef.AccrualOfVendorRebates
		FillInAccordingToAccrualDocument(DocumentAccruals, StandardProcessing);
		ARAPAccountingServer.Filling(ThisObject, DocumentAccruals);
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(
		ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	VendorBonusCertificateLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi chứng từ trong nút phụ trao đổi';
							|ru = 'Запрещено изменение документа в подчиненном узле обмена';
							|en = 'Cannot change the document in a subordinate exchange node'; fa = 'Cannot change the document in a subordinate exchange node';
							|it = 'Запрещено изменение документа в подчиненном узле обмена';
							|pl = 'Cannot change the document in a subordinate exchange node';
							|tr = 'Bağımlı değişim düğümündeki belgenin değiştirilmesi yasaktır'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AmountARAP = Rebates.Total("AmountARAP");
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	SetupParameters = Documents.VendorBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.BeforeWrite(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.VendorBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If IsNew()
	   And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	VendorBonusCertificateLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	VendorBonusCertificateLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	VendorBonusCertificateLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	VendorBonusCertificateLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
	InitializeDocument();
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	For Each TSRow In Rebates Do
		
		CalculationParameters = New Structure;
		CalculationParameters.Insert("Currency", TSRow.BonusCurrency);
		CalculationParameters.Insert("CourseNumerator", TSRow.ExchangeRateNumeratorOfMutualSettlements);
		CalculationParameters.Insert("CourseDenominator", TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements);
		CalculationParameters.Insert("ARAPCurrency", ARAPCurrency);
		
		TSRow.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
			CalculationParameters, TSRow.BonusAmount, CurrencyOfComplianceAccounting);
		
	EndDo;
	
	VendorBonusCertificateLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If GetFunctionalOption("NotUseMultipleCurrencies") Then
		
		ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		
	EndIf;
	
EndProcedure

#Region InputOnBasis

// Parameters:
//  AccrualDocument - DocumentRef.AccrualOfVendorRebates
//  StandardProcessing - Boolean - 
//
Procedure FillInAccordingToAccrualDocument(AccrualDocument, StandardProcessing)
	
	FillingData = Documents.AccrualOfVendorRebates.DataOfAccrualDocument(AccrualDocument);
	
	HeaderData_ = FillingData.Header;
	RowsData = FillingData.RowsData;
	Counterparties = FillingData.Counterparties;
	
	HeaderData_.Next();
	BonusType = HeaderData_.BonusType;
	
	If Counterparties.Count() > 1
	   And BonusType = Enums.VendorRebateTypes.Purchases Then
		
		NotificationText2 = NStr("vi = 'Trong chứng từ tính toán đã chỉ ra một số đối tác. Không thể xác định đối tác để tạo biên bản.';
								|ru = 'В документе начисления указаны несколько контрагентов. Невозможно определить контрагента для создания акта.';
								|en = 'The accrual document contains several counterparties. Cannot identify the counterparty for creating the certificate.'; fa = 'The accrual document contains several counterparties. Cannot identify the counterparty for creating the certificate.';
								|it = 'В документе начисления указаны несколько контрагентов. Невозможно определить контрагента для создания акта.';
								|pl = 'The accrual document contains several counterparties. Cannot identify the counterparty for creating the certificate.';
								|tr = 'Tahakkuk belgesinde çeşitli cari hesaplar belirtilmiş. Fiilin oluşturulması için bir cari hesap tanımlanamaz.'");
		Raise NotificationText2;
		
	Else
		
		FillPropertyValues(ThisObject, HeaderData_);
		ARAPCurrency = HeaderData_.Currency;
		
		If BonusType = Enums.VendorRebateTypes.Purchases
		   And Counterparties.Count() > 0 Then
			
			Counterparties.Next();
			Counterparty = Counterparties.Counterparty;
			
		EndIf;
		
		While RowsData.Next() Do
			
			NewRow = Rebates.Add();
			FillPropertyValues(NewRow, RowsData);
			NewRow.BonusAmount = RowsData.Sum;
			NewRow.AmountARAP = RowsData.Sum;
			NewRow.BonusCurrency = HeaderData_.Currency;
			NewRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf