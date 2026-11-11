#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the text of the hint for the mode of generating expense orders.
//
// Parameters:
//  GoodsIssueNoteGenerationMode	 - EnumRef.GoodsIssueNoteGenerationModes - mode for generating
//  spending orders.
// 
// Returns:
//  String - a hint on the mode of formation of spending orders.
//
Function FormationModeHint(GoodsIssueNoteGenerationMode) Export
	
	UsedDelivery20 =
		(GetFunctionalOption("UseDeliveryManagement")
			And GetFunctionalOption("NotUseDeliveryManagement25"));
	
	If GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.Automatically Then
		
		If UsedDelivery20 Then
			
			ToolTipText = NStr("vi = 'Phiếu xuất nhập được lập và lập lại tự động sau khi ghi chứng từ sau: đơn hàng, phiếu xuất nhập, nhiệm vụ vận chuyển.';
								|ru = 'Ордера формируются и переформировываются автоматически после записи документов, влияющих на их формирование: заказов, накладных, заданий на перевозку.';
								|en = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, itineraries.'; fa = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, itineraries.';
								|it = 'I mandati vengono generati e rigenerati automaticamente dopo il salvataggio dei documenti che incidono sulla loro generazione: ordini, bolle, incarichi di trasporto.';
								|pl = 'Zlecenia są formowane i przeformowane automatycznie po zapisie dokumentów, które mają wpływ na ich formowanie: zamówienia, faktury, zlecenia na transport.';
								|tr = 'Emirler, oluşumlarını etkileyen belgeler kaydedildikten sonra otomatik olarak oluşturulur ve yeniden biçimlendirilir: siparişler, irsaliyeler, taşıma planları.'");
			
		Else
			
			ToolTipText = NStr("ru = 'Ордера формируются и переформировываются автоматически после записи документов, влияющих на их формирование: заказов, накладных, рейсов.';
								|vi = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, and trips.';
								|en = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, and trips.'; fa = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, and trips.';
								|it = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, and trips.';
								|pl = 'Goods issues are created and recreated automatically after the documents that affect their creation are saved, such as: orders, invoices, and trips.';
								|tr = 'Emirler, oluşumlarını etkileyen belgeler kaydedildikten sonra otomatik olarak oluşturulur ve yeniden biçimlendirilir: siparişler, irsaliyeler, seferler.'");
			
		EndIf;
		
	ElsIf GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.ByManager Then
		
		If UsedDelivery20 Then
			
			ToolTipText = NStr("ru = 'Менеджер инициирует формирование и переформирование расходных ордеров из списков распоряжений на отгрузку (т.е. из списков заказов и накладных). При использовании доставки ордера формирует менеджер по доставке в целом по заданию на перевозку.';
								|vi = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (i.e. from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues for the whole itinerary.';
								|en = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (i.e. from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues for the whole itinerary.'; fa = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (i.e. from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues for the whole itinerary.';
								|it = 'Lo specialista avvia la generazione e rigenerazione dei mandati di pagamento dall''elenco delle disposizioni di spedizione (ovvero dall''elenco degli ordini e delle fatture). In caso di utilizzo di consegna i mandati vengono emessi dallo specialista di consegna in base all''incarico di trasporto in generale.';
								|pl = 'Menedżer inicjuje formowanie i przeformowanie zleceń wydania z list zamówień wysyłki (tj. z listy zamówień i faktur). Podczas korzystania z wysyłki zlecenia tworzy menedżer dostawy w całości wg zlecenia na przewóz.';
								|tr = 'Yönetici, sevkiyat siparişleri listelerinden (yani sipariş ve irsaliye listelerinden) ambar çıkış fişlerinin oluşturulmasını ve yeniden oluşturulmasını başlatır. Teslimat kullanılıyorsa, emirler teslimat yöneticisi tarafından tüm taşıma planı için oluşturulur.'");
			
		Else
			
			ToolTipText = NStr("ru = 'Менеджер инициирует формирование и переформирование расходных ордеров из списков распоряжений на отгрузку (т.е. из списков заказов и накладных). При использовании доставки менеджер по доставке формирует ордера по рейсам.';
								|vi = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues by trip.';
								|en = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues by trip.'; fa = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues by trip.';
								|it = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues by trip.';
								|pl = 'Employee initiates generation and regeneration of goods issues from shipment reference lists (from the lists of orders and invoices). If delivery is used, the delivery officer generates goods issues by trip.';
								|tr = 'Yönetici, sevkiyat talimatları listelerinden (yani sipariş ve irsaliye listelerinden) ambar çıkış emirlerinin oluşturulmasını ve yeniden oluşturulmasını başlatır. Teslimat kullanıldığında, teslimat yöneticisi seferlere göre emirleri oluşturur.'");
			
		EndIf;
		
	ElsIf GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.ByWarehouseman Then
		
		ToolTipText = NStr("ru = 'Кладовщик вручную инициирует формирование и переформирование расходных ордеров по распоряжениям на отгрузку в рабочем месте ""Отгрузка"".';
							|vi = 'Warehouse keeper manually starts creating and recreating goods issues under shipment references in the ""Shipment"" workplace.';
							|en = 'Warehouse keeper manually starts creating and recreating goods issues under shipment references in the ""Shipment"" workplace.'; fa = 'Warehouse keeper manually starts creating and recreating goods issues under shipment references in the ""Shipment"" workplace.';
							|it = 'Il magazziniere avvia la generazione e rigenerazione dei mandati di pagamento manualmente in base alle disposizioni di spedizione nella postazione di lavoro ""Spedizione"".';
							|pl = 'Prowadzący zapasy magazynu ręcznie inicjuje formowanie i przeformowanie kolejności zleceń wydania dla zamówień wysyłkowych w miejscu pracy ""Wysyłka"".';
							|tr = 'Ambar sorumlusu, ""Sevkiyat"" çalışma alanında sevkiyat siparişleri için ambar çıkış fişlerinin oluşturulmasını ve yeniden oluşturulmasını manuel olarak başlatır.'");
		
	Else
		
		ToolTipText = NStr("vi = 'Xác định người khởi xướng việc lập phiếu xuất kho.';
							|ru = 'Определяет инициатора формирования расходных ордеров.';
							|en = 'Determines an initiator of goods issue note generation.'; fa = 'Determines an initiator of goods issue note generation.';
							|it = 'Stabilisce un promotore della generazione dei mandati di pagamento.';
							|pl = 'Definiuje inicjatora formowania zleceń wydatków.';
							|tr = 'Ambar çıkış fişlerini oluşturma işlemini başlatan kişiyi tanımlıyor.'");
		
	EndIf;
	
	Return ToolTipText;
	
EndFunction

#EndRegion

#EndIf