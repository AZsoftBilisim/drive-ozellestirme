
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CopySource = Parameters.CopySource;
	
	ParametersForCopyingAdditionalData = Parameters.ParametersForCopyingAdditionalData;
	
EndProcedure

#EndRegion


#Region ProcessingCommands_

&AtClient
Procedure Copy(Command)
		
	Close(ParametersForCopyingAdditionalData);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion