
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Period") Then
		Period = Parameters.Period;
	EndIf;
	AllocationOption = Enums.MethodsOfExpenseItemAllocations.ByBusinessUnitsAndStagesAccToRules;
	
	If GetFunctionalOption("ComplexAutomation") Then
		Items.DivisionsStagesTheRuleOfDistributionByStages.Title = NStr("vi = 'Theo sản phẩm xuất xưởng';
																		|ru = 'По выпускам продукции';
																		|en = 'By product release'; fa = 'By product release';
																		|it = 'In base alla fabbricazione dei prodotti';
																		|pl = 'Dla wyprodukowań towarów';
																		|tr = 'İmal edilen ürün çıkışlarına göre'");
		Items.StagesTheRuleOfDistributionByStages.Title = NStr("vi = 'Theo sản phẩm xuất xưởng';
																|ru = 'По выпускам продукции';
																|en = 'By product release'; fa = 'By product release';
																|it = 'In base alla fabbricazione dei prodotti';
																|pl = 'Dla wyprodukowań towarów';
																|tr = 'İmal edilen ürün çıkışlarına göre'");
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ArrayOfOperationDetails = New Array;
	
	ArrayOfOperationDetails.Add("AllocationOption");
	
	
	If AllocationOption = 
			Enums.MethodsOfExpenseItemAllocations.ByBusinessUnitsAndStagesAccToRules Then
				ArrayOfOperationDetails.Add("TheRuleOfDistributionByStages");
				ArrayOfOperationDetails.Add("DivisionAllocationRule");
	Else
		ArrayOfOperationDetails.Add("TheRuleOfDistributionByStages");
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		CheckedAttributes,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllocationOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AllocationOptionOnChange(Item)
	
	SetVisibilityOfDistributionRules();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateDocuments(Command)
	
	ClearMessages();
	If CheckFilling() Then
		FillingData = New Structure;
		FillingData.Insert("AllocationOption", AllocationOption);
		FillingData.Insert("TheRuleOfDistributionByStages", TheRuleOfDistributionByStages);
		FillingData.Insert("DivisionAllocationRule", DivisionAllocationRule);
		Close(FillingData);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetVisibilityOfDistributionRules()
	
	If AllocationOption = PredefinedValue("Enum.MethodsOfExpenseItemAllocations.ByBusinessUnitsAndStagesAccToRules") Then
		Items.PageAllocationRulesGroup.CurrentPage = Items.PageDepartmentsStages;
	ElsIf AllocationOption = 
		PredefinedValue("Enum.MethodsOfExpenseItemAllocations.ByStagesAccToRuleInBusinessUnit")
		Or AllocationOption = 
			PredefinedValue("Enum.MethodsOfExpenseItemAllocations.ByStagesAccToRuleInAllBusinessUnits") Then
		Items.PageAllocationRulesGroup.CurrentPage = Items.PageStages;
	EndIf;
	
EndProcedure

#EndRegion
