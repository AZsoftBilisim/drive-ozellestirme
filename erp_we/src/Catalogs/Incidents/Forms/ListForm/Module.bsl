#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ListOfDuplicateIncidents = New Array;
	
	If Parameters.Property("ListOfIncidents", ListOfDuplicateIncidents) Then
		CommonClientServer.SetDynamicListFilterItem(
		List, "Ref", ListOfDuplicateIncidents, DataCompositionComparisonType.InList,, True);
	EndIf;
	
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
	
	SetPeriod();
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDesiredDate.ChoiceList);
	
	RestoreFormSettingsWhenCreating(); 
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		SaveFormSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PeriodOnChange(Item) 
	
	SaveFormSettings();
	SetSelectionByPeriod(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterAuthorOnChange(Item)
	
	SaveFormSettings();
	SetSelectionByAuthor(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterIncidentKindOnChange(Item)
	
	SaveFormSettings();
	SetSelectionBasedOnTypeOfIncident(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterSeverityOnChange(Item)
	
	SaveFormSettings();
	SetSelectionByCriticality(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SaveFormSettings();
	SetSelectionByResponsible(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SaveFormSettings();
	SetSelectionByStatus(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region SettingManagement

&AtServer
Procedure RestoreFormSettingsWhenCreating()
	
	FormSettings = FormDataSettingsStorage.Load(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey());
	If ValueIsFilled(FormSettings) Then
		FillPropertyValues(ThisForm, FormSettings);
	EndIf; 
	
	SetSelectionByAuthor(ThisForm);
	SetSelectionBasedOnTypeOfIncident(ThisForm);
	SetSelectionByCriticality(ThisForm);
	SetSelectionByResponsible(ThisForm);
	SetSelectionByPeriod(ThisForm);
	SetSelectionByStatus(ThisForm);
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterDesiredDate.ChoiceList);
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	FormSettings = SavedFormSettings();
	
	FillPropertyValues(FormSettings, ThisForm);
	FormDataSettingsStorage.Save(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey(), FormSettings);
	
EndProcedure

&AtServer
Function SavedFormSettings()
	
	Result = New Structure;
	Result.Insert("FilterPeriod");
	Result.Insert("FilterIncidentKind");
	Result.Insert("FilterSeverity");
	Result.Insert("FilterEmployeeResponsible");
	Result.Insert("FilterAuthor");
	Result.Insert("FilterStatus");
	Result.Insert("Relevance");
	Result.Insert("EventDate");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "Incidents";
	
EndFunction

&AtServer
Function SettingsManagerSettingsKey()
	
	Return "FormSettings";
	
EndFunction

#EndRegion 

#Region FormMaintenance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.RegistrationDate", "RegistrationDate");

	// Severity
	SetConditionalDesignOfCriticalityField();
	
	// highlighting an overdue incident in color
	#Region OverdueIncidents
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("RequiredClosingDate");
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.RequiredClosingDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentSessionDate();
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.IncidentStatuses.Registered;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalDesignOfCriticalityField()
	
	Catalogs.IncidentsSeverity.SetConditionalDesignOfCriticalityField(ThisObject, "List", "Severity", "Severity", True, "FilterSeverity", "FilterSeverity");
	
EndProcedure

#EndRegion

#Region ListSettings

&AtServer
Procedure SetPeriod()
	
	CurrentDate = CurrentSessionDate();
	List.Parameters.SetParameterValue("CurrentDate", CurrentDate);
	
EndProcedure

#EndRegion

#Region Filters

&AtClientAtServerNoContext
Procedure SetSelectionByAuthor(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Author", 
		Form.FilterAuthor,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterAuthor));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Status",
		Form.FilterStatus,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterStatus));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByResponsible(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Performer", 
		Form.FilterEmployeeResponsible,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterEmployeeResponsible));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByCriticality(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Severity", 
		Form.FilterSeverity,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterSeverity));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionBasedOnTypeOfIncident(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"IncidentKind", 
		Form.FilterIncidentKind,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterIncidentKind));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByPeriod(Form)
	
	If ValueIsFilled(Form.FilterPeriod.StartDate) Then
		
		Items_Group = CommonClientServer.CreateFilterItemGroup(
			Form.List.Filter.Items,
			"GroupBegin",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"RegistrationDate", 
			DataCompositionComparisonType.GreaterOrEqual, 
			Form.FilterPeriod.StartDate);
			
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"RegistrationDate", 
			DataCompositionComparisonType.NotFilled);
			
	Else
		
		CommonClientServer.DeleteFilterItems(
			Form.List.Filter,
			"RegistrationDate");
		
	EndIf;
	
	If ValueIsFilled(Form.FilterPeriod.EndDate) Then
		
		Items_Group = CommonClientServer.CreateFilterItemGroup(
			Form.List.Filter.Items,
			"EndGroup",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"RegistrationDate", 
			DataCompositionComparisonType.LessOrEqual, 
			Form.FilterPeriod.EndDate);
			
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"RegistrationDate", 
			DataCompositionComparisonType.NotFilled);
			
	Else
		
		CommonClientServer.DeleteFilterItems(
			Form.List.Filter,
			"RegistrationDate");
			
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterDesiredDateOnChange(Item) 
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterDesiredDate.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterDesiredDateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
		TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterDesiredDate",
		"EventDate");
		
EndProcedure

&AtClient
Procedure FilterDesiredDateClearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SceneryAllIncidentsClick(Item)
	
	Clear_Filter();
	
EndProcedure 

&AtClient
Procedure SceneryIsOnMeClick(Item)   
	
	Clear_Filter();
	SceneryIsOnMeClickServer();
	SetSelectionByResponsible(ThisForm);
	SetSelectionByStatus(ThisForm);

EndProcedure 

&AtClient
Procedure DecorationIsOverdueClick(Item) 
	
	Clear_Filter();
	DecorationExpiredClickOnServer();
	SetSelectionByStatus(ThisForm);

	If ValueIsFilled(EventDate) Then
		Presentation = NStr("vi = 'Đã quá hạn';
							|ru = 'Просрочен';
							|en = 'Overdue'; fa = 'سررسیدگذشته';
							|it = 'Scaduto';
							|pl = 'Przeterminowany';
							|tr = 'Vadesi geçti'");
		Relevance = Presentation;
		Items["FilterDesiredDate"].ChoiceList.FindByValue("Overdue").Presentation = Presentation;
	EndIf;
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterDesiredDate.ChoiceList);
	RefreshDataRepresentation();

EndProcedure

&AtClient
Procedure DecorationForTodayClick(Item) 
	
	Clear_Filter();
	FilterPeriod = New StandardPeriod(StandardPeriodVariant.Today);
	SetSelectionByPeriod(ThisForm);

EndProcedure

&AtServer
Procedure SceneryIsOnMeClickServer()
	
	FilterEmployeeResponsible 	= Users.AuthorizedUser();
	FilterStatus			= Enums.IncidentStatuses.Registered;

EndProcedure

&AtServer
Procedure DecorationExpiredClickOnServer()
	
	EventDate = Common.CurrentUserDate();
	FilterStatus = Enums.IncidentStatuses.Registered;

EndProcedure 

&AtClient
Procedure Clear_Filter()
	
	FilterStructure1 = IncidentSelectionStructure();
	
	For Each Item In FilterStructure1 Do
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, Item.Key); 
	EndDo;

	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, True);

	FilterAuthor			= Undefined;
	FilterIncidentKind	= Undefined;
	FilterSeverity	= Undefined;
	FilterEmployeeResponsible	= Undefined;
	FilterPeriod			= Undefined;
	FilterStatus			= Undefined;
	
EndProcedure

&AtClient
Function IncidentSelectionStructure()
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("GroupBegin");
	FilterStructure1.Insert("EndGroup");
	FilterStructure1.Insert("RegistrationDate");
	FilterStructure1.Insert("IncidentKind");
	FilterStructure1.Insert("Severity");
	FilterStructure1.Insert("Performer");
	FilterStructure1.Insert("Status");
	FilterStructure1.Insert("Author");
	
	Return FilterStructure1;
	
EndFunction

#EndRegion

#EndRegion