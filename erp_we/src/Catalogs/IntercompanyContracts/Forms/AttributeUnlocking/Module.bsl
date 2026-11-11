#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	GenerateHeaderDetails();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	Close(True);
	
EndProcedure

&AtClient
Procedure CheckObjectUsage(Command)
	
	ChangeLockOfTMObjectAttributesClient.CheckObjectUsage(ThisObject, IdleHandlerParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure GenerateHeaderDetails()
	
	ContractType = Common.ObjectAttributeValue(Parameters.Object, "ContractType");
	
	If ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale Then
		TextTitle_ = NStr("vi = 'Kiểu hợp đồng, Doanh nghiệp-nhà cung cấp, Doanh nghiệp-người bán,
			|Chi tiết hạch toán, Tiền tệ hạch toán.';
			|ru = 'Тип договора, Организация-поставщик, Организация-продавец,
			|Детализация расчетов, Валюта взаиморасчетов.';
			|en = 'Contract type, Vendor company, Seller company,
			|AR/AP item, AR/AP currency.'; fa = 'Contract type, Vendor company, Seller company,
			|AR/AP item, AR/AP currency.';
			|it = 'Тип договора, Организация-поставщик, Организация-продавец,
			|Детализация расчетов, Валюта взаиморасчетов.';
			|pl = 'Contract type, Vendor company, Seller company,
			|AR/AP item, AR/AP currency.';
			|tr = 'Sözleşme türü, Tedarikçinin iş yeri, Satış asistanının iş yeri,
			|Alacak/borç muhasebesi detaylandırma, Alacak/borç muhasebesi para birimi.'");
	Else
		TextTitle_ = NStr("vi = 'Kiểu hợp đồng, Doanh nghiệp-người đặt ký gửi, Doanh nghiệp-người nhận ký gửi,
			|Chi tiết hạch toán, Tiền tệ hạch toán.';
			|ru = 'Тип договора, Организация-комитент, Организация-комиссионер,
			|Детализация расчетов, Валюта взаиморасчетов.';
			|en = 'Contract type, Consignor company, Consignee company,
			|AR/AP item, AR/AP currency.'; fa = 'Contract type, Consignor company, Consignee company,
			|AR/AP item, AR/AP currency.';
			|it = 'Тип договора, Организация-комитент, Организация-комиссионер,
			|Детализация расчетов, Валюта взаиморасчетов.';
			|pl = 'Contract type, Consignor company, Consignee company,
			|AR/AP item, AR/AP currency.';
			|tr = 'Тип договора, Организация-комитент, Организация-комиссионер,
			|Детализация расчетов, Валюта взаиморасчетов.'");
	EndIf;
	
	Items.TitleDetails.Title = TextTitle_;
	
EndProcedure

#EndRegion

#EndRegion
