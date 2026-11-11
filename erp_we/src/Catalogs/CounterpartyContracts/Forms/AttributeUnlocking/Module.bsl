#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	GenerateHeaderDetails();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Close(True);

EndProcedure

&AtClient
Procedure CheckObjectUsage(Command)
	
	ChangeLockOfTMObjectAttributesClient.CheckObjectUsage(ThisForm, IdleHandlerParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure GenerateHeaderDetails()
	
	ObjectAttributes = Common.ObjectAttributesValues(Parameters.Object, "BusinessOperation, ContractType");
	
	TextPartner = PartnersAndCounterparties.HeaderOfPartnerDetailsDependingOnBusinessOperation(ObjectAttributes.BusinessOperation);
	
	UsePurchasingOption = GetFunctionalOption("UseGoodsInTransitFromVendors")
											Or GetFunctionalOption("UseUninvoicedDeliveries");
	
	If UsePurchasingOption Then
		TextTitle_ = NStr("vi = 'Kiểu mối quan hệ, %1, Đối tác, Doanh nghiệp,
			|Trình tự thanh toán, Tiền tệ, Chi tiết thanh toán, Lập chứng từ mua hàng từng phần';
			|ru = 'Тип взаимоотношений, %1, Контрагент, Организация,
			|Порядок оплаты, Валюта, Детализация расчетов, Оформление раздельной закупки';
			|en = 'Relationship type, %1, Counterparty, Company,
			|Payment procedure, Currency, AR/AP item, Separate purchase registration'; fa = 'Relationship type, %1, Counterparty, Company,
			|Payment procedure, Currency, AR/AP item, Separate purchase registration';
			|it = 'Il tipo delle relazioni, %1, Controparte, Società,
			|Modalità di pagamento, Valuta, Dettagli dei pagamenti, Registrazione di acquisto separato';
			|pl = 'Typ interakcji, %1, Kontrahent, Firma,
			|Procedura płatności, Waluta, Detalizacja rozliczeń, Sporządzenie zakupu rozdzielnego';
			|tr = 'İlişki türü, %1, Cari hesap, İş yeri,
			| Ödeme prosedürü, Para birimi, Mutabakat detayları, Bölünmüş satın alma işlemi'");
	Else
		TextTitle_ = NStr("vi = 'Kiểu mối quan hệ, %1, Đối tác, Doanh nghiệp,
			|Trình tự thanh toán, Tiền tệ, Chi tiết thanh toán';
			|ru = 'Тип взаимоотношений, %1, Контрагент, Организация,
			|Порядок оплаты, Валюта, Детализация расчетов';
			|en = 'Relationship type, %1, Counterparty, Company,
			|Payment procedure, Currency, AR/AP item'; fa = 'Relationship type, %1, Counterparty, Company,
			|Payment procedure, Currency, AR/AP item';
			|it = 'Il tipo delle relazioni, %1, Contraente, Società,
			|Modalità di pagamento, Valuta, Dettagli dei pagamenti';
			|pl = 'Typ interakcji, %1, Kontrahent, Firma,
			|Procedura płatności, Waluta, Detalizacja rozliczeń';
			|tr = 'İlişki türü, %1, Cari hesap, İş yeri,
			| Ödeme prosedürü, Para birimi, Mutabakat detayları'");
	EndIf;
	
	UseWarehouseAcceptance	= (ObjectAttributes.ContractType = Enums.ContractTypes.WithVendor
												Or ObjectAttributes.ContractType = Enums.ContractTypes.PurchaseEAEU
												Or ObjectAttributes.ContractType = Enums.ContractTypes.Import
												Or ObjectAttributes.ContractType = Enums.ContractTypes.ReceivingForCustody)
											And (UsePurchasingOption
												Or GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt"));
	
	TextTitle_ = TextTitle_ + ?(UseWarehouseAcceptance,
										"," + Chars.NBSp + NStr("vi = 'Nhập kho';
																|ru = 'Приемка товаров на склад';
																|en = 'Goods receipt at warehouse'; fa = 'رسید کالا در انبار';
																|it = 'Accettazione merce al magazzino';
																|pl = 'Przyjęcie towarów do magazynu';
																|tr = 'Ambara mal girişi'"),
										"");
	
	Items.TitleDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(TextTitle_, TextPartner);
	
EndProcedure

#EndRegion

#EndRegion
