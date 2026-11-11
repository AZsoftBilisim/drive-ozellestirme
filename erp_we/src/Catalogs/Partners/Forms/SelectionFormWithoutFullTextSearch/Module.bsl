
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	PartnersAndCounterparties.PartnersFormForSelectingListWhenCreatingItOnServer(ThisForm, Cancel, StandardProcessing);
	
	If Not Parameters.Counterparty.IsEmpty() Then
		Items.ByCounterparty.Visible = True;
		Items.List.Representation = TableRepresentation.List;
		Partner = Common.ObjectAttributesValues(Parameters.Counterparty, New Structure("Partner")).Partner;
		PartnerList.LoadValues(PartnersAndCounterparties.GetDownstreamPartners(Partner));
		Items.ByCounterparty.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Theo đối tác ""%1""';
																									|ru = 'По контрагенту ""%1""';
																									|en = 'By counterparty ""%1""'; fa = 'By counterparty ""%1""';
																									|it = 'Secondo il contraente ""%1""';
																									|pl = 'Wg kontrahenta ""%1""';
																									|tr = '""%1"" cari hesabına göre'"), Parameters.Counterparty);
	EndIf;
	
	If Parameters.Property("Basis") Then
		Basis = Parameters.Basis;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	PartnersAndCounterparties.HideCommandsIfYouDonTHaveEditRights(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	InformationPanelUpdateRequired = False;
	
	PartnersAndCounterpartiesClient.PartnersSelectionListFormNotificationProcessing(ThisForm, EventName, Parameter, Source, InformationPanelUpdateRequired);
	
	If InformationPanelUpdateRequired Then
		IgnoreTheCurrentPositionSaving = True;
		ProcessListRowActivation();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit And Not Parameters.Counterparty.IsEmpty() Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	PartnersAndCounterparties.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
	If Not Parameters.Counterparty.IsEmpty() Then
		
		LoadSettings();
		Items.IncludingDownstream.Visible = ByCounterparty And PartnerList.Count() > 1;
		If ByCounterparty Then
			SetPartnerSelection(ThisForm, IncludingDownstream);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PartnersAndCounterpartiesClient.NavigationBarManageAccessibility(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnlyMineOnChange(Item)
	
	ChangeFilterList();
	
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	
	ExecuteSearch(Undefined);
	
EndProcedure

&AtClient
Procedure SelectionBasisClick(Item, StandardProcessing)
	
	PartnersAndCounterpartiesClient.PartnersSelectionListFormSelectionBasePressing(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SegmentOnChange(Item)
	
	PartnersAndCounterpartiesClient.PartnersFormOfSegmentSelectionListWhenChanging(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure SearchStringAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ByCounterpartyOnChange(Item)
	
	IncludingDownstream = ByCounterparty;
	Items.IncludingDownstream.Visible = (PartnerList.Count() > 1 And ByCounterparty);
	If ByCounterparty Then
		SetPartnerSelection(ThisForm, True);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Ref");
	EndIf;
	
EndProcedure

&AtClient
Procedure IncludingDownstreamOnChange(Item)
	
	SetPartnerSelection(ThisForm, IncludingDownstream);
	
EndProcedure

&AtClient
Procedure FilterType_Clearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure UseAFilterOnChange(Item)
	
	PartnersAndCounterpartiesClient.NavigationBarManageAccessibility(ThisForm);
	ProcessDynamicListRowActivation();
	
EndProcedure

&AtClient
Procedure DynamicListFiltersWhenARowIsActivated(Item)
	
	If Item.Name = "BusinessRegions" And Items.PagesFilterType.CurrentPage <> Items.PageBusinessRegions Then
		Return;
	ElsIf Item.Name = "PartnerAccessGroups" And Items.PagesFilterType.CurrentPage <> Items.PageAccessGroups Then
		Return;
	ElsIf Item.Name = "Managers" And Items.PagesFilterType.CurrentPage <> Items.PageManagers Then
		Return;
	ElsIf Item.Name = "Properties" And Items.PagesFilterType.CurrentPage <> Items.PropertiesPage Then
		Return;
	ElsIf Item.Name = "Categories" And Items.PagesFilterType.CurrentPage <> Items.CategoriesPage Then
		Return;
	EndIf;
	
	If DoNotTestNavigationPanelActivation Then
		DoNotTestNavigationPanelActivation = False;
	Else
		If Item.Name = "BusinessRegions" And CurrentFilterValue = Items.BusinessRegions.CurrentRow Then
			Return;
		ElsIf Item.Name = "PartnerAccessGroups" And CurrentFilterValue = Items.PartnerAccessGroups.CurrentRow Then
			Return;
		ElsIf Item.Name = "Managers" And CurrentFilterValue = Items.Managers.CurrentRow Then
			Return;
		ElsIf Item.Name = "Properties" And CurrentFilterValue = Properties.FindByID(Items.Properties.CurrentRow) Then
			Return;
		ElsIf Item.Name = "Categories" And CurrentFilterValue = Categories.FindByID(Items.Categories.CurrentRow) Then
			Return;
		EndIf;
		
		AttachIdleHandler("ProcessDynamicListRowActivation",0.2,True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerCounterpartiesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	PartnersAndCounterpartiesClient.PartnerCounterpartiesClick(ThisForm);
	
EndProcedure

&AtClient
Procedure ContactPersonsOfPartnerClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	PartnersAndCounterpartiesClient.ContactPersonsOfPartnerClick(ThisForm);
	
EndProcedure 

&AtClient
Procedure ForAllWhenChanging(Item)

	ChangeFilterList(True);
	
EndProcedure

&AtClient
Procedure FilterType_OnChange(Item)
	
	PropertyPageNeedsFilling = False;
	PartnersAndCounterpartiesClient.FiltersNavigationBarFilterTypeWhenChanged(ThisForm, Item, PropertyPageNeedsFilling);
	ChangeFilterList(True, PropertyPageNeedsFilling);
	If PropertyPageNeedsFilling Then
		For Each TreeRow In Properties.GetItems() Do
			Items.Properties.Expand(TreeRow.GetID());
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure FiltersCheckDragAndDrop(Item, DragParameters, StandardProcessing, String, Field)
	
	PartnersAndCounterpartiesClient.FiltersNavigationBarDragCheck(ThisForm, Item, DragParameters, StandardProcessing, String, Field) 
	
EndProcedure

&AtClient
Procedure FiltersDragAndDrop(Item, DragParameters, StandardProcessing, String, Field)
	
	WrittenItemsCount = 0;
	PartnersAndCounterpartiesClient.FiltersNavigationBarDragAndDrop(WrittenItemsCount, Item, DragParameters, StandardProcessing, String, Field);
	
	If WrittenItemsCount > 0 Then
		ChangeFilterList();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.Find("MainCounterparty") Then
		
		CurrentData = Item.CurrentData;
		If CurrentData.BranchOffice And Not ValueIsFilled(CurrentData.MainCounterparty) Then
			
			StandardProcessing = False;
			
			FillParameters = New Structure;
			PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(FillParameters, CurrentData);
			FillParameters.Insert("Counterparty", CurrentData.Counterparty);
			FillParameters.Insert("Partner",    CurrentData.Ref);
			FillParameters.Insert("UsePartnersAsCounterparties", True);
			
			Notification = New CallbackDescription("FillInTheHeadCounterpartyCompletion", ThisObject);
			PartnersAndCounterpartiesClient.FillInTheHeadCounterparty(ThisObject, FillParameters, True, Notification);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("ProcessListRowActivation",0.2,True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	PartnersAndCounterpartiesClient.PartnersSelectListFormListBeforeYouStartAdding(ThisForm, Item, Cancel, Copy, Parent, Var_Group, Basis);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateNewOne(Command)
	
	PartnersAndCounterpartiesClient.PartnersSelectListFormCreateNew(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure FindPP(Command)
	
	ExecuteSearch(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	PartnersAndCounterparties.PartnersListSelectionFormConditionalAppearance(ThisForm);
	PartnersAndCounterparties.SetRegistrationOfHeadCounterpartyInList(ThisForm);

EndProcedure

#Region FullTextSearch

&AtClient
Procedure CheckFullTextSearchIndex(Val Notification)
	
	If Not FullTextSearchIndexIsUpToDate And FileInfobase Then
		
		ShowQueryBox(New CallbackDescription("CheckFullTextSearchIndexCompletion", ThisObject, New Structure("Notification", Notification)), 
			NStr("vi = 'Chưa cập nhật chỉ mục tìm kiếm toàn văn.  Cập nhật chỉ mục?';
				|ru = 'Индекс полнотекстового поиска неактуален. Обновить индекс?';
				|en = 'Full-text search index is invalid. Update the index?'; fa = 'Full-text search index is invalid. Update the index?';
				|it = 'L''indice di ricerca full-text è irrilevante. Aggiornare l''indice?';
				|pl = 'Indeks wyszukiwania pełnotekstowego jest nieaktualny. Zaktualizować indeks?';
				|tr = 'Tam metin arama endeksi güncel değil. Endeksi güncelle?'"), QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	CheckIndexOfFullTextSearchFragment(Notification);
EndProcedure

&AtClient
Procedure CheckFullTextSearchIndexCompletion(QuestionResult, AdditionalParameters) Export
    
    Notification = AdditionalParameters.Notification;
    
    
    Result = QuestionResult; 
    
    If Result = DialogReturnCode.Yes Then
        AttachIdleHandler("UpdateFullTextSearchIndex",0.2,True);
        RunCallback(Notification);
        Return;
    EndIf;
    
    
    CheckIndexOfFullTextSearchFragment(Notification);

EndProcedure

&AtClient
Procedure CheckIndexOfFullTextSearchFragment(Val Notification)
    
    ExecuteFullTextSearch();
    
    RunCallback(Notification);

EndProcedure

&AtClient
Procedure UpdateFullTextSearchIndex()
	
	Status(NStr("vi = 'Đang cập nhật chỉ mục tìm kiếm toàn văn...';
				|ru = 'Идет обновление индекса полнотекстового поиска ...';
				|en = 'Updating full-text search index...'; fa = 'Updating full-text search index...';
				|it = 'Aggiornamento dell''indice di ricerca full-text in corso ...';
				|pl = 'Trwa aktualizacja indeksu wyszukiwania pełnotekstowego ...';
				|tr = 'Tam metin arama endeksi güncelleniyor ...'"));
	UpdateFullTextSearchIndexServer();
	FullTextSearchIndexIsUpToDate = True;
	Status(NStr("vi = 'Đã kết thúc cập nhật chỉ mục tìm kiếm toàn văn...';
				|ru = 'Обновление индекса полнотекстового поиска завершено...';
				|en = 'Updating of the full-text search index has been completed...'; fa = 'Updating of the full-text search index has been completed...';
				|it = 'Aggiornamento dell''indice di ricerca full-text completato ...';
				|pl = 'Aktualizacja indeksu wyszukiwania pełnotekstowego została zakończona...';
				|tr = 'Tam metin arama endeksi güncellenmesi tamamlandı...'"));
	
	ExecuteFullTextSearch();
	
EndProcedure

&AtServer
Procedure UpdateFullTextSearchIndexServer()
	
	PartnersAndCounterparties.UpdateFullTextSearchIndex();
	
EndProcedure

&AtClient
Procedure ExecuteFullTextSearch()
	
	ErrorText = FindPartnersFullTextSearch();
	If ErrorText = Undefined Then
		AdvancedSearch = True;
		PartnersAndCounterpartiesClient.FillInBaseLine(ThisForm);
	Else
		If Not ErrorText = NStr("vi = 'Không tìm thấy gì';
								|ru = 'Ничего не найдено';
								|en = 'No results found'; fa = 'No results found';
								|it = 'Non è stato trovato nulla';
								|pl = 'Nic nie znaleziono';
								|tr = 'Sonuç bulunamadı'") Then
			ShowUserNotification(ErrorText);
		Else
			PartnersAndCounterpartiesClient.RestoreListDisplayAfterFullTextSearch(ThisForm);
			AdvancedSearch = False;
		EndIf;
	EndIf;
	
EndProcedure 

&AtServer
Function FindPartnersFullTextSearch()
	
	Return PartnersAndCounterparties.FindPartnersFullTextSearch(ThisForm)
	
EndFunction

&AtClient
Procedure ExecuteSearch(Val Notification)
	
	If SearchString <> "" Then
		
		CheckFullTextSearchIndex(New CallbackDescription("ExecuteSearchCompletion", ThisObject, New Structure("Notification", Notification)));
        Return;
		
	Else
		
		PartnersAndCounterpartiesClient.RestoreListDisplayAfterFullTextSearch(ThisForm);
		AdvancedSearch = False;
		CommonClientServer.SetDynamicListParameter(List,
		                                                                   "FullTextSearchSelectionIsSet",
		                                                                   False);
		CommonClientServer.SetDynamicListParameter(List,
		                                                                   "FullTextSearchSelection",
		                                                                   Undefined);
		SelectionBasis = "";
		
	EndIf;
	
	SearchForFragment(Notification);
EndProcedure

&AtClient
Procedure ExecuteSearchCompletion(Result, AdditionalParameters) Export
    
    Notification = AdditionalParameters.Notification;
    
    
    ThisForm.CurrentItem = ?(Not AdvancedSearch, Items.SearchString, Items.List);
    
    
    SearchForFragment(Notification);

EndProcedure

&AtClient
Procedure SearchForFragment(Val Notification)
    
    RunCallback(Notification);

EndProcedure

#EndRegion

#Region Filters

&AtClientAtServerNoContext
Procedure SetPartnerSelection(Form, IncludingDownstream = True)
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(Form.List, "Ref");
	If IncludingDownstream Then
		CommonClientServer.SetDynamicListFilterItem(Form.List, "Ref", Form.PartnerList, DataCompositionComparisonType.InList,,True);
	Else
		CommonClientServer.SetDynamicListFilterItem(Form.List, "Ref", Form.Partner, DataCompositionComparisonType.Equal,,True);
	EndIf;
	
EndProcedure 

#EndRegion

#Region Settings

&AtServer
Procedure ShouldSaveSettings()

	Var Settings;
	
	Settings = New Map;
	Settings.Insert("IncludingDownstream",IncludingDownstream);
	Settings.Insert("ByCounterparty",ByCounterparty);
	
	Common.CommonSettingsStorageSave("Catalogs.Partners",SettingsKey, Settings);
	
EndProcedure

&AtServer
Procedure LoadSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("Catalogs.Partners", SettingsKey);
	If TypeOf(SettingsValue) = Type("Map") Then
		IncludingDownstream = SettingsValue.Get("IncludingDownstream");
		ByCounterparty      = SettingsValue.Get("ByCounterparty");
	Else
		ByCounterparty      = True;
		IncludingDownstream = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure ProcessListRowActivation()
	
	If Not PartnersAndCounterpartiesClient.PositioningIsCorrect("List",ThisForm) Then
		
		If CurrentActivePartner <> PredefinedValue("Catalog.Partners.EmptyRef") Then
			FillInInformationPanelBasedOnPartnerData( Undefined);
		EndIf;
		SelectionBasis = "";
		
	Else
		
		If CurrentActivePartner <> Items.List.CurrentRow Or IgnoreTheCurrentPositionSaving Then
			FillInInformationPanelBasedOnPartnerData(Items.List.CurrentRow);
		EndIf;
		
		If AdvancedSearch Then
			PartnersAndCounterpartiesClient.FillInBaseLine(ThisForm);
		Else
			SelectionBasis = "";
		EndIf;
		
	EndIf;
	
	IgnoreTheCurrentPositionSaving = False;
	
EndProcedure

&AtServer
Procedure FillInInformationPanelBasedOnPartnerData(Partner)

	PartnersAndCounterparties.FillInInformationPanelBasedOnPartnerData(ThisForm, Partner);

EndProcedure

&AtClient
Procedure ProcessDynamicListRowActivation()

	ChangeFilterList();

EndProcedure

&AtServer
Procedure ChangeFilterList(ReshapingNavigationBar = False, PropertyPageNeedsFilling = False)

	PartnersAndCounterparties.ChangeFilterList(ThisForm, ReshapingNavigationBar, PropertyPageNeedsFilling);

EndProcedure

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

&AtClient
Procedure FillInTheHeadCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
