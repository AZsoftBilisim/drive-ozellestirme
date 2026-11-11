
#Region Private

#Region SetOfSeries

// Adds columns of additional details to the tabular part of the form and outputs them to the linked table.
//
// Parameters:
//	SeriesUseSettings - See Catalogs.ItemKinds.SeriesUseSettings.
//	Form - ClientApplicationForm - A Form containing a tabular part to which additional Attributes must be added:
//		* Items - FormAllItems - form element.
//	AttributeTable - String - the path to the data of the table to which columns of additional details are added.
//	ItemTable - String - the name of the form table element to which columns of additional details are added.
//	InsertBeforeElement - String - the name of the column element of the form table, before which columns
//										of additional details will be added.
//	ReadOnly - Boolean - a sign of the possibility /impossibility of editing, adding columns of additional
//								details.
//
Procedure AddColumnsOfAdditionalDetails(SeriesUseSettings, Form, AttributeTable, ItemTable, InsertBeforeElement = "", ReadOnly = False) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Return;
	EndIf;
	
	EmptySeriesObject = Catalogs.ItemsBatches.EmptyObject(SeriesUseSettings.BatchOwner);
	
	GivenTableName = StrReplace(AttributeTable,".","_");
	DetailsName = GivenTableName + "PropertiesAdditionalAttributeDetails";
	NameOfSets  = GivenTableName + "PropertiesObjectAdditionalAttributeSets";
	
	Reinitialization = TMCommonUseClientServer.HasObjectAttribute(Form, DetailsName); 
	
	SetsOfTableObjectProperties = PropertyManagerInternal.GetObjectPropertySets(EmptySeriesObject, Undefined);
	SetsOfListObjectProperties = New ValueList;
	
	For Each String In SetsOfTableObjectProperties Do
		If PropertyManagerInternal.SetPropertiesTypes(String.Set).AdditionalAttributes Then
			SetsOfListObjectProperties.Add(String.Set, String.Title);
		EndIf;
	EndDo;
	
	If Reinitialization Then
		If CommonClientServer.ValueListsAreEqual(SetsOfListObjectProperties,
																Form[NameOfSets]) Then
			// Everything has already been initialized
			Return;
		EndIf;
	EndIf;
	
	ColumnDetailsToDelete = New Array;
	
	If Not Reinitialization Then
		Attributes = New Array;
		
		// Creating service details of the form
		// Adding a prop containing the sets of additional props used.
		Attributes.Add(New FormAttribute(
		NameOfSets, New TypeDescription("ValueList")));
		
		
		// Adding the details of the description of the created details and form elements.
		Attributes.Add(New FormAttribute(
		DetailsName, New TypeDescription("ValueTable")));
		
		Attributes.Add(New FormAttribute(
		"ValueAttributeName", New TypeDescription("String"), DetailsName));
		
		Attributes.Add(New FormAttribute(
		"Property", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"),
		DetailsName));
		
		Attributes.Add(New FormAttribute(
		"ValueType", New TypeDescription("TypeDescription"), DetailsName));
		
		Attributes.Add(New FormAttribute(
		"MultilineInputField", New TypeDescription("Number"), DetailsName));
		
		Attributes.Add(New FormAttribute(
		"Deleted", New TypeDescription("Boolean"), DetailsName));
		
		Attributes.Add(New FormAttribute(
		"RequiredToFill", New TypeDescription("Boolean"), DetailsName));
		
		Attributes.Add(New FormAttribute(
		"Description", New TypeDescription("String"), DetailsName));
			
		Form.ChangeAttributes(Attributes);
		
	Else
		
		PropertiesDetails = PropertiesValues(
			EmptySeriesObject.AdditionalAttributes.Unload(),
			Form[NameOfSets],
			False);
			
		For Each PropertyDetails In PropertiesDetails Do
			ValueAttributeName = GivenTableName +
			    "AdditionalAttributeValue_"+
				StrReplace(Upper(String(PropertyDetails.Set.UUID())), "-", "x")
				+ "_"
				+ StrReplace(Upper(String(PropertyDetails.Property.UUID())), "-", "x");			
			
			ColumnDetailsToDelete.Add(AttributeTable + "." + ValueAttributeName);	
			Form.Items.Delete(Form.Items[ValueAttributeName]);
			
		EndDo;
		
	EndIf;
		
	// Let's form columns
	Form[NameOfSets] = SetsOfListObjectProperties;
		
	PropertiesDetails = PropertiesValues(
		EmptySeriesObject.AdditionalAttributes.Unload(),
		Form[NameOfSets],
		False);
	PropertiesDetails.Columns.Add("ValueAttributeName");
	PropertiesDetails.Columns.Add("NameUniquePart");
	PropertiesDetails.Columns.Add("AdditionalValue");
	PropertiesDetails.Columns.Add("Boolean");
	
	MandatoryAdditionalDetailsOfSeries = SeriesUseSettings.MandatoryAdditionalDetails;
	
	AttributesToBeAdded = New Array();
	For Each PropertyDetails In PropertiesDetails Do
		
		PropertyValueType1 = New TypeDescription(PropertyDetails.ValueType,
			,,, New StringQualifiers(1024));
		
		// Support for strings of unlimited length.
		UseUnlimitedString = PropertyManagerInternal.UseUnlimitedString(
			PropertyValueType1, PropertyDetails.MultilineInputField);
		
		If UseUnlimitedString Then
			PropertyValueType1 = New TypeDescription("String");
		EndIf;
		
		PropertyDetails.NameUniquePart = 
			StrReplace(Upper(String(PropertyDetails.Set.UUID())), "-", "x")
			+ "_"
			+ StrReplace(Upper(String(PropertyDetails.Property.UUID())), "-", "x");
		
		PropertyDetails.ValueAttributeName =
			GivenTableName + "AdditionalAttributeValue_" + PropertyDetails.NameUniquePart;
		
		If PropertyDetails.Deleted Then
			PropertyValueType1 = New TypeDescription("String");
		EndIf;
																									
		PropertyDetails.AdditionalValue =
			PropertyManagerInternal.ValueTypeContainsPropertyValues(PropertyValueType1);
		
		PropertyDetails.Boolean = Common.TypeDetailsContainsType(PropertyValueType1, Type("Boolean"));
		
		IndexOfWhatIsBeingDeleted = ColumnDetailsToDelete.Find(AttributeTable + "." + PropertyDetails.ValueAttributeName);
		
		If IndexOfWhatIsBeingDeleted <> Undefined Then
			ColumnDetailsToDelete.Delete(IndexOfWhatIsBeingDeleted);
		Else
			Attribute = New FormAttribute(PropertyDetails.ValueAttributeName, PropertyValueType1, AttributeTable, PropertyDetails.Description, True);
			AttributesToBeAdded.Add(Attribute);
		EndIf;
		
	EndDo;
	Form.ChangeAttributes(AttributesToBeAdded,ColumnDetailsToDelete);
	
	// Creating form elements.
	ItemForPlacementName = ItemTable;
	PlacementItem = Form.Items[ItemForPlacementName];
	
	Form[DetailsName].Clear();
	
	For Each PropertyDetails In PropertiesDetails Do
		
		NewDescriptionLine = Form[DetailsName].Add();
		
		FillPropertyValues(NewDescriptionLine, PropertyDetails);
		
		NewDescriptionLine.RequiredToFill = (MandatoryAdditionalDetailsOfSeries.Find(NewDescriptionLine.Property) <> Undefined);
		
		If Not IsBlankString(InsertBeforeElement) Then
			Item = Form.Items.Insert(PropertyDetails.ValueAttributeName, Type("FormField"), PlacementItem, Form.Items[InsertBeforeElement]); // FormField -
		Else
			Item = Form.Items.Add(PropertyDetails.ValueAttributeName, Type("FormField"), PlacementItem); // FormField -
		EndIf;
		
		If PropertyDetails.Boolean And IsBlankString(PropertyDetails.FormatProperties) Then
			Item.Type = FormFieldType.CheckBoxField;;
		Else
			Item.Type = FormFieldType.InputField;
			Item.AutoMarkIncomplete = NewDescriptionLine.RequiredToFill And Not PropertyDetails.Deleted;
		EndIf;
		
		Item.DataPath    = AttributeTable + "." + PropertyDetails.ValueAttributeName;
		Item.ToolTip      = PropertyDetails.Property.ToolTip;
		Item.ReadOnly = ReadOnly;
		
		If PropertyDetails.Property.MultilineInputField > 0 Then
			Item.MultiLine = True;
		EndIf;
		
		If Not IsBlankString(PropertyDetails.FormatProperties) Then
			FormatString = "";
			Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
				PropertyDetails.FormatProperties, ";");
			
			For Each Substring In Array Do
				If StrFind(Substring, "DE=") > 0 Or StrFind(Substring, "DE=") > 0 Then
					Continue;
				EndIf;
				If StrFind(Substring, "NZ=") > 0 Or StrFind(Substring, "NZ=") > 0 Then
					Continue;
				EndIf;
				If StrFind(Substring, "DF=") > 0 Or StrFind(Substring, "DF=") > 0 Then
					If StrFind(Substring, "ddd") > 0 Or StrFind(Substring, "ddd") > 0 Then
						Substring = StrReplace(Substring, "ddd", "dd");
						Substring = StrReplace(Substring, "ddd", "dd");
					EndIf;
					If StrFind(Substring, "dddd") > 0 Or StrFind(Substring, "dddd") > 0 Then
						Substring = StrReplace(Substring, "dddd", "dd");
						Substring = StrReplace(Substring, "dddd", "dd");
					EndIf;
					If StrFind(Substring, "MMM") > 0 Or StrFind(Substring, "MMM") > 0 Then
						Substring = StrReplace(Substring, "MMM", "MM");
						Substring = StrReplace(Substring, "MMM", "MM");
					EndIf;
					If StrFind(Substring, "MMMM") > 0 Or StrFind(Substring, "MMMM") > 0 Then
						Substring = StrReplace(Substring, "MMMM", "MM");
						Substring = StrReplace(Substring, "MMMM", "MM");
					EndIf;
				EndIf;
				If StrFind(Substring, "DLF=") > 0 Or StrFind(Substring, "DLF=") > 0 Then
					If StrFind(Substring, "DD") > 0 Or StrFind(Substring, "DD") > 0 Then
						Substring = StrReplace(Substring, "DD", "D");
						Substring = StrReplace(Substring, "DD", "D");
					EndIf;
				EndIf;
				FormatString = FormatString + ?(FormatString = "", "", ";") + Substring;
			EndDo;
			
			Item.Format = FormatString;
			Item.EditFormat = FormatString;
		EndIf;
		
		AdditionalValuesTypes = New Map;
		AdditionalValuesTypes.Insert(Type("CatalogRef.ObjectsPropertiesValues"), True);
		AdditionalValuesTypes.Insert(Type("CatalogRef.ObjectPropertyValueHierarchy"), True);
		
		AdditionalValueTypeIsUsed = True;
		For Each Type In PropertyDetails.ValueType.Types() Do
			If AdditionalValuesTypes.Get(Type) = Undefined Then
				AdditionalValueTypeIsUsed = False;
				Break;
			EndIf;
		EndDo;
		If AdditionalValueTypeIsUsed Then
			Item.OpenButton = False;
		EndIf;
		
		If PropertyDetails.AdditionalValue Then
			ChoiceParameters = New Array;
			ChoiceParameters.Add(New ChoiceParameter("Filter.Owner",
				?(ValueIsFilled(PropertyDetails.AdditionalValuesOwner),
					PropertyDetails.AdditionalValuesOwner, PropertyDetails.Property)));
			Item.ChoiceParameters = New FixedArray(ChoiceParameters);
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in columns containing descriptions of additional Catalog Attributes.
//
// Parameters:
//	Form - ClientApplicationForm - a form containing a table to be filled in.
//	AttributeTable - String - the path to the Attribute of the form.
//	PropertyOwnerColumn - String - the name of the column containing information about the owner of additional Attributes.
//
Procedure FillInColumnsOfAdditionalDetails(Form, AttributeTable, PropertyOwnerColumn) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Return;
	EndIf;
	
	FormTable = TableByName(Form, AttributeTable);
	
	If FormTable.Count() = 0 Then
		Return;
	EndIf;
	
	TableOfPropertyOwners = FormTable.Unload(); // ValueTable - 
	TableOfPropertyOwners.Indexes.Add(PropertyOwnerColumn);
	
	GivenTableName = StrReplace(AttributeTable, ".", "_");
	
	PropertiesTable = Form[GivenTableName + "PropertiesAdditionalAttributeDetails"].Unload(); // ValueTable - 
	PropertiesTable.Indexes.Add("Property");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AddlAttributesTable.Ref				AS Series,
	|	AddlAttributesTable.Property			AS Property,
	|	AddlAttributesTable.Value			AS Value,
	|	AddlAttributesTable.TextString	AS TextString
	|FROM
	|	Catalog.ItemsBatches.AdditionalAttributes AS AddlAttributesTable
	|WHERE
	|	AddlAttributesTable.Ref IN(&SetOfSeries)
	|
	|ORDER BY
	|	Series
	|
	|AUTOORDER";
	
	Query.SetParameter("SetOfSeries", TableOfPropertyOwners.UnloadColumn(PropertyOwnerColumn));
	
	Selection = Query.Execute().Select();
	
	CurSeries_	= Undefined;
	RowFilter		= New Structure(PropertyOwnerColumn);
	SeriesLines_		= Undefined;
	
	While Selection.Next() Do
		PropertyStrings = PropertiesTable.Find(Selection.Property, "Property");
		
		If PropertyStrings = Undefined Then
			Continue;
		EndIf;
		
		If Selection.Series <> CurSeries_ Then
			CurSeries_ = Selection.Series;
			RowFilter[PropertyOwnerColumn] = Selection.Series;
			SeriesLines_ = TableOfPropertyOwners.FindRows(RowFilter);
		EndIf;
		
		AttributeValue = ?(PropertyStrings.MultilineInputField > 0, Selection.TextString, Selection.Value);
		
		For Each RowSeries In SeriesLines_ Do
			RowSeries[PropertyStrings.ValueAttributeName] = AttributeValue;
		EndDo;
	EndDo;
	
	FormTable.Load(TableOfPropertyOwners);
	
EndProcedure

Function CheckFillingInAdditionalDetails(Form, AttributeTable) Export
	
	HasErrors = False;
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Return True;
	EndIf;
	
	Table = TableByName(Form, AttributeTable);
	GivenTableName = StrReplace(AttributeTable, ".", "_");
	
	StructureOfVerifiedDetails = New Structure;
	For Each CurrRow In Form[GivenTableName + "PropertiesAdditionalAttributeDetails"] Do
		If CurrRow.RequiredToFill And Not CurrRow.Deleted Then
			StructureOfVerifiedDetails.Insert(CurrRow.ValueAttributeName);
		EndIf;
	EndDo;
	
	If StructureOfVerifiedDetails.Count() = 0 Then
		Return True;
	EndIf;
	
	For Each CurrRow In Table Do
		For Each Attribute In StructureOfVerifiedDetails Do
			If Not ValueIsFilled(CurrRow[Attribute.Key]) Then
				HasErrors = True;
			EndIf;
		EndDo;
	EndDo;
	
	If HasErrors Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền mục tin bổ sung bắt buộc sê-ri.';
				|ru = 'Не заполнены обязательные доп. реквизиты серий.';
				|en = 'Required addit. batch attributes are not filled in.'; fa = 'Required addit. batch attributes are not filled in.';
				|it = 'I requisiti aggiuntivi obbligatori delle serie non sono compilati.';
				|pl = 'Nie są wypełnione wymagane dod. rekwizyty serii.';
				|tr = 'Zorunlu ek parti öznitelikleri doldurulmadı.'"));
		
	EndIf;
	
	Return Not HasErrors;
	
EndFunction

Procedure TransferAdditionalDetailsFromFormToObject(Object, Form, TableRow, AttributeTable) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Return;
	EndIf;
	
	Object.AdditionalAttributes.Clear();
	
	GivenTableName = StrReplace(AttributeTable, ".", "_");
	
	For Each CurrRow In Form[GivenTableName + "PropertiesAdditionalAttributeDetails"] Do
		
		NwRw = Object.AdditionalAttributes.Add();
		NwRw.Property = CurrRow.Property;
		
		If CurrRow.MultilineInputField > 0 Then
			NwRw.TextString = TableRow[CurrRow.ValueAttributeName];
		Else
			NwRw.Value = TableRow[CurrRow.ValueAttributeName];
		EndIf;
		
	EndDo;
	
EndProcedure

// Function - There is an add-on.Attributes in the table
//  Analyzes the presence of add-ons.Attributes in the Attributes table.
// Parameters:
//  Form			 - ClientApplicationForm - form being checked
//  AttributeTable	 - String - The path to the form table with the add-on.Attributes
// 
// Returns:
//  Boolean - Indicates that there is an add-on.Attributes in the table
//
Function ThereAreAdditionalDetailsInTable(Form, AttributeTable) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Return False;
	EndIf;
	
	GivenTableName = StrReplace(AttributeTable,".","_");
	DetailsName = GivenTableName + "PropertiesAdditionalAttributeDetails";
	
	If Not TMCommonUseClientServer.HasObjectAttribute(Form, DetailsName) Then
		Return False;
	EndIf;
	
	Return TableByName(Form, DetailsName).Count() > 0;
	
	
EndFunction

Function ReadAdditionalSeriesDetails(Form, AttributeTable, Series) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo")
	 Or Not ValueIsFilled(Series) Then
		Return New FixedStructure;
	EndIf;
	
	GivenTableName = StrReplace(AttributeTable,".","_");
	DetailsName = GivenTableName + "PropertiesAdditionalAttributeDetails";
	DescriptionTable = TableByName(Form, DetailsName);
	
	StructureOfAdditionalBankingDetails = New Structure;
	For Each CurrRow In DescriptionTable Do
		StructureOfAdditionalBankingDetails.Insert(CurrRow.ValueAttributeName, "");
	EndDo;
	
	For Each CurrRow In Series.AdditionalAttributes Do
		
		PropertyStrings = DescriptionTable.FindRows(New Structure("Property", CurrRow.Property));
		If PropertyStrings.Count() > 0 Then
			StructureOfAdditionalBankingDetails.Insert(
				PropertyStrings[0].ValueAttributeName,
				?(PropertyStrings[0].MultilineInputField > 0, CurrRow.TextString, CurrRow.Value));
		EndIf;
		
	EndDo;
	
	Return New FixedStructure(StructureOfAdditionalBankingDetails);
	
EndFunction

// Set the mark of unfilled properties.
// 
// Parameters:
//  Form - ClientApplicationForm
//  PropertiesOwner - CatalogObject.ItemsBatches - Property Owner
Procedure CheckBlankProperties(Form, PropertiesOwner) Export
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Return;
	EndIf;
	
	If Not TMCommonUseClientServer.HasObjectAttribute(Form, "PropertiesAdditionalAttributeDetails") Then
		Return;
	EndIf;
	
	PropertiesTable = Form.PropertiesAdditionalAttributeDetails;
	
	MandatoryAdditionalDetails = New Array;
	
	AdditionalAttributesOfOwner = PropertyManager.ObjectProperties(PropertiesOwner.Ref);
	For Each RequiredAttributeElement In AdditionalAttributesOfOwner Do
		
		If RequiredAttributeElement.RequiredToFill Then
			MandatoryAdditionalDetails.Add(RequiredAttributeElement);
		EndIf;
		
	EndDo;
	
	MandatoryAdditionalAttributesOfItemKind = Catalogs.ItemKinds.SeriesUseSettings(PropertiesOwner.ProductKind).MandatoryAdditionalDetails;
	CommonClientServer.SupplementArray(MandatoryAdditionalDetails, MandatoryAdditionalAttributesOfItemKind, True);
	
	For Each CurProperty In PropertiesTable Do
		
		If Not CurProperty.FormItemAdded
			Or Form.Items[CurProperty.ValueAttributeName].Type <> FormFieldType.InputField Then
			Continue;
		EndIf;
		
		CurProperty.RequiredToFill = MandatoryAdditionalDetails.Find(CurProperty.Property) <> Undefined;
		
		Form.Items[CurProperty.ValueAttributeName].AutoMarkIncomplete =
			CurProperty.RequiredToFill
			And Not CurProperty.Deleted;
		
	EndDo;
	
EndProcedure

Function TableByName(Form, AttributeTable)
	
	PointPosition = StrFind(AttributeTable, ".");
	
	If PointPosition = 0 Then
		Table = Form[AttributeTable];
	Else
		NamesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AttributeTable,".");
		Table = Form[NamesArray[0]][NamesArray[1]];
	EndIf;
	
	Return Table;
EndFunction

#EndRegion

#Region ItemKinds

Procedure PerformActionsBeforeSavingAdditionalAttributeBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.IsAdditionalInfo
	 Or Source.AdditionalProperties.Property("DoNotUpdateTitleTemplates") Then
		Return;
	EndIf;
	
	OldName_ = Common.ObjectAttributeValue(Source.Ref, "Description");
	
	If Source.Description <> OldName_ Then
		Source.AdditionalProperties.Insert("OldName_", OldName_);
	EndIf;
	
EndProcedure

Procedure PerformActionsOnSavingAdditionalAttributeOnWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Source.AdditionalProperties.Property("OldName_") Then
		Return;
	EndIf;
	
	OldName_ = "[" + Source.AdditionalProperties.OldName_ + "]";
	NewDescription  = "[" + Source.Description + "]";
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ItemKinds.Ref,
	|	CASE
	|		WHEN ItemKinds.CharacteristicsPropertySet = &PropertiesSet
	|			THEN ""Characteristics""
	|		WHEN ItemKinds.BatchPropertySet = &PropertiesSet
	|			THEN ""SetOfSeries""
	|		ELSE ""OfProductItem""
	|	END AS TemplateName,
	|	ItemKinds.NameTemplateForPrintingOfProductItem,
	|	ItemKinds.NameTemplateForPrintingCharacteristics,
	|	"""" AS NameTemplateForPrintingSetOfSeries,
	|	ItemKinds.WorkingNameTemplateOfProductItem,
	|	ItemKinds.WorkingNameTemplateCharacteristics,
	|	ItemKinds.WorkingNameTemplateSetOfSeries
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	(ItemKinds.PropertiesSet = &PropertiesSet
	|			OR ItemKinds.BatchPropertySet = &PropertiesSet
	|			OR ItemKinds.CharacteristicsPropertySet = &PropertiesSet)";
	
	Query.SetParameter("PropertiesSet", Source.PropertiesSet);
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	TemplateDetails_0 = New Structure;
	TemplateDetails_0.Insert("NameTemplateForPrinting" + Selection.TemplateName, "");
	TemplateDetails_0.Insert("WorkingNameTemplate"  + Selection.TemplateName, "");
	
	FillPropertyValues(TemplateDetails_0, Selection);
	
	ChangedNames = New Map;
	ChangedNames.Insert(OldName_, NewDescription);
	
	ReplaceNamesInTemplates(Selection.Ref, TemplateDetails_0, ChangedNames);
	
EndProcedure

// Adapted version of property Management.Before writing a ViewObject()
//
// Parameters:
//  ProductKind - CatalogObject.ItemKinds
//  ObjectWithPropertiesName - String - Name of an object with properties
//  PropertySetAttributeName - String - The name of the property set props
//  EndOfName - String - End of the name
//  NeedSetOfProperties - Boolean - Need a set of properties
Procedure UpdateAdditionalPropertyFields(ProductKind,
                                  ObjectWithPropertiesName,
                                  PropertySetAttributeName = "PropertiesSet",
								  EndOfName = "",
								  NeedSetOfProperties = True) Export
	
	SetPrivilegedMode(True);
	
	PropertiesSet   = ProductKind[PropertySetAttributeName];
	SetParent = PropertyManager.PropertiesSetByName(ObjectWithPropertiesName);
	
	// Updates to the names of a set of properties
	If ValueIsFilled(PropertiesSet) Then
		
		OldSetProperties = Common.ObjectAttributesValues(
			PropertiesSet, "Description, Parent, DeletionMark");
		
		If OldSetProperties.Description    = ProductKind.Description + EndOfName
		   And OldSetProperties.DeletionMark = ProductKind.DeletionMark
		   And OldSetProperties.Parent        = SetParent Then
			
			Return;
		EndIf;
		
		If OldSetProperties.Parent = SetParent Then
			LockDataForEdit(PropertiesSet);
			PropertySetObject = PropertiesSet.GetObject();
		Else
			PropertySetObject = PropertiesSet.Copy();
		EndIf;
		
	ElsIf NeedSetOfProperties Then
		PropertySetObject = Catalogs.AdditionalAttributesAndInfoSets.CreateItem();
		PropertySetObject.Used = True;
	Else
		PropertySetObject = Undefined;
	EndIf;
	
	If PropertySetObject <> Undefined Then 
		PropertySetObject.Description    = ProductKind.Description + EndOfName;
		PropertySetObject.DeletionMark = ?(NeedSetOfProperties, ProductKind.DeletionMark, True);;
		PropertySetObject.Parent        = SetParent;
		PropertySetObject.Write();
	EndIf;
	
	ProductKind[PropertySetAttributeName] = ?(NeedSetOfProperties, PropertySetObject.Ref, Undefined);
	
	// Updating the names of non-common additional details and information.
	If Not ValueIsFilled(PropertiesSet) Then
		Return;
	EndIf;
	
	ChangedNames = New Map;
	
	Query = New Query;
	Query.SetParameter("PropertiesSet", PropertiesSet);
	Query.Text =
	"SELECT
	|	Properties.Ref AS Ref,
	|	Properties.PropertiesSet.Description AS DescriptionOfSet,
	|	Properties.PropertiesSet.DeletionMark AS DeletionMarkOfSet,
	|	Properties.IsAdditionalInfo
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|WHERE
	|	Properties.PropertiesSet = &PropertiesSet
	|	AND CASE
	|			WHEN Properties.Description <> Properties.Title + "" ("" + Properties.PropertiesSet.Description + "")""
	|				THEN TRUE
	|			WHEN Properties.DeletionMark <> Properties.PropertiesSet.DeletionMark
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	
	PropertiesSelection = Query.Execute().Select();
	While PropertiesSelection.Next() Do
		
		LockDataForEdit(PropertiesSelection.Ref);
		
		Object = PropertiesSelection.Ref.GetObject(); // ChartOfCharacteristicTypesObject.AdditionalAttributesAndInfo
		
		OldName_ = Object.Description;
		Object.Description = Object.Title + " (" + String(PropertiesSelection.DescriptionOfSet) + ")";
		Object.DeletionMark = PropertiesSelection.DeletionMarkOfSet;
		
		Object.AdditionalProperties.Insert("DoNotUpdateTitleTemplates");
		Object.Write();
		
		If Not PropertiesSelection.IsAdditionalInfo Then
			ChangedNames.Insert(
				"[" + OldName_ + "]", "[" + Object.Description + "]");
		EndIf;
		
	EndDo;
	
	// Renaming in name templates
	If ChangedNames.Count() = 0 Then
		Return;
	EndIf;
	
	TemplateDetails_0 = New Structure;
	
	If PropertySetAttributeName = "CharacteristicsPropertySet" Then
		TemplateDetails_0.Insert("NameTemplateForPrintingCharacteristics");
		TemplateDetails_0.Insert("WorkingNameTemplateCharacteristics");
	ElsIf PropertySetAttributeName = "BatchPropertySet" Then
		TemplateDetails_0.Insert("WorkingNameTemplateSetOfSeries");
	Else
		TemplateDetails_0.Insert("NameTemplateForPrintingOfProductItem");
		TemplateDetails_0.Insert("WorkingNameTemplateOfProductItem");
	EndIf;
	
	FillPropertyValues(TemplateDetails_0, ProductKind);
	
	ReplaceNamesInTemplates(ProductKind, TemplateDetails_0, ChangedNames);
	
EndProcedure

Function ReplaceNamesInTemplates(ObjectOrRef, TemplateDetails_0, ChangedNames)
	
	ChangedTemplateProps = New Structure;
	
	For Each KeyAndValue In TemplateDetails_0 Do
		
		ModifiedTemplate_ = KeyAndValue.Value;
		
		For Each Descriptions In ChangedNames Do
			ModifiedTemplate_ = StrReplace(ModifiedTemplate_, Descriptions.Key, Descriptions.Value);
		EndDo;
		
		If ModifiedTemplate_ <> KeyAndValue.Value Then
			ChangedTemplateProps.Insert(KeyAndValue.Key, ModifiedTemplate_);
		EndIf;
		
	EndDo;
	
	If ChangedTemplateProps.Count() = 0 Then
		Return False;
	EndIf;
	
	If TypeOf(ObjectOrRef) = Type("CatalogRef.ItemKinds") Then
		
		Try
			LockDataForEdit(ObjectOrRef);
		Except
			
			MessageText = NStr("vi = 'Không thể phong tỏa dạng mặt hàng ""%1"" để thay đổi khuôn mẫu tên gọi.
				|Cần thay đổi thủ công tên mục tin bổ sung trong khuôn mẫu.';
				|ru = 'Не удалось заблокировать вид номенклатуры ""%1"" для изменения шаблонов наименований.
				|Необходимо вручную изменить имя дополнительного реквизита в шаблонах.';
				|en = 'Cannot lock item kind ""%1"" for changing name templates. 
				|Manually change the additional attribute name in the templates.'; fa = 'Cannot lock item kind ""%1"" for changing name templates. 
				|Manually change the additional attribute name in the templates.';
				|it = 'Non è stato possibile bloccare il tipo di articolo ""%1"" per la modifica dei modelli di denominazione. 
				| Richiesta modifica manuale del nome del requisito aggiuntivo nei modelli.';
				|pl = 'Nie udało się zablokować rodzaj pozycji ""%1"" dla zmiany szablonów nazw.
				|Należy ręcznie zmienić nazwę dodatkowego rekwizytu w szablonach.';
				|tr = 'Öğe numunelerini değiştirmek için ""%1"" ürün türü kilitlenemedi.
				|Numunelerdeki ek gereksinimin tanımı manuel olarak değiştirmek gerekir.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, TrimAll(ObjectOrRef));
			
			CommonClientServer.MessageToUser(MessageText);
			
			Return False;
			
		EndTry;
		
		Object = ObjectOrRef.GetObject();
		FillPropertyValues(Object, ChangedTemplateProps);
		Object.Write();
		
	Else
		
		FillPropertyValues(ObjectOrRef, ChangedTemplateProps);
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region Other

// Returns a table populated with the values of the object properties.
// 
// Parameters:
//  AdditionalObjectProperties - ValueTable - Additional object properties
// 	Sets - FormDataCollection
// 	IsAdditionalInfo - Boolean
// 	
// Returns:
//	ValueTable
Function PropertiesValues(AdditionalObjectProperties, Sets, IsAdditionalInfo) Export
	
	If AdditionalObjectProperties.Count() = 0 Then
		// Preliminary quick check of the use of additional properties.
		PropertiesNotFound = AdditionalAttributesAndInfoNotFound(Sets, IsAdditionalInfo);
		
		If PropertiesNotFound Then
			PropertiesDetails = New ValueTable;
			PropertiesDetails.Columns.Add("Set");
			PropertiesDetails.Columns.Add("Property");
			PropertiesDetails.Columns.Add("AdditionalValuesOwner");
			PropertiesDetails.Columns.Add("RequiredToFill");
			PropertiesDetails.Columns.Add("Description");
			PropertiesDetails.Columns.Add("ValueType");
			PropertiesDetails.Columns.Add("FormatProperties");
			PropertiesDetails.Columns.Add("MultilineInputField");
			PropertiesDetails.Columns.Add("Deleted");
			PropertiesDetails.Columns.Add("Value");
			Return PropertiesDetails;
		EndIf;
	EndIf;
	
	Properties = AdditionalObjectProperties.UnloadColumn("Property");
	
	PropertiesSets = New ValueTable;
	
	PropertiesSets.Columns.Add(
		"Set", New TypeDescription("CatalogRef.AdditionalAttributesAndInfoSets"));
	
	PropertiesSets.Columns.Add(
		"SetOrder", New TypeDescription("Number"));
	
	For Each ListItem In Sets Do
		NewRow = PropertiesSets.Add();
		NewRow.Set         = ListItem.Value;
		NewRow.SetOrder = Sets.IndexOf(ListItem);
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Properties",      Properties);
	Query.SetParameter("PropertiesSets", PropertiesSets);
	Query.Text =
	"SELECT
	|	PropertiesSets.Set,
	|	PropertiesSets.SetOrder
	|INTO PropertiesSets
	|FROM
	|	&PropertiesSets AS PropertiesSets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PropertiesSets.Set,
	|	PropertiesSets.SetOrder,
	|	SetsProperties.Property,
	|	SetsProperties.DeletionMark,
	|	SetsProperties.LineNumber AS PropertyOrder
	|INTO SetsProperties
	|FROM
	|	PropertiesSets AS PropertiesSets
	|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsProperties
	|		ON (SetsProperties.Ref = PropertiesSets.Set)
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|		ON (SetsProperties.Property = Properties.Ref)
	|WHERE
	|	NOT SetsProperties.DeletionMark
	|	AND NOT Properties.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Properties.Ref AS Property
	|INTO CompletedProperties
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|WHERE
	|	Properties.Ref IN(&Properties)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetsProperties.Set,
	|	SetsProperties.SetOrder,
	|	SetsProperties.Property,
	|	SetsProperties.PropertyOrder,
	|	SetsProperties.DeletionMark AS Deleted
	|INTO AllProperties
	|FROM
	|	SetsProperties AS SetsProperties
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef),
	|	0,
	|	CompletedProperties.Property,
	|	0,
	|	TRUE
	|FROM
	|	CompletedProperties AS CompletedProperties
	|		LEFT JOIN SetsProperties AS SetsProperties
	|		ON CompletedProperties.Property = SetsProperties.Property
	|WHERE
	|	SetsProperties.Property IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AllProperties.Set,
	|	AllProperties.Property,
	|	AdditionalAttributesAndInfo.AdditionalValuesOwner,
	|	AdditionalAttributesAndInfo.RequiredToFill,
	|	AdditionalAttributesAndInfo.Title AS Description,
	|	AdditionalAttributesAndInfo.ValueType,
	|	AdditionalAttributesAndInfo.FormatProperties,
	|	AdditionalAttributesAndInfo.MultilineInputField,
	|	AllProperties.Deleted AS Deleted,
	|	AdditionalAttributesAndInfo.Available,
	|	AdditionalAttributesAndInfo.isVisible,
	|	AdditionalAttributesAndInfo.AdditionalAttributesDependencies.(
	|		DependentProperty,
	|		Attribute,
	|		Condition,
	|		Value
	|	)
	|FROM
	|	AllProperties AS AllProperties
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON AllProperties.Property = AdditionalAttributesAndInfo.Ref
	|
	|ORDER BY
	|	Deleted,
	|	AllProperties.SetOrder,
	|	AllProperties.PropertyOrder";
	
	If IsAdditionalInfo Then
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes",
			"Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
	EndIf;
	
	PropertiesDetails = Query.Execute().Unload();
	PropertiesDetails.Indexes.Add("Property");
	PropertiesDetails.Columns.Add("Value");
	
	// Deleting duplicates of properties in the lower sets of properties.
	IndexOf = PropertiesDetails.Count()-1;
	
	While IndexOf >= 0 Do
		String = PropertiesDetails[IndexOf];
		FoundRow = PropertiesDetails.Find(String.Property);
		
		If FoundRow <> Undefined
		   And FoundRow <> String Then
			
			PropertiesDetails.Delete(IndexOf);
		EndIf;
		
		IndexOf = IndexOf-1;
	EndDo;
	
	// Filling in property values.
	For Each String In AdditionalObjectProperties Do
		PropertyDetails = PropertiesDetails.Find(String.Property, "Property");
		If PropertyDetails <> Undefined Then
			// Support for strings of unlimited length.
			If Not IsAdditionalInfo
			   And UseUnlimitedString(
			         PropertyDetails.ValueType, PropertyDetails.MultilineInputField)
			   And Not IsBlankString(String.TextString) Then 
				
				PropertyDetails.Value = String.TextString;
			Else
				PropertyDetails.Value = String.Value;
			EndIf;
		EndIf;
	EndDo;
	
	Return PropertiesDetails;
	
EndFunction

// Additional details and information were not found (for internal use only).
// 
// Parameters:
//  Sets - FormDataCollection - Sets
//  IsAdditionalInfo - Boolean - This is additional information
//  DeferredInitialization - Boolean - Delayed initialization
// 
// Returns:
//  Boolean - Additional banking details and information not found
Function AdditionalAttributesAndInfoNotFound(Sets, IsAdditionalInfo, DeferredInitialization = False) Export
	
	Query = New Query;
	Query.SetParameter("PropertiesSets", Sets.UnloadValues());
	Query.Text =
	"SELECT TOP 1
	|	SetsProperties.Property AS Property
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsProperties
	|WHERE
	|	SetsProperties.Ref IN(&PropertiesSets)
	|	AND NOT SetsProperties.DeletionMark";
	
	If IsAdditionalInfo Then
		Query.Text = StrReplace(
			Query.Text,
			"Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes",
			"Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo");
	EndIf;
	
	SetPrivilegedMode(True);
	PropertiesNotFound = Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return PropertiesNotFound;
EndFunction

// Checks whether the unlimited length string property can be used.
// 
// Parameters:
//  PropertyValueType1 - Arbitrary - Property value type
//  MultilineInputField - Arbitrary - Multiline input field
// 
// Returns:
//  Boolean - Use an unlimited string
Function UseUnlimitedString(PropertyValueType1, MultilineInputField) Export
	
	If PropertyValueType1.ContainsType(Type("String"))
	   And PropertyValueType1.Types().Count() = 1
	   And MultilineInputField > 1 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	InventoryInOperationServer.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	NonCurrentAssets.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	RMManagement.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	RebatesServer.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	GoodsDelivery.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	
	If Not Common.SubsystemExists("SalaryPersonnelSubsystems") Then
		
		Set = Items.Add();
		Set.PredefinedSetName = "Catalog_BusinessStructure";
		Set.Ref = New UUID("c091b4fd-9802-11e9-80cd-4cedfb43b11a");
		Set.Used = True;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"vi = 'Cấu trúc doanh nghiệp';
			|ru = 'Структура предприятия';
			|en = 'Business units';
			|it = 'Структура предприятия';
			|pl = 'Struktura przedsiębiorstwa';
			|tr = 'İşletme yapısı'", LanguagesCodes); // @NStr-2
		
		Set = Items.Add();
		Set.PredefinedSetName = "Catalog_Persons";
		Set.Ref = New UUID("c091b4e3-9802-11e9-80cd-4cedfb43b11a");
		Set.Used = True;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"vi = 'Cá nhân';
			|ru = 'Физические лица';
			|en = 'Persons';
			|it = 'Физические лица';
			|pl = 'Osoby fizyczne';
			|tr = 'Gerçek kişiler'", LanguagesCodes); // @NStr-2
		
		// ++ WE
		Set = Items.Add();
		Set.PredefinedSetName = "Catalog_EmployeesHR";
		Set.Ref = New UUID("c091b4e6-9802-11e9-80cd-4cedfb43b11a");
		Set.Used = True;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"ru = 'Сотрудники';
			|vi = 'Employees';
			|en = 'Employees';
			|it = 'Employees';
			|pl = 'Employees';
			|tr = 'Çalışanlar'", LanguagesCodes); // @NStr-2
		
		Set = Items.Add();
		Set.PredefinedSetName = "Catalog_JobTitles";
		Set.Ref = New UUID("c091b4c9-9802-11e9-80cd-4cedfb43b11a");
		Set.Used = True;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"ru = 'Должности';
			|vi = 'Job titles';
			|en = 'Job titles';
			|it = 'Job titles';
			|pl = 'Job titles';
			|tr = 'Unvanlar'", LanguagesCodes); // @NStr-2
		// -- WE
		Set = Items.Add();
		Set.PredefinedSetName = "Catalog_DocumentKindsOfPersons";
		Set.Ref = New UUID("d42dbf6a-9802-11e9-80cd-4cedfb43b11a");
		Set.Used = True;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"vi = 'Danh mục dạng giấy tờ tùy thân';
			|ru = 'Виды документов физических лиц';
			|en = 'Document kinds of persons';
			|it = 'Виды документов физических лиц';
			|pl = 'Rodzaje dokumentów osób fizycznych';
			|tr = 'Gerçek kişi belge türleri'", LanguagesCodes); // @NStr-2
		
		Set = Items.Add();
		Set.PredefinedSetName = "Document_BankConfirmationAboutCashReceiptOnEmployeeAccount";
		Set.Ref = New UUID("c091b4ce-9802-11e9-80cd-4cedfb43b11a");
		Set.Used = True;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
			"vi = 'Ghi có tiền vào tài khoản cá nhân';
			|ru = 'Зачисления ДС на лицевые счета';
			|en = 'Cash deposit into personal accounts';
			|it = 'Зачисления ДС на лицевые счета';
			|pl = 'Zaliczenia środków pieniężnych na konta osobiste';
			|tr = 'Kişisel hesaplara nakit tahakkuku'", LanguagesCodes); // @NStr-2
		
	EndIf;
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ReconcileOpeningBalancesByWarehouses";
	Set.Ref = New UUID("de562360-2ddb-41d4-affa-1d1bcab44b64");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Đối chiếu số dư đầu kỳ theo kho';
		|ru = 'Сверки начальных остатков по складам';
		|en = 'Reconcile opening balances by warehouses';
		|it = 'Сверки начальных остатков по складам';
		|pl = 'Uzgodnienia początkowych pozostałości według magazynu';
		|tr = 'Açılış bakiyelerinin ambarlara göre mutabakatlarının yapılması'", LanguagesCodes); // @NStr-2
	Set = Items.Add();
	Set.PredefinedSetName = "Document_PostingPayrollExpensesInFinancialAccounting2_5";
	Set.Ref = New UUID("f6751afd-bf23-492f-a2b6-3d87df8751b3");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Phản ánh tiền lương trong kế toán tài chính';
		|ru = 'Отражение зарплаты в финансовом учете';
		|en = 'Post payroll expenses to accounting';
		|it = 'Отражение зарплаты в финансовом учете';
		|pl = 'Odzwierciedlenie wynagrodzenia w ewidencji finansowej';
		|tr = 'Finansal muhasebede maaşın yansıması'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_AccrualAndDeductionKinds";
	Set.Ref = New UUID("8b46e704-739f-4bf4-bff1-f6739989eaa6");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Dạng tính lương và giữ lại tiền lương';
		|ru = 'Виды начислений, удержаний';
		|en = 'Accrual and deduction kinds';
		|it = 'Виды начислений, удержаний';
		|pl = 'Rodzaje naliczeń, potraceń';
		|tr = 'Tahakkuk türleri, kesintiler'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_CostCenters";
	Set.Ref = New UUID("10afff39-4ca9-11ea-a3f0-4cedfb68273f");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Đối tượng phát sinh chi phí';
		|ru = 'Объекты возникновения затрат';
		|en = 'Cost centers';
		|it = 'Объекты возникновения затрат';
		|pl = 'Obiekty tworzenia się rozchodów';
		|tr = 'Maliyet nesneleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ImpairmentFA";
	Set.Ref = New UUID("109b6a0d-f0c4-46a3-9061-405f492c9d24");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Chứng từ giảm giá tài sản dài hạn';
		|ru = 'Документы обесценения внеоборотных активов';
		|en = 'Fixed asset impairment documents';
		|it = 'Документы обесценения внеоборотных активов';
		|pl = 'Dokumenty utraty wartości aktywów nieobrotowych';
		|tr = 'Duran varlıkların değer kaybı  belgeleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_CashGeneratingUnits";
	Set.Ref = New UUID("831d97ce-b357-46b9-82c7-240d0af76eb1");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Đơn vị tạo tiền';
		|ru = 'ЕГДС';
		|en = 'Cash-generating unit';
		|it = 'ЕГДС';
		|pl = 'Cash-generating unit';
		|tr = 'NYB (nakit yaratan birim)'", LanguagesCodes); // @NStr-2
	Set = Items.Add();
	Set.PredefinedSetName = "Document_WIPOpeningBalancesByProductionLots";
	Set.Ref = New UUID("eb27c57c-ed52-47ae-950c-294984db1c1b");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Số dư đầu kỳ SXDD theo lô sản xuất';
		|ru = 'Начальные остатки НЗП по партиям производства';
		|en = 'WIP opening balances by production lots';
		|it = 'Начальные остатки НЗП по партиям производства';
		|pl = 'Początkowe salda PWT wg partii produkcyjnych';
		|tr = 'Lot üretimine göre Tamamlanmamış Üretimin açılış bakiyeleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_InitialWIPBalancesByBusinessUnits";
	Set.Ref = New UUID("68cc0222-1b01-4928-99de-80806db631ac");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Số dư đầu kỳ SXDD theo bộ phận';
		|ru = 'Начальные остатки НЗП по подразделениям';
		|en = 'WIP opening balances by business units';
		|it = 'Начальные остатки НЗП по подразделениям';
		|pl = 'Początkowe pozostałości produkcji w toku wg działów';
		|tr = 'Departmanlara göre devam eden imalatın açılış​​bakiyeleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_SetProductionExpenseStandards";
	Set.Ref = New UUID("fd6879f9-2e4e-43cb-b6a6-7b53e78efe51");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Định mức chi phí sản xuất';
		|ru = 'Нормативы производственных расходов';
		|en = 'Production overhead standards';
		|it = 'Нормативы производственных расходов';
		|pl = 'Normatywy kosztów produkcyjnych';
		|tr = 'Standart üretim maliyetleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_StandardCosting2_2";
	Set.Ref = New UUID("4c45141f-31b1-4823-8a1c-bb8369e082ea");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Tính giá thành kế hoạch';
		|ru = 'Плановые калькуляции';
		|en = 'Product standard costs';
		|it = 'Плановые калькуляции';
		|pl = 'Planowane kalkulacje';
		|tr = 'Standart ürün maliyetleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_TechnologicalProcesses";
	Set.Ref = New UUID("5d7e6c76-44f4-4234-89b5-a911ee94f167");
	Set.Used  = GetFunctionalOption("UseTechnologicalProcesses");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Quy trình công nghệ';
		|ru = 'Технологические процессы';
		|en = 'Technological processes';
		|it = 'Технологические процессы';
		|pl = 'Procesy technologiczne';
		|tr = 'Teknolojik süreçler'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_GoodsResearchSheets";
	Set.Ref = New UUID("76740654-da70-11f0-8de9-0242ac120002");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Карты исследования товаров';
		|vi = 'Goods research sheets';
		|en = 'Goods research sheets';
		|it = 'Goods research sheets';
		|pl = 'Goods research sheets';
		|tr = 'Ürün inceleme kartları'", LanguagesCodes); // @NStr-2
		
	Set = Items.Add();
	Set.PredefinedSetName = "Document_GoodsQualityResearch";
	Set.Ref = New UUID("1a762b0c-da70-11f0-8de9-0242ac120002");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Исследование качества товаров';
		|vi = 'Goods quality research';
		|en = 'Goods quality research';
		|it = 'Goods quality research';
		|pl = 'Goods quality research';
		|tr = 'Ürün kalite incelemesi'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_AcquiringContracts";
	Set.Ref = New UUID("73aa43ee-cabb-472d-b2ba-b191fa820620");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Hợp đồng kết nối đến hệ thống thanh toán';
		|ru = 'Договоры подключения к платежным системам';
		|en = 'Payment system contracts';
		|it = 'Договоры подключения к платежным системам';
		|pl = 'Umowy o podłączenie do systemów płatniczych';
		|tr = 'Ödeme sistemlerine bağlama sözleşmeleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ElectronicTicketTransaction";
	Set.Ref = New UUID("b9b299f9-f870-44c7-bbea-b00f8b7b1ae0");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Операции с электронными билетами';
		|vi = 'Electronic ticket transactions';
		|en = 'Electronic ticket transactions';
		|it = 'Electronic ticket transactions';
		|pl = 'Electronic ticket transactions';
		|tr = 'Elektronik bilet işlemleri'", LanguagesCodes); // @NStr-2
	
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ApplicationForBusinessTrip";
	Set.Ref = New UUID("5c35575c-3121-44bc-8039-14c4d49983e0");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Giấy đăng ký đi công tác';
		|ru = 'Заявки на командировку';
		|en = 'Travel requests';
		|it = 'Заявки на командировку';
		|pl = 'Zgłoszenia na podróż służbową';
		|tr = 'Seyahat talepleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_PriceGroups";
	Set.Ref = New UUID("32b8b176-f9b6-11ea-80f0-1831bf523deb");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Nhóm giá';
		|ru = 'Ценовые группы';
		|en = 'Price groups';
		|it = 'Ценовые группы';
		|pl = 'Grupy cenowe';
		|tr = 'Fiyat grupları'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_InventoryAssignmentAdjustment";
	Set.Ref = New UUID("b3a20385-a6ab-41c5-b92d-791290d34f5a");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Điều chỉnh mục đích hàng hóa';
		|ru = 'Корректировка назначения товаров';
		|en = 'Inventory assignment adjustment';
		|it = 'Корректировка назначения товаров';
		|pl = 'Korekta przeznaczenia towarów';
		|tr = 'Stok atama düzeltmesi'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_GoodsQualityControlCertificate";
	Set.Ref = New UUID("3a094440-02bd-4bde-919b-c4e36fe634ec");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Акт контроля качества товаров';
		|vi = 'Goods quality control certificate';
		|en = 'Goods quality control certificate';
		|it = 'Goods quality control certificate';
		|pl = 'Goods quality control certificate';
		|tr = 'Ürün kalite kontrol tutanağı'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_RequestForGoodsQualityControl";
	Set.Ref = New UUID("a7b1e6db-350c-4739-a9de-1cb0240ee2c0");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Заявка на контроль качества товаров';
		|vi = 'Request for goods quality control';
		|en = 'Request for goods quality control';
		|it = 'Request for goods quality control';
		|pl = 'Request for goods quality control';
		|tr = 'Ürün kalite kontrol talebi'", LanguagesCodes); // @NStr-2
	
	//Description Of Groups
	Set = Items.Add();
	Set.PredefinedSetName = "Document_ProductionOperation2_2";
	Set.Ref = New UUID("32542057-ad69-4117-812f-beeb230e5f06");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Giao dịch sản xuất';
		|ru = 'Производственные операции';
		|en = 'Routing operations';
		|it = 'Производственные операции';
		|pl = 'Operacje produkcyjne';
		|tr = 'Rota işlemleri'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Document_ProductionOperation2_2_Overall";
	ChildOneSet.Parent = New UUID("32542057-ad69-4117-812f-beeb230e5f06");
	ChildOneSet.Ref = New UUID("b657e8cf-b14b-4742-8049-286da4ed58f9");
	ChildOneSet.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_SubAssets";
	Set.Ref = New UUID("4db038ec-08e6-4764-a271-e7e7a0f07839");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Chi tiết máy của tài sản đang vận hành';
		|ru = 'Узлы объектов эксплуатации';
		|en = 'Sub-assets';
		|it = 'Узлы объектов эксплуатации';
		|pl = 'Węzły obiektów eksploatacji';
		|tr = 'Alt varlıklar'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_SubAssets_Overall";
	ChildOneSet.Parent = New UUID("4db038ec-08e6-4764-a271-e7e7a0f07839");
	ChildOneSet.Ref = New UUID("14b16392-2c48-424a-92af-416c00c28dfc");
	ChildOneSet.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_Products";
	Set.IsFolder = True;
	Set.Used = True;
	Set.Ref = New UUID("556f79a2-3f82-4c97-9969-9b389945b3e3");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Mặt hàng';
		|ru = 'Номенклатура';
		|en = 'Items';
		|it = 'Номенклатура';
		|pl = 'Items';
		|tr = 'Ürün'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Products_Overall";
	ChildOneSet.Parent = New UUID("556f79a2-3f82-4c97-9969-9b389945b3e3");
	ChildOneSet.Used = True;
	ChildOneSet.Ref = New UUID("b03509f2-680f-459b-ac16-d5a7c34ebfc6");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_Assets";
	Set.Ref = New UUID("28ff3dfe-b65d-48f0-af5f-4962cea026ea");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Tài sản đang vận hành';
		|ru = 'Объекты эксплуатации';
		|en = 'Assets';
		|it = 'Объекты эксплуатации';
		|pl = 'Obiekty eksploatacji';
		|tr = 'Varlıklar'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Assets_Overall";
	ChildOneSet.Ref = New UUID("e9a88d39-aeb9-4892-b319-a984ad275132");
	ChildOneSet.Parent = New UUID("28ff3dfe-b65d-48f0-af5f-4962cea026ea");
	ChildOneSet.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_Partners";
	Set.Ref = New UUID("4e3b8c92-3da9-4fe3-9256-c63d89407653");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Bạn hàng';
		|ru = 'Партнеры';
		|en = 'Partners';
		|it = 'Партнеры';
		|pl = 'Partners';
		|tr = 'İş ortakları'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Partners_Overall";
	ChildOneSet.Parent = New UUID("4e3b8c92-3da9-4fe3-9256-c63d89407653");
	ChildOneSet.Used = True;
	ChildOneSet.Ref = New UUID("4b07bb18-b2d4-46f6-b228-c378a280def1");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Partners_Customers";
	ChildOneSet.Parent = New UUID("4e3b8c92-3da9-4fe3-9256-c63d89407653");
	ChildOneSet.Used = True;
	ChildOneSet.Ref = New UUID("6a51863a-02a2-49ca-983f-78eb94939a94");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Khách hàng';
		|ru = 'Клиенты';
		|en = 'Customers';
		|it = 'Клиенты';
		|pl = 'Customers';
		|tr = 'Müşteriler'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Partners_Competitors";
	ChildOneSet.Parent = New UUID("4e3b8c92-3da9-4fe3-9256-c63d89407653");
	ChildOneSet.Used = True;
	ChildOneSet.Ref = New UUID("7038e549-e6d2-4e0c-aa5e-e24045053505");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Đối thủ cạnh tranh';
		|ru = 'Конкуренты';
		|en = 'Competitors';
		|it = 'Конкуренты';
		|pl = 'Competitors';
		|tr = 'Rakipler'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Partners_Vendors";
	ChildOneSet.Parent = New UUID("4e3b8c92-3da9-4fe3-9256-c63d89407653");
	ChildOneSet.Used = True;
	ChildOneSet.Ref = New UUID("f54ac927-da38-4dbe-826b-1b457678d952");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Nhà cung cấp';
		|ru = 'Поставщики';
		|en = 'Vendors';
		|it = 'Поставщики';
		|pl = 'Vendors';
		|tr = 'Tedarikçiler'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Partners_OtherItems";
	ChildOneSet.Parent = New UUID("4e3b8c92-3da9-4fe3-9256-c63d89407653");
	ChildOneSet.Used = True;
	ChildOneSet.Ref = New UUID("75311ade-943a-4914-9e5b-c657c5a9899b");
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Khác';
		|ru = 'Прочие';
		|en = 'Other';
		|it = 'Прочие';
		|pl = 'Other';
		|tr = 'Diğer'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_ItemsBatches";
	Set.Ref = New UUID("a47538d3-e375-45f8-8325-b5948ca9575a");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Sê-ri mặt hàng';
		|ru = 'Серии номенклатуры';
		|en = 'Item batch';
		|it = 'Серии номенклатуры';
		|pl = 'Serii produktów';
		|tr = 'Ürün partisi'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_ItemsBatches_Overall";
	ChildOneSet.Parent = New UUID("a47538d3-e375-45f8-8325-b5948ca9575a");
	ChildOneSet.Ref = New UUID("d9f45df2-85b2-4da1-a1ae-e4c6c44f08bc");
	ChildOneSet.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_ItemsCharacteristics";
	Set.Ref = New UUID("35ae0ba3-fac6-45f2-a8da-35205563d746");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Đặc tính mặt hàng';
		|ru = 'Характеристики номенклатуры';
		|en = 'Item variants';
		|it = 'Характеристики номенклатуры';
		|pl = 'Charakterystyki produktów';
		|tr = 'Ürün varyantları'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_ItemsCharacteristics_Overall";
	ChildOneSet.Parent = New UUID("35ae0ba3-fac6-45f2-a8da-35205563d746");
	ChildOneSet.Ref = New UUID("7c8a1529-810e-4f5a-b5ff-bde9861c75d2");
	ChildOneSet.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_Incidents";
	Set.Ref = New UUID("006d165e-67d7-4813-95f7-30aa2f5dd72a");
	Set.IsFolder = True;
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Sự cố';
		|ru = 'Инциденты';
		|en = 'Incidents';
		|it = 'Инциденты';
		|pl = 'Incidents';
		|tr = 'Olaylar'", LanguagesCodes); // @NStr-2
	
	ChildOneSet = Items.Add();
	ChildOneSet.PredefinedSetName = "Catalog_Incidents_Overall";
	ChildOneSet.Parent = New UUID("006d165e-67d7-4813-95f7-30aa2f5dd72a");
	ChildOneSet.Ref = New UUID("f19ed12e-d5cd-4b1b-b57d-b6d9d0139844");
	ChildOneSet.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(ChildOneSet, "Description",
		"vi = 'Chung';
		|ru = 'Общие';
		|en = 'Common';
		|it = 'Общие';
		|pl = 'Common';
		|tr = 'Genel'", LanguagesCodes); // @NStr-2
	
	Description = "vi = 'Giấy thanh toán tiền tạm ứng';
					|ru = 'Авансовые отчеты';
					|en = 'Expense reports';
					|it = 'Авансовые отчеты';
					|pl = 'Raporty zaliczkowe';
					|tr = 'Gider raporları'"; // @NStr
	AddPropertySetElement(Items, "801f514d-6181-4b90-858d-9162a37587ee", 
	"Document_ExpenseReport", Description, LanguagesCodes);
	
	Description = "vi = 'Biên bản nghiệm thu công việc';
					|ru = 'Акты выполненных работ';
					|en = 'Customer invoices — Services';
					|it = 'Акты выполненных работ';
					|pl = 'Protokoły odbioru';
					|tr = 'İş Tutanakları'"; // @NStr
	AddPropertySetElement(Items, "69506c38-be24-4674-a051-f6c376c09785", 
	"Document_CustomerInvoiceServices", Description, LanguagesCodes);
	
	Description = "vi = 'Biên bản chênh lệch sau khi giao hàng';
					|ru = 'Акты о расхождениях после отгрузки';
					|en = 'Customer invoice disputes';
					|it = 'Акты о расхождениях после отгрузки';
					|pl = 'Protokołu o odchyleniu po wysyłce';
					|tr = 'Teslimat sonrası tutarsızlık raporu'"; // @NStr
	AddPropertySetElement(Items, "ba4c6ae8-37fb-40fb-9da7-d9ac1ababd9f", 
	"Document_DiscrepancyReportFollowingShipment", Description, LanguagesCodes);
	
	Description = "vi = 'Biên bản chênh lệch sau khi điều chuyển';
					|ru = 'Акт о расхождениях после перемещения';
					|en = 'Stock transfer discrepancy report';
					|it = 'Акт о расхождениях после перемещения';
					|pl = 'Protokół o odchyleniu po przemieszczeniu';
					|tr = 'Stok transferi tutarsızlık raporu'"; // @NStr
	AddPropertySetElement(Items, "c1cab76f-caab-4fe3-9e88-8bc81f921d7f", 
	"Document_DiscrepancyReportFollowingTransfer", Description, LanguagesCodes);
	
	Description = "vi = 'Biên bản chênh lệch sau khi chấp nhận';
					|ru = 'Акты о расхождениях после приемки';
					|en = 'Receipt discrepancy reports';
					|it = 'Акты о расхождениях после приемки';
					|pl = 'Protokoły o odchyleniu po przyjęciu';
					|tr = 'Giriş tutarsızlık raporları'"; // @NStr
	AddPropertySetElement(Items, "9c639181-871f-4c71-b22c-51c099c3086b", 
	"Document_DiscrepancyReportFollowingReceipt", Description, LanguagesCodes);
	
	Description = "vi = 'Hủy bỏ phiếu quà tặng';
					|ru = 'Аннулирование подарочных сертификатов';
					|en = 'Void gift card';
					|it = 'Аннулирование подарочных сертификатов';
					|pl = 'Anulowanie certyfikatów podarunkowych';
					|tr = 'Hediye çeklerinin iptali'"; // @NStr
	AddPropertySetElement(Items, "9c5df4e2-4291-46b0-a8ec-d76f8928b905", 
	"Document_GiftCertificateCancellation", Description, LanguagesCodes);
	
	Description = "vi = 'Chứng từ nhập số dư đầu';
					|ru = 'Документы ввода начальных остатков';
					|en = 'OB entry documents';
					|it = 'Документы ввода начальных остатков';
					|pl = 'Dokumenty wprowadzania ostatków początkowych';
					|tr = 'Açılış bakiyelerinin giriş belgeleri'"; // @NStr
	AddPropertySetElement(Items, "64afc2f5-3111-4526-9125-41148861eadb", 
	"Document_OBEntry", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư hạch toán công nợ';
					|ru = 'Ввод остатков взаиморасчетов';
					|en = 'OB entry: AR/AP';
					|it = 'Ввод остатков взаиморасчетов';
					|pl = 'Wprowadzanie ostatków rozliczeń wzajemnych';
					|tr = 'Hesaplaşma bakiyelerinin girişi'"; // @NStr
	AddPropertySetElement(Items, "f92f4b5b-4d75-4ba7-9e5e-d928d4582278", 
	"Document_OBEntryARAP", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư tiền mặt';
					|ru = 'Ввод остатков денежных средств';
					|en = 'OB entry: cash balance';
					|it = 'Ввод остатков денежных средств';
					|pl = 'Wprowadzenie ostatków środków pieniężnych';
					|tr = 'Nakit bakiyelerin girişi'"; // @NStr
	AddPropertySetElement(Items, "107bd5db-91f6-4cc8-8810-2349e91eb948", 
	"Document_OBEntryCash", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư bán hàng trong các kỳ trước';
					|ru = 'Ввод остатков о продажах за прошлые периоды';
					|en = 'OB entry: sales for past periods';
					|it = 'Ввод остатков о продажах за прошлые периоды';
					|pl = 'Wprowadzenie sald sprzedaży za poprzednie okresy';
					|tr = 'Geçmiş dönemlere ait satış bakiyelerinin girişi'"; // @NStr
	AddPropertySetElement(Items, "18589708-cddf-4dba-b816-948afc1fc655", 
	"Document_OBEntrySalesForPastPeriods", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư theo công cụ tài chính';
					|ru = 'Ввод остатков по финансовым инструментам';
					|en = 'OB entry: financial instruments';
					|it = 'Ввод остатков по финансовым инструментам';
					|pl = 'Wprowadzenie sald wg instrumentów finansowych';
					|tr = 'Finansal araç bakiyelerini girme'"; // @NStr
	AddPropertySetElement(Items, "6686df75-1d21-450f-8dd4-b33907ee4d6b", 
	"Document_OBEntryFinancialInstruments", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư chi phí khác';
					|ru = 'Ввод остатков прочие расходы';
					|en = 'OB entry: other expenses';
					|it = 'Ввод остатков прочие расходы';
					|pl = 'Wprowadzenie ostatków inne rozchody';
					|tr = 'Bakiye girişi: Diğer giderler'"; // @NStr
	AddPropertySetElement(Items, "de2acb0b-0893-4ea6-8f0f-2c5e14856961", 
	"Document_OBEntryOtherExpenses", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư tài sản nguồn vốn khác';
					|ru = 'Ввод остатков прочих активов пассивов';
					|en = 'OB entry: other assets and liabilities';
					|it = 'Ввод остатков прочих активов пассивов';
					|pl = 'Wprowadzenie sald innych aktywów pasywów';
					|tr = 'Diğer pasif varlıkların bakiyelerinin girilmesi'"; // @NStr
	AddPropertySetElement(Items, "6ae3cdb3-3831-44c2-9fea-b87154818ff9", 
	"Document_OBEntryOtherAssetsAndLiabilities", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư ban đầu theo thiết bị thanh toán';
					|ru = 'Ввод начальных остатков расчетов по эквайрингу';
					|en = 'OB entry: acquiring contract AR/AP';
					|it = 'Ввод начальных остатков расчетов по эквайрингу';
					|pl = 'Wprowadzenie sald początkowych rozliczeń przez centrum autoryzacyjne';
					|tr = 'Açılış bakiyesi: PoS mutabakatları'"; // @NStr
	AddPropertySetElement(Items, "fb910346-f64d-4b89-9d4b-dd4426bc64a8", 
	"Document_OBEntryAcquiringContractARAP", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư với người tạm ứng';
					|ru = 'Ввод остатков с подотчетниками';
					|en = 'OB entry: AR/AP advance holders';
					|it = 'Ввод остатков с подотчетниками';
					|pl = 'Wprowadzenie sald z osobami odpowiedzialnymi';
					|tr = 'Bakiye girişi: Avans sahipleri'"; // @NStr
	AddPropertySetElement(Items, "12e68b85-c228-4bea-837d-df9122a2b4f7", 
	"Document_OBEntryARAPAdvanceHolders", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập số dư sản phẩm';
					|ru = 'Ввод остатков товаров';
					|en = 'OB entry: goods';
					|it = 'Ввод остатков товаров';
					|pl = 'Wprowadzenie ostatków towarów';
					|tr = 'Ürün bakiyelerinin girişi'"; // @NStr
	AddPropertySetElement(Items, "b4a699ac-aa0d-42c4-b451-ae3d27f23422", 
	"Document_OBEntryGoods", Description, LanguagesCodes);
	
	Description = "vi = 'Đối trừ công nợ';
					|ru = 'Взаимозачеты задолженности';
					|en = 'AR/AP offsets';
					|it = 'Взаимозачеты задолженности';
					|pl = 'Rozliczenia wzajemne zadłużenia';
					|tr = 'Alacak/Borç mahsupları'"; // @NStr
	AddPropertySetElement(Items, "a5b7c017-106e-4373-ac52-fc63f06e1c62", 
	"Document_ARAPSettlement", Description, LanguagesCodes);
	
	Description = "vi = 'Nhập tiền vào quầy thu ngân';
					|ru = 'Внесение денежных средств в кассу ККМ';
					|en = 'Put cash in the cash register';
					|it = 'Внесение денежных средств в кассу ККМ';
					|pl = 'Wpłata środków pieniężnych do kasy';
					|tr = 'Yazar kasa hesabına nakit yatırma'"; // @NStr
	AddPropertySetElement(Items, "418fab75-e201-4dc6-abac-8f2aa6c8a8a6", 
	"Document_DepositCashIntoCashRegister", Description, LanguagesCodes);
	
	Description = "vi = 'Chứng từ tiêu dùng hàng hóa nội bộ';
					|ru = 'Документы внутреннего потребления товаров';
					|en = 'Inventory consumptions — Non-operational activities';
					|it = 'Документы внутреннего потребления товаров';
					|pl = 'Dokumenty na rozchód materiałów';
					|tr = 'Stok tüketim belgeleri'"; // @NStr
	AddPropertySetElement(Items, "39594b94-13bb-44eb-bcc3-6c3c03f38380", 
	"Document_InventoryConsumption", Description, LanguagesCodes);
	
	Description = "vi = 'Nhận lại hàng hóa giữa các doanh nghiệp';
					|ru = 'Возвраты товаров между организациями';
					|en = 'Goods return — Intercompany';
					|it = 'Возвраты товаров между организациями';
					|pl = 'Zwroty towarów pomiędzy firmami';
					|tr = 'İşyerleri arası ürün iadeleri'"; // @NStr
	AddPropertySetElement(Items, "bfdfd72c-5524-4bea-b2d2-bf46d127d224", 
	"Document_IntercompanyGoodsReturn", Description, LanguagesCodes);
	
	Description = "vi = 'Nhận hàng bán bị trả lại';
					|ru = 'Возвраты товаров от клиентов';
					|en = 'Sales returns';
					|it = 'Возвраты товаров от клиентов';
					|pl = 'Zwroty towarów od klientów';
					|tr = 'Müşteriden gelen ürün iadesi'"; // @NStr
	AddPropertySetElement(Items, "60bcfb69-ab90-4d19-b35b-f542da756f07", 
	"Document_ReturnOfGoodsFromCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách trả lại nhà cung cấp';
					|ru = 'Список возвратов поставщикам';
					|en = 'List of returns to vendors';
					|it = 'Список возвратов поставщикам';
					|pl = 'Lista zwrotów do dostawców';
					|tr = 'Tedarikçiden iadelerin listesi'"; // @NStr
	AddPropertySetElement(Items, "ea84fc70-303e-486d-b07c-41fa4b2ddd0a", 
	"Document_ReturnOfGoodsToVendor", Description, LanguagesCodes);
	
	Description = "vi = 'Rút tiền từ quầy thu ngân';
					|ru = 'Выемка денежных средств из кассы ККМ';
					|en = 'Take cash out of cash register';
					|it = 'Выемка денежных средств из кассы ККМ';
					|pl = 'Wyjęcie środków pieniężnych z kasy fiskalnej';
					|tr = 'Yazar kasa hesabından nakit para çekimi'"; // @NStr
	AddPropertySetElement(Items, "7293ce55-1397-45cb-8951-de6fad85a001", 
	"Document_CashWithdrawalFromCashRegister", Description, LanguagesCodes);
	
	Description = "vi = 'Mua lại bao bì luân chuyển khách hàng';
					|ru = 'Выкупы возвратной тары клиентами';
					|en = 'Returnable packaging redemptions by customers';
					|it = 'Выкупы возвратной тары клиентами';
					|pl = 'Wykupy tary zwrotnej przez klienta';
					|tr = 'Müşteri tarafından iade edilebilir ambalajın itfaları'"; // @NStr
	AddPropertySetElement(Items, "5a5cc4ba-7ac4-4b29-ae6c-ba1b7fb46d9a", 
	"Document_ReturnablePackagingRedemptionByCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Mua lại bao bì luân chuyển nhà cung cấp';
					|ru = 'Выкупы возвратной тары у поставщиков';
					|en = 'Redemptions of returnable packaging from vendors';
					|it = 'Выкупы возвратной тары у поставщиков';
					|pl = 'Wykup tary zwrotnej od dostawcy';
					|tr = 'Tedarikçiden iade edilebilir ambalajın itfaları'"; // @NStr
	AddPropertySetElement(Items, "a7d515df-add9-450c-a332-916a6790303f", 
	"Document_RedemptionOfReturnablePackagingFromVendor", Description, LanguagesCodes);
	
	Description = "vi = 'Mua lại hàng hóa từ kho bảo quản';
					|ru = 'Выкупы товаров с хранения';
					|en = 'Purchase invoice — VMI';
					|it = 'Выкупы товаров с хранения';
					|pl = 'Wykupy towarów z depozytu';
					|tr = 'Depodan mal itfaları'"; // @NStr
	AddPropertySetElement(Items, "63fdb30c-5b2f-4dad-b4b9-e1dd907d30e8", 
	"Document_RedemptionOfGoodsFromStorage", Description, LanguagesCodes);
	
	Description = "vi = 'Mua lại hàng hóa bởi bên bảo quản';
					|ru = 'Выкупы товаров хранителем';
					|en = 'Sales invoices — VMI sold';
					|it = 'Выкупы товаров хранителем';
					|pl = 'Wykupy towarów opiekunem';
					|tr = 'Satış faturası - Satılan VMI'"; // @NStr
	AddPropertySetElement(Items, "8a8bd71e-7dba-4e2c-ac68-4a54c23d6a0b", 
	"Document_RedemptionOfGoodsByCustodian", Description, LanguagesCodes);
	
	Description = "vi = 'Biến động tài sản và nguồn vốn khác';
					|ru = 'Движения прочих активов и пассивов';
					|en = 'Flow of other assets and liabilities';
					|it = 'Движения прочих активов и пассивов';
					|pl = 'Ruchy innych aktywów i zobowiązań';
					|tr = 'İşletme dışı varlık ve borçların kaydı'"; // @NStr
	AddPropertySetElement(Items, "2b4670d0-c81c-4939-9e8d-4de3cca5f43f", 
	"Document_MovementOfOtherAssetsAndLiabilities", Description, LanguagesCodes);
	
	Description = "vi = 'Giấy ủy quyền';
					|ru = 'Доверенности';
					|en = 'Authorization letters';
					|it = 'Доверенности';
					|pl = 'Authorization letters';
					|tr = 'Yetki belgeleri'"; // @NStr
	AddPropertySetElement(Items, "95848746-ee8c-459b-b52c-ec376c88b51a", 
	"Document_IssuedLetterOfAuthority", Description, LanguagesCodes);
	
	Description = "vi = 'Nhiệm vụ vận chuyển';
					|ru = 'Задания на перевозку';
					|en = 'Itineraries';
					|it = 'Задания на перевозку';
					|pl = 'Zadania przewozu';
					|tr = 'Taşıma planı'"; // @NStr
	AddPropertySetElement(Items, "1536e0a2-1247-4057-b129-662f18baabbf", 
	"Document_TransportationJob", Description, LanguagesCodes);
	
	Description = "vi = 'Nhiệm vụ đối với đại diện thương mại';
					|ru = 'Задания торговым представителям';
					|en = 'Sales representative tasks';
					|it = 'Задания торговым представителям';
					|pl = 'Zadania dla przedstawicieli handlowych';
					|tr = 'Satış temsilcisinin görevleri'"; // @NStr
	AddPropertySetElement(Items, "60ef6213-9b62-46c9-8484-110edab7dc1d", 
	"Document_JobForSalesRepresentative", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách đơn hàng khách hàng';
					|ru = 'Список заказов клиентов';
					|en = 'Sales order list';
					|it = 'Список заказов клиентов';
					|pl = 'Lista zamówień sprzedaży';
					|tr = 'Müşteri sipariş listesi'"; // @NStr
	AddPropertySetElement(Items, "03dd5357-8b34-4da5-a195-8798e22640a3", 
	"Document_SalesOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn hàng tiêu dùng nội bộ';
					|ru = 'Заказы на внутреннее потребление';
					|en = 'Inventory consumption orders';
					|it = 'Заказы на внутреннее потребление';
					|pl = 'Zamówienia na konsumpcję wewnętrzną';
					|tr = 'İç tüketim emirleri'"; // @NStr
	AddPropertySetElement(Items, "9d859cfe-35a8-4239-a26b-39afc8da2d24", 
	"Document_InventoryConsumptionOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn hàng điều chuyển nội bộ';
					|ru = 'Заказы на перемещение';
					|en = 'Transfer orders';
					|it = 'Заказы на перемещение';
					|pl = 'Zamówienia na przesunięcie';
					|tr = 'Transfer siparişleri'"; // @NStr
	AddPropertySetElement(Items, "2c31eee1-7175-4dda-bbd7-f55f0a4c3f42", 
	"Document_TransferOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn hàng đóng bộ (tách bộ)';
					|ru = 'Заказы на сборку (разборку)';
					|en = 'Kitting orders';
					|it = 'Заказы на сборку (разборку)';
					|pl = 'Zamówienia na montaż (demontaż)';
					|tr = 'Montaj için siparişler (demontaj)'"; // @NStr
	AddPropertySetElement(Items, "4c278a13-c0bb-407f-8bb3-6428eebc2d61", 
	"Document_ByAssemblyDisassemblyOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách đơn hàng đặt nhà cung cấp';
					|ru = 'Список заказов поставщикам';
					|en = 'Purchase order list';
					|it = 'Список заказов поставщикам';
					|pl = 'Rejestr dokumentów';
					|tr = 'Satın alma siparişleri listesi'"; // @NStr
	AddPropertySetElement(Items, "33eedfd9-352b-4d54-88ae-739511f8e846", 
	"Document_PurchaseOrder", Description, LanguagesCodes);
	
	Description = "ru = 'Заявки на обеспечение';
					|vi = 'Provision requests';
					|en = 'Provision requests';
					|it = 'Provision requests';
					|pl = 'Provision requests';
					|tr = 'Tedarik talepleri'"; // @NStr
	AddPropertySetElement(Items, "46ead614-6e00-11f0-bd11-e89c25df8ebe", 
	"Document_ApplicationForCollateral", Description, LanguagesCodes);
	
	Description = "ru = 'Заявки на закупку';
					|vi = 'Purchase requests';
					|en = 'Purchase requests';
					|it = 'Purchase requests';
					|pl = 'Purchase requests';
					|tr = 'Satın alma talepleri'"; // @NStr
	AddPropertySetElement(Items, "46ead615-6e00-11f0-bd11-e89c25df8ebe", 
	"Document_PurchaseRequest", Description, LanguagesCodes);
	
	Description = "vi = 'Giấy đề nghị trả hàng từ người mua';
					|ru = 'Заявки на возврат товаров от клиентов';
					|en = 'Sales return requests';
					|it = 'Заявки на возврат товаров от клиентов';
					|pl = 'Wnioski o zwrot towarów od klientów';
					|tr = 'Müşteriden mal iadesi talebi'"; // @NStr
	AddPropertySetElement(Items, "4342fadf-1cdd-4d59-b2e3-05d19be6ade5", 
	"Document_RequestForReturnOfGoodsFromCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách giấy đề nghị thanh toán';
					|ru = 'Список заявок на расходование ДС';
					|en = 'List of payment requests';
					|it = 'Список заявок на расходование ДС';
					|pl = 'Lista wniosków o wydatkowanie środków pieniężnych';
					|tr = 'Fon harcamaları için talep listesi'"; // @NStr
	AddPropertySetElement(Items, "7b4d5dbb-b0a9-4d4f-b245-46d2709dad8a", 
	"Document_PaymentRequest", Description, LanguagesCodes);
	
	Description = "vi = 'Yêu cầu nhập hàng từ liên minh kinh tế Á-Âu';
					|ru = 'Заявления о ввозе товаров из ЕАЭС';
					|en = 'Applications for goods import from EAEU';
					|it = 'Заявления о ввозе товаров из ЕАЭС';
					|pl = 'Oświadczenia o imporcie towarów z EUG';
					|tr = 'AEB''den mal ithalatı için yapılan başvurular'"; // @NStr
	AddPropertySetElement(Items, "2917737a-b940-4157-bb6f-2f43049f3efa", 
	"Document_ApplicationForImportationOfGoods", Description, LanguagesCodes);
	
	Description = "vi = 'Thay đổi phân loại';
					|ru = 'Изменение ассортимента';
					|en = 'Product range change';
					|it = 'Изменение ассортимента';
					|pl = 'Zmiana asortymentu';
					|tr = 'Ürün gamı değişimi'"; // @NStr
	AddPropertySetElement(Items, "66bbaa92-0c69-4ea8-8dc7-2d03e85b0980", 
	"Document_ProductRangeChange", Description, LanguagesCodes);
	
	Description = "vi = 'Bản kiểm kê';
					|ru = 'Инвентаризационные описи';
					|en = 'Physical inventory registers';
					|it = 'Инвентаризационные описи';
					|pl = 'Spisy inwentaryzacyjne';
					|tr = 'Envanter listeleri'"; // @NStr
	AddPropertySetElement(Items, "ed4dc447-ec20-46ec-b121-44d738325b89", 
	"Document_PhysicalCountReport", Description, LanguagesCodes);
	
	Description = "vi = 'Kiểm kê tiền mặt';
					|ru = 'Инвентаризации наличных ДС';
					|en = 'Petty cash audits';
					|it = 'Инвентаризации наличных ДС';
					|pl = 'Inwentaryzacja środków gotówkowych';
					|tr = 'Nakit fiziksel stok sayımı'"; // @NStr
	AddPropertySetElement(Items, "ffe2909c-7dbe-47c0-b880-1c31f34f007d", 
	"Document_PhysicalCountOfCashAccounts", Description, LanguagesCodes);
	
	Description = "vi = 'Báo giá cho khách hàng';
					|ru = 'Коммерческие предложения клиентам';
					|en = 'Sales quotations';
					|it = 'Коммерческие предложения клиентам';
					|pl = 'Oferty komercyjne do klientów';
					|tr = 'Müşterilere sunulan satış teklifleri'"; // @NStr
	AddPropertySetElement(Items, "efefe76a-2f6a-43be-a4d2-72ff08a6618f", 
	"Document_CommercialProposalForCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh lịch biểu hạch toán công nợ';
					|ru = 'Корректировки графика взаиморасчетов';
					|en = 'AR/AP accounting schedule adjustments';
					|it = 'AR/AP accounting schedule adjustments';
					|pl = 'AR/AP accounting schedule adjustments';
					|tr = 'Alacak/borç muhasebesi planının düzeltilmesi'"; // @NStr
	AddPropertySetElement(Items, "19200cc1-040f-4ff1-a667-ae81feaac1f0", 
	"Document_ARAPAccountingScheduleAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh kế hoạch nhu cầu';
					|ru = 'Корректировки плановых потребностей';
					|en = 'Planned demand adjustments';
					|it = 'Корректировки плановых потребностей';
					|pl = 'Korekty planowanych potrzeb';
					|tr = 'Planlanan gereksinimlerde yapılan düzeltmeler'"; // @NStr
	AddPropertySetElement(Items, "0f4f8e3b-a8c8-48e4-90df-6dcc152e68fa", 
	"Document_AdjustmentOfPlannedDemand", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh mua hàng';
					|ru = 'Корректировки приобретений';
					|en = 'Purchase adjustments';
					|it = 'Корректировки приобретений';
					|pl = 'Korekty dokumentów zakupowych ';
					|tr = 'Satın alma düzeltmeleri'"; // @NStr
	AddPropertySetElement(Items, "ff1efb04-feed-495b-8b39-8e7da0cb097f", 
	"Document_PurchaseAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh hạch toán với người nhận tạm ứng';
					|ru = 'Корректировки расчетов с подотчетными лицами';
					|en = 'Adjustments of AR/AP accounting with advance holders';
					|it = 'Adjustments of AR/AP accounting with advance holders';
					|pl = 'Adjustments of AR/AP accounting with advance holders';
					|tr = 'Avans sahibi kişilerle yapılan hesaplama düzeltmeleri'"; // @NStr
	AddPropertySetElement(Items, "c40cbb36-a7a5-4213-a8ed-bb788eaf289a", 
	"Document_AdjustmentOfARAPAccountingForAdvanceHolders", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh bán hàng';
					|ru = 'Корректировки реализаций';
					|en = 'Sales adjustments';
					|it = 'Корректировки реализаций';
					|pl = 'Korekta sprzedaży';
					|tr = 'Satış düzeltmesi'"; // @NStr
	AddPropertySetElement(Items, "14fd2e36-20f8-4b9f-883f-28676d24993e", 
	"Document_SaleAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh biểu ghi';
					|ru = 'Корректировка регистров';
					|en = 'Register adjustment';
					|it = 'Корректировка регистров';
					|pl = 'Korekta rejestrów';
					|tr = 'Kayıtları düzeltme'"; // @NStr
	AddPropertySetElement(Items, "5e071822-b125-446d-8785-8369f551153d", 
	"Document_RegisterAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Tính thuế GTGT hoàn lại';
					|ru = 'Начисления реверсивного НДС';
					|en = 'Reverse VAT charge accruals';
					|it = 'Начисления реверсивного НДС';
					|pl = 'Naliczenia odwrotnego VAT';
					|tr = 'Tersine KDV tahakkukları'"; // @NStr
	AddPropertySetElement(Items, "9d37be73-5f56-44ed-b443-6debbd0c1c00", 
	"Document_ReverseVATAccrual", Description, LanguagesCodes);
	
	Description = "vi = 'Cộng và trừ điểm thưởng';
					|ru = 'Начисления и списания бонусных баллов';
					|en = 'Accrual and write-off of bonus points';
					|it = 'Начисления и списания бонусных баллов';
					|pl = 'Naliczanie i rozchód punktów bonusowych';
					|tr = 'Bonus puanların tahakkuk edilmesi ve silinmesi'"; // @NStr
	AddPropertySetElement(Items, "5614c32b-f2ca-4a87-99f1-b59c6e669cd4", 
	"Document_AccrueAndDeductionOfBonusPoints", Description, LanguagesCodes);
	
	Description = "vi = 'Định mức phân bổ kế hoạch bán hàng theo thể loại';
					|ru = 'Нормативы распределения планов продаж по категориям';
					|en = 'Distribution standards of product categories';
					|it = 'Нормативы распределения планов продаж по категориям';
					|pl = 'Normatywy przydziału planów sprzedaży wg kategorii';
					|tr = 'Kategoriler göre satış tahmini için dağılım standartları'"; // @NStr
	AddPropertySetElement(Items, "fe22e6fd-0818-4dd3-87b2-400d60777c16", 
	"Document_SalesPlansAllocationBaseByCategories", Description, LanguagesCodes);
	
	Description = "vi = 'Thu tiền dự tính';
					|ru = 'Ожидаемые поступления ДС';
					|en = 'Planned cash inflows';
					|it = 'Ожидаемые поступления ДС';
					|pl = 'Oczekiwane wpłaty środków pieniężnych';
					|tr = 'Beklenen nakit girişleri'"; // @NStr
	AddPropertySetElement(Items, "66c0227a-8d36-40fe-85f6-18ff19fccbb5", 
	"Document_PlannedCashReceipt", Description, LanguagesCodes);
	
	Description = "vi = 'Giao dịch thẻ thanh toán';
					|ru = 'Эквайринговые операции';
					|en = 'Acquiring transactions';
					|it = 'Эквайринговые операции';
					|pl = 'Operacje acquiringowe';
					|tr = 'PoS işlemleri'"; // @NStr
	AddPropertySetElement(Items, "53523743-007a-4cb4-b4c8-fbf16c2af464", 
	"Document_PaymentCardTransaction", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi tăng hàng thừa';
					|ru = 'Оприходования излишков товаров';
					|en = 'Stock surplus recognition';
					|it = 'Оприходования излишков товаров';
					|pl = 'Przyjęcie na stan wewnętrzne ';
					|tr = 'Stok fazlası tahakkuku'"; // @NStr
	AddPropertySetElement(Items, "f3940a0a-9396-402d-a823-85a709757c62", 
	"Document_InventorySurplusRecognition", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi tăng hàng thừa đối với mặt hàng đã giao';
					|ru = 'Оприходования излишков отгруженных товаров';
					|en = 'Stock surpluses of shipped goods';
					|it = 'Stock surpluses of shipped goods';
					|pl = 'Stock surpluses of shipped goods';
					|tr = 'Sevk edilen stok fazlası ürünlerin kabulü'"; // @NStr
	AddPropertySetElement(Items, "46f35046-5db1-4da9-83f6-b4cd9f83905b", 
	"Document_RecognitionOfStockSurplusShippedToCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu phản ánh hàng thừa';
					|ru = 'Ордера на отражение излишков товаров';
					|en = 'Stock surplus notes';
					|it = 'Ордера на отражение излишков товаров';
					|pl = 'Polecenia na prze klasyfikacje towarów';
					|tr = 'Stok fazlası yansıtılması için siparişler'"; // @NStr
	AddPropertySetElement(Items, "616278ec-2a6f-41a8-bc6d-25f24b3a536a", 
	"Document_GoodsSurplusesNote", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu phản ánh hàng thiếu';
					|ru = 'Ордера на отражение недостач товаров';
					|en = 'Stock shortage notes';
					|it = 'Ордера на отражение недостач товаров';
					|pl = 'Polecenia na prze klasyfikacje towarów';
					|tr = 'Ürün eksikliklerinin yansıması siparişi'"; // @NStr
	AddPropertySetElement(Items, "5c000661-739b-4b1c-bbc4-b6d09a67a5d5", 
	"Document_GoodsShortageNote", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu phản ánh của việc sắp xếp lại hàng hóa';
					|ru = 'Ордера на отражение пересортицы товаров';
					|en = 'Stock reclass notes';
					|it = 'Ордера на отражение пересортицы товаров';
					|pl = 'Polecenia na prze klasyfikacje towarów';
					|tr = 'Stok yeniden sınıflandırması yansıması için siparişler'"; // @NStr
	AddPropertySetElement(Items, "bfa5aba5-2304-4ea6-bef5-191adb786e6a", 
	"Document_GoodsMisgradingNote", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu phản ánh hàng hỏng';
					|ru = 'Ордера на отражение порчи товаров';
					|en = 'Stock quality change notes';
					|it = 'Ордера на отражение порчи товаров';
					|pl = 'Polecenia na prze klasyfikacje towarów';
					|tr = 'Ürün stok kalite değişikliği yansıma siparişleri'"; // @NStr
	AddPropertySetElement(Items, "fdbb8c46-6fd4-4ee9-a6e4-802b20491a31", 
	"Document_DamageNote", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu chuyển kho';
					|ru = 'Ордера на перемещение товаров';
					|en = 'Internal stock transfer';
					|it = 'Ордера на перемещение товаров';
					|pl = 'Zlecenia przemieszczenia towarów';
					|tr = 'Dahili stok transferi'"; // @NStr
	AddPropertySetElement(Items, "234b1bcf-7f61-481a-8cc6-00fe315d25d9", 
	"Document_GoodsTransferNote", Description, LanguagesCodes);
	
	Description = "vi = 'Lấy ra (xếp vào) hàng hóa';
					|ru = 'Отборы (размещения) товаров';
					|en = 'Intra-warehouse transfers';
					|it = 'Отборы (размещения) товаров';
					|pl = 'Filtr (rozmieszczenia) wierszy pozycji';
					|tr = 'Ürün filtreleri (yerleştirme)'"; // @NStr
	AddPropertySetElement(Items, "75841b9d-7294-44f4-9d25-d978fd71bf2e", 
	"Document_GoodsPickingPlacement", Description, LanguagesCodes);
	
	Description = "vi = 'Giao hàng cho khách';
					|ru = 'Отгрузка товаров клиентам';
					|en = 'Goods shipment to customers';
					|it = 'Goods shipment to customers';
					|pl = 'Goods shipment to customers';
					|tr = 'Müşterinin ürünlerinin sevkiyatı'"; // @NStr
	AddPropertySetElement(Items, "6b0018c6-9353-4e4b-9dc4-189db10560ae", 
	"Document_GoodsShipmentToCustomer", Description, LanguagesCodes);

	Description = "vi = 'Xuất hàng từ kho bảo quản';
					|ru = 'Отгрузка товаров с хранения';
					|en = 'VMI pick-up request from vendor';
					|it = 'Отгрузка товаров с хранения';
					|pl = 'Wysyłka towarów z przechowywania';
					|tr = 'Malların VMI''dan sevkiyat talebi'"; // @NStr
	AddPropertySetElement(Items, "a3b6b141-52ea-479b-aa08-eb5e89cba5e9", 
	"Document_GoodsShipmentFromStorage", Description, LanguagesCodes);
	
	Description = "vi = 'Chênh lệch khi chuyển tiền nội bộ';
					|ru = 'Расхождения при инкассации денежных средств';
					|en = 'Cash deposit/withdrawal discrepancies';
					|it = 'Расхождения при инкассации денежных средств';
					|pl = 'Odchylenie podczas inkasacji środków pieniężnych';
					|tr = 'Nakit yatırma sırasında tutarsızlıklar'"; // @NStr
	AddPropertySetElement(Items, "e2352c1d-e5f2-4bb3-a054-db4b8cd70fbc", 
	"Document_CashDepositWithdrawalDiscrepancies", Description, LanguagesCodes);
	
	Description = "vi = 'Báo cáo của ngân hàng về dịch vụ thẻ thanh toán';
					|ru = 'Отчеты банков по эквайрингу';
					|en = 'Merchant statements';
					|it = 'Отчеты банков по эквайрингу';
					|pl = 'Raporty banku z acquiringu';
					|tr = 'Hesap ekstreleri'"; // @NStr
	AddPropertySetElement(Items, "01f2e38d-a7be-4b85-8149-e86a6f8ccb25", 
	"Document_BankReportOnAcquiringTransactions", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng bán của người nhận ký gửi (đại lý)';
					|ru = 'Отчеты комиссионеров (агентов) о продажах';
					|en = 'Consignment issue notifications';
					|it = 'Отчеты комиссионеров (агентов) о продажах';
					|pl = 'Raporty komisantów (agentów) ze sprzedaży';
					|tr = 'Komisyon yetkililerinin (acentelerin) satış raporları'"; // @NStr
	AddPropertySetElement(Items, "f56976e3-473e-4a42-8505-d9c0f09ccd8c", 
	"Document_ConsignmentReportFromCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê ghi giảm hàng bán của người nhận ký gửi';
					|ru = 'Отчеты комиссионеров о списании';
					|en = 'Consignment stock adjustments';
					|it = 'Отчеты комиссионеров о списании';
					|pl = 'Raporty komisantów z rozchodu';
					|tr = 'Komisyon acentesi stok düzeltme raporu'"; // @NStr
	AddPropertySetElement(Items, "c5f01e92-cd38-4fdd-bb4f-dc35947f60e8", 
	"Document_WriteOffReportFromCommissionAgent", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
					|ru = 'Отчеты комитентам (принципалам) о продажах';
					|en = 'Consignment notifications — Intercompany';
					|it = 'Отчеты комитентам (принципалам) о продажах';
					|pl = 'Raporty dla komitentów (zleceniodawców) ze sprzedaży';
					|tr = 'Konsinye uzlaşma bildirimleri'"; // @NStr
	AddPropertySetElement(Items, "98063dee-6c0a-44bf-b171-db4c80a01f43", 
	"Document_ConsignmentReportToVendor", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
					|ru = 'Отчеты комитентам (принципалам) о закупках';
					|en = 'Purchase notifications';
					|it = 'Отчеты комитентам (принципалам) о закупках';
					|pl = 'Raporty komitentom (zleceniodawcom) o zakupach';
					|tr = 'Satın alma bildirimleri'"; // @NStr
	AddPropertySetElement(Items, "b415714a-0fac-4ed8-ac1d-2d9acb3d5486", 
	"Document_PurchasingReportToConsignorPrincipal", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê ghi giảm hàng hóa dành cho người đặt ký gửi';
					|ru = 'Отчеты комитентам о списании';
					|en = 'Write-off consignment notifications';
					|it = 'Отчеты комитентам о списании';
					|pl = 'Raporty z rozchodów dla komitentów';
					|tr = 'Tedarikçi konsinye stok ayarlamaları'"; // @NStr
	AddPropertySetElement(Items, "645176c8-de13-49ba-a171-daadf684a1df", 
	"Document_PurchaseInvoiceConsignmentStockLost", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng hóa bán lẻ trả lại';
					|ru = 'Отчеты о розничных возвратах';
					|en = 'Retail return reports';
					|it = 'Отчеты о розничных возвратах';
					|pl = 'Raporty o zwrotach detalicznych';
					|tr = 'Perakende i̇ade raporları'"; // @NStr
	AddPropertySetElement(Items, "87408fa0-fcbe-aeb4-88a2-d6778ccdae67", 
	"Document_RetailReturnsReport", Description, LanguagesCodes);	
	
	Description = "vi = 'Bảng kê bán lẻ hàng hóa';
					|ru = 'Отчеты о розничных продажах';
					|en = 'Retail reports';
					|it = 'Отчеты о розничных продажах';
					|pl = 'Raporty ze sprzedaży detalicznych';
					|tr = 'Perakende satış raporları'"; // @NStr
	AddPropertySetElement(Items, "84708af0-bfce-4aeb-8a28-e7687cdcae76", 
	"Document_RetailSalesReport", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi giảm hàng đã giao';
					|ru = 'Списания отгруженных товаров';
					|en = 'Shipped goods write-offs';
					|it = 'Shipped goods write-offs';
					|pl = 'Shipped goods write-offs';
					|tr = 'Sevk edilen ürünlerin gider yazılması'"; // @NStr
	AddPropertySetElement(Items, "02214fff-b37e-4819-a630-691a9197cd68", 
	"Document_WriteOffOfShippedGoods", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng bán ký gửi';
					|ru = 'Отчеты по комиссии';
					|en = 'Commission reports';
					|it = 'Отчеты по комиссии';
					|pl = 'Raporty o komisji';
					|tr = 'Komisyon raporları'"; // @NStr
	AddPropertySetElement(Items, "c8c8e810-dad6-4bca-8acc-e1649a0814a0", 
	"Document_CommissionReportIntercompany", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng bán ký gửi';
					|ru = 'Отчеты по комиссии';
					|en = 'Commission reports';
					|it = 'Отчеты по комиссии';
					|pl = 'Raporty o komisji';
					|tr = 'Komisyon raporları'"; // @NStr
	AddPropertySetElement(Items, "04325bfb-d094-4560-9806-2065b07f979f", 
	"Document_CommissionWriteOffReportIntercompany", Description, LanguagesCodes);
	
	Description = "vi = 'Chuyển giao hàng hóa';
					|ru = 'Передачи товаров';
					|en = 'Goods transfers';
					|it = 'Передачи товаров';
					|pl = 'Transfery towarów';
					|tr = 'Ürünlerin transferi'"; // @NStr
	AddPropertySetElement(Items, "348b9fd2-2329-474f-82a9-801314db98d0", 
	"Document_CustomerInvoiceIntercompany", Description, LanguagesCodes);
	
	Description = "vi = 'Chuyển giao hàng hóa cho bên bảo quản/người nhận ký gửi';
					|ru = 'Передачи товаров хранителям/комиссионерам';
					|en = 'Put away goods to custodian or agent';
					|it = 'Передачи товаров хранителям/комиссионерам';
					|pl = 'Przeniesienia towarów do depozytariuszy/komisantów';
					|tr = 'Konsinye/emanetçiden tarafından ürün transferi'"; // @NStr
	AddPropertySetElement(Items, "d1c2fbba-bdc4-4132-9bde-06277de9fc58", 
	"Document_TransferOfGoodsToBailee", Description, LanguagesCodes);
	
	Description = "vi = 'Chứng từ điều chuyển hàng hóa nội bộ';
					|ru = 'Документы перемещения товаров';
					|en = 'Goods transfer documents';
					|it = 'Документы перемещения товаров';
					|pl = 'Dokumenty przesunięcie towarów';
					|tr = 'Ürün transfer belgeleri'"; // @NStr
	AddPropertySetElement(Items, "e9017c23-1928-40d1-96ac-abdd536071b2", 
	"Document_InventoryTransfer", Description, LanguagesCodes);
	
	Description = "vi = 'Chuyển tồn hàng hóa';
					|ru = 'Пересортицы товаров';
					|en = 'Stock reclass';
					|it = 'Пересортицы товаров';
					|pl = 'Prze-klasyfikacja towarów';
					|tr = 'Stok yeniden sınıflandırmaları'"; // @NStr
	AddPropertySetElement(Items, "a102a711-55fe-4252-8c97-70dd11e9b77d", 
	"Document_GoodsMisgrading", Description, LanguagesCodes);
	
	Description = "vi = 'Chuyển tồn hàng hóa ở bên bảo quản';
					|ru = 'Пересортицы товаров у хранителей';
					|en = 'Stock reclass at custodians';
					|it = 'Пересортицы товаров у хранителей';
					|pl = 'Przeklasyfikowania towarów u opiekuna';
					|tr = 'VMI stoku yeniden sınıflandırma'"; // @NStr
	AddPropertySetElement(Items, "7ba77144-f8a4-48d4-8de4-8636e134ebc4", 
	"Document_MisgradingOfGoodsAtCustodian", Description, LanguagesCodes);
	
	Description = "vi = 'Kiểm đếm hàng hóa';
					|ru = 'Пересчеты товаров';
					|en = 'Inventory count sheets';
					|it = 'Пересчеты товаров';
					|pl = 'Inwentaryzacja';
					|tr = 'Stok sayımı'"; // @NStr
	AddPropertySetElement(Items, "53061e7a-7187-460d-97b3-3b78c328a839", 
	"Document_InventoryRecount", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch nhu cầu nội bộ';
					|ru = 'Планы внутренних потреблений';
					|en = 'Inventory consumption plans';
					|it = 'Планы внутренних потреблений';
					|pl = 'Plany konsumpcji wewnętrznych';
					|tr = 'İç tüketim planları'"; // @NStr
	AddPropertySetElement(Items, "82333b2a-3cbf-4891-8032-a8d37f312576", 
	"Document_InventoryConsumptionPlan", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch mua hàng';
					|ru = 'Планы закупок';
					|en = 'Purchase plans';
					|it = 'Планы закупок';
					|pl = 'Plany zakupu';
					|tr = 'Satın alma planları'"; // @NStr
	AddPropertySetElement(Items, "8ef37129-a607-401b-8ab6-b437402a7e03", 
	"Document_PurchasePlan", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch số dư';
					|ru = 'Планы остатков';
					|en = 'Goods stock plans';
					|it = 'Планы остатков';
					|pl = 'Plany sald';
					|tr = 'Mal stok planları'"; // @NStr
	AddPropertySetElement(Items, "413d6ed2-8438-4142-8cf9-1ba6b7e906ff", 
	"Document_PlanOfGoodsStock", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch bán hàng theo mặt hàng';
					|ru = 'Планы продаж по номенклатуре';
					|en = 'Sales forecasts by items';
					|it = 'Планы продаж по номенклатуре';
					|pl = 'Plany sprzedaży według nomenklatury';
					|tr = 'Ürünlere göre satış tahminleri'"; // @NStr
	AddPropertySetElement(Items, "6cfc9e82-d818-4f58-a56a-d2ddeaf180f4", 
	"Document_SalesPlan", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch bán hàng theo thể loại';
					|ru = 'Планы продаж по категориям';
					|en = 'Sales forecasts by categories';
					|it = 'Планы продаж по категориям';
					|pl = 'Plany sprzedaży wg kategorii';
					|tr = 'Kategorilere göre satış tahminleri'"; // @NStr
	AddPropertySetElement(Items, "18e96531-e429-459a-bd3c-32fb78e8b467", 
	"Document_SalesPlanByCategories", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch đóng bộ (tách bộ)';
					|ru = 'Планы сборки (разборки)';
					|en = 'Kitting plans';
					|it = 'Планы сборки (разборки)';
					|pl = 'Plany montażu (demontażu)';
					|tr = 'Montaj (demontaj) programı'"; // @NStr
	AddPropertySetElement(Items, "e375b2b8-f36b-4131-b358-2e210a6f4ec2", 
	"Document_AssemblyDisassemblyPlan", Description, LanguagesCodes);
	
	Description = "vi = 'Giao hàng cho bên vận chuyển';
					|ru = 'Поручения экспедиторам';
					|en = 'Delivery requests';
					|it = 'Поручения экспедиторам';
					|pl = 'Zamówienie na transport';
					|tr = 'Teslimat talepleri'"; // @NStr
	AddPropertySetElement(Items, "4fce3a52-74d5-4abc-9c82-437107cc2a9d", 
	"Document_InstructionForShippingAgent", Description, LanguagesCodes);
	
	Description = "vi = 'Hàng hỏng';
					|ru = 'Порчи товаров';
					|en = 'Stock quality changes';
					|it = 'Порчи товаров';
					|pl = 'Rejestr uszkodzenia towarów';
					|tr = 'Ürün stok kalite değişikliği'"; // @NStr
	AddPropertySetElement(Items, "6468b535-c213-4b70-b39b-2275a88674a3", 
	"Document_GoodsDamage", Description, LanguagesCodes);
	
	Description = "vi = 'Hàng hỏng tại nơi cất giữ';
					|ru = 'Порчи товаров у хранителей';
					|en = 'VMI quality changes';
					|it = 'Порчи товаров у хранителей';
					|pl = 'Uszkodzenia towarów u opiekunów';
					|tr = 'Emanetçi ürünlerinin stok kalite değişikliği'"; // @NStr
	AddPropertySetElement(Items, "a4ddba45-9418-444c-b828-61d6002f30e8", 
	"Document_DamageAtCustodian", Description, LanguagesCodes);
	
	Description = "vi = 'Thu tiền vào tài khoản ngân hàng';
					|ru = 'Поступления безналичных ДС';
					|en = 'Incoming payments — Bank account';
					|it = 'Поступления безналичных ДС';
					|pl = 'Przelew przychodzący';
					|tr = 'Gayri nakdin girişleri'"; // @NStr
	AddPropertySetElement(Items, "06f31d96-e21c-45fb-963d-f5f0c2fd1700", 
	"Document_BankAccountReceiptNote", Description, LanguagesCodes);
	
	Description = "vi = 'Tiếp nhận hàng vào kho';
					|ru = 'Поступления товаров на склад';
					|en = 'Receipts of goods to warehouse';
					|it = 'Поступления товаров на склад';
					|pl = 'Wpływy towarów do magazynu';
					|tr = 'Ambara ürün girişi'"; // @NStr
	AddPropertySetElement(Items, "3d1f393c-1f47-473a-b3af-310d3fc8301d", 
	"Document_ReceiptOfGoodsToWarehouse", Description, LanguagesCodes);
	
	Description = "vi = 'Tiếp nhận hàng hóa từ khách hàng';
					|ru = 'Поступления товаров от клиентов';
					|en = 'Goods receipts from customers';
					|it = 'Goods receipts from customers';
					|pl = 'Goods receipts from customers';
					|tr = 'Müşterilerden ürün alımları'"; // @NStr
	AddPropertySetElement(Items, "124b1db9-e1e0-4cdc-ad87-7e23dee17814", 
	"Document_GoodsReceiptFromCustomer", Description, LanguagesCodes);

	Description = "vi = 'Tiếp nhận hàng hóa từ người cất giữ/người nhận ký gửi';
					|ru = 'Поступления товаров от хранителей/комиссионеров';
					|en = 'Receipts of goods from custodians/consignees';
					|it = 'Поступления товаров от хранителей/комиссионеров';
					|pl = 'Przyjęcia towarów od depozytariuszy komisantów';
					|tr = 'Ürünlerin emanetçiden/konsinyeden teslim alınması'"; // @NStr
	AddPropertySetElement(Items, "289dcab0-792f-45b0-8846-50814d5800d2", 
	"Document_ReceiptOfGoodsFromCustodian", Description, LanguagesCodes);
	
	Description = "vi = 'Tiếp nhận dịch vụ vào bộ phận';
					|ru = 'Поступления услуг в подразделение';
					|en = 'Receipts of services to business unit';
					|it = 'Поступления услуг в подразделение';
					|pl = 'Receipts of services to business unit';
					|tr = 'Departmana hizmet alımı'"; // @NStr
	AddPropertySetElement(Items, "cb8baba2-d302-4d6f-a886-9cfea6d8677c", 
	"Document_ReceiptOfServicesToBusinessUnit", Description, LanguagesCodes);
	
	Description = "vi = 'Chứng từ nhận hàng hóa để bảo quản';
					|ru = 'Документы приемки товаров на хранение';
					|en = 'VMI procurement documents';
					|it = 'Документы приемки товаров на хранение';
					|pl = 'Dokumenty przyjęcia towarów do magazynu';
					|tr = 'Malların depoya giriş belgeleri'"; // @NStr
	AddPropertySetElement(Items, "368e8cc5-3ebf-41dd-a547-9af7effa1271", 
	"Document_GoodsReceiptForStorage", Description, LanguagesCodes);
	
	Description = "vi = 'Mua hàng hóa và dịch vụ';
					|ru = 'Приобретение товаров и услуг';
					|en = 'Vendor invoice';
					|it = 'Приобретение товаров и услуг';
					|pl = 'Nabycie towarów i usług';
					|tr = 'Satın alma faturası'"; // @NStr
	AddPropertySetElement(Items, "36a77c62-862d-40a1-88d6-0cc59b6d6a6a", 
	"Document_VendorInvoice", Description, LanguagesCodes);
	
	Description = "vi = 'Mua dịch vụ và tài sản khác';
					|ru = 'Приобретение услуг и прочих активов';
					|en = 'Vendor invoice — Services and Assets';
					|it = 'Приобретение услуг и прочих активов';
					|pl = 'Nabycie usług i innych aktywów';
					|tr = 'Satın alma faturası — hizmetler ve varlıklar'"; // @NStr
	AddPropertySetElement(Items, "411484b4-1c7e-4ca7-9cae-f74165efd1c8", 
	"Document_VendorInvoiceServicesAndAssets", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu thu';
					|ru = 'Приходные кассовые ордера';
					|en = 'Incoming payments — Cash account';
					|it = 'Приходные кассовые ордера';
					|pl = 'Asygnaty kasowo przychodowe';
					|tr = 'Gelen ödemeler - kasa hesabı '"; // @NStr
	AddPropertySetElement(Items, "8a4a8161-ea9a-4803-80f7-b12cede75b86", 
	"Document_CashAccountReceiptNote", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu nhập kho';
					|ru = 'Приходные ордера на товары';
					|en = 'Goods receipts';
					|it = 'Приходные ордера на товары';
					|pl = 'Przychodowe zlecenia na wiersze pozycji';
					|tr = 'Ambar giriş fişleri'"; // @NStr
	AddPropertySetElement(Items, "327fa038-96fd-4955-b518-ab5804ca6997", 
	"Document_GoodsReceiptNote", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi tăng khác';
					|ru = 'Прочие оприходования товаров';
					|en = 'Other goods recording as received';
					|it = 'Прочие оприходования товаров';
					|pl = 'Inne zaliczenia do przychodów towarów';
					|tr = 'Diğer ürünlerin envantere girişi'"; // @NStr
	AddPropertySetElement(Items, "400c7d9a-0329-4355-b194-d9ee777be42d", 
	"Document_OtherGoodsRecordingAsReceived", Description, LanguagesCodes);
	
	Description = "vi = 'Phản ánh thu nhập và chi phí khác';
					|ru = 'Отражение прочих доходов и расходов';
					|en = 'Non-operating income and expenses';
					|it = 'Отражение прочих доходов и расходов';
					|pl = 'Odzwierciedlenie pozostałych dochodów i rozchodów';
					|tr = 'İşletme dışı gelir ve giderlerin kaydı'"; // @NStr
	AddPropertySetElement(Items, "ef88ae64-5759-45c1-b936-eafb1ec2f68e", 
	"Document_OtherIncomeExpenses", Description, LanguagesCodes);
	
	Description = "vi = 'Lệnh chuyển tiền';
					|ru = 'Распоряжения на перемещение ДС';
					|en = 'Cash transfer orders';
					|it = 'Распоряжения на перемещение ДС';
					|pl = 'Zamówienia na przeniesienie ŚP';
					|tr = 'Nakit transfer emri'"; // @NStr
	AddPropertySetElement(Items, "f33caa42-29bf-46da-8ce8-24d276aa5605", 
	"Document_CashTransferReferenceOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Phân bổ thu nhập theo lĩnh vực kinh doanh';
					|ru = 'Распределение доходов по направлениям деятельности';
					|en = 'Allocation of income by lines of business';
					|it = 'Распределение доходов по направлениям деятельности';
					|pl = 'Podział dochodów według kierunków działalności';
					|tr = 'Faaliyet alanlarına göre gelir dağılımı'"; // @NStr
	AddPropertySetElement(Items, "5d2fee21-0aad-4e7d-bcf3-227ed455b2dd", 
	"Document_AllocationOfIncomeByLinesOfBusiness", Description, LanguagesCodes);
	
	Description = "vi = 'Phân bổ chi phí';
					|ru = 'Распределение расходов';
					|en = 'Line of business — allocation base';
					|it = 'Распределение расходов';
					|pl = 'Podział kosztów';
					|tr = 'Giderlerin dağıtımı'"; // @NStr
	AddPropertySetElement(Items, "4f0d1f0d-4d18-4c12-9b06-2539cad45d7c", 
	"Document_AllocationOfOtherCosts", Description, LanguagesCodes);
	
	Description = "vi = 'Phân bổ chi phí trả trước';
					|ru = 'Распределение РБП';
					|en = 'Deferred expense allocation';
					|it = 'Распределение РБП';
					|pl = 'Podział RPO';
					|tr = 'Ertelenmiş giderler dağıtımı'"; // @NStr
	AddPropertySetElement(Items, "64af17e6-b93c-4ec4-9f77-e9ec1f0cc608", 
	"Document_DeferredExpensesAllocation", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu chi';
					|ru = 'Расходные кассовые ордера';
					|en = 'Outgoing payments — Cash account';
					|it = 'Расходные кассовые ордера';
					|pl = 'Dowody kasowe KW';
					|tr = 'Giden ödemeler - kasa hesabı'"; // @NStr
	AddPropertySetElement(Items, "30a04b84-de56-491d-87c1-9be488409178", 
	"Document_CashVoucher", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu xuất kho';
					|ru = 'Расходные ордера на товары';
					|en = 'Goods issues';
					|it = 'Расходные ордера на товары';
					|pl = 'Wydanie zewnętrzne na wiersze zamówień';
					|tr = 'Ambar çıkış fişleri'"; // @NStr
	AddPropertySetElement(Items, "46490293-a9be-4da7-8133-f439c546298e", 
	"Document_GoodsIssueNote", Description, LanguagesCodes);
	
	Description = "vi = 'Giao hàng và cung cấp dịch vụ';
					|ru = 'Реализации товаров и услуг';
					|en = 'Customer invoice';
					|it = 'Реализации товаров и услуг';
					|pl = 'Sprzedaż towarów i usług';
					|tr = 'Ürün ve hizmet satışları'"; // @NStr
	AddPropertySetElement(Items, "30345ec6-cfd9-4f28-8da1-32596d600b32", 
	"Document_CustomerInvoice", Description, LanguagesCodes);
	
	Description = "vi = 'Cung cấp dịch vụ và tài sản khác';
					|ru = 'Реализации услуг и прочих активов';
					|en = 'Customer invoice — Services and Assets';
					|it = 'Реализации услуг и прочих активов';
					|pl = 'Sprzedaż usług ';
					|tr = 'Hizmetlerin ve diğer varlıkların gerçekleştirilmesi'"; // @NStr
	AddPropertySetElement(Items, "fc704a91-efe3-4d1d-bdcf-60b7d2573232", 
	"Document_CustomerInvoiceServicesAndAssets", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn giá của nhà cung cấp';
					|ru = 'Цены поставщиков';
					|en = 'Vendor prices';
					|it = 'Цены поставщиков';
					|pl = 'Cenniki dostawców';
					|tr = 'Tedarikçi fiyatları'"; // @NStr
	AddPropertySetElement(Items, "d341322b-84c7-45fa-a57d-5c62fe26824f", 
	"Document_VendorPriceList", Description, LanguagesCodes);
	
	Description = "vi = 'Chứng từ đóng bộ (tách bộ) hàng hóa';
					|ru = 'Документы сборки (разборки) товаров';
					|en = 'Documents of goods kitting';
					|it = 'Документы сборки (разборки) товаров';
					|pl = 'Dokumenty montażu (demontażu) towarów';
					|tr = 'Montaj (demontaj) ürün belgeleri'"; // @NStr
	AddPropertySetElement(Items, "b5bfb826-6e0f-4278-8105-ed1ad27939f7", 
	"Document_AssemblyFromComponents", Description, LanguagesCodes);
	
	Description = "vi = 'Đối chiếu công nợ (2.4)';
					|ru = 'Сверки взаиморасчетов (2.4)';
					|en = 'AR/AP reconciliations (2.4)';
					|it = 'Сверки взаиморасчетов (2.4)';
					|pl = 'AR/AP reconciliations (2.4)';
					|tr = 'Alacak/Borç mutabakatı (2.4)'"; // @NStr
	AddPropertySetElement(Items, "a66116af-cda2-4a92-ae9f-c9c4c82acf7e", 
	"Document_ARAPReconciliation2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Đối chiếu công nợ (2.5.11)';
					|ru = 'Сверки взаиморасчетов (2.5.11)';
					|en = 'AR/AP reconciliations (2.5.11)';
					|it = 'Сверки взаиморасчетов (2.5.11)';
					|pl = 'AR/AP reconciliations (2.5.11)';
					|tr = 'Alacak/Borç mutabakatı (2.5.11)'"; // @NStr
	AddPropertySetElement(Items, "793d65f3-6cae-40be-b9ef-f6dab8a45e78", 
	"Document_ARAPReconciliation2_5_11", Description, LanguagesCodes);
	
	Description = "vi = 'Chi tiền từ tài khoản ngân hàng';
					|ru = 'Списания безналичных ДС';
					|en = 'Outgoing payments — Bank account';
					|it = 'Списания безналичных ДС';
					|pl = 'Pobrania bezgotówkowych ŚP';
					|tr = 'Gayri nakdin gider yazılması'"; // @NStr
	AddPropertySetElement(Items, "321a9487-1049-4326-9473-294c9df1150b", 
	"Document_BankAccountIssue", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi giảm chênh lệch giữ tiếp nhận và mua hàng';
					|ru = 'Списание расхождений между поступлением и приобретением';
					|en = 'Write off discrepancies between receipt and purchase';
					|it = 'Списание расхождений между поступлением и приобретением';
					|pl = 'Write off discrepancies between receipt and purchase';
					|tr = 'Kabul ve satın alma arasındaki tutarsızlıkların yazılması'"; // @NStr
	AddPropertySetElement(Items, "f1f8032c-b58c-45d9-a053-626d80baa016", 
	"Document_WriteOffDiscrepanciesBetweenReceiptAndPurchase", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh công nợ';
					|ru = 'Корректировки задолженностей';
					|en = 'AR/AP adjustments';
					|it = 'Корректировки задолженностей';
					|pl = 'Korekty zobowiązań';
					|tr = 'Borçların düzeltilmesi'"; // @NStr
	AddPropertySetElement(Items, "08c14b9b-0e3a-4dbb-85a8-0f13fe3eed24", 
	"Document_ARAPAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi giảm hàng thiếu';
					|ru = 'Списания недостач товаров';
					|en = 'Inventory shortage write-offs';
					|it = 'Списания недостач товаров';
					|pl = 'Rozchód wewnętrzny';
					|tr = 'Stok eksiği tahakkuku'"; // @NStr
	AddPropertySetElement(Items, "8bb7fae3-b885-4b0c-bd01-c4dbf52c0998", 
	"Document_WriteOffOfGoodsShortages", Description, LanguagesCodes);
	
	Description = "vi = 'Báo cáo ghi giảm hàng hóa từ nơi cất giữ';
					|ru = 'Отчеты о списании товаров с хранения';
					|en = 'VMI adjustment reports';
					|it = 'Отчеты о списании товаров с хранения';
					|pl = 'Raporty o rozchodowaniu towarów z przechowywania';
					|tr = 'Depodaki mallar için zarar raporları'"; // @NStr
	AddPropertySetElement(Items, "4785cc91-2f39-43c6-8426-12fc56b471a9", 
	"Document_ReportOnVMIAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Hóa đơn thanh toán';
					|ru = 'Счета на оплату';
					|en = 'Commercial invoices';
					|it = 'Счета на оплату';
					|pl = 'Rachunki do zapłaty';
					|tr = 'Ticari faturalar'"; // @NStr
	AddPropertySetElement(Items, "a1dd40d8-1959-4d7e-a08f-0847804865bd", 
	"Document_CustomerCommercialInvoice", Description, LanguagesCodes);
	
	Description = "vi = 'Tờ khai hải quan nhập khẩu';
					|ru = 'Таможенные декларации на импорт';
					|en = 'Customs import declarations';
					|it = 'Таможенные декларации на импорт';
					|pl = 'Importowe deklaracje celne';
					|tr = 'İthalat için gümrük beyannamesi'"; // @NStr
	AddPropertySetElement(Items, "8a5574f1-c64b-42b9-8c4a-88352d921694", 
	"Document_CCDImport", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu đóng gói';
					|ru = 'Упаковочные листы';
					|en = 'Packing lists';
					|it = 'Упаковочные листы';
					|pl = 'Specyfikacja ładunkowa';
					|tr = 'Ürün listeleri'"; // @NStr
	AddPropertySetElement(Items, "65668eeb-1f44-41bb-8f01-695caaf88cba", 
	"Document_PackingList", Description, LanguagesCodes);
	
	Description = "vi = 'Đặt phong tỏa ô hàng';
					|ru = 'Установки блокировок ячеек';
					|en = 'Block storage bins';
					|it = 'Установки блокировок ячеек';
					|pl = 'Ustawienia blokad komórek';
					|tr = 'Hücre kilit ayarlama'"; // @NStr
	AddPropertySetElement(Items, "aa777918-c7b7-46da-8b91-9769691115dc", 
	"Document_SetStorageBinLocks", Description, LanguagesCodes);
	
	Description = "vi = 'Hạn mức danh điểm mặt hàng';
					|ru = 'Квоты ассортимента';
					|en = 'Product mix quotas';
					|it = 'Квоты ассортимента';
					|pl = 'Limit asortymentu';
					|tr = 'Ürün çeşitliliği kotası'"; // @NStr
	AddPropertySetElement(Items, "ff884028-ef80-4bb9-8be3-5b4bf94620c3", 
	"Document_SetProductRangeQuotas", Description, LanguagesCodes);
	
	Description = "vi = 'Lịch sử thay đổi đơn giá';
					|ru = 'История изменения цен';
					|en = 'Price change history';
					|it = 'История изменения цен';
					|pl = 'Historia zmiany cen';
					|tr = 'Fiyat değişiklik geçmişi'"; // @NStr
	AddPropertySetElement(Items, "da4604d7-6cba-4bfd-afdc-5ae5c693e533", 
	"Document_PriceSetup", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu tính tiền bán hàng';
					|ru = 'Чеки ККМ продажи';
					|en = 'Receipts of sale';
					|it = 'Чеки ККМ продажи';
					|pl = 'Paragony kasowe sprzedaży';
					|tr = 'Yazar kasa satış fişleri'"; // @NStr
	AddPropertySetElement(Items, "6440dad7-cb6a-bf4d-fdac-93e56335ae5c", 
	"Document_CashRegisterReceipt", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu tính tiền trả lại';
					|ru = 'Чеки ККМ на возврат';
					|en = 'Refund receipts';
					|it = 'Чеки ККМ на возврат';
					|pl = 'Paragony kasy do zwrotu';
					|tr = 'Yazar kasa iade fişleri'"; // @NStr
	AddPropertySetElement(Items, "da6d0474-ba6c-fd4b-dcaf-5ae5c93e5336", 
	"Document_CashRegisterReceiptReturn", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu tính tiền điều chỉnh';
					|ru = 'Чеки ККМ коррекции';
					|en = 'Receipts of cash register adjustment';
					|it = 'Чеки ККМ коррекции';
					|pl = 'Paragony kas korekty';
					|tr = 'Yazar kasa düzeltme fişleri'"; // @NStr
	AddPropertySetElement(Items, "d4d760a4-6acb-4dbf-acfd-ae5533c693e5", 
	"Document_ReceiptOfCashRegisterAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Kênh tác động quảng cáo';
					|ru = 'Каналы рекламных воздействий';
					|en = 'Advertising channels';
					|it = 'Каналы рекламных воздействий';
					|pl = 'Kanały oddziaływań reklamowych';
					|tr = 'Reklam etki kanalları'"; // @NStr
	AddPropertySetElement(Items, "822c566d-f23f-4a8f-b4d5-5d0903a6dd27", 
	"ChartOfCharacteristicTypes_ChannelsOfAdvertisingImpacts", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng tài sản và nguồn vốn';
					|ru = 'Статьи активов и пассивов';
					|en = 'Asset and liability items';
					|it = 'Статьи активов и пассивов';
					|pl = 'Pozycje aktywów i pasywów';
					|tr = 'Varlıklar ve yükümlülükler kalemleri'"; // @NStr
	AddPropertySetElement(Items, "7b41e8e0-bbe7-4943-a859-c9705218896b", 
	"ChartOfCharacteristicTypes_AssetLiabilityItems", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng thu nhập';
					|ru = 'Статьи доходов';
					|en = 'Income items';
					|it = 'Статьи доходов';
					|pl = 'Pozycje przychodów';
					|tr = 'Gelir kalemleri'"; // @NStr
	AddPropertySetElement(Items, "cfb5df13-8137-4eae-b1e8-b769f09116fd", 
	"ChartOfCharacteristicTypes_IncomeItems", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng chi phí';
					|ru = 'Статьи расходов';
					|en = 'Expense items';
					|it = 'Статьи расходов';
					|pl = 'Pozycje rozchodów';
					|tr = 'Gider kalemleri'"; // @NStr
	AddPropertySetElement(Items, "c9c3ca99-a1c6-46f5-960c-d494dee30b80", 
	"ChartOfCharacteristicTypes_ExpenseItems", Description, LanguagesCodes);
	
	Description = "vi = 'Tài khoản ngân hàng';
					|ru = 'Банковские счета';
					|en = 'Bank accounts';
					|it = 'Банковские счета';
					|pl = 'Rachunki bankowe';
					|tr = 'Banka hesapları'"; // @NStr
	AddPropertySetElement(Items, "fa532757-da27-4e26-ac5f-c32550213cb1", 
	"Catalog_CounterpartyBankAccounts", Description, LanguagesCodes);
	
	Description = "vi = 'Tài khoản ngân hàng của doanh nghiệp';
					|ru = 'Банковские счета организаций';
					|en = 'Company bank accounts';
					|it = 'Банковские счета организаций';
					|pl = 'Rachunki bankowe firmy';
					|tr = 'İş yerlerinin banka hesapları'"; // @NStr
	AddPropertySetElement(Items, "f6d04f12-8796-458a-8c35-223f917b6794", 
	"Catalog_CompaniesBankAccounts", Description, LanguagesCodes);
	
	Description = "vi = 'Khu vực kinh doanh';
					|ru = 'Бизнес-регионы';
					|en = 'Business regions';
					|it = 'Бизнес-регионы';
					|pl = 'Business regions';
					|tr = 'İş bölgesi'"; // @NStr
	AddPropertySetElement(Items, "fa6b1e95-38c5-4ba5-85d3-9263dc8bf5f1", 
	"Catalog_BusinessRegions", Description, LanguagesCodes);
	
	Description = "vi = 'Chương trình tích điểm khách hàng thân thiết';
					|ru = 'Бонусные программы лояльности';
					|en = 'Loyalty programs';
					|it = 'Бонусные программы лояльности';
					|pl = 'Bonusowe programy lojalnościowe';
					|tr = 'Sadakat programları'"; // @NStr
	AddPropertySetElement(Items, "99130094-d0dd-406f-8068-68b71ba6acb5", 
	"Catalog_LoyaltyPrograms", Description, LanguagesCodes);
	
	Description = "vi = 'Phương án đóng bộ mặt hàng';
					|ru = 'Варианты комплектации номенклатуры';
					|en = 'Product kit configurations';
					|it = 'Варианты комплектации номенклатуры';
					|pl = 'Warianty kompletacji produktów';
					|tr = 'Öğe set konfigürasyonu'"; // @NStr
	AddPropertySetElement(Items, "6a89b3b1-87ee-4d87-a502-0f9cfe3d67fd", 
	"Catalog_ProductKitConfigurations", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng thẻ khách hàng thân thiết';
					|ru = 'Виды карт лояльности';
					|en = 'Loyalty card kinds';
					|it = 'Виды карт лояльности';
					|pl = 'Rodzaje kart lojalnościowych';
					|tr = 'Sadakat kartı türleri'"; // @NStr
	AddPropertySetElement(Items, "900ac571-f985-405c-a50e-c9c6edfbae4c", 
	"Catalog_LoyaltyCardKinds", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng mặt hàng';
					|ru = 'Виды номенклатуры';
					|en = 'Item kinds';
					|it = 'Виды номенклатуры';
					|pl = 'Rodzaje produktów';
					|tr = 'Öğe türleri'"; // @NStr
	AddPropertySetElement(Items, "058d7e98-beea-4834-b7cb-1ab05d63c8f3", 
	"Catalog_ItemKinds", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng phiếu quà tặng';
					|ru = 'Виды подарочных сертификатов';
					|en = 'Gift card kinds';
					|it = 'Виды подарочных сертификатов';
					|pl = 'Rodzaje certyfikatów podarunkowych';
					|tr = 'Hediye kartı türleri'"; // @NStr
	AddPropertySetElement(Items, "34177601-7a1d-4283-9b22-a8cb0e58bb42", 
	"Catalog_GiftCertificateKinds", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng giá';
					|ru = 'Виды цен';
					|en = 'Price types';
					|it = 'Виды цен';
					|pl = 'Rodzaje cen';
					|tr = 'Fiyat türleri'"; // @NStr
	AddPropertySetElement(Items, "f9dd70bb-e697-42ae-99c4-aaa62abdbf27", 
	"Catalog_TypesOfPrices", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng giá của nhà cung cấp';
					|ru = 'Виды цен поставщиков';
					|en = 'Vendor price types';
					|it = 'Виды цен поставщиков';
					|pl = 'Rodzaje cen dostawców';
					|tr = 'Tedarikçinin ücret türleri'"; // @NStr
	AddPropertySetElement(Items, "f0dc7108-4df0-4065-ae1f-cc20e167678c", 
	"Catalog_VendorPriceTypes", Description, LanguagesCodes);
	
	Description = "vi = 'Nhóm tùy chỉnh kế toán tài chính mặt hàng';
					|ru = 'Группы настроек фин. учета номенклатуры';
					|en = 'Financial accounting groups';
					|it = 'Группы настроек фин. учета номенклатуры';
					|pl = 'Grupy ustawień ewidencji fin.  nomenklatury';
					|tr = 'Öğe finansal muhasebesi ayar grupları'"; // @NStr
	AddPropertySetElement(Items, "7ec7394d-a2bc-4493-a01f-83bb1c5730e4", 
	"Catalog_InventoryAccountingGroups", Description, LanguagesCodes);
	
	Description = "vi = 'Hợp đồng với đối tác';
					|ru = 'Договоры с контрагентами';
					|en = 'Contracts';
					|it = 'Договоры с контрагентами';
					|pl = 'Umowy z kontrahentami';
					|tr = 'Cari hesap sözleşmeleri'"; // @NStr
	AddPropertySetElement(Items, "d23b5f4f-061a-4c28-9cc7-f7ede71c8ab7", 
	"Catalog_CounterpartyContracts", Description, LanguagesCodes);
	
	Description = "vi = 'Hợp đồng tín dụng và tiền gửi';
					|ru = 'Договоры кредитов и депозитов';
					|en = 'Loan and deposit contracts';
					|it = 'Договоры кредитов и депозитов';
					|pl = 'Umowy kredytowe i depozytowe';
					|tr = 'Kredi ve mevduat sözleşmeleri'"; // @NStr
	AddPropertySetElement(Items, "ebdaa4c6-750c-47cf-b4e1-d1fbb281bfe5", 
	"Catalog_LoanAndDepositContracts", Description, LanguagesCodes);
	
	Description = "vi = 'Hợp đồng giữa các doanh nghiệp';
					|ru = 'Договоры между организациями';
					|en = 'Intercompany contracts';
					|it = 'Договоры между организациями';
					|pl = 'Kontrakty między firmami';
					|tr = 'Şirketler arası sözleşmeler'"; // @NStr
	AddPropertySetElement(Items, "132b5b62-b81a-47cb-897b-c5280b32b52f", 
	"Catalog_IntercompanyContracts", Description, LanguagesCodes);
	
	Description = "ru = '(не используется) Дополнительные отчеты и обработки';
					|vi = '(not used) Additional reports and data processors';
					|en = '(not used) Additional reports and data processors';
					|it = '(not used) Additional reports and data processors';
					|pl = '(not used) Additional reports and data processors';
					|tr = '(kullanılmıyor) Ek raporlar ve işlemler'"; // @NStr
	AddPropertySetElement(Items, "9623d53e-672d-4b56-b054-3ff1c5d1437e", 
	"DeleteCatalog_AdditionalReportsAndDataProcessors", Description, LanguagesCodes);
	
	Description = "vi = 'Nhiệm vụ của dự án';
					|ru = 'Задачи проекта';
					|en = 'Project tasks';
					|it = 'Задачи проекта';
					|pl = 'Zadania projektu';
					|tr = 'Proje görevleri'"; // @NStr
	AddPropertySetElement(Items, "03239253-36af-4b77-95fd-a62e4f1bdebc", 
	"Catalog_ProjectTasks", Description, LanguagesCodes);
	
	Description = "vi = 'Nguồn dữ liệu lập kế hoạch';
					|ru = 'Источники данных планирования';
					|en = 'Planning data sources';
					|it = 'Источники данных планирования';
					|pl = 'Źródła danych planowania';
					|tr = 'Planlama veri kaynakları'"; // @NStr
	AddPropertySetElement(Items, "5204eeef-8b8e-4169-8b12-b33a5badaaa6", 
	"Catalog_PlanningDataSources", Description, LanguagesCodes);
	
	Description = "vi = 'Thẻ khách hàng thân thiết';
					|ru = 'Карты лояльности';
					|en = 'Loyalty cards';
					|it = 'Карты лояльности';
					|pl = 'Karty lojalnościowe';
					|tr = 'Sadakat kartları'"; // @NStr
	AddPropertySetElement(Items, "6cc28cb7-986c-4f23-a8a7-14ca2a48f3de", 
	"Catalog_LoyaltyCards", Description, LanguagesCodes);
	
	Description = "vi = 'Quỹ tiền mặt';
					|ru = 'Кассы';
					|en = 'Cash accounts';
					|it = 'Кассы';
					|pl = 'Kasy';
					|tr = 'Kasalar'"; // @NStr
	AddPropertySetElement(Items, "dbde3b0f-2cb1-44f6-9b8a-30ea7f389a20", 
	"Catalog_CashAccounts", Description, LanguagesCodes);
	
	Description = "vi = 'Quầy thu ngân';
					|ru = 'Кассы ККМ';
					|en = 'Cash registers';
					|it = 'Кассы ККМ';
					|pl = 'Kasy';
					|tr = 'Yazar kasalar'"; // @NStr
	AddPropertySetElement(Items, "350d3a26-98e4-4232-a0df-e555f1482afb", 
	"Catalog_CashRegisters", Description, LanguagesCodes);
	
	Description = "vi = 'Bộ sưu tập (thời vụ)';
					|ru = 'Коллекции (сезоны)';
					|en = 'Collections (seasons)';
					|it = 'Коллекции (сезоны)';
					|pl = 'Kolekcje (sezony)';
					|tr = 'Koleksiyonlar (sezonlar)'"; // @NStr
	AddPropertySetElement(Items, "243e323f-965d-4767-9008-fb633876c63e", 
	"Catalog_ItemsCollections", Description, LanguagesCodes);
	
	Description = "vi = 'Người liên hệ';
					|ru = 'Контактные лица';
					|en = 'Contact persons';
					|it = 'Контактные лица';
					|pl = 'Osoby kontaktowe';
					|tr = 'İrtibat kişileri'"; // @NStr
	AddPropertySetElement(Items, "5321769f-c1aa-47de-b029-0a31f3d2c67a", 
	"Catalog_ContactPersonsForPartners", Description, LanguagesCodes);
	
	Description = "vi = 'Đối tác';
					|ru = 'Контрагенты';
					|en = 'Counterparties';
					|it = 'Контрагенты';
					|pl = 'Kontrahenci';
					|tr = 'Cari hesaplar'"; // @NStr
	AddPropertySetElement(Items, "312bf0ee-35a3-4cd1-b84e-1e54fd5d3e4f", 
	"Catalog_Counterparties", Description, LanguagesCodes);
	
	Description = "vi = 'Hoạt động Marketing';
					|ru = 'Маркетинговые мероприятия';
					|en = 'Marketing activities';
					|it = 'Маркетинговые мероприятия';
					|pl = 'Wydarzenia marketingowe';
					|tr = 'Pazarlama faaliyetleri'"; // @NStr
	AddPropertySetElement(Items, "b820665e-f743-4072-bc2b-804e020aefe6", 
	"Catalog_MarketingActivities", Description, LanguagesCodes);
	
	Description = "vi = 'Lĩnh vực hoạt động';
					|ru = 'Направления деятельности';
					|en = 'Lines of business';
					|it = 'Направления деятельности';
					|pl = 'Rodzaje działalności';
					|tr = 'İş kolları'"; // @NStr
	AddPropertySetElement(Items, "e8967082-7e2b-48ec-add2-c756ffeed0cf", 
	"Catalog_LinesOfBusiness", Description, LanguagesCodes);
	
	Description = "vi = 'Vùng cất giữ';
					|ru = 'Области хранения';
					|en = 'Storage areas';
					|it = 'Области хранения';
					|pl = 'Obszary przechowywania';
					|tr = 'Depolama alanları'"; // @NStr
	AddPropertySetElement(Items, "a8dc8cd3-db32-4280-9b2a-05ce095e6610", 
	"Catalog_StorageAreas", Description, LanguagesCodes);
	
	Description = "vi = 'Doanh nghiệp';
					|ru = 'Организации';
					|en = 'Companies';
					|it = 'Организации';
					|pl = 'Companies';
					|tr = 'İş yerleri'"; // @NStr
	AddPropertySetElement(Items, "83c464a3-259d-49f9-8eda-5cd69322550a", 
	"Catalog_Companies", Description, LanguagesCodes);
	
	Description = "vi = 'Phiếu quà tặng';
					|ru = 'Подарочные сертификаты';
					|en = 'Gift cards';
					|it = 'Подарочные сертификаты';
					|pl = 'Certyfikaty podarunkowe';
					|tr = 'Hediye kartları'"; // @NStr
	AddPropertySetElement(Items, "687e3458-4629-4682-bca7-675c6806dfd2", 
	"Catalog_GiftCertificates", Description, LanguagesCodes);
	
	Description = "vi = 'Thiết bị kết nối';
					|ru = 'Подключаемое оборудование';
					|en = 'Peripherals';
					|it = 'Подключаемое оборудование';
					|pl = 'Urządzenia peryferyjne';
					|tr = 'Bağlanabilir donanım'"; // @NStr
	AddPropertySetElement(Items, "a26d2637-fc50-4397-99be-2b7eabc7ce86", 
	"Catalog_Peripherals", Description, LanguagesCodes);
	
	Description = "vi = 'Quy tắc cộng và trừ điểm thưởng';
					|ru = 'Правила начисления и списания бонусных баллов';
					|en = 'Rules of accrual and write-off of bonus points';
					|it = 'Правила начисления и списания бонусных баллов';
					|pl = 'Zasady naliczania i odejmowania punktów bonusowych';
					|tr = 'Bonus puanların tahakkuk edilmesi ve silinmesine yönelik kurallar'"; // @NStr
	AddPropertySetElement(Items, "c6087fe9-09d7-491b-a2d2-2860fc7ac555", 
	"Catalog_CustomerRewardProgramRules", Description, LanguagesCodes);
	
	Description = "vi = 'Quy tắc trao đổi với thiết bị bán hàng offline';
					|ru = 'Правила обмена с подключаемым оборудованием offline';
					|en = 'Rules of exchange with offline peripherals';
					|it = 'Правила обмена с подключаемым оборудованием offline';
					|pl = 'Reguły wymiany z urządzeniami peryferyjnymi offline';
					|tr = 'Bağlanan ekipmanla değişim kuralı offline'"; // @NStr
	AddPropertySetElement(Items, "f864b090-942a-4cdd-8dd3-0fdc34d7aafc", 
	"Catalog_RulesOfExchangeWithOfflinePeripherals", Description, LanguagesCodes);
	
	Description = "vi = 'Khiếu nại';
					|ru = 'Претензии';
					|en = 'Complaints';
					|it = 'Претензии';
					|pl = 'Complaints';
					|tr = 'Şikayetler'"; // @NStr
	AddPropertySetElement(Items, "1a291c8e-09ed-4531-b1d6-d0ebbe5b34f4", 
	"Catalog_Complaints", Description, LanguagesCodes);
	
	Description = "vi = 'Dự án';
					|ru = 'Проекты';
					|en = 'Projects';
					|it = 'Проекты';
					|pl = 'Projects';
					|tr = 'Projeler'"; // @NStr
	AddPropertySetElement(Items, "f36c7c4a-dded-47c0-8283-b526aefaf3a3", 
	"Catalog_Projects", Description, LanguagesCodes);
	
	Description = "vi = 'Tài sản và nguồn vốn khác';
					|ru = 'Прочие активы и пассивы';
					|en = 'Other assets and liabilities';
					|it = 'Прочие активы и пассивы';
					|pl = 'Inne aktywa i pasywa';
					|tr = 'Diğer varlıklar ve yükümlülükler'"; // @NStr
	AddPropertySetElement(Items, "dd99c581-5039-424c-b290-26ba21dba251", 
	"Catalog_OtherAssetsLiabilities", Description, LanguagesCodes);
	
	Description = "vi = 'Chi phí khác';
					|ru = 'Прочие расходы';
					|en = 'Other expenses';
					|it = 'Прочие расходы';
					|pl = 'Inne rozchody';
					|tr = 'Diğer giderler'"; // @NStr
	AddPropertySetElement(Items, "a1c33d61-5466-4b90-81f3-d6cac7747dee", 
	"Catalog_OtherExpenses", Description, LanguagesCodes);
	
	Description = "vi = 'Đánh giá kết quả bán hàng';
					|ru = 'Рейтинги продаж номенклатуры';
					|en = 'Sales ranks';
					|it = 'Рейтинги продаж номенклатуры';
					|pl = 'Rankingi sprzedaży wg nomenklatury';
					|tr = 'Satış sıralamaları'"; // @NStr
	AddPropertySetElement(Items, "c5fa4373-8702-4588-b5e8-37e93967be71", 
	"Catalog_SalesRanks", Description, LanguagesCodes);
	
	Description = "vi = 'Vụ việc với khách hàng';
					|ru = 'Сделки с клиентами';
					|en = 'Sales opportunities';
					|it = 'Сделки с клиентами';
					|pl = 'Umowy z klientami';
					|tr = 'Müşterilerle satış fırsatları'"; // @NStr
	AddPropertySetElement(Items, "8e2d44d3-f80d-490e-b008-8d3e5469ee56", 
	"Catalog_SalesOpportunitiesToCustomer", Description, LanguagesCodes);
	
	Description = "vi = 'Phân khúc mặt hàng';
					|ru = 'Сегменты номенклатуры';
					|en = 'Inventory segments';
					|it = 'Сегменты номенклатуры';
					|pl = 'Segmenty produktów';
					|tr = 'Stok segmentleri'"; // @NStr
	AddPropertySetElement(Items, "fbf5065c-426e-40b3-a9fb-e46aa9d7c2e1", 
	"Catalog_ProductSegments", Description, LanguagesCodes);
	
	Description = "vi = 'Phân khúc khách hàng';
					|ru = 'Сегменты клиентов';
					|en = 'Customer segments';
					|it = 'Сегменты клиентов';
					|pl = 'Segmenty klientów';
					|tr = 'Müşteri segmentleri'"; // @NStr
	AddPropertySetElement(Items, "78ab2475-b2fd-4817-be7b-00aa6a2b7658", 
	"Catalog_PartnersSegments", Description, LanguagesCodes);
	
	Description = "vi = 'Giấy chứng nhận mặt hàng';
					|ru = 'Сертификаты номенклатуры';
					|en = 'Quality certificates';
					|it = 'Сертификаты номенклатуры';
					|pl = 'Certyfikaty towarów';
					|tr = 'Kalite belgeleri'"; // @NStr
	AddPropertySetElement(Items, "345d0b95-60ff-4d5b-bfa0-4e77504dd435", 
	"Catalog_QualityCertificates", Description, LanguagesCodes);
	
	Description = "vi = 'Chiết khấu (phụ thu)';
					|ru = 'Скидки (наценки)';
					|en = 'Discounts (markups)';
					|it = 'Скидки (наценки)';
					|pl = 'Rabaty (marże)';
					|tr = 'İndirim (marj)'"; // @NStr
	AddPropertySetElement(Items, "48d065fe-21ed-43df-b919-5882ef9674b2", 
	"Catalog_DiscountsMarkups", Description, LanguagesCodes);
	
	Description = "vi = 'Nhà kho';
					|ru = 'Складские помещения';
					|en = 'Warerooms';
					|it = 'Складские помещения';
					|pl = 'Pomieszczenia magazynowe';
					|tr = 'Depolar'"; // @NStr
	AddPropertySetElement(Items, "39d0e77b-2346-4099-a680-7d47fe57fe9d", 
	"Catalog_Warerooms", Description, LanguagesCodes);
	
	Description = "vi = 'Ô hàng';
					|ru = 'Складские ячейки';
					|en = 'Storage bins';
					|it = 'Складские ячейки';
					|pl = 'Komórki magazynowe';
					|tr = 'Depo yerleri'"; // @NStr
	AddPropertySetElement(Items, "d0b6fee9-4117-4091-827a-5dab0a776a48", 
	"Catalog_StorageBins", Description, LanguagesCodes);
	
	Description = "vi = 'Kho bãi và cửa hàng';
					|ru = 'Склады и магазины';
					|en = 'Warehouses and stores';
					|it = 'Склады и магазины';
					|pl = 'Magazyny i sklepy';
					|tr = 'Ambarlar ve mağazalar'"; // @NStr
	AddPropertySetElement(Items, "a9e936e8-0b20-4a5e-937d-adbb4348cba7", 
	"Catalog_Warehouses", Description, LanguagesCodes);
	
	Description = "vi = 'Thỏa thuận về điều kiện bán hàng';
					|ru = 'Соглашения об условиях продаж';
					|en = 'Terms of sale';
					|it = 'Соглашения об условиях продаж';
					|pl = 'Umowa o warunkach sprzedaży';
					|tr = 'Satış şart ve hükümleri'"; // @NStr
	AddPropertySetElement(Items, "d47427af-b1d4-41cd-b69a-ba0cd46f89d0", 
	"Catalog_TermsOfSale", Description, LanguagesCodes);
	
	Description = "vi = 'Thỏa thuận với nhà cung cấp';
					|ru = 'Соглашения с поставщиками';
					|en = 'Terms of purchase';
					|it = 'Соглашения с поставщиками';
					|pl = 'Zamówienie do dostawców';
					|tr = 'Satın alma koşulları'"; // @NStr
	AddPropertySetElement(Items, "e8723370-89b4-4f7e-92e5-1671f5b13047", 
	"Catalog_TermsOfPurchaseFromVendors", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng lưu chuyển tiền tệ';
					|ru = 'Статьи движения денежных средств';
					|en = 'Cash flow items';
					|it = 'Статьи движения денежных средств';
					|pl = 'Pozycje przepływów środków pieniężnych';
					|tr = 'Nakit akışı öğeleri'"; // @NStr
	AddPropertySetElement(Items, "faf07d23-941f-411b-be46-79b72c161cc7", 
	"Catalog_CashFlowReportItems", Description, LanguagesCodes);
	
	Description = "vi = 'Cấu trúc mục tiêu';
					|ru = 'Структура целей';
					|en = 'Goal tree';
					|it = 'Структура целей';
					|pl = 'Struktura celów';
					|tr = 'Hedef yapısı'"; // @NStr
	AddPropertySetElement(Items, "ed9e0081-196a-48cb-8bbf-f75b9a560b69", 
	"Catalog_StructureOfTargets", Description, LanguagesCodes);
	
	Description = "vi = 'Kịch bản đồng bộ dữ liệu';
					|ru = 'Сценарии синхронизации данных';
					|en = 'Data synchronization scenarios';
					|it = 'Сценарии синхронизации данных';
					|pl = 'Scenariusze synchronizacji danych';
					|tr = 'Veri senkronizasyon senaryoları'"; // @NStr
	AddPropertySetElement(Items, "7c296fff-4787-4529-beba-120360654bdc", 
	"Catalog_DataExchangeScenarios", Description, LanguagesCodes);
	
	Description = "vi = 'Thể loại hàng hóa';
					|ru = 'Товарные категории';
					|en = 'Product categories';
					|it = 'Товарные категории';
					|pl = 'Kategorie towarowe';
					|tr = 'Ürün kategorileri'"; // @NStr
	AddPropertySetElement(Items, "4458ad39-53b9-4004-abbb-6c5c6bd47685", 
	"Catalog_ProductCategories", Description, LanguagesCodes);
	
	Description = "vi = 'Khuôn dạng cửa hàng';
					|ru = 'Форматы магазинов';
					|en = 'Retail formats';
					|it = 'Форматы магазинов';
					|pl = 'Formaty sklepów';
					|tr = 'Mağaza formatları'"; // @NStr
	AddPropertySetElement(Items, "53c4705f-3adf-4550-b431-cd52097c7ce2", 
	"Catalog_StoreFormats", Description, LanguagesCodes);
	
	Description = "vi = 'Khuôn mẫu nhãn tem và nhãn giá';
					|ru = 'Шаблоны этикеток и ценников';
					|en = 'Label and price tag templates';
					|it = 'Шаблоны этикеток и ценников';
					|pl = 'Szablony etykiet i cenników';
					|tr = 'Etiket ve fiyat etiketi numuneleri'"; // @NStr
	AddPropertySetElement(Items, "a502c8cb-85e9-48b0-9c93-e9c5e025cae4", 
	"Catalog_LabelAndPriceTagTemplates", Description, LanguagesCodes);
	
	Description = "vi = 'Thiết bị thanh toán thẻ';
					|ru = 'Эквайринговые терминалы';
					|en = 'POS terminals';
					|it = 'Эквайринговые терминалы';
					|pl = 'Terminale acquiringowe';
					|tr = 'PoS terminalleri'"; // @NStr
	AddPropertySetElement(Items, "950dc173-da97-4ff2-bed0-47059cfb2120", 
	"Catalog_POSTerminals", Description, LanguagesCodes);
	
	
	
	
	Description = "vi = 'Biên bản nghiệm thu công việc nội bộ';
					|ru = 'Акты выполненных внутренних работ';
					|en = 'Internal works acceptance';
					|it = 'Акты выполненных внутренних работ';
					|pl = 'Protokoły odbioru';
					|tr = 'Gerçekleştirilen dahili iş tutanakları'"; // @NStr
	AddPropertySetElement(Items, "114c5fc9-39cd-4d46-a72b-a2b88cc112eb", 
	"Document_InternalAcceptanceCertificate", Description, LanguagesCodes);
	
	Description = "vi = 'Mua lại TSCĐ đã thuê';
					|ru = 'Выкуп арендованных ОС';
					|en = 'Vendor invoice — Leased assets';
					|it = 'Выкуп арендованных ОС';
					|pl = 'Wykup wynajmowanych środków trwałych';
					|tr = 'Alıcı faturası - Kiralanan varlıklar'"; // @NStr
	AddPropertySetElement(Items, "bb9ae340-7b48-461c-b96b-a03ddef16415", 
	"Document_VendorInvoiceLeasedAssets", Description, LanguagesCodes);
	
	Description = "vi = 'Sản lượng tính cho TSCĐ vô hình';
					|ru = 'Выработка НМА';
					|en = 'Intangible assets — Operating time';
					|it = 'Выработка НМА';
					|pl = 'Wydajność wartości niematerialnych';
					|tr = 'Maddi olmayan varlıklar - İşletim süresi'"; // @NStr
	AddPropertySetElement(Items, "88eb2a4f-1f03-4efa-bcd2-ac68b24cebf4", 
	"Document_IntangibleAssetsOperatingTime", Description, LanguagesCodes);
	
	Description = "vi = 'Sản lượng của nhân viên';
					|ru = 'Выработка сотрудников';
					|en = 'Timesheets charge';
					|it = 'Выработка сотрудников';
					|pl = 'Ustawienia wydajności pracowników';
					|tr = 'Zaman çizelgesi bazlı ücretlendirme'"; // @NStr
	AddPropertySetElement(Items, "89824a09-4486-4485-a771-e92f090e20d2", 
	"Document_WorkOutput", Description, LanguagesCodes);
	
	Description = "vi = 'Biến động sản phẩm và nguyên vật liệu';
					|ru = 'Движение продукции и материалов';
					|en = 'Movement of products and materials';
					|it = 'Движение продукции и материалов';
					|pl = 'Obrót produkcji i materiałów';
					|tr = 'İmal edilen ürünler ve malzeme hareketi'"; // @NStr
	AddPropertySetElement(Items, "59e93f0b-738c-4576-b5c4-b68b67ea8f85", 
	"Document_MovementOfProductsAndMaterials", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn đề nghị xuất nguyên vật liệu vào sản xuất';
					|ru = 'Заказы материалов в производство';
					|en = 'Material orders for shop floor stockroom';
					|it = 'Заказы материалов в производство';
					|pl = 'Zamówienia materiałów na produkcje';
					|tr = 'Üretimdeki malzemelerin siparişleri'"; // @NStr
	AddPropertySetElement(Items, "a10b4f33-0225-4717-827f-0821a4fc9ac5", 
	"Document_OrderOfMaterialsForProduction", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn đặt hàng gia công';
					|ru = 'Заказы переработчикам';
					|en = 'Subcontracting purchase orders';
					|it = 'Заказы переработчикам';
					|pl = 'Zamówienia do przetwórców';
					|tr = 'Fason satın alma siparişleri'"; // @NStr
	AddPropertySetElement(Items, "627424a6-eb85-4b56-be26-11faf80f9d9d", 
	"Document_SubcontractOrder2_5", Description, LanguagesCodes);
	
	Description = "vi = 'Ký hợp đồng thuê';
					|ru = 'Заключение договоров аренды';
					|en = 'Rental contracts signing';
					|it = 'Заключение договоров аренды';
					|pl = 'Zawarcie umów dzierżawy';
					|tr = 'Kira sözleşmelerinin sonuçlandırılması'"; // @NStr
	AddPropertySetElement(Items, "498bfb4b-2638-4975-8a9d-fb50e0b84c7c", 
	"Document_SigningOfLeaseContract", Description, LanguagesCodes);
	
	Description = "vi = 'Thay đổi tham số TSCĐVH';
					|ru = 'Изменение параметров НМА';
					|en = 'Adjust intangible asset financial details';
					|it = 'Изменение параметров НМА';
					|pl = 'Zmiana parametrów wartości niematerialnych';
					|tr = 'Maddi olmayan varlık finansal bilgi düzeltmesi'"; // @NStr
	AddPropertySetElement(Items, "834a7cc0-094d-40da-860a-b00aa10e8cab", 
	"Document_ChangeIntangibleAssetFinancialDetails2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Thay đổi cài đặt TSCĐ hữu hình';
					|ru = 'Изменение параметров ОС';
					|en = 'Adjust fixed asset financial details';
					|it = 'Изменение параметров ОС';
					|pl = 'Zmiana parametrów środków trwałych';
					|tr = 'Sabit kıymet finansal bilgi düzeltmesi'"; // @NStr
	AddPropertySetElement(Items, "a54bd05c-a4a9-40b9-b0e3-975314db71aa", 
	"Document_ChangeFixedAssetFinancialDetails2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Thay đổi điều khoản hợp đồng thuê';
					|ru = 'Изменение условий договоров аренды';
					|en = 'Rental terms adjustment';
					|it = 'Изменение условий договоров аренды';
					|pl = 'Zmiana warunków umów dzierżawy';
					|tr = 'Kira koşulu düzeltmesi'"; // @NStr
	AddPropertySetElement(Items, "13cced4a-ddfe-4aa5-9052-4b0651b66c6e", 
	"Document_LeaseTermAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Thay đổi điều kiện chuyển giao cho thuê';
					|ru = 'Изменение условий передачи в аренду';
					|en = 'Change rental terms';
					|it = 'Изменение условий передачи в аренду';
					|pl = 'Change rental terms';
					|tr = 'Kira devir şartlarının değiştirilmesi'"; // @NStr
	AddPropertySetElement(Items, "8b6f7237-1f75-465b-835a-296b42517bac", 
	"Document_ChangeRentalTerms", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh giá trị và khấu hao tài sản cố định vô hình';
					|ru = 'Корректировка стоимости и амортизации НМА';
					|en = 'Adjust intangible asset cost and amortization';
					|it = 'Корректировка стоимости и амортизации НМА';
					|pl = 'Korekta wartości i amortyzacji ANM';
					|tr = 'Maddi olmayan varlık maliyet ve amortisman düzeltmesi'"; // @NStr
	AddPropertySetElement(Items, "458eb5bd-ad91-425e-9b2d-740d238a2af2", 
	"Document_IntangibleAssetsCostAndAmortizationAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chỉnh giá trị và khấu hao TSCĐ';
					|ru = 'Корректировка стоимости и амортизации ОС';
					|en = 'Adjust fixed asset cost and depreciation';
					|it = 'Корректировка стоимости и амортизации ОС';
					|pl = 'Korekta wartości i amortyzacji ŚT';
					|tr = 'Sabit kıymet maliyet ve amortisman düzeltmesi'"; // @NStr
	AddPropertySetElement(Items, "c44e8926-8c2d-4d2a-82d1-5fbbfc33ef56", 
	"Document_FixedAssetCostAndDepreciationAdjustment", Description, LanguagesCodes);
	
	Description = "vi = 'Nâng cấp TSCĐ';
					|ru = 'Модернизация ОС';
					|en = 'Fixed assets appreciation';
					|it = 'Модернизация ОС';
					|pl = 'Modernizacja środków trwałych';
					|tr = 'SV modernizasyonu'"; // @NStr
	AddPropertySetElement(Items, "eb1ae85f-0ff9-4943-bd1c-26ff4cc4ccc7", 
	"Document_FixedAssetsCostAdditions2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Đưa các chênh lệch vào giá trị tài sản cố định';
					|ru = 'Отнесение отклонений в стоимость ОС';
					|en = 'Allocate variances to fixed asset cost';
					|it = 'Allocate variances to fixed asset cost';
					|pl = 'Allocate variances to fixed asset cost';
					|tr = 'Farkların sabit kıymet maliyetine yüklenmesi'"; // @NStr
	AddPropertySetElement(Items, "742d8aef-7795-456c-960b-ac0daf7ce61e", 
	"Document_AllocateVariancesToFixedAssetCost", Description, LanguagesCodes);
	
	Description = "vi = 'Hợp nhất TSCĐ';
					|ru = 'Объединение ОС';
					|en = 'Merge fixed assets';
					|it = 'Объединение ОС';
					|pl = 'Połączenie ŚT';
					|tr = 'Sabit kıymet birleşmesi'"; // @NStr
	AddPropertySetElement(Items, "92e3a550-9e20-4937-967f-38fcd8d8e0e4", 
	"Document_MergeOfFixedAssets", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê hàng hóa của bên nhận gia công';
					|ru = 'Отчеты переработчиков';
					|en = 'Subcontracting services notifications received';
					|it = 'Отчеты переработчиков';
					|pl = 'Raporty przetwórców';
					|tr = 'Alınan fason hizmetleri bildirimi'"; // @NStr
	AddPropertySetElement(Items, "76741a5f-9dff-42cc-aabc-1e34d3885b72", 
	"Document_SubcontractorReport2_5", Description, LanguagesCodes);
	
	Description = "vi = 'Điều chuyển TSCĐ hữu hình';
					|ru = 'Перемещение ОС';
					|en = 'Transfer fixed assets';
					|it = 'Перемещение ОС';
					|pl = 'Przemieszczenie środków trwałych';
					|tr = 'Sabit kıymet transferi'"; // @NStr
	AddPropertySetElement(Items, "e3a78434-82f7-4d6d-a342-3fbefbefd069", 
	"Document_FATransfer2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Kế hoạch sản xuất';
					|ru = 'Планы производства';
					|en = 'Production plans';
					|it = 'Планы производства';
					|pl = 'Plany produkcji';
					|tr = 'Üretim planları'"; // @NStr
	AddPropertySetElement(Items, "ae919624-9533-4775-bc0c-ac5019059399", 
	"Document_ProductionPlan", Description, LanguagesCodes);
	
	Description = "vi = 'Chuẩn bị chuyển giao TSCĐ hữu hình';
					|ru = 'Подготовка к передаче ОС';
					|en = 'Prepare for sale of fixed assets';
					|it = 'Подготовка к передаче ОС';
					|pl = 'Przygotowanie do przekazania środków trwałych';
					|tr = 'Sabit kıymet satışına hazırlık'"; // @NStr
	AddPropertySetElement(Items, "1d2705d6-f523-4b07-a638-190c77b8b002", 
	"Document_PreparingForFixedAssetSale2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Tiếp nhận dịch vụ thuê';
					|ru = 'Поступление услуг по аренде';
					|en = 'Receiving rental services';
					|it = 'Поступление услуг по аренде';
					|pl = 'Wpływ usług dotyczących dzierżawy';
					|tr = 'Kiralama hizmetleri makbuzu'"; // @NStr
	AddPropertySetElement(Items, "c8f306e8-4c81-4eec-9be4-5456cc4756bf", 
	"Document_ReceivingLeaseServices", Description, LanguagesCodes);
	
	Description = "vi = 'Chấm dứt hợp đồng thuê';
					|ru = 'Прекращение договоров аренды';
					|en = 'Termination of rental contracts';
					|it = 'Прекращение договоров аренды';
					|pl = 'Wygaśnięcie umów dzierżawy';
					|tr = 'Kira sözleşmesi feshi'"; // @NStr
	AddPropertySetElement(Items, "66855b6a-dc14-4ba2-beb1-92fdf8d41818", 
	"Document_LeaseTermination", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi nhận chi phí nghiên cứu và phát triển';
					|ru = 'Признание расходов по исследованиям и разработкам';
					|en = 'R&D expense recognition';
					|it = 'Признание расходов по исследованиям и разработкам';
					|pl = 'Uznanie rozchodów wg badań i opracowań';
					|tr = 'Ar-Ge giderlerinin muhasebeleştirilmesi'"; // @NStr
	AddPropertySetElement(Items, "b8cf2d72-6c64-4ba9-89ad-9f6d8e8b7713", 
	"Document_RDExpenseRecognition", Description, LanguagesCodes);
	
	Description = "vi = 'Bắt đầu hạch toán TSCĐ vô hình';
					|ru = 'Принятие к учету НМА';
					|en = 'Intangible assets — Initial recognition';
					|it = 'Принятие к учету НМА';
					|pl = 'Przyjęcie do ewidencji wartości niematerialnych';
					|tr = 'Maddi olmayan varlıklar - İlk tahakkuk'"; // @NStr
	AddPropertySetElement(Items, "80a5c6e3-0281-4424-b62e-3ea2ab7e6fd9", 
	"Document_IntangibleAssetsInitialRecognition2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách chứng từ ""Tiếp nhận vào kế toán TSCĐ""';
					|ru = 'Список документов ""Принятие к учету ОС""';
					|en = '""Fixed assets — Initial recognition"" document list';
					|it = 'Список документов ""Принятие к учету ОС""';
					|pl = 'Lista dokumentów ""Przyjęcie do ewidencji ŚT""';
					|tr = '""Sabit kıymetler - İlk tahakkuk"" belgelerinin listesi'"; // @NStr
	AddPropertySetElement(Items, "2e960f2e-bf5d-4f4e-8f3e-24c6a818ae3b", 
	"Document_FixedAssetsInitialRecognition2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Tiếp nhận vào kế toán các bộ phận và thành phần khấu hao';
					|ru = 'Принятие к учету узлов и компонентов амортизации';
					|en = 'Recognize sub-assets and components of depreciation';
					|it = 'Принятие к учету узлов и компонентов амортизации';
					|pl = 'Przyjęcie do ewidencji węzłów i komponentów amortyzacji';
					|tr = 'Alt varlıkların ve amortisman bileşenlerinin muhasebeleştirilmesi'"; // @NStr
	AddPropertySetElement(Items, "280a6172-d24e-4cb2-a492-1eb3fb32da8d", 
	"Document_RecognizeSubAssetsComponentsOfDepreciation", Description, LanguagesCodes);
	
	Description = "vi = 'Sản xuất không theo đơn đặt hàng';
					|ru = 'Производство без заказа';
					|en = 'Backflush production';
					|it = 'Производство без заказа';
					|pl = 'Produkcja bez zamówień';
					|tr = 'Geriye dönük üretim'"; // @NStr
	AddPropertySetElement(Items, "9365622e-b582-4329-971d-dffd928eb5ec", 
	"Document_BackflushProduction", Description, LanguagesCodes);
	
	Description = "vi = 'TSCĐ ngừng hoạt động';
					|ru = 'Разукомплектация ОС';
					|en = 'Split fixed assets';
					|it = 'Разукомплектация ОС';
					|pl = 'Zdekompletowanie ST';
					|tr = 'SV''lerin bölünmesi'"; // @NStr
	AddPropertySetElement(Items, "23b4a057-b965-49eb-8b2f-de2a0d26abe2", 
	"Document_SplitFixedAssets", Description, LanguagesCodes);
	
	Description = "vi = 'Phân bổ phế liệu thu hồi';
					|ru = 'Распределения возвратных отходов';
					|en = 'Recyclable waste allocation';
					|it = 'Распределения возвратных отходов';
					|pl = 'Podział zwrotnych odpadów';
					|tr = 'Geri dönüştürülebilir atık dağıtımı'"; // @NStr
	AddPropertySetElement(Items, "ff767172-5efa-4b5c-ae58-dd3cb60cb169", 
	"Document_RecyclableWasteAllocation", Description, LanguagesCodes);
	
	Description = "vi = 'Phân bổ chi phí nguyên vật liệu và nhân công';
					|ru = 'Распределение материалов и работ';
					|en = 'Material and labor allocation';
					|it = 'Распределение материалов и работ';
					|pl = 'Rozdział materiałów i prac';
					|tr = 'Malzeme ve iş dağıtımı'"; // @NStr
	AddPropertySetElement(Items, "5d382cc7-0c8c-4e7d-8f7f-ada5dc0edff9", 
	"Document_ProductionCostAllocation", Description, LanguagesCodes);
	
	Description = "vi = 'Ghi giảm TSCĐ vô hình';
					|ru = 'Списание НМА';
					|en = 'Dispose intangible assets';
					|it = 'Списание НМА';
					|pl = 'Wyksięgowanie wartości niematerialnych';
					|tr = 'Maddi olmayan varlık gider yazma'"; // @NStr
	AddPropertySetElement(Items, "c8b8cbf7-634b-43c6-bbb2-087497ad2a2b", 
	"Document_DisposeIntangibleAssets2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách chứng từ ""Ghi giảm TSCĐ""';
					|ru = 'Список документов ""Списание ОС""';
					|en = '""Dispose fixed assets"" document list';
					|it = 'Список документов ""Списание ОС""';
					|pl = 'Lista dokumentów ""Rozchód ŚT""';
					|tr = '""Sabit kıymetlerin tasfiyesi"" belgelerinin listesi'"; // @NStr
	AddPropertySetElement(Items, "58e7a2b2-7810-4bad-9a39-056fd8aff917", 
	"Document_DisposeFixedAssets2_4", Description, LanguagesCodes);
	
	Description = "vi = 'Cải thiện TSCĐ vô hình';
					|ru = 'Улучшение НМА';
					|en = 'Intangible asset improvement';
					|it = 'Улучшение НМА';
					|pl = 'Intangible asset improvement';
					|tr = 'GMA''nın iyileştirilmesi'"; // @NStr
	AddPropertySetElement(Items, "66f0a8af-c93d-433e-8d02-837f7877cb55", 
	"Document_IntangibleAssetImprovement", Description, LanguagesCodes);
	
	Description = "vi = 'Kiểm kê tài sản cố định vô hình';
					|ru = 'Инвентаризация НМА';
					|en = 'Intangible assets — Physical inventory';
					|it = 'Inventario attivi immateriali';
					|pl = 'Inwentaryzacja wartości niematerialnych';
					|tr = 'Maddi olmayan varlıklar - Fiziksel stok'"; // @NStr
	AddPropertySetElement(Items, "582e5ba1-d12e-48a3-96d7-2c76b42a6258", 
	"Document_IntangibleAssetsPhysicalCount", Description, LanguagesCodes);
	
	Description = "vi = 'Kiểm kê TSCĐ hữu hình';
					|ru = 'Инвентаризация ОС';
					|en = 'Fixed assets — Physical inventory';
					|it = 'Inventario capitali fissi';
					|pl = 'Inwentaryzacja środka trwałego';
					|tr = 'Sabit kıymetler - Fiziksel stok'"; // @NStr
	AddPropertySetElement(Items, "9b3ee5e0-96f3-48f4-93fb-ec2958733d98", 
	"Document_FixedAssetsPhysicalCount", Description, LanguagesCodes);
	
	Description = "vi = 'Chứng từ nhập các chỉ tiêu ngân sách';
					|ru = 'Экземпляры бюджетов';
					|en = 'Budget entry forms';
					|it = 'Экземпляры бюджетов';
					|pl = 'Egzemplarzy budżetów';
					|tr = 'Bütçe giriş formları'"; // @NStr
	AddPropertySetElement(Items, "1b46fd46-d88e-43ab-a77f-b8fdc23c6045", 
	"Document_BudgetEntryForm", Description, LanguagesCodes);
	
	Description = "vi = 'Đội lao động';
					|ru = 'Бригады';
					|en = 'Work teams';
					|it = 'Бригады';
					|pl = 'Work teams';
					|tr = 'Çalışma ekipleri'"; // @NStr
	AddPropertySetElement(Items, "bd297921-d608-4512-8c3e-2ec7439f0936", 
	"Catalog_Teams", Description, LanguagesCodes);
	
	Description = "vi = 'Thiết lập các chỉ tiêu báo cáo ngân sách';
					|ru = 'Виды бюджетов';
					|en = 'Budget profiles';
					|it = 'Виды бюджетов';
					|pl = 'Rodzaje budżetów';
					|tr = 'Bütçe profilleri'"; // @NStr
	AddPropertySetElement(Items, "b159b10b-4ddc-4c04-a0bc-79716efde652", 
	"Catalog_BudgetProfiles", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng công việc người lao động';
					|ru = 'Виды работ сотрудников';
					|en = 'Employee activity kinds';
					|it = 'Виды работ сотрудников';
					|pl = 'Rodzaje pracy ';
					|tr = 'Çalışanların iş türleri'"; // @NStr
	AddPropertySetElement(Items, "294076d5-784c-405f-b5ff-cbb1363472c9", 
	"Catalog_EmployeeWorkKinds", Description, LanguagesCodes);
	
	Description = "vi = 'Hợp đồng thuê (leasing)';
					|ru = 'Договоры аренды (лизинга)';
					|en = 'Rental (financial lease) contracts';
					|it = 'Договоры аренды (лизинга)';
					|pl = 'Umowy dzierżawy (leasingu)';
					|tr = 'Kiralama sözleşmesi (finansal kiralama)'"; // @NStr
	AddPropertySetElement(Items, "1e77da49-a7f4-43e0-8aa0-f999bafcb1c7", 
	"Catalog_LeaseContract", Description, LanguagesCodes);
	
	Description = "vi = 'Tài sản cố định vô hình và chi phí nghiên cứu và phát triển';
					|ru = 'НМА и расходы на НИОКР';
					|en = 'Intangible assets and R&D expenses';
					|it = 'НМА и расходы на НИОКР';
					|pl = 'Aktywa niematerialne i wydatki na prace naukowo-badawcze i doświadczalno-konstrukcyjne';
					|tr = 'Maddi olmayan varlıklar ve Ar-ge giderleri'"; // @NStr
	AddPropertySetElement(Items, "9a376657-e800-49cc-822c-12f73cb43b5d", 
	"Catalog_IntangibleAssets", Description, LanguagesCodes);
	
	Description = "vi = 'Chỉ tiêu ngân sách phi tài chính';
					|ru = 'Нефинансовые показатели бюджетов';
					|en = 'Non-financial items of budgets';
					|it = 'Нефинансовые показатели бюджетов';
					|pl = 'Niefinansowane wskaźniki budżetów';
					|tr = 'Mali olmayan bütçe dengesi kalemleri'"; // @NStr
	AddPropertySetElement(Items, "40e12415-ec59-45e3-b25c-eaf2d880a6d7", 
	"Catalog_NonFinancialItemsOfBudgets", Description, LanguagesCodes);
	
	Description = "vi = 'Đối tượng xây dựng cơ bản';
					|ru = 'Объекты строительства';
					|en = 'Assets under construction';
					|it = 'Объекты строительства';
					|pl = 'Obiekty budowy';
					|tr = 'Yapım aşamasındaki varlıklar'"; // @NStr
	AddPropertySetElement(Items, "e8235a22-2752-4e84-96c1-74512da4ae79", 
	"Catalog_ConstructionObjects", Description, LanguagesCodes);
	
	Description = "vi = 'Đối tượng kế toán dự phòng cho các chi phí trong tương lai';
					|ru = 'Объекты учета резервов предстоящих расходов';
					|en = 'Objects of provisions and contingent liabilities';
					|it = 'Объекты учета резервов предстоящих расходов';
					|pl = 'Obiekty ewidencji rezerw przyszłych wydatków';
					|tr = 'Karşılık nesneleri'"; // @NStr
	AddPropertySetElement(Items, "d4ec47fc-c373-4e3e-8ebc-367b5bb292ec", 
	"Catalog_AccountingObjectsOfFutureExpenseCommitments", Description, LanguagesCodes);
	
	Description = "vi = 'Lô sản xuất';
					|ru = 'Партии производства';
					|en = 'Production lots';
					|it = 'Партии производства';
					|pl = 'Partie produkcji';
					|tr = 'Üretim lotları'"; // @NStr
	AddPropertySetElement(Items, "0b493c2f-1432-4bc5-b94a-8257cbfbe6eb", 
	"Catalog_ProductionLots", Description, LanguagesCodes);
	
	Description = "vi = 'Chỉ tiêu ngân sách';
					|ru = 'Показатели бюджетов';
					|en = 'Budget balance items';
					|it = 'Показатели бюджетов';
					|pl = 'Wskaźniki budżetowe';
					|tr = 'Bütçe dengesi kalemleri'"; // @NStr
	AddPropertySetElement(Items, "78b57f4f-93f2-487c-bcfa-8efa77c90003", 
	"Catalog_BudgetBalanceItems", Description, LanguagesCodes);
	
	Description = "vi = 'Các loại dự phòng và nợ phải trả ước tính';
					|ru = 'Виды резервов и оценочных обязательств';
					|en = 'Types of provisions';
					|it = 'Виды резервов и оценочных обязательств';
					|pl = 'Rodzaje rezerw i szacowanych zobowiązań';
					|tr = 'Rezervlerin veya değerleme yükümlülüklerinin türleri'"; // @NStr
	AddPropertySetElement(Items, "7d340d32-0863-4e7d-a2b5-5bb8450c6f6b", 
	"Catalog_Reserves", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất';
					|ru = 'Ресурсные спецификации';
					|en = 'Bills of materials';
					|it = 'Ресурсные спецификации';
					|pl = 'Specyfikacje zasobów';
					|tr = 'Ürün reçeteleri'"; // @NStr
	AddPropertySetElement(Items, "4f1f948d-a242-4086-a0bc-7a2819813979", 
	"Catalog_BillsOfMaterials", Description, LanguagesCodes);
	
	Description = "vi = 'Khoản mục ngân sách';
					|ru = 'Статьи бюджетов';
					|en = 'Budget flow items';
					|it = 'Статьи бюджетов';
					|pl = 'Pozycje budżetowe';
					|tr = 'Bütçe kalemleri'"; // @NStr
	AddPropertySetElement(Items, "11ddb9cc-3508-4a40-a69b-9d5c4f9885a2", 
	"Catalog_BudgetFlowItems", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng tính giá thành';
					|ru = 'Статьи калькуляции';
					|en = 'Product cost elements';
					|it = 'Статьи калькуляции';
					|pl = 'Pozycje kalkulacji';
					|tr = 'Ürün maliyet kalemleri'"; // @NStr
	AddPropertySetElement(Items, "5bdbbb97-9f58-4e0d-9515-53a408082ede", 
	"Catalog_ProductCostElements", Description, LanguagesCodes);
	
	Description = "vi = 'Đề tài, giai đoạn nghiên cứu và phát triển';
					|ru = 'Темы, этапы исследований и разработок';
					|en = 'R&D topics, stages';
					|it = 'Темы, этапы исследований и разработок';
					|pl = 'Tematy, etapy badań i opracowań';
					|tr = 'Konu, araştırma ve geliştirme aşaması'"; // @NStr
	AddPropertySetElement(Items, "2c0bfb5b-12e7-4b58-95f9-87b6707611fb", 
	"Catalog_RDTopicsStages", Description, LanguagesCodes);
	
	Description = "vi = 'Công đoạn danh sách bảng kê chi tiết các nguồn lực sản xuất';
					|ru = 'Этапы ресурсной спецификации';
					|en = 'Bill of materials stages';
					|it = 'Этапы ресурсной спецификации';
					|pl = 'Etapy specyfikacji zasobów';
					|tr = 'Ürün reçetesi aşamaları'"; // @NStr
	AddPropertySetElement(Items, "dae5dd83-1274-4f37-a9ca-8604bb97c3da", 
	"Catalog_ProductionStages", Description, LanguagesCodes);
	
	Description = "vi = 'Phương pháp phản ánh chi phí';
					|ru = 'Способы отражения расходов';
					|en = 'Expense record methods';
					|it = 'Способы отражения расходов';
					|pl = 'Expense record methods';
					|tr = 'Gider yansıtma yöntemleri'"; // @NStr
	AddPropertySetElement(Items, "b83d56a8-e766-416b-add7-865e607e0cd2", 
	"Catalog_WaysToReflectExpenses", Description, LanguagesCodes);

	
	
	Description = "vi = 'Đơn hàng nhận gia công';
					|ru = 'Заказы давальцев';
					|en = 'Subcontracting sales orders';
					|it = 'Заказы давальцев';
					|pl = 'Zamówienia właścicieli surowców';
					|tr = 'Sağlayıcı siparişleri'"; // @NStr
	AddPropertySetElement(Items, "d6b0f9c2-16b7-40c6-ae8a-8ce7d89d71a2", 
	"Document_MaterialProviderOrder2_5", Description, LanguagesCodes);
	
	Description = "vi = 'Đơn hàng sản xuất';
					|ru = 'Заказы на производство';
					|en = 'Production orders';
					|it = 'Заказы на производство';
					|pl = 'Zamówienia na produkcję';
					|tr = 'Üretim emirleri'"; // @NStr
	AddPropertySetElement(Items, "2033a0f9-4544-4fd7-b9f0-39576d4436b2", 
	"Document_ProductionOrder2_2", Description, LanguagesCodes);
	
	Description = "vi = 'Danh sách phiếu yêu cầu sửa chữa';
					|ru = 'Список заказов на ремонт';
					|en = 'R&M order list';
					|it = 'Список заказов на ремонт';
					|pl = 'Lista zamówień remontowych';
					|tr = 'Onarım emirlerinin listesi'"; // @NStr
	AddPropertySetElement(Items, "c814d3bb-6c98-4c47-9c58-b382d8dbde4d", 
	"Document_RMOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Bảng kê dành cho bên đặt gia công';
					|ru = 'Отчеты давальцам';
					|en = 'Consumption reports — Subcontracting services delivered';
					|it = 'Отчеты давальцам';
					|pl = 'Raporty dla właścicieli surowców';
					|tr = 'Tüketim raporu-Verilen fason hizmetleri'"; // @NStr
	AddPropertySetElement(Items, "21f43da9-1947-4e04-94e5-08a3a192c925", 
	"Document_ReportToMaterialProvider2_5", Description, LanguagesCodes);
	
	Description = "vi = 'Báo cáo dành cho người đặt gia công giữa các doanh nghiệp';
					|ru = 'Отчеты давальцам между организаций';
					|en = 'Intercompany consumption reports — Subcontracting services delivered';
					|it = 'Отчеты давальцам между организаций';
					|pl = 'Intercompany consumption reports — Subcontracting services delivered';
					|tr = 'İş yerleri arası tüketim raporu-Verilen fason hizmetleri'"; // @NStr
	AddPropertySetElement(Items, "8002a98a-623d-4822-bdcf-54561124514c", 
	"Document_ConsumptionReportSubcontractingServicesDeliveredIntercompany", Description, LanguagesCodes);
	
	Description = "vi = 'Cho phép thay thế vật liệu';
					|ru = 'Разрешения на замену материалов';
					|en = 'Engineering change orders';
					|it = 'Разрешения на замену материалов';
					|pl = 'Zgoda na wykorzystania zamienników';
					|tr = 'Mühendislik değişiklik emri'"; // @NStr
	AddPropertySetElement(Items, "ee594808-3f12-454a-8e83-d2bde4e43e23", 
	"Document_EngineeringChangeOrder", Description, LanguagesCodes);
	
	Description = "vi = 'Ca làm việc';
					|ru = 'Сменные задания';
					|en = 'Shift tasks';
					|it = 'Сменные задания';
					|pl = 'Zadania zmiany';
					|tr = 'Vardiyalı görevler'"; // @NStr
	AddPropertySetElement(Items, "ca69dd34-efe1-4768-86f0-0fb4a6292cc0", 
	"Document_ShiftTask", Description, LanguagesCodes);
	
	Description = "vi = 'Công đoạn sản xuất';
					|ru = 'Этапы производства';
					|en = 'Production stages';
					|it = 'Этапы производства';
					|pl = 'Etapy produkcji';
					|tr = 'Üretim aşamaları'"; // @NStr
	AddPropertySetElement(Items, "92d08fd3-4d0a-4922-887a-86ef4e313706", 
	"Document_ProductionStage2_2", Description, LanguagesCodes);
	
	Description = "vi = 'Dạng nguồn lực sản xuất';
					|ru = 'Виды рабочих центров';
					|en = 'Work center types';
					|it = 'Виды рабочих центров';
					|pl = 'Rodzaj centrów wykonania pracy';
					|tr = 'İş merkezi türleri'"; // @NStr
	AddPropertySetElement(Items, "a070ee7e-3dca-471b-a0d4-a49bfed42c83", 
	"Catalog_WorkCenterTypes", Description, LanguagesCodes);
	
	Description = "vi = 'Sơ đồ quy trình';
					|ru = 'Маршрутные карты';
					|en = 'Route sheets';
					|it = 'Маршрутные карты';
					|pl = 'Karty technologiczne';
					|tr = 'Rotalar'"; // @NStr
	AddPropertySetElement(Items, "7d45c880-b9e6-46da-a6cb-a558f14f6bde", 
	"Catalog_RouteSheets", Description, LanguagesCodes);
	
	Description = "vi = 'Địa điểm sản xuất';
					|ru = 'Производственные участки';
					|en = 'Production sites';
					|it = 'Производственные участки';
					|pl = 'Piony produkcyjne';
					|tr = 'Üretim yerleri'"; // @NStr
	AddPropertySetElement(Items, "525c0f81-2e46-4946-83b4-dfff5fdd417b", 
	"Catalog_ProductionSites", Description, LanguagesCodes);
	
	Description = "vi = 'Nguồn lực sản xuất';
					|ru = 'Рабочие центры';
					|en = 'Work centers';
					|it = 'Рабочие центры';
					|pl = 'Centr wykonania prac';
					|tr = 'İş merkezleri'"; // @NStr
	AddPropertySetElement(Items, "1b8687a8-d9eb-48d2-b32c-4a0b906f0457", 
	"Catalog_WorkCenters", Description, LanguagesCodes);
	
	Description = "vi = 'Thao tác chế tạo';
					|ru = 'Технологические операции';
					|en = 'Technological operations';
					|it = 'Технологические операции';
					|pl = 'Operacje technologiczne';
					|tr = 'Teknolojik işlemler'"; // @NStr
	AddPropertySetElement(Items, "4866c0e3-b01b-4b40-a78e-a7af83da2f79", 
	"Catalog_ManufacturingOperations", Description, LanguagesCodes);
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_ARAPObjects";
	Set.Ref = New UUID("ae562360-2ddb-41d4-affa-1d1bcab44b64");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Đối tượng hạch toán';
		|ru = 'Объекты расчетов';
		|en = 'AR/AP objects';
		|it = 'Oggetti di regolamenti';
		|pl = 'Obiekty rozliczeń';
		|tr = 'Alacak/Borç nesneleri'", LanguagesCodes); // @NStr-2

	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_UserNotificationKinds";
	Set.Ref = New UUID("fc305419-3db3-4971-b4e5-c90826790356");
	Set.Used  = GetFunctionalOption("UseUserNotificationsOfSystemEvents");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Dạng thông báo cho người sử dụng';
		|ru = 'Виды оповещений пользователей';
		|en = 'User notification kinds';
		|it = 'User notification kinds';
		|pl = 'User notification kinds';
		|tr = 'Kullanıcı bildirimlerinin türleri'", LanguagesCodes); // @NStr-2
	
EndProcedure

// Adds a set of additional Attributes and information.
//
// Parameters:
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  Id - String - The unique identifier of the set.
//  SetName - String - The owner of the set.
//  Description - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//
Procedure AddPropertySetElement(Items, Id, SetName, Description, LanguagesCodes)
	
	Set = Items.Add();
	Set.PredefinedSetName = SetName;
	Set.Ref = New UUID(Id);
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		Description, LanguagesCodes);
	
EndProcedure

#EndRegion

#EndRegion
