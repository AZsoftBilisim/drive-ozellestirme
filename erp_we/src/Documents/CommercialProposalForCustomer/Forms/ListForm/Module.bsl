
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	CustomizeFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	
	Items.StatusPresentation.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// Handler of the subsystem "Versioning of objects".
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	CommonClientServer.SetDynamicListParameter(List,
	                                                                   "UpdateDate",
	                                                                   CurrentSessionDate(),
	                                                                   True);
	
	CommercialProposalsDocumentsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	CommercialProposalsDocumentsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, EventDate, 
	                                                                                     CurrentSessionDate(), QuickFilterStructure,
	                                                                                     Items.FilterDueDate_2.ChoiceList);
	
	CommercialProposalsDocumentsClientServer.SelectionByListValueWhenCreatedOnServer(List,
	                                                                                       "State",
	                                                                                       StateFilter,
	                                                                                       QuickFilterStructure,,
	                                                                                       DataCompositionComparisonType.InList,
	                                                                                       "StateFilter");
	
	CommercialProposalsDocumentsClientServer.SelectionByListValueWhenCreatedOnServer(List,
	                                                                                       "Manager",
	                                                                                        Manager,
	                                                                                        QuickFilterStructure);
	
	CommercialProposalsDocumentsOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	

	CommercialProposalsDocumentsClientOverridable.HandlingNotificationOfListForms(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	SettingsParameters = CommercialProposalsDocumentsClientServer.SelectionOptionsBeforeLoadingFromSettings();
	SettingsParameters.List        = List;
	SettingsParameters.ColumnName    = "State";
	SettingsParameters.SettingName  = "StateFilter";
	SettingsParameters.Settings     = Settings;
	SettingsParameters.Use = Undefined;
	SettingsParameters.ComparisonType  = DataCompositionComparisonType.InList;
	
	CommercialProposalsDocumentsClientServer.SelectingByListValueBeforeLoadingFromSettings(SettingsParameters, StateFilter, QuickFilterStructure);
	
	SettingsParameters = CommercialProposalsDocumentsClientServer.SelectionOptionsBeforeLoadingFromSettings();
	SettingsParameters.List        = List; 
	SettingsParameters.ColumnName    = "Manager";
	SettingsParameters.SettingName  = "Manager";
	SettingsParameters.Settings     = Settings;
	
	CommercialProposalsDocumentsClientServer.SelectingByListValueBeforeLoadingFromSettings(SettingsParameters, Manager, QuickFilterStructure);
	
	CommercialProposalsDocumentsClientServer.SelectionByRelevanceWhenLoadingFromSettings(
		List,
		Relevance,
		EventDate,
		CurrentSessionDate(),
		QuickFilterStructure,
		Settings,
		Items.FilterDueDate_2.ChoiceList);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionState();
	
EndProcedure

&AtClient
Procedure FilterStateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	MultipleListSelectionStartSelection(ThisObject,
	                                                                            Item,
	                                                                            StateFilter,
	                                                                            Type(StateTypeName),
	                                                                            NStr("vi = 'Bang được chọn';
																					|ru = 'Выбранные состояния';
																					|en = 'Selected states'; fa = 'Selected states';
																					|it = 'Stati selezionati';
																					|pl = 'Wybrane statusy';
																					|tr = 'Seçili durumlar'"));
	
EndProcedure

&AtClient
Procedure FilterDueDate_2OnChange(Item)

	CommercialProposalsDocumentsClientServer.WhenChangingRelevanceSelection(
		List, 
		Relevance, 
		EventDate, 
		CommonClient.SessionDate(),
		Items.FilterDueDate_2.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterDueDate_2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CommercialProposalsDocumentsClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance", 
		"EventDate",
		"FilterDueDate_2");
	
EndProcedure

&AtClient
Procedure SelectionDeadlineForCompletingTheOfferCleaningUp(Item, StandardProcessing)
	
	CommercialProposalsDocumentsClientServer.WhenClearingSelectionByRelevance(
		List,
		Relevance, 
		EventDate, 
		CommonClient.SessionDate(),
		StandardProcessing,
		Items.FilterDueDate_2.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "Manager",
	                                                                        Manager,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	AccountingSettings = CommercialProposalsDocuments.AccountingSettings();
	
	Items.Client.Visible         = AccountingSettings.PartnersAreUsed;
	Items.Counterparty.Visible     = CommercialProposalsDocumentsClientServer.CounterpartyFieldVisible(AccountingSettings);
	
	Items.Status.Visible         = AccountingSettings.StatusOfCommercialOffersToClientsIsUsed;
	Items.State.Visible      = AccountingSettings.StatesOfCommercialOffersToClientsAreUsed;
	Items.FilterState.Visible = AccountingSettings.StatesOfCommercialOffersToClientsAreUsed;
	
	If AccountingSettings.StatesOfCommercialOffersToClientsAreUsed Then
	
		For Each Type In Metadata.DefinedTypes.StatesOfCommercialProposalsToCustomer.Type.Types() Do
			
			ValueMetadata = Metadata.FindByType(Type);
			If ValueMetadata = Undefined Then
				Continue;
			EndIf;
			
			FullTypeName = ValueMetadata.FullName();
			
			If StrFind(FullTypeName, "Enum") > 0 Then
				StateTypeName = "EnumRef." + ValueMetadata.Name;
			EndIf;
			
		EndDo;
	
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List,
	                                                                   "DraftStatuses",
	                                                                   AccountingSettings.StatusOfCommercialOffersToClientsDraft,
	                                                                   True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	AccountingSettings = CommercialProposalsDocuments.AccountingSettings();
	
	ConditionalAppearance.Items.Clear();
	List.ConditionalAppearance.Items.Clear();
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValidityPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentSessionDate();
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AccountingSettings.StatusOfCommercialOffersToClientsDraft;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("ValidityPeriod");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	CommercialProposalsDocumentsOverridable.WhenSettingConditionalAppearance(ThisObject);
	
EndProcedure 

#Region QuickFilters

// Handler for the start event for quick multiple selection in the list.
//
// Parameters:
//  Form              - ClientApplicationForm - The form in which the action is performed.
//  Item            - FormItems - the element that the event is being processed for.
//  Values           - ValueList - contains already selected values.
//  TypeOfEnumeration    - Type - the type of enumeration that the selection is based on.
//  Var_Title - String - title of the selection form.
//
&AtClient
Procedure MultipleListSelectionStartSelection(Form, Item, Values, TypeOfEnumeration, Var_Title)

	OpeningParameters = New Structure;
	OpeningParameters.Insert("SelectionList", Values);
	OpeningParameters.Insert("TypeOfEnumeration", TypeOfEnumeration);
	OpeningParameters.Insert("Title", Var_Title);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	ClosingNotification1 = New CallbackDescription("FormOfMultipleSelectionAfterClosure", Form, AdditionalParameters);
	OpenForm("Document.CommercialProposalForCustomer.Form.MultipleListFilter", OpeningParameters, Item,,,,
		ClosingNotification1);

EndProcedure

// Parameters:
// 	Result - Arbitrary
// 	AdditionalParameters - Structure
&AtClient
Procedure FormOfMultipleSelectionAfterClosure(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Not AdditionalParameters.Property("Item") Then
		Return;
	EndIf;
	
	If AdditionalParameters.Item = Items.FilterState Then
		StateFilter = Result;
		SetSelectionState();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionState()

	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "State",
	                                                                        StateFilter,
	                                                                        DataCompositionComparisonType.InList,
	                                                                        ,
	                                                                        StateFilter.Count() > 0);
	

EndProcedure

#EndRegion

#EndRegion
