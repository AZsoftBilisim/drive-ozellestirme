#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ImageIndicatorsInRowsClick(Item)
	
	TableType = 0;
	
EndProcedure

&AtClient
Procedure ImageIndicatorsInColumnsClick(Item)
	
	TableType = 1;
	
EndProcedure

&AtClient
Procedure ImageComplexTableClick(Item)
	
	TableType = 2;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateTable(Command)
	
	Close(TableType);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
