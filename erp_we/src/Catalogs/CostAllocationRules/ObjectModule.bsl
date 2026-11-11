#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	If SettingsOfBaseOfAllocationByLotsChanged Then
		RulePresentation = Catalogs.CostAllocationRules.GetRulePresentation(
			BaseOfAllocationByLots);
	EndIf;
	

	If AssignRule <> Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
		DataSource = Enums.DataSourcesForExpenseAllocation.EmptyRef();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Catalogs.CostAllocationRules.ItemsAndDimensionsSelectionParameters(AssignRule);
	If Not ItemsAndDimensionsSelectionParameters = Undefined Then
		IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
		
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Catalogs.CostAllocationRules.AccountingAccountSettings_());
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AssignRule") Then
		
		If FillingData.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits
			Or FillingData.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter Then
			
			If FillingData.Property("AllocationBase")
				And TypeOf(FillingData.AllocationBase) <> Type("EnumRef.TypesOfCostAllocatingBase") Then
				FillingData.Delete("AllocationBase");
			EndIf;
			If Not FillingData.Property("AllocationBase") Then
				FillingData.Insert("AllocationBase", Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis);
			EndIf;
			
		EndIf;
		
		If Not FillingData.Property("BaseOfAllocationByLots") Then
			BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.DefaultValue(FillingData.AssignRule);
		EndIf;
	
		If FillingData.AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
			DataSource = Enums.DataSourcesForExpenseAllocation.RevenueAndCOGS;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	If Obsolete_ Then
		
		AttributesNotToCheck.Add("BaseOfAllocationByLots");
		AttributesNotToCheck.Add("DeferredExpensesWriteOffItem");
		AttributesNotToCheck.Add("DeferredExpensesDimension");
		AttributesNotToCheck.Add("DataSource");
		AttributesNotToCheck.Add("BaseOfAllocationByBusinessUnits");
		AttributesNotToCheck.Add("CostShareForProduction");
		AttributesNotToCheck.Add("Factor");
	Else
		AttributesNotToCheck.Add("AllocationBase");
		
		If Not (AllocateByLots And AllocateToExpenseItems
			And Not (LotsAreSpecifiedInDocument Or BusinessUnitsAreSpecifiedManually)) Then
			AttributesNotToCheck.Add("CostShareForProduction");
		EndIf;
		
		If Not AllocateToBusinessUnits Or BusinessUnitsAreSpecifiedManually Then
			AttributesNotToCheck.Add("BaseOfAllocationByBusinessUnits");
		EndIf;
		
		If (Not AllocateByLots 
				Or LotsAreSpecifiedInDocument)
			And Not AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts Then
			AttributesNotToCheck.Add("BaseOfAllocationByLots");
		EndIf;
		
		ItemsAndDimensionsSelectionParameters = Catalogs.CostAllocationRules.ItemsAndDimensionsSelectionParameters(AssignRule);
		If Not ItemsAndDimensionsSelectionParameters = Undefined Then
			IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, 
				ItemsAndDimensionsSelectionParameters);
		EndIf;
		If Not AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationToDeferredExpenses Then
			
			AttributesNotToCheck.Add("DeferredExpensesWriteOffItem");
			AttributesNotToCheck.Add("DeferredExpensesDimension");
			
		EndIf;
		
		If AllocationDirection = Enums.AllocationDirectionByBusinessUnits.ByRates
			Or Not AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts Then
			AttributesNotToCheck.Add("BaseOfAllocationByLots");
		EndIf;
		
		If AssignRule <> Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult Then
			AttributesNotToCheck.Add("DataSource");
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#EndIf
