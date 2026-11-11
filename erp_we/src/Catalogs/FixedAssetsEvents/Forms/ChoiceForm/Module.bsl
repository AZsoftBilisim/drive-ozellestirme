
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	FillInSelections();
	SetFilters(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterEventKindOnChange(Item)
	
	SetFilters(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	FormParameters = New Structure;
	
	If Copy Then
		FormParameters.Insert("CopyingValue", Items.List.CurrentData.Ref);
	EndIf;
	
	FillingValues = New Structure;
	For Each FilterElement In List.Filter.Items Do
		
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		If FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			FillingValues.Insert(String(FilterElement.LeftValue), FilterElement.RightValue);
		EndIf;
		
		If FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			FillingValues.Insert(String(FilterElement.LeftValue), FilterElement.RightValue[0].Value);
		EndIf;
		
	EndDo;
	
	FormParameters.Insert("FillingValues", FillingValues);
	
	EventTypeFAAvailableValues = GetAvailableFAEventViewValues();
	
	If EventTypeFAAvailableValues.Count() > 0 Then
		FormParameters.Insert("EventTypeFAAvailableValues", EventTypeFAAvailableValues)
	EndIf;
	
	OpenForm("Catalog.FixedAssetsEvents.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", Item.CurrentRow);
	
	EventTypeFAAvailableValues = GetAvailableFAEventViewValues();
	
	If EventTypeFAAvailableValues.Count() > 0 Then
		FormParameters.Insert("EventTypeFAAvailableValues", EventTypeFAAvailableValues)
	EndIf;
	
	OpenForm("Catalog.FixedAssetsEvents.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function GetAvailableFAEventViewValues()
	
	ContractTypeAvailableValues = New Array;
	
	For Each FilterElement In List.Filter.Items Do
		
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		If String(FilterElement.LeftValue) <> "EventKindWithFixedAssets" Then
			Continue;
		EndIf;
		
		If FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			ContractTypeAvailableValues.Add(FilterElement.RightValue);
		EndIf;
		
		If FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			For Each ValueListItem In FilterElement.RightValue Do
				ContractTypeAvailableValues.Add(ValueListItem.Value);
			EndDo;
		EndIf;
		
	EndDo;
	
	Return ContractTypeAvailableValues;
	
EndFunction

&AtServer
Procedure FillInSelections()
	
	If Not Parameters.Property("Filter") Then
		Return;
	EndIf;
	
	If Parameters.Filter.Property("EventKindWithFixedAssets") Then
		
		If TypeOf(Parameters.Filter.EventKindWithFixedAssets) = Type("Array")
			Or TypeOf(Parameters.Filter.EventKindWithFixedAssets) = Type("FixedArray") Then
		
			For Each Item In Parameters.Filter.EventKindWithFixedAssets Do
				FilterEventKind.Add(Item);
			EndDo;	
			
		ElsIf TypeOf(Parameters.Filter.EventKindWithFixedAssets) = Type("ValueList") Then
		
			For Each Item In Parameters.Filter.EventKindWithFixedAssets Do
				FilterEventKind.Add(Item.Value);
			EndDo;	
			
		ElsIf TypeOf(Parameters.Filter.EventKindWithFixedAssets) = Type("EnumRef.EventKindsWithFixedAssets") Then
		
			FilterEventKind.Add(Parameters.Filter.EventKindWithFixedAssets);
			
		EndIf;
		
		Parameters.Filter.Delete("EventKindWithFixedAssets");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilters(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"EventKindWithFixedAssets", 
		Form.FilterEventKind, 
		DataCompositionComparisonType.InList,,
		ValueIsFilled(Form.FilterEventKind));
	
EndProcedure

#EndRegion
