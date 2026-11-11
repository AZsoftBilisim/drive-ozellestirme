
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterValidityPeriod.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "CompanyRecipient", CompanyRecipient, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	If Parameters.Property("VATRate") Then
		CommonClientServer.SetDynamicListFilterItem(
												List, "VATRate", Parameters.VATRate);
	EndIf;
	
	If Parameters.Property("Status") Then
		If Parameters.Property("TypeOfStatusComparison") Then
			CommonClientServer.SetDynamicListFilterItem(
													List, "State", Parameters.Status, Parameters.TypeOfStatusComparison);
		Else
			CommonClientServer.SetDynamicListFilterItem(
													List, "State", Parameters.Status);
		EndIf;
	EndIf;
	
	If Parameters.Property("ValidityEndDate") Then
		If Parameters.Property("TypeOfDateComparison") Then
			CommonClientServer.SetDynamicListFilterItem(
													List, "ValidityEndDate", Parameters.ValidityEndDate, Parameters.TypeOfDateComparison);
		Else
			CommonClientServer.SetDynamicListFilterItem(
													List, "ValidityEndDate", Parameters.ValidityEndDate);
		EndIf;
	EndIf;
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "CompanyRecipient", CompanyRecipient, QuickFilterStructure, Settings);
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
Procedure CompanyRecipientOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"CompanyRecipient", 
		CompanyRecipient, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(CompanyRecipient));

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusNotAgreed_5(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	NotificationParameters	= New Structure("SelectedRows", SelectedRows);
	CallbackDescription	= New CallbackDescription("SetTheStatusNotAgreed_5Completion",
													ThisObject,
													NotificationParameters);
	
	QueryText = NStr("vi = 'Ở các hợp đồng đã chọn trong danh sách sẽ đặt trạng thái ""Không thống nhất"". Theo hợp đồng hiện hành có thể lập chứng từ. Sau khi thay đổi trạng thái hợp đồng hiện hành sẽ mất hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке договоров будет установлен статус ""Не согласован"". По действующим договорам могут быть оформлены документы. После изменения статуса действующие договоры перестанут действовать. Продолжить?';
					|en = 'Status of the contracts selected in the list will be set to Not approved. Documents can be generated based on the contracts. Once the status is changed, the contracts will be no longer valid. Continue?'; fa = 'Status of the contracts selected in the list will be set to Not approved. Documents can be generated based on the contracts. Once the status is changed, the contracts will be no longer valid. Continue?';
					|it = 'Agli accordi selezionati dall''elenco viene assegnato lo stato ""Non concordato"". Sarà possibile realizzare documenti per gli accordi attivi. Dopo la modifica dello stato gli accordi attivi non saranno più in vigore. Procedere?';
					|pl = 'Dla umów zaznaczonych na liście zostanie ustawiony status ""Nieuzgodniona"". Dla aktualnych umów mogą być sporządzone dokumenty. Po zmianie statusu aktualne umowy utracą ważność. Kontynuować?';
					|tr = 'Listede seçili sözleşmelerin durumu ""Beklemede"" olarak ayarlanacaktır. Mevcut sözleşmeler için belge düzenlenebilir. Durum değiştirildikten sonra, mevcut sözleşmelerin geçerliliği sona erecektir. Devam edilsin mi?'");
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreed_5Completion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetStatusServer(SelectedRows, "NotApproved");
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List,
																		ProcessedItemsCount,
																		SelectedRows.Count(),
																		NStr("vi = 'Không thống nhất';
																			|ru = 'Не согласован';
																			|en = 'Not approved'; fa = 'تأییدنشده';
																			|it = 'Non concordato';
																			|pl = 'Nieuzgodniony';
																			|tr = 'Onaylanmadı'"));
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	NotificationParameters	= New Structure("SelectedRows", SelectedRows);
	CallbackDescription	= New CallbackDescription("SetStatusValidCompletion",
													ThisObject,
													NotificationParameters);
	
	QueryText = NStr("vi = 'Ở các hợp đồng đã chọn, trong danh sách cần đặt trạng thái ""Có hiệu lực"". Tiếp tục?';
					|ru = 'У выделенных в списке договоров будет установлен статус ""Действует"". Продолжить?';
					|en = 'Status of the contracts selected in the list will be set to Valid. Continue?'; fa = 'Status of the contracts selected in the list will be set to Valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Attivo"". Procedere?';
					|pl = 'Dla umów zaznaczonych na liście zostanie ustawiony status ""Aktualna"". Kontynuować?';
					|tr = 'Listede seçili sözleşmelerin durumu ""Aktif"" olarak ayarlanacaktır. Devam edilsin mi?'");
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusValidCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetStatusServer(SelectedRows, "Valid");
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List,
																		ProcessedItemsCount,
																		SelectedRows.Count(),
																		NStr("vi = 'Có hiệu lực';
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
	
	NotificationParameters	= New Structure("SelectedRows", SelectedRows);
	CallbackDescription	= New CallbackDescription("SetTheClosedStatusCompletion",
													ThisObject,
													NotificationParameters);
	
	QueryText = NStr("vi = 'Ở các hợp đồng đã chọn, trong danh sách sẽ đặt trạng thái ""Đã đóng"". Sau khi thay đổi trạng thái hợp đồng hiện hành sẽ mất hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке договоров будет установлен статус ""Закрыт"". После изменения статуса действующие договоры перестанут действовать. Продолжить?';
					|en = 'Status of the contracts selected in the list will be set to Closed. Once the status is changed, the contracts will be no longer valid. Continue?'; fa = 'Status of the contracts selected in the list will be set to Closed. Once the status is changed, the contracts will be no longer valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Chiuso"". Dopo la modifica dello stato gli accordi attivi non saranno più in vigore. Procedere?';
					|pl = 'Dla umów zaznaczonych na liście zostanie ustawiony status ""Zamknięta"". Po zmianie statusu aktualne umowy utracą ważność. Kontynuować?';
					|tr = 'Listede seçili sözleşmelerin durumu ""Kapalı"" olarak ayarlanacaktır. Durum değiştirildikten sonra, mevcut sözleşmelerin geçerliliği sona erecektir. Devam edilsin mi?'");
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheClosedStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetStatusServer(SelectedRows, "Closed");
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List,
																		ProcessedItemsCount,
																		SelectedRows.Count(),
																		NStr("vi = 'Đã đóng';
																			|ru = 'Закрыт';
																			|en = 'Closed'; fa = 'بسته‌شده';
																			|it = 'Chiuso';
																			|pl = 'Closed';
																			|tr = 'Kapalı'"));
	
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

#EndRegion

#Region Private

#Region Other

&AtServerNoContext
Function SetStatusServer(Val Contracts, NewStatus)
	
	Return Catalogs.IntercompanyContracts.SetStatus(Contracts,
																	Enums.CounterpartyContractStatuses[NewStatus]);
	
EndFunction

#EndRegion

#EndRegion
