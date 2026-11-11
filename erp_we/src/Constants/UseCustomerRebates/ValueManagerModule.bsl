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
		
		MessageText = NStr("vi = 'Cấm thay đổi tính năng thưởng lũy kế của khách hàng trong nút phụ trao đổi';
							|ru = 'Запрещено изменение функционала ретро-бонусов клиентов в подчиненном узле обмена';
							|en = 'Cannot change the customer rebate functions in a subordinate exchange node'; fa = 'Cannot change the customer rebate functions in a subordinate exchange node';
							|it = 'Запрещено изменение функционала ретро-бонусов клиентов в подчиненном узле обмена';
							|pl = 'Cannot change the customer rebate functions in a subordinate exchange node';
							|tr = 'Değişim düğümünde retro bonuslarının işlevselliklerini değiştirmek yasaktır'");
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
		SetParameters.Used = GetFunctionalOption("UseCustomerRebates");
		
		PropertyManager.SetPropertySetParameters(
			"Catalog_CustomerRebatesKinds", SetParameters);
		PropertyManager.SetPropertySetParameters(
			"Document_ConditionsOfCustomerRebates", SetParameters);
		PropertyManager.SetPropertySetParameters(
			"Document_DebitCustomerRebates", SetParameters);
		PropertyManager.SetPropertySetParameters(
			"Document_AccrualOfCustomerRebates", SetParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf