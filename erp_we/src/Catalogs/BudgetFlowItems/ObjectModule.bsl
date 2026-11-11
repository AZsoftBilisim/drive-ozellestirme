#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	BudgetingServer.FillInAuxiliaryDetailsBeforeRecording(ThisObject);
	
	If Not IsNew() Then
		ComparisonAttributes = StrSplit("Code,Description,LongDesc", ",");
		InitialValuesOfDetails = Common.ObjectAttributesValues(Ref, ComparisonAttributes);
		For Each ComparisonProps In ComparisonAttributes Do
			If ThisObject[ComparisonProps] <> InitialValuesOfDetails[ComparisonProps] Then
				AdditionalProperties.Insert("UpdateElementsOfFinancialStatements", Description);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not IsFolder Then
		
		If RecordByQuantity Then
			If UnitOfMeasureIsDeterminedByDimension Then
				CheckedAttributes.Add("DimensionUnitsOfMeasurement");
			Else
				CheckedAttributes.Add("UnitOfMeasure");
			EndIf;
		EndIf;
		
		If RecordByCurrency Then
			If CurrencyIsDeterminedByDimension Then
				CheckedAttributes.Add("DimensionCurrencies");
			EndIf;
		EndIf;
		
		BudgetingServer.CheckCompletionOfAnalyticsCurrencyUnitsOfMeasurement(ThisObject, Cancel);
		BudgetingServer.CheckAnalyticsCompletionByItem(ThisObject, Cancel);
		
		NotCheckedAttributeArray = New Array;
		
		If Not Catalogs.AccessGroupsOfBudgetFlowItemsAndIndicators.AccessGroupsAreUsed() Then
			NotCheckedAttributeArray.Add("AccessGroup");
		EndIf;
		
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	If IsFolder Then
		Return;
	EndIf;
	
	// Let's update the analytics filling expressions
	Query = New Query;
	Query.Text = "SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	NOT ActualDataQueryRulesByBudgetFlowItems.AdvancedModeOfDimensionFillSetting
	|	AND ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem = &BudgetFlowItem";
	Query.SetParameter("BudgetFlowItem", Ref);
	
	Selection = Query.Execute().Select();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ActualDataQueryRulesByBudgetFlowItems");
	LockItem.SetValue("BudgetFlowItem", Ref);
	Block.Lock();
	
	While Selection.Next() Do
	
		RuleObject_ = Selection.Ref.GetObject();
		RuleObject_.Lock();
		RuleObject_.Write();
	
	EndDo;
	
	If AdditionalProperties.Property("UpdateElementsOfFinancialStatements") Then
		Catalogs.FinancialReportItems.UpdateTitlesForPrinting(Ref, Description);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
