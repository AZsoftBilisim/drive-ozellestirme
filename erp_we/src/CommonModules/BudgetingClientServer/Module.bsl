
#Region Public

// The function returns the budget items used by the Analytics, separated by " / "
//
// Parameters:
// 	 DetailsOfBudgetItem - Structure, QueryResultSelection, ValueTableRow  - details of budget items.
//
// Returns:
// 	 String - Performance.
//
Function PresentationOfAnalystBudgets(DetailsOfBudgetItem) Export
	
	Presentation = "";
	
	For DimensionNumber = 1 To DetailsOfBudgetItem.NumberOfUsedDimensions Do
		If ValueIsFilled(DetailsOfBudgetItem["DimensionKind" + DimensionNumber]) Then
			Presentation = Presentation 
				+ ?(Presentation = "", "", " / ") 
				+ DetailsOfBudgetItem["DimensionKind" + DimensionNumber];
		EndIf;
	EndDo;
	
	Return Presentation;
	
EndFunction

// Fills in the representation of the object's value type
//
// Parameters:
// 	 Object - ChartOfCharacteristicTypesObject.BudgetFlowItemDimensions  - the object whose details will be filled in.
//
// Returns:
// 	 String - type representation
//
Function PresentationValueType(Object) Export
	
	PresentationValueType = "";
	
	If ValueIsFilled(Object.AdditionalProperty) Then
		PresentationValueType = String(Object.AdditionalProperty);
	Else
		PresentationValueType = String(Object.ValueType);
	EndIf;
	
	Return PresentationValueType;
	
EndFunction

// Returns the value of the SKD setting.
// 
// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer - The linker settings.
// 	SettingName - String - name of the setting.
// Returns:
// 	Arbitrary - setting value.
Function ValueOfDCSSettings(SettingsComposer, SettingName) Export
	
	For Each UserSetting In SettingsComposer.UserSettings.Items Do
		If TypeOf(UserSetting) = Type("DataCompositionSettingsParameterValue")
			And String(UserSetting.Parameter) = SettingName Then
			Return UserSetting.Value;
		EndIf;
	EndDo;
		
	For Each UserSetting In SettingsComposer.FixedSettings.DataParameters.Items Do
		If String(UserSetting.Parameter) = SettingName Then
			Return UserSetting.Value;
		EndIf;
	EndDo;
		
EndFunction

#Region ConvertingAnalyticsTypes

// Returns the Analytics value converted to the type. The analysis type may or may not include the Undefined type.
// The value will be converted to the original type, without undefined. But if the given value is empty, it is reduced to
// undefined.
//
// Parameters:
// 	DimensionValue - Arbitrary - The value to be cast to the type.
// 	DescriptionOfAnalyticsTypes_ - TypeDescription - Description of the types to cast the value to
// 						But if the given value is empty, it will be cast to Undefined.
//
// Returns:
// 	Arbitrary - The analytics value reduced to the type. If the analytics value is not filled in, it will return Undefined,
// 						regardless of the original type description.
//
Function ReducedAnalyticsValue(Val DimensionValue, Val DescriptionOfAnalyticsTypes_) Export
	
	DimensionValue = DescriptionOfAnalyticsTypes_.AdjustValue(DimensionValue);
	
	If Not ValueIsFilled(DimensionValue) Then
		DimensionValue = EmptyDimensionValue();
	EndIf;
	
	Return DimensionValue;
EndFunction

// Returns an empty value for budget item analytics
//
// Returns:
//  Undefined
//
Function EmptyDimensionValue() Export
	Return Undefined;
EndFunction

// Returns the number of analysts in budgeting
//
// Returns:
// 	Number - The number of analytics supported in budgeting.
//
Function MaximumNumberOfAnalysts() Export
	Return 6;
EndFunction

#EndRegion

// Returns as a string an array of names of budget Attributes for matching the primary budget with its adjustments.
//
// Returns:
//  String
//
Function NamesOfBudgetAttributes() Export
	
	AttributesNames = New Array;
	AttributesNames.Add("BudgetingModel");
	AttributesNames.Add("BudgetProfile");
	AttributesNames.Add("BeginOfPeriod");
	AttributesNames.Add("PeriodEnding");
	AttributesNames.Add("Organization");
	AttributesNames.Add("Department");
	AttributesNames.Add("Scenario");
	For Counter = 1 To MaximumNumberOfAnalysts() Do
		AttributesNames.Add("Dimension" + Counter);
	EndDo;
	AttributesNames.Add("Date");
	
	Return StrConcat(AttributesNames, ",");
	
EndFunction

#EndRegion
