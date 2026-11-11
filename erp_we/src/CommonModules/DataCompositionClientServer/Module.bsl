#Region Public

// Copies items from one collection to another
//
// Parameters:
//	ValueReceiver	- collection of CD elements where parameters are copied
//	ValueSource	- collection of CD elements from which parameters are copied
//	CleaningReceiver		- indicates whether the receiver needs to be cleared (Boolean, default: true)
//
Procedure CopyElements(ValueReceiver, ValueSource, CleaningReceiver = True) Export
	
	If TypeOf(ValueSource) = Type("DataCompositionConditionalAppearance")
		Or TypeOf(ValueSource) = Type("DataCompositionUserFieldsCaseVariants")
		Or TypeOf(ValueSource) = Type("DataCompositionAppearanceFields")
		Or TypeOf(ValueSource) = Type("DataCompositionDataParameterValues") Then
		CreateByType = False;
	Else
		CreateByType = True;
	EndIf;
	ReceiverOfElements = ValueReceiver.Items;
	SourceOfElements = ValueSource.Items;
	If CleaningReceiver Then
		ReceiverOfElements.Clear();
	EndIf;
	
	For Each SourceItem In SourceOfElements Do
		
		If TypeOf(SourceItem) = Type("DataCompositionOrderItem") Then
			// We add the elements of the order to the beginning
			IndexOf = SourceOfElements.IndexOf(SourceItem);
			DestinationItem = ReceiverOfElements.Insert(IndexOf, TypeOf(SourceItem));
		Else
			If CreateByType Then
				DestinationItem = ReceiverOfElements.Add(TypeOf(SourceItem));
			Else
				DestinationItem = ReceiverOfElements.Add();
			EndIf;
		EndIf;
		
		FillPropertyValues(DestinationItem, SourceItem);
		// In some collections it is necessary to fill in other collections
		If TypeOf(SourceOfElements) = Type("DataCompositionConditionalAppearanceItemCollection") Then
			CopyElements(DestinationItem.Fields, SourceItem.Fields);
			CopyElements(DestinationItem.Filter, SourceItem.Filter);
			FillInElements(DestinationItem.Appearance, SourceItem.Appearance); 
		ElsIf TypeOf(SourceOfElements)	= Type("DataCompositionUserFieldCaseVariantCollection") Then
			CopyElements(DestinationItem.Filter, SourceItem.Filter);
		EndIf;
		
		// In some elements of the collection, you need to fill in other collections
		If TypeOf(SourceItem) = Type("DataCompositionFilterItemGroup") Then
			CopyElements(DestinationItem, SourceItem);
		ElsIf TypeOf(SourceItem) = Type("DataCompositionSelectedFieldGroup") Then
			CopyElements(DestinationItem, SourceItem);
		ElsIf TypeOf(SourceItem) = Type("DataCompositionUserFieldCase")
			    And TypeOf(DestinationItem) = Type("DataCompositionUserFieldCase") Then
			CopyElements(DestinationItem.Variants, SourceItem.Variants);
		ElsIf TypeOf(SourceItem) = Type("DataCompositionUserFieldExpression") Then
			DestinationItem.SetDetailRecordExpression (SourceItem.GetDetailRecordExpression());
			DestinationItem.SetTotalRecordExpression(SourceItem.GetTotalRecordExpression());
			DestinationItem.SetDetailRecordExpressionPresentation(SourceItem.GetDetailRecordExpressionPresentation ());
			DestinationItem.SetTotalRecordExpressionPresentation(SourceItem.GetTotalRecordExpressionPresentation ());
		EndIf;
		
	EndDo;
	
EndProcedure

// Populates one collection of items based on another
//
// Parameters:
//	ValueReceiver	- collection of CD elements where parameters are copied
//	ValueSource	- collection of CD elements from which parameters are copied
//	FirstLevel		- the level of the structure of the collection of CD elements for copying parameters
//
Procedure FillInElements(ValueReceiver, ValueSource, FirstLevel = Undefined) Export
	
	If TypeOf(ValueReceiver) = Type("DataCompositionParameterValueCollection") Then
		ValueCollection = ValueSource;
	Else
		ValueCollection = ValueSource.Items;
	EndIf;
	
	For Each SourceItem In ValueCollection Do
		If FirstLevel = Undefined Then
			DestinationItem = ValueReceiver.FindParameterValue(SourceItem.Parameter);
		Else
			DestinationItem = FirstLevel.FindParameterValue(SourceItem.Parameter);
		EndIf;
		If DestinationItem = Undefined Then
			Continue;
		EndIf;
		FillPropertyValues(DestinationItem, SourceItem);
		If TypeOf(SourceItem) = Type("DataCompositionParameterValue") Then
			If SourceItem.NestedParameterValues.Count() <> 0 Then
				FillInElements(DestinationItem.NestedParameterValues, SourceItem.NestedParameterValues, ValueReceiver);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds a new field to the collection of data layout fields that are being designed
//
// Parameters:
//	CollectionOfGeneratedFields 	- DataCompositionAppearanceFields - collection of formalized CD fields
//	FieldName						- String - field name
//
// Returns:
//	DataCompositionAppearanceField - created field
//
// Example:
// 	Form.Conditional form.Elements[0].Fields
//
Function AddFieldToCreate(CollectionOfGeneratedFields, FieldName) Export
	
	ItemField 		= CollectionOfGeneratedFields.Items.Add();
	ItemField.Field 	= New DataCompositionField(FieldName);

	Return ItemField;
	
EndFunction

// Adds a new group of the specified type to the selection collection.
//
// Parameters:
//	CollectionOfSelectionElements - DataCompositionFilterItemCollection 
//	GroupType - DataCompositionFilterItemsGroupType - GroupaI or GroupaIly
//
// Returns:
//	DataCompositionFilterItemGroup - added group
//
Function AddSelectionGroup(CollectionOfSelectionElements, GroupType) Export

	FilterItemsGroup			 = CollectionOfSelectionElements.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType  = GroupType;
	
	Return FilterItemsGroup;

EndFunction

// Adds the selected field from the layout data
//
// Parameters:
//	Var_To - DataCompositionSettingsComposer, DataCompositionSettings, DataCompositionSelectedFields - the destination where you want to add the field
//	DCNameOrField - String, DataCompositionField - name of the field to add
//	Title - String - title of the field in the layout result.
//
// Returns:
//	DataCompositionSelectedField - the selected field.
//
Function AddSelectedField(Var_To, DCNameOrField, Title = "") Export
	
	If TypeOf(Var_To) = Type("DataCompositionSettingsComposer") Then
		SelectedDCFields = Var_To.Settings.Selection;
	ElsIf TypeOf(Var_To) = Type("DataCompositionSettings") Then
		SelectedDCFields = Var_To.Selection;
	Else
		SelectedDCFields = Var_To;
	EndIf;
	
	If TypeOf(DCNameOrField) = Type("String") Then
		DCField = New DataCompositionField(DCNameOrField);
	Else
		DCField = DCNameOrField;
	EndIf;
	
	SelectedDCField = SelectedDCFields.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = DCField;
	If Title <> "" Then
		SelectedDCField.Title = Title;
	EndIf;
	
	Return SelectedDCField;
	
EndFunction

// Adds a grouping in the settings Builder to the lowest level of the structure, if the field is not specified - detailed fields.
//
// Parameters:
//	SettingsComposer - DataCompositionSettingsComposer, DataCompositionSettings - element of the CD structure.
//	Field - String, DataCompositionField - the name of the field or KD
//	Rows - Boolean - flag for getting the latest grouping of rows (Series) or columns (points)
//	GroupingParameters - Structure - structure with properties:
//		*BeginOfPeriod - Date - start of the grouping period by the period field.
//		*EndOfPeriod - Date - end of the grouping period by period field.
//		*GroupType - DataCompositionGroupType - type of grouping.
//		*AdditionType - DataCompositionPeriodAdditionType - type of extension.
//
// Returns:
//	DataCompositionTableGroup, DataCompositionChartGroup, DataCompositionGroup - a new grouping.
//
Function AddGrouping(SettingsComposer, Val Field = Undefined, Rows = True, GroupingParameters = Undefined) Export
	
	If GroupingParameters = Undefined Then
		GroupingParameters = New Structure("BeginOfPeriod, EndOfPeriod, GroupType, AdditionType");
	EndIf;
	
	StructureItem = GetLastElementOfStructure(SettingsComposer, Rows);
	If StructureItem = Undefined 
		Or GetDetailedRecordsStructureElement(SettingsComposer) <> Undefined 
		And Field = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(Field) = Type("String") Then
		Field = New DataCompositionField(Field);
	EndIf;
	
	If TypeOf(StructureItem) = Type("DataCompositionTableGroup") 
	 Or TypeOf(StructureItem) = Type("DataCompositionChartGroup") Then
		NewGrouping = StructureItem.Structure.Add();
	ElsIf TypeOf(StructureItem) = Type("DataCompositionTableStructureItemCollection")
			Or TypeOf(StructureItem) = Type("DataCompositionChartStructureItemCollection") Then
		NewGrouping = StructureItem.Add();
	Else
		NewGrouping = StructureItem.Structure.Add(Type("DataCompositionGroup"));
	EndIf;
	
	NewGrouping.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	NewGrouping.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	If Field <> Undefined Then
		GroupingField = NewGrouping.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Field = Field;
		
		If GroupingParameters.BeginOfPeriod <> Undefined 
			And TypeOf(GroupingParameters.BeginOfPeriod) = Type("Date") Then
			GroupingField.BeginOfPeriod = GroupingParameters.BeginOfPeriod;
		EndIf;
		If GroupingParameters.EndOfPeriod <> Undefined 
			And TypeOf(GroupingParameters.EndOfPeriod) = Type("Date") Then
			GroupingField.EndOfPeriod = GroupingParameters.EndOfPeriod;
		EndIf;
		If GroupingParameters.GroupType <> Undefined 
			And TypeOf(GroupingParameters.GroupType) = Type("DataCompositionGroupType") Then
			GroupingField.GroupType = GroupingParameters.GroupType;
		EndIf;
		If GroupingParameters.AdditionType <> Undefined 
			And TypeOf(GroupingParameters.AdditionType) = Type("DataCompositionPeriodAdditionType") Then
			GroupingField.AdditionType = GroupingParameters.AdditionType;
		EndIf;
	EndIf;
	Return NewGrouping;
	
EndFunction

// Adds grouping in the settings Builder to the root level of the settings structure, if the field is not specified - detailed fields.
//
// Parameters:
//	SettingsComposer - DataCompositionSettingsComposer, DataCompositionSettings - CD structure element
//	Field - String, DataCompositionField - name or field of the data layout.
//	GroupingParameters - Structure - structure with properties:
//		*BeginOfPeriod - Date - start of the grouping period by the period field.
//		*EndOfPeriod - Date - end of the grouping period by period field.
//		*GroupType - DataCompositionGroupType - type of grouping.
//		*AdditionType - DataCompositionPeriodAdditionType - type of extension.
//
// Returns:
//	DataCompositionTableGroup, DataCompositionChartGroup, DataCompositionGroup - a new grouping at the root of the structure.
//
Function AddGroupingToStructureRoot(SettingsComposer, Val Field = Undefined, GroupingParameters = Undefined) Export
	
	If GroupingParameters = Undefined Then
		GroupingParameters = New Structure("BeginOfPeriod, EndOfPeriod, GroupType, AdditionType");
	EndIf;
	
	If Field = Undefined Then
		Return Undefined;
	EndIf;
	
	StructureItem = SettingsComposer.Settings;
	
	If TypeOf(Field) = Type("String") Then
		Field = New DataCompositionField(Field);
	EndIf;
	
	NewGrouping = StructureItem.Structure.Add(Type("DataCompositionGroup"));
	
	NewGrouping.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	NewGrouping.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	If Field <> Undefined Then
		GroupingField = NewGrouping.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Field = Field;
		
		If GroupingParameters.BeginOfPeriod <> Undefined 
			And TypeOf(GroupingParameters.BeginOfPeriod) = Type("Date") Then
			GroupingField.BeginOfPeriod = GroupingParameters.BeginOfPeriod;
		EndIf;
		If GroupingParameters.EndOfPeriod <> Undefined 
			And TypeOf(GroupingParameters.EndOfPeriod) = Type("Date") Then
			GroupingField.EndOfPeriod = GroupingParameters.EndOfPeriod;
		EndIf;
		If GroupingParameters.GroupType <> Undefined 
			And TypeOf(GroupingParameters.GroupType) = Type("DataCompositionGroupType") Then
			GroupingField.GroupType = GroupingParameters.GroupType;
		EndIf;
		If GroupingParameters.AdditionType <> Undefined 
			And TypeOf(GroupingParameters.AdditionType) = Type("DataCompositionPeriodAdditionType") Then
			GroupingField.AdditionType = GroupingParameters.AdditionType;
		EndIf;
	EndIf;
	Return NewGrouping;
	
EndFunction

// Adds a selection to the linker's selection collection or selection group
//
// Parameters:
//	StructureItem - DataCompositionSettingsComposer, DataCompositionSettings - element of the data layout structure.
//	Field - String - name of the field to add the selection to.
//	Value - Arbitrary - value for selecting the data layout.
//	Var_ComparisonType - DataCompositionComparisonType - type of CD comparisons (default: Undefined).
//	Use - Boolean - indicates whether selection is used (default: True).
//	AdditionalParameters - Structure - structure with properties:
//		*ToUserSettings - Boolean - flag for adding data layout to user settings (default: false).
//		*ReplaceCurrent - Boolean - indicates whether the existing selection by field is completely replaced (default: True).
//
// Returns:
//	DataCompositionFilterItem - added selection.
//
Function AddFilter(StructureItem, Val Field, Value = Undefined, Var_ComparisonType = Undefined, Use = True, AdditionalParameters = Undefined) Export
		
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure("ToUserSettings, ReplaceCurrent", False, True); 
	Else
		If Not AdditionalParameters.Property("ToUserSettings") Then
			AdditionalParameters.Insert("ToUserSettings", False);
		EndIf;
		If Not AdditionalParameters.Property("ReplaceCurrent") Then
			AdditionalParameters.Insert("ReplaceCurrent", True);
		EndIf;
	EndIf;
	
	If TypeOf(Field) = Type("String") Then
		Field = New DataCompositionField(Field);
	EndIf;
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filter = StructureItem.Settings.Filter;
		
		If AdditionalParameters.ToUserSettings Then
			For Each SettingItem In StructureItem.UserSettings.Items Do
				If SettingItem.UserSettingID = StructureItem.Settings.Filter.UserSettingID Then
					Filter = SettingItem;
				EndIf;
			EndDo;
		EndIf;
		
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Filter = StructureItem.Filter;
	Else
		Filter = StructureItem;
	EndIf;
	
	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;
	
	FilterElement = Undefined;
	If AdditionalParameters.ReplaceCurrent Then
		For Each Item In Filter.Items Do
			
			If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
				Continue;
			EndIf;
			
			If Item.LeftValue = Field Then
				FilterElement = Item;
			EndIf;
			
		EndDo;
	EndIf;
	
	If FilterElement = Undefined Then
		FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
	EndIf;
	FilterElement.Use		= Use;
	FilterElement.LeftValue		= Field;
	FilterElement.ComparisonType		= Var_ComparisonType;
	FilterElement.RightValue	= Value;
	
	Return FilterElement;
	
EndFunction

// Clears all data layout configuration elements from the object
// Parameters:
//  Settings - DataCompositionSettings - settings to clear.
//
Procedure ClearDataLayoutSettings(Settings) Export
	
	If Settings = Undefined Or TypeOf(Settings) <> Type("DataCompositionSettings") Then
		Return;
	EndIf;
	
	For Each Parameter In Settings.DataParameters.Items Do
		Parameter.Value = Undefined;
		Parameter.Use = False;
	EndDo;
	
	For Each Parameter In Settings.OutputParameters.Items Do
		Parameter.Use = False;
	EndDo;
	
	Settings.UserFields.Items.Clear();
	Settings.Filter.Items.Clear();
	Settings.Order.Items.Clear();
	Settings.Selection.Items.Clear();
	Settings.Structure.Clear();
	
EndProcedure

