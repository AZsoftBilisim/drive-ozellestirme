// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value = True Then
		
		Delivery25WasUsed = GoodsDelivery.Delivery25WasUsed();
		
		If Delivery25WasUsed Then
			
			Constants.NotUseDeliveryManagement20.Set(True);
			Constants.NotUseDeliveryManagement25.Set(False);
			
		Else
			
			Constants.NotUseDeliveryManagement20.Set(False);
			Constants.NotUseDeliveryManagement25.Set(True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf