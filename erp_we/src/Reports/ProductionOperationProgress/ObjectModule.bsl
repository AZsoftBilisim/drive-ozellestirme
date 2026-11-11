#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnLoadVariantAtServer = True;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
// 
// Parameters:
// 	Form - ClientApplicationForm -
// 	NewDCSettings - DataCompositionSettings -
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	If Form.Parameters.Property("CommandParameter") Then
		
		Parameter = Form.Parameters.CommandParameter;
		
		If TypeOf(Parameter) = Type("DocumentRef.ProductionStage2_2") Then
			
			DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(
				Common.ObjectAttributeValue(Parameter, "Department"));
			
			If Not DivisionParameters.UseShiftTasks Then
				
				RemoveChangeableJobFromLayoutSettings(Form);
				
			EndIf;
			
		EndIf;
		
	EndIf;	
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	If Form.Parameters.Property("CommandParameter") Then
		
		Parameter = Form.Parameters.CommandParameter;
		
		If TypeOf(Parameter) = Type("DocumentRef.ProductionStage2_2") Then
			
			Form.ParametersForm.Filter.Insert("Stage", Parameter);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
// 
// Parameters:
// 	Form - ClientApplicationForm -
// 	NewDCUserSettings - DataCompositionUserSettings - 
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	If Form.Parameters.Property("CommandParameter") Then
		
		Parameter = Form.Parameters.CommandParameter;
		
		If TypeOf(Parameter) = Type("DocumentRef.ProductionStage2_2") Then
			
			DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(
				Common.ObjectAttributeValue(Parameter, "Department"));
			
			If Not DivisionParameters.UseShiftTasks Then
				
				RemoveChangeableJobFromLayoutSettings(Form);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure RemoveChangeableJobFromLayoutSettings(Form)
	
	Settings = SettingsComposer.Settings;
	
	// Date of the task
	Field = New DataCompositionField("TaskDate_");
	MatchingElements = New Map;
	
	FindGroupingRecursively(Settings.Structure, MatchingElements, Field);
	For Each Group In MatchingElements Do
		
		Var_Key = Group.Key;//DataCompositionTableGroup, DataCompositionGroup -
		
		If Var_Key.GroupFields.Items.Count() = 1 Then
			Var_Key.Parent.Structure.Delete(Group.Key);
		Else
			Var_Key.GroupFields.Items.Delete(Group.Value);
		EndIf;
		
		DeleteSelectedField(Var_Key.Selection, Field, Settings);
		
	EndDo;
	
	DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Settings, "TaskDate_");
	
EndProcedure

Procedure FindGroupingRecursively(ItemsCollection, MatchingElements, SearchValue)
	
	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionGroup")
			Or TypeOf(Item) = Type("DataCompositionTableGroup") Then
			For Each GroupingField In Item.GroupFields.Items Do 
				If GroupingField.Field = SearchValue Then
					MatchingElements.Insert(Item, GroupingField)
				EndIf;
			EndDo;
			FindGroupingRecursively(Item.Structure, MatchingElements, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			FindGroupingRecursively(Item.Rows, MatchingElements, SearchValue);
			FindGroupingRecursively(Item.Columns, MatchingElements, SearchValue);
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	SelectedFields - DataCompositionSelectedFields -
// 	SearchValue - DataCompositionField -
// 	Settings - DataCompositionSettings -
Procedure DeleteSelectedField(SelectedFields, SearchValue, Settings)
	
	ItemArray = New Array;// Array of DataCompositionSelectedField - 
	
	FindSelectedFieldRecursively(SelectedFields.Items, ItemArray, SearchValue);
	For Each Item In ItemArray Do
		
		IDOfElementSCustomSetting = Settings.Selection.GetIDByObject(Item);;
		If Item.Parent <> Undefined Then
			Item.Parent.Items.Delete(Item);
		Else
			SelectedFields.Items.Delete(Item);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FindSelectedFieldRecursively(ItemsCollection, ItemArray, SearchValue)

	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Field = SearchValue Then
				ItemArray.Add(Item);
			EndIf;
		ElsIf TypeOf(Item) = Type("DataCompositionAutoSelectedField") Then
			Continue;
		Else
			FindSelectedFieldRecursively(Item.Items, ItemArray, SearchValue);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf