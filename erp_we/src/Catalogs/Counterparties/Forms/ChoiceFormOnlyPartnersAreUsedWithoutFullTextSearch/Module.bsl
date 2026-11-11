
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	PartnersAndCounterpartiesLocalization.SetPropertiesOfDynamicListOfContractorsSelectionForm(ThisForm);
	PartnersAndCounterparties.PartnersFormForSelectingListWhenCreatingItOnServer(ThisForm, Cancel, StandardProcessing);
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(Parameters, "Filter")
			And CommonClientServer.HasAttributeOrObjectProperty(Parameters.Filter, "Partner")
			And ValueIsFilled(Parameters.Filter.Partner) Then
			
			Partner = Parameters.Filter.Partner;
			PartnersAndCounterparties.FillInPartnerListWithAllHierarchy(Partner, PartnerList);
			
			If PartnerList.Count() > 1 Then
				OnlyParentCounterpartyAndBranches = True;
				Parameters.Filter.Delete("Partner");
				CommonClientServer.SetDynamicListFilterItem(
					List, "ParameterizationOfThePartner", PartnerList, DataCompositionComparisonType.InList);
				Items.OnlyParentCounterpartyAndBranches.Visible = True;
			Else
				Parameters.Filter.Delete("Partner");
				Partner = Catalogs.Partners.EmptyRef();
			EndIf;
		EndIf;
			
	ElsIf CommonClientServer.HasAttributeOrObjectProperty(Parameters, "Filter")
		And CommonClientServer.HasAttributeOrObjectProperty(Parameters.Filter, "Partner")
		And ValueIsFilled(Parameters.Filter.Partner) Then
		
		Partner = Parameters.Filter.Partner;
		ByPartner = True;
		Parameters.Filter.Delete("Partner");
		
		PartnersAndCounterparties.FillInPartnerListWithAllHierarchy(Partner, PartnerList);
		
		CommonClientServer.SetDynamicListFilterItem(List, "ParameterizationOfThePartner", PartnerList, DataCompositionComparisonType.InList);
		
	Else
		
		Partner = Catalogs.Partners.EmptyRef();
	
	EndIf;
	
	If Parameters.Property("Basis") Then
		Basis = Parameters.Basis;
	EndIf;
	
	PartnersAndCounterpartiesLocalization.WhenCreatingCounterpartySelectionFormOnServer(ThisForm, Cancel, StandardProcessing);
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	PartnersAndCounterparties.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PartnersAndCounterpartiesClient.NavigationBarManageAccessibility(ThisForm);
	
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
Procedure ContactPersonsOfPartnerClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	PartnersAndCounterpartiesClient.ContactPersonsOfPartnerClick(ThisForm);
	
EndProcedure 

&AtClient
Procedure ForAllWhenChanging(Item)
	
	ChangeFilterList(True);
	
EndProcedure

&AtClient
Procedure OnlyParentCounterpartyAndBranchesOnChange(Item)
	
	If OnlyParentCounterpartyAndBranches Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "ParameterizationOfThePartner", PartnerList, DataCompositionComparisonType.InList,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			List, "ParameterizationOfThePartner", PartnerList, DataCompositionComparisonType.InList,, False);
	EndIf;
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.MainCounterparty Then
		
		CurrentData = Item.CurrentData;
		If CurrentData.BranchOffice And Not ValueIsFilled(CurrentData.MainCounterparty) Then
			
			StandardProcessing = False;
			
			FillParameters = New Structure;
			PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(FillParameters, CurrentData);
			FillParameters.Insert("Counterparty", CurrentData["Ref"]);
			FillParameters.Insert("Partner",    CurrentData.Partner);
			FillParameters.Insert("UsePartnersAsCounterparties", True);

			Notification = New CallbackDescription("FillInTheHeadCounterpartyCompletion", ThisObject);
			PartnersAndCounterpartiesClient.FillInTheHeadCounterparty(ThisObject, FillParameters, True, Notification);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("ProcessListRowActivation",0.2,True);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	PartnersAndCounterpartiesClient.PartnersSelectListFormListBeforeYouStartAdding(ThisObject, Item, Cancel, Copy, Parent, Var_Group, Basis);
	
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

#EndRegion

#Region Private

#Region FullTextSearch

&AtClient
Procedure CheckFullTextSearchIndex(Val Notification)
	
	If Not FullTextSearchIndexIsUpToDate And FileInfobase Then
		
		ShowQueryBox(New CallbackDescription("CheckFullTextSearchIndexCompletion", ThisObject, 
			New Structure("Notification", Notification)), NStr("vi = 'Chưa kích hoạt chỉ mục tìm kiếm toàn văn.  Cập nhật chỉ mục?';
																|ru = 'Индекс полнотекстового поиска неактуален. Обновить индекс?';
																|en = 'Full-text search index is invalid. Update the index?'; fa = 'Full-text search index is invalid. Update the index?';
																|it = 'L''indice di ricerca full-text è irrilevante. Aggiornare l''indice?';
																|pl = 'Indeks wyszukiwania pełnotekstowego jest nieaktualny. Zaktualizować indeks?';
																|tr = 'Tam metin arama endeksi güncel değil. Endeksi güncelle?'"), 
			QuestionDialogMode.YesNo);
			
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
								|tr = 'Bulunamadı'") Then
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

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	PartnersAndCounterparties.PartnersListSelectionFormConditionalAppearance(ThisForm);
	PartnersAndCounterparties.SetRegistrationOfHeadCounterpartyInList(ThisForm);

	
EndProcedure

&AtClient
Procedure ProcessListRowActivation()
	
	If Not PartnersAndCounterpartiesClient.PositioningIsCorrect("List" ,ThisForm) Then
		
		If CurrentActivePartner <> PredefinedValue("Catalog.Counterparties.EmptyRef") Then
			FillInInformationPanelBasedOnPartnerData(Undefined);
		EndIf;
		SelectionBasis = "";
		
	Else
		
		CurrentData = Items.List.CurrentData;
		If CurrentData = Undefined Then
			FillInInformationPanelBasedOnPartnerData(Undefined);
			Return;
		EndIf;
		
		If CurrentActivePartner <> CurrentData.Partner Or IgnoreTheCurrentPositionSaving Then
			FillInInformationPanelBasedOnPartnerData(CurrentData.Partner);
		EndIf;
		
		If AdvancedSearch Then
			PartnersAndCounterpartiesClient.FillInBaseLine(ThisForm);
		Else
			SelectionBasis = "";
		EndIf;
		
		IgnoreTheCurrentPositionSaving = False;
		
	EndIf;
	
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

&AtClient
Procedure FillInTheHeadCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
