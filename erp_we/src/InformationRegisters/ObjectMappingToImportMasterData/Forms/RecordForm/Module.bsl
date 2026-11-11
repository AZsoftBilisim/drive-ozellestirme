
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	MetadataObjectType = TypeOf(Record.MetadataObject);
	
	Items.ObjectReference.TypeRestriction = New TypeDescription(CommonClientServer.ValueInArray(MetadataObjectType));
	Items.MetadataObject.InputHint = String(MetadataObjectType);
	
EndProcedure

#EndRegion
