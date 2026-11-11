#Region Public

// Values of details for filling in the balance entry document.
// 
// Returns:
// 	Structure - A structure containing the names of the Attributes of the Balance entry document and the values of their filling:
//       * Comment                                - String - The comment that will be set by the document being created
//       * DocumentDate                             - Date - The date that will be set for the document to be created
//       * RecordInMA                                - Boolean - A sign of reflection in management accounting
//       * PostInFinancialAndTaxAccounting - Boolean        - A sign of reflection in regulated and tax accounting
//       * RecordInOperationalAccounting - Boolean - The sign of reflection in operational accounting
//       * Organization                                 - CatalogRef.Companies - the organization for which Balances are entered
//       * BusinessOperation            - EnumRef.BusinessTransactions - the economic operation of entering Balances.
//
Function InitializeDocumentFillValuesEnteringBalances() Export

	Return OBEntryServer.InitializeDocumentFillValuesEnteringBalances();

EndFunction

#EndRegion

#Region Private

// Returns a representation of the balance entry document.
// 
// Parameters:
// 	Document - DocumentRef.OBEntry - Link to the document for entering balances.
// 	DocumentNumber - String - Number of the balance entry document.
// 	DocumentDate - Date - Date of the balance entry document.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business operation of the balance entry document.
// Returns:
// 	String - String representation of the document for entering balances.
//
Function DocumentTitleEnteringBalancesForBusinessTransaction(Document, DocumentNumber, DocumentDate, BusinessOperation) Export
	
	If Not ValueIsFilled(BusinessOperation) Then
		Return "";
	EndIf;
	
	TitleTemplate1 = "%1";
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCashInRetailCashRegister
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tiền mặt %1';
								|ru = 'Ввод начальных остатков в кассах %1';
								|en = 'OB entry: cash in retail POS terminals %1'; fa = 'OB entry: cash in retail POS terminals %1';
								|it = 'Inserimento dei saldi iniziali in cassa %1';
								|pl = 'Wprowadzenie sald początkowych w kasach %1';
								|tr = '%1 kasalarda açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu công nợ phải thu khách hàng %1';
								|ru = 'Ввод начальных остатков задолженности клиентов %1';
								|en = 'OB entry: customer receivables %1'; fa = 'OB entry: customer receivables %1';
								|it = 'Inserimento dei saldi iniziali del debito dei clienti %1';
								|pl = 'Wprowadzenie sald początkowych zadłużenia klientów %1';
								|tr = '%1 müşteri alacakları/borçları açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu công nợ phải trả nhà cung cấp %1';
								|ru = 'Ввод начальных остатков задолженности перед поставщиками %1';
								|en = 'OB entry: vendor payables %1'; fa = 'OB entry: vendor payables %1';
								|it = 'Inserimento dei saldi iniziali del debito con i fornitori %1';
								|pl = 'Wprowadzenie sald początkowych zadłużenia wobec dostawców %1';
								|tr = '%1 tedarikçi borçlarının açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryAdvanceHolderReceivables Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu công nợ với người nhận tạm ứng %1';
								|ru = 'Ввод начальных остатков задолженности подотчетных лиц %1';
								|en = 'OB entry: advance holder receivables %1'; fa = 'OB entry: advance holder receivables %1';
								|it = 'Inserimento dei saldi iniziali del debito dei titolari di anticipo %1';
								|pl = 'Wprowadzenie sald początkowych zadłużenia osób odpowiedzialnych %1';
								|tr = '%1 sorumlu kişilerin borçlarının açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerBonuses Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu thưởng cho khách hàng %1';
								|ru = 'Ввод начальных остатков премий клиентам %1';
								|en = 'OB entry: customer bonuses %1'; fa = 'OB entry: customer bonuses %1';
								|it = 'Ввод начальных остатков премий клиентам %1';
								|pl = 'OB entry: customer bonuses %1';
								|tr = 'Müşteri primlerinin başlangıç bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryVendorBonuses Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu thưởng của nhà cung cấp %1';
								|ru = 'Ввод начальных остатков премий поставщиков %1';
								|en = 'OB entry: vendor bonuses %1'; fa = 'OB entry: vendor bonuses %1';
								|it = 'Ввод начальных остатков премий поставщиков %1';
								|pl = 'OB entry: vendor bonuses %1';
								|tr = '%1 tedarikçi başlangıç prim bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu chi quá tiền tạm ứng %1';
								|ru = 'Ввод начальных остатков перерасходов подотчетных средств %1';
								|en = 'OB entry: advance holder overspendings %1'; fa = 'OB entry: advance holder overspendings %1';
								|it = 'Inserimento dei saldi iniziali degli eccessi di spesa di fondi responsabili %1';
								|pl = 'Wprowadzenie sald początkowych nadmiernych rozchodów środków podlegających rozliczeniu %1';
								|tr = '%1 sorumlu kişilerin fazla harcamalarının açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tiền gửi %1';
								|ru = 'Ввод начальных остатков на банковских счетах %1';
								|en = 'Enter opening balance of accounts %1'; fa = 'Enter opening balance of accounts %1';
								|it = 'Inserimento dei saldi iniziali sui conti bancari %1';
								|pl = 'Wprowadzenie sald początkowych na rachunków bankowych %1';
								|tr = '%1 banka hesaplarına açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu ứng trước của khách hàng %1';
								|ru = 'Ввод начальных остатков авансов, полученных от клиентов %1';
								|en = 'OB entry: unmatched prepayments from customers %1'; fa = 'OB entry: unmatched prepayments from customers %1';
								|it = 'Inserimento dei saldi iniziali dei pagamenti anticipati ricevuti dai clienti %1';
								|pl = 'Wprowadzenie sald początkowych zaliczek, otrzymanych od klientów %1';
								|tr = '%1 müşterilerden alınan avansların açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu ứng trước cho nhà cung cấp %1';
								|ru = 'Ввод начальных остатков авансов, выданных поставщикам %1';
								|en = 'OB entry: unmatched prepayments to vendors %1'; fa = 'OB entry: unmatched prepayments to vendors %1';
								|it = 'Inserimento dei saldi iniziali dei pagamenti anticipati emessi ai fornitori %1';
								|pl = 'Wprowadzenie sald początkowych zaliczek, wydanych dostawcom %1';
								|tr = '%1 tedarikçilere verilen avansların açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedIntercompanyPrepayment Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu hạch toán trả trước giữa các doanh nghiệp %1';
								|ru = 'Ввод начальных остатков расчетов между организациями по авансам %1';
								|en = 'OB entry: intercompany AR/AP by advances %1'; fa = 'OB entry: intercompany AR/AP by advances %1';
								|it = 'Inserimento dei saldi iniziale dei calcoli tra aziende per anticipi %1';
								|pl = 'Wprowadzenie sald początkowych rozliczeń między firmami wg zaliczek %1';
								|tr = '%1 avans iş yerleri arasında ödeme açılış bakiyelerinin girilmesi '");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedIntercompanyInvoice Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu hạch toán bán hàng giữa các doanh nghiệp %1';
								|ru = 'Ввод начальных остатков расчетов между организациями по реализациям %1';
								|en = 'OB entry: intercompany AR/AP by sales %1'; fa = 'OB entry: intercompany AR/AP by sales %1';
								|it = 'Inserimento dei saldi iniziale dei calcoli tra aziende per vendite %1';
								|pl = 'Wprowadzenie sald początkowych rozliczeń między firmami wg sprzedaży %1';
								|tr = '%1 satış yapan iş yerleri arasında ödeme açılış bakiyelerinin girilmesi '");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư của hàng hóa đặt riêng %1';
								|ru = 'Ввод остатков собственных товаров %1';
								|en = 'OB entry: cost of owned inventory in our warehouse %1'; fa = 'OB entry: cost of owned inventory in our warehouse %1';
								|it = 'Ввод остатков собственных товаров %1';
								|pl = 'OB entry: cost of owned inventory in our warehouse %1';
								|tr = '%1 yerel ürünlerinin bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư hàng hóa đã tiếp nhận ký gửi %1';
								|ru = 'Ввод остатков товаров, принятых на комиссию %1';
								|en = 'Enter remaining goods received for consignment %1'; fa = 'Enter remaining goods received for consignment %1';
								|it = 'Ввод остатков товаров, принятых на комиссию %1';
								|pl = 'Enter remaining goods received for consignment %1';
								|tr = 'Konsinye stok üzerine kabul edilen ürün bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư hàng hóa đã tiếp nhận để bảo quản riêng %1';
								|ru = 'Ввод остатков товаров, принятых на ответственное хранение %1';
								|en = 'Enter remaining available VMI %1'; fa = 'Enter remaining available VMI %1';
								|it = 'Ввод остатков товаров, принятых на ответственное хранение %1';
								|pl = 'Enter remaining available VMI %1';
								|tr = 'Satıcı tarafından yönetilen stok (VMI) bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư hàng hóa đã chuyển giao để bảo quản riêng %1';
								|ru = 'Ввод остатков товаров, переданных на ответственное хранение %1';
								|en = 'Enter remaining VMI %1'; fa = 'Enter remaining VMI %1';
								|it = 'Ввод остатков товаров, переданных на ответственное хранение %1';
								|pl = 'Enter remaining VMI %1';
								|tr = 'Satıcı tarafından yönetilen stok üzerine transfer edilen ürünlerin bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
		Postfix = ConsignmentSalesServer.PostfixCommissionSchemes20();
		TitleTemplate1 = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhập số dư hàng hóa đã chuyển giao đi ký gửi (%1) %2';
				|ru = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
				|en = 'OB entry: consignment sales stock (%1)%2'; fa = 'OB entry: consignment sales stock (%1)%2';
				|it = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
				|pl = 'OB entry: consignment sales stock (%1)%2';
				|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi (%1) %2'"),
			Postfix,
			"%1");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5 Then
		If Not GetFunctionalOption("ConsignmentSaleIsUsed20")
			Or GetFunctionalOption("OnlyConsignmentSales25") Then
			TitleTemplate1 = NStr("vi = 'Nhập số dư hàng hóa đã chuyển giao đi ký gửi %1';
									|ru = 'Ввод остатков товаров, переданных на комиссию %1';
									|en = 'Enter remaining consignment stock %1'; fa = 'Enter remaining consignment stock %1';
									|it = 'Ввод остатков товаров, переданных на комиссию %1';
									|pl = 'Enter remaining consignment stock %1';
									|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi %1'");
		Else
			Postfix = ConsignmentSalesServer.PostfixCommissionSchemes25();
			TitleTemplate1 = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhập số dư hàng hóa đã chuyển giao đi ký gửi (%1) %2';
					|ru = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
					|en = 'OB entry: consignment sales stock (%1)%2'; fa = 'OB entry: consignment sales stock (%1)%2';
					|it = 'Ввод остатков товаров, переданных на комиссию (%1) %2';
					|pl = 'OB entry: consignment sales stock (%1)%2';
					|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi (%1) %2'"),
				Postfix,
				"%1");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư hàng hóa đã giao cho khách %1';
								|ru = 'Ввод остатков товаров, отгруженных клиентам %1';
								|en = 'OB entry: goods shipped to customers %1'; fa = 'OB entry: goods shipped to customers %1';
								|it = 'OB entry: goods shipped to customers %1';
								|pl = 'OB entry: goods shipped to customers %1';
								|tr = '%1  müşterilerine sevk edilen ürünlerin stok miktarlarının girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư của bao bì luân chuyển được chuyển cho khách hàng %1';
								|ru = 'Ввод остатков возвратной тары, переданной клиентам %1';
								|en = 'OB entry: cost of returnable packaging sent to customers %1'; fa = 'OB entry: cost of returnable packaging sent to customers %1';
								|it = 'OB entry: cost of returnable packaging sent to customers %1';
								|pl = 'OB entry: cost of returnable packaging sent to customers %1';
								|tr = 'Müşterilere transfer edilen iade edilebilir ambalajların bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư của bao bì luân chuyển tiếp nhận từ các nhà cung cấp %1';
								|ru = 'Ввод остатков возвратной тары, принятой от поставщиков %1';
								|en = 'OB entry: cost of returnable packaging received from vendors %1'; fa = 'OB entry: cost of returnable packaging received from vendors %1';
								|it = 'OB entry: cost of returnable packaging received from vendors %1';
								|pl = 'OB entry: cost of returnable packaging received from vendors %1';
								|tr = 'Tedarikçilerden alınan iade edilebilir ambalajların bakiyelerinin girilmesi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư khi chuyển sang sử dụng lưu trữ địa chỉ số dư %1';
								|ru = 'Ввод остатков при переходе на использование адресного хранения остатков %1';
								|en = 'OB entry: bin location system of owned inventory %1'; fa = 'OB entry: bin location system of owned inventory %1';
								|it = 'OB entry: bin location system of owned inventory %1';
								|pl = 'OB entry: bin location system of owned inventory %1';
								|tr = 'Artıkların adreslenebilir depolanmasını kullanmaya devam ederken artıkların girilmesi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư khi chuyển sang sử dụng nhà kho %1';
								|ru = 'Ввод остатков при переходе на использование складских помещений %1';
								|en = 'OB entry: wareroom address of owned inventory %1'; fa = 'OB entry: wareroom address of owned inventory %1';
								|it = 'OB entry: wareroom address of owned inventory %1';
								|pl = 'OB entry: wareroom address of owned inventory %1';
								|tr = 'Depoları kullanmaya geçişte kalıntıların girilmesi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		TitleTemplate1 = NStr("vi = 'Nhập nguyên vật liệu còn lại chuyển sang sản xuất %1';
								|ru = 'Ввод остатков материалов, переданных в производство %1';
								|en = 'Enter remaining materials transferred to production %1'; fa = 'Enter remaining materials transferred to production %1';
								|it = 'Enter remaining materials transferred to production %1';
								|pl = 'Enter remaining materials transferred to production %1';
								|tr = 'Üretime aktarılan malzeme bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư tiền mặt phải thu từ thiết bị thanh toán thẻ %1';
								|ru = 'Ввод остатков денежных средств к поступлению от эквайера %1';
								|en = 'OB entry: cash balance to receive from acquirer %1'; fa = 'OB entry: cash balance to receive from acquirer %1';
								|it = 'Immissione di saldi di cassa in arrivo dall''acquirente %1';
								|pl = 'Wprowadzenie sald środków pieniężnych do wpływu od centrum autoryzacyjnego %1';
								|tr = 'Alıcı bankadan tahsil edilecek nakit bakiyelerinin girilmesi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOtherAssetsAndLiabilities Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu tài sản và nguồn vốn khác %1';
								|ru = 'Ввод начальных остатков прочих активов и пассивов %1';
								|en = 'OB entry: other assets and liabilities %1'; fa = 'OB entry: other assets and liabilities %1';
								|it = 'Inserimento dei saldi iniziale di altri attivi e passivi %1';
								|pl = 'Wprowadzenie sald początkowych innych aktywów i pasywów %1';
								|tr = '%1 diğer varlık ve yükümlülük açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOpenGiftCards Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu phiếu quà tặng %1';
								|ru = 'Ввод начальных остатков подарочных сертификатов %1';
								|en = 'OB entry: balance of gift cards %1'; fa = 'OB entry: balance of gift cards %1';
								|it = 'Inserimento dei saldi iniziali dei buoni regalo %1';
								|pl = 'Wprowadzenie sald początkowych certyfikatów podarunkowych %1';
								|tr = '%1 hediye kartı açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu hạch toán các khoản tín dụng, tiền gửi (deposit) và vay nợ khác %1';
								|ru = 'Ввод начальных остатков расчетов по кредитам, депозитам и выданным займам %1';
								|en = 'OB entry: debt outstanding of loans and borrowings %1'; fa = 'OB entry: debt outstanding of loans and borrowings %1';
								|it = 'Inserimento dei saldi iniziali per crediti, depositi e prestiti emessi %1';
								|pl = 'Wprowadzenie sald początkowych rozlibczeń z tytułu kredytów, depozytów i wydanych pożyczek %1';
								|tr = '%1 krediler, mevduatlar ve verilen borçlar üzerindeki hesapların açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryInventoryInOperation Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu vật tư đang sử dụng %1';
								|ru = 'Ввод начальных остатков ТМЦ в эксплуатации %1';
								|en = 'OB entry: inventory in operation %1'; fa = 'OB entry: inventory in operation %1';
								|it = 'Inserimento saldi iniziale Beni Materiali nell''operazione %1';
								|pl = 'Wprowadzenie sald początkowych zapasy w eksploatacji %1';
								|tr = '%1 kullanımdaki stok açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOfOtherExpenses Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư đầu các chi phí khác %1';
								|ru = 'Ввод начальных остатков прочих расходов %1';
								|en = 'OB entry: other expenses%1'; fa = 'OB entry: other expenses%1';
								|it = 'Inserimento dei saldi iniziali di altre spese %1';
								|pl = 'Wprowadzenie sald początkowych innych rozchodów%1';
								|tr = '%1 diğer giderlerin açılış bakiyelerinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods Then
		TitleTemplate1 = NStr("vi = 'Kết quả kinh doanh trong các kỳ trước %1';
								|ru = 'Финансовый результат за прошлые периоды %1';
								|en = 'OB entry: statistics of other P&L items in past periods %1'; fa = 'OB entry: statistics of other P&L items in past periods %1';
								|it = 'Risultati finanziari dei periodi passati%1';
								|pl = 'Rezultat finansowy za poprzednie okresy %1';
								|tr = '%1 geçmiş dönemlere ait kârlılık ve maliyet'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		TitleTemplate1 = NStr("vi = 'Doanh số bán buôn trong các kỳ trước %1';
								|ru = 'Оптовые продажи за прошлые периоды %1';
								|en = 'Wholesale sales in past periods %1'; fa = 'Wholesale sales in past periods %1';
								|it = 'Vendite all''ingrosso per i periodi precedenti %1';
								|pl = 'Operacji sprzedaży hurtowej za poprzednie okresy %1';
								|tr = '%1 geçmiş dönemlere ait toptan satışlar'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		TitleTemplate1 = NStr("vi = 'Doanh số bán lẻ trong các kỳ trước %1';
								|ru = 'Розничные продажи за прошлые периоды %1';
								|en = 'Retail sales in past periods %1'; fa = 'Retail sales in past periods %1';
								|it = 'Vendite al dettaglio per i periodi precedenti %1';
								|pl = 'Operacji sprzedaży detalicznej za poprzednie okresy %1';
								|tr = '%1 geçmiş dönemlere ait perakende satışlar'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryVATOnAcquiredAssets Then
		TitleTemplate1 = NStr("vi = 'Thuế GTGT đầu vào của hàng hóa, công việc và dịch vụ %1';
								|ru = 'Входящий НДС по товарам, работам и услугам %1';
								|en = 'Input VAT by goods, works and services %1'; fa = 'Input VAT by goods, works and services %1';
								|it = 'IVA a monte per articoli, lavori e servizi %1';
								|pl = 'Przychodzący VAT wg towarów, prac i usług %1';
								|tr = '%1 ürün, iş ve hizmetler için KDV girişi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư chênh lệch vào giá trị hàng hóa %1';
								|ru = 'Ввод остатков отклонений в стоимости товаров %1';
								|en = 'OB entry: goods cost variances %1'; fa = 'OB entry: goods cost variances %1';
								|it = 'OB entry: goods cost variances %1';
								|pl = 'OB entry: goods cost variances %1';
								|tr = 'Ürün maliyetindeki farkların bakiyelerinin girilmesi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
		TitleTemplate1 = NStr("vi = 'Nhập nguyên vật liệu đã chuyển giao gia công %1';
								|ru = 'Ввод остатков материалов, переданных переработчикам %1';
								|en = 'Enter remaining materials transferred to subcontractors %1'; fa = 'Enter remaining materials transferred to subcontractors %1';
								|it = 'Enter remaining materials transferred to subcontractors %1';
								|pl = 'Enter remaining materials transferred to subcontractors %1';
								|tr = 'Fason üreticiye transfer edilen malzemelerin bakiyelerinin girişi %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOtherSTSExpenses Then
		TitleTemplate1 = NStr("vi = 'Chi phí theo hệ thống ThGL (khác) %1';
								|ru = 'Расходы по УСН (прочие) %1';
								|en = 'STS expenses (other) %1'; fa = 'STS expenses (other) %1';
								|it = 'Spese in base al Sistema Fiscale Semplificato (altre) %1';
								|pl = 'Rozchody wg uproszczonego systemu opodatkowania (inne) %1';
								|tr = 'Basitleştirilmiş Vergi Sistemine göre giderler (diğer) %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntrySTSExpensesOnGoods Then
		TitleTemplate1 = NStr("vi = 'Chi phí theo hệ thống ThGL (hàng hóa) %1';
								|ru = 'Расходы по УСН (товары) %1';
								|en = 'STS expenses (goods) %1'; fa = 'STS expenses (goods) %1';
								|it = 'Spese in base al sistema fiscale semplificato (articoli) %1';
								|pl = 'Rozchody wg uproszczonego systemu opodatkowania (towary) %1';
								|tr = 'Basitleştirilmiş Vergi Sistemine göre giderler (ürünler) %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntrySTSExpensesOnMaterials Then
		TitleTemplate1 = NStr("vi = 'Chi phí theo hệ thống ThGL (nguyên vật liệu) %1';
								|ru = 'Расходы по УСН (материалы) %1';
								|en = 'STS expenses (materials) %1'; fa = 'STS expenses (materials) %1';
								|it = 'Spese in base al sistema fiscale semplificato (materiali) %1';
								|pl = 'Rozchody według uproszczonego systemu opodatkowania (materiały) %1';
								|tr = 'Basitleştirilmiş Vergi Sistemine göre giderler (malzemeler) %1'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư của nguyên vật liệu đã nhận để gia công %1';
								|ru = 'Ввод остатков материалов, принятых в переработку %1';
								|en = 'Enter remaining materials received for subcontracting %1'; fa = 'Enter remaining materials received for subcontracting %1';
								|it = 'Inserimento dei saldi dei materiali ricevuti in elaborazione %1';
								|pl = 'Wprowadzenie sald materiałów, przyjętych do przetwarzania %1';
								|tr = '%1 fason üretimine kabul edilen malzeme bakiyesinin girilmesi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư bán thành phẩm của người đặt gia công %1';
								|ru = 'Ввод остатков полуфабрикатов давальца %1';
								|en = 'Enter remaining semi-finished products of the provider %1'; fa = 'Enter remaining semi-finished products of the provider %1';
								|it = 'Inserimento dei saldi dei semilavorati del fornitore %1';
								|pl = 'Wprowadzenie sald półproduktów właściciela surowców %1';
								|tr = '%1 tedarikçi yarı mamul ürün bakiyelerini girme'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		TitleTemplate1 = NStr("vi = 'Nhập số dư sản phẩm của người đặt gia công %1';
								|ru = 'Ввод остатков продукции давальца %1';
								|en = 'Enter remaining manufactured products of the provider %1'; fa = 'Enter remaining manufactured products of the provider %1';
								|it = 'Inserimento dei saldi di produzione del fornitore %1';
								|pl = 'Wprowadzenie sald produkcji właściciela surowców %1';
								|tr = '%1 tedarikçi imal edilen ürünlerinin bakiyelerinin girilmesi'");
	EndIf;

	If TypeOf(Document) = Type("Structure") And ValueIsFilled(Document.Ref) Then
		EndOfTitle = NStr("vi = '%1 ngày %2';
							|ru = '%1 от %2';
							|en = '%1 from %2'; fa = '%1 from %2';
							|it = '%1 del %2';
							|pl = '%1 z dn. %2';
							|tr = '%2 itibaren %1'");
		EndOfTitle = StrTemplate(EndOfTitle, DocumentNumber, DocumentDate);
	ElsIf ValueIsFilled(Common.ObjectAttributeValue(Document, "Ref")) Then
		EndOfTitle = NStr("vi = '%1 ngày %2';
							|ru = '%1 от %2';
							|en = '%1 from %2'; fa = '%1 from %2';
							|it = '%1 del %2';
							|pl = '%1 z dn. %2';
							|tr = '%2 itibaren %1'");
		EndOfTitle = StrTemplate(EndOfTitle, DocumentNumber, DocumentDate);
	Else
		EndOfTitle = NStr("vi = '(tạo mới)';
							|ru = '(создание)';
							|en = '(create)'; fa = '(create)';
							|it = '(creazione)';
							|pl = '(utworzenie)';
							|tr = '(oluşturma)'");
	EndIf;
	
	Return StrTemplate(TitleTemplate1, EndOfTitle);

EndFunction

Function GetParametersForCopyingDocument(BusinessOperation) Export
	Return OBEntryServer.GetParametersForCopyingDocument(BusinessOperation);
EndFunction
	
Function ObtainingFormForEnteringBalancesOnSalesForPastPeriods(BusinessOperation) Export
	Return OBEntryServer.ObtainingFormForEnteringBalancesOnSalesForPastPeriods(BusinessOperation);
EndFunction
#EndRegion
