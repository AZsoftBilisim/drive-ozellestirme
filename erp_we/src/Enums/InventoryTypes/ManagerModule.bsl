#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a collection of values for inventory types that do not require monitoring the Balance of item organizations.
//
// Returns:
//	Array of EnumRef.InventoryTypes - types of inventory that do not require monitoring the Balance
//												of item organizations.
//
Function NonControllingEntitiesInventoryTypes() Export
	
	InventoryTypes = New Array;
	InventoryTypes.Add(Enums.InventoryTypes.OwnGoodsInTransit);
	InventoryTypes.Add(Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery);
	InventoryTypes.Add(Enums.InventoryTypes.OperationService);
	InventoryTypes.Add(Enums.InventoryTypes.AgentService);
	InventoryTypes.Add(Enums.InventoryTypes.GoodsStoredWithRightOfSaleTransferred);
	
	Return InventoryTypes;
	
EndFunction

// Returns a collection of inventory type values to be monitored on organizations' Balances.
//
// Returns:
//	Array of EnumRef.InventoryTypes - types of stocks that need to be monitored on the Balances of organizations.
//
Function ControlledInventoryTypes() Export
	
	ControlledInventoryTypes = New Array;
	ControlledInventoryTypes.Add(Enums.InventoryTypes.OwnGoods);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.ConsignedGoods);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.Work_5);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.SubcontractorProducts);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	ControlledInventoryTypes.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	Return ControlledInventoryTypes;
	
EndFunction

// Returns a collection of inventory type values whose owners are not listed in the Business directory.
//
// Returns:
//	Array of EnumRef.InventoryTypes - inventory types whose owners are not listed in the Organization's Catalog.
//
Function InventoryTypesExternalOwner() Export
	
	InventoryTypesExternalOwner = New Array;
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.ConsignedGoods);
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.GoodsStoredWithRightOfSaleTransferred);
	InventoryTypesExternalOwner.Add(Enums.InventoryTypes.AgentService);
	
	Return InventoryTypesExternalOwner;
	
EndFunction

// Returns a collection of values of inventory types owned by our organization.
//
// Returns:
//	Array of EnumRef.InventoryTypes - types of inventory owned by our organization.
//
Function InventoryTypesOwn() Export
	
	InventoryTypesOwn = New Array();
	InventoryTypesOwn.Add(Enums.InventoryTypes.OwnGoods);
	InventoryTypesOwn.Add(Enums.InventoryTypes.OwnGoodsInTransit);
	InventoryTypesOwn.Add(Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery);
	InventoryTypesOwn.Add(Enums.InventoryTypes.OperationService);
	InventoryTypesOwn.Add(Enums.InventoryTypes.Work_5);
	InventoryTypesOwn.Add(Enums.InventoryTypes.SubcontractorProducts);
	Return InventoryTypesOwn;
	
EndFunction

// Returns a Presentation of the enumeration value.
//
// Parameters:
//	Value - EnumRef.InventoryTypes - the value for which the Presentation is returned.
//	LanguageCode - String - the language code.
//
// Returns:
//	String - representation of the enumeration value.
//
Function RepresentationInLanguage(Value, LanguageCode = Undefined) Export
	
	Presentation = "";
	
	If Value = Enums.InventoryTypes.OwnGoods Then
		Presentation = NStr("vi = 'Hàng hóa thuộc sở hữu';
							|ru = 'Собственный товар';
							|en = 'Own goods'; fa = 'کالای خودی';
							|it = 'Merce Propria';
							|pl = 'Towar własny';
							|tr = 'Yerel ürün'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.ConsignedGoods Then
		Presentation = NStr("vi = 'Hàng ký gửi';
							|ru = 'Комиссионный товар';
							|en = 'Consignment goods'; fa = 'کالای امانی';
							|it = 'Merce in conto vendita';
							|pl = 'Towar komisowy';
							|tr = 'Konsinye ürün'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.Work_5 Then
		Presentation = NStr("vi = 'Công việc';
							|ru = 'Работа';
							|en = 'Work'; fa = 'کار';
							|it = 'Работа';
							|pl = 'Work';
							|tr = 'İş'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.OperationService Then
		Presentation = NStr("vi = 'Công việc (Dịch vụ)';
							|ru = 'Работа (Услуга)';
							|en = 'Operation (Service)'; fa = 'عملیات (سرویس)';
							|it = 'Lavoro (servizio)';
							|pl = 'Praca (Usługa)';
							|tr = 'İş (Hizmet)'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.MaterialOfMaterialProvider Then
		Presentation = NStr("vi = 'Nguyên vật liệu của bên đặt gia công';
							|ru = 'Материал давальца';
							|en = 'Material of the material provider'; fa = 'مواد تأمین‌کننده مواد';
							|it = 'Materiale di fornitore di materiali';
							|pl = 'Materiał właściciela surowca';
							|tr = 'Tedarikçinin malzemesi'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider Then
		Presentation = NStr("vi = 'Bán thành phẩm của bên đặt gia công';
							|ru = 'Полуфабрикат давальца';
							|en = 'Semi-finished product of material provider'; fa = 'محصول نیمه‌ساخته تأمین‌کننده مواد';
							|it = 'Semilavorato del committente';
							|pl = 'Półprodukt właściciela surowca';
							|tr = 'Tedarikçinin yarı mamul ürünü'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.ProductsOfMaterialProvider Then
		Presentation = NStr("vi = 'Sản phẩm của bên đặt gia công';
							|ru = 'Продукция давальца';
							|en = 'Products of the material provider'; fa = 'محصولات تأمین‌کننده مواد';
							|it = 'Produzione del committente';
							|pl = 'Wiersze pozycji właściciela surowca';
							|tr = 'Tedarikçinin imal edilen ürünleri'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.AgentService Then
		Presentation = NStr("vi = 'Dịch vụ đại lý';
							|ru = 'Агентская услуга';
							|en = 'Agent service'; fa = 'خدمت عاملیت';
							|it = 'Servizio di agenzia';
							|pl = 'Usługa agencyjna';
							|tr = 'Ajans hizmeti'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
		Presentation = NStr("vi = 'Hàng hóa cất giữ có thể bán';
							|ru = 'Товар на хранении с правом продажи';
							|en = 'Goods at storage with the right of sale'; fa = 'کالای نزد انبار با حق فروش';
							|it = 'Merce in magazzino con diritto di vendita';
							|pl = 'Towar jest w przechowywaniu z prawem sprzedaży';
							|tr = 'Satış yetkisi olan depodaki ürün'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.OwnGoodsInTransit Then
		Presentation = NStr("vi = 'Hàng đang chuyển';
							|ru = 'Собственный товар в пути';
							|en = 'Own goods in transit'; fa = 'کالای خودی در راه';
							|it = 'Merce di proprietà in transito';
							|pl = 'Własny towar w drodze';
							|tr = 'Transit mallar'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery Then
		Presentation = NStr("vi = 'Hàng hóa sở hữu riêng khi giao hàng không có hóa đơn';
							|ru = 'Собственный товар по неотфактурованной поставке';
							|en = 'In-house goods received not invoiced'; fa = 'کالای داخلی دریافت‌شده بدون فاکتور';
							|it = 'Proprio prodotto dalla consegna non fatturata';
							|pl = 'Własny towar z tytułu dostawy niefakturowanej';
							|tr = 'Faturasız tedarik doğrultusunda yerel ürün'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.GoodsStoredWithRightOfSaleTransferred Then
		Presentation = NStr("vi = 'Hàng lưu kho có quyền bán đã được chuyển giao';
							|ru = 'Товар на хранении с правом продажи переданный';
							|en = 'The goods stored with the right of sale transferred'; fa = 'کالای نگهداری‌شده با حق فروش منتقل‌شده';
							|it = 'Merce in magazzino con diritto di vendita';
							|pl = 'Towar na przechowywaniu z prawem sprzedaży przekazany';
							|tr = 'Satış yetkisi devredilen depodaki ürün'", LanguageCode);
	ElsIf Value = Enums.InventoryTypes.SubcontractorProducts Then
		Presentation = NStr("vi = 'Sản phẩm của bên nhận gia công';
							|ru = 'Продукция переработчика';
							|en = 'Subcontractor products'; fa = 'محصولات پیمانکار فرعی';
							|it = 'Produzione elaboratore';
							|pl = 'Produkcja przetwórcy';
							|tr = 'Fason üreticinin imal edilen ürünleri'", LanguageCode);
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion

#EndIf
