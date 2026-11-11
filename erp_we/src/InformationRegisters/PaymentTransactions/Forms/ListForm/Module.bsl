#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;   
	
	EquipmentManagerServerCallOverridable.ListOfPaymentTransactionsWhenCreatedOnServer(ThisForm, Cancel, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion
