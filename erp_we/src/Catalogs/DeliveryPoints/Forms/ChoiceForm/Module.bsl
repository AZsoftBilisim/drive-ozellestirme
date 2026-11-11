//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	GoodsDeliveryClientServer.ChangeSelectionOfCurrentPoints(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldShowUnused(Command)
	
	GoodsDeliveryClientServer.ChangeSelectionOfCurrentPoints(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	GoodsDelivery.SetUpRegistrationOfUnusedDeliveryPoints(List);
	
EndProcedure

#EndRegion