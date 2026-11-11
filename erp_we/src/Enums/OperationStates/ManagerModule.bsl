
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The order of States in the lists
// 
// Parameters:
//  State - EnumRef.OperationStates
// 
// Returns:
//  Number
Function OrderInList(State) Export
	
	Result = 0;
	
	If State = Enums.OperationStates.Executed
		Or State = Enums.OperationStates.RolledBack
		Or State = Enums.OperationStates.IsSkipped Then
		Result = 7;
	ElsIf State = Enums.OperationStates.Running
		Or State = Enums.OperationStates.UnderControl
		Or State = Enums.OperationStates.UnderRevision Then
		Result = 6;
	ElsIf State = Enums.OperationStates.ForCompletion Then
		Result = 5;
	ElsIf State = Enums.OperationStates.Assigned_ Then
		Result = 4;
	ElsIf State = Enums.OperationStates.ToAssign Then
		Result = 3;
	ElsIf State = Enums.OperationStates.PreviousOnesAreStarted Then
		Result = 2;
	ElsIf State = Enums.OperationStates.PendingPredecessorCompletion Then
		Result = 1;
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the conditional design of the "State" field in the lists
// 
// Parameters:
//  Form - ClientApplicationForm
//  FieldName - String - field name
//  PathToStateField - String - The Path To The State Field
//  PathToCreatedField - String - The Path To The Created Field
//  
Procedure SetConditionalAppearanceOfState(Form, FieldName = "State", PathToStateField = "Operations.State", PathToCreatedField = Undefined) Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Form.Items[FieldName].Name);
	
	PendingStates = New ValueList();
	PendingStates.Add(Enums.OperationStates.PreviousOnesAreStarted);
	PendingStates.Add(Enums.OperationStates.PendingPredecessorCompletion);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToStateField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = PendingStates;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	If PathToCreatedField <> Undefined Then
		
		For Each ListItem In PendingStates Do
			
			Item = Form.ConditionalAppearance.Items.Add();
			Item.Fields.Items.Add().Field = New DataCompositionField(Form.Items[FieldName].Name);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToStateField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = ListItem.Value;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToCreatedField);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			FieldText = StrTemplate(NStr("vi = '%1 (đã ấn định)';
										|ru = '%1 (уже назначена)';
										|en = '%1 (already assigned)'; fa = '%1 (already assigned)';
										|it = '%1 (already assigned)';
										|pl = '%1 (already assigned)';
										|tr = '%1  (zaten atanmış)'"), String(ListItem.Value));
			Item.Appearance.SetParameterValue("Text", FieldText);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf