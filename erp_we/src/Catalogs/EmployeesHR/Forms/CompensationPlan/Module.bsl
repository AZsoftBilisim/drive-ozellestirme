#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Employee") Then 
		
		CommonClientServer.SetDynamicListParameter(Accruals, "Employee", Parameters.Employee, True);
		
		CommonClientServer.SetDynamicListParameter(Deductions, "Employee", Parameters.Employee, True);
		
	EndIf;
	
EndProcedure

#EndRegion
