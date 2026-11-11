#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion