#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Description) Then
		If ThisNode Then
			Description = NStr("vi = 'Trung tâm';
								|ru = 'Центральный';
								|en = 'Central'; fa = 'Central';
								|it = 'Centrale';
								|pl = 'Centralny';
								|tr = 'Merkezi'");
		Else
			TextName = NStr("vi = '%User% (""1С:Đơn hàng"")';
							|ru = '%User% (""1С:Заказы"")';
							|en = '%User% (1C:Orders)'; fa = '%User% (1C:Orders)';
							|it = '%User% (""1C:Orders"")';
							|pl = '%User% (""1C:Orders"")';
							|tr = '%User% (""1C:Orders"")'");
			TextName = StrReplace(TextName, "%User%", TrimAll(User));
			Description = TextName;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Code) Then
		If ThisNode Then
			Code = "001";
		Else
			NewCode = TrimAll(User.UUID());
			CheckNewCode(NewCode, ThisObject.Ref, Cancel);
			If Cancel Then
				Message = NStr("vi = 'Đối với người sử dụng ""%User%"" đã tồn tại tùy chỉnh
				|nhưng vẫn chưa được sử dụng để đồng bộ dữ liệu với ứng dụng di động.
				|Hãy sử dụng tùy chỉnh đó để tùy chỉnh trao đổi dữ liệu.';
				|ru = 'Для пользователя ""%User%"" уже существует настройка,
				|которая еще не была задействована для синхронизации данных с мобильным приложением.
				|Используйте ее для настройки обмена данными.';
				|en = 'For user ""%User%"", there is a setting
				|that has not yet been used for data synchronization with the mobile application.
				|Use it, to configure data exchange.'; fa = 'For user ""%User%"", there is a setting
				|that has not yet been used for data synchronization with the mobile application.
				|Use it, to configure data exchange.';
				|it = 'Per l''utente ""%User%"" esiste già l''impostazione, 
				| la quale non è stata ancora utilizzata per sincronizzare i dati con l''app mobile.
				| Utilizzare per configurare lo scambio dati.';
				|pl = 'Dla użytkownika ""%User%"" już istnieje ustawienie,
				|które jeszcze nie zostało włączone do synchronizacji danych z aplikacją mobilną.
				|Użyj jego do ustawienia wymiany danych.';
				|tr = 'Mobil uygulama ile veri senkronizasyonu için henüz etkinleştirilmemiş olan
				| ""%User%"" kullanıcısı için zaten bir ayar vardır.
				| Veri alışverişini ayarlamak için bunu kullanın.'");
				Message = StrReplace(Message, "%User%", User);
				Field = "User";
				CommonClientServer.MessageToUser(Message, ThisObject, Field,, Cancel);
				Return;
			Else
				Code = NewCode;
			EndIf;
		EndIf;
	EndIf;
	
	If Not ThisNode Then
		
		PrefixUsed = MobileApplicationSalesOrdersOverridable.CheckPrefixForMobileDeviceData(
		Ref, PrefixForMobileDeviceData);
		
		If PrefixUsed Then
			Message = NStr("vi = 'Tiền tố ""%Prefix%"" đã được sử dụng!';
							|ru = 'Префикс ""%Prefix%"" уже используется !';
							|en = 'Prefix ""%Prefix%"" is already used.'; fa = 'Prefix ""%Prefix%"" is already used.';
							|it = 'Prefisso ""%Prefix%"" già in uso!';
							|pl = 'Prefiks ""%Prefix%"" jest już używany!';
							|tr = 'Önek ""%Prefix%"" zaten kullanılıyor!'");
			Message = StrReplace(Message, "%Prefix%", PrefixForMobileDeviceData);
			Field = "PrefixForMobileDeviceData";
			CommonClientServer.MessageToUser(Message, ThisObject, Field,, Cancel);
		EndIf;
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	AddUnverifiablePropsToArray(NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Code = "";
	Description = "";
	PrefixForMobileDeviceData = "";
	DeliverableNotificationSubscriberID = Undefined;
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	ExchangePlans.DeleteChangeRecords(Ref);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If Not ThisNode And ValueIsFilled(Ref) And Not DeletionMark
		And Code = TrimAll(User.UUID()) Then
		ExchangePlans.RecordChanges(Ref, Metadata.Catalogs.Partners);
	EndIf;
EndProcedure

#EndRegion

#Region Private

Procedure AddUnverifiablePropsToArray(NotCheckedAttributeArray)
	
	If Ref = ExchangePlans.MobileApplicationSalesOrders.ThisNode() Then
		NotCheckedAttributeArray.Add("User");
		NotCheckedAttributeArray.Add("PrefixForMobileDeviceData");
	EndIf;
	
	NotCheckedAttributeArray.Add("Code");
	NotCheckedAttributeArray.Add("Description");
	
EndProcedure

Procedure CheckNewCode(NewCode, ObjectReference, Cancel)
	
	Query = New Query("SELECT
	|	MobileApplicationSalesOrders.Ref
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	NOT MobileApplicationSalesOrders.Ref = &ObjectReference
	|	AND MobileApplicationSalesOrders.Code = &Code");
	
	Query.SetParameter("ObjectReference", ObjectReference);
	Query.SetParameter("Code", NewCode);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#EndIf
