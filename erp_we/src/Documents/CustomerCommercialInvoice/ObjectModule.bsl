#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	PaymentID   = Undefined;
	
	CustomerCommercialInvoiceLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoice") Then
		ServicesForSaleOfGoods(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
		InstructionsForRedemptionOfReturnableContainersByClient(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		InstructionsForRedemptionOfGoodsByCustodian(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoiceServices") Then
		FillInActOfWorkPerformed(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ConsignmentReportToVendor") Then
		FillInReportToCommittee(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
		FillInCommissionAgentSReportOnWriteOff(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.CounterpartyContracts") Then
		FillInTheContract(
			FillingData,
			FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		
		FillInReportToGiver2_5(FillingData, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
		FillInReportToPurchasingCommittee(
			FillingData,
			FillingData);

	EndIf;
	
	InitializeDocument(FillingData);
    AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
    AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	CustomerCommercialInvoiceLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	InterestAmount = 0;
	For Each ScheduleStage In PaymentScheduleSteps Do
		If Not ScheduleStage.ThisIsDepositForPackage Then
			InterestAmount = InterestAmount + ScheduleStage.PaymentPercentage;
		EndIf;
	EndDo;
	
	// The percentage of payment for all stages should be 100%
	If InterestAmount <> 100 Then
		
		ErrorText = NStr("vi = 'Phần trăm thanh toán theo tất cả giai đoạn cần phải bằng 100%';
						|ru = 'Процент платежей по всем этапам должен быть равен 100%';
						|en = 'Payment percentage at all stages should be equal to 100 %'; fa = 'Payment percentage at all stages should be equal to 100 %';
						|it = 'La percentuale di pagamento per tutte le fasi deve essere pari al 100%';
						|pl = 'Procent płatności dla wszystkich etapów powinien wynosić 100%';
						|tr = 'Tüm aşamalar için ödeme yüzdesi 100% olmalıdır'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"PaymentScheduleSteps",
			,
			Cancel);
		
	EndIf;
	
	AmountOfPaymentStages = PaymentScheduleSteps.Total("PaymentAmount");
	If AmountOfPaymentStages > 0 And DocumentAmount <> AmountOfPaymentStages Then
		
		ErrorText = NStr("vi = 'Số tiền trong chứng từ không được khác với số tiền trong các giai đoạn thanh toán';
						|ru = 'Сумма документа не должна отличаться от суммы этапов оплаты';
						|en = 'Document amount should not differ from payment milestones amount'; fa = 'Document amount should not differ from payment milestones amount';
						|it = 'Importo del documento non deve differire dal totale delle fasi di pagamento';
						|pl = 'Wartość dokumentu nie powinna różnić się od sumy etapów płatności.';
						|tr = 'Belge tutarı, ödeme aşamalarındaki tutardan farklı olmamalıdır.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"DocumentAmount",
			,
			Cancel);
		
	EndIf;
	
	If TypeOf(DocumentBasis) <> Type("CatalogRef.CounterpartyContracts") And Not Canceled_ Then
		
		FoundingCurrency = Common.ObjectAttributeValue(DocumentBasis, "Currency");
		
		BaseAmount_ = Documents.CustomerCommercialInvoice.GetAmountOfFoundationDocument(DocumentBasis);
		
		If DocumentAmount > BaseAmount_ Then
			
			ErrorText = NStr("vi = 'Số tiền chứng từ không thể lớn hơn số tiền của chứng từ cơ sở ""%BaseAmount_% %FoundingCurrency%""';
							|ru = 'Сумма документа не может быть больше суммы документа-основания ""%BaseAmount_% %FoundingCurrency%""';
							|en = 'Document amount cannot be greater than the amount of the base document ""%BaseAmount_% %FoundingCurrency%""'; fa = 'Document amount cannot be greater than the amount of the base document ""%BaseAmount_% %FoundingCurrency%""';
							|it = 'Importo del documento non può essere superiore all''importo del documento-causale ""%BaseAmount_% %FoundingCurrency%""';
							|pl = 'Wartość dokumentu nie może być większa niż wartość dokumentu pierwotnego ""%BaseAmount_% %FoundingCurrency%""';
							|tr = 'Belge tutarı, temel belge tutarından fazla olamaz ""%BaseAmount_% %FoundingCurrency%""'");
			ErrorText = StrReplace(ErrorText,"%BaseAmount_%", Format(BaseAmount_, "NFD=2"));
			ErrorText = StrReplace(ErrorText,"%FoundingCurrency%",FoundingCurrency);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"DocumentAmount",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray.Add("PaymentScheduleSteps.PaymentPercentage");
	For Each ScheduleStage In PaymentScheduleSteps Do
		
		If Not ValueIsFilled(ScheduleStage.PaymentPercentage) And Not ScheduleStage.ThisIsDepositForPackage Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Phần trăm thanh toán"" tại dòng %LineNumber% của danh sách ""Giai đoạn lịch biểu thanh toán""';
							|ru = 'Не заполнена колонка ""Процент платежа"" в строке %LineNumber% списка ""Этапы графика оплаты""';
							|en = 'Column ""Payment percentage"" is not populated in line %LineNumber% of the ""Payment milestones"" list'; fa = 'Column ""Payment percentage"" is not populated in line %LineNumber% of the ""Payment milestones"" list';
							|it = 'Colonna ""Percentuale di pagamento"" nella riga %LineNumber% dell''elenco ""Fasi del grafico di pagamento"" non è compilata';
							|pl = 'Nie jest wypełniona kolumna ""Procent płatności"" w wierszu %LineNumber% listy ""Etapy harmonogramu płatności""';
							|tr = '""Ödeme planının aşamaları"" listesinin %LineNumber% satırında ""Ödeme yüzdesi"" sütunu doldurulmadı'");
			ErrorText = StrReplace(ErrorText,"%LineNumber%",ScheduleStage.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("PaymentScheduleSteps", ScheduleStage.LineNumber, "PaymentPercentage"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	CustomerCommercialInvoiceLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	AttributesArray = New Array;
	If ValueIsFilled(PaymentMethod) And PaymentMethod <> Enums.PaymentForms.CashAccountPayment_ Then
		AttributesArray.Add("CashAccount");
	EndIf;
	
	CashServer.ClearUnusedProps(ThisObject, AttributesArray, New Array);
	
	For Each ScheduleStage In PaymentScheduleSteps Do
		If ScheduleStage.ThisIsDepositForPackage And ValueIsFilled(ScheduleStage.PaymentPercentage) Then
			ScheduleStage.PaymentPercentage = 0;
		EndIf;
	EndDo;
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	CustomerCommercialInvoiceLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CustomerCommercialInvoiceLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CustomerCommercialInvoiceLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CustomerCommercialInvoiceLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(FillingData)
	
	If FillingData.Property("Organization") Then
		Organization = FillingData.Organization;
	EndIf;
	
	If FillingData.Property("PaymentMethod") Then
		PaymentMethod = FillingData.PaymentMethod;
	EndIf;
	
	If FillingData.Property("DocumentBasis") Then
		
		DocumentBasis = FillingData.DocumentBasis;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
			ServicesForSaleOfGoods(
				DocumentBasis,
				FillingData);
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor") Then
			FillInReportToCommittee(
				DocumentBasis,
				FillingData);
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
			FillInCommissionAgentSReportOnWriteOff(
				DocumentBasis,
				FillingData);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ServicesForSaleOfGoods(Val Basis, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Date AS PrepaymentDate,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.ContactPerson AS ContactPerson,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.Number AS AgreementNumber_,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementsUnderContract,
	|
	|	NULL AS Status,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.Director AS Director,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	DocumentData.CashAccount AS CashAccount,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted,
	|	FALSE AS ThereAreErrorsStatus,
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreErrorsEconomicOperation
	|
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.SalesOrder = UNDEFINED
	|		OR DocumentData.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|		OR DocumentData.SalesOrder = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	
	|	SUM(DocumentData.PackageDepositValue) AS PaymentAmount,
	|	TRUE AS ThisIsDepositForPackage
	|
	|FROM
	|	Document.CustomerInvoice.PaymentScheduleSteps AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentDate
	|HAVING
	|	SUM(DocumentData.PackageDepositValue) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	
	|	SUM(DocumentData.PaymentPercentage) AS PaymentPercentage,
	|	SUM(DocumentData.PaymentAmount) AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|FROM
	|	Document.CustomerInvoice.PaymentScheduleSteps AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentDate
	|HAVING
	|	SUM(DocumentData.PaymentAmount) > 0
	|
	|ORDER BY
	|	PaymentDate DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CustomersARAPAccounting.AmountDueBalance,0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS CustomersARAPAccounting
	|");
	Query.SetParameter("Ref", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult[0].Select();
	SelectionByStages    = QueryResult[1].Select();
	SampleByCalculation  = QueryResult[2].Select();
	
	If SelectionByDocument.Next() Then
		
		ArrayOfValidStatuses = New Array();
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToSupply);
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToShip);
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.Closed);
		
		Documents.CustomerCommercialInvoice.CheckCorrectnessOfBusinessTransactionOfFoundationDocument(
			SelectionByDocument.ThereAreErrorsEconomicOperation,
			SelectionByDocument.BusinessOperation);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			SelectionByDocument.Status,
			SelectionByDocument.ThereAreErrorsPosted,
			SelectionByDocument.ThereAreErrorsStatus,
			ArrayOfValidStatuses);
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
		
		If SelectionByDocument.SettlementsUnderContract Then
			
			While SelectionByStages.Next() Do
				PaymentStage = PaymentScheduleSteps.Add();
				FillPropertyValues(PaymentStage, SelectionByStages);
			EndDo;
			
		Else
			
			If SampleByCalculation.Next() Then
				
				PayAmount = SampleByCalculation.PayAmount;
				If SelectionByDocument.ARAPCurrency <> SelectionByDocument.Currency Then
					Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
						SelectionByDocument.Currency,
						SelectionByDocument.ARAPCurrency,
						SelectionByDocument.Date,
						SelectionByDocument.Organization);
					PayAmount = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, PayAmount / Coefficients.ConversionRateToSettlementCurrency, 0);
				EndIf;
				
				While PayAmount > 0 And SelectionByStages.Next() Do
					
					PaymentStage = PaymentScheduleSteps.Add();
					FillPropertyValues(PaymentStage, SelectionByStages);
					If PayAmount < SelectionByStages.PaymentAmount Then
						PaymentStage.PaymentAmount = PayAmount;
					EndIf;
					
					PayAmount = PayAmount - SelectionByStages.PaymentAmount;
					
				EndDo;
				
			EndIf;
			
			FillingData.Insert("DocumentAmount",  PaymentScheduleSteps.Total("PaymentAmount"));
			FillingData.Insert("PartialPayment", SelectionByDocument.DocumentAmount <> PaymentScheduleSteps.Total("PaymentAmount"));
			
		EndIf;
		
		PaymentScheduleSteps.Sort("PaymentDate");
		
	EndIf;
	
EndProcedure

Procedure InstructionsForRedemptionOfReturnableContainersByClient(Val Basis, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.ContactPerson AS ContactPerson,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.Number AS AgreementNumber_,
	|	DocumentData.Director AS Director,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementsUnderContract,
	|
	|	NULL AS Status,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccount,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted
	|
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|SELECT
	|	ISNULL(CustomersARAPAccounting.SumBalance,0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS CustomersARAPAccounting
	|");
	Query.SetParameter("Ref", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	BaseAmount_ = 0;
	SelectionByDocument = QueryResult[0].Select();
	SampleByCalculation  = QueryResult[1].Select();
	
	If SelectionByDocument.Next() Then
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			,
			SelectionByDocument.ThereAreErrorsPosted);
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
		
		If SelectionByDocument.SettlementsUnderContract Then
			AddPaymentStage(SelectionByDocument.DocumentAmount, SelectionByDocument.PaymentDate);
			FillingData.Insert("DocumentAmount",  SelectionByDocument.DocumentAmount);
			FillingData.Insert("PartialPayment", False);
		Else
			FillInAmountOfDocumentForSettlementsWithCustomers(SelectionByDocument, SampleByCalculation, FillingData);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInActOfWorkPerformed(Val Basis, FillingData)

	Query = New Query("SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.ContactPerson AS ContactPerson,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.Number AS AgreementNumber_,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	DocumentData.Director AS Director,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	NULL AS Status,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted,
	|	FALSE AS ThereAreErrorsStatus,
	|	FALSE AS ThereAreErrorsEconomicOperation,
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SettlementsUnderContract,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccount
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.SalesOrder = UNDEFINED
	|			OR DocumentData.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|			OR DocumentData.SalesOrder = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|			OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|			OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|			OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.PaymentDate,
	|	SUM(DocumentData.PaymentPercentage),
	|	SUM(DocumentData.PaymentAmount),
	|	FALSE
	|FROM
	|	Document.CustomerInvoiceServices.PaymentScheduleSteps AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentDate
	|
	|HAVING
	|	SUM(DocumentData.PaymentAmount) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS CustomersARAPAccounting");
	Query.SetParameter("Ref", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult[0].Select();
	SelectionByStages    = QueryResult[1].Select();	
	SampleByCalculation  = QueryResult[2].Select();
	
	If SelectionByDocument.Next() Then
		
		ArrayOfValidStatuses = New Array();
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToSupply);
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToShip);
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.Closed);
		
		Documents.CustomerCommercialInvoice.CheckCorrectnessOfBusinessTransactionOfFoundationDocument(
			SelectionByDocument.ThereAreErrorsEconomicOperation,
			SelectionByDocument.BusinessOperation);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			SelectionByDocument.Status,
			SelectionByDocument.ThereAreErrorsPosted,
			SelectionByDocument.ThereAreErrorsStatus,
			ArrayOfValidStatuses);
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
			
			
		If SelectionByDocument.SettlementsUnderContract Then
			
			While SelectionByStages.Next() Do
				PaymentStage = PaymentScheduleSteps.Add();
				FillPropertyValues(PaymentStage, SelectionByStages);
			EndDo;
			
		Else
			
			If SampleByCalculation.Next() Then
				
				PayAmount = SampleByCalculation.PayAmount;
				If SelectionByDocument.ARAPCurrency <> SelectionByDocument.Currency Then
					Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
						SelectionByDocument.Currency,
						SelectionByDocument.ARAPCurrency,
						SelectionByDocument.Date,
						SelectionByDocument.Organization);
					PayAmount = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, PayAmount / Coefficients.ConversionRateToSettlementCurrency, 0);
				EndIf;
				
				While PayAmount > 0 And SelectionByStages.Next() Do
					
					PaymentStage = PaymentScheduleSteps.Add();
					FillPropertyValues(PaymentStage, SelectionByStages);
					If PayAmount < SelectionByStages.PaymentAmount Then
						PaymentStage.PaymentAmount = PayAmount;
					EndIf;
					
					PayAmount = PayAmount - SelectionByStages.PaymentAmount;
					
				EndDo;
				
				PaymentScheduleSteps.Sort("PaymentDate");
				
			EndIf;
			
			FillingData.Insert("DocumentAmount",  PaymentScheduleSteps.Total("PaymentAmount"));
			FillingData.Insert("PartialPayment", SelectionByDocument.DocumentAmount <> PaymentScheduleSteps.Total("PaymentAmount"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInAmountOfDocumentForSettlementsWithCustomers(SelectionByDocument, SampleByCalculation, FillingData)
	
	If SampleByCalculation.Next() And SampleByCalculation.PayAmount > 0 Then
		
		If SelectionByDocument.ARAPCurrency <> SelectionByDocument.Currency Then
			Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
				SelectionByDocument.Currency,
				SelectionByDocument.ARAPCurrency,
				SelectionByDocument.Date,
				SelectionByDocument.Organization);
			PayAmount = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, SampleByCalculation.PayAmount / Coefficients.ConversionRateToSettlementCurrency, 0);
		Else
			PayAmount = SampleByCalculation.PayAmount;
		EndIf;
		
		AddPaymentStage(PayAmount, SelectionByDocument.PaymentDate);
		FillingData.Insert("DocumentAmount",  PayAmount);
		FillingData.Insert("PartialPayment", PayAmount <> SelectionByDocument.DocumentAmount);
		
	Else
		
		FillingData.Insert("DocumentAmount",  0);
		FillingData.Insert("PartialPayment", True);
		
	EndIf;
	
EndProcedure

Procedure FillInReportToCommittee(Val Basis, FillingData)

	Query = New Query(
	"SELECT
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization				AS Organization,
	|	DocumentData.Director            AS Director,
	|	DocumentData.ChiefAccountant        AS ChiefAccountant,
	|	DocumentData.Number					AS Number,
	|	DocumentData.Organization.Prefix		AS Prefix,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.Currency					AS ARAPCurrency,
	|	DocumentData.CommissionAmount		AS DocumentAmount,
	|	DocumentData.Ref					AS DocumentBasis,
	|	DocumentData.Partner					AS Partner,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentData.ContactPerson			AS ContactPerson,
	|	DocumentData.Contract					AS Contract,
	|	DocumentData.PaymentDate				AS PaymentDate,
	|	FALSE									AS PartialPayment,
	|	NOT DocumentData.Posted				AS ThereAreErrorsPosted,
	|	DocumentData.KeepCommissionFee	AS KeepCommissionFee,
	|	DocumentData.BankAccount			AS BankAccount,
	|	DocumentData.PaymentMethod				AS PaymentMethod,
	|	DocumentData.CashAccount					AS CashAccount,
	|
	|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementsUnderContract
	|
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|SELECT
	|	ISNULL(CustomersARAPAccounting.SumBalance,0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object=&Ref) AS CustomersARAPAccounting
	|");
	Query.SetParameter("Ref", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult[0].Select();
	SampleByCalculation  = QueryResult[1].Select();
	
	If SelectionByDocument.Next() Then
		
		If SelectionByDocument.KeepCommissionFee Then
				
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần nhập hóa đơn thanh toán trên cơ sở chứng từ %1, vì trong đó đã giữ lại khoản hoa hồng';
					|ru = 'Не требуется вводить счет на оплату на основании документа %1, поскольку в нем удержано вознаграждение';
					|en = 'It is not required to enter commercial invoice based on document %1 as remuneration is deducted in it'; fa = 'It is not required to enter commercial invoice based on document %1 as remuneration is deducted in it';
					|it = 'Non è necessario inserire la fattura di pagamento in base al documento %1, perché nel documento è trattenuto il compenso';
					|pl = 'Nie trzeba wprowadzać rachunku do zapłaty na podstawie dokumentu %1, ponieważ w nim jest potrącono wynagrodzenie';
					|tr = '%1 belgesine dayalı olarak ticari fatura girmek gerekli değildir, çünkü bu belgeden ücret düşüldü.'"),
				Basis);
			
			Raise Text;
			
		EndIf;
		
		If SelectionByDocument.DocumentAmount <= 0 Then
				
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không bắt buộc phải nhập hóa đơn để thanh toán trên cơ sở chứng từ %1, vì không có số tiền thù lao hoặc nó là âm';
					|ru = 'Не требуется вводить счет на оплату на основании документа %1, поскольку отсутствует сумма вознаграждения или она отрицательная';
					|en = 'It is not required to enter a commercial invoice based on document %1 as commission amount is missing or it is negative'; fa = 'It is not required to enter a commercial invoice based on document %1 as commission amount is missing or it is negative';
					|it = 'Non è necessario inserire la fattura di pagamento in base al documento %1, perché manca l''importo del compenso oppure è negativo';
					|pl = 'Nie jest wymagane wprowadzanie faktury do zapłaty na podstawie dokumentu %1, ponieważ nie ma wartości wynagrodzenia lub jest ona ujemną';
					|tr = 'Ücret tutarı eksik veya negatif olduğu için %1 belgesine dayalı olarak ticari fatura girilmesine gerek yoktur'"),
				Basis);
			
			Raise Text;
			
		EndIf;
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			Undefined, // Status
			SelectionByDocument.ThereAreErrorsPosted,
			False); // ThereAreErrorsStatus
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
		
	EndIf;
	
	If SelectionByDocument.SettlementsUnderContract Then
		
		AddPaymentStage(SelectionByDocument.DocumentAmount, SelectionByDocument.PaymentDate);
		
		If SelectionByDocument.DocumentAmount > 0 Then
			FillingData.Insert("DocumentAmount",  SelectionByDocument.DocumentAmount);
			FillingData.Insert("PartialPayment", False);
		Else
			FillingData.Insert("DocumentAmount",  0);
			FillingData.Insert("PartialPayment", True);
		EndIf;
		
	Else
		FillInAmountOfDocumentForSettlementsWithCustomers(SelectionByDocument, SampleByCalculation, FillingData);
	EndIf;
	
EndProcedure

Procedure FillInCommissionAgentSReportOnWriteOff(Val Basis, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Date                AS Date,
	|	DocumentData.Organization         AS Organization,
	|	DocumentData.Number               AS Number,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Currency              AS Currency,
	|	DocumentData.Currency              AS ARAPCurrency,
	|	DocumentData.DocumentAmount      AS DocumentAmount,
	|	DocumentData.Partner             AS Partner,
	|	DocumentData.Counterparty          AS Counterparty,
	|	DocumentData.Contract             AS Contract,
	|	DocumentData.PaymentDate         AS PaymentDate,
	|	DocumentData.Ref              AS DocumentBasis,
	|	FALSE                                AS PartialPayment,
	|	NOT DocumentData.Posted         AS ThereAreErrorsPosted,
	|
	|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementsUnderContract
	|
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|SELECT
	|	ISNULL(CustomersARAPAccounting.SumBalance,0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object=&Ref) AS CustomersARAPAccounting
	|");
	Query.SetParameter("Ref", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult[0].Select();
	SampleByCalculation  = QueryResult[1].Select();
	
	If SelectionByDocument.Next() Then
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			Undefined, // Status
			SelectionByDocument.ThereAreErrorsPosted,
			False); // ThereAreErrorsStatus
		
		Organization = SelectionByDocument.Organization;
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number, 
			Basis,
			SelectionByDocument.Date);
		
	EndIf;
	
	If SelectionByDocument.SettlementsUnderContract Then
		AddPaymentStage(SelectionByDocument.DocumentAmount, SelectionByDocument.PaymentDate);
		FillingData.Insert("DocumentAmount",  SelectionByDocument.DocumentAmount);
		FillingData.Insert("PartialPayment", False);
	Else
		FillInAmountOfDocumentForSettlementsWithCustomers(SelectionByDocument, SampleByCalculation, FillingData);
	EndIf;
		
EndProcedure

Procedure FillInTheContract(Val Basis, FillingData)

	Query = New Query(
	"SELECT
	|	DocumentData.Ref               AS Contract,
	|	DocumentData.Organization          AS Organization,
	|	DocumentData.Number                AS Number,
	|	DocumentData.Date                 AS Date,
	|	UNDEFINED                         AS Prefix,
	|	DocumentData.ARAPCurrency AS Currency,
	|	0                                    AS DocumentAmount,
	|	DocumentData.Ref               AS DocumentBasis,
	|	DocumentData.Partner              AS Partner,
	|	DocumentData.Counterparty           AS Counterparty,
	|	&CurrentDate                         AS PaymentDate,
	|	TRUE                               AS PartialPayment,
	|	DocumentData.Status               AS Status,
	|	DocumentData.ContactPerson       AS ContactPerson,
	|	DocumentData.BankAccount       AS BankAccount,
	|
	|	CASE WHEN DocumentData.Status = VALUE(Enum.CounterpartyContractStatuses.NotApproved) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                AS ThereAreErrorsStatus,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                AS ThereAreContractTypeErrors
	|
	|FROM
	|	Catalog.CounterpartyContracts AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", Basis);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult.Select();
	
	If SelectionByDocument.Next() Then
		
		CheckPossibilityOfEnteringOnBasisOfContract(SelectionByDocument.ThereAreContractTypeErrors);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			SelectionByDocument.Status,
			, // ThereAreErrorsPosted
			SelectionByDocument.ThereAreErrorsStatus);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
		
	EndIf;
	
EndProcedure


Procedure FillInReportToGiver2_5(Val Basis, FillingData)

	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Date                      AS Date,
	|	DocumentData.Partner                   AS Partner,
	|	DocumentData.Counterparty                AS Counterparty,
	|	DocumentData.ContactPerson            AS ContactPerson,
	|	DocumentData.Contract                   AS Contract,
	|	DocumentData.Organization               AS Organization,
	|	DocumentData.Number                     AS Number,
	|	DocumentData.Organization.Prefix       AS Prefix,
	|	DocumentData.PaymentMethod               AS PaymentMethod,
	|	DocumentData.Currency                    AS Currency,
	|	DocumentData.ARAPCurrency      AS ARAPCurrency,
	|	DocumentData.DocumentAmount            AS DocumentAmount,
	|	DocumentData.Ref                    AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.TollManufacturing2_5) AS BusinessOperation,
	|	NULL                                      AS Status,
	|	NOT DocumentData.Posted               AS ThereAreErrorsPosted,
	|	FALSE                                      AS ThereAreErrorsStatus,
	|	FALSE                                      AS ThereAreErrorsEconomicOperation,
	|
	|	DocumentData.ARAPObjectSettings =
	|				VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)       AS SettlementsUnderContract,
	|
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CashAccount                     AS CashAccount
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|	   OR DocumentData.ARAPObjectSettings IN (
	|								VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts),
	|								VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CustomersARAPAccounting.SumBalance,0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS CustomersARAPAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref                AS DocumentBasis,
	|	DocumentData.PaymentDate           AS PaymentDate,
	|	SUM(DocumentData.PaymentPercentage) AS PaymentPercentage,
	|	SUM(DocumentData.PaymentAmount)   AS PaymentAmount,
	|	FALSE                                  AS ThisIsDepositForPackage
	|FROM
	|	Document.ReportToMaterialProvider2_5.PaymentScheduleSteps AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentDate
	|
	|HAVING
	|	SUM(DocumentData.PaymentAmount) > 0
	|";
	
	Query.SetParameter("Ref", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult[0].Select();
	SampleByCalculation  = QueryResult[1].Select();
	SelectionByStages    = QueryResult[2].Select();
	
	If SelectionByDocument.Next() Then
		
		ArrayOfValidStatuses = New Array();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			SelectionByDocument.Status,
			SelectionByDocument.ThereAreErrorsPosted,
			SelectionByDocument.ThereAreErrorsStatus,
			ArrayOfValidStatuses);
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
								SelectionByDocument.Number, Basis, SelectionByDocument.Date);
		
		If SelectionByDocument.SettlementsUnderContract Then
			
			While SelectionByStages.Next() Do
				PaymentStage = PaymentScheduleSteps.Add();
				FillPropertyValues(PaymentStage, SelectionByStages);
			EndDo;
			
		Else
			
			If SampleByCalculation.Next() Then
				
				PayAmount = SampleByCalculation.PayAmount;
				If SelectionByDocument.ARAPCurrency <> SelectionByDocument.Currency Then
					
					Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
						SelectionByDocument.Currency, SelectionByDocument.ARAPCurrency, SelectionByDocument.Date, SelectionByDocument.Organization);
					
					PayAmount = ?(Coefficients.ConversionRateToSettlementCurrency <> 0,
									PayAmount / Coefficients.ConversionRateToSettlementCurrency,
									0);
					
				EndIf;
				
				While PayAmount > 0 And SelectionByStages.Next() Do
					
					PaymentStage = PaymentScheduleSteps.Add();
					FillPropertyValues(PaymentStage, SelectionByStages);
					
					If PayAmount < SelectionByStages.PaymentAmount Then
						PaymentStage.PaymentAmount = PayAmount;
					EndIf;
					
					PayAmount = PayAmount - SelectionByStages.PaymentAmount;
					
				EndDo;
				
				PaymentScheduleSteps.Sort("PaymentDate");
				
			EndIf;
			
			FillingData.Insert("DocumentAmount",  PaymentScheduleSteps.Total("PaymentAmount"));
			FillingData.Insert(
				"PartialPayment",
				SelectionByDocument.DocumentAmount <> PaymentScheduleSteps.Total("PaymentAmount"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Organization    = SettingsValueCached.GetDefaultOrganization(Organization);
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
			And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "DocumentBasis") Then
		BasisOfFillingData = FillingData.DocumentBasis;
	ElsIf Common.IsReference(TypeOf(FillingData)) Then
		BasisOfFillingData = FillingData;
	Else
		BasisOfFillingData = Undefined;
	EndIf;
	ResponsiblePersonsServer.InstallManager(ThisObject, BasisOfFillingData);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization    	= Organization;
	ParametersStructure.PaymentMethod		= PaymentMethod;
	ParametersStructure.CashAccount			= CashAccount;
	CashAccount          = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("PartialPayment")
		And FillingData.PartialPayment Then
		CalculatePaymentPercentages();
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure InstructionsForRedemptionOfGoodsByCustodian(Val Basis, FillingData)
	
	Query = New Query;
	Query.SetParameter("Ref", Basis);
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.ContactPerson AS ContactPerson,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.Number AS AgreementNumber_,
	|	DocumentData.Director AS Director,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SettlementsUnderContract,
	|	NULL AS Status,
	|	DocumentData.CompanyBankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccount,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS CustomersARAPAccounting";
	
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	BaseAmount_ = 0;
	SelectionByDocument = QueryResult[0].Select();
	SampleByCalculation = QueryResult[1].Select();
	
	If SelectionByDocument.Next() Then
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			,
			SelectionByDocument.ThereAreErrorsPosted);
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
		
		If SelectionByDocument.SettlementsUnderContract Then
			AddPaymentStage(SelectionByDocument.DocumentAmount, SelectionByDocument.PaymentDate);
			FillingData.Insert("DocumentAmount",  SelectionByDocument.DocumentAmount);
			FillingData.Insert("PartialPayment", False);
		Else
			FillInAmountOfDocumentForSettlementsWithCustomers(SelectionByDocument, SampleByCalculation, FillingData);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInReportToPurchasingCommittee(Val Basis, FillingData)

	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Date AS PrepaymentDate,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.ContactPerson AS ContactPerson,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.Number AS AgreementNumber_,
	|	VALUE(Enum.BusinessTransactions.DeliveryForPrincipal) AS BusinessOperation,
	|
	|	CASE WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementsUnderContract,
	|
	|	NULL AS Status,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.Director AS Director,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	DocumentData.CashAccount AS CashAccount,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted,
	|	FALSE AS ThereAreErrorsStatus,
	|	FALSE AS ThereAreErrorsEconomicOperation
	|
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (&OptionOfAssignment = VALUE(Enum.OptionsOfGoodsAssignmentInSales.Contract)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|		OR DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|	)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	
	|	SUM(DocumentData.PaymentPercentage) AS PaymentPercentage,
	|	SUM(DocumentData.PaymentAmount) AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.PaymentScheduleSteps AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentDate
	|HAVING
	|	SUM(DocumentData.PaymentAmount) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.ARAPObject AS ARAPObject
	|INTO TTCalculationObjects_
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(ISNULL(CustomersARAPAccounting.SumBalance, 0)) AS PayAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|			,
	|			ARAPObject IN
	|				(SELECT
	|					TTCalculationObjects_.ARAPObject
	|				FROM
	|					TTCalculationObjects_)) AS CustomersARAPAccounting");

	Query.SetParameter("Ref", Basis);
	Query.SetParameter("OptionOfAssignment", Constants.OptionOfGoodsAssignmentInSales.Get());
	QueryResult = Query.ExecuteBatch();
	
	FillingData = New Structure;
	For Each Column In QueryResult[0].Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	SelectionByDocument = QueryResult[0].Select();
	SelectionByStages    = QueryResult[1].Select();
	SampleByCalculation  = QueryResult[3].Select();
	
	If SelectionByDocument.Next() Then
		
		If SelectionByDocument.DocumentAmount <= 0 Then
				
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không bắt buộc phải nhập hóa đơn để thanh toán trên cơ sở chứng từ %1, vì không có số tiền thù lao hoặc nó là âm';
					|ru = 'Не требуется вводить счет на оплату на основании документа %1, поскольку отсутствует сумма вознаграждения или она отрицательная';
					|en = 'It is not required to enter a commercial invoice based on document %1 as commission amount is missing or it is negative'; fa = 'It is not required to enter a commercial invoice based on document %1 as commission amount is missing or it is negative';
					|it = 'Non è necessario inserire la fattura di pagamento in base al documento %1, perché manca l''importo del compenso oppure è negativo';
					|pl = 'Nie jest wymagane wprowadzanie faktury do zapłaty na podstawie dokumentu %1, ponieważ nie ma wartości wynagrodzenia lub jest ona ujemną';
					|tr = 'Ücret tutarı eksik veya negatif olduğu için %1 belgesine dayalı olarak ticari fatura girilmesine gerek yoktur'"),
				Basis);
			
			Raise Text;
			
		EndIf;
		
		Documents.CustomerCommercialInvoice.CheckCorrectnessOfBusinessTransactionOfFoundationDocument(
			SelectionByDocument.ThereAreErrorsEconomicOperation,
			SelectionByDocument.BusinessOperation);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			SelectionByDocument.DocumentBasis,
			SelectionByDocument.Status,
			SelectionByDocument.ThereAreErrorsPosted,
			SelectionByDocument.ThereAreErrorsStatus);
		
		FillPropertyValues(FillingData, SelectionByDocument);
		
		Organization = SelectionByDocument.Organization;
		BankAccount = SelectionByDocument.BankAccount;
		PaymentMethod = SelectionByDocument.PaymentMethod;
		CashAccount = SelectionByDocument.CashAccount;
		
		PaymentPurposes = Documents.CustomerCommercialInvoice.GeneratePaymentPurpose(
			SelectionByDocument.Number,
			Basis,
			SelectionByDocument.Date);
		
		If SelectionByDocument.SettlementsUnderContract Then
			
			While SelectionByStages.Next() Do
				PaymentStage = PaymentScheduleSteps.Add();
				FillPropertyValues(PaymentStage, SelectionByStages);
			EndDo;
			
		Else
			
			If SampleByCalculation.Next() Then
				
				PayAmount = SampleByCalculation.PayAmount;
				If SelectionByDocument.ARAPCurrency <> SelectionByDocument.Currency Then
					Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
						SelectionByDocument.Currency,
						SelectionByDocument.ARAPCurrency,
						SelectionByDocument.Date,
						SelectionByDocument.Organization);
					PayAmount = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, PayAmount / Coefficients.ConversionRateToSettlementCurrency, 0);
				EndIf;
				
				While PayAmount > 0 And SelectionByStages.Next() Do
					
					PaymentStage = PaymentScheduleSteps.Add();
					FillPropertyValues(PaymentStage, SelectionByStages);
					If PayAmount < SelectionByStages.PaymentAmount Then
						PaymentStage.PaymentAmount = PayAmount;
					EndIf;
					
					PayAmount = PayAmount - SelectionByStages.PaymentAmount;
					
				EndDo;
				
				PaymentScheduleSteps.Sort("PaymentDate");
				
			EndIf;
			
			FillingData.Insert("DocumentAmount",  PaymentScheduleSteps.Total("PaymentAmount"));
			FillingData.Insert("PartialPayment", SelectionByDocument.DocumentAmount <> PaymentScheduleSteps.Total("PaymentAmount"));
			
		EndIf;
		
		AmountByPayments            = PaymentScheduleSteps.Total("PaymentAmount");
			InterestAmount             = 100;
			Multiplier                  = ?(AmountByPayments<0,-1,1);
			
			Cnt = 0;
			While Cnt < PaymentScheduleSteps.Count() Do
				
				If AmountByPayments * Multiplier > 0 Then
					PaymentScheduleSteps[Cnt].PaymentPercentage = ?(Cnt = PaymentScheduleSteps.Count()-1,
																		InterestAmount,
																		PaymentScheduleSteps[Cnt].PaymentAmount / AmountByPayments * 100);
					
					InterestAmount = InterestAmount - PaymentScheduleSteps[Cnt].PaymentPercentage*Multiplier;
				EndIf;
				
				Cnt = Cnt + 1;
			EndDo;
		
	Else
		FillInAmountOfDocumentForSettlementsWithCustomers(SelectionByDocument, SampleByCalculation, FillingData);
	EndIf;
	
