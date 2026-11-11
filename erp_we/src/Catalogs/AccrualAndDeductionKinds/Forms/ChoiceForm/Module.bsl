
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetSelectionOfTypeOfAccrualsOfDeductions(Parameters);   
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetSelectionOfTypeOfAccrualsOfDeductions(Var_Parameters)
	
	If Var_Parameters.RetentionOnly = True Then
		SetFilterItem(True);
	ElsIf Var_Parameters.AccrualOnly = True Then
		SetFilterItem(False);
	EndIf;
	
	If Var_Parameters.OnlyOneTime Then 
		
		ListOfVisibleInputPeriodicity = New ValueList();
		ListOfVisibleInputPeriodicity.Add(2);
		ListOfVisibleInputPeriodicity.Add(3);
		
		Item = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Item.ComparisonType = DataCompositionComparisonType.InList;
		Item.LeftValue = New DataCompositionField("InputFrequency");
		Item.RightValue = ListOfVisibleInputPeriodicity;

	EndIf;
		
	If Var_Parameters.OnlyPersonnel Then 
		
		ListOfVisibleInputPeriodicity = New ValueList();
		ListOfVisibleInputPeriodicity.Add(0);
		ListOfVisibleInputPeriodicity.Add(1);
		ListOfVisibleInputPeriodicity.Add(2);
		
		Item = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Item.ComparisonType = DataCompositionComparisonType.InList;
		Item.LeftValue = New DataCompositionField("InputFrequency");
		Item.RightValue = ListOfVisibleInputPeriodicity;

	EndIf;
	
EndProcedure

&AtServer
Procedure SetFilterItem(ValueIsHold)
	
	Item = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Item.ComparisonType = DataCompositionComparisonType.Equal;
	Item.LeftValue = New DataCompositionField("ItIsADeduction");
	Item.RightValue = ValueIsHold;

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
		
	If Parameters.RetentionOnly Then
		
		Item = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Item.ComparisonType = DataCompositionComparisonType.Equal;
		Item.LeftValue = New DataCompositionField("ItIsADeduction");
		Item.RightValue = Parameters.RetentionOnly;

		Items.AccrualMethod.Visible = False;
		Items.CalculationFormula.Visible = False;
		
	ElsIf Parameters.AccrualOnly Then
		
		Item = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Item.ComparisonType = DataCompositionComparisonType.Equal;
		Item.LeftValue = New DataCompositionField("ItIsADeduction");
		Item.RightValue = Not Parameters.AccrualOnly;
		
	EndIf;	
	
EndProcedure 

#EndRegion
