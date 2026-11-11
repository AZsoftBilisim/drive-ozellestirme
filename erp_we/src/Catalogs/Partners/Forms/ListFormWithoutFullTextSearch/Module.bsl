
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	PartnersAndCounterparties.PartnersFormForSelectingListWhenCreatingItOnServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the subsystem "External processing"
	
	// Electronic documents
	If AccessRight("Update", Metadata.Catalogs.Partners) Then
		Items.ListUploadBankDetails.Visible = True;
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.Partners);
	Items.ListChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	
	PartnersAndCounterparties.HideCommandsIfYouDonTHaveEditRights(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	SetVisibilityOfContextReportCommands();
	
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

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	PartnersAndCounterparties.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PartnersAndCounterpartiesClient.NavigationBarManageAccessibility(ThisForm);
	
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		PartnersAndCounterpartiesClient.FormOfSelectionListWhenClosing(ThisForm);
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
			FillParameters.Insert("Partner",    CurrentData.Ref);
			FillParameters.Insert("Counterparty", CurrentData.Counterparty);
			FillParameters.Insert("UsePartnersAsCounterparties", True);
			
			Notification = New CallbackDescription("FillInTheHeadCounterpartyCompletion", ThisObject);
			PartnersAndCounterpartiesClient.FillInTheHeadCounterparty(ThisObject, FillParameters, True, Notification);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("ProcessListRowActivation", 0.2, True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	PartnersAndCounterpartiesClient.PartnersSelectListFormListBeforeYouStartAdding(ThisForm, Item, Cancel, Copy, Parent, Var_Group);
	
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
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

&AtClient
Procedure UploadBankDetails(Command)
	
	Notification = New CallbackDescription("AfterQuestionAboutInstallingExtensionToWorkWithFiles", ThisObject);
	CommonClient.ShowFileSystemExtensionInstallationQuestion(Notification);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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
Procedure OpenReportPartnerPropertyFillingIn(Command)
	ReportParameters = New Structure("GenerateOnOpen", True);
	OpenForm("Report.PartnersPropertiesFilling.Form", ReportParameters, ThisForm);
EndProcedure

&AtClient
Procedure MarkSelectedOnesWithDuplicates(Command)
	SearchAndReplaceDuplicatesMasterDataClient.MarkSelectedOnesWithDuplicates(Items.List);
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
			NStr("vi = 'Chưa cập nhật chỉ mục tìm kiếm toàn văn. Cập nhật chỉ mục?';
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
				|ru = 'Идет обновление индекса полнотекстового поиска...';
				|en = 'Updating full-text search index...'; fa = 'Updating full-text search index...';
				|it = 'Aggiornamento dell''indice di ricerca full-text in corso ...';
				|pl = 'Trwa aktualizacja indeksu wyszukiwania pełnotekstowego...';
				|tr = 'Tam metin arama dizini güncelleniyor...'"));
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

&AtClient
Procedure ExecuteFullTextSearch()
	
	ErrorText = FindPartnersFullTextSearch();
	If ErrorText = Undefined Then
		AdvancedSearch = True;
		FillInBaseLine();
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
Procedure UpdateFullTextSearchIndexServer()
	
	PartnersAndCounterparties.UpdateFullTextSearchIndex();
	
EndProcedure

&AtClient
Procedure FillInBaseLine()
	
	Basis = Basis1.FindRows(New Structure("Partner", Items.List.CurrentRow));
	If Basis.Count() = 0 Then
		SelectionBasis = "";
	Else
		SelectionBasis = Basis[0].Basis;
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

&AtClient
Procedure ProcessListRowActivation()
	
	If Not PartnersAndCounterpartiesClient.PositioningIsCorrect("List",ThisForm) Then
		
		If CurrentActivePartner <> PredefinedValue("Catalog.Partners.EmptyRef") Then
			FillInInformationPanelBasedOnPartnerData(Undefined);
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

&AtServer 
Procedure SetVisibilityOfContextReportCommands()
	NumberOfAvailableReports = 0;
	
	If AccessRight("View", Metadata.Reports.PartnersPropertiesFilling) Then
		Items.OpenReportPartnerPropertyFillingIn.Visible = True;
		NumberOfAvailableReports = NumberOfAvailableReports + 1;
	Else
		Items.OpenReportPartnerPropertyFillingIn.Visible = False;
	EndIf;
	
	If NumberOfAvailableReports > 0 Then
		Items.PagesContextReports.CurrentPage = Items.PageAvailableReports;
	Else
		Items.PagesContextReports.CurrentPage = Items.PageNoAvailableReports;
	EndIf;
EndProcedure

&AtClient
Procedure FillInTheHeadCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionAboutInstallingExtensionToWorkWithFiles(Attached, AdditionalParameters) Export
	
	If Attached Then
		
		OpenFileDialog = New FileDialog(FileDialogMode.Open);
		OpenFileDialog.Filter = NStr("vi = 'Tập tin XML';
									|ru = 'XML файл';
									|en = 'XML file'; fa = 'XML file';
									|it = 'File XML';
									|pl = 'Plik XML';
									|tr = 'XML dosyası'")+"(*.xml)|*.xml";
		OpenFileDialog.Multiselect = False;
		OpenFileDialog.Title = NStr("vi = 'Hãy chọn tệp';
									|ru = 'Выберите файл';
									|en = 'Select file'; fa = 'انتخاب فایل';
									|it = 'Selezionare un file';
									|pl = 'Wybierz plik';
									|tr = 'Dosya seçin'");
		
		CallbackDescription = New CallbackDescription(
			"UploadDetailsFileSelection",
			ThisObject);
		
		OpenFileDialog.Show(CallbackDescription);
		
	Else
		
		#If WebClient Then
			
			FileAddressInTempStorage = "";
			FileName = "";
			BeginPutFile(
				New CallbackDescription(
					"ImportSchemaFromFileCompletion",
					ThisObject,
					New Structure("FileAddressInTempStorage", FileAddressInTempStorage)),
				FileAddressInTempStorage,
				FileName,
				True,
				UUID);
			
		#EndIf
			
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadDetailsFileSelection(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	ImportFile = SelectedFiles[0];
	
	Notification = New CallbackDescription("AfterCreatingBinaryDataFromFile", ThisObject);
	BeginCreateBinaryDataFromFile(Notification, ImportFile);
	
EndProcedure

&AtClient
Procedure AfterCreatingBinaryDataFromFile(BinaryData, AdditionalParameters) Export
	
	FileRef = PutToTempStorage(BinaryData);
	
	OpenForm("Catalog.Partners.Form.WizardOfNew",
		New Structure("FileRef, ListFilterByPartnerType", FileRef, ListFilterByPartnerType),
		,
		UUID);
	
EndProcedure

&AtClient
Procedure ImportSchemaFromFileCompletion(Result, Address, FileName, AdditionalParameters) Export
    
    FileAddressInTempStorage = AdditionalParameters.FileAddressInTempStorage;
    
    If Not Result Then
        Return;
    EndIf;
    
	OpenForm("Catalog.Partners.Form.WizardOfNew",
		New Structure("FileRef, ListFilterByPartnerType", FileAddressInTempStorage, ListFilterByPartnerType),
		,
		UUID);

EndProcedure

#EndRegion

#EndRegion
