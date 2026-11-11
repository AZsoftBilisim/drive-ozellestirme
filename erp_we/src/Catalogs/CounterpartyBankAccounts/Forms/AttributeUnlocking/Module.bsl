
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AllowEditingCurrencyOfFunds     = True;
	AllowOwnerEditing                 = True;
	AllowEditingAccountOpeningPlace        = True;
	AllowEditingStateContract = True;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	If AllowOwnerEditing Then
		Result.Add("Owner");
	EndIf;
	If AllowEditingCurrencyOfFunds Then
		Result.Add("CashCurrency");
	EndIf;
	If AllowEditingStateContract Then
		Result.Add("SeparateSDOAccount");
		Result.Add("StateContract");
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
