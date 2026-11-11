#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export
	
	FillInDataType = TypeOf(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef.GiftCertificateSale") Then
		
		ServicesForSaleOfGiftCertificates(FillingData, Undefined);
		
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("CashRegisterReceipt") Then
		
		ServicesForSaleOfGiftCertificates(FillingData.CashRegisterReceipt, FillingData);
		FillInDocumentAtCashRegister(CashRegister);
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Counterparty) Then
		Counterparty = Catalogs.Counterparties.RetailCustomer;
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			FillInCalculationObject();
			
		ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
			
			Cancel = True;
			
			ErrorText = NStr("vi = 'Đánh phiếu tính tiền trả lại phiếu quà tặng. Không thể hủy bỏ kết chuyển.';
							|ru = 'Чек на возврат подарочных сертификатов пробит. Отмена проведения невозможна.';
							|en = 'Refund receipt of gift cards is issued. Posting cancellation is unavailable.'; fa = 'Refund receipt of gift cards is issued. Posting cancellation is unavailable.';
							|it = 'Lo scontrino per la resa dei buoni regalo è emesso. Impossibile annullare.';
							|pl = 'Paragon na zwrot certyfikatów podarunkowych jest wydrukowany. Anulowanie zatwierdzenia jest niemożliwe.';
							|tr = 'Hediye kuponlarının iade fişi tahsil edilmiştir. İptal işlemi mümkün değildir.'");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject);
			
			Return;
			
		EndIf;
		
	Else
		
		For Each TSRow In GiftCertificates Do
			TSRow.ARAPObject = Undefined;
		EndDo;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "GiftCertificates,PaymentWithPaymentCards");
		
	DocumentAmount = GiftCertificates.Total("Sum");
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Raise NStr("vi = 'Chứng từ ""Nhận phiếu quà tặng trả lại"" chỉ được nhập trên cơ sở chứng từ ""Bán phiếu quà tặng"".';
				|ru = 'Документ ""Возврат подарочных сертификатов"" вводится только на основании документа ""Реализация подарочных сертификатов"".';
				|en = 'The ""Return of gift cards"" document can only be generated from the ""Gift card sales"" base document.'; fa = 'The ""Return of gift cards"" document can only be generated from the ""Gift card sales"" base document.';
				|it = 'Il documento ""Resa dei buoni regalo"" viene inserito solo in base al documento ""Realizzo dei buoni regalo"".';
				|pl = 'Dokument ""Zwrot certyfikatów podarunkowych"" jest wprowadzany na podstawie dokumentu ""Sprzedaż certyfikatów podarunkowych"".';
				|tr = '""Hediye kuponlarının iadesi"" belgesi yalnızca ""Hediye kuponlarının satışı"" belgesi temelinde girilir.'");
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "GiftCertificates,PaymentWithPaymentCards");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	GiftCertificatesServer.FillCheckProcessing(ThisObject, Cancel);
	RetailSales.CheckPaymentCompletionWithPaymentCards(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// Procedure for filling out a document based on an expense order.
//
// Parameters:
//	DocumentBasis - DocumentRef.PaymentRequest - Request for payment
//	FillingData - Structure - Data for filling in the document.
//	
Procedure ServicesForSaleOfGiftCertificates(Val DocumentBasis, FillingData = Undefined)
	
	RefundableGiftCertificates = Undefined;
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("GiftCertificates") Then
			RefundableGiftCertificates = GetFromTempStorage(FillingData.GiftCertificates);
		EndIf;
	EndIf;

	QueriesTexts = New Array;
	Query = New Query;
	
	// The text of the request to fill in the document header.
	QueryText = "SELECT
			|	GiftCertificateSale.Currency AS Currency,
			|	GiftCertificateSale.Ref AS CashRegisterReceipt,
			|	GiftCertificateSale.Organization AS Organization,
			|	GiftCertificateSale.CashRegister AS CashRegister,
			|	GiftCertificateSale.CashRegisterShift AS CashRegisterShift,
			|	GiftCertificateSale.Status AS Status,
			|	GiftCertificateSale.Posted AS Posted
			|FROM
			|	Document.GiftCertificateSale AS GiftCertificateSale
			|WHERE
			|	GiftCertificateSale.Ref = &Ref";
	QueriesTexts.Add(QueryText);

	// Query Text for filling in the tabular part Payment by payment cards
	// all types of payment except payment by payment cards
	QueriesTexts.Add(Documents.GiftCertificateSale.QueryTextForReceivingUndeliveredPaymentsByCashRegisterReceipt(True, True));
	
	// The text of the request to fill in the table part
	If RefundableGiftCertificates = Undefined Then
		QueryText = "SELECT
               |	GiftCertificates.GiftCertificate AS GiftCertificate,
               |	SUM(GiftCertificates.Count) AS Count,
               |	SUM(GiftCertificates.Sum) AS Sum
               |FROM
               |	(SELECT
               |		GiftCertificates.GiftCertificate AS GiftCertificate,
               |		1 AS Count,
               |		GiftCertificates.Sum AS Sum
               |	FROM
               |		Document.GiftCertificateSale.GiftCertificates AS GiftCertificates
               |	WHERE
               |		GiftCertificates.Ref = &Ref
               |	
               |	UNION ALL
               |	
               |	SELECT
               |		GiftCertificates.GiftCertificate,
               |		-1,
               |		-GiftCertificates.Sum
               |	FROM
               |		Document.ReturnOfGiftCards.GiftCertificates AS GiftCertificates
               |	WHERE
               |		GiftCertificates.Ref.GiftCertificateSale = &Ref
               |		AND GiftCertificates.Ref.Posted
               |		AND GiftCertificates.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)) AS GiftCertificates
               |
               |GROUP BY
               |	GiftCertificates.GiftCertificate
               |
               |HAVING
               |	SUM(GiftCertificates.Count) > 0
               |
               |ORDER BY
               |	GiftCertificate";
		QueriesTexts.Add(QueryText);
	EndIf;
	ArrayOfExcludedPaymentTypes = New Array;
	ArrayOfExcludedPaymentTypes.Add(Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
	Query.Text = StrConcat(QueriesTexts, Chars.LF+";"+Chars.LF);
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("TypesOfPayments", ArrayOfExcludedPaymentTypes);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection, ,"Status, Posted");
	
	ErrorText = "";
	If Not Selection.Posted Then
		ErrorText = NStr("vi = 'Chứng từ ""Bán phiếu quà tặng"" chưa được kết chuyển. Không thể nhập trên cơ sở.';
						|ru = 'Документ ""Реализация подарочных сертификатов"" не проведен. Ввод на основании невозможен.';
						|en = 'Document ""Gift card sales"" is not posted. Generation from base documents is not available.'; fa = 'Document ""Gift card sales"" is not posted. Generation from base documents is not available.';
						|it = 'Il documento ""Realizzo dei buoni regalo"" non è stato registrato. Inserimento in base alla causale non è possibile.';
						|pl = 'Dokument ""Реализация подарочных сертификатов"" nie jest zatwierdzony. Wprowadzenie na podstawie jest niemożliwe.';
						|tr = '""Hediye kuponu satışı"" belgesi kaydedilmemiştir. Temelde giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	If Selection.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		ErrorText = NStr("vi = 'Không thể đánh phiếu ""Bán phiếu quà tặng"". Không thể nhập trên cơ sở.';
						|ru = 'Чек ""Реализация подарочных сертификатов"" не пробит. Ввод на основании невозможен.';
						|en = 'Receipt ""Gift card sales"" is not issued. Generation from base documents is not available.'; fa = 'Receipt ""Gift card sales"" is not issued. Generation from base documents is not available.';
						|it = 'Lo scontrino ""Realizzo dei buoni regalo"" non è stato emesso. Inserimento in base alla causale non è possibile.';
						|pl = 'Paragon ""Реализация подарочных сертификатов"" nie jest wydrukowany. Wprowadzenie na podstawie jest niemożliwe.';
						|tr = '""Hediye kuponu satışı"" fişinin tahsil edilmemiştir. Temelde giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	CashRegisterByDefault = Catalogs.CashRegisters.KKMCashRegisterIsFiscalCashRegisterByCompanyForCWPByDefault(Selection.Organization, Selection.CashRegister);
	If Not ValueIsFilled(CashRegisterByDefault) Then
		MessageText = NStr("vi = 'Đối với chỗ làm việc hiện tại, chưa thiết lập tùy chỉnh quầy thu ngân theo doanh nghiệp: %Organization%.';
							|ru = 'Для текущего рабочего места не настроена касса ККМ по организации: %Organization%.';
							|en = 'The cash register is not configured for the current workplace for the company: %Organization%.'; fa = 'The cash register is not configured for the current workplace for the company: %Organization%.';
							|it = 'Для текущего рабочего места не настроена касса ККМ по организации: %Organization%.';
							|pl = 'The cash register is not configured for the current workplace for the company: %Organization%.';
							|tr = 'Mevcut çalışma alanı için yazar kasa ayarlanmadı: %Organization%.'");
		MessageText = StrReplace(MessageText, "%Organization%", Selection.Organization);
		Raise MessageText;
	EndIf;
	CashRegister = CashRegisterByDefault;
	StructureRegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
	
	CurrentSessionDate = CurrentSessionDate();
	DataOfGiftCertificates = Undefined;
	ValueTable = RefundableGiftCertificates;
	If ValueTable = Undefined Then
		ValueTable = QueryResult[3].Unload();
		DataOfGiftCertificates = GiftCertificatesServerCall.GetGiftCertificatesDetails(ValueTable.UnloadColumn("GiftCertificate"));
	EndIf;
	
	GiftCertificates.Clear();	
	For Each String In ValueTable Do
		GiftCertificateCanBeReturned = True;
		If ValueIsFilled(DataOfGiftCertificates) Then
			GiftCertificateCanBeReturned = False;
			GiftCertificateDetails = DataOfGiftCertificates[String.GiftCertificate];
			If Not GiftCertificateDetails = Undefined Then
				If GiftCertificatesClientServer.GiftCertificateCanBeReturned(GiftCertificateDetails, CurrentSessionDate) Then
					GiftCertificateCanBeReturned = True;
				EndIf;
			EndIf;
		EndIf;
		If GiftCertificateCanBeReturned Then
			TSRow = GiftCertificates.Add();
			FillPropertyValues(TSRow, String);
		EndIf;
	EndDo;

	If GiftCertificates.Count() = 0 Then
		ErrorText = NStr("vi = 'Theo phiếu tính tiền này, tất cả phiếu quà tặng đã được trả lại, sử dụng một phần hoặc không có hiệu lực.';
						|ru = 'По данному чеку ККМ все подарочные сертификаты уже возвращены, частично использованы, либо уже не действуют.';
						|en = 'All gift cards from this receipt are returned, partially used, or invalid.'; fa = 'All gift cards from this receipt are returned, partially used, or invalid.';
						|it = 'In base allo scontrino del registratore fiscale, tutti i buoni regalo sono già stati restituiti, parzialmente utilizzati o già non validi.';
						|pl = 'Dla danego paragonu fiskalnego wszystkie certyfikaty podarunkowe są już zwrócone. częściowo zużyte lub są nieważne.';
						|tr = 'Tüm hediye kuponları zaten iade edilmiş, kısmen kullanılmış veya bu makbuz üzerinde artık geçerli değildir.'");
		Raise ErrorText;
	EndIf;

	GiftCertificateSale = DocumentBasis;
	DocumentAmount = GiftCertificates.Total("Sum");
	
	// Distribution of the refund amount according to the payment table
	PaymentWithPaymentCards.Clear();
	AmountForAllocation = DocumentAmount;
	SamplePayments = QueryResult[2].Select();
	While SamplePayments.Next() And AmountForAllocation > 0 Do
		TSRow = PaymentWithPaymentCards.Add();
		FillPropertyValues(TSRow, SamplePayments);
		TSRow.Sum = Min(AmountForAllocation, TSRow.Sum);
		AmountForAllocation = AmountForAllocation - TSRow.Sum;
	EndDo;
	
EndProcedure

// Initializes the sale of goods and services.
//	Document object - the Object to be filled in.
//
Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Cashier      = Users.CurrentUser();
	If Not ValueIsFilled(Counterparty) Then
		Counterparty = Catalogs.Counterparties.RetailCustomer;
	EndIf;
	
EndProcedure

Procedure FillInDocumentAtCashRegister(CashRegister)
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	VATTaxation = RegisterShiftState.VATTaxation;
	
EndProcedure

Procedure FillInCalculationObject()
	
	If GiftCertificates.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	CAST(GiftCertificates.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate
	|INTO GiftCertificates
	|FROM
	|	&GiftCertificates AS GiftCertificates
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	GiftCertificates AS GiftCertificates
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = GiftCertificates.GiftCertificate
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GiftCertificates.GiftCertificate.Owner.GiftCardAccounting25";
	
	Query.SetParameter("GiftCertificates", GiftCertificates.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		IndexOf = Selection.LineNumber - 1;
		GiftCertificates[IndexOf].ARAPObject = Selection.ARAPObject;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
