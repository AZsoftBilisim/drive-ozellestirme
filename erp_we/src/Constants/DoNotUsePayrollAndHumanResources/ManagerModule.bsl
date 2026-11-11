#Region Private

#Region InfobaseUpdateHandlers	

Procedure SetConstantOfNotUsingPayrollAndPersonnel() Export
	
	UsePayrollAndPersonnel = Constants.PayrollAndHumanResourcesWE.Get();
	NotUsePayrollAndPersonnel = Constants.DoNotUsePayrollAndHumanResources.Get();
	If UsePayrollAndPersonnel <> NotUsePayrollAndPersonnel Then
		Return;                 
	EndIf;
	
	Constants.DoNotUsePayrollAndHumanResources.Set(Not UsePayrollAndPersonnel);
	
EndProcedure

#EndRegion

#EndRegion