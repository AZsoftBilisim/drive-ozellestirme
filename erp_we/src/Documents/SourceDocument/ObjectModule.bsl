#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Partner") Then
			If Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
				FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FillingData.Partner));
			EndIf;
			If FillingData.Property("Organization") 
				And ValueIsFilled(FillingData.Organization) 
				And Not FillingData.Property("Currency") Then
				If (TypeOf(FillingData.Organization) = Type("FixedArray")
					Or TypeOf(FillingData.Organization) = Type("Array"))
					And FillingData.Organization.Count() > 0 Then
					FillingData.Insert("Currency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization[0]));
				Else
					FillingData.Insert("Currency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization));
				EndIf;
			EndIf;
		EndIf;
		
		If FillingData.Property("ContractCurrency") Then
			FillingData.Insert("Currency", FillingData.ContractCurrency);
		EndIf;
		
		If FillingData.Property("ARAPObjectSettings") Then
			If TypeOf(FillingData.ARAPObjectSettings) = Type("FixedArray")
				Or TypeOf(FillingData.ARAPObjectSettings) = Type("Array") Then
				If FillingData.ARAPObjectSettings.Find(Enums.ARAPObjectSettings.ByARAPDocuments) <> Undefined Then
					ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
				EndIf;
			EndIf;
		EndIf;
		
		If FillingData.Property("SourceDocumentType")
			And (TypeOf(FillingData.SourceDocumentType) = Type("FixedArray")
				Or TypeOf(FillingData.SourceDocumentType) = Type("Array"))
			And FillingData.SourceDocumentType.Count() > 0 Then
			SourceDocumentType = FillingData.SourceDocumentType[0];
		EndIf;
		
		If FillingData.Property("SourceDocumentType")
			And FillingData.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
			And FillingData.Property("Contract")
			And ValueIsFilled(FillingData.Contract)
			And CommonClientServer.HasAttributeOrObjectProperty(FillingData.Contract, "ARAPObjectSettings") Then
			ARAPObjectSettings = Common.ObjectAttributeValue(FillingData.Contract, "ARAPObjectSettings");
		EndIf;
		
	EndIf;
	
	FillParameters = Documents.SourceDocument.ParametersForFillingInVATTaxation_(ThisObject);
	If FillParameters.Sale Then
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	ElsIf FillParameters.Purchase Then
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	EndIf;
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Date              = BegOfDay(Common.CurrentUserDate());
	DocumentBasis = Undefined;
	PaymentID = Undefined;
	
	FillParameters = Documents.SourceDocument.ParametersForFillingInVATTaxation_(ThisObject);
	If FillParameters.Sale Then
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	ElsIf FillParameters.Purchase Then
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		
		ThereAreAdjustingEntries = False;	
		
		If SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor Then
			
			ThereAreInvoices_1 = False;
			PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
			If ThereAreAdjustingEntries Then
				PurchasesServer.ReportErrorsCancellationsAndAdjustments(Ref, Cancel);
			EndIf;
			
		ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
			
			SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries);
			If ThereAreAdjustingEntries Then
				SalesServer.ReportErrorsCancellationsAndAdjustments(Ref, Cancel);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesReceived(ThisObject);
		VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	EndIf;
	
	If SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesIssued(ThisObject);
		VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	EndIf;
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		
		IncomingDocumentNumber = Number;
		IncomingDocumentDate = Date;
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate Then
		
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
		IncomingDocumentNumber = Number;
		IncomingDocumentDate = Date;
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.VendorBonusCertificate Then
		
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
		
	EndIf;
	
	If Not IsNew() 
		And Not SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement
		And TMCommonUse.DocumentChanges(ThisObject).Property("Attributes") Then
		
		Query = New Query();
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	OBEntryARAPPartnersARAPAccounting.Ref 
		|FROM
		|	Document.OBEntryARAP.PartnersARAPAccounting AS OBEntryARAPPartnersARAPAccounting
		|WHERE
		|	OBEntryARAPPartnersARAPAccounting.DocumentOfARAPAccounting = &DocumentOfARAPAccounting";
		Query.SetParameter("DocumentOfARAPAccounting", Ref);
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			ErrorText = NStr("vi = 'Không thể thay đổi chứng từ đã được dùng trong các chứng từ nhập số dư';
							|ru = 'Документ уже использован в документах ввода остатков, изменение невозможно';
							|en = 'The document is already used in balance entry documents. Cannot change the document.'; fa = 'The document is already used in balance entry documents. Cannot change the document.';
							|it = 'Документ уже использован в документах ввода остатков, изменение невозможно';
							|pl = 'The document is already used in balance entry documents. Cannot change the document.';
							|tr = 'Belge zaten bakiye giriş belgelerinde kullanılmıştır, değişiklik mümkün değildir'");
			Common.MessageToUser(ErrorText, Ref, , , Cancel);
		EndIf;
		
	EndIf;
	If TypeOf(Contract) <> Type("CatalogRef.LeaseContract") Then
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	EndIf;
	AdditionalProperties.Insert("IsNew",    IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	Attributes = Documents.SourceDocument.ArrayOfDetailsByPrimaryDocumentType(SourceDocumentType);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		Attributes.ArrayOfAllProps,
		Attributes.ArrayOfDetailsForType,
		NotCheckedAttributeArray);
	
	If ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts
		And Not SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement
		And Not SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	If Not ValueIsFilled(IncomingDocumentNumber)
		And Not ValueIsFilled(IncomingDocumentDate) Then
		NotCheckedAttributeArray.Add("IncomingDocumentNumber");
		NotCheckedAttributeArray.Add("IncomingDocumentDate");
	EndIf; 
	
	// If the number was not filled in manually according to the data of the previous system, it will be generated automatically.
	NotCheckedAttributeArray.Add("Number"); 
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
	If ValueIsFilled(Organization) And Organization = Counterparty Then
		Common.MessageToUser(
			NStr("vi = 'Doanh nghiệp và đối tác không được trùng';
				|ru = 'Организация и контрагент не должны совпадать';
				|en = 'Company and counterparty should not match'; fa = 'Company and counterparty should not match';
				|it = 'L''azienda ed il contraente non devono coincidere';
				|pl = 'Firma i kontrahent nie mogą się pokrywać';
				|tr = 'İş yeri ve cari hesap aynı olmamalıdır'"),
			ThisObject,
			"Counterparty",
			,
			Cancel);
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)

	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If Not SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesReceived(ThisObject);
		VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	EndIf;
	If SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesIssued(ThisObject);
		VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)

	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Not SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesReceived(ThisObject);
		VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	EndIf;
	If SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesIssued(ThisObject);
		VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData)
	
	DataIsStructure = (TypeOf(FillingData) = Type("Structure"));
	
	If DataIsStructure And FillingData.Property("Organization") Then
		If (TypeOf(FillingData.Organization) = Type("FixedArray")
				Or TypeOf(FillingData.Organization) = Type("Array"))
			And FillingData.Organization.Count() > 0 Then
			Organization = FillingData.Organization[0];
		Else
			Organization = FillingData.Organization;
		EndIf;
	Else
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If Not DataIsStructure Or Not FillingData.Property("Counterparty") Then
		Counterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	
	If Not DataIsStructure Or Not FillingData.Property("Contract") Then
		If DataIsStructure 
			And FillingData.Property("Partner")
			And FillingData.Partner = Catalogs.Partners.OurEnterprise Then
			Contract = Catalogs.IntercompanyContracts.EmptyRef();
		Else
			Contract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;
	
	If Not DataIsStructure Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If DataIsStructure
		And FillingData.Property("Contract") Then
		FillPropertyValues(
			ThisObject,
			Common.ObjectAttributesValues(
				FillingData.Contract,
				"Department, LineOfBusiness, VATTaxation, FinancialAccountingGroup"));
	EndIf;
	
	If DataIsStructure
		And FillingData.Property("AdvanceReportData") Then
		
		AdvanceReportData = FillingData.AdvanceReportData;
		
		Organization = AdvanceReportData.Organization;
		Department = AdvanceReportData.Department;
		Date = AdvanceReportData.Date;
		VATTaxation = AdvanceReportData.VATTaxation;
		SourceDocumentType = AdvanceReportData.SourceDocumentType;
		IncomingDocumentNumber = AdvanceReportData.IncomingDocumentNumber;
		IncomingDocumentDate = AdvanceReportData.IncomingDocumentDate;
		Counterparty = AdvanceReportData.Counterparty;
		Currency = AdvanceReportData.Currency;
		DocumentAmount = AdvanceReportData.DocumentAmount;
		SumCompl = AdvanceReportData.SumCompl;
			
	EndIf;
	
	If DataIsStructure And FillingData.Property("Number") Then
		Number = FillingData.Number;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
