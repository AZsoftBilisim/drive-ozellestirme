#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export
	
	If TypeOf(FillingData) = Type("DocumentRef.CashRegisterReceipt") Then
		FillInCashRegisterReceipt(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("Goods") Then
			
		FillInCashRegisterReceipt(FillingData.CashRegisterReceipt, FillingData.CashRegisterReceipt);
		If FillingData.Property("Cashier") And ValueIsFilled(FillingData.Cashier) Then
			Cashier = FillingData.Cashier;
		EndIf;
		
		Goods.Clear();
		
		ReturnedGoods = GetFromTempStorage(FillingData.Goods);
		
		For Each TSRow In ReturnedGoods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, TSRow);
		EndDo;
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		If Not FillingData.Property("ReadingFormCommands") Then
			FillInSelectionDocument(FillingData);
		EndIf;
		
	Else
		
		CashRegister = Catalogs.CashRegisters.CashRegisterCashRegisterFiscalRegistrarForCWP();
		If ValueIsFilled(CashRegister) Then
			FillInDocumentAtCashRegister(CashRegister);
		Else
			Raise NStr("vi = 'Thiết bị được kết nối không được định cấu hình cho nơi làm việc hiện tại: Thiết bị tài chính';
						|ru = 'Для текущего рабочего места не настроено подключаемое оборудование: Фискальное устройство';
						|en = 'Peripherals are not configured for the current workplace: Fiscal device'; fa = 'Peripherals are not configured for the current workplace: Fiscal device';
						|it = 'L''apparecchiatura collegata non è configurata per il presente posto di lavoro: dispositivo fiscale';
						|pl = 'Podłączony sprzęt nie jest skonfigurowany dla obecnego miejsca pracy: Rejestrator fiskalny';
						|tr = 'Mevcut çalışma alanı için hiçbir bağlanabilir donanım yapılandırılmamıştır: Mali cihaz'");
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	BonusPointsServer.FillInBonusPointsCheckCashRegisterRefund(ThisObject);
	
	CashRegisterReceiptReturnLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ And WriteMode = DocumentWriteMode.UndoPosting Then
		
		Cancel = True;
		ErrorText = NStr("vi = 'Phiếu tính tiền trả lại đã đánh. Không thể hủy bỏ kết chuyển.';
						|ru = 'Чек ККМ на возврат пробит. Отмена проведения невозможна.';
						|en = 'Refund receipt is issued. Posting cancellation is unavailable.'; fa = 'Refund receipt is issued. Posting cancellation is unavailable.';
						|it = 'Emissione scontrino per resa. Impossibile annullare.';
						|pl = 'Wydrukowano paragon fiskalny. Anulowanie zaksięgowania jest niemożliwe.';
						|tr = 'İade kasa fişi kesilmiştir. İptal mümkün değildir'");
		Common.MessageToUser(ErrorText, ThisObject);
		
		Return;
		
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ProductsServer.ClearUnusedSeries(ThisObject,ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CashRegisterReceiptReturn));
	
	BonusPointsServer.FillInBonusPointsCheckCashRegisterRefund(ThisObject);
	
	CashRegisterReceiptReturnLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
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
	
	Raise NStr("vi = 'Phiếu trả lại chỉ được nhập trên cơ sở phiếu tính tiền.';
				|ru = 'Чек на возврат вводится только на основании чека ККМ.';
				|en = 'Refund receipt is entered only on the basis of receipt.'; fa = 'Refund receipt is entered only on the basis of receipt.';
				|it = 'Lo scontrino per resa è inserito solo nella causale dello scontrino.';
				|pl = 'Paragon do zwrotu wprowadza się tylko na podstawie paragonu fiskalnego.';
				|tr = 'Bir iade fişi yalnızca kasa fişi temelinde girilir.'");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	If ValueIsFilled(CashRegisterReceipt) Then
		CheckParameters.TSName = "Object";
		For Each RowOfProductsTable In Goods Do
			If RowOfProductsTable.NumberOfPackages <> 0 Then
				CheckedAttributes.Add("Count");
				CheckedAttributes.Add("NumberOfPackages");
				ProductsServer.CheckQuantityFilling(RowOfProductsTable, CheckedAttributes, Cancel, CheckParameters);	
			EndIf;
		EndDo;
		AttributeNameOfGoodsQuantity = "Goods.Count";
		AttributeNameOfGoodsNumberOfPackages = "Goods.NumberOfPackages";
		CheckedAttributes.Delete(CheckedAttributes.Find(AttributeNameOfGoodsQuantity));
		CheckedAttributes.Delete(CheckedAttributes.Find(AttributeNameOfGoodsNumberOfPackages));

	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.TSName = "Goods";
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	EndIf;
	
	AttributeNameOfGoodsAmount = "Goods.Sum";
	CheckedAttributes.Delete(CheckedAttributes.Find(AttributeNameOfGoodsAmount));
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	CashRegisterReceipt.CashRegisterShift AS CashRegisterShift,
	|	CashRegisterReceipt.Date          AS Date,
	|	CashRegisterReceipt.Posted      AS Posted,
	|	CashRegisterReceipt.Status        AS Status
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &CashRegisterReceipt
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Count     AS Count
	|INTO TSGoods
	|FROM
	|	&VTProducts_ AS Goods
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Count     AS QuantityInReceipt,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Count     AS Count
	|INTO TDProducts
	|FROM
	|	Document.CashRegisterReceipt.Goods AS Goods
	|WHERE
	|	Goods.Ref = &CashRegisterReceipt
	|
	|UNION ALL
	|
	|SELECT
	|	0                     AS QuantityInReceipt,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	-Goods.Count     AS Count
	|FROM
	|	Document.CashRegisterReceiptReturn.Goods AS Goods
	|WHERE
	|	Goods.Ref.CashRegisterReceipt = &CashRegisterReceipt
	|	AND Goods.Ref <> &CashRegisterReceiptReturn
	|	AND Goods.Ref.Posted
	|	AND Goods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND Goods.NumberOfPackages <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	0                     AS QuantityInReceipt,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	-Goods.Count    AS Count
	|FROM
	|	TSGoods AS Goods
	|
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products                  AS Products,
	|	Goods.Products.UnitOfMeasure AS UnitOfMeasure,
	|	Goods.Characteristic                AS Characteristic,
	|	SUM(Goods.Count)             AS Count,
	|	SUM(Goods.QuantityInReceipt)        AS QuantityInReceipt
	|FROM
	|	TDProducts AS Goods
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic
	|HAVING
	|	SUM(Goods.Count) < 0
	|";
	
	Query.Text = QueryText;
	Query.SetParameter("CashRegisterReceipt",        CashRegisterReceipt);
	Query.SetParameter("CashRegisterReceiptReturn", Ref);
	Query.SetParameter("VTProducts_", Goods.Unload(,"Products, Characteristic, Count"));
	
	Result = Query.ExecuteBatch(); 
	
	Selection = Result[0].Select();
	
	If Selection.Next() Then
		
		If Not Selection.Posted Then
			ErrorText = NStr("vi = 'Chưa kết chuyển phiếu tính tiền';
							|ru = 'Чек ККМ не проведен';
							|en = 'Receipt is not posted'; fa = 'Receipt is not posted';
							|it = 'Scontrino non emesso.';
							|pl = 'Paragon fiskalny nie został zaksięgowany';
							|tr = 'Kasa fişi kaydedilmedi'");
			Common.MessageToUser(ErrorText, ThisObject, "CashRegisterReceipt",, Cancel);
		EndIf;
		
		If Selection.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
			ErrorText = NStr("vi = 'Chưa đánh phiếu tính tiền bán hàng';
							|ru = 'Чек ККМ продажи не пробит';
							|en = 'Receipt of a sale is not issued'; fa = 'Receipt of a sale is not issued';
							|it = 'Scontrino di vendita non controllato';
							|pl = 'Paragon fiskalny sprzedaży nie został wydrukowany';
							|tr = 'Satış fişi kesilmemiş'");
			Common.MessageToUser(ErrorText, ThisObject, "CashRegisterReceipt",, Cancel);
		EndIf;
		
		ErrorText = "";
		If Not RetailSales.ShiftIsOpened(CashRegisterShift, Date, ErrorText) Then
			Common.MessageToUser(ErrorText, ThisObject, "CashRegisterShift",, Cancel);
		EndIf;
		
		ProductSelection_1 = Result[3].Select();
		If Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
			
			While ProductSelection_1.Next() Do
				
				Balance = -ProductSelection_1.Count;
				ProductIsPresentInOriginalReceipt = ProductSelection_1.QuantityInReceipt > 0;
				
				RowsArray = Goods.FindRows(New Structure("Products, Characteristic", ProductSelection_1.Products, ProductSelection_1.Characteristic));
				
				// Let's reverse the order of the rows
				FoundRows = New Array; // Array of LineOfATabularSection
				For Each String In RowsArray Do
					FoundRows.Insert(0,String);
				EndDo;
				
				For Each FoundRow In FoundRows Do
					
					Count = ?(FoundRow.Count >= Balance, Balance, FoundRow.Count);
					Balance = Balance - Count;
					
					If ProductIsPresentInOriginalReceipt Then
						ErrorText = NStr("vi = 'Số lượng hàng hóa trả lại cao hơn số lượng đã bán là %1% %2%';
										|ru = 'Количество возвращаемого товара превышает количество проданного на %1% %2%';
										|en = 'Quantity of goods pending return exceeds the quantity of sold goods by %1% %2%'; fa = 'Quantity of goods pending return exceeds the quantity of sold goods by %1% %2%';
										|it = 'Quantità prodotto da restiture è superiore alla quantita venduta di %1%%2%';
										|pl = 'Ilość zwróconych towarów przekracza ilość sprzedanych na %1% %2%';
										|tr = 'İade edilen miktar satılan miktarı %1% %2% oranında aşıyor'");
						ErrorText = StrReplace(ErrorText, "%1%", Count * (FoundRow.NumberOfPackages / FoundRow.Count));
						ErrorText = StrReplace(ErrorText, "%2%", ?(ValueIsFilled(FoundRow.Package), FoundRow.Package, FoundRow.Products.UnitOfMeasure));
						
						ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
											|ru = 'в строке %LineNumber% списка ""Товары""';
											|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
											|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
											|pl = 'w wierszu %LineNumber% listy ""Towary""';
											|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
						ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", FoundRow.LineNumber);
						
						Common.MessageToUser(
							ErrorText + " " + ErrorAddress,
							ThisObject,
							CommonClientServer.PathToTabularSection("Goods", FoundRow.LineNumber, "NumberOfPackages"),
							,
							Cancel);
					Else
						ErrorText = NStr("vi = 'Mặt hàng %1% không được bán theo phiếu %2%. Hãy xóa mục mặt hàng';
										|ru = 'Номенклатура %1% не продавалась по чеку %2%. Удалите номенклатурную позицию';
										|en = 'Items %1% were not sold by receipt %2%. Remove the product item'; fa = 'Items %1% were not sold by receipt %2%. Remove the product item';
										|it = 'La nomenclatura %1% non è stata venduta tramite scontrino%2%. Eliminare la posizione della nomenclatura';
										|pl = 'Wykaz towarów %1% nie sprzedawano na podstawie paragonu %2%. Usuń pozycje wykazu towarów';
										|tr = 'Öğe%1% fişle satılmadı %2%. Öğe kalemini silin'");
						ErrorText = StrReplace(ErrorText, "%1%", FoundRow.Products);
						ErrorText = StrReplace(ErrorText, "%2%", CashRegisterReceipt);
						
						ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
											|ru = 'в строке %LineNumber% списка ""Товары""';
											|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
											|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
											|pl = 'w wierszu %LineNumber% listy ""Towary""';
											|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
						ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", FoundRow.LineNumber);
						
						Common.MessageToUser(
							ErrorText + " " + ErrorAddress,
							ThisObject,
							CommonClientServer.PathToTabularSection("Goods", FoundRow.LineNumber, "Products"),
							,
							Cancel);
					EndIf;
					
					If Balance <= 0 Then
						Break;
					EndIf;
					
				EndDo;
			EndDo;
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseWarerooms(Warehouse, Date) Then
		AttributeNameOfGoodsPremises = "Goods.Premise";
		NotCheckedAttributeArray.Add(AttributeNameOfGoodsPremises);
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CashRegisterReceiptReturn),
												Cancel,
												NotCheckedAttributeArray);	
	RetailSales.CheckPaymentCompletionWithPaymentCards(ThisObject, Cancel);
	
	CashRegisterReceiptReturnLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// the procedure for filling out the document on the basis of the Cash register receipt document.
//
// Parameters:
//	DocumentBasis - DocumentRef.CashRegisterReceipt - the link to the document is the Cash register receipt.
//	FillingData - Structure - Data for filling in the document.
//	
Procedure FillInCashRegisterReceipt(Val DocumentBasis, FillingData)
	
	If Documents.ReceiptOfCashRegisterAdjustment.ThereIsCorrectionForCashRegisterReceipt(DocumentBasis, True) Then
		Raise NStr("vi = 'Đã nhập phiếu tính tiền điều chỉnh theo phiếu tính tiền này. Cấm nhập mới phiếu tính tiền!';
					|ru = 'По Чеку ККМ введен Чек ККМ коррекции. Ввод нового Чека ККМ возврат запрещен!';
					|en = 'Cash register adjustment voucher is entered on this receipt. Entering a new return receipt is not allowed!'; fa = 'Cash register adjustment voucher is entered on this receipt. Entering a new return receipt is not allowed!';
					|it = 'Per lo Scontrino di registratore di cassa è stato emesso lo Scontrino di registratore di cassa di correzione. È vietato inserire un nuovo Scontrino di registratore di cassa di restituzione!';
					|pl = 'Według paragonu kasy wprowadzono Paragon kasy korekty. Wprowadzenie nowego Paragonu kasy zwrot jest zabronione!';
					|tr = 'Kasa fişine ilişkin bir yazar kasa düzeltme fişi girilmiştir. Yeni bir kasa fişi iade edilemez!'");
	EndIf;
	If Documents.ReturnOfGoodsFromCustomer.ThereIsReturnOfGoodsFromClientByReceiptCashRegister(DocumentBasis) Then
		Raise NStr("vi = 'Đã nhập chứng từ Nhận hàng bán bị trả lại theo phiếu tính tiền này. Cấm nhập mới Phiếu tính tiền trả lại!';
					|ru = 'По Чеку ККМ введен Возврат товаров от клиента. Ввод нового Чека ККМ возврат запрещен!';
					|en = 'Return of goods from customer is entered for the receipt. You cannot enter a new return receipt.'; fa = 'Return of goods from customer is entered for the receipt. You cannot enter a new return receipt.';
					|it = 'Per lo Scontrino di registratore di cassa è stato inserito Reso dal cliente. È vietato inserire un nuovo Scontrino di registratore di cassa di reso!';
					|pl = 'Według paragonu kasy fiskalnej został wprowadzony Zwrot towarów od nabywcy. Wprowadzenie nowego paragonu kasy fiskalnej zwrotu jest zabronione!';
					|tr = 'Kasa fişine ilişkin müşteri mal iadesi girilmiştir. Yeni bir kasa fişi iadesi girilmez!'");
	EndIf;
	PresentationOfDeferredReceipt = "";
	If ValueIsFilled(Documents.CashRegisterReceiptReturn.FindDeferredReceiptCashRegisterRefundOnReceiptCashRegister(DocumentBasis, PresentationOfDeferredReceipt)) Then
		MessageText = NStr("vi = 'Theo phiếu tính tiền có chứng từ %1 hoãn lại. Cấm tạo mới Phiếu tính tiền trả lại!';
							|ru = 'По Чеку ККМ есть отложенный %1. Ввод нового Чека ККМ возврат запрещен!';
							|en = 'There is a deferred %1 under the receipt. Entering a new refund receipt is not allowed.'; fa = 'There is a deferred %1 under the receipt. Entering a new refund receipt is not allowed.';
							|it = 'In base allo Scontrino del Registratore di Cassa vi è %1 postposto. Non è possibile inserire un nuovo Scontrino di reso del Registratore di Cassa!';
							|pl = 'Wg paragonu kasowego jest odłożony %1. Wprowadzenie nowego paragonu kasowego zwrot jest zabroniony!';
							|tr = 'Kasa fişine ilişkin %1ertelme var. Yeni bir kasa fişi iadesi girilmez!'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, PresentationOfDeferredReceipt);
		Raise MessageText;
	EndIf;

	// Fill in the data of the document header.
	MainQueryText = 
	"SELECT
	|	CashRegisterReceipt.Currency AS Currency,
	|	CashRegisterReceipt.Ref AS CashRegisterReceipt,
	|	CashRegisterReceipt.PriceKind AS PriceKind,
	|	CashRegisterReceipt.Organization AS Organization,
	|	CashRegisterReceipt.CashRegister AS CashRegister,
	|	CashRegisterReceipt.Warehouse AS Warehouse,
	|	CashRegisterReceipt.PriceIncludesVAT AS PriceIncludesVAT,
	|	CashRegisterReceipt.VATTaxation AS VATTaxation,
	|	CashRegisterReceipt.Status AS Status,
	|	CashRegisterReceipt.Posted AS Posted,
	|	CashRegisterReceipt.Partner AS Partner,
	|	CashRegisterReceipt.LoyaltyCard AS LoyaltyCard,
	|	CashRegisterReceipt.CashRegisterShift AS CashChangeOfFoundationDocument
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &Ref
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
	|
	|UNION ALL
	|
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Series,
	|	SetOfSeries.Premise,
	|	-SetOfSeries.Count
	|FROM
	|	Document.CashRegisterReceiptReturn.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref.CashRegisterReceipt = &Ref
	|	AND SetOfSeries.Ref.Posted
	|	AND SetOfSeries.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|;
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
	|";

	QueryTextArray = New Array;
	QueryTextArray.Add(MainQueryText);
	QueryTextArray.Add(Documents.CashRegisterReceipt.QueryTextForReceivingUndeliveredPaymentsByCashRegisterReceipt(True, True));

	ArrayOfPaymentKinds = New Array;
	ArrayOfPaymentKinds.Add(Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTextArray, Chars.LF+";");
	
	Query.SetParameter("Ref", DocumentBasis);	
	Query.SetParameter("TypesOfPayments", ArrayOfPaymentKinds);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	FillPropertyValues(ThisObject, Selection, ,"Status, Posted");
	
	If Not Selection.Posted Then
		ErrorText = NStr("vi = 'Phiếu tính tiền chưa kết chuyển. Không thể nhập trên cơ sở';
						|ru = 'Чек ККМ не проведен. Ввод на основании невозможен.';
						|en = 'Receipt is not posted. Generation from this base document is not allowed.'; fa = 'Receipt is not posted. Generation from this base document is not allowed.';
						|it = 'Scontrino non emesso. Impossibile immettere nella ricevuta.';
						|pl = 'Paragon fiskalny nie został zaksięgowany. Wprowadzenie na podstawie nie jest możliwe.';
						|tr = 'Kasa fişi kaydedilmemiştir. Temelde giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	If Selection.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		ErrorText = NStr("vi = 'Phiếu tính tiền chưa đánh. Không thể nhập trên cơ sở';
						|ru = 'Чек ККМ не пробит. Ввод на основании невозможен.';
						|en = 'Receipt is not issued. Generation from this base document is not allowed.'; fa = 'Receipt is not issued. Generation from this base document is not allowed.';
						|it = 'Scontrino non controllato. Impossibile immettere nella ricevuta.';
						|pl = 'Paragon fiskalny sprzedaży nie został wydrukowany. Wprowadzenie na podstawie nie jest możliwe.';
						|tr = 'Kasa fişi kesilmemiştir. Temelde giriş mümkün değildir.'");
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
	CashRegisterParameters = Catalogs.CashRegisters.CashRegisterParameters(CashRegister);
	
	StructureRegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;

	FilterParameters = Documents.CashRegisterReceipt.ParametersForReceivingNonReturnedItemsByCashRegisterReceipt();
	FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment = CashRegisterParameters.UseWithoutConnectingPeripherals;
	FilterParameters.CashRegisterShift = CashRegisterShift;
	FilterParameters.CashRegisterReceipt = DocumentBasis;
	If Not ValueIsFilled(DocumentBasis) Then
		FilterParameters.Organization = Organization;
	EndIf;
	If ValueIsFilled(CashRegisterShift) Then
		FilterParameters.UsedByKKTFZ54 = RetailSalesServerCall.UsedByKKTFZ54(CashRegisterShift);
	EndIf;
	TableOfNonReturnedGoods = Documents.CashRegisterReceipt.TableOfNonReturnedItemsByCashRegisterReceipt(FilterParameters);
	
	If TableOfNonReturnedGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Theo phiếu tính tiền này tất cả hàng hóa đã được trả lại';
						|ru = 'По данному чеку ККМ все товары уже возвращены.';
						|en = 'All goods on this receipt have already been returned.'; fa = 'All goods on this receipt have already been returned.';
						|it = 'Secondo i dati dello scontrino, tutti i prodotti sono stati resi.';
						|pl = 'Dla danego paragonu fiskalnego wszystkie wiersze pozycji już zwrócono.';
						|tr = 'Kasa fişi verilerine göre tüm ürünler iade edildi.'");
		Raise ErrorText;
	EndIf;
	
	If Not CashRegisterShift = Selection.CashChangeOfFoundationDocument
		And Not CalculationOfCostCached.BatchAccountingVersion22(CurrentSessionDate())
		And Not GetFunctionalOption("BaseVersion") Then
		Raise NStr("vi = 'Để nhập phiếu tính tiền trả lại ngoài phiên bán hàng, cần chuyển sang kế toán lô hàng phiên bản 2.2.
								|Để lập chứng từ ngoài phiên theo phiếu bán hàng khi sử dụng lô hàng phiên bản 2.1, hãy sử dụng chứng từ Nhận hàng bán bị trả lại.';
								|ru = 'Для ввода нового Чека ККМ возврат вне смены продажи необходимо перейти на партионный учет версии 2.2.
								|Чтобы оформить возврат вне смены по чеку продажи при использовании партионного учета версии 2.1 воспользуйтесь документом Возврат товаров от клиента.';
								|en = 'To register a new receipt of a return outside the sales shift, go to lot accounting 2.2.
								|To register a return outside the shift by a sales receipt using lot accounting 2.1, use the ""Goods return from customer"" document.'; fa = 'To register a new receipt of a return outside the sales shift, go to lot accounting 2.2.
								|To register a return outside the shift by a sales receipt using lot accounting 2.1, use the ""Goods return from customer"" document.';
								|it = 'Для ввода нового Чека ККМ возврат вне смены продажи необходимо перейти на партионный учет версии 2.2.
								|Чтобы оформить возврат вне смены по чеку продажи при использовании партионного учета версии 2.1 воспользуйтесь документом Возврат товаров от клиента.';
								|pl = 'To register a new receipt of a return outside the sales shift, go to lot accounting 2.2.
								|To register a return outside the shift by a sales receipt using lot accounting 2.1, use the ""Goods return from customer"" document.';
								|tr = 'Yeni bir Kasa Fişi İadesi Dış Satış Vardiyası girmek için toplu muhasebe sürüm 2.2''ye geçmeniz gerekir.
								| Toplu muhasebe sürüm 2.1 kullanırken bir dış satış fişi iadesini işlemek için Müşteriden İadeler belgesini kullanın.'");
	EndIf;
		
	Goods.Load(TableOfNonReturnedGoods);
	SetOfSeries.Load(QueryResult[2].Unload());
	PaymentWithPaymentCards.Load(QueryResult[QueryResult.UBound()].Unload());
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
EndProcedure

// Initializes document data.
//
// Parameters:
//		Document object - the Object to be filled in.
//
Procedure InitializeDocument(FillingData = Undefined)
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(Cashier) Then
		Cashier = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillInDocumentAtCashRegister(CashRegister)
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	FillPropertyValues(ThisObject, RegisterShiftState,,"Cashier");
	
EndProcedure

Procedure FillInSelectionDocument(FillingData)
	
	If FillingData.Property("CashRegister") Then
		FillInDocumentAtCashRegister(FillingData.CashRegister);
	ElsIf FillingData.Property("CashRegisterShift") And TypeOf(FillingData.CashRegisterShift) = Type("DocumentRef.CashRegisterShift") Then
		CashRegisterToFillIn = Common.ObjectAttributeValue(FillingData.CashRegisterShift, "CashRegister");
		If Not CashRegisterToFillIn = Undefined Then
			FillInDocumentAtCashRegister(CashRegisterToFillIn);
		EndIf;	
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

#EndRegion

#EndRegion

#EndIf