
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseShiftTasks.Get();
	
	PropertyManager.SetPropertySetParameters("Document_ShiftTask", SetParameters);
	
EndProcedure

#EndRegion

#EndIf
