#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
	
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("PartnerSRole1");
		NotCheckedAttributeArray.Add("PartnerSRole2");
		
		If Not ValueIsFilled(PartnerSRole1) Then
			ErrorText = NStr("vi = 'Chưa điền ""Vai trò của đối tác 1""';
							|ru = 'Не заполнена ""Роль контрагента 1""';
							|en = '""Counterparty role 1"" is required'; fa = '""Counterparty role 1"" is required';
							|it = '""Ruolo del contraente1"" non è compilato';
							|pl = 'Nie wypełniono pola ""Rola kontrahenta 1""';
							|tr = '""Cari hesap rolü 1"" doldurulmadı'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"PartnerSRole1",
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(PartnerSRole2) Then
			ErrorText = NStr("vi = 'Chưa điền ""Vai trò của đối tác 2""';
							|ru = 'Не заполнена ""Роль контрагента 2""';
							|en = '""Counterparty role 2"" is required'; fa = '""Counterparty role 2"" is required';
							|it = '""Ruolo del contraente 2"" non è compilato';
							|pl = 'Nie wypełniono pola ""Rola kontrahenta 2""';
							|tr = '""Cari hesap rolü 2"" doldurulmadı'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"PartnerSRole2",
				,
				Cancel);
		EndIf;
		
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	EndIf;
	
EndProcedure

#EndRegion

#EndIf