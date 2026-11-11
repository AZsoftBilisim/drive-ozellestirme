
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ConfigureSelectionsOnForm();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ConfigureSelectionsOnForm()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Enums.BudgetingRuleStatuses.Valid,
		DataCompositionComparisonType.Equal,
		,
		True);
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("FormationOfBudgetTurnover") And Parameters.Filter.FormationOfBudgetTurnover Then
			
			FilterElement = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField("RecordCalculationInPlanningDocuments");
			FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
			FilterElement.RightValue = False;
			FilterElement.Use = True;
			
			FilterOrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterOrGroup.Use = True;
			FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			FilterOrGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			
			FilterElement = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField("Receiver.IndicatorType");
			FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
			FilterElement.Use = True;
			
			FilterElement = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField("Receiver.IndicatorType");
			FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
			FilterElement.RightValue = Enums.BudgetBalanceItemType.SpecialPurpose;
			FilterElement.Use = True;
			
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion