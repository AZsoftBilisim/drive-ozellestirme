
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ManagingElements();
	
EndProcedure 

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenExpenseItems(Command)
	
	OpenForm("ChartOfCharacteristicTypes.ExpenseItems.Form.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenIncomeItems(Command)
	
	OpenForm("ChartOfCharacteristicTypes.IncomeItems.Form.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenCostAllocationRules(Command)
	
	OpenForm("Catalog.CostAllocationRules.Form.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenOtherExpenses(Command)
	
	OpenForm("Catalog.OtherExpenses.Form.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheObjectCostCenter(Command)
	OpenForm("Catalog.CostCenters.Form.ListForm", , ThisForm);
EndProcedure

&AtClient
Procedure OpenLinesOfBusiness(Command)
	
	OpenForm("Catalog.LinesOfBusiness.Form.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenMethodsOfAllocationByLinesOfBusiness(Command)
	
	OpenForm("Catalog.AllocationMethodsByLinesOfBusiness.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSettingsOfAllocationByLinesOfBusiness(Command)
	
	OpenForm("InformationRegister.SetUpAllocationByLinesOfBusiness.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheTypesOfChargesDeductions(Command)
	
	OpenForm("Catalog.AccrualAndDeductionKinds.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTypesOfTaxesAndContributions(Command)
	
	OpenForm("Catalog.TaxContributionKinds.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTypesOfEmployeeCompensations(Command)
	
	OpenForm("Catalog.TypesOfEmployeeCompensations.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()
	
	Items.GroupAccountingForOtherIncomeAndExpenses.Visible =
		GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
		
	Items.GroupAccountingByBusinessLines.Visible =
		GetFunctionalOption("GenerateFinancialResult");
	
	
EndProcedure

#EndRegion
