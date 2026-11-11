
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Not ValueIsFilled(Record.Author)
	 Or ValueIsFilled(Parameters.CopyingValue) Then
		Record.Author = Users.CurrentUser();
	EndIf;
	
	If Parameters.Property("Partner") Then
		Record.FirstPartner = Parameters.Partner;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	               ThisObject, "Partner1", NStr("vi = 'Đối tác thứ nhất';
												|ru = 'Первый контрагент';
												|en = 'The first counterparty'; fa = 'The first counterparty';
												|it = 'Primo contraente';
												|pl = 'Pierwszy kontrahent';
												|tr = 'İlk cari hesap'"));
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	               ThisObject, "Partner2", NStr("vi = 'Đối tác thứ hai';
												|ru = 'Второй контрагент';
												|en = 'The second counterparty'; fa = 'The second counterparty';
												|it = 'Secondo contraente';
												|pl = 'Drugi kontrahent';
												|tr = 'İkinci cari hesap'"));
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	               ThisObject, "", NStr("vi = 'Quản hệ giữa các đối tác';
										|ru = 'Связь между контрагентами';
										|en = 'Connections between counterparties'; fa = 'Connections between counterparties';
										|it = 'Collegamento tra contraenti';
										|pl = 'Komunikacja między kontrahentami';
										|tr = 'Cari hesaplar arasındaki bağlantı'"));
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject)
	
	If Record.FirstPartner = Record.SecondPartner Then
		
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			MessageText = NStr("vi = 'Đối tác được chỉ ra trong liên kết không trùng nhau.';
								|ru = 'Контрагенты, указанные в связи не должны совпадать.';
								|en = 'Counterparties specified in the link cannot match.'; fa = 'Counterparties specified in the link cannot match.';
								|it = 'I contraenti indicati nel collegamento non devono coincidere.';
								|pl = 'Kontrahenci, wymienieni w połączeniu nie powinny być takie same.';
								|tr = 'Bağlantıda belirtilen cari hesaplar eşleşmemelidir.'");
		Else
			MessageText = NStr("vi = 'Bạn hàng được chỉ ra trong mối liên hệ không được phép trùng nhau.';
								|ru = 'Партнеры, указанные в связи не должны совпадать.';
								|en = 'Partners specified in the link should not match.'; fa = 'Partners specified in the link should not match.';
								|it = 'I partner indicati nel collegamento non devono coincidere.';
								|pl = 'Partnerzy, wymienieni w połączeniu nie powinny być takie same.';
								|tr = 'Bağlantıda belirtilen iş ortakları eşleşmemelidir.'");
		EndIf;
		
		CommonClientServer.MessageToUser(
		MessageText,
		,
		"FirstPartner",, Cancel);
		Cancel = True;
	EndIf;

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion
