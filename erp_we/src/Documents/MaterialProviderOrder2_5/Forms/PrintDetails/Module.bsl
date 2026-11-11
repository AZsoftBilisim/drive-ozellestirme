
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisForm, Parameters, , "CloseOnChoice,CloseOnOwnerClose,PurposeUseKey");
	Items.DeliveryAddress.Visible = Not GoodsDeliveryClientServer.UsedDelivery20();
	
	If Parameters.AttributeSelectionParameters <> Undefined Then
		For Each EmailSettings In Parameters.AttributeSelectionParameters Do
			TMCommonUseClientServer.SetFormItemProperty(Items, EmailSettings.Key, "ChoiceParameters", EmailSettings.Value);
		EndDo;
	EndIf;
	SalesServer.FillInAddressSelectionList(Items.DeliveryAddress, Partner);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		If Exit Then
			
			
			WarningText = NStr("vi = 'Dữ liệu đã được thay đổi.
				|Trước khi kết thúc công việc, nên lưu lại thay đổi,
				|nếu không những dữ liệu đã thay đổi sẽ bị mất.';
				|ru = 'Данные были изменены.
				|Перед завершением работы рекомендуется сохранить изменения,
				|иначе измененные данные будут утеряны.';
				|en = 'Data has changed.
				|Save the changes before exiting, 
				|otherwise the changed data will be lost.'; fa = 'Data has changed.
				|Save the changes before exiting, 
				|otherwise the changed data will be lost.';
				|it = 'I dati sono stati modificati.
				|Prima di terminare il lavoro è consigliabile salvare le modifiche,
				|altrimenti i dati modificati verranno persi.';
				|pl = 'Dane zostały zmienione.
				|Zaleca się zapisanie zmian przed zakończeniem pracy,
				|w przeciwnym razie zmienione dane zostaną utracone.';
				|tr = 'Veriler değiştirilmiştir.
				| Çalışmayı tamamlamadan önce değişiklikleri kaydetmeniz önerilmektedir,
				| aksi takdirde değiştirilen veriler kaybolacaktır.'");
			
			Return;
			
		Else
			
			If Not SaveFormParameters Then
			
				Cancel = True;
				
				ButtonsList = New ValueList();
				ButtonsList.Add("Close",     NStr("vi = 'Đóng';
													|ru = 'Закрыть';
													|en = 'Close'; fa = 'بستن';
													|it = 'Chiudere';
													|pl = 'Zamknij';
													|tr = 'Kapat'"));
				ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
												|ru = 'Не закрывать';
												|en = 'Do not close'; fa = 'بسته نشود';
												|it = 'Non chiudere';
												|pl = 'Nie zamykaj';
												|tr = 'Kapatmayın'"));
				
				CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
				QueryText       = NStr("vi = 'Chi tiết in đã được thay đổi. Đóng mà không lưu chi tiết?';
										|ru = 'Реквизиты печати были изменены. Закрыть без сохранения реквизитов?';
										|en = 'Print details were changed. Close without saving the attributes?'; fa = 'Print details were changed. Close without saving the attributes?';
										|it = 'I parametri di stampa sono stati modificati. Chiudere il modulo senza salvare i parametri?';
										|pl = 'Szczegóły pieczęci zostały zmienione. Zamknij bez zapisywania atrybutów?';
										|tr = 'Yazdırma öznitelikleri değiştirildi. Öznitelikler kaydedilmeden kapatılsın mı?'");
				
				ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
			
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Close" Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveFormParameters And Not Exit Then
		
		ParametersStructure = AttributesToChange(ThisForm);
		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShipperOnChange(Item)
	
	If ValueIsFilled(Shipper) Then
		ShipperBankAccount = GetDefaultCounterpartyBankAccountServer(Shipper);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsRecipientOnChange(Item)
	
	If ValueIsFilled(GoodsRecipient) Then
		GoodsRecipientBankAccount = GetDefaultCounterpartyBankAccountServer(GoodsRecipient);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveFormParameters = True;
	EndIf;
	
	Close();

EndProcedure

&AtClient
Procedure RefillPurposeOfPayment(Command)
	PopulatePurposeOfPayment();
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtClientAtServerNoContext
Function AttributesToChange(Source)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                  Source.DeliveryAddress);
	ParametersStructure.Insert("BankAccount",                 Source.BankAccount);
	ParametersStructure.Insert("ShipperBankAccount", Source.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Source.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Source.CounterpartyBankAccount);
	ParametersStructure.Insert("ChiefAccountant",               Source.ChiefAccountant);
	ParametersStructure.Insert("Shipper",               Source.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Source.GoodsRecipient);
	ParametersStructure.Insert("OrderDate",                     Source.OrderDate);
	ParametersStructure.Insert("AdditionalInformation",       Source.AdditionalInformation);
	ParametersStructure.Insert("PaymentPurposes",              Source.PaymentPurposes);
	ParametersStructure.Insert("OrderNumber",                    Source.OrderNumber);
	ParametersStructure.Insert("Director",                   Source.Director);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure PopulatePurposeOfPayment()
	PaymentPurposes = StrTemplate(NStr("vi = 'Theo hóa đơn số %1 ngày %2';
										|ru = 'По счету № %1 от %2';
										|en = 'By proforma invoice No. %1 dated %2'; fa = 'By proforma invoice No. %1 dated %2';
										|it = 'In base al conto № %1 di %2';
										|pl = 'Dla rachunku nr %1 z dn. %2';
										|tr = 'Hesaplara göre %1 sayılı %2 tarihli'"), OrderNumber, OrderDate);
EndProcedure

#EndRegion

#EndRegion
