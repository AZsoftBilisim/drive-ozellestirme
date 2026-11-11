//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ValueChanged; // Boolean

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi tính năng thưởng lũy kế của nhà cung cấp trong nút phụ trao đổi';
							|ru = 'Запрещено изменение функционала ретро-бонусов поставщиков в подчиненном узле обмена';
							|en = 'Cannot change the vendor rebate functions in a subordinate exchange node'; fa = 'Cannot change the vendor rebate functions in a subordinate exchange node';
							|it = 'Запрещено изменение функционала ретро-бонусов поставщиков в подчиненном узле обмена';
							|pl = 'Cannot change the vendor rebate functions in a subordinate exchange node';
							|tr = 'Alt değişim düğümünde tedarikçi retro bonuslarının işlevselliğini değiştirmek yasaktır'");
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
	ValueChanged = (Value <> Constants.UseCustomerRebates.Get());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueChanged Then
		
		SetParameters = PropertyManager.PropertySetParametersStructure();
		SetParameters.Used = GetFunctionalOption("UseVendorRebates");
		
		PropertyManager.SetPropertySetParameters(
			"Catalog_VendorRebateKinds", SetParameters);
		PropertyManager.SetPropertySetParameters(
			"Document_ConditionsOfVendorRebates", SetParameters);
		PropertyManager.SetPropertySetParameters(
			"Document_WriteOffVendorRebates", SetParameters);
		PropertyManager.SetPropertySetParameters(
			"Document_AccrualOfVendorRebates", SetParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf