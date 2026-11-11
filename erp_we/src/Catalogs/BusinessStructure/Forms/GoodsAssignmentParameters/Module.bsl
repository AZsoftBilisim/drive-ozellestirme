
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	OptionOfAssignedAccountingOfGoods = Parameters.OptionOfAssignedAccountingOfGoods;
	
	ReadOnly = Not AccessRight("Update", Metadata.Catalogs.BusinessStructure);
	Items.OptionOfAssignedAccountingOfGoods.ReadOnly = ReadOnly;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	NotifyChoice(OptionOfAssignedAccountingOfGoods);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
