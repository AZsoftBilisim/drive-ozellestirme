#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves the cash flow item for the selected business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
// 	CatalogRef.CashFlowReportItems - The found DDS article.
//
Function CashFlowItemForBusinessTransaction(BusinessOperation) Export
	
	Query = New Query("SELECT TOP 2
		|	CashFlowReportItems.Ref AS CashFlowItem
		|FROM
		|	Catalog.CashFlowReportItems.BusinessTransactions AS CashFlowReportItemsBusinessTransactions
		|		INNER JOIN Catalog.CashFlowReportItems AS CashFlowReportItems
		|		ON CashFlowReportItemsBusinessTransactions.Ref = CashFlowReportItems.Ref
		|			AND (NOT CashFlowReportItems.DeletionMark)
		|			AND (CashFlowReportItemsBusinessTransactions.BusinessOperation = &BusinessOperation)");
	
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		CashFlowItem = Selection.CashFlowItem;
	Else
		CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
	EndIf;
	
	Return CashFlowItem;

EndFunction

// Receives all items of RegisteredRecords of funds for the selected business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
// 	Array of CatalogRef.CashFlowReportItems
//
Function ArticlesOfBusinessOfOperation(BusinessOperation) Export
	
	Query = New Query("
	|SELECT
	|	CashFlowReportItems.Ref AS CashFlowItem
	|FROM
	|	Catalog.CashFlowReportItems.BusinessTransactions AS CashFlowReportItemsBusinessTransactions
	|
	|INNER JOIN
	|	Catalog.CashFlowReportItems AS CashFlowReportItems
	|ON
	|	  CashFlowReportItemsBusinessTransactions.Ref = CashFlowReportItems.Ref
	|	AND NOT CashFlowReportItems.DeletionMark
	|	AND (CashFlowReportItemsBusinessTransactions.BusinessOperation = &BusinessOperation)");
	
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	Return Query.Execute().Unload().UnloadColumn("CashFlowItem");
	
EndFunction

// Gets a predefined cash flow item for the selected business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//	Currency - CatalogRef.Currencies - the currency of the document.
//
// Returns:
// 	CatalogRef.CashFlowReportItems - A predefined DDS article.
//
Function PredefinedCFItem(BusinessOperation, Currency = Undefined) Export
	
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank
		Or BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
		If Not ValueIsFilled(Currency)
		 Or Currency = SettingsValueCached.DefaultBaseCurrency() Then
			CashFlowItem = Catalogs.CashFlowReportItems.CashReceiptFromBank;
		Else
			CashFlowItem = Catalogs.CashFlowReportItems.CashReceiptFromBankInForeignCurrency;
		EndIf;
			
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount Then
		If Not ValueIsFilled(Currency)
		 Or Currency = SettingsValueCached.DefaultBaseCurrency() Then
			CashFlowItem = Catalogs.CashFlowReportItems.CashDepositToBankAccount;
		Else
			CashFlowItem = Catalogs.CashFlowReportItems.CashDepositToBankAccountInForeignCurrency;
		EndIf;
		
	Else
		Map = New Map;
		Map.Insert(Enums.BusinessTransactions.CashIssueToAnotherCashAccount, 
			Catalogs.CashFlowReportItems.CashIssueToAnotherCashAccount);
			
		Map.Insert(Enums.BusinessTransactions.CashPaymentToAnotherCompany, 
			Catalogs.CashFlowReportItems.CashPaymentToAnotherCompany);
			
		Map.Insert(Enums.BusinessTransactions.CashIssueToCashRegister,
			Catalogs.CashFlowReportItems.CashIssueToAnotherCashAccount);	

		Map.Insert(Enums.BusinessTransactions.TransferCashToAnotherAccount,
			Catalogs.CashFlowReportItems.TransferCashToAnotherAccount);

		Map.Insert(Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount,
			Catalogs.CashFlowReportItems.CashIssueToAnotherCashAccount);
			
		Map.Insert(Enums.BusinessTransactions.CashReceiptFromOtherCompany,
			Catalogs.CashFlowReportItems.CashPaymentToAnotherCompany);
			
		Map.Insert(Enums.BusinessTransactions.CashReceiptFromCashRegister,
			Catalogs.CashFlowReportItems.CashIssueToAnotherCashAccount);

		Map.Insert(Enums.BusinessTransactions.CashIssueToCashRegister,
			Catalogs.CashFlowReportItems.CashIssueToCashRegister);
			
		Map.Insert(Enums.BusinessTransactions.CashReceiptFromCashRegister,
			Catalogs.CashFlowReportItems.CashReceiptFromCashRegister);
			
		Map.Insert(Enums.BusinessTransactions.SalaryPayment,
			Catalogs.CashFlowReportItems.PayrollPayment);
			
		Map.Insert(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram,
			Catalogs.CashFlowReportItems.PayrollPayment);
			
		Map.Insert(Enums.BusinessTransactions.SalaryPaymentToBankAccounts,
			Catalogs.CashFlowReportItems.PayrollPayment);
			
		Map.Insert(Enums.BusinessTransactions.SalaryPaymentViaCashAccount,
			Catalogs.CashFlowReportItems.PayrollPayment);
			
		Map.Insert(Enums.BusinessTransactions.SalaryPaymentByDistributor,
			Catalogs.CashFlowReportItems.PayrollPayment);
			
		Map.Insert(Enums.BusinessTransactions.SalaryPaymentToEmployee,
			Catalogs.CashFlowReportItems.PayrollPayment);
			
		Map.Insert(Enums.BusinessTransactions.ExchangeDifferencesForCashExchangeGain,
			Catalogs.CashFlowReportItems.ExchangeRateDifferencesProfit_);
			
		Map.Insert(Enums.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss,
			Catalogs.CashFlowReportItems.ExchangeDifferencesLoss);
		
		CashFlowItem = Map.Get(BusinessOperation);
	EndIf; 
	
	If CashFlowItem = Undefined Then
		CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
	EndIf;
	
	Return CashFlowItem;
	
EndFunction

// Gets a list of business operations that correspond to the expenditure of funds.
//
// Returns:
// 	Array - Array of business operations.
//
Function EconomicOperationsOfCashFlow() Export
	
	Query = New Query(
	"SELECT
	|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|WHERE
	|	BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash)
	|	AND BusinessTransactionsSettings.Receipt <> VALUE(Enum.AccountingDataTypes.EmptyRef)
	|	AND BusinessTransactionsSettings.BusinessOperation NOT IN (
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentToEmployee),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentViaCashAccount),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentByDistributor),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.BusinessTransactions.SalaryPayment)"); 
	
	Return Query.Execute().Unload().UnloadColumn("BusinessOperation");
	
