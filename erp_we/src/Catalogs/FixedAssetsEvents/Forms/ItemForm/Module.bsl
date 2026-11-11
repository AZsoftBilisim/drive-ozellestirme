#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Limitation of the selection list of the "OS Event type" field
	If Parameters.Property("EventTypeFAAvailableValues") Then
		Items.EventKindWithFixedAssets.ListChoiceMode = True;
		Items.EventKindWithFixedAssets.ChoiceList.LoadValues(Parameters.EventTypeFAAvailableValues);
	EndIf;
	
EndProcedure

#EndRegion
