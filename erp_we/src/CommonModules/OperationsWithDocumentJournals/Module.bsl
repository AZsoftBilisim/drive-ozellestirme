////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for the user
// to work with document logs.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the time limit for updating the list of documents.
// 
// Returns:
//  Number - Time Limit For Updating The List Of Documents
Function TimeLimitForUpdatingListOfDocuments() Export

	TimeLimitForUpdatingList = Constants.TimeLimitForUpdatingListOfDocuments.Get();
	
	Return TimeLimitForUpdatingList;

EndFunction

// The structure of the list's user settings.
// 
// Returns:
//  Structure - Structure Of The User Settings Of the List:
// * ListName - String - 
// * NameOfListItem - String - 
// * HasMainTable - Boolean - 
// * ListKeys - Map of String - 
// * ListOfCompositeTypeFields - Array of String- 
// * DataIsOutdated - Boolean - 
// * UpdatingDuration - Number - 
// * TimeLimitForUpdatingListOfDocuments - Number - 
// * TheRefreshButton - String - 
// * AttributeNameAutoUpdateMode - String - 
// * AttributeNameProductiveUpdateMode - String -
// * ProblematicSettingsElement - String - 
// * ItemTitleOfListIssue - String - 
// * SelectedFieldsElement - String - 
// * HeaderElementSelectedFields - String - 
// * SelectedFieldsCriticalElement - String - 
// * SelectedFieldsElementIsNormal - String - 
// * ItemSelectedFieldsFix - String - 
// * ListSelectionsElement - String - 
// * SelectionHeaderElement - String - 
// * ElementSelectionCritical - String - 
// * SelectionElementIsOrdinary - String - 
// * ElementSelectionsFix - String - 
// * ListOrderElement - String - 
// * HeadingOrderElement - String - 
// * ElementOrderCritical - String - 
// * OrderElementIsOrdinary - String - 
// * FixOrderElement - String - 
// * ListConditionalAppearanceElement - String - 
// * HeadingConditionalAppearanceElement - String - 
// * ConditionalAppearanceElementIsCritical - String - 
// * ConditionalAppearanceElementIsOrdinary - String - 
// * FixConditionalAppearanceElement - String - 
// * GroupNoProblems - String - 
// * GroupIrrelevantData - String - 
// * GroupDescriptionOfProblems - String - 
// * DataLayoutSettingsHaveBeenChecked - Boolean - 
// * DataCompositionSettings - DataCompositionSettings - 
// * StructureOfUserSettings - See OperationsWithDocumentJournals.CheckUserSettingsOfDynamicList
Function StructureOfUserSettingsOfList() Export

	ParametersStructure = New Structure;
	ParametersStructure.Insert("ListName", "");
	ParametersStructure.Insert("NameOfListItem", "");
	ParametersStructure.Insert("HasMainTable", True);
	ParametersStructure.Insert("ListKeys", New Map);
	ParametersStructure.Insert("ListOfCompositeTypeFields", New Array);
	ParametersStructure.Insert("DataIsOutdated", False);
	ParametersStructure.Insert("UpdatingDuration", 0);
	ParametersStructure.Insert("TimeLimitForUpdatingListOfDocuments", 2);
	ParametersStructure.Insert("TheRefreshButton", "");
	ParametersStructure.Insert("GroupNoProblems", "");
	ParametersStructure.Insert("GroupIrrelevantData", "");
	ParametersStructure.Insert("GroupDescriptionOfProblems", "");
	ParametersStructure.Insert("AttributeNameAutoUpdateMode", "");
	ParametersStructure.Insert("AttributeNameProductiveUpdateMode", "");
	ParametersStructure.Insert("ProblematicSettingsElement", "");
	ParametersStructure.Insert("ItemTitleOfListIssue", "");
	ParametersStructure.Insert("SelectedFieldsElement", "");
	ParametersStructure.Insert("HeaderElementSelectedFields", "");
	ParametersStructure.Insert("SelectedFieldsCriticalElement", "");
	ParametersStructure.Insert("SelectedFieldsElementIsNormal", "");
	ParametersStructure.Insert("ItemSelectedFieldsFix", "");
	ParametersStructure.Insert("ListSelectionsElement", "");
	ParametersStructure.Insert("SelectionHeaderElement", "");
	ParametersStructure.Insert("ElementSelectionCritical", "");
	ParametersStructure.Insert("SelectionElementIsOrdinary", "");
	ParametersStructure.Insert("ElementSelectionsFix", "");
	ParametersStructure.Insert("ListOrderElement", "");
	ParametersStructure.Insert("HeadingOrderElement", "");
	ParametersStructure.Insert("ElementOrderCritical", "");
	ParametersStructure.Insert("OrderElementIsOrdinary", "");
	ParametersStructure.Insert("FixOrderElement", "");
	ParametersStructure.Insert("ListConditionalAppearanceElement", "");
	ParametersStructure.Insert("HeadingConditionalAppearanceElement", "");
	ParametersStructure.Insert("ConditionalAppearanceElementIsCritical", "");
	ParametersStructure.Insert("ConditionalAppearanceElementIsOrdinary", "");
	ParametersStructure.Insert("FixConditionalAppearanceElement", "");
	ParametersStructure.Insert("DataCompositionSettings", New DataCompositionSettings);
	ParametersStructure.Insert("DataLayoutSettingsHaveBeenChecked", False);
	ParametersStructure.Insert("StructureOfUserSettings", New Structure);

	Return ParametersStructure;

EndFunction

// Set dynamic list properties (main table: Register of documents).
// 
// Parameters:
//  List - DynamicList -
//  ListKeys - Map of String - list of dynamic list keys
//  CompositeTypeFields - Undefined, Array of String - List Of Composite Type Fields
//  UseProductiveUpdateMode - Boolean - Indicates whether the list update acceleration mode is being used
//
Procedure SetPropertiesOfDynamicListTableDocumentRegistry(List, ListKeys,
	CompositeTypeFields = Undefined, UseProductiveUpdateMode = False) Export

	If UseProductiveUpdateMode Then

		List.MainTable = "";

		KeyFields = New Array;
		KeyFields.Add(ListKeys.Get("RefType"));
		KeyFields.Add(ListKeys.Get("BusinessOperation"));
		KeyFields.Add(ListKeys.Get("Date"));
		KeyFields.Add(ListKeys.Get("RecordID"));

		List.KeyFields = New FixedArray(KeyFields);
		List.KeyType = DynamicListKeyType.RowKey;
		List.DynamicDataRead = True;

	EndIf;

	If Not CompositeTypeFields = Undefined Then

		For Each Item In List.SettingsComposer.Settings.SelectionAvailableFields.Items Do

			FieldTypes = Item.Type.Types();
			If FieldTypes.Count() > 1 Then
				CompositeTypeFields.Add(String(Item.Field));
			EndIf;

		EndDo;

		For Each Item In List.SettingsComposer.Settings.GroupAvailableFields.Items Do

			FieldTypes = Item.Type.Types();
			If FieldTypes.Count() > 1 Then
				CompositeTypeFields.Add(String(Item.Field));
			EndIf;

		EndDo;

		For Each Item In List.SettingsComposer.Settings.FilterAvailableFields.Items Do

			FieldTypes = Item.Type.Types();
			If FieldTypes.Count() > 1 Then
				CompositeTypeFields.Add(String(Item.Field));
			EndIf;

		EndDo;

		For Each Item In List.SettingsComposer.Settings.StructureItemsFilterAvailableFields.Items Do

			FieldTypes = Item.Type.Types();
			If FieldTypes.Count() > 1 Then
				CompositeTypeFields.Add(String(Item.Field));
			EndIf;

		EndDo;

		For Each Item In List.SettingsComposer.Settings.OrderAvailableFields.Items Do

			FieldTypes = Item.Type.Types();
			If FieldTypes.Count() > 1 Then
				CompositeTypeFields.Add(String(Item.Field));
			EndIf;

		EndDo;

		CompositeTypeFields = CommonClientServer.CollapseArray(CompositeTypeFields);

	EndIf;

EndProcedure

// The structure of the formation on the Form of a group of user settings of a dynamic list.
// 
// Returns:
//  Structure - The Structure Of The Formation Of A Group Of User Settings For A Dynamic List On The Form:
// * ListName - String - 
// * NameOfListItem - String - 
// * ListKeys - Map of String - 
// * ListOfCompositeFields - Array of String- 
// * PlacementGroupSettings - Undefined - 
// * AttributeNameAutoUpdateMode - String - 
// * NameOfListUpdateCommands - String - 
// * TimeLimitForUpdatingListOfDocuments - Number - 
Function StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm() Export

	ParametersStructure = New Structure;
	ParametersStructure.Insert("ListName", "");
	ParametersStructure.Insert("NameOfListItem", "");
	ParametersStructure.Insert("ListKeys", New Map);
	ParametersStructure.Insert("ListOfCompositeFields", New Array);

	ParametersStructure.Insert("PlacementGroupSettings", Undefined);
	ParametersStructure.Insert("AttributeNameAutoUpdateMode", "");
	ParametersStructure.Insert("NameOfListUpdateCommands", "");

	ParametersStructure.Insert("TimeLimitForUpdatingListOfDocuments", 2);

	Return ParametersStructure;

EndFunction

// Initiate dynamic list settings.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListSettingsParameters - Array of See OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm.
Procedure InitiateDynamicListSettings(Form, ListSettingsParameters) Export

	TimeLimitForUpdatingListOfDocuments = OperationsWithDocumentJournals.TimeLimitForUpdatingListOfDocuments();
	UseMechanismToChangeListSettings = Constants.UseToolForChangingDocumentListSettings.Get();

	KeysForSavedSettings = KeysForSavedSettingsProductiveListUpdateMode();
	SettingUpListAcceleration = Common.CommonSettingsStorageLoad(KeysForSavedSettings.ObjectKey,
		KeysForSavedSettings.SettingsKey);
	ProductiveUpdateMode = False;
	If TypeOf(SettingUpListAcceleration) = Type("Boolean") Then
		ProductiveUpdateMode = SettingUpListAcceleration;
	EndIf;

	AttributesToAddArray = New Array;

	SettingsDetails = New FormAttribute(NameOfDocumentListFormSettings(), New TypeDescription);
	SettingsDetails.Title = NStr("vi = 'Tùy chỉnh danh sách';
								|ru = 'Настройки списка';
								|en = 'List settings'; fa = 'تنظیمات فهرست';
								|it = 'Настройки списка';
								|pl = 'Ustawienia listy';
								|tr = 'Liste ayarları'");
	SettingsDetails.StoredData = False;
	AttributesToAddArray.Add(SettingsDetails);

	AttributesProductiveUpdateMode = New FormAttribute("DocumentListAccelerationModeIsEnabled",
		New TypeDescription("Boolean"));
	AttributesProductiveUpdateMode.Title = NStr("vi = 'Chế độ tùy ý';
												|ru = 'Производительный режим';
												|en = 'Productive mode'; fa = 'Productive mode';
												|it = 'Производительный режим';
												|pl = 'Productive mode';
												|tr = 'Performans modu'");
	AttributesProductiveUpdateMode.StoredData = False;
	AttributesToAddArray.Add(AttributesProductiveUpdateMode);

	Form.ChangeAttributes(AttributesToAddArray);

	Form[AttributesProductiveUpdateMode.Name] = ProductiveUpdateMode;

	SettingCompliance = New Structure;

	For Each ListSettingsParameter In ListSettingsParameters Do

		If ListSettingsParameter.ListKeys.Count() > 0 Then
			ListKeys = ListSettingsParameter.ListKeys;
		Else
			ListKeys = New Map;
			ListKeys.Insert("RefType", "RefType");
			ListKeys.Insert("BusinessOperation", "BusinessOperation");
			ListKeys.Insert("Date", "Date");
			ListKeys.Insert("RecordID", "RecordID");
		EndIf;

		ListOfCompositeFields = New Array;
		ListOfCompositeFields.Add("Ref");
		If ListSettingsParameter.ListOfCompositeFields.Count() > 0 Then
			ListOfCompositeFields = ListSettingsParameter.ListOfCompositeFields;
		EndIf;

		If ListSettingsParameter.NameOfListItem = "" Then
			ListSettingsParameter.NameOfListItem = ListSettingsParameter.ListName;
		EndIf;
		
		UseProductiveUpdateMode = UseMechanismToChangeListSettings
			And ProductiveUpdateMode;
		SetPropertiesOfDynamicListTableDocumentRegistry(Form[ListSettingsParameter.ListName],
			ListKeys, ListOfCompositeFields, UseProductiveUpdateMode);

		ListSettingsParameter.Insert("TimeLimitForUpdatingListOfDocuments",
			TimeLimitForUpdatingListOfDocuments);
		ListSettingsParameter.Insert("ListOfCompositeFields", ListOfCompositeFields);

		SettingsStructure = New Structure;
		SettingsStructure.Insert("Settings", New Structure);
		SettingsStructure.Insert("ElementsOfSettingsGroup", New Map);
		SettingsStructure.Insert("HasMainTable", Form[ListSettingsParameter.ListName].MainTable <> "");
		SettingsStructure.Insert("ListKeys", ListKeys);
		SettingsStructure.Insert("UseMechanismToChangeListSettings", UseMechanismToChangeListSettings);
		SettingsStructure.Insert("AttributesProductiveUpdateMode", AttributesProductiveUpdateMode.Name);

		CreateGroupOfDynamicListSettingsOnForm(Form, ListSettingsParameter, SettingsStructure);

		SettingCompliance.Insert(ListSettingsParameter.ListName, SettingsStructure);

	EndDo;

	Form[SettingsDetails.Name] = SettingCompliance;

EndProcedure

// A list of documents when uploading data from settings on the server.
// 
// Parameters:
//  Form - ClientApplicationForm
//  ListName - String - Name Of The Dynamic List
//  Settings - See OperationsWithDocumentJournals.StructureOfUserSettingsOfList
Procedure SetFlagForAutoUpdatingListOfDocumentsWhenUploadingDataFromSettings(Form, ListName, Settings) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;

	Form[ListSettings.AttributeNameAutoUpdateMode] = True;

	ListAutoUpdateMode = Settings.Get(ListSettings.AttributeNameAutoUpdateMode);

	If Not ListAutoUpdateMode = Undefined Then
		Form[ListSettings.AttributeNameAutoUpdateMode] = ListAutoUpdateMode;
	EndIf;

EndProcedure

// Getting the document list setting value.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
//  PropertyName - String - property name
// 
// Returns:
//  Arbitrary - The Value Of The Document List Settings
Function ValueOfDocumentListSettings(Form, ListName, PropertyName) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	PropertyValue = Undefined;

	ListSettings.Property(PropertyName, PropertyValue);

	Return PropertyValue;

EndFunction

// Returns an array of business operations of the transmitted document types
// that are reflected in the document registry and are not disabled by the FO.
//
// Parameters:
//  DocumentTypes - Array of Type - array of types.
// 
// Returns:
//  Array of EnumRef.BusinessTransactions - 
//
Function BusinessTransactionsReflectedInRegister(DocumentTypes) Export

	ArrayOfIdentifiers = New Array;
	ArrayOfBusinessOperations = New Array;

	For Each ArrRow In DocumentTypes Do
		If Common.IsReference(ArrRow) Then
			MetadataObject = Metadata.FindByType(ArrRow);
			If Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				ArrayOfIdentifiers.Add(Common.MetadataObjectID(MetadataObject));
			EndIf;
		EndIf;
	EndDo;

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	BusinessTransactionsSettingsDocuments.Ref.BusinessOperation AS BusinessOperation
	|FROM
	|	Catalog.BusinessTransactionsSettings.Documents AS BusinessTransactionsSettingsDocuments
	|WHERE
	|	BusinessTransactionsSettingsDocuments.MetadataObjectID IN (&ArrayOfIdentifiers)";

	Query.SetParameter("ArrayOfIdentifiers", ArrayOfIdentifiers);

	Selection = Query.Execute().Select();

	While Selection.Next() Do

		ArrayOfBusinessOperations.Add(Selection.BusinessOperation);

	EndDo;

	Return ArrayOfBusinessOperations;

EndFunction

// Keys for saved settings list acceleration mode.
// 
// Returns:
//  Structure - Keys for saved settings list acceleration mode:
// * ObjectKey - String - Key of the configuration object
// * SettingsKey - String - key of saved settings
Function KeysForSavedSettingsProductiveListUpdateMode() Export

	KeysStructure = New Structure;
	KeysStructure.Insert("ObjectKey", "OperationsWithDocumentJournals");
	KeysStructure.Insert("SettingsKey", "ProductiveModeOfUpdatingListOfDocuments");

	Return KeysStructure;

EndFunction

// Checking the user settings of the dynamic list and identifying those that may lead to a decrease
// in the speed of working with it.
// 
// Parameters:
//  DataCompositionSettings - DataCompositionSettings
//  ListOfCompositeTypeFields - Array of String
// 
// Returns:
//  Structure - Verified Dynamic list settings:
// * ThereAreProblemsInSettings - Boolean - Indicates that there are problems in the user settings
// * ThereAreProblemsInSelectionSettingsCritical - Boolean - A sign of the presence of "critical" problems in user settings 
// * ThereAreProblemsInSelectionSettings - Boolean - A sign of the presence of "normal" problems in user settings
// * FilterRegular - Array of String - List of problematic list fields with the importance level "Normal"
// * FilterCriticalOnes - Array of String - List of problem fields in the list with the importance level "Critical"
// * FilterRegularPresentation - Array of String - Presentation of problematic list fields with the importance level "Ordinary"
// * FilterCriticalOnesPresentation - Array of String - Presentation of problem fields of the list with the importance level "Critical"
// * ThereAreProblemsInSettingsOfOrderCritical - Boolean - The presence of problems in the settings with the "Critical" importance level
// * ThereAreProblemsInOrderSettings - Boolean - The presence of problems in the settings with the "Normal" importance level
// * OrderIsNormal - Array of String- List of problematic list fields with the importance level "Normal"
// * OrderIsCritical - Array of String - List of problem fields in the list with the importance level "Critical"
// * OrderIsNormalPresentation - Array of String - Presentation of problematic list fields with the importance level "Ordinary"
// * OrderIsCriticalPresentation - Array of String - Presentation of problem fields of the list with the importance level "Critical"
// * ThereAreProblemsInDesignSettingsCritical - Boolean - The presence of problems in the settings with the "Critical" importance level
// * ThereAreProblemsInDesignSettings - Boolean - The presence of problems in the settings with the "Normal" importance level
// * ConditionalAppearanceOrdinary - Array of String - List of problematic list fields with the importance level "Normal"
// * ConditionalAppearanceCritical - Array of String - List of problem fields in the list with the importance level "Critical"
// * ConditionalAppearanceOrdinaryPresentation - Array of String - Presentation of problematic list fields with the importance level "Ordinary"
// * ConditionalAppearanceCriticalPresentation - Array of String - Presentation of problem fields of the list with the importance level "Critical"
// * ThereAreProblemsInSelectedFieldsCritical - Boolean - The presence of problems in the settings with the "Critical" importance level
// * ThereAreProblemsInSelectedFields - Boolean - The presence of problems in the settings with the "Normal" importance level
// * SelectedFieldsAreNormal - Array of String - List of problematic list fields with the importance level "Normal"
// * SelectedFieldsAreCritical - Array of String - List of problem fields in the list with the importance level "Critical"
// * SelectedFieldsAreNormalPresentation - Array of String - Presentation of problematic list fields with the importance level "Ordinary"
// * SelectedFieldsAreCriticalPresentation - Array of String - Presentation of problem fields of the list with the importance level "Critical"
Function CheckUserSettingsOfDynamicList(DataCompositionSettings, ListOfCompositeTypeFields) Export
	
	ListOfCriticalSelectionFields = New Array;
	ListOfFieldsOrderCritical = New Array;
	ListOfFieldsConditionalAppearanceCritical = New Array;
	ListOfFieldsSelectedFieldsCritical = New Array;

	ListOfFieldsFilters = New Array;
	ListOfFieldsOrder = New Array;
	ListOfConditionalAppearanceFields = New Array;
	ListOfFieldsSelectedFields = New Array;

	ThereAreProblemsInUserSettings = False;

	CheckElementsOfDynamicListSelectionSettings(DataCompositionSettings.Filter, ListOfFieldsFilters);
	CheckItemsOfDynamicListOrderSettings(DataCompositionSettings.Order, ListOfFieldsOrder, ListOfCompositeTypeFields);
	CheckElementsOfSelectedFieldsOfDynamicList(DataCompositionSettings.Structure, ListOfFieldsSelectedFields);
	CheckElementsOfConditionalAppearanceSettingsOfDynamicList(DataCompositionSettings.Structure,
		ListOfConditionalAppearanceFields);

	If ListOfFieldsFilters.Count() > 0 Or ListOfFieldsOrder.Count() > 0
		Or ListOfConditionalAppearanceFields.Count() > 0 Or ListOfFieldsSelectedFields.Count() > 0 Then

		ThereAreProblemsInUserSettings = True;

	EndIf;
	
	// Critical user settings for a dynamic list are accessing the Attributes of composite type objects
	For Each CompositeAttributes In ListOfCompositeTypeFields Do

		For Each CurrentItem In ListOfFieldsFilters Do

			If Not StrFind(CurrentItem, CompositeAttributes + ".") = 0 Then
				ListOfCriticalSelectionFields.Add(CurrentItem);
			EndIf;

		EndDo;

		For Each CurrentItem In ListOfFieldsOrder Do

			If Not StrFind(CurrentItem, CompositeAttributes + ".") = 0 Or CurrentItem = CompositeAttributes Then
				ListOfFieldsOrderCritical.Add(CurrentItem);
			EndIf;

		EndDo;

		For Each CurrentItem In ListOfConditionalAppearanceFields Do

			If Not StrFind(CurrentItem, CompositeAttributes + ".") = 0 Then
				ListOfFieldsConditionalAppearanceCritical.Add(CurrentItem);
			EndIf;

		EndDo;

		For Each CurrentItem In ListOfFieldsSelectedFields Do

			If Not StrFind(CurrentItem, CompositeAttributes + ".") = 0 Then
				ListOfFieldsSelectedFieldsCritical.Add(CurrentItem);
			EndIf;

		EndDo;

	EndDo;
	
	// Critical user settings of the dynamic list - access through "multiple points"
	For Each CurrentItem In ListOfFieldsFilters Do
		If StrOccurrenceCount(CurrentItem, ".") > 1
			And ListOfCriticalSelectionFields.Find(CurrentItem) = Undefined Then
			ListOfCriticalSelectionFields.Add(CurrentItem);
		EndIf;
	EndDo;

	For Each CurrentItem In ListOfFieldsOrder Do
		If StrOccurrenceCount(CurrentItem, ".") > 1
			And ListOfFieldsOrderCritical.Find(CurrentItem) = Undefined Then
			ListOfFieldsOrderCritical.Add(CurrentItem);
		EndIf;
	EndDo;

	For Each CurrentItem In ListOfConditionalAppearanceFields Do
		If StrOccurrenceCount(CurrentItem, ".") > 1
			And ListOfFieldsConditionalAppearanceCritical.Find(CurrentItem) = Undefined Then
			ListOfFieldsConditionalAppearanceCritical.Add(CurrentItem);
		EndIf;
	EndDo;

	For Each CurrentItem In ListOfFieldsSelectedFields Do
		If StrOccurrenceCount(CurrentItem, ".") > 1
			And ListOfFieldsSelectedFieldsCritical.Find(CurrentItem) = Undefined Then
			ListOfFieldsSelectedFieldsCritical.Add(CurrentItem);
		EndIf;
	EndDo;

	ListOfFieldsFilters = CommonClientServer.ArraysDifference(ListOfFieldsFilters, ListOfCriticalSelectionFields);
	ListOfFieldsOrder = CommonClientServer.ArraysDifference(ListOfFieldsOrder, ListOfFieldsOrderCritical);
	ListOfConditionalAppearanceFields = CommonClientServer.ArraysDifference(ListOfConditionalAppearanceFields,
		ListOfFieldsConditionalAppearanceCritical);
	ListOfFieldsSelectedFields = CommonClientServer.ArraysDifference(ListOfFieldsSelectedFields,
		ListOfFieldsSelectedFieldsCritical);
		
	CheckingUserSettingsStructure = New Structure;
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInSettings", ThereAreProblemsInUserSettings);
	
	ListOfCriticalSelectionFields = CommonClientServer.CollapseArray(ListOfCriticalSelectionFields);
	ListOfFieldsFilters = CommonClientServer.CollapseArray(ListOfFieldsFilters);
	
	ListOfCriticalSelectionFieldsPresentation = New Array;
	For Each CurrentItem In ListOfCriticalSelectionFields Do
		ListOfCriticalSelectionFieldsPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.FilterAvailableFields));
	EndDo;
	
	ListOfFieldsFiltersPresentation = New Array;
	For Each CurrentItem In ListOfFieldsFilters Do
		ListOfFieldsFiltersPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.FilterAvailableFields));
	EndDo;
	
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInSelectionSettingsCritical", ListOfCriticalSelectionFields.Count() > 0);
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInSelectionSettings", ListOfFieldsFilters.Count() > 0);
	CheckingUserSettingsStructure.Insert("FilterRegular", ListOfFieldsFilters);
	CheckingUserSettingsStructure.Insert("FilterCriticalOnes", ListOfCriticalSelectionFields);
	CheckingUserSettingsStructure.Insert("FilterRegularPresentation", ListOfFieldsFiltersPresentation);
	CheckingUserSettingsStructure.Insert("FilterCriticalOnesPresentation", ListOfCriticalSelectionFieldsPresentation);
	
	ListOfFieldsOrderCritical = CommonClientServer.CollapseArray(ListOfFieldsOrderCritical);
	ListOfFieldsOrder = CommonClientServer.CollapseArray(ListOfFieldsOrder);
	
	ListOfFieldsOrderCriticalPresentation = New Array;
	For Each CurrentItem In ListOfFieldsOrderCritical Do
		ListOfFieldsOrderCriticalPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.OrderAvailableFields));
	EndDo;
	
	ListOfFieldsOrderPresentation = New Array;
	For Each CurrentItem In ListOfFieldsOrder Do
		ListOfFieldsOrderPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.OrderAvailableFields));
	EndDo;
	
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInSettingsOfOrderCritical", ListOfFieldsOrderCritical.Count() > 0);
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInOrderSettings", ListOfFieldsOrder.Count() > 0);
	CheckingUserSettingsStructure.Insert("OrderIsNormal", ListOfFieldsOrder);
	CheckingUserSettingsStructure.Insert("OrderIsCritical", ListOfFieldsOrderCritical);
	CheckingUserSettingsStructure.Insert("OrderIsNormalPresentation", ListOfFieldsOrderPresentation);
	CheckingUserSettingsStructure.Insert("OrderIsCriticalPresentation", ListOfFieldsOrderCriticalPresentation);
	
	ListOfFieldsConditionalAppearanceCritical = CommonClientServer.CollapseArray(ListOfFieldsConditionalAppearanceCritical);
	ListOfConditionalAppearanceFields = CommonClientServer.CollapseArray(ListOfConditionalAppearanceFields);
	
	ListOfFieldsConditionalAppearanceCriticalPresentation = New Array;
	For Each CurrentItem In ListOfFieldsConditionalAppearanceCritical Do
		ListOfFieldsConditionalAppearanceCriticalPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.FilterAvailableFields));
	EndDo;
	
	ListOfConditionalAppearanceFieldsPresentation = New Array;
	For Each CurrentItem In ListOfConditionalAppearanceFields Do
		ListOfConditionalAppearanceFieldsPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.FilterAvailableFields));
	EndDo;
	
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInDesignSettingsCritical", ListOfFieldsConditionalAppearanceCritical.Count() > 0);
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInDesignSettings", ListOfConditionalAppearanceFields.Count() > 0);
	CheckingUserSettingsStructure.Insert("ConditionalAppearanceOrdinary", ListOfConditionalAppearanceFields);
	CheckingUserSettingsStructure.Insert("ConditionalAppearanceCritical", ListOfFieldsConditionalAppearanceCritical);
	CheckingUserSettingsStructure.Insert("ConditionalAppearanceOrdinaryPresentation", ListOfConditionalAppearanceFieldsPresentation);
	CheckingUserSettingsStructure.Insert("ConditionalAppearanceCriticalPresentation", ListOfFieldsConditionalAppearanceCriticalPresentation);
	
	ListOfFieldsSelectedFieldsCritical = CommonClientServer.CollapseArray(ListOfFieldsSelectedFieldsCritical);
	ListOfFieldsSelectedFields = CommonClientServer.CollapseArray(ListOfFieldsSelectedFields);
	
	ListOfFieldsSelectedFieldsCriticalPresentation = New Array;
	For Each CurrentItem In ListOfFieldsSelectedFieldsCritical Do
		ListOfFieldsSelectedFieldsCriticalPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.SelectionAvailableFields));
	EndDo;
	
	ListOfFieldsSelectedFieldsPresentation = New Array;
	For Each CurrentItem In ListOfFieldsSelectedFields Do
		ListOfFieldsSelectedFieldsPresentation.Add(TitleOfAvailableListField(CurrentItem, DataCompositionSettings.SelectionAvailableFields));
	EndDo;
	
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInSelectedFieldsCritical", ListOfFieldsSelectedFieldsCritical.Count() > 0);
	CheckingUserSettingsStructure.Insert("ThereAreProblemsInSelectedFields", ListOfFieldsSelectedFields.Count() > 0);
	CheckingUserSettingsStructure.Insert("SelectedFieldsAreNormal", ListOfFieldsSelectedFields);
	CheckingUserSettingsStructure.Insert("SelectedFieldsAreCritical", ListOfFieldsSelectedFieldsCritical);
	CheckingUserSettingsStructure.Insert("SelectedFieldsAreNormalPresentation", ListOfFieldsSelectedFieldsPresentation);
	CheckingUserSettingsStructure.Insert("SelectedFieldsAreCriticalPresentation", ListOfFieldsSelectedFieldsCriticalPresentation);
	
	Return CheckingUserSettingsStructure;
	
EndFunction

// Displays the main group of list update settings.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure SetVisibilityOfDefaultUpdateSettingsGroup(Form, ListName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	
	If Not Form[ListSettings.AttributeNameAutoUpdateMode] Then
		
		GroupVisibilityNoProblems = CommonClientServer.FormItemPropertyValue(Form.Items,
			ListSettings.GroupNoProblems, "Visible");
			
		If GroupVisibilityNoProblems Then
			Return;
		EndIf;
		
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListSettings.GroupDescriptionOfProblems, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListSettings.GroupNoProblems, "Visible", True);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListSettings.GroupIrrelevantData, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items, ListSettings.TheRefreshButton,
			"Visible", False);
		
	EndIf;

EndProcedure

// Checks whether the dynamic list has a main table.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
// 
// Returns:
//  Boolean - There Is A Main Table Of The List
Function ThereIsMainTableOfList(Form, ListName) Export
	
	ThereIsMainTableOfList = True;
	If ValueIsFilled(ListName) Then
		ThereIsMainTableOfList = ValueIsFilled(Form[ListName].MainTable);
	EndIf;
	
	Return ThereIsMainTableOfList;
	
EndFunction
#EndRegion

#Region Private

// Creating a group of dynamic list settings on the Form.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Parameters - See OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm
//  SettingsStructure - Structure
Procedure CreateGroupOfDynamicListSettingsOnForm(Form, Parameters, SettingsStructure)

	ListName = Parameters.ListName;
	
	Action = "ListOfDocumentsFormElementEventHandling";
	
	FontOfPopUpGroupTitle = StyleFonts.FontOfPopUpGroupTitle;
	GroupHeadingFont = StyleFonts.GroupHeadingFont;
	WebColorsGreen = WebColors.Green;
	WebColorsDarkOrange = WebColors.DarkOrange;
	ResultIssueColor = StyleColors.ResultIssueColor;
	HyperlinkColor = StyleColors.HyperlinkColor;
	WebColorsAreDullGray = WebColors.DimGray;
	
	MatchingCreatedElements = New Map;

	GroupDescriptionOfProblems = Form.Items.Insert(ListName + "GroupDescriptionOfProblems", Type("FormGroup"),
		Parameters.PlacementGroupSettings); //FormGroupExtensionForAUsualGroup
	GroupDescriptionOfProblems.Type = FormGroupType.UsualGroup;
	GroupDescriptionOfProblems.TitleFont = FontOfPopUpGroupTitle;
	GroupDescriptionOfProblems.Group = ChildFormItemsGroup.AlwaysHorizontal;
	GroupDescriptionOfProblems.Representation = UsualGroupRepresentation.WeakSeparation;
	GroupDescriptionOfProblems.Behavior = UsualGroupBehavior.PopUp;
	GroupDescriptionOfProblems.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	GroupDescriptionOfProblems.VerticalAlignInGroup = ItemVerticalAlign.Center;
	GroupDescriptionOfProblems.Title = NStr("vi = 'Tại sao việc cập nhật danh sách mất nhiều thời gian?';
											|ru = 'Почему список обновляется долго?';
											|en = 'Why does it take so long to update the list?'; fa = 'Why does it take so long to update the list?';
											|it = 'Почему список обновляется долго?';
											|pl = 'Why does it take so long to update the list?';
											|tr = 'Listenin güncellenmesi neden uzun sürüyor?'");
	GroupDescriptionOfProblems.TitleTextColor = WebColorsDarkOrange;
	GroupDescriptionOfProblems.Visible = True;
	
	#Region SettingsGroupDescriptionOfProblems
	SettingsGroupDescriptionOfProblems = Form.Items.Insert(ListName + "SettingsGroupDescriptionOfProblems", Type("FormGroup"),
		GroupDescriptionOfProblems); //FormGroupExtensionForAUsualGroup
	SettingsGroupDescriptionOfProblems.Type = FormGroupType.UsualGroup;
	SettingsGroupDescriptionOfProblems.Title = NStr("vi = 'Tùy chỉnh';
													|ru = 'Настройки';
													|en = 'Settings'; fa = 'تنظیمات';
													|it = 'Настройки';
													|pl = 'Settings';
													|tr = 'Ayarlar'");
	SettingsGroupDescriptionOfProblems.ShowTitle = False;
	SettingsGroupDescriptionOfProblems.Representation = UsualGroupRepresentation.None;
	SettingsGroupDescriptionOfProblems.Group = ChildFormItemsGroup.Vertical;

	GroupCreationParameters = New Structure;
	GroupCreationParameters.Insert("SettingsPrefix", "DescriptionOfProblems");
	GroupCreationParameters.Insert("ParentGroup1", SettingsGroupDescriptionOfProblems);
	GroupCreationParameters.Insert("AttributeNameAutoUpdateMode", Parameters.AttributeNameAutoUpdateMode);
	GroupCreationParameters.Insert("SettingsStructure", SettingsStructure);
	GroupCreationParameters.Insert("DisplayTitleListUpdate", True);
	GroupCreationParameters.Insert("WebColorsAreDullGray", WebColorsAreDullGray);
	GroupCreationParameters.Insert("GroupHeadingFont", GroupHeadingFont);
	CreateGroupOfAutoUpdateAndProductiveModeSettings(Form, ListName, GroupCreationParameters, MatchingCreatedElements);
	
	GroupDocumentsProblematicSettings = Form.Items.Insert(ListName + "DocumentsProblematicSettings", Type(
		"FormGroup"), SettingsGroupDescriptionOfProblems); //FormGroupExtensionForAUsualGroup
	GroupDocumentsProblematicSettings.Type = FormGroupType.UsualGroup;
	GroupDocumentsProblematicSettings.Title = NStr("vi = 'Tùy chỉnh tự tạo';
													|ru = 'Пользователькие настройки';
													|en = 'Custom settings'; fa = 'Custom settings';
													|it = 'Пользователькие настройки';
													|pl = 'Custom settings';
													|tr = 'Kullanıcı ayarları'");
	GroupDocumentsProblematicSettings.ShowTitle = False;
	GroupDocumentsProblematicSettings.Representation = UsualGroupRepresentation.None;
	GroupDocumentsProblematicSettings.Group = ChildFormItemsGroup.Vertical;

	TitleOfListIssue = Form.Items.Insert(ListName + "DocumentsTitleOfProblemList", Type(
		"FormDecoration"), GroupDocumentsProblematicSettings);
	TitleOfListIssue.Type = FormDecorationType.Label;
	TitleOfListIssue.Title = NStr(
		"vi = 'Tùy chỉnh tự tạo làm chậm công việc với danh sách chứng từ';
		|ru = 'Пользовательские настройки, замедляющие работу со списком документов';
		|en = 'Custom settings that slow down operations with the document list'; fa = 'Custom settings that slow down operations with the document list';
		|it = 'Пользовательские настройки, замедляющие работу со списком документов';
		|pl = 'Custom settings that slow down operations with the document list';
		|tr = 'Belge listesi işlemlerini yavaşlatan özel ayarlar'");
	TitleOfListIssue.Font = GroupHeadingFont;
	
	// Selected field
	GroupDocumentsSelectedFields = Form.Items.Insert(ListName + "DocumentsSelectedFields", Type("FormGroup"),
		GroupDocumentsProblematicSettings); //FormGroupExtensionForAUsualGroup
	GroupDocumentsSelectedFields.Type = FormGroupType.UsualGroup;
	GroupDocumentsSelectedFields.Title = NStr("vi = 'Trường được chọn';
												|ru = 'Выбранные поля';
												|en = 'Selected fields'; fa = 'فیلدهای انتخاب‌شده';
												|it = 'Выбранные поля';
												|pl = 'Wybrane pola';
												|tr = 'Seçilen alanlar'");
	GroupDocumentsSelectedFields.ShowTitle = False;
	GroupDocumentsSelectedFields.Representation = UsualGroupRepresentation.None;
	GroupDocumentsSelectedFields.Group = ChildFormItemsGroup.Vertical;
	
	DocumentsTitleSelectedFields = Form.Items.Insert(ListName + "DocumentsTitleSelectedFields", Type(
		"FormDecoration"), GroupDocumentsSelectedFields);
	DocumentsTitleSelectedFields.Type = FormDecorationType.Label;
	DocumentsTitleSelectedFields.Title = NStr("vi = 'Trường danh sách:';
												|ru = 'Поля списка:';
												|en = 'List fields:'; fa = 'List fields:';
												|it = 'Поля списка:';
												|pl = 'List fields:';
												|tr = 'Liste alanları:'");
	DocumentsTitleSelectedFields.Font = GroupHeadingFont;
	DocumentsTitleSelectedFields.TextColor = WebColorsGreen;

	DocumentsSelectedFieldsAreCritical = Form.Items.Insert(ListName + "DocumentsSelectedFieldsAreCritical", Type(
		"FormDecoration"), GroupDocumentsSelectedFields);
	DocumentsSelectedFieldsAreCritical.Type = FormDecorationType.Label;
	DocumentsSelectedFieldsAreCritical.Title = NStr("vi = 'Trường được chọn';
													|ru = 'Выбранные поля';
													|en = 'Selected fields'; fa = 'فیلدهای انتخاب‌شده';
													|it = 'Выбранные поля';
													|pl = 'Wybrane pola';
													|tr = 'Seçilen alanlar'");
	DocumentsSelectedFieldsAreCritical.TextColor = ResultIssueColor;

	DocumentsSelectedFieldsAreNormal = Form.Items.Insert(ListName + "DocumentsSelectedFieldsAreNormal", Type(
		"FormDecoration"), GroupDocumentsSelectedFields);
	DocumentsSelectedFieldsAreNormal.Type = FormDecorationType.Label;
	DocumentsSelectedFieldsAreNormal.Title = NStr("vi = 'Trường được chọn';
													|ru = 'Выбранные поля';
													|en = 'Selected fields'; fa = 'فیلدهای انتخاب‌شده';
													|it = 'Выбранные поля';
													|pl = 'Wybrane pola';
													|tr = 'Seçilen alanlar'");

	DocumentsSelectedFieldsCorrect = Form.Items.Insert(ListName + "DocumentsSelectedFieldsCorrect", Type(
		"FormButton"), GroupDocumentsSelectedFields);
	DocumentsSelectedFieldsCorrect.Type = FormButtonType.Hyperlink;
	DocumentsSelectedFieldsCorrect.Title = "Settings";

	MatchingCreatedElements.Insert(DocumentsSelectedFieldsCorrect.Name, "SelectedFields");
	
	// List Selections
	GroupDocumentsListSelections = Form.Items.Insert(ListName + "ListSelectionDocuments", Type("FormGroup"),
		GroupDocumentsProblematicSettings); //FormGroupExtensionForAUsualGroup
	GroupDocumentsListSelections.Type = FormGroupType.UsualGroup;
	GroupDocumentsListSelections.Title = NStr("vi = 'Danh sách lựa chọn';
												|ru = 'Отборы списка';
												|en = 'List filters'; fa = 'فیلترهای فهرست';
												|it = 'Отборы списка';
												|pl = 'Filtr listy';
												|tr = 'Liste filtreleme'");
	GroupDocumentsListSelections.ShowTitle = False;
	GroupDocumentsListSelections.Representation = UsualGroupRepresentation.None;
	GroupDocumentsListSelections.Group = ChildFormItemsGroup.Vertical;
	
	DocumentsTitleSelection = Form.Items.Insert(ListName + "DocumentsTitleSelection", Type("FormDecoration"),
		GroupDocumentsListSelections);
	DocumentsTitleSelection.Type = FormDecorationType.Label;
	DocumentsTitleSelection.Title = NStr("vi = 'Danh sách lựa chọn:';
										|ru = 'Отборы списка:';
										|en = 'List filters'; fa = 'فیلترهای فهرست';
										|it = 'Отборы списка:';
										|pl = 'List filters';
										|tr = 'Liste filtreleme:'");
	DocumentsTitleSelection.Font = GroupHeadingFont;
	DocumentsTitleSelection.TextColor = WebColorsGreen;

	DocumentsSelectionCritical = Form.Items.Insert(ListName + "DocumentsSelectionCritical", Type("FormDecoration"),
		GroupDocumentsListSelections);
	DocumentsSelectionCritical.Type = FormDecorationType.Label;
	DocumentsSelectionCritical.Title = NStr("vi = 'Lọc';
											|ru = 'Отборы';
											|en = 'Filters'; fa = 'فیلترها';
											|it = 'Отборы';
											|pl = 'Filtry';
											|tr = 'Filtreler'");
	DocumentsSelectionCritical.TextColor = ResultIssueColor;

	SelectionDocumentsAreOrdinary = Form.Items.Insert(ListName + "SelectionDocumentsAreOrdinary", Type("FormDecoration"),
		GroupDocumentsListSelections);
	SelectionDocumentsAreOrdinary.Type = FormDecorationType.Label;
	SelectionDocumentsAreOrdinary.Title = NStr("vi = 'Lọc';
												|ru = 'Отборы';
												|en = 'Filters'; fa = 'فیلترها';
												|it = 'Отборы';
												|pl = 'Filtry';
												|tr = 'Filtreler'");

	DocumentSelectionsCorrect = Form.Items.Insert(ListName + "DocumentSelectionsCorrect", Type("FormDecoration"),
		GroupDocumentsListSelections); //FormDecorationExtensionForALabel
	DocumentSelectionsCorrect.Type = FormDecorationType.Label;
	DocumentSelectionsCorrect.Title = NStr("vi = 'Sửa lỗi';
											|ru = 'Исправить';
											|en = 'Correct'; fa = 'اصلاح';
											|it = 'Исправить';
											|pl = 'Correct';
											|tr = 'Düzelt'");
	DocumentSelectionsCorrect.SetAction("Click", Action);
	DocumentSelectionsCorrect.Hyperlink = True;
	DocumentSelectionsCorrect.TextColor = HyperlinkColor;
	MatchingCreatedElements.Insert(DocumentSelectionsCorrect.Name, "Filters");
	
	// Order
	GroupDocumentsListOrder = Form.Items.Insert(ListName + "DocumentsListOrder", Type("FormGroup"),
		GroupDocumentsProblematicSettings); //FormGroupExtensionForAUsualGroup
	GroupDocumentsListOrder.Type = FormGroupType.UsualGroup;
	GroupDocumentsListOrder.Title = NStr("vi = 'Trình tự thao tác';
										|ru = 'Порядок списка';
										|en = 'List order'; fa = 'List order';
										|it = 'Порядок списка';
										|pl = 'List order';
										|tr = 'Listenin sırası'");
	GroupDocumentsListOrder.ShowTitle = False;
	GroupDocumentsListOrder.Representation = UsualGroupRepresentation.None;
	GroupDocumentsListOrder.Group = ChildFormItemsGroup.Vertical;

	DocumentsTitleOrder = Form.Items.Insert(ListName + "DocumentsTitleOrder", Type("FormDecoration"),
		GroupDocumentsListOrder);
	DocumentsTitleOrder.Type = FormDecorationType.Label;
	DocumentsTitleOrder.Title = NStr("vi = 'Trường sắp xếp danh sách:';
									|ru = 'Поля сортировки списка:';
									|en = 'List sort fields:'; fa = 'List sort fields:';
									|it = 'Поля сортировки списка:';
									|pl = 'List sort fields:';
									|tr = 'Sıralama alanlarını listeleyin:'");
	DocumentsTitleOrder.Font = GroupHeadingFont;
	DocumentsTitleOrder.TextColor = WebColorsGreen;

	DocumentsAreOrderCritical = Form.Items.Insert(ListName + "DocumentsAreOrderCritical", Type("FormDecoration"),
		GroupDocumentsListOrder);
	DocumentsAreOrderCritical.Type = FormDecorationType.Label;
	DocumentsAreOrderCritical.Title = NStr("vi = 'Trình tự';
											|ru = 'Порядок';
											|en = 'Order'; fa = 'سفارش';
											|it = 'Порядок';
											|pl = 'Order';
											|tr = 'Sıra'");
	DocumentsAreOrderCritical.TextColor = ResultIssueColor;

	DocumentsAreInUsualOrder = Form.Items.Insert(ListName + "DocumentsAreInUsualOrder", Type("FormDecoration"),
		GroupDocumentsListOrder);
	DocumentsAreInUsualOrder.Type = FormDecorationType.Label;
	DocumentsAreInUsualOrder.Title = NStr("vi = 'Trình tự';
											|ru = 'Порядок';
											|en = 'Order'; fa = 'سفارش';
											|it = 'Порядок';
											|pl = 'Order';
											|tr = 'Sıra'");

	DocumentsOrderToFix = Form.Items.Insert(ListName + "DocumentsOrderToFix", Type("FormDecoration"),
		GroupDocumentsListOrder); //FormDecorationExtensionForALabel
	DocumentsOrderToFix.Type = FormDecorationType.Label;
	DocumentsOrderToFix.Title = NStr("vi = 'Sửa lỗi';
									|ru = 'Исправить';
									|en = 'Correct'; fa = 'اصلاح';
									|it = 'Исправить';
									|pl = 'Correct';
									|tr = 'Düzelt'");
	DocumentsOrderToFix.SetAction("Click", Action);
	DocumentsOrderToFix.Hyperlink = True;
	DocumentsOrderToFix.TextColor = HyperlinkColor;
	MatchingCreatedElements.Insert(DocumentsOrderToFix.Name, "Order");
	
	// conditional design
	GroupDocumentsConditionalAppearanceOfList = Form.Items.Insert(ListName + "DocumentsConditionalAppearanceOfList",
		Type("FormGroup"), GroupDocumentsProblematicSettings); //FormGroupExtensionForAUsualGroup
	GroupDocumentsConditionalAppearanceOfList.Type = FormGroupType.UsualGroup;
	GroupDocumentsConditionalAppearanceOfList.Title = NStr("vi = 'Trang trí quy ước danh sách';
															|ru = 'Условное оформление списка';
															|en = 'Conditional list appearance'; fa = 'Conditional list appearance';
															|it = 'Условное оформление списка';
															|pl = 'Conditional list appearance';
															|tr = 'Koşullu liste tasarımı'");
	GroupDocumentsConditionalAppearanceOfList.ShowTitle = False;
	GroupDocumentsConditionalAppearanceOfList.Representation = UsualGroupRepresentation.None;
	GroupDocumentsConditionalAppearanceOfList.Group = ChildFormItemsGroup.Vertical;
	
	DocumentsTitleConditionalAppearance = Form.Items.Insert(ListName + "DocumentsTitleConditionalAppearance",
		Type("FormDecoration"), GroupDocumentsConditionalAppearanceOfList);
	DocumentsTitleConditionalAppearance.Type = FormDecorationType.Label;
	DocumentsTitleConditionalAppearance.Title = NStr("vi = 'Trang trí quy ước danh sách';
													|ru = 'Условное оформление списка:';
													|en = 'Conditional list appearance:'; fa = 'Conditional list appearance:';
													|it = 'Условное оформление списка:';
													|pl = 'Conditional list appearance:';
													|tr = 'Koşullu liste tasarımı:'");
	DocumentsTitleConditionalAppearance.Font = GroupHeadingFont;
	DocumentsTitleConditionalAppearance.TextColor = WebColorsGreen;

	DocumentsConditionalAppearanceCritical = Form.Items.Insert(ListName + "DocumentsConditionalAppearanceCritical",
		Type("FormDecoration"), GroupDocumentsConditionalAppearanceOfList);
	DocumentsConditionalAppearanceCritical.Type = FormDecorationType.Label;
	DocumentsConditionalAppearanceCritical.Title = NStr("vi = 'Lập';
														|ru = 'Оформление';
														|en = 'Appearance'; fa = 'ظاهر';
														|it = 'Оформление';
														|pl = 'Appearance';
														|tr = 'Düzenleme'");
	DocumentsConditionalAppearanceCritical.TextColor = ResultIssueColor;

	DocumentsConditionalAppearanceOrdinary = Form.Items.Insert(ListName + "DocumentsConditionalAppearanceOrdinary", Type(
		"FormDecoration"), GroupDocumentsConditionalAppearanceOfList);
	DocumentsConditionalAppearanceOrdinary.Type = FormDecorationType.Label;
	DocumentsConditionalAppearanceOrdinary.Title = NStr("vi = 'Lập';
														|ru = 'Оформление';
														|en = 'Appearance'; fa = 'ظاهر';
														|it = 'Оформление';
														|pl = 'Appearance';
														|tr = 'Düzenleme'");

	DocumentsConditionalAppearanceCorrect = Form.Items.Insert(ListName + "DocumentsConditionalAppearanceCorrect",
		Type("FormDecoration"), GroupDocumentsConditionalAppearanceOfList); //FormDecorationExtensionForALabel
	DocumentsConditionalAppearanceCorrect.Type = FormDecorationType.Label;
	DocumentsConditionalAppearanceCorrect.Title = NStr("vi = 'Sửa lỗi';
														|ru = 'Исправить';
														|en = 'Correct'; fa = 'اصلاح';
														|it = 'Исправить';
														|pl = 'Correct';
														|tr = 'Düzelt'");
	DocumentsConditionalAppearanceCorrect.SetAction("Click", Action);
	DocumentsConditionalAppearanceCorrect.Hyperlink = True;
	DocumentsConditionalAppearanceCorrect.TextColor = HyperlinkColor;
	MatchingCreatedElements.Insert(DocumentsConditionalAppearanceCorrect.Name, "ConditionalAppearance");
	
	#EndRegion
	
	#Region GroupNoProblems
	GroupNoProblems = Form.Items.Insert(ListName + "GroupNoProblems", Type("FormGroup"),
		Parameters.PlacementGroupSettings); //FormGroupExtensionForAUsualGroup
	GroupNoProblems.Type = FormGroupType.UsualGroup;
	GroupNoProblems.TitleFont = FontOfPopUpGroupTitle;
	GroupNoProblems.Group = ChildFormItemsGroup.AlwaysHorizontal;
	GroupNoProblems.Representation = UsualGroupRepresentation.WeakSeparation;
	GroupNoProblems.Behavior = UsualGroupBehavior.PopUp;
	GroupNoProblems.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	GroupNoProblems.VerticalAlignInGroup = ItemVerticalAlign.Center;
	GroupNoProblems.Title = NStr("vi = 'Tùy chỉnh cập nhật';
								|ru = 'Настройки обновления';
								|en = 'Update settings'; fa = 'Update settings';
								|it = 'Настройки обновления';
								|pl = 'Update settings';
								|tr = 'Güncelleme ayarları'");
	GroupNoProblems.TitleTextColor = HyperlinkColor;
	GroupNoProblems.Visible = True;
	
	SettingsGroupNoProblems = Form.Items.Insert(ListName + "SettingsGroupNoProblems", Type("FormGroup"),
		GroupNoProblems); //FormGroupExtensionForAUsualGroup
	SettingsGroupNoProblems.Type = FormGroupType.UsualGroup;
	SettingsGroupNoProblems.Title = NStr("vi = 'Tùy chỉnh';
										|ru = 'Настройки';
										|en = 'Settings'; fa = 'تنظیمات';
										|it = 'Настройки';
										|pl = 'Settings';
										|tr = 'Ayarlar'");
	SettingsGroupNoProblems.ShowTitle = False;
	SettingsGroupNoProblems.Representation = UsualGroupRepresentation.None;
	SettingsGroupNoProblems.Group = ChildFormItemsGroup.Vertical;
	
	GroupCreationParameters = New Structure;
	GroupCreationParameters.Insert("SettingsPrefix", "NoProblems");
	GroupCreationParameters.Insert("ParentGroup1", SettingsGroupNoProblems);
	GroupCreationParameters.Insert("AttributeNameAutoUpdateMode", Parameters.AttributeNameAutoUpdateMode);
	GroupCreationParameters.Insert("SettingsStructure", SettingsStructure);
	GroupCreationParameters.Insert("DisplayTitleListUpdate", False);
	GroupCreationParameters.Insert("WebColorsAreDullGray", WebColorsAreDullGray);
	GroupCreationParameters.Insert("GroupHeadingFont", GroupHeadingFont);
	CreateGroupOfAutoUpdateAndProductiveModeSettings(Form, ListName, GroupCreationParameters, MatchingCreatedElements);
	
	#EndRegion
	
	#Region GroupIrrelevantData
	GroupIrrelevantData = Form.Items.Insert(ListName + "GroupIrrelevantData", Type("FormGroup"),
		Parameters.PlacementGroupSettings); //FormGroupExtensionForAUsualGroup
	GroupIrrelevantData.Type = FormGroupType.UsualGroup;
	GroupIrrelevantData.TitleFont = FontOfPopUpGroupTitle;
	GroupIrrelevantData.Group = ChildFormItemsGroup.AlwaysHorizontal;
	GroupIrrelevantData.Representation = UsualGroupRepresentation.WeakSeparation;
	GroupIrrelevantData.Behavior = UsualGroupBehavior.PopUp;
	GroupIrrelevantData.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	GroupIrrelevantData.VerticalAlignInGroup = ItemVerticalAlign.Center;
	GroupIrrelevantData.Title = NStr("vi = 'Có thể, dữ liệu biểu mẫu đã cũ';
									|ru = 'Возможно, данные формы устарели';
									|en = 'These forms may be outdated'; fa = 'These forms may be outdated';
									|it = 'Возможно, данные формы устарели';
									|pl = 'These forms may be outdated';
									|tr = 'Bu formlar güncelliğini yitirmiş olabilir'");
	GroupIrrelevantData.TitleTextColor = WebColorsDarkOrange;
	GroupIrrelevantData.Visible = True;
	
	SettingsGroupIrrelevantData = Form.Items.Insert(ListName + "SettingsGroupIrrelevantData", Type("FormGroup"),
		GroupIrrelevantData); //FormGroupExtensionForAUsualGroup
	SettingsGroupIrrelevantData.Type = FormGroupType.UsualGroup;
	SettingsGroupIrrelevantData.Title = NStr("vi = 'Tùy chỉnh';
											|ru = 'Настройки';
											|en = 'Settings'; fa = 'تنظیمات';
											|it = 'Настройки';
											|pl = 'Settings';
											|tr = 'Ayarlar'");
	SettingsGroupIrrelevantData.ShowTitle = False;
	SettingsGroupIrrelevantData.Representation = UsualGroupRepresentation.None;
	SettingsGroupIrrelevantData.Group = ChildFormItemsGroup.Vertical;
	
	IrrelevantDataDataIsOutdated = Form.Items.Insert(ListName + "IrrelevantDataDataIsOutdated", Type(
		"FormDecoration"), SettingsGroupIrrelevantData);
	IrrelevantDataDataIsOutdated.Type = FormDecorationType.Label;
	IrrelevantDataDataIsOutdated.Title = NStr(
		"vi = 'Để cập nhật dữ liệu của các chứng từ được phản ánh trong danh sách, hãy sử dụng nút ""Cập nhật"" trên biểu mẫu hoặc bật sử dụng cập nhật tự động danh sách.';
		|ru = 'Для актуализации отражаемых в списке данных документов следует воспользоваться кнопкой ""Обновить"" на форме или включить автообновление списка.';
		|en = 'To update the documents displayed in the data list, click Update on the form or enable the automatic list update.'; fa = 'To update the documents displayed in the data list, click Update on the form or enable the automatic list update.';
		|it = 'Для актуализации отражаемых в списке данных документов следует воспользоваться кнопкой ""Обновить"" на форме или включить автообновление списка.';
		|pl = 'To update the documents displayed in the data list, click Update on the form or enable the automatic list update.';
		|tr = 'Listeye yansıtılan belge verilerini güncellemek için formdaki “Güncelle” düğmesini kullanın veya listenin otomatik güncellenmesini etkinleştirin.'");
	IrrelevantDataDataIsOutdated.TextColor = WebColorsAreDullGray;
	
	GroupCreationParameters = New Structure;
	GroupCreationParameters.Insert("SettingsPrefix", "IrrelevantData");
	GroupCreationParameters.Insert("ParentGroup1", SettingsGroupIrrelevantData);
	GroupCreationParameters.Insert("AttributeNameAutoUpdateMode", Parameters.AttributeNameAutoUpdateMode);
	GroupCreationParameters.Insert("SettingsStructure", SettingsStructure);
	GroupCreationParameters.Insert("DisplayTitleListUpdate", True);
	GroupCreationParameters.Insert("WebColorsAreDullGray", WebColorsAreDullGray);
	GroupCreationParameters.Insert("GroupHeadingFont", GroupHeadingFont);
	CreateGroupOfAutoUpdateAndProductiveModeSettings(Form, ListName, GroupCreationParameters, MatchingCreatedElements);
	
	UpdateButton = Form.Items.Insert(ListName + "_Refresh", Type("FormButton"),
		Parameters.PlacementGroupSettings);
	UpdateButton.CommandName = Parameters.NameOfListUpdateCommands;
	UpdateButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	
	#EndRegion
	
	ListSettingsStructure = StructureOfUserSettingsOfList();
	ListSettingsStructure.GroupDescriptionOfProblems = GroupDescriptionOfProblems.Name;
	ListSettingsStructure.GroupNoProblems = GroupNoProblems.Name;
	ListSettingsStructure.GroupIrrelevantData = GroupIrrelevantData.Name;
	ListSettingsStructure.ListName = Parameters.ListName;
	ListSettingsStructure.NameOfListItem = Parameters.NameOfListItem;
	ListSettingsStructure.HasMainTable = SettingsStructure.HasMainTable;
	ListSettingsStructure.ListKeys  = SettingsStructure.ListKeys;
	ListSettingsStructure.ListOfCompositeTypeFields = Parameters.ListOfCompositeFields;
	ListSettingsStructure.DataIsOutdated = False;
	ListSettingsStructure.UpdatingDuration = 0;
	ListSettingsStructure.TimeLimitForUpdatingListOfDocuments = Parameters.TimeLimitForUpdatingListOfDocuments;
	ListSettingsStructure.TheRefreshButton = UpdateButton.Name;
	ListSettingsStructure.AttributeNameAutoUpdateMode = Parameters.AttributeNameAutoUpdateMode;
	ListSettingsStructure.AttributeNameProductiveUpdateMode = SettingsStructure.AttributesProductiveUpdateMode;
	ListSettingsStructure.ProblematicSettingsElement = GroupDocumentsProblematicSettings.Name;
	ListSettingsStructure.ItemTitleOfListIssue = TitleOfListIssue.Name;
	ListSettingsStructure.SelectedFieldsElement = GroupDocumentsSelectedFields.Name;
	ListSettingsStructure.HeaderElementSelectedFields = DocumentsTitleSelectedFields.Name;
	ListSettingsStructure.SelectedFieldsCriticalElement = DocumentsSelectedFieldsAreCritical.Name;
	ListSettingsStructure.SelectedFieldsElementIsNormal = DocumentsSelectedFieldsAreNormal.Name;
	ListSettingsStructure.ItemSelectedFieldsFix = DocumentsSelectedFieldsCorrect.Name;
	ListSettingsStructure.ListSelectionsElement = GroupDocumentsListSelections.Name;
	ListSettingsStructure.SelectionHeaderElement = DocumentsTitleSelection.Name;
	ListSettingsStructure.ElementSelectionCritical = DocumentsSelectionCritical.Name;
	ListSettingsStructure.SelectionElementIsOrdinary = SelectionDocumentsAreOrdinary.Name;
	ListSettingsStructure.ElementSelectionsFix = DocumentSelectionsCorrect.Name;
	ListSettingsStructure.ListOrderElement = GroupDocumentsListOrder.Name;
	ListSettingsStructure.HeadingOrderElement = DocumentsTitleOrder.Name;
	ListSettingsStructure.ElementOrderCritical = DocumentsAreOrderCritical.Name;
	ListSettingsStructure.OrderElementIsOrdinary = DocumentsAreInUsualOrder.Name;
	ListSettingsStructure.FixOrderElement = DocumentsOrderToFix.Name;
	ListSettingsStructure.ListConditionalAppearanceElement = GroupDocumentsConditionalAppearanceOfList.Name;
	ListSettingsStructure.HeadingConditionalAppearanceElement = DocumentsTitleConditionalAppearance.Name;
	ListSettingsStructure.ConditionalAppearanceElementIsCritical = DocumentsConditionalAppearanceCritical.Name;
	ListSettingsStructure.ConditionalAppearanceElementIsOrdinary = DocumentsConditionalAppearanceOrdinary.Name;
	ListSettingsStructure.FixConditionalAppearanceElement = DocumentsConditionalAppearanceCorrect.Name;

	SettingsStructure.Insert("Settings", ListSettingsStructure);
	SettingsStructure.Insert("ElementsOfSettingsGroup", MatchingCreatedElements);

EndProcedure

// Checks the elements of the dynamic list selection settings and identifies those that may lead to a decrease
// in the speed of working with it.
// 
// Parameters:
//  ListFilter - DataCompositionFilter - List Selections
//  FieldList - Array of String - List of configuration fields
//
Procedure CheckElementsOfDynamicListSelectionSettings(ListFilter, FieldList)
	
	For Each FilterElement In ListFilter.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			CheckElementsOfDynamicListSelectionSettings(FilterElement, FieldList);
			Continue;
			
		EndIf;
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") And FilterElement.Use Then
			FilterField = String(FilterElement.LeftValue);
			If Not StrFind(FilterField, ".") = 0 Then
				FieldList.Add(FilterField);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the elements of the order settings of the dynamic list and identifies those that may lead to a decrease
// in the speed of working with it.
// 
// Parameters:
//  ListOrder - DataCompositionOrder - Ordering the list
//  FieldList - Array of String - list of fields
//  ListOfCompositeAttributes - Array of String - List Of Composite Type Fields
//
Procedure CheckItemsOfDynamicListOrderSettings(ListOrder, FieldList, ListOfCompositeAttributes)
	
	For Each OrderItem In ListOrder.Items Do
		
		If TypeOf(OrderItem) = Type("DataCompositionOrderItem") And OrderItem.Use Then
			OrderField_ = String(OrderItem.Field);
			If Not StrFind(OrderField_, ".") = 0 
				Or Not ListOfCompositeAttributes.Find(String(OrderItem.Field)) = Undefined Then
					FieldList.Add(OrderField_);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the elements of the selected fields of the dynamic list and identifies those that may lead to a decrease 
// in the speed of working with it.
// 
// Parameters:
//  SettingStructure - DataCompositionSettingStructureItemCollection - List configuration structure
//  FieldList - Array of String - list of fields
//
Procedure CheckElementsOfSelectedFieldsOfDynamicList(SettingStructure, FieldList)
	
	For Each ChoiceItem In SettingStructure Do
		For Each CurrentSelectionField In ChoiceItem.Selection.Items Do
			If TypeOf(CurrentSelectionField) = Type("DataCompositionSelectedField") Then
				ComboBox = String(CurrentSelectionField.Field);
				If Not StrFind(ComboBox, ".") = 0 Then
					FieldList.Add(ComboBox);
				EndIf;
			EndIf;
			If TypeOf(ChoiceItem) = Type("DataCompositionSelectedFieldGroup") Then
				CheckElementsOfSelectedFieldsOfDynamicList(ChoiceItem.Structure, FieldList);
			EndIf;
		EndDo;
	EndDo;

EndProcedure

// Checks the selection of elements of the conditional design settings of the dynamic list
// and identifies those that may lead to a decrease in the speed of working with it.
// 
// Parameters:
//  SettingStructure - DataCompositionSettingStructureItemCollection - List configuration structure
//  FieldList - Array of String - list of fields
//
Procedure CheckElementsOfConditionalAppearanceSettingsOfDynamicList(SettingStructure, FieldList)
	
	For Each ConditionalAppearanceItem In SettingStructure Do
		For Each ConditionalAppearanceSetting In ConditionalAppearanceItem.ConditionalAppearance.Items Do
			CheckElementsOfDynamicListSelectionSettings(ConditionalAppearanceSetting.Filter, FieldList);
		EndDo;
	EndDo;

EndProcedure

Procedure CreateGroupOfAutoUpdateAndProductiveModeSettings(Form, ListName, Parameters, MatchingCreatedElements)
	
	Action = "ListOfDocumentsFormElementEventHandling";
	
	DescriptionAutoUpdatingList = NStr(
		"vi = 'Khi bật tùy chọn này, sẽ cập nhật danh sách mỗi lần sau khi thay đổi chứng từ mà điều đó sẽ dẫn đến tăng thời gian kết chuyển chúng.';
		|ru = 'При включенном параметре каждый раз после изменения документов будет выполняться обновление списка, что может приводить к увеличению времени их проведения.';
		|en = 'If the parameter is enabled, the list will be updated every time the documents are changed. This may increase their posting time.'; fa = 'If the parameter is enabled, the list will be updated every time the documents are changed. This may increase their posting time.';
		|it = 'При включенном параметре каждый раз после изменения документов будет выполняться обновление списка, что может приводить к увеличению времени их проведения.';
		|pl = 'If the parameter is enabled, the list will be updated every time the documents are changed. This may increase their posting time.';
		|tr = 'Etkinleştirilirse, belgeler her değiştirildiğinde liste güncellenir ve bu da tamamlanma süresinin uzamasına neden olabilir.'");
	
	DescriptionProductiveMode = NStr(
		"vi = 'Việc bật tùy chọn này sẽ tăng tốc độ cập nhật danh sách chứng từ. 
		|Ở chế độ này, các phím nóng Ins Del F2 F9 không khả dụng.
		|Để áp dụng cài đặt, bạn cần mở lại biểu mẫu danh sách.';
		|ru = 'Включение параметра ускоряет обновление списка документов. 
		|В данном режиме недоступны горячие клавиши Ins Del F2 F9.
		|Для применения настройки требуется заново открыть форму списка.';
		|en = 'Enabling this parameter speeds up the document list update. 
		|Ins Del F2 F9 keyboard shortcuts are not available in this mode.
		|To apply the setting, reopen the list form.'; fa = 'Enabling this parameter speeds up the document list update. 
		|Ins Del F2 F9 keyboard shortcuts are not available in this mode.
		|To apply the setting, reopen the list form.';
		|it = 'Включение параметра ускоряет обновление списка документов. 
		|В данном режиме недоступны горячие клавиши Ins Del F2 F9.
		|Для применения настройки требуется заново открыть форму списка.';
		|pl = 'Enabling this parameter speeds up the document list update. 
		|Ins Del F2 F9 keyboard shortcuts are not available in this mode.
		|To apply the setting, reopen the list form.';
		|tr = 'Ayarın etkinleştirilmesi belge listesinin güncellenmesini hızlandırır. 
		| Del F2 F9 kısayol tuşları bu modda kullanılamaz. 
		|Ayarı uygulamak için liste formunu yeniden açmanız gerekir.'");
		
	WebColorsAreDullGray = Parameters.WebColorsAreDullGray;
		
	AutoUpdateSettingsGroup = Form.Items.Insert(ListName + Parameters.SettingsPrefix + "AutoRefreshSettings",
		Type("FormGroup"), Parameters.ParentGroup1); //FormGroupExtensionForAUsualGroup
	AutoUpdateSettingsGroup.Type = FormGroupType.UsualGroup;
	AutoUpdateSettingsGroup.Title = NStr("vi = 'Tùy chỉnh tự động cập nhật';
										|ru = 'Настройки автообновления';
										|en = 'Auto update settings'; fa = 'Auto update settings';
										|it = 'Настройки автообновления';
										|pl = 'Auto update settings';
										|tr = 'Otomatik güncelleme ayarları'");
	AutoUpdateSettingsGroup.ShowTitle = False;
	AutoUpdateSettingsGroup.Representation = UsualGroupRepresentation.None;
	AutoUpdateSettingsGroup.Group = ChildFormItemsGroup.Vertical;

	TitleUpdatingList = Form.Items.Insert(ListName + Parameters.SettingsPrefix + "TitleUpdatingList", Type(
		"FormDecoration"), AutoUpdateSettingsGroup);
	TitleUpdatingList.Type = FormDecorationType.Label;
	TitleUpdatingList.Title = NStr("vi = 'Tùy chỉnh cập nhật danh sách';
									|ru = 'Настройки обновления списка';
									|en = 'List update settings'; fa = 'List update settings';
									|it = 'Настройки обновления списка';
									|pl = 'List update settings';
									|tr = 'Güncelleme ayarlarını listele'");
	TitleUpdatingList.Font = Parameters.GroupHeadingFont;
	TitleUpdatingList.Visible = Parameters.DisplayTitleListUpdate;
	
	AutoUpdateMode = Form.Items.Insert(ListName + Parameters.SettingsPrefix + "AutoUpdateMode", Type("FormField"),
		AutoUpdateSettingsGroup);
	AutoUpdateMode.Type = FormFieldType.CheckBoxField;
	AutoUpdateMode.TitleLocation = FormItemTitleLocation.Right;
	AutoUpdateMode.DataPath = Parameters.AttributeNameAutoUpdateMode;
	AutoUpdateMode.SetAction("OnChange", Action);
	AutoUpdateMode.Visible = True;
	AutoUpdateMode.Enabled = True;
	MatchingCreatedElements.Insert(AutoUpdateMode.Name, "RefreshEnabled");

	InscriptionAutoUpdateExplanation = Form.Items.Insert(ListName + Parameters.SettingsPrefix + "InscriptionAutoUpdateExplanation",
		Type("FormDecoration"), AutoUpdateSettingsGroup);
	InscriptionAutoUpdateExplanation.Type = FormDecorationType.Label;
	InscriptionAutoUpdateExplanation.Title = DescriptionAutoUpdatingList;
	InscriptionAutoUpdateExplanation.TextColor = WebColorsAreDullGray;

	ProductiveMode = Form.Items.Insert(ListName + Parameters.SettingsPrefix + "ProductiveMode", Type("FormField"),
		AutoUpdateSettingsGroup);
	ProductiveMode.Type = FormFieldType.CheckBoxField;
	ProductiveMode.TitleLocation = FormItemTitleLocation.Right;
	ProductiveMode.DataPath = Parameters.SettingsStructure.AttributesProductiveUpdateMode;
	ProductiveMode.SetAction("OnChange", Action);
	ProductiveMode.Enabled = True;
	ProductiveMode.Visible = Parameters.SettingsStructure.UseMechanismToChangeListSettings;
	MatchingCreatedElements.Insert(ProductiveMode.Name, "SpeedingUpListUpdates");
	
	ProductiveModeExplanation = Form.Items.Insert(ListName + Parameters.SettingsPrefix + "ProductiveModeExplanation",
		Type("FormDecoration"), AutoUpdateSettingsGroup);
	ProductiveModeExplanation.Type = FormDecorationType.Label;
	ProductiveModeExplanation.Title = DescriptionProductiveMode;
	ProductiveModeExplanation.TextColor = WebColorsAreDullGray;
	ProductiveModeExplanation.Visible = Parameters.SettingsStructure.UseMechanismToChangeListSettings;
	
EndProcedure

Function TitleOfAvailableListField(ListBox, AvailableFields)
	
	FieldDetails = Undefined;
	
	AvailableFieldsElements = AvailableFields.Items;
	
	FieldElements = StrSplit(ListBox, ".");
	IndexOf = 0;
	FieldParts = New Array;
	
	While IndexOf < FieldElements.Count() Do
		
		FieldParts.Add(FieldElements[IndexOf]);
		Id = StrConcat(FieldParts, ".");
		FieldDetails = AvailableFieldsElements.Find(Id);
		
		If FieldDetails <> Undefined
			And IndexOf <> FieldElements.UBound() Then
			AvailableFieldsElements = FieldDetails.Items;
		EndIf;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	If FieldDetails = Undefined Then
		Return ListBox;
	Else
		Return FieldDetails.Title;
	EndIf;
	
EndFunction

Function NameOfDocumentListFormSettings()
	
	Return "ListOfDocumentsCacheSettings";
	
EndFunction

#EndRegion