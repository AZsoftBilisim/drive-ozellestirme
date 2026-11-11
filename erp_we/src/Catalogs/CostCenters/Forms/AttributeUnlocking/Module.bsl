

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AllowEditingOfTheOrganizationDepartment = False;
	AllowEditingOfTheTypeAndCostAllocationOptions = True;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = AttributesToEdit();
	Close(Result);

EndProcedure

&AtServer
Function AttributesToEdit()
	
	Result = New Array;
	If AllowEditingOfTheOrganizationDepartment Then
		Result.Add(Metadata.Catalogs.CostCenters.Attributes.Organization.Name);
		Result.Add(Metadata.Catalogs.CostCenters.Attributes.Department.Name);
	EndIf;
	If AllowEditingOfTheTypeAndCostAllocationOptions Then
		Result.Add(Metadata.Catalogs.CostCenters.Attributes.ExpensesOccur.Name);
		Result.Add(Metadata.Catalogs.CostCenters.Attributes.CostAllocationOptionManag.Name);
		Result.Add(Metadata.Catalogs.CostCenters.Attributes.CostAllocationOptionLocal.Name);
		Result.Add(Metadata.Catalogs.CostCenters.Attributes.CostAllocationOptionTax.Name);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
