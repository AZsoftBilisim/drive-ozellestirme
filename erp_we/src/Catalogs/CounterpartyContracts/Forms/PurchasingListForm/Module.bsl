
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UsePartnersAsCounterparties = (GetFunctionalOption("UsePartnersAsCounterparties"));
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterValidityPeriod.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Counterparty", Counterparty, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure);
	
	If Parameters.Property("Partner") 
		Or (UsePartnersAsCounterparties 
		And Parameters.Property("Filter") And Parameters.Filter.Property("Counterparty")) Then
		
		If Parameters.Property("Partner") Then
			Partner = Parameters.Partner;
		Else
			Partner = Common.ObjectAttributeValue(Parameters.Filter.Counterparty, "Partner");
		EndIf;
		
		SetPartnerSelection_();
		
	Else
		
		List.Parameters.SetParameterValue("DefaultPartner", Catalogs.Partners.EmptyRef());
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"DefaultBusinessTransaction", 
		Enums.BusinessTransactions.PurchaseFromSupplier, 
		DataCompositionComparisonType.Equal,
		, 
		True);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject, Items.List, Items.ListARAPCurrency);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(
		ThisObject,
		Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.List);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure


&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Manager", Manager, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Counterparty", Counterparty, QuickFilterStructure, Settings);
	If UsePartnersAsCounterparties And ValueIsFilled(Counterparty) Then
		SetSelectionByPartnerCounterparty();
	EndIf;
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure, Settings);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(State, QuickFilterStructure, Settings) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodOnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterValidityPeriod.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodClearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterValidityPeriod",
		"EventDate");
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Organization", 
		Organization, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Counterparty", 
		Counterparty, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Counterparty));
	
	If UsePartnersAsCounterparties Then
		SetSelectionByPartnerCounterparty();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Manager", 
		Manager, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing) 
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name, ThisObject, Items.List, StandardProcessing);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If Field = Items.StatusPresentation Then
	EndIf;

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows); 
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusNotAgreed_5(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở các hợp đồng đã chọn, trong danh sách sẽ đặt trạng thái ""Không thống nhất"". Theo hợp đồng hiện hành có thể lập chứng từ. Sau khi thay đổi trạng thái hợp đồng hiện hành sẽ mất hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке договоров будет установлен статус ""Не согласован"". По действующим договорам могут быть оформлены документы. После изменения статуса действующие договоры перестанут действовать. Продолжить?';
					|en = 'Status of the contracts selected in the list will be set to ""Not approved"". Documents can be generated based on the contracts. Once the status is changed, the contracts will be no longer valid. Continue?'; fa = 'Status of the contracts selected in the list will be set to ""Not approved"". Documents can be generated based on the contracts. Once the status is changed, the contracts will be no longer valid. Continue?';
					|it = 'Agli accordi selezionati dall''elenco viene assegnato lo stato ""Non concordato"". Sarà possibile realizzare documenti per gli accordi attivi. Dopo la modifica dello stato gli accordi attivi non saranno più in vigore. Procedere?';
					|pl = 'Dla umów zaznaczonych na liście zostanie ustawiony status ""Nieuzgodniona"". Dla aktualnych umów mogą być sporządzone dokumenty. Po zmianie statusu aktualne umowy utracą ważność. Kontynuować?';
					|tr = 'Listede seçili sözleşmelerin durumu ""Beklemede"" olarak ayarlanacaktır. Mevcut sözleşmeler için belge düzenlenebilir. Durum değiştirildikten sonra, mevcut sözleşmelerin geçerliliği sona erecektir. Devam edilsin mi?'");
	
	Response = Undefined;

	
	ShowQueryBox(New CallbackDescription("SetTheStatusNotAgreed_5Completion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreed_5Completion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = SetStatusServer(SelectedRows, "NotApproved");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Không thống nhất';
																												|ru = 'Не согласован';
																												|en = 'Not approved'; fa = 'تأییدنشده';
																												|it = 'Non concordato';
																												|pl = 'Nieuzgodniony';
																												|tr = 'Beklemede'"));

EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở các hợp đồng đã chọn, trong danh sách cần đặt trạng thái ""Có hiệu lực"". Tiếp tục?';
					|ru = 'У выделенных в списке договоров будет установлен статус ""Действует"". Продолжить?';
					|en = 'Status of the contracts selected in the list will be set to ""Valid"". Continue?'; fa = 'Status of the contracts selected in the list will be set to ""Valid"". Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Attivo"". Procedere?';
					|pl = 'Dla umów zaznaczonych na liście zostanie ustawiony status ""Aktualna"". Kontynuować?';
					|tr = 'Listede seçili sözleşmelerin durumu ""Aktif"" olarak ayarlanacaktır. Devam edilsin mi?'");
	
	Response = Undefined;

	
	ShowQueryBox(New CallbackDescription("SetStatusValidCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusValidCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = SetStatusServer(SelectedRows, "Valid");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Có hiệu lực';
																												|ru = 'Действует';
																												|en = 'Valid'; fa = 'معتبر';
																												|it = 'In vigore';
																												|pl = 'Valid';
																												|tr = 'Aktif'"));

EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở các hợp đồng đã chọn, trong danh sách sẽ đặt trạng thái ""Đã đóng"". Sau khi thay đổi trạng thái hợp đồng hiện hành sẽ mất hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке договоров будет установлен статус ""Закрыт"". После изменения статуса действующие договоры перестанут действовать. Продолжить?';
					|en = 'Status of the contracts selected in the list will be set to ""Closed"". Once the status is changed, the contracts will be no longer valid. Continue?'; fa = 'Status of the contracts selected in the list will be set to ""Closed"". Once the status is changed, the contracts will be no longer valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Chiuso"". Dopo la modifica dello stato gli accordi attivi non saranno più in vigore. Procedere?';
					|pl = 'Dla umów zaznaczonych na liście zostanie ustawiony status ""Zamknięta"". Po zmianie statusu aktualne umowy utracą ważność. Kontynuować?';
					|tr = 'Listede seçili sözleşmelerin durumu ""Kapalı"" olarak ayarlanacaktır. Durum değiştirildikten sonra, mevcut sözleşmelerin geçerliliği sona erecektir. Devam edilsin mi?'");
	
	Response = Undefined;

	
	ShowQueryBox(New CallbackDescription("SetTheClosedStatusCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheClosedStatusCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = SetStatusServer(SelectedRows, "Closed");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã đóng';
																												|ru = 'Закрыт';
																												|en = 'Closed'; fa = 'بسته‌شده';
																												|it = 'Chiuso';
																												|pl = 'Closed';
																												|tr = 'Kapalı'"));

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
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

// End MenuReports


// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
    
    UpdateOriginalStateCommands();
   
EndProcedure
&AtServer
Procedure UpdateOriginalStateCommands()
    
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
    
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

#EndRegion

#Region Private

#Region Other

&AtServerNoContext
Function SetStatusServer(Val Contracts, NewStatus)
	
	Return Catalogs.CounterpartyContracts.SetStatus(Contracts, Enums.CounterpartyContractStatuses[NewStatus]);
	
EndFunction

&AtServer
Procedure SetSelectionByPartnerCounterparty()

	Partner = Common.ObjectAttributeValue(Counterparty, "Partner");
	SetPartnerSelection_();

EndProcedure

&AtServer
Procedure SetPartnerSelection_()
	
	List.Parameters.SetParameterValue("DefaultPartner", Partner);
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"DefaultPartner", 
		Partner, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Partner));
		
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);

	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Partner", 
		PartnerList, 
		DataCompositionComparisonType.InList,
		, 
		ValueIsFilled(Partner));
	
EndProcedure

#EndRegion

#EndRegion
