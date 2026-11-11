////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for the user
// to work with document logs.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Displays a group of user selections and settings.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure DocumentsDisplayGroupOfUserSelectionsAndSettings(Form, ListName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;

	DisplayGroupOfUserSelectionsAndSettings(Form, Form[ListSettings.AttributeNameAutoUpdateMode],
		ListSettings);
	
EndProcedure

// Sets the value of the document list settings.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
//  PropertyName - String - property name
//  Value - Arbitrary
Procedure SetValueOfDocumentListSettings(Form, ListName, PropertyName, Value) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	
	If ListSettings.Property(PropertyName) Then
		ListSettings[PropertyName] = Value;
	EndIf; 

EndProcedure

// Getting the document list setting value.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
// 
// Returns:
//  Arbitrary - The Value Of The Document List Settings
Function SettingValueForAutoUpdatingListOfDocuments(Form, ListName) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	FormAttributesAutoUpdateMode = ListSettings["AttributeNameAutoUpdateMode"];

	Return Form[FormAttributesAutoUpdateMode];

EndFunction

// Checks that the time of the last update of the list exceeds the allowed time.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
// 
// Returns:
//  Boolean - The Time To Update The List Exceeds The Allowed Time
Function TimeToUpdateListExceedsAllowedTime(Form, ListName) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	
	If (ListSettings.UpdatingDuration >= ListSettings.TimeLimitForUpdatingListOfDocuments)
		And Not ListSettings.DataIsOutdated Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;

EndFunction

// Get key parameters for a document.
// 
// Parameters:
//  DocumentReference - DocumentRef - link to the document
//  Date - Date - Document date
//  BusinessOperation - EnumRef.BusinessTransactions
// 
// Returns:
//  Structure - Get Key Parameters For A Document:
// * Ref - DocumentRef - link to the document
// * Date - Date - Document date
// * BusinessOperation - EnumRef.BusinessTransactions 
Function GetKeyParametersForDocument(DocumentReference, Date, BusinessOperation) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Ref", DocumentReference);
	ReturnStructure.Insert("Date", Date);
	ReturnStructure.Insert("BusinessOperation", BusinessOperation);
	
	Return ReturnStructure;
	
EndFunction

// Sets the parameters for updating the list of documents.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
//  DataIsOutdated - Boolean - Indicates that the data is outdated
//  UpdatingDuration - Undefined, Date - Duration of the last update in seconds
Procedure SetParametersForUpdatingDocumentList(Form, ListName, DataIsOutdated,
	UpdatingDuration = Undefined) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	
	If Form[ListSettings.AttributeNameAutoUpdateMode] Then
		ListSettings.DataIsOutdated = False;
	Else
		ListSettings.DataIsOutdated = DataIsOutdated;
	EndIf;

	If Not UpdatingDuration = Undefined Then
		ListSettings.UpdatingDuration = UpdatingDuration;
	EndIf;

EndProcedure

// Updating the data of the document list with time measurement.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
//  Parameter - Arbitrary
Procedure UpdateDocumentListDataWithTimeMeasurement(Form, ListName, Parameter = Undefined) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	NameOfListItem = ListSettings.NameOfListItem;
	ListKeys = ListSettings.ListKeys;
	
	CurrentRow = Form.Items[NameOfListItem].CurrentRow;
	If CurrentRow <> Undefined And TypeOf(CurrentRow) <> Type("DynamicListGroupRow")
		And ListSettings.HasMainTable = False Then

		RowData = Form.Items[NameOfListItem].RowData(CurrentRow);
		KeyStructure1 = New Structure;
		KeyStructure1.Insert(ListKeys.Get("Date"), CurrentRow[ListKeys.Get("Date")]);
		KeyStructure1.Insert(ListKeys.Get("RefType"), CurrentRow[ListKeys.Get("RefType")]);
		KeyStructure1.Insert(ListKeys.Get("BusinessOperation"), CurrentRow[ListKeys.Get(
			"BusinessOperation")]);
		KeyStructure1.Insert(ListKeys.Get("RecordID"), CurrentRow[ListKeys.Get(
			"RecordID")]);

	EndIf;
	
	MeasurementStartTime = CommonClient.SessionDate();
	Form.Items[ListSettings.NameOfListItem].Refresh();
	UpdatingDuration = CommonClient.SessionDate() - MeasurementStartTime;
	SetParametersForUpdatingDocumentList(Form, ListName, False, UpdatingDuration);
	
	If CurrentRow <> Undefined And TypeOf(CurrentRow) <> Type("DynamicListGroupRow")
		And ListSettings.HasMainTable = False And Not RowData = Undefined Then

		If TypeOf(Parameter) = Type("Structure") And Parameter.Property("NotificationDocumentKeys") And RowData.Ref
			= Parameter.NotificationDocumentKeys.Ref Then
			KeyStructure1.Insert(ListKeys.Get("Date"), Parameter.NotificationDocumentKeys.Date);
			KeyStructure1.Insert(ListKeys.Get("BusinessOperation"),
				Parameter.NotificationDocumentKeys.BusinessOperation);
		Else
			OperationsWithDocumentJournalsServerCall.FindDataOfCurrentLineInList(RowData.Ref, KeyStructure1, ListKeys);
		EndIf;

		CurrentLineIsNew = New DynamicListRowKey(KeyStructure1);
		Form.Items[NameOfListItem].CurrentRow = CurrentLineIsNew;

	EndIf;
	
EndProcedure

// Updating the list of documents when an alert processing event occurs on the Form.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
//  Parameter - Arbitrary
Procedure UpdateListOfDocumentsEventNotificationProcessing(Form, ListName, Parameter = Undefined) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	
	If Form[ListSettings.AttributeNameAutoUpdateMode] Then
		UpdateDocumentListDataWithTimeMeasurement(Form, ListName, Parameter);
	Else
		
		ListKeys = ListSettings.ListKeys;
		NameOfListItem = ListSettings.NameOfListItem;
		CurrentRow = Form.Items[NameOfListItem].CurrentRow;
		If CurrentRow <> Undefined And TypeOf(CurrentRow) <> Type("DynamicListGroupRow")
			And ListSettings.HasMainTable = False Then

			RowData = Form.Items[NameOfListItem].RowData(CurrentRow);
			KeyStructure1 = New Structure;
			KeyStructure1.Insert(ListKeys.Get("Date"), CurrentRow[ListKeys.Get("Date")]);
			KeyStructure1.Insert(ListKeys.Get("RefType"), CurrentRow[ListKeys.Get("RefType")]);
			KeyStructure1.Insert(ListKeys.Get("BusinessOperation"), CurrentRow[ListKeys.Get(
			"BusinessOperation")]);
			KeyStructure1.Insert(ListKeys.Get("RecordID"), CurrentRow[ListKeys.Get(
			"RecordID")]);

		EndIf;
	
		SetParametersForUpdatingDocumentList(Form, ListName, True);
		
		If CurrentRow <> Undefined And TypeOf(CurrentRow) <> Type("DynamicListGroupRow")
			And ListSettings.HasMainTable = False And Not RowData = Undefined Then

			If TypeOf(Parameter) = Type("Structure") And Parameter.Property("NotificationDocumentKeys") And RowData.Ref
				= Parameter.NotificationDocumentKeys.Ref Then
				KeyStructure1.Insert(ListKeys.Get("Date"), Parameter.NotificationDocumentKeys.Date);
				KeyStructure1.Insert(ListKeys.Get("BusinessOperation"),
					Parameter.NotificationDocumentKeys.BusinessOperation);
			Else
				OperationsWithDocumentJournalsServerCall.FindDataOfCurrentLineInList(RowData.Ref, KeyStructure1,
					ListKeys);
			EndIf;

			CurrentLineIsNew = New DynamicListRowKey(KeyStructure1);
			Form.Items[NameOfListItem].CurrentRow = CurrentLineIsNew;

		EndIf;
		
	EndIf;

EndProcedure

// Retrieves the name of the list of documents by the name of the Form element.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  TagName - String - name of the element on the form
// 
// Returns:
//  Structure - Data about the name of the list and the action:
// * ListName - String - 
// * Action - String - 
Function NameOfListOfDocumentsByNameOfFormElement(Form, TagName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ReturnStructure = New Structure("ListName, Action", "", "");
	
	For Each DocumentsList In Form[SettingName] Do
		
		DataByItem = DocumentsList.Value["ElementsOfSettingsGroup"].Get(TagName);
		If DataByItem <> Undefined Then
			ReturnStructure.ListName = DocumentsList.Key;
			ReturnStructure.Action = DataByItem;
			Return ReturnStructure;
		EndIf;
		
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

// Correction of user selections in the document list.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure FixCustomSelectionsInDocumentList(Form, ListName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;

	ProblematicElementsOfSelection = New Array; //StructureOfUserSettings
	CommonClientServer.SupplementArray(ProblematicElementsOfSelection,
		ListSettings.StructureOfUserSettings["FilterRegular"], True);
	CommonClientServer.SupplementArray(ProblematicElementsOfSelection,
		ListSettings.StructureOfUserSettings["FilterCriticalOnes"], True);

	DynamicListUserSettingsDisableUseOfSelectionItems(Form[ListName],
		ProblematicElementsOfSelection);

	CommonClientServer.SetFormItemProperty(Form.Items, ListSettings.ListSelectionsElement,
		"Visible", False);

	DisplayGroupOfUserSelectionsAndSettings(Form, Form[ListSettings.AttributeNameAutoUpdateMode],
		ListSettings, True);

EndProcedure

// Correction of sorting settings in the document list.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure FixSortingSettingsInDocumentList(Form, ListName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;

	ProblematicElementsOfOrder = New Array;
	CommonClientServer.SupplementArray(ProblematicElementsOfOrder,
		ListSettings.StructureOfUserSettings["OrderIsNormal"], True);
	CommonClientServer.SupplementArray(ProblematicElementsOfOrder,
		ListSettings.StructureOfUserSettings["OrderIsCritical"], True);

	DynamicListUserSettingsDisableUseOfOrderItems(Form[ListName],
		ProblematicElementsOfOrder);

	CommonClientServer.SetFormItemProperty(Form.Items, ListSettings.ListOrderElement,
		"Visible", False);

	DisplayGroupOfUserSelectionsAndSettings(Form, Form[ListSettings.AttributeNameAutoUpdateMode],
		ListSettings, True);

EndProcedure

// Correction of conditional formatting settings in the list of documents.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure FixConditionalAppearanceSettingsInDocumentList(Form, ListName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;

	ProblematicElementsOfConditionalAppearance = New Array;
	CommonClientServer.SupplementArray(ProblematicElementsOfConditionalAppearance,
		ListSettings.StructureOfUserSettings["ConditionalAppearanceOrdinary"], True);
	CommonClientServer.SupplementArray(ProblematicElementsOfConditionalAppearance,
		ListSettings.StructureOfUserSettings["ConditionalAppearanceCritical"], True);

	DynamicListUserSettingsDisableUseOfDesignElements(Form[ListName],
		ProblematicElementsOfConditionalAppearance);

	CommonClientServer.SetFormItemProperty(Form.Items,
		ListSettings.ListConditionalAppearanceElement, "Visible", False);

	DisplayGroupOfUserSelectionsAndSettings(Form, Form[ListSettings.AttributeNameAutoUpdateMode],
		ListSettings, True);

EndProcedure

// Saving the settings of the productive list update mode.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure SaveSettingProductiveListUpdateMode(Form, ListName) Export
	
	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;

	ProductiveUpdateModeIsEnabled = Form[ListSettings.AttributeNameProductiveUpdateMode];
	
	OperationsWithDocumentJournalsServerCall.SaveSettingProductiveListUpdateMode(ProductiveUpdateModeIsEnabled);

EndProcedure

// Sets the list of documents to indicate that the displayed data is no longer relevant.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
Procedure SetFlagForDisplayingIrrelevantDataInList(Form, ListName) Export

	SettingName = NameOfDocumentListFormSettings();
	ListSettings = Form[SettingName][ListName].Settings;
	
	If Not Form[ListSettings.AttributeNameAutoUpdateMode] Then
		
		SetParametersForUpdatingDocumentList(Form, ListName, True);
		ShowGroupOfListUpdateSettings("IrrelevantData", Form, ListSettings);
		
	EndIf;

EndProcedure

// Displaying a group of user selections and settings on the Form by default.
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
		
		ShowGroupOfListUpdateSettings("NoProblems", Form, ListSettings);
		
	EndIf;

EndProcedure

// Parameters for updating the list of documents.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListName - String - the name of the dynamic list Attribute on the Form
// 
// Returns:
//  Structure - Parameters For Updating The Document List:
// * Form - ClientApplicationForm - 
// * ListName - String -
// * UpdateList - See OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments 
Function ParametersForUpdatingDocumentList(Form, ListName) Export
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("Form", Form);
	ParametersOfUpdate.Insert("ListName", ListName);
	
	UpdateList = OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments(Form, ListName);

	ParametersOfUpdate.Insert("UpdateList", UpdateList);
	
	Return ParametersOfUpdate;
	
EndFunction

#EndRegion

#Region Private

// Reading the settings of the dynamic list and displaying items that may reduce the speed of working
// with it in the group of user selections and settings on the Form.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListParameters - See OperationsWithDocumentJournals.StructureOfUserSettingsOfList
//
Procedure ReadDisplayDynamicListSettings(Form, ListParameters)
	
	Settings = ListParameters.StructureOfUserSettings;

	//Filters
	CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.ListSelectionsElement,
		"Visible", Settings.ThereAreProblemsInSelectionSettingsCritical
		Or Settings.ThereAreProblemsInSelectionSettings);
	CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.ElementSelectionCritical,
		"Visible", Settings.ThereAreProblemsInSelectionSettingsCritical);
	CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.SelectionElementIsOrdinary,
		"Visible", Settings.ThereAreProblemsInSelectionSettings);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.ElementSelectionsFix, "Visible", Settings.ThereAreProblemsInSelectionSettings
		Or Settings.ThereAreProblemsInSelectionSettingsCritical);

	If Settings.ThereAreProblemsInSelectionSettingsCritical Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.ElementSelectionCritical, "Title", StrConcat(Settings.FilterCriticalOnesPresentation,
			Chars.LF));
	EndIf;

	If Settings.ThereAreProblemsInSelectionSettings Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.SelectionElementIsOrdinary, "Title", StrConcat(Settings.FilterRegularPresentation,
			Chars.LF));
	EndIf;
		
	// Selected field
	CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.SelectedFieldsElement,
		"Visible", Settings.ThereAreProblemsInSelectedFieldsCritical Or Settings.ThereAreProblemsInSelectedFields);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.SelectedFieldsCriticalElement, "Visible", Settings.ThereAreProblemsInSelectedFieldsCritical);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.SelectedFieldsElementIsNormal, "Visible", Settings.ThereAreProblemsInSelectedFields);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.ItemSelectedFieldsFix, "Visible", Settings.ThereAreProblemsInSelectedFieldsCritical
		Or Settings.ThereAreProblemsInSelectedFields);

	If Settings.ThereAreProblemsInSelectedFieldsCritical Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.SelectedFieldsCriticalElement, "Title", StrConcat(
				Settings.SelectedFieldsAreCriticalPresentation, Chars.LF));
	EndIf;

	If Settings.ThereAreProblemsInSelectedFields Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.SelectedFieldsElementIsNormal, "Title", StrConcat(
				Settings.SelectedFieldsAreNormalPresentation, Chars.LF));
	EndIf;
		
	//Order
	CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.ListOrderElement,
		"Visible", Settings.ThereAreProblemsInSettingsOfOrderCritical
		Or Settings.ThereAreProblemsInOrderSettings);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.ElementOrderCritical, "Visible", Settings.ThereAreProblemsInSettingsOfOrderCritical);
	CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.OrderElementIsOrdinary,
		"Visible", Settings.ThereAreProblemsInOrderSettings);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.FixOrderElement, "Visible", Settings.ThereAreProblemsInSettingsOfOrderCritical
		Or Settings.ThereAreProblemsInOrderSettings);

	If Settings.ThereAreProblemsInSettingsOfOrderCritical Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.ElementOrderCritical, "Title", StrConcat(
				Settings.OrderIsCriticalPresentation, Chars.LF));
	EndIf;

	If Settings.ThereAreProblemsInOrderSettings Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.OrderElementIsOrdinary, "Title", StrConcat(Settings.OrderIsNormalPresentation,
			Chars.LF));
	EndIf;
		
	// conditional design
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.ListConditionalAppearanceElement, "Visible", Settings.ThereAreProblemsInDesignSettingsCritical
		Or Settings.ThereAreProblemsInDesignSettings);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.ConditionalAppearanceElementIsCritical, "Visible",
		Settings.ThereAreProblemsInDesignSettingsCritical);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.ConditionalAppearanceElementIsOrdinary, "Visible",
		Settings.ThereAreProblemsInDesignSettings);
	CommonClientServer.SetFormItemProperty(Form.Items,
		ListParameters.FixConditionalAppearanceElement, "Visible", Settings.ThereAreProblemsInDesignSettingsCritical
		Or Settings.ThereAreProblemsInDesignSettings);

	If Settings.ThereAreProblemsInDesignSettingsCritical Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.ConditionalAppearanceElementIsCritical, "Title", StrConcat(
				Settings.ConditionalAppearanceCriticalPresentation, Chars.LF));
	EndIf;

	If Settings.ThereAreProblemsInDesignSettings Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.ConditionalAppearanceElementIsOrdinary, "Title", StrConcat(
				Settings.ConditionalAppearanceOrdinaryPresentation, Chars.LF));
	EndIf;

EndProcedure

// Checks the user settings for selecting a dynamic list and disables the use of the passed list of fields.
// 
// Parameters:
//  DynamicList - DynamicList -
//  FieldList - Array of String - list of fields
//
Procedure DynamicListUserSettingsDisableUseOfSelectionItems(DynamicList, FieldList)
	
	UserSettings = DynamicList.SettingsComposer.UserSettings;
	For Each ItemTheCustomSettings In UserSettings.Items Do
		
		If TypeOf(ItemTheCustomSettings) = Type("DataCompositionFilter") Then
			DisableUseOfCustomSelectionElementsRecursively(ItemTheCustomSettings, FieldList);
		EndIf;
		
	EndDo;
	
EndProcedure

// Disables the use of custom selection elements recursively through the passed list of fields
// 
// Parameters:
//  ListFilter - DataCompositionFilter, DataCompositionFilterItemGroup - Selecting a list
//  FieldList - Array of String - list of fields
Procedure DisableUseOfCustomSelectionElementsRecursively(ListFilter, FieldList)
	
	For Each FilterElement In ListFilter.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			DisableUseOfCustomSelectionElementsRecursively(FilterElement, FieldList);
			Continue;
			
		EndIf;
		
		If FilterElement.Use Then
			FilterField = String(FilterElement.LeftValue);
			If Not FieldList.Find(FilterField) = Undefined Then
				FilterElement.Use = False;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Displaying a group of user selections and settings on a Form with warnings for those elements
// that may lead to a decrease in the speed of working with a dynamic list.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  AutoUpdatingList - Boolean - Dynamic list auto-update mode
//  ListParameters - See OperationsWithDocumentJournals.StructureOfUserSettingsOfList
//  CorrectionMode - Boolean - Mode for correcting user settings in Form
//
Procedure DisplayGroupOfUserSelectionsAndSettings(Form, AutoUpdatingList, ListParameters, CorrectionMode = False)

	If CorrectionMode Then

		VisibilityElementSelectedFields = CommonClientServer.FormItemPropertyValue(Form.Items,
			ListParameters.SelectedFieldsElement, "Visible");
		VisibilityOfListSelectionElement = CommonClientServer.FormItemPropertyValue(Form.Items,
			ListParameters.ListSelectionsElement, "Visible");
		VisibilityElementListOrder = CommonClientServer.FormItemPropertyValue(Form.Items,
			ListParameters.ListOrderElement, "Visible");
		VisibilityElementConditionalAppearanceOfList = CommonClientServer.FormItemPropertyValue(
			Form.Items, ListParameters.ListConditionalAppearanceElement, "Visible");

		If Not VisibilityElementSelectedFields And Not VisibilityOfListSelectionElement And Not VisibilityElementListOrder
			And Not VisibilityElementConditionalAppearanceOfList Then

			ShowGroupOfListUpdateSettings("NoProblems", Form, ListParameters);

		EndIf;

		Return;

	EndIf;

	If Not AutoUpdatingList And ListParameters.DataIsOutdated Then

		ShowGroupOfListUpdateSettings("IrrelevantData", Form, ListParameters);

	ElsIf Not AutoUpdatingList Then

		If ListParameters.UpdatingDuration >= ListParameters.TimeLimitForUpdatingListOfDocuments
			And ListParameters["StructureOfUserSettings"].ThereAreProblemsInSettings Then

			ShowGroupOfListUpdateSettings("DescriptionOfProblems", Form, ListParameters);
			ReadDisplayDynamicListSettings(Form, ListParameters);

		Else

			ShowGroupOfListUpdateSettings("NoProblems", Form, ListParameters);

		EndIf;

	Else

		If ListParameters.UpdatingDuration >= ListParameters.TimeLimitForUpdatingListOfDocuments
			And ListParameters["StructureOfUserSettings"].ThereAreProblemsInSettings Then

			ShowGroupOfListUpdateSettings("DescriptionOfProblems", Form, ListParameters);
			ReadDisplayDynamicListSettings(Form, ListParameters);

		Else

			ShowGroupOfListUpdateSettings("NoProblems", Form, ListParameters);

		EndIf;

	EndIf;

EndProcedure

// Checks the user settings for the conditional design of the dynamic list and disables the use of the 
// passed list of fields.
// 
// Parameters:
//  DynamicList - DynamicList -
//  FieldList - Array of String - list of fields
//
Procedure DynamicListUserSettingsDisableUseOfDesignElements(DynamicList,
	FieldList) Export

	UserSettings = DynamicList.SettingsComposer.UserSettings;
	For Each ItemTheCustomSettings In UserSettings.Items Do

		If TypeOf(ItemTheCustomSettings) = Type("DataCompositionConditionalAppearance") Then
			ConditionalAppearanceItems = ItemTheCustomSettings.Items;
			For Each ConditionalAppearanceItem In ConditionalAppearanceItems Do
				DisableUseOfCustomSelectionElementsRecursively(ConditionalAppearanceItem.Filter, FieldList);
			EndDo;
		EndIf;

	EndDo;

EndProcedure

// Checks user settings for the order of the dynamic list and disables the use of the passed list of fields.
// 
// Parameters:
//  DynamicList - DynamicList -
//  FieldList - Array of String - list of fields
//
Procedure DynamicListUserSettingsDisableUseOfOrderItems(DynamicList, FieldList)
	
	UserSettings = DynamicList.SettingsComposer.UserSettings;
	For Each ItemTheCustomSettings In UserSettings.Items Do

		If TypeOf(ItemTheCustomSettings) = Type("DataCompositionOrder") Then

			For Each OrderItem In ItemTheCustomSettings.Items Do
				If OrderItem.Use Then
					OrderField_ = String(OrderItem.Field);
					If Not FieldList.Find(OrderField_) = Undefined Then
						OrderItem.Use = False;
					EndIf;
				EndIf;
			EndDo;

		EndIf;

	EndDo;
	
EndProcedure

// Enabling visibility of the main group of the list update settings.
// 
// Parameters:
//  GroupName - String -
//  Form - ClientApplicationForm - The Form in which the dynamic list is configured
//  ListParameters - See OperationsWithDocumentJournals.StructureOfUserSettingsOfList
Procedure ShowGroupOfListUpdateSettings(GroupName, Form, ListParameters)

	If GroupName = "DescriptionOfProblems" Then
		
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupDescriptionOfProblems, "Visible", True);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupNoProblems, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupIrrelevantData, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.TheRefreshButton,
			"Visible", False);
			
	EndIf;
	
	If GroupName = "NoProblems" Then
		
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupDescriptionOfProblems, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupNoProblems, "Visible", True);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupIrrelevantData, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.TheRefreshButton,
			"Visible", False);
			
	EndIf;
	
	If GroupName = "IrrelevantData" Then
		
		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupDescriptionOfProblems, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupNoProblems, "Visible", False);

		CommonClientServer.SetFormItemProperty(Form.Items,
			ListParameters.GroupIrrelevantData, "Visible", True);

		CommonClientServer.SetFormItemProperty(Form.Items, ListParameters.TheRefreshButton,
			"Visible", True);
			
	EndIf;

EndProcedure
	
Function NameOfDocumentListFormSettings()
	
	Return "ListOfDocumentsCacheSettings";
	
EndFunction

#EndRegion