EndFunction

// Checks the legality of applying the DDS article for a business transaction
//
// Parameters:
//    CashFlowItem - CatalogRef.CashFlowReportItems - DDS article
//    BusinessOperation - EnumRef.BusinessTransactions - economic operation
//
// Returns:
//    Boolean - Indication of compliance with the operation article
Function ArticleCorrespondsToEconomicOperation(CashFlowItem, BusinessOperation) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	1
	|FROM
	|	Catalog.CashFlowReportItems.BusinessTransactions AS BusinessTransactions
	|WHERE
	|	BusinessTransactions.BusinessOperation = &BusinessOperation
	|	AND BusinessTransactions.Ref = &CashFlowItem
	|";
	
	Query.SetParameter("CashFlowItem", CashFlowItem);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - name of the table part of the object
//                               Value-Uploading an empty table part to the table of values
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region InvestmentActivity
	Item = Items.Add();
	Item.PredefinedDataName = "InvestmentActivity";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hoạt động đầu tư';
																					|ru = 'Инвестиционная деятельность';
																					|en = 'Investment activity';
																					|it = 'Attività di investimento';
																					|pl = 'Działalność inwestycyjna';
																					|tr = 'Yatırım faaliyeti'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region OperatingActivity
	Item = Items.Add();
	Item.PredefinedDataName = "OperatingActivity";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hoạt động điều hành';
																					|ru = 'Операционная деятельность';
																					|en = 'Operating activity';
																					|it = 'Attività operativa';
																					|pl = 'Działalność operacyjna';
																					|tr = 'İşlevsel faaliyet'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region FinancialActivities
	Item = Items.Add();
	Item.PredefinedDataName = "FinancialActivities";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hoạt động tài chính';
																					|ru = 'Финансовая деятельность';
																					|en = 'Financial activities';
																					|it = 'Attività finanziaria';
																					|pl = 'Działalność finansowa';
																					|tr = 'Finansal faaliyet'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region RefundFromAnotherCompany
	Item = Items.Add();
	Item.PredefinedDataName = "RefundFromAnotherCompany";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả lại tiền từ doanh nghiệp khác';
																					|ru = 'Возврат денежных средств от другой организации';
																					|en = 'Refund from another company';
																					|it = 'Restituzione di denaro da un''altra azienda';
																					|pl = 'Zwrot środków pieniężnych od innej organizacji';
																					|tr = 'Diğer iş yerinden para iadesi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region RefundFromVendor
	Item = Items.Add();
	Item.PredefinedDataName = "RefundFromVendor";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả lại thanh toán từ nhà cung cấp (hàng hóa, công việc, dịch vụ)';
																					|ru = 'Возврат оплаты поставщиком (товары, работы, услуги)';
																					|en = 'Payment return from vendor (goods, works, services)';
																					|it = 'Restituzione del pagamento da parte di un fornitore (merci, lavori, servizi)';
																					|pl = 'Zwrot opłaty dostawcom (towary, roboty, usługi)';
																					|tr = 'Tedarikçiden ödeme iadesi (ürünler, işler, hizmetler)'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region RefundToCustomer
	Item = Items.Add();
	Item.PredefinedDataName = "RefundToCustomer";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả lại thanh toán cho khách hàng (bán hàng hóa, công việc, dịch vụ)';
																					|ru = 'Возврат оплаты клиенту (продажа товаров, работ, услуг)';
																					|en = 'Refund to customer (sale of goods, works, services)';
																					|it = 'Restituzione del pagamento a un cliente (vendita di merci, lavori, servizi)';
																					|pl = 'Zwrot opłaty klientowi (sprzedaż towarów, robót, usług)';
																					|tr = 'Müşteriye ödeme iadesi (ürün, iş, hizmet satışı)'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashIssueToAnotherCashAccount
	Item = Items.Add();
	Item.PredefinedDataName = "CashIssueToAnotherCashAccount";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chuyển sang quỹ tiền mặt khác';
																					|ru = 'Выдача денежных средств в другую кассу';
																					|en = 'Cash issue to another cash account';
																					|it = 'Emissione del contante in un altro conto di cassa';
																					|pl = 'Wydawanie środków pieniężnych do innej kasy';
																					|tr = 'Nakdi diğer kasaya aktarma'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashIssueToCashRegister
	Item = Items.Add();
	Item.PredefinedDataName = "CashIssueToCashRegister";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi tiền vào quầy thu ngân';
																					|ru = 'Выдача денежных средств в кассу ККМ';
																					|en = 'Cash payment to cash register';
																					|it = 'Trasferimento di denaro in cassa KKM';
																					|pl = 'Wydanie środków pieniężnych do kasy KF';
																					|tr = 'Yazar kasa hesabından nakit çıkış'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region PayrollPayment
	Item = Items.Add();
	Item.PredefinedDataName = "PayrollPayment";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả tiền lương theo bảng kê';
																					|ru = 'Выплата заработной платы по ведомостям';
																					|en = 'Payroll payment by paysheets';
																					|it = 'Pagamento dello stipendio in base alle buste paga';
																					|pl = 'Wypłata wynagrodzenia wg rejestru';
																					|tr = 'Beyana göre bordro ödemesi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region ExchangeRateDifferencesProfit_
	Item = Items.Add();
	Item.PredefinedDataName = "ExchangeRateDifferencesProfit_";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi từ chênh lệch tỷ giá';
																					|ru = 'Прибыль от курсовых разниц';
																					|en = 'Exchange gain';
																					|it = 'Ricavo dalle differenze dei tassi di cambio';
																					|pl = 'Dochody od różnic kursowych';
																					|tr = 'Kur farklarından gelen kâr'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region ExchangeDifferencesLoss
	Item = Items.Add();
	Item.PredefinedDataName = "ExchangeDifferencesLoss";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lỗ từ chênh lệch tỷ giá';
																					|ru = 'Убыток от курсовых разниц';
																					|en = 'Exchange loss';
																					|it = 'Perdita dalle differenze dei tassi di cambio';
																					|pl = 'Strata na różnicach kursowych';
																					|tr = 'Kur farkından zarar'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashPaymentToAnotherCompany
	Item = Items.Add();
	Item.PredefinedDataName = "CashPaymentToAnotherCompany";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả tiền cho doanh nghiệp khác';
																					|ru = 'Оплата денежных средств в другую организацию';
																					|en = 'Cash payment to another company';
																					|it = 'Pagamento di denaro ad un''altra azienda';
																					|pl = 'Opłata środków pieniężnych do innej organizacji';
																					|tr = 'Diğer iş yerine para ödemesi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region PaymentToVendor
	Item = Items.Add();
	Item.PredefinedDataName = "PaymentToVendor";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả tiền cho nhà cung cấp (hàng hóa, công việc, dịch vụ)';
																					|ru = 'Оплата поставщику (товары, работы, услуги)';
																					|en = 'Payment to vendor (goods, works, services)';
																					|it = 'Pagamento al fornitore (merci, lavori, servizi)';
																					|pl = 'Opłata dostawcy (towary, roboty, usługi)';
																					|tr = 'Tedarikçiye ödeme (ürünler, işler, hizmetler)'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region TransferCashToAnotherAccount
	Item = Items.Add();
	Item.PredefinedDataName = "TransferCashToAnotherAccount";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chuyển sang tài khoản khác';
																					|ru = 'Перечисление денежных средств на другой счет';
																					|en = 'Cash transfer to another account';
																					|it = 'Versamento contanti in un altro conto';
																					|pl = 'Przelew środków pieniężnych na inne konto';
																					|tr = 'Nakdin diğer hesaba transferi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashReceiptFromBank
	Item = Items.Add();
	Item.PredefinedDataName = "CashReceiptFromBank";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhận tiền từ tài khoản ngân hàng';
																					|ru = 'Поступление денежных средств из банка';
																					|en = 'Cash receipt from bank';
																					|it = 'Versamento contanti dalla banca';
																					|pl = 'Wpływ środków pieniężnych z banku';
																					|tr = 'Bankadan nakit girişi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashReceiptFromBankInForeignCurrency
	Item = Items.Add();
	Item.PredefinedDataName = "CashReceiptFromBankInForeignCurrency";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhận tiền từ ngân hàng (ngoại tệ)';
																					|ru = 'Поступление денежных средств из банка (в иностранной валюте)';
																					|en = 'Cash receipt from bank (in foreign currency)';
																					|it = 'Ricezione di denaro dalla banca (in valuta estera)';
																					|pl = 'Wpłata środków pieniężnych z banku (w walucie obcej)';
																					|tr = 'Bankadan nakit girişi (yabancı para biriminde)'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashReceiptFromCashRegister
	Item = Items.Add();
	Item.PredefinedDataName = "CashReceiptFromCashRegister";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhận tiền từ quầy thu ngân';
																					|ru = 'Поступление денежных средств из кассы ККМ';
																					|en = 'Cash receipt from cash register';
																					|it = 'Ricezione di denaro dalla cassa KKM';
																					|pl = 'Wpłata środków pieniężnych z kasy KF';
																					|tr = 'Yazar kasadan nakit girişi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashReceiptFromAnotherCompany
	Item = Items.Add();
	Item.PredefinedDataName = "CashReceiptFromAnotherCompany";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhận tiền từ doanh nghiệp khác';
																					|ru = 'Поступление денежных средств от другой организации';
																					|en = 'Payment from another company';
																					|it = 'Ricezione di denaro da un''altra azienda';
																					|pl = 'Wpłata środków pieniężnych od innej organizacji';
																					|tr = 'Diğer iş yerinden para girişi'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashReceiptFromCustomer
	Item = Items.Add();
	Item.PredefinedDataName = "CashReceiptFromCustomer";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhận tiền từ khách hàng (bán hàng hóa, công việc, dịch vụ)';
																					|ru = 'Поступление оплаты от клиента (продажа товаров, работ, услуг)';
																					|en = 'Payment from client (sale of goods, works, services)';
																					|it = 'Ricezione di pagamento da un cliente (vendita di merci, lavori, servizi)';
																					|pl = 'Wpływ opłaty od klienta (sprzedaż towarów, robót, usług)';
																					|tr = 'Müşteriden ödeme girişi (ürün, iş, hizmet satışı)'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashDepositToBankAccount
	Item = Items.Add();
	Item.PredefinedDataName = "CashDepositToBankAccount";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nộp tiền vào tài khoản ngân hàng';
																					|ru = 'Сдача денежных средств в банк';
																					|en = 'Cash delivery to bank';
																					|it = 'Consegna del contante in banca';
																					|pl = 'Przekazanie środków pieniężnych do banku';
																					|tr = 'Bankaya teslimat'", LanguagesCodes); // @NStr-2
	#EndRegion

	#Region CashDepositToBankAccountInForeignCurrency
	Item = Items.Add();
	Item.PredefinedDataName = "CashDepositToBankAccountInForeignCurrency";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nộp tiền vào tài khoản ngân hàng (ngoại tệ)';
																					|ru = 'Сдача денежных средств в банк (в иностранной валюте)';
																					|en = 'Cash delivery to bank (in foreign currency)';
																					|it = 'Versamento di denaro in banca (in valuta estera)';
																					|pl = 'Przekazanie środków pieniężnych do banku (w walucie obcej)';
																					|tr = 'Bankaya teslimat (yabancı para biriminde)'", LanguagesCodes); // @NStr-2
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.CashFlowReportItems - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("CashFlowOnly") Then
		
		StandardProcessing = False;
		
		Query = New Query(
		"SELECT
		|	BusinessTransactionsSettings.BusinessOperation AS Ref
		|INTO EconomicOperationsOfExpenditure 
		|FROM
		|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|WHERE
		|	BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash)
		|	AND BusinessTransactionsSettings.Receipt <> VALUE(Enum.AccountingDataTypes.EmptyRef)
		|	
		|INDEX BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////
		|SELECT
		|	CashFlowItems_BusinessTransactions.Ref
		|FROM
		|	Catalog.CashFlowReportItems.BusinessTransactions AS CashFlowItems_BusinessTransactions
		|	INNER JOIN
		|		EconomicOperationsOfExpenditure AS EconomicOperationsOfExpenditure
		|	ON
		|		CashFlowItems_BusinessTransactions.BusinessOperation = EconomicOperationsOfExpenditure.Ref");
		
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	ElsIf Parameters.Property("Filter") And Parameters.Filter.Property("BusinessOperation") Then
		
		StandardProcessing = False;
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	CatalogData.Ref
		|FROM
		|	Catalog.CashFlowReportItems.BusinessTransactions AS CatalogData
		|WHERE
		|	CatalogData.BusinessOperation IN (&BusinessOperation)
		|	AND (CatalogData.Ref.Description LIKE &SearchString
		|		OR CatalogData.Ref.DescriptionLanguage1 LIKE &SearchString
		|		OR CatalogData.Ref.DescriptionLanguage2 LIKE &SearchString
		|		OR CatalogData.Ref.Code LIKE &SearchString
		|		OR &SearchStringOmitted)
		|";
		
		Query.SetParameter("BusinessOperation", Parameters.Filter.BusinessOperation);
		
		SearchString = "";
		If Parameters.Property("SearchString") Then
			SearchString = Parameters.SearchString;
		EndIf;
		
		Query.SetParameter("SearchString", "%" + SearchString + "%");
		Query.SetParameter("SearchStringOmitted", Not ValueIsFilled(SearchString));
		
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	EndIf;
EndProcedure

#EndIf

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" Then
		If Parameters.Property("Filter")
			And Parameters.Filter.Property("BusinessOperation")
			And TypeOf(Parameters.Filter.BusinessOperation) = Type("EnumRef.BusinessTransactions") Then
			SelectedForm = "FormOfSelectionByBusinessTransaction";
			StandardProcessing = False;
		EndIf;
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

Procedure FillInPredefinedCashFlowItems(CFItem = Undefined) Export
	
	Map = New Map;
	If CFItem = Catalogs.CashFlowReportItems.CashIssueToAnotherCashAccount Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashIssueToAnotherCashAccount,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashIssueToAnotherCashAccount,
				"50.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.PaymentToVendor Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.PaymentToVendor,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.PaymentToVendor,
				"60.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.TransferCashToAnotherAccount Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.TransferCashToAnotherAccount,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.TransferCashToAnotherAccount,
				"51",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashReceiptFromBank Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashReceiptFromBank,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashReceiptFromBank,
				"51",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashReceiptFromBankInForeignCurrency Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashReceiptFromBankInForeignCurrency,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashReceiptFromBank,
				"52",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashReceiptFromCustomer Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashReceiptFromCustomer,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashReceiptFromCustomer,
				"62.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashDepositToBankAccount Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashDepositToBankAccount,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashDepositToBankAccount,
				"51",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashDepositToBankAccountInForeignCurrency Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashDepositToBankAccountInForeignCurrency,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashDepositToBankAccount,
				"52",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashPaymentToAnotherCompany Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashPaymentToAnotherCompany,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashPaymentToAnotherCompany,
				"60.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashIssueToCashRegister Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashIssueToCashRegister,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashIssueToCashRegister,
				"50.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashReceiptFromCashRegister Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashReceiptFromCashRegister,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashReceiptFromCashRegister,
				"50.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.PayrollPayment Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.PayrollPayment,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.SalaryPayment,
				"70",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.RefundFromVendor Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.RefundFromVendor,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.RefundFromVendor,
				"60.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.RefundToCustomer Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.RefundToCustomer,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.RefundToCustomer,
				"62.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.ExchangeRateDifferencesProfit_ Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.ExchangeRateDifferencesProfit_,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.ExchangeDifferencesForCashExchangeGain,
				"91.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.ExchangeDifferencesLoss Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.ExchangeDifferencesLoss,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss,
				"91.02",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.CashReceiptFromAnotherCompany Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.CashReceiptFromAnotherCompany,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.CashReceiptFromOtherCompany,
				"62.01",));
	EndIf;
	If CFItem = Catalogs.CashFlowReportItems.RefundFromAnotherCompany Or Not ValueIsFilled(CFItem) Then
		Map.Insert(Catalogs.CashFlowReportItems.RefundFromAnotherCompany ,
			New Structure("BusinessOperation, OffsettingAccount",
				Enums.BusinessTransactions.RefundFromAnotherCompany,
				"60.01",));
	EndIf;
	
	For Each Item In Map Do
	
		ArticleDDSObject = Item.Key.GetObject();
		Item.Value.Insert("Parent", OperatingActivity);
		FillPropertyValues(ArticleDDSObject, Item.Value);
		If ArticleDDSObject.BusinessTransactions.Find(Item.Value.BusinessOperation) = Undefined Then
			ArticleDDSObject.BusinessTransactions.Add().BusinessOperation = Item.Value.BusinessOperation;
		EndIf;
		Try
			InfobaseUpdate.WriteData(ArticleDDSObject);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Danh mục%1 không được ghi lại, xảy ra lỗi trong khi ghi!';
					|ru = 'Справочник %1 не записан, произошли ошибки при записи!';
					|en = 'The %1 catalog was not saved. Errors occurred during saving.'; fa = 'The %1 catalog was not saved. Errors occurred during saving.';
					|it = 'L''elenco %1 non è registrato, si sono verificati errori durante la registrazione!';
					|pl = 'Katalog %1 nie został zapisany, podczas zapisywania zaistniały błędy!';
					|tr = 'Katalog %1 kaydedilmemiş, kayıt sırasında hata oluştu!'", CommonClientServer.DefaultLanguageCode()),
				ArticleDDSObject);
			ErrorDescription = ErrorInfo();
			WriteLogEvent(MessageText, EventLogLevel.Error,,, ErrorDescription.Description);
		EndTry;
	EndDo;
	
	Try
		
		Object = OperatingActivity.GetObject();
		Object.AddlOrderingAttribute = 1;
		InfobaseUpdate.WriteData(Object);
		
		Object = InvestmentActivity.GetObject();
		Object.AddlOrderingAttribute = 2;
		InfobaseUpdate.WriteData(Object);
		
		Object = FinancialActivities.GetObject();
		Object.AddlOrderingAttribute = 3;
		InfobaseUpdate.WriteData(Object);
		
	Except
		
		MessageText = StrTemplate(
			NStr("vi = 'Danh mục%1 không được ghi lại, xảy ra lỗi trong khi ghi!';
				|ru = 'Справочник %1 не записан, произошли ошибки при записи!';
				|en = 'The %1 catalog was not saved. Errors occurred during saving.'; fa = 'The %1 catalog was not saved. Errors occurred during saving.';
				|it = 'L''elenco %1 non è registrato, si sono verificati errori durante la registrazione!';
				|pl = 'Katalog %1 nie został zapisany, podczas zapisywania zaistniały błędy!';
				|tr = 'Katalog %1 kaydedilmemiş, kayıt sırasında hata oluştu!'", CommonClientServer.DefaultLanguageCode()),
			Object);
		ErrorDescription = ErrorInfo();
		WriteLogEvent(MessageText, EventLogLevel.Error,,, ErrorDescription.Description);
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf


