//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi tính năng thưởng lũy kế trong nút phụ trao đổi';
							|ru = 'Запрещено изменение функционала ретро-бонусов в подчиненном узле обмена';
							|en = 'Cannot change the rebate functions in a subordinate exchange node'; fa = 'Cannot change the rebate functions in a subordinate exchange node';
							|it = 'Запрещено изменение функционала ретро-бонусов в подчиненном узле обмена';
							|pl = 'Cannot change the rebate functions in a subordinate exchange node';
							|tr = 'Bir alt değişim düğümünde retro-bonusların işlevselliğini değiştirmek yasaktır'");
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf