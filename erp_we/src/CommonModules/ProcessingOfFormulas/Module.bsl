
#Region Public

// Returns an expression for getting the characteristic ID. Please note that the expression
// in a normal query and in a set-query SKD are different.
// 
// Parameters:
// 	MetadataOfCharacteristicsType - MetadataObject - Feature metadata object. See ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources.
// 	ForDCS - Boolean - Flag for getting an expression for the query text in the SKD.
// Returns:
// 	String - An expression of an identifier field that includes parentheses and a reference to the field specified in the properties of the supported sources of characteristics.
//
Function ExpressionOfFullFeatureID(MetadataOfCharacteristicsType, ForDCS = False) Export
	
	PropertiesOfCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	PropertiesCharacteristics = PropertiesOfCharacteristics.Find(MetadataOfCharacteristicsType, "SourceMetadata");
	If Not PropertiesCharacteristics = Undefined Then
		If ForDCS Then
			// In the extension of query languages, it is now impossible to specify more than 1 table of types of characteristics with a restriction
			// of curly brackets.
			Template = """[%1"" + %TableName%.%2 + ""]""";
		Else
			Template = """{%1"" + %TableName%.%2 + ""}""";
		EndIf;
		FieldExpression = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			PropertiesCharacteristics.PropertyTypePrefix,
			PropertiesCharacteristics.IdField_);
	Else
		FieldExpression = "";
	EndIf;
	
	Return FieldExpression;
EndFunction

// Returns a modified operand expression for a SCD with query datasets that redefine
// getting characteristics.
// 
// Parameters:
// 	OriginalExpression - String - The operand expression. For example, " Nomenclature. {OTHER Specification1}.Contractor"
// Returns:
// 	String - modified expression. For example, "Nomenclature.[[etc.Characteristic 1]]].Counterparty".
Function ModifiedOperandExpressionForDCS(OriginalExpression) Export
	
	// Due to the current feature of the SKD, we replace the curly brackets with square ones.
	// There are 3 closing brackets, one is part of the characteristic expression, and two adds a SCD to check the closure
	// of the field expression in the SCD (internal mechanism)).
	ModifiedExpression = StrReplace(OriginalExpression, "{", "[[");
	ModifiedExpression = StrReplace(ModifiedExpression, "}", "]]]");
	
	Return ModifiedExpression;
	
EndFunction


// Returns properties of a characteristic based on its expression in the formula language
// 
// Parameters:
// 	ExpressionOfCharacteristic - String - For example, "{, ETC.Main supplier}".
// Returns:
// 	Structure - LongDesc:
// * Metadata - MetadataObjectChartOfCharacteristicTypes, MetadataObjectCatalog - The metadata of the source characteristics.
// 				For Example, Metadata.Playvideopokeronline.Additional
// 				information or Metadata requirements.Guides.Types of contact information.
// * Id - String - The characteristic ID specified in the corresponding attribute stored in the characteristics table.
// * Prefix - String - Prefix of the type of characteristics. For example, " DR. " - For additional details and information.
Function PropertiesCharacteristics(ExpressionOfCharacteristic) Export
	
	PropertiesCharacteristics = New Structure;
	PropertiesCharacteristics.Insert("Prefix", "");
	PropertiesCharacteristics.Insert("Id", "");
	PropertiesCharacteristics.Insert("Metadata");
	
	PropertiesOfSupportedCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	ExpressionWithoutBrackets = StrReplace(ExpressionOfCharacteristic, "[", "");
	ExpressionWithoutBrackets = StrReplace(ExpressionWithoutBrackets, "]", "");
	ExpressionWithoutBrackets = StrReplace(ExpressionWithoutBrackets, "{", "");
	ExpressionWithoutBrackets = StrReplace(ExpressionWithoutBrackets, "}", "");
	
	For Each PropertiesDetails In PropertiesOfSupportedCharacteristics Do
		If StrStartsWith(ExpressionWithoutBrackets, PropertiesDetails.PropertyTypePrefix) Then
			PropertiesCharacteristics.Prefix = PropertiesDetails.PropertyTypePrefix;
			PropertiesCharacteristics.Id = Mid(ExpressionWithoutBrackets, StrLen(PropertiesDetails.PropertyTypePrefix) + 1);
			PropertiesCharacteristics.Metadata = PropertiesDetails.SourceMetadata;
			Break;
		EndIf;
	EndDo;
	
	Return PropertiesCharacteristics;
	
EndFunction

// Returns the name of the ID field for additional details and information formulas.
// 
// Returns:
// 	String - The name of the "Formula Identifier" field
Function IdFieldForAdditionalBankingDetails() Export
	MetadataCharacteristics_ = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo;
	PropertiesOfCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	PropertiesDetails = PropertiesOfCharacteristics.Find(MetadataCharacteristics_, "SourceMetadata");
	
	Return PropertiesDetails.IdField_;
EndFunction

#Region WorkingWithOperandTree

// Forms a tree of values with the ID and View columns.
//
// Returns:
//  ValueTree - Empty operand tree with columns:
//    *Id - String - ID of the operand.
//    *Presentation - String - Representation of the operand.
//    *TreeItemType - String - See ProcessingOfFormulas.TypesOfOperandTreeElements
//    *OperandSelectionAllowed - Boolean - If true, the operand tree string can be selected in the formula.
//    		For example, it doesn't make sense to select operand groups.
//    *IncludedInID - Boolean - Indicates whether the ID of the current row is included in the ID of the lower row.
//    		For example, if a group of operands identifies a data path, it must be included in the identifier.
//    		If an operand group is only used for logical linking of operands, it should not be included in the identifier.
//    *ValueType              - TypeDescription - A description of the types of the operand. You can only omit the type for groups of operands.
//    		In all other cases, you must fill in the form.
//    *ExpandToAttributes - Boolean - Indicates whether the reference operand must be recursively expanded to the details.
//    *Value - Number - The value of the operand. It can be used, for example, for interactive calculation of a value using a formula.
//    *ContainsValue - Boolean - Flag that the operand string contains a value.
//    *DeletionMark  - Boolean - Filled in if the operand is a reference to an object (for example, the price type).
//    		If an item is marked for deletion, an additional notification will be displayed when it is selected.
//
Function GetEmptyOperandTree() Export
	
	Tree = New ValueTree();
	
	// Basic property
	Tree.Columns.Add("Id", New TypeDescription("String"));
	Tree.Columns.Add("Presentation", New TypeDescription("String"));
	
	Tree.Columns.Add("TreeItemType", New TypeDescription("String"));
	Tree.Columns.Add("OperandSelectionAllowed", New TypeDescription("Boolean"));
	Tree.Columns.Add("IncludedInID", New TypeDescription("Boolean"));
	
	Tree.Columns.Add("ValueType",   New TypeDescription("TypeDescription"));
	Tree.Columns.Add("ExpandToAttributes", New TypeDescription("Boolean"));
	
	// Additional property
	Tree.Columns.Add("Value", New TypeDescription("Number", New NumberQualifiers(32, 3, AllowedSign.Any)));
	Tree.Columns.Add("ContainsValue", New TypeDescription("Boolean"));
	
	Tree.Columns.Add("DeletionMark", New TypeDescription("Boolean"));
	
	Return Tree;
	
EndFunction

// Types of elements in the operand tree. The element type affects the image of the row in the tree, and can also affect the behavior.
// When implemented as a structure, you can use it as an enum in your code.
// 
// Returns:
// 	Structure - LongDesc:
// * Operand - String - A normal operand that is not related to metadata. For example, the type of prices. Default.
// * Group - String - A group of operands or props or parameters. Image as a folder.
// * TopLevelRowGroup - String - A group of operands or props. The picture is how three props.
// * Attribute - String - The requisite metadata. For example, the item type details.
// * AdditionalAttribute - String - Additional banking details. Differs from additional information only in the image (and the location where the value is stored).
// * AdditionalInfoItem - String - Additional information.
// * TypeOfContactInformation_Address - String - Type of contact information with the "address" type.
// * TypeOfContactInformation_Phone - String - Type of contact information with the "phone" type.
// * TypeOfContactInformation_EmailAddress - String - Contact information type with the "email address" type.
// * TypeOfContactInformation_Skype - String - Type of contact information with the "skype" type.
// * TypeOfContactInformation_WebPage - String - Type of contact information with the "web page" type.
// * TypeOfContactInformation_Fax - String - Type of contact information with the "Fax" type.
// * TypeOfContactInformation_Other - String - Type of contact information with the "other" type.
// * TypeOfContactInformation_MultipleTypesOfContactInformation - String - ID for the specified ID, there are several
// 		elements of the contact information types directory with different types.
// * OtherCharacteristics - String - Other type of characteristics that are not additional.Bank details and information or contact information.
//
Function TypesOfOperandTreeElements() Export
	
	Result = New Structure;
	Result.Insert("Operand", "Operand"); // A simple operand, for example, the type of prices.
	Result.Insert("Group", "Group"); // A group of operands. The picture is like a folder. For example, layout diagram fields grouped into group fields.
	Result.Insert("TopLevelRowGroup", "TopLevelRowGroup"); // A group of operands. The picture is like three props.
	
	Result.Insert("Attribute", "Attribute");
	
	Result.Insert("AdditionalAttribute", "AdditionalAttribute");
	Result.Insert("AdditionalInfoItem", "AdditionalInfoItem");
	
	Result.Insert("TypeOfContactInformation_Address", "TypeOfContactInformation_Address");
	Result.Insert("TypeOfContactInformation_Phone", "TypeOfContactInformation_Phone");
	Result.Insert("TypeOfContactInformation_EmailAddress", "TypeOfContactInformation_EmailAddress");
	Result.Insert("TypeOfContactInformation_Skype", "TypeOfContactInformation_Skype");
	Result.Insert("TypeOfContactInformation_WebPage", "TypeOfContactInformation_WebPage");
	Result.Insert("TypeOfContactInformation_Fax", "TypeOfContactInformation_Fax");
	Result.Insert("TypeOfContactInformation_Other", "TypeOfContactInformation_Other");
	Result.Insert("TypeOfContactInformation_MultipleTypesOfContactInformation", "TypeOfContactInformation_MultipleTypesOfContactInformation");
	
	Result.Insert("OtherCharacteristics", "OtherCharacteristics");
	
	Return Result;
	
EndFunction

// Adds to the specified location, the subject line of the tree and populates it with default values.
// 
// Parameters:
// 	PlaceAdded - ValueTree, ValueTreeRow, FormDataTree, FormDataTreeItem - the tree
// 			obtained by the getposter of Operands method, or a tree on the form or string of the tree.
// Returns:
// 	- ValueTreeRow - A string added to the value tree.
// 	- FormDataTreeItem - A string added to the tree on the form.
Function NewLineOfOperandTree(PlaceAdded) Export
	
	If TypeOf(PlaceAdded) = Type("ValueTree")
	 Or TypeOf(PlaceAdded) = Type("ValueTreeRow") Then
		NewTreeRow = PlaceAdded.Rows.Add();
	Else
		NewTreeRow = PlaceAdded.GetItems().Add();
	EndIf;
	
	// Basic properties.
	
	// Obligatory. Used in the formula itself.
	NewTreeRow.Id = "";
	
	// Obligatory. Used in a custom view.
	NewTreeRow.Presentation = "";
	
	// Obligatory. Used to define the image of a tree row.
	NewTreeRow.TreeItemType = TypesOfOperandTreeElements().Operand;
	
	// A flag indicating whether the current row of the tree can be selected in the formula.
	// For example, it does not make sense to choose a combining group of operands.
	NewTreeRow.OperandSelectionAllowed = True;
	
	// A flag indicating whether to include the identifier of a given string of the combining group of identifiers
	// may or may not be included in the identifier of the lower operands.
	NewTreeRow.IncludedInID = True;
	
	// Recursive reversal of tree rows and display of the operand type on the form.
	
	// Mandatory (excluding a group of operands). Required for recursive reversal in the formula constructor.
	NewTreeRow.ValueType = Undefined;
	
	// Flag of the need for further recursive reversal of the tree string in the formula constructor.
	// Requires specifying the value type on the current row of the tree.
	NewTreeRow.ExpandToAttributes = False;
	
	// Properties for online calculation of formula values in the formula constructor.
	NewTreeRow.Value = 0; // Optional. Numeric value for online calculation of the value by the formula, if known.
	NewTreeRow.ContainsValue = False; // Optional. Flag if it contains a value (0 is also a value).
	
	// Additional properties.
	
	// It is indicated if the operand is a pointer to a link, for example, a type of price or an item of expenditure,
	// and it is necessary to additionally warn the user about a mark to delete an element when selecting an operand in the formula constructor
	// .
	NewTreeRow.DeletionMark = False; 
	
	
	Return NewTreeRow;
	
EndFunction

// Returns a template for parameters for additional operand expansion constraints.
// 
// Returns:
// 	Structure - LongDesc:
// * RecursivelyExpandLayoutSchemeOperands - Boolean - The default value is True (expanded). However, you can disable row reversal
// 		with a single parameter without specifying the corresponding parameter for each row in the operand tree.
// * MaximumRowExpansionLevel - Number - The default value is 0 (not controlled). Controls the maximum level of rows in the tree when scanning.
// * DisplayBankingDetails - Boolean - The default value is True. Flag for the need to display the usual details when scanning.
// * DisplayCharacteristics - Boolean - The default value is True. Flag for displaying characteristics (additional details and contact information).
// * AdditionalAttributeSets - Array of CatalogRef.AdditionalAttributesAndInfoSets - If the array is empty, then an additional selection for the add.details
// 		and information on sets are not superimposed. Only the selection described in the metadata (the "Characteristics" button) applies to objects
// 		from the value type of the expanded string.
// 		If the array is not empty, then in addition to the selection from the metadata, the selection is applied to the occurrence of an additional.details and information
// 		in the specified sets.
// * OutputAttributes - String - The default value is "" (the output of details is not limited). Ability to limit the output details to a comma-separated list.
// 		If the value is filled in, then when the details are displayed, a check will be performed for entering this list.
// * NotOutputAttributes - String - The default value is "" (the output of details is not limited). Ability to limit the output details to a comma-separated list.
// 		If the value is filled in, then when the details are displayed, a check will be performed for NOT being included in this list.
//
Function LimitationsOfOperandSweep() Export
	
	Result = New Structure;
	
	Result.Insert("RecursivelyExpandLayoutSchemeOperands", True);
	
	Result.Insert("MaximumRowExpansionLevel", 0);
	
	Result.Insert("DisplayBankingDetails", True);
	Result.Insert("DisplayCharacteristics", True);
	Result.Insert("AdditionalAttributeSets", New Array);
	
	Result.Insert("OutputAttributes", "");
	Result.Insert("NotOutputAttributes", "");
	
	Return Result;
	
EndFunction

// Expand the operand tree string by one level according to its value type (add subordinate strings-details and characteristics).
// 
// Parameters:
// 	TreeRow - ValueTreeRow - unfolding tree line:
// 	 *Id - String - For all types of values. row ID.
// 	 *Presentation - String - For all types of values. The representation of the string.
// 	 *TreeItemType - String - For all types of values. See ProcessingOfFormulas.TypesOfOperandTreeElements.
// 	 *OperandSelectionAllowed - Boolean - For all types of values. Flag for selecting the operand string.
// 	 *IncludedInID - Boolean - For all types of values. Flag for including the current operand in the following.
// 	The tree string is the data form of the tree element - the unfolded tree string.
// 	 *Id - String - For all types of values. row ID.
// 	 *Presentation - String - For all types of values. The representation of the string.
// 	 *TreeItemType - String - For all types of values. See ProcessingOfFormulas.TypesOfOperandTreeElements.
// 	 *OperandSelectionAllowed - Boolean - For all types of values. Flag for selecting the operand string.
// 	 *IncludedInID - Boolean - For all types of values. Flag for including the current operand in the following ones.
// 	SweepRestrictions - Undefined - The value of the sweep by default.
// 	Ogranicheniyami - See ProcessingOfFormulas.LimitationsOfOperandSweep.
//
Procedure ExpandOperandString(TreeRow, SweepRestrictions = Undefined) Export
	If TypeOf(TreeRow) = Type("FormDataTreeItem") Then
		If TreeRow.SubordinateRowsExpanded Then
			Return;
		EndIf;
	ElsIf TypeOf(TreeRow) = Type("ValueTreeRow") Then
		If TreeRow.Rows.Count() > 0 Then
			Return;
		EndIf;
	EndIf;
	
	// For the props row, the props itself unfolds,
	// for the table row (table part), the owner row is searched for and it unfolds.
	UnfoldsTable = (TreeRow.TreeItemType = "TabularSection");
	If UnfoldsTable Then
		ValueType = New TypeDescription();
		If TypeOf(TreeRow) = Type("FormDataTreeItem") Then
			ParentRow = TreeRow.GetParent();
		Else
			ParentRow = TreeRow.Parent;
		EndIf;
		If ParentRow = Undefined Then
			ErrorText = NStr("vi = 'Đối với bảng %1 chưa xác định đối tượng chủ của bảng, không thể xác định mục tin của bảng';
							|ru = 'Для таблицы %1 не определен объект владелец таблицы, невозможно определить реквизиты таблицы';
							|en = 'The table owner object is not defined for the table %1. Cannot determine the table attributes'; fa = 'The table owner object is not defined for the table %1. Cannot determine the table attributes';
							|it = 'Per la tabella %1 non è stato stabilito l''oggetto titolare della tabella, impossibile definire i requisiti della tabella';
							|pl = 'Dla tabeli %1 nie określono obiektu właściciel tabeli, określenie atrybutów tabeli jest niemożliwe.';
							|tr = '%1 tablosu için tablonun nesne sahibi tanımlanmadı, tablonun özniteliklerini tanımlamak mümkün değildir'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText,
				TreeRow.Presentation);
			Raise ErrorText;
		Else
			ValueType = ParentRow.ValueType;
		EndIf;
	Else
		ValueType = TreeRow.ValueType;
	EndIf;
	
	If ValueType.Types().Count() = 0 Then
		ErrorText = NStr("vi = 'Đối với dòng của toán hạng, chưa đặt kiểu giá trị, không thể quét';
						|ru = 'Для строки операнда не задан тип значения, развертка не возможна';
						|en = 'Value type is not specified for operand string, expanding is not available'; fa = 'Value type is not specified for operand string, expanding is not available';
						|it = 'Per la riga dell''operando non è stato impostato il tipo di valore, impossibile espandere';
						|pl = 'Dla wiersza operandu nie zadano typu wartości, rozwinięcie jest niemożliwe';
						|tr = 'İşlenen satırı için değer tipi belirtilmedi, genişletme mümkün değildir'");
		Raise ErrorText;
	EndIf;
	
	ParametersForAddingRows = OptionsForAddingRowByLayoutField();
	ParametersForAddingRows.ParentFieldValueType = ValueType;
	
	If SweepRestrictions = Undefined Then
		ParametersForAddingRows.RecursivelyExpandLayoutSchemeOperands = True;
		DisplayCharacteristics = True;
		AdditionalAttributeSets = New Array;
	Else
		ParametersForAddingRows.RecursivelyExpandLayoutSchemeOperands = SweepRestrictions.RecursivelyExpandLayoutSchemeOperands;
		DisplayCharacteristics = SweepRestrictions.DisplayCharacteristics;
		AdditionalAttributeSets = SweepRestrictions.AdditionalAttributeSets;
	EndIf;
	
	ParametersForAddingRows.IDPrefixToDelete = "Attribute";
	// programmatically generated SKD, the "Props" field has no representation in the user language.
	ParametersForAddingRows.PresentationPrefixToRemove = "Attribute";
	
	If TypeOf(TreeRow) = Type("FormDataTreeItem") Then
		// The tree on the form has an expanded composition of columns, including "Full Line Identifier" and "Full Line representation".
		// If the operand tree is prepared before it is loaded onto the form, these columns do not yet exist, they will
		// be calculated later when loading.
		// Therefore, filling in the prefixes to be added is only for the row of the form tree.
		If TreeRow.IncludedInID Then
			ParametersForAddingRows.IDPrefixToAdd = TreeRow.FullRowID;
			ParametersForAddingRows.PresentationPrefixToAdd  = TreeRow.FullRowPresentation;
		Else
			ParametersForAddingRows.IDPrefixToAdd = "";
			ParametersForAddingRows.PresentationPrefixToAdd  = "";
		EndIf;
	EndIf;
	
	CompositionSchema = LayoutDiagramForGettingPropsByValueType(ValueType, DisplayCharacteristics, AdditionalAttributeSets);
	
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	For Each AvailableField In SettingsComposer.Settings.SelectionAvailableFields.Items Do
		
		// System fields at the first level - the level of typed props.
		If AvailableField.Folder Then
			Continue;
		EndIf;
		If AvailableField.Table Then
			Continue;
		EndIf;
		
		If UnfoldsTable Then
			
			// In the available elements, we look for a table with the same identifier and expand only it.
			For Each AvailableLayoutField In AvailableField.Items Do
		
				If Not AvailableLayoutField.Table Then
					Continue;
				EndIf;
				
				FieldID = RowIdOfLayoutField(AvailableLayoutField, ParametersForAddingRows);
				If FieldID <> TreeRow.Id Then
					Continue;
				EndIf;
				
				ParametersForAddingRows.IDPrefixToDelete = ParametersForAddingRows.IDPrefixToDelete
					+ "." + TreeRow.Id;
				ParametersForAddingRows.PresentationPrefixToRemove = ParametersForAddingRows.PresentationPrefixToRemove
					+ "." + TreeRow.Presentation;
				
				FieldList = SortedListOfLayoutFields(
					AvailableLayoutField.Items,
					ParametersForAddingRows);
					
				For Each ListItem In FieldList Do
					NewTreeLineByLayoutField(ListItem,
						TreeRow,
						ParametersForAddingRows,
						SweepRestrictions);
				EndDo;
				
				Break;
			EndDo;
			
		Else
			
			FieldList = SortedListOfLayoutFields(
				AvailableField.Items,
				ParametersForAddingRows);
				
			For Each ListItem In FieldList Do
				NewTreeLineByLayoutField(ListItem,
					TreeRow,
					ParametersForAddingRows,
					SweepRestrictions);
			EndDo;
			
		EndIf;
	EndDo;
	
	
EndProcedure

// Expand the operand tree string by one level according to its value type (add subordinate strings-details and characteristics).
// Called from a form with an operand tree when the tree string is expanded. Search for a string by its ID and delete a subordinate service string.
// 
// Parameters:
// 	OperandTreeOfForm - FormDataTree - Operand tree on the form.
// 	IDOfCurRowOfOperandTree - Number - ID of the form tree row.
// 	MaximumRowExpansionLevel - Number - The default value is 0 (not controlled). Controls the maximum level of rows in the tree when scanning.
//
Procedure ExpandOperandStringOfFormTree(OperandTreeOfForm, IDOfCurRowOfOperandTree, MaximumRowExpansionLevel = 0) Export
	
	TreeRow = OperandTreeOfForm.FindByID(IDOfCurRowOfOperandTree);
	SubordinateRows = TreeRow.GetItems();
	
	// In subordinate lines, one line with the Subordinate Line flag is serviceable
	// to display the presence of subordinate lines. This line needs to be deleted.
	ServiceLineToDelete = Undefined;
	For Each SubordinateRow In SubordinateRows Do
		If SubordinateRow.SubordinateRowInternal Then
			ServiceLineToDelete = SubordinateRow;
		EndIf;
	EndDo;
	
	SweepRestrictions = LimitationsOfOperandSweep();
	SweepRestrictions.MaximumRowExpansionLevel = MaximumRowExpansionLevel;
	
	ExpandOperandString(TreeRow, SweepRestrictions);
	
	If Not ServiceLineToDelete = Undefined Then
		SubordinateRows.Delete(ServiceLineToDelete);
	EndIf;
	
EndProcedure


// Adds the first level of fields in the data layout scheme to the specified location in the operand tree.
// 
// Parameters:
// 	PlaceAdded - ValueTree, ValueTreeRow - Strings are added directly to the operand tree
// 				or to the specified string in the operand tree.
// 	CompositionSchema - DataCompositionSchema - An arbitrary layout scheme whose selection fields must be added
// 				to the specified location.
// 	SweepRestrictions - Undefined, Structure - See ProcessingOfFormulas.LimitationsOfOperandSweep.
//
Procedure AddAvailableFieldsToTreeUsingLayoutScheme(PlaceAdded, CompositionSchema, SweepRestrictions = Undefined) Export
	
	
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	ParametersForAddingRows = OptionsForAddingRowByLayoutField();
	ParametersForAddingRows.AddingFieldsAccordingToLayoutScheme = True;
	
	If SweepRestrictions = Undefined Then
		ParametersForAddingRows.RecursivelyExpandLayoutSchemeOperands = True;
	Else
		ParametersForAddingRows.RecursivelyExpandLayoutSchemeOperands = SweepRestrictions.RecursivelyExpandLayoutSchemeOperands;
	EndIf;
	
	// Processing the availability of details in a custom layout scheme.
	// It is expensive to expand the available fields for complex composite types, so
	// the availability flags of the fields in the schema itself are analyzed.
	FieldsWithRestrictedBankingDetails = New Array;
	For Each DataSet In CompositionSchema.DataSets Do
		For Each SetField In DataSet.Fields Do
			CheckAdditionOfExpandedDCSFieldGroups(ParametersForAddingRows.DCSFieldGroupsToExpand,
				SetField.DataPath);
			If Not TypeOf(SetField) = Type("DataCompositionSchemaDataSetField") Then
				Continue;
			EndIf;
			FieldName = SetField.DataPath;
			UseRestriction = SetField.UseRestriction.Field;
			AttributeUseRestriction = SetField.AttributeUseRestriction.Field;
			If Not UseRestriction And AttributeUseRestriction Then
				If FieldsWithRestrictedBankingDetails.Find(FieldName) = Undefined Then
					FieldsWithRestrictedBankingDetails.Add(FieldName);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	For Each FieldToEval In CompositionSchema.CalculatedFields Do
		CheckAdditionOfExpandedDCSFieldGroups(ParametersForAddingRows.DCSFieldGroupsToExpand,
			SetField.DataPath);
		FieldName = FieldToEval.DataPath;
		UseRestriction = FieldToEval.UseRestriction.Field;
		//Restricting the use of Requesits = Computable field.Restricting the use of Requesits.Field;
		//If THERE is NO restriction on the use And restriction on the use of requirements, Then
		//	If the fields limit the availability of requesits.Find(Field name) = Undefined Then
		//		Fields limiting the availability of requesits.Add(Field name);
		//	The end if;
		//The end if;
	EndDo;
	
	FieldList = SortedListOfLayoutFields(
		SettingsComposer.Settings.SelectionAvailableFields.Items,
		ParametersForAddingRows,
		FieldsWithRestrictedBankingDetails);
	
	For Each ListItem In FieldList Do
		NewTreeLineByLayoutField(ListItem,
			PlaceAdded, ParametersForAddingRows, SweepRestrictions);
	EndDo;
	
EndProcedure

// Loads the value tree initialized by the developer into the tree on the form
// , and also fills in the corresponding operand values if the corresponding parameter is passed.
// 
// Parameters:
// 	FormTree - FormDataTree - The tree on the form that the developer initialized value tree is loaded into.
// 				Has service columns that are not present in the tree Operands, they are filled in in this method.
// 	OperandsTree - ValueTree - Initialized by the developer the value tree. See GetEmptyOperandTree.
// 	ArrayOfAllowedOperands - Undefined, Array - names of allowed operands for checking the correctness of the formula.
// 	OperandValues - Undefined - The default value. The correspondence of operands and their values is not filled in.
// 				Matching - Matching operands and their values:
// 					* Key - String - ID of the operand.
// 					* Value - Number - the value of the operand.
Procedure LoadOperandTreeIntoTreeOfForm(FormTree, OperandsTree, ArrayOfAllowedOperands = Undefined,
						OperandValues = Undefined) Export
	
	FormTree.GetItems().Clear();
	LoadOperandTreeStrings(FormTree, OperandsTree, ArrayOfAllowedOperands, OperandValues);
	
EndProcedure



#EndRegion

#Region WorkingWithOperatorTree

// Forms a value tree with the Name, Operator, and Shift columns.
//
// Returns:
//  ValueTree - Empty operator tree with columns:
//  * Description - String - Name of the operator.
//  * Operator - String - Operator.
//  * Move - Number - Operator shift.
//
Function GetEmptyOperatorsTree() Export
	
	Tree = New ValueTree();
	Tree.Columns.Add("Presentation", New TypeDescription("String")); // Representation of the operator in the user's language.
	Tree.Columns.Add("Id", New TypeDescription("String")); // Operator ID in the code language.
	
	// The text inserted into the formula, the operator identifier in the code language with additional elements - brackets,
	// an indication of parameters, explanations of parameters can be in the user's language.
	// For example, for the format function for the configuration with the Russian language of the code for the user with the English 
	// interface "Format(<Value>, <Format string>)".
	Tree.Columns.Add("StructureToInsert", New TypeDescription("String"));
	
	Tree.Columns.Add("Move", New TypeDescription("Number"));
	Tree.Columns.Add("Explanation", New TypeDescription("String"));
	
	Tree.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	
	Return Tree;
	
EndFunction

// Adds a group of operators with the passed name to the operator tree.
//
// Parameters:
//  Tree - ValueTree - the operator tree. see the function Get a list of operators().
//  Id - String - Operator ID in the built-in language.
//  Presentation - String - Name of the operator tree group in the user's language.
//
// Returns:
//  ValueTreeRow - Added a group of operators.
//
Function AddOperatorsGroup(Tree, Id, Presentation) Export
	
	NewFolder = Tree.Rows.Add();
	NewFolder.Id = Id;
	NewFolder.Presentation = Presentation;
	NewFolder.IsFolder = True;
	
	Return NewFolder;
	
EndFunction

// Adds a group of operators with the passed name to the operator tree.
//
// Parameters:
//  PlaceAdded - ValueTree, ValueTreeRow - The tree operators or group of operators to which you want to add an operator.
//  Id - String - Operator ID in the built-in language.
//  StructureToInsert - String - Text that is added to the formula when choosing the identifier with parentheses and parameters.
//  Presentation - String - Representation of the operator in the user's language.
//  Explanation - String - Optional explanation for the user what the operator does.
//  Move - Number - required to determine the cursor position.
//
// Returns:
//  ValueTreeRow - Added operator.
//
Function AddOperator(PlaceAdded, Id, StructureToInsert, Presentation, Explanation = "", Move = 0) Export
	
	NewRow = PlaceAdded.Rows.Add();
	NewRow.Id = Id;
	NewRow.StructureToInsert = StructureToInsert;
	NewRow.Presentation = Presentation;
	NewRow.Explanation = Explanation;
	NewRow.Move = Move;
	NewRow.IsFolder = False;
	
	Return NewRow;
	
EndFunction

// Forms a tree with standard operators" +", "-", "*", "/"
//
// Returns:
//  ValueTree - the operator tree. see the function Get a list of operators().
//
Function GetStandardOperatorsTree() Export
	
	Tree = GetEmptyOperatorsTree();
	
	PresentationOfOperatorGroup = NStr("vi = 'Toán tử';
										|ru = 'Операторы';
										|en = 'Operators'; fa = 'عملگرها';
										|it = 'Operatori';
										|pl = 'Operatory';
										|tr = 'Operatörler'");
	OperatorsGroup = AddOperatorsGroup(Tree, "Operators", PresentationOfOperatorGroup);
	
	AddOperator(OperatorsGroup, "+", " + ", "+");
	AddOperator(OperatorsGroup, "-", " - ", "-");
	AddOperator(OperatorsGroup, "*", " * ", "*");
	AddOperator(OperatorsGroup, "/", " / ", "/");
	
	Return Tree;
	
EndFunction

// Fills in the operator tree for the formula constructor.
//
// Parameters:
//  Parameters - Structure - contains the types of operators to add to the tree.
//  UUID - UUID - the unique ID of the form in which actions are performed 
//  		is required for correct placement in temporary storage.
//
// Returns:
//  String - the address in the temporary storage.
//
Function BuildTreeOfOperators(Parameters, UUID) Export
	
	Tree = GetEmptyOperatorsTree();
	
	If Parameters.Property("StandardOperators") And Parameters.StandardOperators Then
		AddGroupOfStandardOperators(Tree);
	EndIf;
	
	If Parameters.Property("BooleanOperators") And Parameters.BooleanOperators Then
		AddGroupOfLogicalOperators(Tree);
	EndIf;
	
	If Parameters.Property("Functions") And Parameters.Functions Then
		AddFunctionGroup(Tree);
	EndIf;
	
	Return PutToTempStorage(Tree, UUID);
	
EndFunction

#EndRegion

#Region CheckingFormula

// Returns a template for formula validation parameters.
// 
// Returns:
// 	Structure - LongDesc:
// * CommonModuleFunctions - Array of See ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction - Description of the added functions.
// * FormulaForCalculationInQuery - Boolean - Indicates whether the function is executed as an expression of the request text.
// * Field - String - The path to the form details for which the message was output, or to the object data.
// * DataPath - String - Contains the path in the form that will display the message to the object associated with this message.
// * ErrorMessage - String - The default value is "". If the message is filled in, the specified message will be displayed if there is an error.
// * NotOutputMessages - Boolean - Flag that allows you to disable the output of error messages.
//
Function FormulaValidationParameters() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("CommonModuleFunctions", New Array);
	CheckParameters.Insert("FormulaForCalculationInQuery", False);
	CheckParameters.Insert("Field", "");
	CheckParameters.Insert("DataPath", "");
	CheckParameters.Insert("ErrorMessage", "");
	CheckParameters.Insert("NotOutputMessages", False);
	
	Return CheckParameters;
	
EndFunction

// Checks whether the formula is correct
//
// Parameters:
//   Formula - String - text of the formula.
//   Operands - Array of String - operands of the formula.
//   ResultType - TypeDescription - the expected type of the result of the computation.
//   CheckParameters - See FormulaValidationParameters
//
// Returns:
//  Boolean - False if there are errors, otherwise True.
//
Function CheckFormula(Formula, Operands, ResultType, Val CheckParameters = Undefined) Export	
	
	Result = True;
	
	If CheckParameters = Undefined Then
		CheckParameters = FormulaValidationParameters();
	EndIf;
	
	If ValueIsFilled(Formula) Then
		
		ResultTypes = ResultType.Types();
		If ResultTypes.Count() = 1
			And ResultTypes[0] = Type("String") Then
			CalculationText = """String"" + " + Formula;
			ReplacementValue = """1""";
		ElsIf ResultTypes.Count() = 1
			And ResultTypes[0] = Type("Date") Then
			If CheckParameters.FormulaForCalculationInQuery Then
				ReplacementValue = CurrentSessionDate();
			Else
				ReplacementValue = 1;
			EndIf;
			CalculationText = Formula;
		Else
			ReplacementValue = 1;
			CalculationText = Formula;
		EndIf;
		
		TypesOfOperands = Undefined;
		CheckParameters.Property("TypesOfOperands", TypesOfOperands);
		
		ProcessingOfFormulasServerCall.GetCalculationText(
			CalculationText,
			Operands,
			ReplacementValue,
			TypesOfOperands);
		
		Try
			If CheckParameters.FormulaForCalculationInQuery Then
				
				CalculationResult2 = ProcessingOfFormulasServerCall.CheckQueryFormula(CalculationText, ReplacementValue);
				
			Else
				If CheckParameters.CommonModuleFunctions.Count() > 0 Then
					
					For Each FunctionProperties In CheckParameters.CommonModuleFunctions Do
						CalculationText = StrReplace(CalculationText, FunctionProperties.Id, FunctionProperties.FullPath);
					EndDo; 
					
				EndIf;
				
				CalculationResult2 = Common.CalculateInSafeMode(CalculationText);
			EndIf;
			VerificationText = StrReplace(Formula, Chars.LF, "");
			VerificationText = StrReplace(VerificationText, " ", "");
			NoSeparators = Find(VerificationText, "][")
				+ Find(VerificationText, """[")
				+ Find(VerificationText, "]""");
			If NoSeparators > 0 Then
				ReportErrorInFormula(Formula,
					CalculationText,
					NStr("vi = 'Giữa các toán hạng cần có toán tử hoặc dấu chia tách';
						|ru = 'Между операндами должен присутствовать оператор или разделитель';
						|en = 'An operator or a separator is to be between the operands'; fa = 'An operator or a separator is to be between the operands';
						|it = 'An operator or a separator is to be between the operands';
						|pl = 'An operator or a separator is to be between the operands';
						|tr = 'İşlenenlerin arasında bir operatör veya sınırlayıcı olmalıdır'"),
					CheckParameters,
					Result);
			EndIf;
			
			CalculationResultTypeIsCorrect = False;
			
			For Each ValidType_ In ResultType.Types() Do
				If TypeOf(CalculationResult2) = ValidType_ Then
					CalculationResultTypeIsCorrect = True;
					Break;
				EndIf;
			EndDo;
			
			If Not CalculationResultTypeIsCorrect Then
				ErrorReason = NStr("vi = 'Kết quả tính toán cần có kiểu %1';
									|ru = 'Результат расчета должен быть типа %1';
									|en = 'Calculation result must be of the %1 type'; fa = 'Calculation result must be of the %1 type';
									|it = 'Calculation result must be of the %1 type';
									|pl = 'Calculation result must be of the %1 type';
									|tr = 'Hesaplama sonucu %1 türünde olmalıdır'");
				ErrorReason = StrTemplate(ErrorReason, ResultType);
				
				ReportErrorInFormula(Formula,
					CalculationText,
					ErrorReason,
					CheckParameters,
					Result);
			EndIf;
		
		Except
			
			Result = False;
			
			If ValueIsFilled(CheckParameters.ErrorMessage) Then
				MessageText = CheckParameters.ErrorMessage;
			Else
				MessageText = NStr("vi = 'Đã phát hiện lỗi trong công thức. Hãy kiểm tra công thức. Cần lập công thức theo quy tắc ghi lại biểu thức bằng ngôn ngữ hệ thống 1C:Enterprise.';
									|ru = 'В формуле обнаружены ошибки. Проверьте формулу. Формулы должны составляться по правилам написания выражений на встроенном языке 1С:Предприятия.';
									|en = 'Errors are detected in the formula. Check the formula. Formulas should be created based on the expression rules of 1C:Enterprise script.'; fa = 'Errors are detected in the formula. Check the formula. Formulas should be created based on the expression rules of 1C:Enterprise script.';
									|it = 'Sono stati rilevati errori nella formula. Controllate la formula. Le formule devono essere composte secondo le regole di scrittura delle espressioni del linguaggio incorporato 1C:Enterprise.';
									|pl = 'We wzorze zostały wykryte błędy. Sprawdź wzór. Wzory powinny być sporządzane zgodnie z zasadami pisowni wyrażeń na wbudowanym języku 1C:Enterprise.';
									|tr = 'Formülde hatalar bulundu. Formülü kontrol edin. Formüller, yerleşik 1C:Enterprise dilinde ifade yazma kurallarına göre hazırlanmalıdır.'");
			EndIf;
			
			ReportErrorInFormula(Formula,
				CalculationText,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				CheckParameters,
				Result,
				MessageText);
			
		EndTry;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ExecutionOfFormulas

#Region ObtainingExpressionsWithPresentationOfCharacteristicsForOnlineVerification

// Returns a matching expression with IDs - an expression with views.
// It is used for online verification of the correctness of SKD expressions from the Analytics and sub-konto selection forms.
// If you specify contact information for which multiple views are suitable for the ID, it returns
// the first appropriate representation of contact information
// (for correct display in the field on the form), rather than a complex expression using the SELECT WHEN construct.
// To check expressions online, you should substitute representations of characteristics in expressions.
// The use of feature name overriding for online validation is not used because of the high overhead
// of linker initialization.
// 
// Parameters:
// 	ExpressionsWithIdentifiers - Array of String - operand expression in terms of identifiers. For example, the item. {ETC.Forwarder}.Head counteragent. {KI. Phone}
// 	CompositionSchema - Undefined, DataCompositionSchema - Layout for which to check existence of the fields of the operands.
// 				If the layout scheme is not specified, expression parsing is not possible.
// 	
// Returns:
// 	Map of KeyAndValue - matching expressions in terms of identifiers and expressions using representation:
// 	 *Key - String - expression with identifiers. For example, the Nomenclature.{DR.Freight forwarder}.The head counteragent.{KI.Phone number}.
// 	 *Value - String - an expression with representations of characteristics. For example, the Nomenclature.[Chief Freight forwarder].The head counteragent.Phone number.
//
Function ExpressionsWithPresentationsOfCharacteristicsForOnlineVerification(ExpressionsWithIdentifiers, CompositionSchema = Undefined) Export
	
	ExpressionMatches = New Map;
	
	PropertiesOfCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	
	// Depending on the uniqueness property of the Name and the distribution of the Table characteristics, there are characteristics
	// where one characteristic identifier represents one database object (and, accordingly, a representation),
	// and there are characteristics (like contact information) where one identifier is unique only within its set.
	// For example, the identifier "Additional Telephone" may be for contractors and organizations, and database objects may have
	// a different representation.
	// We check for the presence of different elements with different views. Parsing according to the layout scheme
	// is performed as a last resort due to high overhead costs.
	
	TableOfExpressions = New ValueTable();
	TableOfExpressions.Columns.Add("MetadataOfCharacteristicsSource");
	TableOfExpressions.Columns.Add("ExpressionOfCharacteristic", New TypeDescription("String"));
	TableOfExpressions.Columns.Add("PathToCharacteristic", New TypeDescription("String"));
	
	For Each ExpressionWithIdentifiers In ExpressionsWithIdentifiers Do
		If StrFind(ExpressionWithIdentifiers, "{") = 0 Then
			// There are no characteristics.
			ExpressionMatches.Insert(ExpressionWithIdentifiers, ExpressionWithIdentifiers);
		Else
			
			OperandParts = ProcessingOfFormulasClientServer.OperandParts(ExpressionWithIdentifiers);
			PathToCharacteristic = "";
			For Each PartOfOperand In OperandParts Do
				If StrFind(PartOfOperand, "{") = 1 Then
					MetadataCharacteristics_ = PropertiesCharacteristics(PartOfOperand).Metadata;
					PropertiesCharacteristics = PropertiesOfCharacteristics.Find(MetadataCharacteristics_, "SourceMetadata");
					
					ExpressionString = TableOfExpressions.Add();
					ExpressionString.MetadataOfCharacteristicsSource = PropertiesCharacteristics.SourceMetadata;
					ExpressionString.ExpressionOfCharacteristic = PartOfOperand;
					ExpressionString.PathToCharacteristic = PathToCharacteristic;
					
				EndIf;
				PathToCharacteristic = PathToCharacteristic + ?(PathToCharacteristic = "", "", ".") + PartOfOperand;
			EndDo;
		EndIf;
	EndDo;
	
	If TableOfExpressions.Count() > 0 Then
		TableOfExpressions.GroupBy("MetadataOfCharacteristicsSource, ExpressionOfCharacteristic, PathToCharacteristic");
		
		TableOfExpressions.Columns.Add("ParsingIsRequired", New TypeDescription("Boolean"));
		TableOfExpressions.Columns.Add("CharacteristicPresentation", New TypeDescription("String"));
		
		TableOfExpressions.Indexes.Add("MetadataOfCharacteristicsSource");
		TableOfExpressions.Indexes.Add("ExpressionOfCharacteristic");
		
		// Getting unique representations of characteristics by identifiers.
		For Each PropertiesCharacteristics In PropertiesOfCharacteristics Do
			Search = New Structure("MetadataOfCharacteristicsSource", PropertiesCharacteristics.SourceMetadata);
			RowsOfCharacteristicsType = TableOfExpressions.FindRows(Search);
			If RowsOfCharacteristicsType.Count() = 0 Then
				Continue;
			EndIf;
			IDs = New Array;
			For Each TableRow In RowsOfCharacteristicsType Do
				If IDs.Find(TableRow.ExpressionOfCharacteristic) = Undefined Then
					IDs.Add(TableRow.ExpressionOfCharacteristic);
				EndIf;
			EndDo;
			
			Query = New Query;
			QueryText =
			"SELECT DISTINCT
			|	&ExpressionIdentifier AS Id,
			|	PRESENTATION(Table.Ref) AS Presentation
			|FROM
			|	&SourceOfCharacteristics AS Table
			|WHERE
			|	&ExpressionIdentifier IN (&IDs)
			|TOTALS BY
			|	Id";
			
			SourceOfCharacteristics = ProcessingOfFormulasCached.FullNameOfDataTable(
				PropertiesCharacteristics.SourceMetadata.FullName());
			ExpressionIdentifier = ExpressionOfFullFeatureID(PropertiesCharacteristics.SourceMetadata, False);
			ExpressionIdentifier = StrReplace(ExpressionIdentifier, "%TableName%", "Table");
			QueryText = StrReplace(QueryText, "&SourceOfCharacteristics", SourceOfCharacteristics);
			QueryText = StrReplace(QueryText, "&ExpressionIdentifier", ExpressionIdentifier);
			
			Query.Text = QueryText;
			Query.SetParameter("IDs", IDs);
			
			SelectionID = Query.Execute().Select(QueryResultIteration.ByGroups, "Id");
			While SelectionID.Next() Do
				Id = SelectionID.Id;
				ThereAreVarietyOfPresentations = False;
				CharacteristicPresentation = "";
				PresentationSelection = SelectionID.Select();
				While PresentationSelection.Next() Do
					CharacteristicPresentation = PresentationSelection.Presentation;
					Break;
				EndDo;
				If Not PropertiesCharacteristics.UniquenessOfNameWithinEntireCharacteristicsTable Then
					ThereAreVarietyOfPresentations = (PresentationSelection.Count() > 1);
					If ThereAreVarietyOfPresentations Then
						CharacteristicPresentation = "";
					EndIf;
				EndIf;
				
				ExpressionTableRows = TableOfExpressions.FindRows(New Structure("ExpressionOfCharacteristic", Id));
				For Each TableRow In ExpressionTableRows Do
					TableRow.CharacteristicPresentation = CharacteristicPresentation;
					TableRow.ParsingIsRequired = ThereAreVarietyOfPresentations;
				EndDo;
			EndDo;
		EndDo;
		
		// Getting representations of characteristics, if the representations are not unique.
		TableOfExpressions.Sort("ParsingIsRequired, PathToCharacteristic");
		
		ExpressionsThatRequireParsing = TableOfExpressions.FindRows(New Structure("ParsingIsRequired", True));
		If ExpressionsThatRequireParsing.Count() > 0
			And TypeOf(CompositionSchema) = Type("DataCompositionSchema") Then
			// Optimization of parsing. Stores representations of characteristics calculated during parsing.
			FeaturePresentationCache = New Map();
			// Optimization of parsing. Stores the nearest calculated type.
			TypeCachePathToCharacteristics = New Map;
			
			Composer = New DataCompositionSettingsComposer;
			Composer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
			Composer.LoadSettings(CompositionSchema.DefaultSettings);
			Composer.Settings.Filter.Items.Clear();
			
			For Each TableRow In ExpressionsThatRequireParsing Do
				FullFeaturePath = TableRow.PathToCharacteristic + "." + TableRow.ExpressionOfCharacteristic;
				CharacteristicPresentation = FeaturePresentationCache.Get(FullFeaturePath);
				If ValueIsFilled(CharacteristicPresentation) Then
					TableRow.CharacteristicPresentation = CharacteristicPresentation;
					TableRow.ParsingIsRequired = False;
					Continue;
				EndIf;
				
				PathParts = ProcessingOfFormulasClientServer.OperandParts(TableRow.PathToCharacteristic);
				// Attempt to find the nearest cached data type.
				NumberOfSearchAttempts = PathParts.Count();
				NearestPathFound = "";
				DescriptionOfTypesOnNearestPath = Undefined;
				For AttemptNumber = 1 To NumberOfSearchAttempts Do
					PathOfCurAttempt = "";
					For Cnt = 0 To NumberOfSearchAttempts - AttemptNumber Do
						PathOfCurAttempt = PathOfCurAttempt + ?(PathOfCurAttempt = "", "", ".") + PathParts[Cnt];
					EndDo;
					DescriptionOfTypesOnNearestPath = TypeCachePathToCharacteristics.Get(PathOfCurAttempt);
					If Not DescriptionOfTypesOnNearestPath = Undefined Then
						NearestPathFound = PathOfCurAttempt;
						Break;
					EndIf;
				EndDo;
				If NearestPathFound = "" Then
					// Referring to the first-level SCD field (this cannot be a characteristic).
					// All fields of the first level are immediately added to the cached fields.
					NearestPathFound = PathParts[0];
					For Each AvailableField In Composer.Settings.Selection.SelectionAvailableFields.Items Do
						If AvailableField.Folder Or AvailableField.Table Then
							Continue;
						EndIf;
						Path = String(AvailableField.Field);
						If TypeCachePathToCharacteristics.Get(Path) = Undefined Then
							TypeCachePathToCharacteristics.Insert(Path, AvailableField.ValueType);
						EndIf;
						If Path = PathParts[0] Then
							DescriptionOfTypesOnNearestPath = AvailableField.ValueType;
						EndIf;
					EndDo;
				EndIf;
				If NearestPathFound = "" Then
					// The layout scheme has been changed and does not contain the previous path.
					TableRow.CharacteristicPresentation = TableRow.ExpressionOfCharacteristic;
					TableRow.ParsingIsRequired = False;
				EndIf;
				While TableRow.ParsingIsRequired Do
					
					SchemaByType = LayoutDiagramForGettingPropsByValueType(DescriptionOfTypesOnNearestPath);
					Composer = New DataCompositionSettingsComposer();
					Composer.Initialize(New DataCompositionAvailableSettingsSource(SchemaByType));
					
					ParametersForAddingRows = OptionsForAddingRowByLayoutField();
					ParametersForAddingRows.ParentFieldValueType = DescriptionOfTypesOnNearestPath;
					ParametersForAddingRows.IDPrefixToDelete = "Attribute";
					// programmatically generated SKD, the "Props" field has no representation in the user language.
					ParametersForAddingRows.PresentationPrefixToRemove = "Attribute";
					
					// Getting representations of characteristics.
					ServiceDetailsField = Undefined;
					For Each AvailableField In Composer.Settings.SelectionAvailableFields.Items Do
						If Not AvailableField.Folder
							And Not AvailableField.Table
							And String(AvailableField.Field) = "Attribute" Then
							ServiceDetailsField = AvailableField;
							Break;
						EndIf;
					EndDo;
					NextStepFound = False;
					If Not ServiceDetailsField = Undefined Then
						// Reference type.
						ListWithTypesAndPresentations = SortedListOfLayoutFields(ServiceDetailsField.Items,
							ParametersForAddingRows);
						For Each ListItem In ListWithTypesAndPresentations Do
							AvailableField = ListItem.Value.Field;
							IDOfNewLine = RowIdOfLayoutField(AvailableField, ParametersForAddingRows);
							FieldPresentation = ListItem.Presentation;
							StringValueType = ListItem.Value.ValueType; // a type with a possible redefinition of the type.
							ThisIsCharacteristic = ListItem.Value.ThisIsCharacteristic;
							
							Path = NearestPathFound + "." + IDOfNewLine;
							TypeCachePathToCharacteristics.Insert(Path, StringValueType);
							
							If ThisIsCharacteristic Then
								FeaturePresentationCache.Insert(Path, FieldPresentation);
							EndIf;
							If FullFeaturePath = Path Then
								NextStepFound = True;
								NearestPathFound = Path;
								DescriptionOfTypesOnNearestPath = StringValueType;
								
								TableRow.CharacteristicPresentation = FieldPresentation;
								TableRow.ParsingIsRequired = False;
							Else
								SearchString = Path + ".";
								If StrFind(FullFeaturePath, SearchString) = 1 Then
									NextStepFound = True;
									NearestPathFound = Path;
									DescriptionOfTypesOnNearestPath = StringValueType;
								EndIf;
							EndIf;
						EndDo;
					EndIf;
					If Not NextStepFound Then
						// The layout scheme has been changed or the feature ID has been changed.
						TableRow.CharacteristicPresentation = "";
						TableRow.ParsingIsRequired = False;
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		
		ColumnSortingDirection = "DESC";
		TableOfExpressions.Sort("PathToCharacteristic" + " " + ColumnSortingDirection);
		
		For Each ExpressionWithIdentifiers In ExpressionsWithIdentifiers Do
			
			// The expression contained characteristics and was not placed in a match earlier.
			ExpressionContainsCharacteristics = (ExpressionMatches.Get(ExpressionWithIdentifiers) = Undefined);
			If ExpressionContainsCharacteristics Then
				
				NewExpressionValue = ExpressionWithIdentifiers;
				For Each PresentationsRow In TableOfExpressions Do
					If ValueIsFilled(PresentationsRow.CharacteristicPresentation) Then
						FullPathToCharacterization = PresentationsRow.PathToCharacteristic + "." + PresentationsRow.ExpressionOfCharacteristic;
						If StrFind(NewExpressionValue, FullPathToCharacterization) = 1 Then
							If Not ValueIsFilled(PresentationsRow.CharacteristicPresentation) Then
								// The characteristic could not be parsed.
								CharacteristicPresentation = PresentationsRow.ExpressionOfCharacteristic;
							Else
								CharacteristicPresentation = PresentationOfCharacteristicInDCSExpression(
									PresentationsRow.CharacteristicPresentation);
							EndIf;
							NewExpressionValue = Mid(NewExpressionValue, 1, StrLen(PresentationsRow.PathToCharacteristic + "."))
								+ CharacteristicPresentation + Mid(NewExpressionValue, StrLen(FullPathToCharacterization) + 1);
						EndIf;
					EndIf;
				EndDo;
				
				ExpressionMatches.Insert(ExpressionWithIdentifiers, NewExpressionValue);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return ExpressionMatches;
	
EndFunction

#EndRegion

#Region GettingDataForFormulas

// Calculates the values of operand expressions for a table of values. Returns a data table with added columns of calculation results.
// Data table columns must be typed.
// 
// Parameters:
// 	DataTable - ValueTable - A data table containing an arbitrary number of typed columns.
// 	CalculationExpressions - Map - The expression (operand) of the calculation and the name of the result column. Depending
// 				on the context of the formula execution, all expressions (operands) that can be calculated
// 				from the data table are specified:
// 	 * Key - String - Calculation expression in formula operand format.
// 	 			For example, "Nomenclature.{DR.Freight forwarder}.The head counteragent.{KI.Phone}".
// 	 			If the calculation expression starts with a specific column, for example, "Nomenclature", then this column
// 	 			should be in the data table.
// 	 * Value - String - The name of the column in which the result of the expression calculation will be placed.
// 	FeatureColumnNames - Undefined, Map - if the calculation expression starts with a characteristic,
// 				then you must specify the name of the column that contains the corresponding characteristic values.
// 				For example, when calculating the name of a new item not recorded in the database,
// 				the values of the operands can be calculated from the additional Attributes filled in in the goods card:
// 		* Key - String - Part of the operand, the expression of the characteristic in the format of formulas. For example "{Dr.The main nomenclature of the description}".
// 		* Value - String - The name of the column in the calculation source table.
// 	PerformExpressionChecks - Boolean - A flag indicating whether to perform a full scan of the expression.
// 				If the entire expression is not fully checked, this can save time on parsing expressions
// 				(assuming that the expressions are specified correctly), which can be critical for the mechanisms used
// 				in the transaction. If the entire expression is not fully checked, expressions are parsed only to
// 				get the types for which the characteristic is specified, or to get a representation of the characteristic.
// 				If the entire expression is fully checked, the entire expression is checked for correctness
// 				regardless of whether it has any characteristics.
// 	
// Returns:
// 	Structure - structure with properties:
// * ResultsTable - ValueTable - A table containing columns of the calculation source table and columns of calculation results:
// 	 ** RowIndex - Number - column of the row index. If it is not in the source table, it will be added.
// * HasErrors - Boolean - Flag the presence of errors in the conversion expressions.
// * ConversionErrorMessages - Map - Conversion error messages, if any:
//    ** Key - String - The original expression for which the error was registered.
//    ** Value - String - text of the error message.
//
Function GetOperandDataForDataTable(DataTable, CalculationExpressions, FeatureColumnNames = Undefined,
			PerformExpressionChecks = False) Export
	
	Result = New Structure;
	Result.Insert("ResultsTable", Undefined);
	Result.Insert("HasErrors", False);
	Result.Insert("ConversionErrorMessages", New Map);
	
	If DataTable.Columns.Find("RowIndex") = Undefined Then
		DescriptionOfIndexType = New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative));
		DataTable.Columns.Add("RowIndex", DescriptionOfIndexType);
		CurIndexValue = 0;
		For Each TableRow In DataTable Do
			TableRow.RowIndex = CurIndexValue;
			CurIndexValue = CurIndexValue + 1;
		EndDo;
	EndIf;
	
	ErrorText = "";
	NamesOfColumnsUsed = New Array;
	InitialChecksForDataAcquisition(DataTable,
		CalculationExpressions,
		FeatureColumnNames,
		NamesOfColumnsUsed,
		ErrorText);
		
	If Not IsBlankString(ErrorText) Then
		Result.HasErrors = True;
		For Each OriginalExpression In CalculationExpressions Do
			Result.ConversionErrorMessages.Insert(OriginalExpression, ErrorText);
		EndDo;
		
		Return Result;
	EndIf;
	
	NamesOfResultColumnsByExpression = New Map;
	ArrayOfExpressions = New Array;
	For Each ExpressionAndColumnName In CalculationExpressions Do
		OriginalExpression = ExpressionAndColumnName.Key;
		NameOfResultColumn = ExpressionAndColumnName.Value;
		If TypeOf(FeatureColumnNames) = Type("Map") Then
			For Each ColumnCharacteristicAndName In FeatureColumnNames Do
				ExpressionOfCharacteristic = ColumnCharacteristicAndName.Key;
				ColumnName = ColumnCharacteristicAndName.Value;
				If StrStartsWith(OriginalExpression, ExpressionOfCharacteristic) Then
					RemainderOfOriginalExpression = Mid(OriginalExpression, StrLen(ExpressionOfCharacteristic) + 1);
					OriginalExpression = ColumnName + ?(RemainderOfOriginalExpression = "", "", ".") + RemainderOfOriginalExpression;
					Break;
				EndIf;
			EndDo;
		EndIf;
		ArrayOfExpressions.Add(OriginalExpression);
		NamesOfResultColumnsByExpression.Insert(OriginalExpression, NameOfResultColumn);
	EndDo;
	
	
	CompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(CompositionSchema,
		Type("DataCompositionSchemaDataSetObject"),
		"DataTable");
	If NamesOfColumnsUsed.Find("RowIndex") = Undefined Then
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = "RowIndex";
		NewField.DataPath = "RowIndex";
		NewField.ValueType = DataTable.Columns["RowIndex"].ValueType;
	EndIf;
	For Each TableColumnName In NamesOfColumnsUsed Do
		DataTableColumn = DataTable.Columns[TableColumnName];
		
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = TableColumnName;
		NewField.DataPath = TableColumnName;
		NewField.ValueType = DataTableColumn.ValueType;
	EndDo;
	
	
	ConversionResult = DataForObtainingFormulaExpressionsViaDCS(CompositionSchema,
		ArrayOfExpressions, PerformExpressionChecks);
	
	If ConversionResult.HasErrors Then
		Result.HasErrors = ConversionResult.HasErrors;
		Result.ConversionErrorMessages = ConversionResult.ConversionErrorMessages;
		
		Return Result;
	EndIf;
	
	For Each OriginalExpressionAndReplacement In ConversionResult.ConvertedExpressions Do
		OriginalExpression = OriginalExpressionAndReplacement.Key;
		ConvertedExpression = OriginalExpressionAndReplacement.Value;
		NameOfResultColumn = NamesOfResultColumnsByExpression.Get(OriginalExpression);
		
		FieldToEval = CompositionSchema.CalculatedFields.Add();
		FieldToEval.DataPath = NameOfResultColumn;
		FieldToEval.Expression = ConvertedExpression;
	EndDo;
	
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	
	Settings = SettingsComposer.GetSettings();
	
	DataCompositionClientServer.AddGrouping(Settings);
	For Each SetField In DataSet.Fields Do
		DataCompositionClientServer.AddSelectedField(Settings, SetField.Field);
	EndDo;
	For Each FieldToEval In CompositionSchema.CalculatedFields Do
		DataCompositionClientServer.AddSelectedField(Settings, FieldToEval.DataPath);
	EndDo;
	OrderItem = Settings.Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Use = True;
	OrderItem.Field = New DataCompositionField("RowIndex");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	
	ExternalSets = New Structure;
	ExternalSets.Insert("DataTable", DataTable);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(CompositionSchema, Settings,,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	ResultsTable = New ValueTable();
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalSets,,True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(ResultsTable);
	ResultsTable = OutputProcessor.Output(CompositionProcessor, True);
	
	Result.ResultsTable = ResultsTable;
	
	Return Result;
	
EndFunction

// Returns a structure of parameters for receiving data via the access control system and, corrects SKD
// (if expressions are used only the sets of data requests, then these expressions are evaluated
// all types of data that have the characteristics indicated in the texts of the relevant sets of the queries
// the override text to obtain the characteristics of the language extension requests (limited number of types
// since the indication of override characteristics for all possible types is not optimal).
// If sets of objects are used to evaluate expressions, the expressions are converted using
// representations of characteristics in the language of the current user.
// 
// Parameters:
// 	CompositionSchema - DataCompositionSchema - The layout scheme used to get the data.
// 	OriginalExpressions - Array of String - An array of original expressions in the format of writing formulas.
// 				For example, " Nomenclature. {ETC.Main supplier of goods}. {KEY. Phone}".
// 	PerformExpressionChecks - Boolean - A flag indicating whether to perform a full scan of the expression.
// 				If the entire expression is not fully checked, this can save time on parsing expressions
// 				(assuming that the expressions are specified correctly), which can be critical for the mechanisms used
// 				in the transaction. If the entire expression is not fully checked, expressions are parsed only to
// 				get the types for which the characteristic is specified, or to get a representation of the characteristic.
// 				If the entire expression is fully checked, the entire expression is checked for correctness
// 				regardless of whether it has any characteristics.
// 	UseFeaturePresentationsOnly - Boolean - This setting allows you to force conversion
// 				of characteristics to a view in the current user's language. It can be useful for
// 				applications where the performance of the data acquisition mechanism is critical (for example, execution in a transaction), because parsing
// 				expressions with the aim of obtaining types of data takes time. If True, the characteristics will be replaced
// 				with views regardless of which data sets are used in the layout scheme.
// Returns:
// 	Structure - LongDesc:
// * ConvertedExpressions - Map - The result of converting expressions.
// 		*Key - String - The original expression.
// 		*Value - String - The result of the conversion to CDS. If
// 			only sets of queries are used for calculating expressions, then, for example, "Nomenclature. [[ETC.Main supplier of goods]]]. [[KI.Telephone]]]".
// 			If sets of objects are also used to evaluate expressions, the expression is converted using
// 			views. For Example, " Nomenclature.[Main supplier of the product (Shoes)].Telephone".
// * HasErrors - Boolean - Flag the presence of errors in the conversion expressions.
// * ConversionErrorMessages - Map - Conversion error messages, if any:
//    **Key - String - The original expression for which the error was registered.
//    **Value - String - text of the error message.
// * LayoutSchemeChanged - Boolean - Flag indicating that the layout scheme has been changed (an
//   			override for getting characteristics in the query extension language has been added to the query datasets.
//
Function DataForObtainingFormulaExpressionsViaDCS(CompositionSchema, OriginalExpressions, PerformExpressionChecks = False,
				UseFeaturePresentationsOnly = False) Export
	
	Result = New Structure;
	Result.Insert("ConvertedExpressions", New Map);
	Result.Insert("HasErrors", False);
	Result.Insert("ConversionErrorMessages", New Map);
	Result.Insert("LayoutSchemeChanged", False);
	
	ExpressionsToCheck_ = New Array;
	
	For Each OriginalExpression In OriginalExpressions Do
		ExpressionContainsCharacteristics = (StrFind(OriginalExpression, "{") > 0);
		If Not ExpressionContainsCharacteristics 
			And Not PerformExpressionChecks Then
			// The expression is executed as is, without further checks.
			Result.ConvertedExpressions.Insert(OriginalExpression, OriginalExpression);
		Else
			ExpressionsToCheck_.Add(OriginalExpression);
		EndIf;
	EndDo;
	
	If ExpressionsToCheck_.Count() > 0 Then
		
		ThereAreSetsOfObjects = False;
		
		DataSetsUsed = UsedLayoutSchemaDataSets(CompositionSchema,
			ExpressionsToCheck_);
		
		FieldNamesWithParents = New Array;
		
		For Each DataSetAndFields In DataSetsUsed Do
			DataSet = DataSetAndFields.Key;
			SetUsageParameters = DataSetAndFields.Value;
			SetFields = SetUsageParameters.SetFields;
			DataSetIsUsedInFeatureExpressions = SetUsageParameters.DataSetIsUsedInFeatureExpressions;
			
			If DataSetIsUsedInFeatureExpressions
				And TypeOf(DataSet) = Type("DataCompositionSchemaDataSetObject") Then
				ThereAreSetsOfObjects = True;
			EndIf;
			For Each FieldDataPath In SetFields Do
				If (StrFind(FieldDataPath, ".") > 0)
					And (FieldNamesWithParents.Find(FieldDataPath) = Undefined) Then
					FieldNamesWithParents.Add(FieldDataPath);
				EndIf;
			EndDo;
		EndDo;
		
		// When checking the parents of the field, the first maximum value that comes up will be used.
		SortingFieldNames = New ValueList();
		SortingFieldNames.LoadValues(FieldNamesWithParents);
		SortingFieldNames.SortByValue(SortDirection.Desc);
		
		FieldNamesWithParents = SortingFieldNames.UnloadValues();
		
		ExpressionValidationParameters = New Structure;
		ExpressionValidationParameters.Insert("CompositionSchema", CompositionSchema);
		ExpressionValidationParameters.Insert("FieldNamesWithParents", FieldNamesWithParents);
		ExpressionValidationParameters.Insert("TypesForOverridingCharacteristics", New Array);
		ExpressionValidationParameters.Insert("ExpressionsToCheck_", ExpressionsToCheck_);
		ExpressionValidationParameters.Insert("PerformExpressionChecks", PerformExpressionChecks);
		
		If ThereAreSetsOfObjects Or UseFeaturePresentationsOnly Then
			
			// To calculate fields with characteristics, sets of objects are used (at least including).
			// 
			// If only one data set, an object, was used, it would be possible to add a service data set
			// for combining queries and set up a link connection between the sets. But since in the general case
			// the number of data sets and the relationships between them are not known, the method of substituting
			// representations as characteristics is used.
			// 
			// Since metadata (the characteristics button on the data tab) does not imply specifying fields for identifiers,
			// the default data layout scheme mechanism uses
			// the characteristics representation as a characteristic identifier. Moreover, it is the representation in the language of the Cur user
			// (which can be overridden programmatically), and not fields, for example, the Name.
			// ==> If instead of identifiers in the format {prefixcharacteristics.Characteristics identifier}
			// substitute a representation in the language of the Cur user, then the layout scheme engine will receive the data.
			// 		If the representation is simple, does not contain special characters and can be specified as Attributes, then
			// 		the representation must be specified as Attributes. For example, an Order.Freight forwarder, where the Freight Forwarder is a representation.
			// 		If the representation is complex, then it is indicated in square brackets, for example, the Order.[Main freight forwarder].
			// There is a complexity in substituting a representation. The characteristic representation must be unique for
			// all characteristics (supported and unsupported) that are suitable for a single metadata object.
			// Suitable characteristics for a metadata object are determined based on the selection of characteristics specified
			// in the metadata. For example, if there is a field of a composite type (Contractors and Organizations Catalogs), then
			// you can specify a representation of the "Phone" characteristic for them (different types of contact information, but within the
			// same metadata object, the "Phone" representation will be unique. However, you cannot specify additional
			// Attributes with the "Phone" view if contact information is specified for the metadata object and
			// there is a suitable type of contact information with the same view.
			
			ExpressionValidationParameters.Insert("ConvertingCharacteristicsToPresentation", True);
			
			PerformingExpressionValidationAndConversion(ExpressionValidationParameters, Result);
			
		Else
			
			// Query datasets are used to calculate fields with characteristics.
			// This means that in the texts of query datasets, using the query extension language, you can redefine
			// feature identifiers.
			// ==> Expressions are parsed, the types of values for which redefinition is required
			// in the query extension language are determined, the text of the redefinition is compiled using the characterization method for
			// describing types and this text is inserted into the query text (the text in the query extension language is not the text of the
			// query itself, so the length of the text can not be controlled).
			// The expressions themselves at the moment also need to be converted by replacing curly brackets with square
			// brackets in the format {Prefix types of characteristics.Characteristic identifier} --> [[Characteristic Type prefix.Character ID]]]
			// (the third closing parenthesis is a service for the parsing mechanism of the layout scheme expression).
			
			ExpressionValidationParameters.Insert("ConvertingCharacteristicsToPresentation", False);
			
			PerformingExpressionValidationAndConversion(ExpressionValidationParameters, Result);
				
			If ExpressionValidationParameters.TypesForOverridingCharacteristics.Count() > 0 Then
				
				TypeDescription = New TypeDescription(ExpressionValidationParameters.TypesForOverridingCharacteristics);
				CharacteristicsText = DescriptionOfDCSCharacteristicsForDescribingTypes(TypeDescription);
				
				For Each DataSetAndFields In DataSetsUsed Do
					SetUsageParameters = DataSetAndFields.Value;
					DataSetIsUsedInFeatureExpressions = SetUsageParameters.DataSetIsUsedInFeatureExpressions;
					If DataSetIsUsedInFeatureExpressions Then
						QueryDataSet = DataSetAndFields.Key;
						QueryDataSet.Query = QueryDataSet.Query + Chars.LF + Chars.LF + CharacteristicsText;
					EndIf;
				EndDo;
				
				Result.LayoutSchemeChanged = True;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region GettingDataForFormulas

Function PresentationOfCharacteristicInDCSExpression(CharacteristicPresentation)
	PresentationOfCharacteristicsOfVZKD = CharacteristicPresentation;
	
	SpecialChars = ProcessingOfFormulasClientServer.SpecialChars();
	
	ContainsSpecialCharacters = False;
	For CharNum = 1 To StrLen(SpecialChars) Do
		Char = Mid(SpecialChars, CharNum, 1);
		If StrFind(CharacteristicPresentation, Char) > 0 Then
			ContainsSpecialCharacters = True;
			Break;
		EndIf;
	EndDo;
	If ContainsSpecialCharacters Then
		PresentationOfCharacteristicsOfVZKD = "[" + CharacteristicPresentation + "]";
	EndIf;
	
	Return PresentationOfCharacteristicsOfVZKD;
EndFunction

// Performs an initial check of the passed data table and fills in the list of used columns.
// 
// Parameters:
// 	DataTable - ValueTable - 
// 	CalculationExpressions - Map - 
// 	FeatureColumnNames - Undefined, Map -
// 	Imenumanager - an Array of String - 
// 	ErrorsText - String - 
//
Procedure InitialChecksForDataAcquisition(DataTable, CalculationExpressions, FeatureColumnNames,
			NamesOfColumnsUsed, ErrorsText = "")
	
	For Each ResultColumnExpressionAndName In CalculationExpressions Do
		
		Expression = ResultColumnExpressionAndName.Key;
		OperandParts = ProcessingOfFormulasClientServer.OperandParts(Expression);
		FirstPartOfOperand = OperandParts[0];
		ThisIsCharacteristic  = (StrFind(FirstPartOfOperand, "{") > 0);
		
		// Initial checks. Presence of a column in the table
		TableColumnName = Undefined;
		If ThisIsCharacteristic And Not FeatureColumnNames = Undefined Then
			TableColumnName = FeatureColumnNames.Get(FirstPartOfOperand);
		ElsIf Not ThisIsCharacteristic Or FeatureColumnNames = Undefined Then
			TableColumnName = FirstPartOfOperand;
		EndIf;
		If Not ValueIsFilled(TableColumnName) Then
			ErrorsText = NStr("vi = 'Cần chỉ định tên cột của bảng đối với đặc tính ""%1"".';
								|ru = 'Необходимо указать имя колонки таблицы для характеристики ""%1"".';
								|en = 'Please specify the table column name for variant ""%1"".'; fa = 'Please specify the table column name for variant ""%1"".';
								|it = 'È necessario indicare il nome della colonna della tabella per la caratteristica ""%1"".';
								|pl = 'Należy podać nazwę kolumny tabeli dla charakterystyki ""%1"".';
								|tr = '""%1"" varyantı için tablo sütun adını belirtmeniz gerekmektedir.'");
			ErrorsText = StringFunctionsClientServer.SubstituteParametersToString(ErrorsText, FirstPartOfOperand);
			Return;
		EndIf;
		TableColumn2 = DataTable.Columns.Find(TableColumnName);
		If TableColumn2 = Undefined Then
			ErrorsText = NStr("vi = 'Trong bảng nguồn không có cột với tên gọi ""%1"".';
								|ru = 'В таблице источников отсутствует колонка с именем ""%1"".';
								|en = 'The source table does not contain column with name ""%1"".'; fa = 'The source table does not contain column with name ""%1"".';
								|it = 'Nella tabella delle fonti non c''è la colonna con il nome ""%1"".';
								|pl = 'W tabeli źródeł nie ma kolumny o nazwie ""%1"".';
								|tr = 'Kaynak tablosunda ""%1"" adında sütun bulunmamaktadır.'");
			ErrorsText = StringFunctionsClientServer.SubstituteParametersToString(ErrorsText, TableColumnName);
			Return;
		EndIf;
		
		TypeDescription = TableColumn2.ValueType;
		If TypeDescription.Types().Count() = 0 Then
			ErrorsText = NStr("vi = 'Cột của bảng ""%1"" không điển hình, không thể nhận dữ liệu.';
								|ru = 'Колонка таблицы ""%1"" не типизирована, получение данных не возможно.';
								|en = 'The ""%1"" column in the table is not typed, cannot get Data.'; fa = 'The ""%1"" column in the table is not typed, cannot get Data.';
								|it = 'La colonna della tabella ""%1"" non è tipizzata, impossibile ricevere dati.';
								|pl = 'Kolumna tabeli ""%1"" nie jest stypizowana, pobieranie danych jest niemożliwe.';
								|tr = '""%1"" tablo sütunu tipleştirilmedi, veri alımı mümkün değildir.'");
			ErrorsText = StringFunctionsClientServer.SubstituteParametersToString(ErrorsText, TableColumnName);
			Return;
		EndIf;
		
		If NamesOfColumnsUsed.Find(TableColumnName) = Undefined Then
			NamesOfColumnsUsed.Add(TableColumnName);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PerformingExpressionValidationAndConversion(ExpressionValidationParameters, ResultStructure1)
	
	CompositionSchema = ExpressionValidationParameters.CompositionSchema;
	FieldNamesWithParents = ExpressionValidationParameters.FieldNamesWithParents;
	ConvertingCharacteristicsToPresentation = ExpressionValidationParameters.ConvertingCharacteristicsToPresentation;
	TypesForOverridingCharacteristics = ExpressionValidationParameters.TypesForOverridingCharacteristics;
	ExpressionsToCheck_ = ExpressionValidationParameters.ExpressionsToCheck_;
	PerformExpressionChecks = ExpressionValidationParameters.PerformExpressionChecks;
	ConversionErrorMessages = ResultStructure1.ConversionErrorMessages; // Map -
	PropertiesOfCharacteristicSources = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	
	ComposerSourceSchema = New DataCompositionSettingsComposer;
	ComposerSourceSchema.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	ExpressionTypeCache = New Map;
	CacheOfFeatureSources = New Map;
	FeaturePresentationCache = New Map;
	
	ParametersForSpecifyingCharacteristics = GetParametersForSpecifyingCharacteristicsInExpressions(ExpressionsToCheck_,
		ExpressionValidationParameters,
		ResultStructure1,
		PropertiesOfCharacteristicSources);
	ParametersOfUniqueCharacteristics = ParametersForSpecifyingCharacteristics.ParametersOfUniqueCharacteristics;
	ExpressionsWithErrors = ParametersForSpecifyingCharacteristics.ExpressionsWithErrors;
	ExpressionsWithNonUniqueCharacteristics = ParametersForSpecifyingCharacteristics.ExpressionsWithNonUniqueCharacteristics;
	MatchesNamesOfStandardProps = ProcessingOfFormulasCached.MatchesNamesOfStandardProps();
	
	For Each OriginalExpression In ExpressionsToCheck_ Do
		
		ResultStructure1.ConvertedExpressions.Insert(OriginalExpression, "");
		
		If Not ExpressionsWithErrors.Get(OriginalExpression) = Undefined Then
			Continue;
		EndIf;
		
		ParseExpression_ = PerformExpressionChecks
			Or Not ConvertingCharacteristicsToPresentation
			Or ExpressionsWithNonUniqueCharacteristics.Find(OriginalExpression) <> Undefined;
		
		ThereAreExpressionConversionErrors = False;
		ReplacementExpression = Undefined;
		
		If Not ParseExpression_ Then
			
			ReplacementExpression = OriginalExpression;
			For Each FeatureIDAndParameters In ParametersOfUniqueCharacteristics Do
				ItemVariantID = FeatureIDAndParameters.Key;
				CharacteristicParameters = FeatureIDAndParameters.Value;
				CharacteristicPresentation = PresentationOfCharacteristicInDCSExpression(
					CharacteristicParameters.Presentation);
				ReplacementExpression = StrReplace(ReplacementExpression, ItemVariantID, CharacteristicPresentation);
			EndDo;
			
		Else
		
			If PerformExpressionChecks Then
				// Parsing the whole expression.
				CheckedPartOfExpression = OriginalExpression;
			Else
				// Parsing an expression in order to substitute a representation of a characteristic. We get
				// to the last characteristic, including it.
				PositionNumber = StrFind(OriginalExpression, "}", SearchDirection.FromEnd);
			
				If PositionNumber = 0 Then
					// The expression is not parsed, because it does not contain characteristics and does not need to check the entire expression.
					CheckedPartOfExpression = "";
				Else
					// Parsing an expression to the last characteristic, in order to determine
					// the data types that the characteristic can correspond to or set the desired representation.
					CheckedPartOfExpression = Mid(OriginalExpression, 1, PositionNumber);
				EndIf;
			EndIf;
			
			If IsBlankString(CheckedPartOfExpression) Then
				
				// Full expression validation is not required and there are no characteristics.
				ReplacementExpression = OriginalExpression;
				
			Else
				
				ReplacementExpression = "";
				
				// Checking for the use of a complex data path (via a group or another element).
				ParentSpecificField = "";
				For Each FieldNameWithParents In FieldNamesWithParents Do
					If StrStartsWith(OriginalExpression, FieldNameWithParents) Then
						NextChar = Mid(OriginalExpression, StrLen(FieldNameWithParents) + 1, 1);
						If NextChar = "." Or NextChar = "" Then
							ParentSpecificField = FieldNameWithParents;
							Break;
						EndIf;
					EndIf;
				EndDo;
				
				If IsBlankString(ParentSpecificField) Then
					RemainderOfExpression = OriginalExpression;
				Else
					RemainderOfExpression = Mid(OriginalExpression, StrLen(ParentSpecificField + ".") + 1);
				EndIf;
				
				PartsOfExpression = ProcessingOfFormulasClientServer.OperandParts(RemainderOfExpression,, False);
				If IsBlankString(ParentSpecificField) Then
					AccumulatedPath = PartsOfExpression[0];
					PartsOfExpression.Delete(0);
				Else
					AccumulatedPath = ParentSpecificField;
				EndIf;
				
				
				// There cannot be a characteristic at the beginning of an expression, because a characteristic always belongs
				// to some object (a field in a query or a column in a table). Therefore, we are looking for a field according to the original layout scheme
				// , taking into account that a complex data path can be set for the field.
				FieldType = ExpressionTypeCache.Get(AccumulatedPath);
				If FieldType = Undefined Then
					DCSField = DataCompositionServer.FindDCSFieldByFullName(
						ComposerSourceSchema.Settings.Selection.SelectionAvailableFields.Items,
						AccumulatedPath);
					If DCSField = Undefined Then
						ThereAreExpressionConversionErrors = True;
						
						MessageText = NStr("vi = 'Không tìm thấy trường %1 trong biểu thức %2. Hãy kiểm tra tính chính xác của biểu thức.';
											|ru = 'Не найдено поле %1 в выражении %2. Проверьте корректность выражения.';
											|en = 'Cannot find %1 field in expression %2. Check, if the expression is correct.'; fa = 'Cannot find %1 field in expression %2. Check, if the expression is correct.';
											|it = 'Il campo %1 nell''espressione %2non è stato trovato. Verificate la correttezza dell''espressione.';
											|pl = 'Nie znaleziono pola %1 w wyrażeniu %2. Sprawdź poprawność wyrażenia.';
											|tr = '%2 ifadesinde %1 alanı bulunamadı. İfadenin doğruluğunu kontrol edin.'");
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
							AccumulatedPath, OriginalExpression);
						ConversionErrorMessages.Insert(OriginalExpression, MessageText);
					Else
						FieldType = DCSField.Type;
						ExpressionTypeCache.Insert(AccumulatedPath, FieldType);
					EndIf;
				EndIf;
				If ThereAreExpressionConversionErrors Then
					Continue;
				Else
					ReplacementExpression = AccumulatedPath;
				EndIf;
				
				While Not ThereAreExpressionConversionErrors
					And PartsOfExpression.Count() > 0
					And CheckedPartOfExpression <> AccumulatedPath Do
					
					PartOfExpression = PartsOfExpression[0];
					PartsOfExpression.Delete(0);
					
					ThisIsCharacteristic = (StrFind(PartOfExpression, "{") > 0);
					If ThisIsCharacteristic And Not ConvertingCharacteristicsToPresentation Then
						AddTypesToRedefineCharacteristics(TypesForOverridingCharacteristics,
							FieldType);
					EndIf;
					
					CurrentExpression = AccumulatedPath + "." + PartOfExpression;
					
					If ThisIsCharacteristic Then
						UniqueCharacteristicParameters = ParametersOfUniqueCharacteristics.Get(PartOfExpression);
						If Not UniqueCharacteristicParameters = Undefined Then
							TypeOfCurExpression = UniqueCharacteristicParameters.ValueType;
							Presentation = UniqueCharacteristicParameters.Presentation;
							If Not ConvertingCharacteristicsToPresentation Then
								ReplacementExpression = ReplacementExpression + "." + ModifiedOperandExpressionForDCS(PartOfExpression);
							Else
								ReplacementExpression = ReplacementExpression + "." + PresentationOfCharacteristicInDCSExpression(Presentation);
							EndIf;
						Else
							// Not a unique representation of the characteristic and the transformation of the characteristic to the representation = True.
							
							ExtensionParameters_ = New Structure;
							ExtensionParameters_.Insert("ExpressionTypeCache", ExpressionTypeCache);
							ExtensionParameters_.Insert("FeaturePresentationCache", FeaturePresentationCache);
							ExtensionParameters_.Insert("CacheOfFeatureSources", CacheOfFeatureSources);
							ExtensionParameters_.Insert("PropertiesOfCharacteristicSources", PropertiesOfCharacteristicSources);
							ExtensionParameters_.Insert("AccumulatedPath", AccumulatedPath);
							ExtensionParameters_.Insert("ExpressionOfCharacteristic", PartOfExpression);
							ExtensionParameters_.Insert("OriginalExpression", OriginalExpression);
								
							ComplementReplacementExpressionWithPresentationOfCharacteristic(ReplacementExpression,
								ExtensionParameters_,
								ThereAreExpressionConversionErrors,
								ConversionErrorMessages);
								
							TypeOfCurExpression = ExpressionTypeCache.Get(CurrentExpression);
						EndIf;
							
					Else
						TypeOfCurExpression = ExpressionTypeCache.Get(CurrentExpression);
						If TypeOfCurExpression = Undefined Then
							ArrayOfTypesFound = New Array;
							Types = FieldType.Types();
							For Each Type In Types Do
								MetadataObjectsList = Metadata.FindByType(Type);
								If MetadataObjectsList = Undefined Then
									Continue;
								EndIf;
								If Common.IsEnum(MetadataObjectsList) Then
									Continue;
								EndIf;
								PropsFound = False;
								Attribute = MetadataObjectsList.Attributes.Find(PartOfExpression);
								If Not Attribute = Undefined Then
									PropsFound = True;
									AttributeTypes = Attribute.Type.Types();
									For Each AttributeType In AttributeTypes Do
										If ArrayOfTypesFound.Find(AttributeType) = Undefined Then
											ArrayOfTypesFound.Add(AttributeType);
										EndIf;
									EndDo;
								EndIf;
								If Not PropsFound Then
									For Each Attribute In MetadataObjectsList.StandardAttributes Do
										If Attribute.Name = PartOfExpression
											Or MatchesNamesOfStandardProps.Get(Attribute.Name) = PartOfExpression Then
											PropsFound = True;
											AttributeTypes = Attribute.Type.Types();
											For Each AttributeType In AttributeTypes Do
												If ArrayOfTypesFound.Find(AttributeType) = Undefined Then
													ArrayOfTypesFound.Add(AttributeType);
												EndIf;
											EndDo;
											Break;
										EndIf;
									EndDo;
								EndIf;
							EndDo;
							If ArrayOfTypesFound.Count() = 0 Then
								ThereAreExpressionConversionErrors = True;
								
								MessageText = NStr("vi = 'Không tìm thấy trường %1 trong biểu thức %2. Hãy kiểm tra tính chính xác của biểu thức.';
													|ru = 'Не найдено поле %1 в выражении %2. Проверьте корректность выражения.';
													|en = 'Cannot find %1 field in expression %2. Check, if the expression is correct.'; fa = 'Cannot find %1 field in expression %2. Check, if the expression is correct.';
													|it = 'Il campo %1 nell''espressione %2non è stato trovato. Verificate la correttezza dell''espressione.';
													|pl = 'Nie znaleziono pola %1 w wyrażeniu %2. Sprawdź poprawność wyrażenia.';
													|tr = '%2 ifadesinde %1 alanı bulunamadı. İfadenin doğruluğunu kontrol edin.'");
								MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
									AccumulatedPath, OriginalExpression);
								ConversionErrorMessages.Insert(OriginalExpression, MessageText);
							Else
								TypeOfCurExpression = New TypeDescription(ArrayOfTypesFound);
							EndIf;
							
						EndIf;
						
						ReplacementExpression = ReplacementExpression + "." + PartOfExpression;
						
						If Not ThereAreExpressionConversionErrors Then
							ExpressionTypeCache.Insert(CurrentExpression, TypeOfCurExpression);
						EndIf;
						
					EndIf;
					If Not ThereAreExpressionConversionErrors Then
						ExpressionTypeCache.Insert(CurrentExpression, TypeOfCurExpression);
					EndIf;
					
					FieldType = TypeOfCurExpression;
					AccumulatedPath = CurrentExpression;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
		If Not ThereAreExpressionConversionErrors Then
			ResultStructure1.ConvertedExpressions.Insert(OriginalExpression, ReplacementExpression);
		EndIf;
		
		If ThereAreExpressionConversionErrors Then
			ResultStructure1.HasErrors = True;
		EndIf;
	EndDo;
	
EndProcedure

Function GetParametersForSpecifyingCharacteristicsInExpressions(ExpressionsToCheck_, ExpressionValidationParameters,
				ResultStructure1, PropertiesOfCharacteristicSources)
	
	ParametersForSpecifyingCharacteristics = New Structure;
	
	ConversionErrorMessages = ResultStructure1.ConversionErrorMessages;
	ConvertingCharacteristicsToPresentation = ExpressionValidationParameters.ConvertingCharacteristicsToPresentation;
	
	ControlOfPresentations = ConvertingCharacteristicsToPresentation;
	
	// Characteristics that have the uniqueness property of having the limits of their table characteristics = True. For example, additional Attributes.
	ParametersOfUniqueCharacteristics = New Map;
	ExpressionsWithNonUniqueCharacteristics = New Array;
	ExpressionsWithErrors = New Map;
	
	IdentifiersOfCharacteristicsByType = New Map;
	For Each OriginalExpression In ExpressionsToCheck_ Do
		If StrFind(OriginalExpression, "{") = 0 Then
			Continue;
		EndIf;
		ExpressionContainsParsingErrors = False;
		ExpressionLength = StrLen(OriginalExpression);
		
		For Each SourceDetails In PropertiesOfCharacteristicSources Do
			SourceMetadata = SourceDetails.SourceMetadata;
			
			StartTag_ = "{" + SourceDetails.PropertyTypePrefix;
			StartTagLength = StrLen(StartTag_);
			EndTag_ = "}";
			
			ChecksCompleted_ = False;
			PositionNumber = 0;
			While Not ChecksCompleted_ And Not ExpressionContainsParsingErrors Do
				PositionNumber = StrFind(OriginalExpression, StartTag_,, PositionNumber + 1);
				If PositionNumber = 0 Then
					ChecksCompleted_ = True;
					Break;
				Else
					EndPositionNumber = StrFind(OriginalExpression, EndTag_,, PositionNumber + StartTagLength);
					If EndPositionNumber = 0 Then
						ResultStructure1.HasErrors = True;
						ExpressionsWithErrors.Insert(OriginalExpression, True);
						
						MessageText = NStr("vi = 'Lỗi cú pháp của biểu thức ""%1"". Không tìm thấy thẻ kết thúc đặc tính.';
											|ru = 'Ошибка парсинга выражения ""%1"". Не найден тег окончания характеристики.';
											|en = 'Error when parsing the ""%1"" expression. Cannot find variant end tag.'; fa = 'Error when parsing the ""%1"" expression. Cannot find variant end tag.';
											|it = 'Errore di parsing dell''espressione ""%1"". Tag di fine caratteristica non trovato.';
											|pl = 'Błąd parsingu wyrażenia ""%1"". Nie znaleziono tagu zakończenia charakterystyki.';
											|tr = '""%1"" ifadesi ayrıştırılırken hata oluştu. Varyant bitiş etiketi bulunamadı.'");
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
							OriginalExpression);
						ConversionErrorMessages.Insert(OriginalExpression, MessageText);
						Break;
					EndIf;
					FullID = Mid(OriginalExpression, PositionNumber, EndPositionNumber - PositionNumber + 1);
					IDLength = EndPositionNumber - (PositionNumber + StartTagLength);
					ItemVariantID = Mid(OriginalExpression, PositionNumber + StartTagLength, IDLength);
					
					
					IDsTable = IdentifiersOfCharacteristicsByType.Get(SourceMetadata);
					If IDsTable = Undefined Then
						DescriptionOfIDType = New TypeDescription("String",, New StringQualifiers(1000, AllowedLength.Variable));
						IDsTable = New ValueTable;
						IDsTable.Columns.Add("FieldID", DescriptionOfIDType);
						IDsTable.Columns.Add("NameFieldValue", DescriptionOfIDType);
					EndIf;
					Id_String = IDsTable.Add();
					Id_String.FieldID = FullID;
					Id_String.NameFieldValue = ItemVariantID;
					
					IdentifiersOfCharacteristicsByType.Insert(SourceMetadata, IDsTable);
					
					PositionNumber = EndPositionNumber + 1;
					If PositionNumber > ExpressionLength Then
						ChecksCompleted_ = True;
					EndIf;
				EndIf;
			EndDo;
			If ExpressionContainsParsingErrors Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	CharacteristicsWithErrors = New Map;
	NotUniqueCharacteristics = New Array;
	For Each TypeOfCharacteristicsAndIdentifiers In IdentifiersOfCharacteristicsByType Do
		SourceMetadata = TypeOfCharacteristicsAndIdentifiers.Key;
		IDsTable = TypeOfCharacteristicsAndIdentifiers.Value;
		IDsTable.GroupBy("FieldID, NameFieldValue");
		
		CharacteristicsSourceProperties = PropertiesOfCharacteristicSources.Find(SourceMetadata, "SourceMetadata");
		DBTable = ProcessingOfFormulasCached.FullNameOfDataTable(
			CharacteristicsSourceProperties.SourceMetadata.FullName());
		
		Query = New Query;
		Text =
		"SELECT
		|	FeatureIds.FieldID AS FieldID,
		|	FeatureIds.NameFieldValue AS NameFieldValue
		|INTO FeatureIds
		|FROM
		|	&FeatureIds AS FeatureIds
		|;
		|
		|SELECT
		|	FeatureIds.FieldID AS FieldID,
		|	FeatureIds.NameFieldValue AS NameFieldValue,
		|	TableOfTypesOfCharacteristics.Ref AS Ref,
		|	&PresentationExpressionOfCharacteristic AS CharacteristicPresentation,
		|	&ValueTypeExpression_ AS ValueType
		|FROM
		|	FeatureIds AS FeatureIds
		|LEFT JOIN
		|	#NameOfCharacteristicsSourceTable AS TableOfTypesOfCharacteristics
		|ON
		|	&TableJoinExpression
		|
		|TOTALS
		|	MAX(NameFieldValue) AS NameFieldValue
		|BY
		|	FieldID";
		
		TableJoinExpression = StringFunctionsClientServer.SubstituteParametersToString(
			"FeatureIds.NameFieldValue = TableOfTypesOfCharacteristics.%1",
			CharacteristicsSourceProperties.IdField_);
		If CharacteristicsSourceProperties.ValueTypeExpressionIsUsed Then
			ValueTypeExpression_ = CharacteristicsSourceProperties.ExpressionTypeOfValue;
		Else
			ValueTypeExpression_ = StringFunctionsClientServer.SubstituteParametersToString(
				"TableOfTypesOfCharacteristics.%1",
				CharacteristicsSourceProperties.FieldTypeOfValues);
		EndIf;
		If ConvertingCharacteristicsToPresentation Then
			PresentationExpressionOfCharacteristic = "CASE
			|		WHEN NOT TableOfTypesOfCharacteristics.Ref IS NULL
			|			THEN PRESENTATION(TableOfTypesOfCharacteristics.Ref)
			|		ELSE """"
			|	END";
		Else
			PresentationExpressionOfCharacteristic = """""";
		EndIf;
			
		Text = StrReplace(Text, "#NameOfCharacteristicsSourceTable", DBTable);
		Text = StrReplace(Text, "&TableJoinExpression", TableJoinExpression);
		Text = StrReplace(Text, "&ValueTypeExpression_", ValueTypeExpression_);
		Text = StrReplace(Text, "&PresentationExpressionOfCharacteristic", PresentationExpressionOfCharacteristic);
		
		Query.Text = Text;
		Query.SetParameter("FeatureIds", IDsTable);
		
		SelectionID = Query.Execute().Select(QueryResultIteration.ByGroups, "FieldID");
		While SelectionID.Next() Do
			FieldID = SelectionID.FieldID;
			NameFieldValue = SelectionID.NameFieldValue;
			
			SamplingDetailed = SelectionID.Select();
			If CharacteristicsSourceProperties.UniquenessOfNameWithinEntireCharacteristicsTable
				And SamplingDetailed.Count() > 1 Then
				MessageText = NStr("vi = 'Không đảm bảo tính đơn trị của đặc tính theo tên định danh ""%1""';
									|ru = 'Не обеспечена уникальность характеристики по идентификатору ""%1""';
									|en = 'Variant with ID ""%1"" must be unique'; fa = 'Variant with ID ""%1"" must be unique';
									|it = 'Non è stata garantita l''unicità della caratteristica per identificativo ""%1""';
									|pl = 'Nie zapewniono unikalności charakterystyki wg identyfikatora ""%1""';
									|tr = '""%1"" kimliğine göre varyant benzersizliği sağlanmadı'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
					NameFieldValue);
				
				CharacteristicsWithErrors.Insert(FieldID, MessageText);
				Continue;
			EndIf;
			CharacteristicDataType = Undefined;
			CharacteristicPresentation = Undefined;
			
			CharacteristicIsNotUnique = False;
			ThereAreErrorsInCharacteristics = False;
			While SamplingDetailed.Next() Do
				If Not ValueIsFilled(SamplingDetailed.Ref) Then
					MessageText = NStr("vi = 'Không tìm thấy đặc tính theo tên định danh ""%1""';
										|ru = 'Не найдена характеристика по идентификатору ""%1""';
										|en = 'Cannot find variant with ID ""%1""'; fa = 'Cannot find variant with ID ""%1""';
										|it = 'Non è stata trovata la caratteristica con identificativo ""%1""';
										|pl = 'Nie znaleziono charakterystyki wg identyfikatora ""%1""';
										|tr = '""%1"" kimliğine göre varyant bulunamadı'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
						NameFieldValue);
					
					CharacteristicsWithErrors.Insert(FieldID, MessageText);
					ThereAreErrorsInCharacteristics = True;
					Break;
				EndIf;
				DataType = SamplingDetailed.ValueType;
				If ValueIsFilled(CharacteristicsSourceProperties.OverridingValueTypeExpression) Then
					DataType = CharacteristicsSourceProperties.OverridingValueTypeExpression;
				EndIf;
				If ControlOfPresentations
					And Not CharacteristicPresentation = Undefined
					And CharacteristicPresentation <> SamplingDetailed.CharacteristicPresentation Then
					CharacteristicIsNotUnique = True;
					Break;
				EndIf;
				CharacteristicPresentation = SamplingDetailed.CharacteristicPresentation;
				CharacteristicDataType = DataType;
			EndDo;
			
			If Not ThereAreErrorsInCharacteristics Then
				If CharacteristicIsNotUnique Then
					NotUniqueCharacteristics.Add(FieldID);
				Else
					CharacteristicParameters = New Structure;
					CharacteristicParameters.Insert("Presentation", CharacteristicPresentation);
					CharacteristicParameters.Insert("ValueType", CharacteristicDataType);
					ParametersOfUniqueCharacteristics.Insert(FieldID, CharacteristicParameters);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	For Each OriginalExpression In ExpressionsToCheck_ Do
		ThereAreErrorsInExpression = False;
		For Each ErrorCharacteristicsAndText In CharacteristicsWithErrors Do
			ItemVariantID = ErrorCharacteristicsAndText.Key;
			ErrorText = ErrorCharacteristicsAndText.Value;
			PositionNumber = StrFind(OriginalExpression, ItemVariantID);
			If PositionNumber > 0 Then
				ExpressionsWithErrors.Insert(OriginalExpression, True);
				ConversionErrorMessages.Insert(OriginalExpression, ErrorText);
				ResultStructure1.HasErrors = True;
				ThereAreErrorsInExpression = True;
				Break;
			EndIf;
		EndDo;
		If ThereAreErrorsInExpression Then
			Continue;
		EndIf;
		ThereAreNonUniqueCharacteristics = False;
		For Each ItemVariantID In NotUniqueCharacteristics Do
			PositionNumber = StrFind(OriginalExpression, ItemVariantID);
			If PositionNumber > 0 Then
				ThereAreNonUniqueCharacteristics = True;
				Break;
			EndIf;
		EndDo;
		If ThereAreNonUniqueCharacteristics Then
			ExpressionsWithNonUniqueCharacteristics.Add(OriginalExpression);
		EndIf;
	EndDo;
	
	ParametersForSpecifyingCharacteristics.Insert("ParametersOfUniqueCharacteristics", ParametersOfUniqueCharacteristics);
	ParametersForSpecifyingCharacteristics.Insert("ExpressionsWithNonUniqueCharacteristics", ExpressionsWithNonUniqueCharacteristics);
	ParametersForSpecifyingCharacteristics.Insert("ExpressionsWithErrors", ExpressionsWithErrors);
	
	Return ParametersForSpecifyingCharacteristics;
	
EndFunction

Procedure AddTypesToRedefineCharacteristics(TypesForOverridingCharacteristics, TypeDescription)
	
	Types = TypeDescription.Types();
	For Each Type In Types Do
		If Common.IsReference(Type) Then
			If TypesForOverridingCharacteristics.Find(Type) = Undefined Then
				TypesForOverridingCharacteristics.Add(Type);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure ComplementReplacementExpressionWithPresentationOfCharacteristic(ReplacementExpression, ExtensionParameters_,
				ThereAreExpressionConversionErrors, ConversionErrorMessages)
	
	ExpressionTypeCache = ExtensionParameters_.ExpressionTypeCache;
	FeaturePresentationCache = ExtensionParameters_.FeaturePresentationCache;
	CacheOfFeatureSources = ExtensionParameters_.CacheOfFeatureSources;
	PropertiesOfCharacteristicSources = ExtensionParameters_.PropertiesOfCharacteristicSources;
	AccumulatedPath = ExtensionParameters_.AccumulatedPath;
	ExpressionOfCharacteristic = ExtensionParameters_.ExpressionOfCharacteristic;
	OriginalExpression = ExtensionParameters_.OriginalExpression;
	
	ExpressionWithCharacteristic = AccumulatedPath + "." + ExpressionOfCharacteristic;
	Expressions = FeaturePresentationCache.Get(ExpressionWithCharacteristic);
	
	If Expressions = Undefined Then
		PropertyOwnerFieldType = ExpressionTypeCache.Get(AccumulatedPath);
		Expressions = GetPresentationCharacteristicsForObjectsOfType(PropertyOwnerFieldType,
			ExpressionOfCharacteristic, PropertiesOfCharacteristicSources, CacheOfFeatureSources);
		FeaturePresentationCache.Insert(ExpressionWithCharacteristic, Expressions);
	EndIf;
	If Expressions.Count() = 0 Then
		ThereAreExpressionConversionErrors = True;
		MessageText = NStr("vi = 'Không tìm thấy đặc tính có tên định danh %1 trong biểu thức %2';
							|ru = 'Не найдено характеристики с идентификатором %1 в выражении %2';
							|en = 'Cannot find variant with ID %1 in expression %2'; fa = 'Cannot find variant with ID %1 in expression %2';
							|it = 'Non è stata trovata la caratteristica con l''identificativo %1 nell''espressione %2';
							|pl = 'Nie znaleziono charakterystyki z identyfikatorem %1 w wyrażeniu %2';
							|tr = '%2 ifadesinde %1 kimliği olan varyant bulunamadı'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
			ExpressionOfCharacteristic, ExpressionWithCharacteristic);
		ConversionErrorMessages.Insert(OriginalExpression, MessageText);
	ElsIf Expressions.Count() = 1 Then
		For Each TypeDescriptionAndPresentation In Expressions Do
			Presentation = TypeDescriptionAndPresentation.Value;
			ReplacementExpression = ReplacementExpression + "." + PresentationOfCharacteristicInDCSExpression(Presentation);
		EndDo;
	
	Else
		// Contact information assumes the possibility of multiple representations.
		// Since the type of the value of contact information is a string (representation),
		// there can be no expressions after it.
		NewReplacementExpression = "";
		For Each TypeDescriptionAndPresentation In Expressions Do
			Presentation = TypeDescriptionAndPresentation.Value;
			TypeDescription = TypeDescriptionAndPresentation.Key;
			VSKDPresentation = PresentationOfCharacteristicInDCSExpression(Presentation);
			Types = TypeDescription.Types();
			TypeReplacementExpression = "";
			For Each Type In Types Do
				MetadataObjectsList = MetadataObjectByValueType(Type);
				MdObjectType = MetadataObjectKind(MetadataObjectsList);
				If TypeReplacementExpression = "" Then
					TypeReplacementExpression = "WHEN" + " ";
				Else
					TypeReplacementExpression = TypeReplacementExpression + Chars.LF + " " + "OR" + " ";
				EndIf;
				TypeReplacementExpression = TypeReplacementExpression + StringFunctionsClientServer.SubstituteParametersToString(
					"VALUETYPE(%1) = TYPE(""%2"")",
					ReplacementExpression,
					MdObjectType + "." + MetadataObjectsList.Name);
			EndDo;
			TypeReplacementExpression = TypeReplacementExpression + " " + Chars.LF + Chars.Tab
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"THEN %1",
					ReplacementExpression + "." + VSKDPresentation);
			NewReplacementExpression = NewReplacementExpression + ?(NewReplacementExpression = "", "", Chars.LF + " ")
				+ TypeReplacementExpression;
		EndDo;
		NewReplacementExpression = StringFunctionsClientServer.SubstituteParametersToString(
			"CASE
			|	%1
			|END",
			NewReplacementExpression);
		ReplacementExpression = NewReplacementExpression;
	EndIf;
	
EndProcedure

Function RequestingPropertiesCharacteristicsForMetadataObjects(TypeDescription, PropertiesOfCharacteristicSources, CacheOfFeatureSources,
			ExpressionOfCharacteristic = "", SelectionBySetsOfAdditionalDetails = Undefined, UseTitleInsteadOfPresentation = False)
	
	Query = New Query;
	
	TableConnectionTemplates = New ValueTable;
	TableConnectionTemplates.Columns.Add("TemplateNumber");
	TableConnectionTemplates.Columns.Add("DescriptionOfSourceOfCharacteristics");
	
	TableConnectionTemplates.Columns.Add("CharacteristicTypes");
	TableConnectionTemplates.Columns.Add("KeyField");
	TableConnectionTemplates.Columns.Add("TypesFilterField");
	
	SqH = New NumberQualifiers(10, 0, AllowedSign.Any);
	KVS = New StringQualifiers(1000, AllowedLength.Variable);
	KVD = New DateQualifiers(DateFractions.DateTime);
	DescriptionOfReferenceValues = Common.AllRefsTypeDetails();
	StringTypeDetails = New TypeDescription("String",,,, KVS, KVD);
	TypeDescriptionNumber = New TypeDescription("Number",,, SqH);
	BooleanTypeDetails = New TypeDescription("Boolean");
	DateTypeDetails = New TypeDescription("Boolean",,,,, KVD);
	IndexFlags = New Structure;
	IndexFlags.Insert("ThereAreLines", False);
	IndexFlags.Insert("ThereAreNumbers", False);
	IndexFlags.Insert("ThereIsBoolean", False);
	IndexFlags.Insert("ThereAreDates", False);
	IndexFlags.Insert("ThereAreRefs", False);
	
	
	CharacteristicsOfMetadataObjectsByTemplates = New ValueTable;
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("DescriptionOfPropertyOwnerType",
		Common.StringTypeDetails(1000));
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("TemplateNumber",
		Common.TypeDescriptionNumber(5, 0));
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("SignificanceOfSelectionOfReferenceSpecies", DescriptionOfReferenceValues);
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("ImportanceOfSpeciesSelectionRow", StringTypeDetails);
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("SignificanceOfSpeciesSelectionNumber", TypeDescriptionNumber);
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("ValueOfSpeciesSelectionIsBoolean", BooleanTypeDetails);
	CharacteristicsOfMetadataObjectsByTemplates.Columns.Add("ImportanceOfSpeciesSelectionDate", DateTypeDetails);
	
	ConditionExpressionById = "";
	If Not IsBlankString(ExpressionOfCharacteristic) Then
		For Each DescriptionOfSourceOfCharacteristics In PropertiesOfCharacteristicSources Do
			SearchRow = "{" + DescriptionOfSourceOfCharacteristics.PropertyTypePrefix;
			If Not StrStartsWith(ExpressionOfCharacteristic, SearchRow) Then
				Continue;
			EndIf;
		
			ItemVariantID = Mid(ExpressionOfCharacteristic, StrLen(SearchRow) + 1);
			ItemVariantID = Mid(ItemVariantID, 1, StrLen(ItemVariantID) -1);
			ConditionExpressionById = "TableOfTypesOfCharacteristics.%1 = ""%2""";
			ConditionExpressionById = StringFunctionsClientServer.SubstituteParametersToString(
				ConditionExpressionById,
				DescriptionOfSourceOfCharacteristics.IdField_,
				ItemVariantID);
			Break;
		EndDo;
	EndIf;
	
	Types = TypeDescription.Types();
	For Each Type In Types Do
		MetadataObjectsList = MetadataObjectByValueType(Type);
		If MetadataObjectsList = Undefined Then
			Continue
		EndIf;
		MdObjectType = MetadataObjectKind(MetadataObjectsList, True);
		If MdObjectType = Undefined Then
			// The transfer has no details
			Continue;
		EndIf;
		
		SourceTypeExpression = StringFunctionsClientServer.SubstituteParametersToString(
			"%1.%2",
			MdObjectType,
			MetadataObjectsList.Name);
		
		SourcesOfCharacteristics = CacheOfFeatureSources.Get(Type);
		If SourcesOfCharacteristics = Undefined Then
			SourcesOfCharacteristics = New Map;
			FillInUsedSourcesOfCharacteristics(SourcesOfCharacteristics,
				MetadataObjectsList, PropertiesOfCharacteristicSources);
			CacheOfFeatureSources.Insert(Type, SourcesOfCharacteristics);
		EndIf;
		
		If SourcesOfCharacteristics.Count() > 0 Then
			For Each DescriptionOfSourceOfCharacteristics In PropertiesOfCharacteristicSources Do
				If TypeOf(SelectionBySetsOfAdditionalDetails) = Type("Array")
					And DescriptionOfSourceOfCharacteristics.SourceMetadata <> Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo Then
					Continue;
				EndIf;
				
				IncludeSourceOfCharacteristicsInRequest = False;
				If IsBlankString(ExpressionOfCharacteristic) Then
					SourcesOfCurCharacteristics = SourcesOfCharacteristics.Get(DescriptionOfSourceOfCharacteristics.SourceMetadata);
					IncludeSourceOfCharacteristicsInRequest = (SourcesOfCurCharacteristics <> Undefined);
				Else
					SearchRow = "{" + DescriptionOfSourceOfCharacteristics.PropertyTypePrefix;
					If StrStartsWith(ExpressionOfCharacteristic, SearchRow) Then
						IncludeSourceOfCharacteristicsInRequest = True;
					EndIf;
				EndIf;
				If IncludeSourceOfCharacteristicsInRequest Then
					SourcesOfCurCharacteristics = SourcesOfCharacteristics.Get(DescriptionOfSourceOfCharacteristics.SourceMetadata);
					
					For Each DescriptionOfCharacteristicInMetadata In SourcesOfCurCharacteristics Do
						
						SearchByTemplate = New Structure;
						SearchByTemplate.Insert("CharacteristicTypes", DescriptionOfCharacteristicInMetadata.CharacteristicTypes);
						SearchByTemplate.Insert("KeyField", DescriptionOfCharacteristicInMetadata.KeyField);
						SearchByTemplate.Insert("TypesFilterField", DescriptionOfCharacteristicInMetadata.TypesFilterField);
						TemplateStrings = TableConnectionTemplates.FindRows(SearchByTemplate);
						If TemplateStrings.Count() = 0 Then
							TemplateRow = TableConnectionTemplates.Add();
							TemplateNumber = TableConnectionTemplates.Count();
							FillPropertyValues(TemplateRow, DescriptionOfCharacteristicInMetadata);
							TemplateRow.TemplateNumber = TemplateNumber;
							TemplateRow.DescriptionOfSourceOfCharacteristics = DescriptionOfSourceOfCharacteristics;
							
						Else
							TemplateRow = TemplateStrings[0];
							TemplateNumber = TemplateRow.TemplateNumber;
						EndIf;
						
						SelectionStringByCharacteristicType = CharacteristicsOfMetadataObjectsByTemplates.Add();
						SelectionStringByCharacteristicType.TemplateNumber = TemplateNumber;
						SelectionStringByCharacteristicType.DescriptionOfPropertyOwnerType = SourceTypeExpression;
						FilterType = TypeOf(DescriptionOfCharacteristicInMetadata.TypesFilterValue);
						If FilterType = Type("String") Then
							SelectionStringByCharacteristicType.ImportanceOfSpeciesSelectionRow = DescriptionOfCharacteristicInMetadata.TypesFilterValue;
							IndexFlags.ThereAreLines = True;
						ElsIf FilterType = Type("Number") Then
							SelectionStringByCharacteristicType.SignificanceOfSpeciesSelectionNumber = DescriptionOfCharacteristicInMetadata.TypesFilterValue;
							IndexFlags.ThereAreNumbers = True;
						ElsIf FilterType = Type("Boolean") Then
							SelectionStringByCharacteristicType.ValueOfSpeciesSelectionIsBoolean = DescriptionOfCharacteristicInMetadata.TypesFilterValue;
							IndexFlags.ThereIsBoolean = True;
						ElsIf FilterType = Type("Date") Then
							SelectionStringByCharacteristicType.ImportanceOfSpeciesSelectionDate = DescriptionOfCharacteristicInMetadata.TypesFilterValue;
							IndexFlags.ThereAreDates = True;
						Else
							SelectionStringByCharacteristicType.SignificanceOfSelectionOfReferenceSpecies = DescriptionOfCharacteristicInMetadata.TypesFilterValue;
							IndexFlags.ThereAreRefs = True;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If CharacteristicsOfMetadataObjectsByTemplates.Count() > 0 Then
		
		SeparatorText = "
		|
		|UNION ALL
		|
		|";
		QueryTexts = New Array;
		QueryText = 
		"SELECT
			|	CharacteristicsOfMetadataObjectsByTemplates.TemplateNumber AS TemplateNumber,
			|	CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSelectionOfReferenceSpecies AS SignificanceOfSelectionOfReferenceSpecies,
			|	CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionRow AS ImportanceOfSpeciesSelectionRow,
			|	CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSpeciesSelectionNumber AS SignificanceOfSpeciesSelectionNumber,
			|	CharacteristicsOfMetadataObjectsByTemplates.ValueOfSpeciesSelectionIsBoolean AS ValueOfSpeciesSelectionIsBoolean,
			|	CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionDate AS ImportanceOfSpeciesSelectionDate,
			|	CharacteristicsOfMetadataObjectsByTemplates.DescriptionOfPropertyOwnerType AS DescriptionOfPropertyOwnerType
			|INTO CharacteristicsOfMetadataObjectsByTemplates
			|FROM
			|	&CharacteristicsOfMetadataObjectsByTemplates AS CharacteristicsOfMetadataObjectsByTemplates
			|INDEX BY
			|	CharacteristicsOfMetadataObjectsByTemplates.TemplateNumber";
		If IndexFlags.ThereAreRefs Then
			QueryText = QueryText + ",
			|	CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSelectionOfReferenceSpecies";
		EndIf;
		If IndexFlags.ThereAreLines Then
			QueryText = QueryText + ",
			|	CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionRow";
		EndIf;
		If IndexFlags.ThereAreNumbers Then
			QueryText = QueryText + ",
			|	CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSpeciesSelectionNumber";
		EndIf;
		If IndexFlags.ThereIsBoolean Then
			QueryText = QueryText + ",
			|	CharacteristicsOfMetadataObjectsByTemplates.ValueOfSpeciesSelectionIsBoolean";
		EndIf;
		If IndexFlags.ThereAreDates Then
			QueryText = QueryText + ",
			|	CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionDate";
		EndIf;
		
		For Each SampleTemplateDescription In TableConnectionTemplates Do
			Text = SampleTextForPropertiesAndCharacteristicsBasedOnTemplate(SampleTemplateDescription,
				IndexFlags,
				ConditionExpressionById,
				SelectionBySetsOfAdditionalDetails,
				UseTitleInsteadOfPresentation);
			QueryTexts.Add(Text);
		EndDo;
		
		QueryText = QueryText + "
		|;
		|
		|" + StrConcat(QueryTexts, SeparatorText);
		
		Query.SetParameter("CharacteristicsOfMetadataObjectsByTemplates", CharacteristicsOfMetadataObjectsByTemplates);
		Query.SetParameter("AdditionalAttributeSets", SelectionBySetsOfAdditionalDetails);
		
	Else
		
		QueryText =
		"SELECT
		|	"""" AS DescriptionOfPropertyOwnerType,
		|	UNDEFINED AS Ref,
		|	"""" AS FullID,
		|	"""" AS IDForFormulas,
		|	"""" AS PropertyTypePrefix,
		|	"""" AS CharacteristicPresentation,
		|	UNDEFINED AS ValueType
		|WHERE
		|	FALSE";
		
	EndIf;
	Query.Text = QueryText;
	
	Return Query;
	
EndFunction

Function SampleTextForPropertiesAndCharacteristicsBasedOnTemplate(SampleTemplateDescription, IndexFlags, ConditionExpressionById,
				AdditionalAttributeSets, UseTitleInsteadOfPresentation)
	
	DescriptionOfSourceOfCharacteristics = SampleTemplateDescription.DescriptionOfSourceOfCharacteristics;
	MDOfSourceOfCharacteristics = DescriptionOfSourceOfCharacteristics.SourceMetadata;
	TableOfTypesOfCharacteristics = ProcessingOfFormulasCached.FullNameOfDataTable(MDOfSourceOfCharacteristics.FullName());
	
	KeyField = SampleTemplateDescription.KeyField; // MetadataObjectField - 
	
	If SampleTemplateDescription.CharacteristicTypes = MDOfSourceOfCharacteristics Then
		
		SubqueryText =
		"SELECT
		|	CharacteristicsOfMetadataObjectsByTemplates.DescriptionOfPropertyOwnerType AS DescriptionOfPropertyOwnerType,
		|	&ExpressionOfReferenceField AS Ref,
		|	&FullIdFieldExpression AS FullID,
		|	&ExpressionOfIdFieldForFormulas AS IDForFormulas,
		|	&ExpressionOfTypePrefixFieldOfCharacteristicsType AS PropertyTypePrefix,
		|	&PresentationExpression AS CharacteristicPresentation,
		|	&ValueTypeExpression AS ValueType
		|FROM
		|	&CharacteristicsOfMetadataObjectsByTemplates AS CharacteristicsOfMetadataObjectsByTemplates
		|INNER JOIN
		|	#SourceTypesOfCharacteristics AS TableOfTypesOfCharacteristics
		|ON
		|	CharacteristicsOfMetadataObjectsByTemplates.TemplateNumber = &TemplateNumber
		|	AND &ConditionsForSelectingTypesOfCharacteristics
		|	AND &ConditionsByCharacteristics";
		
	Else
		
		SubqueryText =
		"SELECT
		|	CharacteristicsOfMetadataObjectsByTemplates.DescriptionOfPropertyOwnerType AS DescriptionOfPropertyOwnerType,
		|	&ExpressionOfReferenceField AS Ref,
		|	&FullIdFieldExpression AS FullID,
		|	&ExpressionOfIdFieldForFormulas AS IDForFormulas,
		|	&ExpressionOfTypePrefixFieldOfCharacteristicsType AS PropertyTypePrefix,
		|	&PresentationExpression AS CharacteristicPresentation,
		|	&ValueTypeExpression AS ValueType
		|FROM
		|	&CharacteristicsOfMetadataObjectsByTemplates AS CharacteristicsOfMetadataObjectsByTemplates
		|INNER JOIN
		|	#SourceTypesOfCharacteristics AS SourceTable1
		|ON
		|	CharacteristicsOfMetadataObjectsByTemplates.TemplateNumber = &TemplateNumber
		|	AND &ConditionsForSelectingTypesOfCharacteristics
		|INNER JOIN
		|	#TableOfTypesOfCharacteristics AS TableOfTypesOfCharacteristics
		|ON
		|	&ConnectionCondition
		|	AND &ConditionsByCharacteristics";
		
		ConnectionCondition = StringFunctionsClientServer.SubstituteParametersToString(
			"SourceTable1.%1 = TableOfTypesOfCharacteristics.Ref",
			KeyField.Name);
		
		If Not IsBlankString(ConditionExpressionById) Then
			ConnectionCondition = ConnectionCondition + "
			|	AND " + ConditionExpressionById;
		EndIf;
		
		SubqueryText = StrReplace(SubqueryText, "#TableOfTypesOfCharacteristics", TableOfTypesOfCharacteristics);
		SubqueryText = StrReplace(SubqueryText, "&ConnectionCondition", ConnectionCondition);
		
	EndIf;
	
	SubqueryText = StrReplace(SubqueryText, "&ConditionsByCharacteristics", "TableOfTypesOfCharacteristics.%1 <> """"");
	
	SubqueryText = StringFunctionsClientServer.SubstituteParametersToString(SubqueryText,
		DescriptionOfSourceOfCharacteristics.IdField_);
	
	SourceTypesOfCharacteristics = ProcessingOfFormulasCached.FullNameOfDataTable(
		SampleTemplateDescription.CharacteristicTypes.FullName());
	
	If SampleTemplateDescription.CharacteristicTypes = MDOfSourceOfCharacteristics Then
		ExpressionOfReferenceField = "TableOfTypesOfCharacteristics."
			+ KeyField.Name;
	Else
		ExpressionOfReferenceField = "SourceTable1."
			+ KeyField.Name;
	EndIf;
	
	FullIdFieldExpression = ExpressionOfFullFeatureID(MDOfSourceOfCharacteristics, False);
	FullIdFieldExpression = StrReplace(FullIdFieldExpression, "%TableName%", "TableOfTypesOfCharacteristics");
	ExpressionOfIdFieldForFormulas = StringFunctionsClientServer.SubstituteParametersToString(
		"TableOfTypesOfCharacteristics.%1",
		DescriptionOfSourceOfCharacteristics.IdField_);
	ExpressionOfTypePrefixFieldOfCharacteristicsType = StringFunctionsClientServer.SubstituteParametersToString(
		"""%1""",
		DescriptionOfSourceOfCharacteristics.PropertyTypePrefix);
	If Not UseTitleInsteadOfPresentation Then
		PresentationExpression = "PRESENTATION(TableOfTypesOfCharacteristics.Ref)";
	Else
		PresentationExpression = "TableOfTypesOfCharacteristics.Description";
	EndIf;
	
	If DescriptionOfSourceOfCharacteristics.ValueTypeExpressionIsUsed Then
		ValueTypeExpression = DescriptionOfSourceOfCharacteristics.ExpressionTypeOfValue;
	Else
		ValueTypeExpression = "TableOfTypesOfCharacteristics."
			+ DescriptionOfSourceOfCharacteristics.FieldTypeOfValues;
	EndIf;
	
	ConditionsForSelectingTypesOfCharacteristics = "";
	If SampleTemplateDescription.TypesFilterField = Undefined Then
		
		ConditionsForSelectingTypesOfCharacteristics = "TRUE";
		
	Else
		
		TypesFilterField = SampleTemplateDescription.TypesFilterField; // MetadataObjectField -
		TypesOfSelectionField = Undefined;
		SelectionFieldOfReferenceType = False;
		SelectionFieldString = False;
		SelectionFieldNumber = False;
		SelectionFieldIsBoolean = False;
		DateSelectionField = False;
		
		FullNameOfCharacteristicType = SampleTemplateDescription.CharacteristicTypes.FullName();
		If StrFind(Upper(FullNameOfCharacteristicType), Upper(".TabularSection."))> 0
			And Upper(TypesFilterField.Name) = "REF" Then
			ParentMDObject = SampleTemplateDescription.CharacteristicTypes.Parent(); // MetadataObject -
			DescriptionOfSelectionFieldTypes = New TypeDescription(MetadataObjectKind(ParentMDObject, True)
				+ "." + ParentMDObject.Name);
			TypesOfSelectionField = DescriptionOfSelectionFieldTypes.Types();
		Else
			Attribute = SampleTemplateDescription.CharacteristicTypes.Attributes.Find(TypesFilterField.Name);
			If Attribute = Undefined Then
				AttributesCount = SampleTemplateDescription.CharacteristicTypes.StandardAttributes.Count();
				For AttributeNumber = 1 To AttributesCount Do
					AttributeDetails = SampleTemplateDescription.CharacteristicTypes.StandardAttributes[AttributeNumber - 1]; // MetadataObjectField -
					If AttributeDetails.Name = TypesFilterField.Name Then
						TypesOfSelectionField = AttributeDetails.Type.Types();
						Break;
					EndIf;
				EndDo;
			Else
				TypesOfSelectionField = Attribute.Type.Types();
			EndIf;
		EndIf;
		
		If Not TypesOfSelectionField = Undefined Then
			If TypesOfSelectionField.Find(Type("String")) <> Undefined Then
				SelectionFieldString = True;
			ElsIf TypesOfSelectionField.Find(Type("Number")) <> Undefined Then
				SelectionFieldNumber = True;
			ElsIf TypesOfSelectionField.Find(Type("Boolean")) <> Undefined Then
				SelectionFieldIsBoolean = True;
			ElsIf TypesOfSelectionField.Find(Type("Date")) <> Undefined Then
				DateSelectionField = True;
			Else
				SelectionFieldOfReferenceType = True;
			EndIf;
		EndIf;
		
		ConditionsForSelectingTypesOfCharacteristics = "";
		If IndexFlags.ThereAreRefs Then
			ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + ?(ConditionsForSelectingTypesOfCharacteristics = "", "", "
					|	AND ");
			If SelectionFieldOfReferenceType Then
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ StringFunctionsClientServer.SubstituteParametersToString(
							"%SelectionTableName_%.%1 = CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSelectionOfReferenceSpecies",
							TypesFilterField.Name);
			Else
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ "CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSelectionOfReferenceSpecies = UNDEFINED";
			EndIf;
		EndIf;
		If IndexFlags.ThereAreLines Then
			ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + ?(ConditionsForSelectingTypesOfCharacteristics = "", "", "
					|	AND ");
					
			If SelectionFieldString Then
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ StringFunctionsClientServer.SubstituteParametersToString(
							"%SelectionTableName_%.%1 = CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionRow",
							TypesFilterField.Name);
			Else
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ "CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionRow = """"";
			EndIf;
		EndIf;
		If IndexFlags.ThereAreNumbers Then
			ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + ?(ConditionsForSelectingTypesOfCharacteristics = "", "", "
					|	AND ");
					
			If SelectionFieldNumber Then
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ StringFunctionsClientServer.SubstituteParametersToString(
							"%SelectionTableName_%.%1 = CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSpeciesSelectionNumber",
							TypesFilterField.Name);
			Else
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ "CharacteristicsOfMetadataObjectsByTemplates.SignificanceOfSpeciesSelectionNumber = 0";
			EndIf;
		EndIf;
		If IndexFlags.ThereIsBoolean Then
			ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + ?(ConditionsForSelectingTypesOfCharacteristics = "", "", "
					|	AND ");
				
			If SelectionFieldIsBoolean Then
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ StringFunctionsClientServer.SubstituteParametersToString(
							"%SelectionTableName_%.%1 = CharacteristicsOfMetadataObjectsByTemplates.ValueOfSpeciesSelectionIsBoolean",
							TypesFilterField.Name);
			Else
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ "CharacteristicsOfMetadataObjectsByTemplates.ValueOfSpeciesSelectionIsBoolean = FALSE";
			EndIf;
		EndIf;
		If IndexFlags.ThereAreDates Then
			ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + ?(ConditionsForSelectingTypesOfCharacteristics = "", "", "
					|	AND ");
				
			If DateSelectionField Then
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ StringFunctionsClientServer.SubstituteParametersToString(
							"%SelectionTableName_%.%1 = CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionDate",
							TypesFilterField.Name);
			Else
				ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics
					+ "CharacteristicsOfMetadataObjectsByTemplates.ImportanceOfSpeciesSelectionDate = FALSE";
			EndIf;
		EndIf;
		If SampleTemplateDescription.CharacteristicTypes = MDOfSourceOfCharacteristics Then
			SelectionTableName_ = "TableOfTypesOfCharacteristics";
		Else
			SelectionTableName_ = "SourceTable1";
		EndIf;
		ConditionsForSelectingTypesOfCharacteristics = StrReplace(ConditionsForSelectingTypesOfCharacteristics, "%SelectionTableName_%", SelectionTableName_);
		
	EndIf;
	
	ExpressionOfAdditionalSelection = "";
	If MDOfSourceOfCharacteristics = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo Then
		If TypeOf(AdditionalAttributeSets) = Type("Array")
			And AdditionalAttributeSets.Count() > 0 Then
			// The expression of additional selections of the source of characteristics should contain only conditions for the fields of the table of types of characteristics,
			// since additional conditions are set on the metadata object of the types of characteristics.
			ExpressionOfAdditionalSelection =
			"TableOfTypesOfCharacteristics.Ref In
			|	(&ExpressionForSelectingAdditionalBankingDetails)";
			TemplateForSelectingAdditionalBankingDetails =
			"SELECT
			|	PropertySetsComposition.Property AS Property
			|FROM
			|	&SetsTable AS PropertySetsComposition
			|WHERE
			|	PropertySetsComposition.Ref IN (&AdditionalAttributeSets)";
			If SampleTemplateDescription.CharacteristicTypes = Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalAttributes Then
				SampleExpression = StrReplace(TemplateForSelectingAdditionalBankingDetails,
					"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes");
			ElsIf SampleTemplateDescription.CharacteristicTypes = Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalInfo Then
				SampleExpression = StrReplace(TemplateForSelectingAdditionalBankingDetails,
					"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
			Else
				SampleExpression = StrReplace(TemplateForSelectingAdditionalBankingDetails,
					"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes")
					+ "
					|
					|UNION ALL
					|
					|"
					+ StrReplace(TemplateForSelectingAdditionalBankingDetails,
					"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
			EndIf;
			ExpressionOfAdditionalSelection = StrReplace(ExpressionOfAdditionalSelection, "&ExpressionForSelectingAdditionalBankingDetails", SampleExpression);
		EndIf;
	EndIf;
	If SampleTemplateDescription.CharacteristicTypes = MDOfSourceOfCharacteristics Then
		If Not IsBlankString(ConditionExpressionById) Then
			ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + "
			|	AND " + ConditionExpressionById;
		EndIf;
	EndIf;
	If Not ExpressionOfAdditionalSelection = "" Then
		SubqueryText = SubqueryText + "
		|WHERE
		|	" + ExpressionOfAdditionalSelection;
	EndIf;
	
	ExpressionTemplateNumber = Format(SampleTemplateDescription.TemplateNumber, "NZ=0; NG=0;");
	
	SubqueryText = StrReplace(SubqueryText, "&CharacteristicsOfMetadataObjectsByTemplates", "CharacteristicsOfMetadataObjectsByTemplates");
	SubqueryText = StrReplace(SubqueryText, "#SourceTypesOfCharacteristics", SourceTypesOfCharacteristics);
	SubqueryText = StrReplace(SubqueryText, "#TableOfTypesOfCharacteristics", TableOfTypesOfCharacteristics);
	
	SubqueryText = StrReplace(SubqueryText, "&ExpressionOfReferenceField", ExpressionOfReferenceField);
	SubqueryText = StrReplace(SubqueryText, "&FullIdFieldExpression", FullIdFieldExpression);
	SubqueryText = StrReplace(SubqueryText, "&ExpressionOfIdFieldForFormulas", ExpressionOfIdFieldForFormulas);
	SubqueryText = StrReplace(SubqueryText, "&ExpressionOfTypePrefixFieldOfCharacteristicsType", ExpressionOfTypePrefixFieldOfCharacteristicsType);
	SubqueryText = StrReplace(SubqueryText, "&PresentationExpression", PresentationExpression);
	SubqueryText = StrReplace(SubqueryText, "&ValueTypeExpression", ValueTypeExpression);
	SubqueryText = StrReplace(SubqueryText, "&ConditionsForSelectingTypesOfCharacteristics", ConditionsForSelectingTypesOfCharacteristics);
	
	SubqueryText = StrReplace(SubqueryText, "&TemplateNumber", ExpressionTemplateNumber);
	
	Return SubqueryText;
	
EndFunction

Function GetPresentationCharacteristicsForObjectsOfType(TypeDescription, ExpressionOfCharacteristic, 
		PropertiesOfCharacteristicSources, CacheOfFeatureSources)
	
	FeaturePresentations = New Map();
	
	Query = RequestingPropertiesCharacteristicsForMetadataObjects(TypeDescription,
		PropertiesOfCharacteristicSources, CacheOfFeatureSources, ExpressionOfCharacteristic);
	
	TypesOfFeatureOwnersByPresentation = New Map;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Presentation = Selection.CharacteristicPresentation;
		TypesArray = TypesOfFeatureOwnersByPresentation.Get(Presentation);
		If TypesArray = Undefined Then
			TypesArray = New Array;
		EndIf;
		Type = Type(Selection.DescriptionOfPropertyOwnerType);
		TypesArray.Add(Type);
		TypesOfFeatureOwnersByPresentation.Insert(Presentation, TypesArray);
	EndDo;
	For Each KeyAndValue In TypesOfFeatureOwnersByPresentation Do
		TypeDescription = New TypeDescription(KeyAndValue.Value);
		Presentation = KeyAndValue.Key;
		FeaturePresentations.Insert(TypeDescription, Presentation);
	EndDo;
	
	Return FeaturePresentations;
	
EndFunction

Function TableOfPropertiesCharacteristicsByOwnerType(DescriptionOfTypesOfPossibleCharacteristics)
	
	DescriptionOfIDType = New TypeDescription("String",, New StringQualifiers(1000, AllowedLength.Variable));
	DescriptionOfPrefixType = New TypeDescription("String",, New StringQualifiers(10, AllowedLength.Variable));
	
	Table = New ValueTable();
	Table.Columns.Add("Ref", DescriptionOfTypesOfPossibleCharacteristics);
	Table.Columns.Add("FullID", DescriptionOfIDType);
	Table.Columns.Add("IDForFormulas", DescriptionOfIDType);
	Table.Columns.Add("PropertyTypePrefix", DescriptionOfPrefixType);
	Table.Columns.Add("CharacteristicPresentation", DescriptionOfIDType);
	Table.Columns.Add("PresentationOfCharacteristicUpperCase", DescriptionOfIDType);
	Table.Columns.Add("ValueType");
	
	Return Table;
	
EndFunction

// Returns tables of characteristics and their properties for each value type
// 
// Parameters:
// 	TypeDescription - TypeDescription - Types for which you want to obtain characteristics.
// 	SelectionBySetsOfAdditionalDetails - Undefined, Array of CatalogRef.AdditionalAttributesAndInfoSets - If a
// 			selection is set, only additional details and information that meets the selection will be received.
// 	UseTitleInsteadOfPresentation - Boolean - True if you need to get names as views.
// 			For example, in templates for names of types of items.
// Returns:
// 	Map - Matching the data type included in the type description passed to the method and the characteristic properties table:
// 	  * Key - Type - Type of values.
// 	  * Value - See TableOfPropertiesCharacteristicsByOwnerType
//
Function GetPropertiesOfCharacteristicsForObjectsOfType(TypeDescription, SelectionBySetsOfAdditionalDetails = Undefined,
			UseTitleInsteadOfPresentation = False)
	
	PropertiesOfCharacteristicSources = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	CacheOfFeatureSources = New Map;
	
	PropertiesOfCharacteristicsByDataType = New Map();
	OverridingValueTypes = New Map;
	DescriptionOfTypesOfPossibleCharacteristics = New Array;
	For Each DescriptionOfPossibleCharacteristics In PropertiesOfCharacteristicSources Do
		MetadataOfCharacteristics = DescriptionOfPossibleCharacteristics.SourceMetadata; // MetadataObjectChartOfCharacteristicTypes - 
		MdObjectType = MetadataObjectKind(MetadataOfCharacteristics, True);
		TypeAsString = StringFunctionsClientServer.SubstituteParametersToString("%1.%2",
			MdObjectType, MetadataOfCharacteristics.Name);
		TypeOfFeature = Type(TypeAsString);
		DescriptionOfTypesOfPossibleCharacteristics.Add(TypeOfFeature);
		If ValueIsFilled(DescriptionOfPossibleCharacteristics.OverridingValueTypeExpression) Then
			OverridingValueTypes.Insert(DescriptionOfPossibleCharacteristics.PropertyTypePrefix,
				DescriptionOfPossibleCharacteristics.OverridingValueTypeExpression);
		EndIf;
	EndDo;
	DescriptionOfTypesOfPossibleCharacteristics = New TypeDescription(DescriptionOfTypesOfPossibleCharacteristics);
	
	Query = RequestingPropertiesCharacteristicsForMetadataObjects(TypeDescription,
		PropertiesOfCharacteristicSources,
		CacheOfFeatureSources,
		"",
		SelectionBySetsOfAdditionalDetails,
		UseTitleInsteadOfPresentation);
	
	If TypeOf(SelectionBySetsOfAdditionalDetails) = Type("Array") Then
		
	EndIf;
	Query.Text = Query.Text + "
	|TOTALS BY
	|	DescriptionOfPropertyOwnerType";
	
	SelectionOwnerType = Query.Execute().Select(QueryResultIteration.ByGroups, "DescriptionOfPropertyOwnerType");
	
	While SelectionOwnerType.Next() Do
		Type = Type(SelectionOwnerType.DescriptionOfPropertyOwnerType);
		TableOfPropertiesCharacteristics = TableOfPropertiesCharacteristicsByOwnerType(DescriptionOfTypesOfPossibleCharacteristics);
		
		Selection = SelectionOwnerType.Select();
		While Selection.Next() Do
			PropertyString = TableOfPropertiesCharacteristics.Add();
			FillPropertyValues(PropertyString, Selection);
			PropertyString.PresentationOfCharacteristicUpperCase = Upper(Selection.CharacteristicPresentation);
			OverridingType = OverridingValueTypes.Get(Selection.PropertyTypePrefix);
			If ValueIsFilled(OverridingType) Then
				PropertyString.ValueType = OverridingType;
			EndIf;
		EndDo;
		
		PropertiesOfCharacteristicsByDataType.Insert(Type, TableOfPropertiesCharacteristics);
	EndDo;
	
	Return PropertiesOfCharacteristicsByDataType;
	
EndFunction

// Returns text from query language extension constructs for describing characteristics.
// 
// Parameters:
// 	TypeDescription - TypeDescription - types for which you need to create feature description expressions in the SCD query extension language.
// Returns:
// 	String - expressions describing characteristics in the query extension language of the SCD.
//
Function DescriptionOfDCSCharacteristicsForDescribingTypes(TypeDescription)
	
	QueryLanguageExtensionExpressions = "";
	
	PropertiesOfCharacteristicSources = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	
	StringDataTypes = TypeDescription.Types();
	For Each ValueType In StringDataTypes Do
		MetadataObjectsList = MetadataObjectByValueType(ValueType);
		If MetadataObjectsList = Undefined Then
			Continue
		EndIf;
		MdObjectType = MetadataObjectKind(MetadataObjectsList);
		If MdObjectType = Undefined Then
			// The transfer has no details
			Continue;
		EndIf;
		
		TextsOfCharacteristics = New Array;
		
		If MetadataObjectsList.Characteristics.Count() = 0 Then
			// For the metadata object, any (not only supported) characteristics are not defined at the metadata level,
			// so an expression overriding the receipt of characteristics is not necessary.
			Continue;
		EndIf;
		
		// Matching Key - metadata object type of characteristics, Value - descriptioncharacteristics.
		UsedSourcesOfCharacteristics = New Map;
		
		FillInUsedSourcesOfCharacteristics(UsedSourcesOfCharacteristics,
			MetadataObjectsList,
			PropertiesOfCharacteristicSources);
		
		SourceTypeExpression = StringFunctionsClientServer.SubstituteParametersToString(
				"%1.%2",
				MdObjectType,
				MetadataObjectsList.Name);
		
		If UsedSourcesOfCharacteristics.Count() = 0 Then
			// The supported types of characteristics cannot be defined. We prohibit the use of any characteristics.
			
			CharacteristicsTextTemplate = "
			|{Characteristics
			|	TYPE(&SourceTypeExpression)
			|	CharacteristicTypes (SELECT
			|			UNDEFINED AS Id,
			|			"""" AS Name,
			|			UNDEFINED AS ValueType
			|		WHERE FALSE)
			|	KeyField Id
			|	NameField Name
			|	ValueTypeField ValueType
			|	CharacteristicValues (SELECT
			|			UNDEFINED AS Ref,
			|			UNDEFINED AS Property,
			|			UNDEFINED AS VALUE
			|		WHERE FALSE)
			|	ObjectField Ref
			|	TypeField Property
			|	ValueField VALUE }";
			CharacteristicsText = StrReplace(CharacteristicsTextTemplate,
				"&SourceTypeExpression", SourceTypeExpression);
			
			TextsOfCharacteristics.Add(CharacteristicsText);
			
		Else
			
			CharacteristicsTextTemplate = "
			|{Characteristics
			|	TYPE(&SourceTypeExpression)
			|	CharacteristicTypes (&SubqueryTextSourcesOfCharacteristics
			|		)
			|	KeyField Id
			|	NameField Name
			|	ValueTypeField ValueType
			|	CharacteristicValues (&SubqueryTextSourcesOfValues)
			|	ObjectField Ref
			|	TypeField Property
			|	ValueField VALUE }";
			
			SubqueryTextSourcesOfCharacteristics = "";
			
			SubqueryTextSourcesOfValues = "";
			
			For Each SourceObjectAndDescriptionOfCharacteristics In UsedSourcesOfCharacteristics Do
				
				MDOfSourceOfCharacteristics = SourceObjectAndDescriptionOfCharacteristics.Key;
				CharacteristicsDescriptions = SourceObjectAndDescriptionOfCharacteristics.Value;
				
				SourceProperties = PropertiesOfCharacteristicSources.Find(MDOfSourceOfCharacteristics, "SourceMetadata");
				
				For Each CharacteristicsDescription In CharacteristicsDescriptions Do
					
					// A combination of subqueries cannot be placed in a subquery of a selection of types of characteristics, so
					// each set of characteristics is a new query.
					SubqueryTextSourcesOfCharacteristics = SubqueryTextForSourcesAndTypesOfCharacteristics(
						SourceProperties,
						CharacteristicsDescription,,
						True);
					
					SubqueryTextSourcesOfValues = SubqueryTextForFeatureValueSources(CharacteristicsDescription);
					
					CharacteristicsText = CharacteristicsTextTemplate;
					CharacteristicsText = StrReplace(CharacteristicsText, "&SubqueryTextSourcesOfCharacteristics", SubqueryTextSourcesOfCharacteristics);
					CharacteristicsText = StrReplace(CharacteristicsText, "&SubqueryTextSourcesOfValues", SubqueryTextSourcesOfValues);
					CharacteristicsText = StrReplace(CharacteristicsText, "&SourceTypeExpression", SourceTypeExpression);
					
					TextsOfCharacteristics.Add(CharacteristicsText);
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
		QueryLanguageExtensionExpressions = QueryLanguageExtensionExpressions
			+ StrConcat(TextsOfCharacteristics, Chars.LF);
		
	EndDo;
	
	Return QueryLanguageExtensionExpressions;
	
EndFunction

// Returns a list of data sets used for expression calculations.
// 
// Parameters:
// 	CompositionSchema - DataCompositionSchema - The layout scheme used for calculating expressions.
// 	ExpressionsToCheck_ - Array of String - Expressions for calculations.
// 
// Returns:
// 	Map - sets used to evaluate expressions and their properties:
// 	 *Key - DataCompositionSchemaDataSetQuery, DataCompositionSchemaDataSetObject - a set of layout schema data.
// 	 *Value - Structure - Properties of the set used:
// 	   **SetFields - Array of String - lists the paths to the data of the set fields.
// 	   **DataSetIsUsedInFeatureExpressions - Boolean - flag using a set to evaluate an expression with a characteristic.
//
Function UsedLayoutSchemaDataSets(CompositionSchema, ExpressionsToCheck_)
	DataSetsUsed = New Map;
		
	SchemaDataSets = LayoutSchemaDataSets(CompositionSchema);
	For Each DataSetAndFields In SchemaDataSets Do
		DataSet = DataSetAndFields.Key;
		SetFields = DataSetAndFields.Value; // - Array of String -
		
		DataSetIsUsedInExpressions = False;
		DataSetIsUsedInFeatureExpressions = False;
		For Each FieldDataPath In SetFields Do
			For Each OriginalExpression In ExpressionsToCheck_ Do
				If StrFind(OriginalExpression, FieldDataPath) = 1 Then
					DataSetIsUsedInExpressions = True;
					
					ExpressionContainsCharacteristics = (StrFind(OriginalExpression, "{") > 0);
					If ExpressionContainsCharacteristics Then
						DataSetIsUsedInFeatureExpressions = True;
					EndIf;
					If DataSetIsUsedInFeatureExpressions Then
						Break;
					EndIf;
				EndIf;
			EndDo;
			If DataSetIsUsedInFeatureExpressions Then
				Break;
			EndIf;
		EndDo;
		
		If DataSetIsUsedInExpressions Then
			UsageParameters = New Structure;
			UsageParameters.Insert("SetFields", SetFields);
			UsageParameters.Insert("DataSetIsUsedInFeatureExpressions", DataSetIsUsedInFeatureExpressions);
			DataSetsUsed.Insert(DataSet, UsageParameters);
		EndIf;
	EndDo;
		
	Return DataSetsUsed;
EndFunction

Function LayoutSchemaDataSets(CompositionSchema)
	MatchingDataSets = New Map;
	For Each DataSet In CompositionSchema.DataSets Do
		FillDataAcquisitionSetsRecursively(MatchingDataSets, DataSet);
	EndDo;
	
	Return MatchingDataSets;
EndFunction

Procedure FillDataAcquisitionSetsRecursively(ListOfDataSets, Current_Set)
	If TypeOf(Current_Set) = Type("DataCompositionSchemaDataSetUnion") Then
		For Each NestedSet In Current_Set.Items Do
			FillDataAcquisitionSetsRecursively(ListOfDataSets, NestedSet);
		EndDo;
	Else
		ListOfDataSets.Insert(Current_Set, LayoutSchemaSetFields(Current_Set));
	EndIf;
EndProcedure

Function LayoutSchemaSetFields(LayoutSchemaDataSet)
	FieldArray = New Array;
	
	For Each Field In LayoutSchemaDataSet.Fields Do
		If TypeOf(Field) = Type("DataCompositionSchemaDataSetFieldFolder") Then
			Continue;
		EndIf;
		FieldArray.Add(Field.DataPath);
	EndDo;
	
	Return FieldArray;
EndFunction

#EndRegion

#Region LayoutDiagramByTypeDescription

// Returns the layout scheme for getting details and additional details based on the passed type description.
// The layout diagram has a single "Props" field of the corresponding type, and a section for describing characteristics can also be specified.
//
// Parameters:
//  TypeDescription - TypeDescription - Description of the field types for which the data layout scheme will be obtained.
//  DisplayCharacteristics - Boolean - Indicates whether you need to display additional details and contact information. The default value is True.
//  AdditionalAttributeSets - Undefined, Array of CatalogRef.AdditionalAttributesAndInfoSets - If there are elements in the array,
//  				then additional selection is applied for additional details and information for entering the specified sets.
//  				Undefined - the default value. No additional selections by set are specified. 
//  				Only standard selections for characteristics specified in metadata objects of the specified type are applied.
//
// Returns:
//  DataCompositionSchema - Layout diagram for obtaining the details and extras. characteristics.
//
Function LayoutDiagramForGettingPropsByValueType(TypeDescription, DisplayCharacteristics = True,
					AdditionalAttributeSets = Undefined)
	
	CompositionSchema = New DataCompositionSchema;
	SchemaDataSource = CompositionSchema.DataSources.Add();
	SchemaDataSource.Name = "DataSource1";
	SchemaDataSource.DataSourceType = "Local";
	
	SetAssociation = DataCompositionServer.AddEmptyDataSet(CompositionSchema,
		Type("DataCompositionSchemaDataSetUnion"),
		"NextLevelOfCurLineDetails");
	
	PropertiesOfCharacteristicSources = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	
	StringDataTypes = TypeDescription.Types();
	For Each ValueType In StringDataTypes Do
		MetadataObjectsList = MetadataObjectByValueType(ValueType);
		If MetadataObjectsList = Undefined Then
			Continue
		EndIf;
		MdObjectType = MetadataObjectKind(MetadataObjectsList);
		If MdObjectType = Undefined Then
			// The transfer has no details
			Continue;
		EndIf;
		
		// It is not possible to execute all types of text in one query due to exceeding the allowable length of the SQL query
		// (sampling an empty link).
		SetName = MdObjectType + "_" + MetadataObjectsList.Name;
		SetCurTypeOfProps = DataCompositionServer.AddEmptyDataSet(SetAssociation,
			Type("DataCompositionSchemaDataSetQuery"),
			SetName);
		
		
		DataSetText = "";
		TextsOfCharacteristics = New Array;
		
		
		// Matching Key - metadata object type of characteristics, Value - descriptioncharacteristics.
		UsedSourcesOfCharacteristics = New Map;
		
		If DisplayCharacteristics Then
			
			FillInUsedSourcesOfCharacteristics(UsedSourcesOfCharacteristics,
				MetadataObjectsList,
				PropertiesOfCharacteristicSources);
		EndIf;
		
		QueryText = "SELECT
		|	&EmptyReferenceExpression AS Attribute
		|{SELECT Attribute.*}
		|FROM
		|	&SourceTable2 AS SourceTable2
		|{WHERE (&EmptyReferenceExpression).* AS Attribute}";
		
		EmptyReferenceExpression = StringFunctionsClientServer.SubstituteParametersToString(
			"VALUE(%1.%2.EmptyRef)",
			MdObjectType,
			MetadataObjectsList.Name);
		
		SourceTable2 = StringFunctionsClientServer.SubstituteParametersToString(
			"%1.%2",
			MdObjectType,
			MetadataObjectsList.Name);
		
		QueryText = StrReplace(QueryText, "&EmptyReferenceExpression", EmptyReferenceExpression);
		QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
		
		SourceTypeExpression = StringFunctionsClientServer.SubstituteParametersToString(
				"%1.%2",
				MdObjectType,
				MetadataObjectsList.Name);
		
		If UsedSourcesOfCharacteristics.Count() = 0 Then
			
			CharacteristicsTextTemplate = "
			|{Characteristics
			|	TYPE(&SourceTypeExpression)
			|	CharacteristicTypes (SELECT
			|			UNDEFINED AS Id,
			|			"""" AS Name,
			|			UNDEFINED AS ValueType
			|		WHERE FALSE)
			|	KeyField Id
			|	NameField Name
			|	ValueTypeField ValueType
			|	CharacteristicValues (SELECT
			|			UNDEFINED AS Ref,
			|			UNDEFINED AS Property,
			|			UNDEFINED AS VALUE
			|		WHERE FALSE)
			|	ObjectField Ref
			|	TypeField Property
			|	ValueField VALUE }";
			CharacteristicsText = StrReplace(CharacteristicsTextTemplate,
				"&SourceTypeExpression", SourceTypeExpression);
			
			TextsOfCharacteristics.Add(CharacteristicsText);
			
		Else
			
			CharacteristicsTextTemplate = "
			|{Characteristics
			|	TYPE(&SourceTypeExpression)
			|	CharacteristicTypes (&SubqueryTextSourcesOfCharacteristics
			|		)
			|	KeyField Id
			|	NameField Name
			|	ValueTypeField ValueType
			|	CharacteristicValues (&SubqueryTextSourcesOfValues)
			|	ObjectField Ref
			|	TypeField Property
			|	ValueField VALUE }";
			
			SubqueryTextSourcesOfCharacteristics = "";
			
			SubqueryTextSourcesOfValues = "";
			
			For Each SourceObjectAndDescriptionOfCharacteristics In UsedSourcesOfCharacteristics Do
				
				MDOfSourceOfCharacteristics = SourceObjectAndDescriptionOfCharacteristics.Key;
				DescriptionsOfCharacteristicsInMetadata = SourceObjectAndDescriptionOfCharacteristics.Value;
				
				SourceProperties = PropertiesOfCharacteristicSources.Find(MDOfSourceOfCharacteristics, "SourceMetadata");
				
				For Each DescriptionOfCharacteristicsInMetadata In DescriptionsOfCharacteristicsInMetadata Do
					
					// A combination of subqueries cannot be placed in a subquery of a selection of types of characteristics, so
					// each set of characteristics is a new query.
					SubqueryTextSourcesOfCharacteristics = SubqueryTextForSourcesAndTypesOfCharacteristics(
						SourceProperties,
						DescriptionOfCharacteristicsInMetadata,
						AdditionalAttributeSets,
						True);
					
					SubqueryTextSourcesOfValues = SubqueryTextForFeatureValueSources(DescriptionOfCharacteristicsInMetadata);
					
					CharacteristicsText = CharacteristicsTextTemplate;
					CharacteristicsText = StrReplace(CharacteristicsText, "&SubqueryTextSourcesOfCharacteristics", SubqueryTextSourcesOfCharacteristics);
					CharacteristicsText = StrReplace(CharacteristicsText, "&SubqueryTextSourcesOfValues", SubqueryTextSourcesOfValues);
					CharacteristicsText = StrReplace(CharacteristicsText, "&SourceTypeExpression", SourceTypeExpression);
					
					TextsOfCharacteristics.Add(CharacteristicsText);
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
		DataSetText = QueryText + StrConcat(TextsOfCharacteristics, Chars.LF);
		
		SetCurTypeOfProps.Query = DataSetText;
		
		SetCurTypeOfProps.AutoFillAvailableFields = False;
		SetFields = SetCurTypeOfProps.Fields; // DataCompositionSchemaDataSetFields -
		SetField = SetFields.Add(Type("DataCompositionSchemaDataSetField"));
		SetField.Field = "Attribute"; // Service processed name.
		SetField.DataPath = "Attribute"; // Service processed name.
		TypesArray = New Array;
		TypesArray.Add(ValueType);
		SetField.ValueType = New TypeDescription(TypesArray);
		
	EndDo;
	
	SetFields = SetAssociation.Fields; // DataCompositionSchemaDataSetFields -
	SetField = SetFields.Add(Type("DataCompositionSchemaDataSetField"));
	SetField.Field = "Attribute"; // Service processed name.
	SetField.DataPath = "Attribute"; // Service processed name.
	SetField.ValueType = TypeDescription;
	
	If DisplayCharacteristics
		And TypeOf(AdditionalAttributeSets) = Type("Array")
		And AdditionalAttributeSets.Count() > 0 Then
		LayoutParameter = CompositionSchema.Parameters.Add();
		LayoutParameter.Name = "AdditionalAttributeSets";
		LayoutParameter.Use = DataCompositionParameterUse.Always;
		LayoutParameter.Value = AdditionalAttributeSets;
		LayoutParameter.ValueListAllowed = True;
	EndIf;
	
	Return CompositionSchema;
	
EndFunction

// Returns an empty table describing the characteristics of the metadata. Repeats columns of corresponding properties in the metadata.
// 
// Returns:
// 	ValueTable - table of description of characteristics in metadata:
// 	  * CharacteristicTypes - MetadataObject - (types of characteristics) the object of the source of the types of characteristics.
// 	  * KeyField - MetadataObject - (types of characteristics) field of the key of the source of characteristics.
//    * TypesFilterField - MetadataObject, Undefined - (types of characteristics) the field of selection of the source of characteristics.
// 				Undefined - the default value if the selection is not specified in the metadata.
//    * TypesFilterValue - Undefined, AnyRef, Boolean, Number, String, Date - the value of the selection.
//    * CharacteristicValues - MetadataObject - (characteristic values) the object of the source of characteristic values.
// 	  * ObjectField - MetadataObject - (characteristic values) the field of the object that the characteristics belong to.
// 	  * TypeField - MetadataObject - (characteristic values) the field that contains the type of characteristic.
// 	  * ValueField - MetadataObject - (characteristic values) the field that contains the characteristic value.
//
Function TableOfPropertiesCharacteristicsByMetadata()
	TableOfPropertiesCharacteristics = New ValueTable();
	// Columns describing the types of characteristics.
	TableOfPropertiesCharacteristics.Columns.Add("CharacteristicTypes");
	TableOfPropertiesCharacteristics.Columns.Add("KeyField");
	TableOfPropertiesCharacteristics.Columns.Add("TypesFilterField");
	TableOfPropertiesCharacteristics.Columns.Add("TypesFilterValue");
	
	// Columns describing the values of characteristics.
	TableOfPropertiesCharacteristics.Columns.Add("CharacteristicValues");
	TableOfPropertiesCharacteristics.Columns.Add("ObjectField");
	TableOfPropertiesCharacteristics.Columns.Add("TypeField");
	TableOfPropertiesCharacteristics.Columns.Add("ValueField");
	
	Return TableOfPropertiesCharacteristics;
EndFunction

// Fills in the correspondence of the used sources of characteristics
// 
// Parameters:
// 	UsedSourcesOfCharacteristics - Map of KeyAndValue - matching the metadata of the source of characteristics and the description table of properties of characteristics by metadata:
// 	  * Key - MetadataObject - the metadata object of the characteristics source, for example, Metadata.The plan of the species characteristics.Additional inquisitionsreferences
// 	  * Value - See TableOfPropertiesCharacteristicsByMetadata
// 	MetadataObjectsList - MetadataObjectCatalog - the metadata object of the operand tree field containing characteristics, for example, Metadata.Catalogs.Organizations.
// 	         - MetadataObjectDocument - the metadata object of the operand tree field.
// 	         - MetadataObjectExchangePlan - the metadata object of the operand tree field.
// 	         - MetadataObjectChartOfCharacteristicTypes - the metadata object of the operand tree field.
// 	         - MetadataObjectChartOfAccounts - the metadata object of the operand tree field.
// 	         - MetadataObjectChartOfCalculationTypes - the metadata object of the operand tree field.
// 	         - MetadataObjectBusinessProcess - the metadata object of the operand tree field.
// 	         - MetadataObjectTask - the metadata object of the operand tree field.
// 	PropertiesOfCharacteristicSources - See ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources
// 	SelectionBasedOnMetadataOfCharacteristicsSource - Undefined, MetadataObject - Empty selection value based on the metadata of the feature source.
// 				If the metadata object is specified , the value of selection based on the metadata of the characteristics source. For Example, Metadata.Guides.Types of contact information.
//
Procedure FillInUsedSourcesOfCharacteristics(UsedSourcesOfCharacteristics, MetadataObjectsList, PropertiesOfCharacteristicSources,
				SelectionBasedOnMetadataOfCharacteristicsSource = Undefined)
	
	For Each CharacteristicsDescription In MetadataObjectsList.Characteristics Do
		If CharacteristicsDescription.KeyField = Undefined
				Or CharacteristicsDescription.ObjectField = Undefined
				Or CharacteristicsDescription.TypeField = Undefined
				Or CharacteristicsDescription.CharacteristicTypes = Undefined
				Or CharacteristicsDescription.CharacteristicValues = Undefined Then
				// Erroneous filling in of characteristics.
			Continue;
		EndIf;
		KeyField = CharacteristicsDescription.KeyField.Name;
		SourcesOfCharacteristics = CharacteristicsDescription.CharacteristicTypes;
		CharacteristicSourcesField = SourcesOfCharacteristics.Attributes.Find(KeyField);
		If CharacteristicSourcesField = Undefined Then
			CharacteristicSourcesField = SourcesOfCharacteristics.StandardAttributes[KeyField];
		EndIf;
		If CharacteristicSourcesField = Undefined Then
			If StrFind(Upper(CharacteristicsDescription.CharacteristicTypes.FullName()), Upper(".TabularSection.")) > 0
				And Upper(KeyField) = "REF" Then
				OwnerOfTS = CharacteristicsDescription.CharacteristicTypes.Parent(); // MetadataObjectCatalog - 
				CharacteristicSourcesField = OwnerOfTS.StandardAttributes[KeyField];
			EndIf;
		EndIf;
		TypesOfFeatureSources = CharacteristicSourcesField.Type.Types();
		For Each TypeOfCharacteristicsSource In TypesOfFeatureSources Do
			MDOfSourceOfCharacteristics = Metadata.FindByType(TypeOfCharacteristicsSource);
			
			SourceProperties = PropertiesOfCharacteristicSources.Find(MDOfSourceOfCharacteristics, "SourceMetadata");
			If SourceProperties = Undefined Then
				// Not an available source of characteristics.
				Continue;
			EndIf;
			If Not SelectionBasedOnMetadataOfCharacteristicsSource = Undefined
				And MDOfSourceOfCharacteristics <> SelectionBasedOnMetadataOfCharacteristicsSource Then
				Continue;
			EndIf;
			
			CharacteristicsDescriptions = UsedSourcesOfCharacteristics.Get(MDOfSourceOfCharacteristics);
			If CharacteristicsDescriptions = Undefined Then
				CharacteristicsDescriptions = TableOfPropertiesCharacteristicsByMetadata();
			EndIf;
			CharacteristicDescriptionString = CharacteristicsDescriptions.Add();
			FillPropertyValues(CharacteristicDescriptionString, CharacteristicsDescription);
			UsedSourcesOfCharacteristics.Insert(MDOfSourceOfCharacteristics, CharacteristicsDescriptions);
		EndDo;
	EndDo;
	
EndProcedure

// Returns the text of a subquery of sources of the characteristics type
// 
// Parameters:
// 	SourceProperties - ValueTableRow - Description of properties of the type of characteristics.
// 	DescriptionOfCharacteristicsInMetadata - ValueTableRow - Row of the table of descriptions of characteristics by metadata. Table Constructor See TableOfPropertiesCharacteristicsByMetadata.
// 	AdditionalAttributeSets - Array of CatalogRef.AdditionalAttributesAndInfoSets - Additional selection based on sets of additional details and information.
// 	Set of additional requests-Undefined - default Value.
// 	ForDCS - Boolean - Flag for composing the request text for the SKD.
// Returns:
// 	String - The text of the subquery.
Function SubqueryTextForSourcesAndTypesOfCharacteristics(SourceProperties, DescriptionOfCharacteristicsInMetadata, AdditionalAttributeSets = Undefined, ForDCS = False)
	
	MDOfSourceOfCharacteristics = SourceProperties.SourceMetadata;
	TableOfTypesOfCharacteristics = ProcessingOfFormulasCached.FullNameOfDataTable(MDOfSourceOfCharacteristics.FullName());
	
	KeyField = DescriptionOfCharacteristicsInMetadata.KeyField; // MetadataObjectField - 
	
	If DescriptionOfCharacteristicsInMetadata.CharacteristicTypes = MDOfSourceOfCharacteristics Then
		
		SubqueryText =
		"SELECT
		|	&IdFieldExpression AS Id,
		|	&NameFieldExpression AS Name,
		|	&ValueTypeExpression AS ValueType
		|FROM
		|	&SourceTypesOfCharacteristics AS TableOfTypesOfCharacteristics
		|WHERE
		|	&ConditionsForSelectingTypesOfCharacteristics";
		
	Else
		
		SubqueryText =
		"SELECT
		|	&IdFieldExpression AS Id,
		|	&NameFieldExpression AS Name,
		|	&ValueTypeExpression AS ValueType
		|FROM
		|	&SourceTypesOfCharacteristics AS SourceTable1
		|INNER JOIN
		|	#TableOfTypesOfCharacteristics AS TableOfTypesOfCharacteristics
		|ON
		|	&ConnectionCondition
		|WHERE
		|	&ConditionsForSelectingTypesOfCharacteristics";
		
		ConnectionCondition = StringFunctionsClientServer.SubstituteParametersToString(
		"SourceTable1.%1 = TableOfTypesOfCharacteristics.Ref",
		KeyField.Name);
		
		SubqueryText = StrReplace(SubqueryText, "#TableOfTypesOfCharacteristics", TableOfTypesOfCharacteristics);
		SubqueryText = StrReplace(SubqueryText, "&ConnectionCondition", ConnectionCondition);
		
	EndIf;
	
	SourceTypesOfCharacteristics = ProcessingOfFormulasCached.FullNameOfDataTable(
		DescriptionOfCharacteristicsInMetadata.CharacteristicTypes.FullName());
	
	If DescriptionOfCharacteristicsInMetadata.CharacteristicTypes = MDOfSourceOfCharacteristics Then
		
		IdFieldExpression = "TableOfTypesOfCharacteristics."
			+ KeyField.Name;
		
	Else
		
		IdFieldExpression = "SourceTable1."
			+ KeyField.Name;
		
	EndIf;
	
	NameFieldExpression = ExpressionOfFullFeatureID(MDOfSourceOfCharacteristics, ForDCS);
	NameFieldExpression = StrReplace(NameFieldExpression, "%TableName%", "TableOfTypesOfCharacteristics");
	
	If SourceProperties.ValueTypeExpressionIsUsed Then
		ValueTypeExpression = SourceProperties.ExpressionTypeOfValue;
	Else
		ValueTypeExpression = "TableOfTypesOfCharacteristics."
			+ SourceProperties.FieldTypeOfValues;
	EndIf;
	
	ConditionsForSelectingTypesOfCharacteristics = "";
	If DescriptionOfCharacteristicsInMetadata.TypesFilterField <> Undefined Then
		
		ConditionsForSelectingTypesOfCharacteristics = ConditionForSelectingCharacteristicsBasedOnMetadataData(DescriptionOfCharacteristicsInMetadata,
			MDOfSourceOfCharacteristics,
			"SourceTable1",
			"TableOfTypesOfCharacteristics");
		
		ExpressionOfAdditionalSelection = "";
		If MDOfSourceOfCharacteristics = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo Then
			If TypeOf(AdditionalAttributeSets) = Type("Array")
				And AdditionalAttributeSets.Count() > 0 Then
				// The expression of additional selections of the source of characteristics should contain only conditions for the fields of the table of types of characteristics,
				// since additional conditions are set on the metadata object of the types of characteristics.
				ExpressionOfAdditionalSelection =
				"TableOfTypesOfCharacteristics.Ref In
				|	(&ExpressionForSelectingAdditionalBankingDetails)";
				TemplateForSelectingAdditionalBankingDetails =
				"SELECT
				|	PropertySetsComposition.Property AS Property
				|FROM
				|	&SetsTable AS PropertySetsComposition
				|WHERE
				|	PropertySetsComposition.Ref IN (&AdditionalAttributeSets)";
				If DescriptionOfCharacteristicsInMetadata.CharacteristicTypes = Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalAttributes Then
					SampleExpression = StrReplace(TemplateForSelectingAdditionalBankingDetails,
						"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes");
				ElsIf DescriptionOfCharacteristicsInMetadata.CharacteristicTypes = Metadata.Catalogs.AdditionalAttributesAndInfoSets.TabularSections.AdditionalInfo Then
					SampleExpression = StrReplace(TemplateForSelectingAdditionalBankingDetails,
						"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
				Else
					SampleExpression = StrReplace(TemplateForSelectingAdditionalBankingDetails,
						"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes")
						+ "
						|
						|UNION ALL
						|
						|"
						+ StrReplace(TemplateForSelectingAdditionalBankingDetails,
						"&SetsTable", "Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
				EndIf;
				ExpressionOfAdditionalSelection = StrReplace(ExpressionOfAdditionalSelection, "&ExpressionForSelectingAdditionalBankingDetails", SampleExpression);
			EndIf;
		EndIf;
		If ConditionsForSelectingTypesOfCharacteristics <> ""
			And ExpressionOfAdditionalSelection <> "" Then
			ConditionsForSelectingTypesOfCharacteristics = StringFunctionsClientServer.SubstituteParametersToString(
			"%1 AND %2",
			ConditionsForSelectingTypesOfCharacteristics,
			ExpressionOfAdditionalSelection);
		ElsIf ConditionsForSelectingTypesOfCharacteristics = ""
			And ExpressionOfAdditionalSelection <> "" Then
			ConditionsForSelectingTypesOfCharacteristics = ExpressionOfAdditionalSelection;
		EndIf;
	EndIf;
	ConditionsForSelectingTypesOfCharacteristics = ConditionsForSelectingTypesOfCharacteristics + ?(ConditionsForSelectingTypesOfCharacteristics = "", "", " " + "And" + " ")
		+ StringFunctionsClientServer.SubstituteParametersToString("(TableOfTypesOfCharacteristics.%1 <> """")",
			SourceProperties.IdField_);
	
	SubqueryText = StrReplace(SubqueryText, "&IdFieldExpression", IdFieldExpression);
	SubqueryText = StrReplace(SubqueryText, "&NameFieldExpression", NameFieldExpression);
	SubqueryText = StrReplace(SubqueryText, "&ValueTypeExpression", ValueTypeExpression);
	SubqueryText = StrReplace(SubqueryText, "&SourceTypesOfCharacteristics", SourceTypesOfCharacteristics);
	SubqueryText = StrReplace(SubqueryText, "&ConditionsForSelectingTypesOfCharacteristics", ConditionsForSelectingTypesOfCharacteristics);
	
	Return SubqueryText;
	
EndFunction

// Returns the text of the condition based on the description of characteristics specified in the metadata.
// 
// Parameters:
// 	DescriptionOfCharacteristicsInMetadata - ValueTableRow - Row of the table of descriptions of characteristics by metadata. Table Constructor See TableOfPropertiesCharacteristicsByMetadata:
// 	 * CharacteristicTypes - MetadataObjectCatalog - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectDocument - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectExchangePlan - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectChartOfCharacteristicTypes - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectChartOfCalculationTypes - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectBusinessProcess - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectTask - (types of characteristics) the object of the source of the types of characteristics.
// 	 * CharacteristicTypes - MetadataObjectTabularSection - (types of characteristics) the object of the source of the types of characteristics.
// 	 * KeyField - MetadataObject - (types of characteristics) field of the key of the source of characteristics.
// 	 * TypesFilterField - MetadataObjectField - (types of characteristics) the field of selection of the source of characteristics.
// 	 * TypesFilterField - Undefined - the default value if the selection is not specified in the metadata.
// 	 * TypesFilterValue - Undefined, AnyRef, Boolean, Number, String, Date - the value of the selection.
// 	 * CharacteristicValues - MetadataObject - (characteristic values) the object of the source of characteristic values.
// 	 * ObjectField - MetadataObject - (characteristic values) the field of the object that the characteristics belong to.
// 	 * TypeField - MetadataObject - (characteristic values) the field that contains the type of characteristic.
// 	 * ValueField - MetadataObject - (characteristic values) the field that contains the characteristic value.
// 	MDTypesOfCharacteristics - MetadataObjectCatalog - Metadata of types of characteristics. For Example, The Plan Of Species Characteristics.Additional information requirements.
// 	Mdvidovcharacteristic-Objectmetadannyhdocument-Metadata of types of characteristics.
// 	Mdvidovcharacteristic-Objectmetadannyhplanobmen-Metadata of types of characteristics.
// 	Mdvidovcharacteristic-Objectmetadannyplanvidovcharacteristic-Metadata of types of characteristics.
// 	Mdvidovcharacteristic-Objectmetadannyhplanschetov-Metadata of types of characteristics.
// 	Mdvidovcharacteristic-Objectmetadannyplanvidovrascheta-Metadata of types of characteristics.
// 	Mdvidovcharacteristic-Objectmetadannyhbiznesprocess-Metadata of types of characteristics.
// 	Mdvidovcharacteristic-Objectmetadannyhtask - Metadata of types of characteristics.
// 	TableName_Source - String - Name of the table that the condition is specified for, if the source table has characteristics as specified in the metadata
// 					(for example, Metadata.Guides.A set of additional requisitesreferences.Additional requirements)
// 					DOES not match the table of the characteristic type itself (for example, Metadata.Playvideopokeronline.Additional information requirements).
// 	NameOfCharacteristicTypesTable - String - Name of the table that the condition is specified for, if the source table has characteristics as specified in the metadata
// 					(for example, Metadata.Guides.A set of additional requisitesreferences.Additional requirements)
// 					matches the table of the characteristic type itself (for example, Metadata.Playvideopokeronline.Additional information requirements).
//
// Returns:
// 	String - The text of the condition according to the description of the characteristics specified in the metadata.
//
Function ConditionForSelectingCharacteristicsBasedOnMetadataData(DescriptionOfCharacteristicsInMetadata, MDTypesOfCharacteristics, TableName_Source, NameOfCharacteristicTypesTable)
	ConditionsForSelectingTypesOfCharacteristics = "";
	
	If DescriptionOfCharacteristicsInMetadata.TypesFilterField <> Undefined Then
		
		TypesFilterField = DescriptionOfCharacteristicsInMetadata.TypesFilterField; // MetadataObjectField - 
		ExpressionOfComparisonForm = "";
		ValueExpression = "";
		
		TypesFilterValue = DescriptionOfCharacteristicsInMetadata.TypesFilterValue;
		TypeOfSpeciesSelectionValue = TypeOf(TypesFilterValue);
		If Common.IsReference(TypeOfSpeciesSelectionValue) Then
			MetadataKind = TypesFilterValue.Metadata();
			ExpressionOfComparisonForm = "=";
			ValueExpression = "VALUE(%1)";
			ValueExpression = StringFunctionsClientServer.SubstituteParametersToString(
				ValueExpression,
				ProcessingOfFormulasCached.FullNameOfDataTable(MetadataKind.FullName())
					+ "." + TypesFilterValue.PredefinedDataName);
		Else
			ExpressionOfComparisonForm = "=";
			If TypeOfSpeciesSelectionValue = Type("String") Then
				ValueExpression = StringFunctionsClientServer.SubstituteParametersToString(
					"""%1""",
					TypesFilterValue);
			ElsIf TypeOfSpeciesSelectionValue = Type("Boolean") Then
				ValueExpression = ?(TypesFilterValue, "TRUE", "FALSE");
			ElsIf TypeOfSpeciesSelectionValue = Type("Date") Then
				ValueExpression = StringFunctionsClientServer.SubstituteParametersToString(
					"DATETIME(%1,%2,%3,%4,%5,%6)",
					Year(TypesFilterValue),
					Month(TypesFilterValue),
					Day(TypesFilterValue),
					Hour(TypesFilterValue),
					Minute(TypesFilterValue),
					Second(TypesFilterValue));
			Else
				ValueExpression = "UNDEFINED";
			EndIf;
		EndIf;
		If DescriptionOfCharacteristicsInMetadata.CharacteristicTypes = MDTypesOfCharacteristics Then
			ConditionsForSelectingTypesOfCharacteristics = StringFunctionsClientServer.SubstituteParametersToString(
				"&TableOfTypesOfCharacteristics.%1 %2 %3",
				TypesFilterField.Name,
				ExpressionOfComparisonForm,
				ValueExpression);
			ConditionsForSelectingTypesOfCharacteristics = StrReplace(ConditionsForSelectingTypesOfCharacteristics, "&TableOfTypesOfCharacteristics", NameOfCharacteristicTypesTable);
		Else
			ConditionsForSelectingTypesOfCharacteristics = StringFunctionsClientServer.SubstituteParametersToString(
				"&SourceTable1.%1 %2 %3",
				TypesFilterField.Name,
				ExpressionOfComparisonForm,
				ValueExpression);
			ConditionsForSelectingTypesOfCharacteristics = StrReplace(ConditionsForSelectingTypesOfCharacteristics, "&SourceTable1", TableName_Source);
		EndIf;
	EndIf;
	
	
	Return ConditionsForSelectingTypesOfCharacteristics;
	
EndFunction

// Returns the text of the subquery for sources of characteristic values.
// 
// Parameters:
// 	CharacteristicsDescription - ValueTableRow - Row of the table of descriptions of characteristics by metadata. Table Constructor See TableOfPropertiesCharacteristicsByMetadata:
//
// Returns:
// 	String - The text of the subquery of the sources of characteristic values.
//
Function SubqueryTextForFeatureValueSources(CharacteristicsDescription)
	SubqueryText =
	"SELECT
	|	&ObjectFieldExpression AS Ref,
	|	&FieldExpressionOfForm AS Property,
	|	&ValueFieldExpression AS Value
	|FROM
	|	&SourceOfFeatureValues AS TableOfCharacteristicValues";
	
	ObjectField = CharacteristicsDescription.ObjectField; // MetadataObjectField - 
	TypeField = CharacteristicsDescription.TypeField; // MetadataObjectField -
	ValueField = CharacteristicsDescription.ValueField; // MetadataObjectField -
	
	SourceOfFeatureValues = ProcessingOfFormulasCached.FullNameOfDataTable(
		CharacteristicsDescription.CharacteristicValues.FullName());
	ObjectFieldExpression = "TableOfCharacteristicValues." + ObjectField.Name;
	FieldExpressionOfForm = "TableOfCharacteristicValues." + TypeField.Name;
	If CharacteristicsDescription.ValueField = Undefined Then
		ValueFieldExpression = "UNDEFINED";
	Else
		ValueFieldExpression = "TableOfCharacteristicValues." + ValueField.Name;
	EndIf;
	
	SubqueryText = StrReplace(SubqueryText, "&SourceOfFeatureValues", SourceOfFeatureValues);
	SubqueryText = StrReplace(SubqueryText, "&ObjectFieldExpression", ObjectFieldExpression);
	SubqueryText = StrReplace(SubqueryText, "&FieldExpressionOfForm", FieldExpressionOfForm);
	SubqueryText = StrReplace(SubqueryText, "&ValueFieldExpression", ValueFieldExpression);
	
	Return SubqueryText;
	
EndFunction

Function FullNameOfDataTable(MetadataObject) Export
	
	If TypeOf(MetadataObject) = Type("String") Then
		MetadataObject = Metadata.FindByFullName(MetadataObject);
	EndIf;
	
	If Common.IsCatalog(MetadataObject) Then
		Result = "Catalog." + MetadataObject.Name;
	ElsIf Common.IsDocument(MetadataObject) Then
		Result = "Document." + MetadataObject.Name;
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObject) Then
		Result = "ChartOfCharacteristicTypes." + MetadataObject.Name;
	ElsIf Common.IsInformationRegister(MetadataObject) Then
		Result = "InformationRegister." + MetadataObject.Name;
	ElsIf Common.IsChartOfAccounts(MetadataObject) Then
		Result = "ChartOfAccounts." + MetadataObject.Name;
	ElsIf Common.IsChartOfCalculationTypes(MetadataObject) Then
		Result = "ChartOfCalculationTypes." + MetadataObject.Name;
	ElsIf Common.IsExchangePlan(MetadataObject) Then
		Result = "ExchangePlan." + MetadataObject.Name;
	ElsIf Common.IsBusinessProcess(MetadataObject) Then
		Result = "BusinessProcess." + MetadataObject.Name;
	ElsIf Common.IsTask(MetadataObject) Then
		Result = "Task." + MetadataObject.Name;
	Else
		// The tabular part.
		ParentMDObject = MetadataObject.Parent();
		Result = FullNameOfDataTable(ParentMDObject)
			+ "." + MetadataObject.Name;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region WorkingWithOperandTree

// Complements the array of expanded groups with groups that are part of the pathname of the layout field (if the groups are specified).
// 
// Parameters:
// 	DCSFieldGroupsToExpand - Array of String - Lists the groups that need to be expanded immediately
// 			when adding fields according to the layout scheme.
// 	FieldDataPath - String - The data path of the layout field.
Procedure CheckAdditionOfExpandedDCSFieldGroups(DCSFieldGroupsToExpand, FieldDataPath)
	If StrFind(FieldDataPath, ".") > 0 Then
		// The field is included in the group.
		GroupsAndFields = StrSplit(FieldDataPath, ".", False);
		GroupsAndFields.Delete(GroupsAndFields.Count() - 1);
		GroupsOnly = StrConcat(GroupsAndFields, ".");
		If DCSFieldGroupsToExpand.Find(GroupsOnly) = Undefined Then
			DCSFieldGroupsToExpand.Add(GroupsOnly);
		EndIf;
	EndIf;
EndProcedure

Function SortedListOfLayoutFields(ElementsOfAvailableLayoutFields, ParametersForAddingLine, FieldsWithRestrictedBankingDetails = Undefined)
	
	DescriptionOfIDType = New TypeDescription("String",, New StringQualifiers(1000, AllowedLength.Variable));
	FeatureIds = New Map;
	PropertiesOfCharacteristicSources = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	
	TypesOfCharacteristicsWithRedefinitionOfValueType = ParametersForAddingLine.TypesOfCharacteristicsWithRedefinitionOfValueType;
	// Quick search for the desired list item when refilling the view and marking the deletion of the list of fields.
	ElementsOfListOfAdditionalCharacteristics = New Map;
	
	List = New ValueList();
	
	NamesOfPredefinedDCSGroups = New Array;
	NamesOfPredefinedDCSGroups.Add("SystemFields");
	NamesOfPredefinedDCSGroups.Add("DataParameters");
	
	For Each AvailableLayoutField In ElementsOfAvailableLayoutFields Do
		
		If AvailableLayoutField.Folder
			And Not AvailableLayoutField.Table
			And NamesOfPredefinedDCSGroups.Find(String(AvailableLayoutField.Field)) <> Undefined Then
			Continue;
		EndIf;
		// The tabular parts are not output.
		If AvailableLayoutField.Table Then
			Continue;
		EndIf;

		FieldID = RowIdOfLayoutField(AvailableLayoutField, ParametersForAddingLine);
		
		ValueOfListItem = New Structure;
		ValueOfListItem.Insert("Field", AvailableLayoutField);
		ValueOfListItem.Insert("DeletionMark", False);
		ValueOfListItem.Insert("ValueType", AvailableLayoutField.ValueType); // It may be redefined below for characteristics.
		
		ValueOfListItem.Insert("ThisIsCharacteristic", False);
		ValueOfListItem.Insert("IsFolder", False);
		ValueOfListItem.Insert("ThisIsTable", False);
		
		If AvailableLayoutField.Folder Then
			ValueOfListItem.IsFolder = True;
		EndIf;
		If AvailableLayoutField.Table Then
			ValueOfListItem.ThisIsTable = True;
		EndIf;
		If StrFind(FieldID, "{") > 0 Then
			ValueOfListItem.ThisIsCharacteristic = True;
		EndIf;
		
		// Additional influence on the element type and the tree element icon
		ValueOfListItem.Insert("IsAdditionalAttribute", False);
		ValueOfListItem.Insert("IsAdditionalInfo", False);
		ValueOfListItem.Insert("ThisIsKindOfContactInformation", False);
		ValueOfListItem.Insert("ContactInformationType", Undefined);
		
		ValueOfListItem.Insert("MetadataOfCharacteristicsType", Undefined);
		
		ValueOfListItem.Insert("RestrictingAvailabilityOfBankingDetails", False);
		If FieldsWithRestrictedBankingDetails <> Undefined
			And FieldsWithRestrictedBankingDetails.Find(FieldID) <> Undefined Then
			ValueOfListItem.RestrictingAvailabilityOfBankingDetails = True;
		EndIf;
		
		ListItem = List.Add(ValueOfListItem, "");
		
		IDWithoutBrackets = StrReplace(FieldID, "[", "");
		IDWithoutBrackets = StrReplace(IDWithoutBrackets, "]", "");
		
		IDWithoutBrackets = StrReplace(IDWithoutBrackets, "{", "");
		IDWithoutBrackets = StrReplace(IDWithoutBrackets, "}", "");
		If StrFind(FieldID, "{") > 0 Then
			For Each CharacteristicsSourceProperties In PropertiesOfCharacteristicSources Do
				PropertyTypePrefix = CharacteristicsSourceProperties.PropertyTypePrefix;
				If StrFind(IDWithoutBrackets, PropertyTypePrefix) = 1 Then
					MetadataCharacteristics_ = CharacteristicsSourceProperties.SourceMetadata;
					ListItem.Value.MetadataOfCharacteristicsType = MetadataCharacteristics_;
					RedefiningTypeDescription = TypesOfCharacteristicsWithRedefinitionOfValueType.Get(MetadataCharacteristics_);
					If Not RedefiningTypeDescription = Undefined Then
						ListItem.Value.ValueType = RedefiningTypeDescription;
					EndIf;
					
					IDWithoutSourceType = Mid(IDWithoutBrackets, StrLen(PropertyTypePrefix) + 1);
					IDsTable = FeatureIds.Get(PropertyTypePrefix);
					If IDsTable = Undefined Then
						IDsTable = New ValueTable;
						IDsTable.Columns.Add("FieldID", DescriptionOfIDType);
						IDsTable.Columns.Add("NameFieldValue", DescriptionOfIDType);
					EndIf;
					Id_String = IDsTable.Add();
					Id_String.FieldID = FieldID;
					Id_String.NameFieldValue = IDWithoutSourceType;
					
					FeatureIds.Insert(PropertyTypePrefix, IDsTable);
					
					ElementsOfListOfAdditionalCharacteristics.Insert(FieldID, ListItem);
					Break;
				EndIf;
			EndDo;
		Else
			FieldPresentation = String(AvailableLayoutField.Title);
			If Not IsBlankString(ParametersForAddingLine.PresentationPrefixToRemove) Then
				PrefixToDelete = ParametersForAddingLine.PresentationPrefixToRemove + ".";
				PrefixLength = StrLen(PrefixToDelete);
				If Left(FieldPresentation, PrefixLength) = PrefixToDelete Then
					FieldPresentation = Mid(FieldPresentation, PrefixLength + 1);
				EndIf;
			EndIf;
			ListItem.Presentation = FieldPresentation;
		EndIf;
		
	EndDo;
	
	// Refilling the view and marking the deletion of the list of fields.
	For Each SourceTypeAndIdentifiers In FeatureIds Do
		
		PropertyTypePrefix = SourceTypeAndIdentifiers.Key;
		IDsTable       = SourceTypeAndIdentifiers.Value;
		CharacteristicsSourceProperties = PropertiesOfCharacteristicSources.Find(PropertyTypePrefix, "PropertyTypePrefix");
		DBTable = ProcessingOfFormulasCached.FullNameOfDataTable(
			CharacteristicsSourceProperties.SourceMetadata.FullName());
		
		Query = New Query;
		Text =
		"SELECT
		|	FeatureIds.FieldID AS FieldID,
		|	FeatureIds.NameFieldValue AS NameFieldValue
		|INTO FeatureIds
		|FROM
		|	&FeatureIds AS FeatureIds
		|;
		|
		|SELECT
		|	FeatureIds.FieldID AS FieldID,
		|	FeatureIds.NameFieldValue AS NameFieldValue,
		|	TableOfTypesOfCharacteristics.Ref AS Ref,
		|	ISNULL(TableOfTypesOfCharacteristics.DeletionMark, FALSE) AS DeletionMark,
		|	&ExpressionIsExtraProp AS IsAdditionalAttribute,
		|	&ExpressionIsAdditionalInformation AS IsAdditionalInfo,
		|	&ExpressionIsKindOfContactInformation AS ThisIsKindOfContactInformation,
		|	&ExpressionTypeOfContactInformation AS ContactInformationType,
		|	CASE
		|		WHEN NOT TableOfTypesOfCharacteristics.Ref IS NULL
		|			THEN PRESENTATION(TableOfTypesOfCharacteristics.Ref)
		|		ELSE """"
		|	END AS CharacteristicPresentation
		|FROM
		|	FeatureIds AS FeatureIds
		|LEFT JOIN
		|	#NameOfCharacteristicsSourceTable AS TableOfTypesOfCharacteristics
		|ON
		|	&TableJoinExpression";
		
		TableJoinExpression = StringFunctionsClientServer.SubstituteParametersToString(
			"FeatureIds.NameFieldValue = TableOfTypesOfCharacteristics.%1",
			CharacteristicsSourceProperties.IdField_);
		If CharacteristicsSourceProperties.SourceMetadata = Metadata.Catalogs.ContactInformationKinds Then
			ExpressionTypeOfContactInformation = "TableOfTypesOfCharacteristics.Type";
			ExpressionIsKindOfContactInformation = "TRUE";
		Else
			ExpressionTypeOfContactInformation = "UNDEFINED";
			ExpressionIsKindOfContactInformation = "FALSE";
		EndIf;
		If CharacteristicsSourceProperties.SourceMetadata = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo Then
			ExpressionIsExtraProp = "NOT TableOfTypesOfCharacteristics.IsAdditionalInfo";
			ExpressionIsAdditionalInformation = "TableOfTypesOfCharacteristics.IsAdditionalInfo";
		Else
			ExpressionIsExtraProp = "FALSE";
			ExpressionIsAdditionalInformation = "FALSE";
		EndIf;
		
		If Not CharacteristicsSourceProperties.UniquenessOfNameWithinEntireCharacteristicsTable Then
			// Since there can be two or more characteristics with this identifier in the characteristics table (for example,
			// in the types of contact information, the "Phone" identifier can be specified for a set of Organizations / Contractors, etc.),
			// it is necessary to limit the number of selected characteristics by the type of value of the parent field, using
			// the selection specified in the metadata for characteristics.
			// Also, in this case, it is necessary to specify the totals for the field identifier field in order to analyze
			// the differences in the selected fields (representation of the characteristics - the minimum value will be taken, as for the usual requisites,
			// The deletion mark is the maximum value, the type of contact information is undefined if there are different ones).
			
			Text = Text + "
			|WHERE
			|	&ExpressionOfFeatureSelectionByParentValueType
			|TOTALS BY
			|	FieldID";
			
			ParentFieldValueType = ParametersForAddingLine.ParentFieldValueType;
			SelectionExpression = ExpressionOfFeatureSelectionByParentValueType(ParentFieldValueType,
				CharacteristicsSourceProperties, PropertiesOfCharacteristicSources);
			Text = StrReplace(Text, "&ExpressionOfFeatureSelectionByParentValueType", SelectionExpression);
		EndIf;
		
		Text = StrReplace(Text, "#NameOfCharacteristicsSourceTable", DBTable);
		Text = StrReplace(Text, "&TableJoinExpression", TableJoinExpression);
		Text = StrReplace(Text, "&ExpressionIsExtraProp", ExpressionIsExtraProp);
		Text = StrReplace(Text, "&ExpressionIsAdditionalInformation", ExpressionIsAdditionalInformation);
		Text = StrReplace(Text, "&ExpressionIsKindOfContactInformation", ExpressionIsKindOfContactInformation);
		Text = StrReplace(Text, "&ExpressionTypeOfContactInformation", ExpressionTypeOfContactInformation);
		
		Query.Text = Text;
		Query.SetParameter("FeatureIds", IDsTable);
		
		If CharacteristicsSourceProperties.UniquenessOfNameWithinEntireCharacteristicsTable Then
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ListItem = ElementsOfListOfAdditionalCharacteristics.Get(Selection.FieldID);
				ValueOfListItem = ListItem.Value;
				ValueOfListItem.DeletionMark = Selection.DeletionMark;
				ValueOfListItem.IsAdditionalAttribute = Selection.IsAdditionalAttribute;
				ValueOfListItem.IsAdditionalInfo = Selection.IsAdditionalInfo;
				ValueOfListItem.ThisIsKindOfContactInformation = Selection.ThisIsKindOfContactInformation;
				ValueOfListItem.ContactInformationType = Selection.ContactInformationType;

				ListItem.Value = ValueOfListItem;
				ListItem.Presentation = Selection.CharacteristicPresentation;
			EndDo;
		Else
			SelectionFieldID = Query.Execute().Select(QueryResultIteration.ByGroups, "FieldID");
			While SelectionFieldID.Next() Do
				ListItem = ElementsOfListOfAdditionalCharacteristics.Get(SelectionFieldID.FieldID);
				ValueOfListItem = ListItem.Value;
				
				Presentation = "";
				DeletionMark = False;
				IsAdditionalAttribute = False;
				IsAdditionalInfo = False;
				ThisIsKindOfContactInformation = False;
				ContactInformationType = Undefined;
				ThereAreDifferentTypesOfContactInformation = False;
				Selection = SelectionFieldID.Select();
				While Selection.Next() Do
					Presentation = ?(Presentation = "", Selection.CharacteristicPresentation, Min(Presentation, Selection.CharacteristicPresentation));
					DeletionMark = Max(DeletionMark, Selection.DeletionMark);
					If Not ThereAreDifferentTypesOfContactInformation Then
						ContactInformationType = ?(ContactInformationType = Undefined, Selection.ContactInformationType, ContactInformationType);
						ThereAreDifferentTypesOfContactInformation = (ContactInformationType <> Selection.ContactInformationType);
					EndIf;
					If ThereAreDifferentTypesOfContactInformation Then
						ContactInformationType = Undefined;
					EndIf;
					IsAdditionalAttribute = Max(IsAdditionalAttribute, Selection.IsAdditionalAttribute);
					IsAdditionalInfo = Max(IsAdditionalInfo, Selection.IsAdditionalInfo);
					ThisIsKindOfContactInformation = Max(ThisIsKindOfContactInformation, Selection.ThisIsKindOfContactInformation);
				EndDo;
				
				ValueOfListItem.DeletionMark = DeletionMark;
				ValueOfListItem.IsAdditionalAttribute = IsAdditionalAttribute;
				ValueOfListItem.IsAdditionalInfo = IsAdditionalInfo;
				ValueOfListItem.ThisIsKindOfContactInformation = ThisIsKindOfContactInformation;
				ValueOfListItem.ContactInformationType = ContactInformationType;

				ListItem.Value = ValueOfListItem;
				ListItem.Presentation = Presentation;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	List.SortByPresentation();
	
	Return List;
	
EndFunction

Function MetadataObjectByValueType(ValueType)
	MetadataObjectsList = Undefined;
	If Common.IsReference(ValueType) Then
		MetadataObjectsList = Metadata.FindByType(ValueType);
	EndIf;
	
	Return MetadataObjectsList;
EndFunction


Function MetadataObjectKind(MetadataObjectsList, ToSpecifyType = False)
	MdObjectType = Undefined;
	If Common.IsCatalog(MetadataObjectsList) Then
		MdObjectType = "Catalog";
	ElsIf Common.IsDocument(MetadataObjectsList) Then
		MdObjectType = "Document";
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObjectsList) Then
		MdObjectType = "ChartOfCharacteristicTypes";
	ElsIf Common.IsChartOfAccounts(MetadataObjectsList) Then
		MdObjectType = "ChartOfAccounts";
	ElsIf Common.IsChartOfCalculationTypes(MetadataObjectsList) Then
		MdObjectType = "ChartOfCalculationTypes";
	ElsIf Common.IsExchangePlan(MetadataObjectsList) Then
		MdObjectType = "ExchangePlan";
	ElsIf Common.IsBusinessProcess(MetadataObjectsList) Then
		MdObjectType = "BusinessProcess";
	ElsIf Common.IsTask(MetadataObjectsList) Then
		MdObjectType = "Task";
	EndIf;
	// The enumeration has no details, so no value is specified for it.
	If ToSpecifyType And Not MdObjectType = Undefined Then
		MdObjectType = MdObjectType + "Ref";
	EndIf;
	
	Return MdObjectType;
EndFunction

Function ExpressionOfFeatureSelectionByParentValueType(ParentFieldValueType, CharacteristicsSourceProperties, PropertiesOfCharacteristicSources)
	SelectionExpression = "";
	
	If ParentFieldValueType = Undefined Then
		SelectionExpression = "FALSE";
	Else
		SourceMetadata = CharacteristicsSourceProperties.SourceMetadata;
		ParentFieldTypes = ParentFieldValueType.Types();
		
		UsedSourcesOfCharacteristics = New Map();
		For Each ValueType In ParentFieldTypes Do
			MetadataObjectsList = MetadataObjectByValueType(ValueType);
			If MetadataObjectsList = Undefined Then
				Continue;
			EndIf;
			MdObjectType = MetadataObjectKind(MetadataObjectsList);
			If MdObjectType = Undefined Then
				// The transfer has no details
				Continue;
			EndIf;
			
			FillInUsedSourcesOfCharacteristics(UsedSourcesOfCharacteristics,
				MetadataObjectsList,
				PropertiesOfCharacteristicSources,
				SourceMetadata);
		EndDo;
		
		TableOfPropertiesCharacteristicsByMetadata = UsedSourcesOfCharacteristics.Get(SourceMetadata);
		If TableOfPropertiesCharacteristicsByMetadata = Undefined
			Or TableOfPropertiesCharacteristicsByMetadata.Count() = 0 Then
			SelectionExpression = "FALSE";
		Else
			// For fields of composite type, there may be identical rows in the table. To optimize the condition expression, the table is collapsed.
			// An expression of the form WHERE The link is IN (SELECT the values of the selections of the metadannym1 COMBINE ALL the values of the selections of the Metadannym2) is compiled
			ConvolutionColumns = "CharacteristicTypes, KeyField, TypesFilterField, TypesFilterValue";
			TableOfPropertiesCharacteristicsByMetadata.GroupBy(ConvolutionColumns);
			PartsOfExpression = New Array;
			SelectionTemplate1 =
			"SELECT
			|	SourceTable1.Ref
			|FROM
			|	&SourceTypesOfCharacteristics AS SourceTable1
			|WHERE
			|	&ConditionsForSelectingTypesOfCharacteristics";
			For Each DescriptionOfCharacteristicsInMetadata In TableOfPropertiesCharacteristicsByMetadata Do
				SampleExpression = SelectionTemplate1;
				SourceTypesOfCharacteristics = ProcessingOfFormulasCached.FullNameOfDataTable(
					DescriptionOfCharacteristicsInMetadata.CharacteristicTypes.FullName());
				ConditionsForSelectingTypesOfCharacteristics = ConditionForSelectingCharacteristicsBasedOnMetadataData(DescriptionOfCharacteristicsInMetadata,
					SourceMetadata, "SourceTable1", "SourceTable1");
				
				If ConditionsForSelectingTypesOfCharacteristics = "" Then
					ConditionsForSelectingTypesOfCharacteristics = "TRUE";
				EndIf;
				SampleExpression = StrReplace(SampleExpression, "&SourceTypesOfCharacteristics", SourceTypesOfCharacteristics);
				SampleExpression = StrReplace(SampleExpression, "&ConditionsForSelectingTypesOfCharacteristics", ConditionsForSelectingTypesOfCharacteristics);
				
				PartsOfExpression.Add(SampleExpression);
			EndDo;
			
			Separator = "
			|
			|UNION ALL
			|
			|";
			CombiningSamples = StrConcat(PartsOfExpression, Separator);
			SelectionExpression = StringFunctionsClientServer.SubstituteParametersToString(
				"TableOfTypesOfCharacteristics.Ref IN (%1)", CombiningSamples);
		EndIf;
	EndIf;
	
	Return SelectionExpression;
EndFunction


// Calculates the current row level in the tree based on row groups.
// 
// Parameters:
// 	TreeItem - ValueTreeRow, FormDataTreeItem, ValueTree, FormDataTree - The element of wood, which we need to calculate.
// 	ItemsTypes - See ProcessingOfFormulas.TypesOfOperandTreeElements
// 	
// Returns:
// 	Number - LongDesc
Function CurLevelOfRecursionOfProps(TreeItem, ItemsTypes)
	If TypeOf(TreeItem) = Type("ValueTree")
	 Or TypeOf(TreeItem) = Type("FormDataTree") Then
		CurrentLevel = 0;
	ElsIf TypeOf(TreeItem) = Type("ValueTreeRow") Then
		CurrentLevel = 0;
		ParentRow = TreeItem.Parent;
		While Not ParentRow = Undefined Do
			If Not ParentRow.TreeItemType = ItemsTypes.Group
				And Not ParentRow.TreeItemType = ItemsTypes.TopLevelRowGroup Then
				CurrentLevel = CurrentLevel + 1;
			EndIf;
			ParentRow = ParentRow.GetParent();
		EndDo;
	ElsIf TypeOf(TreeItem) = Type("FormDataTreeItem") Then
		CurrentLevel = 0;
		ParentRow = TreeItem.GetParent();
		While Not ParentRow = Undefined Do
			If Not ParentRow.TreeItemType = ItemsTypes.Group
				And Not ParentRow.TreeItemType = ItemsTypes.TopLevelRowGroup Then
				CurrentLevel = CurrentLevel + 1;
			EndIf;
			ParentRow = ParentRow.GetParent();
		EndDo;
	EndIf;
	Return CurrentLevel;
EndFunction

Function NewTreeLineByLayoutField(FieldListElement, PlaceAdded, ParametersForAddingLine, SweepRestrictions = Undefined)
	
	AvailableField = FieldListElement.Value.Field;
	StringValueType = FieldListElement.Value.ValueType; // type, taking into account possible redefinition.
	DeletionMark = FieldListElement.Value.DeletionMark;
	IsFolder = FieldListElement.Value.IsFolder;
	ThisIsTable = FieldListElement.Value.ThisIsTable;
	ThisIsCharacteristic = FieldListElement.Value.ThisIsCharacteristic;
	IsAdditionalAttribute = FieldListElement.Value.IsAdditionalAttribute;
	IsAdditionalInfo = FieldListElement.Value.IsAdditionalInfo;
	ThisIsKindOfContactInformation = FieldListElement.Value.ThisIsKindOfContactInformation;
	ContactInformationType = FieldListElement.Value.ContactInformationType;
	RestrictingAvailabilityOfBankingDetails = FieldListElement.Value.RestrictingAvailabilityOfBankingDetails;
	DCSFieldGroupsToExpand = ParametersForAddingLine.DCSFieldGroupsToExpand;
	AddingFieldsAccordingToLayoutScheme = ParametersForAddingLine.AddingFieldsAccordingToLayoutScheme;
	
	If TypeOf(PlaceAdded) = Type("ValueTree")
		Or TypeOf(PlaceAdded) = Type("ValueTreeRow") Then
		PlaceOfAdditionOnForm = False;
	Else
		PlaceOfAdditionOnForm = True;
	EndIf;
	
	ItemsTypes = TypesOfOperandTreeElements();
	
	IDOfNewLine = RowIdOfLayoutField(AvailableField, ParametersForAddingLine);
	FieldPresentation = FieldListElement.Presentation;
	
	OutputString_1 = True;
	
	FieldTypes = StringValueType.Types();
	If FieldTypes.Count() = 1
		And FieldTypes[0] = Type("ValueStorage") Then
		OutputString_1 = False;
	EndIf;
	
	If Not IsBlankString(ParametersForAddingLine.IDPrefixToAdd) Then
		FullRowID = ParametersForAddingLine.IDPrefixToAdd
			+ "." + IDOfNewLine;
	Else
		FullRowID = IDOfNewLine;
	EndIf;
	If Not IsBlankString(ParametersForAddingLine.PresentationPrefixToAdd) Then
		FullRowPresentation = ParametersForAddingLine.PresentationPrefixToAdd
			+ "." + FieldPresentation;
	Else
		FullRowPresentation = FieldPresentation;
	EndIf;
	
	If OutputString_1
		And Not SweepRestrictions = Undefined Then
		If Not SweepRestrictions.DisplayBankingDetails
			And Not ThisIsCharacteristic
			And Not ThisIsTable Then
			OutputString_1 = False;
		EndIf;
		If OutputString_1
			And SweepRestrictions.MaximumRowExpansionLevel > 0 Then
			CurrentLevel = CurLevelOfRecursionOfProps(PlaceAdded, ItemsTypes) + 1;
			If CurrentLevel > SweepRestrictions.MaximumRowExpansionLevel Then
				OutputString_1 = False;
			EndIf;
		EndIf;
		If AddingFieldsAccordingToLayoutScheme Then
			IDToCheck = FullRowID;
		Else
			IDToCheck = IDOfNewLine;
		EndIf;
		If OutputString_1
			And Not IsBlankString(SweepRestrictions.OutputAttributes)
			And Not ThisIsCharacteristic Then
			ArrayOfOutputDetails = StrSplit(SweepRestrictions.OutputAttributes, ",", False);
			If ArrayOfOutputDetails.Find(IDToCheck) = Undefined Then
				OutputString_1 = False;
			EndIf;
		EndIf;
		If OutputString_1
			And Not IsBlankString(SweepRestrictions.NotOutputAttributes)
			And Not ThisIsCharacteristic Then
			ArrayOfNonOutputDetails = StrSplit(SweepRestrictions.NotOutputAttributes, ",", False);
			If ArrayOfNonOutputDetails.Find(IDToCheck) <> Undefined Then
				OutputString_1 = False;
			EndIf;
		EndIf;
	EndIf;
	If Not OutputString_1 Then
		Return Undefined;
	EndIf;
	
	If Not PlaceOfAdditionOnForm Then
		OperandString_ = PlaceAdded.Rows.Add();
	Else
		OperandString_ = PlaceAdded.GetItems().Add();
	EndIf;
	
	OperandString_.Id = IDOfNewLine;
	OperandString_.Presentation = FieldPresentation;
	
	If ThisIsTable Then
		OperandString_.TreeItemType = "TabularSection";
	ElsIf IsFolder Then
		OperandString_.TreeItemType = ItemsTypes.Group;
	ElsIf IsAdditionalAttribute Then
		OperandString_.TreeItemType = ItemsTypes.AdditionalAttribute;
	ElsIf IsAdditionalInfo Then
		OperandString_.TreeItemType = ItemsTypes.AdditionalInfoItem;
	ElsIf ThisIsKindOfContactInformation Then
		If ContactInformationType = Enums.ContactInformationTypes.Address Then
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_Address;
		ElsIf ContactInformationType = Enums.ContactInformationTypes.Phone Then
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_Phone;
		ElsIf ContactInformationType = Enums.ContactInformationTypes.Skype Then
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_Skype;
		ElsIf ContactInformationType = Enums.ContactInformationTypes.Email Then
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_EmailAddress;
		ElsIf ContactInformationType = Enums.ContactInformationTypes.WebPage Then
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_WebPage;
		ElsIf ContactInformationType = Enums.ContactInformationTypes.Fax Then
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_Fax;
		ElsIf ContactInformationType = Enums.ContactInformationTypes.Other Then 
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_Other;
		Else
			OperandString_.TreeItemType = ItemsTypes.TypeOfContactInformation_MultipleTypesOfContactInformation;
		EndIf;
	ElsIf ThisIsCharacteristic Then
		OperandString_.TreeItemType = ItemsTypes.OtherCharacteristics;
	Else
		OperandString_.TreeItemType = ItemsTypes.Attribute;
	EndIf;
	
	If PlaceOfAdditionOnForm Then
		OperandString_.FullRowID = FullRowID;
		OperandString_.FullRowPresentation = FullRowPresentation;
		OperandString_.PictureCode = StringEncodingOfOperandTree(OperandString_, ItemsTypes);
	EndIf;
	
	OperandString_.ValueType = StringValueType;
	If IsFolder Or ThisIsTable Then
		OperandString_.OperandSelectionAllowed = False;
	Else
		OperandString_.OperandSelectionAllowed = True;
	EndIf;
	OperandString_.DeletionMark = DeletionMark;
	OperandString_.IncludedInID = True;
	
	ExpandToAttributes = False;
	If ParametersForAddingLine.RecursivelyExpandLayoutSchemeOperands
		And Not RestrictingAvailabilityOfBankingDetails Then
		If ThisIsTable Then
			ExpandToAttributes = True;
		Else
			Types = OperandString_.ValueType.Types();
			For Each FieldType In Types Do
				MDObjectFound = Metadata.FindByType(FieldType);
				If MDObjectFound <> Undefined Then
					If Not Metadata.Enums.Contains(MDObjectFound) Then
						ExpandToAttributes = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If Not SweepRestrictions = Undefined
		And SweepRestrictions.MaximumRowExpansionLevel > 0 Then
		CurrentLevel = CurLevelOfRecursionOfProps(PlaceAdded, ItemsTypes) + 1;
		If CurrentLevel = SweepRestrictions.MaximumRowExpansionLevel Then
			ExpandToAttributes = False;
		EndIf;
	EndIf;
	OperandString_.ExpandToAttributes = ExpandToAttributes;
	
	If PlaceOfAdditionOnForm Then
		// The operand tree on the form has an expanded composition of columns, including the service
		// details of the subordinate rows, which is responsible for the need to add
		// subordinate rows recursively by the data type of the parent row (the parent row
		// on the form has a subordinate service row).
		PlaceAdded.SubordinateRowsExpanded = True;
	EndIf;
	
	ExpandingFieldWhenAddingFieldsAccordingToLayoutScheme = False;
	If Not IsFolder
		And DCSFieldGroupsToExpand.Count() <> 0
		And OperandString_.ExpandToAttributes
		And Not PlaceOfAdditionOnForm Then
		If DCSFieldGroupsToExpand.Find(FullRowID) <> Undefined Then
			ExpandingFieldWhenAddingFieldsAccordingToLayoutScheme = True;
		EndIf;
	EndIf;
	If IsFolder Or ExpandingFieldWhenAddingFieldsAccordingToLayoutScheme Then
		
		NewOptionsForAddingLine = Common.CopyRecursive(ParametersForAddingLine);
		NewOptionsForAddingLine.IDPrefixToDelete = String(AvailableField.Field);
		NewOptionsForAddingLine.PresentationPrefixToRemove  = String(AvailableField.Title);
		
		If PlaceOfAdditionOnForm Then
			// The operand tree on the form has an expanded composition of columns.
			NewOptionsForAddingLine.IDPrefixToAdd = OperandString_.FullRowID;
			NewOptionsForAddingLine.PresentationPrefixToAdd  = OperandString_.FullRowPresentation;
		Else
			NewOptionsForAddingLine.IDPrefixToAdd = FullRowID;
			NewOptionsForAddingLine.PresentationPrefixToAdd  = FullRowPresentation;
		EndIf;
		
		FieldList = SortedListOfLayoutFields(AvailableField.Items, NewOptionsForAddingLine);
		For Each ListItem In FieldList Do
				
			NewTreeLineByLayoutField(ListItem, OperandString_, NewOptionsForAddingLine, SweepRestrictions);
			
		EndDo;
		
	ElsIf OperandString_.ExpandToAttributes Then
		
		If PlaceOfAdditionOnForm Then
			// The operand tree on the form has an expanded composition of columns, including the service
			// details of the subordinate service line. If the current operand string has a reference type
			// and must be expanded, then a service string is added as a subordinate string
			// so that a plus icon appears, clicking on which the user can expand the current operand string.
			// The list of subordinate details will be obtained during interactive deployment.
			ServiceLine = OperandString_.GetItems().Add();
			ServiceLine.SubordinateRowInternal = True;
		EndIf;
	EndIf;

	Return OperandString_;
	
EndFunction

Function RowIdOfLayoutField(LayoutField, ParametersForAddingLine)
	
	IDPrefixToDelete = ParametersForAddingLine.IDPrefixToDelete;
	IDOfNewLine = String(LayoutField.Field);
	If Not IsBlankString(IDPrefixToDelete) Then
		PrefixToDelete = IDPrefixToDelete + ".";
		PrefixLength = StrLen(PrefixToDelete);
		If Left(IDOfNewLine, PrefixLength) = PrefixToDelete Then
			IDOfNewLine = Mid(IDOfNewLine, PrefixLength + 1);
		EndIf;
	EndIf;
	
	// The platform adds brackets [] to fields that do not meet the requirements for variables, and at the end of ]].
	While StrFind(IDOfNewLine, "[[") > 0 Do 
		IDOfNewLine = StrReplace(IDOfNewLine, "[[", "[");
	EndDo;
	While StrFind(IDOfNewLine, "]]") > 0 Do 
		IDOfNewLine = StrReplace(IDOfNewLine, "]]", "]");
	EndDo;
	
	// In DCS, curly brackets are replaced with square
	// brackets (see the description of the method for expressing a complete identifier of the characteristic).
	If StrFind(IDOfNewLine, "[") > 0
		And StrFind(IDOfNewLine, "]") > 0 Then
		IDOfNewLine = StrReplace(IDOfNewLine, "[", "{");
		IDOfNewLine = StrReplace(IDOfNewLine, "]", "}");
	EndIf;
	
	Return IDOfNewLine;
	
EndFunction


// Loads rows of the operand tree into the form tree recursively.
// 
// Parameters:
// 	Tree forms-dataform Tree-A tree on the form that loads the value tree initialized by the developer.
// 	                                  Has service columns that are not present in the tree Operands, they are filled in in this method.
// 	Tree operands-tree Values-a value tree Initialized by the developer. See GetEmptyOperandTree.
// 	OperandValues - Undefined - The default value. The correspondence of operands and their values is not filled in.
// 	                    Matching - Matching operands and their values:
// 	                       * Key - String - ID of the operand.
// 	                       * Value - Number - the value of the operand.
Procedure LoadOperandTreeStrings(PlaceAdded, Val StringSource_, ArrayOfAllowedOperands = Undefined,
			OperandValues = Undefined)
	
	CollectionOfFormTreeElements = PlaceAdded.GetItems(); // FormDataTreeItemCollection
	OperandTreeStrings = StringSource_.Rows;
	TypesOfTreeElements = TypesOfOperandTreeElements();
	
	For Each OperandTreeString In OperandTreeStrings Do
		
		NewRowOfFormTree = CollectionOfFormTreeElements.Add();
		FillPropertyValues(NewRowOfFormTree, OperandTreeString);
		
		NewRowOfFormTree.PictureCode = StringEncodingOfOperandTree(NewRowOfFormTree, TypesOfTreeElements);
		If TypeOf(PlaceAdded) = Type("FormDataTree") Then
			If NewRowOfFormTree.IncludedInID Then
				NewRowOfFormTree.FullRowID = NewRowOfFormTree.Id;
			EndIf;
			NewRowOfFormTree.FullRowPresentation = NewRowOfFormTree.Presentation;
		Else // Placeholders are a tree string.
			If PlaceAdded.IncludedInID Then
				NewRowOfFormTree.FullRowID = PlaceAdded.FullRowID
					+ "." + NewRowOfFormTree.Id;
			Else
				NewRowOfFormTree.FullRowID = NewRowOfFormTree.Id;
			EndIf;
			NewRowOfFormTree.FullRowPresentation = PlaceAdded.FullRowPresentation
				+ "." + NewRowOfFormTree.Presentation;
		EndIf;
		If OperandTreeString.Rows.Count() = 0 Then
			NewRowOfFormTree.SubordinateRowsExpanded = False;
			
			If NewRowOfFormTree.ExpandToAttributes Then
				NewServiceLine = NewRowOfFormTree.GetItems().Add();
				NewServiceLine.SubordinateRowInternal = True;
			EndIf;
		Else
			NewRowOfFormTree.SubordinateRowsExpanded = True;
			
			LoadOperandTreeStrings(NewRowOfFormTree,
				OperandTreeString,
				ArrayOfAllowedOperands,
				OperandValues);
		EndIf;
		
		If Not ArrayOfAllowedOperands = Undefined
			And OperandTreeString.OperandSelectionAllowed Then
			ArrayOfAllowedOperands.Add(NewRowOfFormTree.FullRowID);
			
			If TypeOf(PlaceAdded) = Type("FormDataTreeItem")
				And Not PlaceAdded.IncludedInID
				And NewRowOfFormTree.ExpandToAttributes Then
				// If the identifier of the added row consists of several parts
				// that are not parts of the higher-level rows, and if the added row
				// If it is expanded to the requisites, then we add the first part of the operand
				// to the array of allowed ones in order to control
				// the lower lines of the added string expanded to the requisites.
				PartsOfCurOperand = ProcessingOfFormulasClientServer.OperandParts(
					NewRowOfFormTree.FullRowID);
				If PartsOfCurOperand.Count() > 1 Then
					If ArrayOfAllowedOperands.Find(PartsOfCurOperand[0]) = Undefined Then
						ArrayOfAllowedOperands.Add(PartsOfCurOperand[0]);
						ArrayOfAllowedOperands.Add(PartsOfCurOperand[0] + ".");
					EndIf;
				EndIf;
			EndIf;
			
			If NewRowOfFormTree.ExpandToAttributes
				And Not NewRowOfFormTree.SubordinateRowsExpanded Then
				ArrayOfAllowedOperands.Add(NewRowOfFormTree.FullRowID + ".");
			EndIf;
		EndIf;
		If Not OperandValues = Undefined
			And NewRowOfFormTree.ContainsValue Then
			OperandValues.Insert(NewRowOfFormTree.FullRowID, NewRowOfFormTree.Value);
		EndIf;
		
	EndDo;
EndProcedure

Function StringEncodingOfOperandTree(TreeRow, TypesOfTreeElements)
	
	PictureCode = 10;
	If TreeRow.TreeItemType = TypesOfTreeElements.Operand Then
		If TreeRow.DeletionMark Then
			PictureCode = 11;
		Else
			PictureCode = 10;
		EndIf;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.Attribute Then
		PictureCode = 10;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TopLevelRowGroup Then
		PictureCode = 8;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.Group Then
		PictureCode = 9;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.AdditionalAttribute Then
		If TreeRow.DeletionMark Then
			PictureCode = 14;
		Else
			PictureCode = 12;
		EndIf;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.AdditionalInfoItem Then
		If TreeRow.DeletionMark Then
			PictureCode = 15;
		Else
			PictureCode = 13;
		EndIf;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_Skype Then
		PictureCode = 7;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_Address Then
		PictureCode = 6;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_EmailAddress Then
		PictureCode = 2;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_WebPage Then
		PictureCode = 3;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_Other Then
		PictureCode = 5;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_MultipleTypesOfContactInformation Then
		PictureCode = 5;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_Phone Then
		PictureCode = 1;
	ElsIf TreeRow.TreeItemType = TypesOfTreeElements.TypeOfContactInformation_Fax Then
		PictureCode = 4;
	Else
		PictureCode = 10;
	EndIf;
	Return PictureCode;
EndFunction

// Returns a template of parameters for adding a row by layout field.
// If you add rows to the form, the tree has an expanded set of columns
// compared to the tree preparation stage.
//
// Returns:
//  Structure - Structure of parameters with properties:
//   *IDPrefixToAdd - String - The default value is "". Will be added before the layout field ID
//   					to get the full row ID. For example, the line "Item.Counterparty",
//   					then the prefix "Nomenclature" is added for the counterparty's INN field.Contractor".
//   *PresentationPrefixToAdd - String - The default value is "". The same as adding a prefix Identifier,
//   					but to get a complete view.
//   *IDPrefixToDelete - String - The default value is "". Used when you need
//   					to delete part of the ID string to the left of the layout field name to get the full ID of the string
//   					(when recursively expanding a string, you need to delete the name of the top-level props,
//   					for example, the service ID "Props").
//   *PresentationPrefixToRemove - String - The default value is "". The same as deleting the identifier Prefix,
//   					but to get a complete view.
//   *MaximumRowExpansionLevel - Number - The default value is 0. the Maximum level of C when adding tree rows
//   					according to the line-up settings. If 0, the level is not controlled (any).
//   *RecursivelyExpandLayoutSchemeOperands - Boolean - a parameter that determines whether
//   					strings in the operand tree can be recursively expanded.
//   *ParentFieldValueType - Undefined, TypeDescription - If there is a parent string and its value type is described. Used
//   					for setting additional selection based on characteristics that are not guaranteed
//   					to be unique within the entire table of characteristics (for example, types of contact information).
//   *TypesOfCharacteristicsWithRedefinitionOfValueType - Map - contains metadata of the characteristic type and
//   					the type description assigned to it, if a value type override is specified
//   					(used if the value type is calculated by an expression, i.e.
//   					the metadata of the characteristic type is not a plan of characteristic types, since
//   					the type expression in the query returns just the type (not a specific one)).
//   *DCSFieldGroupsToExpand - Array of String - It is filled in only in the addtranslatedtranslatedpolyposchem Components method.
//   					In the data layout scheme, some fields can be included in other fields (data Path, and these can be
//   					group fields or fields of ordinary details). When adding rows of the operand tree according to the layout scheme, such fields
//   					must be expanded immediately, because when lines are expanded interactively, the programmatically created layout scheme
//   					does not know anything about the existence of additional fields in the interactively expanded field, since they are defined
//   					only in the original layout scheme.
//   *AddingFieldsAccordingToLayoutScheme - Boolean - Flag for adding fields according to the layout scheme. If True, the fields are added
//						according to the layout scheme passed to the method, including fields in groups. Then, if you set restrictions on the names
//						of output fields, you need to get the full field ID when checking.
//
Function OptionsForAddingRowByLayoutField()
	
	Result = New Structure;
	
	// Prefixes to be added to get the full identifier and string representation (including the higher-level strings).
	Result.Insert("IDPrefixToAdd", "");
	Result.Insert("PresentationPrefixToAdd", "");
	
	// The prefixes to be deleted to get the identifier and representation at the current nesting level.
	// This can be the identifier (representation) of the parent line or the service name of the "Props" field
	// specified in the layout scheme when recursively retrieving nested fields.
	Result.Insert("IDPrefixToDelete", "");
	Result.Insert("PresentationPrefixToRemove", "");
	
	// Limiting the maximum recursion level for the entire operand tree. 0 - do not limit.
	Result.Insert("MaximumRowExpansionLevel", 0);
	
	// Flag of the need to recursively expand reference operands.
	Result.Insert("RecursivelyExpandLayoutSchemeOperands", True);
	
	Result.Insert("ParentFieldValueType", Undefined);
	
	TypesOfCharacteristicsWithRedefinitionOfValueType = New Map;
	PropertiesOfAllCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	For Each PropertiesCharacteristics In PropertiesOfAllCharacteristics Do
		If PropertiesCharacteristics.ValueTypeExpressionIsUsed
			And TypeOf(PropertiesCharacteristics.OverridingValueTypeExpression) = Type("TypeDescription") Then
			TypesOfCharacteristicsWithRedefinitionOfValueType.Insert(PropertiesCharacteristics.SourceMetadata,
				PropertiesCharacteristics.OverridingValueTypeExpression);
		EndIf;
	EndDo;
	Result.Insert("TypesOfCharacteristicsWithRedefinitionOfValueType", TypesOfCharacteristicsWithRedefinitionOfValueType);
	
	Result.Insert("DCSFieldGroupsToExpand", New Array);
	
	Result.Insert("AddingFieldsAccordingToLayoutScheme", False);
	
	Return Result;
EndFunction


#EndRegion

#Region WorkingWithOperatorTree

// Adds a group of standard operators to the operator tree (+,-,*,/)
//
// Parameters:
//  Tree - ValueTree - the operator tree. see the function Get a list of operators().
//
Procedure AddGroupOfStandardOperators(Tree)

	PresentationOfOperatorGroup = NStr("vi = 'Toán tử';
										|ru = 'Операторы';
										|en = 'Operators'; fa = 'عملگرها';
										|it = 'Operatori';
										|pl = 'Operatory';
										|tr = 'Operatörler'");
	OperatorsGroup = AddOperatorsGroup(Tree, "Operators", PresentationOfOperatorGroup);
	
	AddOperator(OperatorsGroup, "+", " + ", "+");
	AddOperator(OperatorsGroup, "-", " - ", "-");
	AddOperator(OperatorsGroup, "*", " * ", "*");
	AddOperator(OperatorsGroup, "/", " / ", "/");

EndProcedure

// Adds a group of logical operators to the operator tree
//
// Parameters:
//  Tree - ValueTree - the operator tree. see the function Get a list of operators().
//
Procedure AddGroupOfLogicalOperators(Tree)

	PresentationOfOperatorGroup = NStr("vi = 'Toán tử lô-gic và hằng';
										|ru = 'Логические операторы и константы';
										|en = 'Logical operators and constants'; fa = 'Logical operators and constants';
										|it = 'Operatori logici e costanti';
										|pl = 'Operatory logiczne i konstanty';
										|tr = 'Mantıksal operatörler ve sabitler'");
	OperatorsGroup = AddOperatorsGroup(Tree, "LogicalOperatorsAndConstants", PresentationOfOperatorGroup);
	
	AddOperator(OperatorsGroup, "<", " < ", "<");
	AddOperator(OperatorsGroup, ">", " > ", ">");
	AddOperator(OperatorsGroup, "<=", " <= ", "<=");
	AddOperator(OperatorsGroup, ">=", " >= ", ">=");
	AddOperator(OperatorsGroup, "=", " = ", "=");
	AddOperator(OperatorsGroup, "<>", " <> ", "<>");
	
	OperatorID = "And";
	OperatorPresentation = NStr("vi = 'VÀ';
								|ru = 'И';
								|en = 'AND'; fa = 'و';
								|it = 'E';
								|pl = 'ORAZ';
								|tr = 'AND'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "OR";
	OperatorPresentation = NStr("vi = 'HOẶC';
								|ru = 'ИЛИ';
								|en = 'OR'; fa = 'یا';
								|it = 'OPPURE';
								|pl = 'LUB';
								|tr = 'OR'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "NOT";
	OperatorPresentation = NStr("vi = 'KHÔNG';
								|ru = 'НЕ';
								|en = 'NOT'; fa = 'NOT';
								|it = 'NON';
								|pl = 'NIE';
								|tr = 'NOT'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "TRUE";
	OperatorPresentation = NStr("vi = 'TRUE';
								|ru = 'ИСТИНА';
								|en = 'TRUE'; fa = 'TRUE';
								|it = 'VERO';
								|pl = 'PRAWDA';
								|tr = 'TRUE'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);
	
	OperatorID = "FALSE";
	OperatorPresentation = NStr("vi = 'FALSE';
								|ru = 'ЛОЖЬ';
								|en = 'FALSE'; fa = 'FALSE';
								|it = 'FALSO';
								|pl = 'FAŁSZ';
								|tr = 'FALSE'");
	OperatorInCodeLanguageForInsertion = " " + OperatorID + " ";
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation);

EndProcedure

// Adds a group of functions to the operator tree
//
// Parameters:
//  Tree - ValueTree - the operator tree. see the function Get a list of operators().
//
Procedure AddFunctionGroup(Tree)

	PresentationOfOperatorGroup = NStr("vi = 'Hàm';
										|ru = 'Функции';
										|en = 'Functions'; fa = 'توابع';
										|it = 'Funzioni';
										|pl = 'Funkcje';
										|tr = 'Fonksiyonlar'");
	OperatorsGroup = AddOperatorsGroup(Tree, "Functions", PresentationOfOperatorGroup);
	
	
	OperatorID = "Max";
	OperatorPresentation = NStr("vi = 'Tối đa';
								|ru = 'Максимум';
								|en = 'Maximum'; fa = 'حداکثر';
								|it = 'Massimo';
								|pl = 'Maksimum';
								|tr = 'Maksimum'");
	OperatorInCodeLanguageForInsertion = "Max(,)";
	ExplanationOfOperator = NStr("vi = 'Trả về giá trị lớn nhất từ các giá trị đã chuyển';
								|ru = 'Возвращает максимальное значение из переданных значений';
								|en = 'Returns the maximum value of the passed values'; fa = 'Returns the maximum value of the passed values';
								|it = 'Riporta il valore massimo dei valori trasmessi';
								|pl = 'Zwraca maksymalną wartość z przekazanych wartości';
								|tr = 'Aktarılan değerlerden maksimum değeri döndürür'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator,
		2);
	
	OperatorID = "Min";
	OperatorPresentation = NStr("vi = 'Tối thiểu';
								|ru = 'Минимум';
								|en = 'Minimum'; fa = 'حداقل';
								|it = 'Minimo';
								|pl = 'Minimum';
								|tr = 'Minimum'");
	OperatorInCodeLanguageForInsertion = "Min(,)";
	ExplanationOfOperator = NStr("vi = 'Trả về giá trị nhỏ nhất từ các giá trị đã truyền';
								|ru = 'Возвращает минимальное значение из переданных значений';
								|en = 'Returns the minimum value of the passed values'; fa = 'Returns the minimum value of the passed values';
								|it = 'Riporta il valore minimo dei valori trasmessi';
								|pl = 'Zwraca minimalną wartość z przekazanych wartości';
								|tr = 'Aktarılan değerlerden minimum değeri döndürür'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator,
		2);
	
	OperatorID = "Round";
	OperatorPresentation = NStr("vi = 'Làm tròn';
								|ru = 'Округление';
								|en = 'Rounding'; fa = 'Rounding';
								|it = 'Arrotondamento';
								|pl = 'Zaokrąglenie';
								|tr = 'Yuvarlama'");
	TextRoundedValue = NStr("vi = '<Giá trị làm tròn>';
							|ru = '<Округляемое значение>';
							|en = '<Round value>'; fa = '<Round value>';
							|it = '<Valore da arrotondare>';
							|pl = '<Wartość zaokrąglana>';
							|tr = '<Yuvarlanmış değer>'");
	TextNumberOfCharacters = NStr("vi = '<Ký tự sau dấu phẩy>';
									|ru = '<Знаков после запятой>';
									|en = '<Decimal places>'; fa = '<Decimal places>';
									|it = '<Caratteri dopo la virgola>';
									|pl = '<Znaków po przecinku>';
									|tr = '<Ondalık basamak>'");
	OperatorInCodeLanguageForInsertion = StringFunctionsClientServer.SubstituteParametersToString(
		"Round(%1,%2)",
		TextRoundedValue,
		TextNumberOfCharacters);
	ExplanationOfOperator            = NStr("vi = 'Làm tròn giá trị chuyển đổi';
											|ru = 'Округляет переданное значение';
											|en = 'Rounds the passed value'; fa = 'Rounds the passed value';
											|it = 'Arrotonda il valore trasmesso';
											|pl = 'Zaokrągla przekazywaną wartość';
											|tr = 'Aktarılan değeri yuvarlar'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator,
		2);
	
	OperatorID = "Int";
	OperatorPresentation = NStr("vi = 'Phần nguyên';
								|ru = 'Целая часть';
								|en = 'Integral part'; fa = 'بخش صحیح';
								|it = 'Parte intera';
								|pl = 'Cała część';
								|tr = 'Tam sayı kısmı'");
	OperatorInCodeLanguageForInsertion = "Int()";
	ExplanationOfOperator = NStr("vi = 'Trả về phần nguyên của số đã chuyển';
								|ru = 'Возвращает целую часть переданного числа';
								|en = 'Returns the integer part of the passed number'; fa = 'Returns the integer part of the passed number';
								|it = 'Riporta la parte intera del numero trasmesso';
								|pl = 'Zwraca całą część przekazanej liczby';
								|tr = 'Aktarılan sayının tam sayı kısmını geri döndürür'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator,
		1);
	
	OperatorID = "?";
	OperatorPresentation = NStr("vi = 'Điều kiện';
								|ru = 'Условие';
								|en = 'Condition'; fa = 'شرط';
								|it = 'Condizione';
								|pl = 'Warunek';
								|tr = 'Şart'");
	TextCondition = NStr("vi = '<Điều kiện>';
						|ru = '<Условие>';
						|en = '<Condition>'; fa = '<Condition>';
						|it = '<Condizione>';
						|pl = '<Warunek>';
						|tr = '<Koşul>'");
	TextMeaningTrue = NStr("vi = '<Giá trị nếu đúng>';
							|ru = '<Значение если истина>';
							|en = '<Value if true>'; fa = '<Value if true>';
							|it = '<Valore se vero>';
							|pl = '<Wartość jeśli prawda>';
							|tr = '<Doğru ise değer>'");
	TextMeaningFalse = NStr("vi = '<Giá trị nếu sai>';
							|ru = '<Значение если ложь>';
							|en = '<Value if false>'; fa = '<Value if false>';
							|it = '<Valore se falso>';
							|pl = '<Wartość jeśli fałsz>';
							|tr = '<Yanlış ise değer>'");
	OperatorInCodeLanguageForInsertion = StringFunctionsClientServer.SubstituteParametersToString(
		"?(%1, %2, %3)",
		TextCondition,
		TextMeaningTrue,
		TextMeaningFalse);
	ExplanationOfOperator = NStr("vi = 'Tính toán giá trị phụ thuộc vào giá trị điều kiện';
								|ru = 'Вычисляет значение в зависимости от значения условия';
								|en = 'Calculates a value based on a condition value'; fa = 'Calculates a value based on a condition value';
								|it = 'Calcola il valore in relazione al valore della condizione';
								|pl = 'Oblicza wartość w zależności od wartości warunku';
								|tr = 'Şartın değerine bağlı olarak değeri hesaplar'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator,
		3);
	
	OperatorID = "PredefinedValue";
	OperatorPresentation = NStr("vi = 'Giá trị định trước';
								|ru = 'Предопределенное значение';
								|en = 'Predefined value'; fa = 'Predefined value';
								|it = 'Valore predefinito';
								|pl = 'Wartość predefiniowana';
								|tr = 'Önceden tanımlanmış değer'");
	OperatorInCodeLanguageForInsertion = "PredefinedValue()";
	ExplanationOfOperator = NStr("vi = 'Tham chiếu đến phần tử định trước theo tên của nó';
								|ru = 'Обращение к предопределенному элементу по его имени';
								|en = 'Accesses a predefined item by its name'; fa = 'Accesses a predefined item by its name';
								|it = 'Accesso all''elemento predefinito per nome';
								|pl = 'Odwołanie do predefiniowanego elementu wg jego nazwy';
								|tr = 'Önceden tanımlanmış bir öğeye adıyla başvurma'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator);
	
	OperatorID = "ValueIsFilled";
	OperatorPresentation = NStr("vi = 'Đã điền giá trị';
								|ru = 'Значение заполнено';
								|en = 'Value filled'; fa = 'Value filled';
								|it = 'Valore compilato';
								|pl = 'Wartość wypełniona';
								|tr = 'Değer dolduruldu'");
	OperatorInCodeLanguageForInsertion = "ValueIsFilled()";
	ExplanationOfOperator = NStr("vi = 'Kiểm tra điền giá trị';
								|ru = 'Проверка заполненности значения';
								|en = 'Checking whether the value is filled'; fa = 'Checking whether the value is filled';
								|it = 'Controllo della compilazione del valore';
								|pl = 'Sprawdzenie wypełnienia wartości';
								|tr = 'Değerin doluluk kontrolü'");
	AddOperator(OperatorsGroup,
		OperatorID,
		OperatorInCodeLanguageForInsertion,
		OperatorPresentation,
		ExplanationOfOperator);
	
EndProcedure

#EndRegion

#Region MethodsForUpdatingInformationBase

// Returns tables of characteristics and their properties for each value type
// 
// Parameters:
// 	TypeDescription - TypeDescription - Types for which you want to obtain characteristics.
// 	SelectionBySetsOfAdditionalDetails - Undefined, Array of CatalogRef.AdditionalAttributesAndInfoSets - If a
// 			selection is set, only additional details and information that meets the selection will be received.
// 	UseTitleInsteadOfPresentation - Boolean - True if you need to get names as views.
// 			For example, in templates for names of types of items.
// Returns:
// 	Map - Matching the data type included in the type description passed to the method and the characteristic properties table:
// 	  * Key - Type - Type of values.
// 	  * Value - See TableOfPropertiesCharacteristicsByOwnerType
//
Function CharacteristicsByPresentation(TypeDescription, SelectionBySetsOfAdditionalDetails = Undefined, UseTitleInsteadOfPresentation = False) Export
	
	PropertiesOfCharacteristicsByType = GetPropertiesOfCharacteristicsForObjectsOfType(TypeDescription,
		SelectionBySetsOfAdditionalDetails,
		UseTitleInsteadOfPresentation);
	
	For Each KeyAndValue In PropertiesOfCharacteristicsByType Do
		PropertiesTable = KeyAndValue.Value; // ValueTable -
		PropertiesTable.Indexes.Add("CharacteristicPresentation");
	EndDo;
	
	Return PropertiesOfCharacteristicsByType;
	
EndFunction

// Converts the operand expression to a new formula format (instead of representations of characteristics
// , identifiers will be specified in the format " {Prefixtypacharacteristic.Character identifier}".
// 
// Parameters:
// 	SourceOperands - Array of String - Texts of the source operands.
// 	DataCompositionSchema - DataCompositionSchema - Layout drawing on which to build the operands
// Returns:
// 	Structure - LongDesc:
// * ConvertedExpressions - Map - consists of:
//    **Key - String - The original expression.
//    **Value - String - The converted expression.
// * HasErrors - Boolean - Flag for a conversion error.
// * ConversionErrorMessages - String - Descriptions of conversion errors:
//    **Key - String - The original expression.
//    **Value - String - Text of the conversion error.
//
Function ConvertOperandsOfDCSFormulaToIdentifierFormat(SourceOperands, DataCompositionSchema) Export
	
	ConversionResult = New Structure;
	ConversionResult.Insert("ConvertedExpressions", New Map);
	ConversionResult.Insert("HasErrors", False);
	ConversionResult.Insert("ConversionErrorMessages", New Map);
	
	FieldNamesWithParents = New Array;
	For Each DataSet In DataCompositionSchema.DataSets Do
		SetFields = DataSet.Fields;
		For Each FieldDetails In SetFields Do
			DataPath = FieldDetails.DataPath;
			If StrFind(DataPath, ".") > 0 Then
				If FieldNamesWithParents.Find(DataPath) = Undefined Then
					FieldNamesWithParents.Add(DataPath);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	PresentationOfAllCharacteristicsByType = ProcessingOfFormulasCached.CharacteristicsByPresentation();
	
	ConversionParameters = New Structure;
	ConversionParameters.Insert("FieldNamesWithParents", FieldNamesWithParents);
	ConversionParameters.Insert("PresentationsOfCharacteristics", PresentationOfAllCharacteristicsByType);
	ConversionParameters.Insert("OverridingFeaturePresentationsForTypes", Undefined);
	ConversionParameters.Insert("ExpressionParameterCache", New Map);
	ConversionParameters.Insert("FirstPartOfOperandIsNotIncludedInText", False);
	
	For Each SourceOperand In SourceOperands Do
		If OperandIsSpecifiedInFormatOfIdentifiers(SourceOperand) Then
			ConversionResult.ConvertedExpressions.Insert(SourceOperand, SourceOperand);
			Continue;
		EndIf;
		
		ResultOfOperandConversion = ConvertFormulaOperandToIdentifierFormat(SourceOperand,
			SettingsComposer, ConversionParameters);
		If ResultOfOperandConversion.HasErrors Then
			ConversionResult.HasErrors = True;
			ConversionResult.ConversionErrorMessages.Insert(SourceOperand, ResultOfOperandConversion.ErrorText);
			ConversionResult.ConvertedExpressions.Insert(SourceOperand, "");
		Else
			ConversionResult.ConvertedExpressions.Insert(SourceOperand, ResultOfOperandConversion.ConvertedOperand);
		EndIf;
	EndDo;
	
	Return ConversionResult;
	
EndFunction

// Converts the operand expression to a new formula format (instead of representations of characteristics
// , identifiers will be specified in the format " {Prefixtypacharacteristic.Character identifier}".
// 
// Parameters:
// 	SourceOperand - String - Text of the source operand.
// 	FirstLevelOperandSettingsComposer - DataCompositionSettingsComposer - initialized configuration linker for searching the first part of an expression.
// 	ConversionParameters - Structure - Auxiliary conversion parameters:
// 	 * FieldNamesWithParents - Array of String - A list of fields whose data path is separated by a dot. For example, "Account.Subconto1".
// 	 * PresentationsOfCharacteristics - See ProcessingOfFormulas.CharacteristicsByPresentation
// 	 * OverridingFeaturePresentationsForTypes - Undefined, Map - In the event that a redefinition of getting characteristics was set for certain types:
// 	   ** Key - Type - The data type for which the property acquisition override was set.
// 	   ** Value - See ProcessingOfFormulas.CharacteristicsByPresentation
// 	 * FirstPartOfOperandIsNotIncludedInText - Boolean - Indicates that the first part of the expression is not included in the operand.
// 	 		For example, in the operands of the formula types of nomenclature, the operand characteristic of the nomenclature is written as
// 	 		[Feature representation], instead of [Nomenclature.[Performance characteristics]].
// 	 *ExpressionTypeCache - Map - 
// Returns:
// 	Structure - LongDesc:
// * ErrorText - String - Description of the conversion error.
// * HasErrors - Boolean - Flag for a conversion error.
// * ConvertedOperand - String - The value of the converted operand.
Function ConvertFormulaOperandToIdentifierFormat(SourceOperand, FirstLevelOperandSettingsComposer, ConversionParameters)
	
	ConversionResult = New Structure;
	ConversionResult.Insert("ConvertedOperand", "");
	ConversionResult.Insert("HasErrors", False);
	ConversionResult.Insert("ErrorText", "");
	
	FieldNamesWithParents = ConversionParameters.FieldNamesWithParents;
	OverridingFeaturePresentationsForTypes = ConversionParameters.OverridingFeaturePresentationsForTypes;
	PresentationsOfCharacteristics = ConversionParameters.PresentationsOfCharacteristics;
	ExpressionParameterCache = ConversionParameters.ExpressionParameterCache;
	FirstPartOfOperandIsNotIncludedInText = ConversionParameters.FirstPartOfOperandIsNotIncludedInText;
	If FirstPartOfOperandIsNotIncludedInText Then
		OperandParts = ProcessingOfFormulasClientServer.OperandParts(SourceOperand);
		OperandParts.Delete(0);
		PresentationOfOriginalOperand = StrConcat(OperandParts, ".");
	Else
		PresentationOfOriginalOperand = SourceOperand;
	EndIf;
	MatchesNamesOfStandardProps = ProcessingOfFormulasCached.MatchesNamesOfStandardProps();
	
	ReplacementExpression = "";
	AccumulatedPath = "";
	ThereAreOperandBrackets = StrStartsWith(SourceOperand, "[") And StrEndsWith(SourceOperand, "]");
	If ThereAreOperandBrackets Then
		SourceOperandWithoutOuterBrackets = Mid(SourceOperand, 1, StrLen(SourceOperand) - 1);
		SourceOperandWithoutOuterBrackets = Mid(SourceOperandWithoutOuterBrackets, 2);
	Else
		SourceOperandWithoutOuterBrackets = SourceOperand;
	EndIf;
	
	// Checking for a complex layout field, for example "Invoice.Subconto1".
	ParentSpecificField = "";
	For Each FieldNameWithParents In FieldNamesWithParents Do
		If StrStartsWith(SourceOperand, FieldNameWithParents) Then
			NextChar = Mid(SourceOperand, StrLen(FieldNameWithParents) + 1, 1);
			If NextChar = "." Or NextChar = "" Then
				ParentSpecificField = FieldNameWithParents;
				Break;
			EndIf;
		EndIf;
	EndDo;
	If IsBlankString(ParentSpecificField) Then
		RemainderOfExpression = SourceOperand;
	Else
		RemainderOfExpression = Mid(SourceOperand, StrLen(ParentSpecificField + ".") + 1);
	EndIf;
	
	PartsOfExpression = ProcessingOfFormulasClientServer.OperandParts(RemainderOfExpression,, False);
	If IsBlankString(ParentSpecificField) Then
		AccumulatedPath = PartsOfExpression[0];
		PartsOfExpression.Delete(0);
	Else
		AccumulatedPath = ParentSpecificField;
	EndIf;
	
	
	// There cannot be a characteristic at the beginning of an expression, because a characteristic always belongs
	// to some object (a field in a query or a column in a table). Therefore, we are looking for a field according to the original layout scheme
	// , taking into account that a complex data path can be set for the field.
	ExpressionParameters = ExpressionParameterCache.Get(AccumulatedPath);
	If ExpressionParameters = Undefined Then
		DCSField = DataCompositionServer.FindDCSFieldByFullName(
			FirstLevelOperandSettingsComposer.Settings.Selection.SelectionAvailableFields.Items,
			AccumulatedPath);
		If DCSField = Undefined Then
			ConversionResult.HasErrors = True;
			
			MessageText = NStr("vi = 'Không tìm thấy trường ""%1"" trong biểu thức ""%2"". Hãy kiểm tra tính chính xác của biểu thức.';
								|ru = 'Не найдено поле ""%1"" в выражении ""%2"". Проверьте корректность выражения.';
								|en = 'Cannot find ""%1"" field in expression ""%2"". Check, if the expression is correct.'; fa = 'Cannot find ""%1"" field in expression ""%2"". Check, if the expression is correct.';
								|it = 'Il campo ""%1"" nell''espressione ""%2"" non è stato trovato. Verificate la correttezza dell''espressione.';
								|pl = 'Nie znaleziono pola ""%1"" w wyrażeniu ""%2"". Sprawdź popawność wyrażenia.';
								|tr = '""%2"" ifadesinde ""%1"" alanı bulunamadı. İfadenin doğruluğunu kontrol edin.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
				AccumulatedPath, PresentationOfOriginalOperand);
			ConversionResult.ErrorText =  MessageText;
		Else
			ValueType = DCSField.Type;
			ExpressionInFormulaFormat = AccumulatedPath;
			ExpressionParameters = New Structure("ValueType, ExpressionInFormulaFormat", ValueType, ExpressionInFormulaFormat);
			ExpressionParameterCache.Insert(AccumulatedPath, ExpressionParameters);
		EndIf;
	Else
		ValueType = ExpressionParameters.ValueType;
		ExpressionInFormulaFormat = ExpressionParameters.ExpressionInFormulaFormat;
	EndIf;
	If Not ConversionResult.HasErrors Then
		ReplacementExpression = AccumulatedPath;
	EndIf;
	
	While AccumulatedPath <> SourceOperandWithoutOuterBrackets
		And PartsOfExpression.Count() > 0
		And Not ConversionResult.HasErrors Do
		
		PartOfExpression = PartsOfExpression[0];
		PartsOfExpression.Delete(0);
		
		TypesOfExpressionPart = New Array;
		
		ThisIsCharacteristic = (Upper(ProcessingOfFormulasClientServer.IDForFormulas(PartOfExpression)) <> Upper(PartOfExpression));
		MaybeItSProps = False;
		If Not ThisIsCharacteristic Then
			// Perhaps this is a prop, or perhaps a characteristic with a simple representation.
			MaybeItSProps = True;
			PropsFound = False;
			Types = ValueType.Types();
			For Each Type In Types Do
				MetadataObjectsList = Metadata.FindByType(Type);
				If MetadataObjectsList = Undefined Then
					Continue;
				EndIf;
				If Common.IsEnum(MetadataObjectsList) Then
					Continue;
				EndIf;
				
				Attribute = MetadataObjectsList.Attributes.Find(PartOfExpression);
				If Not Attribute = Undefined Then
					PropsFound = True;
					TypesOfExpressionPart = New Array;
					AttributeTypes = Attribute.Type.Types();
					For Each AttributeType In AttributeTypes Do
						If TypesOfExpressionPart.Find(AttributeType) = Undefined Then
							TypesOfExpressionPart.Add(AttributeType);
						EndIf;
					EndDo;
				EndIf;
				If Not PropsFound Then
					For Each Attribute In MetadataObjectsList.StandardAttributes Do
						If Attribute.Name = PartOfExpression
							Or MatchesNamesOfStandardProps.Get(Attribute.Name) = PartOfExpression Then
							PropsFound = True;
							AttributeTypes = Attribute.Type.Types();
							For Each AttributeType In AttributeTypes Do
								If TypesOfExpressionPart.Find(AttributeType) = Undefined Then
									TypesOfExpressionPart.Add(AttributeType);
								EndIf;
							EndDo;
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			If PropsFound Then
				AccumulatedPath = AccumulatedPath + "." + PartOfExpression;
				ReplacementExpression = ReplacementExpression + "." + PartOfExpression;
				ValueType = New TypeDescription(TypesOfExpressionPart);
			Else
				ThisIsCharacteristic = True;
			EndIf;
		EndIf;
		If ThisIsCharacteristic Then
			If StrStartsWith(PartOfExpression, "[") And StrEndsWith(PartOfExpression, "]") Then
				CharacteristicPresentation = Mid(PartOfExpression, 1, StrLen(PartOfExpression) - 1);
				CharacteristicPresentation = Mid(CharacteristicPresentation, 2);
			Else
				CharacteristicPresentation = PartOfExpression;
			EndIf;
			
			Types = ValueType.Types();
			SuitableIdentifiers = New Array;
			For Each Type In Types Do
				PropertiesOfTypeCharacteristics = Undefined;
				If TypeOf(OverridingFeaturePresentationsForTypes) = Type("Map") Then
					PropertiesOfTypeCharacteristics = OverridingFeaturePresentationsForTypes.Get(Type);
				EndIf;
				If PropertiesOfTypeCharacteristics = Undefined Then
					PropertiesOfTypeCharacteristics = PresentationsOfCharacteristics.Get(Type);
				EndIf;
				
				If TypeOf(PropertiesOfTypeCharacteristics) = Type("ValueTable") Then
					Search = New Structure("PresentationOfCharacteristicUpperCase", Upper(CharacteristicPresentation));
					FoundCharacteristics = PropertiesOfTypeCharacteristics.FindRows(Search);
					If FoundCharacteristics.Count() > 1 Then
						ConversionResult.HasErrors = True;
						ErrorText = NStr("vi = 'Đối với kiểu giá trị %1 đã tìm thấy hơn 1 đặc tính theo cách trình bày ""%2"". Không thể chuyển đổi biểu thức.';
										|ru = 'Для типа значений %1 по найдено более 1 характеристики по представлению ""%2"". Выражение не может быть преобразовано.';
										|en = 'More than 1 variants by presentation ""%2"" were found for %1 value type. Expression cannot be converted.'; fa = 'More than 1 variants by presentation ""%2"" were found for %1 value type. Expression cannot be converted.';
										|it = 'Per il tipo di valore %1 sono state trovate più di una caratteristica per visualizzazione ""%2"". Espressione non può essere trasformata.';
										|pl = 'Dla typu wartości %1 znaleziono więcej niż 1 charakterystykę wg prezentacji ""%2"". Wyrażenie nie może być przekształcone.';
										|tr = '%1 değer tipi için ""%2"" görünümünde 1''den fazla varyant bulundu. İfade dönüştürülemez.'");
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
							Type, CharacteristicPresentation);
						ConversionResult.ErrorText = ErrorText;
						Break;
					ElsIf FoundCharacteristics.Count() = 1 Then
						TypesOfCharacteristics = FoundCharacteristics[0].ValueType; // TypeDescription -
						For Each Type In TypesOfCharacteristics.Types() Do
							If TypesOfExpressionPart.Find(Type) = Undefined Then
								TypesOfExpressionPart.Add(Type);
							EndIf;
						EndDo;
						If SuitableIdentifiers.Find(FoundCharacteristics[0].FullID) = Undefined Then
							SuitableIdentifiers.Add(FoundCharacteristics[0].FullID);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			If ConversionResult.HasErrors Then
				Break;
			EndIf;
			If SuitableIdentifiers.Count() = 1 Then
				AccumulatedPath = AccumulatedPath + "." + PartOfExpression;
				ReplacementExpression = ReplacementExpression + "." + SuitableIdentifiers[0];
				ValueType = New TypeDescription(TypesOfExpressionPart);
			ElsIf SuitableIdentifiers.Count() = 0 Then
				ConversionResult.HasErrors = True;
				If MaybeItSProps Then
					ErrorText = NStr("vi = 'Không tìm thấy trường ""%1"" trong biểu thức ""%2"". Hãy kiểm tra tính chính xác của biểu thức.';
									|ru = 'Не найдено поле ""%1"" в выражении ""%2"". Проверьте корректность выражения.';
									|en = 'Cannot find ""%1"" field in expression ""%2"". Check, if the expression is correct.'; fa = 'Cannot find ""%1"" field in expression ""%2"". Check, if the expression is correct.';
									|it = 'Il campo ""%1"" nell''espressione ""%2"" non è stato trovato. Verificate la correttezza dell''espressione.';
									|pl = 'Nie znaleziono pola ""%1"" w wyrażeniu ""%2"". Sprawdź popawność wyrażenia.';
									|tr = '""%2"" ifadesinde ""%1"" alanı bulunamadı. İfadenin doğruluğunu kontrol edin.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
						CharacteristicPresentation, PresentationOfOriginalOperand);
				Else
					ErrorText = NStr("vi = 'Trong biểu thức ""%1"" theo cách trình bày đặc tính ""%2"" không tìm thấy đặc tính hợp lệ tương ứng. Không thể chuyển đổi biểu thức.';
									|ru = 'В выражении ""%1"" по представлению характеристики ""%2"" не найдено соответствующей доступной характеристики. Выражение не может быть преобразовано.';
									|en = 'No corresponding available variant was found in expression ""%1"" by presentation of variant ""%2"". Expression cannot be converted.'; fa = 'No corresponding available variant was found in expression ""%1"" by presentation of variant ""%2"". Expression cannot be converted.';
									|it = 'Nell''espressione ""%1"" per visualizzazione della caratteristica ""%2"" non è stata trovata caratteristica corrispondente disponibile. L''espressione non può essere trasformata.';
									|pl = 'W wyrażeniu ""%1"" wg prezentacji charakterystyki ""%2"" nie znaleziono pasującej dostępnej charakterystyki. Wyrażenie nie może być przekształcone.';
									|tr = '""%2"" varyant görünümü doğrultusunda ""%1"" ifadesinde eşleşen mevcut bir varyant bulunamadı. İfade dönüştürülemez.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
						PresentationOfOriginalOperand, CharacteristicPresentation);
				EndIf;
				ConversionResult.ErrorText = ErrorText;
			Else
				ConversionResult.HasErrors = True;
				ErrorText = NStr("vi = 'Trong biểu mẫu ""%1"" theo cách trình bày đặc tính ""%2"" đã tìm thấy hơn 1 đặc tính hợp lệ tương ứng. Không thể chuyển đổi biểu thức.';
								|ru = 'В выражении ""%1"" по представлению характеристики ""%2"" найдено более 1 соответствующей доступной характеристики. Выражение не может быть преобразовано.';
								|en = 'More than 1 corresponding available variants were found in expression ""%1"" by presentation of variant ""%2"". Expression cannot be converted.'; fa = 'More than 1 corresponding available variants were found in expression ""%1"" by presentation of variant ""%2"". Expression cannot be converted.';
								|it = 'Nell''espressione ""%1"" per visualizzazione della caratteristica ""%2"" sono state trovate più caratteristiche disponibili corrispondenti. L''espressione non può essere trasformata.';
								|pl = 'W wyrażeniu ""%1"" wg prezentacji charakterystyki ""%2"" znaleziono więcej niż 1 pasująca charakterystyka. Wyrażenie nie może być przekształcone.';
								|tr = '""%2"" varyant görünümü doğrultusunda ""%1"" ifadesinde 1''den fazla eşleşen mevcut varyant bulundu. İfade dönüştürülemez.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					PresentationOfOriginalOperand, CharacteristicPresentation);
				ConversionResult.ErrorText = ErrorText;
			EndIf;
		EndIf;
	EndDo;
	
	If Not ConversionResult.HasErrors Then
		If ThereAreOperandBrackets Then
			ReplacementExpression = ProcessingOfFormulasClientServer.GetOperandTextToInsert(ReplacementExpression);
		EndIf;
		ConversionResult.ConvertedOperand = ReplacementExpression;
	EndIf;
	
	
	
	Return ConversionResult;
	
EndFunction

Function OperandIsSpecifiedInFormatOfIdentifiers(Operand)
	
	// If the expression contains characteristics and these characteristics are specified in a new format,
	// then the operand is exactly specified in the new format.
	// Otherwise, it is necessary to parse the operand, because it is impossible to accurately separate the writing of the props from the writing of the characteristic.
	// For example, the Nomenclature.Freight forwarder.
	OperandInIDFormat = False;
	
	PropertiesOfCharacteristicSources = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	For Each PropertiesDetails In PropertiesOfCharacteristicSources Do
		If StrFind(Operand, "{" + PropertiesDetails.PropertyTypePrefix) > 0 Then
			OperandInIDFormat = True;
			Break;
		EndIf;
	EndDo;
	
	Return OperandInIDFormat;
EndFunction

#Region FeaturesOfUpdatingMetadataObjects

// Converts the expression of the item type name template to the format of formula IDs
// (the characteristics will be replaced with a string in the format " {Prefixtypacharacteristic.Character identifier}".
// For Example, " Counterparty.Main delivery warehouse "-- > " Counterparty. {ETC.Mainstay}".
// 
// Parameters:
// 	OriginalExpression - String - The original expression of the formula.
// 	TemplateAssignmentType - Type - The type for which the name template (formula) is specified:
// 			Reference link.Nomenclature, reference referenceslink.Nomenclature specificationsreferencesexternal links.SeriiNomenclature.
// 	SetsOfAdditionalPropsOfFirstLevel - Array of CatalogRef.AdditionalAttributesAndInfoSets - selection by sets
// 			of additional details that can be specified as the first part of the formula operands.
// Returns:
// 	Structure - LongDesc:
// * ErrorText - String - Text of the error, if any.
// * HasErrors - Boolean - Error flag when converting a formula
// * ConvertedExpression - String - Converted to the format of the IDs formula.
//
Function ConvertProductTypeFormulaExpressionToIDFormat(OriginalExpression, TemplateAssignmentType,
				SetsOfAdditionalPropsOfFirstLevel) Export
	
	ConversionResult = New Structure;
	ConversionResult.Insert("ConvertedExpression", "");
	ConversionResult.Insert("HasErrors", False);
	ConversionResult.Insert("ErrorText", "");
	
	OperandReplacementTable = New ValueTable;
	OperandReplacementTable.Columns.Add("SourceOperand");
	OperandReplacementTable.Columns.Add("OperandReplacement");
	
	OriginalExpressionInFormatOfIdentifiers = False;
	FormulaOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(OriginalExpression, True);
	For Each SourceOperand In FormulaOperands Do
		StringOfSubstitutions = OperandReplacementTable.Add();
		StringOfSubstitutions.SourceOperand = ProcessingOfFormulasClientServer.GetOperandTextToInsert(SourceOperand);
		
		If OperandIsSpecifiedInFormatOfIdentifiers(StringOfSubstitutions.SourceOperand) Then
			OriginalExpressionInFormatOfIdentifiers = True;
		EndIf;
	EndDo;
	
	If OriginalExpressionInFormatOfIdentifiers Then
		// It cannot be that one operand is specified in the new format, the other in the old one.
		// The situation is possible, for example, when programmatically changing database objects.
		ConversionResult.ConvertedExpression = OriginalExpression;
		Return ConversionResult;
	EndIf;
	If OperandReplacementTable.Count() = 0 Then
		// Calculated operands are not used
		ConversionResult.ConvertedExpression = OriginalExpression;
		Return ConversionResult;
	EndIf;

	// The prefix of the expression is needed to perform the main parsing algorithm, because
	// the value type is set for it. In principle, there is no difference what kind of text value it has,
	// because in the types of nomenclatures, the first part is not specified in the operands.
	If TemplateAssignmentType = Type("CatalogRef.Products") Then
		ExpressionPrefix = "Products";
		FieldTitle = NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Items'; fa = 'اقلام';
							|it = 'Articolo';
							|pl = 'Pozycja';
							|tr = 'Öğe'");
	ElsIf TemplateAssignmentType = Type("CatalogRef.ItemsCharacteristics") Then
		ExpressionPrefix = "ProductCharacteristic";
		FieldTitle = NStr("vi = 'Đặc tính mặt hàng';
							|ru = 'Характеристика номенклатуры';
							|en = 'Item variant'; fa = 'گونه قلم';
							|it = 'Caratteristica dell''articolo';
							|pl = 'Charakterystyka produktu';
							|tr = 'Ürün varyantları'");
	Else
		ExpressionPrefix = "ProductSeries";
		FieldTitle = NStr("vi = 'Sê-ri mặt hàng';
							|ru = 'Серия номенклатуры';
							|en = 'Item batch'; fa = 'بچ قلم';
							|it = 'Serie dell''elenco articoli';
							|pl = 'Seria produktów';
							|tr = 'Ürün partisi'");
	EndIf;
	TypesArray = New Array;
	TypesArray.Add(TemplateAssignmentType);
	TypeDescription = New TypeDescription(TypesArray);
	CompositionSchema = LayoutDiagramForGettingPropsByValueType(TypeDescription, True, SetsOfAdditionalPropsOfFirstLevel);
	SetAssociation = CompositionSchema.DataSets[0]; // DataCompositionSchemaDataSetUnion -
	AttributeField = SetAssociation.Fields.Find("Attribute");
	AttributeField.DataPath = ExpressionPrefix;
	AttributeField.Title = FieldTitle;
	
	SourcesOfAvailableCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	
	PresentationOfAllCharacteristicsByType = ProcessingOfFormulasCached.CharacteristicsByPresentation();
	OverridingFeaturePresentationsForTypes = CharacteristicsByPresentation(TypeDescription, SourcesOfAvailableCharacteristics, True);
	
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	FieldNamesWithParents = New Array;
	
	OperandReplacementTable.Sort("SourceOperand DESC");
	
	For Each StringOfSubstitutions In OperandReplacementTable Do
		SourceOperand = StringOfSubstitutions.SourceOperand;
		
		IntermediateExpression = SourceOperand;
		ThereAreBrackets = StrStartsWith(SourceOperand, "[") And StrEndsWith(SourceOperand, "]");
		If ThereAreBrackets Then
			IntermediateExpression = Mid(IntermediateExpression, 1, StrLen(IntermediateExpression) - 1);
			IntermediateExpression = Mid(IntermediateExpression, 2);
		EndIf;
		IntermediateExpression = ExpressionPrefix + "." + IntermediateExpression;
		
		ConversionParameters = New Structure;
		ConversionParameters.Insert("FieldNamesWithParents", FieldNamesWithParents);
		ConversionParameters.Insert("PresentationsOfCharacteristics", PresentationOfAllCharacteristicsByType);
		ConversionParameters.Insert("OverridingFeaturePresentationsForTypes", OverridingFeaturePresentationsForTypes);
		ConversionParameters.Insert("ExpressionParameterCache", New Map);
		ConversionParameters.Insert("FirstPartOfOperandIsNotIncludedInText", True);
		
		ResultOfOperandConversion = ConvertFormulaOperandToIdentifierFormat(IntermediateExpression,
			SettingsComposer,
			ConversionParameters);
		
		If ResultOfOperandConversion.HasErrors Then
			ConversionResult.HasErrors = True;
			ConversionResult.ErrorText = ResultOfOperandConversion.ErrorText;
			Break;
		EndIf;
		
		ConvertedOperand = ResultOfOperandConversion.ConvertedOperand;
		// Removing the prefix of the expression.
		ConvertedOperand = Mid(ConvertedOperand, StrLen(ExpressionPrefix) + 2); // Prefix expressions + "."
		// Add parentheses to identify the operand.
		ConvertedOperand = ProcessingOfFormulasClientServer.GetOperandTextToInsert(ConvertedOperand);
		
		StringOfSubstitutions.OperandReplacement = ConvertedOperand;
	EndDo;
	
	If Not ConversionResult.HasErrors Then
		ConvertedExpression = OriginalExpression;
		For Each StringOfSubstitutions In OperandReplacementTable Do
			ConvertedExpression = StrReplace(ConvertedExpression, StringOfSubstitutions.SourceOperand, StringOfSubstitutions.OperandReplacement);
		EndDo;
		
		ConversionResult.ConvertedExpression = ConvertedExpression;
	EndIf;
	
	Return ConversionResult;
	
EndFunction

#EndRegion

#EndRegion

#Region ErrorOutput

Procedure ReportErrorInFormula(Formula, CalculationText, ErrorReason, CheckParameters, Result, Val MessageToUserText = "")
	
	Result = False;
	EventLogComment = StrTemplate(
		NStr("vi = 'Trong công thức: %1
			|Đã phát hiện ra lỗi:
			|%2
			|
			|Nội dung tính công thức nhận được: %3';
			|ru = 'В формуле: %1
			|Обнаружены ошибки:
			|%2
			|
			|Полученный текст расчета формулы: %3';
			|en = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3'; fa = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3';
			|it = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3';
			|pl = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3';
			|tr = 'Formülde: %1
			| Hatalar tespit edildi:
			|%2
			|
			|Alınan formül hesabı metni: %3'"),
		Formula,
		ErrorReason,
		CalculationText);
		
	EventLog.AddMessageForEventLog(
		NStr("vi = 'Lỗi khi kiểm tra công thức';
			|ru = 'Ошибка при проверке формулы';
			|en = 'Formula check error'; fa = 'Formula check error';
			|it = 'Formula check error';
			|pl = 'Formula check error';
			|tr = 'Formül kontrolünde hata yaşandı'"),
		EventLogLevel.Warning, , ,
		EventLogComment);
		
	If CheckParameters.NotOutputMessages Then
		Return;
	EndIf;
	
	If IsBlankString(MessageToUserText) Then
		MessageToUserText = StrTemplate("In formula_1 detected_1 errors. %1", ErrorReason);
	EndIf;
	
	Common.MessageToUser(
		MessageToUserText,,
		CheckParameters.Field,
		CheckParameters.DataPath);
	
EndProcedure

#EndRegion

#EndRegion
