
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AttributeName = Parameters.AttributeName;
	
	For Each ListItem In Parameters.FilterValue Do
		NewRow = FilterValuesList.Add();
		NewRow.Check = True;
		NewRow.FilterValue = ListItem.Value;
	EndDo;	
	
	Query = New Query;
	If Not Parameters.IsAddlAttribute Then
		
		Query.Text = 
		"SELECT TOP 1
		|	Products." + AttributeName + " AS AttributeValue
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.ProductKind = &ProductKind
		|	AND Products." + AttributeName + " <> """"
		|	";
		
	ElsIf Parameters.FilterRemainingGoodsByShelfLives Then
		
		Query.Text =
		"SELECT TOP 1
		|	AdditionalAttributes.Value AS AttributeValue,
		|	AdditionalAttributes.Property AS Property
		|FROM
		|	Catalog.Products.AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	AdditionalAttributes.Property.Title = &Property
		|	AND AdditionalAttributes.Ref.ProductKind = &ProductKind";
		
	ElsIf Not Parameters.FilterRemainingGoodsByShelfLives Then
		
		Query.Text =
		"SELECT TOP 1
		|	CharacteristicsAdditionalDetails_.Value AS AttributeValue,
		|	CharacteristicsAdditionalDetails_.Property AS Property
		|FROM
		|	Catalog.ItemsCharacteristics.AdditionalAttributes AS CharacteristicsAdditionalDetails_
		|WHERE
		|	CharacteristicsAdditionalDetails_.Property.Title = &Property
		|	AND CASE
		|			WHEN VALUETYPE(CharacteristicsAdditionalDetails_.Ref.Owner) = TYPE(Catalog.ItemKinds)
		|				THEN CharacteristicsAdditionalDetails_.Ref.Owner = &ProductKind
		|			ELSE CharacteristicsAdditionalDetails_.Ref.Owner.ProductKind = &ProductKind
		|		END";
		
	EndIf;
	Query.SetParameter("Property", AttributeName);
	Query.SetParameter("ProductKind", Parameters.ProductKind);
	Selection = Query.Execute().Select();
	Selection.Next();
	ValueTypeFilter = TypeOf(Selection.AttributeValue);
	
	If ValueTypeFilter = Type("CatalogRef.ObjectsPropertiesValues") Then
		
		ParametersArray = New Array();
		NewParameter1 = New ChoiceParameter("Filter.Owner", Selection.Property);
		ParametersArray.Add(NewParameter1);
		
		Items.FilterValuesListFilterValue.ChoiceParameters = New FixedArray(ParametersArray);
		OwnerFilter = Selection.Property;
	EndIf;
	
	FullObjectName = Metadata.FindByType(ValueTypeFilter).FullName();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ValueIsFilled(ValueSelected) Then
		For Each Value In ValueSelected Do
			NewRow = FilterValuesList.Add();
			NewRow.FilterValue = Value;
			NewRow.Check = True;
		EndDo;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	IncorrectInterval = False;
	
	FilterValue = New ValueList;
	For Each ValueListItem In FilterValuesList Do
		If ValueListItem.Check 
			And ValueIsFilled(ValueListItem.FilterValue)
			And FilterValue.FindByValue(ValueListItem.FilterValue) = Undefined Then
			FilterValue.Add(ValueListItem.FilterValue);
		EndIf;	
	EndDo;
	
	ReturnStructure = New Structure("FilterValue", FilterValue);
	
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure FilterValuesListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If Copy Then
		Return;
	EndIf;
	
	NewRow = FilterValuesList.Add();
	NewRow.Check = True;
	NewRow.FilterValue = New (ValueTypeFilter);
	                                
	RowsCount = FilterValuesList.Count();
	Items.FilterValuesList.CurrentRow =  FilterValuesList[RowsCount - 1].GetID();
	
	Cancel = True;
	       
EndProcedure

&AtClient
Procedure Pick(Command)
	
	If ValueIsFilled(OwnerFilter) Then
		Filter = New Structure("Owner", OwnerFilter);
		FormParameters = New Structure;
		FormParameters.Insert("CloseOnChoice",False);
		FormParameters.Insert("MultipleChoice",True);
		FormParameters.Insert("ChoiceMode",True);
		FormParameters.Insert("Filter",Filter);
	Else
		FormParameters = New Structure("CloseOnChoice, MultipleChoice, ChoiceMode", False, True, True);
	EndIf;
	
	OpenForm(FullObjectName + ".ChoiceForm",FormParameters,ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion
