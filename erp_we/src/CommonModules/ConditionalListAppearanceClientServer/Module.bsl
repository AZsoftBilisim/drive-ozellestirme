#Region Public

// Adds a conditional design element. Sets the parameter value and the layout selection
// Parameters:
//  Object - ClientApplicationForm, DynamicList - To which you need to add a Conditional appearance
//  NamesOfDesignElements - String, Array of String - Names of form elements to be drawn up. 
//			For example, "Products", "Item, Characteristics", Names = New Array; Names.Add("Item"); Names.Add ("Characteristic");.
//  NameOfLayoutParameter - String, DataCompositionParameter - Indicates what will be changed in the design of the field. For example, "iPhone Color" / "Text" / 
//  ValueOfDesignParameter - Arbitrary - The meaning of the design.
//  		For Example, The New Color Is (222, 255, 222).
//  PathToLeftSelectionValue - String, Undefined - The path to the field where the conditional design is selected. 
//			For example, "Products.Nomenclature" / "Counterparty". If you do not transmit, the selection will not be set.
//			
//  RightFilterValue - Arbitrary - With which to compare the right selection value.
//  TypeOfSelectionComparison - DataCompositionComparisonType - By default, the "Comparison viewcomposed.Equal."
// 
// Returns:
//  DataCompositionConditionalAppearanceItem
//
Function NewDesignElement(Object, NamesOfDesignElements,
	NameOfLayoutParameter, ValueOfDesignParameter,
	PathToLeftSelectionValue, RightFilterValue = Undefined, TypeOfSelectionComparison = Undefined) Export
	
	ConditionalAppearanceItem = NewSimpleDesignElement(Object, NamesOfDesignElements);
	ConditionalAppearanceItem.Appearance.SetParameterValue(NameOfLayoutParameter, ValueOfDesignParameter);
	DataCompositionClientServer.AddFilter(ConditionalAppearanceItem.Filter,
		PathToLeftSelectionValue,
		RightFilterValue,
		TypeOfSelectionComparison);
		
	Return ConditionalAppearanceItem;
EndFunction

// Adds a conditional design element. Sets the value of the layout parameter
// Parameters:
//  Object - ClientApplicationForm, DynamicList - To which you need to add a Conditional appearance
//  NamesOfDesignElements - String, Array of String - Names of form elements to be drawn up. 
//			For example, "Products", "Item, Characteristics", Names = New Array; Names.Add("Item"); Names.Add ("Characteristic");.
//  NameOfLayoutParameter - String, DataCompositionParameter - Indicates what will be changed in the design of the field. For example, "iPhone Color" / "Text" / 
//  ValueOfDesignParameter - Arbitrary - The meaning of the design.
//  		For Example, The New Color Is (222, 255, 222).
// 
// Returns:
//  DataCompositionConditionalAppearanceItem
//
Function NewSimpleDesignElementWithDesignParameter(Object, NamesOfDesignElements,
	NameOfLayoutParameter, ValueOfDesignParameter) Export
	
	ConditionalAppearanceItem = NewSimpleDesignElement(Object, NamesOfDesignElements);
	ConditionalAppearanceItem.Appearance.SetParameterValue(NameOfLayoutParameter, ValueOfDesignParameter);
	
	Return ConditionalAppearanceItem;
EndFunction

// Adds a conditional layout element for a Form element. Sets the selection for registration
// Parameters:
//  Object - ClientApplicationForm, DynamicList - To which you need to add a Conditional appearance
//  NamesOfDesignElements - String, Array of String - Names of form elements to be drawn up. 
//			For example, "Products", "Item, Characteristics", Names = New Array; Names.Add("Item"); Names.Add ("Characteristic");.
//  PathToLeftSelectionValue - String, Undefined - The path to the field where the conditional design is selected. 
//			For example, "Products.Nomenclature" / "Counterparty". If you do not transmit, the selection will not be set.
//			
//  RightFilterValue - Arbitrary - With which to compare the right selection value.
//  TypeOfSelectionComparison - DataCompositionComparisonType - By default, the "Comparison viewcomposed.Equal."
// 
// Returns:
//  DataCompositionConditionalAppearanceItem
//
Function NewSimpleDesignElementWithSelection(Object, NamesOfDesignElements,
	PathToLeftSelectionValue, RightFilterValue = Undefined, TypeOfSelectionComparison = Undefined) Export
	
	ConditionalAppearanceItem = NewSimpleDesignElement(Object, NamesOfDesignElements);
	DataCompositionClientServer.AddFilter(ConditionalAppearanceItem.Filter,
		PathToLeftSelectionValue,
		RightFilterValue,
		TypeOfSelectionComparison);
	
	Return ConditionalAppearanceItem;
	
