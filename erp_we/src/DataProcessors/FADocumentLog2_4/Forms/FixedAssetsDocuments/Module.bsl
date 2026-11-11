#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	ListOfDocumentsAutoUpdateMode = True;
	ListOfDocumentsDepreciationAutoUpdateMode = True;
	// End DynamicListsSettings
	
	SetTextOfDynamicListQueries();
	
	List.Parameters.SetParameterValue("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ListDetailed.Parameters.SetParameterValue("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	
	List.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
	ListDetailed.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	NonCurrentAssetsLocalization.FillInCorrespondenceOfFALogDocuments(DocumentCorrespondence);
	
	If Not Parameters.Property("FormAssignmentKey")
		Or IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DataProcessors.FADocumentLog2_4.DefaultFormAssignmentKey();
		SettingsKey = "";
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
		SettingsKey = Parameters.FormAssignmentKey;
	EndIf;
	
	If Parameters.Property("ListFormSelections") Then
		
		FormsOpenedByHyperlink = True;
		FilterDocumentTypes = Parameters.ListFormSelections.FilterDocumentTypes;
		FilterBusinessTransactions = Parameters.ListFormSelections.FilterBusinessTransactions;
		
		If SettingsKey = "TransitionAssistant" Then
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"CreatedToUpgradeToVersion24",
				1,
				DataCompositionComparisonType.Equal,,
				True);
				
			CommonClientServer.SetDynamicListFilterItem(
				ListDetailed,
				"CreatedToUpgradeToVersion24",
				1,
				DataCompositionComparisonType.Equal,,
				True);
				
			AutoTitle = False;
			Title = NStr("vi = 'Chứng từ TSCĐ được tạo để chuyển sang kế toán cho tài sản dài hạn phiên bản 2.4';
						|ru = 'Документы по ОС, созданные для перехода на учет внеоборотных активов версии 2.4';
						|en = 'Fixed assets documents created for migration to fixed asset accounting 2.4'; fa = 'Fixed assets documents created for migration to fixed asset accounting 2.4';
						|it = 'Documento del capitale fisso creato per il passaggio alla contabilità per le attività non correnti della versione 2.4';
						|pl = 'Dokumenty po ŚT utworzone w celu przejścia na ewidencję trwałych aktywów wersji 2.4';
						|tr = 'Duran varlıkların muhasebesine geçiş için oluşturulan sabit kıymet belgeleri sürüm 2.4'");
			
			Items.TheSelectionOfTheOrganizationDepreciation.Visible = False;
			Items.TheSelectionOfTheAssetTheDepreciation.Visible = False;
			Items.ListDepreciation.Visible = False;
			Items.GroupCustomSettingsListDepreciation.Visible = False;
			Items.ToRegister.Visible = False;
			
		EndIf; 
		
	ElsIf Parameters.Property("Asset") Then
		
		Items.Pages.CurrentPage = Items.DocumentsDetailsPage;

		FormsOpenedByHyperlink = True;
		
		FilterFixedAsset = Parameters.Asset;

		OSType = Enums.FATypes.Asset;
		If ValueIsFilled(FilterFixedAsset) Then
			OSType = Common.ObjectAttributeValue(FilterFixedAsset, "OSType");
		EndIf;

		If OSType = Enums.FATypes.DepreciationComponent
			Or OSType = Enums.FATypes.Node Then
			
			FAOwner = Catalogs.Assets.OwnerOfDepreciationComponentNode(FilterFixedAsset);
		Else
			FillInSelectionByOwnerAndNodes();
		EndIf;
		
		Items.List.Visible = False;
		Items.FilterOrganization.Visible = False;
		Items.HelpTextFilter.Visible = False;
		Items.FilterFixedAsset.Visible = False;
		Items.TheSelectionOfTheAssetTheDepreciation.Visible = False;
		Items.ListDetailedFixedAsset.Visible = ValueIsFilled(FAOwner) Or SelectionByOwnerAndNodes.Count() <> 0;
		Items.GroupUserSettingsList.Visible = False;
		Items.ToRegister.Visible = False;
		
		SetTextOfDynamicListQueries();
		
		AutoTitle = False;
		
		If OSType = Enums.FATypes.Node Then
			Title = StrTemplate(NStr("vi = 'Chứng từ theo nút %1 và đối tượng chủ của nó';
									|ru = 'Документы по узлу %1 и его владельцу';
									|en = 'Documents by the %1 node and its owner'; fa = 'Documents by the %1 node and its owner';
									|it = 'Documenti per nodo %1 e proprietario';
									|pl = 'Dokumenty dotyczące węzła %1 i jego właściciela';
									|tr = '%1 alt varlık ve sahibi için belgeler'"), String(FilterFixedAsset));
		ElsIf OSType = Enums.FATypes.DepreciationComponent Then
			Title = StrTemplate(NStr("vi = 'Chứng từ theo cấu phần khấu hao %1 và đối tượng chủ của nó';
									|ru = 'Документы по компоненту амортизации %1 и его владельцу';
									|en = 'Documents by the %1 depreciation component and its owner'; fa = 'Documents by the %1 depreciation component and its owner';
									|it = 'Documento per componente di ammortamento %1 e proprietario';
									|pl = 'Dokumenty dotyczące komponentu amortyzacji %1 i jego właściciela';
									|tr = '%1Amortisman bileşeni ve sahibi ile ilgili belgeler'"), String(FilterFixedAsset));
		ElsIf SelectionByOwnerAndNodes.Count() <> 0 Then
			Title = StrTemplate(NStr("vi = 'Chứng từ về TSCĐ hữu hình %1 và các nút và cấu phần của nó';
									|ru = 'Документы по основному средству %1 и его узлам и компонентам';
									|en = 'Documents of %1 fixed asset and its nodes and components'; fa = 'Documents of %1 fixed asset and its nodes and components';
									|it = 'Документы по основному средству %1 и его узлам и компонентам';
									|pl = 'Documents of %1 fixed asset and its nodes and components';
									|tr = 'Sabit kıymet belgeleri %1 ve onun alt varlıkları ve bileşenleri'"), String(FilterFixedAsset));
		Else
			Title = StrTemplate(NStr("vi = 'Chứng từ tài sản cố định %1';
									|ru = 'Документы по основному средству %1';
									|en = '%1 fixed asset documents'; fa = '%1 fixed asset documents';
									|it = 'Documenti riguardo l''attività immobilizzata %1';
									|pl = 'Dokumenty po środku trwałym %1';
									|tr = '%1Sabit kıymet belgeleri'"), String(FilterFixedAsset));
		EndIf;
		
	Else
		RestoreSettings();
	EndIf;
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ListOfReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	FillInFormDetailsWhenCreating();
	CustomizeFormElementsWhenCreating();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List);
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListDepreciation);
	
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, 
		BusinessTransactionsAndDocuments, 
		FilterDocumentTypes, 
		FilterBusinessTransactions);
		
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently() Then
		Items.ListOfMa.Visible = False;
		Items.ListOfAC.Visible = False;
		Items.ListDetailedRecordInManAccounting.Visible = False;
		Items.ListDetailedRecordInLocalAccounting.Visible = False;
	EndIf;
	
	DocumentTypesUsed = New Array;
	For Each OperationDescription In BusinessTransactionsAndDocuments Do
		DocumentTypesUsed.Add(Type("DocumentRef." + StrSplit(OperationDescription.FullDocumentName, ".")[1]));
	EndDo;
	For Each LineDocument In DocumentCorrespondence Do
		DocumentTypesUsed.Add(Type("DocumentRef." + LineDocument.OldDocumentName));
	EndDo;
	DocumentTypesUsedDepreciation = New Array;
	For Each OperationDescription In BusinessTransactionsAndDocumentsDepreciation Do
		DocumentTypesUsedDepreciation.Add(Type("DocumentRef." + StrSplit(OperationDescription.FullDocumentName, ".")[1]));
	EndDo;
	
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	PlacementParameters.GroupsPrefix = "List";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListDetailedCommandBar;
	PlacementParameters.GroupsPrefix = "ListDetailed";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsedDepreciation);
	PlacementParameters.CommandBar = Items.ListDepreciationCommandBar;
	PlacementParameters.GroupsPrefix = "ListDepreciation";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	

	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
	StartUpdatingDataInBackground();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
	
	
	If EventName = "Write_File" Then
		UpdatedList_4();
	ElsIf StrFind(EventName, "Record_") <> 0 Then
		
		FADataNeedsToBeUpdated = False;
		For Each LineDocument In BusinessTransactionsAndDocuments Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				FADataNeedsToBeUpdated = True;
				Break;
			EndIf;
		EndDo;

		If FADataNeedsToBeUpdated Then
			// DynamicListsSettings
			UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
			// End DynamicListsSettings
		EndIf;
		
		DepreciationDataNeedsToBeUpdated = False;
		For Each LineDocument In BusinessTransactionsAndDocumentsDepreciation Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				DepreciationDataNeedsToBeUpdated = True;
				Break;
			EndIf;
		EndDo;

		If DepreciationDataNeedsToBeUpdated Then
			// DynamicListsSettings
			UpdateListOfDocumentsEventNotificationProcessing("ListDepreciation", Parameter);
			// End DynamicListsSettings
		EndIf;
		
	EndIf;
	
	If EventName = "Write_FixedAssetsInitialRecognition2_4"
		Or EventName = "Write_DisposeFixedAssets2_4"
		Or EventName = "WritingDocumentToFALog" Then
		UpdateDataWhenFormBecomesActive();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	WhenSelectionChanges();
	
	StartUpdatingDataInBackground();
	
EndProcedure

&AtClient
Procedure FilterFixedAssetOnChange(Item)
	
	FilterMainRemedyWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
	FormParameters,,,,,New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", ThisObject));
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#FixedAssetsInitialRecognition" Then
		OpenForm("DataProcessor.RecognizeAndIncludeExpensesInFixedAssetCost.Form");
	ElsIf FormattedStringURL = "#DisposeFixedAssets" Then
		OpenForm("Document.DisposeFixedAssets2_4.Form.WriteOffOfFAAtDisposalOfInventory");
	ElsIf FormattedStringURL = "#CorrectAccountingErrors" Then
		OpenForm("DataProcessor.CorrectAccountingErrors.Form");
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.ListGroupCreateGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.ListGroupCreateGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);
	
	TMCommonUseClient.SetDeletionMark(Item, Title, CompletionHandler);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListDetailed

&AtClient
Procedure ListDetailedOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListDetailedSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDetailedBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.ListOfDetailsGroupCreateGeneratedBy.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.ListOfDetailsGroupCreateGeneratedBy.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDetailedBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDetailedBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);
	
	TMCommonUseClient.SetDeletionMark(Item, Title, CompletionHandler);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListDepreciation

&AtClient
Procedure ListDepreciationOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListDepreciationSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDepreciationBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.AListOfDepreciationCreateGroupGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.AListOfDepreciationCreateGroupGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDepreciationBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDepreciationBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Item, Title, CompletionHandler);
	
EndProcedure

&AtServer
Procedure ListDepreciationOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDepreciation");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region List

&AtClient
Procedure ListSetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ListInterval,, Notification);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.List);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, CompletionHandler,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));

	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure ListFinancialAccountingPostings(Command)
	If Items.List.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.List.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

&AtClient
Procedure UpdateData1(Command)
	
	UpdateDataWhenFormBecomesActive();

EndProcedure

&AtClient
Procedure ShowDocumentTime(Command)
	
	ShowDocumentTime = Not ShowDocumentTime;
	Items.ListShowDocumentTime.Check = ShowDocumentTime;
	Items.ListDetailedShowDocumentTime.Check = ShowDocumentTime;
	
	List.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
	ListDetailed.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
	
	ShouldSaveSettings();
	
EndProcedure

#EndRegion

#Region ListDetailed

&AtClient
Procedure TheListDetailsTheCancellationOfThe(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDetailed, Title);
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
EndProcedure

&AtClient
Procedure AListOfDetailsToCarryOut(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListDetailed, Title);
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure CopyTheListInDetail(Command)
	
	TMCommonUseClient.CopyItem(Items.ListDetailed);
	
EndProcedure

&AtClient
Procedure AListOfDetailsToSetTheInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ListInDetailInterval,, Notification);
	
EndProcedure

&AtClient
Procedure ListDetailedSetClearADeletionMark(Command)
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);
	
	TMCommonUseClient.SetDeletionMark(Items.ListDetailed, Title, CompletionHandler);
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure ListOfInternationalAccountingTransactionsInDetail(Command)
	If Items.ListDetailed.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListDetailed.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

#EndRegion

#Region ListDepreciation

&AtClient
Procedure ListDepreciationCancellationOfTheEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDepreciation, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListDepreciation"));
	
EndProcedure

&AtClient
Procedure ListOfDepreciationHold(Command)
	
	TMCommonUseClient.NavigateDocumentsInBackgroundTask(
		Items.ListDepreciation, "Document.FixedAssetsDepreciationCharge2_4.Form.DepreciationCalculation");
	
EndProcedure

&AtClient
Procedure AListOfDepreciationCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListDepreciation);
	
EndProcedure

&AtClient
Procedure ListDepreciationChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListDepreciation);
	
EndProcedure

&AtClient
Procedure TheListOfAttenuationToSetTheInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(AListOfTheAmortizationInterval,, Notification);
	
EndProcedure

&AtClient
Procedure AListOfDepreciationSetUnmarkDelete(Command)
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Items.ListDepreciation, Title, CompletionHandler,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListDepreciation"));
	
EndProcedure

&AtClient
Procedure ListOfDepreciationOfInternationalAccountingTransactions(Command)
	If Items.ListDepreciation.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListDepreciation.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, SelectionsForCreatingDocument());
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		FormKey, PurposeUseKey, SelectionsForCreatingDocument());
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, CurrentList(ThisForm));
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, CurrentList(ThisForm), Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, CurrentList(ThisForm));
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("List");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure DepreciationDocumentListToUpdate(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListDepreciation");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RestoreSettings()
	
	Settings = Common.CommonSettingsStorageLoad("DataProcessor.FADocumentLog2_4.Form.FixedAssetsDocuments", PurposeUseKey);
	
	If TypeOf(Settings) = Type("Structure") Then
	
		ListInterval = Settings.ListInterval;
		ListInDetailInterval = Settings.ListInDetailInterval;
		AListOfTheAmortizationInterval = Settings.AListOfTheAmortizationInterval;
		FilterOrganization = Settings.FilterOrganization;
		FilterFixedAsset = Settings.FilterFixedAsset;
		
		Settings.Property("FilterBusinessTransactions", FilterBusinessTransactions);
		Settings.Property("FilterDocumentTypes", FilterDocumentTypes);
		
		If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
			ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
		EndIf;
		If Settings.Property("ListOfDocumentsDepreciationAutoUpdateMode") Then
			ListOfDocumentsDepreciationAutoUpdateMode = Settings.ListOfDocumentsDepreciationAutoUpdateMode;
		EndIf;
		
		ShowDocumentTime = CommonClientServer.StructureProperty(Settings, "ShowDocumentTime", False);
		Items.ListShowDocumentTime.Check = ShowDocumentTime;
		Items.ListDetailedShowDocumentTime.Check = ShowDocumentTime;
		List.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
		ListDetailed.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
		
		FillInSelectionByOwnerAndNodes();
		
		SetTextOfDynamicListQueries();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If FormsOpenedByHyperlink Then
		Return;
	EndIf;
	
	AttributesToSaveNames =
		"ListInterval,ListInDetailInterval,AListOfTheAmortizationInterval,
		|FilterOrganization,
		|FilterFixedAsset,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|ShowDocumentTime,
		|ListOfDocumentsAutoUpdateMode,
		|ListOfDocumentsDepreciationAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave("DataProcessor.FADocumentLog2_4.Form.FixedAssetsDocuments", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload(),
		FilterBusinessTransactions,
		FilterDocumentTypes,
		SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
	//
	TableOfValuesAvailable = InitializeBusinessTransactionsAndDepreciationDocuments(
		BusinessTransactionsAndDocumentsDepreciation.Unload(),
		TheSelectionOfABusinessTransactionDepreciation,
		FilterDocumentTypesDepreciation,
		SettingsKey);
	
	BusinessTransactionsAndDocumentsDepreciation.Load(TableOfValuesAvailable);
	
	SetDynamicListSelections_();
	
EndProcedure

&AtServer
Procedure CustomizeFormElementsWhenCreating()
	If Not AccessRight("View", Metadata.DataProcessors.DocumentPostingInFinancialAccounting.Commands.AccountingEntries) Then
		Items.ListFinancialAccountingPostings.Visible = False;
		Items.ListOfInternationalAccountingTransactionsInDetail.Visible = False;
		Items.ListOfDepreciationOfInternationalAccountingTransactions.Visible = False;
	EndIf;
	If Parameters.Property("QuickFilterStructure") Then
		If Parameters.QuickFilterStructure.Property("FullDocumentName") Then
						
			Filter = New Structure();
			Filter.Insert("FullDocumentName", Parameters.QuickFilterStructure.FullDocumentName);
			
			FoundRows = BusinessTransactionsAndDocuments.FindRows(Filter);
			
			For Each FoundRow In FoundRows Do
				FoundRow.Filter = True;
			EndDo;
			
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("IncomeTaxPayer") Then
		Items.ListIsTA.Visible = False;
		Items.ListDetailedReflectImageInside.Visible = False;
	EndIf;
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
EndProcedure

&AtServer
Procedure ConfigureFormUsingSettingsForBusinessOperationsAndDocuments()
	
	TMCommonUse.WorkplaceData(
		BusinessTransactionsAndDocuments.Unload(), 
		DefaultFormAssignmentKey(), 
		NStr("vi = 'tất cả';
			|ru = 'все';
			|en = 'all'; fa = 'همه';
			|it = 'tutti';
			|pl = 'all';
			|tr = 'tümü'"));
	
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections_()
	
	FilterTypesOfDocumentsForSelection = AddTypesOfDocumentsForSelection(FilterDocumentTypes);
	SelectionBusinessOperationsForSelection = SupplementBusinessTransactionsForSelection(FilterBusinessTransactions);
	
	#Region List
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"BusinessOperation",
		SelectionBusinessOperationsForSelection,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		List,
		"RefType",
		FilterTypesOfDocumentsForSelection,
		DataCompositionComparisonType.InList,
		,
		True);
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"AdditionalRecord",
		False,
		DataCompositionComparisonType.Equal,
		,
		Not ValueIsFilled(FilterOrganization));
		
	List.Parameters.SetParameterValue("BeginOfPeriod", ListInterval.StartDate);
	
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(ListInterval.EndDate),
			EndOfDay(ListInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	Items.ListSetDateInterval.Check = 
		ValueIsFilled(ListInterval.StartDate) Or ValueIsFilled(ListInterval.EndDate);
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
	#EndRegion
	
	#Region ListDetailed
	CommonClientServer.SetDynamicListFilterItem(
		ListDetailed,
		"BusinessOperation",
		SelectionBusinessOperationsForSelection,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		ListDetailed,
		"RefType",
		FilterTypesOfDocumentsForSelection,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		ListDetailed,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDetailed,
		"AdditionalRecord",
		False,
		DataCompositionComparisonType.Equal,
		,
		Not ValueIsFilled(FilterOrganization));
		
	If ValueIsFilled(FAOwner) Then
		
		FilterList = New ValueList;
		FilterList.Add(FilterFixedAsset);
		FilterList.Add(FAOwner);
		
		CommonClientServer.SetDynamicListFilterItem(
			ListDetailed,
			"FixedAsset",
			FilterList,
			DataCompositionComparisonType.InList,
			,
			True);
			
	ElsIf SelectionByOwnerAndNodes.Count() <> 0 Then
		
		CommonClientServer.SetDynamicListFilterItem(
			ListDetailed,
			"FixedAsset",
			SelectionByOwnerAndNodes,
			DataCompositionComparisonType.InList,
			,
			True);
				
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
			ListDetailed,
			"FixedAsset",
			FilterFixedAsset,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(FilterFixedAsset));
		
	EndIf;
		
	ListDetailed.Parameters.SetParameterValue("BeginOfPeriod", ListInDetailInterval.StartDate);
	
	ListDetailed.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(ListInDetailInterval.EndDate),
			EndOfDay(ListInDetailInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	Items.AListOfDetailsToSetTheInterval.Check = 
		ValueIsFilled(ListInDetailInterval.StartDate) Or ValueIsFilled(ListInDetailInterval.EndDate);
	#EndRegion
	
	#Region ListDepreciation
	FilterTypesOfDocumentsForSelection = AddTypesOfDocumentsForSelection(FilterDocumentTypesDepreciation);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDepreciation,
		"RefType",
		FilterTypesOfDocumentsForSelection,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDepreciation,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	ListDepreciation.Parameters.SetParameterValue("BeginOfPeriod", AListOfTheAmortizationInterval.StartDate);
	
	ListDepreciation.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(AListOfTheAmortizationInterval.EndDate),
			EndOfDay(AListOfTheAmortizationInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	Items.TheListOfAttenuationToSetTheInterval.Check = 
		ValueIsFilled(AListOfTheAmortizationInterval.StartDate) Or ValueIsFilled(AListOfTheAmortizationInterval.EndDate);
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDepreciation");
	// End DynamicListsSettings
	
	#EndRegion

EndProcedure

&AtServer
Function AddTypesOfDocumentsForSelection(SelectListDocumentTypes)

	If DocumentCorrespondence.Count() = 0 Then
		Return SelectListDocumentTypes;
	EndIf; 
	
	SelectDocumentTypesCopy = SelectListDocumentTypes.Copy();

	For Each CollectionItem In SelectListDocumentTypes Do
		TheStructureOfTheSearch = New Structure("NewDocument", CollectionItem.Value);
		StringsList = DocumentCorrespondence.FindRows(TheStructureOfTheSearch);
		For Each RowData In StringsList Do
			SelectDocumentTypesCopy.Add(RowData.OldDocument);
		EndDo; 
	EndDo; 
	
	Return SelectDocumentTypesCopy;
	
EndFunction

&AtServer
Function SupplementBusinessTransactionsForSelection(FilterBusinessTransactions)

	SelectionOfBusinessOperationsCopy = FilterBusinessTransactions.Copy();

	If SelectionOfBusinessOperationsCopy.FindByValue(Enums.BusinessTransactions.NonCurrentAssetsSale) <> Undefined Then
		SelectionOfBusinessOperationsCopy.Add(Enums.BusinessTransactions.SaleToCustomer);
	EndIf; 
	If SelectionOfBusinessOperationsCopy.FindByValue(Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer) <> Undefined Then
		SelectionOfBusinessOperationsCopy.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
	EndIf;
	If SelectionOfBusinessOperationsCopy.FindByValue(Enums.BusinessTransactions.RenderRentalServices) <> Undefined Then
		SelectionOfBusinessOperationsCopy.Add(Enums.BusinessTransactions.RenderRentalServices);
	EndIf;
	
	Return SelectionOfBusinessOperationsCopy;
	
EndFunction

&AtServer
Procedure SetTextOfDynamicListQueries()

	QueryText = 
	"SELECT
	|	DocumentsRegistryOverridable.Ref AS Ref,
	|	DocumentsRegistryOverridable.Organization AS Organization,
	|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistryOverridable.Department AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.More AS More,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	DocumentsRegistryOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN DocumentsRegistryOverridable.Posted
	|			THEN 0
	|		WHEN DocumentsRegistryOverridable.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|	DocumentsRegistryOverridable.AdditionalRecord AS AdditionalRecord,
	|	DocumentsRegistryOverridable.RefType AS RefType,
	|	ISNULL(FixedAssetsDocumentsOverridable.RecordInManAccounting, FALSE) AS RecordInManAccounting,
	|	ISNULL(FixedAssetsDocumentsOverridable.RecordInLocalAccounting, FALSE) AS RecordInLocalAccounting,
	|	ISNULL(FixedAssetsDocumentsOverridable.RecordInTA, FALSE) AS RecordInTA,
	|	&ShowDocumentTime AS ShowDocumentTime,
	|	&CheckStatus AS CheckStatus,
	|	CAST(&CheckingIndicator AS BOOLEAN) AS CheckingIndicator,
	|	VALUETYPE(DocumentsRegistryOverridable.Ref) AS TheTypeOfReferenceDocument,
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.RecordInManAccounting
	|				AND DocumentsRegistryOverridable.Posted
	|			THEN 1
	|		WHEN FixedAssetsDocumentsOverridable.RecordInManAccounting
	|				AND NOT DocumentsRegistryOverridable.Posted
	|			THEN 2
	|		ELSE 0
	|	END AS ToReflectInTheAccountPicture,
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.RecordInLocalAccounting
	|				AND DocumentsRegistryOverridable.Posted
	|			THEN 1
	|		WHEN FixedAssetsDocumentsOverridable.RecordInLocalAccounting
	|				AND NOT DocumentsRegistryOverridable.Posted
	|			THEN 2
	|		ELSE 0
	|	END AS ReflectTheImageInTheReglAccount,
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.RecordInTA
	|				AND DocumentsRegistryOverridable.Posted
	|			THEN 1
	|		WHEN FixedAssetsDocumentsOverridable.RecordInTA
	|				AND NOT DocumentsRegistryOverridable.Posted
	|			THEN 2
	|		ELSE 0
	|	END AS ReflectImageInside,
	|	CASE
	|		WHEN DocumentsRegistryOverridable.IBDocumentDate < &AccountingStartDate
	|				AND (DocumentsRegistryOverridable.Ref REFS Document.EntryOfCapitalAssetsBalance2_4
	|					OR DocumentsRegistryOverridable.Ref REFS Document.ChangeFixedAssetFinancialDetails2_4)
	|			THEN 1
	|		ELSE 0
	|	END AS CreatedToUpgradeToVersion24,
	|	CASE
	|		WHEN FilesExistOverridable.HasFiles IS NULL
	|			THEN 0
	|		WHEN FilesExistOverridable.HasFiles
	|			THEN 1
	|		ELSE 0
	|	END AS HasFiles,
	|	EDStatesOverridable.StatusPresentation AS StatusPresentation,
	|	DocumentsRegistryOverridable.RecordID AS RecordID,
	|	ISNULL(FixedAssetsDocumentsOverridable.FixedAssetsEvent, VALUE(Catalog.FixedAssetsEvents.EmptyRef)) AS FixedAssetsEvent,
	|	ISNULL(FixedAssetsDocumentsOverridable.CorrectionPeriodStart, DATETIME(1,1,1)) AS CorrectionPeriodStart,
	|	ISNULL(FixedAssetsDocumentsOverridable.CorrectionPeriodEnd, DATETIME(1,1,1)) AS CorrectionPeriodEnd
	|
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
	|
	|		INNER JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocumentsOverridable
	|		ON (FixedAssetsDocumentsOverridable.RefType = DocumentsRegistryOverridable.RefType)
	|			AND (FixedAssetsDocumentsOverridable.BusinessOperation = DocumentsRegistryOverridable.BusinessOperation)
	|			AND (FixedAssetsDocumentsOverridable.RecNo = 0)
	|			AND (FixedAssetsDocumentsOverridable.AdditionalRecord = FALSE)
	|			AND (FixedAssetsDocumentsOverridable.Ref = DocumentsRegistryOverridable.Ref)
	|
	|		LEFT JOIN InformationRegister.FilesExist AS FilesExistOverridable
	|		ON DocumentsRegistryOverridable.Ref = FilesExistOverridable.ObjectWithFiles
	|
	|		{LEFT JOIN InformationRegister.StatesByEDIAccountingObjects AS EDStatesOverridable
	|		ON EDStatesOverridable.ObjectReference = DocumentsRegistryOverridable.Ref}
	|
	|{WHERE
	|	DocumentsRegistryOverridable.Ref.* AS Ref,
	|	DocumentsRegistryOverridable.Organization.* AS Organization,
	|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistryOverridable.Department.* AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible.* AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.More AS More,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	DocumentsRegistryOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|	(DocumentsRegistryOverridable.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|	}";
	
	NonCurrentAssetsLocalization.SupplementTextOfFALogRequest(QueryText);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	If FilterFixedAsset.IsEmpty() Then
		
		QueryText = 
		"SELECT
		|	DocumentsRegistryOverridable.RefType AS RefType,
		|	VALUETYPE(DocumentsRegistryOverridable.Ref) AS TheTypeOfReferenceDocument,
		|	DocumentsRegistryOverridable.Ref AS Ref,
		|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
		|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
		|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
		|	DocumentsRegistryOverridable.Posted AS Posted,
		|	DocumentsRegistryOverridable.Organization AS Organization,
		|	ISNULL(FixedAssetsDepreciationCharge2_4Overridable.PackageNumber, 0) AS PackageNumber,
		|	DocumentsRegistryOverridable.Comment AS Comment,
		|	DocumentsRegistryOverridable.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
		|	DocumentsRegistryOverridable.RecordID AS RecordID,
		|	CASE
		|		WHEN DocumentsRegistryOverridable.Posted
		|			THEN 0
		|		WHEN DocumentsRegistryOverridable.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END AS CustomPicture,
		|	CASE
		|		WHEN FilesExistOverridable.HasFiles IS NULL
		|			THEN 0
		|		WHEN FilesExistOverridable.HasFiles
		|			THEN 1
		|		ELSE 0
		|	END AS HasFiles
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
		|		LEFT JOIN Document.FixedAssetsDepreciationCharge2_4 AS FixedAssetsDepreciationCharge2_4Overridable
		|		ON (FixedAssetsDepreciationCharge2_4Overridable.Ref = DocumentsRegistryOverridable.Ref)
		|		LEFT JOIN InformationRegister.FilesExist AS FilesExistOverridable
		|		ON DocumentsRegistryOverridable.Ref = FilesExistOverridable.ObjectWithFiles
		|{WHERE
		|	DocumentsRegistryOverridable.Ref.* AS Ref,
		|	DocumentsRegistryOverridable.Organization.* AS Organization,
		|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
		|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
		|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
		|	DocumentsRegistryOverridable.Department.* AS Department,
		|	DocumentsRegistryOverridable.EmployeeResponsible.* AS EmployeeResponsible,
		|	DocumentsRegistryOverridable.More AS More,
		|	DocumentsRegistryOverridable.Comment AS Comment,
		|	DocumentsRegistryOverridable.Posted AS Posted,
		|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
		|	(DocumentsRegistryOverridable.IBDocumentDate >= &BeginOfPeriod
		|		AND DocumentsRegistryOverridable.IBDocumentDate <= &EndOfPeriod)}";
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = QueryText;
		Common.SetDynamicListProperties(Items.ListDepreciation, ListProperties);
		
	Else
		
		QueryText = 
		"SELECT
		|	DocumentsRegistryOverridable.RefType AS RefType,
		|	VALUETYPE(DocumentsRegistryOverridable.Ref) AS TheTypeOfReferenceDocument,
		|	DocumentsRegistryOverridable.Ref AS Ref,
		|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
		|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
		|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
		|	DocumentsRegistryOverridable.Posted AS Posted,
		|	DocumentsRegistryOverridable.Organization AS Organization,
		|	ISNULL(FixedAssetsDepreciationCharge2_4Overridable.PackageNumber, 0) AS PackageNumber,
		|	DocumentsRegistryOverridable.Comment AS Comment,
		|	DocumentsRegistryOverridable.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
		|	DocumentsRegistryOverridable.RecordID AS RecordID,
		|	CASE
		|		WHEN DocumentsRegistryOverridable.Posted
		|			THEN 0
		|		WHEN DocumentsRegistryOverridable.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END AS CustomPicture,
		|	CASE
		|		WHEN FilesExistOverridable.HasFiles IS NULL
		|			THEN 0
		|		WHEN FilesExistOverridable.HasFiles
		|			THEN 1
		|		ELSE 0
		|	END AS HasFiles
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
		|		LEFT JOIN Document.FixedAssetsDepreciationCharge2_4 AS FixedAssetsDepreciationCharge2_4Overridable
		|		ON (FixedAssetsDepreciationCharge2_4Overridable.Ref = DocumentsRegistryOverridable.Ref)
		|		LEFT JOIN InformationRegister.FilesExist AS FilesExistOverridable
		|		ON DocumentsRegistryOverridable.Ref = FilesExistOverridable.ObjectWithFiles
		|WHERE
		|	DocumentsRegistryOverridable.Ref IN
		|			(SELECT
		|				RegisterDepreciationFA.Recorder
		|			FROM
		|				AccumulationRegister.FixedAssetsDepreciationCharge AS RegisterDepreciationFA
		|			WHERE
		|				RegisterDepreciationFA.FixedAsset = &FixedAsset)
		|{WHERE
		|	DocumentsRegistryOverridable.Ref.* AS Ref,
		|	DocumentsRegistryOverridable.Organization.* AS Organization,
		|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
		|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
		|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
		|	DocumentsRegistryOverridable.Department.* AS Department,
		|	DocumentsRegistryOverridable.EmployeeResponsible.* AS EmployeeResponsible,
		|	DocumentsRegistryOverridable.More AS More,
		|	DocumentsRegistryOverridable.Comment AS Comment,
		|	DocumentsRegistryOverridable.Posted AS Posted,
		|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
		|	(DocumentsRegistryOverridable.IBDocumentDate >= &BeginOfPeriod
		|		AND DocumentsRegistryOverridable.IBDocumentDate <= &EndOfPeriod)}";
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = QueryText;
		Common.SetDynamicListProperties(Items.ListDepreciation, ListProperties);
		
		ListDepreciation.Parameters.SetParameterValue("FixedAsset", FilterFixedAsset);
		
	EndIf; 

EndProcedure

&AtServer
Procedure FilterMainRemedyWhenChangingOnServer()

	FillInSelectionByOwnerAndNodes();
	SetTextOfDynamicListQueries();
	WhenSelectionChanges();

EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "FADocuments";
	
EndFunction

&AtServer
Procedure WhenSelectionChanges()
	
	ShouldSaveSettings();
	SetDynamicListSelections_();
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisForm;
	ParametersStructure.NameOfCreateGroup                                    = "ListGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext                            = "ListGroupCreateGeneratedByContext";
	ParametersStructure.NameOfCopyButton                                = "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton                 = "CopyContextList";
	ParametersStructure.ChangeButtonName                                   = "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton                    = "EditContextList";
	ParametersStructure.ButtonNamePost                                   = "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton                    = "ListAndContext";
	ParametersStructure.NameOfCancelEventButton                           = "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu            = "ListOfCancellationsOfTheEventContext";
	ParametersStructure.NameOfMarkDeleteButton                  = "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu   = "SetMarkDeleteContextList";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);

	//
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisForm;
	ParametersStructure.NameOfCreateGroup                                    = "ListOfDetailsGroupCreateGeneratedBy";
	ParametersStructure.GroupNameCreateContext                            = "ListDetailedGroupCreateGeneratedContext";
	ParametersStructure.NameOfCopyButton                                = "CopyTheListInDetail";
	ParametersStructure.NameOfCopyContextMenuButton                 = "CopyContextDetailsList";
	ParametersStructure.ChangeButtonName                                   = "ListDetailedChange";
	ParametersStructure.NameOfChangeContextMenuButton                    = "EditContextDetailsList";
	ParametersStructure.ButtonNamePost                                   = "AListOfDetailsToCarryOut";
	ParametersStructure.NameOfHoldContextMenuButton                    = "ListOfDetailsToHoldContext";
	ParametersStructure.NameOfCancelEventButton                           = "TheListDetailsTheCancellationOfThe";
	ParametersStructure.NameOfCancelButtonIsContextMenu            = "ListOfDetailsCancellationOfTheEventContext";
	ParametersStructure.NameOfMarkDeleteButton                  = "AListOfDetailsPutATickRemoval";
	ParametersStructure.ButtonNameMarkDeleteContextMenu   = "AListOfDetailsPutATickRemoveTheContext";
	ParametersStructure.ElementPrefix                                    = "ListDetailed";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
	//
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisForm;
	ParametersStructure.NameOfCreateGroup                                    = "AListOfDepreciationCreateGroupGenerated";
	ParametersStructure.GroupNameCreateContext                            = "AListOfTheDepreciationGroupToCreateTheGeneratedContext";
	ParametersStructure.NameOfCopyButton                                = "AListOfDepreciationCopy";
	ParametersStructure.NameOfCopyContextMenuButton                 = "AListOfDepreciationToCopyTheContext";
	ParametersStructure.ChangeButtonName                                   = "ListDepreciationChange";
	ParametersStructure.NameOfChangeContextMenuButton                    = "AListOfDepreciationToChangeTheContext";
	ParametersStructure.ButtonNamePost                                   = "ListOfDepreciationHold";
	ParametersStructure.NameOfHoldContextMenuButton                    = "ListCushioningToHoldTheContext";
	ParametersStructure.NameOfCancelEventButton                           = "ListDepreciationCancellationOfTheEvent";
	ParametersStructure.NameOfCancelButtonIsContextMenu            = "ListDepreciationCancellationOfTheTransactionContext";
	ParametersStructure.NameOfMarkDeleteButton                  = "DepreciationListSetDeleteMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu   = "AListOfDepreciationIsToSetAMarkDeleteTheContext";
	ParametersStructure.ElementPrefix                                    = "ListDepreciation";
	ParametersStructure.NameOfTableOfBusinessOperationsAndDocuments          = "BusinessTransactionsAndDocumentsDepreciation";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	NonCurrentAssetsInternal.SetDateFieldConditionalAppearance(
		ThisObject, "List.Date", "ListDate", "ShowDocumentTime");
		
	NonCurrentAssetsInternal.SetDateFieldConditionalAppearance(
		ThisObject, "ListDetailed.Date", "ListDetailedDate", "ShowDocumentTime");
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments)
	
	TableBusinessOperationsAndDocuments = GetFromTempStorage(AddressOfAvailableBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(TableBusinessOperationsAndDocuments);
	
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(
		TableBusinessOperationsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
	WhenSelectionChanges();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListDepreciation);
	
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	WhenSelectionChanges();
	
EndProcedure

&AtClientAtServerNoContext
Function CurrentList(Form)

	If Form.Items.Pages.CurrentPage = Form.Items.DocumentsDetailsPage Then
		Return Form.Items.ListDetailed;
	ElsIf Form.Items.Pages.CurrentPage = Form.Items.DepreciationPage Then
		Return Form.Items.ListDepreciation;
	Else
		Return Form.Items.List;
	EndIf; 

EndFunction

&AtServerNoContext
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, UnregisteredDocuments = False)
	
	NonCurrentAssetsInternal.InitializeBusinessTransactionsAndDocumentsOfNonCurrentAssets(BusinessTransactionsAndDocuments);
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer;
		String.FullDocumentName			= Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName();
		String.PurposeUseKey 	= PurposeUseKey;
		String.WorkplaceTitle	 	= NStr("vi = 'bán dịch vụ và các tài sản khác';
											|ru = 'реализация услуг и прочих активов';
											|en = 'Customer invoice — Services and Assets'; fa = 'فاکتور مشتری — خدمات و دارایی‌ها';
											|it = 'Vendita di servizi e altri attivi';
											|pl = 'realizacja usług i innych aktywów';
											|tr = 'müşteri faturası - hizmetler ve varlıklar'");
		String.AddButtonCreate        = True;
	EndIf;
	
	If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation		= Enums.BusinessTransactions.RenderRentalServices;
		String.FullDocumentName			= Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName();
		String.PurposeUseKey	= PurposeUseKey;
		String.WorkplaceTitle		= NStr("vi = 'bán dịch vụ và các tài sản khác';
											|ru = 'реализация услуг и прочих активов';
											|en = 'Customer invoice — Services and Assets'; fa = 'فاکتور مشتری — خدمات و دارایی‌ها';
											|it = 'Vendita di servizi e altri attivi';
											|pl = 'realizacja usług i innych aktywów';
											|tr = 'müşteri faturası - hizmetler ve varlıklar'");
		String.AddButtonCreate		= True;
	EndIf;
	
	#Region FixedAssetsInitialRecognition
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsInitialRecognition;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'chấp nhận TSCĐ kế toán';
										|ru = 'принятие к учету ОС';
										|en = 'Fixed assets — Initial recognition'; fa = 'دارایی‌های ثابت — شناسایی اولیه';
										|it = 'Scrittura nei libri contabili Cespiti';
										|pl = 'Przyjęcie do ewidencji środków trwałych';
										|tr = 'Sabit kıymetler - İlk tahakkuk'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RecognitionOfLeaseItems;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'chấp nhận TSCĐ kế toán';
										|ru = 'принятие к учету ОС';
										|en = 'Fixed assets — Initial recognition'; fa = 'دارایی‌های ثابت — شناسایی اولیه';
										|it = 'Scrittura nei libri contabili Cespiti';
										|pl = 'Przyjęcie do ewidencji środków trwałych';
										|tr = 'Sabit kıymetler - İlk tahakkuk'");
	String.AddButtonCreate        = True;
	
	#EndRegion
	
	#Region RecognizeSubAssetsComponentsOfDepreciation
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation;
	String.FullDocumentName			= Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.FullName();
	String.PurposeUseKey 	= "RecognizeSubAssetsComponentsOfDepreciation";
	String.WorkplaceTitle	 	= NStr("vi = 'tiếp nhận vào kế toán các bộ phận và thành phần khấu hao';
										|ru = 'принятие к учету узлов и компонентов амортизации';
										|en = 'recognition of sub-assets and components of depreciation'; fa = 'recognition of sub-assets and components of depreciation';
										|it = 'ricezione in contabilità di nodi e componenti di ammortamento';
										|pl = 'przyjęcie do ewidencji węzłów i komponentów amortyzacji';
										|tr = 'alt varlıkların ve amortisman bileşenlerinin muhasebeleştirilmesi'");
	String.AddButtonCreate        = True;
	#EndRegion
	
	#Region DisposeFixedAssets
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.DisposeFixedAssets;
	String.FullDocumentName			= Metadata.Documents.DisposeFixedAssets2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi giảm TSCĐ hữu hình';
										|ru = 'Списание ОС';
										|en = 'Dispose fixed assets'; fa = 'واگذاری دارایی‌های ثابت';
										|it = 'Cancellazione contabile capitale fisso';
										|pl = 'Wyksięgowanie środków trwałych';
										|tr = 'Sabit kıymetlerin tasfiyesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PartialFixedAssetsDisposal;
	String.FullDocumentName			= Metadata.Documents.DisposeFixedAssets2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi giảm một phần TSCĐ hữu hình';
										|ru = 'Частичное списание ОС';
										|en = 'Partial fixed assets disposal'; fa = 'واگذاری جزئی دارایی‌های ثابت';
										|it = 'Cancellazione parziale del capitale fisso';
										|pl = 'Częściowe wyksięgowanie ŚT';
										|tr = 'Sabit kıymetlerin kısmi tasfiyesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation;
	String.FullDocumentName			= Metadata.Documents.DisposeFixedAssets2_4.FullName();
	String.PurposeUseKey 	= "DisposeFixedAssets";
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi giảm các bộ phận và thành phần';
										|ru = 'Полное списание узлов и компонентов';
										|en = 'Complete write-off of sub-assets and components'; fa = 'Complete write-off of sub-assets and components';
										|it = 'Storno completo nodi e componenti';
										|pl = 'Pełny rozchód węzłów i komponentów';
										|tr = 'Alt varlıkları ve bileşenleri tamamen gider yazma'");
	String.AddButtonCreate        = True;
	
	#EndRegion
	
	#Region FATransfer
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FATransfer;
	String.FullDocumentName			= Metadata.Documents.FATransfer2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'điều chuyển TSCĐ hữu hình';
										|ru = 'перемещение ОС';
										|en = 'transfer fixed assets'; fa = 'transfer fixed assets';
										|it = 'Trasferimento Capitale Fisso';
										|pl = 'Przemieszczenie środków trwałych';
										|tr = 'sabit kıymet transferi'");
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferSubAssets;
	String.FullDocumentName			= Metadata.Documents.FATransfer2_4.FullName();
	String.PurposeUseKey 	= "TransferSubAssets";
	String.WorkplaceTitle	 	= NStr("vi = 'điều chuyển các bộ phận TSCĐ';
										|ru = 'перемещение ОС-узлов';
										|en = 'transfer fixed asset sub-assets'; fa = 'transfer fixed asset sub-assets';
										|it = 'spostamento nodi cespite';
										|pl = 'przeniesienie ŚT-węzłów';
										|tr = 'Sabit kıymet alt varlıklarının transferi'");
	String.AddButtonCreate        = True;
	
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice;
		String.FullDocumentName			= Metadata.Documents.FATransfer2_4.FullName();
		String.PurposeUseKey 	= PurposeUseKey;
		String.WorkplaceTitle	 	= NStr("vi = 'điều chuyển TSCĐ hữu hình';
											|ru = 'перемещение ОС';
											|en = 'transfer fixed assets'; fa = 'transfer fixed assets';
											|it = 'Trasferimento Capitale Fisso';
											|pl = 'Przemieszczenie środków trwałych';
											|tr = 'sabit kıymet transferi'");
		String.AddButtonCreate        = True;
	EndIf; 
	
	#EndRegion
	
	#Region Lease
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.SigningOfLeaseContract;
	String.FullDocumentName			= Metadata.Documents.SigningOfLeaseContract.FullName();
	String.PurposeUseKey 	= "SigningOfLeaseContract";
	String.WorkplaceTitle	 	= NStr("vi = 'ký hợp đồng thuê';
										|ru = 'заключение договоров аренды';
										|en = 'rental contracts signing'; fa = 'rental contracts signing';
										|it = 'conclusione dei contratti di affitto';
										|pl = 'zawarcie umów dzierżawy';
										|tr = 'kira sözleşmelerinin sonuçlandırılması'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ReceiveLeasedAssets;
	String.FullDocumentName			= Metadata.Documents.ReceiveLeasedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'tiếp nhận TSCĐ cho thuê';
										|ru = 'поступление арендованных ОС';
										|en = 'receive leased assets'; fa = 'receive leased assets';
										|it = 'entrata di Immobilizzazioni locate';
										|pl = 'wpływ wynajmowanych środków trwałych';
										|tr = 'kiralanan varlıkların teslim alınması'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ReturnLeasedAssets;
	String.FullDocumentName			= Metadata.Documents.ReturnLeasedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.LeaseTermination;
	String.FullDocumentName			= Metadata.Documents.LeaseTermination.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.EarlyTerminationOfLeaseContract;
	String.FullDocumentName			= Metadata.Documents.LeaseTermination.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.VendorInvoiceLeasedAssets;
	String.FullDocumentName			= Metadata.Documents.VendorInvoiceLeasedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.EarlyBuyoutOfLeasedAssets;
	String.FullDocumentName			= Metadata.Documents.VendorInvoiceLeasedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.LeaseTermAdjustment;
	String.FullDocumentName			= Metadata.Documents.LeaseTermAdjustment.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ChangeRentalTerms;
	String.FullDocumentName			= Metadata.Documents.ChangeRentalTerms.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ProvideAssetsToLeasee;
	String.FullDocumentName			= Metadata.Documents.ProvideAssetsToLeasee2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'chuyển giao TSCĐ cho thuê';
										|ru = 'передача ОС в аренду';
										|en = 'provide assets to lessee'; fa = 'provide assets to lessee';
										|it = 'trasferimento immobilizzazioni in affitto';
										|pl = 'przekazanie środków trwałych do dzierżawy';
										|tr = 'sabit kıymetlerin kiralayana temini'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ReturnAssetsFromLeasee;
	String.FullDocumentName			= Metadata.Documents.ReturnAssetsFromLeasee2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'trả lại TSCĐ đã thuê';
										|ru = 'возврат ОС из аренды';
										|en = 'return assets from lessee'; fa = 'return assets from lessee';
										|it = 'reso immobilizzazioni dall''affitto';
										|pl = 'zwrot środków trwałych z dzierżawy';
										|tr = 'sabit kıymetlerin kiralayandan iadesi'");
	String.AddButtonCreate        = True;
	
	#EndRegion
	
	#Region Other
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ChangeFixedAssetFinancialDetails;
	String.FullDocumentName			= Metadata.Documents.ChangeFixedAssetFinancialDetails2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'thay đổi cài đặt TSCĐ HH';
										|ru = 'изменение параметров ОС';
										|en = 'adjust fixed asset financial details'; fa = 'adjust fixed asset financial details';
										|it = 'Modifica dei parametri dei capitali fissi';
										|pl = 'Zmiana parametrów środków trwałych';
										|tr = 'sabit kıymet finansal bilgi düzeltmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsCostAdditions;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsCostAdditions2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nâng cấp TSCĐ';
										|ru = 'модернизация ОС';
										|en = 'Fixed assets appreciation'; fa = 'افزایش ارزش دارایی‌های ثابت';
										|it = 'Ammodernamento del patrimonio aziendale di capitale fisso';
										|pl = 'Modernizacja środków trwałych';
										|tr = 'SV modernizasyonu'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsCostAdditions2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nâng cấp TSCĐ';
										|ru = 'модернизация ОС';
										|en = 'Fixed assets appreciation'; fa = 'افزایش ارزش دارایی‌های ثابت';
										|it = 'Ammodernamento del patrimonio aziendale di capitale fisso';
										|pl = 'Modernizacja środków trwałych';
										|tr = 'SV modernizasyonu'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FARevaluation;
	String.FullDocumentName			= Metadata.Documents.FARevaluation2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Đánh giá lại TSCĐ';
										|ru = 'переоценка ОС';
										|en = 'revaluate fixed assets'; fa = 'revaluate fixed assets';
										|it = 'Rivalutazione Capitale Fisso';
										|pl = 'Przeszacowanie środków trwałych';
										|tr = 'sabit kıymet yeniden değerlemesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PreparingForFixedAssetSale;
	String.FullDocumentName			= Metadata.Documents.PreparingForFixedAssetSale2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'chuẩn bị chuyển giao TSCĐ';
										|ru = 'подготовка к передаче ОС';
										|en = 'preparing for sale of fixed assets'; fa = 'preparing for sale of fixed assets';
										|it = 'preparazione al trasferimento del capitale fisso';
										|pl = 'Przygotowanie do przekazania środków trwałych';
										|tr = 'sabit kıymet satışına hazırlık'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.AssetActivityRecord;
	String.FullDocumentName			= Metadata.Documents.AssetActivityRecord.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Kỳ hoạt động';
										|ru = 'наработка ОС';
										|en = 'Fixed assets running time'; fa = 'Fixed assets running time';
										|it = 'sviluppo del capitale fisso';
										|pl = 'napracowanie ST';
										|tr = 'varlık faaliyet ölçümü sabit kıymet'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.CompleteSplitFixedAssets;
	String.FullDocumentName			= Metadata.Documents.SplitFixedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'TSCĐ tháo dỡ';
										|ru = 'разукомплектация ОС';
										|en = 'split fixed assets'; fa = 'split fixed assets';
										|it = 'smantellamento Capitale fisso';
										|pl = 'Zdekompletowanie ST';
										|tr = 'SV''lerin bölünmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PartialFixedAssetsSplit;
	String.FullDocumentName			= Metadata.Documents.SplitFixedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'TSCĐ tháo dỡ';
										|ru = 'разукомплектация ОС';
										|en = 'split fixed assets'; fa = 'split fixed assets';
										|it = 'smantellamento Capitale fisso';
										|pl = 'Zdekompletowanie ST';
										|tr = 'SV''lerin bölünmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation;
	String.FullDocumentName			= Metadata.Documents.SplitFixedAssets.FullName();
	String.PurposeUseKey 	= "SplitFixedAssets";
	String.WorkplaceTitle	 	= NStr("vi = 'TSCĐ tháo dỡ';
										|ru = 'разукомплектация ОС';
										|en = 'split fixed assets'; fa = 'split fixed assets';
										|it = 'smantellamento Capitale fisso';
										|pl = 'Zdekompletowanie ST';
										|tr = 'SV''lerin bölünmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.MergeOfFixedAssets;
	String.FullDocumentName			= Metadata.Documents.MergeOfFixedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.AttachingToExistingFixedAsset;
	String.FullDocumentName			= Metadata.Documents.MergeOfFixedAssets.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetCostAndDepreciationAdjustment;
	String.FullDocumentName			= Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RegistrationAtFADisposal;
	String.FullDocumentName			= Metadata.Documents.OtherGoodsRecordingAsReceived.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'ghi tăng nguyên vật liệu khi thanh lý TSCĐ';
										|ru = 'оприходование материалов при выбытии ОС';
										|en = 'record the materials as received upon fixed assets retirement'; fa = 'record the materials as received upon fixed assets retirement';
										|it = 'accettazione materiali alla dismissione Immobilizzazione';
										|pl = 'rejestracja materiałów przy wyrejestrowaniu ŚT';
										|tr = 'sabit kıymetlerin elden çıkarılması üzerine malzemelerin aktifleştirilmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.AllocateVariancesToFixedAssetCost;
	String.FullDocumentName			= Metadata.Documents.AllocateVariancesToFixedAssetCost.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'đưa các chênh lệch vào giá trị tài sản cố định';
										|ru = 'отнесение отклонений в стоимость ОС';
										|en = 'allocate variances to fixed asset cost'; fa = 'allocate variances to fixed asset cost';
										|it = 'allocate variances to fixed asset cost';
										|pl = 'allocate variances to fixed asset cost';
										|tr = 'farkların sabit kıymet maliyetine yüklenmesi'");
	String.AddButtonCreate        = True;

	#EndRegion
	
	#Region OBEntry
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryFixedAssets;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của tài sản cố định';
										|ru = 'Ввод начальных остатков основных средств';
										|en = 'OB entry: cost of owned fixed assets'; fa = 'OB entry: cost of owned fixed assets';
										|it = 'Inserimento dei saldi iniziali dei capitali fissi';
										|pl = 'Wprowadzenie sald początkowych środków trwałych';
										|tr = 'Sabit kıymetlerin başlangıç bakiyelerinin girişi'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntrySubAssetsAndComponentsOfDepreciation;
	String.FullDocumentName			= Metadata.Documents.OBEntrySubAssetsAndComponentsOfDepreciation.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư bộ phận và thành phần khấu hao';
										|ru = 'Ввод начальных остатков узлов, компонентов амортизации';
										|en = 'OB entry: sub-assets and components of depreciation'; fa = 'ورود مانده افتتاحیه: دارایی‌های فرعی و اجزای استهلاک';
										|it = 'Ввод начальных остатков узлов, компонентов амортизации';
										|pl = 'OB entry: sub-assets and components of depreciation';
										|tr = 'Açılış bakiye girişi: alt varlıklar ve amortisman bileşenleri'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của các khoản đầu tư vào tài sản dài hạn';
										|ru = 'Ввод начальных остатков вложений во внеоборотные активы';
										|en = 'OB entry: investments in fixed and intangible assets'; fa = 'ورود مانده افتتاحیه: سرمایه‌گذاری در دارایی‌های ثابت و نامشهود';
										|it = 'Inserimento dei saldi iniziali degli investimenti in attivi non circolanti';
										|pl = 'Wprowadzenie sald początkowych inwestycji w aktywa pozaobrotowe';
										|tr = 'Duran varlıklara yapılan yatırımların başlangıç bakiyelerinin girilmesi'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (trong bảng cân đối)';
										|ru = 'Ввод начальных остатков арендованных ОС (на балансе)';
										|en = 'OB entry: leased fixed assets (on balance sheet)'; fa = 'ورود مانده افتتاحیه: دارایی‌های ثابت اجاره‌ای (در ترازنامه)';
										|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (in bilancio)';
										|pl = 'Wprowadzenie sald początkowych wynajmowanych środków trwałych (na bilansie)';
										|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi (bilançoda)'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê trong bảng';
										|ru = 'Ввод начальных остатков переданных в аренду предметов лизинга на балансе';
										|en = 'OB entry: financial lease items on the balance sheet'; fa = 'ورود مانده افتتاحیه: اقلام اجاره مالی در ترازنامه';
										|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio dati in affitto';
										|pl = 'Wprowadzenie początkowych sald przekazanych do dzierżawy przedmiotów leasingu na bilansie';
										|tr = 'Kiralanan kalemlerin ilk bakiyelerinin bilançoya girilmesi'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê ngoài bảng';
										|ru = 'Ввод начальных остатков предметов лизинга за балансом';
										|en = 'OB entry: financial lease items off the balance sheet'; fa = 'ورود مانده افتتاحیه: اقلام اجاره مالی خارج از ترازنامه';
										|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio';
										|pl = 'Wprowadzenie sald początkowych przedmiotów leasingu poza bilansem';
										|tr = 'Kiralanan kalemlerin ilk bilanço arkasına girilmesi'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của tài sản cố định cho thuê';
										|ru = 'Ввод начальных остатков переданных в аренду основных средств';
										|en = 'OB entry: leased out fixed assets'; fa = 'ورود مانده افتتاحیه: دارایی‌های ثابت اجاره‌داده‌شده';
										|it = 'Inserimento dei saldi iniziali dei capitali fissi dati in affitto';
										|pl = 'Wprowadzenie sald początkowych przekazanych do dzierżawy środków trwałych';
										|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi'");
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (ngoài bảng cân đối)';
										|ru = 'Ввод начальных остатков арендованных ОС (за балансом)';
										|en = 'OB entry: leased fixed assets (off balance sheet)'; fa = 'ورود مانده افتتاحیه: دارایی‌های ثابت اجاره‌ای (خارج از ترازنامه)';
										|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (fuori bilancio)';
										|pl = 'Wprowadzenie sald początkowych środków trwałych (poza bilansem)';
										|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi (bakiyenin arkasında)'");
	String.AddButtonCreate        = False;

	#EndRegion
	
	#Region Impairment
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FAImpairment;
	String.FullDocumentName			= Metadata.Documents.ImpairmentFA.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Giảm giá trị tài sản dài hạn';
										|ru = 'Обесценение внеоборотных активов';
										|en = 'Fixed asset impairment'; fa = 'کاهش ارزش دارایی ثابت';
										|it = 'Svalutazione attivi non correnti';
										|pl = 'Utrata wartości aktywów nieobrotowych';
										|tr = 'Duran varlıklar değer kaybı'");
	String.AddButtonCreate        = True;

	#EndRegion
	
	#Region Reserves
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FutureExpenseCommitmentsAccrualWriteOff;
	String.FullDocumentName			= Metadata.Documents.FutureExpenseCommitmentsAccrualWriteOff.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Dự phòng nghĩa vụ thanh lý';
										|ru = 'Резервы по ликвидационным обязательствам';
										|en = 'Residual liability reserves'; fa = 'Residual liability reserves';
										|it = 'Резервы по ликвидационным обязательствам';
										|pl = 'Residual liability reserves';
										|tr = 'Tasfiye yükümlülükleri için rezervler'");
	String.AddButtonCreate        = False;

	#EndRegion
	
	#Region PurchaseDocumentsAll
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromSupplier;
	String.FullDocumentName			= Metadata.Documents.VendorInvoice.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	String.FullDocumentName			= Metadata.Documents.VendorInvoice.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	#EndRegion
	
	#Region FixedAssetsPhysicalCount
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsPhysicalCount;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsPhysicalCount.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'kiểm kê TSCĐ';
										|ru = 'инвентаризация ОС';
										|en = 'Fixed assets — Physical inventory'; fa = 'دارایی‌های ثابت — موجودی فیزیکی';
										|it = 'Fixed assets — Physical inventory';
										|pl = 'Fixed assets — Physical inventory';
										|tr = 'sabit kıymet stok sayımı'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PhysicalCountOfCIPAssets;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsPhysicalCount.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'kiểm kê TSCĐ';
										|ru = 'инвентаризация ОС';
										|en = 'Fixed assets — Physical inventory'; fa = 'دارایی‌های ثابت — موجودی فیزیکی';
										|it = 'Fixed assets — Physical inventory';
										|pl = 'Fixed assets — Physical inventory';
										|tr = 'sabit kıymet stok sayımı'");
	String.AddButtonCreate        = True;
	
	If GetFunctionalOption("UseConstructionObjects") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.PhysicalCountOfConstructionInProgress;
		String.FullDocumentName			= Metadata.Documents.FixedAssetsPhysicalCount.FullName();
		String.PurposeUseKey 	= PurposeUseKey;
		String.WorkplaceTitle	 	= NStr("vi = 'kiểm kê TSCĐ';
											|ru = 'инвентаризация ОС';
											|en = 'Fixed assets — Physical inventory'; fa = 'دارایی‌های ثابت — موجودی فیزیکی';
											|it = 'Fixed assets — Physical inventory';
											|pl = 'Fixed assets — Physical inventory';
											|tr = 'sabit kıymet stok sayımı'");
		String.AddButtonCreate        = True;
	EndIf; 
	#EndRegion
	
	NonCurrentAssetsLocalization.SupplementBusinessOperationsAndFADocuments(BusinessTransactionsAndDocuments, PurposeUseKey);
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								PurposeUseKey);
	
	Return TableOfValuesAvailable;
		
EndFunction

&AtServerNoContext
Function InitializeBusinessTransactionsAndDepreciationDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey)
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsDepreciationCharge;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsDepreciationCharge2_4.FullName();
	String.PurposeUseKey 	= "FixedAssetsDepreciationCharge";
	String.WorkplaceTitle	 	= NStr("vi = 'Khấu hao';
										|ru = 'Амортизация';
										|en = 'Depreciation'; fa = 'استهلاک';
										|it = 'Ammortamento';
										|pl = 'Depreciation';
										|tr = 'Amortisman'");
	String.AddButtonCreate        = True;
	
	If PurposeUseKey = DefaultFormAssignmentKey() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								SettingsKey);
								
	Return TableOfValuesAvailable;
	
EndFunction

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.8, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		
		UpdatedList_4();
		StartUpdatingDataInBackground();
		
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtClient
Procedure UpdatedList_4()

	If Items.List.Visible Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List");
		// End DynamicListsSettings
	EndIf;
	
	If Items.ListDetailed.Visible Then
		Items.ListDetailed.Refresh();
	EndIf;

	If Items.ListDepreciation.Visible Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListDepreciation");
		// End DynamicListsSettings
	EndIf;
	
EndProcedure

&AtClient
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	
	If Items.Pages.CurrentPage = Items.DocumentsDetailsPage
		And ValueIsFilled(FilterFixedAsset) Then
		StructureSelections.Insert("FixedAsset", FilterFixedAsset);
	EndIf;
	
	Return StructureSelections;
	
EndFunction

&AtServer
Procedure FillInSelectionByOwnerAndNodes()

	SelectionByOwnerAndNodes.Clear();
	
	If Not ValueIsFilled(FilterFixedAsset) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT ALLOWED
	|	SubAssetsComponentsOfDepreciation.SubAssetComponent AS SubAssetComponent
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|WHERE
	|	SubAssetsComponentsOfDepreciation.FixedAsset = &FixedAsset
	|	AND SubAssetsComponentsOfDepreciation.Active
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("FixedAsset", FilterFixedAsset);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	SelectionByOwnerAndNodes.LoadValues(Result.Unload().UnloadColumn("SubAssetComponent"));
	SelectionByOwnerAndNodes.Add(FilterFixedAsset);
	
EndProcedure

&AtClient
Procedure SetClearDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
		NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure OnChangingListATServer()

	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtServer
Function BarcodeDataOfPrintedForm(Barcode, ListName = "")
	
	ThereIsMainTableOfList = OperationsWithDocumentJournals.ThereIsMainTableOfList(ThisObject, ListName);
	
	BarcodeData = TMCommonUse.BarcodeDataOfPrintedForm(Barcode, BusinessTransactionsAndDocuments.Unload(), ThereIsMainTableOfList);	
	
	Return BarcodeData;
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	Status(NStr("vi = 'Đang tìm kiếm chứng từ theo mã vạch...';
				|ru = 'Выполняется поиск документа по штрихкоду...';
				|en = 'Searching for the document by barcode...'; fa = 'Searching for the document by barcode...';
				|it = 'Viene effettuata la ricerca del documento per codice a barre...';
				|pl = 'Wyszukiwanie dokumentu według kodu kreskowego...';
				|tr = 'Belge barkoda göre aranıyor...'"));
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "List");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "List");
	
EndProcedure

#EndRegion

#Region HyperlinkToDesign

&AtClient
Procedure StartUpdatingDataInBackground()
	
	TimeConsumingOperation = StartUpdatingDataInBackgroundOnServer();
	
	CallbackOnCompletion = New CallbackDescription("UpdatingDataInBackgroundEnds", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function StartUpdatingDataInBackgroundOnServer()

	FunctionParameters = New Structure;
	FunctionParameters.Insert("Organization", FilterOrganization);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "DataProcessors.FADocumentLog2_4.WorkplaceData", FunctionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: <đang cập nhật dữ liệu>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		ToRegister = New FormattedString(TextIsUpdatingData);
	EndIf;

	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure UpdatingDataInBackgroundEnds(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
			
	UpdatingDataInBackgroundOrOnServer(Result.ResultAddress);
	
EndProcedure 

&AtServer
Procedure UpdatingDataInBackgroundOrOnServer(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);

	If ValueIsFilled(Result) Then
		ToRegister = New FormattedString(Result);
		Items.ToRegister.Visible = Items.List.Visible;
		Items.ToRegisterPageDetails.Visible = True;
	Else
		Items.ToRegister.Visible = False;
		Items.ToRegisterPageDetails.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "List";
	ListParameterStructure.PlacementGroupSettings = Items.DocumentListSettingsGroup;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfDocumentsAutoUpdateMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.DocumentsListRefresh.Name;
	DocumentListParameters.Add(ListParameterStructure);
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListDepreciation";
	ListParameterStructure.PlacementGroupSettings = Items.DocumentListSettingsGroupDepreciation;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfDocumentsDepreciationAutoUpdateMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.DepreciationDocumentListToUpdate.Name;
	DocumentListParameters.Add(ListParameterStructure);
	
	OperationsWithDocumentJournals.InitiateDynamicListSettings(ThisObject, DocumentListParameters);

EndProcedure

&AtClient
Procedure DisplayingGroupOfUserSelectionsAndSettings(ListName)
	
	LongTermUpdate = OperationsWithDocumentJournalsClient.TimeToUpdateListExceedsAllowedTime(ThisObject,
		ListName);
		
	If LongTermUpdate Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	Else
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", False);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", New DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", New Structure);
	EndIf;

	OperationsWithDocumentJournalsClient.DocumentsDisplayGroupOfUserSelectionsAndSettings(ThisObject, ListName);
	
EndProcedure

&AtServer
Function GetPerformingDataCompositionSettings(ListName)
	
	TagName = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject, ListName,
		"NameOfListItem");
	ListFormElement = Items[TagName];
	DataCompositionSettings = ListFormElement.GetPerformingDataCompositionSettings();

	ReturnStructure = New Structure;
	ReturnStructure.Insert("DataCompositionSettings", DataCompositionSettings);

	ListOfCompositeTypeFields = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject,
		ListName, "ListOfCompositeTypeFields");

	StructureOfUserSettings = OperationsWithDocumentJournals.CheckUserSettingsOfDynamicList(
		DataCompositionSettings, ListOfCompositeTypeFields);

	ReturnStructure.Insert("StructureOfUserSettings", StructureOfUserSettings);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure SetParametersForUpdatingDocumentLists(DataIsOutdated, UpdatingDuration = Undefined)
	
	SettingName = "ListOfDocumentsCacheSettings";
	ListName = "";
	For Each SettingUpListOfDocuments In ThisObject[SettingName] Do
		ListName = SettingUpListOfDocuments.Key;
		OperationsWithDocumentJournalsClient.SetParametersForUpdatingDocumentList(ThisObject, ListName, DataIsOutdated,
			UpdatingDuration);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateDocumentListDataWithTimeMeasurement(ListName, ConsiderAutoUpdateParameter = False)

	If Not ConsiderAutoUpdateParameter Then

		TheListNeedsToBeUpdated = True;

	Else

		TheListNeedsToBeUpdated = OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments(
			ThisObject, ListName);

		If Not TheListNeedsToBeUpdated Then
			OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(ThisObject, ListName);
		EndIf;

	EndIf;

	If TheListNeedsToBeUpdated Then

		OperationsWithDocumentJournalsClient.UpdateDocumentListDataWithTimeMeasurement(ThisObject, ListName);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);

	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfDocumentsEventNotificationProcessing(ListName, Parameter = Undefined)
	
	OperationsWithDocumentJournalsClient.UpdateListOfDocumentsEventNotificationProcessing(ThisObject, ListName, Parameter);
	DisplayingGroupOfUserSelectionsAndSettings(ListName);

EndProcedure

// Processing the form element event.
// 
// Parameters:
//  Item - FormField
//@skip-check module-unused-method
&AtClient
Procedure ListOfDocumentsFormElementEventHandling(Item)

	ActionForList = OperationsWithDocumentJournalsClient.NameOfListOfDocumentsByNameOfFormElement(ThisObject, Item.Name);
	
	If ActionForList.ListName = "" Then
		Return;
	EndIf;
	
	ListName = ActionForList.ListName;
	Action = ActionForList.Action;
	
	If Action = "Filters" Or Action = "Order" Or Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	EndIf;
	
	If Action = "Filters" Then
		OperationsWithDocumentJournalsClient.FixCustomSelectionsInDocumentList(ThisObject, ListName);
	ElsIf Action = "Order" Then
		OperationsWithDocumentJournalsClient.FixSortingSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.FixConditionalAppearanceSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "RefreshEnabled" Then
		UpdateDocumentListDataWithTimeMeasurement(ListName);
	ElsIf Action = "SpeedingUpListUpdates" Then
		OperationsWithDocumentJournalsClient.SaveSettingProductiveListUpdateMode(ThisObject, ListName);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
