#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = UsersClientServer.CurrentUser();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible         = UsersClientServer.CurrentUser();
	StartDate            = Undefined;
	EndDate         = Undefined;
	PlannedStartDate    = Undefined;
	PlannedEndDate = Undefined;
	Completed             = False;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.SetActiveFlag(Ref, (Not Completed) And (Not DeletionMark));
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If PlannedEndDate < PlannedStartDate
		And ValueIsFilled(PlannedEndDate) Then
		
		MessageText = NStr("vi = 'Ngày kết thúc dự kiến ​​không được nhỏ hơn ngày bắt đầu dự kiến.';
							|ru = 'Плановая дата окончания не должна быть меньше чем плановая дата начала.';
							|en = 'Planned end date cannot be less than planned start date.'; fa = 'Planned end date cannot be less than planned start date.';
							|it = 'La data di fine pianificata non deve essere inferiore alla data di inizio pianificata.';
							|pl = 'Planowana data zakończenia nie może być mniejsza niż planowana data rozpoczęcia.';
							|tr = 'Planlanan bitiş tarihi, planlanan başlangıç ​​tarihinden önce olmamalıdır.'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "PlannedEndDate",, Cancel);
		
	EndIf;
	
	If EndDate < StartDate
		And ValueIsFilled(EndDate) Then
		
		MessageText = NStr("vi = 'Ngày kết thúc thực tế không được nhỏ hơn ngày bắt đầu thực tế.';
							|ru = 'Фактическая дата окончания не должна быть меньше чем фактическая дата начала.';
							|en = 'Actual end date cannot be less than actual start date.'; fa = 'Actual end date cannot be less than actual start date.';
							|it = 'La data di fine effettiva non deve essere inferiore alla data di inizio effettiva.';
							|pl = 'Faktyczna data zakończenia nie powinna być mniejsza niż faktyczna data rozpoczęcia.';
							|tr = 'Fiilî bitiş tarihi, fiilî başlangıç ​​tarihinden önce olmamalıdır.'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "EndDate",, Cancel);
		
	EndIf;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		NotCheckedAttributeArray.Add("PartnersAndContactPersons.Partner");
		
		For Each PartnerLine In PartnersAndContactPersons Do
			
			If Not ValueIsFilled(PartnerLine.Partner) Then
				
				MessageText = StrTemplate(NStr("vi = 'Chưa điền cột ""Đối tác"" trong dòng %1 của phần bảng ""Đối tác và người liên hệ""';
												|ru = 'Не заполнена колонка ""Контрагент"" в строке %1 табличной части ""Контрагенты и контактные лица""';
												|en = 'Column ""Counterparty"" in line %1 of the ""Counterparties and contact persons"" table is not filled in'; fa = 'Column ""Counterparty"" in line %1 of the ""Counterparties and contact persons"" table is not filled in';
												|it = 'La colonna ""Contraente"" non è compilata nella riga %1 della parte tabulare ""Contraenti e persone di riferimento""';
												|pl = 'Nie wypełniona kolumna ""Kontrahent"" w wierszu %1 części tabelarycznej ""Kontrahenci i osoby kontaktowe""';
												|tr = '""Cari Hesaplar ve İlgili Kişiler"" tablo bölümünün %1 satırındaki ""Cari Hesap"" sütunu doldurulmadı'"), PartnerLine.LineNumber);
				PathToTop = CommonClientServer.PathToTabularSection("PartnersAndContactPersons", PartnerLine.LineNumber, "Partner");
				
				CommonClientServer.MessageToUser(MessageText, ThisObject, PathToTop,, Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf