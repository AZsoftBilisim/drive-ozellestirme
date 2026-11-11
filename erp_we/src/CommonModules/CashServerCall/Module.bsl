
#Region Public

// Forms the structure for creating a payment in several applications for expenditure of funds
// If the key details of the header differ in the submitted requests, an error message is displayed.
//
// Parameters:
//    ReferencesArrray   - Array - requests for spending funds for which you need to enter a payment
//    PaymentMethod - String - application payment form
//    PaymentAllocation - Array - line balances the distribution of charge.
//
// Returns:
//    Boolean - False if the details of the header differ in the transferred orders.
//
Function GeneratePaymentFillingData(ReferencesArrray, PaymentMethod, PaymentAllocation) Export
	
	QueryText =
		RequestTextStatusCheck() +
		QueryTextPaymentAllocation();
	
	If ReferencesArrray.Count() > 1 Then
		QueryText = QueryText + RequestTextAbilityToGroupRequests();
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	If PaymentMethod = "BankAccountPayment" Then
		Query.SetParameter("TypeOfPaymentLocation", Type("CatalogRef.CompaniesBankAccounts"));
	ElsIf PaymentMethod = "CashAccountPayment_" Then
		Query.SetParameter("TypeOfPaymentLocation", Type("CatalogRef.CashAccounts"));
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Cancel = False;
	If Not QueryResult[0].IsEmpty() > 0 Then
						
		ComplianceWithAcceptableStatusOfApplications = ComplianceWithAcceptableStatusOfApplications();
		AcceptableDefaultStatuses = ComplianceWithAcceptableStatusOfApplications.Get(Type("EnumRef.StatusesOfPaymentRequests"));
		
		ApplicationSelection = QueryResult[0].Select();
		While ApplicationSelection.Next() Do
			
			AcceptableStatuses = ComplianceWithAcceptableStatusOfApplications.Get(TypeOf(ApplicationSelection.Status));
			AcceptableStatuses = ?(AcceptableStatuses = Undefined,	AcceptableDefaultStatuses, AcceptableStatuses);
			
			TMCommonUse.CheckPossibilityOfEnteringBasedOn(
				ApplicationSelection.Request,
				ApplicationSelection.Status,
				ApplicationSelection.ThereAreErrorsPosted,
				ApplicationSelection.ThereAreErrorsStatus,
				AcceptableStatuses);
		EndDo;
		
	ElsIf ReferencesArrray.Count() > 1 Then
		
		Selection = QueryResult[2].Select();
		Selection.Next();
		If ReportErrorsInGeneratingPaymentFillingData(Selection) Then
			
			ErrorText = NStr("vi = 'Không thể nhập chứng từ thanh toán trên cơ sở các giấy đề nghị đã chọn';
							|ru = 'Ввод одного документа оплаты на основании выделенных заявок невозможен';
							|en = 'Cannot enter one AR/AP transaction based on the selected requests'; fa = 'Cannot enter one AR/AP transaction based on the selected requests';
							|it = 'L''immissione di un documento in base alle disposizioni selezionate è impossibile';
							|pl = 'Wprowadzenie jednego dokumentu płatności na podstawie zaznaczonych zleceń jest nie możliwe';
							|tr = 'Seçili başvurulara göre tek bir ödeme belgesi girilmesi mümkün değildir'");
			CommonClientServer.MessageToUser(ErrorText,,,, Cancel);
		EndIf;
	EndIf;
	
	PaymentAllocation = Common.ValueTableToArray(QueryResult[1].Unload());
	
	Return Not Cancel;
	
EndFunction

Function ComplianceWithAcceptableStatusOfApplications()
	
	MatchingStatusTypes 		= New Map;	
	
	AcceptableDefaultStatuses 	= New Array;
	AcceptableDefaultStatuses.Add(Enums.StatusesOfPaymentRequests.AmountDue);	
	
	AcceptableStatusesOfEmployeeApplications 	= New Array;
	AcceptableStatusesOfEmployeeApplications.Add(Enums.EmployeeApplicationStatuses.AgreedUpon);        
	
	MatchingStatusTypes.Insert(Type("EnumRef.EmployeeApplicationStatuses"),AcceptableStatusesOfEmployeeApplications);
	MatchingStatusTypes.Insert(Type("EnumRef.StatusesOfPaymentRequests"),AcceptableDefaultStatuses);
		
	Return MatchingStatusTypes;
	
EndFunction

// Converts binary file data to text
//
// Parameters:
//    FileAddress - String - Address of temporary storage with file data
//    Encoding - String - "DOS" or "Windows".
//
// Returns:
//    TextDocument - The text of the file.
//
Function TextDocumentFromTemporaryFileStorage(FileAddress, Encoding) Export
	
	If Encoding = "UTF-8" Then
		TempFileName = GetTempFileName("xml");
	ElsIf Encoding = "Windows" Or Encoding = "DOS" Then
		TempFileName = GetTempFileName("txt");
	Else
		TempFileName = GetTempFileName();
	EndIf;
	FileBinaryData = GetFromTempStorage(FileAddress); // BinaryData
	FileBinaryData.Write(TempFileName);
	Text = New TextDocument();
	If Encoding = "DOS" Then
		Kodir = "cp866";
	ElsIf Encoding = "UTF-8" Then
		Kodir = "UTF-8";
	Else
		Kodir = "windows-1251";
	EndIf;
	
	Text.Read(TempFileName, Kodir);
	
	Try
		DeleteFiles(TempFileName);
	Except
		Event = NStr("vi = 'Kết nhập bản sao kê ngân hàng';
					|ru = 'Загрузка банковской выписки';
					|en = 'Importing bank statement'; fa = 'Importing bank statement';
					|it = 'Importazione estratto conto';
					|pl = 'Pobieranie wyciągu bankowego';
					|tr = 'Banka ekstresi içe aktarma'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Xóa tệp tạm thời';
						|ru = 'Удаление временного файла';
						|en = 'Delete temporary file'; fa = 'Delete temporary file';
						|it = 'Cancellazione del file temporaneo';
						|pl = 'Usuwanie pliku tymczasowego';
						|tr = 'Geçici dosyayı silme'", Common.DefaultLanguageCode());
		WriteLogEvent(Event,
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Text;
	
EndFunction

// Receives the bank's SWIFT
// 
// Parameters:
//  Bank - CatalogRef.BankClassifier - link to the bank
// Returns:
//  String - SWIFT bank.
Function SWIFT(Bank) Export
	
	Return Common.ObjectAttributeValue(Bank, "SWIFTBIC")
	
EndFunction

// Returns an indication of the use of the list of accountable persons in the document "Application for the expenditure of DS"
// 
// Parameters:
//  PaymentRequests - Array of DocumentRef.PaymentRequest - list of documents "Application for the expenditure of DS"
// 
// Returns:
//  Boolean
//
Function ListOfIndividualsOnPaymentRequests(PaymentRequests) Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	MAX(PaymentRequest.PersonsList) AS PersonsList
		|FROM
		|	Document.PaymentRequest AS PaymentRequest
		|WHERE
		|	PaymentRequest.Ref IN (&DocumentsList)";
	
	Query.SetParameter("DocumentsList", PaymentRequests);
	QueryResult = Query.Execute().Select();
	QueryResult.Next();
	
	Return ?(ValueIsFilled(QueryResult.PersonsList), QueryResult.PersonsList, False);
	
EndFunction

Function Perform_VerificationOfCreditCoursesInAdvanceReports(Parameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(New UUID);
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "CashServer.Perform_VerificationOfCreditCoursesInAdvanceReports", Parameters);
	
EndFunction

#EndRegion

#Region Private

Function RequestTextStatusCheck()
	
	QueryText = "
	|SELECT
	|	Request.Ref AS Request,
	|	Request.Status AS Status,
	|	NOT Request.Posted AS ThereAreErrorsPosted,
	|	CASE WHEN NOT (Request.Status = VALUE(Enum.StatusesOfPaymentRequests.AmountDue))
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus
	|	
	|FROM
	|	Document.PaymentRequest AS Request
	|WHERE
	|	Request.Ref IN (&ReferencesArrray)
	|	AND (NOT Request.Posted OR
	|		Request.Status <> VALUE(Enum.StatusesOfPaymentRequests.AmountDue))
	|
	|UNION ALL
	|
	|SELECT
	|	Request.Ref AS Request,
	|	Request.Status AS Status,
	|	NOT Request.Posted AS ThereAreErrorsPosted,
	|	CASE WHEN NOT (Request.Status = VALUE(Enum.EmployeeApplicationStatuses.AgreedUpon))
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus
	|	
	|FROM
	|	Document.ApplicationForBusinessTrip AS Request
	|WHERE
	|	Request.Ref IN (&ReferencesArrray)
	|	AND (NOT Request.Posted OR
	|		Request.Status <> VALUE(Enum.EmployeeApplicationStatuses.AgreedUpon))
	|;
	|
	|///////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextAbilityToGroupRequests()
	
	QueryText = "
	|SELECT
	|	CASE WHEN
	|		COUNT(DISTINCT
	|			CASE WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|					OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
	|					OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.PaymentCard)
	|					OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
	|				THEN Request.PaymentMethodOfPaymentRequest
	|			END) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesInFormOfPayment,
	|	MIN(CASE WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|			OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.PaymentCard)
	|			OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
	|		THEN Request.PaymentMethodOfPaymentRequest
	|		END) AS PaymentMethodOfPaymentRequest,
	|	
	|	MIN(CASE WHEN Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InPaymentCurrency)
	|			THEN Request.Currency
	|		WHEN Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency)
	|			THEN
	|				CASE WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|						AND Request.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|					THEN Request.CashAccount.CashCurrency
	|					WHEN (Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
	|							OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments))
	|						AND Request.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN Request.BankAccount.CashCurrency
	|				END
	|		END) AS Currency,
	|	MIN(Request.Currency) AS CurrencyCandidate,
	|	CASE WHEN COUNT(DISTINCT
	|		CASE WHEN Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InPaymentCurrency)
	|			THEN Request.Currency
	|		WHEN Request.AmountPlanning = VALUE(Enum.MethodsOfPlanningRequestPayment.InARAPCurrency)
	|			THEN 
	|				CASE WHEN Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|						AND Request.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|					THEN Request.CashAccount.CashCurrency
	|					WHEN (Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
	|							OR Request.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments))
	|						AND Request.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN Request.BankAccount.CashCurrency
	|				END
	|		END) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesInPaymentCurrency,
	|	
	|	MIN(Request.Organization) AS Organization,
	|	CASE WHEN COUNT(DISTINCT Request.Organization) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesCompany,
	|	
	|	MIN(Request.BusinessOperation) AS BusinessOperation,
	|	CASE WHEN COUNT(DISTINCT Request.BusinessOperation) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesEconomicOperation,
	|	
	|	MIN(Request.PayrollTransaction) AS PayrollTransaction,
	|	CASE WHEN COUNT(DISTINCT Request.PayrollTransaction) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesEconomicOperationOnSalary,
	|	
	|	MIN(Request.Counterparty) AS Counterparty,
	|	CASE WHEN COUNT(DISTINCT Request.Counterparty) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesCounterparty,
	|	
	|	MIN(Request.AdvanceHolder) AS AdvanceHolder,
	|	CASE WHEN COUNT(DISTINCT Request.AdvanceHolder) > 1
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreDifferencesAccountablePerson,
	|	
	|	CASE WHEN COUNT(DISTINCT
	|		CASE WHEN Request.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|			THEN Request.CashAccount
	|		END) > 1
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS ThereAreDifferencesCheckout,
	|	MIN(CASE WHEN Request.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|		THEN Request.CashAccount
	|	END) AS CashAccount,
	|	
	|	CASE WHEN COUNT(DISTINCT
	|		CASE WHEN Request.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|			THEN Request.BankAccount
	|		END) > 1
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS ThereAreDifferencesBankAccount,
	|	MIN(CASE WHEN Request.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|		THEN Request.BankAccount
	|	END) AS BankAccount,
	|	
	|	CASE WHEN COUNT(DISTINCT Request.Department) > 1 THEN
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE MIN(Request.Department)
	|	END AS Department,
	|	
	|	CASE WHEN COUNT(DISTINCT Request.CounterpartyBankAccount) > 1 THEN
	|		VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|		ELSE MIN(Request.CounterpartyBankAccount)
	|	END AS CounterpartyBankAccount,
	|	
	|	CASE WHEN COUNT(DISTINCT Request.CashFlowItem) > 1 THEN
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|		ELSE MIN(Request.CashFlowItem)
	|	END AS CashFlowItem,
	|	
	|	CASE WHEN COUNT(DISTINCT Request.AssetAndLiabilityItem) > 1 THEN
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		ELSE MIN(Request.AssetAndLiabilityItem)
	|	END AS AssetAndLiabilityItem,
	|	
	|	MIN(CASE WHEN Request.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN Request.CashAccountRecipient
	|		ELSE UNDEFINED
	|	END) AS CashAccountRecipient,
	|	MIN(CASE WHEN Request.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN Request.BankAccountBeneficiary
	|		ELSE UNDEFINED
	|	END) AS BankAccountBeneficiary,
	|	
	|	MIN(Request.CurrencyOfConversion) AS CurrencyOfConversion,
	|	MIN(Request.ConversionRate) AS ConversionRate,
	|	
	|	MIN(CASE WHEN Request.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions)
	|		THEN TRUE
	|		ELSE FALSE
	|	END) AS TransferOfTaxesAndContributions,
	|	
	|	MIN(Request.AssetsLiabilitiesDimension) AS AssetsLiabilitiesDimension,
	|	
	|	MIN(Request.Counterparty.Description) AS CounterpartyName_,
	|	MIN(Request.Counterparty.DescriptionFull) AS CounterpartyFullName,
	|	MIN(Request.AdvanceHolder.Description) AS ReportingEntityName,
	|
	|	CASE 
	|		WHEN COUNT(DISTINCT Request.FPSTransactionID) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS MultipleSBPIDs
	|
	|	
	|FROM
	|	Document.PaymentRequest AS Request
	|
	|WHERE
	|	Request.Ref IN (&ReferencesArrray)
	|;
	|
	|//////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextPaymentAllocation()
	
	QueryText = "
	|SELECT
	|	ScheduleOfPayments.BankAccountCashAccount,
	|	ScheduleOfPayments.PaymentDate,
	|	SUM(ScheduleOfPayments.Sum) AS Sum
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|WHERE
	|	ScheduleOfPayments.PaymentObject IN(&ReferencesArrray)
	|	AND ScheduleOfPayments.ReceiptIssue = VALUE(Enum.CashFlowTypes.WriteOff)
	|GROUP BY
	|	ScheduleOfPayments.BankAccountCashAccount,
	|	ScheduleOfPayments.PaymentDate
	|;
	|
	|///////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction

Function ReportErrorsInGeneratingPaymentFillingData(SelectionHeaderDetails)
	
	Cancel = False;
	
	MessageText = NStr("vi = 'Trong giấy đề nghị thanh toán đã chọn có khác biệt tại trường ""%FieldPresentation%""';
						|ru = 'У выделенных заявок на расходование денежных средств отличается поле ""%FieldPresentation%""';
						|en = 'The ""%FieldPresentation%"" field of the selected payment requests is different'; fa = 'The ""%FieldPresentation%"" field of the selected payment requests is different';
						|it = 'Le domande selezionate per i fondi di spesa differiscono nel campo ""%FieldPresentation%""';
						|pl = 'Zaznaczone wnioski o wydatkowanie środków pieniężnych-gotówki mają różniące się pole %FieldPresentation%""';
						|tr = 'Seçilmiş ödeme taleplerinin ""%FieldPresentation%"" alanı farklı'");
	
	If SelectionHeaderDetails.ThereAreDifferencesInFormOfPayment Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hình thức thanh toán';
																|ru = 'Форма оплаты';
																|en = 'Payment method'; fa = 'روش پرداخت';
																|it = 'Modalità di pagamento';
																|pl = 'Forma płatności';
																|tr = 'Ödeme formu'")),,,, Cancel);
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesEconomicOperation Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch kinh tế';
																|ru = 'Хозяйственная операция';
																|en = 'Business transaction'; fa = 'عملیات تجاری';
																|it = 'Operazione economica';
																|pl = 'Operacja gospodarcza';
																|tr = 'Ticari işlem'")),,,, Cancel);
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesEconomicOperationOnSalary Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giao dịch kinh tế theo thanh toán';
																|ru = 'Хозяйственная операция по зарплате';
																|en = 'Payroll transaction'; fa = 'معامله حقوق و دستمزد';
																|it = 'Operazione commerciale salariale';
																|pl = 'Operacja gospodarcze według wynagrodzenia';
																|tr = 'Ücret ve maaşlara ilişkin ticari işlem'")),,,, Cancel);
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInPaymentCurrency Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tiền tệ';
																|ru = 'Валюта';
																|en = 'Currency'; fa = 'ارز';
																|it = 'Valuta';
																|pl = 'Waluta';
																|tr = 'Para birimi'")),,,, Cancel);
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCompany Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Doanh nghiệp';
																|ru = 'Организация';
																|en = 'Company'; fa = 'Company';
																|it = 'Azienda';
																|pl = 'Firma';
																|tr = 'İş yeri'")),,,, Cancel);
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCounterparty Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'")),,,, Cancel);
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesAccountablePerson Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Người nhận tạm ứng';
																|ru = 'Подотчетное лицо';
																|en = 'Advance holder'; fa = 'تنخواه‌دار';
																|it = 'Titolare di anticipo';
																|pl = 'Osoba rozliczająca się za wydatki';
																|tr = 'Sorumlu kişi'")),,,, Cancel);
	EndIf;
		
	If SelectionHeaderDetails.MultipleSBPIDs Then
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'ID giao dịch của hệ thống thanh toán nhanh';
																|ru = 'Идентификатор операции СБП';
																|en = 'FPS transaction ID'; fa = 'شناسه تراکنش FPS';
																|it = 'FPS transaction ID';
																|pl = 'FPS transaction ID';
																|tr = 'SBP işlem kimliği'")),,,, Cancel);
	EndIf;
	
	Return Cancel;
	
EndFunction

Function PayChartLines(GraphLines, DocumentType) Export
	
	Return CashServer.PayChartLines(GraphLines, DocumentType);
	
EndFunction

// Returns the values of the document Attributes or undefined.
// 
// Parameters:
//  Document - DocumentRef - The document that uses the SBP.
//  PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of settlements with a partner.
//  SelectedAttributes - Map of KeyAndValue - The Attributes you need to get.
//  GetSettlementAmounts - Boolean - flag for getting the amount of settlements for the document.
// 
// Returns:
//  See CashServer.DocumentData
//
Function DocumentData(Document, PaymentType_, SelectedAttributes, GetSettlementAmounts = False) Export

	Return CashServer.DocumentData(Document, PaymentType_, SelectedAttributes, GetSettlementAmounts);

EndFunction

#EndRegion

#Region VATTaxation

// Sets whether the settlement object matches the document in the table and fills in the taxation line
//
// Parameters:
// 	Parameters - Structure:
//		* Ref - DocumentRef.PaymentRequest,
//			Document link.Incoming Checkout Order,
//			Document link.Expendable Cash Order,
//			Document link.Write-off of non-cash funds,
//			Document link.Receipt of non-cash funds,
//			Document link.The payment card operation is a link to the execution schedule.
//		* TaxationOfNSDBySilence - EnumRef.VATTaxationTypes - the type of taxation defined for the Cur document;
//		* ARAPObject - CatalogRef.ARAPObjects - The object of calculations.
//
// Returns:
// 	Structure - New row values:
//		* VATRate - CatalogRef.VATRates - VAT rate by taxationnds;
//		* VATTaxation - EnumRef.VATTaxationTypes - Tax type for the line;
//		* TheCalculationObjectMatchesTheDocument - Boolean - Indicates whether the calculation object matches the document.
//
Function FillInDetailsForNDSV(Parameters) Export
	
	Result = New Structure();
	Result.Insert("VATTaxation", Undefined);
	Result.Insert("TheCalculationObjectMatchesTheDocument", False);
	
	If ValueIsFilled(Parameters.Contract) Then
		TaxationUnderContract = Common.ObjectAttributeValue(Parameters.Contract, "VATTaxation");
	EndIf;
	
	If ValueIsFilled(Parameters.ARAPObject)
				And Not Common.ObjectAttributeValue(Parameters.ARAPObject, "Object")= Parameters.Ref Then
				
			Result.VATTaxation = Common.ObjectAttributeValue(Parameters.ARAPObject, "VATTaxation");
			If Not ValueIsFilled(Result.VATTaxation) Then
				Result.VATTaxation = TaxationUnderContract;
			EndIf;
			Result.TheCalculationObjectMatchesTheDocument = False;
			
	Else
			
			Result.VATTaxation = Parameters.TaxationOfNSDBySilence;
			Result.TheCalculationObjectMatchesTheDocument = True;
				
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion