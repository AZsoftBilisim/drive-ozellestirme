
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters,,"CloseOnChoice,CloseOnOwnerClose,PurposeUseKey");
	
	DeliveryIsRequired = Parameters.DeliveryIsRequired;
	DeliverySpecificationMethod = Parameters.DeliverySpecificationMethod;
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		If DeliveryIsRequired
			And DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
			
			ToolTipText = NStr("ru = 'Адрес указан по точке доставки';
								|vi = 'Address is specified by delivery point';
								|en = 'Address is specified by delivery point'; fa = 'Address is specified by delivery point';
								|it = 'Address is specified by delivery point';
								|pl = 'Address is specified by delivery point';
								|tr = 'Adres teslimat noktasına göre belirtilmiş'");
			
			Items.DeliveryAddress.ReadOnly = True;
			Items.DeliveryAddress.ToolTip = ToolTipText;
			Items.DeliveryAddress.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
			
		Else
			
			GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(Items, DeliveryOrderData, True);
			
		EndIf;
		
	Else
		
		ReFillInDeliveryAddress = GoodsDelivery.ReFillInDeliveryAddressInSalesDocument(Ref);
		
		Items.DeliveryAddress.Visible =
			Not GetFunctionalOption("UseDeliveryManagement") Or ReFillInDeliveryAddress;
			
		If ReFillInDeliveryAddress Then
			GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, DeliveryOrderData);
		Else
			SalesServer.FillInAddressSelectionList(Items.DeliveryAddress, Partner);
		EndIf;
		
	EndIf;
	
	If Parameters.AttributeSelectionParameters <> Undefined Then
		For Each EmailSettings In Parameters.AttributeSelectionParameters Do
			TMCommonUseClientServer.SetFormItemProperty(Items, EmailSettings.Key, "ChoiceParameters", EmailSettings.Value);
		EndDo;
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ForcefullyCloseTheForm
		And (Modified And Not SaveParameters)
		And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
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
		
		Cancel = True;
		
		AdditionalParameters = New Structure;
		ShowQueryBox(
			New CallbackDescription("ShowQuestionBeforeClosingEnd", ThisObject, AdditionalParameters),
			NStr("vi = 'Chi tiết in đã được thay đổi. Đóng mà không lưu chi tiết?';
				|ru = 'Реквизиты печати были изменены. Закрыть без сохранения реквизитов?';
				|en = 'Print details were changed. Close without saving the attributes?'; fa = 'Print details were changed. Close without saving the attributes?';
				|it = 'I parametri di stampa sono stati modificati. Chiudere il modulo senza salvare i parametri?';
				|pl = 'Szczegóły pieczęci zostały zmienione. Zamknij bez zapisywania atrybutów?';
				|tr = 'Yazdırma öznitelikleri değiştirildi. Öznitelikler kaydedilmeden kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuestionBeforeClosingEnd(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "Close" Then
		ForcefullyCloseTheForm = True;
		Close(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters And Not Exit Then
		
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
	
	If ValueIsFilled(GoodsRecipient) Or ReFillInDeliveryAddress Then
		GoodsRecipientOnChangeServer()
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	If ReFillInDeliveryAddress
		Or GoodsDeliveryClientServer.UsedDelivery25() Then
		
		NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			ThisObject[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
			ThisObject[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ReFillInDeliveryAddress
		Or GoodsDeliveryClientServer.UsedDelivery25() Then
		
		StandardProcessing = False;
		DeliveryAddressOnChange(Item);
		FillPropertyValues(DeliveryOrderData, ThisObject);
		GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, DeliveryOrderData, Item.Name, ValueSelected);
		FillPropertyValues(ThisObject, DeliveryOrderData, "DeliveryAddress, DeliveryAddressValue, DeliveryAddressFieldValues");
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveParameters = True;
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

&AtServer
Procedure GoodsRecipientOnChangeServer()
	
	If ValueIsFilled(GoodsRecipient) Then
		GoodsRecipientBankAccount = GetDefaultCounterpartyBankAccountServer(GoodsRecipient);
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		If Not (DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument
					And DeliveryIsRequired) Then
			
			GoodsDelivery.FillInListsForSelectingRecipientSenderAddresses(Items, ThisObject, True);
			If Items.DeliveryAddress.ChoiceList.Count() > 0 Then
				
				FirstStructureInList = Items.DeliveryAddress.ChoiceList[0].Value;
				DeliveryAddress = FirstStructureInList.DeliveryAddress;
				DeliveryAddressValue = FirstStructureInList.DeliveryAddressValue;
				DeliveryAddressFieldValues = FirstStructureInList.DeliveryAddressFieldValues;
				
			EndIf;
			
		EndIf;
		
	Else
		
		If ReFillInDeliveryAddress Then
			FillPropertyValues(DeliveryOrderData, ThisObject);
			FillParameters = GoodsDelivery.ParametersForFillingInBankingDetails();
			FillParameters.ClearDeliveryDetails = False;
			FillParameters.SetDeliveryMethod = False;
			GoodsDelivery.FillInDeliveryDetails(Items, "GoodsRecipient", DeliveryOrderData, FillParameters);
			FillPropertyValues(
				ThisObject, DeliveryOrderData, "DeliveryAddress, DeliveryAddressValue, DeliveryAddressFieldValues");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function AttributesToChange(Source)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                  Source.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Source.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Source.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryZone",                   Source.DeliveryZone);
	ParametersStructure.Insert("DeliveryTimeFrom",                 Source.DeliveryTimeFrom);
	ParametersStructure.Insert("DeliveryTimeTo",                Source.DeliveryTimeTo);
	ParametersStructure.Insert("AdditionalDeliveryInformation", Source.AdditionalDeliveryInformation);
	ParametersStructure.Insert("BankAccount",                 Source.BankAccount);
	ParametersStructure.Insert("ShipperBankAccount", Source.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Source.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Source.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",               Source.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Source.GoodsRecipient);
	ParametersStructure.Insert("Director",                   Source.Director);
	ParametersStructure.Insert("ChiefAccountant",               Source.ChiefAccountant);
	ParametersStructure.Insert("PaymentPurposes",              Source.PaymentPurposes);
	ParametersStructure.Insert("OrderNumber",			           Source.OrderNumber);
	ParametersStructure.Insert("OrderDate",			           Source.OrderDate);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure PopulatePurposeOfPayment()
	PaymentPurposes = NStr("vi = 'Theo hóa đơn số %OrderNumber% ngày %OrderDate%';
							|ru = 'По счету №%OrderNumber% от %OrderDate%';
							|en = 'By account No. %OrderNumber% of %OrderDate%'; fa = 'By account No. %OrderNumber% of %OrderDate%';
							|it = 'Per la fattura №%OrderNumber% del %OrderDate%';
							|pl = 'Na podstawie rachunku nr%OrderNumber% z dn. %OrderDate%';
							|tr = '%OrderNumber% sayılı %OrderDate% tarihli hesaba göre'");
	PaymentPurposes = StrReplace(PaymentPurposes,"%OrderNumber%",OrderNumber);
	PaymentPurposes = StrReplace(PaymentPurposes,"%OrderDate%",OrderDate);
EndProcedure

#EndRegion

#EndRegion
