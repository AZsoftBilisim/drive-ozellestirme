#Region Public

// Changes the selection element of the list group.
//
// Parameters:
//   Group         - DataCompositionFilterItemGroup - The group for which the selection element is being changed.
//   FieldName        - String - field name.
//   RightValue - Arbitrary - the selection value, by default, is undefined.
//   Set     - Boolean - Indicates the selection setting, False by default.
//   Var_ComparisonType   - DataCompositionComparisonType - by default, it is undefined.
//
Procedure ChangeSelectionElementOfListGroup(Group, FieldName, RightValue = Undefined, Set = False, Var_ComparisonType = Undefined) Export
	
	DeleteCollectionSelectionItem(Group.Items, FieldName);
	
	If Set Then
		SetCollectionSelectionElement(Group.Items, FieldName, RightValue, Var_ComparisonType);
	EndIf;
	
EndProcedure // Change the Subscription element()

// Search for a selection element by view.
//
// Parameters:
//   ItemsCollection - DataCompositionFilterItemCollection - The collection that is being searched.
//   Presentation      - String - the search value.
//   SearchType          - Number - 0 exact match,
//                                1 starts with the passed value,
//                                2 the occurrence of the passed value in the view.
//
// Returns:
//   - DataCompositionFilterItem - the selection element found.
//   - Undefined - if the element is not found.
//
Function FindFilterItemByPresentation(ItemsCollection, Presentation, SearchType = 0) Export
	
	ReturnValue = Undefined;
	
	For Each FilterElement In ItemsCollection Do
		If SearchType = 0 Then
			If FilterElement.Presentation = Presentation Then
				ReturnValue = FilterElement;
				Break;
			EndIf;
		ElsIf SearchType = 1 Then
			If StrFind(FilterElement.Presentation, Presentation) = 1 Then
				ReturnValue = FilterElement;
				Break;
			EndIf;
		ElsIf SearchType = 2 Then
			If StrFind(FilterElement.Presentation, Presentation) > 0 Then
				ReturnValue = FilterElement;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return ReturnValue
	
EndFunction // Find the element of the selection of the representation()

// Creates a group of selection items.
// 
// Parameters:
//   ItemsCollection - DataCompositionFilterItemCollection - The collection in which the group will be created.
//   Presentation - String - representation of group.
//   GroupType - DataCompositionFilterItemsGroupType - type of group.
//
// Returns:
//   - DataCompositionFilterItemGroup
//
Function CreateFilterItemGroup(ItemsCollection, Presentation, GroupType) Export
	
	FilterItemsGroup = FindFilterItemByPresentation(ItemsCollection, Presentation);
	If FilterItemsGroup = Undefined Then
		FilterItemsGroup = ItemsCollection.Add(Type("DataCompositionFilterItemGroup"));
	Else
		FilterItemsGroup.Items.Clear();
	EndIf;
	
	FilterItemsGroup.Presentation    = Presentation;
	FilterItemsGroup.Application       = DataCompositionFilterApplicationType.Items;
	FilterItemsGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItemsGroup.GroupType        = GroupType;
	FilterItemsGroup.Use    = True;
	
	Return FilterItemsGroup;
	
EndFunction

// Sets the dynamic list selection element
//
// Parameters:
//   List         - DynamicList - dynamic list being processed.
//   FieldName        - String - the name of the layout field to select from.
//   RightValue - Arbitrary - the value of the selection.
//   Var_ComparisonType   - DataCompositionComparisonType - the type of selection comparison, by default-Equal.
//   Presentation  - String - view of the layout field to select from.
//
Procedure SetListSelectionElement(List, FieldName, RightValue, Var_ComparisonType = Undefined, Presentation = "") Export
	
	SetCollectionSelectionElement(TMCommonUseClientServer.GetDynamicListSelection(List).Items, FieldName, RightValue, Var_ComparisonType, Presentation);
	
EndProcedure // Install the Subscription element()

// Changes the selection element of the dynamic list
//
// Parameters:
// List         - DynamicList - dynamic list being processed.
// FieldName        - String - the name of the layout field to select from.
// RightValue - Arbitrary - the selection value, by default, is Undefined.
// Use  - Boolean - a sign of the use of selection, by default - False.
// Var_ComparisonType   - DataCompositionComparisonType - the type of selection comparison, by default-Equal.
//
Procedure ChangeListSelectionElement(List, FieldName, RightValue = Undefined, Use = False, Var_ComparisonType = Undefined) Export
	
	CommonClientServer.DeleteFilterItems(
		List.SettingsComposer.Settings.Filter, 
		FieldName);
	CommonClientServer.SetFilterItem(
		List.SettingsComposer.Settings.Filter, 
		FieldName, 
		RightValue, 
		Var_ComparisonType, 
		DataCompositionSettingsItemViewMode.QuickAccess, 
		Use); 
	
EndProcedure // Change the Subscription element()

// Returns a custom selection element in the dynamic list 
// that corresponds to the selection specified in the configurator with the specified name.
// The match is determined by matching the setting IDs.
//
// Parameters:
//  List - DynamicList - a dynamic list for which the selection element is searched.
//  FilterName - String - the selection name specified in the configurator for the dynamic list settings item.
//
// Returns:
//  - DataCompositionFilterItem - the found user selection element.
//  - Undefined - if the custom selection element is not found.
//
Function ListSelectionElementByName(List, FilterName) Export

	Filters = CommonClientServer.FindFilterItemsAndGroups(
		List.SettingsComposer.Settings.Filter, 
		FilterName);
	
	If Filters.Count() = 0 Then
		Return Undefined;
	Else
		Return Filters[0];
	EndIf;
	
EndFunction

// Sets or changes the "fast" selection of a dynamic list (based on the selection values specified in the form details).
//
// Parameters:
// Form - ClientApplicationForm - a form that has a dynamic list attribute named List.
// FieldName - String - selection name, the form must have details with the names Selection<Field name> and Selection<Field name>Using.
// Var_ComparisonType - DataCompositionComparisonType - type of selection comparison.
//
Procedure SetQuickFilter(Form, FieldName, Var_ComparisonType = Undefined) Export
	
	RightValue = Form["Filter" + FieldName];
	Use  = Form["Filter" + FieldName + "Use"];
	CommonClientServer.DeleteFilterItems(
		Form.List.SettingsComposer.Settings.Filter, 
		FieldName);
	CommonClientServer.SetFilterItem(
		Form.List.SettingsComposer.Settings.Filter,
		FieldName,
		RightValue,
		Var_ComparisonType,
		,
		Use);
	
EndProcedure

#Region RelevanceSelectionProcedures

// Sets the selection by relevance passed to the list of documents form
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Relevance - String - selection line by relevance
// ChoiceList - ValueList - List of values for selecting an element of the selection form by relevance
// EventDate - Date - date on which documents should be considered irrelevant
// QuickFilterStructure - Structure - transferred in the form of a list of documents selected.
//
Procedure SelectionByRelevanceWhenCreatingOnServer(List, Relevance, ChoiceList, EventDate, Val QuickFilterStructure) Export
	
	If QuickFilterStructure <> Undefined Then
		
		QuickFilterStructure.Property("Relevance",   Relevance);
		QuickFilterStructure.Property("EventDate",    EventDate);
		
		WhenChangingRelevanceSelection(List, Relevance, EventDate, ChoiceList);
	EndIf;
	
EndProcedure