// Disables displaying vertical and horizontal totals in the root element
// Parameters:
//  Settings - DataCompositionSettings - change the settings.
//
Procedure DisableOutputOfTotals(Settings) Export
	
	SetOutputParameter(Settings, "HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	SetOutputParameter(Settings, "VerticalOverallPlacement", DataCompositionTotalPlacement.None);
	
EndProcedure

// Returns whether the field is used in the SCD configuration
//
// Parameters:
//	StructureItem - DataCompositionSettingsComposer, DataCompositionSettings - CD structure element
//	Field - String, DataCompositionField - name or field of the data layout.
//	IncludingNestedFields - Boolean - If True, nested fields will be checked. For Example, " Registrar.Date".
//					False by default.
//
// Returns:
//	Boolean - True if the field is found in any of the settings.
//
Function FieldUsed_(StructureItem, Field, IncludingNestedFields = False) Export
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Settings = StructureItem.GetSettings();
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Settings = StructureItem;
	EndIf;
	
	ThereIsGrouping = False;
	
	ThereIsGrouping = FindField(Settings.Structure, Field, IncludingNestedFields);
	
	If TypeOf(Field) = Type("String") Then
		LayoutField = New DataCompositionField(Field);
		NameOfLayoutFieldWithDot = Field + ".";
	Else
		LayoutField = Field;
		NameOfLayoutFieldWithDot = String(Field) + ".";
	EndIf;
	
	If Not ThereIsGrouping Then
		// find the grouping field in the selection
		For Each FilterField In Settings.Filter.Items Do
			
			If TypeOf(FilterField) = Type("DataCompositionFilterItemGroup") Then
				ThereIsGrouping = SelectionIsUsed_(FilterField.Items, LayoutField, IncludingNestedFields);
				If ThereIsGrouping Then
					Break;
				EndIf;
			Else
				If FilterField.Use And TypeOf(FilterField.LeftValue) = Type("DataCompositionField") Then
					If IncludingNestedFields
						And (FilterField.LeftValue = LayoutField
						Or StrStartsWith(String(FilterField.LeftValue), NameOfLayoutFieldWithDot)) Then
						ThereIsGrouping = True;
						Break;
					ElsIf Not IncludingNestedFields And FilterField.LeftValue = LayoutField Then
						ThereIsGrouping = True;
						Break;
					EndIf;
				ElsIf FilterField.Use And TypeOf(FilterField.RightValue) = Type("DataCompositionField") Then
					If IncludingNestedFields
						And (FilterField.RightValue = LayoutField
						Or StrStartsWith(String(FilterField.RightValue), NameOfLayoutFieldWithDot)) Then
						ThereIsGrouping = True;
						Break;
					ElsIf Not IncludingNestedFields And FilterField.RightValue = LayoutField Then
						ThereIsGrouping = True;
						Break;
					EndIf;
				EndIf;
			EndIf;
			
		EndDo;
	EndIf;
	
	If Not ThereIsGrouping Then
		SelectedFields = GetSelectedFields(Settings);
		
		For Each ComboBox In SelectedFields Do
			
			If TypeOf(ComboBox) = Type("DataCompositionSelectedField")
				And ComboBox.Use Then
				If IncludingNestedFields
					And (ComboBox.Field = LayoutField
					Or StrStartsWith(String(ComboBox.Field), NameOfLayoutFieldWithDot)) Then
					ThereIsGrouping = True;
					Break;
				ElsIf Not IncludingNestedFields And ComboBox.Field = LayoutField Then
					ThereIsGrouping = True;
					Break;
				EndIf;
			EndIf;
			
		EndDo;
	EndIf;
	
	Return ThereIsGrouping;
	
EndFunction 

// Returns a list of all settings linker groupings
// 
// Parameters:
//	StructureItem - DataCompositionSettingsComposer, DataCompositionSettings - CD structure element
//	ShowTableDimensions - Boolean - flag for adding column groupings to the list (True by default).
//
// Returns:
// 	ValueList - List Of Dimensions:
// 	 *Value - DataCompositionTableGroup -
// 	 *Value - DataCompositionChartGroup -
// 	 *Value- DataCompositionGroup - the found grouping.
//
Function GetGroupings(StructureItem, ShowTableDimensions = True) Export
	
	FieldList = New ValueList;
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Structure = StructureItem.Settings.Structure;
		AddDimensions(Structure, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Structure = StructureItem.Structure;
		AddDimensions(Structure, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then
		AddDimensions(StructureItem.Rows, FieldList);
		AddDimensions(StructureItem.Columns, FieldList);
	ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
		AddDimensions(StructureItem.Series, FieldList);
		AddDimensions(StructureItem.Points, FieldList);
	Else
		AddDimensions(StructureItem.Structure, FieldList, ShowTableDimensions);
	EndIf;
	Return FieldList;
	
EndFunction

// Returns the value of the data layout parameter
//
// Parameters:
//	SettingObject1 - DataCompositionSettings - the configuration object.
//					- DataCompositionUserSettings -
//					- DataCompositionSettingsComposer -
//					- DataCompositionNestedObjectSettings -
//					- DataCompositionDetailsData -
//					- DataCompositionParameterValueCollection -
//					- DataCompositionAppearance -
//	Parameter		- String, DataCompositionParameter - field or name of the field to return the parameter for.
//
// Returns:
//	DataCompositionSettingsParameterValue - Undefined if the parameter is not found.
//
Function GetParameter(SettingObject1, Parameter) Export
	
	ParameterValue = Undefined;
	ParameterField_ = ?(TypeOf(Parameter) = Type("String"), New DataCompositionParameter(Parameter), Parameter);
	
	If TypeOf(SettingObject1) = Type("DataCompositionSettings") Then
		ParameterValue = SettingObject1.DataParameters.FindParameterValue(ParameterField_);
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionUserSettings") Then
		For Each SettingItem In SettingObject1.Items Do
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
			   And SettingItem.Parameter = ParameterField_ Then
				ParameterValue = SettingItem;
				Break;
			EndIf;
		EndDo;
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionSettingsComposer") Then
		For Each SettingItem In SettingObject1.UserSettings.Items Do
			If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
				And SettingItem.Parameter = ParameterField_ Then
				ParameterValue = SettingItem;
				Break;
			EndIf;
		EndDo;
		If ParameterValue = Undefined Then
			ParameterValue = SettingObject1.Settings.DataParameters.FindParameterValue(ParameterField_);
		EndIf;
		If ParameterValue = Undefined Then
			ParameterValue = SettingObject1.FixedSettings.DataParameters.FindParameterValue(ParameterField_);
		EndIf;
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionNestedObjectSettings") Then
		ParameterValue = SettingObject1.Settings.DataParameters.FindParameterValue(ParameterField_);
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionDetailsData") Then
		ParameterValue = SettingObject1.Settings.DataParameters.FindParameterValue(ParameterField_);
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionParameterValueCollection") Then
		ParameterValue = SettingObject1.Find(ParameterField_);
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionAppearance") Then
		ParameterValue = SettingObject1.FindParameterValue(ParameterField_);
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// Returns the last element of the structure - the grouping
//
// Parameters:
//	SettingsStructureItem - DataCompositionSettingsComposer, DataCompositionSettings - CD structure element
//	Rows - Boolean - flag for getting the latest grouping of rows (series) or columns (points).
//
// Returns:
//	DataCompositionChartStructureItemCollection, DataCompositionTableStructureItemCollection, DataCompositionSettingStructureItemCollection - Undefined if nothing is found.
//
Function GetLastElementOfStructure(SettingsStructureItem, Rows = True) Export
	
	If TypeOf(SettingsStructureItem) = Type("DataCompositionSettingsComposer") Then
		Settings = SettingsStructureItem.Settings;
	ElsIf TypeOf(SettingsStructureItem) = Type("DataCompositionSettings") Then
		Settings = SettingsStructureItem;
	Else
		Return Undefined;
	EndIf;
	
	Structure = Settings.Structure;
	If Structure.Count() = 0 Then
		Return Settings;
	EndIf;
	
	If Rows Then
		TableStructureName = "Rows";
		DiagramStructureName = "SetOfSeries";
	Else
		TableStructureName = "Columns";
		DiagramStructureName = "Points";
	EndIf;
	
	While True Do
		StructureItem = Structure[0];
		If TypeOf(StructureItem) = Type("DataCompositionTable")
			And StructureItem[TableStructureName].Count() > 0 Then
			If StructureItem[TableStructureName][0].Structure.Count() = 0 Then
				Structure = StructureItem[TableStructureName];
				Break;
			EndIf;
			Structure = StructureItem[TableStructureName][0].Structure;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart")
			And StructureItem[DiagramStructureName].Count() > 0 Then
			If StructureItem[DiagramStructureName][0].Structure.Count() = 0 Then
				Structure = StructureItem[DiagramStructureName];
				Break;
			EndIf;
			Structure = StructureItem[DiagramStructureName][0].Structure;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionGroup")
			  Or TypeOf(StructureItem) = Type("DataCompositionTableGroup")
			  Or TypeOf(StructureItem) = Type("DataCompositionChartGroup") Then
			If StructureItem.Structure.Count() = 0 Then
				Break;
			EndIf;
			Structure = StructureItem.Structure;
		ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then
			Return StructureItem[TableStructureName];
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart")	Then
			Return StructureItem[DiagramStructureName];
		Else
			Return StructureItem;
		EndIf;
	EndDo;
	
	Return Structure[0];
	
EndFunction

// Returns grouping-detailed records of the settings linker
//
// Parameters:
//	SettingsComposer - DataCompositionSettingsComposer, DataCompositionSettings - element of the CD structure.
//
// Returns:
//	See DataCompositionClientServer.GetLastElementOfStructure
//
Function GetDetailedRecordsStructureElement(SettingsComposer) Export
	
	LastElementOfStructure = GetLastElementOfStructure(SettingsComposer, True);
	If TypeOf(LastElementOfStructure) = Type("DataCompositionGroup")
		Or TypeOf(LastElementOfStructure) = Type("DataCompositionTableGroup")
		Or TypeOf(LastElementOfStructure) = Type("DataCompositionChartGroup") Then
		If LastElementOfStructure.GroupFields.Items.Count() = 0 Then
			Return LastElementOfStructure;
		EndIf;
	EndIf;
	
EndFunction

// Copies the information from the layout data
//
// Parameters:
//	ReceiverSettings	- DataCompositionSettings -
//						- DataCompositionNestedObjectSettings -
//						- DataCompositionGroup -
//						- DataCompositionTableGroup -
//						- DataCompositionChartGroup -
//						- DataCompositionTable -
//						- DataCompositionChart - a collection of CD settings where settings are copied.
//	SettingsSource_	- DataCompositionSettings -
//						- DataCompositionNestedObjectSettings -
//						- DataCompositionGroup -
//						- DataCompositionTableGroup -
//						- DataCompositionChartGroup -
//						- DataCompositionTable -
//						- DataCompositionChart - collection of CD settings, from where the settings are copied.
//
Procedure CopyDataLayoutSettings(ReceiverSettings, SettingsSource_) Export
	
	If SettingsSource_ = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ReceiverSettings) = Type("DataCompositionSettings") Then
		For Each Parameter In SettingsSource_.DataParameters.Items Do
			ParameterValue = ReceiverSettings.DataParameters.FindParameterValue(Parameter.Parameter);
			If ParameterValue <> Undefined Then
				FillPropertyValues(ParameterValue, Parameter);
			EndIf;
		EndDo;
	EndIf;
	
	If TypeOf(SettingsSource_) = Type("DataCompositionNestedObjectSettings") Then
		FillPropertyValues(ReceiverSettings, SettingsSource_);
		CopyDataLayoutSettings(ReceiverSettings.Settings, SettingsSource_.Settings);
		Return;
	EndIf;
	
	// Copying Settings
	If TypeOf(SettingsSource_) = Type("DataCompositionSettings") Then
		
		FillInElements(ReceiverSettings.DataParameters,		SettingsSource_.DataParameters);
		CopyElements(ReceiverSettings.UserFields,	SettingsSource_.UserFields);
		CopyElements(ReceiverSettings.Filter,				SettingsSource_.Filter);
		CopyElements(ReceiverSettings.Order,				SettingsSource_.Order);
		
	EndIf;
	
	If TypeOf(SettingsSource_) = Type("DataCompositionGroup")
		Or TypeOf(SettingsSource_) = Type("DataCompositionTableGroup")
		Or TypeOf(SettingsSource_) = Type("DataCompositionChartGroup") Then
		
		CopyElements(ReceiverSettings.GroupFields, SettingsSource_.GroupFields);
		CopyElements(ReceiverSettings.Filter, SettingsSource_.Filter);
		CopyElements(ReceiverSettings.Order, SettingsSource_.Order);
		FillPropertyValues(ReceiverSettings, SettingsSource_);
		
	EndIf;
	
	CopyElements(ReceiverSettings.Selection, SettingsSource_.Selection);
	CopyElements(ReceiverSettings.ConditionalAppearance, SettingsSource_.ConditionalAppearance);
	FillInElements(ReceiverSettings.OutputParameters, SettingsSource_.OutputParameters);
	
	// Copying the structure
	If TypeOf(SettingsSource_) = Type("DataCompositionSettings")
		Or TypeOf(SettingsSource_) = Type("DataCompositionGroup") Then
		
		For Each SourceStructureElement In SettingsSource_.Structure Do
			StructureElementReceiver = ReceiverSettings.Structure.Add(TypeOf(SourceStructureElement));
			CopyDataLayoutSettings(StructureElementReceiver, SourceStructureElement);
		EndDo;
		
	EndIf;
	
	If TypeOf(SettingsSource_) = Type("DataCompositionTableGroup")
		Or TypeOf(SettingsSource_) = Type("DataCompositionChartGroup") Then
		
		SettingsReceiverStructure = ReceiverSettings.Structure; // DataCompositionTableStructureItemCollection, DataCompositionChartStructureItemCollection  -
		For Each SourceStructureElement In SettingsSource_.Structure Do
			StructureElementReceiver = SettingsReceiverStructure.Add();
			CopyDataLayoutSettings(StructureElementReceiver, SourceStructureElement);
		EndDo;
		
	EndIf;
	
	If TypeOf(SettingsSource_) = Type("DataCompositionTable") Then
		
		For Each SourceStructureElement In SettingsSource_.Rows Do
			StructureElementReceiver = ReceiverSettings.Rows.Add();
			CopyDataLayoutSettings(StructureElementReceiver, SourceStructureElement);
		EndDo;
		
		For Each SourceStructureElement In SettingsSource_.Columns Do
			StructureElementReceiver = ReceiverSettings.Columns.Add();
			CopyDataLayoutSettings(StructureElementReceiver, SourceStructureElement);
		EndDo;
		
	EndIf;
	
	If TypeOf(SettingsSource_) = Type("DataCompositionChart") Then
		
		For Each SourceStructureElement In SettingsSource_.Series Do
			StructureElementReceiver = ReceiverSettings.Series.Add();
			CopyDataLayoutSettings(StructureElementReceiver, SourceStructureElement);
		EndDo;
		
		For Each SourceStructureElement In SettingsSource_.Points Do
			StructureElementReceiver = ReceiverSettings.Points.Add();
			CopyDataLayoutSettings(StructureElementReceiver, SourceStructureElement);
		EndDo;
		
	EndIf;
	
EndProcedure

// Copies selections from one data layout setting to another
//
// Parameters:
//	ReceiverCircuit		- DataCompositionSchema - map of the CD to whose settings the selection is copied
//	ReceiverSettings	- DataCompositionSettings - settings of the CD to which the selection is copied
//	SettingsSource_	- DataCompositionSettings - CD settings from which the selection is copied
//	ExceptionFields		- String, Array, Undefined - names of fields to skip when copying.
//
Procedure CopyDataCompositionFilter(ReceiverCircuit, ReceiverSettings, SettingsSource_, Val ExceptionFields = Undefined) Export
	
	ThereAreExceptionFields = False;
	
	If TypeOf(ExceptionFields) = Type("String") Then
		ExceptionFields = StrSplit(ExceptionFields, ",");
		For Each ExceptionField In ExceptionFields Do 
			ExceptionField = TrimAll(ExceptionField);
		EndDo;
	EndIf;
	
	ThereAreExceptionFields = TypeOf(ExceptionFields) = Type("Array") And ExceptionFields.Count() > 0;
	
	For Each FilterElement In SettingsSource_.Filter.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			If ThereAreExceptionFields Then
				AddSelectionElementToSelectionWithVerification(ReceiverSettings.Filter, FilterElement, ExceptionFields);
			Else
				AddSelectionElementToSelection(ReceiverSettings.Filter, FilterElement);
			EndIf;
		Else
			AddGroupOfSelectionElementsToSelection(ReceiverSettings.Filter,FilterElement);
		EndIf;
	EndDo;
	
	// It is necessary to correct the receiver settings, because there may be fields in the source selection that are not available in the receiver.
	QuerySettingsComposer = New DataCompositionSettingsComposer;
	QuerySettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ReceiverCircuit));
	QuerySettingsComposer.LoadSettings(ReceiverSettings);
	QuerySettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	ReceiverSettings = QuerySettingsComposer.GetSettings();
	
