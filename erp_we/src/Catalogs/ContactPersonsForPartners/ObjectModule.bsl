#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Description") Then
		// creating from an interaction based on a participant's description
			Description = FillingData.Description;
		ElsIf FillingData.Property("LongDesc") Then
			Description = FillingData.LongDesc;
		EndIf;
		If FillingData.Property("Owner") Then
			Owner = FillingData.Owner;
		EndIf
	ElsIf TypeOf(FillingData) = Type("CatalogRef.Partners") Then
		Owner = FillingData;
	ElsIf TypeOf(FillingData) = Type("CatalogRef.Persons") Then
		Person = FillingData;
	EndIf;
	
	// specify the author of the information
	If Not ValueIsFilled(Author) Then
		Author = Users.AuthorizedUser();
	EndIf;
	
	// specify the date of registration of the connection
	If Not ValueIsFilled(RelationRegistrationDate) Then
		RelationRegistrationDate = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
	
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("Owner");
		
		If Not ValueIsFilled(Owner) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Đối tác""';
							|ru = 'Поле ""Контрагент"" не заполнено';
							|en = '""Counterparty"" is not filled in'; fa = '""Counterparty"" is not filled in';
							|it = 'Il campo ""Contraente"" non è compilato';
							|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
							|tr = '""Cari hesap"" alanı doldurulmadı'");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				"Owner",
				,
				Cancel);
		EndIf;
		
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	EndIf;
	
EndProcedure

#EndRegion

#EndIf