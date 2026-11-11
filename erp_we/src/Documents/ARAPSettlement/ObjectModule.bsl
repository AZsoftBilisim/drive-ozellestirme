#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If ValueIsFilled(FillingData) Then
		
		FillInDataType = TypeOf(FillingData);
		
		If FillInDataType = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			ActivitiesForAcquisitionOfServicesOtherAssets(FillingData);
		ElsIf FillInDataType = Type("DocumentRef." + Metadata().Name) Then
			DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		EndIf;
		
	EndIf;
	
	ARAPSettlementLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	AccountsReceivableWithoutDivision=False;
	If AdditionalProperties.Property("AccountsReceivableWithoutDivision")
		And AdditionalProperties.AccountsReceivableWithoutDivision Then
		AccountsReceivableWithoutDivision = True;
	EndIf;
	
	AccountsPayableWithoutSplitting=False;
	If AdditionalProperties.Property("AccountsPayableWithoutSplitting")
		And AdditionalProperties.AccountsPayableWithoutSplitting Then
		AccountsPayableWithoutSplitting = True;
	EndIf;
	
	Documents.ARAPSettlement.FillInNamesOfBankingDetailsByTypeOfOperation(
		OperationKind,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
		
	CommissionOffset = OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
		Or OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent;
	
	BarterOrArbitrary = OperationKind = Enums.KindsOfARAPSettlements.Barter
		Or OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.Arbitrary
		Or CommissionOffset;
	// Let's check the correspondence of the amounts of the document and the tabular part.
	If BarterOrArbitrary And AccountsReceivable.Total("SumCompl") <> AccountsPayable.Total("SumCompl") Then
		MessageText = NStr("vi = 'Tổng số tiền của kế toán tài chính tại các phần bảng phải bằng nhau.';
							|ru = 'Итоговые суммы регламентированного учета в табличных частях должны быть равны между собой.';
							|en = 'Total local accounting amounts in tables must be equal.'; fa = 'Total local accounting amounts in tables must be equal.';
							|it = 'Итоговые суммы регламентированного учета в табличных частях должны быть равны между собой.';
							|pl = 'Total local accounting amounts in tables must be equal.';
							|tr = 'Tablodaki yerel muhasebe tutarları birbirine eşit olmalıdır.'");
		Common.MessageToUser(
			MessageText,
			ThisObject,
			, // Field
			,
			Cancel);
	EndIf;
	
	// Let's check the correspondence of the amounts of the document and the tabular part.
	If BarterOrArbitrary And AccountsReceivable.Total("SumMan") <> AccountsPayable.Total("SumMan") Then
		MessageText = NStr("vi = 'Tổng số tiền của kế toán quản trị tại các phần bảng phải bằng nhau.';
							|ru = 'Итоговые суммы управленческого учета в табличных частях должны быть равны между собой.';
							|en = 'Total management accounting amounts in tables must be equal.'; fa = 'Total management accounting amounts in tables must be equal.';
							|it = 'Итоговые суммы управленческого учета в табличных частях должны быть равны между собой.';
							|pl = 'Total management accounting amounts in tables must be equal.';
							|tr = 'Tablodaki yönetim muhasebesi tutarları birbirine eşit olmalıdır.'");
		Common.MessageToUser(
			MessageText,
			ThisObject,
			, // Field
			,
			Cancel);
	EndIf;
	
	// Let's check the correspondence of the amounts of the document and the tabular part.
	If Not BarterOrArbitrary And Not CommissionOffset And AccountsReceivable.Total("AmountARAP") <> AccountsPayable.Total("AmountARAP") Then
		MessageText = NStr("vi = 'Tổng số tiền hạch toán tại các phần bảng phải bằng nhau';
							|ru = 'Итоговые суммы взаиморасчетов в табличных частях должны быть равны между собой';
							|en = 'Total AR/AP accounting amounts in tables must be equal'; fa = 'Total AR/AP accounting amounts in tables must be equal';
							|it = 'Итоговые суммы взаиморасчетов в табличных частях должны быть равны между собой';
							|pl = 'Total AR/AP accounting amounts in tables must be equal';
							|tr = 'Tablodaki alacak/borç muhasebesi tutarları birbirine eşit olmalıdır'");
		Common.MessageToUser(
			MessageText,
			ThisObject,
			, // Field
			,
			Cancel);
	EndIf;
	
	If Not CommissionOffset And AccountsReceivableWithoutDivision And AccountsReceivable.Count() > 0 And Not ValueIsFilled(AccountsReceivable[0].ARAPCurrency) Then
		MessageText = NStr("vi = 'Chưa điền Tiền tệ tài khoản phải thu';
							|ru = 'Не заполнена Валюта взаиморасчетов Дебиторской задолженности';
							|en = 'Settlements currency for receivables is required'; fa = 'Settlements currency for receivables is required';
							|it = 'Non è compilata la Valuta delle regolazioni dei conti reciproche per i Crediti correnti';
							|pl = 'Nie wypełniono Waluty wzajemnych rozliczeń należności';
							|tr = 'Alacakların mutabakat Para birimi doldurulmadı'");
		Common.MessageToUser(
			MessageText,
			,
			"Items.AccountsReceivable.CurrentData.ARAPCurrency",
			,
			Cancel);
		NotCheckedAttributeArray.Add("AccountsReceivable.ARAPCurrency");
	EndIf;
	
	If Not CommissionOffset And AccountsPayableWithoutSplitting And AccountsPayable.Count() > 0 And Not ValueIsFilled(AccountsPayable[0].ARAPCurrency) Then
		MessageText = NStr("vi = 'Chưa điền Tiền tệ của các tài khoản phải trả';
							|ru = 'Не заполнена Валюта взаиморасчетов Кредиторской задолженности';
							|en = 'Settlements currency for payables is required'; fa = 'Settlements currency for payables is required';
							|it = 'Non è compilata la Valuta delle regolazioni dei conti reciproche per i Debiti correnti';
							|pl = 'Nie wypełniono Waluty wzajemnych rozliczeń zobowiązań';
							|tr = 'Borçların mutabakat Para birimi doldurulmadı'");
		Common.MessageToUser(
			MessageText,
			,
			"Items.AccountsPayable.CurrentData.ARAPCurrency",
			,
			Cancel);
		NotCheckedAttributeArray.Add("AccountsPayable.ARAPCurrency");
	EndIf;
	
	If Not BarterOrArbitrary Then
		DrDebt = AccountsReceivable.Unload();
		DrDebt.GroupBy("ARAPCurrency");
		CrDebt = AccountsPayable.Unload();
		CrDebt.GroupBy("ARAPCurrency");
		If DrDebt.Count() > 0 And CrDebt.Count() > 0 Then
			If DrDebt.Count() > 1 Or CrDebt.Count() > 1
				Or DrDebt[0].ARAPCurrency <> CrDebt[0].ARAPCurrency Then
				MessageText = NStr("vi = 'Không hỗ trợ chuyển công nợ giữa các tiền tệ hạch toán công nợ khác nhau';
									|ru = 'Перенос задолженности между разными валютами взаиморасчетов не поддерживается';
									|en = 'Debt transfer between different settlement currencies is not supported'; fa = 'Debt transfer between different settlement currencies is not supported';
									|it = 'Il trasferimento del debito tra diverse valute dei conti reciproci non è supportato';
									|pl = 'Przeniesienie zadłużenia między różnymi walutami rozliczeń wzajemnych nie jest obsługiwane';
									|tr = 'Farklı mutabakat para birimleri arasında borç transferi desteklenmiyor'");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					, // Field
					,
					Cancel);
			EndIf;
		EndIf;
	EndIf;
	
	If OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany Then
			NotCheckedAttributeArray.Add("ARAPObjectIntercompany");
	EndIf;
	
	If (CounterpartyDebtorType <> Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			And CounterpartyDebtorType <> Enums.ARAPSettlemenParticipantTypes.CompanyVendor
			And CounterpartyCreditorType <> Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			And CounterpartyCreditorType <> Enums.ARAPSettlemenParticipantTypes.CompanyVendor)
		Or CounterpartyDebtor = Creditor
		Or OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies Then
		NotCheckedAttributeArray.Add("ARAPObjectDebtorCreditor");
	EndIf;
	
	If CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		Or CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor Then
		NotCheckedAttributeArray.Add("AccountsReceivable.Partner");
	EndIf;
	If CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		Or CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor Then
		NotCheckedAttributeArray.Add("AccountsPayable.Partner");
	EndIf;
	If OperationKind <> Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty
		And OperationKind <> Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		Or Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		NotCheckedAttributeArray.Add("AccountsReceivable.PaymentDate");
	EndIf;
	If OperationKind <> Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
		And OperationKind <> Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany
		Or Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		NotCheckedAttributeArray.Add("AccountsPayable.PaymentDate");
	EndIf;
	
	If CommissionOffset Then
		
		NotCheckedAttributeArray.Add("AccountsPayable.AmountARAP");
		NotCheckedAttributeArray.Add("AccountsReceivable.AmountARAP");
		NotCheckedAttributeArray.Add("AccountsPayable.ARAPObject");
		NotCheckedAttributeArray.Add("AccountsReceivable.ARAPObject");
		NotCheckedAttributeArray.Add("AccountsPayable.Partner");
		NotCheckedAttributeArray.Add("AccountsReceivable.Partner");
		NotCheckedAttributeArray.Add("AccountsPayable.ARAPCurrency");
		NotCheckedAttributeArray.Add("AccountsReceivable.ARAPCurrency");
		NotCheckedAttributeArray.Add("CounterpartyDebtor");
		NotCheckedAttributeArray.Add("Creditor");
		
		If AccountsReceivable.Count() = 1 And AccountsPayable.Count() = 1 Then
			
			If AccountsReceivable[0].AmountARAP = 0 Or AccountsPayable[0].AmountARAP = 0 Then
				MessageTextErrorByAmount = NStr("vi = 'Chưa điền số tiền';
												|ru = 'Не заполнена сумма';
												|en = 'Amount is not filled in'; fa = 'Amount is not filled in';
												|it = 'Importo non compilato';
												|pl = 'Nie wypełniono kwoty';
												|tr = 'Tutar doldurulmadı'");
				Common.MessageToUser(
					MessageTextErrorByAmount,
					ThisObject,
					, // Field
					,
					Cancel);
				EndIf;
				
			If (OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
				And Not ValueIsFilled(Creditor))
				Or (OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent
				And Not ValueIsFilled(CounterpartyDebtor)) Then
				MessageText = NStr("vi = 'Chưa điền người nhận ký gửi';
									|ru = 'Не заполнен комиссионер';
									|en = 'Consignee is not filled in'; fa = 'Consignee is not filled in';
									|it = 'Commissionario non compilato';
									|pl = 'Komisant nie jest wypełniony';
									|tr = 'Konsinye doldurulmadı'");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					, // Field
					,
					Cancel);
			EndIf;
					
			If (OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
				And Not ValueIsFilled(CounterpartyDebtor))
				Or (OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent
				And Not ValueIsFilled(Creditor)) Then
				MessageText = NStr("vi = 'Chưa điền khách hàng';
									|ru = 'Не заполнен клиент';
									|en = 'Customer is not filled in'; fa = 'Customer is not filled in';
									|it = 'Cliente non compilato';
									|pl = 'Nabywca nie jest wypełniony';
									|tr = 'İstemci doldurulmadı'");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					, // Field
					,
					Cancel);
			EndIf;
				
			
			If Not ValueIsFilled(AccountsReceivable[0].ARAPObject) Or Not ValueIsFilled(AccountsPayable[0].ARAPObject) Then
				MessageText = NStr("vi = 'Chưa điền đối tượng hạch toán';
									|ru = 'Не заполнен объект расчетов';
									|en = 'AR/AP object is not filled in'; fa = 'AR/AP object is not filled in';
									|it = 'Non è stato compilato l''oggetto di regolamenti';
									|pl = 'Nie wypełniono obiektu rozliczeń';
									|tr = 'Alacak/Borç nesnesi doldurulmadı'");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					, // Field
					,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(AccountsReceivable[0].Partner) Or Not ValueIsFilled(AccountsPayable[0].Partner) Then
				MessageText = NStr("vi = 'Chưa điền bạn hàng';
									|ru = 'Не заполнен партнер';
									|en = 'Partner is not filled in'; fa = 'Partner is not filled in';
									|it = 'Partner non compilato';
									|pl = 'Partner nie jest wypełniony';
									|tr = 'İş ortağı doldurulmadı'");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					, // Field
					,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(AccountsReceivable[0].ARAPCurrency) Or Not ValueIsFilled(AccountsPayable[0].ARAPCurrency) Then
				MessageText = NStr("vi = 'Chưa điền tiền tệ hạch toán công nợ';
									|ru = 'Не заполнена валюта взаиморасчетов';
									|en = 'AR/AP currency is not filled in'; fa = 'AR/AP currency is not filled in';
									|it = 'Valuta dei conti reciproci non compilata';
									|pl = 'Nie wypełniono waluty rozliczeń wzajemnych';
									|tr = 'Mutabakat para birimi doldurulmadı'");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					, // Field
					,
					Cancel);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If AdditionalProperties.Property("ListNameDr") Then
		CheckFillingOfTablePart("AccountsReceivable", AdditionalProperties.ListNameDr, NotCheckedAttributeArray, Cancel);
	EndIf;
	
	If AdditionalProperties.Property("ListNameCr") Then
		CheckFillingOfTablePart("AccountsPayable", AdditionalProperties.ListNameCr, NotCheckedAttributeArray, Cancel);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	PresentationsStructure = Documents.ARAPSettlement.PresentationOfBankingDetailsByTypeOfOperation(OperationKind);
	CheckIfLegalEntitiesMatch("CounterpartyDebtor", PresentationsStructure.CounterpartyDebtor, Cancel);
	If NotCheckedAttributeArray.Find("Creditor") = Undefined Then
		CheckIfLegalEntitiesMatch("Creditor", PresentationsStructure.Creditor, Cancel);
	EndIf;
	If NotCheckedAttributeArray.Find("CompanyCreditor") = Undefined Then
		CheckIfLegalEntitiesMatch("CompanyCreditor", PresentationsStructure.CompanyCreditor, Cancel);
	EndIf;
	
	ARAPSettlementLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If ValueIsFilled(OperationKind)
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
		And OperationKind <> Enums.KindsOfARAPSettlements.PaymentByGiftCard
		And OperationKind <> Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
		And OperationKind <> Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties
		And OperationKind <> Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties
		And OperationKind <> Enums.KindsOfARAPSettlements.Barter
		And OperationKind <> Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies
		And OperationKind <> Enums.KindsOfARAPSettlements.Arbitrary
		And OperationKind <> Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
		And OperationKind <> Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
		
		Creditor = CounterpartyDebtor;
		CounterpartyCreditorType = CounterpartyDebtorType;
		
	ElsIf ValueIsFilled(OperationKind)
		And (OperationKind = Enums.KindsOfARAPSettlements.Barter
			Or OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies) Then
		
		Creditor = CounterpartyDebtor;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "AccountsReceivable,AccountsPayable");
	
	// Filling in the details in the tabular parts.
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInAccordingToCalculationObjects(Cancel);
		FillInCurrencyAmountOfDocument();
		
		SumCompl = AccountsReceivable.Total("SumCompl");
		SumMan = AccountsReceivable.Total("SumMan");
		
		FillInCalculationTypeInTablePart(AccountsReceivable, CounterpartyDebtorType);
		FillInCalculationTypeInTablePart(AccountsPayable, CounterpartyCreditorType);
		
		SettlementsBetweenCompaniesDebtor =
			CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			Or CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
		
		SettlementsBetweenCompaniesCreditor =
			CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			Or CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
		
		If Not SettlementsBetweenCompaniesDebtor And ValueIsFilled(CounterpartyDebtor) Then
			PartnerDebtor = CashServer.GetCounterpartyPartner(CounterpartyDebtor);
			FillInPartnerInTablePart(AccountsReceivable, PartnerDebtor, SettlementsBetweenCompaniesDebtor);
			If OperationKind = Enums.KindsOfARAPSettlements.Barter Then
				FillInPartnerInTablePart(AccountsPayable, PartnerDebtor, SettlementsBetweenCompaniesCreditor);
			EndIf;
		EndIf;
		
		If Not SettlementsBetweenCompaniesCreditor And ValueIsFilled(Creditor) Then
			PartnerCreditor = CashServer.GetCounterpartyPartner(Creditor);
			FillInPartnerInTablePart(AccountsPayable, PartnerCreditor, SettlementsBetweenCompaniesCreditor);
		EndIf;
		
	EndIf;
	
	ARAPSettlementLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ARAPSettlementLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "AccountsReceivable,AccountsPayable");
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ARAPSettlementLocalization.Posting(ThisObject, Cancel, PostingMode);
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ARAPSettlementLocalization.UndoPosting(ThisObject, Cancel);
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If Not Users.IsFullUser()
		And Users.RolesAvailable("AddEditARAPAdjustmentDocumentsPaymentOffset") Then
		OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty;
	EndIf;
	
EndProcedure

Procedure ActivitiesForAcquisitionOfServicesOtherAssets(Val DocumentBasis)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Documents.Ref AS Ref
	|INTO Documents
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS Documents
	|WHERE
	|	Documents.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS CounterpartyDebtor,
	|	DocumentData.Counterparty AS Creditor,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Department AS Department,
	|	DocumentData.Director AS Director,
	|	DocumentData.Partner AS PartnerDebtor,
	|	DocumentData.Partner AS PartnerCreditor,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	VALUE(Enum.ARAPSettlemenParticipantTypes.Client) AS CounterpartyDebtorType,
	|	VALUE(Enum.ARAPSettlemenParticipantTypes.Vendor) AS CounterpartyCreditorType,
	|	VALUE(Enum.KindsOfARAPSettlements.Arbitrary) AS OperationKind,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.AmountARAP AS AmountARAP
	|FROM
	|	Documents AS Documents
	|		INNER JOIN Document.VendorInvoiceServicesAndAssets AS DocumentData
	|		ON Documents.Ref = DocumentData.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	ARAPObjects.Ref AS ARAPObject,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_
	|FROM
	|	Documents AS Documents
	|		INNER JOIN Document.VendorInvoiceServicesAndAssets AS DocumentData
	|			ON Documents.Ref = DocumentData.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON (DocumentData.ARAPObject.Object = ARAPObjects.Object)
	|				AND (ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_
	|FROM
	|	Documents AS Documents
	|		INNER JOIN Document.VendorInvoiceServicesAndAssets AS DocumentData
	|			ON Documents.Ref = DocumentData.Ref";
	
	Query.SetParameter("Ref", DocumentBasis);
	QueryResult = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResult[1].Select();
	
	If HeaderAttributes.Next() Then
	
		FillPropertyValues(ThisObject, HeaderAttributes);
		AccountsReceivable.Load(QueryResult[2].Unload());
		AccountsPayable.Load(QueryResult[3].Unload());
		
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(HeaderAttributes.Organization);
		ManagementAccountingCurrency     = Constants.ManagementAccountingCurrency.Get();
		
		If Currency = LocalAccountingCurrency Then
			SumCompl = DocumentAmount;
		ElsIf SumCompl = 0 Then
			SumCompl = ProcessingOfExchangeRatesTM.ConvertToCurrency(DocumentAmount,
				LocalAccountingCurrency,
				Currency,
				LocalAccountingCurrency,
				Date,
				HeaderAttributes.ARAPObject);
		EndIf;
		
		If Currency = ManagementAccountingCurrency Then
			SumMan = DocumentAmount;
		ElsIf SumMan = 0 Then
			SumMan = ProcessingOfExchangeRatesTM.ConvertToCurrency(DocumentAmount,
				LocalAccountingCurrency,
				Currency,
				ManagementAccountingCurrency,
				Date,
				HeaderAttributes.ARAPObject);
		EndIf;
		
		ArrayOfTabularParts = New Array;
		ArrayOfTabularParts.Add("AccountsReceivable");
		ArrayOfTabularParts.Add("AccountsPayable");
		
		For Each TabularSection In ArrayOfTabularParts Do
			If ThisObject[TabularSection].Count() Then
				TableRow = ThisObject[TabularSection][0];
				TableRow.SumCompl = SumCompl;
				TableRow.SumMan = SumMan;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckIfLegalEntitiesMatch(Attribute, Presentation, Cancel)
	
	Entity = ThisObject[Attribute];
	If ValueIsFilled(Organization) And ValueIsFilled(Entity) And (Organization = Entity) Then
		Text = NStr("vi = 'Doanh nghiệp và %Counterparty% phải khác nhau.';
					|ru = 'Организация и %Counterparty% должны различаться.';
					|en = 'Company and %Counterparty% should be different.'; fa = 'Company and %Counterparty% should be different.';
					|it = 'La società e %Counterparty% devono differire.';
					|pl = 'Firma i %Counterparty% powinni się różnić';
					|tr = 'İş yeri ve %Counterparty% farklı olmalı.'");
		Text = StrReplace(Text,"%Counterparty%", Presentation);
		Common.MessageToUser(Text, ThisObject, Attribute,, Cancel);
	EndIf;
EndProcedure

Procedure FillInCalculationTypeInTablePart(TabularSection, TypeOfCounterparty)
	
	If ValueIsFilled(TypeOfCounterparty) Then
		
		If OperationKind = Enums.KindsOfARAPSettlements.Barter Then
			
			If TabularSection = AccountsReceivable Then
				PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
			Else
				PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
			EndIf;
			
		Else
			
			If TypeOfCounterparty = Enums.ARAPSettlemenParticipantTypes.Client
				Or TypeOfCounterparty = Enums.ARAPSettlemenParticipantTypes.OrganizationClient Then
				PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
			Else
				PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
			EndIf;
			
		EndIf;
		
		For Each TableRow In TabularSection Do
			TableRow.PaymentType_ = PaymentType_;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInPartnerInTablePart(ObjectTablePart, PartnerLink, IntercompanyARAP)
	For Each TableRow In ObjectTablePart Do
		If IntercompanyARAP Then
			TableRow.Partner = Undefined;
		ElsIf Not ValueIsFilled(TableRow.Partner) Then
			TableRow.Partner = PartnerLink;
		EndIf;
	EndDo;
EndProcedure

Procedure FillInAccordingToCalculationObjects(Cancel = False) Export

	QueriesTexts = New Array;
	QueriesTexts.Add(TemporaryTableQueryText("AccountsReceivable"));
	QueriesTexts.Add(TemporaryTableQueryText("AccountsPayable"));
	
	QueriesTexts.Add(QueryTextForTabularPart("AccountsReceivable"));
	QueriesTexts.Add(QueryTextForTabularPart("AccountsPayable"));
	
	QueriesTexts.Add(RequestTextByDocumentDetails("ARAPObjectIntercompany"));
	QueriesTexts.Add(RequestTextByDocumentDetails("ARAPObjectDrCr"));
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("AccountsReceivable", AccountsReceivable.Unload());
	Query.SetParameter("AccountsPayable", AccountsPayable.Unload());
	Query.SetParameter("ARAPObjectIntercompany", ARAPObjectIntercompany);
	Query.SetParameter("ARAPObjectDrCr", ARAPObjectDebtorCreditor);
	
	QueryResults = Query.ExecuteBatch();
	
	CheckMirrorObjectOfCalculations(AccountsReceivable, QueryResults[2].Unload(), True, Cancel);
	CheckMirrorObjectOfCalculations(AccountsPayable, QueryResults[3].Unload(), False, Cancel);
	
	Intercompany = QueryResults[4].Unload();
	If Intercompany.Count() > 0 Then
		ARAPObjectIntercompanyMirrored = Intercompany[0].ARAPObjectMirror;
		If Not ValueIsFilled(ARAPObjectIntercompanyMirrored) Then
			ReportMirroredCalculationObjectIsNotFilled(Intercompany[0], Cancel);
		EndIf;
	EndIf;
	
	ThreeCompanies = 
		(CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			Or CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor)
		And (CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
				Or CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor);
	
	DrCr = QueryResults[5].Unload();
	If ThreeCompanies And DrCr.Count() > 0 Then
		ARAPObjectDebtorCreditorMirror = DrCr[0].ARAPObjectMirror;
		If Not ValueIsFilled(ARAPObjectDebtorCreditorMirror) Then
			ReportMirroredCalculationObjectIsNotFilled(DrCr[0], Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInCurrencyAmountOfDocument()
	
	Dr = AccountsReceivable.Unload();
	Dr.GroupBy("ARAPCurrency","AmountARAP");
	
	Cr = AccountsPayable.Unload();
	Cr.GroupBy("ARAPCurrency","AmountARAP");
	
	DocumentAmount = 0;
	Currency = Undefined;
	If Dr.Count() = 1 And Cr.Count() = 1 
		And Dr[0].ARAPCurrency = Cr[0].ARAPCurrency Then
			DocumentAmount = Dr[0].AmountARAP;
			Currency = Dr[0].ARAPCurrency;
	EndIf;
	
EndProcedure

Procedure CheckMirrorObjectOfCalculations(Debt_, DebtData, ThisIsDebit, Cancel)
	
	Check = 
		ThisIsDebit 
			And (CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
				Or CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor)
		Or Not ThisIsDebit 
			And (CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
				Or CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor);
	
	Debt_.Clear();
	For Each Data In DebtData Do
		NewRecord = Debt_.Add();
		FillPropertyValues(NewRecord, Data);
		If Check And Not ValueIsFilled(NewRecord.ARAPObjectMirror) Then
			ReportMirroredCalculationObjectIsNotFilled(Data, Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure ReportMirroredCalculationObjectIsNotFilled(Data, Cancel = False)
	
	MessageText = NStr("vi = 'Không thể tìm thấy đối tượng hạch toán đã sao chép cho %1.
		|Đối tượng hạch toán đã sao chép cần được lập cho doanh nghiệp ""%2""
		|với số %3 và ngày %4 với số tiền và tiền tệ như nhau.';
		|ru = 'Не удалось найти зеркальный объект расчетов для %1.
		|Зеркальный объект расчетов должен быть оформлен от организации ""%2""
		|с номером %3 и датой %4, на ту же сумму в той же валюте.';
		|en = 'Could not find a mirrored AR/AP object for %1.
		|The mirrored AR/AP object must be generated using company ""%2"",
		|with number %3 and date %4, for the same amount in the same currency.'; fa = 'Could not find a mirrored AR/AP object for %1.
		|The mirrored AR/AP object must be generated using company ""%2"",
		|with number %3 and date %4, for the same amount in the same currency.';
		|it = 'Non è stato possibile trovare l''elemento speculare dei conti per %1. 
		|L''oggetto speculare dei conti deve essere compilato dall''organizzazione ""%2""
		| con numero %3 in data %4 per la medesima somma e valuta.';
		|pl = 'Nie udało się znaleźć odwrotnego obiektu rozliczeń dla %1.
		|Obiekt odwrotny rozliczeń powinien być utworzony od imienia firmy""%2""
		|z numerem%3 i datą %4, o tej samej wartości w tej samej walucie.';
		|tr = '%1 için yansıtıcı alacak/borç nesnesi bulunamadı.
		|Yansıtıcı alacak/borç nesnesi, ""%2"" iş yerinden 
		|%3 numaralı ve %4 tarihli, aynı tutarda, aynı para biriminde düzenlenmiş olmalıdır.'");
	If Data.ARAPObjectType = Type("DocumentRef.BankAccountIssue")
		Or Data.ARAPObjectType = Type("DocumentRef.BankAccountReceiptNote") Then
		MessageText = StrReplace(MessageText, 
							NStr("vi = 'có số %3 và ngày %4';
								|ru = 'с номером %3 и датой %4';
								|en = 'with number %3 and date %4'; fa = 'with number %3 and date %4';
								|it = 'con numero %3 in data %4';
								|pl = 'z numerem %3 i datą %4';
								|tr = '%3 numarayla ve %4 tarihli'"), 
							NStr("vi = 'có số %3 và ngày %4 theo ngân hàng';
								|ru = 'с номером %3 и датой %4 по банку';
								|en = 'with number %3 and date %4 according to bank'; fa = 'with number %3 and date %4 according to bank';
								|it = 'con numero %3 in data %4 per banca';
								|pl = 'z numerem %3 i datą %4 wg banku';
								|tr = 'bankaya göre %3 numarayla ve %4 tarihli'"));
	EndIf;
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
		Data.ARAPObject,
		Data.MirrorOrganization,
		Data.Number,
		Format(Data.Date, "DLF=D"));
	
	Common.MessageToUser(
		MessageText,
		ThisObject,
		, // Field
		,
		Cancel);
	
EndProcedure

Function TemporaryTableQueryText(TableName)
	
	QueryText =  
	"SELECT
	|	DocumentData.LineNumber                     AS LineNumber,
	|	DocumentData.PaymentType_                     AS PaymentType_,
	|	DocumentData.ARAPObject                  AS ARAPObject,
	|	DocumentData.ARAPObjectMirror        AS ARAPObjectMirror,
	|
	|	DocumentData.Partner                         AS Partner,
	|	DocumentData.LineOfBusiness         AS LineOfBusiness,
	|	
	|	DocumentData.ARAPCurrency            AS ARAPCurrency,
	|	DocumentData.AmountARAP             AS AmountARAP,
	|
	|	DocumentData.Sum                           AS Sum,
	|	CASE WHEN DocumentData.ARAPCurrency = &LocalAccountingCurrency
	|		THEN DocumentData.AmountARAP
	|		ELSE DocumentData.SumCompl
	|	END                                           AS SumCompl,
	|	CASE WHEN DocumentData.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN DocumentData.AmountARAP
	|		ELSE DocumentData.SumMan
	|	END                                           AS SumMan,
	|	
	|	DocumentData.RowID             AS RowID
	|
	|INTO TempTable
	|FROM
	|	&AccountsReceivable AS DocumentData
	|
	|INDEX BY
	|	ARAPObject";
	
	If TableName = "AccountsPayable" Then
		QueryText = StrReplace(QueryText, "TTAccountsReceivable", "TTAccountsPayable");
		QueryText = StrReplace(QueryText, "&AccountsReceivable", "&AccountsPayable");
	EndIf;
	QueryText = StrReplace(QueryText, "TempTable", "TT" + TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextForTabularPart(TableName)
	
	QueryText =  
	"//AccountsReceivable
	|SELECT
	|	AccountsReceivable.LineNumber            AS LineNumber,
	|	AccountsReceivable.PaymentType_            AS PaymentType_,
	|	AccountsReceivable.ARAPObject         AS ARAPObject,
	|	VALUETYPE(ARAPObjects.Object)             AS ARAPObjectType,
	|	MirrorObjectOfCalculations.Ref                 AS ARAPObjectMirror,
	|
	|	AccountsReceivable.Partner                AS Partner,
	|	AccountsReceivable.LineOfBusiness AS LineOfBusiness,
	|	
	|	AccountsReceivable.ARAPCurrency   AS ARAPCurrency,
	|	AccountsReceivable.AmountARAP    AS AmountARAP,
	|
	|	AccountsReceivable.Sum                  AS Sum,
	|	AccountsReceivable.SumCompl              AS SumCompl,
	|	AccountsReceivable.SumMan               AS SumMan,
	|	
	|	AccountsReceivable.RowID    AS RowID,
	|	ARAPObjects.Organization                     AS Organization,
	|	ARAPObjects.Counterparty                      AS MirrorOrganization,
	|	CASE
	|		WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountReceiptNote)
	|				OR VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountIssue)
	|			THEN 
	|				ARAPObjects.IncomingDocumentDate
	|		ELSE 
	|			ARAPObjects.Date
	|	END AS Date,
	|	CASE
	|		WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountReceiptNote)
	|				OR VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountIssue)
	|			THEN 
	|				ARAPObjects.IncomingDocumentNumber
	|		ELSE 
	|			ARAPObjects.Number
	|	END AS Number
	|FROM
	|	TempTable AS AccountsReceivable
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = AccountsReceivable.ARAPObject
	|		LEFT JOIN Catalog.ARAPObjects AS MirrorObjectOfCalculations
	|			ON MirrorObjectOfCalculations.Organization = ARAPObjects.Counterparty
	|				AND MirrorObjectOfCalculations.PaymentType_ = 
	|					CASE WHEN ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|						THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|						ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					END
	|				AND CASE
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountReceiptNote)
	|						THEN VALUETYPE(MirrorObjectOfCalculations.Object) = TYPE(Document.BankAccountIssue)
	|							AND MirrorObjectOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectOfCalculations.IncomingDocumentDate = ARAPObjects.IncomingDocumentDate
	|							AND MirrorObjectOfCalculations.IncomingDocumentNumber = ARAPObjects.IncomingDocumentNumber
	|							AND MirrorObjectOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountIssue)
	|						THEN VALUETYPE(MirrorObjectOfCalculations.Object) = TYPE(Document.BankAccountReceiptNote)
	|							AND MirrorObjectOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectOfCalculations.IncomingDocumentDate = ARAPObjects.IncomingDocumentDate
	|							AND MirrorObjectOfCalculations.IncomingDocumentNumber = ARAPObjects.IncomingDocumentNumber
	|							AND MirrorObjectOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.CashAccountReceiptNote)
	|						THEN VALUETYPE(MirrorObjectOfCalculations.Object) = TYPE(Document.CashVoucher)
	|							AND MirrorObjectOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectOfCalculations.Date = ARAPObjects.Date
	|							AND MirrorObjectOfCalculations.Number = ARAPObjects.Number
	|							AND MirrorObjectOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.CashVoucher)
	|						THEN VALUETYPE(MirrorObjectOfCalculations.Object) = TYPE(Document.CashAccountReceiptNote)
	|							AND MirrorObjectOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectOfCalculations.Date = ARAPObjects.Date
	|							AND MirrorObjectOfCalculations.Number = ARAPObjects.Number
	|							AND MirrorObjectOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.SourceDocument)
	|						THEN VALUETYPE(MirrorObjectOfCalculations.Object) = TYPE(Document.SourceDocument)
	|							AND MirrorObjectOfCalculations.Sum = ARAPObjects.Sum
	|							AND BEGINOFPERIOD(MirrorObjectOfCalculations.Date, DAY) = BEGINOFPERIOD(ARAPObjects.Date, DAY)
	|							AND MirrorObjectOfCalculations.Number = ARAPObjects.Number
	|							AND MirrorObjectOfCalculations.Currency = ARAPObjects.Currency
	|					ELSE MirrorObjectOfCalculations.Object = ARAPObjects.Object
	|				END
	|ORDER BY
	|	LineNumber";
	
	If TableName = "AccountsPayable" Then
		QueryText = StrReplace(QueryText, "TTAccountsReceivable", "TTAccountsPayable");
		QueryText = StrReplace(QueryText, "AccountsReceivable", TableName);
	EndIf;
	QueryText = StrReplace(QueryText, "TempTable", "TT" + TableName);
	
	Return QueryText;
	
EndFunction

Function RequestTextByDocumentDetails(AttributeName)
	
	QueryText =  
	"SELECT
	|	ARAPObjects.Ref              AS ARAPObject,
	|	VALUETYPE(ARAPObjects.Object) AS ARAPObjectType,
	|	MirrorObjectsOfCalculations.Ref    AS ARAPObjectMirror,
	|	ARAPObjects.Counterparty          AS MirrorOrganization,
	|	CASE
	|		WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountReceiptNote)
	|				OR VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountIssue)
	|			THEN 
	|				ARAPObjects.IncomingDocumentDate
	|		ELSE 
	|			ARAPObjects.Date
	|	END AS Date,
	|	CASE
	|		WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountReceiptNote)
	|				OR VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountIssue)
	|			THEN 
	|				ARAPObjects.IncomingDocumentNumber
	|		ELSE 
	|			ARAPObjects.Number
	|	END AS Number
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.ARAPObjects AS MirrorObjectsOfCalculations
	|			ON MirrorObjectsOfCalculations.Organization = ARAPObjects.Counterparty
	|				AND MirrorObjectsOfCalculations.Counterparty = ARAPObjects.Organization
	|				AND MirrorObjectsOfCalculations.PaymentType_ = 
	|					CASE WHEN ARAPObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|						THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|						ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					END
	|				AND CASE
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountReceiptNote)
	|						THEN VALUETYPE(MirrorObjectsOfCalculations.Object) = TYPE(Document.BankAccountIssue)
	|							AND MirrorObjectsOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectsOfCalculations.IncomingDocumentDate = ARAPObjects.IncomingDocumentDate
	|							AND MirrorObjectsOfCalculations.IncomingDocumentNumber = ARAPObjects.IncomingDocumentNumber
	|							AND MirrorObjectsOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.BankAccountIssue)
	|						THEN VALUETYPE(MirrorObjectsOfCalculations.Object) = TYPE(Document.BankAccountReceiptNote)
	|							AND MirrorObjectsOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectsOfCalculations.IncomingDocumentDate = ARAPObjects.IncomingDocumentDate
	|							AND MirrorObjectsOfCalculations.IncomingDocumentNumber = ARAPObjects.IncomingDocumentNumber
	|							AND MirrorObjectsOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.CashAccountReceiptNote)
	|						THEN VALUETYPE(MirrorObjectsOfCalculations.Object) = TYPE(Document.CashVoucher)
	|							AND MirrorObjectsOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectsOfCalculations.Date = ARAPObjects.Date
	|							AND MirrorObjectsOfCalculations.Number = ARAPObjects.Number
	|							AND MirrorObjectsOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.CashVoucher)
	|						THEN VALUETYPE(MirrorObjectsOfCalculations.Object) = TYPE(Document.CashAccountReceiptNote)
	|							AND MirrorObjectsOfCalculations.Sum = ARAPObjects.Sum
	|							AND MirrorObjectsOfCalculations.Date = ARAPObjects.Date
	|							AND MirrorObjectsOfCalculations.Number = ARAPObjects.Number
	|							AND MirrorObjectsOfCalculations.Currency = ARAPObjects.Currency
	|					WHEN VALUETYPE(ARAPObjects.Object) = TYPE(Document.SourceDocument)
	|						THEN VALUETYPE(MirrorObjectsOfCalculations.Object) = TYPE(Document.SourceDocument)
	|							AND MirrorObjectsOfCalculations.Sum = ARAPObjects.Sum
	|							AND BEGINOFPERIOD(MirrorObjectsOfCalculations.Date, DAY) = BEGINOFPERIOD(ARAPObjects.Date, DAY)
	|							AND MirrorObjectsOfCalculations.Number = ARAPObjects.Number
	|							AND MirrorObjectsOfCalculations.Currency = ARAPObjects.Currency
	|					ELSE MirrorObjectsOfCalculations.Object = ARAPObjects.Object
	|				END
	|WHERE
	|	ARAPObjects.Ref = &AttributeName";
	
	QueryText = StrReplace(QueryText,"&AttributeName","&" + AttributeName);
	
	Return QueryText;
	
EndFunction

Procedure CheckFillingOfTablePart(TSName, ListName, ArrayOfUnverifiable, Cancel)
	
	Template = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của danh sách ""%3""';
					|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
					|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
					|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
					|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
					|tr = 'Sütun ""%1"" ""%2"" listesinin %3 satırında doldurulmadı'");
	Template = StrReplace(Template,"%3",ListName);
	For Each String In ThisObject[TSName] Do
		For Each Attribute In ThisObject.Metadata().TabularSections[TSName].Attributes Do
			If Attribute.FillChecking = FillChecking.ShowError 
				And ArrayOfUnverifiable.Find(TSName + "." + Attribute.Name) = Undefined Then
				If Not ValueIsFilled(String[Attribute.Name]) Then
					MessageText = StrReplace(Template,"%1",Attribute.Synonym);
					MessageText = StrReplace(MessageText,"%2",String.LineNumber);
					Common.MessageToUser(
						MessageText,
						ThisObject,
						, // Field
						,
						Cancel);
				EndIf;
				ArrayOfUnverifiable.Add(TSName + "." + Attribute.Name);
			EndIf;
		EndDo;// according to the details of the tabular part
	EndDo;// by the rows of the table part
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
