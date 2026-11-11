// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		Items.List.ChangeRowSet = False;
	EndIf;
	
EndProcedure

#EndRegion