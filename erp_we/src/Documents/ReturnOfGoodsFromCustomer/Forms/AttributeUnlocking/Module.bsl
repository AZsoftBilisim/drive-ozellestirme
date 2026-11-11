
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AllowEditAttributes = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	If AllowEditAttributes Then 
		
		Close(GetBlockedBankingDetails());
		
	Else
		
		Close();
		
	EndIf;

EndProcedure

&AtServer 
Function GetBlockedBankingDetails()
	
	Return Documents.ReturnOfGoodsFromCustomer.GetObjectAttributesToLock();
	
EndFunction

#EndRegion
