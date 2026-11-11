#Region Public

// It is used to get a cache of the quality control mechanism in document forms in the context of an object,
// for example: Header or Goods.
// Parameters:
//  Cache - See QualityControl.DataCacheOfMechanism
//  Var_Key - String - the key of the data source in the object where the cache is used
// Returns:
//   Structure - structure with fields:
//    * Key - String
//    * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//    * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//    * FillInSenderSControlledLotReference - See QualityControl.New_ActionParameters
Function CacheByKey(Cache, Var_Key = Undefined) Export
	
	If Var_Key = Undefined Or TypeOf(Cache) <> Type("FixedArray") Then
		Return Cache;
	Else
		For Each Item In Cache Do
			If Item.Key = Var_Key Then
				Return Item.Parameters;
			EndIf;
		EndDo;
		Return Undefined;
	EndIf;
	
EndFunction

// Forms a Presentation of the "Controlled Parties" element of the Catalog.
// Parameters:
//  Attributes - See QualityControl.NewAttributesOfControlledLotReference
//  LanguageCode - String,Undefined - language code, if not specified, the Presentation will be in the user's language.
// Returns:
//  String - Presentation of the controlled Lot reference.
Function PresentationOfControlledLotReference(Attributes, LanguageCode = Undefined) Export
	
	If Not TypeOf(Attributes.Lot) = Type("CatalogRef.TermsOfPurchaseFromVendors")
			And Not TypeOf(Attributes.Lot) = Type("CatalogRef.CounterpartyContracts") Then
		
		Lot = Attributes.Lot;
		BusinessOperation = Attributes.BusinessOperation;
		DocumentType = NStr("ru = 'Неизвестный документ';
							|vi = 'Unknown document';
							|en = 'Unknown document'; fa = 'Unknown document';
							|it = 'Unknown document';
							|pl = 'Unknown document';
							|tr = 'Bilinmeyen belge'", LanguageCode);
		If TypeOf(Lot) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
			DocumentType = NStr("vi = 'Nhận hàng bán bị trả lại';
								|ru = 'Возврат товаров от клиента';
								|en = 'Sales return'; fa = 'برگشت از فروش';
								|it = 'Resi delle merci dal cliente';
								|pl = 'Zwrot towarów od klienta';
								|tr = 'Müşteriden ürün iadesi'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.GoodsReceiptFromCustomer") Then
			DocumentType = NStr("vi = 'Tiếp nhận hàng hóa từ khách';
								|ru = 'Поступление товаров от клиента';
								|en = 'Goods receipt from customer'; fa = 'دریافت کالا از مشتری';
								|it = 'Goods receipt from customer';
								|pl = 'Goods receipt from customer';
								|tr = 'Müşteriden ürün alımı'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.MovementOfProductsAndMaterials") Then
			
			If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromStoreroom") Then
				DocumentType = NStr("vi = 'Chuyển hàng hóa từ kho tại xưởng';
									|ru = 'Передача продукции из кладовой';
									|en = 'Transfer of products from shop floor stockroom'; fa = 'Transfer of products from shop floor stockroom';
									|it = 'Consegna dei prodotti dal deposito';
									|pl = 'Przekazanie produkcji z komórki';
									|tr = 'İmal edilen ürünlerin ambardan transferi'", LanguageCode);
			ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom") Then
				DocumentType = NStr("vi = 'Chuyển nguyên vật liệu vào kho tại xưởng';
									|ru = 'Передача материалов в кладовую';
									|en = 'Transfer of materials to shop floor stockroom'; fa = 'Transfer of materials to shop floor stockroom';
									|it = 'Consegna dei materiali al deposito';
									|pl = 'Przekazanie materiałów do komórki';
									|tr = 'Malzemelerin ambara transferi'", LanguageCode);
			ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom") Then
				DocumentType = NStr("vi = 'Trả lại nguyên vật liệu từ kho';
									|ru = 'Возврат материалов из кладовой';
									|en = 'Return of materials from shop floor stockroom'; fa = 'Return of materials from shop floor stockroom';
									|it = 'Reso di materiali dal deposito';
									|pl = 'Zwrot materiałów z komórki';
									|tr = 'Malzemelerin ambardan iadesi'", LanguageCode);
			ElsIf  BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProducts") Then
				DocumentType = NStr("vi = 'Điều chuyển bán thành phẩm';
									|ru = 'Перемещение полуфабрикатов';
									|en = 'Transfer of semi-finished products'; fa = 'انتقال محصولات نیمه‌ساخته';
									|it = 'Trasferimento dei prodotti semilavorati';
									|pl = 'Przemieszczenie półproduktów';
									|tr = 'Yarı mamul ürün transferi'", LanguageCode);
			ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices") Then
				DocumentType = NStr("vi = 'Điều chuyển bán thành phẩm';
									|ru = 'Перемещение полуфабрикатов';
									|en = 'Transfer of semi-finished products'; fa = 'انتقال محصولات نیمه‌ساخته';
									|it = 'Trasferimento dei prodotti semilavorati';
									|pl = 'Przemieszczenie półproduktów';
									|tr = 'Yarı mamul ürün transferi'", LanguageCode);
			EndIf;
			
		ElsIf TypeOf(Lot) = Type("DocumentRef.InventoryTransfer") Then
			DocumentType = NStr("ru = 'Перемещение товаров';
								|vi = 'Goods transfer';
								|en = 'Goods transfer'; fa = 'انتقال کالا';
								|it = 'Trasferimento delle merci';
								|pl = 'Przemieszczenie towarów';
								|tr = 'Mal transferi'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			DocumentType = NStr("vi = 'Tiếp nhận hàng hóa tại kho';
								|ru = 'Поступление товаров на склад';
								|en = 'Warehouse receipt'; fa = 'دریافت انبار';
								|it = 'Arrivodi merci in magazzino';
								|pl = 'Wpływ towaru do magazynu';
								|tr = 'Ambara ürün tahsilatı'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
			
			If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
				DocumentType = NStr("vi = 'Trả lại từ bên cho thuê kho';
									|ru = 'Возврат от хранителя';
									|en = 'VMI pick-up'; fa = 'برداشت VMI';
									|it = 'Restituzione dal depositario';
									|pl = 'Zwrot od opiekuna';
									|tr = 'VMI teslimi'", LanguageCode);
			ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
				DocumentType = NStr("vi = 'Nhận hàng ký gửi bị trả lại';
									|ru = 'Возврат от комиссионера';
									|en = 'Consignment pick-up'; fa = 'برداشت امانی';
									|it = 'Reso dal commissionario';
									|pl = 'Zwrot od komisanta';
									|tr = 'Konsinye teslim alma'", LanguageCode);
			
			ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5") Then
				DocumentType = NStr("vi = 'Nhận hàng gia công bị trả lại';
									|ru = 'Возврат от переработчика';
									|en = 'Materials pick-up from subcontractor'; fa = 'تحویل‌گیری مواد از پیمانکار فرعی';
									|it = 'Restituzione da subfornitore';
									|pl = 'Zwrot od przetwórcy';
									|tr = 'Malzemelerin fason üreticiden geri alınması'", LanguageCode);
			ElsIf  BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5") Then
				DocumentType = NStr("vi = 'Tiếp nhận từ người nhận gia công';
									|ru = 'Поступление от переработчика';
									|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
									|it = 'Ricezione dal subfornitore';
									|pl = 'Wpływ od przetwórcy';
									|tr = 'Fason üreticiden gelen ürünleri teslim alma'", LanguageCode);
			
			EndIf;
			
		ElsIf TypeOf(Lot) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
			If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale") Then
				DocumentType = NStr("vi = 'Tiếp nhận để bảo quản và có quyền bán';
									|ru = 'Прием на хранение с правом продажи';
									|en = 'VMI procurement'; fa = 'تدارکات VMI';
									|it = 'Accettazione in deposito con diritto di vendita';
									|pl = 'Przyjęcie na przechowywanie z prawem sprzedaży';
									|tr = 'VMI tedariği'", LanguageCode);
			
			ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
				DocumentType = NStr("vi = 'Tiếp nhận từ người đặt gia công';
									|ru = 'Поступление от давальца';
									|en = 'Receipt from material provider'; fa = 'دریافت از تأمین‌کننده مواد';
									|it = 'Ricezione dall''addetto alla lavorazione';
									|pl = 'Wpływ od właściciela surowców';
									|tr = 'Mal girişi — Verilen fason hizmetleri'", LanguageCode);
			
			EndIf;
			
		ElsIf TypeOf(Lot) = Type("DocumentRef.VendorInvoice") Then
			DocumentType = NStr("vi = 'Mua hàng hóa và dịch vụ';
								|ru = 'Приобретение товаров и услуг';
								|en = 'Vendor invoice'; fa = 'فاکتور تأمین‌کننده';
								|it = 'Acquisti di beni e servizi';
								|pl = 'Nabycie towarów i usług';
								|tr = 'Satın alma faturası'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.BackflushProduction") Then
			DocumentType = NStr("vi = 'Sản xuất không có đơn hàng';
								|ru = 'Производство без заказа';
								|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
								|it = 'Produzione senza ordine';
								|pl = 'Produkcja bez zamówień';
								|tr = 'Geriye dönük üretim'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.OtherGoodsRecordingAsReceived") Then
			DocumentType = NStr("vi = 'Ghi tăng khác';
								|ru = 'Прочее оприходование товаров';
								|en = 'Other receipt of goods'; fa = 'سایر دریافت‌های کالا';
								|it = 'Altra registrazione in contabilità delle merci';
								|pl = 'Inne rejestrowanie towarów';
								|tr = 'Diğer ürünlerin envantere girişi'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.AssemblyFromComponents") Then
			DocumentType = NStr("vi = 'Đóng bộ (tách bộ) hàng hóa';
								|ru = 'Сборка (разборка) товаров';
								|en = 'Product kitting'; fa = 'کیت‌سازی محصول';
								|it = 'Assemblaggio (disassemblaggio) di merci';
								|pl = 'Montaż (demontaż) towarów';
								|tr = 'Ürünlerin montajı (demontajı)'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.ProductionStage2_2") Then
			DocumentType = NStr("ru = 'Этап производства';
								|vi = 'Production stage';
								|en = 'Production stage'; fa = 'مرحله تولید';
								|it = 'Fase di produzione';
								|pl = 'Etap produkcji';
								|tr = 'Üretim aşaması'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.RequestForGoodsQualityControl") Then
			DocumentType = NStr("ru = 'Заявка на контроль качества';
								|vi = 'Request for quality control';
								|en = 'Request for quality control'; fa = 'Request for quality control';
								|it = 'Request for quality control';
								|pl = 'Request for quality control';
								|tr = 'Kalite kontrol talebi'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.PurchaseOrder") Then
			DocumentType = NStr("ru = 'Заказ поставщику';
								|vi = 'Purchase order';
								|en = 'Purchase order'; fa = 'سفارش خرید';
								|it = 'Ordine al fornitore';
								|pl = 'Zamówienie do dostawcy';
								|tr = 'Satın alma siparişi'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			DocumentType = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
								|ru = 'Заявка на возврат товаров от клиента';
								|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
								|it = 'Richiesta di reso della merce dal cliente';
								|pl = 'Wniosek o zwrot towarów od klienta';
								|tr = 'Müşteriden mal iade talebi'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
			DocumentType = NStr("vi = 'Đơn hàng đóng bộ (tách bộ)';
								|ru = 'Заказ на сборку (разборку)';
								|en = 'Kitting order'; fa = 'سفارش کیت‌سازی';
								|it = 'Ordine di assemblaggio/disassemblaggio';
								|pl = 'Zamówienie na montaż';
								|tr = 'Montaj emri (demontaj)'", LanguageCode);
		ElsIf TypeOf(Lot) = Type("DocumentRef.TransferOrder") Then
			DocumentType = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
								|ru = 'Заказ на перемещение';
								|en = 'Transfer order'; fa = 'سفارش انتقال';
								|it = 'Ordine di trasferimento';
								|pl = 'Zamówienie na przesunięcie';
								|tr = 'Transfer emri'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.SubcontractOrder2_5") Then
			DocumentType = NStr("ru = 'Заказ переработчику';
								|vi = 'Subcontracting purchase order';
								|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
								|it = 'Ordine al subfornitore';
								|pl = 'Zamówienie do przetwórcy';
								|tr = 'Fason satın alma siparişi'", LanguageCode);
		
		ElsIf TypeOf(Lot) = Type("DocumentRef.MaterialProviderOrder2_5") Then
			DocumentType = NStr("ru = 'Заказ давальца';
								|vi = 'Subcontracting sales order';
								|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
								|it = 'Ordine del committente';
								|pl = 'Zamówienie dostawcy';
								|tr = 'Tedarikçi siparişi'", LanguageCode);
			
		EndIf;
		
		Presentation = NStr("vi = '%1 %2 ngày %3';
							|ru = '%1 %2 от %3';
							|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
							|it = '%1 %2 del %3';
							|pl = '%1 %2 z dnia %3';
							|tr = '%3 tarihli %1 %2'", LanguageCode);
		Presentation = StrTemplate(Presentation,
			DocumentType,
			Attributes.ReceiptDocumentNumber,
			Format(Attributes.DateOfReceiptDocument, "DLF=D;"));
		
	ElsIf ValueIsFilled(Attributes.Contract) Then // Lot reference - Contract
		
		Presentation = NStr("ru = 'Договор: %1';
							|vi = 'Contract: %1';
							|en = 'Contract: %1'; fa = 'Contract: %1';
							|it = 'Contratto: %1';
							|pl = 'Kontrakt: %1';
							|tr = 'Sözleşme: %1'", LanguageCode);
		Presentation = StrTemplate(Presentation, Attributes.Contract);
		
	EndIf;
	
	Return Presentation;
	
EndFunction

// The structure of parameters for filling in the tabular part "Goods" of the workplace of the Quality control department.
// Returns:
//  Structure - structure with fields:
//   * CompositionSettings - DataCompositionSettings - customize the layout data
//   * Filter - Structure - structure with fields:
//      ** Warehouse - CatalogRef.Warehouses, Undefined - selection by warehouse.
//      ** Products - CatalogRef.Products, Undefined - selection by nomenclature.
//      ** Purpose - CatalogRef.Assignments, Undefined - selection by appointment.
//      ** ApplicationFormalized - Boolean, Undefined - selection for displaying only applications or non-applications.
Function FillingParametersOfItemsForQualityControl() Export
	
	FillParameters = New Structure();
	FilterFields = New Structure();
	FilterFields.Insert("Warehouse");
	FilterFields.Insert("Products");
	FilterFields.Insert("Purpose");
	FilterFields.Insert("ApplicationFormalized");
	FillParameters.Insert("Filter", FilterFields);
	FillParameters.Insert("CompositionSettings", New DataCompositionSettings);
	Return FillParameters;
	
EndFunction

// A structure constructor for Transferring data from filling out an application for quality control of goods to a document form.
// Returns:
//  Structure - structure with fields:
//   * ReasonForGoodsLock - CatalogRef.GoodsLockReasons
Function NewDataOnFillingOutApplicationForQualityControlOfGoods() Export
	
	Result = New Structure();
	Result.Insert("ReasonForGoodsLock", PredefinedValue("Catalog.GoodsLockReasons.EmptyRef"));
	Return Result;
	
EndFunction

#EndRegion