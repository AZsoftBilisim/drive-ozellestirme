#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	ObjectOfAccountingForImproperValues = Parameters.ObjectOfAccountingForImproperValues;
	
EndProcedure

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure Select(Command)
	
	If CheckFilling() Then
		Close(GLAccount);
	EndIf;
	
EndProcedure

#EndRegion