
#Region FormEventHandlers
 
&AtClient
Procedure EnableEdit(Command)
	
	Result = New Array;
	
	If UseBranchOfficesWithSeparateBalanceSheets() Then
		If AllowEditingParentOrganization Or Not BranchOffice Then
			Result.Add("ParentCompany");
		EndIf;
	EndIf;
	
	If AllowEditingCurrencyOfRegulatedAccounting Then
		Result.Add("LocalAccountingCurrency");
	EndIf;
	
	Close(Result);
	
EndProcedure // Allow Editing()

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	BranchOffice = Parameters.BranchOffice;
	
	Items.GroupParentOrganization.Visible = Parameters.BranchOffice;
	
EndProcedure // Joining the Server()

#EndRegion

#Region Private

&AtServer
Function UseBranchOfficesWithSeparateBalanceSheets()
	
	Return GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	
EndFunction

#EndRegion
