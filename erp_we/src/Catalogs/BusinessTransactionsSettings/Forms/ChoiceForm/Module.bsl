
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RepresentedAsList = Parameters.Property("RepresentedAsList");
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If RepresentedAsList Then
		Items.List.Representation = TableRepresentation.List;
	EndIf;
	
EndProcedure

#EndRegion