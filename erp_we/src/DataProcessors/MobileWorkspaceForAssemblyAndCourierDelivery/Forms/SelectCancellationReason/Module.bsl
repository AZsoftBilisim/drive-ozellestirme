#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReferenceOrder", ReferenceOrder);
	
EndProcedure

#EndRegion


#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	Cancel = False;
	CancelTheOrder(RowSelected, Cancel);
	
	If Not Cancel Then
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CancelTheOrder(CancellationReason, Cancel)
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.CancelTheOrder(ReferenceOrder, CancellationReason, Cancel);
	
EndProcedure

#EndRegion
