#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.CashRegisterReceipt") Then
		
		FillOutDocumentOnCashRegisterReceipt(FillingData);
		FillingLocalization(ThisObject, FillingData, StandardProcessing);
		
	ElsIf FillInDataType = Type("Structure") And FillingData.Property("Goods") Then
		
		FillOutDocumentOnCashRegisterReceipt(FillingData.CashRegisterReceipt);
		FillingLocalization(ThisObject, FillingData.CashRegisterReceipt, StandardProcessing);
		Goods.Clear();
		
		ReturnedGoods = GetFromTempStorage(FillingData.Goods);
		
		For Each TSRow In ReturnedGoods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, TSRow);
		EndDo;

	ElsIf FillInDataType = Type("Structure") Then
		
		If Not FillingData.Property("ReadingFormCommands") Then
			FillInSelectionDocument(FillingData);
		EndIf;
		
	Else
		
		If Not ValueIsFilled(CashRegisterReceipt) Then
			Raise NStr("vi = 'Phiếu tính tiền điều chỉnh phải được nhập trên cơ sở Phiếu tính tiền';
						|ru = 'Чек ККМ коррекции необходимо вводить на основании чека ККМ';
						|en = 'Cash register adjustment voucher must be entered on the basis of CR receipt'; fa = 'Cash register adjustment voucher must be entered on the basis of CR receipt';
						|it = 'Lo scontrino di registratore di cassa di correzione deve essere inserito in base allo scontrino di registratore di cassa';
						|pl = 'Paragon kasy korekty należy wprowadzać na podstawie paragonu kasy';
						|tr = 'Yazar kasa düzeltme fişi, kasa fişi temel alınarak girilmelidir'");
		EndIf;
				
		CashRegister = Catalogs.CashRegisters.CashRegisterCashRegisterFiscalRegistrarForCWP();
		If ValueIsFilled(CashRegister) Then
			FillInDocumentAtCashRegister(CashRegister);
		Else
			Raise NStr("vi = 'Đối với chỗ làm việc hiện tại không thiết lập thiết bị kết nối: Máy ghi nhận tiền mặt';
						|ru = 'Для текущего рабочего места не настроено подключаемое оборудование: Фискальный регистратор';
						|en = 'Peripherals are not configured for the current workplace: Fiscal cash register'; fa = 'Peripherals are not configured for the current workplace: Fiscal cash register';
						|it = 'L''apparecchiatura collegata non è configurata per il presente posto di lavoro: registratore di cassa';
						|pl = 'Podłączony sprzęt nie jest skonfigurowany do obecnego miejsca pracy: Rejestrator fiskalny';
						|tr = 'Mevcut çalışma alanı için hiçbir bağlanabilir donanım yapılandırılmamıştır: Mali yazar kasa'");
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	EndIf;
	
	If Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ And WriteMode = DocumentWriteMode.UndoPosting Then
		
		Cancel = True;
		
		ErrorText = NStr("vi = 'Phiếu tính tiền đã đánh. Không thể hủy bỏ kết chuyển';
						|ru = 'Чек ККМ пробит. Отмена проведения невозможна';
						|en = 'Receipt is issued. Posting cancellation is unavailable'; fa = 'Receipt is issued. Posting cancellation is unavailable';
						|it = 'Scontrino del registratore di cassa è stato emesso. Cancellazione impossibile';
						|pl = 'Wydrukowano paragon fiskalny. Anulowanie jest niemożliwe';
						|tr = 'Kasa fişi kesilmiştir. İptal mümkün değildir'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject);
		Return;
		
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ProductsServer.ClearUnusedSeries(ThisObject, ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CashRegisterReceipt));
	
	ReceiptOfCashRegisterAdjustmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Raise NStr("vi = 'Sao chép chứng từ ""Kiểm tra chỉnh sửa Phiếu tính tiền"" đều bị cấm!';
				|ru = 'Копирование документа ""Чек ККМ коррекции"" запрещено!';
				|en = 'Copying of the ""Cash register adjustment voucher"" document is not allowed!'; fa = 'Copying of the ""Cash register adjustment voucher"" document is not allowed!';
				|it = 'È vietato copiare il documento ""Scontrino di registratore di cassa di correzione""!';
				|pl = 'Kopiowanie dokumentu""Paragon kasy korekty"" jest zabronione!';
				|tr = '""Yazar kasa düzeltme fişi"" belgesi kopyalanamaz!'");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Goods.Premise");
	EndIf;
	
	If AdjustmentType = Enums.TypesOfAdjustmentReceipts.Independently_ Then
		CheckedAttributes.Add("AdjustmentDescription");
	Else
		CheckedAttributes.Add("PrescriptionNumberOfTaxAuthority");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CashRegisterReceipt),
												Cancel,
												NotCheckedAttributeArray);
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	RetailSales.CheckPaymentCompletionWithPaymentCards(ThisObject, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Cashier = Users.CurrentUser();
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillParameters.Organization = Organization;
	FillParameters.Date = Date;
	FillParameters.Warehouse = Warehouse;
	FillParameters.Retail_ = True;
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

Procedure FillInDocumentAtCashRegister(CashRegister)
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	FillPropertyValues(ThisObject, RegisterShiftState,,"Cashier");
	
EndProcedure

Procedure FillInSelectionDocument(FillingData)
	
	If FillingData.Property("CashRegister") Then
		FillInDocumentAtCashRegister(FillingData.CashRegister);
	EndIf;
	
EndProcedure

Procedure FillOutDocumentOnCashRegisterReceipt(DocumentBasis)
	
	If Documents.CashRegisterReceiptReturn.ThereIsRefundByReceiptCashRegister(DocumentBasis) Then
		Raise NStr("vi = 'Đã nhập phiếu tính tiền trả lại theo phiếu tính tiền này. Cấm nhập phiếu tính tiền điều chỉnh!';
					|ru = 'По Чеку ККМ введен Чек ККМ на возврат. Ввод Чека ККМ коррекции запрещен!';
					|en = 'Return receipt is entered on this receipt. Entering an adjustment receipt is not allowed!'; fa = 'Return receipt is entered on this receipt. Entering an adjustment receipt is not allowed!';
					|it = 'Per lo Scontrino di registratore di cassa è stato emesso lo Scontrino di registratore di cassa di restituzione. È vietato inserire lo Scontrino di registratore di cassa di correzione!';
					|pl = 'Według paragonu kasy wprowadzono Paragon kasy na zwrot. Wprowadzenie Paragonu kasy korekty jest zabronione!';
					|tr = 'Kasa fişine ilişkin bir iade fişi girilmiştir. Kasa fişi düzenlenemez!'");
	EndIf;
	
	If Documents.ReceiptOfCashRegisterAdjustment.ThereIsCorrectionForCashRegisterReceipt(DocumentBasis, True) Then
		Raise NStr("vi = 'Đã nhập phiếu tính tiền điều chỉnh theo phiếu tính tiền này. Cấm nhập phiếu tính tiền điều chỉnh mới!';
					|ru = 'По Чеку ККМ введен Чек ККМ коррекции. Ввод нового Чека ККМ коррекции запрещен!';
					|en = 'Cash register adjustment voucher is entered on this receipt. Entering a new cash register adjustment voucher is not allowed!'; fa = 'Cash register adjustment voucher is entered on this receipt. Entering a new cash register adjustment voucher is not allowed!';
					|it = 'Per lo Scontrino di registratore di cassa è stato emesso lo Scontrino di registratore di cassa di correzione. È vietato inserire un nuovo Scontrino di registratore di cassa di correzione!';
					|pl = 'Według paragonu kasy wprowadzono Paragon kasy korekty. Wprowadzenie nowego Paragonu kasy korekty jest zabronione!';
					|tr = 'Kasa fişine ilişkin bir yazar kasa düzeltme fişi girilmiştir. Yeni bir kasa fişi düzenlenemez!'");
	EndIf;
	
	If Documents.ReturnOfGoodsFromCustomer.ThereIsReturnOfGoodsFromClientByReceiptCashRegister(DocumentBasis) Then
		Raise NStr("vi = 'Đã nhập chứng từ Nhận hàng bán bị trả lại theo phiếu tính tiền này. Cấm nhập phiếu tính tiền điều chỉnh mới!';
					|ru = 'По Чеку ККМ введен Возврат товаров от клиента. Ввод нового Чека ККМ коррекции запрещен!';
					|en = 'Goods return from customer is entered for the Cash register adjustment voucher. You cannot enter new Cash register adjustment voucher.'; fa = 'Goods return from customer is entered for the Cash register adjustment voucher. You cannot enter new Cash register adjustment voucher.';
					|it = 'Per lo Scontrino di registratore di cassa è stato inserito Reso dal cliente. È vietato inserire un nuovo Scontrino di registratore di cassa di correzione!';
					|pl = 'Według paragonu kasy fiskalnej został wprowadzony Zwrot towarów od nabywcy. Wprowadzenie nowego paragonu kasy fiskalnej korekty jest zabroniony!';
					|tr = 'Kasa fişine ilişkin müşteri mal iadesi girilmiştir. Yeni bir kasa fişi düzenlenemez!'");
	EndIf;
	
	// Fill in the data of the document header.
	QueryText = 
	"SELECT
	|	CashRegisterReceipt.Currency AS Currency,
	|	CashRegisterReceipt.Ref AS CashRegisterReceipt,
	|	CashRegisterReceipt.Date AS DateOfCashRegisterReceipt,
	|	CashRegisterReceipt.PriceKind AS PriceKind,
	|	CashRegisterReceipt.Organization AS Organization,
	|	CashRegisterReceipt.CashRegister AS CashRegister,
	|	CashRegisterReceipt.Warehouse AS Warehouse,
	|	CashRegisterReceipt.PriceIncludesVAT AS PriceIncludesVAT,
	|	CashRegisterReceipt.VATTaxation AS VATTaxation,
	|	CashRegisterReceipt.ReceivedInCash AS ReceivedInCash,
	|	CashRegisterReceipt.Status AS Status,
	|	CashRegisterReceipt.Posted AS Posted,
	|	CashRegisterReceipt.Partner AS Partner,
	|	CashRegisterReceipt.PaymentMethod AS PaymentMethod
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.USAISProducts AS USAISProducts,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Products.ItemsType AS ItemsType,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Package AS Package,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	CAST(CASE
	|		WHEN Goods.ManualDiscount + Goods.DiscountMarkupAmount + Goods.AmountOfBonusPointsToDeductionInCurrency = 0
	|		OR Goods.NumberOfPackages = 0
	|			THEN Goods.Price
	|		ELSE Goods.Sum / Goods.NumberOfPackages
	|	END AS NUMBER(31, 2)) AS Price,
	|	Goods.Sum AS Sum,
	|	Goods.VATRate AS VATRate,
	|	Goods.VATAmount AS VATAmount,
	|	Goods.Premise AS Premise,
	|	Goods.Seller AS Seller,
	|	Goods.Consignor AS Consignor,
	|	Goods.LineNumber
	|INTO TDProducts
	|FROM
	|	Document.CashRegisterReceipt.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.USAISProducts AS USAISProducts,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Products.ItemsType AS ItemsType,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Package AS Package,
	|	Goods.VATRate AS VATRate,
	|	Goods.Price AS Price,
	|	Goods.Premise AS Premise,
	|	Goods.Seller AS Seller,
	|	Goods.Consignor AS Consignor,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	Goods.Sum AS Sum,
	|	Goods.VATAmount AS VATAmount,
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	TDProducts AS Goods
	|WHERE
	|	Goods.Count > 0
	|
	|ORDER BY
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package,
	|	Premise,
	|	Seller,
	|	Consignor,
	|	Price
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Premise AS Premise,
	|	SetOfSeries.Count AS Count
	|INTO TDSeries
	|FROM
	|	Document.CashRegisterReceipt.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Premise AS Premise,
	|	SUM(SetOfSeries.Count) AS Count
	|FROM
	|	TDSeries AS SetOfSeries
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Series,
	|	SetOfSeries.Premise
	|HAVING
	|	SUM(SetOfSeries.Count) > 0
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Premise
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExciseStamps.ExciseStamp AS ExciseStamp,
	|	ExciseStamps.Help2 AS Help2,
	|	ExciseStamps.PackageBarcode AS PackageBarcode,
	|	ExciseStamps.ExciseStampCode AS ExciseStampCode
	|FROM
	|	Document.CashRegisterReceipt.ExciseStamps AS ExciseStamps
	|WHERE
	|	ExciseStamps.Ref = &Ref
	|
	|ORDER BY
	|	ExciseStamp,
	|	PackageBarcode,
	|	ExciseStampCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PaymentCards_.PaymentKind_ AS PaymentKind_,
	|	PaymentCards_.POSTerminal AS POSTerminal,
	|	PaymentCards_.AuthorizationCode AS AuthorizationCode,
	|	PaymentCards_.PaymentCardNumber AS PaymentCardNumber,
	|	PaymentCards_.Sum AS Sum
	|INTO RefundOfPaymentByPaymentCardsByReceipt
	|FROM
	|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|		INNER JOIN Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS PaymentCards_
	|		ON (PaymentCards_.Ref = CashRegisterReceiptReturn.Ref)
	|WHERE
	|	CashRegisterReceiptReturn.CashRegisterReceipt = &Ref
	|
	|INDEX BY
	|	POSTerminal,
	|	AuthorizationCode,
	|	PaymentCardNumber,
	|	Sum
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
	|	PaymentWithPaymentCards.POSTerminal AS POSTerminal,
	|	PaymentWithPaymentCards.AuthorizationCode AS AuthorizationCode,
	|	PaymentWithPaymentCards.PaymentCardNumber AS PaymentCardNumber,
	|	PaymentWithPaymentCards.Sum AS Sum,
	|	PaymentWithPaymentCards.CartID AS CartID,
	|	PaymentWithPaymentCards.ReferenceNumber AS ReferenceNumber,
	|	PaymentWithPaymentCards.ConnectionContract AS ConnectionContract,
	|	PaymentWithPaymentCards.PaymentSystemId AS PaymentSystemId,
	|	PaymentWithPaymentCards.POSTerminalReceiptNumber AS POSTerminalReceiptNumber
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentWithPaymentCards
	|WHERE
	|	PaymentWithPaymentCards.Ref = &Ref
	|	AND NOT (PaymentWithPaymentCards.PaymentKind_, PaymentWithPaymentCards.POSTerminal,
	|		PaymentWithPaymentCards.AuthorizationCode, PaymentWithPaymentCards.PaymentCardNumber, PaymentWithPaymentCards.Sum)
	|		IN
	|		(SELECT
	|			RefundOfPaymentByPaymentCardsByReceipt.PaymentKind_,
	|			RefundOfPaymentByPaymentCardsByReceipt.POSTerminal,
	|			RefundOfPaymentByPaymentCardsByReceipt.AuthorizationCode,
	|			RefundOfPaymentByPaymentCardsByReceipt.PaymentCardNumber,
	|			RefundOfPaymentByPaymentCardsByReceipt.Sum
	|		FROM
	|			RefundOfPaymentByPaymentCardsByReceipt AS RefundOfPaymentByPaymentCardsByReceipt)
	|
	|ORDER BY
	|	PaymentKind_,
	|	POSTerminal,
	|	PaymentCardNumber,
	|	AuthorizationCode,
	|	CartID,
	|	ConnectionContract,
	|	POSTerminalReceiptNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterReceiptGiftCertificates.GiftCertificate AS GiftCertificate,
	|	CashRegisterReceiptGiftCertificates.Sum AS Sum,
	|	CashRegisterReceiptGiftCertificates.AmountInCertificateCurrency AS AmountInCertificateCurrency
	|FROM
	|	Document.CashRegisterReceipt.GiftCertificates AS CashRegisterReceiptGiftCertificates
	|WHERE
	|	CashRegisterReceiptGiftCertificates.Ref = &Ref
	|
	|ORDER BY
	|	GiftCertificate";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection, ,"Status, Posted");
	DateOfAdjustedCalculation = Selection.DateOfCashRegisterReceipt;
	
	StructureRegisterShiftState = RetailSales.GetCashShiftState(Selection.CashRegister);
	CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
	
	If Not Selection.Posted Then
		ErrorText = NStr("vi = 'Phiếu tính tiền chưa kết chuyển. Không thể nhập trên cơ sở';
						|ru = 'Чек ККМ не проведен. Ввод на основании невозможен.';
						|en = 'Receipt is not posted. Generation from this base document is not allowed.'; fa = 'Receipt is not posted. Generation from this base document is not allowed.';
						|it = 'Scontrino non emesso. Impossibile immettere nella ricevuta.';
						|pl = 'Paragon fiskalny nie został zaksięgowany. Wprowadzenie na podstawie nie jest możliwe.';
						|tr = 'Kasa fişi kaydedilmemiştir. Temelde giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	Goods.Load(QueryResult[2].Unload());
	SetOfSeries.Load(QueryResult[4].Unload());
	ExciseStamps.Load(QueryResult[5].Unload());
	PaymentWithPaymentCards.Load(QueryResult[7].Unload());
	GiftCertificates.Load(QueryResult[8].Unload());
	
	Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ReceivedInCash = DocumentAmount - PaymentWithPaymentCards.Total("Sum") - GiftCertificates.Total("Sum");
	
EndProcedure

#EndRegion

#Region Other

#EndRegion

#Region Localization

Procedure FillingLocalization(Var_ThisObject, FillingData, StandardProcessing)
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