EndFunction

// Adds a conditional layout element for a Form element
// Parameters:
//  Object - ClientApplicationForm, DynamicList - To which you need to add a Conditional appearance
//  NamesOfDesignElements - String, Array of String - Names of form elements to be drawn up. 
//			For example, "Products", "Item, Characteristics", Names = New Array; Names.Add("Item"); Names.Add ("Characteristic");.
// 
// Returns:
//  DataCompositionConditionalAppearanceItem
//
Function NewSimpleDesignElement(Object, Val NamesOfDesignElements) Export
	
	If TypeOf(NamesOfDesignElements) = Type("String") Then
		NamesOfDesignElements = TMCommonUseClientServer.StringOfNamesInArray(NamesOfDesignElements);
	EndIf;
	
	ConditionalAppearanceItem = Object.ConditionalAppearance.Items.Add();
	For Each FormatElementName In NamesOfDesignElements Do
		DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, FormatElementName);
	EndDo;
	
	Return ConditionalAppearanceItem;
	
EndFunction

// Adds a conditional layout element for an unavailable Form field. Sets the properties "Only View", "Text Color", "Text"
// Parameters:
//  Object - ClientApplicationForm, DynamicList - To which you need to add a Conditional appearance
//  NamesOfDesignElements - String, Array of String - Names of form elements to be drawn up. 
//			For example, "Products", "Item, Characteristics", Names = New Array; Names.Add("Item"); Names.Add ("Characteristic");.
//	TextColor - Color, Undefined - Will be set for the element
//	Text - String, Undefined - Will be set for the element
//  PathToLeftSelectionValue - String, Undefined - The path to the field where the conditional design is selected. 
//			For example, "Products.Nomenclature" / "Counterparty". If you do not transmit, the selection will not be set.
//			
//  RightFilterValue - Arbitrary - With which to compare the right selection value.
//  TypeOfSelectionComparison - DataCompositionComparisonType - By default, the "Comparison viewcomposed.Equal."
// 
// Returns:
//  DataCompositionConditionalAppearanceItem
//
Function NewDesignElementForUnavailableField(Object, NamesOfDesignElements,
	TextColor, Text,
	PathToLeftSelectionValue, RightFilterValue = Undefined, TypeOfSelectionComparison = Undefined) Export
	
	ConditionalAppearanceItem = NewSimpleDesignElementWithSelection(Object,
		NamesOfDesignElements,
		PathToLeftSelectionValue,
		RightFilterValue,
		TypeOfSelectionComparison);
		
	SetLayoutOfInaccessibleField(ConditionalAppearanceItem, TextColor, Text);
	
	Return ConditionalAppearanceItem;
	
EndFunction

// Sets the parameters "Text Color", "Text" and "Only View" for the conditional design element
// 
// Parameters:
//  ConditionalAppearanceItem - DataCompositionConditionalAppearanceItem - to which you need to add the design.
//  TextColor - Color, Undefined - set for the design element.
//  Text - String, Undefined - set for the design element.
Procedure SetLayoutOfInaccessibleField(ConditionalAppearanceItem, TextColor = Undefined, Text = Undefined) Export
	
	Appearance = ConditionalAppearanceItem.Appearance;
	
	If TextColor <> Undefined Then
		Appearance.SetParameterValue("TextColor", TextColor);
	EndIf;
	
	If Text <> Undefined Then
		Appearance.SetParameterValue("Text", Text);
	EndIf;
	
	Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure
#EndRegion

