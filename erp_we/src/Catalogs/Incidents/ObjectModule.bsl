#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If FillingData <> Undefined And TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Closed_") Then
			FillingData.Closed_ = False;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Author) And Not ValueIsFilled(Department) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Tác giả"" và ""Bộ phận"". Hãy điền một trong các trường này.';
							|ru = 'Не заполнены поля ""Автор"" и ""Подразделение"". Заполните одно из полей.';
							|en = 'The ""Author"" and ""Business unit"" fields are not filled. Fill one of the fields.'; fa = 'The ""Author"" and ""Business unit"" fields are not filled. Fill one of the fields.';
							|it = 'I campi ""Autore"" e ""Reparto"" non sono compilati. Compilare uno dei campi.';
							|pl = 'Nie wypełniono pola ""Autor"" i ""Dział"". Wypełnij jedno z pól.';
							|tr = '""Oluşturan"" ve ""Departman"" alanları doldurulmadı. Alanlardan birini doldur.'");
		Common.MessageToUser(
		MessageText,
		ThisObject,
		"Author",, Cancel);
	EndIf;
	
	If Not ValueIsFilled(Performer) And Not ValueIsFilled(AssigneeBusinessUnit) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Người thực hiện"" và ""Bộ phận thực hiện"". Hãy điền một trong các trường này.';
							|ru = 'Не заполнены поля ""Исполнитель"" и ""Подразделение исполнитель"". Заполните одно из полей.';
							|en = 'The ""Assignee"" and ""Business unit"" fields are not filled. Fill one of the fields.'; fa = 'The ""Assignee"" and ""Business unit"" fields are not filled. Fill one of the fields.';
							|it = 'I campi ""Esecutore"" e ""Reparto esecutore"" non sono compilati. Compilare uno dei campi.';
							|pl = 'Nie wypełniono pola ""Wykonawca"" i ""Dział wykonawca"". Wypełnij jedno z pól.';
							|tr = '""Atanan"" ve ""Atanan departman"" alanları doldurulmadı. Alanlardan birini doldur.'");
		Common.MessageToUser(
		MessageText,
		ThisObject,
		"Performer",, Cancel);
	EndIf;
	
	If Status = Enums.IncidentStatuses.Registered Then
		
		// The desired closing date cannot be earlier than the date the incident was created
		If ValueIsFilled(RequiredClosingDate) And RequiredClosingDate < ?(ValueIsFilled(RegistrationDate), RegistrationDate, CurrentSessionDate()) Then
			MessageText = NStr("vi = '""Ngày dự tính đóng"" không được sớm hơn ngày tạo sự cố';
								|ru = '""Желаемая дата закрытия"" должна быть не ранее даты создания инцидента';
								|en = '""Required closing date"" cannot be earlier than the incident creation date'; fa = '""Required closing date"" cannot be earlier than the incident creation date';
								|it = '""La data di chiusura preferibile"" non deve essere precedente alla data della creazione dell''incidente';
								|pl = '""Prognozowana data zamknięcia"" powinna być nie wcześniej niż data utworzenia incydentu';
								|tr = '""Arzu edilen kapanış tarihi"", olayın oluşturulduğu tarihten önce olmamalıdır'");
			Common.MessageToUser(
				MessageText,
				ThisObject,
				"RequiredClosingDate",, Cancel);
		EndIf;
		
	Else
		
		NotCheckedAttributeArray.Add("RequiredClosingDate");
		
	EndIf;
	
	If ValueIsFilled(Duplicate1) Then
		
		If Duplicate1 = Ref Then
			MessageText = NStr("vi = 'Đã chỉ ra sai giá trị trường ""Đây là sự cố trùng"" - sự cố liên kết đến chính nó.';
								|ru = 'Значение поля ""Это дубль инцидента"" указано неверно - инцидент ссылается сам на себя.';
								|en = '""This is an incident duplicate"" field value is incorrect: the incident refers to itself.'; fa = '""This is an incident duplicate"" field value is incorrect: the incident refers to itself.';
								|it = 'Il valore del campo ""È un doppione dell''incidente"" è indicato in modo errato - l''incidente è riferito a se stesso.';
								|pl = 'Wartość pola ""To jest duplikat incydentu"" jest podana niepoprawnie - incydent powołuje się sam na siebie.';
								|tr = '""Bu, olayın kopyasıdır"" alanının değeri yanlış belirtildi - olay kendisine atıfta bulunuyor.'");
			Common.MessageToUser(
			MessageText,
			ThisObject, "Duplicate1",, Cancel);
		EndIf;
	
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Status = Enums.IncidentStatuses.Registered Then
		If Not ValueIsFilled(RegistrationDate) Then 
			RegistrationDate = CurrentSessionDate();
		EndIf;
		If ValueIsFilled(ClosingDate) Then
			ClosingDate = Date(1,1,1);
		EndIf;
	EndIf;
	
	If Status = Enums.IncidentStatuses.Solved And Not ValueIsFilled(ClosingDate) Then
		ClosingDate = CurrentSessionDate();
	EndIf;

EndProcedure

Procedure OnCopy(CopiedObject)

	Author 			= Users.CurrentUser();
	Status			= Enums.IncidentStatuses.Registered;
	RegistrationDate	= Date(1,1,1);
	ClosingDate	= Date(1,1,1); 
	RequiredClosingDate = Date(1,1,1);
	Decision			= "";
	Duplicate1			= Catalogs.Incidents.EmptyRef();

EndProcedure

#EndRegion

#EndIf