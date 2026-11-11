#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Owner") Then
	
		Query = New Query;
		Query.Text = "
		|SELECT
		|	CatalogData.Ref
		|FROM
		|	Catalog.OptionsOfLoansAndDepositsSchedules AS CatalogData
		|WHERE
		|	NOT CatalogData.DeletionMark
		|	AND CatalogData.Owner = &Owner";
		
		Query.SetParameter("Owner", FillingData.Owner);
		Upholded = Query.Execute().IsEmpty();
		Used = Upholded;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Common.ObjectAttributeValue(Owner, "Status") = Enums.CounterpartyContractStatuses.Closed Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cấm thay đổi lịch biểu theo hợp đồng đã đóng!';
				|ru = 'Изменения графика по закрытому договору запрещены!';
				|en = 'Changing schedule for a closed contract is not allowed.'; fa = 'Changing schedule for a closed contract is not allowed.';
				|it = 'Le modifiche al programma per un contratto chiuso sono proibite!';
				|pl = 'Zmiany w harmonogramie zamkniętej umowy są zabronione!';
				|tr = 'Kapalı sözleşme kapsamında program değişiklikleri yasaktır!'"),,,, Cancel);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Upholded Or Used Then
	
		Query = New Query;
		Query.Text = "
		|SELECT
		|	CatalogData.Ref
		|FROM
		|	Catalog.OptionsOfLoansAndDepositsSchedules AS CatalogData
		|WHERE
		|	CatalogData.Owner = &Owner
		|	AND CatalogData.Ref <> &Ref
		|	AND (CatalogData.Upholded AND &Upholded
		|		OR CatalogData.Used AND &Used)
		|";
		
		Query.SetParameter("Owner", Owner);
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Upholded", Upholded);
		Query.SetParameter("Used", Used);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			VariantOfObjectGraph = Selection.Ref.GetObject();
			
			Try
				VariantOfObjectGraph.Lock();
			Except
				MessageText = StrTemplate(
					NStr("vi = '%1 đang trong quá trình chỉnh sửa bởi người dùng hoặc hệ thống và không thể thay đổi được.
						|Để đặt trạng thái, phần còn lại của lịch trình hợp đồng phải được giải phóng.';
						|ru = '%1 находится в процессе редактирования пользователем или системой и не может быть изменен.
						|Для установки статусов необходимо освободить остальные варианты графиков договора.';
						|en = '%1 is being edited by a user or application and cannot be changed.
						|To set statuses, release other contract schedule options.'; fa = '%1 is being edited by a user or application and cannot be changed.
						|To set statuses, release other contract schedule options.';
						|it = '%1 è in fase di modifica da parte dell''utente o del sistema e non può essere modificato. 
						|Per impostare gli stati, è necessario rilasciare le opzioni rimanenti per i grafici di contratto.';
						|pl = '%1 znajduje się w procesie edycji użytkownikiem lub systemem i nie może zostać zmieniony. 
						| Aby ustawić statusy należy zwolnić pozostałe warianty harmonogramów kontraktu.';
						|tr = '%1, kullanıcı veya sistem tarafından düzenlenme sürecindedir ve değiştirilemez.
						|Durumları ayarlamak için, sözleşme planı seçeneklerinin geri kalanı serbest bırakılmalı.'"),
					VariantOfObjectGraph);
				CommonClientServer.MessageToUser(MessageText,,,, Cancel);
				Break;
			EndTry;
			
			If Upholded Then
				VariantOfObjectGraph.Upholded = False;
			EndIf;
			
			If Used Then
				VariantOfObjectGraph.Used = False;
			EndIf;
			
			VariantOfObjectGraph.Write();
		EndDo;
	EndIf;
	
	If Not AdditionalProperties.Property("RecordingGraphs") Then
		PaymentObjects = New Array;
		PaymentObjects.Add(Owner);
		SetPrivilegedMode(True);
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(PaymentObjects);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf