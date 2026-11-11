
#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ActiveCalculationsBeforeDeleteRow(Item, Cancel)
	
	If Items.ActiveCalculations.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Cancel = True;
	
	DeleteCalculationRecords(Items.ActiveCalculations.CurrentData.CalculationID);
	
	Items.ActiveCalculations.Refresh();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DeleteCalculationRecords(CalculationID)
	
	InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	
EndProcedure

#EndRegion
