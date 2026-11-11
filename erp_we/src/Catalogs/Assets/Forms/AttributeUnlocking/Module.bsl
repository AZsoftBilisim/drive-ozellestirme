
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	Result = New Array;
	
	If AllowEditingComplianceAccountingData Then
		Result.Add("CodeByRNCFA");
		Result.Add("CodeByUFADR");
		Result.Add("OSGroup");
		Result.Add("OSType");
	EndIf;
	
	If AllowEditingInternationalAccountingData Then
		Result.Add("FixedAssetsGroupFinancialAccounting");
	EndIf;
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion