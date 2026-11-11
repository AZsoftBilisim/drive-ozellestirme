#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("FormPath") Then 
		Cancel = True;
		Return;
	EndIf;
	
	InformationCenterServer.OutputContextualLinks(ThisObject,
														Items.InformationReferences,
														1,
														20,
														False,
														Parameters.FormPath);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_ClickingOnInformationLink(Item) Export
	
	InformationCenterClient.ClickingOnInformationLink(ThisObject, Item);
	
EndProcedure

#EndRegion