EndProcedure


#EndRegion

#Region Other

Procedure AddPaymentStage(PayAmount, PaymentDate)
	
	PaymentStage = PaymentScheduleSteps.Add();
	PaymentStage.PaymentPercentage = 100;
	PaymentStage.PaymentAmount   = PayAmount;
	PaymentStage.PaymentDate    = ?(ValueIsFilled(PaymentDate), PaymentDate, CurrentSessionDate());
	
EndProcedure

Procedure CheckPossibilityOfEnteringOnBasisOfContract(ThereAreContractTypeErrors)
	
	If ThereAreContractTypeErrors Then
		
		ErrorText = NStr("vi = 'Cấm nhập trên cơ sở hợp đồng với nhà cung cấp.';
						|ru = 'Ввод на основании договора с поставщиком запрещен.';
						|en = 'Generation from contracts with vendors is not allowed.'; fa = 'Generation from contracts with vendors is not allowed.';
						|it = 'Inserimento in base all''accordo con il fornitore è vietato.';
						|pl = 'Wprowadzenie na podstawie umowy z dostawcą jest zabronione.';
						|tr = 'Sağlayıcı ile yapılan bir sözleşmeye dayalı girişler yasaktır.'");
	
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Procedure CalculatePaymentPercentages()
	PaymentLines_ = PaymentScheduleSteps.FindRows(New Structure("ThisIsDepositForPackage", False));
	SalesAmounts = PaymentScheduleSteps.Unload(PaymentLines_, "PaymentAmount").UnloadColumn("PaymentAmount");
	InterestPayments = TMCommonUseClientServer.DistributeProportionally(100, SalesAmounts);
	If InterestPayments <> Undefined Then
		CounterOfTable = 0;
		ArrayCounter = 0;
		While ArrayCounter < InterestPayments.Count() Do
			While PaymentScheduleSteps[CounterOfTable].ThisIsDepositForPackage 
				And CounterOfTable < PaymentScheduleSteps.Count() Do
				CounterOfTable = CounterOfTable + 1;
			EndDo;
			If CounterOfTable < PaymentScheduleSteps.Count()
				And Not PaymentScheduleSteps[CounterOfTable].ThisIsDepositForPackage Then
				PaymentScheduleSteps[CounterOfTable].PaymentPercentage = InterestPayments[ArrayCounter];
			EndIf;
			CounterOfTable = CounterOfTable + 1;
			ArrayCounter = ArrayCounter + 1;
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#EndRegion

#EndIf
