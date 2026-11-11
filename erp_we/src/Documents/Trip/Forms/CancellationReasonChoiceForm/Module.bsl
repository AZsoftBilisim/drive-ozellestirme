// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CancellationReason = Catalogs.DeliveryCancellationReasons.NotDelivered;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Confirm(Command)
	
	If CheckFilling() Then
		
		Close(CancellationReason);
		
	EndIf;
	
EndProcedure

#EndRegion
