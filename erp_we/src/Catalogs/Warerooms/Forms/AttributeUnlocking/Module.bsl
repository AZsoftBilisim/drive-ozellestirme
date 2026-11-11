
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AllowEditingOwner                            = True;
	AllowEditingToUseAddressStorage        = True;
	AllowEditingStartDateOfAddressStorageOfBalances = True;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	
	If AllowEditingToUseAddressStorage Then
		Result.Add("CustomizeBinLocationWarehousing");
	EndIf;

	If AllowEditingOwner Then
		Result.Add("Owner");
	EndIf;
	
	If AllowEditingStartDateOfAddressStorageOfBalances Then
		Result.Add("StartDateOfUsingWarehouseBinSystem");
	EndIf;
	
	Close(Result);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
