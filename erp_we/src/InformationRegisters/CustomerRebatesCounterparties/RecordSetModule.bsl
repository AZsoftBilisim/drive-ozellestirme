//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi dữ liệu thưởng lũy kế tại nút trao đổi phụ';
							|ru = 'Запрещено изменение данных ретро-бонусов в подчиненном узле обмена';
							|en = 'Cannot change the rebate data in a subordinate exchange node'; fa = 'Cannot change the rebate data in a subordinate exchange node';
							|it = 'Запрещено изменение данных ретро-бонусов в подчиненном узле обмена';
							|pl = 'Cannot change the rebate data in a subordinate exchange node';
							|tr = 'Bir bağımlı değişim düğümünde retro-bonus veri değişikliği yasaktır'");
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf