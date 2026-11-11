////////////////////////////////////////////////////////////////////////////////
// Client procedures and functions (cached) that control system settings.
//
////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Shape properties.
// 
// Parameters:
//  FormName - String - form name
// 
// Returns:
//  See SystemSettingsClient.FormPropertyConstructor
Function ShapeProperties(FormName) Export
	
	//@skip-check use-non-recommended-method
	Form = GetForm(FormName);
	ShapeProperties = SystemSettingsClient.FormPropertyConstructor();
	
	If Form = Undefined Then
		Return ShapeProperties;
	EndIf;
	
	ColorExplanatoryText = CommonClientCached.StyleColor("NoteText");
	
	Items = ShapeProperties.Items;
	ShapeProperties.NameOfFormAsString = New FormattedString(Form.FormName,, CommonClientCached.StyleColor("UnavailableData"));
	
	For Each FormItem In Form.Items Do
		SystemSettingsClient.AddFormItem(Items, FormItem, ColorExplanatoryText);
	EndDo;
	
	Return ShapeProperties
EndFunction

// Form elements by line.
// 
// Parameters:
//  SearchString - String - search string
//  FormName - String -form name
// 
// Returns:
//  See SystemSettingsClient.FindItemsByRow
Function FormElementsByLine(SearchString, FormName) Export
	
	Form = SystemSettingsClientCached.ShapeProperties(FormName);
	Result = New Array();
	
	If Not ValueIsFilled(Form.NameOfFormAsString) Then
		Return Result;
	EndIf;
	
	SearchIndex = SystemSettingsClient.AdditionalSettingsSearchIndex().Get(FormName);
	Result = SystemSettingsClient.FindItemsByRow(SearchString, Form.Items, Form.NameOfFormAsString, SearchIndex);
	
	Return Result;
	
EndFunction

#EndRegion