// Sets the list of documents in the form of a selection by relevance, saved in the settings
// Selection from the settings is set only if the selection is not passed to the form from the outside.
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Relevance - String - selection line by relevance
// EventDate - Date - the date on which the documents should be considered irrelevant
// List of selections - List of values - A list of values for selecting an element of the selection form by relevance
// QuickFilterStructure - Structure - selection passed to the list of documents form
// Settings - Map - form settings.
//
Procedure SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, ChoiceList, EventDate, Val QuickFilterStructure, Settings) Export
	
	If QuickFilterStructure = Undefined Then
		
		Relevance     = Settings.Get("Relevance");
		EventDate      = Settings.Get("EventDate");
		
		WhenChangingRelevanceSelection(List, Relevance, EventDate, ChoiceList);
		
	Else
		
		If Not QuickFilterStructure.Property("Relevance") Then
			Relevance = Settings.Get("Relevance");
		EndIf;
		
		If Not QuickFilterStructure.Property("EventDate") Then
			EventDate = Settings.Get("EventDate");
		EndIf;
		
		WhenChangingRelevanceSelection(List, Relevance, EventDate, ChoiceList);
		
	EndIf;
	
	Settings.Delete("Relevance");
	Settings.Delete("EventDate");
	
EndProcedure

// Sets in the form of a list of documents selected according to the relevance
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Relevance - String - line selection based on relevance.
//
Procedure SetSelectionInListByRelevance(List, Relevance) Export
	
	CommonClientServer.SetDynamicListFilterItem(List, 
		"Overdue",
		Relevance = "Overdue",
		DataCompositionComparisonType.Equal,,
		Relevance = "NotOverdue" Or Relevance = "Overdue");
	
EndProcedure

// Sets in the form of a list of documents selected according to the date of the event
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// EventDate - Date - the date on which the document will be expired.
//
Procedure SetSelectionInListByEventDate(List, EventDate) Export
	
	TypeOfEventDateComparison = DataCompositionComparisonType.LessOrEqual;
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo ngày sự kiện';
			|ru = 'Отбор по дате события';
			|en = 'Filter by event date'; fa = 'Filter by event date';
			|it = 'Selezione per data di evento';
			|pl = 'Filtr wg daty zdarzenia';
			|tr = 'Etkinleştirme tarihi'"), 
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"EventDate",
		TypeOfEventDateComparison,
		EventDate,,
		ValueIsFilled(EventDate));
		
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"EventDate",
		DataCompositionComparisonType.NotEqual,
		Date(1,1,1),,
		ValueIsFilled(EventDate));

EndProcedure

// Sets the selection by relevance and date of relevance in the form of a list of documents
// Changes the value of the up-to-date date depending on the up-to-date string.
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Relevance - String - selection line by relevance
// EventDate - Date - the date on which the documents are considered outdated.
// ChoiceList - ValueList - List of values for selecting an element of the selection form by relevance
//
Procedure WhenChangingRelevanceSelection(List, Relevance, EventDate, ChoiceList=Undefined) Export
	
	TypeOfEventDateComparison = DataCompositionComparisonType.Equal;
	
	If Not ValueIsFilled(Relevance) Then
		EventDate = Date(1,1,1);
	ElsIf Relevance = "Today" Then
		EventDate = GeneralPurposeTMServerCall.SessionDate();
	ElsIf Relevance = "Tomorrow" Then
		EventDate = GeneralPurposeTMServerCall.SessionDate() + 86400;
	ElsIf Relevance = "TheDayAfterTomorrow" Then
		EventDate = GeneralPurposeTMServerCall.SessionDate() + 172800;
	ElsIf Relevance = "InAWeek" Then
		EventDate = GeneralPurposeTMServerCall.SessionDate() + 604800;
	ElsIf Relevance = "ExpiresOnDate" Then
		
		Presentation = NStr("vi = 'Hết hạn vào %EventDate%';
							|ru = 'Истекает на %EventDate%';
							|en = 'Expires on %EventDate%'; fa = 'Expires on %EventDate%';
							|it = 'Scade il %EventDate%';
							|pl = 'Upływa w dniu  %EventDate%';
							|tr = '%EventDate% sona eriyor'");
		
		Presentation = StrReplace(Presentation, "%EventDate%", Format(EventDate, "DF=MM/dd/yy"));
		ChoiceList.FindByValue(Relevance).Presentation = Presentation;

	// Working out the old values from the saved settings
	ElsIf Relevance =  NStr("vi = 'Hôm nay';
							|ru = 'Сегодня';
							|en = 'Today'; fa = 'امروز';
							|it = 'Oggi';
							|pl = 'Today';
							|tr = 'Bugün'") Then
		Relevance = "Today";
		EventDate = GeneralPurposeTMServerCall.SessionDate();
	ElsIf Relevance = NStr("vi = 'Ngày mai';
							|ru = 'Завтра';
							|en = 'Tomorrow'; fa = 'Tomorrow';
							|it = 'Domani';
							|pl = 'Tomorrow';
							|tr = 'Yarın'") Then
		Relevance = "Tomorrow";
		EventDate = GeneralPurposeTMServerCall.SessionDate() + 86400;
	ElsIf Relevance = NStr("vi = 'Ngày kia';
							|ru = 'Послезавтра';
							|en = 'The day after tomorrow'; fa = 'The day after tomorrow';
							|it = 'Dopodomani';
							|pl = 'The day after tomorrow';
							|tr = 'Öbür gün'") Then
		Relevance = "TheDayAfterTomorrow";
		EventDate = GeneralPurposeTMServerCall.SessionDate() + 172800;
	ElsIf Relevance = NStr("vi = 'Trong một tuần';
							|ru = 'Через неделю';
							|en = 'In a week'; fa = 'In a week';
							|it = 'Tra una settimana';
							|pl = 'Za tydzień';
							|tr = 'Bir hafta sonra'") Then
		Relevance = "InAWeek";
		EventDate = GeneralPurposeTMServerCall.SessionDate() + 604800;
	ElsIf Relevance = NStr("vi = 'Tất cả';
							|ru = 'Все';
							|en = 'All'; fa = 'همه';
							|it = 'Tutti';
							|pl = 'All';
							|tr = 'Tümü'") 
		Or StrFind(Relevance,  NStr("vi = 'Hết hạn ngày';
									|ru = 'Истекающие на';
									|en = 'Expiring as of ...'; fa = 'Expiring as of ...';
									|it = 'Che scade il';
									|pl = 'Upływające w dniu';
									|tr = 'Sona eren'")) > 0 Then
		Relevance = "";
		EventDate = Date(1,1,1);
	ElsIf StrFind(Relevance, NStr("vi = 'Hết hạn';
									|ru = 'Истекает на';
									|en = 'Expires on'; fa = 'Expires on';
									|it = 'Scade il';
									|pl = 'Upływa w dniu';
									|tr = 'Sona eriyor'")) > 0 Then
		Relevance = "ExpiresOnDate";
		Presentation = NStr("vi = 'Hết hạn vào %EventDate%';
							|ru = 'Истекает на %EventDate%';
							|en = 'Expires on %EventDate%'; fa = 'Expires on %EventDate%';
							|it = 'Scade il %EventDate%';
							|pl = 'Upływa w dniu  %EventDate%';
							|tr = '%EventDate% sona eriyor'");
		Presentation = StrReplace(Presentation, "%EventDate%", Format(EventDate, "DF=MM/dd/yy"));
		ChoiceList.FindByValue(Relevance).Presentation = Presentation;
	ElsIf Relevance = NStr("vi = 'Đã quá hạn';
							|ru = 'Просрочен';
							|en = 'Overdue document'; fa = 'سند سررسیدگذشته';
							|it = 'Scaduto';
							|pl = 'Overdue document';
							|tr = 'Vadesi geçti'") Or Relevance = NStr("vi = 'Quá hạn';
																			|ru = 'Просроченные';
																			|en = 'Overdue documents'; fa = 'Overdue documents';
																			|it = 'Scaduti';
																			|pl = 'Overdue documents';
																			|tr = 'Vadesi geçenler'") Then
		Relevance = "Overdue";
		EventDate      = Date(1,1,1);
	ElsIf Relevance = "NotOverdue"
		Or Relevance = NStr("vi = 'Chưa quá hạn';
							|ru = 'Не просрочен';
							|en = 'Not overdue document'; fa = 'Not overdue document';
							|it = 'Non scaduto';
							|pl = 'Nieprzeterminowany';
							|tr = 'Vadesi geçmemiş'") 
		Or Relevance = NStr("vi = 'Chưa quá hạn';
							|ru = 'Не просроченные';
							|en = 'Not overdue documents'; fa = 'اسناد سررسیدنگذشته';
							|it = 'Non scaduti';
							|pl = 'Nie zaległe';
							|tr = 'Vadesi geçmeyenler'") Then
		Relevance = "NotOverdue";
		EventDate      = Date(1,1,1);
	EndIf;
	
	SetSelectionInListByRelevance(List, Relevance);
	SetSelectionInListByEventDate(List, EventDate);
	
EndProcedure

// Sets the selection by relevance and date of relevance in the form of a list of documents
// Changes the value of the up-to-date date depending on the up-to-date string.
//
// Parameters:
// 	List - DynamicList - a list in which you want to set the selection
// 	Relevance - String - selection line by relevance
// 	EventDate - Date - date on which the document will be expired
// 	StandardProcessing - Boolean - flag for performing standard processing when clearing the field value.
//
Procedure WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing) Export
	
	StandardProcessing = False;
	If ValueIsFilled(Relevance) Then
		Relevance = "";
		WhenChangingRelevanceSelection(List, Relevance, EventDate);
	EndIf;
	
EndProcedure

// Fills in the selection list for selection by relevance
//
// Parameters:
// 	RelevanceSelectionList - ValueList - a list of choices that need to be filled.
//
Procedure FillInSelectionSelectionListByRelevance(RelevanceSelectionList) Export
	
	RelevanceSelectionList.Add("NotOverdue", NStr("vi = 'Chưa quá hạn';
													|ru = 'Не просрочен';
													|en = 'Not overdue document'; fa = 'Not overdue document';
													|it = 'Non scaduto';
													|pl = 'Nieprzeterminowany';
													|tr = 'Vadesi geçmemiş'"));
	RelevanceSelectionList.Add("Overdue", NStr("vi = 'Đã quá hạn';
												|ru = 'Просрочен';
												|en = 'Overdue document'; fa = 'سند سررسیدگذشته';
												|it = 'Scaduto';
												|pl = 'Overdue document';
												|tr = 'Vadesi geçti'"));
	RelevanceSelectionList.Add("ExpiresOnDate", NStr("vi = 'Hết hạn vào ngày...';
													|ru = 'Истекает на дату...';
													|en = 'Expires on date ...'; fa = 'انقضا در تاریخ ...';
													|it = 'Scade il...';
													|pl = 'Dobiega końca w dniu...';
													|tr = 'Son kullanma tarihi...'"));
	RelevanceSelectionList.Add("Today", NStr("vi = 'Hôm nay';
											|ru = 'Сегодня';
											|en = 'Today'; fa = 'امروز';
											|it = 'Oggi';
											|pl = 'Today';
											|tr = 'Bugün'"));
	RelevanceSelectionList.Add("Tomorrow", NStr("vi = 'Ngày mai';
												|ru = 'Завтра';
												|en = 'Tomorrow'; fa = 'Tomorrow';
												|it = 'Domani';
												|pl = 'Tomorrow';
												|tr = 'Yarın'"));
	RelevanceSelectionList.Add("TheDayAfterTomorrow", NStr("vi = 'Ngày kia';
															|ru = 'Послезавтра';
															|en = 'The day after tomorrow'; fa = 'The day after tomorrow';
															|it = 'Dopodomani';
															|pl = 'The day after tomorrow';
															|tr = 'Öbür gün'"));
	RelevanceSelectionList.Add("InAWeek", NStr("vi = 'Qua tuần';
												|ru = 'Через неделю';
												|en = 'In a week'; fa = 'In a week';
												|it = 'Tra una settimana';
												|pl = 'Za tydzień';
												|tr = 'Bir hafta sonra'"));
	
EndProcedure

#EndRegion

// STATE SELECTION FUNCTIONS

// Checks whether the state selection is passed to the document list form
//
// Parameters:
// State - String - selection line by state
// QuickFilterStructure - Structure - transferred in the form of a list of documents selected.
//
// Returns:
// Boolean
// The truth is, if you want to set the selection condition, otherwise False.
//
Function YouNeedToSelectByStateWhenCreatingOnServer(State, Val QuickFilterStructure) Export
	
	If QuickFilterStructure <> Undefined Then
		If QuickFilterStructure.Property("State", State) Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction // The need to select the state of the creation of the server()

// Checks whether you need to set the selection by state, loaded from the settings or passed to the form from the outside.
// Selection from the settings is set only if the selection is not passed to the form from the outside.
//
// Parameters:
// 	State - EnumRef - The selection condition
// 	QuickFilterStructure - Structure - The structure rapid selection
// 	Settings - Map - form settings.
//
// Returns:
// 	Boolean - 
Function YouNeedToSelectByStateWhenLoadingFromSettings(State, Val QuickFilterStructure, Settings) Export
	
	StateSelectionIsNecessary = False;
	
	If QuickFilterStructure = Undefined Then
		
		State = Settings.Get("State");
		StateSelectionIsNecessary = True;
		
	Else
	
		If Not QuickFilterStructure.Property("State") Then
			State = Settings.Get("State");
			StateSelectionIsNecessary = True;
		EndIf;
		
	EndIf;
	
	Settings.Delete("State");

	Return StateSelectionIsNecessary;
	
EndFunction // The need to select the state of the load of the settings()

// SELECTION PROCEDURES BY REGULARITY

// Sets the passed in form of list of documents selected according to the regularity
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Regularity - String - selection string by regularity
// QuickFilterStructure - Structure - transferred in the form of a list of documents selected.
//
Procedure SelectionByRegularityWhenCreatingOnServer(List, Regularity, Val QuickFilterStructure) Export
	
	If QuickFilterStructure <> Undefined Then
		
		If QuickFilterStructure.Property("Regularity", Regularity) Then
			SetSelectionInListByRegularity(List, Regularity);
		EndIf;
		
	EndIf;
	
EndProcedure // Selectionregularity of the creation of the Server()

// Sets in the form of a list of documents selected according to the frequency, stored in the settings
// Selection from the settings is set only if the selection is not passed to the form from the outside.
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Regularity - String - selection string by regularity
// QuickFilterStructure - Structure - selection passed to the list of documents form
// Settings - Map - form settings.
//
Procedure SelectionByRegularityWhenLoadingFromSettings(List, Regularity, Val QuickFilterStructure, Settings) Export
	
	If QuickFilterStructure = Undefined Then
		
		Regularity = Settings.Get("Regularity");
		SetSelectionInListByRegularity(List, Regularity);
		
	Else
	
		If Not QuickFilterStructure.Property("Regularity") Then
			Regularity = Settings.Get("Regularity");
			SetSelectionInListByRegularity(List, Regularity);
		EndIf;
		
	EndIf;
	
	Settings.Delete("Regularity");
	
EndProcedure // Selectionregularizagruzkeiznadjustments()

// Sets the list of documents to be selected by frequency
//
// Parameters:
// List - DynamicList - a list in which you want to set the selection
// Regularity - String - selection string by regularity.
//
Procedure SetSelectionInListByRegularity(List, Regularity) Export
	
	CommonClientServer.SetDynamicListFilterItem(List, "Frequent", Regularity = "Regular", DataCompositionComparisonType.Equal,,ValueIsFilled(Regularity));
	
EndProcedure // Set the breakdiscoregularity()

// SELECTION PROCEDURES BY LIST VALUE

// Sets the selection in the list by the specified value for the desired column
// , taking into account the passed quick selection structure.
//
// Parameters:
//  List - DynamicList -  dynamic list for which you want to set the selection
//  ColumnName - String - Name of the column to select from
//  Value - Arbitrary -  set the value of selection
//  QuickFilterStructure - Undefined, Structure - A structure containing the keys and values selection
//  Use - Undefined, Boolean - Indicates whether the selection element is used
//  Var_ComparisonType - Undefined, DataCompositionComparisonType - comparison type set for the selection element
//  ConvertValueToNumber - Boolean - Indicates whether the value is converted to a number.
//
Procedure SelectionByListValueWhenCreatedOnServer(List, ColumnName, Value, Val QuickFilterStructure, 
			Use = Undefined, Var_ComparisonType = Undefined, ConvertValueToNumber = False) Export
	
	If QuickFilterStructure <> Undefined Then
		
		If QuickFilterStructure.Property(ColumnName, Value) Then
			If ConvertValueToNumber Then
				Value = ?(ValueIsFilled(Value), Number(Value), Value);
			EndIf;
			UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
			CommonClientServer.SetDynamicListFilterItem(List, ColumnName, Value, Var_ComparisonType,,UsingSelectionElement);
		EndIf;
		
	EndIf;
	
EndProcedure // Selection of the value of the list of the creation of the Server()

// Sets the selection in the list by the specified value for the desired column
// , taking into account the passed quick selection structure and the passed settings.
//
// Parameters:
//  List - DynamicList - dynamic list for which you want to set the selection
//  ColumnName - String - Name of the column to select from
//  Value - Arbitrary - set the value of selection
//  QuickFilterStructure - Undefined, Structure - A structure containing the keys and values selection
//  Settings - Map - form settings that can be used to get selection values
//  Use - Undefined, Boolean - Indicates whether the selection element is used
//  Var_ComparisonType - Undefined, DataCompositionComparisonType - comparison type set for the selection element
//  ConvertValueToNumber - Boolean - Indicates whether the value is converted to a number.
//
Procedure SelectionByListValueWhenLoadingFromSettings(List, ColumnName, Value, Val QuickFilterStructure, 
			Settings, Use = Undefined, Var_ComparisonType = Undefined, ConvertValueToNumber = False) Export
	
	If QuickFilterStructure = Undefined Then
		Value = Settings.Get(ColumnName);
		If ConvertValueToNumber Then
			Value = ?(ValueIsFilled(Value), Number(Value), Value);
		EndIf;
		UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
		CommonClientServer.SetDynamicListFilterItem(List, ColumnName, Value, Var_ComparisonType,,UsingSelectionElement);
	Else
		If Not QuickFilterStructure.Property(ColumnName) Then
			Value = Settings.Get(ColumnName);
			If ConvertValueToNumber Then
				Value = ?(ValueIsFilled(Value), Number(Value), Value);
			EndIf;
			UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
			CommonClientServer.SetDynamicListFilterItem(List, ColumnName, Value, Var_ComparisonType,,UsingSelectionElement);
		EndIf;
	EndIf;
	
	Settings.Delete(ColumnName);
	
EndProcedure

// Sets selections in the list by the specified value for the desired column
// , taking into account the passed quick selection structure and the passed settings.
//
// Parameters:
//	FilterParameters - Structure - The structure of the selection parameters, including the following fields:
//  	*ListForm - ClientApplicationForm - Form where dynamic lists are located
//  	*ArrayOfLists - Array - an array of names of dynamic lists that you want to set the selection
//  	*ColumnName - String - Name of the column to select from
//  	*Value - Arbitrary - set the value of selection
//  	*Settings - Map - form settings that can be used to get selection values
//  QuickFilterStructure - Undefined, Structure - A structure containing the keys and values selection
//  Use - Undefined, Boolean - Indicates whether the selection element is used
//  Var_ComparisonType - Undefined, DataCompositionComparisonType - the type of comparison that is set for the selection element.
//
Procedure SetSelectionsByListValueWhenLoadingFromSettings(FilterParameters, Val QuickFilterStructure, Use = Undefined, Var_ComparisonType = Undefined) Export
	
	ListForm     = FilterParameters.ListForm;
	ArrayOfLists 	= FilterParameters.ArrayOfLists;
	ColumnName  	= FilterParameters.ColumnName;
	Value        = FilterParameters.Value;
	Settings       = FilterParameters.Settings;
	
	If QuickFilterStructure = Undefined Then
		Value = Settings.Get(ColumnName);
		UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
		For Each List In ArrayOfLists Do
			CommonClientServer.SetDynamicListFilterItem(ListForm[List], 
				ColumnName,
				Value,
				Var_ComparisonType,,
				UsingSelectionElement);
		EndDo;
	Else
		If Not QuickFilterStructure.Property(ColumnName) Then
			Value = Settings.Get(ColumnName);
			UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
			For Each List In ArrayOfLists Do
				CommonClientServer.SetDynamicListFilterItem(ListForm[List],
					ColumnName, 
					Value, 
					Var_ComparisonType,,
					UsingSelectionElement);
			EndDo;
		EndIf;
	EndIf;
	
	Settings.Delete(ColumnName);
	
EndProcedure
// PROCEDURES AND FUNCTIONS OF SELECTION BY MANAGER

// The procedure copies values from the source list to the selection field selection list
//
Procedure CopySelectionListOfSelectionByManager(ChoiceList, SourceList) Export
	
	ChoiceList.Clear();
	For Iterator_SSLy = 0 To SourceList.Count() - 1 Do
		ChoiceList.Add(SourceList[Iterator_SSLy].Value, SourceList[Iterator_SSLy].Presentation);
	EndDo;
	
EndProcedure // Copy the Selection list to the Manager()

// Deletes a dynamic list selection element
//
// Parameters:
// List  - DynamicList - dynamic list being processed,
// FieldName - String - name of the layout field to remove the selection from.
//
Procedure DeleteListSelectionItem(List, FieldName) Export
	
	ItemsToDelete1 = New Array;
	
	FilterItems1 = TMCommonUseClientServer.GetDynamicListSelection(List).Items;
	LayoutField = New DataCompositionField(FieldName);
	For Each FilterElement In FilterItems1 Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem")
			And FilterElement.LeftValue = LayoutField Then
			ItemsToDelete1.Add(FilterElement);
		EndIf;
	EndDo;
	
	For Each SelectionElementToDelete In ItemsToDelete1 Do
		FilterItems1.Delete(SelectionElementToDelete);
	EndDo;
	
EndProcedure // Delete the Subscription element()

#EndRegion

#Region Private

Procedure SetCollectionSelectionElement(ItemsCollection, FieldName, RightValue, Var_ComparisonType = Undefined, Presentation = "")
	
	FilterElement = ItemsCollection.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue    = New DataCompositionField(FieldName);
	FilterElement.ComparisonType     = ?(Var_ComparisonType = Undefined, DataCompositionComparisonType.Equal, Var_ComparisonType);
	FilterElement.Use    = True;
	FilterElement.RightValue   = RightValue;
	FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterElement.Presentation    = Presentation;
	
EndProcedure // Install the elements of the Collection()

Procedure DeleteCollectionSelectionItem(ItemsCollection, FieldName)
	
	LayoutField = New DataCompositionField(FieldName);
	For Each FilterElement In ItemsCollection Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem")
			And FilterElement.LeftValue = LayoutField Then
			ItemsCollection.Delete(FilterElement);
		EndIf;
	EndDo;
	
EndProcedure // Remove the elements of the Collection()

#EndRegion