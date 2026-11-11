
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CreationOfReconciliationSettlementsIsAvailable2_5_11 = AccessRight("Insert", Metadata.Documents.ARAPReconciliation2_5_11);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
	LayoutParameter = List.Parameters.FindParameterValue(New DataCompositionParameter("ProhibitedPaymentTypes"));
	If LayoutParameter <> Undefined Then
		LayoutParameter.Use = True;
		LayoutParameter.Value.LoadValues(Documents.ARAPReconciliation2_5_11.ProhibitedPaymentTypes());
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	SetVisibilityOfElementsOnServer();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	

	If EventName = "ReconciliationCreatedByAssistant2_5_11" Then
		Items.List.Refresh();
	EndIf;

EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Manager			= Settings.Get("Manager");
	Status				= Settings.Get("Status");
	StateOfEdoSelection	= Settings.Get("StateOfEdoSelection");
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Status));
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EDIState",
		StateOfEdoSelection,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(StateOfEdoSelection));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusFilterOnChange(Item)
	
	TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
	RightValue = Undefined;
	
	If Status = "CreatedOn_" Then
		TypeOfSelectionComparison = DataCompositionComparisonType.InList;
		RightValue = New Array;
		RightValue.Add(PredefinedValue("Enum.StatusesOfARAPReconciliation.CreatedOn_"));
		RightValue.Add(PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.CreatedOn_"));
	ElsIf Status = "OnReconciliation" Then 
		TypeOfSelectionComparison = DataCompositionComparisonType.InList;
		RightValue = New Array;
		RightValue.Add(PredefinedValue("Enum.StatusesOfARAPReconciliation.OnReconciliation"));
		RightValue.Add(PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.OnReconciliation"));
	ElsIf Status = "Reconciled" Then
		RightValue = PredefinedValue("Enum.StatusesOfARAPReconciliation.Reconciled");
	ElsIf Status = "ReconciledWithoutDisputes" Then
		RightValue = PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.ReconciledWithoutDisputes");
	ElsIf Status = "ReconciledWithDisputes" Then
		RightValue = PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.ReconciledWithDisputes");
	ElsIf Status = "IsRejected" Then
		RightValue = PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.IsRejected");
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", RightValue, TypeOfSelectionComparison,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure ManagerSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure EDIStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EDIState",
		StateOfEdoSelection,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(StateOfEdoSelection));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Not CreationOfReconciliationSettlementsIsAvailable2_5_11 Then
		Return;
	EndIf;
	
	If Copy Then
		If TypeOf(Items.List.CurrentData.Ref) = Type("DocumentRef.ARAPReconciliation2_4") Then
			StructureFilter = New Structure("Organization,Counterparty,ContactPerson,BeginOfPeriod,EndOfPeriod");
			CurrentRow = Items.List.CurrentData;
			If CurrentRow <> Undefined Then
				FillPropertyValues(StructureFilter,CurrentRow);
			EndIf;
			ParametersStructure1 = New Structure("FillingValues", StructureFilter);
			OpenForm("Document.ARAPReconciliation2_5_11.ObjectForm", ParametersStructure1, Items.List);
		Else
			TMCommonUseClient.CopyItem(Item);
		EndIf;
	Else
		OpenForm("Document.ARAPReconciliation2_5_11.ObjectForm",,Items.List);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreationAssistant(Command)
	
	OpenForm("Document.ARAPReconciliation2_5_11.Form.FormOfReconciliationWizard");
	
EndProcedure

&AtClient
Procedure SetTheStatusCreated(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("Status_Name", "CreatedOn_");
	AdditionalParameters.Insert("StatusSynonym", NStr("vi = 'Đã tạo';
														|ru = 'Создана';
														|en = 'Created'; fa = 'ایجادشده';
														|it = 'Создана';
														|pl = 'Created';
														|tr = 'Oluşturuldu'"));
	
	ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters),
		NStr("vi = 'Trong các chứng từ được chọn trong danh sách sẽ đặt trạng thái ""Đã tạo"". Tiếp tục?';
			|ru = 'У выделенных в списке документов будет установлен статус ""Создана"". Продолжить?';
			|en = 'Status of the documents selected in the list will be set to Created. Continue?'; fa = 'Status of the documents selected in the list will be set to Created. Continue?';
			|it = 'Per i documenti selezionati nell''elenco verrà impostato lo stato ""Creato"". Continuare?';
			|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Utworzona"". Kontynuować?';
			|tr = 'Listedeki seçili belgelerin durumu ""Oluşturuldu"" olarak ayarlanacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusOnReconciliation(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("Status_Name", "OnReconciliation");
	AdditionalParameters.Insert("StatusSynonym", NStr("vi = 'Đang đối chiếu';
														|ru = 'На сверке';
														|en = 'In reconciliation'; fa = 'در حال تطبیق';
														|it = 'In verifica';
														|pl = 'Na weryfikacji';
														|tr = 'Mutabakatta'"));	
	
	ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters),
		NStr("vi = 'Trong các chứng từ được chọn trong danh sách sẽ đặt trạng thái ""Đang đối chiếu"". Tiếp tục?';
			|ru = 'У выделенных в списке документов будет установлен статус ""На сверке"". Продолжить?';
			|en = 'Status of the documents selected in the list will be set to ""In reconciliation"". Continue?'; fa = 'Status of the documents selected in the list will be set to ""In reconciliation"". Continue?';
			|it = 'Per i documenti selezionati nell''elenco verrà impostato lo stato ""In verifica"". Continuare?';
			|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Na weryfikacji"". Kontynuować?';
			|tr = 'Listedeki seçili belgelerin durumu ""Mutabakatta"" olarak ayarlanacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheVerifiedStatus(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	TypesToExclude = New Array;
	TypesToExclude.Add(Type("DocumentRef.ARAPReconciliation2_5_11"));
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("TypesToExclude", TypesToExclude);
	AdditionalParameters.Insert("Status_Name", "Reconciled");
	AdditionalParameters.Insert("StatusSynonym", NStr("vi = 'Đã đối chiếu';
														|ru = 'Сверена';
														|en = 'Reconciled'; fa = 'تطبیق‌شده';
														|it = 'Сверена';
														|pl = 'Reconciled';
														|tr = 'Uzlaşıldı'"));
	
	ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters),
		NStr("vi = 'Trong các giấy ủy quyền mà được tách ra trong danh sách sẽ đặt trạng thái ""Đã kiểm tra"". Tiếp tục?';
			|ru = 'У выделенных в списке документов будет установлен статус ""Сверена"". Продолжить?';
			|en = 'Status of the documents selected in the list will be set to Reconciled. Continue?'; fa = 'Status of the documents selected in the list will be set to Reconciled. Continue?';
			|it = 'Per i documenti selezionati nell''elenco verrà impostato lo stato ""Verificato"". Continuare?';
			|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Zweryfikowane"". Kontynuować?';
			|tr = 'Listedeki seçili belgelerin durumu ""Uzlaşıldı"" olarak ayarlanacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusVerifiedWithoutDiscrepancies(Command)

	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	TypesToExclude = New Array;
	TypesToExclude.Add(Type("DocumentRef.ARAPReconciliation2_4"));
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("TypesToExclude", TypesToExclude);
	AdditionalParameters.Insert("Status_Name", "ReconciledWithoutDisputes");
	AdditionalParameters.Insert("StatusSynonym", NStr("vi = 'Đã đối chiếu và không có chênh lệch';
														|ru = 'Сверена без разногласий';
														|en = 'Reconciled without discrepancies'; fa = 'تطبیق‌شده بدون مغایرت';
														|it = 'Сверена без разногласий';
														|pl = 'Reconciled without discrepancies';
														|tr = 'Tartışmasız uzlaşıldı'"));
	
	ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters),
		NStr("vi = 'Trong các chứng từ được tách ra trong danh sách sẽ đặt trạng thái ""Đã đối chiếu và không có chênh lệch"". Tiếp tục?';
			|ru = 'У выделенных в списке документов будет установлен статус ""Сверена без разногласий"". Продолжить?';
			|en = 'The status of the documents selected in the list will be set to ""Reconciled without discrepancies"". Continue?'; fa = 'The status of the documents selected in the list will be set to ""Reconciled without discrepancies"". Continue?';
			|it = 'У выделенных в списке документов будет установлен статус ""Сверена без разногласий"". Продолжить?';
			|pl = 'The status of the documents selected in the list will be set to ""Reconciled without discrepancies"". Continue?';
			|tr = 'Listedeki seçili belgelerin durumu ""Tartışmasız uzlaşıldı"" olarak ayarlanacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure SetStatusCheckedAgainstDiscrepancies(Command)

	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	TypesToExclude = New Array;
	TypesToExclude.Add(Type("DocumentRef.ARAPReconciliation2_4"));
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("TypesToExclude", TypesToExclude);
	AdditionalParameters.Insert("Status_Name", "ReconciledWithDisputes");
	AdditionalParameters.Insert("StatusSynonym", NStr("vi = 'Đã đối chiếu và có chênh lệch';
														|ru = 'Сверена с разногласиями';
														|en = 'Reconciled with discrepancies'; fa = 'تطبیق‌شده با مغایرت';
														|it = 'Сверена с разногласиями';
														|pl = 'Reconciled with discrepancies';
														|tr = 'Tartışmalarla uzlaşıldı'"));

	ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters),
		NStr("vi = 'Trong các chứng từ được tách ra trong danh sách sẽ đặt trạng thái ""Đã đối chiếu và có chênh lệch"". Tiếp tục?';
			|ru = 'У выделенных в списке документов будет установлен статус ""Сверена с разногласиями"". Продолжить?';
			|en = 'The status of the documents selected in the list will be set to ""Reconciled with discrepancies"". Continue?'; fa = 'The status of the documents selected in the list will be set to ""Reconciled with discrepancies"". Continue?';
			|it = 'У выделенных в списке документов будет установлен статус ""Сверена с разногласиями"". Продолжить?';
			|pl = 'The status of the documents selected in the list will be set to ""Reconciled with discrepancies"". Continue?';
			|tr = 'Listedeki seçili belgelerin durumu ""Tartışmalarla uzlaşıldı"" olarak ayarlanacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure ToSetTheStatusToRejected(Command)

	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	TypesToExclude = New Array;
	TypesToExclude.Add(Type("DocumentRef.ARAPReconciliation2_4"));
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("TypesToExclude", TypesToExclude);
	AdditionalParameters.Insert("Status_Name", "IsRejected");
	AdditionalParameters.Insert("StatusSynonym", NStr("vi = 'Đã hủy';
														|ru = 'Отклонена';
														|en = 'Rejected'; fa = 'ردشده';
														|it = 'Отклонена';
														|pl = 'Rejected';
														|tr = 'Reddedildi'"));

	ShowQueryBox(New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters),
		NStr("vi = 'Sẽ đặt trạng thái ""Đã hủy"" đối với các chứng từ được chọn trong danh sách. Tiếp tục?';
			|ru = 'У выделенных в списке документов будет установлен статус ""Отклонена"". Продолжить?';
			|en = 'The documents selected in the list will have the ""Rejected"" status. Continue?'; fa = 'The documents selected in the list will have the ""Rejected"" status. Continue?';
			|it = 'У выделенных в списке документов будет установлен статус ""Отклонена"". Продолжить?';
			|pl = 'The documents selected in the list will have the ""Rejected"" status. Continue?';
			|tr = 'Talep listesinde seçilenlerin durumu ""Reddedildi"" olarak ayarlanacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure


#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function GetLinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ARAPReconciliation2_4.EmptyRef"));
	Managers.Add(PredefinedValue("Document.ARAPReconciliation2_5_11.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = GetLinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);

EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export

	ExecuteCommandAtServer(ExecutionParameters);

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)

	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);

EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()

	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);

EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure SetVisibilityOfElementsOnServer()
	
	Items.Partner.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	Items.GroupCreate.Visible = False;
	Items.ListCreationAssistant.Visible = CreationOfReconciliationSettlementsIsAvailable2_5_11;
	
	
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	Items.EDOSubmenu.Visible = Not ThisIsBasic;
	Items.StatusPresentation.Visible = Not ThisIsBasic;
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(QuestionResult, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	Status_Name = AdditionalParameters.Status_Name;
	StatusSynonym = AdditionalParameters.StatusSynonym;

	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	ClearMessages();
	CheckingBeforeChangingStatus(AdditionalParameters);
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, Status_Name, AdditionalParameters);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), StatusSynonym);

EndProcedure

&AtClient
Procedure CheckingBeforeChangingStatus(AdditionalParameters)
	
	If AdditionalParameters.Property("TypesToExclude") = False Then
		Return;
	EndIf;
	
	SelectedRows = AdditionalParameters.SelectedRows;
	StatusSynonym = AdditionalParameters.StatusSynonym;          
	TypesToExclude = AdditionalParameters.TypesToExclude;
	
	For Each Ref In SelectedRows Do
		If TypesToExclude.Find(TypeOf(Ref)) <> Undefined Then     
			ErrorText = NStr("vi = 'Thiết lập trạng thái ""%Status%"" không xem xét đối với chứng từ %Document%';
							|ru = 'Установка статуса ""%Status%"" не предусмотрена для документа %Document%';
							|en = 'You cannot set the ""%Status%"" status for the %Document% document'; fa = 'You cannot set the ""%Status%"" status for the %Document% document';
							|it = 'Установка статуса ""%Status%"" не предусмотрена для документа %Document%';
							|pl = 'You cannot set the ""%Status%"" status for the %Document% document';
							|tr = '""%Document%"" belgesi için  ""%Status%"" durumunun ayarlanmamıştır'");
			ErrorText = StrReplace(ErrorText, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", StatusSynonym);
			CommonClient.MessageToUser(ErrorText, Ref);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
