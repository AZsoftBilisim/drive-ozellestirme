////////////////////////////////////////////////////////////////////////////////
// Contains procedures and functions for working with reports.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Adds the report period to the selection values.
//
// Parameters:
//  DataCompositionSettings - DataCompositionSettings - SKD settings.
//  DataSelectionValues - Structure - The value of the selection.
//
Procedure ReportPeriod(DataCompositionSettings, DataSelectionValues) Export

	ReportParameter_ = ParameterValue(DataCompositionSettings, "ReportPeriod"); // StandardPeriod - 
	
	If ReportParameter_ <> Undefined Then
		DataSelectionValues.Insert("BeginOfPeriod", ReportParameter_.StartDate);
		DataSelectionValues.Insert("PeriodEnding", ReportParameter_.EndDate);
	Else
		DataSelectionValues.Insert("BeginOfPeriod", '000101010000');
		DataSelectionValues.Insert("PeriodEnding", '000101010000');
	EndIf; 
	
EndProcedure

// Gets the value of the SKD parameter.
//
// Parameters:
//  DataCompositionSettings - DataCompositionSettings - SKD settings.
//  Parameter - String, DataCompositionParameter	 - field or name of the field to return the parameter for.
//  EmptyValue - Arbitrary - The value to return if the parameter is not used.
// 
// Returns:
//  Arbitrary - The value of the SKD parameter.
//
Function ParameterValue(DataCompositionSettings, Parameter, EmptyValue = Undefined) Export

	ReportParameter_ = DataCompositionClientServer.GetParameter(DataCompositionSettings, Parameter);
	
	If ReportParameter_ <> Undefined And ReportParameter_.Use Then
		Return ReportParameter_.Value;
	Else
		Return EmptyValue;
	EndIf;

EndFunction

// Returns the value of the selection set in the report
//
// Parameters:
//  FieldName	- String - Name of the selection.
//  FilterItems1- DataCompositionFilterItemCollection - selecting the data layout.
// 
// Returns:
//  Array of Arbitrary - Established selection.
//
Function FilterValue(FieldName, FilterItems1) Export

	ArrayOfSelectionValues = New Array;
	
	If FilterItems1 = Undefined Then
		Return ArrayOfSelectionValues;
	EndIf;
	
	Field = New DataCompositionField(FieldName);
	
	FilterValue = Undefined;
	For Each CollectionItem In FilterItems1 Do
		If TypeOf(CollectionItem) = Type("DataCompositionFilterItem") 
			And CollectionItem.LeftValue = Field 
			And CollectionItem.Use Then
			
			FilterValue = CollectionItem.RightValue;
			Break;
		EndIf; 
	EndDo; 
	
	If FilterValue <> Undefined And TypeOf(FilterValue) = Type("ValueList") Then
		ArrayOfSelectionValues = FilterValue.UnloadValues();
	ElsIf FilterValue <> Undefined Then
		ArrayOfSelectionValues.Add(FilterValue);
	EndIf;
	
	Return ArrayOfSelectionValues;

EndFunction

#EndRegion