EndProcedure

Procedure AddSelectionElementToSelectionWithVerification(FilterReceiver, FilterElement, ExceptionFields)
	
	AddFieldToSelection = True;
	
	FieldName = String(FilterElement.LeftValue);
	For Each ExceptionField In ExceptionFields Do 
		If StrStartsWith(FieldName, ExceptionField) Then
			AddFieldToSelection = False;
			Break;
		EndIf;
	EndDo;
	
	If AddFieldToSelection Then
		AddSelectionElementToSelection(FilterReceiver, FilterElement);
	EndIf;

EndProcedure

// Deletes the selection from the settings Builder, if the field is not specified, clears the selection
//
// Parameters:
//	StructureItem - DataCompositionSettingsComposer, DataCompositionFilter - layout structure element
//	Field - String, DataCompositionField - name or layout field.
//
// Returns:
//	Boolean - indicates successful deletion/cleanup.
//
Function DeleteSelection(StructureItem, Val Field = Undefined) Export
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filter = StructureItem.Settings.Filter;
	Else
		Filter = StructureItem;
	EndIf;
		
	If Field = Undefined Then
		Filter.Items.Clear();
		Return True;
	EndIf;
	If TypeOf(Field) = Type("String") Then
		Field = New DataCompositionField(Field);
	EndIf;
	
	Items = GetSelectionElements(Filter);
	ArrayOfElementsToDelete = New Array;
	For Each Item In Items Do
		If Item.LeftValue = Field Then
			ArrayOfElementsToDelete.Add(Item);
		EndIf;
	EndDo;
	
	If ArrayOfElementsToDelete.Count() = 0 Then
		Return False;
	Else
		For Each Item In ArrayOfElementsToDelete Do
			Filter.Items.Delete(Item);
		EndDo;
		
		Return True;
		
	EndIf;
	
EndFunction

// Sets the data layout settings parameter
//
// Parameters:
//	Settings - DataCompositionSettings -
//				- DataCompositionUserSettings -
//				- DataCompositionSettingsComposer - CD settings for which you want to set parameters.
//	Parameter - String, DataCompositionParameter - the option that you want to install
//	Value - Arbitrary - the value that you want to install.
//	Use - Boolean - indicates whether the CD parameter is used.
//	Inaccessible - Boolean - True if the setting element is not intended to be changed as part of the user setting.
//
// Returns:
//	DataCompositionSettingsParameterValue - the set parameter of CD settings. Undefined if the parameter is not found.
//
Function SetParameter(Settings, Parameter, Value, Use = True, Inaccessible = False) Export
	ParameterValue = GetParameter(Settings, Parameter);
	
	If ParameterValue <> Undefined Then
		ParameterValue.Value		= Value;
		ParameterValue.Use	= Use;
		If Inaccessible Then
			ParameterValue.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
	EndIf;
	
	Return ParameterValue;
EndFunction

// Sets data layout settings
//
// Parameters:
//	Settings - DataCompositionSettings, DataCompositionUserSettings, DataCompositionSettingsComposer - DCS Settings for Which you want to set parameters
//	ParametersToBeSpecified - Map - in which:
//		*Key - String - the name of the data layout parameter as specified in the schema
//		*Value - Arbitrary - set value.
//
Procedure SetCollectionOfParameters(Settings, ParametersToBeSpecified) Export
	
	If Not Settings = Undefined Then
		For Each SetParameter_1 In ParametersToBeSpecified Do
			ParameterKey =  SetParameter_1.Key;
			ParameterValue = SetParameter_1.Value;
			
			SettingsParameterValue = GetParameter(Settings, ParameterKey);
			If Not SettingsParameterValue = Undefined Then
				
				SetParameter(Settings, ParameterKey, ParameterValue, True);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Sets the output parameter of the settings linker or CD settings
//
// Parameters:
//	GroupSettingsComposer - DataCompositionGroup -
//									- DataCompositionTableGroup -
//									- DataCompositionChartGroup - the settings builder or CD configuration/grouping.
//	ParameterName - String - name of the CD parameter.
//	Value - Arbitrary - value of the CD output parameter.
//
// Returns:
//	DataCompositionParameterValue - the set parameter of CD settings. Undefined if the parameter is not found.
//
Function SetOutputParameter(GroupSettingsComposer, ParameterName, Value) Export
	
	If TypeOf(GroupSettingsComposer) = Type("DataCompositionSettingsComposer") Then
		ParameterValue = GroupSettingsComposer.Settings.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	Else
		ParameterValue = GroupSettingsComposer.OutputParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	EndIf;
	
	If ParameterValue <> Undefined Then
		ParameterValue.Use = True;
		ParameterValue.Value = Value;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// Sets the settings of the data layout. However, if the parameter is included in the user settings,
// the user setting with the corresponding ID is edited. It is used in cases
// when you need to set user parameters programmatically.
//
// Parameters:
//	SettingsComposer - DataCompositionSettingsComposer - CD structure element
//	ParametersArray - Array - Array of parameters.
//
Procedure AddParametersToUserSettings(SettingsComposer, ParametersArray) Export
	
	For Each ItemToAdd_ In ParametersArray Do
		
		// search for a suitable user parameter
		UserSettingID = "";
		ComposerParameterElements = SettingsComposer.Settings.DataParameters.Items;
		For Each ComposerElement In ComposerParameterElements Do
			If ComposerElement.Parameter = New DataCompositionParameter(ItemToAdd_.Name) Then
				UserSettingID = ComposerElement.UserSettingID;
				Break;
			EndIf;
		EndDo;
		
		// if a custom parameter is found, then edit it
		If ValueIsFilled(UserSettingID) Then
			For Each SettingItem In SettingsComposer.UserSettings.Items Do
				If SettingItem.UserSettingID = UserSettingID Then
					ParameterElement = SettingItem;
					Break;
				EndIf;
			EndDo;
			ParameterElement.Value = ItemToAdd_.Value;
			ParameterElement.Use = True;
			
		Else
			// if the user parameter is not found, then add
			SetParameter(SettingsComposer.UserSettings,
				ItemToAdd_.Name,
				ItemToAdd_.Value,
				True);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the name of the field and its child details, separated by a dot
//
// Parameters:
//	FieldName - String - field name in the format " field Name "or" field Name.Requisite.Requisite..."
//
// Returns:
//	Structure - name and Attributes in string format:
//		*Name - String - field name
//		*Attribute - String - The name of the prop in the format " Prop.Requisite..."
//
Function SeparateFieldNameAndProps(FieldName) Export
	
	Result = New Structure("Name,Attribute", "", "");
	NamesArray = StrSplit(FieldName, ".");
	If NamesArray.Count() > 0 Then
		Result.Name = NamesArray[0];
	EndIf;
	
	If NamesArray.Count() > 1 Then
		NamesArray.Delete(0);
		Result.Attribute = StrConcat(NamesArray,".");
	EndIf;
	
	Return Result;
	
EndFunction

// Checks for equality of two passed data layout schema selections
//
// Parameters:
//  SourceSelection - DataCompositionSettings - the first element of comparison
//  ElementOfComparisonSelection - DataCompositionSettings - the second element of comparison.
//
// Returns:
//   Boolean - True if the transmitted selections are equal, otherwise false.
//
Function SelectionsUsedAreEqual(SourceSelection, ElementOfComparisonSelection) Export
	
	SourceSelectionElements = FilterItems1(SourceSelection);
	ComparisonElementSelectionElements = FilterItems1(ElementOfComparisonSelection);
	
	If SourceSelectionElements = Undefined And ComparisonElementSelectionElements = Undefined Then
		Return True;
	EndIf;
	
	If SourceSelectionElements = Undefined Then
		Return Not ThereAreSignificantSelectionElements(ComparisonElementSelectionElements);
	EndIf;
	
	If ComparisonElementSelectionElements = Undefined Then
		Return Not ThereAreSignificantSelectionElements(SourceSelectionElements);
	EndIf;
	
	For Each FilterElement In SourceSelectionElements Do
		FoundItem = Undefined;
		If Not ThereIsSameSelection(FilterElement, ComparisonElementSelectionElements, FoundItem) Then
			Return False;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If Not SelectionsUsedAreEqual(FilterElement.Items, FoundItem) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	For Each FilterElement In ComparisonElementSelectionElements Do
		FoundItem = Undefined;
		If Not ThereIsSameSelection(FilterElement, SourceSelectionElements, FoundItem) Then
			Return False;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If Not SelectionsUsedAreEqual(FilterElement.Items, FoundItem) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

Procedure AddSelectionElementToSelection(FilterReceiver,FilterElement)
	NewItem = FilterReceiver.Items.Add(Type("DataCompositionFilterItem"));
	FillPropertyValues(NewItem,FilterElement);
EndProcedure


// Adds a group of selection elements.
// 
// Parameters:
// 	FilterReceiver - DataCompositionFilterItemGroup, DataCompositionFilter, DataCompositionFilterItem - the collection where the group is added.
// 	Items_Group - DataCompositionFilterItem, DataCompositionFilterItemGroup - non-investigative place where the group is inserted.
// 	ExceptionFields - Undefined, Array - LongDesc
Procedure AddGroupOfSelectionElementsToSelection(FilterReceiver, Items_Group, Val ExceptionFields = Undefined)
	
	ThereAreExceptionFields = False;
	
	If TypeOf(ExceptionFields) = Type("String") Then
		ExceptionFields = StrSplit(ExceptionFields, ",");
		For Each ExceptionField In ExceptionFields Do 
			ExceptionField = TrimAll(ExceptionField);
		EndDo;
	EndIf;
	
	ThereAreExceptionFields = TypeOf(ExceptionFields) = Type("Array") And ExceptionFields.Count() > 0;
	
	NewFolder = FilterReceiver.Items.Add(Type("DataCompositionFilterItemGroup"));
	FillPropertyValues(NewFolder,Items_Group);
	
	For Each FilterElement In Items_Group.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			If ThereAreExceptionFields Then
				AddSelectionElementToSelectionWithVerification(NewFolder, FilterElement, ExceptionFields);
			Else
				AddSelectionElementToSelection(NewFolder, FilterElement);
			EndIf;
		Else
			AddGroupOfSelectionElementsToSelection(NewFolder, FilterElement, ExceptionFields);
		EndIf;
	EndDo;
EndProcedure

Procedure AddSelectedFieldsToArray(StructureItem, FieldArray, GroupsOnly = False)
	
	For Each Item In StructureItem Do
		If TypeOf(Item) = Type("DataCompositionAutoSelectedField") Then
			Continue;
		ElsIf TypeOf(Item) = Type("DataCompositionSelectedFieldGroup") Then
			If GroupsOnly Then
				FieldArray.Add(Item);
			EndIf;
			AddSelectedFieldsToArray(Item.Items, FieldArray, GroupsOnly);
		Else
			If Not GroupsOnly Then
				FieldArray.Add(Item);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds nested groupings of the structure element.
//
Procedure AddDimensions(Structure, ListOfDimensions, ShowTableDimensions = True)
	
	For Each StructureItem In Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			AddDimensions(StructureItem.Rows, ListOfDimensions);
			AddDimensions(StructureItem.Columns, ListOfDimensions);
		ElsIf TypeOf(StructureItem) = Type("DataCompositionChart") Then
			AddDimensions(StructureItem.Series, ListOfDimensions);
			AddDimensions(StructureItem.Points, ListOfDimensions);
		Else
			ListOfDimensions.Add(StructureItem);
			If ShowTableDimensions Then
				AddDimensions(StructureItem.Structure, ListOfDimensions);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure AddSelectionElementsToArray(Items, FieldArray, GroupsOnly = False)
	
	For Each Item In Items Do
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
			If GroupsOnly Then
				FieldArray.Add(Item);
			EndIf;
			AddSelectionElementsToArray(Item.Items, FieldArray, GroupsOnly);
		Else
			If Not GroupsOnly Then
				FieldArray.Add(Item);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Checks whether selection is used for the specified field.
//
// Parameters:
//	Items - DataCompositionFilterItemCollection - collection of selection elements.
//	LayoutField - String, DataCompositionField - name of the field to search for.
//	IncludingNestedFields - Boolean - Indicates whether to search in nested elements.
//
// Returns:
//  Boolean - True if the current selection is set for the specified field
//
Function SelectionIsUsed_(Items, Val LayoutField, IncludingNestedFields = False) Export
	
	ThereIsGrouping = False;
	NameOfLayoutFieldWithDot = String(LayoutField) + ".";
	If TypeOf(LayoutField) = Type("String") Then
		LayoutField = New DataCompositionField(LayoutField);
	EndIf;
	
	For Each FilterField In Items Do
		
		If TypeOf(FilterField) = Type("DataCompositionFilterItemGroup") Then
			ThereIsGrouping = SelectionIsUsed_(FilterField.Items, LayoutField, IncludingNestedFields);
			If ThereIsGrouping Then
				Break;
			EndIf;
		Else
			If FilterField.Use And TypeOf(FilterField.LeftValue) = Type("DataCompositionField") Then
				If IncludingNestedFields
					And (FilterField.LeftValue = LayoutField
					Or StrStartsWith(String(FilterField.LeftValue), NameOfLayoutFieldWithDot)) Then
					ThereIsGrouping = True;
					Break;
				ElsIf Not IncludingNestedFields And FilterField.LeftValue = LayoutField Then
					ThereIsGrouping = True;
					Break;
				EndIf;
			ElsIf FilterField.Use And TypeOf(FilterField.RightValue) = Type("DataCompositionField") Then
				If IncludingNestedFields
					And (FilterField.RightValue = LayoutField
					Or StrStartsWith(String(FilterField.RightValue), NameOfLayoutFieldWithDot)) Then
					ThereIsGrouping = True;
					Break;
				ElsIf Not IncludingNestedFields And FilterField.RightValue = LayoutField Then
					ThereIsGrouping = True;
					Break;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return ThereIsGrouping;
	
EndFunction

// Returns true if the field is present in the structure element groupings.
//
// Parameters:
//	Structure - DataCompositionSettingStructureItemCollection - An element of the report settings structure.
//				- DataCompositionTableStructureItemCollection - An element of the report settings structure.
//				- DataCompositionChartStructureItemCollection - An element of the report settings structure.
//				- DataCompositionTable - An element of the report settings structure.
//				- DataCompositionGroup - An element of the report settings structure.
//				- DataCompositionChartGroup - An element of the report settings structure.
//				- DataCompositionTableGroup - An element of the report settings structure.
//				- DataCompositionChart - An element of the report settings structure.
//	Field - String - Name of the layout field.
//			- DataCompositionField - data layout field.
//	IncludingNestedFields - Boolean - If True, nested fields will be checked. For Example, " Registrar.Date".
//						False by default.
//
// Returns:
//	Boolean - True if there is a Field in the groupings of the structure elements.
//
Function FindField(Structure, Field, IncludingNestedFields = False)
	
	ThereIsField = False;
	
	If TypeOf(Structure) <> Type("DataCompositionSettingStructureItemCollection")
		And TypeOf(Structure) <> Type("DataCompositionTableStructureItemCollection")
		And TypeOf(Structure) <> Type("DataCompositionChartStructureItemCollection") Then
		
		Return ThereIsField;
		
	EndIf;
	
	If TypeOf(Field) = Type("String") Then
		LayoutField = New DataCompositionField(Field);
	Else
		LayoutField = Field;
	EndIf;
	NameOfLayoutFieldWithDot = String(Field) + ".";
	
	For Each StructureItem In Structure Do
		
		If Type(StructureItem) = Type("DataCompositionGroup") 
			Or Type(StructureItem) = Type("DataCompositionTableGroup") 
			Or Type(StructureItem) = Type("DataCompositionChartGroup") Then
			For Each GroupingField In StructureItem.GroupFields.Items Do
				If GroupingField.Use Then
					If IncludingNestedFields
						And (GroupingField.Field = LayoutField
						Or StrStartsWith(String(GroupingField.Field), NameOfLayoutFieldWithDot)) Then
						ThereIsField = True;
						Break;
					ElsIf Not IncludingNestedFields And GroupingField.Field = LayoutField Then
						ThereIsField = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		If ThereIsField Then
			Break;
		EndIf;
		If Type(StructureItem) = Type("DataCompositionTable") Then
			ThereIsField = FindField(StructureItem.Rows, Field, IncludingNestedFields)
					Or FindField(StructureItem.Columns, Field, IncludingNestedFields);
		ElsIf Type(StructureItem) = Type("DataCompositionGroup")
			Or Type(StructureItem) = Type("DataCompositionTableGroup")
			Or Type(StructureItem) = Type("DataCompositionChartGroup") Then
			ThereIsField = FindField(StructureItem.Structure, Field, IncludingNestedFields);
		ElsIf Type(StructureItem) = Type("DataCompositionChart") Then
			If StructureItem.Points.Count() <> 0 Then
				ThereIsField = FindField(StructureItem.Points, Field, IncludingNestedFields)
						Or FindField(StructureItem.Series, Field, IncludingNestedFields);
			EndIf;
		EndIf;

	EndDo;
	
	Return ThereIsField;
	
EndFunction //NaytiPole()

// Returns an array of selected fields or groups of selected fields
//
// Parameters:
//		StructureItem - DataCompositionSettingsComposer -
//							- DataCompositionNestedObjectSettings -
//							- DataCompositionSettings - structure Element, Settings Composer Settings, Settings Composer.
//		GroupsOnly - Boolean - indicates that the procedure will return only groups.
//
// Returns:
//		Array of DataCompositionSelectedField, DataCompositionSelectedFieldGroup - array of selected fields.
//
Function GetSelectedFields(StructureItem, GroupsOnly = False)
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") 
	 Or TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings")  Then
		SelectedFields = StructureItem.Settings.Selection;
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings")  Then
		SelectedFields = StructureItem.Selection;
	EndIf;
	
	FieldArray = New Array;
	AddSelectedFieldsToArray(SelectedFields.Items, FieldArray, GroupsOnly);
	Return FieldArray;
	
EndFunction


// Returning an array of selection elements.
// 
// Parameters:
// 	StructureItem - DataCompositionFilter - collection of selection elements.
// 	GroupsOnly - Boolean - Return only groups.
// Returns:
// 	Array of DataCompositionFilterItem, DataCompositionFilterItemGroup - Array of selection elements.
//
Function GetSelectionElements(StructureItem, GroupsOnly = False) Export
	
	FieldArray = New Array;
	
	AddSelectionElementsToArray(StructureItem.Items, FieldArray, GroupsOnly);
	Return FieldArray;
	
EndFunction

// Returns the value of the fixed data layout settings parameter
//
// Parameters:
//	Settings - DataCompositionSettingsComposer, DataCompositionSettings - fixed CD settings, CD Settings, CD settings Linker.
//	Parameter - String - name of the CD parameter to return the parameter value for.
//
// Returns:
//	DataCompositionParameterValue, Undefined - parameter value.
//
Function GetFixedSettingsParameter(Settings, Parameter) Export
	
	ParameterValue = Undefined;
	ParameterField_ = ?(TypeOf(Parameter) = Type("String"), New DataCompositionParameter(Parameter), Parameter);
	
	If TypeOf(Settings) = Type("DataCompositionSettingsComposer") Then
		ParameterValue = Settings.FixedSettings.DataParameters.FindParameterValue(ParameterField_);
	ElsIf TypeOf(Settings) = Type("DataCompositionSettings") Then
		ParameterValue = Settings.DataParameters.FindParameterValue(ParameterField_);
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// The procedure returns a selection by name.
// The procedure is not recursive, because it is called from the used selection Column,
// in which the group traversal has already been processed.
//
// Parameters:
//  FilterElement - DataCompositionFilterItem - the desired selection.
//  FilterItems1 - DataCompositionFilter - select where we are looking.
//  FoundItem - DataCompositionFilterItem - the selection element found.
//
// Returns:
//  Boolean - True if there is the same element of selection.
//
Function ThereIsSameSelection(FilterElement, FilterItems1, FoundItem)
	
	For Each ComparisonSelectionElement In FilterItems1 Do
		If TypeOf(ComparisonSelectionElement) <> Type(FilterElement) Then
			Continue;
		EndIf;
		
		If TypeOf(ComparisonSelectionElement) = Type("DataCompositionFilterItem") Then
			RightValuesAreEqual = ComparisonSelectionElement.RightValue = FilterElement.RightValue;
			If TypeOf(ComparisonSelectionElement.RightValue) = Type("ValueList")
				And TypeOf(FilterElement.RightValue) = Type("ValueList") Then
				RightValuesAreEqual = CommonClientServer.ValueListsAreEqual(
					ComparisonSelectionElement.RightValue, FilterElement.RightValue);
			EndIf;
			If ComparisonSelectionElement.Use = FilterElement.Use
				And RightValuesAreEqual
				And ComparisonSelectionElement.LeftValue = FilterElement.LeftValue
				And ComparisonSelectionElement.ComparisonType = FilterElement.ComparisonType
				And ComparisonSelectionElement.Application = FilterElement.Application Then
				
				FoundItem = ComparisonSelectionElement;
				Return True;
				
			EndIf;
		Else
			If ComparisonSelectionElement.Use = FilterElement.Use
				And ComparisonSelectionElement.GroupType = FilterElement.GroupType
				And ComparisonSelectionElement.Application = FilterElement.Application Then
				
				FoundItem = ComparisonSelectionElement;
				Return True;
				
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ThereAreSignificantSelectionElements(FilterItems1)
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then
			Return True;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If ThereAreSignificantSelectionElements(FilterElement.Items) Then
				Return True;
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function FilterItems1(FilterSettings)
	
	If TypeOf(FilterSettings) = Type("DataCompositionSettingsComposer")
		Or TypeOf(FilterSettings) = Type("DataCompositionSettings") Then
		FilterItems1 = FilterSettings.Filter.Items;
	
	Else
		FilterItems1 = FilterSettings;
		
	EndIf;
	
	Return FilterItems1;
	
EndFunction

#EndRegion
