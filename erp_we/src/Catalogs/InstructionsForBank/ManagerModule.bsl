#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure FillInPredefinedElements() Export
	
	InstructionTable = ListOfInstructions();
	
	For Each TableRow In InstructionTable Do
		CatalogItem = FindByCode(TableRow.Code);
		If Not ValueIsFilled(CatalogItem) Then
			NewItem = CreateItem();
			FillPropertyValues(NewItem, TableRow);
			NewItem.LongDesc = TableRow.Description;
			InfobaseUpdate.WriteData(NewItem);
		EndIf;
	EndDo;
	
EndProcedure

Function ListOfInstructions()
	
	Table = New ValueTable();
	
	AddColumns(Table, "Code, CannotBeUsedTogether, Description");
	// =================================================================================================================
	AddRecord(Table, "SDVA", "CHQB,HOLD",                NStr("vi = 'Tiền phải được chuyển cho khách hàng thụ hưởng vào cùng ngày chuyển đổi ngoại tệ';
																|ru = 'Средства должны быть зачислены клиенту бенефициару той же датой валютирования';
																|en = 'Cash must be deposited to the beneficiary on the same valuation date'; fa = 'Cash must be deposited to the beneficiary on the same valuation date';
																|it = 'Gli importi devono essere accreditati al cliente beneficiario nella stessa data di valuta';
																|pl = 'Środki powinny być przelane klientowi beneficjentowi z tą samą datą walutowania ';
																|tr = 'Fonlar aynı valör tarihinde lehtar müşteriye transfer edilmelidir'"));
	AddRecord(Table, "INTC", "CHQB,HOLD",                NStr("vi = 'Thanh toán mang tính chất nội bộ công ty, tức là việc chuyển tiền giữa hai công ty thuộc cùng một nhóm (ví dụ: giữa một chi nhánh và một doanh nghiệp mẹ)';
																|ru = 'Платеж является внутрикорпоративным, то есть перевод средств между двумя компаниями, принадлежащими к одной группе (например, между филиалом и головной организацией)';
																|en = 'It is an in-house payment. Cash is transferred between two companies of the same group (for example, between the branch office and the parent company)'; fa = 'It is an in-house payment. Cash is transferred between two companies of the same group (for example, between the branch office and the parent company)';
																|it = 'Il pagamento risulta interno, dunque il trasferimento di fondi avviene tra due aziende appartenenti allo stesso gruppo (ad esempio, tra filiale e azienda madre)';
																|pl = 'Płatność jest wewnątrzkorporacyjną, to jest przelew środków między dwoma firmami, należącymi do jednej grupy (na przykład, między filią a firmą główną)';
																|tr = 'Ödeme kurum içidir, yani aynı gruba ait iki şirket arasında (örneğin bir şube ile bir ana iş yeri arasında) fon transferidir'"));
	AddRecord(Table, "REPA", "CHQB,CORT,HOLD",           NStr("vi = 'Khoản thanh toán có một liên kết được liên kết với một khoản thanh toán điện tử (e-Payments), mà khách hàng thanh toán đã gửi cho người thụ hưởng bằng hệ thống giao tiếp điện tử, liên kết dành cho ngân hàng của người thụ hưởng';
																|ru = 'Платеж имеет связанную ссылку на электронный платеж (e-Payments), который клиент-плательщик направил бенефициару с использованием электронных систем связи, ссылка предназначена для банка бенефициара';
																|en = 'The payment has a link to an electronic payment (e-Payments), which the payer sent to the beneficiary using electronic communication systems. The link is for the beneficiary''s bank'; fa = 'The payment has a link to an electronic payment (e-Payments), which the payer sent to the beneficiary using electronic communication systems. The link is for the beneficiary''s bank';
																|it = 'Il pagamento presenta un collegamento allegato per il pagamento elettronico (e-Payments), inviato al beneficiario da parte del cliente pagante tramite collegamento di sistemi elettronici, il collegamento è previsto per la banca del beneficiario';
																|pl = 'Płatność ma powiązany link do płatności elektronicznej (e-Payments), który klient-płatnik wysłał do beneficjenta za pomocą systemów łączności elektronicznej, link jest przeznaczony dla banku beneficjenta';
																|tr = 'Ödeme, ödemeyi yapan müşteri tarafından elektronik iletişim sistemlerini kullanarak alıcıya gönderilen bir elektronik ödemeye (e-Ödemeler) ilişkin bir bağlantıya sahiptir, bağlantı alıcının bankasına yöneliktir'"));
	AddRecord(Table, "CORT", "CHQB,HOLD,REPA",           NStr("vi = 'Thanh toán cho một giao dịch (cho một giao dịch ngoại hối, cho một giao dịch chứng khoán)';
																|ru = 'Оплата по сделке (по форексной сделке, по сделке с ценными бумагами)';
																|en = 'Transaction payment (FX transaction, security transaction)'; fa = 'Transaction payment (FX transaction, security transaction)';
																|it = 'Pagamento per transazione (transazione forex, transazione per titoli)';
																|pl = 'Opłata w ramach transakcji (w ramach transakcji Forex, w ramach transakcji z walorami)';
																|tr = 'Satış fırsatı kapsamında ödeme (forex satış fırsatı kapsamında, menkul kıymetlerle satış fırsatı kapsamında)'"));
	AddRecord(Table, "HOLD", "CHQB,CORT,INTC,REPA,SDVA", NStr("vi = 'Thanh toán khi xuất trình giấy tờ tùy thân của khách hàng của người thụ hưởng';
																|ru = 'Оплата по предъявлению документа, удостоверяющего личность клиента бенефициара';
																|en = 'Payment upon presentation of the beneficiary''s identity document'; fa = 'Payment upon presentation of the beneficiary''s identity document';
																|it = 'Pagamento per presentazione di documento di identità del cliente beneficiario';
																|pl = 'Płatność po przedstawieniu dokumentu tożsamości klienta beneficjenta';
																|tr = 'Alıcı müşterinin kimlik belgesinin ibrazı üzerine ödeme'"));
	AddRecord(Table, "CHQB", "CORT,HOLD,INTC,REPA,SDVA", NStr("vi = 'Việc thanh toán cho khách hàng, cho người thụ hưởng chỉ được thực hiện bằng séc';
																|ru = 'Оплата клиенту бенефициару должна быть произведена только чеком';
																|en = 'Payment to the beneficiary must be made by check only'; fa = 'Payment to the beneficiary must be made by check only';
																|it = 'Il pagamento al cliente beneficiario deve essere effettuato esclusivamente tramite bonifico';
																|pl = 'Opłata klientowi beneficjentowi powinna być przeprowadzona tylko za pomocą czeku';
																|tr = 'Lehtar müşteriye ödeme yalnızca çekle yapılmalıdır'"));
	AddRecord(Table, "PHOB", "TELB",                     NStr("vi = 'Yêu cầu thông báo / liên hệ với người thụ hưởng (trường 59a) về việc nhận tiền qua điện thoại';
																|ru = 'Просьба известить/связаться с бенефициаром (поле 59a) о поступлении средств по телефону';
																|en = 'Notify/contact the beneficiary (59a field) of cash receipt by phone'; fa = 'Notify/contact the beneficiary (59a field) of cash receipt by phone';
																|it = 'Richiesta di notifica/collegamento con il beneficiario (campo 59a) circa la ricezione dei fondi per telefono';
																|pl = 'Prośba o powiadomienie/skontaktowanie się z beneficjentem (pole 59a) o wpływie środków pieniężnych za pomocą telefonu';
																|tr = 'Fonların alındığını alıcı ile (alan 59a) telefonla bilgilendirme/irtibat kurma talebi'"));
	AddRecord(Table, "TELB", "PHOB",                     NStr("vi = 'Yêu cầu thông báo/liên hệ với người thụ hưởng (trường 59a) về việc nhận tiền bằng phương tiện giao tiếp điện tử hiệu quả nhất';
																|ru = 'Просьба известить/связаться с бенефициаром (поле 59a) о поступлении средств по наиболее эффективному средству электронной связи';
																|en = 'Notify/contact the beneficiary (59a field) of cash receipt by the most efficient means of electronic communication'; fa = 'Notify/contact the beneficiary (59a field) of cash receipt by the most efficient means of electronic communication';
																|it = 'Richiesta di notifica/collegamento con il beneficiario (campo 59a) circa la ricezione dei fondi tramite metodo di collegamento elettronico più efficace';
																|pl = 'Prośba o powiadomienie/skontaktowanie się z beneficjentem (pole 59a) o wpływie środków pieniężnych za pomocą najbardziej efektywnego środka połączenia elektronicznego';
																|tr = 'Daha verimli elektronik iletişim araçları aracılığıyla fonların alındığını alıcı ile (kutu 59a) bilgilendirme/iletişime geçme talebi'"));
	AddRecord(Table, "PHON", "TELE",                     NStr("vi = 'Yêu cầu thông báo cho ngân hàng của người thụ hưởng (trường 57a) về việc nhận tiền qua điện thoại';
																|ru = 'Просьба известить банк бенефициара (поле 57а) о поступлении средств по телефону';
																|en = 'Notify the beneficiary (57a field) of cash receipt by phone'; fa = 'Notify the beneficiary (57a field) of cash receipt by phone';
																|it = 'Richiesta di notifica alla banca del beneficiario (campo 57a) circa la ricezione dei fondi per telefono';
																|pl = 'Prośba o powiadomienie banku beneficjenta (pole 57a) o wpływie środków pieniężnych za pomocą telefonu';
																|tr = 'Fonların alındığını alıcının bankasına (alan 57a) telefonla bildirme talebi'"));
	AddRecord(Table, "TELE", "PHON",                     NStr("vi = 'Yêu cầu thông báo cho ngân hàng của người thụ hưởng (trường 57a) về việc nhận tiền bằng phương tiện giao tiếp điện tử hiệu quả nhất';
																|ru = 'Просьба известить банк бенефициара (поле 57а) о поступлении средств по наиболее эффективному средству электронной связи';
																|en = 'Notify the beneficiary''s bank (57a field) of cash receipt by the most efficient means of electronic communication'; fa = 'Notify the beneficiary''s bank (57a field) of cash receipt by the most efficient means of electronic communication';
																|it = 'Richiesta di notifica alla banca del beneficiario (campo 57a) circa la ricezione dei fondi tramite metodo di collegamento elettronico più efficace';
																|pl = 'Prośba o powiadomienie banku beneficjenta (pole 57a) o wpływie środków pieniężnych za pomocą najbardziej efektywnego środka połączenia elektronicznego';
																|tr = 'Fonların alındığını alıcının bankasına (alan 57a) daha etkili elektronik iletişim araçları aracılığıyla bildirme talebi'"));
	AddRecord(Table, "PHOI", "TELI",                     NStr("vi = 'Yêu cầu thông báo cho ngân hàng trung gian (trường 56a) về việc nhận tiền qua điện thoại';
																|ru = 'Просьба известить банк-посредник (поле 56а) о поступлении средств по телефону';
																|en = 'Notify the intermediary bank (56a field) of cash receipt by phone'; fa = 'Notify the intermediary bank (56a field) of cash receipt by phone';
																|it = 'Richiesta di notifica alla banca intermediaria (campo 56a) circa la ricezione dei fondi per telefono';
																|pl = 'Prośba o powiadomienie banku pośredniczącego (pole 56a) o wpływie środków pieniężnych za pomocą telefonu';
																|tr = 'Fonların alındığını aracı bankaya (alan 56a) telefonla bildirme talebi'"));
	AddRecord(Table, "TELI", "PHOI",                     NStr("vi = 'Yêu cầu thông báo cho ngân hàng trung gian (trường 56a) về việc nhận tiền thông qua các phương tiện giao tiếp điện tử hiệu quả nhất';
																|ru = 'Просьба известить банк-посредник (поле 56а) о поступлении средств по наиболее эффективному средству электронной связи';
																|en = 'Notify the intermediary bank (56a field) of cash receipt by the most effective means of electronic communication'; fa = 'Notify the intermediary bank (56a field) of cash receipt by the most effective means of electronic communication';
																|it = 'Richiesta di notifica alla banca intermediaria (campo 56a) circa la ricezione tramite metodo di collegamento elettronico più efficace';
																|pl = 'Prośba o powiadomienie banku pośredniczącego (pole 56a) o wpływie środków pieniężnych za pomocą najbardziej efektywnego środka połączenia elektronicznego';
																|tr = 'Aracı bankaya (alan 56a) fonların en verimli elektronik iletişim araçları aracılığıyla alındığını bildirme talebi'"));
	
	Return Table
	
EndFunction

Procedure AddColumns(Table, Columns)
	
	TMCommonUse.AddColumns(Table, Columns);
	
EndProcedure

Procedure AddRecord(Table, Value1, Value2, Value3)
	
	TMCommonUse.AddRecord(Table, Value1, Value2, Value3);

EndProcedure

#EndRegion

#EndIf